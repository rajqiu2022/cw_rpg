extends "res://tests/helpers/joint_v15_v8_city_authored_battle_lifecycle_phase.gd"
## NEW ROOT198 source-authored scene lifecycle observation only.
## All 52 normal input/effect branches and inherited 45s UI/30s-180s battle
## predicates remain. No transition initiation, state bypass or timer cancellation.
const SCENE_CASE_ORIGIN_PATH: String="res://tests/helpers/joint_v15_v8_city_authored_battle_lifecycle_phase.gd"
const SCENE_CASE_ORIGIN_SHA: String="44687491cbe761ef92f97a20592a5cee21ffe4c385b94894095722fbe67583d5"
var transition_case_blocked: bool=false

func _normal_action_case(id: String,kind: String,entry: Dictionary,mode: String) -> void:
	if not _check(FileAccess.get_sha256(SCENE_CASE_ORIGIN_PATH).to_lower()==SCENE_CASE_ORIGIN_SHA,"exact unchanged ROOT198 battle lifecycle and original 52 action predicates"): return
	if not _check(FileAccess.get_sha256(AUTHORED_PARENT_PATH).to_lower()==AUTHORED_PARENT_SHA and FileAccess.get_sha256(CASE_ORIGIN_PATH).to_lower()==CASE_ORIGIN_SHA and FileAccess.get_sha256(BATTLE_ORIGIN_PATH).to_lower()==BATTLE_ORIGIN_SHA,"unchanged authored UI, original normal action predicates and bounded battle UI sources"): return
	if not _check(not transition_case_blocked,"no prior unrecognized or failed normal transition before a new public fixture"): return
	_public_fixture(entry)
	if not await _open(id): return
	var sid: String=String(entry.get("npc_id" if kind=="npcs" else "id",""))
	var slot: Dictionary=_slot(manifest.gameplay_slots[kind],sid)
	var target: Node=_npc(sid) if kind=="npcs" else null
	_check(kind!="npcs" or target!=null,"required original gated NPC really spawned: "+id+"/"+sid)
	if kind=="npcs" and target==null: return
	# Each gated original NPC appears through its NORMAL entry fixture. Aggregate
	# all these actual source families before claiming a complete boat domain.
	if kind=="npcs":
		var water_proofs: Array=await probe.call("water_proofs")
		for proof: Dictionary in water_proofs:
			proof["normal_npc_gate_fixture"]=id+"/"+sid+"/"+mode
			records.water_domains.append(proof)
			_check(_write("water_family_"+id+"_"+sid+"_"+mode+".json",proof),"full normal source-family domain evidence checked readback before absence classification")
	var station: Vector2=_npc_stand(target) if target!=null else _point(slot.get("stand_px"))
	var approach: Dictionary=await probe.call("move_to",station)
	if not _check(bool(approach.get("ok",false)),"real normal input reaches original action: "+id+"/"+sid+" "+mode): return
	var source_foot: Vector2=(field.get("_player") as Node2D).position
	var before: Dictionary=_state()
	var event_start: int=events.size()
	var input: Dictionary={"mode":mode}
	if mode=="space": await driver.call("key",KEY_SPACE)
	elif target!=null: input=await probe.call("click_entity",target.get("sprite"))
	else:
		var sprite: Sprite2D=probe.call("prop",String(slot.get("object_id",""))) as Sprite2D
		_check(sprite!=null,"original action's actual entity exists, no invisible ground fallback")
		if sprite==null: return
		input=await probe.call("click_entity",sprite)
	await driver.call("completed_actor_stage")
	var dialogues: Array[Dictionary]=await _finish_dialogs()
	var action: String=String(entry.get("interaction_action",entry.get("action","")))
	var dialog_id: String=String(entry.get("dialog_id",""))
	if action.begins_with("dialog:"): dialog_id=action.trim_prefix("dialog:")
	var received: Array=events.slice(event_start)
	var effects: Dictionary={}
	var battle_lifecycle: Dictionary={}
	var scene_lifecycle: Dictionary={}
	var settled_id: String=id
	if action.begins_with("spar:"):
		var modal: Control=field.get("_sparring_confirm_dialog") as Control
		_check(modal!=null and modal.is_visible_in_tree(),"ordinary sparring preface opens real confirm, not direct battle")
		if modal!=null:
			var button: Button=modal.get_node_or_null("%ConfirmAction") as Button
			_check(button!=null,"normal sparring confirmation button exists")
			if button!=null: await driver.call("pointer",button.get_global_rect().get_center())
		var battle: RefCounted=BATTLE.new()
		battle.call("configure",tree,driver,_check)
		effects=await battle.call("victory",id,source_foot,3)
		battle.call("release")
		battle=null
		var spar_id: String=action.split(":")[1]
		_check(bool(((tree.root.get_node("GameState").get("sparring_records") as Dictionary).get(spar_id,{}) as Dictionary).get("won",false)),"normal first victory records actual sparring result/reward")
		if bool(effects.get("returned",false)) and await _wait_field(id): _bind_field(id)
	elif action.begins_with("shop:"):
		effects=await _normal_shop_buy(id,source_foot)
	elif action.begins_with("bounty_board:"):
		var page: Node=tree.current_scene
		_check(page!=null and page.get_node_or_null("BountyEntries")!=null,"actual entity opens normal bounty board")
		if page!=null and page.get_node_or_null("CloseButton")!=null:
			await driver.call("pointer",(page.get_node("CloseButton") as Control).get_global_rect().get_center())
			_check(await _wait_field(id),"normal bounty close returns original city")
			if is_instance_valid(field): _bind_field(id)
	elif action.begins_with("discover_readable:"):
		var parts: PackedStringArray=action.split(":")
		_check(parts.size()>=3 and bool((tree.root.get_node("GameState").get("flags") as Dictionary).get(parts[2],false)),"normal actual discovery executes original once flag")
	else:
		_check(not dialog_id.is_empty() and not dialogues.is_empty(),"normal original NPC/hotspot starts and completes actual dialogue, no dry log")
		battle_lifecycle=_observed_battle_lifecycle(dialogues)
		if not records.has("battle_lifecycle"): records["battle_lifecycle"]=[]
		(records.battle_lifecycle as Array).append(battle_lifecycle.duplicate(true))
		if not _check(_write("battle_entry_"+id+"_"+sid+"_"+mode+".json",battle_lifecycle),"actual dialogue/loading/battle scalar evidence persisted with exact readback"): return
		var actual_battle: bool=bool(battle_lifecycle.get("actual_battle_ui",false)) or bool(battle_lifecycle.get("actual_battle_loading",false))
		if bool(battle_lifecycle.get("authored_terminal_requires_battle",false)) and not actual_battle:
			_check(false,"actual authored terminal requires battle but no real LoadingManager battle transition or normal Battle UI exists")
			transition_case_blocked=true
			return
		if not bool(battle_lifecycle.get("terminal_source_valid",false)):
			transition_case_blocked=true
			return
		if actual_battle:
			var battle: RefCounted=BATTLE.new()
			battle.call("configure",tree,driver,_check)
			effects=await battle.call("victory",id,source_foot,3)
			battle.call("release")
			if bool(effects.get("returned",false)) and await _wait_field(id):
				var return_dialogues: Array[Dictionary]=await _finish_dialogs()
				if not return_dialogues.is_empty():
					var return_terminal: Dictionary=_observed_battle_lifecycle(return_dialogues)
					if String(return_terminal.get("terminal_on_end","")).begins_with("scene:"):
						scene_lifecycle=await _observe_authored_scene_arrival(return_terminal)
						settled_id=String(scene_lifecycle.get("target_scene_id",""))
				if settled_id==id: _bind_field(id)
		elif String(battle_lifecycle.get("terminal_on_end","")).begins_with("scene:"):
			scene_lifecycle=await _observe_authored_scene_arrival(battle_lifecycle)
			settled_id=String(scene_lifecycle.get("target_scene_id",""))
	if not scene_lifecycle.is_empty(): effects["scene_transition"]=scene_lifecycle.duplicate(true)
	var settled: Dictionary=_normal_field_receipt(settled_id)
	settled["source_scene_id"]=id
	settled["source_id"]=sid
	settled["mode"]=mode
	settled["original_action"]=action
	settled["battle_entry"]=battle_lifecycle.duplicate(true)
	settled["battle_effects"]=effects.duplicate(true)
	settled["scene_arrival"]=scene_lifecycle.duplicate(true)
	if not scene_lifecycle.is_empty(): settled["complete"]=bool(settled.complete) and bool(scene_lifecycle.get("complete",false))
	if not records.has("normal_transition_receipts"): records["normal_transition_receipts"]=[]
	(records.normal_transition_receipts as Array).append(settled.duplicate(true))
	var receipt_saved: bool=_write("normal_transition_"+id+"_"+sid+"_"+mode+".json",settled)
	if not _check(receipt_saved and bool(settled.complete),"normal action has completed actual loading/live Field Player identity; unrecognized pending transition refuses"):
		transition_case_blocked=true
		return
	received=events.slice(event_start)
	if kind=="npcs":
		var exact_npc_event: bool=false
		for event: Dictionary in received:
			if event.get("kind")=="npc_talked_to" and event.get("id")==sid: exact_npc_event=true
		_check(exact_npc_event,"normal current NPC identity actually accepted this input, not a nearer NPC")
	var record: Dictionary={"source_scene_id":id,"source_id":sid,"mode":mode,"dry_run":false,"action":action,"dialog_id":dialog_id,"actual_input":input,"approach":approach,"pre_action_feet_px":[source_foot.x,source_foot.y],"events":received,"dialog_nodes":dialogues,"before":before,"after":_state(),"effects":effects}
	record["battle_lifecycle"]=battle_lifecycle.duplicate(true)
	record["scene_lifecycle"]=scene_lifecycle.duplicate(true)
	record["normal_transition_receipt"]=settled.duplicate(true)
	records[kind].append(record)
	_check(_write(kind+"_"+id+"_"+sid+"_"+mode+".json",record),"actual normal action and state evidence checked readback")
	await _capture(kind+"_"+sid+"_"+mode)

func _normal_field_receipt(expected_id: String) -> Dictionary:
	var current: Node=tree.current_scene
	var loading: Node=tree.root.get_node_or_null("LoadingManager")
	var loading_active: bool=is_instance_valid(loading) and bool(loading.get("_transition_active"))
	var live_field: bool=is_instance_valid(current) and current.is_inside_tree() and not current.is_queued_for_deletion() and current.scene_file_path in ["res://scenes/field_walkable.tscn","res://scenes/field.tscn"]
	var definition: SceneScript=current.get("_current_scene") as SceneScript if live_field else null
	var player: Node2D=current.get("_player") as Node2D if live_field else null
	var live_player: bool=is_instance_valid(player) and player.is_inside_tree() and not player.is_queued_for_deletion() and current.is_ancestor_of(player) and player.get_script()!=null and player.get_script().resource_path=="res://scripts/field/player.gd"
	var dialog_playing: bool=bool(tree.root.get_node("DialogPlayer").call("is_playing"))
	var complete: bool=not loading_active and not dialog_playing and live_field and live_player and definition!=null and String(definition.scene_id)==expected_id and field==current and not bool(current.get("_scene_rebuilding"))
	return {"scope":"OBSERVED_NORMAL_ACTION_TRANSITION_RECEIPT_NOT_PORTAL_OR_FULL_CREDIT","ticks_msec":Time.get_ticks_msec(),"expected_scene_id":expected_id,"actual_scene_id":String(definition.scene_id) if definition!=null else "","current_scene_path":current.scene_file_path if is_instance_valid(current) else "","current_scene_instance_id":current.get_instance_id() if is_instance_valid(current) else 0,"actual_definition_path":definition.resource_path if definition!=null else "","actual_definition_sha256":FileAccess.get_sha256(definition.resource_path) if definition!=null and FileAccess.file_exists(definition.resource_path) else "","live_field":live_field,"bound_field_is_current":field==current,"live_player":live_player,"player_instance_id":player.get_instance_id() if is_instance_valid(player) else 0,"player_script":player.get_script().resource_path if is_instance_valid(player) and player.get_script()!=null else "","actual_player_feet_px":[player.position.x,player.position.y] if is_instance_valid(player) else [],"loading_active":loading_active,"loading_path":String(loading.get("_loading_path")) if is_instance_valid(loading) else "","complete":complete,"route_injected":false,"outcome_injected":false}

func _observe_authored_scene_arrival(terminal: Dictionary,seen_terminals: Dictionary={}) -> Dictionary:
	var started: int=Time.get_ticks_msec()
	var action: String=String(terminal.get("terminal_on_end",""))
	var parts: PackedStringArray=action.split(":")
	var target_id: String=parts[1] if parts.size()==2 else ""
	var source_path: String=String(terminal.get("terminal_source_path",""))
	var source_sha: String=String(terminal.get("terminal_source_sha256",""))
	var valid: bool=bool(terminal.get("terminal_source_valid",false)) and parts.size()==2 and parts[0]=="scene" and not target_id.is_empty() and FileAccess.file_exists(source_path) and FileAccess.get_sha256(source_path)==source_sha
	var evidence: Dictionary={"scope":"ACTUAL_SOURCE_AUTHORED_SCENE_ARRIVAL_NOT_ROUTER_SHORTCUT_OR_FULL","start_ticks_msec":started,"end_ticks_msec":started,"wait_budget_msec":30000,"target_scene_id":target_id,"authored_terminal":terminal.duplicate(true),"source_bytes_exact_before":valid,"complete":false,"go_field_called_by_observer":false,"fixture_reset_during_wait":false,"production_timer_cancelled":false}
	if not _check(valid,"scene arrival observer uses actual visited original terminal source/node/SHA and exact authored scene target"): return evidence
	var terminal_key: String=source_path+"@"+source_sha+"/"+String(terminal.get("terminal_identity",""))
	if not _check(not seen_terminals.has(terminal_key),"normal source-authored scene chain is finite; repeated terminal refuses instead of another fixture"):
		evidence["repeated_terminal_rejected"]=true
		return evidence
	var chain: Dictionary=seen_terminals.duplicate()
	chain[terminal_key]=true
	var arrived: bool=await _wait_field(target_id,30)
	evidence["actual_arrival_before_on_enter_ui"]=_normal_field_receipt(target_id)
	if not _check(arrived,"normal authored scene terminal reaches its exact live Field/Player within original 30s wait"): return evidence
	# Normal automatic arrival dialogue must use the same inherited 45s UI
	# path. is_playing=false for the source dialogue is not proof that the
	# target's authored scene/automatic dialogue lifecycle has completed.
	var arrival_dialogues: Array[Dictionary]=await _finish_dialogs()
	evidence["on_enter_dialog_nodes"]=arrival_dialogues.duplicate(true)
	evidence["on_enter_ui_budget_msec"]=45000
	var chain_complete: bool=true
	if not arrival_dialogues.is_empty():
		var arrival_terminal: Dictionary=_observed_battle_lifecycle(arrival_dialogues)
		evidence["on_enter_terminal"]=arrival_terminal.duplicate(true)
		chain_complete=bool(arrival_terminal.get("terminal_source_valid",false))
		if chain_complete and String(arrival_terminal.get("terminal_on_end","")).begins_with("scene:"):
			var following: Dictionary=await _observe_authored_scene_arrival(arrival_terminal,chain)
			evidence["following_source_authored_scene"]=following.duplicate(true)
			chain_complete=bool(following.get("complete",false))
			target_id=String(following.get("target_scene_id",""))
			evidence["target_scene_id"]=target_id
		elif bool(arrival_terminal.get("authored_terminal_requires_battle",false)) or bool(arrival_terminal.get("actual_battle_ui",false)) or bool(arrival_terminal.get("actual_battle_loading",false)):
			chain_complete=false
			_check(false,"unexpected arrival-dialogue battle must not be silently credited as a completed scene arrival")
	evidence["end_ticks_msec"]=Time.get_ticks_msec()
	evidence["actual_arrival"]=_normal_field_receipt(target_id)
	evidence["source_bytes_exact_after"]=FileAccess.file_exists(source_path) and FileAccess.get_sha256(source_path)==source_sha
	evidence["complete"]=chain_complete and bool((evidence.actual_arrival as Dictionary).complete) and bool(evidence.source_bytes_exact_after)
	_check(bool(evidence.complete),"source-authored scene and normal on-enter UI finish on exact current Field/Player; unknown pending transition refuses")
	if bool(evidence.complete):
		# The arrived target may be an ordinary legacy area (the actual ancient
		# temple), not a city-v5 resource. Never bind it to a city manifest/raw
		# oracle. Release only the now-obsolete test-owned source-field oracles.
		_release_field_oracles()
	return evidence

