extends "res://build/quest_warrants_20261110/live.gd"

const INNOCENT := &"bianzhou_wronged_ferryman"
const ESCORT := &"jinling_wronged_escort"

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
	for city: StringName in bounty.OFFICES:
		var entries: Array = bounty.get_board_entries(city)
		expect(entries.size()==2 and entries==bounty.get_board_entries(city),"stable daily draw "+String(city))
		for def: BountyDef in bounty._board_pool(city):
			expect(bag.load_item_by_id(bounty._evidence_id(def.bounty_id))!=null,"proof "+String(def.bounty_id))
			if bounty.FIELD_LOOT.has(def.bounty_id):
				expect(bag.load_item_by_id(bounty.FIELD_LOOT[def.bounty_id]) is Equipment,"gear "+String(def.bounty_id))
	if "normal" in OS.get_cmdline_user_args():
		await hunt_live(bounty,bag)
		expect(bag.count_of(&"iron_sword")==1,"normal fugitive gear reaches bag")
	else:
		var id := ESCORT if "escort" in OS.get_cmdline_user_args() else INNOCENT
		var choice := 0 if "custody" in OS.get_cmdline_user_args() else (1 if "spare" in OS.get_cmdline_user_args() else 2)
		await wronged_live(bounty,bag,id,choice)
	finish()

func wronged_live(bounty: Node,bag: Node,id: StringName,choice: int) -> void:
	var def: BountyDef = bounty.get_definition(id)
	bounty.from_dict({"states":{String(id):{"status":&"active","location_index":0,"escape_count":0,"completion_count":0}}})
	state.add_reputation(30)
	var before_gold: int = state.gold
	var before_rep: int = state.reputation
	var proof: StringName = bounty._evidence_id(id)
	var companion: StringName = bounty.FALSE_CASES[id].companion
	var field := await enter(def.locations[0].scene_id)
	if field==null: return
	await settle(field)
	var target: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if is_instance_valid(npc) and npc.npc_id=="bounty_"+String(id):target=npc
	if not expect(is_instance_valid(target),"spawn new warrant NPC"): return
	state.player.skills.assign([&"basic_attack"])
	state.player.speed = 1000
	state.player.agility = 180
	var actor := await approach_officer(field,target)
	if not expect(actor!=null and target.try_interact(),"approach actual wanted NPC"): return
	if not expect(await wait_for(func(): return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1,23000),"real bounty battle ready"): return
	var battle := current_scene
	var enemies: Array = battle.get("_team_enemies")
	if not expect(enemies.size()==1,"wronged target is alone"): return
	var enemy: BattleCombatant = enemies[0]
	enemy.stats.hp=1
	var active: BattleCombatant=battle.get("_team_active_unit")
	var skills: Array=battle._skills_for_stats(active.stats)
	var skill:=0
	for i in skills.size():
		if skills[i].skill_id==&"basic_attack": skill=i
	var battle_ref: WeakRef = weakref(battle)
	for attempt in range(5):
		if not is_instance_valid(battle) or current_scene!=battle or not enemy.alive: break
		if battle.get("_state")==1:
			battle._team_player_action_skill_use(skill,enemy.unit_id)
		await wait_for(func():
			var current: Node = battle_ref.get_ref()
			return current_scene!=null and (current_scene!=current or (current!=null and current.get("_state")==1))
		,6500)
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/result_victory.tscn",26000),"victory result"): return
	expect(bounty._state_for(id).status==&"decision" and bag.count_of(proof)==0 and state.reputation==before_rep,"victory starts unresolved decision")
	bounty.from_dict(JSON.parse_string(JSON.stringify(bounty.to_dict())))
	current_scene.call("_on_continue_pressed")
	if not expect(await wait_for(func():return dialogue.is_playing() and String(dialogue.get("_current_script").dialog_id)=="warrant_testimony_"+String(id),26000),"return opens three-choice testimony"): return
	expect(dialogue.get("_current_node").choices.size()==3,"three moral choices")
	if "visual" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://warrant-decision.png")
	dialogue.choose(choice)
	var after_rep: int = before_rep-(0 if choice==0 else int(bounty.FALSE_CASES[id].penalty))
	expect(bounty._state_for(id).status==&"evidence" and bag.count_of(proof)==1,"settled disposition stores proof")
	expect(state.reputation==after_rep and state.gold==before_gold,"correct upfront reputation, no early money")
	expect((state.get_party_member(companion)!=null)==(choice==2),"only recruit adds companion")
	if choice==2:
		state.restore_party([{"character_id":String(companion)}])
		expect(state.get_party_member(companion)!=null,"companion resource restores from saved id")
	expect(not bounty.start_bounty(StringName("warrant_office_"+String(def.board_city))),"reject filing away from office")
	await wait_for(func():return not root.get_node("LoadingManager").get("_transition_active"))
	var city := await enter(bounty.OFFICES[def.board_city][0])
	if city==null: return
	await settle(city)
	var filed := false
	for npc: NPCNode in city.get("_npc_nodes"):
		if not is_instance_valid(npc) or npc.npc_id!="warrant_office_"+String(def.board_city): continue
		var arrived := await approach_officer(city,npc)
		if arrived!=null:
			print("FILING_APPROACH ",npc.npc_id," ",npc.interaction_action," distance=",arrived.global_position.distance_to(npc.global_position))
			await press_space()
			await process_frame
			filed=dialogue.is_playing() and String(dialogue.get("_current_script").dialog_id)=="warrant_report_"+String(def.board_city)
		break
	expect(filed and bounty._state_for(id).status==&"captured" and bag.count_of(proof)==0,"issuing office consumes proof")
	expect(state.gold==before_gold+def.reward_gold and state.reputation==after_rep+(def.reward_reputation if choice==0 else 0),"office pays once without restoring lost reputation")
	bounty._file_city_cases(def.board_city)
	expect(state.gold==before_gold+def.reward_gold,"cannot claim twice")
	expect(not bounty.accept_bounty(id).ok,"authored wronged case is not reposted")
	if choice==2:
		await settle(city)
		var opponents: Array[StringName] = [&"warrant_ferryman_hei"]
		router.start_encounter(opponents)
		if expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_team_allies").size()>=2,20000),"next battle instantiates recruited ally"):
			var found := false
			for ally: BattleCombatant in current_scene.get("_team_allies"):
				if ally.stats.character_id==String(companion): found=true
			expect(found,"recruited NPC fights in the player's formation")
