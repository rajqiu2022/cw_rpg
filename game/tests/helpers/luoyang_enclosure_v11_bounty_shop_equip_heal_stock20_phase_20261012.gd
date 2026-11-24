extends "res://tests/helpers/luoyang_enclosure_v11_bounty_travel_ready_health_phase_20261012.gd"
## ONLY original two bounties with explicit NORMAL_SHOP_EQUIP_HEAL_QUARTER_HP_STOCK20 strategy.
## Passive D699 health strategy_modified=false concerns that observer only.
## No Stats, fixture money/items, RNG, enemies, movement or Battle budget edits.
const SUPPLIED_BATTLE = preload("res://tests/helpers/battle_shop_equip_heal_stock20_ui_probe_20261012.gd")
const SUPPLIED_BATTLE_PATH := "res://tests/helpers/battle_shop_equip_heal_stock20_ui_probe_20261012.gd"
const SUPPLIED_BATTLE_SHA := "16d8d03de8a061e55782a6f06dbb0682158e1885e553103cd819ee67565a465f"
const SUPPLIED_FIELD_PATH := "res://scripts/field/field_walkable_controller.gd"
const SUPPLIED_FIELD_SHA := "e545834700715e23540a5036ffaeb01e2ba412b62e14f81c5abd7b28a08ee1ed"
const SUPPLIED_SCOPE := "LUOYANG_TWO_BOUNTY_NORMAL_SHOP_EQUIP_HEAL_QUARTER_HP_STOCK20_NOT_SIX"
var supply_record: Dictionary={}

func _bind_field(id: String) -> bool:
	_release_field_oracles()
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	if not _check(definition!=null and definition.scene_id==StringName(id) and definition.map_layout!=null and ENCLOSURE.is_v3(definition),"current actual city3 definition and exact enclosure/base metadata"): return false
	if not _check(field.get_script().resource_path=="res://scripts/field/field_walkable_controller.gd" and ENCLOSURE.semantic_fidelity(definition),"production Field and unchanged original gameplay storage"): return false
	raw=ENCLOSURE_RAW.new()
	if not _check(raw.call("configure_city",definition,candidate),"independent BASE/patch PNG/full17/source-solid city reader"): return false
	manifest=(raw.get("source_record") as Dictionary).duplicate(true)
	author_records[id]=manifest.duplicate(true)
	probe=preload("res://tests/helpers/luoyang_roof_source_display_toast_actual_probe_20261012.gd").new()
	return _check(probe.call("configure",tree,field,manifest,_check,_capture),"complete current875/17 actualPhysics/Y/alpha probe")

func _normal_shop_supplies() -> bool:
	if not _check(FileAccess.get_sha256(SUPPLIED_BATTLE_PATH)==SUPPLIED_BATTLE_SHA and FileAccess.get_sha256(SUPPLIED_FIELD_PATH)==SUPPLIED_FIELD_SHA,"exact NEW UI strategy and current production Field source"): return false
	var market: String=IDS[3]
	if not await _open(market): return false
	var original: SceneScript=ENCLOSURE.legacy_scene(StringName(market))
	if not _check(original!=null and original.resource_path=="res://data/maps/luoyang_v3_legacy/ch4_s3_luoyang_market_scene.tres" and FileAccess.get_sha256(original.resource_path)==MARKET_RETURN_SOURCE_PINS[original.resource_path],"fixed original Market NPC source before normal shop input"): return false
	var authors: Array[Dictionary]=[]
	for entry: Dictionary in original.npcs:
		if entry.get("npc_id")=="luoyang_armorer": authors.append(entry.duplicate(true))
	if not _check(authors.size()==1 and authors[0].get("interaction_action")=="shop:luoyang_armory","one exact original armory NPC/action, no hidden shop open"): return false
	var npc: Node=_npc("luoyang_armorer")
	if not _check(is_instance_valid(npc),"original live armorer exists"): return false
	var station: Vector2=_npc_stand(npc)
	var approach: Dictionary=await probe.call("move_to",station)
	if not _check(approach.get("ok")==true,"normal full875+17/Physics input reaches real armorer"): return false
	var source_foot: Vector2=(field.get("_player") as Node2D).position
	supply_record={"scope":SUPPLIED_SCOPE,"original_author":authors[0],"legacy_scene_path":original.resource_path,"legacy_scene_sha256":FileAccess.get_sha256(original.resource_path),"source_foot":source_foot,"normal_approach":approach,"actual_NPC":_diag_node(npc),"shop":{}}
	_diag_emit("normal_shop_before_input",supply_record)
	await driver.call("key",KEY_SPACE)
	var deadline: int=Time.get_ticks_msec()+30000
	var shop: Node
	while Time.get_ticks_msec()<deadline:
		await tree.process_frame
		var current: Node=tree.current_scene
		if is_instance_valid(current) and current.scene_file_path=="res://scenes/shop.tscn" and current.get_script()!=null and current.get_script().resource_path=="res://scripts/ui/shop_ui.gd":
			shop=current; break
	if not _check(is_instance_valid(shop),"original NPC Space opens actual Shop, not public API credit"): return false
	var shopper: RefCounted=SUPPLIED_BATTLE.new()
	shopper.call("configure",tree,driver,_check)
	supply_record.shop=await shopper.call("shop_supplies",shop)
	shopper.call("release"); shopper=null; shop=null
	_diag_emit("normal_shop_trade_immediate_return",supply_record)
	if not _check(supply_record.shop.get("ok")==true,"real shop exact one sword/one armor/ten pills, cost872"): return false
	if not _check(await _wait_field(market),"normal Accept returns actual Market through production loading"): return false
	await _finish_dialogs()
	if not _check(not bool(tree.root.get_node("DialogPlayer").call("is_playing")) and (field.get("_player") as Node2D).position.distance_to(source_foot)<.03,"normal shop_thanks drains and exact pre-shop source feet retained"): return false
	if not _check(_bind_field(market) and probe.call("clear",(field.get("_player") as Node2D).position),"returned Market independent fullbody/17/source/Physics rebinding"): return false
	supply_record["normal_return_foot"]=(field.get("_player") as Node2D).position
	supply_record["after"]=_state()
	records["normal_shop_supplies"]=supply_record.duplicate(true)
	_diag_emit("normal_shop_return",supply_record)
	return true

func _finish_bounty_diagnostic() -> Dictionary:
	records["battle_strategy_modified"]=true
	records["Attack_only"]=false
	records["strategy_scope"]="NORMAL_SHOP_EQUIP_HEAL_QUARTER_HP_STOCK20"
	records["passive_health_strategy_modified_false_scope"]="D699_OBSERVER_ONLY_NOT_OVERALL_BATTLE"
	records["normal_shop_supplies"]=supply_record.duplicate(true)
	var report: Dictionary=await super._finish_bounty_diagnostic()
	report["execution_scope"]=SUPPLIED_SCOPE
	report["battle_strategy_modified"]=true
	report["Attack_only"]=false
	report["strategy_scope"]="NORMAL_SHOP_EQUIP_HEAL_QUARTER_HP_STOCK20"
	report["health_strategy_modified_false_scope"]="PASSIVE_DRIVER_ONLY"
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
	if not await _normal_shop_supplies(): return
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
		var battle: RefCounted=SUPPLIED_BATTLE.new()
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

func _follow_with_ordinary_encounters(bounty_id: String,target_raw: RefCounted,source_binding: Dictionary,original_path: PackedVector2Array,station: Vector2,clear: Callable,segment: Callable) -> Dictionary:
	var attempts: Array[Dictionary]=[]
	var remaining: PackedVector2Array=original_path.duplicate()
	var original_next_index: int=1
	for attempt in range(ORDINARY_MAX_INTERRUPTS+1):
		var original_clear_observations: Array[Dictionary]=[]
		var captured_player: Variant=field.get("_player") if is_instance_valid(field) else null
		var observed_clear: Callable=func(point: Vector2)->bool:
			var before: Dictionary=driver.call("live_tuple",field,captured_player)
			var source_evidence: Dictionary={}
			var physics_result: bool=false
			var original_value: bool=false
			if before.live==true:
				source_evidence=target_raw.call("foot_evidence",point)
				physics_result=_actual_body_clear(field,point)
				original_value=source_evidence.get("clear")==true and physics_result
			var after: Dictionary=driver.call("live_tuple",field,captured_player)
			var same_live_tuple: bool=before.live==true and after.live==true and var_to_bytes(before)==var_to_bytes(after)
			original_clear_observations.append({"root":point,"root_native_bytes":var_to_bytes(point).hex_encode(),"original_ROOT17_Physics_result":original_value,"raw_foot_evidence":source_evidence.duplicate(true),"independent_Physics_clear":physics_result,"before_tuple":before,"after_tuple":after,"same_live_tuple":same_live_tuple,"source_binding":source_binding.duplicate(true),"physics_frame":Engine.get_physics_frames(),"ticks_usec":Time.get_ticks_usec()})
			return original_value and same_live_tuple
		var driven: Dictionary=await driver.call("follow",field,remaining,observed_clear,segment)
		_diag_follow_rows+=1
		attempts.append(driven.duplicate(true))
		_diag_emit("follow_immediate_return",{"bounty_id":bounty_id,"attempt":attempt,"complete_original_driven_return":driven.duplicate(true),"original_clear_observations":original_clear_observations,"original_path":original_path,"original_station":station,"remaining_original_waypoints":remaining,"original_next_index":original_next_index,"current_root":_diag_live_point(target_raw),"field_context":_diag_field_context(),"timing":"ORIGINAL_CLEAR_CALLBACK_VALUES_PLUS_SYNCHRONOUS_FOLLOW_RETURN_NO_EXTRA_PHYSICS_QUERY"})
		if driven.get("ok")==true: return {"ok":true,"attempts":attempts,"original_path":original_path,"original_station":station,"ordinary_encounters_count":attempt,"segments":driven.get("segments",[])}
		# Navigation/Physics failures do not become encounters merely because a battle exists.
		if driven.get("reason")!="real_input_failed" or typeof(driven.get("index"))!=TYPE_INT or driven.index<1 or driven.index>=remaining.size() or not driven.get("segments") is Array or driven.segments.is_empty(): return {"ok":false,"reason":"original_follow_failure_not_ordinary_interruption","attempts":attempts}
		var last: Variant=driven.segments[-1]
		if not last is Dictionary or last.get("first_bad",[])!=[] or last.get("all_recorded_feet_clear")!=true or last.get("reason")!="scene_changed_during_movement" or last.get("identity_loss")!=true or typeof(last.get("last_live_foot"))!=TYPE_VECTOR2 or not last.last_live_foot.is_finite() or last.get("last_live_foot_native_bytes")!=var_to_bytes(last.last_live_foot).hex_encode(): return {"ok":false,"reason":"original_recorded_clearance_or_lifecycle_failure","attempts":attempts}
		for observation: Dictionary in original_clear_observations:
			if observation.original_ROOT17_Physics_result!=true or observation.same_live_tuple!=true: return {"ok":false,"reason":"original_clear_callback_denied_even_if_scene_changed","attempts":attempts}
		if attempt==ORDINARY_MAX_INTERRUPTS:
			_diag_emit("ordinary_budget_exhausted",{"bounty_id":bounty_id,"limit":ORDINARY_MAX_INTERRUPTS,"attempts":attempts,"no_bounty_credit":true})
			_check(false,"bounded ordinary encounter continuation exhausted, no completion credit")
			return {"ok":false,"reason":"ordinary_continuation_budget_exhausted","attempts":attempts}
		# Loading/current=null is not a second wait budget. Original BATTLE.victory
		# will observe the real Battle inside its original 30-second entry wait.
		var battle_scene: Node=tree.current_scene
		var payload: Dictionary=(tree.root.get_node("SceneRouter").call("get_battle_payload") as Dictionary).duplicate(true)
		var party: Array=tree.root.get_node("GameState").get("party")
		var error: String=ordinary_payload_error(payload,source_binding,party.size())
		_diag_emit("ordinary_payload",{"bounty_id":bounty_id,"payload":payload,"binding":source_binding,"error":error,"old_follow":driven,"observed_original_roots":driver.get("observed_positions"),"battle_scene":_diag_node(battle_scene)})
		var expected_normalized: Vector2=Vector2(last.last_live_foot.x/source_binding.size.x,last.last_live_foot.y/source_binding.size.y)
		var last_live_bound: bool=error.is_empty() and var_to_bytes(payload.return_spawn)==var_to_bytes(expected_normalized)
		if not _check(last_live_bound,"exact typed source-bound ordinary encounter and native last-live-foot return, not bounty/mode/action"): return {"ok":false,"reason":"ordinary_payload_rejected","attempts":attempts,"error":error,"last_live_foot":last.last_live_foot,"expected_normalized":expected_normalized}
		if not _check(target_raw.call("verify_sources"),"interrupted independent navigation sources unchanged"): return {"ok":false,"reason":"source_mutation","attempts":attempts}
		var expected_foot: Vector2=payload.return_spawn*source_binding.size
		var before_state: Dictionary=_state()
		var bounty_before: Dictionary=(tree.root.get_node("BountyManager").call("to_dict") as Dictionary).duplicate(true)
		target_raw.call("release")
		var battle: RefCounted=SUPPLIED_BATTLE.new()
		var actual_entry_rows: Array[Dictionary]=[]
		var entry_checker: Callable=func(value: bool,label: String)->bool:
			var original_check: bool=_check(value,label)
			if label=="normal entity/dialog action really enters production Battle":
				var current: Node=tree.current_scene
				var script: Script=current.get_script() as Script if is_instance_valid(current) else null
				var actual_payload: Dictionary=(tree.root.get_node("SceneRouter").call("get_battle_payload") as Dictionary).duplicate(true)
				var exact_entry: bool=value and is_instance_valid(current) and current.is_inside_tree() and not current.is_queued_for_deletion() and current.scene_file_path==BATTLE_SCENE_PATH and script!=null and script.resource_path==BATTLE_SCRIPT_PATH and FileAccess.get_sha256(BATTLE_SCENE_PATH)==BATTLE_SCENE_SHA and FileAccess.get_sha256(BATTLE_SCRIPT_PATH)==BATTLE_SCRIPT_SHA and var_to_bytes(actual_payload)==var_to_bytes(payload)
				var entry_row: Dictionary={"original_value":value,"original_label":label,"actual_Battle":_diag_node(current),"scene_file_path":current.scene_file_path if is_instance_valid(current) else "","scene_sha256":FileAccess.get_sha256(BATTLE_SCENE_PATH),"script_sha256":FileAccess.get_sha256(BATTLE_SCRIPT_PATH),"public_payload":actual_payload,"source_binding":source_binding.duplicate(true),"exact_entry":exact_entry,"physics_frame":Engine.get_physics_frames(),"ticks_usec":Time.get_ticks_usec()}
				actual_entry_rows.append(entry_row)
				_diag_emit("ordinary_actual_Battle_entry",entry_row)
				_check(exact_entry,"ordinary original Battle entry checker binds exact current production scene/script/source payload")
			return original_check
		battle.call("configure",tree,driver,entry_checker)
		var actual: Dictionary=await battle.call("victory",source_binding.id,expected_foot,source_binding.local_version,source_binding.size)
		battle.call("release")
		var after_state: Dictionary=_state()
		var bounty_after: Dictionary=(tree.root.get_node("BountyManager").call("to_dict") as Dictionary).duplicate(true)
		var result: Variant=actual.get("actual_result_payload")
		var reward_ok: bool=result is Dictionary and typeof(result.get("gold"))==TYPE_INT and typeof(result.get("exp"))==TYPE_INT and result.gold>=0 and result.exp>=0 and after_state.gold==before_state.gold+result.gold and after_state.training==before_state.training+result.exp and result.get("bounty_result") is Dictionary and result.bounty_result.is_empty()
		var result_binding_ok: bool=result is Dictionary and typeof(result.get("return_scene"))==TYPE_STRING_NAME and result.return_scene==payload.return_scene and typeof(result.get("return_spawn"))==TYPE_VECTOR2 and var_to_bytes(result.return_spawn)==var_to_bytes(payload.return_spawn) and typeof(result.get("return_world_map_version"))==TYPE_INT and result.return_world_map_version==14 and typeof(result.get("return_local_layout_version"))==TYPE_INT and result.return_local_layout_version==source_binding.local_version and typeof(result.get("battle_mode"))==TYPE_STRING_NAME and result.battle_mode==&"" and typeof(result.get("victory_action"))==TYPE_STRING and result.victory_action=="" and var_to_bytes(actual.get("original_payload"))==var_to_bytes(payload)
		records.ordinary_encounters.append({"bounty_task_id":bounty_id,"payload":payload,"normal_battle":actual,"before":before_state,"after":after_state,"ordinary_rewards_only":true,"bounty_credit":false,"bounty_before":bounty_before,"bounty_after":bounty_after,"reward_delta_matches_actual_victory":reward_ok,"actual_Battle_entry":actual_entry_rows.duplicate(true),"last_live_foot":last.last_live_foot,"last_live_normalized":expected_normalized})
		_diag_emit("ordinary_battle_return",records.ordinary_encounters[-1])
		if not _check(actual.get("entered")==true and actual.get("won")==true and actual.get("returned")==true and actual_entry_rows.size()==1 and actual_entry_rows[0].exact_entry==true and result_binding_ok and reward_ok and var_to_bytes(bounty_before)==var_to_bytes(bounty_after),"ordinary real UI victory/exact return; rewards separate and all bounty states unchanged"): return {"ok":false,"reason":"ordinary_battle_return_or_rewards_failed","attempts":attempts}
		if not _check(await _wait_field(source_binding.id),"ordinary victory naturally rebinds fresh original Field"): return {"ok":false,"reason":"ordinary_return_missing","attempts":attempts}
		var definition: SceneScript=field.get("_current_scene") as SceneScript
		if not _check(var_to_bytes(_bounty_source_binding(definition))==var_to_bytes(source_binding) and _configure_bounty_raw(target_raw,definition),"returned scene/layout/native source exactly unchanged; independent raw rebuilt"): return {"ok":false,"reason":"ordinary_return_source_mismatch","attempts":attempts}
		var return_foot: Vector2=(field.get("_player") as Node2D).position
		if not _check(return_foot.distance_to(expected_foot)<.03 and bool(clear.call(return_foot)) and bool(clear.call(station)),"returned original root+17/Physics and unchanged final station clear"): return {"ok":false,"reason":"ordinary_return_clearance_failed","attempts":attempts}
		original_next_index+=int(driven.index)-1
		remaining=PackedVector2Array([return_foot])
		for index in range(original_next_index,original_path.size()): remaining.append(original_path[index])
		_diag_emit("ordinary_continue_original_path",{"bounty_id":bounty_id,"original_path":original_path,"remaining":remaining,"original_next_index":original_next_index,"unchanged_station":station,"returned_root":_diag_live_point(target_raw),"binding":source_binding,"all_edges_rechecked_by_original_follow":true})
	return {"ok":false,"reason":"unreachable_bounded_fallthrough","attempts":attempts}

