extends Control

signal closed
signal medicine_requested

const JOURNAL := preload("res://scripts/ui/journal_ui.gd")
const THEME := preload("res://scripts/ui/wuxia_theme.gd")
const ENTRIES := [
	{
		"id": &"medicine", "title": "制药", "note": "随身制作",
		"body": "临战药提升伤害、暴击或防御。制好后，在战斗背包里使用。",
		"detail": "竹尾猎径日照好的坡上常有丹参，路肩也能找到紫苏。",
	},
	{
		"id": &"gathering", "title": "采集", "note": "野外采药与采矿",
		"body": "山道、林地和岩壁脚都有药草或矿脉。近处地面亮圈时，按空格采集。",
		"detail": "山道、竹尾后山、洞窟入口营地各有一处可采矿脉。",
	},
	{
		"id": &"smithing", "title": "锻造", "note": "需要铁匠铺",
		"body": "用铁矿和工钱可将一把兵器升至 +3。升满会生成附加效果，并升一品（橙品除外）。",
		"detail": "林西找杜青衫，或在竹尾村的清风商铺选「升级兵器」。",
	},
]

var _heading: Label
var _body: Label
var _detail: Label
var _medicine: Button
var _tabs := ButtonGroup.new()

func _ready() -> void:
	name = "LifeSkillsJournal"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	var frame := JOURNAL.add_frame(self)
	var title := JOURNAL.add_label(frame, "生活技能", Rect2(405, 49, 390, 65), 32, THEME.GOLD_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	JOURNAL.add_label(frame, "技艺名录", Rect2(78, 145, 288, 38), 22, THEME.JADE)
	for index in ENTRIES.size():
		var entry: Dictionary = ENTRIES[index]
		var button := Button.new()
		button.name = String(entry.id).capitalize()
		button.text = entry.title
		button.position = Vector2(78, 221 + index * 64)
		button.size = Vector2(286, 44)
		button.toggle_mode = true
		button.button_group = _tabs
		button.button_pressed = index == 0
		JOURNAL.style_button(button, 20, "primary")
		button.pressed.connect(_select.bind(entry))
		frame.add_child(button)
	_heading = JOURNAL.add_label(frame, "", Rect2(442, 173, 640, 53), 32, THEME.GOLD_LIGHT)
	_body = JOURNAL.add_label(frame, "", Rect2(442, 259, 600, 85), 23)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail = JOURNAL.add_label(frame, "", Rect2(442, 371, 600, 80), 20, THEME.JADE)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_medicine = Button.new()
	_medicine.name = "OpenMedicine"
	_medicine.text = "打开药方"
	_medicine.position = Vector2(899, 622)
	_medicine.size = Vector2(183, 43)
	JOURNAL.style_button(_medicine)
	_medicine.pressed.connect(func() -> void: medicine_requested.emit())
	frame.add_child(_medicine)
	var exit_button := TextureButton.new()
	exit_button.texture_normal = preload("res://art/ui/inventory/buttons/btn_x_normal.png")
	exit_button.texture_hover = preload("res://art/ui/inventory/buttons/btn_x_hover.png")
	exit_button.texture_pressed = preload("res://art/ui/inventory/buttons/btn_x_pressed.png")
	exit_button.ignore_texture_size = true
	exit_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	exit_button.tooltip_text = "关闭（Esc）"
	exit_button.position = Vector2(1122, 34)
	exit_button.size = Vector2(46, 46)
	exit_button.pressed.connect(close)
	frame.add_child(exit_button)
	_select(ENTRIES[0])

func _select(entry: Dictionary) -> void:
	_heading.text = entry.title
	_body.text = "%s\n%s" % [entry.note, entry.body]
	_detail.text = entry.detail
	_medicine.visible = entry.id == &"medicine"

func close() -> void:
	hide()
	closed.emit()
	queue_free()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close()

