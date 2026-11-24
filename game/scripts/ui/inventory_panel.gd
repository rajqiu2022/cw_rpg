extends Control
const EQUIPMENT_STATS := preload("res://scripts/ui/equipment_stat_presentation.gd")
## 背包面板
signal closed
signal action_committed(action_type: StringName)

const FORMAL_CONFIRM_SCENE := preload("res://scenes/ui/formal_confirm_dialog.tscn")
const FORMAL_CHOICE_SCENE := preload("res://scenes/ui/formal_choice_menu.tscn")
const READING_PANEL_SCENE := preload("res://scenes/ui/reading_panel.tscn")

# -- 格子贴图 --
const CELL_DEFAULT := preload("res://art/ui/inventory/cells/cell_default.png")
const CELL_SELECTED := preload("res://art/ui/inventory/cells/cell_selected.png")
const CELL_EMPTY := preload("res://art/ui/inventory/cells/cell_empty.png")

# -- 回退图标 --
const ICON_WEAPON := preload("res://art/ui/inventory/icons/icon_sword.png")
const ICON_HEAD := preload("res://art/ui/inventory/icons/icon_iron_helmet.png")
const ICON_ARMOR := preload("res://art/ui/inventory/icons/icon_armor.png")
const ICON_HANDS := preload("res://art/ui/inventory/icons/icon_leather_bracers.png")
const ICON_POTION := preload("res://art/ui/inventory/icons/icon_potion.png")
const ICON_ORE := preload("res://art/ui/inventory/icons/icon_ore.png")
const ICON_SCROLL := preload("res://art/ui/inventory/icons/icon_scroll.png")
const ICON_KEY := preload("res://art/ui/inventory/icons/icon_key.png")
const ICON_RING := preload("res://art/ui/inventory/icons/icon_ring.png")
const ICON_SHOES := preload("res://art/ui/inventory/icons/icon_deer_leather_boots.png")

# -- 场景节点 --
@onready var _close_btn: TextureButton = %CloseBtn
@onready var _slot_grid: GridContainer = %SlotGrid
@onready var _detail_label: RichTextLabel = $MainPanel/Hotspots/DetailArea/DetailLabel
@onready var _detail_icon: TextureRect = $MainPanel/Hotspots/DetailArea/DetailIcon
@onready var _tab_all: TextureButton = $MainPanel/Hotspots/TabPanel/TabAll
@onready var _tab_consumable: TextureButton = $MainPanel/Hotspots/TabPanel/TabConsumable
@onready var _tab_equipment: TextureButton = $MainPanel/Hotspots/TabPanel/TabEquipment
@onready var _tab_key: TextureButton = $MainPanel/Hotspots/TabPanel/TabKey
@onready var _tab_material: TextureButton = $MainPanel/Hotspots/TabPanel/TabMaterial
@onready var _btn_use: TextureButton = %BtnUse
@onready var _btn_equip: TextureButton = %BtnEquip
@onready var _btn_drop: TextureButton = %BtnDrop

const TAB_TEX := {
	"all": {"n": preload("res://art/ui/inventory/tabs/tab_all_normal.png"), "s": preload("res://art/ui/inventory/tabs/tab_all_selected.png"), "p": preload("res://art/ui/inventory/tabs/tab_all_pressed.png")},
	"consumable": {"n": preload("res://art/ui/inventory/tabs/tab_consumable_normal.png"), "s": preload("res://art/ui/inventory/tabs/tab_consumable_selected.png"), "p": preload("res://art/ui/inventory/tabs/tab_consumable_pressed.png")},
	"equipment": {"n": preload("res://art/ui/inventory/tabs/tab_equipment_normal.png"), "s": preload("res://art/ui/inventory/tabs/tab_equipment_selected.png"), "p": preload("res://art/ui/inventory/tabs/tab_equipment_pressed.png")},
	"key": {"n": preload("res://art/ui/inventory/tabs/tab_key_normal.png"), "s": preload("res://art/ui/inventory/tabs/tab_key_selected.png"), "p": preload("res://art/ui/inventory/tabs/tab_key_pressed.png")},
	"material": {"n": preload("res://art/ui/inventory/tabs/tab_material_normal.png"), "s": preload("res://art/ui/inventory/tabs/tab_material_selected.png"), "p": preload("res://art/ui/inventory/tabs/tab_material_pressed.png")},
}

# -- 品质颜色 --
const QUALITY_COLORS := {
	Item.Quality.COMMON: "#c0c8d0", Item.Quality.UNCOMMON: "#1eff00",
	Item.Quality.RARE: "#4d8fff", Item.Quality.EPIC: "#b56cff", Item.Quality.LEGENDARY: "#ff9b38",
}
const QUALITY_NAMES := {
	Item.Quality.COMMON: "凡品", Item.Quality.UNCOMMON: "优质",
	Item.Quality.RARE: "高品", Item.Quality.EPIC: "稀有", Item.Quality.LEGENDARY: "尚品",
}

var _current_filter: String = "all"
var _selected_item: Item = null
var _selected_count: int = 0
var _selected_instance_id: String = ""
var _context_menu: FormalChoiceMenu = null
var _context_slot_index: int = -1
var _highlighted_cell: TextureRect = null
var _battle_mode: bool = false
var _confirm_dialog: FormalConfirmDialog
var _pending_confirm_action: StringName = &""
var _pending_confirm_item_id: StringName = &""
var _pending_confirm_instance_id := ""
var _reading_panel: ReadingPanel


func _ready() -> void:
	visible = false
	_setup_button_textures()
	_confirm_dialog = FORMAL_CONFIRM_SCENE.instantiate() as FormalConfirmDialog
	_confirm_dialog.name = "InventoryConfirmation"
	_confirm_dialog.confirmed.connect(_on_confirmation_confirmed)
	_confirm_dialog.cancelled.connect(_clear_pending_confirmation)
	add_child(_confirm_dialog)
	_reading_panel = READING_PANEL_SCENE.instantiate() as ReadingPanel
	add_child(_reading_panel)

	_close_btn.pressed.connect(close)
	_setup_tabs()
	_create_context_menu()
	_btn_use.pressed.connect(func(): _on_use_selected())
	_btn_equip.pressed.connect(func(): _on_equip_selected())
	_btn_drop.pressed.connect(func(): _on_drop_selected())
	Inventory.slots_changed.connect(_refresh)
	GameState.player_changed.connect(_refresh)
	EventBus.item_read_requested.connect(_on_item_read_requested)
	_refresh()


func _setup_button_textures() -> void:
	_close_btn.texture_normal = load("res://art/ui/inventory/buttons/btn_close_normal.png")
	_close_btn.texture_hover = load("res://art/ui/inventory/buttons/btn_close_hover.png")
	_close_btn.texture_pressed = load("res://art/ui/inventory/buttons/btn_close_pressed.png")
	_btn_use.texture_normal = load("res://art/ui/inventory/buttons/btn_use_normal.png")
	_btn_use.texture_hover = load("res://art/ui/inventory/buttons/btn_use_hover.png")
	_btn_use.texture_pressed = load("res://art/ui/inventory/buttons/btn_use_pressed.png")
	_btn_equip.texture_normal = load("res://art/ui/inventory/buttons/btn_equip_normal.png")
	_btn_equip.texture_hover = load("res://art/ui/inventory/buttons/btn_equip_hover.png")
	_btn_equip.texture_pressed = load("res://art/ui/inventory/buttons/btn_equip_pressed.png")
	_btn_drop.texture_normal = load("res://art/ui/inventory/buttons/btn_drop_normal.png")
	_btn_drop.texture_hover = load("res://art/ui/inventory/buttons/btn_drop_hover.png")
	_btn_drop.texture_pressed = load("res://art/ui/inventory/buttons/btn_drop_pressed.png")


func open() -> void:
	visible = true
	_refresh()


func set_battle_mode(enabled: bool) -> void:
	_battle_mode = enabled
	if enabled:
		_current_filter = "all"
		_selected_item = null
		_selected_count = 0
		_refresh()


func close() -> void:
	if _reading_panel != null and _reading_panel.is_open():
		_reading_panel.close_reader()
		return
	if _confirm_dialog != null:
		_confirm_dialog.close_dialog()
	_clear_pending_confirmation()
	visible = false

	emit_signal("closed")


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _reading_panel != null and _reading_panel.is_open():
			_reading_panel.close_reader()
			get_viewport().set_input_as_handled()
			return
		if _confirm_dialog != null and _confirm_dialog.is_open():
			return
		if _context_menu != null and _context_menu.is_open():
			return
		close()
		get_viewport().set_input_as_handled()
	if visible and event is InputEventKey and event.keycode == KEY_C and event.pressed:
		# C switches from the legacy inventory to the combined character view.
		EventBus.ui_requested.emit(&"equipment")
		get_viewport().set_input_as_handled()


const TAB_LABELS := {"all": "全部", "consumable": "消耗", "equipment": "装备", "key": "剧情", "material": "材料"}


func _tab_btn(key: String) -> TextureButton:
	match key:
		"all": return _tab_all
		"consumable": return _tab_consumable
		"equipment": return _tab_equipment
		"key": return _tab_key
		"material": return _tab_material
	return _tab_all


func _setup_tabs() -> void:
	for key in TAB_LABELS:
		var btn: TextureButton = _tab_btn(key)
		btn.custom_minimum_size = Vector2(160, 52)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(func(): _set_filter(key))
	_update_tab_highlights()


func _set_filter(key: String) -> void:
	_set_filter_internal(key, true)

func _set_filter_internal(key: String, emit_events: bool) -> void:
	_current_filter = key
	_selected_item = null
	_selected_count = 0
	if emit_events:
		if key == "equipment":
			EventBus.ui_requested.emit(&"equipment")
			return
		
	_refresh()


func _update_tab_highlights() -> void:
	for key in TAB_TEX:
		var btn: TextureButton = _tab_btn(key)
		var t: Dictionary = TAB_TEX[key]
		if key == _current_filter:
			btn.texture_normal = t["s"]
			btn.texture_hover = t["s"]
			btn.texture_pressed = t["p"]
		else:
			btn.texture_normal = t["n"]
			btn.texture_hover = t["s"]
			btn.texture_pressed = t["p"]


func _refresh() -> void:
	_update_tab_highlights()
	if _slot_grid == null: return
	for c in _slot_grid.get_children():
		c.queue_free()

	var shown: Array[Dictionary] = _filtered_slots()
	if shown.is_empty():
		var empty: Label = Label.new()
		empty.text = "暂无物品"
		empty.add_theme_color_override("font_color", Color(0.48, 0.58, 0.64, 1))
		empty.add_theme_font_size_override("font_size", 18)
		_slot_grid.add_child(empty)
		if _detail_label != null: _detail_label.text = ""
		return

	for i in shown.size():
		var entry: Dictionary = shown[i]
		_slot_grid.add_child(_make_slot_cell(entry["item"], entry["count"], String(entry.get("instance_id", "")), i))

	var total_slots: int = 24
	for i in range(shown.size(), total_slots):
		_slot_grid.add_child(_make_empty_cell())

	if _selected_item == null or not _passes_filter(_selected_item):
		var first: Dictionary = shown[0]
		_show_detail(first["item"], first["count"], String(first.get("instance_id", "")))
	else:
		_show_detail(_selected_item, _selected_count, _selected_instance_id)


func _filtered_slots() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in Inventory.slots:
		var item: Item = s.get("item")
		if item == null: continue
		if not _passes_filter(item): continue
		out.append(s)
	return out


func _passes_filter(item: Item) -> bool:
	match _current_filter:
		"consumable": return item.category == Item.Category.CONSUMABLE
		"equipment": return item is Equipment
		"key": return item.is_key_item()
		"material": return item.category == Item.Category.MATERIAL
	return true


func _make_slot_cell(item: Item, count: int, instance_id: String, slot_index: int) -> Control:
	var cell: TextureRect = TextureRect.new()
	cell.custom_minimum_size = Vector2(85, 83)
	cell.texture = CELL_DEFAULT
	cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_add_quality_frame(cell, item)

	var icon_tex: Texture2D = _resolve_icon(item)
	if icon_tex != null:
		var icon: TextureRect = TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(60, 44)
		icon.position = Vector2(12, 4)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)

	var name_lbl: Label = Label.new()
	name_lbl.text = _compact_slot_name(item)
	name_lbl.position = Vector2(2, 48)
	name_lbl.size = Vector2(81, 32)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_font_size_override("font_size", 11 if item.display_name.length() > 7 else 12)
	name_lbl.add_theme_color_override("font_color", Color.from_string(String(QUALITY_COLORS.get(item.quality, "#c0c8d0")), Color(0.8, 0.88, 0.94)))
	cell.add_child(name_lbl)

	if item.stackable and count > 1:
		var lbl: Label = Label.new()
		lbl.text = str(count)
		lbl.position = Vector2(55, 1)
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		cell.add_child(lbl)

	cell.set_meta("slot_index", slot_index)
	# Equipped indicator
	if item is Equipment and Inventory.is_instance_equipped(instance_id):
		var check := Label.new()
		check.text = "✓"
		check.position = Vector2(56, 48)
		check.add_theme_font_size_override("font_size", 30)
		check.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		cell.add_child(check)
	cell.gui_input.connect(func(ev: InputEvent): _on_cell_input(ev, item, count, instance_id, slot_index, cell))
	return cell


func _compact_slot_name(item: Item) -> String:
	if item != null and item.is_readable():
		# Keep the full manuscript title in the detail/reading panels; inventory
		# cells use a compact catalogue form so neighbouring slots never overlap.
		return item.display_name.replace("《", "").replace("》", "·")
	return item.display_name if item != null else ""


func _resolve_icon(item: Item) -> Texture2D:
	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		return load(item.icon_path)
	if item is Equipment:
		match (item as Equipment).slot:
			Equipment.Slot.WEAPON: return ICON_WEAPON
			Equipment.Slot.HEAD: return ICON_HEAD
			Equipment.Slot.ARMOR: return ICON_ARMOR
			Equipment.Slot.HANDS: return ICON_HANDS
			Equipment.Slot.SHOES: return ICON_SHOES
			Equipment.Slot.ACCESSORY: return ICON_RING
	match item.category:
		Item.Category.CONSUMABLE: return ICON_POTION
		Item.Category.MATERIAL: return ICON_ORE
		Item.Category.KEY_ITEM: return ICON_KEY
	return ICON_SCROLL


func _add_quality_frame(cell: Control, item: Item) -> void:
	if item == null:
		return
	var frame := Panel.new()
	frame.name = "QualityFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 2.0
	frame.offset_top = 2.0
	frame.offset_right = -2.0
	frame.offset_bottom = -2.0
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var border := StyleBoxFlat.new()
	border.bg_color = Color.TRANSPARENT
	border.border_color = Color.from_string(String(QUALITY_COLORS.get(item.quality, "#c0c8d0")), Color.WHITE)
	border.set_border_width_all(3 if item.quality == Item.Quality.LEGENDARY else (2 if item.quality >= Item.Quality.UNCOMMON else 1))
	border.set_corner_radius_all(4)
	frame.add_theme_stylebox_override("panel", border)
	cell.add_child(frame)


func _make_empty_cell() -> Control:
	var cell: TextureRect = TextureRect.new()
	cell.custom_minimum_size = Vector2(85, 83)
	cell.texture = CELL_EMPTY
	cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cell


func _on_cell_input(ev: InputEvent, item: Item, count: int, instance_id: String, slot_index: int, cell: TextureRect) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_highlight_cell(cell)
			_show_detail(item, count, instance_id)
			if mb.double_click and item.is_readable():
				_open_reading(item)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if item is Equipment:
				if Inventory.is_instance_equipped(instance_id):
					Inventory.unequip((item as Equipment).slot)
				else:
					Inventory.equip_instance(instance_id)
				# If not already in equipment mode, switch to it
				if _current_filter != "equipment":
					EventBus.ui_requested.emit(&"equipment")
				else:
					_refresh()
			elif item.category == Item.Category.CONSUMABLE:
				var p: CharacterStats = GameState.player
				if p == null: return
				if String(item.item_id) == "linxi_jiu":
					# 永久属性物品不受满血限制
					var old_max_hp: int = p.max_hp
					var old_max_mp: int = p.max_mp
					if Inventory.use_item(item.item_id):
						var max_lines: Array[String] = []
						if p.max_hp > old_max_hp:
							max_lines.append(_effect_tip_line("生命值最大值", p.max_hp - old_max_hp))
						if p.max_mp > old_max_mp:
							max_lines.append(_effect_tip_line("内力值最大值", p.max_mp - old_max_mp))
						_show_tip("\n".join(max_lines), true)
						_refresh()
				elif item.heal_hp > 0 and p.hp >= p.max_hp and item.heal_mp == 0:
					_show_tip("[color=#ff6b6b]生命已满[/color]", true)
				elif item.heal_mp > 0 and p.mp >= p.max_mp and item.heal_hp == 0:
					_show_tip("[color=#64b5f6]内力已满[/color]", true)
				elif item.heal_hp > 0 and item.heal_mp > 0 and p.hp >= p.max_hp and p.mp >= p.max_mp:
					_show_tip("[color=#ff6b6b]生命[/color]与[color=#64b5f6]内力[/color]均已满", true)
				else:
					var old_hp: int = p.hp
					var old_mp: int = p.mp
					if Inventory.use_item(item.item_id):
						var parts: Array[String] = []
						if p.hp > old_hp: parts.append(_effect_tip_line("生命值", p.hp - old_hp))
						if p.mp > old_mp: parts.append(_effect_tip_line("内力值", p.mp - old_mp))
						if not parts.is_empty(): _show_tip("\n".join(parts), true)
						_refresh()
			else:
				_context_slot_index = slot_index
				_show_context_menu(item)


func _highlight_cell(cell: TextureRect) -> void:
	if _highlighted_cell != null:
		_highlighted_cell.texture = CELL_DEFAULT
	cell.texture = CELL_SELECTED
	_highlighted_cell = cell


func _show_tip(text: String, use_bbcode: bool = false) -> void:
	var panel := PanelContainer.new()
	panel.z_index = 100
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line_count: int = maxi(1, text.count("\n") + 1)
	panel.custom_minimum_size = Vector2(280.0, 38.0 + line_count * 25.0)
	panel.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	var style: StyleBoxFlat = panel.get_theme_stylebox("panel")
	style.bg_color = Color(0, 0, 0, 0.75)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	var lbl: Control
	if use_bbcode:
		var rich_lbl: RichTextLabel = RichTextLabel.new()
		rich_lbl.bbcode_enabled = true
		rich_lbl.fit_content = true
		rich_lbl.custom_minimum_size = Vector2(260.0, line_count * 25.0)
		rich_lbl.add_theme_font_size_override("normal_font_size", 19)
		rich_lbl.add_theme_color_override("default_color", Color(0.95, 0.98, 1.0, 1.0))
		rich_lbl.text = "[font_size=20]%s[/font_size]" % text
		lbl = rich_lbl
	else:
		var plain_lbl: Label = Label.new()
		plain_lbl.text = text
		plain_lbl.custom_minimum_size = Vector2(260.0, line_count * 25.0)
		plain_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plain_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plain_lbl.add_theme_font_size_override("font_size", 19)
		plain_lbl.add_theme_color_override("font_color", Color(0.92, 0.98, 1.0, 1.0))
		plain_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.08, 1.0))
		plain_lbl.add_theme_constant_override("outline_size", 3)
		lbl = plain_lbl
	panel.add_child(lbl)
	panel.reset_size()
	panel.position = get_global_mouse_position() - global_position + Vector2(10, -40)
	add_child(panel)
	var tween := create_tween()
	tween.tween_property(panel, "position", panel.position + Vector2(0, -50), 1.2)
	tween.parallel().tween_property(panel, "modulate", Color(1,1,1,0), 1.2)
	tween.tween_callback(panel.queue_free)


func _effect_tip_line(label_text: String, amount: int) -> String:
	return "[color=#e3a64a]%s[/color] [color=#a970ff]+ %d[/color]" % [label_text, amount]

func _on_use_selected() -> void:
	if _selected_item == null:
		return
	if _selected_item.is_readable():
		_open_reading(_selected_item)
	elif _selected_item.category == Item.Category.CONSUMABLE:
		_on_use(_selected_item.item_id)


func _on_equip_selected() -> void:
	if _selected_item != null and _selected_item is Equipment:
		_on_equip(_selected_item.item_id, _selected_instance_id)







func _on_drop_selected() -> void:
	if _selected_item != null:
		_request_drop(_selected_item, _selected_instance_id)


func _show_detail(item: Item, count: int, instance_id: String = "") -> void:
	_selected_item = item
	_selected_count = count
	_selected_instance_id = instance_id
	var icon_tex: Texture2D = _resolve_icon(item)
	if _detail_icon != null:
		_detail_icon.texture = icon_tex
		_detail_icon.visible = icon_tex != null

	var qc: String = QUALITY_COLORS.get(item.quality, "#c0c8d0")
	var qn: String = QUALITY_NAMES.get(item.quality, "")

	var lines: Array[String] = []
	if item.is_readable():
		lines.append("[font_size=21][color=%s]%s[/color][/font_size]" % [qc, item.display_name])
	else:
		lines.append("[font_size=21][color=%s]%s[/color] [color=#e8e8e8][%s][/color][/font_size]" % [qc, item.display_name, qn])
	lines.append("[font_size=15][color=#8899aa]%s · ×%d[/color][/font_size]" % [_cat_text(item), count])
	lines.append("[font_size=15][color=#e8e8e8]%s[/color][/font_size]" % item.description)
	if item.is_readable():
		lines.append("[font_size=15][color=#e5c06b]可阅读 · 双击或右键选择“阅读”[/color][/font_size]")

	# Consumable effects
	if item.category == Item.Category.CONSUMABLE:
		var fx: Array[String] = []
		if item.heal_hp > 0: fx.append("[color=#ff6b6b]生命+%d[/color]" % item.heal_hp)
		if item.heal_mp > 0: fx.append("[color=#64b5f6]内力+%d[/color]" % item.heal_mp)
		if not fx.is_empty():
			lines.append("[font_size=15]%s[/font_size]" % "  ".join(fx))

	# Equipment stat bonuses
	if item is Equipment:
		var eq := item as Equipment
		lines.append("")
		lines.append("[font_size=13][color=#8899aa]—— %s ——[/color][/font_size]" % Inventory.slot_display_name(eq.slot))
		var effect_color: String = QUALITY_COLORS.get(eq.quality, "#c0c8d0")
		lines.append("[font_size=15]%s[/font_size]" % EQUIPMENT_STATS.bbcode(eq, effect_color))

	lines.append("[font_size=14][color=#889999]卖出 %d[/color][/font_size]" % item.sell_price)
	_detail_label.text = "\n".join(lines)


func _stat_tier_color(val: int) -> String:
	return EQUIPMENT_STATS.row_color({"value": val}, "#c0c8d0")


func _school_name(s: String) -> String:
	match s:
		"linxi": return "林西"
		"gufeng": return "古峰"
		"huashan": return "华山"
		"lingyue": return "凌月"
		"mingwu": return "茗雾"
		"wudang": return "武当"
	return s


func _weapon_style_name(style: StringName) -> String:
	match style:
		&"sword": return "剑法"
		&"blade": return "刀法"
		&"axe": return "斧法"
		&"staff": return "棍法"
		&"dagger": return "短兵武功"
		&"hidden": return "暗器武功"
		&"ring": return "奇门武功"
		&"palm": return "掌法"
	return "兵器武功"


func _cat_text(item: Item) -> String:
	if item is Equipment: return "装备"
	match item.category:
		Item.Category.CONSUMABLE: return "消耗"
		Item.Category.MATERIAL: return "材料"
		Item.Category.KEY_ITEM: return "剧情"
	return "物品"


func _on_use(id: StringName) -> bool:
	var item: Item = Inventory.load_item_by_id(id)
	if item == null or not item.can_use(_battle_mode):
		_show_tip("该道具当前无法使用", false)
		return false
	if _requires_precious_use_confirmation(item):
		_pending_confirm_action = &"use"
		_pending_confirm_item_id = id
		_pending_confirm_instance_id = ""
		var target_name := GameState.player.display_name if GameState.player != null else "冷孤云"
		var quality_color: String = QUALITY_COLORS.get(item.quality, "#b56cff")
		var message := "[center]是否给 [color=#e5c06b]%s[/color] 使用\n[color=%s]%s[/color]？\n\n[color=#d6c4a4]该物品会永久增加属性或上限，使用后无法撤销。[/color][/center]" % [target_name, quality_color, item.display_name]
		_confirm_dialog.show_confirm("确认使用珍贵丹药", message, "确认使用", "取消")
		return false
	return _use_item_now(id)


func _use_item_now(id: StringName) -> bool:
	var item: Item = Inventory.load_item_by_id(id)
	if item == null or not item.can_use(_battle_mode):
		_show_tip("该道具当前无法使用", false)
		return false
	var player: CharacterStats = GameState.player
	if player == null:
		return false
	var old_hp: int = player.hp
	var old_mp: int = player.mp
	var old_max_hp: int = player.max_hp
	var old_max_mp: int = player.max_mp
	if not Inventory.use_item(id, _battle_mode):
		_show_tip("当前状态无法使用该道具", false)
		return false
	var parts: Array[String] = []
	if player.hp > old_hp:
		parts.append(_effect_tip_line("生命值", player.hp - old_hp))
	if player.mp > old_mp:
		parts.append(_effect_tip_line("内力值", player.mp - old_mp))
	if player.max_hp > old_max_hp:
		parts.append(_effect_tip_line("生命值最大值", player.max_hp - old_max_hp))
	if player.max_mp > old_max_mp:
		parts.append(_effect_tip_line("内力值最大值", player.max_mp - old_max_mp))
	if parts.is_empty():
		parts.append("[color=#e3a64a]已使用：[/color][color=#a970ff]%s[/color]" % item.display_name)
	_show_tip("\n".join(parts), true)
	_refresh()
	if _battle_mode:
		action_committed.emit(&"use_item")
	return true


func _on_equip(id: StringName, instance_id: String = "") -> bool:
	var item: Item = Inventory.load_item_by_id(id)
	if not item is Equipment:
		_show_tip("请选择可装备的物品", false)
		return false
	var equipped_ok: bool = Inventory.equip_instance(instance_id) if instance_id != "" else Inventory.equip(id)
	if not equipped_ok:
		_show_tip("装备失败", false)
		return false
	_show_tip("已装备 %s" % item.display_name, false)
	_refresh()
	if _battle_mode:
		action_committed.emit(&"equip")
	return true


func _create_context_menu() -> void:
	var legacy_menu := get_node_or_null("ContextMenu")
	if legacy_menu != null:
		legacy_menu.queue_free()
	_context_menu = FORMAL_CHOICE_SCENE.instantiate() as FormalChoiceMenu
	_context_menu.name = "ContextMenu"
	_context_menu.item_selected.connect(_on_context)
	_context_menu.cancelled.connect(func(): _context_slot_index = -1)
	add_child(_context_menu)


func _show_context_menu(item: Item) -> void:
	var options: Array[Dictionary] = [{"id": &"detail", "label": "查看详情"}]
	if item.is_readable():
		options.append({"id": &"read", "label": "阅读"})
	if item.category == Item.Category.CONSUMABLE:
		options.append({"id": &"use", "label": "使用"})
	elif item is Equipment:
		options.append({"id": &"equip", "label": "装备"})
	options.append({"id": &"drop", "label": "丢弃", "enabled": not item.is_key_item()})
	_context_menu.show_choices("物品操作", options)


func _on_context(id: StringName) -> void:
	if _context_slot_index < 0: return
	var entry: Dictionary = _get_slot(_context_slot_index)
	var item: Item = entry.get("item")
	if item == null: return
	_context_slot_index = -1
	match id:
		&"detail": _show_detail(item, int(entry.get("count", 1)), String(entry.get("instance_id", "")))
		&"read": _open_reading(item)
		&"use": _on_use(item.item_id)
		&"equip": _on_equip(item.item_id, String(entry.get("instance_id", "")))
		&"drop":
			_request_drop(item, String(entry.get("instance_id", "")))


func _on_item_read_requested(item_id: StringName) -> void:
	if _battle_mode:
		_show_tip("战斗中无法阅读", false)
		return
	var item := Inventory.load_item_by_id(item_id)
	if item != null and Inventory.has_item(item_id, 1):
		_open_reading(item)


func _open_reading(item: Item) -> void:
	if _battle_mode:
		_show_tip("战斗中无法阅读", false)
		return
	if item == null or not item.is_readable() or _reading_panel == null:
		_show_tip("这件物品没有可阅读的内容", false)
		return
	_reading_panel.open_item(item)


func _requires_precious_use_confirmation(item: Item) -> bool:
	return (
		item != null
		and item.category == Item.Category.CONSUMABLE
		and item.permanent_growth
		and item.quality >= Item.Quality.EPIC
	)


func _request_drop(item: Item, instance_id: String = "") -> void:
	if item == null:
		return
	if item.is_key_item():
		_confirm_dialog.show_notice("无法丢弃", "[center]剧情物品不能丢弃。[/center]")
		return
	_pending_confirm_action = &"drop"
	_pending_confirm_item_id = item.item_id
	_pending_confirm_instance_id = instance_id
	var quality_color: String = QUALITY_COLORS.get(item.quality, "#c0c8d0")
	var message := "[center]是否丢弃\n[color=%s]%s[/color]？\n\n[color=#d6c4a4]丢弃后将从背包中移除，无法撤销。[/color][/center]" % [quality_color, item.display_name]
	_confirm_dialog.show_confirm("确认丢弃物品", message, "确认丢弃", "取消")


func _on_confirmation_confirmed() -> void:
	var action := _pending_confirm_action
	var item_id := _pending_confirm_item_id
	var instance_id := _pending_confirm_instance_id
	_clear_pending_confirmation()
	match action:
		&"use":
			_use_item_now(item_id)
		&"drop":
			if not instance_id.is_empty():
				Inventory.remove_instance(instance_id)
			else:
				Inventory.remove_item(item_id, 1)
			_selected_item = null
			_selected_instance_id = ""
			_refresh()


func _clear_pending_confirmation() -> void:
	_pending_confirm_action = &""
	_pending_confirm_item_id = &""
	_pending_confirm_instance_id = ""


func _get_slot(idx: int) -> Dictionary:
	var shown: Array[Dictionary] = _filtered_slots()
	if idx >= 0 and idx < shown.size(): return shown[idx]
	return {}
