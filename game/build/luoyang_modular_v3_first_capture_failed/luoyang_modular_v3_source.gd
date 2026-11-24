extends RefCounted

# Independent human-scale city authoring. No formal scene, world or save writes.
const SIZE := Vector2i(3072,2048)
const PPM := 64.0
const ZPPM := 32.0 # 48x64 metres, actual 30-degree elevated orthographic camera
const OUT := "res://art/maps/luoyang_modular_v3/"
const RAW := OUT+"source/"
const LEGACY_RAW := "res://art/maps/luoyang_modular_v1/source/"
const GENERATION := RAW+"generation_record.json"
const REUSED_AUTHORING := RAW+"reused_architecture_authoring.json"
const TREE_RAW := "res://art/external/polyhaven/tree_small_02/tree_small_02_1k.gltf"
const TREE_MESH := "res://art/maps/world_map_v14/entities/tree_small02_native_hybrid.res"
const FILE_SHA := {"south_gate_v1.png":"368cae36b04f983f537f813173a65737a2ac61f2a5be8ded50ef9fb10f709343","inn_v1.png":"661bd90ebc9bf75ebb67064e80633afd3ab7f371184e514574d667e59e2540b9","shop_v1.png":"02d474a76c6deaf995eff97be9cb343bf1b0f6ae26a42a72e716308f38d23883","notice_pavilion_v2.png":"523ca1084365d836ab6b687804b6a25020b464f897a764d7c7d9c6632a883ccb","street_lamp_v2.png":"8efad8443a667ca9d382ca96b0ef4ceea543a095b838259aaab8c01ebeb63043","goods_stall_v2.png":"85cfbe6b14d6aef518d33acb3c3034e07a7b26e0d3e57dc3e9c1047452d416d0","worn_bluestone_v2.png":"7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d"}
var objects: Array[Dictionary]=[]
var routes: Array[Dictionary]=[]
var anchors: Array[Dictionary]=[]

const REGIONS := ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s3_luoyang_market","ch4_s2_canal_docks"]
const MODULES := ["street_row_v3.png","courtyard_wall_gate_v3.png","yamen_hall_v3c.png","canal_warehouse_v3.png"]
var region := "ch4_s0_luoyang_gate"
var module_semantics: Dictionary={}
var reused_authoring: Dictionary={}
var preparation_error := ""
var gameplay_slots: Dictionary={}
var entry_foot := Vector2(1536,1860)
var region_out := OUT+"ch4_s0_luoyang_gate/"

func prepare(value: String="ch4_s0_luoyang_gate") -> void:
	region=value
	region_out=OUT+region+"/"
	objects.clear()
	routes.clear()
	anchors.clear()
	preparation_error=""
	entry_foot=Vector2(1536,1860)
	if not region in REGIONS:
		preparation_error="Unknown canonical city district."
		return
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(OUT+"source/module_semantics.json"))
	if not parsed is Dictionary or parsed.get("status","")!="MEASURED_ACTUAL_SOURCE":
		preparation_error="New generated module source semantics not measured; no guessed footprints or publish."
		return
	module_semantics=parsed["modules"]
	var reused: Variant=JSON.parse_string(FileAccess.get_file_as_string(REUSED_AUTHORING))
	if not reused is Dictionary or reused.get("status","")!="FROZEN_AUTHORING_GEOMETRY_ONLY":
		preparation_error="Exact isolated reused architecture geometry missing."
		return
	reused_authoring=reused
	for filename in MODULES:
		if not module_semantics.has(filename) or FileAccess.get_sha256(RAW+filename).to_lower()!=String(module_semantics[filename].get("source_sha256","")).to_lower():
			preparation_error="New module SHA or source foot missing: "+filename
			return
	if region=="ch4_s0_luoyang_gate":
		_reuse("south_gate","south_gate",Vector2(1536,1660))
		_module("west_street_front","street_row_v3.png",Vector2(700,1040),.67)
		_module("east_street_front","street_row_v3.png",Vector2(2370,1040),.67)
		_module("north_court_boundary","courtyard_wall_gate_v3.png",Vector2(1536,500),.5)
		_reuse("notice_pavilion","notice_pavilion",Vector2(700,1400))
		_route("south_avenue",[[1536,1860],[1536,1660],[1536,1280],[1536,680],[1536,500]])
		_route("public_loop",[[1536,1280],[900,1280],[500,1280],[500,1510],[1050,1510],[1536,1510],[2450,1510],[2600,1280],[1536,1280]])
		_route("notice_approach",[[900,1280],[850,1450],[700,1460]])
		gameplay_slots=_slots(
			[{"source_id":"luoyang_gate_sergeant","foot_px":[1740,1540]}],
			[{"source_id":"luoyang_wanted_board","object_id":"notice_pavilion","stand_px":[700,1460]},{"source_id":"luoyang_repeatable_bounty_board","object_id":"notice_pavilion","stand_px":[700,1460]}],
			[{"source_id":"enter_luoyang","foot_px":[1536,500]},{"source_id":"return_world","foot_px":[1536,1860]}])
	elif region=="ch4_s1_luoyang_yamen":
		# Third source has genuinely larger transparent margins, so use its
		# actual ~142px doorway rather than the superseded first source scale.
		_module("magistrate_hall","yamen_hall_v3c.png",Vector2(1536,660),1.06)
		_module("south_court_gate","courtyard_wall_gate_v3.png",Vector2(1536,1700),.5)
		_module("west_service_front","street_row_v3.png",Vector2(575,940),.67)
		_module("east_service_front","street_row_v3.png",Vector2(2500,940),.67)
		_reuse("notice_pavilion","notice_pavilion",Vector2(550,1180))
		_route("court_axis",[[1536,1860],[1536,1700],[1536,1360],[1536,830]])
		_route("court_loop",[[1536,1360],[750,1360],[300,1220],[300,1080],[1050,1080],[2050,1080],[2790,1080],[2790,1350],[2200,1500],[1536,1500],[1536,1360]])
		_route("case_board",[[750,1360],[550,1240]])
		_route("court_inscription",[[2200,1500],[1960,1450]])
		gameplay_slots=_slots(
			[{"source_id":"spar_yamen_patrol","foot_px":[1170,1000]},{"source_id":"spar_yamen_captain","foot_px":[1790,870]},{"source_id":"ch8_luoyang_final_clerk","foot_px":[1980,1180]}],
			[{"source_id":"yamen_case_board","object_id":"notice_pavilion","stand_px":[550,1240]},{"source_id":"hanjia_water_rule","object_id":"court_stone_inscription","stand_px":[1960,1450]},{"source_id":"hanjia_rubbing","object_id":"court_stone_inscription","stand_px":[1960,1450]}],
			[{"source_id":"to_city_gate","foot_px":[1536,1860]},{"source_id":"to_south_market","foot_px":[300,1220]},{"source_id":"to_canal_quay","foot_px":[2790,1350]}])
		_native("court_stone_inscription","inscription",Vector2(1960,1390),Vector2(56,32))
	elif region=="ch4_s3_luoyang_market":
		_reuse("inn","inn",Vector2(735,830))
		_reuse("shop","shop",Vector2(2320,850))
		_module("north_market_front","street_row_v3.png",Vector2(1536,450),.67)
		_module("southwest_market_front","street_row_v3.png",Vector2(725,1620),.67)
		_module("southeast_market_front","street_row_v3.png",Vector2(2360,1620),.67)
		_reuse("goods_stall","goods_stall",Vector2(620,1240))
		_reuse("medicine_stall","goods_stall",Vector2(2320,1220))
		_route("market_axis",[[1536,1860],[1536,1500],[1536,1050],[1536,640]])
		_route("market_east_west",[[220,1060],[1000,1060],[1536,1060],[2090,1060],[2840,1060]])
		_route("market_loop",[[1000,1060],[1000,1380],[1320,1420],[1320,1790],[1536,1790],[1780,1790],[1780,1400],[2090,1360],[2090,1060]])
		_route("inn_and_paper",[[1000,1060],[735,920],[735,830]])
		_route("armory",[[2090,1060],[2320,950],[2320,850]])
		_route("medicine",[[2090,1360],[2320,1290]])
		_route("paper_stall",[[1000,1380],[620,1310]])
		gameplay_slots=_slots(
			[{"source_id":"spar_luoyang_shen_guard","foot_px":[370,1130]},{"source_id":"spar_luoyang_examiner","foot_px":[1170,820]},{"source_id":"spar_luoyang_blademaster","foot_px":[1380,1540]},{"source_id":"spar_luoyang_patrol","foot_px":[1710,1500]},{"source_id":"feng_yanqiu_ch4","foot_px":[790,1030]},{"source_id":"luoyang_paper_scholar","foot_px":[520,1340]},{"source_id":"luoyang_poetry_host","foot_px":[1260,1720]},{"source_id":"luoyang_armorer","foot_px":[2440,950]}],
			[{"source_id":"armory_old_record","object_id":"shop","stand_px":[2320,950]},{"source_id":"paper_birdseal","object_id":"goods_stall","stand_px":[620,1310]},{"source_id":"zhao_medicine_parcel","object_id":"medicine_stall","stand_px":[2320,1290]},{"source_id":"xuantong_note","object_id":"shop","stand_px":[2440,950]}],
			[{"source_id":"to_yamen_square","foot_px":[1536,640]},{"source_id":"to_city_gate","foot_px":[220,1060]},{"source_id":"to_canal_docks","foot_px":[2840,1060]},{"source_id":"to_ancient_temple","foot_px":[1536,1860]}])
	else:
		_module("north_canal_warehouse","canal_warehouse_v3.png",Vector2(870,660),.62)
		_module("south_canal_front","street_row_v3.png",Vector2(650,1090),.67)
		_reuse("dock_notice","notice_pavilion",Vector2(720,1280))
		_route("quay_road",[[340,1840],[820,1500],[1430,1250],[1900,1100],[2140,820],[1840,790],[1500,810]])
		_route("quay_loop",[[1430,1250],[1170,1080],[1110,800],[1500,810],[1840,790],[2140,820],[1900,1100],[1430,1250]])
		_route("yamen_exit",[[1110,800],[260,790]])
		_route("market_exit",[[820,1500],[260,1510]])
		_route("warehouse_mud",[[1110,800],[940,750]])
		_route("quay_notice",[[1170,1080],[1060,1240],[720,1340]])
		entry_foot=Vector2(340,1840)
		gameplay_slots=_slots(
			[{"source_id":"canal_endangered_porter","foot_px":[1830,1190]},{"source_id":"canal_saved_porter","foot_px":[1830,1190]},{"source_id":"canal_old_soldier","foot_px":[1930,970]}],
			[{"source_id":"canal_feud_chest","object_id":"canal_feud_chest","stand_px":[1740,1310]},{"source_id":"canal_warehouse_mud","object_id":"warehouse_mud_trace","stand_px":[940,750]}],
			[{"source_id":"to_yamen_square","foot_px":[260,790]},{"source_id":"to_south_market","foot_px":[260,1510]},{"source_id":"canal_world_ferry","foot_px":[340,1840]}])
		_native("canal_feud_chest","cargo",Vector2(1740,1250),Vector2(42,30))
		_native("warehouse_mud_trace","mud_trace",Vector2(940,690),Vector2.ZERO)
	for i in range(4):
		var points: Array=[Vector2(300,550),Vector2(2800,520),Vector2(330,1770),Vector2(2720,1760)]
		if region=="ch4_s2_canal_docks": points=[Vector2(250,420),Vector2(1750,500),Vector2(1800,1760),Vector2(680,1800)]
		_native("street_tree_%d"%i,"tree",points[i],Vector2(24,18))
	for i in range(2):
		var lamp_foot:=Vector2(1300+i*465,1190)
		if region=="ch4_s2_canal_docks": lamp_foot=Vector2(1160,1470) if i==0 else Vector2(2120,1320)
		_reuse("lamp_%d"%i,"lamp_west",lamp_foot)
	for item in gameplay_slots["portals"]:
		var p: Array=item["foot_px"]
		item["arrival_foot_px"]=p.duplicate()
		item["interaction_polygon_px"]=[[p[0]-48,p[1]-24],[p[0]+48,p[1]-24],[p[0]+48,p[1]+24],[p[0]-48,p[1]+24]]
		item["passage_path_px"]=[[p[0],p[1]+18],p.duplicate()]
		anchors.append({"id":item["source_id"],"point_px":p,"source_action":"SYSTEM_BINDS_ORIGINAL_SOURCE_ID","action_mode":"NO_ART_EXECUTION"})
	for item in gameplay_slots["interactions"]:
		var stand: Array=item["stand_px"]
		item["interaction_polygon_px"]=[[stand[0]-38,stand[1]-20],[stand[0]+38,stand[1]-20],[stand[0]+38,stand[1]+20],[stand[0]-38,stand[1]+20]]
		anchors.append({"id":item["source_id"],"point_px":stand,"source_action":"SYSTEM_BINDS_ORIGINAL_SOURCE_ID","action_mode":"NO_ART_EXECUTION"})

func _slots(npcs: Array,interactions: Array,portals: Array) -> Dictionary:
	return {"npcs":npcs,"interactions":interactions,"portals":portals}

func _route(id: String,points: Array) -> void:
	routes.append({"id":id,"points_px":points})

func _reuse(id: String,original_id: String,foot: Vector2) -> void:
	# Sole authoring dependency: exact frozen old source definitions. The runtime
	# texture always points to the byte-exact NEW root copy, never a v2 entity.
	var frozen: Dictionary=reused_authoring
	if frozen.is_empty():
		preparation_error="Frozen source-authoring contract missing."
		return
	for item in frozen["objects"]:
		if item["id"]!=original_id: continue
		var record: Dictionary=item.duplicate(true)
		var old_foot:=Vector2(record["world_foot_px"][0],record["world_foot_px"][1])
		var delta: Vector2=foot-old_foot
		record["id"]=id
		record["original_source"]=record["texture"]
		record["texture"]=RAW+String(record["texture"]).get_file()
		record["source"]=record["texture"]
		record["world_foot_px"]=[foot.x,foot.y]
		record["depth_foot_y"]=foot.y
		record["physical_center_px"]=[foot.x,foot.y]
		for polygon in record["solid_polygons_px"]:
			for p in polygon:
				p[0]+=delta.x
				p[1]+=delta.y
		objects.append(record)
		return
	preparation_error="Missing original city source entity: "+original_id

func _module(id: String,filename: String,foot: Vector2,scale: float) -> void:
	var record: Dictionary=module_semantics[filename]
	var size: Array=record["source_size_px"]
	var uv: Array=record["foot_uv"]
	var polygons: Array=[]
	for values in record["solid_polygons_uv"]:
		var polygon: Array=[]
		for p in values: polygon.append([foot.x+(p[0]-uv[0])*size[0]*scale,foot.y+(p[1]-uv[1])*size[1]*scale])
		polygons.append(polygon)
	objects.append({"id":id,"prototype":"","texture":RAW+filename,"source":RAW+filename,"source_sha256":record["source_sha256"],"source_size_px":size,"render_size_px":[size[0]*scale,size[1]*scale],"foot_uv":uv,"world_foot_px":[foot.x,foot.y],"depth_foot_y":foot.y,"solid_polygons_px":polygons,"collision_size_px":[0,0],"physical_center_px":[foot.x,foot.y],"blocking":true,"nature":"project_original_generated_independent_architecture","source_semantics":record,"doorstep_visual_review_status":"PENDING_FIELD_REVIEW"})

func water_area(p: Vector2) -> bool:
	return region=="ch4_s2_canal_docks" and p.x>=2230.

func source_height(p: Vector2) -> float:
	return -.55 if water_area(p) else 0.

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
	objects.append({"id":id,"prototype":kind,"world_foot_px":[foot.x,foot.y],"depth_foot_y":foot.y,"collision_size_px":[physical.x,physical.y],"physical_center_px":[foot.x,foot.y-physical.y*.5],"solid_polygons_px":[],"blocking":physical.x>0.,"nature":"licensed_native_tree" if kind=="tree" else "project_original_native_city_prop"})
	if kind=="mud_trace":
		objects[-1]["role"]="ground_overlay"
		objects[-1]["z_index"]=-2
		objects[-1]["ghost_occlusion"]=false

static func point3(p: Vector2,height: float=0.) -> Vector3:
	return Vector3((p.x-1536)/PPM,height,(p.y-1024)/ZPPM)

static func feet() -> Array[Vector2]:
	var result: Array[Vector2]=[Vector2.ZERO]
	for i in range(16): result.append(Vector2(cos(TAU*i/16.)*10.,sin(TAU*i/16.)*6.))
	return result

func point_clear(p: Vector2,round_pixel: bool=true) -> bool:
	if round_pixel: p=p.round()
	if water_area(p): return false
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
	if preparation_error!="": failures.append({"preparation_error":preparation_error})
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
	var passage_centers:=0
	for portal in gameplay_slots.get("portals",[]):
		var points: Array=portal["passage_path_px"]
		for i in range(points.size()-1):
			var a:=Vector2(points[i][0],points[i][1])
			var b:=Vector2(points[i+1][0],points[i+1][1])
			var count:=int(ceil(a.distance_to(b)/4.))
			for j in range(count+1):
				var p: Vector2=a.lerp(b,float(j)/maxi(count,1))
				passage_centers+=1
				if not foot_clear(p) or not physical_clear(p): failures.append({"portal_passage":portal["source_id"],"point_px":[p.x,p.y]})
	return {"passed":failures.is_empty(),"failures":failures,"centers":centers,"portal_passage_centers":passage_centers,"objects":objects.size(),"full_foot_samples":17,"real_body_size_px":[34,24],"margin_px":0,"sampling":"round_world_pixel","ground_height_m":0.,"height_source":"genuine native flat city paving and independent low stone geometry; not image-derived fake height","scope":"SOURCE_FORECAST_ONLY: nine Rectangle samples do not replace independent full875 footprint or actual Physics/Field input"}

func snapshot() -> Dictionary:
	return {"schema_version":1,"scene_id":region,"canonical_scene_id":region,"region_root":region_out,"gameplay_slots":gameplay_slots,"logical_size_px":[3072,2048],"objects":objects,"routes":routes,"interaction_anchors":anchors,"npc_stations":npc_stations(),"entry_foot_px":[entry_foot.x,entry_foot.y],"return_foot_px":[entry_foot.x,entry_foot.y],"pixel_sampling":"round_world_pixel","physical_navigation_margin_px":0,"ordinary_actor_visual_scale":.91,"ordinary_actor_effective_height_px":113.5134,"ordinary_actor_body_px":[34,24],"status":"SOURCE_AUTHORING_ONLY_NOT_CAPTURE_READY"}

func npc_stations() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for slot in gameplay_slots.get("npcs",[]): result.append({"id":slot["source_id"],"point_px":slot["foot_px"]})
	return result

func ground_zone(p: Vector2) -> String:
	# Zones are authored for the new district layouts. They never alter solid/nav truth.
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
