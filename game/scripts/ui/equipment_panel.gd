class_name EquipmentPanel
extends Control
## 装备面板 — 纸娃娃布局 + 属性

signal closed

@onready var _close_btn: TextureButton = $BtnClose
@onready var _attr_labels: Array[Label] = [
	$AttrGroup/Attr_筋骨, $AttrGroup/Attr_机敏, $AttrGroup/Attr_内劲, $AttrGroup/Attr_悟性,
	$AttrGroup/Attr_生命, $AttrGroup/Attr_内力, $AttrGroup/Attr_攻击, $AttrGroup/Attr_防御, $AttrGroup/Attr_速度,
]

const SLOT_NODES := ["SlotWeapon", "SlotHead", "SlotArmor", "SlotHands", "SlotShoes", "SlotAccessory"]


func open() -> void:
	visible = true
	call_deferred("_refresh")


func _on_close() -> void:
	close()
	emit_signal("closed")


func close() -> void:
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close()
		get_viewport().set_input_as_handled()


func _ready() -> void:
	call_deferred("_create_slot_icons")
	_close_btn.pressed.connect(_on_close)
	_close_btn.texture_normal = load("res://art/ui/inventory/buttons/btn_x_normal.png")
	_close_btn.texture_hover = load("res://art/ui/inventory/buttons/btn_x_hover.png")
	_close_btn.texture_pressed = load("res://art/ui/inventory/buttons/btn_x_pressed.png")
	Inventory.slots_changed.connect(_refresh)
	GameState.player_changed.connect(_refresh)


func _create_slot_icons() -> void:
	for i in 6:
		var frame: ColorRect = get_node_or_null(SLOT_NODES[i])
		if frame == null: continue
		frame.mouse_filter = Control.MOUSE_FILTER_STOP
		frame.gui_input.connect(_on_slot_click.bind(i))
		frame.mouse_entered.connect(_show_tooltip.bind(i))
		frame.mouse_exited.connect(_hide_tooltip)
		var icon := TextureRect.new()
		icon.name = "EquipIcon"
		# Center icon in slot, 60% of slot size max
		var iw: int = max(int(frame.size.x * 0.55), 32)
		var ih: int = max(int(frame.size.y * 0.50), 28)
		icon.position = Vector2((frame.size.x - iw) / 2, (frame.size.y - ih - 10) / 2)
		icon.size = Vector2(iw, ih)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(icon)
		var lbl := Label.new()
		lbl.name = "EquipName"
		lbl.position = Vector2(2, frame.size.y - 16)
		lbl.size = Vector2(frame.size.x - 4, 14)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.clip_text = true
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
		frame.add_child(lbl)


var _tooltip: Control = null
var _tooltip_labels: Array[Label] = []

func _refresh() -> void:
	for i in 6:
		var frame: ColorRect = get_node_or_null(SLOT_NODES[i])
		if frame == null: continue
		var icon: TextureRect = frame.get_node_or_null("EquipIcon")
		var lbl: Label = frame.get_node_or_null("EquipName")
		var eq: Equipment = Inventory.get_equipped(i)
		if eq:
			if icon:
				if eq.icon_path != "" and ResourceLoader.exists(eq.icon_path):
					icon.texture = load(eq.icon_path)
				else:
					icon.texture = _default_icon(i)
			if lbl:
				lbl.text = eq.display_name
				lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
		else:
			if icon: icon.texture = null
			if lbl:
				lbl.text = ""
				lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.7))
	_refresh_attrs()


func _refresh_attrs() -> void:
	var p: CharacterStats = GameState.player
	if p == null: return
	var texts := [
		str(p.strength + Inventory.get_strength_bonus()),
		str(p.agility + Inventory.get_agility_bonus()),
		str(p.inner_power + Inventory.get_inner_power_bonus()),
		str(p.insight + Inventory.get_insight_bonus()),
		"%d/%d" % [p.hp, p.max_hp + Inventory.get_vitality_bonus() * 8],
		"%d/%d" % [p.mp, p.max_mp + Inventory.get_inner_pool_bonus() * 6],
		str(p.attack + Inventory.get_atk_bonus()),
		str(p.defense + Inventory.get_def_bonus()),
		str(p.speed + Inventory.get_speed_bonus()),
	]
	for i in _attr_labels.size():
		if i < texts.size() and _attr_labels[i] != null:
			_attr_labels[i].text = texts[i]


func _default_icon(slot_idx: int) -> Texture2D:
	match slot_idx:
		0: return preload("res://art/ui/inventory/icons/icon_sword.png")
		1, 2, 3, 4: return preload("res://art/ui/inventory/icons/icon_armor.png")
		5: return preload("res://art/ui/inventory/icons/icon_ring.png")
	return null


func _on_slot_click(ev: InputEvent, slot_idx: int) -> void:
	if not (ev is InputEventMouseButton): return
	var mb := ev as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT or not mb.pressed: return
	Inventory.unequip(slot_idx)
	_refresh()


func _ensure_tooltip() -> void:
	if _tooltip: return
	_tooltip = PanelContainer.new()
	_tooltip.visible = false
	_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip.custom_minimum_size = Vector2(260, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.16, 0.88)
	sb.border_color = Color(0.25, 0.40, 0.55, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 8
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_tooltip.add_theme_stylebox_override("panel", sb)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	var name_lbl := Label.new()
	name_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_lbl)
	_tooltip_labels = [name_lbl]
	for attr_name in ["筋骨", "机敏", "内劲", "悟性", "生命", "内力", "防御"]:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 16)
		l.text = attr_name + ": 0"
		vbox.add_child(l)
		_tooltip_labels.append(l)
	_tooltip.add_child(vbox)
	add_child(_tooltip)


func _show_tooltip(slot_idx: int) -> void:
	_ensure_tooltip()
	var eq: Equipment = Inventory.get_equipped(slot_idx)
	if eq == null:
		return
	_tooltip_labels[0].text = eq.display_name
	_tooltip_labels[0].add_theme_color_override("font_color", Color(0.95, 0.92, 0.85))
	var bonus_pairs: Array[Dictionary] = [
		{"name": "筋骨", "val": eq.get_strength_bonus()},
		{"name": "机敏", "val": eq.get_agility_bonus()},
		{"name": "内劲", "val": eq.get_inner_power_bonus()},
		{"name": "悟性", "val": eq.get_insight_bonus()},
		{"name": "生命", "val": eq.get_vitality_bonus()},
		{"name": "内力", "val": eq.get_inner_pool_bonus()},
		{"name": "防御", "val": eq.get_guard_bonus()},
	]
	for j in bonus_pairs.size():
		var pair: Dictionary = bonus_pairs[j]
		var val: int = int(pair["val"])
		var attr_name: String = str(pair["name"])
		var c := "#e8e8e8" if val == 0 else "#ff8c42"
		var sign := "+" if val > 0 else ""
		_tooltip_labels[j + 1].text = "%s: %s%d" % [attr_name, sign, val]
		_tooltip_labels[j + 1].add_theme_color_override("font_color", Color(c))
	var mouse_pos := get_global_mouse_position() - global_position
	_tooltip.position = mouse_pos + Vector2(16, 16)
	_tooltip.visible = true


func _hide_tooltip() -> void:
	if _tooltip:
		_tooltip.visible = false
