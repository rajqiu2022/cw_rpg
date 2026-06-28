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
##   "open_inventory"       请求当前 Field 打开背包 UI（M5）
##   "open_equipment"       请求当前 Field 打开装备 UI（M5）
##   "open_quest_log"       请求当前 Field 打开任务面板（M3）
##   "chapter_end:<chapter>"进入章节结算（M6）
##   "play_bgm:<path>"      播放/切换 BGM（带 0.8s 交叉淡出）
##   "play_sfx:<path>"      播放一击音效
##   "stop_bgm"             停止当前 BGM（0.5s 淡出）
##   "end" 或 ""            空操作

const SCENE_MAIN_MENU := "res://scenes/main_menu.tscn"
const SCENE_BATTLE := "res://scenes/battle.tscn"
const SCENE_VICTORY := "res://scenes/result_victory.tscn"
const SCENE_DEFEAT := "res://scenes/result_defeat.tscn"
const SCENE_FIELD := "res://scenes/field.tscn"
const SCENE_FIELD_WALKABLE := "res://scenes/field_walkable.tscn"
const SCENE_SHOP := "res://scenes/shop.tscn"
const SCENE_CHAPTER_END := "res://scenes/chapter_end.tscn"
const START_FIELD_SCENE := &"linxi_tutorial"

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


func go_field_smart(scene_id: StringName, player_spawn: Variant = null) -> void:
	var target_scene := get_field_scene_path(scene_id)
	if target_scene == SCENE_FIELD_WALKABLE:
		var spawn := _scene_default_spawn(scene_id)
		if player_spawn is Vector2:
			spawn = player_spawn
		_field_payload = {"scene_id": scene_id, "player_spawn": spawn}
	else:
		_field_payload = {"scene_id": scene_id}
	_current_field_id = scene_id
	get_tree().change_scene_to_file(target_scene)


func go_field_walkable(scene_id: StringName, player_spawn: Vector2 = Vector2(0.5, 0.8)) -> void:
	if not ResourceLoader.exists(SCENE_FIELD_WALKABLE):
		push_warning("[SceneRouter] walkable field scene not found, falling back to classic")
		go_field(scene_id)
		return
	_field_payload = {"scene_id": scene_id, "player_spawn": player_spawn}
	_current_field_id = scene_id
	get_tree().change_scene_to_file(SCENE_FIELD_WALKABLE)


func get_field_payload() -> Dictionary:
	return _field_payload


func get_current_field_id() -> StringName:
	return _current_field_id


func get_field_scene_path(scene_id: StringName) -> String:
	var scene_def := _load_field_scene_def(scene_id)
	if scene_def != null and scene_def.is_walkable and ResourceLoader.exists(SCENE_FIELD_WALKABLE):
		return SCENE_FIELD_WALKABLE
	return SCENE_FIELD


func go_shop(shop_id: StringName) -> void:
	_shop_payload = {"shop_id": shop_id}
	get_tree().change_scene_to_file(SCENE_SHOP)


func get_shop_payload() -> Dictionary:
	return _shop_payload


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
			var scene_id := _arg(parts, 1)
			if scene_id != "":
				go_field_smart(StringName(scene_id))
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
			EventBus.ui_requested.emit(&"inventory")
		"open_equipment":
			EventBus.ui_requested.emit(&"equipment")
		"open_skills":
			EventBus.ui_requested.emit(&"skills")
		"open_quest_log":
			EventBus.ui_requested.emit(&"quest_log")
		"chapter_end":
			go_chapter_end(int(_arg(parts, 1, "1")))
		"play_bgm":
			AudioManager.play_bgm(_arg(parts, 1))
		"play_sfx":
			AudioManager.play_sfx(_arg(parts, 1))
		"stop_bgm":
			AudioManager.stop_bgm()
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


func _load_field_scene_def(scene_id: StringName) -> SceneScript:
	var path := "%s%s.tres" % [FIELD_SCENE_DIR, String(scene_id)]
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is SceneScript:
		return res
	return null


func _scene_default_spawn(scene_id: StringName) -> Vector2:
	var scene_def := _load_field_scene_def(scene_id)
	if scene_def != null:
		return scene_def.player_spawn
	return Vector2(0.5, 0.8)
