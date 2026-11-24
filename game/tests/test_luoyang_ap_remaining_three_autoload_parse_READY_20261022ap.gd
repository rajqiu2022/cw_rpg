extends SceneTree
## Only remaining Router/resident/ENV scripts. The two actual parsed visual
## scripts are inherited facts, not loaded again. Shader bytes only declared.
const FIXTURE: String="res://build/luoyang_city_full_rollout_20261022ap_qa01/remaining_three_autoload_parse_READY.json"
const FIXTURE_SHA: String="d65edb444f6455a41ad689d86fe7097d0d1e09d3f4cf2292bba30712eba9a193"
const LIMIT_MS: int=15000
var checks: int=0
var failures: Array[String]=[]
var first: Dictionary={}
var rows: Array[Dictionary]=[]
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures.append(label);printerr("AP_REMAINING_THREE_PARSE_FAIL ",label)
	return ok
func track(path: String,expected: String) -> bool:
	var actual: String=FileAccess.get_sha256(path)
	if not need(expected.length()==64 and actual==expected,"Exact frozen input "+path): return false
	first[path]=actual;return true
func parse_three() -> bool:
	if not need(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name()=="headless","Headless three-script parse only, no args"): return false
	if not need(root.get_node_or_null("GameState")!=null and root.get_node_or_null("SceneRouter")!=null and root.get_node_or_null("DialogPlayer")!=null and root.get_node_or_null("Inventory")!=null and root.get_node_or_null("PlatformBridge")!=null,"Deferred actual project autoload context"): return false
	if not track(FIXTURE,FIXTURE_SHA): return false
	var fixed: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(fixed is Dictionary and fixed.get("status")=="AP_REMAINING_THREE_SCRIPTS_AUTOLOAD_PARSE_ONLY" and fixed.get("limit_ms")==LIMIT_MS and fixed.get("rows") is Array and fixed.rows.size()==3 and fixed.get("source_sha256") is Dictionary and fixed.get("shaders_declared_bytes_only_not_loaded_or_compiled") is Array,"Fixed three rows and exact declared source map"): return false
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
	var complete: bool=parse_three()
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path);need(final[path]==first[path],"Parse input bytes unchanged "+path)
	need(Time.get_ticks_msec()-began<LIMIT_MS,"Original 15s bounded parse limit")
	var folder: String="res://build/luoyang_city_full_rollout_20261022ap_qa01/remaining_three_autoload_parse/%d_%d"%[OS.get_process_id(),began]
	var report_path: String=folder.path_join("result.json")
	var writable: bool=not FileAccess.file_exists(report_path) and DirAccess.make_dir_recursive_absolute(folder)==OK
	need(writable,"NEW own result only")
	var report: Dictionary={"scope":"ONLY_REMAINING_THREE_ROUTER_RESIDENT_ENV_AUTOLOAD_PARSE_NOT_RUNTIME","complete":complete and failures.is_empty(),"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"source_first":first,"source_final":final,"rows":rows,"instances_created":0,"candidate_methods_called":0,"public_requests":0,"Field_created":false,"geometry_or_collector_executed":false,"production_candidates_modified":false,"prior_17_parse_replayed":false,"prior_two_visual_scripts_reloaded":false,"shader_load_or_compile_claimed":false,"bare_parse_failures_retained":true,"UI_or_performance_admission":false}
	var output: FileAccess=FileAccess.open(report_path,FileAccess.WRITE) if writable else null
	if output==null: failures.append("RESULT_OPEN")
	else:
		output.store_string(JSON.stringify(report,"\t"));output.close()
	print("AP_REMAINING_THREE_PARSE_RESULT=",report_path)
	quit(0 if complete and failures.is_empty() else 1)
