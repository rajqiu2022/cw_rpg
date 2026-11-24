extends "res://build/town_layout_20261029r_qa/formal05.gd"
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var reg:Variant=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	check("native_source_contract",reg.source_valid())
	check("world_additions_still_three",reg.portal_rows().size()==3)
	for id in ["ch2_s4_lingyue_gate","ch7_s1_lieyun_valley_ferry","ch7_s2_mingwu_tea_town"]:
		sr.call("go_field_smart",StringName(id))
		var f:=await wait_field(id)
		if not check(id+" loaded",f!=null):finish(false);return
		var t:Node=f.get("native_town")
		if not check(id+" native outdoor",is_instance_valid(t)):finish(false);return
		check(id+" arrival near return arrow",t.actor.position.distance_to(reg.town(id).arrival)<1)
		check(id+" original exits",f.get("_exit_nodes").size()==2)
		check(id+" original NPCs",f.get("_npc_nodes").size()==(0 if id=="ch2_s4_lingyue_gate" else 1))
		var before:Vector2=t.actor.position;await key(KEY_W,10)
		check(id+" real movement",t.actor.position.distance_to(before)>30)
		await shot(id+"_formal04")
	finish(true)
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var file:=FileAccess.open("res://build/town_layout_20261029r_qa/sects04.json",FileAccess.WRITE);file.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));file.close();quit(0 if ok else 1)
