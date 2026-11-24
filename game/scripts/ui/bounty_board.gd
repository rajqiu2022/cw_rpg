extends Control

const BOARD_TEXTURE := preload("res://art/ui/bounty_board/bounty_board_frame_v2.png")
const CITY_NAMES := {
	"luoyang": "洛阳府缉捕榜",
	"bianzhou": "汴州府缉捕榜",
	"xiangzhou": "襄州城缉捕榜",
	"jinling": "金陵府缉捕榜",
}
const STATUS_LABELS := {"available": "揭榜", "active": "追捕中", "decision": "待抉择", "evidence": "待验缴", "captured": "已归案"}

var _payload: Dictionary
var _city_id: StringName
var _list: VBoxContainer
var _reputation_label: Label
var _page := 0
var _previous_page: Button
var _next_page: Button


func _ready() -> void:
	_payload = SceneRouter.get_bounty_board_payload()
	_city_id = StringName(_payload.get("city_id", &"luoyang"))
	_build_ui()
	_refresh()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.008, 0.012, 0.014, 1.0)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var board := TextureRect.new()
	board.name = "BountyBoardArt"
	board.texture = BOARD_TEXTURE
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)

	var title := _make_label(40, Color("f0d396"), HORIZONTAL_ALIGNMENT_CENTER)
	title.name = "BoardTitle"
	var county: Dictionary = BountyManager.COUNTY_BOARDS.get(_city_id,{})
	title.text = county.get("name",CITY_NAMES.get(String(_city_id), "州府缉捕榜"))
	_place(title, 0.30, 0.046, 0.70, 0.126)
	add_child(title)

	_reputation_label = _make_label(22, Color("9bd5cf"), HORIZONTAL_ALIGNMENT_CENTER)
	_reputation_label.name = "ReputationLabel"
	# The teal information plaque begins below the decorative gold lip. Keep
	# both status lines inside its painted inner face, not on the outer frame.
	_place(_reputation_label, 0.25, 0.165, 0.75, 0.199)
	add_child(_reputation_label)

	var hint := _make_label(22, Color("e0d0aa"), HORIZONTAL_ALIGNMENT_CENTER)
	hint.name = "BoardHint"
	hint.text = "每日轮换榜文。揭榜后循线追捕，取回物证，再到发榜府衙交验领赏。"
	if not county.is_empty():
		hint.text = "本镇只张榜，不发赏。取得物证后，请到%s交验。"%BountyManager.office_label_for_board(_city_id)
	_place(hint, 0.18, 0.202, 0.82, 0.238)
	add_child(hint)

	_list = VBoxContainer.new()
	_list.name = "BountyEntries"
	_list.add_theme_constant_override("separation", 12)
	# These bounds match the two parchment slots in bounty_board_frame_v2.
	# Keeping the list inside the artwork's safe area prevents names and buttons
	# from drifting into the portrait medallions or outer metal frame.
	_place(_list, 0.110, 0.275, 0.890, 0.760)
	add_child(_list)

	_previous_page = _make_page_button("‹ 上一页",0.295,-1)
	_next_page = _make_page_button("下一页 ›",0.580,1)

	var close := Button.new()
	close.text = "合上榜册"
	close.add_theme_font_size_override("font_size", 24)
	close.add_theme_color_override("font_color", Color("eee0bd"))
	close.add_theme_stylebox_override("normal", _panel_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 8, 8))
	close.add_theme_stylebox_override("hover", _panel_style(Color(0.12, 0.24, 0.23, 0.42), Color("e1c074"), 2, 8, 8))
	close.name = "CloseButton"
	# Match the inset face of the bottom cyan plaque. The previous anchor began
	# above the plaque and made the label appear to sit on its upper trim.
	_place(close, 0.430, 0.858, 0.570, 0.930)
	close.pressed.connect(_close)
	add_child(close)

func _make_page_button(label: String,left: float,delta: int) -> Button:
	var button := Button.new()
	button.text = label
	button.add_theme_font_size_override("font_size",20)
	_place(button,left,0.856,left+0.12,0.924)
	button.pressed.connect(func() -> void:
		_page+=delta
		_refresh())
	add_child(button)
	return button

func _refresh() -> void:
	_reputation_label.text = "江湖声望 %d · %s" % [GameState.reputation, GameState.get_reputation_title()]
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	var entries := BountyManager.get_board_entries(_city_id)
	var page_count := maxi(1,ceili(entries.size()/2.0))
	_page=clampi(_page,0,page_count-1)
	_previous_page.visible=page_count>1
	_previous_page.disabled=_page==0
	_next_page.visible=page_count>1
	_next_page.disabled=_page>=page_count-1
	if entries.is_empty():
		var empty := _make_label(24, Color("503a2c"), HORIZONTAL_ALIGNMENT_CENTER)
		empty.text = "今日暂无与少侠身手相称的榜文。"
		empty.custom_minimum_size = Vector2(0, 210)
		_list.add_child(empty)
		return
	var visible_entries: Array = entries.slice(_page*2, _page*2+2)
	for entry_index: int in range(visible_entries.size()):
		_list.add_child(_build_entry(visible_entries[entry_index], entry_index))


func _build_entry(entry: Dictionary, entry_index: int = 0) -> Control:
	var card := PanelContainer.new()
	card.name = "BountyEntry_%s" % String(entry.bounty_id)
	card.custom_minimum_size = Vector2(0, 244)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.93, 0.86, 0.68, 0.015), Color.TRANSPARENT, 0, 0, 0))
	var content := Control.new()
	content.name = "Content"
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(content)
	# The VBox's second 244px card starts above the lower parchment painted in
	# the full-screen artwork. PanelContainer owns its direct child's rect, so
	# apply one shared optical inset to the three dynamic regions themselves.
	var row_shift := 0.095 if entry_index == 1 else 0.0

	var portrait := Label.new()
	portrait.name = "Seal"
	portrait.text = String(entry.display_name).left(1)
	portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait.add_theme_font_size_override("font_size", 52)
	portrait.add_theme_color_override("font_color", Color("d0b67b"))
	# The circular frame is already baked into the board art. A transparent
	# label keeps the glyph centered without drawing a second, mismatched disc.
	_place(portrait, 0.025, 0.145 + row_shift, 0.155, 0.855 + row_shift)
	content.add_child(portrait)

	var text_box := VBoxContainer.new()
	text_box.name = "TextColumn"
	text_box.add_theme_constant_override("separation", 2)
	_place(text_box, 0.195, 0.160 + row_shift, 0.780, 0.920 + row_shift)
	content.add_child(text_box)
	var name_label := _make_label(31, Color("24140d"))
	name_label.name = "Name"
	name_label.text = "%s　「%s」" % [entry.display_name, entry.title]
	text_box.add_child(name_label)
	var level := _make_label(22, Color("17453e"))
	level.name = "LevelAndStatus"
	level.text = "建议抓捕等级：%s　　状态：%s" % [entry.level_text, STATUS_LABELS.get(String(entry.status), "未知")]
	text_box.add_child(level)
	var description := _make_label(22, Color("30271f"))
	description.name = "Description"
	description.text = String(entry.description)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_box.add_child(description)
	var location := _make_label(22, Color("59300e"))
	location.name = "Location"
	match StringName(entry.status):
		&"evidence": location.text = "交验地点：%s" % entry.location_label
		&"active": location.text = "当前线报：%s" % entry.location_label
		&"decision": location.text = "回去听他解释：%s" % entry.location_label
		_: location.text = "藏身范围：接榜后查明"
	text_box.add_child(location)
	var rewards := _make_label(22, Color("103d29"))
	rewards.name = "Rewards"
	rewards.text = "交验奖励：%s" % entry.reward_text
	rewards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.add_child(rewards)

	var button := Button.new()
	button.name = "AcceptButton"
	button.text = STATUS_LABELS.get(String(entry.status), "查看")
	button.disabled = StringName(entry.status) != BountyManager.STATUS_AVAILABLE
	# The baked vermilion plaque is visually heavy; use a larger label so the
	# action reads as the plaque's focal point instead of floating inside it.
	button.add_theme_font_size_override("font_size", 32)
	button.add_theme_color_override("font_color", Color("f4dfb2"))
	button.add_theme_color_override("font_disabled_color", Color("a99471"))
	button.add_theme_stylebox_override("normal", _panel_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 8, 8))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.45, 0.10, 0.06, 0.34), Color("f0c477"), 2, 8, 8))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.08, 0.06, 0.05, 0.18), Color.TRANSPARENT, 0, 8, 8))
	button.pressed.connect(_accept.bind(StringName(entry.bounty_id)))
	_place(button, 0.855, 0.185 + row_shift, 0.970, 0.815 + row_shift)
	content.add_child(button)
	return card


func _make_label(font_size: int, color: Color, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _place(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _accept(bounty_id: StringName) -> void:
	BountyManager.accept_bounty(bounty_id)
	_refresh()


func _panel_style(fill: Color, border: Color, width: int, radius: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style


func _close() -> void:
	SceneRouter.go_field_smart(StringName(_payload.get("return_scene", SceneRouter.START_FIELD_SCENE)),
		_payload.get("return_spawn", null),"",-1,int(_payload.get("return_local_layout_version",-1)))


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
