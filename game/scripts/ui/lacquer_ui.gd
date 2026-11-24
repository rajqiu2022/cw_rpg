extends RefCounted

## Shared art for the eight modal interfaces. Atlas crops keep the original pixels.
const FRAME := preload("res://art/ui/lacquer_20261112/frame.png")
const TITLES := preload("res://art/ui/lacquer_20261112/titles.png")
const CONTROLS := preload("res://art/ui/lacquer_20261112/controls.png")
const CAPTIONS := preload("res://art/ui/lacquer_20261112/captions.png")
const MARTIAL_TABS := preload("res://art/ui/lacquer_20261112/martial_tabs.png")
const LIFE_TABS := preload("res://art/ui/lacquer_20261112/life_tabs.png")
const RESULT_BACKDROP := preload("res://art/ui/lacquer_20261112/result_bg.png")
const INK_DIM := Color(0.016, 0.026, 0.039, 0.56)
const IVORY := Color("#f2e7cf")
const PALE_JADE := Color("#a4c4bc")
const MUTED := Color("#adb8bf")
const CLOSE_INSET := Vector2(72.0 / 1536.0, 93.0 / 1004.0)
enum Heading { SYSTEM, CHARACTER, QUEST, SKILL, LIFE, SHOP, VICTORY, DEFEAT }
enum Shape { ACTION, CLOSE, CARD, CELL }
enum Caption { MOVE, MIND, SETTINGS, SAVE, LOAD, RETURN, BUY, SELL }

const TITLE_Y := [61, 294, 540, 771]
const MARTIAL_TAB_ROWS := [97, 253, 410, 564, 706, 851]
const LIFE_TAB_ROWS := [224, 439, 672]
const CAPTION_REGIONS := [
	Rect2(188, 44, 431, 221), Rect2(921, 45, 439, 211),
	Rect2(187, 304, 419, 204), Rect2(806, 314, 686, 185),
	Rect2(61, 543, 667, 195), Rect2(821, 549, 665, 192),
	Rect2(202, 785, 426, 202), Rect2(936, 776, 394, 221),
]
const REGIONS := [
	[Rect2(34, 92, 472, 128), Rect2(532, 92, 472, 128), Rect2(1030, 92, 472, 128)],
	[Rect2(177, 289, 190, 193), Rect2(673, 289, 190, 193), Rect2(1170, 289, 190, 193)],
	[Rect2(33, 540, 474, 193), Rect2(531, 540, 474, 193), Rect2(1029, 540, 474, 193)],
	[Rect2(182, 786, 180, 184), Rect2(677, 786, 182, 184), Rect2(1173, 786, 183, 184)],
]

static func _atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	atlas.filter_clip = true
	return atlas

static func control_texture(shape: Shape, state: int = 0) -> AtlasTexture:
	return _atlas(CONTROLS, REGIONS[shape][state])

static func frame_texture() -> AtlasTexture:
	return _atlas(FRAME, Rect2(12, 37, 1512, 941))

static func use_frame(rect: TextureRect) -> void:
	rect.texture = frame_texture()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate = Color.WHITE

static func place_close_button(button: BaseButton, frame: TextureRect, inset: Vector2 = CLOSE_INSET) -> void:
	if button is TextureButton:
		style_texture_button(button, Shape.CLOSE)
	elif button is Button:
		style_button(button, Shape.CLOSE)
	button.tooltip_text = "关闭"
	var side := minf(roundf(frame.size.x / 24.0), 64.0)
	var top_right := Vector2(frame.size.x, 0.0)
	var frame_position := top_right + frame.size * Vector2(-inset.x, inset.y) - Vector2(side, 0.0)
	var parent := button.get_parent_control()
	var position_in_parent := parent.get_global_transform().affine_inverse() * (frame.get_global_transform() * frame_position)
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	button.size = Vector2(side, side)
	button.position = position_in_parent.round()

static func title(parent: Control, heading: Heading, bounds: Rect2) -> TextureRect:
	var art := TextureRect.new()
	art.name = "LacquerTitle"
	art.texture = _atlas(TITLES, Rect2(18 + (heading % 2) * 768, TITLE_Y[heading >> 1], 733, 194))
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(art)
	art.position = bounds.position
	art.size = bounds.size
	return art

static func caption_texture(word: Caption) -> AtlasTexture:
	return _atlas(CAPTIONS, CAPTION_REGIONS[word])

static func martial_tab(button: Button, index: int, selected: Callable) -> void:
	var states: Array[AtlasTexture] = []
	for state in 3:
		states.append(_atlas(MARTIAL_TABS, Rect2(440, MARTIAL_TAB_ROWS[index * 3 + state], 657, 98)))
	_illustrated_button(button, states, selected)

static func life_tab(button: Button, index: int) -> void:
	var normal := _atlas(LIFE_TABS, Rect2(53, LIFE_TAB_ROWS[index], 685, 152))
	var active := _atlas(LIFE_TABS, Rect2(798, LIFE_TAB_ROWS[index], 685, 152))
	_illustrated_button(button, [normal, active, active], func() -> bool: return button.button_pressed)

static func _illustrated_button(button: Button, states: Array[AtlasTexture], selected: Callable) -> void:
	# Keep the original control and input wiring. Its old skin can be rebuilt by its owner.
	button.self_modulate.a = 0.0
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var art := TextureRect.new()
	art.name = "IllustratedButtonArt"
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var update := func() -> void:
		var mode := button.get_draw_mode()
		var down := mode == BaseButton.DRAW_PRESSED or mode == BaseButton.DRAW_HOVER_PRESSED
		var highlighted := mode == BaseButton.DRAW_HOVER or button.has_focus() or bool(selected.call())
		art.texture = states[2 if down else int(highlighted)]
		art.modulate = Color(0.75, 0.75, 0.75) if button.disabled else Color.WHITE
	button.draw.connect(update)
	update.call()

static func caption(button: BaseButton, word: Caption) -> void:
	if button is Button:
		button.tooltip_text = button.text
		button.text = ""
	var legacy := button.get_node_or_null("Caption") as Label
	if legacy != null:
		legacy.hide()
	var glyphs := TextureRect.new()
	glyphs.name = "LacquerCaption"
	glyphs.texture = caption_texture(word)
	glyphs.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyphs.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyphs.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	glyphs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(glyphs)
	glyphs.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyphs.offset_left = 18
	glyphs.offset_right = -18
	glyphs.offset_top = 12
	glyphs.offset_bottom = -12

static func surface(shape: Shape = Shape.CARD, state: int = 0, padding: Vector4 = Vector4.ZERO) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = control_texture(shape, state)
	var corner := 17.0 if shape == Shape.CARD else 0.0
	box.texture_margin_left = corner
	box.texture_margin_top = corner
	box.texture_margin_right = corner
	box.texture_margin_bottom = corner
	box.content_margin_left = padding.x
	box.content_margin_top = padding.y
	box.content_margin_right = padding.z
	box.content_margin_bottom = padding.w
	return box

static func section(parent: Control, bounds: Rect2, index: int = 1) -> Panel:
	var panel := Panel.new()
	panel.name = "LacquerSection"
	panel.position = bounds.position
	panel.size = bounds.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	panel.add_theme_stylebox_override("panel", surface())
	parent.add_child(panel)
	parent.move_child(panel, index)
	return panel

static func style_button(button: Button, shape: Shape = Shape.ACTION, selected: bool = false) -> void:
	var previous := button.get_theme_stylebox("normal")
	var padding := Vector4(
		maxf(previous.content_margin_left, 0), maxf(previous.content_margin_top, 0),
		maxf(previous.content_margin_right, 0), maxf(previous.content_margin_bottom, 0)
	)
	button.flat = false
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_color", IVORY if not selected else PALE_JADE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", IVORY)
	button.add_theme_color_override("font_disabled_color", MUTED.darkened(0.2))
	button.add_theme_stylebox_override("normal", surface(shape, int(selected), padding))
	button.add_theme_stylebox_override("hover", surface(shape, 1, padding))
	button.add_theme_stylebox_override("pressed", surface(shape, 2, padding))
	button.add_theme_stylebox_override("hover_pressed", surface(shape, 2, padding))
	var disabled := surface(shape, 0, padding)
	disabled.modulate_color = Color(0.63, 0.67, 0.70)
	button.add_theme_stylebox_override("disabled", disabled)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = PALE_JADE
	focus.set_border_width_all(1)
	button.add_theme_stylebox_override("focus", focus)

static func style_texture_button(button: TextureButton, shape: Shape = Shape.ACTION, selected: bool = false) -> void:
	button.texture_normal = control_texture(shape, int(selected))
	button.texture_hover = control_texture(shape, 1)
	button.texture_pressed = control_texture(shape, 2)
	button.texture_disabled = control_texture(shape, 0)
	button.texture_focused = null
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
