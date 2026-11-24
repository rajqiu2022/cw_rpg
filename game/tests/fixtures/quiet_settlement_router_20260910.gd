extends "res://scripts/autoload/scene_router.gd"

## QA uses real start/settle payloads but never instantiates result screens.
var transition_paths: Array[String] = []
func _transition_to(scene_path: String, _kind: StringName, _context: Dictionary = {}) -> void:
	transition_paths.append(scene_path)
func _change_scene_immediate(scene_path: String) -> void:
	transition_paths.append(scene_path)
func _clear_transient_ui() -> void: pass
