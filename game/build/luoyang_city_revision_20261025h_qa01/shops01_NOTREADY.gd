extends "res://build/luoyang_city_revision_20261024c_qa01/finite_Field_NOTREADY/common.gd"
## Only four room actors and the actual menu->ShopUI route. No buy/sell action.
const READY25H=false
const FIXTURE25H="PENDING_SOURCE25H_INDEPENDENT_ROOM_NPC_FIXTURE"
const FIXTURE_SHA25H="PENDING_SOURCE25H_INDEPENDENT_ROOM_NPC_FIXTURE_SHA"
var adapter25h: RefCounted
var completed25h: Array=[]
func precheck() -> bool:
	if not check(READY25H and track(FIXTURE25H,FIXTURE_SHA25H),"Hardfalse until implementation interface, independent Source maps and formal Root deployment"): return false
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE25H))
	if not check(raw is Dictionary and raw.get("ready")==true and raw.get("formal_deployed")==true,"Final25h fixture only"): return false
	fixture=raw
	if not check(fixture.whole_ms==60000 and fixture.entry_ms==20000 and fixture.max_pictures<=2 and fixture.rooms.size()==4,"Finite4 rooms/60s/20s/at most2 images"): return false
	for path: String in fixture.source_sha256:
		if not track(path,fixture.source_sha256[path]): return false
	return check(false,"HARDFALSE pending final sourcebound local-menu adapter; no guessed private API")
func exercise_cpu() -> bool:
	for row: Dictionary in fixture.rooms:
		# The final adapter may only read actual nodes / drive INPUT. It must not
		# spawn the actor, append scene.npcs, emit an interaction signal, or go_shop.
		if not await adapter25h.call("enter_and_assert_source_actor",self,row): return false
		if not await adapter25h.call("real_interact_then_select_shop",self,row): return false
		var actual: Node=current_scene
		var shop: Variant=actual.get("_shop") if is_instance_valid(actual) else null
		if not check(shop is ShopDef and String(shop.shop_id)==row.shop_id and actual.is_visible_in_tree(),"Actual ShopUI from native NPC interaction has exact source shop "+row.npc_id): return false
		if not await adapter25h.call("close_actual_shop_same_room",self,row): return false
		completed25h.append(row.room_id)
	return check(completed25h.size()==4,"Four actual shopkeeper routes, no direct go_shop test shortcut")
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+60000
	output="res://build/luoyang_city_revision_20261025h_qa01/shops01_output/%d_%d"%[OS.get_process_id(),began]
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self);gameplay=_gameplay()
		complete=await exercise_cpu()
	if driver!=null: driver.release();driver=null
	if complete: complete=check(_gameplay()==gameplay,"No buy/sell, rewards, quests or gold changes")
	records.append({"kind":"25H_FOUR_NATIVE_ROOM_SHOPKEEPERS_ONLY","completed":completed25h,"old25g_material_geometry_routes_replayed":0,"collector_calls":0,"implementation_writes":0})
	finish(output,began,complete,"25H_SHOPS_HARDFALSE_PENDING_FINAL_INTERFACE")
