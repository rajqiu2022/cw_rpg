extends SceneTree
## Root-only, normal project autoload context; syntax admission only.
const PINS := {
	"res://build/luoyang_city_rectification_20261027d_system01/logical_context_bridge.gd":"9ea4fd4ee8fde845d6d346a7c95e2bdceb1379513e0482c1b8225157afc4cdbf",
	"res://build/luoyang_city_rectification_20261027d_system01/logical_terminal_projector.gd":"ce4bb7f2452e911d2e929db245f37a1b211fd7e3d74df0d1b794d37e494cd7fb",
	"res://build/luoyang_regions_20261027d_source01/region_compiler.gd":"3431159950c670009d0b08d9ae09009249e474e5d28fa1ccf9d9a242a9ed00fe",
	"res://build/luoyang_regions_20261027d_source01/legacy_alias.gd":"3c90bd59b18fcd6b3e9367ec5129fee19bf1d71b282c7c69c9f11f02e17b094c",
	"res://build/luoyang_regions_20261027d_source01/region_session.gd":"7da7287fe455f28a496aec2c0ea2e0b83d76c9709909b08c1bd626f619965c62"
}
const AUTOLOADS := ["EventBus","GameState","WeatherManager","InvestigationState","Inventory","LoadingManager","SceneRouter","QuestManager","BountyManager","DialogPlayer","SaveManager","CursorManager","PlatformBridge","ContentPackManager","AudioManager","GMConsole"]
const OUTPUT_ROOT := "res://build/luoyang_regions_20261027d_qa01/syntax5_output/"
var began: int = 0
var checks: int = 0
var errors: Array[String] = []
var rows: Array = []
var source_first: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, label: String) -> bool:
	checks += 1
	if not value: errors.append(label)
	return value

func _run() -> void:
	began = Time.get_ticks_msec()
	for id: String in AUTOLOADS: _check(root.get_node_or_null(id)!=null,"NORMAL_AUTOLOAD:"+id)
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if not _check(bridge!=null and bridge.has_method("set_checkpoint_saves_suspended") and bridge.has_method("is_checkpoint_saves_suspended"),"CHECKPOINT_API"):
		_finish(false); return
	bridge.call("set_checkpoint_saves_suspended",true)
	if not _check(bridge.call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED"):
		_finish(false); return
	for path: String in PINS:
		source_first[path] = FileAccess.get_sha256(path)
		_check(source_first[path]==PINS[path],"FIXED_SHA:"+path)
	if not errors.is_empty(): _finish(true); return
	for path: String in PINS:
		if not _check(Time.get_ticks_msec()-began<15000,"BEFORE_LOAD_15S:"+path): break
		var script: Variant = ResourceLoader.load(path,"GDScript",ResourceLoader.CACHE_MODE_IGNORE)
		var loaded: bool = script is GDScript and script.resource_path==path
		var can_make: bool = loaded and script.can_instantiate()
		rows.append({"path":path,"sha256":PINS[path],"GDScript":loaded,"can_instantiate":can_make,"instances":0,"business_calls":0})
		_check(loaded and can_make,"PARSE_ONLY:"+path)
	_check(rows.size()==5,"EXACT_FIVE_RESULTS")
	_check(Time.get_ticks_msec()-began<15000,"WHOLE_15S")
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"SUSPENSION_HELD_TO_QUIT")
	_finish(true)

func _finish(suspended: bool) -> void:
	var source_final: Dictionary = {}
	for path: String in PINS: source_final[path] = FileAccess.get_sha256(path)
	_check(source_first.is_empty() or source_first==source_final,"FIVE_SOURCE_FIRST_FINAL")
	var result := {"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"rows":rows,"source_first":source_first,"source_final":source_final,"normal_autoload_count":16,"checkpoint_saves_suspended_to_quit":suspended,"candidate_instances":0,"business_calls":0,"Field_instances":0,"Scene_requests":0,"geometry_calls":0,"collector_calls":0,"PNG_decode":0,"packet_decode":0,"runtime_admission":false}
	var path: String = OUTPUT_ROOT+str(OS.get_process_id())+"_"+str(Time.get_ticks_usec())+"/result.json"
	if FileAccess.file_exists(path): printerr("PRESERVE_EXISTING_RESULT"); quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: printerr("RESULT_WRITE_FAILED"); quit(2); return
	file.store_string(JSON.stringify(result,"\t")+"\n"); file.close()
	print("SYNTAX5_RESULT ",path)
	quit(0 if result.passed else 1)
