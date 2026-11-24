extends RefCounted
## Native 茗雾 only; these are physical feet, not the old painted-background UVs.

static func rows(size: Vector2, terrain: Node) -> Array[Dictionary]:
	return [
		_spot("ch7_tea_basket_start", "查看歇脚棚退货单", Vector2(2290,2635), size, terrain, "", "ch7_dual_route_chosen", "ch7_tea_basket_accepted"),
		_spot("ch7_tea_basket_tag", "查看北侧茶架下的旧秤签", Vector2(1210,1525), size, terrain, "q_ch7_side_05_tea_basket", "", "ch7_tea_basket_tag_seen"),
		_spot("ch7_tea_basket_rope", "查看水边货篓的旧绳", Vector2(2430,1540), size, terrain, "q_ch7_side_05_tea_basket", "ch7_tea_basket_tag_seen", "ch7_tea_basket_rope_seen"),
		_spot("ch7_tea_basket_report", "在退货单上填写复秤意见", Vector2(2290,2635), size, terrain, "q_ch7_side_05_tea_basket", "ch7_tea_basket_rope_seen", "ch7_tea_basket_verified"),
	]

static func _spot(id: String, label: String, foot: Vector2, size: Vector2, terrain: Node, quest: String, require: String, hide: String) -> Dictionary:
	return {"id":id,"pos":foot/size,"size":Vector2(118,94)/size,"label":label,
		"action":"dialog:"+id,"activation":"interact","visual_baked":true,"sect_floor":terrain.level_at(foot),
		"require_quest_active":quest,"require_flag":require,"hide_flag":hide}
