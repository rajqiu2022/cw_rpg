class_name Item
extends Resource

## 物品基类。所有"能进背包"的东西都从这里继承。
## Equipment 继承 Item，统一字段简化背包栏渲染。

enum Category {
	CONSUMABLE,   ## 消耗品（药、丹）
	MATERIAL,     ## 材料（暂不用）
	KEY_ITEM,     ## 剧情物品（地图/信物，不可丢弃）
	EQUIPMENT,    ## 装备（实际类型由 Equipment 子类覆写 category）
}

@export var item_id: StringName = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon_path: String = ""

@export var category: Category = Category.CONSUMABLE
@export var stackable: bool = true
@export var max_stack: int = 99

@export var sell_price: int = 0
@export var buy_price: int = 0

@export var usable_in_battle: bool = false
@export var usable_in_field: bool = true

## 消耗品效果（简化为统一字段，进阶时再做 effect 列表）
@export var heal_hp: int = 0
@export var heal_mp: int = 0


func is_key_item() -> bool:
	return category == Category.KEY_ITEM


func can_use(in_battle: bool) -> bool:
	if category != Category.CONSUMABLE:
		return false
	return usable_in_battle if in_battle else usable_in_field
