extends "res://tests/test_world_gate_stable_import_entry_key_20261017.gd"
## One normal world96/Space cold Gate/32px only. No warm or rooms.
const COLD_READY=false
const C_PATH="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const EXPECTED_C_SHA="PENDING_ROOT_FINAL_C"
const RESIDENT_PATH="res://scripts/city/luoyang_resident_field_20261016.gd"
const HASH_HELPER="res://scripts/city/luoyang_parallel_source_hash_20261017k.gd"
const EXPECTED_HASH_SHA="PENDING_ROOT_FINAL_HELPER"
const BENCH_HELPER="res://build/luoyang_cold_source_sha_20261017k_source01/parallel_source_hash.gd"
const OLD_C_BACKUP="res://build/luoyang_cold_source_sha_20261017k_source01/C_82DF_before.source"
const BASE_ENTRY="res://tests/test_world_gate_stable_import_entry_key_20261017.gd"
const CHOSEN_LIMIT=2
const FIXTURE_RESULT="PENDING_ROOT_FIXTURE_RESULT"
const FIXTURE_SHA="PENDING_ROOT_FIXTURE_SHA"
const FULLMAP_RESULT="PENDING_ROOT_FULLMAP_RESULT"
const FULLMAP_SHA="PENDING_ROOT_FULLMAP_SHA"
var profile_target: String=""
var profile_last_usec:=0
var frame_gaps_usec: Dictionary={}
var source_intervals: Array[Dictionary]=[]
var source_interval: Dictionary={}
func precheck() -> bool:
	if not check(COLD_READY and not FINAL_SOURCE_PINS.is_empty(),"Cold SHA deployment and both CPU evidence atoms must be frozen"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0,"Real GPU/native clock"): return false
	for argument: String in OS.get_cmdline_user_args():
		if not check(not argument.contains("candidate") and argument!="--luoyang-live-city-lease-20261016g","No candidate or warm flags"): return false
	if not track(BASE_ENTRY,"055c5dcac7f6fcade80c8408041914bcd594ece674962522b341f955009de55f") or not track(OLD_C_BACKUP,"82df07a7411aa10327485db7c9e7d90df7770defb4b677907a9bc0a57c62d1d1"): return false
	for path: String in FINAL_SOURCE_PINS:
		var expected: String=EXPECTED_C_SHA if path==C_PATH else ("f1730e461fe6328763cfd70c79b2bbc36c80a2afb7609c364fa7ea7af8acdd7f" if path==RESIDENT_PATH else FINAL_SOURCE_PINS[path])
		if not track(path,expected): return false
	if not check(OS.get_cmdline_user_args().is_empty() and CHOSEN_LIMIT in [2,4],"Ordinary no flags; explicit actual CPU-selected bounded default"): return false
	if not track(HASH_HELPER,EXPECTED_HASH_SHA) or not track(BENCH_HELPER,"80b9b63ec0262524c3cf49fa181520a53c83498a39d2088498f9043bca78095b"): return false
	var prior: String=FileAccess.get_file_as_string(BENCH_HELPER)
	if not check(prior.replace("const DEFAULT_WORKER_LIMIT := 2","const DEFAULT_WORKER_LIMIT := "+str(CHOSEN_LIMIT))==FileAccess.get_file_as_string(HASH_HELPER),"Production helper is tested whole source with only chosen default literal delta"): return false
	for row: Dictionary in [{"path":FIXTURE_RESULT,"sha":FIXTURE_SHA},{"path":FULLMAP_RESULT,"sha":FULLMAP_SHA}]:
		if not track(row.path,row.sha): return false
		var evidence: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(row.path))
		if not check(evidence.get("complete")==true and evidence.get("failures")==0,"Exact successful independent SHA CPU atom, not discarded failed result"): return false
	var approval: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(STABLE.APPROVAL_PATH))
	for path: String in approval.source_sha256:
		if not track(path,approval.source_sha256[path]): return false
	var historical: Dictionary=GATE.runtime_manifest()
	if not check(historical.get("asset_sha256",{}).size()==56,"Original immutable56 catalog, no historical pin rewrite"): return false
	var authorized: int=0;var unchanged: int=0
	for path: String in historical.asset_sha256:
		if STABLE.handles(path):
			var effective: String=STABLE.effective_sha(path,historical.asset_sha256[path])
			if not check(effective.length()==64,"Actual FINAL exact8 approval plus raw/import/ctex pair identity") or not track(path,effective): return false
			authorized+=1
		else:
			if not track(path,historical.asset_sha256[path]): return false
			unchanged+=1
	if not check(authorized==8 and unchanged==48,"Only exact8 variants; remaining48 actual historical SHA unchanged"): return false
	for paths: Dictionary in [STABLE.source_paths(),OFFICE.source_paths()]:
		for path: String in paths:
			if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	if not track(R.BIND_PATH,FINAL_BIND_SHA): return false
	package=R.binding();author=R.author(package)
	if not check(R.cpu_proof_valid(package,author),"Existing district CPU geometry reused; no old city rebuild"): return false
	for path: String in R.source_paths():
		if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	for path: String in [get_script().resource_path,"res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd","res://data/scenes/world_map_jianghu.tres"]:
		if not track(path,FileAccess.get_sha256(path)): return false
	return true

func _wait_once(target: String,source_id: String="") -> bool:
	profile_target=target;profile_last_usec=Time.get_ticks_usec()
	return await super._wait_once(target,source_id)

func _busy() -> bool:
	var now: int=Time.get_ticks_usec()
	if profile_last_usec>0:
		frame_gaps_usec[profile_target]=maxi(int(frame_gaps_usec.get(profile_target,0)),now-profile_last_usec)
	profile_last_usec=now
	var state: Dictionary=C.transition_validation_state()
	var active: bool=state.get("source_worker_active",false)
	if active and source_interval.is_empty():
		source_interval={"start_usec":now,"token":C._live_source_token,"target":profile_target,"start_frame":Engine.get_process_frames(),"observed_frames":0}
	if active: source_interval.observed_frames=int(source_interval.observed_frames)+1
	elif not source_interval.is_empty():
		source_interval["end_usec"]=now;source_interval["observed_usec"]=now-int(source_interval.start_usec);source_interval["end_frame"]=Engine.get_process_frames()
		source_intervals.append(source_interval.duplicate(true));source_interval={}
	return super._busy()

func _exercise() -> bool:
	var complete: bool=await super._exercise()
	if not complete: return false
	var proof: Dictionary=C.resident_receipt(scene)
	if not check(proof.get("sources_finalized")==true and proof.get("sources",{}).get(C_PATH)==EXPECTED_C_SHA and proof.sources.get(HASH_HELPER)==EXPECTED_HASH_SHA and source_before.get(HASH_HELPER,{}).get("sha256")==EXPECTED_HASH_SHA,"Actual complete first/final Gate owner includes exact new C/helper, no count-only receipt"): return false
	records.append({"kind":"COLD_ACTUAL_PROFILE","actual_source_count":proof.sources.size(),"source_first_finalized":proof.sources_finalized,"source_worker_frame_observations":source_intervals,"max_wait_frame_gap_usec":frame_gaps_usec,"C_native_phase_timings":C.transition_validation_state(),"Loading_metrics":root.get_node("LoadingManager").call("get_field_preload_metrics"),"chosen_default_workers":CHOSEN_LIMIT,"source_interval_is_frame_observed_not_hash_only_stopwatch":true,"warm_or_room_tested":false})
	return true

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+120000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_cold_source_gate_entry_20261017k/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete:=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
		if not await _leave_actual_field(): complete=false
		root.get_node("SceneRouter").call("reset_for_new_game");await process_frame;await process_frame
	if driver!=null: driver.release();driver=null
	field=null;scene=null;oracle=null;frame_images.clear()
	records.append({"kind":"SCOPE","whole_ms":120000,"arrival_ms":60000,"captures":captures,"native_queries":native_queries,"warm_or_rooms":false,"whole_city_or_story_tested":false})
	finish(folder,began,complete,"ONE_REAL_WORLD96_SPACE_COLD_GATE32_COMPLETE_SOURCE")

