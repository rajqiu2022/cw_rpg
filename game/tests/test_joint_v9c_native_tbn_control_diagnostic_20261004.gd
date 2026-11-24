extends "res://tests/test_joint_v9c_native_array_roundtrip_diagnostic_20261004.gd"

func _digest(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty(): context.update(bytes)
	return context.finish().hex_encode()

func _run() -> void:
	if FileAccess.get_sha256(MESH_PATH).to_lower() != MESH_SHA:
		quit(1)
		return
	var baseline := ResourceLoader.load(MESH_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if baseline == null or baseline.get_surface_count() != 1:
		quit(1)
		return
	var original: Array = baseline.surface_get_arrays(0)
	var control_a := ArrayMesh.new()
	var control_b := ArrayMesh.new()
	control_a.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,original.duplicate(true))
	control_b.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,original.duplicate(true))
	var altered: Array = original.duplicate(true)
	var normals: PackedVector3Array = altered[Mesh.ARRAY_NORMAL]
	normals[1] = Vector3(0.2,1.0,0.3).normalized()
	altered[Mesh.ARRAY_NORMAL] = normals
	var trial := ArrayMesh.new()
	trial.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,altered)
	var a: Array = control_a.surface_get_arrays(0)
	var b: Array = control_b.surface_get_arrays(0)
	var t: Array = trial.surface_get_arrays(0)
	var changed_rows: Array = []
	var passed := true
	for slot in Mesh.ARRAY_MAX:
		if _bytes(a[slot]) != _bytes(b[slot]) or typeof(a[slot]) != typeof(b[slot]): passed = false
		if slot not in [Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT]:
			if _bytes(t[slot]) != _bytes(original[slot]) or typeof(t[slot]) != typeof(original[slot]): passed = false
	for slot in [Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT]:
		var stride := 12 if slot == Mesh.ARRAY_NORMAL else 16
		var before := _bytes(a[slot])
		var after := _bytes(t[slot])
		var changed_vertices: Array = []
		var outside := 0
		for index in before.size()/stride:
			if before.slice(index*stride,(index+1)*stride) != after.slice(index*stride,(index+1)*stride):
				if changed_vertices.size() < 16: changed_vertices.append(index)
				if index != 1: outside += 1
		if outside != 0: passed = false
		changed_rows.append({"slot":slot,"first_changed_vertex_ids":changed_vertices,"outside_single_authorized_vertex_changes":outside})
	print(JSON.stringify({"scope":"READONLY_NATIVE_TBN_CONTROL_DIAGNOSTIC_NOT_GEOMETRY_APPROVAL","passed":passed,"original_format":baseline.surface_get_format(0),"control_format":control_a.surface_get_format(0),"trial_format":trial.surface_get_format(0),"control_repeat":_comparison(a,b),"original_roundtrip":_comparison(original,a),"normal_change_tbn_domain":changed_rows,"original_tangent_semantic_input_bytes_exact":_bytes(original[Mesh.ARRAY_TANGENT])==_bytes(altered[Mesh.ARRAY_TANGENT])}))
	baseline = null
	control_a = null
	control_b = null
	trial = null
	quit(0 if passed else 1)
