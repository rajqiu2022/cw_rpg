extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var game_state: Node = root.get_node("GameState")
	var quest_manager: Node = root.get_node("QuestManager")
	game_state.call("reset_for_new_game")
	quest_manager.call("reset_for_new_game")
	_expect(bool(quest_manager.call("accept", &"q_secret_canglong_three_pages")), "hidden manual quest cannot be accepted")

	game_state.call("set_flag", &"canglong_upper_found", true)
	game_state.call("set_flag", &"canglong_middle_found", true)
	_expect(not bool(game_state.call("get_flag", &"canglong_pages_complete", false)), "two manual pages incorrectly unlock assembly")
	_expect(&"canglong_three_turns" not in game_state.get("player").get("skills"), "skill learned before all pages were assembled")

	game_state.call("set_flag", &"canglong_lower_found", true)
	_expect(bool(game_state.call("get_flag", &"canglong_pages_complete", false)), "three manual pages did not unlock assembly")
	_expect(&"canglong_three_turns" not in game_state.get("player").get("skills"), "collecting pages should not auto-learn the skill")

	var dialogue := root.get_node("DialogPlayer")
	var assembly := load("res://data/dialogs/ch4_canglong_assemble.tres") as DialogScript
	dialogue.play(assembly)
	dialogue.advance()
	dialogue.advance()
	_expect(dialogue.get("_current_node").node_id == &"pending", "low insight narration should defer learning")
	_expect(&"canglong_three_turns" in game_state.pending_skill_unlocks, "assembled manual must remain pending")
	var tip_text: String = quest_manager.get("_reward_tip").get("_rewards").get_parsed_text()
	_expect(tip_text.contains("有效悟性达到 9 时领悟"), "receipt should name the unlock condition")
	dialogue.advance()
	_expect(bool(quest_manager.call("is_completed", &"q_secret_canglong_three_pages")), "assembly flag did not complete the hidden quest")

	game_state.player.insight = 9
	root.get_node("EventBus").player_leveled_up.emit(game_state.player.level)
	_expect(&"canglong_three_turns" in game_state.player.skills, "reaching nine insight should teach the pending skill")
	game_state.call("reset_for_new_game")
	game_state.player.insight = 9
	game_state.get("flags")["canglong_manual_assembled"] = true
	game_state.call("reconcile_progression_rewards")
	_expect(&"canglong_three_turns" in game_state.get("player").get("skills"), "old-save reconciliation did not restore the hidden skill")
	_expect(assembly.find_node_by_id(&"outcome").node_id == &"mastered", "learned skill should use the mastery narration")

	game_state.reset_for_new_game()
	quest_manager.reset_for_new_game()
	game_state.player.insight = 9
	quest_manager.accept(&"q_secret_canglong_three_pages")
	for flag in [&"canglong_upper_found", &"canglong_middle_found", &"canglong_lower_found"]:
		game_state.set_flag(flag, true)
	dialogue.play(assembly)
	dialogue.advance()
	dialogue.advance()
	_expect(dialogue.get("_current_node").node_id == &"mastered", "eligible reader should see the mastery narration")
	tip_text = quest_manager.get("_reward_tip").get("_rewards").get_parsed_text()
	_expect(tip_text.contains("习得") and tip_text.contains("藏龙三转") and not tip_text.contains("时领悟"), "eligible reader's receipt should confirm learning")
	dialogue.advance()

	print("[HiddenLegacyRewards] failed=%d" % _failures.size())
	for failure: String in _failures:
		push_error("[HiddenLegacyRewards] %s" % failure)
	quit(1 if not _failures.is_empty() else 0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
