extends "res://tests/world_map_v14_fourth_failure_diagnostic_20261002.gd"

func _model_geometry(mesh: ArrayMesh, metadata: Dictionary) -> Dictionary:
	var basis := Basis(Vector3.UP, deg_to_rad(float(metadata.yaw))) * Basis.from_scale(Vector3.ONE * float(metadata.model_scale))
	var points := PackedVector3Array()
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var seen: Dictionary = {}
		for i: int in arrays[Mesh.ARRAY_INDEX]:
			if seen.has(i): continue
			seen[i] = true
			points.append(basis * arrays[Mesh.ARRAY_VERTEX][i])
	var bounds := AABB(points[0], Vector3.ZERO)
	for p in points: bounds = bounds.expand(p)
	var lowest: Array[Vector3] = []
	for p in points:
		if p.y <= bounds.position.y + bounds.size.y * .06: lowest.append(p)
	var support := AABB(lowest[0], Vector3.ZERO)
	for p in lowest: support = support.expand(p)
	var contact := Vector3(support.get_center().x, bounds.position.y, support.end.z)
	var vertex_extent := 0.0
	for p in points:
		var r := p - contact
		vertex_extent = maxf(vertex_extent, maxf(absf(r.x * 102.4), absf((r.z - r.y) * 102.4 / sqrt(2.0))))
	var corner_extent := 0.0
	for i in 8:
		var r := bounds.get_endpoint(i) - contact
		corner_extent = maxf(corner_extent, maxf(absf(r.x * 102.4), absf((r.z - r.y) * 102.4 / sqrt(2.0))))
	var source := _point(metadata.source_foot)
	var ground := Vector3((source.x / WORLD_SIZE.x - .5) * 45., _height_at(source), (source.y / WORLD_SIZE.y - .5) * 42.42640687)
	return {"vertices": points.size(), "bounds_min": bounds.position, "bounds_size": bounds.size, "contact": contact, "ground": ground, "position": ground-contact, "position_error": (ground-contact).distance_to(_vec3(metadata.model_position_m)), "contact_error": contact.distance_to(_vec3(metadata.support_contact_m)), "ground_error": ground.distance_to(_vec3(metadata.ground_m)), "tight_canvas": maxi(512, int(ceil((vertex_extent*2+32)/256))*256), "corner_canvas": maxi(512, int(ceil((corner_extent*2+32)/256))*256), "actual_canvas": metadata.sourcebody_canvas}

func _raw_mesh(path: String) -> ArrayMesh:
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	assert(doc.append_from_file(path, state) == OK)
	var node := doc.generate_scene(state)
	var meshes: Array[MeshInstance3D] = []
	_collect_source_meshes(node, meshes)
	var mesh := meshes[0].mesh as ArrayMesh
	node.free()
	return mesh

func _run() -> void:
	_load_actual_geometry()
	var uv_mismatches := 0
	var integer_mismatches := 0
	for y in terrain_rows:
		for x in terrain_cols:
			var a := Vector2(float(x)/terrain_cols, float(y)/terrain_rows)
			var b := Vector2(float(x+1)/terrain_cols, float(y)/terrain_rows)
			var c := Vector2(float(x)/terrain_cols, float(y+1)/terrain_rows)
			var d := Vector2(float(x+1)/terrain_cols, float(y+1)/terrain_rows)
			var expected := [a,b,c,b,d,c]
			var row := y * (terrain_cols+1) + x
			var old_ids := [row,row+1,row+terrain_cols+1,row+1,row+terrain_cols+2,row+terrain_cols+1]
			var first := (y*terrain_cols+x)*6
			for offset in 6:
				if terrain_uvs[terrain_indices[first+offset]] != expected[offset]: uv_mismatches += 1
				if terrain_indices[first+offset] != old_ids[offset]: integer_mismatches += 1
	diagnosis["terrain_index_uv"] = {"actual_index_to_expected_uv_mismatches":uv_mismatches, "old_rowmajor_integer_mismatches":integer_mismatches, "actual_triangles":terrain_indices.size()/3}
	_check(uv_mismatches == 0, "actual indexed UV occupies every expected source triangle")
	var cliff := _json(ART_DIR + "entities/native_cliff_south.json")
	var raw := _raw_mesh(String(cliff.source))
	var imported := (load(String(cliff.source)) as PackedScene).instantiate()
	var meshes: Array[MeshInstance3D] = []
	_collect_source_meshes(imported, meshes)
	diagnosis["cliff_raw"] = _model_geometry(raw, cliff)
	diagnosis["cliff_actual_import"] = _model_geometry(meshes[int(cliff.source_variant)].mesh as ArrayMesh, cliff)
	_check(float(diagnosis.cliff_actual_import.position_error) < .0001 and float(diagnosis.cliff_actual_import.contact_error) < .0001, "actual executed imported cliff support agrees with captured transform")
	imported.free()
	var tree := _json(ART_DIR + "entities/native_tree_10.json")
	var original := _raw_mesh(String(tree.source))
	var actual := load(String(tree.derived_mesh_recipe.derived_mesh_path)) as ArrayMesh
	var importer := ImporterMesh.new()
	for surface in original.get_surface_count(): importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, original.surface_get_arrays(surface), [], {}, original.surface_get_material(surface))
	importer.generate_lods(60.,60.,[])
	var expected_mesh := ArrayMesh.new()
	var surfaces: Array = []
	for surface in original.get_surface_count():
		var arrays := original.surface_get_arrays(surface).duplicate()
		var expected_indices := importer.get_surface_lod_indices(surface,2)
		arrays[Mesh.ARRAY_INDEX] = expected_indices
		expected_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var repacked := expected_mesh.surface_get_arrays(surface)
		var captured := actual.surface_get_arrays(surface)
		var record := {"surface":surface, "index_equal": captured[Mesh.ARRAY_INDEX].to_byte_array() == expected_indices.to_byte_array()}
		for entry in [["vertex",Mesh.ARRAY_VERTEX],["uv",Mesh.ARRAY_TEX_UV],["normal",Mesh.ARRAY_NORMAL]]:
			var attribute := int(entry[1])
			record[String(entry[0])+"_raw_equal"] = _array_sha(original.surface_get_arrays(surface)[attribute]) == _array_sha(captured[attribute])
			record[String(entry[0])+"_native_packed_equal"] = _array_sha(repacked[attribute]) == _array_sha(captured[attribute])
			_check(bool(record[String(entry[0])+"_native_packed_equal"]), "native independently rebuilt attribute exact: surface%d %s" % [surface,entry[0]])
		_check(bool(record.index_equal), "independent native LOD2 index exact surface%d" % surface)
		surfaces.append(record)
	diagnosis["tree_surfaces"] = surfaces
	diagnosis["tree10_canvas"] = _model_geometry(actual,tree)
	_check(int(diagnosis.tree10_canvas.corner_canvas) == int(_point(tree.sourcebody_canvas).x), "actual conservative AABB8corner body canvas is exact")
	diagnosis["checks"] = checks; diagnosis["failures"] = failed
	var path := "res://build/world_map_v14_fourth_independent_geometry_%d.json" % int(Time.get_unix_time_from_system())
	var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(diagnosis,"\t")); file.close()
	print("[FourthGeometry] ",JSON.stringify(diagnosis), " path=",path)
	quit(0 if failed == 0 else 1)
