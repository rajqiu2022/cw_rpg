extends RefCounted
## Independent complete-v5 saved ArrayMesh/RF lattice oracle. Does not load or
## execute the art source/builder; source strings/hashes are not geometry proof.
const SIZE := Vector2(1536,1024)
const STEP := 4
const SHAPE := Vector2i(513,385)
const ORIGIN := Vector2(-256,-256)
const PPM := 102.4
const Z_PPM := 72.40773439
var errors: Array[String]=[]
var checks: int=0

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label)
	return ok

func run(record: Dictionary) -> Dictionary:
	var grid: Dictionary=record.get("height_grid",{})
	_check(grid.get("size")==[513.0,385.0] and grid.get("origin_px")==[-256.0,-256.0] and float(grid.get("step_px",0))==STEP,"exact new local 4px/513x385/overscan origin contract, not global-world8px")
	var rf_path: String=String(record.get("terrain_height_path",""))
	var mesh_path: String=String(record.get("terrain_mesh_path",""))
	var buffer: PackedByteArray=FileAccess.get_file_as_bytes(rf_path)
	var mesh: ArrayMesh=load(mesh_path) as ArrayMesh if FileAccess.file_exists(mesh_path) else null
	_check(buffer.size()==SHAPE.x*SHAPE.y*4 and mesh!=null and mesh.get_surface_count()==1,"actual independent saved float32 RF and one real ArrayMesh surface")
	if mesh==null or mesh.get_surface_count()!=1 or buffer.size()!=SHAPE.x*SHAPE.y*4: return _report(rf_path,mesh_path,{})
	var arrays: Array=mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	_check(vertices.size()==SHAPE.x*SHAPE.y and uv.size()==vertices.size() and indices.size()==(SHAPE.x-1)*(SHAPE.y-1)*6,"actual draw arrays fully cover the declared RF lattice")
	if vertices.size()!=SHAPE.x*SHAPE.y or uv.size()!=vertices.size(): return _report(rf_path,mesh_path,{})
	var observed: Dictionary={}
	var vertex_cell: Array[Vector2i]=[]
	var mismatches: Array[Dictionary]=[]
	var bad_y: int=0
	var bad_xz: int=0
	var bad_uv: int=0
	var max_xz_m: float=0
	for index in vertices.size():
		# Cell inferred from ACTUAL saved UV, then tested against independent
		# source metric coordinates; inverse XZ must identify the same RF cell.
		var cell: Vector2i=Vector2i((uv[index]*SIZE-ORIGIN)/STEP+Vector2(.5,.5))
		vertex_cell.append(cell)
		var in_domain: bool=cell.x>=0 and cell.y>=0 and cell.x<SHAPE.x and cell.y<SHAPE.y
		if not in_domain or observed.has(cell): bad_uv+=1; continue
		observed[cell]=true
		var source: Vector2=ORIGIN+Vector2(cell)*STEP
		var expected_uv: Vector2=source/SIZE
		var inverse_source:=Vector2(vertices[index].x*PPM+768,vertices[index].z*Z_PPM+512)
		var expected: Vector3=Vector3((source.x-768)/PPM,buffer.decode_float((cell.y*SHAPE.x+cell.x)*4),(source.y-512)/Z_PPM)
		var xz_error: float=Vector2(vertices[index].x-expected.x,vertices[index].z-expected.z).length()
		max_xz_m=maxf(max_xz_m,xz_error)
		var inverse_cell:=Vector2i(((inverse_source-ORIGIN)/STEP).round())
		if xz_error>0.0001 or inverse_cell!=cell: bad_xz+=1
		if vertices[index].y!=expected.y or not is_finite(expected.y): bad_y+=1
		if uv[index]!=expected_uv: bad_uv+=1
		if (xz_error>0.0001 or inverse_cell!=cell or vertices[index].y!=expected.y or uv[index]!=expected_uv) and mismatches.size()<24:
			mismatches.append({"actual_index":index,"actual_uv":[uv[index].x,uv[index].y],"inferred_RF_cell":[cell.x,cell.y],"source_px":[source.x,source.y],"actual_vertex":[vertices[index].x,vertices[index].y,vertices[index].z],"expected_RF_vertex":[expected.x,expected.y,expected.z],"inverse_XZ_source":[inverse_source.x,inverse_source.y],"xz_error_m":xz_error})
	_check(observed.size()==SHAPE.x*SHAPE.y and bad_uv==0,"every actual UV maps one-to-one to independent RF cells, exact original source pixel UV")
	_check(bad_y==0,"every actual saved draw vertex Y equals its independent original float32 RF sample")
	_check(bad_xz==0,"actual saved mesh X/Z AND inverse metric map match 4px RF lattice; fixed8px mismatch is a genuine FAIL")
	var bad_triangles: int=0
	for at in range(0,indices.size(),6):
		if at+5>=indices.size(): bad_triangles+=1; break
		var cells: Array[Vector2i]=[]
		for offset in 6:
			var vi: int=indices[at+offset]
			if vi<0 or vi>=vertex_cell.size(): cells.clear(); break
			cells.append(vertex_cell[vi])
		if cells.size()!=6: bad_triangles+=1; continue
		var a: Vector2i=cells[0]
		if cells!=[a,a+Vector2i.RIGHT,a+Vector2i.DOWN,a+Vector2i.RIGHT,a+Vector2i.ONE,a+Vector2i.DOWN]: bad_triangles+=1
	_check(bad_triangles==0,"all actual triangles identify the real [a,b,c,b,d,c] 4px cells through UV, not metadata assertions")
	mesh=null
	return _report(rf_path,mesh_path,{"vertices":vertices.size(),"triangles":indices.size()/3,"bad_Y":bad_y,"bad_XZ":bad_xz,"bad_UV":bad_uv,"bad_triangle_cells":bad_triangles,"maximum_XZ_error_m":max_xz_m,"geometry_budget_m":0.0001,"first_mismatches":mismatches})

func _report(rf: String,mesh: String,evidence: Dictionary) -> Dictionary:
	return {"scope":"ACTUAL_SAVED_LOCAL_4PX_MESH_RF_BIDIRECTIONAL_NOT_FIELD_OR_VISUAL","checks":checks,"failures":errors.size(),"errors":errors,"RF_path":rf,"RF_sha256":FileAccess.get_sha256(rf),"mesh_path":mesh,"mesh_sha256":FileAccess.get_sha256(mesh),"evidence":evidence}
