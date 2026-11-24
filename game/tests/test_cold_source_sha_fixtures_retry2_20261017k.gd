extends "res://tests/helpers/cold_sha_qa_retry2_20261017k.gd"
const SOURCE_READY=true
const HELPER_PATH="res://build/luoyang_cold_source_sha_20261017k_source01/parallel_source_hash.gd"
const HELPER_SHA="80b9b63ec0262524c3cf49fa181520a53c83498a39d2088498f9043bca78095b"
const UTILITY_SHA="001717611f3ec5a8f3cd3df518471f51a3b7c213bfe9592d48bb619b14919102"
class CancelOwner extends RefCounted:
	var mutex:=Mutex.new()
	var cancelled:=false
	func request_cancel() -> void:
		mutex.lock();cancelled=true;mutex.unlock()
	func stopped() -> bool:
		mutex.lock();var value: bool=cancelled;mutex.unlock();return value

func _initialize() -> void:
	atom_name="FIXTURES_ONLY_30S";budget_ms=30000;super._initialize()
func precheck() -> bool:
	if not check(SOURCE_READY,"Exact candidate helper frozen, not production installation"): return false
	if not track(HELPER_PATH,HELPER_SHA) or not track("res://tests/helpers/cold_sha_qa_retry2_20261017k.gd",UTILITY_SHA): return false
	if not track("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","82df07a7411aa10327485db7c9e7d90df7770defb4b677907a9bc0a57c62d1d1"): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	helper_script=load(HELPER_PATH) as Script
	return check(helper_script!=null and helper_script.can_instantiate(),"Pure helper Script can instantiate")

func _fixture(name: String,count: int,seed: int) -> String:
	var path: String=folder.path_join(name)
	if not check(path.begins_with(folder+"/") and not FileAccess.file_exists(path),"New QA-owned fixture path only"): return ""
	var bytes:=PackedByteArray();bytes.resize(count);bytes.fill(seed)
	if count>0:
		bytes[0]=(seed+17)%256;bytes[count >> 1]=(seed+31)%256;bytes[count-1]=(seed+47)%256
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if not check(file!=null,"Own fixture create"): return ""
	file.store_buffer(bytes)
	var valid: bool=file.get_error()==OK and file.get_length()==count
	file.close();bytes.clear()
	if not check(valid,"Complete fixture bytes written before any readers"): return ""
	return path

func _negative(paths: Array,limit: int,label: String,pre_cancel: bool=false) -> bool:
	var result: Dictionary=await run_job(paths,limit,false,pre_cancel)
	if not result.get("ok",false): return false
	return check(result.hashes.is_empty() and joined(result.debug,limit) and not result.debug.complete and (result.debug.cancelled if pre_cancel else not String(result.debug.error).is_empty()),label,result)

func exercise() -> bool:
	var paths: Array=[];var expected: Dictionary={};var total_bytes:=0
	var sizes: Array[int]=[0,1,31,63,64,65,1048575,1048576,1048577,4194321]
	for index: int in sizes.size():
		var path: String=_fixture("boundary_%02d.bin"%index,sizes[index],31+index)
		if path.is_empty(): return false
		paths.append(path);expected[path]=FileAccess.get_sha256(path);source_before[path]=fact(path,expected[path]);total_bytes+=sizes[index]
	if not check(expected[paths[0]]=="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855","Existing empty file is valid full SHA, not missing file"): return false
	var large: Array=[]
	for index: int in 4:
		var path: String=_fixture("cancel_%d_32MiB.bin"%index,32*1024*1024,70+index)
		if path.is_empty(): return false
		large.append(path);paths.append(path);expected[path]=FileAccess.get_sha256(path);source_before[path]=fact(path,expected[path]);total_bytes+=32*1024*1024
	for limit: int in [2,4]:
		var good: Dictionary=await run_job(paths,limit)
		if not good.get("ok",false): return false
		if not check(good.hashes==expected and good.debug.complete and not good.debug.cancelled and String(good.debug.error).is_empty() and joined(good.debug,limit) and int(good.debug.completed_files)==paths.size() and int(good.debug.read_bytes)==total_bytes and good.coordinator_joined,"Every boundary/full file digest exact against independent FileAccess SHA; bounded all children joined",good): return false
	if not await _negative([paths[0],folder.path_join("INTENTIONAL_MISSING.bin"),large[0]],4,"Mixed missing batch rejects every partial hash and joins all started children"): return false
	if not await _negative(paths,4,"Pre-cancel publishes no SHA and joins without children",true): return false
	for invalid: Dictionary in [{"paths":[],"limit":2},{"paths":[paths[0],paths[0]],"limit":2},{"paths":[StringName(paths[0])],"limit":2},{"paths":[paths[0]],"limit":3}]:
		if not await _negative(invalid.paths,invalid.limit,"Invalid empty/duplicate/non-String/limit domain rejects before child allocation"): return false
	for limit: int in [2,4]:
		var external: RefCounted=CancelOwner.new() if limit==2 else null
		var cancelled: Dictionary=await run_job(large,limit,true,false,external)
		if not cancelled.get("ok",false): return false
		if not check(cancelled.read_cancel_triggered and int(cancelled.cancel_trigger.read_chunks)>0 and int(cancelled.cancel_trigger.completed_files)<large.size() and cancelled.hashes.is_empty() and cancelled.debug.cancelled and not cancelled.debug.complete and joined(cancelled.debug,limit) and cancelled.coordinator_joined,"Actual read-in-progress cooperative direct/external cancellation empties result and joins every child, not a pre-cancel",cancelled): return false
	records.append({"kind":"SCOPE","fixture_bytes":total_bytes,"paths":paths.size(),"READ_CHUNK_BYTES":1048576,"children_peak_means":"STARTED_NOT_YET_JOINED_NOT_SIMULTANEOUS_CPU","token_owner":"UNCHANGED_ORIGINAL_C_SOURCE_REVIEW_NOT_FAKE_FIELD","production_source_modified":false,"real_saved_files_written":false})
	return failures==0


