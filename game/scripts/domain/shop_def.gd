class_name ShopDef
extends Resource

## 商店定义。固定库存 + 固定价格（MVP）。
## 物品 buy_price/sell_price 默认走 Item 自身字段；这里只列"卖什么"。

@export var shop_id: StringName = ""
@export var display_name: String = "无名商铺"
@export var greeting: String = "客官，看看？"

## 在售物品 id 列表，引用 res://data/items/<id>.tres
@export var stock: Array[StringName] = []

## 玩家卖物折扣（0.5 = 半价回收）
@export var sell_back_ratio: float = 0.5
