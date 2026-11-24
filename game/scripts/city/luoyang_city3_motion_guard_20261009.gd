extends RefCounted
## Motion-only guard for the explicitly bound V11 city. No asset/foot/nav edits.
## Raster intervals are conservatively closed over native Float32 states. This
## may reject a grazing move that the point predicate accepts; it cannot make a
## forbidden point legal. The prefix and solids live only as long as this Field.
const SIZE := Vector2i(3072, 2048)
const BODY := Vector2(34, 24)
var _configured := false
var _prefix := PackedInt32Array()
var _solids: Array[PackedVector2Array] = []
var _solid_minimums: Array[Vector2] = []
var _solid_maximums: Array[Vector2] = []

func release() -> void:
	_configured = false
	_prefix = PackedInt32Array()
	_solids.clear(); _solid_minimums.clear(); _solid_maximums.clear()

func configure(mask: Image, visual_objects: Array) -> bool:
	release()
	if mask == null or mask.get_size() != SIZE or visual_objects.is_empty(): return false
	for value: Variant in visual_objects:
		if not value is Dictionary or typeof(value.get("blocking")) != TYPE_BOOL: release(); return false
		var object: Dictionary = value
		if not object.blocking: continue
		var before: int = _solids.size()
		var raw_polygons: Variant = object.get("city_v3_solid_polygons_px", [])
		if not raw_polygons is Array: release(); return false
		for raw: Variant in raw_polygons:
			var polygon := PackedVector2Array()
			if raw is PackedVector2Array: polygon = raw.duplicate()
			elif raw is Array:
				for vertex: Variant in raw: polygon.append(_point(vertex))
			else: release(); return false
			if not _add_solid(polygon): release(); return false
		var size: Vector2 = _point(object.get("collision_size_px", [0, 0]))
		if not size.is_finite() or size.x < 0 or size.y < 0 or ((size.x == 0) != (size.y == 0)): release(); return false
		if size.x > 0:
			var center: Vector2 = _point(object.get("physical_center_px"))
			if not center.is_finite() or not _add_solid(_rect_polygon(Rect2(center - size * .5, size))): release(); return false
		if _solids.size() == before: release(); return false
	var image: Image = mask.duplicate() as Image
	if image.is_compressed() and image.decompress() != OK: release(); return false
	# Only exact 8-bit channels preserve C's R/A < .5 predicate under conversion.
	# Reject float formats rather than quantizing a forbidden .4999 to byte 128.
	if image.get_format() not in [Image.FORMAT_L8, Image.FORMAT_LA8, Image.FORMAT_RGB8, Image.FORMAT_RGBA8]: release(); return false
	image.convert(Image.FORMAT_RGBA8)
	var pixels: PackedByteArray = image.get_data()
	if pixels.size() != SIZE.x * SIZE.y * 4: release(); return false
	var stride: int = SIZE.x + 1
	_prefix.resize(stride * (SIZE.y + 1)); _prefix.fill(0)
	for y: int in SIZE.y:
		var row_sum := 0
		for x: int in SIZE.x:
			var pixel: int = (y * SIZE.x + x) * 4
			if pixels[pixel] < 128 or pixels[pixel + 3] < 128: row_sum += 1
			_prefix[(y + 1) * stride + x + 1] = _prefix[y * stride + x + 1] + row_sum
	_configured = true
	return true

func safe_motion(from: Vector2, to: Vector2, point_clear: Callable, physical_safe_margin: float) -> bool:
	if not _configured or not point_clear.is_valid() or not _center_in_domain(from) or not _center_in_domain(to): return false
	var start_clear: Variant = point_clear.call(from)
	if typeof(start_clear) != TYPE_BOOL or not start_clear: return false
	# Doorway queries also call the movement constraint at the current foot.
	# Keep that exact point-only behavior, including the original C predicate.
	if from == to: return true
	var end_clear: Variant = point_clear.call(to)
	if typeof(end_clear) != TYPE_BOOL or not end_clear or not is_finite(physical_safe_margin) or physical_safe_margin < 0: return false
	if not _raster_sweep_clear(from, to): return false
	return _solid_sweep_clear(from, to, physical_safe_margin)

func _center_in_domain(p: Vector2) -> bool:
	return p.is_finite() and p.x >= 0 and p.y >= 0 and p.x < SIZE.x and p.y < SIZE.y

func _raster_sweep_clear(from: Vector2, to: Vector2) -> bool:
	var events := PackedFloat64Array([0., 1.])
	for axis: int in 2:
		var a: float = from[axis]; var b: float = to[axis]
		if a == b: continue
		# Integer half-body sizes mean both body edges use this same half-grid.
		for integer: int in range(ceili(minf(a, b) - .5), floori(maxf(a, b) - .5) + 1):
			var t: float = (float(integer) + .5 - a) / (b - a)
			if t > 0. and t < 1.: events.append(t)
	events.sort()
	for index: int in range(1, events.size()):
		var lower: float = events[index - 1]; var upper: float = events[index]
		if lower == upper: continue
		var minimum := Vector2.ZERO; var maximum := Vector2.ZERO
		for axis: int in 2:
			# Scalar endpoints, not Vector2's rounded delta/lerp, bound the entire
			# continuous interval. Outward next-Float32 states close arithmetic
			# ties without an epsilon or a success-point search.
			var a: float = float(from[axis]) + (float(to[axis]) - float(from[axis])) * lower
			var b: float = float(from[axis]) + (float(to[axis]) - float(from[axis])) * upper
			minimum[axis] = _next_float32(minf(a, b), false)
			maximum[axis] = _next_float32(maxf(a, b), true)
		if not minimum.is_finite() or not maximum.is_finite(): return false
		# Match C's actual native Rect2 subtraction/addition chain. A closed
		# bounds union covers every footprint throughout this interval, rather
		# than trusting an interior sample to prove absence.
		var low: Vector4i = _native_bounds(minimum)
		var high: Vector4i = _native_bounds(maximum)
		if not _prefix_clear(Vector4i(low.x, low.y, high.z, high.w)): return false
	return true

func _native_bounds(p: Vector2) -> Vector4i:
	var rect := Rect2(p - BODY * .5, BODY)
	return Vector4i(roundi(rect.position.x), roundi(rect.position.y), roundi(rect.end.x), roundi(rect.end.y))

func _prefix_clear(bounds: Vector4i) -> bool:
	if bounds.x < 0 or bounds.y < 0 or bounds.z >= SIZE.x or bounds.w >= SIZE.y or bounds.x > bounds.z or bounds.y > bounds.w: return false
	var stride: int = SIZE.x + 1
	var right: int = bounds.z + 1; var bottom: int = bounds.w + 1
	return _prefix[bottom * stride + right] - _prefix[bounds.y * stride + right] - _prefix[bottom * stride + bounds.x] + _prefix[bounds.y * stride + bounds.x] == 0

func _solid_sweep_clear(from: Vector2, to: Vector2, margin: float) -> bool:
	var vertices := PackedVector2Array()
	for center: Vector2 in [from, to]:
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			# Collision recovery support only: actual safe_margin is read, never
			# assigned. Raster still uses the original 34x24 body/nav margin 0.
			var x: float = float(center.x) + corner.x * (17. + margin)
			var y: float = float(center.y) + corner.y * (12. + margin)
			var p := Vector2(_next_float32(x, corner.x > 0), _next_float32(y, corner.y > 0))
			if not p.is_finite(): return false
			vertices.append(p)
	var hull: PackedVector2Array = Geometry2D.convex_hull(vertices)
	if hull.size() < 3: return false
	var minimum: Vector2 = hull[0]; var maximum: Vector2 = hull[0]
	for p: Vector2 in hull: minimum = minimum.min(p); maximum = maximum.max(p)
	for index: int in _solids.size():
		var low: Vector2 = _solid_minimums[index]; var high: Vector2 = _solid_maximums[index]
		if maximum.x < low.x or minimum.x > high.x or maximum.y < low.y or minimum.y > high.y: continue
		var solid: PackedVector2Array = _solids[index]
		if _inside_closed(hull[0], solid) or _inside_closed(solid[0], hull): return false
		for i: int in hull.size():
			for j: int in solid.size():
				if _segments_touch(hull[i], hull[(i + 1) % hull.size()], solid[j], solid[(j + 1) % solid.size()]): return false
	return true

func _add_solid(polygon: PackedVector2Array) -> bool:
	if polygon.size() < 3: return false
	var minimum: Vector2 = polygon[0]; var maximum: Vector2 = polygon[0]
	for p: Vector2 in polygon:
		if not p.is_finite(): return false
		minimum = minimum.min(p); maximum = maximum.max(p)
	if Geometry2D.triangulate_polygon(polygon).is_empty(): return false
	_solids.append(polygon); _solid_minimums.append(minimum); _solid_maximums.append(maximum)
	return true

func _point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size() == 2 and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT]: return Vector2(float(value[0]), float(value[1]))
	return Vector2(INF, INF)

func _rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])

func _next_float32(value: float, upwards: bool) -> float:
	var bytes: PackedByteArray = PackedFloat32Array([value]).to_byte_array()
	var native: float = bytes.decode_float(0)
	if not is_finite(native): return native
	if native == 0.:
		bytes.encode_u32(0, 1 if upwards else 0x80000001)
	else:
		bytes.encode_u32(0, bytes.decode_u32(0) + (1 if (native > 0.) == upwards else -1))
	return bytes.decode_float(0)

func _orientation(a: Vector2, b: Vector2, p: Vector2) -> float:
	# Scalar arithmetic avoids a rounded Vector2 subtraction/cross result.
	return (float(b.x) - float(a.x)) * (float(p.y) - float(a.y)) - (float(b.y) - float(a.y)) * (float(p.x) - float(a.x))

func _on_segment(a: Vector2, b: Vector2, p: Vector2) -> bool:
	return _orientation(a, b, p) == 0. and p.x >= minf(a.x, b.x) and p.x <= maxf(a.x, b.x) and p.y >= minf(a.y, b.y) and p.y <= maxf(a.y, b.y)

func _segments_touch(a: Vector2, b: Vector2, c: Vector2, d: Vector2) -> bool:
	var ac: float = _orientation(a, b, c); var ad: float = _orientation(a, b, d)
	var ca: float = _orientation(c, d, a); var cb: float = _orientation(c, d, b)
	if ((ac > 0. and ad < 0.) or (ac < 0. and ad > 0.)) and ((ca > 0. and cb < 0.) or (ca < 0. and cb > 0.)): return true
	return (ac == 0. and _on_segment(a, b, c)) or (ad == 0. and _on_segment(a, b, d)) or (ca == 0. and _on_segment(c, d, a)) or (cb == 0. and _on_segment(c, d, b))

func _inside_closed(p: Vector2, polygon: PackedVector2Array) -> bool:
	var inside := false
	for i: int in polygon.size():
		var a: Vector2 = polygon[i]; var b: Vector2 = polygon[(i + 1) % polygon.size()]
		if _on_segment(a, b, p): return true
		if (a.y > p.y) != (b.y > p.y):
			var intersection: float = float(a.x) + (float(p.y) - float(a.y)) * (float(b.x) - float(a.x)) / (float(b.y) - float(a.y))
			if float(p.x) < intersection: inside = not inside
	return inside
