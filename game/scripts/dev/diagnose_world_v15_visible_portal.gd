extends SceneTree
## Reproduce the approved v14 visual-doorstep gap without changing any asset.
const WORLD = preload("res://scripts/world/world_map_v14_contract.gd")
var counts := {"interacted": 0}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var router := root.get_node("SceneRouter")
	var prior: Dictionary = router.get_navigation_state()
	var scene := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	var portal: Dictionary = {}
	var landmark: Dictionary = {}
	for entry: Dictionary in scene.map_layout.portals:
		if entry.id == "luoyang": portal = entry
	for entry: Dictionary in scene.map_layout.visual_objects:
		if entry.get("portal_id", "") == "luoyang": landmark = entry
	if portal.is_empty() or landmark.is_empty(): quit(2); return
	var center: Vector2 = portal.pos * WORLD.SIZE
	var size: Vector2 = portal.size * WORLD.SIZE
	var area := Rect2(center - size * .5, size)
	var render_center: Vector2 = landmark.pos * WORLD.SIZE
	var render_size: Vector2 = landmark.render_size_px
	# Source reviewed bottom-center gate apron. Scan actual full-foot nav rather
	# than permitting the player to stand on the building for this reproduction.
	var front_y := render_center.y + render_size.y * .5
	var doorway: Variant = null
	for y in range(int(front_y) - 30, int(front_y) + 11):
		var p := Vector2(render_center.x, y) / WORLD.SIZE
		if WORLD.safe_foot(scene, p): doorway = p; break
	if not doorway is Vector2: quit(3); return
	var field: Node = load("res://scenes/field_walkable.tscn").instantiate()
	field.set_script(load("res://scripts/dev/world_v15_portal_probe_field.gd"))
	root.add_child(field)
	await physics_frame
	await physics_frame
	var player: Player = field.get("_player")
	player.interacted.connect(func(): counts.interacted += 1)
	var rows: Array[Dictionary] = []
	for point: Vector2 in [doorway, portal.pos]:
		player.position = point * WORLD.SIZE
		player.velocity = Vector2.ZERO
		for settle in 8:
			await physics_frame
			await process_frame
		var before: int = field.observed_exits.size()
		var before_keys: int = counts.interacted
		var key := InputEventKey.new()
		key.keycode = KEY_SPACE
		key.physical_keycode = KEY_SPACE
		key.pressed = true
		Input.parse_input_event(key)
		await process_frame
		await physics_frame
		key = InputEventKey.new()
		key.keycode = KEY_SPACE
		key.physical_keycode = KEY_SPACE
		key.pressed = false
		Input.parse_input_event(key)
		await process_frame
		var observed_zone: ExitZone = null
		for zone: ExitZone in field.get("_exit_nodes"):
			if zone.target_scene_id == String(portal.target_scene): observed_zone = zone
		rows.append({"point_px": [point.x * WORLD.SIZE.x, point.y * WORLD.SIZE.y], "full17_safe": WORLD.safe_foot(scene, point), "inside_trigger": area.has_point(point * WORLD.SIZE), "actual_player_interacted": counts.interacted - before_keys, "actual_exit_signals": field.observed_exits.size() - before, "actual_body_overlap": observed_zone.overlaps_body(player), "zone_global": str(observed_zone.global_position), "player_global": str(player.global_position)})
	print("VISIBLE_PORTAL_DIAGNOSIS ", JSON.stringify({"portal_id": "luoyang", "trigger_center_px": [center.x, center.y], "trigger_size_px": [size.x, size.y], "render_bottom_y": front_y, "cases": rows, "router_travel_suppressed_only_in_fixture": true}))
	root.remove_child(field)
	field.queue_free()
	await process_frame
	await physics_frame
	router.restore_navigation_state(prior)
	var reproduced: bool = rows.size() == 2 and rows[0].actual_player_interacted == 1 and rows[0].actual_exit_signals == 0 and rows[1].actual_exit_signals == 1
	print("VISIBLE_PORTAL_REPRODUCED=", reproduced)
	quit(0 if reproduced else 1)
