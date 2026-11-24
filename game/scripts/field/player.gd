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
const HORIZONTAL_FRAME_SECONDS := 0.08
const VERTICAL_FRAME_SECONDS := 0.10
const IDLE_FRAME_SECONDS := 0.28
const VISUAL_SCALE := 0.945
const FIELD_VARIANT_ROOT := "res://art/characters/weapon_variants/lengguyun/v7_idle_stable"
const FIELD_VARIANT_PREFIXES := {
	&"sword": "lengguyun_sword",
	&"dao": "lengguyun_dao",
	&"staff": "lengguyun_staff",
	&"palm": "lengguyun_palm",
	&"hidden": "lengguyun_hidden",
}

@onready var sprite: Sprite2D = $Sprite2D
@onready var interact_area: Area2D = $InteractArea

var can_move: bool = true
## Optional positive walkable-area contract supplied by FieldWalkableController.
## Static collision remains responsible for physical props; this prevents a player
## from ever crossing the outer road boundary between physics frames.
var movement_constraint: Callable = Callable()
var _direction := "down"
var _frame_timer := 0.0
var _is_moving := false
var _visual_scale_multiplier: float = 1.0
var _overlap_ghost: Sprite2D = null
var _overlap_mask_material: ShaderMaterial = null
var _frame_overlap_material: ShaderMaterial = null
var _weapon_style: StringName = &"sword"
var _variant_texture_cache: Dictionary = {}
var _applied_visual_key := ""
var _baked_map_overlap_active: bool = false
var _baked_map_fade_tween: Tween = null
var _ground_anchored: bool = false

func _ready() -> void:
	add_to_group("player")
	sprite.centered = true
	sprite.scale = Vector2.ONE * VISUAL_SCALE * _visual_scale_multiplier
	set_walk_direction(Vector2.DOWN, false)
	_create_overlap_ghost()


func _process(_delta: float) -> void:
	if _overlap_ghost != null and _overlap_ghost.visible:
		_sync_overlap_ghost()

func _physics_process(delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		set_walk_direction(Vector2.ZERO, false)
		_advance_idle_frame(delta)
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = _constrain_velocity(input_dir * SPEED, delta)
	var before_move := global_position
	move_and_slide()
	var moved_this_tick := global_position.distance_squared_to(before_move) > 0.0001
	set_walk_direction(input_dir, moved_this_tick)
	if moved_this_tick:
		_advance_walk_frame(delta)
		emit_signal("moved", global_position)
	else:
		_advance_idle_frame(delta)


func set_movement_constraint(constraint: Callable) -> void:
	movement_constraint = constraint


func set_visual_scale_multiplier(multiplier: float) -> void:
	_visual_scale_multiplier = maxf(0.5, multiplier)
	_apply_visual_scale()


func set_weapon_style(style: StringName) -> void:
	_weapon_style = _normalized_weapon_style(style)
	_applied_visual_key = ""
	if sprite == null:
		return
	set_walk_direction(Vector2.ZERO, false)


func _normalized_weapon_style(style: StringName) -> StringName:
	match style:
		&"blade", &"dao", &"axe":
			return &"dao"
		&"staff":
			return &"staff"
		&"palm":
			return &"palm"
		&"hidden", &"throwing", &"ring", &"dagger":
			return &"hidden"
		_:
			return &"sword"


func _variant_texture(direction: String, moving: bool) -> Texture2D:
	var cache_key := "%s:%s:%s" % [String(_weapon_style), direction, "walk" if moving else "idle"]
	if _variant_texture_cache.has(cache_key):
		return _variant_texture_cache[cache_key] as Texture2D
	var prefix := String(FIELD_VARIANT_PREFIXES.get(_weapon_style, "lengguyun_sword"))
	var state := "walk" if moving else "idle"
	var frame_count := 8 if moving else 4
	var path := "%s/%s/%s_%s_%s_25d_%df.png" % [
		FIELD_VARIANT_ROOT,
		String(_weapon_style),
		prefix,
		state,
		direction,
		frame_count,
	]
	if not ResourceLoader.exists(path):
		return null
	var texture := load(path) as Texture2D
	_variant_texture_cache[cache_key] = texture
	return texture


func _apply_visual_scale() -> void:
	if sprite != null:
		# Every current field strip uses the same 160x160 cell contract and scale.
		# Reassign from the canonical value instead of multiplying the current
		# scale, so repeated weapon swaps can never progressively shrink it.
		sprite.scale = Vector2.ONE * VISUAL_SCALE * _visual_scale_multiplier
		# World-map navigation, portals and saved positions all represent feet.
		# 160px adopted cells have an 8px transparent bottom margin. This uses
		# texture dimensions only; never read image pixels in the movement loop.
		sprite.position.y = -sprite.texture.get_height() * sprite.scale.y * 0.45 if _ground_anchored and sprite.texture != null else 0.0


func set_ground_anchored(enabled: bool) -> void:
	_ground_anchored = enabled
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		collision.position.y = 0.0 if enabled else 42.0
	_apply_visual_scale()


func set_world_travel_foot_anchor(enabled: bool) -> void:
	set_ground_anchored(enabled)
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null:
		collision.position.y = 0.0 if enabled else 42.0
		if enabled:
			# The small-scale travel actor uses a 5px foot contact circle, matching
			# the surveyed narrow bridge clearance rather than the local-map body.
			var foot := CircleShape2D.new()
			foot.radius = 5.0
			collision.shape = foot
		else:
			var body := RectangleShape2D.new()
			body.size = Vector2(34, 24)
			collision.shape = body
	_apply_visual_scale()


func get_depth_sort_y() -> float:
	return global_position.y + _visual_foot_offset()


func refresh_depth_sort() -> void:
	var depth_band := clampi(int(floor(get_depth_sort_y() / 8.0)), 0, int(get_meta("depth_band_max", 255)))
	if z_index != depth_band:
		z_index = depth_band


func _visual_foot_offset() -> float:
	if sprite == null or sprite.texture == null:
		return 42.0
	return sprite.position.y + sprite.texture.get_height() * sprite.scale.y * 0.45


func set_building_overlap(active: bool, faded_alpha: float = 0.46, immediate: bool = false, mask_payload: Dictionary = {}) -> void:
	if sprite == null or _overlap_ghost == null:
		return
	# Base sprite stays below the opaque building. When it overlaps a roof, a
	# separate translucent ghost is drawn above the foreground so only the
	# character reads as semi-transparent; the building pixels never fade.
	_overlap_ghost.visible = active
	_overlap_ghost.z_index = int(mask_payload.get("ghost_z", 450)) if active else 450
	_overlap_ghost.modulate = Color(1.0, 1.0, 1.0, clampf(faded_alpha, 0.15, 0.90))
	_configure_overlap_mask(mask_payload if active else {}, faded_alpha)
	_sync_overlap_ghost()


func set_baked_map_overlap(active: bool, faded_alpha: float = 0.46, immediate: bool = false) -> void:
	if sprite == null:
		return
	var target_alpha := clampf(faded_alpha, 0.15, 0.90) if active else 1.0
	if _baked_map_overlap_active == active and is_equal_approx(sprite.modulate.a, target_alpha):
		return
	_baked_map_overlap_active = active
	if _baked_map_fade_tween != null and _baked_map_fade_tween.is_valid():
		_baked_map_fade_tween.kill()
	if immediate:
		sprite.modulate.a = target_alpha
		return
	_baked_map_fade_tween = create_tween()
	_baked_map_fade_tween.tween_property(sprite, "modulate:a", target_alpha, 0.12)


func _create_overlap_ghost() -> void:
	_overlap_ghost = Sprite2D.new()
	_overlap_ghost.name = "BuildingOverlapGhost"
	_overlap_ghost.z_as_relative = false
	_overlap_ghost.z_index = 450
	_overlap_ghost.visible = false
	add_child(_overlap_ghost)
	_sync_overlap_ghost()


func _configure_overlap_mask(mask_payload: Dictionary, faded_alpha: float) -> void:
	if _overlap_ghost == null:
		return
	if mask_payload.get("space", "") == "actor_frame":
		_configure_frame_overlap_mask(mask_payload, faded_alpha)
		return
	var mask_texture := mask_payload.get("texture") as Texture2D
	var mask_world_size := mask_payload.get("world_size", Vector2.ZERO) as Vector2
	if mask_texture == null or mask_world_size.x <= 0.0 or mask_world_size.y <= 0.0:
		# Legacy authored zones keep their previous full-silhouette fallback. New
		# traversable gates are required to provide an explicit alpha mask.
		_overlap_ghost.material = null
		return
	if _overlap_mask_material == null:
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;
uniform sampler2D overlap_mask : filter_linear;
uniform vec2 mask_world_size = vec2(1.0);
uniform float ghost_alpha = 0.46;
varying vec2 world_position;
void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment() {
	vec4 actor = texture(TEXTURE, UV);
	vec2 mask_uv = world_position / mask_world_size;
	float inside = step(0.0, mask_uv.x) * step(mask_uv.x, 1.0) * step(0.0, mask_uv.y) * step(mask_uv.y, 1.0);
	float overlap = texture(overlap_mask, clamp(mask_uv, vec2(0.0), vec2(1.0))).a * inside;
	COLOR = vec4(actor.rgb, actor.a * overlap * ghost_alpha);
}
"""
		_overlap_mask_material = ShaderMaterial.new()
		_overlap_mask_material.shader = shader
	_overlap_mask_material.set_shader_parameter("overlap_mask", mask_texture)
	_overlap_mask_material.set_shader_parameter("mask_world_size", mask_world_size)
	_overlap_mask_material.set_shader_parameter("ghost_alpha", clampf(faded_alpha, 0.15, 0.90))
	_overlap_ghost.material = _overlap_mask_material


func _configure_frame_overlap_mask(payload: Dictionary, faded_alpha: float) -> void:
	var texture := payload.get("texture") as Texture2D
	var rect: Rect2 = payload.get("actor_rect", Rect2())
	if texture == null or rect.size.x <= 0 or rect.size.y <= 0:
		_overlap_ghost.visible = false
		return
	if _frame_overlap_material == null:
		var shader := Shader.new()
		shader.code = """
shader_type canvas_item;
uniform sampler2D frame_mask : filter_nearest;
uniform vec4 actor_local_rect;
uniform vec2 mask_flip = vec2(0.0);
uniform float ghost_alpha = 0.46;
varying vec2 frame_uv;
void vertex() {
	frame_uv = (VERTEX - actor_local_rect.xy) / actor_local_rect.zw;
	frame_uv = mix(frame_uv, vec2(1.0) - frame_uv, mask_flip);
}
void fragment() {
	vec4 actor = texture(TEXTURE, UV);
	float overlap = texture(frame_mask, clamp(frame_uv, vec2(0.0), vec2(1.0))).a;
	COLOR = vec4(actor.rgb, actor.a * overlap * ghost_alpha);
}
"""
		_frame_overlap_material = ShaderMaterial.new()
		_frame_overlap_material.shader = shader
	_frame_overlap_material.set_shader_parameter("frame_mask", texture)
	_frame_overlap_material.set_shader_parameter("actor_local_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	_frame_overlap_material.set_shader_parameter("mask_flip", payload.get("flip", Vector2.ZERO))
	_frame_overlap_material.set_shader_parameter("ghost_alpha", clampf(faded_alpha, .15, .90))
	_overlap_ghost.material = _frame_overlap_material


func _sync_overlap_ghost() -> void:
	if _overlap_ghost == null or sprite == null:
		return
	_overlap_ghost.texture = sprite.texture
	_overlap_ghost.texture_filter = sprite.texture_filter
	_overlap_ghost.hframes = sprite.hframes
	_overlap_ghost.vframes = sprite.vframes
	_overlap_ghost.frame = sprite.frame
	_overlap_ghost.centered = sprite.centered
	_overlap_ghost.position = sprite.position
	_overlap_ghost.scale = sprite.scale
	_overlap_ghost.flip_h = sprite.flip_h
	_overlap_ghost.flip_v = sprite.flip_v
	_overlap_ghost.offset = sprite.offset
	_overlap_ghost.rotation = sprite.rotation
	_overlap_ghost.region_enabled = sprite.region_enabled
	_overlap_ghost.region_rect = sprite.region_rect


func _constrain_velocity(requested_velocity: Vector2, delta: float) -> Vector2:
	if movement_constraint.is_null() or requested_velocity == Vector2.ZERO:
		return requested_velocity
	var full_target := global_position + requested_velocity * delta
	if bool(movement_constraint.call(full_target)):
		return requested_velocity

	# Let the player slide along a hand-authored road outline instead of stopping
	# completely whenever a diagonal input reaches its boundary.
	var horizontal := Vector2(requested_velocity.x, 0.0)
	if horizontal != Vector2.ZERO and bool(movement_constraint.call(global_position + horizontal * delta)):
		return horizontal
	var vertical := Vector2(0.0, requested_velocity.y)
	if vertical != Vector2.ZERO and bool(movement_constraint.call(global_position + vertical * delta)):
		return vertical
	return Vector2.ZERO

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

	var prev_moving := _is_moving
	_is_moving = moving
	var visual_key := "%s:%s:%s" % [String(_weapon_style), _direction, "walk" if moving else "idle"]
	if visual_key != _applied_visual_key:
		if moving:
			_apply_walk_direction(_direction)
		else:
			_apply_idle_direction(_direction)
		if prev_moving:  # just transitioned from walk to idle
			_frame_timer = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not can_move:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		emit_signal("interacted")

func _apply_walk_direction(direction: String) -> void:
	if sprite == null:
		return
	var texture := _variant_texture(direction, true)
	if texture == null:
		return
	var frame_count := 8
	if sprite.texture == texture and sprite.hframes == frame_count:
		_applied_visual_key = "%s:%s:walk" % [String(_weapon_style), direction]
		return
	sprite.texture = texture
	sprite.material = null
	sprite.hframes = frame_count
	sprite.vframes = 1
	sprite.flip_h = false
	sprite.frame = 0
	_apply_visual_scale()
	_applied_visual_key = "%s:%s:walk" % [String(_weapon_style), direction]
	_frame_timer = 0.0

func _apply_idle_direction(direction: String) -> void:
	if sprite == null:
		return
	var texture := _variant_texture(direction, false)
	if texture == null:
		return
	var frame_count := 4
	if sprite.texture == texture and sprite.hframes == frame_count:
		_applied_visual_key = "%s:%s:idle" % [String(_weapon_style), direction]
		return
	sprite.texture = texture
	sprite.material = null
	sprite.hframes = frame_count
	sprite.vframes = 1
	sprite.flip_h = false
	sprite.frame = 0
	_apply_visual_scale()
	_applied_visual_key = "%s:%s:idle" % [String(_weapon_style), direction]

func _advance_walk_frame(delta: float) -> void:
	var frame_count := 8
	var frame_seconds := HORIZONTAL_FRAME_SECONDS
	if _direction == "up" or _direction == "down":
		frame_seconds = VERTICAL_FRAME_SECONDS

	_frame_timer += delta
	while _frame_timer >= frame_seconds:
		_frame_timer -= frame_seconds
		sprite.frame = (sprite.frame + 1) % frame_count

func _advance_idle_frame(delta: float) -> void:
	var frame_count := 4
	_frame_timer += delta
	while _frame_timer >= IDLE_FRAME_SECONDS:
		_frame_timer -= IDLE_FRAME_SECONDS
		sprite.frame = (sprite.frame + 1) % frame_count
