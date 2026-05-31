class_name UITextureSkin
extends RefCounted

## Reusable texture-backed UI helpers.
## Use this for production UI pieces that are generated/cropped as PNG assets.


static func load_texture(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		push_warning("[UITextureSkin] texture missing: %s" % path)
		return null
	var res: Resource = load(path)
	if res is Texture2D:
		return res
	push_warning("[UITextureSkin] resource is not Texture2D: %s" % path)
	return null


static func place_texture(parent: Control, name: String, path: String, rect: Rect2) -> TextureRect:
	var tex := load_texture(path)
	if tex == null:
		return null
	var node: TextureRect = TextureRect.new()
	node.name = name
	node.texture = tex
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.position = rect.position
	node.size = rect.size
	parent.add_child(node)
	return node


static func make_texture_button(
	parent: Control,
	name: String,
	paths: Dictionary,
	rect: Rect2,
	callback: Callable
) -> TextureButton:
	var normal: Texture2D = load_texture(String(paths.get("normal", "")))
	if normal == null:
		return null
	var button: TextureButton = TextureButton.new()
	button.name = name
	button.texture_normal = normal
	button.texture_hover = load_texture(String(paths.get("hover", "")))
	button.texture_pressed = load_texture(String(paths.get("pressed", "")))
	button.stretch_mode = TextureButton.STRETCH_SCALE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.position = rect.position
	button.size = rect.size
	if callback.is_valid():
		button.pressed.connect(callback)
	parent.add_child(button)
	return button


static func stylebox_texture(path: String, margin: int = 24) -> StyleBoxTexture:
	var tex := load_texture(path)
	if tex == null:
		return null
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = tex
	box.region_rect = Rect2(Vector2.ZERO, tex.get_size())
	box.set_texture_margin(SIDE_LEFT, margin)
	box.set_texture_margin(SIDE_TOP, margin)
	box.set_texture_margin(SIDE_RIGHT, margin)
	box.set_texture_margin(SIDE_BOTTOM, margin)
	box.set_content_margin_all(margin)
	return box


static func label(parent: Control, name: String, text: String, rect: Rect2, font_size: int, color: Color) -> Label:
	var node: Label = Label.new()
	node.name = name
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.74))
	node.add_theme_constant_override("shadow_offset_x", 2)
	node.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(node)
	return node


static func rich_text(parent: Control, name: String, text: String, rect: Rect2, font_size: int, color: Color) -> RichTextLabel:
	var node: RichTextLabel = RichTextLabel.new()
	node.name = name
	node.bbcode_enabled = true
	node.fit_content = false
	node.scroll_active = false
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_size_override("normal_font_size", font_size)
	node.add_theme_color_override("default_color", color)
	parent.add_child(node)
	return node
