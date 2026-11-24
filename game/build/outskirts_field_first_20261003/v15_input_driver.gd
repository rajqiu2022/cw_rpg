extends RefCounted
## Real device input only. No portal signal emission, teleport, router shortcut,
## forced ghost/depth refresh, or production clearance function as oracle.
var tree: SceneTree
var observed_positions := PackedVector2Array()

func configure(owner_tree: SceneTree) -> void:
	tree = owner_tree

func release_movement() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)

func completed_actor_stage() -> void:
	# process_frame resumes before node idle callbacks. The next physics boundary
	# observes normal priority100 late sorting, not a test-forced refresh.
	await tree.process_frame
	await tree.physics_frame

func key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await tree.process_frame

func pointer(logical_viewport_point: Vector2) -> Dictionary:
	var transform: Transform2D = tree.root.get_final_transform()
	var physical: Vector2 = transform * logical_viewport_point
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = physical
		event.global_position = physical
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await tree.process_frame
	return {"logical": [logical_viewport_point.x, logical_viewport_point.y], "physical": [physical.x, physical.y], "final_transform": [transform.x.x, transform.x.y, transform.y.x, transform.y.y, transform.origin.x, transform.origin.y]}

func drive(field: Node, target: Vector2, independent_clear: Callable) -> Dictionary:
	observed_positions.clear()
	if not is_instance_valid(field) or not independent_clear.is_valid(): return {"ok": false, "reason": "missing_field_or_oracle"}
	var player: Node2D = field.get("_player") as Node2D
	if not is_instance_valid(player): return {"ok": false, "reason": "missing_actual_player"}
	var start: Vector2 = player.position
	var budget: int = maxi(120, ceili(start.distance_to(target) / 2.0) + 180)
	var all_feet := true
	var first_bad := Vector2(INF, INF)
	for tick in budget:
		if not is_instance_valid(player) or not is_instance_valid(field):
			release_movement()
			return {"ok": false, "reason": "scene_changed_during_movement"}
		var delta: Vector2 = target - player.position
		if delta.length() <= .15: break
		release_movement()
		var direction: Vector2 = delta.normalized()
		var deadzone := 0.0
		for action: String in ["move_right", "move_left", "move_down", "move_up"]:
			deadzone += InputMap.action_get_deadzone(action) * .25
		# Existing production controller's maximum speed is 480px/s. The actual
		# reached point and every recorded physics step, not this estimate, decide.
		var strength: float = deadzone + (1.0 - deadzone) * minf(1.0, delta.length() / (480.0 / Engine.physics_ticks_per_second))
		Input.action_press("move_right", maxf(direction.x, 0) * strength)
		Input.action_press("move_left", maxf(-direction.x, 0) * strength)
		Input.action_press("move_down", maxf(direction.y, 0) * strength)
		Input.action_press("move_up", maxf(-direction.y, 0) * strength)
		await tree.physics_frame
		if not is_instance_valid(player): break
		observed_positions.append(player.position)
		if not bool(independent_clear.call(player.position)):
			all_feet = false
			if not first_bad.is_finite(): first_bad = player.position
	release_movement()
	await completed_actor_stage()
	var reached: bool = is_instance_valid(player) and player.position.distance_to(target) <= .3
	return {"ok": reached and all_feet, "reached": reached, "all_recorded_feet_clear": all_feet, "start": [start.x, start.y], "target": [target.x, target.y], "actual_end": [player.position.x, player.position.y] if is_instance_valid(player) else [], "physics_samples": observed_positions.size(), "first_bad": [first_bad.x, first_bad.y] if first_bad.is_finite() else []}

func follow(field: Node, points: PackedVector2Array, independent_clear: Callable, independent_segment: Callable) -> Dictionary:
	if points.size() < 2 or not independent_segment.is_valid(): return {"ok": false, "reason": "missing_complete_path"}
	var evidence: Array[Dictionary] = []
	for index in range(1, points.size()):
		var planned: Dictionary = independent_segment.call(points[index - 1], points[index])
		if not bool(planned.get("clear", false)): return {"ok": false, "reason": "planned_edge_full17_denied", "index": index, "evidence": planned}
		var actual: Dictionary = await drive(field, points[index], independent_clear)
		evidence.append(actual)
		if not bool(actual.get("ok", false)): return {"ok": false, "reason": "real_input_failed", "index": index, "segments": evidence}
	return {"ok": true, "segments": evidence}

func plan(from: Vector2, to: Vector2, size: Vector2, independent_clear: Callable, independent_segment: Callable) -> PackedVector2Array:
	# Lazy bounded graph. Every edge (including exact source/target connectors)
	# is independently sampled <=4px/full17; clear endpoints alone never suffice.
	if not independent_clear.is_valid() or not independent_segment.is_valid() or not bool(independent_clear.call(from)) or not bool(independent_clear.call(to)): return PackedVector2Array()
	if bool((independent_segment.call(from, to) as Dictionary).get("clear", false)): return PackedVector2Array([from, to])
	const STEP := 32.0
	var dimensions := Vector2i(ceili(size.x / STEP), ceili(size.y / STEP))
	var parents: Dictionary = {}
	var queue: Array[Vector2i] = []
	var seed := Vector2i(floori(from.x / STEP), floori(from.y / STEP))
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var cell := seed + Vector2i(dx, dy)
			var point := Vector2(cell) * STEP
			if cell.x < 0 or cell.y < 0 or cell.x >= dimensions.x or cell.y >= dimensions.y or not bool(independent_clear.call(point)): continue
			if bool((independent_segment.call(from, point) as Dictionary).get("clear", false)):
				parents[cell] = null
				queue.append(cell)
	var cursor := 0
	var goal := Vector2i(-1, -1)
	const DIRECTIONS := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]
	while cursor < queue.size() and cursor < 20000:
		var cell: Vector2i = queue[cursor]
		cursor += 1
		var point := Vector2(cell) * STEP
		if point.distance_to(to) <= STEP * 1.5 and bool((independent_segment.call(point, to) as Dictionary).get("clear", false)):
			goal = cell
			break
		for direction: Vector2i in DIRECTIONS:
			var other: Vector2i = cell + direction
			if other.x < 0 or other.y < 0 or other.x >= dimensions.x or other.y >= dimensions.y or parents.has(other): continue
			var next: Vector2 = Vector2(other) * STEP
			if not bool(independent_clear.call(next)) or not bool((independent_segment.call(point, next) as Dictionary).get("clear", false)): continue
			parents[other] = cell
			queue.append(other)
	if goal.x < 0: return PackedVector2Array()
	var reversed := PackedVector2Array([to])
	var node: Variant = goal
	while node is Vector2i:
		reversed.append(Vector2(node) * STEP)
		node = parents[node]
	reversed.append(from)
	reversed.reverse()
	return reversed

func release() -> void:
	release_movement()
	observed_positions.clear()
	tree = null
