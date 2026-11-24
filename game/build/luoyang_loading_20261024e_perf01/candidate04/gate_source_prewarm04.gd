extends RefCounted
## Candidate only. A plain complete-SHA job, never a finite/NAV/transition receipt.
const SELF := "res://build/luoyang_loading_20261024e_perf01/candidate04/gate_source_prewarm04.gd"
const C_PATH := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const B_PATH := "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const H = preload("res://scripts/city/luoyang_parallel_source_hash_20261017k.gd")
const PREWARM_WORKER_LIMIT := H.DEFAULT_WORKER_LIMIT
const TARGET := &"ch4_s0_luoyang_gate"
const RAW := "res://data/scenes/ch4_s0_luoyang_gate.tres"
const ENABLED := true
static var _serial: int = 0
static var _slot: Dictionary = {}
static var _last: Dictionary = {}

static func enabled() -> bool:
	return ENABLED and not OS.has_feature("web")

static func _c() -> Variant: return load(C_PATH)
static func _b() -> Variant: return load(B_PATH)
static func _tree() -> SceneTree: return Engine.get_main_loop() as SceneTree
static func _sha(bytes: PackedByteArray) -> String:
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256); digest.update(bytes)
	return digest.finish().hex_encode()

static func map_key(values: Dictionary) -> String:
	var keys: Array = values.keys()
	for path: Variant in keys:
		if typeof(path) != TYPE_STRING or typeof(values[path]) != TYPE_STRING or not _c()._hash(values[path]): return ""
	keys.sort()
	var pairs: Array = []
	for path: Variant in keys:
		pairs.append([path, values[path]])
	return _sha(var_to_bytes(pairs)) if not pairs.is_empty() else ""

static func exact_keys(paths: Dictionary, expected: Dictionary) -> bool:
	if paths.is_empty() or paths.size() != expected.size(): return false
	for path: Variant in paths:
		if typeof(path) != TYPE_STRING or not expected.has(path): return false
	return true

static func joined_matches(expected: Dictionary, actual: Dictionary, debug: Dictionary) -> bool:
	return debug.get("complete") == true and int(debug.get("active_children", -1)) == 0 and int(debug.get("children_started", -1)) == int(debug.get("children_joined", -2)) and not map_key(expected).is_empty() and _c()._equal_value(expected, actual)

static func gate_expected_map() -> Dictionary:
	# Exact Gate-only B.describe recipe, not a path-count or metadata-stamp key.
	var bundle: Variant = _b()
	if not bundle.requested(TARGET): return {}
	var config: Dictionary = bundle.manifest(TARGET)
	if config.is_empty(): return {}
	var expected: Dictionary = config.legacy_source_sha256.duplicate(true)
	expected.merge(config.runtime_authority_sha256); expected.merge(config.artifacts)
	for path: String in [bundle.INDEX, bundle.ESTATE_INDEX, bundle.AO_INDEX, bundle.AP_INDEX, bundle.AP_ENV_INDEX, bundle.AP_EXEC_INDEX, bundle.AP_QUARTER_INDEX]:
		var value: String = FileAccess.get_sha256(path)
		if not _c()._hash(value): return {}
		expected[path] = value
	var entry: Dictionary = bundle._entry(TARGET)
	if entry.is_empty(): return {}
	expected[entry.manifest_path] = entry.manifest_sha256
	return expected if not bundle.describe(TARGET, expected).is_empty() else {}

static func _inputs(raw: SceneScript) -> Dictionary:
	if raw == null or raw.scene_id != TARGET or raw.resource_path != RAW or raw.map_layout == null or not _c().is_v3(raw): return {}
	var paths: Dictionary = _c()._transition_sources(raw, false)
	var expected: Dictionary = gate_expected_map()
	if not exact_keys(paths, expected): return {}
	var key := map_key(expected)
	if key.is_empty(): return {}
	return {"expected":expected, "map_key":key, "input":_c()._transition_storage(raw), "layout":_c()._transition_storage(raw.map_layout)}

static func _start_inputs(raw: SceneScript) -> Dictionary:
	# Speculation only. Do NOT collect the full C graph on a playable World frame.
	# Claim still calls _inputs above; missing/changed keys then force normal SHA.
	if raw == null or raw.scene_id != TARGET or raw.resource_path != RAW or raw.map_layout == null or not _c().is_v3(raw): return {}
	var expected: Dictionary = gate_expected_map()
	var key: String = map_key(expected)
	if key.is_empty(): return {}
	return {"expected":expected, "map_key":key, "input":_c()._transition_storage(raw), "layout":_c()._transition_storage(raw.map_layout), "speculative_start_only":true, "start_collector_calls":0}

static func _world_matches(slot: Dictionary) -> bool:
	var tree := _tree()
	var owner: Node = slot.owner.get_ref() if slot.get("owner") is WeakRef else null
	var scene: Resource = slot.world_scene.get_ref() if slot.get("world_scene") is WeakRef else null
	var layout: Resource = slot.world_layout.get_ref() if slot.get("world_layout") is WeakRef else null
	return tree != null and is_instance_valid(owner) and owner.is_inside_tree() and not owner.is_queued_for_deletion() and tree.current_scene == owner and owner.get("_current_scene") == scene and scene != null and scene.get("scene_id") == slot.get("world_id") and scene.get("map_layout") == layout and layout != null and int(owner.get("_city3_motion_revision")) == int(slot.get("revision", -1))

static func _owns(epoch: int) -> bool:
	return not _slot.is_empty() and int(_slot.get("epoch", -1)) == epoch

static func _cancel(epoch: int, reason: String) -> void:
	if not _owns(epoch): return
	var job: RefCounted = _slot.get("job")
	var task: int = int(_slot.get("task", -1))
	if job != null: job.call("request_cancel")
	if task >= 0: WorkerThreadPool.wait_for_task_completion(task)
	_last = {"phase":reason, "epoch":epoch, "fresh_final_credit":false, "children_joined_before_release":true}
	if _owns(epoch): _slot.clear()

static func cancel_for_owner(owner: Node) -> void:
	if _slot.is_empty() or _slot.get("phase") == "CLAIMED": return
	if _slot.owner.get_ref() == owner: _cancel(int(_slot.epoch), "WORLD_OWNER_RELEASED")

static func cancel_claim(token: int) -> void:
	if token > 0 and _slot.get("phase") == "CLAIMED" and int(_slot.get("claimed_token", 0)) == token:
		_cancel(int(_slot.epoch), "CITY_CLAIM_CANCELLED")

static func state() -> Dictionary:
	if _slot.is_empty(): return _last.duplicate(true)
	return {"phase":_slot.phase, "epoch":_slot.epoch, "scene_id":String(TARGET), "source_count":_slot.get("expected", {}).size(), "map_key":_slot.get("map_key", ""), "worker_limit":PREWARM_WORKER_LIMIT, "started_usec":_slot.get("started_usec", 0), "hash_started_usec":_slot.get("hash_started_usec", 0), "completed_usec":_slot.get("completed_usec", 0), "world_hidden_operable_draw_usec":_slot.get("world_hidden_operable_draw_usec", 0), "world_hidden_operable_draw_frame":_slot.get("world_hidden_operable_draw_frame", 0), "claimed_token":_slot.get("claimed_token", 0), "fresh_final_credit":false}

static func _join(epoch: int) -> bool:
	if not _owns(epoch): return false
	var task: int = int(_slot.task)
	if task >= 0:
		WorkerThreadPool.wait_for_task_completion(task)
		_slot.task = -1
	var job: RefCounted = _slot.job
	var actual: Dictionary = job.get("hashes")
	var debug: Dictionary = job.call("debug_state")
	if not joined_matches(_slot.expected, actual, debug):
		_cancel(epoch, "PREWARM_HASH_FAILED"); return false
	_slot.hashes = actual.duplicate()
	if int(_slot.get("completed_usec", 0)) == 0: _slot.completed_usec = Time.get_ticks_usec()
	if _slot.phase != "CLAIMED": _slot.phase = "COMPLETE"
	return true

static func _poll(epoch: int) -> void:
	while _owns(epoch) and _slot.phase == "PENDING":
		if not _world_matches(_slot): _cancel(epoch, "WORLD_EPOCH_CHANGED"); return
		if WorkerThreadPool.is_task_completed(int(_slot.task)):
			_join(epoch); return
		await _tree().process_frame

static func start(owner: Node, scene: SceneScript, world_draw_usec: int = 0, world_draw_frame: int = 0) -> void:
	if not enabled() or not _slot.is_empty() or owner == null or scene == null or scene.map_layout == null or world_draw_usec <= 0 or world_draw_frame <= 0: return
	var tree := _tree()
	var router: Node = tree.root.get_node_or_null("SceneRouter") if tree != null else null
	if router == null or tree.current_scene != owner or owner.get("_current_scene") != scene or not bool(router.call("is_world_map_scene", scene.scene_id)) or int(router.call("world_version_for_scene", scene.scene_id)) != 15: return
	var matches: int = 0
	for portal: Dictionary in scene.map_layout.portals:
		if String(portal.get("id", "")) == "luoyang" and StringName(portal.get("target_scene", &"")) == TARGET: matches += 1
	if matches != 1: return
	_serial += 1
	var epoch: int = _serial
	_slot = {"phase":"PREPARING_INPUTS", "epoch":epoch, "owner":weakref(owner), "world_scene":weakref(scene), "world_id":scene.scene_id, "world_layout":weakref(scene.map_layout), "revision":int(owner.get("_city3_motion_revision")), "task":-1, "job":null, "started_usec":Time.get_ticks_usec(), "world_hidden_operable_draw_usec":world_draw_usec, "world_hidden_operable_draw_frame":world_draw_frame}
	var raw := ResourceLoader.load(RAW, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _owns(epoch) or not _world_matches(_slot): _cancel(epoch, "PREPARE_OWNER_CHANGED"); return
	var input: Dictionary = _start_inputs(raw)
	if input.is_empty(): _cancel(epoch, "PREPARE_EXPECTED_MAP_UNAVAILABLE"); return
	if not _owns(epoch) or not _world_matches(_slot): _cancel(epoch, "PREPARE_OWNER_CHANGED"); return
	_slot.merge(input)
	var job := H.new()
	job.paths = input.expected.keys(); job.worker_limit = PREWARM_WORKER_LIMIT
	_slot.job = job
	_slot.hash_started_usec = Time.get_ticks_usec()
	var task: int = WorkerThreadPool.add_task(job.run, false, "Gate complete source SHA prewarm epoch")
	if task < 0: _cancel(epoch, "PREWARM_WORKER_REFUSED"); return
	_slot.task = task; _slot.phase = "PENDING"
	Callable(load(SELF), "_poll").call_deferred(epoch)

static func source_first(raw: SceneScript, token: int, fallback: Callable) -> Dictionary:
	if not fallback.is_valid(): return {}
	if not enabled() or token <= 0 or _slot.is_empty():
		return await fallback.call()
	var epoch: int = int(_slot.epoch)
	if raw == null or raw.scene_id != TARGET:
		_cancel(epoch, "DIFFERENT_CITY_SOURCE_FIRST")
		return await fallback.call()
	var input: Dictionary = _inputs(raw)
	if _slot.phase not in ["PENDING", "COMPLETE"] or not _world_matches(_slot) or input.is_empty() or input.map_key != _slot.map_key or not _c()._equal_value(input.expected, _slot.expected) or not _c()._equal_value(input.input, _slot.input) or not _c()._equal_value(input.layout, _slot.layout):
		_cancel(epoch, "CLAIM_IDENTITY_MISS")
		return await fallback.call()
	if int(_c()._live_source_token) != token: return {}
	var claim_basis: String = String(_slot.phase)
	_slot.phase = "CLAIMED"; _slot.claimed_token = token
	var wait_started: int = Time.get_ticks_usec()
	while _owns(epoch) and int(_slot.task) >= 0 and not WorkerThreadPool.is_task_completed(int(_slot.task)):
		if int(_c()._live_source_token) != token:
			_cancel(epoch, "CLAIM_OWNER_CHANGED"); return {}
		await _tree().process_frame
	if not _owns(epoch) or int(_c()._live_source_token) != token: return {}
	if not _join(epoch): return await fallback.call()
	var wait_finished: int = Time.get_ticks_usec()
	# Fresh control/whole-key check after pending work; never reuse finite context.
	# Complete path collection was just performed at claim; do not collect it a
	# second time. Final transition still recollects and freshly hashes ALL paths.
	var expected_now: Dictionary = gate_expected_map()
	if map_key(expected_now) != input.map_key or not _c()._equal_value(expected_now, input.expected) or not _c()._equal_value(_c()._transition_storage(raw), input.input) or not _c()._equal_value(_c()._transition_storage(raw.map_layout), input.layout) or _b().describe(TARGET, _slot.hashes).is_empty():
		_cancel(epoch, "JOIN_CONTROL_MAP_CHANGED")
		return await fallback.call()
	var result: Dictionary = _slot.hashes.duplicate()
	_last = {"phase":"CONSUMED_SOURCE_FIRST_ONLY", "epoch":epoch, "scene_id":String(TARGET), "source_count":result.size(), "map_key":input.map_key, "worker_limit":PREWARM_WORKER_LIMIT, "started_usec":_slot.started_usec, "hash_started_usec":_slot.hash_started_usec, "completed_usec":_slot.completed_usec, "world_hidden_operable_draw_usec":_slot.world_hidden_operable_draw_usec, "world_hidden_operable_draw_frame":_slot.world_hidden_operable_draw_frame, "claimed_token":token, "claim_basis":claim_basis, "remaining_task_wait_usec":wait_finished-wait_started, "postjoin_control_recheck_usec":Time.get_ticks_usec()-wait_finished, "fresh_final_credit":false, "finite_receipt_reused":false, "children_joined_before_release":true}
	_slot.clear()
	return result
