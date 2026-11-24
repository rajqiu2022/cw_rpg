extends "res://build/lanxi_revision_20261030l/layout07.gd"
func finish(ok:bool)->void:
	for c in checks:ok=ok and c.ok
	var f:=FileAccess.open(LOCAL+"formal09.json",FileAccess.WRITE);f.store_string(JSON.stringify({"ok":ok,"checks":checks},"\t"));f.close();quit(0 if ok else 1)
func run()->void:
	sr=root.get_node("SceneRouter");lm=root.get_node("LoadingManager");root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	var reg:Variant=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	if not check("166 exact pinned sources",reg.source_valid()):finish(false);return
	check("original World request",sr.go_field_smart(&"world_map_jianghu",Vector2(900,6000)/Vector2(12288,8192),"",15,-1))
	var f:=await wait_field("world_map_jianghu")
	if not check("World loaded",f!=null):finish(false);return
	var gate:Node
	for z in f.get("_exit_nodes"):
		if z.target_scene_id=="openworld_lanxi_zhai":gate=z;break
	if not check("existing Lanxi arrow reachable",is_instance_valid(gate) and gate.can_enter()):finish(false);return
	await key(KEY_SPACE);f=await wait_field("openworld_lanxi_zhai")
	if not check("real World Space entered updated town",f!=null):finish(false);return
	var t:Node=f.get("native_town")
	check("latest controller loaded",t.get_script().resource_path==LOCAL+"controller.gd");check("arrival unchanged",t.actor.position.distance_to(Vector2(1610,3900))<1)
	await key(KEY_W,8);check("arrival can walk",t.actor.position.y<3875)
	var mm:Node=f.get("_world_travel_minimap");await settle();var cache:Dictionary=mm.get_debug_state().visual_cache
	check("real minimap regenerated",cache.ready and cache.texture_paths.has("res://art/modules/miao_recompose_20261029g/rock_bank.png"));check("minimap no actor copies",cache.actor_copies==0)
	place(f,Vector2(1750,1845));await settle();await key(KEY_SPACE);check("original hall enters",t.in_hall);await key(KEY_SPACE);check("hall returns exact foot",not t.in_hall and t.actor.position.distance_to(Vector2(1750,1845))<1)
	place(f,Vector2(6100,4070));await settle();check("shop opaque / hero ghost",t.get_node("Town/RaisedMarket2/Foreground/Shops").material.get_shader_parameter("fade_enabled")==0.0 and t.visibility_ghost.overlay.visible and is_equal_approx(t.visibility_ghost.overlay.modulate.a,.42));await shot("formal_market09")
	place(f,Vector2(2480,2170));await settle();await shot("formal_bank09")
	check("lower resident keeps off bank",t.get_node("Town/WestWeaver").route[-1]==Vector2(1900,2050))
	place(f,Vector2(1610,3900));await settle();await key(KEY_SPACE);f=await wait_field("world_map_jianghu")
	if not check("real Space returned to World",f!=null):finish(false);return
	check("World return at original arrow",f.get("_player").position.distance_to(Vector2(900,6000))<1)
	finish(true)
