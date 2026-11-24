extends Node

var _checked := 0
var _failed := 0


func _ready() -> void:
	var quest_manager: Node = get_tree().root.get_node_or_null("QuestManager")
	_check(quest_manager != null, "QuestManager autoload is available")
	if quest_manager == null:
		get_tree().quit(1)
		return
	quest_manager.call("reset_for_new_game")
	var states: Dictionary = quest_manager.get("states")
	states[&"q_ch1_main_zhuwei"] = QuestDef.Status.IN_PROGRESS
	states[&"q_ch1_side_02_cliff_herb"] = QuestDef.Status.IN_PROGRESS
	quest_manager.set("states", states)
	_check(not bool(quest_manager.call("set_tracked_side_quest", &"q_ch1_main_zhuwei")), "main quests cannot occupy the tracked-side slot")
	var current_main := quest_manager.call("get_current_main_quest") as QuestDef
	_check(current_main != null and current_main.quest_id == &"q_ch1_main_zhuwei", "HUD resolves the canonical current main quest")
	_check(bool(quest_manager.call("set_tracked_side_quest", &"q_ch1_side_02_cliff_herb")), "active side quest can be tracked")
	var saved: Dictionary = quest_manager.call("to_dict") as Dictionary
	_check(String(saved.get("__tracked_side_quest", "")) == "q_ch1_side_02_cliff_herb", "tracked side quest is serialized")
	quest_manager.call("reset_for_new_game")
	quest_manager.call("from_dict", saved)
	var tracked := quest_manager.call("get_tracked_side_quest") as QuestDef
	_check(tracked != null and tracked.quest_id == &"q_ch1_side_02_cliff_herb", "tracked side quest survives save round-trip")

	var packed := load("res://scenes/ui/field_primary_hud.tscn") as PackedScene
	_check(packed != null, "field HUD scene loads")
	if packed != null:
		var hud := packed.instantiate() as FieldPrimaryHud
		add_child.call_deferred(hud)
		await get_tree().process_frame
		var main := quest_manager.call("load_def", &"q_ch1_main_zhuwei") as QuestDef
		hud.set_quest_tracker(main.title, main.get_tracker_hint(), tracked.title, tracked.get_tracker_hint())
		var panel := hud.get_node("QuestSummaryPanel") as PanelContainer
		var summary := hud.get_node("QuestSummaryPanel/QuestSummary") as RichTextLabel
		_check(panel != null and panel.visible and panel.position.x < 50.0, "tracker is visible on the left")
		var style := panel.get_theme_stylebox("panel")
		_check(style is StyleBoxEmpty, "tracker has no black panel or border")
		_check(main.title in summary.text and tracked.title in summary.text, "tracker shows current main and tracked side quest")
		_check("目标地点" in summary.text, "tracker labels its spoiler-free destination")
		_check(main.desc_in_progress not in summary.text, "tracker does not expose the quest-log narrative")
		_check("[b]" not in summary.text, "tracker text uses regular weight instead of blurred bold markup")
		hud.queue_free()
	quest_manager.call("from_dict", {"q_ch1_main_01_thug": QuestDef.Status.IN_PROGRESS, "q_ch1_main_02_qingfeng": QuestDef.Status.IN_PROGRESS})
	var migrated_states: Dictionary = quest_manager.get("states")
	_check(not migrated_states.has(&"q_ch1_main_01_thug") and not migrated_states.has(&"q_ch1_main_02_qingfeng"), "legacy duplicate main quest ids are removed on load")
	_check(int(migrated_states.get(&"q_ch1_main_road", QuestDef.Status.NOT_STARTED)) == QuestDef.Status.IN_PROGRESS, "legacy road quest migrates to the canonical road quest")
	_check(int(migrated_states.get(&"q_ch1_main_zhuwei", QuestDef.Status.NOT_STARTED)) == QuestDef.Status.IN_PROGRESS, "legacy village quest migrates to the canonical village quest")
	var game_state: Node = get_tree().root.get_node_or_null("GameState")
	_check(game_state != null, "GameState autoload is available for quest transition checks")
	if game_state != null:
		game_state.call("reset_for_new_game")
		quest_manager.call("reset_for_new_game")
		_check(bool(quest_manager.call("accept", &"q_ch1_main_get_sword")), "master can start the get-sword main quest")
		current_main = quest_manager.call("get_current_main_quest") as QuestDef
		_check(current_main != null and current_main.quest_id == &"q_ch1_main_get_sword", "HUD shows find-the-blacksmith after the master's farewell")
		game_state.call("set_flag", &"got_sword", true)
		_check(bool(quest_manager.call("is_completed", &"q_ch1_main_get_sword")), "receiving the sword completes the get-sword phase")
		_check(bool(quest_manager.call("accept", &"q_ch1_main_road")), "blacksmith can start the Zhuwei-bound road phase")
		current_main = quest_manager.call("get_current_main_quest") as QuestDef
		_check(current_main != null and current_main.quest_id == &"q_ch1_main_road", "HUD switches to the Zhuwei-bound main quest after receiving the sword")
		quest_manager.call("reset_for_new_game")
		game_state.call("reset_for_new_game")
		game_state.call("set_flag", &"master_farewell_done", true)
		quest_manager.call("from_dict", {})
		current_main = quest_manager.call("get_current_main_quest") as QuestDef
		_check(current_main != null and current_main.quest_id == &"q_ch1_main_get_sword", "old save after the master's farewell restores the missing blacksmith objective")
		quest_manager.call("reset_for_new_game")
		game_state.call("set_flag", &"got_sword", true)
		quest_manager.call("from_dict", {})
		current_main = quest_manager.call("get_current_main_quest") as QuestDef
		_check(current_main != null and current_main.quest_id == &"q_ch1_main_road", "old save after receiving the sword restores the Zhuwei-bound objective")
	quest_manager.call("reset_for_new_game")
	print("[FieldQuestTracker] checked=%d failed=%d" % [_checked, _failed])
	get_tree().quit(1 if _failed > 0 else 0)


func _check(condition: bool, message: String) -> void:
	_checked += 1
	if condition:
		return
	_failed += 1
	push_error("[FieldQuestTracker] %s" % message)
