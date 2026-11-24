extends RefCounted

# New local scenes, not copies or recolours of an existing story background.
const SIZE := Vector2i(1536,1024)
const STEP := 8
const PPM := 102.4
const Z_PPM := 72.40773439
const WATER_Y := -.025
const MATERIAL_ORIGIN := Vector2(5376,3584)
const IDS := {"bamboo":"openworld_v15_bamboo_outskirts","forest":"openworld_v15_forest_outskirts","marsh":"openworld_v15_marsh_outskirts"}
var kind := "bamboo"
var cache: Dictionary={}
var route := PackedVector2Array([Vector2(768,920),Vector2(768,780),Vector2(540,690),Vector2(490,460),Vector2(680,330),Vector2(900,440),Vector2(960,650),Vector2(768,780)])
var props: Array[Dictionary]=[]
var branch := PackedVector2Array()

func prepare(value: String) -> void:
	kind=value
	cache.clear()
	props.clear()
	if kind=="bamboo":
		route=PackedVector2Array([Vector2(768,920),Vector2(710,790),Vector2(505,655),Vector2(465,440),Vector2(640,325),Vector2(895,405),Vector2(960,630),Vector2(710,790)])
		branch=PackedVector2Array([Vector2(895,405),Vector2(900,300),Vector2(920,190)])
	elif kind=="forest":
		route=PackedVector2Array([Vector2(768,920),Vector2(785,800),Vector2(1070,610),Vector2(1030,395),Vector2(820,300),Vector2(595,425),Vector2(510,610),Vector2(615,765),Vector2(785,800)])
		branch=PackedVector2Array([Vector2(595,425),Vector2(480,340),Vector2(420,250)])
	else:
		route=PackedVector2Array([Vector2(768,920),Vector2(825,805),Vector2(1005,680),Vector2(990,560),Vector2(875,390),Vector2(745,250),Vector2(610,345),Vector2(640,570),Vector2(675,730),Vector2(825,805)])
		branch=PackedVector2Array([Vector2(1005,680),Vector2(1190,715),Vector2(1280,790)])
	var centers: Array[Vector2]=[]
	if kind=="forest": centers.assign([Vector2(260,380),Vector2(790,540),Vector2(1210,700)])
	elif kind=="bamboo": centers.assign([Vector2(250,380),Vector2(1120,795),Vector2(800,340)])
	else: centers.assign([Vector2(505,420),Vector2(1010,470),Vector2(315,670)])
	var number: int=7 if kind=="forest" else 14
	for group in range(centers.size()):
		for i in range(number):
			var p: Vector2=centers[group]+Vector2(sin(i*2.399963)*sqrt(i+1)*42.,cos(i*2.399963)*sqrt(i+1)*31.)
			if not Rect2(50,65,1436,850).has_point(p) or road_distance(p)<90.: continue
			if kind!="marsh" and bank(p)<46.: continue
			if kind=="marsh" and (bank(p)<3. or bank(p)>72.): continue
			props.append({"id":"%s_%02d_%02d"%[kind,group,i],"prototype":kind,"source_foot":p,"yaw":25.+float(i%3)*65.,"blocking":kind!="marsh","collision_size_px":Vector2(24,18) if kind=="forest" else Vector2(20,16),"nature":"licensed native broadleaf tree" if kind=="forest" else "CC0 Yughues original native OBJ bamboo" if kind=="bamboo" else "CC0 Shrub03 low ground plant; nonblocking dry mud-bank vegetation, NOT reeds"})
	props.append({"id":"return_waymarker","prototype":"waymarker","source_foot":Vector2(720,890),"yaw":0.,"blocking":true,"collision_size_px":Vector2(12,10),"nature":"project-original native timber waymarker"})
	props.append({"id":"discovery_cache","prototype":"discovery","source_foot":branch[-1]+Vector2(36,-18),"yaw":0.,"blocking":false,"collision_size_px":Vector2.ZERO,"nature":"project-original native small material cache, independent nonblocking pickup"})

static func feet() -> PackedVector2Array:
	var result:=PackedVector2Array([Vector2.ZERO])
	for i in range(16): result.append(Vector2(cos(TAU*i/16.),sin(TAU*i/16.))*Vector2(10,6))
	return result

static func point3(p: Vector2,h: float) -> Vector3:
	return Vector3((p.x-768.)/PPM,h,(p.y-512.)/Z_PPM)

func bank(p: Vector2) -> float:
	if kind=="forest":
		return p.distance_to(Vector2(1420,325))-170.
	if kind=="bamboo":
		var q: Vector2=(p-Vector2(1220,315))/Vector2(235,155)
		return (q.length()-1.)*155.+9.*sin(p.x/73.)*sin(p.y/91.)
	var left: Vector2=(p-Vector2(285,430))/Vector2(270,220)
	var right: Vector2=(p-Vector2(1245,365))/Vector2(280,235)
	return minf((left.length()-1.)*220.,(right.length()-1.)*235.)+10.*sin(p.x/89.)*sin(p.y/76.)

func road_distance(p: Vector2) -> float:
	var best:=INF
	for path: PackedVector2Array in [route,branch]:
		for i in range(path.size()-1):
			var d: Vector2=path[i+1]-path[i]
			best=minf(best,p.distance_to(path[i]+d*clampf((p-path[i]).dot(d)/d.length_squared(),0.,1.)))
	return best

func authored_height(p: Vector2) -> float:
	var shore: float=bank(p)
	if shore<0.: return WATER_Y-.55*smoothstep(0.,155.,-shore)
	var high: float=.055
	if kind=="forest": high+=.48*exp(-pow((p.x-270.)/460.,2.)-pow((p.y-120.)/340.,2.))
	elif kind=="bamboo": high+=.32*exp(-pow((p.x-330.)/570.,2.)-pow((p.y-150.)/370.,2.))
	else: high+=.03*sin(p.x/185.)*sin(p.y/160.)
	# This low loop is an authored clearing, not an absolute-height ditch in a hill.
	high=lerpf(high,.065,1.-smoothstep(50.,145.,road_distance(p)))
	return lerpf(WATER_Y,high,smoothstep(0.,42.,shore))

func vertex(g: Vector2i) -> float:
	if not cache.has(g):
		var packed:=PackedFloat32Array([authored_height(Vector2(g*STEP))])
		cache[g]=float(packed[0])
	return cache[g]

func height(p: Vector2) -> float:
	var g:=Vector2i((p/STEP).floor())
	var f: Vector2=p/STEP-Vector2(g)
	var a: float=vertex(g)
	var b: float=vertex(g+Vector2i(1,0))
	var c: float=vertex(g+Vector2i(0,1))
	var d: float=vertex(g+Vector2i.ONE)
	return a+(b-a)*f.x+(c-a)*f.y if f.x+f.y<=1. else d+(c-d)*(1.-f.x)+(b-d)*(1.-f.y)

func gradient(g: Vector2i,upper: bool) -> float:
	var a: float=vertex(g)
	var b: float=vertex(g+Vector2i(1,0))
	var c: float=vertex(g+Vector2i(0,1))
	var d: float=vertex(g+Vector2i.ONE)
	return Vector2((d-c if upper else b-a)*PPM/STEP,(d-b if upper else c-a)*Z_PPM/STEP).length()

func selector(p: Vector2) -> Dictionary:
	var origin: Vector2=(p/2.).floor()*2.
	var g:=Vector2i((origin/STEP).floor())
	var fraction: Vector2=origin/STEP-Vector2(g)
	var max_gradient:=0.
	if fraction.x+fraction.y<=1.: max_gradient=maxf(max_gradient,gradient(g,false))
	if fraction.x+fraction.y+4./STEP>=1.: max_gradient=maxf(max_gradient,gradient(g,true))
	var min_height:=INF
	var min_bank:=INF
	for q: Vector2 in [origin,origin+Vector2(2,0),origin+Vector2(0,2),origin+Vector2(2,2),origin+Vector2.ONE]:
		min_height=minf(min_height,height(q))
		min_bank=minf(min_bank,bank(q))
	return {"land":min_height>WATER_Y,"walk":min_height>WATER_Y and min_bank>28. and max_gradient<.72,"max_triangle_gradient":max_gradient,"min_bed_m":min_height,"min_bank_px":min_bank}

func ecology(p: Vector2) -> Vector4:
	var forest:=0.
	for prop in props:
		if prop["prototype"] in ["forest","bamboo"]:
			var radius: float=145. if kind=="forest" else 105.
			forest=maxf(forest,1.-smoothstep(radius*.4,radius,Vector2(prop["source_foot"]).distance_to(p)))
	var wet: float=1.-smoothstep(5.,105.,bank(p))
	var rock: float=.25*(1.-smoothstep(.12,.38,height(p))) if kind=="bamboo" else 0.
	return Vector4(forest*.85,rock,wet,0)

func projected(p: Vector2) -> Vector2:
	return Vector2(p.x,p.y-height(p)*Z_PPM)

func source_from_screen(p: Vector2) -> Vector2:
	var q:=p
	for i in range(12): q.y=p.y+height(q)*Z_PPM
	return q

func safe_screen(p: Vector2,include_props: bool=true) -> bool:
	for offset in feet():
		var q: Vector2=source_from_screen(p+offset)
		if not selector(q)["walk"]: return false
		if include_props:
			for prop in props:
				if prop["blocking"] and Rect2(projected(prop["source_foot"])+Vector2(prop.get("physical_offset_px",Vector2.ZERO))-Vector2(prop["collision_size_px"])*.5,prop["collision_size_px"]).has_point(p+offset): return false
	return true

func forecast() -> Dictionary:
	var failures: Array[Dictionary]=[]
	var centers:=0
	for path: PackedVector2Array in [route,branch]:
		for i in range(path.size()-1):
			var a: Vector2=projected(path[i])
			var b: Vector2=projected(path[i+1])
			var steps: int=ceili(a.distance_to(b)/4.)
			for n in range(steps+1):
				var p: Vector2=a.lerp(b,float(n)/steps)
				centers+=1
				if not safe_screen(p): failures.append({"screen_center":[p.x,p.y],"segment":i})
	var return_foot: Vector2=projected(route[0])
	return {"passed":failures.is_empty() and safe_screen(return_foot),"route_centers":centers,"failures":failures,"return_foot_px":[return_foot.x,return_foot.y],"prop_count":props.size(),"interpolation":"Float32 lattice8px, [a,b,c,b,d,c] affine triangles; selector conservatively includes every intersected native triangle in each2px cell"}
