extends "res://build/town_layout_20261029r_qa/formal05.gd"
const DIR:="res://build/four_settlements_20261030e_qa/"
func shot(name:String)->void:
	await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(DIR+name+".png")
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(DIR+"formal01.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var flags:Dictionary=root.get_node("GameState").get("flags");flags["seen_ch6_return_intro"]=true;flags["entered_zhuwei_village"]=true;flags["seen_ch2_zhuwei_intro"]=true
	var reg:Variant=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	if not check("all pinned native sources",reg.source_valid()):finish(false);return
	check("original world additions unchanged",reg.portal_rows().size()==3)
	for id in reg.SETTLEMENTS.IDS:
		check(String(id)+" request accepted",sr.go_field_smart(id))
		var f:=await wait_field(id)
		if not check(String(id)+" formal load",f!=null):finish(false);return
		var t:Node=f.get("native_town");var original:Resource=load("res://data/scenes/"+String(id)+".tres")
		check(String(id)+" native scene",t.scene_file_path==reg.town(id).scene)
		check(String(id)+" story NPC rows retained",f.get("npc_rows").size()==original.npcs.size())
		check(String(id)+" original portal rows",f.get("portal_rows").size()==original.map_layout.portals.size())
		check(String(id)+" arrival",t.actor.position.distance_to(reg.town(id).arrival)<1)
		check(String(id)+" actor clear",reg.actor_shape_clear(t.actor))
		var before:Vector2=t.actor.position;await key(KEY_A,9);check(String(id)+" actual movement",before.distance_to(t.actor.position)>30)
		var mm:Node=f.get("_world_travel_minimap");check(String(id)+" local thumbnail",is_instance_valid(mm))
		if is_instance_valid(mm):
			for i in range(3):await process_frame
			check(String(id)+" native thumbnail capture",mm.get_debug_state().get("visual_cache_ready",false))
		await shot(String(id)+"_formal01")
	finish(true)
