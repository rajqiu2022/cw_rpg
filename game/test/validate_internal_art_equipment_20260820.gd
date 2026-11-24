extends SceneTree

const EXPECTED_NEW_ARTS := {
	&"linxi_guarded_breath": Skill.Quality.COMMON,
	&"herbal_breathing_guide": Skill.Quality.UNCOMMON,
	&"zhuwei_bamboo_guard_art": Skill.Quality.RARE,
	&"luoshui_returning_origin": Skill.Quality.EPIC,
	&"xuanshuang_hidden_current": Skill.Quality.LEGENDARY,
}

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var game_state: Node = root.get_node("GameState")
	game_state.call("reset_for_new_game")
	var player := game_state.get("player") as CharacterStats
	_check(player != null, "主角数据可用")
	if player == null:
		_finish()
		return

	for skill_id: StringName in [&"linxi_inner_breath", &"wudang_xuanwu_xinjing"]:
		if skill_id not in player.skills:
			player.skills.append(skill_id)
	player.insight = 20
	var stats_before := _core_stats(player)
	_check(bool(game_state.call("equip_internal_art", &"linxi_inner_breath")), "可装备已学心法")
	_check(player.equipped_internal_art == &"linxi_inner_breath", "装备槽记录第一门心法")
	_check(_core_stats(player) == stats_before, "装备心法不重复写入永久属性")
	_check(bool(game_state.call("equip_internal_art", &"wudang_xuanwu_xinjing")), "装备第二门心法会替换第一门")
	_check(player.equipped_internal_art == &"wudang_xuanwu_xinjing", "心法装备上限严格为一门")
	_check(not bool(game_state.call("equip_internal_art", &"basic_attack")), "普通攻击不能占用心法槽")
	_check(_core_stats(player) == stats_before, "切换心法不改变永久属性")
	_check(bool(game_state.call("unequip_internal_art")), "可卸下已装备心法")
	_check(player.equipped_internal_art == &"", "卸下后心法槽为空")

	var yijin := load("res://data/skills/jingang_tempered_meridians.tres") as Skill
	_check(yijin != null, "高悟性门槛心法可加载")
	if yijin != null:
		if yijin.skill_id not in player.skills:
			player.skills.append(yijin.skill_id)
		player.insight = yijin.get_required_insight() - 1
		_check(not bool(game_state.call("equip_internal_art", yijin.skill_id)), "悟性不足时数据层拒绝装备心法")
		_check(player.equipped_internal_art == &"", "悟性不足不会写入心法装备槽")
		player.insight = yijin.get_required_insight()
		_check(bool(game_state.call("equip_internal_art", yijin.skill_id)), "悟性达标后可装备心法")
		player.insight = yijin.get_required_insight() - 1
		game_state.call("reconcile_equipped_internal_arts")
		_check(player.equipped_internal_art == &"", "悟性降低后清理不再满足条件的心法")
		var panel_scene := load("res://scenes/ui/skill_panel.tscn") as PackedScene
		var panel := panel_scene.instantiate() if panel_scene != null else null
		_check(panel != null, "武学界面可实例化")
		if panel != null:
			root.add_child(panel)
			await process_frame
			panel.set("_runtime_group", "mind")
			panel.set("_runtime_route", "general")
			panel.set("_runtime_selected_id", yijin.skill_id)
			panel.call("_refresh_runtime_v2")
			var detail := panel.get("_runtime_detail") as RichTextLabel
			var requirement := panel.get("_runtime_cost_label") as RichTextLabel
			var equip_button := panel.get("_runtime_equip_btn") as Button
			var upgrade_button := panel.get("_runtime_upgrade_btn") as Button
			_check(detail != null and detail.clip_contents and detail.position.y + detail.size.y <= 755.0, "心法详情严格收在上方详情框内")
			_check(requirement != null and requirement.text.contains("[color=#e6a14f]条件不足") and not requirement.text.contains("[b]"), "悟性不足以橙色常规字重显示")
			_check(equip_button != null and equip_button.disabled, "悟性不足时装备按钮禁用")
			var disabled_style := upgrade_button.get_theme_stylebox("disabled") as StyleBoxTexture if upgrade_button != null else null
			_check(disabled_style != null and disabled_style.texture != null, "提升心法禁用态仍显示正式按钮底图")
			panel.queue_free()
			await process_frame

	var xuanwu := load("res://data/skills/wudang_xuanwu_xinjing.tres") as Skill
	var taiji := load("res://data/skills/wudang_taiji_liangyi.tres") as Skill
	var ordinary := load("res://data/skills/basic_attack.tres") as Skill
	_check(xuanwu != null and taiji != null and ordinary != null, "玄武心经、太极剑法和普通攻击可加载")
	if xuanwu != null and taiji != null and ordinary != null:
		var taiji_bonus := xuanwu.get_equipped_bonus_for(taiji, 1)
		var basic_bonus := xuanwu.get_equipped_bonus_for(ordinary, 1)
		_check(int(taiji_bonus.get("scaling", 0)) > 0, "玄武心经增强太极剑法伤害")
		_check(float(taiji_bonus.get("crit_chance", 0.0)) > 0.0, "玄武心经增强太极剑法暴击")
		_check(int(taiji_bonus.get("internal_injury", 0)) > 0, "玄武心经增强太极剑法内伤")
		_check(int(basic_bonus.get("scaling", 0)) == 0, "普通攻击不吃心法武器招式加成")

	var internal_count := 0
	for filename in DirAccess.get_files_at("res://data/skills"):
		if not filename.ends_with(".tres"):
			continue
		var skill := load("res://data/skills/%s" % filename) as Skill
		if skill == null or not skill.is_internal_art:
			continue
		internal_count += 1
		_check(not skill.equip_weapon_categories.is_empty(), "%s 拥有心法装备流派效果" % skill.display_name)
		_check(not skill.get_equipped_effect_lines(0).is_empty(), "%s 的装备效果可供界面展示" % skill.display_name)
	_check(internal_count >= 20, "心法内容不少于二十门")

	for raw_id: Variant in EXPECTED_NEW_ARTS:
		var skill_id := StringName(raw_id)
		var art := load("res://data/skills/%s.tres" % String(skill_id)) as Skill
		_check(art != null and art.quality == EXPECTED_NEW_ARTS[skill_id], "%s 品质与章节梯度一致" % skill_id)
	var save_source := FileAccess.get_file_as_string("res://scripts/autoload/save_manager.gd")
	_check(save_source.contains("const SAVE_VERSION := 13"), "当前存档版本保持为 v13")
	_check(save_source.contains('"equipped_internal_art"'), "存档包含已装备心法")
	_finish()


func _core_stats(stats: CharacterStats) -> Array[int]:
	return [stats.strength, stats.agility, stats.inner_power, stats.insight, stats.vitality, stats.inner_pool, stats.guard, stats.max_hp, stats.max_mp]


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)


func _finish() -> void:
	print("[InternalArtEquipment20260820] checks=%d failed=%d" % [checks, failures.size()])
	for failure in failures:
		push_error("[InternalArtEquipment20260820] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
