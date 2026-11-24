extends SceneTree

const OCCLUDER_SCRIPT := preload("res://scripts/field/dynamic_occluder_2d.gd")

const LAYOUTS := {
	"linxi_village_center": "res://data/maps/linxi_village_center_layout_v1.tres",
}

var _checked: int = 0
var _failed: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for scene_id in LAYOUTS:
		var layout := load(LAYOUTS[scene_id]) as WalkableMapLayout
		_validate_layout(scene_id, layout)
		_validate_npc_visual_clearance(scene_id, layout)
	_validate_runtime_component()
	_validate_player_overlap_ghost()
	_validate_player_baked_map_fade()
	_validate_actor_foot_depth_sort()
	print("[DynamicOccluderValidation] checked=%d failed=%d" % [_checked, _failed])
	quit(1 if _failed > 0 else 0)


func _validate_layout(scene_id: String, layout: WalkableMapLayout) -> void:
	_check(layout != null, "%s layout loads" % scene_id)
	if layout == null:
		return
	_check(not layout.occluders.is_empty(), "%s has dynamic occluders" % scene_id)
	var ids := {}
	var blockers_by_id := {}
	for blocker_entry in layout.blockers:
		var blocker: Dictionary = blocker_entry
		blockers_by_id[String(blocker.get("id", ""))] = blocker
	for occluder_entry in layout.occluders:
		var data: Dictionary = occluder_entry
		var occluder_id := String(data.get("id", ""))
		var blocker_id := String(data.get("blocker_id", ""))
		var cover: PackedVector2Array = data.get("cover_polygon", PackedVector2Array())
		var fade: PackedVector2Array = data.get("fade_region", PackedVector2Array())
		var source_texture_path := String(data.get("source_texture_path", ""))
		_check(occluder_id != "" and not ids.has(occluder_id), "%s occluder id is unique: %s" % [scene_id, occluder_id])
		ids[occluder_id] = true
		_check(blockers_by_id.has(blocker_id), "%s occluder %s references blocker %s" % [scene_id, occluder_id, blocker_id])
		_check(cover.size() >= 3, "%s occluder %s cover polygon is valid" % [scene_id, occluder_id])
		_check(fade.size() >= 3, "%s occluder %s fade region is valid" % [scene_id, occluder_id])
		_check(_all_normalized(cover) and _all_normalized(fade), "%s occluder %s coordinates are normalized" % [scene_id, occluder_id])
		_check(_fade_region_has_reachable_ground(fade, layout), "%s occluder %s fade region reaches valid ground" % [scene_id, occluder_id])
		_check(source_texture_path != "" and ResourceLoader.exists(source_texture_path), "%s occluder %s has a separate foreground source" % [scene_id, occluder_id])
		var actor_faded_alpha := float(data.get("actor_faded_alpha", 1.0))
		_check(actor_faded_alpha >= 0.25 and actor_faded_alpha <= 0.60, "%s occluder %s player transparency is readable" % [scene_id, occluder_id])
		if blockers_by_id.has(blocker_id) and cover.size() >= 3:
			var blocker: Dictionary = blockers_by_id[blocker_id]
			var blocker_pos: Vector2 = blocker.get("pos", Vector2.ZERO)
			var blocker_size: Vector2 = blocker.get("size", Vector2.ZERO)
			var cover_bounds := _polygon_bounds(cover)
			var blocker_bounds := Rect2(blocker_pos - blocker_size * 0.5, blocker_size)
			_check(cover_bounds.grow(0.05).intersects(blocker_bounds), "%s occluder %s aligns with its building footprint" % [scene_id, occluder_id])


func _validate_runtime_component() -> void:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.25, 0.5, 0.75, 1.0))
	var texture := ImageTexture.create_from_image(image)
	var occluder := OCCLUDER_SCRIPT.new() as DynamicOccluder2D
	root.add_child(occluder)
	var configured := occluder.configure({
		"id": "test_roof",
		"blocker_id": "test_building",
		"cover_polygon": PackedVector2Array([Vector2(0.2, 0.2), Vector2(0.8, 0.2), Vector2(0.8, 0.8), Vector2(0.2, 0.8)]),
		"fade_region": PackedVector2Array([Vector2(0.3, 0.3), Vector2(0.7, 0.3), Vector2(0.7, 0.7), Vector2(0.3, 0.7)]),
		"actor_faded_alpha": 0.35,
	}, texture, Vector2(640, 360))
	_check(configured, "runtime occluder configures")
	_check(occluder.polygon.size() == 4 and occluder.uv.size() == 4, "runtime occluder builds sampled geometry")
	occluder.update_player_position(Vector2(0.5, 0.5), true)
	_check(occluder.is_faded and is_equal_approx(occluder.modulate.a, 1.0), "runtime occluder stays opaque inside region")
	_check(is_equal_approx(occluder.get_player_faded_alpha(), 0.35), "runtime occluder exposes actor transparency")
	occluder.update_player_position(Vector2(0.05, 0.05), true)
	_check(not occluder.is_faded and is_equal_approx(occluder.modulate.a, 1.0), "runtime occluder stays opaque outside region")
	occluder.free()


func _validate_player_overlap_ghost() -> void:
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var player := player_scene.instantiate() as Player if player_scene != null else null
	_check(player != null, "player scene instantiates for roof-overlap contract")
	if player == null:
		return
	root.add_child(player)
	await process_frame
	player.set_building_overlap(true, 0.46, true)
	var ghost := player.get_node_or_null("BuildingOverlapGhost") as Sprite2D
	_check(ghost != null and ghost.visible, "roof overlap shows a separate player ghost")
	_check(ghost != null and ghost.z_index > 400 and not ghost.z_as_relative, "overlap ghost renders above opaque building foreground")
	_check(player.sprite.modulate.a == 1.0, "base player remains opaque below the building")
	_check(ghost != null and is_equal_approx(ghost.modulate.a, 0.46), "only overlap ghost uses player transparency")
	player.set_building_overlap(false, 0.46, true)
	_check(ghost != null and not ghost.visible, "overlap ghost hides after leaving roof region")
	player.free()


func _validate_player_baked_map_fade() -> void:
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var player := player_scene.instantiate() as Player if player_scene != null else null
	_check(player != null, "player scene instantiates for baked-map fade contract")
	if player == null:
		return
	root.add_child(player)
	await process_frame
	player.set_baked_map_overlap(true, 0.44, true)
	var ghost := player.get_node_or_null("BuildingOverlapGhost") as Sprite2D
	_check(is_equal_approx(player.sprite.modulate.a, 0.44), "baked building zone fades only the base player")
	_check(ghost != null and not ghost.visible, "baked building zone does not add a duplicate foreground building/ghost")
	player.set_baked_map_overlap(false, 0.44, true)
	_check(is_equal_approx(player.sprite.modulate.a, 1.0), "player opacity restores after leaving baked roof")
	player.free()


func _validate_actor_foot_depth_sort() -> void:
	var player_scene := load("res://scenes/player.tscn") as PackedScene
	var npc_scene := load("res://scenes/npc_node.tscn") as PackedScene
	var player := player_scene.instantiate() as Player if player_scene != null else null
	var npc := npc_scene.instantiate() as NPCNode if npc_scene != null else null
	_check(player != null and npc != null, "player and NPC actors instantiate for depth sorting")
	if player == null or npc == null:
		if player != null:
			player.free()
		if npc != null:
			npc.free()
		return
	root.add_child(player)
	root.add_child(npc)
	player.position = Vector2(600, 420)
	npc.position = Vector2(600, 520)
	await process_frame
	player.refresh_depth_sort()
	npc.refresh_depth_sort()
	_check(npc.z_index > player.z_index, "actor with lower visible feet renders in front")
	player.position = Vector2(600, 580)
	player.refresh_depth_sort()
	_check(player.z_index > npc.z_index, "player renders in front only after walking below NPC feet")
	player.free()
	npc.free()


func _validate_npc_visual_clearance(scene_id: String, layout: WalkableMapLayout) -> void:
	var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
	_check(scene != null, "%s scene loads for NPC occlusion audit" % scene_id)
	if scene == null or layout == null:
		return
	for raw_npc: Variant in scene.npcs:
		var npc: Dictionary = raw_npc as Dictionary
		var sprite_path := String(npc.get("sprite_path", ""))
		var texture := load(sprite_path) as Texture2D if ResourceLoader.exists(sprite_path) else null
		if texture == null:
			continue
		var frame_extent := float(texture.get_height()) * float(npc.get("scale", 1.0)) * scene.npc_visual_scale
		var center := npc.get("pos", Vector2.ZERO) as Vector2
		var half_size := Vector2(frame_extent / 1920.0, frame_extent / 1080.0) * 0.5
		var visual_rect := Rect2(center - half_size, half_size * 2.0)
		var visual_polygon := PackedVector2Array([
			visual_rect.position,
			Vector2(visual_rect.end.x, visual_rect.position.y),
			visual_rect.end,
			Vector2(visual_rect.position.x, visual_rect.end.y),
		])
		for raw_occluder: Variant in layout.occluders:
			var occluder: Dictionary = raw_occluder as Dictionary
			var cover: PackedVector2Array = occluder.get("cover_polygon", PackedVector2Array())
			var overlap := Geometry2D.intersect_polygons(visual_polygon, cover)
			_check(overlap.is_empty(), "%s NPC %s is clear of occluder %s" % [scene_id, String(npc.get("npc_id", "")), String(occluder.get("id", ""))])


func _all_normalized(points: PackedVector2Array) -> bool:
	for point in points:
		if point.x < 0.0 or point.x > 1.0 or point.y < 0.0 or point.y > 1.0:
			return false
	return true


func _fade_region_has_reachable_ground(points: PackedVector2Array, layout: WalkableMapLayout) -> bool:
	if points.size() < 3:
		return false
	var bounds := _polygon_bounds(points)
	for x_index in range(1, 8):
		for y_index in range(1, 8):
			var sample := Vector2(
				lerpf(bounds.position.x, bounds.end.x, float(x_index) / 8.0),
				lerpf(bounds.position.y, bounds.end.y, float(y_index) / 8.0)
			)
			if not Geometry2D.is_point_in_polygon(sample, points):
				continue
			if not _inside_any_walkable(sample, layout.walkable_regions):
				continue
			if not _inside_any_blocker(sample, layout.blockers):
				return true
	return false


func _polygon_bounds(points: PackedVector2Array) -> Rect2:
	var bounds := Rect2(points[0], Vector2.ZERO)
	for point in points:
		bounds = bounds.expand(point)
	return bounds


func _inside_any_walkable(point: Vector2, regions: Array[PackedVector2Array]) -> bool:
	for region in regions:
		if Geometry2D.is_point_in_polygon(point, region):
			return true
	return false


func _inside_any_blocker(point: Vector2, blockers: Array[Dictionary]) -> bool:
	for blocker in blockers:
		var pos: Vector2 = blocker.get("pos", Vector2.ZERO)
		var size: Vector2 = blocker.get("size", Vector2.ZERO)
		if Rect2(pos - size * 0.5, size).has_point(point):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	_checked += 1
	if condition:
		return
	_failed += 1
	push_error("[DynamicOccluderValidation] %s" % message)
