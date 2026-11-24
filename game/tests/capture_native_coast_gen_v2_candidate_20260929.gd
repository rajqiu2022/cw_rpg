extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var router := root.get_node("SceneRouter")
	router.go_field_smart(&"world_map_native_coast_gen_v2_candidate_20260929", Vector2(0.350, 0.430))
	for tick in range(120):
		await create_timer(0.05).timeout
		if current_scene != null and current_scene.has_method("_is_inside_walkable_screen"):
			break
	await create_timer(1.0).timeout
	for frame in range(10):
		await process_frame
	var output := "res://screenshots/world_map_native_coast_gen_v2_candidate_20260929.png"
	if root.get_texture().get_image().save_png(output) != OK:
		push_error("Could not save native coast gameplay capture")
		quit(1)
		return
	print("[NativeCoastGameplayCapture] ", output)
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	quit(0)
