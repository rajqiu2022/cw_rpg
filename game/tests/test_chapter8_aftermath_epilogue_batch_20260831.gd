extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_8_content_plan.tres") as ChapterContentPlan
	var quest := load("res://data/quests/q_ch8_main_13_aftermath_returns.tres") as QuestDef
	_check(plan.main_scene_ids.size() == 7 and plan.main_quest_ids.size() == 13 and plan.story_battle_groups.size() == 5, "chapter eight closes with seven scenes, thirteen main quests and five battle anchors")
	_check(quest.require_all_completion_triggers and quest.completion_triggers.size() == 5, "aftermath requires three cities, relationship and Linxi return")
	var luoyang := load("res://data/scenes/ch4_s1_luoyang_yamen.tres") as SceneScript
	var lieyun := load("res://data/scenes/ch7_s5_lieyun_assembly_hall.tres") as SceneScript
	var zhuwei := load("res://data/scenes/ch2_s1_zhuwei_market.tres") as SceneScript
	_check(luoyang.npcs.any(func(n: Dictionary): return String(n.get("dialog_id", "")) == "ch8_aftermath_luoyang" and String(n.get("require_quest_active", "")) == "q_ch8_main_13_aftermath_returns"), "Luoyang owns a gated final-trial visit")
	_check(_scene_has_dialog_variant(lieyun, "ch8_aftermath_lieyun"), "Lieyun assembly hall owns a gated reform visit")
	_check(_scene_has_dialog_variant(zhuwei, "ch8_aftermath_zhuwei"), "Zhuwei market owns a gated civilian visit")
	for id in ["ch8_aftermath_luoyang", "ch8_aftermath_lieyun", "ch8_aftermath_zhuwei"]:
		var dialog := load("res://data/dialogs/%s.tres" % id) as DialogScript
		var end := dialog.find_node_by_id(&"end")
		_check(end.on_end == "resolve_ch8_relationship_if_ready" and end.set_flags.size() >= 1, "city visit can resolve relationship only after writing its own result: %s" % id)
	var investigation := root.get_node("InvestigationState")
	var game_state := root.get_node("GameState")
	investigation.reset_for_new_game()
	game_state.flags.clear()
	_check(investigation.resolve_relationship_epilogue() == &"independent", "low or tied history resolves to independence")
	investigation.adjust_companion_trust(&"yuewuheng", 12)
	_check(investigation.resolve_relationship_epilogue() == &"yuewuheng", "earned Yue Wuheng trust resolves her candidate")
	investigation.reset_for_new_game()
	investigation.adjust_companion_trust(&"zhao_siying", 12)
	_check(investigation.resolve_relationship_epilogue() == &"zhao_siying", "earned Zhao Siying trust resolves her candidate")
	investigation.reset_for_new_game()
	game_state.set_flag(&"ch6_qiyun_letter_read", true)
	game_state.set_flag(&"ch7_qi_yunsheng_met", true)
	game_state.set_flag(&"ch7_qi_reform_testimony_heard", true)
	_check(investigation.resolve_relationship_epilogue() == &"qi_yunsheng", "Qi Yunsheng legacy story beats score old saves fairly")
	for id in ["yuewuheng", "zhao_siying", "qi_yunsheng"]:
		var dialog := load("res://data/dialogs/ch8_relationship_%s.tres" % id) as DialogScript
		var choice := dialog.find_node_by_id(&"choice")
		_check(choice.choices.size() == 2, "earned relationship offers only that bond or independence: %s" % id)
		for node_id in [&"together", &"independent"]:
			var node := dialog.find_node_by_id(node_id)
			_check(node.set_flags.any(func(entry: Dictionary): return String(entry.get("key", "")) == "ch8_relationship_epilogue_done") and node.set_flags.any(func(entry: Dictionary): return String(entry.get("key", "")) == "ch8_linxi_final_return_open"), "relationship outcome opens Linxi without overwriting history: %s/%s" % [id, node_id])
	var linxi := load("res://data/scenes/linxi_tutorial.tres") as SceneScript
	_check(linxi.npcs.any(func(n: Dictionary): return String(n.get("npc_id", "")) == "xingfantian_epilogue" and String(n.get("require_quest_active", "")) == "q_ch8_main_13_aftermath_returns"), "Linxi courtyard owns the final master debrief")
	var final_dialog := load("res://data/dialogs/ch8_linxi_final_return.tres") as DialogScript
	var final_end := final_dialog.find_node_by_id(&"end")
	_check(final_end.complete_quest == &"q_ch8_main_13_aftermath_returns" and final_end.on_end == "chapter_end:8", "Linxi debrief is the only chapter-eight settlement action")
	var chapter_end_script := FileAccess.get_file_as_string("res://scripts/ui/chapter_end.gd")
	_check("8: \"第八章 · 雾散之后\"" in chapter_end_script, "chapter-end UI owns the formal chapter-eight title")
	var quest_manager := root.get_node("QuestManager")
	quest_manager.reset_for_new_game()
	game_state.flags.clear()
	quest_manager.accept(&"q_ch8_main_13_aftermath_returns")
	for flag_key: StringName in [&"ch8_aftermath_luoyang_done", &"ch8_aftermath_lieyun_done", &"ch8_aftermath_zhuwei_done", &"ch8_relationship_epilogue_done"]:
		game_state.set_flag(flag_key, true)
	_check(quest_manager.is_active(&"q_ch8_main_13_aftermath_returns"), "four of five aftermath milestones do not complete the chapter")
	game_state.set_flag(&"ch8_linxi_final_return_done", true)
	_check(quest_manager.is_completed(&"q_ch8_main_13_aftermath_returns") and bool(game_state.flags.get("chapter8_complete", false)), "fifth milestone completes chapter eight and unlocks final mastery checks")
	print("[Chapter8AftermathEpilogue20260831] failures=%d" % failures)
	quit(1 if failures else 0)


func _scene_has_dialog_variant(scene: SceneScript, dialog_id: String) -> bool:
	for npc: Dictionary in scene.npcs:
		for variant: Dictionary in npc.get("dialog_variants", []):
			if String(variant.get("dialog_id", "")) == dialog_id and String(variant.get("require_quest_active", "")) == "q_ch8_main_13_aftermath_returns":
				return true
	return false


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
