class_name WuxiaTheme
extends RefCounted

const INK := Color(0.018, 0.026, 0.035, 0.97)
const INK_SOFT := Color(0.045, 0.070, 0.092, 0.92)
const PAPER := Color(0.58, 0.66, 0.68, 0.90)
const PAPER_DARK := Color(0.095, 0.125, 0.145, 0.94)
const WOOD := Color(0.075, 0.125, 0.155, 0.96)
const WOOD_DARK := Color(0.030, 0.055, 0.075, 0.98)
const GOLD := Color(0.42, 0.58, 0.70, 1.0)
const GOLD_LIGHT := Color(0.76, 0.90, 0.98, 1.0)
const JADE := Color(0.36, 0.70, 0.72, 1.0)
const CRIMSON := Color(0.38, 0.10, 0.16, 1.0)
const BLUE_STEEL := Color(0.20, 0.34, 0.48, 1.0)
const TEXT := Color(0.82, 0.90, 0.94, 1.0)
const MUTED := Color(0.48, 0.58, 0.64, 1.0)


static func panel(bg: Color = INK_SOFT, border: Color = GOLD, radius: int = 14, border_width: int = 2) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 14
	s.content_margin_bottom = 14
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 10
	return s

static func button_style(bg: Color, border: Color, radius: int = 9) -> StyleBoxFlat:
	var s := panel(bg, border, radius, 2)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.shadow_size = 4
	return s

static func style_button(btn: Button, font_size: int = 22, accent: Color = GOLD) -> void:
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal", button_style(WOOD, accent, 8))
	btn.add_theme_stylebox_override("hover", button_style(Color(0.055, 0.145, 0.145, 0.98), accent.lightened(0.32), 8))
	btn.add_theme_stylebox_override("pressed", button_style(WOOD_DARK, accent.lightened(0.18), 8))
	btn.add_theme_stylebox_override("focus", button_style(Color(0.050, 0.130, 0.135, 0.98), JADE, 8))
	btn.add_theme_stylebox_override("disabled", button_style(Color(0.045, 0.055, 0.062, 0.66), Color(0.22, 0.28, 0.32, 0.80), 8))
	btn.add_theme_color_override("font_color", TEXT)

	btn.add_theme_color_override("font_hover_color", Color(0.90, 0.78, 0.42, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.90, 0.98, 1.0, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.34, 0.40, 0.43, 1.0))
	btn.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.95))
	btn.add_theme_constant_override("outline_size", 3)
	btn.add_theme_font_size_override("font_size", font_size)

static func style_wood_tab(btn: Button, font_size: int = 24) -> void:
	style_button(btn, font_size, GOLD)
	btn.custom_minimum_size = Vector2(max(btn.custom_minimum_size.x, 280.0), max(btn.custom_minimum_size.y, 56.0))


static func style_label(label: Label, font_size: int, color: Color = TEXT, shadow := true) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if shadow:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.72))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)

static func style_rich_text(label: RichTextLabel, font_size: int = 18) -> void:
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", TEXT)
	label.add_theme_stylebox_override("normal", panel(Color(0.020, 0.030, 0.040, 0.72), Color(0.18, 0.30, 0.38, 0.80), 10, 1))

static func style_progress(bar: ProgressBar, fill: Color, bg: Color = Color(0.025, 0.035, 0.045, 0.94)) -> void:
	bar.add_theme_stylebox_override("background", button_style(bg, Color(0.15, 0.24, 0.30, 0.9), 5))

	bar.add_theme_stylebox_override("fill", button_style(fill, fill.lightened(0.18), 5))
