extends "res://build/linxi_entry_repair_20261029q/probe01.gd"
var checks:Array=[]
func check(name:String,ok:bool)->bool:
	checks.append({"name":name,"ok":ok});print(name,": ",ok);return ok
func shot(name:String)->void:
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/town_layout_20261029r_qa/"+name+".png")
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	check("native_contract",load("res://build/three_towns_world_20261029j_system01/town_registry.gd").source_valid())
	sr.call("go_field_smart",&"openworld_desert_city",Vector2(2560,3990)/Vector2(8520,5780))
	var f:=await wait_field("openworld_desert_city")
	if not check("desert_actual_loaded",f!=null):finish(false);return
	var t:Node=f.get("native_town")
	await key(KEY_W,35)
	check("actual_opaque_gate_ghost_actor",t.get_node("Town/WallFront/Art").material.get_shader_parameter("fade_enabled")==0.0 and t.ghost.overlay.visible)
	await shot("desert_gate_formal05")
	sr.call("go_field_smart",&"openworld_redrock_town",Vector2(3700,2100)/Vector2(7200,6400))
	f=await wait_field("openworld_redrock_town")
	if not check("redrock_actual_loaded",f!=null):finish(false);return
	t=f.get("native_town");await key(KEY_W,100)
	check("actual_stair_reaches_highland",t.terrain.actor_level==1 and t.terrain.actor_height==240.0)
	await shot("redrock_highland_formal05")
	sr.call("go_field_smart",&"openworld_redrock_town",Vector2(1700,1545)/Vector2(7200,6400))
	f=await wait_field("openworld_redrock_town")
	if not check("saved_highland_loaded",f!=null):finish(false);return
	t=f.get("native_town");check("saved_highland_level",t.terrain.actor_level==1)
	await key(KEY_SPACE)
	check("highland_home_enter",t.in_hall and t.active_room=="home")
	await key(KEY_SPACE)
	check("highland_home_return",not t.in_hall and t.actor.global_position.distance_to(Vector2(1700,1545))<1 and t.terrain.actor_level==1)
	await shot("redrock_home_return05")
	finish(true)
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open("res://build/town_layout_20261029r_qa/formal05.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
