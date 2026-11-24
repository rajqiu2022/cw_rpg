extends SceneTree

# Independent actual-resource comparison. Does not invoke any art builder.
const OLD := "res://build/luoyang_modular_v3_root070_before_masonry/art/"
const NEW := "res://art/maps/luoyang_modular_v3/"
const OUTPUT := "res://build/luoyang_v3_masonry_only_verification/"
const REGIONS := ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s3_luoyang_market","ch4_s2_canal_docks"]
const OBJECT_INVARIANTS := ["id","prototype","blocking","world_foot_px","depth_foot_y","physical_center_px","collision_size_px","solid_polygons_px","native_transform","foot_uv","render_size_px","source_size_px","source_semantics","original_source","original_source_sha256","role","ghost_occlusion","walk_support"]
const PROTOTYPE_INVARIANTS := ["kind","draw_basis_columns","support_m","used_bounds_m","actual_used_vertices","scale","source_min_vertex_ground_delta_m","raw_camera","crop_rect_px","foot_uv","render_size_px","source_size_px"]
const CONTRACT_INVARIANTS := ["scene_id","canonical_scene_id","logical_size_px","pixel_sampling","physical_navigation_margin_px","ordinary_actor_body_px","ordinary_actor_visual_scale","ordinary_actor_effective_height_px","entry_foot_px","return_foot_px","routes","gameplay_slots","interaction_anchors","npc_stations","height_grid","navigation_recipe","capture_camera","authority_camera"]
var checks := 0
var failures: Array[Dictionary]=[]
var evidence: Array[Dictionary]=[]
var input_sha256: Dictionary={}
var expected_mesh_pairs := 0
var attempted_mesh_pairs := 0
var completed_mesh_pairs := 0
var expected_surfaces := 0
var completed_surfaces := 0
var completed_array_slots := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if "--verify-luoyang-masonry-only" not in OS.get_cmdline_user_args():
		push_error("Explicit material-only comparison argument required.")
		await _finish(2)
		return
	var output: String=OUTPUT+str(Time.get_unix_time_from_system()).replace(".","_")+"/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for region: String in REGIONS:
		_verify_region(region)
	var old_sources: Array[String]=_files(OLD+"source/",".png")
	var new_sources: Array[String]=_files(NEW+"source/",".png")
	_check(old_sources==new_sources,"common source PNG sets",{"old":old_sources,"new":new_sources})
	for relative: String in old_sources:
		_file_pair(OLD+"source/"+relative,NEW+"source/"+relative,"original common PNG")
	_file_pair("res://build/luoyang_modular_v3_root070_before_masonry/luoyang_modular_v3_source.gd","res://scripts/dev/luoyang_modular_v3_source.gd","unchanged source layout script")
	# All reads above are independently computed; metadata array hashes are
	# deliberately NOT consulted as equality oracles.
	for path: String in input_sha256:
		_check(FileAccess.get_sha256(path)==input_sha256[path],"input remained unchanged during verification",{"path":path})
	_check(expected_mesh_pairs>0 and attempted_mesh_pairs==expected_mesh_pairs and completed_mesh_pairs==expected_mesh_pairs,"all enumerated actual mesh pairs completed",{"expected":expected_mesh_pairs,"attempted":attempted_mesh_pairs,"completed":completed_mesh_pairs})
	_check(expected_surfaces>0 and completed_surfaces==expected_surfaces,"all actual surface comparisons completed",{"expected":expected_surfaces,"completed":completed_surfaces,"array_slots":completed_array_slots})
	var result: Dictionary={"status":"ACTUAL_MATERIAL_ONLY_GEOMETRY_COMPARISON","passed":failures.is_empty(),"checks":checks,"failures":failures,"evidence":evidence,"input_sha256":input_sha256,"old_root":OLD,"new_root":NEW,"executed_fixture_path":get_script().resource_path,"executed_fixture_sha256":FileAccess.get_sha256(get_script().resource_path),"scope":"Direct old/new CACHE_MODE_IGNORE Mesh surface arrays and selected geometry/physical/foot contracts; authority PNG/RF and original generated PNG exact bytes. NOT whole-manifest byte equality, Field gameplay or visual approval.","material_resources_excluded_from_array_comparison":true,"native_array_metadata_hashes_used_as_oracle":false,"no_art_writes":true,"no_capture_or_builder_execution":true}
	result["actual_completion_counts"]={"expected_mesh_pairs":expected_mesh_pairs,"attempted_mesh_pairs":attempted_mesh_pairs,"completed_mesh_pairs":completed_mesh_pairs,"expected_surfaces":expected_surfaces,"completed_surfaces":completed_surfaces,"completed_array_slots":completed_array_slots}
	if not _write(output+"result.json",result):
		await _finish(1)
		return
	print("LUOYANG_MASONRY_ONLY_ACTUAL_COMPARISON ",checks," checks / ",failures.size()," failures: ",output)
	await _finish(0 if failures.is_empty() else 1)

func _verify_region(region: String) -> void:
	var old_root: String=OLD+region+"/"
	var new_root: String=NEW+region+"/"
	var old_contract: Dictionary=_json(old_root+"art_contract.json")
	var new_contract: Dictionary=_json(new_root+"art_contract.json")
	if old_contract.is_empty() or new_contract.is_empty(): return
	for key: String in CONTRACT_INVARIANTS:
		_compare_field(old_contract,new_contract,key,region+" contract")
	for filename: String in ["land.png","raw_walk.png","walk.png","terrain_height.rf"]:
		_file_pair(old_root+filename,new_root+filename,region+" authority bytes")
	var old_meshes: Array[String]=_files(old_root,".res")
	var new_meshes: Array[String]=_files(new_root,".res")
	_check(not old_meshes.is_empty() and old_meshes==new_meshes,region+" actual mesh file sets",{"old":old_meshes,"new":new_meshes})
	expected_mesh_pairs+=old_meshes.size()
	for relative: String in old_meshes:
		_mesh_pair(old_root+relative,new_root+relative)
	var old_objects: Dictionary={}
	var new_objects: Dictionary={}
	for object: Dictionary in old_contract.get("objects",[]):
		var id: String=object.get("id","")
		_check(id!="" and not old_objects.has(id),region+" old unique object ID",{"id":id})
		old_objects[id]=object
	for object: Dictionary in new_contract.get("objects",[]):
		var id: String=object.get("id","")
		_check(id!="" and not new_objects.has(id),region+" new unique object ID",{"id":id})
		new_objects[id]=object
	var old_ids: Array=old_objects.keys()
	var new_ids: Array=new_objects.keys()
	old_ids.sort()
	new_ids.sort()
	_check(old_ids==new_ids,region+" exact object IDs",{"old":old_ids,"new":new_ids})
	var measured_prototypes: Dictionary={}
	for id: String in old_objects:
		if not new_objects.has(id): continue
		var before: Dictionary=old_objects[id]
		var after: Dictionary=new_objects[id]
		for key: String in OBJECT_INVARIANTS:
			_compare_field(before,after,key,region+" object "+id)
		var kind: String=before.get("prototype","")
		if kind=="":
			# Original building/prop byte copies are immutable, including weak alpha.
			var texture: String=before.get("texture","")
			_check(texture.begins_with(new_root),region+" original texture bounded",{"id":id,"path":texture})
			if texture.begins_with(new_root):
				_file_pair(old_root+texture.trim_prefix(new_root),after.get("texture",""),region+" original entity PNG "+id)
			_compare_field(before,after,"source_sha256",region+" original source SHA "+id)
			var source_path: String=after.get("source","")
			_pin(source_path)
			_check(FileAccess.get_sha256(source_path)==before.get("source_sha256","INVALID"),region+" original authoring PNG SHA",{"id":id,"path":source_path})
		elif not measured_prototypes.has(kind):
			measured_prototypes[kind]=true
			var relative: String="entities/native_"+kind+".json"
			var old_proto: Dictionary=_json(old_root+relative)
			var new_proto: Dictionary=_json(new_root+relative)
			if old_proto.is_empty() or new_proto.is_empty(): continue
			for key: String in PROTOTYPE_INVARIANTS:
				_compare_field(old_proto,new_proto,key,region+" actual native "+kind)

func _mesh_pair(old_path: String,new_path: String) -> void:
	attempted_mesh_pairs+=1
	_pin(old_path)
	_pin(new_path)
	if not FileAccess.file_exists(old_path) or not FileAccess.file_exists(new_path): return
	var before: Mesh=ResourceLoader.load(old_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	var after: Mesh=ResourceLoader.load(new_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	_check(before!=null and after!=null,"actual saved Mesh load",{"old":old_path,"new":new_path,"cache_mode":"CACHE_MODE_IGNORE"})
	if before==null or after==null: return
	expected_surfaces+=before.get_surface_count()
	_check(before.get_surface_count()==after.get_surface_count(),"actual surface count",{"old":old_path,"new":new_path,"old_count":before.get_surface_count(),"new_count":after.get_surface_count()})
	if before is PrimitiveMesh and after is PrimitiveMesh:
		var old_faces: PackedVector3Array=before.get_faces()
		var new_faces: PackedVector3Array=after.get_faces()
		var complete_faces: bool=not old_faces.is_empty() and old_faces.size()%3==0 and old_faces.size()==new_faces.size()
		_check(complete_faces and old_faces.to_byte_array()==new_faces.to_byte_array(),"PrimitiveMesh native get_faces OLD vs NEW direct bytes",{"old":old_path,"new":new_path,"old_face_vertices":old_faces.size(),"new_face_vertices":new_faces.size(),"old_sha256":_sha(old_faces.to_byte_array()),"new_sha256":_sha(new_faces.to_byte_array())})
		var old_parameters: Dictionary=_primitive_storage(before)
		var new_parameters: Dictionary=_primitive_storage(after)
		var old_names: Array=old_parameters.keys()
		var new_names: Array=new_parameters.keys()
		old_names.sort()
		new_names.sort()
		_check(not old_names.is_empty() and old_names==new_names,"PrimitiveMesh stored parameter sets excluding materials",{"old":old_path,"new":new_path,"old_names":old_names,"new_names":new_names})
		for parameter: String in old_names:
			_compare_field(old_parameters,new_parameters,parameter,"PrimitiveMesh stored parameter "+new_path)
		evidence.append({"role":"PrimitiveMesh actual stored geometry parameters","old_path":old_path,"new_path":new_path,"old_parameters":old_parameters,"new_parameters":new_parameters,"material_excluded":true,"native_get_faces_compared_old_to_new_not_to_other_API":true})
	var surface_records: Array[Dictionary]=[]
	for surface in range(mini(before.get_surface_count(),after.get_surface_count())):
		var old_arrays: Array=before.surface_get_arrays(surface)
		var new_arrays: Array=after.surface_get_arrays(surface)
		var old_primitive: Dictionary=_primitive_record(before,surface,old_arrays,old_path)
		var new_primitive: Dictionary=_primitive_record(after,surface,new_arrays,new_path)
		_check(not old_primitive.is_empty() and not new_primitive.is_empty() and old_primitive==new_primitive,"actual surface primitive",{"path":new_path,"surface":surface,"old":old_primitive,"new":new_primitive})
		_check(old_arrays.size()==new_arrays.size(),"actual surface array slots",{"path":new_path,"surface":surface})
		var slots: Array[Dictionary]=[]
		for slot in range(mini(old_arrays.size(),new_arrays.size())):
			# Compare every actual slot, including tangents/colours/bones, not just
			# the four mandatory vertex/normal/UV/index fields in new metadata.
			var old_value: Variant=old_arrays[slot]
			var new_value: Variant=new_arrays[slot]
			var old_bytes: PackedByteArray=_array_bytes(old_value)
			var new_bytes: PackedByteArray=_array_bytes(new_value)
			var exact: bool=typeof(old_value)==typeof(new_value) and old_bytes==new_bytes
			_check(exact,"direct actual Mesh array bytes",{"path":new_path,"surface":surface,"slot":slot,"old_type":typeof(old_value),"new_type":typeof(new_value),"old_bytes":old_bytes.size(),"new_bytes":new_bytes.size()})
			slots.append({"slot":slot,"type":typeof(old_value),"old_bytes":old_bytes.size(),"new_bytes":new_bytes.size(),"direct_bytes_equal":exact,"old_sha256":_sha(old_bytes),"new_sha256":_sha(new_bytes)})
			completed_array_slots+=1
		surface_records.append({"surface":surface,"primitive":old_primitive,"slots":slots})
		completed_surfaces+=1
	evidence.append({"role":"actual Mesh geometry comparison excluding materials","old_path":old_path,"new_path":new_path,"old_file_sha256":input_sha256[old_path],"new_file_sha256":input_sha256[new_path],"surfaces":surface_records,"direct_bytes_not_metadata":true})
	before=null
	after=null
	completed_mesh_pairs+=1

func _primitive_record(mesh: Mesh,surface: int,arrays: Array,path: String) -> Dictionary:
	if mesh is ArrayMesh:
		var array_mesh: ArrayMesh=mesh as ArrayMesh
		return {"class":mesh.get_class(),"primitive":array_mesh.surface_get_primitive_type(surface),"method":"Actual ArrayMesh.surface_get_primitive_type"}
	if not mesh is PrimitiveMesh:
		_check(false,"unsupported actual Mesh class fails closed",{"path":path,"class":mesh.get_class()})
		return {}
	var native: PrimitiveMesh=mesh as PrimitiveMesh
	_check(surface==0 and mesh.get_surface_count()==1,"PrimitiveMesh real single surface",{"path":path,"surface":surface,"count":mesh.get_surface_count()})
	var native_arrays: Array=native.get_mesh_arrays()
	_check(native_arrays.size()==arrays.size(),"PrimitiveMesh actual get_mesh_arrays slot count",{"path":path})
	for slot in range(mini(native_arrays.size(),arrays.size())):
		_check(typeof(native_arrays[slot])==typeof(arrays[slot]) and _array_bytes(native_arrays[slot])==_array_bytes(arrays[slot]),"PrimitiveMesh native arrays vs actual surface arrays",{"path":path,"slot":slot})
	if arrays.size()!=Mesh.ARRAY_MAX or not arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array:
		_check(false,"PrimitiveMesh actual triangle arrays invalid",{"path":path})
		return {}
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var indices := PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: indices=arrays[Mesh.ARRAY_INDEX]
	var draw_count: int=vertices.size() if indices.is_empty() else indices.size()
	if draw_count==0 or draw_count%3!=0:
		_check(false,"PrimitiveMesh nonempty native draw triples",{"path":path,"draw_count":draw_count})
		return {}
	var expanded := PackedVector3Array()
	expanded.resize(draw_count)
	for index in range(draw_count):
		var vertex_index: int=index if indices.is_empty() else indices[index]
		if vertex_index<0 or vertex_index>=vertices.size():
			_check(false,"PrimitiveMesh actual index in bounds",{"path":path,"index":index,"vertex_index":vertex_index})
			return {}
		expanded[index]=vertices[vertex_index]
	var faces: PackedVector3Array=mesh.get_faces()
	var expanded_bytes: PackedByteArray=expanded.to_byte_array()
	var faces_bytes: PackedByteArray=faces.to_byte_array()
	var byte_exact: bool=faces.size()==draw_count and faces_bytes==expanded_bytes
	# Actual ROOT083 proves these two APIs return unequal representations.
	# Keep that fact and exact values; neither infer its precision cause nor
	# require cross-API byte identity to prove old/new material-only invariance.
	var topology: Dictionary=_exact_face_topology(expanded,faces)
	var diagnostic: Dictionary={"path":path,"native_face_vertices":faces.size(),"actual_draw_vertices":draw_count,"native_faces_byte_exact":byte_exact,"cross_representation_status":"EQUAL" if byte_exact else "NOT_EQUAL_DIAGNOSTIC_ONLY","cross_representation_not_material_invariance_oracle":true,"expanded_sha256":_sha(expanded_bytes),"faces_sha256":_sha(faces_bytes),"first_byte_difference":_first_byte_difference(expanded_bytes,faces_bytes),"expanded_vertices":_actual_vertices(expanded),"native_faces_vertices":_actual_vertices(faces),"exact_topology":topology}
	evidence.append({"role":"PrimitiveMesh actual face expansion diagnostic","record":diagnostic})
	var triangles_valid: bool=not faces.is_empty() and faces.size()==draw_count and faces.size()%3==0
	_check(triangles_valid,"PrimitiveMesh native triangle count complete/nonempty",{"path":path,"native_face_vertices":faces.size(),"actual_draw_vertices":draw_count})
	if not triangles_valid: return {}
	return {"class":mesh.get_class(),"primitive":Mesh.PRIMITIVE_TRIANGLES,"triangle_count":draw_count/3,"actual_faces_sha256":_sha(faces_bytes),"actual_draw_sha256":_sha(expanded_bytes),"faces_byte_exact_to_draw":byte_exact,"method":"Actual nonempty complete PrimitiveMesh triangle data. Each API representation compared strictly OLD vs NEW; cross-representation inequality retained as diagnostic, never repaired with epsilon."}

func _primitive_storage(mesh: Mesh) -> Dictionary:
	var parameters: Dictionary={}
	for property: Dictionary in mesh.get_property_list():
		if (int(property.get("usage",0))&PROPERTY_USAGE_STORAGE)==0: continue
		var name: String=property["name"]
		var value: Variant=mesh.get(name)
		if name=="material" or value is Material: continue
		parameters[name]=value
	return parameters

func _exact_face_topology(expanded: PackedVector3Array,faces: PackedVector3Array) -> Dictionary:
	var mapping: Array[Dictionary]=[]
	if expanded.size()!=faces.size() or faces.is_empty() or faces.size()%3!=0: return {"passed":false,"triangle_map":mapping}
	var used: Dictionary={}
	for draw_triangle in range(expanded.size()/3):
		var found := false
		for face_triangle in range(faces.size()/3):
			if used.has(face_triangle): continue
			for cycle in range(3):
				var exact := true
				for corner in range(3):
					if expanded[draw_triangle*3+corner]!=faces[face_triangle*3+(corner+cycle)%3]: exact=false
				if exact:
					mapping.append({"draw_triangle":draw_triangle,"native_face_triangle":face_triangle,"oriented_cycle":cycle})
					used[face_triangle]=true
					found=true
					break
			if found: break
		if not found: return {"passed":false,"triangle_map":mapping}
	return {"passed":true,"triangle_map":mapping}

func _actual_vertices(vertices: PackedVector3Array) -> Array[Dictionary]:
	var records: Array[Dictionary]=[]
	# PlaneMesh has six expanded draw vertices. Keep complete data when small;
	# other primitives are already covered by direct stored-array comparison.
	for index in range(mini(vertices.size(),24)):
		var vertex: Vector3=vertices[index]
		var packed := PackedVector3Array([vertex])
		records.append({"index":index,"xyz":[vertex.x,vertex.y,vertex.z],"packed_float32_hex":packed.to_byte_array().hex_encode()})
	return records

func _first_byte_difference(a: PackedByteArray,b: PackedByteArray) -> Dictionary:
	for index in range(mini(a.size(),b.size())):
		if a[index]!=b[index]: return {"byte_index":index,"expanded_byte":a[index],"native_faces_byte":b[index]}
	return {"byte_index":-1,"length_equal":a.size()==b.size()}

func _array_bytes(value: Variant) -> PackedByteArray:
	match typeof(value):
		TYPE_NIL: return PackedByteArray()
		TYPE_PACKED_BYTE_ARRAY: return value
		TYPE_PACKED_INT32_ARRAY,TYPE_PACKED_INT64_ARRAY,TYPE_PACKED_FLOAT32_ARRAY,TYPE_PACKED_FLOAT64_ARRAY,TYPE_PACKED_VECTOR2_ARRAY,TYPE_PACKED_VECTOR3_ARRAY,TYPE_PACKED_VECTOR4_ARRAY,TYPE_PACKED_COLOR_ARRAY: return value.to_byte_array()
		_: return var_to_bytes(value)

func _compare_field(before: Dictionary,after: Dictionary,key: String,label: String) -> void:
	var exact: bool=before.has(key)==after.has(key) and var_to_bytes(before.get(key))==var_to_bytes(after.get(key))
	_check(exact,label+" field "+key,{"old":before.get(key),"new":after.get(key)})

func _file_pair(old_path: String,new_path: String,label: String) -> void:
	_pin(old_path)
	_pin(new_path)
	var exists: bool=FileAccess.file_exists(old_path) and FileAccess.file_exists(new_path)
	var exact: bool=exists and FileAccess.get_file_as_bytes(old_path)==FileAccess.get_file_as_bytes(new_path)
	_check(exact,label,{"old_path":old_path,"new_path":new_path})
	evidence.append({"role":label,"old_path":old_path,"new_path":new_path,"old_sha256":input_sha256.get(old_path,""),"new_sha256":input_sha256.get(new_path,""),"direct_file_bytes_equal":exact})

func _pin(path: String) -> void:
	_check(path!="" and FileAccess.file_exists(path),"actual input exists",{"path":path})
	if path!="" and FileAccess.file_exists(path) and not input_sha256.has(path): input_sha256[path]=FileAccess.get_sha256(path)

func _json(path: String) -> Dictionary:
	_pin(path)
	if not FileAccess.file_exists(path): return {}
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(parsed is Dictionary,"actual JSON input decode",{"path":path})
	return parsed if parsed is Dictionary else {}

func _files(directory: String,suffix: String,prefix: String="") -> Array[String]:
	var paths: Array[String]=[]
	var access:=DirAccess.open(directory+prefix)
	if access==null:
		_check(false,"actual input directory exists",{"path":directory+prefix})
		return paths
	for filename: String in access.get_files():
		if filename.ends_with(suffix): paths.append(prefix+filename)
	for folder: String in access.get_directories():
		paths.append_array(_files(directory,suffix,prefix+folder+"/"))
	paths.sort()
	return paths

func _check(passed: bool,label: String,detail: Dictionary) -> void:
	checks+=1
	if not passed: failures.append({"label":label,"detail":detail})

func _sha(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty(): hash.update(bytes)
	return hash.finish().hex_encode()

func _write(path: String,result: Dictionary) -> bool:
	var text: String=JSON.stringify(result,"\t")
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(text)
	file.flush()
	var code: Error=file.get_error()
	file.close()
	return code==OK and FileAccess.get_file_as_string(path)==text and JSON.parse_string(text) is Dictionary

func _finish(code: int) -> void:
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	var cursor:=root.get_node_or_null("CursorManager")
	if cursor!=null:
		for key in ["_arrow","_hand","_wait"]: cursor.set(key,null)
	for i in range(16): await process_frame
	quit(code)
