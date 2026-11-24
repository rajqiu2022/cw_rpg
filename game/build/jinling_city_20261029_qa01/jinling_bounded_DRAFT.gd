extends "res://build/major_cities_20261028_qa01/bianzhou_bounded_DRAFT.gd"
## One new Jinling trip only; Root runs after the author/route/interface freeze.
const J_FIXTURE := "res://build/jinling_city_20261029_qa01/jinling_bounded_READY.json"
const J_OUTPUT := "res://build/jinling_city_20261029_qa01/actual/"
var review_count := 0

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(J_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"FINAL_JINLING_SOURCE_AND_ROUTE_CONTRACT"): finish(); return
	spec=raw
	if not check(spec.whole_seconds<=90 and spec.entry_seconds==20 and spec.max_png==1,"ONE_BOUNDED_JINLING_TRIP_ONE_NATIVE_ONE_REVIEW"): finish(); return
	source_before=file_facts(spec.fixed_sources.keys())
	for path: String in spec.fixed_sources: check(source_before[path].get("sha256","")==spec.fixed_sources[path],"PIN:"+path)
	var baseline: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.baseline))
	if not check(baseline.get("save15",{}).size()==15,"REGISTERED_SAVE15_ONLY"): finish(); return
	save_before=file_facts(baseline.save15.keys())
	sr=root.get_node_or_null("SceneRouter"); dp=root.get_node_or_null("DialogPlayer"); lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"): finish(); return
	platform.call("set_checkpoint_saves_suspended",true)
	check(platform.call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED_UNTIL_QUIT")
	state_before=business_state()
	dp.connect("text_displayed",_on_text); dp.connect("choices_displayed",_on_choices)
	if not errors.is_empty(): finish(); return
	# This explicit World gateway setup is not a default World long-distance trip.
	if not check(sr.call("go_field_smart",StringName(spec.world_id),point(spec.world_setup_foot)/point(spec.world_size),"",15,-1)==true,"PUBLIC_WORLD_GATEWAY_SETUP_NOT_ACTOR_TELEPORT"): finish(); return
	var world: Node=await wait_field(spec.world_id)
	if world==null: finish(); return
	var layout: Resource=(world.get("_current_scene") as Resource).get("map_layout")
	var rows: Array=(layout.get("portals") as Array).filter(func(row: Dictionary) -> bool: return String(row.get("id"))=="jinling")
	if not check(rows.size()==1 and rows[0].get("target_scene")==spec.city_id and rows[0].get("target_pos")==Vector2(.51,.9),"ORIGINAL_WORLD_JINLING_TARGET_051_09"): finish(); return
	var expected_world_anchor: Vector2=rows[0].get("source_spawn_pos",rows[0].get("pos"))
	var zones: Array=[]
	for zone: Node in world.get("_exit_nodes"):
		if String(zone.get("target_scene_id"))==spec.city_id: zones.append(zone)
	for _stable_tick: int in range(3): await physics_frame
	if not check(zones.size()==1 and zones[0].call("can_enter")==true,"REAL_WORLD_GATE_CAN_ENTER_BEFORE_SPACE"): finish(); return
	records.append({"world_anchor_frozen_before_exit":expected_world_anchor,"actual_world_foot":(world.get("_player") as Node2D).position,"default_world_travel_claim":false})
	await key(KEY_SPACE)
	var field: Node=await wait_field(spec.city_id)
	if field==null: finish(); return
	if not check(field.get_script().resource_path==spec.city_field and (field.get("_player") as Node2D).position.distance_to(point(spec.city_arrival_foot))<=1,"ORDINARY_WORLD_PORTAL_NEW_NATIVE_ARRIVAL"): finish(); return
	var debug: Dictionary=field.call("get_jinling_debug")
	check(debug.layout_version==31 and (sr.get("_local_layout_versions") as Dictionary).get(spec.city_id)==31,"NATURAL_LOCAL_VERSION31_NO_VERSION_DICT_WRITE")
	var city_layout: Resource=(field.get("_current_scene") as Resource).get("map_layout")
	var boards: Array=(city_layout.get("interactions") as Array).filter(func(row: Dictionary) -> bool: return String(row.get("action"))=="bounty_board:jinling")
	check(boards.size()==1 and (city_layout.get("portals") as Array).size()==2,"ORIGINAL_UNIQUE_BOARD_TWO_DOORS")
	if not bridge_water_suffix(field): finish(); return
	if not await walk_route(field,spec.route_to_guide): finish(); return
	var static_before: Dictionary=jinling_static(field)
	if not await speak(field,spec.guide,false): finish(); return
	check(not texts.is_empty() and texts[0].speaker==spec.guide.hero_name and texts[0].portrait==spec.guide.hero_portrait and texts[0].text==spec.guide.hero_text,"WATER_PATROL_HERO_FIRST_MATCHING_PORTRAIT")
	check(jinling_static(field)==static_before,"GUIDE_SAFE_DIALOG_NO_TERRAIN_REBUILD")
	if not await walk_route(field,spec.route_to_merchant): finish(); return
	if not verify_npc(field,spec.merchant): finish(); return
	var merchant_foot: Vector2=(field.get("_player") as Node2D).position
	await key(KEY_SPACE)
	var shop_started:=Time.get_ticks_msec()
	while active() and Time.get_ticks_msec()-shop_started<5000:
		await process_frame
		if current_scene!=null and current_scene.scene_file_path=="res://scenes/shop.tscn": break
	if not check(current_scene!=null and current_scene.scene_file_path=="res://scenes/shop.tscn" and String(sr.call("get_shop_payload").get("shop_id"))=="lingyue_pavilion","ORIGINAL_SHOP_UI_OPEN_NO_PURCHASE"): finish(); return
	await process_frame; await key(KEY_ESCAPE)
	field=await wait_field(spec.city_id)
	if field==null: finish(); return
	check((field.get("_player") as Node2D).position.distance_to(merchant_foot)<=1 and business_state()==state_before,"SHOP_ORIGINAL_FEET_RETURN_NOT_SAME_FIELD_OWNER_ORACLE")
	if not await walk_route(field,spec.route_to_capture): finish(); return
	if not await capture_jinling(field): finish(); return
	if not await overview_jinling(field): finish(); return
	if not await walk_route(field,spec.route_to_world_exit): finish(); return
	await key(KEY_SPACE)
	world=await wait_field(spec.world_id)
	if world==null: finish(); return
	check((world.get("_player") as Node2D).position.distance_to(expected_world_anchor*point(spec.world_size))<=1,"ORDINARY_WORLD_RETURN_TO_PRECAPTURED_SOURCE_ANCHOR")
	check(business_state()==state_before and png_count==1 and review_count==1 and active(),"ONE_NEW_CITY_TRIP_NO_OLD_CITY_OR_BUSINESS_REPLAY")
	finish()

func bridge_water_suffix(field: Node) -> bool:
	var author: Variant=load(spec.author)
	if not check(field.has_method(spec.live_foot_method),"NEW_LIVE_POINT_FOOT_INTERFACE_NOT_PLAYER_TO_FAR_POINT_PATH"): return false
	for bridge: Dictionary in spec.bridge_probes:
		for raw: Array in bridge.safe:
			var foot: Vector2=point(raw)
			check(author.safe_foot(foot/point(spec.size),false) and field.call(spec.live_foot_method,foot,false)==true,"BRIDGE_OR_BANK_FULL_FOOT_CLEAR:"+String(bridge.id))
		for raw: Array in bridge.water:
			var foot: Vector2=point(raw)
			check(not author.safe_foot(foot/point(spec.size),false) and field.call(spec.live_foot_method,foot,false)==false,"BESIDE_BRIDGE_WATER_REJECTS_FULL_FOOT:"+String(bridge.id))
	return errors.is_empty()

func jinling_static(field: Node) -> Dictionary:
	var ids: Array=[]
	for node: Node in field.get("_scene_object_nodes"): ids.append(str(node.get_instance_id()))
	for node: Node in field.get("_collision_bodies"): ids.append(str(node.get_instance_id()))
	return {"field":str(field.get_instance_id()),"revision":field.call("get_jinling_debug").layout_revision,"static_ids":ids}

func capture_jinling(_field: Node) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path: String=J_OUTPUT+str(OS.get_process_id())+"/bridge_market_NATIVE.png"
	if not check(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NORMAL_GAME_CAMERA_NATIVE"): return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not check(image.save_png(path)==OK,"SAVE_JINLING_NATIVE"): return false
	png_count=1; records.append({"native_png":path,"sha256":FileAccess.get_sha256(path),"actor_or_game_camera_writes":0}); return true

func overview_jinling(field: Node) -> bool:
	var game_camera: Camera2D=root.get_viewport().get_camera_2d()
	if not check(game_camera!=null,"LIVE_GAME_CAMERA_EXISTS"): return false
	var zoom: Vector2=game_camera.zoom
	var review:=SubViewport.new(); review.size=Vector2i(4096,3072); review.world_2d=root.get_viewport().world_2d
	review.render_target_update_mode=SubViewport.UPDATE_ALWAYS; root.add_child(review)
	var camera:=Camera2D.new(); review.add_child(camera)
	var size: Vector2=point(spec.size)
	camera.global_position=(field.get("world_container") as Node2D).to_global(size*.5)
	camera.zoom=Vector2.ONE*minf(4096.0/(size.x+64),3072.0/(size.y+64)); camera.make_current()
	await process_frame; await RenderingServer.frame_post_draw
	await process_frame; await RenderingServer.frame_post_draw
	var image: Image=review.get_texture().get_image()
	var path: String=J_OUTPUT+str(OS.get_process_id())+"/whole_jinling_REVIEW.png"
	var ok: bool=check(image!=null and image.get_size()==Vector2i(4096,3072) and not FileAccess.file_exists(path),"REVIEW_SHARED_REAL_WORLD_NOT_BAKED_BACKGROUND")
	if ok: ok=check(image.save_png(path)==OK,"SAVE_ONE_COMPLETE_CITY_REVIEW")
	if ok: review_count=1; records.append({"review_only_png":path,"sha256":FileAccess.get_sha256(path),"not_normal_camera_credit":true,"real_shared_world_and_npcs":true})
	check(root.get_viewport().get_camera_2d()==game_camera and game_camera.zoom==zoom,"NO_GAME_CAMERA_OVERRIDE_FOR_REVIEW")
	review.queue_free(); await process_frame; return ok

func finish() -> void:
	release_input()
	if not source_before.is_empty(): check(source_before==file_facts(source_before.keys()),"NEW_SCOPE_SOURCE_FIRST_FINAL")
	if not save_before.is_empty(): check(save_before==file_facts(save_before.keys()),"REGISTERED_SAVE15_SAME_ROOT_PRECISE_TICKS_SEPARATE")
	var path: String=J_OUTPUT+str(OS.get_process_id())+"/jinling_result.json"
	if FileAccess.file_exists(path): quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(2); return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"native_png_count":png_count,"review_only_count":review_count,"records":records,"fixture_sha256":FileAccess.get_sha256(J_FIXTURE),"actor_or_game_camera_writes":0,"save_writes":0,"local_version_dict_writes":0,"old_cities_retested":false},"\t")); file.close()
	print("[JinlingBounded] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
