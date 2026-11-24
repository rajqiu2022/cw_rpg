extends RefCounted

# Independent human-scale city authoring. No formal scene, world or save writes.
const SIZE := Vector2i(3072,2048)
const PPM := 64.0
const ZPPM := 32.0 # 48x64 metres, actual 30-degree elevated orthographic camera
const OUT := "res://art/maps/luoyang_modular_v2/"
const RAW := OUT+"source/"
const LEGACY_RAW := "res://art/maps/luoyang_modular_v1/source/"
const GENERATION := "res://../assets/raw/scene_module/luoyang_modular_v2/generation_record.json"
const TREE_RAW := "res://art/external/polyhaven/tree_small_02/tree_small_02_1k.gltf"
const TREE_MESH := "res://art/maps/world_map_v14/entities/tree_small02_native_hybrid.res"
const FILE_SHA := {"south_gate_v1.png":"368cae36b04f983f537f813173a65737a2ac61f2a5be8ded50ef9fb10f709343","inn_v1.png":"661bd90ebc9bf75ebb67064e80633afd3ab7f371184e514574d667e59e2540b9","shop_v1.png":"02d474a76c6deaf995eff97be9cb343bf1b0f6ae26a42a72e716308f38d23883","notice_pavilion_v2.png":"523ca1084365d836ab6b687804b6a25020b464f897a764d7c7d9c6632a883ccb","street_lamp_v2.png":"8efad8443a667ca9d382ca96b0ef4ceea543a095b838259aaab8c01ebeb63043","goods_stall_v2.png":"85cfbe6b14d6aef518d33acb3c3034e07a7b26e0d3e57dc3e9c1047452d416d0","worn_bluestone_v2.png":"7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d"}
var objects: Array[Dictionary]=[]
var routes: Array[Dictionary]=[]
var anchors: Array[Dictionary]=[]

func prepare() -> void:
	objects.clear()
	# Source pixels are measured against the NEW full-size interior architecture,
	# never against a miniature world-map compound or alpha-derived shadow bounds.
	_building("south_gate",.47,Vector2(768,945),Vector2(1536,1660),[
		PackedVector2Array([Vector2(28,760),Vector2(659,760),Vector2(659,952),Vector2(28,952)]),
		PackedVector2Array([Vector2(881,760),Vector2(1508,760),Vector2(1508,952),Vector2(881,952)])],
		{"door_top_source_px":[768,610],"door_foot_source_px":[768,945],"transparent_hole_witnesses_source_px":[[768,620],[768,700],[768,800],[768,850]],"solid_witnesses_source_px":[[600,880],[920,880]],"passage_source_rect_px":[680,665,170,190],"measured_door_height_px":157.45})
	_building("inn",.62,Vector2(768,963),Vector2(940,1020),[
		PackedVector2Array([Vector2(140,685),Vector2(1390,685),Vector2(1390,923),Vector2(140,923)])],
		{"door_top_source_px":[768,690],"door_foot_source_px":[768,963],"solid_witnesses_source_px":[[400,860],[1120,860]],"measured_door_height_px":169.26})
	_building("shop",.5,Vector2(1000,942),Vector2(2200,1040),[
		PackedVector2Array([Vector2(190,670),Vector2(1310,670),Vector2(1310,902),Vector2(190,902)])],
		{"door_top_source_px":[1000,630],"door_foot_source_px":[1000,942],"solid_witnesses_source_px":[[600,790],[1210,790]],"measured_door_height_px":156.0})
	_generated_prop("notice_pavilion","notice_pavilion_v2.png",Vector2(1536,1024),.18,Vector2(768,963),Vector2(2140,1320),[
		PackedVector2Array([Vector2(300,820),Vector2(1255,820),Vector2(1255,963),Vector2(300,963)])],
		{"solid_witnesses_source_px":[[350,920],[1160,920]],"source_ground_kind":"two stone footings and low board footprint; insufficient adult headroom below board","weak_contact_tail_excluded_from_solids":true})
	for entry in [{"id":"lamp_west","foot":Vector2(1330,1380)},{"id":"lamp_east","foot":Vector2(1742,1380)}]:
		_generated_prop(entry["id"],"street_lamp_v2.png",Vector2(1024,1536),.135,Vector2(425,1480),entry["foot"],[
			PackedVector2Array([Vector2(320,1350),Vector2(526,1350),Vector2(526,1480),Vector2(320,1480)])],
			{"solid_witnesses_source_px":[[400,1420]],"source_ground_kind":"actual stone lamp plinth, NOT hanging lantern or external shadow","weak_contact_tail_excluded_from_solids":true})
	_generated_prop("goods_stall","goods_stall_v2.png",Vector2(1536,1024),.215,Vector2(768,960),Vector2(550,1210),[
		PackedVector2Array([Vector2(95,780),Vector2(1440,780),Vector2(1440,960),Vector2(95,960)])],
		{"solid_witnesses_source_px":[[150,925],[1350,925],[660,820]],"source_ground_kind":"counter, storage and complete four-foot stall ground envelope; not an open doorway","weak_contact_tail_excluded_from_solids":true})
	for i in range(4):
		_native("street_tree_%d"%i,"tree",[Vector2(620,1380),Vector2(2520,1360),Vector2(640,560),Vector2(2500,550)][i],Vector2(24,18))
	routes=[
		{"id":"gate_to_market","points_px":[[1536,1860],[1536,1660],[1536,1440],[1536,1120],[1536,720],[1536,540]]},
		{"id":"market_public_loop","points_px":[[1536,1120],[1160,1120],[760,1120],[760,1260],[980,1480],[1536,1480],[2260,1480],[2420,1240],[2420,1120],[2200,1120],[1536,1120]]},
		{"id":"inn_door_approach","points_px":[[1160,1120],[940,1120],[940,1020]]},
		{"id":"shop_door_approach","points_px":[[2200,1120],[2200,1040]]},
		{"id":"bounty_pavilion_approach","points_px":[[2260,1480],[2180,1420],[2140,1380]]}]
	anchors=[
		{"id":"entry","point_px":[1536,1860],"source_action":"scene:luoyang_south_gate","action_mode":"DRY_RUN_ONLY"},
		{"id":"south_market","point_px":[1536,540],"source_action":"scene:luoyang_south_market","action_mode":"DRY_RUN_ONLY"},
		{"id":"inn","point_px":[940,1020],"source_action":"UNCHANGED_EXISTING_INN_ACTION_PENDING_SYSTEM_BINDING","action_mode":"DRY_RUN_ONLY"},
		{"id":"shop","point_px":[2200,1040],"source_action":"UNCHANGED_EXISTING_SHOP_ACTION_PENDING_SYSTEM_BINDING","action_mode":"DRY_RUN_ONLY"},
		{"id":"bounty_board","point_px":[2140,1380],"source_action":"UNCHANGED_LUOYANG_BOUNTY_BOARD_ACTION_PENDING_SYSTEM_BINDING","action_mode":"DRY_RUN_ONLY"}]

func _building(id: String,scale: float,foot: Vector2,world_foot: Vector2,source_polys: Array,semantics: Dictionary) -> void:
	var size := Vector2(1536,1024)*scale
	var origin: Vector2=world_foot-foot*scale
	var solids: Array=[]
	for polygon: PackedVector2Array in source_polys:
		var projected: Array=[]
		for p in polygon: projected.append([origin.x+p.x*scale,origin.y+p.y*scale])
		solids.append(projected)
	objects.append({"id":id,"texture":RAW+id+"_v1.png","source":RAW+id+"_v1.png","original_source":LEGACY_RAW+id+"_v1.png","original_source_sha256":FileAccess.get_sha256(LEGACY_RAW+id+"_v1.png"),"source_sha256":FileAccess.get_sha256(RAW+id+"_v1.png"),"source_size_px":[1536,1024],"render_size_px":[size.x,size.y],"foot_uv":[foot.x/1536.,foot.y/1024.],"world_foot_px":[world_foot.x,world_foot.y],"depth_foot_y":world_foot.y,"solid_polygons_px":solids,"collision_size_px":[0,0],"physical_center_px":[world_foot.x,world_foot.y],"blocking":true,"nature":"generated_independent_architecture","prototype":"","source_semantics":semantics,"occlusion_source":"original unmodified RGBA; semantic solids are NOT an alpha/shadow threshold","source_attribution":"Codex built-in imagegen; NOT CC0; v1 original architecture byte-exactly copied, not newly generated","doorstep_visual_review_status":"PENDING_FIELD_REVIEW"})

func _generated_prop(id: String,filename: String,source_size: Vector2,scale: float,foot: Vector2,world_foot: Vector2,source_polys: Array,semantics: Dictionary) -> void:
	var origin: Vector2=world_foot-foot*scale
	var solids: Array=[]
	for polygon: PackedVector2Array in source_polys:
		var projected: Array=[]
		for p in polygon: projected.append([origin.x+p.x*scale,origin.y+p.y*scale])
		solids.append(projected)
	objects.append({"id":id,"texture":RAW+filename,"source":RAW+filename,"source_sha256":FileAccess.get_sha256(RAW+filename),"source_size_px":[source_size.x,source_size.y],"render_size_px":[source_size.x*scale,source_size.y*scale],"foot_uv":[foot.x/source_size.x,foot.y/source_size.y],"world_foot_px":[world_foot.x,world_foot.y],"depth_foot_y":world_foot.y,"solid_polygons_px":solids,"collision_size_px":[0,0],"physical_center_px":[world_foot.x,world_foot.y],"blocking":true,"nature":"generated_independent_city_prop","prototype":"","source_semantics":semantics,"source_attribution":"Codex builtin-imagegen original; NOT CC0; source bytes preserved without alpha thresholding","occlusion_source":"original true RGBA; external weak-alpha tails are not ground blockers","doorstep_visual_review_status":"NOT_A_PORTAL"})

func _native(id: String,kind: String,foot: Vector2,physical: Vector2) -> void:
	objects.append({"id":id,"prototype":kind,"world_foot_px":[foot.x,foot.y],"depth_foot_y":foot.y,"collision_size_px":[physical.x,physical.y],"physical_center_px":[foot.x,foot.y-physical.y*.5],"solid_polygons_px":[],"blocking":true,"nature":"licensed_native_tree" if kind=="tree" else "project_original_native_city_prop"})

static func point3(p: Vector2,height: float=0.) -> Vector3:
	return Vector3((p.x-1536)/PPM,height,(p.y-1024)/ZPPM)

static func feet() -> Array[Vector2]:
	var result: Array[Vector2]=[Vector2.ZERO]
	for i in range(16): result.append(Vector2(cos(TAU*i/16.)*10.,sin(TAU*i/16.)*6.))
	return result

func point_clear(p: Vector2,round_pixel: bool=true) -> bool:
	if round_pixel: p=p.round()
	if p.x<24 or p.y<24 or p.x>=SIZE.x-24 or p.y>=SIZE.y-24: return false
	for object in objects:
		for polygon in object["solid_polygons_px"]:
			var values:=PackedVector2Array()
			for q in polygon: values.append(Vector2(q[0],q[1]))
			if Geometry2D.is_point_in_polygon(p,values): return false
		var size:=Vector2(object["collision_size_px"][0],object["collision_size_px"][1])
		if size.x>0:
			var center:=Vector2(object["physical_center_px"][0],object["physical_center_px"][1])
			if Rect2(center-size*.5,size).has_point(p): return false
	return true

func foot_clear(p: Vector2) -> bool:
	for offset in feet():
		if not point_clear(p+offset): return false
	return true

func physical_clear(p: Vector2) -> bool:
	# The real ordinary actor is Rectangle34x24, not a world-travel circle.
	for x in [-17.,0.,17.]:
		for y in [-12.,0.,12.]:
			if not point_clear(p+Vector2(x,y),false): return false
	return true

func forecast() -> Dictionary:
	var failures: Array=[]
	var centers:=0
	for filename: String in FILE_SHA:
		if FileAccess.get_sha256(RAW+filename)!=FILE_SHA[filename]: failures.append({"source_sha":RAW+filename})
	for route in routes:
		var points: Array=route["points_px"]
		for i in range(points.size()-1):
			var a:=Vector2(points[i][0],points[i][1])
			var b:=Vector2(points[i+1][0],points[i+1][1])
			var count:=int(ceil(a.distance_to(b)/4.))
			for j in range(count+1):
				var p: Vector2=a.lerp(b,float(j)/maxi(count,1))
				centers+=1
				if not foot_clear(p) or not physical_clear(p): failures.append({"route":route["id"],"point_px":[p.x,p.y],"full17":foot_clear(p),"rectangle34x24":physical_clear(p)})
	for anchor in anchors:
		var a:=Vector2(anchor["point_px"][0],anchor["point_px"][1])
		if not foot_clear(a) or not physical_clear(a): failures.append({"anchor":anchor["id"]})
	for station in npc_stations():
		var p:=Vector2(station["point_px"][0],station["point_px"][1])
		if not foot_clear(p) or not physical_clear(p): failures.append({"npc_station":station["id"]})
	return {"passed":failures.is_empty(),"failures":failures,"centers":centers,"objects":objects.size(),"full_foot_samples":17,"real_body_size_px":[34,24],"margin_px":0,"sampling":"round_world_pixel","ground_height_m":0.,"height_source":"genuine native flat city paving and independent low stone geometry; not image-derived fake height"}

func snapshot() -> Dictionary:
	return {"schema_version":1,"scene_id":"luoyang_layered_interior_v2","logical_size_px":[3072,2048],"objects":objects,"routes":routes,"interaction_anchors":anchors,"npc_stations":npc_stations(),"entry_foot_px":[1536,1860],"return_foot_px":[1536,1860],"pixel_sampling":"round_world_pixel","physical_navigation_margin_px":0,"ordinary_actor_visual_scale":.91,"ordinary_actor_effective_height_px":113.5134,"ordinary_actor_body_px":[34,24],"status":"SOURCE_AUTHORING_ONLY_NOT_CAPTURE_READY"}

static func npc_stations() -> Array[Dictionary]:
	return [{"id":"guard","point_px":[1700,1780]},{"id":"patrol","point_px":[1070,1170]},{"id":"armorer","point_px":[2370,1080]}]

func ground_zone(p: Vector2) -> String:
	# Authoring zones only; solids and the five mandatory walking routes do not move.
	if p.x>=1360 and p.x<=1712 and p.y>=500 and p.y<=1940: return "main_street"
	if Rect2(1140,300,800,530).has_point(p): return "public_square"
	if Rect2(495,920,900,235).has_point(p) or Rect2(1810,935,650,220).has_point(p): return "shop_apron"
	for route in routes:
		var points: Array=route["points_px"]
		for i in range(points.size()-1):
			var a:=Vector2(points[i][0],points[i][1])
			var b:=Vector2(points[i+1][0],points[i+1][1])
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))<82.: return "public_loop"
	return "outer_shoulder"

func floor_contact_strength(p: Vector2) -> float:
	# Restrained dirt/contact at actual solid front edges. Not a building cast,
	# no alpha-canvas rectangle and no duplicate native tree circle shadow.
	var result: float=0.
	for object in objects:
		if object["prototype"]!="": continue
		for polygon in object["solid_polygons_px"]:
			var left: float=INF
			var right: float=-INF
			var front: float=-INF
			for v in polygon:
				left=minf(left,v[0])
				right=maxf(right,v[0])
				front=maxf(front,v[1])
			if p.x<left or p.x>right: continue
			var fade: float=clampf(1.-absf(p.y-front)/14.,0.,1.)
			result=maxf(result,fade)
	return result
