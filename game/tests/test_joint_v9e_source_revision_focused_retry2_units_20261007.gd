extends SceneTree
## SOURCE_REVISION-focused retry2 READ ONLY test. Not publish/whole/Field approval.
## Preserves the first complete revision failure; avoids only redundant postfailure material reconstruction.
## Full publisher validate() is unchanged and must still run independently.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const GATE_PATH := "res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd"
const GATE_SHA := "7de74b5a3eafa62475c456a0828a2a06e02b258d664a51652850b07adeb8bdcd"
const SOURCE_PATH := "res://data/maps/world_map_v15_complete_v9c_source.json"
const SOURCE_SHA := "85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f"
const MANIFEST_PATH := "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const MANIFEST_SHA := "1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a"
const REPORT_PATH := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const REPORT_SHA := "cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851"
var checks: int = 0
var errors: Array[String] = []
var stages: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _json(path: String) -> Dictionary:
	var parser: JSON = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK or not parser.data is Dictionary: return {}
	return parser.data

func _independent_projection(point: Vector2, rf: PackedFloat32Array) -> Vector2:
	# Decode four actual RF nodes, affine triangle, then native Vector2 storage.
	# No production project_source()/triangle_height()/authored-height factory.
	var q: Vector2 = point / 8.0
	var x: int = mini(floori(q.x), 1535)
	var y: int = mini(floori(q.y), 1023)
	var f: Vector2 = q - Vector2(x, y)
	var a: float = rf[y * 1537 + x]
	var b: float = rf[y * 1537 + x + 1]
	var c: float = rf[(y + 1) * 1537 + x]
	var d: float = rf[(y + 1) * 1537 + x + 1]
	var height: float = a + (b - a) * f.x + (c - a) * f.y if f.x + f.y <= 1.0 else d + (c - d) * (1.0 - f.x) + (b - d) * (1.0 - f.y)
	return Vector2(point.x, point.y - height * (102.4 * sqrt(.5)))

func _adjacent_double(value: float, step: int) -> float:
	var bytes: PackedByteArray = PackedFloat64Array([value]).to_byte_array()
	bytes.encode_u64(0, bytes.decode_u64(0) + step)
	return bytes.decode_double(0)

func _adjacent_float(value: float, step: int) -> float:
	var bytes: PackedByteArray = PackedFloat32Array([value]).to_byte_array()
	bytes.encode_u32(0, bytes.decode_u32(0) + step)
	return bytes.decode_float(0)

func _portal_source(source: Dictionary, index: int, door: Variant) -> Dictionary:
	# Copy only containers that are changed; the original source stays untouched.
	var result: Dictionary = source.duplicate()
	result.portals = source.portals.duplicate()
	result.portals[index] = source.portals[index].duplicate(true)
	result.portals[index].door_foot_px = door
	return result

func _door_units(source: Dictionary, evidence: Dictionary, boundary: Dictionary, catalog: Dictionary) -> void:
	var actual = boundary.source
	var rf: PackedFloat32Array = actual.heights
	_check(rf.size() == 1537 * 1025, "actual fully reconstructed derived RF, never a lazy authored fallback")
	_check(source.portals.size() == 16, "all sixteen actual source doorways")
	var native_mismatch_ids: Array[String] = []
	for index in source.portals.size():
		var entry: Dictionary = source.portals[index]
		var point := Vector2(entry.source_XZ_foot_px[0], entry.source_XZ_foot_px[1])
		var independent: Vector2 = _independent_projection(point, rf)
		var native: Vector2 = actual.project_source(point)
		var saved: Array = entry.door_foot_px
		_check(var_to_bytes(independent) == var_to_bytes(native), "independent exact actual RF/native projection: " + str(entry.id))
		_check(GATE._pair(saved) and GATE._json_native_exact(saved, [native.x, native.y]), "actual saved writer-encoded door: " + str(entry.id))
		if not GATE._pair_eq(saved, native): native_mismatch_ids.append(entry.id)
		print("V9E_DOOR_JSON_DIAGNOSTIC ", JSON.stringify({"id": entry.id, "source_XZ": entry.source_XZ_foot_px, "saved": saved, "native_x_17dp": "%.17f" % native.x, "native_y_17dp": "%.17f" % native.y, "saved_y_17dp": "%.17f" % saved[1], "native_y_float64_hex": PackedFloat64Array([native.y]).to_byte_array().hex_encode(), "saved_y_float64_hex": PackedFloat64Array([saved[1]]).to_byte_array().hex_encode(), "old_native_pair_equal": GATE._pair_eq(saved, native)}))
		for axis in 2:
			for step: int in [-1, 1]:
				var wrong: Array = saved.duplicate()
				wrong[axis] = _adjacent_double(float(saved[axis]), step)
				var refusal: String = GATE._v9c_boundary_error(_portal_source(source, index, wrong), evidence, boundary, catalog)
				_check(refusal == "Fresh actual protected doorway differs " + str(entry.id), "saved one Float64 ULP rejected: %s/%d/%d" % [entry.id, axis, step])
				wrong = [native.x, native.y]
				wrong[axis] = _adjacent_float(float(wrong[axis]), step)
				wrong = JSON.parse_string(JSON.stringify(wrong, "\t"))
				refusal = GATE._v9c_boundary_error(_portal_source(source, index, wrong), evidence, boundary, catalog)
				_check(refusal == "Fresh actual protected doorway differs " + str(entry.id), "writer-encoded one native Float32 ULP rejected: %s/%d/%d" % [entry.id, axis, step])
		for invalid: Variant in [[saved[0]], [saved[0], saved[1], 0], [saved[0], str(saved[1])], [saved[0], true], [saved[0], NAN], [saved[0], INF]]:
			_check(GATE._v9c_boundary_error(_portal_source(source, index, invalid), evidence, boundary, catalog) == "Fresh actual protected doorway differs " + str(entry.id), "finite shape/type doorway rejected: " + str(entry.id))
	print("V9E_DOOR_NATIVE_JSON_MISMATCH_IDS ", JSON.stringify(native_mismatch_ids))
	_check(native_mismatch_ids.size() == 4 and native_mismatch_ids.has("yanmen_pass") and native_mismatch_ids.has("huashan") and native_mismatch_ids.has("linxi_village") and native_mismatch_ids.has("east_sea_port"), "actual four native-versus-JSON door differences independently located")

func _record_stage(name: String, error: String) -> void:
	stages[name] = error
	_check(error.is_empty(), name + ": " + error)
	print("V9E_SOURCE_REVISION_STAGE ", JSON.stringify({"stage": name, "error": error}))

func _run() -> void:
	var pins: Dictionary = {GATE_PATH: GATE_SHA, SOURCE_PATH: SOURCE_SHA, MANIFEST_PATH: MANIFEST_SHA, REPORT_PATH: REPORT_SHA}
	for path: String in GATE.EXACT_INPUTS: pins[path] = GATE.EXACT_INPUTS[path]
	pins[GATE.BASE_PATH] = GATE.BASE_SHA
	for role: String in GATE.DERIVED_INPUTS:
		var row: Dictionary = GATE.DERIVED_INPUTS[role]
		pins[row.path] = row.sha256
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == String(pins[path]).to_lower(), "actual source/frozen input SHA: " + path)
	var source: Dictionary = _json(SOURCE_PATH)
	var manifest: Dictionary = _json(MANIFEST_PATH)
	var report: Dictionary = _json(REPORT_PATH)
	_check(not source.is_empty() and not manifest.is_empty() and not report.is_empty(), "actual SHA-bound S/M/report dictionaries")
	if errors.is_empty():
		GATE._report = report
		var evidence: Dictionary = source.v9c_revision_evidence
		var catalog: Dictionary = manifest.asset_sha256
		var graph: Dictionary = manifest.capture_graph
		# The complete current RF formula/mesh/selector/support preparation is not
		# skipped. Only predecessor whole hashing, 64 chunks and 112 seams are out
		# of this focused test; the production publisher still performs all of them.
		var boundary: Dictionary = GATE._v9c_prepared_source(graph, source, evidence, catalog)
		_check(boundary.has("source"), "full unchanged RF/mesh/selector source reconstruction: " + str(boundary.get("error", "")))
		if boundary.has("source"):
			_record_stage("actual_boundary", GATE._v9c_boundary_error(source, evidence, boundary, catalog))
			_door_units(source, evidence, boundary, catalog)
		var revision_error: String = GATE._v7_revision_error(source, catalog, graph)
		_record_stage("actual_v7_revision_complete", revision_error)
		# Preserve every failure, and diagnose later pure branches in the same
		# run rather than erasing errors or turning partial success into publish.
		if not revision_error.is_empty() and boundary.has("source"):
			var authorization: Dictionary = _json(str(report.authorization.path))
			_record_stage("post_refusal_actual_regional", GATE._v9c_regional_error(authorization.get("regional_visual_review"), evidence.get("regional_approval"), catalog, graph, evidence))
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == String(pins[path]).to_lower(), "actual source/frozen input unchanged: " + path)
	print("V9E_SOURCE_REVISION_FOCUSED_UNITS ", JSON.stringify({"scope": "READ_ONLY_SOURCE_REVISION_ONLY_NOT_PUBLISH_OR_FULL_OR_FIELD", "checks": checks, "failures": errors.size(), "errors": errors, "stages": stages, "whole64_executed": false, "seam112_executed": false, "Field_executed": false, "GPU_capture_executed": false, "formal_cutover": false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
