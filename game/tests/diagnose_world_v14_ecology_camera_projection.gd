extends SceneTree

## Exact native projection diagnostic only. No Field/capture/resource writes.
const ART := "res://art/maps/world_map_v14/"
var failures := 0
var report: Dictionary = {}
var output := ""
var receiver: SubViewport

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition: return
	failures += 1
	push_error("[EcologyCameraDiagnostic FAIL] " + message)

func _json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(value is Dictionary, "actual JSON dictionary: " + path)
	return value if value is Dictionary else {}

func _v2(value: Variant) -> Vector2:
	return Vector2(float(value[0]), float(value[1])) if value is Array and value.size() == 2 else Vector2(INF, INF)

func _v3(value: Variant) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2])) if value is Array and value.size() == 3 else Vector3(INF, INF, INF)

func _height_rf(point: Vector2, samples: PackedFloat32Array, cols: int, rows: int) -> float:
	# Independently reconstruct the stored 6px RF grid's actual a,b,c/b,d,c
	# source triangles. Never invoke the mutable renderer or terrain helper.
	var grid := point / Vector2(4608, 3072) * Vector2(cols - 1, rows - 1)
	if not grid.is_finite() or grid.x < 0 or grid.y < 0 or grid.x > cols - 1 or grid.y > rows - 1: return NAN
	var x := mini(floori(grid.x), cols - 2)
	var y := mini(floori(grid.y), rows - 2)
	var fx := grid.x - x
	var fy := grid.y - y
	var a := float(samples[y * cols + x])
	var b := float(samples[y * cols + x + 1])
	var c := float(samples[(y + 1) * cols + x])
	var d := float(samples[(y + 1) * cols + x + 1])
	return a + (b - a) * fx + (c - a) * fy if fx + fy <= 1 else d + (c - d) * (1 - fx) + (b - d) * (1 - fy)

func _run() -> void:
	output = "res://build/world_map_v14_qa/ecology_camera_exact_%d/" % Time.get_unix_time_from_system()
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique diagnostic output")
	var manifest := _json(ART + "manifest.json")
	var contract := _json(ART + "source_contract.json")
	var geometry := _json(ART + "geometry.json")
	var evidence: Dictionary = manifest.get("ecology_evidence", {})
	var pose: Dictionary = evidence.get("camera", {})
	var canvas := _v2(pose.get("canvas"))
	var logical := _v2(pose.get("logical_canvas"))
	var columns: Array = pose.get("basis_columns", [])
	var shape := _v2(geometry.get("height_grid_shape"))
	var cols := int(shape.x)
	var rows := int(shape.y)
	var rf_path := String(geometry.get("height_grid_path", ""))
	var bytes := FileAccess.get_file_as_bytes(rf_path)
	_check(cols == 769 and rows == 513 and bytes.size() == cols * rows * 4 and canvas == Vector2(9216, 6144) and logical == Vector2(4608, 3072) and int(pose.get("projection_to_logical_divisor", -1)) == 2 and columns.size() == 3, "actual SSAA2 camera/RF schema is exact")
	if failures > 0:
		report = {"scope": "EXACT_ECOLOGY_CAMERA_CAUSAL_NOT_FULL_MAP", "setup_failed": true}
		call_deferred("_finish")
		return
	var samples := bytes.to_float32_array()
	var image := Image.load_from_file(ART + "ecology_weights.png")
	_check(image != null and image.get_size() == Vector2i(logical) and image.get_format() == Image.FORMAT_RGBA8, "original logical ecology PNG read without mutation")
	if image == null:
		call_deferred("_finish")
		return
	receiver = SubViewport.new()
	receiver.size = Vector2i(canvas)
	receiver.render_target_update_mode = SubViewport.UPDATE_DISABLED
	receiver.world_3d = World3D.new()
	root.add_child(receiver)
	var camera := Camera3D.new()
	camera.projection = int(pose.get("projection_enum", -1))
	camera.size = float(pose.get("size", 0))
	camera.position = _v3(pose.get("position"))
	camera.basis = Basis(_v3(columns[0]), _v3(columns[1]), _v3(columns[2]))
	receiver.add_child(camera)
	camera.current = true
	await process_frame
	await process_frame
	var meter_size := _v2(contract.get("camera", {}).get("world_meters"))
	var records: Array = []
	var actual_exact := 0
	var simple_exact := 0
	var red_exact := 0
	for probe: Dictionary in evidence.get("forest_core_probes", []):
		var source := _v2(probe.get("source_px"))
		var height := _height_rf(source, samples, cols, rows)
		_check(source.is_finite() and is_finite(height), "original RF triangle supports actual crown witness: " + String(probe.get("entity_id", "")))
		var vertex := Vector3((source.x / logical.x - .5) * meter_size.x, height, (source.y / logical.y - .5) * meter_size.y)
		var actual_high := camera.unproject_position(vertex)
		var actual_low := actual_high / 2.
		var actual_pixel := Vector2i(actual_low)
		var local := camera.basis.inverse() * (vertex - camera.position)
		var simple_high := canvas * .5 + Vector2(local.x, -local.y) * (canvas.y / camera.size)
		var simple_low := simple_high / 2.
		var simple_pixel := Vector2i(simple_low)
		var captured_pixel := Vector2i(_v2(probe.get("actual_camera_pixel")))
		if actual_pixel == captured_pixel: actual_exact += 1
		if simple_pixel == captured_pixel: simple_exact += 1
		var red := image.get_pixelv(captured_pixel).r if Rect2i(Vector2i.ZERO, image.get_size()).has_point(captured_pixel) else NAN
		if red == float(probe.get("encoded_forest_red", -1)): red_exact += 1
		records.append({"id": probe.get("entity_id"), "source_px": [source.x, source.y], "rf_triangle_height_m": height, "world_ground_m": [vertex.x, vertex.y, vertex.z], "recorded_pixel": [captured_pixel.x, captured_pixel.y], "actual_camera_high": [actual_high.x, actual_high.y], "actual_camera_low": [actual_low.x, actual_low.y], "actual_camera_pixel": [actual_pixel.x, actual_pixel.y], "simple_high": [simple_high.x, simple_high.y], "simple_low": [simple_low.x, simple_low.y], "simple_pixel": [simple_pixel.x, simple_pixel.y], "actual_matches_record_exact": actual_pixel == captured_pixel, "simple_matches_record_exact": simple_pixel == captured_pixel, "original_png_red_at_recorded_pixel": red, "red_matches_record_exact": red == float(probe.get("encoded_forest_red", -1))})
	report = {"scope": "EXACT_ECOLOGY_CAMERA_CAUSAL_NOT_FULL_MAP", "script_path": get_script().resource_path, "script_sha256": FileAccess.get_sha256(get_script().resource_path), "manifest_sha256": FileAccess.get_sha256(ART + "manifest.json"), "source_contract_sha256": FileAccess.get_sha256(ART + "source_contract.json"), "rf_path": rf_path, "rf_sha256": FileAccess.get_sha256(rf_path), "ecology_png_sha256": FileAccess.get_sha256(ART + "ecology_weights.png"), "capture_iteration": manifest.get("capture_iteration"), "actual_viewport": [receiver.size.x, receiver.size.y], "actual_camera_position": [camera.position.x, camera.position.y, camera.position.z], "actual_camera_size": camera.size, "actual_camera_projection": camera.projection, "actual_camera_basis": [[camera.basis.x.x, camera.basis.x.y, camera.basis.x.z], [camera.basis.y.x, camera.basis.y.y, camera.basis.y.z], [camera.basis.z.x, camera.basis.z.y, camera.basis.z.z]], "probe_count": records.size(), "actual_camera_exact_count": actual_exact, "simple_formula_exact_count": simple_exact, "recorded_red_exact_count": red_exact, "records": records, "setup_failures": failures, "pixel_tolerance": 0, "production_approved": false}
	call_deferred("_finish")

func _finish() -> void:
	var viewport_ref: WeakRef = weakref(receiver) if is_instance_valid(receiver) else null
	if is_instance_valid(receiver): receiver.queue_free()
	receiver = null
	var cursors := root.get_node_or_null("CursorManager")
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	if cursors != null:
		for key: String in ["_arrow", "_hand", "_wait"]: cursors.set(key, null)
	for frame in 8: await process_frame
	_check(viewport_ref == null or not is_instance_valid(viewport_ref.get_ref()), "diagnostic owns no remaining viewport or camera")
	report["setup_failures"] = failures
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	_check(file != null, "write only unique camera diagnostic JSON")
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("[EcologyCameraDiagnostic] actual_exact=%d simple_exact=%d probes=%d setup_failures=%d result=%s; NOT_FULL_MAP" % [int(report.get("actual_camera_exact_count", -1)), int(report.get("simple_formula_exact_count", -1)), int(report.get("probe_count", 0)), failures, output + "result.json"])
	quit(0 if failures == 0 else 1)
