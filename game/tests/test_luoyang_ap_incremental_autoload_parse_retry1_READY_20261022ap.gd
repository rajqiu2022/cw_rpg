extends SceneTree
## AP incremental ORIGINAL-path syntax atom. Root deployed only inactive family dependency.
## Never instantiates candidates or calls readiness/authority/projection/publisher/runtime methods.
const FIXTURE: String="res://build/luoyang_city_full_rollout_20261022ap_qa01/incremental_autoload_parse_retry1_READY.json"
const FIXTURE_SHA: String="dfe549f3b77028ffb0ba1eb9b2aa30ae1abf1fbea67eb024e0fcf2d7de15506b"
const LIMIT_MS: int=15000
var checks: int=0
var failures: Array[String]=[]
var first: Dictionary={}
var rows: Array[Dictionary]=[]
var fixed: Dictionary={}
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures.append(label);printerr("AP_INCREMENTAL_PARSE_FAIL ",label)
	return ok
func track(path: String,expected: String) -> bool:
	var actual: String=FileAccess.get_sha256(path)
	if not need(expected.length()==64 and actual==expected,"Exact frozen input "+path): return false
	first[path]=actual;return true
func parse_group() -> bool:
	if not need(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name()=="headless","Headless original-path parse only, no args"): return false
	if not need(root.get_node_or_null("GameState")!=null and root.get_node_or_null("SceneRouter")!=null and root.get_node_or_null("PlatformBridge")!=null,"Deferred established autoload context"): return false
	if not track(FIXTURE,FIXTURE_SHA): return false
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(value is Dictionary and value.get("status")=="AP_INCREMENTAL_PARSE_CURRENT_FROZEN_BYTES_NOT_RUNTIME_ADMISSION" and value.get("limit_ms")==LIMIT_MS and value.get("rows") is Array and value.rows.size()==17,"Exact10 main candidates +2 execution wrappers +5 necessary helper scripts"): return false
	fixed=value
	if not track(fixed.graph_path,fixed.graph_sha256) or not track(fixed.canonical_preload_dependency.path,fixed.canonical_preload_dependency.sha256): return false
	var seen: Dictionary={}
	# Verify ALL exact input bytes before parsing any member, no mid-group auto-pin.
	for row: Dictionary in fixed.rows:
		if not need(row.get("path") is String and row.get("methods") is Array and not row.methods.is_empty() and not seen.has(row.path),"Unique original script + explicit required methods"): return false
		seen[row.path]=true
		if not track(row.path,row.sha256): return false
	for row: Dictionary in fixed.rows:
		var script: Script=ResourceLoader.load(row.path,"Script",ResourceLoader.CACHE_MODE_IGNORE) as Script
		var compiled: bool=script!=null and script.resource_path==row.path and script.can_instantiate()
		need(compiled,"Original exact path real Script compiles "+row.path)
		var signatures: Dictionary={}
		if compiled:
			var available: Dictionary={}
			for method: Dictionary in script.get_script_method_list(): available[String(method.name)]=method
			for name: String in row.methods:
				if not need(available.has(name),"Required method present "+row.path+":"+name): continue
				var signature: Dictionary=available[name]
				need(signature.get("args") is Array and signature.get("return") is Dictionary,"Typed method descriptor args/result domain "+name)
				signatures[name]=signature
		rows.append({"path":row.path,"sha256":row.sha256,"original_path_load":true,"compiled":compiled,"method_signatures":signatures,"instances_created":0,"module_methods_called":0})
		script=null
	# Collect every parse failure in this one group; no success is borrowed from old NPC check.
	return failures.is_empty()
func _run() -> void:
	var began: int=Time.get_ticks_msec()
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	var complete: bool=parse_group()
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path);need(final[path]==first[path],"Whole own parse input unchanged "+path)
	need(Time.get_ticks_msec()-began<LIMIT_MS,"Predeclared15s incremental parse scope")
	var folder: String="res://build/luoyang_city_full_rollout_20261022ap_qa01/incremental_parse/%d_%d"%[OS.get_process_id(),began]
	var report_path: String=folder.path_join("result.json")
	var writable: bool=not FileAccess.file_exists(report_path) and DirAccess.make_dir_recursive_absolute(folder)==OK
	need(writable,"NEW own result only")
	var report: Dictionary={"scope":"AP_INCREMENTAL_ORIGINAL_PATH_SCRIPT_PARSE_ONLY_NOT_RUNTIME","complete":complete and failures.is_empty(),"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"source_first":first,"source_final":final,"rows":rows,"candidate_instances_created":0,"module_methods_executed":0,"source_projection_or_preload_rewrite":false,"readiness_publication_GUI_Field_NAV_save_writes":false,"prior_npc117632_retested":false,"environment_precheck_retested":false,"canonical_inactive_family_dependency":fixed.get("canonical_preload_dependency",{})}
	var output: FileAccess=FileAccess.open(report_path,FileAccess.WRITE) if writable else null
	if output==null: failures.append("RESULT_OPEN")
	else:
		output.store_string(JSON.stringify(report,"\t"));output.close()
	print("AP_INCREMENTAL_PARSE_RESULT=",report_path)
	quit(0 if complete and failures.is_empty() else 1)
