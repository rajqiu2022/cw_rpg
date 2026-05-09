class_name Player
extends CharacterBody2D

## 玩家在场景中的移动控制器。
##
## - WASD / 方向键移动
## - 速度 480 px/s（1920x1080 场景下适中）
## - 空格 / Enter / Z 交互键
## - 使用四方向主角行走 sprite sheet

signal interacted      ## 玩家按了交互键
signal moved(global_pos: Vector2)  ## 移动时广播位置

const SPEED: float = 480.0
const HORIZONTAL_FRAME_SECONDS := 0.10
const VERTICAL_FRAME_SECONDS := 0.18

const WALK_TEXTURES := {
	"right": preload("res://art/characters/lengguyun_walk_right_8f.png"),
	"left": preload("res://art/characters/lengguyun_walk_left_8f.png"),
	"down": preload("res://art/characters/lengguyun_walk_down_4f.png"),
	"up": preload("res://art/characters/lengguyun_walk_up_4f.png"),
}

const WALK_FRAME_COUNTS := {
	"right": 8,
	"left": 8,
	"down": 4,
	"up": 4,
}

@onready var sprite: Sprite2D = $Sprite2D
@onready var interact_area: Area2D = $InteractArea

var can_move: bool = true
var _direction := "down"
var _frame_timer := 0.0

func _ready() -> void:
	add_to_group("player")
	sprite.centered = true
	sprite.scale = Vector2.ONE
	set_walk_direction(Vector2.DOWN, false)

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		set_walk_direction(Vector2.ZERO, false)
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * SPEED
	set_walk_direction(input_dir, input_dir != Vector2.ZERO)
	if input_dir != Vector2.ZERO:
		_advance_walk_frame(delta)

	if input_dir != Vector2.ZERO:
		emit_signal("moved", global_position)

	move_and_slide()

func set_can_move(enabled: bool) -> void:
	can_move = enabled
	velocity = Vector2.ZERO

func uses_directional_walk_sprites() -> bool:
	return true

func set_walk_direction(input_dir: Vector2, moving: bool) -> void:
	if input_dir != Vector2.ZERO:
		if absf(input_dir.x) >= absf(input_dir.y):
			_direction = "right" if input_dir.x > 0.0 else "left"
		else:
			_direction = "down" if input_dir.y > 0.0 else "up"

	_apply_direction(_direction)
	if not moving:
		sprite.frame = 0
		_frame_timer = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not can_move:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		emit_signal("interacted")

func _apply_direction(direction: String) -> void:
	var texture: Texture2D = WALK_TEXTURES[direction]
	var frame_count: int = WALK_FRAME_COUNTS[direction]
	if sprite.texture == texture and sprite.hframes == frame_count:
		return
	sprite.texture = texture
	sprite.hframes = frame_count
	sprite.vframes = 1
	sprite.frame = 0
	_frame_timer = 0.0

func _advance_walk_frame(delta: float) -> void:
	var frame_count: int = WALK_FRAME_COUNTS[_direction]
	var frame_seconds := HORIZONTAL_FRAME_SECONDS
	if _direction == "up" or _direction == "down":
		frame_seconds = VERTICAL_FRAME_SECONDS

	_frame_timer += delta
	while _frame_timer >= frame_seconds:
		_frame_timer -= frame_seconds
		sprite.frame = (sprite.frame + 1) % frame_count
