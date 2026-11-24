extends RefCounted

const THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ART := preload("res://art/ui/menu_buttons_20261109/atlas_data.gd")
const STATES := ["normal", "hover", "pressed", "disabled"]

static func aspect(family: String) -> float:
	var region: Rect2 = ART.REGIONS[family][0]
	return region.size.aspect()

static func style_button(button: Button, family: String, font_size: int) -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", THEME.TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", THEME.GOLD_LIGHT)
	button.add_theme_color_override("font_hover_pressed_color", THEME.GOLD_LIGHT)
	button.add_theme_color_override("font_focus_color", THEME.JADE.lightened(0.32))
	button.add_theme_color_override("font_disabled_color", THEME.MUTED)
	for i in STATES.size():
		var style := StyleBoxTexture.new()
		style.texture = ART.SHEETS[family]
		style.region_rect = ART.REGIONS[family][i]
		style.set_content_margin_all(0)
		button.add_theme_stylebox_override(STATES[i], style)
	button.add_theme_stylebox_override("hover_pressed", button.get_theme_stylebox("pressed"))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

static func style_hud(button: TextureButton, sheet: Texture2D, regions: Array[Rect2]) -> void:
	var frames: Array[AtlasTexture] = []
	for region in regions:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = region
		frame.filter_clip = true
		frames.append(frame)
	button.texture_normal = frames[0]
	button.texture_hover = frames[1]
	button.texture_pressed = frames[2]
	button.texture_disabled = frames[2]
	button.focus_entered.connect(func() -> void: button.texture_normal = frames[1])
	button.focus_exited.connect(func() -> void: button.texture_normal = frames[0])
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
