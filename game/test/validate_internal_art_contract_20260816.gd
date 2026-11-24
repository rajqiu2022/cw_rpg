extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var skill := load("res://data/skills/linxi_inner_breath.tres") as Skill
	_check(skill != null, "林西吐纳术资源可加载")
	if skill == null:
		_finish()
		return
	_check(skill.quality == Skill.Quality.RARE, "林西吐纳术为蓝色品质")
	_check(skill.is_internal_art, "林西吐纳术声明为心法")
	_check(skill.is_passive, "林西吐纳术为纯被动心法")
	_check(not skill.has_active_effect(), "纯被动心法无战斗主动效果")
	_expect_lines(skill.get_passive_effect_lines(0), ["生命 +16", "内功 +18", "防御 +2"], "初学常驻数值")
	_expect_lines(skill.get_passive_effect_lines(1), ["生命 +24", "内功 +24", "防御 +2"], "提升后常驻数值")

	var game_state: Node = root.get_node("GameState")
	game_state.call("reset_for_new_game")
	var player := game_state.get("player") as CharacterStats
	var hp_before := player.max_hp
	var mp_before := player.max_mp
	var defense_before := player.defense
	_check(bool(game_state.call("learn_skill", &"linxi_inner_breath")), "满足悟性时可习得心法")
	_check(player.max_hp - hp_before == 16, "习得立即增加生命 16")
	_check(player.max_mp - mp_before == 18, "习得立即增加内功 18")
	_check(player.defense - defense_before == 2, "习得立即增加防御 2")
	var learned_hp := player.max_hp
	var learned_mp := player.max_mp
	game_state.set("training_points_total", 1000)
	game_state.set("training_points_available", 1000)
	_check(bool(game_state.call("practice_skill", &"linxi_inner_breath")), "心法可消耗阅历提升")
	_check(player.max_hp - learned_hp == 8, "提升心法继续增加生命")
	_check(player.max_mp - learned_mp == 6, "提升心法继续增加内功")
	var active_art := load("res://data/skills/qinghe_jade_guard.tres") as Skill
	_check(active_art != null and active_art.has_active_effect(), "主动心法声明可在战斗中运功")
	if active_art != null:
		_check(active_art.get_active_effect_value(1) > active_art.get_active_effect_value(0), "提升心法增强主动效果数值")
		_check(active_art.get_active_duration(1) > active_art.get_active_duration(0), "提升心法延长主动效果")

	var panel_source := FileAccess.get_file_as_string("res://scripts/ui/skill_panel.gd")
	_check(panel_source.contains('"提升心法"'), "心法升级按钮使用心法文案")
	_check(panel_source.contains("无主动运功（不会出现在战斗招式中）"), "纯被动心法说明不进入战斗")
	var battle_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	_check(battle_source.contains("skill.is_internal_art and not skill.has_active_effect()"), "战斗招式选择按主动功效过滤纯被动心法")
	var walkable_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check(walkable_source.contains("_quality_color(skill.quality)"), "学习提示按武学品质取色")
	_finish()


func _expect_lines(actual: PackedStringArray, expected: Array[String], label: String) -> void:
	_check(Array(actual) == expected, "%s expected=%s actual=%s" % [label, expected, Array(actual)])


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _finish() -> void:
	print("[InternalArtContract20260816] checks=19 failed=%d" % failures.size())
	for failure in failures:
		push_error("[InternalArtContract20260816] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
