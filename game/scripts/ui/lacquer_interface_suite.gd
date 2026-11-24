extends RefCounted

const ART := preload("res://scripts/ui/lacquer_ui.gd")
const SCREENS := {
	"res://scenes/ui/system_menu.tscn": &"system",
	"res://scenes/ui/save_slot_panel.tscn": &"save_slots",
	"res://scenes/ui/character_panel.tscn": &"character",
	"res://scenes/ui/quest_panel.tscn": &"quest",
	"res://scenes/ui/skill_panel.tscn": &"skill",
	"res://scenes/ui/formal_confirm_dialog.tscn": &"confirm",
	"res://scenes/ui/formal_choice_menu.tscn": &"choice",
	"res://scenes/shop.tscn": &"shop",
	"res://scenes/result_victory.tscn": &"victory",
	"res://scenes/result_defeat.tscn": &"defeat",
}

static func screen_for(node: Control) -> StringName:
	var scene_kind: StringName = SCREENS.get(node.scene_file_path, &"")
	if scene_kind != &"":
		return scene_kind
	var script: Script = node.get_script()
	if script != null and script.resource_path == "res://scripts/ui/life_skills_journal.gd":
		return &"life"
	return &""

static func apply(root: Control, screen: StringName) -> void:
	if not is_instance_valid(root) or not root.is_inside_tree():
		return
	match screen:
		&"system": _system(root)
		&"save_slots": _save_slots(root)
		&"character": _character(root)
		&"quest": _quest(root)
		&"skill": _skill(root)
		&"life": _life(root)
		&"confirm", &"choice": _dialog(root, screen)
		&"shop": _shop(root)
		&"victory": _result(root, true)
		&"defeat": _result(root, false)

static func _watch_rows(container: Node, skin: Callable) -> void:
	for child in container.get_children():
		skin.call(child)
	container.child_entered_tree.connect(func(child: Node) -> void:
		_skin_row_if_alive.call_deferred(weakref(child), skin)
	)

static func _skin_row_if_alive(row_ref: WeakRef, skin: Callable) -> void:
	var child := row_ref.get_ref() as Node
	if is_instance_valid(child) and not child.is_queued_for_deletion() and skin.is_valid():
		skin.call(child)

static func _split_sections(parent: Control) -> void:
	ART.section(parent, Rect2(56, 128, 328, 622))
	ART.section(parent, Rect2(400, 128, 746, 622))

static func _dialog(root: Control, screen: StringName) -> void:
	if screen == &"confirm":
		preload("res://scripts/ui/confirm_layout.gd").install(root)
		return
	var parent := root.get_parent()
	while parent is Control:
		if screen_for(parent) in [&"system", &"save_slots", &"character", &"quest", &"skill"] or parent.name == "LacquerCraftingPanel":
			ART.use_frame(root.get_node("PanelArt"))
			_watch_rows(root.get_node("%ChoiceGrid"), _skin_card_button)
			return
		parent = parent.get_parent()

static func _system(root: Control) -> void:
	var panel := root.get_node("Panel") as Control
	var content := panel.get_node("Content") as Control
	var frame := panel.get_node("PanelArt") as TextureRect
	ART.use_frame(frame)
	_split_sections(panel)
	content.get_node("Title").hide()
	ART.title(content, ART.Heading.SYSTEM, Rect2(410, 30, 380, 92))
	var words := [ART.Caption.SETTINGS, ART.Caption.SAVE, ART.Caption.LOAD]
	var names := ["SettingsBtn", "SaveBtn", "LoadBtn"]
	for index in names.size():
		var button := content.get_node(names[index]) as Button
		ART.style_button(button)
		ART.caption(button, words[index])
	ART.place_close_button(content.get_node("CloseBtn"), frame)

static func _save_slots(root: Control) -> void:
	if not bool(root.get("embedded")):
		var legacy_title := root.get("_frame_title") as Label
		if is_instance_valid(legacy_title):
			var frame := legacy_title.get_parent() as Control
			ART.use_frame(frame.get_child(0))
			_split_sections(frame)
			legacy_title.hide()
			ART.title(frame, ART.Heading.SYSTEM, Rect2(410, 30, 380, 92))
	for key in ["_btn_confirm", "_btn_cancel"]:
		ART.style_button(root.get(key))
	var panel := root as SaveSlotPanel
	var preview := TextureRect.new()
	preview.name = "SavedScenePreview"
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.position = Vector2(459, 420)
	preview.size = Vector2(605, 202)
	preview.hide()
	root.get_node("Content").add_child(preview)
	panel._description.size.y = 92
	panel._description.position.y = 326
	panel._progress.position.y = 276
	panel._timestamp.position.y = 230
	var slots := panel._slot_container
	slots.add_theme_constant_override("separation", 6 if panel.embedded else 10)
	_watch_rows(slots, _style_save_slot.bind(panel))

static func _style_save_slot(button: Button, panel: SaveSlotPanel) -> void:
	var preview := panel.get_node("Content/SavedScenePreview") as TextureRect
	var slot := button.get_index()
	button.pressed.connect(_display_slot_preview.bind(preview, slot))
	if panel._selected_slot < 0:
		preview.hide()
	elif button.button_pressed:
		_display_slot_preview(preview, slot)
	var meta := panel._slot_metadata[button.get_index()]
	var occupied := bool(meta.get("exists", false))
	var caption := "空存档" if meta.is_empty() else "时间未记录"
	if occupied and int(meta.get("timestamp", 0)) > 0:
		caption = SaveManager.format_timestamp(int(meta.timestamp))

	button.custom_minimum_size.y = 56 if panel.embedded else 72
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.accessibility_description = caption
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color("#e7ddc8"))
	button.add_theme_color_override("font_pressed_color", Color("#ffe2a4"))
	button.add_theme_color_override("font_hover_pressed_color", Color("#ffe2a4"))
	button.add_theme_color_override("font_disabled_color", Color("#a6b0ae"))
	var selected := _save_slot_surface(Color("#253b3c"), Color("#c3a364"), 4)
	button.add_theme_stylebox_override("normal", _save_slot_surface(Color("#152329"), Color("#586466")))
	button.add_theme_stylebox_override("hover", _save_slot_surface(Color("#203138"), Color("#a3b6af")))
	button.add_theme_stylebox_override("pressed", selected)
	button.add_theme_stylebox_override("hover_pressed", selected)
	button.add_theme_stylebox_override("disabled", _save_slot_surface(Color("#182226"), Color("#404d51")))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(2)
	focus.border_color = Color("#9cd9d0")
	button.add_theme_stylebox_override("focus", focus)

	var date := Label.new()
	date.name = "SaveTime"
	date.text = caption
	date.mouse_filter = Control.MOUSE_FILTER_IGNORE
	date.add_theme_font_size_override("font_size", 17)
	date.add_theme_color_override("font_color", Color("#b5cfca") if occupied else Color("#a0adaa"))
	button.add_child(date)
	date.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	date.offset_left = 16
	date.offset_right = -12
	date.offset_top = -28 if panel.embedded else -34
	date.offset_bottom = -3 if panel.embedded else -9
	date.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

static func _display_slot_preview(preview: TextureRect, slot: int) -> void:
	preview.texture = SaveManager.get_slot_preview(slot)
	preview.visible = preview.texture != null

static func _save_slot_surface(fill: Color, edge: Color, accent_width := 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(1)
	box.border_width_left = accent_width
	box.content_margin_left = 16
	box.content_margin_right = 12
	box.content_margin_top = 2
	box.content_margin_bottom = 25
	return box

static func _skin_card_button(node: Node) -> void:
	if is_instance_valid(node) and not node.is_queued_for_deletion() and node is Button:
		var normal: StyleBox = node.get_theme_stylebox("normal")
		var selected: bool = node.button_pressed
		if normal is StyleBoxTexture and normal.texture != null:
			selected = selected or normal.texture.resource_path.ends_with("_selected.png")
		elif normal is StyleBoxFlat:
			selected = selected or normal.border_color.g > 0.69
		ART.style_button(node, ART.Shape.CARD, selected)

static func _character(root: Control) -> void:
	var panel := root.get_node("Panel") as Control
	var frame := panel.get_child(0) as TextureRect
	ART.use_frame(frame)
	panel.get_node("TitleArt").hide()
	ART.title(panel, ART.Heading.CHARACTER, Rect2(569, 23, 422, 99))
	for child in panel.get_children():
		if child is Panel:
			# The older backing covered dividers baked into the quest image.
			child.hide()
		elif child is TextureButton:
			# The equipment card starts at y=128, so this header uses more right inset.
			ART.place_close_button(child, frame, Vector2(0.065, 0.065))
		elif child is Control and child.get_child_count() > 1 and child.get_child(0) is Panel:
			var surface := child.get_child(0) as Panel
			surface.add_theme_stylebox_override("panel", ART.surface())
			var heading := child.get_child(1) as Label
			if heading != null:
				heading.add_theme_color_override("font_color", ART.PALE_JADE)
	var detail := panel.find_child("InventoryDetail", true, false) as Panel
	if detail != null:
		detail.add_theme_stylebox_override("panel", ART.surface())
	for key in ["_inventory_action_button", "_inventory_drop_button"]:
		var button := root.get(key) as Button
		ART.style_button(button)
		button.position.y = 212.0
		button.custom_minimum_size = Vector2(92, 52)
		button.size = button.custom_minimum_size
	_watch_rows(root.get("_character_list"), _skin_card_button)
	_watch_rows(root.get("_equipment_list"), _skin_card_button)
	var grid := root.get("_inventory_grid") as GridContainer
	_watch_rows(grid, func(node: Node) -> void:
		_skin_inventory_cell(node)
		if is_instance_valid(root):
			_character_filters(root)
	)
	_character_filters(root)

static func _character_filters(root: Control) -> void:
	var buttons: Dictionary = root.get("_inventory_filter_buttons")
	for key in buttons:
		var button := buttons[key] as Button
		if button.get_theme_stylebox("normal") is StyleBoxFlat:
			ART.style_button(button, ART.Shape.ACTION, key == root.get("_inventory_filter"))

static func _skin_inventory_cell(node: Node) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return
	if node is TextureRect:
		node.texture = ART.control_texture(ART.Shape.CELL)
		node.self_modulate = Color(0.62, 0.68, 0.73)
	elif node is TextureButton:
		var old: Texture2D = node.texture_normal
		var selected := old != null and old.resource_path.ends_with("_selected.png")
		ART.style_texture_button(node, ART.Shape.CELL, selected)

static func _quest(root: Control) -> void:
	var panel := root.get_node("Panel") as Control
	var frame := panel.get_node("PanelBg") as TextureRect
	ART.use_frame(frame)
	root.get_node("Dim").color = ART.INK_DIM
	_split_sections(panel)
	panel.get_node("TitleArt").hide()
	ART.title(panel, ART.Heading.QUEST, Rect2(410, 30, 380, 92))
	ART.place_close_button(panel.get_node("CloseBtn"), frame)
	for name in ["ChapterDropdown", "TrackBtn", "ViewMainTarget"]:
		var button := panel.get_node_or_null(name) as TextureButton
		if button != null:
			ART.style_texture_button(button)
			if name == "ChapterDropdown":
				button.stretch_mode = TextureButton.STRETCH_SCALE
	for name in ["PrimaryMain", "PrimarySide", "StatusActive", "StatusDone"]:
		panel.get_node(name).pressed.connect(_quest_tabs.bind(root).call_deferred)
	_watch_rows(panel.get_node("QuestScroll/QuestList"), _quest_row)
	_watch_rows(panel.get_node("RewardList"), _quest_reward)
	_quest_tabs(root)

static func _quest_tabs(root: Control) -> void:
	if not is_instance_valid(root):
		return
	var panel := root.get_node("Panel")
	for name in ["PrimaryMain", "PrimarySide", "StatusActive", "StatusDone"]:
		var button := panel.get_node(name) as TextureButton
		var selected: bool
		match name:
			"PrimaryMain": selected = root.get("_kind_filter") == "main"
			"PrimarySide": selected = root.get("_kind_filter") == "side"
			"StatusActive": selected = root.get("_status_page") == "active"
			"StatusDone": selected = root.get("_status_page") == "done"
		ART.style_texture_button(button, ART.Shape.ACTION, selected)
		button.stretch_mode = TextureButton.STRETCH_SCALE
		var label := button.get_node_or_null("Caption") as Label
		if label != null:
			label.add_theme_color_override("font_color", ART.PALE_JADE if selected else ART.IVORY)

static func _quest_row(node: Node) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion() or not node is TextureButton:
		return
	var selected: bool = node.texture_normal != null and node.texture_normal.resource_path.ends_with("_selected.png")
	ART.style_texture_button(node, ART.Shape.CARD, selected)
	node.stretch_mode = TextureButton.STRETCH_SCALE
	for child in node.get_children():
		if child is Label:
			child.position.x = 18
			child.size.x = 240

static func _quest_reward(node: Node) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion():
		return
	for child in node.get_children():
		if child is TextureButton:
			ART.style_texture_button(child, ART.Shape.CELL)

static func _skill(root: Control) -> void:
	var content := root.get("_runtime_root") as Control
	if content == null:
		return
	var frame := root.get_node("PanelBg") as TextureRect
	ART.use_frame(frame)
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.offset_left = -768
	frame.offset_right = 768
	frame.offset_top = -502
	frame.offset_bottom = 502
	ART.section(content, Rect2(42, 271, 360, 678), 0)
	ART.section(content, Rect2(418, 291, 1045, 488), 1)
	ART.section(content, Rect2(418, 793, 1045, 142), 2)
	for child in content.get_children():
		if child is TextureRect and child.texture != null:
			var path: String = child.texture.resource_path
			if path.ends_with("/title_wuxue_text.png"):
				child.hide()
			elif path.ends_with("/stat_cell.png"):
				child.texture = ART.control_texture(ART.Shape.CARD)
				child.stretch_mode = TextureRect.STRETCH_SCALE
		elif child is Button and child.position.x == 1460:
			ART.place_close_button(child, frame)
	# Keep the live counters tied to the same training-points signal as upgrades.
	root.get("_runtime_total_resource_label").hide()
	root.get("_runtime_available_resource_label").hide()
	var counters := HBoxContainer.new()
	counters.name = "TrainingLedger"
	counters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counters.position = Vector2(1020, 60)
	counters.size = Vector2(345, 86)
	counters.add_theme_constant_override("separation", 12)
	content.add_child(counters)
	var total := _training_counter(counters, "总阅历", Color("#c4d4cf"))
	var available := _training_counter(counters, "可用阅历", Color("#f6d38e"))
	var refresh_points := func(all_points: int, free_points: int) -> void:
		total.text = str(all_points)
		available.text = str(free_points)
	refresh_points.call(GameState.training_points_total, GameState.training_points_available)
	EventBus.training_points_changed.connect(refresh_points)
	counters.tree_exiting.connect(func() -> void: EventBus.training_points_changed.disconnect(refresh_points), CONNECT_ONE_SHOT)
	ART.title(content, ART.Heading.SKILL, Rect2(540, 49, 456, 106))
	var tab_titles: Array = root.get("_runtime_primary_text_images")
	var primary_tabs: Array = root.get("_runtime_primary_buttons")
	for index in primary_tabs.size():
		tab_titles[index].hide()
		var button := primary_tabs[index] as Button
		button.tooltip_text = "招式" if index == 0 else "心法"
		button.get_node("SelectedMark").self_modulate.a = 0.0
		var group := "move" if index == 0 else "mind"
		ART.martial_tab(button, index, func() -> bool: return root.get("_runtime_group") == group)
	for key in ["_runtime_equip_btn", "_runtime_upgrade_btn"]:
		var button := root.get(key) as Button
		ART.style_button(button)
		for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
			button.get_theme_stylebox(state).set_content_margin_all(0)
		button.position.y = 804
		button.size.y = 52
	var refresh := _skill_tabs.bind(root)
	for button in root.get("_runtime_primary_buttons") + root.get("_runtime_category_buttons"):
		button.pressed.connect(refresh.call_deferred)
	root.visibility_changed.connect(refresh.call_deferred)
	_watch_rows(root.get("_runtime_list"), _skill_row)
	_skill_tabs(root)

static func _skill_row(node: Node) -> void:
	if not is_instance_valid(node) or node.is_queued_for_deletion() or not node is Button:
		return
	_skin_card_button(node)
	var row := node as Button
	row.custom_minimum_size.y = 78
	var icon := row.get_child(0) as TextureRect
	icon.position = Vector2(17, 15)
	var name_label := row.get_child(1) as Label
	var meta_label := row.get_child(2) as Label
	row.tooltip_text = name_label.text + "\n" + meta_label.text
	for label in [name_label, meta_label]:
		label.anchor_right = 1.0
		label.offset_left = 80
		label.offset_right = -17
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.offset_top = 14
	name_label.offset_bottom = 39
	meta_label.offset_top = 39
	meta_label.offset_bottom = 64

static func _skill_tabs(root: Control) -> void:
	if not is_instance_valid(root):
		return
	var routes := ["all", "sword", "blade", "staff", "palm", "hidden"]
	var categories: Array = root.get("_runtime_category_buttons")
	for index in categories.size():
		var route: String = "general" if index == 0 and root.get("_runtime_group") == "mind" else routes[index]
		ART.style_button(categories[index], ART.Shape.CELL, root.get("_runtime_route") == route)

static func _life(root: Control) -> void:
	var frame := root.get_child(0) as Control
	var art := frame.get_child(0) as TextureRect
	ART.use_frame(art)
	frame.get_child(1).hide()
	_split_sections(frame)
	ART.title(frame, ART.Heading.LIFE, Rect2(410, 30, 380, 92))
	var entries := ["Medicine", "Gathering", "Smithing"]
	for index in entries.size():
		var button := frame.get_node(entries[index]) as Button
		button.position = Vector2(78, 212 + index * 73)
		button.size = Vector2(284, 63)
		ART.life_tab(button, index)
	ART.style_button(frame.get_node("OpenMedicine"))
	for child in frame.get_children():
		if child is TextureButton:
			ART.place_close_button(child, art)

static func _training_counter(parent: HBoxContainer, caption: String, ink: Color) -> Label:
	var plate := PanelContainer.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#15252d")
	box.border_color = ink.darkened(0.42)
	box.set_border_width_all(1)
	box.border_width_bottom = 3
	box.set_corner_radius_all(4)
	plate.add_theme_stylebox_override("panel", box)
	parent.add_child(plate)
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	plate.add_child(stack)
	var title := Label.new()
	title.text = caption
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", ink)
	stack.add_child(title)
	var value := Label.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 30)
	value.add_theme_color_override("font_color", ink)
	stack.add_child(value)
	return value

static func _shop(root: Control) -> void:
	var panel := root.get_node("Panel") as Control
	var frame := panel.get_node("PanelArt") as TextureRect
	ART.use_frame(frame)
	root.get_node("Bg").color = Color("#101a24")
	var title := ART.title(panel, ART.Heading.SHOP, Rect2(495, 35, 390, 93))
	var confirmation := panel.get_node("TradeConfirmOverlay") as Control
	panel.move_child(title, confirmation.get_index())
	ART.section(panel, Rect2(68, 240, 1262, 590))
	var name_label := panel.get_node("ShopName") as Label
	name_label.position = Vector2(90, 55)
	name_label.size = Vector2(365, 65)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var greeting := panel.get_node("Greeting") as Label
	greeting.position = Vector2(566, 139)
	greeting.size = Vector2(650, 64)
	greeting.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for index in 2:
		var button := panel.get_node("BuyTabButton" if index == 0 else "SellTabButton") as TextureButton
		button.position = Vector2(90 + index * 220, 140)
		button.size = Vector2(207, 61)
		ART.caption(button, ART.Caption.BUY if index == 0 else ART.Caption.SELL)
		button.pressed.connect(_shop_tabs.bind(root).call_deferred)
	ART.place_close_button(panel.get_node("CloseBtn"), frame)
	ART.use_frame(panel.get_node("TradeConfirmOverlay/Dialog"))
	_smith_button(panel.get_node_or_null("LifeSmithButton"))
	panel.child_entered_tree.connect(_smith_button)
	for key in ["confirm_trade_button", "cancel_trade_button", "accept_trade_button"]:
		ART.style_button(root.get(key))
	for key in ["buy_list", "sell_list"]:
		_watch_rows(root.get(key), func(row: Node) -> void:
			if is_instance_valid(row) and not row.is_queued_for_deletion():
				for button in row.find_children("*", "Button", true, false):
					ART.style_button(button, ART.Shape.CELL)
			_shop_tabs(root)
		)
	_shop_tabs(root)

static func _smith_button(node: Node) -> void:
	if node is Button and node.name == "LifeSmithButton":
		node.position = Vector2(565, 196)
		node.size = Vector2(217, 38)

static func _shop_tabs(root: Control) -> void:
	if not is_instance_valid(root):
		return
	var tab: int = root.get("tabs").current_tab
	ART.style_texture_button(root.get("buy_tab_button"), ART.Shape.ACTION, tab == 0)
	ART.style_texture_button(root.get("sell_tab_button"), ART.Shape.ACTION, tab == 1)

static func _result(root: Control, victory: bool) -> void:
	var background := root.get_node("FormalBackground") as TextureRect
	background.texture = ART.RESULT_BACKDROP
	background.modulate = Color.WHITE if victory else Color(0.82, 0.85, 0.91)
	root.get_node("TitleArt").hide()
	var frame := TextureRect.new()
	frame.name = "LacquerResultFrame"
	root.add_child(frame)
	frame.set_anchors_preset(Control.PRESET_CENTER)
	frame.offset_left = -510
	frame.offset_right = 510
	frame.offset_top = -322
	frame.offset_bottom = 322
	ART.use_frame(frame)
	ART.title(frame, ART.Heading.VICTORY if victory else ART.Heading.DEFEAT, Rect2(258, 42, 504, 128))
	ART.section(frame, Rect2(123, 192, 774, 294), 0)
	var scroll := ScrollContainer.new()
	scroll.name = "ResultDetails"
	scroll.position = Vector2(145, 208)
	scroll.size = Vector2(730, 263)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	frame.add_child(scroll)
	var detail := root.get_node("RewardLabel" if victory else "Subtitle") as Control
	detail.reparent(scroll, false)
	detail.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
	detail.set("horizontal_alignment", HORIZONTAL_ALIGNMENT_CENTER)
	detail.set("vertical_alignment", VERTICAL_ALIGNMENT_CENTER)
	detail.add_theme_color_override("default_color" if victory else "font_color", ART.IVORY)
	detail.add_theme_font_size_override("normal_font_size" if victory else "font_size", 25)
	detail.add_theme_constant_override("line_spacing", 7)
	var button := root.get_node("%BtnContinue" if victory else "%BtnBack") as Button
	var action := root.get_node("ButtonRow") as Control if victory else button
	button.custom_minimum_size = Vector2(280, 62)
	ART.style_button(button)
	action.reparent(frame, false)
	action.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	action.position = Vector2(370, 523)
	action.size = Vector2(280, 62)
	ART.caption(button, ART.Caption.RETURN)
