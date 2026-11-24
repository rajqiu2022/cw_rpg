extends RefCounted

# Isolated v8 visual candidate: all authored geography/depth comes from v7.
const SOURCE := preload("res://scripts/dev/world_native_pair_landmark_contract_v7.gd")
const WORLD_SIZE := SOURCE.WORLD_SIZE
const LAB_ID := &"world_native_pair_landmark_lab_v8"
const ROOT := SOURCE.ROOT
const PREFIX := "res://build/world_native_pair_ortho_v8_"
const BRIDGE_CENTER := SOURCE.BRIDGE_CENTER
const BRIDGE_SIZE := SOURCE.BRIDGE_SIZE
const CITY_FOOT := SOURCE.CITY_FOOT
const FERRY_FOOT := SOURCE.FERRY_FOOT
const BRIDGE_DECK := SOURCE.BRIDGE_DECK
const ROAD_STOPS := SOURCE.ROAD_STOPS
const CITY_SPUR := SOURCE.CITY_SPUR
const FERRY_SPUR := SOURCE.FERRY_SPUR


static func river_x(y: float) -> float:
	return SOURCE.river_x(y)


static func road_y(x: float) -> float:
	return SOURCE.road_y(x)


static func bridge_rect() -> Rect2:
	return SOURCE.bridge_rect()


static func landmarks() -> Array[Dictionary]:
	return SOURCE.landmarks()


static func scene_objects() -> Array[Dictionary]:
	return SOURCE.scene_objects()


static func blockers() -> Array[Dictionary]:
	return SOURCE.blockers()


static func route_points() -> Array[Vector2]:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PREFIX + "route.json"))
	var points: Array[Vector2] = []
	if data is Dictionary and data.get("road_feet") is Array:
		for pair in data["road_feet"]:
			points.append(Vector2(pair[0], pair[1]))
	return points


static func make_scene() -> SceneScript:
	var scene := SOURCE.make_scene()
	scene.scene_id = LAB_ID
	scene.display_name = "中心—东岸 · 地表改良 v8 制作候选"
	scene.background_path = PREFIX + "visual.png"
	scene.map_layout.walkable_mask_path = PREFIX + "walk.png"
	return scene
