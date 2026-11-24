extends SceneTree
## NEW ROOT275 regression. READ ONLY: independent whole-RF measurements and
## unchanged gate's scalar JSON boundary; not FULL publication or Field credit.
const GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const GATE_PATH := "res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd"
const GATE_SHA := "83e2e26417514d58ee6b7f86391c53da3b93485c8c87329d312c5bfc785163e4"
const OLD_RF := "res://art/maps/world_map_v15_complete_v5/terrain_height.rf"
const OLD_SHA := "b7210634cbc2d7a2809bfab608e47930d5717459b01dc42df33ae9e6919548b9"
const DERIVED := "res://build/world_map_v15_v9c_visual_quality_proposal/v9d_broad_soft/1791124651_1751026/derived_geometry/"
const NEW_RF := DERIVED + "terrain_height.rf"
const NEW_SHA := "7158eaf91c38ce55541e895b449ee5645a772a2cd037479357eedaf1917e6f4b"
const REPORT := DERIVED + "derivation_report.json"
const REPORT_SHA := "707870fe709b12f9df4eeff76fb253b08c41631bc87065ab2d638828c674f1a0"
const NODE_COUNT := 1537 * 1025
var checks: int = 0
var errors: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: errors.append(label)

func _measure(old_bytes: PackedByteArray, new_bytes: PackedByteArray) -> Dictionary:
	# Independent byte decoding, not production derivation/helper or report PASS.
	if old_bytes.size() != NODE_COUNT * 4 or new_bytes.size() != old_bytes.size(): return {}
	var before: PackedFloat32Array = old_bytes.to_float32_array()
	var after: PackedFloat32Array = new_bytes.to_float32_array()
	var before_bits: PackedInt32Array = old_bytes.to_int32_array()
	var after_bits: PackedInt32Array = new_bytes.to_int32_array()
	var changed: int = 0
	var maximum: float = 0.0
	var maximum_index: int = -1
	for index in NODE_COUNT:
		if not is_finite(before[index]) or not is_finite(after[index]): return {}
		if (before[index] > -0.025) != (after[index] > -0.025): return {}
		if before_bits[index] == after_bits[index]: continue
		var x: int = index % 1537
		@warning_ignore("integer_division")
		var y: int = index / 1537
		# Rect2(3920,0,2320,1360), right/bottom exclusive, integer lattice.
		if x < 490 or x >= 780 or y < 0 or y >= 170: return {}
		changed += 1
		var delta: float = absf(after[index] - before[index])
		if delta > maximum:
			maximum = delta
			maximum_index = index
	return {"changed_nodes": changed, "maximum_height_delta_m": maximum, "water_land_vertex_changes": 0, "maximum_index": maximum_index}

func _audit_matches(audit: Dictionary, measured: Dictionary) -> bool:
	# Same three production predicates; expected maximum alone goes through
	# writer's default JSON representation. Never round saved input or use epsilon.
	return not measured.is_empty() and measured.changed_nodes > 0 and GATE._num(audit.get("changed_nodes"), measured.changed_nodes) and GATE._json_native_exact(audit.get("maximum_height_delta_m"), measured.maximum_height_delta_m) and GATE._num(audit.get("water_land_vertex_changes"), 0)

func _adjacent_double(value: float, increment: int) -> float:
	var bytes: PackedByteArray = PackedFloat64Array([value]).to_byte_array()
	bytes.encode_u64(0, bytes.decode_u64(0) + increment)
	return bytes.decode_double(0)

func _run() -> void:
	var pins: Dictionary = {GATE_PATH: GATE_SHA, OLD_RF: OLD_SHA, NEW_RF: NEW_SHA, REPORT: REPORT_SHA}
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == pins[path], "frozen actual source/RF/report SHA: " + path)
	var parser: JSON = JSON.new()
	_check(parser.parse(FileAccess.get_file_as_string(REPORT)) == OK and parser.data is Dictionary, "actual SHA-bound report parses")
	if errors.is_empty():
		var report: Dictionary = parser.data
		var audit: Dictionary = report.get("audit", {})
		_check(audit.get("baseline_sha256", {}).get(OLD_RF) == OLD_SHA and report.get("artifacts", {}).get("height_rf", {}).get("path") == NEW_RF and report.artifacts.height_rf.get("sha256") == NEW_SHA, "actual source metadata binds both original and derived RF")
		var old_bytes: PackedByteArray = FileAccess.get_file_as_bytes(OLD_RF)
		var new_bytes: PackedByteArray = FileAccess.get_file_as_bytes(NEW_RF)
		var measured: Dictionary = _measure(old_bytes, new_bytes)
		_check(not measured.is_empty(), "independent all-node finite/domain/water/RF measurement")
		if not measured.is_empty():
			_check(measured.changed_nodes == 20769 and measured.maximum_index == 109691, "all 1575425 nodes independently measured, exact changed count and maximum site")
			_check(PackedFloat64Array([measured.maximum_height_delta_m]).to_byte_array().hex_encode() == "000000002eb2e93f", "actual native difference of packed Float32 heights, before JSON")
			var saved: Variant = audit.get("maximum_height_delta_m")
			var native: float = measured.maximum_height_delta_m
			_check(not GATE._num(saved, native), "ROOT275 exact native versus saved JSON mismatch reproduced")
			_check(_audit_matches(audit, measured), "actual original audit matches independently computed writer representation")
			print("V9E_RF_HEIGHT_JSON_DIAGNOSTIC ", JSON.stringify({"nodes": NODE_COUNT, "changed": measured.changed_nodes, "maximum_index": measured.maximum_index, "native_17dp": "%.17f" % native, "saved_17dp": "%.17f" % saved, "native_float64_hex": PackedFloat64Array([native]).to_byte_array().hex_encode(), "saved_float64_hex": PackedFloat64Array([saved]).to_byte_array().hex_encode(), "default_writer_json": JSON.stringify(native, "\t")}))
			for increment: int in [-1, 1]:
				var wrong: Dictionary = audit.duplicate(true)
				wrong.maximum_height_delta_m = _adjacent_double(float(saved), increment)
				_check(not _audit_matches(wrong, measured), "saved maximum difference of one Float64 ULP rejected: " + str(increment))
			for invalid: Variant in [null, true, false, str(saved), NAN, INF, -INF, native, 0.0, native + 0.000001]:
				var wrong: Dictionary = audit.duplicate(true)
				wrong.maximum_height_delta_m = invalid
				_check(not _audit_matches(wrong, measured), "unencoded/incorrect/nonnumeric saved maximum rejected: " + str(invalid))
			for key: String in ["changed_nodes", "water_land_vertex_changes"]:
				var wrong: Dictionary = audit.duplicate(true)
				wrong[key] = float(measured[key]) + 1.0
				_check(not _audit_matches(wrong, measured), "unchanged strict integer audit predicate: " + key)
			var obsolete: Dictionary = audit.duplicate(true)
			obsolete.changed_nodes = 0
			obsolete.maximum_height_delta_m = 0.0
			_check(not _audit_matches(obsolete, measured), "old unchanged-height audit cannot substitute for actual derived RF")
			var changed_bytes: PackedByteArray = new_bytes.duplicate()
			var offset: int = int(measured.maximum_index) * 4
			changed_bytes.encode_u32(offset, changed_bytes.decode_u32(offset) + 1)
			_check(not _audit_matches(audit, _measure(old_bytes, changed_bytes)), "one actual Float32 RF ULP mutation rejected, not rounded away")
		_check(_measure(old_bytes, PackedByteArray([1, 2, 3])).is_empty(), "non-RF bytes and wrong dimensions rejected")
		var nonfinite: PackedByteArray = new_bytes.duplicate()
		nonfinite.encode_u32(0, 0x7fc00000)
		_check(_measure(old_bytes, nonfinite).is_empty(), "nonfinite RF rejected")
		var missing: Dictionary = GATE._v9c_prepared_source({}, {}, {}, {})
		_check(missing.get("error") == "Four exact actual ROOT220 CPU-derived inputs are not separately root-authorized", "existing gate rejects absent source/authorization metadata before any preparation")
	for path: String in pins: _check(FileAccess.get_sha256(path).to_lower() == pins[path], "original frozen source/RF/report unchanged after units: " + path)
	print("V9E_RF_HEIGHT_JSON_UNITS ", JSON.stringify({"scope": "READ_ONLY_ACTUAL_RF_JSON_BOUNDARY_UNIT_NOT_FULL_PUBLICATION", "checks": checks, "failures": errors.size(), "errors": errors, "Field_executed": false, "GPU_executed": false, "formal_cutover": false}))
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(0 if errors.is_empty() else 1)
