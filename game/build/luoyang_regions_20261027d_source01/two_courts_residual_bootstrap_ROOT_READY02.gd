extends SceneTree
## Mature normal-project deferred entry. The worker alone uses autoload globals.
const INPUT = "res://build/luoyang_regions_20261027d_source01/two_courts_residual_input_ROOT_READY02.json"
const INPUT_SHA = "a4d63c5895e7e9e228f9601f2957b4904967654bd75beb3826bad23b27b52e1b"
const WORKER = "res://build/luoyang_regions_20261027d_source01/two_courts_residual_worker_ROOT_READY02.gd"
const WORKER_SHA = "03abc009ef97d49994ba9dab32d72196636d5e23589bf58eeedd44b0c0693ba7"
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
