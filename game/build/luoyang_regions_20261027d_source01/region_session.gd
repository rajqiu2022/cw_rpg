extends RefCounted
## A real new lease. It never claims to be a C/Family/Temple legacy owner.
const Compiler = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const FIELD_SCRIPT := "res://build/luoyang_regions_20261027d_source01/region_field.gd"
var _field: WeakRef
var _scene: WeakRef
var _layout: WeakRef
var _revision: int = 0
var _first: Dictionary = {}
var _compiled: Dictionary = {}
var _phase: String = "EMPTY"
var _pins: Dictionary = {}
var _compiled_bytes: PackedByteArray = PackedByteArray()
var _layout_bytes: PackedByteArray = PackedByteArray()
var _scene_bytes: PackedByteArray = PackedByteArray()
var _final: Dictionary = {}
var _compiled_sha: String = ""
var _field_script: Script
var _scene_script: Script
var _layout_script: Script

static func _storage(resource: Resource) -> Dictionary:
	var result: Dictionary = {}
	var script: Script = resource.get_script() as Script
	result["@script"] = {"path": script.resource_path, "instance": script.get_instance_id()} if script != null else {}
	for property: Dictionary in resource.get_property_list():
		var key: String = String(property.name)
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or key == "script": continue
		var value: Variant = resource.get(key)
		if value is WalkableMapLayout: result[key] = _storage(value)
		elif value is Resource: result[key] = {"path": value.resource_path, "instance": value.get_instance_id()}
		else: result[key] = value
	return result

func begin(field: Node, scene: SceneScript, compiled: Dictionary, declared_sources: Dictionary) -> bool:
	if _phase != "EMPTY" or field == null or scene == null or scene.map_layout == null or not compiled.get("ok", false): return false
	var field_script: Script = field.get_script() as Script
	var scene_script: Script = scene.get_script() as Script
	var layout_script: Script = scene.map_layout.get_script() as Script
	if field_script == null or field_script.resource_path != FIELD_SCRIPT or scene_script == null or layout_script == null: return false
	if String(scene.scene_id) != compiled.get("id") or Vector2(scene.map_layout.design_size) != compiled.get("size"): return false
	for path: String in [FIELD_SCRIPT, scene.resource_path, scene_script.resource_path, layout_script.resource_path]:
		if path.is_empty() or not declared_sources.has(path): return false
	if not compiled.get("sources") is Dictionary or compiled.sources.is_empty(): return false
	for path: String in compiled.sources:
		if declared_sources.get(path) != compiled.sources[path]: return false
	if not Compiler.source_pass(declared_sources): return false
	_field = weakref(field); _scene = weakref(scene); _layout = weakref(scene.map_layout)
	_field_script = field_script; _scene_script = scene_script; _layout_script = layout_script
	_revision = compiled.revision; _compiled = compiled.duplicate(true); _first = declared_sources.duplicate(true)
	_compiled_bytes = var_to_bytes(compiled); _layout_bytes = var_to_bytes(_storage(scene.map_layout)); _scene_bytes = var_to_bytes(_storage(scene)); _phase = "FIRST"
	var hash := HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(_compiled_bytes); _compiled_sha = hash.finish().hex_encode()
	return true

func matches(field: Node, scene: SceneScript) -> bool:
	return _phase in ["FIRST", "LIVE", "PARKED"] and _field.get_ref() == field and _scene.get_ref() == scene and scene != null and _layout.get_ref() == scene.map_layout and _field_script == field.get_script() and _scene_script == scene.get_script() and _layout_script == scene.map_layout.get_script() and _compiled.revision == _revision

func finalize(field: Node, scene: SceneScript, compiled: Dictionary) -> bool:
	if _phase != "FIRST" or not content_matches(field, scene, compiled) or not Compiler.source_pass(_first): return false
	_final = _first.duplicate(true)
	_phase = "LIVE"
	return true

func safe_foot(field: Node, scene: SceneScript, foot: Vector2) -> bool:
	return _phase == "LIVE" and matches(field, scene) and Compiler.safe_body(_compiled, foot, Vector2(17, 12))

func pin(reason: String) -> bool:
	if _phase != "LIVE" or reason.is_empty(): return false
	_pins[reason] = int(_pins.get(reason, 0)) + 1
	return true

func unpin(reason: String) -> void:
	if not _pins.has(reason): return
	_pins[reason] -= 1
	if _pins[reason] <= 0: _pins.erase(reason)

func can_park() -> bool:
	return _phase == "LIVE" and _pins.is_empty()

func park(field: Node, scene: SceneScript) -> bool:
	if not can_park() or not matches(field, scene): return false
	_phase = "PARKED"
	return true

func resume(field: Node, scene: SceneScript, compiled: Dictionary) -> bool:
	if _phase != "PARKED" or not content_matches(field, scene, compiled) or not Compiler.source_pass(_first): return false
	_phase = "LIVE"
	return true

func content_matches(field: Node, scene: SceneScript, compiled: Dictionary) -> bool:
	return matches(field, scene) and var_to_bytes(compiled) == _compiled_bytes and var_to_bytes(_storage(scene.map_layout)) == _layout_bytes and var_to_bytes(_storage(scene)) == _scene_bytes

func revalidate_boundary(field: Node, scene: SceneScript, compiled: Dictionary) -> bool:
	return _phase == "LIVE" and _first == _final and content_matches(field, scene, compiled) and Compiler.source_pass(_first)

func release() -> void:
	_phase = "RELEASED"; _compiled.clear(); _first.clear(); _final.clear(); _pins.clear(); _compiled_bytes.clear(); _layout_bytes.clear(); _scene_bytes.clear()
	_field_script = null; _scene_script = null; _layout_script = null

func receipt() -> Dictionary:
	return {"owner_kind": "REGION_27D", "token": get_instance_id(), "phase": _phase, "revision": _revision, "finalized": _phase in ["LIVE", "PARKED"], "source_first": _first.duplicate(true), "source_final": _final.duplicate(true), "compiled_SHA256": _compiled_sha, "same_field": _field != null and _field.get_ref() != null, "field_instance": _field.get_ref().get_instance_id() if _field != null and _field.get_ref() != null else 0, "scene_instance": _scene.get_ref().get_instance_id() if _scene != null and _scene.get_ref() != null else 0, "layout_instance": _layout.get_ref().get_instance_id() if _layout != null and _layout.get_ref() != null else 0}
