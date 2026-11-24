extends "res://tests/test_world_map_v14_production_20261002.gd"

## Limited genuine button-input diagnosis. No geometry, renderer, fake outcomes,
## production writes, or GPU. Null scene frames are recorded, never skipped by
## forcing a result. Buttons count only observed pressed signals.
func _run() -> void:
	candidate_stage = true
	active_id = CANDIDATE_ID
	active_path = CANDIDATE_PATH
	qa_scope = "FOCUSED_REAL_BATTLE_INPUT_NOT_FULL_MAP"
	phase_output = OUTPUT_DIR + "focused_battle_input_" + str(int(Time.get_unix_time_from_system())) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output))
	player_saves_before = _actual_player_saves()
	manifest = _json(MANIFEST_PATH)
	source_contract = _json(SOURCE_PATH)
	world = load(active_path) as SceneScript
	_check(DisplayServer.get_name() == "headless", "limited battle diagnosis is headless only")
	if failed > 0 or world == null:
		_finish(); return
	var bus := root.get_node("EventBus")
	var events: Array = []
	var record := func(won: bool, fled: bool): events.append({"won": won, "fled": fled})
	bus.connect("battle_ended", record)
	for mode: String in ["victory", "defeat", "flee"]:
		_fixture_new_game()
		if not await _open_world(world.player_spawn): break
		var player: Node2D = field.get("_player")
		var original := player.position / WORLD_SIZE
		var state := root.get_node("GameState")
		var stats: Resource = state.get("player")
		stats.set("hp", 1 if mode == "defeat" else stats.get("max_hp"))
		stats.set("mp", stats.get("max_mp"))
		seed(140002 if mode == "defeat" else 140003)
		var router := root.get_node("SceneRouter")
		var enemies: Array[StringName] = [&"thug_lone"]
		var before := events.size()
		router.call("start_encounter", enemies, active_id, original)
		var battle: Node
		var deadline := Time.get_ticks_msec() + 30000
		while Time.get_ticks_msec() < deadline:
			await process_frame
			if is_instance_valid(current_scene) and current_scene.get_node_or_null("%BtnAttack") != null:
				battle = current_scene; break
		_check(battle != null, "real ordinary Battle exists: " + mode)
		if battle == null: continue
		var button := battle.get_node("%BtnAttack" if mode == "victory" else ("%BtnDefend" if mode == "defeat" else "%BtnFlee")) as Button
		var signals: Array = []
		button.pressed.connect(func(): signals.append(Time.get_ticks_msec()))
		var loading := root.get_node("LoadingManager")
		print("[BattleInputInitial] mode=%s state=%s visible=%s disabled=%s loading=%s rect=%s canvas=%s physical=%s" % [mode,battle.get("_state"),button.is_visible_in_tree(),button.disabled,loading.get("_transition_active"),button.get_global_rect(),button.get_global_transform_with_canvas(),root.get_final_transform()*button.get_global_rect().get_center()])
		var commands := 0
		var null_frames := 0
		var result_scene: Node
		deadline = Time.get_ticks_msec() + 120000
		while Time.get_ticks_msec() < deadline and commands < 32:
			await process_frame
			if not is_instance_valid(current_scene): null_frames += 1; continue
			if current_scene != battle:
				if bool(loading.get("_transition_active")): continue
				if mode == "flee" and current_scene.get_node_or_null("WorldContainer") != null: result_scene = current_scene; break
				if mode == "victory" and current_scene.get_node_or_null("%BtnContinue") != null: result_scene = current_scene; break
				if mode == "defeat" and current_scene.get_node_or_null("%BtnBack") != null: result_scene = current_scene; break
				continue
			if bool(loading.get("_transition_active")) or int(battle.get("_state")) != 1 or not button.is_visible_in_tree() or button.disabled: continue
			var pressed_before := signals.size()
			await _pointer(button.get_global_rect().get_center())
			commands += 1
			print("[BattleInputCommand] mode=%s command=%d pressed_delta=%d state=%s nullframes=%d" % [mode,commands,signals.size()-pressed_before,battle.get("_state") if is_instance_valid(battle) else "freed",null_frames])
			_check(signals.size() == pressed_before + 1, "real visible ready button receives one ordinary mouse press: " + mode)
			if mode == "flee":
				var dialog := battle.get("_flee_confirm_dialog") as Control
				_check(dialog != null and dialog.is_visible_in_tree(), "real PLAYER_TURN flee input opens confirmation")
				if dialog != null and dialog.is_visible_in_tree():
					var confirm := dialog.get_node("%ConfirmAction") as Button
					var confirmation: Array = []
					confirm.pressed.connect(func(): confirmation.append(true), CONNECT_ONE_SHOT)
					await _pointer(confirm.get_global_rect().get_center())
					_check(confirmation.size() == 1, "real ordinary flee confirmation receives pointer")
			# An accepted command may retain PLAYER_TURN until the next process
			# callback. Let normal animation/input settlement run, not 32 rapid
			# attempts inside the initial .5-second intro.
			for frame in range(6): await process_frame
		print("[BattleInputOutcome] mode=%s commands=%d actual_pressed=%d nullframes=%d events=%s scene=%s" % [mode,commands,signals.size(),null_frames,events.slice(before),result_scene.scene_file_path if is_instance_valid(result_scene) else "null"])
		var expected_event := false
		for event: Dictionary in events.slice(before):
			if bool(event.won) == (mode == "victory") and bool(event.fled) == (mode == "flee"): expected_event = true
		_check(expected_event and result_scene != null, "normal commands resolve to actual " + mode + " event and scene")
		if result_scene == null: continue
		if mode != "flee":
			var result: Dictionary = router.call("get_result_payload")
			_check(int(result.get("return_world_map_version", -1)) == 14, "actual outcome keeps source version14: " + mode)
			await _pointer((result_scene.get_node("%BtnContinue" if mode == "victory" else "%BtnBack") as Button).get_global_rect().get_center())
		_check(await _wait_field(active_id), "real result/retreat normal UI returns to candidate: " + mode)
		if is_instance_valid(field):
			var returned: Node2D = field.get("_player")
			_check((returned.position / WORLD_SIZE).distance_to(original) * WORLD_SIZE.length() < .03 and _foot_clear(returned.position), "actual outcome return restores exact complete feet: " + mode)
	bus.disconnect("battle_ended", record)
	_finish()
