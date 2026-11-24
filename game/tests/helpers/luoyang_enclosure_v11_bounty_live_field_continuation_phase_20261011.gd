extends "res://tests/helpers/luoyang_enclosure_v11_bounty_encounter_continuation_phase_20261011.gd"
## Original continuation, two-source bounty rewards and all original inputs inherit.
## Only current-Field lifecycle loss is distinct; any actual live clearance FAIL
## still rejects. Ordinary Battle waits remain the ORIGINAL 30/180/30 seconds.
const LIVE_INPUT = preload("res://tests/helpers/luoyang_bounty_live_field_input_driver_20261011.gd")
const LIVE_INPUT_PATH := "res://tests/helpers/luoyang_bounty_live_field_input_driver_20261011.gd"
const LIVE_INPUT_SHA := "905a37e4170bb4fbc0a1f661602262910508c8574858670820d48f0a4d142199"
const BATTLE_SCENE_PATH := "res://scenes/battle.tscn"
const BATTLE_SCENE_SHA := "8476a5c23a4eec1194d65a390daeaebf860d93845f203aed9e2768d8907cbaa9"
const BATTLE_SCRIPT_PATH := "res://scripts/battle/battle_controller.gd"
const BATTLE_SCRIPT_SHA := "bad948d80679350289dc70c1a550c522a8173cc4c88bef75f02b2db3e6b4a087"

func run_bounty_diagnostic(owner: SceneTree,directory: String) -> Dictionary:
	tree=owner; candidate=true; output=directory
	before_files=_normal_files(); before_slot=tree.root.get_node("SaveManager").get("active_slot")
	driver=LIVE_INPUT.new(); driver.call("configure",tree)
	_check(FileAccess.get_sha256(LIVE_INPUT_PATH)==LIVE_INPUT_SHA and driver.get_script().resource_path==LIVE_INPUT_PATH,"actual NEW lifecycle driver installed, no lexical INPUT shadow")
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
		var battle: RefCounted=BATTLE.new()
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

