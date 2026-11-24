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

enum Quality {
	COMMON,       ## 白品
	UNCOMMON,     ## 绿品
	RARE,         ## 蓝品
	EPIC,         ## 紫品
	LEGENDARY,    ## 橙品
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

## 书籍、信件、残页和卷宗可在背包中打开独立阅读界面。
## 阅读不会消耗物品，也不承担任务状态；线索是否取得仍由物品本身和场景旗标决定。
@export var readable: bool = false
@export var read_title: String = ""
@export_multiline var read_content: String = ""
@export var read_source: String = ""
## Optional manual study target.  Reading is always allowed; learning remains
## gated by the Skill's insight requirement and never consumes the book.
@export var study_skill_id: StringName = &""
@export var study_requires_item: StringName = &""

@export var quality: Quality = Quality.COMMON

## 珍贵成长型消耗品：永久增加基础属性或生命/内力上限。
## 角色界面仅对紫/橙品质且该字段为 true 的物品进行二次确认。
@export var permanent_growth: bool = false

## 消耗品效果（简化为统一字段，进阶时再做 effect 列表）
@export var heal_hp: int = 0
@export var heal_mp: int = 0


func is_key_item() -> bool:
	return category == Category.KEY_ITEM


func is_readable() -> bool:
	return readable and not read_content.strip_edges().is_empty()


func can_use(in_battle: bool) -> bool:
	if category != Category.CONSUMABLE:
		return false
	return usable_in_battle if in_battle else usable_in_field
