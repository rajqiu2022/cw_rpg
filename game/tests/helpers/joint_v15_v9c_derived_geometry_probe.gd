extends RefCounted
## Independent SOURCE/actual-resource oracle. Never invokes a derivation helper,
## renderer, publication gate, source.prepare/bank/selector, or approval API.
## CPU source proof is not Field/17-shoe/Physics/input or FULL/visual approval.
const ROOT := "res://art/maps/world_map_v15_complete_v9c/"
const PROTOCOL := "COHERENT_WHOLE_FIXED_CAMERA_DERIVED_RF_V9C_FULL64_112_V1"
const GRID := Vector2i(1537,1025)
const SIZE := Vector2(12288,8192)
const STEP := 8
const PPM := 102.4
const Z_PPM := 102.4 * 0.7071067811865476
const DOMAIN := Rect2(3920,0,2320,1360)
const CPU_PREFIX := "res://build/world_map_v15_v9c_visual_quality_proposal/"
const ROLES := ["height_rf","terrain_mesh","source_topology","derivation_report"]
const BASE_SOURCE := "res://data/maps/world_map_v15_complete_v8_source.json"
const BASE_MANIFEST := "res://art/maps/world_map_v15_complete_v8/art_contract.json"
const BASE_RF := "res://art/maps/world_map_v15_complete_v5/terrain_height.rf"
const BASE_MESH := "res://art/maps/world_map_v15_complete_v5/terrain_mesh.res"
const BASE_SELECTOR := "res://art/maps/world_map_v15_complete_v5/source_topology.png"
const BASE_PINS := {
 BASE_SOURCE:"13f3d5a9940283a92971ea20eae0234301635812dd0975a4c119536fb026cff5",
 BASE_MANIFEST:"cfb7656b2b50690ddb2e28cc91a0fcd23c734ba28cd21b171c67f2857561dd94",
 BASE_RF:"b7210634cbc2d7a2809bfab608e47930d5717459b01dc42df33ae9e6919548b9",
 BASE_MESH:"2eb9ad81081768f938798bf4879df705505783d2aeb9b328927289f7b51d2a9a",
 BASE_SELECTOR:"5d65605fa804faacc03f5378dd4c87c8bcce0f27e38821f11c02a839e28dbb1a",
 "res://art/maps/world_map_v15_complete_v5/chunks/r0_c0_actual_deck_support_mesh.res":"668022ddb74892023ef214dac5551f9b49f79d9958ccfb1126646bc7934923a9",
 "res://scripts/dev/world_map_v15_complete_v5_source.gd":"f812bcd93efe93da54866c2d61287feaeaf6bc68543493b4b54a606d99769299"
}
const EXPECTED_FAMILIES := {"compound_measured_solids":16,"bridge_deck_actual_bounds":5,"bridge_post_actual_bounds":78,"bridge_rail_actual_bounds":10,"boulder_actual_fullxz":46,"tree_actual_collider":655,"bamboo_actual_collider":1517,"herb_nonblocking_render_and_native_support":360}
const HERB_RAW := "res://art/external/polyhaven/shrub_03/shrub_03_1k.gltf"
const HERB_SOURCE_PINS := {
 HERB_RAW:"b76d7c14bc027e834e82d3f984c32b5d060e62908aa90ff9420a637ca253a8ea",
 "res://art/external/polyhaven/shrub_03/shrub_03.bin":"bf4df21e6d2a2bc5f00b4c9142f776171fe7da00cf960001825748067af542b6",
 "res://art/external/polyhaven/shrub_03/textures/shrub_03_nor_gl_1k.jpg":"ff856bacfce859b8a7555dd9a3b92fbd36b2e775d486be71df485afb4235d6c9",
 "res://art/external/polyhaven/shrub_03/textures/shrub_03_diff_1k.jpg":"3cadc7aba46d3aabbd7d6d2b1d04aa32e2a7da0bc87c2d38ef3cb1ee42cb03ec",
 "res://art/external/polyhaven/shrub_03/textures/shrub_03_arm_1k.jpg":"3e2b16812a623037138eedace958210c5f3443a827bbe69663045bba5612f815",
 "res://scripts/dev/build_world_map_v15_complete_v5_full_draft.gd":"2e5efff6bf27f478bea3f6a1131c2919cdd502c6fa37f7969d60067a8c4d2f85",
 "res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd":"032a483213e99649b4adec193d24f413cc897ccc6b7de52a29f46a26abb9a23f"
}
const HERB_ORIGINAL_META_SHA := ["53e90bc14494dc2db0fdf80c2b573caa5ef5e853c6200a88846fc5147fbc8f44","876f0005ea2300d9b455d54ae3a7b8b5b13e6255e2b082c6a2e134d2c6a8fbfb","471ed22c3eb120d70b1ba32f896edf7b0c77fdeead485d934077467b3cd30218"]
const HERB_V8_META_SHA := ["8a1731bbc5b5b2be26a0275702a00e7419c7a92dc38d68ce02510fc38f4e0543","a26ffb0ac51f45e48ce9c68ea060784f35e78139539aa158018a01f862890389","16f2fb4308cd87c0a18620df56a9c72c454712fff9e13cd1aab79e81a81a4935"]
const HERB_CURRENT_META_SHA := ["e3d0b63ca99e6eab4b369f84ac1c8e1de3981be6a7a4d3b897be47e9785db745","46fff336a5d197e799c637cee26ffaffe1bfdf86a04b00895f065d64e5bd9082","a2bd1743a5df8d2d153b30dd98031c8b1ec51096d6fc6c29ad72ec4ffbf19cc6"]
const MASSES := [{"center":Vector2(4780,780),"radius":Vector2(420,310),"height":3.4,"front":.20,"angle":-.31},{"center":Vector2(5430,650),"radius":Vector2(340,240),"height":4.4,"front":.27,"angle":.43}]
var checks: int=0
var errors: Array[String]=[]
var records: Dictionary={}
var inputs: Dictionary={}
var protected_shapes: Array[Rect2]=[]
var physical_buckets: Dictionary={}
var rf_physical_buckets: Dictionary={}
var rf_protected_shapes: Array[Rect2]=[]
var road_buckets: Dictionary={}
var rf_road_buckets: Dictionary={}
var original_road_buckets: Dictionary={}
var river_buckets: Dictionary={}
var native_cache: Dictionary={}
var herb_controls: Dictionary={}
var herb_input_pins: Dictionary={}
var old_height := PackedFloat32Array()
var new_height := PackedFloat32Array()
var original_bridge_domains: Array = []

func _check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label)
	return ok

func _hash(value: Variant) -> bool:
	return value is String and RegEx.create_from_string("^[0-9a-fA-F]{64}$").search(value)!=null

func _pair(value: Variant) -> Vector2:
	if not value is Array or value.size()!=2: return Vector2(INF,INF)
	for n: Variant in value:
		if typeof(n) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(n)): return Vector2(INF,INF)
	return Vector2(value[0],value[1])

func _vector(value: Variant) -> Vector3:
	if not value is Array or value.size()!=3: return Vector3(INF,INF,INF)
	for n: Variant in value:
		if typeof(n) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(n)): return Vector3(INF,INF,INF)
	return Vector3(value[0],value[1],value[2])

func _equal(a: Variant,b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equal(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size(): return false
		for i in a.size():
			if not _equal(a[i],b[i]): return false
		return true
	if typeof(a) in [TYPE_INT,TYPE_FLOAT] and typeof(b) in [TYPE_INT,TYPE_FLOAT]: return is_finite(float(a)) and is_finite(float(b)) and a==b
	return typeof(a)==typeof(b) and a==b

func _sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	if not bytes.is_empty(): context.update(bytes)
	return context.finish().hex_encode()

func _json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not _check(value is Dictionary and not value.is_empty(),"actual nonempty dictionary: "+path): return {}
	return value

func bindings_report(value: Dictionary,manifest: Dictionary,source: Dictionary) -> Dictionary:
	inputs=value.duplicate(true)
	var catalog: Variant=manifest.get("asset_sha256")
	if not _check(inputs.size()==4 and catalog is Dictionary,"exact four explicit CPU artifacts and current catalog"): return result()
	for role: String in ROLES:
		var row: Variant=inputs.get(role)
		if not _check(row is Dictionary and row.size()==2,"exact path/SHA row: "+role): continue
		var path: String=String(row.get("path",""))
		_check(path.begins_with(CPU_PREFIX) and not ".." in path and _hash(row.get("sha256")) and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==String(row.get("sha256","")).to_lower() and catalog.get(path)==row.get("sha256"),"real approved CPU original bytes/catalog: "+role)
	if not errors.is_empty(): return result()
	var report: Dictionary=_json(String(inputs.derivation_report.path))
	var audit: Variant=report.get("audit")
	_check(report.get("schema_version")==1 and report.get("passed")==true and report.get("status")=="DERIVED_GEOMETRY_SOURCE_CHECKS_PASS_REQUIRES_ACTUAL_CAPTURE" and audit is Dictionary,"source-only report schema, never capture PASS substitution")
	var listed: Variant=report.get("artifacts")
	if not _check(listed is Dictionary and listed.size()==3,"report has exactly RF/mesh/selector, no self-hash recursion"): return result()
	for role: String in ["height_rf","terrain_mesh","source_topology"]: _check(_equal(listed.get(role),inputs[role]),"report/current original role exact: "+role)
	if not audit is Dictionary: return result()
	for path: String in BASE_PINS:
		_check(FileAccess.get_sha256(path).to_lower()==BASE_PINS[path] and audit.get("baseline_sha256",{}).get(path)==BASE_PINS[path],"immutable old baseline bytes/audit: "+path)
	for field: String in ["executed_helper","caller_source"]:
		var row: Variant=audit.get(field)
		_check(row is Dictionary and _hash(row.get("sha256")) and FileAccess.file_exists(String(row.get("path",""))) and FileAccess.get_sha256(String(row.get("path",""))).to_lower()==String(row.get("sha256","")).to_lower() and catalog.get(String(row.get("path","")))==row.get("sha256"),"actual helper/caller bytes, never invoking them: "+field)
	_check(_pair(audit.get("height_grid_size"))==Vector2(GRID) and audit.get("height_grid_step_px")==STEP and audit.get("old_NAV_unchanged_claim")==false and int(audit.get("changed_nodes",0))>0 and audit.get("water_land_vertex_changes")==0,"actual changed RF owns NEW navigation, exact lattice and unchanged water/land")
	var support_guard: Dictionary={"identity":"RF_HARD_EXTRA16_SOFT640_ORIGINAL_NAV_HARD_UNCHANGED_V2","RF_support_extra_px":16.,"RF":{"physical_total_halo_px":40.,"physical_soft_width_px":640.,"road_hard_extra_px":136.,"road_soft_end_extra_px":776.,"shore_hard_bank_px":144.,"shore_soft_end_bank_px":784.,"own_bucket_px":128.,"separate_physical_and_road_buckets":true},"NAV":{"physical_halo_px":24.,"road_hard_extra_px":120.,"shore_hard_bank_px":128.,"selector_formula_unchanged":true,"hard_domain_expanded":false},"soft_physical_span_metres_X":640./PPM,"soft_physical_span_metres_Z":640./Z_PPM,"no_RF_triangle_support_or_NAV_threshold_waiver":true,"visual_approved":false}
	_check(_equal(audit.get("RF_support_guard"),JSON.parse_string(JSON.stringify(support_guard))),"independent RF triangle support guard16 contract, unchanged NAV hard domain")
	var full_report: Dictionary=_json(ROOT+"whole_actual_capture.json")
	_check(_equal(full_report.get("derived_geometry_inputs"),inputs) and _equal(full_report.get("geometry_derivation_audit"),audit),"FULL report pins actual CPU input/audit exact, not regional credit")
	var evidence: Variant=source.get("v9c_revision_evidence")
	_check(evidence is Dictionary and _equal(evidence.get("derived_geometry_inputs"),inputs) and _equal(evidence.get("derived_geometry_audit"),audit),"captured source pins actual derived inputs/audit")
	for row: Array in [["height_rf","terrain_height.rf"],["terrain_mesh","terrain_mesh.res"],["source_topology","source_topology.png"]]:
		var original: String=String(inputs[row[0]].path)
		var copy: String=ROOT+row[1]
		_check(original!=copy and catalog.get(copy)==inputs[row[0]].sha256 and FileAccess.get_sha256(copy).to_lower()==String(inputs[row[0]].sha256).to_lower() and FileAccess.get_file_as_bytes(copy)==FileAccess.get_file_as_bytes(original),"distinct runtime exact-byte copy of actual GPU original: "+row[0])
	records["bindings"]={"inputs":inputs.duplicate(true),"audit":audit.duplicate(true),"production_helper_invoked":false}
	return result()

func run(value: Dictionary,manifest: Dictionary,source: Dictionary) -> Dictionary:
	bindings_report(value,manifest,source)
	if not errors.is_empty(): return result()
	old_height=FileAccess.get_file_as_bytes(BASE_RF).to_float32_array()
	new_height=FileAccess.get_file_as_bytes(String(inputs.height_rf.path)).to_float32_array()
	if not _check(old_height.size()==GRID.x*GRID.y and new_height.size()==old_height.size(),"complete two Float32 RF node domains"): return result()
	var original: Dictionary=_json(BASE_SOURCE)
	var audit: Dictionary=records.bindings.audit
	if not _prepare_native_inputs(source,audit) or not _support_and_protection(original,audit): return result()
	var changed: Dictionary={}
	var recipe_exact: bool=true
	for i in new_height.size():
		if not is_finite(old_height[i]) or not is_finite(new_height[i]): recipe_exact=false; break
		var p:=Vector2(Vector2i(i%GRID.x,i/GRID.x)*STEP)
		var expected: float=old_height[i]
		if p.x>=DOMAIN.position.x and p.x<=DOMAIN.end.x and p.y>=DOMAIN.position.y and p.y<=DOMAIN.end.y and expected>-.025:
			var road: Vector2=_distance(p,rf_road_buckets)
			var road_weight: float=1. if is_inf(road.x) else smoothstep(road.y+136.,road.y+776.,road.x)
			var edge: float=minf(minf(p.x-DOMAIN.position.x,DOMAIN.end.x-p.x),DOMAIN.end.y-p.y)
			var weight: float=road_weight*smoothstep(144.,784.,_bank(p))*_rf_physical_weight(p)*smoothstep(0.,96.,edge)
			if weight!=0.:
				var delta: float=0.
				var original_road: Vector2=_distance(p,original_road_buckets,256.)
				for mass: Dictionary in MASSES: delta+=_natural_mass(p,mass)-_old_mass(p,mass,original_road)
				expected=PackedFloat32Array([expected+delta*weight])[0]
		if expected!=new_height[i] or (old_height[i]>-.025)!=(new_height[i]>-.025): recipe_exact=false; break
		if new_height[i]!=old_height[i]: changed[i]=true
	_check(recipe_exact and not changed.is_empty() and changed.size()==int(audit.get("changed_nodes",-1)),"ALL RF nodes independent finite two-mass/protection formula exact Float32, not report counters")
	if not errors.is_empty(): return result()
	_mesh(changed)
	_selector(changed)
	_transition_measurement(changed,audit)
	records["RF"]={"nodes":new_height.size(),"changed_nodes":changed.size(),"old_sha256":BASE_PINS[BASE_RF],"new_sha256":inputs.height_rf.sha256,"complete":recipe_exact}
	return result()


# Independently enumerate every triangle, not a helper's reported maxima.
# Default JSON codec is applied ONLY after computing native numeric evidence.
func _transition_measurement(changed: Dictionary,audit: Dictionary) -> void:
	var bins: Array=[.25,.72,1.5,3.,6.]
	var before_bins: Array=[0,0,0,0,0,0]
	var after_bins: Array=[0,0,0,0,0,0]
	var before_max: float=0.
	var after_max: float=0.
	var increase_max: float=0.
	var flat_before: int=0
	var flat_after: int=0
	var incident_count: int=0
	var total: int=0
	var start:=Vector2i((DOMAIN.position/STEP).floor())
	var finish:=Vector2i((DOMAIN.end/STEP).ceil()).min(GRID-Vector2i(2,2))
	for y in range(start.y,finish.y+1):
		for x in range(start.x,finish.x+1):
			var cell:=Vector2i(x,y)
			var index: int=y*GRID.x+x
			var incident: bool=changed.has(index) or changed.has(index+1) or changed.has(index+GRID.x) or changed.has(index+GRID.x+1)
			var hard: bool=_rf_physical_weight(Vector2(cell*STEP))==0.
			for upper: bool in [false,true]:
				var old_grade: float=_gradient(old_height,cell,upper)
				var new_grade: float=_gradient(new_height,cell,upper)
				var old_bin: int=bins.size()
				var new_bin: int=bins.size()
				for i in bins.size():
					if old_bin==bins.size() and old_grade<bins[i]: old_bin=i
					if new_bin==bins.size() and new_grade<bins[i]: new_bin=i
				before_bins[old_bin]+=1; after_bins[new_bin]+=1
				before_max=maxf(before_max,old_grade); after_max=maxf(after_max,new_grade)
				increase_max=maxf(increase_max,new_grade-old_grade)
				if incident: incident_count+=1
				if hard and old_height[index]>=1.5 and old_grade<.025:
					flat_before+=1
					if new_grade<.025: flat_after+=1
				total+=1
	var expected: Dictionary={"identity":"ACTUAL_NATIVE_TRIANGLE_GRADIENT_AND_RETAINED_FLAT_TOP_DIAGNOSTIC_V1","domain_source_px":[DOMAIN.position.x,DOMAIN.position.y,DOMAIN.size.x,DOMAIN.size.y],"triangles":total,"changed_incident_triangles":incident_count,"grade_bin_upper_bounds":bins,"old_grade_bin_counts":before_bins,"new_grade_bin_counts":after_bins,"maximum_old_grade":before_max,"maximum_new_grade":after_max,"maximum_added_grade":increase_max,"original_protected_flat_triangles_above1_5m_grade_below_025":flat_before,"remaining_protected_flat_triangles_above1_5m_grade_below_025":flat_after,"flat_count_definition":"triangle A reference vertex in RF hard domain and old height>=1.5m; triangle gradient<.025; not an all-vertices/fullfoot proof","hard_original_RF_preserved":true,"flat_tops_not_claimed_removed":true,"visual_approved":false,"production_approved":false}
	var encoded: Variant=JSON.parse_string(JSON.stringify(expected))
	_check(_equal(audit.get("RF_transition_measurement"),encoded) and _equal(audit.get("selector",{}).get("broader_RF_soft_transition"),encoded),"all native triangles independent grade bins/maxima/retained flats exact default codec; not fullfoot or visual approval")
	_check(audit.get("two_mass_recipe")=="OLD_SEPARABLE_SHOULDERS_COMPACT_LOBES_BROAD_RF_SOFT_640_NAV_HARD_UNCHANGED_V2","explicit RF640 recipe identity, unchanged NAV hard rules")
	records["transition_measurement"]=expected

func _prepare_native_inputs(source: Dictionary,audit: Dictionary) -> bool:
	if not _prepare_original_bridge_domains(source): return false
	var revision: Dictionary=source.get("v9c_revision_evidence",{})
	var routes: Variant=revision.get("prepared_native_routes")
	var rivers: Variant=revision.get("prepared_native_rivers")
	if not _check(routes is Array and routes.size()==27 and rivers is Array and rivers.size()==3,"captured exact pre-bind native route/river inputs, not projected points used as XZ"): return false
	_check(_hash(revision.get("baseline_prepared_site_signature")) and revision.get("baseline_prepared_site_signature")==audit.get("original_site_signature"),"old RF prepare/site signature captured before derived bind")
	var route_ids: Dictionary={}
	for route: Dictionary in source.get("routes",[]): route_ids[String(route.get("id",""))]=route
	var seen: Dictionary={}
	for row: Variant in routes:
		if not _check(row is Dictionary and row.get("points") is Array and row.points.size()>=2 and route_ids.has(String(row.get("id",""))) and not seen.has(String(row.get("id",""))),"unique actual native road with captured projected counterpart"): continue
		seen[String(row.id)]=true
		var counterpart: Dictionary=route_ids[String(row.id)]
		var projected: Variant=counterpart.get("points_px")
		var width: float=float(row.get("half_width_px",NAN))
		if not _check(is_finite(width) and width>0. and projected is Array and float(counterpart.get("width_px",NAN))==width*2.,"native/prepared/projected route real width"): continue
		var exact: bool=true
		if row.id=="portal_bianzhou":
			exact=_original_bianzhou_route(source,row,counterpart)
		else:
			exact=projected.size()==row.points.size()
			if exact:
				for i in row.points.size():
					var point: Vector2=_pair(row.points[i])
					# Frozen FULL writer exports authored Y0 bridge support, not wet RF.
					var p: Vector2=point if _inside_original_bridge(point) else point-Vector2(0,_height(old_height,point)*Z_PPM)
					exact=exact and point.is_finite() and p.distance_to(_pair(projected[i]))<.01
		_check(exact,"old RF independent native→captured projected route (.01 original contract): "+String(row.id))
		_index(row,road_buckets,width+260.)
		_index(row,rf_road_buckets,width+776.)
		_index(row,original_road_buckets,160.,256.)
	var expected_rivers: Array=[{"id":"northern_river","half_width_px":112.,"raw":[Vector2(500,1550),Vector2(2000,1800),Vector2(4300,1500),Vector2(6200,1700),Vector2(8600,3000),Vector2(10900,3600),Vector2(12400,3900)]},{"id":"southern_river","half_width_px":142.,"raw":[Vector2(-150,6400),Vector2(2100,6500),Vector2(4200,7000),Vector2(6500,6100),Vector2(8300,5600),Vector2(10300,6300),Vector2(12400,6900)]},{"id":"bailu_tributary","half_width_px":74.,"raw":[Vector2(8600,3000),Vector2(9000,3700),Vector2(9700,4700),Vector2(8300,5600)]}]
	for i in expected_rivers.size():
		var expected: Dictionary=expected_rivers[i]
		var row: Variant=rivers[i]
		if not _check(row is Dictionary and row.get("id")==expected.id and float(row.get("half_width_px",NAN))==expected.half_width_px and row.get("points") is Array,"fixed independent river identity/order/width"): continue
		var control:=PackedVector2Array()
		var raw: Array=expected.raw
		for n in range(raw.size()-1):
			var a: Vector2=raw[maxi(0,n-1)]
			var b: Vector2=raw[n]
			var c: Vector2=raw[n+1]
			var d: Vector2=raw[mini(raw.size()-1,n+2)]
			var count: int=maxi(1,ceili(b.distance_to(c)/32.))
			for j in count:
				var t: float=float(j)/count
				control.append(.5*((2.*b)+(-a+c)*t+(2.*a-5.*b+4.*c-d)*t*t+(-a+3.*b-3.*c+d)*t*t*t))
		control.append(raw.back())
		var good: bool=control.size()==row.points.size()
		if good:
			for j in control.size(): good=good and control[j]==_pair(row.points[j])
		_check(good,"independent entire native river Catmull-Rom exact, not source.bank")
		_index(row,river_buckets,360.,256.)
	return errors.is_empty()

# Independent original support domains, not current metadata self-certification.
# Only these fields are bridge projection authority; resource paths may differ.
func _prepare_original_bridge_domains(source: Dictionary) -> bool:
	original_bridge_domains.clear()
	if not _check(FileAccess.get_sha256(BASE_SOURCE).to_lower()==BASE_PINS[BASE_SOURCE],"original bridge domain source SHA bound"): return false
	var original: Dictionary=_json(BASE_SOURCE)
	var baseline: Variant=original.get("structures")
	var current: Variant=source.get("structures")
	if not _check(baseline is Array and baseline.size()==5 and current is Array and current.size()==5,"exact five original/current bridge projection domains"): return false
	var seen: Dictionary={}
	for i in 5:
		var saved: Variant=current[i]
		var row: Variant=baseline[i]
		if not _check(row is Dictionary and saved is Dictionary and row.get("id")=="bridge_%02d"%i and typeof(saved.get("id"))==TYPE_STRING and saved.get("id")==row.id and not seen.has(row.id) and row.get("deck_height_m")==0. and _equal(saved.get("deck_height_m"),row.get("deck_height_m")) and _equal(saved.get("source_deck_polygon"),row.get("source_deck_polygon")),"original/current exact bridge identity/Y0/domain:"+str(i)): return false
		seen[row.id]=true
		var raw: Variant=row.get("source_deck_polygon")
		if not _check(raw is Array and raw.size()==4,"four actual original bridge domain corners:"+str(i)): return false
		var polygon:=PackedVector2Array()
		for value: Variant in raw:
			var p: Vector2=_pair(value)
			if not _check(p.is_finite(),"finite original bridge domain corner"): return false
			polygon.append(p)
		original_bridge_domains.append(polygon)
	return true

func _inside_original_bridge(p: Vector2) -> bool:
	for polygon: PackedVector2Array in original_bridge_domains:
		if Geometry2D.is_point_in_polygon(p,polygon): return true
	return false

func _original_rf_projection(p: Vector2) -> Vector2:
	# Match original project's expression: only final Vector2 is Float32.
	return Vector2(p.x,p.y-_height(old_height,p)*Z_PPM)

func _original_inverse_world_point(world: Vector2) -> Vector2:
	if _inside_original_bridge(world): return world
	var low: float=maxf(0.,world.y-512.)
	var high: float=minf(SIZE.y,world.y+512.)
	if _original_rf_projection(Vector2(world.x,low)).y>world.y or _original_rf_projection(Vector2(world.x,high)).y<world.y: return Vector2(INF,INF)
	for iteration in 32:
		var middle: float=(low+high)*.5
		if _original_rf_projection(Vector2(world.x,middle)).y<world.y: low=middle
		else: high=middle
	var result:=Vector2(world.x,(low+high)*.5)
	return result if _original_rf_projection(result).distance_to(world)<=.001 else Vector2(INF,INF)

func _original_bianzhou_route(source: Dictionary,row: Dictionary,counterpart: Dictionary) -> bool:
	# Original writer stores five WORLD bends, but uses 4px inverse-RF samples
	# for its native road input. Never replace the 149 native bucket points by 5.
	var world:=PackedVector2Array([Vector2(7600,2340),Vector2(7840,2295),Vector2(7840,2230),Vector2(7600,2230),_original_rf_projection(Vector2(7600,2200))])
	var bends: Array=[]
	for p: Vector2 in world: bends.append([p.x,p.y])
	var evidence: Variant=source.get("v7_revision_evidence")
	if not _check(evidence is Dictionary and _equal(counterpart.get("points_px"),JSON.parse_string(JSON.stringify(bends))) and _equal(evidence.get("bianzhou_projected_world_approach"),JSON.parse_string(JSON.stringify(bends))),"independent original fixed five Bianzhou world bends/default writer"): return false
	var expected_points: Array=[]
	var expected_records: Array=[]
	for segment in range(world.size()-1):
		var a: Vector2=world[segment]
		var b: Vector2=world[segment+1]
		var steps: int=maxi(1,ceili(a.distance_to(b)/4.))
		for n in range(steps+1):
			if segment>0 and n==0: continue
			var sampled: Vector2=a.lerp(b,float(n)/steps)
			var native: Vector2=_original_inverse_world_point(sampled)
			if not _check(native.is_finite(),"independent original32-step Bianzhou RF inverse finite"): return false
			var projected: Vector2=_original_rf_projection(native)
			expected_points.append([native.x,native.y])
			expected_records.append({"world_px":[sampled.x,sampled.y],"source_XZ_px":[native.x,native.y],"projected_RF_px":[projected.x,projected.y],"bridge_deck_Y0":_inside_original_bridge(native) or _height(old_height,native)==0.})
	return _check(expected_points.size()==149 and _equal(row.get("points"),JSON.parse_string(JSON.stringify(expected_points))) and _equal(evidence.get("inverse_RF_records"),JSON.parse_string(JSON.stringify(expected_records))),"all149 native points/4px samples/32-step inverse/RF projection/bridge flags exact original writer")

func _index(row: Dictionary,buckets: Dictionary,padding: float,bucket: float=128.) -> void:
	for i in range(row.points.size()-1):
		var a: Vector2=_pair(row.points[i])
		var b: Vector2=_pair(row.points[i+1])
		var rect: Rect2=Rect2(a,Vector2.ZERO).expand(b).grow(padding)
		for y in range(floori(rect.position.y/bucket),floori(rect.end.y/bucket)+1):
			for x in range(floori(rect.position.x/bucket),floori(rect.end.x/bucket)+1):
				var key:=Vector2i(x,y)
				if not buckets.has(key): buckets[key]=[]
				buckets[key].append({"a":a,"b":b,"width":float(row.half_width_px)})

func _distance(p: Vector2,buckets: Dictionary,bucket: float=128.) -> Vector2:
	var distance: float=INF
	var width: float=48.
	for line: Dictionary in buckets.get(Vector2i((p/bucket).floor()),[]):
		var delta: Vector2=line.b-line.a
		var actual: float=p.distance_to(line.a+delta*clampf((p-line.a).dot(delta)/maxf(delta.length_squared(),.000001),0.,1.))
		if actual<distance: distance=actual; width=line.width
	return Vector2(distance,width)

func _bank(p: Vector2) -> float:
	var river: float=INF
	for line: Dictionary in river_buckets.get(Vector2i((p/256.).floor()),[]):
		var delta: Vector2=line.b-line.a
		river=minf(river,p.distance_to(line.a+delta*clampf((p-line.a).dot(delta)/maxf(delta.length_squared(),.000001),0.,1.))-float(line.width))
	return minf(river,12140.-120.*sin(p.y/1100.)-55.*sin(p.y/370.)-p.x)

func _protect(rect: Rect2) -> void:
	var guarded: Rect2=rect.grow(24.)
	var index: int=protected_shapes.size()
	protected_shapes.append(guarded)
	var soft: Rect2=guarded.grow(80.)
	for y in range(floori(soft.position.y/128.),floori(soft.end.y/128.)+1):
		for x in range(floori(soft.position.x/128.),floori(soft.end.x/128.)+1):
			var key:=Vector2i(x,y)
			if not physical_buckets.has(key): physical_buckets[key]=[]
			physical_buckets[key].append(index)
	# RF has its own complete-triangle support halo; NAV keeps the original rect.
	var rf_rect: Rect2=guarded.grow(16.)
	var rf_index: int=rf_protected_shapes.size()
	rf_protected_shapes.append(rf_rect)
	var rf_soft: Rect2=rf_rect.grow(640.)
	for y in range(floori(rf_soft.position.y/128.),floori(rf_soft.end.y/128.)+1):
		for x in range(floori(rf_soft.position.x/128.),floori(rf_soft.end.x/128.)+1):
			var key:=Vector2i(x,y)
			if not rf_physical_buckets.has(key): rf_physical_buckets[key]=[]
			rf_physical_buckets[key].append(rf_index)

func _rf_physical_weight(p: Vector2) -> float:
	var weight: float=1.
	for index: int in rf_physical_buckets.get(Vector2i((p/128.).floor()),[]):
		var rect: Rect2=rf_protected_shapes[index]
		weight=minf(weight,smoothstep(0.,640.,p.distance_to(p.clamp(rect.position,rect.end))))
	return weight

func _physical_weight(p: Vector2) -> float:
	var weight: float=1.
	for index: int in physical_buckets.get(Vector2i((p/128.).floor()),[]):
		var rect: Rect2=protected_shapes[index]
		weight=minf(weight,smoothstep(0.,80.,p.distance_to(p.clamp(rect.position,rect.end))))
	return weight

func _support_and_protection(original: Dictionary,audit: Dictionary) -> bool:
	var portals: Dictionary={}
	for row: Dictionary in original.get("portals",[]):
		var foot: Vector2=_pair(row.get("source_XZ_foot_px"))
		portals[String(row.compound_id)]=foot
		_protect(Rect2(foot-Vector2(64,64),Vector2(128,208)))
	var objects: Variant=original.get("objects")
	if not _check(objects is Array and objects.size()==2687 and portals.size()==16,"immutable all2687 original bodies and16 doors"): return false
	var families: Dictionary={}
	var ids: Dictionary={}
	var old_bytes: PackedByteArray=old_height.to_byte_array()
	var fresh_bytes: PackedByteArray=new_height.to_byte_array()
	var rows: Array=[]
	for obj: Dictionary in objects:
		var id: String=String(obj.get("id",""))
		if not _check(not id.is_empty() and not ids.has(id),"unique protected original ID: "+id): continue
		ids[id]=true
		var foot: Vector2=_pair(obj.get("source_XZ_foot_px"))
		var world: Vector2=_pair(obj.get("world_foot_px"))
		var family: String=""
		if obj.get("role")=="independent_generated_compound":
			family="compound_measured_solids"
			foot=portals.get(id,Vector2(INF,INF))
			for raw: Array in obj.get("solid_polygons_px",[]):
				if not _check(raw.size()>=3,"original complete measured solid polygon: "+id): continue
				var rect:=Rect2(_pair(raw[0])+Vector2(0,foot.y-world.y),Vector2.ZERO)
				for point: Variant in raw: rect=rect.expand(_pair(point)+Vector2(0,foot.y-world.y))
				_protect(rect)
		elif String(obj.get("role","")).begins_with("bridge_"):
			family=String(obj.role)+"_actual_bounds"
			var bounds: Variant=obj.get("actual_used_world_bounds_m")
			if not _check(bounds is Array and bounds.size()==2 and obj.get("deck_height_m")==0,"actual Y0 bridge bounds: "+id): continue
			var low: Vector3=_vector(bounds[0])
			var high: Vector3=_vector(bounds[1])
			var a:=Vector2(low.x*PPM+SIZE.x*.5,low.z*Z_PPM+SIZE.y*.5)
			var b:=Vector2(high.x*PPM+SIZE.x*.5,high.z*Z_PPM+SIZE.y*.5)
			_protect(Rect2(a,b-a))
			foot=world
		elif obj.get("kind")=="boulder":
			family="boulder_actual_fullxz"
			var r: Variant=obj.get("source_fullxz_rect_px")
			if not _check(r is Array and r.size()==4 and obj.get("blocking")==true,"actual blocking fullXZ boulder: "+id): continue
			_protect(Rect2(Vector2(r[0],r[1]),Vector2(r[2],r[3])))
		elif obj.get("kind") in ["tree","bamboo"]:
			family=String(obj.kind)+"_actual_collider"
			var size: Vector2=_pair(obj.get("collision_size_px"))
			var center: Vector2=_pair(obj.get("collision_center_world_px",obj.get("world_foot_px")))
			if not _check(size.is_finite() and size.x>0 and size.y>0 and obj.get("blocking")==true,"actual ordinary source collider: "+id): continue
			_protect(Rect2(center+Vector2(0,foot.y-world.y)-size*.5,size))
		elif obj.get("kind")=="herb":
			family="herb_nonblocking_render_and_native_support"
			if not _check(obj.get("blocking")==false and _pair(obj.get("collision_size_px"))==Vector2.ZERO,"nonblocking herb has no invented collider: "+id): continue
			var proto: Variant=obj.get("prototype_actual_sourcebody_evidence")
			if not _check(proto is Dictionary,"actual herb prototype source"): continue
			var transform: Variant=obj.get("actual_model_transform")
			if not _check(transform is Dictionary and transform.get("basis_columns") is Array and transform.basis_columns.size()==3 and proto.get("basis_columns") is Array and proto.basis_columns.size()==3,"actual herb instance and prototype Basis families"): continue
			var same_basis: bool=true
			for column in 3: same_basis=same_basis and _vector(transform.basis_columns[column])==_vector(proto.basis_columns[column])
			if not _check(same_basis,"actual herb instance Basis equals source pose, not inferred footprint"): continue
			var native: Dictionary=_native_bounds(proto)
			if native.is_empty(): continue
			var size: Vector2=_pair(obj.get("render_size_px"))
			var uv: Vector2=_pair(obj.get("foot_uv"))
			var low: Vector3=native.low
			var high: Vector3=native.high
			var support: Vector3=native.support
			_protect(Rect2(foot-uv*size,size))
			_protect(Rect2(foot+Vector2((low.x-support.x)*PPM,(low.z-support.z)*Z_PPM),Vector2((high.x-low.x)*PPM,(high.z-low.z)*Z_PPM)))
		else:
			_check(false,"unknown original protection family: "+id)
			continue
		families[family]=int(families.get(family,0))+1
		if not _check(foot.is_finite() and Rect2(Vector2.ZERO,SIZE).has_point(foot),"original support literal domain: "+id): continue
		_protect(Rect2(foot-Vector2(18,14),Vector2(36,28)))
		var cell:=Vector2i((foot/STEP).floor()).clamp(Vector2i.ZERO,GRID-Vector2i(2,2))
		var corners: Array=[cell.y*GRID.x+cell.x,cell.y*GRID.x+cell.x+1,(cell.y+1)*GRID.x+cell.x,(cell.y+1)*GRID.x+cell.x+1]
		var exact: bool=true
		for index: int in corners: exact=exact and old_bytes.slice(index*4,index*4+4)==fresh_bytes.slice(index*4,index*4+4)
		_check(exact,"all four actual RF Float32 support bytes frozen: "+id)
		rows.append({"id":id,"source_foot_px":[foot.x,foot.y],"indices":corners})
	var recorded: Variant=audit.get("object_support")
	_check(_equal(families,EXPECTED_FAMILIES) and rows.size()==2687,"independent all8 protection families count and full support row domain")
	# This field crosses native Vector2 -> default JSON; replay that exact codec,
	# never add epsilon or alter the independently checked four RF byte slices.
	var saved_rows_expected: Variant=JSON.parse_string(JSON.stringify(rows))
	_check(recorded is Dictionary and _equal(recorded.get("protected_support_rows"),saved_rows_expected) and _equal(recorded.get("protection_family_counts"),families),"report support IDs/corners equal independent original body reconstruction/default JSON codec")
	records["support"]={"families":families,"objects":rows.size(),"corners":rows.size()*4,"original_support_row_sha256":_sha(JSON.stringify(rows).to_utf8_buffer()),"herb_physical_collision_invented":false}
	return errors.is_empty()

# These are independent raw-source controls, not production factory results.
# The immutable v5 writer records exactly VERTEX/NORMAL/UV/INDEX, while native
# ArrayMesh also stores TANGENT. All thirteen native slots remain exact against
# original GLTF -> one add_surface_from_arrays, independently of those four SHAs.
func _herb_pin(path: String,sha: String) -> bool:
	if herb_input_pins.has(path):
		return _check(herb_input_pins[path]==sha,"same-run herb input identity cannot change: "+path)
	if not _check(_hash(sha) and FileAccess.get_sha256(path)==sha,"independent original herb input bytes: "+path): return false
	herb_input_pins[path]=sha
	return true

func _herb_inputs_unchanged() -> void:
	for path: String in herb_input_pins:
		_check(FileAccess.get_sha256(path)==herb_input_pins[path],"independent herb input final bytes: "+path)

func _herb_collect(node: Node,found: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D: found.append(node as MeshInstance3D)
	for child: Node in node.get_children(): _herb_collect(child,found)

func _herb_control(proto: Dictionary) -> ArrayMesh:
	var pose_value: Variant=proto.get("pose")
	if not _check(typeof(pose_value) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(pose_value)) and float(pose_value)==floor(float(pose_value)) and float(pose_value)>=0. and float(pose_value)<=2.,"original herb exact pose0/1/2"): return null
	var pose: int=int(pose_value)
	var key: String="native_herb"+str(pose)
	var path: Variant=proto.get("actual_draw_mesh_path")
	var metadata_path: Variant=proto.get("metadata_path")
	var prefix8: String="res://art/maps/world_map_v15_complete_v8/prototypes/"
	var prefix5: String="res://art/maps/world_map_v15_complete_v5/prototypes/"
	if not _check(typeof(path)==TYPE_STRING and typeof(metadata_path)==TYPE_STRING and path in [prefix8+key+"_actual_draw_mesh.res",ROOT+"prototypes/"+key+"_actual_draw_mesh.res"],"exact original/current herb pose artifact path"): return null
	var prefix: String=path.get_base_dir()+"/"
	if not _check(metadata_path==prefix+key+".json","exact same-domain herb metadata path"): return null
	for input_path: String in HERB_SOURCE_PINS:
		if not _herb_pin(input_path,HERB_SOURCE_PINS[input_path]): return null
	if not _herb_pin(BASE_SOURCE,BASE_PINS[BASE_SOURCE]): return null
	var original_path: String=prefix5+key+".json"
	if not _herb_pin(original_path,HERB_ORIGINAL_META_SHA[pose]): return null
	if not _herb_pin(metadata_path,HERB_V8_META_SHA[pose] if prefix==prefix8 else HERB_CURRENT_META_SHA[pose]): return null
	if not _herb_pin(prefix+key+"_original_metadata.json",HERB_ORIGINAL_META_SHA[pose]): return null
	var original: Dictionary=_json(original_path)
	for field: String in ["kind","pose","basis_columns","draw_mesh_source","draw_mesh_source_sha256","actual_draw_mesh_sha256"]:
		if not _check(_equal(proto.get(field),original.get(field)),"independent original herb metadata selection: "+field): return null
	if not _check(typeof(proto.get("draw_mesh_source"))==TYPE_STRING and proto.draw_mesh_source==HERB_RAW and proto.get("draw_mesh_source_sha256")==HERB_SOURCE_PINS[HERB_RAW],"exact original herb raw GLTF binding"): return null
	var origin: Variant=proto.get("sourcebody_capture_origin")
	if not _check(origin is Dictionary and _equal(origin.get("original_metadata_path"),original_path) and _equal(origin.get("original_metadata_copy_path"),prefix+key+"_original_metadata.json") and _equal(origin.get("original_metadata_sha256"),HERB_ORIGINAL_META_SHA[pose]) and _equal(origin.get("actual_GPU_loaded_mesh_path"),prefix5+key+"_actual_draw_mesh.res") and _equal(origin.get("actual_GPU_loaded_mesh_sha256"),original.get("actual_draw_mesh_sha256")) and typeof(origin.get("new_mesh_artifact_is_exact_copy"))==TYPE_BOOL and origin.new_mesh_artifact_is_exact_copy==true,"exact original herb mesh-copy provenance"): return null
	if not _herb_pin(path,String(original.actual_draw_mesh_sha256)): return null
	if herb_controls.has(pose): return herb_controls[pose] as ArrayMesh
	var document:=GLTFDocument.new()
	var state:=GLTFState.new()
	if not _check(document.append_from_file(HERB_RAW,state)==OK,"independent original herb raw GLTF import"): return null
	var scene: Node=document.generate_scene(state)
	if not _check(scene!=null,"independent original herb owned scene"): return null
	var nodes: Array[MeshInstance3D]=[]
	_herb_collect(scene,nodes)
	if not _check(nodes.size()==4,"independent original herb four DFS variants"):
		nodes.clear()
		scene.free()
		return null
	for selected in 3:
		var raw: ArrayMesh=nodes[selected].mesh as ArrayMesh
		if not _check(raw!=null and raw.get_surface_count()>0,"original herb selected raw ArrayMesh:"+str(selected)): continue
		var control:=ArrayMesh.new()
		for sid in raw.get_surface_count():
			control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,raw.surface_get_arrays(sid))
		herb_controls[selected]=control
	nodes.clear()
	scene.free()
	return herb_controls.get(pose) as ArrayMesh

func _herb_surface_arrays(arrays: Array,expected: Array,actual_format: int,expected_format: int,primitive: int,row: Variant,sid: int) -> bool:
	var before: int=errors.size()
	if not _check(arrays.size()==Mesh.ARRAY_MAX and expected.size()==Mesh.ARRAY_MAX,"actual herb complete thirteen-slot domains"): return false
	if not _check(row is Dictionary and _equal(row.get("surface_index"),sid) and row.get("draw_arrays_sha256") is Dictionary,"actual herb surface ordinal and original four-array record"): return false
	var hashes: Dictionary=row.draw_arrays_sha256
	var keys: Array=["0","1","4","12"]
	var exact_keys: bool=hashes.size()==keys.size()
	for key: String in keys: exact_keys=exact_keys and hashes.has(key)
	if not _check(exact_keys,"actual herb writer exact four recorded array keys"): return false
	_check(actual_format==expected_format and _equal(row.get("native_surface_format"),actual_format),"actual herb independent native format exact")
	_check(primitive==Mesh.PRIMITIVE_TRIANGLES,"actual indexed herb triangle domain")
	for slot in Mesh.ARRAY_MAX:
		_check(_same_slot(arrays[slot],expected[slot]),"actual herb all thirteen native slot types/bytes exact:"+str(sid)+"/"+str(slot))
	for key: String in keys:
		var slot: int=int(key)
		var value: Variant=arrays[slot]
		# A malformed slot is rejected by native type first; never invoke arbitrary
		# Variant methods merely because a mutated record names that slot.
		var same_type: bool=value!=null and typeof(value)==typeof(expected[slot])
		_check(same_type and _hash(hashes[key]) and hashes[key]==_sha(value.to_byte_array()),"independent actual used-source array byte SHA: "+str(sid)+"/"+key)
	return errors.size()==before

func _native_bounds(proto: Dictionary) -> Dictionary:
	var before: int=errors.size()
	var path: String=String(proto.get("actual_draw_mesh_path",""))
	var columns: Variant=proto.get("basis_columns")
	if not _check(columns is Array and columns.size()==3 and _hash(proto.get("actual_draw_mesh_sha256")) and FileAccess.get_sha256(path)==proto.get("actual_draw_mesh_sha256"),"actual herb saved mesh/Basis SHA"): return {}
	# All consumed prototype fields participate in this per-run cache identity.
	# A same-path record mutation cannot inherit an earlier successful validation.
	var key: String=_sha(var_to_bytes([path,columns,proto.get("kind"),proto.get("pose"),proto.get("metadata_path"),proto.get("actual_draw_mesh_sha256"),proto.get("actual_surfaces"),proto.get("draw_mesh_source"),proto.get("draw_mesh_source_sha256"),proto.get("sourcebody_capture_origin"),proto.get("used_vertex_bounds_m"),proto.get("support_m")]))
	if native_cache.has(key): return native_cache[key]
	var control: ArrayMesh=_herb_control(proto)
	if control==null: return {}
	var basis:=Basis(_vector(columns[0]),_vector(columns[1]),_vector(columns[2]))
	var mesh: ArrayMesh=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var surface_rows: Variant=proto.get("actual_surfaces")
	if not _check(mesh!=null and basis.determinant()!=0. and surface_rows is Array and mesh.get_surface_count()==surface_rows.size() and mesh.get_surface_count()==control.get_surface_count() and not surface_rows.is_empty(),"actual herb native mesh/surface records with nondegenerate Basis"): return {}
	var low:=Vector3(INF,INF,INF)
	var high:=Vector3(-INF,-INF,-INF)
	var points:=PackedVector3Array()
	for sid in mesh.get_surface_count():
		var arrays: Array=mesh.surface_get_arrays(sid)
		var row: Variant=surface_rows[sid]
		if not _herb_surface_arrays(arrays,control.surface_get_arrays(sid),mesh.surface_get_format(sid),control.surface_get_format(sid),mesh.surface_get_primitive_type(sid),row,sid): return {}
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var seen: Dictionary={}
		if not _check(mesh.surface_get_primitive_type(sid)==Mesh.PRIMITIVE_TRIANGLES and not indices.is_empty() and indices.size()%3==0,"actual indexed herb triangle domain"): continue
		for index: int in indices:
			if not _check(index>=0 and index<vertices.size(),"actual herb used-index range"): continue
			if seen.has(index): continue
			seen[index]=true
			var p: Vector3=basis*vertices[index]
			points.append(p); low=low.min(p); high=high.max(p)
	var sum: float=0.
	var front: float=-INF
	var count: int=0
	for p: Vector3 in points:
		if p.y<=low.y+(high.y-low.y)*.02: sum+=p.x; front=maxf(front,p.z); count+=1
	if not _check(count>0,"actual herb lowest2% support used vertices"): return {}
	var support:=Vector3(sum/count,low.y,front)
	var saved: Variant=proto.get("used_vertex_bounds_m")
	_check(saved is Array and saved.size()==2 and low==_vector(saved[0]) and high==_vector(saved[1]) and support==_vector(proto.get("support_m")),"actual herb native used-bounds/support exact, no metadata-self-certification")
	mesh=null
	if errors.size()!=before: return {}
	native_cache[key]={"low":low,"high":high,"support":support}
	return native_cache[key]

func _old_mass(p: Vector2,mass: Dictionary,road: Vector2) -> float:
	var q: Vector2=(p-mass.center)/mass.radius
	var protect: float=1. if is_inf(road.x) else smoothstep(road.y+90.,road.y+260.,road.x)
	return mass.height*(1.-smoothstep(.40,1.25,absf(q.x)))*smoothstep(-1.45,-.40,q.y)*(1.-smoothstep(mass.front,.72,q.y))*(.45+.55*(1.-smoothstep(-.03,.23,q.y+.13*q.x)))*(1.-.30*exp(-pow((q.x-.33)/.17,2.))*smoothstep(-.6,.5,q.y))*protect

func _natural_mass(p: Vector2,mass: Dictionary) -> float:
	var delta: Vector2=p-mass.center
	var rotated: Vector2=delta.rotated(-float(mass.angle))
	var q: Vector2=rotated/mass.radius
	var envelope: float=1.-smoothstep(1.35,1.90,q.length())
	var main: float=exp(-(q.x*q.x*.95+q.y*q.y*1.8))
	var minor: float=exp(-((q.x+.42)*(q.x+.42)*3.4+(q.y-.26)*(q.y-.26)*4.6))
	return float(mass.height)*envelope*(.58*main+.20*minor)

func _same_slot(a: Variant,b: Variant) -> bool:
	if a==null or b==null: return a==null and b==null
	return typeof(a)==typeof(b) and a.to_byte_array()==b.to_byte_array()

func _mesh(changed: Dictionary) -> void:
	var old: ArrayMesh=ResourceLoader.load(BASE_MESH,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var actual: ArrayMesh=ResourceLoader.load(String(inputs.terrain_mesh.path),"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if not _check(old!=null and actual!=null and old.get_surface_count()==1 and actual.get_surface_count()==1 and old.surface_get_primitive_type(0)==Mesh.PRIMITIVE_TRIANGLES and actual.surface_get_primitive_type(0)==Mesh.PRIMITIVE_TRIANGLES,"two actual triangle ArrayMesh domains"): return
	var arrays: Array=old.surface_get_arrays(0)
	if not _check(arrays.size()==Mesh.ARRAY_MAX and arrays[Mesh.ARRAY_VERTEX] is PackedVector3Array and arrays[Mesh.ARRAY_NORMAL] is PackedVector3Array and arrays[Mesh.ARRAY_INDEX] is PackedInt32Array and arrays[Mesh.ARRAY_TANGENT] is PackedFloat32Array,"actual native control slot types, including semantic tangent input"): return
	var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX].duplicate()
	var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL].duplicate()
	var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
	if not _check(vertices.size()==old_height.size() and normals.size()==vertices.size() and indices.size()==(GRID.x-1)*(GRID.y-1)*6 and arrays[Mesh.ARRAY_TANGENT].size()==vertices.size()*4,"actual full baseline native lattice slots/counts"): return
	var affected: Dictionary={}
	for index: int in changed:
		vertices[index].y=new_height[index]
		var c:=Vector2i(index%GRID.x,index/GRID.x)
		for y in range(maxi(0,c.y-1),mini(GRID.y,c.y+2)):
			for x in range(maxi(0,c.x-1),mini(GRID.x,c.x+2)): affected[y*GRID.x+x]=true
	for index: int in affected:
		var c:=Vector2i(index%GRID.x,index/GRID.x)
		var sum:=Vector3.ZERO
		for y in range(maxi(0,c.y-1),mini(GRID.y-1,c.y+1)):
			for x in range(maxi(0,c.x-1),mini(GRID.x-1,c.x+1)):
				var start: int=(y*(GRID.x-1)+x)*6
				for n in 2:
					var a: int=indices[start+n*3]
					var b: int=indices[start+n*3+1]
					var d: int=indices[start+n*3+2]
					if index not in [a,b,d]: continue
					var area: Vector3=(vertices[d]-vertices[a]).cross(vertices[b]-vertices[a])
					if area.y<0.: area=-area
					sum+=area
		if not _check(sum.is_finite() and sum.length_squared()>0.,"nondegenerate independently summed incident triangles"): return
		normals[index]=sum.normalized()
	# Independent A: unmodified packed input roundtrip. B: new normals/OLD
	# vertices/unchanged tangent semantic input. C: new Y/new normals/OLD tangent.
	# No claim that old packed TBN survives native re-encoding byte-for-byte.
	var a_control:=ArrayMesh.new()
	a_control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var b_input: Array=arrays.duplicate(true)
	b_input[Mesh.ARRAY_NORMAL]=normals
	var b_control:=ArrayMesh.new()
	b_control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,b_input)
	var c_input: Array=b_input.duplicate(true)
	c_input[Mesh.ARRAY_VERTEX]=vertices
	var c_control:=ArrayMesh.new()
	c_control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,c_input)
	if not _check(a_control.get_surface_count()==1 and b_control.get_surface_count()==1 and c_control.get_surface_count()==1,"independent actual native A/B/C packing controls"): return
	var a: Array=a_control.surface_get_arrays(0)
	var b: Array=b_control.surface_get_arrays(0)
	var c: Array=c_control.surface_get_arrays(0)
	var saved: Array=actual.surface_get_arrays(0)
	_check(old.surface_get_format(0)==actual.surface_get_format(0) and old.surface_get_format(0)==a_control.surface_get_format(0) and old.surface_get_format(0)==b_control.surface_get_format(0) and old.surface_get_format(0)==c_control.surface_get_format(0),"original and all independently packed controls have exact same native format")
	var slots: Array=[]
	for slot in Mesh.ARRAY_MAX:
		_check(_same_slot(saved[slot],c[slot]),"ALL actual derived slots equal independently constructed C control: "+str(slot))
		if slot not in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_TANGENT]: _check(_same_slot(saved[slot],arrays[slot]),"original protected packed slot unchanged: "+str(slot))
		slots.append({"slot":slot,"original_sha256":_sha(arrays[slot].to_byte_array()) if arrays[slot]!=null else "NULL","A_sha256":_sha(a[slot].to_byte_array()) if a[slot]!=null else "NULL","B_sha256":_sha(b[slot].to_byte_array()) if b[slot]!=null else "NULL","C_sha256":_sha(c[slot].to_byte_array()) if c[slot]!=null else "NULL"})
	_check(_same_slot(arrays[Mesh.ARRAY_TANGENT],b_input[Mesh.ARRAY_TANGENT]) and _same_slot(arrays[Mesh.ARRAY_TANGENT],c_input[Mesh.ARRAY_TANGENT]),"old tangent semantic INPUT exact, no regeneration/omission")
	var actual_vertices: PackedVector3Array=saved[Mesh.ARRAY_VERTEX]
	var saved_normal: PackedByteArray=saved[Mesh.ARRAY_NORMAL].to_byte_array()
	var saved_tangent: PackedByteArray=saved[Mesh.ARRAY_TANGENT].to_byte_array()
	var a_normal: PackedByteArray=a[Mesh.ARRAY_NORMAL].to_byte_array()
	var a_tangent: PackedByteArray=a[Mesh.ARRAY_TANGENT].to_byte_array()
	var b_normal: PackedByteArray=b[Mesh.ARRAY_NORMAL].to_byte_array()
	var b_tangent: PackedByteArray=b[Mesh.ARRAY_TANGENT].to_byte_array()
	var exact: bool=true
	for index in vertices.size():
		exact=exact and actual_vertices[index].x==arrays[Mesh.ARRAY_VERTEX][index].x and actual_vertices[index].z==arrays[Mesh.ARRAY_VERTEX][index].z and actual_vertices[index].y==new_height[index]
		var control_normal: PackedByteArray=b_normal if affected.has(index) else a_normal
		var control_tangent: PackedByteArray=b_tangent if affected.has(index) else a_tangent
		exact=exact and saved_normal.slice(index*12,index*12+12)==control_normal.slice(index*12,index*12+12) and saved_tangent.slice(index*16,index*16+16)==control_tangent.slice(index*16,index*16+16)
	_check(exact,"every vertex XZ/RFY, affected TBN againstB, outside TBN againstA, ZERO tolerance")
	records["native_packing"]={"slots":slots,"affected_vertex_count":affected.size(),"outside_control":"A_UNMODIFIED_NATIVE_ROUNDTRIP","inside_control":"B_NEW_NORMAL_OLD_VERTEX_OLD_TANGENT_INPUT","actual_control":"C_NEW_HEIGHT_NEW_NORMAL_OLD_TANGENT_INPUT","tolerance":0,"full_array_domain":Mesh.ARRAY_MAX}
	old=null; actual=null; a_control=null; b_control=null; c_control=null

func _height(h: PackedFloat32Array,p: Vector2) -> float:
	var q: Vector2=p.clamp(Vector2.ZERO,SIZE)/STEP
	var c:=Vector2i(mini(floori(q.x),GRID.x-2),mini(floori(q.y),GRID.y-2))
	var local: Vector2=q-Vector2(c)
	var a: float=h[c.y*GRID.x+c.x]
	var b: float=h[c.y*GRID.x+c.x+1]
	var d: float=h[(c.y+1)*GRID.x+c.x]
	var e: float=h[(c.y+1)*GRID.x+c.x+1]
	return a+(b-a)*local.x+(d-a)*local.y if local.x+local.y<=1. else e+(d-e)*(1.-local.x)+(b-e)*(1.-local.y)

func _gradient(h: PackedFloat32Array,c: Vector2i,upper: bool) -> float:
	var a: float=h[c.y*GRID.x+c.x]
	var b: float=h[c.y*GRID.x+c.x+1]
	var d: float=h[(c.y+1)*GRID.x+c.x]
	var e: float=h[(c.y+1)*GRID.x+c.x+1]
	return Vector2((e-d if upper else b-a)*PPM/STEP,(e-b if upper else d-a)*Z_PPM/STEP).length()

func _cell(h: PackedFloat32Array,p: Vector2) -> Vector3i:
	var c:=Vector2i((p/STEP).floor()).clamp(Vector2i.ZERO,GRID-Vector2i(2,2))
	var local: Vector2=(p-Vector2(c*STEP))/STEP
	var grade: float=0.
	if local.x+local.y<=1.: grade=maxf(grade,_gradient(h,c,false))
	if local.x+local.y+.5>=1.: grade=maxf(grade,_gradient(h,c,true))
	var low: float=INF
	var bank: float=INF
	for offset: Vector2 in [Vector2.ZERO,Vector2(2,0),Vector2(0,2),Vector2(2,2),Vector2(1,1)]: low=minf(low,_height(h,p+offset)); bank=minf(bank,_bank(p+offset))
	return Vector3i(255 if low>-.025 else 0,0,255 if low>-.025 and bank>28. and grade<.72 else 0)

func _selector(changed: Dictionary) -> void:
	var old: Image=Image.load_from_file(BASE_SELECTOR)
	var fresh: Image=Image.load_from_file(String(inputs.source_topology.path))
	if not _check(old!=null and fresh!=null and old.get_size()==Vector2i(6144,4096) and fresh.get_size()==old.get_size() and old.get_format()==Image.FORMAT_RGB8 and fresh.get_format()==Image.FORMAT_RGB8 and not old.has_mipmaps() and not fresh.has_mipmaps(),"actual full selector original RGB8/native2px canvases"): return
	var low:=GRID
	var high:=Vector2i.ZERO
	for index: int in changed:
		var c:=Vector2i(index%GRID.x,index/GRID.x)
		low=low.min(c); high=high.max(c)
	var start: Vector2i=((low-Vector2i.ONE)*4).max(Vector2i.ZERO)
	var end: Vector2i=((high+Vector2i.ONE)*4).min(old.get_size()-Vector2i.ONE)
	var original: PackedByteArray=old.get_data()
	var actual: PackedByteArray=fresh.get_data()
	var good: bool=true
	var nav_changes: int=0
	for y in old.get_height():
		var row_start: int=y*old.get_width()*3
		if y<start.y or y>end.y:
			good=good and original.slice(row_start,row_start+old.get_width()*3)==actual.slice(row_start,row_start+old.get_width()*3)
			continue
		good=good and original.slice(row_start,row_start+start.x*3)==actual.slice(row_start,row_start+start.x*3) and original.slice(row_start+(end.x+1)*3,row_start+old.get_width()*3)==actual.slice(row_start+(end.x+1)*3,row_start+old.get_width()*3)
		for x in range(start.x,end.x+1):
			var at: int=(y*old.get_width()+x)*3
			var p:=Vector2(x,y)*2.
			var previous: Vector3i=_cell(old_height,p)
			var expected: Vector3i=_cell(new_height,p)
			good=good and original[at]==previous.x and original[at+1]==previous.y and original[at+2]==previous.z and actual[at]==expected.x and actual[at+1]==expected.y and actual[at+2]==expected.z and previous.x==expected.x
			if previous.z!=expected.z:
				nav_changes+=1
				var road: Vector2=_distance(p,road_buckets)
				good=good and _physical_weight(p)!=0. and road.x>road.y+120. and _bank(p)>128.
	_check(good,"ALL selector bytes: outside unchanged; inside independent ALL-intersected triangles/shore/height; protected NAV exact")
	records["selector"]={"canvas":[6144,4096],"step_px":2,"recomputed_cell_count":(end.x-start.x+1)*(end.y-start.y+1),"nonprotected_NAV_changes":nav_changes,"all_canvas_bytes_checked":true,"old_NAV_unchanged_claim":false,"zero_tolerance":true}
	old=null; fresh=null

func result() -> Dictionary:
	_herb_inputs_unchanged()
	return {"scope":"INDEPENDENT_V9C_CPU_INPUT_AND_SAVED_DERIVED_GEOMETRY_NOT_FIELD_FULL_OR_VISUAL_APPROVAL","checks":checks,"failed":errors.size(),"failures":errors.size(),"errors":errors.duplicate(),"complete":errors.is_empty() and not records.is_empty(),"records":records.duplicate(true),"helper_or_builder_invoked":false,"Field_input_executed":false,"visual_approved":false,"production_approved":false}

func release() -> void:
	_herb_inputs_unchanged()
	herb_controls.clear(); herb_input_pins.clear()
	original_bridge_domains.clear()
	old_height.clear(); new_height.clear(); native_cache.clear(); protected_shapes.clear()
	physical_buckets.clear()
	rf_physical_buckets.clear(); rf_protected_shapes.clear(); rf_road_buckets.clear()
	road_buckets.clear(); original_road_buckets.clear(); river_buckets.clear(); inputs.clear()
