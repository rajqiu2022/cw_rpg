class_name NPCNode
extends Node2D

## 场景中的 NPC 节点。
## 玩家走进 interact_area 时显示提示图标，按交互键触发对话。

signal npc_interacted(npc_id: String, dialog_id: String)

@export var npc_id: String = ""
@export var npc_name: String = ""
@export var dialog_id: String = ""
@export var portrait_path: String = ""
@export var sprite_path: String = ""
@export var sprite_scale: float = 0.08

@onready var sprite: Sprite2D = $Sprite2D
@onready var interact_area: Area2D = $InteractArea
@onready var prompt: Label = $Prompt

func _ready() -> void:
	add_to_group("npc")
	
	## 加载 sprite 纹理
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
		var origin_size: float = max(sprite.texture.get_width(), sprite.texture.get_height())
		sprite.scale = Vector2.ONE * (96.0 / origin_size)
	
	## 设置 Area2D 的碰撞形状大小
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(80, 80)
	var collider: CollisionShape2D = interact_area.get_node("CollisionShape2D")
	if collider != null:
		collider.shape = shape
	
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	prompt.visible = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		prompt.visible = false

func try_interact() -> bool:
	## 外部调用：如果玩家在当前交互范围内，触发对话
	if not prompt.visible:
		return false
	if dialog_id != "":
		emit_signal("npc_interacted", npc_id, dialog_id)
		return true
	return false
