extends SceneTree
## Residual parse-domain check only. Does not instantiate Router or change scene.
const TARGET="res://build/luoyang_estate_courtyard_20261021am_system01/Router_candidate.gd"
const TARGET_SHA="d99665c8503e0ebfbc5eb0656d4d7980a1e863ba9551cfb0e217e45266698b5d"
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var began: int=Time.get_ticks_msec();var first: String=FileAccess.get_sha256(TARGET)
	var ok: bool=OS.get_cmdline_user_args().is_empty() and first==TARGET_SHA and root.get_node_or_null("GameState")!=null
	var script: Variant=ResourceLoader.load(TARGET,"GDScript",ResourceLoader.CACHE_MODE_IGNORE) if ok else null
	ok=ok and script is GDScript and script.can_instantiate() and script.resource_path==TARGET
	var final: String=FileAccess.get_sha256(TARGET);ok=ok and final==first
	var path: String="res://build/luoyang_estate_courtyard_20261021am_system01/router_autoload_check/"+str(OS.get_process_id())+"/result.json"
	var result: Dictionary={"passed":ok,"target":TARGET,"source_first":first,"source_final":final,"elapsed_ms":Time.get_ticks_msec()-began,"scope":"AUTOLOAD_ESTABLISHED_DELAYED_SCRIPT_LOAD_ONLY_NOT_ROUTER_INSTANCE_OR_TRAVEL","preserved_failure":"Root direct --script check-only GameState identifier error retained"}
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: quit(1);return
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(1);return
	file.store_string(JSON.stringify(result,"\t",true,true));file.close()
	print(JSON.stringify({"path":path,"passed":ok}));quit(0 if ok else 1)
