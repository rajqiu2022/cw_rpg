extends "res://build/lanxi_revision_20261030l/layout07.gd"
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(LOCAL+"restore10.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	check("final source header exact",load("res://build/three_towns_world_20261029j_system01/town_registry.gd").source_valid())
	sr.go_field_smart(&"openworld_lanxi_zhai",Vector2(2660,1220)/Vector2(7600,5200),"",15,1)
	var f:=await wait_field("openworld_lanxi_zhai")
	if not check("formal covered legacy-foot load",f!=null):finish(false);return
	var t:Node=f.get("native_town");await settle()
	check("formal migration to authored doorstep",t.migrated_foot and t.actor.position.distance_to(Vector2(2480,1315))<1)
	check("formal returned floor and clearance",t.terrain.actor_level==1 and t.foot_clear(t.actor.position))
	await key(KEY_S,12);check("formal migrated foot can leave",t.actor.position.y>1365);await shot("formal_home10")
	finish(true)
