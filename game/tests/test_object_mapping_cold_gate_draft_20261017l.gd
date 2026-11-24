extends "res://tests/test_cold_source_gate_entry_key_20261017k.gd"
## Same k observer/_busy/_exercise instrumentation and120/60. No warm/room/Market.
const L_READY=false
const L_BASE="res://tests/test_cold_source_gate_entry_key_20261017k.gd"
const L_CPU_RESULT="PENDING_ROOT_ACTUAL_MAPPING_CPU_RESULT"
const L_CPU_SHA="PENDING_ROOT_ACTUAL_MAPPING_CPU_SHA"
const L_TEMPLE_SHA="cf7e336ba9478c5650403c8653e4d1414655a0dea236167a1a703bdcafe05415"
const L_TEMPLE_BIND="res://data/maps/luoyang_temple_assembly_20261016/binding_object_mapping_receipt_v6.json"
const L_TEMPLE_BIND_SHA="489fe1501cf3ca5f6babadc34794b8c35a76dc415f8c7890e012ce65d4f9dae0"
const L_SOURCE_SHA={
	"res://scripts/dev/luoyang_v3_wall_v5_saved_resource_checker.gd":"17297869279c43e068e442e7269c57cc4d986b5b26c9a2374883d6ff97cb5481",
	"res://scripts/dev/luoyang_v3_wall_v5_note_saved_resource_checker.gd":"7e3dd58d49a628e7b9ae3af428f050526bc5c7b473873c93b10dde5908ff3825",
	"res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd":"2c2f2cbaf84afa92a585cd4eac2670c59be35c8fb33c0e4164d7469d228b48a3"}
const L_OLD_SHA={
	"res://scripts/dev/luoyang_v3_wall_v5_saved_resource_checker.gd":"1d7b01750b526df05084da3dc280ad27f662bfc6b3ee776a06aa025a0b886018",
	"res://scripts/dev/luoyang_v3_wall_v5_note_saved_resource_checker.gd":"10559051d50480fd1735bb8619b7e307ac654306115fa8b00d26d842795531d4",
	"res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd":"aa164d13ad1f0fe566a920c6b30810122354399b87ac70a53496514d4852e7df"}

func precheck() -> bool:
	if not check(L_READY and not FINAL_SOURCE_PINS.is_empty(),"Cold SHA deployment and both CPU evidence atoms must be frozen"): return false
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
	if not track(J_RESULT,J_SHA) or not track(TEMPLE_PATH,L_TEMPLE_SHA) or not track(TEMPLE_BIND,TEMPLE_BIND_SHA) or not track(L_TEMPLE_BIND,L_TEMPLE_BIND_SHA): return false
	if not track(L_BASE,"c71cdf4ef701d3520afd6f53773edad6341845f1baf5cfe664c2ff3c1ad02452") or not track(L_CPU_RESULT,L_CPU_SHA): return false
	var mapping_evidence: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(L_CPU_RESULT))
	if not check(mapping_evidence.get("complete")==true and mapping_evidence.get("failures")==0,"Actual successful limited old/new mapping and real workspace refusal proof"): return false
	for path: String in L_SOURCE_SHA:
		if not track(path,L_SOURCE_SHA[path]): return false
	var prior_result: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(J_RESULT))
	if not check(prior_result.get("complete")==true and prior_result.get("failures")==0,"Pinned actual ordinary j baseline successful"): return false
	var proofs: Array[Dictionary]=[]
	for row: Dictionary in prior_result.records:
		if row.get("kind")=="ACTUAL_GATE_FULL_SOURCE_PROOF": proofs.append(row.proof)
	if not check(proofs.size()==2,"Both actual cold/warm j finalized full source maps present"): return false
	for proof: Dictionary in proofs:
		if not check(proof.get("sources_finalized")==true and proof.get("sources",{}).size()==624,"Original exact624 maps are finalized, not fabricated count"): return false
	if not _exact_source_map(proofs[0].sources,proofs[1].sources,"Original j first/final actual maps identical"): return false
	expected_gate_sources=proofs[0].sources.duplicate(true)
	if not check(expected_gate_sources.get(C_PATH)=="82df07a7411aa10327485db7c9e7d90df7770defb4b677907a9bc0a57c62d1d1" and not expected_gate_sources.has(HASH_HELPER) and not expected_gate_sources.has(TEMPLE_PATH) and not expected_gate_sources.has(TEMPLE_BIND),"Exactly declared Gate dependency delta; Temple separately guarded, not invented Gate leaves"): return false
	expected_gate_sources[C_PATH]=EXPECTED_C_SHA
	expected_gate_sources[HASH_HELPER]=EXPECTED_HASH_SHA
	for path: String in L_SOURCE_SHA:
		if not check(expected_gate_sources.get(path)==L_OLD_SHA[path],"Only declared original/checker/base old value replacement "+path): return false
		expected_gate_sources[path]=L_SOURCE_SHA[path]
	var canonical: SceneScript=load("res://data/scenes/ch4_s0_luoyang_gate.tres")
	var actual_paths: Dictionary=C._transition_sources(canonical,false)
	if not _exact_source_paths(actual_paths,expected_gate_sources,"Current pure Gate collector exact independent expected path set"): return false
	records.append({"kind":"EXPECTED_COMPLETE_GATE_SOURCE_MAP","baseline_result":J_RESULT,"baseline_sha":J_SHA,"replaced":{C_PATH:EXPECTED_C_SHA},"added":{HASH_HELPER:EXPECTED_HASH_SHA},"l_only_replaced":L_SOURCE_SHA.duplicate(true),"expected_sources":expected_gate_sources.duplicate(true),"count":expected_gate_sources.size(),"temple_dependency_guarded_separately_not_collected":true,"no_duplicate_full_corpus_hash_in_test_precheck":true})
	return true


func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+120000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_object_mapping_cold_gate_20261017l/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
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
	finish(folder,began,complete,"ONE_REAL_WORLD96_SPACE_COLD_GATE32_MAPPING_RECEIPT_COMPLETE_SOURCE")






