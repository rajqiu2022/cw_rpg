class_name ItemDetailTip
extends PanelContainer

## 背包、任务奖励等界面共用的物品详情浮层。

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const PANEL_TEXTURE := preload("res://art/ui/quest/detail_panel_v2.png")
const QUALITY_COLORS := {
	Item.Quality.COMMON: "#c0c8d0",
	Item.Quality.UNCOMMON: "#65d58a",
	Item.Quality.RARE: "#67b7ff",
	Item.Quality.EPIC: "#b56cff",
	Item.Quality.LEGENDARY: "#f0a43a",
}

var _text: RichTextLabel


func _ready() -> void:
	custom_minimum_size = Vector2(410, 176)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 80
	var style := StyleBoxTexture.new()
	style.texture = PANEL_TEXTURE
	style.texture_margin_left = 28
	style.texture_margin_right = 28
	style.texture_margin_top = 28
	style.texture_margin_bottom = 28
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	add_theme_stylebox_override("panel", style)

	_text = RichTextLabel.new()
	_text.name = "ItemDetailText"
	_text.bbcode_enabled = true
	_text.fit_content = false
	_text.scroll_active = false
	_text.custom_minimum_size = Vector2(360, 126)
	_text.add_theme_font_size_override("normal_font_size", 15)
	_text.add_theme_color_override("default_color", UI_THEME.TEXT)
	_text.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	add_child(_text)
	visible = false


func show_item(item: Item, count: int = 1) -> void:
	if item == null:
		visible = false
		return
	var color: String = QUALITY_COLORS.get(item.quality, "#c0c8d0")
	var lines: Array[String] = [
		"[font_size=20][color=%s]%s[/color][/font_size]" % [color, item.display_name],
		"[color=#82949c]%s · ×%d[/color]" % [_category_name(item), count],
	]
	if item is Equipment:
		var stats := _equipment_stat_lines(item as Equipment)
		if not stats.is_empty():
			lines.append("[color=#72d2a6]%s[/color]" % "\n".join(stats))
	elif item.category == Item.Category.CONSUMABLE:
		var effects: Array[String] = []
		if item.heal_hp > 0:
			effects.append("恢复生命 %d" % item.heal_hp)
		if item.heal_mp > 0:
			effects.append("恢复内力 %d" % item.heal_mp)
		if not effects.is_empty():
			lines.append("[color=#72d2a6]%s[/color]" % " · ".join(effects))
	if not item.description.strip_edges().is_empty():
		lines.append(item.description)
	_text.text = "\n".join(lines)
	visible = true
	move_to_front()


func hide_tip() -> void:
	visible = false


func _category_name(item: Item) -> String:
	if item is Equipment:
		return "装备"
	match item.category:
		Item.Category.CONSUMABLE: return "消耗品"
		Item.Category.KEY_ITEM: return "剧情物品"
		Item.Category.MATERIAL: return "材料"
	return "物品"


func _equipment_stat_lines(equipment: Equipment) -> Array[String]:
	var stats: Array[String] = []
	_append_stat(stats, "攻击", equipment.atk_bonus)
	_append_stat(stats, "防御", equipment.def_bonus)
	_append_stat(stats, "守御", equipment.get_guard_bonus())
	_append_stat(stats, "速度", equipment.speed_bonus)
	_append_stat(stats, "筋骨", equipment.get_strength_bonus())
	_append_stat(stats, "机敏", equipment.get_agility_bonus())
	_append_stat(stats, "内劲", equipment.get_inner_power_bonus())
	_append_stat(stats, "悟性", equipment.get_insight_bonus())
	_append_stat(stats, "生命", equipment.get_vitality_bonus())
	_append_stat(stats, "内力", equipment.get_inner_pool_bonus())
	if equipment.get_crit_chance_bonus() != 0.0:
		stats.append("暴击率 %+d%%" % int(round(equipment.get_crit_chance_bonus() * 100.0)))
	if equipment.get_weapon_skill_scaling_bonus() != 0:
		stats.append("兵器招式系数 %+d%%" % equipment.get_weapon_skill_scaling_bonus())
	return stats


func _append_stat(lines: Array[String], label: String, value: int) -> void:
	if value != 0:
		lines.append("%s %+d" % [label, value])
