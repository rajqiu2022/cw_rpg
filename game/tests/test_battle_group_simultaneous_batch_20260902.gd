extends SceneTree

var failures := 0


func _initialize() -> void:
	await process_frame
	await _test_bold_font_runtime()
	await _test_simultaneous_hit_start()
	await _test_shared_group_vfx_clock()
	_test_controller_contracts()
	print("[BattleGroupSimultaneous20260902] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_bold_font_runtime() -> void:
	var bridge := root.get_node_or_null("PlatformBridge")
	_check(bridge != null, "PlatformBridge autoload is available")
	if bridge == null:
		return
	var bold_font := bridge.get("_bundled_ui_font_bold") as FontVariation
	_check(bold_font != null and bold_font.variation_embolden >= 0.5, "bundled Chinese font uses portable synthetic embolden")
	var label := Label.new()
	root.add_child(label)
	await process_frame
	_check(label.get_theme_font("font") is FontVariation, "new runtime labels inherit the clear bold font")
	label.queue_free()
	await process_frame


func _test_simultaneous_hit_start() -> void:
	var packed := load("res://scenes/battle_actor.tscn") as PackedScene
	var actor_a := packed.instantiate() as BattleActor
	var actor_b := packed.instantiate() as BattleActor
	root.add_child(actor_a)
	root.add_child(actor_b)
	actor_a.position = Vector2(300, 360)
	actor_b.position = Vector2(720, 360)
	await process_frame
	var image := Image.create(48, 72, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture := ImageTexture.create_from_image(image)
	var frames: Array[Texture2D] = [texture, texture, texture, texture]
	actor_a.configure(texture, false, true, frames, frames, frames, frames, frames)
	actor_b.configure(texture, false, true, frames, frames, frames, frames, frames)
	var initial_a := actor_a.position
	var initial_b := actor_b.position
	var duration_a := actor_a.start_hit_reaction(31, false, false)
	var duration_b := actor_b.start_hit_reaction(47, true, false)
	_check(_has_damage_label(actor_a, "-31") and _has_damage_label(actor_b, "-47"), "all group damage numbers spawn in the same frame")
	_check(is_equal_approx(duration_a, duration_b), "parallel hit reactions expose one shared wait duration")
	await create_timer(maxf(duration_a, duration_b) + 0.05).timeout
	_check(actor_a.position.is_equal_approx(initial_a) and actor_b.position.is_equal_approx(initial_b), "all parallel hit reactions settle together")
	actor_a.queue_free()
	actor_b.queue_free()
	await process_frame


func _test_shared_group_vfx_clock() -> void:
	var vfx := BattleVfxPlayer.new()
	vfx.size = Vector2(1280, 720)
	root.add_child(vfx)
	var source := Control.new()
	var target_a := Control.new()
	var target_b := Control.new()
	for control: Control in [source, target_a, target_b]:
		control.size = Vector2(180, 260)
		root.add_child(control)
	source.position = Vector2(160, 360)
	target_a.position = Vector2(720, 280)
	target_b.position = Vector2(960, 380)
	await process_frame
	var config: Dictionary = vfx.get_effect_config(&"sword_arc")
	var single_duration := float(config.get("frame_seconds", 0.10)) * 4.0
	var started := Time.get_ticks_msec()
	await vfx.play_for_skill_group(&"sword_arc", [target_a, target_b], source)
	var elapsed := float(Time.get_ticks_msec() - started) / 1000.0
	_check(elapsed < single_duration * 1.55, "two-target VFX uses one shared clock instead of two serial clocks (%.3fs)" % elapsed)
	await process_frame
	_check(vfx.get_child_count() == 0, "group VFX clears all target layers together")
	vfx.queue_free()
	source.queue_free()
	target_a.queue_free()
	target_b.queue_free()
	await process_frame


func _test_controller_contracts() -> void:
	var controller := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	_check("PROTAGONIST_FORMATION_SCALE_FACTOR := 1.28" in controller, "protagonist visual area is normalized against ordinary combatants")
	_check("simultaneous_support" in controller and "play_for_skill_group(skill.animation_id, support_actors" in controller, "ALLY_ALL heal and buff effects share one impact")
	var player_group := _function_source(controller, "func _team_execute_player_group_damage", "func _team_actors_for_targets")
	_check("_team_play_simultaneous_hits" in player_group and "await target_actor.play_hit" not in player_group, "player group damage commits all targets before one shared reaction wait")
	var enemy_group := _function_source(controller, "func _team_execute_enemy_group_damage", "func _skill_uses_approach")
	_check("_team_play_simultaneous_hits" in enemy_group and "await defender.play_hit" not in enemy_group, "enemy group damage commits all targets before one shared reaction wait")
	var font_source := FileAccess.get_file_as_string("res://scripts/autoload/platform_bridge.gd")
	_check("variation_embolden = 0.55" in font_source, "font clarity setting is locked in source")
	_check('description_label.add_theme_font_size_override("font_size", 16)' in controller and 'name_label.add_theme_font_size_override("font_size", 20)' in controller, "battle skill popup uses larger high-contrast text")


func _has_damage_label(actor: BattleActor, expected: String) -> bool:
	for child in actor.get_children():
		if child is Label and expected in (child as Label).text:
			return true
	return false


func _function_source(source: String, start_marker: String, end_marker: String) -> String:
	var start := source.find(start_marker)
	var end := source.find(end_marker, start + start_marker.length())
	if start < 0:
		return ""
	return source.substr(start, end - start if end > start else source.length() - start)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
