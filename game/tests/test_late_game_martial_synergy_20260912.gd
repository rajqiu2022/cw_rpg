extends SceneTree

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var game_state := root.get_node("GameState")
	var inventory := root.get_node("Inventory")
	game_state.reset_for_new_game()
	inventory.reset_for_new_game()

	var linxi := load("res://data/skills/linxi_basic_sword_one.tres") as Skill
	var taiji := load("res://data/skills/wudang_taiji_sword.tres") as Skill
	var xuanwu := load("res://data/skills/wudang_xuanwu_xinjing.tres") as Skill
	_check(linxi != null and taiji != null and xuanwu != null, "核心对比资源可加载")
	if linxi == null or taiji == null or xuanwu == null:
		_finish()
		return

	# 开局同一属性下，绝学本体也必须明显强于入门式；不能把全部价值藏在后期属性里。
	var starter_attack := 24
	var linxi_raw := linxi.fixed_damage + int(round(float(starter_attack) * linxi.get_attack_scaling() / 100.0))
	var taiji_raw := taiji.fixed_damage + int(round(float(starter_attack) * taiji.get_attack_scaling() / 100.0))
	_check(linxi_raw == 34, "林西一式开局基准仍为34点未减防伤害")
	_check(taiji_raw >= 110, "太极剑法开局基准至少110点未减防伤害")
	_check(taiji_raw - linxi_raw >= 70 and float(taiji_raw) / linxi_raw >= 3.0, "橙色绝学本体形成清晰跨阶差")
	_check(taiji.mp_cost >= linxi.mp_cost * 5, "绝学高伤害仍由显著内力成本约束")

	var taiji_bonus := xuanwu.get_equipped_bonus_for(taiji, 0)
	_check(int(taiji_bonus.get("scaling", 0)) >= 22, "玄武心经同时提供流派与指定招式系数")
	_check(int(taiji_bonus.get("defense_pierce", 0)) == 15, "玄武心经为太极招式追加15%破防")
	_check(int(taiji_bonus.get("self_hp_restore", 0)) == 12 and int(taiji_bonus.get("self_mp_restore", 0)) == 6, "玄武心经提供有感气血与内力续航")
	_check(int(taiji_bonus.get("internal_injury", 0)) >= 16, "玄武心经强化太极招式内伤积累")
	var paired_scaling := taiji.get_attack_scaling() + taiji.get_complement_scaling_bonus() + int(taiji_bonus.get("scaling", 0))
	var paired_raw := taiji.fixed_damage + int(round(float(starter_attack) * paired_scaling / 100.0))
	_check(paired_raw > taiji_raw, "配套心法继续拉开绝学上限")

	var signature_pairs := {
		"gufeng_jingang_li": "gufeng_liedi",
		"huashan_zixia_shengong": "huashan_jianduan_qianshan",
		"lingyue_yuehua_yin": "lingyue_hanshuang_wan_zhen",
		"mingwu_yinying_jue": "mingwu_yinying_duoming",
		"wudang_xuanwu_xinjing": "wudang_taiji_sword",
		"xuanshuang_hidden_current": "wanxiang_breaking_sword",
	}
	for art_id: String in signature_pairs:
		var art := load("res://data/skills/%s.tres" % art_id) as Skill
		var technique := load("res://data/skills/%s.tres" % signature_pairs[art_id]) as Skill
		_check(art != null and technique != null, "%s 配套资源可加载" % art_id)
		if art == null or technique == null:
			continue
		var bonus := art.get_equipped_bonus_for(technique, 0)
		var has_special := (
			int(bonus.get("self_hp_restore", 0)) > 0
			or int(bonus.get("self_mp_restore", 0)) > 0
			or StringName(bonus.get("target_status", &"")) != &""
			or float(bonus.get("execute_damage_bonus", 0.0)) > 0.0
			or float(bonus.get("crit_multiplier", 0.0)) > 0.0
		)
		_check(int(bonus.get("scaling", 0)) > 0 and has_special, "%s 不仅加伤害系数且拥有独特协同" % art.display_name)

	# 直接验证现行编队战斗的协同状态与回复，不只检查静态资源字段。
	var controller: Node = load("res://scripts/battle/battle_controller.gd").new()
	var quiet_log := RichTextLabel.new()
	controller.set("battle_log", quiet_log)
	var player := game_state.player as CharacterStats
	player.insight = 20
	if xuanwu.skill_id not in player.skills:
		player.skills.append(xuanwu.skill_id)
	_check(game_state.equip_internal_art(xuanwu.skill_id), "玄武心经可进入当前心法槽")
	var source := BattleCombatant.new()
	source.configure_from_stats(&"player", BattleCombatant.Team.ALLY, player)
	player.hp = maxi(1, player.max_hp - 30)
	player.mp = maxi(0, player.max_mp - 30)
	var hp_before := player.hp
	var mp_before := player.mp
	controller.call("_team_apply_internal_art_self_effect", source, taiji)
	_check(player.hp - hp_before == 12 and player.mp - mp_before == 6, "编队战斗实际结算玄武心经回血回内")
	var formula_target_stats := CharacterStats.new()
	formula_target_stats.display_name = "公式木桩"
	formula_target_stats.defense = 100
	formula_target_stats.max_hp = 1000
	formula_target_stats.hp = 1000
	var formula_target := BattleCombatant.new()
	formula_target.configure_from_stats(&"formula_dummy", BattleCombatant.Team.ENEMY, formula_target_stats)
	seed(20260912)
	controller.call("_calc_team_player_skill_damage", taiji, source, formula_target)
	var paired_breakdown := controller.get("last_damage_breakdown") as DamageBreakdown
	_check(paired_breakdown != null and paired_breakdown.attack_scaling == 192, "编队实际伤害入口叠加太极本体、互补和玄武心经系数")
	_check(paired_breakdown != null and paired_breakdown.effective_defense == 55, "编队实际伤害入口按45%总破防结算")

	var gufeng := load("res://data/skills/gufeng_jingang_li.tres") as Skill
	var liedi := load("res://data/skills/gufeng_liedi.tres") as Skill
	player.skills.append(gufeng.skill_id)
	game_state.equip_internal_art(gufeng.skill_id)
	var enemy_stats := CharacterStats.new()
	enemy_stats.display_name = "协同木桩"
	var target := BattleCombatant.new()
	target.configure_from_stats(&"synergy_dummy", BattleCombatant.Team.ENEMY, enemy_stats)
	controller.call("_team_apply_internal_art_target_effect", source, target, liedi)
	_check(int(target.status_effects.get("armor_break", 0)) == 2 and int(target.status_effects.get("armor_break_percent", 0)) == 25, "编队战斗实际施加金刚力25%破防")

	var yinying := load("res://data/skills/mingwu_yinying_jue.tres") as Skill
	var duoming := load("res://data/skills/mingwu_yinying_duoming.tres") as Skill
	player.skills.append(yinying.skill_id)
	game_state.equip_internal_art(yinying.skill_id)
	formula_target_stats.hp = 400
	seed(20260912)
	controller.call("_calc_team_player_skill_damage", duoming, source, formula_target)
	var execute_breakdown := controller.get("last_damage_breakdown") as DamageBreakdown
	_check(execute_breakdown != null and is_equal_approx(execute_breakdown.outgoing_bonus_total, 0.25), "编队实际伤害入口触发隐影诀半血追击25%")
	controller.free()
	quiet_log.free()

	_finish()


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)


func _finish() -> void:
	print("[LateGameMartialSynergy20260912] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[LateGameMartialSynergy20260912] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
