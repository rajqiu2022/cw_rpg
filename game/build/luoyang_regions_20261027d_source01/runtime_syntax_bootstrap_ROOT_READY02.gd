extends SceneTree
## Mature normal-project deferred entry. The worker alone uses autoload globals.
const INPUT = "res://build/luoyang_regions_20261027d_source01/runtime_syntax_input_ROOT_READY02.json"
const INPUT_SHA = "f4c4dac05ee96b4ca1916d4803e14518bece50bb156cb0978818e58b8f849e56"
const WORKER = "res://build/luoyang_regions_20261027d_source01/runtime_syntax_worker_ROOT_READY01.gd"
const WORKER_SHA = "a6ac5de71527f6ea94c93160fbe6be1f2eef2315ccd96befc7697b3c1951f461"
const AUTOLOADS = ["EventBus","GameState","WeatherManager","InvestigationState","Inventory","LoadingManager","SceneRouter","QuestManager","BountyManager","DialogPlayer","SaveManager","CursorManager","PlatformBridge","ContentPackManager","AudioManager","GMConsole"]

func _initialize() -> void:
	_begin.call_deferred()

func _begin() -> void:
	for id: String in AUTOLOADS:
		if root.get_node_or_null(id) == null: push_error("MISSING_NORMAL_AUTOLOAD:" + id); quit(2); return
	var platform: Node = root.get_node_or_null("PlatformBridge")
	platform.call("set_checkpoint_saves_suspended", true)
	if platform.call("is_checkpoint_saves_suspended") != true or FileAccess.get_sha256(INPUT) != INPUT_SHA or FileAccess.get_sha256(WORKER) != WORKER_SHA: push_error("COLD_COMPILE_SOURCE_OR_SAVE_GATE"); quit(2); return
	var input: Variant = JSON.parse_string(FileAccess.get_file_as_string(INPUT))
	if not input is Dictionary or input.get("root_authorized") != true: push_error("ROOT_AUTHORIZATION_REQUIRED"); quit(2); return
	var script: Variant = ResourceLoader.load(WORKER, "GDScript", ResourceLoader.CACHE_MODE_IGNORE)
	if not script is GDScript or not script.can_instantiate(): push_error("COLD_COMPILE_WORKER_LOAD"); quit(2); return
	var worker: RefCounted = script.new()
	var result: Dictionary = worker.call("run", self, input)
	print("REGION_TERMINAL_COMPILE_RESULT ", JSON.stringify(result))
	quit(0 if result.get("passed") == true else 1)
