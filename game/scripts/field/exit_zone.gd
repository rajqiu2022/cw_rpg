class_name ExitZone
extends Area2D

signal exit_triggered(target_scene: String, target_pos: Vector2)
signal exit_action_triggered(action: String)
signal exit_locked(label: String)

@export var exit_label: String = "前往"
@export var destination_name: String = ""
@export var target_scene_id: String = ""
@export var target_spawn_pos: Vector2 = Vector2(0.5, 0.5)
@export var action: String = ""
@export var auto_trigger: bool = false
@export var is_locked: bool = false
@export var marker_rotation_degrees: float = 0.0
@export var always_show_destination: bool = false
@export var destination_label_side: float = 1.0

@onready var prompt: Label = get_node_or_null("Prompt") as Label
@onready var indicator: Label = get_node_or_null("Indicator") as Label
@onready var marker_visual: Sprite2D = get_node_or_null("MarkerVisual") as Sprite2D

var _arrow_time := 0.0
var _in_range := false
var _marker_anchor_offset := Vector2(0.0, -40.0)
var _destination_render_scale := 1.0


func _ready() -> void:
	add_to_group("exit_zone")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(100, 200)
	var collider := get_node("CollisionShape2D") as CollisionShape2D
	if collider != null:
		collider.shape = shape

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	input_pickable = true
	if marker_visual != null:
		marker_visual.rotation_degrees = marker_rotation_degrees
		marker_visual.modulate = Color(1.0, 1.0, 1.0, 0.96)
		if is_locked:
			marker_visual.modulate = Color(0.94, 0.28, 0.12, 0.92)
	if indicator != null:
		indicator.visible = false
	if prompt != null:
		prompt.text = _display_destination()
		prompt.visible = always_show_destination
		if always_show_destination:
			prompt.add_theme_font_size_override("font_size", 24)
			prompt.add_theme_color_override("font_color", Color(1.0, 0.88, 0.54, 1.0))
			prompt.add_theme_color_override("font_outline_color", Color(0.055, 0.040, 0.020, 0.98))
			prompt.add_theme_constant_override("outline_size", 3)
			_apply_destination_render_scale()


func _process(delta: float) -> void:
	_arrow_time += delta
	var bob: float = sin(_arrow_time * 2.4) * (5.0 if _in_range else 4.0)
	if marker_visual != null:
		marker_visual.position = _marker_anchor_offset + Vector2(0.0, bob)
		var scale_factor: float = 0.092 if _in_range else 0.080
		marker_visual.scale = Vector2.ONE * scale_factor


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_in_range = true
	if not auto_trigger and prompt != null:
		prompt.text = _display_destination()
		prompt.visible = true
	if auto_trigger and target_scene_id != "":
		exit_triggered.emit(target_scene_id, target_spawn_pos)
		return
	if auto_trigger and action != "":
		exit_action_triggered.emit(action)


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_in_range = false
		if prompt != null:
			prompt.visible = always_show_destination


func configure_marker(world_position: Vector2, world_size: Vector2, authored_offset: Vector2 = Vector2.ZERO) -> void:
	var desired_position: Vector2 = world_position + authored_offset + Vector2(0.0, -40.0)
	var safe_position := Vector2(
		# The prompt is 200 px wide and starts 140 px left of the marker, so a
		# 150 px edge inset keeps the arrow and its 200 px prompt clear of the
		# scene-title plaque. The former 440 px right inset pulled
		# true edge exits back onto nearby building entrances.
		clampf(desired_position.x, 120.0, maxf(120.0, world_size.x - 150.0)),
		clampf(desired_position.y, 120.0, maxf(120.0, world_size.y - 130.0))
	)
	_marker_anchor_offset = safe_position - world_position
	if marker_visual != null:
		marker_visual.position = _marker_anchor_offset
	if prompt != null:
		if always_show_destination:
			var label_x := 26.0 if destination_label_side >= 0.0 else -226.0
			prompt.position = _marker_anchor_offset + Vector2(label_x, -13.0)
			prompt.size = Vector2(200.0, 34.0)
			prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if destination_label_side >= 0.0 else HORIZONTAL_ALIGNMENT_RIGHT
		else:
			prompt.position = _marker_anchor_offset + Vector2(-140.0, 28.0)


func configure_destination_render_scale(camera_zoom: float) -> void:
	# Destination names live below the moving world camera. Rendering them at the
	# inverse camera scale makes the final glyph transform exactly 1:1 in screen
	# pixels, instead of rasterizing at 19 px and then enlarging it by 1.25x.
	_destination_render_scale = 1.0 / maxf(camera_zoom, 0.001)
	_apply_destination_render_scale()


func _apply_destination_render_scale() -> void:
	if prompt == null or not always_show_destination:
		return
	prompt.scale = Vector2.ONE * _destination_render_scale


func _display_destination() -> String:
	if destination_name.strip_edges() != "":
		return destination_name
	if exit_label.strip_edges() != "":
		return exit_label
	return "前往下一处"


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var tapped: bool = event is InputEventScreenTouch and event.pressed
	if (clicked or tapped) and _in_range:
		_activate()


func try_interact() -> bool:
	if not _in_range:
		return false
	return _activate()


func _activate() -> bool:
	if is_locked:
		exit_locked.emit(exit_label)
		return true
	if action != "":
		exit_action_triggered.emit(action)
		return true
	if target_scene_id != "":
		exit_triggered.emit(target_scene_id, target_spawn_pos)
		return true
	return false
