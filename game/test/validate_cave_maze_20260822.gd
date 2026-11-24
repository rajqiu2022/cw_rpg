extends SceneTree

const GRID_W := 120
const GRID_H := 68
const PLAYER_RADIUS := 0.028
const SCENE_PATHS := {
	"ch1_s4_zhuwei_beast_cave": "res://data/scenes/ch1_s4_zhuwei_beast_cave.tres",
	"ch1_s4_cave_mine_gallery": "res://data/scenes/ch1_s4_cave_mine_gallery.tres",
	"ch1_s4_cave_waterway": "res://data/scenes/ch1_s4_cave_waterway.tres",
	"ch1_s4_cave_deep_den": "res://data/scenes/ch1_s4_cave_deep_den.tres",
}

var failures: Array[String] = []
var checks := 0
var scenes: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_load_and_validate_scenes()
	_validate_topology()
	_validate_content_placement()
	print("[CaveMaze20260822] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[CaveMaze20260822] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _load_and_validate_scenes() -> void:
	for scene_id: String in SCENE_PATHS:
		var scene := load(String(SCENE_PATHS[scene_id])) as SceneScript
		_check(scene != null, "%s场景资源可加载" % scene_id)
		if scene == null:
			continue
		scenes[scene_id] = scene
		_check(scene.is_walkable and scene.map_layout != null, "%s使用可行走布局" % scene_id)
		_check(scene.map_layout.design_size == Vector2i(1536, 1024), "%s保持1536×1024原生设计尺寸" % scene_id)
		_check(ResourceLoader.exists(scene.background_path), "%s正式背景存在" % scene_id)
		var image := Image.load_from_file(ProjectSettings.globalize_path(scene.background_path))
		_check(image != null and image.get_size() == Vector2i(1536, 1024), "%s背景尺寸正确" % scene_id)
		_check(_walkable(scene.player_spawn, scene.map_layout), "%s默认出生点可行走" % scene_id)
		for probe: Dictionary in scene.map_layout.walkable_probes:
			var point: Vector2 = probe.get("pos", Vector2.ZERO)
			_check(_reachable(scene.player_spawn, point, scene.map_layout), "%s探针可达：%s" % [scene_id, probe.get("id", "")])
		for portal: Dictionary in scene.map_layout.portals:
			var point: Vector2 = portal.get("pos", Vector2.ZERO)
			_check(_reachable(scene.player_spawn, point, scene.map_layout), "%s出口可达：%s" % [scene_id, portal.get("id", "")])
		for interaction: Dictionary in scene.map_layout.interactions:
			var point: Vector2 = interaction.get("pos", Vector2.ZERO)
			_check(_reachable(scene.player_spawn, point, scene.map_layout), "%s交互可达：%s" % [scene_id, interaction.get("id", "")])


func _validate_topology() -> void:
	if scenes.size() != SCENE_PATHS.size():
		return
	var graph: Dictionary = {}
	for scene_id: String in scenes:
		graph[scene_id] = []
		var scene: SceneScript = scenes[scene_id]
		for portal: Dictionary in scene.map_layout.portals:
			var target := String(portal.get("target_scene", ""))
			if SCENE_PATHS.has(target):
				(graph[scene_id] as Array).append(target)
				var target_scene: SceneScript = scenes[target]
				var target_pos: Vector2 = portal.get("target_pos", Vector2.ZERO)
				_check(_walkable(target_pos, target_scene.map_layout), "%s到%s的落点可行走" % [scene_id, target])
	_check((graph["ch1_s4_zhuwei_beast_cave"] as Array).size() == 2, "入口营地连接两条洞穴支路")
	_check((graph["ch1_s4_cave_mine_gallery"] as Array).size() == 2, "废弃矿道可回入口且可进深窟")
	_check((graph["ch1_s4_cave_waterway"] as Array).size() == 2, "地下水道可回入口且可进深窟")
	_check((graph["ch1_s4_cave_deep_den"] as Array).size() == 2, "头狼深窟可从两条支路返回")
	for source: String in graph:
		for target: String in graph[source]:
			_check(source in (graph[target] as Array), "%s↔%s出口双向成对" % [source, target])
	for target: String in graph:
		_check(_graph_reachable("ch1_s4_zhuwei_beast_cave", target, graph), "入口营地可抵达%s" % target)
		_check(_graph_reachable(target, "ch1_s4_zhuwei_beast_cave", graph), "%s可返回入口营地" % target)


func _validate_content_placement() -> void:
	if scenes.size() != SCENE_PATHS.size():
		return
	var entrance: SceneScript = scenes["ch1_s4_zhuwei_beast_cave"]
	var mine: SceneScript = scenes["ch1_s4_cave_mine_gallery"]
	var water: SceneScript = scenes["ch1_s4_cave_waterway"]
	var deep: SceneScript = scenes["ch1_s4_cave_deep_den"]
	_check(_find(entrance.map_layout.interactions, "cave_alpha_wolf").is_empty(), "入口营地不提前放置头狼")
	_check(_find(entrance.map_layout.interactions, "cave_supply_clue").is_empty(), "入口营地不提前暴露主线货筒")
	_check(not _find(mine.map_layout.interactions, "cave_mine_cache").is_empty(), "矿道拥有独立宝箱探索点")
	_check(String(_find(mine.map_layout.interactions, "cave_mine_cache").get("action", "")) == "dialog:ch1_zhuwei_cave_mine_cache", "矿道底图宝箱连接独立调查对白")
	_check(not _find(water.map_layout.interactions, "cave_water_cache").is_empty(), "水道拥有独立补给探索点")
	_check(String(_find(water.map_layout.interactions, "cave_water_cache").get("interaction_visual_kind", "")) == "parcel", "水道补给有可见实物")
	var wolf := _find(deep.map_layout.interactions, "cave_alpha_wolf")
	var clue := _find(deep.map_layout.interactions, "cave_supply_clue")
	_check(String(wolf.get("require_quest_active", "")) == "q_ch1_main_zhuwei_wilds", "头狼只在后山主线激活时出现")
	_check(String(clue.get("require_flag", "")) == "defeated_zhuwei_cave_wolf", "击退头狼后显示主线货筒")
	_check(String(clue.get("interaction_visual_kind", "")) == "parcel", "主线货筒使用可见交互物")


func _find(entries: Array, entry_id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if String(entry.get("id", "")) == entry_id:
			return entry
	return {}


func _graph_reachable(start: String, goal: String, graph: Dictionary) -> bool:
	var frontier: Array[String] = [start]
	var visited := {start: true}
	while not frontier.is_empty():
		var current: String = frontier.pop_front()
		if current == goal:
			return true
		for target: String in graph[current]:
			if visited.has(target):
				continue
			visited[target] = true
			frontier.append(target)
	return false


func _walkable(point: Vector2, layout: WalkableMapLayout) -> bool:
	var inside: bool = false
	for polygon: PackedVector2Array in layout.walkable_regions:
		if Geometry2D.is_point_in_polygon(point, polygon):
			inside = true
			break
	if not inside:
		return false
	for blocker: Dictionary in layout.blockers:
		var center: Vector2 = blocker.get("pos", Vector2.ZERO)
		var size: Vector2 = blocker.get("size", Vector2.ZERO)
		var inflated := Rect2(center - size * 0.5 - Vector2.ONE * PLAYER_RADIUS, size + Vector2.ONE * PLAYER_RADIUS * 2.0)
		if inflated.has_point(point):
			return false
	return true


func _reachable(start: Vector2, goal: Vector2, layout: WalkableMapLayout) -> bool:
	var frontier: Array[Vector2i] = [_cell(start)]
	var visited: Dictionary = {frontier[0]: true}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == _cell(goal):
			return true
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + direction
			if next.x < 0 or next.y < 0 or next.x >= GRID_W or next.y >= GRID_H or visited.has(next):
				continue
			if not _walkable(_norm(next), layout):
				continue
			visited[next] = true
			frontier.append(next)
	return false


func _cell(point: Vector2) -> Vector2i:
	return Vector2i(clampi(int(point.x * GRID_W), 0, GRID_W - 1), clampi(int(point.y * GRID_H), 0, GRID_H - 1))


func _norm(cell: Vector2i) -> Vector2:
	return Vector2((float(cell.x) + 0.5) / GRID_W, (float(cell.y) + 0.5) / GRID_H)


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
