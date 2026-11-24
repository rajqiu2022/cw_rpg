extends "res://build/victory_quest_20261108/story_live.gd"

var strikes := 0
var finished := false
var returning := false
var runtime: Node

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router = root.get_node("SceneRouter")
	state = root.get_node("GameState")
	quests = root.get_node("QuestManager")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	state.player.speed = 1000
	state.player.agility = 180
	expect(state.add_companion(&"tang_xingzhou"), "isolated party includes Tang")
	var inventory := root.get_node("Inventory")
	runtime = root.get_node("LayeredAppearanceRuntime")
	router.start_battle("zhuwei_cave_wolf", &"ch1_s4_zhuwei_beast_cave", Vector2(0.5, 0.82))
	if not expect(await wait_for(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/battle.tscn" and current_scene.get("_state") == 1, 18000), "formal battle enters player turn"):
		finish()
		return
	var battle := current_scene
	var hero: BattleActor = battle.formation_view.get_actor(&"player")
	var wolf: BattleActor = battle.formation_view.get_actor(battle._team_enemies[0].unit_id)
	var tang: BattleActor = battle.formation_view.get_actor(&"tang_xingzhou")
	if expect(tang != null, "Tang is in the formal battle formation"):
		await sample_partner(tang, wolf, 3)
	await sample_partner(wolf, hero, 2)
	hero.strike_reached.connect(func(): strikes += 1)
	for profile in [
		[&"seven_star_sword", "", "", "fast_slash1", true],
		[&"seven_star_sword", "linxi_basic_sword_one", "", "fast_slash3", true],
		[&"golden_hoop_staff", "", "", "fast_staff3", true],
		[&"", "", "attack_fist", "fast_palm_fist2", true],
		[&"", "wudang_mianzhang", "attack_palm", "fast_palm3", true],
		[&"shooting_star", "", "", "fast_hidden_single1", false],
		[&"seven_star_sword", "wanxiang_breaking_sword", "", "fast_slash1", true],
	]:
		if profile[0] == &"":
			inventory.unequip(Equipment.Slot.WEAPON)
		else:
			inventory.add_item(profile[0])
			inventory.equip(profile[0])
		hero.action_skill = load("res://data/skills/"+profile[1]+".tres") as Skill if not profile[1].is_empty() else null
		hero.action_pose = profile[2]
		hero.legendary_choreography = profile[1] == "wanxiang_breaking_sword"
		await process_frame
		await sample(hero, wolf, profile[3], profile[4], hero.legendary_choreography)
	var enemy: BattleCombatant = battle._team_enemies[0]
	inventory.add_item(&"shooting_star")
	inventory.equip(&"shooting_star")
	var skills: Array = battle._skills_for_stats(battle._team_active_unit.stats)
	var basic := -1
	for i in skills.size():
		if skills[i].skill_id == &"basic_attack": basic = i
	if expect(basic >= 0, "actual dark weapon basic attack is selectable"):
		var home := hero.position
		var hp := enemy.stats.hp
		strikes = 0
		battle._team_player_action_skill_use(basic, enemy.unit_id)
		var max_slide := 0.0
		var deadline := Time.get_ticks_msec() + 8000
		while Time.get_ticks_msec() < deadline:
			max_slide = maxf(max_slide, home.distance_to(hero.position))
			if strikes == 1 and enemy.stats.hp < hp and hero.combat_clip.is_empty(): break
			await process_frame
		expect(strikes == 1 and enemy.stats.hp < hp and max_slide < 0.5, "actual dark weapon attack deals one strike without running up or sliding")
	finish()

func sample(hero: BattleActor, enemy: BattleActor, release: String, travel: bool, flip: bool) -> void:
	var home := hero.position
	var approach_frames := {}
	var retreat_frames := {}
	var leap_frames := {}
	var rendered_release := false
	var left_home := false
	finished = false
	returning = false
	strikes = 0
	run_motion(hero, enemy, travel)
	var deadline := Time.get_ticks_msec() + 6000
	while not finished and Time.get_ticks_msec() < deadline:
		var pose: Node2D = runtime.actors.get(hero.get_instance_id(), {}).get("pose")
		if pose != null:
			if pose.current_clip + str(pose.current_frame) == release:
				rendered_release = true
			if pose.current_clip == "walk":
				if returning: retreat_frames[pose.current_frame] = true
				else: approach_frames[pose.current_frame] = true
			if pose.current_clip == "fast_leap": leap_frames[pose.current_frame] = true
		left_home = left_home or hero.position.distance_to(home) > 1.0
		await process_frame
	print("FOLLOW_THROUGH ",release," in=",approach_frames.size()," out=",retreat_frames.size()," leap=",leap_frames.keys()," strike=",strikes)
	expect(rendered_release and strikes == 1, release+" actual layered release and one strike")
	expect(finished and hero.position.distance_to(home) < 0.1 and hero.combat_clip.is_empty() and not hero._manual_animation, release+" returns to guard and original feet")
	if travel:
		expect(left_home and retreat_frames.size() >= 4 and (leap_frames.size() == 4 if flip else approach_frames.size() >= 4), release+" changes actual approach and retreat sprites")
	else:
		expect(not left_home, release+" keeps both feet at its own slot")

func run_motion(hero: BattleActor, enemy: BattleActor, travel: bool) -> void:
	if travel:
		await hero.play_attack_approach(enemy, hero.action_skill != null)
		returning = true
		await hero.play_attack_recover()
	else:
		await hero.play_stationary_attack(enemy, hero.action_skill != null)
	finished = true

func sample_partner(actor: BattleActor, target: BattleActor, minimum: int) -> void:
	var home := actor.position
	var counted := [0]
	var on_strike := func(): counted[0] += 1
	actor.strike_reached.connect(on_strike)
	var incoming := {}
	var outgoing := {}
	var attacks := {}
	finished = false
	returning = false
	run_motion(actor, target, true)
	var deadline := Time.get_ticks_msec() + 6000
	while not finished and Time.get_ticks_msec() < deadline:
		var actual := actor.artwork.texture
		if actor.move_frames.has(actual):
			if returning: outgoing[actual] = true
			else: incoming[actual] = true
		if actor.attack_frames.has(actual): attacks[actual] = true
		await process_frame
	actor.strike_reached.disconnect(on_strike)
	print("AUTHORED_ACTOR ",actor.unit_id," in=",incoming.size()," out=",outgoing.size()," attack=",attacks.size())
	expect(actor.stepped_combat and incoming.size() >= minimum and outgoing.size() >= minimum, String(actor.unit_id)+" uses native feet in both directions")
	expect(attacks.size() >= 3 and counted[0] == 1 and actor.ready_frames.has(actor.artwork.texture) and actor.position.distance_to(home) < 0.1, String(actor.unit_id)+" swings once and returns to guard at exact home")
