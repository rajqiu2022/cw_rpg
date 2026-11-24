class_name CombatBalanceSimulator
extends RefCounted

## Deterministic balance model built on the same BattleFormula stages used by
## runtime combat. It is intentionally strategy-light: statuses, healing and
## item usage remain playtest concerns rather than hidden spreadsheet guesses.

const DEFAULT_CRIT_MULTIPLIER := 1.5
const MAX_SIMULATION_ROUNDS := 60

const ENCOUNTER_SPECS: Array[Dictionary] = [
	{"chapter": 1, "enemy_id": "thug_lone", "player_level": 1, "role": "教学", "target_min": 3, "target_max": 4},
	{"chapter": 1, "enemy_id": "bandit_mountain", "player_level": 1, "role": "普通", "target_min": 4, "target_max": 6},
	{"chapter": 1, "enemy_id": "linxi_wild_beast", "player_level": 2, "role": "普通", "target_min": 4, "target_max": 6},
	{"chapter": 1, "enemy_id": "zhuwei_cave_wolf", "player_level": 2, "role": "精英", "target_min": 4, "target_max": 6},
	{"chapter": 1, "enemy_id": "zhuwei_bandit", "player_level": 2, "role": "守门", "target_min": 4, "target_max": 6},
	{"chapter": 1, "enemy_id": "boss_zhao_wuji", "player_level": 3, "role": "章末Boss", "target_min": 6, "target_max": 9},
	{"chapter": 2, "enemy_id": "ch2_tournament_guard", "player_level": 3, "role": "精英", "target_min": 5, "target_max": 7},
	{"chapter": 3, "enemy_id": "linxi_dojo_disciple", "player_level": 3, "role": "教学切磋", "target_min": 2, "target_max": 6},
	{"chapter": 3, "enemy_id": "linxi_dojo_senior", "player_level": 3, "role": "切磋", "target_min": 2, "target_max": 6},
	{"chapter": 3, "enemy_id": "gufeng_trainee", "player_level": 4, "role": "切磋", "target_min": 4, "target_max": 6},
	{"chapter": 3, "enemy_id": "wulin_examiner", "player_level": 4, "role": "精英", "target_min": 5, "target_max": 7},
	{"chapter": 3, "enemy_id": "lingyue_guard", "player_level": 4, "role": "守门", "target_min": 4, "target_max": 6},
	{"chapter": 3, "enemy_id": "mingwu_shadow", "player_level": 4, "role": "普通", "target_min": 4, "target_max": 6},
	{"chapter": 3, "enemy_id": "mingwu_spy", "player_level": 4, "role": "普通", "target_min": 4, "target_max": 6},
	{"chapter": 3, "enemy_id": "mingwu_infiltrator", "player_level": 4, "role": "精英", "target_min": 5, "target_max": 7},
	{"chapter": 3, "enemy_id": "wudang_disciple", "player_level": 4, "role": "切磋", "target_min": 4, "target_max": 6},
	{"chapter": 4, "enemy_id": "luoyang_thug", "player_level": 5, "role": "普通", "target_min": 4, "target_max": 6},
	{"chapter": 4, "enemy_id": "fake_liuyun_assassin", "player_level": 5, "role": "精英", "target_min": 5, "target_max": 9},
	{"chapter": 4, "enemy_id": "temple_ambusher", "player_level": 5, "role": "精英", "target_min": 5, "target_max": 7},
	{"chapter": 5, "enemy_id": "ch5_relief_road_raider", "player_level": 7, "role": "普通拦截·双人编队", "target_min": 3, "target_max": 4},
	{"chapter": 5, "enemy_id": "ch5_false_liuyun_striker", "player_level": 7, "role": "护粮精英·三人编队", "target_min": 3, "target_max": 5},
	{"chapter": 5, "enemy_id": "ch5_snow_pass_pursuer", "player_level": 8, "role": "雪岭精英·双人编队", "target_min": 3, "target_max": 5},
	{"chapter": 5, "enemy_id": "ch5_mine_tunnel_hunter", "player_level": 8, "role": "矿道追猎·双人编队", "target_min": 4, "target_max": 6},
	{"chapter": 5, "enemy_id": "ch5_false_banner_captain", "player_level": 9, "role": "章末Boss·三人编队", "target_min": 6, "target_max": 8},
	{"chapter": 6, "enemy_id": "ch6_archive_reclaimer", "player_level": 10, "role": "档案室精英·双人编队", "target_min": 4, "target_max": 7},
	{"chapter": 6, "enemy_id": "ch6_archive_burner", "player_level": 10, "role": "档案室支援·双人编队", "target_min": 4, "target_max": 7},
	{"chapter": 6, "enemy_id": "ch6_convoy_pursuer", "player_level": 10, "role": "白水驿追兵·双人编队", "target_min": 4, "target_max": 7},
	{"chapter": 6, "enemy_id": "ch6_convoy_tracker", "player_level": 10, "role": "白水驿寻迹者·双人编队", "target_min": 4, "target_max": 7},
	{"chapter": 7, "enemy_id": "ch7_lieyun_hardliner_guard", "player_level": 11, "role": "烈云强硬派·双人编队", "target_min": 5, "target_max": 9},
	{"chapter": 7, "enemy_id": "ch7_lieyun_hardliner_tracker", "player_level": 11, "role": "烈云封渡寻迹·双人编队", "target_min": 5, "target_max": 9},
	{"chapter": 7, "enemy_id": "ch7_mingwu_record_guard", "player_level": 12, "role": "茗雾护档使·双人编队", "target_min": 5, "target_max": 9},
	{"chapter": 7, "enemy_id": "ch7_mingwu_order_burner", "player_level": 12, "role": "茗雾焚令手·双人编队", "target_min": 5, "target_max": 9},
	{"chapter": 8, "enemy_id": "ch8_mistwood_blockade_guard", "player_level": 13, "role": "雾林阻截·双人编队", "target_min": 5, "target_max": 9},
	{"chapter": 8, "enemy_id": "ch8_mistwood_signal_burner", "player_level": 13, "role": "雾林点烽·双人编队", "target_min": 5, "target_max": 9},
	{"chapter": 8, "enemy_id": "ch8_false_order_courier", "player_level": 14, "role": "假令传使·双人编队", "target_min": 5, "target_max": 10},
	{"chapter": 8, "enemy_id": "ch8_false_order_escort", "player_level": 14, "role": "护令客·双人编队", "target_min": 5, "target_max": 10},
	{"chapter": 8, "enemy_id": "ch8_mechanism_warden", "player_level": 14, "role": "机关监守·双人编队", "target_min": 5, "target_max": 10},
	{"chapter": 8, "enemy_id": "ch8_mist_valve_keeper", "player_level": 14, "role": "雾阀守手·双人编队", "target_min": 5, "target_max": 10},
	{"chapter": 8, "enemy_id": "ch8_xueying_last_guard", "player_level": 15, "role": "终局可选单挑", "target_min": 8, "target_max": 13},
	{"chapter": 8, "enemy_id": "ch8_su_wusheng_final", "player_level": 16, "role": "终局Boss单挑", "target_min": 10, "target_max": 16},
]


static func standard_player(level: int) -> Dictionary:
	var safe_level := clampi(level, 1, 20)
	var gained := safe_level - 1
	var strength := 8 + gained
	var agility := 7 + gained
	var inner_power := 8 + gained
	var insight := 6 + gained
	var vitality := 10 + gained * 2
	var inner_pool := 8 + gained * 2
	var guard := 7 + gained
	var max_hp := 80 + vitality * 8 + strength * 3
	var max_mp := 20 + inner_pool * 6 + inner_power * 2
	var external_attack := BattleFormula.calc_external_attack(strength, 0)
	var internal_attack := BattleFormula.calc_internal_attack(inner_power, 0)
	var defense := guard * 2 + strength
	var speed := agility * 2
	var steps := safe_level - 1
	var cumulative_exp := steps * 80 + 20 * steps * (steps - 1)
	var power_score := float(max_hp) / 10.0 + float(external_attack) * 2.0 + float(defense) * 1.5 + float(speed) + float(max_mp) / 5.0
	return {
		"level": safe_level,
		"strength": strength,
		"agility": agility,
		"inner_power": inner_power,
		"insight": insight,
		"vitality": vitality,
		"inner_pool": inner_pool,
		"guard": guard,
		"max_hp": max_hp,
		"max_mp": max_mp,
		"external_attack": external_attack,
		"internal_attack": internal_attack,
		"defense": defense,
		"speed": speed,
		"exp_to_next": 80 + gained * 40,
		"cumulative_exp": cumulative_exp,
		"power_score": power_score,
	}


static func expected_gear_for_level(level: int) -> Dictionary:
	## Editable planning bands, kept separate from base growth. The workbook
	## exposes these values as assumptions; this helper gives Godot regressions
	## the same conservative profile.
	var safe_level := clampi(level, 1, 20)
	if safe_level == 1:
		return _gear("未成套", 0, 0, 0, 0, 0, 0, 0.0, 0.0)
	if safe_level <= 3:
		return _gear("林西前期套", 16, 1, 0, 0, 4, 18, 0.06, 0.0)
	if safe_level <= 6:
		return _gear("门派分支过渡套", 22, 5, 20, 10, 5, 22, 0.08, 0.01)
	if safe_level <= 9:
		return _gear("规划紫装成型套", 34, 10, 40, 25, 7, 30, 0.12, 0.02)
	if safe_level <= 12:
		return _gear("规划橙装初成套", 50, 16, 80, 45, 10, 37, 0.16, 0.03)
	if safe_level <= 15:
		return _gear("规划橙装进阶套", 58, 22, 120, 70, 13, 40, 0.20, 0.04)
	return _gear("终局测试套", 66, 30, 160, 100, 16, 44, 0.25, 0.05)


static func recommended_skill_for_level(level: int) -> Skill:
	var skill_id := "linxi_basic_sword_one"
	if level >= 13:
		skill_id = "heaven_pillar_staff"
	elif level >= 7:
		skill_id = "shadow_swallow_piercing_sword"
	elif level >= 3:
		skill_id = "linxi_basic_sword_two"
	return load("res://data/skills/%s.tres" % skill_id) as Skill


static func get_encounter_specs() -> Array[Dictionary]:
	return ENCOUNTER_SPECS.duplicate(true)


static func expected_damage(base_attack: int, fixed_damage: int, attack_scaling: int, target_defense: int, hit_chance: float, crit_chance_bonus: float = 0.0, crit_multiplier_bonus: float = 0.0, base_crit_multiplier: float = DEFAULT_CRIT_MULTIPLIER, source_hp: int = 1, source_max_hp: int = 1, modifier_stack: DamageModifierStack = null) -> float:
	var final_hit := BattleFormula.calc_hit_chance(hit_chance)
	if final_hit <= 0.0:
		return 0.0
	var final_crit := BattleFormula.calc_crit_chance(false, crit_chance_bonus)
	var normal := BattleFormula.calc_damage_breakdown(base_attack, fixed_damage, attack_scaling, target_defense, 1.0, 1.0, false, false, source_hp, source_max_hp, 1.0, "", modifier_stack).final_damage
	var requested_crit := base_crit_multiplier + crit_multiplier_bonus
	var critical := BattleFormula.calc_damage_breakdown(base_attack, fixed_damage, attack_scaling, target_defense, 1.0, requested_crit, false, false, source_hp, source_max_hp, 1.0, "", modifier_stack).final_damage
	return final_hit * ((1.0 - final_crit) * float(normal) + final_crit * float(critical))


static func simulate_encounter(enemy: EnemyDef, player_level: int, skill: Skill, gear: Dictionary = {}) -> Dictionary:
	if enemy == null or skill == null:
		return {}
	var player := standard_player(player_level)
	var attack_bonus := int(gear.get("attack_bonus", 0))
	var player_attack := int(player.get("internal_attack" if skill.damage_type == Skill.DamageType.INTERNAL else "external_attack", 1)) + attack_bonus
	var scaling := skill.get_attack_scaling() + int(gear.get("skill_scaling_bonus", 0))
	var player_hp := int(player.get("max_hp", 1)) + int(gear.get("hp_bonus", 0))
	var player_defense := int(player.get("defense", 0)) + int(gear.get("defense_bonus", 0))
	var player_speed := int(player.get("speed", 0)) + int(gear.get("speed_bonus", 0))
	var outgoing := expected_damage(
		player_attack, skill.fixed_damage, scaling, enemy.defense,
		BattleFormula.calc_hit_chance(skill.base_hit_chance, float(gear.get("hit_chance_bonus", 0.0))),
		float(gear.get("crit_chance_bonus", 0.0)), float(gear.get("crit_multiplier_bonus", 0.0)),
		DEFAULT_CRIT_MULTIPLIER, player_hp, player_hp
	)
	var incoming := _enemy_expected_damage(enemy, player_defense, enemy.max_hp, enemy.max_hp)
	var tkk := maxi(1, int(ceil(float(enemy.max_hp) / maxf(0.001, outgoing))))
	var ttd := maxi(1, int(ceil(float(player_hp) / maxf(0.001, incoming))))
	var duel := _simulate_expected_duel(enemy, player, skill, gear)
	return {
		"chapter": 0,
		"enemy_id": String(enemy.enemy_id),
		"enemy_name": enemy.display_name,
		"enemy_level": enemy.level,
		"player_level": clampi(player_level, 1, 20),
		"gear_profile": String(gear.get("profile", "未成套")),
		"skill_id": String(skill.skill_id),
		"skill_name": skill.display_name,
		"player_hp": player_hp,
		"player_attack": player_attack,
		"player_defense": player_defense,
		"player_speed": player_speed,
		"enemy_hp": enemy.max_hp,
		"enemy_attack": enemy.attack,
		"enemy_defense": enemy.defense,
		"enemy_speed": enemy.speed,
		"expected_player_damage": outgoing,
		"expected_enemy_damage": incoming,
		"tkk": tkk,
		"ttd": ttd,
		"safety_factor": float(ttd) / float(tkk),
		"duel_result": String(duel.get("result", "超时")),
		"duel_rounds": int(duel.get("rounds", MAX_SIMULATION_ROUNDS)),
		"duel_player_hp": float(duel.get("player_hp", 0.0)),
		"duel_enemy_hp": float(duel.get("enemy_hp", 0.0)),
	}


static func _enemy_expected_damage(enemy: EnemyDef, player_defense: int, source_hp: int, source_max_hp: int) -> float:
	var values: Array[float] = []
	for skill_id: StringName in enemy.skill_ids:
		var enemy_skill := load("res://data/skills/%s.tres" % String(skill_id)) as Skill
		if enemy_skill == null or not (enemy_skill.kind == Skill.Kind.ATTACK or enemy_skill.kind == Skill.Kind.DEBUFF):
			continue
		values.append(expected_damage(enemy.attack, enemy_skill.fixed_damage, enemy_skill.get_attack_scaling(), player_defense, enemy_skill.base_hit_chance, 0.0, 0.0, DEFAULT_CRIT_MULTIPLIER, source_hp, source_max_hp))
	if values.is_empty():
		return expected_damage(enemy.attack, 2, 100, player_defense, 0.85, 0.0, 0.0, DEFAULT_CRIT_MULTIPLIER, source_hp, source_max_hp)
	var total := 0.0
	for value: float in values:
		total += value
	return maxf(0.001, total / float(values.size()))


static func _simulate_expected_duel(enemy: EnemyDef, player: Dictionary, skill: Skill, gear: Dictionary) -> Dictionary:
	var player_max_hp := int(player.get("max_hp", 1)) + int(gear.get("hp_bonus", 0))
	var player_hp := float(player_max_hp)
	var enemy_hp := float(enemy.max_hp)
	var player_defense := int(player.get("defense", 0)) + int(gear.get("defense_bonus", 0))
	var player_speed := int(player.get("speed", 0)) + int(gear.get("speed_bonus", 0))
	var player_attack := int(player.get("internal_attack" if skill.damage_type == Skill.DamageType.INTERNAL else "external_attack", 1)) + int(gear.get("attack_bonus", 0))
	var player_scaling := skill.get_attack_scaling() + int(gear.get("skill_scaling_bonus", 0))
	for round_index in range(1, MAX_SIMULATION_ROUNDS + 1):
		var player_first := player_speed >= enemy.speed
		for actor in (["player", "enemy"] if player_first else ["enemy", "player"]):
			if actor == "player":
				var damage := expected_damage(player_attack, skill.fixed_damage, player_scaling, enemy.defense, BattleFormula.calc_hit_chance(skill.base_hit_chance, float(gear.get("hit_chance_bonus", 0.0))), float(gear.get("crit_chance_bonus", 0.0)), float(gear.get("crit_multiplier_bonus", 0.0)), DEFAULT_CRIT_MULTIPLIER, int(round(player_hp)), player_max_hp)
				enemy_hp -= damage
				if enemy_hp <= 0.0:
					return {"result": "胜利", "rounds": round_index, "player_hp": maxf(0.0, player_hp), "enemy_hp": 0.0}
			else:
				var damage := _enemy_expected_damage(enemy, player_defense, int(round(enemy_hp)), enemy.max_hp)
				player_hp -= damage
				if player_hp <= 0.0:
					return {"result": "失败", "rounds": round_index, "player_hp": 0.0, "enemy_hp": maxf(0.0, enemy_hp)}
	return {"result": "超时", "rounds": MAX_SIMULATION_ROUNDS, "player_hp": maxf(0.0, player_hp), "enemy_hp": maxf(0.0, enemy_hp)}


static func _gear(profile: String, attack_bonus: int, defense_bonus: int, hp_bonus: int, mp_bonus: int, speed_bonus: int, skill_scaling_bonus: int, crit_chance_bonus: float, hit_chance_bonus: float) -> Dictionary:
	return {
		"profile": profile,
		"attack_bonus": attack_bonus,
		"defense_bonus": defense_bonus,
		"hp_bonus": hp_bonus,
		"mp_bonus": mp_bonus,
		"speed_bonus": speed_bonus,
		"skill_scaling_bonus": skill_scaling_bonus,
		"crit_chance_bonus": crit_chance_bonus,
		"hit_chance_bonus": hit_chance_bonus,
		"crit_multiplier_bonus": 0.0,
	}
