extends Control

signal closed

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ATTR_ICON_ATLAS_PATH := "res://art/ui/cold_wuxia/v1/ui_cold_wuxia_attribute_icons_v1.png"
const ATTR_ICON_REGIONS := {
	"筋骨": Rect2(37, 55, 203, 204),
	"机敏": Rect2(290, 55, 201, 204),
	"内劲": Rect2(544, 55, 200, 204),
	"悟性": Rect2(794, 55, 195, 203),
	"生命": Rect2(1033, 55, 197, 204),
	"内力": Rect2(1281, 55, 196, 204),
	"防御": Rect2(38, 293, 202, 207),
}

@onready var stats_label: Label = %StatsLabel
@onready var slot_list: VBoxContainer = %SlotList
@onready var close_btn: Button = %CloseBtn

var _attr_icon_atlas: Texture2D = null
var _category_bar: VBoxContainer = null
var _detail_label: RichTextLabel = null
var _content_root: HBoxContainer = null
var _current_filter: String = "all"
var _selected_item: Item = null
var _selected_count: int = 0


func _ready() -> void:
	if ResourceLoader.exists(ATTR_ICON_ATLAS_PATH):
		_attr_icon_atlas = load(ATTR_ICON_ATLAS_PATH)
	_build_formal_layout()
	_apply_visual_style()
	close_btn.pressed.connect(close)
	Inventory.slots_changed.connect(_refresh)
	GameState.player_changed.connect(_refresh)
	_refresh()


func _build_formal_layout() -> void:
	var body: VBoxContainer = get_node_or_null("Panel/Body") as VBoxContainer
	if body == null or body.get_node_or_null("InventoryShowcase") != null:
		return

	var old_scroll: Control = get_node_or_null("Panel/Body/Scroll") as Control
	if old_scroll != null:
		old_scroll.visible = false
	if stats_label != null:
		stats_label.visible = false

	_content_root = HBoxContainer.new()
	_content_root.name = "InventoryShowcase"
	_content_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_root.add_theme_constant_override("separation", 16)
	body.add_child(_content_root)

	var side_panel := PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(230, 0)
	side_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.020, 0.034, 0.046, 0.92), UI_THEME.BLUE_STEEL, 14, 2))
	_content_root.add_child(side_panel)

	var side_box := VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 12)
	side_panel.add_child(side_box)

	var stat_title := Label.new()
	stat_title.text = "冷孤云"
	UI_THEME.style_label(stat_title, 22, UI_THEME.GOLD_LIGHT)
	side_box.add_child(stat_title)

	stats_label.visible = true
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_box.add_child(stats_label)

	var filter_title := Label.new()
	filter_title.text = "物品分类"
	UI_THEME.style_label(filter_title, 18, UI_THEME.JADE, false)
	side_box.add_child(filter_title)

	_category_bar = VBoxContainer.new()
	_category_bar.add_theme_constant_override("separation", 8)
	side_box.add_child(_category_bar)
	_add_filter_button("全部", "all")
	_add_filter_button("消耗", "consumable")
	_add_filter_button("装备", "equipment")
	_add_filter_button("剧情", "key")
	_add_filter_button("材料", "material")

	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(520, 0)
	list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.018, 0.030, 0.040, 0.82), Color(0.16, 0.30, 0.38, 0.88), 14, 1))
	_content_root.add_child(list_panel)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_panel.add_child(scroll)

	slot_list = VBoxContainer.new()
	slot_list.add_theme_constant_override("separation", 10)
	slot_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(slot_list)

	var detail_panel := PanelContainer.new()
	detail_panel.custom_minimum_size = Vector2(330, 0)
	detail_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.022, 0.038, 0.050, 0.92), Color(0.20, 0.52, 0.48, 0.94), 14, 2))
	_content_root.add_child(detail_panel)

	_detail_label = RichTextLabel.new()
	_detail_label.bbcode_enabled = true
	_detail_label.fit_content = false
	_detail_label.scroll_active = false
	UI_THEME.style_rich_text(_detail_label, 18)
	detail_panel.add_child(_detail_label)


func _add_filter_button(label: String, filter_key: String) -> void:
	if _category_bar == null:
		return
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(0, 42)
	UI_THEME.style_button(btn, 16, UI_THEME.JADE if filter_key == _current_filter else UI_THEME.BLUE_STEEL)
	btn.pressed.connect(func(): _set_filter(filter_key))
	_category_bar.add_child(btn)


func _set_filter(filter_key: String) -> void:
	_current_filter = filter_key
	_refresh()


func _apply_visual_style() -> void:
	var dim: ColorRect = get_node_or_null("Dim") as ColorRect
	if dim != null:
		dim.color = Color(0.004, 0.010, 0.016, 0.74)
	var panel: PanelContainer = get_node_or_null("Panel") as PanelContainer
	if panel != null:
		panel.offset_left = -650
		panel.offset_top = -360
		panel.offset_right = 650
		panel.offset_bottom = 360
		panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.020, 0.034, 0.046, 0.98), UI_THEME.BLUE_STEEL, 18, 3))
	var title: Label = get_node_or_null("Panel/Body/Header/Title") as Label
	if title != null:
		title.text = "行囊"
		UI_THEME.style_label(title, 34, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_button(close_btn, 16, UI_THEME.CRIMSON)
	UI_THEME.style_label(stats_label, 16, UI_THEME.TEXT, false)


func open() -> void:
	visible = true
	_refresh()
	close_btn.grab_focus()


func close() -> void:
	visible = false
	emit_signal("closed")


func _refresh() -> void:
	_update_stats_text()
	_refresh_filter_buttons()
	for c in slot_list.get_children():
		c.queue_free()

	var shown_items: Array[Dictionary] = []
	for s in Inventory.slots:
		var item: Item = s.get("item")
		var count: int = int(s.get("count", 0))
		if item == null or count <= 0:
			continue
		if not _passes_filter(item):
			continue
		shown_items.append({"item": item, "count": count})

	if shown_items.is_empty():
		var empty := Label.new()
		empty.text = "此类行囊空空如也"
		UI_THEME.style_label(empty, 18, UI_THEME.MUTED, false)
		slot_list.add_child(empty)
		_show_empty_detail()
		return

	for entry in shown_items:
		var item: Item = entry.get("item")
		var count: int = int(entry.get("count", 0))
		slot_list.add_child(_make_slot_row(item, count))

	if _selected_item == null or not _passes_filter(_selected_item):
		var first: Dictionary = shown_items[0]
		_show_item_detail(first.get("item"), int(first.get("count", 0)))
	else:
		_show_item_detail(_selected_item, _selected_count)


func _update_stats_text() -> void:
	var player: CharacterStats = GameState.player
	if player != null:
		stats_label.text = "Lv.%d\n生命  %d / %d\n内力  %d / %d\n金钱  %d" % [
			player.level,
			player.hp,
			player.max_hp,
			player.mp,
			player.max_mp,
			GameState.gold,
		]


func _refresh_filter_buttons() -> void:
	if _category_bar == null:
		return
	for c in _category_bar.get_children():
		var btn: Button = c as Button
		if btn == null:
			continue
		var is_active: bool = false
		match btn.text:
			"全部": is_active = _current_filter == "all"
			"消耗": is_active = _current_filter == "consumable"
			"装备": is_active = _current_filter == "equipment"
			"剧情": is_active = _current_filter == "key"
			"材料": is_active = _current_filter == "material"
		UI_THEME.style_button(btn, 16, UI_THEME.JADE if is_active else UI_THEME.BLUE_STEEL)


func _passes_filter(item: Item) -> bool:
	match _current_filter:
		"consumable": return item.category == Item.Category.CONSUMABLE
		"equipment": return item is Equipment
		"key": return item.is_key_item()
		"material": return item.category == Item.Category.MATERIAL
		_: return true


func _make_slot_row(item: Item, count: int) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0, 82)
	row_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.040, 0.064, 0.078, 0.88), Color(0.18, 0.34, 0.40, 0.86), 12, 1))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row_panel.add_child(row)

	var icon := _make_item_icon(_icon_key_for_item(item))
	if icon != null:
		row.add_child(icon)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_box)

	var name_lbl := Label.new()
	name_lbl.text = "%s ×%d" % [item.display_name, count]
	UI_THEME.style_label(name_lbl, 19, UI_THEME.GOLD_LIGHT, false)
	text_box.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = "%s  ·  %s" % [_category_text(item), item.description]
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_THEME.style_label(desc_lbl, 14, Color(0.68, 0.82, 0.84, 1.0), false)
	text_box.add_child(desc_lbl)

	var detail_btn := Button.new()
	detail_btn.text = "详情"
	detail_btn.custom_minimum_size = Vector2(78, 42)
	UI_THEME.style_button(detail_btn, 15, UI_THEME.BLUE_STEEL)
	detail_btn.pressed.connect(func(): _show_item_detail(item, count))
	row.add_child(detail_btn)

	if item is Equipment:
		var eq: Equipment = item
		var btn := Button.new()
		var already_equipped: bool = Inventory.get_equipped_id(eq.slot) == eq.item_id
		if already_equipped:
			btn.text = "已装备"
		else:
			btn.text = "装备"
		btn.disabled = already_equipped

		btn.custom_minimum_size = Vector2(92, 42)
		UI_THEME.style_button(btn, 16, UI_THEME.JADE)
		btn.pressed.connect(func(): _on_equip(eq.item_id))
		row.add_child(btn)
	elif item.category == Item.Category.CONSUMABLE and item.can_use(false):
		var btn := Button.new()
		btn.text = "使用"
		btn.disabled = not _would_item_have_effect(item)
		btn.custom_minimum_size = Vector2(92, 42)
		UI_THEME.style_button(btn, 16, UI_THEME.JADE)
		btn.pressed.connect(func(): _on_use(item.item_id))
		row.add_child(btn)
	else:
		var tag := Label.new()
		if item.is_key_item():
			tag.text = "剧情"
		else:
			tag.text = "不可用"
		tag.custom_minimum_size = Vector2(92, 42)

		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UI_THEME.style_label(tag, 15, UI_THEME.MUTED, false)
		row.add_child(tag)

	return row_panel


func _show_item_detail(item: Item, count: int) -> void:
	if item == null or _detail_label == null:
		return
	_selected_item = item
	_selected_count = count
	var extra: String = ""
	if item is Equipment:
		extra = "\n[b]装备槽[/b]：%s\n[b]属性[/b]：%s" % [Inventory.slot_display_name((item as Equipment).slot), _bonus_text(item as Equipment)]
	elif item.category == Item.Category.CONSUMABLE:
		extra = "\n[b]效果[/b]：生命 +%d / 内力 +%d" % [item.heal_hp, item.heal_mp]
	_detail_label.text = "[b]%s[/b]\n[color=#8eb8ca]%s ×%d[/color]\n\n%s%s\n\n[b]价格[/b]\n买入 %d · 卖出 %d" % [
		item.display_name,
		_category_text(item),
		count,
		item.description,
		extra,
		item.buy_price,
		item.sell_price,
	]


func _show_empty_detail() -> void:
	_selected_item = null
	_selected_count = 0
	if _detail_label != null:
		_detail_label.text = "[b]行囊[/b]\n当前分类没有物品。"


func _category_text(item: Item) -> String:
	if item is Equipment:
		return "装备"
	match item.category:
		Item.Category.CONSUMABLE: return "消耗"
		Item.Category.MATERIAL: return "材料"
		Item.Category.KEY_ITEM: return "剧情"
		_: return "物品"


func _bonus_text(eq: Equipment) -> String:
	var parts: Array[String] = []
	if eq.get_strength_bonus() != 0: parts.append("筋骨 %+d" % eq.get_strength_bonus())
	if eq.get_agility_bonus() != 0: parts.append("机敏 %+d" % eq.get_agility_bonus())
	if eq.get_inner_power_bonus() != 0: parts.append("内劲 %+d" % eq.get_inner_power_bonus())
	if eq.get_insight_bonus() != 0: parts.append("悟性 %+d" % eq.get_insight_bonus())
	if eq.get_vitality_bonus() != 0: parts.append("生命 %+d" % eq.get_vitality_bonus())
	if eq.get_inner_pool_bonus() != 0: parts.append("内力 %+d" % eq.get_inner_pool_bonus())
	if eq.get_guard_bonus() != 0: parts.append("防御 %+d" % eq.get_guard_bonus())
	return " / ".join(parts) if not parts.is_empty() else "无属性加成"


func _icon_key_for_item(item: Item) -> String:
	if item is Equipment:
		return "防御"
	if item.is_key_item():
		return "悟性"
	if item.category == Item.Category.MATERIAL:
		return "内力"
	if item.category == Item.Category.CONSUMABLE:
		if item.heal_hp > 0:
			return "生命"
		if item.heal_mp > 0:
			return "内劲"
		return "机敏"
	return "筋骨"


func _make_item_icon(icon_key: String) -> TextureRect:
	if _attr_icon_atlas == null:
		return null
	var region: Rect2 = ATTR_ICON_REGIONS.get(icon_key, Rect2())
	if region.size.x <= 0 or region.size.y <= 0:
		return null
	var tex := AtlasTexture.new()
	tex.atlas = _attr_icon_atlas
	tex.region = region
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(46, 46)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = tex
	icon.tooltip_text = icon_key
	return icon


func _would_item_have_effect(item: Item) -> bool:
	var player: CharacterStats = GameState.player
	if player == null:
		return false
	if item.heal_hp > 0 and player.hp < player.max_hp:
		return true
	if item.heal_mp > 0 and player.mp < player.max_mp:
		return true
	return false


func _on_use(item_id: StringName) -> void:
	if Inventory.use_item(item_id):
		print("[InventoryUI] used: %s" % item_id)
	_refresh()


func _on_equip(item_id: StringName) -> void:
	if Inventory.equip(item_id):
		print("[InventoryUI] equipped: %s" % item_id)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
