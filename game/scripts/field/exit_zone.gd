class_name ExitZone
extends Area2D

## 场景出口 / 传送门。
## 玩家走进该区域时显示提示，按交互键触发场景切换。

signal exit_triggered(target_scene: String, target_pos: Vector2)

@export var exit_label: String = "前往"
@export var target_scene_id: String = ""
@export var target_spawn_pos: Vector2 = Vector2(0.5, 0.5)
@export var auto_trigger: bool = false  ## true=走进自动触发，false=需交互键

@onready var prompt: Label = $Prompt

func _ready() -> void:
	add_to_group("exit_zone")
	
	## 设置碰撞形状
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(100, 200)
	var collider: CollisionShape2D = get_node("CollisionShape2D")
	if collider != null:
		collider.shape = shape
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.visible = false

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if auto_trigger and target_scene_id != "":
		emit_signal("exit_triggered", target_scene_id, target_spawn_pos)
		return
	prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	prompt.visible = false

func try_interact() -> bool:
	if not prompt.visible:
		return false
	if target_scene_id != "":
		emit_signal("exit_triggered", target_scene_id, target_spawn_pos)
		return true
	return false
