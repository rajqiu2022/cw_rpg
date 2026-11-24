extends "res://tests/helpers/luoyang_enclosure_v11_bounty_live_field_continuation_phase_20261011.gd"
## Only passive health observation and a shared-budget travel readiness gate.
## Original ordinary continuation, live clearance, reward accounting and Battle UI
## strategy/30-180-30 budgets are inherited unchanged; this is NEVER a SIX slot.
const HEALTH_INPUT = preload("res://tests/helpers/luoyang_bounty_health_observation_input_driver_20261012.gd")
const HEALTH_INPUT_PATH := "res://tests/helpers/luoyang_bounty_health_observation_input_driver_20261012.gd"
const HEALTH_INPUT_SHA := "d69975fc078b31277b6ed747076c8e1d6d42ed0bcddab090157a90b485ada7b8"
const HEALTH_SCOPE := "LUOYANG_TWO_BOUNTY_TRAVEL_READY_HEALTH_NOT_SIX"
var travel_ready_rows: Array[Dictionary]=[]

func run_bounty_diagnostic(owner: SceneTree,directory: String) -> Dictionary:
	tree=owner; candidate=true; output=directory
	before_files=_normal_files(); before_slot=tree.root.get_node("SaveManager").get("active_slot")
	driver=HEALTH_INPUT.new(); driver.call("configure",tree)
	_check(FileAccess.get_sha256(HEALTH_INPUT_PATH)==HEALTH_INPUT_SHA and driver.get_script().resource_path==HEALTH_INPUT_PATH,"actual NEW health/lifecycle driver installed, no lexical INPUT shadow")
	_check(BOUNTY_FLAG in OS.get_cmdline_user_args() and "--fresh-start-only" in OS.get_cmdline_user_args() and "--luoyang-v3-candidate" in OS.get_cmdline_user_args() and "--luoyang-enclosure-v11-candidate" in OS.get_cmdline_user_args(),"explicit finite candidate diagnostic, never full gameplay/six")
	_check(FileAccess.get_sha256(BOUNTY_PARENT_PATH)==BOUNTY_PARENT_SHA and FileAccess.get_sha256(V9C_CITY_ORIGIN_PATH)==V9C_CITY_ORIGIN_SHA,"frozen new source substitutions and unchanged original lifecycle")
	if failures!=0: return await _finish_bounty_diagnostic()
	_public_fixture({})
	var router: Node=tree.root.get_node("SceneRouter")
	router.call("reset_for_new_game")
	router.call("restore_navigation_state",router.call("get_navigation_state"),&"", &"world_map_jianghu")
	before_nav=(router.call("get_navigation_state") as Dictionary).duplicate(true)
	_check(before_nav.get("world_map_version")==14 and String(router.call("get_active_world_map_scene"))=="world_map_jianghu","formal world14 baseline, no world15 or historical migration")
	_connect_events()
	if failures!=0: return await _finish_bounty_diagnostic()
	await _normal_bounty_rewards()
	_check(records.bounties.size()==2,"both original UI-accepted bounty battles and exact rewards")
	return await _finish_bounty_diagnostic()

func _wait_field_until(id: String,deadline: int) -> bool:
	while Time.get_ticks_msec()<deadline:
		await tree.process_frame
		var loading: Node=tree.root.get_node_or_null("LoadingManager")
		if loading!=null and bool(loading.get("_transition_active")): continue
		var pending_field: Node=tree.current_scene
		if not is_instance_valid(pending_field) or not pending_field.is_inside_tree() or pending_field.is_queued_for_deletion(): continue
		if pending_field.scene_file_path not in ["res://scenes/field_walkable.tscn","res://scenes/field.tscn"]: continue
		var definition: SceneScript=pending_field.get("_current_scene") as SceneScript
		var player: Node2D=pending_field.get("_player") as Node2D
		if definition==null or String(definition.scene_id)!=id or not is_instance_valid(player) or not player.is_inside_tree() or player.is_queued_for_deletion() or bool(pending_field.get("_scene_rebuilding")): continue
		# Same-ID navigation can replace this Field during the awaited normal stages.
		# Never bind the pre-await node, or ask detached Physics for its space.
		await driver.call("completed_actor_stage")
		if not is_instance_valid(pending_field) or tree.current_scene!=pending_field or not pending_field.is_inside_tree() or pending_field.is_queued_for_deletion(): continue
		if loading!=null and bool(loading.get("_transition_active")): continue
		if bool(pending_field.get("_scene_rebuilding")) or not is_instance_valid(player) or not player.is_inside_tree() or player.is_queued_for_deletion() or pending_field.get("_player")!=player: continue
		var completed_definition: SceneScript=pending_field.get("_current_scene") as SceneScript
		if completed_definition==null or String(completed_definition.scene_id)!=id or not pending_field.is_ancestor_of(player): continue
		if Time.get_ticks_msec()>=deadline: return false
		field=pending_field
		runtime_started=true
		return true
	return false

func _travel_ready(target_id: String,previous_expected_id: String) -> Dictionary:
	# ONE original 30-second budget across readiness and target arrival. The
	# inherited _wait_field remains untouched for ordinary encounter rebinding.
	var deadline: int=Time.get_ticks_msec()+30000
	var row: Dictionary={"target_id":target_id,"previous_expected_id":previous_expected_id,"deadline_msec":deadline,"started_msec":Time.get_ticks_msec(),"go_calls":0,"ready":false,"accepted":false,"ok":false,"budget_seconds":30,"additional_Battle_return_credit":false,"before":_diag_field_context()}
	if not await _wait_field_until(previous_expected_id,deadline):
		row["reason"]="previous_expected_Field_not_TRAVEL_READY_in_original_budget"
		row["after"]=_diag_field_context()
		travel_ready_rows.append(row.duplicate(true)); _diag_emit("travel_ready",row)
		return row
	var ready_field: Node=field
	var ready_player: Node2D=ready_field.get("_player") as Node2D
	row["ready"]=true
	row["ready_field_instance"]=ready_field.get_instance_id()
	row["ready_player_instance"]=ready_player.get_instance_id()
	row["ready_msec"]=Time.get_ticks_msec()
	row["ready_context"]=_diag_field_context()
	if Time.get_ticks_msec()>=deadline:
		row["reason"]="shared_travel_budget_exhausted_before_dispatch"
		travel_ready_rows.append(row.duplicate(true)); _diag_emit("travel_ready",row)
		return row
	# No await between the completed-stage identity check and this single public
	# request. No Router shortcut, retry dispatch, private busy write or timer reset.
	row.go_calls=1
	row.accepted=tree.root.get_node("SceneRouter").call("go_field_smart",StringName(target_id))
	if row.accepted==true:
		row.ok=await _wait_field_until(target_id,deadline)
	row["reason"]="TRAVEL_READY_AND_ORIGINAL_TARGET_ARRIVAL" if row.ok==true else "request_rejected_or_target_arrival_budget_exhausted"
	row["finished_msec"]=Time.get_ticks_msec()
	row["after"]=_diag_field_context()
	travel_ready_rows.append(row.duplicate(true)); _diag_emit("travel_ready",row)
	return row

func _finish_bounty_diagnostic() -> Dictionary:
	var observer: RefCounted=driver
	records["travel_ready"]=travel_ready_rows.duplicate(true)
	records["health_observation_scope"]="FRAME_AND_IMMEDIATE_EVENT_ONLY_NOT_PER_DAMAGE"
	var report: Dictionary=await super._finish_bounty_diagnostic()
	var health: Dictionary=observer.call("get_health_observation") if observer!=null else {}
	_check(not health.is_empty() and health.get("overflow")==false and health.get("connected")==false and health.get("released")==true,"bounded passive health observations and symmetric signal release")
	_check(_write("travel_ready_health_observations.json",{"scope":HEALTH_SCOPE,"six_slot_eligible":false,"per_damage_tested":false,"Battle_returned_Loading_semantics_fixed":false,"health":health,"travel_ready":travel_ready_rows.duplicate(true)}),"passive health and shared-deadline observations persisted")
	report["execution_scope"]=HEALTH_SCOPE
	report["health_observation"]=health
	report["travel_ready"]=travel_ready_rows.duplicate(true)
	report["per_damage_tested"]=false
	report["Battle_returned_Loading_semantics_fixed"]=false
	report.checks=checks; report.failures=failures
	report.complete=report.complete and failures==0; report.diagnostic_complete=report.complete
	observer=null
	return report

func _normal_bounty_rewards() -> void:
	_check(FileAccess.get_sha256(OBSERVATION_PARENT_PATH)==OBSERVATION_PARENT_SHA,"unchanged observation/lifecycle parent bytes")
	_ordinary_payload_checks()
	if failures!=0: return
	records["ordinary_encounters"]=[]
	await _finish_dialogs()
	if not _check(not bool(tree.root.get_node("DialogPlayer").call("is_playing")),"previous dialogue normally finished before bounty fixture reset"): return
	var legacy: SceneScript=ENCLOSURE.legacy_scene(StringName(IDS[0]))
	var boards: Array[Dictionary]=[]
	if legacy!=null and legacy.map_layout!=null:
		for entry: Dictionary in legacy.map_layout.interactions:
			if entry.get("id")=="luoyang_repeatable_bounty_board": boards.append(entry.duplicate(true))
	if not _check(boards.size()==1 and FileAccess.get_sha256("res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_layout.tres")==MARKET_RETURN_SOURCE_PINS["res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_layout.tres"],"one exact original repeatable board source"): return
	var board: Dictionary=boards[0]
	if not _check(typeof(board.get("require_flag"))==TYPE_STRING and board.require_flag=="luoyang_case_found_clue" and board.get("action")=="bounty_board:luoyang" and board.get("activation")=="interact" and board.get("clickable")==true,"original board author flag/action/activation, no invented accepted bounty"): return
	_public_fixture(board)
	var id: String=IDS[0]
	if not await _open(id): return
	var slot: Dictionary=_slot(manifest.gameplay_slots.interactions,"luoyang_repeatable_bounty_board")
	var approach: Dictionary=await probe.call("move_to",_point(slot.get("stand_px")))
	if not _check(bool(approach.get("ok",false)),"real bounty entity approachable"): return
	var areas: Array[Area2D]=[]
	for area: Area2D in field.get("_trigger_areas"):
		if is_instance_valid(area) and (area.get_meta("trigger_data",{}) as Dictionary).get("id")==board.id: areas.append(area)
	if not _check(areas.size()==1,"original live repeatable board Area present before click"): return
	var live_data: Dictionary=areas[0].get_meta("trigger_data",{})
	var live_ok: bool=areas[0].is_inside_tree() and areas[0].overlaps_body(field.get("_player")) and areas[0].collision_layer==4 and areas[0].collision_mask==2 and areas[0].input_pickable
	for key: String in ["id","action","require_flag","activation","clickable"]:
		live_ok=live_ok and typeof(live_data.get(key))==typeof(board.get(key)) and var_to_bytes(live_data.get(key))==var_to_bytes(board.get(key))
	if not _check(live_ok and (tree.root.get_node("GameState").get("flags") as Dictionary).get(board.require_flag)==true,"actual source-bound enabled board Area/action and real body overlap before normal pointer"): return
	records["bounty_board_binding"]={"source_entry":board.duplicate(true),"source_path":"res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_layout.tres","source_sha256":MARKET_RETURN_SOURCE_PINS["res://data/maps/luoyang_v3_legacy/ch4_s0_luoyang_gate_layout.tres"],"live_trigger_data":live_data.duplicate(true),"live_Area_instance_id":areas[0].get_instance_id(),"original_approach":approach}
	await probe.call("click_entity",probe.call("prop",String(slot.get("object_id",""))))
	for tick in 10: await tree.process_frame
	var page: Node=tree.current_scene
	if not _check(page!=null and page.get_node_or_null("BountyEntries")!=null,"ordinary entity opens actual two-case board"): return
	_diag_emit("board_open",{"page":_diag_node(page),"cards":_diag_cards(page),"manager_state":tree.root.get_node("BountyManager").call("to_dict"),"field_context":_diag_field_context()})
	var entries: Array[Dictionary]=tree.root.get_node("BountyManager").call("get_board_entries",&"luoyang")
	_check(entries.size()==2,"both existing Luoyang bounty identities retained")
	for entry: Dictionary in entries:
		var button: Button=page.get_node_or_null("BountyEntries/BountyEntry_"+String(entry.bounty_id)+"/Content/AcceptButton") as Button
		_diag_button_rows+=1
		_diag_emit("accept_lookup",{"bounty_id":entry.bounty_id,"lookup_path":"BountyEntries/BountyEntry_"+String(entry.bounty_id)+"/Content/AcceptButton","lookup_found":button!=null,"button":_diag_node(button),"cards":_diag_cards(page),"original_available_predicate":button!=null and not button.disabled,"entry":entry.duplicate(true),"manager_state":tree.root.get_node("BountyManager").call("to_dict")})
		_check(button!=null and not button.disabled,"ordinary available bounty accept control")
		var original_pointer: Dictionary={}
		if button!=null: original_pointer=await driver.call("pointer",button.get_global_rect().get_center())
		_diag_emit("accept_pointer_return",{"bounty_id":entry.bounty_id,"original_pointer":original_pointer,"old_button":_diag_node(button),"cards":_diag_cards(page),"manager_state":tree.root.get_node("BountyManager").call("to_dict"),"field_context":_diag_field_context()})
	await driver.call("pointer",(page.get_node("CloseButton") as Control).get_global_rect().get_center())
	_check(await _wait_field(id),"normal bounty board closes to exact city")
	var previous_expected_id: String=id
	for entry: Dictionary in entries:
		var manager: Node=tree.root.get_node("BountyManager")
		var states: Dictionary=(manager.call("to_dict") as Dictionary).states
		var state: Dictionary=states.get(String(entry.bounty_id),{})
		var definition: BountyDef=manager.call("get_definition",StringName(entry.bounty_id)) as BountyDef
		_diag_state_rows+=1
		_diag_emit("accepted_state",{"bounty_id":entry.bounty_id,"state":state.duplicate(true),"definition":_diag_definition(definition),"original_active_predicate":String(state.get("status",""))=="active" and definition!=null,"manager_state":manager.call("to_dict"),"field_context":_diag_field_context()})
		_check(String(state.get("status",""))=="active" and definition!=null,"normal actual UI accepted bounty, no injected active state")
		if definition==null or int(state.get("location_index",-1))<0: continue
		var location: Dictionary=definition.locations[int(state.location_index)]
		var target_id: String=String(location.scene_id)
		_diag_emit("chosen_location",{"bounty_id":entry.bounty_id,"location_index":state.location_index,"location":location.duplicate(true),"definition":_diag_definition(definition),"original_not_city_predicate":not IDS.has(target_id),"target_id":target_id})
		_check(IDS.has(target_id) or ORDINARY_SOURCE_PINS.has(target_id),"actual original bounty location is current city or exact original neighbor")
		var travel: Dictionary=await _travel_ready(target_id,previous_expected_id)
		if not _check(travel.get("ok")==true,"normal public travel enters actual original bounty location"): continue
		previous_expected_id=target_id
		await _finish_dialogs()
		var current: SceneScript=field.get("_current_scene") as SceneScript
		var target_raw: RefCounted=ENCLOSURE_RAW.new() if IDS.has(target_id) else ROOT_AND_FEET_RAW.new()
		var source_binding: Dictionary=_bounty_source_binding(current)
		if not _check(not source_binding.is_empty() and _configure_bounty_raw(target_raw,current),"actual city independent current PNG/875+17 or original neighbor ROOT+17 source binding"): target_raw.call("release"); continue
		_diag_emit("birth",{"bounty_id":entry.bounty_id,"field_context":_diag_field_context(),"birth":_diag_point(target_raw,(field.get("_player") as Node2D).position)})
		var bounty_npc: Node=_npc("bounty_"+String(entry.bounty_id))
		_check(bounty_npc!=null,"actual accepted bounty spawns normal target NPC")
		if bounty_npc==null: target_raw.call("release"); continue
		var clear: Callable=func(p: Vector2)->bool: return bool(target_raw.call("clear",p)) and _actual_body_clear(field,p)
		var segment: Callable=func(a: Vector2,b: Vector2)->Dictionary:
			var count: int=maxi(1,ceili(a.distance_to(b)/4))
			for index in range(count+1):
				if not bool(clear.call(a.lerp(b,float(index)/count))): return {"clear":false}
			return {"clear":true}
		var station: Vector2=Vector2(INF,INF)
		for radius in [48,56,64,72]:
			for angle in 16:
				var point: Vector2=bounty_npc.position+Vector2.from_angle(TAU*angle/16)*radius
				if bool(clear.call(point)): station=point; break
			if station.is_finite(): break
		_diag_emit("station",{"bounty_id":entry.bounty_id,"npc":_diag_node(bounty_npc),"npc_position":(bounty_npc as Node2D).position,"station":_diag_point(target_raw,station),"field_context":_diag_field_context()})
		var path: PackedVector2Array=driver.call("plan",(field.get("_player") as Node2D).position,station,field.get("_world_size"),clear,segment)
		_diag_emit("planned_path",{"bounty_id":entry.bounty_id,"path":path,"original_from":(field.get("_player") as Node2D).position,"original_station":station,"world_size":field.get("_world_size"),"field_context":_diag_field_context()})
		var driven: Dictionary=await _follow_with_ordinary_encounters(String(entry.bounty_id),target_raw,source_binding,path,station,clear,segment)
		if not _check(bool(driven.get("ok",false)),"actual normal input approaches original bounty NPC"): target_raw.call("release"); continue
		var pre: Dictionary=_state()
		var original_foot: Vector2=(field.get("_player") as Node2D).position
		var original_size: Vector2=field.get("_world_size")
		var expected_bounty_enemies: Array[StringName]=definition.enemy_ids.duplicate()
		var bounty_party: Array=tree.root.get_node("GameState").get("party")
		if not (field.get("_current_scene") as SceneScript).encounter_allow_full_group_for_solo: expected_bounty_enemies.resize(mini(expected_bounty_enemies.size(),clampi(bounty_party.size()+1,2,3)))
		await driver.call("key",KEY_SPACE)
		var battle: RefCounted=BATTLE.new()
		battle.call("configure",tree,driver,_check)
		var actual: Dictionary=await battle.call("victory",target_id,original_foot,source_binding.local_version,original_size)
		battle.call("release")
		var after: Dictionary=_state()
		var final_state: Dictionary=((manager.call("to_dict") as Dictionary).states as Dictionary).get(String(entry.bounty_id),{})
		_check(bool(actual.get("won",false)) and String(final_state.get("status",""))=="captured" and int(final_state.get("completion_count",0))==1,"real bounty victory completes original case exactly once")
		var bounty_payload: Variant=actual.get("original_payload")
		var victory_result: Variant=actual.get("actual_result_payload")
		var payload_bound: bool=bounty_payload is Dictionary and bounty_payload.size()==9 and typeof(bounty_payload.get("bounty_id"))==TYPE_STRING_NAME and bounty_payload.bounty_id==definition.bounty_id and typeof(bounty_payload.get("battle_mode"))==TYPE_STRING_NAME and bounty_payload.battle_mode==&"bounty" and typeof(bounty_payload.get("return_scene"))==TYPE_STRING_NAME and bounty_payload.return_scene==StringName(target_id) and typeof(bounty_payload.get("return_spawn"))==TYPE_VECTOR2 and bounty_payload.return_spawn.is_finite() and bounty_payload.return_spawn.distance_to(original_foot/original_size)<.00001 and typeof(bounty_payload.get("return_world_map_version"))==TYPE_INT and bounty_payload.return_world_map_version==14 and typeof(bounty_payload.get("return_local_layout_version"))==TYPE_INT and bounty_payload.return_local_layout_version==source_binding.local_version and bounty_payload.get("enemy_ids") is Array and var_to_bytes(bounty_payload.enemy_ids)==var_to_bytes(expected_bounty_enemies) and typeof(bounty_payload.get("enemy_id"))==TYPE_STRING and not expected_bounty_enemies.is_empty() and bounty_payload.enemy_id==String(expected_bounty_enemies[0])
		var result_bound: bool=payload_bound and victory_result is Dictionary and typeof(victory_result.get("return_scene"))==TYPE_STRING_NAME and victory_result.return_scene==bounty_payload.return_scene and typeof(victory_result.get("return_spawn"))==TYPE_VECTOR2 and var_to_bytes(victory_result.return_spawn)==var_to_bytes(bounty_payload.return_spawn) and typeof(victory_result.get("return_world_map_version"))==TYPE_INT and victory_result.return_world_map_version==14 and typeof(victory_result.get("return_local_layout_version"))==TYPE_INT and victory_result.return_local_layout_version==source_binding.local_version and typeof(victory_result.get("battle_mode"))==TYPE_STRING_NAME and victory_result.battle_mode==&"bounty" and typeof(victory_result.get("victory_action"))==TYPE_STRING and victory_result.victory_action=="" and typeof(victory_result.get("gold"))==TYPE_INT and victory_result.gold>=0 and typeof(victory_result.get("exp"))==TYPE_INT and victory_result.exp>=0 and victory_result.get("bounty_result") is Dictionary and victory_result.bounty_result.size()==2
		var expected_member_lines: PackedStringArray=[]
		var summary_bound: bool=result_bound and victory_result.get("party_exp_results") is Array and victory_result.party_exp_results.size()==bounty_party.size()
		var seen_members: Dictionary={}
		if summary_bound:
			for member: CharacterStats in bounty_party:
				if member==null or seen_members.has(member.character_id): summary_bound=false; break
				seen_members[member.character_id]=true
				var matches: Array[Dictionary]=[]
				for candidate_row: Variant in victory_result.party_exp_results:
					if candidate_row is Dictionary and typeof(candidate_row.get("character_id"))==TYPE_STRING and candidate_row.character_id==member.character_id: matches.append(candidate_row)
				if matches.size()!=1: summary_bound=false; break
				var row: Dictionary=matches[0]
				if typeof(row.get("display_name"))!=TYPE_STRING or row.display_name!=member.display_name or typeof(row.get("exp_gained"))!=TYPE_INT or row.exp_gained!=victory_result.exp or typeof(row.get("level_after"))!=TYPE_INT or row.level_after<1 or row.level_after>member.level: summary_bound=false; break
				expected_member_lines.append("%s 额外经验 +%d%s"%[member.display_name,definition.reward_exp,"，升至%d级"%member.level if member.level>row.level_after else ""])
		var expected_summary: String="%s\n%s"%[definition.reward_summary(),"\n".join(expected_member_lines)]
		summary_bound=summary_bound and typeof(victory_result.bounty_result.get("title"))==TYPE_STRING and victory_result.bounty_result.title=="缉捕归案 · %s"%definition.display_name and typeof(victory_result.bounty_result.get("summary"))==TYPE_STRING and victory_result.bounty_result.summary==expected_summary
		var old_reward_predicate: bool=int(after.reputation)==int(pre.reputation)+definition.reward_reputation and int(after.training)==int(pre.training)+definition.reward_training
		var totals_bound: bool=result_bound and summary_bound and typeof(pre.get("reputation"))==TYPE_INT and typeof(after.get("reputation"))==TYPE_INT and after.reputation==pre.reputation+definition.reward_reputation and typeof(pre.get("training"))==TYPE_INT and typeof(after.get("training"))==TYPE_INT and after.training==pre.training+definition.reward_training+victory_result.exp and typeof(pre.get("gold"))==TYPE_INT and typeof(after.get("gold"))==TYPE_INT and after.gold==pre.gold+definition.reward_gold+victory_result.gold
		var accounting: Dictionary={"old_reward_predicate_diagnostic_only":old_reward_predicate,"authored_bounty_reputation":definition.reward_reputation,"authored_bounty_training":definition.reward_training,"authored_bounty_gold":definition.reward_gold,"actual_battle_gold":victory_result.get("gold") if victory_result is Dictionary else null,"actual_battle_exp":victory_result.get("exp") if victory_result is Dictionary else null,"expected_bounty_summary":expected_summary,"payload_bound":payload_bound,"result_bound":result_bound,"summary_bound":summary_bound,"strict_two_source_total_bound":totals_bound,"ordinary_rewards_borrowed":false}
		_check(totals_bound,"exact authored bounty plus actual non-spar battle totals and bound original bounty result")
		records.bounties.append({"id":entry.bounty_id,"location":location,"normal_drive":driven,"battle":actual,"before":pre,"after":after,"final_state":final_state,"reward_accounting":accounting})
		_diag_emit("original_reward_checks_completed",{"bounty_id":entry.bounty_id,"original_bounty_record":records.bounties[-1],"manager_state":manager.call("to_dict"),"field_context":_diag_field_context()})
		target_raw.call("release")

