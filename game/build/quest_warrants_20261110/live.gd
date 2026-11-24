extends "res://build/victory_quest_20261108/story_live.gd"

const CASE := &"bianzhou_roaming_thief"
const ROUTE := &"ch6_s4_baishui_convoy_route"

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
	var bounty: Node = root.get_node("BountyManager")
	var bag: Node = root.get_node("Inventory")
	bounty.reset_for_new_game()
	if "relief" in OS.get_cmdline_user_args():
		await relief_live(bag)
		finish()
		return
	for city: StringName in bounty.OFFICES:
		var pool: Array = bounty._board_pool(city)
		var expected_count := 4 if city in [&"bianzhou",&"jinling"] else 3
		expect(pool.size() == expected_count, "case definitions " + String(city))
		expect(bounty.get_board_entries(city).size() == 2, "two visible slots " + String(city))
		for def: BountyDef in pool:
			expect(bag.load_item_by_id(bounty._evidence_id(def.bounty_id)) != null, "evidence " + String(def.bounty_id))
			for enemy: StringName in def.enemy_ids:
				expect(load("res://data/enemies/%s.tres" % enemy) != null, "enemy " + String(enemy))
			for reward: Dictionary in def.reward_items:
				expect(bag.load_item_by_id(StringName(reward.item_id)) != null, "reward " + String(reward.item_id))
	if "compile" in OS.get_cmdline_user_args():
		finish()
		return
	if "hunt" in OS.get_cmdline_user_args():
		await hunt_live(bounty, bag)
		finish()
		return
	var id: StringName = &""
	for entry: Dictionary in bounty.get_board_entries(&"bianzhou"):
		if not bounty.FALSE_CASES.has(entry.bounty_id):
			id=StringName(entry.bounty_id)
			break
	if not expect(id!=&"","board keeps at least one regular case"):
		finish()
		return
	var definition: BountyDef = bounty.get_definition(id)
	expect(bounty.accept_bounty(id).ok, "accept posted case")
	expect(not bounty.accept_bounty(id).ok, "cannot accept twice")
	var gold: int = state.gold
	var renown: int = state.reputation
	var evidence: StringName = bounty._evidence_id(id)
	expect(not bounty.resolve_victory(id).is_empty(), "battle callback creates evidence")
	expect(state.gold == gold and state.reputation == renown and bag.count_of(evidence) == 1, "no bounty money before filing")
	expect(bounty.resolve_victory(id).is_empty(), "no duplicate evidence")
	var staged: Dictionary = bounty.to_dict()
	bounty.from_dict(staged)
	expect(bounty._state_for(id).status == &"evidence", "pending survives in-memory serialization")
	expect(not bounty.start_bounty(&"warrant_office_bianzhou"), "reject from other map")
	var city := await enter(&"openworld_bianzhou_city")
	if city != null:
		await settle(city)
		var officer: Node2D
		for npc: Node2D in city.get("_npc_nodes"):
			if is_instance_valid(npc) and npc.get("npc_id") == "warrant_office_bianzhou":
				officer = npc
				break
		if expect(is_instance_valid(officer), "actual city has officer"):
			var actor := await approach_officer(city, officer)
			expect(actor != null and officer.try_interact(), "nearby interaction requests officer")
			if expect(await wait_for(func(): return dialogue.is_playing() and dialogue.get("_current_script").dialog_id == &"warrant_report_bianzhou",2500),"officer dialogue"):
				for i in range(8):
					if not dialogue.is_playing(): break
					dialogue.advance()
					await process_frame
			expect(state.gold == gold + definition.reward_gold and state.reputation == renown + definition.reward_reputation and bag.count_of(evidence)==0, "pay exact once and consume evidence")
			expect(not bounty.accept_bounty(id).ok, "same-day case cannot be accepted after filing")
			bounty._file_city_cases(&"bianzhou")
			expect(state.gold == gold + definition.reward_gold, "no double payment")
	for office_id: StringName in [&"luoyang_yamen_official_hall_20261018t", &"openworld_xiangzhou_city", &"openworld_jinling_city"]:
		var field := await enter(office_id)
		if field == null: continue
		await settle(field)
		var found := false
		for npc: Node2D in field.get("_npc_nodes"):
			if not is_instance_valid(npc) or not String(npc.get("npc_id")).begins_with("warrant_office_"): continue
			found = true
			print("OFFICE ", office_id, " ", npc.global_position, " spawn=", field.get("_player").global_position, " canvas=",field.get("_screen_size"))
			if expect(await approach_officer(field, npc) != null, "walkable " + String(office_id)):
				expect(npc.try_interact(), "nearby officer interaction " + String(office_id))
				expect(dialogue.is_playing() and String(dialogue.get("_current_script").dialog_id).begins_with("warrant_report_"), "official dialogue " + String(office_id))
				while dialogue.is_playing() and not dialogue.get("_current_node").has_choices():
					dialogue.advance()
					await process_frame
		expect(found, "actual officer " + String(office_id))
	quests.accept(&"q_ch6_main_04_old_convoy_route")
	state.current_chapter = 6
	state.set_flag(&"ch6_old_convoy_route_unlocked", true)
	var road := await enter(ROUTE)
	if road != null:
		await settle(road)
		var cart := area(road, "ch6_baishui_cart")
		expect(cart == null or not road.call("_flag_truthy", "ch6_baishui_milestone_checked"), "trace starts locked")
		if await inspect(road, "ch6_baishui_milestone", &"ch6_baishui_milestone"):
			await create_timer(0.4).timeout
			await inspect(road, "ch6_baishui_cart", &"ch6_baishui_cart_trace")
			expect(state.flags.get("ch6_baishui_cart_checked",false), "wheel trace recorded")
			await create_timer(0.5).timeout
		await inspect(road, "ch6_courier_sign", &"ch6_courier_tally_start", [0])
		await create_timer(0.5).timeout
		expect(quests.is_active(&"q_ch6_side_04_courier_tally"), "optional tally accepted")
		var before_cloth: int = bag.count_of(&"cloth_roll")
		await inspect(road, "ch6_courier_crate", &"ch6_courier_tally_crate", [0,1])
		expect(quests.is_completed(&"q_ch6_side_04_courier_tally") and bag.count_of(&"cloth_roll") == before_cloth + 2, "optional tally solved after wrong guess and grant reward")
		await create_timer(0.5).timeout
		expect(area(road, "ch6_courier_crate") == null, "cleared hidden clue cannot repeat")
	finish()

func approach_officer(field: Node, officer: Node2D) -> Player:
	var registry: Script = load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	for offset in [Vector2(0,68), Vector2(68,0), Vector2(-68,0), Vector2(0,-68), Vector2(65,65), Vector2(-65,65), Vector2(65,-65), Vector2(-65,-65)]:
		var actor := await position_at(field, officer.global_position + offset)
		var clear: bool = registry.actor_shape_clear(actor)
		if router.get_current_field_id() == &"luoyang_yamen_official_hall_20261018t":
			clear = field.call("_interior_safe_position",actor.global_position,true)
		if clear and actor.global_position.distance_to(officer.global_position) <= 118.0:
			return actor
		if router.get_current_field_id()==&"luoyang_yamen_official_hall_20261018t":
			print("OFFICE_PROBE ",actor.global_position," clear=",registry.actor_shape_clear(actor)," distance=",actor.global_position.distance_to(officer.global_position))
	return null

func hunt_live(bounty: Node, bag: Node) -> void:
	var id := &"bianzhou_roaming_thief"
	var def: BountyDef = bounty.get_definition(id)
	# Set up a deterministic posted solo case and hideout. Battle and settlement are real.
	bounty.from_dict({"states":{"bianzhou_roaming_thief":{"status":&"active","location_index":0,"escape_count":0,"completion_count":0}}})
	var field := await enter(&"openworld_bianzhou_old_post")
	if field == null: return
	await settle(field)
	var target: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if is_instance_valid(npc) and npc.npc_id == "bounty_bianzhou_roaming_thief":
			target = npc
			break
	if not expect(is_instance_valid(target), "wanted target spawned at the hideout"): return
	state.player.skills.assign([&"basic_attack"])
	state.player.speed = 1000
	state.player.agility = 180
	var actor := await approach_officer(field,target)
	if not expect(actor != null and target.try_interact(), "nearby wanted target starts battle"): return
	if not expect(await wait_for(func(): return current_scene != null and current_scene.scene_file_path.contains("battle") and current_scene.get("_state")==1), "ready wanted battle"): return
	var battle := current_scene
	var enemies: Array = battle.get("_team_enemies")
	if not expect(enemies.size()==1, "expected solo target"): return
	var enemy: BattleCombatant = enemies[0]
	enemy.stats.hp = 1
	var active: BattleCombatant = battle.get("_team_active_unit")
	var skills: Array = battle._skills_for_stats(active.stats)
	var basic := -1
	for i in skills.size():
		if skills[i].skill_id==&"basic_attack":
			basic = i
			break
	if not expect(basic >= 0, "player can use basic attack"): return
	var battle_ref: WeakRef = weakref(battle)
	for attempt in range(4):
		if not is_instance_valid(battle) or current_scene != battle or not enemy.alive: break
		if battle.get("_state")==1:
			battle._team_player_action_skill_use(basic,enemy.unit_id)
		await wait_for(func():
			var current_battle: Node = battle_ref.get_ref()
			return current_scene!=null and (current_scene!=current_battle or (current_battle!=null and current_battle.get("_state")==1))
		,6500)
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/result_victory.tscn",16000),"battle win uses victory router"): return
	var evidence: StringName = bounty._evidence_id(id)
	expect(bag.count_of(evidence)==1 and bounty._state_for(id).status==&"evidence", "real victory records exactly one case item")
	expect(router.get_result_payload().get("bounty_result",{}).get("summary","").contains("物证"), "result tells player to file")
	expect(state.reputation==0 and state.gold==0,"no warrant reward on victory")
	await wait_for(func(): return not root.get_node("LoadingManager").get("_transition_active"))
	var city := await enter(&"openworld_bianzhou_city")
	if city == null: return
	await settle(city)
	for npc: NPCNode in city.get("_npc_nodes"):
		if is_instance_valid(npc) and npc.npc_id=="warrant_office_bianzhou":
			var arrived := await approach_officer(city,npc)
			if expect(arrived != null and npc.try_interact(), "real evidence submitted at issuing office"):
				expect(state.gold == def.reward_gold and state.reputation == def.reward_reputation and bag.count_of(evidence)==0, "regional payment settles once")
			return
	expect(false,"issuing officer missing")

func inspect(field: Node, id: String, dialog_id: StringName, choices: Array[int] = []) -> bool:
	var trigger := area(field, id)
	if not expect(trigger != null, "spawned " + id): return false
	var actor := await position_at(field, trigger.global_position)
	var hits := await wait_for(func(): return is_instance_valid(trigger) and trigger.overlaps_body(actor), 1000)
	var clear := check_clear(actor, id)
	if not expect(hits and clear, "clear interaction footprint %s foot=%s zone=%s overlap=%s" % [id,actor.global_position,trigger.global_position,hits]): return false
	field.call("_on_player_interacted")
	if not expect(dialogue.is_playing() and dialogue.get("_current_script").dialog_id == dialog_id, "nearby object opens " + id):
		print("INTERACTION_DEBUG ", id, " can_move=", actor.can_move, " dialogue=", dialogue.get("_current_script"), " trigger=", trigger.get_meta("trigger_data"))
		return false
	for choice in choices:
		dialogue.choose(choice)
		if dialogue.is_playing() and not dialogue.get("_current_node").has_choices():
			dialogue.advance()
	while dialogue.is_playing() and not dialogue.get("_current_node").has_choices():
		dialogue.advance()
	return expect(not dialogue.is_playing(), "dialogue closed " + id)

func relief_live(bag: Node) -> void:
	const TASK := &"q_ch5_side_01_relief_receipt"
	state.current_chapter = 5
	state.set_flag(&"ch5_relief_road_cleared", true)
	var field := await enter(CAMP)
	if field == null: return
	await settle(field)
	expect(area(field, "ch5_relief_receipt_start") == null, "side commission does not compete with rescue")
	state.set_flag(&"ch5_grain_convoy_saved", true)
	await settle(field)
	expect(area(field, "ch5_relief_receipt_seal") == null, "no seal hotspot before accepting")
	if not await inspect(field,"ch5_relief_receipt_start",&"ch5_relief_receipt_start",[0]): return
	await settle(field)
	expect(quests.is_active(TASK) and area(field,"ch5_relief_receipt_report")==null,"report locked until evidence")
	if not await inspect(field,"ch5_relief_receipt_seal",&"ch5_relief_receipt_seal"): return
	await settle(field)
	var timber: int = bag.count_of(&"timber_bundle")
	if not await inspect(field,"ch5_relief_receipt_report",&"ch5_relief_receipt_report"): return
	await settle(field)
	expect(quests.is_completed(TASK) and bag.count_of(&"timber_bundle")==timber+2,"report completes with material reward")
	expect(area(field,"ch5_relief_receipt_report")==null and area(field,"ch5_relief_receipt_seal")==null,"no repeatable completion")
	expect(area(field,"legacy_hotspot_1")!=null and not state.flags.get("ch5_false_banner_cloth_found",false),"main evidence remains independent")
