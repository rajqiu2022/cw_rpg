extends "res://tests/test_world_map_v14_production_20261002.gd"

const ORIGINAL_LOCAL := "res://build/world_map_v14_ninth_v9_north_visual_guard_preview/"
const CORRECTED_LOCAL := "res://build/world_map_v14_ninth_v10_north_visual_guard_ordinal_preview/"
const CORRECTED_SOURCE_SHA := "111ccff5c6a360d0088cfad14535ad3ce541233b5e7851c22506939e74fa128a"

func _initialize() -> void:
	call_deferred("_run_ordinal_local")

func _run_ordinal_local() -> void:
	qa_scope = "LIMITED_LOCAL_NORTH_GUARD_ORDINAL_NOT_WHOLE_WORLD"
	candidate_stage = true
	phase_output = OUTPUT_DIR + "north_guard_ordinal_local_" + str(int(Time.get_unix_time_from_system())) + "/"
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output)) == OK, "unique local ordinal comparison evidence directory")
	player_saves_before = _actual_player_saves()
	prior_navigation = root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	manifest = _json(MANIFEST_PATH)
	source_contract = _json(SOURCE_PATH)
	_check(DisplayServer.get_name() == "headless", "local receiver comparison has no QA GPU or Field")
	var old_record := _json(ORIGINAL_LOCAL + "result.json")
	var new_record := _json(CORRECTED_LOCAL + "result.json")
	_check(new_record.get("executed_builder_sha256") == CORRECTED_SOURCE_SHA and new_record.get("status") == "NORTH_VISUAL_GUARD_LOCAL_TECHNICAL_PASS", "actual corrected local capture binds approved ordinal-only executed source")
	var file := FileAccess.open(ART_DIR + "height_grid.rf", FileAccess.READ)
	_check(file != null, "original unchanged RF available")
	if file == null:
		_finish()
		return
	var bytes := file.get_buffer(file.get_length())
	var read_error := file.get_error()
	file.close()
	file = null
	_check(read_error == OK and bytes.size() == 769 * 513 * 4 and FileAccess.get_sha256(ART_DIR + "height_grid.rf").to_lower() == NORTH_GUARD_PRIOR_AUTHORITY_SHAS["height_grid.rf"], "ordinal geometry reconstruction binds literal frozen original RF")
	if read_error != OK or bytes.size() != 769 * 513 * 4:
		_finish()
		return
	var rf := bytes.to_float32_array()
	var expected_vertices := PackedVector3Array()
	var expected_water := PackedVector3Array()
	var expected_uv := PackedVector2Array()
	var expected_indices := PackedInt32Array()
	var world_metres := Vector2(45.0, 42.42640687)
	for cell in 768:
		var h0: float = rf[cell]
		var h1: float = rf[cell + 1]
		if h0 >= -.025 and h1 >= -.025: continue
		var left_t := (-.025 - h0) / (h1 - h0) if h0 >= -.025 else 0.0
		var right_t := (-.025 - h0) / (h1 - h0) if h1 >= -.025 else 1.0
		var left: float = (cell + left_t) * 6.0
		var right: float = (cell + right_t) * 6.0
		if right - left < .000001: continue
		var left_h := lerpf(h0, h1, left_t)
		var right_h := lerpf(h0, h1, right_t)
		var first := expected_vertices.size()
		var corners: Array[Vector2] = [Vector2(left, -96), Vector2(right, -96), Vector2(left, 0), Vector2(right, 0)]
		for corner in 4:
			var source: Vector2 = corners[corner]
			var y: float = left_h if corner % 2 == 0 else right_h
			var vertex := Vector3((source.x / WORLD_SIZE.x - .5) * world_metres.x, y, (source.y / WORLD_SIZE.y - .5) * world_metres.y)
			expected_vertices.append(vertex)
			expected_water.append(Vector3(vertex.x, 0, vertex.z))
			expected_uv.append(source / WORLD_SIZE)
		for index in [0, 1, 2, 1, 3, 2]: expected_indices.append(first + index)
	var changed_y_indices: Array[int] = []
	var changed_normal_indices: Array[int] = []
	var rf_mismatches: Array[Dictionary] = []
	var vertex_deltas: Array[Dictionary] = []
	# Decode an independent same-native packing control, rather than tolerating
	# the engine's octahedral normal representation or trusting metadata normals.
	var expected_normals := PackedVector3Array()
	expected_normals.resize(expected_vertices.size())
	expected_normals.fill(Vector3.ZERO)
	for triangle in range(0, expected_indices.size(), 3):
		var a: int = expected_indices[triangle]
		var b: int = expected_indices[triangle + 1]
		var c: int = expected_indices[triangle + 2]
		var normal := (expected_vertices[c] - expected_vertices[a]).cross(expected_vertices[b] - expected_vertices[a])
		expected_normals[a] += normal
		expected_normals[b] += normal
		expected_normals[c] += normal
	for i in expected_normals.size(): expected_normals[i] = expected_normals[i].normalized()
	var control_arrays: Array = []
	control_arrays.resize(Mesh.ARRAY_MAX)
	control_arrays[Mesh.ARRAY_VERTEX] = expected_vertices
	control_arrays[Mesh.ARRAY_NORMAL] = expected_normals
	control_arrays[Mesh.ARRAY_TEX_UV] = expected_uv
	control_arrays[Mesh.ARRAY_INDEX] = expected_indices
	var control := ArrayMesh.new()
	control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, control_arrays)
	var packed_control: Array = control.surface_get_arrays(0)
	for kind: String in ["bed", "water"]:
		var meshes: Array[ArrayMesh] = []
		for prefix: String in [ORIGINAL_LOCAL, CORRECTED_LOCAL]:
			var path := prefix + "north_visual_guard_" + kind + ".res"
			var record: Dictionary = old_record if prefix == ORIGINAL_LOCAL else new_record
			var guard: Dictionary = record.get("guard_geometry", {})
			_check(guard.get(kind + "_mesh_path") == path and FileAccess.get_sha256(path).to_lower() == String(guard.get(kind + "_mesh_sha256", "")).to_lower(), "independent local resource binds recorded actual SHA: " + path)
			var mesh := load(path) as ArrayMesh
			_check(mesh != null and mesh.get_surface_count() == 1 and mesh.surface_get_primitive_type(0) == Mesh.PRIMITIVE_TRIANGLES, "actual saved local receiver triangle mesh: " + path)
			if mesh == null or mesh.get_surface_count() != 1:
				_finish()
				return
			meshes.append(mesh)
		var before := meshes[0].surface_get_arrays(0)
		var after := meshes[1].surface_get_arrays(0)
		if kind == "water":
			for attribute in Mesh.ARRAY_MAX: _check(_domain_equal(before[attribute], after[attribute]), "all actual water mesh attributes remain exact, not just metadata: " + str(attribute))
			_check(after[Mesh.ARRAY_VERTEX] == expected_water and after[Mesh.ARRAY_TEX_UV] == expected_uv and after[Mesh.ARRAY_INDEX] == expected_indices, "corrected water remains the independently reconstructed original plane stream")
			continue
		var vertices: PackedVector3Array = after[Mesh.ARRAY_VERTEX]
		var original_vertices: PackedVector3Array = before[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = after[Mesh.ARRAY_NORMAL]
		var original_normals: PackedVector3Array = before[Mesh.ARRAY_NORMAL]
		var uvs: PackedVector2Array = after[Mesh.ARRAY_TEX_UV]
		_check(vertices.size() == original_vertices.size() and normals.size() == original_normals.size() and vertices.size() == uvs.size(), "local bed arrays retain original lengths")
		_check(vertices == expected_vertices and uvs == expected_uv and after[Mesh.ARRAY_INDEX] == expected_indices, "actual corrected local bed equals independently RF/ordinal-derived vertices/UV/indices exactly")
		_check(normals == packed_control[Mesh.ARRAY_NORMAL], "actual corrected normals match independent ordinal geometry after exact same-native packing")
		for attribute in Mesh.ARRAY_MAX:
			if attribute in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL]: continue
			_check(_domain_equal(before[attribute], after[attribute]), "ordinal fix leaves all other bed attributes exactly unchanged: " + str(attribute))
		for i in mini(vertices.size(), original_vertices.size()):
			_check(vertices[i].x == original_vertices[i].x and vertices[i].z == original_vertices[i].z, "bed vertex actual XZ remains exact: " + str(i))
			if vertices[i].y != original_vertices[i].y:
				changed_y_indices.append(i)
				vertex_deltas.append({"index": i, "old": original_vertices[i], "new": vertices[i], "delta_height_m": vertices[i].y - original_vertices[i].y})
			var grid_x := clampf(float(uvs[i].x) * WORLD_SIZE.x / 6.0, 0, 768)
			var cell_x := mini(767, floori(grid_x))
			var expected_height := lerpf(float(rf[cell_x]), float(rf[cell_x + 1]), grid_x - cell_x)
			var error := absf(float(vertices[i].y) - expected_height)
			if error > .0001: rf_mismatches.append({"index": i, "actual_saved_uv": uvs[i], "original_rf_expected_height_m": expected_height, "actual_height_m": vertices[i].y, "error_m": error})
		for i in mini(normals.size(), original_normals.size()):
			if normals[i] != original_normals[i]: changed_normal_indices.append(i)
	_check(changed_y_indices == [0, 2], "exactly the two original left corners changed bed Y; no other placement change")
	_check(not changed_normal_indices.is_empty(), "actual first-segment normals respond to repaired height")
	for index in changed_normal_indices: _check(index >= 0 and index < 4, "normal changes restricted to the same first segment: " + str(index))
	_check(rf_mismatches.is_empty(), "corrected saved bed actual UV interpolates original RF within unchanged .0001m budget")
	control = null
	_checked_alpha_json(phase_output + "ordinal_local_evidence.json", {"scope": qa_scope, "old_local_result_sha256": FileAccess.get_sha256(ORIGINAL_LOCAL + "result.json"), "corrected_local_result_sha256": FileAccess.get_sha256(CORRECTED_LOCAL + "result.json"), "actual_vertex_y_changes": vertex_deltas, "changed_vertex_indices": changed_y_indices, "changed_normal_indices": changed_normal_indices, "actual_rf_mismatches": rf_mismatches, "not_whole_capture_or_visual_or_canonical_acceptance": true})
	print("[NorthGuardOrdinalLocal] changed_bed_y=%s changed_normals=%s RF_mismatches=%d; old whole OUT remains untouched, this only proves actual saved local ordinal geometry" % [changed_y_indices, changed_normal_indices, rf_mismatches.size()])
	_finish()
