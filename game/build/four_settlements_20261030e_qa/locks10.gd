extends "res://build/four_settlements_20261030e_qa/business02.gd"
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(DIR+"locks10.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var flags:Dictionary=root.get_node("GameState").get("flags");flags["seen_ch6_return_intro"]=true;flags["entered_zhuwei_village"]=true
	for route in [["ch1_s2_qingfeng","ch1_s3_zhuwei_forest","zhuwei_village_inquiry_done"]]:
		flags[route[2]]=false;sr.go_field_smart(StringName(route[0]));var f:=await wait_field(route[0]);await close_dialog()
		if not check(route[0]+" locked field ready",f!=null):finish(false);return
		var out:Node2D
		for z in f.get("_exit_nodes"):
			if z.is_locked and z.destination_name.contains("后山密林"):out=z;break
		if not check(route[0]+" locked arrow retained",is_instance_valid(out)):finish(false);return
		place(f,out.position);await settle();await key(KEY_SPACE);await settle()
		check(route[0]+" real Space cannot bypass quest lock",sr.get("_current_field_id")==StringName(route[0]) and not lm.get("_transition_active"))
		await close_dialog();root.get_node("GameState").set_flag(StringName(route[2]),true);f.call("rebuild_business");await settle();await key(KEY_SPACE);f=await wait_field(route[1])
		if not check(route[1]+" flag unlock allows actual travel",f!=null):finish(false);return
		await close_dialog();sr.go_field_smart(StringName(route[0]));f=await wait_field(route[0])
		if not check(route[0]+" native reentry after original route",f!=null):finish(false);return
	var id:=&"linxi_village_center";sr.go_field_smart(id,Vector2(.835,.60),"",-1,1);var f:=await wait_field(String(id))
	if not check("legacy layout reload",f!=null):finish(false);return
	var reg:Variant=load("res://build/four_settlements_20261030e_system01/locations.gd")
	check("legacy foot migrates to authored arrival",f.get("_player").position.distance_to(reg.town(id).arrival)<1)
	var retained:=Vector2(600,2300);sr.go_field_smart(id,retained/reg.town(id).size,"",-1,3001);f=await wait_field(String(id))
	if not check("current layout reload",f!=null):finish(false);return
	check("current layout foot retained",f.get("_player").position.distance_to(retained)<1)
	await shot("linxi_retained_foot10");finish(true)



