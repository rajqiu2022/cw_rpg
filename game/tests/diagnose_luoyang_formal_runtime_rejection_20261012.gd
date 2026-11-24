extends SceneTree
## Read-only component evidence. Never opens a Field or changes navigation.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const ID := &"ch4_s0_luoyang_gate"
const PATH := "res://data/scenes/ch4_s0_luoyang_gate.tres"
var differences: Array[Dictionary] = []

func _init() -> void:
	call_deferred("_run")

func _description(value: Variant) -> Dictionary:
	var result := {"type": typeof(value), "value": str(value)}
	if typeof(value) == TYPE_FLOAT:
		result["float64_hex"] = PackedFloat64Array([value]).to_byte_array().hex_encode()
		result["native32_hex"] = PackedFloat32Array([value]).to_byte_array().hex_encode()
	return result

func _diff(a: Variant, b: Variant, path: Array, visual: bool) -> void:
	if differences.size() >= 100: return
	var equal: bool = C.equal_visual_serialized_value(a, b, path) if visual else C._equal_value(a, b)
	if equal: return
	if typeof(a) == typeof(b) and a is Array and a.size() == b.size():
		for index: int in a.size(): _diff(a[index], b[index], path + [index], visual)
		return
	if typeof(a) == typeof(b) and a is Dictionary and a.size() == b.size():
		for key: Variant in a:
			if not b.has(key):
				differences.append({"path": path + [key], "kind": "missing_actual_key"})
			else: _diff(a[key], b[key], path + [key], visual)
		return
	differences.append({"path": path, "expected": _description(a), "actual": _description(b), "visual_adapter": visual})

func _run() -> void:
	var platform := root.get_node("PlatformBridge")
	platform.call("set_checkpoint_saves_suspended", true)
	var sources: Dictionary = {}
	for path: String in [get_script().resource_path, PATH, C.layout_path(ID), C.candidate_path(ID), "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd", "res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd", "res://scripts/autoload/scene_router.gd"]:
		sources[path] = FileAccess.get_sha256(path)
	var scene := ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var report := {"scope": "READONLY_FORMAL_CITY_RUNTIME_COMPONENT_DIAGNOSTIC", "sources": sources, "scene_present": scene != null, "scene_id": String(scene.scene_id) if scene != null else "", "resource_path": scene.resource_path if scene != null else "", "is_v3": C.is_v3(scene), "checkpoint_suspended": platform.call("is_checkpoint_saves_suspended"), "Field_input_tested": false, "navigation_changed": false}
	var resolved: SceneScript = C.resolve_scene(scene)
	report["resolved"] = resolved != null
	report["resolve_C_errors"] = C.errors()
	report["resolve_BASE_errors"] = C.BASE.errors()
	var expected: SceneScript = C.materialize(ID)
	report["materialize_present"] = expected != null
	report["materialize_C_errors"] = C.errors()
	report["materialize_BASE_errors"] = C.BASE.errors()
	if scene != null:
		report["semantic_fidelity"] = C.semantic_fidelity(scene)
		report["semantic_BASE_errors"] = C.BASE.errors()
	if expected != null and scene != null:
		for name: String in ["background_path", "streamed_background", "player_spawn", "player_visual_scale", "actor_positions_are_feet", "npcs", "animated_props", "scene_objects", "collision_rects", "exits", "trigger_zones"]:
			_diff(expected.get(name), scene.get(name), ["scene", name], false)
		for property: Dictionary in expected.map_layout.get_property_list():
			var name := String(property.name)
			if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or name in ["script", "resource_path", "resource_name", "resource_local_to_scene"]: continue
			_diff(expected.map_layout.get(name), scene.map_layout.get(name), ["visual_objects"] if name == "visual_objects" else ["layout", name], name == "visual_objects")
	report["strict_differences"] = differences
	var actual_router_result: SceneScript = root.get_node("SceneRouter").call("_load_field_scene_def", ID)
	report["actual_router_target_loaded"] = actual_router_result != null
	report["router_C_errors"] = C.errors()
	report["router_BASE_errors"] = C.BASE.errors()
	var after: Dictionary = {}
	for path: String in sources: after[path] = FileAccess.get_sha256(path)
	report["source_unchanged"] = sources == after
	print("LUOYANG_FORMAL_RUNTIME_COMPONENTS=" + JSON.stringify(report))
	# Diagnostic success means completed evidence, never a production approval.
	quit(0 if sources == after and platform.call("is_checkpoint_saves_suspended") == true else 1)
