extends "res://tests/test_luoyang_loading_candidate_retry1_draft_20261018r.gd"
## Frozen standalone WORLD only. No bundle/native-city/Room/Gate entry credit.
const WORLD_ONLY_READY=true
const WORLD_CORE_PATH="res://tests/fixtures/luoyang_loading_candidate_20261018r_core_prepublication.json"
const WORLD_CORE_SHA="d0279af07c2c3a351c6e55dd64771c07acc8c8e4f046a218e062438b50dbcf4a"
const WORLD_TOOL_PATH="res://tests/test_luoyang_loading_candidate_retry1_draft_20261018r.gd"
const WORLD_TOOL_SHA="d3bf145e6f7bca9e254f50ab45cc503149578ec979ec9802fac0a92a7e866ad8"

func precheck() -> bool:
	if not check(WORLD_ONLY_READY and DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty(),"Only real ordinary world streaming; no bundle or city flags"): return false
	if not track(WORLD_CORE_PATH,WORLD_CORE_SHA) or not track(WORLD_TOOL_PATH,WORLD_TOOL_SHA): return false
	var core: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(WORLD_CORE_PATH))
	for path: String in core.source_sha256:
		if not track(path,core.source_sha256[path]): return false
	if not track("res://tests/helpers/world_viewport_independent_oracle_20261018r.gd",VIEW_ORACLE_SHA) or not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	stream_api=load(STREAM_PATH)
	return check(stream_api!=null,"Exact currently deployed default world streamer, no publication artifact read")

func _exercise() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var definition: SceneScript=ResourceLoader.load("res://data/scenes/world_map_jianghu.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var portals: Array=[]
	for entry: Dictionary in definition.map_layout.portals:
		if entry.get("target_scene")==GATE_ID: portals.append(entry)
	if not check(portals.size()==1,"Original immutable unique Gate world doorway, not activating it"): return false
	var entry: Vector2=portals[0].pos*Vector2(12288,8192)
	var setup: Vector2=entry+Vector2(0,96)
	_arm_draw(WORLD_ID,"WORLD_STREAM_ONLY_LEGAL_NEAR_SETUP_NOT_TRAVEL")
	if not check(router.call("go_field_smart",StringName(WORLD_ID),setup/Vector2(12288,8192),"",15),"Only one normal public world near-door setup") or not await _wait_once(WORLD_ID) or not _world_bind(): return false
	if not await _walk(PackedVector2Array([field.get("_player").position,entry])) or not _zone(GATE_ID): return false
	return await _capture("ordinary_world_stream_near_gate_NO_CITY_ENTRY")

func _leave_actual_field() -> bool:
	if not is_instance_valid(field): return true
	var owned: Node=field
	var field_ref: WeakRef=weakref(owned)
	var stream_ref: WeakRef=weakref(owned.get("_world_v15_stream"))
	var observed: Dictionary={"tree_exited":false}
	owned.tree_exited.connect(func() -> void: observed.tree_exited=true,CONNECT_ONE_SHOT)
	owned.queue_free()
	await process_frame;await process_frame
	while stream_api.drain_count()>0 and Time.get_ticks_msec()<deadline: await process_frame
	var released: bool=observed.tree_exited and field_ref.get_ref()==null and stream_ref.get_ref()==null and stream_api.drain_count()==0
	records.append({"kind":"WORLD_OWN_EXIT_AND_DRAIN","tree_exited":observed.tree_exited,"Field_gone":field_ref.get_ref()==null,"stream_gone":stream_ref.get_ref()==null,"outstanding":stream_api.drain_count(),"released":released})
	field=null
	return check(released,"Own real world tree exit/stream release/no late loader owner/drain0 within90s")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+90000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/world_visible_stream_actual_20261018r/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		RenderingServer.frame_post_draw.connect(_r_draw)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
		if not await _leave_actual_field(): complete=false
	draw_target=""
	if RenderingServer.frame_post_draw.is_connected(_r_draw): RenderingServer.frame_post_draw.disconnect(_r_draw)
	if driver!=null: driver.release();driver=null
	root.get_node("SceneRouter").call("reset_for_new_game")
	await process_frame;await process_frame
	field=null;scene=null;oracle=null;frame_images.clear()
	records.append({"kind":"SCOPE","whole_ms":90000,"arrival_ms":60000,"captures":captures,"native_queries":native_queries,"complete_world_bodies":2322,"complete_world_Areas":16,"postdraw_world_checks":world_checks,"selection_changes_after_normal96px":world_selection_changes,"same_R_firstdraw_instrument":true,"NO_city_entry_bundle_or_warm_performance_credit":true})
	finish(folder,began,complete,"R_WORLD_VISIBLE_STREAM_ONLY_ORIGINAL96INPUT_AND_FULL_PHYSICS")
