class_name BattleFormula
extends RefCounted

## 战斗数值公式（静态工具类）。
##
## 所有伤害/暴击/命中/逃跑计算集中于此，便于：
##   - 单独测试边界条件（M6 要求）
##   - 全局微调时只需改动一处
##   - 加倍减半法快速评估数值意义（game-design-skills）

const CRIT_BASE: float = 0.05
const CRIT_MULT: float = 1.5
const CRIT_MAX: float = 0.70
const CRIT_MULT_MAX: float = 2.2
const DAMAGE_VARIANCE_MIN: float = 0.95
const DAMAGE_VARIANCE_MAX: float = 1.05
const MAX_DEFENSE_ABSORPTION_RATIO: float = 0.80
const FLEE_BASE: float = 0.5


static func calc_effective_attack(strength: int, inner_power: int, str_bonus: int, ip_bonus: int, legacy_atk: int, legacy_bonus: int) -> int:
	var core: int = (strength * 2 + inner_power) + (str_bonus * 2 + ip_bonus)
	var legacy: int = legacy_atk + legacy_bonus
	return max(legacy, core)


static func calc_external_attack(strength: int, str_bonus: int, final_attack_bonus: int = 0) -> int:
	## 外功只受筋骨与通用攻击加成影响。
	return maxi(1, (strength + str_bonus) * 3 + final_attack_bonus)


static func calc_internal_attack(inner_power: int, inner_bonus: int, final_attack_bonus: int = 0) -> int:
	## 内功只受内劲与通用攻击加成影响。
	return maxi(1, (inner_power + inner_bonus) * 3 + final_attack_bonus)


static func calc_effective_speed(agility: int, agi_bonus: int, legacy_spd: int, legacy_bonus: int) -> int:
	var core: int = agility * 2 + agi_bonus * 2
	var legacy: int = legacy_spd + legacy_bonus
	return max(legacy, core)


static func calc_crit_chance(burst_active: bool, equipment_bonus: float = 0.0) -> float:
	## 暴击只来自基础概率、武器词条与战斗状态；悟性不参与。
	var chance: float = CRIT_BASE + maxf(0.0, equipment_bonus)
	if burst_active:
		chance += 0.50
	return clampf(chance, 0.0, CRIT_MAX)


static func calc_hit_chance(base_chance: float, equipment_bonus: float = 0.0) -> float:
	return clampf(base_chance + maxf(0.0, equipment_bonus), 0.0, 1.0)


static func calc_damage_value(base_atk: int, fixed_damage: int, attack_scaling: int, target_def: int, variance: float = 1.0, crit_multiplier: float = 1.0, target_weak: bool = false, source_weak: bool = false, source_hp: int = 1, source_max_hp: int = 1) -> int:
	return calc_damage_breakdown(
		base_atk, fixed_damage, attack_scaling, target_def, variance, crit_multiplier,
		target_weak, source_weak, source_hp, source_max_hp
	).final_damage


static func calc_damage_breakdown(base_atk: int, fixed_damage: int, attack_scaling: int, target_def: int, variance: float = 1.0, crit_multiplier: float = 1.0, target_weak: bool = false, source_weak: bool = false, source_hp: int = 1, source_max_hp: int = 1, post_multiplier: float = 1.0, post_modifier_label: String = "", modifier_stack: DamageModifierStack = null) -> DamageBreakdown:
	## 固定伤害在防御前；所有阶段在此唯一结算并留下可审计快照。
	var detail := DamageBreakdown.new()
	detail.base_attack = maxi(0, base_atk)
	detail.fixed_damage = maxi(0, fixed_damage)
	detail.attack_scaling = maxi(0, attack_scaling)
	detail.scaled_attack = int(round(float(detail.base_attack) * float(detail.attack_scaling) / 100.0))
	detail.offense_before_variance = detail.fixed_damage + detail.scaled_attack
	detail.variance = maxf(0.0, variance)
	detail.damage_after_variance = int(round(float(detail.offense_before_variance) * detail.variance))

	detail.requested_crit_multiplier = maxf(1.0, crit_multiplier)
	detail.crit_multiplier = minf(detail.requested_crit_multiplier, CRIT_MULT_MAX)
	detail.crit_multiplier_capped = detail.requested_crit_multiplier > CRIT_MULT_MAX
	detail.was_critical = detail.requested_crit_multiplier > 1.0
	detail.damage_after_crit = int(round(float(detail.damage_after_variance) * detail.crit_multiplier))

	detail.target_defense = maxi(0, target_def)
	detail.target_weak = target_weak
	detail.effective_defense = int(round(float(detail.target_defense) * 0.5)) if target_weak else detail.target_defense
	# Preserve subtractive defense outside the high-defense suppression band.
	# The cap is based on this strike's actual post-critical power, never level.
	detail.max_defense_absorption = maxi(0, int(floor(float(detail.damage_after_crit) * MAX_DEFENSE_ABSORPTION_RATIO)))
	detail.defense_absorption = mini(detail.effective_defense, detail.max_defense_absorption)
	detail.defense_absorption_capped = detail.effective_defense > detail.max_defense_absorption
	detail.damage_after_defense = maxi(1, detail.damage_after_crit - detail.defense_absorption)

	var modifiers := modifier_stack.copy() if modifier_stack != null else DamageModifierStack.new()
	if source_weak:
		modifiers.add_outgoing_penalty("虚弱", 0.30)
	detail.source_weak = source_weak
	detail.source_weak_multiplier = 0.7 if source_weak else 1.0
	detail.outgoing_bonus_total = modifiers.get_outgoing_bonus_total()
	detail.outgoing_penalty_total = modifiers.get_outgoing_penalty_total()
	detail.outgoing_multiplier = modifiers.get_outgoing_multiplier()
	detail.outgoing_modifier_summary = modifiers.outgoing_summary()
	detail.damage_after_outgoing = maxi(1, int(round(float(detail.damage_after_defense) * detail.outgoing_multiplier)))
	detail.damage_after_source_weak = detail.damage_after_outgoing
	detail.source_hp = maxi(0, source_hp)
	detail.source_max_hp = maxi(1, source_max_hp)
	# HP is not a hidden outgoing-damage penalty. Explicit weaken/status zones
	# still apply above; retained trace fields keep older GM consumers compatible.
	detail.low_hp_multiplier = 1.0
	detail.damage_after_low_hp = detail.damage_after_outgoing
	detail.incoming_vulnerability_total = modifiers.get_incoming_vulnerability_total()
	detail.incoming_multiplier = modifiers.get_incoming_multiplier()
	detail.incoming_modifier_summary = modifiers.incoming_summary()
	detail.damage_after_incoming = maxi(1, int(round(float(detail.damage_after_low_hp) * detail.incoming_multiplier)))

	detail.post_modifier_label = post_modifier_label
	detail.post_multiplier = maxf(0.0, post_multiplier)
	detail.final_damage = maxi(1, int(round(float(detail.damage_after_incoming) * detail.post_multiplier)))
	return detail


static func calc_damage(base_atk: int, fixed_damage: int, attack_scaling: int, target_def: int, _is_player: bool, crit_mult_bonus: float, equipment_crit_chance: float, burst_active: bool, target_weak: bool, source_weak: bool, source_hp: int, source_max_hp: int, base_hit_chance: float = 1.0, equipment_hit_chance: float = 0.0, post_multiplier: float = 1.0, post_modifier_label: String = "", modifier_stack: DamageModifierStack = null) -> Dictionary:
	## 返回 {"dealt": int, "hit": bool, "was_crit": bool}。未命中时 dealt=0。
	var hit_chance := calc_hit_chance(base_hit_chance, equipment_hit_chance if _is_player else 0.0)
	var hit_roll := randf()
	if hit_chance < 1.0 and hit_roll >= hit_chance:
		var miss_detail := calc_damage_breakdown(base_atk, fixed_damage, attack_scaling, target_def, 1.0, 1.0, target_weak, source_weak, source_hp, source_max_hp, post_multiplier, post_modifier_label, modifier_stack)
		miss_detail.hit = false
		miss_detail.hit_chance = hit_chance
		miss_detail.final_damage = 0
		return {"dealt": 0, "hit": false, "was_crit": false, "variance": 1.0, "hit_chance": hit_chance, "breakdown": miss_detail}
	var was_crit := false

	var crit_chance: float = calc_crit_chance(burst_active, equipment_crit_chance if _is_player else 0.0)
	if randf() < crit_chance:
		was_crit = true
	var crit_multiplier: float = CRIT_MULT + crit_mult_bonus if was_crit else 1.0
	var variance := randf_range(DAMAGE_VARIANCE_MIN, DAMAGE_VARIANCE_MAX)
	var detail := calc_damage_breakdown(base_atk, fixed_damage, attack_scaling, target_def, variance, crit_multiplier, target_weak, source_weak, source_hp, source_max_hp, post_multiplier, post_modifier_label, modifier_stack)
	detail.hit = true
	detail.hit_chance = hit_chance
	detail.was_critical = was_crit
	detail.crit_chance = crit_chance
	return {"dealt": detail.final_damage, "hit": true, "was_crit": was_crit, "variance": variance, "hit_chance": hit_chance, "breakdown": detail}


static func estimate_damage_range(base_atk: int, fixed_damage: int, attack_scaling: int) -> Vector2i:
	var offense := maxi(0, fixed_damage) + int(round(float(maxi(0, base_atk)) * float(maxi(0, attack_scaling)) / 100.0))
	return Vector2i(
		maxi(1, int(floor(float(offense) * DAMAGE_VARIANCE_MIN))),
		maxi(1, int(ceil(float(offense) * DAMAGE_VARIANCE_MAX)))
	)


static func calc_poison_dot(max_hp: int, multiplier: float = 1.0) -> int:
	return maxi(3, int(round(float(max_hp) * 0.05 * multiplier)))


static func calc_flee_success() -> bool:
	return randf() < FLEE_BASE
