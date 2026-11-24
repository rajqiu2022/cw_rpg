extends RefCounted

## SOURCE-ONLY derivation helper. No SceneTree, GPU, default execution or approval.
## Only an explicit derive() into a new build directory writes artifacts.
## New RF, native mesh and selector share one Float32 lattice; the old cache is
## an immutable INPUT, never relabelled as changed terrain or unchanged NAV.
const BASE := preload("res://scripts/dev/world_map_v15_complete_v5_source.gd")
const OUTPUT_PREFIX := "res://build/world_map_v15_v9c_visual_quality_proposal/"
const BASELINE_SOURCE := "res://data/maps/world_map_v15_complete_v8_source.json"
const BASELINE_MANIFEST := "res://art/maps/world_map_v15_complete_v8/art_contract.json"
const BASELINE_RF := "res://art/maps/world_map_v15_complete_v5/terrain_height.rf"
const BASELINE_MESH := "res://art/maps/world_map_v15_complete_v5/terrain_mesh.res"
const BASELINE_SELECTOR := "res://art/maps/world_map_v15_complete_v5/source_topology.png"
const BASELINE_SUPPORT := "res://art/maps/world_map_v15_complete_v5/chunks/r0_c0_actual_deck_support_mesh.res"
const BASELINE_PINS := {
	BASELINE_SOURCE: "13f3d5a9940283a92971ea20eae0234301635812dd0975a4c119536fb026cff5",
	BASELINE_MANIFEST: "cfb7656b2b50690ddb2e28cc91a0fcd23c734ba28cd21b171c67f2857561dd94",
	BASELINE_RF: "b7210634cbc2d7a2809bfab608e47930d5717459b01dc42df33ae9e6919548b9",
	BASELINE_MESH: "2eb9ad81081768f938798bf4879df705505783d2aeb9b328927289f7b51d2a9a",
	BASELINE_SELECTOR: "5d65605fa804faacc03f5378dd4c87c8bcce0f27e38821f11c02a839e28dbb1a",
	BASELINE_SUPPORT: "668022ddb74892023ef214dac5551f9b49f79d9958ccfb1126646bc7934923a9",
	"res://scripts/dev/world_map_v15_complete_v5_source.gd": "f812bcd93efe93da54866c2d61287feaeaf6bc68543493b4b54a606d99769299",
}
const DOMAIN := Rect2(3920, 0, 2320, 1360)
const MASSES := [
	{"center": Vector2(4780,780), "radius": Vector2(420,310), "height": 3.4, "front": .20, "angle": -.31},
	{"center": Vector2(5430,650), "radius": Vector2(340,240), "height": 4.4, "front": .27, "angle": .43},
]
const PROTECTION_BUCKET := 128.0
const PHYSICAL_HALO := 24.0
const SOFT_HALO := 80.0
var error := ""
var _protected: Array[Dictionary] = []
var _buckets: Dictionary = {}
var _feet: Array[Dictionary] = []
var _road_buckets: Dictionary = {}

func derive(source: RefCounted, baseline_objects: Array, output_dir: String) -> Dictionary:
	error = ""
	_protected.clear()
	_buckets.clear()
	_feet.clear()
	_road_buckets.clear()
	if not source is BASE or source.get("routes").size() != 27:
		return _failure("Prepared real authoring source/27 routes missing")
	if not output_dir.begins_with(OUTPUT_PREFIX) or ".." in output_dir or not output_dir.ends_with("/") or output_dir == OUTPUT_PREFIX or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output_dir)):
		return _failure("Derivation requires a unique absent NEW build subdirectory")
	for path: String in BASELINE_PINS:
		if FileAccess.get_sha256(path).to_lower() != BASELINE_PINS[path]:
			return _failure("Frozen geometry/body input changed: " + path)
	var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(BASELINE_SOURCE))
	if not record is Dictionary or not record.get("objects") is Array or not record.get("portals") is Array or record.portals.size() != 16 or not _same_value(baseline_objects, record.objects):
		return _failure("All original body IDs/metadata and 16 source doors must be exact")
	var original_bytes: PackedByteArray = FileAccess.get_file_as_bytes(BASELINE_RF)
	if original_bytes.size() != BASE.GRID_SIZE.x * BASE.GRID_SIZE.y * 4:
		return _failure("Frozen RF dimensions invalid")
	var original: PackedFloat32Array = original_bytes.to_float32_array()
	var caller_heights: Variant = source.get("heights")
	if not caller_heights is PackedFloat32Array or caller_heights.to_byte_array() != original_bytes:
		return _failure("Caller must be prepared from the exact old RF before deriving")
	var caller_sites: String = _sha(JSON.stringify(source.get("vegetation_sites")).to_utf8_buffer())
	if not _prepare_protection(record, baseline_objects): return _failure(error)
	if not _index_roads(source.get("routes")): return _failure(error)
	var result_heights: PackedFloat32Array = original.duplicate()
	var changed: Dictionary = {}
	var maximum_delta := 0.0
	var protected_nodes := 0
	var road_nodes := 0
	var shore_nodes := 0
	var land_changes := 0
	var begin := Vector2i((DOMAIN.position / BASE.GRID_STEP).floor())
	var finish := Vector2i((DOMAIN.end / BASE.GRID_STEP).ceil()).min(BASE.GRID_SIZE - Vector2i.ONE)
	for y in range(begin.y, finish.y + 1):
		for x in range(begin.x, finish.x + 1):
			var cell := Vector2i(x,y)
			var p := Vector2(cell * BASE.GRID_STEP)
			var index: int = y * BASE.GRID_SIZE.x + x
			var road: Vector2 = _road_distance(p)
			var bank: float = source.call("bank", p)
			if not is_finite(original[index]) or not is_finite(bank): return _failure("Nonfinite RF/bank")
			var road_weight: float = 1.0 if is_inf(road.x) else smoothstep(road.y + 120., road.y + 260., road.x)
			var shore_weight: float = smoothstep(128., 256., bank)
			if road_weight == 0.: road_nodes += 1
			if shore_weight == 0.: shore_nodes += 1
			var physical_weight: float = _physical_weight(p)
			if physical_weight == 0.: protected_nodes += 1
			var edge: float = minf(p.x-DOMAIN.position.x, DOMAIN.end.x-p.x)
			edge = minf(edge, DOMAIN.end.y-p.y)
			var weight: float = road_weight * shore_weight * physical_weight * smoothstep(0., 96., edge)
			if weight == 0. or original[index] <= BASE.WATER_Y: continue
			var replacement := 0.0
			var original_road: Vector2 = source.call("road_distance",p)
			for mass: Dictionary in MASSES:
				replacement += _natural_mass(p,mass) - _old_mass(p,mass,original_road)
			result_heights[index] = original[index] + replacement * weight
			if not is_finite(result_heights[index]): return _failure("Nonfinite new RF")
			if (result_heights[index] > BASE.WATER_Y) != (original[index] > BASE.WATER_Y): land_changes += 1
			if result_heights[index] != original[index]:
				changed[index] = true
				maximum_delta = maxf(maximum_delta, absf(result_heights[index]-original[index]))
	if changed.is_empty() or land_changes != 0: return _failure("No real height change or changed water/land vertices")
	var support_audit: Dictionary = _support_audit(original_bytes, result_heights.to_byte_array())
	if not bool(support_audit.get("passed",false)): return _failure("Original object support lattice changed")
	var baseline_mesh: ArrayMesh = ResourceLoader.load(BASELINE_MESH,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var mesh_result: Dictionary = _derive_mesh(baseline_mesh, original, result_heights, changed)
	if not bool(mesh_result.get("passed",false)): return _failure(String(mesh_result.get("error","Missing new actual mesh")))
	var old_selector: Image = Image.load_from_file(BASELINE_SELECTOR)
	if old_selector == null or old_selector.get_size() != BASE.SIZE / BASE.SELECTOR_STEP: return _failure("Missing exact selector canvas")
	old_selector.convert(Image.FORMAT_RGB8)
	var selector: Image = old_selector.duplicate() as Image
	var selector_result: Dictionary = _derive_selector(source, original, result_heights, old_selector, selector, changed)
	if not bool(selector_result.get("passed",false)): return _failure(String(selector_result.get("error","Selector regeneration failed")))
	if source.get("heights").to_byte_array() != original_bytes or _sha(JSON.stringify(source.get("vegetation_sites")).to_utf8_buffer()) != caller_sites:
		return _failure("Helper mutated caller RF or original instance sites")
	for path: String in BASELINE_PINS:
		if FileAccess.get_sha256(path).to_lower() != BASELINE_PINS[path]: return _failure("Input changed during derivation: " + path)
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir)) != OK: return _failure("Cannot create NEW geometry directory")
	var artifacts: Dictionary = {}
	var rf_path := output_dir + "terrain_height.rf"
	var file := FileAccess.open(rf_path,FileAccess.WRITE)
	if file == null: return _failure("Cannot write NEW RF")
	file.store_buffer(result_heights.to_byte_array())
	file.flush()
	var io: Error = file.get_error()
	file.close()
	if io != OK or FileAccess.get_file_as_bytes(rf_path) != result_heights.to_byte_array(): return _failure("NEW RF write/readback not exact")
	var mesh: ArrayMesh = mesh_result.mesh
	var mesh_path := output_dir + "terrain_mesh.res"
	var selector_path := output_dir + "source_topology.png"
	if ResourceSaver.save(mesh,mesh_path) != OK or selector.save_png(selector_path) != OK: return _failure("NEW mesh/selector save failed")
	var saved_mesh: ArrayMesh = ResourceLoader.load(mesh_path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var saved_selector: Image = Image.load_from_file(selector_path)
	if saved_mesh == null or not _mesh_exact(mesh,saved_mesh) or saved_selector == null: return _failure("NEW mesh/selector missing after save")
	saved_selector.convert(Image.FORMAT_RGB8)
	if saved_selector.get_size() != selector.get_size() or saved_selector.get_data() != selector.get_data(): return _failure("NEW selector write/readback changed")
	for pair: Array in [["height_rf",rf_path],["terrain_mesh",mesh_path],["source_topology",selector_path]]:
		artifacts[pair[0]] = {"path":pair[1],"sha256":FileAccess.get_sha256(pair[1])}
	var audit: Dictionary = {"schema_version":1,"scope":"NEW_V9C_DERIVED_RF_MESH_SELECTOR_SOURCE_ONLY_NOT_GPU_NAV_FIELD_OR_VISUAL_APPROVAL",
		"status":"DERIVED_GEOMETRY_SOURCE_CHECKS_PASS_REQUIRES_ACTUAL_CAPTURE","baseline_sha256":BASELINE_PINS.duplicate(true),
		"executed_helper":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)},
		"caller_source":{"path":source.get_script().resource_path,"sha256":FileAccess.get_sha256(source.get_script().resource_path)},
		"artifacts":artifacts.duplicate(true),"height_grid_size":[BASE.GRID_SIZE.x,BASE.GRID_SIZE.y],"height_grid_step_px":BASE.GRID_STEP,
		"changed_nodes":changed.size(),"maximum_height_delta_m":maximum_delta,"water_land_vertex_changes":land_changes,
		"domain_source_px":[DOMAIN.position.x,DOMAIN.position.y,DOMAIN.size.x,DOMAIN.size.y],"two_mass_recipe":"OLD_SEPARABLE_SHOULDERS_REPLACED_BY_ROTATED_COMPACT_ELLIPTIC_LOBES_V1",
		"protected_zero_weight_nodes":protected_nodes,"road_zero_weight_nodes":road_nodes,"shore_zero_weight_nodes":shore_nodes,
		"protection_shapes":_protected.size(),"objects":baseline_objects.size(),"portals":record.portals.size(),"routes":source.get("routes").size(),"structures":source.get("structures").size(),
		"object_support":support_audit,"mesh":mesh_result.audit,"selector":selector_result.audit,"original_site_signature":caller_sites,
		"old_NAV_unchanged_claim":false,"normal_rules":"Current actual index faces; clockwise native winding reversed only for NORMAL cross product, never index edits",
		"native_binary_capture_required":true,"whole_GPU_approval":false,"visual_approved":false,"production_approved":false}
	var report_path := output_dir + "derivation_report.json"
	var report: Dictionary={"schema_version":1,"passed":true,"error":"","status":audit.status,"artifacts":artifacts.duplicate(true),"audit":audit}
	if not _write_json(report_path,report): return _failure("Derivation audit exact write/readback failed")
	artifacts["derivation_report"] = {"path":report_path,"sha256":FileAccess.get_sha256(report_path)}
	return {"passed":true,"error":"","heights":result_heights,"mesh":mesh,"selector":selector,"artifacts":artifacts,"audit":audit}

func _prepare_protection(record: Dictionary, objects: Array) -> bool:
	var compounds: Dictionary = {}
	for portal: Dictionary in record.portals:
		var p: Vector2 = _v2(portal.get("source_XZ_foot_px"))
		if not p.is_finite(): error="Missing measured source door"; return false
		compounds[portal.compound_id] = p
		_add_rect("door_"+String(portal.id),Rect2(p-Vector2(64,64),Vector2(128,208)))
	for object: Dictionary in objects:
		var oid: String = object.id
		var foot: Vector2 = _v2(object.get("source_XZ_foot_px"))
		if object.get("role") == "independent_generated_compound":
			if not compounds.has(oid): error="Compound has no exact source portal"; return false
			foot = compounds[oid]
			var world: Vector2 = _v2(object.get("world_foot_px"))
			if not object.get("solid_polygons_px") is Array or not world.is_finite(): error="Missing measured compound solids"; return false
			for raw: Array in object.solid_polygons_px:
				if raw.size()<3: error="Missing compound polygon"; return false
				var rect := Rect2(_v2(raw[0])+Vector2(0,foot.y-world.y),Vector2.ZERO)
				for point: Variant in raw:
					var p: Vector2 = _v2(point)+Vector2(0,foot.y-world.y)
					if not p.is_finite(): error="Nonfinite compound polygon"; return false
					rect=rect.expand(p)
				_add_rect(oid,rect)
		elif String(object.get("role","")).begins_with("bridge_"):
			var bounds: Variant = object.get("actual_used_world_bounds_m")
			if not bounds is Array or bounds.size()!=2 or float(object.get("deck_height_m",INF))!=0.: error="Missing actual deck/post world bounds"; return false
			var low: Vector3 = _v3(bounds[0])
			var high: Vector3 = _v3(bounds[1])
			if not low.is_finite() or not high.is_finite(): error="Invalid bridge support bounds"; return false
			var start := Vector2(low.x*BASE.PPM+BASE.SIZE.x*.5,low.z*BASE.Z_PPM+BASE.SIZE.y*.5)
			var finish := Vector2(high.x*BASE.PPM+BASE.SIZE.x*.5,high.z*BASE.Z_PPM+BASE.SIZE.y*.5)
			_add_rect(oid,Rect2(start,finish-start))
			foot=_v2(object.get("world_foot_px"))
		else:
			if not foot.is_finite(): error="Missing original native instance source foot: "+oid; return false
			if object.has("source_fullxz_rect_px"):
				var raw: Variant=object.source_fullxz_rect_px
				if not raw is Array or raw.size()!=4: error="Missing real fullXZ footprint"; return false
				_add_rect(oid,Rect2(Vector2(float(raw[0]),float(raw[1])),Vector2(float(raw[2]),float(raw[3]))))
			else:
				var size: Vector2=_v2(object.get("collision_size_px"))
				var center: Vector2=_v2(object.get("collision_center_world_px",object.get("world_foot_px")))
				var world: Vector2=_v2(object.get("world_foot_px"))
				if not size.is_finite() or size.x<=0 or size.y<=0 or not center.is_finite() or not world.is_finite(): error="Missing measured native physical footprint: "+oid; return false
				_add_rect(oid,Rect2(center+Vector2(0,foot.y-world.y)-size*.5,size))
		if not foot.is_finite(): error="Missing original entity support foot"; return false
		# Always freeze all FOUR native lattice corners, not only the interpolated
		# foot height. The rectangle contains the complete 10x6 shoe + lattice halo.
		_add_rect(oid+"_shoe",Rect2(foot-Vector2(18,14),Vector2(36,28)))
		var cell:=Vector2i((foot/BASE.GRID_STEP).floor()).clamp(Vector2i.ZERO,BASE.GRID_SIZE-Vector2i(2,2))
		_feet.append({"id":oid,"source_foot_px":[foot.x,foot.y],"indices":[cell.y*BASE.GRID_SIZE.x+cell.x,cell.y*BASE.GRID_SIZE.x+cell.x+1,(cell.y+1)*BASE.GRID_SIZE.x+cell.x,(cell.y+1)*BASE.GRID_SIZE.x+cell.x+1]})
	return true

func _index_roads(routes: Array) -> bool:
	var ids: Dictionary={}
	for route: Dictionary in routes:
		var id: String=String(route.get("id",""))
		var points: Variant=route.get("points")
		var width: float=float(route.get("half_width_px",INF))
		if id.is_empty() or ids.has(id) or not points is PackedVector2Array or points.size()<2 or not is_finite(width) or width<=0.:
			error="Invalid exact prepared road geometry"; return false
		ids[id]=true
		for index in range(points.size()-1):
			var a: Vector2=points[index]
			var b: Vector2=points[index+1]
			if not a.is_finite() or not b.is_finite(): error="Nonfinite road segment"; return false
			# The parent road buckets have a 160px query halo. Protection needs a
			# larger halo; build a separate truthful index instead of assuming INF
			# from the smaller parent index means no nearby protected road.
			var bound: Rect2=Rect2(a,Vector2.ZERO).expand(b).grow(width+260.)
			for y in range(floori(bound.position.y/PROTECTION_BUCKET),floori(bound.end.y/PROTECTION_BUCKET)+1):
				for x in range(floori(bound.position.x/PROTECTION_BUCKET),floori(bound.end.x/PROTECTION_BUCKET)+1):
					var key:=Vector2i(x,y)
					if not _road_buckets.has(key): _road_buckets[key]=[]
					_road_buckets[key].append({"a":a,"b":b,"width":width})
	return true

func _road_distance(p: Vector2) -> Vector2:
	var distance:=INF
	var width:=48.0
	for segment: Dictionary in _road_buckets.get(Vector2i((p/PROTECTION_BUCKET).floor()),[]):
		var delta: Vector2=segment.b-segment.a
		var closest: Vector2=segment.a+delta*clampf((p-segment.a).dot(delta)/maxf(delta.length_squared(),.000001),0.,1.)
		var actual: float=p.distance_to(closest)
		if actual<distance:
			distance=actual
			width=segment.width
	return Vector2(distance,width)

func _add_rect(id: String, rect: Rect2) -> void:
	var guarded: Rect2=rect.grow(PHYSICAL_HALO)
	var index: int=_protected.size()
	_protected.append({"id":id,"rect":guarded})
	var soft: Rect2=guarded.grow(SOFT_HALO)
	for y in range(floori(soft.position.y/PROTECTION_BUCKET),floori(soft.end.y/PROTECTION_BUCKET)+1):
		for x in range(floori(soft.position.x/PROTECTION_BUCKET),floori(soft.end.x/PROTECTION_BUCKET)+1):
			var key:=Vector2i(x,y)
			if not _buckets.has(key): _buckets[key]=[]
			_buckets[key].append(index)

func _physical_weight(p: Vector2) -> float:
	var weight:=1.0
	for index: int in _buckets.get(Vector2i((p/PROTECTION_BUCKET).floor()),[]):
		var rect: Rect2=_protected[index].rect
		var distance: float=p.distance_to(p.clamp(rect.position,rect.end))
		weight=minf(weight,smoothstep(0.,SOFT_HALO,distance))
	return weight

func _old_mass(p: Vector2, mass: Dictionary, road: Vector2) -> float:
	var q: Vector2=(p-mass.center)/mass.radius
	var protect: float=1. if is_inf(road.x) else smoothstep(road.y+90.,road.y+260.,road.x)
	return mass.height*(1.-smoothstep(.40,1.25,absf(q.x)))*smoothstep(-1.45,-.40,q.y)*(1.-smoothstep(mass.front,.72,q.y))*(.45+.55*(1.-smoothstep(-.03,.23,q.y+.13*q.x)))*(1.-.30*exp(-pow((q.x-.33)/.17,2.))*smoothstep(-.6,.5,q.y))*protect

func _natural_mass(p: Vector2, mass: Dictionary) -> float:
	var delta: Vector2=p-mass.center
	var rotated: Vector2=delta.rotated(-float(mass.angle))
	var q: Vector2=rotated/mass.radius
	var distance: float=q.length()
	var envelope: float=1.-smoothstep(1.35,1.90,distance)
	var main: float=exp(-(q.x*q.x*.95+q.y*q.y*1.8))
	var minor: float=exp(-((q.x+.42)*(q.x+.42)*3.4+(q.y-.26)*(q.y-.26)*4.6))
	return float(mass.height)*envelope*(.58*main+.20*minor)

func _support_audit(before: PackedByteArray, after: PackedByteArray) -> Dictionary:
	var rows: Array[Dictionary]=[]
	for row: Dictionary in _feet:
		for index: int in row.indices:
			if before.slice(index*4,index*4+4)!=after.slice(index*4,index*4+4): return {"passed":false,"id":row.id,"index":index}
		rows.append(row.duplicate(true))
	return {"passed":true,"objects":rows.size(),"four_corners_per_object":4,"protected_support_rows":rows,"protected_RF_bytes_exact":true}

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
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	if mesh.get_surface_count()!=1: return {"passed":false,"error":"Derived native mesh failed"}
	var actual: Array=mesh.surface_get_arrays(0)
	var actual_vertices: PackedVector3Array=actual[Mesh.ARRAY_VERTEX]
	var old_vertices: PackedVector3Array=old_arrays[Mesh.ARRAY_VERTEX]
	for index in actual_vertices.size():
		if actual_vertices[index].x!=old_vertices[index].x or actual_vertices[index].z!=old_vertices[index].z or actual_vertices[index].y!=heights[index]: return {"passed":false,"error":"Actual native mesh/RF/XZ relation failed"}
		if not changed.has(index) and actual_vertices[index]!=old_vertices[index]: return {"passed":false,"error":"Unchanged native vertex altered"}
	for slot in Mesh.ARRAY_MAX:
		if slot not in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL] and not _same_array(old_arrays[slot],actual[slot]): return {"passed":false,"error":"Actual protected native arrays changed on construction"}
	return {"passed":true,"mesh":mesh,"audit":{"vertex_count":vertices.size(),"indices_count":indices.size(),"changed_Y_nodes":changed.size(),"recomputed_actual_face_normals":affected.size(),"XZ_UV_indices_other_slots_exact":true,"RF_vertex_relation":"same row-major Float32 height lattice"}}

func _derive_selector(source: RefCounted, original: PackedFloat32Array, heights: PackedFloat32Array, before: Image, after: Image, changed: Dictionary) -> Dictionary:
	var minimum:=BASE.GRID_SIZE
	var maximum:=Vector2i.ZERO
	for index: int in changed:
		var cell:=Vector2i(index%BASE.GRID_SIZE.x,index/BASE.GRID_SIZE.x)
		minimum=minimum.min(cell)
		maximum=maximum.max(cell)
	var start:=((minimum-Vector2i.ONE)*BASE.GRID_STEP/BASE.SELECTOR_STEP).max(Vector2i.ZERO)
	var finish:=((maximum+Vector2i.ONE)*BASE.GRID_STEP/BASE.SELECTOR_STEP).min(before.get_size()-Vector2i.ONE)
	var nav_changes:=0
	var land_changes:=0
	var protected_cells:=0
	var maximum_grade_delta:=0.0
	var minimum_height_delta:=0.0
	for y in range(start.y,finish.y+1):
		for x in range(start.x,finish.x+1):
			var p:=Vector2(x,y)*BASE.SELECTOR_STEP
			var old: Dictionary=_selector(source,original,p)
			var fresh: Dictionary=_selector(source,heights,p)
			var previous: Color=before.get_pixel(x,y)
			if (previous.r==1.)!=old.land or (previous.b==1.)!=old.walk or previous.g!=0.: return {"passed":false,"error":"Frozen selector does not match actual source/RF formula"}
			if fresh.land!=old.land: land_changes+=1
			if fresh.walk!=old.walk:
				nav_changes+=1
				var road: Vector2=_road_distance(p)
				if _physical_weight(p)==0. or road.x<=road.y+120. or float(source.call("bank",p))<=128.: return {"passed":false,"error":"Changed protected road/entity/shore navigation"}
			if _physical_weight(p)==0.: protected_cells+=1
			maximum_grade_delta=maxf(maximum_grade_delta,absf(fresh.gradient-old.gradient))
			minimum_height_delta=maxf(minimum_height_delta,absf(fresh.min_height-old.min_height))
			after.set_pixel(x,y,Color(1. if fresh.land else 0.,0.,1. if fresh.walk else 0.))
	if land_changes!=0: return {"passed":false,"error":"Actual source selector changed water/land"}
	return {"passed":true,"audit":{"recomputed_2px_cells":(finish.x-start.x+1)*(finish.y-start.y+1),"source_rect_px":[start.x*2,start.y*2,(finish.x-start.x+1)*2,(finish.y-start.y+1)*2],"water_land_changes":land_changes,"nonprotected_mountain_NAV_changes":nav_changes,"protected_nav_cells":protected_cells,"maximum_gradient_delta":maximum_grade_delta,"maximum_min_height_delta_m":minimum_height_delta,"walk_predicate":"full 2px native triangles, height>-.025, bank>28, gradient<.72","NAV_is_new_actual_derived_source_not_old_SHA":true}}

func _selector(source: RefCounted, heights: PackedFloat32Array, p: Vector2) -> Dictionary:
	var cell:=Vector2i((p/BASE.GRID_STEP).floor()).clamp(Vector2i.ZERO,BASE.GRID_SIZE-Vector2i(2,2))
	var local: Vector2=(p-Vector2(cell*BASE.GRID_STEP))/BASE.GRID_STEP
	var gradient:=0.0
	if local.x+local.y<=1.: gradient=maxf(gradient,_gradient(heights,cell,false))
	if local.x+local.y+2.*BASE.SELECTOR_STEP/BASE.GRID_STEP>=1.: gradient=maxf(gradient,_gradient(heights,cell,true))
	var low:=INF
	var coast:=INF
	for offset: Vector2 in [Vector2.ZERO,Vector2(2,0),Vector2(0,2),Vector2(2,2),Vector2(1,1)]:
		low=minf(low,_height(heights,p+offset))
		coast=minf(coast,float(source.call("bank",p+offset)))
	return {"land":low>BASE.WATER_Y,"walk":low>BASE.WATER_Y and coast>BASE.SHORE_MARGIN_PX and gradient<BASE.MAX_GRADIENT,"gradient":gradient,"min_height":low}

func _height(heights: PackedFloat32Array,p: Vector2) -> float:
	var q: Vector2=p.clamp(Vector2.ZERO,Vector2(BASE.SIZE))/BASE.GRID_STEP
	var cell:=Vector2i(mini(floori(q.x),BASE.GRID_SIZE.x-2),mini(floori(q.y),BASE.GRID_SIZE.y-2))
	var local: Vector2=q-Vector2(cell)
	var a: float=heights[cell.y*BASE.GRID_SIZE.x+cell.x]
	var b: float=heights[cell.y*BASE.GRID_SIZE.x+cell.x+1]
	var c: float=heights[(cell.y+1)*BASE.GRID_SIZE.x+cell.x]
	var d: float=heights[(cell.y+1)*BASE.GRID_SIZE.x+cell.x+1]
	return a+(b-a)*local.x+(c-a)*local.y if local.x+local.y<=1. else d+(c-d)*(1.-local.x)+(b-d)*(1.-local.y)

func _gradient(h: PackedFloat32Array,cell: Vector2i,upper: bool) -> float:
	var a: float=h[cell.y*BASE.GRID_SIZE.x+cell.x]
	var b: float=h[cell.y*BASE.GRID_SIZE.x+cell.x+1]
	var c: float=h[(cell.y+1)*BASE.GRID_SIZE.x+cell.x]
	var d: float=h[(cell.y+1)*BASE.GRID_SIZE.x+cell.x+1]
	return Vector2((d-c if upper else b-a)*BASE.PPM/BASE.GRID_STEP,(d-b if upper else c-a)*BASE.Z_PPM/BASE.GRID_STEP).length()

func _mesh_exact(a: ArrayMesh,b: ArrayMesh) -> bool:
	if a.get_surface_count()!=b.get_surface_count(): return false
	for surface in a.get_surface_count():
		if a.surface_get_primitive_type(surface)!=b.surface_get_primitive_type(surface): return false
		var aa: Array=a.surface_get_arrays(surface)
		var bb: Array=b.surface_get_arrays(surface)
		for slot in Mesh.ARRAY_MAX:
			if not _same_array(aa[slot],bb[slot]): return false
	return true

func _same_array(a: Variant,b: Variant) -> bool:
	if a==null or b==null: return a==null and b==null
	if typeof(a)!=typeof(b): return false
	if a is PackedByteArray: return a==b
	return a.to_byte_array()==b.to_byte_array()

func _same_value(a: Variant,b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _same_value(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size(): return false
		for index in a.size():
			if not _same_value(a[index],b[index]): return false
		return true
	if typeof(a) in [TYPE_INT,TYPE_FLOAT] and typeof(b) in [TYPE_INT,TYPE_FLOAT]: return is_finite(float(a)) and is_finite(float(b)) and a==b
	return typeof(a)==typeof(b) and a==b

func _v2(raw: Variant) -> Vector2:
	if not raw is Array or raw.size()!=2: return Vector2(INF,INF)
	for value: Variant in raw:
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)): return Vector2(INF,INF)
	return Vector2(raw[0],raw[1])

func _v3(raw: Variant) -> Vector3:
	if not raw is Array or raw.size()!=3: return Vector3(INF,INF,INF)
	for value: Variant in raw:
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)): return Vector3(INF,INF,INF)
	return Vector3(raw[0],raw[1],raw[2])

func _sha(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	return hash.finish().hex_encode()

func _write_json(path: String,value: Dictionary) -> bool:
	var text: String=JSON.stringify(value,"\t")
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(text)
	file.flush()
	var code: Error=file.get_error()
	file.close()
	return code==OK and FileAccess.get_file_as_string(path)==text and JSON.parse_string(text) is Dictionary

func _failure(message: String) -> Dictionary:
	error=message
	return {"passed":false,"error":message,"scope":"SOURCE_DERIVATION_REFUSED_NOT_CAPTURE_OR_APPROVAL"}
