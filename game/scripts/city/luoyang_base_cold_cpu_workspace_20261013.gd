extends RefCounted
## One live transition's exclusive PNG computation. No Node/Texture/GPU access.
## Results are copied byte packets, consumed by the original main-thread checks.
const ROOT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/"
const SELF_PATH := "res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd"
const IDS := ["ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market"]
var _mutex := Mutex.new()
var _cancelled := false
var _token := 0
var _id := ""
var _prefix := ""
var _record: Dictionary = {}
var _catalog: Dictionary = {}
var _sources: Dictionary = {}
var _metadata: Dictionary = {}
var _alpha: Callable
var _images: Dictionary = {}
var _logical: Dictionary = {}
var _ground: Dictionary = {}
var _completed := false
var _joined := false
var _error := ""
var _main_timings: Dictionary = {}
var _main_last_stage := ""

func configure(token: int, id: StringName, record: Dictionary, sources: Dictionary, alpha: Callable) -> bool:
	if token <= 0 or String(id) not in IDS or not alpha.is_valid() or not record.get("asset_sha256") is Dictionary or not record.get("objects") is Array: return false
	var prefix := ROOT + String(id) + "/"
	if record.get("canonical_scene_id") != String(id): return false
	var catalog: Dictionary = record.asset_sha256
	for path: Variant in catalog:
		if not path is String or not catalog[path] is String or sources.get(path) != catalog[path]: return false
	# Match the original validate() first-occurrence prototype walk exactly.
	# Gate has one wall kind, Yamen two; Docks/Market have no wall prototypes.
	for item: Variant in record.objects:
		if not item is Dictionary: return false
		var kind := String(item.get("prototype", ""))
		if kind not in ["wall_horizontal", "wall_vertical"]: continue
		var stem := prefix + "entities/native_" + kind
		if _metadata.has(stem): continue
		var path := stem + ".json"
		if not catalog.has(path): return false
		var bytes := FileAccess.get_file_as_bytes(path)
		if _sha(bytes) != catalog[path]: return false
		var value: Variant = JSON.parse_string(bytes.get_string_from_utf8())
		if not value is Dictionary or value.get("kind") != kind: return false
		_metadata[stem] = value.duplicate(true)
	_token = token; _id = String(id); _prefix = prefix
	_record = record.duplicate(true); _catalog = catalog.duplicate(true); _sources = sources.duplicate(true)
	_alpha = alpha
	return true

func request_cancel() -> void:
	_mutex.lock(); _cancelled = true; _mutex.unlock()

func is_cancelled() -> bool:
	_mutex.lock(); var value := _cancelled; _mutex.unlock()
	return value

func run() -> void:
	# All images below are task-local. Only plain byte packets cross the join.
	var on: Image
	for role: String in ["on", "off"]:
		for suffix: String in ["_raw.png", "_raw_repeat.png"]:
			if is_cancelled(): return
			var path := _prefix + "ground_" + role + suffix
			var image := _load_bound_png(path)
			_images[path] = _packet(image)
			if role == "on" and suffix == "_raw.png": on = image
	if is_cancelled(): return
	_images[_prefix + "floor.png"] = _packet(_load_bound_png(_prefix + "floor.png"))
	if on != null:
		var derived := on.duplicate() as Image
		derived.resize(3072, 2048, Image.INTERPOLATE_LANCZOS)
		if is_cancelled(): return
		_ground = _packet(derived)
	for stem: String in _metadata:
		if is_cancelled(): return
		var raw: Image
		for suffix: String in ["_raw.png", "_raw_repeat.png", ".png"]:
			if is_cancelled(): return
			var image := _load_bound_png(stem + suffix)
			_images[stem + suffix] = _packet(image)
			if suffix == "_raw.png": raw = image
		if raw != null:
			var logical: Image = _alpha.call(raw, Vector2i(768, 768), self)
			if is_cancelled(): return
			_logical[stem] = _packet(logical)
	if is_cancelled(): return
	_completed = true
	_alpha = Callable()

func matches(token: int, id: StringName, prefix: String, record: Dictionary, catalog: Dictionary) -> bool:
	return matches_owner(token, id) and _prefix == prefix and var_to_bytes(_record) == var_to_bytes(record) and var_to_bytes(_catalog) == var_to_bytes(catalog)

func mark_joined(token: int, id: StringName) -> bool:
	# Main calls this only after wait_for_task_completion and its owner check.
	if not _completed or not _error.is_empty() or is_cancelled() or token <= 0 or _token != token or _id != String(id): return false
	_joined = true
	return true

func matches_owner(token: int, id: StringName) -> bool:
	return ready() and token > 0 and _token == token and _id == String(id) and _prefix == ROOT+String(id)+"/"

func source_sha(id: StringName, path: Variant) -> String:
	# No file fallback, static cache or reads of an active job's output.
	if get_script().resource_path != SELF_PATH or not matches_owner(_token, id) or typeof(path) != TYPE_STRING or not path.begins_with("res://") or ".." in path or not _sources.has(path): return ""
	var value: Variant = _sources[path]
	if typeof(value) != TYPE_STRING or value.length() != 64: return ""
	for index in range(value.length()):
		if value[index] not in "0123456789abcdefABCDEF": return ""
	return value

func matches_input(id: StringName, prefix: String, record: Dictionary, catalog: Dictionary) -> bool:
	return matches(_token, id, prefix, record, catalog)

func matches_body(stem: String, metadata: Dictionary, catalog: Dictionary) -> bool:
	return _completed and _error.is_empty() and not is_cancelled() and _metadata.has(stem) and var_to_bytes(_metadata[stem]) == var_to_bytes(metadata) and var_to_bytes(_catalog) == var_to_bytes(catalog)

func image(path: String) -> Image:
	return _unpack(_images.get(path, {})) if _completed and not is_cancelled() else null

func logical(stem: String) -> Image:
	return _unpack(_logical.get(stem, {})) if _completed and not is_cancelled() else null

func ground(prefix: String, catalog: Dictionary) -> Image:
	return _unpack(_ground) if _completed and not is_cancelled() and prefix == _prefix and var_to_bytes(catalog) == var_to_bytes(_catalog) else null

func ready() -> bool:
	return _joined and _completed and _error.is_empty() and not is_cancelled()

func error() -> String:
	return _error

func record_main_stage(id: StringName, label: String, elapsed_usec: int) -> void:
	# Main-only, scalar diagnostics. Never retain a Resource, Node or callback.
	if not matches_owner(_token, id) or elapsed_usec < 0: return
	var row: Dictionary = _main_timings.get(label, {"count":0,"total_usec":0,"max_usec":0})
	row.count += 1; row.total_usec += elapsed_usec; row.max_usec = maxi(row.max_usec, elapsed_usec)
	_main_timings[label] = row
	_main_last_stage = label

func main_timings(id: StringName) -> Dictionary:
	return _main_timings.duplicate(true) if matches_owner(_token, id) else {}

func main_last_completed_stage(id: StringName) -> String:
	return _main_last_stage if matches_owner(_token, id) else ""

func release() -> void:
	# Caller must have joined the task before releasing these exclusive buffers.
	release_pixels(); _metadata.clear()
	_record.clear(); _catalog.clear(); _sources.clear(); _alpha = Callable()
	_main_timings.clear()
	_main_last_stage = ""
	_completed = false; _joined = false; _token = 0

func release_pixels() -> void:
	# After BASE consumption, retain only this transition's small identity receipt.
	_images.clear(); _logical.clear(); _ground.clear()

func _load_bound_png(path: String) -> Image:
	if is_cancelled(): return null
	if not _catalog.has(path) or _sources.get(path) != _catalog[path]: _error = "BASE CPU PNG absent from complete source identity: " + path; return null
	# Decode the exact bytes hashed here, not a second pathname read (TOCTOU).
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty() or _sha(bytes) != _catalog[path]: _error = "BASE CPU PNG source changed: " + path; return null
	if is_cancelled(): return null
	var result := Image.new()
	if result.load_png_from_buffer(bytes) != OK: return null
	return result

static func _sha(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256) != OK or hash.update(bytes) != OK: return ""
	return hash.finish().hex_encode()

static func _packet(image: Image) -> Dictionary:
	return {} if image == null else {"width":image.get_width(), "height":image.get_height(), "mipmaps":image.has_mipmaps(), "format":image.get_format(), "bytes":image.get_data()}

static func _unpack(packet: Dictionary) -> Image:
	if packet.is_empty(): return null
	return Image.create_from_data(packet.width, packet.height, packet.mipmaps, packet.format, packet.bytes)
