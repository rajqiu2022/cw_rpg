extends SceneTree

const GRID_W := 120
const GRID_H := 80
const PLAYER_RADIUS := 0.028
const SCENE_PATH := "res://data/scenes/ch1_s3_west_ruin.tres"

var _failed := 0


func _initialize() -> void:
	var scene_data := load(SCENE_PATH) as SceneScript
	_check(scene_data != null, "west ruin scene cannot load")
	if scene_data == null or scene_data.map_layout == null:
		quit(1)
		return
	var layout: WalkableMapLayout = scene_data.map_layout
	_check(layout.design_size == Vector2i(1536, 1024), "west ruin must use native background dimensions")
	_check(not layout.display_at_native_size, "west ruin must uniformly cover the play viewport")
	_check(_reachable(scene_data.player_spawn, Vector2(0.10, 0.86), layout), "player cannot reach village return exit")
	_check(_reachable(scene_data.player_spawn, Vector2(0.60, 0.36), layout), "player cannot reach the inner-hall door")
	_check(not _blocked(Vector2(0.10, 0.86), layout), "village return exit overlaps collision")
	_check(not _blocked(Vector2(0.60, 0.36), layout), "inner-hall door overlaps collision")
	print("[Ch1WestRuinNavigation] failed=%d" % _failed)
	quit(1 if _failed > 0 else 0)


func _reachable(start: Vector2, goal: Vector2, layout: WalkableMapLayout) -> bool:
	if not _inside(start, layout.walkable_regions) or not _inside(goal, layout.walkable_regions):
		return false
	var frontier: Array[Vector2i] = [_cell(start)]
	var visited: Dictionary = {frontier[0]: true}
	var target := _cell(goal)
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == target:
			return true
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next_cell: Vector2i = current + direction
			if next_cell.x < 0 or next_cell.y < 0 or next_cell.x >= GRID_W or next_cell.y >= GRID_H or visited.has(next_cell):
				continue
			var sample: Vector2 = _norm(next_cell)
			if not _inside(sample, layout.walkable_regions) or _blocked(sample, layout):
				continue
			visited[next_cell] = true
			frontier.append(next_cell)
	return false


func _inside(point: Vector2, regions: Array[PackedVector2Array]) -> bool:
	for region in regions:
		if Geometry2D.is_point_in_polygon(point, region):
			return true
	return false


func _blocked(point: Vector2, layout: WalkableMapLayout) -> bool:
	for entry in layout.blockers:
		var data: Dictionary = entry
		var pos: Vector2 = data.get("pos", Vector2.ZERO)
		var size: Vector2 = data.get("size", Vector2.ZERO)
		if Rect2(pos - size * 0.5 - Vector2.ONE * PLAYER_RADIUS, size + Vector2.ONE * PLAYER_RADIUS * 2.0).has_point(point):
			return true
	return false


func _cell(point: Vector2) -> Vector2i:
	return Vector2i(clampi(int(point.x * GRID_W), 0, GRID_W - 1), clampi(int(point.y * GRID_H), 0, GRID_H - 1))


func _norm(cell: Vector2i) -> Vector2:
	return Vector2((float(cell.x) + 0.5) / GRID_W, (float(cell.y) + 0.5) / GRID_H)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed += 1
	push_error("[Ch1WestRuinNavigation] %s" % message)
