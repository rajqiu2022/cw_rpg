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

@onready var slot_list: VBoxContainer = %SlotList
@onready var close_btn: Button = %CloseBtn

var _slot_grid: GridContainer = null
var _stats_label: RichTextLabel = null
var _detail_label: RichTextLabel = null
var _available_box: VBoxContainer = null
var _attr_icon_strip: HBoxContainer = null
var _unequip_btn: Button = null
var _selected_slot: int = Equipment.Slot.WEAPON
var _slot_buttons: Dictionary = {}


func _ready() -> void:
	_build_formal_layout()
	_apply_visual_style()
	close_btn.pressed.connect(close)
	Inventory.equipped_changed.connect(func(_slot: int, _item: Equipment): _refresh())
	Inventory.slots_changed.connect(_refresh)
	if GameState.has_signal("player_changed"):
		GameState.player_changed.connect(_refresh)
	_refresh()


func _build_formal_layout() -> void:
	var body: VBoxContainer = get_node_or_null("Panel/Body") as VBoxContainer
	if body == null:
		return
	var old_hint: Control = get_node_or_null("Panel/Body/Hint") as Control
	var old_scroll: Control = get_node_or_null("Panel/Body/Scroll") as Control
	if old_hint != null:
		old_hint.visible = false
	if old_scroll != null:
		old_scroll.visible = false
	if body.get_node_or_null("FormalEquipmentLayout") != null:
		return

	var layout := HBoxContainer.new()
	layout.name = "FormalEquipmentLayout"
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 18)
	body.add_child(layout)

	var left_panel := _make_panel(Vector2(300, 500), Color(0.042, 0.064, 0.078, 0.94), UI_THEME.BLUE_STEEL)
	layout.add_child(left_panel)
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 12)
	left_panel.add_child(left_box)

	var role_title := Label.new()
	role_title.text = "冷孤云"
	role_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_THEME.style_label(role_title, 28, UI_THEME.GOLD_LIGHT)
	left_box.add_child(role_title)

	var figure := PanelContainer.new()
	figure.custom_minimum_size = Vector2(0, 260)
	figure.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.055, 0.090, 0.095, 0.72), UI_THEME.JADE, 16, 2))
	left_box.add_child(figure)
	var figure_label := Label.new()
	figure_label.text = "侠客立身\n\n玄衣 · 冷锋 · 孤云"
	figure_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	figure_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_THEME.style_label(figure_label, 22, Color(0.72, 0.88, 0.90, 1.0))
	figure.add_child(figure_label)

	_attr_icon_strip = HBoxContainer.new()
	_attr_icon_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	_attr_icon_strip.add_theme_constant_override("separation", 6)
	left_box.add_child(_attr_icon_strip)
	_build_attr_icon_strip()

	_stats_label = RichTextLabel.new()
	_stats_label.bbcode_enabled = true
	_stats_label.fit_content = false
	_stats_label.custom_minimum_size = Vector2(0, 150)
	_stats_label.scroll_active = false
	UI_THEME.style_rich_text(_stats_label, 15)
	left_box.add_child(_stats_label)

	var center_panel := _make_panel(Vector2(390, 500), Color(0.035, 0.056, 0.072, 0.96), UI_THEME.GOLD)
	layout.add_child(center_panel)
	var center_box := VBoxContainer.new()
	center_box.add_theme_constant_override("separation", 14)
	center_panel.add_child(center_box)

	var slot_title := Label.new()
	slot_title.text = "六槽武备"
	slot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_THEME.style_label(slot_title, 26, UI_THEME.GOLD_LIGHT)
	center_box.add_child(slot_title)

	_slot_grid = GridContainer.new()
	_slot_grid.columns = 2
	_slot_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_slot_grid.add_theme_constant_override("h_separation", 12)
	_slot_grid.add_theme_constant_override("v_separation", 12)
	center_box.add_child(_slot_grid)

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_CENTER
	action_row.add_theme_constant_override("separation", 12)
	center_box.add_child(action_row)
	_unequip_btn = Button.new()
	_unequip_btn.text = "卸下当前槽"
	_unequip_btn.custom_minimum_size = Vector2(150, 44)
	UI_THEME.style_button(_unequip_btn, 16, UI_THEME.CRIMSON)
	_unequip_btn.pressed.connect(_unequip_selected)
	action_row.add_child(_unequip_btn)

	var right_panel := _make_panel(Vector2(390, 500), Color(0.048, 0.068, 0.078, 0.96), UI_THEME.JADE)
	layout.add_child(right_panel)
	var right_box := VBoxContainer.new()
	right_box.add_theme_constant_override("separation", 12)
	right_panel.add_child(right_box)

	var detail_title := Label.new()
	detail_title.text = "装备详情"
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI_THEME.style_label(detail_title, 26, UI_THEME.GOLD_LIGHT)
	right_box.add_child(detail_title)

	_detail_label = RichTextLabel.new()
	_detail_label.bbcode_enabled = true
	_detail_label.fit_content = false
	_detail_label.custom_minimum_size = Vector2(0, 210)
	_detail_label.scroll_active = false
	UI_THEME.style_rich_text(_detail_label, 16)
	right_box.add_child(_detail_label)

	var available_title := Label.new()
	available_title.text = "可替换装备"
	UI_THEME.style_label(available_title, 18, UI_THEME.JADE)
	right_box.add_child(available_title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_box.add_child(scroll)
	_available_box = VBoxContainer.new()
	_available_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_available_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_available_box)


func _make_panel(min_size: Vector2, bg: Color, border: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", UI_THEME.panel(bg, border, 16, 2))
	return panel


func _apply_visual_style() -> void:
	var dim: ColorRect = get_node_or_null("Dim") as ColorRect
	if dim != null:
		dim.color = Color(0.005, 0.010, 0.016, 0.58)
	var panel: PanelContainer = get_node_or_null("Panel") as PanelContainer
	if panel != null:
		panel.offset_left = -660
		panel.offset_top = -350
		panel.offset_right = 660
		panel.offset_bottom = 350
		panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.040, 0.060, 0.075, 0.98), UI_THEME.GOLD, 18, 3))
	var title: Label = get_node_or_null("Panel/Body/Header/Title") as Label
	if title != null:
		title.text = "武备"
		UI_THEME.style_label(title, 34, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_button(close_btn, 16, UI_THEME.CRIMSON)


func open() -> void:
	visible = true
	_refresh()
	close_btn.grab_focus()


func close() -> void:
	visible = false
	emit_signal("closed")


func _refresh() -> void:
	_build_attr_icon_strip()
	_refresh_slot_grid()
	_refresh_stats()
	_refresh_detail()
	_refresh_available_list()


func _refresh_slot_grid() -> void:
	if _slot_grid == null:
		return
	_slot_buttons.clear()
	for child in _slot_grid.get_children():
		child.queue_free()
	for slot in Inventory.all_slots():
		var card := _make_slot_button(slot)
		_slot_grid.add_child(card)


func _make_slot_button(slot: int) -> Button:
	var eq: Equipment = Inventory.get_equipped(slot)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(170, 118)
	btn.text = _slot_button_text(slot, eq)
	btn.tooltip_text = "查看 %s 槽" % Inventory.slot_display_name(slot)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var accent: Color = UI_THEME.BLUE_STEEL
	if slot == _selected_slot:
		accent = UI_THEME.JADE
	UI_THEME.style_button(btn, 16, accent)

	btn.pressed.connect(func(): _select_slot(slot))
	_slot_buttons[slot] = btn
	return btn


func _slot_button_text(slot: int, eq: Equipment) -> String:
	var slot_name := Inventory.slot_display_name(slot)
	if eq == null:
		return "%s\n空置\n可从行囊穿戴" % slot_name
	return "%s\n%s\n%s" % [slot_name, eq.display_name, _compact_bonus_text(eq)]


func _select_slot(slot: int) -> void:
	_selected_slot = slot
	_refresh()


func _refresh_stats() -> void:
	if _stats_label == null:
		return
	var p: CharacterStats = GameState.player
	if p == null:
		_stats_label.text = "[b]角色属性[/b]\n暂无角色数据"
		return
	_stats_label.text = "[b]角色属性[/b]\nLv.%d  HP %d/%d  MP %d/%d\n攻击 %d  防御 %d  身法 %d\n\n[b]装备总加成[/b]\n筋骨 %+d  机敏 %+d\n内劲 %+d  悟性 %+d\n生命 %+d  内力 %+d  防御 %+d" % [
		p.level, p.hp, p.max_hp, p.mp, p.max_mp,
		p.attack + Inventory.get_atk_bonus(),
		p.defense + Inventory.get_def_bonus(),
		p.speed + Inventory.get_speed_bonus(),
		Inventory.get_strength_bonus(),
		Inventory.get_agility_bonus(),
		Inventory.get_inner_power_bonus(),
		Inventory.get_insight_bonus(),
		Inventory.get_vitality_bonus(),
		Inventory.get_inner_pool_bonus(),
		Inventory.get_guard_bonus(),
	]


func _refresh_detail() -> void:
	if _detail_label == null:
		return
	var slot_name := Inventory.slot_display_name(_selected_slot)
	var eq: Equipment = Inventory.get_equipped(_selected_slot)
	if _unequip_btn != null:
		_unequip_btn.disabled = eq == null
	if eq == null:
		_detail_label.text = "[b]%s[/b]\n\n当前槽位空置。\n\n从右侧可替换装备或背包中选择对应装备即可穿戴。" % slot_name
		return
	_detail_label.text = "[b]%s · %s[/b]\n%s\n\n[b]属性加成[/b]\n%s\n\n[b]说明[/b]\n%s" % [
		slot_name,
		eq.display_name,
		_equipment_quality_line(eq),
		_bonus_text(eq),
		eq.description,
	]


func _refresh_available_list() -> void:
	if _available_box == null:
		return
	for child in _available_box.get_children():
		child.queue_free()
	var added := 0
	for entry in Inventory.slots:
		var item_value: Variant = entry.get("item")
		var eq := item_value as Equipment
		if eq == null or eq.slot != _selected_slot:
			continue
		added += 1
		_available_box.add_child(_make_available_row(eq))
	if added == 0:
		var empty := Label.new()
		empty.text = "行囊中暂无可用于此槽位的装备。"
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UI_THEME.style_label(empty, 15, UI_THEME.MUTED, false)
		_available_box.add_child(empty)


func _make_available_row(eq: Equipment) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.add_theme_stylebox_override("panel", UI_THEME.panel(Color(0.035, 0.055, 0.065, 0.82), Color(0.16, 0.30, 0.28, 0.86), 10, 1))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row_panel.add_child(row)

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "%s\n%s" % [eq.display_name, _compact_bonus_text(eq)]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_THEME.style_label(label, 15, UI_THEME.TEXT, false)
	row.add_child(label)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(78, 38)
	if Inventory.get_equipped(_selected_slot) == eq:
		btn.text = "已穿戴"
		btn.disabled = true
	else:
		btn.text = "穿戴"
	UI_THEME.style_button(btn, 14, UI_THEME.JADE)
	btn.pressed.connect(func(): _equip_item(eq))
	row.add_child(btn)
	return row_panel


func _equip_item(eq: Equipment) -> void:
	if eq == null:
		return
	Inventory.equip(eq.item_id)
	_selected_slot = eq.slot
	_refresh()


func _unequip_selected() -> void:
	Inventory.unequip(_selected_slot)
	_refresh()


func _equipment_quality_line(eq: Equipment) -> String:
	var price_text := "价值 %d / 售价 %d" % [eq.price, eq.sell_price]
	return "类型：装备    槽位：%s    %s" % [Inventory.slot_display_name(eq.slot), price_text]


func _compact_bonus_text(eq: Equipment) -> String:
	var parts: Array[String] = _bonus_parts(eq)
	if parts.is_empty():
		return "无属性加成"
	if parts.size() > 2:
		return "%s / %s 等" % [parts[0], parts[1]]
	return " / ".join(parts)


func _bonus_text(eq: Equipment) -> String:
	var parts: Array[String] = _bonus_parts(eq)
	return "\n".join(parts) if not parts.is_empty() else "无属性加成"


func _bonus_parts(eq: Equipment) -> Array[String]:
	var parts: Array[String] = []
	if eq.get_strength_bonus() != 0:
		parts.append("筋骨 %+d" % eq.get_strength_bonus())
	if eq.get_agility_bonus() != 0:
		parts.append("机敏 %+d" % eq.get_agility_bonus())
	if eq.get_inner_power_bonus() != 0:
		parts.append("内劲 %+d" % eq.get_inner_power_bonus())
	if eq.get_insight_bonus() != 0:
		parts.append("悟性 %+d" % eq.get_insight_bonus())
	if eq.get_vitality_bonus() != 0:
		parts.append("生命 %+d" % eq.get_vitality_bonus())
	if eq.get_inner_pool_bonus() != 0:
		parts.append("内力 %+d" % eq.get_inner_pool_bonus())
	if eq.get_guard_bonus() != 0:
		parts.append("防御 %+d" % eq.get_guard_bonus())
	return parts


func _build_attr_icon_strip() -> void:
	if _attr_icon_strip == null:
		return
	for child in _attr_icon_strip.get_children():
		child.queue_free()
	if not ResourceLoader.exists(ATTR_ICON_ATLAS_PATH):
		return
	var atlas := load(ATTR_ICON_ATLAS_PATH) as Texture2D
	if atlas == null:
		return
	for attr_name in ["筋骨", "机敏", "内劲", "悟性", "生命", "内力", "防御"]:
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(38, 0)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.tooltip_text = attr_name
		var texture := AtlasTexture.new()
		texture.atlas = atlas
		texture.region = ATTR_ICON_REGIONS.get(attr_name, Rect2())
		icon.texture = texture
		box.add_child(icon)
		var name_lbl := Label.new()
		name_lbl.text = attr_name
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UI_THEME.style_label(name_lbl, 11, UI_THEME.MUTED, false)
		box.add_child(name_lbl)
		_attr_icon_strip.add_child(box)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
