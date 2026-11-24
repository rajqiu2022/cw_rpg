extends SceneTree

const GRID_W := 160
const GRID_H := 72
const PLAYER_RADIUS := 0.028
const SCENE_PATH := "res://data/scenes/ch1_s2_qingfeng.tres"
const INN_LAYOUT_PATH := "res://data/maps/interior_inn_hall_layout_v1.tres"
const VILLAGE_ENTRY := Vector2(0.24, 0.72)
const INN_RETURN := Vector2(0.31, 0.54)
const NPC_CATALOG_PATH := "res://data/npcs/npc_catalog.tres"
const MERCHANT_FOOT_SAFE_PATH := "res://art/characters/street_expansion_v1/npc_street_merchant_idle_down_4f_v3_runtime.png"
const VENDOR_FOOT_SAFE_PATH := "res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png"
const ESCORT_FOOT_SAFE_PATH := "res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png"
const ESCORT_PARTNER_PATH := "res://art/characters/npc_zhuwei_gate_guard_idle_down_25d_4f_v2_runtime.png"

var _failed := 0


func _initialize() -> void:
	var scene_data := load(SCENE_PATH) as SceneScript
	_check(scene_data != null, "cannot load Zhuwei scene")
	if scene_data == null or scene_data.map_layout == null:
		quit(1)
		return
	var layout := scene_data.map_layout
	_check(layout.design_size == Vector2i(1536, 1024), "Zhuwei main street must use the new native composition")
	_check(not layout.display_at_native_size, "Zhuwei main street must uniformly cover the play viewport")
	_check(scene_data.player_spawn.is_equal_approx(VILLAGE_ENTRY), "Zhuwei entry must be in front of the southwest inn")
	_check(_walkable(scene_data.player_spawn, layout), "spawn is not on the road")
	_check(_inn_returns_to_village_entry(), "inn exit must return in front of the southwest inn")
	_check(_npc_visual_contracts(scene_data), "Zhuwei merchant/vendor must use foot-safe strips and gate guard must use reviewed adult scale")
	_check(_baked_actor_fade_contract(layout), "southwest baked roof must own a player-only transparency zone")
	for probe_data in layout.walkable_probes:
		var probe: Dictionary = probe_data
		var pos: Vector2 = probe.get("pos", Vector2.ZERO)
		_check(_walkable(pos, layout), "walkable probe %s is unreachable" % String(probe.get("id", "")))
	for object_entry in layout.visual_objects:
		var object_data: Dictionary = object_entry
		if object_data.has("collision_size"):
			var foot: Vector2 = object_data.get("pos", Vector2.ZERO) + object_data.get("collision_offset", Vector2.ZERO)
			_check(_blocked(foot, layout), "building %s has no effective foot collision" % String(object_data.get("id", "")))
		if String(object_data.get("interaction_action", "")) != "":
			var approach: Vector2 = object_data.get("pos", Vector2.ZERO) + object_data.get("interaction_offset", Vector2.ZERO)
			_check(_walkable(approach, layout), "interactive building %s cannot be reached" % String(object_data.get("id", "")))
	for portal_entry in layout.portals:
		var portal: Dictionary = portal_entry
		var portal_pos: Vector2 = portal.get("pos", Vector2.ZERO)
		_check(_walkable(portal_pos, layout), "portal %s is unreachable" % String(portal.get("id", "")))
		if String(portal.get("id", "")) == "to_zhuwei_forest":
			_check(portal_pos.x >= 0.92, "forest entrance must sit on the visible right-edge road")
	print("[Ch1ZhuweiNavigation] failed=%d" % _failed)
	quit(1 if _failed > 0 else 0)


func _npc_visual_contracts(scene_data: SceneScript) -> bool:
	var catalog := load(NPC_CATALOG_PATH) as NPCCatalog
	if catalog == null:
		return false
	var merchant := catalog.find(&"merchant", &"ch1_s2_qingfeng")
	var vendor := catalog.find(&"vegetable_vendor", &"ch1_s2_qingfeng")
	if merchant == null or vendor == null:
		return false
	if merchant.sprite_path != MERCHANT_FOOT_SAFE_PATH or vendor.sprite_path != VENDOR_FOOT_SAFE_PATH:
		return false
	if not ResourceLoader.exists(merchant.sprite_path) or not ResourceLoader.exists(vendor.sprite_path):
		return false
	if not _foot_safe(merchant.sprite_path) or not _foot_safe(vendor.sprite_path):
		return false
	var guard_ok := false
	var escort_ids: Dictionary = {}
	for raw_npc: Variant in scene_data.npcs:
		var npc: Dictionary = raw_npc as Dictionary
		var npc_id := String(npc.get("npc_id", ""))
		if npc_id == "guard":
			guard_ok = float(npc.get("scale", 0.0)) >= 1.08 and float((npc.get("pos", Vector2.ZERO) as Vector2).x) <= 0.88
		if npc_id in ["patrol_scout", "patrol_scout_partner"]:
			escort_ids[npc_id] = true
			var expected_path := ESCORT_FOOT_SAFE_PATH if npc_id == "patrol_scout" else ESCORT_PARTNER_PATH
			if String(npc.get("sprite_path", "")) != expected_path:
				return false
			if String(npc.get("require_flag", "")) != "" or String(npc.get("hide_flag", "")) != "":
				return false
	return guard_ok and escort_ids.size() == 2 and _foot_safe(ESCORT_FOOT_SAFE_PATH) and _foot_safe(ESCORT_PARTNER_PATH)


func _baked_actor_fade_contract(layout: WalkableMapLayout) -> bool:
	if layout.actor_fade_zones.size() != 1:
		return false
	var zone: Dictionary = layout.actor_fade_zones[0]
	if String(zone.get("id", "")) != "southwest_baked_roof_actor_fade":
		return false
	var region: PackedVector2Array = zone.get("region", PackedVector2Array())
	if region.size() < 3:
		return false
	var roof_sample := Vector2(0.29, 0.78)
	var square_sample := Vector2(0.54, 0.62)
	return (
		Geometry2D.is_point_in_polygon(roof_sample, region)
		and not Geometry2D.is_point_in_polygon(square_sample, region)
		and _walkable(roof_sample, layout)
		and float(zone.get("actor_faded_alpha", 1.0)) >= 0.35
		and float(zone.get("actor_faded_alpha", 1.0)) <= 0.55
	)


func _foot_safe(resource_path: String) -> bool:
	var image := Image.load_from_file(ProjectSettings.globalize_path(resource_path))
	if image == null or image.is_empty() or image.get_height() <= 0:
		return false
	var frame_count: int = 1
	if image.get_width() > image.get_height() and image.get_width() % image.get_height() == 0:
		frame_count = image.get_width() / image.get_height()
	var frame_width: int = image.get_width() / frame_count
	for frame_index: int in range(frame_count):
		var max_alpha_y: int = -1
		for y: int in range(image.get_height()):
			for x: int in range(frame_index * frame_width, (frame_index + 1) * frame_width):
				if image.get_pixel(x, y).a > 0.02:
					max_alpha_y = y
		if max_alpha_y < 0 or image.get_height() - 1 - max_alpha_y < 6:
			return false
	return true


func _inn_returns_to_village_entry() -> bool:
	var inn_layout := load(INN_LAYOUT_PATH) as WalkableMapLayout
	if inn_layout == null:
		return false
	for portal_entry in inn_layout.portals:
		var portal: Dictionary = portal_entry
		if String(portal.get("id", "")) != "leave_inn":
			continue
		return String(portal.get("target_scene", "")) == "ch1_s2_qingfeng" and Vector2(portal.get("target_pos", Vector2.ZERO)).is_equal_approx(INN_RETURN)
	return false


func _walkable(point: Vector2, layout: WalkableMapLayout) -> bool:
	if not _inside(point, layout.walkable_regions) or _blocked(point, layout):
		return false
	var frontier: Array[Vector2i] = [_cell(Vector2(0.10, 0.68))]
	var visited: Dictionary = {frontier[0]: true}
	var target := _cell(point)
	for _step in range(GRID_W * GRID_H):
		if frontier.is_empty():
			return false
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
	var entries: Array = layout.blockers.duplicate(true)
	for object_entry in layout.visual_objects:
		var object_data: Dictionary = object_entry
		if object_data.has("collision_size"):
			entries.append({"pos": object_data.get("pos", Vector2.ZERO) + object_data.get("collision_offset", Vector2.ZERO), "size": object_data.get("collision_size", Vector2.ZERO)})
	for entry in entries:
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
	push_error("[Ch1ZhuweiNavigation] %s" % message)
