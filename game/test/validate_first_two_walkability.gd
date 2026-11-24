extends SceneTree

const GRID_W := 120
const GRID_H := 68
const PLAYER_RADIUS := 0.028
const SCENES := [
	"res://data/scenes/linxi_tutorial.tres",
	"res://data/scenes/ch1_s0_linxi_main_walkable.tres",
	"res://data/scenes/ch1_s1_road.tres",
]


func _initialize() -> void:
	for path in SCENES:
		var scene_data := load(path) as SceneScript
		if scene_data == null:
			_fail("cannot load %s" % path)
			return
		if scene_data.exits.is_empty():
			if scene_data.map_layout == null or scene_data.map_layout.portals.is_empty():
				_fail("%s has no exit" % scene_data.scene_id)
				return
		var blocks := _all_collision_blocks(scene_data)
		var portals: Array = scene_data.map_layout.portals if scene_data.map_layout != null else scene_data.exits
		for exit_data in portals:
			var exit_pos: Vector2 = exit_data.get("pos", Vector2.ZERO)
			if scene_data.scene_id == &"ch1_s1_road" and String(exit_data.get("id", "")).begins_with("exit_to_zhuwei") and exit_pos.distance_to(Vector2(0.82, 0.14)) > 0.03:
				_fail("%s exit %s is not aligned with the visible upper-right entrance" % [scene_data.scene_id, exit_data.get("id", "")])
				return
			if scene_data.scene_id == &"ch1_s1_road" and String(exit_data.get("id", "")) == "bandit_cave_entry" and exit_pos.distance_to(Vector2(0.705, 0.585)) > 0.025:
				_fail("bandit cave portal is no longer aligned with the painted cave threshold")
				return
			if _blocked(exit_pos, blocks):
				_fail("%s exit %s overlaps collision" % [scene_data.scene_id, exit_data.get("id", "")])
				return
			if not _reachable(scene_data.player_spawn, exit_pos, blocks):
				_fail("%s spawn cannot reach exit %s" % [scene_data.scene_id, exit_data.get("id", "")])
				return
			if scene_data.scene_id == &"linxi_tutorial" and String(exit_data.get("target_scene", "")) == "ch1_s1_road":
				var target_scene := load("res://data/scenes/ch1_s1_road.tres") as SceneScript
				if target_scene == null or target_scene.map_layout == null:
					_fail("ch1_s1_road target map cannot load")
					return
				var target_pos: Vector2 = exit_data.get("target_pos", Vector2.ZERO)
				if not _inside_walkable(target_pos, target_scene.map_layout.walkable_regions):
					_fail("%s exit %s spawns outside ch1_s1_road walkable space" % [scene_data.scene_id, exit_data.get("id", "")])
					return
		if scene_data.scene_id == &"ch1_s1_road" and not _has_interactive_object(scene_data, "road_supply_box_closed"):
			_fail("%s modular supply box lacks collision or interaction data" % scene_data.scene_id)
			return
		if scene_data.scene_id == &"ch1_s1_road" and not _has_safe_stone_trigger(scene_data):
			_fail("%s stone trigger must be interaction-only and hidden after reading" % scene_data.scene_id)
			return
		if scene_data.scene_id == &"ch1_s1_road" and scene_data.background_path != "res://art/backgrounds/bg_ch1_s1_road_cave_entry_v2.png":
			_fail("ch1_s1_road must use the reviewed background with a visible cave entrance")
			return
		print("[FirstTwoWalkability] PASS %s" % scene_data.scene_id)
	quit(0)


func _all_collision_blocks(scene_data: SceneScript) -> Array:
	var blockers: Array = scene_data.map_layout.blockers if scene_data.map_layout != null else scene_data.collision_rects
	var objects: Array = scene_data.map_layout.visual_objects if scene_data.map_layout != null else scene_data.scene_objects
	var blocks: Array = blockers.duplicate(true)
	for entry in objects:
		var data: Dictionary = entry
		if not data.has("collision_size"):
			continue
		var pos: Vector2 = data.get("pos", Vector2.ZERO) + data.get("collision_offset", Vector2.ZERO)
		blocks.append({"pos": pos, "size": data.get("collision_size", Vector2.ZERO)})
	return blocks


func _has_interactive_object(scene_data: SceneScript, object_id: String) -> bool:
	var objects: Array = scene_data.map_layout.visual_objects if scene_data.map_layout != null else scene_data.scene_objects
	for entry in objects:
		var data: Dictionary = entry
		if String(data.get("id", "")) != object_id:
			continue
		return data.has("collision_size") and String(data.get("interaction_action", "")) != ""
	return false


func _has_safe_stone_trigger(scene_data: SceneScript) -> bool:
	var interactions: Array = scene_data.map_layout.interactions if scene_data.map_layout != null else scene_data.trigger_zones
	for entry in interactions:
		var data: Dictionary = entry
		if String(data.get("id", "")) != "road_stone_read":
			continue
		var activation: String = String(data.get("activation", "interact" if bool(data.get("interaction_only", false)) else "enter_once"))
		return activation == "interact" and String(data.get("hide_flag", "")) == "saw_stone_warning"
	return false


func _reachable(start: Vector2, goal: Vector2, blocks: Array) -> bool:
	var frontier: Array[Vector2i] = [_cell(start)]
	var visited: Dictionary = {frontier[0]: true}
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == _cell(goal):
			return true
		for direction in directions:
			var next := current + direction
			if next.x < 0 or next.y < 0 or next.x >= GRID_W or next.y >= GRID_H:
				continue
			if visited.has(next) or _blocked(_norm(next), blocks):
				continue
			visited[next] = true
			frontier.append(next)
	return false


func _blocked(point: Vector2, blocks: Array) -> bool:
	for entry in blocks:
		var data: Dictionary = entry
		var pos: Vector2 = data.get("pos", Vector2.ZERO)
		var size: Vector2 = data.get("size", Vector2.ZERO)
		var inflated := Rect2(pos - size * 0.5 - Vector2.ONE * PLAYER_RADIUS, size + Vector2.ONE * PLAYER_RADIUS * 2.0)
		if inflated.has_point(point):
			return true
	return false


func _inside_walkable(point: Vector2, regions: Array[PackedVector2Array]) -> bool:
	for region in regions:
		if Geometry2D.is_point_in_polygon(point, region):
			return true
	return false


func _cell(point: Vector2) -> Vector2i:
	return Vector2i(clampi(int(point.x * GRID_W), 0, GRID_W - 1), clampi(int(point.y * GRID_H), 0, GRID_H - 1))


func _norm(cell: Vector2i) -> Vector2:
	return Vector2((float(cell.x) + 0.5) / GRID_W, (float(cell.y) + 0.5) / GRID_H)


func _fail(message: String) -> void:
	push_error("[FirstTwoWalkability] %s" % message)
	quit(1)
