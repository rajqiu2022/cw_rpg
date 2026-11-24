extends RefCounted
## Independent ordinary-field PNG/physical source oracle, not WorldV15.safe_foot
## or Field clearance. Newly authored 3 fields may have their own logical size.
var valid := false
var errors: Array[String] = []
var size := Vector2.ZERO
var layers: Array[Dictionary] = []
var solids: Array[Dictionary] = []
var regions: Array[PackedVector2Array] = []
var sampling := "normalized_image_round"
var physical_margin_override := -1.0

func configure(layout: Resource, pixel_sampling := "normalized_image_round", margin_px := -1.0) -> bool:
	release()
	errors.clear()
	sampling = pixel_sampling
	physical_margin_override = margin_px
	if sampling not in ["normalized_image_round", "round_world_pixel"] or (margin_px < 0 and margin_px != -1):
		errors.append("unknown independent pixel/margin contract")
		return false
	if layout == null:
		errors.append("missing actual field layout")
		return false
	size = Vector2(layout.get("design_size"))
	if not size.is_finite() or size.x <= 0 or size.y <= 0:
		errors.append("invalid actual logical field size")
		return false
	var tiles: Array = layout.get("walkable_mask_tiles")
	if tiles.is_empty():
		var path: String = layout.get("walkable_mask_path")
		if path.is_empty() and sampling == "normalized_image_round":
			# Actual legacy source scenes declare polygon-only navigation. This
			# is not a fallback for missing/broken PNGs, and never applies to the
			# three native round_world_pixel fields requiring captured PNGs.
			for polygon: PackedVector2Array in layout.get("walkable_regions"):
				if polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty():
					errors.append("invalid original legacy walkable polygon")
					continue
				var finite_normalized := true
				for point: Vector2 in polygon:
					if not point.is_finite() or point.x < 0 or point.y < 0 or point.x > 1 or point.y > 1: finite_normalized = false
				if not finite_normalized:
					errors.append("original legacy walkable polygon outside normalized source domain")
					continue
				regions.append(polygon.duplicate())
			if regions.is_empty(): errors.append("legacy declares neither original navigation PNG nor valid polygon regions")
		else:
			_read_layer(path, Rect2(Vector2.ZERO, size), false)
	else:
		for entry: Dictionary in tiles:
			_read_layer(String(entry.get("path", "")), entry.get("logical_rect", Rect2()), true)
		# Native tile regions must form a complete disjoint source canvas; a
		# missing black gap is not silently accepted as a smaller playable map.
		var covered := 0.0
		for index in layers.size():
			var rect: Rect2 = layers[index].rect
			covered += rect.size.x * rect.size.y
			for other in range(index):
				if rect.intersects(layers[other].rect): errors.append("overlapping native field navigation tiles")
		if covered != size.x * size.y: errors.append("incomplete native tiled navigation canvas")
	for kind: String in ["visual_objects", "blockers"]:
		for entry: Dictionary in layout.get(kind):
			if kind == "visual_objects" and entry.has("solid_polygons_px"):
				var polygons: Variant = entry.get("solid_polygons_px")
				if not polygons is Array or polygons.is_empty():
					errors.append("malformed exact solid polygon source")
					continue
				for polygon: Variant in polygons:
					if not polygon is PackedVector2Array or polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty():
						errors.append("invalid exact polygon source")
						continue
					for point: Vector2 in polygon:
						if not point.is_finite() or point.x < 0 or point.y < 0 or point.x > size.x or point.y > size.y: errors.append("polygon source outside field canvas")
					solids.append({"id": entry.get("id", ""), "kind": "exact_world_polygon", "polygon": polygon})
				continue
			if kind == "visual_objects" and not entry.has("collision_size"): continue
			var center: Vector2 = (entry.get("pos", Vector2(INF, INF)) + entry.get("collision_offset", Vector2.ZERO)) * size
			var extent: Vector2 = entry.get("collision_size" if kind == "visual_objects" else "size", Vector2.ZERO) * size
			var margin: Vector2 = entry.get("walkability_margin_px", size * (.004 if kind == "visual_objects" else .014))
			if physical_margin_override >= 0: margin = Vector2.ONE * physical_margin_override
			if not center.is_finite() or not extent.is_finite() or not margin.is_finite() or extent.x <= 0 or extent.y <= 0 or margin.x < 0 or margin.y < 0:
				errors.append("invalid physical source rectangle")
				continue
			solids.append({"id": entry.get("id", ""), "kind": "grown_rectangle", "rect": Rect2(center - extent * .5 - margin, extent + margin * 2)})
	valid = errors.is_empty() and (not layers.is_empty() or not regions.is_empty())
	return valid

func _read_layer(path: String, rect: Rect2, native_tile: bool) -> void:
	if path.is_empty() or not FileAccess.file_exists(path) or rect.size.x <= 0 or rect.size.y <= 0 or not Rect2(Vector2.ZERO, size).encloses(rect):
		errors.append("missing/outside actual field PNG and logical_rect: " + path)
		return
	var image: Image = Image.load_from_file(path)
	if image == null or image.is_empty():
		errors.append("original field PNG decode failed: " + path)
		return
	if native_tile and (Vector2(image.get_size()) != rect.size or rect.position != Vector2(Vector2i(rect.position))):
		errors.append("native tile must have integral one-source-pixel logical mapping")
		return
	if sampling == "round_world_pixel" and Vector2(image.get_size()) != rect.size:
		errors.append("direct-world round requires one original pixel per logical pixel")
		return
	layers.append({"path": path, "sha256": FileAccess.get_sha256(path), "rect": rect, "image": image, "native_tile": native_tile})

func samples(center: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array([center])
	for index in 16:
		var angle: float = TAU * index / 16
		points.append(center + Vector2(cos(angle) * 10, sin(angle) * 6))
	return points

func pixel_evidence(point: Vector2) -> Dictionary:
	if not valid or not point.is_finite() or point.x < 0 or point.y < 0 or point.x >= size.x or point.y >= size.y:
		return {"clear": false, "kind": "invalid_or_outside"}
	if not regions.is_empty():
		var normalized: Vector2 = point / size
		for index in regions.size():
			if Geometry2D.is_point_in_polygon(normalized, regions[index]): return {"clear": true, "kind": "original_legacy_polygon", "region_index": index, "normalized_point": [normalized.x, normalized.y]}
		return {"clear": false, "kind": "outside_original_legacy_polygons", "normalized_point": [normalized.x, normalized.y]}
	# The original logical domain check above rejects out-of-map shoes first.
	# In the final half pixel a valid point rounds to size; the native nearest
	# sample is the last real texel, not an additional nonexistent source pixel.
	var global_pixel := Vector2i(clampi(roundi(point.x), 0, int(size.x) - 1), clampi(roundi(point.y), 0, int(size.y) - 1)) if sampling == "round_world_pixel" else Vector2i(roundi(point.x / size.x * (size.x - 1)), roundi(point.y / size.y * (size.y - 1)))
	if global_pixel.x < 0 or global_pixel.y < 0 or global_pixel.x >= size.x or global_pixel.y >= size.y: return {"clear": false, "kind": "rounded_pixel_outside"}
	for layer: Dictionary in layers:
		var rect: Rect2 = layer.rect
		var native: bool = layer.native_tile
		if not rect.has_point(Vector2(global_pixel) if native else point): continue
		var image: Image = layer.image
		var uv: Vector2 = (point - rect.position) / rect.size
		var pixel: Vector2i = global_pixel - Vector2i(rect.position) if native or sampling == "round_world_pixel" else Vector2i(roundi(uv.x * (image.get_width() - 1)), roundi(uv.y * (image.get_height() - 1)))
		var color: Color = image.get_pixelv(pixel)
		return {"clear": color.a >= .5 and maxf(color.r, maxf(color.g, color.b)) >= .5, "kind": "raw_nav", "pixel": [pixel.x, pixel.y], "path": layer.path, "sha256": layer.sha256, "rgba": [color.r, color.g, color.b, color.a]}
	return {"clear": false, "kind": "uncovered_source_pixel"}

func verify_sources() -> bool:
	# The suite calls this before and after each actual phase. Do not hash a
	# multi-megabyte PNG per shoe/physics tick and pollute movement/perf timing.
	for layer: Dictionary in layers:
		if not FileAccess.file_exists(layer.path) or FileAccess.get_sha256(layer.path) != layer.sha256:
			errors.append("actual field PNG changed while tested: " + String(layer.path))
			valid = false
	return valid

func foot_evidence(center: Vector2) -> Dictionary:
	var shoes: PackedVector2Array = samples(center)
	for index in shoes.size():
		var record: Dictionary = pixel_evidence(shoes[index])
		if not bool(record.clear):
			record["shoe_index"] = index
			record["center"] = [center.x, center.y]
			return record
	for solid: Dictionary in solids:
		for index in shoes.size():
			var blocked: bool = Geometry2D.is_point_in_polygon(shoes[index], solid.polygon) if solid.kind == "exact_world_polygon" else (solid.rect as Rect2).has_point(shoes[index])
			if blocked: return {"clear": false, "kind": "source_collision", "solid_kind": solid.kind, "id": solid.id, "shoe_index": index, "point": [shoes[index].x, shoes[index].y]}
	return {"clear": true, "kind": "full17"}

func clear(center: Vector2) -> bool:
	return bool(foot_evidence(center).clear)

func segment(a: Vector2, b: Vector2) -> Dictionary:
	var steps: int = maxi(1, ceili(a.distance_to(b) / 4))
	for index in range(steps + 1):
		var point: Vector2 = a.lerp(b, float(index) / steps)
		var witness: Dictionary = foot_evidence(point)
		if not bool(witness.clear):
			witness["segment_index"] = index
			witness["point_px"] = [point.x, point.y]
			return witness
	return {"clear": true, "centers": steps + 1, "max_step_px": a.distance_to(b) / steps}

func release() -> void:
	layers.clear()
	solids.clear()
	regions.clear()
	size = Vector2.ZERO
	valid = false
