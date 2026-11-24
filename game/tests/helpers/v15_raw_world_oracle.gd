extends RefCounted
## Independent original-PNG oracle; never calls Field/WorldV15.safe_foot.
## Tile selection uses ONE global rounded coordinate, not per-tile resampling.
const WORLD_SIZE := Vector2(12288, 8192)
const CHUNK_SIZE := Vector2i(1536, 1024)
const VISUAL_MARGIN_PX := Vector2(18.432, 12.288)
const BLOCKER_MARGIN_PX := Vector2(64.512, 43.008)
var valid := false
var errors: Array[String] = []
var tiles: Dictionary = {}
var blockers: Array[Dictionary] = []
var cache: Dictionary = {}
var cache_fifo: Array[Vector2i] = []
var cache_limit := 6

func configure(layout: Resource) -> bool:
	valid = false
	errors.clear()
	tiles.clear()
	blockers.clear()
	cache.clear()
	cache_fifo.clear()
	if layout == null or int(layout.get("schema_version")) != 15 or Vector2i(layout.get("design_size")) != Vector2i(WORLD_SIZE):
		errors.append("missing or mismatched actual v15 layout")
		return false
	var entries: Array = layout.get("walkable_mask_tiles")
	if entries.size() != 64: errors.append("exact 64 native navigation chunks required")
	for entry: Dictionary in entries:
		var rect: Rect2 = entry.get("logical_rect", Rect2())
		var path: String = entry.get("path", "")
		var cell := Vector2i(roundi(rect.position.x / CHUNK_SIZE.x), roundi(rect.position.y / CHUNK_SIZE.y))
		var expected := Rect2(Vector2(cell * CHUNK_SIZE), Vector2(CHUNK_SIZE))
		if rect != expected or cell.x < 0 or cell.y < 0 or cell.x >= 8 or cell.y >= 8 or tiles.has(cell) or path.is_empty() or not FileAccess.file_exists(path):
			errors.append("invalid/duplicate/missing native navigation tile: " + str(cell))
		else:
			tiles[cell] = {"path": path, "rect": rect, "sha256": FileAccess.get_sha256(path)}
	for kind: String in ["visual_objects", "blockers"]:
		var rows: Array = layout.get(kind)
		for entry: Dictionary in rows:
			if kind == "visual_objects" and entry.has("solid_polygons_px"):
				var polygons: Variant = entry.get("solid_polygons_px")
				if not polygons is Array or polygons.is_empty():
					errors.append("empty/malformed exact solid polygon source: " + String(entry.get("id", "")))
					continue
				for polygon: Variant in polygons:
					if not polygon is PackedVector2Array or polygon.size() < 3:
						errors.append("invalid worldpixel polygon type/vertices")
						continue
					var bounds := Rect2(polygon[0], Vector2.ZERO)
					var area := 0.0
					for index in polygon.size():
						var point: Vector2 = polygon[index]
						var next: Vector2 = polygon[(index + 1) % polygon.size()]
						if not point.is_finite() or point.x < 0 or point.y < 0 or point.x > WORLD_SIZE.x or point.y > WORLD_SIZE.y: errors.append("solid polygon point outside actual canvas")
						bounds = bounds.expand(point)
						area += point.x * next.y - point.y * next.x
					if absf(area) <= .0001 or Geometry2D.triangulate_polygon(polygon).is_empty(): errors.append("degenerate/untriangulatable source solid polygon")
					blockers.append({"id": String(entry.get("id", "")), "kind": kind, "shape": "exact_world_polygon", "polygon": polygon, "grown": bounds})
				# Exact multiple solid polygons replace the old enclosing rectangle.
				# Their clear gaps/door passages are not closed with rectangle grow.
				continue
			if kind == "visual_objects" and not entry.has("collision_size"): continue
			var pos: Variant = entry.get("pos")
			var extent: Variant = entry.get("collision_size" if kind == "visual_objects" else "size")
			var offset: Variant = entry.get("collision_offset", Vector2.ZERO) if kind == "visual_objects" else Vector2.ZERO
			var margin: Variant = entry.get("walkability_margin_px", VISUAL_MARGIN_PX if kind == "visual_objects" else BLOCKER_MARGIN_PX)
			if not pos is Vector2 or not extent is Vector2 or not offset is Vector2 or not margin is Vector2:
				errors.append("non-vector collision source: " + String(entry.get("id", "")))
				continue
			var center: Vector2 = (pos + offset) * WORLD_SIZE
			var size: Vector2 = extent * WORLD_SIZE
			if not center.is_finite() or not size.is_finite() or not margin.is_finite() or size.x <= 0 or size.y <= 0 or margin.x < 0 or margin.y < 0:
				errors.append("invalid physical footprint: " + String(entry.get("id", "")))
				continue
			blockers.append({"id": String(entry.get("id", "")), "kind": kind, "solid": Rect2(center - size * .5, size), "grown": Rect2(center - size * .5 - margin, size + margin * 2)})
	valid = errors.is_empty() and tiles.size() == 64
	return valid

func samples(center: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array([center])
	for index in 16:
		var angle := TAU * float(index) / 16.0
		result.append(center + Vector2(cos(angle) * 10, sin(angle) * 6))
	return result

func _raw_tile(cell: Vector2i) -> Image:
	if cache.has(cell): return cache[cell]
	if not tiles.has(cell): return null
	var path: String = tiles[cell].path
	if FileAccess.get_sha256(path) != tiles[cell].sha256:
		errors.append("navigation file mutated during test: " + path)
		valid = false
		return null
	var image := Image.load_from_file(path)
	if image == null or image.is_empty() or image.get_size() != CHUNK_SIZE:
		errors.append("raw PNG decode/native size failure: " + path)
		valid = false
		return null
	if cache_fifo.size() >= cache_limit:
		cache.erase(cache_fifo.pop_front())
	cache_fifo.append(cell)
	cache[cell] = image
	return image

func pixel_evidence(point: Vector2) -> Dictionary:
	if not valid or not point.is_finite() or point.x < 0 or point.y < 0 or point.x >= WORLD_SIZE.x or point.y >= WORLD_SIZE.y:
		return {"clear": false, "kind": "invalid_or_outside", "point": [point.x, point.y]}
	var pixel := Vector2i(roundi(point.x / WORLD_SIZE.x * (WORLD_SIZE.x - 1)), roundi(point.y / WORLD_SIZE.y * (WORLD_SIZE.y - 1)))
	var cell := Vector2i(pixel.x / CHUNK_SIZE.x, pixel.y / CHUNK_SIZE.y)
	var image: Image = _raw_tile(cell)
	if image == null: return {"clear": false, "kind": "missing_raw_tile", "pixel": [pixel.x, pixel.y]}
	var local := pixel - cell * CHUNK_SIZE
	var color := image.get_pixelv(local)
	return {"clear": color.a >= .5 and maxf(color.r, maxf(color.g, color.b)) >= .5, "kind": "raw_nav", "point": [point.x, point.y], "pixel": [pixel.x, pixel.y], "chunk": [cell.x, cell.y], "rgba": [color.r, color.g, color.b, color.a], "path": tiles[cell].path, "sha256": tiles[cell].sha256}

func foot_evidence(center: Vector2) -> Dictionary:
	var shoes := samples(center)
	for index in shoes.size():
		var evidence := pixel_evidence(shoes[index])
		if not evidence.clear:
			evidence["shoe_index"] = index
			evidence["center"] = [center.x, center.y]
			return evidence
	for entry: Dictionary in blockers:
		var rect: Rect2 = entry.grown
		if rect.position.x > center.x + 10 or rect.end.x < center.x - 10 or rect.position.y > center.y + 6 or rect.end.y < center.y - 6: continue
		for index in shoes.size():
			var blocked: bool = Geometry2D.is_point_in_polygon(shoes[index], entry.polygon) if entry.get("shape") == "exact_world_polygon" else rect.has_point(shoes[index])
			if blocked:
				return {"clear": false, "kind": "source_collision", "shape": entry.get("shape", "grown_rectangle"), "id": entry.id, "shoe_index": index, "point": [shoes[index].x, shoes[index].y], "center": [center.x, center.y]}
	return {"clear": true, "kind": "full17", "center": [center.x, center.y]}

func clear(center: Vector2) -> bool:
	return bool(foot_evidence(center).clear)

func segment_evidence(from: Vector2, to: Vector2) -> Dictionary:
	var steps := maxi(1, ceili(from.distance_to(to) / 4.0))
	for index in range(steps + 1):
		var point := from.lerp(to, float(index) / steps)
		var evidence := foot_evidence(point)
		if not evidence.clear:
			evidence["segment_index"] = index
			evidence["segment_steps"] = steps
			return evidence
	return {"clear": true, "centers": steps + 1, "max_step_px": from.distance_to(to) / steps}

func release() -> void:
	cache.clear()
	cache_fifo.clear()
	tiles.clear()
	blockers.clear()
	valid = false
