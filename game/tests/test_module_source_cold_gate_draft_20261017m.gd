extends "res://tests/test_world_gate_stable_import_entry_key_20261017.gd"
## One normal world96/Space cold Gate/32px only. No warm or rooms.
const COLD_READY=false
const C_PATH="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const EXPECTED_C_SHA="3deb7395e2441f94068377c905e5a9e85222416c672834bbfad1754b22ac50ca"
const RESIDENT_PATH="res://scripts/city/luoyang_resident_field_20261016.gd"
const HASH_HELPER="res://scripts/city/luoyang_parallel_source_hash_20261017k.gd"
const EXPECTED_HASH_SHA="80261e1bf9b34400c6aa99959d98502b648589fccf2138231f3907d9826d8b0b"
const BENCH_HELPER="res://build/luoyang_cold_source_sha_20261017k_source01/parallel_source_hash.gd"
const OLD_C_BACKUP="res://build/luoyang_cold_source_sha_20261017k_source01/C_82DF_before.source"
const BASE_ENTRY="res://tests/test_world_gate_stable_import_entry_key_20261017.gd"
const CHOSEN_LIMIT=4
const FIXTURE_RESULT="res://build/luoyang_cold_source_sha_qa_20261017k/FIXTURES_ONLY_30S/33324_1627/result.json"
const FIXTURE_SHA="6b9223ef3442dc8aa221a919c7471d0eb6332c5de167937963dd65885d0d3846"
const FULLMAP_RESULT="res://build/luoyang_cold_source_sha_qa_20261017k/ACTUAL_624_FULLMAP_60S/103704_1610/result.json"
const FULLMAP_SHA="e650a9e619181218e5769c9fc893d7c945ad5d02e54bbe616a87820ebbecdae8"
const J_RESULT="res://build/luoyang_live_city_ordinary_warm_20261017j/22920_2528/result.json"
const J_SHA="29259d01fcdcc10be9e5129aafffddd74eebd6ed1beb25940a67e4087c7c8790"
const TEMPLE_PATH="res://scripts/city/luoyang_temple_assembly_20261016.gd"
const TEMPLE_SHA="9584e0046565c4fcb8ebfb0576b02b8f321b472e20da49564269cee3df782974"
const TEMPLE_BIND="res://data/maps/luoyang_temple_assembly_20261016/binding_module_source_receipt_v7.json"
const TEMPLE_BIND_SHA="acaf16f21e0c6e7dbfcf3c71e471a5b26caf1ec6a6dfe36818ec323b99675952"
const M_CPU_RESULT="PENDING_ROOT_MODULE_CPU_RESULT"
const M_CPU_SHA="PENDING_ROOT_MODULE_CPU_SHA"
const L_RESULT="res://build/luoyang_object_mapping_cold_gate_20261017l/83180_2534/result.json"
const L_SHA="02037915cad7c7389b2b25777ee51545c51a1ce274a2ca73856da7434998e26a"
const M_SOURCE_SHA={
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"3deb7395e2441f94068377c905e5a9e85222416c672834bbfad1754b22ac50ca",
	"res://scripts/city/luoyang_module_live_cpu_20261015.gd":"95f1c05c217868857f91da21bae460cc27e7813a47e907dc47dec3bbaa3560e0",
	"res://scripts/city/luoyang_gate_fortification_contract_20261013.gd":"23719d1be5633ddf681c08ae220fb1196853bfc54894b08c484a48a2df0121b3",
	"res://scripts/city/luoyang_gate_stable_imports_20261017.gd":"29001631c265538b8d89a7aa13896017bdd49b74d1396bd488c7a810153cd784"}
const M_OLD_SHA={
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"9ca2f4615e576e45b20b2a8cd2b59b07b097095a7199009ba2c7d42877709374",
	"res://scripts/city/luoyang_module_live_cpu_20261015.gd":"780af073facaba7a5dc469df5de6bca1b6c698c2b95a85c1389511d900b2a63e",
	"res://scripts/city/luoyang_gate_fortification_contract_20261013.gd":"62a9f85d9ee8cd6cd295c089a70060809c1df14d896b66027a269ef0cbd3caa7",
	"res://scripts/city/luoyang_gate_stable_imports_20261017.gd":"f43f74f88b1971d99c5c18f380072638cd646dcc323a384c1e88f6dc55af4ded"}
var expected_gate_sources: Dictionary={}
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
		var expected: String=M_SOURCE_SHA[path] if M_SOURCE_SHA.has(path) else ("f1730e461fe6328763cfd70c79b2bbc36c80a2afb7609c364fa7ea7af8acdd7f" if path==RESIDENT_PATH else FINAL_SOURCE_PINS[path])
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
	if not track(L_RESULT,L_SHA) or not track(M_CPU_RESULT,M_CPU_SHA) or not track(TEMPLE_PATH,TEMPLE_SHA) or not track(TEMPLE_BIND,TEMPLE_BIND_SHA): return false
	if not track("res://tests/test_cold_source_gate_entry_key_20261017k.gd","c71cdf4ef701d3520afd6f53773edad6341845f1baf5cfe664c2ff3c1ad02452"): return false
	var cpu: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(M_CPU_RESULT))
	if not check(cpu.get("complete")==true and cpu.get("failures")==0,"Exact successful OLD/NEW whole module packet and receipt rejection evidence"): return false
	var prior_result: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(L_RESULT))
	if not check(prior_result.get("complete")==true and prior_result.get("failures")==0,"Actual ordinary l full625 evidence successful"): return false
	var proofs: Array[Dictionary]=[]
	for row: Dictionary in prior_result.records:
		if row.get("kind")=="ACTUAL_GATE_FULL_SOURCE_PROOF": proofs.append(row.proof)
	if not check(proofs.size()==1 and proofs[0].get("sources_finalized")==true and proofs[0].get("sources",{}).size()==625,"Actual l finalized625 full map, not j-count reconstruction"): return false
	expected_gate_sources=proofs[0].sources.duplicate(true)
	if not check(expected_gate_sources.get(HASH_HELPER)==EXPECTED_HASH_SHA and not expected_gate_sources.has(TEMPLE_PATH) and not expected_gate_sources.has(TEMPLE_BIND),"Original four-thread source helper unchanged; Temple guard not invented Gate leaves"): return false
	for path: String in M_SOURCE_SHA:
		if not check(expected_gate_sources.get(path)==M_OLD_SHA[path],"Declared prior exact value for module-only replacement "+path) or not track(path,M_SOURCE_SHA[path]): return false
		expected_gate_sources[path]=M_SOURCE_SHA[path]
	var canonical: SceneScript=load("res://data/scenes/ch4_s0_luoyang_gate.tres")
	var actual_paths: Dictionary=C._transition_sources(canonical,false)
	if not _exact_source_paths(actual_paths,expected_gate_sources,"Current pure Gate collector exact independent expected path set"): return false
	records.append({"kind":"EXPECTED_COMPLETE_GATE_SOURCE_MAP","baseline_result":L_RESULT,"baseline_sha":L_SHA,"replaced":M_SOURCE_SHA.duplicate(true),"added":{},"expected_sources":expected_gate_sources.duplicate(true),"count":expected_gate_sources.size(),"temple_dependency_guarded_separately_not_collected":true,"no_duplicate_full_corpus_hash_in_test_precheck":true})
	return true

func _exact_source_paths(actual: Dictionary,expected: Dictionary,label: String) -> bool:
	var same: bool=actual.size()==expected.size()
	var missing: Array=[];var extra: Array=[]
	for path: String in expected:
		if not actual.has(path): missing.append(path);same=false
	for path: String in actual:
		if not expected.has(path): extra.append(path);same=false
	if not same: records.append({"kind":"SOURCE_PATH_DIFFERENCE","label":label,"missing":missing,"extra":extra})
	return check(same,label)

func _exact_source_map(actual: Dictionary,expected: Dictionary,label: String) -> bool:
	if not _exact_source_paths(actual,expected,label+" paths"): return false
	var differences: Array=[]
	for path: String in expected:
		if not actual[path] is String or actual[path]!=expected[path]:
			differences.append({"path":path,"expected":expected[path],"actual":actual[path]})
	if not differences.is_empty(): records.append({"kind":"SOURCE_SHA_DIFFERENCE","label":label,"differences":differences})
	return check(differences.is_empty(),label+" every complete SHA")

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
	if not _exact_source_map(proof.sources,expected_gate_sources,"Actual complete finalized Gate proof equals independent full expected map"): return false
	records.append({"kind":"COLD_ACTUAL_PROFILE","actual_source_count":proof.sources.size(),"source_first_finalized":proof.sources_finalized,"source_worker_frame_observations":source_intervals,"max_wait_frame_gap_usec":frame_gaps_usec,"C_native_phase_timings":C.transition_validation_state(),"Loading_metrics":root.get_node("LoadingManager").call("get_field_preload_metrics"),"chosen_default_workers":CHOSEN_LIMIT,"source_interval_is_frame_observed_not_hash_only_stopwatch":true,"warm_or_room_tested":false})
	return true

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+120000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_module_source_cold_gate_20261017m/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
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
	finish(folder,began,complete,"ONE_REAL_WORLD96_SPACE_COLD_GATE32_MODULE_RECEIPT_COMPLETE_SOURCE")





