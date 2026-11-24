extends "res://scripts/dev/capture_luoyang_gate_refined_ashlar_wall_v3_a.gd"

## B3-only terminal tower authoring capture plus one explanatory group preview.
## Reuses A3 material/camera/readback/source/checkpoint helpers.  It never loads
## a city scene and does not publish either asset into runtime data.

const B3_RUN_FLAG := "--capture-luoyang-gate-refined-corner-tower-v3-b"
const B3_OUTPUT_ROOT := "res://art/modules/luoyang_gate_fortification_v3_b_refined/"
const B3_CONTRACT := B3_OUTPUT_ROOT + "source_contract.json"
const B3_OUTPUTS := {
	"tower_mesh": B3_OUTPUT_ROOT + "luoyang_gate_corner_tower_refined_v3_b.res",
	"tower_png": B3_OUTPUT_ROOT + "luoyang_gate_corner_tower_refined_v3_b.png",
	"group_preview_png": B3_OUTPUT_ROOT + "luoyang_gate_fortification_v3_ab_group_preview_1920x1080.png",
	"result": B3_OUTPUT_ROOT + "capture_result.json",
}

const A3_SCRIPT := "res://scripts/dev/capture_luoyang_gate_refined_ashlar_wall_v3_a.gd"
const A3_SCRIPT_SHA := "dd765dde5aabb39657e5754b48b782f46a16524dabf77aee8dc50752108347f9"
const A3_CONTRACT_PATH := A3_OUTPUT_ROOT + "source_contract.json"
const A3_CONTRACT_SHA := "76b6b4ce0296890ff695948ecf7094025ab13b070b73f457fd436ff6713792c8"
const A3_RESULT := A3_OUTPUT_ROOT + "capture_result.json"
const A3_RESULT_SHA := "087a0a76d2880e307feae946ab565cff2ba9933ebc83cfaf27bb031afc38235d"
const A3_MESH := A3_OUTPUTS.wall_mesh
const A3_MESH_SHA := "7b7dfbffb2023fe910754e73d5dfbf842fb8a2e95b39749e4e93eaff5f060547"
const A3_PNG := A3_OUTPUTS.wall_png
const A3_PNG_SHA := "078a873f8892ea8329c4cb923260e5e19aac1f72a358f8c80877d1cb43552435"

const V1_TOWER_MESH := OUTPUTS.tower_mesh
const V1_TOWER_MESH_SHA := "371c687e3da1fdb649eb44dfe2e5e1f87070e120809b91fa4f4deb7784f12ce5"
const V1_TOWER_PNG := OUTPUTS.tower_png
const V1_TOWER_PNG_SHA := "624ff65bb097bde7b44a0e1c3322cbfe0278ca97114620000b70752b1d252d55"
const B3_DRAW_MIN := Vector3(-0.901000022888184, 0.0, -0.746767342090607)
const B3_DRAW_MAX := Vector3(0.901000022888184, 1.98000001907349, 0.774947226047516)
const B3_SUPPORT_MIN := Vector3(-0.880600022369961, 0.0, -0.704497492975659)
const B3_SUPPORT_MAX := Vector3(0.880600022369961, 0.0, 0.774947226047516)

const GROUP_CANVAS := Vector2i(1920, 1080)
const GROUP_SCALE := 0.6
const GROUP_OFFSET := Vector2(38.4, 350.0)
const GROUP_GROUND_Y := 500.0
const GROUP_WALL_FEET := [333.0, 950.0, 2122.0, 2739.0]
const GROUP_TOWER_FEET := [100.0, 2972.0]

var group_preview_record: Dictionary = {}


func _start() -> void:
	# First deferred action and strictly before the first await.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		_fail_now("B3 capture requires public checkpoint suspension; no fallback.")
		return
	bridge.call("set_checkpoint_saves_suspended", true)
	if bridge.call("is_checkpoint_saves_suspended") != true:
		_fail_now("Checkpoint suspension was not verified before B3 authoring.")
		return
	checkpoint_guard = {"public_api":"PlatformBridge.set_checkpoint_saves_suspended(true)","before_first_await":true,"verified_suspended":true,"restored_before_quit":false}

	var args: PackedStringArray = OS.get_cmdline_user_args()
	var run_tag := ""
	for arg: String in args:
		if arg.begins_with("--capture-run-tag="):
			run_tag = arg.trim_prefix("--capture-run-tag=")
	var tag_rule := RegEx.new()
	if B3_RUN_FLAG not in args or tag_rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or tag_rule.search(run_tag) == null:
		_fail_now("Explicit B3 flag and safe unique --capture-run-tag are required.")
		return
	if DisplayServer.get_name() == "headless":
		_fail_now("Transparent native GPU capture refuses a headless display server.")
		return
	for path: String in B3_OUTPUTS.values():
		if FileAccess.file_exists(path):
			_fail_now("Refusing to overwrite an existing B3 output: " + path)
			return

	if not (
		_track(get_script().resource_path)
		and _track(B3_CONTRACT)
		and _track(A3_SCRIPT, A3_SCRIPT_SHA)
		and _track(A3_CONTRACT_PATH, A3_CONTRACT_SHA)
		and _track(A3_RESULT, A3_RESULT_SHA)
		and _track(A3_MESH, A3_MESH_SHA)
		and _track(A3_PNG, A3_PNG_SHA)
		and _track(V1_RESULT, V1_RESULT_SHA)
		and _track(V1_TOWER_MESH, V1_TOWER_MESH_SHA)
		and _track(V1_TOWER_PNG, V1_TOWER_PNG_SHA)
		and _track(WEATHER_PARENT_SCRIPT, WEATHER_PARENT_SCRIPT_SHA)
		and _track(RETRY_SCRIPT, RETRY_SCRIPT_SHA)
		and _track(PARENT_CAPTURE_SCRIPT, PARENT_CAPTURE_SCRIPT_SHA)
		and _track(BASE_CAPTURE_SCRIPT, BASE_CAPTURE_SCRIPT_SHA)
		and _track(SOURCE_CONTRACT, SOURCE_CONTRACT_SHA)
	):
		_fail_now(error)
		return
	var art_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_CONTRACT))
	if not art_value is Dictionary or art_value.get("scene_id") != "ch4_s0_luoyang_gate":
		_fail_now("Exact frozen gate art contract is required.")
		return
	source_contract = art_value
	if not _validate_gate_contract(source_contract):
		_fail_now(error)
		return
	var author_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(B3_CONTRACT))
	if not author_value is Dictionary or author_value.get("asset_pack") != "luoyang_gate_fortification_v3_b_refined" or author_value.get("status") != "SOURCE_AUTHORED_CAPTURE_PENDING":
		_fail_now("Exact pending B3 source contract is required.")
		return
	authoring_contract = author_value
	if not _bound(ROCK_SOURCE) or not _track_imported_texture(ROCK_DIFFUSE) or not _track_imported_texture(ROCK_NORMAL) or not _track_imported_texture(ROCK_ARM) or not _track_imported_texture(GATE_TEXTURE) or not _bound(WORN_BLUestone) or not _track_imported_texture(WORN_BLUestone) or not _bound(WORN_PROVENANCE):
		_fail_now(error)
		return

	var a3_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(A3_RESULT))
	var v1_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(V1_RESULT))
	if not a3_value is Dictionary or a3_value.get("passed_capture_checks", false) != true:
		_fail_now("Pinned A3 actual capture is unavailable or not passed.")
		return
	if not v1_value is Dictionary or not _validate_v1_tower_result(v1_value):
		_fail_now(error if error != "" else "Pinned actual v1 B result mismatch.")
		return
	var v1_tower: ArrayMesh = ResourceLoader.load(V1_TOWER_MESH, "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if v1_tower == null or not _validate_v1_tower_mesh(v1_tower):
		_fail_now(error if error != "" else "Pinned actual v1 B mesh mismatch.")
		return

	var stone_material: ShaderMaterial = _make_ashlar_material(Color(0.64, 0.635, 0.61), 1.0, 0.38, 0.79)
	var mortar_material: ShaderMaterial = _make_ashlar_material(Color(0.335, 0.33, 0.315), 0.40, 0.13, 0.91)
	if stone_material == null or mortar_material == null:
		_fail_now(error if error != "" else "Could not build B3 A-matched materials.")
		return
	var tower: ArrayMesh = _build_b3_tower(stone_material, mortar_material)
	if tower == null or error != "" or not _validate_b3_geometry(tower):
		_fail_now(error if error != "" else "B3 geometry/support build failed.")
		return
	geometry["tower"] = _measure(tower)
	geometry["b3_authoring"] = {"body_courses":10,"nominal_blocks_per_front_course":6,"joint_m":0.010,"bevel_m":0.007,"deterministic_corner_chips":true,"shallow_face_recesses":true,"arrow_openings":3,"low_crenellations":5}

	var tower_capture: Dictionary = await _capture(tower, "tower")
	if tower_capture.is_empty():
		await _finish(false, run_tag, bridge)
		return
	geometry["tower_capture"] = tower_capture
	var tower_size := Vector2i(tower_capture.crop_size_px[0], tower_capture.crop_size_px[1])
	print(JSON.stringify({"event":"gate_refined_corner_tower_v3_b_capture_measurement","crop_size_px":tower_capture.crop_size_px,"foot_uv":tower_capture.foot_uv,"foot_anchor_px":tower_capture.foot_anchor_px}))
	if tower_size.x < 180 or tower_size.x > 390 or tower_size.y < 220 or tower_size.y > 340:
		error = "B3 actual crop left the unchanged 180..390 by 220..340 v1 B domain."
		await _finish(false, run_tag, bridge)
		return
	var v1_geometry: Dictionary = v1_value.get("geometry_and_capture", {})
	var v1_capture: Dictionary = v1_geometry.get("tower_capture", {})
	if not _foot_is_preserved(tower_capture, v1_capture):
		error = "B3 foot anchor exceeds the unchanged <=3 px actual v1 B guard."
		await _finish(false, run_tag, bridge)
		return

	var tower_image: Image = tower_capture["_verified_image"]
	var group_preview: Dictionary = await _compose_group_preview(tower_image, tower_capture, a3_value)
	if group_preview.is_empty():
		await _finish(false, run_tag, bridge)
		return
	group_preview_record = group_preview
	var group_image: Image = group_preview["_verified_image"]
	tower_capture.erase("_verified_image")
	group_preview_record.erase("_verified_image")
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(B3_OUTPUT_ROOT)) != OK:
		error = "Cannot create isolated B3 candidate directory."
		await _finish(false, run_tag, bridge)
		return
	if not _save_mesh(B3_OUTPUTS.tower_mesh, tower, "B3 ten-course terminal tower, three narrow arrow openings and five A3-scale low crenellations"):
		await _finish(false, run_tag, bridge)
		return
	if not _save_png(B3_OUTPUTS.tower_png, tower_image) or not _save_png(B3_OUTPUTS.group_preview_png, group_image):
		await _finish(false, run_tag, bridge)
		return
	await _finish(true, run_tag, bridge)


func _validate_v1_tower_result(v1: Dictionary) -> bool:
	if v1.get("passed_capture_checks", false) != true:
		error = "Pinned v1 result is not passed."
		return false
	var g: Dictionary = v1.get("geometry_and_capture", {})
	var measure: Dictionary = g.get("tower", {})
	var capture: Dictionary = g.get("tower_capture", {})
	if not _measure_has_bounds(measure, B3_DRAW_MIN, B3_DRAW_MAX):
		error = "Pinned v1 B draw bounds changed."
		return false
	var crop: Variant = capture.get("crop_size_px", [])
	var foot: Variant = capture.get("foot_anchor_px", [])
	if not crop is Array or crop.size() != 2 or int(crop[0]) != 246 or int(crop[1]) != 332 or not foot is Array or foot.size() != 2 or absf(float(foot[0]) - 123.0) > 0.000001 or absf(float(foot[1]) - 323.958984375) > 0.000001:
		error = "Pinned v1 B actual crop/foot changed."
		return false
	return true


func _validate_v1_tower_mesh(mesh: ArrayMesh) -> bool:
	var measure: Dictionary = _measure(mesh)
	if measure.is_empty() or not _measure_has_bounds(measure, B3_DRAW_MIN, B3_DRAW_MAX):
		error = "Pinned v1 B mesh no longer matches its actual draw bounds."
		return false
	var support: Dictionary = _minimum_y_support_bounds(mesh)
	if support.is_empty() or not _v3_near(support.minimum, B3_SUPPORT_MIN, 0.000001) or not _v3_near(support.maximum, B3_SUPPORT_MAX, 0.000001):
		error = "Pinned v1 B minimum-Y support changed."
		return false
	geometry["v1_tower_minimum_y_support"] = {"minimum":_v3(support.minimum),"maximum":_v3(support.maximum),"source":"actual pinned v1 tower mesh"}
	return true


func _measure_has_bounds(measure: Dictionary, expected_min: Vector3, expected_max: Vector3) -> bool:
	return _v3_near(_array_v3(measure.get("minimum_m", [])), expected_min, 0.000001) and _v3_near(_array_v3(measure.get("maximum_m", [])), expected_max, 0.000001)


func _minimum_y_support_bounds(mesh: ArrayMesh) -> Dictionary:
	var low := INF
	var points: Array[Vector3] = []
	for surface in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for index: int in indices:
			low = minf(low, vertices[index].y)
			points.append(vertices[index])
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	var used := 0
	for point: Vector3 in points:
		if point.y <= low + 0.000001:
			minimum = minimum.min(point)
			maximum = maximum.max(point)
			used += 1
	return {"minimum":minimum,"maximum":maximum,"used_index_visits":used} if used >= 3 else {}


func _build_b3_tower(stone_material: ShaderMaterial, mortar_material: ShaderMaterial) -> ArrayMesh:
	var result := ArrayMesh.new()
	var support_center := (B3_SUPPORT_MIN + B3_SUPPORT_MAX) * 0.5
	var support_size := B3_SUPPORT_MAX - B3_SUPPORT_MIN
	var mortar_boxes: Array[Dictionary] = [
		{"center":Vector3(0.0, 0.83, support_center.z - 0.0105),"size":Vector3(support_size.x - 0.024, 1.54, support_size.z - 0.045)},
		{"center":Vector3(0.0, 1.77, (B3_DRAW_MIN.z + B3_DRAW_MAX.z) * 0.5 - 0.0105),"size":Vector3(B3_DRAW_MAX.x * 2.0 - 0.024, 0.06, B3_DRAW_MAX.z - B3_DRAW_MIN.z - 0.045)},
	]
	var mortar_arrays: Array = _boxes_arrays(mortar_boxes)
	if mortar_arrays.is_empty():
		return null
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mortar_arrays)
	result.surface_set_material(0, mortar_material)

	var stones: Array[Dictionary] = []
	stones.append({"minimum":B3_SUPPORT_MIN,"maximum":Vector3(B3_SUPPORT_MAX.x, 0.055, B3_SUPPORT_MAX.z),"bevel":0.0,"role":"exact_v1_tower_support_plinth"})
	var body_start := 0.06
	var body_end := 1.42
	var step := (body_end - body_start) / 10.0
	for row in range(10):
		_b3_append_course(stones, row, body_start + float(row) * step, body_start + float(row + 1) * step - 0.009)
	_b3_append_even_course(stones, 7, 1.42, 1.51, 0.006, 0.005, "tower_thin_cap")
	_b3_append_even_course(stones, 7, 1.51, 1.60, 0.006, 0.005, "tower_arrow_sill")
	_b3_append_arrow_row(stones, 1.60, 1.74)
	_b3_append_even_course(stones, 8, 1.74, 1.80, 0.005, 0.004, "tower_arrow_lintel")
	var width := B3_DRAW_MAX.x - B3_DRAW_MIN.x
	var cell := width / 9.0
	for index in range(5):
		var x0 := B3_DRAW_MIN.x + float(index * 2) * cell
		var x1 := minf(x0 + cell, B3_DRAW_MAX.x)
		stones.append({"minimum":Vector3(x0, 1.80, B3_DRAW_MIN.z),"maximum":Vector3(x1, B3_DRAW_MAX.y, B3_DRAW_MAX.z),"bevel":0.006,"role":"tower_low_gate_crenellation"})
	var stone_arrays: Array = _beveled_blocks_arrays(stones)
	if stone_arrays.is_empty():
		return null
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, stone_arrays)
	result.surface_set_material(1, stone_material)
	return result


func _b3_append_course(blocks: Array[Dictionary], row: int, y0: float, y1: float) -> void:
	var minimum_x := B3_SUPPORT_MIN.x
	var maximum_x := B3_SUPPORT_MAX.x
	var width := maximum_x - minimum_x
	var nominal := width / 6.0
	var boundaries: Array[float] = [minimum_x]
	if row % 2 == 1:
		boundaries.append(minimum_x + nominal * 0.5)
		for index in range(1, 6):
			var jitter := 0.010 if index % 2 == 1 else -0.008
			boundaries.append(minimum_x + nominal * (float(index) + 0.5) + jitter)
	else:
		for index in range(1, 6):
			var jitter := 0.009 if index % 3 == 1 else (-0.007 if index % 3 == 2 else 0.0)
			boundaries.append(minimum_x + nominal * float(index) + jitter)
	boundaries.append(maximum_x)
	for column in range(boundaries.size() - 1):
		var x0: float = boundaries[column] if column == 0 else boundaries[column] + 0.005
		var x1: float = boundaries[column + 1] if column == boundaries.size() - 2 else boundaries[column + 1] - 0.005
		var recess := 0.010 if ((row * 11 + column * 5) % 29 == 8) else 0.0
		var minimum := Vector3(x0, y0, B3_SUPPORT_MIN.z)
		var maximum := Vector3(x1, y1, B3_SUPPORT_MAX.z - recess)
		var chipped := column > 0 and column < boundaries.size() - 2 and ((row * 13 + column * 7) % 37 == 6)
		if chipped:
			var chip_w := minf(0.035, (x1 - x0) * 0.20)
			var chip_h := minf(0.030, (y1 - y0) * 0.26)
			blocks.append({"minimum":Vector3(x0 + chip_w, y0, minimum.z),"maximum":maximum,"bevel":0.007,"role":"tower_course_chipped_main"})
			blocks.append({"minimum":minimum,"maximum":Vector3(x0 + chip_w, y1 - chip_h, maximum.z),"bevel":0.005,"role":"tower_course_chip_remainder"})
		else:
			blocks.append({"minimum":minimum,"maximum":maximum,"bevel":0.007,"role":"tower_refined_course"})


func _b3_append_even_course(blocks: Array[Dictionary], count: int, y0: float, y1: float, joint: float, bevel: float, role: String) -> void:
	var width := B3_DRAW_MAX.x - B3_DRAW_MIN.x
	for index in range(count):
		var x0 := B3_DRAW_MIN.x + width * float(index) / float(count)
		var x1 := B3_DRAW_MIN.x + width * float(index + 1) / float(count)
		if index > 0:
			x0 += joint * 0.5
		if index < count - 1:
			x1 -= joint * 0.5
		blocks.append({"minimum":Vector3(x0, y0, B3_DRAW_MIN.z),"maximum":Vector3(x1, y1, B3_DRAW_MAX.z),"bevel":bevel,"role":role})


func _b3_append_arrow_row(blocks: Array[Dictionary], y0: float, y1: float) -> void:
	var bays := 3
	var width := B3_DRAW_MAX.x - B3_DRAW_MIN.x
	var bay_width := width / float(bays)
	var slot_width := 0.052
	for index in range(bays):
		var bx0 := B3_DRAW_MIN.x + float(index) * bay_width
		var bx1 := bx0 + bay_width
		var center := (bx0 + bx1) * 0.5
		blocks.append({"minimum":Vector3(bx0, y0, B3_DRAW_MIN.z),"maximum":Vector3(center - slot_width * 0.5, y1, B3_DRAW_MAX.z),"bevel":0.005,"role":"tower_arrow_row_left"})
		blocks.append({"minimum":Vector3(center + slot_width * 0.5, y0, B3_DRAW_MIN.z),"maximum":Vector3(bx1, y1, B3_DRAW_MAX.z),"bevel":0.005,"role":"tower_arrow_row_right"})


func _validate_b3_geometry(mesh: ArrayMesh) -> bool:
	var measure: Dictionary = _measure(mesh)
	if measure.is_empty() or not _measure_has_bounds(measure, B3_DRAW_MIN, B3_DRAW_MAX) or measure.get("surface_count", 0) != 2 or measure.get("triangles", 0) < 600:
		error = "B3 lost exact v1 draw bounds, two materials or refined topology."
		return false
	var support: Dictionary = _minimum_y_support_bounds(mesh)
	if support.is_empty() or not _v3_near(support.minimum, B3_SUPPORT_MIN, 0.000001) or not _v3_near(support.maximum, B3_SUPPORT_MAX, 0.000001):
		error = "B3 minimum-Y support differs from the actual pinned v1 tower."
		return false
	geometry["tower_minimum_y_support"] = {"minimum":_v3(support.minimum),"maximum":_v3(support.maximum),"used_index_visits":support.used_index_visits,"exact_actual_v1_domain":true}
	return true


func _compose_group_preview(tower_image: Image, tower_capture: Dictionary, a3_result: Dictionary) -> Dictionary:
	var a3_image: Image = Image.load_from_file(A3_PNG)
	if a3_image == null:
		error = "Pinned A3 PNG failed to decode for group preview."
		return {}
	a3_image.convert(Image.FORMAT_RGBA8)
	var a3_capture: Dictionary = a3_result.get("geometry_and_capture", {}).get("wall_capture", {})
	if a3_image.get_size() != Vector2i(656, 280) or a3_capture.get("crop_size_px", []) != [656.0, 280.0]:
		error = "Pinned A3 image/result size mismatch."
		return {}
	var preview := SubViewport.new()
	preview.size = GROUP_CANVAS
	preview.transparent_bg = false
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(preview)
	var sky := ColorRect.new()
	sky.size = Vector2(GROUP_CANVAS.x, 650.0)
	sky.color = Color(0.155, 0.17, 0.175, 1.0)
	preview.add_child(sky)
	var ground := ColorRect.new()
	ground.position = Vector2(0.0, 650.0)
	ground.size = Vector2(GROUP_CANVAS.x, GROUP_CANVAS.y - 650.0)
	ground.color = Color(0.255, 0.25, 0.235, 1.0)
	preview.add_child(ground)
	var group := Node2D.new()
	group.position = GROUP_OFFSET
	group.scale = Vector2.ONE * GROUP_SCALE
	preview.add_child(group)

	var a3_texture := ImageTexture.create_from_image(a3_image)
	var a3_foot := Vector2(a3_capture.foot_anchor_px[0], a3_capture.foot_anchor_px[1])
	for foot_x: float in GROUP_WALL_FEET:
		_add_group_sprite(group, a3_texture, Vector2(foot_x, GROUP_GROUND_Y) - a3_foot, Vector2.ONE)
	var gate_texture: Texture2D = ResourceLoader.load(GATE_TEXTURE, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if gate_texture == null or gate_texture.get_size() != Vector2(1536, 1024):
		error = "Actual south_gate texture failed group binding."
		preview.queue_free()
		return {}
	_add_group_sprite(group, gate_texture, Vector2(1536.0, GROUP_GROUND_Y) - GATE_SOURCE_FOOT * GATE_PREVIEW_SCALE, Vector2.ONE * GATE_PREVIEW_SCALE)
	var tower_texture := ImageTexture.create_from_image(tower_image)
	var tower_foot := Vector2(tower_capture.foot_anchor_px[0], tower_capture.foot_anchor_px[1])
	for foot_x: float in GROUP_TOWER_FEET:
		_add_group_sprite(group, tower_texture, Vector2(foot_x, GROUP_GROUND_Y) - tower_foot, Vector2.ONE)

	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var first: Image = preview.get_texture().get_image()
	first.convert(Image.FORMAT_RGBA8)
	for frame in range(2):
		await process_frame
	await RenderingServer.frame_post_draw
	var second: Image = preview.get_texture().get_image()
	second.convert(Image.FORMAT_RGBA8)
	preview.queue_free()
	if first.get_size() != GROUP_CANVAS or first.get_data() != second.get_data():
		error = "B3 group preview was not an exact repeatable 1920x1080 GPU readback."
		return {}
	return {"_verified_image":second,"canvas_px":[1920,1080],"logical_stage_px":[3072,1080],"uniform_presentation_scale":GROUP_SCALE,"group_offset_px":[GROUP_OFFSET.x,GROUP_OFFSET.y],"logical_ground_y":GROUP_GROUND_Y,"a3_wall_foot_x":GROUP_WALL_FEET,"b3_tower_foot_x":GROUP_TOWER_FEET,"south_gate_foot":[1536,500],"a3_and_b3_local_scale":[1.0,1.0],"south_gate_uniform_local_scale":GATE_PREVIEW_SCALE,"nonuniform_stretch_or_flip":false,"actual_field_screenshot":false,"purpose":"Explanatory full-fortification same-coordinate group preview only."}


func _add_group_sprite(parent: Node2D, texture: Texture2D, position: Vector2, scale_value: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.position = position
	sprite.scale = scale_value
	parent.add_child(sprite)


func _save_mesh(path: String, mesh: ArrayMesh, revision: String) -> bool:
	if not path.begins_with(B3_OUTPUT_ROOT) or FileAccess.file_exists(path) or ResourceSaver.save(mesh, path) != OK:
		error = "Own NEW B3 mesh save/overwrite refused: " + path
		return false
	var reloaded: ArrayMesh = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var before: Dictionary = geometry.get("tower", {})
	var readback: Dictionary = _measure(reloaded) if reloaded != null else {}
	if before.is_empty() or readback.is_empty() or not _same_geometry_arrays(before, readback) or not _validate_b3_geometry(reloaded):
		error = "Saved B3 mesh failed exact authored-array/support readback."
		return false
	var dependencies: Array[String] = []
	for dependency: String in ResourceLoader.get_dependencies(path):
		for part: String in dependency.split("::"):
			if part.begins_with("res://") and part not in dependencies:
				dependencies.append(part)
	for required: String in [ROCK_DIFFUSE, ROCK_NORMAL, ROCK_ARM, WORN_BLUestone]:
		if required not in dependencies:
			error = "Saved B3 mesh lost registered A3 material dependency: " + required
			return false
	outputs[path] = {"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size(),"revision":revision,"strict_authored_array_readback":true,"resource_dependencies":dependencies}
	return true


func _save_png(path: String, image: Image) -> bool:
	if not path.begins_with(B3_OUTPUT_ROOT) or FileAccess.file_exists(path) or image.save_png(path) != OK:
		error = "Own NEW B3 PNG save/overwrite refused: " + path
		return false
	var readback: Image = Image.load_from_file(path)
	if readback == null:
		error = "B3 PNG readback failed for " + path
		return false
	readback.convert(Image.FORMAT_RGBA8)
	if readback.get_size() != image.get_size() or readback.get_data() != image.get_data():
		error = "B3 PNG readback differs for " + path
		return false
	outputs[path] = {"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size(),"rgba_sha256":_hash(image.get_data()),"size_px":[image.get_width(),image.get_height()],"lossless_readback_exact":true}
	return true


func _b3_consumer_entry(capture: Dictionary) -> Dictionary:
	return {"asset_id":"luoyang_gate_corner_tower_refined_v3_b","mesh_path":B3_OUTPUTS.tower_mesh,"mesh_sha256":outputs[B3_OUTPUTS.tower_mesh]["sha256"],"texture_path":B3_OUTPUTS.tower_png,"texture_sha256":outputs[B3_OUTPUTS.tower_png]["sha256"],"texture_bytes":outputs[B3_OUTPUTS.tower_png]["bytes"],"render_size_px":capture.crop_size_px,"foot_uv":capture.foot_uv,"foot_anchor_px":capture.foot_anchor_px,"support_polygon_px":capture.actual_min_y_support_polygon_px,"ground_y_definition":"For candidate ground_y=500, place texture top-left at [world_x-foot_anchor_px.x,500-foot_anchor_px.y]; translate support_polygon_px by the same top-left. Art placement only; not collision/Field approval.","same_asset_left_and_right_without_flip":true,"source_catalog_key":"source_catalog.sha256_by_res_path"}


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
		error = "Read-only source input changed during B3 capture."
	if bridge == null or bridge.call("is_checkpoint_saves_suspended") != true:
		passed = false
		error = "Checkpoint suspension did not remain active through B3 capture."
	if bridge != null and bridge.has_method("set_checkpoint_saves_suspended"):
		bridge.call("set_checkpoint_saves_suspended", false)
	checkpoint_guard["restored_before_quit"] = bridge != null and bridge.call("is_checkpoint_saves_suspended") == false
	if checkpoint_guard["restored_before_quit"] != true:
		passed = false
		error = "Checkpoint suspension was not restored before quit."
	var consumer_catalog := {}
	if passed:
		consumer_catalog = {"schema_version":1,"ground_y_reference_world_px":500,"ground_y_definition":"ground_y is the world-space Y assigned to the captured front-centre minimum-mesh-Y foot anchor; not PNG bottom/collision.","source_catalog":{"sha256_by_res_path":inputs_first,"last_readback_sha256_by_res_path":inputs_last,"unchanged":input_changes.is_empty()},"tower":_b3_consumer_entry(geometry["tower_capture"])}
	var report := {"status":"B3_REFINED_NATIVE_CANDIDATE_CAPTURED_NOT_FIELD_OR_FORMAL" if passed else "B3_REFINED_CAPTURE_FAILED_NOT_ADOPTED","passed_capture_checks":passed,"reason":error,"scope":"ONE B3 terminal tower plus explanatory group preview; no runtime publisher, Field, Physics, portal, water, NPC, save, audio or formal write","run_tag":run_tag,"source_contract":authoring_contract,"inputs_sha256_first":inputs_first,"inputs_sha256_last":inputs_last,"input_changes":input_changes,"outputs":outputs,"geometry_and_capture":geometry,"group_preview":group_preview_record,"consumer_catalog":consumer_catalog,"visual_review":"PENDING_ROOT_ACTUAL_GPU_READBACK","field_or_physics_approved":false,"production_or_formal_approved":false,"checkpoint_guard":checkpoint_guard}
	if passed:
		var report_file := FileAccess.open(B3_OUTPUTS.result, FileAccess.WRITE)
		if report_file == null:
			passed = false
			error = "Could not create final B3 result."
		else:
			report_file.store_string(JSON.stringify(report, "\t") + "\n")
			report_file.close()
			outputs[B3_OUTPUTS.result] = {"sha256":FileAccess.get_sha256(B3_OUTPUTS.result),"bytes":FileAccess.get_file_as_bytes(B3_OUTPUTS.result).size()}
	if not passed:
		push_error(error)
	quit(0 if passed else 1)
