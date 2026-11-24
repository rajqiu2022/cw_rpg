extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	var weapon := Equipment.new()
	weapon.atk_bonus = 7
	weapon.crit_chance_bonus = 0.12
	weapon.weapon_skill_bonus_scaling = 10
	weapon.skill_bonus_school = "huashan"
	weapon.skill_bonus_scaling = 10
	_expect("blue sword displayed attack", weapon.atk_bonus, 7)
	_expect("attack does not become strength", weapon.get_strength_bonus(), 0)
	var naked_attack := 8 * 2 + 8
	var equipped_attack := (8 + weapon.get_strength_bonus()) * 2 + 8 + weapon.get_inner_power_bonus() + weapon.get_attack_bonus()
	_expect("literal +7 attack delta", equipped_attack - naked_attack, 7)
	_expect("school bonus migrated", weapon.get_skill_scaling_bonus(), 10)
	_expect_float("weapon crit chance", weapon.get_crit_chance_bonus(), 0.12)
	_expect_float("crit formula includes equipment", BattleFormula.calc_crit_chance(false, weapon.get_crit_chance_bonus()), 0.17)
	_expect_float("base crit is fixed", BattleFormula.calc_crit_chance(false, 0.0), 0.05)
	_expect("weapon technique scaling", weapon.get_weapon_skill_scaling_bonus(), 10)
	var mixed_weapon: Equipment = load("res://data/equipment/gufeng_diamond_blade.tres")
	if mixed_weapon == null:
		failures.append("gufeng_diamond_blade failed to load")
	else:
		_expect("mixed weapon literal attack field", mixed_weapon.get_attack_bonus(), 44)
		var mixed_delta := mixed_weapon.get_attack_bonus() + mixed_weapon.get_strength_bonus() * 2 + mixed_weapon.get_inner_power_bonus()
		_expect("mixed weapon attributes counted once", mixed_delta, 54)

	var stats := CharacterStats.new()
	stats.defense = 12
	stats.hp = 100
	stats.max_hp = 100
	var dealt := stats.take_damage(37)
	_expect("take_damage accepts final damage", dealt, 37)
	_expect("take_damage does not subtract defense twice", stats.hp, 63)

	print("[EquipmentCombatBonuses] checks=12 failed=%d" % failures.size())
	for failure in failures:
		push_error("[EquipmentCombatBonuses] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _expect(label: String, actual: int, expected: int) -> void:
	if actual != expected:
		failures.append("%s expected=%d actual=%d" % [label, expected, actual])


func _expect_float(label: String, actual: float, expected: float) -> void:
	if not is_equal_approx(actual, expected):
		failures.append("%s expected=%.3f actual=%.3f" % [label, expected, actual])
