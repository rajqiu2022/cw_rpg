extends SceneTree

const CLIFF_QUEST := &"q_ch1_side_02_cliff_herb"

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_cliff_herb_chain()
	_validate_side_quest_decisions()
	_validate_runtime_completion()
	print("[Ch1PolishBatchE20260821] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[Ch1PolishBatchE20260821] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_cliff_herb_chain() -> void:
	var quest := load("res://data/quests/q_ch1_side_02_cliff_herb.tres") as QuestDef
	_check(quest != null, "悬崖采药任务可加载")
	if quest != null:
		_check(quest.tracker_hint == "林西村外 · 山道", "HUD只提示采集地点")
		_check("flag_set:cliff_herb_delivered" in quest.completion_triggers, "任务在回交药师后结算而非采到即完成")
		var reward_ids: Array[String] = []
		for reward: Dictionary in quest.reward_items:
			reward_ids.append(String(reward.get("item_id", reward.get("id", ""))))
		_check("lingzhi_pill" not in reward_ids and "life_extend_pill" not in reward_ids, "第一章采药不提前发放神品或高阶救命丹")
		_check("herb_bundle" in reward_ids and "healing_pill_minor" in reward_ids, "奖励符合第一章补给定位")

	var center := load("res://data/scenes/linxi_village_center.tres") as SceneScript
	var herbalist := _find_entry(center.npcs if center != null else [], "linxi_herbalist", "npc_id")
	_check(not herbalist.is_empty(), "林西药师作为任务委托人存在")
	_check(_has_variant(herbalist, "linxi_cliff_herb_offer", "require_flags", "master_training_done"), "师门授艺后才出现采药邀约")
	_check(_has_variant(herbalist, "linxi_cliff_herb_waiting", "require_quest_active", String(CLIFF_QUEST)), "进行中复访不会重复派任务")
	_check(_has_variant(herbalist, "linxi_cliff_herb_done", "require_quest_completed", String(CLIFF_QUEST)), "完成后药师拥有独立对白")
	_check(_has_variant(herbalist, "linxi_cliff_herb_turnin", "require_flags", "cliff_herb_collected"), "采到药草后切换为回交对白")

	var road := load("res://data/scenes/ch1_s1_road.tres") as SceneScript
	var herb_visual := _find_entry(road.map_layout.visual_objects if road != null and road.map_layout != null else [], "road_cliff_herb_visual", "id")
	_check(not herb_visual.is_empty(), "山道拥有可见的任务药草物件")
	_check(String(herb_visual.get("require_quest_active", "")) == String(CLIFF_QUEST), "只有接取后才显示药草")
	_check(String(herb_visual.get("hide_flag", "")) == "cliff_herb_collected", "采集后药草立即消失")
	_check(String(herb_visual.get("interaction_action", "")) == "dialog:ch1_cliff_herb_collect", "药草连接正式采集对白")
	var herb_pos: Vector2 = herb_visual.get("pos", Vector2(-1, -1))
	_check(_point_in_walkable(road.map_layout, herb_pos), "药草交互点位于正向可行走区域")

	var offer := load("res://data/dialogs/linxi_cliff_herb_offer.tres") as DialogScript
	var collect := load("res://data/dialogs/ch1_cliff_herb_collect.tres") as DialogScript
	var turnin := load("res://data/dialogs/linxi_cliff_herb_turnin.tres") as DialogScript
	_check(_dialog_accepts(offer, CLIFF_QUEST) and _dialog_sets_flag(offer, "cliff_herb_accepted"), "委托由玩家确认后接取")
	_check(_dialog_sets_flag(collect, "cliff_herb_collected"), "采集对白写入取得状态")
	_check(_dialog_completes(turnin, CLIFF_QUEST) and _dialog_sets_flag(turnin, "cliff_herb_delivered"), "回交对白唯一结算任务")


func _validate_side_quest_decisions() -> void:
	var plan := load("res://data/chapters/chapter_1_content_plan.tres") as ChapterContentPlan
	_check(plan != null and CLIFF_QUEST in plan.side_quest_ids, "悬崖采药进入第一章现行可玩清单")
	if plan == null:
		return
	var decisions: Dictionary = {}
	for entry: Dictionary in plan.side_quest_decisions:
		decisions[String(entry.get("quest_id", ""))] = entry
	_check(String((decisions.get("q_ch1_side_04_tiger_hunt", {}) as Dictionary).get("decision", "")) == "migrate", "独猎猛虎明确迁章")
	_check(int((decisions.get("q_ch1_side_04_tiger_hunt", {}) as Dictionary).get("target_chapter", 0)) == 5, "独猎猛虎迁至第五章")
	_check(String((decisions.get("q_ch1_side_05_ancestral_theft", {}) as Dictionary).get("replacement_id", "")) == "q_ch6_side_02_home_belongings", "祠堂失窃并入第六章旧居遗物")
	_check(String((decisions.get("q_ch1_side_07_village_duel", {}) as Dictionary).get("replacement_id", "")) == "q_ch1_side_09_martial_hall", "村口试剑并入武馆试剑")
	for removed_id: StringName in [&"q_ch1_side_04_tiger_hunt", &"q_ch1_side_05_ancestral_theft", &"q_ch1_side_07_village_duel"]:
		_check(removed_id not in plan.side_quest_ids, "%s不再冒充当前可玩支线" % removed_id)


func _validate_runtime_completion() -> void:
	var quest_manager := root.get_node_or_null("QuestManager")
	var game_state := root.get_node_or_null("GameState")
	var inventory := root.get_node_or_null("Inventory")
	_check(quest_manager != null and game_state != null and inventory != null, "任务、状态与背包Autoload可用于运行回归")
	if quest_manager == null or game_state == null or inventory == null:
		return
	quest_manager.call("reset_for_new_game")
	inventory.call("reset_for_new_game")
	_check(bool(quest_manager.call("accept", CLIFF_QUEST)), "运行时可接取悬崖采药")
	game_state.call("set_flag", &"cliff_herb_collected", true)
	_check(bool(quest_manager.call("is_active", CLIFF_QUEST)), "采到药草后仍保持进行中")
	var gold_before := int(game_state.get("gold"))
	var herbs_before := int(inventory.call("count_of", &"herb_bundle"))
	game_state.call("set_flag", &"cliff_herb_delivered", true)
	_check(bool(quest_manager.call("is_completed", CLIFF_QUEST)), "交回药草后任务完成")
	_check(int(game_state.get("gold")) == gold_before + 12, "完成奖励发放12金")
	_check(int(inventory.call("count_of", &"herb_bundle")) == herbs_before + 2, "完成奖励发放两束药草")
	var gold_after := int(game_state.get("gold"))
	game_state.call("set_flag", &"cliff_herb_delivered", true)
	_check(int(game_state.get("gold")) == gold_after, "重复交付旗标不重复发奖")


func _find_entry(entries: Array, entry_id: String, key: String) -> Dictionary:
	for raw_entry: Variant in entries:
		if raw_entry is Dictionary and String((raw_entry as Dictionary).get(key, "")) == entry_id:
			return raw_entry as Dictionary
	return {}


func _has_variant(npc: Dictionary, dialog_id: String, key: String, value: String) -> bool:
	for raw_variant: Variant in npc.get("dialog_variants", []):
		if not raw_variant is Dictionary:
			continue
		var variant := raw_variant as Dictionary
		if String(variant.get("dialog_id", "")) != dialog_id:
			continue
		var actual: Variant = variant.get(key, "")
		if actual is Array:
			return value in actual
		return String(actual) == value
	return false


func _point_in_walkable(layout: WalkableMapLayout, point: Vector2) -> bool:
	if layout == null:
		return false
	for region: PackedVector2Array in layout.walkable_regions:
		if Geometry2D.is_point_in_polygon(point, region):
			return true
	return false


func _dialog_accepts(dialog: DialogScript, quest_id: StringName) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node != null and node.accept_quest == quest_id:
			return true
	return false


func _dialog_completes(dialog: DialogScript, quest_id: StringName) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node != null and node.complete_quest == quest_id:
			return true
	return false


func _dialog_sets_flag(dialog: DialogScript, flag_key: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node == null:
			continue
		for flag: Dictionary in node.set_flags:
			if String(flag.get("key", "")) == flag_key and bool(flag.get("value", true)):
				return true
	return false


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
