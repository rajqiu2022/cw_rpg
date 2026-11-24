extends SceneTree

const SCENE_IDS := [
	&"openworld_huashan_forecourt",
	&"openworld_huashan_sword_terrace",
	&"openworld_huashan_waterfall_terrace",
	&"openworld_wudang_gate",
	&"openworld_wudang_taiji_court",
	&"openworld_wudang_purple_cloud_court",
]
const GRID := 144

var checks := 0
var failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("GameState").call("reset_for_new_game")
	var router := root.get_node("SceneRouter")
	for scene_id: StringName in SCENE_IDS:
		await _wait_transition_idle()
		router.call("go_field_smart", scene_id)
		await _wait_scene(scene_id)
		_check_runtime_navigation(current_scene, current_scene.get("_current_scene"))
	print("[SectMapV3RuntimeNavigation] checks=%d failed=%d" % [checks, failed])
	if current_scene != null:
		current_scene.queue_free()
		await process_frame
	quit(1 if failed else 0)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error("[SectMapV3RuntimeNavigation] " + label)


func _wait_scene(scene_id: StringName) -> void:
	for tick in range(200):
		await create_timer(0.025).timeout
		if current_scene != null and current_scene.get("_current_scene") != null and current_scene.get("_current_scene").scene_id == scene_id:
			await process_frame
			return
	_check(false, "timed out loading " + String(scene_id))


func _wait_transition_idle() -> void:
	var loading_manager := root.get_node("LoadingManager")
	for tick in range(200):
		if not bool(loading_manager.get("_transition_active")):
			return
		await create_timer(0.025).timeout
	_check(false, "loading transition did not become idle")


func _check_runtime_navigation(field: Node, scene: SceneScript) -> void:
	var spawn := scene.player_spawn
	var first := Vector2i(roundi(spawn.x * GRID), roundi(spawn.y * GRID))
	var queue: Array[Vector2i] = [first]
	var visited := {first: true}
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next := cell + step
			if next.x < 0 or next.y < 0 or next.x > GRID or next.y > GRID or visited.has(next):
				continue
			if _footprint_walkable(field, scene, Vector2(next) / GRID):
				visited[next] = true
				queue.append(next)
	_check(_footprint_walkable(field, scene, spawn), "spawn supports the complete actor footprint: " + String(scene.scene_id))
	_check(queue.size() >= 200, "scene exposes a meaningful walkable area: %s (%d cells)" % [scene.scene_id, queue.size()])
	var targets: Array[Dictionary] = []
	targets.assign(scene.map_layout.walkable_probes)
	targets.append_array(scene.map_layout.portals)
	for data: Dictionary in targets:
		var target: Vector2 = data.get("pos", Vector2.ZERO)
		var nearest := INF
		for cell: Vector2i in queue:
			nearest = minf(nearest, (Vector2(cell) / GRID).distance_to(target))
		_check(nearest <= 0.035, "spawn-connected route reaches %s/%s (%.4f)" % [scene.scene_id, data.get("id", "?"), nearest])
	for probe: Dictionary in scene.map_layout.blocked_probes:
		_check(not _footprint_walkable(field, scene, probe.get("pos", Vector2.ZERO)), "blocked terrain rejects the actor footprint: %s/%s" % [scene.scene_id, probe.get("id", "?")])
	_check_wudang_depth_layers(field, scene)


func _check_wudang_depth_layers(field: Node, scene: SceneScript) -> void:
	if not String(scene.scene_id).begins_with("openworld_wudang"):
		return
	var occluders: Array = field.get("_occluder_nodes")
	_check(not occluders.is_empty(), "Wudang runtime instantiates foreground samples: " + String(scene.scene_id))
	if scene.scene_id == &"openworld_wudang_gate":
		var gate := occluders[0] as DynamicOccluder2D
		_check(gate != null and not gate.uses_foot_depth_sort(), "gate foreground uses overlap mode")
		_check(gate != null and gate.contains_fade_point(Vector2(0.500, 0.500)), "under-gate witness triggers the masked actor ghost")
		_check(gate != null and not gate.contains_fade_point(Vector2(0.500, 0.575)), "open stairs keep the actor fully opaque")
		return
	var depth_count := 0
	for raw: Variant in occluders:
		var occluder := raw as DynamicOccluder2D
		if occluder == null or not occluder.uses_foot_depth_sort():
			continue
		depth_count += 1
		occluder.update_player_position(Vector2(0.5, occluder.depth_y - 0.02), true)
		_check(occluder.visible, "foreground prop covers actor behind its foot-Y line: " + occluder.occluder_id)
		occluder.update_player_position(Vector2(0.5, occluder.depth_y + 0.02), true)
		_check(not occluder.visible, "foreground prop yields when actor walks in front: " + occluder.occluder_id)
	_check(depth_count >= 4, "Wudang court creates at least four foot-Y foreground props: " + String(scene.scene_id))


func _footprint_walkable(field: Node, scene: SceneScript, point: Vector2) -> bool:
	var player: Node2D = field.get("_player")
	var collider := player.get_node("CollisionShape2D") as CollisionShape2D
	var half_size: Vector2 = collider.shape.size * 0.5
	var size_px: Vector2 = field.get("_screen_size")
	for offset: Vector2 in [Vector2.ZERO, collider.position, collider.position - half_size, collider.position + half_size, collider.position + Vector2(-half_size.x, half_size.y), collider.position + Vector2(half_size.x, -half_size.y)]:
		if not field.call("_is_normalized_spawn_walkable", scene, point + offset / size_px):
			return false
	return true
