class_name DynamicOccluder2D
extends Polygon2D

## Samples a reviewed baked background into a foreground polygon.
##
## `overlap` is used for traversable gates/roofs: the sampled architecture is
## always above the base actor and the actor gets one uniformly translucent
## ghost while its feet are in fade_region.
## `y_sort` is used for free-standing lanterns, steles and braziers baked into
## the painting: the sample is only visible while the actor's feet are behind
## the object's authored depth line. This reproduces foot-Y sorting without
## requiring a second hand-cut texture for every prop.

var occluder_id: String = ""
var blocker_id: String = ""
var fade_region: PackedVector2Array = PackedVector2Array()
var player_faded_alpha: float = 0.46
var is_faded: bool = false
var depth_mode: StringName = &"overlap"
var depth_y: float = 0.0
var _world_size := Vector2.ONE
var _actor_overlap_mask: Texture2D = null

const ALPHA_MASK_SHADER := """
shader_type canvas_item;
uniform sampler2D alpha_mask : filter_linear;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float mask_alpha = texture(alpha_mask, UV).a;
	COLOR = vec4(source.rgb, source.a * mask_alpha);
}
"""

const DIFFERENCE_MASK_SHADER := """
shader_type canvas_item;
uniform sampler2D clean_texture : filter_linear;
uniform float difference_threshold = 0.08;
uniform float edge_softness = 0.06;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec4 clean = texture(clean_texture, UV);
	float difference = distance(source.rgb, clean.rgb);
	float building_mask = smoothstep(difference_threshold, difference_threshold + edge_softness, difference);
	COLOR = vec4(source.rgb, source.a * building_mask);
}
"""


func configure(data: Dictionary, background_texture: Texture2D, world_size: Vector2) -> bool:
	_world_size = world_size
	occluder_id = String(data.get("id", ""))
	blocker_id = String(data.get("blocker_id", ""))
	depth_mode = StringName(data.get("depth_mode", "overlap"))
	depth_y = clampf(float(data.get("depth_y", 0.0)), 0.0, 1.0)
	player_faded_alpha = clampf(float(data.get("actor_faded_alpha", 0.46)), 0.15, 0.90)
	var sampled_texture := background_texture
	var source_texture_path := String(data.get("source_texture_path", ""))
	if source_texture_path != "":
		var source_texture := load(source_texture_path) as Texture2D
		if source_texture != null:
			sampled_texture = source_texture
	var difference_mask_texture := background_texture
	var mask_texture_path := String(data.get("mask_texture_path", ""))
	if mask_texture_path != "":
		var mask_texture := load(mask_texture_path) as Texture2D
		if mask_texture != null:
			difference_mask_texture = mask_texture
	var alpha_mask_texture_path := String(data.get("alpha_mask_texture_path", ""))
	if alpha_mask_texture_path != "":
		_actor_overlap_mask = load(alpha_mask_texture_path) as Texture2D

	var cover_normalized: PackedVector2Array = data.get("cover_polygon", PackedVector2Array())
	fade_region = data.get("fade_region", PackedVector2Array())
	if sampled_texture == null or cover_normalized.size() < 3:
		return false
	if depth_mode == &"overlap" and fade_region.size() < 3:
		return false
	if depth_mode == &"y_sort" and depth_y <= 0.0:
		return false

	var world_points := PackedVector2Array()
	var source_uv := PackedVector2Array()
	var texture_size := Vector2(sampled_texture.get_width(), sampled_texture.get_height())
	for point in cover_normalized:
		world_points.append(Vector2(point.x * world_size.x, point.y * world_size.y))
		source_uv.append(Vector2(point.x * texture_size.x, point.y * texture_size.y))

	polygon = world_points
	uv = source_uv
	texture = sampled_texture
	if _actor_overlap_mask != null:
		var alpha_shader := Shader.new()
		alpha_shader.code = ALPHA_MASK_SHADER
		var alpha_material := ShaderMaterial.new()
		alpha_material.shader = alpha_shader
		alpha_material.set_shader_parameter("alpha_mask", _actor_overlap_mask)
		material = alpha_material
	elif bool(data.get("isolate_difference", false)) and difference_mask_texture != null:
		var difference_shader := Shader.new()
		difference_shader.code = DIFFERENCE_MASK_SHADER
		var difference_material := ShaderMaterial.new()
		difference_material.shader = difference_shader
		difference_material.set_shader_parameter("clean_texture", difference_mask_texture)
		difference_material.set_shader_parameter("difference_threshold", float(data.get("difference_threshold", 0.08)))
		difference_material.set_shader_parameter("edge_softness", float(data.get("difference_softness", 0.06)))
		material = difference_material
	color = Color.WHITE
	modulate = Color.WHITE
	z_index = int(data.get("z_index", 0))
	visible = depth_mode != &"y_sort"
	return true


func update_player_position(normalized_foot_position: Vector2, immediate: bool = false) -> void:
	if depth_mode == &"y_sort":
		# Smaller screen Y is farther away in the fixed 2.5D projection.
		visible = normalized_foot_position.y < depth_y
		is_faded = false
		return
	is_faded = Geometry2D.is_point_in_polygon(normalized_foot_position, fade_region)


func get_player_faded_alpha() -> float:
	return player_faded_alpha


func get_actor_overlap_mask_payload() -> Dictionary:
	if _actor_overlap_mask == null:
		return {}
	return {
		"texture": _actor_overlap_mask,
		"world_size": _world_size,
	}


func contains_fade_point(normalized_foot_position: Vector2) -> bool:
	return depth_mode == &"overlap" and fade_region.size() >= 3 and Geometry2D.is_point_in_polygon(normalized_foot_position, fade_region)


func uses_foot_depth_sort() -> bool:
	return depth_mode == &"y_sort"
