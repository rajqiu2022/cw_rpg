extends Control
## Display projection only: neither world gains a new navigation coordinate space.
const EAST_PATH := "res://data/scenes/east_mainland_overworld.tres"
const PORTRAIT := preload("res://scripts/ui/minimap_portrait.gd")
const WATER := "res://art/maps/jinling_city_20261029/river_water_v1.png"
const GRASS := "res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/grass_ground_diff_2k.jpg"
const EARTH := "res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png"
const STONE := "res://art/modules/luoyang_moat_v1/cobblestone_floor_08_diff_1k.jpg"
const SEA := Color("254948")
const EAST_PORT := &"east_tidegate_port"
const ISLAND := &"openworld_east_sea_port"
const BAILU := &"openworld_bailu_ferry"
const WEST_TOWNS := "res://build/three_towns_world_20261029j_system01/town_registry.gd"
const WEST_TRAILS := "res://build/adventure_world_20261031f_system01/world_links.gd"

var west: SceneScript
var west_preview: Texture2D
var east: SceneScript
var local: SceneScript
var _actor: WeakRef
var _portrait: Control
var _textures: Dictionary = {}
var _projection := Rect2()
var _chart := preload("res://scripts/ui/minimap_exploration.gd").new()
var _paving: Array[Dictionary] = []
var _local_map: Control
var _west_size := Vector2.ZERO
var _east_size := Vector2.ZERO
var _west_rows: Array[Dictionary] = []
var _marker_point := Vector2.INF
var _marker_state: Dictionary = {}
var _viewport_extent := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	resized.connect(queue_redraw)
	_portrait = PORTRAIT.new()
	_portrait.hide()
	add_child(_portrait)
	set_process(false)


func configure_overview(west_scene: SceneScript, preview: Texture2D) -> bool:
	east = load(EAST_PATH) as SceneScript
	west = west_scene
	west_preview = preview
	if west == null or west.map_layout == null or east == null or east.map_layout == null or west_preview == null:
		return false
	_west_size = Vector2(west.map_layout.design_size)
	_east_size = Vector2(east.map_layout.design_size)
	if int(west.get_meta("coordinate_space_version", -1)) != 16 or _west_size != Vector2(12288, 8192) or _east_size != Vector2(6144, 8192):
		return false
	_west_rows = west.map_layout.portals.duplicate()
	for path in [WEST_TOWNS, WEST_TRAILS]:
		var source := load(path) as Script
		if source == null:
			continue
		for entry: Dictionary in source.call("portal_rows"):
			var row := entry.duplicate()
			row["pos"] = Vector2(row.world_foot) / _west_size
			_west_rows.append(row)
	queue_redraw()
	return true


func configure_local(scene: SceneScript, actor: Node2D) -> void:
	local = scene
	_cache_paving(scene.map_layout)
	_actor = weakref(actor)
	if _local_map == null:
		_local_map = Control.new()
		_local_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_local_map.clip_contents = true
		add_child(_local_map)
		move_child(_local_map, 0)
		_local_map.draw.connect(_paint_local)
	_place_minimap()
	set_process(true)
	queue_redraw()


static func visit_flag(id: StringName) -> StringName:
	return StringName("east_chart_visited_" + String(id))


func _draw() -> void:
	_marker_state.clear()
	if local != null:
		_draw_local()
	elif west != null and west_preview != null and east != null:
		_draw_overview()


func _draw_overview() -> void:
	var chart := Vector2(_west_size.x + _east_size.x, _west_size.y)
	# The original page may append extra labels after opening; cover the
	# full content area, including the letterbox, while this page is visible.
	draw_rect(Rect2(Vector2.ZERO, size), Color("101c1b"))
	_projection = _fit(Rect2(Vector2.ZERO, size), chart)
	var scale_px := _projection.size.x / chart.x
	var west_rect := Rect2(_projection.position, _west_size * scale_px)
	var east_rect := Rect2(Vector2(west_rect.end.x, west_rect.position.y), _east_size * scale_px)
	draw_rect(_projection, SEA)
	draw_texture_rect(west_preview, west_rect, false)
	_draw_region(east.map_layout, east_rect, false, true)
	var west_ports := _portal_points(_west_rows, west_rect)
	var east_ports := _portal_points(east.map_layout.portals, east_rect)
	_ferry(west_ports.get(BAILU, Vector2.INF), west_ports.get(ISLAND, Vector2.INF), 16.0)
	_ferry(west_ports.get(ISLAND, Vector2.INF), east_ports.get(EAST_PORT, Vector2.INF), -15.0)
	_label("江湖行旅总览", Vector2(16, _projection.position.y - 44), 27, Color("f8e2ac"))
	_label("白鹿渡  ·  东海埠  ·  潮门港", Vector2(16, _projection.end.y + 31), 15, Color("dec995"))
	_ferry(Vector2(268, _projection.end.y + 26), Vector2(312, _projection.end.y + 26), 0.0)
	_label("乘船航线", Vector2(321, _projection.end.y + 31), 15, Color("cde1cb"))
	_label("中原", _projection.position + Vector2(14, 26), 22, Color("f8e2ac"))
	_label("外海", Vector2(east_rect.position.x + 72, east_rect.position.y + 92), 21, Color("d1e5d9"))
	_label("东大陆", Vector2(east_rect.end.x - 82, east_rect.position.y + 29), 21, Color("f8e2ac"))
	var label_rects: Array[Rect2] = [Rect2(_projection.position, Vector2(66, 32))]
	for row in _west_rows:
		var id := StringName(row.get("target_scene", ""))
		if not west_ports.has(id):
			continue
		var pt: Vector2 = west_ports[id]
		var gate := StringName(row.get("require_flag", ""))
		var tone := Color("f4daa3") if gate == &"" or GameState.get_flag(gate) == true else Color("acb7b4")
		_place_west_label(String(row.get("label", "")), pt, west_rect, label_rects, tone)
	for row in east.map_layout.portals:
		var id := StringName(row.target_scene)
		var pt: Vector2 = east_ports[id]
		var visited: bool = GameState.get_flag(visit_flag(id)) == true
		var color := Color("f4daa3") if visited else Color("aab5b3")
		_marker_state[id] = visited
		draw_circle(pt, 4.5, Color("233834"), true, -1, true)
		draw_circle(pt, 2.8, color, true, -1, true)
		var delta := Vector2(-52, 13) if pt.x > east_rect.end.x - 62 else Vector2(8, 5)
		_label(String(row.label), pt + delta, 15, color)
	var current := SceneRouter.get_current_field_id()
	var pos: Vector2 = east_ports.get(current, west_ports.get(current, Vector2.INF))
	var field := get_tree().current_scene
	if field != null and (current == east.scene_id or current == west.scene_id):
		var actor := field.get("_player") as Node2D
		if actor != null:
			pos = (east_rect.position if current == east.scene_id else west_rect.position) + actor.position * scale_px
	elif not pos.is_finite():
		var anchor: Variant = SceneRouter.get_world_map_position_for_scene(current, west.scene_id)
		if anchor is Vector2:
			pos = west_rect.position + anchor * west_rect.size
	_set_marker.call_deferred(pos)


func _draw_local() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.023, 0.049, 0.054, 0.66))

func _paint_local() -> void:
	if not _chart.window.has_area():
		return
	var panel := Rect2(Vector2.ZERO, _local_map.size)
	var full := Rect2(_chart.project(Vector2.ZERO, panel), panel.size / _chart.window.size)
	var wet := local.scene_id in [&"east_mainland_overworld", EAST_PORT, &"east_salt_bay_village", &"east_cangpu_city"]
	_draw_region(local.map_layout, full, true, wet, _local_map)
	for row in local.map_layout.portals:
		var pt: Vector2 = _chart.project(row.pos, panel)
		if local.scene_id == east_region_id():
			var id := StringName(row.target_scene)
			var visited: bool = GameState.get_flag(visit_flag(id)) == true
			_marker_state[id] = visited
			var tone := Color("efd298") if visited else Color("adb4b3")
			_local_map.draw_circle(pt, 3.0, tone, true, -1, true)
		else:
			var diamond := PackedVector2Array([pt + Vector2(0, -5), pt + Vector2(5, 0), pt + Vector2(0, 5), pt + Vector2(-5, 0)])
			_local_map.draw_colored_polygon(diamond, Color("eaca8b"))
	_chart.draw_layer(_local_map, _chart.texture, panel)


static func east_region_id() -> StringName:
	return &"east_mainland_overworld"


func _draw_region(layout: WalkableMapLayout, rect: Rect2, compact: bool, wet: bool, canvas: CanvasItem = null) -> void:
	if canvas == null:
		canvas = self
	canvas.draw_texture_rect(_texture(WATER if wet else GRASS), rect, false, Color(0.49, 0.64, 0.62) if wet else Color(0.66, 0.68, 0.57))
	var earthy := compact and layout.design_size.x < 6144 and wet
	var land := _texture(EARTH if earthy else GRASS)
	for poly in layout.walkable_regions:
		var points := _points(poly, rect)
		var uv := PackedVector2Array()
		for p in poly:
			uv.append(p * Vector2(layout.design_size) / 2500.0)
		var tint := Color(0.91, 0.90, 0.79) if earthy else Color(0.80, 0.82, 0.68)
		canvas.draw_polygon(points, PackedColorArray([tint]), uv, land)
		if wet:
			canvas.draw_polyline(points, Color("899584"), 1.0, true)
	if canvas == _local_map:
		for surface: Dictionary in _paving:
			canvas.draw_polygon(_points(surface.points, rect), PackedColorArray([surface.tint]), surface.uv, surface.art)
	else:
		for yard: Dictionary in layout.get_meta("east_yards", []):
			canvas.draw_colored_polygon(_points(yard.points, rect), Color("a99a82") if yard.surface == "stone" else Color("ac9677"))
		for road: Dictionary in layout.get_meta("east_routes", []):
			var width := maxf(1.0 if compact else 2.0, float(road.width_px) / layout.design_size.x * rect.size.x)
			canvas.draw_polyline(_points(road.points, rect), Color("c2aa7f"), width, true)
	for row: Dictionary in layout.blockers:
		if not row.has("salt_pan"):
			continue
		var extent: Vector2 = row.size * rect.size
		var pan := Rect2(rect.position + Vector2(row.pos) * rect.size - extent * 0.5, extent)
		var inset := 15.0 * rect.size.x / layout.design_size.x
		var crust := String(row.salt_pan) == "crystal"
		canvas.draw_rect(pan, Color("8f7859"))
		if crust:
			canvas.draw_rect(pan.grow(-inset), Color("c7c2aa"))
		else:
			canvas.draw_texture_rect(_texture(WATER), pan.grow(-inset), false, Color("94aaa1"))
	var objects := layout.visual_objects.duplicate()
	objects.sort_custom(func(a: Dictionary, b: Dictionary): return float(a.get("depth_sort_foot_y", 0)) < float(b.get("depth_sort_foot_y", 0)))
	for row: Dictionary in objects:
		var art := _texture(String(row.get("texture", "")))
		if art == null:
			continue
		var pt: Vector2 = rect.position + Vector2(row.pos) * rect.size
		var dimensions: Vector2
		var visited := true
		if layout.design_size.x == 6144:
			var id := StringName(String(row.id).trim_suffix("_landmark"))
			visited = GameState.get_flag(visit_flag(id)) == true
			var width := (31.0 if compact else 55.0) if id == &"east_cangpu_city" else (23.0 if compact else 39.0)
			dimensions = Vector2(width, width * float(art.get_height()) / art.get_width())
		else:
			dimensions = art.get_size() * Vector2(row.get("scale", Vector2.ONE)) / Vector2(layout.design_size) * rect.size
		if visited:
			canvas.draw_texture_rect(art, Rect2(pt - dimensions * 0.5, dimensions), false)
		else:
			# Gray silhouette communicates unvisited without a text badge.
			canvas.draw_texture_rect(art, Rect2(pt - dimensions * 0.5, dimensions), false, Color(0.54, 0.58, 0.56))


func _cache_paving(layout: WalkableMapLayout) -> void:
	_paving.clear()
	var extent := Vector2(layout.design_size)
	for yard: Dictionary in layout.get_meta("east_yards", []):
		var path := STONE if yard.surface == "stone" else EARTH
		_add_paving(_points(yard.points, Rect2(Vector2.ZERO, extent)), extent, path, yard.repeat_px, yard.tint)
	for road: Dictionary in layout.get_meta("east_routes", []):
		var line := _points(road.points, Rect2(Vector2.ZERO, extent))
		var outlines := Geometry2D.offset_polyline(line, float(road.width_px) * 0.5, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
		for outline in outlines:
			_add_paving(outline, extent, road.texture, road.get("repeat_px", 425.0), layout.get_meta("east_lane_tint", Color.WHITE))


func _add_paving(outline: PackedVector2Array, extent: Vector2, path: String, period: float, tint: Color) -> void:
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for p in outline:
		points.append(p / extent)
		uv.append(p / period)
	_paving.append({"points": points, "uv": uv, "art": _texture(path), "tint": tint})


func _process(_delta: float) -> void:
	var hud := get_parent()
	visible = not (hud.has_method("is_right_menu_visible") and hud.call("is_right_menu_visible"))
	if visible:
		if get_viewport_rect().size != _viewport_extent:
			_place_minimap()
		_update_local_marker()


func _place_minimap() -> void:
	var hud := get_parent() as Control
	if hud == null:
		return
	_viewport_extent = get_viewport_rect().size
	var factor := clampf(_viewport_extent.y / 1080.0, 0.72, 1.0)
	size = Vector2(362, 256) * factor
	position = hud.get_global_transform().affine_inverse() * Vector2(_viewport_extent.x - size.x - 18.0 * factor, 218.0 * factor)


func _update_local_marker() -> void:
	if _actor == null:
		return
	var actor := _actor.get_ref() as Node2D
	if actor == null:
		return
	_projection = Rect2(Vector2.ZERO, size).grow(-8)
	var extent := Vector2(local.map_layout.design_size)
	var uv := (actor.position / extent).clamp(Vector2.ZERO, Vector2.ONE)
	var previous := _chart.window
	_chart.follow(String(local.scene_id), uv, extent, _projection.size)
	_local_map.position = _projection.position
	_local_map.size = _projection.size
	var point := _chart.project(uv, _projection)
	if previous != _chart.window or point != _marker_point:
		_local_map.queue_redraw()
	_set_marker(point)


func _set_marker(point: Vector2) -> void:
	if _portrait == null or (_marker_point == point and _portrait.visible):
		return
	_marker_point = point
	_portrait.visible = point.is_finite()
	if _portrait.visible:
		_portrait.call("sync_marker", point)


func _portal_points(rows: Array[Dictionary], rect: Rect2) -> Dictionary:
	var out := {}
	for row in rows:
		var id := StringName(row.get("target_scene", ""))
		if id != &"" and not bool(row.get("staging_pending_asset", false)):
			out[id] = rect.position + Vector2(row.pos) * rect.size
	return out


func _ferry(start: Vector2, end: Vector2, bend: float) -> void:
	if not start.is_finite() or not end.is_finite():
		return
	var middle := start.lerp(end, 0.50) + Vector2(0, bend)
	draw_dashed_line(start, middle, Color("cde1cb"), 1.7, 5.0, true, true)
	draw_dashed_line(middle, end, Color("cde1cb"), 1.7, 5.0, true, true)


func _label(value: String, pt: Vector2, font_size: int, tint: Color) -> void:
	var font := get_theme_default_font()
	draw_string_outline(font, pt, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("172826"))
	draw_string(font, pt, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)


func _place_west_label(value: String, pt: Vector2, bounds: Rect2, occupied: Array[Rect2], tone: Color) -> void:
	if value.is_empty():
		return
	const LABEL_SIZE := 13
	var font := get_theme_default_font()
	var text_width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, LABEL_SIZE).x
	var extent := Vector2(text_width + 5.0, 17.0)
	var candidates := [Vector2(4, 4), Vector2(-text_width - 6, 4), Vector2(4, -19), Vector2(-text_width - 6, -19), Vector2(-text_width * 0.5, 16)]
	for offset: Vector2 in candidates:
		var candidate := Rect2((pt + offset).clamp(bounds.position + Vector2(2, 2), bounds.end - extent), extent)
		var available := true
		for used in occupied:
			if candidate.intersects(used):
				available = false
				break
		if available:
			occupied.append(candidate)
			_label(value, candidate.position + Vector2(1, font.get_ascent(LABEL_SIZE)), LABEL_SIZE, tone)
			return


func _texture(path: String) -> Texture2D:
	if not _textures.has(path):
		_textures[path] = load(path) as Texture2D if not path.is_empty() and ResourceLoader.exists(path) else null
	return _textures[path] as Texture2D


func _fit(bounds: Rect2, extent: Vector2) -> Rect2:
	var fit_size := extent * minf(bounds.size.x / extent.x, bounds.size.y / extent.y)
	return Rect2(bounds.position + (bounds.size - fit_size) * 0.5, fit_size)


func _points(input: PackedVector2Array, rect: Rect2) -> PackedVector2Array:
	var output := PackedVector2Array()
	for p in input:
		output.append(rect.position + p * rect.size)
	return output
