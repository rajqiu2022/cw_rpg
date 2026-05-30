extends Control
## 背包面板
signal closed

# -- 格子贴图 --
const CELL_DEFAULT := preload("res://art/ui/inventory/cells/cell_default.png")
const CELL_SELECTED := preload("res://art/ui/inventory/cells/cell_selected.png")
const CELL_EMPTY := preload("res://art/ui/inventory/cells/cell_empty.png")

# -- 回退图标 --
const ICON_WEAPON := preload("res://art/ui/inventory/icons/icon_sword.png")
const ICON_ARMOR := preload("res://art/ui/inventory/icons/icon_armor.png")
const ICON_POTION := preload("res://art/ui/inventory/icons/icon_potion.png")
const ICON_ORE := preload("res://art/ui/inventory/icons/icon_ore.png")
const ICON_SCROLL := preload("res://art/ui/inventory/icons/icon_scroll.png")
const ICON_KEY := preload("res://art/ui/inventory/icons/icon_key.png")
const ICON_RING := preload("res://art/ui/inventory/icons/icon_ring.png")
const ICON_SHOES := preload("res://art/ui/inventory/icons/icon_shoes.png")

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
	Item.Quality.RARE: "#0070dd", Item.Quality.EPIC: "#a335ee", Item.Quality.LEGENDARY: "#ff8000",
}
const QUALITY_NAMES := {
	Item.Quality.COMMON: "普通", Item.Quality.UNCOMMON: "精良",
	Item.Quality.RARE: "稀有", Item.Quality.EPIC: "史诗", Item.Quality.LEGENDARY: "传说",
}
const STAT_COLORS := {
	"筋骨": "#ff8a80", "机敏": "#b9f6ca", "内劲": "#82b1ff", "悟性": "#b388ff",
	"生命": "#ff5252", "内力": "#448aff", "防御": "#b0bec5",
}

var _current_filter: String = "all"
var _selected_item: Item = null
var _selected_count: int = 0
var _context_menu: PopupMenu = null
var _context_slot_index: int = -1
var _highlighted_cell: TextureRect = null


func _ready() -> void:
	visible = false
	_setup_button_textures()
	_close_btn.pressed.connect(close)
	_setup_tabs()
	_create_context_menu()
	_btn_use.pressed.connect(func(): _on_use_selected())
	_btn_equip.pressed.connect(func(): _on_equip_selected())
	_btn_drop.pressed.connect(func(): _on_drop_selected())
	Inventory.slots_changed.connect(_refresh)
	GameState.player_changed.connect(_refresh)
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


func close() -> void:
	visible = false
	emit_signal("closed")


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
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
	_current_filter = key
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

	var shown := _filtered_slots()
	if shown.is_empty():
		var empty := Label.new()
		empty.text = "暂无物品"
		empty.add_theme_color_override("font_color", Color(0.48, 0.58, 0.64, 1))
		empty.add_theme_font_size_override("font_size", 16)
		_slot_grid.add_child(empty)
		if _detail_label != null: _detail_label.text = ""
		return

	for i in shown.size():
		var entry: Dictionary = shown[i]
		_slot_grid.add_child(_make_slot_cell(entry["item"], entry["count"], i))

	var total_slots := 36
	for i in range(shown.size(), total_slots):
		_slot_grid.add_child(_make_empty_cell())

	if _selected_item == null or not _passes_filter(_selected_item):
		var first: Dictionary = shown[0]
		_show_detail(first["item"], first["count"])
	else:
		_show_detail(_selected_item, _selected_count)


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


func _make_slot_cell(item: Item, count: int, slot_index: int) -> Control:
	var cell := TextureRect.new()
	cell.custom_minimum_size = Vector2(85, 83)
	cell.texture = CELL_DEFAULT
	cell.expand_mode = 1
	cell.stretch_mode = 5
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var icon_tex := _resolve_icon(item)
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(60, 44)
		icon.position = Vector2(12, 3)
		icon.expand_mode = 1
		icon.stretch_mode = 5
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = item.display_name
	name_lbl.position = Vector2(2, 48)
	name_lbl.size = Vector2(81, 32)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.8, 0.88, 0.94))
	cell.add_child(name_lbl)

	if item.stackable and count > 1:
		var lbl := Label.new()
		lbl.text = str(count)
		lbl.position = Vector2(55, 1)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		cell.add_child(lbl)

	cell.set_meta("slot_index", slot_index)
	cell.gui_input.connect(func(ev: InputEvent): _on_cell_input(ev, item, count, slot_index, cell))
	return cell


func _resolve_icon(item: Item) -> Texture2D:
	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		return load(item.icon_path)
	if item is Equipment:
		match (item as Equipment).slot:
			Equipment.Slot.WEAPON: return ICON_WEAPON
			Equipment.Slot.HEAD, Equipment.Slot.ARMOR, Equipment.Slot.HANDS: return ICON_ARMOR
			Equipment.Slot.SHOES: return ICON_SHOES
			Equipment.Slot.ACCESSORY: return ICON_RING
	match item.category:
		Item.Category.CONSUMABLE: return ICON_POTION
		Item.Category.MATERIAL: return ICON_ORE
		Item.Category.KEY_ITEM: return ICON_KEY
	return ICON_SCROLL


func _make_empty_cell() -> Control:
	var cell := TextureRect.new()
	cell.custom_minimum_size = Vector2(85, 83)
	cell.texture = CELL_EMPTY
	cell.expand_mode = 1
	cell.stretch_mode = 5
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cell


func _on_cell_input(ev: InputEvent, item: Item, count: int, slot_index: int, cell: TextureRect) -> void:
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_highlight_cell(cell)
			_show_detail(item, count)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_context_slot_index = slot_index
			var entry := _get_slot(slot_index)
			var it: Item = entry.get("item")
			for i in 4: _context_menu.set_item_disabled(i, it == null)
			if it != null:
				_context_menu.set_item_disabled(1, it.category != Item.Category.CONSUMABLE)
				_context_menu.set_item_disabled(2, not it is Equipment)
			_context_menu.position = Vector2i(int(get_global_mouse_position().x), int(get_global_mouse_position().y))
			_context_menu.popup()


func _highlight_cell(cell: TextureRect) -> void:
	if _highlighted_cell != null:
		_highlighted_cell.texture = CELL_DEFAULT
	cell.texture = CELL_SELECTED
	_highlighted_cell = cell


func _on_use_selected() -> void:
	if _selected_item != null and _selected_item.category == Item.Category.CONSUMABLE:
		_on_use(_selected_item.item_id)


func _on_equip_selected() -> void:
	if _selected_item != null and _selected_item is Equipment:
		_on_equip(_selected_item.item_id)


func _on_drop_selected() -> void:
	if _selected_item != null:
		Inventory.remove_item(_selected_item.item_id, 1)
		_selected_item = null
		_refresh()


func _show_detail(item: Item, count: int) -> void:
	_selected_item = item
	_selected_count = count
	var icon_tex := _resolve_icon(item)
	if _detail_icon != null:
		_detail_icon.texture = icon_tex
		_detail_icon.visible = icon_tex != null

	var qc: String = QUALITY_COLORS.get(item.quality, "#c0c8d0")
	var qn: String = QUALITY_NAMES.get(item.quality, "")

	var lines: Array[String] = []
	lines.append("[font_size=16][color=%s]%s[/color][/font_size]  [font_size=11][color=#667788]%s[/color][/font_size]" % [qc, item.display_name, qn])
	lines.append("[font_size=13][color=#6a8a9a]%s ×%d[/color][/font_size]" % [_cat_text(item), count])
	lines.append("")
	lines.append("[font_size=13]%s[/font_size]" % item.description)

	if item is Equipment:
		var eq := item as Equipment
		lines.append("")
		lines.append("[font_size=12][color=#7a8a9a]装备槽：%s[/color][/font_size]" % Inventory.slot_display_name(eq.slot))
		var bonus := _bonus_text(eq)
		if bonus != "":
			lines.append("[font_size=13][b]属性加成[/b][/font_size]")
			lines.append(bonus)
	elif item.category == Item.Category.CONSUMABLE:
		lines.append("")
		if item.heal_hp > 0:
			lines.append("[font_size=13][color=#ff5252]生命 +%d[/color][/font_size]" % item.heal_hp)
		if item.heal_mp > 0:
			lines.append("[font_size=13][color=#448aff]内力 +%d[/color][/font_size]" % item.heal_mp)

	lines.append("")
	lines.append("[font_size=12][color=#7a8a9a]买 %d  卖 %d[/color][/font_size]" % [item.buy_price, item.sell_price])
	_detail_label.text = "\n".join(lines)


func _bonus_text(eq: Equipment) -> String:
	var lines: Array[String] = []
	if eq.get_strength_bonus() != 0: lines.append("  [color=%s]筋骨 %+d[/color]" % [STAT_COLORS["筋骨"], eq.get_strength_bonus()])
	if eq.get_agility_bonus() != 0: lines.append("  [color=%s]机敏 %+d[/color]" % [STAT_COLORS["机敏"], eq.get_agility_bonus()])
	if eq.get_inner_power_bonus() != 0: lines.append("  [color=%s]内劲 %+d[/color]" % [STAT_COLORS["内劲"], eq.get_inner_power_bonus()])
	if eq.get_insight_bonus() != 0: lines.append("  [color=%s]悟性 %+d[/color]" % [STAT_COLORS["悟性"], eq.get_insight_bonus()])
	if eq.get_vitality_bonus() != 0: lines.append("  [color=%s]生命 %+d[/color]" % [STAT_COLORS["生命"], eq.get_vitality_bonus()])
	if eq.get_inner_pool_bonus() != 0: lines.append("  [color=%s]内力 %+d[/color]" % [STAT_COLORS["内力"], eq.get_inner_pool_bonus()])
	if eq.get_guard_bonus() != 0: lines.append("  [color=%s]防御 %+d[/color]" % [STAT_COLORS["防御"], eq.get_guard_bonus()])
	return "\n".join(lines) if not lines.is_empty() else ""


func _cat_text(item: Item) -> String:
	if item is Equipment: return "装备"
	match item.category:
		Item.Category.CONSUMABLE: return "消耗"
		Item.Category.MATERIAL: return "材料"
		Item.Category.KEY_ITEM: return "剧情"
	return "物品"


func _on_use(id: StringName) -> void:
	if Inventory.use_item(id): _refresh()


func _on_equip(id: StringName) -> void:
	if Inventory.equip(id): _refresh()


func _create_context_menu() -> void:
	_context_menu = $ContextMenu
	if _context_menu == null:
		_context_menu = PopupMenu.new()
		_context_menu.name = "ContextMenu"
		add_child(_context_menu)
	_context_menu.clear()
	_context_menu.add_item("详情", 0)
	_context_menu.add_item("使用", 1)
	_context_menu.add_item("装备", 2)
	_context_menu.add_item("丢弃", 3)
	_context_menu.id_pressed.connect(_on_context)


func _on_context(id: int) -> void:
	if _context_slot_index < 0: return
	var entry := _get_slot(_context_slot_index)
	var item: Item = entry.get("item")
	if item == null: return
	_context_slot_index = -1
	match id:
		0: _show_detail(item, entry.get("count", 1))
		1: _on_use(item.item_id)
		2: _on_equip(item.item_id)
		3: Inventory.remove_item(item.item_id, 1); _refresh()


func _get_slot(idx: int) -> Dictionary:
	var shown := _filtered_slots()
	if idx >= 0 and idx < shown.size(): return shown[idx]
	return {}
