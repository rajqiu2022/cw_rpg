extends "res://build/town_layout_20261029r_qa/formal05.gd"
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	sr.call("go_field_smart",&"openworld_redrock_town",Vector2(3700,2100)/Vector2(7200,6400))
	var f:=await wait_field("openworld_redrock_town")
	if not check("redrock_loaded",f!=null):finish(false);return
	var t:Node=f.get("native_town")
	check("requested_foot_preserved",t.actor.global_position.distance_to(Vector2(3700,2100))<1)
	await key(KEY_W,100)
	check("actual_stair_reaches_highland",t.terrain.actor_level==1 and t.terrain.actor_height==240.0)
	await shot("redrock_highland_formal06")
	sr.call("go_field_smart",&"openworld_redrock_town",Vector2(1700,1545)/Vector2(7200,6400))
	f=await wait_field("openworld_redrock_town")
	if not check("saved_highland_loaded",f!=null):finish(false);return
	t=f.get("native_town");check("saved_highland_level",t.terrain.actor_level==1 and t.actor.global_position.distance_to(Vector2(1700,1545))<1)
	await key(KEY_SPACE)
	check("highland_home_enter",t.in_hall and t.active_room=="home" and t.actor.collision_mask==2)
	await shot("redrock_home_inside06")
	await key(KEY_SPACE)
	check("highland_home_return",not t.in_hall and t.actor.global_position.distance_to(Vector2(1700,1545))<1 and t.terrain.actor_level==1 and t.actor.collision_mask==40)
	await shot("redrock_home_return06")
	finish(true)
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var file:=FileAccess.open("res://build/town_layout_20261029r_qa/formal06.json",FileAccess.WRITE);file.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));file.close();quit(0 if ok else 1)
