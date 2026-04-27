extends Node

## 全局对话播放器。
##
## 用法：
##   var script = load("res://data/dialogs/ch1_road_intro.tres")
##   DialogPlayer.play(script)
##   await DialogPlayer.dialog_ended  # 等用户点完整段对话
##
## 信号广播给 DialogBox（UI 层），UI 不持有状态。

signal text_displayed(speaker: String, text: String, has_choices: bool, portrait_path: String)
signal choices_displayed(choices: Array)
signal dialog_ended(dialog_id: StringName)

const DIALOG_BOX_SCENE_PATH := "res://scenes/ui/dialog_box.tscn"

var _current_script: DialogScript = null
var _current_node: DialogNode = null
var _is_playing: bool = false

var _box: Node = null   # 实例化的 DialogBox UI


func _ready() -> void:
	# 全局对话框：autoload 启动时挂载到根。
	# 因 autoload 子节点常驻，所有场景都能复用同一个对话框实例。
	if ResourceLoader.exists(DIALOG_BOX_SCENE_PATH):
		var scn: PackedScene = load(DIALOG_BOX_SCENE_PATH)
		_box = scn.instantiate()
		add_child(_box)


# --- 公开 API ---

func is_playing() -> bool:
	return _is_playing


func play(script: DialogScript) -> void:
	if script == null:
		push_warning("[DialogPlayer] null script")
		return
	_current_script = script
	_is_playing = true
	EventBus.dialog_started.emit(script.dialog_id)
	_show_node(script.get_entry_node())


func play_at(script: DialogScript, node_id: StringName) -> void:
	if script == null: return
	_current_script = script
	_is_playing = true
	EventBus.dialog_started.emit(script.dialog_id)
	_show_node(script.find_node_by_id(node_id))


func advance() -> void:
	## 玩家按"继续"。仅在当前节点无 choices 时有效。
	if _current_node == null: return
	if _current_node.has_choices():
		return
	_apply_node_side_effects(_current_node)
	_resolve_action(_current_node.on_end)


func choose(idx: int) -> void:
	## 玩家点了第 idx 个选项。
	if _current_node == null: return
	if not _current_node.has_choices(): return
	if idx < 0 or idx >= _current_node.choices.size(): return

	var c: Dictionary = _current_node.choices[idx]
	# 选项本身的 set_flag 副作用
	if c.has("set_flag"):
		var flag_dict: Dictionary = c.get("set_flag", {})
		for key in flag_dict.keys():
			GameState.flags[key] = flag_dict[key]
			EventBus.flag_set.emit(StringName(key), flag_dict[key])

	var next_id: String = String(c.get("next", ""))
	if next_id == "" or next_id == "end":
		_end_dialog()
	else:
		_show_node(_current_script.find_node_by_id(StringName(next_id)))


# --- 内部 ---

func _show_node(node: DialogNode) -> void:
	if node == null:
		_end_dialog()
		return
	_current_node = node
	text_displayed.emit(
		node.speaker,
		node.text,
		node.has_choices(),
		node.portrait_path
	)
	if node.has_choices():
		choices_displayed.emit(node.choices)


func _apply_node_side_effects(node: DialogNode) -> void:
	## 节点级副作用：give_items / give_gold / set_flags / quest 操作。
	## 选项级副作用在 choose() 里单独处理。
	for entry in node.give_items:
		var iid: StringName = StringName(entry.get("id", ""))
		var cnt: int = int(entry.get("count", 1))
		if String(iid) != "":
			Inventory.add_item(iid, cnt)

	if node.give_gold > 0:
		GameState.add_gold(node.give_gold)

	for flag_entry in node.set_flags:
		var key: String = String(flag_entry.get("key", ""))
		var value: Variant = flag_entry.get("value", true)
		if key != "":
			GameState.flags[key] = value
			EventBus.flag_set.emit(StringName(key), value)

	# Quest 命令必须经过 QuestManager（它是 source of truth），
	# 避免直接 emit EventBus.quest_accepted 造成 QuestManager 重入循环。
	if String(node.accept_quest) != "":
		QuestManager.accept(node.accept_quest)

	if String(node.complete_quest) != "":
		QuestManager.complete(node.complete_quest)


func _resolve_action(action: String) -> void:
	## "next:<id>" 是 DialogPlayer 自有动作（节点内跳转），其他全转交 SceneRouter。
	if action == "" or action == "end":
		_end_dialog()
		return

	var parts: PackedStringArray = action.split(":", true, 1)
	var cmd: String = parts[0]
	var arg: String = parts[1] if parts.size() > 1 else ""

	if cmd == "next":
		_show_node(_current_script.find_node_by_id(StringName(arg)))
		return

	# 其余动作都 = 结束本对话 + 让 SceneRouter 处理（可能切场景）
	_end_dialog()
	SceneRouter.resolve_action(action)


func _end_dialog() -> void:
	var id := _current_script.dialog_id if _current_script != null else &""
	_current_script = null
	_current_node = null
	_is_playing = false
	dialog_ended.emit(id)
	EventBus.dialog_ended.emit(id)
