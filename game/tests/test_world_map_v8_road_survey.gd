extends SceneTree

var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state := root.get_node("GameState")
	state.set_flag(&"seen_ch7_route_choice", true)
	var router := root.get_node("SceneRouter")
	router.go_field_smart(&"world_map_jianghu", Vector2(746.0 / 1920.0, 495.0 / 1280.0))
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
	_check(is_zero_approx(actor.get_depth_sort_y() - actor.global_position.y), "visual feet and navigation root coincide")
	for style in [&"sword", &"dao", &"staff", &"palm", &"hidden", &"sword"]:
		actor.set_weapon_style(style)
		_check(is_zero_approx(actor.get_depth_sort_y() - actor.global_position.y), "weapon swap retains foot anchor " + str(style))
	var foot: CollisionShape2D = actor.get_node("CollisionShape2D")
	_check(foot.position.is_zero_approx() and foot.shape is CircleShape2D and is_equal_approx(foot.shape.radius, 5.0), "world travel collision uses surveyed 5px contact radius")
	_check(size.is_equal_approx(Vector2(2304, 1536)), "runtime uses mask logical size, independent of HD chunks")
	var layout := load("res://data/maps/world_map_jianghu_layout_v8.tres") as WalkableMapLayout
	var scene_def := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	for old_point in [Vector2(500,433), Vector2(610,437), Vector2(1287,320), Vector2(1765,567)]:
		var old_spawn: Vector2 = old_point / Vector2(1920,1280)
		var repaired: Vector2 = field.call("_resolve_player_spawn", scene_def, old_spawn)
		_check(field.call("_world_map_spawn_has_foot_clearance", scene_def, repaired), "old save returns to safe road " + str(old_point))
		_check((repaired * size).distance_to(old_spawn * size) < 210.0, "old save stays in its region " + str(old_point))
	for portal in layout.portals:
		var pos: Vector2 = portal.get("pos", Vector2.ZERO)
		_check(field.call("_is_inside_walkable_screen", world.to_global(pos * size)), "portal on actual road: " + str(portal.get("id")))
	# RGB survey puts the village road centre at y=741; y=726 is the old uphill edge, not the visible road.
	var road_points := [Vector2(746,495), Vector2(389,342), Vector2(776,568), Vector2(911,1034), Vector2(490,741), Vector2(1173,837), Vector2(895,414), Vector2(356,199), Vector2(346,343), Vector2(211,662)]
	var blocked_points := [Vector2(500,433), Vector2(610,437), Vector2(1287,320), Vector2(969,506), Vector2(1034,730), Vector2(681,969), Vector2(278,291), Vector2(1830,576), Vector2(1690,849), Vector2(1765,567)]
	for point in road_points:
		_check(field.call("_is_inside_walkable_screen", world.to_global(point / Vector2(1920,1280) * size)), "visible road " + str(point))
	for point in blocked_points:
		_check(not field.call("_is_inside_walkable_screen", world.to_global(point / Vector2(1920,1280) * size)), "rock/water/roof blocked " + str(point))
	# A translated world tests the same conversion used during camera travel.
	var before := world.position
	world.position += Vector2(-187, 123)
	_check(field.call("_is_inside_walkable_screen", world.to_global(Vector2(776,568) / Vector2(1920,1280) * size)), "camera/world translation retains bridge alignment")
	_check(not field.call("_is_inside_walkable_screen", world.to_global(Vector2(500,433) / Vector2(1920,1280) * size)), "camera/world translation still blocks reported cliff")
	world.position = before
	if "capture" in OS.get_cmdline_user_args():
		await create_timer(2.5).timeout
		for i in range(20):
			await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://screenshots/world_map_v8_road_survey_20260910.png"
		root.get_texture().get_image().save_png(path)
		print("[RoadSurvey] screenshot=" + path)
	print("[RoadSurvey] checks=%d failures=%d" % [checks, failures])
	current_scene.queue_free()
	for i in range(5):
		await process_frame
	quit(1 if failures else 0)

func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[RoadSurvey] " + description)
