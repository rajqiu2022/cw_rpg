extends "res://build/victory_quest_20261108/story_live.gd"

var hits := 0
var manual_done := false

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
	state.player.speed = 1000
	state.player.agility = 180
	var inventory := root.get_node("Inventory")
	inventory.add_item(&"jinhe_duanyue_blade")
	inventory.equip(&"jinhe_duanyue_blade")
	router.start_battle("zhuwei_cave_wolf", &"ch1_s4_zhuwei_beast_cave", Vector2(0.5, 0.82))
	if not expect(await wait_for(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/battle.tscn" and current_scene.get("_state") == 1, 18000), "real wolf king fight starts"):
		finish()
		return
	var battle := current_scene
	var actor: BattleActor = battle.formation_view.get_actor(&"player")
	var enemy: BattleCombatant = battle._team_enemies[0]
	var wolf: BattleActor = battle.formation_view.get_actor(enemy.unit_id)
	var home := actor.position
	var idle := {}
	var begin := Time.get_ticks_msec()
	while Time.get_ticks_msec() - begin < 1500:
		idle[wolf.artwork.texture.resource_path] = true
		await process_frame
	expect(idle.size() == 3 and wolf.ready_frames.size() == 4 and not wolf.artwork.flip_h, "wolf king cycles three authored idle poses facing the player")
	print("WOLF_IDLE ", idle.keys())
	actor.strike_reached.connect(func(): hits += 1)
	# Verify a distinct sweeping sequence and exact visual recovery without
	# introducing a synthetic second damage event into the real encounter.
	actor.action_skill = load("res://data/skills/gufeng_liedi.tres") as Skill
	perform_sweep(actor, wolf)
	var sweep_poses := {}
	while not manual_done:
		sweep_poses[actor.combat_clip + str(actor.combat_frame)] = true
		await process_frame
	expect(sweep_poses.has("fast_blade_group0") and sweep_poses.has("fast_blade_group1") and sweep_poses.has("fast_sword_group0"), "heavy sweep keeps its own body poses and intermediate turn")
	expect(hits == 1 and actor.position.distance_to(home) < 0.1, "sweep one strike and exact recovery")
	var basic_index := -1
	var skills: Array = battle._skills_for_stats(battle._team_active_unit.stats)
	for i in range(skills.size()):
		if skills[i].skill_id == &"basic_attack": basic_index = i
	if not expect(basic_index >= 0, "find real basic attack"):
		finish()
		return
	var hp := enemy.stats.hp
	hits = 0
	battle._team_player_action_skill_use(basic_index, enemy.unit_id)
	begin = Time.get_ticks_msec()
	var before_strike := {}
	var after_strike := {}
	var swing := {}
	var saw_hit := false
	var saw_ready_again := false
	while Time.get_ticks_msec() - begin < 12000 and is_instance_valid(actor) and is_instance_valid(wolf):
		if actor.combat_clip == "walk":
			if hits == 0: before_strike[actor.combat_frame] = true
			else: after_strike[actor.combat_frame] = true
		elif not actor.combat_clip.is_empty():
			swing[actor.combat_clip + str(actor.combat_frame)] = true
		if wolf.hit_frames.has(wolf.artwork.texture): saw_hit = true
		if saw_hit and wolf.ready_frames.has(wolf.artwork.texture): saw_ready_again = true
		if hits > 0 and not after_strike.is_empty() and actor.combat_clip.is_empty() and saw_ready_again: break
		await process_frame
	print("BLADE_STEPS enter=", before_strike.size(), " retreat=", after_strike.size(), " swing=", swing.keys(), " hits=", hits)
	expect(before_strike.size() >= 4 and after_strike.size() >= 4, "actual blade basic attack steps in and backs out with multiple different frames")
	expect(swing.has("fast_blade_chop0") and swing.has("fast_blade_chop1") and (swing.has("fast_sword_group1") or swing.has("fast_sword_group2")), "chop shows windup, transfer and impact")
	expect(hits == 1 and enemy.stats.hp < hp and actor.position.distance_to(home) < 0.1, "real attack applies damage with one strike and restores home slot")
	expect(saw_hit and saw_ready_again, "wolf returns to the idle loop after a real hit")
	finish()

func perform_sweep(actor: BattleActor, wolf: BattleActor) -> void:
	await actor.play_attack_approach(wolf, true)
	await actor.play_attack_recover()
	manual_done = true
