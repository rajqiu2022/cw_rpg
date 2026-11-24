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
##   evidence_acquired:<evidence_id>
##   evidence_verified:<evidence_id>
##   testimony_heard:<testimony_id>
##   testimony_verified:<testimony_id>

signal active_quests_changed   ## 任务列表（接受/完成/失败）变化时广播给 UI
signal tracked_quest_changed(qid: StringName)  ## 当前追踪的支线变化时广播给 Field HUD

const QUEST_DIR := "res://data/quests/"
const MAIN_QUEST_PROGRESS_ORDER: Array[StringName] = [
	&"q_ch1_main_get_sword",
	&"q_ch1_main_road",
	&"q_ch1_main_return_master",
	&"q_ch1_main_training",
	&"q_ch1_main_zhuwei",
	&"q_ch1_main_village_inquiry",
	&"q_ch1_main_zhuwei_wilds",
	&"q_ch1_main_west_ruin_trace",
	&"q_ch1_main_west_ruin",
	&"q_ch2_main_01_investigate",
	&"q_ch2_main_02_rescue_yue",
	&"q_ch2_main_03_trace_hideout",
	&"q_ch2_main_04_report_lingyue",
	&"q_ch3_main_00_assembly_clues",
	&"q_ch3_main_01_join_faction",
	&"q_ch3_main_02_faction_training",
	&"q_ch3_main_03_token_conspiracy",
	&"q_ch4_main_01_luoyang_case",
	&"q_ch4_main_03_canal_witness",
	&"q_ch4_main_02_ancient_temple",
	&"q_ch4_main_04_tunnel_mastermind",
	&"q_ch5_main_01_relief_route",
	&"q_ch5_main_02_grain_convoy",
	&"q_ch5_main_03_snow_pass",
	&"q_ch5_main_04_mine_survivor",
	&"q_ch5_main_05_false_banner_outpost",
	&"q_ch5_main_06_disclosure_choice",
	&"q_ch6_main_01_homecoming",
	&"q_ch6_main_02_old_residence",
	&"q_ch6_main_03_underground_archive",
	&"q_ch6_main_04_old_convoy_route",
	&"q_ch6_main_05_master_confrontation",
	&"q_ch6_main_06_ancient_road_letter",
	&"q_ch7_main_01_choose_first_route",
	&"q_ch7_main_02_compare_two_fronts",
	&"q_ch7_main_03_outer_wards",
	&"q_ch7_main_04_reform_and_witness",
	&"q_ch7_main_05_dead_name_live_access",
	&"q_ch7_main_06_threefold_identity_check",
	&"q_ch7_main_07_confirm_xueying_identity",
	&"q_ch7_main_08_inner_office_authorization",
	&"q_ch7_main_09_protect_witnesses",
	&"q_ch7_main_10_personal_authorization",
	&"q_ch7_main_11_disclosure_strategy",
	&"q_ch8_main_01_alliance_muster",
	&"q_ch8_main_02_mistwood_blockade",
	&"q_ch8_main_03_false_order_matrix",
	&"q_ch8_main_04_drum_mist_mechanisms",
	&"q_ch8_main_05_final_alliance_roles",
	&"q_ch8_main_06_first_false_order",
	&"q_ch8_main_07_su_first_confrontation",
	&"q_ch8_main_08_su_xueying_authorization",
	&"q_ch8_main_09_final_evacuation",
	&"q_ch8_main_10_xueying_resolution",
	&"q_ch8_main_11_su_final_order",
	&"q_ch8_main_12_truth_disclosure",
	&"q_ch8_main_13_aftermath_returns",
]
const LEGACY_MAIN_QUEST_MIGRATIONS := {
	&"q_ch1_main_01_thug": &"q_ch1_main_road",
	&"q_ch1_main_02_qingfeng": &"q_ch1_main_zhuwei",
}

var states: Dictionary = {}   ## quest_id (StringName) -> QuestDef.Status (int)
var _defs: Dictionary = {}    ## quest_id -> QuestDef 缓存
var tracked_side_quest_id: StringName = &""
var _auto_accept_quest_ids: Array[StringName] = []


func _ready() -> void:
	_discover_auto_accept_quests()
	EventBus.enemy_defeated.connect(_on_enemy_defeated)
	EventBus.scene_entered.connect(_on_scene_entered)
	EventBus.item_picked_up.connect(_on_item_picked_up)
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.npc_talked_to.connect(_on_npc_talked_to)
	EventBus.evidence_acquired.connect(_on_evidence_acquired)
	EventBus.evidence_verified.connect(_on_evidence_verified)
	EventBus.testimony_heard.connect(_on_testimony_heard)
	EventBus.testimony_verified.connect(_on_testimony_verified)


func _discover_auto_accept_quests() -> void:
	_auto_accept_quest_ids.clear()
	var directory := DirAccess.open(QUEST_DIR)
	if directory == null:
		return
	for file_name in directory.get_files():
		if not file_name.ends_with(".tres"):
			continue
		var qid := StringName(file_name.trim_suffix(".tres"))
		var quest := load_def(qid)
		if quest != null and not quest.auto_accept_triggers.is_empty():
			_auto_accept_quest_ids.append(qid)


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


func get_current_main_quest() -> QuestDef:
	## 主线按剧情进度确定，避免旧存档或同一对话的状态切换让 HUD
	## 依赖 Dictionary 插入顺序，显示出较早的任务阶段。
	return _find_main_quest(states, QuestDef.Status.IN_PROGRESS)


func get_saved_main_progress(saved_states: Dictionary) -> Dictionary:
	var snapshot := saved_states.duplicate()
	for old_id: StringName in LEGACY_MAIN_QUEST_MIGRATIONS:
		if snapshot.has(old_id):
			var canonical_id: StringName = LEGACY_MAIN_QUEST_MIGRATIONS[old_id]
			snapshot[canonical_id] = maxi(int(snapshot.get(canonical_id, 0)), int(snapshot[old_id]))
			snapshot.erase(old_id)
	var status := QuestDef.Status.IN_PROGRESS
	var quest := _find_main_quest(snapshot, status)
	if quest == null:
		status = QuestDef.Status.COMPLETED
		quest = _find_main_quest(snapshot, status)
	if quest == null:
		return {}
	var description := quest.get_description(status).replace("\n", " ").strip_edges()
	var sentence_end := description.find("。")
	if sentence_end >= 0:
		description = description.left(sentence_end + 1)
	if description.length() > 72:
		description = description.left(71) + "…"
	return {
		"title": quest.title,
		"completed": status == QuestDef.Status.COMPLETED,
		"description": description,
	}


func _find_main_quest(quest_states: Dictionary, status: QuestDef.Status) -> QuestDef:
	for index in range(MAIN_QUEST_PROGRESS_ORDER.size() - 1, -1, -1):
		var qid: StringName = MAIN_QUEST_PROGRESS_ORDER[index]
		if quest_states.get(qid) != status:
			continue
		var ordered_quest := load_def(qid)
		if ordered_quest != null:
			return ordered_quest
	var fallback_ids: Array[String] = []
	for raw_qid: Variant in quest_states:
		if raw_qid == "__tracked_side_quest" or quest_states[raw_qid] != status:
			continue
		var qid := StringName(String(raw_qid))
		var quest := load_def(qid)
		if quest != null and quest.kind == QuestDef.Kind.MAIN:
			fallback_ids.append(String(qid))
	fallback_ids.sort()
	return load_def(StringName(fallback_ids[0])) if not fallback_ids.is_empty() else null


func get_tracked_side_quest() -> QuestDef:
	if tracked_side_quest_id == &"" or not is_active(tracked_side_quest_id):
		return null
	var quest := load_def(tracked_side_quest_id)
	if quest == null or quest.kind != QuestDef.Kind.SIDE:
		return null
	return quest


func set_tracked_side_quest(qid: StringName) -> bool:
	if qid == &"":
		if tracked_side_quest_id == &"":
			return false
		tracked_side_quest_id = &""
		tracked_quest_changed.emit(tracked_side_quest_id)
		return true
	if not is_active(qid):
		return false
	var quest := load_def(qid)
	if quest == null or quest.kind != QuestDef.Kind.SIDE:
		return false
	if tracked_side_quest_id == qid:
		return false
	tracked_side_quest_id = qid
	tracked_quest_changed.emit(tracked_side_quest_id)
	return true


func toggle_tracked_side_quest(qid: StringName) -> bool:
	return set_tracked_side_quest(&"" if tracked_side_quest_id == qid else qid)


func _clear_tracking_if_matches(qid: StringName) -> void:
	if tracked_side_quest_id != qid:
		return
	tracked_side_quest_id = &""
	tracked_quest_changed.emit(tracked_side_quest_id)


# --- 状态变更 ---

func accept(qid: StringName) -> bool:
	## 同一任务重复接受 = 静默忽略（已 in_progress 或 completed 都不动作）。
	if get_status(qid) != QuestDef.Status.NOT_STARTED:
		return false
	var def := load_def(qid)
	if def == null:
		return false
	states[qid] = QuestDef.Status.IN_PROGRESS
	# 第一条支线默认进入追踪，但绝不覆盖玩家已经选择的支线。
	if def.kind == QuestDef.Kind.SIDE and get_tracked_side_quest() == null:
		tracked_side_quest_id = qid
		tracked_quest_changed.emit(tracked_side_quest_id)
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
	_clear_tracking_if_matches(qid)
	_grant_rewards(def)
	EventBus.quest_completed.emit(qid)
	if qid in [&"q_ch8_main_03_final_boss", &"q_ch8_main_13_aftermath_returns"]:
		GameState.set_flag(&"chapter8_complete", true)
	active_quests_changed.emit()
	print("[Quest] ✓ completed: %s 「%s」 (gold +%d, exp +%d)" % [
		qid, def.title, def.reward_gold, def.reward_exp
	])
	return true


func fail(qid: StringName) -> bool:
	if get_status(qid) != QuestDef.Status.IN_PROGRESS:
		return false
	states[qid] = QuestDef.Status.FAILED
	_clear_tracking_if_matches(qid)
	EventBus.quest_failed.emit(qid)
	active_quests_changed.emit()
	return true


# --- 奖励发放 ---

func _grant_rewards(def: QuestDef) -> void:
	if def.reward_gold > 0:
		GameState.add_gold(def.reward_gold)
	if def.reward_exp > 0 and GameState.player != null:
		GameState.player.gain_exp(def.reward_exp)
		GameState.add_training_points(def.reward_exp)
	for entry in def.reward_items:
		# 兼容早期章节数据使用的 item_id；新数据统一使用 id。
		var iid: String = String(entry.get("id", entry.get("item_id", "")))
		var n: int = int(entry.get("count", 1))
		if iid != "":
			Inventory.add_item(StringName(iid), n)
	for skill_id: StringName in def.reward_skills:
		GameState.learn_skill(skill_id)
	var faction_id := String(GameState.player_faction)
	var faction_rewards: Variant = def.reward_skills_by_faction.get(faction_id, [])
	if faction_rewards is Array:
		for raw_skill_id: Variant in faction_rewards:
			GameState.learn_skill(StringName(String(raw_skill_id)))
	for raw_flag: Variant in def.reward_skills_by_flag.keys():
		var flag_id := String(raw_flag)
		if not bool(GameState.flags.get(flag_id, false)):
			continue
		var flag_rewards: Variant = def.reward_skills_by_flag[raw_flag]
		if flag_rewards is Array:
			for raw_skill_id: Variant in flag_rewards:
				GameState.learn_skill(StringName(String(raw_skill_id)))


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
	if def.require_all_completion_triggers:
		return _all_triggers_satisfied(def.completion_triggers)
	for trig in def.completion_triggers:
		if _trigger_historically_satisfied(trig):
			return true
	return false


func _trigger_historically_satisfied(trigger: String) -> bool:
	var parts: PackedStringArray = trigger.split(":", true, 1)
	if parts.size() < 2:
		return false
	var ev: String = parts[0]
	var arg: String = parts[1]
	match ev:
		"flag_set":
			return _flag_truthy(arg)
		"defeated":
			return _flag_truthy("defeated_%s" % arg)
		"evidence_acquired":
			return InvestigationState.has_evidence(StringName(arg))
		"evidence_verified":
			return InvestigationState.is_evidence_verified(StringName(arg))
		"testimony_heard":
			return InvestigationState.has_testimony(StringName(arg))
		"testimony_verified":
			return InvestigationState.is_testimony_verified(StringName(arg))
	return false


func _all_triggers_satisfied(triggers: Array[String], current_event: String = "") -> bool:
	if triggers.is_empty():
		return false
	for trigger in triggers:
		if trigger == current_event or _trigger_historically_satisfied(trigger):
			continue
		return false
	return true


func _auto_accept_for_event(event_key: String) -> void:
	for qid: StringName in _auto_accept_quest_ids:
		if get_status(qid) != QuestDef.Status.NOT_STARTED:
			continue
		var quest := load_def(qid)
		if quest != null and event_key in quest.auto_accept_triggers:
			accept(qid)


func reconcile_auto_accept_quests() -> void:
	## 旧存档可能已经拥有首个线索 flag；读档时补接对应长线任务。
	for qid: StringName in _auto_accept_quest_ids:
		if get_status(qid) != QuestDef.Status.NOT_STARTED:
			continue
		var quest := load_def(qid)
		if quest == null:
			continue
		for trigger in quest.auto_accept_triggers:
			if _trigger_historically_satisfied(trigger):
				accept(qid)
				break


func _check_match(event_key: String) -> void:
	## event_key 形如 "enemy_defeated:thug_lone"
	_auto_accept_for_event(event_key)
	_emit_progress_for_event(event_key)
	var to_complete: Array[StringName] = []
	for qid in states.keys():
		if states[qid] != QuestDef.Status.IN_PROGRESS:
			continue
		var def := load_def(qid)
		if def == null:
			continue
		if def.require_all_completion_triggers:
			if _all_triggers_satisfied(def.completion_triggers, event_key):
				to_complete.append(qid)
			continue
		for trig in def.completion_triggers:
			if trig == event_key:
				to_complete.append(qid)
				break
	for qid in to_complete:
		complete(qid)


func _emit_progress_for_event(event_key: String) -> void:
	var progressed := false
	for raw_qid: Variant in states.keys():
		var qid := StringName(String(raw_qid))
		if not is_active(qid):
			continue
		var quest := load_def(qid)
		if quest == null or event_key in quest.completion_triggers:
			continue
		for record: Dictionary in quest.progress_records:
			if String(record.get("trigger", "")) == event_key:
				EventBus.quest_progressed.emit(qid)
				progressed = true
				break
	if progressed:
		active_quests_changed.emit()


func get_progress_record_texts(qid: StringName) -> Array[String]:
	var result: Array[String] = []
	var quest := load_def(qid)
	if quest == null:
		return result
	for record: Dictionary in quest.progress_records:
		var trigger := String(record.get("trigger", ""))
		var text := String(record.get("text", "")).strip_edges()
		if not trigger.is_empty() and not text.is_empty() and _trigger_historically_satisfied(trigger):
			result.append(text)
	return result


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


func _on_evidence_acquired(evidence_id: StringName) -> void:
	_check_match("evidence_acquired:%s" % String(evidence_id))


func _on_evidence_verified(evidence_id: StringName) -> void:
	_check_match("evidence_verified:%s" % String(evidence_id))


func _on_testimony_heard(testimony_id: StringName) -> void:
	_check_match("testimony_heard:%s" % String(testimony_id))


func _on_testimony_verified(testimony_id: StringName) -> void:
	_check_match("testimony_verified:%s" % String(testimony_id))


# --- 持久化（SaveManager 调用） ---

func to_dict() -> Dictionary:
	var d := {}
	for qid in states.keys():
		d[String(qid)] = int(states[qid])
	d["__tracked_side_quest"] = String(tracked_side_quest_id)
	return d


func from_dict(d: Dictionary) -> void:
	states.clear()
	for k in d.keys():
		if String(k) == "__tracked_side_quest":
			continue
		states[StringName(k)] = int(d[k])
	_migrate_legacy_main_quests()
	_migrate_ch1_expansion()
	_reconcile_ch1_main_quest_gap()
	reconcile_auto_accept_quests()
	tracked_side_quest_id = StringName(String(d.get("__tracked_side_quest", "")))
	if get_tracked_side_quest() == null:
		tracked_side_quest_id = &""
	active_quests_changed.emit()
	tracked_quest_changed.emit(tracked_side_quest_id)


func _migrate_legacy_main_quests() -> void:
	for legacy_qid: StringName in LEGACY_MAIN_QUEST_MIGRATIONS:
		if not states.has(legacy_qid):
			continue
		var canonical_qid: StringName = LEGACY_MAIN_QUEST_MIGRATIONS[legacy_qid]
		var legacy_status: int = int(states[legacy_qid])
		var canonical_status: int = int(states.get(canonical_qid, QuestDef.Status.NOT_STARTED))
		states[canonical_qid] = maxi(canonical_status, legacy_status)
		states.erase(legacy_qid)


func _migrate_ch1_expansion() -> void:
	## 2026-08 第一章扩展：旧档可能在抵达竹尾村时直接接到了 Boss 主线。
	## 尚未击败赵无忌的存档回到对应调查阶段，避免绕过密林与洞窟。
	if GameState.current_chapter != 1 or _flag_truthy("chapter1_complete") or _flag_truthy("defeated_boss_zhao_wuji"):
		return
	if get_status(&"q_ch1_main_west_ruin") == QuestDef.Status.IN_PROGRESS \
			and not _flag_truthy("zhao_wuji_identified"):
		states.erase(&"q_ch1_main_west_ruin")
	if not _flag_truthy("entered_zhuwei_village"):
		return
	if _flag_truthy("zhao_wuji_identified"):
		if get_status(&"q_ch1_main_west_ruin") == QuestDef.Status.NOT_STARTED:
			states[&"q_ch1_main_west_ruin"] = QuestDef.Status.IN_PROGRESS
	elif _flag_truthy("clue_west_ruin_supply_route"):
		if get_status(&"q_ch1_main_west_ruin_trace") == QuestDef.Status.NOT_STARTED:
			states[&"q_ch1_main_west_ruin_trace"] = QuestDef.Status.IN_PROGRESS
	elif _flag_truthy("zhuwei_village_inquiry_done"):
		if get_status(&"q_ch1_main_zhuwei_wilds") == QuestDef.Status.NOT_STARTED:
			states[&"q_ch1_main_zhuwei_wilds"] = QuestDef.Status.IN_PROGRESS
	else:
		if get_status(&"q_ch1_main_village_inquiry") == QuestDef.Status.NOT_STARTED:
			states[&"q_ch1_main_village_inquiry"] = QuestDef.Status.IN_PROGRESS


func _reconcile_ch1_main_quest_gap() -> void:
	## 早期存档只保存了剧情 flag，没有对应 Quest 状态。根据已经发生的
	## 故事节点恢复“下一件该做的事”，让玩家读档后不必重开或重播对话。
	if GameState.current_chapter != 1 or _flag_truthy("chapter1_complete"):
		return
	if get_current_main_quest() != null:
		return
	if get_status(&"q_ch1_main_zhuwei") == QuestDef.Status.COMPLETED \
			or get_status(&"q_ch1_main_village_inquiry") != QuestDef.Status.NOT_STARTED \
			or get_status(&"q_ch1_main_zhuwei_wilds") != QuestDef.Status.NOT_STARTED \
			or get_status(&"q_ch1_main_west_ruin_trace") != QuestDef.Status.NOT_STARTED \
			or get_status(&"q_ch1_main_west_ruin") != QuestDef.Status.NOT_STARTED:
		return
	var inferred_qid: StringName = &""
	if _flag_truthy("master_training_done"):
		inferred_qid = &"q_ch1_main_zhuwei"
	elif _flag_truthy("defeated_thug_lone"):
		inferred_qid = &"q_ch1_main_return_master"
	elif _flag_truthy("got_sword"):
		inferred_qid = &"q_ch1_main_road"
	elif _flag_truthy("master_farewell_done"):
		inferred_qid = &"q_ch1_main_get_sword"
	if inferred_qid == &"" or load_def(inferred_qid) == null:
		return
	states[inferred_qid] = QuestDef.Status.IN_PROGRESS
	print("[Quest] restored missing chapter 1 main quest from story flags: %s" % inferred_qid)


func reset_for_new_game() -> void:
	states.clear()
	tracked_side_quest_id = &""
	# _defs 缓存可保留（同一进程内多次 New Game 复用）
	active_quests_changed.emit()
	tracked_quest_changed.emit(tracked_side_quest_id)
