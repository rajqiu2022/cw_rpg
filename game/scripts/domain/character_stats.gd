class_name CharacterStats
extends Resource

## 角色面板。纯数据，不含战斗逻辑。
## v1：新增七项核心属性，旧 attack/defense/speed 作为兼容派生字段保留。

@export var character_id: String = ""
@export var display_name: String = ""
@export var portrait_path: String = ""

@export var level: int = 1
@export var exp: int = 0

## 七项核心属性（玩家面板主显示）
@export var strength: int = 8      ## 筋骨
@export var agility: int = 7       ## 机敏
@export var inner_power: int = 8   ## 内劲
@export var insight: int = 6       ## 悟性
@export var vitality: int = 8      ## 生命
@export var inner_pool: int = 8    ## 内力
@export var guard: int = 7         ## 防御

@export var max_hp: int = 100
@export var hp: int = 100
@export var max_mp: int = 30
@export var mp: int = 30

## 兼容字段：战斗系统当前仍有部分逻辑直接使用
@export var attack: int = 10
@export var defense: int = 5
@export var speed: int = 10

@export var skills: Array[StringName] = []

func is_dead() -> bool:
	return hp <= 0

func take_damage(amount: int) -> int:
	## 简化伤害公式：扣血并返回实际伤害值。后续可抽象成 BattleFormula。
	var dealt: int = max(1, amount - defense / 2)
	hp = max(0, hp - dealt)
	return dealt

func heal(amount: int) -> void:
	hp = min(max_hp, hp + amount)

func gain_exp(amount: int) -> bool:
	## 返回 true 表示升级。极简 100 * level 公式占位。
	exp += amount
	var threshold: int = level * 100
	if exp >= threshold:
		level += 1
		exp -= threshold
		_apply_levelup()
		return true
	return false

func refresh_derived_stats(refill: bool = false) -> void:
	max_hp = _calc_max_hp()
	max_mp = _calc_max_mp()
	attack = _calc_attack()
	defense = _calc_defense()
	speed = _calc_speed()
	if refill:
		hp = max_hp
		mp = max_mp
	else:
		hp = clamp(hp, 0, max_hp)
		mp = clamp(mp, 0, max_mp)

func has_core_attributes() -> bool:
	return strength > 0 and agility > 0 and inner_power > 0 and insight > 0 and vitality > 0 and inner_pool > 0 and guard > 0

func infer_core_attributes_from_legacy() -> void:
	## 老存档兼容：把旧三维/血蓝估算回七属性，不改现有战斗数值。
	strength = max(1, int(round(float(attack) / 2.0)))
	guard = max(1, defense)
	agility = max(1, speed - 2)
	inner_power = max(1, int(round(float(attack) / 4.0)))
	insight = max(1, int(round(float(agility) / 2.0)) + 3)
	vitality = max(1, int(round(float(max_hp - 60) / 7.0)))
	inner_pool = max(1, int(round(float(max_mp - 12) / 3.0)))

func _apply_levelup() -> void:
	strength += 1
	agility += 1
	inner_power += 1
	insight += 1
	vitality += 2
	inner_pool += 2
	guard += 1
	refresh_derived_stats(true)

func _calc_max_hp() -> int:
	return 60 + vitality * 5 + strength * 2

func _calc_max_mp() -> int:
	return 12 + inner_pool * 2 + inner_power + int(round(float(insight) / 2.0))

func _calc_attack() -> int:
	return max(1, strength * 2 + int(round(float(inner_power) / 2.0)))

func _calc_defense() -> int:
	return max(1, guard + int(round(float(strength) / 2.0)))

func _calc_speed() -> int:
	return max(1, agility + int(round(float(insight) / 2.0)) + 2)

