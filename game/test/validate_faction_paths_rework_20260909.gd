extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var game_state: Node = root.get_node("GameState")
	var quest_manager: Node = root.get_node("QuestManager")

	# 无门派是可持久化、互斥的正式道路，不会偷发任何门派武学。
	game_state.call("reset_for_new_game")
	quest_manager.call("reset_for_new_game")
	var before: int = game_state.get("player").skills.size()
	_expect(bool(game_state.call("select_faction", &"wanderer")), "no-faction road cannot be selected")
	_expect(game_state.get("player_faction") == &"wanderer", "no-faction road is not persisted")
	_expect(bool(game_state.get("flags").get("joined_wanderer", false)), "no-faction joined flag is missing")
	_expect(game_state.get("player").skills.size() == before, "no-faction road incorrectly grants faction skills")
	_expect(not bool(game_state.call("select_faction", &"huashan")), "no-faction road can be overwritten by a faction")
	# 无门派不受武学类型或门派字段锁定，实际代价是收集兵器并分别投入历练。
	game_state.call("learn_skill", &"huashan_lanhui_sandie")
	game_state.call("learn_skill", &"snow_pass_returning_blade")
	game_state.call("learn_skill", &"examiner_staff_sweep")
	game_state.call("learn_skill", &"circling_breath_palm")
	game_state.call("learn_skill", &"bamboo_rain_piercing_shot")
	for skill_id: StringName in [&"huashan_lanhui_sandie", &"snow_pass_returning_blade", &"examiner_staff_sweep", &"circling_breath_palm", &"bamboo_rain_piercing_shot"]:
		_expect(_owned_or_pending(game_state, skill_id), "no-faction route is blocked from learning %s" % skill_id)
	var open_world_sources := {
		&"huashan_lanhui_sandie": &"q_ch5_side_05_mountain_stream",
		&"snow_pass_returning_blade": &"q_ch5_main_03_snow_pass",
		&"examiner_staff_sweep": &"q_ch1_side_09_martial_hall",
		&"circling_breath_palm": &"q_ch2_side_05_martial_tournament",
		&"bamboo_rain_piercing_shot": &"q_ch2_main_02_rescue_yue",
	}
	for skill_id: StringName in open_world_sources:
		var quest := load("res://data/quests/%s.tres" % String(open_world_sources[skill_id])) as QuestDef
		_expect(quest != null and skill_id in quest.reward_skills, "world mentor/encounter source is missing for %s" % skill_id)

	# 武当剑、掌可以兼修；额外成本由每门武学独立的历练修炼承担。
	game_state.call("reset_for_new_game")
	quest_manager.call("reset_for_new_game")
	_expect(bool(game_state.call("select_faction", &"wudang")), "Wudang cannot be selected")
	_expect(&"wudang_xuanwu_ge" in game_state.get("player").skills, "Wudang foundation is not granted")
	var entry_quest := load("res://data/quests/q_ch3_wudang_investigate.tres") as QuestDef
	_expect(entry_quest != null and &"wudang_raozhirou_sword" in entry_quest.reward_skills, "Wudang trial does not grant the entry sword line")
	_expect(entry_quest != null and &"wudang_mianzhang" in entry_quest.reward_skills, "Wudang trial does not grant the entry palm line")
	_expect(bool(quest_manager.call("accept", &"q_ch6_main_02_confront_master")), "chapter-6 Wudang reward quest cannot be accepted")
	game_state.call("set_flag", &"confronted_fanxuan", true)
	await process_frame
	_expect(_owned_or_pending(game_state, &"wudang_rouyun_sword"), "Wudang advanced sword line is missing")
	_expect(_owned_or_pending(game_state, &"wudang_taiji_sixiang"), "Wudang advanced palm line is missing")
	_expect(_owned_or_pending(game_state, &"wudang_xuanwu_xinjing"), "Wudang advanced internal art is missing")

	var wudang_sword := load("res://data/skills/wudang_raozhirou_sword.tres") as Skill
	var wudang_fist := load("res://data/skills/wudang_mianzhang.tres") as Skill
	var lingyue_staff := load("res://data/skills/lingyue_lingbo_yizhi.tres") as Skill
	_expect(wudang_sword != null and wudang_sword.required_weapon_type == &"sword" and wudang_sword.target == Skill.Target.ENEMY_SINGLE, "Wudang sword line is not single-target sword")
	_expect(wudang_fist != null and wudang_fist.required_weapon_type == &"palm" and wudang_fist.target == Skill.Target.ENEMY_SINGLE, "Wudang palm line is not single-target palm")
	_expect(wudang_sword.get_practice_cost(0, 4) > 0 and wudang_fist.get_practice_cost(0, 4) > 0, "dual study does not charge independent training costs")
	_expect(lingyue_staff != null and lingyue_staff.required_weapon_type == &"staff" and lingyue_staff.get_martial_category() == &"staff", "Lingyue primary family is not staff")

	var huashan_single := load("res://data/skills/huashan_lanhui_sandie.tres") as Skill
	var huashan_group := load("res://data/skills/huashan_qunfeng_luozhao.tres") as Skill
	_expect(huashan_single != null and huashan_single.target == Skill.Target.ENEMY_SINGLE and huashan_single.school == "huashan", "Huashan lacks its extra single-target sword choice")
	_expect(huashan_group != null and huashan_group.target == Skill.Target.ENEMY_ALL and huashan_group.school == "huashan", "Huashan lacks a group sword choice")
	var hidden_master_quest := load("res://data/quests/q_ch5_side_05_mountain_stream.tres") as QuestDef
	_expect(hidden_master_quest != null and &"huashan_lanhui_sandie" in hidden_master_quest.reward_skills, "hidden master encounter does not teach an unrestricted sword art")

	var huilan := load("res://data/skills/huilan_redirecting_art.tres") as Skill
	var huilan_quest := load("res://data/quests/q_legend_huilan_redirecting_art.tres") as QuestDef
	_expect(huilan != null and huilan.school == "generic" and huilan.quality == Skill.Quality.LEGENDARY, "Huilan is not a generic legendary internal art")
	_expect(huilan_quest != null and huilan_quest.chapter_independent, "Huilan quest is not chapter-independent")

	print("[FactionPathsRework20260909] failed=%d" % _failures.size())
	for failure: String in _failures:
		push_error("[FactionPathsRework20260909] %s" % failure)
	quit(1 if not _failures.is_empty() else 0)


func _owned_or_pending(game_state: Node, skill_id: StringName) -> bool:
	return skill_id in game_state.get("player").skills or skill_id in game_state.get("pending_skill_unlocks")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
