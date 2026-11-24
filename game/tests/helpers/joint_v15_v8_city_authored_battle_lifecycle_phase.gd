extends "res://tests/helpers/joint_v15_v8_city_authored_two_choice_phase.gd"
## NEW ROOT194 asynchronous normal-dialog battle lifecycle correction only.
## The original 52 action cases and authored normal UI choices are unchanged.
## LoadingManager/current Battle observations never initiate battle or fake an outcome.
const AUTHORED_PARENT_PATH: String="res://tests/helpers/joint_v15_v8_city_authored_two_choice_phase.gd"
const AUTHORED_PARENT_SHA: String="97a8d255a7148074ff5a2fbb334a675c92697b992b12565b0d14fb52d859b126"
const CASE_ORIGIN_PATH: String="res://tests/helpers/joint_v15_v8_city_prepared_phase.gd"
const CASE_ORIGIN_SHA: String="568a4a869e10afd857246c505e35ab72d0e6ddbe2678b1c67e96c0299fa04967"
const BATTLE_ORIGIN_PATH: String="res://tests/helpers/joint_v15_existing_battle_ui_probe.gd"
const BATTLE_ORIGIN_SHA: String="6ac3b45a23f75f528710677c591a8e51725d2fe57c0d4e8b1de3c8ef552c8ff7"
const NORMAL_BATTLE_PATH: String="res://scenes/battle.tscn"

func _normal_action_case(id: String,kind: String,entry: Dictionary,mode: String) -> void:
	if not _check(FileAccess.get_sha256(AUTHORED_PARENT_PATH).to_lower()==AUTHORED_PARENT_SHA and FileAccess.get_sha256(CASE_ORIGIN_PATH).to_lower()==CASE_ORIGIN_SHA and FileAccess.get_sha256(BATTLE_ORIGIN_PATH).to_lower()==BATTLE_ORIGIN_SHA,"unchanged authored UI, original normal action predicates and bounded battle UI sources"): return
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
			return
		if not bool(battle_lifecycle.get("terminal_source_valid",false)): return
		if actual_battle:
			var battle: RefCounted=BATTLE.new()
			battle.call("configure",tree,driver,_check)
			effects=await battle.call("victory",id,source_foot,3)
			battle.call("release")
			if bool(effects.get("returned",false)) and await _wait_field(id):
				await _finish_dialogs()
				_bind_field(id)
	received=events.slice(event_start)
	if kind=="npcs":
		var exact_npc_event: bool=false
		for event: Dictionary in received:
			if event.get("kind")=="npc_talked_to" and event.get("id")==sid: exact_npc_event=true
		_check(exact_npc_event,"normal current NPC identity actually accepted this input, not a nearer NPC")
	var record: Dictionary={"source_scene_id":id,"source_id":sid,"mode":mode,"dry_run":false,"action":action,"dialog_id":dialog_id,"actual_input":input,"approach":approach,"pre_action_feet_px":[source_foot.x,source_foot.y],"events":received,"dialog_nodes":dialogues,"before":before,"after":_state(),"effects":effects}
	record["battle_lifecycle"]=battle_lifecycle.duplicate(true)
	records[kind].append(record)
	_check(_write(kind+"_"+id+"_"+sid+"_"+mode+".json",record),"actual normal action and state evidence checked readback")
	await _capture(kind+"_"+sid+"_"+mode)

func _observed_battle_lifecycle(dialogues: Array[Dictionary]) -> Dictionary:
	var current: Node=tree.current_scene
	var loading: Node=tree.root.get_node_or_null("LoadingManager")
	var loading_active: bool=is_instance_valid(loading) and bool(loading.get("_transition_active"))
	var loading_path: String=String(loading.get("_loading_path")) if is_instance_valid(loading) else ""
	var battle_ui: bool=is_instance_valid(current) and current.is_inside_tree() and not current.is_queued_for_deletion() and current.scene_file_path==NORMAL_BATTLE_PATH and current.get_node_or_null("%BtnAttack")!=null
	var evidence: Dictionary={"scope":"ACTUAL_NORMAL_DIALOGUE_BATTLE_LIFECYCLE_NOT_DIRECT_BATTLE_OR_RESULT_API","ticks_msec":Time.get_ticks_msec(),"current_scene_path":current.scene_file_path if is_instance_valid(current) else "","current_scene_id":current.get_instance_id() if is_instance_valid(current) else 0,"current_scene_live":is_instance_valid(current) and current.is_inside_tree(),"loading_instance_id":loading.get_instance_id() if is_instance_valid(loading) else 0,"loading_active":loading_active,"loading_path":loading_path,"actual_battle_ui":battle_ui,"actual_battle_loading":loading_active and loading_path==NORMAL_BATTLE_PATH,"terminal_source_valid":false,"authored_terminal_requires_battle":false,"battle_wait_budget_msec":30000,"battle_ui_budget_msec":180000,"normal_ui_only":true,"outcome_injected":false}
	if dialogues.is_empty():
		evidence["terminal_source_status"]="NO_ACTUAL_VISITED_DIALOG_NODE"
		_check(false,"actual normal dialogue terminal source is present before lifecycle classification")
		return evidence
	var last: Dictionary=dialogues.back()
	var source_path: String=String(last.get("source_path",""))
	var source_sha: String=String(last.get("source_sha256",""))
	var identity: String=String(last.get("id",""))
	evidence["terminal_source_path"]=source_path
	evidence["terminal_source_sha256"]=source_sha
	evidence["terminal_identity"]=identity
	var bytes_bound: bool=not source_path.is_empty() and FileAccess.file_exists(source_path) and not source_sha.is_empty() and FileAccess.get_sha256(source_path)==source_sha
	if not _check(bytes_bound,"actual visited dialogue terminal source bytes are unchanged"): return evidence
	var actual_script: DialogScript=load(source_path) as DialogScript
	var node_id: String=identity.get_slice("/",1)
	var actual_node: DialogNode=actual_script.find_node_by_id(StringName(node_id)) if actual_script!=null else null
	var source_valid: bool=actual_script!=null and actual_node!=null and identity==String(actual_script.dialog_id)+"/"+String(actual_node.node_id)
	if not _check(source_valid,"actual visited terminal matches original DialogScript and authored node"): return evidence
	var terminal_action: String=String(actual_node.on_end)
	var command: String=terminal_action.get_slice(":",0)
	evidence["terminal_source_valid"]=true
	evidence["terminal_on_end"]=terminal_action
	evidence["authored_terminal_requires_battle"]=command in ["battle","battle_solo","battle_then","battle_solo_then","battle_group","battle_group_then"]
	actual_node=null
	actual_script=null
	return evidence

