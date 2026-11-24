class_name DamageBreakdown
extends RefCounted

## One immutable-in-practice trace of a damage calculation. BattleFormula owns
## the numeric stages; BattleController only annotates source/target/skill.

var source_label: String = ""
var target_label: String = ""
var skill_label: String = ""

var hit: bool = true
var hit_chance: float = 1.0
var was_critical: bool = false
var crit_chance: float = 0.0

var base_attack: int = 0
var fixed_damage: int = 0
var attack_scaling: int = 0
var scaled_attack: int = 0
var offense_before_variance: int = 0
var variance: float = 1.0
var damage_after_variance: int = 0

var requested_crit_multiplier: float = 1.0
var crit_multiplier: float = 1.0
var crit_multiplier_capped: bool = false
var damage_after_crit: int = 0

var target_defense: int = 0
var target_weak: bool = false
var effective_defense: int = 0
var defense_absorption: int = 0
var max_defense_absorption: int = 0
var defense_absorption_capped: bool = false
var damage_after_defense: int = 0

var outgoing_bonus_total: float = 0.0
var outgoing_penalty_total: float = 0.0
var outgoing_multiplier: float = 1.0
var outgoing_modifier_summary: String = ""
var damage_after_outgoing: int = 0

var source_weak: bool = false
var source_weak_multiplier: float = 1.0
var damage_after_source_weak: int = 0
var source_hp: int = 1
var source_max_hp: int = 1
var low_hp_multiplier: float = 1.0
var damage_after_low_hp: int = 0

var incoming_vulnerability_total: float = 0.0
var incoming_multiplier: float = 1.0
var incoming_modifier_summary: String = ""
var damage_after_incoming: int = 0

var post_modifier_label: String = ""
var post_multiplier: float = 1.0
var final_damage: int = 0


func annotate(source: String, target: String, skill: String) -> DamageBreakdown:
	source_label = source
	target_label = target
	skill_label = skill
	return self


func to_gm_text() -> String:
	var context := ""
	if not source_label.is_empty() or not target_label.is_empty():
		context = "%s → %s" % [source_label if not source_label.is_empty() else "攻击方", target_label if not target_label.is_empty() else "目标"]
	if not skill_label.is_empty():
		context += (" · " if not context.is_empty() else "") + skill_label
	var lines := PackedStringArray()
	if not context.is_empty():
		lines.append(context)
	lines.append("命中 %.0f%% · %s" % [hit_chance * 100.0, "命中" if hit else "未命中"])
	lines.append("造数 %d × %d%% + 固定%d = %d" % [base_attack, attack_scaling, fixed_damage, offense_before_variance])
	lines.append("浮动 ×%.2f → %d" % [variance, damage_after_variance])
	if was_critical:
		var cap_note := "（原×%.2f，已封顶）" % requested_crit_multiplier if crit_multiplier_capped else ""
		lines.append("暴击 ×%.2f%s → %d" % [crit_multiplier, cap_note, damage_after_crit])
	else:
		lines.append("未暴击 → %d" % damage_after_crit)
	lines.append("防御 %d%s · 实际吸收 %d / 本击上限 %d%s → %d" % [effective_defense, "（虚弱减半）" if target_weak else "", defense_absorption, max_defense_absorption, "（80%吸收封顶）" if defense_absorption_capped else "", damage_after_defense])
	if outgoing_multiplier != 1.0:
		lines.append("攻击方修正%s ×%.2f → %d" % ["（%s）" % outgoing_modifier_summary if not outgoing_modifier_summary.is_empty() else "", outgoing_multiplier, damage_after_outgoing])
	if low_hp_multiplier != 1.0:
		lines.append("伤势衰减 ×%.2f → %d" % [low_hp_multiplier, damage_after_low_hp])
	if incoming_multiplier != 1.0:
		lines.append("目标易伤%s ×%.2f → %d" % ["（%s）" % incoming_modifier_summary if not incoming_modifier_summary.is_empty() else "", incoming_multiplier, damage_after_incoming])
	if post_multiplier != 1.0:
		lines.append("%s ×%.2f → %d" % [post_modifier_label if not post_modifier_label.is_empty() else "最终修正", post_multiplier, final_damage])
	lines.append("最终伤害：%d" % final_damage)
	return "\n".join(lines)
