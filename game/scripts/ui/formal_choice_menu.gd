class_name FormalChoiceMenu
extends Control

## 与 FormalConfirmDialog 配套的通用选项面板，用于替代系统原生 PopupMenu / OptionButton。

signal item_selected(item_id: StringName)
signal cancelled

const UI_THEME := preload("res://scripts/ui/wuxia_theme.gd")
const PANEL_ART := preload("res://art/ui/character/character_confirm_panel_v2.png")
const BTN_NORMAL := preload("res://art/ui/button/btn_menu_frame_normal.png")
const BTN_HOVER := preload("res://art/ui/button/btn_menu_frame_hover.png")
const BTN_PRESSED := preload("res://art/ui/button/btn_menu_frame_pressed.png")

@onready var _title: Label = %ChoiceTitle
@onready var _grid: GridContainer = %ChoiceGrid


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	%Backdrop.gui_input.connect(_on_backdrop_input)


func show_choices(title_text: String, options: Array[Dictionary], selected_id: StringName = &"") -> void:
	_title.text = title_text
	for child in _grid.get_children():
		child.queue_free()
	_grid.columns = 1 if options.size() <= 5 else 2
	for option: Dictionary in options:
		var button := Button.new()
		button.custom_minimum_size = Vector2(270, 44)
		button.text = String(option.get("label", option.get("id", "")))
		button.disabled = not bool(option.get("enabled", true))
		button.toggle_mode = true
		var option_id := StringName(option.get("id", &""))
		button.button_pressed = option_id == selected_id
		_install_button_style(button, option_id == selected_id)
		button.pressed.connect(_select.bind(option_id))
		_grid.add_child(button)
	visible = true
	move_to_front()
	if _grid.get_child_count() > 0:
		(_grid.get_child(0) as Control).grab_focus()


func close_menu() -> void:
	visible = false


func is_open() -> bool:
	return visible


func _select(item_id: StringName) -> void:
	close_menu()
	item_selected.emit(item_id)


func _cancel() -> void:
	close_menu()
	cancelled.emit()


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_cancel()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_cancel()
		get_viewport().set_input_as_handled()


func _install_button_style(button: Button, selected: bool) -> void:
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", UI_THEME.GOLD_LIGHT if selected else UI_THEME.TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", UI_THEME.GOLD_LIGHT)
	button.add_theme_color_override("font_disabled_color", Color(0.42, 0.48, 0.50, 0.72))
	button.add_theme_stylebox_override("normal", _texture_stylebox(BTN_HOVER if selected else BTN_NORMAL))
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
	style.content_margin_left = 18.0
	style.content_margin_top = 6.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 6.0
	return style
