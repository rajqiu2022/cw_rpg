extends "res://tests/test_luoyang_live_module_field_key_retry2_20261015.gd"
## NEW one Market live transition. Existing failed Gate+Market whole remains.
## Yamen public legal portal birth is setup only, not travel/performance credit.
const MARKET_ONLY_SCOPE := "KEY_MARKET_LIVE_MODULE_ONLY_PLUS_YAMEN_PUBLIC_SETUP_20261015"
const MARKET_ONLY_BUDGET_MS := 150000
const PARENT_SOURCE := "res://tests/test_luoyang_live_module_field_key_retry2_20261015.gd"
const PARENT_SHA := "281bf84a6dc266a2f8083055d911a1a0550e65fd955c40cd69365ecaf0c1b91a"

func _ordinary_key() -> void:
	var yamen: SceneScript = ResourceLoader.load("res://data/scenes/ch4_s1_luoyang_yamen.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var departure: Dictionary = {}
	if yamen != null:
		for item: Dictionary in yamen.map_layout.portals:
			if item.get("id") == "to_south_market": departure=item
	if not _check(not departure.is_empty() and departure.get("arrival_foot_px") == Vector2(300,1220),"Original Yamen toMarket exact source portal foot"): return
	_tag("YAMEN_PUBLIC_CURRENT_VERSION3_SETUP_ONLY_NOT_MARKET_PERFORMANCE",YAMEN_ID)
	_observe(YAMEN_ID,"before_public_Yamen_setup_explicit_local_version3",Time.get_ticks_msec())
	var call_started := Time.get_ticks_msec()
	var ok: bool = bool(root.get_node("SceneRouter").call("go_field_smart",StringName(YAMEN_ID),Vector2(300,1220)/C.SIZE,"",-1,C.VERSION))
	tag_stats[observation_tag].public_call_ms=Time.get_ticks_msec()-call_started
	_observe(YAMEN_ID,"after_public_Yamen_setup_return_"+str(ok),call_started)
	if not _check(ok,"Explicit current-format version3 lawful Yamen public setup"):
		_finish_tag(); return
	if not await _wait_field(YAMEN_ID) or not _bind(): _finish_tag(); return
	_finish_tag()
	var foot: Vector2=(field.get("_player") as Node2D).position
	if not _check(foot.distance_to(Vector2(300,1220))<.03 and _clear(foot),"Actual Yamen setup original full875/17/Physics and exact portal foot"): return
	var market_zone: Node
	for item: Node in field.get("_exit_nodes"):
		if String(item.get("target_scene_id")) == String(MARKET.ID): market_zone=item
	if not _check(market_zone!=null and bool(market_zone.get("_in_range")) and not bool(market_zone.get("is_locked")),"Actual original Yamen toMarket portal overlap"): return
	rows.append({"kind":"YAMEN_PUBLIC_SETUP_ONLY","foot":foot,"raw875":_body_raw(foot),"raw17":oracle.call("foot_evidence",foot),"Physics":_physical(foot),"explicit_local_version":C.VERSION,"Gate_or_world_travel_tested":false,"Market_performance_credit":false})
	_tag("MARKET_LIVE_SPACE",String(MARKET.ID))
	if not await _space_to(String(MARKET.ID)): _finish_tag(); return
	_finish_tag()
	var expected: Array[String]=[MARKET.TEXTURE_ALIASES[MARKET.STREET],MARKET.TEXTURE_ALIASES[MARKET.STALL],MARKET.TEXTURE_ALIASES[MARKET.TREE],MARKET.ROOT+"walk.png"]
	_module_assert(String(MARKET.ID),expected)
	_tag("QA_MARKET_FULL_SOURCE_ORACLE_NOT_LOADING_PERFORMANCE",String(MARKET.ID))
	if not _sources_market() or not _bind(): _finish_tag(); return
	var actual: SceneScript=field.get("_current_scene") as SceneScript
	var manifest_objects: Array=MARKET.runtime_manifest().get("objects",[])
	_check(actual!=null and actual.map_layout.visual_objects.size()==26 and manifest_objects.size()==26,"Actual Market canonical26 definitions and exact published26 composition")
	var native_ids: Dictionary={}
	for node: Sprite2D in field.get("_scene_object_nodes"):
		if not String(node.name).begins_with("SceneObject_"): continue
		var id: String=String(node.name).trim_prefix("SceneObject_")
		_check(not native_ids.has(id) and node.is_inside_tree() and not node.is_queued_for_deletion(),"Live unique native Market object "+id)
		native_ids[id]=node
	_check(native_ids.size()==26,"Actual native Market26 object sprites, not definition-only count")
	for object: Dictionary in manifest_objects:
		var node: Sprite2D=native_ids.get(String(object.id)) as Sprite2D
		_check(node!=null and node.texture!=null and node.texture.resource_path==object.texture,"Actual native object texture source identity "+String(object.id))
	foot=(field.get("_player") as Node2D).position
	if not _check(foot.distance_to(Vector2(1536,770))<.03 and _clear(foot),"Actual live Market original770 birth full875/17/Physics"): _finish_tag(); return
	rows.append({"kind":"ACTUAL_MARKET_FIELD","foot":foot,"raw875":_body_raw(foot),"raw17":oracle.call("foot_evidence",foot),"Physics":_physical(foot),"fade":field.call("get_city_building_fade_debug"),"actual_visual_count":actual.map_layout.visual_objects.size()})
	captures.append(await _capture_gate("actual_market_after_live_space"))
	_finish_tag()

func _run() -> void:
	live_started=Time.get_ticks_msec(); deadline=live_started+MARKET_ONLY_BUDGET_MS
	output="res://build/luoyang_market_live_module_only_key_20261015/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"Checkpoints held before first await")
	players_before=_players(); prior_slot=int(root.get_node("SaveManager").get("active_slot"))
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"Unique Market-only actual Field output")
	var args:=OS.get_cmdline_user_args()
	_check("--luoyang-market-live-module-only-key" in args and not "--world-v15-candidate" in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args and not GATE.FLAG in args and not MARKET.FLAG in args,"Ordinary single Market key without candidate flags")
	_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==ENGINE_SHA,"Installed GPU engine ordinary clock")
	for path: String in NEW_PINS:
		source_before[path]=_file(path)
		_check(source_before[path].exists and source_before[path].sha256==NEW_PINS[path],"Frozen current source/helper "+path)
	source_before[PARENT_SOURCE]=_file(PARENT_SOURCE)
	_check(source_before[PARENT_SOURCE].exists and source_before[PARENT_SOURCE].sha256==PARENT_SHA,"Exact reviewed parent helper, failed whole remains frozen")
	source_before[get_script().resource_path]=_file(get_script().resource_path)
	var published: Dictionary=MARKET.runtime_manifest()
	_check(not published.is_empty() and published.get("asset_sha256") is Dictionary,"Exact existing Market runtime manifest")
	for path: String in MARKET.source_paths():
		if not source_before.has(path): source_before[path]=_file(path)
	for path: String in published.get("asset_sha256",{}):
		if not source_before.has(path): source_before[path]=_file(path)
		_check(source_before[path].sha256==published.asset_sha256[path],"Complete published Market source/import catalog "+path)
	_check(not C._records.has(String(MARKET.ID)),"Fresh process Market record cache empty; OS file cache uncontrolled")
	driver=INPUT_DRIVER.new(); driver.call("configure",self)
	if failures==0:
		for id: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(id).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		observe_live=true; process_frame.connect(_live_frame)
		await _ordinary_key()
	observe_live=false
	if process_frame.is_connected(_live_frame): process_frame.disconnect(_live_frame)
	while loading_capture_pending>0 and Time.get_ticks_msec()<deadline: await process_frame
	if oracle!=null:
		_check(bool(oracle.call("verify_sources")),"Final independent navigation sources unchanged")
		oracle.call("release"); oracle=null
	mask=null; polygons.clear(); packet.clear(); manifest.clear()
	if driver!=null: driver.call("release"); driver=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	_check(_sources()==source_before and _players()==players_before and root.get_node("SaveManager").get("active_slot")==prior_slot and bridge.call("is_checkpoint_saves_suspended")==true,"All source/player15/slot guards unchanged; checkpoints held to quit")
	_check(Time.get_ticks_msec()<deadline and transitions.size()==1 and captures.size()==1 and loading_captures.size()==1 and module_receipts.has(String(MARKET.ID)) and not module_receipts.has(GATE_ID),"NEW shared150/arrival60 one real Market Space, actual module, one Loading+oneField PNG complete")
	var result: Dictionary={"scope":MARKET_ONLY_SCOPE,"complete":failures==0,"checks":checks,"failures":failures,"records":rows,"transitions":transitions,"arrival_observations":observations,"loading_progress_samples":progress_samples,"per_tag_timings":tag_stats,"module_frame_observations":module_stats,"actual_module_receipts":module_receipts,"Field_captures":captures,"Loading_captures":loading_captures,"elapsed_ms":Time.get_ticks_msec()-live_started,"budget_ms":MARKET_ONLY_BUDGET_MS,"each_arrival_ms":60000,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"world_or_Gate_travel_tested":false,"Yamen_setup_excluded_from_Market_performance":true,"explicit_Yamen_setup_local_version":C.VERSION,"QA_full_source_oracle_excluded_from_loading_performance":true,"cold_scope":"Fresh process Market cache; OS file cache uncontrolled","old_failed_Gate_Market_whole_overridden":false,"full_six_or_full_city_completion_credit":false,"loading_speed_or_smoothness_approved":false,"audio_credit":false,"ROOT_outer_exactticks_and_complete_stderr_review_required":true}
	_save_evidence("result.json",result)
	print("LUOYANG_MARKET_LIVE_MODULE_ONLY_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures)+" elapsed_ms="+str(result.elapsed_ms))
	quit(0 if failures==0 else 1)
