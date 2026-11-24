extends SceneTree
## Root-only parse probe. No .new(), candidate methods, Scene or Field execution.
const READY=false
const INPUT="PENDING_FINAL_PARSE_INPUT"
const INPUT_SHA="PENDING_FINAL_PARSE_INPUT_SHA"
var checks: int=0
var failures: Array[String]=[]
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures.append(label);printerr("FINAL_CANDIDATE_PARSE_FAIL ",label)
	return ok
func sha(bytes: PackedByteArray) -> String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(bytes);return h.finish().hex_encode()
func facts(paths: Array) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(path): result[path]={"exists":false};continue
		var f:=FileAccess.open(path,FileAccess.READ)
		result[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":f.get_length(),"mtime":FileAccess.get_modified_time(path)};f.close()
	return result
func run() -> void:
	var began:=Time.get_ticks_msec()
	if not check(READY and FileAccess.get_sha256(INPUT)==INPUT_SHA,"Root fixed final parse input"): quit(2);return
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(INPUT))
	if not check(raw is Dictionary and raw.get("ready")==true and raw.get("scripts") is Array and not raw.scripts.is_empty(),"Exact nonempty final GD list"): quit(2);return
	var spec: Dictionary=raw;var paths: Array=[];var seen: Dictionary={}
	for row: Dictionary in spec.scripts:
		if not check(row.path is String and row.path.ends_with(".gd") and row.sha256 is String and row.sha256.length()==64 and not seen.has(row.path),"Unique fixed GDScript path/SHA"): quit(2);return
		seen[row.path]=true;paths.append(row.path)
	var before:=facts(paths);var saved_before:=facts(spec.save_paths);var rows: Array=[]
	for row: Dictionary in spec.scripts:
		if not check(before[row.path].get("sha256")==row.sha256,"Candidate exact SHA before load:"+row.path): break
		var script: Variant=ResourceLoader.load(row.path,"",ResourceLoader.CACHE_MODE_IGNORE)
		var load_ok: bool=script is GDScript and script.resource_path==row.path
		var instantiable: bool=load_ok and script.can_instantiate()
		rows.append({"path":row.path,"sha256":row.sha256,"loaded_GDScript":load_ok,"can_instantiate":instantiable,"new_calls":0,"candidate_method_calls":0})
		if not check(load_ok and instantiable,"Load and can_instantiate only:"+row.path): break
	var after:=facts(paths);var saved_after:=facts(spec.save_paths)
	check(before==after,"Small candidate source first/final same")
	check(saved_before==saved_after,"Current15save before/after same")
	check(Time.get_ticks_msec()-began<20000,"20s parse-only bound")
	var result: Dictionary={"passed":failures.is_empty(),"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"rows":rows,"source_first":before,"source_final":after,"save_first":saved_before,"save_final":saved_after,"new_calls":0,"candidate_method_calls":0,"Field_Scene_geometry_collector_calls":0,"native_packet_decodes":0,"PNG_outputs":0,"runtime_or_ART_admission":false}
	var path: String=String(spec.output_prefix)+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path): printerr("PRESERVE_PARSE_ACTUAL");quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(2);return
	file.store_string(JSON.stringify(result,"\t",true,true));file.close()
	print("FINAL_CANDIDATE_PARSE_RESULT ",path);quit(0 if result.passed else 1)
