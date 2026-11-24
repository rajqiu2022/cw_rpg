extends SceneTree

var _checks := 0
var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	var world := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	field.set("_current_scene", world)
	field.call("_load_walkable_mask", world.map_layout.walkable_mask_path)
	for sample in [
		Vector2(1450, 555), # East Sea sailing lane from the report.
		Vector2(1280, 520), # Harbor inlet.
		Vector2(1210, 340), # Luoyang roofs.
		Vector2(1340, 330), # Luoyang courtyard.
		Vector2(720, 500),  # Xiangzhou walled city.
		Vector2(1200, 720), # Jinling city interior.
	]:
		_check(not field.call("_is_walkable_by_mask", sample / Vector2(1536.0, 1024.0)), "world map blocks sea/city sample %s" % sample)
	for portal_id in ["luoyang", "east_sea_port", "jinling", "xiangzhou", "bailu_ferry", "mingwu"]:
		var portal: Dictionary = _find_by_id(world.map_layout.portals, portal_id)
		_check(not portal.is_empty(), "%s portal still exists" % portal_id)
		if not portal.is_empty():
			_check(field.call("_is_walkable_by_mask", portal.get("pos", Vector2.ZERO)), "%s portal remains walkable" % portal_id)

	var jinling := load("res://data/scenes/openworld_jinling_city.tres") as SceneScript
	field.set("_current_scene", jinling)
	field.call("_rebuild_walkability_collision_entries", jinling.map_layout.blockers, jinling.map_layout.visual_objects)
	for prop_id in ["southwest_bridge_lantern_base", "southeast_bridge_lantern_base"]:
		var base: Dictionary = _find_by_id(jinling.map_layout.blockers, prop_id)
		var foreground: Dictionary = _find_by_id(jinling.map_layout.occluders, prop_id.trim_suffix("_base"))
		_check(not base.is_empty() and field.call("_is_blocked_by_layout", base.get("pos", Vector2.ZERO)), "%s blocks actor feet" % prop_id)
		_check(not foreground.is_empty() and foreground.get("depth_mode", "") == "y_sort", "%s owns a Y-depth foreground" % prop_id)
		if not foreground.is_empty():
			var occluder := DynamicOccluder2D.new()
			var background := load(jinling.background_path) as Texture2D
			_check(occluder.configure(foreground, background, Vector2(3072, 2048)), "%s foreground configures against the runtime art" % prop_id)
			occluder.update_player_position(Vector2(0.39, 0.70))
			_check(occluder.visible, "%s covers an actor behind the lantern" % prop_id)
			occluder.update_player_position(Vector2(0.39, 0.80))
			_check(not occluder.visible, "%s leaves an actor in front unobscured" % prop_id)
			occluder.free()

	var mingwu := load("res://data/maps/ch7_s2_mingwu_tea_town_layout_v1.tres") as WalkableMapLayout
	var outer_gate: Dictionary = _find_by_id(mingwu.portals, "enter_mingwu_outer_court")
	_check(not outer_gate.is_empty() and "未解锁" not in String(outer_gate.get("locked_label", "")) and "庄主外出" in String(outer_gate.get("locked_label", "")), "locked Mingwu gate speaks to the player in-world")
	field.free()
	print("[WorldLayerContract20260928] checks=%d failed=%d" % [_checks, _failed])
	quit(_failed)


func _find_by_id(entries: Array, wanted: String) -> Dictionary:
	for raw: Variant in entries:
		if raw is Dictionary and String(raw.get("id", "")) == wanted:
			return raw
	return {}


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
