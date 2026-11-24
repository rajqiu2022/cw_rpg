extends SceneTree

var failures := 0


func _initialize() -> void:
	await process_frame
	_test_bgm_assets()
	await _test_attack_timing_and_damage_number()
	_test_feedback_source_contracts()
	print("[AudioTimingBatch20260823] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_bgm_assets() -> void:
	var field_names := ["jianghu_journey", "village_day", "mountain_path", "forest_mystery", "cave_ominous", "market_lively", "city_ceremony", "sect_clouds"]
	var battle_names := ["battle_village", "battle_mountain", "battle_river", "battle_spar", "battle_boss"]
	var lengths: Dictionary = {}
	for name in field_names:
		var path := "res://art/audio/bgm/bgm_%s_v4.wav" % name
		var stream := load(path) as AudioStream
		_check(stream != null, "%s loads" % path)
		if stream != null:
			lengths[name] = stream.get_length()
			_check(stream.get_length() >= 40.0, "%s preserves a complete early-theme phrase before looping" % name)
	for name in battle_names:
		var path := "res://art/audio/bgm/bgm_%s_v4.wav" % name
		var stream := load(path) as AudioStream
		_check(stream != null, "%s loads" % path)
		if stream != null:
			lengths[name] = stream.get_length()
			_check(stream.get_length() >= 32.0, "%s preserves a complete early battle phrase before looping" % name)
	_check(lengths.size() == 13, "all 13 early-theme variations are present")
	var audio_source := FileAccess.get_file_as_string("res://scripts/autoload/audio_manager.gd")
	_check(audio_source.contains("BgmPlayerA") and audio_source.contains("BgmPlayerB"), "BGM uses immediate dual-player crossfade")
	_check(not audio_source.contains("create_timer(0.25)"), "BGM switching no longer waits for an old-track fade")


func _test_attack_timing_and_damage_number() -> void:
	var packed := load("res://scenes/battle_actor.tscn") as PackedScene
	var attacker := packed.instantiate() as BattleActor
	var target := packed.instantiate() as BattleActor
	root.add_child(attacker)
	root.add_child(target)
	attacker.position = Vector2(180, 320)
	target.position = Vector2(720, 320)
	attacker.size = Vector2(220, 300)
	target.size = Vector2(220, 300)
	var image := Image.create(64, 96, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	var frames: Array[Texture2D] = [texture, texture, texture, texture]
	attacker.configure(texture, false, true, frames, frames, frames, frames, frames)
	target.configure(texture, true, false, frames, frames, frames, frames, frames)
	attacker.set_action_time_scale(1.12)
	var started := Time.get_ticks_msec()
	var strike_record := [-1]
	attacker.strike_reached.connect(func() -> void: strike_record[0] = Time.get_ticks_msec(), CONNECT_ONE_SHOT)
	await attacker.play_attack_approach(target, false)
	var elapsed := float(Time.get_ticks_msec() - started) / 1000.0
	_check(elapsed >= 1.45, "approach plus four-frame strike remains readable (%.2fs)" % elapsed)
	_check(int(strike_record[0]) > started, "attack emits a deterministic impact frame")

	target.call("_spawn_damage_number", 42, false)
	await create_timer(1.60).timeout
	var number_alive := false
	for child in target.get_children():
		if child is Label and (child as Label).text == "-42":
			number_alive = true
	_check(number_alive, "damage number remains visible after 1.6 seconds")
	await create_timer(0.75).timeout
	var number_gone := true
	for child in target.get_children():
		if child is Label and (child as Label).text == "-42":
			number_gone = false
	_check(number_gone, "damage number clears after its two-second presentation")
	attacker.queue_free()
	target.queue_free()


func _test_feedback_source_contracts() -> void:
	var controller := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	var legendary := FileAccess.get_file_as_string("res://scripts/battle/legendary_skill_cinematic.gd")
	_check(controller.contains("play_fullscreen_effect(skill.skill_id, _skill_impact_sfx(skill))"), "legendary impact receives its sound before visual completion")
	_check(controller.contains("play_hit(dealt, was_critical, false,"), "late duplicate hit sound is suppressed while preserving strike-source recoil")
	_check(legendary.contains("if frame_index == 2:") and legendary.contains("sfx_requested"), "legendary sound fires on the authored impact frame")


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
