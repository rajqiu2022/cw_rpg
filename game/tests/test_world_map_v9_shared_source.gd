extends SceneTree

# Kept at the historical path so existing CI invocations continue to work.
# The assertions now lock the production v12 realistic open-plain overworld contract.

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := root.get_node("GameState")
	state.set_flag(&"seen_ch7_route_choice", true)
	var router := root.get_node("SceneRouter")
	router.go_field_smart(&"world_map_jianghu", Vector2(720.0 / 1536.0, 430.0 / 1024.0))
	for i in range(100):
		await create_timer(0.1).timeout
		if current_scene != null and current_scene.has_method("_is_inside_walkable_screen"):
			break
	var field := current_scene
	_check(field != null and field.has_method("_is_inside_walkable_screen"), "walkable field loaded")
	if field == null or not field.has_method("_is_inside_walkable_screen"):
		quit(1)
		return
	var world: Node2D = field.get("world_container")
	var size: Vector2 = field.get("_screen_size")
	var actor: Player = field.get("_player")
	var foot: CollisionShape2D = actor.get_node("CollisionShape2D")
	_check(is_zero_approx(actor.get_depth_sort_y() - actor.global_position.y), "visual feet and navigation root coincide")
	_check(foot.position.is_zero_approx() and foot.shape is CircleShape2D and is_equal_approx(foot.shape.radius, 5.0), "world travel uses the surveyed 5px foot contact")
	_check(size.is_equal_approx(Vector2(2304, 1536)), "runtime uses the v12 logical mask size")

	var layout := load("res://data/maps/world_map_jianghu_layout_v12.tres") as WalkableMapLayout
	var scene_def := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	_check(layout != null and layout.schema_version == 12, "v12 layout loads")
	_check(scene_def != null and scene_def.map_layout == layout, "production scene owns the v12 layout")
	_check(scene_def.background_path.ends_with("bg_world_map_jianghu_v12_2304.png"), "production scene owns the v12 realistic synchronized background")
	_check(layout.walkable_mask_path.ends_with("world_map_jianghu_walk_v12.png"), "v12 layout owns the synchronized navigation mask")
	_check(scene_def.streamed_background != null and scene_def.streamed_background.mobile_preview_path.ends_with("bg_world_map_jianghu_v12_2304.png"), "desktop/mobile streaming set is v12")

	for portal: Dictionary in layout.portals:
		var pos: Vector2 = portal.get("pos", Vector2.ZERO)
		_check(field.call("_is_inside_walkable_screen", world.to_global(pos * size)), "portal has walkable foot clearance: " + str(portal.get("id")))
		_check(bool(portal.get("show_destination_label", false)), "portal keeps its destination name visible: " + str(portal.get("id")))

	var road_points := [
		Vector2(455, 470), Vector2(760, 470), Vector2(1040, 480),
		Vector2(760, 610), Vector2(330, 565), Vector2(1400, 595),
		# User-reported visible road between the central plain and Mingwu.
		Vector2(1160, 760), Vector2(1210, 835), Vector2(1250, 895),
	]
	var blocked_points := [Vector2(35, 35), Vector2(730, 35), Vector2(575, 340), Vector2(1210, 340), Vector2(1520, 560), Vector2(970, 940), Vector2(700, 1000)]
	for point in road_points:
		_check(field.call("_is_inside_walkable_screen", world.to_global(point / Vector2(1536, 1024) * size)), "surveyed open field/road: " + str(point))
	for point in blocked_points:
		_check(not field.call("_is_inside_walkable_screen", world.to_global(point / Vector2(1536, 1024) * size)), "surveyed terrain remains blocked: " + str(point))

	for old_point in [Vector2(35, 35), Vector2(575, 340), Vector2(1520, 560)]:
		var old_spawn: Vector2 = old_point / Vector2(1536, 1024)
		var repaired: Vector2 = field.call("_resolve_player_spawn", scene_def, old_spawn)
		_check(field.call("_world_map_spawn_has_foot_clearance", scene_def, repaired), "blocked save is repaired onto safe terrain: " + str(old_point))

	var before := world.position
	world.position += Vector2(-187, 123)
	_check(field.call("_is_inside_walkable_screen", world.to_global(Vector2(760, 470) / Vector2(1536, 1024) * size)), "camera translation retains open-plain alignment")
	_check(not field.call("_is_inside_walkable_screen", world.to_global(Vector2(1210, 340) / Vector2(1536, 1024) * size)), "camera translation retains city-roof blocking")
	world.position = before

	var exit_nodes: Array = field.get("_exit_nodes")
	_check(exit_nodes.size() == layout.portals.size(), "all authored destination markers are instantiated")
	for zone in exit_nodes:
		var prompt := zone.get_node_or_null("Prompt") as Label
		_check(bool(zone.get("always_show_destination")) and prompt != null and prompt.visible and not prompt.text.strip_edges().is_empty(), "runtime marker displays its destination name")

	print("[WorldMapV12Realistic] checks=%d failures=%d" % [checks, failures])
	current_scene.queue_free()
	for i in range(5):
		await process_frame
	quit(1 if failures else 0)


func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[WorldMapV11Realistic] " + description)
