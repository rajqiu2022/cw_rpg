extends "res://tests/test_luoyang_revision_market_rooms_key_retry2_20261015.gd"
## DRAFT ONLY. ROOT must bind successful A/B evidence and its one boolean edit.
## No candidate _run, room trips, Gate/world, or full-city claim.
const FORMAL_FIXTURE_READY := false
const FORMAL_RUNTIME_SHA := "PENDING_ROOT_TRUE_RUNTIME_SHA"
const FALSE_RUNTIME_BACKUP := "PENDING_ROOT_FALSE_RUNTIME_EXACT_BACKUP"
const FALSE_RUNTIME_SHA := "da8faf3d85a4e7bb91ca74f05a1a630873be5f274d3fd7e12b8e2cb11d528a7e"
const FROZEN_PARENT_PATH := "res://tests/test_luoyang_revision_market_rooms_key_retry2_20261015.gd"
const FROZEN_PARENT_SHA := "91dcfbdde7c2222265ed1d14a037623e2253a0f44d9bb471a986d31050cda9fe"
const ACCEPTED_ATOMS := [
	{"path":"PENDING_A_SUCCESS_RESULT","sha":"PENDING_A_RESULT_SHA","scope":"LIMITED_CANDIDATE_MARKET_ROOMS"},
	{"path":"PENDING_B_SUCCESS_RESULT","sha":"PENDING_B_RESULT_SHA","scope":"LIMITED_CANDIDATE_DOCKS"}
]

func _precheck_revision() -> bool:
	if not _check(FORMAL_FIXTURE_READY,"DRAFT refuses execution until ROOT binds A/B and exact true-runtime source"): return false
	if not _track_source(FROZEN_PARENT_PATH,FROZEN_PARENT_SHA) or not _track_source(FALSE_RUNTIME_BACKUP,FALSE_RUNTIME_SHA) or not _track_source(REVISION_PATH,FORMAL_RUNTIME_SHA): return false
	var false_text:=FileAccess.get_file_as_string(FALSE_RUNTIME_BACKUP)
	var true_text:=FileAccess.get_file_as_string(REVISION_PATH)
	var old_literal:="const FORMAL_ENABLED := false"
	if not _check(false_text.count(old_literal)==1 and false_text.replace(old_literal,"const FORMAL_ENABLED := true")==true_text,"Only exact ROOT-authorized FORMAL_ENABLED false-to-true byte-text edit"): return false
	for path: String in RUNTIME_PINS:
		if not _track_source(path,FORMAL_RUNTIME_SHA if path==REVISION_PATH else String(RUNTIME_PINS[path])): return false
	for path: String in UTILITY_PINS:
		if not _track_source(path,UTILITY_PINS[path]): return false
	for atom: Dictionary in ACCEPTED_ATOMS:
		if not _track_source(atom.path,atom.sha): return false
		var evidence: Variant=JSON.parse_string(FileAccess.get_file_as_string(atom.path))
		if not _check(evidence is Dictionary and evidence.get("scope")==atom.scope and evidence.get("complete")==true and evidence.get("failures")==0 and evidence.get("source_before") is Dictionary,"Exact completed candidate atom, never old failed evidence "+atom.scope): return false
		for path: String in evidence.source_before:
			var expected: String=FORMAL_RUNTIME_SHA if path==REVISION_PATH else String(evidence.source_before[path].sha256)
			if not _track_source(path,expected): return false
	revision=load(REVISION_PATH) as Script
	if not _check(revision!=null and revision.get_script_constant_map().get("FORMAL_ENABLED")==true,"Actual frozen adapter default formal enabled"): return false
	var publication: Dictionary=PUBLICATIONS[MARKET_ID]
	if not _track_source(publication.result,publication.sha) or not _track_source(publication.manifest,publication.manifest_sha): return false
	proof=JSON.parse_string(FileAccess.get_file_as_string(publication.result))
	published=JSON.parse_string(FileAccess.get_file_as_string(publication.manifest))
	for path: String in revision.call("source_paths"):
		if not source_before.has(path): source_before[path]=_file(path)
		_check(source_before[path].exists,"Actual default runtime closed source exists "+path)
	source_before[get_script().resource_path]=_file(get_script().resource_path)
	return failures==0

func _run() -> void:
	var started:=Time.get_ticks_msec(); deadline=started+180000
	output="res://build/luoyang_revision_formal_boot_20261015/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players(); prior_slot=int(root.get_node("SaveManager").get("active_slot"))
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"Unique independent formal boot output")
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"Checkpoint writes held before first await")
	var args:=OS.get_cmdline_user_args()
	_check("--luoyang-formal-revision-boot-key" in args and not REVISION_FLAG in args and not "--luoyang-city-revision-candidate-retry2-20261015" in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args and not "--luoyang-market-enrichment-candidate-20261014" in args,"Ordinary formal boot without candidate selection flags")
	_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"Installed actual GPU engine ordinary clock")
	driver=INPUT_DRIVER.new(); driver.call("configure",self)
	if _precheck_revision() and failures==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		process_frame.connect(_frame_gap)
		if await _public_setup(Vector2(735,920)):
			var enabled: Array=(candidate_scene.map_layout.portals as Array).filter(func(portal: Dictionary)->bool:return portal.get("candidate_only",false)==true and portal.get("enabled",false)==true)
			var nodes: Array=field.get("_exit_nodes")
			_check(candidate_scene.get_meta("city_frontage_revision_runtime_status","")=="ROOT_APPROVED_DEFAULT_REVISION" and candidate_scene.map_layout.portals.size()==12 and enabled.size()==8 and nodes.size()==12,"Actual default formal Market12 portal nodes and eight enabled reviewed doors")
			if await _way(PackedVector2Array([Vector2(735,920),Vector2(735,890)]),"formal_native_normal_INPUT30px_only") and await _fade("inn",false,"formal_inn_front_alpha1"):
				rows.append(_state("ACTUAL_FORMAL_MARKET_AFTER_NORMAL30PX"))
				captures.append(await _capture_gate("ordinary_formal_market_front"))
	if process_frame.is_connected(_frame_gap): process_frame.disconnect(_frame_gap)
	if oracle!=null: _check(bool(oracle.call("verify_sources")),"Independent formal navigation source unchanged"); oracle.call("release"); oracle=null
	mask=null; polygons.clear(); candidate_scene=null
	if driver!=null: driver.call("release"); driver=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	_check(_sources()==source_before and _players()==players_before and root.get_node("SaveManager").get("active_slot")==prior_slot and bridge.call("is_checkpoint_saves_suspended")==true,"Exact formal source/15save/slot/checkpoint guards unchanged")
	_check(Time.get_ticks_msec()<deadline and captures.size()==1 and transitions.is_empty() and room_receipts.is_empty(),"Shared180/arrival60 one formal birth+normal30px+onePNG only")
	var result: Dictionary={"scope":"ORDINARY_FORMAL_MARKET_BOOT_ONLY_NOT_ROOM_OR_ALL_CITY_REPLAY","complete":failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-started,"budget_ms":180000,"arrival_ms":60000,"records":rows,"arrival_observations":observations,"captures":captures,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"candidate_actual_evidence":ACCEPTED_ATOMS,"only_authorized_production_delta":"Exact FORMAL_ENABLED false-to-true","room_or_Gate_or_world_travel_retested":false,"full_city_or_loading_speed_credit":false,"ROOT_outer_exactticks_and_complete_stderr_required":true}
	_save_evidence("result.json",result)
	print("LUOYANG_REVISION_FORMAL_BOOT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)
