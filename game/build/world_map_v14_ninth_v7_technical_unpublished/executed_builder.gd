extends SceneTree

# Ninth SOURCE DRAFT: self-contained native definitions, not a fifth-resource reader.
# Main/seventh active OUT and eighth source/preview remain frozen.
# New ninth capture can run only after explicit producer CPU/GPU authorization.
# No inheritance or old static output hooks. Default startup fails closed.
const OUT := "res://art/maps/world_map_v14/"
const OLD := "res://art/modules/world_map_v13/"
const SIZE := Vector2i(4608,3072)
const WORLD := Vector2(45.0,42.42640687)
const CAMERA_SIZE := 30.0
const BOULDER := "res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf"
const HERB := "res://art/external/polyhaven/shrub_03/shrub_03_1k.gltf"
const PINE := "res://art/external/polyhaven/pine_sapling_small/pine_sapling_small_1k.gltf"
const TREE := "res://art/external/polyhaven/tree_small_02/tree_small_02_1k.gltf"
const ROCKFACE := "res://art/external/polyhaven/world_native_v14_ninth/rock_face_01/rock_face_01_1k.gltf"
const NINTH := preload("res://scripts/dev/world_map_v14_ninth_native_surface.gd")
var native_surface := NINTH.new()
var pose_cache: Dictionary={}
var native_material_cache: Dictionary={}
var native_material_recipes: Array[Dictionary]=[]
const VISUAL_SSAA_SCALE := 2
var ssaa_capture_records: Array[Dictionary]=[]
var ssaa_readback_serial: int=0
var tool_cursor_release_refs: Array[Dictionary]=[]
var geometry_witness_audit: Dictionary={}
var rock_pad_specs: Array[Dictionary]=[]
var sprite_pose_cache: Dictionary={}
var road_profile_image: Image
var road_profile_texture: ImageTexture
var actual_height_image: Image
var actual_height_texture: ImageTexture
var coverage_record: Dictionary={}
const FULL_CAMERA_OFFSET := 20.0
const STAGING := "res://data/maps/world_map_jianghu_v13_staging_layout.tres"
var routes: Array[Dictionary]=[]
var objects: Array[Dictionary]=[]
var portals: Array[Dictionary]=[]
var landmarks: Array[Dictionary]=[]
var models: Array[Dictionary]=[]
var model_templates: Dictionary={}
var tree_lod_mesh: ArrayMesh
var tree_lod_recipe: Dictionary={}
var topo: Image
var topology_texture: ImageTexture
var terrain_mesh: ArrayMesh
var capture_count := 0
var surface_materials: Dictionary={}
var compiled_water_material: ShaderMaterial
var shader_gate_results: Array[Dictionary]=[]
var source_design_only:=false
var source_plan_tag: String="ninth_v7_witness_source_plan"
var bridge_decks := [Rect2(2282,1983,36,225),Rect2(1415,2838,242,24),Rect2(4057,2021,36,225)]
var bridge_centers: Array[Vector2]=[Vector2(2300,2095),Vector2(1536,2850),Vector2(4075,2133)]
var waterways: Array[Dictionary]=[]
var water_buckets: Dictionary={}
var vegetation_sites: Array[Dictionary]=[]
var route_buckets: Dictionary={}
var height_grid: PackedFloat32Array=PackedFloat32Array()
const HEIGHT_COLS := 768
const HEIGHT_ROWS := 512
const CULTIVATION_FIELDS := [[720.,1850.,140.,75.,.14,0.],[930.,1830.,105.,62.,-.21,0.],[1100.,1850.,120.,80.,.27,0.],[1470.,1510.,125.,85.,-.24,0.],[1670.,1560.,112.,78.,.20,0.],[1840.,1590.,130.,95.,-.08,0.],[2700.,1500.,120.,95.,-.12,0.],[2860.,1550.,135.,78.,.20,0.],[3230.,1870.,110.,82.,.36,1.],[3410.,1890.,123.,78.,-.20,1.],[620.,2580.,125.,82.,-.23,1.],[810.,2510.,118.,85.,.18,1.],[2260.,2380.,122.,84.,.30,1.],[2470.,2460.,125.,80.,-.16,1.],[3050.,2610.,130.,100.,-.24,2.],[3220.,2550.,112.,92.,.12,2.],[3360.,2710.,120.,85.,.30,2.],[3650.,2410.,128.,85.,-.21,2.]]
# Surveyed actual draw-vertex XZ bounds from the frozen third native capture.
# These are route design blueprints only. New models are independently rebuilt
# and must match before any export; their physical rectangles are never shrunk.
const ROCK_COLLISION_BLUEPRINTS := {
	"native_rock_west":[17.9232788,-16.7475586,134.9857483,96.6664352],
	"native_rock_foothill":[-20.5767822,-20.2344971,116.5608521,92.2815323],
	"native_rock_heartland":[5.6696777,-23.0333252,112.5080795,97.0559311],
	"native_rock_south":[15.6472168,-28.6972656,111.0449219,71.3839798],
	"native_rock_cove":[-16.1074219,-14.9323730,114.3109589,73.4834976],
	"native_cliff_south":[-25.7866211,-16.2285156,232.8038025,37.5623436]}
var component_blueprints: Dictionary={}
var native_export_root: String=OUT
var preview_entity_records: Array[Dictionary]=[]
var native_specs := [
	{"id":"native_ridge_base_0","source":BOULDER,"foot":Vector2(1830,765),"yaw":20.,"scale":.95,"variant":0,"blocking":true,"nature":"independent_rockface_base_boulder"},
	{"id":"native_ridge_base_1","source":BOULDER,"foot":Vector2(1960,815),"yaw":90.,"scale":.90,"variant":0,"blocking":true,"nature":"independent_rockface_base_boulder"},
	{"id":"native_ridge_base_2","source":BOULDER,"foot":Vector2(2095,842),"yaw":170.,"scale":1.02,"variant":0,"blocking":true,"nature":"independent_rockface_base_boulder"},
	{"id":"native_ridge_base_3","source":BOULDER,"foot":Vector2(2220,770),"yaw":245.,"scale":.84,"variant":0,"blocking":true,"nature":"independent_rockface_base_boulder"},
	{"id":"native_ridge_base_4","source":BOULDER,"foot":Vector2(2365,830),"yaw":15.,"scale":.93,"variant":0,"blocking":true,"nature":"independent_rockface_base_boulder"},
	{"id":"native_ridge_base_5","source":BOULDER,"foot":Vector2(2470,850),"yaw":120.,"scale":.85,"variant":0,"blocking":true,"nature":"independent_rockface_base_boulder"},
	{"id":"native_ridge_base_6","source":BOULDER,"foot":Vector2(1770,730),"yaw":210.,"scale":.83,"variant":0,"blocking":true,"nature":"independent_rockface_base_boulder"},
	{"id":"native_ridge_base_7","source":BOULDER,"foot":Vector2(3400,730),"yaw":300.,"scale":.90,"variant":0,"blocking":true,"nature":"independent_rockface_base_boulder"},
	{"id":"native_ridge_face_west","source":ROCKFACE,"foot":Vector2(1835,680),"yaw":18.,"scale":.60,"variant":0,"blocking":true,"nature":"licensed_rockface_solid"},
	{"id":"native_ridge_face_near","source":ROCKFACE,"foot":Vector2(2070,785),"yaw":-24.,"scale":.62,"variant":0,"blocking":true,"nature":"licensed_rockface_solid"},
	{"id":"native_ridge_face_crest","source":ROCKFACE,"foot":Vector2(2210,670),"yaw":36.,"scale":.67,"variant":0,"blocking":true,"nature":"licensed_rockface_solid"},
	{"id":"native_ridge_face_east","source":ROCKFACE,"foot":Vector2(2410,785),"yaw":-55.,"scale":.57,"variant":0,"blocking":true,"nature":"licensed_rockface_solid"},
	{"id":"native_ridge_face_pine","source":ROCKFACE,"foot":Vector2(3430,660),"yaw":62.,"scale":.54,"variant":0,"blocking":true,"nature":"licensed_rockface_solid"},
	{"id":"native_pass_face","source":ROCKFACE,"foot":Vector2(330,785),"yaw":-12.,"scale":.50,"variant":0,"blocking":true,"nature":"licensed_rockface_solid"},
	{"id":"native_rock_west","source":BOULDER,"foot":Vector2(600,1320),"yaw":35.0,"scale":.85,"variant":0,"blocking":true},
	{"id":"native_rock_foothill","source":BOULDER,"foot":Vector2(1650,1160),"yaw":-42.0,"scale":.75,"variant":0,"blocking":true},
	{"id":"native_rock_heartland","source":BOULDER,"foot":Vector2(2810,1670),"yaw":15.0,"scale":.80,"variant":0,"blocking":true},
	{"id":"native_rock_south","source":BOULDER,"foot":Vector2(2730,2690),"yaw":115.0,"scale":.68,"variant":0,"blocking":true},
	{"id":"native_rock_cove","source":BOULDER,"foot":Vector2(3970,1650),"yaw":-65.0,"scale":.70,"variant":0,"blocking":true},
	{"id":"native_cliff_south","source":"res://art/external/polyhaven/coastal_cliff_01/coastal_cliff_01_1k.gltf","foot":Vector2(3520,2930),"yaw":-8.0,"scale":.025,"variant":0,"blocking":true}]

func _initialize() -> void:
	# SOURCE DRAFT ONLY. The producer must grant the next CPU/GPU window.
	# Ordinary execution can never start a build against frozen active OUT.
	if "--ninth-local-preview" in OS.get_cmdline_user_args():
		source_design_only=true
		call_deferred("_run_ninth_local_previews")
	elif "--ninth-material-preflight" in OS.get_cmdline_user_args():
		source_design_only=true
		call_deferred("_run_ninth_preflight")
	elif "--geometry-witness-audit" in OS.get_cmdline_user_args():
		source_design_only=true
		source_plan_tag="ninth_v7_witness_only"
		call_deferred("_geometry_witness_audit_only")
	elif "--source-plan-audit" in OS.get_cmdline_user_args():
		source_design_only=true
		source_plan_tag="ninth_v7_witness_source_plan"
		call_deferred("_source_plan_audit")
	elif "--ninth-full-capture-approved" in OS.get_cmdline_user_args():
		if not "--fresh-ninth-out-confirmed" in OS.get_cmdline_user_args():
			push_error("[WorldV14NinthDraft] Producer fresh-OUT confirmation required")
			quit(1)
			return
		call_deferred("_build")
	else:
		push_error("[WorldV14NinthDraft] Frozen main/OUT: default capture rejected; explicit producer CPU/GPU window required")
		quit(1)

func _json(path: String,data: Dictionary) -> void:
	if source_design_only and path.begins_with(OUT): return
	var file:=FileAccess.open(path,FileAccess.WRITE)
	assert(file!=null,"Cannot save new v14 JSON")
	file.store_string(JSON.stringify(data,"\t"))
	file.close()

func _checked_geometry_json(path: String,data: Dictionary) -> bool:
	# Limited explicit I/O contract for witness/geometry evidence. Never asserts
	# in a child writer and then lets its caller report successful output.
	if source_design_only and path.begins_with(OUT):
		print("[V14GeometryIO] Frozen production write refused: ",path)
		return false
	var serialized: String=JSON.stringify(data,"\t")
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if file==null:
		print("[V14GeometryIO] Cannot open JSON: ",path," error=",FileAccess.get_open_error())
		return false
	file.store_string(serialized)
	file.flush()
	var write_error: Error=file.get_error()
	file.close()
	if write_error!=OK:
		print("[V14GeometryIO] JSON store failed: ",path," error=",write_error)
		return false
	if FileAccess.get_file_as_string(path)!=serialized:
		print("[V14GeometryIO] JSON readback differs: ",path)
		return false
	return true

func _source_png(image: Image,path: String) -> Error:
	return OK if source_design_only else image.save_png(path)

func _source_plan_audit() -> void:
	_prepare_contract()
	var obstacles:=_source_obstacles()
	var failures:=0
	for route in routes:
		if route["id"]=="bailu_dock_access" or String(route["id"]).ends_with("_bridge"): continue
		var bad:=0
		var points: PackedVector2Array=route["points"]
		for i in range(1,points.size()):
			if not _source_segment_clear(points[i-1],points[i],obstacles): bad+=1
		failures+=bad
		print("[V14SourcePlan] ",route["id"]," points=",points.size()," wall_or_water_segments=",bad)
	_cache_height_grid()
	_project_runtime_contract()
	# Read-only physical forecasts, never manufactured asset metadata.
	for spec in native_specs:
		if not spec["blocking"]: continue
		var foot:=projected(spec["foot"])
		var collision_size:=Vector2(12,9) if spec["source"]==PINE else Vector2(18,14)
		var collision_center:=foot+Vector2(0,-5 if spec["source"]==PINE else -8)
		if spec["source"] not in [PINE,TREE]:
			var measured: Array=component_blueprints[spec["id"]]
			collision_size=Vector2(measured[2],measured[3])
			collision_center=foot+Vector2(measured[0],measured[1])
		objects.append({"id":spec["id"],"pos":collision_center/Vector2(SIZE),"collision_size":collision_size/Vector2(SIZE)})
	var total_samples:=0
	var audit_routes: Array=[]
	for route in routes:
		var samples:=0
		var bad:=0
		var nav_bad:=0
		var max_gradient:=0.
		var nav_examples: Array=[]
		var first:=Vector2.ZERO
		var points: PackedVector2Array=route["points"]
		for i in range(1,points.size()):
			var steps:=maxi(1,ceili(projected(points[i-1]).distance_to(projected(points[i]))/4.))
			for j in range(steps+1):
				var ratio:=float(j)/steps
				var hint:=points[i-1].lerp(points[i],ratio)
				# Match the runtime JSON polyline, not a differently curved
				# projection of interpolated source centers.
				var point:=projected(points[i-1]).lerp(projected(points[i]),ratio)
				var clear:=_projected_layout_foot_clear(point)
				if not clear:
					if bad==0: first=point
					bad+=1
				var foot_nav:=_source_plan_foot_nav(point,hint.y)
				max_gradient=maxf(max_gradient,float(foot_nav["max_gradient"]))
				if not foot_nav["allowed"]:
					nav_bad+=1
					if nav_examples.size()<8: nav_examples.append(foot_nav)
				samples+=1
		total_samples+=samples
		failures+=bad+nav_bad
		print("[V14ProjectedPlan] ",route["id"]," samples=",samples," layout_fullfoot_bad=",bad," first=",first," first_entity=",_projected_layout_blocker(first) if bad>0 else "")
		print("[V14TriangleNavPlan] ",route["id"]," samples=",samples," fullfoot_bad=",nav_bad," max_gradient=",max_gradient," first=",nav_examples[0] if not nav_examples.is_empty() else {})
		var source_points: Array=[]
		for p in points: source_points.append(_pair(p))
		audit_routes.append({"id":route["id"],"samples":samples,"layout_bad":bad,"first_layout_bad":_pair(first),"first_layout_entity":_projected_layout_blocker(first) if bad>0 else "","nav_bad":nav_bad,"max_gradient":max_gradient,"first_bad_examples":nav_examples,"source_points":source_points})
	var witnesses: Array=[]
	for item in [["bailu_dry_apron",Vector2(4230,1788),true],["bailu_south_approach",Vector2(4220,1815),true],["bailu_boat_water",Vector2(4296,1744),false],["heartland_natural_water",bridge_centers[0],false],["southern_natural_water",bridge_centers[1],false],["east_natural_water",bridge_centers[2],false]]:
		var p: Vector2=item[1]
		var land:=natural_distance(p)>0.
		var allowed:=natural_distance(p)>24. and terrain_gradient(p)<.72
		var passed: bool=allowed if item[2] else (not land and terrain_height(p)<NINTH.WATER_Y-.00001)
		if not passed: failures+=1
		witnesses.append({"id":item[0],"source_point":_pair(p),"height_m":terrain_height(p),"gradient":terrain_gradient(p),"bank_distance_px":natural_distance(p),"land":land,"natural_walk":allowed,"expected_dry_walk":item[2],"passed":passed})
	var plane_bad:=0
	var deck_evidence: Array=[]
	for i in bridge_decks.size():
		var deck: Rect2=bridge_decks[i]
		var plane:=PlaneMesh.new()
		plane.size=deck.size/Vector2(SIZE)*WORLD
		var actual_arrays:=plane.surface_get_arrays(0)
		var actual_vertices: PackedVector3Array=actual_arrays[Mesh.ARRAY_VERTEX]
		var maximum_y:=0.
		for vertex in actual_vertices: maximum_y=maxf(maximum_y,absf(vertex.y))
		if maximum_y>.000001: plane_bad+=1
		var bed:=terrain_height(deck.get_center())
		var must_be_wet: bool=i<3
		if must_be_wet and bed>=NINTH.WATER_Y-.00001: plane_bad+=1
		deck_evidence.append({"id":"support_"+str(i),"kind":"bridge" if i<3 else "dock","source_rect_px":_rect(deck),"actual_native_plane_vertices":actual_vertices.size(),"actual_local_max_abs_y":maximum_y,"support_world_y_m":0.,"natural_bed_height_m":bed,"water_y_m":NINTH.WATER_Y,"must_be_natural_wet_center":must_be_wet,"natural_bed_is_underwater":bed<NINTH.WATER_Y,"forecast_not_GPU_support_capture":true})
	failures+=plane_bad
	var measured_geometry: Dictionary=_measure_geometry_witnesses()
	if measured_geometry.is_empty() or not bool(measured_geometry.get("passed",false)): failures+=1
	var result: Dictionary={"status":"CPU_SOURCE_PLAN_PASS" if failures==0 else "CPU_SOURCE_PLAN_FAIL","executed_builder_sha256":FileAccess.get_sha256(get_script().resource_path),"no_gpu_no_production_write":true,"route_sampling":"runtime projected polyline <=4px; center +16 ellipse feet; exact actual triangle inverse and 2px selector forecast, not actual GPU mask acceptance","routes":audit_routes,"witnesses":witnesses,"actual_deck_support_height_nonzero_samples":plane_bad,"deck_forecast_evidence":deck_evidence,"natural_bed_preserved_separate_from_support":true,"geometry_witness_audit":measured_geometry,"failures":failures}
	var result_saved: bool=_checked_geometry_json("res://build/world_map_v14_"+source_plan_tag+"_result.json",result)
	if not result_saved: failures+=1
	print("[V14SourcePlan] no_render_no_production_png_no_production_json=true failures=",failures," native_specs=",native_specs.size())
	print("[V14ProjectedPlan] exact_triangle_height=true total_samples=",total_samples," actual_GPU_nav_not_tested=true")
	_free_capture_model_nodes()
	_release_capture_resource_refs()
	# Headless forecast has no draw event: natural process frames only.
	for frame in 16: await process_frame
	var cursors_released: bool=_cursor_release_audit()
	quit(0 if failures==0 and cursors_released else 1)

func _source_plan_inverse(screen: Vector2,source_y_hint: float) -> Vector2:
	var lower:=maxf(0.,source_y_hint-180.)
	var upper:=minf(SIZE.y,source_y_hint+180.)
	for iteration in 24:
		var middle:=(lower+upper)*.5
		if projected(Vector2(screen.x,middle)).y<screen.y: lower=middle
		else: upper=middle
	return Vector2(screen.x,(lower+upper)*.5)

func _source_plan_foot_nav(screen: Vector2,source_y_hint: float) -> Dictionary:
	var maximum:=0.
	var first_bad: Dictionary={}
	for index in 17:
		var shoe:=screen
		if index>0:
			var angle:=TAU*(index-1)/16.
			shoe+=Vector2(cos(angle)*10.,sin(angle)*6.)
		var source:=_source_plan_inverse(shoe,source_y_hint)
		# Nearest source selector matches the actual topology source-node
		# convention. This is a forecast, not copied or hand-painted nav.
		var selector:=Vector2(floorf(source.x/2.)*2.,floorf(source.y/2.)*2.)
		var cell:=_selector_cell_info(selector)
		var gradient: float=cell["max_gradient"]
		maximum=maxf(maximum,gradient)
		var allowed: bool=terrain_height(source)>NINTH.WATER_Y and cell["allowed"]
		if not allowed:
			for deck in bridge_decks:
				if deck.has_point(shoe): allowed=true
		if not allowed and first_bad.is_empty():
			first_bad={"screen_point":_pair(screen),"shoe_point":_pair(shoe),"source_point":_pair(source),"selector_point":_pair(selector),"height_m":terrain_height(source),"gradient":gradient,"bank_distance_px":natural_distance(selector)}
	return {"allowed":first_bad.is_empty(),"max_gradient":maximum,"first_bad":first_bad}

func _projected_layout_foot_clear(point: Vector2) -> bool:
	return _projected_layout_blocker(point)==""

func _projected_layout_blocker(point: Vector2) -> String:
	for object in objects:
		if not object.has("collision_size"): continue
		var center: Vector2=(object["pos"]+object.get("collision_offset",Vector2.ZERO))*Vector2(SIZE)
		var size: Vector2=object["collision_size"]*Vector2(SIZE)
		var rect:=Rect2(center-size*.5,size).grow_individual(SIZE.x*.004,SIZE.y*.004,SIZE.x*.004,SIZE.y*.004)
		if rect.has_point(point): return String(object["id"])
		for i in 16:
			var angle:=TAU*i/16.
			if rect.has_point(point+Vector2(cos(angle)*10.,sin(angle)*6.)): return String(object["id"])
	return ""

func _fail_candidate(reason: String) -> void:
	_json(OUT+"manifest.json",{"version":"world_v14","status":"TECHNICAL_FAIL","current_outputs_not_ready":true,"production_approved":false,"reason":reason,"world_size":[4608,3072]})
	push_error("[WorldV14] fail-closed: "+reason)
	# Every callsite already returns; defer cleanup so caller resource locals
	# unwind before the isolated process drops DisplayServer/autoload handles.
	call_deferred("_finish_local_preview",1)

func _pair(v: Vector2) -> Array:
	return [v.x,v.y]

func _rect(v: Rect2) -> Array:
	return [v.position.x,v.position.y,v.size.x,v.size.y]

func _smooth(a: float,b: float,v: float) -> float:
	return smoothstep(a,b,v)

func shore_x(y: float) -> float:
	# The L-shaped quay ends in actual dirt/stone on its south side. A shorter
	# southern bay shoulder connects that dry apron without filling the boat
	# basin or claiming another white support rectangle over open water.
	var bailu_width:=lerpf(108.,82.,smoothstep(1730.,1790.,y))
	return 4355.0+55.0*sin(y/285.0)-125.0*exp(-pow((y-1290.0)/116.0,2.0))-135.0*exp(-pow((y-1730.0)/bailu_width,2.0))

func river_y(x: float) -> float:
	return 2095.0+38.0*sin((x-2300.0)/235.0)*smoothstep(110.0,350.0,absf(x-2300.0))

func _river_distance(p: Vector2) -> float:
	# Only the 0..130 px bank band affects height/material/navigation. A
	# conservative 384 px bucket apron includes every possibly relevant
	# segment; the saturated far distance is not a changed wet/dry boundary.
	var nearest:=384.0
	if not water_buckets.is_empty():
		for segment in water_buckets.get(Vector2i(floori(p.x/128.),floori(p.y/128.)),[]):
			var a: Vector2=segment[0]
			var d: Vector2=segment[1]-a
			var t:=clampf((p-a).dot(d)/maxf(d.length_squared(),.001),0.,1.)
			nearest=minf(nearest,p.distance_to(a+t*d)-lerpf(segment[2],segment[3],t))
		return nearest
	for water in waterways:
		var points: PackedVector2Array=water["points"]
		var widths: PackedFloat32Array=water["radii"]
		for i in range(1,points.size()):
			var d:=points[i]-points[i-1]
			var t:=clampf((p-points[i-1]).dot(d)/d.length_squared(),0.,1.)
			nearest=minf(nearest,p.distance_to(points[i-1]+t*d)-lerpf(widths[i-1],widths[i],t))
	return nearest

func _index_waterways() -> void:
	water_buckets.clear()
	for water in waterways:
		var points: PackedVector2Array=water["points"]
		var widths: PackedFloat32Array=water["radii"]
		for i in range(1,points.size()):
			var a:=points[i-1]
			var b:=points[i]
			var apron:=384.+maxf(widths[i-1],widths[i])
			for y in range(floori((minf(a.y,b.y)-apron)/128.),ceili((maxf(a.y,b.y)+apron)/128.)+1):
				for x in range(floori((minf(a.x,b.x)-apron)/128.),ceili((maxf(a.x,b.x)+apron)/128.)+1):
					var key:=Vector2i(x,y)
					if not water_buckets.has(key): water_buckets[key]=[]
					water_buckets[key].append([a,b,widths[i-1],widths[i]])

func _curved_waterway(id: String,knots: Array,radii: Array) -> void:
	# Catmull-Rom source curve sampled densely enough to keep natural banks
	# round at this orthographic scale. CPU, mesh, masks and shader all consume
	# these exact same segments, not independently estimated visual curves.
	var points:=PackedVector2Array()
	var widths:=PackedFloat32Array()
	for i in range(knots.size()-1):
		var p0: Vector2=knots[maxi(0,i-1)]
		var p1: Vector2=knots[i]
		var p2: Vector2=knots[i+1]
		var p3: Vector2=knots[mini(knots.size()-1,i+2)]
		var steps:=maxi(3,ceili(p1.distance_to(p2)/85.))
		for j in steps:
			var t:=float(j)/steps
			points.append(.5*((2.*p1)+(-p0+p2)*t+(2.*p0-5.*p1+4.*p2-p3)*t*t+(-p0+3.*p1-3.*p2+p3)*t*t*t))
			widths.append(lerpf(radii[i],radii[i+1],smoothstep(0.,1.,t)))
	points.append(knots[-1])
	widths.append(radii[-1])
	waterways.append({"id":id,"points":points,"radii":widths,"source_curve":"authored Catmull-Rom knots; shared <=85px segments with gradual bank width"})

func natural_distance(p: Vector2) -> float:
	var coast:=shore_x(p.y)-p.x
	return minf(coast,_river_distance(p))

func _route_distance(p: Vector2) -> float:
	var nearest:=10000.0
	if not route_buckets.is_empty():
		for segment in route_buckets.get(Vector2i(floori(p.x/128.),floori(p.y/128.)),[]):
			nearest=minf(nearest,p.distance_to(Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1]))-float(segment[2])*.5)
		return nearest
	for route in routes:
		var points: PackedVector2Array=route["points"]
		for i in range(1,points.size()):
			nearest=minf(nearest,p.distance_to(Geometry2D.get_closest_point_to_segment(p,points[i-1],points[i]))-float(route["width"])*.5)
	return nearest

func _route_profile(p: Vector2) -> Vector2:
	var closest:=Vector2(20.,40.)
	var edge:=10000.
	for segment in route_buckets.get(Vector2i(floori(p.x/128.),floori(p.y/128.)),[]):
		var half:=float(segment[2])*.5
		var distance:=p.distance_to(Geometry2D.get_closest_point_to_segment(p,segment[0],segment[1]))
		if distance-half<edge:
			edge=distance-half
			closest=Vector2(distance/maxf(half,1.),half)
	return closest

func _index_routes() -> void:
	route_buckets.clear()
	# One connected grade graph, not per-route independent clamps: shared
	# junctions receive the same height and terminal roads cannot create steps
	# into landmark pads. Limit true world-XZ longitudinal grade to .30 while
	# retaining low valleys/sea-level bridge stations. This changes real mesh
	# vertices, never the nav selector's slope threshold or water exclusion.
	var grades: Dictionary={}
	var links: Array=[]
	for route in routes:
		var points: PackedVector2Array=route["points"]
		var structure: bool=String(route["id"]).ends_with("_bridge") or route["id"]=="bailu_dock_access"
		for point in points:
			grades[point]=minf(float(grades.get(point,INF)),0. if structure else _base_ground(point))
		for i in range(1,points.size()):
			var delta: Vector2=(points[i]-points[i-1])/Vector2(SIZE)*WORLD
			links.append([points[i-1],points[i],delta.length()*.30])
	for iteration in 64:
		var changed:=false
		for edge in links:
			var a: Vector2=edge[0]
			var b: Vector2=edge[1]
			var rise: float=edge[2]
			var lower_a:=minf(float(grades[a]),float(grades[b])+rise)
			var lower_b:=minf(float(grades[b]),lower_a+rise)
			if lower_a<float(grades[a])-.000001 or lower_b<float(grades[b])-.000001: changed=true
			grades[a]=lower_a
			grades[b]=lower_b
		if not changed: break
	for route in routes:
		var points: PackedVector2Array=route["points"]
		for i in range(1,points.size()):
			var a:=points[i-1]
			var b:=points[i]
			var grade_a: float=grades[a]
			var grade_b: float=grades[b]
			for y in range(floori((minf(a.y,b.y)-180.)/128.),ceili((maxf(a.y,b.y)+180.)/128.)+1):
				for x in range(floori((minf(a.x,b.x)-180.)/128.),ceili((maxf(a.x,b.x)+180.)/128.)+1):
					var key:=Vector2i(x,y)
					if not route_buckets.has(key): route_buckets[key]=[]
					route_buckets[key].append([a,b,route["width"],grade_a,grade_b])

func _road_grade(p: Vector2,fallback: float) -> Vector2:
	var height_sum:=0.
	var weight_sum:=0.
	var maximum_strength:=0.
	for segment in route_buckets.get(Vector2i(floori(p.x/128.),floori(p.y/128.)),[]):
		var d: Vector2=segment[1]-segment[0]
		var t:=clampf((p-segment[0]).dot(d)/maxf(d.length_squared(),.001),0.,1.)
		var distance: float=p.distance_to(segment[0]+d*t)-float(segment[2])*.5
		var strength:=1.-smoothstep(20.,110.,distance)
		var weight:=pow(strength,4.)
		height_sum+=lerpf(segment[3],segment[4],t)*weight
		weight_sum+=weight
		maximum_strength=maxf(maximum_strength,strength)
	return Vector2((height_sum+fallback*.000001)/(weight_sum+.000001),maximum_strength)

func _final_structure_grade(p: Vector2,height: float) -> float:
	# Final, after every road and landmark/native pad. The actual support
	# receiver is a plane at .005 m; no later pad can lift ground through it.
	# Bridge approach roads also remain sea-level, with real graded shoulders.
	for i in range(3):
		var deck: Rect2=bridge_decks[i]
		var delta: Vector2=(p-deck.get_center()).abs()-deck.size*.5
		var edge:=Vector2(maxf(delta.x,0.),maxf(delta.y,0.)).length()
		height*=smoothstep(24.,124.,edge)
	return height

func terrain_height(p: Vector2) -> float:
	if not height_grid.is_empty():
		var uv:=p/Vector2(SIZE)*Vector2(HEIGHT_COLS,HEIGHT_ROWS)
		var x:=clampi(floori(uv.x),0,HEIGHT_COLS-1)
		var y:=clampi(floori(uv.y),0,HEIGHT_ROWS-1)
		var f:=(uv-Vector2(x,y)).clamp(Vector2.ZERO,Vector2.ONE)
		var a:=height_grid[y*(HEIGHT_COLS+1)+x]
		var b:=height_grid[y*(HEIGHT_COLS+1)+x+1]
		var c:=height_grid[(y+1)*(HEIGHT_COLS+1)+x]
		var d:=height_grid[(y+1)*(HEIGHT_COLS+1)+x+1]
		# Exactly the GPU triangles [a,b,c] and [b,d,c], not bilinear RF.
		return a+(b-a)*f.x+(c-a)*f.y if f.x+f.y<=1. else d+(c-d)*(1.-f.x)+(b-d)*(1.-f.y)
	return _authored_height(p)

func _base_ground(p: Vector2) -> float:
	# Self-contained native source. No old RF/candidate/contract dependency.
	var height: float=native_surface.regional_relief(p)
	height*=smoothstep(5.,105.,natural_distance(p))
	for deck in bridge_decks:
		var delta: Vector2=(p-deck.get_center()).abs()-deck.size*.5
		height*=smoothstep(42.,130.,Vector2(maxf(delta.x,0.),maxf(delta.y,0.)).length())
	return height

func _authored_height(p: Vector2) -> float:
	var bank:=natural_distance(p)
	if bank<0.:
		# Real submerged bed is never flattened to the supported bridge height.
		return NINTH.WATER_Y-1.10*smoothstep(0.,95.,-bank)
	var height:=_base_ground(p)
	var road:=_road_grade(p,height)
	# Centimetre-scale shallow tilled ridges share the material's short curved
	# rows. They are genuine surface normals/geometry, kept out of road cores.
	height+=_field_relief(p)*(1.-road.y)
	for site in landmarks:
		var center: Vector2=site["collision_center"]
		var size: Vector2=site["collision_size"]
		var ellipse:=(p-center)/Vector2(size.x*.75+36.,size.y*.75+32.)
		height=lerpf(height,float(site["pad_height"]),1.-smoothstep(.9,2.4,ellipse.length()))
	for spec in rock_pad_specs:
		var foot: Vector2=spec["foot"]
		# Only surveyed solid rocks have pads; plants follow the unmodified surface.
		var measured: Array=component_blueprints.get(spec["id"],[0.,0.,100.,70.])
		var radius:=Vector2(measured[2],measured[3])*.70+Vector2(24,20)
		var center:=foot+Vector2(measured[0],measured[1])
		height=lerpf(height,float(spec["pad_height"]),1.-smoothstep(.75,1.55,((p-center)/radius).length()))
	# Road is the final continuous grade, not overwritten by a nearby high
	# compound/rock foundation. Pads keep the same road terminal elevation.
	road=_road_grade(p,height)
	height=lerpf(height,road.x,road.y)
	height=_final_structure_grade(p,height)
	# Narrow continuous dry shore joins exactly to the authored wet bed.
	# At bridges, the independent actual deck stays Y0 above this bed.
	return lerpf(NINTH.WATER_Y,height,smoothstep(0.,36.,bank))

func _field_relief(p: Vector2) -> float:
	var result:=0.
	for f in CULTIVATION_FIELDS:
		var q: Vector2=(p-Vector2(f[0],f[1])).rotated(-float(f[4]))
		var axes:=Vector2(f[2],f[3])
		var bound: float=(q/axes).length()
		if bound>1.45: continue
		var taper:=1.-smoothstep(.65,1.45,bound)
		var spacing:=14. if f[5]==0. else 18.
		var bend:=q.y+.045*q.x*q.x/axes.x+4.*sin(q.x/70.)
		var row:=floorf(bend/spacing)
		var row_distance:=absf(fposmod(bend+spacing*.5,spacing)-spacing*.5)
		# Integer-sized hash matches the material expression exactly, avoiding
		# CPU-double / GPU-float sin-hash disagreements in ridge end lengths.
		var row_hash:=fposmod(row*17.+f[0]*13.,31.)/31.
		var end_length: float=axes.x*(.58+.30*row_hash)
		var end_taper:=1.-smoothstep(end_length-18.,end_length+8.,absf(q.x))
		result=maxf(result,.014*exp(-pow(row_distance/2.4,2.))*taper*end_taper)
	return result

func _point(p: Vector2,flat: bool=false) -> Vector3:
	return Vector3((p.x/SIZE.x-.5)*WORLD.x,0.0 if flat else terrain_height(p),(p.y/SIZE.y-.5)*WORLD.y)

func projected(p: Vector2) -> Vector2:
	return Vector2(p.x,p.y-supported_height(p)*SIZE.y/CAMERA_SIZE/sqrt(2.0))

func supported_height(p: Vector2) -> float:
	# Source deck rectangles are the actual narrow PlaneMesh pieces, not the
	# whole harbour image or a bay filled with land. RF remains natural bed.
	for deck in bridge_decks:
		if deck.has_point(p): return 0.
	return terrain_height(p)

func _support_at_screen(p: Vector2) -> bool:
	# DeckY0 projection is identity in source XY for this fixed camera.
	for deck in bridge_decks:
		if deck.has_point(p): return true
	return false

func _route(id: String,points: Array,width: float=72.0) -> void:
	var packed:=PackedVector2Array()
	for point in points:
		packed.append(point)
	routes.append({"id":id,"points":packed,"width":width})

func _curved_route(id: String,knots: Array,width: float=60.0) -> void:
	var points: Array=[]
	for i in range(knots.size()-1):
		var p0: Vector2=knots[maxi(0,i-1)]
		var p1: Vector2=knots[i]
		var p2: Vector2=knots[i+1]
		var p3: Vector2=knots[mini(knots.size()-1,i+2)]
		var count:=maxi(2,ceili(p1.distance_to(p2)/46.))
		for j in count:
			var t:=float(j)/count
			points.append(.5*((2.*p1)+(-p0+p2)*t+(2.*p0-5.*p1+4.*p2-p3)*t*t+(-p0+3.*p1-3.*p2+p3)*t*t*t))
	points.append(knots[-1])
	_route(id,points,width)

func _prepare_contract() -> void:
	_survey_component_bounds()
	var layout:=load(STAGING) as WalkableMapLayout
	assert(layout!=null)
	# One shared network with regional arcs, rather than three horizontal bars.
	_curved_route("north_foothill",[Vector2(400,1000),Vector2(850,1110),Vector2(1330,980),Vector2(1830,1090),Vector2(2300,1160),Vector2(2750,950),Vector2(3330,980),Vector2(3910,950)])
	_curved_route("central_trade",[Vector2(340,1850),Vector2(780,1730),Vector2(1260,1600),Vector2(1710,1880),Vector2(2300,1790),Vector2(3050,1690),Vector2(3510,1550),Vector2(3910,1370)])
	_curved_route("southern_west",[Vector2(400,2850),Vector2(790,2630),Vector2(1200,2790),Vector2(1390,2850)])
	_route("southern_bridge",[Vector2(1390,2850),Vector2(1680,2850)],54.)
	_curved_route("southern_east",[Vector2(1680,2850),Vector2(1950,2930),Vector2(2480,2820),Vector2(3130,2860),Vector2(3630,2780),Vector2(4140,2850)])
	_curved_route("west_north_south",[Vector2(850,1110),Vector2(1150,1420),Vector2(1260,1600),Vector2(1020,1960),Vector2(800,2240),Vector2(790,2630)])
	_curved_route("heartland_north",[Vector2(2300,1160),Vector2(2210,1470),Vector2(2300,1790),Vector2(2300,1930)])
	_route("heartland_bridge",[Vector2(2300,1930),Vector2(2300,2260)],54.)
	_curved_route("heartland_south",[Vector2(2300,2260),Vector2(2140,2450),Vector2(2480,2820)])
	_curved_route("east_north",[Vector2(3910,950),Vector2(3830,1190),Vector2(3910,1370)])
	_curved_route("east_port_landward",[Vector2(3910,1370),Vector2(4050,1580),Vector2(4030,1840),Vector2(4075,1970)])
	_route("east_bridge",[Vector2(4075,1970),Vector2(4075,2300)],54.)
	# A broad land-side shoulder goes west of the gorge compound, rather than
	# a short city-corner hairpin whose differing projected altitudes fold the
	# road under the front wall. The physical gorge footprint stays unchanged.
	_curved_route("east_south",[Vector2(4075,2300),Vector2(3850,2415),Vector2(3780,2635),Vector2(3850,2810),Vector2(4140,2850)])
	# A narrow true headwater turns into a shared confluence, never a broad
	# square/round tube chopped off at a blind source. Surveyed bridges remain
	# exact knots; the lower branch joins the same physical source point.
	_curved_waterway("main_river",[Vector2(1460,2020),Vector2(1400,2110),Vector2(1350,2260),Vector2(1690,2220),Vector2(1940,2140),Vector2(2300,2095),Vector2(2750,2205),Vector2(3270,2080),Vector2(3720,2175),Vector2(4075,2133),Vector2(4635,2285)],[6.,19.,46.,58.,65.,72.,80.,73.,79.,72.,115.])
	_curved_waterway("south_branch",[Vector2(1350,2260),Vector2(1430,2390),Vector2(1540,2600),Vector2(1536,2850),Vector2(1450,3160)],[46.,50.,55.,62.,75.])
	_index_waterways()
	for old_portal in layout.portals:
		var entry: Dictionary=old_portal.duplicate(true)
		var foot: Vector2=entry["pos"]*Vector2(SIZE)
		if entry["id"]=="east_sea_port": foot=Vector2(4138,1370)
		if entry["id"]=="bailu_ferry": foot=Vector2(4190,1840)
		entry["pos"]=foot/Vector2(SIZE)
		entry.erase("staging_pending_asset")
		entry.erase("validation_status")
		var original: Dictionary={}
		for candidate in layout.visual_objects:
			if candidate.get("portal_id","")==entry["id"]:
				original=candidate.duplicate(true)
				break
		assert(not original.is_empty())
		var size: Vector2=original["render_size_px"]
		var center: Vector2=original["pos"]*Vector2(SIZE)
		if entry["id"]=="east_sea_port": center=Vector2(4240,1260)
		if entry["id"]=="bailu_ferry": center=Vector2(4210,1720)
		var path: String=original["texture"]
		var filename:=path.get_file()
		var image:=Image.load_from_file(path)
		assert(image!=null and image.get_format()==Image.FORMAT_RGBA8)
		assert(_source_png(image,OUT+"entities/"+filename)==OK)
		original["texture"]=OUT+"entities/"+filename
		original["pos"]=center/Vector2(SIZE)
		original.erase("validation_status")
		# Explicit ground-level source UV contracts, reviewed on the original
		# image. No old v13 normalized rectangles: several were behind walls.
		var bounds:=_landmark_ground_uv(String(entry["id"]))
		var footprint_size:=bounds.size*size
		var footprint_center:=center+(bounds.get_center()-Vector2(.5,.5))*size
		var base_y:=center.y+(bounds.end.y-.5)*size.y
		original["collision_offset"]=(footprint_center-center)/Vector2(SIZE)
		original["collision_size"]=footprint_size/Vector2(SIZE)
		original["depth_sort_foot_y"]=base_y/SIZE.y
		# The outside station includes the full Field nav grow and body size.
		foot.y=maxf(foot.y,base_y+46.)
		if entry["id"]=="bailu_ferry": foot.y=1861.
		entry["pos"]=foot/Vector2(SIZE)
		portals.append(entry)
		var hub:=_closest_hub(foot)
		if entry["id"]=="east_sea_port": hub=Vector2(3910,1370)
		if entry["id"]=="bailu_ferry": hub=Vector2(4030,1840)
		_curved_route("portal_"+String(entry["id"]),[hub,hub.lerp(foot,.50)+Vector2(0,22),foot],62.0)
		if entry["id"] in ["east_sea_port","bailu_ferry"]:
			original.erase("sort_by_feet")
			original.erase("depth_sort_foot_y")
			original["z_index"]=-2
			_harbor_foregrounds(String(entry["id"]),image,center,size)
		objects.append(original)
		var probes: Array=[]
		for uv in _ground_probes(String(entry["id"])):
			probes.append({"source_uv":_pair(uv),"world_px":_pair(center+(uv-Vector2(.5,.5))*size),"source_alpha":image.get_pixel(clampi(roundi(uv.x*image.get_width()),0,image.get_width()-1),clampi(roundi(uv.y*image.get_height()),0,image.get_height()-1)).a})
		landmarks.append({"id":entry["id"],"source":path,"source_sha256":FileAccess.get_sha256(path),"center":center,"size":size,"foundation":Rect2(footprint_center-footprint_size*.5,footprint_size),"collision_center":footprint_center,"collision_size":footprint_size,"foot":foot,"depth_y":base_y,"alpha_canvas":image.get_size(),"ground_uv_rect":bounds,"solid_ground_probes":probes})
	var old_center:=Vector2(2420,615.8)
	var scale:=Vector2(330./420.,235./280.)
	for old_rect in [Rect2(2380,593,95,32),Rect2(2395,613,52,79)]:
		bridge_decks.append(Rect2(Vector2(4210,1720)+(old_rect.position-old_center)*scale,old_rect.size*scale))
	_route("bailu_dock_access",[Vector2(4190,1861),Vector2(4220,1815),Vector2(4220,1749),Vector2(4220,1714),Vector2(4241,1714)],36.)
	for index in range(3):
		var north_south:=index!=1
		var filename: String="bridge_stone_northsouth_v1.png" if north_south else "bridge_stone_eastwest_v1.png"
		var image:=Image.load_from_file(OLD+filename)
		assert(_source_png(image,OUT+"entities/"+filename)==OK)
		objects.append({"id":"bridge_"+str(index),"texture":OUT+"entities/"+filename,"pos":bridge_centers[index]/Vector2(SIZE),"render_size_px":Vector2(190,285) if north_south else Vector2(280,280.*float(image.get_height())/image.get_width()),"z_index":-2})
		_bridge_foregrounds(index,image)
	# Organic entity clearance must be measured against the corrected roads,
	# not against paths which were still running through the old city walls.
	_repair_route_clearance()
	var group_feet: Array[Vector2]=[Vector2(510,2050),Vector2(810,2260),Vector2(2750,2480),Vector2(3810,2400)]
	for gi in group_feet.size():
		for variant in 3:
			native_specs.append({"id":"native_herb_%d_%d"%[gi,variant],"source":HERB,"foot":group_feet[gi]+Vector2(variant*19.0,variant*8.0),"yaw":22.0+variant*81,"scale":1.0,"variant":variant,"blocking":false})
	var pine_feet: Array[Vector2]=[Vector2(330,1110),Vector2(460,1170),Vector2(370,1270),Vector2(280,1380),Vector2(500,1290),Vector2(600,1130),Vector2(720,1290),Vector2(650,1400),Vector2(3190,730),Vector2(3330,780),Vector2(3220,875),Vector2(3460,850),Vector2(3600,770),Vector2(3700,870),Vector2(3510,970),Vector2(3740,1030),Vector2(3070,1130),Vector2(2960,1250),Vector2(3070,1370),Vector2(3330,1460),Vector2(3460,1340),Vector2(3660,1310),Vector2(3830,2350),Vector2(3730,2490)]
	for i in pine_feet.size():
		var foot:=pine_feet[i]
		if natural_distance(foot)<90. or _route_distance(foot)<80.: continue
		native_specs.append({"id":"native_pine_%02d"%i,"source":PINE,"foot":foot,"yaw":[22.,112.,202.][i%3],"scale":1.0,"variant":i%3,"blocking":true,"nature":"small_pine_sapling"})
	var pine_colonies: Array=[
		[Vector2(700,1040),Vector2(180,145),7],
		[Vector2(3240,960),Vector2(230,185),9],
		[Vector2(3640,1190),Vector2(170,200),8],
		[Vector2(3680,2830),Vector2(190,130),6]]
	for ci in pine_colonies.size():
		var colony: Array=pine_colonies[ci]
		for ti in int(colony[2]):
			var phase:=ti*2.39996323+ci*.67
			var radial:=sqrt(float(ti+1)/float(colony[2]+1))*.82
			var foot: Vector2=colony[0]+Vector2(cos(phase),sin(phase))*colony[1]*radial
			if not _vegetation_foot_clear(foot,90.,80.,75.): continue
			var variant:=ti%3
			native_specs.append({"id":"native_pine_colony_%d_%d"%[ci,ti],"source":PINE,"foot":foot,"yaw":[22.,112.,202.][variant],"scale":1.,"variant":variant,"blocking":true,"nature":"small_pine_sapling","colony":ci,"pose_key":"pine_%d"%variant})
	# Mature broadleaf patches, not enlarged saplings or copied full groups.
	# Authored dense cores, broken edges, and deliberate clearings. Reuse only
	# identical pose alpha; every trunk retains its own foot/collider/depth/caster.
	var colonies: Array=[
		[Vector2(590,1450),Vector2(290,280),50],
		[Vector2(1050,2140),Vector2(290,245),45],
		[Vector2(540,2550),Vector2(290,190),45],
		[Vector2(1660,1380),Vector2(255,195),35],
		[Vector2(3070,1310),Vector2(290,290),55],
		[Vector2(3290,1900),Vector2(300,250),50],
		[Vector2(3530,2580),Vector2(340,295),55],
		[Vector2(3690,1550),Vector2(245,295),45]]
	var tree_index:=0
	for ci in colonies.size():
		var colony: Array=colonies[ci]
		for ti in int(colony[2]):
			if tree_index>=180: continue
			# Golden-angle placement within hand-positioned biome cores, no rows.
			var phase:=float(ti)*2.39996323+float(ci)*.71
			var radial:=sqrt(float(ti+1)/float(colony[2]+1))*.84
			var foot: Vector2=colony[0]+Vector2(cos(phase),sin(phase))*colony[1]*radial
			if not _vegetation_foot_clear(foot,100.,96.,90.): continue
			var pose:=tree_index%3
			native_specs.append({"id":"native_tree_%03d"%tree_index,"source":TREE,"foot":foot,"yaw":[25.,145.,265.][pose],"scale":[.70,.78,.86][pose],"variant":0,"blocking":true,"nature":"mature_broadleaf_geographic_scale","colony":ci,"pose_key":"tree_hybrid_%d"%pose})
			tree_index+=1
	for base in [Vector2(1820,765),Vector2(1950,812),Vector2(2100,838),Vector2(2220,765),Vector2(2370,827),Vector2(2460,843)]:
		for vi in 3:
			var foot: Vector2=base+Vector2(cos(vi*2.4)*38.,sin(vi*2.4)*20.)
			native_specs.append({"id":"native_ridge_herb_%d"%native_specs.size(),"source":HERB,"foot":foot,"yaw":22.+vi*81.,"scale":1.,"variant":vi,"blocking":false,"nature":"natural_rockbase_groundcover","pose_key":"herb_%d"%vi})
	# Ecotone low plants sit as individual entities, not a shared group Y line.
	var ecotones: Array[Vector2]=[Vector2(720,1680),Vector2(1160,2280),Vector2(2830,2470),Vector2(3650,2400),Vector2(3880,1860),Vector2(3040,1530)]
	for gi in ecotones.size():
		for vi in 4:
			var foot:=ecotones[gi]+Vector2(cos(vi*2.4)*42.,sin(vi*2.4)*28.)
			if not _vegetation_foot_clear(foot,70.,64.,45.): continue
			native_specs.append({"id":"native_ecotone_%d_%d"%[gi,vi],"source":HERB,"foot":foot,"yaw":22.+(vi%3)*81.,"scale":1.,"variant":vi%3,"blocking":false,"nature":"natural_groundcover","pose_key":"herb_%d"%(vi%3)})
	_index_routes()
	for site in landmarks:
		site["pad_height"]=0. if site["id"] in ["east_sea_port","bailu_ferry"] else _road_grade(site["foot"],_base_ground(site["foot"])).x
	rock_pad_specs.clear()
	for spec in native_specs:
		if spec["source"] not in [PINE,HERB,TREE]: rock_pad_specs.append(spec)
		var base:=_base_ground(spec["foot"])
		var grade:=_road_grade(spec["foot"],base)
		spec["pad_height"]=lerpf(base,grade.x,grade.y)
	_add_original_groves()
	# Stable, explicit schema is available before GPU capture. Not a ready flag.
	_write_source_contract()

func _vegetation_foot_clear(foot: Vector2,bank_margin: float,road_margin: float,wall_margin: float) -> bool:
	if natural_distance(foot)<bank_margin or _route_distance(foot)<road_margin: return false
	for site in landmarks:
		if Rect2(site["collision_center"]-site["collision_size"]*.5,site["collision_size"]).grow(wall_margin).has_point(foot): return false
	return true

func _closest_hub(foot: Vector2) -> Vector2:
	var result:=Vector2.ZERO
	var best:=INF
	for route in routes:
		if String(route["id"]).begins_with("portal_"): continue
		var points: PackedVector2Array=route["points"]
		for i in range(1,points.size()):
			var point:=Geometry2D.get_closest_point_to_segment(foot,points[i-1],points[i])
			if point.distance_squared_to(foot)<best:
				result=point
				best=point.distance_squared_to(foot)
	return result

func _source_obstacles() -> Array[Rect2]:
	var result: Array[Rect2]=[]
	for site in landmarks:
		# City wall footprints remain unchanged. The road itself moves outside
		# full-foot+Field grow, with additional survey margin, not mask erasure.
		result.append(Rect2(site["collision_center"]-site["collision_size"]*.5,site["collision_size"]).grow(40.))
	for spec in native_specs:
		if not component_blueprints.has(spec["id"]): continue
		var measured: Array=component_blueprints[spec["id"]]
		var center: Vector2=spec["foot"]+Vector2(measured[0],measured[1])
		var size:=Vector2(measured[2],measured[3])
		result.append(Rect2(center-size*.5,size).grow(40.))
	return result

func _source_segment_clear(a: Vector2,b: Vector2,obstacles: Array[Rect2]) -> bool:
	var samples:=maxi(1,ceili(a.distance_to(b)/12.))
	for sample in range(samples+1):
		if natural_distance(a.lerp(b,float(sample)/samples))<34.: return false
	for rect in obstacles:
		if rect.has_point(a) or rect.has_point(b): return false
		var corners: Array[Vector2]=[rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]
		for side in 4:
			if Geometry2D.segment_intersects_segment(a,b,corners[side],corners[(side+1)%4])!=null: return false
	return true

func _outside_source_point(point: Vector2,obstacles: Array[Rect2]) -> Vector2:
	var blocked:=false
	for rect in obstacles:
		if rect.has_point(point): blocked=true
	if not blocked: return point
	var result:=point
	var best:=INF
	for rect in obstacles:
		if not rect.has_point(point): continue
		for candidate in [Vector2(rect.position.x-2.,point.y),Vector2(rect.end.x+2.,point.y),Vector2(point.x,rect.position.y-2.),Vector2(point.x,rect.end.y+2.)]:
			var valid:=natural_distance(candidate)>=34.
			for other in obstacles:
				if other.has_point(candidate): valid=false
			if valid and candidate.distance_squared_to(point)<best:
				best=candidate.distance_squared_to(point)
				result=candidate
	assert(best<INF,"No legal land-side outside point; do not shrink entity")
	return result

func _repair_route_clearance() -> void:
	var obstacles:=_source_obstacles()
	var graph:=AStar2D.new()
	var corners: Array[Vector2]=[]
	for rect in obstacles:
		var padded:=rect.grow(2.)
		for p in [padded.position,Vector2(padded.end.x,padded.position.y),padded.end,Vector2(padded.position.x,padded.end.y)]:
			var valid:=natural_distance(p)>=34.
			for other in obstacles:
				if other.has_point(p): valid=false
			if valid:
				graph.add_point(corners.size(),p)
				corners.append(p)
	for a in corners.size():
		for b in range(a+1,corners.size()):
			if _source_segment_clear(corners[a],corners[b],obstacles): graph.connect_points(a,b)
	# Rebuild terminal hubs AFTER mains have gone around the real cities.
	var main_routes: Array[Dictionary]=[]
	for route in routes:
		if not String(route["id"]).begins_with("portal_"): main_routes.append(route)
	routes=main_routes
	for route in routes:
		if route["id"]=="bailu_dock_access" or String(route["id"]).ends_with("_bridge"): continue # surveyed real structural support, not land white paint
		route["points"]=_clearance_path(route["points"],obstacles,graph,corners)
	for portal in portals:
		var foot: Vector2=portal["pos"]*Vector2(SIZE)
		var hub:=_closest_hub(foot)
		if portal["id"]=="east_sea_port": hub=_closest_hub(Vector2(3910,1370))
		if portal["id"]=="bailu_ferry": hub=_closest_hub(Vector2(4030,1840))
		_curved_route("portal_"+String(portal["id"]),[hub,hub.lerp(foot,.5)+Vector2(0,22),foot],62.)
		var terminal:=routes[-1]
		terminal["points"]=_clearance_path(terminal["points"],obstacles,graph,corners)

func _clearance_path(points: PackedVector2Array,obstacles: Array[Rect2],graph: AStar2D,corners: Array[Vector2]) -> PackedVector2Array:
	var result:=PackedVector2Array()
	var previous:=_outside_source_point(points[0],obstacles)
	result.append(previous)
	for i in range(1,points.size()):
		var target:=_outside_source_point(points[i],obstacles)
		if previous.distance_to(target)<.1: continue
		var path:=PackedVector2Array([previous,target])
		if not _source_segment_clear(previous,target,obstacles):
			graph.add_point(1000,previous)
			graph.add_point(1001,target)
			for j in corners.size():
				if _source_segment_clear(previous,corners[j],obstacles): graph.connect_points(1000,j)
				if _source_segment_clear(target,corners[j],obstacles): graph.connect_points(1001,j)
			path=graph.get_point_path(1000,1001)
			graph.remove_point(1000)
			graph.remove_point(1001)
			assert(path.size()>1,"No city bypass exists; do not weaken physical footprint")
		for k in range(1,path.size()):
			var count:=maxi(1,ceili(path[k-1].distance_to(path[k])/20.))
			for sample in range(1,count+1): result.append(path[k-1].lerp(path[k],float(sample)/count))
		previous=target
	return result

func _landmark_ground_uv(id: String) -> Rect2:
	var boxes: Dictionary={
		"yanmen_pass":Rect2(.045,.52,.915,.425),
		"huashan":Rect2(.245,.64,.575,.345),
		"wudang":Rect2(.065,.52,.85,.465),
		"gufeng":Rect2(.08,.58,.84,.355),
		"lingyue":Rect2(.055,.61,.88,.335),
		"bianzhou":Rect2(.045,.29,.915,.53),
		"linxi_village":Rect2(.08,.45,.84,.45),
		"luoyang":Rect2(.025,.28,.95,.55),
		"xiangzhou":Rect2(.025,.25,.95,.625),
		"east_sea_port":Rect2(.09,.30,.445,.335),
		"bailu_ferry":Rect2(.07,.285,.365,.27),
		"zhuwei_village":Rect2(.07,.43,.86,.50),
		"qinghe_town":Rect2(.15,.42,.70,.53),
		"jinling":Rect2(.04,.28,.92,.705),
		"mingwu":Rect2(.055,.40,.89,.455),
		"lieyun_valley":Rect2(.12,.58,.78,.36)}
	return boxes[id]

func _ground_probes(id: String) -> Array[Vector2]:
	var probes: Dictionary={
		"yanmen_pass":[Vector2(.18,.70),Vector2(.78,.85)],
		"huashan":[Vector2(.29,.80),Vector2(.72,.89)],
		"wudang":[Vector2(.15,.78),Vector2(.84,.81)],
		"gufeng":[Vector2(.20,.84),Vector2(.73,.79)],
		"lingyue":[Vector2(.17,.84),Vector2(.81,.84)],
		"bianzhou":[Vector2(.22,.71),Vector2(.79,.75)],
		"linxi_village":[Vector2(.16,.72),Vector2(.79,.77)],
		"luoyang":[Vector2(.20,.70),Vector2(.83,.70)],
		"xiangzhou":[Vector2(.18,.69),Vector2(.81,.69)],
		"east_sea_port":[Vector2(.17,.50),Vector2(.25,.56)],
		"bailu_ferry":[Vector2(.17,.45),Vector2(.28,.50)],
		"zhuwei_village":[Vector2(.24,.72),Vector2(.80,.78)],
		"qinghe_town":[Vector2(.21,.60),Vector2(.71,.69)],
		"jinling":[Vector2(.17,.77),Vector2(.81,.75)],
		"mingwu":[Vector2(.17,.66),Vector2(.77,.72)],
		"lieyun_valley":[Vector2(.21,.79),Vector2(.75,.75)]}
	var result: Array[Vector2]=[]
	for p in probes[id]: result.append(p)
	return result

func _harbor_foregrounds(id: String,source: Image,center: Vector2,size: Vector2) -> void:
	if id=="bailu_ferry":
		for part in [["pavilion_foreground",565.],["rail_north",631.],["rail_right_middle",757.],["rail_right_near",924.],["rail_left_middle",713.],["rail_left_near",910.]]:
			var suffix: String="ferry_"+String(part[0])+".png"
			var image:=Image.load_from_file("res://build/world_native_pair_ortho_v9_"+suffix)
			assert(image!=null and image.get_size()==source.get_size())
			var path:=OUT+"entities/bailu_"+String(part[0])+".png"
			assert(_source_png(image,path)==OK)
			objects.append({"id":"bailu_"+String(part[0]),"texture":path,"pos":center/Vector2(SIZE),"render_size_px":size,"sort_by_feet":true,"depth_sort_foot_y":(center.y+(float(part[1])/1024.-.5)*size.y)/SIZE.y})
	else:
		var polygon:=PackedVector2Array([Vector2(110,290),Vector2(330,80),Vector2(650,5),Vector2(800,100),Vector2(835,370),Vector2(870,540),Vector2(790,645),Vector2(520,625),Vector2(140,570)])
		var mask:=Image.create(source.get_width(),source.get_height(),false,Image.FORMAT_RGBA8)
		mask.fill(Color.TRANSPARENT)
		for y in range(0,646):
			for x in range(100,871):
				if Geometry2D.is_point_in_polygon(Vector2(x+.5,y+.5),polygon):
					mask.set_pixel(x,y,source.get_pixel(x,y))
		assert(_source_png(mask,OUT+"entities/east_sea_gate_foreground.png")==OK)
		objects.append({"id":"east_sea_gate_foreground","texture":OUT+"entities/east_sea_gate_foreground.png","pos":center/Vector2(SIZE),"render_size_px":size,"sort_by_feet":true,"depth_sort_foot_y":(center.y+(645./1024.-.5)*size.y)/SIZE.y})

func _bridge_foregrounds(index: int,source: Image) -> void:
	var size: Vector2=Vector2(280,280.*float(source.get_height())/source.get_width()) if index==1 else Vector2(190,285)
	var center: Vector2=bridge_centers[index]
	if index==1:
		# Source Y481 is walking floor except the six actual cap silhouettes.
		# Do not crop a broad strip of floor into a common front layer.
		var parts: Array[Dictionary]=[]
		var posts: Array[Vector2]=[Vector2(170,591),Vector2(430,590),Vector2(727,590),Vector2(1044,590),Vector2(1339,590),Vector2(1603,594)]
		for i in posts.size():
			var p:=posts[i]
			var cap_top:=467. if i in [0,5] else 478.
			var radius:=29. if i in [0,5] else 23.
			parts.append({"id":"post_%d"%i,"polygon":PackedVector2Array([Vector2(p.x-radius,cap_top+20),Vector2(p.x-radius*.7,cap_top+5),Vector2(p.x,cap_top),Vector2(p.x+radius*.75,cap_top+6),Vector2(p.x+radius,cap_top+23),Vector2(p.x+radius,cap_top+55),Vector2(p.x+radius+2,p.y),Vector2(p.x-radius-2,p.y)]),"base_source_y":p.y})
		for i in range(5):
			parts.append({"id":"panel_%d"%i,"polygon":PackedVector2Array([Vector2(posts[i].x+25,523),Vector2(posts[i+1].x-23,523),Vector2(posts[i+1].x-23,607),Vector2(posts[i].x+25,607)]),"base_source_y":607.})
		# Vertical arch fascia below the railing is a separate lower-base entity.
		parts.append({"id":"fascia","polygon":PackedVector2Array([Vector2(211,608),Vector2(1553,608),Vector2(1553,622),Vector2(1395,625),Vector2(1276,648),Vector2(1260,676),Vector2(1186,676),Vector2(1180,650),Vector2(970,621),Vector2(810,622),Vector2(597,651),Vector2(590,676),Vector2(535,676),Vector2(527,652),Vector2(389,623),Vector2(211,623)]),"base_source_y":676.})
		var owned:=PackedByteArray()
		owned.resize(source.get_width()*source.get_height())
		# Posts own overlap with panel edges. All raw alpha remains source-derived.
		for part in parts:
			var mask:=Image.create(source.get_width(),source.get_height(),false,Image.FORMAT_RGBA8)
			mask.fill(Color.TRANSPARENT)
			for y in range(465,677):
				for x in range(136,1635):
					var key:=y*source.get_width()+x
					if owned[key]>0 or not Geometry2D.is_point_in_polygon(Vector2(x+.5,y+.5),part["polygon"]): continue
					var pixel:=source.get_pixel(x,y)
					if pixel.a<=0.: continue
					mask.set_pixel(x,y,pixel)
					owned[key]=1
			var path:=OUT+"entities/bridge_eastwest_"+String(part["id"])+".png"
			assert(mask.get_used_rect().has_area() and _source_png(mask,path)==OK)
			var base_y:=center.y+(float(part["base_source_y"])/source.get_height()-.5)*size.y
			objects.append({"id":"bridge_eastwest_"+String(part["id"]),"texture":path,"pos":center/Vector2(SIZE),"render_size_px":size,"sort_by_feet":true,"depth_sort_foot_y":base_y/SIZE.y,"source_base_y":part["base_source_y"],"source_alpha_semantics":"near cap/post, carved railing panel or lower arch fascia; no broad walking-floor rectangle"})
		return
	# Explicit side masonry, not rectangular strips of walking deck. Each
	# segment gets its own actual source bottom, avoiding one common Y line.
	var source_size:=Vector2(source.get_size())
	for side in 2:
		for segment in 5:
			var mask:=Image.create(source.get_width(),source.get_height(),false,Image.FORMAT_RGBA8)
			mask.fill(Color.TRANSPARENT)
			var min_y:=30+segment*290
			var max_y:=mini(source.get_height()-1,min_y+289)
			var bottom:=0
			for y in range(min_y,max_y+1):
				for x in source.get_width():
					var edge:=.351-.052*(float(y)/source.get_height())
					var side_pixel:=float(x)/source.get_width()<edge if side==0 else float(x)/source.get_width()>1.0-edge
					if side_pixel and source.get_pixel(x,y).a>.0:
						mask.set_pixel(x,y,source.get_pixel(x,y))
						bottom=maxi(bottom,y)
			var filename:="bridge_ns_side_%d_%d.png"%[side,segment] if index==0 else "bridge_ns%d_side_%d_%d.png"%[index,side,segment]
			assert(mask.get_used_rect().has_area() and _source_png(mask,OUT+"entities/"+filename)==OK)
			var base_y:=center.y+(float(bottom)/source_size.y-.5)*size.y
			objects.append({"id":"bridge_ns%d_side_%d_%d"%[index,side,segment],"texture":OUT+"entities/"+filename,"pos":center/Vector2(SIZE),"render_size_px":size,"sort_by_feet":true,"depth_sort_foot_y":base_y/SIZE.y})

func _add_original_groves() -> void:
	var path:=OLD+"shrub_cluster_generated_v1_candidate.png"
	var image:=Image.load_from_file(path)
	assert(_source_png(image,OUT+"entities/shrub_original.png")==OK)
	var rng:=RandomNumberGenerator.new()
	rng.seed=141402
	var clusters: Array[Vector2]=[Vector2(300,2100),Vector2(650,2070),Vector2(440,2700),Vector2(830,2950),Vector2(1180,2360),Vector2(3210,2470),Vector2(3640,2570),Vector2(3840,2480),Vector2(3310,1310),Vector2(2980,1380),Vector2(360,1210)]
	var sites: Array[Vector2]=[]
	for cluster in clusters:
		for j in 7:
			var foot:=cluster+Vector2(rng.randf_range(-190.,190.),rng.randf_range(-130.,130.))
			# Actual 115..204px mature grove footprint, Field .004 grow and
			# complete actor feet need more than the old fixed 65px spacing.
			if natural_distance(foot)<100. or _route_distance(foot)<120.: continue
			var blocked:=false
			for site in landmarks:
				if foot.distance_to(site["foot"])<220.: blocked=true
			for other in sites:
				if other.distance_to(foot)<90.: blocked=true
			if not blocked: sites.append(foot)
	for i in sites.size():
		var foot:=sites[i]
		var width:=115.0+float((i*31)%90)
		var size:=Vector2(width,width*2.0/3.0)
		var center:=foot+Vector2(0,-size.y*.44)
		objects.append({"id":"original_grove_"+str(i),"texture":OUT+"entities/shrub_original.png","pos":center/Vector2(SIZE),"render_size_px":size,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,"collision_offset":(foot-center)/Vector2(SIZE),"collision_size":Vector2(width*.58,32)/Vector2(SIZE)})
		vegetation_sites.append({"id":"original_grove_"+str(i),"source_foot":foot,"source":path,"legacy_baked_light":true,"license":"project original generated asset; not CC0"})

func _object_json(source: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for key in source:
		var value: Variant=source[key]
		result[key]=_pair(value) if value is Vector2 else value
	return result

func _project_runtime_contract() -> void:
	# Legacy sprites are flat billboards standing on a surveyed level pad.
	# Runtime coordinates and semantic alpha probes follow that same pad.
	for site in landmarks:
		var source_center: Vector2=site["center"]
		var height:=terrain_height(site["collision_center"])
		if site["id"] in ["east_sea_port","bailu_ferry"]: height=0. # sea-level port floor and supported planks stay co-registered
		var shift:=Vector2(0,-height*SIZE.y/CAMERA_SIZE/sqrt(2.))
		site["runtime_shift"]=shift
		site["support_height_m"]=height
		for object in objects:
			if (object["pos"]*Vector2(SIZE)).distance_to(source_center)<.01 and object.get("render_size_px",Vector2.ZERO)==site["size"]:
				object["pos"]+=shift/Vector2(SIZE)
				if object.has("depth_sort_foot_y"): object["depth_sort_foot_y"]+=shift.y/SIZE.y
		for probe in site["solid_ground_probes"]:
			probe["source_world_px"]=probe["world_px"].duplicate()
			var value: Array=probe["world_px"]
			probe["world_px"]=[value[0]+shift.x,value[1]+shift.y]
	for portal in portals:
		var source_foot: Vector2=portal["pos"]*Vector2(SIZE)
		portal["source_foot_px"]=_pair(source_foot)
		portal["pos"]=projected(source_foot)/Vector2(SIZE)
	for site in vegetation_sites:
		var source_foot: Vector2=site["source_foot"]
		var shift:=projected(source_foot)-source_foot
		for object in objects:
			if object["id"]==site["id"]:
				object["pos"]+=shift/Vector2(SIZE)
				object["depth_sort_foot_y"]=projected(source_foot).y/SIZE.y

func _write_source_contract(ready: bool=false) -> void:
	var portal_json: Array=[]
	for portal in portals:
		var item:=_object_json(portal)
		item["foot_px"]=_pair(portal["pos"]*Vector2(SIZE))
		portal_json.append(item)
	var object_json: Array=[]
	for object in objects: object_json.append(_object_json(object))
	var route_json: Array=[]
	for route in routes:
		var points: Array=[]
		for point in route["points"]: points.append(_pair(projected(point)))
		route_json.append({"id":route["id"],"points_px":points,"width_px":route["width"],"baked_into_terrain":true})
	var supports: Array=[]
	for deck in bridge_decks: supports.append(_rect(deck))
	var structures: Array=[]
	for index in bridge_decks.size():
		var is_dock:=index>=3
		var support: Rect2=bridge_decks[index]
		var object_id: String="bailu_landmark" if is_dock else "bridge_"+str(index)
		var center:=Vector2(4210,1720) if is_dock else bridge_centers[index]
		var size:=Vector2(330,235) if is_dock else Vector2(190,285)
		# Structure source-UV mapping must use the actual independently drawn
		# object size. Never repeat a stale approximate image aspect here.
		for object in objects:
			if String(object["id"])==object_id:
				size=object["render_size_px"]
				break
		var path:=OUT+"entities/landmark_bailu_ferry_v1.png" if is_dock else OUT+"entities/"+("bridge_stone_eastwest_v1.png" if index==1 else "bridge_stone_northsouth_v1.png")
		var source_passage: Array=[]
		var passage: Array=[]
		if is_dock:
			for p in [Vector2(4190,1861),Vector2(4220,1815),Vector2(4220,1749),Vector2(4220,1714),Vector2(4241,1714)]:
				source_passage.append(_pair(p))
				passage.append(_pair(projected(p)))
		elif index==1:
			source_passage=[_pair(center-Vector2(150,0)),_pair(center+Vector2(150,0))]
			passage=[_pair(projected(center-Vector2(150,0))),_pair(projected(center+Vector2(150,0)))]
		else:
			source_passage=[_pair(center-Vector2(0,165)),_pair(center+Vector2(0,165))]
			passage=[_pair(projected(center-Vector2(0,165))),_pair(projected(center+Vector2(0,165)))]
		structures.append({"id":"support_"+str(index),"object_id":object_id,"kind":"dock" if is_dock else "bridge","rect_px":_rect(support),"texture_path":path,"render_center_px":_pair(center),"render_size_px":_pair(size),"source_uv_rect":_rect(Rect2((support.position-center)/size+Vector2(.5,.5),support.size/size)),"passage_px":passage,"source_passage_px":source_passage,"source_deck_polygon":[_pair(support.position),_pair(Vector2(support.end.x,support.position.y)),_pair(support.end),_pair(Vector2(support.position.x,support.end.y))],"deck_height_m":0.,"support_mesh_path":OUT+"entities/support_"+str(index)+".res","support_mesh_sha256":FileAccess.get_sha256(OUT+"entities/support_"+str(index)+".res") if ready else "","support_node_position_m":[(support.get_center().x/SIZE.x-.5)*WORLD.x,0.,(support.get_center().y/SIZE.y-.5)*WORLD.y],"support_capture_camera":coverage_record if ready else {"position":[0,FULL_CAMERA_OFFSET,FULL_CAMERA_OFFSET],"orthographic_size":CAMERA_SIZE,"actual_capture_pending":true},"support_geometry":"actual native PlaneMesh Y0 rendered only in final walk; stored RES and transform independent from negative bed RF","source_alpha_semantics":"actual stone/wooden deck; rail silhouettes separately Y sorted"})
	var sources: Array=[]
	for site in landmarks:
		var shift: Vector2=site.get("runtime_shift",Vector2.ZERO)
		var foundation: Rect2=site["foundation"]
		foundation.position+=shift
		sources.append({"id":site["id"],"source":site["source"],"source_sha256":site["source_sha256"],"legacy_baked_light":true,"source_center_px":_pair(site["center"]),"render_center_px":_pair(site["center"]+shift),"source_collision_center_px":_pair(site["collision_center"]),"support_height_m":site.get("support_height_m",0.),"foundation_px":_rect(foundation),"depth_foot_y":site["depth_y"]+shift.y,"ground_uv_rect":_rect(site["ground_uv_rect"]),"solid_ground_probes":site["solid_ground_probes"],"collision_center_px":_pair(site["collision_center"]+shift),"collision_size_px":_pair(site["collision_size"]),"outside_entry_px":_pair(projected(site["foot"])) if not height_grid.is_empty() else _pair(site["foot"]),"ground_semantics":"actual front/court footprint on local altitude pad; source and projected coordinates explicit; roof bounds not used"})
	var seams: Array=[]
	for row in 3:
		for column in range(1,3):
			var line:=float(column*1536)
			var point:=_route_crossing(line,true,Rect2(0,row*1024,SIZE.x,1024))
			seams.append({"id":"vertical_%d_%d"%[row,column],"axis":"x","line_px":line,"witness_px":_pair(point),"from":"r%dc%d"%[row,column-1],"to":"r%dc%d"%[row,column],"route_visible":true})
	for row in range(1,3):
		for column in 3:
			var line:=float(row*1024)
			var point:=_route_crossing(line,false,Rect2(column*1536,0,1536,SIZE.y))
			seams.append({"id":"horizontal_%d_%d"%[row,column],"axis":"y","line_px":line,"witness_px":_pair(point),"from":"r%dc%d"%[row-1,column],"to":"r%dc%d"%[row,column],"route_visible":true})
	var waters: Array=[]
	for water in waterways:
		var points: Array=[]
		for p in water["points"]: points.append(_pair(p))
		waters.append({"id":water["id"],"points":points,"radii":Array(water["radii"]),"method":"distance-to-segment radius interpolation and round endpoint; common CPU/native shader"})
	var vegetation: Array=[]
	for site in vegetation_sites:
		vegetation.append({"id":site["id"],"source":site["source"],"source_sha256":FileAccess.get_sha256(site["source"]),"source_foot":_pair(site["source_foot"]),"legacy_baked_light":true,"license":site["license"]})
	_json(OUT+"source_contract.json",{"schema_version":14,"world_size":[4608,3072],"status":"ART_ASSETS_READY" if ready else "BUILD_IN_PROGRESS","overview_path":OUT+"overview.png","visual_path":OUT+"visual.png","land_path":OUT+"land.png","walk_path":OUT+"walk.png","raw_walk_path":OUT+"raw_walk.png","geometry_path":OUT+"geometry.json","portals":portal_json,"objects":object_json,"routes":route_json,"seams":seams,"structure_support_rects_px":supports,"structure_entries":structures,"structure_semantics":"first3 actual sea-level bridge decks; last2 sea-level L-shaped Bailu planks, same-camera actual support mesh","waterways":waters,"landmark_sources":sources,"original_vegetation_sources":vegetation,"player_spawn_px":_pair(projected(Vector2(644,1800))),"source_space":"self-contained authored source XZ controls; runtime dry route/portal/player/objects actual terrain height projection; only validated narrow deck points use separate actual supportY0; true underwater RF unchanged","camera":{"size":30,"position":[0,FULL_CAMERA_OFFSET,FULL_CAMERA_OFFSET],"world_meters":[45,42.42640687]},"no_legacy_tile_copy":true})

func _route_crossing(line: float,vertical: bool,region: Rect2) -> Vector2:
	for route in routes:
		var points: PackedVector2Array=route["points"]
		for i in range(1,points.size()):
			var a:=projected(points[i-1])
			var b:=projected(points[i])
			var first:=a.x if vertical else a.y
			var last:=b.x if vertical else b.y
			if absf(last-first)<.01 or line<minf(first,last) or line>maxf(first,last): continue
			var p:=a.lerp(b,(line-first)/(last-first))
			if region.has_point(p): return p
	return Vector2(-1,-1)

func _source_images() -> void:
	print("[WorldV14] authored height grid begin")
	_cache_height_grid()
	print("[WorldV14] shared height grid complete; source selectors begin")
	# Source topology is a deterministic low-resolution selector, not runtime nav.
	topo=Image.create(2304,1536,false,Image.FORMAT_RGBA8)
	road_profile_image=Image.create(2304,1536,false,Image.FORMAT_RGF)
	for y in topo.get_height():
		for x in topo.get_width():
			var p:=Vector2(x*2.0,y*2.0)
			var dry:=terrain_height(p)>NINTH.WATER_Y
			var profile:=_route_profile(p)
			road_profile_image.set_pixel(x,y,Color(profile.x,profile.y,0.,1.))
			var path:=1.0-smoothstep(-8.0,10.0,(profile.x-1.)*profile.y)
			var gradient:=terrain_gradient(p)
			var allowed: bool=_selector_cell_info(p)["allowed"]
			topo.set_pixel(x,y,Color(1.0 if dry else 0.0,path,1.0 if allowed else 0.0,clampf(terrain_height(p)/5.0,0.0,1.0)))
	assert(_source_png(topo,OUT+"source_topology.png")==OK)
	topology_texture=ImageTexture.create_from_image(topo)
	road_profile_texture=ImageTexture.create_from_image(road_profile_image)
	if not source_design_only:
		var profile_file:=FileAccess.open(OUT+"road_profile.rgf",FileAccess.WRITE)
		assert(profile_file!=null)
		profile_file.store_buffer(road_profile_image.get_data())
		profile_file.close()

func _cache_height_grid() -> void:
	var precomputed:=PackedFloat32Array()
	precomputed.resize((HEIGHT_COLS+1)*(HEIGHT_ROWS+1))
	for y in range(HEIGHT_ROWS+1):
		for x in range(HEIGHT_COLS+1): precomputed[y*(HEIGHT_COLS+1)+x]=_authored_height(Vector2(x*6.0,y*6.0))
	height_grid=precomputed

# The same 2px nearest selector covers an AREA, not just its source corner.
# Explicit native-cell gradient enumeration covers BOTH triangles whenever
# the 2px area intersects their interiors, even when endpoints shift next-cell.
# Corner/centre/diagonal samples remain height/bank witnesses and may include
# conservative adjacent-cell gradient values at inclusive mesh boundaries.
func _selector_cell_info(p: Vector2) -> Dictionary:
	var origin:=Vector2(floorf(p.x/2.)*2.,floorf(p.y/2.)*2.)
	var samples: Array[Vector2]=[origin,origin+Vector2(2,0),origin+Vector2(0,2),origin+Vector2(2,2),origin+Vector2.ONE]
	var cell:=Vector2(floorf(origin.x/6.)*6.,floorf(origin.y/6.)*6.)
	var diagonal:=cell.x+cell.y+6.
	for x in [origin.x,origin.x+2.]:
		var y: float=diagonal-x
		if y>=origin.y and y<=origin.y+2.: samples.append(Vector2(x,y))
	for y in [origin.y,origin.y+2.]:
		var x: float=diagonal-y
		if x>=origin.x and x<=origin.x+2.: samples.append(Vector2(x,y))
	assert(not height_grid.is_empty(),"Cell-area oracle requires actual cached Float32 mesh heights")
	var ix:=clampi(floori(origin.x/6.),0,HEIGHT_COLS-1)
	var iy:=clampi(floori(origin.y/6.),0,HEIGHT_ROWS-1)
	var u:=(origin-Vector2(ix*6,iy*6))/6.
	var minimum_sum:=u.x+u.y
	var maximum_sum:=minimum_sum+4./6.
	var a:=height_grid[iy*(HEIGHT_COLS+1)+ix]
	var b:=height_grid[iy*(HEIGHT_COLS+1)+ix+1]
	var c:=height_grid[(iy+1)*(HEIGHT_COLS+1)+ix]
	var d:=height_grid[(iy+1)*(HEIGHT_COLS+1)+ix+1]
	var world_step:=Vector2(WORLD.x/HEIGHT_COLS,WORLD.y/HEIGHT_ROWS)
	var gradient:=0.
	if minimum_sum<=1.: gradient=maxf(gradient,(Vector2(b-a,c-a)/world_step).length())
	if maximum_sum>=1.: gradient=maxf(gradient,(Vector2(d-c,d-b)/world_step).length())
	var height:=INF
	var bank:=INF
	for q in samples:
		q=q.clamp(Vector2.ZERO,Vector2(SIZE))
		gradient=maxf(gradient,terrain_gradient(q))
		height=minf(height,terrain_height(q))
		bank=minf(bank,natural_distance(q))
	# Additional 3px shore contraction covers an unsampled curve between
	# witnesses. Does not open water and is shared with full17 forecast.
	return {"allowed":height>NINTH.WATER_Y and bank>27. and gradient<.72,"max_gradient":gradient,"minimum_height_m":height,"minimum_sample_bank_px":bank,"source_cell":[origin.x,origin.y,2.,2.],"native_affine_witness_count":samples.size(),"native_cell_triangles_enumerated":[minimum_sum<=1.,maximum_sum>=1.]}

func _gentle_fullfoot_witness(source: Vector2) -> bool:
	var screen:=projected(source)
	for index in 17:
		var shoe:=screen
		if index>0:
			var angle:=TAU*(index-1)/16.
			shoe+=Vector2(cos(angle)*10.,sin(angle)*6.)
		var q:=_source_plan_inverse(shoe,source.y)
		var gradient:=terrain_gradient(q)
		if gradient>.45 or natural_distance(q)<65. or not _selector_cell_info(q)["allowed"]: return false
	return true

func terrain_gradient(p: Vector2) -> float:
	if height_grid.is_empty():
		return Vector2((terrain_height(p+Vector2(1,0))-terrain_height(p-Vector2(1,0)))/(2.*WORLD.x/SIZE.x),(terrain_height(p+Vector2(0,1))-terrain_height(p-Vector2(0,1)))/(2.*WORLD.y/SIZE.y)).length()
	var uv:=p/Vector2(SIZE)*Vector2(HEIGHT_COLS,HEIGHT_ROWS)
	var x:=clampi(floori(uv.x),0,HEIGHT_COLS-1)
	var y:=clampi(floori(uv.y),0,HEIGHT_ROWS-1)
	var f:=(uv-Vector2(x,y)).clamp(Vector2.ZERO,Vector2.ONE)
	var a:=height_grid[y*(HEIGHT_COLS+1)+x]
	var b:=height_grid[y*(HEIGHT_COLS+1)+x+1]
	var c:=height_grid[(y+1)*(HEIGHT_COLS+1)+x]
	var d:=height_grid[(y+1)*(HEIGHT_COLS+1)+x+1]
	var delta:=Vector2(b-a,c-a) if f.x+f.y<=1. else Vector2(d-c,d-b)
	return (delta/Vector2(WORLD.x/HEIGHT_COLS,WORLD.y/HEIGHT_ROWS)).length()

func _visible_native_source(screen: Vector2) -> Dictionary:
	# Exact camera-nearest terrain intersection, without an engine/GPU capture.
	# For fixed screenX, each actual RF triangle is affine along sourceY.
	# Full camera is at positiveY/Z: among intersections with fixed z-y,
	# largest sourceY has largest z+y and hence the nearest actual depth.
	var x: int=clampi(floori(screen.x/6.),0,HEIGHT_COLS-1)
	var fx: float=clampf(screen.x/6.-x,0.,1.)
	var k: float=SIZE.y/CAMERA_SIZE/sqrt(2.)
	var nearest_y: float=-INF
	var hits: int=0
	for row in HEIGHT_ROWS:
		var a: float=height_grid[row*(HEIGHT_COLS+1)+x]
		var b: float=height_grid[row*(HEIGHT_COLS+1)+x+1]
		var c: float=height_grid[(row+1)*(HEIGHT_COLS+1)+x]
		var d: float=height_grid[(row+1)*(HEIGHT_COLS+1)+x+1]
		var ys: Array[float]=[float(row*6),float(row*6)+6.*(1.-fx),float((row+1)*6)]
		var hs: Array[float]=[a+(b-a)*fx,b*fx+c*(1.-fx),c+(d-c)*fx]
		for segment in 2:
			if ys[segment+1]-ys[segment]<.000001: continue
			var sa: float=ys[segment]-hs[segment]*k
			var sb: float=ys[segment+1]-hs[segment+1]*k
			if screen.y<minf(sa,sb)-.000001 or screen.y>maxf(sa,sb)+.000001: continue
			if absf(sb-sa)<.000001: continue
			var t: float=clampf((screen.y-sa)/(sb-sa),0.,1.)
			nearest_y=maxf(nearest_y,lerpf(ys[segment],ys[segment+1],t))
			hits+=1
	if hits==0: return {"found":false,"hits":0}
	var q:=Vector2(screen.x,nearest_y)
	return {"found":true,"hits":hits,"source":q,"height_m":terrain_height(q),"world_gradient":terrain_gradient(q),"camera_visibility_method":"maximum sourceY of all exact RF triangle-affine screenY intersections; positiveY/Z camera"}

func _geometry_fullfoot_data(source: Vector2) -> Dictionary:
	var screen: Vector2=projected(source)
	var shoes: Array=[]
	var reason: String=""
	for index in 17:
		var shoe: Vector2=screen
		if index>0:
			var angle: float=TAU*(index-1)/16.
			shoe+=Vector2(cos(angle)*10.,sin(angle)*6.)
		var visible: Dictionary=_visible_native_source(shoe)
		if not visible["found"]:
			reason="shoe_has_no_visible_native_triangle"
			shoes.append({"index":index,"screen":_pair(shoe),"visible":false})
			break
		var q: Vector2=visible["source"]
		var gradient: float=terrain_gradient(q)
		var bank: float=natural_distance(q)
		var cell: Dictionary=_selector_cell_info(q)
		var shoe_valid: bool=gradient<=.45 and bank>=65. and cell["allowed"]
		shoes.append({"index":index,"screen":_pair(shoe),"nearest_source":_pair(q),"height_m":terrain_height(q),"world_gradient":gradient,"bank_distance_px":bank,"selector_cell":cell,"passed":shoe_valid})
		if not shoe_valid:
			reason="shoe_gradient_over_.45" if gradient>.45 else ("shoe_bank_under65" if bank<65. else "shoe_conservative_selector_denied")
			break
	return {"passed":reason.is_empty() and shoes.size()==17,"reason":reason,"shoes":shoes}

func _measure_geometry_witnesses() -> Dictionary:
	if not geometry_witness_audit.is_empty(): return geometry_witness_audit
	assert(not height_grid.is_empty())
	var gentle: Array=[]
	var steep: Array=[]
	var candidates: Array=[]
	var reasons: Dictionary={}
	var visited: int=0
	var max_dry_gradient: float=0.
	var max_dry_point: Array=[]
	var phases: Array=[]
	for phase: String in ["historical24","native_triangle_centres6"]:
		var stride: int=24 if phase=="historical24" else 6
		var before_gentle: int=gentle.size()
		var before_steep: int=steep.size()
		var phase_samples: int=0
		var offsets: Array[Vector2]=[]
		if phase=="historical24":
			offsets.append(Vector2.ZERO)
		else:
			offsets.append(Vector2(2,2))
			offsets.append(Vector2(4,4))
		var start: int=48 if phase=="historical24" else 12
		var done: bool=false
		for y in range(start,SIZE.y-12,stride):
			if done: break
			for x in range(start,SIZE.x-12,stride):
				if done: break
				for offset in offsets:
					var p: Vector2=Vector2(x,y)+offset
					visited+=1
					phase_samples+=1
					var screen: Vector2=projected(p)
					var bank: float=natural_distance(p)
					if not Rect2(Vector2(12,12),Vector2(SIZE)-Vector2(24,24)).has_point(screen) or bank<65.:
						reasons["outside_safe_canvas_or_bank65"]=int(reasons.get("outside_safe_canvas_or_bank65",0))+1
						continue
					var gradient: float=terrain_gradient(p)
					if gradient>max_dry_gradient:
						max_dry_gradient=gradient
						max_dry_point=_pair(p)
					var kind: String="steep" if gradient>.76 and steep.size()<24 else ("gentle" if gradient>.08 and gradient<.32 and gentle.size()<24 else "")
					if kind.is_empty(): continue
					var item: Dictionary={"source_point":_pair(p),"projected_point":_pair(screen),"height_m":terrain_height(p),"world_gradient":gradient,"bank_distance_px":bank,"phase":phase,"candidate_kind":kind}
					var visible: Dictionary=_visible_native_source(screen)
					var visible_valid: bool=visible["found"]
					if visible_valid:
						var nearest: Vector2=visible["source"]
						item["nearest_visible_source"]=_pair(nearest)
						item["source_to_visible_error_px"]=nearest.distance_to(p)
						item["nearest_visible_gradient"]=visible["world_gradient"]
						visible_valid=nearest.distance_to(p)<.12
					if not visible_valid:
						item["accepted"]=false
						item["rejected_reason"]="source_occluded_or_no_native_intersection"
					elif kind=="gentle":
						var foot: Dictionary=_geometry_fullfoot_data(p)
						item["full17_data"]=foot
						item["accepted"]=foot["passed"]
						item["rejected_reason"]=foot["reason"]
						if foot["passed"]:
							var exported: Dictionary=item.duplicate(true)
							exported["full17_shoes_verified"]=true
							exported["source_cell_rule"]="same conservative entire2px selector, exact owning6px triangle enumeration"
							gentle.append(exported)
					else:
						item["accepted"]=true
						item["rejected_reason"]=""
						steep.append(item.duplicate(true))
					if not item["accepted"]:
						var rejected: String=item["rejected_reason"]
						reasons[rejected]=int(reasons.get(rejected,0))+1
					candidates.append(item)
					if gentle.size()>=24 and steep.size()>=24: done=true;break
		phases.append({"phase":phase,"source_sample_step_px":stride,"samples_visited":phase_samples,"gentle_added":gentle.size()-before_gentle,"steep_added":steep.size()-before_steep,"gentle_count":gentle.size(),"steep_count":steep.size()})
		if gentle.size()>=12 and steep.size()>=12: break
	var passed: bool=gentle.size()>=12 and steep.size()>=12
	var reject_reason: String="" if passed else ("insufficient_real_full17_gentle_%d_or_visible_steep_%d"%[gentle.size(),steep.size()])
	geometry_witness_audit={"status":"GEOMETRY_WITNESS_PASS" if passed else "GEOMETRY_WITNESS_FAIL","passed":passed,"gentle_count":gentle.size(),"steep_count":steep.size(),"required_each":12,"rejection_reason":reject_reason,"source_samples_visited":visited,"phases":phases,"max_actual_dry_triangle_gradient":max_dry_gradient,"max_gradient_source":max_dry_point,"rejection_counts":reasons,"thresholds_unchanged":{"gentle_candidate_min":.08,"gentle_candidate_max":.32,"all17_shoe_max":.45,"steep_candidate_min":.76,"bank_min_px":65.,"nav_selector_max":.72},"gentle_examples":gentle,"steep_examples":steep,"candidate_point_data":candidates,"visibility":"exact CPU camera-nearest native RF affine triangles; no GPU/derived normal/no navigation painting","executed_builder_sha256":FileAccess.get_sha256(get_script().resource_path)}
	print("[V14GeometryWitness] gentle=",gentle.size()," steep=",steep.size()," samples=",visited," max_dry_triangle_gradient=",max_dry_gradient," passed=",passed)
	return geometry_witness_audit

func _geometry_witness_audit_only() -> void:
	_prepare_contract()
	_cache_height_grid()
	var measured: Dictionary=_measure_geometry_witnesses()
	if measured.is_empty():
		measured={"status":"GEOMETRY_WITNESS_RUNTIME_FAIL","passed":false,"rejection_reason":"measurement_returned_empty_dictionary","executed_builder_sha256":FileAccess.get_sha256(get_script().resource_path)}
	var result_saved: bool=_checked_geometry_json("res://build/world_map_v14_"+source_plan_tag+"_result.json",measured)
	_free_capture_model_nodes()
	_release_capture_resource_refs()
	for frame in 16: await process_frame
	var cursors_released: bool=_cursor_release_audit()
	quit(0 if bool(measured.get("passed",false)) and result_saved and cursors_released else 1)

func _export_geometry() -> bool:
	var measured: Dictionary=_measure_geometry_witnesses()
	if not _checked_geometry_json(OUT+"geometry_witness_audit.json",measured): return false
	if measured.is_empty() or not bool(measured.get("passed",false)):
		print("[V14GeometryWitness] export rejected: ",measured.get("rejection_reason","measurement_returned_empty_dictionary"))
		return false
	var file: FileAccess=FileAccess.open(OUT+"height_grid.rf",FileAccess.WRITE)
	if file==null: return false
	var raw_rf: PackedByteArray=height_grid.to_byte_array()
	file.store_buffer(raw_rf)
	file.flush()
	var rf_error: Error=file.get_error()
	file.close()
	if rf_error!=OK or FileAccess.get_file_as_bytes(OUT+"height_grid.rf")!=raw_rf:
		print("[V14GeometryIO] RF store/readback failed error=",rf_error)
		return false
	if ResourceSaver.save(terrain_mesh,OUT+"terrain_mesh.res")!=OK: return false
	var gentle: Array=measured["gentle_examples"]
	var steep: Array=measured["steep_examples"]
	var arrays:=terrain_mesh.surface_get_arrays(0)
	var attributes: Dictionary={}
	for item in [[Mesh.ARRAY_VERTEX,"vertex"],[Mesh.ARRAY_NORMAL,"normal"],[Mesh.ARRAY_TEX_UV,"uv"],[Mesh.ARRAY_INDEX,"index"]]:
		var hashing:=HashingContext.new()
		hashing.start(HashingContext.HASH_SHA256)
		hashing.update(arrays[item[0]].to_byte_array())
		attributes[item[1]]=hashing.finish().hex_encode()
	var geometry: Dictionary={"height_grid_path":OUT+"height_grid.rf","height_grid_shape":[HEIGHT_COLS+1,HEIGHT_ROWS+1],"height_grid_format":"little endian float32 meters, row-major; actual mesh vertex source, not GPU height capture","source_node_spacing_px":[6,6],"terrain_mesh_path":OUT+"terrain_mesh.res","terrain_mesh_sha256":FileAccess.get_sha256(OUT+"terrain_mesh.res"),"mesh_attributes_sha256":attributes,"world_meters":_pair(WORLD),"camera_size":30.,"height_to_projected_y":-SIZE.y/CAMERA_SIZE/sqrt(2.),"steep_examples":steep,"gentle_examples":gentle,"actual_front_winding":"a,b,c,b,d,c same native PlaneMesh","topology_selector_path":OUT+"source_topology.png","nav_selector_spacing_px":2,"natural_shore_clip":"actual terrain vertex XYZ height > waterY; water uses identical Float32 returned mesh RF affine triangle height, source bank>24 only conservative nav selector"}
	geometry["height_interpolation"]="exact triangle-affine: a+(b-a)*fx+(c-a)*fy when fx+fy<=1; d+(c-d)*(1-fx)+(b-d)*(1-fy) otherwise"
	geometry["gradient_method"]="exact selected GPU triangle derivatives (b-a,c-a) or (d-c,d-b), divided by native world grid XZ size; no central or bilinear approximation"
	geometry["nav_selector_cell_rule"]="Entire2pxcell explicit owning6pxcell triangle coverage: minsum<=1 lower/maxsum>=1 upper; gradients directly from a,b,c,d; corners/centre/diagonal minheight-bank witnesses; inclusiveboundary extra gradients and conservative27pxsample bank; forecast exactsame rule"
	geometry["gentle_examples_contract"]="eachcandidate full17shoes uses same cellrule; no centre-only positive assertion"
	geometry["geometry_witness_audit_path"]=OUT+"geometry_witness_audit.json"
	geometry["geometry_witness_sampling"]="historical24 then exact native triangle centres6; CPU camera-nearest visibility/full17 verified before GPU capture"
	return _checked_geometry_json(OUT+"geometry.json",geometry)

func _mesh(flat: bool=false) -> ArrayMesh:
	# Explicit native arrays guarantee the declared source-cell index stream.
	# SurfaceTool may deduplicate/reorder vertices while generating normals;
	# the prior capture must be verified through index->UV, not literal IDs.
	# Here no such ambiguity is needed: RF nodes, UVs and draw vertices align.
	var vertices:=PackedVector3Array()
	var uvs:=PackedVector2Array()
	var normals:=PackedVector3Array()
	var count: int=(HEIGHT_COLS+1)*(HEIGHT_ROWS+1)
	vertices.resize(count)
	uvs.resize(count)
	normals.resize(count)
	normals.fill(Vector3.UP if flat else Vector3.ZERO)
	for y in HEIGHT_ROWS+1:
		for x in HEIGHT_COLS+1:
			var index: int=y*(HEIGHT_COLS+1)+x
			var uv:=Vector2(float(x)/HEIGHT_COLS,float(y)/HEIGHT_ROWS)
			uvs[index]=uv
			vertices[index]=Vector3((uv.x-.5)*WORLD.x,0. if flat else height_grid[index],(uv.y-.5)*WORLD.y)
	var indices:=PackedInt32Array()
	indices.resize(HEIGHT_ROWS*HEIGHT_COLS*6)
	for y in HEIGHT_ROWS:
		for x in HEIGHT_COLS:
			var a: int=y*(HEIGHT_COLS+1)+x
			var b:=a+1
			var c:=a+HEIGHT_COLS+1
			var d:=c+1
			var first: int=(y*HEIGHT_COLS+x)*6
			for offset in 6: indices[first+offset]=[a,b,c,b,d,c][offset]
	if not flat:
		for i in range(0,indices.size(),3):
			var a:=indices[i]
			var b:=indices[i+1]
			var c:=indices[i+2]
			# Godot clockwise front; its illumination normal points upward.
			var normal: Vector3=(vertices[c]-vertices[a]).cross(vertices[b]-vertices[a])
			normals[a]+=normal
			normals[b]+=normal
			normals[c]+=normal
		for i in normals.size(): normals[i]=normals[i].normalized()
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	if not flat:
		var returned: PackedVector3Array=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var values:=PackedFloat32Array()
		values.resize(returned.size())
		for i in returned.size(): values[i]=returned[i].y
		assert(values==height_grid,"Water RF must exactly equal actual returned mesh Y")
		actual_height_image=Image.create_from_data(HEIGHT_COLS+1,HEIGHT_ROWS+1,false,Image.FORMAT_RF,values.to_byte_array())
		actual_height_texture=ImageTexture.create_from_image(actual_height_image)
	return mesh

func _surface_material(mode: int) -> ShaderMaterial:
	if surface_materials.has(mode): return surface_materials[mode]
	if mode in [0,4] and not native_surface.load_verified_sources():
		_fail_candidate(native_surface.last_error)
		return null
	var shader:=Shader.new()
	shader.code=native_surface.surface_code(mode,_waterway_shader(),_foundation_shader(),_cultivation_shader())
	var required: Array=["ecology_gate","road_profile_rg"] if mode==4 else (["mode","topo","water_y_m"] if mode>0 else ["mode","topo","detail_normals","road_profile_rg","aerial_grass_rock_diff","aerial_grass_rock_nor_gl","aerial_grass_rock_arm","rock_01_nor_gl","leafy_grass_arm","forest_ground_04_diff","brown_mud_03_arm","grass_ground_diff","grass_ground_nor_gl","grass_ground_arm"])
	if not _shader_compiled(shader,required,"ninth_surface_%d"%mode): return null
	var material:=ShaderMaterial.new()
	material.shader=shader
	if mode==4:
		material.set_shader_parameter("ecology_gate",1.)
		material.set_shader_parameter("road_profile_rg",road_profile_texture)
	else:
		material.set_shader_parameter("topo",topology_texture)
		material.set_shader_parameter("mode",mode)
	if mode in [1,2]: material.set_shader_parameter("water_y_m",NINTH.WATER_Y)
	elif mode==0:
		if road_profile_texture==null:
			var fixture:=Image.create(2,2,false,Image.FORMAT_RGF)
			fixture.fill(Color(20.,40.,0.,1.))
			road_profile_texture=ImageTexture.create_from_image(fixture)
		material.set_shader_parameter("road_profile_rg",road_profile_texture)
		for name in native_surface.textures: material.set_shader_parameter(name,native_surface.textures[name])
	surface_materials[mode]=material
	return material

func _shader_compiled(shader: Shader,required: Array,label: String) -> bool:
	# Reflection forces native compiler validation. An invalid spatial program
	# returns no uniforms; never capture its fallback/default material.
	var names: Array=[]
	for uniform in shader.get_shader_uniform_list(): names.append(String(uniform["name"]))
	var valid:=true
	for name in required:
		if not names.has(name): valid=false
	shader_gate_results.append({"label":label,"required":required,"actual_uniforms":names,"compiled":valid})
	if not valid: push_error("[WorldV14] shader compile/reflection gate failed: "+label)
	return valid

func _water_material() -> ShaderMaterial:
	if compiled_water_material!=null: return compiled_water_material
	var shader:=Shader.new()
	shader.code=native_surface.water_code()
	if not _shader_compiled(shader,["actual_height_rf","grid_shape","water_y_m"],"ninth_actual_triangle_rf_water"): return null
	var material:=ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("water_y_m",NINTH.WATER_Y)
	material.set_shader_parameter("grid_shape",Vector2i(HEIGHT_COLS+1,HEIGHT_ROWS+1))
	if actual_height_texture!=null: material.set_shader_parameter("actual_height_rf",actual_height_texture)
	compiled_water_material=material
	return material

func _foundation_shader() -> String:
	var code:="vec2 site_contact(vec2 p){float soil=0.;float ao=0.;"
	for site in landmarks:
		var center: Vector2=site["collision_center"]
		var size: Vector2=site["collision_size"]
		code+="{vec2 q=(p-vec2(%f,%f))/vec2(%f,%f);float w=(1.-smoothstep(.72,1.55,length(q)+(n(p/31.)-.5)*.31))*(.60+.40*n(p/17.));soil=max(soil,w);float contact=exp(-pow((p.y-%f)/6.,2.))*exp(-pow((p.x-%f)/%f,4.));ao=max(ao,contact*.14);}"%[center.x,center.y,size.x*.55+16.,size.y*.5+13.,center.y+size.y*.5,center.x,size.x*.55]
	code+="return vec2(soil,ao);}"
	return code

func _waterway_shader() -> String:
	var code:="float bank_distance(vec2 p){float d=shore(p.y)-p.x;"
	for water in waterways:
		var points: PackedVector2Array=water["points"]
		var widths: PackedFloat32Array=water["radii"]
		for i in range(1,points.size()):
			var a:=points[i-1]
			var b:=points[i]
			code+="{vec2 a=vec2(%f,%f),b=vec2(%f,%f);float t=clamp(dot(p-a,b-a)/dot(b-a,b-a),0.,1.);d=min(d,length(p-mix(a,b,t))-mix(%f,%f,t));}"%[a.x,a.y,b.x,b.y,widths[i-1],widths[i]]
	code+="return d;}"
	return code

func _water_flow_shader() -> String:
	# Each segment uses cumulative along-river arc distance and local cross
	# distance. Blend its actual normal perturbation, not a hard nearest winner
	# or global dot(p,flow) phase which jumps at bends and confluences.
	var code:="vec2 water_tilt(vec2 p){vec2 sum=vec2(.030*cos(p.x/29.+p.y/97.),.046*cos(p.y/23.+sin(p.x/67.)))*.05;float weight=.05;"
	for water in waterways:
		var points: PackedVector2Array=water["points"]
		var widths: PackedFloat32Array=water["radii"]
		var cumulative:=0.
		for i in range(1,points.size()):
			var a:=points[i-1]
			var b:=points[i]
			code+="{vec2 a=vec2(%f,%f),b=vec2(%f,%f);vec2 ab=b-a;vec2 flow=normalize(ab),across=vec2(-flow.y,flow.x);float t=clamp(dot(p-a,ab)/dot(ab,ab),0.,1.);float radius=mix(%f,%f,t);float distance=length(p-mix(a,b,t));float w=pow(1.-smoothstep(radius+32.,radius+128.,distance),3.);float along=%f+dot(p-a,flow),crossflow=dot(p-a,across);float dx=.055*cos(along/21.+sin(crossflow/47.))+.024*cos(along/9.+crossflow/33.);float dz=.040*cos(crossflow/16.+sin(along/63.));sum+=(flow*dx+across*dz)*w;weight+=w;}"%[a.x,a.y,b.x,b.y,widths[i-1],widths[i],cumulative]
			cumulative+=a.distance_to(b)
	code+="return sum/weight;}"
	return code

func _cultivation_shader() -> String:
	var code:="vec3 cultivated_land(vec2 p,vec3 base,vec3 soil,vec3 grass){"
	for f in CULTIVATION_FIELDS:
		code+="{vec2 v=p-vec2(%f,%f);vec2 q=mat2(vec2(cos(%f),-sin(%f)),vec2(sin(%f),cos(%f)))*v;vec2 axes=vec2(%f,%f);"%[f[0],f[1],f[4],f[4],f[4],f[4],f[2],f[3]]
		code+="float bound=length(q/axes);float field=1.-smoothstep(.65,1.45,bound);float spacing=%f;float bend=q.y+.045*q.x*q.x/axes.x+4.*sin(q.x/70.);float row=floor(bend/spacing);float row_distance=abs(mod(bend+spacing*.5,spacing)-spacing*.5);float row_end=axes.x*(.58+.30*mod(row*17.+%f*13.,31.)/31.);float end_mask=1.-smoothstep(row_end-18.,row_end+8.,abs(q.x));"%[14. if f[5]==0. else 18.,f[0]]
		code+="float furrow=exp(-pow(row_distance/2.4,2.))*end_mask;float leaves=(1.-smoothstep(1.1,2.4,row_distance))*end_mask*smoothstep(.38,.64,n(vec2(q.x/3.7,row*3.)));float clear_road=1.-texture(topo,p/vec2(4608,3072)).g;float worked=field*clear_road;vec3 turned_soil=mix(soil*.86,texture(forest_ground_04_diff,p*vec2(45./4608.,42.42640687/3072.)/3.2).rgb,.28);base=mix(base,turned_soil,worked*.44);base=mix(base,turned_soil*.78,furrow*worked*.26);vec3 leaf=mix(grass*.93,base*.90,.38);base=mix(base,leaf,leaves*worked*.56);}"
	code+="return base;}"
	return code

func _viewport(mode: int) -> SubViewport:
	var viewport:=SubViewport.new()
	viewport.msaa_3d=Viewport.MSAA_DISABLED
	viewport.size=SIZE*VISUAL_SSAA_SCALE if mode in [0,4] else SIZE
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world:=Node3D.new()
	viewport.add_child(world)
	var env:=WorldEnvironment.new()
	env.environment=native_surface.environment()
	if mode>0:
		env.environment.background_mode=Environment.BG_COLOR
		env.environment.background_color=Color.BLACK
	world.add_child(env)
	if mode==0:
		var river:=MeshInstance3D.new()
		river.mesh=_mesh(true)
		river.position.y=NINTH.WATER_Y
		river.material_override=_water_material()
		river.material_override.set_shader_parameter("actual_height_rf",actual_height_texture)
		river.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(river)
	var land:=MeshInstance3D.new()
	land.name="ActualTerrain"
	land.mesh=terrain_mesh
	land.material_override=_surface_material(mode)
	land.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if mode==0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(land)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-34,0)
	light.light_energy=NINTH.DIRECT
	light.shadow_enabled=mode==0
	light.shadow_bias=.02
	light.shadow_normal_bias=1.
	light.directional_shadow_max_distance=60.
	light.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	world.add_child(light)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=CAMERA_SIZE
	camera.position=Vector3(0,FULL_CAMERA_OFFSET,FULL_CAMERA_OFFSET)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current=true
	coverage_record=_capture_coverage(camera,light)
	if not coverage_record["whole_visible_receiver_covered"]:
		_fail_candidate("Whole map shadow distance excludes native receiver")
		return null
	return viewport

func _capture_coverage(camera: Camera3D,light: DirectionalLight3D) -> Dictionary:
	var reference:=Camera3D.new()
	reference.projection=camera.projection
	reference.size=camera.size
	reference.position=Vector3(0,36,36)
	camera.get_parent().add_child(reference)
	reference.look_at(Vector3.ZERO)
	var mismatch:=0.
	var nearest:=INF
	var furthest:=-INF
	var min_y:=INF
	var vertices: PackedVector3Array=terrain_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var actual_viewport: SubViewport=camera.get_viewport() as SubViewport
	assert(actual_viewport!=null)
	var image_rect:=Rect2(Vector2.ZERO,Vector2(actual_viewport.size))
	var projection_scale: float=float(actual_viewport.size.x)/SIZE.x
	for vertex in vertices:
		min_y=minf(min_y,vertex.y)
		mismatch=maxf(mismatch,camera.unproject_position(vertex).distance_to(reference.unproject_position(vertex))/projection_scale)
		if not image_rect.has_point(camera.unproject_position(vertex)): continue
		var depth:=-(camera.global_transform.affine_inverse()*vertex).z
		nearest=minf(nearest,depth)
		furthest=maxf(furthest,depth)
	# Conservative screen-top ray + lowest actual vertex also covers triangle
	# interiors whose original vertices fall outside the image.
	var bound:=FULL_CAMERA_OFFSET*sqrt(2.)+camera.size*.5-sqrt(2.)*min_y
	reference.queue_free()
	return {"actual_camera_position":[camera.position.x,camera.position.y,camera.position.z],"actual_orthographic_size":camera.size,"actual_projection":camera.projection,"same_orientation_projection_error_px":mismatch,"reference_fifth_camera":[0,36,36],"camera_offset_change_only_along_view_direction":true,"min_receiver_height_m":min_y,"actual_in_canvas_depth_min":nearest,"actual_in_canvas_depth_max":furthest,"whole_visible_receiver_far_bound":bound,"max_shadow_distance":light.directional_shadow_max_distance,"whole_visible_receiver_covered":bound<light.directional_shadow_max_distance and mismatch<.01 and nearest>camera.near,"actual_canvas":[actual_viewport.size.x,actual_viewport.size.y],"logical_canvas":[SIZE.x,SIZE.y],"projection_scale_to_logical":1./projection_scale,"shadow_mode":light.directional_shadow_mode,"normal_bias":light.shadow_normal_bias,"bias":light.shadow_bias,"conservative_bound_formula":"offset*sqrt2+orthosize/2-sqrt2*actualmeshminY","actual_camera_basis_columns":[[camera.basis.x.x,camera.basis.x.y,camera.basis.x.z],[camera.basis.y.x,camera.basis.y.y,camera.basis.y.z],[camera.basis.z.x,camera.basis.z.y,camera.basis.z.z]]}

func _preview_model_clone(entry: Dictionary,world: Node3D,casting: int) -> Node3D:
	var node:=entry["node"].duplicate() as Node3D
	node.name="Preview_"+String(entry["spec"]["id"])
	var meshes: Array[MeshInstance3D]=[]
	_meshes(node,meshes)
	for mesh in meshes:
		mesh.layers=1
		mesh.cast_shadow=casting
	world.add_child(node)
	return node

func _set_preview_cast(nodes: Array[Node3D],casting: int,visible: bool=true) -> void:
	for node in nodes:
		node.visible=visible
		var meshes: Array[MeshInstance3D]=[]
		_meshes(node,meshes)
		for mesh in meshes: mesh.cast_shadow=casting

func _image_rgba_sha(image: Image) -> String:
	var hash:=HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(image.get_data())
	return hash.finish().hex_encode()

func _ssaa_resample(raw: Image,logical_size: Vector2i) -> Image:
	assert(raw.get_size()==logical_size*VISUAL_SSAA_SCALE)
	var derived: Image=raw.duplicate() as Image
	# Spatial reconstruction of ONE unchanged native frame; no temporal
	# averaging, channel tolerance, frame blending or altered repeat gate.
	derived.resize(logical_size.x,logical_size.y,Image.INTERPOLATE_LANCZOS)
	return derived

func _ssaa_readback(viewport: SubViewport,logical_size: Vector2i,raw_path: String) -> Image:
	assert(viewport.msaa_3d==Viewport.MSAA_DISABLED)
	assert(viewport.size==logical_size*VISUAL_SSAA_SCALE)
	await _sync()
	var raw: Image=viewport.get_texture().get_image()
	raw.convert(Image.FORMAT_RGBA8)
	assert(raw.get_size()==viewport.size)
	assert(raw.save_png(raw_path)==OK)
	var derived: Image=_ssaa_resample(raw,logical_size)
	var camera: Camera3D=viewport.get_camera_3d()
	var basis: Basis=camera.transform.basis
	ssaa_capture_records.append({"raw_path":raw_path,"raw_png_sha256":FileAccess.get_sha256(raw_path),"raw_rgba_sha256":_image_rgba_sha(raw),"raw_canvas":[raw.get_width(),raw.get_height()],"logical_canvas":[logical_size.x,logical_size.y],"derived_rgba_sha256":_image_rgba_sha(derived),"actual_msaa_3d_enum":viewport.msaa_3d,"ssaa_scale":VISUAL_SSAA_SCALE,"resampling_method":"native Image.resize INTERPOLATE_LANCZOS on one raw RGBA8 frame; no temporal averaging/tolerance","camera_projection_map":"actual Camera3D.unproject_position /2 gives logical image point; camera orthographic size/basis unchanged","actual_camera":{"projection_enum":camera.projection,"orthographic_size":camera.size,"position":[camera.position.x,camera.position.y,camera.position.z],"basis_columns":[[basis.x.x,basis.x.y,basis.x.z],[basis.y.x,basis.y.y,basis.y.z],[basis.z.x,basis.z.y,basis.z.z]],"actual_native_pixels_per_meter":float(raw.get_height())/camera.size,"logical_pixels_per_meter":float(logical_size.y)/camera.size}})
	return derived

func _ssaa_record(raw_path: String) -> Dictionary:
	for record in ssaa_capture_records:
		if record["raw_path"]==raw_path: return record
	return {}

func _ssaa_raw_repeat_exact(a: String,b: String) -> bool:
	var first: Dictionary=_ssaa_record(a)
	var second: Dictionary=_ssaa_record(b)
	return not first.is_empty() and not second.is_empty() and first["raw_rgba_sha256"]==second["raw_rgba_sha256"]

func _preview_readback(viewport: SubViewport,raw_path: String="") -> Image:
	if raw_path.is_empty():
		raw_path=native_export_root+"ssaa_readback_%d_raw.png"%ssaa_readback_serial
		ssaa_readback_serial+=1
	return await _ssaa_readback(viewport,Vector2i(viewport.size/VISUAL_SSAA_SCALE),raw_path)

func _preview_shadow(on: Image,off: Image,body: Image) -> Dictionary:
	var result:=Image.create(on.get_width(),on.get_height(),false,Image.FORMAT_RGBA8)
	result.fill(Color.TRANSPARENT)
	var body_excluded:=0
	var pixels:=0
	for y in on.get_height():
		for x in on.get_width():
			var near_body:=false
			for dy in range(-2,3):
				for dx in range(-2,3):
					if body.get_pixel(clampi(x+dx,0,body.get_width()-1),clampi(y+dy,0,body.get_height()-1)).a>.01: near_body=true
			if near_body: body_excluded+=1;continue
			var a:=on.get_pixel(x,y)
			var b:=off.get_pixel(x,y)
			var luma_on:=Vector3(a.r,a.g,a.b).dot(Vector3(.2126,.7152,.0722))
			var luma_off:=Vector3(b.r,b.g,b.b).dot(Vector3(.2126,.7152,.0722))
			var darkening:=maxf((luma_off-luma_on)/maxf(luma_off,.0001),0.)
			if darkening<=.015: continue
			result.set_pixel(x,y,Color(0,0,0,minf(darkening,.85)))
			pixels+=1
	return {"image":result,"body_excluded_pixels":body_excluded,"outside_body_ground_pixels":pixels}

func _run_ninth_local_previews() -> void:
	# This isolated comparison contains actual native models; screenshots are
	# NOT runtime ground assets. Every runtime entity remains a separate body.
	source_design_only=true
	var prefix:="res://build/world_map_v14_ninth_native_preview_v7_witness/"
	native_export_root=prefix
	DirAccess.make_dir_recursive_absolute(prefix+"entities")
	var ignored:=FileAccess.open(prefix+".gdignore",FileAccess.WRITE)
	assert(ignored!=null)
	ignored.store_string("")
	ignored.close()
	_prepare_contract()
	if not native_surface.load_verified_sources():
		push_error(native_surface.last_error)
		await _finish_local_preview(1)
		return
	_source_images()
	_project_runtime_contract()
	terrain_mesh=_mesh()
	_prepare_native_models()
	_bind_native_ecology()
	assert(models.size()==native_specs.size())
	var visual_material:=_surface_material(0)
	var ecology_material:=_surface_material(4)
	var water_material:=_water_material()
	if visual_material==null or water_material==null or ecology_material==null:
		visual_material=null
		ecology_material=null
		water_material=null
		await _finish_local_preview(1)
		return
	assert(ResourceSaver.save(terrain_mesh,prefix+"actual_terrain_mesh.res")==OK)
	var rf:=FileAccess.open(prefix+"actual_height_grid.rf",FileAccess.WRITE)
	assert(rf!=null)
	rf.store_buffer(actual_height_image.get_data())
	rf.close()
	assert(topo.save_png(prefix+"source_topology.png")==OK)
	var profile_file:=FileAccess.open(prefix+"road_profile.rgf",FileAccess.WRITE)
	assert(profile_file!=null)
	profile_file.store_buffer(road_profile_image.get_data())
	profile_file.close()
	if tree_lod_mesh!=null:
		assert(ResourceSaver.save(tree_lod_mesh,prefix+"entities/tree_small02_native_hybrid.res")==OK)
		tree_lod_recipe["derived_mesh_path"]=prefix+"entities/tree_small02_native_hybrid.res"
		tree_lod_recipe["derived_mesh_sha256"]=FileAccess.get_sha256(prefix+"entities/tree_small02_native_hybrid.res")
	# Export individual representative poses as real transparent foreground
	# resources. Other instances have the same immutable mesh/material pose
	# cache but independent transforms, feet, collisions and sort lines.
	var representative_sources: Dictionary={}
	for entry in models:
		var spec: Dictionary=entry["spec"]
		var key: String=entry["pose_key"]
		var representative:=false
		if spec["source"]==ROCKFACE and spec["id"] in ["native_ridge_face_near","native_ridge_face_crest"]: representative=true
		elif spec["source"]==TREE and not representative_sources.has(key): representative=true
		elif spec["source"]==BOULDER and not representative_sources.has(BOULDER): representative=true
		if not representative: continue
		var body: Image=await _capture_native_entity(entry)
		if body==null or body.is_empty():
			visual_material=null
			ecology_material=null
			water_material=null
			push_error("Native representative body failed; preview stops with resource cleanup")
			await _finish_local_preview(1)
			return
		representative_sources[key]=true
		representative_sources[spec["source"]]=true
		preview_entity_records.append(JSON.parse_string(FileAccess.get_file_as_string(prefix+"entities/"+spec["id"]+".json")))
	var definitions: Array=[
		{"id":"north_ridge_components","center":Vector2(2190,700)},
		{"id":"central_forest_road","center":Vector2(3070,1230)},
		{"id":"south_shore_grove","center":Vector2(3200,2040)}]
	var cases: Array=[]
	var valid:=true
	for spec in definitions:
		var viewport:=SubViewport.new()
		viewport.msaa_3d=Viewport.MSAA_DISABLED
		viewport.size=Vector2i(1536,1024)*VISUAL_SSAA_SCALE
		viewport.own_world_3d=true
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var world:=Node3D.new()
		viewport.add_child(world)
		var environment:=WorldEnvironment.new()
		environment.environment=native_surface.environment()
		world.add_child(environment)
		var terrain:=MeshInstance3D.new()
		terrain.mesh=terrain_mesh
		terrain.material_override=visual_material
		terrain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		world.add_child(terrain)
		var water:=MeshInstance3D.new()
		water.mesh=_mesh(true)
		water.position.y=NINTH.WATER_Y
		water.material_override=water_material
		water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(water)
		var light:=DirectionalLight3D.new()
		light.rotation_degrees=Vector3(-55,-34,0)
		light.light_energy=NINTH.DIRECT
		light.shadow_enabled=true
		light.shadow_bias=.02
		light.shadow_normal_bias=1.
		light.directional_shadow_max_distance=60.
		light.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
		world.add_child(light)
		var focus:=_point(spec["center"],true)
		var camera:=Camera3D.new()
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL
		camera.size=10.
		camera.position=focus+Vector3(0,FULL_CAMERA_OFFSET,FULL_CAMERA_OFFSET)
		world.add_child(camera)
		camera.look_at(focus)
		camera.current=true
		var reference:=Camera3D.new()
		reference.projection=camera.projection
		reference.size=camera.size
		reference.position=focus+Vector3(0,36,36)
		world.add_child(reference)
		reference.look_at(focus)
		var comparison_nodes: Array[Node3D]=[]
		var comparison_models: Array=[]
		# Native components selected by their true transformed 3D vertices,
		# not tiny foot-only rectangles. Margin also retains nearby casters.
		for entry in models:
			var bounds: AABB=entry["bounds"]
			var ground: Vector3=entry["ground"]
			var contact: Vector3=entry["contact"]
			var projected_bounds:=Rect2()
			var first:=true
			for corner in 8:
				var pixel:=camera.unproject_position(ground+bounds.get_endpoint(corner)-contact)/VISUAL_SSAA_SCALE
				if first: projected_bounds=Rect2(pixel,Vector2.ZERO);first=false
				else: projected_bounds=projected_bounds.expand(pixel)
			if not projected_bounds.intersects(Rect2(-350,-350,2236,1724)): continue
			comparison_nodes.append(_preview_model_clone(entry,world,GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY))
			comparison_models.append({"id":entry["spec"]["id"],"source":entry["spec"]["source"],"source_sha256":FileAccess.get_sha256(entry["spec"]["source"]),"source_foot_px":_pair(entry["spec"]["foot"]),"world_foot_px":_pair(entry["foot"]),"ground_m":[ground.x,ground.y,ground.z],"model_position_m":[entry["node"].position.x,entry["node"].position.y,entry["node"].position.z],"scale":entry["spec"]["scale"],"yaw":entry["spec"]["yaw"],"source_variant":entry["spec"]["variant"],"collision_size_px":_pair(entry["collision_size"]),"collision_center_px":_pair(entry["collision_center"]),"blocking":entry["spec"]["blocking"],"depth_y":entry["foot"].y,"actual_transformed_bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z],"contact_m":[contact.x,contact.y,contact.z],"projected_visual_bounds":[projected_bounds.position.x,projected_bounds.position.y,projected_bounds.size.x,projected_bounds.size.y]})
		var ground_on: Image=await _preview_readback(viewport,prefix+String(spec["id"])+"_terrain_pbr_raw_ssaa2.png")
		var ground_repeat: Image=await _preview_readback(viewport,prefix+String(spec["id"])+"_terrain_repeat_raw_ssaa2.png")
		_set_preview_cast(comparison_nodes,GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,false)
		var ground_off: Image=await _preview_readback(viewport,prefix+String(spec["id"])+"_terrain_shadow_off_raw_ssaa2.png")
		_set_preview_cast(comparison_nodes,GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
		var scene: Image=await _preview_readback(viewport,prefix+String(spec["id"])+"_scene_components_raw_ssaa2.png")
		var scene_repeat: Image=await _preview_readback(viewport,prefix+String(spec["id"])+"_scene_repeat_raw_ssaa2.png")
		terrain.visible=false
		water.visible=false
		viewport.transparent_bg=true
		environment.environment=native_surface.environment(true)
		_set_preview_cast(comparison_nodes,GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
		var body_union: Image=await _preview_readback(viewport,prefix+String(spec["id"])+"_sourcebody_union_raw_ssaa2.png")
		var body_repeat: Image=await _preview_readback(viewport,prefix+String(spec["id"])+"_sourcebody_repeat_raw_ssaa2.png")
		var body_valid:=body_union.detect_alpha()!=Image.ALPHA_NONE and body_union.get_used_rect().has_area() and body_union.get_data()==body_repeat.get_data()
		_set_preview_cast(comparison_nodes,GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,false)
		viewport.transparent_bg=false
		environment.environment=native_surface.environment()
		environment.environment.background_mode=Environment.BG_COLOR
		environment.environment.background_color=Color.BLACK
		terrain.visible=true
		terrain.material_override=ecology_material
		var weights: Image=await _preview_readback(viewport,prefix+String(spec["id"])+"_ecology_weights_raw_ssaa2.png")
		var weights_repeat: Image=await _preview_readback(viewport,prefix+String(spec["id"])+"_ecology_repeat_raw_ssaa2.png")
		var ecology_probes: Array=[]
		var core_valid:=true
		if spec["id"]=="central_forest_road":
			for offset in [Vector2(-40,0),Vector2.ZERO,Vector2(40,0),Vector2(0,-40),Vector2(0,40)]:
				var source: Vector2=Vector2(3070,1310)+offset
				var pixel:=Vector2i(camera.unproject_position(_point(source))/VISUAL_SSAA_SCALE)
				assert(Rect2i(Vector2i.ZERO,weights.get_size()).has_point(pixel))
				var weight:=weights.get_pixelv(pixel).r
				core_valid=core_valid and weight>=.85
				ecology_probes.append({"source_px":_pair(source),"actual_camera_pixel":[pixel.x,pixel.y],"encoded_forest_red":weight,"expected_minimum":.85,"provenance":"actual shared habitat shader raster, not a synthetic painted diagnostic"})
		var raw_repeat_exact: bool=_ssaa_raw_repeat_exact(prefix+String(spec["id"])+"_terrain_pbr_raw_ssaa2.png",prefix+String(spec["id"])+"_terrain_repeat_raw_ssaa2.png") and _ssaa_raw_repeat_exact(prefix+String(spec["id"])+"_scene_components_raw_ssaa2.png",prefix+String(spec["id"])+"_scene_repeat_raw_ssaa2.png") and _ssaa_raw_repeat_exact(prefix+String(spec["id"])+"_sourcebody_union_raw_ssaa2.png",prefix+String(spec["id"])+"_sourcebody_repeat_raw_ssaa2.png") and _ssaa_raw_repeat_exact(prefix+String(spec["id"])+"_ecology_weights_raw_ssaa2.png",prefix+String(spec["id"])+"_ecology_repeat_raw_ssaa2.png")
		var exact:=raw_repeat_exact and ground_on.get_data()==ground_repeat.get_data() and scene.get_data()==scene_repeat.get_data() and weights.get_data()==weights_repeat.get_data()
		var shadow:=_preview_shadow(ground_on,ground_off,body_union)
		var shadow_image: Image=shadow["image"]
		var min_y:=INF
		var nearest:=INF
		var furthest:=-INF
		var projection_error:=0.
		var vertices: PackedVector3Array=terrain_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var image_rect:=Rect2(Vector2.ZERO,Vector2(viewport.size))
		for vertex in vertices:
			min_y=minf(min_y,vertex.y)
			projection_error=maxf(projection_error,camera.unproject_position(vertex).distance_to(reference.unproject_position(vertex))/VISUAL_SSAA_SCALE)
			if not image_rect.has_point(camera.unproject_position(vertex)): continue
			var depth:=-(camera.global_transform.affine_inverse()*vertex).z
			nearest=minf(nearest,depth)
			furthest=maxf(furthest,depth)
		var conservative_far:=FULL_CAMERA_OFFSET*sqrt(2.)+camera.size*.5-sqrt(2.)*min_y
		var covered:=conservative_far<60. and nearest>camera.near and projection_error<.02
		var outputs: Dictionary={"terrain_pbr":ground_on,"terrain_repeat":ground_repeat,"terrain_shadow_off":ground_off,"scene_components":scene,"scene_repeat":scene_repeat,"sourcebody_union":body_union,"sourcebody_repeat":body_repeat,"ecology_weights":weights,"ecology_repeat":weights_repeat,"ground_shadow":shadow_image}
		var paths: Dictionary={}
		var saved:=true
		for key in outputs:
			var path: String=prefix+spec["id"]+"_"+key+".png"
			saved=saved and outputs[key].save_png(path)==OK
			paths[key]={"path":path,"sha256":FileAccess.get_sha256(path)}
		var case_valid: bool=exact and covered and saved and body_valid and core_valid and shadow["outside_body_ground_pixels"]>0 and not comparison_nodes.is_empty()
		valid=valid and case_valid
		var basis:=camera.transform.basis
		cases.append({"id":spec["id"],"source_center_px":_pair(spec["center"]),"canvas":[1536,1024],"outputs":paths,"repeat_exact":exact,"sourcebody_valid":body_valid,"actual_msaa_3d_enum":viewport.msaa_3d,"ssaa_scale":VISUAL_SSAA_SCALE,"raw_repeat_exact":raw_repeat_exact,"actual_canvas":[viewport.size.x,viewport.size.y],"camera":{"actual_canvas":[viewport.size.x,viewport.size.y],"logical_canvas":[1536,1024],"projection_to_logical_divisor":VISUAL_SSAA_SCALE,"orthographic":true,"projection_enum":camera.projection,"size":camera.size,"position":[camera.position.x,camera.position.y,camera.position.z],"look_at":[focus.x,focus.y,focus.z],"basis_columns":[[basis.x.x,basis.x.y,basis.x.z],[basis.y.x,basis.y.y,basis.y.z],[basis.z.x,basis.z.y,basis.z.z]],"pixels_per_meter":102.4*VISUAL_SSAA_SCALE,"logical_pixels_per_meter":102.4},"actual_visible_receiver_depth_range":[nearest,furthest],"conservative_far_bound":conservative_far,"receiver_covered":covered,"projection_error_to_reference36_px":projection_error,"native_self_shadow":"ON common real mesh; not disabled to remove volume","actual_native_canvas":[viewport.size.x,viewport.size.y],"logical_projection_from_actual":"Camera3D.unproject_position/2","outside_body_ground_pixels":shadow["outside_body_ground_pixels"],"body_excluded_pixels":shadow["body_excluded_pixels"],"forest_core_probes":ecology_probes,"forest_core_valid":core_valid,"native_entities":comparison_models,"saved":saved,"valid":case_valid})
		viewport.queue_free()
		await process_frame
	_json(prefix+"result.json",{"status":"LOCAL_PREVIEW_TECHNICAL_PASS" if valid else "LOCAL_PREVIEW_TECHNICAL_FAIL","visual_approved":false,"production_approved":false,"whole_map_capture":false,"no_production_OUT_write":true,"screenshots_with_components_are_not_runtime_terrain_assets":true,"actual_height_grid_path":prefix+"actual_height_grid.rf","actual_terrain_mesh_path":prefix+"actual_terrain_mesh.res","actual_water_height":"same returned Float32 RF and exact a,b,c/b,d,c affine triangles","source_profile_path":prefix+"road_profile.rgf","material_sources":native_surface.audit,"builder_path":get_script().resource_path,"builder_sha256":FileAccess.get_sha256(get_script().resource_path),"helper_path":native_surface.get_script().resource_path,"helper_sha256":FileAccess.get_sha256(native_surface.get_script().resource_path),"illumination":{"ambient":NINTH.AMBIENT,"direct":NINTH.DIRECT,"light_rotation":[-55,-34,0],"shadow_normal_bias":1.,"shadow_bias":.02,"shadow_max_distance":60.},"cases":cases,"independent_foreground_entity_exports":preview_entity_records,"actual_canopy_ecology_regions":_canopy_evidence_records(),"actual_native_material_derivatives":native_material_recipes,"visual_msaa_3d_samples":0,"visual_ssaa_scale":VISUAL_SSAA_SCALE,"raw_ssaa_evidence":ssaa_capture_records,"compiler_gates":shader_gate_results})
	print("[WorldV14Ninth] three representative native component views valid=",valid," whole visual/Field NOT tested")
	# Coroutine-local ShaderMaterial references must be dropped too.
	visual_material=null
	ecology_material=null
	water_material=null
	await _finish_local_preview(0 if valid else 1)

func _free_capture_model_nodes() -> void:
	for entry in models:
		if is_instance_valid(entry["node"]): entry["node"].free()
	models.clear()
	for template in model_templates.values():
		if is_instance_valid(template): template.free()
	model_templates.clear()
	for pose in pose_cache.values():
		if is_instance_valid(pose["prototype"]): pose["prototype"].free()
	pose_cache.clear()

func _finish_local_preview(exit_code: int) -> void:
	# This dedicated SceneTree owns every preview viewport; fail paths may
	# still have a sourcebody/world viewport attached. Queue them before release.
	for child in root.get_children():
		if child is SubViewport: child.queue_free()
	_free_capture_model_nodes()
	_release_capture_resource_refs()
	for frame in 16: await process_frame
	await RenderingServer.frame_post_draw
	var cursors_released: bool=_cursor_release_audit()
	quit(exit_code if cursors_released else 1)

func _release_tool_cursors() -> void:
	# Tool-process teardown only: CursorManager and normal game UI are unchanged.
	# DisplayServer keeps the custom-cursor textures alive unless Input releases
	# its three handles before the autoload's corresponding Texture2D references.
	Input.set_custom_mouse_cursor(null,Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_POINTING_HAND)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_WAIT)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	var manager: Node=root.get_node_or_null("CursorManager")
	if manager==null: return
	for field: String in ["_arrow","_hand","_wait"]:
		var texture: Texture2D=manager.get(field)
		if texture!=null:
			tool_cursor_release_refs.append({"field":field,"path":texture.resource_path,"class":texture.get_class(),"rid_before_release":str(texture.get_rid()),"weak":weakref(texture)})
		manager.set(field,null)
	manager.set("_is_waiting",false)

func _cursor_release_audit() -> bool:
	var records: Array=[]
	var released: bool=true
	for tracked in tool_cursor_release_refs:
		var alive: bool=tracked["weak"].get_ref()!=null
		released=released and not alive
		records.append({"field":tracked["field"],"path":tracked["path"],"class":tracked["class"],"rid_before_release":tracked["rid_before_release"],"weak_alive_after_natural_frames":alive})
	var path: String="res://build/world_map_v14_ninth_v7_full_cursor_release.json"
	if source_design_only:
		if native_export_root!=OUT: path=native_export_root+"cursor_release.json"
		else: path="res://build/world_map_v14_"+source_plan_tag+"_cursor_release.json"
	_json(path,{"status":"TOOL_CURSOR_RELEASED" if released else "TOOL_CURSOR_REFERENCE_STILL_ALIVE","tool_only":true,"global_cursor_manager_source_unchanged":true,"displayserver_handles_reset":["ARROW","POINTING_HAND","WAIT"],"autoload_fields_released":["_arrow","_hand","_wait"],"original_48px_rgba_mipmap_chain_bytes_each":12280,"records":records,"all_tracked_weakrefs_dead":released,"executed_builder_sha256":FileAccess.get_sha256(get_script().resource_path)})
	tool_cursor_release_refs.clear()
	if not released: push_error("[WorldV14Ninth] tool custom-cursor reference survives explicit teardown")
	return released

func _release_capture_resource_refs() -> void:
	_release_tool_cursors()
	# Viewports/models have been queued/freed before this hook. Drop every
	# resource-holding cache before natural-frame cleanup; never suppress RID errors.
	native_material_cache.clear()
	native_material_recipes.clear()
	preview_entity_records.clear()
	ssaa_capture_records.clear()
	sprite_pose_cache.clear()
	surface_materials.clear()
	compiled_water_material=null
	actual_height_texture=null
	actual_height_image=null
	road_profile_texture=null
	road_profile_image=null
	topology_texture=null
	terrain_mesh=null
	tree_lod_mesh=null
	if native_surface!=null:
		native_surface.textures.clear()
		native_surface.sky=null
		native_surface=null

func _run_ninth_preflight() -> void:
	# Isolated shader fixture only; old/full OUT cannot be written here.
	_prepare_contract()
	if not native_surface.load_verified_sources():
		push_error(native_surface.last_error)
		await _finish_local_preview(1)
		return
	actual_height_image=Image.create(HEIGHT_COLS+1,HEIGHT_ROWS+1,false,Image.FORMAT_RF)
	actual_height_image.fill(Color(-.5,0,0,1))
	actual_height_texture=ImageTexture.create_from_image(actual_height_image)
	await _shader_preflight()

func _sync() -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw

func _shader_preflight() -> void:
	var prefix:="res://build/world_map_v14_ninth_v7_witness_material_preflight/"
	DirAccess.make_dir_recursive_absolute(prefix)
	var invalid:=Shader.new()
	invalid.code="shader_type spatial;uniform float gate=1.;void fragment(){vec2 q=mat2(1.,0.,0.,1.)*UV;ALBEDO=vec3(q,gate);}"
	var rejected:=not _shader_compiled(invalid,["gate"],"intentional_invalid_mat2_control")
	var dummy:=Image.create(16,16,false,Image.FORMAT_RGBA8)
	dummy.fill(Color(1.,.3,.7,1.))
	topology_texture=ImageTexture.create_from_image(dummy)
	var cases: Array[Dictionary]=[]
	var all_valid:=rejected
	for mode in 4:
		var material: ShaderMaterial=_surface_material(mode) if mode<3 else _water_material()
		if material==null:
			all_valid=false
			break
		var view:=SubViewport.new()
		view.size=Vector2i(384,256)
		view.own_world_3d=true
		view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		root.add_child(view)
		var world:=Node3D.new()
		view.add_child(world)
		var environment:=WorldEnvironment.new()
		environment.environment=native_surface.environment()
		environment.environment.background_mode=Environment.BG_COLOR
		environment.environment.background_color=Color.BLACK
		world.add_child(environment)
		var plane:=MeshInstance3D.new()
		var plane_mesh:=PlaneMesh.new()
		plane_mesh.size=Vector2(10,10)
		plane.mesh=plane_mesh
		plane.material_override=material
		world.add_child(plane)
		var light:=DirectionalLight3D.new()
		light.rotation_degrees=Vector3(-55,-34,0)
		light.light_energy=NINTH.DIRECT
		world.add_child(light)
		var camera:=Camera3D.new()
		camera.projection=Camera3D.PROJECTION_ORTHOGONAL
		camera.size=10.
		camera.position=Vector3(0,12,12)
		world.add_child(camera)
		camera.look_at(Vector3.ZERO)
		camera.current=true
		await _sync()
		var frame:=view.get_texture().get_image()
		frame.convert(Image.FORMAT_RGBA8)
		var pixel:=frame.get_pixel(192,128)
		var expected:=pixel.r<.9 and pixel.g<.9 and pixel.b<.9
		if mode==1: expected=pixel.r>.95 and pixel.g>.95 and pixel.b>.95
		if mode==2: expected=pixel.r>.60 and pixel.r<.95 and absf(pixel.r-pixel.g)<.01 and absf(pixel.r-pixel.b)<.01
		var water_control: Dictionary={}
		if mode==3:
			# Actual wet RF must shade a nonempty water fragment, not merely
			# match a black-background upper bound after discarding everything.
			expected=expected and pixel.g>.015 and pixel.b>.02 and pixel.a>.95
			var wet_hash:=HashingContext.new()
			wet_hash.start(HashingContext.HASH_SHA256)
			wet_hash.update(actual_height_image.get_data())
			var wet_sha:=wet_hash.finish().hex_encode()
			var dry_image:=Image.create(HEIGHT_COLS+1,HEIGHT_ROWS+1,false,Image.FORMAT_RF)
			dry_image.fill(Color(0,0,0,1))
			var dry_texture:=ImageTexture.create_from_image(dry_image)
			material.set_shader_parameter("actual_height_rf",dry_texture)
			await _sync()
			var dry_frame:=view.get_texture().get_image()
			dry_frame.convert(Image.FORMAT_RGBA8)
			var dry_pixel:=dry_frame.get_pixel(192,128)
			var dry_discard:=maxf(dry_pixel.r,maxf(dry_pixel.g,dry_pixel.b))<.001
			var dry_saved:=dry_frame.save_png(prefix+"water_dry_rf_discard.png")==OK
			var dry_hash:=HashingContext.new()
			dry_hash.start(HashingContext.HASH_SHA256)
			dry_hash.update(dry_image.get_data())
			var wet_file:=FileAccess.open(prefix+"water_wet_fixture.rf",FileAccess.WRITE)
			var dry_file:=FileAccess.open(prefix+"water_dry_fixture.rf",FileAccess.WRITE)
			var fixture_saved:=wet_file!=null and dry_file!=null
			if fixture_saved:
				wet_file.store_buffer(actual_height_image.get_data())
				dry_file.store_buffer(dry_image.get_data())
				wet_file.close()
				dry_file.close()
			water_control={"wet_rf_meters":-.5,"wet_rf_sha256":wet_sha,"wet_rgb_nonblack":expected,"dry_rf_meters":0.,"dry_rf_sha256":dry_hash.finish().hex_encode(),"dry_center_rgba":[dry_pixel.r,dry_pixel.g,dry_pixel.b,dry_pixel.a],"dry_actual_fragment_discard":dry_discard,"actual_rf_bytes_saved":fixture_saved,"same_native_camera_material_only_RF_changes":true}
			expected=expected and dry_discard and dry_saved and fixture_saved
			material.set_shader_parameter("actual_height_rf",actual_height_texture)
		var saved:=frame.save_png(prefix+"mode_%d.png"%mode)==OK
		all_valid=all_valid and expected and saved
		cases.append({"mode":mode,"compiled":true,"center_rgba":[pixel.r,pixel.g,pixel.b,pixel.a],"expected_fragment_output":expected,"saved":saved,"water_wet_dry_control":water_control})
		view.queue_free()
		await process_frame
	_json(prefix+"result.json",{"status":"MATERIAL_PREFLIGHT_PASS" if all_valid else "MATERIAL_PREFLIGHT_FAIL","intentional_invalid_shader_rejected":rejected,"compiler_gates":shader_gate_results,"actual_gpu_cases":cases,"full_world_capture":false,"sync":"8 frames and frame_post_draw"})
	if not all_valid:
		_fail_candidate("Native shader preflight failed; no full world capture started")
		return
	print("[WorldV14] MATERIAL_PREFLIGHT_PASS: invalid shader rejected; all four actual GPU fragment outputs match")
	await _finish_local_preview(0)

func _meshes(node: Node,result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D: result.append(node)
	for child in node.get_children(): _meshes(child,result)

func _derived_tree_mesh(source: ArrayMesh) -> ArrayMesh:
	if tree_lod_mesh!=null: return tree_lod_mesh
	var importer:=ImporterMesh.new()
	for surface in source.get_surface_count():
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,source.surface_get_arrays(surface),[],{},source.surface_get_material(surface))
	importer.generate_lods(60.,60.,[])
	var result:=ArrayMesh.new()
	var records: Array=[]
	for surface in source.get_surface_count():
		if surface!=1 and importer.get_surface_lod_count(surface)<=2: return null
		var arrays:=source.surface_get_arrays(surface).duplicate(true)
		# Thin leaf cards cannot share branch/trunk simplification. Controlled
		# same-camera captures retained only56.4% crown at blanket LOD2; this
		# mixed stream retains99.30% while safely simplifying opaque wood.
		var selected: int=-1 if surface==1 else 2
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if selected<0 else importer.get_surface_lod_indices(surface,selected)
		arrays[Mesh.ARRAY_INDEX]=indices
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		result.surface_set_material(surface,source.surface_get_material(surface))
		var hashing:=HashingContext.new()
		hashing.start(HashingContext.HASH_SHA256)
		hashing.update(indices.to_byte_array())
		records.append({"surface":surface,"selected_surface":surface,"index_source":"source_lod0" if selected<0 else "native_generated_lod","lod_index":selected,"lod_distance":0. if selected<0 else importer.get_surface_lod_size(surface,selected),"actual_triangles":indices.size()/3,"indices_sha256":hashing.finish().hex_encode(),"index_byte_width":4,"semantic":"original leaf cards" if surface==1 else "branch" if surface==0 else "trunk","recipe_method":"original source indices" if selected<0 else "ImporterMesh.generate_lods(60,60,[])","normal_storage":"source decoded normals re-encoded by native ArrayMesh storage; compare with a same-native-packing control, not raw byte equality"})
	tree_lod_recipe={"method":"per-surface original leaf indices and native generated branch/trunk LOD2; explicit source arrays then native ArrayMesh encoding","source_sha256":FileAccess.get_sha256(TREE),"original_triangles":2062487,"actual_total_triangles":1954530,"surfaces":records,"same_mesh_for_alpha_and_cast":true,"controlled_capture_evidence":"res://build/world_map_v14_tree_hybrid_compare/result.json","controlled_evidence_scope":"historical fifth-light raw leaf+LOD2 wood fixture only; ninth body and ground cast require new actual capture, not claimed by this proof","controlled_crown_alpha_retention":.99297056955325,"not_an_entire_map_visual_pass":true}
	tree_lod_mesh=result
	return result


# Pure model-geometry survey, only performed in an explicitly authorized source
# forecast/capture. No import cache dependence for the newly copied RockFace.
# Geometry/source image bytes remain unchanged. This shared material recipe
# is applied once to each immutable native pose and reused by alpha AND caster.
func _apply_native_material_derivative(mesh: MeshInstance3D,source: String) -> Array:
	var raw: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
	var raw_materials: Array=raw.get("materials",[])
	var recipes: Array=[]
	for surface in mesh.mesh.get_surface_count():
		var original:=mesh.get_active_material(surface) as BaseMaterial3D
		assert(original!=null,"Native material must expose explicit BaseMaterial3D recipe")
		var material_index:=-1
		for index in raw_materials.size():
			if raw_materials[index].get("name","")==original.resource_name: material_index=index;break
		if material_index<0 and surface<raw_materials.size(): material_index=surface
		var original_record: Dictionary=raw_materials[material_index] if material_index>=0 else {}
		var key:=source+":"+str(material_index)+":"+original.resource_name
		var derivative: BaseMaterial3D
		var record: Dictionary
		if native_material_cache.has(key):
			derivative=native_material_cache[key]["material"]
			record=native_material_cache[key]["record"].duplicate(true)
		else:
			derivative=original.duplicate() as BaseMaterial3D
			var original_alpha: String=String(original_record.get("alphaMode","OPAQUE"))
			var original_transparency: int=original.transparency
			if original_alpha=="BLEND":
				derivative.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				derivative.alpha_scissor_threshold=.40
				derivative.alpha_antialiasing_mode=BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
				derivative.alpha_antialiasing_edge=.30
			derivative.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			var texture_records: Array=[]
			for slot in [BaseMaterial3D.TEXTURE_ALBEDO,BaseMaterial3D.TEXTURE_NORMAL,BaseMaterial3D.TEXTURE_ROUGHNESS,BaseMaterial3D.TEXTURE_METALLIC,BaseMaterial3D.TEXTURE_AMBIENT_OCCLUSION]:
				var texture: Texture2D=original.get_texture(slot)
				if texture==null: continue
				var image:=texture.get_image()
				assert(image!=null and not image.is_empty())
				if image.is_compressed(): assert(image.decompress()==OK)
				var hash:=HashingContext.new()
				hash.start(HashingContext.HASH_SHA256)
				hash.update(image.get_data())
				var before_hash: String=hash.finish().hex_encode()
				assert(image.generate_mipmaps()==OK and image.get_mipmap_count()>0)
				derivative.set_texture(slot,ImageTexture.create_from_image(image))
				texture_records.append({"slot_enum":slot,"source_texture_resource_path":texture.resource_path,"decoded_before_mipmap_sha256":before_hash,"actual_mipmap_count":image.get_mipmap_count(),"size":[image.get_width(),image.get_height()],"mip_method":"actual native Image.generate_mipmaps on decoded immutable source tex; external raw file unchanged"})
			record={"source_gltf":source,"source_gltf_sha256":FileAccess.get_sha256(source),"source_material_index":material_index,"source_material_name":original_record.get("name",original.resource_name),"source_alpha_mode":original_alpha,"source_alpha_cutoff":original_record.get("alphaCutoff",.5),"original_godot_transparency_enum":original_transparency,"actual_godot_transparency_enum":derivative.transparency,"actual_cull_mode_enum":derivative.cull_mode,"actual_shading_mode_enum":derivative.shading_mode,"actual_texture_filter_enum":derivative.texture_filter,"actual_alpha_scissor_threshold":derivative.alpha_scissor_threshold,"actual_alpha_antialiasing_mode_enum":derivative.alpha_antialiasing_mode,"actual_alpha_antialiasing_edge":derivative.alpha_antialiasing_edge,"textures":texture_records,"external_bytes_unchanged":true,"geometry_unchanged":true,"same_material_for_sourcebody_and_ground_caster":true,"recipe":"native duplicate; only BLEND becomes alpha_scissor .40/A2C .30; real mipmaps and anisotropic filter; MSAA0 native2x SSAA visual only"}
			native_material_cache[key]={"material":derivative,"record":record}
			native_material_recipes.append(record)
		mesh.set_surface_override_material(surface,derivative)
		record["actual_surface"]=surface
		var arrays:=mesh.mesh.surface_get_arrays(surface)
		var hash:=HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(arrays[Mesh.ARRAY_INDEX].to_byte_array())
		record["actual_draw_indices_sha256"]=hash.finish().hex_encode()
		record["actual_draw_triangle_count"]=arrays[Mesh.ARRAY_INDEX].size()/3
		recipes.append(record)
	return recipes

func _survey_component_bounds() -> void:
	component_blueprints=ROCK_COLLISION_BLUEPRINTS.duplicate(true)
	for spec in native_specs:
		if spec["source"]!=ROCKFACE and not String(spec["id"]).begins_with("native_ridge_base_"): continue
		var key: String="%s:%d:%.4f:%.4f"%[spec["source"],spec["variant"],spec["yaw"],spec["scale"]]
		if not pose_cache.has(key):
			var document:=GLTFDocument.new()
			var state:=GLTFState.new()
			assert(document.append_from_file(spec["source"],state)==OK,"Registered native RockFace parse failed")
			var imported:=document.generate_scene(state) as Node3D
			assert(imported!=null)
			var meshes: Array[MeshInstance3D]=[]
			_meshes(imported,meshes)
			assert(meshes.size()==1,"Registered independent solid has one actual mesh")
			var mesh:=meshes[0].duplicate() as MeshInstance3D
			mesh.transform=Transform3D.IDENTITY
			for child in mesh.get_children(): child.free()
			var model:=Node3D.new()
			model.rotation_degrees.y=spec["yaw"]
			model.scale=Vector3.ONE*float(spec["scale"])
			var material_recipe: Array=_apply_native_material_derivative(mesh,spec["source"])
			model.add_child(mesh)
			var points:=PackedVector3Array()
			var bounds:=AABB()
			var first:=true
			for surface in mesh.mesh.get_surface_count():
				var arrays:=mesh.mesh.surface_get_arrays(surface)
				var used: Dictionary={}
				for index in arrays[Mesh.ARRAY_INDEX]: used[index]=true
				for index in used:
					var point: Vector3=model.transform*arrays[Mesh.ARRAY_VERTEX][index]
					points.append(point)
					if first: bounds=AABB(point,Vector3.ZERO);first=false
					else: bounds=bounds.expand(point)
			var support:=AABB()
			first=true
			for point in points:
				if point.y>bounds.position.y+bounds.size.y*.06: continue
				if first: support=AABB(point,Vector3.ZERO);first=false
				else: support=support.expand(point)
			assert(not first)
			var contact:=Vector3(support.get_center().x,bounds.position.y,support.end.z)
			pose_cache[key]={"prototype":model,"bounds":bounds,"contact":contact,"vertex_count":points.size(),"source_mesh_node":String(mesh.name),"material_recipe":material_recipe,"source_import_method":"GLTFDocument raw scene"}
			imported.free()
		var measured: Dictionary=pose_cache[key]
		var bounds: AABB=measured["bounds"]
		var contact: Vector3=measured["contact"]
		component_blueprints[spec["id"]]=[(bounds.get_center().x-contact.x)*SIZE.x/WORLD.x,(bounds.get_center().z-contact.z)*SIZE.y/WORLD.y,bounds.size.x*SIZE.x/WORLD.x,bounds.size.z*SIZE.y/WORLD.y]

func _bind_native_ecology() -> void:
	var crowns: Array[Dictionary]=[]
	for entry in models:
		if entry["spec"]["source"]!=TREE: continue
		var bounds: AABB=entry["bounds"]
		var contact: Vector3=entry["contact"]
		var center: Vector2=entry["spec"]["foot"]+Vector2((bounds.get_center().x-contact.x)*SIZE.x/WORLD.x,(bounds.get_center().z-contact.z)*SIZE.y/WORLD.y)
		var radius:=Vector2(bounds.size.x*SIZE.x/WORLD.x,bounds.size.z*SIZE.y/WORLD.y)*.55
		crowns.append({"id":entry["spec"]["id"],"center":center,"radius":radius,"basis":"actual drawn crown XZ bounds; visual soil selector, never full crown collider"})
	native_surface.set_canopy_regions(crowns)
	# Habitat code includes these actual transforms; cached old shaders invalid.
	surface_materials.clear()

func _prepare_native_models() -> void:
	for spec in native_specs:
		var pose_key: String="%s:%d:%.4f:%.4f"%[spec["source"],spec["variant"],spec["yaw"],spec["scale"]]
		var model: Node3D
		var bounds: AABB
		var contact: Vector3
		var vertex_count: int
		var source_mesh_node: String
		var material_recipe: Array=[]
		var import_method: String
		if pose_cache.has(pose_key):
			var pose: Dictionary=pose_cache[pose_key]
			model=pose["prototype"].duplicate() as Node3D
			bounds=pose["bounds"]
			contact=pose["contact"]
			vertex_count=pose["vertex_count"]
			source_mesh_node=pose["source_mesh_node"]
			material_recipe=pose["material_recipe"]
			import_method=pose["source_import_method"]
		else:
			var imported: Node3D
			if model_templates.has(spec["source"]):
				imported=model_templates[spec["source"]]
			elif spec["source"] in [PINE,TREE,ROCKFACE]:
				var document:=GLTFDocument.new()
				var state:=GLTFState.new()
				assert(document.append_from_file(spec["source"],state)==OK)
				imported=document.generate_scene(state) as Node3D
			else:
				imported=(load(spec["source"]) as PackedScene).instantiate()
			model_templates[spec["source"]]=imported
			var meshes: Array[MeshInstance3D]=[]
			_meshes(imported,meshes)
			model=Node3D.new()
			model.rotation_degrees.y=float(spec["yaw"])
			model.scale=Vector3.ONE*float(spec["scale"])
			var mesh: MeshInstance3D=meshes[int(spec["variant"])].duplicate()
			if spec["source"]==TREE:
				mesh.mesh=_derived_tree_mesh(mesh.mesh as ArrayMesh)
				assert(mesh.mesh!=null)
			mesh.transform=Transform3D.IDENTITY
			for child in mesh.get_children(): child.free()
			material_recipe=_apply_native_material_derivative(mesh,spec["source"])
			import_method="GLTFDocument raw scene" if spec["source"] in [PINE,TREE,ROCKFACE] else "Godot engine imported PackedScene"
			model.add_child(mesh)
			bounds=AABB()
			var vertices:=PackedVector3Array()
			var first:=true
			for surface in mesh.mesh.get_surface_count():
				var arrays:=mesh.mesh.surface_get_arrays(surface)
				var used: Dictionary={}
				for index in arrays[Mesh.ARRAY_INDEX]: used[index]=true
				for index in used:
					var vertex: Vector3=arrays[Mesh.ARRAY_VERTEX][index]
					var v: Vector3=model.transform*vertex
					vertices.append(v)
					if first: bounds=AABB(v,Vector3.ZERO);first=false
					else: bounds=bounds.expand(v)
			var support:=AABB()
			first=true
			for v in vertices:
				if v.y>bounds.position.y+bounds.size.y*.06: continue
				if first: support=AABB(v,Vector3.ZERO);first=false
				else: support=support.expand(v)
			assert(not first)
			contact=Vector3(support.get_center().x,bounds.position.y,support.end.z)
			vertex_count=vertices.size()
			source_mesh_node=String(mesh.name)
			pose_cache[pose_key]={"prototype":model.duplicate(),"bounds":bounds,"contact":contact,"vertex_count":vertex_count,"source_mesh_node":source_mesh_node,"material_recipe":material_recipe,"source_import_method":import_method}
		var ground:=_point(spec["foot"])
		model.position=ground-contact
		var foot: Vector2=projected(spec["foot"])
		var collider:=Vector2(bounds.size.x*SIZE.x/WORLD.x,bounds.size.z*SIZE.y/WORLD.y)
		var collision_center:=foot+Vector2((bounds.get_center().x-contact.x)*SIZE.x/WORLD.x,(bounds.get_center().z-contact.z)*SIZE.y/WORLD.y)
		if spec["source"] in [PINE,TREE]:
			# Canopy is Y-sorted alpha, not a solid canopy-sized XZ rectangle.
			collider=Vector2(12,9) if spec["source"]==PINE else Vector2(18,14)
			collision_center=foot+Vector2(0,-5 if spec["source"]==PINE else -8)
		if component_blueprints.has(spec["id"]):
			var expected: Array=component_blueprints[spec["id"]]
			assert(collider.distance_to(Vector2(expected[2],expected[3]))<.02 and (collision_center-foot).distance_to(Vector2(expected[0],expected[1]))<.02,"Actual independent native model physical bounds diverged from surveyed road-clearance blueprint")
		models.append({"spec":spec,"node":model,"ground":ground,"foot":foot,"bounds":bounds,"contact":contact,"collision_size":collider,"collision_center":collision_center,"vertex_count":vertex_count,"source_mesh_node":source_mesh_node,"pose_key":pose_key,"material_recipe":material_recipe,"source_import_method":import_method})

func _native_casters(world: Node) -> void:
	for entry in models:
		var node: Node3D=entry["node"].duplicate()
		node.name="Caster_"+String(entry["spec"]["id"])
		var meshes: Array[MeshInstance3D]=[]
		_meshes(node,meshes)
		for mesh in meshes:
			mesh.layers=1
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		world.add_child(node)

func _write_native_capture_failure(entry: Dictionary,body: Image,repeat: Image,canvas: int,rect: Rect2i,size_valid: bool,repeat_valid: bool,corner_valid: bool,used_valid: bool,crop_margin_valid: bool) -> void:
	var id: String=entry["spec"]["id"]
	var prefix: String=native_export_root+"capture_failure_"+id
	var body_path: String=prefix+"_body.png"
	var repeat_path: String=prefix+"_repeat.png"
	var body_saved: bool=body.save_png(body_path)==OK
	var repeat_saved: bool=repeat.save_png(repeat_path)==OK
	var a: PackedByteArray=body.get_data()
	var b: PackedByteArray=repeat.get_data()
	var different_bytes: int=absi(a.size()-b.size())
	var maximum_byte_delta: int=0
	for i in mini(a.size(),b.size()):
		if a[i]!=b[i]: different_bytes+=1
		maximum_byte_delta=maxi(maximum_byte_delta,absi(int(a[i])-int(b[i])))
	var different_pixels: int=0
	for y in mini(body.get_height(),repeat.get_height()):
		for x in mini(body.get_width(),repeat.get_width()):
			if body.get_pixel(x,y)!=repeat.get_pixel(x,y): different_pixels+=1
	var used: Rect2i=body.get_used_rect()
	var corners: Array=[]
	for p in [Vector2i.ZERO,Vector2i(body.get_width()-1,0),Vector2i(0,body.get_height()-1),body.get_size()-Vector2i.ONE]:
		corners.append({"pixel":[p.x,p.y],"alpha":body.get_pixelv(p).a})
	_json(prefix+".json",{"status":"NATIVE_CAPTURE_TECHNICAL_FAIL","id":id,"source":entry["spec"]["source"],"source_sha256":FileAccess.get_sha256(entry["spec"]["source"]),"pose_key":entry["pose_key"],"expected_canvas":[canvas,canvas],"body_size":[body.get_width(),body.get_height()],"repeat_size":[repeat.get_width(),repeat.get_height()],"size_valid":size_valid,"repeat_exact":repeat_valid,"corner00_transparent":corner_valid,"used_rect_nonempty":used_valid,"crop_margin_valid":crop_margin_valid,"used_rect":[used.position.x,used.position.y,used.size.x,used.size.y],"crop_rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"actual_corner_alphas":corners,"different_bytes":different_bytes,"different_pixels":different_pixels,"maximum_byte_delta":maximum_byte_delta,"body_byte_length":a.size(),"repeat_byte_length":b.size(),"body_path":body_path,"repeat_path":repeat_path,"body_saved":body_saved,"repeat_saved":repeat_saved,"body_sha256":FileAccess.get_sha256(body_path) if body_saved else "","repeat_sha256":FileAccess.get_sha256(repeat_path) if repeat_saved else "","executed_builder_sha256":FileAccess.get_sha256(get_script().resource_path),"raw_ssaa_evidence":entry.get("raw_capture_evidence",{}),"gate_unchanged":"exact native high-resolution AND derived logical body/repeat bytes, expected actual/logical canvas, corner00 alpha0, nonempty body, crop apron; any failure stops exports"})
	push_error("[WorldV14Ninth] native capture gate failed id="+id+" diagnostic="+prefix+".json")

func _capture_native_entity(entry: Dictionary) -> Image:
	var viewport:=SubViewport.new()
	viewport.msaa_3d=Viewport.MSAA_DISABLED
	var bounds: AABB=entry["bounds"]
	var contact: Vector3=entry["contact"]
	var extent:=0.
	for corner in 8:
		var vertex: Vector3=bounds.get_endpoint(corner)-contact
		extent=maxf(extent,maxf(absf(vertex.x*102.4),absf((vertex.z-vertex.y)/sqrt(2.)*102.4)))
	var canvas:=maxi(512,ceili((extent*2.+32.)/256.)*256)
	viewport.size=Vector2i(canvas,canvas)*VISUAL_SSAA_SCALE
	viewport.own_world_3d=true
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world:=Node3D.new()
	viewport.add_child(world)
	var env:=WorldEnvironment.new()
	var settings:=native_surface.environment(true)
	env.environment=settings
	world.add_child(env)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-34,0)
	light.light_energy=NINTH.DIRECT
	world.add_child(light)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=float(canvas)/102.4
	camera.position=entry["ground"]+Vector3(0,FULL_CAMERA_OFFSET,FULL_CAMERA_OFFSET)
	world.add_child(camera)
	camera.look_at(entry["ground"])
	camera.current=true
	var pose_key: String=entry["pose_key"]
	var body: Image
	var repeat: Image
	var body_raw: Image
	var repeat_raw: Image
	var pose_provenance: Dictionary
	if sprite_pose_cache.has(pose_key):
		var cached_pose: Dictionary=sprite_pose_cache[pose_key]
		body=cached_pose["body"]
		repeat=cached_pose["repeat"]
		body_raw=cached_pose["body_raw"]
		repeat_raw=cached_pose["repeat_raw"]
		pose_provenance={"mode":"translation_equivalent_same_pose_rgba_reuse","prototype_id":cached_pose["id"],"prototype_sourcebody_path":cached_pose["path"],"prototype_sourcebody_sha256":FileAccess.get_sha256(cached_pose["path"]),"prototype_ground_m":cached_pose["ground"],"translation_m":[entry["ground"].x-cached_pose["ground"][0],entry["ground"].y-cached_pose["ground"][1],entry["ground"].z-cached_pose["ground"][2]],"same_infinite_directional_light_and_sky":true,"fresh_capture":false}
	else:
		world.add_child(entry["node"].duplicate())
		await _sync()
		body_raw=viewport.get_texture().get_image()
		body_raw.convert(Image.FORMAT_RGBA8)
		body=_ssaa_resample(body_raw,Vector2i(canvas,canvas))
		await _sync()
		repeat_raw=viewport.get_texture().get_image()
		repeat_raw.convert(Image.FORMAT_RGBA8)
		repeat=_ssaa_resample(repeat_raw,Vector2i(canvas,canvas))
		var prototype_id: String=entry["spec"]["id"]
		var gp: Vector3=entry["ground"]
		sprite_pose_cache[pose_key]={"body":body,"repeat":repeat,"body_raw":body_raw,"repeat_raw":repeat_raw,"id":prototype_id,"path":native_export_root+"entities/"+prototype_id+"_sourcebody.png","ground":[gp.x,gp.y,gp.z]}
		pose_provenance={"mode":"actual_gpu_body_and_repeat","prototype_id":prototype_id,"fresh_capture":true}
	var id: String=entry["spec"]["id"]
	var raw_body_path: String=native_export_root+"entities/"+id+"_sourcebody_raw_ssaa2.png"
	var raw_repeat_path: String=native_export_root+"entities/"+id+"_sourcebody_repeat_raw_ssaa2.png"
	assert(body_raw.save_png(raw_body_path)==OK)
	assert(repeat_raw.save_png(raw_repeat_path)==OK)
	var raw_repeat_exact: bool=body_raw.get_data()==repeat_raw.get_data()
	var raw_capture_evidence: Dictionary={"raw_body_path":raw_body_path,"raw_repeat_path":raw_repeat_path,"raw_body_png_sha256":FileAccess.get_sha256(raw_body_path),"raw_repeat_png_sha256":FileAccess.get_sha256(raw_repeat_path),"raw_body_rgba_sha256":_image_rgba_sha(body_raw),"raw_repeat_rgba_sha256":_image_rgba_sha(repeat_raw),"raw_repeat_exact":raw_repeat_exact,"actual_canvas":[viewport.size.x,viewport.size.y],"logical_canvas":[canvas,canvas],"ssaa_scale":VISUAL_SSAA_SCALE,"actual_msaa_3d_enum":viewport.msaa_3d,"resampling_method":"Image.resize INTERPOLATE_LANCZOS spatial reconstruction per individual native RGBA8 frame; no temporal averaging or tolerance","cache_reuse":sprite_pose_cache.has(pose_key) and not pose_provenance["fresh_capture"]}
	entry["raw_capture_evidence"]=raw_capture_evidence
	var size_valid: bool=body.get_size()==Vector2i(canvas,canvas) and body_raw.get_size()==Vector2i(canvas,canvas)*VISUAL_SSAA_SCALE and repeat_raw.get_size()==body_raw.get_size()
	var repeat_valid: bool=body.get_data()==repeat.get_data() and raw_repeat_exact
	var corner_valid: bool=body.get_pixel(0,0).a==0
	var used_valid: bool=body.get_used_rect().has_area()
	var rect:=body.get_used_rect().grow(4).intersection(Rect2i(0,0,canvas,canvas))
	var crop_margin_valid: bool=rect.size.x<canvas-12 and rect.size.y<canvas-12
	if not (size_valid and repeat_valid and corner_valid and used_valid and crop_margin_valid):
		# Preserve the strict exact-repeat/alpha/canvas gates. Diagnostic originals
		# precede fail-closed return; never average or overwrite a failing frame.
		_write_native_capture_failure(entry,body,repeat,canvas,rect,size_valid,repeat_valid,corner_valid,used_valid,crop_margin_valid)
		viewport.queue_free()
		await process_frame
		return null
	var path:=native_export_root+"entities/"+id+".png"
	assert(body.save_png(native_export_root+"entities/"+id+"_sourcebody.png")==OK)
	assert(repeat.save_png(native_export_root+"entities/"+id+"_sourcebody_repeat.png")==OK)
	assert(body.get_region(rect).save_png(path)==OK)
	var actual_body_foot: Vector2=camera.unproject_position(entry["ground"])
	var body_foot: Vector2=actual_body_foot/VISUAL_SSAA_SCALE
	var foot: Vector2=entry["foot"]
	var uv:=(body_foot-Vector2(rect.position))/Vector2(rect.size)
	var size:=Vector2(rect.size)
	var center:=foot+(Vector2(.5,.5)-uv)*size
	var collision_center: Vector2=entry["collision_center"]
	var object: Dictionary={"id":id,"texture":path,"pos":center/Vector2(SIZE),"render_size_px":size,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y}
	if entry["spec"]["blocking"]:
		object["collision_offset"]=(collision_center-center)/Vector2(SIZE)
		object["collision_size"]=entry["collision_size"]/Vector2(SIZE)
	objects.append(object)
	var ground: Vector3=entry["ground"]
	var model: Node3D=entry["node"]
	_json(native_export_root+"entities/"+id+".json",{"id":id,"texture_path":path,"source":entry["spec"]["source"],"source_sha256":FileAccess.get_sha256(entry["spec"]["source"]),"source_foot":_pair(entry["spec"]["foot"]),"world_foot":_pair(foot),"foot_uv":_pair(uv),"size":_pair(size),"collision_center":_pair(collision_center),"collision_size":_pair(entry["collision_size"]),"depth_y":foot.y,"blocking":entry["spec"]["blocking"],"actual_vertex_count":entry["vertex_count"],"actual_min_vertex_ground_delta":model.position.y+bounds.position.y-ground.y,"model_position_m":[model.position.x,model.position.y,model.position.z],"ground_m":[ground.x,ground.y,ground.z],"support_contact_m":[contact.x,contact.y,contact.z],"actual_transformed_bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z],"source_variant":entry["spec"]["variant"],"support_method":"minY and frontZ of actual lowest6percent vertices; synthetic support contact, not literal vertex","same_native_camera_orientation_px_per_meter":102.4*VISUAL_SSAA_SCALE,"logical_map_pixels_per_meter":102.4,"sourcebody_camera_foot":_pair(body_foot),"sourcebody_canvas":[canvas,canvas],"sourcebody_repeat_exact":true,"sourcebody_crop_rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"sourcebody_path":native_export_root+"entities/"+id+"_sourcebody.png","sourcebody_repeat_path":native_export_root+"entities/"+id+"_sourcebody_repeat.png","sourcebody_origin_world_px":_pair(foot-body_foot),"model_scale":entry["spec"]["scale"],"yaw":entry["spec"]["yaw"],"nature":entry["spec"].get("nature","solid_rock" if entry["spec"]["blocking"] else "natural_groundcover")})
	var metadata: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(native_export_root+"entities/"+id+".json"))
	metadata["source_mesh_node"]=String(entry["source_mesh_node"])
	metadata["source_import_method"]=entry["source_import_method"]
	metadata["actual_native_material_derivative"]=entry["material_recipe"]
	metadata["same_derivative_material_in_body_and_caster"]=true
	metadata["sourcebody_msaa_3d_enum"]=viewport.msaa_3d
	metadata["sourcebody_msaa_3d_samples"]=0
	metadata["sourcebody_ssaa_evidence"]=raw_capture_evidence
	metadata["actual_sourcebody_camera_foot"]=_pair(actual_body_foot)
	metadata["sourcebody_ssaa_scale"]=VISUAL_SSAA_SCALE
	metadata["sourcebody_actual_canvas"]=[viewport.size.x,viewport.size.y]
	metadata["sourcebody_canvas"]=[canvas,canvas]
	metadata["sourcebody_canvas_method"]="logical canvas: conservative projected eight-corner bound of actual draw-vertex AABB at102.4px/m, aligned256px with32px apron; native actual canvas2x/204.8px/m; may exceed tight vertex minimum"
	var basis:=camera.transform.basis
	metadata["shared_illumination"]={"ambient_energy":NINTH.AMBIENT,"directional_energy":NINTH.DIRECT,"rotation_degrees":[-55,-34,0],"reflected_light_source":"native ProceduralSky identical to terrain water Sky","legacy_baked_buildings_not_relighted":true}
	metadata["pose_reuse_evidence"]=pose_provenance
	metadata["sourcebody_camera"]={"orthographic":camera.projection==Camera3D.PROJECTION_ORTHOGONAL,"projection_enum":camera.projection,"size":camera.size,"canvas":[viewport.size.x,viewport.size.y],"logical_canvas":[canvas,canvas],"projection_to_logical_divisor":VISUAL_SSAA_SCALE,"pixels_per_meter":102.4*VISUAL_SSAA_SCALE,"logical_pixels_per_meter":102.4,"position":[camera.position.x,camera.position.y,camera.position.z],"look_at":[ground.x,ground.y,ground.z],"basis_columns":[[basis.x.x,basis.x.y,basis.x.z],[basis.y.x,basis.y.y,basis.y.z],[basis.z.x,basis.z.y,basis.z.z]],"provenance":"actual Camera3D properties read for this instance export; reused pose is separately marked translation-equivalent and not a fresh GPU capture"}
	metadata["executed_builder_sha256"]=FileAccess.get_sha256(get_script().resource_path)
	metadata["executed_builder_path"]=get_script().resource_path
	metadata["builder_binding_semantics"]="SHA sampled during capture; producer retains this exact source snapshot separately before future source revisions"
	metadata["actual_vertex_semantics"]="unique indices referenced by actually drawn triangles; unused source-array vertices excluded"
	metadata["collision_method"]="narrow trunk 12x9px" if entry["spec"]["source"]==PINE else ("narrow mature trunk 18x14px; canopy alpha not solid" if entry["spec"]["source"]==TREE else "full actual transformed draw-vertex XZ bounds; nonblocking low herbs")
	if entry["spec"]["source"]==TREE: metadata["derived_mesh_recipe"]=tree_lod_recipe
	entry["body_origin"]=foot-body_foot
	_json(native_export_root+"entities/"+id+".json",metadata)
	viewport.queue_free()
	await process_frame
	return body

func _support_mesh(world: Node) -> void:
	for index in bridge_decks.size():
		var rect: Rect2=bridge_decks[index]
		var deck:=MeshInstance3D.new()
		deck.name="ActualSupport_"+str(index)
		var plane:=PlaneMesh.new()
		plane.size=rect.size/Vector2(SIZE)*WORLD
		deck.mesh=plane
		deck.position=_point(rect.get_center(),true)
		var mat:=StandardMaterial3D.new()
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color=Color.WHITE
		deck.material_override=mat
		deck.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(deck)
		assert(ResourceSaver.save(plane,OUT+"entities/support_"+str(index)+".res")==OK)

func _overview(visual: Image) -> void:
	# M-map only. Buildings never enter visual.png or Field ground chunks.
	var overview:=visual.duplicate() as Image
	var ordered:=objects.duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary): return float(a.get("depth_sort_foot_y",a["pos"].y))<float(b.get("depth_sort_foot_y",b["pos"].y)))
	for object in ordered:
		var image:=Image.load_from_file(object["texture"])
		var size: Vector2=object["render_size_px"]
		image.resize(roundi(size.x),roundi(size.y),Image.INTERPOLATE_LANCZOS)
		var origin:=Vector2i(object["pos"]*Vector2(SIZE)-size*.5)
		overview.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),origin)
	assert(overview.save_png(OUT+"overview.png")==OK)

func _shadow(on: Image,off: Image,land: Image,body_union: Image) -> Image:
	var shadow:=Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	shadow.fill(Color.TRANSPARENT)
	var count:=0
	var expanded:=PackedByteArray()
	expanded.resize(SIZE.x*SIZE.y)
	var bytes:=body_union.get_data()
	for y in SIZE.y:
		for x in SIZE.x:
			if bytes[(y*SIZE.x+x)*4+3]==0: continue
			for dy in range(-2,3):
				for dx in range(-2,3):
					expanded[clampi(y+dy,0,SIZE.y-1)*SIZE.x+clampi(x+dx,0,SIZE.x-1)]=1
	for y in SIZE.y:
		for x in SIZE.x:
			if land.get_pixel(x,y).r<.5: continue
			var p:=Vector2(x,y)
			var supported:=false
			for rect in bridge_decks:
				if rect.has_point(p): supported=true
			if supported: continue
			if expanded[y*SIZE.x+x]>0: continue
			var a:=on.get_pixel(x,y)
			var b:=off.get_pixel(x,y)
			var la:=a.r*.299+a.g*.587+a.b*.114
			var lb:=b.r*.299+b.g*.587+b.b*.114
			var alpha:=clampf((lb-la)/maxf(lb,.01),0.0,.85)
			if alpha>.015:
				shadow.set_pixel(x,y,Color(0,0,0,alpha))
				count+=1
	assert(count>0,"Actual native ground cast must be nonempty")
	print("[WorldV14] actual native shadow pixels=",count)
	assert(shadow.save_png(OUT+"native_shadow.png")==OK)
	objects.append({"id":"native_cast_shadow","texture":OUT+"native_shadow.png","pos":Vector2(.5,.5),"render_size_px":Vector2(SIZE),"z_index":-3})
	return shadow

func _save_capture(viewport: SubViewport,name: String) -> Image:
	var image: Image
	if name in ["land","raw_walk","walk"]:
		# Authoritative binary captures remain native original canvas, no
		# multisample coverage, no resize/interpolation or derived selector.
		assert(viewport.size==SIZE and viewport.msaa_3d==Viewport.MSAA_DISABLED)
		await _sync()
		image=viewport.get_texture().get_image()
		image.convert(Image.FORMAT_RGBA8)
		assert(image.get_size()==SIZE)
	else:
		image=await _ssaa_readback(viewport,SIZE,OUT+name+"_raw_ssaa2.png")
	assert(image.save_png(OUT+name+".png")==OK)
	for row in 3:
		for col in 3:
			var crop:=image.get_region(Rect2i(col*1536,row*1024,1536,1024))
			assert(crop.save_png(OUT+"chunks/r%dc%d_%s.png"%[row,col,name])==OK)
	return image


func _canopy_evidence_records() -> Array:
	var records: Array=[]
	for region in native_surface.canopy_regions:
		records.append({"id":region["id"],"source_center_px":_pair(region["center"]),"source_radius_px":_pair(region["radius"]),"basis":region["basis"]})
	return records

func _whole_ecology(viewport: SubViewport) -> Dictionary:
	var ecology_material: ShaderMaterial=_surface_material(4)
	if ecology_material==null:
		push_error("[WorldV14Ninth] whole ecology compiler rejected; no default material capture")
		return {}
	var world:=viewport.get_child(0)
	for child in world.get_children():
		if child is MeshInstance3D: child.visible=child.name=="ActualTerrain"
	world.get_node("ActualTerrain").material_override=ecology_material
	viewport.msaa_3d=Viewport.MSAA_DISABLED
	viewport.size=SIZE*VISUAL_SSAA_SCALE
	var weights: Image=await _save_capture(viewport,"ecology_weights")
	var repeat: Image=await _preview_readback(viewport,OUT+"ecology_weights_repeat_raw_ssaa2.png")
	assert(_ssaa_raw_repeat_exact(OUT+"ecology_weights_raw_ssaa2.png",OUT+"ecology_weights_repeat_raw_ssaa2.png"))
	assert(weights.get_data()==repeat.get_data())
	assert(repeat.save_png(OUT+"ecology_weights_repeat.png")==OK)
	var camera: Camera3D=viewport.get_camera_3d()
	var probes: Array=[]
	var cores:=0
	# Actual crown centres, not labelled empty habitats, provide raster probes.
	for region in native_surface.canopy_regions:
		var source: Vector2=region["center"]
		var pixel:=Vector2i(camera.unproject_position(_point(source))/VISUAL_SSAA_SCALE)
		if not Rect2i(Vector2i.ZERO,SIZE).has_point(pixel): continue
		var value:=weights.get_pixelv(pixel).r
		if value>=.85: cores+=1
		probes.append({"entity_id":region["id"],"source_px":_pair(source),"actual_camera_pixel":[pixel.x,pixel.y],"encoded_forest_red":value,"core_minimum":.85,"is_verified_core":value>=.85})
	assert(cores>=12,"Whole forest requires12 actual crown-backed core raster witnesses")
	return {"path":OUT+"ecology_weights.png","sha256":FileAccess.get_sha256(OUT+"ecology_weights.png"),"repeat_path":OUT+"ecology_weights_repeat.png","repeat_sha256":FileAccess.get_sha256(OUT+"ecology_weights_repeat.png"),"repeat_exact":true,"same_visual_shader_selector_function":"native_surface.ecology_shader() shared by mode0 and4; red forest excludes road core, green rock, blue wet","actual_msaa_3d_enum":viewport.msaa_3d,"ssaa_scale":VISUAL_SSAA_SCALE,"raw_repeat_exact":true,"raw_capture":_ssaa_record(OUT+"ecology_weights_raw_ssaa2.png"),"raw_repeat_capture":_ssaa_record(OUT+"ecology_weights_repeat_raw_ssaa2.png"),"source_canopy_regions":_canopy_evidence_records(),"forest_core_probes":probes,"actual_crown_core_count":cores,"not_a_visual_approval":true,"camera":{"orthographic":camera.projection==Camera3D.PROJECTION_ORTHOGONAL,"projection_enum":camera.projection,"size":camera.size,"position":[camera.position.x,camera.position.y,camera.position.z],"basis_columns":[[camera.basis.x.x,camera.basis.x.y,camera.basis.x.z],[camera.basis.y.x,camera.basis.y.y,camera.basis.y.z],[camera.basis.z.x,camera.basis.z.y,camera.basis.z.z]],"canvas":[viewport.size.x,viewport.size.y],"logical_canvas":[SIZE.x,SIZE.y],"projection_to_logical_divisor":VISUAL_SSAA_SCALE}}

func _build() -> void:
	DirAccess.make_dir_recursive_absolute(OUT+"chunks")
	DirAccess.make_dir_recursive_absolute(OUT+"entities")
	_json(OUT+"manifest.json",{"version":"world_v14","status":"BUILD_IN_PROGRESS","current_outputs_not_ready":true,"production_approved":false,"world_size":[4608,3072]})
	_prepare_contract()
	if portals.size()!=16:
		_fail_candidate("Incomplete 16 landmark portal source contract")
		return
	if "--source-only" in OS.get_cmdline_user_args():
		print("[WorldV14] source contract prepared, no GPU")
		quit(0)
		return
	if "--shader-preflight" in OS.get_cmdline_user_args():
		await _shader_preflight()
		return
	_source_images()
	_project_runtime_contract()
	for mode in 3:
		if _surface_material(mode)==null:
			_fail_candidate("Surface shader compiler rejected mode %d before GPU exports"%mode)
			return
	if _water_material()==null:
		_fail_candidate("Water shader compiler rejected before GPU exports")
		return
	terrain_mesh=_mesh()
	if compiled_water_material!=null: compiled_water_material.set_shader_parameter("actual_height_rf",actual_height_texture)
	if not _export_geometry():
		_fail_candidate("Geometry export rejected: "+String(geometry_witness_audit.get("rejection_reason","geometry file or mesh save failed")))
		return
	print("[WorldV14] actual front-facing terrain mesh ready")
	_prepare_native_models()
	_bind_native_ecology()
	# Canopy binding rebuilds shader code: validate the actual final modes,
	# not only the pre-binding shader cache. No default-material fallback.
	if _surface_material(0)==null or _surface_material(4)==null:
		_fail_candidate("Final crown-bound visual/ecology shader compiler rejected")
		return
	if models.size()!=native_specs.size():
		_fail_candidate("Incomplete actual native model construction")
		return
	if tree_lod_mesh!=null:
		assert(ResourceSaver.save(tree_lod_mesh,OUT+"entities/tree_small02_native_hybrid.res")==OK)
		tree_lod_recipe["derived_mesh_path"]=OUT+"entities/tree_small02_native_hybrid.res"
		tree_lod_recipe["derived_mesh_sha256"]=FileAccess.get_sha256(OUT+"entities/tree_small02_native_hybrid.res")
	var union:=Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	union.fill(Color.TRANSPARENT)
	for entry in models:
		var body: Image=await _capture_native_entity(entry)
		if body==null:
			_fail_candidate("Invalid native entity capture "+String(entry["spec"]["id"]))
			return
		var origin:=Vector2i(entry["body_origin"])
		union.blend_rect(body,Rect2i(Vector2i.ZERO,body.get_size()),origin)
	assert(union.save_png(OUT+"native_body_union.png")==OK)
	var viewport:=_viewport(0)
	if viewport==null: return
	var visual: Image=await _save_capture(viewport,"visual")
	if visual==null:
		_fail_candidate("Terrain visual capture failed")
		return
	_native_casters(viewport.get_child(0))
	var shadow_on: Image=await _save_capture(viewport,"shadow_on")
	var on_repeat: Image=await _preview_readback(viewport,OUT+"shadow_on_repeat_raw_ssaa2.png")
	assert(_ssaa_raw_repeat_exact(OUT+"shadow_on_raw_ssaa2.png",OUT+"shadow_on_repeat_raw_ssaa2.png"))
	assert(shadow_on.get_data()==on_repeat.get_data())
	assert(on_repeat.save_png(OUT+"shadow_on_repeat.png")==OK)
	for child in viewport.get_child(0).get_children():
		if String(child.name).begins_with("Caster_"): child.visible=false
	var shadow_off: Image=await _save_capture(viewport,"shadow_off")
	assert(visual.get_data()==shadow_off.get_data())
	var off_repeat: Image=await _preview_readback(viewport,OUT+"shadow_off_repeat_raw_ssaa2.png")
	assert(_ssaa_raw_repeat_exact(OUT+"shadow_off_raw_ssaa2.png",OUT+"shadow_off_repeat_raw_ssaa2.png"))
	assert(_ssaa_raw_repeat_exact(OUT+"visual_raw_ssaa2.png",OUT+"shadow_off_raw_ssaa2.png"))
	assert(shadow_off.get_data()==off_repeat.get_data())
	assert(off_repeat.save_png(OUT+"shadow_off_repeat.png")==OK)
	# Native binary land/nav retains original logical canvas and exact raster.
	# No resize/SSAA path may manufacture a walkable coverage fringe.
	viewport.msaa_3d=Viewport.MSAA_DISABLED
	viewport.size=SIZE
	viewport.get_child(0).get_node("ActualTerrain").material_override=_surface_material(1)
	for child in viewport.get_child(0).get_children():
		if child is WorldEnvironment:
			child.environment.background_mode=Environment.BG_COLOR
			child.environment.background_color=Color.BLACK
		if child is MeshInstance3D and child.name!="ActualTerrain": child.visible=false
	var land: Image=await _save_capture(viewport,"land")
	viewport.get_child(0).get_node("ActualTerrain").material_override=_surface_material(2)
	await _save_capture(viewport,"raw_walk")
	# Same-camera real support geometry, never reclassifies natural water land.
	_support_mesh(viewport.get_child(0))
	var walk: Image=await _save_capture(viewport,"walk")
	var ecology_evidence: Dictionary=await _whole_ecology(viewport)
	if ecology_evidence.is_empty():
		_fail_candidate("Whole ecology evidence absent; candidate remains failed")
		return
	var actual_shadow:=_shadow(shadow_on,shadow_off,land,union)
	if actual_shadow==null or not actual_shadow.get_used_rect().has_area():
		_fail_candidate("Actual native ground shadow empty or invalid")
		return
	_write_source_contract(true)
	_overview(visual)
	var topology:=land.duplicate() as Image
	assert(topology.save_png(OUT+"topology.png")==OK)
	var sources: Array=[]
	for path in [BOULDER,HERB,PINE,TREE,ROCKFACE,"res://art/external/polyhaven/coastal_cliff_01/coastal_cliff_01_1k.gltf"]: sources.append({"path":path,"sha256":FileAccess.get_sha256(path),"license":"PolyHaven CC0 registered; pine/tree official verified SOURCE.json 20261002"})
	var regions: Array=[]
	for row in 3:
		for col in 3:
			var extrema:=Vector2(INF,-INF)
			for y in range(row*1024,(row+1)*1024,24):
				for x in range(col*1536,(col+1)*1536,24):
					var value:=terrain_height(Vector2(x,y))
					extrema.x=minf(extrema.x,value)
					extrema.y=maxf(extrema.y,value)
			var files: Dictionary={}
			for name in ["visual","walk","land"]:
				var path: String=OUT+"chunks/r%dc%d_%s.png"%[row,col,name]
				files[name]={"path":path,"sha256":FileAccess.get_sha256(path)}
			regions.append({"id":"r%dc%d"%[row,col],"logical_rect":[col*1536,row*1024,1536,1024],"source_height_range_m":_pair(extrema),"captures":files})
	var completed: Dictionary={"version":"world_v14","status":"ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","production_approved":false,"world_size":[4608,3072],"tile_size":[1536,1024],"regions":regions,"continuous_shared_mesh":true,"mesh_triangles":HEIGHT_COLS*HEIGHT_ROWS*2,"source_height":get_script().resource_path+"::terrain_height","topology":"source_topology.png CPU selector; actual land/walk captures same mesh and camera","raw_walk_path":OUT+"raw_walk.png","source_contract_path":OUT+"source_contract.json","overview_path":OUT+"overview.png","capture_sync":"eight process frames then frame_post_draw","camera":{"position":[0,FULL_CAMERA_OFFSET,FULL_CAMERA_OFFSET],"size":30,"orthographic":true,"actual_visual_canvas":[SIZE.x*VISUAL_SSAA_SCALE,SIZE.y*VISUAL_SSAA_SCALE],"logical_canvas":[SIZE.x,SIZE.y],"projection_to_logical_divisor":VISUAL_SSAA_SCALE,"binary_land_nav_canvas":[SIZE.x,SIZE.y]},"light":{"rotation":[-55,-34,0],"energy":NINTH.DIRECT,"ambient":NINTH.AMBIENT},"sources":sources,"legacy_landmarks":true,"visual_approved":false,"native_model_count":models.size(),"real_shadow_path":OUT+"native_shadow.png","raw_visual_sha":FileAccess.get_sha256(OUT+"visual.png"),"land_sha":FileAccess.get_sha256(OUT+"land.png"),"walk_sha":FileAccess.get_sha256(OUT+"walk.png")}
	completed["ecology_evidence"]=ecology_evidence
	completed["actual_native_material_derivatives"]=native_material_recipes
	completed["visual_msaa_3d_samples"]=0
	completed["visual_ssaa_scale"]=VISUAL_SSAA_SCALE
	completed["raw_ssaa_evidence"]=ssaa_capture_records
	completed["authoritative_land_nav_msaa_3d_samples"]=0
	completed["geometry_path"]=OUT+"geometry.json"
	completed["height_grid_path"]=OUT+"height_grid.rf"
	completed["terrain_mesh_path"]=OUT+"terrain_mesh.res"
	completed["shadow_evidence"]={"on":OUT+"shadow_on.png","off":OUT+"shadow_off.png","on_repeat":OUT+"shadow_on_repeat.png","off_repeat":OUT+"shadow_off_repeat.png","body_union":OUT+"native_body_union.png","ground_shadow":OUT+"native_shadow.png","body_exclusion_dilation_px":2,"relative_luma_threshold":.015,"maximum_alpha":.85,"on_off_each_repeat_actual_readback":true,"raw_on":OUT+"shadow_on_raw_ssaa2.png","raw_off":OUT+"shadow_off_raw_ssaa2.png","raw_on_repeat":OUT+"shadow_on_repeat_raw_ssaa2.png","raw_off_repeat":OUT+"shadow_off_repeat_raw_ssaa2.png","native_highres_and_derived_repeat_exact_required":true,"resampling":"single-frame Lanczos2x; never temporal averaging"}
	completed["mesh_triangles"]=HEIGHT_COLS*HEIGHT_ROWS*2
	completed["capture_iteration"]=9
	completed["executed_builder_sha256"]=FileAccess.get_sha256(get_script().resource_path)
	completed["executed_builder_path"]=get_script().resource_path
	completed["capture_history"]={"first":"visual FAIL archived in build/world_map_v14_first_iteration","second":"TECHNICAL_FAIL mat2 compiler; archived in build/world_map_v14_second_shader_failure","third":"technical retry of second composition, shader constructor fix only; visual FAIL and actual Field contract failures preserved by producer","fourth":"whole visual FAIL and 28469/33 actual Field technical failures archived by producer in build/world_map_v14_fourth_failed","fifth":"full capture archived after overall visual FAIL; retained producer fifth evidence and technical QA","sixth":"actual full capture 47 native entities, 888772 body-excluded ground shadow pixels; overall visual FAIL; technical QA still independent; all sixth source and OUT frozen","seventh":"producer actual full capture exit0,86 native and1008900 body-excluded ground shadow; overall visual FAIL, frozen source/OUT","eighth":"three actual local previews technically passed; smooth clay ridge / olive meadow / absent forest visual FAIL, no fullcapture", "ninth":"local1 visual FAIL; v2 compiler FAIL; v3/v4 strict body repeat RGB1 technical FAIL; MSAA8/4/2 instability and MSAA0 SSAA2 exact repeats diagnosed independently; v5 SSAA2 representative scene/forecast/Field approval still required"}
	completed["source_design"]={"iteration":9,"geology":"wide low RF shoulders and valleys carry six independent registered native RockFace proxy components; real component solids remain separate RGBA/fullXZ collision/Y/caster, never baked into walkable terrain","ecology":"hand-positioned dense cores/broken edges/open corridors, each native instance independent physical/depth contract","road_profile_path":OUT+"road_profile.rgf","road_profile_shape":[2304,1536],"road_profile_format":"little-endian Float32 RG: unsigned distance/halfwidth then halfwidth_px; row-major 2px source","road_profile_sha256":FileAccess.get_sha256(OUT+"road_profile.rgf"),"road_visual_not_navigation":"narrow worn core and soft shoulders do not change conservative natural nav selector","scan_scales":"six registered full PBR sets; grass_ground actual2.51m meadow; aerial_grass_rock15m confined to dry rock shoulders; MAX/actualcrown union forestfloor and real wetmud, no habitat-average dilution","native_unique_pose_count":sprite_pose_cache.size(),"native_instance_count":models.size(),"cast_shadow_instances":"each actual shared derived mesh with its own ground transform; no sprite baked into terrain"}
	completed["current_outputs_not_ready"]=false
	completed["mature_tree_native_lod_recipe"]=tree_lod_recipe
	completed["height_interpolation"]="GPU mesh triangles a,b,c then b,d,c; split fx+fy=1; exact piecewise affine, not bilinear"
	completed["native_shader_compiler_gate"]=shader_gate_results
	completed["ninth_pbr_sources"]=native_surface.audit
	completed["ninth_material_helper_path"]=native_surface.get_script().resource_path
	completed["ninth_material_helper_sha256"]=FileAccess.get_sha256(native_surface.get_script().resource_path)
	completed["whole_camera_shadow_coverage"]=coverage_record
	completed["surface_ecological_habitats"]=[]
	for habitat in NINTH.HABITATS:
		completed["surface_ecological_habitats"].append({"id":habitat[0],"source_center":_pair(habitat[1]),"source_radius":_pair(habitat[2]),"scan_weights":[habitat[3],habitat[4],habitat[5]],"transition":"overlapping radial smooth weights, not chunk rectangles"})
	completed["water_actual_height_rf"]={"path":OUT+"height_grid.rf","same_native_mesh_vertices":true,"mip_count":0,"filter":"nearest texelFetch","height_interpolation":"same exact triangle-affine fx+fy<=1","water_y_m":NINTH.WATER_Y,"not_depth_buffer_refraction":true}
	completed["self_shadow_common_base"]=true
	completed["legacy_landmark_lighting_limitation"]="baked original buildings cannot be physically relit; native props/ground share actual .35/.85/Sky lighting; requires Field visual approval"
	completed["first_visual_fail_archive"]="res://build/world_map_v14_first_iteration/"
	completed["native_sourcebody_schema"]="entities/<id>.json plus sourcebody/repeat exact; actual vertex transform/lowest6percent contact and projected foot"
	_json(OUT+"manifest.json",completed)
	print("[WorldV14] complete shared native 4608x3072 terrain and 9x3 chunks exported; not yet visual approved; landmarks=",landmarks.size()," routes=",routes.size())
	viewport.queue_free()
	for entry in models: entry["node"].free()
	models.clear()
	for template in model_templates.values(): template.free()
	model_templates.clear()
	for pose in pose_cache.values(): pose["prototype"].free()
	pose_cache.clear()
	sprite_pose_cache.clear()
	road_profile_texture=null
	road_profile_image=null
	surface_materials.clear()
	compiled_water_material=null
	actual_height_texture=null
	actual_height_image=null
	native_surface.textures.clear()
	native_surface.sky=null
	topology_texture=null
	terrain_mesh=null
	tree_lod_mesh=null
	_release_capture_resource_refs()
	for frame in 16: await process_frame
	await RenderingServer.frame_post_draw
	if not _cursor_release_audit():
		_json(OUT+"manifest.json",{"version":"world_v14","status":"TECHNICAL_FAIL","current_outputs_not_ready":true,"production_approved":false,"reason":"Tool cursor references not released at teardown"})
		quit(1)
		return
	quit(0)
