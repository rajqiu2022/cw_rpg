extends RefCounted
## Positive paths are real native NPC/key/ShopUI mouse input. Only finish replay is a negative.
const ORACLE=preload("res://build/luoyang_city_revision_20261025h_qa01/service_oracle_NOTREADY.gd")
var last_dialog: String=""
var last_helper: RefCounted
var shop_room_refs: Array=[]
var remembered_uv: Vector2
var inn_row: Dictionary={}
var rest_picture: bool=false
func enter_and_assert_source_actor(qa: Variant,row: Dictionary) -> bool:
	return await qa._room25h(row)
func open_inn_menu_and_decline(qa: Variant,row: Dictionary) -> bool:
	if not await qa._open_menu25h(row) or not await qa._choice25h(2,"leave",row) or not await qa._finish_node25h(): return false
	return qa.check(qa._same_room_owner25h() and not qa.service25h.call("debug_state").active,"Inn actual hero/menu/leave exists; inn is not a fake fourth goods shop")
func real_interact_then_select_shop(qa: Variant,row: Dictionary) -> bool:
	if not await qa._open_menu25h(row): return false
	if row.role=="pawn" and not await qa._room_picture25h("01_pawn_keeper_real_menu"): return false
	shop_room_refs=qa.room_refs25h.duplicate();remembered_uv=qa.return_uv25h
	if not await qa._choice25h(0,"shop",row) or not await qa._finish_node25h(): return false
	var limit: int=mini(qa.deadline,Time.get_ticks_msec()+5000)
	while Time.get_ticks_msec()<limit:
		var current: Node=qa.current_scene
		if current is Control and current.get("_shop") is ShopDef:
			return qa.check(String(current.get("_shop").shop_id)==row.shop_id and current.is_visible_in_tree(),"Native keeper menu opened exact actual ShopUI, not direct go_shop")
		await qa.process_frame
	return qa.check(false,"ShopUI did not naturally arrive in finite5s")
func close_actual_shop_same_room(qa: Variant,row: Dictionary) -> bool:
	var shop: Control=qa.current_scene as Control
	var close: TextureButton=shop.get("close_btn") as TextureButton if shop!=null else null
	if not qa.check(close!=null and close.is_visible_in_tree() and not close.disabled,"Actual ShopUI CloseBtn before real pointer click"): return false
	var click: Dictionary=await qa.driver.pointer(close.get_global_rect().get_center())
	if not await qa._arrive(StringName(row.room_id),20000,"25H_EXISTING_SHOP_CLOSE_REBUILDS_ROOM_NOT_WARM_OWNER_CREDIT"): return false
	var state: Dictionary=qa._room_session25h()
	var size: Vector2=qa.field.get("_world_size")
	var expected: Vector2=Vector2(remembered_uv.x*size.x,remembered_uv.y*size.y)
	if not qa.check(state.get("finalized")==true and qa.scene.resource_path==row.scene_path and qa.scene.map_layout.resource_path==row.layout_path and qa._player().position.distance_to(expected)<=.3 and qa._clear(qa._player().position),"Existing Router legitimate shop return: same room/source and pre-Shop remembered foot, new owner allowed"): return false
	qa.records.append({"kind":"25H_REAL_SHOP_CLOSE_ALLOWED_REBUILT_ROOM","room":row.room_id,"pointer":click,"return_uv_captured_before_shop":remembered_uv,"expected_from_prior_uv":expected,"actual":qa._player().position,"Field_preserved":qa.field==shop_room_refs[0].get_ref(),"owner_preservation_required":false,"production_Router_or_ShopUI_changed":false})
	return true
func enter_inn_and_assert_actor(qa: Variant,fixture: Dictionary) -> bool:
	inn_row=fixture.inn
	return await qa._room25h(inn_row)
func open_service_to_confirmation(qa: Variant,service: String) -> bool:
	var native: String="meal" if service=="meal" else "rest"
	if not await qa._open_menu25h(inn_row) or not await qa._choice25h(0 if native=="meal" else 1,native+"_confirm",inn_row): return false
	last_dialog=qa.dialog_id25h;last_helper=qa.service25h
	if not qa.check(qa._node().text.contains("5金" if native=="meal" else "20金") and qa._node().text.contains("全队已满则不收费"),"Actual visible confirmation discloses exact fee/effect/full-party rule"): return false
	if native=="rest" and not rest_picture:
		if not await qa._room_picture25h("02_inn_keeper_actual_rest_price_confirmation"): return false
		rest_picture=true
	return true
func decide_confirmation(qa: Variant,service: String,decision: String) -> bool:
	var native: String="meal" if service=="meal" else "rest"
	var target: String=native+"_commit" if decision=="confirm" else "leave"
	if not await qa._choice25h(0 if decision=="confirm" else 1,target,inn_row) or not await qa._finish_node25h(): return false
	var state: Dictionary=qa.service25h.call("debug_state");var result: Dictionary=state.get("last_result",{})
	if not qa.check(qa._same_room_owner25h() and state.get("active")==false and result.get("matched")==true and qa._player().can_move,"Local service naturally completed exactly once on same live owner and restored movement"): return false
	var feedback: String=String(result.get("feedback",""));var visible: bool=feedback.is_empty()
	var layer: CanvasLayer=qa.field.get("_hud_canvas_layer") as CanvasLayer
	if layer!=null:
		for child: Node in layer.get_children():
			if child is Label and child.text==feedback and child.is_visible_in_tree(): visible=true
	if not qa.check(visible,"Native Field displays actual service feedback, not only helper return value"): return false
	var hud: Node=qa.field.get("_primary_hud")
	var hero: CharacterStats=qa.root.get_node("GameState").get("player")
	var hp: Label=hud.get("_hp_text") as Label if hud!=null else null
	var mp: Label=hud.get("_mp_text") as Label if hud!=null else null
	if not qa.check(hp!=null and mp!=null and hp.is_visible_in_tree() and mp.is_visible_in_tree() and hp.text=="%d / %d"%[hero.hp,hero.max_hp] and mp.text=="%d / %d"%[hero.mp,hero.max_mp],"Actual HUD HP/MP reflects current committed or unchanged resources"): return false
	qa.records.append({"kind":"25H_NATIVE_SERVICE_CONFIRMATION_COMPLETION","service":native,"decision":decision,"dialog_id":last_dialog,"last_result":result,"feedback_visible":visible,"HUD_hp":hp.text,"HUD_mp":mp.text,"same_live_owner":true})
	return true
func real_open_service_and_decide(qa: Variant,service: String,decision: String) -> bool:
	if not await open_service_to_confirmation(qa,service): return false
	return await decide_confirmation(qa,service,decision)
func assert_same_confirmation_replay_no_side_effect(qa: Variant,service: String) -> bool:
	var before: Dictionary=ORACLE.snapshot(qa.root.get_node("GameState"))
	var result: Dictionary=last_helper.call("finish",StringName(last_dialog))
	qa.records.append({"kind":"25H_PUBLIC_FINISH_REPLAY_NEGATIVE_ONLY_NOT_UI","service":service,"old_dialog_id":last_dialog,"result":result})
	return qa.check(result.get("matched",false)==false and not result.get("committed",false) and ORACLE.snapshot(qa.root.get_node("GameState"))==before,"Consumed exact dialog request cannot charge or heal again")
func assert_owner_change_invalidates_unconsumed_confirmation(qa: Variant,fixture: Dictionary) -> bool:
	if not await open_service_to_confirmation(qa,"lodging"): return false
	var old_refs: Array=qa.room_refs25h.duplicate();var old: RefCounted=qa.service25h;var old_id: String=last_dialog
	var before: Dictionary=ORACLE.snapshot(qa.root.get_node("GameState"));var target: Dictionary=fixture.owner_change_target
	if not qa.check(qa.root.get_node("SceneRouter").call("go_field_smart",StringName(target.room_id),qa._v(target.approach_uv)),"Root-authorized final different-room QA setup solely for real lifecycle negative") or not await qa._arrive(StringName(target.room_id),20000,"25H_OWNER_CHANGE_NEGATIVE_NO_OLD_ROUTE_REPLAY"): return false
	var current_helper: RefCounted=qa.field.get("_indoor_services") as RefCounted
	if not qa.check(qa.field!=old_refs[0].get_ref() and qa.scene!=old_refs[2].get_ref() and qa.scene.scene_id!=StringName(inn_row.room_id) and current_helper!=old,"Actual different Field/Scene/helper owner established before stale negative"): return false
	var result: Dictionary=old.call("finish",StringName(old_id))
	qa.records.append({"kind":"25H_REAL_OWNER_CHANGE_PUBLIC_OLD_FINISH_NEGATIVE","from_room":inn_row.room_id,"to_room":target.room_id,"old_dialog_id":old_id,"result":result,"new_Field":qa._id(qa.field),"new_Scene":qa._id(qa.scene),"direct_finish_is_negative_not_positive_interaction_credit":true})
	return qa.check(not result.get("committed",false) and (not result.get("matched",false) or not result.get("ok",false)) and ORACLE.snapshot(qa.root.get_node("GameState"))==before,"Unconsumed old-owner confirmation cannot debit or restore after real owner loss")
