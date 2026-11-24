extends Node
## Bed depth follows the slanted floor footprint, not the rightmost footboard
## across its entire width. Collision and visual texture remain unchanged.

var _field: Node
var _bed: Sprite2D

func _ready() -> void:
	_bed = get_parent() as Sprite2D
	_field = _bed
	while _field != null and not _field.has_method("get_field_loading_state"):
		_field = _field.get_parent()
	set_process(_field != null)

func _process(_delta: float) -> void:
	var hero := _field.get("_player") as Player
	var world := _field.get("world_container") as Node2D
	var extent: Vector2 = _field.get("_world_size")
	if not is_instance_valid(hero) or not is_instance_valid(world) or extent.x <= 0.0:
		return
	var x: float = world.to_local(hero.global_position).x / extent.x
	var y := lerpf(0.596, 0.627, clampf(inverse_lerp(0.174, 0.219, x), 0.0, 1.0))
	if x > 0.219:
		y = lerpf(0.627, 0.650, clampf(inverse_lerp(0.219, 0.271, x), 0.0, 1.0))
	var band := clampi(floori(world.to_global(Vector2(0.0, y * extent.y)).y / 8.0), 0, 255)
	if _bed.z_index != band:
		_bed.z_index = band
