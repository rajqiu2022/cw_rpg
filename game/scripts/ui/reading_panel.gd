class_name ReadingPanel
extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const PANEL_ART := preload("res://art/ui/inventory/reading/readable_panel_bg_v1.png")
const BTN_NORMAL := preload("res://art/ui/button/btn_menu_frame_normal.png")
const BTN_HOVER := preload("res://art/ui/button/btn_menu_frame_hover.png")
const BTN_PRESSED := preload("res://art/ui/button/btn_menu_frame_pressed.png")

var _title: Label
var _source: Label
var _body: RichTextLabel
var _icon: TextureRect
var _close_button: Button
var _study_button: Button
var _study_status: Label
var _scroll: ScrollContainer
var _current_item: Item


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func open_item(item: Item) -> bool:
	if item == null or not item.is_readable():
		return false
	_title.text = item.read_title if not item.read_title.strip_edges().is_empty() else item.display_name
	_source.text = item.read_source
	_source.visible = not item.read_source.strip_edges().is_empty()
	_body.text = item.read_content
	_icon.texture = load(item.icon_path) as Texture2D if not item.icon_path.is_empty() and ResourceLoader.exists(item.icon_path) else null
	_icon.visible = _icon.texture != null
	_current_item = item
	_update_study_ui()
	visible = true
	move_to_front()
	_close_button.grab_focus()
	return true


func close_reader() -> void:
	visible = false
	_current_item = null


func is_open() -> bool:
	return visible


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_reader()
		get_viewport().set_input_as_handled()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.005, 0.01, 0.016, 0.82)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# The whole window is authored raster UI. Text remains native so every
	# manuscript can reuse the same formal frame without baked-in characters.
	var panel_art := TextureRect.new()
	panel_art.name = "ReadablePanelArt"
	panel_art.set_anchors_preset(Control.PRESET_CENTER)
	panel_art.position = Vector2(-480, -320)
	panel_art.size = Vector2(960, 640)
	panel_art.texture = PANEL_ART
	panel_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel_art.stretch_mode = TextureRect.STRETCH_SCALE
	panel_art.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel_art)

	_icon = TextureRect.new()
	_icon.name = "ReadableIcon"
	_icon.position = Vector2(54, 102)
	_icon.size = Vector2(100, 100)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_art.add_child(_icon)

	_title = Label.new()
	_title.name = "ReadableTitle"
	_title.position = Vector2(220, 42)
	_title.size = Vector2(520, 56)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_THEME.style_label(_title, 29, UI_THEME.GOLD_LIGHT)
	panel_art.add_child(_title)

	_source = Label.new()
	_source.name = "ReadableSource"
	_source.position = Vector2(176, 118)
	_source.size = Vector2(700, 30)
	_source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI_THEME.style_label(_source, 16, UI_THEME.MUTED, false)
	panel_art.add_child(_source)

	_scroll = ScrollContainer.new()
	_scroll.name = "ReadableScroll"
	_scroll.position = Vector2(176, 158)
	_scroll.size = Vector2(700, 360)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel_art.add_child(_scroll)

	_body = RichTextLabel.new()
	_body.name = "ReadableBody"
	_body.bbcode_enabled = true
	_body.fit_content = true
	_body.custom_minimum_size = Vector2(680, 350)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_theme_font_size_override("normal_font_size", 20)
	_body.add_theme_color_override("default_color", Color(0.88, 0.87, 0.80, 1.0))
	_body.add_theme_constant_override("line_separation", 8)
	_scroll.add_child(_body)

	_study_status = Label.new()
	_study_status.name = "StudyStatus"
	_study_status.position = Vector2(176, 482)
	_study_status.size = Vector2(700, 42)
	_study_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_study_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UI_THEME.style_label(_study_status, 17, UI_THEME.GOLD_LIGHT, false)
	panel_art.add_child(_study_status)

	_study_button = Button.new()
	_study_button.name = "StudyManual"
	_study_button.text = "研习秘籍"
	_study_button.position = Vector2(205, 540)
	_study_button.size = Vector2(250, 68)
	_study_button.custom_minimum_size = Vector2(250, 68)
	_install_button_style(_study_button)
	_study_button.pressed.connect(_on_study_pressed)
	panel_art.add_child(_study_button)

	_close_button = Button.new()
	_close_button.name = "CloseReader"
	_close_button.text = "合卷"
	# The authored footer is deliberately broad.  Give its only action enough
	# visual weight and touch area for both desktop and WeChat screens.
	_close_button.position = Vector2(350, 540)
	_close_button.size = Vector2(260, 68)
	_close_button.custom_minimum_size = Vector2(260, 68)
	_install_button_style(_close_button)
	_close_button.pressed.connect(close_reader)
	panel_art.add_child(_close_button)


func _update_study_ui() -> void:
	var can_study := _current_item != null and not String(_current_item.study_skill_id).is_empty()
	_study_button.visible = can_study
	_study_status.visible = can_study
	_scroll.size.y = 310.0 if can_study else 360.0
	_close_button.position.x = 505.0 if can_study else 350.0
	if not can_study:
		return
	var path := "res://data/skills/%s.tres" % String(_current_item.study_skill_id)
	var skill: Skill = null
	if ResourceLoader.exists(path):
		skill = load(path) as Skill
	if skill == null:
		_study_status.text = "秘籍内容残缺，暂时无法研习"
		_study_button.disabled = true
		return
	var game_state := _game_state()
	if game_state != null and game_state.player != null and _current_item.study_skill_id in game_state.player.skills:
		_study_status.text = "已领悟：%s" % skill.display_name
		_study_button.text = "已领悟"
		_study_button.disabled = true
		return
	if _current_item.study_requires_item != &"" and not Inventory.has_item(_current_item.study_requires_item):
		var missing := Inventory.load_item_by_id(_current_item.study_requires_item)
		_study_status.text = "研习还缺：%s" % (missing.display_name if missing != null else "另一张残页")
		_study_button.text = "残页未齐"
		_study_button.disabled = true
		return
	var current_insight: int = int(game_state.get_effective_insight()) if game_state != null else 0
	var required_insight: int = skill.get_required_insight()
	_study_status.text = "研习条件：悟性 %d（当前 %d）" % [required_insight, current_insight]
	_study_button.text = "研习秘籍" if current_insight >= required_insight else "悟性不足"
	_study_button.disabled = current_insight < required_insight


func _on_study_pressed() -> void:
	if _current_item == null or String(_current_item.study_skill_id).is_empty():
		return
	if _current_item.study_requires_item != &"" and not Inventory.has_item(_current_item.study_requires_item):
		_update_study_ui()
		return
	var path := "res://data/skills/%s.tres" % String(_current_item.study_skill_id)
	var skill: Skill = null
	if ResourceLoader.exists(path):
		skill = load(path) as Skill
	var game_state := _game_state()
	if game_state == null or skill == null or game_state.get_effective_insight() < skill.get_required_insight():
		_update_study_ui()
		return
	game_state.learn_skill(_current_item.study_skill_id)
	_update_study_ui()


func _game_state() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("GameState") if tree != null else null


func _install_button_style(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", UI_THEME.TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", UI_THEME.GOLD_LIGHT)
	button.add_theme_stylebox_override("normal", _texture_stylebox(BTN_NORMAL))
	button.add_theme_stylebox_override("hover", _texture_stylebox(BTN_HOVER))
	button.add_theme_stylebox_override("pressed", _texture_stylebox(BTN_PRESSED))
	button.add_theme_stylebox_override("focus", _texture_stylebox(BTN_HOVER))


func _texture_stylebox(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 24.0
	style.texture_margin_top = 12.0
	style.texture_margin_right = 24.0
	style.texture_margin_bottom = 12.0
	style.content_margin_left = 20.0
	style.content_margin_top = 8.0
	style.content_margin_right = 20.0
	style.content_margin_bottom = 8.0
	return style
