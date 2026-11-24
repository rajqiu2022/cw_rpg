extends "res://build/town_layout_20261029r_qa/sects05.gd"
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var reg:Variant=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	check("updated native source contract",reg.source_valid())
	for id in ["ch2_s4_lingyue_gate","ch7_s1_lieyun_valley_ferry","ch7_s2_mingwu_tea_town"]:
		sr.call("go_field_smart",StringName(id));var f:=await wait_field(id)
		if not check(id+" arrow residual field",f!=null):finish(false);return
		await close_dialog();var t:Node=f.get("native_town");var r:Dictionary=reg.town(id)
		place(t,r.inner_arrival);await settle()
		var zone:Node2D
		for z in f.get("_exit_nodes"):
			if z.position.distance_to(r.inner_arrival)<1:zone=z
		if not check(id+" physical doorway retained",zone!=null):finish(false);return
		var expected:Vector2=r.inner_arrival-Vector2(0,t.terrain.elevation(2)+40)
		await create_timer(0.3).timeout
		check(id+" animated arrow tracks projected highland",zone.marker_visual.global_position.distance_to(expected)<=5.1)
		await shot(id+"_arrow06")
	finish(true)
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var file:=FileAccess.open("res://build/town_layout_20261029r_qa/sects06.json",FileAccess.WRITE);file.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));file.close();quit(0 if ok else 1)
