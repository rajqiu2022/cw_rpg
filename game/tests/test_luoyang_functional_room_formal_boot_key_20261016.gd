extends "res://tests/test_luoyang_functional_rooms_field_key_retry3_20261016.gd"
## ROOT-approved executable: exact candidate108892 and sole helper-bool edit.
const FORMAL_ROOM_READY := true
const FORMAL_ROOM_PARENT_SHA := "6f04820c536c6ebdb8ae29307cf2bff04662bebad410e99e0525aa95e3cbbe5a"
const FORMAL_ROOM_CANDIDATE_RESULT := "res://build/luoyang_functional_rooms_field_key_20261016/108892_2625631/result.json"
const FORMAL_ROOM_CANDIDATE_SHA := "e6c13910912fb9e7df6a4e0406f5e13d7eb87ee7642f627eb5767a8635108bb1"
const FORMAL_ROOM_HELPER_SHA := "3f2c16da87f01f5b5b9c2f28cc355ba5c43715a337b96e1d57ee8b3193ef44ed"
const FORMAL_ROOM_FALSE_BACKUP := "res://build/luoyang_functional_formal_before_20261016_root01/helper_8C240E2E.source"

func _track_source(path: String,expected: String) -> bool:
	if path==ROOMS.SELF_PATH and expected==ROOM_HELPER_SHA: expected=FORMAL_ROOM_HELPER_SHA
	return super._track_source(path,expected)

func _precheck_revision() -> bool:
	if not _check(FORMAL_ROOM_READY,"Explicit ROOT one-bool formal approval required"): return false
	if not _track_source("res://tests/test_luoyang_functional_rooms_field_key_retry3_20261016.gd",FORMAL_ROOM_PARENT_SHA) or not _track_source(FORMAL_ROOM_CANDIDATE_RESULT,FORMAL_ROOM_CANDIDATE_SHA): return false
	var accepted: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FORMAL_ROOM_CANDIDATE_RESULT))
	if not _check(accepted.get("scope")=="TWO_MATCHED_FUNCTIONAL_ROOMS_NATIVE_TRIPS_AND_DISABLED_WAREHOUSE_PROBE_ONLY" and accepted.get("complete")==true and accepted.get("failures")==0 and accepted.get("trips",[]).size()==2 and not accepted.get("warehouse_probe",{}).is_empty() and C._equal_value(accepted.source_before,accepted.source_after) and C._equal_value(accepted.players_before,accepted.players_after),"Exact completed two-door native candidate proof and unchanged closed inputs/saves"): return false
	# Only this exact helper SHA is folded. All other candidate input SHA remain exact.
	for path: String in accepted.source_before:
		if not _track_source(path,String(accepted.source_before[path].sha256)): return false
	var before: Dictionary=_file(FORMAL_ROOM_FALSE_BACKUP)
	if not _check(before.exists and before.sha256==ROOM_HELPER_SHA,"Exact original false helper byte backup"): return false
	source_before[FORMAL_ROOM_FALSE_BACKUP]=before
	var literal:="const FORMAL_ENABLED := false"
	var text:=FileAccess.get_file_as_string(FORMAL_ROOM_FALSE_BACKUP)
	if not _check(text.count(literal)==1 and text.replace(literal,"const FORMAL_ENABLED := true")==FileAccess.get_file_as_string(ROOMS.SELF_PATH) and ROOMS.FORMAL_ENABLED and not ROOMS.FLAG in OS.get_cmdline_user_args(),"Complete-text sole bool edit; ordinary no candidate flags"): return false
	# Required utility state is initialized, not skipped with the candidate-only precheck.
	revision=load(REVISION_PATH) as Script
	var publication: Dictionary=PUBLICATIONS[MARKET_ID]
	if not _track_source(publication.result,publication.sha) or not _track_source(publication.manifest,publication.manifest_sha): return false
	proof=JSON.parse_string(FileAccess.get_file_as_string(publication.result))
	published=JSON.parse_string(FileAccess.get_file_as_string(publication.manifest))
	source_before[get_script().resource_path]=_file(get_script().resource_path)
	return _check(revision!=null and published.get("full_original_C_first")==true and published.get("Field_Physics_visual_QA")=="PENDING","Frozen revision/published original geometry initialized; no blind ready receipt")

func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+180000
	output="res://build/luoyang_functional_room_formal_boot_20261016/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players(); prior_slot=int(root.get_node("SaveManager").get("active_slot"))
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"Unique formal one-door output")
	var args:=OS.get_cmdline_user_args()
	_check("--luoyang-functional-room-formal-key" in args and not ROOMS.FLAG in args and not REVISION_FLAG in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args,"Ordinary formal key without candidate flags")
	_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1 and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"Actual installed normal-clock GPU engine")
	driver=INPUT_DRIVER.new(); driver.call("configure",self)
	var complete:=false
	if _precheck_revision() and failures==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		process_frame.connect(_resident_frame); process_frame.connect(_room_source_frame)
		complete=await _run_room_trip(ROOM_CASES[0])
	watch_resident_jobs=false
	for callback: Callable in [_resident_frame,_room_source_frame]:
		if process_frame.is_connected(callback): process_frame.disconnect(callback)
	root.get_node("SceneRouter").call("reset_for_new_game")
	retained=null; resident_initial_scene=null; retained_nav.clear()
	if oracle!=null: _check(bool(oracle.call("verify_sources")),"Final independent native geometry source identity"); oracle.call("release"); oracle=null
	mask=null; polygons.clear(); candidate_scene=null; functional_spec.clear()
	if driver!=null: driver.call("release"); driver=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	var after:=_sources(); var save_after:=_players()
	_check(after==source_before and save_after==players_before and root.get_node("SaveManager").get("active_slot")==prior_slot and bridge.call("is_checkpoint_saves_suspended")==true,"Full candidate input closure/new bool/15save/slot/checkpoint exact unchanged")
	_check(complete and Time.get_ticks_msec()<deadline and functional_trips.size()==1 and captures.size()==2,"Fixed180/arrival60/return2000 one ordinary smith door roundtrip only")
	_save_evidence("result.json",{"scope":"ORDINARY_FORMAL_SMITH_ONE_REAL_DOOR_ROUNDTRIP_ONLY","complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"budget_ms":180000,"arrival_ms":60000,"return_limit_ms":RETURN_LIMIT_MS,"trips":functional_trips,"records":rows,"captures":captures,"source_before":source_before,"source_after":after,"players_before":players_before,"players_after":save_after,"candidate_actual_result":FORMAL_ROOM_CANDIDATE_RESULT,"formal_sole_bool_helper_sha":FORMAL_ROOM_HELPER_SHA,"production_proofs":production_proofs,"production_finalized":production_finalized,"no_new_other_room_or_warehouse_credit":true,"ROOT_complete_stderr_exactticks_natural_exit_required":true})
	print("LUOYANG_FUNCTIONAL_FORMAL_KEY=",output,"result.json checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
