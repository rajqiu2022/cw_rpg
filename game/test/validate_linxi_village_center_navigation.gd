extends SceneTree

const GRID_W := 120
const GRID_H := 80
const PLAYER_RADIUS := 0.028

var _checked: int = 0
var _failed: int = 0


func _initialize() -> void:
	var scene: SceneScript = load("res://data/scenes/linxi_village_center.tres") as SceneScript
	_check(scene != null, "Linxi village center scene loads")
	if scene == null or scene.map_layout == null:
		quit(1)
		return
	var layout: WalkableMapLayout = scene.map_layout
	_check(scene.npcs.size() >= 6, "village center has at least six life-scene NPCs")
	_check(_validate_npc_assets(scene), "NPC ids and sprite resources satisfy the reviewed full-body contract")
	_check(_validate_tang_practice(scene), "Tang Xingzhou practices staff against a wooden dummy and keeps authored conversation facings")
	_check(_passable(scene.player_spawn, layout), "default spawn is passable")
	for raw_probe: Variant in layout.walkable_probes:
		var probe: Dictionary = raw_probe as Dictionary
		var position: Vector2 = probe.get("pos", Vector2.ZERO) as Vector2
		_check(_reachable(scene.player_spawn, position, layout), "probe %s is reachable" % String(probe.get("id", "")))
	for raw_portal: Variant in layout.portals:
		var portal: Dictionary = raw_portal as Dictionary
		var position: Vector2 = portal.get("pos", Vector2.ZERO) as Vector2
		_check(_reachable(scene.player_spawn, position, layout), "portal %s is reachable" % String(portal.get("id", "")))
	_check(_validate_south_district_portal(layout), "south district portal uses the distinct right-middle road and stays clear of the courtyard portal")
	_check(_validate_house_portals(layout), "all house entrances stay aligned with their reviewed doorstep or stair position")
	for raw_interaction: Variant in layout.interactions:
		var interaction: Dictionary = raw_interaction as Dictionary
		var position: Vector2 = interaction.get("pos", Vector2.ZERO) as Vector2
		_check(_reachable(scene.player_spawn, position, layout), "interaction %s is reachable" % String(interaction.get("id", "")))
	print("[LinxiCenterNavigation] checked=%d failed=%d" % [_checked, _failed])
	quit(1 if _failed > 0 else 0)


func _validate_south_district_portal(layout: WalkableMapLayout) -> bool:
	var south_portal: Dictionary = {}
	var courtyard_portal: Dictionary = {}
	var farmer_portal: Dictionary = {}
	var south_count := 0
	for raw_portal: Variant in layout.portals:
		var portal: Dictionary = raw_portal as Dictionary
		match String(portal.get("id", "")):
			"to_linxi_south_district":
				south_portal = portal
				south_count += 1
			"to_tutorial_courtyard":
				courtyard_portal = portal
			"enter_farmer_cottage":
				farmer_portal = portal
	if south_count != 1 or courtyard_portal.is_empty() or farmer_portal.is_empty():
		return false
	var south_pos: Vector2 = south_portal.get("pos", Vector2.ZERO) as Vector2
	if south_pos.distance_to(Vector2(0.950, 0.525)) > 0.021:
		return false
	if String(south_portal.get("target_scene", "")) != "linxi_village_scrollmap":
		return false
	if String(south_portal.get("label", "")) != "前往林西村南坊":
		return false
	if (south_portal.get("target_pos", Vector2.ZERO) as Vector2).distance_to(Vector2(0.220, 0.600)) > 0.001:
		return false
	if not _passable(south_pos, layout):
		return false
	var farmer_pos: Vector2 = farmer_portal.get("pos", Vector2.ZERO) as Vector2
	if south_pos.distance_to(farmer_pos) < 0.12:
		return false
	var south_size: Vector2 = south_portal.get("size", Vector2.ZERO) as Vector2
	var courtyard_pos: Vector2 = courtyard_portal.get("pos", Vector2.ZERO) as Vector2
	var courtyard_size: Vector2 = courtyard_portal.get("size", Vector2.ZERO) as Vector2
	var south_rect := Rect2(south_pos - south_size * 0.5, south_size)
	var courtyard_rect := Rect2(courtyard_pos - courtyard_size * 0.5, courtyard_size)
	return not south_rect.intersects(courtyard_rect)


func _validate_house_portals(layout: WalkableMapLayout) -> bool:
	var expected := {
		"enter_scholar_house": {"pos": Vector2(0.455, 0.310), "target": "linxi_scholar_house"},
		"enter_farmer_cottage": {"pos": Vector2(0.835, 0.470), "target": "linxi_farmer_cottage"},
		"enter_herbal_home": {"pos": Vector2(0.835, 0.875), "target": "linxi_herbal_home"},
	}
	var found: Dictionary = {}
	for raw_portal: Variant in layout.portals:
		var portal: Dictionary = raw_portal as Dictionary
		var portal_id := String(portal.get("id", ""))
		if not expected.has(portal_id):
			continue
		var approved: Dictionary = expected[portal_id] as Dictionary
		var portal_pos: Vector2 = portal.get("pos", Vector2.ZERO) as Vector2
		if portal_pos.distance_to(approved.get("pos", Vector2.ZERO) as Vector2) > 0.001:
			return false
		if String(portal.get("target_scene", "")) != String(approved.get("target", "")):
			return false
		if not _passable(portal_pos, layout):
			return false
		found[portal_id] = true
	return found.size() == expected.size()


func _validate_npc_assets(scene: SceneScript) -> bool:
	var npc_ids: Dictionary = {}
	var sprite_paths: Dictionary = {}
	for raw_npc: Variant in scene.npcs:
		var npc: Dictionary = raw_npc as Dictionary
		var npc_id: String = String(npc.get("npc_id", ""))
		var sprite_path: String = String(npc.get("sprite_path", ""))
		if npc_id.is_empty() or npc_ids.has(npc_id):
			return false
		if sprite_path.is_empty() or not ResourceLoader.exists(sprite_path):
			return false
		if sprite_paths.has(sprite_path):
			return false
		if String(npc.get("sprite_quality", "")) != "full_body_reviewed":
			return false
		if sprite_path.ends_with("npc_vegetable_seller_idle_down_4f.png"):
			return false
		npc_ids[npc_id] = true
		sprite_paths[sprite_path] = true
	return true


func _validate_tang_practice(scene: SceneScript) -> bool:
	const EXPECTED_PATH := "res://art/characters/companions/tang_xingzhou_field_v2/npc_tang_xingzhou_staff_dummy_practice_4f_v2.png"
	for raw_npc: Variant in scene.npcs:
		var npc: Dictionary = raw_npc as Dictionary
		if String(npc.get("npc_id", "")) != "tang_xingzhou_recruit":
			continue
		if String(npc.get("sprite_path", "")) != EXPECTED_PATH or not ResourceLoader.exists(EXPECTED_PATH):
			return false
		if absf(float(npc.get("scale", 0.0)) - 0.60) > 0.001:
			return false
		if not String(npc.get("portrait_path", "")).ends_with("portrait_tang_xingzhou_v2.png"):
			return false
		var facings: Dictionary = npc.get("conversation_sprite_paths", {}) as Dictionary
		for facing: String in ["down", "up", "left", "right"]:
			var facing_path := String(facings.get(facing, ""))
			if facing_path.is_empty() or not ResourceLoader.exists(facing_path):
				return false
		var texture := load(EXPECTED_PATH) as Texture2D
		return texture != null and texture.get_width() == texture.get_height() * 4 and _strip_has_safe_bottom_margin(EXPECTED_PATH, 4)
	return false


func _strip_has_safe_bottom_margin(path: String, frame_count: int) -> bool:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null or image.is_empty() or image.get_width() % frame_count != 0:
		return false
	var frame_width := image.get_width() / frame_count
	for frame_index: int in frame_count:
		var max_alpha_y := -1
		for y: int in image.get_height():
			for x: int in range(frame_index * frame_width, (frame_index + 1) * frame_width):
				if image.get_pixel(x, y).a > 0.02:
					max_alpha_y = y
		if max_alpha_y < 0:
			return false
		var bottom_margin := image.get_height() - 1 - max_alpha_y
		if bottom_margin < 6 or bottom_margin > 16:
			return false
	return true


func _reachable(start: Vector2, goal: Vector2, layout: WalkableMapLayout) -> bool:
	var start_cell: Vector2i = _cell(start)
	var goal_cell: Vector2i = _cell(goal)
	var frontier: Array[Vector2i] = [start_cell]
	var visited: Dictionary = {start_cell: true}
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == goal_cell:
			return true
		for direction: Vector2i in directions:
			var next_cell: Vector2i = current + direction
			if next_cell.x < 0 or next_cell.y < 0 or next_cell.x >= GRID_W or next_cell.y >= GRID_H:
				continue
			if visited.has(next_cell):
				continue
			if not _passable(_norm(next_cell), layout):
				continue
			visited[next_cell] = true
			frontier.append(next_cell)
	return false


func _passable(point: Vector2, layout: WalkableMapLayout) -> bool:
	var inside: bool = false
	for polygon: PackedVector2Array in layout.walkable_regions:
		if Geometry2D.is_point_in_polygon(point, polygon):
			inside = true
			break
	if not inside:
		return false
	for raw_blocker: Variant in layout.blockers:
		var blocker: Dictionary = raw_blocker as Dictionary
		var position: Vector2 = blocker.get("pos", Vector2.ZERO) as Vector2
		var size: Vector2 = blocker.get("size", Vector2.ZERO) as Vector2
		var rect := Rect2(position - size * 0.5 - Vector2.ONE * PLAYER_RADIUS, size + Vector2.ONE * PLAYER_RADIUS * 2.0)
		if rect.has_point(point):
			return false
	return true


func _cell(point: Vector2) -> Vector2i:
	return Vector2i(clampi(int(point.x * GRID_W), 0, GRID_W - 1), clampi(int(point.y * GRID_H), 0, GRID_H - 1))


func _norm(cell: Vector2i) -> Vector2:
	return Vector2((float(cell.x) + 0.5) / GRID_W, (float(cell.y) + 0.5) / GRID_H)


func _check(condition: bool, message: String) -> void:
	_checked += 1
	if condition:
		return
	_failed += 1
	push_error("[LinxiCenterNavigation] %s" % message)
