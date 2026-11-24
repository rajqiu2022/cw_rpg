extends "res://tests/test_world_map_v14_production_20261002.gd"

## FOCUSED_SYSTEM_GHOST_NOT_FULL_MAP. Root-approved separate experiment on
## current third-capture candidate, NOT all routes/16 portals/new mature trees.
func _run() -> void:
	qa_scope = "SYSTEM_GHOST_NOT_FULL_MAP"
	candidate_stage = true
	active_id = CANDIDATE_ID
	active_path = CANDIDATE_PATH
	phase_output = OUTPUT_DIR + "focused_system_ghost_" + ("headless_" if DisplayServer.get_name() == "headless" else "gpu_") + str(int(Time.get_unix_time_from_system())) + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output))
	player_saves_before = _actual_player_saves()
	world = load(active_path)
	source_contract = _json(SOURCE_PATH)
	manifest = _json(MANIFEST_PATH)
	print("[V14Focused] FOCUSED_SYSTEM_GHOST_NOT_FULL_MAP FieldSHA=",FileAccess.get_sha256("res://scripts/field/field_walkable_controller.gd"))
	_check(String(manifest.get("status")) == "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA", "current completed third capture only, no transitional new-tree outputs")
	if DisplayServer.get_name() != "headless":
		_check("--qa-gpu-approved" in OS.get_cmdline_user_args(), "root explicitly serialized one focused GPU run")
	if failed > 0:
		_finish()
		return
	_fixture_new_game()
	if not await _open_world(world.player_spawn):
		_finish()
		return
	_collect_runtime()
	for id in ["bianzhou_landmark", "jinling_landmark"]:
		var d: Dictionary = {}
		for candidate: Dictionary in world.map_layout.visual_objects:
			if String(candidate.get("id")) == id: d = candidate
		var prop: Sprite2D = runtime_props.get(id)
		_check(not d.is_empty() and prop != null,"focused real independent city resource exists: " + id)
		if prop == null: continue
		for front in [false,true]:
			var station := _prop_alpha_station(d,prop,front)
			_check(not station.is_empty(),"bounded original-alpha legal %s station found: %s" % ["front" if front else "behind",id])
			if station.is_empty(): continue
			_check(await _place_fixture(station.point),"focused station complete-foot legal: " + id)
			print("[V14FocusedStation] id=",id," front=",front," foot=",station.point," facing=",station.facing," hits=",station.hits)
			var total_positive := 0
			for facing: Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				_set_idle(facing)
				var player: Node2D = field.get("_player")
				var actor: Sprite2D = player.get("sprite")
				for current_frame in actor.hframes * actor.vframes:
					actor.frame = current_frame
					player.set("_frame_timer",0.0)
					var evidence := await _ghost_mask_check("focused %s front=%s facing=%s frame=%d" % [id,front,facing,current_frame])
					if int(evidence.pixels) > 0: total_positive += 1
					_check(_foot_clear(player.position) and _depth_order(player,prop,front), "every real facing/frame retains feet and proper city depth")
				await _capture("%s_%s_%s" % [id,"front" if front else "behind",str(facing)])
			if not front: _check(total_positive > 0,"actual behind current-frame positive ghost remains, not all empty masks: " + id)
		var strong := _prop_alpha_station(d,prop,false,100,true)
		if not strong.is_empty():
			_check(await _place_fixture(strong.point),"strong additional behind station has complete legal feet and a movement corridor: " + id)
			_set_idle(strong.facing)
			var extra := await _ghost_mask_check("strong additional behind source-alpha case: " + id)
			print("[V14FocusedStrong] id=",id," foot=",strong.point," facing=",strong.facing," original_target_hits=",strong.hits," union_pixels=",extra.pixels)
			await _capture(id + "_strong_additional_behind")
		else:
			print("[V14FocusedStrong] id=",id," no qualifying >=100hit+legal-corridor station found in actual bounded alpha domain; original2/18 boundary positives preserved; not an invented stronger visual proof")
	await _ghost_negative_and_performance()
	print("[V14Focused] scope remains FOCUSED_SYSTEM_GHOST_NOT_FULL_MAP; full roads/16 portal tour/production activation NOT RUN")
	_finish()
