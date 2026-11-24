extends RefCounted

# Composition: v9 water/routes/legacy entities stay frozen; generated v11
# metadata supplies only the explicitly approved two rocks / eight low herbs.
const SOURCE := preload("res://scripts/dev/world_native_pair_landmark_contract_v10.gd")
const WORLD_SIZE := SOURCE.WORLD_SIZE
const LAB_ID := &"world_native_pair_landmark_lab_v11"
const ROOT := SOURCE.ROOT
const PREFIX := "res://build/world_native_pair_ortho_v11_"
const BRIDGE_CENTER := SOURCE.BRIDGE_CENTER
const BRIDGE_SIZE := SOURCE.BRIDGE_SIZE
const CITY_FOOT := SOURCE.CITY_FOOT
const FERRY_FOOT := SOURCE.FERRY_FOOT
const BRIDGE_DECK := SOURCE.BRIDGE_DECK
const DOCK_DECKS := SOURCE.DOCK_DECKS
const DOCK_APPROACH := SOURCE.DOCK_APPROACH
const DOCK_ROUTE := SOURCE.DOCK_ROUTE
const PAVILION_FOUNDATION := SOURCE.PAVILION_FOUNDATION
const SHIP_WATER := SOURCE.SHIP_WATER
const ROAD_STOPS := SOURCE.ROAD_STOPS
const CITY_SPUR := SOURCE.CITY_SPUR
const FERRY_SPUR := SOURCE.FERRY_SPUR
const PROP_MOVES := SOURCE.PROP_MOVES
const RAIL_PARTS := SOURCE.RAIL_PARTS
const REPLACED_IDS := ["cc0_boulder_west","generated_shrub_west","cc0_boulder_east_low","grove_east_a"]
const HEIGHT_SOURCE_ROI := Rect2(120,160,440,200)
const HEIGHT_PROJECTED_ROI := Rect2(64,0,576,400)
const VISUAL_ROIS := [HEIGHT_PROJECTED_ROI,Rect2(710,470,290,270),Rect2(1100,635,170,180),Rect2(1750,505,320,285),Rect2(2200,785,170,180)]
const BOULDER_SOURCE := "res://art/external/polyhaven/boulder_01/boulder_01_1k.gltf"
const HERB_SOURCE := "res://art/external/polyhaven/shrub_03/shrub_03_1k.gltf"


static func model_specs() -> Array[Dictionary]:
	var specs: Array[Dictionary]=[
		{"id":"cc0_boulder_west","old_id":"cc0_boulder_west","source":BOULDER_SOURCE,"foot":Vector2(855,650),"yaw":35.0,"scale":1.0,"variant":0,"blocking":true},
		{"id":"cc0_boulder_east_low","old_id":"cc0_boulder_east_low","source":BOULDER_SOURCE,"foot":Vector2(1910,685),"yaw":-24.0,"scale":0.82,"variant":0,"blocking":true}]
	var names: Array[String]=["a","b","c","d"]
	var offsets := [Vector2(-17,-7),Vector2(12,-2),Vector2(-4,10),Vector2(27,13)]
	for group in [{"id":"generated_shrub_west","foot":Vector2(1175,745)},{"id":"grove_east_a","foot":Vector2(2270,895)}]:
		for i in names.size():
			specs.append({"id":String(group["id"])+"_"+names[i],"old_id":group["id"],"source":HERB_SOURCE,"foot":group["foot"]+offsets[i],"group_anchor":group["foot"],"yaw":22.0+float(i)*73.0,"scale":1.0,"variant":i,"blocking":false})
	return specs


static func rail_foot_y(part: Dictionary) -> float:
	return SOURCE.rail_foot_y(part)


static func river_x(y: float) -> float:
	return SOURCE.river_x(y)


static func river_half_width(y: float) -> float:
	return SOURCE.river_half_width(y)


static func shore_x(y: float) -> float:
	return SOURCE.shore_x(y)


static func road_y(x: float) -> float:
	return SOURCE.road_y(x)


static func bridge_rect() -> Rect2:
	return SOURCE.bridge_rect()


static func landmarks() -> Array[Dictionary]:
	return SOURCE.landmarks()


static func blockers() -> Array[Dictionary]:
	return SOURCE.blockers()


static func entity_metadata() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	var seen: Dictionary={}
	for spec in model_specs():
		var path: String=PREFIX+"entity_"+String(spec["id"])+".json"
		var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
		if not data is Dictionary or not _valid_entity(data,spec,path) or seen.has(data.get("id","")):
			push_error("Missing native v11 entity metadata: "+path)
			return []
		seen[data["id"]]=true
		result.append(data)
	return result


static func _finite_pair(value: Variant, positive: bool=false) -> bool:
	if not value is Array or value.size()!=2:
		return false
	for number in value:
		if not (number is int or number is float) or not is_finite(float(number)) or (positive and float(number)<=0):
			return false
	return true


static func _valid_entity(data: Dictionary, spec: Dictionary, path: String) -> bool:
	if data.get("id")!=spec["id"] or data.get("old_id")!=spec["old_id"] or data.get("source_path")!=spec["source"] or data.get("metadata_path")!=path or data.get("texture_path")!=PREFIX+"entity_"+String(spec["id"])+".png":
		return false
	if not data.get("blocking") is bool or data.get("blocking")!=spec["blocking"] or data.get("variant")!=spec["variant"] or data.get("source_sha256")!=FileAccess.get_sha256(spec["source"]):
		return false
	for key in ["world_foot","source_foot","foot_uv","group_anchor","collision_center"]:
		if not _finite_pair(data.get(key)):
			return false
	for key in ["size","render_size","collision_size"]:
		if not _finite_pair(data.get(key),true):
			return false
	if data["size"]!=data["render_size"]:
		return false
	var base: Variant=data.get("world_base_y")
	if not (base is int or base is float) or not is_finite(float(base)) or absf(float(base)-float(data["world_foot"][1]))>0.001:
		return false
	var source := Vector2(data["source_foot"][0],data["source_foot"][1])
	return source.distance_to(spec["foot"])<0.001


static func scene_objects() -> Array[Dictionary]:
	var objects: Array[Dictionary]=[]
	for object in SOURCE.scene_objects():
		if String(object["id"]) in REPLACED_IDS:
			continue
		var texture: String=object.get("texture","")
		if texture.begins_with(SOURCE.PREFIX):
			object["texture"]=PREFIX+texture.trim_prefix(SOURCE.PREFIX)
		objects.append(object)
	# Ground-only actual cast shadows, not source models baked into terrain.
	objects.append({"id":"native_cast_shadows","texture":PREFIX+"shadow.png","pos":Vector2(0.5,0.5),"render_size_px":WORLD_SIZE,"z_index":-3})
	for data in entity_metadata():
		var foot := Vector2(data["world_foot"][0],data["world_foot"][1])
		var size := Vector2(data["render_size"][0],data["render_size"][1])
		var uv := Vector2(data["foot_uv"][0],data["foot_uv"][1])
		var center := foot+(Vector2(0.5,0.5)-uv)*size
		var object := {"id":data["id"],"texture":data["texture_path"],"pos":center/WORLD_SIZE,"render_size_px":size,"sort_by_feet":true,"depth_sort_foot_y":float(data["world_base_y"])/WORLD_SIZE.y}
		if data["blocking"]:
			var collision_center := Vector2(data["collision_center"][0],data["collision_center"][1])
			object["collision_offset"]=(collision_center-center)/WORLD_SIZE
			object["collision_size"]=Vector2(data["collision_size"][0],data["collision_size"][1])/WORLD_SIZE
		objects.append(object)
	return objects


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
	scene.display_name="中心—东岸 · 原生岩肩与低草 v11 候选"
	scene.background_path=PREFIX+"visual.png"
	scene.map_layout.walkable_mask_path=PREFIX+"walk.png"
	scene.map_layout.visual_objects=scene_objects()
	return scene

