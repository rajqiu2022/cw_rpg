extends SceneTree

const CAPTURES := [
	{"id": &"openworld_huashan_forecourt", "spawn": Vector2(0.500, 0.470), "name": "huashan_lower_stairs_opaque"},
	{"id": &"openworld_huashan_forecourt", "spawn": Vector2(0.500, 0.350), "name": "huashan_under_gate_fade"},
	{"id": &"openworld_huashan_sword_terrace", "spawn": Vector2(0.500, 0.525), "name": "huashan_sword_terrace"},
	{"id": &"openworld_huashan_waterfall_terrace", "spawn": Vector2(0.500, 0.520), "name": "huashan_waterfall_terrace"},
	{"id": &"openworld_wudang_gate", "spawn": Vector2(0.500, 0.410), "name": "wudang_lower_stairs_opaque"},
	{"id": &"openworld_wudang_gate", "spawn": Vector2(0.500, 0.320), "name": "wudang_under_gate_fade"},
	{"id": &"openworld_wudang_taiji_court", "spawn": Vector2(0.500, 0.470), "name": "wudang_taiji_court"},
	{"id": &"openworld_wudang_taiji_court", "spawn": Vector2(0.155, 0.560), "name": "wudang_taiji_behind_lantern"},
	{"id": &"openworld_wudang_purple_cloud_court", "spawn": Vector2(0.500, 0.470), "name": "wudang_purple_cloud_court"},
	{"id": &"openworld_wudang_purple_cloud_court", "spawn": Vector2(0.155, 0.560), "name": "wudang_purple_behind_lantern"},
	{"id": &"openworld_wudang_purple_cloud_court", "spawn": Vector2(0.500, 0.245), "name": "wudang_purple_hall_approach"},
	{"id": &"ch2_s4_lingyue_gate", "spawn": Vector2(0.705, 0.355), "name": "lingyue_gate_fade"},
	{"id": &"ch4_s0_luoyang_gate", "spawn": Vector2(0.500, 0.430), "name": "luoyang_gate_fade"},
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("GameState").call("reset_for_new_game")
	var router := root.get_node("SceneRouter")
	var folder := ProjectSettings.globalize_path("res://screenshots/sect_map_v3_20260913")
	DirAccess.make_dir_recursive_absolute(folder)
	for capture: Dictionary in CAPTURES:
		var requested := OS.get_cmdline_user_args()
		if not requested.is_empty() and String(capture.name) not in requested:
			continue
		router.call("go_field_smart", capture.id, capture.spawn)
		await _wait_scene(capture.id)
		var field := current_scene
		var player: Node2D = field.get("_player")
		player.position = field.call("_norm_to_screen", capture.spawn)
		field.call("_update_dynamic_occluders", capture.spawn, true)
		await create_timer(0.35).timeout
		await RenderingServer.frame_post_draw
		var output := folder.path_join(String(capture.name) + ".png")
		var error := root.get_texture().get_image().save_png(output)
		if error != OK:
			push_error("Could not save sect-map capture: " + output)
			quit(1)
			return
		print("[SectMapV3Capture] " + output)
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	quit(0)


func _wait_scene(scene_id: StringName) -> void:
	for tick in range(200):
		await create_timer(0.05).timeout
		if current_scene != null and current_scene.get("_current_scene") != null and current_scene.get("_current_scene").scene_id == scene_id:
			var loading_manager := root.get_node("LoadingManager")
			for transition_tick in range(200):
				if not bool(loading_manager.get("_transition_active")):
					break
				await create_timer(0.025).timeout
			await create_timer(0.20).timeout
			return
	push_error("Timed out loading " + String(scene_id))
	quit(1)
