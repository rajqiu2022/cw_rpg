extends SceneTree

## Two-asset native authoring capture for the Luoyang gate candidate.
##
## Reads the frozen horizontal wall mesh and its embedded materials.  Asset A
## retains source surfaces 0..15, removes only the old tiled cap surfaces
## 16..17, and adds a crenellated parapet.  Asset B is a new square terminal
## tower made from real boxes with the same saved masonry materials.  No city
## scene, route, collision, water, NPC, portal or formal layout is loaded.

const RUN_FLAG := "--capture-luoyang-gate-native-fortification-v1"
const SOURCE_ROOT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s0_luoyang_gate/"
const SOURCE_MESH := SOURCE_ROOT + "entities/native_wall_horizontal.res"
const SOURCE_META := SOURCE_ROOT + "entities/native_wall_horizontal.json"
const SOURCE_CONTRACT := SOURCE_ROOT + "art_contract.json"
const SOURCE_CONTRACT_SHA := "2818f9fca10d30abbbbd386ff2b26a3d4ed87f300a9b8ef47f882bcb83f7640d"
const OUTPUT_ROOT := "res://art/modules/luoyang_gate_fortification_v1/"
const AUTHORING_CONTRACT := OUTPUT_ROOT + "source_contract.json"
const OUTPUTS := {
	"straight_mesh": OUTPUT_ROOT + "luoyang_gate_wall_crenellated_straight_v1.res",
	"straight_png": OUTPUT_ROOT + "luoyang_gate_wall_crenellated_straight_v1.png",
	"tower_mesh": OUTPUT_ROOT + "luoyang_gate_corner_tower_v1.res",
	"tower_png": OUTPUT_ROOT + "luoyang_gate_corner_tower_v1.png",
	"result": OUTPUT_ROOT + "capture_result.json",
}
const RAW_CANVAS := Vector2i(1536, 1536)
const CAMERA_BASIS_COLUMNS := [
	Vector3(1.0, 0.0, 0.0),
	Vector3(0.0, 0.866025447845459, -0.499999970197678),
	Vector3(0.0, 0.499999970197678, 0.866025447845459),
]
const CAMERA_POSITION := Vector3(0.0, 33.5999984741211, 55.4256248474121)
const BODY_ORIGIN := Vector3(0.0, 0.0, -0.34375)

var error := ""
var inputs_first: Dictionary = {}
var outputs: Dictionary = {}
var geometry: Dictionary = {}
var source_contract: Dictionary = {}
var viewport: SubViewport
var checkpoint_guard: Dictionary = {}


func _initialize() -> void:
	call_deferred("_start")


func _start() -> void:
	# First deferred action and strictly before the first await.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		_fail_now("Native authoring requires public checkpoint suspension; no fallback.")
		return
	bridge.call("set_checkpoint_saves_suspended", true)
	if bridge.call("is_checkpoint_saves_suspended") != true:
		_fail_now("Checkpoint suspension was not verified before authoring.")
		return
	checkpoint_guard = {
		"public_api": "PlatformBridge.set_checkpoint_saves_suspended(true)",
		"before_first_await": true,
		"verified_suspended": true,
		"restored_before_quit": false,
	}

	var args: PackedStringArray = OS.get_cmdline_user_args()
	var run_tag := ""
	for arg: String in args:
		if arg.begins_with("--capture-run-tag="):
			run_tag = arg.trim_prefix("--capture-run-tag=")
	var tag_rule := RegEx.new()
	if RUN_FLAG not in args or tag_rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or tag_rule.search(run_tag) == null:
		_fail_now("Explicit capture flag and a safe unique --capture-run-tag are required.")
		return
	if DisplayServer.get_name() == "headless":
		_fail_now("Transparent native GPU capture refuses a headless display server.")
		return
	for path: String in OUTPUTS.values():
		if FileAccess.file_exists(path):
			_fail_now("Refusing to overwrite an existing candidate output: " + path)
			return
	if not _track(get_script().resource_path) or not _track(AUTHORING_CONTRACT) or not _track(SOURCE_CONTRACT, SOURCE_CONTRACT_SHA) or not _track(SOURCE_META):
		_fail_now(error)
		return
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_CONTRACT))
	if not decoded is Dictionary or decoded.get("scene_id") != "ch4_s0_luoyang_gate":
		_fail_now("Exact frozen Luoyang gate art contract is required.")
		return
	source_contract = decoded
	if not _bound_resource(SOURCE_MESH):
		_fail_now(error)
		return
	var source_meta_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_META))
	if not source_meta_value is Dictionary:
		_fail_now("Native wall metadata is not a Dictionary.")
		return
	var source_meta: Dictionary = source_meta_value
	if String(source_meta.get("native_mesh_sha256", "")).to_lower() != inputs_first[SOURCE_MESH] or source_meta.get("actual_used_vertices", 0) != 9216:
		_fail_now("Native wall metadata does not bind the expected actual mesh.")
		return
	var source: ArrayMesh = ResourceLoader.load(SOURCE_MESH, "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if source == null or source.get_surface_count() != 18:
		_fail_now("Frozen native wall must load as the exact 18-surface ArrayMesh.")
		return
	for index in range(18):
		if source.surface_get_primitive_type(index) != Mesh.PRIMITIVE_TRIANGLES or source.surface_get_material(index) == null:
			_fail_now("Frozen native wall has a missing/nontriangle saved surface.")
			return

	var straight: ArrayMesh = _build_straight(source)
	var tower: ArrayMesh = _build_tower(source)
	if straight == null or tower == null or error != "":
		_fail_now(error if error != "" else "Native geometry build failed.")
		return
	var straight_measure: Dictionary = _measure(straight)
	var tower_measure: Dictionary = _measure(tower)
	if straight_measure.is_empty() or tower_measure.is_empty():
		_fail_now(error)
		return
	geometry["straight"] = straight_measure
	geometry["tower"] = tower_measure

	var straight_capture: Dictionary = await _capture(straight, "straight")
	if straight_capture.is_empty():
		await _finish(false, run_tag, bridge)
		return
	var tower_capture: Dictionary = await _capture(tower, "tower")
	if tower_capture.is_empty():
		await _finish(false, run_tag, bridge)
		return
	geometry["straight_capture"] = straight_capture
	geometry["tower_capture"] = tower_capture

	var straight_size := Vector2i(straight_capture.crop_size_px[0], straight_capture.crop_size_px[1])
	var tower_size := Vector2i(tower_capture.crop_size_px[0], tower_capture.crop_size_px[1])
	if straight_size.x < 580 or straight_size.x > 730 or straight_size.y < 220 or straight_size.y > 310:
		error = "Straight wall actual crop falls outside the authorized city-scale range."
		await _finish(false, run_tag, bridge)
		return
	if tower_size.x < 180 or tower_size.x > 390 or tower_size.y < 220 or tower_size.y > 340:
		error = "Corner tower actual crop falls outside the authorized terminal scale range."
		await _finish(false, run_tag, bridge)
		return
	var straight_image: Image = straight_capture["_verified_image"]
	var tower_image: Image = tower_capture["_verified_image"]
	straight_capture.erase("_verified_image")
	tower_capture.erase("_verified_image")
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_ROOT)) != OK:
		error = "Cannot create the isolated candidate asset directory."
		await _finish(false, run_tag, bridge)
		return
	if not _save_mesh(OUTPUTS.straight_mesh, straight, "A retained source surfaces 0..15; removed tiled cap 16..17; added one crenellation surface using source surface14 material"):
		await _finish(false, run_tag, bridge)
		return
	if not _save_mesh(OUTPUTS.tower_mesh, tower, "B new square terminal geometry; source surface14 masonry and surface15 cornice materials only"):
		await _finish(false, run_tag, bridge)
		return
	if not _save_png(OUTPUTS.straight_png, straight_image) or not _save_png(OUTPUTS.tower_png, tower_image):
		await _finish(false, run_tag, bridge)
		return
	await _finish(true, run_tag, bridge)


func _build_straight(source: ArrayMesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	# Preserve the real masonry/support/cornice arrays and materials byte-for-byte.
	for index in range(16):
		var arrays: Array = source.surface_get_arrays(index)
		result.add_surface_from_arrays(source.surface_get_primitive_type(index), arrays)
		result.surface_set_material(result.get_surface_count() - 1, source.surface_get_material(index))
	var bounds: AABB = source.get_aabb()
	var width: float = bounds.size.x
	var depth: float = bounds.size.z * 0.92
	var top: float = bounds.end.y
	var crenel_h: float = bounds.size.y * 0.18
	var parapet_h: float = crenel_h * 0.45
	var boxes: Array[Dictionary] = []
	boxes.append({
		"center": Vector3(bounds.get_center().x, top - crenel_h - parapet_h * 0.5, bounds.get_center().z),
		"size": Vector3(width, parapet_h, depth),
	})
	var count := 9
	var cell: float = width / float(count * 2 - 1)
	for i in range(count):
		boxes.append({
			"center": Vector3(bounds.position.x + cell * 0.5 + float(i) * cell * 2.0, top - crenel_h * 0.5, bounds.get_center().z),
			"size": Vector3(cell, crenel_h, depth),
		})
	var arrays: Array = _boxes_arrays(boxes)
	if arrays.is_empty():
		return null
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	result.surface_set_material(result.get_surface_count() - 1, source.surface_get_material(14))
	return result


func _build_tower(source: ArrayMesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	var bounds: AABB = source.get_aabb()
	var width: float = bounds.size.x * 0.34
	var depth: float = maxf(bounds.size.z * 2.4, width * 0.70)
	var bottom: float = bounds.position.y
	var top: float = bounds.end.y
	var crenel_h: float = bounds.size.y * 0.18
	var parapet_h: float = crenel_h * 0.45
	var body_top: float = top - crenel_h - parapet_h
	var pier_w: float = width * 0.12
	var body_boxes: Array[Dictionary] = [
		{"center": Vector3(0.0, (bottom + body_top) * 0.5, bounds.get_center().z), "size": Vector3(width, body_top - bottom, depth)},
		{"center": Vector3(-width * 0.5 + pier_w * 0.35, (bottom + body_top) * 0.5, bounds.get_center().z + depth * 0.025), "size": Vector3(pier_w, body_top - bottom, depth * 1.05)},
		{"center": Vector3(width * 0.5 - pier_w * 0.35, (bottom + body_top) * 0.5, bounds.get_center().z + depth * 0.025), "size": Vector3(pier_w, body_top - bottom, depth * 1.05)},
	]
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _boxes_arrays(body_boxes))
	result.surface_set_material(0, source.surface_get_material(14))
	var cornice_h: float = bounds.size.y * 0.055
	var cornice_boxes: Array[Dictionary] = [{
		"center": Vector3(0.0, body_top - cornice_h * 0.5, bounds.get_center().z),
		"size": Vector3(width * 1.06, cornice_h, depth * 1.06),
	}]
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _boxes_arrays(cornice_boxes))
	result.surface_set_material(1, source.surface_get_material(15))
	var battlement: Array[Dictionary] = [{
		"center": Vector3(0.0, top - crenel_h - parapet_h * 0.5, bounds.get_center().z),
		"size": Vector3(width * 1.03, parapet_h, depth * 1.03),
	}]
	var count := 5
	var cell: float = width / float(count * 2 - 1)
	for i in range(count):
		battlement.append({
			"center": Vector3(-width * 0.5 + cell * 0.5 + float(i) * cell * 2.0, top - crenel_h * 0.5, bounds.get_center().z),
			"size": Vector3(cell, crenel_h, depth * 1.03),
		})
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _boxes_arrays(battlement))
	result.surface_set_material(2, source.surface_get_material(14))
	return result


func _boxes_arrays(boxes: Array[Dictionary]) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for box: Dictionary in boxes:
		var center: Vector3 = box.center
		var half: Vector3 = box.size * 0.5
		if not center.is_finite() or not half.is_finite() or minf(half.x, minf(half.y, half.z)) <= 0.0:
			error = "Nonfinite or nonpositive authored box."
			return []
		var x0 := center.x - half.x
		var x1 := center.x + half.x
		var y0 := center.y - half.y
		var y1 := center.y + half.y
		var z0 := center.z - half.z
		var z1 := center.z + half.z
		# Clockwise when viewed from outside, matching the frozen source contract.
		_append_face(vertices, normals, tangents, uvs, colors, indices, [Vector3(x0,y0,z1),Vector3(x0,y1,z1),Vector3(x1,y1,z1),Vector3(x1,y0,z1)], Vector3.BACK)
		_append_face(vertices, normals, tangents, uvs, colors, indices, [Vector3(x1,y0,z0),Vector3(x1,y1,z0),Vector3(x0,y1,z0),Vector3(x0,y0,z0)], Vector3.FORWARD)
		_append_face(vertices, normals, tangents, uvs, colors, indices, [Vector3(x1,y0,z1),Vector3(x1,y1,z1),Vector3(x1,y1,z0),Vector3(x1,y0,z0)], Vector3.RIGHT)
		_append_face(vertices, normals, tangents, uvs, colors, indices, [Vector3(x0,y0,z0),Vector3(x0,y1,z0),Vector3(x0,y1,z1),Vector3(x0,y0,z1)], Vector3.LEFT)
		_append_face(vertices, normals, tangents, uvs, colors, indices, [Vector3(x0,y1,z1),Vector3(x0,y1,z0),Vector3(x1,y1,z0),Vector3(x1,y1,z1)], Vector3.UP)
		_append_face(vertices, normals, tangents, uvs, colors, indices, [Vector3(x0,y0,z0),Vector3(x0,y0,z1),Vector3(x1,y0,z1),Vector3(x1,y0,z0)], Vector3.DOWN)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


func _append_face(vertices: PackedVector3Array, normals: PackedVector3Array, tangents: PackedFloat32Array, uvs: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array, points: Array[Vector3], normal: Vector3) -> void:
	var base := vertices.size()
	var tangent: Vector3 = (points[3] - points[0]).normalized()
	if absf(tangent.dot(normal)) > 0.001:
		tangent = Vector3.RIGHT if absf(normal.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	var face_uv := [Vector2(0,1), Vector2(0,0), Vector2(1,0), Vector2(1,1)]
	for i in range(4):
		vertices.append(points[i])
		normals.append(normal)
		tangents.append_array(PackedFloat32Array([tangent.x, tangent.y, tangent.z, 1.0]))
		uvs.append(face_uv[i])
		colors.append(Color.WHITE)
	indices.append_array(PackedInt32Array([base,base+1,base+2,base,base+2,base+3]))


func _capture(mesh: ArrayMesh, label: String) -> Dictionary:
	viewport = SubViewport.new()
	viewport.size = RAW_CANVAS
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0,0,0,0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72,0.75,0.78)
	env.ambient_light_energy = 0.45
	environment.environment = env
	world.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-34,0)
	sun.light_energy = 0.85
	sun.shadow_enabled = false
	world.add_child(sun)
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.position = BODY_ORIGIN
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(body)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.0
	camera.near = 0.1
	camera.far = 160.0
	camera.transform = Transform3D(Basis(CAMERA_BASIS_COLUMNS[0],CAMERA_BASIS_COLUMNS[1],CAMERA_BASIS_COLUMNS[2]), CAMERA_POSITION)
	camera.current = true
	world.add_child(camera)
	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var first: Image = viewport.get_texture().get_image()
	first.convert(Image.FORMAT_RGBA8)
	for frame in range(2):
		await process_frame
	await RenderingServer.frame_post_draw
	var second: Image = viewport.get_texture().get_image()
	second.convert(Image.FORMAT_RGBA8)
	if first.get_data() != second.get_data():
		error = "GPU capture was not byte-repeatable for " + label
		return {}
	var used: Rect2i = first.get_used_rect()
	if used.size.x < 32 or used.size.y < 32 or used.position.x < 12 or used.position.y < 12 or used.end.x > RAW_CANVAS.x - 12 or used.end.y > RAW_CANVAS.y - 12:
		error = "Transparent capture empty or clipped for " + label
		return {}
	var crop := Rect2i(used.position - Vector2i(8,8), used.size + Vector2i(16,16))
	var cropped: Image = first.get_region(crop)
	var support: Dictionary = _project_support(mesh, body.transform, camera, crop)
	if support.is_empty():
		return {}
	var alpha_nonzero := 0
	var bytes: PackedByteArray = cropped.get_data()
	for i in range(3, bytes.size(), 4):
		if bytes[i] != 0:
			alpha_nonzero += 1
	viewport.queue_free()
	viewport = null
	for frame in range(2):
		await process_frame
	return {
		"_verified_image": cropped,
		"raw_canvas_px": [RAW_CANVAS.x,RAW_CANVAS.y],
		"actual_used_rect_px": [used.position.x,used.position.y,used.size.x,used.size.y],
		"actual_crop_rect_px": [crop.position.x,crop.position.y,crop.size.x,crop.size.y],
		"crop_size_px": [cropped.get_width(),cropped.get_height()],
		"nonzero_alpha_pixels": alpha_nonzero,
		"foot_uv": support.foot_uv,
		"foot_anchor_px": support.foot_anchor_px,
		"actual_min_y_support_polygon_px": support.actual_min_y_support_polygon_px,
		"same_asset_for_left_and_right_without_flip": label == "tower",
		"camera": {
			"projection": "orthogonal",
			"size_m": 12.0,
			"position_m": _v3(CAMERA_POSITION),
			"basis_columns": [_v3(CAMERA_BASIS_COLUMNS[0]),_v3(CAMERA_BASIS_COLUMNS[1]),_v3(CAMERA_BASIS_COLUMNS[2])],
			"ambient_energy": 0.45,
			"sun_energy": 0.85,
			"sun_euler_degrees": [-55,-34,0],
		},
	}


func _save_png(path: String, image: Image) -> bool:
	if not path.begins_with(OUTPUT_ROOT) or FileAccess.file_exists(path) or image.save_png(path) != OK:
		error = "Own NEW PNG save/overwrite refused: " + path
		return false
	var readback: Image = Image.load_from_file(path)
	if readback == null:
		error = "Captured PNG readback failed for " + path
		return false
	readback.convert(Image.FORMAT_RGBA8)
	if readback.get_size() != image.get_size() or readback.get_data() != image.get_data():
		error = "Captured PNG readback differs for " + path
		return false
	outputs[path] = {
		"sha256": FileAccess.get_sha256(path),
		"bytes": FileAccess.get_file_as_bytes(path).size(),
		"rgba_sha256": _hash(image.get_data()),
		"size_px": [image.get_width(), image.get_height()],
		"lossless_readback_exact": true,
	}
	return true


func _project_support(mesh: ArrayMesh, transform: Transform3D, camera: Camera3D, crop: Rect2i) -> Dictionary:
	var low := INF
	var vertices := PackedVector3Array()
	for surface in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface)
		if not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
			error = "Support projection requires actual vertices."
			return {}
		for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
			low = minf(low, vertex.y)
			vertices.append(vertex)
	var support_world := PackedVector3Array()
	for vertex: Vector3 in vertices:
		if vertex.y <= low + 0.00001:
			support_world.append(transform * vertex)
	if support_world.size() < 3:
		error = "Actual minimum-Y support set is too small."
		return {}
	var projected: Array[Vector2] = []
	var front_z := -INF
	for point: Vector3 in support_world:
		projected.append(camera.unproject_position(point) - Vector2(crop.position))
		front_z = maxf(front_z, point.z)
	var hull: Array[Vector2] = _convex_hull(projected)
	if hull.size() < 3:
		error = "Actual support projection has no polygon."
		return {}
	var front_x := 0.0
	var front_count := 0
	for point: Vector3 in support_world:
		if point.z >= front_z - 0.00001:
			front_x += point.x
			front_count += 1
	if front_count == 0:
		error = "Actual support has no front anchor."
		return {}
	var foot_px: Vector2 = camera.unproject_position(Vector3(front_x / float(front_count), transform.origin.y + low, front_z)) - Vector2(crop.position)
	var polygon: Array = []
	for point: Vector2 in hull:
		polygon.append([point.x,point.y])
	return {
		"foot_anchor_px": [foot_px.x,foot_px.y],
		"foot_uv": [foot_px.x / float(crop.size.x),foot_px.y / float(crop.size.y)],
		"actual_min_y_support_polygon_px": polygon,
	}


func _convex_hull(points: Array[Vector2]) -> Array[Vector2]:
	points.sort_custom(func(a: Vector2,b: Vector2) -> bool: return a.x < b.x or (is_equal_approx(a.x,b.x) and a.y < b.y))
	var unique: Array[Vector2] = []
	for point: Vector2 in points:
		if unique.is_empty() or unique[-1].distance_squared_to(point) > 0.0001:
			unique.append(point)
	if unique.size() < 3:
		return []
	var lower: Array[Vector2] = []
	for point: Vector2 in unique:
		while lower.size() >= 2 and _cross2(lower[-2],lower[-1],point) <= 0.0:
			lower.pop_back()
		lower.append(point)
	var upper: Array[Vector2] = []
	for i in range(unique.size() - 1, -1, -1):
		var point: Vector2 = unique[i]
		while upper.size() >= 2 and _cross2(upper[-2],upper[-1],point) <= 0.0:
			upper.pop_back()
		upper.append(point)
	lower.pop_back()
	upper.pop_back()
	lower.append_array(upper)
	return lower


func _cross2(a: Vector2,b: Vector2,c: Vector2) -> float:
	return (b-a).cross(c-a)


func _measure(mesh: ArrayMesh) -> Dictionary:
	var low := Vector3(INF,INF,INF)
	var high := Vector3(-INF,-INF,-INF)
	var triangles := 0
	var surface_rows: Array[Dictionary] = []
	for surface in range(mesh.get_surface_count()):
		if mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			error = "Authored mesh contains a nontriangle surface."
			return {}
		var arrays: Array = mesh.surface_get_arrays(surface)
		if arrays.size() != Mesh.ARRAY_MAX or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array or not arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array:
			error = "Authored mesh has incomplete vertex/normal arrays."
			return {}
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices := PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] == null:
			for index in range(vertices.size()):
				indices.append(index)
		elif arrays[Mesh.ARRAY_INDEX] is PackedInt32Array:
			indices = arrays[Mesh.ARRAY_INDEX]
		else:
			error = "Authored mesh has an unsupported index slot."
			return {}
		if vertices.is_empty() or normals.size() != vertices.size() or indices.is_empty() or indices.size() % 3 != 0:
			error = "Authored mesh triangle arrays are incomplete."
			return {}
		for index: int in indices:
			if index < 0 or index >= vertices.size() or not vertices[index].is_finite() or not normals[index].is_finite():
				error = "Authored mesh contains invalid draw data."
				return {}
			low = low.min(vertices[index])
			high = high.max(vertices[index])
		for i in range(0,indices.size(),3):
			var cross: Vector3 = (vertices[indices[i+1]]-vertices[indices[i]]).cross(vertices[indices[i+2]]-vertices[indices[i]])
			if cross.length_squared() <= 0.000000000001 or cross.dot(normals[indices[i]]) >= 0.0:
				error = "Authored triangle is degenerate or violates the source clockwise-normal convention."
				return {}
			triangles += 1
		var material: Material = mesh.surface_get_material(surface)
		if material == null:
			error = "Authored surface lost its saved material."
			return {}
		surface_rows.append({
			"surface": surface,
			"vertices": vertices.size(),
			"indices": indices.size(),
			"material_class": material.get_class(),
			"material_resource_path": material.resource_path,
			"arrays_sha256": _hash(var_to_bytes(arrays)),
		})
	return {
		"surface_count": mesh.get_surface_count(),
		"triangles": triangles,
		"minimum_m": _v3(low),
		"maximum_m": _v3(high),
		"finite_draw_indices_vertices_normals": true,
		"clockwise_faces_match_normals": true,
		"surfaces": surface_rows,
	}


func _save_mesh(path: String, mesh: ArrayMesh, revision: String) -> bool:
	if not path.begins_with(OUTPUT_ROOT) or FileAccess.file_exists(path) or ResourceSaver.save(mesh,path) != OK:
		error = "Own NEW mesh save/overwrite refused: " + path
		return false
	outputs[path] = {
		"sha256": FileAccess.get_sha256(path),
		"bytes": FileAccess.get_file_as_bytes(path).size(),
		"revision": revision,
	}
	return true


func _consumer_entry(asset_id: String, mesh_path: String, texture_path: String, capture: Dictionary) -> Dictionary:
	return {
		"asset_id": asset_id,
		"mesh_path": mesh_path,
		"mesh_sha256": outputs[mesh_path]["sha256"],
		"texture_path": texture_path,
		"texture_sha256": outputs[texture_path]["sha256"],
		"texture_bytes": outputs[texture_path]["bytes"],
		"render_size_px": capture["crop_size_px"],
		"foot_uv": capture["foot_uv"],
		"foot_anchor_px": capture["foot_anchor_px"],
		"support_polygon_px": capture["actual_min_y_support_polygon_px"],
		"ground_y_definition": "For candidate ground_y=500, place texture top-left at [world_x-foot_anchor_px.x, 500-foot_anchor_px.y]; translate support_polygon_px by that same top-left. This is an art placement contract, not collision or Field approval.",
		"source_catalog_key": "source_catalog.sha256_by_res_path",
	}


func _track(path: String, expected: String = "") -> bool:
	var actual: String = FileAccess.get_sha256(path).to_lower()
	if actual.length() != 64 or (expected != "" and actual != expected.to_lower()) or (inputs_first.has(path) and inputs_first[path] != actual):
		error = "Input SHA missing/mismatch/change: " + path
		return false
	inputs_first[path] = actual
	return true


func _bound(path: String) -> bool:
	var catalog: Dictionary = source_contract.get("asset_sha256", {})
	if not catalog.has(path):
		error = "Frozen gate art contract does not bind dependency: " + path
		return false
	return _track(path, String(catalog[path]))


func _bound_resource(path: String, seen: Dictionary = {}) -> bool:
	if not _bound(path):
		return false
	if seen.has(path):
		return true
	seen[path] = true
	for dependency: String in ResourceLoader.get_dependencies(path):
		var target := ""
		for part: String in dependency.split("::"):
			if part.begins_with("res://"):
				target = part
		if target == "" or not _bound_resource(target, seen):
			error = "Unresolved/unbound native dependency: " + dependency
			return false
	return true


func _finish(passed: bool, run_tag: String, bridge: Node) -> void:
	if viewport != null:
		viewport.queue_free()
		viewport = null
	for frame in range(4):
		await process_frame
	var inputs_last: Dictionary = {}
	var input_changes: Array[String] = []
	for path: String in inputs_first:
		inputs_last[path] = FileAccess.get_sha256(path).to_lower()
		if inputs_last[path] != inputs_first[path]:
			input_changes.append(path)
	if not input_changes.is_empty():
		passed = false
		error = "Read-only source input changed during capture."
	if bridge == null or bridge.call("is_checkpoint_saves_suspended") != true:
		passed = false
		error = "Checkpoint suspension did not remain active through capture."
	if bridge != null and bridge.has_method("set_checkpoint_saves_suspended"):
		bridge.call("set_checkpoint_saves_suspended", false)
	checkpoint_guard["restored_before_quit"] = bridge != null and bridge.call("is_checkpoint_saves_suspended") == false
	if checkpoint_guard["restored_before_quit"] != true:
		passed = false
		error = "Checkpoint suspension was not restored before quit."
	var consumer_catalog := {}
	if passed:
		consumer_catalog = {
			"schema_version": 1,
			"ground_y_reference_world_px": 500,
			"ground_y_definition": "ground_y is the world-space Y assigned to the captured front-centre minimum-mesh-Y foot anchor; it is not PNG bottom and does not imply a collision rectangle.",
			"source_catalog": {
				"sha256_by_res_path": inputs_first,
				"last_readback_sha256_by_res_path": inputs_last,
				"unchanged": input_changes.is_empty(),
			},
			"wall": _consumer_entry("luoyang_gate_wall_crenellated_straight_v1", OUTPUTS.straight_mesh, OUTPUTS.straight_png, geometry["straight_capture"]),
			"tower": _consumer_entry("luoyang_gate_corner_tower_v1", OUTPUTS.tower_mesh, OUTPUTS.tower_png, geometry["tower_capture"]),
		}
	var report := {
		"status": "NATIVE_CANDIDATE_CAPTURED_NOT_FIELD_OR_FORMAL" if passed else "CAPTURE_FAILED_NOT_ADOPTED",
		"passed_capture_checks": passed,
		"reason": error,
		"scope": "ONLY TWO NEW GATE FORTIFICATION MODULES; NO city layout, Field, Physics, portal, bridge, guard, water, NPC, save, audio or formal write",
		"run_tag": run_tag,
		"source_mesh_revision": {
			"source": SOURCE_MESH,
			"straight_retained_surfaces": [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],
			"straight_removed_old_tile_surfaces": [16,17],
			"straight_added_crenellation_surface": 16,
			"tower_rebuilt_geometry_material_sources": [14,15],
			"source_mesh_or_material_modified": false,
		},
		"authorization": {
			"native_mesh_and_project_authored_material": "Existing project resource; not CC0 architecture",
			"registered_rock_microdetail": "Poly Haven rock_01 CC0-1.0 as already bound by the source wall contract; no new download",
			"new_geometry": "Project procedural authoring: rectangular grey-brick wall/parapet/merlon/corner-tower boxes only",
			"network_or_generation": false,
		},
		"inputs_sha256_first": inputs_first,
		"inputs_sha256_last": inputs_last,
		"input_changes": input_changes,
		"outputs": outputs,
		"geometry_and_capture": geometry,
		"consumer_catalog": consumer_catalog,
		"placement_intent_not_runtime": {
			"wall_foot_world_px": [1536,500],
			"central_gate_portal_unchanged": [1536,500],
			"bridge_and_guards_unchanged": true,
			"tower_usage": "same symmetric front-facing B asset at the two far ends; no flip and no mid-wall bend",
		},
		"visual_review": "PENDING_ART_READBACK",
		"field_or_physics_approved": false,
		"production_or_formal_approved": false,
		"checkpoint_guard": checkpoint_guard,
	}
	if passed:
		var report_file := FileAccess.open(OUTPUTS.result, FileAccess.WRITE)
		if report_file == null:
			passed = false
			error = "Could not create the final capture result."
		else:
			report_file.store_string(JSON.stringify(report, "\t") + "\n")
			report_file.close()
			outputs[OUTPUTS.result] = {"sha256": FileAccess.get_sha256(OUTPUTS.result), "bytes": FileAccess.get_file_as_bytes(OUTPUTS.result).size()}
	if not passed:
		push_error(error)
	quit(0 if passed else 1)


func _fail_now(message: String) -> void:
	error = message
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge != null and bridge.has_method("set_checkpoint_saves_suspended"):
		bridge.call("set_checkpoint_saves_suspended", false)
	push_error(error)
	quit(1)


func _hash(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK:
		return ""
	return context.finish().hex_encode()


func _v3(value: Vector3) -> Array:
	return [value.x,value.y,value.z]
