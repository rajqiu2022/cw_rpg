extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var router := root.get_node("SceneRouter")
	router.go_field_smart(&"world_map_layered_prototype_20260928", Vector2(0.50, 0.80))
	for tick in range(120):
		await create_timer(0.05).timeout
		if current_scene != null and current_scene.has_method("_is_inside_walkable_screen"):
			break
	await create_timer(1.0).timeout
	for frame in range(10):
		await process_frame
	var output := "res://screenshots/world_map_layered_prototype_20260928.png"
	var error := root.get_texture().get_image().save_png(output)
	if error != OK:
		push_error("Could not save layered world prototype capture: %s" % output)
		quit(1)
		return
	print("[LayeredWorldPrototypeCapture] " + output)
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	quit(0)
