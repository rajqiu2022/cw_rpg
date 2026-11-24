extends CharacterBody2D

@export var atlas_key := "merchant_walk"
@export var route := PackedVector2Array()
@export var walk_speed := 50.0
var enabled := true
var direction_row := 0
var frame_index := 0
var frame_time := 0.0
var destination := 1
var wait_time := 0.8
var frames: Array
var draw_scale := 1.0
var left_runtime_flip := false
var is_walking := false
@onready var art: Sprite2D = $Art

func _ready() -> void:
	var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/modules/redrock_desert_complete_20261028d/atlases.json"))
	frames = config[atlas_key].rows
	left_runtime_flip = bool(config[atlas_key].left_runtime_flip)
	var tallest := 0.0
	for row in frames:
		for frame in row:
			tallest = maxf(tallest, float(frame.height))
	draw_scale = (70.0 if atlas_key == "fox" else 112.0) / tallest
	show_frame()

func show_frame() -> void:
	var frame: Dictionary = frames[direction_row][frame_index]
	var region: Array = frame.region
	art.region_rect = Rect2(region[0], region[1], region[2], region[3])
	art.scale = Vector2.ONE * draw_scale
	art.flip_h = left_runtime_flip and direction_row == 1
	var pivot: Array = frame.pivot
	var px := float(pivot[0])
	if art.flip_h:
		px = float(region[2]) - px
	art.position = -Vector2(px, float(pivot[1])) * draw_scale

func _physics_process(delta: float) -> void:
	is_walking = false
	if not enabled or not is_visible_in_tree():
		return
	var town := get_parent().get_parent()
	if bool(town.show_details):
		return
	if wait_time > 0.0:
		wait_time -= delta
		frame_index = 0
		show_frame()
		return
	if route.size() < 2:
		return
	var target := route[destination]
	var offset := target - global_position
	if offset.length() < 5.0:
		destination = (destination + 1) % route.size()
		wait_time = 1.3
		return
	var hero := get_tree().get_first_node_in_group("player") as Node2D
	if hero != null and global_position.distance_to(hero.global_position) < 105.0:
		frame_index = 0
		show_frame()
		return
	var before := global_position
	velocity = offset.normalized() * minf(walk_speed, offset.length() / delta)
	move_and_slide()
	is_walking = global_position.distance_squared_to(before) > 0.01
	if frames.size() == 1:
		direction_row = 0
		art.flip_h = offset.x > 0.0
	elif absf(offset.x) > absf(offset.y):
		direction_row = 2 if offset.x > 0 else 1
	else:
		direction_row = 0 if offset.y > 0 else 3
	frame_time += delta
	if frame_time >= 0.16:
		frame_time = 0.0
		frame_index = 1 + (frame_index % 3) if is_walking else 0
	show_frame()
	if frames.size() == 1:
		art.flip_h = offset.x > 0.0
	if not is_walking:
		wait_time = 0.5
		destination = (destination + 1) % route.size()
