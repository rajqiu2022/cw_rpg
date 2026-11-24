extends RefCounted
## BUILD dispatch. One explicit feature switch; no automatic takeover on failure.
const MANIFEST_PATH := "res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json"
const FIELD_SCENE := "res://build/luoyang_regions_20261027d_source01/region_field.tscn"
const Compiler = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Alias = preload("res://build/luoyang_regions_20261027d_source01/legacy_alias.gd")
const Terminal = preload("res://build/luoyang_regions_20261027d_source01/region_source_context.gd")
const Phase = preload("res://build/luoyang_regions_20261027d_source01/region_phase_scope.gd")
const ALIASES := {"yihongyuan27n_interior": "yihongyuan27n_interior", "ch4_s1_luoyang_yamen": "luoyang_civic_market_region_27d", "ch4_s3_luoyang_market": "luoyang_civic_market_region_27d", "luoyang_estate_riverside_20261021ai": "luoyang_estate_region_27d", "ch4_s4_ancient_temple": "luoyang_temple_region_27d", "estate27d_living_hall": "estate27d_living_hall", "estate27d_west_study": "estate27d_west_study", "estate27d_east_bedroom": "estate27d_east_bedroom", "temple27d_main_hall": "temple27d_main_hall", "temple27d_monks_room": "temple27d_monks_room", "temple27d_sutra_room": "temple27d_sutra_room"}
const SCENE_RESOURCES := {"yihongyuan27n_interior": "res://data/scenes/yihongyuan27n_interior.tres", "luoyang_civic_market_region_27d": "res://build/luoyang_regions_20261027d_source01/civic_market_scene.tres", "luoyang_estate_region_27d": "res://build/luoyang_regions_20261027d_source01/estate_region_scene.tres", "luoyang_temple_region_27d": "res://build/luoyang_regions_20261027d_source01/temple_region_scene.tres", "estate27d_living_hall": "res://build/luoyang_regions_20261027d_source01/estate_living_hall_scene.tres", "estate27d_west_study": "res://build/luoyang_regions_20261027d_source01/estate_west_study_scene.tres", "estate27d_east_bedroom": "res://build/luoyang_regions_20261027d_source01/estate_east_bedroom_scene.tres", "temple27d_main_hall": "res://build/luoyang_regions_20261027d_source01/temple_main_hall_scene.tres", "temple27d_monks_room": "res://build/luoyang_regions_20261027d_source01/temple_monks_room_scene.tres", "temple27d_sutra_room": "res://build/luoyang_regions_20261027d_source01/temple_sutra_room_scene.tres"}
static var _pending: Dictionary = {}
static var _serial: int = 0

static func requested(id: StringName) -> bool:
	return ALIASES.has(String(id))

static func prepare(id: StringName, uv: Variant, legacy_version: int, extension: Dictionary, expected_author_sha: String) -> Dictionary:
	if not requested(id): return {"matched": false, "ok": true}
	if not _pending.is_empty(): return {"matched": true, "ok": false, "error": "REGION_REQUEST_BUSY"}
	var manifest: Dictionary = _manifest(expected_author_sha)
	if manifest.is_empty(): return {"matched": true, "ok": false, "error": "REGION_NOT_SEALED"}
	var region_id: String = ALIASES[String(id)]
	var loaded: Dictionary = _load_region(manifest, region_id, expected_author_sha)
	if loaded.get("ok") != true: return loaded
	var compiled: Dictionary = loaded.compiled
	var point: Variant = uv
	if point == null: point = compiled.districts[String(id)].save_fallback_uv if compiled.districts.has(String(id)) else Vector2(INF, INF)
	if not point is Vector2: return {"matched": true, "ok": false, "error": "REGION_ENTRY_UNAUTHORED"}
	var version: int = legacy_version if legacy_version >= 0 else int(compiled.districts.get(String(id), {}).get("legacy_version", -1))
	var entry: Dictionary = Alias.arrive(compiled, String(id), point, version, extension)
	if entry.get("ok") != true: return {"matched": true, "ok": false, "error": entry.get("error", "ARRIVAL")}
	return _queue_setup(loaded, String(id), point, entry.foot)

static func prepare_authored(target: Dictionary, expected_author_sha: String) -> Dictionary:
	# This API is reachable only after the dispatcher authenticates the actual
	# compiled ExitZone row and current LIVE owner. It is not a nearest-safe API.
	if not _pending.is_empty(): return {"ok": false, "error": "REGION_REQUEST_BUSY"}
	var manifest: Dictionary = _manifest(expected_author_sha)
	if manifest.is_empty(): return {"ok": false, "error": "REGION_NOT_SEALED"}
	var region_id: String = String(target.get("region_id", ""))
	var logical: String = String(target.get("logical_id", ""))
	if ALIASES.get(logical) != region_id: return {"ok": false, "error": "REGION_AUTHORED_TARGET_ID"}
	var loaded: Dictionary = _load_region(manifest, region_id, expected_author_sha)
	if loaded.get("ok") != true: return loaded
	var foot: Vector2 = Compiler.vec(target.get("foot_px"))
	if Compiler.district_at(loaded.compiled, foot) != logical or not Compiler.safe_body(loaded.compiled, foot, Vector2(17, 12)) or not Compiler.npc_route_clear(loaded.compiled, foot, foot, Vector2(17, 12)): return {"ok": false, "error": "REGION_AUTHORED_TARGET_BODY"}
	var navigation: Dictionary = Alias.navigation(loaded.compiled, foot)
	if navigation.get("ok") != true: return navigation
	return _queue_setup(loaded, logical, navigation.current_field_spawn, foot)

static func _manifest(expected_sha: String) -> Dictionary:
	var manifest: Dictionary = Compiler.read_json(MANIFEST_PATH, expected_sha)
	if manifest.get("schema") != "REGION27D_RUNTIME_MANIFEST_V1" or manifest.get("adoption_enabled") != true: return {}
	if not manifest.get("author") is Dictionary or not manifest.get("compiled_bindings") is Dictionary or not manifest.get("runtime_modules") is Dictionary: return {}
	return manifest

static func _load_region(manifest: Dictionary, region_id: String, expected_manifest_sha: String) -> Dictionary:
	var contexts: Dictionary = {}
	var sources: Dictionary = {MANIFEST_PATH: expected_manifest_sha}
	var author: Dictionary = Compiler.read_json(String(manifest.author.get("path", "")), String(manifest.author.get("sha256", "")))
	if author.is_empty(): return {"ok": false, "error": "REGION_COMPILE_AUTHOR_SOURCE"}
	sources[manifest.author.path] = manifest.author.sha256
	var modules: Dictionary = manifest.get("runtime_modules", {})
	if modules.is_empty() or not Compiler.source_pass(modules): return {"matched": true, "ok": false, "error": "REGION_MODULES_UNSEALED"}
	sources.merge(modules, true)
	# Compiling author geometry is a Root-only publication step, not a repeated
	# transition-time task. The runtime consumes its exact immutable Variant bin.
	var compiled_binding: Dictionary = manifest.compiled_bindings.get(region_id, {})
	var path: String = String(compiled_binding.get("path", ""))
	if path.is_empty() or FileAccess.get_sha256(path) != compiled_binding.get("sha256", ""): return {"ok": false, "error": "REGION_COMPILED_BIN_SOURCE"}
	var raw: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if raw.size() != int(compiled_binding.get("bytes", -1)): return {"ok": false, "error": "REGION_COMPILED_BIN_LENGTH"}
	var decoded: Variant = bytes_to_var(raw)
	if not decoded is Dictionary or not Compiler.plain(decoded) or decoded.get("schema") != Compiler.SCHEMA or decoded.get("ok") != true or decoded.get("id") != region_id or decoded.get("revision") != author.get("revision"): return {"ok": false, "error": "REGION_COMPILED_BIN_IDENTITY"}
	var compiled: Dictionary = decoded
	if not compiled.get("sources") is Dictionary or not Compiler.source_pass(compiled.sources): return {"ok": false, "error": "REGION_COMPILED_CONTENT_SOURCE"}
	sources[path] = compiled_binding.sha256
	for logical: String in compiled.get("source_context_ids", compiled.districts.keys()):
		var binding: Dictionary = author.terminal_bindings.get(logical, {})
		var terminal: Dictionary = Compiler.load_terminal(binding)
		if terminal.is_empty(): return {"matched": true, "ok": false, "error": "REGION_TERMINAL_MISSING:" + logical}
		sources.merge(terminal.sources, true); sources[binding.path] = binding.sha256
		var context: Dictionary = Terminal.source_context(terminal)
		if context.get("ok") != true: return {"matched": true, "ok": false, "error": context.get("error", "REGION_SOURCE_CONTEXT")}
		contexts[logical] = {"source_scene": context.source_scene, "terminal": terminal}
	for source_path: String in compiled.sources:
		if sources.has(source_path) and sources[source_path] != compiled.sources[source_path]: return {"matched": true, "ok": false, "error": "REGION_COMPILED_SOURCE_CONFLICT:" + source_path}
		sources[source_path] = compiled.sources[source_path]
	var dynamic: Dictionary = manifest.get("phase_projector", {})
	path = String(dynamic.get("path", ""))
	if path.is_empty() or FileAccess.get_sha256(path) != dynamic.get("sha256", ""): return {"matched": true, "ok": false, "error": "REGION_TASK_PROJECTOR_UNSEALED"}
	var projector: Variant = load(path)
	if not projector is GDScript or not projector.has_method("project"): return {"matched": true, "ok": false, "error": "REGION_TASK_PROJECTOR_API"}
	sources[path] = dynamic.sha256
	return {"ok": true, "compiled": compiled, "sources": sources, "projector": projector, "contexts": contexts}

static func _queue_setup(loaded: Dictionary, logical: String, legacy_uv: Vector2, foot: Vector2) -> Dictionary:
	_serial += 1
	_pending = {"serial": _serial, "logical_id": logical, "region": loaded.compiled, "sources": loaded.sources, "foot": foot, "projector": loaded.projector, "inputs": loaded.contexts}
	return {"matched": true, "ok": true, "request_serial": _serial, "logical_id": logical, "region_id": loaded.compiled.id, "legacy_uv": legacy_uv, "local_layout_version": loaded.compiled.districts[logical].legacy_version, "field_scene": FIELD_SCENE, "world_uv": foot / loaded.compiled.size}

static func take_setup(field: Node) -> bool:
	if _pending.is_empty(): return false
	var payload: Dictionary = SceneRouter.get_field_payload()
	if payload.get("region27d_request_serial") != _pending.serial or payload.get("scene_id") != _pending.region.id or payload.get("logical_scene_id") != _pending.logical_id: return false
	var data: Dictionary = _pending; _pending = {}
	var bridge: RefCounted = data.projector.new()
	if bridge == null or not bridge.has_method("project_all"): return false
	var phase := Phase.new()
	var dynamic: Callable = Callable(phase, "project").bind(bridge, data.inputs, data.region)
	return field.call("adopt_compiled", data.region, data.sources, data.foot, dynamic, data.inputs, bridge)

static func abort_pending() -> void:
	_pending.clear()
