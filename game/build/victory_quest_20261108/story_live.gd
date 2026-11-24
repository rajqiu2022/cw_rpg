extends "res://build/quest_map_audit_20261108/huilan_live.gd"

const COTTAGE := &"linxi_farmer_cottage"
const MASTER := &"linxi_master_hall"
const ARCHIVE := &"ch6_s3_underground_archive"
const ROAD := &"ch5_s1_relief_road"
const CAMP := &"ch5_s2_grain_convoy_camp"
const PASS := &"ch5_s3_snow_pass"
const MINE := &"ch5_s4_abandoned_mine"
const OUTPOST := &"ch5_s5_false_banner_outpost"
const LIEYUN := &"ch7_s1_lieyun_valley_ferry"
const LIEYUN_WARD := &"ch7_s3_lieyun_outpost_outer_ward"
const MINGWU := &"ch7_s2_mingwu_tea_town"
const MINGWU_WARD := &"ch7_s4_mingwu_manor_outer_court"
const MUSTER := &"ch8_s1_alliance_staging_ground"
const MISTWOOD := &"ch8_s2_mistwood_blockade"
const PERIMETER := &"ch8_s3_manor_perimeter_encampment"
const GALLERY := &"ch8_s4_alliance_mechanism_gallery"
const PLATFORM := &"ch8_s5_alliance_ceremonial_platform"

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router=root.get_node("SceneRouter")
	state=root.get_node("GameState")
	quests=root.get_node("QuestManager")
	dialogue=root.get_node("DialogPlayer")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	for stage in OS.get_cmdline_user_args():
		match stage:
			"1": await village()
			"2": await old_mine()
			"5": await gufeng()
			"6": await old_house()
			"7": await sects()
			"8": await muster()
	finish()

func finish() -> void:
	print("STORY_ROUTE_LIVE checks=",checks," failures=",failures)
	quit(1 if failures else 0)

func settle(field: Node) -> void:
	await create_timer(0.45).timeout
	if not is_instance_valid(field):
		return
	if dialogue.is_playing():
		var script: DialogScript=dialogue.get("_current_script")
		print("ON_ENTER ",script.dialog_id)
		for i in range(20):
			if not dialogue.is_playing() or dialogue.get("_current_node").has_choices(): break
			dialogue.advance()
			await process_frame
	await wait_for(func():
		var actor: Player=field.get("_player")
		return not field.get("_scene_rebuilding") and not dialogue.is_playing() and is_instance_valid(actor) and actor.can_move
	,5500)
	await create_timer(0.22).timeout

func zone_to(field: Node, target: StringName) -> ExitZone:
	for zone: ExitZone in field.get("_exit_nodes"):
		if is_instance_valid(zone) and not zone.is_queued_for_deletion() and StringName(zone.target_scene_id)==target:
			return zone
	return null

func position_at(field: Node, point: Vector2) -> Player:
	var actor: Player=field.get("_player")
	actor.global_position=point
	var town: Variant=field.get("native_town")
	if town!=null:
		town.terrain.reset_actor(town.terrain.level_at(actor.position))
	field.set("_last_encounter_position",actor.position)
	field.set("_encounter_distance",0.0)
	await physics_frame
	await physics_frame
	return field.get("_player")

func check_clear(actor: Player, label: String) -> bool:
	var registry: Script=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	return expect(registry.actor_shape_clear(actor),label+" foot "+str(actor.global_position))

func take(field: Node, target: StringName) -> Node:
	await settle(field)
	var zone:=zone_to(field,target)
	if not expect(zone!=null and not zone.is_locked,"unlocked portal to "+String(target)): return null
	var actor:=await position_at(field,zone.global_position)
	check_clear(actor,"walkable source "+String(target))
	if not expect(await wait_for(func():return is_instance_valid(zone) and zone.get("_in_range"),2200),"foot contacts portal "+String(target)): return null
	var before:=field.get_instance_id()
	print("PORTAL ",router.get_current_field_id()," -> ",target," ",zone.global_position," locked ",zone.is_locked," can_move ",actor.can_move)
	await press_space()
	if not expect(await wait_for(func():
		var next:=current_scene
		return next!=null and next.get_instance_id()!=before and router.get_current_field_id()==target and next.has_method("get_field_loading_state") and next.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active")
	,18000),"real Space travels to "+String(target)):
		print("PORTAL_NOT_ARRIVED current=",router.get_current_field_id()," host=",current_scene.scene_file_path," dialog=",dialogue.is_playing())
		return null
	await settle(current_scene)
	var arrival: Player=current_scene.get("_player")
	check_clear(arrival,"walkable arrival "+String(target))
	print("ARRIVAL ",target," ",arrival.global_position)
	return current_scene

func roundtrip(start: Node, middle: StringName, source: StringName, max_distance: float) -> void:
	await settle(start)
	var out:=zone_to(start,middle)
	var origin:=out.global_position if out!=null else Vector2.INF
	var field:=await take(start,middle)
	if field==null:return
	field=await take(field,source)
	if field!=null:
		var actual: Vector2=field.get("_player").global_position
		expect(actual.distance_to(origin)<=max_distance,"return near original arrow "+String(source)+" original="+str(origin)+" actual="+str(actual))

func village() -> void:
	var field:=await enter(&"linxi_village_center")
	if field!=null:
		await roundtrip(field,COTTAGE,&"linxi_village_center",180.0)
	field=await enter(&"linxi_village_scrollmap")
	if field!=null:
		await roundtrip(field,&"linxi_south_villager_home",&"linxi_village_scrollmap",180.0)

func old_mine() -> void:
	state.set_flag(&"chapter1_complete",true)
	state.set_flag(&"ch2_rescue_complete",true)
	quests.accept(&"q_ch2_main_03_trace_hideout")
	var field:=await enter(&"ch2_s5_bandit_cave")
	if field==null:return
	await settle(field)
	await play_at(field,"ch2_mine_drag_marks",&"ch2_mine_entry_tracks",[])
	field=await take(field,&"ch2_s5_mine_workshop")
	if field==null:return
	state.set_flag(&"defeated_ch2_mine_sentry",true)
	await settle(field)
	await play_at(field,"ch2_mine_burned_ledger",&"ch2_mine_burned_ledger",[])
	field=await take(field,&"ch2_s5_mine_command")
	if field==null:return
	state.set_flag(&"defeated_masked_killer_ambush",true)
	await settle(field)
	await play_at(field,"ch2_hideout_ledger_chest",&"ch2_hideout_result",[])
	expect(state.flags.get("ch2_hideout_cleared",false),"mine ledger opens Lingyue report")
	if expect(await wait_for(func():
		return router.get_current_field_id()==&"ch2_s4_lingyue_gate" and current_scene!=null and current_scene.has_method("get_field_loading_state") and current_scene.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active")
	),"ledger takes player to actual Lingyue gate"):
		var actor: Player=current_scene.get("_player")
		check_clear(actor,"Lingyue story arrival")
		expect(quests.is_active(&"q_ch2_main_04_report_lingyue"),"report objective active at gate")

func gufeng() -> void:
	state.set_flag(&"chapter4_complete",true)
	state.set_flag(&"chapter5_started",true)
	state.set_flag(&"seen_ch5_relief_road_intro",true)
	for flag in [&"seen_ch5_grain_convoy_intro",&"seen_ch5_snow_pass_intro",&"seen_ch5_abandoned_mine_intro",&"seen_ch5_false_banner_outpost_intro"]:
		state.set_flag(flag,true)
	var field:=await enter(ROAD)
	if field==null:return
	await settle(field)
	await play_at(field,"legacy_hotspot_1",&"ch5_relief_road_intro",[])
	# Battle victories serve as chapter fixtures here. The portal and the clue
	# interactions below go through normal input and dispatch.
	state.set_flag(&"ch5_relief_road_cleared",true)
	field=await take(field,CAMP)
	if field==null:return
	state.set_flag(&"ch5_grain_convoy_saved",true)
	await settle(field)
	await play_at(field,"legacy_hotspot_1",&"ch5_false_banner_evidence",[])
	expect(state.flags.get("ch5_false_banner_cloth_found",false),"real evidence opens snow pass")
	field=await take(field,PASS)
	if field==null:return
	state.set_flag(&"ch5_snow_pass_cleared",true)
	field=await take(field,MINE)
	if field==null:return
	state.set_flag(&"ch5_mine_hunters_defeated",true)
	await settle(field)
	await play_at(field,"legacy_hotspot_1",&"ch5_mine_survivor_testimony",[])
	expect(state.flags.get("ch5_old_case_survivor_heard",false),"survivor opens outpost")
	await roundtrip(field,OUTPOST,MINE,200.0)

func old_house() -> void:
	state.set_flag(&"chapter5_complete",true)
	state.set_flag(&"chapter6_started",true)
	quests.accept(&"q_ch6_main_02_old_residence")
	var field:=await enter(MASTER)
	if field==null:return
	await play_at(field,"ch6_revised_escort_note",&"ch6_residence_escort_note",[])
	expect(state.flags.get("ch6_residence_note_found",false),"read revised note")
	await settle(field)
	await play_at(field,"ch6_shifted_weapon_rack",&"ch6_residence_weapon_rack",[])
	expect(state.flags.get("ch6_archive_entry_found",false),"weapon rack unlocks archive")
	await roundtrip(field,ARCHIVE,MASTER,110.0)

func sects() -> void:
	state.set_flag(&"chapter6_complete",true)
	state.set_flag(&"ch7_dual_route_chosen",true)
	for pair: Array in [[LIEYUN,LIEYUN_WARD,"ch7_lieyun_old_ferry_marks",&"ch7_lieyun_ferry_marks"],[MINGWU,MINGWU_WARD,"ch7_mingwu_courier_table",&"ch7_mingwu_courier_table"]]:
		var field:=await enter(pair[0])
		if field==null:continue
		await settle(field)
		await play_at(field,pair[2],pair[3],[])
		if pair[0]==MINGWU:
			await speak_to(field,"ch7_mingwu_broker",&"ch7_outer_routes_open")
			expect(state.flags.get("ch7_outer_routes_opened",false),"broker opens both gates after double inquiry")
			await roundtrip(field,pair[1],pair[0],150.0)
	var field:=await enter(LIEYUN)
	if field!=null: await roundtrip(field,LIEYUN_WARD,LIEYUN,150.0)

func speak_to(field: Node, npc_id: String, expected: StringName) -> void:
	await settle(field)
	var target: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id==npc_id: target=npc
	if not expect(is_instance_valid(target),"npc "+npc_id):return
	await position_at(field,target.global_position+Vector2(0,44))
	if not expect(await wait_for(func():return is_instance_valid(target) and target.get("_in_range"),1800),"in range "+npc_id):return
	await press_space()
	if not expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==expected,2500),"npc opened "+String(expected)):return
	await settle(field)

func muster() -> void:
	state.set_flag(&"chapter7_complete",true)
	var field:=await enter(MUSTER)
	if field==null:return
	if expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==&"ch8_alliance_intro",2500),"chapter eight intro triggers"):
		for i in range(12):
			if not dialogue.is_playing():break
			dialogue.advance()
	await process_frame
	await physics_frame
	await process_frame
	var clerk: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id=="ch8_muster_clerk":clerk=npc
	if not expect(clerk!=null,"muster clerk exists"):return
	await position_at(field,clerk.global_position+Vector2(0,48))
	if not expect(await wait_for(func():return is_instance_valid(clerk) and clerk.get("_in_range"),1800),"clerk within interaction distance"):return
	await press_space()
	if expect(await wait_for(func():return dialogue.is_playing(),2500),"Space speaks to muster clerk"):
		for i in range(12):
			if not dialogue.is_playing():break
			dialogue.advance()
	expect(state.flags.get("ch8_alliance_mustered",false),"clerk unlocks mistwood")
	await roundtrip(field,MISTWOOD,MUSTER,175.0)
	field=await take(current_scene,MISTWOOD)
	if field==null:return
	# Seed the outcome of the earlier mistwood battle, then use the actual
	# chapter-eight clue dialogues and gates for the rest of the segment.
	state.set_flag(&"ch8_mistwood_blockade_cleared",true)
	quests.accept(&"q_ch8_main_03_false_order_matrix")
	field=await take(field,PERIMETER)
	if field==null:return
	await play_at(field,"ch8_false_order_matrix",&"ch8_false_order_matrix",[])
	expect(state.flags.get("ch8_mechanism_gallery_open",false),"clue opens mechanism gallery")
	field=await take(field,GALLERY)
	if field==null:return
	field=await mechanism_battle(field)
	if field==null:return
	await play_at(field,"disable_false_drum",&"ch8_false_drum_disable",[])
	await settle(field)
	await play_at(field,"disable_mist_vents",&"ch8_mist_vents_disable",[])
	expect(quests.is_completed(&"q_ch8_main_04_drum_mist_mechanisms"),"both mechanisms complete the quest")
	await roundtrip(field,PLATFORM,GALLERY,175.0)

func mechanism_battle(field: Node) -> Node:
	state.player.speed=1000
	state.player.agility=180
	state.player.max_hp=4000
	state.player.hp=4000
	var guard: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id=="ch8_mechanism_guards":guard=npc
	if not expect(is_instance_valid(guard),"mechanism guard visible"): return null
	var actor:=await position_at(field,guard.global_position+Vector2(0,44))
	var source_foot:=actor.global_position
	if not expect(await wait_for(func():return is_instance_valid(guard) and guard.get("_in_range"),1800),"mechanism guard can be approached"):return null
	await press_space()
	if not expect(await wait_for(func():return dialogue.is_playing() and dialogue.get("_current_script").dialog_id==&"ch8_mechanism_prebattle",2500),"guard dialogue starts real encounter"):return null
	for i in range(12):
		if not dialogue.is_playing():break
		dialogue.advance()
		await process_frame
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/battle.tscn" and current_scene.get("_state")==1),"mechanism guard battle enters"):return null
	var battle:=current_scene
	var units: Array=battle.get("_team_enemies")
	expect(units.size()==2,"original two-guard formation")
	for unit: BattleCombatant in units:
		unit.stats.hp=1
		unit.stats.agility=1
		unit.stats.speed=1
	for retry in range(6):
		if not is_instance_valid(battle) or battle.get("_state")==5:break
		if not await wait_for(func():return not is_instance_valid(battle) or battle.get("_state") in [1,5],18000):break
		if not is_instance_valid(battle) or battle.get("_state")==5:break
		var living: Array=battle._team_living_enemies()
		print("GUARD_TURN ",retry," living ",living.size())
		if living.is_empty():break
		var unit: BattleCombatant=battle._team_active_unit
		var skills: Array=battle._skills_for_stats(unit.stats)
		for i in skills.size():
			if skills[i].skill_id==&"basic_attack":
				battle._team_player_action_skill_use(i,living[0].unit_id)
				break
		await create_timer(0.45).timeout
	if not expect(await wait_for(func():return current_scene!=null and current_scene.scene_file_path=="res://scenes/result_victory.tscn",10000),"mechanism battle victory results"):
		if is_instance_valid(battle): print("GUARD_BATTLE_LOG ",battle.battle_log.get_parsed_text())
		return null
	current_scene.get_node("%BtnContinue").pressed.emit()
	if not expect(await wait_for(func():return current_scene!=null and current_scene.has_method("get_field_loading_state") and router.get_current_field_id()==GALLERY and current_scene.get_field_loading_state().get("complete",false) and not root.get_node("LoadingManager").get("_transition_active")),"guard victory returns to same gallery"):return null
	field=current_scene
	await settle(field)
	actor=field.get("_player")
	expect(actor.global_position.distance_to(source_foot)<1.0,"guard victory resumes at encounter feet")
	expect(state.flags.get("ch8_mechanism_guards_defeated",false),"real victory return sets required guard flag")
	return field
