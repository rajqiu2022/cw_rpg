extends "res://tests/helpers/cold_sha_qa_retry2_20261017k.gd"
const SOURCE_READY=true
const HELPER_PATH="res://build/luoyang_cold_source_sha_20261017k_source01/parallel_source_hash.gd"
const HELPER_SHA="80b9b63ec0262524c3cf49fa181520a53c83498a39d2088498f9043bca78095b"
const UTILITY_SHA="001717611f3ec5a8f3cd3df518471f51a3b7c213bfe9592d48bb619b14919102"
const EVIDENCE="res://build/luoyang_live_city_ordinary_warm_20261017j/22920_2528/result.json"
const EVIDENCE_SHA="29259d01fcdcc10be9e5129aafffddd74eebd6ed1beb25940a67e4087c7c8790"
var published_sources: Dictionary={}

func _initialize() -> void:
	atom_name="ACTUAL_624_FULLMAP_60S";budget_ms=60000;super._initialize()
func precheck() -> bool:
	if not check(SOURCE_READY,"Exact candidate helper frozen; no C prepare or live Field"): return false
	if not track(HELPER_PATH,HELPER_SHA) or not track("res://tests/helpers/cold_sha_qa_retry2_20261017k.gd",UTILITY_SHA) or not track(EVIDENCE,EVIDENCE_SHA): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	var evidence: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(EVIDENCE))
	if not check(evidence.get("complete")==true and evidence.get("failures")==0 and evidence.get("checks")==455,"Exact successful ordinary real-world Gate source identity"): return false
	var proofs: Array=[]
	for row: Dictionary in evidence.records:
		if row.get("kind")=="ACTUAL_GATE_FULL_SOURCE_PROOF": proofs.append(row.proof)
	if not check(proofs.size()==2 and proofs[0].get("sources_finalized")==true and proofs[1].get("sources_finalized")==true and proofs[0].sources==proofs[1].sources and proofs[0].sources.size()==624,"Complete624 actual owner first/final proof, not a guessed path subset"): return false
	published_sources=proofs[0].sources.duplicate(true)
	helper_script=load(HELPER_PATH) as Script
	return check(helper_script!=null and helper_script.can_instantiate(),"Pure helper Script can instantiate")

func exercise() -> bool:
	var expected: Dictionary={};var total_bytes:=0
	var started: int=Time.get_ticks_usec()
	for path: String in published_sources:
		if not check(Time.get_ticks_msec()<deadline and FileAccess.file_exists(path),"Actual complete-map file exists within fixed deadline "+path): return false
		var sha: String=FileAccess.get_sha256(path)
		if not check(sha.length()==64 and sha==published_sources[path],"Independent FileAccess complete SHA equals pinned actual624 source "+path): return false
		expected[path]=sha
		var current: Dictionary=fact(path,sha)
		if source_before.has(path) and not check(source_before[path]==current,"Source already tracked before serial reference unchanged "+path): return false
		source_before[path]=current;total_bytes+=int(current.bytes)
	var serial_usec: int=Time.get_ticks_usec()-started
	var timings: Dictionary={"independent_FileAccess_get_sha256_usec":serial_usec}
	for limit: int in [1,2,4]:
		var result: Dictionary=await run_job(expected.keys(),limit)
		if not result.get("ok",false): return false
		timings[str(limit)]=result.elapsed_usec
		if not check(result.hashes==expected and result.hashes.size()==624 and result.debug.complete and not result.debug.cancelled and String(result.debug.error).is_empty() and joined(result.debug,limit) and result.coordinator_joined and int(result.debug.completed_files)==624 and int(result.debug.read_bytes)==total_bytes,"All624 complete SHA exact against independent reference, worker limit"+str(limit)+", every child joined",result.debug): return false
	records.append({"kind":"FULL624_BENCHMARK","file_count":624,"bytes":total_bytes,"timings_usec":timings,"order":["independent_FileAccess",1,2,4],"same_OS_cache_state_not_claimed":true,"cold_Field_speedup_not_claimed":true,"selection":"ROOT_SELECTS_2_OR_4_FROM_ACTUAL_RESULTS_NOT_THIS_SCRIPT","native_Source_first_final_guard":"FULL624_REHASH_AFTER_TIMED_RUNS"})
	return failures==0


