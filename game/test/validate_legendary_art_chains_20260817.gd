extends SceneTree

const CHAIN_IDS: Array[StringName] = [
	&"q_legend_wanxiang_breaking_sword",
	&"q_legend_canghai_zhenyue_palms",
	&"q_legend_jingang_tempered_meridians",
	&"q_legend_huilan_redirecting_art",
]
const REWARD_IDS: Array[StringName] = [
	&"wanxiang_breaking_sword",
	&"canghai_zhenyue_palms",
	&"jingang_tempered_meridians",
	&"huilan_redirecting_art",
]
const FORBIDDEN_RUNTIME_NAMES := ["独孤九剑", "降龙十八掌", "天外飞仙", "移花接木"]

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	for index in range(CHAIN_IDS.size()):
		var quest := load("res://data/quests/%s.tres" % String(CHAIN_IDS[index])) as QuestDef
		var skill := load("res://data/skills/%s.tres" % String(REWARD_IDS[index])) as Skill
		_check(quest != null, "%s quest loads" % CHAIN_IDS[index])
		_check(skill != null, "%s skill loads" % REWARD_IDS[index])
		if quest == null or skill == null:
			continue
		_check(quest.require_all_completion_triggers, "%s requires every milestone" % quest.quest_id)
		_check(quest.completion_triggers.size() >= 4, "%s spans at least four milestones" % quest.quest_id)
		_check(quest.milestone_labels.size() == quest.completion_triggers.size(), "%s labels every milestone" % quest.quest_id)
		_check(quest.starts_in_chapter <= 3, "%s is foreshadowed by chapter three" % quest.quest_id)
		if quest.quest_id == &"q_legend_wanxiang_breaking_sword":
			_check(quest.starts_in_chapter == 2 and quest.completes_in_chapter == 8, "孤云九式线从第二章延续到第八章")
			_check(quest.completion_triggers.size() == 6, "孤云九式线包含四次相遇、师徒追忆与地下读书")
			_check(quest.reward_skills.is_empty(), "孤云九式长链只找回完整剑解，最终技能留给师门十重突破")
		else:
			if quest.quest_id == &"q_legend_huilan_redirecting_art":
				_check(quest.chapter_independent, "移花换劲 is an open-world chapter-independent chain")
				_check(quest.completion_triggers.size() == 6, "移花换劲 requires five principles and one final trial")
			else:
				_check(quest.completes_in_chapter in [5, 6], "%s unlocks before the final act" % quest.quest_id)
				_check(quest.completes_in_chapter < 7, "%s leaves at least chapters seven and eight for use" % quest.quest_id)
			_check(quest.reward_skills == [skill.skill_id], "%s rewards its matching skill" % quest.quest_id)
		_check(skill.quality == Skill.Quality.LEGENDARY, "%s is legendary quality" % skill.skill_id)
		_check(skill.animation_id == skill.skill_id, "%s owns a dedicated VFX id" % skill.skill_id)
		_check(BattleVfxPlayer.has_effect(skill.animation_id), "%s VFX is registered" % skill.skill_id)
		for forbidden_name in FORBIDDEN_RUNTIME_NAMES:
			_check(not skill.display_name.contains(forbidden_name), "%s does not reuse protected display name" % skill.skill_id)

	var passive_art := load("res://data/skills/jingang_tempered_meridians.tres") as Skill
	_check(passive_art != null and passive_art.is_internal_art and passive_art.is_passive, "易筋经 is a passive internal art")
	if passive_art != null:
		_check(Array(passive_art.get_passive_effect_lines(0)) == ["生命 +32", "内功 +24", "防御 +4"], "易筋经 shows explicit base bonuses")

	var redirect_art := load("res://data/skills/huilan_redirecting_art.tres") as Skill
	_check(redirect_art != null and redirect_art.active_effect_type == &"redirect", "移花换劲 owns redirect semantics")
	if redirect_art != null:
		_check(redirect_art.get_active_effect_value(0) == 30, "移花换劲 starts at 30 percent")
		_check(redirect_art.get_active_effect_value(3) == 60, "移花换劲 grows to 60 percent")

	var breaking_sword := load("res://data/skills/wanxiang_breaking_sword.tres") as Skill
	_check(breaking_sword != null and breaking_sword.defense_pierce_percent == 45, "孤云九式 pierces 45 percent defense")
	_check(not ResourceLoader.exists("res://data/skills/guhong_falling_star_sword.tres"), "天外惊鸿 is not shipped as an active skill")
	_check(not ResourceLoader.exists("res://data/quests/q_legend_guhong_falling_star_sword.tres"), "天外惊鸿 quest chain is removed")
	var group_palms := load("res://data/skills/canghai_zhenyue_palms.tres") as Skill
	_check(group_palms != null and group_palms.target == Skill.Target.ENEMY_ALL, "盘龙十七式 targets all enemies")
	var battle_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	_check(battle_source.contains("skill.defense_pierce_percent"), "battle applies skill defense penetration")
	_check(battle_source.contains('"canghai_zhenyue_palms"'), "battle applies the palm weakness effect")
	_check(battle_source.contains('"redirect_percent"'), "battle applies and consumes redirect percentage")

	await _check_runtime_chain()
	_finish()


func _check_runtime_chain() -> void:
	var game_state := root.get_node("GameState")
	var quest_manager := root.get_node("QuestManager")
	game_state.call("reset_for_new_game")
	quest_manager.call("reset_for_new_game")
	game_state.get("player").insight = 20
	var quest_id := &"q_legend_huilan_redirecting_art"
	var clue_flags: Array[StringName] = [
		&"huilan_water_rule_understood",
		&"huilan_echo_understood",
		&"huilan_balance_understood",
		&"huilan_bell_counterforce_understood",
		&"huilan_yielding_position_understood",
	]
	game_state.call("set_flag", clue_flags[0], true)
	_check(quest_manager.call("is_active", quest_id), "discovering any clue auto-accepts the open-world chain")
	for index: int in range(1, clue_flags.size()):
		game_state.call("set_flag", clue_flags[index], true)
	_check(bool(game_state.get("flags").get("huilan_openworld_clues_complete", false)), "five principles unlock the final trial regardless of order")
	_check(not quest_manager.call("is_completed", quest_id), "five principles do not grant the skill before the final trial")
	game_state.call("set_flag", &"huilan_openworld_trial_complete", true)
	_check(quest_manager.call("is_completed", quest_id), "final trial completes the chain")
	_check(&"huilan_redirecting_art" in game_state.get("player").skills, "chain completion teaches the legendary art")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[LegendaryArtChains20260817] checks=%d failed=%d" % [checks, failures.size()])
	for failure in failures:
		push_error("[LegendaryArtChains20260817] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
