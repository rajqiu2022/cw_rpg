extends RefCounted

# Composition is deliberate: inherited static v9 methods would still bind its
# LAB_ID/PREFIX. Geometry is delegated unchanged; only visual paths differ.
const SOURCE := preload("res://scripts/dev/world_native_pair_landmark_contract_v9.gd")
const WORLD_SIZE := SOURCE.WORLD_SIZE
const LAB_ID := &"world_native_pair_landmark_lab_v10"
const ROOT := SOURCE.ROOT
const PREFIX := "res://build/world_native_pair_ortho_v10_"
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


static func scene_objects() -> Array[Dictionary]:
	var objects: Array[Dictionary]=SOURCE.scene_objects()
	for object in objects:
		var texture: String=object.get("texture","")
		if texture.begins_with(SOURCE.PREFIX):
			object["texture"]=PREFIX+texture.trim_prefix(SOURCE.PREFIX)
		# Sole approved prop visual-field exception: native contact replaces
		# the previous large repeated runtime ellipse, never an extra shadow.
		object.erase("ground_shadow_size_px")
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
	scene.display_name="中心—东岸 · 材质与接触地面 v10 候选"
	scene.background_path=PREFIX+"visual.png"
	scene.map_layout.walkable_mask_path=PREFIX+"walk.png"
	scene.map_layout.visual_objects=scene_objects()
	return scene
