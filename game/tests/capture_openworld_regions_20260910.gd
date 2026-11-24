extends SceneTree

var failed := 0
var router: Node
var dp: Node
var approach_paths := {}
const IDS := [&"openworld_bailu_ferry", &"openworld_east_sea_port", &"openworld_qinghe_town", &"openworld_yanmen_pass"]

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	router = root.get_node("SceneRouter")
	dp = root.get_node("DialogPlayer")
	root.get_node("GameState").call("reset_for_new_game")
	root.get_node("QuestManager").states.clear()
	var only_yanmen := "--yanmen-only" in OS.get_cmdline_user_args()
	for id: StringName in ([&"openworld_yanmen_pass"] if only_yanmen else IDS):
		router.call("go_field_smart", id)
		await wait_scene(id)
		var field := current_scene
		var scene: Resource = field.get("_current_scene")
		print("SCENE ", id, " spawn=", field.call("_current_player_spawn"), " world_size=", field.get("_screen_size"))
		check_navigation(field, scene)
		await snapshot(String(id))
		if id == &"openworld_yanmen_pass":
			var player: Node2D = field.get("_player")
			field.set("_encounter_locked", true)
			for data: Dictionary in scene.map_layout.interactions:
				player.position = field.call("_norm_to_screen", scene.player_spawn)
				await physics_frame
				await walk_path(player, field, approach_paths.get(String(data.id), []), String(data.id))
				await create_timer(0.2).timeout
				await snapshot(String(data.id))
				if String(data.id) == "snow_old_guard_chest":
					var event := InputEventAction.new()
					event.action = &"interact"
					event.pressed = true
					player.call("_unhandled_input", event)
					await process_frame
					check(dp.call("is_playing"), "physical chest proximity interaction opens dialogue")
					for tick in range(6):
						if not dp.call("is_playing"):
							break
						dp.call("advance")
						await process_frame
		router.call("go_world_map")
		var expected: Vector2 = router.call("get_world_map_position_for_scene", id)
		var payload: Dictionary = router.call("get_field_payload")
		check(payload.player_spawn.is_equal_approx(expected), "return portal spawn " + String(id))
		await wait_scene(&"world_map_jianghu")
		if only_yanmen:
			print("[YanmenQA] failed=", failed)
			quit(1 if failed else 0)
			return
	# Exercise the real authored dialogue choice, then return from that landing.
	for start: StringName in [&"openworld_bailu_ferry", &"openworld_east_sea_port"]:
		router.call("go_field_smart", start)
		await wait_scene(start)
		dp.call("play", load("res://data/dialogs/%s_boat.tres" % String(start)))
		dp.call("choose", 0)
		var landing := &"openworld_east_sea_port" if start == &"openworld_bailu_ferry" else &"openworld_bailu_ferry"
		await wait_scene(landing)
		check(router.call("get_current_field_id") == landing, "boat lands " + String(landing))
		router.call("go_world_map")
		var expected: Vector2 = router.call("get_world_map_position_for_scene", landing)
		var payload: Dictionary = router.call("get_field_payload")
		check(payload.player_spawn.is_equal_approx(expected), "boat return world at landing portal " + String(landing))
		await wait_scene(&"world_map_jianghu")
	print("[OpenworldVisualQA] failed=", failed)
	current_scene.queue_free()
	current_scene = null
	await process_frame
	await process_frame
	quit(1 if failed else 0)

func wait_scene(id: StringName) -> void:
	for tick in range(200):
		await create_timer(0.05).timeout
		if current_scene != null and current_scene.get("_current_scene") != null and current_scene.get("_current_scene").scene_id == id:
			await create_timer(0.35).timeout
			return
	check(false, "timed out " + String(id))

func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		push_error(label)
	else:
		print("PASS ", label)

func check_navigation(field: Node, scene: Resource) -> void:
	# Flood the runtime walkability predicate; targets need only an approach
	# cell within interaction range, not a walkable centre inside the object.
	const GRID := 120
	var visited := {}
	var parents := {}
	var spawn: Vector2 = field.call("_current_player_spawn")
	if scene.scene_id == &"openworld_yanmen_pass":
		print("YANMEN regions=", scene.map_layout.walkable_regions.size(), " mask=", scene.map_layout.walkable_mask_path)
		check(scene.map_layout.walkable_regions.size() == 4 and scene.map_layout.walkable_mask_path.is_empty(), "dedicated snow-road polygon contract")
		for probe: Dictionary in scene.map_layout.blocked_probes:
			check(not field.call("_is_normalized_spawn_walkable", scene, probe.pos), "snow cliff stays blocked " + String(probe.id))
	var first := Vector2i(roundi(spawn.x*GRID), roundi(spawn.y*GRID))
	var queue: Array[Vector2i] = [first]
	visited[first] = true
	var index := 0
	while index < queue.size():
		var p := queue[index]
		index += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := p + step
			if next.x < 0 or next.y < 0 or next.x > GRID or next.y > GRID or visited.has(next):
				continue
			if footprint_walkable(field, scene, Vector2(next)/GRID):
				visited[next] = true
				parents[next] = p
				queue.append(next)
	check(footprint_walkable(field, scene, spawn), String(scene.scene_id) + " initial full foot rectangle navigable")
	var targets: Array = scene.npcs.duplicate()
	targets.append_array(scene.map_layout.interactions)
	targets.append_array(scene.map_layout.portals)
	for data: Dictionary in targets:
		var nearest := INF
		var nearest_pos := Vector2.ZERO
		var nearest_cell := first
		var size_px: Vector2 = field.get("_screen_size")
		for cell: Vector2i in queue:
			var distance: float = ((Vector2(cell)/GRID-data.pos)*size_px).length()
			if distance < nearest:
				nearest = distance
				nearest_pos = Vector2(cell)/GRID
				nearest_cell = cell
		if nearest >= 65.0:
			print("UNREACHABLE ", data.get("id", "?"), " closest=", nearest_pos, " target=", data.pos)
		check(nearest < 65.0, "%s approach %s distance %.1f" % [scene.scene_id, data.get("npc_id", data.get("id", "?")), nearest])
		var path: Array[Vector2] = []
		var cursor := nearest_cell
		while cursor != first and parents.has(cursor):
			path.push_front(Vector2(cursor)/GRID)
			cursor = parents[cursor]
		approach_paths[String(data.get("id", "?"))] = path

func walk_path(player: Node2D, field: Node, path: Array, label: String) -> void:
	check(not path.is_empty(), "physical route exists " + label)
	if path.is_empty():
		return
	for point: Vector2 in path:
		var destination: Vector2 = field.call("_norm_to_screen", point)
		var ticks := 0
		while player.position.distance_to(destination) > 3.0 and ticks < 80:
			var direction := (destination-player.position).normalized()
			Input.action_press("move_left", maxf(-direction.x, 0.0))
			Input.action_press("move_right", maxf(direction.x, 0.0))
			Input.action_press("move_up", maxf(-direction.y, 0.0))
			Input.action_press("move_down", maxf(direction.y, 0.0))
			await physics_frame
			ticks += 1
		for action in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(action)
		if ticks >= 80:
			check(false, "physical walk stalled %s at %s toward %s" % [label, player.position, destination])
			return
	check(true, "physical walk reached " + label)

func footprint_walkable(field: Node, scene: Resource, point: Vector2) -> bool:
	var player: Node2D = field.get("_player")
	var collider := player.get_node("CollisionShape2D") as CollisionShape2D
	var half_size: Vector2 = collider.shape.size * 0.5
	var size_px: Vector2 = field.get("_screen_size")
	for offset: Vector2 in [Vector2.ZERO, collider.position, collider.position-half_size, collider.position+half_size, collider.position+Vector2(-half_size.x,half_size.y), collider.position+Vector2(half_size.x,-half_size.y)]:
		if not field.call("_is_normalized_spawn_walkable", scene, point+offset/size_px):
			return false
	return true

func snapshot(id: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var folder := ProjectSettings.globalize_path("res://../assets/previews/openworld_qa_20260910")
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_texture().get_image().save_png(folder.path_join(id + ".png"))
