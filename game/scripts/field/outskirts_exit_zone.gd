extends ExitZone
## Explicit actual-feet range for only the three new local-field waymarkers.
var _feet_rect := Rect2()
var _feet_position: Callable
var _feet_clearance: Callable

func configure_feet(rect: Rect2, position: Callable, clearance: Callable) -> void:
	_feet_rect = rect
	_feet_position = position
	_feet_clearance = clearance

func _can_enter() -> bool:
	if not _feet_position.is_valid() or not _feet_clearance.is_valid(): return false
	var feet: Vector2 = _feet_position.call()
	return feet.is_finite() and _feet_rect.has_point(feet) and bool(_feet_clearance.call(feet))

func try_interact() -> bool:
	return _activate() if _can_enter() else false

func _activate() -> bool:
	return super._activate() if _can_enter() else false
