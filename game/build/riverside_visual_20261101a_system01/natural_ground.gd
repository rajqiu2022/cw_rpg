extends RefCounted
## Visual-only, exact riverside owner. The original layout remains authoritative.
const SCENE_ID: String = "adventure_luoyang_riverside_route"
const LAYOUT_PATH: String = "res://data/maps/adventure_20261030k/luoyang_riverside_layout.tres"
const HUNTING_ID: String = "adventure_zhuwei_hunting_ground"
const HUNTING_LAYOUT: String = "res://data/maps/adventure_20261030k/forest_layout.tres"
const BACKHILL_ID: String = "ch1_s3_zhuwei_forest"
const BACKHILL_LAYOUT: String = "res://data/maps/ch1_s3_zhuwei_forest_layout_v3.tres"
const RUIN_ID: String = "ch1_s3_west_ruin"
const RUIN_LAYOUT: String = "res://data/maps/ch1_s3_west_ruin_layout_v2.tres"
const SHADER_PATH: String = "res://build/riverside_visual_20261101a_system01/natural_ground.gdshader"
const EARTH_PATH: String = "res://art/modules/sect_maps_20261029k/quiet_ground.png"
const DIRT_PATH: String = "res://art/modules/miao_town_20261029f/ground.png"
const STONE_PATH: String = "res://art/modules/miao_town_20261029f/path.png"
const NODE_NAME: String = "RiversideNaturalGround01"
const MAX_SEGMENTS: int = 32

static func supports(scene: SceneScript) -> bool:
	if scene == null or scene.map_layout == null:
		return false
	return (String(scene.scene_id) == SCENE_ID and scene.map_layout.resource_path == LAYOUT_PATH) or (String(scene.scene_id) == HUNTING_ID and scene.map_layout.resource_path == HUNTING_LAYOUT) or (String(scene.scene_id) == BACKHILL_ID and scene.map_layout.resource_path == BACKHILL_LAYOUT) or (String(scene.scene_id) == RUIN_ID and scene.map_layout.resource_path == RUIN_LAYOUT)

static func install(field: Node, logical: String) -> bool:
	if logical not in [SCENE_ID, HUNTING_ID, BACKHILL_ID, RUIN_ID]:
		return false
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	var visuals: Node = field.get("_visual_layer") as Node
	if not supports(scene) or visuals == null:
		return false
	var world_size: Vector2 = field.get("_world_size")
	if not add_ground(visuals, scene, world_size):
		return false
	# Keep the original visual nodes/data, but do not draw the rejected UV tubes.
	for child: Node in visuals.get_children():
		if child is Line2D and String(child.name).begins_with("TravelRoute_"):
			(child as Line2D).hide()
	return true

static func add_ground(parent: Node, scene: SceneScript, world_size: Vector2) -> bool:
	if not supports(scene) or world_size.x <= 0.0 or world_size.y <= 0.0:
		return false
	if parent.has_node(NodePath(NODE_NAME)):
		return true
	var segments := PackedVector4Array()
	var widths := PackedVector2Array()
	var route_index: int = 0
	var routes: Array = scene.map_layout.get_meta("ground_paths", scene.map_layout.travel_routes) if scene.scene_id in [StringName(BACKHILL_ID), StringName(RUIN_ID)] else scene.map_layout.travel_routes
	for route: Dictionary in routes:
		var points: PackedVector2Array = route.get("points", PackedVector2Array())
		var half_width: float = float(route.get("width_px", 0.0)) * 0.5
		if half_width <= 0.0 or points.size() < 2:
			return false
		for index: int in range(points.size() - 1):
			var start: Vector2 = points[index] * world_size
			var finish: Vector2 = points[index + 1] * world_size
			if start.distance_squared_to(finish) < 0.001:
				continue
			if segments.size() >= MAX_SEGMENTS:
				return false
			segments.append(Vector4(start.x, start.y, finish.x, finish.y))
			# Every original centerline/endpoint stays fixed. Only the painted verge varies.
			widths.append(Vector2(_radius(half_width, index, route_index), _radius(half_width, index + 1, route_index)))
		route_index += 1
	if segments.is_empty():
		return false
	var count: int = segments.size()
	segments.resize(MAX_SEGMENTS)
	widths.resize(MAX_SEGMENTS)
	var material := ShaderMaterial.new()
	material.shader = load(SHADER_PATH) as Shader
	material.set_shader_parameter("earth_tex", load(EARTH_PATH))
	material.set_shader_parameter("dirt_tex", load(DIRT_PATH))
	material.set_shader_parameter("stone_tex", load(STONE_PATH))
	material.set_shader_parameter("route_segments", segments)
	material.set_shader_parameter("route_widths", widths)
	material.set_shader_parameter("segment_count", count)
	var ground := Polygon2D.new()
	ground.name = NODE_NAME
	ground.polygon = PackedVector2Array([Vector2.ZERO, Vector2(world_size.x, 0.0), world_size, Vector2(0.0, world_size.y)])
	ground.material = material
	ground.z_index = -900
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ground.set_meta("source_layout", scene.map_layout.resource_path)
	ground.set_meta("source_route_segment_count", count)
	parent.add_child(ground)
	return true

static func _radius(half_width: float, point_index: int, route_index: int) -> float:
	return half_width * (0.90 + 0.13 * sin(float(point_index) * 1.71 + float(route_index) * 2.13))
