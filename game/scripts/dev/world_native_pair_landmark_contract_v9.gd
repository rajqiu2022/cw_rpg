extends RefCounted

const SOURCE := preload("res://scripts/dev/world_native_pair_landmark_contract_v7.gd")
const WORLD_SIZE := SOURCE.WORLD_SIZE
const LAB_ID := &"world_native_pair_landmark_lab_v9"
const ROOT := SOURCE.ROOT
const PREFIX := "res://build/world_native_pair_ortho_v9_"
const BRIDGE_CENTER := SOURCE.BRIDGE_CENTER
const BRIDGE_SIZE := SOURCE.BRIDGE_SIZE
const CITY_FOOT := SOURCE.CITY_FOOT
const FERRY_FOOT := SOURCE.FERRY_FOOT
const BRIDGE_DECK := SOURCE.BRIDGE_DECK
const DOCK_DECKS := [Rect2(2380,593,95,32),Rect2(2395,613,52,79)]
const DOCK_APPROACH := Rect2(2385,688,60,52)
const DOCK_ROUTE := [Vector2(2390,735),Vector2(2420,720),Vector2(2420,650),Vector2(2420,609),Vector2(2460,609)]
const PAVILION_FOUNDATION := Rect2(2230,560,158,64)
const SHIP_WATER := Rect2(2525,590,60,88)
const ROAD_STOPS := [Vector2(0,535),Vector2(480,425),Vector2(1120,455),Vector2(1410,365),Vector2(1910,365),Vector2(2110,514),Vector2(2190,700),Vector2(2350,700)]
const CITY_SPUR := SOURCE.CITY_SPUR
const FERRY_SPUR := [Vector2(2350,700),Vector2(2390,735)]
const PROP_MOVES := {"grove_middle_b":Vector2(80,0),"cc0_boulder_east_low":Vector2(60,0)}
const RAIL_PARTS := [
	{"name":"north","source_bottom_y":631.0},
	{"name":"right_middle","source_bottom_y":757.0},
	{"name":"right_near","source_bottom_y":924.0},
	{"name":"left_middle","source_bottom_y":713.0},
	{"name":"left_near","source_bottom_y":910.0}]


static func rail_foot_y(part: Dictionary) -> float:
	var ferry: Dictionary=landmarks()[1]
	return ferry["foot"].y+(float(part["source_bottom_y"])/1024.0-ferry["foot_uv"].y)*ferry["size"].y


static func river_x(y: float) -> float:
	var offset := y-365.0
	var bend := smoothstep(90.0,190.0,absf(offset))
	return 1660.0+bend*(90.0*sin(offset/180.0)+35.0*sin(offset/63.0))


static func river_half_width(y: float) -> float:
	var offset := y-365.0
	return lerpf(64.0,50.0+26.0*pow(sin(offset/145.0),2.0),smoothstep(90.0,180.0,absf(offset)))


static func shore_x(y: float) -> float:
	return 2795.0-0.36*y+30.0*sin(y*0.007)-130.0*exp(-pow((y-625.0)/75.0,2.0))


static func road_y(x: float) -> float:
	for i in range(ROAD_STOPS.size()-1):
		var a: Vector2=ROAD_STOPS[i]
		var b: Vector2=ROAD_STOPS[i+1]
		if x<=b.x:
			return lerpf(a.y,b.y,smoothstep(0.0,1.0,clampf((x-a.x)/(b.x-a.x),0.0,1.0)))
	return ROAD_STOPS[-1].y


static func bridge_rect() -> Rect2:
	return BRIDGE_DECK


static func landmarks() -> Array[Dictionary]:
	var entries := SOURCE.landmarks()
	entries[1]["entry"]=Vector2(2390,735)
	return entries


static func scene_objects() -> Array[Dictionary]:
	var objects := SOURCE.scene_objects()
	for object in objects:
		var id: String=object["id"]
		if PROP_MOVES.has(id):
			var move: Vector2=PROP_MOVES[id]
			object["pos"]+=move/WORLD_SIZE
			object["depth_sort_foot_y"]+=move.y/WORLD_SIZE.y
		if id=="lab_bailu":
			# The floor must stay below an actor on the actual L-shaped dock.
			object.erase("sort_by_feet")
			object.erase("depth_sort_foot_y")
			object["z_index"]=-2
	var ferry: Dictionary=landmarks()[1]
	var size: Vector2=ferry["size"]
	var center: Vector2=ferry["foot"]+(Vector2(0.5,0.5)-ferry["foot_uv"])*size
	objects.append({"id":"lab_ferry_pavilion_foreground","texture":PREFIX+"ferry_pavilion_foreground.png","pos":center/WORLD_SIZE,"render_size_px":size,"sort_by_feet":true,"depth_sort_foot_y":625.0/WORLD_SIZE.y})
	# The merged rail PNG is an audit artifact only: independent bases cannot
	# share one Y710 line without covering an actor already south of a column.
	for part in RAIL_PARTS:
		objects.append({"id":"lab_ferry_rail_"+String(part["name"]),"texture":PREFIX+"ferry_rail_"+String(part["name"])+".png","pos":center/WORLD_SIZE,"render_size_px":size,"sort_by_feet":true,"depth_sort_foot_y":rail_foot_y(part)/WORLD_SIZE.y})
	return objects


static func blockers() -> Array[Dictionary]:
	var entries := SOURCE.blockers()
	for entry in entries:
		if entry["id"]=="lab_ferry_pavilion":
			entry["pos"]=Vector2(2295,560)/WORLD_SIZE
			entry["size"]=Vector2(130,130)/WORLD_SIZE
	for rect in [Rect2(2376,635,11,60),Rect2(2454,630,13,69),Rect2(2473,593,12,42)]:
		entries.append({"id":"lab_dock_post_%d"%entries.size(),"pos":rect.get_center()/WORLD_SIZE,"size":rect.size/WORLD_SIZE,"walkability_margin":0.0})
	return entries


static func route_points() -> Array[Vector2]:
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(PREFIX+"route.json"))
	var points: Array[Vector2]=[]
	if data is Dictionary:
		for pair in data.get("road_feet",[]):
			points.append(Vector2(pair[0],pair[1]))
	return points


static func make_scene() -> SceneScript:
	var scene := SOURCE.make_scene()
	scene.scene_id=LAB_ID
	scene.display_name="中心—东岸 · 城外岩肩与港湾 v9 候选"
	scene.background_path=PREFIX+"visual.png"
	scene.map_layout.walkable_mask_path=PREFIX+"walk.png"
	scene.map_layout.visual_objects=scene_objects()
	scene.map_layout.blockers=blockers()
	for portal in scene.map_layout.portals:
		if portal["id"]=="lab_bailu":
			portal["pos"]=Vector2(2390,735)/WORLD_SIZE
	return scene
