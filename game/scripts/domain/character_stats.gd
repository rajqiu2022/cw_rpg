class_name CharacterStats
extends Resource

## 角色面板。纯数据，不含战斗逻辑。

@export var character_id: String = ""
@export var display_name: String = ""
@export var portrait_path: String = ""

@export var level: int = 1
@export var exp: int = 0

@export var max_hp: int = 100
@export var hp: int = 100
@export var max_mp: int = 30
@export var mp: int = 30

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

func _apply_levelup() -> void:
	max_hp += 10
	hp = max_hp
	max_mp += 3
	mp = max_mp
	attack += 2
	defense += 1
	speed += 1
