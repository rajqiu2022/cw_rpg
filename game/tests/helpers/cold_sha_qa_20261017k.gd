extends SceneTree
## QA-owned plain-file jobs only. No Field/C preparation, GPU, or source writes.
var deadline: int
var checks:=0
var failures:=0
var records: Array[Dictionary]=[]
var source_before: Dictionary={}
var players_before: Dictionary={}
var folder: String
var helper_script: Script
var budget_ms:=30000
var atom_name: String="DRAFT"

func _initialize() -> void: call_deferred("_run")
func check(ok: bool,label: String,detail: Variant=null) -> bool:
	checks+=1
	if not ok: failures+=1;printerr("COLD_SHA_QA_FAIL ",label," ",detail)
	return ok
func fact(path: String,known_sha: String="") -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false,"sha256":"ABSENT","bytes":0,"mtime":0}
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {"exists":false,"sha256":"OPEN_FAILED","bytes":0,"mtime":0}
	var length: int=file.get_length();file.close()
	return {"exists":true,"sha256":known_sha if not known_sha.is_empty() else FileAccess.get_sha256(path),"bytes":length,"mtime":FileAccess.get_modified_time(path)}
func track(path: String,expected: String) -> bool:
	var actual: Dictionary=fact(path)
	if not check(actual.exists and expected.length()==64 and actual.sha256==expected.to_lower(),"Exact frozen source "+path): return false
	if source_before.has(path): return check(source_before[path]==actual,"Repeated source facts unchanged "+path)
	source_before[path]=actual;return true
func saves() -> Dictionary:
	var result: Dictionary={}
	for slot: int in 5:
		for suffix: String in [".json",".json.bak",".json.tmp"]:
			var path: String="user://save_"+str(slot)+suffix
			result[path]=fact(path)
	return result
func joined(debug: Dictionary,limit: int) -> bool:
	return int(debug.get("worker_limit",-1))==limit and int(debug.get("children_started",-1))==int(debug.get("children_joined",-2)) and int(debug.get("active_children",-1))==0 and not debug.get("running",true) and int(debug.get("peak_children",limit+1))<=limit
func run_job(paths: Array,limit: int,cancel_during_read: bool=false,pre_cancel: bool=false,external_owner: RefCounted=null) -> Dictionary:
	var job: RefCounted=helper_script.new()
	job.set("paths",paths.duplicate());job.set("worker_limit",limit)
	if external_owner!=null: job.set("external_cancel",external_owner.call.bind("stopped"))
	if pre_cancel: job.call("request_cancel")
	var thread:=Thread.new();var began: int=Time.get_ticks_usec()
	var start: Error=thread.start(job.call.bind("run"))
	if not check(start==OK,"QA coordinator Thread started without pool starvation"): return {"ok":false}
	var cancelled:=false;var trigger: Dictionary={};var cancel_at: int=0
	while thread.is_alive():
		var debug: Dictionary=job.call("debug_state")
		if cancel_during_read and not cancelled and int(debug.get("read_chunks",0))>0 and debug.get("running",false) and int(debug.get("completed_files",paths.size()))<paths.size():
			trigger=debug;cancel_at=Time.get_ticks_usec()
			if external_owner==null: job.call("request_cancel")
			else: external_owner.call("request_cancel")
			cancelled=true
		if Time.get_ticks_msec()>=deadline:
			job.call("request_cancel");check(false,"Fixed CPU atom deadline, cancel then join all children");break
		await process_frame
	thread.wait_to_finish()
	var ended: int=Time.get_ticks_usec()
	var result: Dictionary={"ok":true,"hashes":job.get("hashes").duplicate(true),"debug":job.call("debug_state"),"elapsed_usec":ended-began,"coordinator_joined":not thread.is_started(),"read_cancel_triggered":cancelled,"cancel_trigger":trigger,"cancel_until_all_joined_usec":ended-cancel_at if cancelled else 0}
	records.append({"kind":"JOB","limit":limit,"paths":paths,"cancel_during_read":cancel_during_read,"pre_cancel":pre_cancel,"result":result})
	return result
func precheck() -> bool: return check(false,"Draft must override exact frozen helper source")
func exercise() -> bool: return check(false,"Draft refuses before executable atom")
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+budget_ms
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_cold_source_sha_qa_20261017k/"+atom_name+"/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(folder)
	var complete:=false
	if precheck(): complete=await exercise()
	var source_after: Dictionary={}
	for path: String in source_before: source_after[path]=fact(path)
	var players_after: Dictionary=saves()
	check(source_before==source_after,"Whole own source first/final SHA/bytes/mtime equal")
	check(players_before==players_after and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"All15 real saves unchanged, suspended before first await; no restoration")
	check(complete and Time.get_ticks_msec()<deadline,"Fixed predeclared CPU atom, no extension")
	var report: Dictionary={"scope":atom_name,"complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"budget_ms":budget_ms,"records":records,"source_before":source_before,"source_after":source_after,"players_before":players_before,"players_after":players_after,"Field_or_GPU_credit":false}
	var file:=FileAccess.open(folder.path_join("result.json"),FileAccess.WRITE)
	if file==null: failures+=1
	else: file.store_string(JSON.stringify(report,"\t"));file.close()
	print("COLD_SHA_QA_RESULT=",folder,"/result.json")
	quit(0 if complete and failures==0 else 1)
