extends Node

const CURSOR_ARROW_PATH := "res://art/ui/cursors/cursor_arrow.png"
const CURSOR_HAND_PATH := "res://art/ui/cursors/cursor_hand.png"
const CURSOR_WAIT_PATH := "res://art/ui/cursors/cursor_wait.png"

var _arrow: Texture2D = null
var _hand: Texture2D = null
var _wait: Texture2D = null
var _is_waiting := false


func _ready() -> void:
	_load_cursors()
	apply_cursors()


func _load_cursors() -> void:
	if ResourceLoader.exists(CURSOR_ARROW_PATH):
		_arrow = load(CURSOR_ARROW_PATH)
	if ResourceLoader.exists(CURSOR_HAND_PATH):
		_hand = load(CURSOR_HAND_PATH)
	if ResourceLoader.exists(CURSOR_WAIT_PATH):
		_wait = load(CURSOR_WAIT_PATH)


func apply_cursors() -> void:
	if _arrow != null:
		Input.set_custom_mouse_cursor(_arrow, Input.CURSOR_ARROW, Vector2(6, 4))
	if _hand != null:
		Input.set_custom_mouse_cursor(_hand, Input.CURSOR_POINTING_HAND, Vector2(17, 9))
	if _wait != null:
		Input.set_custom_mouse_cursor(_wait, Input.CURSOR_WAIT, Vector2(24, 24))
	set_waiting(_is_waiting)


func set_waiting(waiting: bool) -> void:
	_is_waiting = waiting
	if waiting:
		Input.set_default_cursor_shape(Input.CURSOR_WAIT)
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func with_wait_cursor(callable: Callable) -> void:
	set_waiting(true)
	callable.call()
	set_waiting(false)
