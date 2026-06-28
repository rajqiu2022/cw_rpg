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
const DAMAGE_VARIANCE_MIN: float = 0.85
const DAMAGE_VARIANCE_MAX: float = 1.15
const FLEE_BASE: float = 0.5


static func calc_effective_attack(strength: int, inner_power: int, str_bonus: int, ip_bonus: int, legacy_atk: int, legacy_bonus: int) -> int:
	var core: int = (strength * 2 + inner_power) + (str_bonus * 2 + ip_bonus)
	var legacy: int = legacy_atk + legacy_bonus
	return max(legacy, core)


static func calc_effective_speed(agility: int, insight: int, agi_bonus: int, ins_bonus: int, legacy_spd: int, legacy_bonus: int) -> int:
	var core: int = (agility * 2 + insight) + (agi_bonus * 2 + ins_bonus)
	var legacy: int = legacy_spd + legacy_bonus
	return max(legacy, core)


static func calc_crit_chance(insight: int, burst_active: bool) -> float:
	var chance: float = CRIT_BASE + insight * 0.005
	if burst_active:
		chance += 0.50
	return chance


static func calc_damage(base_atk: int, power_mult: float, target_def: int, is_player: bool, crit_mult_bonus: float, insight: int, burst_active: bool, target_weak: bool, source_weak: bool, source_hp: int, source_max_hp: int) -> Dictionary:
	## 返回 {"dealt": int, "was_crit": bool}
	var raw: int = int(base_atk * power_mult * randf_range(DAMAGE_VARIANCE_MIN, DAMAGE_VARIANCE_MAX))
	var was_crit := false

	var crit_chance: float = CRIT_BASE
	if is_player:
		crit_chance += insight * 0.005
	if burst_active:
		crit_chance += 0.50
	if randf() < crit_chance:
		var mult: float = CRIT_MULT + crit_mult_bonus
		raw = int(raw * mult)
		was_crit = true

	var effective_def: int = target_def
	if target_weak:
		effective_def = int(target_def * 0.5)
	var dealt: int = max(1, raw - effective_def)

	if source_weak:
		dealt = int(dealt * 0.7)

	var hp_ratio: float = float(source_hp) / max(1, source_max_hp)
	var weakness: float = 1.0
	if hp_ratio < 0.7: weakness = 0.85
	if hp_ratio < 0.5: weakness = 0.65
	if hp_ratio < 0.3: weakness = 0.45
	if hp_ratio < 0.1: weakness = 0.25

	return {"dealt": int(dealt * weakness), "was_crit": was_crit}


static func calc_poison_dot(max_hp: int, multiplier: float = 1.0) -> int:
	return maxi(3, int(round(float(max_hp) * 0.05 * multiplier)))


static func calc_flee_success() -> bool:
	return randf() < FLEE_BASE
