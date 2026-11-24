extends SceneTree
## Actual LoadingScreen presentation only; no Field/resource-preload performance claim.
const SCREEN := "res://scenes/ui/loading_screen.tscn"
const MANAGER := "res://scripts/autoload/loading_manager.gd"
const PINS := {
	MANAGER:"5995b345bb019f95c93f40ba9a47f365f0763f315e08562a84247209b26566cc",
	"res://scripts/ui/loading_screen.gd":"60a8bade4696dc3b8d0736561bd0a6c19ccc4637540a0fcca366171d0c9850da",
	SCREEN:"340c4fd57e4a8aabd3be217d479c7361aebdae24d5cc6440ecbeba0efe1c3c01",
}
const STAGE := "正在读取地图资源……"
var checks: int = 0
var failures: int = 0
var rows: Array[Dictionary] = []

func _initialize() -> void: call_deferred("_run")

func _check(value: bool, label: String) -> bool:
	checks += 1
	if not value: failures += 1; push_error("[LOADING LABEL KEY] "+label)
	return value

func _run() -> void:
	var platform: Node = root.get_node("PlatformBridge")
	var previous: bool = platform.call("is_checkpoint_saves_suspended")
	platform.call("set_checkpoint_saves_suspended",true)
	_check(platform.call("is_checkpoint_saves_suspended") == true,"public checkpoint held before first await")
	_check("--loading-resource-label-key" in OS.get_cmdline_user_args(),"explicit finite label mode")
	for path: String in PINS: _check(FileAccess.get_sha256(path) == PINS[path],"exact UI source "+path)
	var regex := RegEx.new()
	_check(regex.compile('_screen\\.set_progress\\(_field_progress\\(\\.25 \\+ \\.44 \\* float\\(done\\) / maxi\\(1, paths\\.size\\(\\)\\)\\), "([^"]+)"\\)') == OK,"exact unchanged ratio/source-line reader")
	var found: RegExMatch = regex.search(FileAccess.get_file_as_string(MANAGER))
	var stage: String = found.get_string(1) if found != null else ""
	_check(stage == STAGE,"actual manager stage has fixed Chinese text without resource counts")
	var scene: PackedScene = ResourceLoader.load(SCREEN,"",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	var screen: CanvasLayer = scene.instantiate() as CanvasLayer if scene != null else null
	var output: String = "res://build/joint_world_luoyang_20261003_qa/loading_resource_label_key_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK,"unique short evidence directory")
	if _check(screen != null,"actual production LoadingScreen instantiate"):
		root.add_child(screen)
		await process_frame
		screen.call("show_screen",true)
		var label: Label = screen.get_node("Root/Content/Stage") as Label
		var percent: Label = screen.get_node("Root/Content/Percent") as Label
		var bar: ProgressBar = screen.get_node("Root/Content/Progress") as ProgressBar
		var ratios: Array[float] = [0.0,.157,1.0,-.25,1.25]
		var expected: Array[String] = ["0%","16%","100%","0%","100%"]
		for index: int in ratios.size():
			screen.call("set_progress",ratios[index],stage)
			_check(label.text == STAGE and not "/" in label.text,"fixed stage label case "+str(index))
			_check(percent.text == expected[index] and percent.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT,"right-side percent case "+str(index))
			_check(bar.value >= 0.0 and bar.value <= 100.0 and (bar.value == 0.0 if index in [0,3] else bar.value == 100.0 if index in [2,4] else true),"progress clamp0..100 case "+str(index))
			rows.append({"ratio":ratios[index],"stage":label.text,"percent":percent.text,"bar_value":bar.value,"expected_percent":expected[index]})
		screen.queue_free(); screen = null; scene = null
		await process_frame; await process_frame
	for path: String in PINS: _check(FileAccess.get_sha256(path) == PINS[path],"UI source unchanged "+path)
	platform.call("set_checkpoint_saves_suspended",previous)
	_check(platform.call("is_checkpoint_saves_suspended") == previous,"public checkpoint restored")
	var result: Dictionary = {"scope":"LOADING_FIXED_RESOURCE_STAGE_AND_RIGHT_PERCENT_ONLY","complete":failures == 0,"checks":checks,"failures":failures,"records":rows,"source_pins":PINS,"display_server":DisplayServer.get_name(),"Field_loaded":false,"loading_speed_credit":false,"world_or_city_credit":false}
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	_check(file != null,"write actual short receipt")
	if file != null: file.store_string(JSON.stringify(result,"\t")); file.close()
	print("LOADING_RESOURCE_LABEL_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures == 0 else 1)
