extends "res://scripts/dev/run_world_native_pair_landmark_v9.gd"

var failures := 0
var checks := 0
var route_probes := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[WorldLandmarkV9 FAIL] " + message)


func _save_snapshot() -> Dictionary:
	var result := {}
	var saves := root.get_node("SaveManager")
	for slot in range(5):
		for path: String in [saves.slot_path(slot), saves.slot_backup_path(slot)]:
			result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	return result


func _walks(point: Vector2) -> bool:
	return bool(field.call("_is_inside_walkable_screen", field.world_container.to_global(point)))


func _foot_clear(point: Vector2) -> bool:
	return bool(field.call("_spawn_has_foot_clearance", field._current_scene, point / Vector2(field._world_size)))


func _run_tests() -> void:
	var saves_before := _save_snapshot()
	var flags_before: Dictionary = root.get_node("GameState").flags.duplicate(true)
	if not await start_preview():
		return
	_check(field._world_size == CONTRACT.WORLD_SIZE, "native 3072x1024 world preserves geometry")
	_check(field._current_scene.scene_id == CONTRACT.LAB_ID, "runtime-only lab is active")
	_check(field._current_scene.on_enter_dialog == null and field._current_scene.npcs.is_empty(), "no plot or reward NPCs in preview")
	var routes := CONTRACT.route_points()
	_check(routes.size() >= 90, "projected source route has enough samples")
	_check(not routes.is_empty() and routes[-1].distance_to(CONTRACT.FERRY_SPUR[0]) < 0.01, "main road ends exactly at ferry spur start without an unsampled tail")
	for index in range(1, routes.size()):
		var start: Vector2 = routes[index - 1]
		var finish: Vector2 = routes[index]
		var steps := maxi(1, ceili(start.distance_to(finish) / 4.0))
		for step in range(steps + 1):
			var foot := start.lerp(finish, float(step) / steps)
			_check(_walks(foot) and _foot_clear(foot), "continuous main road clears full foot at %s" % foot)
			route_probes += 1
	for spur in [CONTRACT.CITY_SPUR, CONTRACT.FERRY_SPUR]:
		var from: Vector2 = spur[0]
		var to: Vector2 = spur[1]
		var count := maxi(1, ceili(from.distance_to(to) / 4.0))
		for index in range(count + 1):
			var foot := from.lerp(to, float(index) / count)
			_check(_walks(foot) and _foot_clear(foot), "landmark spur clears full foot at %s" % foot)
	_surface_support_checks()
	_terrain_boundary_checks()
	_slope_semantics_checks()
	_dock_support_checks()
	_dock_foreground_exclusion_checks()
	_inherited_prop_land_checks()
	# Explicit bridge deck exception: water on both sides, real rails do not open.
	for x in range(1425, 1896, 10):
		_check(_walks(Vector2(x, 365)) and _foot_clear(Vector2(x, 365)), "deck traversable x=%d" % x)
	# Current measured slope witnesses follow v9 relief; water/rails remain strict.
	for foot in [Vector2(1660, 325), Vector2(1660, 398), Vector2(1660, 295), Vector2(1660, 440), Vector2(2900, 650), Vector2(2600, 900)]:
		_check(not _walks(foot), "rail/water negative blocked at %s" % foot)
	for blocker in CONTRACT.blockers():
		var foot: Vector2 = blocker["pos"] * CONTRACT.WORLD_SIZE
		_check(not _walks(foot), "paired independent blocker: " + String(blocker["id"]))
	for landmark in CONTRACT.landmarks():
		_check(_walks(landmark["entry"]) and _foot_clear(landmark["entry"]), "landward entry full foot: " + String(landmark["id"]))
	_depth_checks()
	_rail_part_depth_checks()
	await _movement_checks()
	await _dock_movement_checks()
	await _capture("city", Vector2(900, 390))
	await _capture("bridge", Vector2(1660, 365))
	for station in [{"label": "bridge_front", "foot": Vector2(1660, 376)}, {"label": "bridge_back", "foot": Vector2(1660, 355)}]:
		_check(_foot_clear(station["foot"]), "bridge screenshot station preserves full foot: " + String(station["label"]))
		await _capture(station["label"], station["foot"])
	await _capture("dock", CONTRACT.DOCK_ROUTE[-1])
	await _capture("dock_side", Vector2(2435, 640))
	field._player.set_walk_direction(Vector2.RIGHT, false)
	await _capture("dock_middle_front", Vector2(2435,686))
	await _capture("ferry", CONTRACT.landmarks()[1]["entry"])
	await _gateway_checks()
	field._open_system_menu()
	field._open_save_slot_panel()
	_check(field._system_ui_canvas_layer.get_node_or_null("SystemMenu") == null, "preview cannot open save-capable menu")
	_check(String(root.get_node("SceneRouter").get_current_field_id()).is_empty(), "preview never registers a saveable current field")
	if String(root.get_node("SceneRouter").get_current_field_id()).is_empty():
		_check(not root.get_node("PlatformBridge").request_checkpoint_save(), "platform lifecycle checkpoint refuses unsaveable preview")
	_check(_save_snapshot() == saves_before, "all five user saves and backups unchanged")
	_check(root.get_node("GameState").flags == flags_before, "no plot/quest flags emitted")
	restore_preview_state()
	_check(root.get_node("SceneRouter").get_navigation_state() == navigation_before, "runtime Router navigation restored")
	print("[WorldLandmarkV9] checks=%d failures=%d continuous_main_road=%d; isolated, shipping map unchanged" % [checks, failures, route_probes])
	quit(0 if failures == 0 else 1)


func _surface_support_checks() -> void:
	var walk := _read_png(CONTRACT.PREFIX + "walk.png")
	var land := _read_png(CONTRACT.PREFIX + "land.png")
	_check(walk != null and land != null and walk.get_size() == Vector2i(CONTRACT.WORLD_SIZE) and land.get_size() == walk.get_size(), "same-camera land/navigation native sizes")
	if walk == null or land == null:
		return
	for family in [{"full": "visual", "left": "center", "right": "coast"}, {"full": "walk", "left": "center_walk", "right": "coast_walk"},
		{"full": "land", "left": "center_land", "right": "coast_land"}]:
		var source := _read_png(CONTRACT.PREFIX + String(family["full"]) + ".png")
		var left := _read_png(CONTRACT.PREFIX + String(family["left"]) + ".png")
		var right := _read_png(CONTRACT.PREFIX + String(family["right"]) + ".png")
		var matched := source != null and left != null and right != null
		matched = matched and source.get_size() == Vector2i(3072, 1024) and left.get_size() == Vector2i(1536,1024) and right.get_size() == left.get_size()
		if matched:
			# Raw pixels, not just a sampling grid: both region images are exact crops.
			matched = left.get_data() == source.get_region(Rect2i(0, 0, 1536, 1024)).get_data()
			matched = matched and right.get_data() == source.get_region(Rect2i(1536, 0, 1536, 1024)).get_data()
		_check(matched, "same-camera region crops exact all pixels: " + String(family["full"]))
	var invalid := 0
	var declared_deck := 0
	for y in range(0, walk.get_height(), 4):
		for x in range(0, walk.get_width(), 4):
			var pixel := Vector2(x, y)
			if walk.get_pixel(x, y).r > 0.5 and land.get_pixel(x, y).r < 0.5:
				if _structure_supports(pixel):
					declared_deck += 1
				else:
					invalid += 1
	_check(invalid == 0, "navigation never opens water outside declared bridge/dock decks (%d invalid)" % invalid)
	_check(declared_deck > 0, "structural bridge is explicitly allowed above river, not mislabeled natural land")


func _read_png(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	return image if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK else null


func _inherited_prop_land_checks() -> void:
	var land := _read_png(CONTRACT.PREFIX + "land.png")
	_check(land != null, "land mask available for inherited physical bases")
	if land == null:
		return
	var audited := 0
	for object in CONTRACT.scene_objects():
		if not object.has("collision_size"):
			continue
		audited += 1
		var center: Vector2 = (object["pos"] + object["collision_offset"]) * CONTRACT.WORLD_SIZE
		var size: Vector2 = object["collision_size"] * CONTRACT.WORLD_SIZE
		var base := Rect2(center - size * 0.5, size)
		var x_steps := ceili(size.x / 4.0)
		var y_steps := ceili(size.y / 4.0)
		var invalid := 0
		for yi in range(y_steps + 1):
			for xi in range(x_steps + 1):
				var pixel := Vector2i(base.position + Vector2(size.x * xi / x_steps, size.y * yi / y_steps))
				if pixel.x < 0 or pixel.y < 0 or pixel.x >= land.get_width() or pixel.y >= land.get_height() or land.get_pixelv(pixel).r < 0.5:
					invalid += 1
		_check(invalid == 0, "inherited full base rests on land: %s (%d water/out-of-bounds samples)" % [object["id"], invalid])
	_check(audited == 13, "all thirteen inherited paired object bases audited")


func _depth_checks() -> void:
	var player: Player = field._player
	for pair in [{"id": "lab_luoyang", "foot": CONTRACT.CITY_FOOT}, {"id": "lab_ferry_pavilion_foreground", "foot": Vector2(2420,625)},
		{"id": "lab_bridge_front_rail", "foot": Vector2(1660, 408)}]:
		var visual := field._actor_layer.get_node_or_null("SceneObject_" + String(pair["id"])) as Sprite2D
		_check(visual != null, "independent depth sprite exists: " + String(pair["id"]))
		if visual != null:
			player.position = pair["foot"] + Vector2(0, -72)
			player.refresh_depth_sort()
			_check(player.z_index < visual.z_index, "actor behind foreground: " + String(pair["id"]))
			player.position = pair["foot"] + Vector2(0, 72)
			player.refresh_depth_sort()
			_check(player.z_index > visual.z_index, "actor in front of foreground: " + String(pair["id"]))
	var deck := field._visual_layer.get_node_or_null("SceneObject_lab_bridge_deck") as Sprite2D
	_check(deck != null and deck.z_index < 0, "whole bridge deck is below actors, not whole-image foreground")
	var dock := field._visual_layer.get_node_or_null("SceneObject_lab_bailu") as Sprite2D
	_check(dock != null and dock.z_index < 0, "whole dock floor is below actors, not whole-image foreground")


func _movement_checks() -> void:
	var player: Player = field._player
	player.position = Vector2(1410, 365)
	player.refresh_depth_sort()
	Input.action_press("move_right")
	for tick in range(78):
		await physics_frame
	Input.action_release("move_right")
	await physics_frame
	_check(player.position.x > 1900 and absf(player.position.y - 365) < 2, "actual physics input crosses bridge west to east: %s" % player.position)
	Input.action_press("move_left")
	for tick in range(78):
		await physics_frame
	Input.action_release("move_left")
	await physics_frame
	_check(player.position.x < 1430 and absf(player.position.y - 365) < 2, "actual physics input returns east to west: %s" % player.position)
	player.position = Vector2(1660, 365)
	Input.action_press("move_down")
	for tick in range(24):
		await physics_frame
	Input.action_release("move_down")
	await physics_frame
	_check(player.position.y < 390, "front rail/deck boundary blocks actual downward motion")


func _capture(label: String, position: Vector2) -> void:
	var player: Player = field._player
	player.position = position
	player.refresh_depth_sort()
	field._snap_camera_to_player()
	for tick in range(10):
		await process_frame
	if DisplayServer.get_name() != "headless":
		var image := root.get_texture().get_image()
		_check(image != null and image.get_size() == Vector2i(1920, 1080), "runtime capture uses physical 1920x1080 viewport: " + label)
		_check(image != null and image.save_png("res://build/world_native_pair_landmark_v9_" + label + ".png") == OK, "1920 runtime capture: " + label)


func _gateway_checks() -> void:
	for landmark in CONTRACT.landmarks():
		var expected_anchor: Vector2 = landmark["entry"] / CONTRACT.WORLD_SIZE
		var player: Player = field._player
		player.position = landmark["entry"]
		field._snap_camera_to_player()
		for tick in range(10):
			await process_frame
		for tick in range(5):
			await physics_frame
		var zone: ExitZone = null
		for candidate: ExitZone in field._exit_nodes:
			if candidate.target_scene_id == String(landmark["target_scene"]):
				zone = candidate
		_check(zone != null and zone._in_range, "real portal range accepts outside stand point")
		var interactions := [0]
		if landmark["kind"] == "city":
			player.interacted.connect(func(): interactions[0] += 1)
			var key := InputEventKey.new()
			key.keycode = KEY_SPACE
			key.physical_keycode = KEY_SPACE
			key.pressed = true
			Input.parse_input_event(key)
			Input.flush_buffered_events()
			await process_frame
			key = InputEventKey.new()
			key.keycode = KEY_SPACE
			key.physical_keycode = KEY_SPACE
			key.pressed = false
			Input.parse_input_event(key)
			Input.flush_buffered_events()
		else:
			var dispatch_before: int = field.pointer_dispatch_count
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = zone.marker_visual.get_global_transform_with_canvas().origin
			click.global_position = click.position
			var click_point := click.position
			click.pressed = true
			Input.parse_input_event(click)
			Input.flush_buffered_events()
			await process_frame
			click = InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = click_point
			click.global_position = click_point
			click.pressed = false
			Input.parse_input_event(click)
			Input.flush_buffered_events()
			for tick in range(8):
				await process_frame
			_check(field.pointer_dispatch_count > dispatch_before, "real pointer reaches isolated Field dispatch")
		for tick in range(12):
			await process_frame
		if landmark["kind"] == "city":
			_check(interactions[0] > 0, "Space input dispatched to real Player.interacted")
		_check(field._current_scene.scene_id == landmark["target_scene"], "existing destination art loaded in runtime copy: " + String(landmark["id"]))
		_check(return_anchor.distance_to(expected_anchor) < 0.0001, "source doorway anchor preserved exactly: " + String(landmark["id"]))
		player = field._player
		_check(_foot_clear(player.position), "destination spawn has complete foot clearance")
		_check(field._current_scene.npcs.is_empty() and field._current_scene.on_enter_dialog == null and field._current_scene.map_layout.interactions.is_empty(), "destination preview cannot issue plot/rewards")
		await _capture(String(landmark["kind"]) + "_arrival", player.position)
		for tick in range(5):
			await physics_frame
		_check(field._exit_nodes.size() == 1 and field._exit_nodes[0].try_interact(), "real return interaction activates")
		for tick in range(12):
			await process_frame
		_check(field._current_scene.scene_id == CONTRACT.LAB_ID, "returns to exact runtime lab")
		_check(field._player.position.distance_to(landmark["entry"]) < 0.01, "returns at same outside doorway, not nearest-road repair")



func _terrain_boundary_checks() -> void:
	var land := _read_png(CONTRACT.PREFIX + "land.png")
	var walk := _read_png(CONTRACT.PREFIX + "walk.png")
	var old_land := _read_png("res://build/world_native_pair_ortho_v8_land.png")
	var topology := _read_png(CONTRACT.PREFIX + "topology.png")
	var visual := _read_png(CONTRACT.PREFIX + "visual.png")
	_check(land != null and walk != null and old_land != null and topology != null and visual != null, "v9 source topology/visual/land/walk and v8 boundary evidence available")
	if land == null or walk == null or old_land == null or topology == null or visual == null:
		return
	var bad_river_land := 0
	var bad_river_walk := 0
	var bad_river_topology := 0
	var bad_river_visual := 0
	var river_witnesses := 0
	for y in range(0, 1024):
		var river := CONTRACT.river_x(y)
		var half_width := CONTRACT.river_half_width(y)
		for fraction in [0.0, -0.3, 0.3, -0.75, 0.75]:
			river_witnesses += 1
			var pixel := Vector2i(roundi(river + half_width * fraction), y)
			if land.get_pixelv(pixel).r > 0.5:
				bad_river_land += 1
			if topology.get_pixelv(pixel).r > 0.5:
				bad_river_topology += 1
			var color := visual.get_pixelv(pixel)
			if color.b <= color.r + 0.02:
				bad_river_visual += 1
			if walk.get_pixelv(pixel).r > 0.5 and not _structure_supports(Vector2(pixel)):
				bad_river_walk += 1
	_check(bad_river_land == 0, "authored river remains natural water along every-row variable-width center/bank witnesses")
	_check(bad_river_walk == 0, "authored river remains blocked except declared structural bridge/dock")
	_check(bad_river_topology == 0, "actual source topology independently contains curved variable-width river")
	_check(bad_river_visual == 0, "rendered source river pixels visibly retain blue-green water rather than land (%d mismatches)" % bad_river_visual)
	var added_land := 0
	var removed_land := 0
	for y in range(0, 1024, 4):
		for x in range(0, 3072, 4):
			var before := old_land.get_pixel(x, y).r > 0.5
			var after := land.get_pixel(x, y).r > 0.5
			if after and not before:
				added_land += 1
			elif before and not after:
				removed_land += 1
	print("[WorldLandmarkV9 boundary] river_witnesses=%d bad_river_land=%d bad_river_walk=%d; 4px lattice added_land=%d removed_land=%d; route/base/coast contracts tested independently" % [river_witnesses, bad_river_land, bad_river_walk, added_land, removed_land])


func _slope_semantics_checks() -> void:
	var metadata: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT.PREFIX + "art.json"))
	var walk := _read_png(CONTRACT.PREFIX + "walk.png")
	var land := _read_png(CONTRACT.PREFIX + "land.png")
	_check(metadata is Dictionary and walk != null and land != null, "current art metadata and same-camera slope masks available")
	if not metadata is Dictionary or walk == null or land == null:
		return
	var gentle: Array = metadata.get("gentle_examples", [])
	_check(gentle.size() >= 2, "current geography supplies explicit gentle land witnesses")
	for probe in gentle:
		var coords: Array = probe.get("projected_point", []) if probe is Dictionary else probe
		var foot := Vector2(coords[0], coords[1])
		var pixel := Vector2i(foot.round())
		if probe is Dictionary:
			_check(float(probe["world_gradient"]) < 0.72, "gentle witness is below unchanged physical threshold at %s" % foot)
		_check(land.get_pixelv(pixel).r > 0.5 and walk.get_pixelv(pixel).r > 0.5 and _walks(foot) and _foot_clear(foot), "current gentle witness rests on natural land with complete foot at %s" % foot)
	var examples: Array = metadata.get("steep_examples", [])
	_check(examples.size() >= 12, "new relief supplies twelve actual steep source/projected witnesses")
	for example in examples:
		var point := Vector2(example["projected_point"][0], example["projected_point"][1])
		var pixel := Vector2i(point.round())
		_check(float(example["world_gradient"]) > 0.72, "new slope exceeds unchanged physical threshold at %s" % point)
		_check(land.get_pixelv(pixel).r > 0.5 and walk.get_pixelv(pixel).r < 0.5 and not _walks(point), "actual projected steep land rejects Field movement at %s" % point)



func _structure_supports(point: Vector2) -> bool:
	if CONTRACT.BRIDGE_DECK.has_point(point):
		return true
	for deck: Rect2 in CONTRACT.DOCK_DECKS:
		if deck.has_point(point):
			return true
	return false


func _rectangle_support(rect: Rect2, land: Image, walk: Image, wants_land: bool, label: String) -> void:
	var steps_x := ceili(rect.size.x / 4.0)
	var steps_y := ceili(rect.size.y / 4.0)
	var wrong := 0
	for y in range(steps_y + 1):
		for x in range(steps_x + 1):
			var pixel := Vector2i((rect.position + rect.size * Vector2(float(x) / steps_x, float(y) / steps_y)).round())
			var supported := land.get_pixelv(pixel).r > 0.5
			if supported != wants_land or (not wants_land and walk.get_pixelv(pixel).r > 0.5):
				wrong += 1
	_check(wrong == 0, "%s full 4px base including edges (%d incorrect pixels)" % [label, wrong])


func _dock_alpha_support(foot: Vector2, dock: Sprite2D, image: Image) -> bool:
	var local := dock.to_local(field.world_container.to_global(foot))
	var rect := dock.get_rect()
	var uv := (local - rect.position) / rect.size
	if uv.x < 0.0 or uv.y < 0.0 or uv.x >= 1.0 or uv.y >= 1.0:
		return false
	return image.get_pixelv(Vector2i(uv * Vector2(image.get_size()))).a > 0.5


func _dock_full_foot_alpha_support(foot: Vector2, dock: Sprite2D, image: Image, land: Image) -> bool:
	for index in range(17):
		var point := foot
		if index < 16:
			var angle := TAU * float(index) / 16.0
			point += Vector2(cos(angle) * 10.0, sin(angle) * 6.0)
		if land.get_pixelv(Vector2i(point.round())).r < 0.5 and not _dock_alpha_support(point, dock, image):
			return false
	return true


func _dock_support_checks() -> void:
	var land := _read_png(CONTRACT.PREFIX + "land.png")
	var walk := _read_png(CONTRACT.PREFIX + "walk.png")
	_check(land != null and walk != null, "dock needs same-camera natural-land/navigation evidence")
	if land == null or walk == null:
		return
	_rectangle_support(CONTRACT.PAVILION_FOUNDATION, land, walk, true, "pavilion foundation stays on natural land")
	_rectangle_support(CONTRACT.DOCK_APPROACH, land, walk, true, "stone/soil dock approach stays on natural land without structural exemption")
	_rectangle_support(CONTRACT.SHIP_WATER, land, walk, false, "ship hull lies over real blocked water")
	var topology := _read_png(CONTRACT.PREFIX + "topology.png")
	var visual := _read_png(CONTRACT.PREFIX + "visual.png")
	var ship_center := Vector2i(CONTRACT.SHIP_WATER.get_center().round())
	_check(topology != null and topology.get_pixelv(ship_center).r < 0.5 and visual != null and visual.get_pixelv(ship_center).b > visual.get_pixelv(ship_center).r + 0.02, "harbor is actual source-topology and rendered water below ship, not merely navigation paint")
	var dock := field._visual_layer.get_node_or_null("SceneObject_lab_bailu") as Sprite2D
	_check(dock != null and dock.texture != null, "dock actual floor sprite is loaded")
	if dock == null or dock.texture == null:
		return
	var alpha := dock.texture.get_image()
	var masks: Array[Image] = []
	for filename in ["ferry_pavilion_foreground.png", "ferry_near_rail.png"]:
		var mask := _read_png(CONTRACT.PREFIX + filename)
		_check(mask != null and mask.get_size() == alpha.get_size() and ResourceLoader.exists(CONTRACT.PREFIX + filename), "readable imported foreground shares exact source canvas: " + filename)
		if mask != null:
			masks.append(mask)
	var water_supported := 0
	var samples := 0
	for index in range(1, CONTRACT.DOCK_ROUTE.size()):
		var from: Vector2 = CONTRACT.DOCK_ROUTE[index - 1]
		var to: Vector2 = CONTRACT.DOCK_ROUTE[index]
		var count := maxi(1, ceili(from.distance_to(to) / 4.0))
		for step in range(count + 1):
			var foot := from.lerp(to, float(step) / count)
			var pixel := Vector2i(foot.round())
			_check(_walks(foot) and _foot_clear(foot), "continuous real dock route clears full foot at %s" % foot)
			_check(_dock_alpha_support(foot, dock, alpha), "real dock sprite alpha supports route at %s" % foot)
			_check(_dock_full_foot_alpha_support(foot, dock, alpha, land), "real dock sprite alpha supports entire over-water foot at %s" % foot)
			for mask in masks:
				_check(not _dock_alpha_support(foot, dock, mask), "separate dock foreground excludes central walkable wooden floor at %s" % foot)
			if land.get_pixelv(pixel).r < 0.5:
				water_supported += 1
				_check(_structure_supports(foot), "only declared physical deck supports watery dock route")
			samples += 1
	_check(water_supported > 0, "real dock route actually spans water, not a dry-land prop masquerading as dock")
	for foot in [Vector2(2495,609), Vector2(2490,650), Vector2(2510,710)]:
		var pixel := Vector2i(foot)
		_check(land.get_pixelv(pixel).r < 0.5 and walk.get_pixelv(pixel).r < 0.5 and not _walks(foot), "water beside dock rejects full actor: %s" % foot)
	print("[WorldLandmarkV9 dock] route_samples=%d structurally_supported_water=%d" % [samples, water_supported])


func _footprint_foreground_free(foot: Vector2, dock: Sprite2D, mask: Image) -> bool:
	for index in range(17):
		var point := foot
		if index < 16:
			var angle := TAU * float(index) / 16.0
			point += Vector2(cos(angle) * 10.0, sin(angle) * 6.0)
		if _dock_alpha_support(point, dock, mask):
			return false
	return true


# Independently inspected in the ORIGINAL source image, not derived from the
# generated foreground/navigation: wood floors must never occlude footwear.
const VERIFIED_DOCK_FLOORS := [Rect2i(650,440,210,45), Rect2i(650,590,190,120), Rect2i(840,580,26,35)]
# These tiny source areas are actual north column roots and south post-cap
# edges. A legal actor may stand behind these entities, unlike a floor plank.
const VERIFIED_RAIL_ENTITY_PIXELS := [
	Vector2i(933,510),Vector2i(925,517),Vector2i(913,522),Vector2i(948,510),Vector2i(940,517),Vector2i(928,522),Vector2i(914,523),
	Vector2i(921,516),Vector2i(918,524),Vector2i(910,531),Vector2i(899,536),Vector2i(936,516),Vector2i(933,524),Vector2i(925,531),
	Vector2i(913,536),Vector2i(899,538),Vector2i(950,516),Vector2i(948,524),Vector2i(940,531),Vector2i(928,536),Vector2i(914,538),
	Vector2i(900,536),Vector2i(948,507),Vector2i(856,744),Vector2i(859,750),Vector2i(856,758),Vector2i(856,742),Vector2i(859,765),
	Vector2i(856,773),Vector2i(856,756),Vector2i(859,779),Vector2i(856,771)]


func _source_in_regions(pixel: Vector2i, regions: Array) -> bool:
	for region: Rect2i in regions:
		if region.has_point(pixel):
			return true
	return false


func _dock_foreground_exclusion_checks() -> void:
	var dock := field._visual_layer.get_node_or_null("SceneObject_lab_bailu") as Sprite2D
	_check(dock != null, "actual dock floor exists for legal side-foot foreground audit")
	if dock == null:
		return
	var known_side := Vector2(2435, 640)
	_check(_walks(known_side) and _foot_clear(known_side), "review side-foot witness remains fully legal without collision masking")
	for filename in ["ferry_pavilion_foreground.png", "ferry_near_rail.png"]:
		var mask := _read_png(CONTRACT.PREFIX + filename)
		_check(mask != null, "actual foreground pixels readable for side-foot audit: " + filename)
		if mask == null:
			continue
		_check(mask.get_used_rect().has_area(), "semantic foreground remains nonempty: " + filename)
		var entity_points: Array = [Vector2i(400,120), Vector2i(337,350)] if filename == "ferry_pavilion_foreground.png" else [Vector2i(900,720), Vector2i(462,844), Vector2i(920,850)]
		for pixel in entity_points:
			_check(mask.get_pixelv(pixel).a > 0.5, "semantic foreground retains actual roof/column/post/stone at source %s: %s" % [pixel, filename])
		var wooden_floor := Vector2i(666,458) if filename == "ferry_pavilion_foreground.png" else Vector2i(859,600)
		_check(mask.get_pixelv(wooden_floor).a < 0.5, "known real wooden floor source pixel is excluded, not covered: %s %s" % [wooden_floor,filename])
		for floor_region: Rect2i in VERIFIED_DOCK_FLOORS:
			var floor_hits := 0
			for y in range(floor_region.position.y, floor_region.end.y):
				for x in range(floor_region.position.x, floor_region.end.x):
					if mask.get_pixel(x,y).a > 0.5:
						floor_hits += 1
			_check(floor_hits == 0, "independently verified source wooden floor stays foreground-free: %s %s invalid=%d" % [filename,floor_region,floor_hits])
		_check(_footprint_foreground_free(known_side, dock, mask), "known legal side foot (2435,640) and its complete 16-point ellipse stay clear of " + filename)
		var legal_centers := 0
		var failures_on_floor := 0
		var verified_entity_centers := 0
		var verified_entity_pixels: Array[Vector2i] = []
		var examples: Array[String] = []
		for deck: Rect2 in CONTRACT.DOCK_DECKS:
			for y in range(int(deck.position.y), int(deck.end.y), 4):
				for x in range(int(deck.position.x), int(deck.end.x), 4):
					var foot := Vector2(x, y)
					if not _walks(foot) or not _foot_clear(foot):
						continue
					legal_centers += 1
					if not _footprint_foreground_free(foot, dock, mask):
						var hits: Array[String] = []
						for sample in range(17):
							var point := foot
							if sample < 16:
								var angle := TAU * float(sample) / 16.0
								point += Vector2(cos(angle) * 10.0, sin(angle) * 6.0)
							if _dock_alpha_support(point, dock, mask):
								var local := dock.to_local(field.world_container.to_global(point))
								var pixel := Vector2i((local - dock.get_rect().position) / dock.get_rect().size * Vector2(mask.get_size()))
								if filename != "ferry_near_rail.png" or _source_in_regions(pixel,VERIFIED_DOCK_FLOORS) or not pixel in VERIFIED_RAIL_ENTITY_PIXELS:
									hits.append(str(pixel))
								elif not pixel in verified_entity_pixels:
									verified_entity_pixels.append(pixel)
						if hits.is_empty():
							verified_entity_centers += 1
						else:
							failures_on_floor += 1
							if examples.size() < 8:
								examples.append("%s source=%s" % [foot,hits])
		_check(legal_centers >= 25, "side-foot audit covers complete-foot legal deck area, not only route centerline")
		_check(failures_on_floor == 0, "foreground excludes every legal 4px-grid full-foot wooden floor: %s invalid=%d first=%s" % [filename, failures_on_floor, examples])
		print("[WorldLandmarkV9 floor foreground] mask=%s legal_centers=%d failures=%d independently_verified_entity_overlap=%d" % [filename, legal_centers, failures_on_floor, verified_entity_centers])
		if not verified_entity_pixels.is_empty():
			print("[WorldLandmarkV9 verified source entity pixels] ",verified_entity_pixels)


func _dock_movement_checks() -> void:
	var player: Player = field._player
	player.position = CONTRACT.DOCK_ROUTE[0]
	player.refresh_depth_sort()
	for index in range(1, CONTRACT.DOCK_ROUTE.size()):
		var target: Vector2 = CONTRACT.DOCK_ROUTE[index]
		for tick in range(100):
			var offset := target - player.position
			if offset.length() <= 8.0:
				break
			var direction := offset.normalized()
			Input.action_press("move_right", maxf(direction.x, 0.0))
			Input.action_press("move_left", maxf(-direction.x, 0.0))
			Input.action_press("move_down", maxf(direction.y, 0.0))
			Input.action_press("move_up", maxf(-direction.y, 0.0))
			await physics_frame
		for action in ["move_right", "move_left", "move_down", "move_up"]:
			Input.action_release(action)
		await physics_frame
		_check(player.position.distance_to(target) <= 10.0, "actual physics input traverses dock bend %d to %s (actor=%s)" % [index,target,player.position])
		_check(_foot_clear(player.position), "actual dock input ends on complete supported foot")


const VERIFIED_RAIL_BASES := {"north":648.3390625,"right_middle":682.7921875,"right_near":728.45625,"left_middle":670.7609375,"left_near":724.628125}


func _actual_actor_alpha_intersection(part: Sprite2D) -> int:
	var actor: Sprite2D = field._player.sprite
	var actor_sheet := actor.texture.get_image()
	var frame_size := actor_sheet.get_size() / Vector2i(actor.hframes,actor.vframes)
	var actor_image := actor_sheet.get_region(Rect2i(actor.frame_coords*frame_size,frame_size))
	var part_image := part.texture.get_image()
	var hits := 0
	for y in range(actor_image.get_height()):
		for x in range(actor_image.get_width()):
			if actor_image.get_pixel(x,y).a <= 0.5:
				continue
			var local_pixel := actor.get_rect().position + (Vector2(x,y)+Vector2(0.5,0.5)) / Vector2(actor_image.get_size()) * actor.get_rect().size
			var on_part := part.to_local(actor.to_global(local_pixel))
			var uv := (on_part-part.get_rect().position)/part.get_rect().size
			if uv.x >= 0 and uv.y >= 0 and uv.x < 1 and uv.y < 1 and part_image.get_pixelv(Vector2i(uv*Vector2(part_image.get_size()))).a > 0.5:
				hits += 1
	return hits


func _rail_part_depth_checks() -> void:
	var player: Player = field._player
	var rail_images: Array[Image] = []
	_check(field._actor_layer.get_node_or_null("SceneObject_lab_ferry_near_rail") == null, "combined near-rail mask is audit-only, not a runtime shared-Y entity")
	for name: String in VERIFIED_RAIL_BASES:
		var part := field._actor_layer.get_node_or_null("SceneObject_lab_ferry_rail_"+name) as Sprite2D
		_check(part != null, "independent physical rail part exists: "+name)
		if part == null:
			continue
		var texture_path := CONTRACT.PREFIX+"ferry_rail_"+name+".png"
		var image := _read_png(texture_path)
		_check(image != null and image.get_size() == Vector2i(1536,1024) and image.get_used_rect().has_area() and ResourceLoader.exists(texture_path), "readable nonempty exact source canvas rail part: "+name)
		if image != null:
			rail_images.append(image)
		var object_found := false
		for object in CONTRACT.scene_objects():
			if object["id"] == "lab_ferry_rail_"+name:
				object_found = true
				_check(absf(float(object["depth_sort_foot_y"])*CONTRACT.WORLD_SIZE.y-float(VERIFIED_RAIL_BASES[name])) < 0.001, "rail depth uses independently verified actual source bottom: "+name)
		_check(object_found, "per-post depth contract exists: "+name)
		# Generic non-intersection witnesses cross the existing 8px sort band;
		# exact overlapping same-band semantics are checked separately below.
		player.position = Vector2(2435,float(VERIFIED_RAIL_BASES[name])-9.0)
		player.refresh_depth_sort()
		_check(player.z_index < part.z_index, "actor north of actual rail base sorts behind: "+name)
		player.position.y += 18.0
		player.refresh_depth_sort()
		_check(_actor_draws_after(part), "actor south of actual rail base effectively sorts in front, including same-band sibling order: "+name)
	var aggregate := _read_png(CONTRACT.PREFIX+"ferry_near_rail.png")
	_check(rail_images.size() == 5 and aggregate != null, "all five actual rail images available for independent full-pixel partition audit")
	if rail_images.size() == 5 and aggregate != null:
		var duplicate_pixels := 0
		var mismatches := 0
		for y in range(aggregate.get_height()):
			for x in range(aggregate.get_width()):
				var nonempty := 0
				var alpha := 0.0
				for image in rail_images:
					var part_alpha := image.get_pixel(x,y).a
					if part_alpha > 0.0:
						nonempty += 1
					alpha = maxf(alpha,part_alpha)
				if nonempty > 1:
					duplicate_pixels += 1
				if absf(alpha-aggregate.get_pixel(x,y).a) > 0.001:
					mismatches += 1
		_check(duplicate_pixels == 0, "five actual rail masks never duplicate source entity pixels (%d)" % duplicate_pixels)
		_check(mismatches == 0, "five actual rail masks reconstruct aggregate alpha at every source pixel (%d)" % mismatches)
		print("[WorldLandmarkV9 rail partition] duplicate_pixels=%d aggregate_alpha_mismatches=%d" % [duplicate_pixels,mismatches])
	var middle := field._actor_layer.get_node_or_null("SceneObject_lab_ferry_rail_right_middle") as Sprite2D
	if middle == null:
		return
	player.set_walk_direction(Vector2.RIGHT,false)
	for station in [{"y":677.0,"front":false},{"y":686.0,"front":true},{"y":689.0,"front":true}]:
		player.position = Vector2(2435,station["y"])
		player.refresh_depth_sort()
		_check(_walks(player.position) and _foot_clear(player.position), "actual overlapping middle-post station preserves complete legal foot: %s" % player.position)
		var hits := _actual_actor_alpha_intersection(middle)
		_check(hits > 0, "standing-right actor actual opaque pixels intersect middle post at %s hits=%d" % [player.position,hits])
		_check(_actor_draws_after(middle) == station["front"], "actual alpha-overlapping actor has correct middle-post front/behind at %s" % player.position)
		if station["y"] == 689.0:
			_check(player.z_index > middle.z_index, "middle-post south witness crosses a full depth band, not only a tie")
		print("[WorldLandmarkV9 post overlap] foot=%s actual_alpha_hits=%d actor_z=%d part_z=%d" % [player.position,hits,player.z_index,middle.z_index])


func _actor_draws_after(part: Sprite2D) -> bool:
	var player: Player = field._player
	return player.z_index > part.z_index or (player.z_index == part.z_index and player.get_parent() == part.get_parent() and player.get_index() > part.get_index())
