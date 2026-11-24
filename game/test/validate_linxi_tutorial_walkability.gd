extends SceneTree

const SCENE_PATH := "res://data/scenes/linxi_tutorial.tres"
const GRID_W := 96
const GRID_H := 54


func _initialize() -> void:
	var scene_data: SceneScript = load(SCENE_PATH) as SceneScript
	if scene_data == null:
		_fail("cannot load tutorial scene")
		return
	if scene_data.exits.size() != 1:
		_fail("expected one visible-map exit, found %d" % scene_data.exits.size())
		return
	var exit_data: Dictionary = scene_data.exits[0]
	if String(exit_data.get("id", "")) != "exit_to_road":
		_fail("tutorial exit must lead to the mountain road")
		return
	var exit_pos: Vector2 = exit_data.get("pos", Vector2.ZERO)
	if _point_blocked(exit_pos, scene_data.collision_rects):
		_fail("right-top exit center overlaps a collision rectangle")
		return
	if not _is_reachable(scene_data.player_spawn, exit_pos, scene_data.collision_rects):
		_fail("player spawn cannot reach the right-top exit")
		return
	print("[TutorialWalkability] PASS spawn=%s exit=%s" % [scene_data.player_spawn, exit_pos])
	quit(0)


func _is_reachable(start: Vector2, goal: Vector2, blocks: Array) -> bool:
	var start_cell := _to_cell(start)
	var goal_cell := _to_cell(goal)
	var frontier: Array[Vector2i] = [start_cell]
	var visited: Dictionary = {start_cell: true}
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == goal_cell:
			return true
		for direction in directions:
			var next: Vector2i = current + direction
			if next.x < 0 or next.y < 0 or next.x >= GRID_W or next.y >= GRID_H:
				continue
			if visited.has(next) or _point_blocked(_to_norm(next), blocks):
				continue
			visited[next] = true
			frontier.append(next)
	return false


func _point_blocked(point: Vector2, blocks: Array) -> bool:
	for entry in blocks:
		var block: Dictionary = entry
		var pos: Vector2 = block.get("pos", Vector2.ZERO)
		var size: Vector2 = block.get("size", Vector2.ZERO)
		var rect := Rect2(pos - size * 0.5, size)
		if rect.has_point(point):
			return true
	return false


func _to_cell(point: Vector2) -> Vector2i:
	return Vector2i(clampi(int(point.x * GRID_W), 0, GRID_W - 1), clampi(int(point.y * GRID_H), 0, GRID_H - 1))


func _to_norm(cell: Vector2i) -> Vector2:
	return Vector2((float(cell.x) + 0.5) / GRID_W, (float(cell.y) + 0.5) / GRID_H)


func _fail(message: String) -> void:
	push_error("[TutorialWalkability] %s" % message)
	quit(1)
