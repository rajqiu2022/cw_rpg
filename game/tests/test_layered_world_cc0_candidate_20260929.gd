extends SceneTree

var _checks := 0
var _failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://data/scenes/world_map_layered_cc0_candidate_20260929.tres") as SceneScript
	_check(scene != null and scene.map_layout != null, "isolated licensed-asset candidate loads")
	if scene == null or scene.map_layout == null:
		quit(1)
		return
	var layout := scene.map_layout
	for official_id in ["world_map_jianghu", "world_map_jianghu_v13_staging", "world_map_layered_prototype_20260928"]:
		var official := load("res://data/scenes/%s.tres" % official_id) as SceneScript
		var isolated := official != null and official.map_layout != null
		if isolated:
			for item: Dictionary in official.map_layout.visual_objects:
				if item.get("id", "") == "cc0_boulder_01":
					isolated = false
		_check(isolated, "boulder is absent from %s" % official_id)
	_check(layout.visual_objects.size() == 2, "candidate has independent city and boulder sprites")
	var rock: Dictionary = layout.visual_objects[1]
	_check(rock.get("id", "") == "cc0_boulder_01", "boulder has a stable object id")
	_check(rock.get("sort_by_feet", false) and rock.has("depth_sort_foot_y") and rock.has("collision_size"), "boulder registers visual depth and foot collision together")
	var texture := load(rock.get("texture", "")) as Texture2D
	_check(texture != null, "CC0-derived boulder sprite imports")
	if texture != null:
		var image := texture.get_image()
		_check(image.get_pixel(0, 0).a < 0.1, "boulder image has transparent exterior")
		_check(image.get_pixel(image.get_width() / 2, image.get_height() / 2).a > 0.8, "boulder has opaque stone body")
	var field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	field.set("_current_scene", scene)
	field.set("_screen_size", Vector2(1536, 1024))
	field.set("_world_size", Vector2(1536, 1024))
	field.call("_load_walkable_mask", layout.walkable_mask_path)
	field.call("_rebuild_walkability_collision_entries", layout.blockers, layout.visual_objects)
	for probe: Dictionary in layout.walkable_probes:
		var position: Vector2 = probe.get("pos", Vector2.ZERO)
		_check(field.call("_is_walkable_by_mask", position) and not field.call("_is_blocked_by_layout", position), "walkable %s" % probe.get("id", ""))
	for probe: Dictionary in layout.blocked_probes:
		var position: Vector2 = probe.get("pos", Vector2.ZERO)
		_check(not field.call("_is_walkable_by_mask", position) or field.call("_is_blocked_by_layout", position), "blocked %s" % probe.get("id", ""))
	var foot_y: float = rock.get("depth_sort_foot_y", 0.0)
	_check(foot_y > 0.62 and foot_y < 0.74, "boulder depth line follows its ground-contact band")
	field.free()
	print("[LayeredWorldCC0Candidate20260929] checks=%d failed=%d" % [_checks, _failed])
	quit(_failed)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
