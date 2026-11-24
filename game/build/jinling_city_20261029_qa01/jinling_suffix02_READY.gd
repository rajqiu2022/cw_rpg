extends "res://build/jinling_city_20261029_qa01/jinling_bounded_READY.gd"
## Only the failed north-quay leg and unfinished trip. Original FAIL is retained.
const S_FIXTURE := "res://build/jinling_city_20261029_qa01/jinling_suffix02_READY.json"

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(S_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"FROZEN_JINLING_FAILED_LEG_SUFFIX_ONLY"): finish(); return
	spec=raw
	if not check(spec.whole_seconds==60 and spec.entry_seconds==20 and spec.max_png==1,"ONE_SUFFIX_60_SECONDS_ONE_NATIVE_ONE_REVIEW"): finish(); return
	source_before=file_facts(spec.fixed_sources.keys())
	for path: String in spec.fixed_sources: check(source_before[path].get("sha256","")==spec.fixed_sources[path],"PIN:"+path)
	if not check(spec.save15.size()==15,"REGISTERED_FIFTEEN_SAVE_PATHS_ONLY"): finish(); return
	save_before=file_facts(spec.save15.keys())
	sr=root.get_node_or_null("SceneRouter"); dp=root.get_node_or_null("DialogPlayer"); lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"): finish(); return
	platform.call("set_checkpoint_saves_suspended",true)
	check(platform.call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED_UNTIL_QUIT")
	state_before=business_state();dp.connect("text_displayed",_on_text);dp.connect("choices_displayed",_on_choices)
	if not errors.is_empty(): finish(); return
	# Explicit public setup reproduces the failed leg; no actor pose is assigned.
	if not check(sr.call("go_field_smart",StringName(spec.city_id),point(spec.public_setup_foot)/point(spec.size),"",-1,31)==true,"PUBLIC_NATIVE_FAILED_LEG_SETUP_NOT_CONTINUOUS_WORLD_TRAVEL"): finish(); return
	var field: Node=await wait_field(spec.city_id)
	if field==null: finish(); return
	if not check(field.get_script().resource_path==spec.city_field and (field.get("_player") as Node2D).position.distance_to(point(spec.public_setup_foot))<=1,"EXACT_FAILED_LEG_PUBLIC_START"): finish(); return
	check((sr.get("_local_layout_versions") as Dictionary).get(spec.city_id)==31,"NATURAL_LOCAL31_NO_VERSION_DICT_WRITE")
	# Pose changed: these eight point probes receive new-pose credit, not old credit.
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
	await process_frame;await key(KEY_ESCAPE)
	field=await wait_field(spec.city_id)
	if field==null: finish(); return
	check((field.get("_player") as Node2D).position.distance_to(merchant_foot)<=1 and business_state()==state_before,"SHOP_ORIGINAL_FEET_RETURN_NOT_SAME_FIELD_OWNER_ORACLE")
	if not await walk_route(field,spec.route_to_capture): finish(); return
	if not await capture_jinling(field): finish(); return
	if not await overview_jinling(field): finish(); return
	if not await walk_route(field,spec.route_to_world_exit): finish(); return
	var expected: Vector2=point(spec.expected_world_anchor_uv)
	check(sr.call("get_world_map_position_for_scene",StringName(spec.city_id),StringName(spec.world_id))==expected,"WORLD_AUTHORED_ANCHOR_FROZEN_BEFORE_SPACE_NOT_RETURNED_ACTUAL")
	records.append({"world_anchor_before_exit":expected,"public_setup_not_original_world_prefix":true})
	await key(KEY_SPACE)
	var world: Node=await wait_field(spec.world_id)
	if world==null: finish(); return
	check((world.get("_player") as Node2D).position.distance_to(expected*point(spec.world_size))<=1,"REAL_SOUTH_WORLD_RETURN_TO_AUTHORED_ANCHOR")
	check(business_state()==state_before and png_count==1 and review_count==1 and active(),"SUFFIX_NO_OLD_WORLD_ENTRY_OR_SUCCESSFUL_SOUTH_APPROACH_REPLAY")
	finish()

func jinling_static(field: Node) -> Dictionary:
	var ids: Array=[]
	for property: String in ["_scene_object_nodes","_collision_bodies","_jl_ground"]:
		for node: Node in field.get(property): ids.append(str(node.get_instance_id()))
	return {"field":str(field.get_instance_id()),"revision":field.call("get_jinling_debug").layout_revision,"all_static_and_ground_ids":ids}

func finish() -> void:
	release_input()
	if not source_before.is_empty(): check(source_before==file_facts(source_before.keys()),"SUFFIX_SCOPE_SOURCE_FIRST_FINAL")
	if not save_before.is_empty(): check(save_before==file_facts(save_before.keys()),"REGISTERED_SAVE15_SAME_PRECISE_TICKS_ROOT_SEPARATE")
	var path: String=J_OUTPUT+str(OS.get_process_id())+"/jinling_suffix02_result.json"
	if FileAccess.file_exists(path): quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(2); return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"native_png_count":png_count,"review_only_count":review_count,"records":records,"fixture_sha256":FileAccess.get_sha256(S_FIXTURE),"actor_or_game_camera_writes":0,"save_writes":0,"local_version_dict_writes":0,"original_actual_114832_fail_preserved":true,"old_world_entry_and_south_approach_replayed":false,"new_bridge_pose_point_probes":8},"\t"));file.close()
	print("[JinlingSuffix02] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
