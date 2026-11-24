extends "res://scripts/dev/capture_luoyang_gate_light_ashlar_wall_v2_a_weathered1.gd"

## A-only refined gate-wall authoring candidate.
## Reuses the proven camera/readback/comparison/source/checkpoint helpers and
## changes only procedural wall A geometry plus the existing weathered material.

const A3_RUN_FLAG := "--capture-luoyang-gate-refined-ashlar-wall-v3-a"
const A3_OUTPUT_ROOT := "res://art/modules/luoyang_gate_fortification_v3_a_refined/"
const A3_CONTRACT := A3_OUTPUT_ROOT + "source_contract.json"
const A3_OUTPUTS := {
	"wall_mesh": A3_OUTPUT_ROOT + "luoyang_gate_wall_refined_ashlar_v3_a.res",
	"wall_png": A3_OUTPUT_ROOT + "luoyang_gate_wall_refined_ashlar_v3_a.png",
	"comparison_png": A3_OUTPUT_ROOT + "luoyang_gate_wall_refined_ashlar_v3_a_vs_south_gate.png",
	"result": A3_OUTPUT_ROOT + "capture_result.json",
}

const WEATHER_PARENT_SCRIPT := "res://scripts/dev/capture_luoyang_gate_light_ashlar_wall_v2_a_weathered1.gd"
const WEATHER_PARENT_SCRIPT_SHA := "ac207395a18a8094a3822737a51034f16b85126c33e6de0949eb5c8eef6c7031"
const WEATHER_PARENT_CONTRACT := WEATHER_OUTPUT_ROOT + "source_contract.json"
const WEATHER_PARENT_CONTRACT_SHA := "7737f72281420b032927d22e3e8a18fe7e9395546d7a80f939bd4c588c0c442f"
const WEATHER_PARENT_RESULT := WEATHER_OUTPUT_ROOT + "capture_result.json"
const WEATHER_PARENT_RESULT_SHA := "2dc9dafb87eef0b375cdfa2f6afb4cc8c758815a11b5058617ed04ebf98799ae"
const WEATHER_PARENT_MESH := WEATHER_OUTPUTS.wall_mesh
const WEATHER_PARENT_MESH_SHA := "1305ffa04e000cd1f7efbf5b73d2d1e38ba630149797c7b3cd73b78fd734f94a"
const WEATHER_PARENT_PNG := WEATHER_OUTPUTS.wall_png
const WEATHER_PARENT_PNG_SHA := "baa0ecf0408769877731e252637d9ef57c21fd00f26c46f1d5e123965fe18cc3"

const A3_SHADER := """
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D rock_diffuse : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D worn_bluestone : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_arm : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 base_tint = vec3(0.62, 0.63, 0.62);
uniform float weather_strength : hint_range(0.0, 1.0) = 1.0;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.38;
uniform float roughness_floor : hint_range(0.0, 1.0) = 0.79;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.22;

varying vec3 local_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 detail_uv = UV * 1.08 + vec2(0.07, 0.13);
	vec3 rock = texture(rock_diffuse, detail_uv).rgb;
	vec3 worn = texture(worn_bluestone, UV * 0.52 + vec2(0.19, 0.09)).rgb;
	vec3 source_colour = mix(worn, rock, 0.46);
	float source_luma = max(dot(source_colour, vec3(0.2126, 0.7152, 0.0722)), 0.08);
	vec3 source_chroma = source_colour / source_luma;
	vec3 mapped = base_tint * mix(vec3(1.0), source_chroma, 0.52 * weather_strength);
	mapped *= mix(1.0, 0.70 + source_luma * 0.62, weather_strength);

	float row = floor(max(local_pos.y, 0.0) * 7.35);
	float stagger = mod(row, 2.0) * 0.5;
	vec2 block_cell = vec2(floor((local_pos.x + 2.5) * 3.20 + stagger), row);
	float block_tone = (hash21(block_cell) - 0.5) * 0.095 * weather_strength;
	float broad_stain = sin(local_pos.x * 1.17 + local_pos.y * 2.31) * 0.025;
	mapped *= 1.0 + block_tone + broad_stain * weather_strength;

	float warm_mineral = clamp((rock.r - rock.b) * 1.55, 0.0, 0.22) * weather_strength;
	mapped += vec3(0.085, 0.038, -0.008) * warm_mineral;
	float damp_shape = 0.72 + 0.28 * hash21(vec2(floor((local_pos.x + 2.5) * 2.0), 9.0));
	float foot_damp = (1.0 - smoothstep(0.03, 0.31, local_pos.y)) * damp_shape * weather_strength;
	mapped = mix(mapped, mapped * vec3(0.77, 0.84, 0.85), foot_damp * 0.24);
	ALBEDO = clamp(mapped, vec3(0.05), vec3(0.92));

	vec3 sampled_normal = texture(rock_normal, detail_uv).rgb;
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), sampled_normal, normal_strength);
	NORMAL_MAP_DEPTH = 1.0;
	vec3 arm = texture(rock_arm, detail_uv).rgb;
	AO = mix(1.0, arm.r, ao_strength);
	ROUGHNESS = mix(roughness_floor, 0.98, max(arm.g, foot_damp * 0.45));
	METALLIC = 0.0;
	SPECULAR = 0.15;
}
"""


func _start() -> void:
	# First deferred action and strictly before the first await.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		_fail_now("A3 capture requires public checkpoint suspension; no fallback.")
		return
	bridge.call("set_checkpoint_saves_suspended", true)
	if bridge.call("is_checkpoint_saves_suspended") != true:
		_fail_now("Checkpoint suspension was not verified before A3 authoring.")
		return
	checkpoint_guard = {"public_api":"PlatformBridge.set_checkpoint_saves_suspended(true)","before_first_await":true,"verified_suspended":true,"restored_before_quit":false}

	var args: PackedStringArray = OS.get_cmdline_user_args()
	var run_tag := ""
	for arg: String in args:
		if arg.begins_with("--capture-run-tag="):
			run_tag = arg.trim_prefix("--capture-run-tag=")
	var tag_rule := RegEx.new()
	if A3_RUN_FLAG not in args or tag_rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or tag_rule.search(run_tag) == null:
		_fail_now("Explicit A3 flag and safe unique --capture-run-tag are required.")
		return
	if DisplayServer.get_name() == "headless":
		_fail_now("Transparent native GPU capture refuses a headless display server.")
		return
	for path: String in A3_OUTPUTS.values():
		if FileAccess.file_exists(path):
			_fail_now("Refusing to overwrite an existing A3 output: " + path)
			return

	if not (
		_track(get_script().resource_path)
		and _track(A3_CONTRACT)
		and _track(WEATHER_PARENT_SCRIPT, WEATHER_PARENT_SCRIPT_SHA)
		and _track(WEATHER_PARENT_CONTRACT, WEATHER_PARENT_CONTRACT_SHA)
		and _track(WEATHER_PARENT_RESULT, WEATHER_PARENT_RESULT_SHA)
		and _track(WEATHER_PARENT_MESH, WEATHER_PARENT_MESH_SHA)
		and _track(WEATHER_PARENT_PNG, WEATHER_PARENT_PNG_SHA)
		and _track(RETRY_SCRIPT, RETRY_SCRIPT_SHA)
		and _track(PARENT_CAPTURE_SCRIPT, PARENT_CAPTURE_SCRIPT_SHA)
		and _track(BASE_CAPTURE_SCRIPT, BASE_CAPTURE_SCRIPT_SHA)
		and _track(V1_RESULT, V1_RESULT_SHA)
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
	var author_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(A3_CONTRACT))
	if not author_value is Dictionary or author_value.get("asset_pack") != "luoyang_gate_fortification_v3_a_refined" or author_value.get("status") != "SOURCE_AUTHORED_CAPTURE_PENDING":
		_fail_now("Exact pending A3 source contract is required.")
		return
	authoring_contract = author_value

	if not _bound(ROCK_SOURCE) or not _track_imported_texture(ROCK_DIFFUSE) or not _track_imported_texture(ROCK_NORMAL) or not _track_imported_texture(ROCK_ARM) or not _track_imported_texture(GATE_TEXTURE) or not _bound(WORN_BLUestone) or not _track_imported_texture(WORN_BLUestone) or not _bound(WORN_PROVENANCE):
		_fail_now(error)
		return
	var parent_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(WEATHER_PARENT_RESULT))
	var v1_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(V1_RESULT))
	if not parent_value is Dictionary or parent_value.get("passed_capture_checks", false) != true:
		_fail_now("Pinned weathered A parent is unavailable or not passed.")
		return
	if not v1_value is Dictionary or not _validate_actual_v1_baseline(v1_value):
		_fail_now(error if error != "" else "Pinned actual v1 baseline mismatch.")
		return

	var stone_material: ShaderMaterial = _make_ashlar_material(Color(0.64, 0.635, 0.61), 1.0, 0.38, 0.79)
	var mortar_material: ShaderMaterial = _make_ashlar_material(Color(0.335, 0.33, 0.315), 0.40, 0.13, 0.91)
	if stone_material == null or mortar_material == null:
		_fail_now(error if error != "" else "Could not build A3 weathered materials.")
		return
	var wall: ArrayMesh = _build_a3_wall(stone_material, mortar_material)
	if wall == null or error != "" or not _validate_retry_support_geometry(wall):
		_fail_now(error if error != "" else "A3 geometry/support build failed.")
		return
	var wall_measure: Dictionary = _measure(wall)
	if wall_measure.is_empty() or not _measure_matches_source_bounds(wall_measure):
		_fail_now(error if error != "" else "A3 draw bounds/topology failed.")
		return
	geometry["wall"] = wall_measure
	geometry["a3_authoring"] = {"body_courses":10,"nominal_blocks_per_full_course":16,"joint_m":0.010,"bevel_m":0.007,"deterministic_corner_chips":true,"shallow_face_recesses":true,"arrow_openings":9,"low_crenellations":14}

	var wall_capture: Dictionary = await _capture(wall, "refined_ashlar_wall_v3_a")
	if wall_capture.is_empty():
		await _finish(false, run_tag, bridge)
		return
	geometry["wall_capture"] = wall_capture
	var wall_size := Vector2i(wall_capture.crop_size_px[0], wall_capture.crop_size_px[1])
	print(JSON.stringify({"event":"gate_refined_ashlar_v3_a_capture_measurement","crop_size_px":wall_capture.crop_size_px,"foot_uv":wall_capture.foot_uv,"foot_anchor_px":wall_capture.foot_anchor_px}))
	if wall_size.x < 650 or wall_size.x > 662 or wall_size.y < 274 or wall_size.y > 288:
		error = "A3 actual crop left the unchanged narrow 650..662 by 274..288 domain."
		await _finish(false, run_tag, bridge)
		return
	var v1_geometry: Dictionary = v1_value.get("geometry_and_capture", {})
	var v1_capture: Dictionary = v1_geometry.get("straight_capture", {})
	if not _foot_is_preserved(wall_capture, v1_capture):
		error = "A3 foot anchor exceeds the unchanged <=3 px v1 guard."
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
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(A3_OUTPUT_ROOT)) != OK:
		error = "Cannot create isolated A3 candidate directory."
		await _finish(false, run_tag, bridge)
		return
	if not _save_mesh(A3_OUTPUTS.wall_mesh, wall, "A3 ten-course refined ashlar, geometry chips/recesses, narrow arrow openings and fourteen low crenellations"):
		await _finish(false, run_tag, bridge)
		return
	if not _save_png(A3_OUTPUTS.wall_png, wall_image) or not _save_png(A3_OUTPUTS.comparison_png, comparison_image):
		await _finish(false, run_tag, bridge)
		return
	await _finish(true, run_tag, bridge)


func _make_ashlar_material(tint: Color, weather_strength: float, normal_strength: float, roughness_floor: float) -> ShaderMaterial:
	var diffuse: Texture2D = ResourceLoader.load(ROCK_DIFFUSE, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var worn: Texture2D = ResourceLoader.load(WORN_BLUestone, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var normal: Texture2D = ResourceLoader.load(ROCK_NORMAL, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var arm: Texture2D = ResourceLoader.load(ROCK_ARM, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if diffuse == null or worn == null or normal == null or arm == null:
		error = "Registered A3 material textures did not load."
		return null
	var shader := Shader.new()
	shader.code = A3_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("rock_diffuse", diffuse)
	material.set_shader_parameter("worn_bluestone", worn)
	material.set_shader_parameter("rock_normal", normal)
	material.set_shader_parameter("rock_arm", arm)
	material.set_shader_parameter("base_tint", Vector3(tint.r, tint.g, tint.b))
	material.set_shader_parameter("weather_strength", weather_strength)
	material.set_shader_parameter("normal_strength", normal_strength)
	material.set_shader_parameter("roughness_floor", roughness_floor)
	return material


func _build_a3_wall(stone_material: ShaderMaterial, mortar_material: ShaderMaterial) -> ArrayMesh:
	var result := ArrayMesh.new()
	var mortar_boxes: Array[Dictionary] = [
		{"center":Vector3(0.0, 0.83, -0.0105), "size":Vector3(4.976, 1.54, 0.675)},
		{"center":Vector3(0.0, 1.77, -0.0105), "size":Vector3(4.976, 0.06, 0.675)},
	]
	var mortar_arrays: Array = _boxes_arrays(mortar_boxes)
	if mortar_arrays.is_empty():
		return null
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mortar_arrays)
	result.surface_set_material(0, mortar_material)

	var stones: Array[Dictionary] = []
	stones.append({"minimum":RETRY_SUPPORT_MIN,"maximum":Vector3(RETRY_SUPPORT_MAX.x, 0.055, RETRY_SUPPORT_MAX.z),"bevel":0.0,"role":"exact_v1_support_plinth"})
	var body_start := 0.06
	var body_end := 1.42
	var step := (body_end - body_start) / 10.0
	for row in range(10):
		_a3_append_course(stones, row, body_start + float(row) * step, body_start + float(row + 1) * step - 0.009)
	_a3_append_even_course(stones, 18, 1.42, 1.51, 0.006, 0.005, "thin_cap")
	_a3_append_even_course(stones, 18, 1.51, 1.60, 0.006, 0.005, "arrow_sill")
	_a3_append_arrow_row(stones, 1.60, 1.74)
	_a3_append_even_course(stones, 20, 1.74, 1.80, 0.005, 0.004, "arrow_lintel")
	var crenel_cell := 5.0 / 27.0
	for index in range(14):
		var x0 := -2.5 + float(index * 2) * crenel_cell
		var x1 := minf(x0 + crenel_cell, 2.5)
		stones.append({"minimum":Vector3(x0, 1.80, RETRY_DRAW_MIN.z),"maximum":Vector3(x1, RETRY_DRAW_MAX.y, RETRY_DRAW_MAX.z),"bevel":0.006,"role":"low_gate_crenellation"})
	var stone_arrays: Array = _beveled_blocks_arrays(stones)
	if stone_arrays.is_empty():
		return null
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, stone_arrays)
	result.surface_set_material(1, stone_material)
	return result


func _a3_append_course(blocks: Array[Dictionary], row: int, y0: float, y1: float) -> void:
	var boundaries: Array[float] = [-2.5]
	var nominal := 5.0 / 16.0
	if row % 2 == 1:
		boundaries.append(-2.5 + nominal * 0.5)
		for index in range(1, 16):
			var jitter := (0.014 if index % 3 == 1 else (-0.011 if index % 3 == 2 else 0.004))
			boundaries.append(-2.5 + nominal * (float(index) + 0.5) + jitter)
	else:
		for index in range(1, 16):
			var jitter := (0.012 if index % 4 == 1 else (-0.010 if index % 4 == 3 else 0.0))
			boundaries.append(-2.5 + nominal * float(index) + jitter)
	boundaries.append(2.5)
	for column in range(boundaries.size() - 1):
		var x0: float = boundaries[column] if column == 0 else boundaries[column] + 0.005
		var x1: float = boundaries[column + 1] if column == boundaries.size() - 2 else boundaries[column + 1] - 0.005
		var recess := 0.012 if ((row * 19 + column * 7) % 31 == 9) else 0.0
		var minimum := Vector3(x0, y0, RETRY_DRAW_MIN.z)
		var maximum := Vector3(x1, y1, RETRY_DRAW_MAX.z - recess)
		var chipped := column > 0 and column < boundaries.size() - 2 and ((row * 17 + column * 11) % 43 == 7)
		if chipped:
			var chip_w := minf(0.038, (x1 - x0) * 0.22)
			var chip_h := minf(0.032, (y1 - y0) * 0.28)
			blocks.append({"minimum":Vector3(x0 + chip_w, y0, minimum.z),"maximum":maximum,"bevel":0.007,"role":"refined_course_chipped_main"})
			blocks.append({"minimum":minimum,"maximum":Vector3(x0 + chip_w, y1 - chip_h, maximum.z),"bevel":0.005,"role":"refined_course_chip_remainder"})
		else:
			blocks.append({"minimum":minimum,"maximum":maximum,"bevel":0.007,"role":"refined_course"})


func _a3_append_even_course(blocks: Array[Dictionary], count: int, y0: float, y1: float, joint: float, bevel: float, role: String) -> void:
	for index in range(count):
		var x0 := -2.5 + 5.0 * float(index) / float(count)
		var x1 := -2.5 + 5.0 * float(index + 1) / float(count)
		if index > 0:
			x0 += joint * 0.5
		if index < count - 1:
			x1 -= joint * 0.5
		blocks.append({"minimum":Vector3(x0, y0, RETRY_DRAW_MIN.z),"maximum":Vector3(x1, y1, RETRY_DRAW_MAX.z),"bevel":bevel,"role":role})


func _a3_append_arrow_row(blocks: Array[Dictionary], y0: float, y1: float) -> void:
	var bays := 9
	var bay_width := 5.0 / float(bays)
	var slot_width := 0.052
	for index in range(bays):
		var bx0 := -2.5 + float(index) * bay_width
		var bx1 := bx0 + bay_width
		var center := (bx0 + bx1) * 0.5
		blocks.append({"minimum":Vector3(bx0, y0, RETRY_DRAW_MIN.z),"maximum":Vector3(center - slot_width * 0.5, y1, RETRY_DRAW_MAX.z),"bevel":0.005,"role":"arrow_row_left"})
		blocks.append({"minimum":Vector3(center + slot_width * 0.5, y0, RETRY_DRAW_MIN.z),"maximum":Vector3(bx1, y1, RETRY_DRAW_MAX.z),"bevel":0.005,"role":"arrow_row_right"})


func _save_mesh(path: String, mesh: ArrayMesh, revision: String) -> bool:
	if not path.begins_with(A3_OUTPUT_ROOT) or FileAccess.file_exists(path) or ResourceSaver.save(mesh, path) != OK:
		error = "Own NEW A3 mesh save/overwrite refused: " + path
		return false
	var reloaded: ArrayMesh = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var readback: Dictionary = _measure(reloaded) if reloaded != null else {}
	if readback.is_empty() or not _same_geometry_arrays(geometry["wall"], readback) or not _validate_retry_support_geometry(reloaded):
		error = "Saved A3 mesh failed exact authored-array/support readback."
		return false
	var dependencies: Array[String] = []
	for dependency: String in ResourceLoader.get_dependencies(path):
		for part: String in dependency.split("::"):
			if part.begins_with("res://") and part not in dependencies:
				dependencies.append(part)
	for required: String in [ROCK_DIFFUSE, ROCK_NORMAL, ROCK_ARM, WORN_BLUestone]:
		if required not in dependencies:
			error = "Saved A3 mesh lost registered material dependency: " + required
			return false
	outputs[path] = {"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size(),"revision":revision,"strict_authored_array_readback":true,"resource_dependencies":dependencies}
	return true


func _save_png(path: String, image: Image) -> bool:
	if not path.begins_with(A3_OUTPUT_ROOT) or FileAccess.file_exists(path) or image.save_png(path) != OK:
		error = "Own NEW A3 PNG save/overwrite refused: " + path
		return false
	var readback: Image = Image.load_from_file(path)
	if readback == null:
		error = "A3 PNG readback failed for " + path
		return false
	readback.convert(Image.FORMAT_RGBA8)
	if readback.get_size() != image.get_size() or readback.get_data() != image.get_data():
		error = "A3 PNG readback differs for " + path
		return false
	outputs[path] = {"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size(),"rgba_sha256":_hash(image.get_data()),"size_px":[image.get_width(),image.get_height()],"lossless_readback_exact":true}
	return true


func _a3_consumer_entry(capture: Dictionary) -> Dictionary:
	return {"asset_id":"luoyang_gate_wall_refined_ashlar_v3_a","mesh_path":A3_OUTPUTS.wall_mesh,"mesh_sha256":outputs[A3_OUTPUTS.wall_mesh]["sha256"],"texture_path":A3_OUTPUTS.wall_png,"texture_sha256":outputs[A3_OUTPUTS.wall_png]["sha256"],"texture_bytes":outputs[A3_OUTPUTS.wall_png]["bytes"],"render_size_px":capture.crop_size_px,"foot_uv":capture.foot_uv,"foot_anchor_px":capture.foot_anchor_px,"support_polygon_px":capture.actual_min_y_support_polygon_px,"ground_y_definition":"For candidate ground_y=500, place texture top-left at [world_x-foot_anchor_px.x,500-foot_anchor_px.y]; translate support_polygon_px by the same top-left. Art placement only; not collision/Field approval.","source_catalog_key":"source_catalog.sha256_by_res_path"}


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
		error = "Read-only source input changed during A3 capture."
	if bridge == null or bridge.call("is_checkpoint_saves_suspended") != true:
		passed = false
		error = "Checkpoint suspension did not remain active through A3 capture."
	if bridge != null and bridge.has_method("set_checkpoint_saves_suspended"):
		bridge.call("set_checkpoint_saves_suspended", false)
	checkpoint_guard["restored_before_quit"] = bridge != null and bridge.call("is_checkpoint_saves_suspended") == false
	if checkpoint_guard["restored_before_quit"] != true:
		passed = false
		error = "Checkpoint suspension was not restored before quit."
	var consumer_catalog := {}
	if passed:
		consumer_catalog = {"schema_version":1,"ground_y_reference_world_px":500,"ground_y_definition":"ground_y is the world-space Y assigned to the captured front-centre minimum-mesh-Y foot anchor; not PNG bottom/collision.","source_catalog":{"sha256_by_res_path":inputs_first,"last_readback_sha256_by_res_path":inputs_last,"unchanged":input_changes.is_empty()},"wall":_a3_consumer_entry(geometry["wall_capture"])}
	var report := {
		"status":"A3_REFINED_NATIVE_CANDIDATE_CAPTURED_NOT_FIELD_OR_FORMAL" if passed else "A3_REFINED_CAPTURE_FAILED_NOT_ADOPTED",
		"passed_capture_checks":passed,
		"reason":error,
		"scope":"ONE refined wall A; no tower B, runtime publisher, city layout, Field, Physics, portal, water, NPC, save, audio or formal write",
		"run_tag":run_tag,
		"source_contract":authoring_contract,
		"weathered_parent":{"script_sha256":WEATHER_PARENT_SCRIPT_SHA,"contract_sha256":WEATHER_PARENT_CONTRACT_SHA,"result_sha256":WEATHER_PARENT_RESULT_SHA,"mesh_sha256":WEATHER_PARENT_MESH_SHA,"png_sha256":WEATHER_PARENT_PNG_SHA},
		"inputs_sha256_first":inputs_first,
		"inputs_sha256_last":inputs_last,
		"input_changes":input_changes,
		"outputs":outputs,
		"geometry_and_capture":geometry,
		"offline_comparison":comparison_record,
		"consumer_catalog":consumer_catalog,
		"visual_review":"PENDING_ROOT_ACTUAL_GPU_READBACK",
		"field_or_physics_approved":false,
		"production_or_formal_approved":false,
		"checkpoint_guard":checkpoint_guard,
	}
	if passed:
		var report_file := FileAccess.open(A3_OUTPUTS.result, FileAccess.WRITE)
		if report_file == null:
			passed = false
			error = "Could not create final A3 result."
		else:
			report_file.store_string(JSON.stringify(report, "\t") + "\n")
			report_file.close()
			outputs[A3_OUTPUTS.result] = {"sha256":FileAccess.get_sha256(A3_OUTPUTS.result),"bytes":FileAccess.get_file_as_bytes(A3_OUTPUTS.result).size()}
	if not passed:
		push_error(error)
	quit(0 if passed else 1)
