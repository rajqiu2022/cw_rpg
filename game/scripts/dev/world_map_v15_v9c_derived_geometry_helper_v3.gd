extends "res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v2.gd"

## NEW source-only native TBN packing correction. No tolerance: old semantic
## tangents are immutable inputs, not falsely promised immutable packed output.
## A=old arrays native roundtrip; B=new normals+old vertices/tangents oracle;
## C=new heights/new normals+the exact same original semantic tangent inputs.
## C/B TBN is byteexact everywhere; C/A TBN is byteexact outside incident faces.
const V3_PARENT_PATH := "res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v2.gd"
const V3_PARENT_SHA := "1751f4e50bd851aae9f2c58f0dac763049834e200b68c85df3d9e14177f8f021"
const NATIVE_TBN_ID := "NEW_NORMAL_OLD_SEMANTIC_TANGENT_NATIVE_ABC_PACKING_BYTE_EXACT_V1"
var _v3_packing_audit: Dictionary={}

func derive(source: RefCounted,baseline_objects: Array,output_dir: String) -> Dictionary:
	_v3_packing_audit.clear()
	if FileAccess.get_sha256(V3_PARENT_PATH).to_lower()!=V3_PARENT_SHA:
		return _failure("Frozen v2 geometry/protection parent differs")
	return super.derive(source,baseline_objects,output_dir)

func _derive_mesh(before: ArrayMesh, original: PackedFloat32Array, heights: PackedFloat32Array, changed: Dictionary) -> Dictionary:
	if before==null or before.get_surface_count()!=1 or before.surface_get_primitive_type(0)!=Mesh.PRIMITIVE_TRIANGLES: return {"passed":false,"error":"Frozen native mesh shape missing"}
	var old_arrays: Array=before.surface_get_arrays(0)
	var arrays: Array=old_arrays.duplicate(true)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	if vertices.size()!=original.size() or normals.size()!=vertices.size() or indices.size()!=(BASE.GRID_SIZE.x-1)*(BASE.GRID_SIZE.y-1)*6: return {"passed":false,"error":"Native mesh/RF indexing shape mismatch"}
	var affected: Dictionary={}
	for index: int in changed:
		var cell:=Vector2i(index%BASE.GRID_SIZE.x,index/BASE.GRID_SIZE.x)
		if vertices[index]!=BASE.point3(Vector2(cell*BASE.GRID_STEP),original[index]): return {"passed":false,"error":"Original mesh vertex not actual frozen lattice"}
		vertices[index].y=heights[index]
		for y in range(maxi(0,cell.y-1),mini(BASE.GRID_SIZE.y,cell.y+2)):
			for x in range(maxi(0,cell.x-1),mini(BASE.GRID_SIZE.x,cell.x+2)): affected[y*BASE.GRID_SIZE.x+x]=true
	for index: int in affected:
		var cell:=Vector2i(index%BASE.GRID_SIZE.x,index/BASE.GRID_SIZE.x)
		var normal:=Vector3.ZERO
		for y in range(maxi(0,cell.y-1),mini(BASE.GRID_SIZE.y-1,cell.y+1)):
			for x in range(maxi(0,cell.x-1),mini(BASE.GRID_SIZE.x-1,cell.x+1)):
				var start: int=(y*(BASE.GRID_SIZE.x-1)+x)*6
				for triangle in 2:
					var a: int=indices[start+triangle*3]
					var b: int=indices[start+triangle*3+1]
					var c: int=indices[start+triangle*3+2]
					if index not in [a,b,c]: continue
					# Existing clockwise fronts stay byte-exact. An UP-facing actual
					# area normal uses the inverse cross, not an index rewrite.
					var area: Vector3=(vertices[c]-vertices[a]).cross(vertices[b]-vertices[a])
					if not area.is_finite() or area.length_squared()==0.: return {"passed":false,"error":"Degenerate actual native face"}
					if area.y<0.: area=-area
					normal+=area
		if normal.length_squared()==0.: return {"passed":false,"error":"Missing actual incident faces"}
		normals[index]=normal.normalized()
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	for slot in Mesh.ARRAY_MAX:
		if slot not in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL] and not _same_array(old_arrays[slot],arrays[slot]): return {"passed":false,"error":"Protected native array changed"}

	# Preserve native construction INPUTS, including every original tangent
	# byte. No tangent generator, no index/winding rewrite, no epsilon.
	var oracle_input: Array=old_arrays.duplicate(true)
	oracle_input[Mesh.ARRAY_NORMAL]=normals
	var control:=ArrayMesh.new()
	control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,old_arrays)
	var oracle:=ArrayMesh.new()
	oracle.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,oracle_input)
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	if control.get_surface_count()!=1 or oracle.get_surface_count()!=1 or mesh.get_surface_count()!=1:
		return {"passed":false,"error":"Actual ABC native construction failed"}
	var aa: Array=control.surface_get_arrays(0)
	var bb: Array=oracle.surface_get_arrays(0)
	var actual: Array=mesh.surface_get_arrays(0)
	var audit: Dictionary={"identity":NATIVE_TBN_ID,"vertex_count":vertices.size(),"indices_count":indices.size(),"changed_Y_nodes":changed.size(),"recomputed_actual_face_normals":affected.size(),"semantic_tangent_input_unchanged":true,"original_normal_tangent_bits_unchanged_claim":false,"outside_incident_TBN_byte_exact_to_native_control":true,"actual_TBN_byte_exact_to_new_normal_oracle":true,"XZ_UV_indices_other_slots_exact":true,"RF_vertex_relation":"same row-major new Float32 height lattice","baseline_format":before.surface_get_format(0),"control_format":control.surface_get_format(0),"oracle_format":oracle.surface_get_format(0),"actual_format":mesh.surface_get_format(0),"slot_records":[],"affected_vertex_indices":[],"baseline_normal_repacked_vertices":0,"baseline_tangent_repacked_vertices":0,"affected_actual_normal_changed_vertices":0,"affected_actual_tangent_changed_vertices":0,"outside_incident_actual_normal_changed_vertices":0,"outside_incident_actual_tangent_changed_vertices":0,"normal_and_tangent_native_encoding_derivation_permitted_only_in_incident_domain":true}
	var affected_indices: Array[int]=[]
	for index: int in affected: affected_indices.append(index)
	affected_indices.sort()
	audit["affected_vertex_indices"]=affected_indices
	_v3_packing_audit=audit
	if audit["baseline_format"]!=audit["control_format"] or audit["baseline_format"]!=audit["oracle_format"] or audit["baseline_format"]!=audit["actual_format"]:
		return _v3_mesh_failure("Native surface format differs",audit)
	for slot in Mesh.ARRAY_MAX:
		var old_bytes: PackedByteArray=_v3_slot_bytes(old_arrays[slot])
		var a_bytes: PackedByteArray=_v3_slot_bytes(aa[slot])
		var b_bytes: PackedByteArray=_v3_slot_bytes(bb[slot])
		var c_bytes: PackedByteArray=_v3_slot_bytes(actual[slot])
		var row: Dictionary={"slot":slot,"old_type":typeof(old_arrays[slot]),"control_type":typeof(aa[slot]),"oracle_type":typeof(bb[slot]),"actual_type":typeof(actual[slot]),"old_bytes":old_bytes.size(),"control_bytes":a_bytes.size(),"oracle_bytes":b_bytes.size(),"actual_bytes":c_bytes.size(),"old_sha256":_sha(old_bytes),"control_sha256":_sha(a_bytes),"oracle_sha256":_sha(b_bytes),"actual_sha256":_sha(c_bytes),"original_vs_control_byte_exact":_same_array(old_arrays[slot],aa[slot]),"oracle_vs_actual_byte_exact":_same_array(bb[slot],actual[slot]),"first_original_control_difference":_v3_first_difference(old_bytes,a_bytes),"first_oracle_actual_difference":_v3_first_difference(b_bytes,c_bytes)}
		audit["slot_records"].append(row)
	# Complete every slot's original/control/oracle/actual evidence before any
	# slot predicate exits. A failure is never a partial all-slot PASS report.
	for slot in Mesh.ARRAY_MAX:
		if slot not in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT] and (not _same_array(old_arrays[slot],aa[slot]) or not _same_array(old_arrays[slot],bb[slot]) or not _same_array(old_arrays[slot],actual[slot])):
			return _v3_mesh_failure("Protected non-TBN native slot changed: "+str(slot),audit)
		if slot in [Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT] and not _same_array(bb[slot],actual[slot]):
			return _v3_mesh_failure("Actual TBN differs from independent new-normal native oracle: "+str(slot),audit)
	if not _same_array(old_arrays[Mesh.ARRAY_TANGENT],arrays[Mesh.ARRAY_TANGENT]) or not _same_array(old_arrays[Mesh.ARRAY_TANGENT],oracle_input[Mesh.ARRAY_TANGENT]):
		return _v3_mesh_failure("Original semantic tangent input changed",audit)
	var actual_vertices: PackedVector3Array=actual[Mesh.ARRAY_VERTEX]
	var old_vertices: PackedVector3Array=old_arrays[Mesh.ARRAY_VERTEX]
	if actual_vertices.size()!=old_vertices.size() or not _same_array(old_arrays[Mesh.ARRAY_VERTEX],aa[Mesh.ARRAY_VERTEX]) or not _same_array(old_arrays[Mesh.ARRAY_VERTEX],bb[Mesh.ARRAY_VERTEX]):
		return _v3_mesh_failure("Baseline/control/oracle vertex representation changed",audit)
	var old_normal: PackedByteArray=_v3_slot_bytes(old_arrays[Mesh.ARRAY_NORMAL])
	var old_tangent: PackedByteArray=_v3_slot_bytes(old_arrays[Mesh.ARRAY_TANGENT])
	var control_normal: PackedByteArray=_v3_slot_bytes(aa[Mesh.ARRAY_NORMAL])
	var control_tangent: PackedByteArray=_v3_slot_bytes(aa[Mesh.ARRAY_TANGENT])
	var actual_normal: PackedByteArray=_v3_slot_bytes(actual[Mesh.ARRAY_NORMAL])
	var actual_tangent: PackedByteArray=_v3_slot_bytes(actual[Mesh.ARRAY_TANGENT])
	if old_normal.size()!=vertices.size()*12 or control_normal.size()!=old_normal.size() or actual_normal.size()!=old_normal.size() or old_tangent.size()!=vertices.size()*16 or control_tangent.size()!=old_tangent.size() or actual_tangent.size()!=old_tangent.size():
		return _v3_mesh_failure("Actual TBN packed-array element shape mismatch",audit)
	for index in actual_vertices.size():
		if actual_vertices[index].x!=old_vertices[index].x or actual_vertices[index].z!=old_vertices[index].z or actual_vertices[index].y!=heights[index]:
			return _v3_mesh_failure("Actual native new RF/XZ relation failed: "+str(index),audit)
		if not changed.has(index) and actual_vertices[index]!=old_vertices[index]:
			return _v3_mesh_failure("Unchanged native vertex changed: "+str(index),audit)
		var start_normal: int=index*12
		var start_tangent: int=index*16
		if old_normal.slice(start_normal,start_normal+12)!=control_normal.slice(start_normal,start_normal+12): audit["baseline_normal_repacked_vertices"]+=1
		if old_tangent.slice(start_tangent,start_tangent+16)!=control_tangent.slice(start_tangent,start_tangent+16): audit["baseline_tangent_repacked_vertices"]+=1
		var normal_changed: bool=control_normal.slice(start_normal,start_normal+12)!=actual_normal.slice(start_normal,start_normal+12)
		var tangent_changed: bool=control_tangent.slice(start_tangent,start_tangent+16)!=actual_tangent.slice(start_tangent,start_tangent+16)
		if affected.has(index):
			if normal_changed: audit["affected_actual_normal_changed_vertices"]+=1
			if tangent_changed: audit["affected_actual_tangent_changed_vertices"]+=1
		else:
			if normal_changed: audit["outside_incident_actual_normal_changed_vertices"]+=1
			if tangent_changed: audit["outside_incident_actual_tangent_changed_vertices"]+=1
			if normal_changed or tangent_changed:
				audit["first_outside_incident_mismatch"]={"index":index,"normal_changed":normal_changed,"tangent_changed":tangent_changed}
				return _v3_mesh_failure("Actual packed TBN changed outside authorized incident domain",audit)
	audit["normal_input_sha256"]=_sha(normals.to_byte_array())
	audit["tangent_semantic_input_sha256"]=_sha(_v3_slot_bytes(old_arrays[Mesh.ARRAY_TANGENT]))
	audit["passed"]=true
	_v3_packing_audit=audit.duplicate(true)
	return {"passed":true,"mesh":mesh,"audit":audit}

func _v3_mesh_failure(message: String,audit: Dictionary) -> Dictionary:
	audit["passed"]=false
	audit["error"]=message
	_v3_packing_audit=audit.duplicate(true)
	return {"passed":false,"error":message,"audit":audit}

func _v3_slot_bytes(value: Variant) -> PackedByteArray:
	if value==null: return PackedByteArray()
	if value is PackedByteArray: return value
	return value.to_byte_array()

func _v3_first_difference(a: PackedByteArray,b: PackedByteArray) -> int:
	for index in mini(a.size(),b.size()):
		if a[index]!=b[index]: return index
	return -1 if a.size()==b.size() else mini(a.size(),b.size())

func _sha(bytes: PackedByteArray) -> String:
	# HashingContext.update(empty) emits engine ERROR; standard empty SHA needs
	# start+finish only, not an error-suppression or different hash algorithm.
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK: return ""
	if not bytes.is_empty() and context.update(bytes)!=OK: return ""
	return context.finish().hex_encode()

func _failure(message: String) -> Dictionary:
	error=message
	return {"passed":false,"error":message,"scope":"SOURCE_DERIVATION_REFUSED_NOT_CAPTURE_OR_APPROVAL","native_packing_diagnostic":_v3_packing_audit.duplicate(true)}
