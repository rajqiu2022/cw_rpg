extends SceneTree
## Read-only compile check with real autoload registration, not a gameplay test.
func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var paths := ["world/world_map_v14_contract", "world/v14_modular_overlap", "dev/publish_world_map_v14", "autoload/scene_router", "autoload/save_manager", "field/field_walkable_controller", "field/player", "field/npc_node", "ui/world_map_panel", "ui/result_victory", "ui/result_defeat", "battle/battle_controller"]
	var failed := false
	for path: String in paths:
		var script := load("res://scripts/%s.gd" % path) as GDScript
		if script == null or not script.can_instantiate():
			push_error("System source cannot compile: " + path)
			failed = true
	print("WorldV14System source compile: %d scripts; failed=%s; no map runtime tested" % [paths.size(), failed])
	quit(1 if failed else 0)
