extends SceneTree

const CAPTURE_POINTS := {
	"center": Vector2(720.0 / 1536.0, 430.0 / 1024.0),
	"north": Vector2(780.0 / 1536.0, 145.0 / 1024.0),
	"west": Vector2(230.0 / 1536.0, 610.0 / 1024.0),
	"east": Vector2(1285.0 / 1536.0, 655.0 / 1024.0),
}

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("GameState").set_flag(&"seen_ch7_route_choice", true)
	var router := root.get_node("SceneRouter")
	var capture_name := "center"
	for arg: String in OS.get_cmdline_user_args():
		if CAPTURE_POINTS.has(arg):
			capture_name = arg
	router.go_field_smart(&"world_map_jianghu", CAPTURE_POINTS[capture_name])
	for tick in range(120):
		await create_timer(0.05).timeout
		if current_scene != null and current_scene.has_method("_is_inside_walkable_screen"):
			break
	await create_timer(1.0).timeout
	for frame in range(10):
		await process_frame
	var output := "res://screenshots/world_map_v11_realistic_%s.png" % capture_name
	var error := root.get_texture().get_image().save_png(output)
	if error != OK:
		push_error("Could not save world-map capture: %s" % output)
		quit(1)
		return
	print("[WorldMapV11Capture] " + output)
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	quit(0)
