extends RefCounted
## Read-only, fail-closed evidence gate. A same-sized stale image is not a
## captured candidate. This gate never writes owner evidence or root approval.
const C = preload("res://scripts/world/world_map_v15_contract.gd")
const ROOT := "res://art/maps/world_map_v15/"
const REVIEW := "res://data/maps/world_map_v15_visual_review.json"
const CORE_IDS := ["huashan", "luoyang", "bianzhou", "gufeng", "wudang", "xiangzhou", "jinling", "lingyue"]
const ROLES := ["source_script", "builder_script", "surface_script", "selector_script", "terrain_shader", "height_rf", "landmark_semantics", "camera_contract"]

static func validate(source: Dictionary, manifest: Dictionary) -> String:
	var catalog: Variant = manifest.get("asset_sha256")
	if not catalog is Dictionary or catalog.is_empty(): return "Missing actual asset SHA catalog"
	for path: Variant in catalog:
		if not path is String or not _asset_path(path) or not _hash(catalog[path]) or not FileAccess.file_exists(path): return "Invalid catalog path/SHA " + str(path)
		if FileAccess.get_sha256(path).to_lower() != String(catalog[path]).to_lower(): return "Changed actual bytes " + path
	for path: String in [C.SOURCE_PATH, ROOT + "landmark_semantics.json", String(source.get("overview_path", ""))]:
		if not _bound(catalog, path): return "Unbound mandatory source/overview " + path
	for path: String in _all_art(ROOT):
		if not _bound(catalog, path): return "Uncatalogued v15 art output " + path
	var graph: Variant = manifest.get("source_graph")
	if not graph is Dictionary or graph.is_empty(): return "Missing executed source graph"
	for path: Variant in graph:
		if not path is String or not _bound(catalog, path) or not _same_hash(graph[path], catalog[path]): return "Source graph/catalog mismatch " + str(path)
		if String(path).get_extension() in ["gd", "gdshader"]:
			var dependency_error := _literal_dependencies(String(path), graph, catalog)
			if not dependency_error.is_empty(): return dependency_error
	var capture: Variant = manifest.get("capture_graph")
	if not capture is Dictionary: return "Missing current capture graph"
	for role: String in ROLES:
		var record: Variant = capture.get(role)
		if not record is Dictionary or not _bound(catalog, String(record.get("path", ""))) or not _same_hash(record.get("sha256"), catalog.get(record.get("path"))): return "Unbound capture role " + role
		if not graph.has(record.path): return "Capture role absent from executed graph " + role
	if capture.source_script.path != "res://scripts/dev/world_map_v15_source.gd" or not String(capture.builder_script.path).begins_with("res://scripts/dev/"):
		return "Capture is not the independent executed v15 source"
	var geometry: Variant = source.get("geometry")
	if not geometry is Dictionary or not _pair_eq(geometry.get("grid_size"), Vector2(1537, 1025)) or not _num(geometry.get("grid_step_px"), 8): return "Wrong global native height lattice"
	var chunks_error := _chunks(source, manifest, catalog, capture)
	if not chunks_error.is_empty(): return chunks_error
	var portals_error := _portals(source, catalog)
	if not portals_error.is_empty(): return portals_error
	var spacing_error := _spacing(source)
	if not spacing_error.is_empty(): return spacing_error
	var routes_error := _routes(source)
	if not routes_error.is_empty(): return routes_error
	return _review(source, manifest, catalog)

static func _chunks(source: Dictionary, manifest: Dictionary, catalog: Dictionary, graph: Dictionary) -> String:
	var source_chunks: Variant = source.get("chunks")
	var captured_chunks: Variant = manifest.get("chunks")
	if not source_chunks is Array or not captured_chunks is Array or source_chunks.size() != 64 or captured_chunks.size() != 64: return "Exactly 64 source and actual capture chunks required"
	var ids: Dictionary = {}
	for raw: Variant in captured_chunks:
		if not raw is Dictionary: return "Malformed chunk evidence"
		var id := String(raw.get("id", ""))
		var row := int(raw.get("row", -1))
		var col := int(raw.get("col", -1))
		if row < 0 or row > 7 or col < 0 or col > 7 or id != "r%d_c%d" % [row, col] or ids.has(id): return "Duplicate/outside chunk " + id
		ids[id] = true
		var expected := [col * 1536, row * 1024, 1536, 1024]
		if not _rect_eq(raw.get("logical_rect_px"), expected): return "Wrong actual chunk rect " + id
		var authored: Dictionary = {}
		for entry: Variant in source_chunks:
			if entry is Dictionary and String(entry.get("id", "")) == id:
				if not authored.is_empty(): return "Duplicate source chunk " + id
				authored = entry
		if authored.is_empty() or not _rect_eq(authored.get("logical_rect_px"), expected): return "Missing exact source chunk " + id
		for kind: String in ["visual", "land", "raw_walk", "walk"]:
			var key := kind + "_path"
			var path := ROOT + "chunks/" + id + "_" + kind + ".png"
			if raw.get(key) != path or authored.get(key) != path or not _bound(catalog, path) or not _png_size(path, C.TILE_SIZE): return "Missing/broken native chunk artifact " + path
		if not _imported_authority_current(String(raw.walk_path)): return "Missing/stale imported authoritative walk pixels " + id + "; strict import current PNGs before publishing"
		var evidence: Variant = raw.get("capture")
		if not evidence is Dictionary: return "Missing actual capture " + id
		if not _rect_eq(evidence.get("logical_rect_px"), expected) or not _pair_eq(evidence.get("actual_logical_canvas"), Vector2(C.TILE_SIZE)) or not _pair(evidence.get("actual_native_canvas")) or not _num(evidence.get("ssaa_scale"), 2): return "Wrong actual capture canvas " + id
		if not _true(evidence.get("raw_repeat_exact")) or not _true(evidence.get("derived_repeat_exact")) or not _num(evidence.get("land_nav_msaa_enum"), 0) or not _false(evidence.get("land_nav_resized")): return "Non-authoritative/reproducible capture " + id
		if not _same_hash(evidence.get("rf_sha256"), graph.height_rf.sha256) or not _same_hash(evidence.get("shader_sha256"), graph.terrain_shader.sha256): return "Capture height/shader differs from current graph " + id
		if not _pair(evidence.get("height_source_grid_origin")) or not _pair(evidence.get("height_source_grid_size")) or not _quad(evidence.get("geometry_source_window_px")) or not _camera(evidence.get("actual_camera")): return "Missing measured native geometry/camera " + id
		var mesh_path := String(evidence.get("terrain_mesh_path", ""))
		if not _bound(catalog, mesh_path) or not _same_hash(evidence.get("terrain_mesh_sha256"), catalog.get(mesh_path)): return "Unbound actual terrain mesh " + id
		var output_hashes: Variant = evidence.get("outputs_sha256")
		if not output_hashes is Dictionary: return "Missing actual outputs hashes " + id
		for kind: String in ["visual", "land", "raw_walk", "walk"]:
			var path := String(raw[kind + "_path"])
			if not _same_hash(output_hashes.get(path), catalog[path]): return "Capture output/catalog SHA mismatch " + path
	return ""

static func _portals(source: Dictionary, catalog: Dictionary) -> String:
	var semantics := C.read_json(ROOT + "landmark_semantics.json")
	var records: Variant = semantics.get("landmarks")
	if not records is Dictionary: return "Missing measured landmark semantics"
	var portals: Variant = source.get("portals")
	var objects: Variant = source.get("objects")
	if not portals is Array or portals.size() != 16 or not objects is Array: return "Incomplete entity/doorway contract"
	for object: Variant in objects:
		if not object is Dictionary: return "Malformed independent object"
		if not _pair(object.get("pos")) or not _pair(object.get("render_size_px")) or not _positive(object.render_size_px[0]) or not _positive(object.render_size_px[1]): return "Invalid actual object render transform"
		var texture := String(object.get("texture", ""))
		if not texture.begins_with(ROOT) or not _bound(catalog, texture): return "Unbound actual object texture " + texture
		if not object.has("solid_polygons_px"): continue
		if not object.solid_polygons_px is Array or object.solid_polygons_px.is_empty(): return "Missing measured multi-solid geometry " + String(object.get("id", ""))
		for polygon: Variant in object.solid_polygons_px:
			if not _polygon(polygon): return "Invalid measured solid polygon " + String(object.get("id", ""))
			for point: Array in polygon:
				if point[0] < 0 or point[1] < 0 or point[0] >= C.SIZE.x or point[1] >= C.SIZE.y: return "Solid outside world " + String(object.get("id", ""))
	for raw: Variant in portals:
		if not raw is Dictionary: return "Invalid doorway record"
		var id := String(raw.get("id", ""))
		var measured: Variant = records.get(id)
		if not measured is Dictionary or measured.get("status") != "MEASURED_ACTUAL_SOURCE": return "Not an actual measured doorway " + id
		var original := String(raw.get("source", ""))
		if not _bound(catalog, original) or not _same_hash(raw.get("source_sha256"), catalog[original]) or measured.get("source") != original or not _same_hash(measured.get("source_sha256"), catalog[original]): return "Stale measured original source " + id
		if not _pair(raw.get("source_doorstep_uv")) or raw.source_doorstep_uv != measured.get("source_doorstep_uv") or not _pair(raw.get("door_foot_px")) or not _pair(raw.get("source_XZ_foot_px")): return "Doorway/source measurement mismatch " + id
		var uv := Vector2(float(raw.source_doorstep_uv[0]), float(raw.source_doorstep_uv[1]))
		if uv.x < 0 or uv.y < 0 or uv.x > 1 or uv.y > 1: return "Outside source doorway UV " + id
		if not _polygon(raw.get("interaction_polygon_px")) or not _polygon(raw.get("passage_polygon_px")) or not _pair(raw.get("approach_direction")): return "Missing actual doorway passage " + id
		if raw.get("auto_trigger", false) != false: return "V15 doorway must use explicit player interaction " + id
		var approach := Vector2(float(raw.approach_direction[0]), float(raw.approach_direction[1]))
		if not is_equal_approx(approach.length(), 1.0): return "Undefined doorway approach direction " + id
		var path: Variant = raw.get("passage_path_px")
		if not path is Array or path.size() < 2: return "Missing actual full-foot passage path " + id
		var has_door := false
		for point: Variant in path:
			if not _pair(point): return "Nonfinite actual passage path " + id
			if point == raw.door_foot_px: has_door = true
		if not has_door: return "Passage path misses actual visible doorway " + id
		var compound := String(raw.get("compound_id", ""))
		var found := false
		for object: Variant in objects:
			if not object is Dictionary or object.get("id") != compound: continue
			if found: return "Duplicate doorway compound " + id
			found = true
			var runtime := String(object.get("texture", ""))
			if not runtime.begins_with(ROOT + "entities/") or not _bound(catalog, runtime) or not _same_hash(catalog[runtime], catalog[original]) or not _same_hash(object.get("source_sha256"), catalog[original]): return "Runtime original-alpha copy differs " + id
			if object.get("foot_uv") != raw.source_doorstep_uv: return "Runtime foot is not measured visible doorway " + id
			if not object.has("solid_polygons_px"): return "Doorway compound has no measured solids " + id
			if not _true(object.get("sort_by_feet")) or object.get("centered", true) != true or not _num(object.get("rotation", 0), 0): return "Compound render does not match measured centered/Y-sorted contract " + id
			var center := Vector2(float(object.pos[0]), float(object.pos[1])) * C.SIZE
			var render_size := Vector2(float(object.render_size_px[0]), float(object.render_size_px[1]))
			var expected_foot := center + (uv - Vector2(.5, .5)) * render_size
			var door := Vector2(float(raw.door_foot_px[0]), float(raw.door_foot_px[1]))
			if expected_foot.distance_to(door) > .01: return "Doorway is not the actual source-to-render transform " + id
			if not _num(object.get("depth_sort_foot_y"), door.y / C.SIZE.y): return "Compound depth line is not actual visible foot " + id
		if not found: return "Missing independent doorway compound " + id
	return ""

static func _literal_dependencies(path: String, graph: Dictionary, catalog: Dictionary) -> String:
	# Close literal preload/shader/material dependencies as well as the owner's
	# declared graph. Missing declared input files are not silently accepted.
	var expression := RegEx.new()
	if expression.compile("['\"](res://[^'\"]+)['\"]") != OK: return "Cannot validate executed source dependencies"
	for match: RegExMatch in expression.search_all(FileAccess.get_file_as_string(path)):
		var dependency := match.get_string(1)
		if dependency.get_extension() not in ["gd", "gdshader", "gltf", "glb", "png", "jpg", "jpeg", "tres"]: continue
		if dependency.begins_with("res://build/"): continue
		if not graph.has(dependency) or not _bound(catalog, dependency): return "Unbound executed literal dependency " + path + " -> " + dependency
	return ""

static func _spacing(source: Dictionary) -> String:
	var cores: Variant = source.get("core_landmarks")
	if not cores is Array or cores.size() != 8: return "Missing eight actual projected core positions"
	var ids: Array[String] = []
	for entry: Variant in cores:
		if not entry is Dictionary or String(entry.get("id", "")) not in CORE_IDS or String(entry.id) in ids or not _pair(entry.get("center_px")) or not _pair(entry.get("door_foot_px")): return "Invalid actual core position"
		ids.append(String(entry.id))
		var portal: Dictionary = {}
		for candidate: Dictionary in source.portals:
			if candidate.id == entry.id: portal = candidate
		if portal.is_empty() or portal.door_foot_px != entry.door_foot_px: return "Core spacing measured from different doorway " + String(entry.id)
	for i in cores.size():
		for j in range(i + 1, cores.size()):
			for key: String in ["center_px", "door_foot_px"]:
				var a := Vector2(float(cores[i][key][0]), float(cores[i][key][1]))
				var b := Vector2(float(cores[j][key][0]), float(cores[j][key][1]))
				if a.distance_to(b) < 3072: return "Actual core spacing < 3072px " + String(cores[i].id) + "/" + String(cores[j].id)
	return ""

static func _routes(source: Dictionary) -> String:
	var routes: Variant = source.get("routes")
	if not routes is Array or routes.is_empty(): return "Missing unambiguous actual route network"
	var ids: Dictionary = {}
	for route: Variant in routes:
		if not route is Dictionary: return "Malformed route"
		var id := String(route.get("id", ""))
		var points: Variant = route.get("points_px")
		if id.is_empty() or ids.has(id) or not points is Array or points.size() < 2 or not _positive(route.get("width_px")): return "Invalid/duplicate route " + id
		ids[id] = true
		for point: Variant in points:
			if not _pair(point): return "Nonfinite route point " + id
	return ""

static func _review(source: Dictionary, _manifest: Dictionary, catalog: Dictionary) -> String:
	var review := C.read_json(REVIEW)
	if not _num(review.get("version"), 15) or review.get("reviewer_role") != "producer/root" or review.get("review_method") != "actual_png_individual_review" or not _true(review.get("visual_approved")) or String(review.get("reviewer", "")).strip_edges().is_empty(): return "Independent producer actual-image review absent"
	if not _same_hash(review.get("source_sha256"), FileAccess.get_sha256(C.SOURCE_PATH)) or not _same_hash(review.get("manifest_sha256"), FileAccess.get_sha256(C.MANIFEST_PATH)): return "Producer review does not bind current source/manifest"
	var images: Variant = review.get("reviewed_assets_sha256")
	if not images is Dictionary: return "Missing individual reviewed image hashes"
	var required: Array[String] = [String(source.overview_path)]
	for chunk: Dictionary in source.chunks: required.append(String(chunk.visual_path))
	for object: Dictionary in source.objects: required.append(String(object.get("texture", "")))
	for portal: Dictionary in source.portals:
		if portal.get("doorstep_visual_review_status") != "APPROVED": return "Unreviewed doorway " + String(portal.id)
		var image := String(portal.get("doorstep_review_image_path", ""))
		if not _bound(catalog, image) or not _same_hash(portal.get("doorstep_review_image_sha256"), catalog[image]): return "Stale actual doorway review image " + String(portal.id)
		required.append(image)
	for path: String in required:
		if not _bound(catalog, path) or not _same_hash(images.get(path), catalog[path]): return "Producer has not reviewed current image " + path
	return ""

static func _all_art(directory: String) -> Array[String]:
	var result: Array[String] = []
	var access := DirAccess.open(directory)
	if access == null: return result
	for file: String in access.get_files():
		if file.get_extension().to_lower() in ["png", "jpg", "jpeg", "rf", "gltf", "glb", "bin", "gdshader"]: result.append(directory.path_join(file))
	for subdir: String in access.get_directories(): result.append_array(_all_art(directory.path_join(subdir)))
	return result

static func _asset_path(value: String) -> bool:
	return value.begins_with("res://") and not ".." in value and not value.ends_with(".import") and value != C.MANIFEST_PATH and value != REVIEW

static func _hash(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for c: String in value.to_lower():
		if not c in "0123456789abcdef": return false
	return true

static func _same_hash(a: Variant, b: Variant) -> bool:
	return _hash(a) and _hash(b) and String(a).to_lower() == String(b).to_lower()

static func _bound(catalog: Dictionary, path: String) -> bool:
	return _asset_path(path) and _hash(catalog.get(path)) and FileAccess.file_exists(path)

static func _num(value: Variant, expected: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == expected

static func _positive(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) > 0

static func _true(value: Variant) -> bool: return typeof(value) == TYPE_BOOL and value == true
static func _false(value: Variant) -> bool: return typeof(value) == TYPE_BOOL and value == false

static func _pair(value: Variant) -> bool:
	return value is Array and value.size() == 2 and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value[0])) and is_finite(float(value[1]))

static func _pair_eq(value: Variant, expected: Vector2) -> bool: return _pair(value) and _num(value[0], expected.x) and _num(value[1], expected.y)

static func _quad(value: Variant) -> bool:
	if not value is Array or value.size() != 4: return false
	for element: Variant in value:
		if not typeof(element) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(element)): return false
	return true

static func _rect_eq(value: Variant, expected: Array) -> bool:
	if not _quad(value): return false
	for i in 4:
		if not _num(value[i], expected[i]): return false
	return true

static func _polygon(value: Variant) -> bool:
	if not value is Array or value.size() < 3: return false
	var points := PackedVector2Array()
	for point: Variant in value:
		if not _pair(point): return false
		points.append(Vector2(float(point[0]), float(point[1])))
	return not Geometry2D.triangulate_polygon(points).is_empty()

static func _camera(value: Variant) -> bool:
	if not value is Dictionary or not _num(value.get("projection"), Camera3D.PROJECTION_ORTHOGONAL) or not _positive(value.get("size")): return false
	var position: Variant = value.get("position")
	var basis: Variant = value.get("basis_columns")
	if not position is Array or position.size() != 3 or not basis is Array or basis.size() != 3: return false
	for row: Variant in [position, basis[0], basis[1], basis[2]]:
		if not row is Array or row.size() != 3: return false
		for component: Variant in row:
			if not typeof(component) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(component)): return false
	return true

static func _png_size(path: String, expected: Vector2i) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 24 or file.get_buffer(8) != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]): return false
	file.big_endian = true
	return file.get_32() == 13 and file.get_buffer(4).get_string_from_ascii() == "IHDR" and file.get_32() == expected.x and file.get_32() == expected.y

static func _imported_authority_current(path: String) -> bool:
	# Raw SHA validation alone cannot catch a stale same-path .ctex import.
	# Compare the authoritative base level, retaining RGB and alpha, without
	# retaining all 64 decoded masks or modifying any importer settings.
	if not FileAccess.file_exists(path + ".import") or not ResourceLoader.exists(path): return false
	var texture := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if texture == null: return false
	var imported := texture.get_image()
	var raw := Image.load_from_file(path)
	if imported == null or raw == null or imported.get_size() != C.TILE_SIZE or raw.get_size() != C.TILE_SIZE: return false
	if imported.is_compressed() and imported.decompress() != OK: return false
	if raw.is_compressed() and raw.decompress() != OK: return false
	imported.convert(Image.FORMAT_RGBA8)
	raw.convert(Image.FORMAT_RGBA8)
	var base_bytes := C.TILE_SIZE.x * C.TILE_SIZE.y * 4
	return imported.get_data().slice(0, base_bytes) == raw.get_data().slice(0, base_bytes)
