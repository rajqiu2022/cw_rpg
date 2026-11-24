extends "res://scripts/battle/battle_controller.gd"

var test_skill: Skill

func _ready() -> void:
	pass

func _load_skill(id: StringName) -> Skill:
	return test_skill if id == &"linxi_basic_sword_one" else super._load_skill(id)

func _skill_uses_approach(_skill: Skill) -> bool:
	return false

func _refresh_hud() -> void:
	pass

func _play_skill_sfx(_path: String) -> void:
	pass

func _end_battle(_victory: bool, _fled: bool) -> void:
	pass

func _log(_line: String) -> void:
	pass
