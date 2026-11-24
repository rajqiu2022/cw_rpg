extends SceneTree

const BASE_ARTS: Array[StringName] = [&"linxi_basic_sword_one", &"linxi_basic_sword_two", &"linxi_inner_breath"]
const EVOLVED_ARTS: Array[StringName] = [&"wanxiang_breaking_sword", &"xuanshuang_hidden_current"]

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	for skill_id: StringName in BASE_ARTS:
		var skill := load("res://data/skills/%s.tres" % String(skill_id)) as Skill
		_check(skill != null, "%s loads" % skill_id)
		if skill != null:
			_check(skill.max_level == 10, "%s has ten total levels" % skill_id)
			_check(skill.self_practice_level_cap == 9, "%s self-practice stops at level nine" % skill_id)
			_check(skill.get_self_practice_max_mastery() == 8, "%s level nine maps to mastery eight" % skill_id)
			_check(skill.evolves_to_skill_id in EVOLVED_ARTS, "%s declares its final evolution" % skill_id)
	for skill_id: StringName in EVOLVED_ARTS:
		var skill := load("res://data/skills/%s.tres" % String(skill_id)) as Skill
		_check(skill != null and skill.quality == Skill.Quality.LEGENDARY, "%s is orange legendary quality" % skill_id)

	var sword_quest := load("res://data/quests/q_legend_wanxiang_breaking_sword.tres") as QuestDef
	var return_quest := load("res://data/quests/q_ch6_main_01_return_home.tres") as QuestDef
	_check(sword_quest != null and sword_quest.reward_skills.is_empty(), "the sword clue chain no longer grants 孤云九式 early")
	_check(return_quest != null and return_quest.reward_skills.is_empty(), "chapter six no longer grants 玄霜归藏诀 early")

	var tutorial := load("res://data/scenes/linxi_tutorial.tres") as SceneScript
	var ready_variant := false
	var after_variant := false
	if tutorial != null:
		for npc: Dictionary in tutorial.npcs:
			ready_variant = ready_variant or String(npc.get("dialog_id", "")) == "ch8_master_ultimate_breakthrough"
			after_variant = after_variant or String(npc.get("dialog_id", "")) == "ch8_master_after_breakthrough"
	_check(ready_variant and after_variant, "master owns final-breakthrough and post-breakthrough dialogue states")
	var quest_manager_source := FileAccess.get_file_as_string("res://scripts/autoload/quest_manager.gd")
	_check(quest_manager_source.contains("q_ch8_main_03_final_boss") and quest_manager_source.contains("chapter8_complete"), "chapter eight final boss completion unlocks the master breakthrough")
	_check(not quest_manager_source.contains("chapter7_complete"), "chapter seven cannot unlock the final master breakthrough")

	var game_state := root.get_node("GameState")
	game_state.call("reset_for_new_game")
	var player: CharacterStats = game_state.get("player")
	player.skills = [&"basic_attack", &"linxi_basic_sword_one", &"linxi_basic_sword_two", &"linxi_inner_breath"]
	game_state.set("skill_mastery", {
		"linxi_basic_sword_one": 8,
		"linxi_basic_sword_two": 8,
		"linxi_inner_breath": 8,
	})
	game_state.call("set_flag", &"chapter8_complete", true)
	_check(not bool(game_state.get("flags").get("linxi_final_breakthrough_available", false)), "ninth-level arts and chapter eight are insufficient without the quest chain")
	for clue_flag: StringName in [&"guyun_feng_first_met", &"guyun_returning_diagram_solved", &"guyun_luoyang_notches_solved", &"guyun_mingwu_catalog_preserved"]:
		game_state.call("set_flag", clue_flag, true)
	_check(bool(game_state.get("flags").get("guyun_recollection_available", false)), "four encounters unlock the final master recollection")
	_check(not bool(game_state.get("flags").get("linxi_final_breakthrough_available", false)), "recollection alone does not bypass the missing book")
	game_state.call("set_flag", &"guyun_master_recollection_done", true)
	game_state.call("set_flag", &"guyun_master_book_read", true)
	_check(bool(game_state.get("flags").get("linxi_final_breakthrough_available", false)), "reading the ancestral book unlocks the final master breakthrough")
	game_state.call("set_flag", &"linxi_master_ultimate_breakthrough", true)
	for skill_id: StringName in BASE_ARTS:
		_check(skill_id not in player.skills, "%s is merged away after breakthrough" % skill_id)
	for skill_id: StringName in EVOLVED_ARTS:
		_check(skill_id in player.skills, "%s is learned after breakthrough" % skill_id)
		_check(int(game_state.get("skill_mastery").get(String(skill_id), -1)) == 9, "%s reaches level ten" % skill_id)
	_check(bool(game_state.get("flags").get("linxi_arts_evolved", false)), "final evolution flag is recorded")
	_finish()


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[LinxiFinalBreakthrough20260820] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[LinxiFinalBreakthrough20260820] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
