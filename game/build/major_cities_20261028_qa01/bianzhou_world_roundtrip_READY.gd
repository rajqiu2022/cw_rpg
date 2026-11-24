extends "res://build/major_cities_20261028_qa01/bianzhou_bounded_DRAFT.gd"
## Root only. Public native south setup establishes version28 through normal Entry.
## One Space to the actual World gateway, then one Space back. No QA state writes.
const WORLD_FIXTURE := "res://build/major_cities_20261028_qa01/bianzhou_world_roundtrip_READY.json"

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(WORLD_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"ROOT_FROZEN_WORLD_BRANCH_ONLY"):finish();return
	spec=raw
	if not check(spec.whole_seconds==60 and spec.entry_seconds==20 and spec.max_png==0 and spec.fixed_sources.size()==20,"ONE_BRANCH_60S_NO_PNG"):finish();return
	var baseline: Variant=JSON.parse_string(FileAccess.get_file_as_string(spec.baseline))
	if not check(baseline is Dictionary and baseline.save15.size()==15,"REGISTERED_SAVE_PATHS_ONLY"):finish();return
	source_before=file_facts(spec.fixed_sources.keys());save_before=file_facts(baseline.save15.keys())
	for path: String in spec.fixed_sources:check(source_before[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path)
	sr=root.get_node_or_null("SceneRouter");dp=root.get_node_or_null("DialogPlayer");lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"):finish();return
	platform.call("set_checkpoint_saves_suspended",true)
	check(platform.call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED_UNTIL_QUIT")
	state_before=business_state()
	if not errors.is_empty():finish();return
	if not check(sr.call("go_field_smart",StringName(spec.city_id),point(spec.public_setup_foot)/point(spec.get("size")),"",-1,28)==true,"PUBLIC_NATIVE_SOUTH_SETUP_NO_ACTOR_OR_VERSION_DICT_WRITE"):finish();return
	var field: Node=await wait_field(spec.city_id)
	if field==null:finish();return
	if not check(field.get_script().resource_path==spec.city_field and (field.get("_player") as Node2D).position.distance_to(point(spec.public_setup_foot))<=1.0,"EXPLICIT_PUBLIC_SOUTH_SETUP_NOT_DEFAULT_TRAVEL"):finish();return
	var versions: Dictionary=(sr.get("_local_layout_versions") as Dictionary).duplicate(true)
	if not check(versions.get(spec.city_id)==28,"NATURAL_ENTRY_HAS_ALREADY_SET_LOCAL_VERSION28"):finish();return
	var expected_world: String=String(sr.get("_active_world_map_scene"))
	records.append({"public_setup_foot":(field.get("_player") as Node2D).position,"natural_local_versions_before_world":versions,"world_id":expected_world,"actor_pose_written_by_QA":false})
	await key(KEY_SPACE)
	var world: Node=await wait_field(expected_world)
	if world==null:finish();return
	var world_scene: Resource=world.get("_current_scene")
	var layout: Resource=world_scene.get("map_layout")
	if not check(layout.get("schema_version")==15 and layout.get("design_size")==Vector2i(12288,8192) and layout.resource_path=="res://data/maps/world_map_jianghu_layout_v15.tres","ACTUAL_WORLD_V15_NOT_GUESSED"):finish();return
	var rows: Array=[]
	for source_row: Dictionary in layout.get("portals"):
		if source_row.get("id")=="bianzhou":rows.append(source_row)
	if not check(rows.size()==1,"UNIQUE_ACTUAL_WORLD_BIANZHOU_PORTAL"):finish();return
	var row: Dictionary=rows[0]
	if not check(String(row.get("target_scene"))==spec.city_id and row.get("target_pos")==point(spec.world_authored_target_uv) and row.get("pos")==point(spec.world_portal_uv),"REAL_PORTAL_TARGET_IS_LEGACY_0535_09_NOT_NATIVE_VERSION28"):finish();return
	var zones: Array=[]
	for exit_node: Node in world.get("_exit_nodes"):
		if String(exit_node.get("target_scene_id"))==spec.city_id:zones.append(exit_node)
	if not check(zones.size()==1,"ONE_ACTUAL_BOUND_WORLD_EXIT"):finish();return
	var zone: Node=zones[0]
	for _stable_tick: int in range(3):await physics_frame
	if not check(zone.get("target_spawn_pos")==point(spec.world_authored_target_uv) and zone.has_method("can_enter") and zone.call("can_enter")==true,"REAL_WORLD_DOOR_CAN_ENTER_BEFORE_SPACE"):finish();return
	check((sr.get("_local_layout_versions") as Dictionary).get(spec.city_id)==28,"NATURAL_EXISTING_VERSION28_SURVIVES_WORLD");if not errors.is_empty():finish();return
	records.append({"actual_world_player":(world.get("_player") as Node2D).position,"actual_world_portal_uv":row.get("pos"),"actual_world_authored_target_uv":row.get("target_pos"),"bound_target_uv":zone.get("target_spawn_pos"),"can_enter_before_real_space":true,"natural_local_versions_on_world":(sr.get("_local_layout_versions") as Dictionary).duplicate(true)})
	await key(KEY_SPACE)
	field=await wait_field(spec.city_id)
	if field==null:finish();return
	var actual: Vector2=(field.get("_player") as Node2D).position
	records.append({"returned_city_actual":actual,"expected_city_external_gate":point(spec.expected_city_foot),"local_versions_after":(sr.get("_local_layout_versions") as Dictionary).duplicate(true)})
	check(actual.distance_to(point(spec.expected_city_foot))<=1.0 and (sr.get("_local_layout_versions") as Dictionary).get(spec.city_id)==28,"WORLD_LEGACY_TARGET_WITH_EXISTING28_RETURNS_OUTSIDE_GATE")
	check(business_state()==state_before,"NO_NEW_BUSINESS_OR_SAVE_SIDE_EFFECTS")
	check(active(),"ONE_BRANCH_60_SECONDS_NO_EXTENSION")
	finish()

func finish() -> void:
	release_input()
	if not source_before.is_empty():check(source_before==file_facts(source_before.keys()),"SMALL_TWENTY_SOURCE_FIRST_FINAL")
	if not save_before.is_empty():check(save_before==file_facts(save_before.keys()),"SAVE15_HASH_BYTES_SECONDS_SAME_EXACTTICKS_ROOT_SEPARATE")
	var path: String=OUTPUT+str(OS.get_process_id())+"/world_roundtrip_result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"records":records,"fixture_sha256":FileAccess.get_sha256(WORLD_FIXTURE),"png_count":0,"qa_actor_pose_writes":0,"qa_local_version_dict_writes":0,"save_writes":0,"reset_calls":0,"default_world_travel_claim":false,"repeated_dialog_shop_north_tests":false},"\t"));file.close()
	print("[BianzhouWorldRoundtrip] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
