extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var router := root.get_node("SceneRouter")
	router.set("_current_field_id", &"openworld_bianzhou_city")
	router.go_bounty_board(&"bianzhou")
	for tick in range(120):
		await create_timer(0.05).timeout
		if current_scene != null and current_scene.name == "BountyBoard":
			break
	await create_timer(0.8).timeout
	for frame in range(8):
		await process_frame
	var output := "res://screenshots/bounty_board_v2.png"
	var error := root.get_texture().get_image().save_png(output)
	if error != OK:
		push_error("Could not save bounty-board capture: %s" % output)
		quit(1)
		return
	print("[BountyBoardV2Capture] " + output)
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	quit(0)
