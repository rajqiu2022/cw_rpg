extends "res://build/victory_quest_20261108/story_live.gd"

const FOREST := &"ch1_s3_zhuwei_forest"
const CAVE := &"ch1_s4_zhuwei_beast_cave"
const VILLAGE := &"ch1_s2_qingfeng"
var loader: Node

func _run() -> void:
	await process_frame
	set_meta("skip_chapter_end_autosave", true)
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	quests = root.get_node("QuestManager")
	dialogue = root.get_node("DialogPlayer")
	loader = root.get_node("LoadingManager")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	for flag in [&"entered_zhuwei_forest", &"entered_zhuwei_village", &"zhuwei_village_inquiry_done", &"defeated_linxi_wild_beast"]:
		state.set_flag(flag, true)
	var field := await enter(FOREST)
	for destination in [CAVE, FOREST, VILLAGE, FOREST]:
		if field == null: break
		field = await sample_portal(field, destination)
	if field != null:
		expect(field.find_child("SceneObject_cave_mouth", true, false) != null, "actual forest still uses the rebuilt cave mouth")
	finish()

func sample_portal(field: Node, destination: StringName) -> Node:
	await settle(field)
	var zone := zone_to(field, destination)
	if not expect(zone != null and not zone.is_locked, "available portal to "+String(destination)): return null
	var actor := await position_at(field, zone.global_position)
	if not expect(await wait_for(func(): return is_instance_valid(zone) and zone.get("_in_range"), 2200), "physical contact "+String(destination)): return null
	var before := field.get_instance_id()
	var presses := [0]
	actor.interacted.connect(func(): presses[0] += 1)
	await press_space()
	var screen := loader.get("_screen") as CanvasLayer
	if not expect(screen != null and loader.get("_transition_active") and router.get_current_field_id() == destination, "actual Space starts intended route "+String(destination)): return null
	await press_space()
	expect(presses[0] == 1, "repeat Space does not reach the old field "+String(destination))
	var samples := 0
	var wrong := 0
	var tested_repeat := false
	var start := Time.get_ticks_msec()
	while loader.get("_transition_active") and Time.get_ticks_msec() - start < 18000:
		await process_frame
		if DisplayServer.get_name() != "headless": await RenderingServer.frame_post_draw
		if not screen.root.visible or screen.root.modulate.a >= 0.999: continue
		samples += 1
		var shown := current_scene
		var camera := root.get_camera_2d()
		if not is_instance_valid(shown) or shown.get_instance_id() == before or not shown.get_field_loading_state().complete or StringName(shown.get_field_loading_state().scene_id) != destination or router.get_current_field_id() != destination or not is_instance_valid(camera) or not shown.is_ancestor_of(camera):
			wrong += 1
		elif not tested_repeat:
			tested_repeat = true
			var incoming := shown.get("_player") as Player
			var incoming_presses := [0]
			incoming.interacted.connect(func(): incoming_presses[0] += 1)
			for pressed in [true, false]:
				var event := InputEventKey.new()
				event.keycode = KEY_SPACE
				event.physical_keycode = KEY_SPACE
				event.pressed = pressed
				Input.parse_input_event(event)
				Input.flush_buffered_events()
			expect(incoming_presses[0] == 0, "repeat Space does not reach the incoming field during reveal "+String(destination))
	expect(samples > 0 and wrong == 0, "every sampled reveal frame belongs to the intended map and camera "+String(destination))
	print("REVEAL ", destination, " frames=", samples, " wrong=", wrong)
	if not expect(not loader.get("_transition_active") and not screen.root.visible and current_scene != null and router.get_current_field_id() == destination, "transition finishes and releases the curtain "+String(destination)): return null
	check_clear(current_scene.get("_player"), "arrival collision "+String(destination))
	return current_scene
