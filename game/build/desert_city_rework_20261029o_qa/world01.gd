extends "res://build/three_towns_world_20261029j_qa01/trips_READY.gd"
const OWN := "res://build/desert_city_rework_20261029o_qa/"
func _run() -> void:
	began=Time.get_ticks_msec()
	spec=JSON.parse_string(FileAccess.get_file_as_string(OWN+"fixture01.json"))
	source_before=file_facts(spec.fixed_sources.keys());save_before=file_facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:need(source_before[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path)
	sr=root.get_node("SceneRouter");gs=root.get_node("GameState");lm=root.get_node("LoadingManager");dp=root.get_node("DialogPlayer")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"CHECKPOINT_SAVES_SUSPENDED")
	state_before=live_state()
	need(load(String(spec.overlay_script)).call("source_valid"),"UPDATED_NATIVE_SOURCE_MANIFEST_VALID")
	if not errors.is_empty():finish();return
	for leg: Dictionary in spec.legs:
		if not need(sr.call("go_field_smart",StringName(leg.world_id),point(leg.world_setup_foot)/point(spec.world_size),"",15,-1),"WORLD_SETUP:"+leg.id):finish();return
		var world: Node=await wait_world(String(leg.world_id))
		if world==null:finish();return
		for i in range(4):await physics_frame
		var group: Node=world.get_node_or_null("WorldContainer/ThreeTownWorldAdditions/"+String(leg.id))
		if not need(group!=null,"LIVE_NEW_WORLD_GROUP:"+leg.id):finish();return
		var sprites: Array=[]
		for child in group.get_children():
			if child is Sprite2D:sprites.append(child)
		if not need(sprites.size()==1 and sprites[0].texture.resource_path==String(leg.new_landmark) and sprites[0].scale==Vector2(.46,.46),"ONE_NATIVE_WHOLE_TOWN_COMPOUND:"+leg.id):finish();return
		var original: Resource=world.get("_current_scene")
		need(original.map_layout.portals.size()==16,"ORIGINAL_16_WORLD_PORTALS_UNCHANGED")
		var zones: Array=[]
		for zone in world.get("_exit_nodes"):
			if zone.target_scene_id==String(leg.id):zones.append(zone)
		if not need(zones.size()==1 and zones[0].call("can_enter"),"NEW_LANDMARK_ACTUAL_DOOR_AND_BODY_CLEAR:"+leg.id):finish();return
		if not await capture(String(leg.screenshot_name)+"_world"):finish();return
		await key(KEY_SPACE)
		var wrapper: Node=await wait_town(leg)
		if wrapper==null:finish();return
		var town: Node=wrapper.get_node(String(leg.town_node))
		need(town.actor.global_position.distance_to(point(leg.arrival_foot))<=1,"SAME_NATIVE_ARRIVAL:"+leg.id)
		var texture: Texture2D=town.get_node(String(leg.replacement_node)).texture
		need(texture.resource_path==String(leg.replacement_texture),"FORMAL_SCENE_USES_NEW_NATIVE_MODULE:"+leg.id)
		if not await capture(String(leg.screenshot_name)+"_town"):finish();return
		if not need(wrapper.get("town_exit").call("can_enter"),"FORMAL_EXIT_CLEAR:"+leg.id):finish();return
		await key(KEY_SPACE);world=await wait_world(String(leg.world_id))
		if world==null:finish();return
		need(world.get("_player").position.distance_to(point(leg.world_setup_foot))<=1,"UNCHANGED_WORLD_RETURN_FOOT:"+leg.id)
		need(live_state()==state_before,"SAME_LIVE_SESSION:"+leg.id)
		if not errors.is_empty():finish();return
	finish()
func capture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var im:=root.get_texture().get_image();var path:=OWN+"actual/"+str(OS.get_process_id())+"/"+name+".png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(im.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"NATIVE_NORMAL_CAPTURE:"+name):return false
	if not need(im.save_png(path)==OK,"SAVED:"+name):return false
	png_count+=1;records.append({"image":path,"sha256":FileAccess.get_sha256(path)});return true
func finish() -> void:
	release_input()
	if not source_before.is_empty():need(source_before==file_facts(source_before.keys()),"SOURCE_FIRST_FINAL")
	if not save_before.is_empty():need(save_before==file_facts(save_before.keys()),"SAVE_FIRST_FINAL_HASH_BYTES_SECONDS")
	var path:=OWN+"actual/"+str(OS.get_process_id())+"/result.json"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir());var f:=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"errors":errors,"input_ticks":input_ticks,"images":records,"elapsed_ms":Time.get_ticks_msec()-began,"fixture_sha256":FileAccess.get_sha256(OWN+"fixture01.json"),"qa_actor_or_camera_writes":0,"save_writes":0},"\t"));f.close()
	print("DESERT_NATIVE_WORLD ",checks," / ",errors.size()," : ",path);quit(0 if errors.is_empty() else 1)
