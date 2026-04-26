class_name Equipment
extends Item

## 装备。继承自 Item，多了"穿戴槽位"和"属性加成"。
## 即穿即生效；MVP 不做强化/附魔/套装。

enum Slot { WEAPON, ARMOR }

@export var slot: Slot = Slot.WEAPON
@export var atk_bonus: int = 0
@export var def_bonus: int = 0
@export var hp_bonus: int = 0
@export var mp_bonus: int = 0
@export var speed_bonus: int = 0


func _init() -> void:
	category = Category.EQUIPMENT
	stackable = false
	max_stack = 1
	usable_in_battle = false
	usable_in_field = false
