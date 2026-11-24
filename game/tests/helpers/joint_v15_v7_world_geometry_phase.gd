extends RefCounted
## New independent saved ArrayMesh / Float32 RF and complete112 edge reference
## comparisons. No builder function, production selector/clearance, or preview
## renderer is called. Missing full reference evidence fails closed.
const ROOT: String = "res://art/maps/world_map_v15_complete_v7/"
const GPU_CACHE: String = "res://art/maps/world_map_v15_complete_v5/"
const PROTOCOL: String = "COHERENT_WHOLE_FIXED_CAMERA_INTEGER_TEXEL_ROI_V1_FULL"
const SIZE: Vector2i = Vector2i(12288,8192)
const GRID: Vector2i = Vector2i(1537,1025)
const TILE: Vector2i = Vector2i(1536,1024)
const PPM: float = 102.4
const Z_PPM: float = 102.4 * 0.7071067811865476
var checks: int = 0
var errors: Array[String] = []
var edge_evidence: Array[Dictionary] = []
var height: PackedFloat32Array = PackedFloat32Array()
var window_evidence: Dictionary = {}

func _check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok: errors.append(message)
	return ok

func _point(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size()==2 and typeof(value[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT,TYPE_FLOAT]: return Vector2(float(value[0]),float(value[1]))
	return Vector2(INF,INF)

func _bound(path: String, catalog: Dictionary) -> bool:
	return path.begins_with(ROOT) and catalog.has(path) and String(catalog[path]).length()==64 and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==String(catalog[path]).to_lower()

func _integer_rect(value: Variant) -> bool:
	if not value is Array or value.size()!=4: return false
	for component: Variant in value:
		if typeof(component) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(component)) or float(component)!=float(int(component)): return false
	return value[0]>=0 and value[1]>=0 and value[2]>0 and value[3]>0 and value[0]+value[2]<=SIZE.x and value[1]+value[3]<=SIZE.y

func run(manifest: Dictionary, source: Dictionary, raw: RefCounted) -> Dictionary:
	var catalog: Variant = manifest.get("asset_sha256")
	if not _check(catalog is Dictionary,"full current world asset catalog required for actual saved geometry"): return report()
	var geometry_path: String = ROOT+"geometry.json"
	if not _check(_bound(geometry_path,catalog),"actual complete geometry JSON bound to frozen catalog"): return report()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(geometry_path))
	if not _check(parsed is Dictionary,"actual geometry metadata dictionary"): return report()
	var geometry: Dictionary = parsed
	_check(geometry.get("capture_protocol")==PROTOCOL,"actual saved global geometry identifies coherent whole FULL protocol")
	var rf_path: String = ROOT+"terrain_height.rf"
	var mesh_path: String = ROOT+"terrain_mesh.res"
	if not _check(_bound(rf_path,catalog) and _bound(mesh_path,catalog),"actual global RF+mesh artifacts, no lazy local window substitution"): return report()
	_check(geometry.get("rf_path")==rf_path and geometry.get("rf_sha256")==catalog.get(rf_path) and geometry.get("terrain_mesh_path")==mesh_path and geometry.get("terrain_mesh_sha256")==catalog.get(mesh_path) and geometry.get("actual_GPU_RF_input_path")==GPU_CACHE+"terrain_height.rf" and geometry.get("actual_GPU_mesh_input_path")==GPU_CACHE+"terrain_mesh.res" and geometry.get("actual_GPU_support_input_path")==GPU_CACHE+"chunks/r0_c0_actual_deck_support_mesh.res" and geometry.get("native_binary_msaa_enum")==0 and geometry.get("native_binary_resized")==false,"runtime copies disclose exact original GLOBAL GPU cache paths; binary authority unresized")
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(rf_path)
	if not _check(bytes.size()==GRID.x*GRID.y*4,"exact full1537x1025 Float32 LE global RF bytes"): return report()
	height = bytes.to_float32_array()
	_check(_point(geometry.get("height_grid_shape"))==Vector2(GRID) and _point(geometry.get("height_grid_origin_px"))==Vector2.ZERO and float(geometry.get("source_node_spacing_px",-1))==8,"explicit global RF lattice shape/origin/spacing8px")
	var mesh: ArrayMesh = ResourceLoader.load(mesh_path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if not _check(mesh!=null and mesh.get_surface_count()==1,"actual stored global terrain ArrayMesh surface"): return report()
	var arrays: Array = mesh.surface_get_arrays(0)
	if not _check(arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array and arrays[Mesh.ARRAY_TEX_UV] is PackedVector2Array and arrays[Mesh.ARRAY_INDEX] is PackedInt32Array,"stored native vertex/UV/index arrays"): return report()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if not _check(vertices.size()==GRID.x*GRID.y and uv.size()==vertices.size() and indices.size()==(GRID.x-1)*(GRID.y-1)*6,"complete global source lattice and actual two-triangle index counts"): return report()
	var cells: PackedVector2Array = PackedVector2Array()
	cells.resize(vertices.size())
	var good_vertices: bool = true
	var finite_height: bool = true
	var max_y_error: float = 0
	for i in vertices.size():
		var cell: Vector2i = Vector2i(roundi(uv[i].x*SIZE.x/8),roundi(uv[i].y*SIZE.y/8))
		if cell.x<0 or cell.y<0 or cell.x>=GRID.x or cell.y>=GRID.y:
			good_vertices=false
			continue
		var expected_uv: Vector2 = Vector2(float(cell.x*8)/SIZE.x,float(cell.y*8)/SIZE.y)
		var h: float = height[cell.y*GRID.x+cell.x]
		finite_height=finite_height and is_finite(h)
		var expected: Vector3 = Vector3((cell.x*8-SIZE.x*.5)/PPM,h,(cell.y*8-SIZE.y*.5)/Z_PPM)
		good_vertices=good_vertices and uv[i]==expected_uv and absf(vertices[i].x-expected.x)<=.0001 and absf(vertices[i].z-expected.z)<=.0001 and absf(vertices[i].y-h)<=.0001
		max_y_error=maxf(max_y_error,absf(vertices[i].y-h))
		cells[i]=Vector2(cell)
	_check(finite_height and good_vertices,"every saved mesh vertex is independently UV-indexed RF height (.0001m), not assumed row-major IDs")
	var seen: PackedByteArray = PackedByteArray()
	seen.resize((GRID.x-1)*(GRID.y-1))
	var good_triangles: bool = true
	for offset in range(0,indices.size(),3):
		var a: int = indices[offset]
		var b: int = indices[offset+1]
		var c: int = indices[offset+2]
		if a<0 or b<0 or c<0 or a>=vertices.size() or b>=vertices.size() or c>=vertices.size():
			good_triangles=false
			continue
		var ca: Vector2i = Vector2i(cells[a])
		var cb: Vector2i = Vector2i(cells[b])
		var cc: Vector2i = Vector2i(cells[c])
		var corner: Vector2i = ca.min(cb).min(cc)
		var low: bool = ca==corner and cb==corner+Vector2i.RIGHT and cc==corner+Vector2i.DOWN
		var high: bool = ca==corner+Vector2i.RIGHT and cb==corner+Vector2i.ONE and cc==corner+Vector2i.DOWN
		if corner.x<0 or corner.y<0 or corner.x>=GRID.x-1 or corner.y>=GRID.y-1 or not (low or high):
			good_triangles=false
			continue
		var key: int = corner.y*(GRID.x-1)+corner.x
		var bit: int = 1 if low else 2
		if (seen[key]&bit)!=0: good_triangles=false
		seen[key]=seen[key]|bit
		good_triangles=good_triangles and (vertices[b]-vertices[a]).cross(vertices[c]-vertices[a]).y<0
	for value in seen:
		if value!=3: good_triangles=false
	_check(good_triangles,"all actual indices independently map exact[a,b,c,b,d,c] cells, unique full coverage, native upward winding")
	mesh=null
	arrays.clear()
	_seams(manifest,source,catalog,raw)
	var result: Dictionary = report()
	result["global_RF_SHA256"]=FileAccess.get_sha256(rf_path)
	result["global_mesh_SHA256"]=FileAccess.get_sha256(mesh_path)
	result["max_saved_vertex_RF_height_error_m"]=max_y_error
	return result

func height_at(point: Vector2) -> float:
	if height.size()!=GRID.x*GRID.y or not point.is_finite() or point.x<0 or point.y<0 or point.x>SIZE.x or point.y>SIZE.y: return NAN
	var cell: Vector2i = Vector2i(clampi(floori(point.x/8),0,GRID.x-2),clampi(floori(point.y/8),0,GRID.y-2))
	var fraction: Vector2 = (point-Vector2(cell*8))/8
	var index: int = cell.y*GRID.x+cell.x
	var a: float = height[index]
	var b: float = height[index+1]
	var c: float = height[index+GRID.x]
	var d: float = height[index+GRID.x+1]
	return a+(b-a)*fraction.x+(c-a)*fraction.y if fraction.x+fraction.y<=1 else d+(c-d)*(1-fraction.x)+(b-d)*(1-fraction.y)

func _seams(manifest: Dictionary, source: Dictionary, catalog: Dictionary, raw: RefCounted) -> void:
	var authored: Variant = source.get("seams")
	var captured: Variant = manifest.get("seams")
	if not _check(authored is Array and authored.size()==112 and captured is Array and captured.size()==112,"exact112 authored+independent actual reference seam records, enumeration alone insufficient"): return
	var actual_by_id: Dictionary = {}
	for entry: Variant in captured:
		if not _check(entry is Dictionary and not actual_by_id.has(String(entry.get("id",""))),"typed unique captured seam"): continue
		actual_by_id[String(entry.id)]=entry
	var expected: Dictionary = {}
	for row in 8:
		for col in 8:
			if col<7: expected["r%d_c%d--r%d_c%d"%[row,col,row,col+1]]={"from":"r%d_c%d"%[row,col],"to":"r%d_c%d"%[row,col+1],"axis":"x","line":(col+1)*TILE.x,"start":row*TILE.y,"length":TILE.y}
			if row<7: expected["r%d_c%d--r%d_c%d"%[row,col,row+1,col]]={"from":"r%d_c%d"%[row,col],"to":"r%d_c%d"%[row+1,col],"axis":"y","line":(row+1)*TILE.y,"start":col*TILE.x,"length":TILE.x}
	var used: Dictionary = {}
	for authored_entry: Variant in authored:
		if not _check(authored_entry is Dictionary,"typed authored seam"): continue
		var id: String = String(authored_entry.get("id",""))
		if not _check(expected.has(id) and actual_by_id.has(id) and not used.has(id),"each actual internal neighbor has original and independent reference: "+id): continue
		used[id]=true
		var record: Dictionary = actual_by_id[id]
		var edge: Dictionary = expected[id]
		var edge_errors_before: int = errors.size()
		_check(authored_entry.get("from")==edge.from and authored_entry.get("to")==edge.to and record.get("from")==edge.from and record.get("to")==edge.to,"reference binds independently enumerated neighbor pair "+id)
		var reference: Variant = record.get("independent_reference_capture")
		if not _check(reference is Dictionary,"independent neighboring geometry capture, not self-crop "+id): continue
		_whole_geometry_binding(reference,catalog,id)
		var rect_value: Variant = reference.get("logical_rect_px")
		if not _check(_integer_rect(rect_value),"reference global rectangle exact integral native domain; no silent integer truncation "+id): continue
		var rect: Rect2i = Rect2i(int(rect_value[0]),int(rect_value[1]),int(rect_value[2]),int(rect_value[3]))
		var strip: Rect2i = Rect2i(edge.line-16,edge.start,32,edge.length) if edge.axis=="x" else Rect2i(edge.start,edge.line-16,edge.length,32)
		if not _check(rect.encloses(strip),"independent reference covers full boundary on both sides "+id): continue
		var kinds_completed: Array[String] = []
		for kind: String in ["visual","shadow_off","land","raw_walk","walk"]:
			var path: String = String(reference.get(kind+"_path",""))
			var repeat_path: String = String(reference.get(kind+"_repeat_path",""))
			if not _check(_bound(path,catalog) and _bound(repeat_path,catalog) and path!=repeat_path and FileAccess.get_sha256(path)==FileAccess.get_sha256(repeat_path),"real independent reference PNG repeat bytes "+id+"/"+kind): continue
			var image: Image = Image.load_from_file(path)
			if not _check(image!=null and image.get_size()==rect.size,"reference actual one-logical-pixel dimensions "+id): continue
			var left_path: String = ROOT+"chunks/"+edge.from+"_"+kind+".png"
			var right_path: String = ROOT+"chunks/"+edge.to+"_"+kind+".png"
			if not _check(_bound(left_path,catalog) and _bound(right_path,catalog) and path!=left_path and path!=right_path,"both original chunks bound independently, reference not either original PNG "+id+"/"+kind): continue
			var left: Image = Image.load_from_file(left_path)
			var right: Image = Image.load_from_file(right_path)
			if not _check(left!=null and right!=null and left.get_size()==TILE and right.get_size()==TILE,"actual frozen pair PNG readable "+id): continue
			image.convert(Image.FORMAT_RGBA8)
			left.convert(Image.FORMAT_RGBA8)
			right.convert(Image.FORMAT_RGBA8)
			var exact: bool = true
			for y in range(strip.position.y,strip.end.y):
				for x in range(strip.position.x,strip.end.x):
					var global_pixel: Vector2i = Vector2i(x,y)
					var cell: Vector2i = Vector2i(floori(float(x)/TILE.x),floori(float(y)/TILE.y))
					var pair_image: Image = left if (edge.axis=="x" and x<edge.line) or (edge.axis=="y" and y<edge.line) else right
					exact=exact and pair_image.get_pixelv(global_pixel-cell*TILE)==image.get_pixelv(global_pixel-rect.position)
			_check(exact,"entire32px strip original RGBA equals independent reference, both sides "+id+"/"+kind)
			if exact: kinds_completed.append(kind)
		var classification: String = String(authored_entry.get("classification",""))
		var witnesses: Variant = authored_entry.get("projected_witnesses")
		_check(classification in ["open","blocked"] and record.get("classification")==classification,"explicit actual open/blocked seam semantics "+id)
		if not _check(witnesses is Array and not witnesses.is_empty(),"seam has explicit projected nav witnesses "+id): continue
		for witness: Variant in witnesses:
			if not _check(witness is Dictionary,"typed projected seam witness"): continue
			if classification=="open":
				var a: Vector2 = _point(witness.get("from_px"))
				var b: Vector2 = _point(witness.get("to_px"))
				var crossing: bool = a.x<edge.line and b.x>edge.line if edge.axis=="x" else a.y<edge.line and b.y>edge.line
				var reason: Dictionary = raw.call("segment_evidence",a,b)
				_check(crossing and bool(reason.get("clear",false)),"open cross-boundary entire<=4px/17 shoes independently legal "+id)
			else:
				var point: Vector2 = _point(witness.get("foot_px"))
				_check(point.is_finite() and not bool(raw.call("clear",point)),"explicit blocked seam foot denied without forcing all112 open "+id)
		edge_evidence.append({"id":id,"classification":classification,"reference":reference.duplicate(true),"witnesses":witnesses.duplicate(true),"exact_kinds":kinds_completed,"all_edge_pixels_checked":kinds_completed.size()==5,"all_predicates_passed":errors.size()==edge_errors_before})
	_check(used.size()==112 and edge_evidence.size()==112,"all112 actual independent reference + navigation classifications completed")

func _whole_geometry_binding(reference: Dictionary,catalog: Dictionary,id: String) -> void:
	# These are actual frozen GLOBAL GPU input files, not 112 fabricated window
	# meshes. The runtime copies are already independently inspected vertex/UV/RF
	# by run(); exact file equality transfers that inspection to the GPU source.
	if not _check(reference.get("capture_protocol")==PROTOCOL and reference.get("capture_role")=="reference" and reference.get("window_id")==id,"fresh second whole-world reference identity "+id): return
	var rows: Array[Array]=[
		["global_terrain_mesh_path","global_terrain_mesh_sha256",GPU_CACHE+"terrain_mesh.res",ROOT+"terrain_mesh.res"],
		["height_rf_path","height_rf_sha256",GPU_CACHE+"terrain_height.rf",ROOT+"terrain_height.rf"],
		["actual_deck_mesh_path","actual_deck_mesh_sha256",GPU_CACHE+"chunks/r0_c0_actual_deck_support_mesh.res",ROOT+"deck_support_mesh.res"]]
	for row: Array in rows:
		var original: String=row[2]
		var copy: String=row[3]
		var valid: bool=reference.get(row[0])==original and catalog.has(original) and _bound(copy,catalog) and FileAccess.file_exists(original) and String(catalog[original]).length()==64 and FileAccess.get_sha256(original).to_lower()==String(catalog[original]).to_lower() and reference.get(row[1])==catalog[original] and catalog[original]==catalog[copy]
		if not _check(valid,"actual GLOBAL GPU input and independently saved runtime copy SHA "+id+"/"+copy): continue
		if not window_evidence.has(original):
			var exact: bool=FileAccess.get_file_as_bytes(original)==FileAccess.get_file_as_bytes(copy)
			_check(exact,"actual GPU geometry/RF/support byteexact copy, no invented local mesh "+original)
			window_evidence[original]={"actual_GPU_input_path":original,"runtime_copy_path":copy,"sha256":catalog[original],"byte_exact_copy":exact,"local_frustum_mesh_claimed":false}

func report() -> Dictionary:
	return {"scope":"JOINT_WORLD_SAVED_GEOMETRY_AND112_REFERENCES_NOT_VISUAL_PASS","capture_protocol":PROTOCOL,"checks":checks,"failures":errors.size(),"errors":errors.duplicate(),"edges":edge_evidence.duplicate(true),"whole_GPU_geometry_bindings":window_evidence.duplicate(true),"runtime_input_executed":false,"visual_approved":false}

func release() -> void:
	height=PackedFloat32Array()
	edge_evidence.clear()
	window_evidence.clear()
