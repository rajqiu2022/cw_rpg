extends RefCounted

## Signed intrinsic bonuses, shared by equipment details and hover tooltips.
const POSITIVE := "#72d2a6"
const NEGATIVE := "#ff8770"
const NEUTRAL := "#82949c"

static func rows(equipment: Equipment) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for stat in [
		["攻击", equipment.atk_bonus], ["防御", equipment.def_bonus],
		["守御", equipment.get_guard_bonus()], ["速度", equipment.speed_bonus],
		["筋骨", equipment.get_strength_bonus()], ["机敏", equipment.get_agility_bonus()],
		["内劲", equipment.get_inner_power_bonus()], ["悟性", equipment.get_insight_bonus()],
		["生命", equipment.get_vitality_bonus()], ["内力", equipment.get_inner_pool_bonus()],
	]:
		_append(result, stat[0], stat[1])
	_append(result, "暴击率", int(round(equipment.get_crit_chance_bonus() * 100.0)), "%")
	_append(result, "命中率", int(round(equipment.get_hit_chance_bonus() * 100.0)), "%")
	var styles := {&"sword": "剑法", &"blade": "刀法", &"staff": "棍法", &"palm": "掌法", &"hidden": "暗器", &"dagger": "短兵"}
	_append(result, "%s招式系数" % styles.get(equipment.get_martial_style(), "兵器"), equipment.get_weapon_skill_scaling_bonus(), "%")
	var schools := {"all": "全门派", "linxi": "林西", "gufeng": "古峰", "huashan": "华山", "lingyue": "凌月", "mingwu": "茗雾", "wudang": "武当"}
	_append(result, "%s武功系数" % schools.get(equipment.skill_bonus_school, equipment.skill_bonus_school), equipment.get_skill_scaling_bonus(), "%")
	if not equipment.special_effect_description.strip_edges().is_empty():
		result.append({"text": "◆ %s" % equipment.special_effect_description.strip_edges(), "kind": "special", "value": 0})
	return result


static func _append(result: Array[Dictionary], label: String, value: int, suffix: String = "") -> void:
	if value != 0:
		result.append({"text": "%s %+d%s" % [label, value, suffix], "kind": "stat", "value": value})


static func row_color(row: Dictionary, quality_color: String) -> String:
	if row.get("kind", "stat") == "special":
		return quality_color
	var value := int(row.get("value", 0))
	return POSITIVE if value > 0 else (NEGATIVE if value < 0 else NEUTRAL)


static func bbcode(equipment: Equipment, quality_color: String, separator: String = "\n") -> String:
	var formatted: Array[String] = []
	for row in rows(equipment):
		formatted.append("[color=%s]%s[/color]" % [row_color(row, quality_color), row.text])
	return separator.join(formatted) if not formatted.is_empty() else "[color=%s]无额外属性[/color]" % NEUTRAL
