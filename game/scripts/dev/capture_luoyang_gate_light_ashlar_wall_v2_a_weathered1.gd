extends "res://scripts/dev/capture_luoyang_gate_light_ashlar_wall_v2_a_retry1.gd"

## Final A-only material comparison candidate.
##
## This script copies both passed retry1 surface arrays verbatim and replaces
## only their saved materials.  It does not rebuild geometry or load a city.

const WEATHER_RUN_FLAG := "--capture-luoyang-gate-light-ashlar-wall-v2-a-weathered1"
const WEATHER_OUTPUT_ROOT := "res://art/modules/luoyang_gate_fortification_v2_a_weathered1/"
const WEATHER_AUTHORING_CONTRACT := WEATHER_OUTPUT_ROOT + "source_contract.json"
const WEATHER_OUTPUTS := {
	"wall_mesh": WEATHER_OUTPUT_ROOT + "luoyang_gate_wall_light_ashlar_straight_v2_a_weathered1.res",
	"wall_png": WEATHER_OUTPUT_ROOT + "luoyang_gate_wall_light_ashlar_straight_v2_a_weathered1.png",
	"comparison_png": WEATHER_OUTPUT_ROOT + "luoyang_gate_wall_light_ashlar_v2_a_weathered1_vs_south_gate.png",
	"result": WEATHER_OUTPUT_ROOT + "capture_result.json",
}

const RETRY_SCRIPT := "res://scripts/dev/capture_luoyang_gate_light_ashlar_wall_v2_a_retry1.gd"
const RETRY_SCRIPT_SHA := "b29b70c6b77bf0938fd711515a96a9100f6655f14468ee9b15dc8c37c1ca01eb"
const RETRY_CONTRACT_SHA := "9376ec24c799e0d272b10cd10db84c6fb3385686b49cddbbdff8baddb512e788"
const RETRY_RESULT := RETRY_OUTPUT_ROOT + "capture_result.json"
const RETRY_RESULT_SHA := "41815c493b747d55b0b85f52895b71b3f97106b35634a6f4b82586bce649cf25"
const RETRY_MESH := RETRY_OUTPUTS.wall_mesh
const RETRY_MESH_SHA := "74c213aeb1a000441d6732d0bfa35aab63cd40a90f64a015175c11947f457cc0"
const RETRY_PNG := RETRY_OUTPUTS.wall_png
const RETRY_PNG_SHA := "523551c6d8c1f4404ee89d7b9012cefb668ee4d3058eece661837df830eda08d"
const WORN_BLUestone := "res://art/maps/luoyang_modular_v3/source/worn_bluestone_v2.png"
const WORN_BLUestone_SHA := "7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d"
const WORN_PROVENANCE := "res://art/maps/luoyang_modular_v3/source/generation_record.json"
const WORN_PROVENANCE_SHA := "55c9a621ff125b736db2da85350a208a08f530e81bea1d2c11dc165cf76858c5"

const WEATHERED_SHADER := """
shader_type spatial;
render_mode cull_back, depth_draw_opaque, diffuse_burley, specular_schlick_ggx;

uniform sampler2D rock_diffuse : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D worn_bluestone : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_arm : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 base_tint = vec3(0.62, 0.63, 0.62);
uniform float weather_strength : hint_range(0.0, 1.0) = 1.0;
uniform float normal_strength : hint_range(0.0, 1.0) = 0.38;
uniform float roughness_floor : hint_range(0.0, 1.0) = 0.78;
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
	vec3 rock = texture(rock_diffuse, UV * 1.08 + vec2(0.07, 0.13)).rgb;
	vec3 worn = texture(worn_bluestone, UV * 0.52 + vec2(0.19, 0.09)).rgb;
	vec3 source_colour = mix(worn, rock, 0.46);
	float source_luma = max(dot(source_colour, vec3(0.2126, 0.7152, 0.0722)), 0.08);
	vec3 source_chroma = source_colour / source_luma;
	vec3 mapped = base_tint * mix(vec3(1.0), source_chroma, 0.52 * weather_strength);
	mapped *= mix(1.0, 0.70 + source_luma * 0.62, weather_strength);

	float row = floor(max(local_pos.y, 0.0) * 4.49);
	float stagger = mod(row, 2.0) * 0.5;
	vec2 block_cell = vec2(floor((local_pos.x + 2.5) * 1.60 + stagger), row);
	float block_tone = (hash21(block_cell) - 0.5) * 0.105 * weather_strength;
	mapped *= 1.0 + block_tone;

	float warm_mineral = clamp((rock.r - rock.b) * 1.55, 0.0, 0.22) * weather_strength;
	mapped += vec3(0.085, 0.038, -0.008) * warm_mineral;
	ALBEDO = clamp(mapped, vec3(0.055), vec3(0.92));

	vec3 sampled_normal = texture(rock_normal, UV * 1.08 + vec2(0.07, 0.13)).rgb;
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), sampled_normal, normal_strength);
	NORMAL_MAP_DEPTH = 1.0;
	vec3 arm = texture(rock_arm, UV * 1.08 + vec2(0.07, 0.13)).rgb;
	AO = mix(1.0, arm.r, ao_strength);
	ROUGHNESS = mix(roughness_floor, 0.97, arm.g);
	METALLIC = 0.0;
	SPECULAR = 0.16;
}
"""


func _start() -> void:
	# First deferred action and strictly before the first await.
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"):
		_fail_now("Weathered A capture requires public checkpoint suspension; no fallback.")
		return
	bridge.call("set_checkpoint_saves_suspended", true)
	if bridge.call("is_checkpoint_saves_suspended") != true:
		_fail_now("Checkpoint suspension was not verified before weathered A authoring.")
		return
	checkpoint_guard = {"public_api":"PlatformBridge.set_checkpoint_saves_suspended(true)","before_first_await":true,"verified_suspended":true,"restored_before_quit":false}

	var args: PackedStringArray = OS.get_cmdline_user_args()
	var run_tag := ""
	for arg: String in args:
		if arg.begins_with("--capture-run-tag="):
			run_tag = arg.trim_prefix("--capture-run-tag=")
	var tag_rule := RegEx.new()
	if WEATHER_RUN_FLAG not in args or tag_rule.compile("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$") != OK or tag_rule.search(run_tag) == null:
		_fail_now("Explicit weathered1 flag and a safe unique --capture-run-tag are required.")
		return
	if DisplayServer.get_name() == "headless":
		_fail_now("Transparent native GPU capture refuses a headless display server.")
		return
	for path: String in WEATHER_OUTPUTS.values():
		if FileAccess.file_exists(path):
			_fail_now("Refusing to overwrite an existing weathered1 output: " + path)
			return

	if not (
		_track(get_script().resource_path)
		and _track(RETRY_SCRIPT, RETRY_SCRIPT_SHA)
		and _track(RETRY_AUTHORING_CONTRACT, RETRY_CONTRACT_SHA)
		and _track(RETRY_RESULT, RETRY_RESULT_SHA)
		and _track(RETRY_MESH, RETRY_MESH_SHA)
		and _track(RETRY_PNG, RETRY_PNG_SHA)
		and _track(BASE_CAPTURE_SCRIPT, BASE_CAPTURE_SCRIPT_SHA)
		and _track(WEATHER_AUTHORING_CONTRACT)
		and _track(V1_RESULT, V1_RESULT_SHA)
		and _track(SOURCE_CONTRACT, SOURCE_CONTRACT_SHA)
	):
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
	var author_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(WEATHER_AUTHORING_CONTRACT))
	if not author_value is Dictionary or author_value.get("asset_pack") != "luoyang_gate_fortification_v2_a_weathered1" or author_value.get("status") != "SOURCE_AUTHORED_CAPTURE_PENDING":
		_fail_now("Exact pending weathered1 source contract is required.")
		return
	authoring_contract = author_value

	if not _bound(ROCK_SOURCE) or not _track_imported_texture(ROCK_DIFFUSE) or not _track_imported_texture(ROCK_NORMAL) or not _track_imported_texture(ROCK_ARM) or not _track_imported_texture(GATE_TEXTURE):
		_fail_now(error)
		return
	if not _bound(WORN_BLUestone) or inputs_first[WORN_BLUestone] != WORN_BLUestone_SHA or not _track_imported_texture(WORN_BLUestone):
		_fail_now(error if error != "" else "Bound worn bluestone source mismatch.")
		return
	if not _bound(WORN_PROVENANCE) or inputs_first[WORN_PROVENANCE] != WORN_PROVENANCE_SHA:
		_fail_now(error if error != "" else "Bound worn bluestone provenance mismatch.")
		return

	var retry_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(RETRY_RESULT))
	var v1_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(V1_RESULT))
	if not retry_value is Dictionary or retry_value.get("passed_capture_checks", false) != true:
		_fail_now("Pinned retry1 actual capture is unavailable or not passed.")
		return
	if not v1_value is Dictionary or not _validate_actual_v1_baseline(v1_value):
		_fail_now(error if error != "" else "Pinned actual v1 baseline mismatch.")
		return
	var source_wall: ArrayMesh = ResourceLoader.load(RETRY_MESH, "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if source_wall == null or source_wall.get_surface_count() != 2:
		_fail_now("Pinned retry1 wall mesh must contain exactly two surfaces.")
		return
	var source_measure: Dictionary = _measure(source_wall)
	if source_measure.is_empty() or not _measure_matches_source_bounds(source_measure) or not _validate_retry_support_geometry(source_wall):
		_fail_now(error if error != "" else "Pinned retry1 geometry failed readback.")
		return

	var stone_material: ShaderMaterial = _make_ashlar_material(Color(0.64, 0.635, 0.61), 1.0, 0.38, 0.79)
	var mortar_material: ShaderMaterial = _make_ashlar_material(Color(0.34, 0.335, 0.32), 0.42, 0.14, 0.90)
	if stone_material == null or mortar_material == null:
		_fail_now(error if error != "" else "Could not build weathered ashlar materials.")
		return
	var wall: ArrayMesh = source_wall.duplicate(false) as ArrayMesh
	wall.surface_set_material(0, mortar_material)
	wall.surface_set_material(1, stone_material)
	var wall_measure: Dictionary = _measure(wall)
	if wall_measure.is_empty() or not _same_geometry_arrays(source_measure, wall_measure) or not _validate_retry_support_geometry(wall):
		_fail_now(error if error != "" else "Material-only copy changed retry1 geometry arrays/support.")
		return
	geometry["retry1_source_wall"] = source_measure
	geometry["wall"] = wall_measure
	geometry["geometry_arrays_byte_identical_to_retry1"] = true

	var wall_capture: Dictionary = await _capture(wall, "light_ashlar_wall_v2_a_weathered1")
	if wall_capture.is_empty():
		await _finish(false, run_tag, bridge)
		return
	geometry["wall_capture"] = wall_capture
	var wall_size := Vector2i(wall_capture.crop_size_px[0], wall_capture.crop_size_px[1])
	print(JSON.stringify({"event":"gate_light_ashlar_v2_a_weathered1_capture_measurement","crop_size_px":wall_capture.crop_size_px,"foot_uv":wall_capture.foot_uv,"foot_anchor_px":wall_capture.foot_anchor_px}))
	if wall_size != Vector2i(656, 280):
		error = "Weathered1 actual crop must remain exactly the passed retry1 656x280; guard was not widened."
		await _finish(false, run_tag, bridge)
		return
	var v1_geometry: Dictionary = v1_value.get("geometry_and_capture", {})
	var v1_capture: Dictionary = v1_geometry.get("straight_capture", {})
	if not _foot_is_preserved(wall_capture, v1_capture):
		error = "Weathered1 foot anchor exceeds the unchanged <=3 px v1 guard."
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
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(WEATHER_OUTPUT_ROOT)) != OK:
		error = "Cannot create the isolated weathered1 candidate directory."
		await _finish(false, run_tag, bridge)
		return
	if not _save_mesh(WEATHER_OUTPUTS.wall_mesh, wall, "Material-only child of passed retry1; exact two surface arrays/support, new registered rock+worn-bluestone weathering only"):
		await _finish(false, run_tag, bridge)
		return
	if not _save_png(WEATHER_OUTPUTS.wall_png, wall_image) or not _save_png(WEATHER_OUTPUTS.comparison_png, comparison_image):
		await _finish(false, run_tag, bridge)
		return
	await _finish(true, run_tag, bridge)


func _make_ashlar_material(tint: Color, weather_strength: float, normal_strength: float, roughness_floor: float) -> ShaderMaterial:
	var diffuse: Texture2D = ResourceLoader.load(ROCK_DIFFUSE, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var worn: Texture2D = ResourceLoader.load(WORN_BLUestone, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var normal: Texture2D = ResourceLoader.load(ROCK_NORMAL, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var arm: Texture2D = ResourceLoader.load(ROCK_ARM, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if diffuse == null or worn == null or normal == null or arm == null:
		error = "Registered rock/worn-bluestone textures did not load."
		return null
	var shader := Shader.new()
	shader.code = WEATHERED_SHADER
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


func _same_geometry_arrays(source_measure: Dictionary, child_measure: Dictionary) -> bool:
	for key: String in ["surface_count", "triangles", "minimum_m", "maximum_m"]:
		if source_measure.get(key) != child_measure.get(key):
			error = "Material-only child changed retry1 geometry measure: " + key
			return false
	var source_surfaces: Array = source_measure.get("surfaces", [])
	var child_surfaces: Array = child_measure.get("surfaces", [])
	if source_surfaces.size() != child_surfaces.size():
		error = "Material-only child changed retry1 surface count."
		return false
	for index in range(source_surfaces.size()):
		for key: String in ["surface", "vertices", "indices", "arrays_sha256"]:
			if source_surfaces[index].get(key) != child_surfaces[index].get(key):
				error = "Material-only child changed retry1 surface array identity."
				return false
	return true


func _save_mesh(path: String, mesh: ArrayMesh, revision: String) -> bool:
	if not path.begins_with(WEATHER_OUTPUT_ROOT) or FileAccess.file_exists(path) or ResourceSaver.save(mesh, path) != OK:
		error = "Own NEW weathered1 mesh save/overwrite refused: " + path
		return false
	var reloaded: ArrayMesh = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var parent: ArrayMesh = ResourceLoader.load(RETRY_MESH, "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var readback: Dictionary = _measure(reloaded) if reloaded != null else {}
	var parent_measure: Dictionary = _measure(parent) if parent != null else {}
	if readback.is_empty() or parent_measure.is_empty() or not _same_geometry_arrays(parent_measure, readback) or not _validate_retry_support_geometry(reloaded):
		error = "Saved weathered1 mesh failed exact retry1 geometry/support readback."
		return false
	var dependencies: Array[String] = []
	for dependency: String in ResourceLoader.get_dependencies(path):
		for part: String in dependency.split("::"):
			if part.begins_with("res://") and part not in dependencies:
				dependencies.append(part)
	for required: String in [ROCK_DIFFUSE, ROCK_NORMAL, ROCK_ARM, WORN_BLUestone]:
		if required not in dependencies:
			error = "Saved weathered1 mesh lost registered material dependency: " + required
			return false
	outputs[path] = {"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size(),"revision":revision,"geometry_arrays_byte_identical_to_retry1":true,"resource_dependencies":dependencies}
	return true


func _save_png(path: String, image: Image) -> bool:
	if not path.begins_with(WEATHER_OUTPUT_ROOT) or FileAccess.file_exists(path) or image.save_png(path) != OK:
		error = "Own NEW weathered1 PNG save/overwrite refused: " + path
		return false
	var readback: Image = Image.load_from_file(path)
	if readback == null:
		error = "Weathered1 PNG readback failed for " + path
		return false
	readback.convert(Image.FORMAT_RGBA8)
	if readback.get_size() != image.get_size() or readback.get_data() != image.get_data():
		error = "Weathered1 PNG readback differs for " + path
		return false
	outputs[path] = {"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size(),"rgba_sha256":_hash(image.get_data()),"size_px":[image.get_width(),image.get_height()],"lossless_readback_exact":true}
	return true


func _weather_consumer_entry(capture: Dictionary) -> Dictionary:
	return {"asset_id":"luoyang_gate_wall_light_ashlar_straight_v2_a_weathered1","mesh_path":WEATHER_OUTPUTS.wall_mesh,"mesh_sha256":outputs[WEATHER_OUTPUTS.wall_mesh]["sha256"],"texture_path":WEATHER_OUTPUTS.wall_png,"texture_sha256":outputs[WEATHER_OUTPUTS.wall_png]["sha256"],"texture_bytes":outputs[WEATHER_OUTPUTS.wall_png]["bytes"],"render_size_px":capture.crop_size_px,"foot_uv":capture.foot_uv,"foot_anchor_px":capture.foot_anchor_px,"support_polygon_px":capture.actual_min_y_support_polygon_px,"ground_y_definition":"For candidate ground_y=500, place texture top-left at [world_x-foot_anchor_px.x,500-foot_anchor_px.y]; translate support_polygon_px by the same top-left. Art placement only; not collision/Field approval.","source_catalog_key":"source_catalog.sha256_by_res_path"}


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
		error = "Read-only source input changed during weathered1 capture."
	if bridge == null or bridge.call("is_checkpoint_saves_suspended") != true:
		passed = false
		error = "Checkpoint suspension did not remain active through weathered1 capture."
	if bridge != null and bridge.has_method("set_checkpoint_saves_suspended"):
		bridge.call("set_checkpoint_saves_suspended", false)
	checkpoint_guard["restored_before_quit"] = bridge != null and bridge.call("is_checkpoint_saves_suspended") == false
	if checkpoint_guard["restored_before_quit"] != true:
		passed = false
		error = "Checkpoint suspension was not restored before quit."
	var consumer_catalog := {}
	if passed:
		consumer_catalog = {"schema_version":1,"ground_y_reference_world_px":500,"ground_y_definition":"ground_y is the world-space Y assigned to the captured front-centre minimum-mesh-Y foot anchor; not PNG bottom/collision.","source_catalog":{"sha256_by_res_path":inputs_first,"last_readback_sha256_by_res_path":inputs_last,"unchanged":input_changes.is_empty()},"wall":_weather_consumer_entry(geometry["wall_capture"])}
	var report := {
		"status":"A_ONLY_WEATHERED1_NATIVE_CANDIDATE_CAPTURED_NOT_FIELD_OR_FORMAL" if passed else "A_ONLY_WEATHERED1_CAPTURE_FAILED_NOT_ADOPTED",
		"passed_capture_checks":passed,
		"reason":error,
		"scope":"ONE material-only A comparison candidate; no tower B, runtime publisher, city layout, Field, Physics, portal, bridge, water, NPC, save, audio or formal write",
		"run_tag":run_tag,
		"source_contract":authoring_contract,
		"passed_retry1_parent":{"script_sha256":RETRY_SCRIPT_SHA,"contract_sha256":RETRY_CONTRACT_SHA,"result_sha256":RETRY_RESULT_SHA,"mesh_sha256":RETRY_MESH_SHA,"transparent_png_sha256":RETRY_PNG_SHA,"actual_crop_px":[656,280],"actual_foot_anchor_px":[328.0,272.3623046875]},
		"material_revision":{"geometry_or_uv_change":false,"source_chroma_and_luminance_used":true,"worn_bluestone_cracks_used":true,"per_block_tone_variation":true,"restrained_warm_mineral_variation":true,"bitmap_modified_or_stretched":false},
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
		var report_file := FileAccess.open(WEATHER_OUTPUTS.result, FileAccess.WRITE)
		if report_file == null:
			passed = false
			error = "Could not create final weathered1 result."
		else:
			report_file.store_string(JSON.stringify(report, "\t") + "\n")
			report_file.close()
			outputs[WEATHER_OUTPUTS.result] = {"sha256":FileAccess.get_sha256(WEATHER_OUTPUTS.result),"bytes":FileAccess.get_file_as_bytes(WEATHER_OUTPUTS.result).size()}
	if not passed:
		push_error(error)
	quit(0 if passed else 1)
