extends SceneTree
## Read-only compile check, not candidate/gameplay approval.
func _initialize() -> void:
	_check.call_deferred()

func _check() -> void:
	var paths := ["world/world_map_v15_contract", "world/v15_modular_overlap", "dev/publish_world_map_v15", "dev/world_map_v15_publication_gate", "autoload/scene_router", "autoload/save_manager", "field/field_walkable_controller", "field/world_v15_exit_zone", "field/player", "field/npc_node", "ui/world_map_panel"]
	var failed := false
	for path: String in paths:
		var source := load("res://scripts/%s.gd" % path) as GDScript
		if source == null or not source.can_instantiate():
			push_error("V15 source cannot compile: " + path)
			failed = true
	if not failed:
		var router := root.get_node("SceneRouter")
		var before: Dictionary = router.call("get_navigation_state")
		var supported: bool = router.call("navigation_coordinate_version_supported", {"world_map_version":15}, "world_map_jianghu_v14")
		var after: Dictionary = router.call("get_navigation_state")
		if supported or before != after:
			push_error("V15 downgrade preflight did not reject without state mutation")
			failed = true
		print("V15_DOWNGRADE_READONLY_PREFLIGHT rejected=%s router_unchanged=%s no_save_file_read_or_written" % [not supported, before == after])
	print("V15_SYSTEM_SOURCE_COMPILE scripts=%d failed=%s no_candidate_runtime_tested" % [paths.size(), failed])
	quit(1 if failed else 0)
