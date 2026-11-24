class_name FormalConfirmDialog
extends Control

## 全局通用的正式确认 / 提示框。
## 文案由调用者提供；底图与按钮三态统一复用已验收的角色界面素材。

signal confirmed
signal cancelled

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const PANEL_ART := preload("res://art/ui/character/character_confirm_panel_v2.png")
const BTN_NORMAL := preload("res://art/ui/button/btn_menu_frame_normal.png")
const BTN_HOVER := preload("res://art/ui/button/btn_menu_frame_hover.png")
const BTN_PRESSED := preload("res://art/ui/button/btn_menu_frame_pressed.png")

@onready var _panel_art: TextureRect = %ConfirmPanelArt
@onready var _title: Label = %ConfirmTitle
@onready var _message: RichTextLabel = %ConfirmMessage
@onready var _confirm_button: Button = %ConfirmAction
@onready var _cancel_button: Button = %CancelAction

var _notice_mode := false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_confirm_button.pressed.connect(_accept)
	_cancel_button.pressed.connect(_cancel)
	_install_button_style(_confirm_button)
	_install_button_style(_cancel_button)


func show_confirm(
	title_text: String,
	body_bbcode: String,
	confirm_text: String = "确认",
	cancel_text: String = "取消"
) -> void:
	_notice_mode = false
	_title.text = title_text
	_message.text = body_bbcode
	_confirm_button.text = confirm_text
	_cancel_button.text = cancel_text
	_cancel_button.visible = true
	_confirm_button.position = Vector2(136, 238)
	_cancel_button.position = Vector2(344, 238)
	_open()


func show_notice(
	title_text: String,
	body_bbcode: String,
	confirm_text: String = "确定"
) -> void:
	_notice_mode = true
	_title.text = title_text
	_message.text = body_bbcode
	_confirm_button.text = confirm_text
	_cancel_button.visible = false
	_confirm_button.position = Vector2(240, 238)
	_open()


func close_dialog() -> void:
	visible = false


func is_open() -> bool:
	return visible


func _open() -> void:
	visible = true
	move_to_front()
	_confirm_button.grab_focus()


func _accept() -> void:
	close_dialog()
	confirmed.emit()


func _cancel() -> void:
	close_dialog()
	cancelled.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		if _notice_mode:
			_accept()
		else:
			_cancel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_accept()
		get_viewport().set_input_as_handled()


func _install_button_style(button: Button) -> void:
	button.flat = false
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", UI_THEME.TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", UI_THEME.GOLD_LIGHT)
	button.add_theme_stylebox_override("normal", _texture_stylebox(BTN_NORMAL))
	button.add_theme_stylebox_override("hover", _texture_stylebox(BTN_HOVER))
	button.add_theme_stylebox_override("pressed", _texture_stylebox(BTN_PRESSED))
	button.add_theme_stylebox_override("focus", _texture_stylebox(BTN_HOVER))


func _texture_stylebox(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 24.0
	style.texture_margin_top = 12.0
	style.texture_margin_right = 24.0
	style.texture_margin_bottom = 12.0
	style.content_margin_left = 20.0
	style.content_margin_top = 8.0
	style.content_margin_right = 20.0
	style.content_margin_bottom = 8.0
	return style
