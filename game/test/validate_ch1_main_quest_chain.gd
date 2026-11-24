extends SceneTree

var _checked := 0
var _failed := 0


func _initialize() -> void:
	var get_sword := load("res://data/quests/q_ch1_main_get_sword.tres") as QuestDef
	var road := load("res://data/quests/q_ch1_main_road.tres") as QuestDef
	_check(get_sword != null, "领取佩剑主线资源存在")
	_check(road != null, "前往竹尾村山道主线资源存在")
	if get_sword != null:
		_check(get_sword.kind == QuestDef.Kind.MAIN, "领取佩剑属于主线")
		_check(get_sword.completion_triggers.has("flag_set:got_sword"), "领取佩剑由实际拿到剑完成")
	if road != null:
		_check("竹尾村" in road.title, "取剑后的下一条主线明确指向竹尾村")

	var master := load("res://data/dialogs/ch1_tutorial_xingfantian.tres") as DialogScript
	var blacksmith := load("res://data/dialogs/ch1_tutorial_duqingshan.tres") as DialogScript
	var after_battle := load("res://data/dialogs/ch1_road_after_battle.tres") as DialogScript
	var return_master := load("res://data/dialogs/ch1_return_to_master.tres") as DialogScript
	_check(_node_accepts(master, &"merge8", &"q_ch1_main_get_sword"), "师傅交代后立即追踪领取佩剑")
	_check(_node_sets_flag(blacksmith, &"n5", "got_sword"), "杜青衫交剑节点写入 got_sword")
	_check(_node_accepts(blacksmith, &"n5", &"q_ch1_main_road"), "领取佩剑后立即追踪前往竹尾村")
	_check(_node_accepts(after_battle, &"n4", &"q_ch1_main_return_master"), "山道遇袭后切换为回禀师傅")
	_check(_node_accepts(return_master, &"n4", &"q_ch1_main_training"), "复命时切换为师门授艺")
	_check(_node_completes(return_master, &"n10", &"q_ch1_main_training"), "授艺结束完成当前主线")
	_check(_node_accepts(return_master, &"n10", &"q_ch1_main_zhuwei"), "授艺结束立即继续追踪前往竹尾村")

	var road_enter := load("res://data/dialogs/ch1_road_enter.tres") as DialogScript
	_check(not _dialog_mentions_legacy(road_enter), "现行山道入口不再接取重复旧主线")
	_validate_zhuwei_investigation_chain()
	_validate_gated_collection_and_cave()
	_validate_old_ledger_turnin()
	print("[Ch1MainQuestChain] checked=%d failed=%d" % [_checked, _failed])
	quit(1 if _failed > 0 else 0)


func _node(dialog: DialogScript, node_id: StringName) -> DialogNode:
	return dialog.find_node_by_id(node_id) if dialog != null else null


func _node_accepts(dialog: DialogScript, node_id: StringName, quest_id: StringName) -> bool:
	var dialog_node := _node(dialog, node_id)
	return dialog_node != null and dialog_node.accept_quest == quest_id


func _node_completes(dialog: DialogScript, node_id: StringName, quest_id: StringName) -> bool:
	var dialog_node := _node(dialog, node_id)
	return dialog_node != null and dialog_node.complete_quest == quest_id


func _node_sets_flag(dialog: DialogScript, node_id: StringName, flag_key: String) -> bool:
	var dialog_node := _node(dialog, node_id)
	if dialog_node == null:
		return false
	for entry: Dictionary in dialog_node.set_flags:
		if String(entry.get("key", "")) == flag_key and bool(entry.get("value", true)):
			return true
	return false


func _dialog_mentions_legacy(dialog: DialogScript) -> bool:
	if dialog == null:
		return true
	for dialog_node: DialogNode in dialog.nodes:
		if dialog_node.accept_quest in [&"q_ch1_main_01_thug", &"q_ch1_main_02_qingfeng"]:
			return true
	return false


func _validate_zhuwei_investigation_chain() -> void:
	var arrival := load("res://data/dialogs/ch1_s2_intro.tres") as DialogScript
	var guard := load("res://data/dialogs/ch1_s2_guard.tres") as DialogScript
	var innkeeper := load("res://data/dialogs/ch1_s2_inn_keeper.tres") as DialogScript
	var scout := load("res://data/dialogs/ch1_s2_patrol_scout.tres") as DialogScript
	var report := load("res://data/dialogs/ch1_s2_guard_report.tres") as DialogScript
	var cave_clue := load("res://data/dialogs/ch1_zhuwei_cave_clue.tres") as DialogScript
	_check(_dialog_accepts(arrival, &"q_ch1_main_village_inquiry"), "进入竹尾村后接取村内调查主线")
	_check(_dialog_sets_flag(guard, "zhuwei_guard_briefed"), "守村人提供第一条调查线索")
	_check(_dialog_sets_flag(innkeeper, "zhuwei_inn_clue"), "客栈老板提供第二条调查线索")
	_check(_dialog_sets_flag(scout, "zhuwei_scout_clue"), "巡山者提供第三条调查线索")
	_check(_dialog_completes(report, &"q_ch1_main_village_inquiry"), "三条线索回报后完成村内调查")
	_check(_dialog_accepts(report, &"q_ch1_main_zhuwei_wilds"), "村内调查完成后接取后山追查")
	_check(_dialog_sets_flag(cave_clue, "clue_west_ruin_supply_route"), "洞内送货记录推进到城西线索")
	_check(_dialog_completes(cave_clue, &"q_ch1_main_zhuwei_wilds"), "调查洞内记录后完成后山主线")
	_check(_dialog_accepts(cave_clue, &"q_ch1_main_west_ruin_trace"), "后山主线完成后自动衔接城西废宅")


func _validate_gated_collection_and_cave() -> void:
	var forest_scene := load("res://data/scenes/ch1_s3_zhuwei_forest.tres") as SceneScript
	var cave_scene := load("res://data/scenes/ch1_s4_zhuwei_beast_cave.tres") as SceneScript
	var deep_scene := load("res://data/scenes/ch1_s4_cave_deep_den.tres") as SceneScript
	_check(forest_scene != null and forest_scene.map_layout != null, "竹尾密林地图资源存在")
	_check(cave_scene != null and cave_scene.map_layout != null, "双路山洞地图资源存在")
	if forest_scene != null and forest_scene.map_layout != null:
		var herb := _find_map_entry(forest_scene.map_layout.visual_objects, "forest_hemostatic_herb_visual")
		var beast := _find_map_entry(forest_scene.map_layout.interactions, "forest_beast_trail")
		_check(String(herb.get("require_quest_active", "")) == "q_ch1_side_12_forest_medicine", "止血草只在接取任务后显示")
		_check(String(herb.get("interaction_action", "")) == "dialog:ch1_zhuwei_forest_herb", "止血草拥有可点击采集交互")
		_check(String(beast.get("require_quest_active", "")) == "q_ch1_main_zhuwei_wilds", "猛兽踪迹只在后山主线激活时出现")
	if cave_scene != null and cave_scene.map_layout != null and deep_scene != null and deep_scene.map_layout != null:
		var wolf := _find_map_entry(deep_scene.map_layout.interactions, "cave_alpha_wolf")
		var clue := _find_map_entry(deep_scene.map_layout.interactions, "cave_supply_clue")
		var chest := _find_map_entry(cave_scene.map_layout.interactions, "cave_left_chest")
		_check(String(wolf.get("require_quest_active", "")) == "q_ch1_main_zhuwei_wilds", "洞内首领仅在主线激活时出现")
		_check(String(clue.get("require_flag", "")) == "defeated_zhuwei_cave_wolf", "击退洞内首领后才显示送货记录")
		_check(not chest.is_empty() and String(chest.get("action", "")) == "dialog:ch1_zhuwei_cave_chest", "左路背景宝箱有独立交互且不重复叠图")
		_check(cave_scene.map_layout.portals.size() == 3, "入口营地分出矿道与水道并保留密林回程")


func _validate_old_ledger_turnin() -> void:
	var center := load("res://data/scenes/linxi_village_center.tres") as SceneScript
	var verify := load("res://data/dialogs/linxi_center_herbalist_ledger_verify.tres") as DialogScript
	var herbalist: Dictionary = {}
	if center != null:
		for entry: Dictionary in center.npcs:
			if String(entry.get("npc_id", "")) == "linxi_herbalist":
				herbalist = entry
				break
	var variants: Array = herbalist.get("dialog_variants", [])
	_check(not variants.is_empty() and String((variants[0] as Dictionary).get("require_flags", [""])[0]) == "found_linxi_old_ledger", "拾取旧账后药师出现鉴定对话")
	_check(_dialog_sets_flag(verify, "linxi_old_ledger_verified"), "药师鉴定写入旧账验证标记")
	_check(_dialog_completes(verify, &"q_ch1_side_11_old_ledger"), "旧账支线可在第一章内完成")


func _dialog_accepts(dialog: DialogScript, quest_id: StringName) -> bool:
	if dialog == null:
		return false
	for dialog_node: DialogNode in dialog.nodes:
		if dialog_node.accept_quest == quest_id:
			return true
	return false


func _dialog_completes(dialog: DialogScript, quest_id: StringName) -> bool:
	if dialog == null:
		return false
	for dialog_node: DialogNode in dialog.nodes:
		if dialog_node.complete_quest == quest_id:
			return true
	return false


func _dialog_sets_flag(dialog: DialogScript, flag_key: String) -> bool:
	if dialog == null:
		return false
	for dialog_node: DialogNode in dialog.nodes:
		for entry: Dictionary in dialog_node.set_flags:
			if String(entry.get("key", "")) == flag_key and bool(entry.get("value", true)):
				return true
	return false


func _find_map_entry(entries: Array[Dictionary], id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if String(entry.get("id", "")) == id:
			return entry
	return {}


func _check(condition: bool, message: String) -> void:
	_checked += 1
	if condition:
		return
	_failed += 1
	push_error("[Ch1MainQuestChain] %s" % message)
