extends SceneTree

## Staging gate for the 3x3 layered world. This intentionally does not replace
## the historical v12 test: production may remain on v12 until this passes.

const STAGING_SCENE := "res://data/scenes/world_map_jianghu_v13_staging.tres"
const TILE_DIR := "res://art/backgrounds/world_map_v13_tiles"
const WORLD_SIZE := Vector2i(4608, 3072)
const TILE_SIZE := Vector2i(1536, 1024)
const EXPECTED_ROUTES := {
	"yanmen_pass": ["openworld_yanmen_pass", Vector2i(0, 0)],
	"huashan": ["openworld_huashan_forecourt", Vector2i(0, 0)],
	"wudang": ["openworld_wudang_gate", Vector2i(1, 0)],
	"gufeng": ["ch5_s1_relief_road", Vector2i(1, 0)],
	"lingyue": ["ch2_s4_lingyue_gate", Vector2i(2, 0)],
	"bianzhou": ["openworld_bianzhou_city", Vector2i(0, 1)],
	"linxi_village": ["linxi_village_scrollmap", Vector2i(0, 1)],
	"luoyang": ["ch4_s0_luoyang_gate", Vector2i(1, 1)],
	"xiangzhou": ["openworld_xiangzhou_city", Vector2i(1, 1)],
	"east_sea_port": ["openworld_east_sea_port", Vector2i(2, 1)],
	"bailu_ferry": ["openworld_bailu_ferry", Vector2i(2, 1)],
	"zhuwei_village": ["ch1_s2_qingfeng", Vector2i(0, 2)],
	"qinghe_town": ["openworld_qinghe_town", Vector2i(0, 2)],
	"jinling": ["openworld_jinling_city", Vector2i(1, 2)],
	"mingwu": ["ch7_s2_mingwu_tea_town", Vector2i(2, 2)],
	"lieyun_valley": ["ch7_s1_lieyun_valley_ferry", Vector2i(2, 2)],
}

var _checks := 0
var _failures := 0
var _pending := 0
var _strict := false
var _production_v13 := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var production := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	_production_v13 = production != null and production.map_layout != null and production.map_layout.schema_version == 13
	_strict = OS.get_cmdline_user_args().has("--strict-v13") or _production_v13
	if not ResourceLoader.exists(STAGING_SCENE):
		_require(false, "v13 staging SceneScript is present: " + STAGING_SCENE)
		_finish()
		return
	var scene := load(STAGING_SCENE) as SceneScript
	_require(scene != null and scene.map_layout != null, "staging scene and layout load")
	if scene == null or scene.map_layout == null:
		_finish()
		return
	var layout := scene.map_layout as WalkableMapLayout
	_check(scene.scene_id == &"world_map_jianghu_v13_staging", "staging scene has isolated ID")
	_check(scene.is_walkable and layout.schema_version == 13, "walkable scene owns v13 layout")
	_check(layout.design_size == WORLD_SIZE, "logical world is 4608x3072")
	_check(layout.display_at_native_size, "v13 renders at logical native size")
	_check(not scene.background_path.contains("v12") and not layout.walkable_mask_path.contains("v12"), "staging art and navigation do not fall back to v12")
	# The gameplay path streams nine native tiles. A full-size texture is only
	# optional QA preview data; requiring one would add an unnecessary import.
	var background := load(scene.background_path) as Texture2D if ResourceLoader.exists(scene.background_path) else null
	var navigation: Texture2D = null
	if background != null and background.get_size() == Vector2(WORLD_SIZE):
		_audit_pixel_seams(background.get_image())
	var navigation_ready := false
	if not layout.walkable_mask_tiles.is_empty():
		_require(layout.walkable_mask_tiles.size() == 9, "nine independent navigation tile records exist")
		var nav_cells: Dictionary = {}
		for raw in layout.walkable_mask_tiles:
			var nav: Dictionary = raw
			var rect: Rect2 = nav.get("logical_rect", Rect2())
			var path := String(nav.get("path", ""))
			_check(rect.size == Vector2(TILE_SIZE), "navigation tile uses native tile size: " + path.get_file())
			_check(not nav_cells.has(rect.position), "navigation tile rectangle is unique: " + str(rect.position))
			nav_cells[rect.position] = true
			_require(ResourceLoader.exists(path), "navigation tile texture exists: " + path.get_file())
			if ResourceLoader.exists(path):
				var tile_texture := load(path) as Texture2D
				_check(tile_texture != null and tile_texture.get_size() == Vector2(TILE_SIZE), "navigation tile raster matches native size: " + path.get_file())
		navigation_ready = layout.walkable_mask_tiles.size() == 9 and nav_cells.size() == 9
		for raw in layout.walkable_mask_tiles:
			var path := String((raw as Dictionary).get("path", ""))
			if not ResourceLoader.exists(path):
				navigation_ready = false
			else:
				var tile_texture := load(path) as Texture2D
				if tile_texture == null or tile_texture.get_size() != Vector2(TILE_SIZE):
					navigation_ready = false
		for row in range(3):
			for col in range(3):
				var origin := Vector2(col * TILE_SIZE.x, row * TILE_SIZE.y)
				_require(nav_cells.has(origin), "navigation tile covers r%dc%d" % [row, col])
				if not nav_cells.has(origin):
					navigation_ready = false
	else:
		_require(ResourceLoader.exists(layout.walkable_mask_path), "full-canvas v13 navigation texture exists")
		if ResourceLoader.exists(layout.walkable_mask_path):
			navigation = load(layout.walkable_mask_path) as Texture2D
			_check(navigation != null and navigation.get_size() == Vector2(WORLD_SIZE), "navigation mask matches logical canvas")
			navigation_ready = navigation != null and navigation.get_size() == Vector2(WORLD_SIZE)
	_require(navigation_ready, "all navigation tiles are independent and complete")
	_require(scene.streamed_background != null, "staging supplies multi-screen streaming data")
	if scene.streamed_background != null:
		_check(scene.streamed_background.logical_size == WORLD_SIZE, "streaming logical size matches map")
		var stream_cells: Dictionary = {}
		var stream_chunks := scene.streamed_background.get_chunks(true)
		_require(stream_chunks.size() == 9, "native streaming spans all nine tiles")
		for raw in stream_chunks:
			var chunk: Dictionary = raw
			var rect: Rect2 = chunk.get("logical_rect", Rect2())
			var path := String(chunk.get("path", ""))
			_check(rect.size == Vector2(TILE_SIZE), "stream chunk native rect: " + path.get_file())
			_check(not stream_cells.has(rect.position), "stream chunk rect unique: " + str(rect.position))
			stream_cells[rect.position] = true
			_require(ResourceLoader.exists(path), "stream chunk texture loads: " + path.get_file())
			if ResourceLoader.exists(path):
				var texture := load(path) as Texture2D
				_check(texture != null and texture.get_size() == Vector2(TILE_SIZE), "stream chunk native raster: " + path.get_file())
		for row in range(3):
			for col in range(3):
				_require(stream_cells.has(Vector2(col * TILE_SIZE.x, row * TILE_SIZE.y)), "stream chunk covers r%dc%d" % [row, col])

	_audit_original_tiles(scene.streamed_background)
	var field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	field.set("_current_scene", scene)
	field.set("_screen_size", Vector2(WORLD_SIZE))
	field.set("_world_size", Vector2(WORLD_SIZE))
	field.call("_load_walkable_mask", layout.walkable_mask_path)
	field.call("_load_walkable_mask_tiles", layout.walkable_mask_tiles)
	field.call("_rebuild_walkability_collision_entries", layout.blockers, layout.visual_objects)
	_audit_portals(scene, field, navigation_ready)
	_audit_landmarks(layout, field)
	if navigation_ready:
		_audit_terrain_probes(layout, field)
		_audit_land_connections(scene, field)
	else:
		_pending_note("full-map foot clearance, road connectivity, and forbidden terrain await nine navigation tiles")
	field.free()

	if production == null or production.map_layout == null or production.map_layout.schema_version != 13:
		_pending_note("production world_map_jianghu still runs v12; staging acceptance is independent")
	else:
		_check(production.map_layout == layout or production.map_layout.resource_path.contains("v13"), "production world references accepted v13 data")
	_finish()


func _audit_original_tiles(streamed: StreamedBackgroundSet) -> void:
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(TILE_DIR)):
		_require(false, "nine original 1536x1024 tiles directory exists")
		return
	var paths: Array[String] = []
	if streamed != null:
		for raw in streamed.get_chunks(true):
			var path := String((raw as Dictionary).get("path", ""))
			_check(path.begins_with(TILE_DIR + "/") and path.ends_with(".png"), "active tile source is a v13 native PNG: " + path.get_file())
			paths.append(path)
	paths.sort()
	_require(paths.size() == 9, "exactly nine active original map tiles are present")
	var unique_paths: Dictionary = {}
	for path in paths:
		unique_paths[path] = true
	_check(unique_paths.size() == paths.size(), "active tile paths are unique")
	var hashes: Dictionary = {}
	for path in paths:
		var image := Image.load_from_file(path)
		_check(image != null and image.get_size() == TILE_SIZE, "tile is 1536x1024: " + path.get_file())
		if image != null:
			var digest := FileAccess.get_sha256(path)
			_check(not hashes.has(digest), "tile is not a repeated bitmap: " + path.get_file())
			hashes[digest] = true


func _audit_portals(scene: SceneScript, field: Node, navigation_ready: bool) -> void:
	var portals := scene.map_layout.portals
	_require(portals.size() == 16, "v13 preserves exactly 16 public gateways")
	var seen: Dictionary = {}
	for raw in portals:
		if not raw is Dictionary:
			_check(false, "portal entry is a dictionary")
			continue
		var portal: Dictionary = raw
		var id := String(portal.get("id", ""))
		_check(EXPECTED_ROUTES.has(id) and not seen.has(id), "known unique gateway: " + id)
		if not EXPECTED_ROUTES.has(id):
			continue
		seen[id] = true
		var expected: Array = EXPECTED_ROUTES[id]
		var pos: Vector2 = portal.get("pos", Vector2(-1, -1))
		var tile := Vector2i(clampi(int(floor(pos.x * 3.0)), 0, 2), clampi(int(floor(pos.y * 3.0)), 0, 2))
		_check(tile == expected[1], "%s is on its planned 3x3 tile" % id)
		_check(String(portal.get("target_scene", "")) == expected[0], "%s keeps its destination scene" % id)
		_require(bool(portal.get("show_destination_label", false)) and not String(portal.get("label", "")).is_empty(), "%s has a visible place name" % id)
		_require(not bool(portal.get("staging_pending_asset", false)), "%s has its reviewed independent landmark asset" % id)
		if navigation_ready:
			_require(field.call("_spawn_has_foot_clearance", scene, pos), "%s has full foot clearance at entry" % id)
		var target_id := String(portal.get("target_scene", ""))
		var target_path := "res://data/scenes/%s.tres" % target_id
		_check(ResourceLoader.exists(target_path), "%s destination resource exists" % id)
		if ResourceLoader.exists(target_path):
			var destination := load(target_path) as SceneScript
			_check(_destination_returns_to_world(destination), "%s destination has an in-game world return" % id)
			var arrival: Vector2 = portal.get("target_pos", Vector2(-1, -1))
			_check(arrival.x >= 0.0 and arrival.x <= 1.0 and arrival.y >= 0.0 and arrival.y <= 1.0, "%s authored destination spawn is normalized" % id)
			var router := root.get_node("SceneRouter")
			var staging_return_anchor: Variant = router.get_world_map_position_for_scene(StringName(target_id), StringName(scene.scene_id))
			_require(staging_return_anchor is Vector2 and (staging_return_anchor as Vector2).distance_to(pos) < 0.0001, "%s staging return anchor resolves to its own gateway" % id)
			if _production_v13:
				var return_anchor: Variant = router.get_world_map_position_for_scene(StringName(target_id))
				_check(return_anchor is Vector2 and (return_anchor as Vector2).distance_to(pos) < 0.0001, "%s runtime return anchor resolves to its v13 gateway" % id)
	for id in EXPECTED_ROUTES.keys():
		_require(seen.has(id), "required gateway is present: " + id)


func _destination_returns_to_world(scene: SceneScript) -> bool:
	if scene == null:
		return false
	if scene.map_layout != null:
		for raw in scene.map_layout.portals:
			if raw is Dictionary and (String(raw.get("action", "")) == "world_map" or String(raw.get("target_scene", "")) == "world_map_jianghu"):
				return true
	for raw in scene.hotspots:
		if raw is Dictionary and String(raw.get("action", "")) == "world_map":
			return true
	return false


func _audit_terrain_probes(layout: WalkableMapLayout, field: Node) -> void:
	_require(layout.walkable_probes.size() >= 9, "each tile has authored safe-ground evidence")
	var categories := {"sea": false, "mountain": false, "city": false}
	for raw in layout.walkable_probes:
		var probe: Dictionary = raw
		var pos: Vector2 = probe.get("pos", Vector2(-1, -1))
		_check(field.call("_spawn_has_foot_clearance", field.get("_current_scene"), pos), "safe foot probe: " + String(probe.get("id", "")))
	for raw in layout.blocked_probes:
		var probe: Dictionary = raw
		var id := String(probe.get("id", ""))
		var lowered := id.to_lower()
		if "sea" in lowered or "water" in lowered or "ocean" in lowered:
			categories["sea"] = true
		if "mountain" in lowered or "ridge" in lowered or "cliff" in lowered:
			categories["mountain"] = true
		if "city" in lowered or "roof" in lowered or "courtyard" in lowered:
			categories["city"] = true
		var pos: Vector2 = probe.get("pos", Vector2(-1, -1))
		_check(not field.call("_is_walkable_by_mask", pos) or field.call("_is_blocked_by_layout", pos), "blocked terrain probe: " + id)
	for category in categories.keys():
		_require(categories[category], "blocked probes cover " + category)
	# The paired east-coast docks sit on dry land, but their adjacent blue-water
	# areas must never become a walkable shortcut around the shoreline.
	for port_water in [
		{"id": "east_sea_port_adjacent_water", "pos": Vector2(0.955, 0.42)},
		{"id": "bailu_ferry_adjacent_water", "pos": Vector2(0.955, 0.58)},
	]:
		var water_pos: Vector2 = port_water["pos"]
		_check(not field.call("_is_walkable_by_mask", water_pos) or field.call("_is_blocked_by_layout", water_pos), "near-port seawater remains blocked: " + String(port_water["id"]))


func _audit_landmarks(layout: WalkableMapLayout, field: Node) -> void:
	var layered_count := 0
	var landmark_ids: Dictionary = {}
	var asset_hashes: Dictionary = {}
	for raw in layout.visual_objects:
		if not raw is Dictionary:
			continue
		var object: Dictionary = raw
		var id := String(object.get("id", ""))
		var portal_id := String(object.get("portal_id", ""))
		if not object.has("collision_size"):
			continue
		layered_count += 1
		var texture_path := String(object.get("texture", ""))
		_require(ResourceLoader.exists(texture_path), "landmark has imported transparent art: " + id)
		_check(bool(object.get("sort_by_feet", false)) and object.has("depth_sort_foot_y"), "landmark owns Y-depth contract: " + id)
		var pos: Vector2 = object.get("pos", Vector2.ZERO) + object.get("collision_offset", Vector2.ZERO)
		_check(field.call("_is_blocked_by_layout", pos), "landmark foot is physically blocked: " + id)
		if portal_id != "":
			_check(EXPECTED_ROUTES.has(portal_id) and not landmark_ids.has(portal_id), "landmark binds one unique gateway: " + portal_id)
			landmark_ids[portal_id] = true
			if FileAccess.file_exists(texture_path):
				var digest := FileAccess.get_sha256(texture_path)
				_check(not asset_hashes.has(digest), "gateway has distinct landmark bitmap: " + portal_id)
				asset_hashes[digest] = portal_id
		if ResourceLoader.exists(texture_path):
			var texture := load(texture_path) as Texture2D
			if texture != null:
				var image := texture.get_image()
				_check(image != null and image.get_pixel(0, 0).a < 0.1, "landmark exterior is transparent: " + id)
	_require(layered_count >= 16, "sixteen gateway landmarks use independent collision/depth objects")
	for portal_id in EXPECTED_ROUTES.keys():
		_require(landmark_ids.has(portal_id), "gateway owns a separate landmark: " + portal_id)


func _audit_land_connections(scene: SceneScript, field: Node) -> void:
	## A 12-pixel mesh finds the single traversable region without trusting only
	## authored probe points. Each visited cell uses the real 10x6px foot ellipse.
	const STEP := 12
	var width := int(ceil(float(WORLD_SIZE.x) / STEP))
	var height := int(ceil(float(WORLD_SIZE.y) / STEP))
	var total := width * height
	var passable := PackedByteArray()
	passable.resize(total)
	for row in range(height):
		for col in range(width):
			var point := Vector2((float(col) + 0.5) * STEP / WORLD_SIZE.x, (float(row) + 0.5) * STEP / WORLD_SIZE.y)
			if field.call("_spawn_has_foot_clearance", scene, point):
				passable[row * width + col] = 1
	var seed: Vector2 = scene.player_spawn
	_check(field.call("_spawn_has_foot_clearance", scene, seed), "staging spawn has full foot clearance")
	var start := _nearest_passable_cell(passable, width, height, seed, STEP)
	_check(start >= 0, "staging spawn enters a sampled road component")
	if start < 0:
		return
	var visited := PackedByteArray()
	visited.resize(total)
	var queue := PackedInt32Array()
	queue.resize(total)
	var head := 0
	var tail := 1
	queue[0] = start
	visited[start] = 1
	while head < tail:
		var at := queue[head]
		head += 1
		var col := at % width
		var row := int(at / width)
		for next in [at - 1, at + 1, at - width, at + width]:
			if next < 0 or next >= total:
				continue
			if abs((next % width) - col) + abs(int(next / width) - row) != 1:
				continue
			if passable[next] == 1 and visited[next] == 0:
				visited[next] = 1
				queue[tail] = next
				tail += 1
	_check(tail > 500, "open world has a substantial reachable road/plain component")
	for raw in scene.map_layout.portals:
		var portal: Dictionary = raw
		var id := String(portal.get("id", ""))
		var index := _nearest_passable_cell(visited, width, height, portal.get("pos", Vector2.ZERO), STEP)
		_check(index >= 0, "road network reaches gateway " + id)

	var seam_segments := 0
	var blocked_seam_segments := 0
	for boundary_col in [1, 2]:
		for tile_row in range(3):
			var connected := false
			var blocked := false
			var left_col := int((float(boundary_col * TILE_SIZE.x) - float(STEP) * 0.5) / float(STEP))
			for y in range(tile_row * TILE_SIZE.y + STEP, (tile_row + 1) * TILE_SIZE.y - STEP, STEP):
				var left := Vector2(float(boundary_col * TILE_SIZE.x - STEP) / WORLD_SIZE.x, float(y) / WORLD_SIZE.y)
				var right := Vector2(float(boundary_col * TILE_SIZE.x + STEP) / WORLD_SIZE.x, float(y) / WORLD_SIZE.y)
				var clear: bool = field.call("_spawn_has_foot_clearance", scene, left) and field.call("_spawn_has_foot_clearance", scene, right)
				if clear:
					var seam_row := clampi(int(float(y) / float(STEP)), 0, height - 1)
					var left_index := seam_row * width + left_col
					if visited[left_index] == 1 and visited[left_index + 1] == 1:
						connected = true
				else:
					blocked = true
			if connected:
				seam_segments += 1
				print("[SEAM] vertical boundary=%d row=%d clear" % [boundary_col, tile_row])
			if blocked:
				blocked_seam_segments += 1
	for boundary_row in [1, 2]:
		for tile_col in range(3):
			var connected := false
			var blocked := false
			var top_row := int((float(boundary_row * TILE_SIZE.y) - float(STEP) * 0.5) / float(STEP))
			for x in range(tile_col * TILE_SIZE.x + STEP, (tile_col + 1) * TILE_SIZE.x - STEP, STEP):
				var top := Vector2(float(x) / WORLD_SIZE.x, float(boundary_row * TILE_SIZE.y - STEP) / WORLD_SIZE.y)
				var bottom := Vector2(float(x) / WORLD_SIZE.x, float(boundary_row * TILE_SIZE.y + STEP) / WORLD_SIZE.y)
				var clear: bool = field.call("_spawn_has_foot_clearance", scene, top) and field.call("_spawn_has_foot_clearance", scene, bottom)
				if clear:
					var seam_col := clampi(int(float(x) / float(STEP)), 0, width - 1)
					var top_index := top_row * width + seam_col
					if visited[top_index] == 1 and visited[top_index + width] == 1:
						connected = true
				else:
					blocked = true
			if connected:
				seam_segments += 1
				print("[SEAM] horizontal boundary=%d col=%d clear" % [boundary_row, tile_col])
			if blocked:
				blocked_seam_segments += 1
	_check(seam_segments >= 6, "at least six tile-adjacency seams have full-foot crossings from the default-spawn component")
	_check(blocked_seam_segments >= 6, "non-road terrain remains blocked across at least six tile adjacencies")
	_audit_authored_seam_crossings(scene, field, visited, width, height, STEP)
	# These four points sit outside the visible bridge decks, on water beside
	# each crossing. Bridge-centre walkability is a pending visual approval, but
	# being able to step into the side water is always a gameplay failure.
	for water_side in [
		{"id": "north_bridge_left_water", "pos": Vector2(0.475, 0.665)},
		{"id": "north_bridge_right_water", "pos": Vector2(0.525, 0.665)},
		{"id": "west_bridge_upper_water", "pos": Vector2(0.333, 0.775)},
		{"id": "west_bridge_lower_water", "pos": Vector2(0.333, 0.840)},
	]:
		_check(not field.call("_spawn_has_foot_clearance", scene, water_side["pos"]), "bridge-side water rejects a full actor foot: " + String(water_side["id"]))
	_audit_bridge_side_water_and_banks(scene, field, visited, width, height, STEP)
	var west_water_crossings := 0
	var west_crossing_ys: Array[int] = []
	for y in range(2 * TILE_SIZE.y + STEP, 3 * TILE_SIZE.y - STEP, STEP):
		var west := Vector2(float(TILE_SIZE.x - STEP) / WORLD_SIZE.x, float(y) / WORLD_SIZE.y)
		var east := Vector2(float(TILE_SIZE.x + STEP) / WORLD_SIZE.x, float(y) / WORLD_SIZE.y)
		if field.call("_spawn_has_foot_clearance", scene, west) and field.call("_spawn_has_foot_clearance", scene, east):
			west_water_crossings += 1
			west_crossing_ys.append(y)
			if west_water_crossings <= 4:
				print("[UNSURVEYED_WATER] r2c0-r2c1 y=%d" % y)
	print("[UNSURVEYED_WATER] r2c0-r2c1 clear_samples=%d" % west_water_crossings)
	var west_bridge := _bridge_meta(scene.map_layout, "east_west_stone_bridge")
	if String(west_bridge.get("validation_status", "")) == "APPROVED_VISUAL_QA":
		var center_y := (west_bridge.get("pos", Vector2.ZERO) as Vector2).y * WORLD_SIZE.y
		var half_height := (west_bridge.get("render_size_px", Vector2.ZERO) as Vector2).y * 0.5
		var outside := 0
		for crossing_y in west_crossing_ys:
			if absf(float(crossing_y) - center_y) > half_height:
				outside += 1
		_check(west_water_crossings >= 3 and outside == 0, "approved east-west bridge confines foot crossings to its visible deck")
		_check_approved_bridge_ends(west_bridge, true, scene, field, visited, width, height, STEP)
	else:
		_require(false, "east-west bridge centre has %d foot crossings but awaits visual deck/bank approval" % west_water_crossings)
	var north_water_crossings := 0
	var north_crossing_xs: Array[int] = []
	for x in range(TILE_SIZE.x + STEP, 2 * TILE_SIZE.x - STEP, STEP):
		var north := Vector2(float(x) / WORLD_SIZE.x, float(2 * TILE_SIZE.y - STEP) / WORLD_SIZE.y)
		var south := Vector2(float(x) / WORLD_SIZE.x, float(2 * TILE_SIZE.y + STEP) / WORLD_SIZE.y)
		if field.call("_spawn_has_foot_clearance", scene, north) and field.call("_spawn_has_foot_clearance", scene, south):
			north_water_crossings += 1
			north_crossing_xs.append(x)
			if north_water_crossings <= 4:
				print("[UNSURVEYED_WATER] r1c1-r2c1 x=%d" % x)
	print("[UNSURVEYED_WATER] r1c1-r2c1 clear_samples=%d" % north_water_crossings)
	var north_bridge := _bridge_meta(scene.map_layout, "north_south_stone_bridge")
	if String(north_bridge.get("validation_status", "")) == "APPROVED_VISUAL_QA":
		var center_x := (north_bridge.get("pos", Vector2.ZERO) as Vector2).x * WORLD_SIZE.x
		var half_width := (north_bridge.get("render_size_px", Vector2.ZERO) as Vector2).x * 0.5
		var outside := 0
		for crossing_x in north_crossing_xs:
			if absf(float(crossing_x) - center_x) > half_width:
				outside += 1
		_check(north_water_crossings >= 3 and outside == 0, "approved north-south bridge confines foot crossings to its visible deck")
		_check_approved_bridge_ends(north_bridge, false, scene, field, visited, width, height, STEP)
	else:
		_require(false, "north-south bridge centre has %d foot crossings but awaits visual deck/bank approval" % north_water_crossings)
	for boundary_col in [1, 2]:
		var blocked_north := false
		for y in range(64, 512, STEP):
			var left := Vector2(float(boundary_col * TILE_SIZE.x - STEP) / WORLD_SIZE.x, float(y) / WORLD_SIZE.y)
			var right := Vector2(float(boundary_col * TILE_SIZE.x + STEP) / WORLD_SIZE.x, float(y) / WORLD_SIZE.y)
			if not field.call("_spawn_has_foot_clearance", scene, left) and not field.call("_spawn_has_foot_clearance", scene, right):
				blocked_north = true
				break
		_check(blocked_north, "north snow/ridge/mist seam has impassable mountain samples at boundary %d" % boundary_col)


func _bridge_meta(layout: WalkableMapLayout, bridge_id: String) -> Dictionary:
	for raw in layout.visual_objects:
		if raw is Dictionary and String((raw as Dictionary).get("id", "")) == bridge_id:
			return raw as Dictionary
	return {}


func _audit_authored_seam_crossings(scene: SceneScript, field: Node, visited: PackedByteArray, width: int, height: int, step: int) -> void:
	var probes := scene.map_layout.seam_crossing_probes
	_require(probes.size() == 8, "eight authored cross-tile foot corridors are documented")
	var seen: Dictionary = {}
	for raw in probes:
		var probe: Dictionary = raw
		var id := String(probe.get("id", ""))
		_check(not id.is_empty() and not seen.has(id), "cross-tile corridor has a unique ID: " + id)
		seen[id] = true
		for end in ["from_pos", "to_pos"]:
			var pos: Vector2 = probe.get(end, Vector2(-1, -1))
			_check(field.call("_spawn_has_foot_clearance", scene, pos), "%s %s admits the complete actor foot" % [id, end])
			_check(_nearest_passable_cell(visited, width, height, pos, step) >= 0, "%s %s joins the default-spawn component" % [id, end])
		_require(String(probe.get("status", "")) == "APPROVED_VISUAL_QA", "seam %s terrain/overlay/foot alignment awaits normal-camera screenshot approval" % id)
	# Four named negative seams stay blocked even when a nearby crossing works.
	for no_cross in [
		{"id": "snowline_north_forbidden", "a": Vector2(0.331, 0.050), "b": Vector2(0.336, 0.050)},
		{"id": "mist_ridge_north_forbidden", "a": Vector2(0.664, 0.105), "b": Vector2(0.669, 0.105)},
		{"id": "jiangnan_bridge_west_water_forbidden", "a": Vector2(0.480, 0.663), "b": Vector2(0.480, 0.670)},
		{"id": "jiangnan_bridge_east_water_forbidden", "a": Vector2(0.515, 0.663), "b": Vector2(0.515, 0.670)},
	]:
		var left: Vector2 = no_cross["a"]
		var right: Vector2 = no_cross["b"]
		_check(not field.call("_spawn_has_foot_clearance", scene, left) and not field.call("_spawn_has_foot_clearance", scene, right), "forbidden seam has no full-foot crossing: " + String(no_cross["id"]))


func _audit_bridge_side_water_and_banks(scene: SceneScript, field: Node, visited: PackedByteArray, width: int, height: int, step: int) -> void:
	for bridge_case in [
		{"id": "north_south_stone_bridge", "east_west": false, "banks": [Vector2(0.499132, 0.643880), Vector2(0.499132, 0.689453)]},
		{"id": "east_west_stone_bridge", "east_west": true, "banks": [Vector2(0.321181, 0.813802), Vector2(0.345486, 0.813802)]},
	]:
		var id := String(bridge_case["id"])
		var bridge := _bridge_meta(scene.map_layout, id)
		_check(not bridge.is_empty(), "bridge artwork is placed: " + id)
		if bridge.is_empty():
			continue
		var center: Vector2 = bridge.get("pos", Vector2.ZERO) * Vector2(WORLD_SIZE)
		var size: Vector2 = bridge.get("render_size_px", Vector2.ZERO)
		var east_west: bool = bridge_case["east_west"]
		var cross_half := (size.y if east_west else size.x) * 0.5
		for sign in [-1.0, 1.0]:
			for outside_px in [16.0, 32.0]:
				var pixel := center + (Vector2(0.0, sign * (cross_half + outside_px)) if east_west else Vector2(sign * (cross_half + outside_px), 0.0))
				var pos := pixel / Vector2(WORLD_SIZE)
				_check(not field.call("_spawn_has_foot_clearance", scene, pos), "%s side water remains blocked %dpx beyond visible deck (%s)" % [id, int(outside_px), "negative" if sign < 0.0 else "positive"])
		for bank_index in range(2):
			var bank: Vector2 = bridge_case["banks"][bank_index]
			_check(field.call("_spawn_has_foot_clearance", scene, bank), "%s dry bank %d has complete foot clearance" % [id, bank_index])
			_check(_nearest_passable_cell(visited, width, height, bank, step) >= 0, "%s dry bank %d joins the default-spawn component" % [id, bank_index])


func _check_approved_bridge_ends(bridge: Dictionary, east_west: bool, scene: SceneScript, field: Node, visited: PackedByteArray, width: int, height: int, step: int) -> void:
	var center: Vector2 = bridge.get("pos", Vector2.ZERO) * Vector2(WORLD_SIZE)
	var size: Vector2 = bridge.get("render_size_px", Vector2.ZERO)
	var axis_half := (size.x if east_west else size.y) * 0.5 + 16.0
	for side in [-1.0, 1.0]:
		var pixel := center + (Vector2(side * axis_half, 0.0) if east_west else Vector2(0.0, side * axis_half))
		var point := pixel / Vector2(WORLD_SIZE)
		var label := ("west" if side < 0.0 else "east") if east_west else ("north" if side < 0.0 else "south")
		_check(field.call("_spawn_has_foot_clearance", scene, point), "approved bridge %s landward foot is clear: %s" % [String(bridge.get("id", "")), label])
		_check(_nearest_passable_cell(visited, width, height, point, step) >= 0, "approved bridge %s landward foot joins world road: %s" % [String(bridge.get("id", "")), label])


func _audit_pixel_seams(image: Image) -> void:
	if image == null or image.is_empty() or image.get_size() != WORLD_SIZE:
		return
	## This detects empty/transparent tile joins. RGB discontinuity is printed as
	## evidence for visual review, not thresholded: snow-to-rock can legitimately
	## change color abruptly at an intentionally blocked mountain boundary.
	for boundary_col in [1, 2]:
		for tile_row in range(3):
			var x: int = boundary_col * TILE_SIZE.x
			var gaps := 0
			var total_delta := 0.0
			var samples := 0
			for y in range(tile_row * TILE_SIZE.y, (tile_row + 1) * TILE_SIZE.y, 4):
				var a := image.get_pixel(x - 1, y)
				var b := image.get_pixel(x, y)
				if a.a < 0.95 or b.a < 0.95:
					gaps += 1
				total_delta += (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) / 3.0
				samples += 1
			_check(gaps == 0, "vertical tile seam has no transparent pixel gap c%d/r%d" % [boundary_col, tile_row])
			print("[SEAM_PIXELS] v c%d/r%d mean_rgb_delta=%.4f" % [boundary_col, tile_row, total_delta / maxf(1.0, float(samples))])
	for boundary_row in [1, 2]:
		for tile_col in range(3):
			var y: int = boundary_row * TILE_SIZE.y
			var gaps := 0
			var total_delta := 0.0
			var samples := 0
			for x in range(tile_col * TILE_SIZE.x, (tile_col + 1) * TILE_SIZE.x, 4):
				var a := image.get_pixel(x, y - 1)
				var b := image.get_pixel(x, y)
				if a.a < 0.95 or b.a < 0.95:
					gaps += 1
				total_delta += (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) / 3.0
				samples += 1
			_check(gaps == 0, "horizontal tile seam has no transparent pixel gap r%d/c%d" % [boundary_row, tile_col])
			print("[SEAM_PIXELS] h r%d/c%d mean_rgb_delta=%.4f" % [boundary_row, tile_col, total_delta / maxf(1.0, float(samples))])


func _nearest_passable_cell(bitmap: PackedByteArray, width: int, height: int, normalized: Vector2, step: int) -> int:
	var cx := clampi(int(normalized.x * WORLD_SIZE.x / step), 0, width - 1)
	var cy := clampi(int(normalized.y * WORLD_SIZE.y / step), 0, height - 1)
	for radius in range(4):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var x := cx + dx
				var y := cy + dy
				if x >= 0 and x < width and y >= 0 and y < height:
					var index := y * width + x
					if bitmap[index] == 1:
						return index
	return -1


func _pending_note(message: String) -> void:
	_pending += 1
	print("[PENDING] " + message)


func _require(ok: bool, message: String) -> void:
	if ok:
		_check(true, message)
	elif _strict:
		_check(false, message)
	else:
		_pending_note(message)


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("[PASS] " + message)
	else:
		_failures += 1
		push_error("[FAIL] " + message)


func _finish() -> void:
	print("[WorldMapV13Staging] checks=%d failed=%d pending=%d" % [_checks, _failures, _pending])
	quit(1 if _failures > 0 else 0)
