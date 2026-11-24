extends "res://build/four_settlements_20261030e_qa/business02.gd"
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(DIR+"world04.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var flags:Dictionary=root.get_node("GameState").get("flags");flags["seen_ch6_return_intro"]=true;flags["entered_zhuwei_village"]=true;flags["seen_ch2_zhuwei_intro"]=true
	for id in ["openworld_bailu_ferry","openworld_east_sea_port","linxi_village_scrollmap","ch1_s2_qingfeng"]:
		sr.go_field_smart(StringName(id));var f:=await wait_field(id);await close_dialog()
		if not check(id+" outside ready",f!=null):finish(false);return
		var out:Node2D
		for z in f.get("_exit_nodes"):
			if String(z.target_scene_id)=="world_map_jianghu":out=z;break
		if not check(id+" original World arrow",is_instance_valid(out)):finish(false);return
		place(f,out.position);await settle();await key(KEY_SPACE);f=await wait_field("world_map_jianghu")
		if not check(id+" Space to World",f!=null):finish(false);return
		await close_dialog();var back:Node2D
		for z in f.get("_exit_nodes"):
			if String(z.target_scene_id)==id:back=z;break
		if not check(id+" original World landmark",is_instance_valid(back)):finish(false);return
		var actor:Node2D=f.get("_player");check(id+" World arrival near landmark",actor.position.distance_to(back.position)<120)
		actor.position=back.position-Vector2(0,float(actor.call("_visual_foot_offset")));await settle();await key(KEY_SPACE);f=await wait_field(id)
		if not check(id+" Space back to native",f!=null):finish(false);return
		var reg:Variant=load("res://build/four_settlements_20261030e_system01/locations.gd");check(id+" new arrival near arrow",f.get("_player").position.distance_to(reg.town(id).arrival)<1)
		await shot(id+"_world04")
	finish(true)
