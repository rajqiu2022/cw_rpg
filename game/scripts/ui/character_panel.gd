class_name CharacterPanel
extends Control

## 统一角色 / 属性 / 背包 / 装备界面。
## 旧 InventoryPanel 保留给 I 键；本面板由 C 键打开。

signal closed

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const PANEL_BG := preload("res://art/ui/quest/runtime_v1/panel_bg_v5.png")
const BTN_NORMAL := preload("res://art/ui/button/btn_menu_frame_normal.png")
const BTN_HOVER := preload("res://art/ui/button/btn_menu_frame_hover.png")
const BTN_PRESSED := preload("res://art/ui/button/btn_menu_frame_pressed.png")
const CLOSE_NORMAL := preload("res://art/ui/inventory/buttons/btn_x_normal.png")
const CLOSE_HOVER := preload("res://art/ui/inventory/buttons/btn_x_hover.png")
const CLOSE_PRESSED := preload("res://art/ui/inventory/buttons/btn_x_pressed.png")
const CHARACTER_TITLE_ART := preload("res://art/ui/character/title_character_inventory_v1.png")
const FORMAL_CONFIRM_SCENE := preload("res://scenes/ui/formal_confirm_dialog.tscn")
const READING_PANEL_SCENE := preload("res://scenes/ui/reading_panel.tscn")
const EQUIPMENT_TOOLTIP_BUTTON := preload("res://scripts/ui/equipment_tooltip_button.gd")
const EQUIPMENT_STATS := preload("res://scripts/ui/equipment_stat_presentation.gd")
const CELL_DEFAULT := preload("res://art/ui/inventory/cells/cell_default.png")
const CELL_SELECTED := preload("res://art/ui/inventory/cells/cell_selected.png")
const CELL_EMPTY := preload("res://art/ui/inventory/cells/cell_empty.png")
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

const INVENTORY_FILTERS := {
	"all": "全部",
	"consumable": "消耗",
	"equipment": "装备",
	"key": "剧情",
	"material": "材料",
}
const QUALITY_COLORS := {
	Item.Quality.COMMON: "#c0c8d0",
	Item.Quality.UNCOMMON: "#1eff00",
	Item.Quality.RARE: "#4d8fff",
	Item.Quality.EPIC: "#b56cff",
	Item.Quality.LEGENDARY: "#ff9b38",
}

var _selected_character_id: StringName = &"protagonist"
var _panel: Control
var _character_list: VBoxContainer
var _portrait: TextureRect
var _name_label: Label
var _bio_label: RichTextLabel
var _attribute_label: RichTextLabel
var _hp_bar: ProgressBar
var _mp_bar: ProgressBar
var _hp_bar_label: Label
var _mp_bar_label: Label
var _skill_label: RichTextLabel
var _inventory_grid: GridContainer
var _inventory_detail_icon: TextureRect
var _inventory_detail_label: RichTextLabel
var _inventory_action_button: Button
var _deploy_button: Button
var _inventory_drop_button: Button
var _inventory_filter_buttons: Dictionary = {}
var _equipment_list: VBoxContainer
var _equipment_hint: Label
var _confirm_dialog: FormalConfirmDialog
var _reading_panel: ReadingPanel
var _pending_use_character_id: StringName = &""
var _pending_use_item_id: StringName = &""
var _pending_drop := false
var _inventory_filter := "all"
var _selected_inventory_item: Item
var _selected_inventory_count := 0
var _selected_inventory_instance_id := ""
var _selected_equipment_slot := -1


func _ready() -> void:
	visible = false
	_build_ui()
	_apply_fullscreen_layout()
	Inventory.slots_changed.connect(_refresh)
	GameState.player_changed.connect(_refresh)
	GameState.party_changed.connect(_refresh)
	_refresh()


func open() -> void:
	_apply_fullscreen_layout()
	visible = true
	move_to_front()
	if GameState.get_party_member(_selected_character_id) == null:
		_selected_character_id = &"protagonist"
	_refresh()


func close() -> void:
	if _reading_panel != null and _reading_panel.is_open():
		_reading_panel.close_reader()
		return
	_hide_precious_use_confirmation()
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _reading_panel != null and _reading_panel.is_open():
			_reading_panel.close_reader()
			get_viewport().set_input_as_handled()
			return
		if _confirm_dialog != null and _confirm_dialog.is_open():
			_hide_precious_use_confirmation()
			get_viewport().set_input_as_handled()
			return
		close()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.018, 0.024, 0.58)
	add_child(dim)

	var panel := Control.new()
	_panel = panel
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-780, -465)
	panel.size = Vector2(1560, 930)
	add_child(panel)

	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.texture = PANEL_BG
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	# The quest artwork is reused only as the ornamental outer frame. Cover its
	# authored inner dividers, then lay out this screen's four sections on one
	# clean backing so frame lines cannot cut through the character content.
	var content_backing := Panel.new()
	content_backing.position = Vector2(40, 116)
	content_backing.size = Vector2(1480, 774)
	content_backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backing_style := StyleBoxFlat.new()
	backing_style.bg_color = Color(0.012, 0.030, 0.043, 0.99)
	backing_style.border_color = Color(0.30, 0.61, 0.62, 0.88)
	backing_style.set_border_width_all(2)
	backing_style.set_corner_radius_all(9)
	backing_style.shadow_color = Color(0, 0, 0, 0.55)
	backing_style.shadow_size = 8
	content_backing.add_theme_stylebox_override("panel", backing_style)
	panel.add_child(content_backing)

	var title_art := TextureRect.new()
	title_art.name = "TitleArt"
	title_art.position = Vector2(570, 39)
	title_art.size = Vector2(420, 72)
	title_art.texture = CHARACTER_TITLE_ART
	title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(title_art)

	var close_button := TextureButton.new()
	close_button.position = Vector2(1464, 42)
	close_button.size = Vector2(54, 54)
	close_button.texture_normal = CLOSE_NORMAL
	close_button.texture_hover = CLOSE_HOVER
	close_button.texture_pressed = CLOSE_PRESSED
	close_button.ignore_texture_size = true
	close_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_button.pressed.connect(close)
	panel.add_child(close_button)

	var left := _make_section(panel, Vector2(54, 128), Vector2(300, 742), "队伍")
	var center_top := _make_section(panel, Vector2(376, 128), Vector2(680, 332), "人物属性")
	var center_bottom := _make_section(panel, Vector2(376, 480), Vector2(680, 390), "背包")
	var right := _make_section(panel, Vector2(1078, 128), Vector2(426, 742), "当前装备")

	var character_scroll := ScrollContainer.new()
	character_scroll.position = Vector2(14, 54)
	character_scroll.size = Vector2(272, 612)
	character_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(character_scroll)
	_character_list = VBoxContainer.new()
	_character_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_character_list.add_theme_constant_override("separation", 10)
	character_scroll.add_child(_character_list)
	_deploy_button = Button.new()
	_deploy_button.position = Vector2(20, 678)
	_deploy_button.size = Vector2(260, 44)
	_install_art_button_style(_deploy_button, 17)
	_deploy_button.add_theme_stylebox_override("disabled", _button_texture_style(BTN_NORMAL))
	_deploy_button.pressed.connect(_toggle_deployment)
	left.add_child(_deploy_button)

	_portrait = TextureRect.new()
	_portrait.name = "CharacterPortrait"
	_portrait.position = Vector2(18, 60)
	_portrait.size = Vector2(170, 222)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.clip_contents = true
	center_top.add_child(_portrait)
	_name_label = Label.new()
	_name_label.position = Vector2(210, 56)
	_name_label.size = Vector2(440, 42)
	_name_label.add_theme_font_size_override("font_size", 27)
	_name_label.add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT)
	center_top.add_child(_name_label)
	_bio_label = RichTextLabel.new()
	_bio_label.position = Vector2(210, 102)
	_bio_label.size = Vector2(440, 70)
	_bio_label.bbcode_enabled = true
	_bio_label.fit_content = false
	_bio_label.add_theme_font_size_override("normal_font_size", 15)
	_bio_label.add_theme_color_override("default_color", UI_THEME.MUTED)
	center_top.add_child(_bio_label)
	_hp_bar = _make_character_resource_bar(center_top, Vector2(210, 176), Color(0.70, 0.16, 0.13, 0.96))
	_hp_bar_label = _make_character_resource_label(center_top, Vector2(210, 176))
	_mp_bar = _make_character_resource_bar(center_top, Vector2(210, 207), Color(0.12, 0.45, 0.70, 0.96))
	_mp_bar_label = _make_character_resource_label(center_top, Vector2(210, 207))
	_attribute_label = RichTextLabel.new()
	_attribute_label.position = Vector2(210, 238)
	_attribute_label.size = Vector2(268, 72)
	_attribute_label.bbcode_enabled = true
	_attribute_label.add_theme_font_size_override("normal_font_size", 15)
	center_top.add_child(_attribute_label)
	_skill_label = RichTextLabel.new()
	_skill_label.position = Vector2(480, 176)
	_skill_label.size = Vector2(180, 126)
	_skill_label.bbcode_enabled = true
	_skill_label.add_theme_font_size_override("normal_font_size", 15)
	center_top.add_child(_skill_label)

	_build_inventory_area(center_bottom)

	_equipment_list = VBoxContainer.new()
	_equipment_list.position = Vector2(22, 62)
	_equipment_list.size = Vector2(382, 620)
	_equipment_list.add_theme_constant_override("separation", 12)
	right.add_child(_equipment_list)
	var hint := Label.new()
	_equipment_hint = hint
	hint.position = Vector2(24, 688)
	hint.size = Vector2(378, 36)
	hint.text = "左键查看装备属性；右键卸下装备"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", UI_THEME.MUTED)
	right.add_child(hint)
	_build_precious_use_confirmation()


func _make_character_resource_bar(parent: Control, pos: Vector2, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(250, 24)
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.015, 0.025, 0.030, 0.96)
	background.border_color = Color(0.28, 0.55, 0.58, 0.82)
	background.set_border_width_all(1)
	background.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar


func _make_character_resource_label(parent: Control, pos: Vector2) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = Vector2(250, 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.94, 0.97, 0.98, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _apply_fullscreen_layout() -> void:
	# Field scenes previously treated this resource like the old compact equipment
	# panel and could reset its root anchor to the top-left. Reassert the fullscreen
	# overlay and center the fixed-size artwork every time it opens.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if _panel == null:
		return
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -780.0
	_panel.offset_top = -465.0
	_panel.offset_right = 780.0
	_panel.offset_bottom = 465.0


func _make_section(parent: Control, pos: Vector2, section_size: Vector2, title_text: String) -> Control:
	var section := Control.new()
	section.position = pos
	section.size = section_size
	parent.add_child(section)
	var panel_background := Panel.new()
	panel_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.055, 0.075, 0.90)
	style.border_color = Color(0.24, 0.55, 0.57, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	panel_background.add_theme_stylebox_override("panel", style)
	section.add_child(panel_background)
	var title := Label.new()
	title.position = Vector2(18, 12)
	title.size = Vector2(section_size.x - 36, 34)
	title.text = title_text
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", UI_THEME.JADE)
	section.add_child(title)
	return section


func _build_inventory_area(parent: Control) -> void:
	var tabs := HBoxContainer.new()
	tabs.name = "InventoryFilters"
	tabs.position = Vector2(16, 48)
	tabs.size = Vector2(648, 36)
	tabs.add_theme_constant_override("separation", 7)
	parent.add_child(tabs)
	for key: String in INVENTORY_FILTERS:
		var tab := Button.new()
		tab.name = "Filter%s" % key.capitalize()
		tab.custom_minimum_size = Vector2(124, 34)
		tab.text = INVENTORY_FILTERS[key]
		tab.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tab.pressed.connect(_set_inventory_filter.bind(key))
		tabs.add_child(tab)
		_inventory_filter_buttons[key] = tab

	var inventory_scroll := ScrollContainer.new()
	inventory_scroll.position = Vector2(16, 92)
	inventory_scroll.size = Vector2(432, 280)
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(inventory_scroll)
	_inventory_grid = GridContainer.new()
	_inventory_grid.name = "InventoryGrid"
	_inventory_grid.columns = 5
	_inventory_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inventory_grid.add_theme_constant_override("h_separation", 1)
	_inventory_grid.add_theme_constant_override("v_separation", 4)
	inventory_scroll.add_child(_inventory_grid)

	var detail_panel := Panel.new()
	detail_panel.name = "InventoryDetail"
	detail_panel.position = Vector2(458, 92)
	detail_panel.size = Vector2(206, 280)
	var detail_style := StyleBoxFlat.new()
	detail_style.bg_color = Color(0.01, 0.025, 0.035, 0.92)
	detail_style.border_color = Color(0.18, 0.38, 0.43, 0.76)
	detail_style.set_border_width_all(1)
	detail_style.set_corner_radius_all(5)
	detail_panel.add_theme_stylebox_override("panel", detail_style)
	parent.add_child(detail_panel)

	_inventory_detail_icon = TextureRect.new()
	_inventory_detail_icon.position = Vector2(67, 10)
	_inventory_detail_icon.size = Vector2(72, 72)
	_inventory_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_inventory_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_panel.add_child(_inventory_detail_icon)

	_inventory_detail_label = RichTextLabel.new()
	_inventory_detail_label.name = "InventoryDetailText"
	_inventory_detail_label.position = Vector2(12, 88)
	_inventory_detail_label.size = Vector2(182, 118)
	_inventory_detail_label.bbcode_enabled = true
	_inventory_detail_label.fit_content = false
	_inventory_detail_label.add_theme_font_size_override("normal_font_size", 13)
	_inventory_detail_label.add_theme_color_override("default_color", UI_THEME.TEXT)
	detail_panel.add_child(_inventory_detail_label)

	_inventory_action_button = Button.new()
	_inventory_action_button.name = "InventoryAction"
	_inventory_action_button.position = Vector2(8, 216)
	_inventory_action_button.size = Vector2(92, 52)
	_inventory_action_button.custom_minimum_size = Vector2(92, 52)
	_inventory_action_button.pressed.connect(_on_inventory_action_pressed)
	_install_art_button_style(_inventory_action_button, 17)
	detail_panel.add_child(_inventory_action_button)

	_inventory_drop_button = Button.new()
	_inventory_drop_button.name = "InventoryDrop"
	_inventory_drop_button.position = Vector2(106, 216)
	_inventory_drop_button.size = Vector2(92, 52)
	_inventory_drop_button.custom_minimum_size = Vector2(92, 52)
	_inventory_drop_button.text = "丢弃"
	_inventory_drop_button.pressed.connect(_on_inventory_drop_pressed)
	_install_art_button_style(_inventory_drop_button, 17)
	detail_panel.add_child(_inventory_drop_button)


func _build_precious_use_confirmation() -> void:
	_confirm_dialog = FORMAL_CONFIRM_SCENE.instantiate() as FormalConfirmDialog
	_confirm_dialog.name = "PreciousUseConfirmation"
	_confirm_dialog.confirmed.connect(_confirm_pending_action)
	_confirm_dialog.cancelled.connect(_clear_pending_confirmation)
	add_child(_confirm_dialog)
	_reading_panel = READING_PANEL_SCENE.instantiate() as ReadingPanel
	add_child(_reading_panel)


func _refresh() -> void:
	if _character_list == null:
		return
	_rebuild_character_list()
	_rebuild_character_detail()
	_rebuild_inventory()
	_rebuild_equipment()


func _rebuild_character_list() -> void:
	_clear_children(_character_list)
	var deployed := GameState.get_battle_party()
	for member: CharacterStats in GameState.party:
		if member == null:
			continue
		# Party cards are selectors, not equipment slots. Using the custom
		# equipment tooltip button here created an empty 400px tooltip panel.
		var button := Button.new()
		button.custom_minimum_size = Vector2(264, 100)
		button.text = ""
		_style_button(button, member.character_id == String(_selected_character_id))
		button.pressed.connect(_select_character.bind(StringName(member.character_id)))
		var avatar_frame := Panel.new()
		avatar_frame.position = Vector2(10, 12)
		avatar_frame.size = Vector2(76, 76)
		avatar_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var avatar_style := StyleBoxFlat.new()
		avatar_style.bg_color = Color(0.02, 0.045, 0.06, 1.0)
		avatar_style.border_color = UI_THEME.GOLD_LIGHT if member.character_id == String(_selected_character_id) else Color(0.25, 0.53, 0.56, 0.9)
		avatar_style.set_border_width_all(2)
		avatar_style.set_corner_radius_all(5)
		avatar_frame.add_theme_stylebox_override("panel", avatar_style)
		button.add_child(avatar_frame)
		var avatar := TextureRect.new()
		avatar.position = Vector2(4, 4)
		avatar.size = Vector2(68, 68)
		avatar.texture = _character_avatar(member)
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_frame.add_child(avatar)
		var card_name := Label.new()
		card_name.position = Vector2(100, 17)
		card_name.size = Vector2(150, 30)
		card_name.text = member.display_name
		card_name.add_theme_font_size_override("font_size", 19)
		card_name.add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT if member.character_id == String(_selected_character_id) else UI_THEME.TEXT)
		card_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(card_name)
		var card_meta := Label.new()
		card_meta.position = Vector2(100, 50)
		card_meta.size = Vector2(150, 34)
		card_meta.text = "Lv.%d · %s\n%s" % [member.level, member.role_title, "出战" if member in deployed else "待命"]
		card_meta.add_theme_font_size_override("font_size", 14)
		card_meta.add_theme_color_override("font_color", UI_THEME.MUTED)
		card_meta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card_meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(card_meta)
		_character_list.add_child(button)


func _character_avatar(member: CharacterStats) -> Texture2D:
	if member == null or member.portrait_path.is_empty() or not ResourceLoader.exists(member.portrait_path):
		return null
	var texture := load(member.portrait_path) as Texture2D
	if texture == null or member.character_id == "protagonist":
		return texture
	# Companion sources are full-body identity anchors. Both the party card and
	# the character-detail portrait use this same upper-body avatar crop so a
	# companion never collapses into a tiny full-body figure inside a portrait box.
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	var width := float(texture.get_width())
	var height := float(texture.get_height())
	# Portrait sources have different canvas ratios (square for Shen Qinghe,
	# vertical for Tang Xingzhou). Derive one square head-and-shoulders crop from
	# the shorter side instead of scaling either whole figure into the frame.
	var crop_size := minf(width, height) * 0.38
	atlas.region = Rect2((width - crop_size) * 0.5, height * 0.02, crop_size, crop_size)
	return atlas


func _select_character(character_id: StringName) -> void:
	_selected_character_id = character_id
	_selected_equipment_slot = -1
	_refresh()


func _rebuild_character_detail() -> void:
	var member := GameState.get_party_member(_selected_character_id)
	if member == null:
		return
	var deployed := GameState.get_battle_party()
	_deploy_button.visible = member != GameState.player
	_deploy_button.text = "设为待命" if member in deployed else "安排出战"
	_deploy_button.disabled = member not in deployed and deployed.size() >= GameState.BATTLE_PARTY_LIMIT
	if _deploy_button.disabled:
		_deploy_button.text = "出战已满"
	_deploy_button.tooltip_text = "出战已满。先将一名队友设为待命。" if _deploy_button.disabled else ""
	_portrait.texture = _character_avatar(member)
	_name_label.text = "%s  ·  %s" % [member.display_name, member.role_title]
	var reputation_line := ""
	if member.character_id == &"protagonist":
		reputation_line = "\n[color=#e4bd70]江湖声望 %d · %s[/color]" % [GameState.reputation, GameState.get_reputation_title()]
	_bio_label.text = "[color=#87bfc1]%s[/color]  %s%s" % [member.origin, member.biography, reputation_line]
	var cid := StringName(member.character_id)
	var passive_defense_bonus := 6 if &"qinghe_jade_guard" in member.skills else 0
	_hp_bar.max_value = maxi(1, member.max_hp)
	_hp_bar.value = maxi(0, member.hp)
	_hp_bar_label.text = "生命  %d / %d" % [member.hp, member.max_hp]
	_mp_bar.max_value = maxi(1, member.max_mp)
	_mp_bar.value = maxi(0, member.mp)
	_mp_bar_label.text = "内力  %d / %d" % [member.mp, member.max_mp]
	_attribute_label.text = "筋骨 %d   机敏 %d   内劲 %d\n悟性 %d   生命 %d   防御 %d\n攻击 %d   防御力 %d   速度 %d" % [
		member.strength + Inventory.get_attribute_bonus_for(cid, &"get_strength_bonus"),
		member.agility + Inventory.get_attribute_bonus_for(cid, &"get_agility_bonus"),
		member.inner_power + Inventory.get_attribute_bonus_for(cid, &"get_inner_power_bonus"),
		member.insight + Inventory.get_attribute_bonus_for(cid, &"get_insight_bonus"),
		member.vitality + Inventory.get_attribute_bonus_for(cid, &"get_vitality_bonus"),
		member.guard + Inventory.get_attribute_bonus_for(cid, &"get_guard_bonus"),
		member.attack + Inventory.get_atk_bonus_for(cid), member.defense + Inventory.get_def_bonus_for(cid) + passive_defense_bonus, member.speed + Inventory.get_speed_bonus_for(cid),
	]
	var skill_names: Array[String] = []
	for skill_id: StringName in member.skills:
		if skill_id in [&"basic_attack", &"defend"]:
			continue
		var path := "res://data/skills/%s.tres" % String(skill_id)
		var skill := load(path) as Skill if ResourceLoader.exists(path) else null
		if skill != null:
			var equipped_suffix := "  [已装备]" if skill.is_internal_art and member.equipped_internal_art == skill.skill_id else ""
			skill_names.append("• %s%s" % [skill.display_name, equipped_suffix])
	_skill_label.text = "[color=#e5c06b]武功心法[/color]\n%s\n[color=#82949c]%s[/color]" % ["\n".join(skill_names), "随剧情成长，不可替换" if member.fixed_martial_arts else "主角可在武学界面研习"]


func _toggle_deployment() -> void:
	var member := GameState.get_party_member(_selected_character_id)
	if member != null:
		GameState.set_companion_deployed(_selected_character_id, member not in GameState.get_battle_party())


func _rebuild_inventory() -> void:
	if _inventory_grid == null:
		return
	_clear_children(_inventory_grid)
	_update_inventory_filter_buttons()
	var shown := _filtered_inventory_slots()
	var selected_entry: Dictionary = {}
	for entry: Dictionary in shown:
		if _inventory_entry_is_selected(entry):
			selected_entry = entry
			break
	if selected_entry.is_empty() and not shown.is_empty():
		selected_entry = shown[0]
		_set_selected_inventory_entry(selected_entry)
	elif shown.is_empty():
		_selected_inventory_item = null
		_selected_inventory_count = 0
		_selected_inventory_instance_id = ""

	for entry: Dictionary in shown:
		_inventory_grid.add_child(_make_inventory_cell(entry))
	for _index in range(shown.size(), maxi(15, shown.size())):
		_inventory_grid.add_child(_make_empty_inventory_cell())
	_refresh_inventory_detail()


func _set_inventory_filter(key: String) -> void:
	_inventory_filter = key
	_selected_inventory_item = null
	_selected_inventory_count = 0
	_selected_inventory_instance_id = ""
	_rebuild_inventory()


func _filtered_inventory_slots() -> Array[Dictionary]:
	var shown: Array[Dictionary] = []
	for entry: Dictionary in Inventory.slots:
		var item: Item = entry.get("item")
		if item != null and _inventory_item_passes_filter(item):
			shown.append(entry)
	return shown


func _inventory_item_passes_filter(item: Item) -> bool:
	match _inventory_filter:
		"consumable": return item.category == Item.Category.CONSUMABLE
		"equipment": return item is Equipment
		"key": return item.is_key_item()
		"material": return item.category == Item.Category.MATERIAL
	return true


func _inventory_entry_is_selected(entry: Dictionary) -> bool:
	var item: Item = entry.get("item")
	if item == null or _selected_inventory_item == null:
		return false
	var instance_id := String(entry.get("instance_id", ""))
	if not instance_id.is_empty() or not _selected_inventory_instance_id.is_empty():
		return instance_id == _selected_inventory_instance_id
	return item.item_id == _selected_inventory_item.item_id


func _set_selected_inventory_entry(entry: Dictionary) -> void:
	_selected_inventory_item = entry.get("item")
	_selected_inventory_count = int(entry.get("count", 0))
	_selected_inventory_instance_id = String(entry.get("instance_id", ""))


func _make_inventory_cell(entry: Dictionary) -> TextureButton:
	var item: Item = entry.get("item")
	var count := int(entry.get("count", 0))
	var instance_id := String(entry.get("instance_id", ""))
	var selected := _inventory_entry_is_selected(entry)
	var equipped_owner := Inventory.get_instance_equipped_character_id(instance_id) if item is Equipment else &""
	var occupied_by_other := equipped_owner != &"" and equipped_owner != _selected_character_id
	var cell := TextureButton.new()
	cell.custom_minimum_size = Vector2(84, 82)
	cell.ignore_texture_size = true
	cell.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	cell.texture_normal = CELL_SELECTED if selected else CELL_DEFAULT
	cell.texture_hover = CELL_SELECTED
	cell.texture_pressed = CELL_SELECTED
	cell.mouse_default_cursor_shape = Control.CURSOR_ARROW if occupied_by_other else Control.CURSOR_POINTING_HAND
	cell.tooltip_text = "%s\n%s" % [item.display_name, item.description]
	if occupied_by_other:
		var owner := GameState.get_party_member(equipped_owner)
		var owner_name := owner.display_name if owner != null else String(equipped_owner)
		cell.tooltip_text += "\n已由%s装备，需先为其卸下。" % owner_name
		cell.modulate = Color(0.42, 0.44, 0.47, 0.88)
	cell.pressed.connect(_select_inventory_entry.bind(entry))
	cell.gui_input.connect(_on_inventory_cell_input.bind(entry))
	_add_inventory_quality_frame(cell, item)

	var icon := TextureRect.new()
	icon.position = Vector2(13, 5)
	icon.size = Vector2(58, 49)
	icon.texture = _resolve_inventory_icon(item)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(icon)

	var name_label := Label.new()
	name_label.position = Vector2(3, 55)
	name_label.size = Vector2(78, 22)
	name_label.text = item.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color.from_string(String(QUALITY_COLORS.get(item.quality, "#c0c8d0")), UI_THEME.TEXT))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(name_label)

	if item.stackable and count > 1:
		var count_label := Label.new()
		count_label.position = Vector2(58, 2)
		count_label.size = Vector2(21, 20)
		count_label.text = str(count)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_label.add_theme_font_size_override("font_size", 13)
		count_label.add_theme_color_override("font_color", Color.WHITE)
		count_label.add_theme_color_override("font_outline_color", Color.BLACK)
		count_label.add_theme_constant_override("outline_size", 3)
		count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(count_label)

	if item is Equipment and Inventory.is_instance_equipped(instance_id):
		var equipped_label := Label.new()
		equipped_label.position = Vector2(4, 2)
		equipped_label.size = Vector2(30, 20)
		equipped_label.text = "占" if occupied_by_other else "装"
		equipped_label.add_theme_font_size_override("font_size", 12)
		equipped_label.add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT)
		equipped_label.add_theme_color_override("font_outline_color", Color.BLACK)
		equipped_label.add_theme_constant_override("outline_size", 3)
		equipped_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(equipped_label)
	return cell


func _make_empty_inventory_cell() -> TextureRect:
	var cell := TextureRect.new()
	cell.custom_minimum_size = Vector2(84, 82)
	cell.texture = CELL_EMPTY
	cell.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cell.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cell


func _select_inventory_entry(entry: Dictionary) -> void:
	_selected_equipment_slot = -1
	_set_selected_inventory_entry(entry)
	_rebuild_inventory()
	_rebuild_equipment()


func _on_inventory_cell_input(event: InputEvent, entry: Dictionary) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_selected_equipment_slot = -1
			_set_selected_inventory_entry(entry)
			_on_inventory_action_pressed()


func _refresh_inventory_detail() -> void:
	if _inventory_detail_label == null:
		return
	if _selected_inventory_item == null:
		_inventory_detail_icon.texture = null
		_inventory_detail_label.text = "[center][color=#82949c]此分类暂无物品[/color][/center]"
		_inventory_action_button.text = "不可操作"
		_inventory_action_button.disabled = true
		_inventory_drop_button.disabled = true
		return
	var item := _selected_inventory_item
	_inventory_detail_icon.texture = _resolve_inventory_icon(item)
	var quality_color: String = QUALITY_COLORS.get(item.quality, "#c0c8d0")
	var target := GameState.get_party_member(_selected_character_id)
	var target_name := target.display_name if target != null else "冷孤云"
	var detail_lines: Array[String] = [
		"[center][font_size=16][color=%s]%s[/color][/font_size][/center]" % [quality_color, item.display_name],
		"[color=#82949c]%s · ×%d[/color]" % [_inventory_category_name(item), _selected_inventory_count],
	]
	if item is Equipment:
		detail_lines.append(_equipment_stats_bbcode(item as Equipment))
	detail_lines.append(item.description)
	detail_lines.append("[color=#e5c06b]当前角色：%s[/color]" % target_name)
	_inventory_detail_label.text = "\n".join(detail_lines)
	if item is Equipment:
		var equipped_owner := Inventory.get_instance_equipped_character_id(_selected_inventory_instance_id)
		var occupied_by_other := equipped_owner != &"" and equipped_owner != _selected_character_id
		if occupied_by_other:
			var owner := GameState.get_party_member(equipped_owner)
			var owner_name := owner.display_name if owner != null else String(equipped_owner)
			detail_lines.append("[color=#82949c]已由%s装备；请先切换到该角色卸下。[/color]" % owner_name)
			_inventory_detail_label.text = "\n".join(detail_lines)
			_inventory_action_button.text = "队友占用"
			_inventory_action_button.disabled = true
		else:
			_inventory_action_button.text = "卸下" if _selected_equipment_is_worn_by_current_character() else "装备"
			_inventory_action_button.disabled = _selected_inventory_instance_id.is_empty()
	elif item.is_readable():
		_inventory_action_button.text = "阅读"
		_inventory_action_button.disabled = false
	elif item.category == Item.Category.CONSUMABLE:
		_inventory_action_button.text = "使用"
		_inventory_action_button.disabled = false
	else:
		_inventory_action_button.text = "不可使用"
		_inventory_action_button.disabled = true
	_inventory_drop_button.disabled = false


func _on_inventory_action_pressed() -> void:
	if _selected_inventory_item == null:
		return
	if _selected_inventory_item.is_readable():
		if _reading_panel != null:
			_reading_panel.open_item(_selected_inventory_item)
		return
	if _selected_inventory_item is Equipment and not _selected_inventory_instance_id.is_empty():
		var equipment := _selected_inventory_item as Equipment
		var equipped_owner := Inventory.get_instance_equipped_character_id(_selected_inventory_instance_id)
		if equipped_owner != &"" and equipped_owner != _selected_character_id:
			return
		if _selected_equipment_is_worn_by_current_character():
			Inventory.unequip_for(_selected_character_id, equipment.slot)
		else:
			Inventory.equip_instance_for(_selected_character_id, _selected_inventory_instance_id)
	elif _selected_inventory_item.category == Item.Category.CONSUMABLE:
		if _requires_precious_use_confirmation(_selected_inventory_item):
			_show_precious_use_confirmation(_selected_inventory_item)
			return
		_use_consumable_for(_selected_character_id, _selected_inventory_item.item_id)
	_refresh()


func _requires_precious_use_confirmation(item: Item) -> bool:
	return (
		item != null
		and item.category == Item.Category.CONSUMABLE
		and item.permanent_growth
		and item.quality >= Item.Quality.EPIC
	)


func _show_precious_use_confirmation(item: Item) -> void:
	var target := GameState.get_party_member(_selected_character_id)
	if target == null or _confirm_dialog == null:
		return
	_pending_use_character_id = _selected_character_id
	_pending_use_item_id = item.item_id
	_pending_drop = false
	var quality_color: String = QUALITY_COLORS.get(item.quality, "#b56cff")
	var message := "[center]是否给 [color=#e5c06b]%s[/color] 使用\n[color=%s]%s[/color]？\n\n[color=#d6c4a4]该物品会永久增加属性或上限，使用后无法撤销。[/color][/center]" % [
		target.display_name, quality_color, item.display_name,
	]
	_confirm_dialog.show_confirm("确认使用珍贵丹药", message, "确认使用", "取消")


func _hide_precious_use_confirmation() -> void:
	_clear_pending_confirmation()
	if _confirm_dialog != null:
		_confirm_dialog.close_dialog()


func _clear_pending_confirmation() -> void:
	_pending_use_character_id = &""
	_pending_use_item_id = &""
	_pending_drop = false


func _confirm_pending_action() -> void:
	var character_id := _pending_use_character_id
	var item_id := _pending_use_item_id
	var should_drop := _pending_drop
	_hide_precious_use_confirmation()
	if item_id == &"":
		return
	if should_drop:
		_drop_selected_inventory_item()
	elif character_id != &"":
		_use_consumable_for(character_id, item_id)
	_refresh()


func _use_consumable_for(character_id: StringName, item_id: StringName) -> bool:
	var item := Inventory.load_item_by_id(item_id)
	var target := GameState.get_party_member(character_id)
	if item == null or target == null:
		_show_item_effect_tip("[color=#ff876f]道具使用失败[/color]")
		return false
	var old_hp := target.hp
	var old_mp := target.mp
	var old_max_hp := target.max_hp
	var old_max_mp := target.max_mp
	if not Inventory.use_item_for(character_id, item_id, false):
		_show_item_effect_tip("[color=#ff876f]%s 当前无法使用[/color]" % item.display_name)
		return false
	var lines: Array[String] = [
		"[center][color=#e5c06b]%s 使用了 %s[/color][/center]" % [target.display_name, item.display_name],
	]
	if target.max_hp > old_max_hp:
		lines.append(_item_effect_line("生命上限", target.max_hp - old_max_hp, "#ffad78"))
	if target.max_mp > old_max_mp:
		lines.append(_item_effect_line("内功上限", target.max_mp - old_max_mp, "#75cfff"))
	if target.hp > old_hp:
		lines.append(_item_effect_line("生命", target.hp - old_hp, "#ff7f7f"))
	if target.mp > old_mp:
		lines.append(_item_effect_line("内功", target.mp - old_mp, "#72bfff"))
	if lines.size() == 1:
		match String(item_id):
			"antidote_pill", "thaw_warm_pill": lines.append("[center][color=#72d2a6]已解除中毒[/color][/center]")
			"anti_weak_powder": lines.append("[center][color=#72d2a6]已解除虚弱[/color][/center]")
			"clarity_dew": lines.append("[center][color=#72d2a6]已解除异常状态[/color][/center]")
			_: lines.append("[center][color=#72d2a6]道具效果已生效[/color][/center]")
	_show_item_effect_tip("\n".join(lines))
	return true


func _item_effect_line(label_text: String, amount: int, color_hex: String) -> String:
	return "[center][color=#c7d5d9]%s[/color] [color=%s]+%d[/color][/center]" % [label_text, color_hex, amount]


func _show_item_effect_tip(bbcode: String) -> void:
	var existing := get_node_or_null("ItemEffectToast")
	if existing != null:
		existing.queue_free()
	var toast := PanelContainer.new()
	toast.name = "ItemEffectToast"
	toast.z_index = 300
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.custom_minimum_size = Vector2(420, 90)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.035, 0.045, 0.94)
	style.border_color = Color(0.31, 0.72, 0.72, 0.92)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(0, 0, 0, 0.66)
	style.shadow_size = 10
	toast.add_theme_stylebox_override("panel", style)
	var label := RichTextLabel.new()
	label.name = "EffectText"
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size = Vector2(380, 64)
	label.add_theme_font_size_override("normal_font_size", 19)
	label.add_theme_constant_override("line_separation", 4)
	label.text = bbcode
	toast.add_child(label)
	add_child(toast)
	toast.reset_size()
	var viewport_size := get_viewport_rect().size
	toast.position = Vector2(viewport_size.x * 0.5 - 210.0, viewport_size.y * 0.36)
	var tween := create_tween()
	tween.tween_interval(0.35)
	tween.tween_property(toast, "position", toast.position + Vector2(0, -46), 1.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(toast, "modulate:a", 0.0, 1.45).set_delay(0.45)
	tween.tween_callback(toast.queue_free)


func _on_inventory_drop_pressed() -> void:
	if _selected_inventory_item == null:
		return
	if _selected_inventory_item.is_key_item():
		_confirm_dialog.show_notice("无法丢弃", "[center]剧情物品不能丢弃。[/center]")
		return
	_pending_drop = true
	_pending_use_character_id = &""
	_pending_use_item_id = _selected_inventory_item.item_id
	var quality_color: String = QUALITY_COLORS.get(_selected_inventory_item.quality, "#c0c8d0")
	var message := "[center]是否丢弃\n[color=%s]%s[/color]？\n\n[color=#d6c4a4]丢弃后将从背包中移除，无法撤销。[/color][/center]" % [
		quality_color, _selected_inventory_item.display_name,
	]
	_confirm_dialog.show_confirm("确认丢弃物品", message, "确认丢弃", "取消")


func _drop_selected_inventory_item() -> void:
	if _selected_inventory_item == null:
		return
	if not _selected_inventory_instance_id.is_empty():
		Inventory.remove_instance(_selected_inventory_instance_id)
	else:
		Inventory.remove_item(_selected_inventory_item.item_id, 1)
	_selected_inventory_item = null
	_selected_inventory_count = 0
	_selected_inventory_instance_id = ""
	_refresh()


func _update_inventory_filter_buttons() -> void:
	for key: String in _inventory_filter_buttons:
		_style_inventory_filter_button(_inventory_filter_buttons[key], key == _inventory_filter)


func _style_inventory_filter_button(button: Button, selected: bool) -> void:
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT if selected else UI_THEME.MUTED)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.075, 0.15, 0.17, 0.98) if selected else Color(0.018, 0.038, 0.052, 0.72)
	normal.border_color = UI_THEME.JADE if selected else Color(0.18, 0.38, 0.43, 0.70)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.08, 0.18, 0.21, 0.98)
	hover.border_color = UI_THEME.JADE
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)


func _resolve_inventory_icon(item: Item) -> Texture2D:
	if not item.icon_path.is_empty() and ResourceLoader.exists(item.icon_path):
		return load(item.icon_path)
	if item is Equipment:
		return _equipment_slot_icon((item as Equipment).slot)
	match item.category:
		Item.Category.CONSUMABLE: return ICON_POTION
		Item.Category.MATERIAL: return ICON_ORE
		Item.Category.KEY_ITEM: return ICON_KEY
	return ICON_SCROLL


func _equipment_slot_icon(slot: int) -> Texture2D:
	match slot:
		Equipment.Slot.WEAPON: return ICON_WEAPON
		Equipment.Slot.HEAD: return ICON_HEAD
		Equipment.Slot.ARMOR: return ICON_ARMOR
		Equipment.Slot.HANDS: return ICON_HANDS
		Equipment.Slot.SHOES: return ICON_SHOES
		Equipment.Slot.ACCESSORY: return ICON_RING
	return ICON_SCROLL


func _add_inventory_quality_frame(cell: Control, item: Item) -> void:
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


func _inventory_category_name(item: Item) -> String:
	if item is Equipment:
		return "装备"
	match item.category:
		Item.Category.CONSUMABLE: return "消耗品"
		Item.Category.KEY_ITEM: return "剧情物品"
		Item.Category.MATERIAL: return "材料"
	return "物品"


func _rebuild_equipment() -> void:
	_clear_children(_equipment_list)
	var candidate := _selected_inventory_item as Equipment if _selected_inventory_item is Equipment else null
	if candidate != null and not _selected_equipment_is_worn_by_current_character():
		var currently_equipped := Inventory.get_equipped_for(_selected_character_id, candidate.slot)
		if currently_equipped != null:
			if _equipment_hint != null:
				_equipment_hint.text = "点击左侧“装备”完成更换"
			_build_equipment_comparison(candidate, currently_equipped)
			return
	if _equipment_hint != null:
		_equipment_hint.text = "左键查看装备属性；右键卸下装备"
	for slot: int in Inventory.all_slots():
		var equipment := Inventory.get_equipped_for(_selected_character_id, slot)
		var button := EQUIPMENT_TOOLTIP_BUTTON.new()
		button.name = "EquipmentSlot%d" % slot
		button.custom_minimum_size = Vector2(378, 82)
		button.text = ""
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_style_equipment_slot_button(button, equipment != null, slot == _selected_equipment_slot)
		button.disabled = equipment == null
		if equipment != null:
			var quality_color := Color.from_string(String(QUALITY_COLORS.get(equipment.quality, "#c0c8d0")), Color("#c0c8d0"))
			button.set_quality_color(quality_color)
			button.set_stat_rows(EQUIPMENT_STATS.rows(equipment))
			button.tooltip_text = _equipment_tooltip(equipment)
		var icon := TextureRect.new()
		icon.name = "EquipmentSlotIcon"
		icon.position = Vector2(14, 9)
		icon.size = Vector2(64, 64)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _resolve_inventory_icon(equipment) if equipment != null else _equipment_slot_icon(slot)
		icon.modulate.a = 1.0 if equipment != null else 0.45
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		var slot_label := Label.new()
		slot_label.name = "EquipmentSlotLabel"
		slot_label.text = Inventory.slot_display_name(slot)
		slot_label.position = Vector2(94, 10)
		slot_label.size = Vector2(268, 22)
		slot_label.add_theme_font_size_override("font_size", 15)
		slot_label.add_theme_color_override("font_color", UI_THEME.MUTED)
		slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(slot_label)
		var name_label := Label.new()
		name_label.name = "EquipmentSlotName"
		name_label.text = equipment.display_name if equipment != null else "未装备"
		name_label.position = Vector2(94, 36)
		name_label.size = Vector2(268, 30)
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.clip_text = true
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.add_theme_color_override("font_color", Color.from_string(String(QUALITY_COLORS.get(equipment.quality, "#c0c8d0")), UI_THEME.TEXT) if equipment != null else UI_THEME.MUTED)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(name_label)
		button.pressed.connect(_select_equipment_slot.bind(slot))
		button.gui_input.connect(_on_equipment_slot_input.bind(slot))
		_equipment_list.add_child(button)


func _build_equipment_comparison(candidate: Equipment, currently_equipped: Equipment) -> void:
	var comparison := VBoxContainer.new()
	comparison.name = "EquipmentComparison"
	comparison.custom_minimum_size = Vector2(378, 600)
	comparison.add_theme_constant_override("separation", 8)
	_equipment_list.add_child(comparison)

	var heading := Label.new()
	heading.text = "同部位对比 · %s" % Inventory.slot_display_name(candidate.slot)
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT)
	comparison.add_child(heading)

	var current_card := PanelContainer.new()
	current_card.name = "EquippedComparisonCard"
	current_card.custom_minimum_size = Vector2(378, 112)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.018, 0.045, 0.058, 0.96)
	card_style.border_color = Color(0.28, 0.61, 0.62, 0.90)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(6)
	card_style.content_margin_left = 12
	card_style.content_margin_right = 12
	card_style.content_margin_top = 10
	card_style.content_margin_bottom = 10
	current_card.add_theme_stylebox_override("panel", card_style)
	comparison.add_child(current_card)

	var current_row := HBoxContainer.new()
	current_row.add_theme_constant_override("separation", 12)
	current_card.add_child(current_row)
	var current_icon := TextureRect.new()
	current_icon.custom_minimum_size = Vector2(78, 78)
	current_icon.texture = _resolve_inventory_icon(currently_equipped)
	current_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	current_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	current_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_row.add_child(current_icon)
	var current_identity := VBoxContainer.new()
	current_identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_row.add_child(current_identity)
	var state_label := Label.new()
	state_label.text = "当前已装备"
	state_label.add_theme_font_size_override("font_size", 15)
	state_label.add_theme_color_override("font_color", UI_THEME.MUTED)
	current_identity.add_child(state_label)
	var name_label := Label.new()
	name_label.name = "EquippedComparisonName"
	name_label.text = currently_equipped.display_name
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.add_theme_color_override("font_color", Color.from_string(String(QUALITY_COLORS.get(currently_equipped.quality, "#c0c8d0")), UI_THEME.TEXT))
	current_identity.add_child(name_label)
	var slot_label := Label.new()
	slot_label.text = "左侧候选：%s" % candidate.display_name
	slot_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	slot_label.add_theme_font_size_override("font_size", 14)
	slot_label.add_theme_color_override("font_color", UI_THEME.JADE)
	current_identity.add_child(slot_label)

	var current_stats := RichTextLabel.new()
	current_stats.name = "EquippedComparisonStats"
	current_stats.custom_minimum_size = Vector2(378, 158)
	current_stats.bbcode_enabled = true
	current_stats.fit_content = false
	current_stats.add_theme_font_size_override("normal_font_size", 16)
	current_stats.add_theme_color_override("default_color", UI_THEME.TEXT)
	current_stats.text = "[color=#82949c]当前装备属性[/color]\n%s" % _equipment_stats_multiline_bbcode(currently_equipped)
	comparison.add_child(current_stats)

	var delta_heading := Label.new()
	delta_heading.text = "装备后变化"
	delta_heading.add_theme_font_size_override("font_size", 18)
	delta_heading.add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT)
	comparison.add_child(delta_heading)

	var delta_label := RichTextLabel.new()
	delta_label.name = "EquipmentComparisonDelta"
	delta_label.custom_minimum_size = Vector2(378, 190)
	delta_label.bbcode_enabled = true
	delta_label.fit_content = false
	delta_label.add_theme_font_size_override("normal_font_size", 16)
	delta_label.add_theme_color_override("default_color", UI_THEME.TEXT)
	delta_label.text = _equipment_comparison_delta_bbcode(candidate, currently_equipped)
	comparison.add_child(delta_label)

	var hint := Label.new()
	hint.text = "绿色为提升，红色为下降"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", UI_THEME.MUTED)
	comparison.add_child(hint)


func _equipment_stats_multiline_bbcode(equipment: Equipment) -> String:
	var quality_color: String = QUALITY_COLORS.get(equipment.quality, "#c0c8d0")
	return EQUIPMENT_STATS.bbcode(equipment, quality_color)


func _equipment_comparison_delta_bbcode(candidate: Equipment, currently_equipped: Equipment) -> String:
	var rows: Array[String] = []
	_append_equipment_delta(rows, "攻击", candidate.atk_bonus - currently_equipped.atk_bonus)
	_append_equipment_delta(rows, "防御", candidate.def_bonus - currently_equipped.def_bonus)
	_append_equipment_delta(rows, "守御", candidate.get_guard_bonus() - currently_equipped.get_guard_bonus())
	_append_equipment_delta(rows, "速度", candidate.speed_bonus - currently_equipped.speed_bonus)
	_append_equipment_delta(rows, "筋骨", candidate.get_strength_bonus() - currently_equipped.get_strength_bonus())
	_append_equipment_delta(rows, "机敏", candidate.get_agility_bonus() - currently_equipped.get_agility_bonus())
	_append_equipment_delta(rows, "内劲", candidate.get_inner_power_bonus() - currently_equipped.get_inner_power_bonus())
	_append_equipment_delta(rows, "悟性", candidate.get_insight_bonus() - currently_equipped.get_insight_bonus())
	_append_equipment_delta(rows, "生命", candidate.get_vitality_bonus() - currently_equipped.get_vitality_bonus())
	_append_equipment_delta(rows, "内力", candidate.get_inner_pool_bonus() - currently_equipped.get_inner_pool_bonus())
	_append_equipment_delta(rows, "暴击率", int(round((candidate.get_crit_chance_bonus() - currently_equipped.get_crit_chance_bonus()) * 100.0)), "%")
	_append_equipment_delta(rows, "命中率", int(round((candidate.get_hit_chance_bonus() - currently_equipped.get_hit_chance_bonus()) * 100.0)), "%")
	_append_equipment_delta(rows, "兵器招式系数", candidate.get_weapon_skill_scaling_bonus() - currently_equipped.get_weapon_skill_scaling_bonus(), "%")
	_append_equipment_delta(rows, "武功系数", candidate.get_skill_scaling_bonus() - currently_equipped.get_skill_scaling_bonus(), "%")
	if rows.is_empty():
		rows.append("[color=#9aa8ad]基础属性没有变化[/color]")
	var current_effect := currently_equipped.special_effect_description.strip_edges()
	var candidate_effect := candidate.special_effect_description.strip_edges()
	if current_effect != candidate_effect:
		if not current_effect.is_empty():
			rows.append("[color=%s]将失去：%s[/color]" % [QUALITY_COLORS.get(currently_equipped.quality, "#c0c8d0"), current_effect])
		if not candidate_effect.is_empty():
			rows.append("[color=%s]将获得：%s[/color]" % [QUALITY_COLORS.get(candidate.quality, "#c0c8d0"), candidate_effect])
	return "\n".join(rows)


func _append_equipment_delta(rows: Array[String], label: String, delta: int, suffix: String = "") -> void:
	if delta == 0:
		return
	var color := "#73d99b" if delta > 0 else "#ff8770"
	rows.append("[color=%s]%s %s%d%s[/color]" % [color, label, "+" if delta > 0 else "", delta, suffix])


func _select_equipment_slot(slot: int) -> void:
	var equipment := Inventory.get_equipped_for(_selected_character_id, slot)
	if equipment == null:
		return
	var instance_id := Inventory.get_equipped_instance_id_for(_selected_character_id, slot)
	var entry := Inventory.find_slot_by_instance(instance_id)
	if entry.is_empty():
		return
	_set_selected_inventory_entry(entry)
	_selected_equipment_slot = slot
	_refresh_inventory_detail()
	_rebuild_equipment()


func _on_equipment_slot_input(event: InputEvent, slot: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			_unequip_slot(slot)
			get_viewport().set_input_as_handled()


func _unequip_slot(slot: int) -> void:
	Inventory.unequip_for(_selected_character_id, slot)
	_selected_equipment_slot = -1
	_refresh()


func _selected_equipment_is_worn_by_current_character() -> bool:
	if not (_selected_inventory_item is Equipment) or _selected_inventory_instance_id.is_empty():
		return false
	var equipment := _selected_inventory_item as Equipment
	return Inventory.get_equipped_instance_id_for(_selected_character_id, equipment.slot) == _selected_inventory_instance_id


func _equipment_stats_bbcode(equipment: Equipment) -> String:
	var quality_color: String = QUALITY_COLORS.get(equipment.quality, "#c0c8d0")
	return EQUIPMENT_STATS.bbcode(equipment, quality_color, "  ")


func _equipment_stat_lines(equipment: Equipment) -> Array[String]:
	var stats: Array[String] = []
	for row in EQUIPMENT_STATS.rows(equipment):
		stats.append(row.text)
	return stats


func _martial_style_display_name(style: StringName) -> String:
	match style:
		&"sword": return "剑法"
		&"blade": return "刀法"
		&"staff": return "棍法"
		&"palm": return "掌法"
		&"hidden": return "暗器"
		&"dagger": return "短兵"
	return "兵器"


func _equipment_tooltip(equipment: Equipment) -> String:
	var stats := _equipment_stat_lines(equipment)
	return EQUIPMENT_TOOLTIP_BUTTON.compose_text(equipment.display_name, stats)


func _append_equipment_stat(stats: Array[String], label: String, value: int) -> void:
	if value != 0:
		stats.append("%s %+d" % [label, value])


func _school_display_name(school: String) -> String:
	match school:
		"linxi": return "林西"
		"gufeng": return "古峰"
		"huashan": return "华山"
		"lingyue": return "凌月"
		"mingwu": return "茗雾"
		"wudang": return "武当"
	return school


func _style_equipment_slot_button(button: Button, occupied: bool, selected: bool) -> void:
	_style_button(button, selected)
	if occupied and not selected:
		button.add_theme_color_override("font_color", UI_THEME.TEXT)
	var normal := button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	if selected:
		normal.bg_color = Color(0.075, 0.16, 0.19, 0.98)
		normal.border_color = UI_THEME.JADE
		normal.set_border_width_all(2)
	elif occupied:
		normal.bg_color = Color(0.035, 0.07, 0.09, 0.92)
		normal.border_color = Color(0.22, 0.46, 0.49, 0.78)
	button.add_theme_stylebox_override("normal", normal)


func _style_button(button: Button, selected: bool) -> void:
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT if selected else UI_THEME.TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.11, 0.14, 0.94) if selected else Color(0.018, 0.038, 0.052, 0.82)
	normal.border_color = Color(0.46, 0.78, 0.75, 0.92) if selected else Color(0.18, 0.38, 0.43, 0.72)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 16
	normal.content_margin_right = 12
	normal.content_margin_top = 7
	normal.content_margin_bottom = 7
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.08, 0.18, 0.21, 0.98)
	hover.border_color = UI_THEME.JADE
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)


func _install_art_button_style(button: Button, font_size: int = 18) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", UI_THEME.GOLD_LIGHT)
	button.add_theme_color_override("font_disabled_color", Color(0.60, 0.68, 0.72, 0.88))
	button.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.98))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", _button_texture_style(BTN_NORMAL))
	button.add_theme_stylebox_override("hover", _button_texture_style(BTN_HOVER))
	button.add_theme_stylebox_override("pressed", _button_texture_style(BTN_PRESSED))
	button.add_theme_stylebox_override("focus", _button_texture_style(BTN_HOVER))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _button_texture_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 24.0
	style.texture_margin_right = 24.0
	style.texture_margin_top = 12.0
	style.texture_margin_bottom = 12.0
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style


func _clear_children(container: Node) -> void:
	for child: Node in container.get_children():
		child.queue_free()

