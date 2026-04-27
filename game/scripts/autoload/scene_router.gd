extends Node

## 场景跳转 + 动作字符串解析中枢。
##
## 所有跨场景调度走这里：
##   - go_main_menu / go_field / start_battle / go_victory / go_defeat
##   - resolve_action(action_str)：DialogPlayer / FieldController 等统一调用
##
## action 字符串语法（详见 DialogNode.gd 注释）：
##   "dialog:<id>"          打开对话脚本
##   "battle:<id>"          启动战斗
##   "scene:<id>"           切换探索场景
##   "shop:<id>"            打开商店（M4）
##   "give_item:<id>:<n>"   给玩家物品
##   "give_gold:<n>"        给金币
##   "set_flag:<key>:<v>"   置 flag（v="true"/"false"/数字）
##   "accept_quest:<id>"    接受任务（→ QuestManager）
##   "complete_quest:<id>"  完成任务（→ QuestManager）
##   "open_inventory"       打开背包（M5）
##   "open_quest_log"       打开任务日志（M3）
##   "end" 或 ""            空操作

const SCENE_MAIN_MENU := "res://scenes/main_menu.tscn"
const SCENE_BATTLE := "res://scenes/battle.tscn"
const SCENE_VICTORY := "res://scenes/result_victory.tscn"
const SCENE_DEFEAT := "res://scenes/result_defeat.tscn"
const SCENE_FIELD := "res://scenes/field.tscn"
const SCENE_SHOP := "res://scenes/shop.tscn"
const SCENE_CHAPTER_END := "res://scenes/chapter_end.tscn"

const DIALOG_DIR := "res://data/dialogs/"
const FIELD_SCENE_DIR := "res://data/scenes/"

var _battle_payload: Dictionary = {}
var _field_payload: Dictionary = {}
var _shop_payload: Dictionary = {}
var _result_payload: Dictionary = {}
var _current_field_id: StringName = &""


# --- 场景跳转 ---

func go_main_menu() -> void:
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)


func start_battle(enemy_id: String = "thug_lone", return_scene_id: StringName = &"") -> void:
	_battle_payload = {
		"enemy_id": enemy_id,
		"return_scene": return_scene_id if String(return_scene_id) != "" else _current_field_id,
	}
	get_tree().change_scene_to_file(SCENE_BATTLE)


func get_battle_payload() -> Dictionary:
	return _battle_payload


func go_victory(reward_gold: int = 0, reward_exp: int = 0) -> void:
	_result_payload = {
		"gold": reward_gold,
		"exp": reward_exp,
		"return_scene": _battle_payload.get("return_scene", &""),
	}
	get_tree().change_scene_to_file(SCENE_VICTORY)


func go_defeat() -> void:
	_result_payload = {}
	get_tree().change_scene_to_file(SCENE_DEFEAT)


func get_result_payload() -> Dictionary:
	return _result_payload


func go_field(scene_id: StringName) -> void:
	_field_payload = {"scene_id": scene_id}
	_current_field_id = scene_id
	get_tree().change_scene_to_file(SCENE_FIELD)


func get_field_payload() -> Dictionary:
	return _field_payload


func get_current_field_id() -> StringName:
	return _current_field_id


func go_chapter_end(chapter: int) -> void:
	_result_payload = {"chapter": chapter}
	get_tree().change_scene_to_file(SCENE_CHAPTER_END)


func quit_game() -> void:
	get_tree().quit()


# --- Action 字符串解析 ---

func resolve_action(action: String) -> void:
	if action == "" or action == "end":
		return

	var parts: PackedStringArray = action.split(":", true)
	var cmd: String = parts[0]

	match cmd:
		"dialog":
			_action_dialog(_arg(parts, 1))
		"battle":
			start_battle(_arg(parts, 1))
		"scene":
			go_field(StringName(_arg(parts, 1)))
		"shop":
			var sid := _arg(parts, 1)
			if sid != "":
				go_shop(StringName(sid))
		"give_item":
			var iid := _arg(parts, 1)
			var n: int = int(_arg(parts, 2, "1"))
			if iid != "":
				Inventory.add_item(StringName(iid), n)
		"give_gold":
			GameState.add_gold(int(_arg(parts, 1, "0")))
		"set_flag":
			var k := _arg(parts, 1)
			var v_str := _arg(parts, 2, "true")
			var v: Variant = _parse_flag_value(v_str)
			if k != "":
				GameState.flags[k] = v
				EventBus.flag_set.emit(StringName(k), v)
		"accept_quest":
			var qid := _arg(parts, 1)
			if qid != "":
				QuestManager.accept(StringName(qid))
		"complete_quest":
			var qid := _arg(parts, 1)
			if qid != "":
				QuestManager.complete(StringName(qid))
		"open_inventory":
			push_warning("[SceneRouter] inventory UI not implemented yet (M5)")
		"open_quest_log":
			push_warning("[SceneRouter] quest log UI not implemented yet (M3)")
		_:
			push_warning("[SceneRouter] unknown action: %s" % action)


# --- helpers ---

func _arg(parts: PackedStringArray, idx: int, default: String = "") -> String:
	return parts[idx] if idx < parts.size() else default


func _parse_flag_value(s: String) -> Variant:
	if s == "true": return true
	if s == "false": return false
	if s.is_valid_int(): return s.to_int()
	if s.is_valid_float(): return s.to_float()
	return s


func _action_dialog(dialog_id: String) -> void:
	if dialog_id == "":
		return
	var path := "%s%s.tres" % [DIALOG_DIR, dialog_id]
	if not ResourceLoader.exists(path):
		push_warning("[SceneRouter] dialog not found: %s" % path)
		return
	var script: Resource = load(path)
	if script is DialogScript:
		DialogPlayer.play(script)
