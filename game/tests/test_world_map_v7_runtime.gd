extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var router := root.get_node_or_null("SceneRouter")
	_check(router != null, "SceneRouter autoload exists")
	if router == null:
		_finish()
		return
	router.set("_field_payload", {"scene_id": &"world_map_jianghu", "player_spawn": Vector2(0.225, 0.850)})
	router.set("_current_field_id", &"world_map_jianghu")
	var packed := load("res://scenes/field_walkable.tscn") as PackedScene
	var field := packed.instantiate() if packed != null else null
	_check(field != null, "field walkable instantiates")
	if field == null:
		_finish()
		return
	root.add_child(field)
	await process_frame
	await process_frame

	var world := field.get_node_or_null("WorldContainer") as Node2D
	var player := world.get_node_or_null("ActorLayer/Player") as Player if world != null else null
	var camera := player.get_node_or_null("WorldCamera") as Camera2D if player != null else null
	_check(world != null and world.position.is_equal_approx(Vector2.ZERO), "scrolling keeps WorldContainer fixed")
	_check(world != null and world.scale.is_equal_approx(Vector2.ONE), "scrolling keeps physics world unscaled")
	_check(camera != null and camera.position_smoothing_speed >= 20.0, "world camera no longer uses the old slow drag setting")
	_check(camera != null and camera.zoom.is_equal_approx(Vector2.ONE), "world map uses integer 1.0 camera zoom")
	_check(field.get("_walkable_mask_image") is Image, "runtime loaded the v8 pixel navigation mask")
	_check(field.get("_world_camera") == camera, "controller tracks the live Camera2D")
	if camera != null:
		_check(camera.limit_right == 2304 and camera.limit_bottom == 1536, "camera limits match the optimized native world image")
	field.queue_free()
	await process_frame
	_finish()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)


func _finish() -> void:
	print("[WorldMapV8Runtime] failures=%d" % failures)
	quit(1 if failures > 0 else 0)
