extends "res://scripts/ui/item_detail_tip.gd"

var _title: Label
var _category: Label


func _ready() -> void:
	super._ready()
	custom_minimum_size = Vector2(410, 176)
	var frame := get_theme_stylebox("panel").duplicate() as StyleBoxTexture
	frame.content_margin_left = 28
	frame.content_margin_right = 28
	frame.content_margin_top = 23
	frame.content_margin_bottom = 21
	add_theme_stylebox_override("panel", frame)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	add_child(stack)
	_title = Label.new()
	_title.custom_minimum_size.y = 29
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.add_theme_font_size_override("font_size", 20)
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(_title)

	_category = Label.new()
	_category.add_theme_font_size_override("font_size", 13)
	_category.add_theme_color_override("font_color", Color("#a0b1bb"))
	_category.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(_category)

	_text.reparent(stack, false)
	_text.custom_minimum_size = Vector2.ZERO
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.scroll_active = true


func show_item(item: Item, count: int = 1) -> void:
	if item == null:
		hide_tip()
		return
	super.show_item(item, count)
	_title.text = item.display_name
	_title.add_theme_color_override("font_color", Color(QUALITY_COLORS.get(item.quality, "#c0c8d0")))
	_category.text = "%s · ×%d" % [_category_name(item), count]
	# Reuse the common formatter for effects, equipment stats and description.
	var lines := _text.text.split("\n", true, 2)
	_text.text = lines[2] if lines.size() == 3 else ""
	_text.scroll_to_line(0)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	var mouse_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var tap: bool = event is InputEventScreenTouch and event.pressed
	if mouse_click or tap:
		var local_position: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if not Rect2(Vector2.ZERO, size).has_point(local_position):
			hide_tip()
