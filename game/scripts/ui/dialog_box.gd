extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")

## 全局对话框 UI。
## 由 DialogPlayer autoload 实例化挂在根节点，所有场景共用同一个实例。

const DIALOG_FRAME_PATH := "res://art/ui/field_hud/v2/hud_dialog_frame_v8.png"
const DIALOG_NARRATION_FRAME_PATH := "res://art/ui/field_hud/v2/hud_dialog_narration_frame_v1.png"
@onready var frame_art: TextureRect = $Frame/FrameArt
@onready var portrait: TextureRect = %Portrait
@onready var portrait_placeholder: ColorRect = $Frame/PortraitPlaceholder
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
const PORTRAIT_TEXT_LEFT := 587.48
const NARRATION_TEXT_LEFT := 312.48
const TEXT_RIGHT := 1463.48
const PORTRAIT_SPEAKER_RECT := Rect2(312.48, 230.48, 170.0, 36.0)
const NARRATION_SPEAKER_RECT := Rect2(337.0, 48.0, 230.0, 36.0)
const TEXT_TOP_NORMAL := 69.48
const TEXT_BOTTOM_NORMAL := 250.48
const TEXT_TOP_WITH_CHOICES := 62.0
const TEXT_BOTTOM_WITH_CHOICES := 128.0
const DIALOG_TEXT_FONT_SIZE: int = 24
const NARRATION_TEXT_FONT_SIZE: int = 22

var _portrait_frame_texture: Texture2D
var _narration_frame_texture: Texture2D


func _ready() -> void:
	DialogPlayer.text_displayed.connect(_on_text_displayed)
	DialogPlayer.choices_displayed.connect(_on_choices_displayed)
	DialogPlayer.dialog_ended.connect(_on_dialog_ended)
	_apply_visual_style()
	_load_frame_textures()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP


func _load_frame_textures() -> void:
	if ResourceLoader.exists(DIALOG_FRAME_PATH):
		_portrait_frame_texture = load(DIALOG_FRAME_PATH) as Texture2D
	if ResourceLoader.exists(DIALOG_NARRATION_FRAME_PATH):
		_narration_frame_texture = load(DIALOG_NARRATION_FRAME_PATH) as Texture2D
	_set_frame_variant(false)


func _set_frame_variant(is_narration: bool) -> void:
	if frame_art == null:
		return
	if is_narration and _narration_frame_texture == null and ResourceLoader.exists(DIALOG_NARRATION_FRAME_PATH):
		_narration_frame_texture = load(DIALOG_NARRATION_FRAME_PATH) as Texture2D
	elif not is_narration and _portrait_frame_texture == null and ResourceLoader.exists(DIALOG_FRAME_PATH):
		_portrait_frame_texture = load(DIALOG_FRAME_PATH) as Texture2D
	var frame_texture: Texture2D = _narration_frame_texture if is_narration else _portrait_frame_texture
	if frame_texture != null:
		frame_art.texture = frame_texture


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

	# RichTextLabel can retain its visible-character and scroll state between dialogs.
	# Reset both before appending so narration never renders as a single leading glyph.
	var displayed_text := _choice_summary(text) if has_choices else text
	text_label.clear()
	text_label.visible_characters = -1
	text_label.append_text(displayed_text)
	text_label.scroll_to_line(0)

	var loaded_portrait: Texture2D = null
	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		loaded_portrait = load(portrait_path) as Texture2D
	if loaded_portrait != null:
		if is_instance_valid(portrait):
			portrait.texture = loaded_portrait
			portrait.visible = true
		if portrait_placeholder != null:
			portrait_placeholder.visible = true
		_set_narration_layout(false)
	else:
		if is_instance_valid(portrait):
			portrait.texture = null
			portrait.visible = false
		if portrait_placeholder != null:
			portrait_placeholder.visible = false
		_set_narration_layout(true)

	if choices_container != null:
		choices_container.visible = false
	_clear_choices()
	if continue_hint != null:
		continue_hint.visible = not has_choices


func _on_choices_displayed(choices: Array) -> void:
	# Reserve a hard, clipped upper band for the spoken line. The option stack
	# owns the lower band and never shares pixels with RichTextLabel content.
	text_label.offset_top = TEXT_TOP_WITH_CHOICES
	text_label.offset_bottom = TEXT_BOTTOM_WITH_CHOICES
	text_label.clip_contents = true
	if choices_container != null:
		choices_container.visible = true
	if continue_hint != null:
		continue_hint.visible = false
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
	UI_THEME.style_rich_text(text_label, DIALOG_TEXT_FONT_SIZE)
	_set_dialog_text_font_size(DIALOG_TEXT_FONT_SIZE)
	UI_THEME.style_label(continue_hint, 14, UI_THEME.MUTED, false)


func _set_narration_layout(is_narration: bool) -> void:
	if text_label == null:
		return
	_set_dialog_text_font_size(NARRATION_TEXT_FONT_SIZE if is_narration else DIALOG_TEXT_FONT_SIZE)
	text_label.offset_left = NARRATION_TEXT_LEFT if is_narration else PORTRAIT_TEXT_LEFT
	text_label.offset_right = TEXT_RIGHT
	if speaker_label != null:
		var speaker_rect: Rect2 = NARRATION_SPEAKER_RECT if is_narration else PORTRAIT_SPEAKER_RECT
		speaker_label.position = speaker_rect.position
		speaker_label.size = speaker_rect.size
	_set_frame_variant(is_narration)


func _set_dialog_text_font_size(font_size: int) -> void:
	if text_label == null:
		return
	text_label.add_theme_font_size_override("normal_font_size", font_size)
	text_label.add_theme_font_size_override("bold_font_size", font_size)
	text_label.add_theme_font_size_override("italics_font_size", font_size)
	text_label.add_theme_font_size_override("bold_italics_font_size", font_size)
	text_label.add_theme_font_size_override("mono_font_size", font_size)


func _clear_choices() -> void:
	if text_label != null:
		text_label.offset_top = TEXT_TOP_NORMAL
		text_label.offset_bottom = TEXT_BOTTOM_NORMAL
		text_label.clip_contents = true
	_hovered_idx = -1
	for lbl in _choice_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_choice_labels.clear()
	_choice_rows.clear()
	_choice_rects.clear()
	for c in choices_container.get_children():
		c.queue_free()


func _choice_summary(text: String) -> String:
	# Choices own the lower half of the frame. Keep the spoken setup to one
	# clipped line so variable-length localisation can never paint into a row.
	var first_line := text.split("\n", false)[0].strip_edges()
	if first_line.length() > 34:
		first_line = first_line.left(33) + "…"
	return first_line if first_line != "" else "请选择："
