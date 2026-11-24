extends SceneTree
## AP parse-only atom. Root alone runs once; no Scene/Field/NPC instance or readiness call.
const LIMIT_MS: int=10000
const ROWS: Array[Dictionary]=[
	{"path":"res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation.gd","sha256":"1c1a43ecfc26f370a703790aacc77b692e0ee7f2ecac745821a5bd473a5bada7","methods":{"readiness":0,"source_paths":0,"identity_mapping":0,"compose_exact":3,"project":2,"daily_topics":2,"daily_topics_exact":3,"daily_handles":2,"validate_daily_identity":2,"validate_daily_identity_exact":3,"build_daily_menu":3}},
	{"path":"res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.gd","sha256":"dfdc530a1c020dbcc93b7a8c09118de59284d0774cfda4f258370ee4f0a9b2a7","methods":{"readiness":0,"source_paths":0,"defs_exact":2,"defs":1,"daily_handles_exact":3,"daily_handles":2,"validate_daily_identity_exact":3,"build_daily_menu":3}}
]
const DATA_PINS: Dictionary={
	"res://build/luoyang_city_full_rollout_20261022ap_npc01/author.json":"d51fa9ffce334601ecad4d114b39db78b24bbc71fef99ab3cfb10b5189720ed2",
	"res://build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.json":"74759592d13ae8dade98e8b44daed34d62ca0acd00387b1ee654d9d300609b9b"
}
const RETURN_TYPES: Dictionary={"readiness":TYPE_DICTIONARY,"source_paths":TYPE_DICTIONARY,"identity_mapping":TYPE_DICTIONARY,"compose_exact":TYPE_DICTIONARY,"project":TYPE_DICTIONARY,"daily_topics":TYPE_ARRAY,"daily_topics_exact":TYPE_ARRAY,"daily_handles":TYPE_BOOL,"daily_handles_exact":TYPE_BOOL,"validate_daily_identity":TYPE_DICTIONARY,"validate_daily_identity_exact":TYPE_DICTIONARY,"build_daily_menu":TYPE_DICTIONARY,"defs":TYPE_DICTIONARY,"defs_exact":TYPE_DICTIONARY}
var checks: int=0
var failures: Array[String]=[]
var first: Dictionary={}
var rows: Array[Dictionary]=[]
func _initialize() -> void: call_deferred("_run")
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures.append(label);printerr("AP_PARSE_FAIL ",label)
	return ok
func track(path: String,expected: String) -> bool:
	var actual: String=FileAccess.get_sha256(path)
	if not need(expected.length()==64 and actual==expected,"Exact frozen input "+path): return false
	first[path]=actual;return true
func parse_modules() -> bool:
	if not need(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name()=="headless","Headless autoload-established parse only, no args"): return false
	if not need(root.get_node_or_null("GameState")!=null and root.get_node_or_null("SceneRouter")!=null and root.get_node_or_null("PlatformBridge")!=null,"Autoload context exists before deferred Script load"): return false
	for path: String in DATA_PINS:
		if not track(path,DATA_PINS[path]): return false
	for row: Dictionary in ROWS:
		if not track(row.path,row.sha256): return false
		# Typed Script variable avoids static preload-class can_instantiate errors.
		var script: Script=ResourceLoader.load(row.path,"Script",ResourceLoader.CACHE_MODE_IGNORE) as Script
		if not need(script!=null and script.resource_path==row.path and script.can_instantiate(),"Real frozen GDScript parses in autoload context "+row.path): return false
		var methods: Dictionary={}
		for descriptor: Dictionary in script.get_script_method_list():
			methods[String(descriptor.name)]=descriptor
		for name: String in row.methods:
			if not need(methods.has(name),"Required callable method "+name): return false
			var signature: Dictionary=methods[name]
			if not need(signature.get("args") is Array and signature.args.size()==int(row.methods[name]),"Exact argument arity "+name): return false
			if not need(signature.get("return") is Dictionary and signature["return"].get("type")==RETURN_TYPES[name],"Exact declared result domain "+name): return false
		rows.append({"path":row.path,"sha256":row.sha256,"required_method_arities":row.methods,"loaded_real_Script":true,"instances_created":0,"methods_executed":0})
		script=null
	return true
func _run() -> void:
	var began: int=Time.get_ticks_msec()
	# Only this own process is affected. No checkpoint/save write is performed.
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	var complete: bool=parse_modules()
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path)
		need(final[path]==first[path],"Frozen parse input unchanged "+path)
	need(Time.get_ticks_msec()-began<LIMIT_MS,"Predeclared10s parse scope")
	var folder: String="res://build/luoyang_city_full_rollout_20261022ap_qa01/npc_parse/%d_%d"%[OS.get_process_id(),began]
	var report_path: String=folder.path_join("result.json")
	var writable: bool=not FileAccess.file_exists(report_path) and DirAccess.make_dir_recursive_absolute(folder)==OK
	need(writable,"NEW own result only")
	var report: Dictionary={"scope":"AP_TWO_FROZEN_NPC_MODULES_AUTOLOAD_PARSE_ONLY_NOT_RUNTIME","complete":complete and failures.is_empty(),"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"source_first":first,"source_final":final,"rows":rows,"publication":false,"Field_or_NPC_instances":0,"readiness_projection_dialog_methods_executed":0,"save_writes":false,"System_candidates_not_frozen_not_loaded":true}
	var output: FileAccess=FileAccess.open(report_path,FileAccess.WRITE) if writable else null
	if output==null: failures.append("RESULT_OPEN")
	else:
		output.store_string(JSON.stringify(report,"\t"));output.close()
	print("AP_NPC_PARSE_RESULT=",report_path)
	quit(0 if complete and failures.is_empty() else 1)
