class_name NPCNode
extends Node2D

## 场景中的 NPC 节点�?
## 玩家走进 interact_area 时显示提示图标，按交互键触发对话�?
## 支持单帧�?4 �?idle 动画（宽�?> 高度时自动按 hframes 切帧）�?

signal npc_interacted(npc_id: String, dialog_id: String)

const IDLE_FRAME_SECONDS := 0.28

@export var npc_id: String = ""
@export var npc_name: String = ""
@export var dialog_id: String = ""
@export var portrait_path: String = ""
@export var sprite_path: String = ""
@export var sprite_scale: float = 0.08

@onready var sprite: Sprite2D = $Sprite2D
@onready var interact_area: Area2D = $InteractArea
@onready var prompt: Label = $Prompt

var _frame_timer: float = 0.0
var _hframes: int = 1
var _name_label: Label = null
var _in_range: bool = false
var _body_collider: StaticBody2D = null

func _ready() -> void:
	add_to_group("npc")

	## 加载 sprite 纹理
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
		_apply_sprite_scale()
		# 检测是否为多帧 strip（宽�?> 高度 �?�?hframes�?
		if sprite.texture != null:
			var tw: int = sprite.texture.get_width()
			var th: int = sprite.texture.get_height()
			if tw > th and th > 0:
				_hframes = max(1, tw / th)
				sprite.hframes = _hframes
				sprite.vframes = 1
				sprite.frame = 0

	## NPC 头顶名字标签
	if npc_name != "":
		_create_name_label()

	## 设置 Area2D 的碰撞形状大小（交互检测区域，稍大�?
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(160, 160)
	var collider: CollisionShape2D = interact_area.get_node("CollisionShape2D")
	if collider != null:
		collider.shape = shape

	## 添加 StaticBody2D 做物理阻挡（玩家不能穿过 NPC�?
	_create_body_collision()

	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	prompt.visible = false


func _process(delta: float) -> void:
	if _hframes <= 1:
		return
	_frame_timer += delta
	while _frame_timer >= IDLE_FRAME_SECONDS:
		_frame_timer -= IDLE_FRAME_SECONDS
		sprite.frame = (sprite.frame + 1) % _hframes

func _apply_sprite_scale() -> void:
	if sprite == null:
		return
	if sprite_scale > 0.0:
		sprite.scale = Vector2.ONE * sprite_scale
		return
	if sprite.texture != null:
		var origin_size: float = max(sprite.texture.get_width(), sprite.texture.get_height())
		sprite.scale = Vector2.ONE * (128.0 / origin_size)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		prompt.visible = false  # 不显示提示文字，仅标记可交互状�?
		_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		prompt.visible = false
		_in_range = false

func try_interact() -> bool:
	## 外部调用：如果玩家在当前交互范围内，触发对话
	if not _in_range:
		return false
	if dialog_id != "":
		emit_signal("npc_interacted", npc_id, dialog_id)
		return true
	return false

func _create_name_label() -> void:
	_name_label = Label.new()
	_name_label.text = npc_name
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 14)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_name_label.add_theme_constant_override("shadow_offset_x", 1)
	_name_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_name_label)
	# 等一帧让 sprite 尺寸确定后再定位
	await get_tree().process_frame
	_position_name_label()

func _position_name_label() -> void:
	if _name_label == null or sprite == null:
		return
	# 计算 sprite 头顶位置
	var sprite_h: float = 0.0
	if sprite.texture != null:
		var th: int = sprite.texture.get_height()
		sprite_h = th * sprite.scale.y
	# 名字放在 sprite 头顶上方
	_name_label.position = Vector2(-_name_label.size.x * 0.5, -sprite_h * 0.5 - 20)


func _create_body_collision() -> void:
	## �?NPC 脚底创建 StaticBody2D 阻挡玩家穿过
	_body_collider = StaticBody2D.new()
	_body_collider.collision_layer = 1  # 与玩家同�?
	_body_collider.collision_mask = 0   # 不检测其他物�?
	var col_shape: CollisionShape2D = CollisionShape2D.new()
	var body_rect: RectangleShape2D = RectangleShape2D.new()
	# NPC 阻挡体大小：窄宽度避免阻挡过大，高高度覆盖身体防止穿过
	var block_w: float = 18.0
	var block_h: float = 36.0
	var offset_y: float = 0.0
	if sprite != null and sprite.texture != null:
		var tw: float = sprite.texture.get_width() / float(max(1, _hframes))
		var th: float = sprite.texture.get_height()
		block_w = tw * sprite.scale.x * 0.14
		block_h = th * sprite.scale.y * 0.18
		offset_y = th * sprite.scale.y * 0.12
	body_rect.size = Vector2(block_w, block_h)
	col_shape.shape = body_rect
	col_shape.position = Vector2(0, offset_y)
	_body_collider.add_child(col_shape)
	add_child(_body_collider)
