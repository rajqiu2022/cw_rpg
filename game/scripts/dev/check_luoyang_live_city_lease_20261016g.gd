extends SceneTree
## Compile/loading entry only. ROOT runs this in a separate headless process;
## it neither enters a map nor mutates player saves. No preload of autoloads.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform==null or not platform.has_method("set_checkpoint_saves_suspended"):
		printerr("LIVE_CITY_LEASE_CHECK: missing save suspension API"); quit(1); return
	platform.call("set_checkpoint_saves_suspended",true)
	var passed: bool=true
	for path: String in ["res://scripts/autoload/scene_router.gd","res://scripts/autoload/loading_manager.gd","res://scripts/field/field_walkable_controller.gd","res://scripts/city/luoyang_resident_field_20261016.gd"]:
		var source: Script=load(path) as Script
		var ready: bool=source!=null and source.can_instantiate()
		print("LIVE_CITY_LEASE_CHECK ",path," can_instantiate=",ready)
		passed=passed and ready
	print("LIVE_CITY_LEASE_CHECK_ONLY_NOT_MAP_ACCEPTANCE ",passed)
	quit(0 if passed else 1)
