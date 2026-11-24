extends SceneTree
## Read-only source/native classification of the first production QA failures.
## No Field, GPU, mutation, artificial repair or assertion weakening.
const SIZE := Vector2(4608, 3072)
const CASES := {
	"west_north_south": Vector2(896.5759, 1156.974),
	"heartland_south": Vector2(2139.688, 2416.788),
	"east_port_landward": Vector2(4053.576, 1652.5),
	"east_south": Vector2(4006.326, 2596.679),
	"portal_bianzhou": Vector2(1092.069, 1355.792),
	"portal_jinling": Vector2(2314.306, 2660.810),
	"bailu_dock_access": Vector2(4210, 1749),
}
var heights := PackedFloat32Array()

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func _dense(points: Array) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for i in range(points.size() - 1):
		var a := _point(points[i])
		var b := _point(points[i + 1])
		var steps := maxi(1, ceili(a.distance_to(b) / 4))
		for j in steps: result.append(a.lerp(b, float(j) / steps))
	result.append(_point(points.back()))
	return result

func _bad_reason(foot: Vector2, layout: WalkableMapLayout, nav: Image) -> Dictionary:
	var mask := 0
	var hits: Dictionary = {}
	for i in range(17):
		var point := foot if i == 16 else foot + Vector2(cos(TAU * i / 16.0) * 10, sin(TAU * i / 16.0) * 6)
		var normal := point / SIZE
		var pixel := Vector2i(roundi(normal.x * (SIZE.x - 1)), roundi(normal.y * (SIZE.y - 1)))
		if not Rect2i(Vector2i.ZERO, nav.get_size()).has_point(pixel):
			mask += 1
			continue
		var value := nav.get_pixelv(pixel)
		if value.a < .5 or maxf(value.r, maxf(value.g, value.b)) < .5: mask += 1
		for d: Dictionary in layout.visual_objects:
			if not d.has("collision_size"): continue
			var center: Vector2 = d.get("pos", Vector2.ZERO) + d.get("collision_offset", Vector2.ZERO)
			var extent: Vector2 = d.collision_size
			if Rect2(center - extent * .5, extent).grow(.004).has_point(normal): hits[String(d.id)] = true
	return {"mask": mask, "entities": hits.keys()}

func _height(point: Vector2) -> float:
	var v := point / SIZE * Vector2(384, 256)
	var x := clampi(floori(v.x), 0, 383)
	var y := clampi(floori(v.y), 0, 255)
	var f := v - Vector2(x, y)
	return lerpf(lerpf(heights[y * 385 + x], heights[y * 385 + x + 1], f.x), lerpf(heights[(y + 1) * 385 + x], heights[(y + 1) * 385 + x + 1], f.x), f.y)

func _initialize() -> void:
	var scene := load("res://data/scenes/world_map_jianghu_v14.tres") as SceneScript
	if scene == null or scene.map_layout == null:
		printerr("Missing actual candidate; refuse diagnostic")
		quit(1)
		return
	var nav := Image.new()
	var land := Image.new()
	if nav.load(scene.map_layout.walkable_mask_path) != OK or land.load("res://art/maps/world_map_v14/land.png") != OK:
		quit(1)
		return
	var file := FileAccess.open("res://art/maps/world_map_v14/height_grid.rf", FileAccess.READ)
	heights = file.get_buffer(file.get_length()).to_float32_array()
	file.close()
	if heights.size() != 385 * 257:
		quit(1)
		return
	for id: String in CASES:
		var foot: Vector2 = CASES[id]
		var samples: Array[Vector2] = [foot]
		for i in range(16): samples.append(foot + Vector2(cos(TAU * i / 16.0) * 10, sin(TAU * i / 16.0) * 6))
		var mask_hits: Array = []
		var layout_hits: Dictionary = {}
		var physical_center_hits: Array = []
		for sample: Vector2 in samples:
			var normalized := sample / SIZE
			var pixel := Vector2i(roundi(normalized.x * (SIZE.x - 1)), roundi(normalized.y * (SIZE.y - 1)))
			var value := nav.get_pixelv(pixel)
			if value.a < .5 or maxf(value.r, maxf(value.g, value.b)) < .5:
				mask_hits.append({"foot_sample_px": [sample.x, sample.y], "actual_mask_pixel": [pixel.x, pixel.y], "natural_land": land.get_pixelv(pixel).r >= .5})
			for d: Dictionary in scene.map_layout.visual_objects:
				if not d.has("collision_size"): continue
				var center: Vector2 = d.get("pos", Vector2.ZERO) + d.get("collision_offset", Vector2.ZERO)
				var size: Vector2 = d.collision_size
				var rect := Rect2(center - size * .5, size)
				if rect.grow(.004).has_point(normalized):
					var name := String(d.get("id", ""))
					layout_hits[name] = int(layout_hits.get(name, 0)) + 1
				if sample == foot and Rect2(rect.position * SIZE, rect.size * SIZE).grow(5).has_point(foot): physical_center_hits.append(String(d.get("id")))
		var source := foot
		for repeat in range(20): source.y = foot.y + _height(source) * SIZE.y / 30 / sqrt(2.0)
		var height := _height(source)
		var gradient := Vector2((_height(source + Vector2(4, 0)) - _height(source - Vector2(4, 0))) / (8.0 * 45 / 4608), (_height(source + Vector2(0, 4)) - _height(source - Vector2(0, 4))) / (8.0 * 42.42640687 / 3072)).length()
		print("[V14FailureClassification] " + JSON.stringify({"route": id, "center_px": [foot.x, foot.y], "source_px": [source.x, source.y], "source_height_m": height, "source_gradient": gradient, "mask_rejected_samples": mask_hits, "layout_grown_fullfoot_entities": layout_hits, "physical_circle_radius5_center_overlap": physical_center_hits, "qualification": "physical circle-vs-rectangle AABB broadphase only; actual input stop tested in full suite, no invented physics PASS"}))
	for d: Dictionary in scene.map_layout.visual_objects:
		if not String(d.get("id")) in ["native_herb_2_1", "native_herb_3_2"]: continue
		var scalar := float(d.depth_sort_foot_y) * SIZE.y
		var vector_y := Vector2(0, scalar).y
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/maps/world_map_v14/entities/%s.json" % d.id))
		print("[V14BandSource] " + JSON.stringify({"id": d.id, "double_y": scalar, "Vector2_y": vector_y, "scalar_band": floori(scalar / 8), "Vector2_band": floori(vector_y / 8), "actual_source_meta_depth_y": meta.get("depth_y"), "actual_source_meta_world_foot": meta.get("world_foot")}))
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/maps/world_map_v14/source_contract.json"))
	for route: Dictionary in source.get("routes", []):
		if not CASES.has(String(route.id)): continue
		var points := _dense(route.points_px)
		var intervals: Array = []
		var current: Dictionary = {}
		var bad := 0
		for i in points.size():
			var reason := _bad_reason(points[i], scene.map_layout, nav)
			if int(reason.mask) > 0 or not reason.entities.is_empty():
				bad += 1
				if current.is_empty(): current = {"from_index": i, "from_px": [points[i].x, points[i].y], "count": 0, "mask_bad_centers": 0, "entities": {}}
				current["to_index"] = i
				current["to_px"] = [points[i].x, points[i].y]
				current["count"] += 1
				if int(reason.mask) > 0: current["mask_bad_centers"] += 1
				for name: String in reason.entities: current.entities[name] = true
			elif not current.is_empty():
				intervals.append(current)
				current = {}
		if not current.is_empty(): intervals.append(current)
		print("[V14FullRouteIntervals] " + JSON.stringify({"route": route.id, "samples": points.size(), "bad_centers": bad, "intervals": intervals}))
	var images: Dictionary = {}
	for entry: Dictionary in source.get("structure_entries", []):
		var raw: Array = entry.rect_px
		var deck := Rect2(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3]))
		var overlaps: Array = []
		var seen: Dictionary = {}
		for point: Vector2 in _dense(entry.passage_px):
			if not deck.has_point(point): continue
			for i in range(17):
				var foot := point if i == 16 else point + Vector2(cos(TAU * i / 16.0) * 10, sin(TAU * i / 16.0) * 6)
				for d: Dictionary in scene.map_layout.visual_objects:
					if not bool(d.get("sort_by_feet", false)) or not String(d.get("id", "")).begins_with("bridge_"): continue
					var path := String(d.texture)
					if not images.has(path):
						var image := Image.new()
						image.load(path)
						images[path] = image
					var image: Image = images[path]
					var center: Vector2 = d.pos * SIZE
					var size: Vector2 = d.render_size_px
					var uv := (foot - center) / size + Vector2(.5, .5)
					if uv.x < 0 or uv.y < 0 or uv.x >= 1 or uv.y >= 1: continue
					var pixel := Vector2i(uv * Vector2(image.get_size()))
					if image.get_pixelv(pixel).a <= .12: continue
					var key := String(d.id) + str(pixel)
					if seen.has(key): continue
					seen[key] = true
					overlaps.append({"entity": d.id, "texture": path, "source_pixel": [pixel.x, pixel.y], "world_foot_sample": [foot.x, foot.y], "depth_base_y": float(d.depth_sort_foot_y) * SIZE.y})
		print("[V14DeckForegroundSourceHits] " + JSON.stringify({"structure": entry.id, "actual_distinct_source_hits": overlaps}))
	quit(0)
