extends "res://tests/test_luoyang_market_enrichment_key_20261014.gd"
## NEW formal boot only; reuse source/875/full17/Physics utilities, not candidate _run.
## No movement/fade/portal/full gameplay repeat. Exactly one ordinary public entry.
const CANDIDATE_KEY_PATH := "res://tests/test_luoyang_market_enrichment_key_20261014.gd"
const CANDIDATE_KEY_SHA := "396ede6e4bacd9d6ca60aaf75afff40b61c2d64d51f52fdf3124d2c4bc608403"
const CANONICAL_MARKET_PATH := "res://data/scenes/ch4_s3_luoyang_market.tres"
const ADOPTED_SCENE_SHA := "2b998f84d251b608f1224956d56a91a49317eee4cb615a32e4dc4ca26c510cfc"

func _exercise() -> void:
	if not _source_market(): return
	var started: int = Time.get_ticks_msec()
	if not _check(bool(root.get_node("SceneRouter").call("go_field_smart",StringName(MARKET_ID),null,"",-1,3)),"one ordinary public formal market startup"): return
	if not await _wait_field(MARKET_ID) or not _bind(): return
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	var player: Node2D = field.get("_player") as Node2D
	var good: bool = scene != null and scene.resource_path == CANONICAL_MARKET_PATH and scene.map_layout.resource_path == MARKET.LAYOUT_PATH and MARKET.bound(scene) and player.position.distance_to(Vector2(1536,1860)) < .03 and _clear(player.position)
	_check(good,"canonical formal identity and original spawn1860 full875/full17/Physics")
	rows.append({"kind":"FORMAL_MARKET_BOOT_ONLY","actual_scene_path":scene.resource_path if scene != null else "MISSING","actual_layout_path":scene.map_layout.resource_path if scene != null else "MISSING","actual_foot":player.position,"raw17":oracle.call("foot_evidence",player.position),"raw875":_body_raw(player.position),"Physics":_physical(player.position),"objects":26,"ordinary_entry_elapsed_ms":Time.get_ticks_msec()-started,"credit":"ONE_FORMAL_BOOT_NOT_LOADING_BENCHMARK","formal_all_gameplay_approved":false})
	weak_fade = weakref(field.get("_v14_modular_overlap"))
	await _capture("formal_market_spawn")

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true,"checkpoint held before first await")
	players_before = _players(); prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	prior_navigation = (root.get_node("SceneRouter").call("get_navigation_state") as Dictionary).duplicate(true)
	deadline = Time.get_ticks_msec()+90000
	output = "res://build/joint_world_luoyang_20261003_qa/market_enrichment_formal_boot_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK,"new formal-only evidence directory")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_check("--luoyang-market-enrichment-formal-boot" in args and not MARKET.FLAG in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args and not "--luoyang-gate-fortification-candidate" in args,"explicit formal boot forbids candidate selection flags")
	_check(DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower() == ENGINE_SHA,"real GPU ordinary clock/frozen GUI engine")
	for path: String in MARKET_PINS:
		source_before[path] = _file(path)
		_check(MARKET_PINS[path].length() == 64 and source_before[path].sha256 == MARKET_PINS[path],"same frozen market implementation/publication "+path)
	for path: String in [CANDIDATE_KEY_PATH,CANONICAL_MARKET_PATH,get_script().resource_path]: source_before[path] = _file(path)
	_check(source_before[CANDIDATE_KEY_PATH].sha256 == CANDIDATE_KEY_SHA and source_before[CANONICAL_MARKET_PATH].sha256 == ADOPTED_SCENE_SHA and source_before[CANONICAL_MARKET_PATH].sha256 == source_before[MARKET.SCENE_PATH].sha256,"immutable candidate helpers and exact recoverable adopted Scene bytes")
	for path: String in MARKET.source_paths(): source_before[path] = _file(path)
	for path: String in [C.layout_path(StringName(MARKET_ID)),C.manifest_path(StringName(MARKET_ID)),C.base_manifest_path(StringName(MARKET_ID)),C.ground_manifest_path(StringName(MARKET_ID))]: source_before[path] = _file(path)
	driver = INPUT_DRIVER.new(); driver.call("configure",self)
	if failures == 0:
		for id: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(id).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		await _exercise()
	if oracle != null: _check(bool(oracle.call("verify_sources")),"final independent formal mask stable"); oracle.call("release"); oracle = null
	mask = null; polygons.clear(); market_record.clear(); market_manifest.clear()
	if driver != null: driver.call("release"); driver = null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	if weak_fade != null: _check(weak_fade.get_ref() == null,"formal dedicated fade releases on local test exit")
	root.get_node("SceneRouter").call("restore_navigation_state",prior_navigation,&"world_map_jianghu",&"world_map_jianghu")
	_check(_sources() == source_before and _players() == players_before and root.get_node("SaveManager").get("active_slot") == prior_slot and bridge.call("is_checkpoint_saves_suspended") == true,"formal sources/current15player/slot preserved, checkpoint held through cleanup")
	_check(rows.size() == 2 and gallery.size() == 1 and arrival_observations.size() == 1 and fade_observations.is_empty(),"source plus one formal birth and one GPU only, no candidate full rerun")
	var result: Dictionary = {"scope":"ONE_NO_FLAGS_FORMAL_MARKET_BOOT_NOT_FULL_CITY_APPROVAL","complete":failures == 0,"checks":checks,"failures":failures,"records":rows,"gallery":gallery,"arrivals":arrival_observations,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"actual_audio_driver":AudioServer.get_driver_name(),"audio_credit":false,"normal_movement_fade_portal_tested":false,"tasks_battles_full_saves_tested":false,"formal_all_gameplay_approved":false,"exactticks_guard":"ROOT_OUTER_REQUIRED"}
	_save("result.json",result)
	print("MARKET_ENRICHMENT_FORMAL_BOOT_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures == 0 else 1)
