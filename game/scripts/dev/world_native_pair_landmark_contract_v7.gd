extends RefCounted

# Runtime-only candidate. No registered SceneScript, shipping portal or save migration.
const WORLD_SIZE := Vector2(3072, 1024)
const LAB_ID := &"world_native_pair_landmark_lab_v7"
const BASE := preload("res://scripts/dev/world_native_pair_prop_contract_v6.gd")
const ROOT := "res://art/modules/world_map_v13/"
const PREFIX := "res://build/world_native_pair_ortho_v7_"
const BRIDGE_CENTER := Vector2(1660, 379)
const BRIDGE_SIZE := Vector2(500, 500.0 * 896.0 / 1784.0)
const CITY_FOOT := Vector2(900, 360)
const FERRY_FOOT := Vector2(2420, 725)
const BRIDGE_DECK := Rect2(1418, 348, 484, 35)
const ROAD_STOPS := [Vector2(0,535), Vector2(480,425), Vector2(1120,455), Vector2(1410,365), Vector2(1910,365), Vector2(2110,514), Vector2(2190,700), Vector2(2395,700)]
const CITY_SPUR := [Vector2(900,385), Vector2(900,450)]
const FERRY_SPUR := [Vector2(2395,700), Vector2(2395,735)]


static func river_x(y: float) -> float:
	return 1660.0 + 28.0 * sin((y - 365.0) * 0.004)


static func road_y(x: float) -> float:
	for index in range(ROAD_STOPS.size() - 1):
		var a: Vector2 = ROAD_STOPS[index]
		var b: Vector2 = ROAD_STOPS[index + 1]
		if x <= b.x:
			return lerpf(a.y, b.y, smoothstep(0.0, 1.0, clampf((x-a.x)/(b.x-a.x), 0.0, 1.0)))
	return ROAD_STOPS[-1].y


static func bridge_rect() -> Rect2:
	return BRIDGE_DECK


static func landmarks() -> Array[Dictionary]:
	return [
		{"id": "lab_luoyang", "kind": "city", "texture": ROOT + "landmark_luoyang_city_v1.png", "foot": CITY_FOOT,
			"size": Vector2(550, 366.666667), "foot_uv": Vector2(0.5, 0.83), "entry": Vector2(900, 390),
			"target_scene": &"ch4_s0_luoyang_gate"},
		{"id": "lab_bailu", "kind": "ferry", "texture": ROOT + "landmark_bailu_ferry_v1.png", "foot": FERRY_FOOT,
			"size": Vector2(420, 280), "foot_uv": Vector2(0.5, 0.89), "entry": Vector2(2395, 735),
			"target_scene": &"openworld_bailu_ferry"},
	]


static func scene_objects() -> Array[Dictionary]:
	var objects := BASE.scene_objects()
	# Move the paired visual, footprint and depth together off the new ferry road.
	# The v6 source and its other thirteen-prop contracts remain unchanged.
	for object in objects:
		if object["id"] == "generated_shrub_east":
			object["pos"] += Vector2(20, 160) / WORLD_SIZE
			object["depth_sort_foot_y"] = 810.0 / WORLD_SIZE.y
		elif object["id"] == "grove_middle_b":
			# The new v7 river replaces this v6 grove's former land; keep its
			# entire paired base on the east bank rather than floating over water.
			object["pos"] += Vector2(120, 10) / WORLD_SIZE
			object["depth_sort_foot_y"] = 810.0 / WORLD_SIZE.y
	for landmark in landmarks():
		var foot: Vector2 = landmark["foot"]
		var size: Vector2 = landmark["size"]
		var center: Vector2 = foot + (Vector2(0.5, 0.5) - landmark["foot_uv"]) * size
		objects.append({"id": landmark["id"], "texture": landmark["texture"], "pos": center / WORLD_SIZE,
			"render_size_px": size, "sort_by_feet": true, "depth_sort_foot_y": foot.y / WORLD_SIZE.y})
	objects.append({"id": "lab_bridge_deck", "texture": ROOT + "bridge_stone_eastwest_v1.png",
		"pos": BRIDGE_CENTER / WORLD_SIZE, "render_size_px": BRIDGE_SIZE, "z_index": -2})
	objects.append({"id": "lab_bridge_front_rail", "texture": ROOT + "bridge_stone_eastwest_front_rail_v7.png",
		"pos": BRIDGE_CENTER / WORLD_SIZE, "render_size_px": BRIDGE_SIZE, "sort_by_feet": true,
		"depth_sort_foot_y": 408.0 / WORLD_SIZE.y})
	return objects


static func blockers() -> Array[Dictionary]:
	var output: Array[Dictionary] = []
	for entry in [
		{"id": "lab_city_compound", "rect": Rect2(635, 115, 530, 244)},
		{"id": "lab_bridge_back_rail", "rect": Rect2(1430, 320, 460, 22)},
		{"id": "lab_bridge_front_rail", "rect": Rect2(1430, 390, 460, 18)},
		{"id": "lab_ferry_pavilion", "rect": Rect2(2230, 495, 160, 130)},
		{"id": "lab_ferry_ship", "rect": Rect2(2520, 540, 145, 200)},
	]:
		var rect: Rect2 = entry["rect"]
		output.append({"id": entry["id"], "pos": rect.get_center() / WORLD_SIZE,
			"size": rect.size / WORLD_SIZE, "walkability_margin": 0.0})
	return output


static func route_points() -> Array[Vector2]:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(PREFIX + "route.json"))
	var points: Array[Vector2] = []
	if data is Dictionary and data.get("road_feet") is Array:
		for pair in data["road_feet"]:
			points.append(Vector2(pair[0], pair[1]))
	return points


static func make_scene() -> SceneScript:
	var layout := WalkableMapLayout.new()
	layout.design_size = Vector2i(WORLD_SIZE)
	layout.display_at_native_size = true
	layout.walkable_mask_path = PREFIX + "walk.png"
	layout.visual_objects = scene_objects()
	layout.blockers = blockers()
	for landmark in landmarks():
		var target := load("res://data/scenes/%s.tres" % landmark["target_scene"]) as SceneScript
		layout.portals.append({"id": landmark["id"], "pos": landmark["entry"] / WORLD_SIZE,
			"size": Vector2(58, 36) / WORLD_SIZE, "label": "洛阳城 · 开发接驳" if landmark["kind"] == "city" else "白鹿渡 · 开发接驳",
			"target_scene": String(landmark["target_scene"]), "target_pos": target.player_spawn,
			"show_destination_label": true, "destination_label_side": -1.0})
	var scene := SceneScript.new()
	scene.scene_id = LAB_ID
	scene.display_name = "中心—东岸 · 分层路线制作候选"
	scene.background_path = PREFIX + "visual.png"
	scene.is_walkable = true
	scene.is_settlement = true
	scene.actor_positions_are_feet = true
	scene.map_layout = layout
	scene.player_spawn = Vector2(380, 448) / WORLD_SIZE
	scene.player_visual_scale = 0.754
	scene.camera_zoom = 1.25
	return scene
