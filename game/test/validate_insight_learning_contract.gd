extends SceneTree

var failures: Array[String] = []


func _initialize() -> void:
	var low := CharacterStats.new()
	low.inner_pool = 8
	low.inner_power = 8
	low.agility = 7
	low.insight = 1
	low.refresh_derived_stats(true)
	var high := low.duplicate(true) as CharacterStats
	high.insight = 30
	high.refresh_derived_stats(true)
	_expect("insight does not change max MP", high.max_mp, low.max_mp)
	_expect("insight does not change speed", high.speed, low.speed)
	_expect_float("base crit is independent of insight", BattleFormula.calc_crit_chance(false), 0.05)

	var skill := Skill.new()
	skill.quality = Skill.Quality.EPIC
	skill.required_insight = 6
	skill.practice_base_cost = 30
	_expect("explicit learning requirement", skill.get_required_insight(), 6)
	_expect("practice cost at requirement", skill.get_practice_cost(0, 6), 30)
	_expect("higher insight discounts practice", skill.get_practice_cost(0, 10), 24)
	_expect("practice discount is capped", skill.get_practice_cost(0, 99), 15)
	_expect("later mastery costs more", skill.get_practice_cost(1, 10), 48)

	var allowed_slots := [Equipment.Slot.WEAPON, Equipment.Slot.ARMOR, Equipment.Slot.ACCESSORY]
	var nonzero_count := 0
	var weapon_count := 0
	var equipment_files := DirAccess.get_files_at("res://data/equipment")
	for file_name in equipment_files:
		if not file_name.ends_with(".tres"):
			continue
		var equipment := load("res://data/equipment/%s" % file_name) as Equipment
		if equipment == null or equipment.insight_bonus <= 0:
			continue
		nonzero_count += 1
		if equipment.slot == Equipment.Slot.WEAPON:
			weapon_count += 1
		_check(equipment.slot in allowed_slots, "%s has insight in forbidden slot %d" % [equipment.item_id, equipment.slot])
		_check(equipment.quality >= Item.Quality.RARE, "%s insight equipment must be rare or better" % equipment.item_id)
	_check(nonzero_count <= 14, "insight equipment remains limited (actual %d)" % nonzero_count)
	_check(weapon_count <= 7, "only a few weapons carry insight (actual %d)" % weapon_count)

	print("[InsightLearningContract] checks=12 equipment=%d weapons=%d failed=%d" % [nonzero_count, weapon_count, failures.size()])
	for failure in failures:
		push_error("[InsightLearningContract] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)


func _expect(label: String, actual: int, expected: int) -> void:
	if actual != expected:
		failures.append("%s expected=%d actual=%d" % [label, expected, actual])


func _expect_float(label: String, actual: float, expected: float) -> void:
	if not is_equal_approx(actual, expected):
		failures.append("%s expected=%.3f actual=%.3f" % [label, expected, actual])
