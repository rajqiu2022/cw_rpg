extends "res://tests/diagnose_world_v14_north_guard_ordinal_local.gd"

## Independent normal-only input controls determine whether engine packing
## exposes derived tangents. No attribute is exempted from exact comparison.
func _initialize() -> void:
	call_deferred("_run_packed_tangents")

func _normal_only_control(vertices: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.ZERO)
	for triangle in range(0, indices.size(), 3):
		var a: int = indices[triangle]
		var b: int = indices[triangle + 1]
		var c: int = indices[triangle + 2]
		var face := (vertices[c] - vertices[a]).cross(vertices[b] - vertices[a])
		normals[a] += face
		normals[b] += face
		normals[c] += face
	for i in normals.size(): normals[i] = normals[i].normalized()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	_check(arrays[Mesh.ARRAY_TANGENT] == null, "independent native control supplies no tangent array")
	var control := ArrayMesh.new()
	control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return control

func _run_packed_tangents() -> void:
	qa_scope = "LIMITED_LOCAL_NORTH_GUARD_NORMAL_PACKING_TANGENTS_NOT_FULL_WORLD"
	candidate_stage = true
	phase_output = OUTPUT_DIR + "north_guard_packed_tangents_" + str(int(Time.get_unix_time_from_system())) + "/"
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output)) == OK, "unique packed-array diagnosis output")
	player_saves_before = _actual_player_saves()
	prior_navigation = root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	manifest = _json(MANIFEST_PATH)
	source_contract = _json(SOURCE_PATH)
	_check(DisplayServer.get_name() == "headless", "serialized root-only local packing diagnosis has no Field/GPU")
	var old_record := _json(ORIGINAL_LOCAL + "result.json")
	var new_record := _json(CORRECTED_LOCAL + "result.json")
	_check(new_record.get("executed_builder_sha256") == CORRECTED_SOURCE_SHA, "corrected actual local evidence binds approved 111CCF executed source")
	var file := FileAccess.open(ART_DIR + "height_grid.rf", FileAccess.READ)
	_check(file != null, "unchanged original RF available")
	if file == null:
		_finish()
		return
	var bytes := file.get_buffer(file.get_length())
	var error := file.get_error()
	file.close()
	file = null
	_check(error == OK and bytes.size() == 769 * 513 * 4 and FileAccess.get_sha256(ART_DIR + "height_grid.rf").to_lower() == NORTH_GUARD_PRIOR_AUTHORITY_SHAS["height_grid.rf"], "normal packing controls derive from exact original RF bytes")
	if error != OK or bytes.size() != 769 * 513 * 4:
		_finish()
		return
	var rf := bytes.to_float32_array()
	var corrected := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var metres := Vector2(45.0, 42.42640687)
	for cell in 768:
		var h0: float = rf[cell]
		var h1: float = rf[cell + 1]
		if h0 >= -.025 and h1 >= -.025: continue
		var a := (-.025 - h0) / (h1 - h0) if h0 >= -.025 else 0.0
		var b := (-.025 - h0) / (h1 - h0) if h1 >= -.025 else 1.0
		var left: float = (cell + a) * 6.0
		var right: float = (cell + b) * 6.0
		if right - left < .000001: continue
		var first := corrected.size()
		var corners: Array[Vector2] = [Vector2(left, -96), Vector2(right, -96), Vector2(left, 0), Vector2(right, 0)]
		for corner in 4:
			var point: Vector2 = corners[corner]
			var y := lerpf(h0, h1, a if corner % 2 == 0 else b)
			corrected.append(Vector3((point.x / WORLD_SIZE.x - .5) * metres.x, y, (point.y / WORLD_SIZE.y - .5) * metres.y))
			uvs.append(point / WORLD_SIZE)
		for i in [0, 1, 2, 1, 3, 2]: indices.append(first + i)
	_check(corrected.size() >= 4, "original wet RF supplies first clipped receiver segment")
	if corrected.size() < 4:
		_finish()
		return
	# Independently model the two PROVEN historical wrong-corner heights, not
	# the saved old arrays or the unreliable Float32 x==double-left branch.
	var historical := corrected.duplicate()
	historical[0].y = corrected[1].y
	historical[2].y = corrected[1].y
	var controls: Array[ArrayMesh] = [_normal_only_control(historical, uvs, indices), _normal_only_control(corrected, uvs, indices)]
	var bed_arrays: Array[Array] = []
	var resource_bindings: Array[Dictionary] = []
	var controls_match := true
	var water_unchanged := true
	var mismatched_control_attributes: Array[Dictionary] = []
	for kind: String in ["bed", "water"]:
		var pair: Array[Array] = []
		for index in 2:
			var prefix: String = ORIGINAL_LOCAL if index == 0 else CORRECTED_LOCAL
			var record: Dictionary = old_record if index == 0 else new_record
			var path := prefix + "north_visual_guard_" + kind + ".res"
			var actual_sha := FileAccess.get_sha256(path).to_lower()
			var binding: Dictionary = record.get("guard_geometry", {})
			_check(binding.get(kind + "_mesh_path") == path and actual_sha.length() == 64 and String(binding.get(kind + "_mesh_sha256", "")).to_lower() == actual_sha, "actual saved local ArrayMesh path/SHA binds before/after: " + path)
			resource_bindings.append({"path": path, "sha256": actual_sha})
			var mesh := load(path) as ArrayMesh
			_check(mesh != null and mesh.get_surface_count() == 1, "actual local receiver ArrayMesh exists")
			if mesh == null or mesh.get_surface_count() != 1:
				_finish()
				return
			var actual: Array = mesh.surface_get_arrays(0)
			pair.append(actual)
			if kind == "bed":
				var independently_packed: Array = controls[index].surface_get_arrays(0)
				for attribute in Mesh.ARRAY_MAX:
					var exact := _domain_equal(actual[attribute], independently_packed[attribute])
					controls_match = controls_match and exact
					if not exact: mismatched_control_attributes.append({"before_after": index, "attribute": attribute})
					_check(exact, "all actual bed attributes including tangent EXACTLY match independent RF/ordinal normal-only input native packing: before_after=%d attribute=%d" % [index, attribute])
			mesh = null
		if kind == "water":
			for attribute in Mesh.ARRAY_MAX:
				var exact := _domain_equal(pair[0][attribute], pair[1][attribute])
				water_unchanged = water_unchanged and exact
				_check(exact, "actual water all-attribute arrays remain exactly unchanged: " + str(attribute))
		else: bed_arrays = pair
	var changed_y: Array[int] = []
	var changed_normals: Array[int] = []
	var changed_tangents: Array[int] = []
	var tangent_deltas: Array[Dictionary] = []
	var old_vertices: PackedVector3Array = bed_arrays[0][Mesh.ARRAY_VERTEX]
	var new_vertices: PackedVector3Array = bed_arrays[1][Mesh.ARRAY_VERTEX]
	var old_normals: PackedVector3Array = bed_arrays[0][Mesh.ARRAY_NORMAL]
	var new_normals: PackedVector3Array = bed_arrays[1][Mesh.ARRAY_NORMAL]
	var old_tangents: PackedFloat32Array = bed_arrays[0][Mesh.ARRAY_TANGENT]
	var new_tangents: PackedFloat32Array = bed_arrays[1][Mesh.ARRAY_TANGENT]
	_check(old_vertices.size() == new_vertices.size() and old_normals.size() == new_normals.size() and old_tangents.size() == new_tangents.size() and new_tangents.size() == new_vertices.size() * 4, "engine-returned tangent stream has actual four components per vertex with unchanged length")
	for i in mini(old_vertices.size(), new_vertices.size()):
		_check(old_vertices[i].x == new_vertices[i].x and old_vertices[i].z == new_vertices[i].z, "actual bed XZ unchanged")
		if old_vertices[i].y != new_vertices[i].y: changed_y.append(i)
		if old_normals[i] != new_normals[i]: changed_normals.append(i)
		var changed := false
		if i * 4 + 3 < mini(old_tangents.size(), new_tangents.size()):
			for component in 4:
				var offset := i * 4 + component
				if old_tangents[offset] == new_tangents[offset]: continue
				changed = true
				tangent_deltas.append({"vertex": i, "component": component, "old_full_precision": JSON.stringify(old_tangents[offset], "", true, true), "new_full_precision": JSON.stringify(new_tangents[offset], "", true, true)})
		if changed: changed_tangents.append(i)
	_check(changed_y == [0, 2], "actual bed height changes remain exactly original two left corners")
	_check(not changed_normals.is_empty() and not changed_tangents.is_empty(), "actual normal/tangent decoded changes independently reproduced by two no-tangent input controls")
	for list: Array in [changed_normals, changed_tangents]:
		for index: int in list: _check(index >= 0 and index < 4, "all actual normal/derived-tangent changes limited to original first segment: " + str(index))
	for attribute in Mesh.ARRAY_MAX:
		if attribute in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TANGENT]: continue
		_check(_domain_equal(bed_arrays[0][attribute], bed_arrays[1][attribute]), "all remaining bed attributes strictly unchanged: " + str(attribute))
	controls.clear()
	_checked_alpha_json(phase_output + "packed_tangent_evidence.json", {"scope": qa_scope, "source_normal_only_input_no_tangent": true, "before_after_all_attributes_match_independent_native_controls": controls_match, "control_mismatched_attributes": mismatched_control_attributes, "water_all_attributes_exact_unchanged": water_unchanged, "actual_bound_resources": resource_bindings, "changed_bed_y": changed_y, "changed_normals": changed_normals, "changed_tangents": changed_tangents, "actual_tangent_component_deltas": tangent_deltas, "original_BFE26_237_checks_1_fail_preserved": true, "not_a_whole_geometry_or_visual_approval": true})
	print("[NorthGuardPackedTangents] actual_y_changes=%s normals=%s tangents=%s; ALL actual arrays checked against independent RF geometry/native normal-only inputs, original water arrays exact" % [changed_y, changed_normals, changed_tangents])
	_finish()
