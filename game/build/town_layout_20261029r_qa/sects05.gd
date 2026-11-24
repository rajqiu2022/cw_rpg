extends "res://build/town_layout_20261029r_qa/formal05.gd"
func settle()->void:
	for i in range(6):await physics_frame
func close_dialog()->void:
	if root.get_node("DialogPlayer").call("is_playing"):root.get_node("DialogPlayer").call("_end_dialog")
	await settle()
func place(t:Node,p:Vector2)->void:
	t.actor.position=p;t.terrain.reset_actor(t.terrain.level_at(p));t.update_view()
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var reg:Variant=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	for id in ["ch2_s4_lingyue_gate","ch7_s1_lieyun_valley_ferry","ch7_s2_mingwu_tea_town"]:
		sr.call("go_field_smart",StringName(id));var f:=await wait_field(id)
		if not check(id+" business field ready",f!=null):finish(false);return
		var t:Node=f.get("native_town");await close_dialog()
		var p:Vector2=Vector2(2300,2870) if id=="ch2_s4_lingyue_gate" else f.get("_npc_nodes")[0].position+Vector2(0,75)
		place(t,p);await settle();await key(KEY_SPACE);await settle()
		check(id+" original conversation by Space",root.get_node("DialogPlayer").call("is_playing"))
		await close_dialog()
		var r:Dictionary=reg.town(id);place(t,r.inner_arrival);await settle()
		if id!="ch2_s4_lingyue_gate":
			root.get_node("GameState").get("flags")["ch7_outer_routes_opened"]=false;f.rebuild_business();await settle();await key(KEY_SPACE);await settle()
			check(id+" original locked gate retained",current_scene==f and not root.get_node("DialogPlayer").call("is_playing"))
			root.get_node("GameState").get("flags")["ch7_outer_routes_opened"]=true;f.rebuild_business();await settle()
		await shot(id+"_door05");await key(KEY_SPACE)
		f=await wait_field(String(r.inner_source))
		if not check(id+" original inner destination",f!=null):finish(false);return
		await close_dialog()
		var zone:Node2D=f.get("_exit_nodes")[0];var actor:Node2D=f.get("_player")
		actor.position=zone.position-Vector2(0,float(actor.call("_visual_foot_offset")));await settle();await key(KEY_SPACE)
		f=await wait_field(id)
		if not check(id+" actual return",f!=null):finish(false);return
		t=f.get("native_town");check(id+" return beside same arrow",t.actor.position.distance_to(r.inner_arrival)<1 and t.terrain.actor_level==2)
		await shot(id+"_return05")
	finish(true)
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var file:=FileAccess.open("res://build/town_layout_20261029r_qa/sects05.json",FileAccess.WRITE);file.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));file.close();quit(0 if ok else 1)
