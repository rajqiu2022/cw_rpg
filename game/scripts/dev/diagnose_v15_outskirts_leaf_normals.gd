extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path: String="res://art/maps/world_map_v15_outskirts/bamboo/entities/bamboo_0_mesh.res"
	var mesh: ArrayMesh=load(path) as ArrayMesh
	if mesh==null:
		quit(1)
		return
	var records: Array[Dictionary]=[]
	for surface in range(mesh.get_surface_count()):
		var arrays: Array=mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var indices:=PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: indices=arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			for i in range(vertices.size()): indices.append(i)
		var up:=0
		var down:=0
		var mean_y:=0.
		var raw_cross_up:=0
		var raw_cross_down:=0
		for normal in normals:
			mean_y+=normal.y
			if normal.y>.01: up+=1
			if normal.y<-.01: down+=1
		for triangle in range(indices.size()/3):
			var a: Vector3=vertices[indices[triangle*3]]
			var b: Vector3=vertices[indices[triangle*3+1]]
			var c: Vector3=vertices[indices[triangle*3+2]]
			var cross_y: float=(b-a).cross(c-a).y
			if cross_y>.0000001: raw_cross_up+=1
			if cross_y<-.0000001: raw_cross_down+=1
		records.append({"surface":surface,"role":"stem" if surface==0 else "leaf","vertices":vertices.size(),"triangles":indices.size()/3,"normal_y_positive":up,"normal_y_negative":down,"mean_normal_y":mean_y/maxi(1,normals.size()),"raw_triangle_cross_y_positive":raw_cross_up,"raw_triangle_cross_y_negative":raw_cross_down})
	var output: String="res://build/world_v15_outskirts_first/leaf_normals_first.json"
	var text: String=JSON.stringify({"mesh_path":path,"mesh_sha256":FileAccess.get_sha256(path),"records":records,"producer_scope":"read actual first GPU stored mesh arrays; no material/geometry mutation"},"\t")
	var file:=FileAccess.open(output,FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print(text)
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	var cursor:=root.get_node_or_null("CursorManager")
	if cursor!=null:
		for key in ["_arrow","_hand","_wait"]: cursor.set(key,null)
	for i in range(16): await process_frame
	quit(0 if FileAccess.get_file_as_string(output)==text else 1)
