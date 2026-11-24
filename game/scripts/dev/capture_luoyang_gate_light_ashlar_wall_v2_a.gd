extends "res://scripts/dev/capture_luoyang_gate_native_fortification_v1.gd"

## A-only light-grey ashlar replacement candidate for the Luoyang gate wall.
##
## The frozen v1 script remains the single implementation of the proven 30-degree
## camera, transparent double-readback, support projection, mesh measurement and
## checkpoint helpers.  This subclass replaces only the authoring flow, geometry,
## material, output root and final A-only report.  It does not build tower B and it
## never loads a city scene or writes a runtime/canonical manifest.

const V2_RUN_FLAG := "--capture-luoyang-gate-light-ashlar-wall-v2-a"
const BASE_CAPTURE_SCRIPT := "res://scripts/dev/capture_luoyang_gate_native_fortification_v1.gd"
const BASE_CAPTURE_SCRIPT_SHA := "65121068df07905dd23cd242f67de94ebf1018a5757123f0f5fd862fb1785a30"
const V1_RESULT := "res://art/modules/luoyang_gate_fortification_v1/capture_result.json"
const V1_RESULT_SHA := "b7799a4009aa071678e73ae7e37c58a0489531b158d0513f7b2d0912cff1c54a"

const V2_OUTPUT_ROOT := "res://art/modules/luoyang_gate_fortification_v2_a/"
const V2_AUTHORING_CONTRACT := V2_OUTPUT_ROOT + "source_contract.json"
const V2_OUTPUTS := {
	"wall_mesh": V2_OUTPUT_ROOT + "luoyang_gate_wall_light_ashlar_straight_v2_a.res",
	"wall_png": V2_OUTPUT_ROOT + "luoyang_gate_wall_light_ashlar_straight_v2_a.png",
	"comparison_png": V2_OUTPUT_ROOT + "luoyang_gate_wall_light_ashlar_v2_a_vs_south_gate.png",
	"result": V2_OUTPUT_ROOT + "capture_result.json",
}

const GATE_TEXTURE := SOURCE_ROOT + "entities/south_gate.png"
const ROCK_ROOT := "res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/"
const ROCK_SOURCE := ROCK_ROOT + "SOURCE.json"
const ROCK_DIFFUSE := ROCK_ROOT + "rock_01_diff_2k.jpg"
const ROCK_NORMAL := ROCK_ROOT + "rock_01_nor_gl_2k.jpg"
const ROCK_ARM := ROCK_ROOT + "rock_01_arm_2k.jpg"

const SOURCE_MIN := Vector3(-2.5, 0.0, -0.391387492418289)
const SOURCE_MAX := Vector3(2.5, 1.98000001907349, 0.391387492418289)
const WALL_DEPTH := 0.782774984836578
const WALL_WIDTH := 5.0
const COMPARISON_SIZE := Vector2i(1600, 720)
const COMPARISON_FOOT_Y := 500.0
const WALL_COMPARISON_FOOT_X := 400.0
const GATE_COMPARISON_FOOT := Vector2(1128.0, 500.0)
const GATE_SOURCE_FOOT := Vector2(768.0, 945.0)
const GATE_PREVIEW_SCALE := 0.5208333333333334
const UV_DENSITY := 0.82

const ASHLAR_SHADER := """
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D rock_diffuse : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_arm : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 base_tint = vec3(0.62, 0.63, 0.62);
uniform float grain_strength : hint_range(0.0, 0.3) = 0.13;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.20;
uniform float roughness_floor : hint_range(0.0, 1.0) = 0.78;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.16;

void fragment() {
	vec3 source_colour = texture(rock_diffuse, UV).rgb;
	float source_luma = dot(source_colour, vec3(0.2126, 0.7152, 0.0722));
	float grain = clamp((source_luma - 0.5) * grain_strength, -0.075, 0.075);
	ALBEDO = clamp(base_tint + vec3(grain), vec3(0.0), vec3(1.0));
	vec3 sampled_normal = texture(rock_normal, UV).rgb;
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), sampled_normal, normal_strength);
	NORMAL_MAP_DEPTH = 1.0;
	vec3 arm = texture(rock_arm, UV).rgb;
	AO = mix(1.0, arm.r, ao_strength);
	ROUGHNESS = mix(roughness_floor, 0.96, arm.g);
	METALLIC = 0.0;
	SPECULAR = 0.20;
}
"""

var authoring_contract: Dictionary = {}
var comparison_record: Dictionary = {}


func _start() -> void:
	# First deferred action and strictly before the first await.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		_fail_now("A-only authoring requires public checkpoint suspension; no fallback.")
		return
	bridge.call("set_checkpoint_saves_suspended", true)
	if bridge.call("is_checkpoint_saves_suspended") != true:
		_fail_now("Checkpoint suspension was not verified before A-only authoring.")
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
	if V2_RUN_FLAG not in args or tag_rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or tag_rule.search(run_tag) == null:
		_fail_now("Explicit A-only capture flag and a safe unique --capture-run-tag are required.")
		return
	if DisplayServer.get_name() == "headless":
		_fail_now("Transparent native GPU capture refuses a headless display server.")
		return
	for path: String in V2_OUTPUTS.values():
		if FileAccess.file_exists(path):
			_fail_now("Refusing to overwrite an existing v2 A-only output: " + path)
			return

	if not _track(get_script().resource_path) or not _track(BASE_CAPTURE_SCRIPT, BASE_CAPTURE_SCRIPT_SHA) or not _track(V2_AUTHORING_CONTRACT) or not _track(V1_RESULT, V1_RESULT_SHA) or not _track(SOURCE_CONTRACT, SOURCE_CONTRACT_SHA):
		_fail_now(error)
		return
	var art_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_CONTRACT))
	if not art_value is Dictionary or art_value.get("scene_id") != "ch4_s0_luoyang_gate":
		_fail_now("Exact frozen Luoyang gate art contract is required.")
		return
	source_contract = art_value
	if not _validate_gate_contract(source_contract):
		_fail_now(error)
		return
	var author_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(V2_AUTHORING_CONTRACT))
	if not author_value is Dictionary or author_value.get("asset_pack") != "luoyang_gate_fortification_v2_a" or author_value.get("status") != "SOURCE_AUTHORED_CAPTURE_PENDING":
		_fail_now("Exact pending v2 A-only source contract is required.")
		return
	authoring_contract = author_value

	if not _bound(SOURCE_MESH) or not _bound(SOURCE_META) or not _bound(ROCK_SOURCE):
		_fail_now(error)
		return
	for texture_path: String in [ROCK_DIFFUSE, ROCK_NORMAL, ROCK_ARM, GATE_TEXTURE]:
		if not _track_imported_texture(texture_path):
			_fail_now(error)
			return

	var meta_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_META))
	if not meta_value is Dictionary or not _validate_source_metadata(meta_value):
		_fail_now(error if error != "" else "Frozen native wall metadata mismatch.")
		return
	var v1_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(V1_RESULT))
	if not v1_value is Dictionary or v1_value.get("passed_capture_checks", false) != true:
		_fail_now("Frozen v1 actual capture result is unavailable or not passed.")
		return

	var stone_material: ShaderMaterial = _make_ashlar_material(Color(0.62, 0.63, 0.62), 0.13, 0.20, 0.78)
	var mortar_material: ShaderMaterial = _make_ashlar_material(Color(0.31, 0.32, 0.32), 0.055, 0.08, 0.88)
	if stone_material == null or mortar_material == null:
		_fail_now(error if error != "" else "Could not build independent ashlar materials.")
		return
	var wall: ArrayMesh = _build_light_ashlar_wall(stone_material, mortar_material)
	if wall == null or error != "":
		_fail_now(error if error != "" else "A-only ashlar geometry build failed.")
		return
	var wall_measure: Dictionary = _measure(wall)
	if wall_measure.is_empty() or not _measure_matches_source_bounds(wall_measure):
		_fail_now(error if error != "" else "A-only mesh does not preserve the source physical bounds.")
		return
	geometry["wall"] = wall_measure

	var wall_capture: Dictionary = await _capture(wall, "light_ashlar_wall_v2_a")
	if wall_capture.is_empty():
		await _finish(false, run_tag, bridge)
		return
	geometry["wall_capture"] = wall_capture
	var wall_size := Vector2i(wall_capture.crop_size_px[0], wall_capture.crop_size_px[1])
	print(JSON.stringify({"event":"gate_light_ashlar_v2_a_capture_measurement","crop_size_px":wall_capture.crop_size_px,"foot_uv":wall_capture.foot_uv,"foot_anchor_px":wall_capture.foot_anchor_px}))
	if wall_size.x < 650 or wall_size.x > 662 or wall_size.y < 274 or wall_size.y > 288:
		error = "A-only actual crop falls outside the frozen narrow 650..662 by 274..288 range; do not widen the gate."
		await _finish(false, run_tag, bridge)
		return
	var v1_capture: Dictionary = v1_value.get("geometry_and_capture", {}).get("straight_capture", {})
	if v1_capture.is_empty() or not _foot_is_preserved(wall_capture, v1_capture):
		error = "A-only actual foot anchor diverged from the measured v1 physical-foot projection."
		await _finish(false, run_tag, bridge)
		return

	var wall_image: Image = wall_capture["_verified_image"]
	var comparison: Dictionary = await _compose_gate_comparison(wall_image, wall_capture)
	if comparison.is_empty():
		await _finish(false, run_tag, bridge)
		return
	comparison_record = comparison
	var comparison_image: Image = comparison["_verified_image"]
	wall_capture.erase("_verified_image")
	comparison_record.erase("_verified_image")

	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(V2_OUTPUT_ROOT)) != OK:
		error = "Cannot create the isolated v2 A-only candidate directory."
		await _finish(false, run_tag, bridge)
		return
	if not _save_mesh(V2_OUTPUTS.wall_mesh, wall, "A-only six-course staggered light-grey ashlar; shallow front bevels; recessed mortar; eleven narrow merlons; source physical bounds unchanged"):
		await _finish(false, run_tag, bridge)
		return
	if not _save_png(V2_OUTPUTS.wall_png, wall_image) or not _save_png(V2_OUTPUTS.comparison_png, comparison_image):
		await _finish(false, run_tag, bridge)
		return
	await _finish(true, run_tag, bridge)


func _validate_source_metadata(meta: Dictionary) -> bool:
	var binding_value: Variant = meta.get("actual_body_mesh_binding", {})
	var bounds_value: Variant = meta.get("used_bounds_m", {})
	if not binding_value is Dictionary or not bounds_value is Dictionary:
		error = "Frozen source metadata lacks the actual mesh binding or used bounds."
		return false
	var binding: Dictionary = binding_value
	if binding.get("native_mesh_path", "") != SOURCE_MESH or binding.get("actual_node_mesh_equals_saved_checked_mesh", false) != true or String(binding.get("native_mesh_sha256", "")).to_lower() != inputs_first[SOURCE_MESH]:
		error = "Frozen source metadata does not bind the expected actual mesh."
		return false
	var minimum: Vector3 = _array_v3(bounds_value.get("minimum", []))
	var maximum: Vector3 = _array_v3(bounds_value.get("maximum", []))
	if not minimum.is_finite() or not maximum.is_finite() or not _v3_near(minimum, SOURCE_MIN, 0.000001) or not _v3_near(maximum, SOURCE_MAX, 0.000001):
		error = "Frozen source physical bounds changed."
		return false
	return true


func _validate_gate_contract(art: Dictionary) -> bool:
	var objects_value: Variant = art.get("objects", [])
	if not objects_value is Array:
		error = "Frozen gate art contract has no object array."
		return false
	for value: Variant in objects_value:
		if not value is Dictionary or value.get("id", "") != "south_gate":
			continue
		var gate: Dictionary = value
		var source_size: Variant = gate.get("source_size_px", [])
		var semantics: Variant = gate.get("source_semantics", {})
		if gate.get("texture", "") != GATE_TEXTURE or String(gate.get("source_sha256", "")).to_lower() != "368cae36b04f983f537f813173a65737a2ac61f2a5be8ded50ef9fb10f709343":
			error = "Frozen south_gate texture identity changed."
			return false
		if not source_size is Array or source_size.size() != 2 or float(source_size[0]) != 1536.0 or float(source_size[1]) != 1024.0:
			error = "Frozen south_gate source dimensions changed."
			return false
		if not semantics is Dictionary:
			error = "Frozen south_gate source semantics are missing."
			return false
		var door_foot: Variant = semantics.get("door_foot_source_px", [])
		if not door_foot is Array or door_foot.size() != 2 or absf(float(door_foot[0])-GATE_SOURCE_FOOT.x) > 0.000001 or absf(float(door_foot[1])-GATE_SOURCE_FOOT.y) > 0.000001:
			error = "Frozen south_gate door-foot anchor changed."
			return false
		return true
	error = "Frozen gate art contract has no exact south_gate object."
	return false


func _build_light_ashlar_wall(stone_material: ShaderMaterial, mortar_material: ShaderMaterial) -> ArrayMesh:
	var result := ArrayMesh.new()
	# Recessed backing only closes the real joints.  It stays inside the source
	# footprint and is never the front silhouette or minimum-Y support.
	var mortar_boxes: Array[Dictionary] = [{
		"center": Vector3(0.0, 0.73, -0.0105),
		"size": Vector3(4.976, 1.34, 0.735),
	}]
	var mortar_arrays: Array = _boxes_arrays(mortar_boxes)
	if mortar_arrays.is_empty():
		return null
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mortar_arrays)
	result.surface_set_material(0, mortar_material)

	var stones: Array[Dictionary] = []
	# A low continuous plinth owns the exact original minimum-Y support and depth.
	stones.append({"minimum": Vector3(-2.5, 0.0, SOURCE_MIN.z), "maximum": Vector3(2.5, 0.06, SOURCE_MAX.z), "bevel": 0.0, "role": "support_plinth"})
	var body_start := 0.06
	var body_end := 1.396
	var course_step := (body_end - body_start) / 6.0
	for row in range(6):
		var y0 := body_start + float(row) * course_step
		var y1 := y0 + course_step - 0.014
		_append_staggered_course(stones, row, y0, y1, 0.018)
	_append_even_course(stones, 10, body_end, 1.49, 0.012, 0.015, "cap_course")
	_append_even_course(stones, 11, 1.49, 1.68, 0.014, 0.018, "parapet_course")
	var merlon_cell := WALL_WIDTH / 21.0
	for index in range(11):
		var x0 := -2.5 + float(index * 2) * merlon_cell
		var x1 := x0 + merlon_cell
		stones.append({"minimum": Vector3(x0, 1.68, SOURCE_MIN.z), "maximum": Vector3(x1, SOURCE_MAX.y, SOURCE_MAX.z), "bevel": 0.022, "role": "narrow_merlon"})
	var stone_arrays: Array = _beveled_blocks_arrays(stones)
	if stone_arrays.is_empty():
		return null
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, stone_arrays)
	result.surface_set_material(1, stone_material)
	return result


func _append_staggered_course(blocks: Array[Dictionary], row: int, y0: float, y1: float, bevel: float) -> void:
	var boundaries: Array[float] = []
	if row % 2 == 0:
		for index in range(9):
			boundaries.append(-2.5 + float(index) * 0.625)
	else:
		boundaries.append(-2.5)
		boundaries.append(-2.1875)
		for index in range(1, 8):
			boundaries.append(-2.1875 + float(index) * 0.625)
		boundaries.append(2.5)
	_append_from_boundaries(blocks, boundaries, y0, y1, 0.022, bevel, "ashlar_course_%d" % row)


func _append_even_course(blocks: Array[Dictionary], count: int, y0: float, y1: float, joint: float, bevel: float, role: String) -> void:
	var boundaries: Array[float] = []
	for index in range(count + 1):
		boundaries.append(-2.5 + WALL_WIDTH * float(index) / float(count))
	_append_from_boundaries(blocks, boundaries, y0, y1, joint, bevel, role)


func _append_from_boundaries(blocks: Array[Dictionary], boundaries: Array[float], y0: float, y1: float, joint: float, bevel: float, role: String) -> void:
	for index in range(boundaries.size() - 1):
		var x0: float = boundaries[index] if index == 0 else boundaries[index] + joint * 0.5
		var x1: float = boundaries[index + 1] if index == boundaries.size() - 2 else boundaries[index + 1] - joint * 0.5
		blocks.append({"minimum": Vector3(x0, y0, SOURCE_MIN.z), "maximum": Vector3(x1, y1, SOURCE_MAX.z), "bevel": bevel, "role": role})


func _beveled_blocks_arrays(blocks: Array[Dictionary]) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var tangents := PackedFloat32Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for block: Dictionary in blocks:
		var minimum: Vector3 = block.get("minimum", Vector3.ZERO)
		var maximum: Vector3 = block.get("maximum", Vector3.ZERO)
		var bevel: float = block.get("bevel", 0.0)
		if not minimum.is_finite() or not maximum.is_finite() or minimum.x >= maximum.x or minimum.y >= maximum.y or minimum.z >= maximum.z:
			error = "A-only stone block has invalid bounds."
			return []
		var safe_bevel := minf(bevel, minf((maximum.x - minimum.x) * 0.20, (maximum.y - minimum.y) * 0.20))
		if safe_bevel <= 0.000001:
			_append_plain_block(vertices, normals, tangents, uvs, colors, indices, minimum, maximum)
		else:
			_append_front_beveled_block(vertices, normals, tangents, uvs, colors, indices, minimum, maximum, safe_bevel)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TANGENT] = tangents
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


func _append_plain_block(vertices: PackedVector3Array, normals: PackedVector3Array, tangents: PackedFloat32Array, uvs: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array, minimum: Vector3, maximum: Vector3) -> void:
	var x0 := minimum.x
	var x1 := maximum.x
	var y0 := minimum.y
	var y1 := maximum.y
	var z0 := minimum.z
	var z1 := maximum.z
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[Vector3(x0,y0,z1),Vector3(x0,y1,z1),Vector3(x1,y1,z1),Vector3(x1,y0,z1)],Vector3.BACK)
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[Vector3(x1,y0,z0),Vector3(x1,y1,z0),Vector3(x0,y1,z0),Vector3(x0,y0,z0)],Vector3.FORWARD)
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[Vector3(x1,y0,z1),Vector3(x1,y1,z1),Vector3(x1,y1,z0),Vector3(x1,y0,z0)],Vector3.RIGHT)
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[Vector3(x0,y0,z0),Vector3(x0,y1,z0),Vector3(x0,y1,z1),Vector3(x0,y0,z1)],Vector3.LEFT)
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[Vector3(x0,y1,z1),Vector3(x0,y1,z0),Vector3(x1,y1,z0),Vector3(x1,y1,z1)],Vector3.UP)
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[Vector3(x0,y0,z0),Vector3(x0,y0,z1),Vector3(x1,y0,z1),Vector3(x1,y0,z0)],Vector3.DOWN)


func _append_front_beveled_block(vertices: PackedVector3Array, normals: PackedVector3Array, tangents: PackedFloat32Array, uvs: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array, minimum: Vector3, maximum: Vector3, bevel: float) -> void:
	var x0 := minimum.x
	var x1 := maximum.x
	var y0 := minimum.y
	var y1 := maximum.y
	var z0 := minimum.z
	var z_outer := maximum.z - bevel
	var z_front := maximum.z
	var bl_o := Vector3(x0,y0,z_outer)
	var tl_o := Vector3(x0,y1,z_outer)
	var tr_o := Vector3(x1,y1,z_outer)
	var br_o := Vector3(x1,y0,z_outer)
	var bl_i := Vector3(x0+bevel,y0+bevel,z_front)
	var tl_i := Vector3(x0+bevel,y1-bevel,z_front)
	var tr_i := Vector3(x1-bevel,y1-bevel,z_front)
	var br_i := Vector3(x1-bevel,y0+bevel,z_front)
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[bl_i,tl_i,tr_i,br_i],Vector3.BACK)
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[bl_o,tl_o,tl_i,bl_i],Vector3(-1.0,0.0,1.0).normalized())
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[tl_o,tr_o,tr_i,tl_i],Vector3(0.0,1.0,1.0).normalized())
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[tr_o,br_o,br_i,tr_i],Vector3(1.0,0.0,1.0).normalized())
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[br_o,bl_o,bl_i,br_i],Vector3(0.0,-1.0,1.0).normalized())
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[Vector3(x1,y0,z0),Vector3(x1,y1,z0),Vector3(x0,y1,z0),Vector3(x0,y0,z0)],Vector3.FORWARD)
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[br_o,tr_o,Vector3(x1,y1,z0),Vector3(x1,y0,z0)],Vector3.RIGHT)
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[Vector3(x0,y0,z0),Vector3(x0,y1,z0),tl_o,bl_o],Vector3.LEFT)
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[tl_o,Vector3(x0,y1,z0),Vector3(x1,y1,z0),tr_o],Vector3.UP)
	_append_face_uv(vertices,normals,tangents,uvs,colors,indices,[Vector3(x0,y0,z0),bl_o,br_o,Vector3(x1,y0,z0)],Vector3.DOWN)


func _append_face_uv(vertices: PackedVector3Array, normals: PackedVector3Array, tangents: PackedFloat32Array, uvs: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array, points: Array[Vector3], normal: Vector3) -> void:
	var base := vertices.size()
	var tangent: Vector3 = (points[3] - points[0]).normalized()
	if absf(tangent.dot(normal)) > 0.001:
		tangent = Vector3.RIGHT if absf(normal.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
	for point: Vector3 in points:
		vertices.append(point)
		normals.append(normal)
		tangents.append_array(PackedFloat32Array([tangent.x,tangent.y,tangent.z,1.0]))
		uvs.append(_project_uv(point, normal))
		colors.append(Color.WHITE)
	indices.append_array(PackedInt32Array([base,base+1,base+2,base,base+2,base+3]))


func _project_uv(point: Vector3, normal: Vector3) -> Vector2:
	var axis := normal.abs()
	if axis.y >= axis.x and axis.y >= axis.z:
		return Vector2(point.x, point.z) * UV_DENSITY
	if axis.x >= axis.z:
		return Vector2(-point.z, -point.y) * UV_DENSITY
	return Vector2(point.x, -point.y) * UV_DENSITY


func _make_ashlar_material(tint: Color, grain: float, normal_strength: float, roughness_floor: float) -> ShaderMaterial:
	var diffuse: Texture2D = ResourceLoader.load(ROCK_DIFFUSE, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var normal: Texture2D = ResourceLoader.load(ROCK_NORMAL, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var arm: Texture2D = ResourceLoader.load(ROCK_ARM, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if diffuse == null or normal == null or arm == null:
		error = "Registered rock microdetail textures did not load."
		return null
	var shader := Shader.new()
	shader.code = ASHLAR_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("rock_diffuse", diffuse)
	material.set_shader_parameter("rock_normal", normal)
	material.set_shader_parameter("rock_arm", arm)
	material.set_shader_parameter("base_tint", Vector3(tint.r,tint.g,tint.b))
	material.set_shader_parameter("grain_strength", grain)
	material.set_shader_parameter("normal_strength", normal_strength)
	material.set_shader_parameter("roughness_floor", roughness_floor)
	return material


func _compose_gate_comparison(wall_image: Image, wall_capture: Dictionary) -> Dictionary:
	var compare_viewport := SubViewport.new()
	compare_viewport.size = COMPARISON_SIZE
	compare_viewport.transparent_bg = false
	compare_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(compare_viewport)
	var canvas := Node2D.new()
	compare_viewport.add_child(canvas)
	var sky := ColorRect.new()
	sky.position = Vector2.ZERO
	sky.size = Vector2(COMPARISON_SIZE.x, COMPARISON_FOOT_Y)
	sky.color = Color(0.155,0.17,0.175,1.0)
	canvas.add_child(sky)
	var ground := ColorRect.new()
	ground.position = Vector2(0.0,COMPARISON_FOOT_Y)
	ground.size = Vector2(COMPARISON_SIZE.x,COMPARISON_SIZE.y-COMPARISON_FOOT_Y)
	ground.color = Color(0.255,0.25,0.235,1.0)
	canvas.add_child(ground)

	var wall_texture := ImageTexture.create_from_image(wall_image)
	var wall_sprite := Sprite2D.new()
	wall_sprite.texture = wall_texture
	wall_sprite.centered = false
	wall_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var wall_foot := Vector2(wall_capture.foot_anchor_px[0],wall_capture.foot_anchor_px[1])
	wall_sprite.position = Vector2(WALL_COMPARISON_FOOT_X,COMPARISON_FOOT_Y) - wall_foot
	canvas.add_child(wall_sprite)

	var gate_texture: Texture2D = ResourceLoader.load(GATE_TEXTURE, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if gate_texture == null or gate_texture.get_size() != Vector2(1536,1024):
		error = "Actual south_gate texture failed its 1536x1024 comparison binding."
		compare_viewport.queue_free()
		return {}
	var gate_sprite := Sprite2D.new()
	gate_sprite.texture = gate_texture
	gate_sprite.centered = false
	gate_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	gate_sprite.scale = Vector2.ONE * GATE_PREVIEW_SCALE
	gate_sprite.position = GATE_COMPARISON_FOOT - GATE_SOURCE_FOOT * GATE_PREVIEW_SCALE
	canvas.add_child(gate_sprite)

	for frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var first: Image = compare_viewport.get_texture().get_image()
	first.convert(Image.FORMAT_RGBA8)
	for frame in range(2):
		await process_frame
	await RenderingServer.frame_post_draw
	var second: Image = compare_viewport.get_texture().get_image()
	second.convert(Image.FORMAT_RGBA8)
	if first.get_data() != second.get_data():
		error = "Offline A-versus-south_gate comparison was not byte-repeatable."
		compare_viewport.queue_free()
		return {}
	var gate_display := gate_texture.get_size() * GATE_PREVIEW_SCALE
	var wall_right := wall_sprite.position.x + float(wall_image.get_width())
	var gate_left := gate_sprite.position.x
	var wall_top_left := wall_sprite.position
	var gate_top_left := gate_sprite.position
	if absf(wall_sprite.scale.x - 1.0) > 0.000001 or absf(wall_sprite.scale.y - 1.0) > 0.000001 or absf(wall_right - gate_left) > 0.01:
		error = "Comparison changed A scale or failed the authored wall-to-gate seam."
		compare_viewport.queue_free()
		return {}
	compare_viewport.queue_free()
	for frame in range(2):
		await process_frame
	return {
		"_verified_image": first,
		"canvas_px": [COMPARISON_SIZE.x,COMPARISON_SIZE.y],
		"wall_bitmap_scale": [1.0,1.0],
		"wall_foot_canvas_px": [WALL_COMPARISON_FOOT_X,COMPARISON_FOOT_Y],
		"wall_top_left_canvas_px": [wall_top_left.x,wall_top_left.y],
		"south_gate_source": GATE_TEXTURE,
		"south_gate_source_size_px": [1536,1024],
		"south_gate_uniform_scale": GATE_PREVIEW_SCALE,
		"south_gate_display_size_px": [gate_display.x,gate_display.y],
		"south_gate_source_foot_px": [GATE_SOURCE_FOOT.x,GATE_SOURCE_FOOT.y],
		"south_gate_foot_canvas_px": [GATE_COMPARISON_FOOT.x,GATE_COMPARISON_FOOT.y],
		"south_gate_top_left_canvas_px": [gate_top_left.x,gate_top_left.y],
		"wall_right_equals_gate_left_px": [wall_right,gate_left],
		"source_colour_or_bitmap_modified": false,
		"actual_field_screenshot": false,
		"purpose": "Clean explanatory art-scale comparison only; A is unscaled and south_gate uses one uniform 800px-wide authored preview scale.",
	}


func _track_imported_texture(path: String) -> bool:
	if not _bound(path):
		return false
	var import_path := path + ".import"
	if not _track(import_path):
		return false
	var config := ConfigFile.new()
	if config.load(import_path) != OK:
		error = "Could not parse texture import binding: " + import_path
		return false
	var imported := String(config.get_value("remap","path",""))
	if not imported.begins_with("res://.godot/imported/") or not FileAccess.file_exists(imported) or not _track(imported):
		error = "Texture source/import/ctex binding is incomplete: " + path
		return false
	return true


func _measure_matches_source_bounds(measure: Dictionary) -> bool:
	var minimum: Vector3 = _array_v3(measure.get("minimum_m", []))
	var maximum: Vector3 = _array_v3(measure.get("maximum_m", []))
	if not minimum.is_finite() or not maximum.is_finite() or not _v3_near(minimum,SOURCE_MIN,0.000001) or not _v3_near(maximum,SOURCE_MAX,0.000001):
		error = "Measured A-only bounds differ from the frozen physical footprint/height."
		return false
	if measure.get("surface_count", 0) != 2 or measure.get("triangles", 0) < 1000:
		error = "A-only mesh lacks the independent mortar/stone surfaces or real bevel topology."
		return false
	return true


func _foot_is_preserved(current: Dictionary, baseline: Dictionary) -> bool:
	var current_anchor := Vector2(current.foot_anchor_px[0],current.foot_anchor_px[1])
	var baseline_anchor := Vector2(baseline.foot_anchor_px[0],baseline.foot_anchor_px[1])
	return current_anchor.distance_to(baseline_anchor) <= 3.0 and absf(current_anchor.x - float(current.crop_size_px[0]) * 0.5) <= 0.01


func _array_v3(value: Variant) -> Vector3:
	if not value is Array or value.size() != 3:
		return Vector3(INF,INF,INF)
	for component: Variant in value:
		if not component is float and not component is int:
			return Vector3(INF,INF,INF)
	var result := Vector3(float(value[0]),float(value[1]),float(value[2]))
	return result if result.is_finite() else Vector3(INF,INF,INF)


func _v3_near(a: Vector3, b: Vector3, tolerance: float) -> bool:
	return absf(a.x-b.x) <= tolerance and absf(a.y-b.y) <= tolerance and absf(a.z-b.z) <= tolerance


func _save_mesh(path: String, mesh: ArrayMesh, revision: String) -> bool:
	if not path.begins_with(V2_OUTPUT_ROOT) or FileAccess.file_exists(path) or ResourceSaver.save(mesh,path) != OK:
		error = "Own NEW v2 A-only mesh save/overwrite refused: " + path
		return false
	var reloaded: ArrayMesh = ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var readback: Dictionary = _measure(reloaded) if reloaded != null else {}
	if readback.is_empty() or not _measure_matches_source_bounds(readback):
		error = "Saved A-only mesh failed strict geometry readback."
		return false
	var dependencies: Array[String] = []
	for dependency: String in ResourceLoader.get_dependencies(path):
		for part: String in dependency.split("::"):
			if part.begins_with("res://") and part not in dependencies:
				dependencies.append(part)
	for required: String in [ROCK_DIFFUSE,ROCK_NORMAL,ROCK_ARM]:
		if required not in dependencies:
			error = "Saved A-only mesh lost a registered rock microdetail dependency: " + required
			return false
	outputs[path] = {
		"sha256": FileAccess.get_sha256(path),
		"bytes": FileAccess.get_file_as_bytes(path).size(),
		"revision": revision,
		"strict_mesh_readback": true,
		"resource_dependencies": dependencies,
	}
	return true


func _save_png(path: String, image: Image) -> bool:
	if not path.begins_with(V2_OUTPUT_ROOT) or FileAccess.file_exists(path) or image.save_png(path) != OK:
		error = "Own NEW v2 A-only PNG save/overwrite refused: " + path
		return false
	var readback: Image = Image.load_from_file(path)
	if readback == null:
		error = "A-only PNG readback failed for " + path
		return false
	readback.convert(Image.FORMAT_RGBA8)
	if readback.get_size() != image.get_size() or readback.get_data() != image.get_data():
		error = "A-only PNG readback differs for " + path
		return false
	outputs[path] = {
		"sha256": FileAccess.get_sha256(path),
		"bytes": FileAccess.get_file_as_bytes(path).size(),
		"rgba_sha256": _hash(image.get_data()),
		"size_px": [image.get_width(),image.get_height()],
		"lossless_readback_exact": true,
	}
	return true


func _v2_consumer_entry(capture: Dictionary) -> Dictionary:
	return {
		"asset_id": "luoyang_gate_wall_light_ashlar_straight_v2_a",
		"mesh_path": V2_OUTPUTS.wall_mesh,
		"mesh_sha256": outputs[V2_OUTPUTS.wall_mesh]["sha256"],
		"texture_path": V2_OUTPUTS.wall_png,
		"texture_sha256": outputs[V2_OUTPUTS.wall_png]["sha256"],
		"texture_bytes": outputs[V2_OUTPUTS.wall_png]["bytes"],
		"render_size_px": capture.crop_size_px,
		"foot_uv": capture.foot_uv,
		"foot_anchor_px": capture.foot_anchor_px,
		"support_polygon_px": capture.actual_min_y_support_polygon_px,
		"ground_y_definition": "For candidate ground_y=500, place texture top-left at [world_x-foot_anchor_px.x, 500-foot_anchor_px.y]; translate support_polygon_px by the same top-left. This is an art placement contract, not collision or Field approval.",
		"source_catalog_key": "source_catalog.sha256_by_res_path",
	}


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
		error = "Read-only source input changed during A-only capture."
	if bridge == null or bridge.call("is_checkpoint_saves_suspended") != true:
		passed = false
		error = "Checkpoint suspension did not remain active through A-only capture."
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
			"wall": _v2_consumer_entry(geometry["wall_capture"]),
		}
	var report := {
		"status": "A_ONLY_NATIVE_CANDIDATE_CAPTURED_NOT_FIELD_OR_FORMAL" if passed else "A_ONLY_CAPTURE_FAILED_NOT_ADOPTED",
		"passed_capture_checks": passed,
		"reason": error,
		"scope": "ONLY ONE NEW LIGHT-GREY ASHLAR WALL A; NO tower B, runtime publisher, city layout, Field, Physics, portal, bridge, guard, water, NPC, save, audio or formal write",
		"run_tag": run_tag,
		"source_contract": authoring_contract,
		"authorization": {
			"architecture": "Existing project-original south_gate and project procedural geometry; not CC0 architecture",
			"registered_rock_microdetail": "Poly Haven rock_01 CC0-1.0 as already bound by the frozen gate art contract; no new download",
			"new_geometry_and_material": "Six staggered ashlar courses, real shallow front bevels, recessed mortar, narrow cap/parapet and eleven narrow merlons; independent light-grey shader",
			"network_generation_or_bitmap_edit": false,
		},
		"inputs_sha256_first": inputs_first,
		"inputs_sha256_last": inputs_last,
		"input_changes": input_changes,
		"outputs": outputs,
		"geometry_and_capture": geometry,
		"offline_comparison": comparison_record,
		"consumer_catalog": consumer_catalog,
		"placement_intent_not_runtime": {
			"candidate_wall_ground_y": 500,
			"central_gate_portal_unchanged": [1536,500],
			"physical_footprint_changed": false,
			"tower_B_included": false,
		},
		"visual_review": "PENDING_ROOT_ACTUAL_GPU_READBACK",
		"field_or_physics_approved": false,
		"production_or_formal_approved": false,
		"checkpoint_guard": checkpoint_guard,
	}
	if passed:
		var report_file := FileAccess.open(V2_OUTPUTS.result,FileAccess.WRITE)
		if report_file == null:
			passed = false
			error = "Could not create the final v2 A-only capture result."
		else:
			report_file.store_string(JSON.stringify(report,"\t") + "\n")
			report_file.close()
			outputs[V2_OUTPUTS.result] = {"sha256":FileAccess.get_sha256(V2_OUTPUTS.result),"bytes":FileAccess.get_file_as_bytes(V2_OUTPUTS.result).size()}
	if not passed:
		push_error(error)
	quit(0 if passed else 1)
