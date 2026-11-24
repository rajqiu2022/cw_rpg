extends "res://tests/test_luoyang_revision_market_rooms_key_retry2_20261015.gd"
## NEW independent Docks key. No Market-room execution or world transition.
var foreman_requests: Array[Dictionary]=[]
const FROZEN_MARKET_HELPER_SHA := "91dcfbdde7c2222265ed1d14a037623e2253a0f44d9bb471a986d31050cda9fe"

func _precheck_revision() -> bool:
	return _track_source("res://tests/test_luoyang_revision_market_rooms_key_retry2_20261015.gd",FROZEN_MARKET_HELPER_SHA) and super._precheck_revision()

func _atom() -> String: return "docks"
func _budget_ms() -> int: return 180000
func _city_id() -> String: return DOCKS_ID

func _foreman_requested(id: String,action: String) -> void:
	foreman_requests.append({"npc_id":id,"action":action,"frame":Engine.get_process_frames()})

func _exercise_revision() -> void:
	if not await _public_setup(Vector2(1200,1840)): return
	var ferry: Array=(candidate_scene.map_layout.portals as Array).filter(func(row: Dictionary)->bool:return row.get("id")=="canal_world_ferry")
	_check(ferry.size()==1 and ferry[0].arrival_foot_px==Vector2(2140,1840) and ferry[0].pos*C.SIZE==Vector2(2140,1840),"Exact revised separated ferry configuration")
	if not await _way(PackedVector2Array([Vector2(1200,1840),Vector2(2140,1840)]),"published_ferry_route_normal_input") or not _visible_arrow(Vector2(2140,1840),"separated_world_ferry"): return
	captures.append(await _capture_gate("new_ferry_visible_not_entered"))
	if not await _way(PackedVector2Array([Vector2(2140,1840),Vector2(1200,1840),Vector2(1200,1600),Vector2(1200,1250),Vector2(1430,1250),Vector2(1670,1296.451613)]),"normal_foreman_approach_stops_before_actual_NPC_body"): return
	var foreman: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id=="canal_work_chief":
			if foreman!=null: _check(false,"Unique actual foreman NPC"); return
			foreman=npc
	var old_box: Array=(candidate_scene.map_layout.interactions as Array).filter(func(row: Dictionary)->bool:return row.get("id")=="canal_feud_chest")
	if not _check(foreman!=null and foreman.is_inside_tree() and foreman.is_visible_in_tree() and foreman.sprite!=null and foreman.sprite.texture!=null and foreman.sprite.is_visible_in_tree() and foreman.interaction_action=="dialog:ch4_canal_grudge_offer" and bool(foreman.get("_in_range")) and old_box.is_empty(),"Actual visible foreman offer target, not box interaction"): return
	var on_screen: Vector2=foreman.sprite.get_global_transform_with_canvas().origin
	_check(root.get_visible_rect().has_point(on_screen),"Actual foreman sprite on-screen before interaction")
	rows.append({"kind":"VISIBLE_NATIVE_FOREMAN","npc_id":foreman.npc_id,"node_id":foreman.get_instance_id(),"texture":foreman.sprite.texture.resource_path,"foot":foreman.position,"on_screen":on_screen,"in_range":foreman.get("_in_range"),"box_offer_removed":old_box.is_empty(),"player":_state("foreman_before_Space")})
	captures.append(await _capture_gate("visible_foreman_before_normal_Space"))
	foreman.npc_action_requested.connect(_foreman_requested)
	await driver.call("key",KEY_SPACE)
	var limit:=mini(deadline,Time.get_ticks_msec()+3000)
	var dialog: Node=root.get_node("DialogPlayer")
	while Time.get_ticks_msec()<limit and not bool(dialog.call("is_playing")): await process_frame
	var script: DialogScript=dialog.get("_current_script") as DialogScript
	var node: DialogNode=dialog.get("_current_node") as DialogNode
	_check(foreman_requests.size()==1 and foreman_requests[0].npc_id=="canal_work_chief" and foreman_requests[0].action=="dialog:ch4_canal_grudge_offer" and bool(dialog.call("is_playing")) and script!=null and script.dialog_id==&"ch4_canal_grudge_offer" and node!=null and node.speaker=="漕工头领","Real Space dispatched visible NPC exact offer and speaker")
	rows.append({"kind":"ACTUAL_FOREMAN_SPACE_OFFER","native_signal":foreman_requests,"dialog_id":script.dialog_id if script!=null else &"","speaker":node.speaker if node!=null else "","reward_or_turnin_credit":false})
	captures.append(await _capture_gate("actual_foreman_offer_dialog"))
	# End only through normal input; no DialogPlayer private advance/stop calls.
	if bool(dialog.call("is_playing")):
		await driver.call("key",KEY_SPACE)
		await driver.call("completed_actor_stage")
		if bool(dialog.call("is_playing")): await driver.call("key",KEY_SPACE)
