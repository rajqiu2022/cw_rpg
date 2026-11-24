extends "res://tests/test_world_map_v14_production_20261002.gd"

## Root-only serialization diagnosis. It cannot approve or alter saved geometry.
func _initialize() -> void:
	call_deferred("_run_guard_json_precision")

func _scalar_differences(expected: Variant, recorded: Variant, path: String, result: Array[Dictionary]) -> void:
	if expected is Dictionary and recorded is Dictionary:
		for key: Variant in expected:
			if recorded.has(key): _scalar_differences(expected[key], recorded[key], path + "." + String(key), result)
			else: result.append({"path": path + "." + String(key), "missing": true})
		return
	if expected is Array and recorded is Array:
		if expected.size() != recorded.size(): result.append({"path": path, "expected_count": expected.size(), "recorded_count": recorded.size()})
		for index in mini(expected.size(), recorded.size()): _scalar_differences(expected[index], recorded[index], path + "[" + str(index) + "]", result)
		return
	if expected == recorded: return
	var numeric: bool = (typeof(expected) == TYPE_FLOAT or typeof(expected) == TYPE_INT) and (typeof(recorded) == TYPE_FLOAT or typeof(recorded) == TYPE_INT)
	var serialized := JSON.stringify(expected, "", true, false)
	var canonical: Variant = JSON.parse_string(serialized)
	result.append({"path": path, "expected_type": type_string(typeof(expected)), "recorded_type": type_string(typeof(recorded)), "independent_unserialized_full_precision": JSON.stringify(expected, "", true, true), "recorded_full_precision": JSON.stringify(recorded, "", true, true), "default_serialized_scalar": serialized, "default_parsed_scalar_full_precision": JSON.stringify(canonical, "", true, true), "default_canonical_exact": canonical == recorded, "numeric_delta_full_precision": JSON.stringify(float(recorded) - float(expected), "", true, true) if numeric else "NON_NUMERIC"})

func _run_guard_json_precision() -> void:
	qa_scope = "LIMITED_NORTH_GUARD_JSON_SERIALIZATION_NOT_GEOMETRY_APPROVAL"
	candidate_stage = true
	phase_output = OUTPUT_DIR + "north_guard_json_precision_" + str(int(Time.get_unix_time_from_system())) + "/"
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output)) == OK, "unique JSON representation diagnosis directory")
	player_saves_before = _actual_player_saves()
	prior_navigation = root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	manifest = _json(MANIFEST_PATH)
	source_contract = _json(SOURCE_PATH)
	_check(DisplayServer.get_name() == "headless" and int(manifest.get("capture_iteration", -1)) == 9 and manifest.get("status") == "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA", "root serialized headless diagnosis reads completed original capture only")
	var file := FileAccess.open(ART_DIR + "height_grid.rf", FileAccess.READ)
	_check(file != null, "original RF available without modifying saved receiver geometry")
	if file == null:
		_finish()
		return
	var bytes := file.get_buffer(file.get_length())
	var error := file.get_error()
	file.close()
	file = null
	_check(error == OK and bytes.size() == 769 * 513 * 4 and FileAccess.get_sha256(ART_DIR + "height_grid.rf").to_lower() == NORTH_GUARD_PRIOR_AUTHORITY_SHAS["height_grid.rf"], "independent original RF exact frozen bytes")
	if error != OK or bytes.size() != 769 * 513 * 4:
		_finish()
		return
	var rf := bytes.to_float32_array()
	var water_y: float = -.025
	var expected: Array[Dictionary] = []
	for cell in 768:
		var h0: float = rf[cell]
		var h1: float = rf[cell + 1]
		if h0 >= water_y and h1 >= water_y: continue
		var left_t := (water_y - h0) / (h1 - h0) if h0 >= water_y else 0.0
		var right_t := (water_y - h0) / (h1 - h0) if h1 >= water_y else 1.0
		var left: float = (cell + left_t) * 6.0
		var right: float = (cell + right_t) * 6.0
		if right - left < .000001: continue
		var left_h := lerpf(h0, h1, left_t)
		var right_h := lerpf(h0, h1, right_t)
		expected.append({"source_x_px": [left, right], "actual_top_row_float32_height_m": [left_h, right_h], "source_y_px": [-96.0, 0.0], "projected_far_edge_max_y": -96.0 - minf(left_h, right_h) * WORLD_SIZE.y / 30.0 / sqrt(2.0)})
	var actual: Array = manifest.get("north_visual_only_guard", {}).get("segments", [])
	var default_serialized := JSON.stringify(expected, "\t", true, false)
	var canonical: Variant = JSON.parse_string(default_serialized)
	var full_serialized := JSON.stringify(expected, "\t", true, true)
	var full_parsed: Variant = JSON.parse_string(full_serialized)
	var differences: Array[Dictionary] = []
	_scalar_differences(expected, actual, "segments", differences)
	var canonical_exact := _domain_equal(canonical, actual)
	_check(not expected.is_empty() and expected.size() == actual.size(), "independently rebuilt original wet segment count matches actual JSON")
	_check(canonical_exact, "exact default-JSON canonical independent segments equal actual persisted metadata, no numeric tolerance")
	_check(not differences.is_empty(), "original raw-double equality mismatch independently reproduced and retained")
	for difference: Dictionary in differences:
		_check(difference.get("default_canonical_exact") == true, "every raw-double mismatch is exactly explained by default serialization: " + String(difference.get("path", "")))
	var evidence := {"scope": qa_scope, "manifest_path": MANIFEST_PATH, "manifest_sha256": FileAccess.get_sha256(MANIFEST_PATH), "raw_expected_equal": _domain_equal(expected, actual), "default_serialized_expected_equal": canonical_exact, "full_precision_serialized_expected_equal": _domain_equal(full_parsed, actual), "default_serialized_independent_segments": default_serialized, "full_precision_serialized_independent_segments": full_serialized, "scalar_differences": differences, "actual_persisted_segments": actual, "saved_geometry_not_rewritten_or_approved": true, "independent_actual_vertex_uv_index_exact_gate_unchanged": true, "original_rf_height_budget_m_unchanged": ".0001"}
	_checked_alpha_json(phase_output + "json_precision_evidence.json", evidence)
	print("[NorthGuardJSONPrecision] segments=%d raw_double_differences=%d default_canonical_exact=%s full_precision_parsed_exact=%s; actual bed failures remain separate, no geometry tolerance change" % [expected.size(), differences.size(), canonical_exact, _domain_equal(full_parsed, actual)])
	_finish()
