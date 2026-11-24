extends "res://scripts/field/exit_zone.gd"
## Exact authored walkable passage; no radius across walls/water.
const READY_OUTLINE := preload("res://build/luoyang_hall_portal_fix_20261024a_system01/portal_interaction_outline_CANDIDATE.gdshader")
var _doorway_polygon := PackedVector2Array()
var _player: Player
var _safe_foot_guard: Callable
var _ready_material: ShaderMaterial

func _ready() -> void:
	super._ready()
	if marker_visual != null:
		_ready_material = ShaderMaterial.new()
		_ready_material.shader = READY_OUTLINE
		_ready_material.set_shader_parameter("outline_color", Color(0.55, 0.94, 1.0, 1.0))
		_ready_material.set_shader_parameter("outline_width", 24.0)
		_ready_material.set_shader_parameter("base_strength", 0.0)
		_ready_material.set_shader_parameter("pulse", 0.0)
		marker_visual.material = _ready_material

func _process(delta: float) -> void:
	_in_range = can_enter()
	super._process(delta)
	if marker_visual != null:
		marker_visual.modulate = Color(1.18, 1.12, 1.0, 1.0) if _in_range else (Color(0.94, 0.28, 0.12, 0.92) if is_locked else Color(1.0, 1.0, 1.0, 0.96))
	if _ready_material != null:
		_ready_material.set_shader_parameter("pulse", 1.0 if _in_range else 0.0)

func can_enter() -> bool:
	return not is_locked and (not action.is_empty() or not target_scene_id.is_empty()) and _doorway_safe()

func configure_doorway(polygon_world: PackedVector2Array, player: Player, guard: Callable) -> void:
	_player = player
	_safe_foot_guard = guard
	_doorway_polygon.clear()
	for point: Vector2 in polygon_world: _doorway_polygon.append(point - position)
	var shape := get_node("CollisionShape2D") as CollisionShape2D
	shape.disabled = true
	var polygon := CollisionPolygon2D.new()
	polygon.name = "DoorwayPolygon"
	polygon.polygon = _doorway_polygon
	add_child(polygon)

func bind_doorway_player(player: Player) -> void:
	_player = player

func try_interact() -> bool:
	return _activate()

func _activate() -> bool:
	# Native Area2D mouse input also calls _activate directly in ExitZone. It
	# must obey the same authored foot contract as the Field pointer/Space path.
	if not can_enter():
		if is_locked and _doorway_safe():
			exit_locked.emit(exit_label)
			return true
		return false
	return super._activate()

func _doorway_safe() -> bool:
	if not is_instance_valid(_player) or _doorway_polygon.size() < 3 or not _safe_foot_guard.is_valid(): return false
	# Physics broad overlap alone admits the actor circle just outside a wall.
	# Require its actual foot center in the authored polygon and safe nav too.
	if not Geometry2D.is_point_in_polygon(to_local(_player.global_position), _doorway_polygon): return false
	if not bool(_safe_foot_guard.call(_player.global_position)): return false
	return true
