extends SceneTree

var _checks := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("[PASS] ", label)
	else:
		_failed += 1
		push_error("[FAIL] " + label)


func _run() -> void:
	var scene := load("res://data/scenes/world_map_native_coast_gen_v2_candidate_20260929.tres") as SceneScript
	_check(scene != null and scene.map_layout != null, "isolated generated-coast candidate loads")
	if scene == null or scene.map_layout == null:
		quit(1)
		return
	var layout := scene.map_layout
	_check(layout.design_size == Vector2i(1536, 1024), "visual and mask share logical size")
	var background := load(scene.background_path) as Texture2D
	var mask := load(layout.walkable_mask_path) as Texture2D
	_check(background != null and background.get_size() == Vector2(1536, 1024), "clean plate imports at native size")
	_check(mask != null and mask.get_size() == Vector2(1536, 1024), "pixel-derived navigation imports at native size")
	_check(layout.visual_objects.size() == 2, "separate CC0 boulder and contact shadow; base stays structure-free")
	var shadow: Dictionary = layout.visual_objects[0]
	var rock: Dictionary = layout.visual_objects[1]
	_check(shadow.get("texture", "").ends_with("boulder_contact_shadow_v1.svg") and not shadow.has("collision_size"), "contact shadow cannot block movement")
	_check(rock.get("sort_by_feet", false) and rock.has("depth_sort_foot_y") and rock.has("collision_size"), "rock owns depth and foot collision together")
	_check(layout.portals.is_empty(), "candidate cannot route into formal world")
	for official_id in ["world_map_jianghu", "world_map_jianghu_v13_staging"]:
		var official := load("res://data/scenes/%s.tres" % official_id) as SceneScript
		_check(official != null and official.background_path != scene.background_path, "candidate does not replace %s" % official_id)
	var field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	field.set("_current_scene", scene)
	field.set("_screen_size", Vector2(1536, 1024))
	field.set("_world_size", Vector2(1536, 1024))
	field.call("_load_walkable_mask", layout.walkable_mask_path)
	field.call("_rebuild_walkability_collision_entries", layout.blockers, layout.visual_objects)
	for probe: Dictionary in layout.walkable_probes:
		var pos: Vector2 = probe.get("pos", Vector2.ZERO)
		_check(field.call("_is_walkable_by_mask", pos) and not field.call("_is_blocked_by_layout", pos), "walkable " + String(probe.get("id", "")))
	for probe: Dictionary in layout.blocked_probes:
		var pos: Vector2 = probe.get("pos", Vector2.ZERO)
		_check(not field.call("_is_walkable_by_mask", pos) or field.call("_is_blocked_by_layout", pos), "blocked " + String(probe.get("id", "")))
	field.free()
	print("[NativeCoastGeneratedCandidate] checks=%d failed=%d" % [_checks, _failed])
	quit(_failed)
