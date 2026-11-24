extends "res://build/victory_quest_20261108/story_live.gd"

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	quests = root.get_node("QuestManager")
	dialogue = root.get_node("DialogPlayer")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	match OS.get_cmdline_user_args()[0]:
		"ruin": await ruin()
		"wolf": await wolf()
		"chapter": await chapter()
	finish()

func dialog_is(id: StringName) -> bool:
	var script := dialogue.get("_current_script") as DialogScript
	return dialogue.is_playing() and script != null and script.dialog_id == id

func stage_uv(field: Node, uv: Vector2) -> Player:
	var world := field.get("world_container") as Node2D
	var dimensions: Vector2 = field.get("_world_size")
	return await position_at(field, world.to_global(dimensions * uv))

func screenshot(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/zhuwei_followup_20261115/" + name + ".png")

func ruin() -> void:
	state.set_flag(&"clue_west_ruin_supply_route", true)
	var field := await enter(&"ch1_s3_west_ruin")
	if field == null:
		return
	await settle(field)
	var visual := field.get("_visual_layer") as Node2D
	expect(visual.has_node("RiversideNaturalGround01"), "modular exterior ground")
	expect(field.has_meta("uses_reward_pickup_tip"), "field routes pickup to shared card")
	var inv := root.get_node("Inventory")
	expect(inv.add_item(&"healing_pill_minor", 1), "real item enters inventory")
	var tip := quests.get_node("QuestRewardTip")
	expect(tip.get("_panel").visible and tip.get("_rewards").get_parsed_text().contains("小还丹"), "item card with text")
	expect(field.get("_item_toast_lines").is_empty(), "no second bare pickup toast")
	await screenshot("ruin_pickup")
	var guard_location := Vector2(0.39, 0.66)
	expect(field.call("_spawn_has_foot_clearance", field.get("_current_scene"), guard_location), "outer approach has body clearance")
	await stage_uv(field, guard_location)
	if expect(await wait_for(func(): return dialog_is(&"ch1_s3_outer_guard"), 3000), "outer guard starts dialogue on approach"):
		await screenshot("ruin_guard")
		var outer_id := field.get_instance_id()
		dialogue.advance()
		expect(await wait_for(func(): return current_scene != null and current_scene.get_instance_id() != outer_id and not root.get_node("LoadingManager").get("_transition_active"), 15000), "guard starts real battle")
	state.set_flag(&"master_training_done", true)
	state.set_flag(&"zhao_wuji_identified", true)
	state.set_flag(&"defeated_zhuwei_bandit", true)
	field = await enter(&"ch1_s3_ruin_inner")
	if field == null:
		return
	expect(not dialogue.is_playing(), "does not trigger at the return threshold")
	await stage_uv(field, Vector2(0.5, 0.63))
	if expect(await wait_for(func(): return dialog_is(&"ch1_s3_ruin_boss"), 3000), "Zhao speaks upon crossing hall"):
		await settle(field)
	if not expect(await wait_for(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/battle.tscn", 10000), "Zhao original battle loads"):
		return
	var fight := current_scene
	if not expect(await wait_for(func(): return fight.get("_state") == 1, 12000), "player turn begins"):
		return
	var actor: BattleActor = fight.get("formation_view").enemy_actors.front()
	var units: Array = fight.get("_team_enemies")
	var enemy := units.front() as BattleCombatant
	enemy.stats.hp = 1
	var capture := {"defeat": false, "shot": false}
	var monitor := func() -> void:
		var observed := instance_from_id(int(capture.actor_id)) as BattleActor
		if observed == null or observed.defeat_frames.is_empty():
			return
		if observed.artwork.texture == observed.defeat_frames.back() and observed.retain_on_defeat:
			capture.defeat = true
			if not capture.shot:
				capture.shot = true
				screenshot("zhao_defeat")
	capture.actor_id = actor.get_instance_id()
	process_frame.connect(monitor)
	var fight_ref: WeakRef = weakref(fight)
	for retry in range(5):
		if not is_instance_valid(fight) or not enemy.alive:
			break
		if not await wait_for(func():
			var active_fight := fight_ref.get_ref() as Node
			return active_fight == null or active_fight.get("_state") == 1
		, 10000):
			break
		if not is_instance_valid(fight):
			break
		var active: BattleCombatant = fight.get("_team_active_unit")
		var skills: Array = fight._skills_for_stats(active.stats)
		for index in skills.size():
			if skills[index].skill_id == &"basic_attack":
				fight._team_player_action_skill_use(index, enemy.unit_id)
				break
		await create_timer(0.5).timeout
	var won := await wait_for(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/result_victory.tscn", 12000)
	process_frame.disconnect(monitor)
	expect(capture.defeat, "actual finishing blow retains Zhao's defeat pose")
	if not expect(won, "Zhao victory results"):
		return
	current_scene.get_node("%BtnContinue").pressed.emit()
	if not expect(await wait_for(func(): return dialog_is(&"ch1_s3_ruin_after_boss"), 14000), "victory returns into Zhao aftermath"):
		return
	field = current_scene
	while dialog_is(&"ch1_s3_ruin_after_boss"):
		dialogue.advance()
		await process_frame
	expect(await wait_for(func():
		var zhao := field.get("_zhao_escape_actor") as Sprite2D
		return zhao != null and zhao.texture.resource_path.ends_with("escape_03.tres")
	, 3500), "launch uses distinct third frame")
	await screenshot("zhao_leap")
	expect(await wait_for(func(): return dialog_is(&"ch1_s3_ruin_after_escape"), 3500), "escape advances aftermath")
	expect(state.get_flag(&"zhao_wuji_wounded_escape") and not state.get_flag(&"zhao_wuji_escape_cutscene_pending"), "escape flags committed once")
	field = await take(field, &"ch1_s3_west_ruin")
	if field != null:
		await take(field, &"ch1_s3_ruin_inner")

func wolf() -> void:
	var field := await enter(&"adventure_zhuwei_hunting_ground")
	if field == null:
		return
	var adventure := root.get_node("AdventureRuntime")
	expect(await wait_for(func(): return adventure.get_adventure_state().features.has("forest_wolf_ridge"), 4500), "wolf challenge is on native hunting map")
	var world := field.get("world_container") as Node2D
	var wolf_node := world.get_node_or_null("OptionalAdventureFeatures/Adventure_forest_wolf_ridge") as Node2D
	if not expect(wolf_node != null, "ridge wolf node"):
		return
	var anim := wolf_node.get_node_or_null("WolfIdle") as AnimatedSprite2D
	expect(anim != null and anim.sprite_frames.get_frame_count(&"default") == 3, "three authored idle frames")
	var hero := await position_at(field, wolf_node.global_position + Vector2(0, -73))
	expect(await wait_for(func(): return dialog_is(&"zhuwei_ridge_wolf_choice"), 3500), "approach opens quest-style dialogue")
	await screenshot("ridge_wolf_choice")
	if dialogue.is_playing() and dialogue.get("_current_node").has_choices():
		dialogue.choose(1)
	expect(not dialogue.is_playing() and current_scene == field, "escape leaves player in the field")
	await create_timer(0.4).timeout
	expect(not dialogue.is_playing(), "no prompt loop")
	await position_at(field, wolf_node.global_position + Vector2(0, 190))
	await position_at(field, wolf_node.global_position + Vector2(0, 73))
	expect(await wait_for(func(): return dialog_is(&"zhuwei_ridge_wolf_choice"), 3000), "proximity prompt rearms")
	expect(hero.z_index + (field.get("_actor_layer") as Node2D).z_index > wolf_node.z_index, "hero in front has greater depth")
	if dialogue.is_playing() and dialogue.get("_current_node").has_choices():
		dialogue.choose(0)
	expect(await wait_for(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/battle.tscn", 9000), "challenge starts actual encounter")
	await wait_for(func(): return not root.get_node("LoadingManager").get("_transition_active"))
	var first_fight := current_scene.get_instance_id()
	var king: Array[StringName] = [&"zhuwei_cave_wolf"]
	router.start_encounter(king, &"ch1_s4_cave_deep_den", Vector2(0.25, 0.72))
	if not expect(await wait_for(func(): return current_scene != null and current_scene.get_instance_id() != first_fight and current_scene.scene_file_path == "res://scenes/battle.tscn", 10000), "wolf king battle loads"):
		return
	var formation: BattleFormationView = current_scene.get("formation_view")
	var widget: VBoxContainer = formation.status_widgets.get(&"zhuwei_cave_wolf_1")
	var caption := widget.get_node("BossCaption") as Label
	expect(caption.text.begins_with("狼王-Boss") and caption.get_theme_color("font_color") == Color("#ff936f"), "distinct title above health")
	expect(formation.enemy_actors[0].ready_frames[0].get_width() == 820, "native atlas frame in battle")
	await create_timer(0.9).timeout
	await screenshot("wolf_king_battle")

func chapter() -> void:
	state.set_flag(&"chapter1_complete", true)
	state.set_flag(&"master_training_done", true)
	state.set_flag(&"defeated_boss_zhao_wuji", true)
	var field := await enter(&"ch1_s3_ruin_inner")
	if field == null:
		return
	field = await take(field, &"ch2_s1_zhuwei_market")
	if field == null:
		return
	await settle(field)
	var town: Node = field.get("native_town")
	expect(town.scene_file_path.ends_with("/zhuwei.tscn"), "Chapter 2 uses the same native village")
	expect(quests.is_active(&"q_ch2_main_01_investigate"), "new chapter starts investigation")
	var locked_names: Array[String] = []
	for zone: ExitZone in field.get("_exit_nodes"):
		if zone.is_locked:
			locked_names.append(zone.destination_name)
	expect(locked_names.size() == 2, "dual investigation gates")
	await screenshot("chapter2_same_street")
	field = await take(field, &"ch2_s1_market_inn")
	if field != null:
		await take(field, &"ch2_s1_zhuwei_market")
