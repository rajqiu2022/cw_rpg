extends SceneTree

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_check(Equipment.normalize_weapon_type(&"dagger") == &"sword", "dagger normalizes to sword")
	_check(Equipment.normalize_weapon_type(&"short_blade") == &"sword", "short blade normalizes to sword")
	_check(Equipment.normalize_weapon_type(&"axe") == &"blade", "axe normalizes to blade")
	_check(BattleFormula.calc_external_attack(12, 3, 4) == 49, "external damage scales from strength")
	_check(BattleFormula.calc_internal_attack(12, 3, 4) == 49, "internal damage scales from inner power")
	_check(is_equal_approx(BattleFormula.calc_hit_chance(0.85, 0.20), 1.0), "accuracy caps at 100 percent")
	_check(is_equal_approx(BattleFormula.calc_crit_chance(true, 0.50), 0.70), "critical chance caps at 70 percent")

	var basic: Skill = load("res://data/skills/basic_attack.tres")
	_check(basic != null and basic.base_hit_chance >= 0.80 and basic.base_hit_chance <= 1.0,
		"basic attack accuracy starts at 80 percent or above")
	var hidden_count := 0
	for filename in DirAccess.get_files_at("res://data/skills"):
		if not filename.ends_with(".tres"):
			continue
		var skill: Skill = load("res://data/skills/%s" % filename)
		if skill == null or skill.is_passive:
			continue
		if skill.skill_id != &"basic_attack":
			_check(skill.base_hit_chance >= 0.90 and skill.base_hit_chance <= 1.0,
				"%s accuracy is at least 90 percent" % skill.skill_id)
		if skill.get_martial_category() == &"hidden":
			hidden_count += 1
	_check(hidden_count >= 4, "hidden-weapon category has meaningful content")

	var skill_panel_source := FileAccess.get_file_as_string("res://scripts/ui/skill_panel.gd")
	_check(skill_panel_source.contains('["全部", "剑", "刀", "棍", "掌", "暗器"]'),
		"martial UI category order is sword blade staff palm hidden")

	print("[CombatTaxonomy20260819] checks=%d hidden=%d failed=%d" % [checks, hidden_count, failures.size()])
	for failure in failures:
		push_error("[CombatTaxonomy20260819] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
