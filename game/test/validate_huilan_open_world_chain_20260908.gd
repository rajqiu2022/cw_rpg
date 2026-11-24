extends SceneTree

const QUEST_ID := &"q_legend_huilan_redirecting_art"
const CLUES: Array[StringName] = [
	&"huilan_echo_understood",
	&"huilan_bell_counterforce_understood",
	&"huilan_yielding_position_understood",
	&"huilan_water_rule_understood",
	&"huilan_balance_understood",
]
const SCENE_DIALOGS := {
	"res://data/scenes/ch1_s2_qingfeng.tres": [&"huilan_openworld_echo", &"huilan_openworld_balance", &"huilan_openworld_final_trial"],
	"res://data/scenes/ch2_s4_lingyue_gate.tres": [&"huilan_openworld_bell"],
	"res://data/scenes/ch3_s1_wulin_assembly.tres": [&"huilan_openworld_board"],
	"res://data/scenes/ch4_s1_luoyang_yamen.tres": [&"huilan_openworld_water_rule"],
}

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var quest := load("res://data/quests/q_legend_huilan_redirecting_art.tres") as QuestDef
	_check(quest != null, "open-world quest loads")
	if quest != null:
		_check(quest.chapter_independent, "quest explicitly ignores chapter order")
		_check(quest.require_all_completion_triggers, "all authored nodes are mandatory")
		_check(quest.completion_triggers.size() == 6, "five clues plus final trial are authored")
		_check(quest.auto_accept_triggers.size() == 5, "any clue can start the quest")
		_check(quest.reward_skills == [&"huilan_redirecting_art"], "the full chain rewards 移花换劲")

	for scene_path: String in SCENE_DIALOGS:
		var source := FileAccess.get_file_as_string(scene_path)
		for dialog_id: StringName in SCENE_DIALOGS[scene_path]:
			_check(source.contains('"action":"dialog:%s"' % String(dialog_id)) or source.contains('"action": "dialog:%s"' % String(dialog_id)), "%s exposes %s" % [scene_path.get_file(), dialog_id])
			var entry_start := source.find("dialog:%s" % String(dialog_id))
			var entry_end := source.find("}", entry_start)
			var entry := source.substr(entry_start, entry_end - entry_start)
			_check(not entry.contains("chapter"), "%s has no chapter gate" % dialog_id)

	for dialog_id: String in ["echo", "bell", "board", "water_rule", "balance", "final_trial"]:
		_check(ResourceLoader.exists("res://data/dialogs/huilan_openworld_%s.tres" % dialog_id), "%s dialogue exists" % dialog_id)
	var world_layout := FileAccess.get_file_as_string("res://data/maps/world_map_jianghu_layout_v10.tres")
	for scene_id: String in ["ch1_s2_qingfeng", "ch2_s4_lingyue_gate", "ch3_s1_wulin_assembly", "ch4_s1_luoyang_yamen"]:
		var target_at := world_layout.find('"target_scene":"%s"' % scene_id)
		_check(target_at >= 0, "%s is reachable from the open world" % scene_id)
		if target_at >= 0:
			var entry_start := world_layout.rfind("{", target_at)
			var entry_end := world_layout.find("}", target_at)
			var portal_entry := world_layout.substr(entry_start, entry_end - entry_start)
			_check(not portal_entry.contains("require_flag"), "%s world portal has no chapter gate" % scene_id)

	await _check_runtime_any_order()
	_check_legacy_migration()
	_finish()


func _check_runtime_any_order() -> void:
	var game_state := root.get_node("GameState")
	var quest_manager := root.get_node("QuestManager")
	game_state.call("reset_for_new_game")
	quest_manager.call("reset_for_new_game")
	game_state.get("player").insight = 20
	var reverse_order: Array[StringName] = CLUES.duplicate()
	reverse_order.reverse()
	game_state.call("set_flag", reverse_order[0], true)
	_check(quest_manager.call("is_active", QUEST_ID), "first clue in any order accepts the quest")
	for index: int in range(1, reverse_order.size()):
		game_state.call("set_flag", reverse_order[index], true)
	_check(bool(game_state.get("flags").get("huilan_openworld_clues_complete", false)), "all five clues unlock the final crisis")
	_check(not quest_manager.call("is_completed", QUEST_ID), "clues alone do not grant the legendary art")
	_check(&"huilan_redirecting_art" not in game_state.get("player").skills, "skill is absent before the final crisis")
	game_state.call("set_flag", &"huilan_openworld_trial_complete", true)
	_check(quest_manager.call("is_completed", QUEST_ID), "final crisis completes the quest")
	_check(&"huilan_redirecting_art" in game_state.get("player").skills, "final crisis grants the legendary art")


func _check_legacy_migration() -> void:
	var game_state := root.get_node("GameState")
	game_state.call("reset_for_new_game")
	game_state.set("flags", {"huilan_watergate_trial_complete": true})
	game_state.call("reconcile_progression_rewards")
	for flag_id: StringName in CLUES:
		_check(bool(game_state.get("flags").get(String(flag_id), false)), "legacy final save restores %s" % flag_id)
	_check(bool(game_state.get("flags").get("huilan_openworld_trial_complete", false)), "legacy final save restores the new final trial")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[HuilanOpenWorld20260908] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[HuilanOpenWorld20260908] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
