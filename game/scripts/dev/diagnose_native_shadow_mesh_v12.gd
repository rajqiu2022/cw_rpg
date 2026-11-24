extends "res://scripts/dev/diagnose_native_shadow_transition_v12.gd"

const MESH_PREFIX := "res://build/native_shadow_mesh_v12_"
var _mesh_results: Array[Dictionary]=[]


func _initialize() -> void:
	call_deferred("_mesh_matrix")


func _array_hash(value: PackedByteArray) -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(value)
	return hash.finish().hex_encode()


func _mesh_statistics(mesh: Mesh) -> Dictionary:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	var up := 0
	var down := 0
	var flat := 0
	var min_cross_y := INF
	var max_cross_y := -INF
	var min_normal_y := INF
	var max_normal_y := -INF
	var count := indices.size() if not indices.is_empty() else vertices.size()
	for index in range(0,count,3):
		var a: Vector3=vertices[indices[index] if not indices.is_empty() else index]
		var b: Vector3=vertices[indices[index+1] if not indices.is_empty() else index+1]
		var c: Vector3=vertices[indices[index+2] if not indices.is_empty() else index+2]
		var cross_y := (b-a).cross(c-a).y
		min_cross_y=minf(min_cross_y,cross_y)
		max_cross_y=maxf(max_cross_y,cross_y)
		if cross_y>0:
			up+=1
		elif cross_y<0:
			down+=1
		else:
			flat+=1
	for normal in normals:
		min_normal_y=minf(min_normal_y,normal.y)
		max_normal_y=maxf(max_normal_y,normal.y)
	return {"vertices":vertices.size(),"triangles":count/3,"cross_y_positive":up,"cross_y_negative":down,"cross_y_zero":flat,"min_cross_y":min_cross_y,"max_cross_y":max_cross_y,"min_normal_y":min_normal_y,"max_normal_y":max_normal_y,"vertex_sha256":_array_hash(vertices.to_byte_array()),"normal_sha256":_array_hash(normals.to_byte_array()),"UV_sha256":_array_hash(uv.to_byte_array()),"index_sha256":_array_hash(indices.to_byte_array()),"front_facing_not_inferred_from_normals":true}


func _reversed(mesh: ArrayMesh) -> ArrayMesh:
	var result := ArrayMesh.new()
	# Preserve engine-packed vertex/normal/UV streams exactly. Round-tripping
	# surface_get_arrays -> add_surface_from_arrays re-quantizes packed normals.
	var packed_surfaces: Array=mesh.get("_surfaces").duplicate(true)
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		assert(not indices.is_empty())
		for index in range(0,indices.size(),3):
			var second := indices[index+1]
			indices[index+1]=indices[index+2]
			indices[index+2]=second
		var packed_indices: PackedByteArray=packed_surfaces[surface]["index_data"]
		var stride := packed_indices.size()/indices.size()
		assert(stride==2 or stride==4)
		for index in indices.size():
			if stride==2:
				packed_indices.encode_u16(index*2,indices[index])
			else:
				packed_indices.encode_u32(index*4,indices[index])
		packed_surfaces[surface]["index_data"]=packed_indices
	result.set("_surfaces",packed_surfaces)
	var before := mesh.surface_get_arrays(0)
	var after := result.surface_get_arrays(0)
	var original_indices: PackedInt32Array=before[Mesh.ARRAY_INDEX]
	var reversed_indices: PackedInt32Array=after[Mesh.ARRAY_INDEX]
	var original_vertices: PackedVector3Array=before[Mesh.ARRAY_VERTEX]
	var reversed_vertices: PackedVector3Array=after[Mesh.ARRAY_VERTEX]
	assert(original_vertices==reversed_vertices)
	assert(before[Mesh.ARRAY_NORMAL]==after[Mesh.ARRAY_NORMAL])
	assert(before[Mesh.ARRAY_TEX_UV]==after[Mesh.ARRAY_TEX_UV])
	assert(original_indices.size()==reversed_indices.size())
	for index in range(0,original_indices.size(),3):
		assert(reversed_indices[index]==original_indices[index])
		assert(reversed_indices[index+1]==original_indices[index+2])
		assert(reversed_indices[index+2]==original_indices[index+1])
		var a := original_vertices[original_indices[index]]
		var b := original_vertices[original_indices[index+1]]
		var c := original_vertices[original_indices[index+2]]
		assert((b-a).cross(c-a)==-(c-a).cross(b-a))
	return result


func _mesh_case(kind: String) -> void:
	var fixture := _transition_fixture("actual_v11_mesh")
	var receiver: MeshInstance3D=fixture["receiver"]
	var original := _mesh_statistics(receiver.mesh)
	if kind=="reverse_winding":
		receiver.mesh=_reversed(receiver.mesh)
	elif kind=="standard_material":
		var material := StandardMaterial3D.new()
		material.albedo_color=Color(0.36,0.41,0.30)
		material.roughness=1.0
		# Match the original shader's visible cull_disabled, not a culling fix.
		material.cull_mode=BaseMaterial3D.CULL_DISABLED
		receiver.material_override=material
	elif kind=="flat_actual_topology":
		receiver.mesh=_local_surface.call("_mesh",_topology,true)
		receiver.position.y=_rock["ground_world"].y
	var actual := _mesh_statistics(receiver.mesh)
	if kind=="reverse_winding":
		assert(original["vertex_sha256"]==actual["vertex_sha256"] and original["normal_sha256"]==actual["normal_sha256"] and original["UV_sha256"]==actual["UV_sha256"])
		assert(actual["cross_y_negative"]==36800 and actual["cross_y_zero"]==0)
	var body: Image=await _body_alpha(fixture)
	_set_cast(fixture,"shadows_only",true)
	await _settle()
	var viewport: SubViewport=fixture["viewport"]
	var on := viewport.get_texture().get_image()
	await _settle()
	var on_repeat := viewport.get_texture().get_image()
	_set_cast(fixture,"shadows_only",false)
	await _settle()
	var off := viewport.get_texture().get_image()
	await _settle()
	var off_repeat := viewport.get_texture().get_image()
	var difference := _difference(on,off,body,"shadows_only")
	var captures := {"on":on,"off":off,"on_repeat":on_repeat,"off_repeat":off_repeat,"body":body,"difference":difference["full"],"ground_difference":difference["ground"]}
	for suffix: String in captures:
		assert(captures[suffix].save_png(MESH_PREFIX+kind+"_"+suffix+".png")==OK)
	var on_stable := FileAccess.get_sha256(MESH_PREFIX+kind+"_on.png")==FileAccess.get_sha256(MESH_PREFIX+kind+"_on_repeat.png")
	var off_stable := FileAccess.get_sha256(MESH_PREFIX+kind+"_off.png")==FileAccess.get_sha256(MESH_PREFIX+kind+"_off_repeat.png")
	var body_stats := _body_statistics(body)
	var valid: bool=body_stats["valid"] and on_stable and off_stable and on.get_size()==SIZE and off.get_size()==SIZE
	var camera: Camera3D=fixture["camera"]
	var ground: Vector3=_rock["ground_world"]
	var projected := camera.unproject_position(ground)
	var node: Node3D=_rock["node"]
	var spec: Dictionary=_rock["spec"]
	var config := {"case":kind,"valid_case":valid,"capture_class":"INVALID_CAPTURE" if not valid else "VALID_NONEMPTY" if difference["statistics"]["outside_body_ground_pixels"]>0 else "VALID_EMPTY","statistics":difference["statistics"],"body_alpha":body_stats,"on_repeat_exact":on_stable,"off_repeat_exact":off_stable,"mesh_before":original,"mesh_after":actual,"vertex_UV_normal_unchanged":original["vertex_sha256"]==actual["vertex_sha256"] and original["normal_sha256"]==actual["normal_sha256"] and original["UV_sha256"]==actual["UV_sha256"],"only_case_variable":kind,"canvas":[SIZE.x,SIZE.y],"actual_model_position":[node.position.x,node.position.y,node.position.z],"source_foot":[spec["foot"].x,spec["foot"].y],"camera_unprojected_foot":[projected.x,projected.y],"ground_world":[ground.x,ground.y,ground.z],"receiver_y":receiver.position.y,"source":spec["source"],"source_sha256":FileAccess.get_sha256(spec["source"]),"topology_sha256":FileAccess.get_sha256(TOPOLOGY),"source_topology":TOPOLOGY,"source_mesh":"exact_v11_mesh","material":"StandardMaterial3D_cull_disabled" if kind=="standard_material" else "exact_v11_surface_material_cull_disabled","caster_layer":1,"camera_mask":1,"cast":"same_layer_SHADOWS_ONLY_ON_vs_hidden_OFF","camera_position":[0,12,12],"camera_size":10,"light_rotation":[-55,-34,0],"energy":1.15,"ambient":0.62,"shadow_mode":"PARALLEL_2_SPLITS","max_distance":32,"bias":0.02,"normal_bias":0.08,"sync":"6_process_frames_then_frame_post_draw_per_state_and_repeat","paths":{"on":MESH_PREFIX+kind+"_on.png","off":MESH_PREFIX+kind+"_off.png","body":MESH_PREFIX+kind+"_body.png","ground_difference":MESH_PREFIX+kind+"_ground_difference.png"},"old_outputs_written":false}
	_json(MESH_PREFIX+kind+".json",config)
	_mesh_results.append(config)
	print("[NativeShadowMeshV12] ",kind," ground=",difference["statistics"]["outside_body_ground_pixels"]," valid=",valid," cross+=",actual["cross_y_positive"]," cross-=",actual["cross_y_negative"])
	viewport.queue_free()
	await process_frame


func _mesh_matrix() -> void:
	_topology=Image.load_from_file(TOPOLOGY)
	assert(_topology!=null)
	_local_surface=LOCAL_SURFACE.new()
	_local_surface.call("_prepare_models",_topology)
	var entries: Array=_local_surface.get("_models")
	assert(entries.size()==10)
	_rock=entries[0]
	if "--geometry-only" in OS.get_cmdline_user_args():
		var actual: ArrayMesh=_local_surface.call("_mesh",_topology,false)
		var reversed := _reversed(actual)
		var flat_mesh: ArrayMesh=_local_surface.call("_mesh",_topology,true)
		var engine_plane := PlaneMesh.new()
		engine_plane.size=Vector2(30,14.1421356)
		_json(MESH_PREFIX+"geometry_preflight.json",{"actual":_mesh_statistics(actual),"reverse":_mesh_statistics(reversed),"flat":_mesh_statistics(flat_mesh),"engine_PlaneMesh":_mesh_statistics(engine_plane),"no_GPU_capture":true})
		for entry in entries:
			entry["node"].free()
		_local_surface.free()
		quit(0)
		return
	for kind in ["actual_original","reverse_winding","standard_material","flat_actual_topology"]:
		await _mesh_case(kind)
	var invalid := false
	for entry in _mesh_results:
		invalid=invalid or not entry["valid_case"]
	_json(MESH_PREFIX+"matrix.json",{"status":"INVALID_CAPTURE" if invalid else "MESH_VARIABLE_EVIDENCE_NOT_FORMAL_PASS","cases":_mesh_results,"GPU_matrix_count":1,"max_cases":4,"no_full_map_outputs":true,"old_scripts_outputs_frozen":true})
	for entry in entries:
		entry["node"].free()
	_local_surface.free()
	await process_frame
	quit(1 if invalid else 0)
