extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	_expect("fixed + 100% - defense", BattleFormula.calc_damage_value(24, 18, 100, 5), 37)
	_expect("round scaled attack", BattleFormula.calc_damage_value(24, 32, 60, 5), 41)
	_expect("fixed damage carries low attack", BattleFormula.calc_damage_value(0, 20, 100, 5), 15)
	_expect("zero scaling remains valid", BattleFormula.calc_damage_value(24, 20, 0, 5), 15)
	_expect("high defense absorbs at most floor(44 * 80%)", BattleFormula.calc_damage_value(24, 20, 100, 999), 9)
	_expect("defense only once", BattleFormula.calc_damage_value(31, 10, 100, 4), 37)
	_expect("crit before defense", BattleFormula.calc_damage_value(24, 18, 100, 5, 1.0, 1.5), 58)
	_expect("Linxi first form baseline", _skill_damage("linxi_basic_sword_one", 31, 4), 37)
	_expect("Linxi second form baseline", _skill_damage("linxi_basic_sword_two", 31, 4), 50)

	print("[SkillDamageFormula] checks=9 failed=%d" % failures.size())
	for failure in failures:
		push_error("[SkillDamageFormula] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _skill_damage(skill_id: String, attack: int, defense: int) -> int:
	var skill: Skill = load("res://data/skills/%s.tres" % skill_id)
	if skill == null:
		failures.append("failed to load %s" % skill_id)
		return -1
	return BattleFormula.calc_damage_value(attack, skill.fixed_damage, skill.get_attack_scaling(), defense)


func _expect(label: String, actual: int, expected: int) -> void:
	if actual != expected:
		failures.append("%s expected=%d actual=%d" % [label, expected, actual])
