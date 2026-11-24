extends SceneTree

const GRID_W := 120
const GRID_H := 68
const PLAYER_RADIUS := 0.028
const TARGETS := [
	"res://data/scenes/ch1_s1_road.tres",
	"res://data/scenes/ch1_s4_zhuwei_beast_cave.tres",
]

var _checked := 0
var _failed := 0


func _initialize() -> void:
	for path in TARGETS:
		_validate_scene(path)
	print("[Ch1RoadCaveWalkability] checked=%d failed=%d" % [_checked, _failed])
	quit(1 if _failed > 0 else 0)


func _validate_scene(path: String) -> void:
	var scene := load(path) as SceneScript
	_check(scene != null, "%s can load" % path)
	if scene == null:
		return
	var layout := scene.map_layout
	_check(layout != null, "%s has a V2 layout" % scene.scene_id)
	if layout == null:
		return
	_check(_walkable(scene.player_spawn, layout), "%s spawn is walkable" % scene.scene_id)
	for entry in layout.walkable_probes:
		var probe: Dictionary = entry
		var point: Vector2 = probe.get("pos", Vector2.ZERO)
		_check(_walkable(point, layout), "%s probe %s lies on the path" % [scene.scene_id, probe.get("id", "")])
		_check(_reachable(scene.player_spawn, point, layout), "%s probe %s is reachable" % [scene.scene_id, probe.get("id", "")])
	for entry in layout.interactions:
		var interaction: Dictionary = entry
		var point: Vector2 = interaction.get("pos", Vector2.ZERO)
		_check(_reachable(scene.player_spawn, point, layout), "%s interaction %s is reachable" % [scene.scene_id, interaction.get("id", "")])
	for entry in layout.portals:
		var portal: Dictionary = entry
		var point: Vector2 = portal.get("pos", Vector2.ZERO)
		_check(_reachable(scene.player_spawn, point, layout), "%s portal %s is reachable" % [scene.scene_id, portal.get("id", "")])
	for entry in layout.blocked_probes:
		var probe: Dictionary = entry
		var point: Vector2 = probe.get("pos", Vector2.ZERO)
		_check(not _walkable(point, layout), "%s blocked probe %s remains blocked" % [scene.scene_id, probe.get("id", "")])


func _walkable(point: Vector2, layout: WalkableMapLayout) -> bool:
	var inside := false
	for polygon in layout.walkable_regions:
		if Geometry2D.is_point_in_polygon(point, polygon):
			inside = true
			break
	return inside and not _blocked(point, layout)


func _reachable(start: Vector2, goal: Vector2, layout: WalkableMapLayout) -> bool:
	var frontier: Array[Vector2i] = [_cell(start)]
	var visited: Dictionary = {frontier[0]: true}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == _cell(goal):
			return true
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + direction
			if next.x < 0 or next.y < 0 or next.x >= GRID_W or next.y >= GRID_H or visited.has(next):
				continue
			var point := _norm(next)
			if not _walkable(point, layout):
				continue
			visited[next] = true
			frontier.append(next)
	return false


func _blocked(point: Vector2, layout: WalkableMapLayout) -> bool:
	var entries: Array = layout.blockers.duplicate(true)
	for object_entry in layout.visual_objects:
		var object_data: Dictionary = object_entry
		if object_data.has("collision_size"):
			entries.append({
				"pos": object_data.get("pos", Vector2.ZERO) + object_data.get("collision_offset", Vector2.ZERO),
				"size": object_data.get("collision_size", Vector2.ZERO),
			})
	for entry in entries:
		var data: Dictionary = entry
		var pos: Vector2 = data.get("pos", Vector2.ZERO)
		var size: Vector2 = data.get("size", Vector2.ZERO)
		var inflated := Rect2(pos - size * 0.5 - Vector2.ONE * PLAYER_RADIUS, size + Vector2.ONE * PLAYER_RADIUS * 2.0)
		if inflated.has_point(point):
			return true
	return false


func _cell(point: Vector2) -> Vector2i:
	return Vector2i(clampi(int(point.x * GRID_W), 0, GRID_W - 1), clampi(int(point.y * GRID_H), 0, GRID_H - 1))


func _norm(cell: Vector2i) -> Vector2:
	return Vector2((float(cell.x) + 0.5) / GRID_W, (float(cell.y) + 0.5) / GRID_H)


func _check(condition: bool, message: String) -> void:
	_checked += 1
	if condition:
		return
	_failed += 1
	push_error("[Ch1RoadCaveWalkability] %s" % message)
