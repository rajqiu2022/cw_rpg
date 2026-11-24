extends "res://scripts/field/player.gd"
## Reuse the real hero appearance and animation; the local town owns movement.

func _physics_process(_delta: float) -> void:
	pass

func animate_preview(direction: Vector2, moving: bool, delta: float) -> void:
	set_walk_direction(direction, moving)
	if moving:
		_advance_walk_frame(delta)
	else:
		_advance_idle_frame(delta)
