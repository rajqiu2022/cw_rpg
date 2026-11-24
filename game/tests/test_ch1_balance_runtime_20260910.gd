extends SceneTree

var checks := 0
var failed := 0
var probe: Node
var gs: Node
var inv: Node
var router: Node
var seed_count := 64
var results: Array[Dictionary] = []

func _init() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error(label)

func run() -> void:
	gs = root.get_node("GameState")
	inv = root.get_node("Inventory")
	router = root.get_node("SceneRouter")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seeds="): seed_count = maxi(1, int(arg.trim_prefix("--seeds=")))
	probe = load("res://scenes/battle.tscn").instantiate()
	probe.set_script(load("res://tests/fixtures/runtime_balance_probe_20260910.gd"))
	root.add_child(probe)
	var cases: Array[Dictionary] = [
		{"id":"tutorial_untrained", "enemy":"thug_lone", "trained":false},
		{"id":"forest_trained", "enemy":"linxi_wild_beast", "trained":true},
		{"id":"boss_techniques", "enemy":"boss_zhao_wuji", "trained":true, "level":3, "potions":true},
		{"id":"boss_basic_only", "enemy":"boss_zhao_wuji", "trained":true, "level":3, "basic":true, "potions":true},
		{"id":"boss_no_potions", "enemy":"boss_zhao_wuji", "trained":true, "level":3},
		{"id":"boss_wine", "enemy":"boss_zhao_wuji", "trained":true, "level":3, "wine":true, "potions":true},
		{"id":"forest_main_1", "group_dialog":"ch1_forest_beast_pack_encounter", "trained":true, "level":2, "potions":true},
		{"id":"forest_main_2", "group_dialog":"ch1_forest_beast_pack_encounter", "trained":true, "level":2, "party":2, "potions":true},
		{"id":"forest_main_3", "group_dialog":"ch1_forest_beast_pack_encounter", "trained":true, "level":2, "party":3, "potions":true},
		{"id":"boss_party2", "enemy":"boss_zhao_wuji", "trained":true, "level":3, "party":2, "potions":true},
		{"id":"boss_party3", "enemy":"boss_zhao_wuji", "trained":true, "level":3, "party":3, "potions":true},
		{"id":"boss_early_purple_veteran", "enemy":"boss_zhao_wuji", "trained":true, "level":1, "veteran":true, "purple":true, "potions":true},
		{"id":"dojo_beginner_L1", "enemy":"linxi_dojo_disciple", "trained":false, "solo":true},
		{"id":"dojo_senior_L1", "enemy":"linxi_dojo_senior", "trained":false, "solo":true},
		{"id":"south_militia_coach_L2", "enemy":"linxi_south_militia_coach", "trained":true, "level":2, "solo":true},
		{"id":"mountain_bandit_L1", "enemy":"bandit_mountain", "trained":false},
		{"id":"ch4_patrol_L6", "enemy":"luoyang_patrol", "trained":true, "level":6, "potions":true},
		{"id":"ch7_spy_L12", "enemy":"mingwu_spy", "trained":true, "level":12, "potions":true},
	]
	for sample in cases:
		var runs: Array[Dictionary] = []
		for seed_index in seed_count:
			setup_player(sample)
			var ids := sample_enemy_ids(sample)
			for id in ids: check(ResourceLoader.exists("res://data/enemies/%s.tres" % id), "sample cannot silently use fallback enemy")
			probe.initialize_units(ids, {"solo_player":sample.get("solo",false)})
			seed(20260910 + seed_index)
			runs.append(await fight(sample))
		var report := summarize(sample.id, runs)
		results.append(report)
		print("RUNTIME_SAMPLE ", JSON.stringify(report))
	await check_action_contracts()
	check_training_idempotence()
	await run_pressure_samples()
	await check_real_settlement()
	probe.release_fakes()
	probe.queue_free()
	await process_frame
	await process_frame
	print("[Ch1BalanceRuntime] checks=%d failed=%d seeds=%d" % [checks, failed, seed_count])
	quit(1 if failed else 0)

func setup_player(sample: Dictionary) -> void:
	gs.reset_for_new_game()
	inv.reset_for_new_game()
	root.get_node("QuestManager").reset_for_new_game()
	# Use authored early acquisition data instead of historical equipment IDs.
	for dialog_id in ["ch1_hero_bedroom_supply_chest", "ch1_tutorial_duqingshan"]:
		var script: DialogScript = load("res://data/dialogs/%s.tres" % dialog_id)
		for node: DialogNode in script.nodes:
			for gift: Dictionary in node.give_items:
				check(inv.add_item(StringName(gift.id), int(gift.get("count",1))), "authored starting gift exists")
	for item_id in [&"linxi_iron_sword", &"hemp_shirt", &"straw_sandals"]:
		check(inv.equip(item_id), "authored starting equipment equips")
	if sample.get("trained", false):
		apply_training()
	while gs.player.level < int(sample.get("level",1)):
		gs.player.gain_exp(gs.player.exp_required_for_next_level())
	if sample.get("wine",false):
		check(inv.add_item(&"linxi_jiu",1) and inv.use_item(&"linxi_jiu"), "optional wine uses real permanent-item path")
	if sample.get("purple",false):
		var treasure: DialogScript = load("res://data/dialogs/openworld_snow_treasure.tres")
		for node: DialogNode in treasure.nodes:
			for gift: Dictionary in node.give_items:
				check(inv.add_item(StringName(gift.id), int(gift.get("count",1))), "real early snow treasure equipment exists")
		check(inv.equip(&"heavy_iron_sword"), "actual early snow treasure heavy iron sword equips")
	if int(sample.get("party",1)) >= 2:
		check(gs.add_companion(&"tang_xingzhou"), "real Tang companion joins")
		equip_companion(&"tang_xingzhou", &"wooden_staff")
	if int(sample.get("party",1)) >= 3:
		check(gs.add_companion(&"shen_qinghe"), "real Qinghe companion joins")
		equip_companion(&"shen_qinghe", &"linxi_iron_sword")
	if sample.get("veteran",false):
		check(gs.add_companion(&"duan_changfeng"), "real level-eight open-world companion joins")
		equip_companion(&"duan_changfeng", &"iron_great_blade")
	# Each independent sample starts rested; multi-battle pressure is separate.
	gs.player.hp = gs.player.max_hp
	gs.player.mp = gs.player.max_mp

func equip_companion(character_id: StringName, item_id: StringName) -> void:
	check(inv.add_item(item_id,1), "companion weapon exists")
	for entry: Dictionary in inv.slots:
		if entry.item.item_id == item_id and not inv.is_instance_equipped(str(entry.get("instance_id",""))):
			check(inv.equip_instance_for(character_id, str(entry.instance_id)), "companion gets an independent matching weapon instance")
			return
	check(false, "companion weapon instance found")

func sample_enemy_ids(sample: Dictionary) -> Array[StringName]:
	if sample.has("group_dialog"):
		var script: DialogScript = load("res://data/dialogs/%s.tres" % sample.group_dialog)
		for node: DialogNode in script.nodes:
			if node.on_end.begins_with("battle_group:"):
				var ids: Array[StringName] = []
				for id in node.on_end.trim_prefix("battle_group:").split(","): ids.append(StringName(id))
				return router._adapt_authored_group_to_party(ids)
		check(false, "main group obtained from authored encounter dialogue")
	if sample.get("solo",false): return [StringName(sample.enemy)]
	return router._expanded_single_enemy_group(StringName(sample.enemy))

func apply_training() -> void:
	var script: DialogScript = load("res://data/dialogs/ch1_return_to_master.tres")
	for node: DialogNode in script.nodes:
		if node.node_id in [&"n7", &"n9", &"n10"]:
			root.get_node("DialogPlayer")._apply_node_side_effects(node)

func fight(sample: Dictionary) -> Dictionary:
	var rounds := 0
	var actions := 0
	var min_hp: int = gs.player.hp
	var initial_mp: int = gs.player.mp
	var paid := 0
	var basic := 0
	var potions := 0
	var heals := 0
	var ally_actions: Dictionary = {}
	while rounds < 60 and not probe.finished:
		rounds += 1
		var order: Array[BattleCombatant] = []
		order.append_array(probe._team_living_allies())
		order.append_array(probe._team_living_enemies())
		order.sort_custom(probe._sort_team_units)
		for unit in order:
			if probe._team_all_dead(probe._team_enemies): probe._team_finish(true)
			elif probe._team_all_dead(probe._team_allies): probe._team_finish(false)
			if probe.finished: break
			if not unit.alive: continue
			probe._team_active_unit = unit
			var skipped: bool = await probe._team_apply_turn_start_status(unit)
			min_hp = mini(min_hp, gs.player.hp)
			if skipped:
				await probe._team_after_action()
				continue
			unit.action_points = 1
			actions += 1
			if unit.team == BattleCombatant.Team.ENEMY:
				await probe._do_team_enemy_turn()
			else:
				ally_actions[String(unit.unit_id)] = int(ally_actions.get(String(unit.unit_id),0)) + 1
				probe._state = probe.State.PLAYER_TURN
				if sample.get("potions",false) and potions < 2 and unit.stats.hp <= int(unit.stats.max_hp * 0.45):
					var hp_before := unit.stats.hp
					if inv.use_item_for(StringName(unit.stats.character_id), &"healing_pill_minor", true):
						potions += 1
						await probe._on_battle_inventory_action(&"use_item")
						check(unit.action_points == 0 and unit.stats.hp > hp_before, "real potion heals and consumes entire action")
						continue
				var skills: Array[Skill] = probe._skills_for_stats(unit.stats)
				var index := select_skill(skills, unit.stats, bool(sample.get("basic", false)))
				var heal_target: BattleCombatant = null
				if not sample.get("basic",false):
					for ally: BattleCombatant in probe._team_living_allies():
						if ally.stats.hp < int(ally.stats.max_hp*0.55) and (heal_target == null or ally.stats.hp < heal_target.stats.hp): heal_target = ally
					if heal_target != null:
						for i in skills.size():
							if skills[i].kind == Skill.Kind.HEAL and probe._can_use_skill(skills[i],unit.stats):
								index = i
								break
				if index < 0:
					await probe._team_player_action_defend()
				else:
					var before_mp := unit.stats.mp
					var skill := skills[index]
					if skill.mp_cost > 0: paid += 1
					if skill.skill_id == &"basic_attack": basic += 1
					var target: BattleCombatant = heal_target if skill.kind == Skill.Kind.HEAL else probe._team_living_enemies()[0]
					if skill.kind == Skill.Kind.HEAL: heals += 1
					await probe._team_player_action_skill_use(index, target.unit_id)
					check(before_mp - unit.stats.mp == skill.mp_cost, "actual player action consumes exactly authored MP")
			min_hp = mini(min_hp, gs.player.hp)
			for actor: BattleCombatant in probe._team_allies + probe._team_enemies:
				check(actor.stats.mp >= 0, "no negative MP")
		# Production checks terminal state before starting another round. A lethal
		# last enemy action or last-unit DOT must not add an empty reporting round.
		if not probe.finished:
			if probe._team_all_dead(probe._team_enemies): probe._team_finish(true)
			elif probe._team_all_dead(probe._team_allies): probe._team_finish(false)
	if not probe.finished:
		if probe._team_all_dead(probe._team_enemies): probe._team_finish(true)
		elif probe._team_all_dead(probe._team_allies): probe._team_finish(false)
	check(probe.finished, "finite battle terminates before 60-round cap")
	return {"win":probe.won,"rounds":rounds,"actions":actions,"min_hp":min_hp,"mp_used":initial_mp-gs.player.mp,"paid":paid,"basic":basic,"potions":potions,"heals":heals,"ally_actions":ally_actions,"damage_one":probe.damage_samples.count(1),"damage_count":probe.damage_samples.size()}

func select_skill(skills: Array[Skill], stats: CharacterStats, basic_only: bool) -> int:
	var chosen := -1
	var score := -1
	for i in skills.size():
		var skill := skills[i]
		if skill.kind != Skill.Kind.ATTACK or not probe._can_use_skill(skill, stats): continue
		if basic_only and skill.skill_id != &"basic_attack": continue
		# Static, public authored-power preference, never roll hypothetical damage.
		var candidate := skill.fixed_damage + skill.get_attack_scaling()
		if candidate > score:
			score = candidate
			chosen = i
	return chosen

func check_training_idempotence() -> void:
	setup_player({})
	check(&"linxi_basic_sword_two" not in gs.player.skills and &"linxi_inner_breath" not in gs.player.skills, "fresh character has not received advanced master lesson")
	apply_training()
	check(gs.player.skills.count(&"linxi_basic_sword_two") == 1 and gs.player.skills.count(&"linxi_inner_breath") == 1, "actual n7/n9/n10 effects teach both techniques exactly once")
	gs.player.hp = 51
	gs.player.mp = 17
	var saver: Node = load("res://tests/fixtures/memory_save_probe_20260910.gd").new()
	var before: Dictionary = saver._serialize_stats(gs.player)
	apply_training()
	gs.reconcile_progression_rewards()
	check(saver._serialize_stats(gs.player) == before, "repeat lesson and reconciliation do not duplicate passives or refill resources")
	check(inv.add_item(&"linxi_jiu",1) and inv.use_item(&"linxi_jiu"), "permanent wine normal use")
	var wine_hp: int = gs.player.max_hp
	var wine_mp: int = gs.player.max_mp
	gs.player.hp = 1
	gs.player.mp = 0
	check(gs.player.gain_exp(gs.player.exp_required_for_next_level()), "actual level-up reward path executes")
	check(gs.player.hp == gs.player.max_hp and gs.player.mp == gs.player.max_mp and gs.player.max_hp >= wine_hp and gs.player.max_mp >= wine_mp, "level-up restores resources and preserves wine capacities")
	check(saver.save_to_slot(0), "actual serializer writes only memory fixture")
	gs.reset_for_new_game()
	check(saver.load_from_slot(0), "actual restorer reads memory fixture")
	check(gs.player.max_hp >= wine_hp and gs.player.skills.count(&"linxi_inner_breath") == 1, "save restore keeps permanent wine and lesson idempotence")
	saver.free()

func check_action_contracts() -> void:
	setup_player({"trained":true,"party":3})
	check(probe._build_player_party_payload({"solo_player":true}).size() == 1 and probe._build_player_party_payload({"battle_mode":&"sparring"}).size() == 1, "formal solo and spar exclude two persistent companions")
	var authored: Array[StringName] = [&"zhuwei_bandit",&"zhuwei_bandit",&"zhuwei_bandit"]
	check(router._adapt_authored_group_to_party(authored).size() == 3, "three allies retain authored three enemies")
	setup_player({"trained":true})
	check(router._adapt_authored_group_to_party(authored).size() == 2, "solo authored encounter is capped at two enemies")
	probe.initialize_units([&"boss_zhao_wuji"] as Array[StringName])
	var unit: BattleCombatant = probe._team_allies[0]
	var enemy: BattleCombatant = probe._team_enemies[0]
	probe._team_active_unit = unit
	probe._state = probe.State.PLAYER_TURN
	unit.action_points = 2
	await probe._team_player_action_defend()
	check(unit.status_effects.get("guard",0) == 1 and unit.action_points == 0, "actual defend applies guard and ends all actions")
	unit.status_effects = {"stun":1,"internal_lock":2,"damage_boost":2,"damage_boost_percent":20,"burst":2}
	check(await probe._team_apply_turn_start_status(unit), "real stun skips action")
	await probe._team_after_action()
	check(unit.status_effects.internal_lock == 1 and unit.status_effects.damage_boost == 1 and unit.status_effects.burst == 1, "skipped turn still uses real end-of-action expiry")
	unit.status_effects.clear()
	unit.stats.mp = 3
	probe._state = probe.State.PLAYER_TURN
	unit.action_points = 1
	var skills: Array[Skill] = probe._skills_for_stats(unit.stats)
	var first_index := -1
	var basic_index := -1
	for i in skills.size():
		if skills[i].skill_id == &"linxi_basic_sword_one": first_index = i
		if skills[i].skill_id == &"basic_attack": basic_index = i
	var before_enemy_hp := enemy.stats.hp
	await probe._team_player_action_skill_use(first_index,enemy.unit_id)
	check(unit.stats.mp == 3 and enemy.stats.hp == before_enemy_hp and unit.action_points == 1, "insufficient MP refuses action without spending turn")
	unit.stats.mp = 0
	enemy.stats.hp = 1
	unit.action_points = 2
	seed(424242)
	await probe._team_player_action_skill_use(basic_index,enemy.unit_id)
	check(probe.finished and probe.won and unit.stats.mp == 0, "zero-MP real basic attack finishes battle immediately despite extra AP")
	# Synthetic durability is confined to action contracts, never balance samples.
	probe.initialize_units([&"gufeng_trainee"] as Array[StringName])
	unit = probe._team_allies[0]
	enemy = probe._team_enemies[0]
	unit.stats.max_hp = 100000
	unit.stats.hp = 100000
	enemy.stats.mp = 4
	probe._team_active_unit = enemy
	seed(20260910)
	for i in 20: await probe._do_team_enemy_turn()
	check(enemy.stats.mp == 0 and probe.chosen_enemy_skills.has("basic_attack"), "real enemy AI spends finite MP and falls back to free attack")
	check(probe.chosen_enemy_skills.get("gufeng_kaishan_yidao",0) <= 1, "4-MP enemy cannot cast 4-MP signature twice")

func run_pressure_samples() -> void:
	for use_wine in [false,true]:
		var completed := 0
		var hp_sum := 0
		var mp_sum := 0
		var potion_sum := 0
		for seed_index in seed_count:
			setup_player({"trained":true,"level":2,"wine":use_wine})
			var all_won := true
			for encounter_index in 3:
				probe.initialize_units(sample_enemy_ids({"group_dialog":"ch1_forest_beast_pack_encounter"}))
				seed(20260910 + seed_index*10 + encounter_index)
				var result := await fight({"potions":false})
				potion_sum += result.potions
				if not result.win:
					all_won = false
					break
			if all_won: completed += 1
			hp_sum += gs.player.hp
			mp_sum += gs.player.mp
		print("PRESSURE_SAMPLE ", JSON.stringify({"id":"three_forest_groups_wine" if use_wine else "three_forest_groups_no_wine","runs":seed_count,"completed":completed,"end_hp_mean":float(hp_sum)/seed_count,"end_mp_mean":float(mp_sum)/seed_count,"potions":potion_sum,"settlement":"intercepted_no_xp_no_refill"}))

func check_real_settlement() -> void:
	# Swap only the presentation seam on the real singleton in this QA process.
	# No transition creates result UI and no save entrypoint is invoked.
	router.set_script(load("res://tests/fixtures/quiet_settlement_router_20260910.gd"))
	setup_player({"trained":true})
	probe.initialize_units([&"thug_lone"] as Array[StringName])
	gs.player.exp = gs.player.exp_required_for_next_level() - 1
	gs.player.hp = 10
	gs.player.mp = 0
	var level_before: int = gs.player.level
	var gold_before: int = gs.gold
	var ordinary_events: Array[StringName] = []
	var end_events: Array[bool] = []
	var on_enemy := func(id: StringName) -> void: ordinary_events.append(id)
	var on_end := func(victory: bool, _fled: bool) -> void: end_events.append(victory)
	root.get_node("EventBus").enemy_defeated.connect(on_enemy)
	root.get_node("EventBus").battle_ended.connect(on_end)
	probe._team_enemies[0].stats.hp = 0
	probe._team_enemies[0].alive = false
	router._battle_payload = {"enemy_id":"thug_lone","return_scene":&"ch1_s1_road"}
	await probe.settle_real(true)
	check(ordinary_events == [&"thug_lone"] and end_events == [true], "actual team victory emits one enemy-defeated and one battle-ended event")
	check(gs.gold > gold_before and gs.player.level > level_before and gs.player.hp == gs.player.max_hp and gs.player.mp == gs.player.max_mp, "actual team drop/XP settlement levels and restores resources")
	check(not router.transition_paths.is_empty(), "actual settlement reaches intercepted result navigation")
	setup_player({"trained":true,"party":3})
	var expected_rewards := [3,0,12,0,0]
	var outcomes := [false,false,true,true,false]
	var training_before: int = gs.training_points_total
	var event_count_before := ordinary_events.size()
	var gold_at_spar: int = gs.gold
	for i in outcomes.size():
		var snapshots: Array[Dictionary] = []
		for member: CharacterStats in gs.party:
			member.hp = member.max_hp - 17
			member.mp = member.max_mp - 9
			snapshots.append({"character_id":member.character_id,"hp":member.hp,"mp":member.mp})
		router.start_sparring(&"qa_runtime_coach","教头","linxi_dojo_senior",12,3,&"linxi_village_scrollmap")
		probe.initialize_units([&"linxi_dojo_senior"] as Array[StringName],router.get_battle_payload())
		check(probe._team_allies.size() == 1, "actual spar payload produces solo player formation")
		gs.player.hp = 0 if not outcomes[i] else 1
		gs.player.mp = 0
		await probe.settle_real(outcomes[i])
		check(router.get_result_payload().training == expected_rewards[i], "actual spar result reward matrix loss-loss-win-win-loss")
		for row in snapshots:
			var member: CharacterStats = gs.get_party_member(StringName(row.character_id))
			check(member.hp == row.hp and member.mp == row.mp, "actual spar settlement restores each prebattle snapshot")
	check(gs.training_points_total-training_before == 15 and gs.gold == gold_at_spar and ordinary_events.size() == event_count_before, "spar grants only one loss and one victory training reward, no ordinary gold/defeat events")
	root.get_node("EventBus").enemy_defeated.disconnect(on_enemy)
	root.get_node("EventBus").battle_ended.disconnect(on_end)

func summarize(id: String, runs: Array[Dictionary]) -> Dictionary:
	var report := {"id":id,"runs":runs.size(),"wins":0,"rounds_mean":0.0,"min_hp_mean":0.0,"mp_used_mean":0.0,"paid_mean":0.0,"basic_mean":0.0,"potions_mean":0.0,"heals_mean":0.0,"damage_one_ratio":0.0,"ally_actions_mean":{}}
	var rounds: Array[int] = []
	var one := 0
	var count := 0
	for row in runs:
		if row.win: report.wins += 1
		rounds.append(row.rounds)
		for key in ["rounds","min_hp","mp_used","paid","basic","potions","heals"]: report[key+"_mean"] += float(row[key])/runs.size()
		for id_key in row.ally_actions:
			report.ally_actions_mean[id_key] = float(report.ally_actions_mean.get(id_key,0.0)) + float(row.ally_actions[id_key])/runs.size()
		one += row.damage_one
		count += row.damage_count
	rounds.sort()
	report["rounds_p50"] = rounds[int((rounds.size()-1)*0.5)]
	report["rounds_p90"] = rounds[int((rounds.size()-1)*0.9)]
	report.damage_one_ratio = float(one)/maxi(1,count)
	return report
