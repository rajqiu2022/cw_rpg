extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var game_state := root.get_node("GameState")
	var inventory := root.get_node("Inventory")
	var quest_manager := root.get_node("QuestManager")
	var investigation := root.get_node("InvestigationState")
	game_state.call("reset_for_new_game")
	inventory.call("reset_for_new_game")
	quest_manager.call("reset_for_new_game")
	investigation.call("reset_for_new_game")
	_check(bool(quest_manager.call("accept", &"q_ch5_main_01_relief_route")), "relief route quest can be accepted")
	game_state.call("set_flag", &"ch5_relief_road_cleared", true)
	await process_frame
	_check(bool(quest_manager.call("is_completed", &"q_ch5_main_01_relief_route")), "relief route quest completes on its victory flag")
	_check(int(inventory.call("count_of", &"battle_helmet")) == 1, "relief route grants exactly one battle helmet")
	_check(bool(quest_manager.call("accept", &"q_ch5_main_02_grain_convoy")), "grain convoy quest can be accepted")
	game_state.call("set_flag", &"ch5_grain_convoy_saved", true)
	await process_frame
	_check(not bool(quest_manager.call("is_completed", &"q_ch5_main_02_grain_convoy")), "saving the convoy alone does not skip evidence inspection")
	_check(bool(investigation.call("acquire_evidence", &"ev_ch5_false_banner_cloth", &"ch5_grain_convoy_camp")), "false-banner evidence can be acquired")
	await process_frame
	_check(bool(quest_manager.call("is_completed", &"q_ch5_main_02_grain_convoy")), "grain convoy quest completes after evidence acquisition")
	_check(int(inventory.call("count_of", &"healing_pill_major")) >= 1 and int(inventory.call("count_of", &"inner_breath_pill")) >= 1, "grain convoy rewards both life and inner-power supplies")
	print("[Chapter5ReliefRewards20260824] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
