extends RefCounted
## Build-only performance candidate. Complete files and every 1MiB cancellation
## boundary are unchanged. No digest cache, Resource, Node or rendering access.
const READ_CHUNK_BYTES := 1024 * 1024
const DEFAULT_WORKER_LIMIT := 8
const ALLOWED_WORKER_LIMITS := [1,2,4,8]
var paths: Array = []
var hashes: Dictionary = {}
var worker_limit: int = DEFAULT_WORKER_LIMIT
var external_cancel: Callable = Callable()
var _mutex := Mutex.new()
var _cancelled := false
var _failed := false
var _began := false
var _queue: Array[String] = []
var _cursor := 0
var _debug: Dictionary = {
	"worker_limit":DEFAULT_WORKER_LIMIT,"children_started":0,"children_joined":0,
	"active_children":0,"peak_children":0,"started_files":0,"completed_files":0,
	"read_chunks":0,"read_bytes":0,"running":false,"complete":false,
	"cancelled":false,"error":""
}

class Lane extends RefCounted:
	var coordinator: RefCounted
	# Written by this lane only. Coordinator reads only after every child joins.
	var results: Dictionary = {}
	var read_chunks: int = 0
	var read_bytes: int = 0
	var completed_files: int = 0
	func _file_sha(path: String) -> String:
		if coordinator._is_cancelled(): return ""
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null: return ""
		var length := file.get_length()
		var digest := HashingContext.new()
		var valid: bool = length >= 0 and file.get_error() == OK and digest.start(HashingContext.HASH_SHA256) == OK
		var consumed := 0
		while valid and consumed < length:
			if coordinator._is_cancelled(): valid = false; break
			var requested := mini(1024 * 1024, length - consumed)
			var bytes := file.get_buffer(requested)
			if bytes.size() != requested or file.get_error() != OK or coordinator._is_cancelled() or digest.update(bytes) != OK:
				valid = false
				break
			consumed += bytes.size()
			read_chunks += 1
			read_bytes += bytes.size()
		valid = valid and consumed == length and file.get_position() == length and file.get_length() == length and file.get_error() == OK and not coordinator._is_cancelled()
		file.close()
		if not valid: return ""
		var result := digest.finish()
		return result.hex_encode() if result.size() == 32 else ""
	func run() -> void:
		while not coordinator._is_cancelled():
			var path: String = coordinator._next_path()
			if path.is_empty(): return
			var sha := _file_sha(path)
			if sha.length() != 64:
				if not coordinator._is_cancelled(): coordinator._fail("Complete file SHA failed: " + path)
				return
			results[path] = sha
			completed_files += 1

func request_cancel() -> void:
	_mutex.lock()
	_cancelled = true
	_debug.cancelled = true
	_mutex.unlock()

func _is_cancelled() -> bool:
	_mutex.lock()
	var stopped: bool = _cancelled or _failed
	_mutex.unlock()
	# Never hold our lock while calling C's independently locked cancel flag.
	if not stopped and external_cancel.is_valid() and bool(external_cancel.call()):
		request_cancel()
		return true
	return stopped

func _fail(message: String) -> void:
	_mutex.lock()
	_failed = true
	_debug.complete = false
	if String(_debug.error).is_empty(): _debug.error = message
	_mutex.unlock()

func _next_path() -> String:
	if _is_cancelled(): return ""
	_mutex.lock()
	var path := ""
	if not _cancelled and not _failed and _cursor < _queue.size():
		path = _queue[_cursor]
		_cursor += 1
		_debug.started_files += 1
	_mutex.unlock()
	return path

func _joined_lane_counters(lanes: Array[Lane]) -> void:
	# Called only after ALL wait_to_finish calls, including cancelled/failed runs.
	# These three progress counters are joined observations, not live estimates.
	_mutex.lock()
	for lane: Lane in lanes:
		_debug.read_chunks += lane.read_chunks
		_debug.read_bytes += lane.read_bytes
		_debug.completed_files += lane.completed_files
	_mutex.unlock()

func _child_started() -> void:
	_mutex.lock()
	_debug.children_started += 1
	_debug.active_children += 1 # Started but not yet joined, not a scheduling claim.
	_debug.peak_children = maxi(int(_debug.peak_children),int(_debug.active_children))
	_mutex.unlock()

func _child_joined() -> void:
	_mutex.lock()
	_debug.children_joined += 1
	_debug.active_children -= 1
	_mutex.unlock()

func debug_state() -> Dictionary:
	_mutex.lock()
	var result := _debug.duplicate(true)
	_mutex.unlock()
	return result

func run() -> void:
	_mutex.lock()
	if _began:
		_mutex.unlock()
		_fail("A source job is single-use")
		hashes = {}
		return
	_began = true
	_debug.running = true
	_debug.worker_limit = worker_limit
	_mutex.unlock()
	hashes = {}
	if worker_limit not in ALLOWED_WORKER_LIMITS or paths.is_empty():
		_fail("Expected nonempty unique paths and worker limit 1, 2, 4 or 8")
	var seen: Dictionary = {}
	for path: Variant in paths:
		if typeof(path) != TYPE_STRING or String(path).is_empty() or seen.has(path):
			_fail("Source paths must be unique nonempty Strings")
			break
		seen[path] = true
		_queue.append(path)
	var threads: Array[Thread] = []
	var lanes: Array[Lane] = []
	if not _is_cancelled():
		for index: int in mini(worker_limit,_queue.size()):
			if _is_cancelled(): break
			var lane := Lane.new()
			lane.coordinator = self
			var thread := Thread.new()
			var error: Error = thread.start(lane.run)
			if error != OK:
				_fail("Source thread start refused: " + str(error))
				break
			threads.append(thread)
			lanes.append(lane)
			_child_started()
	# No early return between first successful start and joining every child.
	for thread: Thread in threads:
		thread.wait_to_finish()
		_child_joined()
	_joined_lane_counters(lanes)
	var merged: Dictionary = {}
	if not _is_cancelled():
		for lane: Lane in lanes:
			for path: String in lane.results:
				if merged.has(path) or String(lane.results[path]).length() != 64:
					_fail("Joined source lane duplicate or incomplete digest")
					break
				merged[path] = lane.results[path]
		if merged.size() != seen.size() or _cursor != _queue.size(): _fail("Joined source map is incomplete")
		for path: String in _queue:
			if not merged.has(path): _fail("Joined source path is missing")
	if not _is_cancelled(): hashes = merged
	_mutex.lock()
	_debug.running = false
	_debug.complete = not _cancelled and not _failed and hashes.size() == _queue.size() and not hashes.is_empty()
	_mutex.unlock()
	# C's parent job checks its own cancel flag again before exposing this map.
	if _is_cancelled():
		hashes = {}
		_mutex.lock()
		_debug.complete = false
		_mutex.unlock()
