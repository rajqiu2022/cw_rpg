extends CanvasLayer

const ART := preload("res://scripts/ui/lacquer_ui.gd")
const QUEST_ICON := preload("res://art/ui/quest/reward_exp_icon_v1.png")

var _panel: PanelContainer
var _heading: Label
var _quest_icon: TextureRect
var _title: Label
var _rewards: RichTextLabel
var _timer: Timer
var _queue: Array[Dictionary] = []


func _ready() -> void:
	layer = 115
	var anchor := CenterContainer.new()
	add_child(anchor)
	anchor.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	anchor.offset_top = 100
	anchor.grow_horizontal = Control.GROW_DIRECTION_BOTH
	anchor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := ART.surface(ART.Shape.CARD, 0, Vector4(24, 15, 24, 17))
	background.modulate_color = Color(1, 1, 1, 0.78)
	_panel.add_theme_stylebox_override("panel", background)
	anchor.add_child(_panel)
	var body := VBoxContainer.new()
	body.custom_minimum_size.x = 410
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 6)
	_panel.add_child(body)
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(header)
	var icon := TextureRect.new()
	_quest_icon = icon
	icon.texture = QUEST_ICON
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(29, 29)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(icon)
	_heading = _label(header, 23, Color("#f2d498"))
	_title = _label(body, 22, ART.IVORY)
	_rewards = RichTextLabel.new()
	_rewards.fit_content = true
	_rewards.scroll_active = false
	_rewards.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rewards.add_theme_font_size_override("normal_font_size", 19)
	_rewards.add_theme_color_override("default_color", ART.PALE_JADE)
	body.add_child(_rewards)
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_show_next)
	_panel.hide()


func _label(parent: Container, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label


func enqueue(heading: String, title: String, rows: Array[Dictionary], pickup := false) -> void:
	_queue.append({"heading": heading, "title": title, "rows": rows, "pickup": pickup})
	if _timer.is_stopped():
		_show_next()


func clear() -> void:
	_queue.clear()
	_timer.stop()
	_panel.hide()


func _show_next() -> void:
	if _queue.is_empty():
		_panel.hide()
		return
	var notice: Dictionary = _queue.pop_front()
	_heading.text = notice.heading
	_quest_icon.visible = not notice.pickup
	_title.text = notice.title
	_title.visible = not _title.text.is_empty()
	_rewards.clear()
	_rewards.visible = not notice.rows.is_empty()
	_rewards.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	for index in range(notice.rows.size()):
		var row: Dictionary = notice.rows[index]
		if index > 0:
			_rewards.newline()
		var icon := row.get("icon") as Texture2D
		if icon != null:
			var size := icon.get_size()
			var scale_factor := 25.0 / maxf(size.x, size.y)
			_rewards.add_image(icon, maxi(1, roundi(size.x * scale_factor)), maxi(1, roundi(size.y * scale_factor)), Color.WHITE, INLINE_ALIGNMENT_CENTER)
			_rewards.add_text("  ")
		_rewards.push_color(row.get("label_color", ART.PALE_JADE))
		_rewards.add_text(row.label + "  ")
		_rewards.pop()
		_rewards.push_color(row.color)
		_rewards.add_text(row.value)
		_rewards.pop()
	_rewards.pop()
	_panel.show()
	_timer.start(2.5 if notice.pickup else clampf(3.5 + notice.rows.size() * 0.65, 4.0, 8.5))
