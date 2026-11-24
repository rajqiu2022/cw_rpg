extends "res://build/luoyang_city_revision_20261025h_qa01/common_ui01_NOTREADY.gd"
const READY25H=false
const FIXTURE25H="PENDING_SOURCE25H_FOUR_ROOM_FIXTURE"
const FIXTURE_SHA25H="PENDING_SOURCE25H_FOUR_ROOM_FIXTURE_SHA"
const ADAPTER25H=preload("res://build/luoyang_city_revision_20261025h_qa01/ui_adapter01_NOTREADY.gd")
var adapter25h: RefCounted
var completed25h: Array=[]
func precheck() -> bool:
	if not check(READY25H and track(FIXTURE25H,FIXTURE_SHA25H),"Hardfalse until independent final Source room/actor/body expectation and Root deployment"): return false
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE25H))
	if not check(raw is Dictionary and raw.get("ready")==true and raw.get("formal_deployed")==true,"Final25h source-derived room fixture"): return false
	fixture=raw
	if not check(fixture.whole_ms==60000 and fixture.entry_ms==20000 and fixture.max_pictures==1 and fixture.rooms.size()==4,"Fixed four NPC/three ShopUI/one inn service menu,60/20/one pawn image"): return false
	for path: String in fixture.source_sha256:
		if not track(path,fixture.source_sha256[path]): return false
	adapter25h=ADAPTER25H.new()
	return check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and root.get_visible_rect().size==Vector2(1920,1080) and OS.get_cmdline_user_args().is_empty(),"Original native GUI/real INPUT, no candidate flags")
func exercise_cpu() -> bool:
	for row: Dictionary in fixture.rooms:
		if not await adapter25h.enter_and_assert_source_actor(self,row): return false
		if row.role=="inn":
			if not await adapter25h.open_inn_menu_and_decline(self,row): return false
		else:
			if not await adapter25h.real_interact_then_select_shop(self,row): return false
			var actual: Control=current_scene as Control
			var shop: ShopDef=actual.get("_shop") as ShopDef if actual!=null else null
			if not check(shop!=null and String(shop.shop_id)==row.shop_id and actual.is_visible_in_tree(),"Actual source-specific ShopUI from native keeper "+row.npc_id): return false
			if not await adapter25h.close_actual_shop_same_room(self,row): return false
		completed25h.append({"room":row.room_id,"npc":row.npc_id,"role":row.role,"shop_id":row.shop_id})
	return check(completed25h.size()==4 and pictures==1 and _gameplay()==gameplay,"Four actor interactions/three true ShopUIs/one inn local menu; no purchase or gameplay effect")
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+60000
	output="res://build/luoyang_city_revision_20261025h_qa01/shops02_output/%d_%d"%[OS.get_process_id(),began]
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self);gameplay=_gameplay()
		complete=await exercise_cpu()
	if driver!=null: driver.release();driver=null
	records.append({"kind":"25H_FOUR_SERVICE_NPCS_THREE_SHOPS_ONE_INN_MENU_ONLY","completed":completed25h,"explicit_QA_room_setups":completed25h.size(),"Player_private_position_writes":0,"NPC_event_or_DP_play_shortcuts":0,"collector_calls":0,"old25g_replay":0,"source_geometry_recompiled":0})
	finish(output,began,complete,"25H_SHOPS02_HARDFALSE_SOURCE_FINAL_PENDING")
