extends "res://scripts/dev/diagnose_world_v15_whole_framebuffer_memory.gd"
## NEW limited transport fixture, not terrain/64-chunk/reference approval.
## Whole GPU primary is never passed to get_image(). Only small targets are.
const TRANSFER_ROOT := "res://build/world_map_v15_native_texel_transfer/"
const TRANSFER_SHADER := "res://shaders/world_v15_native_texel_transfer.gdshader"
const MEMORY_SOURCE := "res://scripts/dev/diagnose_world_v15_whole_framebuffer_memory.gd"
const MEMORY_SOURCE_SHA := "fa4a63b9e3413362e0eb14b3de97556fc4ddb82a9c1fa25f5ab06bbc4306c26a"
const HISTORICAL_RESULT := "res://build/world_map_v15_whole_framebuffer_memory/1791062610_2434323/result.json"
const HISTORICAL_RESULT_SHA := "635f79565e1258f077c47ab53ed5e22c235921896c48079dbdc695b5859cd6fe"
const HISTORICAL_SQUARE_PNG := "res://build/world_map_v15_whole_framebuffer_memory/1791062610_2434323/native_8192x8192_raw.png"
const HISTORICAL_SQUARE_REPEAT := "res://build/world_map_v15_whole_framebuffer_memory/1791062610_2434323/native_8192x8192_raw_repeat.png"
const HISTORICAL_SQUARE_PNG_SHA := "d9a06a25a2bd0394d86a2ba246cafe6b5229f8d64f0b0751277da131348a97e5"
const SMALL := Vector2i(3072, 2048)
const TRANSFER_SCOPE := "NATIVE_INTEGER_GPU_TRANSFER_NOT_TERRAIN_OR_PROTOCOL_APPROVAL"
const PATTERN_CODE := """shader_type spatial;
render_mode unshaded, cull_disabled;
void fragment() {
 vec2 p = floor(UV * vec2(769.0, 513.0));
 ALBEDO = vec3(mod(p.x, 256.0), mod(p.y, 256.0), mod(p.x * 7.0 + p.y * 13.0, 256.0)) / 255.0;
}
"""
var _transfer_view: SubViewport
var _camera: Camera3D
var _pattern: Shader
var _transport: Shader
var _world_node: Node3D
var _completed_post_draw_fences := 0

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--verify-world-v15-native-texel-transfer" not in args or DisplayServer.get_name() == "headless":
		push_error("Explicit native-transfer GPU fixture flag required; no headless allocation.")
		await _finish(2)
		return
	output = TRANSFER_ROOT + "%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) != OK:
		await _finish(1)
		return
	var result: Dictionary = {
		"schema_version": 1, "scope": TRANSFER_SCOPE,
		"executed_fixture_path": get_script().resource_path,
		"executed_fixture_sha256": FileAccess.get_sha256(get_script().resource_path),
		"memory_fixture": {"path": MEMORY_SOURCE, "sha256": FileAccess.get_sha256(MEMORY_SOURCE)},
		"caps_fixture": {"path": PARENT_PATH, "sha256": FileAccess.get_sha256(PARENT_PATH)},
		"transfer_shader": {"path": TRANSFER_SHADER, "sha256": FileAccess.get_sha256(TRANSFER_SHADER)},
		"pattern_shader_code": PATTERN_CODE, "pattern_shader_code_sha256": PATTERN_CODE.sha256_text(),
		"engine_pid": OS.get_process_id(), "godot_version": Engine.get_version_info(),
		"display_server": DisplayServer.get_name(),
		"configured_renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method", "UNKNOWN"),
		"whole_requested": "--allow-whole-native-transfer" in args,
		"whole_gpu_allocated": false, "whole_cpu_image_requested": false,
		"terrain_or_capture_protocol_approved": false, "formal_adoption_approved": false,
		"zero_tolerance": true, "cpu_color_correction": false, "gamma_compensation": false,
		"filter_resize_or_ssaa_downgrade": false,
		"gl_enumerated_limits_known": false,
		"repeat_scope": "second actual render of same diagnostic 3D world; NOT independent terrain reference capture"
	}
	for method: String in ["get_video_adapter_name", "get_video_adapter_vendor", "get_video_adapter_api_version"]:
		if RenderingServer.has_method(method): result[method] = RenderingServer.call(method)
	if result.configured_renderer != "gl_compatibility" or FileAccess.get_sha256(MEMORY_SOURCE) != MEMORY_SOURCE_SHA or FileAccess.get_sha256(PARENT_PATH) != PARENT_SHA:
		await _transfer_finish(result, "REFUSED_BACKEND_OR_PARENT_SOURCE", 2)
		return
	_transport = load(TRANSFER_SHADER) as Shader
	if _transport == null or _transport.code != FileAccess.get_file_as_string(TRANSFER_SHADER):
		await _transfer_finish(result, "REFUSED_LITERAL_TRANSFER_SHADER", 2)
		return
	var baseline: Dictionary = _memory_snapshot("before_stage_A")
	result["baseline"] = baseline
	if not bool(baseline.get("valid", false)) or int(baseline.get("vram_free_bytes", 0)) < GIB or int(baseline.get("host_free_bytes", 0)) < 2 * GIB:
		await _transfer_finish(result, "REFUSED_SMALL_MEMORY_OR_QUERY", 2)
		return
	var stage_a: Dictionary = await _stage(SMALL, true)
	result["stage_A"] = stage_a
	if not bool(stage_a.get("passed", false)):
		await _transfer_finish(result, "STAGE_A_EXACT_TRANSPORT_FAILED", 1)
		return
	if not bool(result.whole_requested):
		await _transfer_finish(result, "STAGE_A_PASS_WHOLE_NOT_REQUESTED", 0)
		return
	# ROOT078 overall remains OS1/whole Image-cap FAIL. Only its independently
	# successful square component is bound here, never treated as whole success.
	var history: Dictionary = _historical_square()
	result["historical_square_component"] = history
	var guard: Dictionary = _memory_snapshot("fresh_before_whole_transfer_guard")
	result["whole_guard"] = guard
	var metrics: Dictionary = history.get("deltas", {})
	var estimate: Dictionary = {
		"method": "bound actual ROOT078 square peak deltas times six; minimum 8GiB RAM",
		"pixel_ratio": 6, "vram_estimate_bytes": int(metrics.get("vram_peak_delta_bytes", 0)) * 6,
		"vram_headroom_bytes": GIB,
		"ram_requirement_bytes": maxi(8 * GIB, int(metrics.get("process_peak_delta_bytes", 0)) * 6)
	}
	result["whole_estimate"] = estimate
	var safe: bool = bool(history.get("valid", false)) and bool(guard.get("valid", false)) and guard.get("gpu_uuid") == history.get("gpu_uuid") and int(guard.get("vram_free_bytes", 0)) >= int(estimate.vram_estimate_bytes) + GIB and int(guard.get("host_free_bytes", 0)) >= int(estimate.ram_requirement_bytes)
	result["whole_guard_passed"] = safe
	if not safe:
		await _transfer_finish(result, "REFUSED_WHOLE_GUARD_NO_DOWNGRADE", 2)
		return
	var stage_b: Dictionary = await _stage(WHOLE, false)
	result["stage_B"] = stage_b
	result["whole_gpu_allocated"] = bool(stage_b.get("primary_allocated", false))
	await _transfer_finish(result, "SMALL_ORACLE_AND_WHOLE_WINDOW_PASS" if bool(stage_b.get("passed", false)) else "WHOLE_WINDOW_TRANSFER_FAILED", 0 if bool(stage_b.get("passed", false)) else 1)

func _historical_square() -> Dictionary:
	var record: Dictionary = {"valid": false, "result_path": HISTORICAL_RESULT, "result_sha256": FileAccess.get_sha256(HISTORICAL_RESULT), "overall_historical_status": "WHOLE_FRAMEBUFFER_ACTUAL_FAILED", "overall_historical_OS_result_not_overridden": 1}
	record["actual_square_png_sha256"] = FileAccess.get_sha256(HISTORICAL_SQUARE_PNG)
	record["actual_square_repeat_png_sha256"] = FileAccess.get_sha256(HISTORICAL_SQUARE_REPEAT)
	record["expected_result_sha256"] = HISTORICAL_RESULT_SHA
	record["expected_square_png_sha256"] = HISTORICAL_SQUARE_PNG_SHA
	if record.result_sha256 != HISTORICAL_RESULT_SHA or FileAccess.get_sha256(HISTORICAL_SQUARE_PNG) != HISTORICAL_SQUARE_PNG_SHA or FileAccess.get_sha256(HISTORICAL_SQUARE_REPEAT) != HISTORICAL_SQUARE_PNG_SHA:
		record["reason"] = "Historical actual result or square PNG byte SHA mismatch"
		return record
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(HISTORICAL_RESULT))
	record["parsed_result_variant_type"] = typeof(parsed)
	if not parsed is Dictionary:
		record["reason"] = "Historical result JSON is not Dictionary"
		return record
	var report: Dictionary = parsed
	record["actual_historical_execution"] = {"fixture_sha256": report.get("executed_fixture_sha256"), "parent_sha256": report.get("parent_fixture_sha256"), "status": report.get("status"), "proposed_exit_code": report.get("proposed_exit_code_not_external_OS_evidence"), "proposed_exit_code_variant_type": typeof(report.get("proposed_exit_code_not_external_OS_evidence"))}
	if report.get("executed_fixture_sha256") != MEMORY_SOURCE_SHA or report.get("parent_fixture_sha256") != PARENT_SHA or report.get("status") != "WHOLE_FRAMEBUFFER_ACTUAL_FAILED" or report.get("proposed_exit_code_not_external_OS_evidence") != 1:
		record["reason"] = "Historical execution source/status/proposed exit identity mismatch"
		return record
	var square: Dictionary = report.get("square", {})
	var actual_canvas: Variant = square.get("actual_raw_canvas")
	var canvas_types: Array[int] = []
	if actual_canvas is Array:
		for component: Variant in actual_canvas: canvas_types.append(typeof(component))
	record["actual_square_flags_and_canvas"] = {"passed": square.get("passed"), "actual_viewport_node_released": square.get("actual_viewport_node_released"), "raw_repeat_byte_exact": square.get("raw_repeat_byte_exact"), "actual_raw_canvas": actual_canvas, "actual_canvas_variant_type": typeof(actual_canvas), "actual_canvas_component_variant_types": canvas_types, "expected_native_canvas": [8192, 8192], "expected_native_canvas_component_variant_type": TYPE_INT, "existing_array_comparison_equal": actual_canvas == [8192, 8192]}
	var canvas_semantics_exact: bool = actual_canvas is Array and actual_canvas.size() == 2
	if canvas_semantics_exact:
		for component: Variant in actual_canvas:
			canvas_semantics_exact = canvas_semantics_exact and typeof(component) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(component)) and float(component) == 8192.0
	record["actual_square_flags_and_canvas"]["exact_numeric_canvas_semantics"] = canvas_semantics_exact
	if not bool(square.get("passed", false)) or not bool(square.get("actual_viewport_node_released", false)) or not canvas_semantics_exact or not bool(square.get("raw_repeat_byte_exact", false)):
		record["reason"] = "Historical square passed/released/native canvas/repeat predicate refused"
		return record
	var images: Array = square.get("images", [])
	record["actual_square_image_records"] = images.duplicate(true)
	if images.size() != 2 or images[0].get("path") != HISTORICAL_SQUARE_PNG or images[1].get("path") != HISTORICAL_SQUARE_REPEAT:
		record["reason"] = "Historical square actual image record count/path identity mismatch"
		return record
	for image_record: Dictionary in images:
		if image_record.get("sha256") != HISTORICAL_SQUARE_PNG_SHA:
			record["reason"] = "Historical square image record SHA identity mismatch"
			record["refused_image_record"] = image_record.duplicate(true)
			return record
	var deltas: Dictionary = _memory_deltas(square)
	var stored_deltas: Variant = report.get("square_measured_deltas")
	var computed_types: Dictionary = {}
	var stored_types: Dictionary = {}
	for key: String in deltas: computed_types[key] = typeof(deltas[key])
	if stored_deltas is Dictionary:
		for key: String in stored_deltas: stored_types[key] = typeof(stored_deltas[key])
	record["actual_computed_square_deltas"] = deltas.duplicate(true)
	record["actual_stored_square_deltas"] = stored_deltas
	record["computed_delta_variant_types"] = computed_types
	record["stored_delta_variant_types"] = stored_types
	record["existing_dictionary_comparison_equal"] = deltas == stored_deltas
	var delta_semantics_exact: bool = stored_deltas is Dictionary and stored_deltas.size() == deltas.size()
	if delta_semantics_exact:
		for key: String in deltas:
			if not stored_deltas.has(key):
				delta_semantics_exact = false
				break
			var expected: Variant = deltas[key]
			var actual: Variant = stored_deltas[key]
			if typeof(expected) == TYPE_BOOL:
				delta_semantics_exact = delta_semantics_exact and typeof(actual) == TYPE_BOOL and actual == expected
			elif typeof(expected) == TYPE_INT:
				delta_semantics_exact = delta_semantics_exact and typeof(actual) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(actual)) and float(actual) == floorf(float(actual)) and float(actual) == float(expected)
			else:
				delta_semantics_exact = false
	record["exact_numeric_and_boolean_delta_semantics"] = delta_semantics_exact
	if not bool(deltas.get("valid", false)) or not delta_semantics_exact:
		record["reason"] = "Historical recomputed square delta validity or exact Dictionary predicate refused"
		return record
	record["valid"] = true
	record["square_images"] = images
	record["historical_execution_source"] = {"path": MEMORY_SOURCE, "sha256": MEMORY_SOURCE_SHA, "parent_path": PARENT_PATH, "parent_sha256": PARENT_SHA}
	record["gpu_uuid"] = square.baseline.gpu_uuid
	record["deltas"] = deltas
	return record

func _make_primary(size: Vector2i) -> void:
	active_view = SubViewport.new()
	active_view.size = size
	active_view.own_world_3d = true
	active_view.msaa_3d = Viewport.MSAA_DISABLED
	active_view.msaa_2d = Viewport.MSAA_DISABLED
	active_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(active_view)
	_world_node = Node3D.new()
	active_view.add_child(_world_node)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0, 0, 0, 1)
	environment.environment = settings
	_world_node.add_child(environment)
	var width: float = 2.0 * float(size.x) / float(size.y)
	var colors: Array[Color] = [Color(.8, .03, .03, 1), Color(.03, .8, .03, 1), Color(.03, .03, .8, 1), Color(.8, .8, .03, 1)]
	for index in 4:
		_axis_quad(_world_node, Vector2(width * .5, 1.0), Vector3((-1.0 if index % 2 == 0 else 1.0) * width * .25, .5 if index < 2 else -.5, 0), colors[index])
	_axis_quad(_world_node, Vector2(width * .2, .4), Vector3(0, 0, .01), Color(.8, .03, .8, 1))
	# Non-symmetric multi-level RGB proves more than only uniform color tiles.
	_pattern = Shader.new()
	_pattern.code = PATTERN_CODE
	var pattern_material := ShaderMaterial.new()
	pattern_material.shader = _pattern
	var pattern_mesh := QuadMesh.new()
	pattern_mesh.size = Vector2(width * .31, .61)
	var pattern_node := MeshInstance3D.new()
	pattern_node.mesh = pattern_mesh
	pattern_node.material_override = pattern_material
	pattern_node.position = Vector3(-width * .22, .23, .02)
	pattern_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world_node.add_child(pattern_node)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.size = 2.0
	_camera.position = Vector3(0, 0, 10)
	_world_node.add_child(_camera)
	_camera.current = true

func _render_primary(pass_id: String) -> Dictionary:
	var before: int = Engine.get_frames_drawn()
	var process_before: int = Engine.get_process_frames()
	var fences: Array[Dictionary] = []
	# Hidden root windows may leave Engine.get_frames_drawn() at zero. Keep
	# that raw counter honest; identity is the actually awaited signal order.
	# Each pass issues fresh UPDATE_ONCE requests, never merely rereads a PNG.
	for tick in 8:
		var tick_process_before: int = Engine.get_process_frames()
		var tick_draw_before: int = Engine.get_frames_drawn()
		active_view.render_target_update_mode = SubViewport.UPDATE_ONCE
		await process_frame
		await RenderingServer.frame_post_draw
		_completed_post_draw_fences += 1
		fences.append({"fence_sequence": _completed_post_draw_fences, "process_frame_before": tick_process_before, "process_frame_after": Engine.get_process_frames(), "engine_draw_frame_before": tick_draw_before, "engine_draw_frame_after": Engine.get_frames_drawn(), "ticks_usec": Time.get_ticks_usec(), "requested_primary_update_mode": SubViewport.UPDATE_ONCE})
	active_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var after: int = Engine.get_frames_drawn()
	var process_after: int = Engine.get_process_frames()
	var record: Dictionary = {"id": pass_id, "frame_before": before, "frame_after": after, "engine_draw_counter_advanced": after > before, "process_frame_before": process_before, "process_frame_after": process_after, "post_draw_fences": fences, "last_post_draw_fence_sequence": _completed_post_draw_fences, "fresh_draw_observed": false, "ticks_usec": Time.get_ticks_usec(), "capture_identity_method": "actual eight natural process/frame_post_draw signal fences after UPDATE_ONCE requests; Engine draw counter growth is NOT asserted; actual image witnesses still required"}
	var effective_world: World3D = active_view.find_world_3d()
	if effective_world == null:
		record["reason"] = "Actual effective World3D unavailable after primary draw; no readback/transfer credit"
		return record
	var texture: ViewportTexture = active_view.get_texture()
	record.merge({"fresh_draw_observed": fences.size() == 8 and process_after > process_before, "primary_texture_rid": texture.get_rid().get_id(), "primary_texture_instance_id": texture.get_instance_id(), "primary_viewport_rid": active_view.get_viewport_rid().get_id(), "primary_viewport_instance_id": active_view.get_instance_id(), "world_3d_instance_id": effective_world.get_instance_id(), "world_node_instance_id": _world_node.get_instance_id(), "camera_instance_id": _camera.get_instance_id(), "primary_canvas": [active_view.size.x, active_view.size.y], "primary_frozen_update_mode": active_view.render_target_update_mode, "camera": {"projection": _camera.projection, "keep_aspect": _camera.keep_aspect, "size": _camera.size, "transform": _transform_record(_camera.global_transform)}, "msaa_3d": active_view.msaa_3d, "msaa_2d": active_view.msaa_2d, "pattern_shader_code_sha256": _pattern.code.sha256_text()}, true)
	return record

func _stage(size: Vector2i, direct_oracle: bool) -> Dictionary:
	var name: String = "stage_A" if direct_oracle else "stage_B"
	var record: Dictionary = {"scope": TRANSFER_SCOPE, "name": name, "primary_canvas": [size.x, size.y], "passed": false, "primary_allocated": false, "whole_primary_cpu_readback": false, "direct_oracle_available": direct_oracle, "transfers": [], "passes": []}
	record["baseline"] = _memory_snapshot(name + "_before_primary")
	if not bool(record.baseline.get("valid", false)):
		record["refusal"] = "fresh stage baseline query unavailable; no allocation"
		return record
	_make_primary(size)
	var windows: Array[Rect2i] = _windows(size, direct_oracle)
	var first_direct: Image
	var first_transfer_paths: Array[String] = []
	var all_passed := true
	for pass_index in 2:
		var pass_record: Dictionary = await _render_primary(name + "_primary_pass_" + str(pass_index + 1))
		record.passes.append(pass_record)
		record["primary_allocated"] = true
		all_passed = all_passed and bool(pass_record.fresh_draw_observed)
		if not bool(pass_record.fresh_draw_observed):
			record["refusal"] = str(pass_record.get("reason", "Actual primary draw not observed"))
			break
		var allocated: Dictionary = _memory_snapshot(name + "_primary_pass_%d_before_transfer" % (pass_index + 1))
		if pass_index == 0: record["allocated"] = allocated
		if not bool(allocated.get("valid", false)) or allocated.get("gpu_uuid") != record.baseline.get("gpu_uuid") or int(allocated.get("host_free_bytes", 0)) < (2 * GIB if direct_oracle else 8 * GIB):
			record["refusal"] = "actual primary allocation query/RAM guard failed"
			all_passed = false
			break
		var oracle: Image
		if direct_oracle:
			# This branch is exclusively 3072x2048; the whole primary never enters it.
			if size != SMALL:
				all_passed = false
				break
			oracle = active_view.get_texture().get_image()
			if not _rgba_native(oracle, size):
				record["refusal"] = "direct small oracle was not native RGBA8; no format conversion"
				all_passed = false
				break
			var direct_path: String = output + name + "_direct_pass_%d.png" % (pass_index + 1)
			var direct_info: Dictionary = _save_native(oracle, direct_path)
			pass_record["direct_oracle_image"] = direct_info
			pass_record["actual_3D_source_witnesses"] = _small_source_witnesses(oracle)
			all_passed = all_passed and bool(direct_info.saved) and bool(pass_record.actual_3D_source_witnesses.passed)
			if pass_index == 0:
				first_direct = oracle
			else:
				var repeat_info: Dictionary = _compare_rgba(first_direct, oracle)
				pass_record["primary_repeat_RGBA"] = repeat_info
				all_passed = all_passed and bool(repeat_info.exact)
		for index in windows.size():
			var rect: Rect2i = windows[index]
			var prefix: String = name + "_window_%d_pass_%d" % [index, pass_index + 1]
			var transfer: Dictionary = await _read_window(rect, pass_record, prefix)
			var image: Image = transfer.get("image")
			transfer.erase("image")
			if direct_oracle and image != null:
				var expected: Image = oracle.get_region(rect)
				transfer["direct_oracle_RGBA"] = _compare_rgba(expected, image)
				all_passed = all_passed and bool(transfer.direct_oracle_RGBA.exact)
				expected = null
			if pass_index == 0:
				first_transfer_paths.append(str(transfer.get("path", "")))
			elif image != null:
				var previous: Image = Image.load_from_file(first_transfer_paths[index])
				transfer["fresh_primary_repeat_RGBA"] = _compare_rgba(previous, image)
				all_passed = all_passed and bool(transfer.fresh_primary_repeat_RGBA.exact)
				previous = null
			if not direct_oracle and index < 5 and image != null:
				transfer["color_witness"] = _color_witness(image, index)
				all_passed = all_passed and bool(transfer.color_witness.passed)
			all_passed = all_passed and bool(transfer.get("passed", false))
			record.transfers.append(transfer)
			image = null
		oracle = null
	first_direct = null
	record["after_all_small_readbacks"] = _memory_snapshot(name + "_all_small_readbacks_released")
	var primary_ref: WeakRef = weakref(active_view)
	_camera = null
	_pattern = null
	_world_node = null
	await _release_view()
	record["actual_primary_released"] = primary_ref.get_ref() == null
	record["released"] = _memory_snapshot(name + "_primary_released")
	record["passed"] = all_passed and record.passes.size() == 2 and record.transfers.size() == windows.size() * 2 and bool(record.actual_primary_released) and bool(record.released.get("valid", false))
	return record

func _read_window(rect: Rect2i, primary_pass: Dictionary, prefix: String) -> Dictionary:
	var record: Dictionary = {"passed": false, "source_primary_pass_id": primary_pass.id, "source_primary_frame": primary_pass.frame_after, "source_primary_process_frame": primary_pass.process_frame_after, "source_primary_post_draw_fence_sequence": primary_pass.last_post_draw_fence_sequence, "source_texture_rid": active_view.get_texture().get_rid().get_id(), "source_viewport_rid": active_view.get_viewport_rid().get_id(), "source_origin_px": [rect.position.x, rect.position.y], "native_window_size": [rect.size.x, rect.size.y], "transfer_shader_sha256": FileAccess.get_sha256(TRANSFER_SHADER), "resized": false, "gamma_compensation": false}
	if rect.size.x <= 0 or rect.size.y <= 0 or rect.position.x < 0 or rect.position.y < 0 or rect.end.x > active_view.size.x or rect.end.y > active_view.size.y or rect.size.x * rect.size.y > SMALL.x * SMALL.y: return record
	if active_view.render_target_update_mode != SubViewport.UPDATE_DISABLED: return record
	_transfer_view = SubViewport.new()
	_transfer_view.size = rect.size
	_transfer_view.disable_3d = true
	_transfer_view.msaa_2d = Viewport.MSAA_DISABLED
	_transfer_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(_transfer_view)
	var panel := ColorRect.new()
	panel.size = Vector2(rect.size)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material := ShaderMaterial.new()
	material.shader = _transport
	material.set_shader_parameter("primary_texture", active_view.get_texture())
	material.set_shader_parameter("source_origin_px", rect.position)
	panel.material = material
	_transfer_view.add_child(panel)
	var before: int = Engine.get_frames_drawn()
	var process_before: int = Engine.get_process_frames()
	_transfer_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	await RenderingServer.frame_post_draw
	_completed_post_draw_fences += 1
	_transfer_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	record["destination_draw_frame_before"] = before
	record["destination_draw_frame_after"] = Engine.get_frames_drawn()
	record["destination_engine_draw_counter_advanced"] = Engine.get_frames_drawn() > before
	record["destination_process_frame_before"] = process_before
	record["destination_process_frame_after"] = Engine.get_process_frames()
	record["destination_actual_post_draw_fence_sequence"] = _completed_post_draw_fences
	record["destination_requested_update_mode"] = SubViewport.UPDATE_ONCE
	record["destination_capture_identity_method"] = "actual natural process/frame_post_draw signal fence, followed by native RGBA readback; Engine counter growth NOT asserted"
	record["destination_viewport_rid"] = _transfer_view.get_viewport_rid().get_id()
	record["destination_texture_rid"] = _transfer_view.get_texture().get_rid().get_id()
	record["destination_viewport_instance_id"] = _transfer_view.get_instance_id()
	record["actual_destination_canvas"] = [_transfer_view.size.x, _transfer_view.size.y]
	record["actual_source_canvas"] = [active_view.size.x, active_view.size.y]
	var image: Image = _transfer_view.get_texture().get_image()
	var native: bool = _rgba_native(image, rect.size)
	record["native_RGBA8"] = native
	if native:
		var saved: Dictionary = _save_native(image, output + prefix + ".png")
		record.merge(saved)
		record["passed"] = bool(saved.saved) and Engine.get_process_frames() > process_before and _completed_post_draw_fences > int(primary_pass.last_post_draw_fence_sequence) and active_view.render_target_update_mode == SubViewport.UPDATE_DISABLED and active_view.get_texture().get_rid().get_id() == record.source_texture_rid
		var actual_width: int = image.get_width()
		var actual_height: int = image.get_height()
		record["actual_readback_canvas"] = [actual_width, actual_height]
	var transfer_ref: WeakRef = weakref(_transfer_view)
	panel.material = null
	material.set_shader_parameter("primary_texture", null)
	material = null
	panel = null
	_transfer_view.queue_free()
	_transfer_view = null
	for tick in 4: await process_frame
	record["actual_destination_released"] = transfer_ref.get_ref() == null
	record["passed"] = bool(record.passed) and bool(record.actual_destination_released)
	record["image"] = image
	return record

func _windows(size: Vector2i, small: bool) -> Array[Rect2i]:
	if small:
		return [Rect2i(Vector2i.ZERO, size), Rect2i(1, 3, 257, 129), Rect2i(2789, 5, 281, 137), Rect2i(3, 1897, 263, 149), Rect2i(2787, 1889, 283, 157), Rect2i(1457, 991, 321, 255)]
	# Five five-color witnesses plus odd-offset future tile-border windows.
	return [Rect2i(1, 3, 129, 127), Rect2i(size.x - 133, 5, 131, 129), Rect2i(3, size.y - 135, 127, 133), Rect2i(size.x - 137, size.y - 133, 135, 131), Rect2i(size.x / 2 - 65, size.y / 2 - 63, 131, 129), Rect2i(3065, 2041, 257, 255), Rect2i(12281, 8185, 259, 253)]

func _rgba_native(image: Image, size: Vector2i) -> bool:
	return image != null and image.get_size() == size and image.get_format() == Image.FORMAT_RGBA8 and not image.is_compressed() and not image.has_mipmaps()

func _save_native(image: Image, path: String) -> Dictionary:
	var bytes: PackedByteArray = image.get_data()
	var record: Dictionary = {"path": path, "saved": false, "raw_RGBA_sha256": _bytes_sha(bytes), "raw_RGBA_bytes": bytes.size(), "format": image.get_format()}
	bytes.clear()
	if FileAccess.file_exists(path) or image.save_png(path) != OK: return record
	var readback: Image = Image.load_from_file(path)
	record["PNG_reload_RGBA"] = _compare_rgba(image, readback)
	record["sha256"] = FileAccess.get_sha256(path)
	record["saved"] = bool(record.PNG_reload_RGBA.exact) and not str(record.sha256).is_empty()
	return record

func _compare_rgba(expected: Image, actual: Image) -> Dictionary:
	var record: Dictionary = {"exact": false, "tolerance": 0, "dimensions_equal": false, "different_bytes": -1, "maximum_byte_delta": -1}
	if expected == null or actual == null: return record
	record["dimensions_equal"] = expected.get_size() == actual.get_size()
	record["expected_canvas"] = [expected.get_width(), expected.get_height()]
	record["actual_canvas"] = [actual.get_width(), actual.get_height()]
	if not record.dimensions_equal or expected.get_format() != Image.FORMAT_RGBA8 or actual.get_format() != Image.FORMAT_RGBA8: return record
	var a: PackedByteArray = expected.get_data()
	var b: PackedByteArray = actual.get_data()
	record["expected_raw_RGBA_sha256"] = _bytes_sha(a)
	record["actual_raw_RGBA_sha256"] = _bytes_sha(b)
	if a == b:
		record["exact"] = true
		record["different_bytes"] = 0
		record["maximum_byte_delta"] = 0
		return record
	var differing := 0
	var maximum := 0
	for index in a.size():
		if a[index] != b[index]:
			if differing == 0:
				record["first_difference"] = {"byte_index": index, "channel": index % 4, "pixel": [int(index / 4) % expected.get_width(), int(index / 4) / expected.get_width()], "expected_byte": a[index], "actual_byte": b[index]}
			differing += 1
			maximum = maxi(maximum, absi(int(a[index]) - int(b[index])))
	record["different_bytes"] = differing
	record["maximum_byte_delta"] = maximum
	return record

func _bytes_sha(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK: return ""
	return context.finish().hex_encode()

func _color_witness(image: Image, index: int) -> Dictionary:
	var color: Color = image.get_pixel(image.get_width() / 2, image.get_height() / 2)
	return _classify_color(color, index)

func _classify_color(color: Color, index: int) -> Dictionary:
	var passed := false
	match index:
		0: passed = color.r > .3 and color.g < .3 and color.b < .3
		1: passed = color.g > .3 and color.r < .3 and color.b < .3
		2: passed = color.b > .3 and color.r < .3 and color.g < .3
		3: passed = color.r > .3 and color.g > .3 and color.b < .3
		4: passed = color.r > .3 and color.b > .3 and color.g < .3
	return {"id": ["top_left_red", "top_right_green", "bottom_left_blue", "bottom_right_yellow", "center_magenta"][index], "raw_RGBA": [color.r, color.g, color.b, color.a], "passed": passed and color.a > .99, "scope": "color/orientation witness only; exact byte proof comes from Stage A and real repeat"}

func _small_source_witnesses(image: Image) -> Dictionary:
	var points: Array[Vector2i] = [Vector2i(1, 1), Vector2i(SMALL.x - 2, 1), Vector2i(1, SMALL.y - 2), Vector2i(SMALL.x - 2, SMALL.y - 2), SMALL / 2]
	var witnesses: Array[Dictionary] = []
	var all_passed := true
	for index in points.size():
		var witness: Dictionary = _classify_color(image.get_pixelv(points[index]), index)
		witness["source_pixel"] = [points[index].x, points[index].y]
		witnesses.append(witness)
		all_passed = all_passed and bool(witness.passed)
	# Grid lies inside the procedural 3D panel, away from its boundaries. Its
	# actual RGB diversity prevents a blank/5-uniform-tile oracle passing.
	var unique: Dictionary = {}
	var gradient_samples: Array[Dictionary] = []
	for row in 7:
		for column in 7:
			var point := Vector2i(int(float(SMALL.x) * (.20 + float(column) * .035)), int(float(SMALL.y) * (.255 + float(row) * .035)))
			var color: Color = image.get_pixelv(point)
			var rgba: Array[int] = [roundi(color.r * 255), roundi(color.g * 255), roundi(color.b * 255), roundi(color.a * 255)]
			unique[str(rgba)] = true
			gradient_samples.append({"source_pixel": [point.x, point.y], "raw_RGBA_bytes": rgba})
	return {"passed": all_passed and unique.size() > 16, "five_colors": witnesses, "procedural_panel_actual_unique_colors": unique.size(), "procedural_panel_samples": gradient_samples, "alpha_gamut_scope": "diagnostic primary is opaque; arbitrary-alpha transport is not separately certified"}

func _transform_record(transform: Transform3D) -> Dictionary:
	return {"origin": [transform.origin.x, transform.origin.y, transform.origin.z], "basis": [[transform.basis.x.x, transform.basis.x.y, transform.basis.x.z], [transform.basis.y.x, transform.basis.y.y, transform.basis.y.z], [transform.basis.z.x, transform.basis.z.y, transform.basis.z.z]]}

func _transfer_finish(result: Dictionary, status: String, code: int) -> void:
	if _transfer_view != null:
		_transfer_view.queue_free()
		_transfer_view = null
	_camera = null
	_world_node = null
	_pattern = null
	_transport = null
	result["status"] = status
	result["proposed_exit_code_not_external_OS_evidence"] = code
	if not _write_result(result): code = 1
	print("NATIVE_TEXEL_TRANSFER_DIAGNOSTIC ", status, " ", output, " scope=", TRANSFER_SCOPE)
	await _finish(code)
