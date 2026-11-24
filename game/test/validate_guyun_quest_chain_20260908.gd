extends SceneTree

const QUEST_ID := &"q_legend_wanxiang_breaking_sword"
const ENCOUNTER_FLAGS: Array[StringName] = [
	&"guyun_feng_first_met",
	&"guyun_returning_diagram_solved",
	&"guyun_luoyang_notches_solved",
	&"guyun_mingwu_catalog_preserved",
]
const BASE_ARTS: Array[StringName] = [
	&"linxi_basic_sword_one",
	&"linxi_basic_sword_two",
	&"linxi_inner_breath",
]

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var quest := load("res://data/quests/q_legend_wanxiang_breaking_sword.tres") as QuestDef
	_check(quest != null, "孤云归式 quest loads")
	if quest != null:
		_check(quest.title == "孤云归式", "quest uses the final title")
		_check(quest.starts_in_chapter == 2 and quest.completes_in_chapter == 8, "quest spans chapters two through eight")
		_check(quest.require_all_completion_triggers and quest.completion_triggers.size() == 6, "all six milestones are required")
		_check(quest.reward_skills.is_empty(), "quest does not grant the evolved skill before the master breakthrough")

	_check(not ResourceLoader.exists("res://data/skills/guhong_falling_star_sword.tres"), "天外惊鸿 skill is absent")
	_check(not ResourceLoader.exists("res://data/quests/q_legend_guhong_falling_star_sword.tres"), "天外惊鸿 quest is absent")
	_check(ResourceLoader.exists("res://art/characters/portraits/portrait_feng_yanqiu_v1.png"), "封砚秋 dedicated portrait exists")

	for scene_path: String in [
		"res://data/scenes/ch2_s1_zhuwei_market.tres",
		"res://data/scenes/ch3_s2_trial_ground.tres",
		"res://data/scenes/ch4_s3_luoyang_market.tres",
		"res://data/scenes/ch7_s4_mingwu_manor_outer_court.tres",
		"res://data/scenes/linxi_tutorial.tres",
	]:
		var source := FileAccess.get_file_as_string(scene_path)
		_check(source.contains("封砚秋"), "%s contains Feng Yanqiu encounter" % scene_path.get_file())

	var book_dialog := FileAccess.get_file_as_string("res://data/dialogs/ch8_guyun_master_book.tres")
	var final_dialog := FileAccess.get_file_as_string("res://data/dialogs/ch8_master_ultimate_breakthrough.tres")
	_check(book_dialog.contains("原本不是九招") and book_dialog.contains("第十重"), "ancestral book explains the ninth-to-tenth principle")
	_check(final_dialog.contains("我也只练到第九重"), "Xing Fantian explicitly shares the ninth-level limit")
	_check(final_dialog.contains("原名从来都是孤云九式"), "final dialogue restores the original name")
	var archive_layout := FileAccess.get_file_as_string("res://data/maps/ch6_s3_underground_archive_layout_v1.tres")
	_check(archive_layout.contains('"id":"guyun_master_book"') and archive_layout.contains('"require_flag":"guyun_master_book_unlocked"'), "the ancestral book appears in the underground archive only after recollection")

	await _check_runtime_progression()
	_finish()


func _check_runtime_progression() -> void:
	var game_state := root.get_node("GameState")
	var quest_manager := root.get_node("QuestManager")
	game_state.call("reset_for_new_game")
	quest_manager.call("reset_for_new_game")
	var player: CharacterStats = game_state.get("player")
	player.skills = [&"basic_attack", &"linxi_basic_sword_one", &"linxi_basic_sword_two", &"linxi_inner_breath"]
	game_state.set("skill_mastery", {
		"linxi_basic_sword_one": 8,
		"linxi_basic_sword_two": 8,
		"linxi_inner_breath": 8,
	})
	game_state.call("set_flag", &"chapter8_complete", true)
	_check(not bool(game_state.get("flags").get("linxi_final_breakthrough_available", false)), "chapter completion and ninth-level arts cannot skip the investigation")

	for flag_id: StringName in ENCOUNTER_FLAGS:
		game_state.call("set_flag", flag_id, true)
	_check(quest_manager.call("is_active", QUEST_ID), "the first encounter auto-accepts the long chain")
	_check(bool(game_state.get("flags").get("guyun_recollection_available", false)), "four solved encounters unlock the recollection")
	_check(not bool(game_state.get("flags").get("linxi_final_breakthrough_available", false)), "the final breakthrough remains locked before reading the book")

	game_state.call("set_flag", &"guyun_master_recollection_done", true)
	_check(not quest_manager.call("is_completed", QUEST_ID), "five of six milestones do not complete the quest")
	game_state.call("set_flag", &"guyun_master_book_read", true)
	_check(quest_manager.call("is_completed", QUEST_ID), "reading the book completes the quest")
	_check(bool(game_state.get("flags").get("linxi_final_breakthrough_available", false)), "the book unlocks the master breakthrough")

	game_state.call("set_flag", &"linxi_master_ultimate_breakthrough", true)
	_check(&"wanxiang_breaking_sword" in player.skills, "the final master scene evolves the sword art into 孤云九式")
	for base_id: StringName in BASE_ARTS:
		_check(base_id not in player.skills, "%s is folded into the final inheritance" % base_id)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[GuyunQuestChain20260908] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[GuyunQuestChain20260908] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
