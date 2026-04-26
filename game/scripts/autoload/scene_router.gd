extends Node

## 集中管理场景跳转。所有跳转必须走这里，便于加过场动画/loading。

const SCENE_MAIN_MENU := "res://scenes/main_menu.tscn"
const SCENE_BATTLE := "res://scenes/battle.tscn"
const SCENE_VICTORY := "res://scenes/result_victory.tscn"
const SCENE_DEFEAT := "res://scenes/result_defeat.tscn"

var _battle_payload: Dictionary = {}

func go_main_menu() -> void:
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

func start_battle(enemy_id: String = "default_thug") -> void:
	_battle_payload = {"enemy_id": enemy_id}
	get_tree().change_scene_to_file(SCENE_BATTLE)

func get_battle_payload() -> Dictionary:
	return _battle_payload

func go_victory(reward_gold: int = 0, reward_exp: int = 0) -> void:
	_battle_payload = {"gold": reward_gold, "exp": reward_exp}
	get_tree().change_scene_to_file(SCENE_VICTORY)

func go_defeat() -> void:
	get_tree().change_scene_to_file(SCENE_DEFEAT)

func quit_game() -> void:
	get_tree().quit()
