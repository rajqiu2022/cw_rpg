extends Control

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")

## 全局对话框 UI。

## 由 DialogPlayer autoload 实例化挂在根节点，所有场景共用同一个实例。
## 自身不持有任何对话状态；只订阅 DialogPlayer 信号渲染 + 把输入转发给 DialogPlayer。

@onready var backdrop: ColorRect = %Backdrop
@onready var frame_bg: ColorRect = $Frame/FrameBg
@onready var frame_border: ColorRect = $Frame/FrameBorder
@onready var portrait: TextureRect = %Portrait
@onready var speaker_label: Label = %SpeakerLabel
@onready var text_label: RichTextLabel = %TextLabel
@onready var continue_hint: Label = %ContinueHint
@onready var choices_container: VBoxContainer = %ChoicesContainer



func _ready() -> void:
	DialogPlayer.text_displayed.connect(_on_text_displayed)
	DialogPlayer.choices_displayed.connect(_on_choices_displayed)
	DialogPlayer.dialog_ended.connect(_on_dialog_ended)
	_apply_visual_style()
	visible = false

	# 输入处理设为 stop，避免对话开启时误点底层 Field 热点
	mouse_filter = Control.MOUSE_FILTER_STOP


func _input(event: InputEvent) -> void:
	if not visible: return
	if choices_container.visible: return  # 选项中，必须点选项按钮

	var advance := false
	if event.is_action_pressed("ui_accept"):
		advance = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true

	if advance:
		get_viewport().set_input_as_handled()
		DialogPlayer.advance()


# --- DialogPlayer 信号回调 ---

func _on_text_displayed(speaker: String, text: String, has_choices: bool, portrait_path: String) -> void:
	visible = true

	if speaker != "":
		speaker_label.text = speaker
		speaker_label.visible = true
	else:
		speaker_label.visible = false

	text_label.text = text

	if portrait_path != "" and ResourceLoader.exists(portrait_path):
		portrait.texture = load(portrait_path)
		portrait.visible = true
	else:
		portrait.visible = false

	choices_container.visible = false
	_clear_choice_buttons()
	continue_hint.visible = not has_choices


func _on_choices_displayed(choices: Array) -> void:
	choices_container.visible = true
	continue_hint.visible = false
	_clear_choice_buttons()
	for i in choices.size():
		var c: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = String(c.get("text", "..."))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 48)
		UI_THEME.style_button(btn, 18, UI_THEME.GOLD)
		var captured_idx := i
		btn.pressed.connect(func(): DialogPlayer.choose(captured_idx))
		choices_container.add_child(btn)



func _on_dialog_ended(_id: StringName) -> void:
	visible = false
	_clear_choice_buttons()


func _apply_visual_style() -> void:
	backdrop.color = Color(0.008, 0.012, 0.018, 0.56)
	if frame_bg != null:
		frame_bg.color = Color(0.030, 0.050, 0.066, 0.94)
	if frame_border != null:
		frame_border.color = Color(0.26, 0.40, 0.50, 0.56)
	UI_THEME.style_label(speaker_label, 26, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_rich_text(text_label, 20)
	UI_THEME.style_label(continue_hint, 14, UI_THEME.MUTED, false)


func _clear_choice_buttons() -> void:

	for c in choices_container.get_children():
		c.queue_free()
