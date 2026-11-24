extends "res://build/four_settlements_20261030e_qa/formal01.gd"
func settle()->void:
	for i in range(6):await physics_frame
func close_dialog()->void:
	if root.get_node("DialogPlayer").is_playing():root.get_node("DialogPlayer").call("_end_dialog")
	await settle()
func place(f:Node,p:Vector2)->void:
	var t:Node=f.get("native_town");t.actor.position=p;t.terrain.reset_actor(t.terrain.level_at(p));t.update_view()
func pair(outdoor:String,indoor:String)->bool:
	sr.go_field_smart(StringName(outdoor));var f:=await wait_field(outdoor)
	if not check(indoor+" outside ready",f!=null):return false
	await close_dialog();var reg:Variant=load("res://build/four_settlements_20261030e_system01/locations.gd");var p:Array=reg.town(outdoor).returns[indoor];var foot:=Vector2(p[0],p[1])
	place(f,foot);await settle();await key(KEY_SPACE);f=await wait_field(indoor)
	if not check(indoor+" real Space entry",f!=null):return false
	await close_dialog();var back:Node2D
	for z in f.get("_exit_nodes"):
		if String(z.target_scene_id)==outdoor:back=z;break
	if not check(indoor+" original return door",is_instance_valid(back)):return false
	var actor:Node2D=f.get("_player");actor.position=back.position-Vector2(0,float(actor.call("_visual_foot_offset")));await settle();await key(KEY_SPACE);f=await wait_field(outdoor)
	if not check(indoor+" real Space return",f!=null):return false
	var t:Node=f.get("native_town");check(indoor+" return at same new arrow",t.actor.position.distance_to(foot)<1)
	check(indoor+" return floor",t.terrain.actor_level==t.terrain.level_at(foot))
	await key(KEY_S,8);check(indoor+" can leave returned foot",t.actor.position.y>foot.y+25)
	await shot(indoor+"_return02");return true
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(DIR+"business02.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var flags:Dictionary=root.get_node("GameState").get("flags");flags["seen_ch6_return_intro"]=true;flags["entered_zhuwei_village"]=true;flags["seen_ch2_zhuwei_intro"]=true
	for id in ["openworld_bailu_ferry","openworld_east_sea_port"]:
		sr.go_field_smart(StringName(id));var f:=await wait_field(id)
		if not check(id+" ferry field",f!=null):finish(false);return
		await close_dialog();var npc:Node2D=f.get("_npc_nodes")[0];place(f,npc.position+Vector2(-65,20));await settle();await key(KEY_SPACE);await settle()
		check(id+" original ferry dialog",root.get_node("DialogPlayer").is_playing());await shot(id+"_ferry02");await close_dialog()
	for r in [["linxi_village_center","linxi_farmer_cottage"],["linxi_village_center","linxi_scholar_house"],["linxi_village_center","linxi_herbal_home"],["ch1_s2_qingfeng","interior_inn_hall"],["ch2_s1_zhuwei_market","ch2_s1_market_training_hall"]]:
		if not await pair(r[0],r[1]):finish(false);return
	finish(true)
