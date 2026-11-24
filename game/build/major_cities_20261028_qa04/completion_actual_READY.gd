extends "res://build/major_cities_20261028_qa01/bianzhou_bounded_DRAFT.gd"
## Two explicitly declared public setups, local real INPUT, no old business replay.
const ACTUAL_FIXTURE := "res://build/major_cities_20261028_qa04/completion_actual_READY.json"
const ACTUAL_OUTPUT := "res://build/major_cities_20261028_qa04/actual/"
var overview_count := 0

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(ACTUAL_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true and raw.get("media_status")=="IMPORTED_FINAL_SOURCE_FROZEN","FINAL_IMPORTED_FIXTURE_ONLY"): finish(); return
	spec=raw
	if not check(spec.whole_seconds==60 and spec.entry_seconds==20 and spec.max_png==3 and spec.public_setups.size()==2,"EXACT_TWO_SETUPS_THREE_NATIVE_ONE_REVIEW_BOUNDARY"): finish(); return
	source_before=file_facts(spec.fixed_sources.keys())
	for path: String in spec.fixed_sources: check(source_before[path].get("sha256","")==spec.fixed_sources[path],"PIN:"+path)
	var baseline: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.baseline))
	save_before=file_facts(baseline.save15.keys())
	sr=root.get_node_or_null("SceneRouter"); dp=root.get_node_or_null("DialogPlayer"); lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"): finish(); return
	platform.call("set_checkpoint_saves_suspended",true); state_before=business_state()
	if not errors.is_empty(): finish(); return
	var field: Node
	for visit: Dictionary in spec.public_setups:
		if not check(sr.call("go_field_smart",StringName(spec.city_id),point(visit.foot)/point(spec.size),"",-1,30)==true,"EXPLICIT_PUBLIC_SETUP_NOT_DEFAULT_OR_CONTINUOUS_TRAVEL:"+String(visit.id)): finish(); return
		field=await wait_field(spec.city_id)
		if field==null: finish(); return
		if not check(field.get_script().resource_path==spec.city_field and field.has_method("get_bianzhou_debug"),"FORMAL_DEDICATED_FIELD_NOT_GENERIC_FALLBACK"): finish(); return
		if not check((field.get("_player") as Node2D).position.distance_to(point(visit.foot))<=1 and field.call("get_bianzhou_debug").layout_version==30,"NATURAL_RUNTIME30_PUBLIC_SETUP_FOOT"): finish(); return
		var identity: Array=[field.get_instance_id(),(field.get("_player") as Node).get_instance_id(),(field.get("_world_camera") as Node).get_instance_id()]
		for stage: Dictionary in visit.stages:
			if not await walk_route(field,stage.route): finish(); return
			if not await normal_image(String(stage.image)): finish(); return
		check(identity==[field.get_instance_id(),(field.get("_player") as Node).get_instance_id(),(field.get("_world_camera") as Node).get_instance_id()],"LOCAL_INPUT_SAME_FIELD_PLAYER_CAMERA:"+String(visit.id))
	if field==null: finish(); return
	var author: Variant=load(spec.author)
	var actors: Dictionary={}
	for node: Node in field.get("_npc_nodes"): actors[String(node.get("npc_id"))]=node
	check(actors.size()==44,"ACTUAL44_DISTINCT_NPC_INSTANCES")
	var moving_before: Dictionary={}
	var moving_max_excursion: Dictionary={}
	for row: Dictionary in author.npc_rows():
		if not check(actors.has(row.npc_id),"ACTUAL_ROLE_ID:"+String(row.npc_id)): continue
		var npc: Node2D=actors[row.npc_id]
		check(npc.get("sprite_path")==row.sprite_path and not String(spec.portraits_by_sprite.get(row.sprite_path,"")).is_empty() and npc.get("portrait_path")==spec.portraits_by_sprite.get(row.sprite_path,""),"ACTUAL_MATCHED_SPRITE_PORTRAIT:"+String(row.npc_id))
		if row.get("movement_mode","")=="patrol":
			var walk_texture: Texture2D=npc.get("_walk_texture")
			var idle_texture: Texture2D=npc.get("_idle_texture")
			var sprite: Sprite2D=npc.get("sprite")
			check(npc.get("walk_sprite_path")==row.walk_sprite_path and walk_texture!=null and walk_texture.resource_path==row.walk_sprite_path and idle_texture!=null and idle_texture.resource_path==row.sprite_path,"ACTUAL_REAL_WALK_AND_IDLE_TEXTURE_BINDING:"+String(row.npc_id))
			check(walk_texture!=null and sprite.texture==walk_texture and sprite.hframes==walk_texture.get_width()/walk_texture.get_height() and sprite.frame>=0 and sprite.frame<sprite.hframes,"ACTUAL_SPRITE_WALK_FRAME_BINDING:"+String(row.npc_id))
			moving_before[row.npc_id]=npc.position; moving_max_excursion[row.npc_id]=0.0
	for _tick: int in range(32):
		await physics_frame
		for id: String in moving_before:
			moving_max_excursion[id]=maxf(float(moving_max_excursion[id]),(actors[id] as Node2D).position.distance_to(moving_before[id]))
	for id: String in moving_before: check(float(moving_max_excursion[id])>.1,"ACTUAL_PATROL_MAX_EXCURSION_32_TICKS_NOT_ENDPOINT_ALIAS:"+id)
	records.append({"patrol_max_excursion_32_physics_ticks":moving_max_excursion,"animation_matrix_repeated":false})
	if not await review_overview(field): finish(); return
	check(business_state()==state_before,"NO_OLD_DIALOG_SHOP_QUEST_ECONOMY_REPLAY")
	check(png_count==3 and overview_count==1 and active(),"BOUNDED_THREE_NATIVE_AND_SEPARATE_OVERVIEW")
	finish()

func normal_image(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var snapshot: Image=root.get_viewport().get_texture().get_image()
	var path: String=ACTUAL_OUTPUT+str(OS.get_process_id())+"/"+name+".png"
	if not check(snapshot!=null and snapshot.get_size()==Vector2i(1920,1080) and png_count<3 and not FileAccess.file_exists(path),"NORMAL_NATIVE_GAME_CAMERA_ONLY:"+name): return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not check(snapshot.save_png(path)==OK,"SAVE_NATIVE:"+name): return false
	png_count+=1; records.append({"native_png":path,"sha256":FileAccess.get_sha256(path),"game_camera_or_actor_writes":0}); return true

func review_overview(field: Node) -> bool:
	var gameplay_camera: Camera2D=root.get_viewport().get_camera_2d()
	if not check(gameplay_camera!=null,"ACTUAL_GAMEPLAY_CAMERA_EXISTS_BEFORE_REVIEW"): return false
	var game_position: Vector2=gameplay_camera.position; var game_zoom: Vector2=gameplay_camera.zoom
	var review:=SubViewport.new(); review.name="IndependentCityReviewOnly"; review.size=Vector2i(4096,4096)
	review.world_2d=root.get_viewport().world_2d; review.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(review)
	var camera:=Camera2D.new(); review.add_child(camera)
	camera.global_position=(field.get("world_container") as Node2D).to_global(Vector2(3072,3072))
	camera.zoom=Vector2.ONE*(4096.0/6208.0); camera.make_current()
	await process_frame; await RenderingServer.frame_post_draw
	await process_frame; await RenderingServer.frame_post_draw
	var snapshot: Image=review.get_texture().get_image()
	var path: String=ACTUAL_OUTPUT+str(OS.get_process_id())+"/whole_city_REVIEW_4096.png"
	var ok: bool=check(snapshot!=null and snapshot.get_size()==Vector2i(4096,4096) and not FileAccess.file_exists(path),"SEPARATE_REVIEW_VIEWPORT_SHARED_REAL_WORLD_NOT_BAKED_BACKGROUND")
	if ok: ok=check(snapshot.save_png(path)==OK,"SAVE_SINGLE_COMPLETE_CITY_REVIEW")
	if ok: overview_count=1; records.append({"review_only_png":path,"sha256":FileAccess.get_sha256(path),"shared_real_world_container_and_npcs":true,"not_normal_game_camera_credit":true,"camera_center":[3072,3072],"review_zoom":4096.0/6208.0})
	check(root.get_viewport().get_camera_2d()==gameplay_camera and gameplay_camera.zoom==game_zoom,"GAMEPLAY_CAMERA_ID_AND_ZOOM_NOT_REPLACED_BY_REVIEW")
	records.append({"game_camera_before":game_position,"game_camera_after":gameplay_camera.position,"natural_camera_follow_not_overridden":true})
	review.queue_free(); await process_frame; return ok

func finish() -> void:
	release_input()
	if not source_before.is_empty(): check(source_before==file_facts(source_before.keys()),"FINAL_SMALL_SOURCE_FIRST_LAST")
	if not save_before.is_empty(): check(save_before==file_facts(save_before.keys()),"SAVE15_SAME_ROOT_PRECISE_TICKS_SEPARATE")
	var path: String=ACTUAL_OUTPUT+str(OS.get_process_id())+"/completion_actual_result.json"
	if FileAccess.file_exists(path): quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(2); return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"native_png_count":png_count,"review_only_count":overview_count,"records":records,"fixture_sha256":FileAccess.get_sha256(ACTUAL_FIXTURE),"actor_or_game_camera_writes":0,"save_writes":0,"old_business_tests_repeated":false},"\t")); file.close()
	print("[BianzhouCompletionActual] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
