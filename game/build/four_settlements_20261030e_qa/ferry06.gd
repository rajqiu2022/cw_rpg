extends "res://build/four_settlements_20261030e_qa/business02.gd"
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(DIR+"ferry06.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var dp:Node=root.get_node("DialogPlayer")
	for route in [["openworld_bailu_ferry","openworld_east_sea_port"],["openworld_east_sea_port","openworld_bailu_ferry"]]:
		sr.go_field_smart(StringName(route[0]));var f:=await wait_field(route[0]);await close_dialog()
		if not check(route[0]+" ready",f!=null):finish(false);return
		var npc:Node2D=f.get("_npc_nodes")[0];place(f,npc.position+Vector2(-65,20));await settle();await key(KEY_SPACE)
		for i in range(12):
			await settle();var node:Resource=dp.get("_current_node")
			if node!=null and node.has_choices():break
			await key(KEY_SPACE)
		var node:Resource=dp.get("_current_node")
		if not check(route[0]+" original choice shown",node!=null and node.has_choices()):finish(false);return
		await shot(route[0]+"_choices06");await key(KEY_1);f=await wait_field(route[1])
		if not check(route[1]+" actual choice travel",f!=null):finish(false);return
		var reg:Variant=load("res://build/four_settlements_20261030e_system01/locations.gd");var a:Array=reg.town(route[1]).returns[route[0]]
		check(route[1]+" ferry landing",f.get("_player").position.distance_to(Vector2(a[0],a[1]))<1)
		check(route[1]+" ferry landing clear",load("res://build/three_towns_world_20261029j_system01/town_registry.gd").actor_shape_clear(f.get("_player")))
		await key(KEY_A,8);await shot(route[1]+"_landing06")
	finish(true)
