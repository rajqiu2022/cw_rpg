extends SceneTree
## Diagnostic instrumentation only. Never a formal source admission or gameplay PASS.
const HOME := "res://build/loading_20261106_system02/"
const FAMILY_PATH := "res://scripts/city/luoyang_quarters_family_20261022ap.gd"
var suspended := false
var failures: Array[String] = []
var rows: Array = []
var runtime: Variant=null
var protected_before: Dictionary = {}
var instrument_receipt: Dictionary = {}
func _initialize() -> void:
	root.child_entered_tree.connect(func(node: Node) -> void:
		if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
			node.call("set_checkpoint_saves_suspended",true)
			suspended=bool(node.call("is_checkpoint_saves_suspended")))
	_run.call_deferred()
func check(value: bool,name: String) -> bool:
	if not value: failures.append(name)
	return value
func record(name: String,start: int,okay: bool) -> void:
	rows.append({"phase":name,"us":Time.get_ticks_usec()-start,"guard_result":okay})
	check(okay,name)
func _run() -> void:
	await process_frame
	if not check(suspended,"EARLY_SAVE_SUSPEND"): finish();return
	instrument_receipt=JSON.parse_string(FileAccess.get_file_as_string(HOME+"instrumentation_receipt.json"))
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(HOME+"plan.json"))
	for path: String in plan.protected_sha256:
		protected_before[path]=FileAccess.get_sha256(path)
		check(protected_before[path]==plan.protected_sha256[path],"PROTECTED_PRE:"+path)
	if not failures.is_empty(): finish();return
	var formal: String=instrument_receipt.formal_path
	var candidate: String=instrument_receipt.candidate_path
	if not check(FileAccess.get_sha256(formal)==instrument_receipt.formal_sha256,"FORMAL_SHA") or not check(FileAccess.get_sha256(candidate)==instrument_receipt.candidate_sha256,"CANDIDATE_SHA"): finish();return
	var original_bytes: PackedByteArray=FileAccess.get_file_as_bytes(formal)
	var code: String=FileAccess.get_file_as_string(candidate)
	var inverse: String=code.replace(String(instrument_receipt.wrapper),"").replace("static func _diag_ensure_body(","static func ensure(")
	var changes: Array=instrument_receipt.changes.duplicate()
	changes.reverse()
	for change: Dictionary in changes:
		if not check(inverse.count(String(change.after))==1,"INVERSE_UNIQUE"): finish();return
		inverse=inverse.replace(String(change.after),String(change.before))
	if instrument_receipt.original_newline=="CRLF": inverse=inverse.replace("\n","\r\n")
	if not check(inverse.to_utf8_buffer()==original_bytes,"WHOLE_BYTE_INVERSE"): finish();return
	runtime=load(formal) as GDScript
	if not check(runtime!=null and runtime.resource_path==formal,"ORIGINAL_RESOURCE_PATH"): finish();return
	# Instrument same loaded script before any Family.ensure invocation; disk remains original.
	runtime.source_code=code
	if not check(runtime.reload()==OK,"DIAGNOSTIC_RELOAD"): finish();return
	var family: Variant=load(FAMILY_PATH)
	var id:=&"luoyang_artisan_residential_20261022ap"
	var start:=Time.get_ticks_usec()
	var okay: bool=family.validation_begin()
	record("FIRST",start,okay)
	if not okay: finish();return
	start=Time.get_ticks_usec()
	var path: String=family.scene_path(id)
	record("scene_path",start,not path.is_empty())
	if path.is_empty(): finish();return
	start=Time.get_ticks_usec()
	var scene: SceneScript=load(path) as SceneScript
	record("scene_load",start,scene!=null)
	if scene==null: finish();return
	start=Time.get_ticks_usec()
	okay=family.matches(scene)
	record("cold_matches_including_ensure",start,okay)
	if not okay: finish();return
	start=Time.get_ticks_usec()
	okay=family.validation_finish()
	record("FINAL",start,okay)
	var receipt: Dictionary=family.validation_receipt()
	rows.append({"phase":"original_receipt_scalars","source_count":receipt.get("source_first",{}).size(),"full_source_hash_passes":receipt.get("full_source_hash_passes",0),"first_hash_elapsed_us":receipt.get("first_hash_elapsed_us",-1),"final_hash_elapsed_us":receipt.get("final_hash_elapsed_us",-1),"finalized":receipt.get("finalized",false)})
	finish()
func finish() -> void:
	var after: Dictionary={}
	for path: String in protected_before:
		after[path]=FileAccess.get_sha256(path)
		check(after[path]==protected_before[path],"PROTECTED_POST:"+path)
	var calls: Array=runtime.diagnostic_calls() if runtime!=null and runtime.has_method("diagnostic_calls") else []
	var cold_measured:=false
	for call_row: Dictionary in calls:
		if call_row.get("scene_id")!="luoyang_artisan_residential_20261022ap" or call_row.get("ok")!=true: continue
		for segment: Dictionary in call_row.get("segments",[]):
			if segment.get("phase")=="object_textures_all": cold_measured=true
	check(cold_measured,"TARGET_COLD_ENSURE_ACTUALLY_MEASURED")
	var target:=HOME+"actual/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(target)
	var file:=FileAccess.open(target+"/finish_phase_result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"status":"IN_MEMORY_DIAGNOSTIC_ONLY_NOT_FORMAL_ADMISSION_OR_FUNCTIONAL_PASS","diagnostic_completed":failures.is_empty(),"failures":failures,"rows":rows,"ensure_calls":calls,"protected_before":protected_before,"protected_after":after,"formal_file_writes":false,"real_save_content_access":false,"limitations":"Fresh process, OS file cache uncontrolled, headless texture costs not equal GPU travel. Nested per-item values already included in phase totals. Instrumentation overhead included. No timing baseline overwritten."},"\t")+"\n")
	file.close()
	print("FINISH_PHASE_DIAGNOSTIC ",failures.size()," ",target)
	quit(0 if failures.is_empty() else 1)
