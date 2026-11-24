class_name Skill
extends Resource

## 技能。战斗系统依赖这个 Resource 描述行为。
##
## v2 新增：
##   - quality: 武学位阶，只影响展示/获取稀有度，不直接乘伤害
##   - fixed_damage + attack_scaling: 固定伤害 + 角色有效攻击百分比
##   - effect_value: 治疗/辅助技能的固定效果值，避免复用伤害字段
##
## v1：
##   - school: 门派归属，用于装备加成和内功互补匹配
##   - is_passive: 被动技能（习得即永久生效）
##   - complemented_by: 互补内功 skill_id，学了该内功后本外功获得加成
##   - complement_bonus_scaling: 互补时增加攻击系数百分点
##   - complement_bonus_desc: 互补效果 UI 描述

enum Target { ENEMY_SINGLE, ENEMY_ALL, ALLY_SINGLE, ALLY_ALL, SELF }
enum Kind { ATTACK, HEAL, BUFF, DEBUFF }
enum Delivery { MELEE, PROJECTILE, STATIONARY_AOE }
enum Quality { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum MotionStyle { AUTO, STATIONARY, APPROACH, DASH_THROUGH, SHADOW_FLURRY }
enum DamageType { EXTERNAL, INTERNAL }

@export var skill_id: StringName = ""
@export var display_name: String = ""
@export var icon_path: String = ""
@export var description: String = ""
@export_multiline var origin: String = "" ## 招式源流、传承与获得背景；武学详情完整展示。

@export var kind: Kind = Kind.ATTACK
@export var target: Target = Target.ENEMY_SINGLE
@export var delivery: Delivery = Delivery.MELEE
@export var mp_cost: int = 0
@export var quality: Quality = Quality.RARE
@export var fixed_damage: int = 0  ## 伤害公式的固定部分；攻击/削弱类招式必须大于 0。
@export var attack_scaling: int = 0  ## 叠加角色有效攻击的百分比；100 = 角色攻击力的 100%。
@export var effect_value: int = 0  ## 治疗/辅助技能的固定效果值。
@export var power: int = 0  ## v1 兼容字段；新资源不得再用，旧资源回退为 attack_scaling。
@export var hit_count: int = 1
@export var animation_id: StringName = &"default"
@export var motion_style: MotionStyle = MotionStyle.AUTO ## 角色本体演出；残影穿身等位移与 VFX 分层播放
@export var required_weapon_type: StringName = &"" ## "sword" / "blade" / "staff"; empty means weapon-independent.
@export var martial_category: StringName = &"" ## 武学界面分类；sword / blade / staff / palm / hidden。
@export var damage_type: DamageType = DamageType.EXTERNAL ## 外功看筋骨，内功看内劲。
@export_range(0.0, 1.0, 0.01) var base_hit_chance: float = 0.90 ## 普通攻击建议 0.80+，招式 0.90+。
@export var required_insight: int = -1 ## 习得门槛；-1 按品质使用默认门槛。
@export var practice_base_cost: int = 0 ## 第一层研读基础阅历；0 按品质使用默认值。
@export_range(1, 10, 1) var max_level: int = 10 ## 正常武学最高十重。
@export_range(1, 10, 1) var self_practice_level_cap: int = 10 ## 自行研读上限；师门绝学可停在九重等待剧情突破。
@export var evolves_to_skill_id: StringName = &"" ## 剧情突破后替换成的高阶武学。
@export var mastery_unlock_skill: StringName = &"" ## 圆满时另学的新招，保留原招。
@export_range(0, 100) var incoming_injury_resist_percent: int = 0
@export_multiline var breakthrough_hint: String = ""
@export_enum("none", "insight", "inner_pool") var breakthrough_attribute: String = "none"
@export_range(0, 999) var breakthrough_attribute_min: int = 0
@export var breakthrough_quest: StringName = &""
@export var breakthrough_internal_art: StringName = &"" ## 装备此心法可修习最后一重。
@export_category("Battle Audio")
@export var cast_sfx_path: String = ""
@export var impact_sfx_path: String = ""

## 门派与互补（v1 新增）
@export var school: String = ""  ## "gufeng" / "huashan" / "lingyue" / "mingwu" / "wudang" / "generic"
@export var is_passive: bool = false  ## 被动技（如 金刚力、月华引），习得后永久生效，不占技能槽
@export var complemented_by: String = ""  ## 互补内功 skill_id；空字符串表示无互补需求
@export var complement_bonus_scaling: int = 0  ## 互补时 attack_scaling 百分点加值。
@export var complement_bonus_power: int = 0  ## v1 兼容字段；新资源使用 complement_bonus_scaling。
@export var complement_bonus_desc: String = ""  ## 互补效果 UI 描述（如 "暴击伤害提升至 1.8 倍"）

## 心法契约。心法与攻击招式分开描述：习得时生效的常驻属性，
## 以及战斗中主动运功的效果。数值字段保存七项核心属性增量，
## UI 会把体魄/气海换算成玩家看到的“生命/内功”实际上限增量。
@export_category("Internal Art")
@export var is_internal_art: bool = false
@export var passive_strength_bonus: int = 0
@export var passive_agility_bonus: int = 0
@export var passive_inner_power_bonus: int = 0
@export var passive_insight_bonus: int = 0
@export var passive_vitality_bonus: int = 0
@export var passive_inner_pool_bonus: int = 0
@export var passive_guard_bonus: int = 0
@export var passive_strength_growth: int = 0
@export var passive_agility_growth: int = 0
@export var passive_inner_power_growth: int = 0
@export var passive_insight_growth: int = 0
@export var passive_vitality_growth: int = 0
@export var passive_inner_pool_growth: int = 0
@export var passive_guard_growth: int = 0
@export var active_effect_description: String = ""
@export var active_effect_type: StringName = &"" ## heal_guard / burst / guard / redirect 等主动语义。
@export var active_effect_growth: int = 0
@export var active_duration_turns: int = 0
@export var active_duration_growth: int = 0

## 心法装备效果。与“习得即生效”的常驻属性分开计算，不写回角色基础属性。
## weapon_categories 可填 sword / blade / staff / palm / hidden / all。
@export_category("Equipped Internal Art")
@export var equip_weapon_categories: Array[StringName] = []
@export_enum("all", "external", "internal") var equip_damage_scope: String = "all"
@export var equip_damage_scaling_bonus: int = 0
@export var equip_damage_scaling_growth: int = 0
@export_range(0.0, 0.5, 0.01) var equip_crit_chance_bonus: float = 0.0
@export_range(0.0, 0.2, 0.01) var equip_crit_chance_growth: float = 0.0
@export_range(0, 100, 1) var equip_internal_injury_bonus: int = 0
@export_range(0, 50, 1) var equip_internal_injury_growth: int = 0
@export var synergy_skill_ids: Array[StringName] = []
@export var synergy_damage_scaling_bonus: int = 0
@export var synergy_damage_scaling_growth: int = 0
@export_range(0.0, 0.5, 0.01) var synergy_crit_chance_bonus: float = 0.0
@export_range(0.0, 0.2, 0.01) var synergy_crit_chance_growth: float = 0.0
@export_range(0.0, 0.7, 0.01) var synergy_crit_multiplier_bonus: float = 0.0
@export_range(0.0, 0.2, 0.01) var synergy_crit_multiplier_growth: float = 0.0
@export_range(0, 100, 1) var synergy_internal_injury_bonus: int = 0
@export_range(0, 50, 1) var synergy_internal_injury_growth: int = 0
@export_range(0, 60, 1) var synergy_defense_pierce_bonus: int = 0
@export_range(0, 20, 1) var synergy_defense_pierce_growth: int = 0
@export_range(0, 100, 1) var synergy_self_hp_restore: int = 0
@export_range(0, 30, 1) var synergy_self_hp_restore_growth: int = 0
@export_range(0, 100, 1) var synergy_self_mp_restore: int = 0
@export_range(0, 30, 1) var synergy_self_mp_restore_growth: int = 0
@export var synergy_target_status: StringName = &"" ## armor_break / vulnerable / weaken / poison / bleed。
@export_range(0.0, 1.0, 0.01) var synergy_target_status_chance: float = 0.0
@export_range(0, 9, 1) var synergy_target_status_duration: int = 0
@export_range(0, 80, 1) var synergy_target_status_value: int = 0 ## 破防/易伤的百分比。
@export_range(0.0, 1.0, 0.01) var synergy_execute_threshold: float = 0.0 ## 目标气血低于此比例时触发追击增伤。
@export_range(0.0, 1.0, 0.01) var synergy_execute_damage_bonus: float = 0.0
@export_multiline var equipped_effect_description: String = ""

@export_category("Advanced Combat")
@export_range(0, 100, 1) var defense_pierce_percent: int = 0
@export_range(0.0, 0.65, 0.01) var skill_crit_chance_bonus: float = 0.0 ## 招式自身暴击率加成，仍受全局70%上限约束。
@export var inflicted_status: StringName = &"" ## poison / bleed / weaken 等。
@export_range(0.0, 1.0, 0.01) var status_chance: float = 0.0
@export_range(0, 9, 1) var status_duration: int = 0
@export_range(0, 100, 1) var internal_injury_gain: int = 0 ## 内功命中累积的内伤值；0 使用品质默认值。


func get_attack_scaling() -> int:
	return attack_scaling if attack_scaling > 0 or power <= 0 else power


func get_effect_value() -> int:
	return effect_value if effect_value > 0 or power <= 0 else power


func get_martial_category() -> StringName:
	if martial_category != &"":
		return martial_category
	var normalized := Equipment.normalize_weapon_type(required_weapon_type)
	if normalized != &"":
		return normalized
	return get_bonus_weapon_style()


func get_active_effect_value(current_mastery: int = 0) -> int:
	return maxi(0, get_effect_value() + maxi(0, current_mastery) * active_effect_growth)


func get_active_duration(current_mastery: int = 0) -> int:
	return maxi(0, active_duration_turns + maxi(0, current_mastery) * active_duration_growth)


func has_active_effect() -> bool:
	return not is_passive


func has_passive_attribute_bonus() -> bool:
	return (
		passive_strength_bonus != 0 or passive_agility_bonus != 0
		or passive_inner_power_bonus != 0 or passive_insight_bonus != 0
		or passive_vitality_bonus != 0 or passive_inner_pool_bonus != 0
		or passive_guard_bonus != 0
	)


func get_passive_effect_lines(current_mastery: int = 0) -> PackedStringArray:
	var rank := maxi(0, current_mastery)
	var lines := PackedStringArray()
	_append_bonus_line(lines, "生命", (passive_vitality_bonus + passive_vitality_growth * rank) * 8)
	_append_bonus_line(lines, "内功", (passive_inner_pool_bonus + passive_inner_pool_growth * rank) * 6)
	_append_bonus_line(lines, "筋骨", passive_strength_bonus + passive_strength_growth * rank)
	_append_bonus_line(lines, "机敏", passive_agility_bonus + passive_agility_growth * rank)
	_append_bonus_line(lines, "内劲", passive_inner_power_bonus + passive_inner_power_growth * rank)
	_append_bonus_line(lines, "悟性", passive_insight_bonus + passive_insight_growth * rank)
	_append_bonus_line(lines, "防御", (passive_guard_bonus + passive_guard_growth * rank) * 2)
	return lines


func get_equipped_bonus_for(technique: Skill, current_mastery: int = 0) -> Dictionary:
	var result := {
		"scaling": 0,
		"crit_chance": 0.0,
		"crit_multiplier": 0.0,
		"internal_injury": 0,
		"defense_pierce": 0,
		"self_hp_restore": 0,
		"self_mp_restore": 0,
		"target_status": &"",
		"target_status_chance": 0.0,
		"target_status_duration": 0,
		"target_status_value": 0,
		"execute_threshold": 0.0,
		"execute_damage_bonus": 0.0,
	}
	if not is_internal_art or technique == null or technique == self:
		return result
	# 普通攻击和另一门心法不是“武器招式”，不吃心法装备词条。
	if technique.skill_id == &"basic_attack" or technique.is_internal_art:
		return result
	var rank := maxi(0, current_mastery)
	var category := technique.get_martial_category()
	var family_match := &"all" in equip_weapon_categories or category in equip_weapon_categories
	var scope_match := (
		equip_damage_scope == "all"
		or (equip_damage_scope == "external" and technique.damage_type == DamageType.EXTERNAL)
		or (equip_damage_scope == "internal" and technique.damage_type == DamageType.INTERNAL)
	)
	if family_match and scope_match:
		result.scaling = equip_damage_scaling_bonus + equip_damage_scaling_growth * rank
		result.crit_chance = equip_crit_chance_bonus + equip_crit_chance_growth * rank
		if technique.damage_type == DamageType.INTERNAL:
			result.internal_injury = equip_internal_injury_bonus + equip_internal_injury_growth * rank
	if technique.skill_id in synergy_skill_ids:
		result.scaling = int(result.scaling) + synergy_damage_scaling_bonus + synergy_damage_scaling_growth * rank
		result.crit_chance = float(result.crit_chance) + synergy_crit_chance_bonus + synergy_crit_chance_growth * rank
		result.crit_multiplier = synergy_crit_multiplier_bonus + synergy_crit_multiplier_growth * rank
		if technique.damage_type == DamageType.INTERNAL:
			result.internal_injury = int(result.internal_injury) + synergy_internal_injury_bonus + synergy_internal_injury_growth * rank
		result.defense_pierce = synergy_defense_pierce_bonus + synergy_defense_pierce_growth * rank
		result.self_hp_restore = synergy_self_hp_restore + synergy_self_hp_restore_growth * rank
		result.self_mp_restore = synergy_self_mp_restore + synergy_self_mp_restore_growth * rank
		result.target_status = synergy_target_status
		result.target_status_chance = synergy_target_status_chance
		result.target_status_duration = synergy_target_status_duration
		result.target_status_value = synergy_target_status_value
		result.execute_threshold = synergy_execute_threshold
		result.execute_damage_bonus = synergy_execute_damage_bonus
	result.crit_chance = clampf(float(result.crit_chance), 0.0, 0.5)
	result.crit_multiplier = clampf(float(result.crit_multiplier), 0.0, 0.7)
	result.internal_injury = clampi(int(result.internal_injury), 0, 100)
	result.defense_pierce = clampi(int(result.defense_pierce), 0, 60)
	return result


func get_equipped_effect_lines(current_mastery: int = 0) -> PackedStringArray:
	var rank := maxi(0, current_mastery)
	var lines := PackedStringArray()
	var category_names := {&"sword": "剑系", &"blade": "刀系", &"staff": "棍系", &"palm": "掌系", &"hidden": "暗器", &"all": "全系"}
	var category_texts := PackedStringArray()
	for category: StringName in equip_weapon_categories:
		category_texts.append(String(category_names.get(category, String(category))))
	var family_label := "、".join(category_texts)
	var scope_label: String = String({"external": "外功", "internal": "内功"}.get(equip_damage_scope, ""))
	if not scope_label.is_empty():
		family_label += scope_label
	var scaling := equip_damage_scaling_bonus + equip_damage_scaling_growth * rank
	var crit := equip_crit_chance_bonus + equip_crit_chance_growth * rank
	var injury := equip_internal_injury_bonus + equip_internal_injury_growth * rank
	if scaling != 0:
		lines.append("%s招式伤害系数 %+d%%" % [family_label, scaling])
	if crit > 0.0:
		lines.append("%s招式暴击率 +%d%%" % [family_label, int(round(crit * 100.0))])
	if incoming_injury_resist_percent > 0:
		lines.append("所受内伤积累减少 %d%%" % incoming_injury_resist_percent)
	if injury != 0:
		lines.append("%s内功招式内伤积累 %+d" % [family_label, injury])
	if not synergy_skill_ids.is_empty():
		var names := PackedStringArray()
		for skill_id: StringName in synergy_skill_ids:
			var path := "res://data/skills/%s.tres" % String(skill_id)
			var skill := load(path) as Skill if ResourceLoader.exists(path) else null
			names.append(skill.display_name if skill != null else String(skill_id))
		var effects := PackedStringArray()
		var special_scaling := synergy_damage_scaling_bonus + synergy_damage_scaling_growth * rank
		var special_crit := synergy_crit_chance_bonus + synergy_crit_chance_growth * rank
		var special_crit_multiplier := synergy_crit_multiplier_bonus + synergy_crit_multiplier_growth * rank
		var special_injury := synergy_internal_injury_bonus + synergy_internal_injury_growth * rank
		var special_pierce := synergy_defense_pierce_bonus + synergy_defense_pierce_growth * rank
		var special_hp_restore := synergy_self_hp_restore + synergy_self_hp_restore_growth * rank
		var special_mp_restore := synergy_self_mp_restore + synergy_self_mp_restore_growth * rank
		if special_scaling != 0:
			effects.append("伤害系数 %+d%%" % special_scaling)
		if special_crit > 0.0:
			effects.append("暴击率 +%d%%" % int(round(special_crit * 100.0)))
		if special_crit_multiplier > 0.0:
			effects.append("暴击伤害 +%.1f倍" % special_crit_multiplier)
		if special_injury != 0:
			effects.append("内伤积累 %+d" % special_injury)
		if special_pierce != 0:
			effects.append("额外破防 %+d%%" % special_pierce)
		if special_hp_restore != 0:
			effects.append("命中回复生命 %d" % special_hp_restore)
		if special_mp_restore != 0:
			effects.append("命中回复内力 %d" % special_mp_restore)
		if synergy_target_status != &"" and synergy_target_status_duration > 0:
			var status_names := {&"armor_break": "破防", &"vulnerable": "易伤", &"weaken": "虚弱", &"poison": "中毒", &"bleed": "流血"}
			var status_text := "%d%%概率%s%d回合" % [int(round(synergy_target_status_chance * 100.0)), String(status_names.get(synergy_target_status, synergy_target_status)), synergy_target_status_duration]
			if synergy_target_status_value > 0:
				status_text += "（%d%%）" % synergy_target_status_value
			effects.append(status_text)
		if synergy_execute_threshold > 0.0 and synergy_execute_damage_bonus > 0.0:
			effects.append("目标生命低于%d%%时伤害 +%d%%" % [int(round(synergy_execute_threshold * 100.0)), int(round(synergy_execute_damage_bonus * 100.0))])
		if not effects.is_empty():
			lines.append("%s：%s" % ["、".join(names), "、".join(effects)])
	if lines.is_empty() and not equipped_effect_description.strip_edges().is_empty():
		lines.append(equipped_effect_description.strip_edges())
	return lines


func _append_bonus_line(lines: PackedStringArray, label: String, value: int) -> void:
	if value != 0:
		lines.append("%s %+d" % [label, value])


func get_complement_scaling_bonus() -> int:
	return complement_bonus_scaling if complement_bonus_scaling != 0 else complement_bonus_power


func get_required_insight() -> int:
	if required_insight >= 0:
		return required_insight
	# 白/绿/蓝/紫/橙。门槛保持温和，特殊秘籍可在资源中单独提高。
	return [0, 4, 5, 6, 7][clampi(quality, 0, 4)]


# 百分比按将要达到的第二至第十重排列；后两重仍需为绝学积攒阅历。
const PRACTICE_COST_PERCENT := [60, 100, 160, 240, 320, 430, 560, 730, 900]


func breakthrough_attribute_label() -> String:
	return "基础悟性" if breakthrough_attribute == "insight" else "基础内力"


func get_practice_limit(equipped_art: StringName, base_attribute: int = 0) -> int:
	if breakthrough_attribute != "none" and base_attribute >= breakthrough_attribute_min:
		return get_max_mastery()
	if breakthrough_internal_art != &"" and equipped_art == breakthrough_internal_art:
		return get_max_mastery()
	return get_self_practice_max_mastery()


func get_practice_cost(current_mastery: int, effective_insight: int, equipped_art: StringName = &"", base_attribute: int = 0) -> int:
	var self_practice_max := get_practice_limit(equipped_art, base_attribute)
	if current_mastery >= self_practice_max:
		return 0
	return get_rank_cost(current_mastery, effective_insight)


func get_rank_cost(current_mastery: int, effective_insight: int) -> int:
	if current_mastery >= get_max_mastery():
		return 0
	var quality_costs: Array[int] = [8, 12, 18, 28, 42]
	var base_cost: int = practice_base_cost if practice_base_cost > 0 else quality_costs[clampi(quality, 0, 4)]
	var undiscounted := base_cost * int(PRACTICE_COST_PERCENT[clampi(current_mastery, 0, PRACTICE_COST_PERCENT.size() - 1)]) / 100.0
	var excess_insight: int = maxi(0, effective_insight - get_required_insight())
	var discount: float = minf(0.50, float(excess_insight) * 0.05)
	return maxi(1, int(ceil(float(undiscounted) * (1.0 - discount))))


func get_max_mastery() -> int:
	return maxi(0, max_level - 1)


func get_self_practice_max_mastery() -> int:
	return maxi(0, mini(max_level, self_practice_level_cap) - 1)


func get_display_level(current_mastery: int) -> int:
	return clampi(current_mastery + 1, 1, max_level)


func get_bonus_weapon_style() -> StringName:
	## 仅用于匹配“对应兵器招式加成”，不会额外限制技能能否施放。
	if required_weapon_type != &"":
		return Equipment.normalize_weapon_type(required_weapon_type)
	if kind != Kind.ATTACK and kind != Kind.DEBUFF:
		return &""
	var id := String(skill_id)
	if id == "basic_attack":
		return &"any"
	if id in ["palm_strike", "canghai_zhenyue_palms", "canglong_three_turns"]:
		return &"palm"
	if id == "heavy_swing":
		return &"blade"
	if id == "toxic_needle":
		return &"hidden"
	if id.begins_with("linxi_") or id.begins_with("huashan_"):
		return &"sword"
	if id.begins_with("wudang_"):
		return &"palm"
	if id.begins_with("gufeng_"):
		return &"blade"
	if id.begins_with("lingyue_"):
		return &"staff"
	if id.begins_with("mingwu_"):
		return &"hidden"
	return &""
