extends SceneTree

var failures := 0


func _initialize() -> void:
	_check_standard_growth()
	_check_expected_damage()
	_check_encounter_matrix()
	print("[StandardCombatBalanceSimulator20260824] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_standard_growth() -> void:
	var level_one := CombatBalanceSimulator.standard_player(1)
	_check(int(level_one.get("max_hp", 0)) == 184, "Lv1 standard HP matches CharacterStats")
	_check(int(level_one.get("max_mp", 0)) == 84, "Lv1 standard inner power matches CharacterStats")
	_check(int(level_one.get("external_attack", 0)) == 24, "Lv1 external attack uses strength only")
	_check(int(level_one.get("internal_attack", 0)) == 24, "Lv1 internal attack uses inner power only")
	_check(int(level_one.get("defense", 0)) == 22, "Lv1 defense matches the runtime derived formula")
	_check(int(level_one.get("speed", 0)) == 14, "Lv1 speed excludes insight")
	var level_twenty := CombatBalanceSimulator.standard_player(20)
	_check(int(level_twenty.get("max_hp", 0)) == 545, "Lv20 HP follows the real linear growth curve")
	_check(int(level_twenty.get("max_mp", 0)) == 350, "Lv20 inner power follows the real linear growth curve")
	_check(int(level_twenty.get("cumulative_exp", 0)) == 8360, "Lv20 cumulative experience matches the live requirement curve")


func _check_expected_damage() -> void:
	var expected := CombatBalanceSimulator.expected_damage(24, 10, 100, 3, 1.0, 0.0, 0.0, 1.5)
	var normal := BattleFormula.calc_damage_breakdown(24, 10, 100, 3, 1.0, 1.0).final_damage
	var critical := BattleFormula.calc_damage_breakdown(24, 10, 100, 3, 1.0, 1.5).final_damage
	var manual := float(normal) * 0.95 + float(critical) * 0.05
	_check(is_equal_approx(expected, manual), "expected damage reuses runtime normal and critical paths")
	var missed := CombatBalanceSimulator.expected_damage(24, 10, 100, 3, 0.0)
	_check(is_zero_approx(missed), "zero accuracy produces zero expected damage")


func _check_encounter_matrix() -> void:
	var specs := CombatBalanceSimulator.get_encounter_specs()
	_check(specs.size() == 40, "chapter 1-8 simulator owns all 40 current encounter anchors")
	for spec: Dictionary in specs:
		var enemy_id := String(spec.get("enemy_id", ""))
		var enemy := load("res://data/enemies/%s.tres" % enemy_id) as EnemyDef
		_check(enemy != null, "encounter resource loads: %s" % enemy_id)
		if enemy == null:
			continue
		var skill := CombatBalanceSimulator.recommended_skill_for_level(int(spec.get("player_level", 1)))
		var result := CombatBalanceSimulator.simulate_encounter(enemy, int(spec.get("player_level", 1)), skill, CombatBalanceSimulator.expected_gear_for_level(int(spec.get("player_level", 1))))
		_check(float(result.get("expected_player_damage", 0.0)) > 0.0, "outgoing expected damage is positive: %s" % enemy_id)
		_check(int(result.get("tkk", 0)) > 0 and int(result.get("ttd", 0)) > 0, "TKK and TTD are finite: %s" % enemy_id)
		_check(float(result.get("safety_factor", 0.0)) > 0.0, "safety factor is positive: %s" % enemy_id)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
