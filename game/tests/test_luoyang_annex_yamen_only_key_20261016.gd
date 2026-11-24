extends "res://tests/test_luoyang_annex_low_furniture_key_retry2_20261016.gd"
## Independent NEW90s Yamen-only key after preserved135s wrapper timeout.
## Reuses unchanged mask/continuous34x24/full875+17/nativePhysics utilities.
## No smithy, room entry, ghost station, resident trip or second public setup.
const YAMEN_SHARED_MS=90000
const YAMEN_PARENT_PATH="res://tests/test_luoyang_annex_low_furniture_key_retry2_20261016.gd"
const YAMEN_PARENT_SHA="0ab4b1f8befa6b68e336369897a9f64621a2d38d47eb9e7aaae89265bbd8b675"

func _precheck() -> bool:
	if not _track(YAMEN_PARENT_PATH,YAMEN_PARENT_SHA) or not _track(BASE_PATH,BASE_SHA): return false
	for path: String in FINAL_PINS:
		if not _track(path,FINAL_PINS[path]): return false
	annex=load(ANNEX_PATH)
	if not _check(KEY_READY and annex!=null and annex.enabled() and not annex.FORMAL_ENABLED and annex.FLAG in OS.get_cmdline_user_args(),"Exact new annex candidate only, independent Yamen scope"): return false
	var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(annex.BIND_PATH))
	if not _track(annex.BIND_PATH,annex.BIND_SHA): return false
	for path: String in config.source_sha256:
		if not source_before.has(path) and not _track(path,config.source_sha256[path]): return false
	if not _track(config.manifest_path,config.manifest_sha256): return false
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(config.manifest_path))
	manifest_records["ch4_s1_luoyang_yamen"]=manifest.record
	candidate_manifest_paths["ch4_s1_luoyang_yamen"]=config
	var canonical:=ResourceLoader.load("res://data/scenes/ch4_s1_luoyang_yamen.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var closure: Dictionary=C._transition_sources(canonical,false)
	if not _check(not closure.is_empty(),"Complete production-declared Yamen source closure, no preparation getter"): return false
	for path: String in closure:
		if not source_before.has(path) and not _track(path): return false
	for path: String in annex.source_paths():
		if not source_before.has(path) and not _track(path): return false
	return _track(get_script().resource_path)

func _exercise() -> bool:
	var setup: Dictionary={"id":"ch4_s1_luoyang_yamen","size":Vector2(3072,2048),"setup_foot":Vector2(2190,1260)}
	if not await _setup(setup): return false
	if not await _way(PackedVector2Array([Vector2(2190,1260),Vector2(2190,1220)]),"east_new_lane_short_INPUT_nativebody"): return false
	if not _check(_clear(Vector2(2190,1150)) and not _physical(Vector2(2640,1160)) and not _clear(Vector2(2640,1160)) and not _physical(Vector2(2110,1280)),"Old east-base corridor clear/new base and original wall still native-solid"): return false
	if not await _overview("yamen_annex_separation"): return false
	if not await _way(PackedVector2Array([Vector2(2190,1220),Vector2(2190,1100),Vector2(2050,1100),Vector2(2050,1080),Vector2(1100,1080),Vector2(860,1080),Vector2(860,1120)]),"east_court_west_lane_normal_INPUT"): return false
	return _check(_clear(Vector2(755,1050)) and not _physical(Vector2(590,1050)) and not _clear(Vector2(590,1050)),"West vacated old-base strip now clear/new annex still blocking; no invisible residual wall")

func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+YAMEN_SHARED_MS
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players()
	output="res://build/luoyang_annex_yamen_only_key_20261016/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var complete:=false
	if _precheck():
		_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1,"Actual normal-clock GPU")
		driver=INPUT.new(); driver.call("configure",self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4); initialized=true
		complete=await _exercise()
	if initialized: root.get_node("SceneRouter").call("reset_for_new_game")
	if driver!=null: driver.call("release"); driver=null
	if oracle!=null: oracle.call("release"); oracle=null
	field=null; scene=null
	if initialized and is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	if initialized: await process_frame; await process_frame
	var after: Dictionary={}
	for path: String in source_before: after[path]=_fact(path)
	var players_after:=_players()
	_check(after==source_before and players_after==players_before and bridge.call("is_checkpoint_saves_suspended")==true,"Exact full Yamen source/15save before-after; no restoration")
	_check(complete and Time.get_ticks_msec()<deadline,"Independent fixed90s/60arrival/one Yamen setup/two original lane tests")
	var file:=FileAccess.open(output.path_join("result.json"),FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"scope":"YAMEN_ONLY_TWO_ANNEX_LANES_NATIVE_PHYSICS_NOT_ROOM_REPLAY","complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"shared_ms":YAMEN_SHARED_MS,"arrival_ms":ARRIVAL_MS,"records":rows,"captures":captures,"source_before":source_before,"source_after":after,"players_before":players_before,"players_after":players_after,"prior26088_timeout_not_overwritten_or_reclassified":true},"\t")); file.close()
	else: failures+=1
	print("YAMEN_ONLY_KEY=",output,"/result.json")
	quit(0 if complete and failures==0 else 1)
