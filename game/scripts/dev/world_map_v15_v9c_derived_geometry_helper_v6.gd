extends "res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v5.gd"

## NEW proposal after ROOT213 real visual failure. RF HARD domains stay exact.
## Only RF SOFT feathers broaden; native ABC and original NAV hard tests remain.
const V6_PARENT_PATH := "res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v5.gd"
const V6_PARENT_SHA := "42b1e135c010e78af769cd321b8cf8167f01080dfee9fb5f530f273118bda93b"
const V6_RF_SOFT_PX := 640.0

func derive(source: RefCounted, baseline_objects: Array, output_dir: String) -> Dictionary:
	error = ""
	_v3_packing_audit.clear()
	_v4_selector_diagnostic.clear()
	_rf_guard_shapes.clear()
	_rf_guard_buckets.clear()
	_rf_guard_road_buckets.clear()
	_catalog_v2.clear()
	_verified_paths_v2.clear()
	_image_sizes_v2.clear()
	_verified_geometry_v2.clear()
	_family_counts_v2.clear()
	_footprint_rows_v2.clear()
	for pair: Array in [[V6_PARENT_PATH,V6_PARENT_SHA],[V5_PARENT_PATH,V5_PARENT_SHA],[V4_PARENT_PATH,V4_PARENT_SHA],[V3_PARENT_PATH,V3_PARENT_SHA],[ORIGINAL_HELPER_PATH,ORIGINAL_HELPER_SHA]]:
		if FileAccess.get_sha256(pair[0]).to_lower()!=pair[1]:
			return _failure("Frozen geometry/protection/native-packing ancestor differs: "+String(pair[0]))
	if FileAccess.get_sha256(BASELINE_MANIFEST).to_lower()!=BASELINE_PINS[BASELINE_MANIFEST]:
		return _failure("Frozen original body catalog changed")
	var catalog: Variant=JSON.parse_string(FileAccess.get_file_as_string(BASELINE_MANIFEST))
	if not catalog is Dictionary or not catalog.get("asset_sha256") is Dictionary:
		return _failure("Missing exact body asset catalog")
	_catalog_v2=catalog.asset_sha256

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
	if not _v5_index_RF_support(source.get("routes")): return _failure(error)
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
			var road: Vector2 = _v5_RF_road_distance(p)
			var bank: float = source.call("bank", p)
			if not is_finite(original[index]) or not is_finite(bank): return _failure("Nonfinite RF/bank")
			var road_weight: float = 1.0 if is_inf(road.x) else smoothstep(road.y + 120. + RF_SUPPORT_EXTRA_PX, road.y + 120. + RF_SUPPORT_EXTRA_PX + V6_RF_SOFT_PX, road.x)
			var shore_weight: float = smoothstep(128. + RF_SUPPORT_EXTRA_PX, 128. + RF_SUPPORT_EXTRA_PX + V6_RF_SOFT_PX, bank)
			if road_weight == 0.: road_nodes += 1
			if shore_weight == 0.: shore_nodes += 1
			var physical_weight: float = _v5_RF_physical_weight(p)
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
		"domain_source_px":[DOMAIN.position.x,DOMAIN.position.y,DOMAIN.size.x,DOMAIN.size.y],"two_mass_recipe":"OLD_SEPARABLE_SHOULDERS_COMPACT_LOBES_BROAD_RF_SOFT_640_NAV_HARD_UNCHANGED_V2",
		"protected_zero_weight_nodes":protected_nodes,"road_zero_weight_nodes":road_nodes,"shore_zero_weight_nodes":shore_nodes,
		"protection_shapes":_protected.size(),"objects":baseline_objects.size(),"portals":record.portals.size(),"routes":source.get("routes").size(),"structures":source.get("structures").size(),
		"RF_support_guard":_v5_guard_contract(),"RF_transition_measurement":selector_result.audit.get("broader_RF_soft_transition",{}),"object_support":support_audit,"mesh":mesh_result.audit,"selector":selector_result.audit,"original_site_signature":caller_sites,
		"old_NAV_unchanged_claim":false,"normal_rules":"Current actual index faces; clockwise native winding reversed only for NORMAL cross product, never index edits",
		"native_binary_capture_required":true,"whole_GPU_approval":false,"visual_approved":false,"production_approved":false}
	var report_path := output_dir + "derivation_report.json"
	var report: Dictionary={"schema_version":1,"passed":true,"error":"","status":audit.status,"artifacts":artifacts.duplicate(true),"audit":audit}
	if not _write_json(report_path,report): return _failure("Derivation audit exact write/readback failed")
	artifacts["derivation_report"] = {"path":report_path,"sha256":FileAccess.get_sha256(report_path)}
	return {"passed":true,"error":"","heights":result_heights,"mesh":mesh,"selector":selector,"artifacts":artifacts,"audit":audit}

func _v5_index_RF_support(routes: Array) -> bool:
	# Separate RF buckets, never mutate the original NAV hard shapes/index.
	for original: Dictionary in _protected:
		var rect: Rect2=original.rect.grow(RF_SUPPORT_EXTRA_PX)
		var index: int=_rf_guard_shapes.size()
		_rf_guard_shapes.append({"id":original.id,"rect":rect})
		var soft: Rect2=rect.grow(V6_RF_SOFT_PX)
		for y in range(floori(soft.position.y/PROTECTION_BUCKET),floori(soft.end.y/PROTECTION_BUCKET)+1):
			for x in range(floori(soft.position.x/PROTECTION_BUCKET),floori(soft.end.x/PROTECTION_BUCKET)+1):
				var key:=Vector2i(x,y)
				if not _rf_guard_buckets.has(key): _rf_guard_buckets[key]=[]
				_rf_guard_buckets[key].append(index)
	for route: Dictionary in routes:
		var points: PackedVector2Array=route.points
		var width: float=float(route.half_width_px)
		for index in range(points.size()-1):
			var a: Vector2=points[index]
			var b: Vector2=points[index+1]
			var bound: Rect2=Rect2(a,Vector2.ZERO).expand(b).grow(width+120.+RF_SUPPORT_EXTRA_PX+V6_RF_SOFT_PX)
			for y in range(floori(bound.position.y/PROTECTION_BUCKET),floori(bound.end.y/PROTECTION_BUCKET)+1):
				for x in range(floori(bound.position.x/PROTECTION_BUCKET),floori(bound.end.x/PROTECTION_BUCKET)+1):
					var key:=Vector2i(x,y)
					if not _rf_guard_road_buckets.has(key): _rf_guard_road_buckets[key]=[]
					_rf_guard_road_buckets[key].append({"a":a,"b":b,"width":width})
	return true

func _v5_RF_physical_weight(p: Vector2) -> float:
	var weight:=1.0
	for index: int in _rf_guard_buckets.get(Vector2i((p/PROTECTION_BUCKET).floor()),[]):
		var rect: Rect2=_rf_guard_shapes[index].rect
		var distance: float=p.distance_to(p.clamp(rect.position,rect.end))
		weight=minf(weight,smoothstep(0.,V6_RF_SOFT_PX,distance))
	return weight

func _v5_guard_contract() -> Dictionary:
	return {"identity":"RF_HARD_EXTRA16_SOFT640_ORIGINAL_NAV_HARD_UNCHANGED_V2","RF_support_extra_px":RF_SUPPORT_EXTRA_PX,
		"RF":{"physical_total_halo_px":PHYSICAL_HALO+RF_SUPPORT_EXTRA_PX,"physical_soft_width_px":V6_RF_SOFT_PX,
			"road_hard_extra_px":120.+RF_SUPPORT_EXTRA_PX,"road_soft_end_extra_px":120.+RF_SUPPORT_EXTRA_PX+V6_RF_SOFT_PX,
			"shore_hard_bank_px":128.+RF_SUPPORT_EXTRA_PX,"shore_soft_end_bank_px":128.+RF_SUPPORT_EXTRA_PX+V6_RF_SOFT_PX,
			"own_bucket_px":PROTECTION_BUCKET,"separate_physical_and_road_buckets":true},
		"NAV":{"physical_halo_px":PHYSICAL_HALO,"road_hard_extra_px":120.,"shore_hard_bank_px":128.,"selector_formula_unchanged":true,"hard_domain_expanded":false},
		"soft_physical_span_metres_X":V6_RF_SOFT_PX/BASE.PPM,"soft_physical_span_metres_Z":V6_RF_SOFT_PX/BASE.Z_PPM,
		"no_RF_triangle_support_or_NAV_threshold_waiver":true,"visual_approved":false}

func _derive_selector(source: RefCounted,original: PackedFloat32Array,heights: PackedFloat32Array,before: Image,after: Image,changed: Dictionary) -> Dictionary:
	# Parent independently recomputes the same full native triangles and .72.
	var result: Dictionary=super._derive_selector(source,original,heights,before,after,changed)
	if not bool(result.get("passed",false)): return result
	result["audit"]["broader_RF_soft_transition"]=_v6_transition_audit(original,heights,changed)
	return result

func _v6_transition_audit(original: PackedFloat32Array,heights: PackedFloat32Array,changed: Dictionary) -> Dictionary:
	var bins: Array=[.25,.72,1.5,3.,6.]
	var old_bins: Array=[0,0,0,0,0,0]
	var new_bins: Array=[0,0,0,0,0,0]
	var maximum_before:=0.0
	var maximum_after:=0.0
	var maximum_increase:=0.0
	var protected_original_flat:=0
	var protected_remaining_flat:=0
	var changed_triangles:=0
	var total:=0
	var start:=Vector2i((DOMAIN.position/BASE.GRID_STEP).floor())
	var finish:=Vector2i((DOMAIN.end/BASE.GRID_STEP).ceil()).min(BASE.GRID_SIZE-Vector2i(2,2))
	for y in range(start.y,finish.y+1):
		for x in range(start.x,finish.x+1):
			var cell:=Vector2i(x,y)
			var a: int=y*BASE.GRID_SIZE.x+x
			var involved: Array=[a,a+1,a+BASE.GRID_SIZE.x,a+BASE.GRID_SIZE.x+1]
			var incident:=false
			for vertex: int in involved:
				if changed.has(vertex): incident=true
			var hard: bool=_v5_RF_physical_weight(Vector2(cell*BASE.GRID_STEP))==0.
			for upper: bool in [false,true]:
				var old_grade: float=_gradient(original,cell,upper)
				var new_grade: float=_gradient(heights,cell,upper)
				var old_bin:=bins.size()
				var new_bin:=bins.size()
				for index in bins.size():
					if old_bin==bins.size() and old_grade<bins[index]: old_bin=index
					if new_bin==bins.size() and new_grade<bins[index]: new_bin=index
				old_bins[old_bin]+=1
				new_bins[new_bin]+=1
				maximum_before=maxf(maximum_before,old_grade)
				maximum_after=maxf(maximum_after,new_grade)
				maximum_increase=maxf(maximum_increase,new_grade-old_grade)
				if incident: changed_triangles+=1
				if hard and original[a]>=1.5 and old_grade<.025:
					protected_original_flat+=1
					if new_grade<.025: protected_remaining_flat+=1
				total+=1
	return {"identity":"ACTUAL_NATIVE_TRIANGLE_GRADIENT_AND_RETAINED_FLAT_TOP_DIAGNOSTIC_V1","domain_source_px":[DOMAIN.position.x,DOMAIN.position.y,DOMAIN.size.x,DOMAIN.size.y],
		"triangles":total,"changed_incident_triangles":changed_triangles,"grade_bin_upper_bounds":bins,"old_grade_bin_counts":old_bins,"new_grade_bin_counts":new_bins,
		"maximum_old_grade":maximum_before,"maximum_new_grade":maximum_after,"maximum_added_grade":maximum_increase,
		"original_protected_flat_triangles_above1_5m_grade_below_025":protected_original_flat,
		"remaining_protected_flat_triangles_above1_5m_grade_below_025":protected_remaining_flat,
		"flat_count_definition":"triangle A reference vertex in RF hard domain and old height>=1.5m; triangle gradient<.025; not an all-vertices/fullfoot proof",
		"hard_original_RF_preserved":true,"flat_tops_not_claimed_removed":true,"visual_approved":false,"production_approved":false}

func _failure(message: String) -> Dictionary:
	var result: Dictionary=super._failure(message)
	result["RF_support_guard"]=_v5_guard_contract()
	var diagnostic: Dictionary=result.get("protected_selector_diagnostic",{})
	for row: Dictionary in diagnostic.get("involved_lattice_vertices",[]):
		var p:=Vector2(row["source_px"][0],row["source_px"][1])
		var road: Vector2=_v5_RF_road_distance(p)
		row["RF_support_physical_weight"]=_v5_RF_physical_weight(p)
		row["RF_support_road_weight"]=1. if is_inf(road.x) else smoothstep(road.y+136.,road.y+776.,road.x)
		row["RF_support_shore_weight"]=smoothstep(144.,784.,float(row["bank_px"]))
	diagnostic["RF_support_guard"]=_v5_guard_contract()
	return result
