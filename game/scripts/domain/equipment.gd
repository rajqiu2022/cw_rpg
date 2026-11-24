class_name Equipment
extends Item

## 装备。继承自 Item，多了"穿戴槽位"和"属性加成"。
## 即穿即生效；MVP 不做强化/附魔/套装。
## v1：新增七项核心属性加成，并保留旧字段兼容已有 .tres 数据。

enum Slot { WEAPON, HEAD, ARMOR, HANDS, SHOES, ACCESSORY }

@export var slot: Slot = Slot.WEAPON
@export var weapon_type: StringName = &"" ## Used only when slot == WEAPON.
@export var martial_style: StringName = &"" ## 可选：非武器装备所强化的武学类型，如护手强化 palm。

## 旧兼容字段
@export var atk_bonus: int = 0
@export var def_bonus: int = 0
@export var hp_bonus: int = 0
@export var mp_bonus: int = 0
@export var speed_bonus: int = 0

## 七项核心属性加成
@export var str_bonus: int = 0         ## 筋骨
@export var agi_bonus: int = 0         ## 机敏
@export var inner_bonus: int = 0       ## 内劲
@export var insight_bonus: int = 0     ## 悟性
@export var vitality_bonus: int = 0    ## 生命
@export var inner_pool_bonus: int = 0  ## 内力
@export var guard_bonus: int = 0       ## 防御
@export_range(0.0, 0.5, 0.01) var crit_chance_bonus: float = 0.0 ## 直接增加暴击概率；0.12 = +12%
@export_range(0.0, 0.2, 0.01) var hit_chance_bonus: float = 0.0 ## 直接增加命中率；全局最高 100%。
@export var weapon_skill_bonus_scaling: int = 0 ## 对应兵器招式的 attack_scaling 百分点加值

@export_category("Special Effect")
@export var special_effect_type: StringName = &"" ## poison / bleed / weaken / internal_injury / armor_break / damage_boost / guard / heal
@export_range(0.0, 1.0, 0.01) var special_effect_chance: float = 0.0
@export var special_effect_value: int = 0 ## 百分比或固定值，由 effect_type 解释。
@export var special_effect_duration: int = 0
@export_multiline var special_effect_description: String = ""

# Runtime-only values on a physical weapon, never written to a .tres template.
var forge_rank: int = 0
var forge_affixes: Array[String] = []

## 武功加成（v1 新增）—— 装备可增强特定门派/特定技能的效果
@export var skill_bonus_school: String = ""  ## 增强哪个门派（如 "huashan"），"" = 不增强
@export var skill_bonus_scaling: int = 0     ## 对应门派招式 attack_scaling 百分点加值
@export var skill_bonus_power: int = 0       ## v1 兼容字段；新资源使用 skill_bonus_scaling
@export var skill_bonus_crit_mult: float = 0.0  ## 暴击倍率加成（如 0.3 表示 crit 从 1.5x → 1.8x）


func _init() -> void:
	category = Category.EQUIPMENT
	stackable = false
	max_stack = 1
	usable_in_battle = false
	usable_in_field = false


func get_strength_bonus() -> int:
	## atk_bonus 是最终攻击加成，不得再当作筋骨乘二。
	return str_bonus


func get_agility_bonus() -> int:
	return agi_bonus


func get_inner_power_bonus() -> int:
	return inner_bonus


func get_insight_bonus() -> int:
	return insight_bonus


func get_vitality_bonus() -> int:
	return vitality_bonus


func get_inner_pool_bonus() -> int:
	return inner_pool_bonus


func get_guard_bonus() -> int:
	return guard_bonus


func get_crit_chance_bonus() -> float:
	return crit_chance_bonus


func get_hit_chance_bonus() -> float:
	return hit_chance_bonus


func get_weapon_skill_scaling_bonus() -> int:
	return weapon_skill_bonus_scaling


func get_martial_style() -> StringName:
	## 武器沿用 weapon_type；拳套、指虎、手甲等可用 martial_style 强化掌法。
	return martial_style if martial_style != &"" else weapon_type


static func normalize_weapon_type(value: StringName) -> StringName:
	## 短刃按剑类使用；斧按刀类使用。暗器仍保留独立类别。
	match value:
		&"dagger", &"short_blade", &"short_sword": return &"sword"
		&"axe", &"dao": return &"blade"
		&"ring", &"throwing": return &"hidden"
	return value


func get_skill_scaling_bonus() -> int:
	return skill_bonus_scaling if skill_bonus_scaling != 0 else skill_bonus_power


func get_attack_bonus() -> int:
	## 最终攻击字段只返回字面加成；筋骨/内劲由有效攻击公式各结算一次。
	return atk_bonus


func get_defense_bonus() -> int:
	## 兼容旧战斗字段 defense
	return def_bonus + guard_bonus + int(round(float(str_bonus) / 2.0))


func get_speed_bonus() -> int:
	## 兼容旧战斗字段 speed
	return speed_bonus + agi_bonus
