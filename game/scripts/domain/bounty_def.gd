class_name BountyDef
extends Resource

## 可重复追捕委托的数据契约。位置只在接榜后公开并生成目标 NPC。

@export var bounty_id: StringName = &""
@export var display_name: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var board_city: StringName = &""
@export var recommended_min_level: int = 1
@export var recommended_max_level: int = 3
@export var enemy_ids: Array[StringName] = []
@export var locations: Array[Dictionary] = []
@export var reward_reputation: int = 5
@export var reward_training: int = 10
@export var reward_exp: int = 20
@export var reward_gold: int = 0
@export var reward_items: Array[Dictionary] = []
@export var field_sprite_path: String = ""
@export var field_sprite_scale: float = 0.86


func reward_summary() -> String:
	var parts: PackedStringArray = [
		"声望 +%d" % reward_reputation,
		"历练 +%d" % reward_training,
		"经验 +%d" % reward_exp,
	]
	if reward_gold > 0:
		parts.append("金钱 +%d" % reward_gold)
	for reward: Dictionary in reward_items:
		var item_id := StringName(reward.get("item_id", &""))
		var item: Item = null
		for directory: String in ["res://data/items/", "res://data/equipment/"]:
			var path := "%s%s.tres" % [directory, String(item_id)]
			if ResourceLoader.exists(path):
				item = load(path) as Item
				break
		var item_name := item.display_name if item != null else String(item_id)
		parts.append("%s ×%d" % [item_name, maxi(1, int(reward.get("count", 1)))])
	return "　".join(parts)
