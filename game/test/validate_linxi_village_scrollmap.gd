extends SceneTree

const GRID_W := 160
const GRID_H := 96
const PLAYER_RADIUS := 0.020
const EXPECTED_SIZE := Vector2i(2048, 976)

var _checked: int = 0
var _failed: int = 0


func _initialize() -> void:
	var scene: SceneScript = load("res://data/scenes/linxi_village_scrollmap.tres") as SceneScript
	_check(scene != null, "scrolling village scene loads")
	if scene == null or scene.map_layout == null:
		quit(1)
		return
	var layout: WalkableMapLayout = scene.map_layout
	_check(layout.design_size == EXPECTED_SIZE, "map uses the reviewed 2048x976 near-native canvas")
	_check(layout.display_at_native_size, "map renders at native size without stretching")
	var texture: Texture2D = load(scene.background_path) as Texture2D
	_check(texture != null, "background texture loads")
	if texture != null:
		_check(texture.get_size() == Vector2(EXPECTED_SIZE), "background pixels match map design size")
	var source_image := Image.load_from_file(ProjectSettings.globalize_path(scene.background_path))
	_check(source_image != null and source_image.get_format() != Image.FORMAT_RGBA8, "large opaque background is stored without a redundant alpha channel")
	_check(scene.npcs.size() >= 11, "expanded village contains at least eleven configured NPCs")
	_check(scene.player_visual_scale >= 0.69 and scene.player_visual_scale <= 0.71, "overview-map protagonist is at least as readable as ordinary NPCs")
	_check(scene.npc_visual_scale >= 0.62 and scene.npc_visual_scale <= 0.66, "overview NPCs remain readable without overpowering the player")
	_check(is_equal_approx(scene.camera_zoom, 1.11), "medium map uses a slightly wider near-native camera framing")
	_check(_validate_house_portals(layout), "three key houses are enterable and return to South District")
	_check(_validate_npc_assets(scene), "NPC sprites are unique reviewed full-body resources")
	_check(_validate_coach_full_body(scene), "militia coach uses the rebuilt four-frame strip with complete feet")
	_check(_validate_peddler_full_body(scene), "peddler uses the full-body v3 strip rebuilt from the approved source atlas")
	_check(_validate_npc_access(scene, layout), "every NPC is reachable and has a loadable dialog")
	_check(_passable(scene.player_spawn, layout), "default spawn is passable")
	_check(scene.player_spawn.distance_to(Vector2(0.080, 0.500)) < 0.001, "entry spawn stays on the wide west road instead of a cottage roof")
	for raw_probe: Variant in layout.walkable_probes:
		var probe: Dictionary = raw_probe as Dictionary
		var position: Vector2 = probe.get("pos", Vector2.ZERO) as Vector2
		_check(_reachable(scene.player_spawn, position, layout), "probe %s is reachable" % String(probe.get("id", "")))
	for raw_portal: Variant in layout.portals:
		var portal: Dictionary = raw_portal as Dictionary
		var position: Vector2 = portal.get("pos", Vector2.ZERO) as Vector2
		_check(_reachable(scene.player_spawn, position, layout), "portal %s is reachable" % String(portal.get("id", "")))
	for raw_probe: Variant in layout.blocked_probes:
		var probe: Dictionary = raw_probe as Dictionary
		var position: Vector2 = probe.get("pos", Vector2.ZERO) as Vector2
		_check(not _passable(position, layout), "blocked probe %s stays blocked" % String(probe.get("id", "")))
	print("[LinxiScrollmap] checked=%d failed=%d" % [_checked, _failed])
	quit(1 if _failed > 0 else 0)


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
		npc_ids[npc_id] = true
		sprite_paths[sprite_path] = true
	return true


func _validate_coach_full_body(scene: SceneScript) -> bool:
	const EXPECTED_PATH := "res://art/characters/street_expansion_v1/npc_linxi_south_militia_coach_idle_down_4f_v2_runtime.png"
	for raw_npc: Variant in scene.npcs:
		var npc: Dictionary = raw_npc as Dictionary
		if String(npc.get("npc_id", "")) != "linxi_south_militia_coach":
			continue
		if String(npc.get("sprite_path", "")) != EXPECTED_PATH:
			return false
		var image := Image.load_from_file(ProjectSettings.globalize_path(EXPECTED_PATH))
		if image == null or image.get_width() != 640 or image.get_height() != 160:
			return false
		for frame_index: int in range(4):
			var max_alpha_y := -1
			for y: int in range(160):
				for x: int in range(frame_index * 160, (frame_index + 1) * 160):
					if image.get_pixel(x, y).a > 0.02:
						max_alpha_y = maxi(max_alpha_y, y)
			if max_alpha_y < 0 or 159 - max_alpha_y < 6:
				return false
		return true
	return false


func _validate_peddler_full_body(scene: SceneScript) -> bool:
	const EXPECTED_PATH := "res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png"
	for raw_npc: Variant in scene.npcs:
		var npc: Dictionary = raw_npc as Dictionary
		if String(npc.get("npc_id", "")) != "linxi_south_peddler":
			continue
		if String(npc.get("sprite_path", "")) != EXPECTED_PATH:
			return false
		var image := Image.load_from_file(ProjectSettings.globalize_path(EXPECTED_PATH))
		if image == null or image.get_width() != 640 or image.get_height() != 160:
			return false
		for frame_index: int in range(4):
			var max_alpha_y := -1
			for y: int in range(160):
				for x: int in range(frame_index * 160, (frame_index + 1) * 160):
					if image.get_pixel(x, y).a > 0.02:
						max_alpha_y = maxi(max_alpha_y, y)
			if max_alpha_y < 0 or 159 - max_alpha_y < 6:
				return false
		return true
	return false


func _validate_house_portals(layout: WalkableMapLayout) -> bool:
	var expected := {
		"enter_south_villager_home": "linxi_south_villager_home",
		"enter_south_scholar_house": "linxi_south_scholar_house",
		"enter_south_apothecary_home": "linxi_south_apothecary_home",
	}
	for portal_id: String in expected:
		var found := false
		for raw_portal: Variant in layout.portals:
			var portal: Dictionary = raw_portal as Dictionary
			if String(portal.get("id", "")) != portal_id:
				continue
			found = true
			var target_scene := String(portal.get("target_scene", ""))
			if target_scene != String(expected[portal_id]):
				return false
			var interior := load("res://data/scenes/%s.tres" % target_scene) as SceneScript
			if interior == null or interior.map_layout == null or interior.map_layout.portals.is_empty():
				return false
			var return_portal: Dictionary = interior.map_layout.portals[0]
			if String(return_portal.get("target_scene", "")) != "linxi_village_scrollmap":
				return false
			break
		if not found:
			return false
	return true


func _validate_npc_access(scene: SceneScript, layout: WalkableMapLayout) -> bool:
	for raw_npc: Variant in scene.npcs:
		var npc: Dictionary = raw_npc as Dictionary
		var position: Vector2 = npc.get("pos", Vector2.ZERO) as Vector2
		var dialog_id: String = String(npc.get("dialog_id", ""))
		var interaction_action: String = String(npc.get("interaction_action", ""))
		if not _reachable_to_interaction(scene.player_spawn, position, layout):
			push_error("[LinxiScrollmap] NPC is unreachable: %s at %s" % [String(npc.get("npc_id", "")), position])
			return false
		var has_dialog := not dialog_id.is_empty() and ResourceLoader.exists("res://data/dialogs/%s.tres" % dialog_id)
		var has_supported_action := interaction_action.begins_with("spar:")
		if not has_dialog and not has_supported_action:
			push_error("[LinxiScrollmap] NPC dialog is missing: %s -> %s" % [String(npc.get("npc_id", "")), dialog_id])
			return false
	return true


func _reachable_to_interaction(start: Vector2, target: Vector2, layout: WalkableMapLayout) -> bool:
	var start_cell: Vector2i = _cell(start)
	var frontier: Array[Vector2i] = [start_cell]
	var visited: Dictionary = {start_cell: true}
	var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		var point := _norm(current)
		var pixel_delta := Vector2(
			(point.x - target.x) * float(layout.design_size.x),
			(point.y - target.y) * float(layout.design_size.y)
		)
		if pixel_delta.length() <= 118.0:
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
		var rect: Rect2 = Rect2(position - size * 0.5 - Vector2.ONE * PLAYER_RADIUS, size + Vector2.ONE * PLAYER_RADIUS * 2.0)
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
	push_error("[LinxiScrollmap] %s" % message)
