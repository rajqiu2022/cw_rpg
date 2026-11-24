extends Control
## Read-only local plan. Static commands are retained in a separate CanvasItem;
## moving the actor redraws only its marker, never the city or a SubViewport.
const FRAME: Texture2D = preload("res://art/ui/field_hud/v1/hud_quest_panel.png")
const CITIES := [&"openworld_bianzhou_city", &"openworld_jinling_city", &"openworld_xiangzhou_city", &"openworld_redrock_town", &"openworld_desert_city", &"openworld_lanxi_zhai"]
const REGIONS := ["estate27d_east_bedroom", "estate27d_living_hall", "estate27d_west_study", "luoyang_civic_market_region_27d", "luoyang_estate_region_27d", "luoyang_temple_region_27d", "temple27d_main_hall", "temple27d_monks_room", "temple27d_sutra_room", "yihongyuan27n_interior"]
const LUOYANG := ["ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market", "ch4_s4_ancient_temple", "luoyang_estate_riverside_20261021ai", "luoyang_artisan_residential_20261022ap", "luoyang_riverside_garden_20261022ap", "luoyang_market_inn_interior_20261015", "luoyang_functional_pawnshop_candidate_20261016", "luoyang_market_market_northeast_rear_frontage_interior_20261015", "luoyang_market_shop_interior_20261015", "luoyang_market_market_east_ward_frontage_interior_20261015", "luoyang_market_north_market_front_interior_20261015", "luoyang_market_market_west_ward_frontage_interior_20261015", "luoyang_market_market_northwest_rear_frontage_interior_20261015", "luoyang_market_southeast_market_front_interior_20261015", "luoyang_canal_warehouse_interior_20261016", "luoyang_functional_mansion_candidate_20261016"]

class Plan extends Control:
	var roads: Array[PackedVector2Array] = []
	var buildings: Array[PackedVector2Array] = []
	var portals: Array[Dictionary] = []
	var world_size := Vector2.ONE
	var base_texture: Texture2D
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("24332f"))
		if base_texture != null: draw_texture_rect(base_texture, Rect2(Vector2.ZERO, size), false)
		var factor := size / world_size
		for source: PackedVector2Array in roads:
			var points := PackedVector2Array()
			for point: Vector2 in source: points.append(point * factor)
			if Geometry2D.triangulate_polygon(points).size() >= 3: draw_colored_polygon(points, Color("a8a18a"))
		for source: PackedVector2Array in buildings:
			var points := PackedVector2Array()
			for point: Vector2 in source: points.append(point * factor)
			if Geometry2D.triangulate_polygon(points).size() >= 3:
				draw_colored_polygon(points, Color("665a49"))
				points.append(points[0]); draw_polyline(points, Color("d0b991"), 0.8, true)
		for portal: Dictionary in portals:
			draw_circle(portal.foot * factor, 2.6, Color("162a2d"))
			draw_circle(portal.foot * factor, 1.7, Color("e9d496"))

class Marker extends Control:
	var point := Vector2.ZERO
	var direction := "down"
	func _draw() -> void:
		var facing := Vector2.DOWN
		match direction:
			"up": facing = Vector2.UP
			"left": facing = Vector2.LEFT
			"right": facing = Vector2.RIGHT
		var side := facing.orthogonal()
		draw_circle(point, 5.5, Color("112a30"))
		draw_colored_polygon(PackedVector2Array([point + facing * 6, point - facing * 3 + side * 3.5, point - facing * 3 - side * 3.5]), Color("b3ffff"))

var _field: WeakRef
var _player: WeakRef
var _world: WeakRef
var _native: WeakRef
var _scene_id := ""
var _context_id := ""
var _world_size := Vector2.ONE
var _world_origin := Vector2.ZERO
var _map_rect := Rect2()
var _viewport_size := Vector2.ZERO
var _player_world := Vector2.ZERO
var _player_uv := Vector2.ZERO
var _plan: Plan
var _marker: Marker
var _static_build_count := 0
var _compiled: Dictionary
var _configured := false
var _shader_seen: Dictionary = {}
var _gm_rect := Rect2()
var _room_floors: Array[PackedVector2Array] = []
var _background_path := ""

static func accepts(scene: SceneScript) -> bool:
	if scene == null: return false
	var id := String(scene.scene_id)
	return id in ["openworld_bailu_ferry", "openworld_east_sea_port", "linxi_tutorial", "linxi_village_center", "linxi_village_scrollmap", "ch1_s2_qingfeng", "ch2_s1_zhuwei_market"]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	visible = false

func configure(field: Node, scene: SceneScript, player: Node2D, _camera: Camera2D, world: Node2D, compiled: Dictionary = {}) -> bool:
	if not accepts(scene) or not is_instance_valid(player) or not is_instance_valid(world): return false
	_field = weakref(field); _player = weakref(player); _world = weakref(world)
	_scene_id = String(scene.scene_id); _compiled = compiled
	_world_size = Vector2(compiled.get("size", field.get("_world_size")))
	if not _world_size.is_finite() or _world_size.x <= 0 or _world_size.y <= 0: return false
	if scene.map_layout != null and ("interior" in _scene_id or _scene_id in ["luoyang_functional_pawnshop_candidate_20261016", "luoyang_functional_mansion_candidate_20261016"]):
		for polygon: PackedVector2Array in scene.map_layout.walkable_regions:
			var pixels := PackedVector2Array()
			for point: Vector2 in polygon: pixels.append(point * _world_size)
			_room_floors.append(pixels)
	var native: Variant = field.get("native_town") if field.has_method("get_world_town_debug") else null
	if is_instance_valid(native): _native = weakref(native)
	_plan = Plan.new(); _plan.mouse_filter = Control.MOUSE_FILTER_IGNORE; _plan.clip_contents = true; add_child(_plan)
	_marker = Marker.new(); _marker.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(_marker)
	_configured = true
	_build_plan()
	# Xiangzhou is still the original single-image city, not a reconstructed
	# Polygon2D city. Its own visible background already contains the roads.
	# Retain one texture draw, never sample a World overview or render its tree.
	if _scene_id == "openworld_xiangzhou_city" and _plan.roads.is_empty() and scene.background_path == "res://art/backgrounds/openworld_cities_v2/bg_xiangzhou_garrison_gameplay_v2_3072.png":
		_plan.base_texture = load(scene.background_path) as Texture2D
		if _plan.base_texture != null: _background_path = scene.background_path
		_plan.queue_redraw()
	update_view()
	return true

func _rect_points(area: Rect2) -> PackedVector2Array:
	return PackedVector2Array([area.position, Vector2(area.end.x, area.position.y), area.end, Vector2(area.position.x, area.end.y)])

func _mapped(node: Node2D, points: PackedVector2Array, world: Node2D) -> PackedVector2Array:
	var output := PackedVector2Array()
	for point: Vector2 in points: output.append(world.to_local(node.to_global(point)) - _world_origin)
	return output

func _building_texture(path: String) -> bool:
	for part: String in ["house", "hall", "dwelling", "gate", "workshop", "tower", "warehouse", "residence", "pavilion", "study", "bedroom", "smithy", "shop", "inn_"]:
		if part in path.get_file().to_lower(): return true
	return false

func _scan(node: Node, world: Node2D) -> void:
	if node is CanvasLayer or node is CharacterBody2D: return
	if node is Node2D and not node.is_visible_in_tree(): return
	if node is Node2D and node.has_meta("visual_rect") and node.get_meta("visual_rect") is Rect2:
		_plan.buildings.append(_mapped(node, _rect_points(node.get_meta("visual_rect")), world))
	if _compiled.is_empty() and node is Sprite2D and node.texture != null and _building_texture(node.texture.resource_path) and not node.get_parent().has_meta("visual_rect"):
		_plan.buildings.append(_mapped(node, _rect_points(node.get_rect()), world))
	if node is Polygon2D and node.material is ShaderMaterial:
		_shader_roads(node.material.shader)
	if node is Polygon2D and node.z_index <= -900 and node.polygon.size() >= 3:
		# Existing paving commands, not a render of the whole world or its atlas.
		var path: String = node.texture.resource_path.to_lower() if node.texture != null else ""
		if not ("grass" in path or "soil" in path or "earth" in path or "water" in path): _plan.roads.append(_mapped(node, node.polygon, world))
	if _compiled.is_empty() and node is CollisionPolygon2D and node.get_parent() is StaticBody2D and not node.disabled:
		var points := _mapped(node, node.polygon, world)
		if points.size() >= 3: _plan.buildings.append(points)
	elif _compiled.is_empty() and node is CollisionShape2D and node.get_parent() is StaticBody2D and not node.disabled and node.shape is RectangleShape2D:
		_plan.buildings.append(_mapped(node, _rect_points(Rect2(-node.shape.size * 0.5, node.shape.size)), world))
	if _compiled.is_empty() and node is ExitZone:
		_plan.portals.append({"id": String(node.name), "target_scene": String(node.target_scene_id), "foot": world.to_local(node.global_position) - _world_origin})
	elif _compiled.is_empty() and node is Node2D and node.name in [&"Exit", &"HallDoor", &"HomeDoor"]:
		_plan.portals.append({"id": String(node.name), "target_scene": "", "foot": world.to_local(node.global_position) - _world_origin})
	for child: Node in node.get_children(): _scan(child, world)

func _shader_roads(shader: Shader) -> void:
	# Native towns author their visible paths in the ground shader instead of
	# Polygon2Ds. Read its real literal centerlines once; do not invent roads
	# from navigation, nor redraw the textured native scene in the HUD.
	if shader == null or _native == null or _shader_seen.has(shader.resource_path): return
	if shader.resource_path not in ["res://art/modules/desert_town_20261029d/ground.gdshader", "res://art/modules/redrock_city_life_20261029a/ground.gdshader", "res://art/modules/miao_terrain_20261029i/ground.gdshader"]: return
	_shader_seen[shader.resource_path] = true
	var expression := RegEx.new()
	if expression.compile("(?:line_dist|dseg|segment)\\(p,vec2\\(([0-9.]+),([0-9.]+)\\),vec2\\(([0-9.]+),([0-9.]+)\\)\\)") != OK: return
	for found: RegExMatch in expression.search_all(shader.code):
		var a := Vector2(float(found.get_string(1)), float(found.get_string(2)))
		var b := Vector2(float(found.get_string(3)), float(found.get_string(4)))
		var line: String = shader.code.substr(maxi(0, found.get_start() - 60), 60)
		var width: float = 125.0 if "desert_town" in shader.resource_path else (105.0 if "miao_terrain" in shader.resource_path else (160.0 if "main=min" in line else (72.0 if "alley=min" in line else 100.0)))
		for polygon: PackedVector2Array in Geometry2D.offset_polyline(PackedVector2Array([a, b]), width, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND): _plan.roads.append(polygon)

func _build_plan() -> void:
	_plan.roads.clear(); _plan.buildings.clear(); _plan.portals.clear(); _shader_seen.clear()
	var world: Node2D = _world.get_ref() as Node2D
	var native: Variant = _native.get_ref() if _native != null else null
	var root: Node = world
	_world_origin = Vector2.ZERO
	_context_id = _scene_id
	if is_instance_valid(native) and bool(native.get("in_hall")):
		root = native.get("hall") as Node2D
		_context_id += "/" + String(root.name)
		# Cached native rooms are authored around their entrance origin. Their
		# visible floor extent supplies exact local bounds, never outdoor coords.
		var bounds := Rect2()
		for item: Node in root.find_children("*", "Sprite2D", true, false):
			var sprite := item as Sprite2D
			var corners := _mapped(sprite, _rect_points(sprite.get_rect()), world)
			for point: Vector2 in corners:
				bounds = Rect2(point, Vector2(0.01, 0.01)) if bounds.size == Vector2.ZERO else bounds.expand(point)
		if bounds.size.x > 0 and bounds.size.y > 0:
			_world_origin = bounds.position; _world_size = bounds.size
		_plan.roads.append(_rect_points(Rect2(Vector2.ZERO, _world_size)))
	else:
		var field: Node = _field.get_ref() as Node
		_world_size = Vector2(_compiled.get("size", field.get("_world_size")))
		if not _compiled.is_empty():
			for points: PackedVector2Array in _compiled.get("solids", []): _plan.buildings.append(points)
			for row: Dictionary in _compiled.get("render", []):
				if not _building_texture(String(row.get("texture", ""))): continue
				var extent: Vector2 = row.get("texture_size_px", Vector2.ZERO) * row.scale
				var start: Vector2 = row.position_px - extent * (0.5 if row.get("centered", true) else 0.0)
				if extent.x > 0 and extent.y > 0: _plan.buildings.append(_rect_points(Rect2(start, extent)))
			for portal: Dictionary in _compiled.get("portals", []): _plan.portals.append({"id": String(portal.get("key", "")), "target_scene": String(portal.get("data", portal).get("target_scene", "")), "foot": portal.foot})
			# Room floor is real room geometry, not an outdoor walkable rectangle.
			if _compiled.get("navigation_kind") == "AUTHORED_INTERIOR":
				for area: Rect2 in _compiled.get("floor_rects", []): _plan.roads.append(_rect_points(area))
		else: _plan.roads.append_array(_room_floors)
	_scan(root, world)
	_static_build_count += 1
	_plan.world_size = _world_size
	_viewport_size = Vector2.ZERO
	_plan.queue_redraw()

func _process(_delta: float) -> void: update_view()

func update_view() -> void:
	if not _configured or not is_inside_tree(): return
	var actor: Variant = _player.get_ref()
	var world: Variant = _world.get_ref()
	if not is_instance_valid(actor) or not is_instance_valid(world): release(); return
	var native: Variant = _native.get_ref() if _native != null else null
	if is_instance_valid(native):
		var context: String = _scene_id + ("/" + String(native.get("hall").name) if bool(native.get("in_hall")) else "")
		if context != _context_id: _build_plan()
	var hud := get_parent() as Control
	var plaque := hud.get_node_or_null("MapInfoPanel") as Control if hud != null else null
	visible = hud == null or ((plaque == null or plaque.is_visible_in_tree()) and not (hud.has_method("is_right_menu_visible") and hud.call("is_right_menu_visible")))
	var viewport := get_viewport_rect().size
	var gm := get_node_or_null("/root/GMConsole/GMFloatingButton") as Control
	var gm_rect := gm.get_global_rect() if gm != null and gm.is_visible_in_tree() else Rect2()
	var gm_bottom := gm_rect.end.y if gm_rect.size != Vector2.ZERO else 0.0
	if viewport != _viewport_size or gm_rect != _gm_rect:
		_viewport_size = viewport
		_gm_rect = gm_rect
		var ui_scale := clampf(viewport.y / 1080.0, 0.72, 1.0)
		size = Vector2(280, 210) * ui_scale
		var top := 116.0 * ui_scale
		var art := plaque.get_node_or_null("MapPanelArt") as TextureRect if plaque != null else null
		if art != null: top = maxf(top, art.get_global_rect().end.y + 10 * ui_scale)
		if gm_bottom > 0: top = maxf(top, gm_bottom + 12 * ui_scale)
		var point := Vector2(maxf(8, viewport.x - 16 * ui_scale - size.x), clampf(top, 8, maxf(8, viewport.y - size.y - 12)))
		position = hud.get_global_transform().affine_inverse() * point if hud != null else point
		var inset := Rect2(Vector2(18, 32) * ui_scale, Vector2(244, 162) * ui_scale)
		var fit := minf(inset.size.x / _world_size.x, inset.size.y / _world_size.y)
		_map_rect = Rect2(inset.position + (inset.size - _world_size * fit) * 0.5, _world_size * fit)
		_plan.position = _map_rect.position; _plan.size = _map_rect.size; _plan.queue_redraw()
		queue_redraw()
	var foot: Vector2 = actor.global_position
	if not is_instance_valid(native) and actor.has_method("get_depth_sort_y"): foot.y = float(actor.call("get_depth_sort_y"))
	_player_world = world.to_local(foot) - _world_origin
	_player_uv = _player_world / _world_size
	_marker.point = _map_rect.position + _player_uv * _map_rect.size
	_marker.direction = String(actor.get("_direction")); _marker.queue_redraw()

func _draw() -> void:
	if _configured: draw_texture_rect(FRAME, Rect2(Vector2.ZERO, size), false)

func get_debug_state() -> Dictionary:
	var portals: Array[Dictionary] = []
	for row: Dictionary in _plan.portals if _plan != null else []:
		var copy := row.duplicate(); copy.marker = get_global_transform() * (_map_rect.position + row.foot / _world_size * _map_rect.size); portals.append(copy)
	return {"configured": _configured, "scene_id": _scene_id, "context_id": _context_id, "visible": is_visible_in_tree(), "world_size": _world_size, "world_origin": _world_origin, "panel_rect": get_global_rect(), "map_rect": Rect2(get_global_transform() * _map_rect.position, _map_rect.size), "player_world": _player_world, "player_uv": _player_uv, "player_marker": get_global_transform() * _marker.point if _marker != null else Vector2.ZERO, "portals": portals, "road_count": _plan.roads.size() if _plan != null else 0, "building_count": _plan.buildings.size() if _plan != null else 0, "static_build_count": _static_build_count, "frame_path": FRAME.resource_path, "overview_path": "", "background_path": _background_path, "mouse_filter": mouse_filter, "zoom": 1.0}

func release() -> void:
	_configured = false; visible = false; set_process(false)
	_field = null; _player = null; _world = null; _native = null
