extends "res://tests/test_world_gate_stable_import_entry_key_20261017.gd"
## o: one ordinary world96/Space Gate32. Diagnostic five token-bound tail rows only; no new tree/module CPU atom.
const COLD_READY=true
const SLICE_RESULT="res://build/luoyang_cold_source_sha_qa_20261017k/TREE_PAIR_REUSE_20261017N_30S/57656_2497/result.json"
const SLICE_SHA="aac57405ca3ab241e14aba16c34b27f34e083ff4853d46c38c64897e4550c9ad"
const C_PATH="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const EXPECTED_C_SHA="06244b1dc286149ce8299cd83f766d2d9f5fd9b61bcb59180261dff40d8e9d3d"
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
const TEMPLE_SHA="a85a521825c9af4cd5faf44a6e2952eefcadccde4a06e2409213be7ef177c08c"
const TEMPLE_BIND="res://data/maps/luoyang_temple_assembly_20261016/binding_tail_profile_v9.json"
const TEMPLE_BIND_SHA="62d91b80ef217bd3192cbab9d1cf9c846ed04e85e1664887b14ba04bb3941a55"
const M_CPU_RESULT="res://build/luoyang_cold_source_sha_qa_20261017k/MODULE_SOURCE_RECEIPT_20261017M_30S/93528_1684/result.json"
const M_CPU_SHA="8401f4dfeff6af4bc2b23f8b7174f2b6485b47b92d66c3eda63ef7a3d49d73fc"
const BASELINE_RESULT="res://build/luoyang_tree_pair_cold_gate_20261017n/108616_2528/result.json"
const BASELINE_SHA="8f54a420bf0c46ff5af899129a1c604a077d419a6c394efb3b64348840a9c0de"
const M_SOURCE_SHA={
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"3deb7395e2441f94068377c905e5a9e85222416c672834bbfad1754b22ac50ca",
	"res://scripts/city/luoyang_module_live_cpu_20261015.gd":"95f1c05c217868857f91da21bae460cc27e7813a47e907dc47dec3bbaa3560e0",
	"res://scripts/city/luoyang_gate_fortification_contract_20261013.gd":"23719d1be5633ddf681c08ae220fb1196853bfc54894b08c484a48a2df0121b3",
	"res://scripts/city/luoyang_gate_stable_imports_20261017.gd":"29001631c265538b8d89a7aa13896017bdd49b74d1396bd488c7a810153cd784"}
const N_SOURCE_SHA={
	"res://scripts/dev/luoyang_v3_wall_v5_saved_resource_checker.gd":"fb11c1dd600587666a00fec57c67aea4ae597fb1f8a3302fdd6746117c2fcff5",
	"res://scripts/dev/luoyang_v3_wall_v5_note_saved_resource_checker.gd":"3b07679017af1b8fc02fcf4a5940c41af0707572ada8964cb287a64d3fe6ec53",
	"res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd":"ee8fbd88436817c7eaedac159a3563034b806340f4c777f3650b5d6c60768b0b"}
const O_SOURCE_SHA={
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"06244b1dc286149ce8299cd83f766d2d9f5fd9b61bcb59180261dff40d8e9d3d",
	"res://scripts/city/luoyang_harbour_life_runtime_20261016.gd":"26e2e263426719878cd6e7853878d25277e25483cbb495bb3df44116efc6b5b8"}
const O_OLD_SHA={
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"3deb7395e2441f94068377c905e5a9e85222416c672834bbfad1754b22ac50ca",
	"res://scripts/city/luoyang_harbour_life_runtime_20261016.gd":"1e1e52210dbe7d5e1158ca9521835eb5f9f4d0e59b8f049141e8143e9b371cae"}
const TAIL_LABELS=["tail.harbour.import_readback","tail.harbour.materialize_serialized","tail.nav.commit","tail.proof.publish","tail.packet.validate"]
const TAIL_INTEGER_FIELDS=["token","count","total_usec","max_usec","first_started_usec","first_started_frame","last_started_usec","last_finished_usec","last_started_frame","last_finished_frame","max_started_usec","max_finished_usec","max_started_frame","max_finished_frame"]
var expected_gate_sources: Dictionary={}
var profile_target: String=""
var profile_last_usec:=0
var frame_gaps_usec: Dictionary={}
var source_intervals: Array[Dictionary]=[]
var source_interval: Dictionary={}
var max_gap_events: Dictionary={}
var previous_gap_state: Dictionary={}
var previous_gap_frame: int=0
func precheck() -> bool:
	if not check(COLD_READY and TEMPLE_SHA.length()==64 and TEMPLE_BIND_SHA.length()==64 and not FINAL_SOURCE_PINS.is_empty(),"o is NOTREADY until final diagnostic deployment and v9 are pinned"): return false
	if not track(SLICE_RESULT,SLICE_SHA): return false
	var slice: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SLICE_RESULT))
	if not check(slice.get("complete")==true and slice.get("failures")==0 and slice.get("budget_ms")==30000,"Pinned successful isolated real Mesh pair slice, not a repeated cold preflight"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0,"Real GPU/native clock"): return false
	for argument: String in OS.get_cmdline_user_args():
		if not check(not argument.contains("candidate") and argument!="--luoyang-live-city-lease-20261016g","No candidate or warm flags"): return false
	if not track(BASE_ENTRY,"055c5dcac7f6fcade80c8408041914bcd594ece674962522b341f955009de55f") or not track(OLD_C_BACKUP,"82df07a7411aa10327485db7c9e7d90df7770defb4b677907a9bc0a57c62d1d1"): return false
	for path: String in FINAL_SOURCE_PINS:
		var expected: String=O_SOURCE_SHA[path] if O_SOURCE_SHA.has(path) else (N_SOURCE_SHA[path] if N_SOURCE_SHA.has(path) else (M_SOURCE_SHA[path] if M_SOURCE_SHA.has(path) else ("f1730e461fe6328763cfd70c79b2bbc36c80a2afb7609c364fa7ea7af8acdd7f" if path==RESIDENT_PATH else FINAL_SOURCE_PINS[path])))
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
	if not track(BASELINE_RESULT,BASELINE_SHA) or not track(M_CPU_RESULT,M_CPU_SHA) or not track(TEMPLE_PATH,TEMPLE_SHA) or not track(TEMPLE_BIND,TEMPLE_BIND_SHA): return false
	if not track("res://tests/test_cold_source_gate_entry_key_20261017k.gd","c71cdf4ef701d3520afd6f53773edad6341845f1baf5cfe664c2ff3c1ad02452"): return false
	var cpu: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(M_CPU_RESULT))
	if not check(cpu.get("complete")==true and cpu.get("failures")==0,"Exact successful OLD/NEW whole module packet and receipt rejection evidence"): return false
	var prior_result: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BASELINE_RESULT))
	if not check(prior_result.get("complete")==true and prior_result.get("failures")==0,"Actual ordinary n full625 evidence successful"): return false
	var proofs: Array[Dictionary]=[]
	for row: Dictionary in prior_result.records:
		if row.get("kind")=="ACTUAL_GATE_FULL_SOURCE_PROOF": proofs.append(row.proof)
	if not check(proofs.size()==1 and proofs[0].get("sources_finalized")==true and proofs[0].get("sources",{}).size()==625,"Actual n finalized625 full map, not count-only reconstruction"): return false
	expected_gate_sources=proofs[0].sources.duplicate(true)
	if not check(expected_gate_sources.get(HASH_HELPER)==EXPECTED_HASH_SHA and not expected_gate_sources.has(TEMPLE_PATH) and not expected_gate_sources.has(TEMPLE_BIND),"Original four-thread source helper unchanged; Temple guard not invented Gate leaves"): return false
	for path: String in M_SOURCE_SHA:
		if path==C_PATH: continue
		if not check(expected_gate_sources.get(path)==M_SOURCE_SHA[path],"Unchanged m Module/Gate/Stable source "+path) or not track(path,M_SOURCE_SHA[path]): return false
	for path: String in N_SOURCE_SHA:
		if not check(expected_gate_sources.get(path)==N_SOURCE_SHA[path],"Unchanged n Original/Note/BASE source "+path) or not track(path,N_SOURCE_SHA[path]): return false
	for path: String in O_SOURCE_SHA:
		if not check(expected_gate_sources.get(path)==O_OLD_SHA[path],"Declared exact n old value for diagnostic source "+path) or not track(path,O_SOURCE_SHA[path]): return false
		expected_gate_sources[path]=O_SOURCE_SHA[path]
	var canonical: SceneScript=load("res://data/scenes/ch4_s0_luoyang_gate.tres")
	var actual_paths: Dictionary=C._transition_sources(canonical,false)
	if not _exact_source_paths(actual_paths,expected_gate_sources,"Current pure Gate collector exact independent expected path set"): return false
	records.append({"kind":"EXPECTED_COMPLETE_GATE_SOURCE_MAP","baseline_result":BASELINE_RESULT,"baseline_sha":BASELINE_SHA,"replaced":O_SOURCE_SHA.duplicate(true),"n_three_sources_unchanged":N_SOURCE_SHA.duplicate(true),"added":{},"expected_sources":expected_gate_sources.duplicate(true),"count":expected_gate_sources.size(),"temple_dependency_guarded_separately_not_collected":true,"no_duplicate_full_corpus_hash_in_test_precheck":true})
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
	profile_target=target;profile_last_usec=Time.get_ticks_usec();previous_gap_state={};previous_gap_frame=Engine.get_process_frames()
	return await super._wait_once(target,source_id)

func _gap_scalar_state(state: Dictionary) -> Dictionary:
	var small: Dictionary={}
	for key: String in ["active","token","scene_id","sources_finalized","source_worker_active","navigation_worker_active","revision_worker_active","base_cpu_worker_active","BASE_live_active","BASE_live_phase","BASE_last_completed_stage"]:
		var value: Variant=state.get(key)
		if typeof(value) in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING]: small[key]=value
	return small

func _busy() -> bool:
	var now: int=Time.get_ticks_usec()
	var frame: int=Engine.get_process_frames()
	var gap: int=now-profile_last_usec if profile_last_usec>0 else 0
	var old_max: int=int(frame_gaps_usec.get(profile_target,0))
	if profile_last_usec>0:
		frame_gaps_usec[profile_target]=maxi(old_max,gap) # Original m maximum computation unchanged.
	profile_last_usec=now
	var state: Dictionary=C.transition_validation_state() # Original once-per-poll query, no extra full-source snapshot.
	var small: Dictionary=_gap_scalar_state(state)
	if gap>old_max and profile_target in ["world_map_jianghu","ch4_s0_luoyang_gate"]:
		max_gap_events[profile_target]={"gap_usec":gap,"observed_at_usec":now,"previous_frame":previous_gap_frame,"observed_frame":frame,"previous_state":previous_gap_state.duplicate(true),"observed_state":small.duplicate(true),"bounded_last_max_per_target":true,"between_polls_not_unique_causal_attribution":true}
	previous_gap_state=small;previous_gap_frame=frame
	var active: bool=state.get("source_worker_active",false)
	if active and source_interval.is_empty():
		source_interval={"start_usec":now,"token":C._live_source_token,"target":profile_target,"start_frame":Engine.get_process_frames(),"observed_frames":0}
	if active: source_interval.observed_frames=int(source_interval.observed_frames)+1
	elif not source_interval.is_empty():
		source_interval["end_usec"]=now;source_interval["observed_usec"]=now-int(source_interval.start_usec);source_interval["end_frame"]=Engine.get_process_frames()
		source_intervals.append(source_interval.duplicate(true));source_interval={}
	return super._busy()

func _tail_profile(proof: Dictionary,state: Dictionary,captured_usec: int,captured_frame: int) -> bool:
	var actual_token: Variant=proof.get("token")
	if not check(typeof(actual_token)==TYPE_INT and actual_token>0 and String(proof.get("id"))=="ch4_s0_luoyang_gate","Actual completed resident proof token/scene, not reset live_source_token"): return false
	var timings: Variant=state.get("main_stage_timings")
	if not check(timings is Dictionary,"Actual same-frame C main_stage_timings value snapshot"): return false
	var tail_keys: Array[String]=[]
	for key: String in timings:
		if key.begins_with("tail."): tail_keys.append(key)
	if not check(tail_keys.size()==TAIL_LABELS.size(),"Exactly five fixed diagnostic tail groups, not timer-count success"): return false
	for label: String in TAIL_LABELS:
		var row: Variant=timings.get(label)
		if not check(row is Dictionary and row.size()==TAIL_INTEGER_FIELDS.size()+1,label+" complete exact scalar schema"): return false
		for name: String in TAIL_INTEGER_FIELDS:
			if not check(typeof(row.get(name))==TYPE_INT and row[name]>=0,label+" native nonnegative INT "+name): return false
		if not check(typeof(row.get("scene_id"))==TYPE_STRING and row.scene_id=="ch4_s0_luoyang_gate" and row.token==actual_token and row.count>=1,label+" same actual token/scene and positive count"): return false
		if not check(row.first_started_usec<=row.last_started_usec and row.last_started_usec<=row.last_finished_usec and row.last_finished_usec<=captured_usec and row.first_started_usec<=row.max_started_usec and row.max_started_usec<=row.max_finished_usec and row.max_finished_usec<=row.last_finished_usec,label+" monotonic start/end/capture bounds"): return false
		if not check(row.first_started_frame<=row.last_started_frame and row.last_started_frame<=row.last_finished_frame and row.last_finished_frame<=captured_frame and row.first_started_frame<=row.max_started_frame and row.max_started_frame<=row.max_finished_frame and row.max_finished_frame<=row.last_finished_frame,label+" monotonic native frame bounds"): return false
		if not check(row.max_finished_usec-row.max_started_usec==row.max_usec and row.total_usec>=row.max_usec and row.last_finished_usec-row.last_started_usec<=row.max_usec,label+" internally exact maximum span/total; no exclusive-time sum claim"): return false
	records.append({"kind":"TOKEN_BOUND_TAIL_PROFILE_COMPLETE","actual_token":actual_token,"scene_id":String(proof.id),"captured_usec":captured_usec,"captured_frame":captured_frame,"rows":timings.duplicate(true),"packet_count_may_exceed_one":true,"durations_may_nest_no_sum_equals_whole_assertion":true})
	return true

func _exercise() -> bool:
	var complete: bool=await super._exercise()
	if not complete: return false
	var proof: Dictionary=C.resident_receipt(scene)
	if not check(proof.get("sources_finalized")==true and proof.get("sources",{}).get(C_PATH)==EXPECTED_C_SHA and proof.sources.get(HASH_HELPER)==EXPECTED_HASH_SHA and source_before.get(HASH_HELPER,{}).get("sha256")==EXPECTED_HASH_SHA,"Actual complete first/final Gate owner includes exact new C/helper, no count-only receipt"): return false
	if not _exact_source_map(proof.sources,expected_gate_sources,"Actual complete finalized Gate proof equals independent full expected map"): return false
	var profile_state: Dictionary=C.transition_validation_state()
	var captured_usec: int=Time.get_ticks_usec();var captured_frame: int=Engine.get_process_frames()
	if not _tail_profile(proof,profile_state,captured_usec,captured_frame): return false
	records.append({"kind":"COLD_ACTUAL_PROFILE","actual_source_count":proof.sources.size(),"source_first_finalized":proof.sources_finalized,"source_worker_frame_observations":source_intervals,"max_wait_frame_gap_usec":frame_gaps_usec,"C_native_phase_timings":profile_state,"Loading_metrics":root.get_node("LoadingManager").call("get_field_preload_metrics"),"chosen_default_workers":CHOSEN_LIMIT,"source_interval_is_frame_observed_not_hash_only_stopwatch":true,"warm_or_room_tested":false,"max_gap_events":max_gap_events.duplicate(true),"instrumentation_changed_from_m":true,"new_instrumentation":"one bounded last-new-maximum scalar event per target; phase observations are not unique causality"})
	return true

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+120000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_tail_profile_gate_20261017o/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
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
	finish(folder,began,complete,"ONE_REAL_WORLD96_SPACE_GATE32_TOKEN_BOUND_TAIL_PROFILE_COMPLETE_SOURCE")













