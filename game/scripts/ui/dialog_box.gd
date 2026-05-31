extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")

## 全局对话框 UI。
## 由 DialogPlayer autoload 实例化挂在根节点，所有场景共用同一个实例。

const DIALOG_FRAME_PATH := "res://art/ui/field_hud/v2/hud_dialog_frame_v8.png"
const PROTAGONIST_PORTRAIT := "res://art/characters/protagonist_portrait.png"

@onready var frame_art: TextureRect = $Frame/FrameArt
@onready var portrait: TextureRect = %Portrait
@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: RichTextLabel = %TextLabel
@onready var continue_hint: Label = %ContinueHint
@onready var choices_container: VBoxContainer = %ChoicesContainer

var _choice_labels: Array[Label] = []
var _choice_rows: Array[PanelContainer] = []
var _choice_rects: Array[Rect2] = []
var _hovered_idx: int = -1
var _choice_bg_normal: StyleBoxFlat
var _choice_bg_hover: StyleBoxFlat


func _ready() -> void:
	DialogPlayer.text_displayed.connect(_on_text_displayed)
	DialogPlayer.choices_displayed.connect(_on_choices_displayed)
	DialogPlayer.dialog_ended.connect(_on_dialog_ended)
	_apply_visual_style()
	_load_frame_texture()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func _load_frame_texture() -> void:
	var image: Image = Image.new()
	if image.load(DIALOG_FRAME_PATH) == OK:
		var tex := ImageTexture.create_from_image(image)
		if frame_art != null:
			frame_art.texture = tex


func _input(event: InputEvent) -> void:
	if not visible:
		return

	# 选择模式：处理键盘数字键、鼠标悬停和点击
	if choices_container.visible and _choice_rects.size() > 0:
		if event.is_action_pressed("ui_accept"):
			return

		# 键盘数字键 1-9
		if event is InputEventKey and event.pressed:
			var key := (event as InputEventKey).keycode
			if key >= KEY_1 and key <= KEY_9:
				var idx := key - KEY_1
				if idx < _choice_rects.size():
					get_viewport().set_input_as_handled()
					DialogPlayer.choose(idx)
					return

		# 鼠标移动 — 更新悬停高亮
		if event is InputEventMouseMotion:
			_update_hover((event as InputEventMouseMotion).position)

		# 鼠标点击
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var pos := (event as InputEventMouseButton).position
			for i in _choice_rects.size():
				if _choice_rects[i].has_point(pos):
					get_viewport().set_input_as_handled()
					DialogPlayer.choose(i)
					return
		return

	# 普通模式：空格/鼠标点击推进对话
	var advance := false
	if event.is_action_pressed("ui_accept"):
		advance = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true

	if advance:
		get_viewport().set_input_as_handled()
		DialogPlayer.advance()


func _on_text_displayed(speaker: String, text: String, has_choices: bool, portrait_path: String) -> void:
	if not is_node_ready():
		await ready
	if speaker_label == null or text_label == null:
		return
	visible = true

	if speaker != "":
		speaker_label.text = speaker
		speaker_label.visible = true
	else:
		speaker_label.visible = false

	text_label.text = text

	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		if portrait != null:
			portrait.texture = load(portrait_path)
			portrait.visible = true
	else:
		if portrait != null:
			portrait.visible = false

	if choices_container != null:
		choices_container.visible = false
	_clear_choices()
	if continue_hint != null:
		continue_hint.visible = not has_choices


func _on_choices_displayed(choices: Array) -> void:
	if choices_container != null:
		choices_container.visible = true
	if continue_hint != null:
		continue_hint.visible = false
	# 选择出现时切换到主角说话 + 主角头像
	if speaker_label != null:
		speaker_label.text = "冷孤云"
		speaker_label.visible = true
	if portrait != null and ResourceLoader.exists(PROTAGONIST_PORTRAIT):
		portrait.texture = load(PROTAGONIST_PORTRAIT)
		portrait.visible = true
	_clear_choices()

	_choice_bg_normal = UI_THEME.panel(UI_THEME.WOOD, UI_THEME.GOLD, 8, 1)
	_choice_bg_hover = UI_THEME.panel(Color(0.05, 0.18, 0.22, 0.98), UI_THEME.GOLD_LIGHT, 8, 2)
	_hovered_idx = -1
	for i in choices.size():
		var c: Dictionary = choices[i]
		var row: PanelContainer = PanelContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size = Vector2(0, 48)
		row.add_theme_stylebox_override("panel", _choice_bg_normal)

		var lbl: Label = Label.new()
		lbl.text = "  %d. %s" % [i + 1, String(c.get("text", "..."))]
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		UI_THEME.style_label(lbl, 20, UI_THEME.GOLD)
		row.add_child(lbl)
		_choice_labels.append(lbl)
		_choice_rows.append(row)
		choices_container.add_child(row)

	# 等一帧让布局计算完，再缓存点击区域
	await get_tree().process_frame
	_refresh_choice_rects()


func _refresh_choice_rects() -> void:
	_choice_rects.clear()
	for lbl in _choice_labels:
		if is_instance_valid(lbl) and lbl.is_visible_in_tree():
			var global_rect := lbl.get_global_rect()
			# 扩展点击区域到整个 choices_container 的宽度
			var container_global := choices_container.get_global_rect()
			global_rect.position.x = container_global.position.x
			global_rect.size.x = container_global.size.x
			_choice_rects.append(global_rect)


func _update_hover(mouse_pos: Vector2) -> void:
	var new_idx := -1
	for i in _choice_rects.size():
		if _choice_rects[i].has_point(mouse_pos):
			new_idx = i
			break
	if new_idx == _hovered_idx:
		return
	# 还原旧悬停
	if _hovered_idx >= 0 and _hovered_idx < _choice_rows.size():
		var old_row := _choice_rows[_hovered_idx]
		if is_instance_valid(old_row):
			old_row.add_theme_stylebox_override("panel", _choice_bg_normal)
		var old_lbl := _choice_labels[_hovered_idx]
		if is_instance_valid(old_lbl):
			UI_THEME.style_label(old_lbl, 20, UI_THEME.GOLD)
	# 设置新悬停
	if new_idx >= 0 and new_idx < _choice_rows.size():
		var new_row := _choice_rows[new_idx]
		if is_instance_valid(new_row):
			new_row.add_theme_stylebox_override("panel", _choice_bg_hover)
		var new_lbl := _choice_labels[new_idx]
		if is_instance_valid(new_lbl):
			UI_THEME.style_label(new_lbl, 20, UI_THEME.GOLD_LIGHT)
	_hovered_idx = new_idx


func _on_dialog_ended(_id: StringName) -> void:
	visible = false
	_clear_choices()


func _apply_visual_style() -> void:
	UI_THEME.style_label(speaker_label, 18, Color(0.70, 0.88, 0.95, 1.0))
	UI_THEME.style_rich_text(text_label, 24)
	UI_THEME.style_label(continue_hint, 14, UI_THEME.MUTED, false)


func _clear_choices() -> void:
	_hovered_idx = -1
	for lbl in _choice_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_choice_labels.clear()
	_choice_rows.clear()
	_choice_rects.clear()
	for c in choices_container.get_children():
		c.queue_free()
