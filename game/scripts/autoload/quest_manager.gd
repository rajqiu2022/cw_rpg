extends Node

## 任务运行时管理器。
##
## 职责：
##   1. 持有所有任务的当前状态（NOT_STARTED / IN_PROGRESS / COMPLETED / FAILED）
##   2. 订阅 EventBus 的"事件类"信号（enemy_defeated / scene_entered / flag_set ...），
##      匹配每个 in_progress 任务的 completion_triggers 字符串，自动推进状态
##   3. 完成任务时发奖（gold / exp / items），并广播 EventBus.quest_completed
##   4. 序列化 / 反序列化（SaveManager 调用）
##
## ⚠️ 设计要点：QuestManager 是任务事件的 **source of truth**。
##   外部（DialogPlayer / SceneRouter）想接受任务请直接调 QuestManager.accept(qid)，
##   **不要** 自己 emit EventBus.quest_accepted——会导致循环。
##   QuestManager 内部 accept/complete 时统一负责 emit EventBus 通知给 UI/成就系统。
##
## Trigger 字符串语法（在 QuestDef.completion_triggers 里写）：
##   enemy_defeated:<enemy_id>
##   scene_entered:<scene_id>
##   item_picked_up:<item_id>
##   flag_set:<flag_key>
##   npc_talked_to:<npc_id>

signal active_quests_changed   ## 任务列表（接受/完成/失败）变化时广播给 UI

const QUEST_DIR := "res://data/quests/"

var states: Dictionary = {}   ## quest_id (StringName) -> QuestDef.Status (int)
var _defs: Dictionary = {}    ## quest_id -> QuestDef 缓存


func _ready() -> void:
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.scene_entered.connect(_on_scene_entered)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.npc_talked_to.connect(_on_npc_talked_to)


# --- 加载与查询 ---

func load_def(qid: StringName) -> QuestDef:
	if _defs.has(qid):
		return _defs[qid]
	var path := "%s%s.tres" % [QUEST_DIR, String(qid)]
	if not ResourceLoader.exists(path):
		push_warning("[QuestManager] quest .tres not found: %s" % path)
		return null
	var res: Resource = load(path)
	if res is QuestDef:
		_defs[qid] = res
		return res
	push_warning("[QuestManager] resource is not QuestDef: %s" % path)
	return null


func get_status(qid: StringName) -> int:
	return states.get(qid, QuestDef.Status.NOT_STARTED)


func is_active(qid: StringName) -> bool:
	return get_status(qid) == QuestDef.Status.IN_PROGRESS


func is_completed(qid: StringName) -> bool:
	return get_status(qid) == QuestDef.Status.COMPLETED


func get_active_quests() -> Array[QuestDef]:
	var result: Array[QuestDef] = []
	for qid in states.keys():
		if states[qid] == QuestDef.Status.IN_PROGRESS:
			var d := load_def(qid)
			if d != null:
				result.append(d)
	return result


# --- 状态变更 ---

func accept(qid: StringName) -> bool:
	## 同一任务重复接受 = 静默忽略（已 in_progress 或 completed 都不动作）。
	if get_status(qid) != QuestDef.Status.NOT_STARTED:
		return false
	var def := load_def(qid)
	if def == null:
		return false
	states[qid] = QuestDef.Status.IN_PROGRESS
	EventBus.quest_accepted.emit(qid)
	active_quests_changed.emit()
	print("[Quest] ▶ accepted: %s 「%s」" % [qid, def.title])
	# 接受时立即检查一次（万一前置条件已经满足，比如先打过怪再接的任务）
	_check_all_active()
	return true


func complete(qid: StringName) -> bool:
	if get_status(qid) != QuestDef.Status.IN_PROGRESS:
		return false
	var def := load_def(qid)
	if def == null:
		return false
	states[qid] = QuestDef.Status.COMPLETED
	_grant_rewards(def)
	EventBus.quest_completed.emit(qid)
	active_quests_changed.emit()
	print("[Quest] ✓ completed: %s 「%s」 (gold +%d, exp +%d)" % [
		qid, def.title, def.reward_gold, def.reward_exp
	])
	return true


func fail(qid: StringName) -> bool:
	if get_status(qid) != QuestDef.Status.IN_PROGRESS:
		return false
	states[qid] = QuestDef.Status.FAILED
	EventBus.quest_failed.emit(qid)
	active_quests_changed.emit()
	return true


# --- 奖励发放 ---

func _grant_rewards(def: QuestDef) -> void:
	if def.reward_gold > 0:
		GameState.add_gold(def.reward_gold)
	if def.reward_exp > 0 and GameState.player != null:
		GameState.player.gain_exp(def.reward_exp)
	for entry in def.reward_items:
		var iid: String = String(entry.get("id", ""))
		var n: int = int(entry.get("count", 1))
		if iid != "":
			Inventory.add_item(StringName(iid), n)


# --- Trigger 匹配 ---

func _check_all_active() -> void:
	var to_complete: Array[StringName] = []
	for qid in states.keys():
		if states[qid] != QuestDef.Status.IN_PROGRESS:
			continue
		var def := load_def(qid)
		if def == null:
			continue
		if _any_trigger_satisfied(def):
			to_complete.append(qid)
	for qid in to_complete:
		complete(qid)


func _any_trigger_satisfied(def: QuestDef) -> bool:
	## 用于 accept 时立即检查"是否已经满足"（比如玩家先打怪再接任务）。
	for trig in def.completion_triggers:
		var parts: PackedStringArray = trig.split(":", true, 1)
		if parts.size() < 2:
			continue
		var ev: String = parts[0]
		var arg: String = parts[1]
		match ev:
			"flag_set":
				if _flag_truthy(arg):
					return true
			"defeated":
				# 兼容 "defeated:<eid>"（GameState.flags 里有 defeated_<eid>）
				if _flag_truthy("defeated_%s" % arg):
					return true
			# enemy_defeated/scene_entered/item_picked_up/npc_talked_to 是事件型，
			# accept 时无法回看历史；只能依赖 EventBus 在事件发生时触发 _check_match。
	return false


func _check_match(event_key: String) -> void:
	## event_key 形如 "enemy_defeated:thug_lone"
	var to_complete: Array[StringName] = []
	for qid in states.keys():
		if states[qid] != QuestDef.Status.IN_PROGRESS:
			continue
		var def := load_def(qid)
		if def == null:
			continue
		for trig in def.completion_triggers:
			if trig == event_key:
				to_complete.append(qid)
				break
	for qid in to_complete:
		complete(qid)


func _flag_truthy(key: String) -> bool:
	var v: Variant = GameState.flags.get(key, null)
	if v == null: return false
	if typeof(v) == TYPE_BOOL: return v
	if typeof(v) == TYPE_INT: return v != 0
	if typeof(v) == TYPE_STRING: return v != ""
	return true


# --- EventBus 回调 ---

func _on_enemy_defeated(eid: StringName) -> void:
	_check_match("enemy_defeated:%s" % String(eid))


func _on_scene_entered(sid: StringName) -> void:
	_check_match("scene_entered:%s" % String(sid))


func _on_item_picked_up(iid: StringName, _n: int) -> void:
	_check_match("item_picked_up:%s" % String(iid))


func _on_flag_set(k: StringName, v: Variant) -> void:
	# 只在置真时触发匹配。设置 false 通常表示"取消标记"，不应推进任务。
	if typeof(v) == TYPE_BOOL and not v:
		return
	_check_match("flag_set:%s" % String(k))


func _on_npc_talked_to(nid: StringName) -> void:
	_check_match("npc_talked_to:%s" % String(nid))


# --- 持久化（SaveManager 调用） ---

func to_dict() -> Dictionary:
	var d := {}
	for qid in states.keys():
		d[String(qid)] = int(states[qid])
	return d


func from_dict(d: Dictionary) -> void:
	states.clear()
	for k in d.keys():
		states[StringName(k)] = int(d[k])
	active_quests_changed.emit()


func reset_for_new_game() -> void:
	states.clear()
	# _defs 缓存可保留（同一进程内多次 New Game 复用）
	active_quests_changed.emit()
