extends RefCounted

# Independent v15 authoring. Nothing is sampled from sealed v14 output pixels.
# Authoring placements are NOT measured source-image doorway UV coordinates.
const SCHEMA := 15
const SIZE := Vector2i(12288, 8192)
const TILE := Vector2i(1536, 1024)
const GRID_STEP := 8
const GRID_SIZE := Vector2i(1537, 1025)
const SELECTOR_STEP := 2
const PPM := 102.4
const Z_PPM := PPM * 0.7071067811865476
const WATER_Y := -0.025
const MAX_GRADIENT := 0.72
const SHORE_MARGIN_PX := 28.0
const OUT := "res://art/maps/world_map_v15/"
const SEMANTICS_PATH := OUT + "landmark_semantics.json"
const NATIVE_SOURCE_DIR := "res://art/external/polyhaven/"
const ORIGINAL_DIR := "res://art/modules/world_map_v13/"
const CORE_IDS := ["huashan", "luoyang", "bianzhou", "gufeng", "wudang", "xiangzhou", "jinling", "lingyue"]
const MIN_CORE_SPACING := 3072.0
const FOOT_RADIUS := Vector2(10,6)
const BAMBOO_TEXTURES := ["res://art/modules/veg/veg_bamboo_single_a.png","res://art/modules/veg/veg_bamboo_single_b.png"]
const BAMBOO_STANDS := [Vector2(3500,6750),Vector2(3820,6950),Vector2(10900,5580)]
const LANDMARKS := [
 {"id":"yanmen_pass", "foot":Vector2(3000,700), "source":ORIGINAL_DIR+"landmark_yanmen_pass_v1.png", "width":620., "target":"openworld_yanmen_pass", "target_pos":Vector2(.25,.78)},
 {"id":"huashan", "foot":Vector2(700,2300), "source":OUT+"entities/sect_huashan_compound_v1.png", "width":620., "target":"openworld_huashan_forecourt", "target_pos":Vector2(.5,.885)},
 {"id":"luoyang", "foot":Vector2(4000,2600), "source":ORIGINAL_DIR+"landmark_luoyang_city_v1.png", "width":720., "target":"ch4_s0_luoyang_gate", "target_pos":Vector2(.5,.9)},
 {"id":"bianzhou", "foot":Vector2(7600,2200), "source":ORIGINAL_DIR+"city_walled_compound_proto_v1.png", "width":720., "target":"openworld_bianzhou_city", "target_pos":Vector2(.535,.9)},
 {"id":"gufeng", "foot":Vector2(10900,1200), "source":OUT+"entities/sect_gufeng_compound_v1.png", "width":620., "target":"ch5_s1_relief_road", "target_pos":Vector2(.52,.9)},
 {"id":"linxi_village", "foot":Vector2(2600,4000), "source":ORIGINAL_DIR+"landmark_linxi_village_v1.png", "width":440., "target":"linxi_village_scrollmap", "target_pos":Vector2(.925,.5)},
 {"id":"qinghe_town", "foot":Vector2(4700,4400), "source":ORIGINAL_DIR+"landmark_qinghe_town_v1.png", "width":460., "target":"openworld_qinghe_town", "target_pos":Vector2(.3,.78)},
 {"id":"zhuwei_village", "foot":Vector2(6500,4700), "source":ORIGINAL_DIR+"landmark_zhuwei_village_v1.png", "width":440., "target":"ch1_s2_qingfeng", "target_pos":Vector2(.52,.79)},
 {"id":"wudang", "foot":Vector2(1400,5600), "source":OUT+"entities/sect_wudang_compound_v1.png", "width":620., "target":"openworld_wudang_gate", "target_pos":Vector2(.5,.875)},
 {"id":"xiangzhou", "foot":Vector2(4800,6000), "source":ORIGINAL_DIR+"landmark_xiangzhou_city_v1.png", "width":720., "target":"openworld_xiangzhou_city", "target_pos":Vector2(.515,.9)},
 {"id":"jinling", "foot":Vector2(8100,6500), "source":ORIGINAL_DIR+"city_jinling_river_v1.png", "width":720., "target":"openworld_jinling_city", "target_pos":Vector2(.51,.9)},
 {"id":"bailu_ferry", "foot":Vector2(9300,4300), "source":ORIGINAL_DIR+"landmark_bailu_ferry_v1.png", "width":520., "target":"openworld_bailu_ferry", "target_pos":Vector2(.42,.73)},
 {"id":"east_sea_port", "foot":Vector2(11700,3500), "source":ORIGINAL_DIR+"landmark_east_sea_port_v1.png", "width":560., "target":"openworld_east_sea_port", "target_pos":Vector2(.5,.78)},
 {"id":"mingwu", "foot":Vector2(7600,7800), "source":ORIGINAL_DIR+"landmark_mingwu_tea_town_v1.png", "width":560., "target":"ch7_s2_mingwu_tea_town", "target_pos":Vector2(.5,.875)},
 {"id":"lingyue", "foot":Vector2(11500,5900), "source":OUT+"entities/sect_lingyue_compound_v1.png", "width":620., "target":"ch2_s4_lingyue_gate", "target_pos":Vector2(.11,.78)},
 {"id":"lieyun_valley", "foot":Vector2(10200,7500), "source":ORIGINAL_DIR+"landmark_lieyun_gorge_v1.png", "width":560., "target":"ch7_s1_lieyun_valley_ferry", "target_pos":Vector2(.5,.875)}]

# Natural regions overlap across chunk edges. These are ecological authoring
# domains, not uniform tile colours. Fictional sect placements are narrative.
const HABITATS := [
 {"id":"northern_snow_ridge","center":Vector2(5000,430),"radius":Vector2(4600,860),"forest":.08,"rock":.92,"wet":0.,"snow":.88},
 {"id":"western_limestone","center":Vector2(1200,2000),"radius":Vector2(1600,1750),"forest":.18,"rock":.65,"wet":.02,"snow":.05},
 {"id":"north_eastern_pine","center":Vector2(10300,1800),"radius":Vector2(1800,1600),"forest":.90,"rock":.40,"wet":.04,"snow":.18},
 {"id":"luoyang_farmland","center":Vector2(4100,3100),"radius":Vector2(2000,1300),"forest":.12,"rock":.04,"wet":.12,"snow":0.},
 {"id":"central_meadow","center":Vector2(6600,3800),"radius":Vector2(2100,1900),"forest":.18,"rock":.06,"wet":.18,"snow":0.},
 {"id":"western_woodland","center":Vector2(1700,4500),"radius":Vector2(1450,1400),"forest":.92,"rock":.14,"wet":.12,"snow":0.},
 {"id":"southern_bamboo","center":Vector2(3700,6800),"radius":Vector2(2500,1600),"forest":.88,"rock":.12,"wet":.35,"snow":0.},
 {"id":"jiangnan_river_fields","center":Vector2(7900,6100),"radius":Vector2(2200,1800),"forest":.18,"rock":.08,"wet":.58,"snow":0.},
 {"id":"southeastern_marsh","center":Vector2(10800,7100),"radius":Vector2(1400,1300),"forest":.32,"rock":.02,"wet":.96,"snow":0.},
 {"id":"lingyue_bamboo_hills","center":Vector2(10800,5400),"radius":Vector2(1500,1450),"forest":.87,"rock":.18,"wet":.28,"snow":0.}]

# Authored river center-lines join at identical nodes, with broad smooth bends.
# All sampled geometry/colour/navigation derive from these source coordinates.
const RIVERS := [
 {"id":"northern_river","width":112.,"points":[Vector2(500,1550),Vector2(2000,1800),Vector2(4300,1500),Vector2(6200,1700),Vector2(8600,3000),Vector2(10900,3600),Vector2(12400,3900)]},
 {"id":"southern_river","width":142.,"points":[Vector2(-150,6400),Vector2(2100,6500),Vector2(4200,7000),Vector2(6500,6100),Vector2(8300,5600),Vector2(10300,6300),Vector2(12400,6900)]},
 {"id":"bailu_tributary","width":74.,"points":[Vector2(8600,3000),Vector2(9000,3700),Vector2(9700,4700),Vector2(8300,5600)]}]

# Routes approach landmarks from their front (south), not through solid courts.
# Networks are not three full-width horizontal / vertical programmatic lanes.
const ROAD_DEFS := [
 ["western_royal_road",[Vector2(700,2440),Vector2(1600,2700),Vector2(2800,2860),Vector2(4000,2740),Vector2(5600,2680),Vector2(7600,2340)],60.],
 ["northern_pass_road",[Vector2(3000,840),Vector2(3100,1100),Vector2(3400,1440),Vector2(3700,1920),Vector2(4000,2740)],54.],
 ["northeastern_trade",[Vector2(7600,2340),Vector2(8300,2240),Vector2(9000,2100),Vector2(10100,1700),Vector2(10900,1340)],56.],
 ["western_village_road",[Vector2(2800,2860),Vector2(2400,3320),Vector2(2600,4140),Vector2(1950,4900),Vector2(1400,5740)],52.],
 ["central_town_road",[Vector2(4000,2740),Vector2(4400,3300),Vector2(4700,4540),Vector2(5800,4780),Vector2(6500,4840)],54.],
 ["xiangzhou_road",[Vector2(4700,4540),Vector2(4900,5100),Vector2(4800,6140),Vector2(3800,6140),Vector2(2500,5920),Vector2(1400,5740)],60.],
 ["jiangnan_road",[Vector2(6500,4840),Vector2(7200,5100),Vector2(8100,6640),Vector2(8500,7200),Vector2(7600,7940)],58.],
 ["eastern_trade_road",[Vector2(7600,2340),Vector2(8000,2250),Vector2(8150,2360),Vector2(8170,2880),Vector2(9300,3200),Vector2(10100,4100),Vector2(11700,3640)],58.],
 ["bailu_road",[Vector2(10100,4100),Vector2(9700,4440),Vector2(9300,4440)],50.],
 ["bamboo_marsh_road",[Vector2(8100,6640),Vector2(9200,6800),Vector2(10200,7640),Vector2(11200,6940),Vector2(11500,6040)],54.],
 ["lingyue_approach",[Vector2(10100,4100),Vector2(10900,4900),Vector2(11500,6040)],50.]]

var routes: Array[Dictionary] = []
var rivers: Array[Dictionary] = []
var heights := PackedFloat32Array()
var semantics: Dictionary = {}
var last_error := ""
var road_buckets: Dictionary = {}
var river_buckets: Dictionary = {}
var vertex_cache: Dictionary = {}
var structures: Array[Dictionary] = []
const BUCKET := 256.0

func prepare() -> void:
	routes.clear()
	rivers.clear()
	for raw in ROAD_DEFS:
		routes.append({"id":raw[0],"points":_smooth(raw[1]),"half_width_px":raw[2],"kind":"public_road"})
	for raw in RIVERS:
		rivers.append({"id":raw["id"],"points":_smooth(raw["points"]),"half_width_px":raw["width"]})
	for entry in LANDMARKS:
		var foot: Vector2 = entry["foot"]
		routes.append({"id":"portal_"+String(entry["id"]),"points":PackedVector2Array([foot+Vector2(0,140),foot]),"half_width_px":48.,"kind":"door_approach","portal_id":entry["id"]})
	_index_segments(routes,road_buckets,160.)
	_index_segments(rivers,river_buckets,360.)
	_prepare_structures()
	# A physical bridge is straight. Replace the local curved road segment by
	# its actual deck axis, not a wider white navigation rectangle.
	for structure in structures:
		for route in routes:
			if route["id"]!=structure["route_id"]: continue
			var old: PackedVector2Array=route["points"]
			var entry: Vector2=structure["source_passage_px"][0]
			var exit: Vector2=structure["source_passage_px"][1]
			var first := 0
			var last := 0
			var first_distance := INF
			var last_distance := INF
			for i in range(old.size()):
				if old[i].distance_squared_to(entry)<first_distance:
					first_distance=old[i].distance_squared_to(entry)
					first=i
				if old[i].distance_squared_to(exit)<last_distance:
					last_distance=old[i].distance_squared_to(exit)
					last=i
			if first>=last: continue
			var revised:=PackedVector2Array()
			for i in range(first): revised.append(old[i])
			revised.append(entry)
			revised.append(exit)
			for i in range(last+1,old.size()): revised.append(old[i])
			route["points"]=revised
	_index_segments(routes,road_buckets,160.)

func _prepare_structures() -> void:
	structures.clear()
	for route in routes:
		if route["kind"]=="door_approach": continue
		var road_points: PackedVector2Array=route["points"]
		for river in rivers:
			var river_points: PackedVector2Array=river["points"]
			for i in range(road_points.size()-1):
				for j in range(river_points.size()-1):
					var crossed: Variant=Geometry2D.segment_intersects_segment(road_points[i],road_points[i+1],river_points[j],river_points[j+1])
					if crossed==null: continue
					var center: Vector2=crossed
					var duplicate := false
					for old in structures:
						if Vector2(old["center"]).distance_to(center)<260.: duplicate=true
					if duplicate: continue
					var axis: Vector2=(road_points[i+1]-road_points[i]).normalized()
					var lateral:=Vector2(-axis.y,axis.x)
					var half_width: float=maxf(48.,float(route["half_width_px"]))
					var half_length: float=river["half_width_px"]+64.
					for step in range(180):
						var dry := true
						for direction in [-1.,1.]:
							for edge in [-half_width,0.,half_width]:
								if bank(center+axis*half_length*direction+lateral*edge)<SHORE_MARGIN_PX+12.: dry=false
						if dry: break
						half_length+=8.
					var polygon:=PackedVector2Array([center-axis*half_length-lateral*half_width,center+axis*half_length-lateral*half_width,center+axis*half_length+lateral*half_width,center-axis*half_length+lateral*half_width])
					structures.append({"id":"bridge_%02d"%structures.size(),"kind":"native_timber_bridge","center":center,"source_deck_polygon":polygon,"source_passage_px":PackedVector2Array([center-axis*(half_length+96.),center+axis*(half_length+96.)]),"deck_height_m":0.,"half_width_px":half_width,"half_length_px":half_length,"axis":axis,"river_id":river["id"],"route_id":route["id"],"geometry_status":"AUTHORED_NATIVE_PLANE_AND_SEPARATE_RAILS_PENDING_CAPTURE","provenance":"project-original native timber geometry, registered wood/stone appearance; NOT copied bridge alpha"})

func supported_height(p: Vector2) -> float:
	for structure in structures:
		if Geometry2D.is_point_in_polygon(p,structure["source_deck_polygon"]): return 0.
	return triangle_height(p)

func supported_walk(p: Vector2) -> bool:
	for structure in structures:
		if Geometry2D.is_point_in_polygon(p,structure["source_deck_polygon"]): return true
	return selector_cell_info(p)["walk"]

static func foot_offsets() -> PackedVector2Array:
	var result := PackedVector2Array([Vector2.ZERO])
	for i in range(16):
		var angle: float=TAU*float(i)/16.
		result.append(Vector2(cos(angle),sin(angle))*FOOT_RADIUS)
	return result

func _index_segments(paths: Array[Dictionary],buckets: Dictionary,padding: float) -> void:
	buckets.clear()
	for path in paths:
		var points: PackedVector2Array=path["points"]
		for i in range(points.size()-1):
			var rect:=Rect2(points[i],Vector2.ZERO).expand(points[i+1]).grow(padding)
			var start:=Vector2i((rect.position/BUCKET).floor())
			var end:=Vector2i((rect.end/BUCKET).floor())
			var entry: Dictionary={"a":points[i],"b":points[i+1],"width":path["half_width_px"]}
			for y in range(start.y,end.y+1):
				for x in range(start.x,end.x+1):
					var key:=Vector2i(x,y)
					if not buckets.has(key): buckets[key]=[]
					buckets[key].append(entry)

func _smooth(raw: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(raw.size()-1):
		var a: Vector2 = raw[maxi(0,i-1)]
		var b: Vector2 = raw[i]
		var c: Vector2 = raw[i+1]
		var d: Vector2 = raw[mini(raw.size()-1,i+2)]
		var count: int = maxi(1,ceili(b.distance_to(c)/32.))
		for n in range(count):
			var t: float = float(n)/count
			result.append(.5*((2.*b)+(-a+c)*t+(2.*a-5.*b+4.*c-d)*t*t+(-a+3.*b-3.*c+d)*t*t*t))
	result.append(raw[-1])
	return result

static func distance_segment(p: Vector2,a: Vector2,b: Vector2) -> float:
	var delta := b-a
	return p.distance_to(a+delta*clampf((p-a).dot(delta)/maxf(delta.length_squared(),.000001),0.,1.))

func distance_path(p: Vector2,points: PackedVector2Array) -> float:
	var value := INF
	for i in range(points.size()-1): value=minf(value,distance_segment(p,points[i],points[i+1]))
	return value

func river_bank(p: Vector2) -> float:
	var value := INF
	for entry in river_buckets.get(Vector2i((p/BUCKET).floor()),[]):
		value=minf(value,distance_segment(p,entry["a"],entry["b"])-float(entry["width"]))
	return value

func sea_bank(p: Vector2) -> float:
	var coast := 12140.-120.*sin(p.y/1100.)-55.*sin(p.y/370.)
	return coast-p.x

func bank(p: Vector2) -> float:
	return minf(river_bank(p),sea_bank(p))

func road_distance(p: Vector2) -> Vector2:
	var best := INF
	var width := 48.
	for route in road_buckets.get(Vector2i((p/BUCKET).floor()),[]):
		var distance: float = distance_segment(p,route["a"],route["b"])
		if distance < best:
			best=distance
			width=route["width"]
	return Vector2(best,width)

func road_grade(p: Vector2) -> Dictionary:
	var distance := INF
	var closest := p
	var width := 48.
	for segment in road_buckets.get(Vector2i((p/BUCKET).floor()),[]):
		var a: Vector2=segment["a"]
		var delta: Vector2=Vector2(segment["b"])-a
		var point: Vector2=a+delta*clampf((p-a).dot(delta)/maxf(delta.length_squared(),.000001),0.,1.)
		var candidate: float=p.distance_to(point)
		if candidate<distance:
			distance=candidate
			closest=point
			width=segment["width"]
	return {"distance":distance,"width":width,"center":closest,"height":base_ground(closest)}

func habitat(p: Vector2) -> Vector4:
	var weights := Vector4.ZERO
	for region in HABITATS:
		var radius: Vector2=region["radius"]
		var q: Vector2=(p-Vector2(region["center"]))/radius
		var strength: float=1.-smoothstep(.45,1.15,q.length())
		# Regional forest potential is not a license to paint gravel forest-floor
		# across treeless land. Actual independent stands provide its local core.
		weights.x=maxf(weights.x,strength*float(region["forest"])*.12)
		weights.y=maxf(weights.y,strength*float(region["rock"]))
		weights.z=maxf(weights.z,strength*float(region["wet"]))
		weights.w=maxf(weights.w,strength*float(region["snow"]))
	for stand in BAMBOO_STANDS:
		var canopy: float=1.-smoothstep(70.,210.,p.distance_to(stand))
		weights.x=maxf(weights.x,canopy*.70)
	# Loose exposed rock is restricted to shoulders / real steep terrain;
	# geological region membership alone must not turn every flat into gravel.
	weights.y*=smoothstep(.18,1.25,base_ground(p))
	return weights

func base_ground(p: Vector2) -> float:
	# Broad uneven northern mass, branches and eroded valleys, not equal cones.
	var north := maxf(0.,1.-p.y/1750.)
	var folds := .6+.20*sin(p.x/780.+.9*sin(p.x/1930.))+.12*cos(p.x/310.+p.y/270.)
	var h: float=.04+4.6*pow(north,1.65)*folds
	var west := exp(-pow((p.x-850.)/980.,2.)-pow((p.y-2250.)/2200.,2.))
	h += 1.9*west*(.6+.25*sin(p.y/280.)+.15*cos(p.x/190.))
	var east := exp(-pow((p.x-10800.)/1600.,2.)-pow((p.y-5300.)/1900.,2.))
	h += .58*east*(.7+.22*sin(p.y/350.+p.x/510.))
	h += .06*sin(p.x/480.)*sin(p.y/370.)
	return h

func authored_height(p: Vector2) -> float:
	var shore: float=bank(p)
	if shore < 0.: return WATER_Y-0.035-1.4*smoothstep(0.,220.,-shore)
	var h: float=base_ground(p)
	var road: Dictionary=road_grade(p)
	var strength: float=1.-smoothstep(float(road["width"])*.7,float(road["width"])+85.,float(road["distance"]))
	# Local cross-road grading follows natural longitudinal elevation; never
	# excavates a world-wide fixed-height trench.
	h=lerpf(h,float(road["height"]),strength*strength)
	for landmark in LANDMARKS:
		var foot: Vector2=landmark["foot"]
		var center: Vector2=foot+Vector2(0,-160)
		var delta: Vector2=p-center
		var q: Vector2=delta/Vector2(float(landmark["width"])*.58,310.)
		var pad: float=1.-smoothstep(.35,1.5,q.length())
		# Gentle natural plane at the doorway's actual local grade. Wide, smooth
		# shoulder and reduced rather than erased regional slope prevent moats.
		var local_grade: float=base_ground(foot)
		var natural_slope: float=(base_ground(p)-local_grade)*.22
		h=lerpf(h,local_grade+natural_slope,pad)
	# A bridge's land tie-in reaches deckY0 only on dry banks. Never flatten
	# the negative river bed or modify structure support semantics.
	for structure in structures:
		var axis: Vector2=structure["axis"]
		var delta: Vector2=p-Vector2(structure["center"])
		var along: float=absf(delta.dot(axis))-float(structure["half_length_px"])
		var across: float=absf(delta.dot(Vector2(-axis.y,axis.x)))
		if along<160. and across<float(structure["half_width_px"])+60.:
			var tie: float=(1.-smoothstep(0.,160.,maxf(0.,along)))*(1.-smoothstep(float(structure["half_width_px"]),float(structure["half_width_px"])+60.,across))
			h=lerpf(h,0.,tie)
	# Actual shoreline is the same continuous Float32 mesh for water/land/nav.
	h=lerpf(WATER_Y,h,smoothstep(0.,40.,shore))
	return h

func generate_height_grid() -> void:
	heights.resize(GRID_SIZE.x*GRID_SIZE.y)
	for y in range(GRID_SIZE.y):
		for x in range(GRID_SIZE.x): heights[y*GRID_SIZE.x+x]=authored_height(Vector2(x*GRID_STEP,y*GRID_STEP))

func vertex_height(cell: Vector2i) -> float:
	cell=cell.clamp(Vector2i.ZERO,GRID_SIZE-Vector2i.ONE)
	if not heights.is_empty(): return heights[cell.y*GRID_SIZE.x+cell.x]
	if not vertex_cache.has(cell):
		# Quantize once to the exact Float32 RF representation even in lazy CPU
		# plan / bounded preview. Not a different high-precision height oracle.
		var value:=PackedFloat32Array([authored_height(Vector2(cell*GRID_STEP))])
		vertex_cache[cell]=value[0]
	return vertex_cache[cell]

func triangle_height(p: Vector2) -> float:
	var q: Vector2=p.clamp(Vector2.ZERO,Vector2(SIZE))/float(GRID_STEP)
	var cell := Vector2i(mini(floori(q.x),GRID_SIZE.x-2),mini(floori(q.y),GRID_SIZE.y-2))
	var f: Vector2=q-Vector2(cell)
	var a: float=vertex_height(cell)
	var b: float=vertex_height(cell+Vector2i(1,0))
	var c: float=vertex_height(cell+Vector2i(0,1))
	var d: float=vertex_height(cell+Vector2i(1,1))
	return a+(b-a)*f.x+(c-a)*f.y if f.x+f.y <= 1. else d+(c-d)*(1.-f.x)+(b-d)*(1.-f.y)

func triangle_gradient(cell: Vector2i,upper: bool) -> float:
	var a: float=vertex_height(cell)
	var b: float=vertex_height(cell+Vector2i(1,0))
	var c: float=vertex_height(cell+Vector2i(0,1))
	var d: float=vertex_height(cell+Vector2i(1,1))
	var dx: float=(d-c if upper else b-a)*PPM/GRID_STEP
	var dz: float=(d-b if upper else c-a)*Z_PPM/GRID_STEP
	return Vector2(dx,dz).length()

func selector_cell_info(p: Vector2) -> Dictionary:
	var origin: Vector2=(p/float(SELECTOR_STEP)).floor()*SELECTOR_STEP
	origin=origin.clamp(Vector2.ZERO,Vector2(SIZE-Vector2i(SELECTOR_STEP,SELECTOR_STEP)))
	var cell := Vector2i(origin/float(GRID_STEP))
	var f: Vector2=(origin-Vector2(cell*GRID_STEP))/float(GRID_STEP)
	var min_sum: float=f.x+f.y
	var max_sum: float=min_sum+2.*SELECTOR_STEP/GRID_STEP
	var gradient := 0.
	if min_sum <= 1.: gradient=maxf(gradient,triangle_gradient(cell,false))
	if max_sum >= 1.: gradient=maxf(gradient,triangle_gradient(cell,true))
	var low := INF
	var coast := INF
	for offset in [Vector2.ZERO,Vector2(2,0),Vector2(0,2),Vector2(2,2),Vector2(1,1)]:
		low=minf(low,triangle_height(origin+offset))
		coast=minf(coast,bank(origin+offset))
	return {"origin":origin,"gradient":gradient,"min_height":low,"min_bank":coast,"land":low>WATER_Y,"walk":low>WATER_Y and coast>SHORE_MARGIN_PX and gradient<MAX_GRADIENT}

static func point3(p: Vector2,height: float) -> Vector3:
	return Vector3((p.x-SIZE.x*.5)/PPM,height,(p.y-SIZE.y*.5)/Z_PPM)

func project_source(p: Vector2) -> Vector2:
	return Vector2(p.x,p.y-triangle_height(p)*Z_PPM)

static func chunks() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for row in range(8):
		for column in range(8):
			var id: String="r%d_c%d"%[row,column]
			result.append({"id":id,"row":row,"col":column,"logical_rect_px":[column*TILE.x,row*TILE.y,TILE.x,TILE.y],"visual_path":OUT+"chunks/"+id+"_visual.png","land_path":OUT+"chunks/"+id+"_land.png","raw_walk_path":OUT+"chunks/"+id+"_raw_walk.png","walk_path":OUT+"chunks/"+id+"_walk.png"})
	return result

func core_spacing() -> Dictionary:
	var minimum := INF
	var pair: Array[String]=[]
	for i in range(LANDMARKS.size()):
		if not LANDMARKS[i]["id"] in CORE_IDS: continue
		for j in range(i+1,LANDMARKS.size()):
			if not LANDMARKS[j]["id"] in CORE_IDS: continue
			var a: Vector2=project_source(LANDMARKS[i]["foot"])
			var b: Vector2=project_source(LANDMARKS[j]["foot"])
			var distance: float=a.distance_to(b)
			if distance < minimum:
				minimum=distance
				pair.assign([String(LANDMARKS[i]["id"]),String(LANDMARKS[j]["id"])])
	return {"minimum_px":minimum,"pair":pair,"minimum_required_px":MIN_CORE_SPACING,"measurement_space":"actual piecewise affine source-height projected doorway anchors; compound centers separately require actual measured source UV","camera_zoom":1.25,"logical_screen_width_px":1536,"passed":minimum>=MIN_CORE_SPACING}

func load_landmark_semantics() -> bool:
	semantics.clear()
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(SEMANTICS_PATH))
	if not parsed is Dictionary or int(parsed.get("schema_version",0)) != SCHEMA:
		last_error="Measured v15 landmark_semantics.json is not available; no guessed doorway anchors."
		return false
	for landmark in LANDMARKS:
		var id: String=landmark["id"]
		var record: Variant=parsed.get("landmarks",{}).get(id)
		if not record is Dictionary or record.get("status","") != "MEASURED_ACTUAL_SOURCE" or record.get("source","") != landmark["source"]:
			last_error="Missing actual source doorway/solid-ground contract: "+id
			return false
		if FileAccess.get_sha256(landmark["source"]) != record.get("source_sha256","") or record.get("source_doorstep_uv",[]).size()!=2 or record.get("solid_polygons_uv",[]).is_empty() or record.get("passage_polygon_uv",[]).size()<3:
			last_error="Doorway source bytes or measured footprint incomplete: "+id
			return false
		semantics[id]=record
	return true

func source_contract_plan() -> Dictionary:
	var portals: Array[Dictionary]=[]
	for entry in LANDMARKS:
		var foot: Vector2=entry["foot"]
		portals.append({"id":entry["id"],"compound_id":"compound_"+String(entry["id"]),"target_scene":entry["target"],"target_pos":[entry["target_pos"].x,entry["target_pos"].y],"planned_source_XZ_foot_px":[foot.x,foot.y],"source_doorstep_uv":null,"door_foot_px":null,"status":"PENDING_ACTUAL_SOURCE_MEASUREMENT"})
	return {"schema_version":SCHEMA,"version":"world_v15","status":"AUTHORING_PLAN_NOT_PUBLISHABLE","world_size":[SIZE.x,SIZE.y],"tile_size":[TILE.x,TILE.y],"chunks":chunks(),"portals":portals,"core_spacing":core_spacing(),"geometry":{"grid_step_px":GRID_STEP,"grid_size":[GRID_SIZE.x,GRID_SIZE.y],"height_format":"Float32 RF","height_interpolation":"exact native [a,b,c,b,d,c] piecewise affine","selector_cell":"entire 2px cell enumerates all intersected native8px triangles; bank28px and exact gradients"},"capture":{"mode":"same global source, local translated orthographic camera, chunk SSAA2 with overscan","whole_ssaa_viewport":false,"authoritative_nav_msaa":0,"authoritative_nav_resize":false},"provenance":{"terrain":"registered official CC0 Poly Haven tileable PBR and native geometry","existing_landmarks":"existing project-generated original alpha; legacy baked light disclosed","four_sect_compounds":"new Codex builtin imagegen originals, NOT CC0","fictional_geography":["gufeng","lingyue","mingwu"]}}
