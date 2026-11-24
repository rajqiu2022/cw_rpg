extends "res://build/jinling_city_20261029_qa01/jinling_bounded_READY.gd"
## Visual seam only; all successful travel/shop/dialogue components are stopped.
const V_FIXTURE := "res://build/jinling_city_20261029_qa01/jinling_visual04_READY.json"

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(V_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"FROZEN_SOUTH_QUAY_SEAM_VISUAL_ONLY"): finish(); return
	spec=raw
	if not check(spec.whole_seconds==20 and spec.max_png==1,"ONE_NORMAL_SEAM_IMAGE_20_SECONDS_ZERO_INPUT"): finish(); return
	source_before=file_facts(spec.fixed_sources.keys())
	for path: String in spec.fixed_sources: check(source_before[path].get("sha256","")==spec.fixed_sources[path],"PIN:"+path)
	save_before=file_facts(spec.save15.keys())
	sr=root.get_node_or_null("SceneRouter");dp=root.get_node_or_null("DialogPlayer");lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"): finish(); return
	platform.call("set_checkpoint_saves_suspended",true);state_before=business_state()
	check(platform.call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED_UNTIL_QUIT")
	if not errors.is_empty(): finish(); return
	if not check(sr.call("go_field_smart",StringName(spec.city_id),point(spec.public_setup_foot)/point(spec.size),"",-1,31)==true,"PUBLIC_BRIDGE_VIEW_SETUP_NOT_ACTOR_OR_CAMERA_WRITE"): finish(); return
	var field: Node=await wait_field(spec.city_id)
	if field==null: finish(); return
	if not check(field.get_script().resource_path==spec.city_field and (field.get("_player") as Node2D).position.distance_to(point(spec.public_setup_foot))<=1,"BRIDGE_VIEW_PUBLIC_NATIVE_1536_2300"): finish(); return
	var road: Polygon2D=(field.get("world_container") as Node).get_node_or_null("JinlingPaving_south_quay0") as Polygon2D
	if not check(road!=null and road.get_meta("jl_texture_path")==spec.stone_texture and road.get_meta("jl_period").is_equal_approx(point(spec.stone_period)),"REAL_SOUTH_ROAD_STONE_TEXTURE_PERIOD"): finish(); return
	var road_min_y:=INF
	for p: Vector2 in road.polygon: road_min_y=minf(road_min_y,p.y)
	check(road_min_y==2580.0,"SOUTH_ROAD_ACTUAL_BEGIN_Y_2580")
	for i: int in range(3):
		var cap: Polygon2D=(field.get("world_container") as Node).get_node_or_null("JinlingPaving_south_quay_cap_%d"%i) as Polygon2D
		if not check(cap!=null,"REAL_SOUTH_CAP_NODE_%d"%i): continue
		var cap_max_y: float=-INF
		for p: Vector2 in cap.polygon: cap_max_y=maxf(cap_max_y,p.y)
		check(cap_max_y==road_min_y and cap.texture==road.texture and cap.get_meta("jl_period")==road.get_meta("jl_period"),"CAP_TOUCHES_ROAD_WITH_IDENTICAL_STONE_UV_PERIOD_%d"%i)
		var uv_matches: bool=cap.uv.size()==cap.polygon.size()
		for j: int in range(cap.polygon.size()):
			if j>=cap.uv.size() or cap.uv[j].distance_to(cap.polygon[j]/point(spec.stone_period)*cap.texture.get_size())>.01: uv_matches=false
		check(uv_matches,"CAP_ACTUAL_WORLD_UV_MATCHES_COMMON_STONE_PERIOD_%d"%i)
		records.append({"south_cap":i,"actual_end_y":cap_max_y,"road_begin_y":road_min_y})
	if not errors.is_empty(): finish(); return
	if not await capture_jinling(field): finish(); return
	check(input_ticks==0 and png_count==1 and review_count==0 and business_state()==state_before and active(),"NO_FUNCTION_REPLAY_INPUT_OVERVIEW_SHOP_OR_WORLD")
	finish()

func finish() -> void:
	release_input()
	if not source_before.is_empty(): check(source_before==file_facts(source_before.keys()),"VISUAL_SCOPE_SOURCE_FIRST_FINAL")
	if not save_before.is_empty(): check(save_before==file_facts(save_before.keys()),"REGISTERED_SAVE15_SAME_ROOT_EXACT_TICKS_SEPARATE")
	var path: String=J_OUTPUT+str(OS.get_process_id())+"/jinling_visual04_result.json"
	if FileAccess.file_exists(path): quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(2); return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"native_png_count":png_count,"review_only_count":review_count,"records":records,"fixture_sha256":FileAccess.get_sha256(V_FIXTURE),"actor_or_game_camera_writes":0,"save_writes":0,"old_functional_components_retested":false},"\t"));file.close()
	print("[JinlingVisual04] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
