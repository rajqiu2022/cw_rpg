class_name Equipment
extends Item

## 装备。继承自 Item，多了"穿戴槽位"和"属性加成"。
## 即穿即生效；MVP 不做强化/附魔/套装。
## v1：新增七项核心属性加成，并保留旧字段兼容已有 .tres 数据。

enum Slot { WEAPON, HEAD, ARMOR, HANDS, SHOES, ACCESSORY }

@export var slot: Slot = Slot.WEAPON

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

## 武功加成（v1 新增）—— 装备可增强特定门派/特定技能的效果
@export var skill_bonus_school: String = ""  ## 增强哪个门派（如 "huashan"），"" = 不增强
@export var skill_bonus_power: int = 0       ## power 加值
@export var skill_bonus_crit_mult: float = 0.0  ## 暴击倍率加成（如 0.3 表示 crit 从 1.5x → 1.8x）


func _init() -> void:
	category = Category.EQUIPMENT
	stackable = false
	max_stack = 1
	usable_in_battle = false
	usable_in_field = false


func get_strength_bonus() -> int:
	return str_bonus + atk_bonus


func get_agility_bonus() -> int:
	return agi_bonus + speed_bonus


func get_inner_power_bonus() -> int:
	return inner_bonus


func get_insight_bonus() -> int:
	return insight_bonus


func get_vitality_bonus() -> int:
	## 旧 hp_bonus 折算到生命属性（近似）
	return vitality_bonus + int(round(float(hp_bonus) / 8.0))


func get_inner_pool_bonus() -> int:
	## 旧 mp_bonus 折算到内力属性（近似）
	return inner_pool_bonus + int(round(float(mp_bonus) / 6.0))


func get_guard_bonus() -> int:
	return guard_bonus + def_bonus


func get_attack_bonus() -> int:
	## 兼容旧战斗字段 attack
	return atk_bonus + str_bonus * 2 + int(round(float(inner_bonus) / 2.0))


func get_defense_bonus() -> int:
	## 兼容旧战斗字段 defense
	return def_bonus + guard_bonus + int(round(float(str_bonus) / 2.0))


func get_speed_bonus() -> int:
	## 兼容旧战斗字段 speed
	return speed_bonus + agi_bonus + int(round(float(insight_bonus) / 2.0))
