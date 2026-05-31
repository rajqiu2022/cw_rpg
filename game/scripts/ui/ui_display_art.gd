class_name UIDisplayArt
extends RefCounted

## Lightweight bridge for the current visual-showcase pass.
## It displays approved UI mockups while full interactive layouts are deferred.


static func install_fullscreen_panel(root: Control, texture_path: String, close_callback: Callable) -> void:
	if root == null or root.get_node_or_null("DisplayArt") != null:
		return
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		push_warning("[UIDisplayArt] display texture missing: %s" % texture_path)
		return

	var panel := root.get_node_or_null("Panel") as Control
	if panel != null:
		panel.visible = false

	var art: TextureRect = TextureRect.new()
	art.name = "DisplayArt"
	art.texture = load(texture_path)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(art)
	root.move_child(art, 1)

	var close_btn: Button = Button.new()
	close_btn.name = "DisplayCloseHotspot"
	close_btn.text = ""
	close_btn.tooltip_text = "关闭"
	close_btn.focus_mode = Control.FOCUS_NONE
	close_btn.flat = true
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	close_btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	close_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	close_btn.anchor_left = 1.0
	close_btn.anchor_right = 1.0
	close_btn.offset_left = -210.0
	close_btn.offset_top = 34.0
	close_btn.offset_right = -44.0
	close_btn.offset_bottom = 118.0
	close_btn.pressed.connect(close_callback)
	root.add_child(close_btn)


static func install_field_hud(root: Control, texture_path: String) -> void:
	if root == null or root.get_node_or_null("FieldHudDisplayArt") != null:
		return
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		push_warning("[UIDisplayArt] HUD display texture missing: %s" % texture_path)
		return

	var art: TextureRect = TextureRect.new()
	art.name = "FieldHudDisplayArt"
	art.texture = load(texture_path)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(art)
	root.move_child(art, min(root.get_child_count() - 1, 4))
