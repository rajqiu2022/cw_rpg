extends "res://build/major_cities_20261028_qa01/bianzhou_bounded_DRAFT.gd"
## Root only. Inherit unchanged helpers, not the failed whole journey verdict.
## Explicit public north setup; no repeated default entry, dialogue or Shop tests.
const RESIDUAL_FIXTURE := "res://build/major_cities_20261028_qa01/bianzhou_north_south_residual02_READY.json"

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(RESIDUAL_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"ROOT_FROZEN_RESIDUAL_ONLY"):finish();return
	spec=raw
	if not check(spec.whole_seconds==120 and spec.entry_seconds==20 and spec.max_png==1 and spec.fixed_sources.size()==20,"NORTH_RETURN_SOUTH_ONLY_BOUNDED"):finish();return
	var baseline: Variant=JSON.parse_string(FileAccess.get_file_as_string(spec.baseline))
	if not check(baseline is Dictionary and baseline.save15.size()==15,"REGISTERED_FIFTEEN_SAVES_ONLY"):finish();return
	source_before=file_facts(spec.fixed_sources.keys());save_before=file_facts(baseline.save15.keys())
	for path: String in spec.fixed_sources:check(source_before[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path)
	check(FileAccess.get_sha256(spec.inherited_prefix.path)==spec.inherited_prefix.sha256,"ORIGINAL_WHOLE_FAILURE_PRESERVED_COMPONENT_PREFIX_ONLY")
	sr=root.get_node_or_null("SceneRouter");dp=root.get_node_or_null("DialogPlayer");lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"):finish();return
	platform.call("set_checkpoint_saves_suspended",true)
	check(platform.call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED_TO_QUIT")
	state_before=business_state()
	if not errors.is_empty():finish();return
	var setup: Vector2=point(spec.public_setup_foot)
	if not check(sr.call("go_field_smart",StringName(spec.city_id),setup/point(spec.get("size")),"",-1,28)==true,"PUBLIC_EXPLICIT_NORTH_SETUP_NOT_DEFAULT_TRAVEL"):finish();return
	var field: Node=await wait_field(spec.city_id)
	if field==null:finish();return
	if not check(field.get_script().resource_path==spec.city_field and (field.get("_player") as Node2D).position.distance_to(setup)<=1.0,"EXPLICIT_NORTH_PUBLIC_SETUP_FOOT"):finish();return
	var scene: Resource=field.get("_current_scene")
	var layout: Resource=scene.get("map_layout")
	var anchors: Array=[]
	for row: Dictionary in layout.get("portals"):
		if row.get("id")=="old_post":anchors.append(row.get("source_spawn_pos",row.get("pos"))*point(spec.get("size")))
	var expected_anchor: Vector2=point(spec.expected_original_source_anchor)
	if not check(anchors.size()==1 and (anchors[0] as Vector2).distance_to(expected_anchor)<=.0001,"INDEPENDENT_FROZEN_GENERIC_SOURCE_ANCHOR_NOT_ACTUAL_FOOT"):finish();return
	var before_actual: Vector2=(field.get("_player") as Node2D).position
	records.append({"explicit_public_north_setup_not_default":setup,"capture_before_actual":before_actual,"expected_generic_authored_source_anchor":expected_anchor,"portal_return_map_before":(sr.get("_portal_return_spawns") as Dictionary).duplicate(true)})
	await key(KEY_SPACE)
	var old_post: Node=await wait_field(spec.north.target)
	if old_post==null:finish();return
	var cache_after_departure: Dictionary=(sr.get("_portal_return_spawns") as Dictionary).duplicate(true)
	records.append({"portal_return_map_after_departure":cache_after_departure,"old_post_actual_arrival":(old_post.get("_player") as Node2D).position})
	if not check((old_post.get("_player") as Node2D).position.distance_to(Vector2(1536,1802.24))<=1.0,"ORIGINAL_OLD_POST_ARRIVAL"):finish();return
	var return_key: String=String(spec.north.target)+"->"+String(spec.city_id)
	if not check(cache_after_departure.has(return_key) and (cache_after_departure[return_key] as Vector2).distance_to(expected_anchor/point(spec.get("size")))<=.0000001,"EXISTING_GENERIC_CACHE_STORES_AUTHORED_SOURCE_ANCHOR"):finish();return
	if not await walk_route(old_post,spec.north.old_post_return_route):finish();return
	await key(KEY_SPACE)
	field=await wait_field(spec.city_id)
	if field==null:finish();return
	var returned_actual: Vector2=(field.get("_player") as Node2D).position
	records.append({"returned_actual":returned_actual,"expected_generic_source_anchor":expected_anchor,"capture_before_actual":before_actual,"distance_to_anchor":returned_actual.distance_to(expected_anchor),"distance_to_before_actual":returned_actual.distance_to(before_actual),"portal_return_map_after_return":(sr.get("_portal_return_spawns") as Dictionary).duplicate(true),"old_failed_actual_foot_expectation_not_reused":true})
	if not check(returned_actual.distance_to(expected_anchor)<=1.0,"ORIGINAL_GENERIC_RETURN_ANCHOR_ONE_PIXEL_UNCHANGED"):finish();return
	if not await walk_route(field,spec.residual_south_before_capture):finish();return
	if not await capture("southgate_material_after_real_traversal"):finish();return
	if not await walk_route(field,spec.residual_south_after_capture):finish();return
	if not check((field.get("_player") as Node2D).position.distance_to(point(spec.south.portal_foot))<=TOLERANCE,"TRUE_INPUT_TO_ORIGINAL_SOUTH_EXIT"):finish();return
	var expected_world: String=String(sr.get("_active_world_map_scene"))
	await key(KEY_SPACE)
	var world: Node=await wait_field(expected_world)
	if world==null:finish();return
	check(sr.call("is_world_map_scene",StringName(expected_world))==true and business_state()==state_before,"SOUTH_ACTUAL_WORLD_NO_BUSINESS_MUTATION")
	check(active(),"ONE_RESIDUAL_WITHIN_120_SECONDS")
	finish()

func finish() -> void:
	release_input()
	if not source_before.is_empty():check(source_before==file_facts(source_before.keys()),"SMALL_CURRENT_SOURCE_FIRST_FINAL")
	if not save_before.is_empty():check(save_before==file_facts(save_before.keys()),"SAVE15_HASH_BYTES_SECONDS_SAME_ROOT_EXACTTICKS_SEPARATE")
	var path: String=OUTPUT+str(OS.get_process_id())+"/residual_result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"png_count":png_count,"records":records,"fixture_sha256":FileAccess.get_sha256(RESIDUAL_FIXTURE),"save_writes":0,"qa_pose_or_camera_writes":0,"reset_calls":0,"repeated_default_dialog_shop_prefix":false,"prior_whole_failure_retained":true},"\t"));file.close()
	print("[BianzhouNorthSouthResidual] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
