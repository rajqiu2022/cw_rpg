extends "res://tests/test_world_map_v14_production_20261002.gd"

# Read-only fourth-capture diagnosis. No Field, Router, gameplay or GPU is run.
var diagnosis: Dictionary = {"scope": "FOURTH_FROZEN_SOURCE_DIAGNOSTIC_NOT_RUNTIME_QA", "intervals": []}
var diagnostic_land: Image
var diagnostic_walk: Image

func _foot_clear(point: Vector2) -> bool:
	return _raw_foot_reason(world, point / WORLD_SIZE).is_empty()

func _world_planned_paths() -> void:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0,0,288,192)
	grid.cell_size = Vector2(16,16); grid.offset = Vector2(8,8)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER; grid.update()
	for y in 192:
		for x in 288:
			var id := Vector2i(x,y)
			grid.set_point_solid(id, not _foot_clear(grid.get_point_position(id)))
	var portal_points: Dictionary = {}
	for p: Dictionary in source_contract.portals: portal_points[String(p.id)] = _point(p.pos) * WORLD_SIZE
	var start: Vector2 = portal_points.bailu_ferry
	for id: String in ["zhuwei_village","qinghe_town"]:
		var finish: Vector2 = portal_points[id]
		var from := _nearest_grid_point(grid,start)
		var to := _nearest_grid_point(grid,finish)
		var path: Array = [start]
		for p in grid.get_point_path(from,to): path.append(p)
		path.append(finish)
		_intervals(world,"planned_bailu_to_"+id,path)

func _load_actual_geometry() -> void:
	var metadata := _json(ART_DIR + "geometry.json")
	terrain_cols = int(_point(metadata.get("height_grid_shape")).x) - 1
	terrain_rows = int(_point(metadata.get("height_grid_shape")).y) - 1
	var mesh := load(ART_DIR + "terrain_mesh.res") as ArrayMesh
	var arrays := mesh.surface_get_arrays(0)
	terrain_vertices = arrays[Mesh.ARRAY_VERTEX]
	terrain_uvs = arrays[Mesh.ARRAY_TEX_UV]
	terrain_indices = arrays[Mesh.ARRAY_INDEX]

func _evidence(scene: SceneScript, point: Vector2) -> Dictionary:
	var size := Vector2(scene.map_layout.design_size)
	var reason := _raw_foot_reason(scene, point / size)
	var evidence := {"point_px": [point.x, point.y], "reason": reason}
	if scene == world:
		var sample: Vector2 = reason.get("sample_px", point)
		var pixel := Vector2i(roundi(sample.x * (diagnostic_walk.get_width() - 1) / WORLD_SIZE.x), roundi(sample.y * (diagnostic_walk.get_height() - 1) / WORLD_SIZE.y))
		if pixel.x >= 0 and pixel.y >= 0 and pixel.x < diagnostic_walk.get_width() and pixel.y < diagnostic_walk.get_height():
			evidence["walk_r"] = diagnostic_walk.get_pixelv(pixel).r
			evidence["land_r"] = diagnostic_land.get_pixelv(pixel).r
		var source := sample
		for iteration in 12:
			var triangle := _actual_terrain_triangle(source)
			if triangle.is_empty(): break
			source.y = sample.y + float(triangle.height) * WORLD_SIZE.y / 30.0 / sqrt(2.0)
		var triangle := _actual_terrain_triangle(source)
		evidence["reconstructed_source_px"] = [source.x, source.y]
		evidence["actual_triangle"] = triangle
	return evidence

func _intervals(scene: SceneScript, label: String, points: Array) -> void:
	var dense := _dense_polyline(points)
	var bad := 0
	var current: Dictionary = {}
	for index in dense.size():
		var reason := _raw_foot_reason(scene, dense[index] / Vector2(scene.map_layout.design_size))
		if reason.is_empty():
			if not current.is_empty(): diagnosis.intervals.append(current); current = {}
			continue
		bad += 1
		var signature := String(reason.get("kind", "")) + ":" + String(reason.get("object_id", ""))
		if current.is_empty() or current.signature != signature:
			if not current.is_empty(): diagnosis.intervals.append(current)
			current = {"label": label, "signature": signature, "first_index": index, "last_index": index, "first": _evidence(scene, dense[index]), "last": _evidence(scene, dense[index]), "samples": []}
		current.last_index = index
		current.last = _evidence(scene, dense[index])
		current.samples.append(_evidence(scene, dense[index]))
	if not current.is_empty(): diagnosis.intervals.append(current)
	print("[FourthDiagnosis] %s centers=%d bad=%d" % [label, dense.size(), bad])

func _bailu_grid(spacing: int, mode: String = "all") -> void:
	var scene := load("res://data/scenes/openworld_bailu_ferry.tres") as SceneScript
	var size := Vector2(scene.map_layout.design_size)
	var oracle := _raw_oracle(scene)
	var saved_shapes: Array = oracle.shapes.duplicate()
	if mode != "all" and mode != "center_only":
		oracle.shapes = []
		for shape: Dictionary in saved_shapes:
			if String(shape.id) == mode: oracle.shapes.append(shape)
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(0, 0, int(size.x / spacing), int(size.y / spacing))
	grid.cell_size = Vector2(spacing, spacing)
	grid.offset = Vector2.ONE * spacing * .5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for y in grid.region.size.y:
		for x in grid.region.size.x:
			var id := Vector2i(x, y)
			var point := grid.get_point_position(id)
			var clear := _raw_foot_reason(scene, point / size).is_empty()
			if mode == "center_only":
				var uv := point / size
				var image: Image = oracle.mask
				var pixel := image.get_pixel(roundi(uv.x*(image.get_width()-1)), roundi(uv.y*(image.get_height()-1)))
				clear = pixel.r >= .5 and pixel.a >= .5
				for shape: Dictionary in saved_shapes:
					if (shape.rect as Rect2).has_point(uv): clear = false
			grid.set_point_solid(id, not clear)
	var start := Vector2(.42,.73) * size
	var finish := Vector2(.205, .075) * size
	var endpoints: Array[Vector2i] = []
	for target: Vector2 in [start, finish]:
		var best := Vector2i(-1, -1)
		var distance := INF
		var center := Vector2i((target - grid.offset) / grid.cell_size)
		for y in range(center.y - 10, center.y + 11):
			for x in range(center.x - 10, center.x + 11):
				var id := Vector2i(x, y)
				if not grid.is_in_boundsv(id) or grid.is_point_solid(id): continue
				var pixel := grid.get_point_position(id)
				if pixel.distance_squared_to(target) < distance:
					distance = pixel.distance_squared_to(target); best = id
		endpoints.append(best)
	var path := PackedVector2Array()
	if endpoints[0].x >= 0 and endpoints[1].x >= 0: path = grid.get_point_path(endpoints[0], endpoints[1])
	var record := {"spacing": spacing, "world_portal_target": start, "authored_default_spawn": scene.player_spawn * size, "exit": finish, "spawn_reason": _evidence(scene, start), "exit_reason": _evidence(scene, finish), "grid_endpoints": endpoints, "path_count": path.size(), "note": "Nearest clear grid nodes only; NOT a runtime entrance/return PASS"}
	record["mode"] = mode
	diagnosis["bailu_grid_%d_%s" % [spacing,mode]] = record
	print("[FourthBailu] ", record)
	oracle.shapes = saved_shapes
	if not path.is_empty(): _intervals(scene, "bailu_grid_%d_%s_against_real_all" % [spacing,mode], Array(path))

func _run() -> void:
	world = load(CANDIDATE_PATH) as SceneScript
	source_contract = _json(SOURCE_PATH)
	diagnostic_land = Image.load_from_file(ART_DIR + "land.png")
	diagnostic_walk = Image.load_from_file(ART_DIR + "walk.png")
	_load_actual_geometry()
	for route: Dictionary in source_contract.routes: _intervals(world, String(route.id), route.points_px)
	for entry: Dictionary in source_contract.structure_entries: _intervals(world, "structure_" + String(entry.object_id), entry.passage_px)
	for seam: Dictionary in source_contract.seams:
		if String(seam.id) != "horizontal_1_0": continue
		var closest := INF
		var path: Array = []
		for route: Dictionary in source_contract.routes:
			var dense := _dense_polyline(route.points_px)
			for i in dense.size():
				var distance := dense[i].distance_to(_point(seam.witness_px))
				if distance < closest:
					closest = distance; path = []
					for j in range(maxi(0, i - 13), mini(dense.size(), i + 14)): path.append(dense[j])
		_intervals(world, "seam_" + String(seam.id), path)
	_bailu_grid(16)
	_bailu_grid(8)
	for mode in ["mask_only","ferry_inn","central_office","open_river","center_only"]: _bailu_grid(8,mode)
	_world_planned_paths()
	var out := "res://build/world_map_v14_fourth_independent_diagnostic_%d.json" % int(Time.get_unix_time_from_system())
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify(diagnosis, "\t")); file.close()
	print("[FourthDiagnosis] output=", out, " intervals=", diagnosis.intervals.size(), " NO_FIELD_NO_GPU")
	quit(0)
