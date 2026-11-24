extends "res://build/four_settlements_20261030e_qa/business02.gd"
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(DIR+"business03.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var flags:Dictionary=root.get_node("GameState").get("flags");flags["seen_ch6_return_intro"]=true;flags["entered_zhuwei_village"]=true;flags["seen_ch2_zhuwei_intro"]=true
	for r in [["linxi_tutorial","linxi_master_hall"],["linxi_tutorial","linxi_hero_bedroom"],["linxi_village_scrollmap","linxi_south_villager_home"],["linxi_village_scrollmap","linxi_south_scholar_house"],["linxi_village_scrollmap","linxi_south_apothecary_home"],["ch2_s1_zhuwei_market","ch2_s1_market_inn"]]:
		if not await pair(r[0],r[1]):finish(false);return
	# Actual cross-neighbourhood arrow destinations, rather than the old default-spawn oracle.
	for route in [["linxi_tutorial","linxi_village_center"],["linxi_village_center","linxi_village_scrollmap"]]:
		sr.go_field_smart(StringName(route[0]));var f:=await wait_field(route[0]);await close_dialog()
		var out:Node2D
		for z in f.get("_exit_nodes"):
			if String(z.target_scene_id)==route[1]:out=z;break
		place(f,out.position);await settle();await key(KEY_SPACE);f=await wait_field(route[1])
		if not check(route[1]+" actual connecting path",f!=null):finish(false);return
		var incoming:Node2D
		for z in f.get("_exit_nodes"):
			if String(z.target_scene_id)==route[0]:incoming=z;break
		check(route[1]+" return-arrow arrival",f.get("_player").position.distance_to(incoming.position)<1)
	finish(true)
