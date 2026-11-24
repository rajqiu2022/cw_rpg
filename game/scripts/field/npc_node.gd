class_name NPCNode
extends Node2D

## 场景中的 NPC 节点�?
## 玩家走进 interact_area 时显示提示图标，按交互键触发对话�?
## 支持单帧�?4 �?idle 动画（宽�?> 高度时自动按 hframes 切帧）�?

signal npc_interacted(npc_id: String, dialog_id: String)
signal npc_action_requested(npc_id: String, action: String)

const IDLE_FRAME_SECONDS := 0.28
const CALIBRATED_ADULT_HEIGHT := 140.0
const SMALL_ADULT_FAMILIES := ["npc_zhuwei_gate_guard_", "npc_zhuwei_inn_waiter_", "npc_escort_guard_", "npc_linxi_martial_hall_master_"]
static var _visible_bounds_cache: Dictionary = {}
const INTERACTION_OUTLINE_SHADER := preload("res://shaders/interaction_outline.gdshader")

@export var npc_id: String = ""
@export var npc_name: String = ""
@export var dialog_id: String = ""
## 无对白的功能型 NPC 可直接发起切磋等场景动作。
@export var interaction_action: String = ""
## Optional state-aware replacements. The first matching entry wins:
## {"dialog_id": "...", "require_flags": ["a", "b"], "hide_flags": ["c"],
##  "require_quest_active": "q_side_id", "require_quest_completed": "q_side_id"}
## This keeps one visible NPC in place while its conversation advances.
@export var dialog_variants: Array[Dictionary] = []
@export var portrait_path: String = ""
@export var sprite_path: String = ""
@export var walk_sprite_path: String = ""
## Optional explicit direction map for conversation-only one-frame or strip assets.
## Keys: down/up/left/right. This is the authoritative fallback for NPCs whose
## normal idle asset only has a front-facing strip.
@export var conversation_sprite_paths: Dictionary = {}
## Baseline horizontal facing of the authored idle sprite. Most generated NPC
## strips face screen-right, but a few legacy/coach assets face screen-left.
## Declaring it prevents the generic mirror fallback from making an NPC turn
## away from the player when no four-direction conversation strip exists.
@export_enum("right", "left", "front") var conversation_base_facing: String = "right"
@export var sprite_scale: float = 0.08
@export_enum("idle", "patrol", "seated") var movement_mode: String = "idle"
@export var patrol_axis: Vector2 = Vector2.RIGHT
@export var patrol_distance: float = 70.0
@export var patrol_speed: float = 22.0
@export var invert_patrol_facing: bool = false
@export_range(0.08, 2.0, 0.01) var idle_frame_seconds: float = IDLE_FRAME_SECONDS
@export_range(0.06, 0.5, 0.01) var walk_frame_seconds: float = 0.12

@onready var sprite: Sprite2D = $Sprite2D
@onready var interact_area: Area2D = $InteractArea
@onready var prompt: Label = $Prompt

var _frame_timer: float = 0.0
var _hframes: int = 1
var _name_label: Label = null
var _in_range: bool = false
var _body_collider: StaticBody2D = null
var _patrol_origin: Vector2
var _patrol_phase: float = 0.0
var _idle_texture: Texture2D = null
var _walk_texture: Texture2D = null
var _interaction_outline_material: ShaderMaterial = null
var _conversation_active: bool = false
var _flip_before_conversation: bool = false
var _conversation_freeze_frame: bool = false
var _warned_missing_conversation_facings: Dictionary = {}
var _ground_anchored := false
var _unanchored_prompt_position := Vector2.ZERO
var _calibrate_adult_body := false

func _ready() -> void:
	add_to_group("npc")
	_patrol_origin = position
	_unanchored_prompt_position = prompt.position
	for family: String in SMALL_ADULT_FAMILIES:
		if sprite_path.get_file().begins_with(family) and movement_mode != "seated":
			_calibrate_adult_body = true
			break

	## 加载 sprite 纹理
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
		_idle_texture = sprite.texture
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
	if walk_sprite_path != "" and ResourceLoader.exists(walk_sprite_path):
		_walk_texture = load(walk_sprite_path) as Texture2D

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
	interact_area.collision_layer = 4
	interact_area.input_pickable = true
	interact_area.input_event.connect(_on_interact_area_input)
	prompt.visible = false
	_make_interaction_highlight()
	_sync_ground_anchor()


func _process(delta: float) -> void:
	if movement_mode == "patrol" and not _conversation_active:
		_patrol_phase = fmod(_patrol_phase + delta * patrol_speed / maxf(1.0, patrol_distance), TAU)
		var offset := patrol_axis.normalized() * sin(_patrol_phase) * patrol_distance
		position = _patrol_origin + offset
		_apply_patrol_walk_visual()
		_update_depth()
		if absf(patrol_axis.x) > absf(patrol_axis.y):
			sprite.flip_h = (cos(_patrol_phase) < 0.0) != invert_patrol_facing
	if _conversation_freeze_frame or _hframes <= 1:
		return
	var frame_seconds := walk_frame_seconds if movement_mode == "patrol" and _walk_texture != null and sprite.texture == _walk_texture else idle_frame_seconds
	_frame_timer += delta
	while _frame_timer >= frame_seconds:
		_frame_timer -= frame_seconds
		sprite.frame = (sprite.frame + 1) % _hframes


func _apply_patrol_walk_visual() -> void:
	if _walk_texture == null or sprite.texture == _walk_texture:
		return
	sprite.texture = _walk_texture
	var width: int = _walk_texture.get_width()
	var height: int = _walk_texture.get_height()
	_hframes = maxi(1, width / height) if height > 0 else 1
	sprite.hframes = _hframes
	sprite.vframes = 1
	sprite.frame = 0
	_apply_sprite_scale()
	_sync_ground_anchor()


func _apply_idle_visual() -> void:
	if _idle_texture == null or sprite == null:
		return
	if sprite.texture != _idle_texture:
		sprite.texture = _idle_texture
	var texture_height: int = _idle_texture.get_height()
	_hframes = maxi(1, _idle_texture.get_width() / texture_height) if texture_height > 0 and _idle_texture.get_width() > texture_height else 1
	sprite.hframes = _hframes
	sprite.vframes = 1
	sprite.frame = 0
	_frame_timer = 0.0
	_apply_sprite_scale()
	_sync_ground_anchor()


func begin_conversation(player_global_position: Vector2) -> void:
	## Stop patrol and use the authored directional strip nearest to the player.
	## Walk strips are frozen on a complete neutral frame when a directional
	## idle strip is unavailable; this avoids the cropped legacy idle artwork.
	if sprite == null:
		return
	_flip_before_conversation = sprite.flip_h
	_conversation_active = true
	var to_player: Vector2 = player_global_position - global_position
	var facing: String = _facing_from_vector(to_player)
	var facing_texture: Texture2D = _load_directional_texture(facing)
	if facing_texture != null:
		_apply_conversation_texture(facing_texture)
		sprite.flip_h = false
	else:
		if not _warned_missing_conversation_facings.has(facing):
			_warned_missing_conversation_facings[facing] = true
			push_warning("[NPCNode] %s has no authored '%s' conversation facing; using mirror fallback" % [npc_id, facing])
		_apply_idle_visual()
		if absf(to_player.x) > 1.0:
			if conversation_base_facing == "left":
				sprite.flip_h = to_player.x > 0.0
			elif conversation_base_facing == "right":
				sprite.flip_h = to_player.x < 0.0
			else:
				sprite.flip_h = false
	_conversation_freeze_frame = true
	_update_depth()


func end_conversation() -> void:
	if not _conversation_active:
		return
	_conversation_active = false
	_conversation_freeze_frame = false
	if sprite != null:
		sprite.flip_h = _flip_before_conversation
	_apply_idle_visual()


func _facing_from_vector(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x >= 0.0 else "left"
	return "down" if direction.y >= 0.0 else "up"


func _load_directional_texture(facing: String) -> Texture2D:
	var explicit_path: String = String(conversation_sprite_paths.get(facing, ""))
	if explicit_path != "" and ResourceLoader.exists(explicit_path):
		var explicit_resource: Resource = load(explicit_path)
		if explicit_resource is Texture2D:
			return explicit_resource as Texture2D
	var candidates: Array[String] = []
	# The generated horizontal NPC sheets use camera-facing labels: their
	# `left` sheet visually faces screen-right and vice versa. Normalize that
	# convention here so every NPC still turns toward the player in world space.
	var authored_facing: String = _authored_facing_for(facing)
	_append_directional_candidates(candidates, sprite_path, authored_facing)
	_append_directional_candidates(candidates, walk_sprite_path, authored_facing)
	for candidate: String in candidates:
		if candidate == "" or not ResourceLoader.exists(candidate):
			continue
		var loaded: Resource = load(candidate)
		if loaded is Texture2D:
			return loaded as Texture2D
	return null


func has_conversation_facing(facing: String) -> bool:
	return _load_directional_texture(facing) != null


func _authored_facing_for(world_facing: String) -> String:
	if world_facing == "left":
		return "right"
	if world_facing == "right":
		return "left"
	return world_facing


func _append_directional_candidates(candidates: Array[String], source_path: String, facing: String) -> void:
	if source_path == "":
		return
	var direction_tokens: Array[String] = ["down", "up", "left", "right"]
	var authored_direction: String = ""
	for token: String in direction_tokens:
		if source_path.contains("_%s_" % token):
			authored_direction = token
			break
	if authored_direction == "":
		return
	var directional_path: String = source_path.replace(
		"_%s_" % authored_direction,
		"_%s_" % facing
	)
	_append_idle_walk_pair(candidates, directional_path)
	# Major NPC runtime paths may carry an identity-version token while their
	# approved four-direction family predates that token. Resolve that sibling
	# family explicitly instead of silently falling back to a front-facing strip.
	for version: int in range(2, 10):
		var token := "_v%d_" % version
		if directional_path.contains(token):
			_append_idle_walk_pair(candidates, directional_path.replace(token, "_"))


func _append_idle_walk_pair(candidates: Array[String], directional_path: String) -> void:
	if directional_path.contains("_idle_"):
		candidates.append(directional_path)
		candidates.append(directional_path.replace("_idle_", "_walk_"))
	else:
		candidates.append(directional_path.replace("_walk_", "_idle_"))
		candidates.append(directional_path)


func _apply_conversation_texture(texture: Texture2D) -> void:
	sprite.texture = texture
	var texture_height: int = texture.get_height()
	_hframes = maxi(1, texture.get_width() / texture_height) if texture_height > 0 else 1
	sprite.hframes = _hframes
	sprite.vframes = 1
	sprite.frame = 0
	_frame_timer = 0.0
	_apply_sprite_scale()
	_sync_ground_anchor()


func _update_depth() -> void:
	# Match the field's fine-grained depth bands so close NPCs do not fall into
	# one coarse bucket and render in scene insertion order.
	var depth_band := clampi(int(floor(get_depth_sort_y() / 8.0)), 0, int(get_meta("depth_band_max", 255)))
	if z_index != depth_band:
		z_index = depth_band


func get_depth_sort_y() -> float:
	if sprite == null or sprite.texture == null:
		return global_position.y
	return global_position.y + sprite.position.y + _visual_foot_offset()


func refresh_depth_sort() -> void:
	_update_depth()


func set_ground_anchored(enabled: bool) -> void:
	# New map coordinates represent feet; legacy scenes continue using centres.
	_ground_anchored = enabled
	_sync_ground_anchor()


func _sync_ground_anchor() -> void:
	if sprite == null or sprite.texture == null:
		return
	var visual_height := float(sprite.texture.get_height()) * sprite.scale.y
	var foot_offset := _visual_foot_offset()
	if _calibrate_adult_body:
		# Keep the authored legacy ground plane fixed while enlarging only art.
		var authored_foot := float(_idle_texture.get_height()) * sprite_scale * 0.45
		sprite.position.y = (0.0 if _ground_anchored else authored_foot) - foot_offset
	else:
		sprite.position.y = -foot_offset if _ground_anchored else 0.0
	if _body_collider != null and _body_collider.get_child_count() > 0:
		var shape := _body_collider.get_child(0) as CollisionShape2D
		_body_collider.position.y = -shape.position.y if _ground_anchored and shape != null else 0.0
	if prompt != null:
		prompt.position = _unanchored_prompt_position
		if _ground_anchored:
			prompt.position.y = sprite.position.y - visual_height * 0.5 - 30.0
	_position_name_label()
	_update_depth()

func _apply_sprite_scale() -> void:
	if sprite == null:
		return
	if sprite_scale > 0.0:
		sprite.scale = Vector2.ONE * sprite_scale
		if _calibrate_adult_body and sprite.texture != null:
			var visible := _visible_bounds(sprite.texture)
			if visible.size.y > 0:
				sprite.scale *= CALIBRATED_ADULT_HEIGHT / float(visible.size.y)
		return
	if sprite.texture != null:
		var origin_size: float = max(sprite.texture.get_width(), sprite.texture.get_height())
		sprite.scale = Vector2.ONE * (128.0 / origin_size)


func _visible_bounds(texture: Texture2D) -> Rect2i:
	var key := texture.get_instance_id()
	if not _visible_bounds_cache.has(key):
		var image := texture.get_image()
		var cell_width := mini(texture.get_width(), texture.get_height())
		_visible_bounds_cache[key] = image.get_region(Rect2i(0, 0, cell_width, image.get_height())).get_used_rect()
	return _visible_bounds_cache[key]


func _visual_foot_offset() -> float:
	if _calibrate_adult_body:
		var bounds := _visible_bounds(sprite.texture)
		return (float(bounds.end.y) - float(sprite.texture.get_height()) * 0.5) * sprite.scale.y
	return float(sprite.texture.get_height()) * sprite.scale.y * 0.45


func apply_runtime_idle_texture(texture: Texture2D) -> void:
	# FieldWalkableController can replace an NPC texture after this node has
	# entered the tree. Keep the runtime frame counter in sync so a 4-frame
	# strip visibly idles instead of staying frozen on its first frame.
	if texture == null or sprite == null:
		return
	sprite.texture = texture
	_idle_texture = texture
	var texture_height: int = texture.get_height()
	_hframes = maxi(1, texture.get_width() / texture_height) if texture_height > 0 and texture.get_width() > texture_height else 1
	sprite.hframes = _hframes
	sprite.vframes = 1
	sprite.frame = 0
	_frame_timer = 0.0
	_apply_sprite_scale()
	_sync_ground_anchor()

func _make_interaction_highlight() -> void:
	if sprite == null:
		return
	# Keep idle NPCs on the cheap default canvas path. South District has many
	# actors; leaving the five-sample outline shader attached to every sprite,
	# even with zero strength, made camera movement visibly hitch.
	_interaction_outline_material = ShaderMaterial.new()
	_interaction_outline_material.shader = INTERACTION_OUTLINE_SHADER
	_interaction_outline_material.set_shader_parameter("pulse", 1.0)
	_interaction_outline_material.set_shader_parameter("base_strength", 0.0)
	sprite.material = null


func _set_interaction_highlight(active: bool) -> void:
	if sprite == null:
		return
	if active:
		sprite.material = _interaction_outline_material
	elif sprite.material == _interaction_outline_material:
		sprite.material = null


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		prompt.visible = false  # 不显示提示文字，仅标记可交互状�?
		if _is_story_confrontation():
			return
		_in_range = true
		_set_interaction_highlight(true)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		prompt.visible = false
		_in_range = false
		_set_interaction_highlight(false)


func _on_interact_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var tapped: bool = event is InputEventScreenTouch and event.pressed
	if clicked or tapped:
		try_interact()

func try_interact() -> bool:
	if _is_story_confrontation():
		return false
	## Area2D signals remain the fast path, but a distance fallback makes NPC
	## interaction resilient after camera/scene rebuilds where an overlap event
	## can be missed for one frame.
	if not _in_range and not _is_player_within_interaction_distance():
		return false
	if not interaction_action.is_empty():
		npc_action_requested.emit(npc_id, interaction_action)
		return true
	var resolved_dialog_id := _resolve_dialog_id()
	if resolved_dialog_id != "":
		emit_signal("npc_interacted", npc_id, resolved_dialog_id)
		return true
	return false


func _is_story_confrontation() -> bool:
	return npc_id in ["ruin_outer_guard", "zhao_wuji_unprepared", "zhao_wuji"]


func _is_player_within_interaction_distance(max_distance: float = 118.0) -> bool:
	var player_node: Node = get_tree().get_first_node_in_group("player")
	if not player_node is Node2D:
		return false
	return global_position.distance_to((player_node as Node2D).global_position) <= max_distance


func _resolve_dialog_id() -> String:
	for variant: Dictionary in dialog_variants:
		if not _variant_flags_match(variant.get("require_flags", []), true):
			continue
		if not _variant_flags_match(variant.get("hide_flags", []), false):
			continue
		if not _variant_quest_state_matches(variant):
			continue
		var candidate: String = String(variant.get("dialog_id", ""))
		if candidate != "":
			return candidate
	return dialog_id


func _variant_flags_match(raw_flags: Variant, required_value: bool) -> bool:
	if not raw_flags is Array:
		return true
	for raw_flag: Variant in raw_flags:
		var key: String = String(raw_flag)
		if key == "":
			continue
		var actual := _flag_truthy(key)
		if actual != required_value:
			return false
	return true


func _variant_quest_state_matches(variant: Dictionary) -> bool:
	var quest_manager := get_tree().root.get_node_or_null("QuestManager")
	if quest_manager == null:
		return not variant.has("require_quest_active") and not variant.has("require_quest_completed")
	var active_qid := StringName(String(variant.get("require_quest_active", "")))
	if active_qid != &"" and not bool(quest_manager.call("is_active", active_qid)):
		return false
	var completed_qid := StringName(String(variant.get("require_quest_completed", "")))
	if completed_qid != &"" and not bool(quest_manager.call("is_completed", completed_qid)):
		return false
	var hidden_active_qid := StringName(String(variant.get("hide_quest_active", "")))
	if hidden_active_qid != &"" and bool(quest_manager.call("is_active", hidden_active_qid)):
		return false
	return true


func _flag_truthy(key: String) -> bool:
	var game_state := get_tree().root.get_node_or_null("GameState")
	if game_state == null:
		return false
	var flags: Dictionary = game_state.get("flags")
	var value: Variant = flags.get(key, null)
	if value == null:
		return false
	if typeof(value) == TYPE_BOOL:
		return value
	if typeof(value) == TYPE_INT:
		return value != 0
	if typeof(value) == TYPE_STRING:
		return value != ""
	return true

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
	_name_label.position = Vector2(-_name_label.size.x * 0.5, sprite.position.y - sprite_h * 0.5 - 20)
	if _calibrate_adult_body and sprite.texture != null:
		var bounds := _visible_bounds(sprite.texture)
		_name_label.position.y = sprite.position.y + (float(bounds.position.y) - float(sprite.texture.get_height()) * 0.5) * sprite.scale.y - 20.0


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
		# Visual normalization must not enlarge or move physical NPC footprints.
		var body_scale := sprite_scale if _calibrate_adult_body else sprite.scale.y
		block_w = tw * body_scale * 0.14
		block_h = th * body_scale * 0.18
		offset_y = th * body_scale * 0.12
	body_rect.size = Vector2(block_w, block_h)
	col_shape.shape = body_rect
	col_shape.position = Vector2(0, offset_y)
	_body_collider.add_child(col_shape)
	add_child(_body_collider)
