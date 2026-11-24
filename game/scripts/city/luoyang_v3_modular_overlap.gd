extends "res://scripts/world/outskirts_modular_overlap.gd"
## Ordinary City v3 depth only. Non-occluding water decoration is still in the
## exact-foot/same-8px-band order, but never becomes a ghost alpha contributor.
func add_non_occluding_prop(sprite: Sprite2D, id: String, foot_y: float) -> void:
	if not is_instance_valid(sprite): return
	var foot_global: Vector2 = _world.to_global(Vector2(sprite.position.x, foot_y))
	_register_depth(sprite, id, sprite.to_local(foot_global), false)
