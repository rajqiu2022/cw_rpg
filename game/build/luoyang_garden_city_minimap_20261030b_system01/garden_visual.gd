extends RefCounted
## Visual successor only: unchanged compiled navigation/solids/portals/bin.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Old = preload("res://build/luoyang_estate_garden_20261029q_system01/garden_visual.gd")
const SELF := "res://build/luoyang_garden_city_minimap_20261030b_system01/garden_visual.gd"
const SPEC := "res://build/luoyang_garden_city_minimap_20261030b_system01/visual_paths.json"
static func handles(region: Dictionary) -> bool: return Old.handles(region)
static func visible_surface(region: Dictionary, row: Dictionary) -> bool:
	return not (handles(region) and String(row.get("id", "")) == "rear_axis")
static func _smooth(points: PackedVector2Array, radius: float, closed: bool = false) -> PackedVector2Array:
	var result := PackedVector2Array()
	if not closed: result.append(points[0])
	for i: int in range(points.size()):
		if not closed and (i == 0 or i == points.size() - 1): continue
		var a: Vector2 = points[(i - 1 + points.size()) % points.size()]
		var b: Vector2 = points[i]
		var c: Vector2 = points[(i + 1) % points.size()]
		var length := minf(radius, minf(b.distance_to(a), b.distance_to(c)) * 0.4)
		var entry := b.move_toward(a, length); var leave := b.move_toward(c, length)
		for k: int in range(7):
			var t := float(k) / 6.0
			result.append(entry.lerp(b, t).lerp(b.lerp(leave, t), t))
	if not closed: result.append(points[-1])
	return result
static func install(field: Node, owner: RefCounted, region: Dictionary) -> bool:
	if not handles(region) or owner == null or owner.call("matches", field, field.get("_current_scene")) != true: return false
	if var_to_bytes(owner.get("_compiled")) != var_to_bytes(region): return false
	var first: Dictionary = owner.call("receipt").get("source_first", {})
	for path: String in [SELF, SPEC]:
		if first.get(path) != FileAccess.get_sha256(path): return false
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPEC))
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Old.SPEC))
	var grass: Dictionary = old.groundcover
	var texture: Texture2D = load(grass.texture) as Texture2D
	var layer: Node = field.get("_visual_layer")
	if texture == null or first.get(grass.texture) != FileAccess.get_sha256(grass.texture): return false
	var lawns: Array = grass.polygons.duplicate(true)
	lawns.append(spec.north_lawn_finish.candidate_linking_lawn_polygon)
	for raw: Array in lawns:
		var outer: PackedVector2Array = Old._points(raw)
		for i: int in range(8):
			var inset: Array = [outer] if i == 0 else Geometry2D.offset_polygon(outer, -8.0 * i)
			for shape: PackedVector2Array in inset: Old._draw(layer, shape, texture, Core.vec(grass.texture_period_px), -999, 1.0 / float(8 - i))
	var paving_path: String = spec.material.texture
	var paving: Texture2D = load(paving_path) as Texture2D
	var period: Vector2 = Core.vec(spec.material.period_px)
	if paving == null or first.get(paving_path) != FileAccess.get_sha256(paving_path): return false
	# Union the lower trunk and upper taper before rounding. At y620 the
	# shared edge is internal, so it cannot leave two rounded-corner notches.
	var trunk := PackedVector2Array([Vector2(1392,1620),Vector2(1392,1464),Vector2(1392,620),Vector2(1446,430),Vector2(1626,430),Vector2(1680,620),Vector2(1680,1464),Vector2(1680,1620)])
	Old._draw(layer, _smooth(trunk, 48.0, true), paving, period, -998, 1.0)
	for route: Dictionary in spec.route_ribbons:
		var points := _smooth(Old._points(route.points), float(route.curve_corner_radius_px))
		for shape: PackedVector2Array in Geometry2D.offset_polyline(points, float(route.width_px) * 0.5, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND): Old._draw(layer, shape, paving, period, -998, 1.0)
	# Shared world UV makes these smooth bell-mouths exact with the axis/cross.
	for center: Vector2 in [Vector2(1536,430), Vector2(1536,1136)]:
		var disk := PackedVector2Array()
		for i: int in range(32): disk.append(center + Vector2.from_angle(TAU * i / 32.0) * 90.0)
		Old._draw(layer, disk, paving, period, -998, 1.0)
	return true
