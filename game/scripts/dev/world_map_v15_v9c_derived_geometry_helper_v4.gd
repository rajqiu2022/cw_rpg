extends "res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v3.gd"

## NEW SOURCE-ONLY failure instrumentation. RF weights, selector formula and every
## protection predicate remain exact parent rules. No guard-band change or waiver.
const V4_PARENT_PATH := "res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v3.gd"
const V4_PARENT_SHA := "34b30d35a4d3fe0349407ceada274ecf077010340d57741f80f38c82e2fabdf0"
var _v4_selector_diagnostic: Dictionary={}

func derive(source: RefCounted,baseline_objects: Array,output_dir: String) -> Dictionary:
	_v4_selector_diagnostic.clear()
	if FileAccess.get_sha256(V4_PARENT_PATH).to_lower()!=V4_PARENT_SHA:
		return _failure("Frozen v3 native ABC packing/protection parent differs")
	return super.derive(source,baseline_objects,output_dir)

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
			if (previous.r==1.)!=old.land or (previous.b==1.)!=old.walk or previous.g!=0.:
				return _v4_selector_failure("Frozen selector does not match actual source/RF formula",source,original,heights,p,old,fresh,previous,changed)
			if fresh.land!=old.land: land_changes+=1
			if fresh.walk!=old.walk:
				nav_changes+=1
				var road: Vector2=_road_distance(p)
				if _physical_weight(p)==0. or road.x<=road.y+120. or float(source.call("bank",p))<=128.:
					return _v4_selector_failure("Changed protected road/entity/shore navigation",source,original,heights,p,old,fresh,previous,changed)
			if _physical_weight(p)==0.: protected_cells+=1
			maximum_grade_delta=maxf(maximum_grade_delta,absf(fresh.gradient-old.gradient))
			minimum_height_delta=maxf(minimum_height_delta,absf(fresh.min_height-old.min_height))
			after.set_pixel(x,y,Color(1. if fresh.land else 0.,0.,1. if fresh.walk else 0.))
	if land_changes!=0: return {"passed":false,"error":"Actual source selector changed water/land"}
	return {"passed":true,"audit":{"recomputed_2px_cells":(finish.x-start.x+1)*(finish.y-start.y+1),"source_rect_px":[start.x*2,start.y*2,(finish.x-start.x+1)*2,(finish.y-start.y+1)*2],"water_land_changes":land_changes,"nonprotected_mountain_NAV_changes":nav_changes,"protected_nav_cells":protected_cells,"maximum_gradient_delta":maximum_grade_delta,"maximum_min_height_delta_m":minimum_height_delta,"walk_predicate":"full 2px native triangles, height>-.025, bank>28, gradient<.72","NAV_is_new_actual_derived_source_not_old_SHA":true,"instrumentation_only_no_protection_or_RF_change":true}}

func _v4_selector_failure(message: String,source: RefCounted,original: PackedFloat32Array,heights: PackedFloat32Array,p: Vector2,old: Dictionary,fresh: Dictionary,previous: Color,changed: Dictionary) -> Dictionary:
	var road: Vector2=_road_distance(p)
	var physical_weight: float=_physical_weight(p)
	var bank: float=float(source.call("bank",p))
	var nearby: Array[Dictionary]=[]
	var hard_ids: Array[String]=[]
	for index: int in _buckets.get(Vector2i((p/PROTECTION_BUCKET).floor()),[]):
		var row: Dictionary=_protected[index]
		var rect: Rect2=row.rect
		var distance: float=p.distance_to(p.clamp(rect.position,rect.end))
		if distance==0.: hard_ids.append(String(row.id))
		nearby.append({"id":row.id,"guarded_rect_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"distance_px":distance,"weight":smoothstep(0.,SOFT_HALO,distance)})
	var cell:=Vector2i((p/BASE.GRID_STEP).floor()).clamp(Vector2i.ZERO,BASE.GRID_SIZE-Vector2i(2,2))
	var local: Vector2=(p-Vector2(cell*BASE.GRID_STEP))/BASE.GRID_STEP
	var lattice: Dictionary={}
	_v4_add_cell(lattice,cell)
	var samples: Array[Dictionary]=[]
	for offset: Vector2 in [Vector2.ZERO,Vector2(2,0),Vector2(0,2),Vector2(2,2),Vector2(1,1)]:
		var point: Vector2=p+offset
		var q: Vector2=point.clamp(Vector2.ZERO,Vector2(BASE.SIZE))/BASE.GRID_STEP
		var sample_cell:=Vector2i(mini(floori(q.x),BASE.GRID_SIZE.x-2),mini(floori(q.y),BASE.GRID_SIZE.y-2))
		var sample_local: Vector2=q-Vector2(sample_cell)
		_v4_add_cell(lattice,sample_cell)
		samples.append({"source_px":[point.x,point.y],"cell":[sample_cell.x,sample_cell.y],"local_uv":[sample_local.x,sample_local.y],"triangle":"ABC" if sample_local.x+sample_local.y<=1. else "DBC","old_height_m":_height(original,point),"new_height_m":_height(heights,point),"bank_px":float(source.call("bank",point))})
	var rows: Array[Dictionary]=[]
	var lattice_indices: Array[int]=[]
	for index: int in lattice: lattice_indices.append(index)
	lattice_indices.sort()
	var original_bytes: PackedByteArray=original.to_byte_array()
	var new_bytes: PackedByteArray=heights.to_byte_array()
	for index: int in lattice_indices:
		var vertex:=Vector2i(index%BASE.GRID_SIZE.x,index/BASE.GRID_SIZE.x)
		var point:=Vector2(vertex*BASE.GRID_STEP)
		var vertex_road: Vector2=_road_distance(point)
		var vertex_bank: float=float(source.call("bank",point))
		var road_weight: float=1. if is_inf(vertex_road.x) else smoothstep(vertex_road.y+120.,vertex_road.y+260.,vertex_road.x)
		var edge: float=minf(point.x-DOMAIN.position.x,DOMAIN.end.x-point.x)
		edge=minf(edge,DOMAIN.end.y-point.y)
		rows.append({"index":index,"lattice_xy":[vertex.x,vertex.y],"source_px":[point.x,point.y],"old_height_m":original[index],"new_height_m":heights[index],"old_Float32_bytes_hex":original_bytes.slice(index*4,index*4+4).hex_encode(),"new_Float32_bytes_hex":new_bytes.slice(index*4,index*4+4).hex_encode(),"changed":changed.has(index),"road_distance_px":null if is_inf(vertex_road.x) else vertex_road.x,"road_half_width_px":vertex_road.y,"bank_px":vertex_bank,"physical_weight":_physical_weight(point),"road_weight":road_weight,"shore_weight":smoothstep(128.,256.,vertex_bank),"domain_edge_weight":smoothstep(0.,96.,edge)})
	_v4_selector_diagnostic={"identity":"PROTECTED_SELECTOR_FIRST_FAILURE_ACTUAL_TRIANGLE_LATTICE_V1","diagnostic_only":true,"protection_or_RF_rules_changed":false,"error":message,"first_source_px":[p.x,p.y],"selector_cell":[int(p.x/BASE.SELECTOR_STEP),int(p.y/BASE.SELECTOR_STEP)],"old":old.duplicate(true),"fresh":fresh.duplicate(true),"frozen_RGB":[previous.r,previous.g,previous.b],"road_distance_px":null if is_inf(road.x) else road.x,"road_half_width_px":road.y,"nearest_route_segments":_v4_nearest_routes(source,p),"bank_px":bank,"physical_weight":physical_weight,"protected_reasons":{"physical":physical_weight==0.,"road":road.x<=road.y+120.,"shore":bank<=128.},"physical_hard_ids":hard_ids,"physical_bucket_shapes":nearby,"gradient_cell":[cell.x,cell.y],"gradient_local_uv":[local.x,local.y],"gradient_triangles":{"ABC_used":local.x+local.y<=1.,"DBC_used":local.x+local.y+2.*BASE.SELECTOR_STEP/BASE.GRID_STEP>=1.,"old_ABC":_gradient(original,cell,false),"new_ABC":_gradient(heights,cell,false),"old_DBC":_gradient(original,cell,true),"new_DBC":_gradient(heights,cell,true)},"height_bank_samples":samples,"involved_lattice_vertices":rows,"all_original_RF_SHA":_sha(original_bytes),"all_new_RF_SHA":_sha(new_bytes),"no_NAV_waiver":true}
	return {"passed":false,"error":message,"audit":_v4_selector_diagnostic.duplicate(true)}

func _v4_add_cell(target: Dictionary,cell: Vector2i) -> void:
	for delta: Vector2i in [Vector2i.ZERO,Vector2i(1,0),Vector2i(0,1),Vector2i.ONE]:
		var vertex: Vector2i=cell+delta
		target[vertex.y*BASE.GRID_SIZE.x+vertex.x]=true

func _v4_nearest_routes(source: RefCounted,p: Vector2) -> Array[Dictionary]:
	var nearest:=INF
	var found: Array[Dictionary]=[]
	for route: Dictionary in source.get("routes"):
		var points: PackedVector2Array=route.points
		var width: float=float(route.half_width_px)
		for index in range(points.size()-1):
			var a: Vector2=points[index]
			var b: Vector2=points[index+1]
			var delta: Vector2=b-a
			var t: float=clampf((p-a).dot(delta)/maxf(delta.length_squared(),.000001),0.,1.)
			var closest: Vector2=a+delta*t
			var distance: float=p.distance_to(closest)
			if distance<nearest:
				nearest=distance
				found.clear()
			if distance==nearest:
				found.append({"id":route.id,"segment_index":index,"distance_px":distance,"half_width_px":width,"a_source_px":[a.x,a.y],"b_source_px":[b.x,b.y],"closest_source_px":[closest.x,closest.y],"t":t})
	return found

func _failure(message: String) -> Dictionary:
	var result: Dictionary=super._failure(message)
	result["protected_selector_diagnostic"]=_v4_selector_diagnostic.duplicate(true)
	return result

