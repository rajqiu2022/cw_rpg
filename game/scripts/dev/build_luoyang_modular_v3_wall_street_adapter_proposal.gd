extends "res://scripts/dev/build_luoyang_modular_v3_street_detail_proposal.gd"

const NEW_SURFACE := preload("res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd")
const GEOMETRY_ID := "PROJECT_CITY_RETAINED_FOOT_FINER_UPPER_MASONRY_CURVED_TILE_V1"
const RETAINED_OLD := [0,1,2,3,4,5,6,7,41,43,45,47,49,51]
var wall_recipe_records: Dictionary={}

func prepare(snapshot: Dictionary) -> bool:
	error=""
	evidence.clear()
	wall_recipe_records.clear()
	for path: String in PINS:
		if FileAccess.get_sha256(path).to_lower()!=String(PINS[path]):
			error="Frozen city dependency changed: "+path
			return false
	if detail!=null: detail.release()
	detail=NEW_SURFACE.new()
	if not detail.configure(snapshot) or not detail.load_sources():
		error=detail.error
		return false
	frozen_snapshot=snapshot.duplicate(true)
	return true

func build_wall(original: ArrayMesh,kind: String,profile: String) -> ArrayMesh:
	if detail==null or original==null or original.get_surface_count()!=54 or kind not in ["wall_horizontal","wall_vertical"]:
		error="Exact frozen54-surface wall required; no inferred geometry split."
		return null
	var horizontal: bool=kind=="wall_horizontal"
	var thickness: float=22./32. if horizontal else 26./64.
	var mesh:=ArrayMesh.new()
	var retained: Array[Dictionary]=[]
	for old_index: int in RETAINED_OLD:
		var index: int=mesh.get_surface_count()
		mesh.add_surface_from_arrays(original.surface_get_primitive_type(old_index),original.surface_get_arrays(old_index))
		mesh.surface_set_material(index,detail.masonry(Color(.95,.95,.95),profile))
		var a: Array=original.surface_get_arrays(old_index)
		var b: Array=mesh.surface_get_arrays(index)
		var slots: Array[Dictionary]=[]
		for slot in range(Mesh.ARRAY_MAX):
			var before: PackedByteArray=var_to_bytes(a[slot])
			var after: PackedByteArray=var_to_bytes(b[slot])
			if before!=after:
				error="Native retained support surface repacking changed bytes."
				return null
			slots.append({"slot":slot,"old_sha256":_hash(before),"new_sha256":_hash(after),"byte_exact":true})
		retained.append({"old_index":old_index,"new_index":index,"primitive":mesh.surface_get_primitive_type(index),"slots":slots})
	# Retained bottom course and original six piers determine exact minimum2%
	# support. Every new vertex starts above.246m; maximumY remains1.98m.
	var bricks:=ArrayMesh.new()
	for row in range(12):
		for column in range(20):
			var lo: float=-2.5+float(column)*.25+(0.125 if row%2==1 else 0.)
			var hi: float=minf(lo+.25,2.5)
			if column==0 and row%2==1: lo=-2.5
			var along: float=(lo+hi)*.5
			var size:=Vector3(hi-lo-.007,.114,thickness) if horizontal else Vector3(thickness,.114,hi-lo-.007)
			var position:=Vector3(along,.303+float(row)*.122,0) if horizontal else Vector3(0,.303+float(row)*.122,along)
			_append_box(bricks,size,position,detail.masonry(Color(.95,.95,.95),profile))
	var merged: Array=_merge_brick_arrays(bricks)
	if merged.is_empty(): return null
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,merged)
	mesh.surface_set_material(14,bricks.surface_get_material(0))
	var cornice_size:=Vector3(5.,.04,thickness+.035) if horizontal else Vector3(thickness+.035,.04,5.)
	_append_box(mesh,cornice_size,Vector3(0,1.685,0),detail.masonry(Color(.88,.88,.875),profile))
	var half: float=(thickness+.10)*.5
	var roof: ArrayMesh=_curved_tiles(horizontal,half)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,roof.surface_get_arrays(0))
	mesh.surface_set_material(mesh.get_surface_count()-1,detail.curved_tile(profile))
	var ridge_size:=Vector3(5.,.025,.065) if horizontal else Vector3(.065,.025,5.)
	_append_box(mesh,ridge_size,Vector3(0,1.9675,0),detail.curved_tile(profile))
	var replaced: Array[int]=[]
	for index in range(54):
		if index not in RETAINED_OLD: replaced.append(index)
	wall_recipe_records[kind]={"algorithm_identity":GEOMETRY_ID,"not_material_only":true,"retained_surface_map":retained,"replaced_original_surface_indices":replaced,"new_surface_range":[14,mesh.get_surface_count()-1],"old_surface_count":54,"new_surface_count":mesh.get_surface_count(),"new_surface_recipe":{"upper_bricks":{"first_surface":14,"merged_surface":true,"merged_source_brick_surface_count":240,"merge_method":"all original native BoxMesh VERTEX/NORMAL/TANGENT/UV arrays concatenated in row/column order; every original INDEX offset by actual preceding vertex count; no dropped attribute or geometry reduction","rows":12,"columns":20,"along_pitch_m":.25,"odd_row_shift_m":.125,"row_center_y0_m":.303,"row_pitch_m":.122,"brick_height_m":.114,"along_gap_m":.007,"extent_m":[-2.5,2.5],"thickness_m":thickness,"method":"lo=-2.5+column*.25+odd*.125; hi=min(lo+.25,2.5); odd first lo=-2.5; center=(lo+hi)/2; BoxMesh stored arrays translated, no custom fake-normal brick grid"},"cornice":{"surface_index":15,"size_m":[cornice_size.x,cornice_size.y,cornice_size.z],"center_m":[0,1.685,0]},"curved_tiles":{"surface_index":16,"half_span_m":half,"column_count":32,"course_count_per_wing":2,"wings":2,"along_sections":4,"column_pitch_m":.15625,"column_gap_m":.018,"course_gap_fraction":.012,"peak_formula":"y=1.94-.21*abs(across)/half+.035*sin(PI*t)*(1-abs(across)/half*.35)","vertex_order":"a,b,c; b,d,c clockwise; actual NORMAL=-cross(b-a,c-a).normalized()","uv":"[along/1.5,abs(across)/1.5]","double_sided":false},"ridge":{"surface_index":17,"size_m":[ridge_size.x,ridge_size.y,ridge_size.z],"center_m":[0,1.9675,0]}},"support_method":"Actual used-index minimum2% over complete new native bounds; require old/new support vector/count/minY byteexact, not old bbox alpha equality.","material_provenance":"Project modeled finer masonry and genuinely curved clay tile, not CC0 geometry; unedited project generated stone + licensed rock_01 microdetail."}
	return mesh

func _merge_brick_arrays(bricks: ArrayMesh) -> Array:
	var result: Array=[]
	result.resize(Mesh.ARRAY_MAX)
	result[Mesh.ARRAY_VERTEX]=PackedVector3Array()
	result[Mesh.ARRAY_NORMAL]=PackedVector3Array()
	result[Mesh.ARRAY_TANGENT]=PackedFloat32Array()
	result[Mesh.ARRAY_TEX_UV]=PackedVector2Array()
	result[Mesh.ARRAY_INDEX]=PackedInt32Array()
	for surface_index in range(bricks.get_surface_count()):
		var arrays: Array=bricks.surface_get_arrays(surface_index)
		var vertex_offset: int=result[Mesh.ARRAY_VERTEX].size()
		for slot in range(Mesh.ARRAY_MAX):
			if slot in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT,Mesh.ARRAY_TEX_UV]:
				result[slot].append_array(arrays[slot])
			elif slot==Mesh.ARRAY_INDEX:
				for index: int in arrays[slot]: result[slot].append(index+vertex_offset)
			elif arrays[slot]!=null:
				error="Unexpected original BoxMesh slot; no dropped brick attribute."
				return []
	return result

func _append_box(mesh: ArrayMesh,size: Vector3,position: Vector3,material: Material) -> void:
	var box:=BoxMesh.new()
	box.size=size
	var arrays: Array=box.get_mesh_arrays()
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	for index in range(vertices.size()): vertices[index]+=position
	arrays[Mesh.ARRAY_VERTEX]=vertices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(mesh.get_surface_count()-1,material)

func _tile_point(horizontal: bool,half: float,along: float,across: float,t: float) -> Vector3:
	var y: float=1.94-.21*absf(across)/half+.035*sin(PI*t)*(1.-absf(across)/half*.35)
	return Vector3(along,y,across) if horizontal else Vector3(across,y,along)

func _curved_tiles(horizontal: bool,half: float) -> ArrayMesh:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for wing in [-1.,1.]:
		for course in range(2):
			var near: float=float(wing)*half*(float(course)/2.+.006)
			var far: float=float(wing)*half*((float(course)+1.)/2.-.006)
			for column in range(32):
				var start: float=-2.5+float(column)*.15625+.009
				var width: float=.15625-.018
				for section in range(4):
					var u0: float=float(section)/4.
					var u1: float=float(section+1)/4.
					var a: Vector3=_tile_point(horizontal,half,start+width*u0,near,u0)
					var b: Vector3=_tile_point(horizontal,half,start+width*u1,near,u1)
					var c: Vector3=_tile_point(horizontal,half,start+width*u0,far,u0)
					var d: Vector3=_tile_point(horizontal,half,start+width*u1,far,u1)
					# Choose clockwise side by exact cross, never disable culling to
					# hide an inverted wing. Metadata records actual stored arrays.
					if (b-a).cross(c-a).y>0.:
						_triangle(tool,a,c,b,horizontal)
						_triangle(tool,b,c,d,horizontal)
					else:
						_triangle(tool,a,b,c,horizontal)
						_triangle(tool,b,d,c,horizontal)
	return tool.commit()

func _triangle(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,horizontal: bool) -> void:
	var normal: Vector3=-(b-a).cross(c-a).normalized()
	for point: Vector3 in [a,b,c]:
		tool.set_normal(normal)
		tool.set_uv(Vector2(point.x,absf(point.z))/1.5 if horizontal else Vector2(point.z,absf(point.x))/1.5)
		tool.add_vertex(point)

func release() -> void:
	wall_recipe_records.clear()
	super.release()
