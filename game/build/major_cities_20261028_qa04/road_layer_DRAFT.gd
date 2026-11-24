extends "res://build/major_cities_20261028_qa01/bianzhou_bounded_DRAFT.gd"
## Last visual observation only: no INPUT, overview, NPC or geometry replay.
const LAYER_FIXTURE := "res://build/major_cities_20261028_qa04/road_layer_READY.json"
const LAYER_OUTPUT := "res://build/major_cities_20261028_qa04/actual/"

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(LAYER_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"FINAL_LAYER_OBSERVATION_ONLY"): finish(); return
	spec=raw; source_before=file_facts(spec.fixed_sources.keys())
	for path: String in spec.fixed_sources: check(source_before[path].get("sha256","")==spec.fixed_sources[path],"PIN:"+path)
	var baseline: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.baseline))
	save_before=file_facts(baseline.save15.keys())
	sr=root.get_node_or_null("SceneRouter"); dp=root.get_node_or_null("DialogPlayer"); lm=root.get_node_or_null("LoadingManager")
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if not check(sr!=null and dp!=null and lm!=null and platform!=null,"NORMAL_AUTOLOADS"): finish(); return
	platform.call("set_checkpoint_saves_suspended",true); state_before=business_state()
	if not errors.is_empty(): finish(); return
	if not check(sr.call("go_field_smart",StringName(spec.city_id),Vector2(1450,1562)/Vector2(6144,6144),"",-1,30)==true,"ONE_EXPLICIT_RESIDENTIAL_SETUP_NO_ACTOR_WRITE"): finish(); return
	var field: Node=await wait_field(spec.city_id)
	if field==null: finish(); return
	if not check(field.get_script().resource_path==spec.city_field and (field.get("_player") as Node2D).position.distance_to(Vector2(1450,1562))<=1,"FORMAL_FIELD_SOURCE_FOOT"): finish(); return
	var world: Node2D=field.get("world_container")
	for id: String in spec.road_layers:
		var node:=world.get_node_or_null("BianzhouPaving_"+id) as Polygon2D
		check(node!=null and node.z_index==int(spec.road_layers[id]),"ACTUAL_ROAD_LAYER:"+id)
	if not errors.is_empty(): finish(); return
	await RenderingServer.frame_post_draw
	var snapshot: Image=root.get_viewport().get_texture().get_image()
	var path: String=LAYER_OUTPUT+str(OS.get_process_id())+"/residential_road_layer_NATIVE.png"
	if not check(snapshot!=null and snapshot.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NORMAL_NATIVE_CAMERA_NO_OVERVIEW"): finish(); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not check(snapshot.save_png(path)==OK,"SAVE_ONE_LAYER_OBSERVATION"): finish(); return
	png_count=1; records.append({"native_png":path,"sha256":FileAccess.get_sha256(path),"inherited_actual":"85680","repeated_109_176_1122":false,"actor_or_camera_writes":0})
	check(input_ticks==0 and business_state()==state_before and active(),"ZERO_INPUT_NO_BUSINESS_MUTATION")
	finish()

func finish() -> void:
	release_input()
	if not source_before.is_empty(): check(source_before==file_facts(source_before.keys()),"LAYER_SOURCE_FIRST_FINAL")
	if not save_before.is_empty(): check(save_before==file_facts(save_before.keys()),"SAVE15_SAME_ROOT_TICKS_SEPARATE")
	var path: String=LAYER_OUTPUT+str(OS.get_process_id())+"/road_layer_result.json"
	if FileAccess.file_exists(path): quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(2); return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"native_png_count":png_count,"overview_count":0,"records":records,"fixture_sha256":FileAccess.get_sha256(LAYER_FIXTURE),"actor_or_camera_writes":0,"save_writes":0},"\t")); file.close()
	print("[BianzhouRoadLayer] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
