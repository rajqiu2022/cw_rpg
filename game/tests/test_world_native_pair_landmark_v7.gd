extends "res://scripts/dev/run_world_native_pair_landmark_v7.gd"

var failures := 0
var checks := 0
var route_probes := 0


func _initialize() -> void:
	call_deferred("_run_tests")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[WorldLandmarkV7 FAIL] " + message)


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
	_inherited_prop_land_checks()
	# Explicit bridge deck exception: water on both sides, real rails do not open.
	for x in range(1425, 1896, 10):
		_check(_walks(Vector2(x, 365)) and _foot_clear(Vector2(x, 365)), "deck traversable x=%d" % x)
	for foot in [Vector2(1660, 325), Vector2(1660, 398), Vector2(1660, 295), Vector2(1660, 440), Vector2(2900, 650), Vector2(2600, 900), Vector2(530,180), Vector2(2070,180)]:
		_check(not _walks(foot), "rail/water negative blocked at %s" % foot)
	for blocker in CONTRACT.blockers():
		var foot: Vector2 = blocker["pos"] * CONTRACT.WORLD_SIZE
		_check(not _walks(foot), "paired independent blocker: " + String(blocker["id"]))
	for landmark in CONTRACT.landmarks():
		_check(_walks(landmark["entry"]) and _foot_clear(landmark["entry"]), "landward entry full foot: " + String(landmark["id"]))
	_depth_checks()
	await _movement_checks()
	await _capture("city", Vector2(900, 390))
	await _capture("bridge", Vector2(1660, 365))
	for station in [{"label": "bridge_front", "foot": Vector2(1660, 376)}, {"label": "bridge_back", "foot": Vector2(1660, 355)}]:
		_check(_foot_clear(station["foot"]), "bridge screenshot station preserves full foot: " + String(station["label"]))
		await _capture(station["label"], station["foot"])
	await _capture("ferry", Vector2(2395, 735))
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
	print("[WorldLandmarkV7] checks=%d failures=%d continuous_main_road=%d; isolated, shipping map unchanged" % [checks, failures, route_probes])
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
			for y in range(0, 1024, 37):
				for x in range(0, 1536, 101):
					if left.get_pixel(x,y) != source.get_pixel(x,y) or right.get_pixel(x,y) != source.get_pixel(x+1536,y):
						matched = false
		_check(matched, "same-camera region crops exact sampled pixels: " + String(family["full"]))
	var invalid := 0
	var declared_deck := 0
	for y in range(0, walk.get_height(), 4):
		for x in range(0, walk.get_width(), 4):
			var pixel := Vector2(x, y)
			if walk.get_pixel(x, y).r > 0.5 and land.get_pixel(x, y).r < 0.5:
				if CONTRACT.BRIDGE_DECK.has_point(pixel):
					declared_deck += 1
				else:
					invalid += 1
	_check(invalid == 0, "navigation never opens water outside declared bridge deck (%d invalid)" % invalid)
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
	for pair in [{"id": "lab_luoyang", "foot": CONTRACT.CITY_FOOT}, {"id": "lab_bailu", "foot": CONTRACT.FERRY_FOOT},
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
		_check(image != null and image.save_png("res://build/world_native_pair_landmark_v7_" + label + ".png") == OK, "1920 runtime capture: " + label)


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
