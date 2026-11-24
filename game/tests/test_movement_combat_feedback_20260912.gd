extends SceneTree

var checks := 0
var failed := 0


func _initialize() -> void:
	await process_frame
	await _check_south_movement_hot_path()
	_check_inventory_shortcut_is_disabled()
	await _check_critical_and_dodge_feedback()
	await _check_victory_music_sting()
	print("[MovementCombatFeedback20260912] checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)


func check(condition: bool, message: String) -> void:
	checks += 1
	if condition:
		print("[PASS] %s" % message)
	else:
		failed += 1
		push_error("[MovementCombatFeedback20260912] %s" % message)


func _check_south_movement_hot_path() -> void:
	var south := load("res://data/scenes/linxi_village_scrollmap.tres") as SceneScript
	check(south != null and south.npcs.size() >= 10, "South District fixture keeps its high-NPC stress case")
	var npc_scene := load("res://scenes/npc_node.tscn") as PackedScene
	var npc := npc_scene.instantiate()
	root.add_child(npc)
	await process_frame
	var sprite := npc.get_node("Sprite2D") as Sprite2D
	check(sprite.material == null, "idle NPC does not retain the five-sample outline shader")
	npc.call("_set_interaction_highlight", true)
	check(sprite.material is ShaderMaterial, "nearby interactable NPC enables its outline on demand")
	npc.call("_set_interaction_highlight", false)
	check(sprite.material == null, "leaving interaction range releases the outline shader")
	npc.queue_free()

	var movement_logic: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	check(not bool(movement_logic.call("_sample_moved_enough", Vector2(0.5, 0.5), Vector2(0.502, 0.502), 8.0)), "sub-threshold movement skips repeated return/occlusion work")
	check(bool(movement_logic.call("_sample_moved_enough", Vector2(0.5, 0.5), Vector2(0.51, 0.5), 8.0)), "travel beyond the sampling threshold still refreshes navigation state")
	movement_logic.free()
	var player_source := FileAccess.get_file_as_string("res://scripts/field/player.gd")
	check("visual_key != _applied_visual_key" in player_source, "unchanged player direction no longer resolves and reapplies the same texture every physics tick")
	var npc_source := FileAccess.get_file_as_string("res://scripts/field/npc_node.gd")
	var patrol_start := npc_source.find("func _apply_patrol_walk_visual")
	var patrol_end := npc_source.find("\nfunc ", patrol_start + 6)
	var patrol_body := npc_source.substr(patrol_start, patrol_end - patrol_start)
	check("ResourceLoader.exists" not in patrol_body and "load(" not in patrol_body, "patrolling NPCs do not query the resource filesystem every rendered frame")


func _check_inventory_shortcut_is_disabled() -> void:
	for path in [
		"res://scripts/field/field_controller.gd",
		"res://scripts/field/field_walkable_controller.gd",
	]:
		var source := FileAccess.get_file_as_string(path)
		check("const INVENTORY_SHORTCUT_ENABLED := false" in source, "%s explicitly disables I inventory shortcut" % path.get_file())
		var branch_start := source.find("event.keycode == KEY_I")
		var branch_end := source.find("event.keycode == KEY_C", branch_start)
		var branch := source.substr(branch_start, branch_end - branch_start)
		check("if INVENTORY_SHORTCUT_ENABLED" in branch and "set_input_as_handled" in branch, "%s consumes I without opening the hidden panel" % path.get_file())


func _check_critical_and_dodge_feedback() -> void:
	var packed := load("res://scenes/battle_actor.tscn") as PackedScene
	var actor := packed.instantiate() as BattleActor
	var source := packed.instantiate() as BattleActor
	root.add_child(actor)
	root.add_child(source)
	actor.size = Vector2(220, 300)
	actor.position = Vector2(700, 350)
	source.size = Vector2(220, 300)
	source.position = Vector2(220, 350)
	await process_frame

	actor.call("_spawn_damage_number", 88, true)
	var crit_label: Label = null
	for child in actor.get_children():
		if child is Label and "暴击" in (child as Label).text:
			crit_label = child as Label
	check(crit_label != null and crit_label.text == "暴击！\n-88", "critical hit shows a dedicated two-line callout and damage")
	check(crit_label != null and crit_label.get_theme_font_size("font_size") >= 96, "critical hit typography is materially larger than normal damage")
	var burst := actor.get_node_or_null("CriticalBurst")
	check(burst != null and burst.get_child_count() == 12, "critical hit creates a twelve-ray explosive burst")

	var dodge_duration := float(actor.start_dodge_reaction(source))
	var dodge_label := actor.get_node_or_null("BattleFeedbackText") as Label
	check(dodge_label != null and dodge_label.text == "闪避", "missed attack produces an immediate dodge callout")
	check(dodge_label != null and dodge_label.get_theme_font_size("font_size") >= 76, "dodge callout remains readable over battle effects")
	await create_timer(dodge_duration + 0.05).timeout
	check(actor.position.is_equal_approx(Vector2(700, 350)), "dodge sidestep returns the target to its formation position")

	var controller_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	check(controller_source.count("play_dodge(") >= 4 and controller_source.count('"dodged": true') >= 2, "single-target and group player/enemy miss paths all dispatch dodge feedback")
	actor.queue_free()
	source.queue_free()


func _check_victory_music_sting() -> void:
	var path := "res://art/audio/bgm/bgm_victory_v2.wav"
	var stream := load(path) as AudioStream
	check(stream != null and stream.get_length() >= 7.0, "victory celebration source is present and long enough for the short cue")
	var audio := root.get_node("AudioManager")
	audio.play_music_sting(path, 0.5)
	await process_frame
	var sting_player := audio.get("_music_sting_player") as AudioStreamPlayer
	check(sting_player != null and sting_player.playing, "victory music starts on the dedicated music-sting player")
	check(sting_player != null and sting_player.stream is AudioStreamWAV and (sting_player.stream as AudioStreamWAV).loop_mode == AudioStreamWAV.LOOP_DISABLED, "victory music is explicitly non-looping")
	await create_timer(0.90).timeout
	check(not sting_player.playing and sting_player.stream == null, "short victory music fades and releases its stream")
	var result_source := FileAccess.get_file_as_string("res://scripts/ui/result_victory.gd")
	check("AudioManager.play_music_sting(VICTORY_MUSIC_PATH, 8.0)" in result_source, "victory result screen owns the celebration cue")
