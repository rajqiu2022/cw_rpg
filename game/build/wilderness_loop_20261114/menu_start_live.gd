extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var loading: Node = root.get_node("LoadingManager")
	var router: Node = root.get_node("SceneRouter")
	var started := Time.get_ticks_msec()
	if change_scene_to_file("res://scenes/loading_bootstrap.tscn") != OK:
		quit(1)
		return
	while Time.get_ticks_msec() - started < 15000:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == "res://scenes/main_menu.tscn" and not loading.get("_transition_active"):
			break
	if current_scene == null or current_scene.scene_file_path != "res://scenes/main_menu.tscn" or current_scene.get_script() == null:
		printerr("MENU_START: missing playable menu")
		quit(2)
		return
	print("MENU_START: bootstrap_ms=", Time.get_ticks_msec() - started)
	var btn: Button = current_scene.get_node("%BtnNewGame")
	var worst_ms := 0
	var sample_start := Time.get_ticks_msec()
	var last := sample_start
	var frames := 0
	while Time.get_ticks_msec() - sample_start < 1200:
		await process_frame
		var now := Time.get_ticks_msec()
		worst_ms = maxi(worst_ms, now - last)
		last = now
		frames += 1
	print("MENU_START: idle frames=", frames, " max_frame_ms=", worst_ms)
	var position := btn.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion, true)
	await process_frame
	started = Time.get_ticks_msec()
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = position
		root.push_input(click, true)
		await process_frame
	print("MENU_START: click_boundary_ms=", Time.get_ticks_msec() - started, " loading_active=", loading.get("_transition_active"))
	if OS.get_cmdline_user_args().has("--expect-preparation"):
		var screen: Node = loading.get("_screen")
		if screen == null or not screen.is_showing() or not loading.get("_external_active") or not btn.disabled:
			printerr("MENU_START: no immediate preparation screen or duplicate-click protection")
			quit(4)
			return
	while Time.get_ticks_msec() - started < 15000:
		await process_frame
		if router.get_current_field_id() != &"linxi_tutorial" or loading.get("_transition_active"):
			continue
		var actor := get_first_node_in_group("player") as Player
		if actor != null and actor.can_move:
			var ready_ms := Time.get_ticks_msec() - started
			var dialogue: Node = root.get_node("DialogPlayer")
			for page in range(20):
				if not dialogue.is_playing():
					break
				dialogue.advance()
				await process_frame
			var before := actor.global_position
			for code in [KEY_W, KEY_D, KEY_A]:
				var key := InputEventKey.new()
				key.keycode = code
				key.physical_keycode = code
				key.pressed = true
				Input.parse_input_event(key)
				await create_timer(0.27).timeout
				var release := key.duplicate() as InputEventKey
				release.pressed = false
				Input.parse_input_event(release)
				if before.distance_to(actor.global_position) > 1.0:
					break
			if before.distance_to(actor.global_position) <= 1.0:
				printerr("MENU_START: Linxi player did not walk")
				quit(5)
				return
			print("MENU_START PASS: linxi_tutorial ready_ms=", ready_ms, " walked_px=", before.distance_to(actor.global_position))
			quit()
			return
	printerr("MENU_START: clicked New Game, no controllable Linxi player")
	quit(3)
