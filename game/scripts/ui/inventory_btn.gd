class_name InventoryBtn
extends Control
## 通用背包按钮组件 — 底框 + 彩色条 + 文字 + 三态

signal pressed

@export var btn_text: String = "按钮":
	set(v):
		btn_text = v
		if _label: _label.text = v

@export var accent_color: Color = Color(0.24, 0.78, 0.90):  ## 青/红/绿
	set(v):
		accent_color = v
		if _accent: _accent.color = v

@onready var _bg: TextureRect = %Bg
@onready var _accent: ColorRect = %Accent
@onready var _label: Label = %Label

var _hovered: bool = false
var _pressed: bool = false


func _ready() -> void:
	_label.text = btn_text
	_accent.color = accent_color
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)
	gui_input.connect(_on_input)


func _on_enter() -> void:
	_hovered = true
	_update_state()


func _on_exit() -> void:
	_hovered = false
	_pressed = false
	_update_state()


func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_pressed = true
				_update_state()
			else:
				if _pressed and _hovered:
					emit_signal("pressed")
				_pressed = false
				_update_state()


func _update_state() -> void:
	if _pressed:
		_bg.modulate = Color(0.55, 0.55, 0.55, 1)
		_label.modulate = Color(0.7, 0.75, 0.82, 1)
	elif _hovered:
		_bg.modulate = Color(1.35, 1.35, 1.35, 1)
		_label.modulate = Color(1, 1, 1, 1)
		_accent.color = accent_color.lightened(0.3)
	else:
		_bg.modulate = Color(1, 1, 1, 1)
		_label.modulate = Color(0.92, 0.94, 0.98, 1)
		_accent.color = accent_color
