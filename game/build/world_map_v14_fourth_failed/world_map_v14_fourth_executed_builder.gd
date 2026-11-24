extends SceneTree

# Complete continuous production candidate. No inherited build/save hooks.
const OUT := "res://art/maps/world_map_v14/"
const OLD := "res://art/modules/world_map_v13/"
const SIZE := Vector2i(4608,3072)
const WORLD := Vector2(45.0,42.42640687)
const CAMERA_SIZE := 30.0
const GRASS := "res://art/external/polyhaven/terrain/aerial_grass_rock_diff_4k.jpg"
const ROAD := "res://art/external/polyhaven/terrain/rock_path_diff_4k.jpg"
const ROCK := "res://art/external/polyhaven/boulder_01/textures/boulder_01_diff_1k.jpg"
const BOULDER := "res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf"
const HERB := "res://art/external/polyhaven/shrub_03/shrub_03_1k.gltf"
const PINE := "res://art/external/polyhaven/pine_sapling_small/pine_sapling_small_1k.gltf"
const TREE := "res://art/external/polyhaven/tree_small_02/tree_small_02_1k.gltf"
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
var bridge_decks := [Rect2(2282,1983,36,225),Rect2(1415,2838,242,24),Rect2(4057,2021,36,225)]
var bridge_centers: Array[Vector2]=[Vector2(2300,2095),Vector2(1536,2850),Vector2(4075,2133)]
var waterways: Array[Dictionary]=[]
var vegetation_sites: Array[Dictionary]=[]
var route_buckets: Dictionary={}
var height_grid: PackedFloat32Array=PackedFloat32Array()
const HEIGHT_COLS := 768
const HEIGHT_ROWS := 512
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
var native_specs := [
	{"id":"native_rock_west","source":BOULDER,"foot":Vector2(600,1320),"yaw":35.0,"scale":.85,"variant":0,"blocking":true},
	{"id":"native_rock_foothill","source":BOULDER,"foot":Vector2(1650,1160),"yaw":-42.0,"scale":.75,"variant":0,"blocking":true},
	{"id":"native_rock_heartland","source":BOULDER,"foot":Vector2(2810,1670),"yaw":15.0,"scale":.80,"variant":0,"blocking":true},
	{"id":"native_rock_south","source":BOULDER,"foot":Vector2(2730,2690),"yaw":115.0,"scale":.68,"variant":0,"blocking":true},
	{"id":"native_rock_cove","source":BOULDER,"foot":Vector2(3970,1650),"yaw":-65.0,"scale":.70,"variant":0,"blocking":true},
	{"id":"native_cliff_south","source":"res://art/external/polyhaven/coastal_cliff_01/coastal_cliff_01_1k.gltf","foot":Vector2(3520,2930),"yaw":-8.0,"scale":.025,"variant":0,"blocking":true}]

func _initialize() -> void:
	if "--source-plan-audit" in OS.get_cmdline_user_args():
		source_design_only=true
		call_deferred("_source_plan_audit")
	elif "--tree-geometry-audit" in OS.get_cmdline_user_args():
		call_deferred("_tree_geometry_audit")
	elif "--mark-shader-fail" in OS.get_cmdline_user_args():
		_fail_candidate("Second capture invalid: mat2 scalar constructor shader compilation failed; second evidence archived in build/world_map_v14_second_shader_failure")
	else:
		call_deferred("_build")

func _json(path: String,data: Dictionary) -> void:
	if source_design_only: return
	var file:=FileAccess.open(path,FileAccess.WRITE)
	assert(file!=null,"Cannot save new v14 JSON")
	file.store_string(JSON.stringify(data,"\t"))
	file.close()

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
			var measured: Array=ROCK_COLLISION_BLUEPRINTS[spec["id"]]
			collision_size=Vector2(measured[2],measured[3])
			collision_center=foot+Vector2(measured[0],measured[1])
		objects.append({"id":spec["id"],"pos":collision_center/Vector2(SIZE),"collision_size":collision_size/Vector2(SIZE)})
	var total_samples:=0
	for route in routes:
		var samples:=0
		var bad:=0
		var first:=Vector2.ZERO
		var points: PackedVector2Array=route["points"]
		for i in range(1,points.size()):
			var steps:=maxi(1,ceili(projected(points[i-1]).distance_to(projected(points[i]))/4.))
			for j in range(steps+1):
				var point:=projected(points[i-1].lerp(points[i],float(j)/steps))
				var clear:=_projected_layout_foot_clear(point)
				if not clear:
					if bad==0: first=point
					bad+=1
				samples+=1
		total_samples+=samples
		failures+=bad
		print("[V14ProjectedPlan] ",route["id"]," samples=",samples," layout_fullfoot_bad=",bad," first=",first," first_entity=",_projected_layout_blocker(first) if bad>0 else "")
	print("[V14SourcePlan] no_render_no_png_no_json=true failures=",failures," native_specs=",native_specs.size())
	print("[V14ProjectedPlan] exact_triangle_height=true total_samples=",total_samples," actual_GPU_nav_not_tested=true")
	quit(0 if failures==0 else 1)

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
	quit(1)

func _pair(v: Vector2) -> Array:
	return [v.x,v.y]

func _rect(v: Rect2) -> Array:
	return [v.position.x,v.position.y,v.size.x,v.size.y]

func _smooth(a: float,b: float,v: float) -> float:
	return smoothstep(a,b,v)

func shore_x(y: float) -> float:
	return 4355.0+55.0*sin(y/285.0)-125.0*exp(-pow((y-1290.0)/116.0,2.0))-135.0*exp(-pow((y-1730.0)/108.0,2.0))

func river_y(x: float) -> float:
	return 2095.0+38.0*sin((x-2300.0)/235.0)*smoothstep(110.0,350.0,absf(x-2300.0))

func _river_distance(p: Vector2) -> float:
	var nearest:=10000.0
	for water in waterways:
		var points: PackedVector2Array=water["points"]
		var widths: PackedFloat32Array=water["radii"]
		for i in range(1,points.size()):
			var d:=points[i]-points[i-1]
			var t:=clampf((p-points[i-1]).dot(d)/d.length_squared(),0.,1.)
			nearest=minf(nearest,p.distance_to(points[i-1]+t*d)-lerpf(widths[i-1],widths[i],t))
	return nearest

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

func _index_routes() -> void:
	for route in routes:
		var points: PackedVector2Array=route["points"]
		for i in range(1,points.size()):
			var a:=points[i-1]
			var b:=points[i]
			var bridge: bool=String(route["id"]).ends_with("_bridge") or route["id"]=="bailu_dock_access"
			var grade_a:=0. if bridge else _base_ground(a)
			var grade_b:=0. if bridge else _base_ground(b)
			for y in range(floori((minf(a.y,b.y)-180.)/128.),ceili((maxf(a.y,b.y)+180.)/128.)+1):
				for x in range(floori((minf(a.x,b.x)-180.)/128.),ceili((maxf(a.x,b.x)+180.)/128.)+1):
					var key:=Vector2i(x,y)
					if not route_buckets.has(key): route_buckets[key]=[]
					route_buckets[key].append([a,b,route["width"],grade_a,grade_b])

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
	# Separate authored summits and interrupted saddles, not a full-width wall.
	var north:=0.
	for peak in [[320.,370.,270.,410.,3.10,-.18],[820.,295.,310.,380.,3.45,.23],[1350.,450.,330.,380.,2.65,-.26],[1940.,290.,300.,410.,3.05,.19],[2460.,430.,390.,390.,2.35,-.16],[3080.,320.,360.,410.,2.10,.21]]:
		var v:=p-Vector2(peak[0],peak[1])
		var q:=v.rotated(float(peak[5]))/Vector2(peak[2],peak[3])
		var body: float=peak[4]*exp(-pow(q.x,2.)-pow(q.y,2.))
		# Low broad shelves and cleft shoulders are genuine mesh contours.
		var shoulder: float=peak[4]*.20*exp(-pow(q.x/1.35,2.)-pow((q.y-.72)/1.45,2.))
		var cleft:=.23*exp(-pow((q.x-.25*q.y-.26)/.12,2.))*smoothstep(.25,.75,q.y)
		north=maxf(north,body*(1.-cleft)+shoulder)
	var west:=1.25*exp(-pow((p.x-140.)/240.,2.)-pow((p.y-1450.)/420.,2.))+.65*exp(-pow((p.x-390.)/210.,2.)-pow((p.y-1130.)/210.,2.))
	var southeast:=1.8*exp(-pow((p.x-3930.)/370.,2.)-pow((p.y-2610.)/330.,2.))+.85*exp(-pow((p.x-4190.)/220.,2.)-pow((p.y-2850.)/220.,2.))
	var tea:=.72*exp(-pow((p.x-3370.)/350.,2.)-pow((p.y-2500.)/420.,2.))+.38*exp(-pow((p.x-3090.)/235.,2.)-pow((p.y-2710.)/220.,2.))
	var inland:=.12+.055*sin(p.x/260.)*sin(p.y/195.)
	var result:=maxf(0.,maxf(north,west)+southeast+tea+inland)
	result*=smoothstep(5.,105.,natural_distance(p))
	for deck in bridge_decks:
		var delta: Vector2=(p-deck.get_center()).abs()-deck.size*.5
		result*=smoothstep(42.,130.,Vector2(maxf(delta.x,0.),maxf(delta.y,0.)).length())
	return result

func _authored_height(p: Vector2) -> float:
	var height:=_base_ground(p)
	# Grade roads to local elevations, avoiding old zero-height excavations.
	var nearest:=INF
	var road_height:=height
	for segment in route_buckets.get(Vector2i(floori(p.x/128.),floori(p.y/128.)),[]):
		var d: Vector2=segment[1]-segment[0]
		var t:=clampf((p-segment[0]).dot(d)/maxf(d.length_squared(),.001),0.,1.)
		var distance: float=p.distance_to(segment[0]+d*t)-float(segment[2])*.5
		if distance<nearest:
			nearest=distance
			road_height=lerpf(segment[3],segment[4],t)
	height=lerpf(height,road_height,1.-smoothstep(20.,110.,nearest))
	for site in landmarks:
		var center: Vector2=site["collision_center"]
		var size: Vector2=site["collision_size"]
		var ellipse:=(p-center)/Vector2(size.x*.75+36.,size.y*.75+32.)
		height=lerpf(height,float(site["pad_height"]),1.-smoothstep(.9,2.4,ellipse.length()))
	for spec in native_specs:
		var foot: Vector2=spec["foot"]
		if spec["source"] in [PINE,HERB,TREE]: continue # organic plants follow actual ground, no miniature craters
		height=lerpf(height,float(spec["pad_height"]),1.-smoothstep(82.,175.,p.distance_to(foot)))
	return maxf(height,0.)

func _point(p: Vector2,flat: bool=false) -> Vector3:
	return Vector3((p.x/SIZE.x-.5)*WORLD.x,0.0 if flat else terrain_height(p),(p.y/SIZE.y-.5)*WORLD.y)

func projected(p: Vector2) -> Vector2:
	return Vector2(p.x,p.y-terrain_height(p)*SIZE.y/CAMERA_SIZE/sqrt(2.0))

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
	_curved_route("east_south",[Vector2(4075,2300),Vector2(4000,2570),Vector2(4140,2850)])
	waterways=[
		{"id":"main_river","points":PackedVector2Array([Vector2(1350,2260),Vector2(1650,2170),Vector2(1940,2140),Vector2(2300,2095),Vector2(2750,2190),Vector2(3270,2105),Vector2(3720,2160),Vector2(4075,2133),Vector2(4610,2250)]),"radii":PackedFloat32Array([46,57,65,72,78,75,79,72,110])},
		{"id":"south_branch","points":PackedVector2Array([Vector2(1350,2260),Vector2(1450,2440),Vector2(1500,2610),Vector2(1536,2850),Vector2(1450,3160)]),"radii":PackedFloat32Array([46,49,54,62,75])}]
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
		native_specs.append({"id":"native_pine_%02d"%i,"source":PINE,"foot":foot,"yaw":float((i*67)%360),"scale":1.0,"variant":i%3,"blocking":true,"nature":"small_pine_sapling"})
	# Mature broadleaf patches, not enlarged saplings or copied full groups.
	var tree_sites: Array[Vector2]=[Vector2(550,1370),Vector2(670,1450),Vector2(720,1340),Vector2(820,1460),Vector2(350,600),Vector2(500,620),Vector2(700,620),Vector2(830,620),Vector2(990,675),Vector2(1160,620),Vector2(3100,1200),Vector2(3200,1320),Vector2(3380,1280),Vector2(3480,1430),Vector2(860,2070),Vector2(1000,2130),Vector2(1120,2090),Vector2(1170,2200),Vector2(1060,2290),Vector2(890,2280),Vector2(3000,1890),Vector2(3120,1840),Vector2(3200,1935),Vector2(3310,1950),Vector2(3300,2580),Vector2(3390,2580),Vector2(3500,2640),Vector2(3650,2500),Vector2(3400,2470),Vector2(3500,2590),Vector2(3600,2460),Vector2(3720,2570)]
	for i in tree_sites.size():
		var foot:=tree_sites[i]
		if natural_distance(foot)<100. or _route_distance(foot)<110.: continue
		var clear:=true
		for site in landmarks:
			if Rect2(site["collision_center"]-site["collision_size"]*.5,site["collision_size"]).grow(135.).has_point(foot): clear=false
		if clear: native_specs.append({"id":"native_tree_%02d"%i,"source":TREE,"foot":foot,"yaw":float((i*83+17)%360),"scale":.68+float(i%4)*.055,"variant":0,"blocking":true,"nature":"mature_broadleaf_geographic_scale"})
	for site in landmarks: site["pad_height"]=0. if site["id"] in ["east_sea_port","bailu_ferry"] else _base_ground(site["collision_center"])
	for spec in native_specs: spec["pad_height"]=_base_ground(spec["foot"])
	_index_routes()
	_add_original_groves()
	# Stable, explicit schema is available before GPU capture. Not a ready flag.
	_write_source_contract()

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
		if not ROCK_COLLISION_BLUEPRINTS.has(spec["id"]): continue
		var measured: Array=ROCK_COLLISION_BLUEPRINTS[spec["id"]]
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
		var size:=Vector2(330,235) if is_dock else (Vector2(280,140.6278) if index==1 else Vector2(190,285))
		var path:=OUT+"entities/landmark_bailu_ferry_v1.png" if is_dock else OUT+"entities/"+("bridge_stone_eastwest_v1.png" if index==1 else "bridge_stone_northsouth_v1.png")
		var passage: Array=[]
		if is_dock:
			for p in [Vector2(4190,1861),Vector2(4220,1815),Vector2(4220,1749),Vector2(4220,1714),Vector2(4241,1714)]: passage.append(_pair(projected(p)))
		elif index==1:
			passage=[_pair(projected(center-Vector2(150,0))),_pair(projected(center+Vector2(150,0)))]
		else:
			passage=[_pair(projected(center-Vector2(0,165))),_pair(projected(center+Vector2(0,165)))]
		structures.append({"id":"support_"+str(index),"object_id":object_id,"kind":"dock" if is_dock else "bridge","rect_px":_rect(support),"texture_path":path,"render_center_px":_pair(center),"render_size_px":_pair(size),"source_uv_rect":_rect(Rect2((support.position-center)/size+Vector2(.5,.5),support.size/size)),"passage_px":passage,"support_geometry":"same-camera flat PlaneMesh rendered in final walk only","source_alpha_semantics":"actual stone/wooden deck; rail silhouettes separately Y sorted"})
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
	_json(OUT+"source_contract.json",{"schema_version":14,"world_size":[4608,3072],"status":"ART_ASSETS_READY" if ready else "BUILD_IN_PROGRESS","overview_path":OUT+"overview.png","visual_path":OUT+"visual.png","land_path":OUT+"land.png","walk_path":OUT+"walk.png","raw_walk_path":OUT+"raw_walk.png","geometry_path":OUT+"geometry.json","portals":portal_json,"objects":object_json,"routes":route_json,"seams":seams,"structure_support_rects_px":supports,"structure_entries":structures,"structure_semantics":"first3 actual sea-level bridge decks; last2 sea-level L-shaped Bailu planks, same-camera actual support mesh","waterways":waters,"landmark_sources":sources,"original_vegetation_sources":vegetation,"player_spawn_px":_pair(projected(Vector2(644,1800))),"source_space":"authored source XZ controls; runtime route/portal/player/objects are actual height-camera projections; source and runtime landmark coordinates explicit","camera":{"size":30,"position":[0,36,36],"world_meters":[45,42.42640687]},"no_legacy_tile_copy":true})

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
	for y in topo.get_height():
		for x in topo.get_width():
			var p:=Vector2(x*2.0,y*2.0)
			var dry:=natural_distance(p)>0.0
			var path:=1.0-smoothstep(-8.0,10.0,_route_distance(p))
			var gradient:=terrain_gradient(p)
			var allowed:=dry and natural_distance(p)>24.0 and gradient<0.72
			topo.set_pixel(x,y,Color(1.0 if dry else 0.0,path,1.0 if allowed else 0.0,clampf(terrain_height(p)/5.0,0.0,1.0)))
	assert(topo.save_png(OUT+"source_topology.png")==OK)
	topology_texture=ImageTexture.create_from_image(topo)

func _cache_height_grid() -> void:
	var precomputed:=PackedFloat32Array()
	precomputed.resize((HEIGHT_COLS+1)*(HEIGHT_ROWS+1))
	for y in range(HEIGHT_ROWS+1):
		for x in range(HEIGHT_COLS+1): precomputed[y*(HEIGHT_COLS+1)+x]=_authored_height(Vector2(x*6.0,y*6.0))
	height_grid=precomputed

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

func _export_geometry() -> void:
	var file:=FileAccess.open(OUT+"height_grid.rf",FileAccess.WRITE)
	assert(file!=null)
	file.store_buffer(height_grid.to_byte_array())
	file.close()
	assert(ResourceSaver.save(terrain_mesh,OUT+"terrain_mesh.res")==OK)
	var steep: Array=[]
	var gentle: Array=[]
	for y in range(48,3024,24):
		for x in range(48,4320,24):
			var p:=Vector2(x,y)
			var screen:=projected(p)
			if screen.y<12. or natural_distance(p)<65.: continue
			var gradient:=terrain_gradient(p)
			var item: Dictionary={"source_point":_pair(p),"projected_point":_pair(screen),"height_m":terrain_height(p),"world_gradient":gradient}
			if gradient>.76 and steep.size()<24: steep.append(item)
			if gradient>.08 and gradient<.32 and gentle.size()<24: gentle.append(item)
	var arrays:=terrain_mesh.surface_get_arrays(0)
	var attributes: Dictionary={}
	for item in [[Mesh.ARRAY_VERTEX,"vertex"],[Mesh.ARRAY_NORMAL,"normal"],[Mesh.ARRAY_TEX_UV,"uv"],[Mesh.ARRAY_INDEX,"index"]]:
		var hashing:=HashingContext.new()
		hashing.start(HashingContext.HASH_SHA256)
		hashing.update(arrays[item[0]].to_byte_array())
		attributes[item[1]]=hashing.finish().hex_encode()
	_json(OUT+"geometry.json",{"height_grid_path":OUT+"height_grid.rf","height_grid_shape":[HEIGHT_COLS+1,HEIGHT_ROWS+1],"height_grid_format":"little endian float32 meters, row-major; actual mesh vertex source, not GPU height capture","source_node_spacing_px":[6,6],"terrain_mesh_path":OUT+"terrain_mesh.res","terrain_mesh_sha256":FileAccess.get_sha256(OUT+"terrain_mesh.res"),"mesh_attributes_sha256":attributes,"world_meters":_pair(WORLD),"camera_size":30.,"height_to_projected_y":-SIZE.y/CAMERA_SIZE/sqrt(2.),"steep_examples":steep,"gentle_examples":gentle,"actual_front_winding":"a,b,c,b,d,c same native PlaneMesh","topology_selector_path":OUT+"source_topology.png","nav_selector_spacing_px":2,"natural_shore_clip":"same CPU bank_distance evaluated continuously by native fragment shader"})
	var geometry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"geometry.json"))
	geometry["height_interpolation"]="exact triangle-affine: a+(b-a)*fx+(c-a)*fy when fx+fy<=1; d+(c-d)*(1-fx)+(b-d)*(1-fy) otherwise"
	geometry["gradient_method"]="exact selected GPU triangle derivatives (b-a,c-a) or (d-c,d-b), divided by native world grid XZ size; no central or bilinear approximation"
	_json(OUT+"geometry.json",geometry)

func _mesh(flat: bool=false) -> ArrayMesh:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in HEIGHT_ROWS:
		for x in HEIGHT_COLS:
			var a:=Vector2(float(x)/HEIGHT_COLS,float(y)/HEIGHT_ROWS)
			var b:=Vector2(float(x+1)/HEIGHT_COLS,float(y)/HEIGHT_ROWS)
			var c:=Vector2(float(x)/HEIGHT_COLS,float(y+1)/HEIGHT_ROWS)
			var d:=Vector2(float(x+1)/HEIGHT_COLS,float(y+1)/HEIGHT_ROWS)
			# Godot front-facing winding, same as native PlaneMesh.
			for uv in [a,b,c,b,d,c]:
				surface.set_uv(uv)
				surface.add_vertex(_point(uv*Vector2(SIZE),flat))
	surface.index()
	surface.generate_normals()
	return surface.commit()

func _surface_material(mode: int) -> ShaderMaterial:
	if surface_materials.has(mode): return surface_materials[mode]
	var material:=ShaderMaterial.new()
	var shader:=Shader.new()
	shader.code="""
shader_type spatial;
render_mode cull_disabled,depth_draw_opaque;
uniform sampler2D topo:filter_nearest;
uniform sampler2D grass_scan:source_color,repeat_enable,filter_linear_mipmap;
uniform sampler2D road_scan:source_color,repeat_enable,filter_linear_mipmap;
uniform sampler2D rock_scan:source_color,repeat_enable,filter_linear_mipmap;
uniform int mode=0;
varying vec3 xyz;
varying vec3 terrain_n;
void vertex(){xyz=VERTEX;terrain_n=NORMAL;}
float h(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float n(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h(i),h(i+vec2(1,0)),f.x),mix(h(i+vec2(0,1)),h(i+1.),f.x),f.y);}
float shore(float y){return 4355.+55.*sin(y/285.)-125.*exp(-pow((y-1290.)/116.,2.))-135.*exp(-pow((y-1730.)/108.,2.));}
""" + _waterway_shader() + _foundation_shader() + _cultivation_shader() + """
void fragment(){
 vec2 p=UV*vec2(4608,3072);vec4 t=texture(topo,UV);
 if(bank_distance(p)<0.){discard;}
 if(mode>0){ALBEDO=vec3(mode==1?1.:t.b);}
 else{
 vec3 nn=abs(normalize(terrain_n));nn=pow(nn,vec3(4));nn/=max(nn.x+nn.y+nn.z,.001);
 vec3 rock=texture(rock_scan,xyz.yz/1.8).rgb*nn.x+texture(rock_scan,xyz.xz/1.8).rgb*nn.y+texture(rock_scan,xyz.xy/1.8).rgb*nn.z;
 vec2 war=vec2(n(p/350.),n((p+217.)/285.))-.5;
 float coarse=n((p+war*75.)/240.);float medium=n(p/67.);
 vec3 scan=textureLod(grass_scan,(p+war*32.)/550.,1.).rgb-textureLod(grass_scan,(p+war*32.)/550.,7.).rgb;
 vec3 dirt=texture(road_scan,(p+war*24.)/440.).rgb;
 float grain=dot(dirt,vec3(.299,.587,.114));
 vec3 soil=mix(vec3(.255,.205,.145),vec3(grain)*vec3(.98,.84,.65),.56);
 vec3 grass=mix(vec3(.125,.143,.093),vec3(.228,.231,.146),coarse)+clamp(scan,vec3(-.14),vec3(.14))*.95;
 float south=smoothstep(1650.,2600.,p.y);float northeast=smoothstep(2500.,3600.,p.x)*(1.-smoothstep(700.,1150.,p.y));
 grass=mix(grass,grass*vec3(.72,.94,.90),south*.45+northeast*.24);
 float dry=smoothstep(.25,.68,coarse)*(.46+.29*medium);
 vec3 land=mix(grass,soil,dry);
 float northern=1.-smoothstep(720.,1220.,p.y);
 vec3 north_soil=mix(dirt*vec3(.83,.82,.73),rock*vec3(.69,.71,.68),.43);
 land=mix(land,north_soil,northern*.74);
 float pasture=(1.-smoothstep(1650.,2250.,p.y))*(1.-northern);
 land=mix(land,mix(soil*.90,grass,.35),pasture*.28);
 land=mix(land,mix(soil*vec3(.79,.85,.80),grass*vec3(.78,.90,.83),.56),south*.31);
 float wet=1.-smoothstep(0.,65.+n(p/70.)*30.,bank_distance(p));
 float silt=1.-smoothstep(8.,28.,bank_distance(p));
 land=mix(land,mix(soil*vec3(.84,.90,.85),rock*.77,.23),wet*.75);
 land=mix(land,soil*vec3(1.10,1.08,.91),silt*.50);
 float slope=1.-normalize(terrain_n).y;
 float outcrop=smoothstep(.075,.34,slope)*( .73+.27*n(p/24.) );
 land=mix(land,rock*vec3(.67,.69,.66),outcrop*.90);
 float snow=(1.-smoothstep(900.,1700.,p.x))*smoothstep(1.50,2.70,xyz.y)*(1.-smoothstep(.15,.55,slope))*(.70+.30*n(p/38.));
 land=mix(land,vec3(.29,.33,.35)+rock*.13,snow*.84);
 land=cultivated_land(p,land,soil,grass);
 vec3 path=mix(soil*.87,dirt*vec3(.83,.75,.65),.62);
 float stones=smoothstep(.63,.82,n(p/2.2))*smoothstep(.3,.6,n(p/13.));
 path=mix(path,rock*.79,stones*.21);
 float verge=t.g*(.79+.21*n(p/5.));
 land=mix(land,path,verge*.88);
 vec2 foundation=site_contact(p);
 land=mix(land,mix(soil*.89,rock*.81,.31),foundation.x*.65);
 land*=1.-foundation.y;
 land*=.86+.28*n(p/2.6);
 ALBEDO=land;ROUGHNESS=1.;}
}
"""
	if mode>0: shader.code=shader.code.replace("render_mode cull_disabled,depth_draw_opaque;","render_mode cull_disabled,depth_draw_opaque,unshaded;")
	if not _shader_compiled(shader,["mode","topo","grass_scan","road_scan","rock_scan"],"surface_%d"%mode): return null
	material.shader=shader
	material.set_shader_parameter("topo",topology_texture)
	material.set_shader_parameter("grass_scan",load(GRASS))
	material.set_shader_parameter("road_scan",load(ROAD))
	material.set_shader_parameter("rock_scan",load(ROCK))
	material.set_shader_parameter("mode",mode)
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
	var material:=ShaderMaterial.new()
	var shader:=Shader.new()
	shader.code="""shader_type spatial;render_mode unshaded;
uniform float shader_guard=1.;
uniform sampler2D sediment_scan:source_color,repeat_enable,filter_linear_mipmap;
float shore(float y){return 4355.+55.*sin(y/285.)-125.*exp(-pow((y-1290.)/116.,2.))-135.*exp(-pow((y-1730.)/108.,2.));}
"""+_waterway_shader()+"""
void fragment(){vec2 p=UV*vec2(4608,3072);float depth=max(-bank_distance(p),0.);vec2 drift=vec2(p.x*.024+p.y*.004,p.y*.11-p.x*.018);float shallow=exp(-depth/29.);float mud=exp(-depth/8.);float foam=exp(-pow((depth-2.)/3.8,2.));float flow=sin(drift.y+sin(drift.x)*2.1)*.007+sin(drift.y*.57+drift.x*.32)*.006;vec3 sediment=texture(sediment_scan,p/310.).rgb*vec3(.76,.86,.82);vec3 deep=mix(vec3(.065,.158,.181),vec3(.115,.197,.210),.5+.5*sin(p.y/760.+p.x/560.));vec3 color=mix(deep,vec3(.24,.29,.245)+sediment*.11,shallow*.68);color=mix(color,sediment*.66,mud*.24);ALBEDO=(color+flow+foam*.025)*shader_guard;ROUGHNESS=.45;}
"""
	if not _shader_compiled(shader,["shader_guard","sediment_scan"],"water"): return null
	material.shader=shader
	material.set_shader_parameter("sediment_scan",load(ROAD))
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

func _cultivation_shader() -> String:
	var code:="vec3 cultivated_land(vec2 p,vec3 base,vec3 soil,vec3 grass){"
	var fields: Array=[[720.,1850.,140.,75.,.14,0.],[930.,1830.,105.,62.,-.21,0.],[1100.,1850.,120.,80.,.27,0.],[1470.,1510.,125.,85.,-.24,0.],[1670.,1560.,112.,78.,.20,0.],[1840.,1590.,130.,95.,-.08,0.],[2700.,1500.,120.,95.,-.12,0.],[2860.,1550.,135.,78.,.20,0.],[3230.,1870.,110.,82.,.36,1.],[3410.,1890.,123.,78.,-.20,1.],[620.,2580.,125.,82.,-.23,1.],[810.,2510.,118.,85.,.18,1.],[2260.,2380.,122.,84.,.30,1.],[2470.,2460.,125.,80.,-.16,1.],[3050.,2610.,130.,100.,-.24,2.],[3220.,2550.,112.,92.,.12,2.],[3360.,2710.,120.,85.,.30,2.],[3650.,2410.,128.,85.,-.21,2.]]
	for f in fields:
		code+="{vec2 v=p-vec2(%f,%f);vec2 q=mat2(vec2(cos(%f),-sin(%f)),vec2(sin(%f),cos(%f)))*v;vec2 axes=vec2(%f,%f);float bound=max(abs(q.x)/axes.x,abs(q.y)/axes.y)+.075*(n(p/19.)-.5)+.08*abs(q.x*q.y)/(axes.x*axes.y);float field=1.-smoothstep(.85,.98,bound);float spacing=%f;float bend=q.y+.06*q.x*q.x/axes.x+7.*sin(q.x/65.);float row=floor(bend/spacing);float row_distance=abs(mod(bend+spacing*.5,spacing)-spacing*.5);float row_end=axes.x*(.56+.38*h(vec2(row,%f)));float end_mask=1.-smoothstep(row_end-8.,row_end,abs(q.x));float crop=(1.-smoothstep(%f,%f,row_distance))*end_mask*smoothstep(.22,.55,n(vec2(q.x/4.,row*3.)));float soil_detail=.85+.23*n(p/2.1);vec3 field_soil=mix(soil*%f,texture(road_scan,p/190.).rgb*vec3(.68,.57,.43),.42)*soil_detail;float bank=smoothstep(.72,.77,bound)*(1.-smoothstep(.83,.89,bound));field_soil*=1.-bank*.15;vec3 leaf=grass*vec3(%f,%f,%f);vec3 worked=mix(field_soil,leaf,crop*.58);base=mix(base,worked,field*(1.-texture(topo,p/vec2(4608,3072)).g)*.88);}"%[f[0],f[1],f[4],f[4],f[4],f[4],f[2],f[3],11. if f[5]==0. else 14.,f[0],.9 if f[5]==0. else 1.4,1.8 if f[5]==0. else 2.8,.91 if f[5]==0. else .78,1.05 if f[5]==0. else .73,1.02 if f[5]==0. else .96,.68 if f[5]==0. else .64]
	code+="return base;}"
	return code

func _viewport(mode: int) -> SubViewport:
	var viewport:=SubViewport.new()
	viewport.size=SIZE
	viewport.own_world_3d=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world:=Node3D.new()
	viewport.add_child(world)
	var env:=WorldEnvironment.new()
	var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color.BLACK if mode>0 else Color(.05,.115,.135)
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color(.90,.94,1.0)
	settings.ambient_light_energy=.54
	env.environment=settings
	world.add_child(env)
	if mode==0:
		var water:=MeshInstance3D.new()
		water.mesh=_mesh(true)
		water.position.y=-.04
		water.material_override=_water_material()
		water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(water)
	var land:=MeshInstance3D.new()
	land.name="ActualTerrain"
	land.mesh=terrain_mesh
	land.material_override=_surface_material(mode)
	land.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(land)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-34,0)
	light.light_energy=1.05
	light.shadow_enabled=mode==0
	light.shadow_bias=.02
	light.shadow_normal_bias=.08
	light.directional_shadow_max_distance=95.0
	light.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	world.add_child(light)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=CAMERA_SIZE
	camera.position=Vector3(0,36,36)
	world.add_child(camera)
	camera.look_at(Vector3.ZERO)
	camera.current=true
	return viewport

func _sync() -> void:
	for frame in 8: await process_frame
	await RenderingServer.frame_post_draw

func _shader_preflight() -> void:
	var prefix:="res://build/world_map_v14_fourth_material_preflight/"
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
		var plane:=MeshInstance3D.new()
		var plane_mesh:=PlaneMesh.new()
		plane_mesh.size=Vector2(10,10)
		plane.mesh=plane_mesh
		plane.material_override=material
		world.add_child(plane)
		var light:=DirectionalLight3D.new()
		light.rotation_degrees=Vector3(-55,-34,0)
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
		var saved:=frame.save_png(prefix+"mode_%d.png"%mode)==OK
		all_valid=all_valid and expected and saved
		cases.append({"mode":mode,"compiled":true,"center_rgba":[pixel.r,pixel.g,pixel.b,pixel.a],"expected_fragment_output":expected,"saved":saved})
		view.queue_free()
		await process_frame
	_json(prefix+"result.json",{"status":"MATERIAL_PREFLIGHT_PASS" if all_valid else "MATERIAL_PREFLIGHT_FAIL","intentional_invalid_shader_rejected":rejected,"compiler_gates":shader_gate_results,"actual_gpu_cases":cases,"full_world_capture":false,"sync":"8 frames and frame_post_draw"})
	if not all_valid:
		_fail_candidate("Native shader preflight failed; no full world capture started")
		return
	print("[WorldV14] MATERIAL_PREFLIGHT_PASS: invalid shader rejected; all four actual GPU fragment outputs match")
	quit(0)

func _meshes(node: Node,result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D: result.append(node)
	for child in node.get_children(): _meshes(child,result)

func _tree_geometry_audit() -> void:
	# CPU-only capability check: no build hooks, no image/metadata writes.
	var document:=GLTFDocument.new()
	var state:=GLTFState.new()
	if document.append_from_file(TREE,state)!=OK:
		quit(1)
		return
	var scene:=document.generate_scene(state)
	var nodes: Array[MeshInstance3D]=[]
	_meshes(scene,nodes)
	for node in nodes:
		var importer:=ImporterMesh.new()
		var triangles:=0
		for surface in node.mesh.get_surface_count():
			var arrays:=node.mesh.surface_get_arrays(surface)
			triangles+=arrays[Mesh.ARRAY_INDEX].size()/3
			importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},node.mesh.surface_get_material(surface))
		print("[TreeAudit] source node=",node.name," triangles=",triangles)
		importer.generate_lods(60.,60.,[])
		for surface in importer.get_surface_count():
			var lods: Array=[]
			for lod in importer.get_surface_lod_count(surface):
				lods.append({"distance":importer.get_surface_lod_size(surface,lod),"triangles":importer.get_surface_lod_indices(surface,lod).size()/3})
			print("[TreeAudit] surface=",surface," actual_native_lods=",JSON.stringify(lods))
	scene.free()
	quit(0)

func _derived_tree_mesh(source: ArrayMesh) -> ArrayMesh:
	if tree_lod_mesh!=null: return tree_lod_mesh
	var importer:=ImporterMesh.new()
	for surface in source.get_surface_count():
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,source.surface_get_arrays(surface),[],{},source.surface_get_material(surface))
	importer.generate_lods(60.,60.,[])
	var result:=ArrayMesh.new()
	var records: Array=[]
	for surface in source.get_surface_count():
		if importer.get_surface_lod_count(surface)<=2: return null
		var arrays:=source.surface_get_arrays(surface).duplicate(true)
		var indices:=importer.get_surface_lod_indices(surface,2)
		arrays[Mesh.ARRAY_INDEX]=indices
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		result.surface_set_material(surface,source.surface_get_material(surface))
		var hashing:=HashingContext.new()
		hashing.start(HashingContext.HASH_SHA256)
		hashing.update(indices.to_byte_array())
		records.append({"surface":surface,"lod_index":2,"lod_distance":importer.get_surface_lod_size(surface,2),"actual_triangles":indices.size()/3,"indices_sha256":hashing.finish().hex_encode()})
	tree_lod_recipe={"method":"actual Godot ImporterMesh.generate_lods(60,60,[]) then index-only select LOD2 per surface","source_sha256":FileAccess.get_sha256(TREE),"original_triangles":2062487,"surfaces":records,"same_mesh_for_alpha_and_cast":true}
	tree_lod_mesh=result
	return result

func _prepare_native_models() -> void:
	for spec in native_specs:
		var imported: Node3D
		if model_templates.has(spec["source"]):
			imported=model_templates[spec["source"]]
		elif spec["source"] in [PINE,TREE]:
			var document:=GLTFDocument.new()
			var state:=GLTFState.new()
			assert(document.append_from_file(spec["source"],state)==OK)
			imported=document.generate_scene(state) as Node3D
		else:
			imported=(load(spec["source"]) as PackedScene).instantiate()
		model_templates[spec["source"]]=imported
		var meshes: Array[MeshInstance3D]=[]
		_meshes(imported,meshes)
		var model:=Node3D.new()
		model.rotation_degrees.y=float(spec["yaw"])
		model.scale=Vector3.ONE*float(spec["scale"])
		var mesh: MeshInstance3D=meshes[int(spec["variant"])].duplicate()
		if spec["source"]==TREE:
			mesh.mesh=_derived_tree_mesh(mesh.mesh as ArrayMesh)
			assert(mesh.mesh!=null)
		mesh.transform=Transform3D.IDENTITY
		for child in mesh.get_children(): child.free()
		model.add_child(mesh)
		var bounds:=AABB()
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
		var contact:=Vector3(support.get_center().x,bounds.position.y,support.end.z)
		var ground:=_point(spec["foot"])
		model.position=ground-contact
		var foot: Vector2=projected(spec["foot"])
		var collider:=Vector2(bounds.size.x*SIZE.x/WORLD.x,bounds.size.z*SIZE.y/WORLD.y)
		var collision_center:=foot+Vector2((bounds.get_center().x-contact.x)*SIZE.x/WORLD.x,(bounds.get_center().z-contact.z)*SIZE.y/WORLD.y)
		if spec["source"] in [PINE,TREE]:
			# Canopy is Y-sorted alpha, not a solid canopy-sized XZ rectangle.
			collider=Vector2(12,9) if spec["source"]==PINE else Vector2(18,14)
			collision_center=foot+Vector2(0,-5 if spec["source"]==PINE else -8)
		if ROCK_COLLISION_BLUEPRINTS.has(spec["id"]):
			var expected: Array=ROCK_COLLISION_BLUEPRINTS[spec["id"]]
			assert(collider.distance_to(Vector2(expected[2],expected[3]))<.02 and (collision_center-foot).distance_to(Vector2(expected[0],expected[1]))<.02,"Actual independent native model physical bounds diverged from surveyed road-clearance blueprint")
		models.append({"spec":spec,"node":model,"ground":ground,"foot":foot,"bounds":bounds,"contact":contact,"collision_size":collider,"collision_center":collision_center,"vertex_count":vertices.size(),"source_mesh_node":mesh.name})

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

func _capture_native_entity(entry: Dictionary) -> Image:
	var viewport:=SubViewport.new()
	var bounds: AABB=entry["bounds"]
	var contact: Vector3=entry["contact"]
	var extent:=0.
	for corner in 8:
		var vertex: Vector3=bounds.get_endpoint(corner)-contact
		extent=maxf(extent,maxf(absf(vertex.x*102.4),absf((vertex.z-vertex.y)/sqrt(2.)*102.4)))
	var canvas:=maxi(512,ceili((extent*2.+32.)/256.)*256)
	viewport.size=Vector2i(canvas,canvas)
	viewport.own_world_3d=true
	viewport.transparent_bg=true
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var world:=Node3D.new()
	viewport.add_child(world)
	var env:=WorldEnvironment.new()
	var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color.TRANSPARENT
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color(.90,.94,1.0)
	settings.ambient_light_energy=.54
	env.environment=settings
	world.add_child(env)
	var light:=DirectionalLight3D.new()
	light.rotation_degrees=Vector3(-55,-34,0)
	light.light_energy=1.05
	world.add_child(light)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=float(canvas)/102.4
	camera.position=entry["ground"]+Vector3(0,36,36)
	world.add_child(camera)
	camera.look_at(entry["ground"])
	camera.current=true
	world.add_child(entry["node"].duplicate())
	await _sync()
	var body:=viewport.get_texture().get_image()
	body.convert(Image.FORMAT_RGBA8)
	await _sync()
	var repeat:=viewport.get_texture().get_image()
	repeat.convert(Image.FORMAT_RGBA8)
	assert(body.get_data()==repeat.get_data() and body.get_pixel(0,0).a==0 and body.get_used_rect().has_area())
	var rect:=body.get_used_rect().grow(4).intersection(Rect2i(0,0,canvas,canvas))
	assert(rect.size.x<canvas-12 and rect.size.y<canvas-12)
	var id: String=entry["spec"]["id"]
	var path:=OUT+"entities/"+id+".png"
	assert(body.save_png(OUT+"entities/"+id+"_sourcebody.png")==OK)
	assert(repeat.save_png(OUT+"entities/"+id+"_sourcebody_repeat.png")==OK)
	assert(body.get_region(rect).save_png(path)==OK)
	var body_foot:=camera.unproject_position(entry["ground"])
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
	_json(OUT+"entities/"+id+".json",{"id":id,"texture_path":path,"source":entry["spec"]["source"],"source_sha256":FileAccess.get_sha256(entry["spec"]["source"]),"source_foot":_pair(entry["spec"]["foot"]),"world_foot":_pair(foot),"foot_uv":_pair(uv),"size":_pair(size),"collision_center":_pair(collision_center),"collision_size":_pair(entry["collision_size"]),"depth_y":foot.y,"blocking":entry["spec"]["blocking"],"actual_vertex_count":entry["vertex_count"],"actual_min_vertex_ground_delta":model.position.y+bounds.position.y-ground.y,"model_position_m":[model.position.x,model.position.y,model.position.z],"ground_m":[ground.x,ground.y,ground.z],"support_contact_m":[contact.x,contact.y,contact.z],"actual_transformed_bounds":[bounds.position.x,bounds.position.y,bounds.position.z,bounds.size.x,bounds.size.y,bounds.size.z],"source_variant":entry["spec"]["variant"],"support_method":"minY and frontZ of actual lowest6percent vertices; synthetic support contact, not literal vertex","same_native_camera_orientation_px_per_meter":102.4,"sourcebody_camera_foot":_pair(body_foot),"sourcebody_canvas":[512,512],"sourcebody_repeat_exact":true,"sourcebody_crop_rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"sourcebody_path":OUT+"entities/"+id+"_sourcebody.png","sourcebody_repeat_path":OUT+"entities/"+id+"_sourcebody_repeat.png","sourcebody_origin_world_px":_pair(foot-body_foot),"model_scale":entry["spec"]["scale"],"yaw":entry["spec"]["yaw"],"nature":entry["spec"].get("nature","solid_rock" if entry["spec"]["blocking"] else "natural_groundcover")})
	var metadata: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OUT+"entities/"+id+".json"))
	metadata["source_mesh_node"]=String(entry["source_mesh_node"])
	metadata["sourcebody_canvas"]=[canvas,canvas]
	metadata["actual_vertex_semantics"]="unique indices referenced by actually drawn triangles; unused source-array vertices excluded"
	metadata["collision_method"]="narrow trunk 12x9px" if entry["spec"]["source"]==PINE else ("narrow mature trunk 18x14px; canopy alpha not solid" if entry["spec"]["source"]==TREE else "full actual transformed draw-vertex XZ bounds; nonblocking low herbs")
	if entry["spec"]["source"]==TREE: metadata["derived_mesh_recipe"]=tree_lod_recipe
	entry["body_origin"]=foot-body_foot
	_json(OUT+"entities/"+id+".json",metadata)
	viewport.queue_free()
	await process_frame
	return body

func _support_mesh(world: Node) -> void:
	for rect in bridge_decks:
		var deck:=MeshInstance3D.new()
		var plane:=PlaneMesh.new()
		plane.size=rect.size/Vector2(SIZE)*WORLD
		deck.mesh=plane
		deck.position=_point(rect.get_center(),true)+Vector3(0,.005,0)
		var mat:=StandardMaterial3D.new()
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color=Color.WHITE
		deck.material_override=mat
		deck.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(deck)

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
	await _sync()
	var image:=viewport.get_texture().get_image()
	assert(image!=null and image.get_size()==SIZE)
	image.convert(Image.FORMAT_RGBA8)
	assert(image.save_png(OUT+name+".png")==OK)
	for row in 3:
		for col in 3:
			var crop:=image.get_region(Rect2i(col*1536,row*1024,1536,1024))
			assert(crop.save_png(OUT+"chunks/r%dc%d_%s.png"%[row,col,name])==OK)
	return image

func _build() -> void:
	DirAccess.make_dir_recursive_absolute(OUT+"chunks")
	DirAccess.make_dir_recursive_absolute(OUT+"entities")
	_json(OUT+"manifest.json",{"version":"world_v14","status":"BUILD_IN_PROGRESS","production_approved":false,"world_size":[4608,3072]})
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
	_export_geometry()
	print("[WorldV14] actual front-facing terrain mesh ready")
	_prepare_native_models()
	if models.size()!=native_specs.size():
		_fail_candidate("Incomplete actual native model construction")
		return
	if tree_lod_mesh!=null:
		assert(ResourceSaver.save(tree_lod_mesh,OUT+"entities/tree_small02_native_lod2.res")==OK)
		tree_lod_recipe["derived_mesh_path"]=OUT+"entities/tree_small02_native_lod2.res"
		tree_lod_recipe["derived_mesh_sha256"]=FileAccess.get_sha256(OUT+"entities/tree_small02_native_lod2.res")
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
	var visual: Image=await _save_capture(viewport,"visual")
	if visual==null:
		_fail_candidate("Terrain visual capture failed")
		return
	_native_casters(viewport.get_child(0))
	var shadow_on: Image=await _save_capture(viewport,"shadow_on")
	await _sync()
	var on_repeat:=viewport.get_texture().get_image()
	on_repeat.convert(Image.FORMAT_RGBA8)
	assert(shadow_on.get_data()==on_repeat.get_data())
	assert(on_repeat.save_png(OUT+"shadow_on_repeat.png")==OK)
	for child in viewport.get_child(0).get_children():
		if String(child.name).begins_with("Caster_"): child.visible=false
	var shadow_off: Image=await _save_capture(viewport,"shadow_off")
	assert(visual.get_data()==shadow_off.get_data())
	await _sync()
	var off_repeat:=viewport.get_texture().get_image()
	off_repeat.convert(Image.FORMAT_RGBA8)
	assert(shadow_off.get_data()==off_repeat.get_data())
	assert(off_repeat.save_png(OUT+"shadow_off_repeat.png")==OK)
	viewport.get_child(0).get_node("ActualTerrain").material_override=_surface_material(1)
	for child in viewport.get_child(0).get_children():
		if child is WorldEnvironment: child.environment.background_color=Color.BLACK
		if child is MeshInstance3D and child.name!="ActualTerrain": child.visible=false
	var land: Image=await _save_capture(viewport,"land")
	viewport.get_child(0).get_node("ActualTerrain").material_override=_surface_material(2)
	await _save_capture(viewport,"raw_walk")
	# Same-camera real support geometry, never reclassifies natural water land.
	_support_mesh(viewport.get_child(0))
	var walk: Image=await _save_capture(viewport,"walk")
	var actual_shadow:=_shadow(shadow_on,shadow_off,land,union)
	if actual_shadow==null or not actual_shadow.get_used_rect().has_area():
		_fail_candidate("Actual native ground shadow empty or invalid")
		return
	_write_source_contract(true)
	_overview(visual)
	var topology:=land.duplicate() as Image
	assert(topology.save_png(OUT+"topology.png")==OK)
	var sources: Array=[]
	for path in [GRASS,ROAD,ROCK,BOULDER,HERB,PINE,TREE,native_specs[5]["source"]]: sources.append({"path":path,"sha256":FileAccess.get_sha256(path),"license":"PolyHaven CC0 registered; pine/tree official verified SOURCE.json 20261002"})
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
	var completed: Dictionary={"version":"world_v14","status":"ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","production_approved":false,"world_size":[4608,3072],"tile_size":[1536,1024],"regions":regions,"continuous_shared_mesh":true,"mesh_triangles":HEIGHT_COLS*HEIGHT_ROWS*2,"source_height":"build_world_map_native_full_v14.gd::terrain_height","topology":"source_topology.png CPU selector; actual land/walk captures same mesh and camera","raw_walk_path":OUT+"raw_walk.png","source_contract_path":OUT+"source_contract.json","overview_path":OUT+"overview.png","capture_sync":"eight process frames then frame_post_draw","camera":{"position":[0,36,36],"size":30,"orthographic":true},"light":{"rotation":[-55,-34,0],"energy":1.05,"ambient":.54},"sources":sources,"legacy_landmarks":true,"visual_approved":false,"native_model_count":models.size(),"real_shadow_path":OUT+"native_shadow.png","raw_visual_sha":FileAccess.get_sha256(OUT+"visual.png"),"land_sha":FileAccess.get_sha256(OUT+"land.png"),"walk_sha":FileAccess.get_sha256(OUT+"walk.png")}
	completed["geometry_path"]=OUT+"geometry.json"
	completed["height_grid_path"]=OUT+"height_grid.rf"
	completed["terrain_mesh_path"]=OUT+"terrain_mesh.res"
	completed["shadow_evidence"]={"on":OUT+"shadow_on.png","off":OUT+"shadow_off.png","on_repeat":OUT+"shadow_on_repeat.png","off_repeat":OUT+"shadow_off_repeat.png","body_union":OUT+"native_body_union.png","ground_shadow":OUT+"native_shadow.png","body_exclusion_dilation_px":2,"relative_luma_threshold":.015,"maximum_alpha":.85,"on_off_each_repeat_actual_readback":true}
	completed["mesh_triangles"]=HEIGHT_COLS*HEIGHT_ROWS*2
	completed["capture_iteration"]=4
	completed["capture_history"]={"first":"visual FAIL archived in build/world_map_v14_first_iteration","second":"TECHNICAL_FAIL mat2 compiler; archived in build/world_map_v14_second_shader_failure","third":"technical retry of second composition, shader constructor fix only; visual FAIL and actual Field contract failures preserved by producer","fourth":"authored multi-summit relief/local road grade/exact triangle projection, short tilled plots/shallow sediment shores, actual mature tree LOD2, source route-clearance correction and semantic bridge railing pieces"}
	completed["current_outputs_not_ready"]=false
	completed["mature_tree_native_lod_recipe"]=tree_lod_recipe
	completed["height_interpolation"]="GPU mesh triangles a,b,c then b,d,c; split fx+fy=1; exact piecewise affine, not bilinear"
	completed["native_shader_compiler_gate"]=shader_gate_results
	completed["first_visual_fail_archive"]="res://build/world_map_v14_first_iteration/"
	completed["native_sourcebody_schema"]="entities/<id>.json plus sourcebody/repeat exact; actual vertex transform/lowest6percent contact and projected foot"
	_json(OUT+"manifest.json",completed)
	print("[WorldV14] complete shared native 4608x3072 terrain and 9x3 chunks exported; not yet visual approved; landmarks=",landmarks.size()," routes=",routes.size())
	viewport.queue_free()
	for entry in models: entry["node"].free()
	models.clear()
	for template in model_templates.values(): template.free()
	model_templates.clear()
	surface_materials.clear()
	compiled_water_material=null
	topology_texture=null
	terrain_mesh=null
	tree_lod_mesh=null
	for frame in 12: await process_frame
	quit(0)
