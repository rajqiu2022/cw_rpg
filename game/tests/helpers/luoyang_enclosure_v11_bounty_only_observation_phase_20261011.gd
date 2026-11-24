extends "res://tests/helpers/luoyang_enclosure_v11_authored_input_repairs_focused_phase_20261011.gd"
## Observation ONLY. Original bounty predicates, input, RNG and cleanup remain.
## No alternative UI lookup, refresh, extra await, station or encounter control.
const BOUNTY_SCOPE := "LUOYANG_TWO_ORIGINAL_BOUNTY_OBSERVATION_NOT_SIX"
const BOUNTY_FLAG := "--luoyang-bounty-only-observation"
const BOUNTY_PARENT_PATH := "res://tests/helpers/luoyang_enclosure_v11_city_only_indirect_market_return_phase_20261011.gd"
const BOUNTY_PARENT_SHA := "3c37cf6568f1cd1ba6d41c28c276879ca6a352205c9c5a9f8b8acdaabf0ab1a6"
var _diag_events: Array[Dictionary]=[]
var _diag_button_rows: int=0
var _diag_state_rows: int=0
var _diag_follow_rows: int=0
var _diag_write_failed: bool=false

func _diag_value(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary={}
		for key: Variant in value: result[String(key)]=_diag_value(value[key])
		return result
	if value is Array or value is PackedVector2Array or value is PackedStringArray:
		var result: Array=[]
		for item: Variant in value: result.append(_diag_value(item))
		return result
	if typeof(value)==TYPE_VECTOR2: return [value.x,value.y] if value.is_finite() else {"nonfinite_vector":str(value),"native_bytes":var_to_bytes(value).hex_encode()}
	if typeof(value)==TYPE_STRING_NAME: return String(value)
	if typeof(value)==TYPE_FLOAT and not is_finite(value): return {"nonfinite_float":str(value),"native_bytes":var_to_bytes(value).hex_encode()}
	if value is Object:
		if not is_instance_valid(value): return {"invalid_object":true}
		return {"class":value.get_class(),"instance_id":value.get_instance_id(),"resource_path":value.resource_path if value is Resource else ""}
	return value

func _diag_node(node: Variant) -> Dictionary:
	if not is_instance_valid(node) or not node is Node: return {"valid":false}
	var script: Script=node.get_script() as Script
	var result: Dictionary={"valid":true,"class":node.get_class(),"instance_id":node.get_instance_id(),"name":String(node.name),"path":String(node.get_path()) if node.is_inside_tree() else "NOT_INSIDE_TREE","inside_tree":node.is_inside_tree(),"queued":node.is_queued_for_deletion(),"script_path":script.resource_path if script!=null else ""}
	if node is Control:
		result["visible"]=node.visible; result["visible_in_tree"]=node.is_visible_in_tree()
		result["global_rect"]=str(node.get_global_rect()); result["global_rect_native_bytes"]=var_to_bytes(node.get_global_rect()).hex_encode()
	if node is Button:
		result["disabled"]=node.disabled; result["text"]=node.text
	return result

func _diag_children(node: Variant) -> Dictionary:
	var result: Dictionary=_diag_node(node)
	var children: Array=[]
	if is_instance_valid(node):
		for child: Node in node.get_children(): children.append(_diag_children(child))
	result["children"]=children
	return result

func _diag_cards(page: Variant) -> Dictionary:
	return _diag_children(page.get_node_or_null("BountyEntries")) if is_instance_valid(page) else {"valid":false}

func _diag_definition(definition: BountyDef) -> Dictionary:
	if definition==null: return {"valid":false}
	var path: String=definition.resource_path
	return {"valid":true,"path":path,"source_sha256":FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT_OR_MEMORY_RESOURCE","bounty_id":definition.bounty_id,"board_city":definition.board_city,"locations":definition.locations.duplicate(true),"locations_native_bytes":var_to_bytes(definition.locations).hex_encode(),"reward_reputation":definition.reward_reputation,"reward_training":definition.reward_training,"enemy_ids":definition.enemy_ids}

func _diag_resource_file(path: String) -> Dictionary:
	var present: bool=FileAccess.file_exists(path)
	var file: FileAccess=FileAccess.open(path,FileAccess.READ) if present else null
	return {"path":path,"exists":present,"sha256":FileAccess.get_sha256(path) if present else "ABSENT_OR_MEMORY_RESOURCE","bytes":file.get_length() if file!=null else 0}

func _diag_field_context() -> Dictionary:
	var current: Node=tree.current_scene
	var result: Dictionary={"current_scene":_diag_node(current),"held_field":_diag_node(field),"held_field_is_current":is_instance_valid(field) and current==field,"public_battle_payload":tree.root.get_node("SceneRouter").call("get_battle_payload").duplicate(true),"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"ticks_usec":Time.get_ticks_usec()}
	if is_instance_valid(current): result["current_scene_file_path"]=current.scene_file_path
	if is_instance_valid(field) and not field.is_queued_for_deletion():
		var definition: SceneScript=field.get("_current_scene") as SceneScript
		var player: Node2D=field.get("_player") as Node2D
		result["held_player"]=_diag_node(player)
		result["definition"]={"id":String(definition.scene_id),"path":definition.resource_path,"layout_path":definition.map_layout.resource_path if definition.map_layout!=null else ""} if definition!=null else {"valid":false}
		if definition!=null and definition.map_layout!=null:
			result["scene_source"]=_diag_resource_file(definition.resource_path)
			result["layout_source"]=_diag_resource_file(definition.map_layout.resource_path)
			result["layout_fields_native_bytes"]=var_to_bytes([definition.map_layout.design_size,definition.map_layout.walkable_mask_path,definition.map_layout.walkable_regions,definition.map_layout.blockers,definition.map_layout.visual_objects]).hex_encode()
		result["canvas"]=field.get("_world_size"); result["screen"]=field.get("_screen_size")
	return result

func _diag_point(target_raw: RefCounted,point: Vector2) -> Dictionary:
	var result: Dictionary={"root":point,"root_native_bytes":var_to_bytes(point).hex_encode(),"point_finite":point.is_finite(),"Physics_observed":false,"source_17_observed":false}
	if not point.is_finite(): return result
	if target_raw!=null:
		result["source_root_AND_visible17"]=target_raw.call("foot_evidence",point)
		result["source_17_observed"]=true
	if is_instance_valid(field) and not field.is_queued_for_deletion() and tree.current_scene==field:
		var player: Node2D=field.get("_player") as Node2D
		var container: Node2D=field.get("world_container") as Node2D
		if is_instance_valid(player) and is_instance_valid(container):
			result["actual_Physics_clear"]=_actual_body_clear(field,point)
			result["Physics_observed"]=true
			var offset: Vector2=container.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y"))))-player.position
			result["actual_visible_offset"]=offset
			result["visible_center"]=point+offset
			if target_raw!=null: result["actual_17_sample_points"]=target_raw.call("samples",point+offset)
	return result

func _diag_live_point(target_raw: RefCounted) -> Dictionary:
	if not is_instance_valid(field) or field.is_queued_for_deletion(): return {"observed":false,"reason":"original_held_Field_gone_or_queued"}
	var player: Node2D=field.get("_player") as Node2D
	if not is_instance_valid(player): return {"observed":false,"reason":"original_player_gone"}
	return _diag_point(target_raw,player.position)

func _diag_emit(kind: String,data: Dictionary) -> void:
	var record: Dictionary={"ordinal":_diag_events.size(),"kind":kind,"scope":BOUNTY_SCOPE,"six_slot_eligible":false,"observational_only":true,"ticks_usec":Time.get_ticks_usec(),"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"native_data_bytes":var_to_bytes(data).hex_encode(),"data":_diag_value(data)}
	_diag_events.append(record)
	var ok: bool=_write("bounty_observation_%03d_%s.json"%[record.ordinal,kind],record)
	if not ok: _diag_write_failed=true
	_check(ok,"immediate readonly bounty observation persisted "+kind)

func _normal_bounty_rewards() -> void:
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
		_check(not IDS.has(target_id),"existing bounty neighbor art/identity retained, not rebuilt as city")
		var accepted: bool=tree.root.get_node("SceneRouter").call("go_field_smart",StringName(target_id))
		if not _check(accepted and await _wait_field(target_id),"normal public travel enters original neighboring bounty scene"): continue
		await _finish_dialogs()
		var current: SceneScript=field.get("_current_scene") as SceneScript
		var target_raw: RefCounted=ROOT_AND_FEET_RAW.new()
		if not _check(bool(target_raw.call("configure_current",current,field)),"original neighbor raw navigation still valid"): target_raw.call("release"); continue
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
		var driven: Dictionary=await driver.call("follow",field,path,clear,segment)
		_diag_follow_rows+=1
		_diag_emit("follow_immediate_return",{"bounty_id":entry.bounty_id,"complete_original_driven_return":driven.duplicate(true),"original_path":path,"original_station":station,"current_root":_diag_live_point(target_raw),"field_context":_diag_field_context(),"timing":"SYNCHRONOUS_AFTER_ORIGINAL_FOLLOW_BEFORE_ORIGINAL_CHECK_NOT_PER_TICK_PHYSICS"})
		if not _check(bool(driven.get("ok",false)),"actual normal input approaches original bounty NPC"): target_raw.call("release"); continue
		var pre: Dictionary=_state()
		var original_foot: Vector2=(field.get("_player") as Node2D).position
		var original_size: Vector2=field.get("_world_size")
		await driver.call("key",KEY_SPACE)
		var battle: RefCounted=BATTLE.new()
		battle.call("configure",tree,driver,_check)
		var actual: Dictionary=await battle.call("victory",target_id,original_foot,1,original_size)
		battle.call("release")
		var after: Dictionary=_state()
		var final_state: Dictionary=((manager.call("to_dict") as Dictionary).states as Dictionary).get(String(entry.bounty_id),{})
		_check(bool(actual.get("won",false)) and String(final_state.get("status",""))=="captured" and int(final_state.get("completion_count",0))==1,"real bounty victory completes original case exactly once")
		_check(int(after.reputation)==int(pre.reputation)+definition.reward_reputation and int(after.training)==int(pre.training)+definition.reward_training,"normal capture gives exact authored reputation/training, no fake result")
		records.bounties.append({"id":entry.bounty_id,"location":location,"normal_drive":driven,"battle":actual,"before":pre,"after":after,"final_state":final_state})
		_diag_emit("original_reward_checks_completed",{"bounty_id":entry.bounty_id,"original_bounty_record":records.bounties[-1],"manager_state":manager.call("to_dict"),"field_context":_diag_field_context()})
		target_raw.call("release")

func run_bounty_diagnostic(owner: SceneTree,directory: String) -> Dictionary:
	tree=owner; candidate=true; output=directory
	before_files=_normal_files(); before_slot=tree.root.get_node("SaveManager").get("active_slot")
	driver=INPUT.new(); driver.call("configure",tree)
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

func _finish_bounty_diagnostic() -> Dictionary:
	# Common cleanup is retained from _finish_city_stage; full stage-count/water
	# claims are deliberately NOT invoked or fabricated for this finite scope.
	await natural_field_grace("city_only_before_actual_cleanup")
	records["own_natural_grace"]=natural_grace_records.duplicate(true)
	var bus: Node=tree.root.get_node("EventBus")
	for entry: Dictionary in event_connections:
		if bus.is_connected(entry.signal,entry.callable): bus.disconnect(entry.signal,entry.callable)
	event_connections.clear()
	if raw!=null: _check(raw.call("verify_sources"),"last current PNG source verification")
	_release_field_oracles()
	var reference: WeakRef=weakref(field) if is_instance_valid(field) else null
	if is_instance_valid(tree.current_scene): tree.current_scene.queue_free(); tree.current_scene=null
	field=null
	for tick in 8: await tree.process_frame
	_check(reference==null or reference.get_ref()==null,"owned Field released normally")
	_check(_normal_files()==before_files and tree.root.get_node("SaveManager").get("active_slot")==before_slot,"all player paths and slot unchanged")
	if not before_nav.is_empty():
		var router: Node=tree.root.get_node("SceneRouter")
		router.call("reset_for_new_game")
		router.call("restore_navigation_state",router.call("get_navigation_state"),&"", &"world_map_jianghu")
		_check(router.call("get_navigation_state")==before_nav,"public current-format process baseline restored exactly")
	var report: Dictionary={"schema":1,"scope":BOUNTY_SCOPE,"phase":"bounty_only_diagnostic","candidate_before_cutover":true,"diagnostic_complete":failures==0 and runtime_started,"complete":failures==0 and runtime_started,"checks":checks,"failures":failures,"records":records.duplicate(true),"initial_navigation":before_nav.duplicate(true),"current_author_bindings":{},"coverage":{"bounty_rewards":records.bounties.size(),"interaction_negatives_executed":false,"portal_inputs_executed":false,"spar_inputs_executed":false},"six_slot_eligible":false,"full_geometry_tested":false,"full_gameplay_tested":false,"historical_compatibility_tested":false,"world_subject_version":14,"world_full_tested":false,"visual_verdict":"NOT_REVIEWED","formal_approved":false}
	for id: String in author_records: report.current_author_bindings[id]={"path":ENCLOSURE.manifest_path(StringName(id)),"sha256":ENCLOSURE.manifest_sha(StringName(id)),"base_path":ENCLOSURE.base_manifest_path(StringName(id)),"base_sha256":ENCLOSURE.base_manifest_sha(StringName(id))}
	report["diagnostic_collection_complete"]=not _diag_write_failed and _diag_button_rows==2 and _diag_state_rows==2
	report["observation_summary"]={"button_lookups":_diag_button_rows,"accepted_states":_diag_state_rows,"original_follow_returns":_diag_follow_rows,"immediate_receipts":_diag_events.size(),"write_failed":_diag_write_failed,"expected_original_failures_are_NOT_pass":true}
	report["bounty_observations"]=_diag_events.duplicate(true)
	_check(_write("bounty_only_diagnostic_stage.json",report),"limited original two bounty diagnostics persists")
	if driver!=null: driver.call("release"); driver=null
	manifest.clear(); tree=null
	report.checks=checks; report.failures=failures
	report.complete=report.complete and failures==0; report.diagnostic_complete=report.complete
	return report

