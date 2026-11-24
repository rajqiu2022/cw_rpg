extends SceneTree
## Two new visual scripts only. HUD copy removes its duplicate global name;
## the fixed production candidate remains byte-for-byte unchanged.
const FIXTURE: String="res://build/luoyang_city_full_rollout_20261022ap_qa01/visual_finish_autoload_parse_two_retry4_READY.json"
const FIXTURE_SHA: String="c9846f2866b574ee41062e11f34e7037a0806a80647681c3bfcfa40f5d81cf3f"
const LIMIT_MS: int=15000
var checks: int=0
var failures: Array[String]=[]
var first: Dictionary={}
var rows: Array[Dictionary]=[]
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures.append(label);printerr("AP_VISUAL_PARSE_FAIL ",label)
	return ok
func track(path: String,expected: String) -> bool:
	var actual: String=FileAccess.get_sha256(path)
	if not need(expected.length()==64 and actual==expected,"Exact frozen input "+path): return false
	first[path]=actual;return true
func parse_two() -> bool:
	if not need(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name()=="headless","Headless two-script parse only, no args"): return false
	if not need(root.get_node_or_null("GameState")!=null and root.get_node_or_null("SceneRouter")!=null and root.get_node_or_null("DialogPlayer")!=null and root.get_node_or_null("Inventory")!=null and root.get_node_or_null("PlatformBridge")!=null,"Deferred actual project autoload context"): return false
	if not track(FIXTURE,FIXTURE_SHA): return false
	var fixed: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(fixed is Dictionary and fixed.get("status")=="AP_TWO_VISUAL_CANDIDATES_AUTOLOAD_PARSE_ONLY" and fixed.get("limit_ms")==LIMIT_MS and fixed.get("rows") is Array and fixed.rows.size()==2 and fixed.get("source_sha256") is Dictionary,"Fixed two rows and exact independent source map"): return false
	for path: String in fixed.source_sha256:
		if not track(path,fixed.source_sha256[path]): return false
	var seen: Dictionary={}
	for row: Dictionary in fixed.rows:
		if not need(row.get("path") is String and row.get("methods") is Array and not row.methods.is_empty() and not seen.has(row.path),"Unique fixed script with methods"): return false
		seen[row.path]=true
		if not track(row.path,row.sha256): return false
	for row: Dictionary in fixed.rows:
		var script: Script=ResourceLoader.load(row.path,"Script",ResourceLoader.CACHE_MODE_IGNORE) as Script
		var compiled: bool=script!=null and script.resource_path==row.path and script.can_instantiate()
		need(compiled,"Actual Script compiles in autoload domain "+row.path)
		var signatures: Dictionary={}
		if compiled:
			var available: Dictionary={}
			for method: Dictionary in script.get_script_method_list(): available[String(method.name)]=method
			for name: String in row.methods:
				if not need(available.has(name),"Required method "+name): continue
				var signature: Dictionary=available[name]
				need(signature.get("args") is Array and signature.get("return") is Dictionary,"Method args and result descriptors "+name)
				signatures[name]=signature
		rows.append({"path":row.path,"sha256":row.sha256,"compiled":compiled,"method_signatures":signatures,"instances_created":0,"module_methods_called":0})
		script=null
	return failures.is_empty()
func _run() -> void:
	var began: int=Time.get_ticks_msec()
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	var complete: bool=parse_two()
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path);need(final[path]==first[path],"Parse input bytes unchanged "+path)
	need(Time.get_ticks_msec()-began<LIMIT_MS,"Original 15s bounded parse limit")
	var folder: String="res://build/luoyang_city_full_rollout_20261022ap_qa01/visual_two_autoload_parse/%d_%d"%[OS.get_process_id(),began]
	var report_path: String=folder.path_join("result.json")
	var writable: bool=not FileAccess.file_exists(report_path) and DirAccess.make_dir_recursive_absolute(folder)==OK
	need(writable,"NEW own result only")
	var report: Dictionary={"scope":"TWO_NEW_VISUAL_SCRIPTS_AUTOLOAD_PARSE_ONLY_NOT_RUNTIME","complete":complete and failures.is_empty(),"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"source_first":first,"source_final":final,"rows":rows,"instances_created":0,"candidate_methods_called":0,"public_requests":0,"Field_created":false,"geometry_or_collector_executed":false,"HUD_copy_only_global_class_line_removed":true,"production_candidates_modified":false,"prior_17_parse_replayed":false,"bare_parse_failures_retained":true,"UI_or_performance_admission":false}
	var output: FileAccess=FileAccess.open(report_path,FileAccess.WRITE) if writable else null
	if output==null: failures.append("RESULT_OPEN")
	else:
		output.store_string(JSON.stringify(report,"\t"));output.close()
	print("AP_VISUAL_TWO_PARSE_RESULT=",report_path)
	quit(0 if complete and failures.is_empty() else 1)
