extends SceneTree
## Root-only compile-domain check. Never instantiates a candidate or calls readiness.
const INPUT="res://build/luoyang_city_full_rollout_20261022ap_system01/system_parse_inputs_READY.json"
const INPUT_SHA="d3c566d702e1e843bf5fe5000f900d1007085d4f6b52abb21b080cae472766e6"
const OUT="res://build/luoyang_city_full_rollout_20261022ap_system01/system_parse/"
const LIMIT_MS=15000
var failures: Array[String]=[]
func check(value: bool,label: String) -> void:
	if not value: failures.append(label)
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge!=null: bridge.call("set_checkpoint_saves_suspended",true)
	var began: int=Time.get_ticks_msec()
	check(OS.get_cmdline_user_args().is_empty(),"NO_USER_ARGS")
	check(FileAccess.get_sha256(INPUT)==INPUT_SHA,"FROZEN_INPUT_SHA")
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(INPUT))
	if not raw is Dictionary or not raw.get("rows") is Array or raw.rows.size()!=16:
		push_error("AP_SYSTEM_PARSE_INPUT");quit(1);return
	var first: Dictionary={INPUT:FileAccess.get_sha256(INPUT),get_script().resource_path:FileAccess.get_sha256(get_script().resource_path)}
	for row: Dictionary in raw.rows:
		check(row.path.begins_with("res://") and not ".." in row.path and not first.has(row.path),"CLOSED_UNIQUE_INPUT:"+row.path)
		first[row.path]=FileAccess.get_sha256(row.path)
		check(first[row.path]==row.sha256,"INPUT_SOURCE:"+row.path)
	var results: Array=[]
	if failures.is_empty():
		for row: Dictionary in raw.rows:
			var began_one: int=Time.get_ticks_usec()
			var candidate: Resource=ResourceLoader.load(row.path,"GDScript",ResourceLoader.CACHE_MODE_IGNORE)
			var compiled: GDScript=candidate as GDScript
			var parsed: bool=compiled!=null and compiled.can_instantiate()
			check(parsed,"CAN_INSTANTIATE_WITH_AUTOLOADS:"+row.path)
			results.append({"path":row.path,"parsed":parsed,"elapsed_us":Time.get_ticks_usec()-began_one,"instantiated":false})
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path)
		check(final[path]==first[path],"SOURCE_FINAL:"+path)
	var elapsed: int=Time.get_ticks_msec()-began
	check(elapsed<LIMIT_MS,"FIXED_15_SECOND_BOUND")
	var report: Dictionary={"passed":failures.is_empty(),"failures":failures,"rows":results,"elapsed_ms":elapsed,"limit_ms":LIMIT_MS,"source_first":first,"source_final":final,"scope":"AP_SYSTEM_AUTOLOAD_DOMAIN_COMPILE_ONLY_NO_INSTANTIATION_OR_READINESS","scene_or_field_instantiated":false,"collector_or_geometry_called":false,"formal_deployment_credit":false}
	var path: String=OUT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: quit(1);return
	var stream: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if stream==null: quit(1);return
	stream.store_string(JSON.stringify(report,"\t",true,true));stream.close()
	print(JSON.stringify({"passed":report.passed,"path":path,"failures":failures}));quit(0 if report.passed else 1)
