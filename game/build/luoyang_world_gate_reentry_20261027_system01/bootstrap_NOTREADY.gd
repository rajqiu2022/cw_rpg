extends SceneTree
## Normal deferred autoload and suspended checkpoint saves; Root sole engine.
const READY := false
const WORKER := "res://build/luoyang_world_gate_reentry_20261027_system01/world_gate_worker_NOTREADY.gd"
const WORKER_SHA := "PENDING_REVIEWED_WORKER"
const FIXTURE := "res://build/luoyang_world_gate_reentry_20261027_system01/fixture_NOTREADY.json"
const FIXTURE_SHA := "PENDING_ROOT_FORMAL_SOURCE_HEAD"
const AUTOLOAD_NAMES := ["EventBus","GameState","WeatherManager","InvestigationState","Inventory","LoadingManager","SceneRouter","QuestManager","BountyManager","DialogPlayer","SaveManager","CursorManager","PlatformBridge","ContentPackManager","AudioManager","GMConsole"]
var began: int=0
var worker: RefCounted

func _initialize() -> void:
	began=Time.get_ticks_msec();call_deferred("run")

func source_facts() -> Dictionary:
	var result: Dictionary={}
	for path: String in [get_script().resource_path,WORKER,FIXTURE]:
		var file:=FileAccess.open(path,FileAccess.READ)
		result[path]={"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
		if file!=null: file.close()
	return result

func run() -> void:
	if not READY or FileAccess.get_sha256(WORKER)!=WORKER_SHA or FileAccess.get_sha256(FIXTURE)!=FIXTURE_SHA:
		printerr("HARDFALSE_OR_FIXED_NORMAL_WORLD_GATE_SOURCE");quit(2);return
	for name: String in AUTOLOAD_NAMES:
		if root.get_node_or_null(name)==null: printerr("MISSING_NORMAL_AUTOLOAD ",name);quit(2);return
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	if bridge.call("is_checkpoint_saves_suspended")!=true: quit(2);return
	create_timer(maxf(.001,60.0-float(Time.get_ticks_msec()-began)/1000.0)).timeout.connect(timeout)
	var first: Dictionary=source_facts()
	var input: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not input is Dictionary or input.get("ready")!=true or input.get("formal_deployed")!=true: quit(2);return
	var script: Variant=ResourceLoader.load(WORKER,"",ResourceLoader.CACHE_MODE_IGNORE)
	if not script is GDScript or not script.can_instantiate(): printerr("AFTER_AUTOLOAD_WORKER_LOAD_FAILED");quit(2);return
	worker=script.new();await worker.call("run",self,input)
	var last: Dictionary=source_facts()
	var ok: bool=first==last and Time.get_ticks_msec()-began<60000
	print("NORMAL_WORLD_GATE_BOOTSTRAP ",JSON.stringify({"same":ok,"source_first":first,"source_final":last,"elapsed_ms":Time.get_ticks_msec()-began,"autoload_count":AUTOLOAD_NAMES.size()}))
	if not ok: quit(1)

func timeout() -> void:
	if worker!=null:
		var input_driver: RefCounted=worker.get("driver")
		if input_driver!=null: input_driver.call("release_movement")
	printerr("WHOLE60S_TIMEOUT_NO_EXTENSION");quit(2)
