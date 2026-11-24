extends SceneTree

const OUTPUT_RELATIVE := "../tmp/combat-balance-audit-20260824/standard-combat-simulation.json"


func _initialize() -> void:
	var level_rows: Array[Dictionary] = []
	var gear_profiles: Dictionary = {}
	for level in range(1, 21):
		var row := CombatBalanceSimulator.standard_player(level)
		var gear := CombatBalanceSimulator.expected_gear_for_level(level)
		row["gear_profile"] = gear.get("profile", "")
		row["gear_attack_bonus"] = gear.get("attack_bonus", 0)
		row["gear_defense_bonus"] = gear.get("defense_bonus", 0)
		row["gear_hp_bonus"] = gear.get("hp_bonus", 0)
		row["gear_mp_bonus"] = gear.get("mp_bonus", 0)
		row["gear_speed_bonus"] = gear.get("speed_bonus", 0)
		row["gear_skill_scaling_bonus"] = gear.get("skill_scaling_bonus", 0)
		row["gear_crit_chance_bonus"] = gear.get("crit_chance_bonus", 0.0)
		row["gear_hit_chance_bonus"] = gear.get("hit_chance_bonus", 0.0)
		level_rows.append(row)
		gear_profiles[String(gear.get("profile", ""))] = gear

	var encounter_rows: Array[Dictionary] = []
	var pressure_rows: Array[Dictionary] = []
	for spec: Dictionary in CombatBalanceSimulator.get_encounter_specs():
		var enemy := load("res://data/enemies/%s.tres" % String(spec.get("enemy_id", ""))) as EnemyDef
		if enemy == null:
			continue
		var player_level := int(spec.get("player_level", 1))
		var snapshot := CombatBalanceSimulator.simulate_encounter(enemy, player_level, CombatBalanceSimulator.recommended_skill_for_level(player_level), CombatBalanceSimulator.expected_gear_for_level(player_level))
		var bare_snapshot := CombatBalanceSimulator.simulate_encounter(enemy, player_level, CombatBalanceSimulator.recommended_skill_for_level(player_level), {})
		_merge_spec(snapshot, spec)
		snapshot["bare_expected_player_damage"] = bare_snapshot.get("expected_player_damage", 0.0)
		snapshot["bare_expected_enemy_damage"] = bare_snapshot.get("expected_enemy_damage", 0.0)
		snapshot["bare_tkk"] = bare_snapshot.get("tkk", 0)
		snapshot["bare_ttd"] = bare_snapshot.get("ttd", 0)
		snapshot["bare_safety_factor"] = bare_snapshot.get("safety_factor", 0.0)
		snapshot["turn_fit"] = _turn_fit(int(snapshot.get("tkk", 0)), int(spec.get("target_min", 0)), int(spec.get("target_max", 99)))
		snapshot["safety_band"] = _safety_band(float(snapshot.get("safety_factor", 0.0)), String(spec.get("role", "")))
		encounter_rows.append(snapshot)
		for level in range(1, 21):
			var pressure := CombatBalanceSimulator.simulate_encounter(enemy, level, CombatBalanceSimulator.recommended_skill_for_level(level), CombatBalanceSimulator.expected_gear_for_level(level))
			_merge_spec(pressure, spec)
			pressure["matrix_level"] = level
			pressure["level_delta"] = level - player_level
			pressure["turn_fit"] = _turn_fit(int(pressure.get("tkk", 0)), int(spec.get("target_min", 0)), int(spec.get("target_max", 99)))
			pressure_rows.append(pressure)

	var payload := {
		"schema_version": 1,
		"generated_date": "2026-08-24",
		"source_contract": "docs/combat-damage-pipeline-v1.md",
		"notes": [
			"基础成长完全复用CharacterStats当前线性公式。",
			"伤害期望复用BattleFormula的普通/暴击路径，按命中率与暴击率加权。",
			"装备档位是可编辑规划假设，不会改写任何游戏资源。",
			"中毒、流血、治疗、道具和玩家策略不计入模型，需继续实机验证。",
		],
		"gear_profiles": gear_profiles.values(),
		"levels": level_rows,
		"encounters": encounter_rows,
		"pressure_matrix": pressure_rows,
	}
	var output_path := ProjectSettings.globalize_path("res://%s" % OUTPUT_RELATIVE)
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("cannot write standard combat simulation: %s" % output_path)
		quit(1)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	print("[StandardCombatSimulationExport] levels=%d encounters=%d matrix=%d output=%s" % [level_rows.size(), encounter_rows.size(), pressure_rows.size(), output_path])
	quit(0)


func _merge_spec(row: Dictionary, spec: Dictionary) -> void:
	row["chapter"] = spec.get("chapter", 0)
	row["role"] = spec.get("role", "")
	row["recommended_level"] = spec.get("player_level", 1)
	row["target_min"] = spec.get("target_min", 0)
	row["target_max"] = spec.get("target_max", 99)


func _turn_fit(tkk: int, target_min: int, target_max: int) -> String:
	if tkk < target_min:
		return "偏快"
	if tkk > target_max:
		return "偏慢"
	return "命中目标"


func _safety_band(value: float, role: String) -> String:
	var is_boss := "Boss" in role
	if is_boss:
		if value < 0.8:
			return "过险"
		if value > 1.8:
			return "偏易"
		return "合理"
	if value < 1.2:
		return "过险"
	if value > 3.0:
		return "偏易"
	return "合理"
