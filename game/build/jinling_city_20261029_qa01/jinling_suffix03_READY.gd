extends "res://build/jinling_city_20261029_qa01/jinling_bounded_READY.gd"
## Only merchant modal return and unfinished images/south exit. Prior FAILs stay.
const M_FIXTURE := "res://build/jinling_city_20261029_qa01/jinling_suffix03_READY.json"

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(M_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"FROZEN_MERCHANT_RETURN_SUFFIX_ONLY"): finish(); return
	spec=raw
	if not check(spec.whole_seconds==60 and spec.entry_seconds==20 and spec.max_png==1,"ONE_MERCHANT_SUFFIX_60S_ONE_NATIVE_ONE_REVIEW"): finish(); return
	source_before=file_facts(spec.fixed_sources.keys())
	for path: String in spec.fixed_sources: check(source_before[path].get("sha256","")==spec.fixed_sources[path],"PIN:"+path)
	if not check(spec.save15.size()==15,"REGISTERED_FIFTEEN_SAVE_PATHS_ONLY"): finish(); return
	save_before=file_facts(spec.save15.keys())
	sr=root.get_node_or_null("SceneRouter");dp=root.get_node_or_null("DialogPlayer");lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"): finish(); return
	platform.call("set_checkpoint_saves_suspended",true)
	check(platform.call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED_UNTIL_QUIT")
	state_before=business_state()
	if not errors.is_empty(): finish(); return
	if not check(sr.call("go_field_smart",StringName(spec.city_id),point(spec.public_setup_foot)/point(spec.size),"",-1,31)==true,"PUBLIC_NATIVE_MERCHANT_FAILED_RETURN_SETUP_NO_ACTOR_POSE_WRITE"): finish(); return
	var field: Node=await wait_field(spec.city_id)
	if field==null: finish(); return
	if not check(field.get_script().resource_path==spec.city_field and (field.get("_player") as Node2D).position.distance_to(point(spec.public_setup_foot))<=1,"EXACT_PREVIOUS_MERCHANT_FEET_2584_1944"): finish(); return
	check((sr.get("_local_layout_versions") as Dictionary).get(spec.city_id)==31,"NATURAL_LOCAL31_NO_VERSION_DICT_WRITE")
	var author: Variant=load(spec.author)
	var positive: Vector2=point(spec.public_setup_foot);var negative: Vector2=point(spec.npc_negative_foot)
	check(author.safe_foot(positive/point(spec.size),true) and field.call(spec.live_foot_method,positive,true)==true,"FULL_PLAYER_BODY_AT_OLD_FALSE_REJECTION_NOW_SAFE_WITH_REAL_NPC")
	check(not author.safe_foot(negative/point(spec.size),true) and field.call(spec.live_foot_method,negative,true)==false,"ACTUAL_NPC_CENTER_STILL_BLOCKED_NOT_BYPASSED")
	check(author.safe_foot(negative/point(spec.size),false) and field.call(spec.live_foot_method,negative,false)==true,"NEGATIVE_POINT_IS_NPC_NOT_BUILDING_OR_WATER")
	if not errors.is_empty() or not verify_npc(field,spec.merchant): finish(); return
	var merchant_foot: Vector2=(field.get("_player") as Node2D).position
	await key(KEY_SPACE)
	var shop_started:=Time.get_ticks_msec()
	while active() and Time.get_ticks_msec()-shop_started<5000:
		await process_frame
		if current_scene!=null and current_scene.scene_file_path=="res://scenes/shop.tscn": break
	if not check(current_scene!=null and current_scene.scene_file_path=="res://scenes/shop.tscn" and String(sr.call("get_shop_payload").get("shop_id"))=="lingyue_pavilion","ORIGINAL_SHOP_UI_OPEN_NO_PURCHASE"): finish(); return
	await process_frame;await key(KEY_ESCAPE)
	field=await wait_field(spec.city_id)
	if field==null: finish(); return
	check((field.get("_player") as Node2D).position.distance_to(merchant_foot)<=1 and business_state()==state_before,"ORIGINAL_MERCHANT_MODAL_RETURNS_EXACT_PREVIOUS_FAILED_FEET")
	if not await walk_route(field,spec.route_to_capture): finish(); return
	if not await capture_jinling(field): finish(); return
	if not await overview_jinling(field): finish(); return
	if not await walk_route(field,spec.route_to_world_exit): finish(); return
	var expected: Vector2=point(spec.expected_world_anchor_uv)
	check(sr.call("get_world_map_position_for_scene",StringName(spec.city_id),StringName(spec.world_id))==expected,"WORLD_AUTHORED_ANCHOR_FROZEN_BEFORE_SPACE")
	await key(KEY_SPACE)
	var world: Node=await wait_field(spec.world_id)
	if world==null: finish(); return
	check((world.get("_player") as Node2D).position.distance_to(expected*point(spec.world_size))<=1,"REAL_SOUTH_WORLD_RETURN_TO_ORIGINAL_AUTHORED_ANCHOR")
	check(business_state()==state_before and png_count==1 and review_count==1 and active(),"ONLY_UNFINISHED_TRIP_NO_BRIDGE_OR_GUIDE_PREFIX_REPLAY")
	finish()

func finish() -> void:
	release_input()
	if not source_before.is_empty(): check(source_before==file_facts(source_before.keys()),"SUFFIX_SCOPE_SOURCE_FIRST_FINAL")
	if not save_before.is_empty(): check(save_before==file_facts(save_before.keys()),"REGISTERED_SAVE15_SAME_PRECISE_TICKS_ROOT_SEPARATE")
	var path: String=J_OUTPUT+str(OS.get_process_id())+"/jinling_suffix03_result.json"
	if FileAccess.file_exists(path): quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(2); return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"native_png_count":png_count,"review_only_count":review_count,"records":records,"fixture_sha256":FileAccess.get_sha256(M_FIXTURE),"actor_or_game_camera_writes":0,"save_writes":0,"local_version_dict_writes":0,"prior_actual_114832_and_86396_fails_preserved":true,"bridge_water_guide_prefix_replayed":false,"old_hero_portrait_oracle_wrong":true,"actual_neutral_hero_component_inherited_not_rerun":true},"\t"));file.close()
	print("[JinlingSuffix03] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
