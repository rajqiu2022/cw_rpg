extends "res://scripts/field/field_walkable_controller.gd"
## Read-only development fixture: real Field/Player/ExitZone input, no travel.
var observed_exits: Array[Dictionary] = []

func _ready() -> void:
	# Do not call production _ready: no scene-entered/dialog/reward/checkpoint.
	var scene := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	_current_scene = scene
	_setup_scene(scene, scene.player_spawn)
	_disable_gameplay_button_focus(self)

func _on_exit_triggered(target_scene: String, target_pos: Vector2, source_portal_spawn: Vector2) -> void:
	observed_exits.append({"target_scene": target_scene, "target_pos": target_pos, "source_portal_spawn": source_portal_spawn})
