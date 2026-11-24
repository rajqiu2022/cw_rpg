extends SceneTree

const GRID_W := 120
const GRID_H := 68
const PLAYER_RADIUS := 0.028
const SCENES := [
	"res://data/scenes/linxi_tutorial.tres",
	"res://data/scenes/linxi_village_center.tres",
	"res://data/scenes/ch1_s0_linxi_main_walkable.tres",
	"res://data/scenes/ch1_s1_road.tres",
	"res://data/scenes/ch1_s2_qingfeng.tres",
	"res://data/scenes/ch1_s3_west_ruin.tres",
	"res://data/scenes/ch1_s3_ruin_inner.tres",
	"res://data/scenes/ch1_s3_zhuwei_forest.tres",
	"res://data/scenes/ch1_s4_zhuwei_beast_cave.tres",
	"res://data/scenes/ch1_s4_cave_mine_gallery.tres",
	"res://data/scenes/ch1_s4_cave_waterway.tres",
	"res://data/scenes/ch1_s4_cave_deep_den.tres",
	"res://data/scenes/ch2_s5_bandit_cave.tres",
	"res://data/scenes/ch2_s5_mine_workshop.tres",
	"res://data/scenes/ch2_s5_mine_command.tres",
	"res://data/scenes/interior_inn_hall.tres",
	"res://data/scenes/linxi_hero_bedroom.tres",
	"res://data/scenes/linxi_master_hall.tres",
	"res://data/scenes/world_map_jianghu.tres",
]

var _checked: int = 0
var _failed: int = 0


func _initialize() -> void:
	for path in SCENES:
		_validate_scene(path)
	print("[WalkableMapV2] checked=%d failed=%d" % [_checked, _failed])
	quit(1 if _failed > 0 else 0)


func _validate_scene(path: String) -> void:
	var scene := load(path) as SceneScript
	_check(scene != null, "%s cannot load" % path)
	if scene == null:
		return
	var layout := scene.map_layout
	_check(layout != null, "%s has no V2 map_layout" % scene.scene_id)
	if layout == null:
		return
	if scene.scene_id == &"world_map_jianghu":
		# V8 keeps the optimized 2304x1536 world at native scale and scrolls it with
		# a real Camera2D. The exact raster road core has a dedicated suite.
		_check(layout.schema_version == 8, "world_map_jianghu schema version is not 8")
		_check(layout.display_at_native_size, "world_map_jianghu must preserve the native painted map scale")
		_check(layout.design_size == Vector2i(2304, 1536), "world_map_jianghu must use the reviewed v8 logical size")
		_check(not layout.walkable_mask_path.is_empty(), "world_map_jianghu must bind the v8 road mask")
		_check(layout.portals.size() >= 8, "world_map_jianghu has too few travel portals")
		_check(layout.walkable_probes.size() >= 8, "world_map_jianghu has too few reviewed road probes")
		return
	_check(layout.schema_version == 2, "%s schema version is not 2" % scene.scene_id)
	_check(not layout.walkable_regions.is_empty(), "%s has no positive walkable region" % scene.scene_id)
	_check(_inside_walkable(scene.player_spawn, layout.walkable_regions), "%s spawn is outside walkable regions" % scene.scene_id)
	_validate_spawn_mobility(scene, layout)
	if scene.scene_id == &"linxi_tutorial":
		_check(not layout.display_at_native_size, "linxi_tutorial must uniformly cover the play viewport")
		_check(layout.design_size == Vector2i(1536, 1024), "linxi_tutorial source design size must match its background")
	if scene.scene_id == &"linxi_village_center":
		_check(not layout.display_at_native_size, "linxi_village_center must uniformly cover the play viewport")
		_check(layout.design_size == Vector2i(1536, 1024), "linxi_village_center source design size must match its background")
	if scene.scene_id == &"ch1_s1_road":
		_check(not layout.display_at_native_size, "ch1_s1_road must uniformly cover the play viewport")
		_check(layout.design_size == Vector2i(1536, 1024), "ch1_s1_road source design size must match its background")
	if scene.scene_id in [&"ch1_s2_qingfeng", &"ch1_s3_west_ruin", &"ch1_s3_zhuwei_forest", &"ch1_s4_zhuwei_beast_cave", &"ch1_s4_cave_mine_gallery", &"ch1_s4_cave_waterway", &"ch1_s4_cave_deep_den", &"ch2_s5_bandit_cave", &"ch2_s5_mine_workshop", &"ch2_s5_mine_command"]:
		_check(not layout.display_at_native_size, "%s must uniformly cover the play viewport" % scene.scene_id)
		_check(layout.design_size == Vector2i(1536, 1024), "%s source design size must match its background" % scene.scene_id)
	if scene.scene_id in [&"interior_inn_hall", &"linxi_hero_bedroom", &"linxi_master_hall"]:
		_check(layout.display_at_native_size, "%s must preserve the reviewed interior stage ratio" % scene.scene_id)

	var ids: Dictionary = {}
	for entry in layout.interactions:
		var data: Dictionary = entry
		_validate_id(scene.scene_id, data, ids)
		var activation: String = String(data.get("activation", ""))
		_check(activation in ["interact", "enter_once"], "%s interaction %s has invalid activation" % [scene.scene_id, data.get("id", "")])
		if activation == "enter_once":
			_check(String(data.get("hide_flag", "")) != "", "%s auto interaction %s needs hide_flag" % [scene.scene_id, data.get("id", "")])
		_check(_inside_walkable(data.get("pos", Vector2.ZERO), layout.walkable_regions), "%s interaction %s is outside walkable regions" % [scene.scene_id, data.get("id", "")])
		_check(_reachable(scene.player_spawn, data.get("pos", Vector2.ZERO), layout), "%s interaction %s is unreachable" % [scene.scene_id, data.get("id", "")])

	for entry in layout.portals:
		var data: Dictionary = entry
		_validate_id(scene.scene_id, data, ids)
		_check(_inside_walkable(data.get("pos", Vector2.ZERO), layout.walkable_regions), "%s portal %s is outside walkable regions" % [scene.scene_id, data.get("id", "")])
		_check(String(data.get("target_scene", "")) != "" or String(data.get("action", "")) != "", "%s portal %s has no destination" % [scene.scene_id, data.get("id", "")])
		_check(_reachable(scene.player_spawn, data.get("pos", Vector2.ZERO), layout), "%s portal %s is unreachable" % [scene.scene_id, data.get("id", "")])
		if String(data.get("target_scene", "")) == "ch1_s1_road":
			var target_scene := load("res://data/scenes/ch1_s1_road.tres") as SceneScript
			_check(target_scene != null and target_scene.map_layout != null, "ch1_s1_road target scene cannot load")
			if target_scene != null and target_scene.map_layout != null:
				var target_pos: Vector2 = data.get("target_pos", Vector2.ZERO)
				_check(_inside_walkable(target_pos, target_scene.map_layout.walkable_regions), "linxi exit target is outside ch1_s1_road walkable regions")
				_check(not _blocked(target_pos, target_scene.map_layout), "linxi exit target is blocked in ch1_s1_road")

	for entry in layout.visual_objects:
		var data: Dictionary = entry
		_validate_id(scene.scene_id, data, ids)
		var texture_path: String = String(data.get("texture", ""))
		_check(texture_path != "" and ResourceLoader.exists(texture_path), "%s visual object %s texture missing" % [scene.scene_id, data.get("id", "")])

	for entry in layout.walkable_probes:
		var data: Dictionary = entry
		var probe_pos: Vector2 = data.get("pos", Vector2.ZERO)
		_check(_inside_walkable(probe_pos, layout.walkable_regions), "%s walkable probe %s is outside path" % [scene.scene_id, data.get("id", "")])
		_check(_reachable(scene.player_spawn, probe_pos, layout), "%s walkable probe %s is unreachable" % [scene.scene_id, data.get("id", "")])

	for entry in layout.blocked_probes:
		var data: Dictionary = entry
		var probe_pos: Vector2 = data.get("pos", Vector2.ZERO)
		_check(not _inside_walkable(probe_pos, layout.walkable_regions) or _blocked(probe_pos, layout), "%s blocked probe %s is walkable" % [scene.scene_id, data.get("id", "")])


func _validate_id(scene_id: StringName, data: Dictionary, ids: Dictionary) -> void:
	var id: String = String(data.get("id", ""))
	_check(id != "", "%s map entry has empty id" % scene_id)
	_check(not ids.has(id), "%s has duplicate map id %s" % [scene_id, id])
	ids[id] = true


func _inside_walkable(point: Vector2, regions: Array[PackedVector2Array]) -> bool:
	for polygon in regions:
		if Geometry2D.is_point_in_polygon(point, polygon):
			return true
	return false


func _validate_spawn_mobility(scene: SceneScript, layout: WalkableMapLayout) -> void:
	var step := Vector2(0.018, 0.018)
	var directions: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	for direction in directions:
		var probe := scene.player_spawn + direction * (step.x if direction.x != 0.0 else step.y)
		_check(_inside_walkable(probe, layout.walkable_regions) and not _blocked(probe, layout), "%s spawn cannot move %s" % [scene.scene_id, direction])


func _reachable(start: Vector2, goal: Vector2, layout: WalkableMapLayout) -> bool:
	var frontier: Array[Vector2i] = [_cell(start)]
	var visited: Dictionary = {frontier[0]: true}
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == _cell(goal):
			return true
		for direction in directions:
			var next: Vector2i = current + direction
			if next.x < 0 or next.y < 0 or next.x >= GRID_W or next.y >= GRID_H:
				continue
			var point := _norm(next)
			if visited.has(next) or not _inside_walkable(point, layout.walkable_regions) or _blocked(point, layout):
				continue
			visited[next] = true
			frontier.append(next)
	return false


func _blocked(point: Vector2, layout: WalkableMapLayout) -> bool:
	var entries: Array = layout.blockers.duplicate(true)
	for object_entry in layout.visual_objects:
		var object_data: Dictionary = object_entry
		if not object_data.has("collision_size"):
			continue
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
	push_error("[WalkableMapV2] %s" % message)
