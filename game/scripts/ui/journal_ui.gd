extends RefCounted

const THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ART := "res://art/ui/quest/runtime_v1/"
const BACKGROUND := preload("res://art/ui/quest/runtime_v1/panel_bg_v5.png")

static func style_button(button: Button, font_size: int = 22, family: String = "track") -> void:
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", THEME.TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", THEME.GOLD_LIGHT)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxTexture.new()
		var art_state: String = "normal" if state == "disabled" else state
		box.texture = load(ART + "%s_%s.png" % [family, art_state])
		if state == "disabled":
			box.modulate_color = Color(0.66, 0.7, 0.74)
		button.add_theme_stylebox_override(state, box)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.set_border_width_all(1)
	focus.border_color = THEME.JADE
	button.add_theme_stylebox_override("focus", focus)

static func add_frame(parent: Control) -> Control:
	var frame := Control.new()
	parent.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	frame.offset_left = -600
	frame.offset_right = 600
	frame.offset_top = -400
	frame.offset_bottom = 400
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := TextureRect.new()
	art.texture = BACKGROUND
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return frame

static func add_label(parent: Control, caption: String, rect: Rect2, font_size: int, color: Color = THEME.TEXT) -> Label:
	var label := Label.new()
	label.text = caption
	label.position = rect.position
	label.size = rect.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	THEME.style_label(label, font_size, color)
	parent.add_child(label)
	return label

