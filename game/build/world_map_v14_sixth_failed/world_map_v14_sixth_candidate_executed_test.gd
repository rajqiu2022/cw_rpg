extends SceneTree

## Complete production-world acceptance, not the native-pair development lab.
## Only this new test owns fixtures, isolated JSON slots, logs and screenshots.
## The implementation owner must finish the manifest/production bindings first.
const WORLD_ID := &"world_map_jianghu"
const WORLD_PATH := "res://data/scenes/world_map_jianghu.tres"
const CANDIDATE_ID := &"world_map_jianghu_v14"
const CANDIDATE_PATH := "res://data/scenes/world_map_jianghu_v14.tres"
const LEGACY_PATH := "res://data/maps/world_map_jianghu_legacy_v12_scene.tres"
const LEGACY_SHA := "09fa89449b1792063e66ad488aa2f60671aa00da2193e5c68acb861df14d71d5"
const FROZEN_PATH := "res://build/world_map_v14_previous_403_frozen.json"
const SOURCE_PATH := "res://art/maps/world_map_v14/source_contract.json"
const ART_DIR := "res://art/maps/world_map_v14/"
const MANIFEST_PATH := ART_DIR + "manifest.json"
const OUTPUT_DIR := "res://build/world_map_v14_qa/"
const WORLD_SIZE := Vector2(4608, 3072)
const TILE_SIZE := Vector2i(1536, 1024)
const ISOLATED_MANAGER_PATH := "res://tests/isolated_permanent_resource_save_20260910.gd"
const EXPECTED_DESTINATIONS := {
	"yanmen_pass": "openworld_yanmen_pass", "huashan": "openworld_huashan_forecourt",
	"wudang": "openworld_wudang_gate", "gufeng": "ch5_s1_relief_road",
	"lingyue": "ch2_s4_lingyue_gate", "bianzhou": "openworld_bianzhou_city",
	"linxi_village": "linxi_village_scrollmap", "luoyang": "ch4_s0_luoyang_gate",
	"xiangzhou": "openworld_xiangzhou_city", "east_sea_port": "openworld_east_sea_port",
	"bailu_ferry": "openworld_bailu_ferry", "zhuwei_village": "ch1_s2_qingfeng",
	"qinghe_town": "openworld_qinghe_town", "jinling": "openworld_jinling_city",
	"mingwu": "ch7_s2_mingwu_tea_town", "lieyun_valley": "ch7_s1_lieyun_valley_ferry",
}

var checks := 0
var failed := 0
var captures := 0
var full_foot_samples := 0
var field: Node
var world: SceneScript
var manifest: Dictionary
var native_images: Dictionary
var player_saves_before: Dictionary
var prior_navigation: Dictionary
var isolated_slots: Node
var isolated_dir: String
var schema_ready := false
var candidate_stage := false
var active_id: StringName
var active_path: String
var source_contract: Dictionary
var pathfinder: FullFootPlanningGrid
var portal_input_count := 0
var seam_input_count := 0
var raw_added_support_pixels := 0
var terrain_rejected_water := 0
var runtime_portals: Dictionary
var runtime_props: Dictionary
var world_pathfinder: FullFootPlanningGrid
var phase_output := ""
var height_samples := PackedFloat32Array()
var terrain_cols := 0
var terrain_rows := 0
var terrain_vertices := PackedVector3Array()
var terrain_uvs := PackedVector2Array()
var terrain_indices := PackedInt32Array()
var support_geometry_cache: Dictionary = {}
var derived_mesh_cache: Dictionary = {}
var original_model_cache: Dictionary = {}
var raw_foot_oracles: Dictionary = {}
var ghost_positive := 0
var ghost_south_positive := 0
var ghost_front_inactive := 0
var performance_samples: Array = []
var source_alpha_rects: Dictionary = {}
var qa_scope := "FULL_WORLD_MAP_PRODUCTION"

class FullFootPlanningGrid extends RefCounted:
	# The graph admits an edge only after independent <=4px full-foot checks.
	# This remains planning, never proof of actual Player/input traversal.
	var graph := AStar2D.new()
	var region: Rect2i
	var cell_size := Vector2(16,16)
	var offset := Vector2(8,8)
	var rejected_edges := 0
	func _id(point: Vector2i) -> int:
		return point.y * region.size.x + point.x
	func is_in_boundsv(point: Vector2i) -> bool:
		return region.has_point(point)
	func is_point_solid(point: Vector2i) -> bool:
		return not graph.has_point(_id(point))
	func get_point_position(point: Vector2i) -> Vector2:
		return Vector2(point) * cell_size + offset
	func get_point_path(from: Vector2i, to: Vector2i) -> PackedVector2Array:
		return graph.get_point_path(_id(from),_id(to))
	func build(size: Vector2, safe_foot: Callable) -> void:
		region = Rect2i(0,0,int(size.x / cell_size.x),int(size.y / cell_size.y))
		for y in region.size.y:
			for x in region.size.x:
				var point := Vector2i(x,y)
				var pixel := get_point_position(point)
				if bool(safe_foot.call(pixel)): graph.add_point(_id(point),pixel)
		for y in region.size.y:
			for x in region.size.x:
				var point := Vector2i(x,y)
				if is_point_solid(point): continue
				for direction: Vector2i in [Vector2i.RIGHT,Vector2i.DOWN]:
					var neighbor := point + direction
					if not is_in_boundsv(neighbor) or is_point_solid(neighbor): continue
					var start := get_point_position(point)
					var finish := get_point_position(neighbor)
					var steps := maxi(1,int(ceil(start.distance_to(finish)/4.0)))
					var clear := true
					for i in range(1,steps):
						if not bool(safe_foot.call(start.lerp(finish,float(i)/steps))): clear = false; break
					if clear: graph.connect_points(_id(point),_id(neighbor),true)
					else: rejected_edges += 1

func _effective_z(item: CanvasItem) -> int:
	var result := 0
	var node: Node = item
	while node is CanvasItem:
		result += (node as CanvasItem).z_index
		if not (node as CanvasItem).z_as_relative: break
		node = node.get_parent()
	return result

func _sprite_frame(sprite: Sprite2D, image: Image) -> Rect2i:
	var base := Rect2i(sprite.region_rect) if sprite.region_enabled else Rect2i(Vector2i.ZERO, image.get_size())
	var cell := Vector2i(base.size.x / sprite.hframes, base.size.y / sprite.vframes)
	return Rect2i(base.position + sprite.frame_coords * cell, cell)

func _alpha_bounds_world_local(sprite: Sprite2D) -> Rect2:
	# Bounds come from original current-frame nontransparent source pixels, not
	# the generated ghost. Return WORLD_LOCAL, never mix global camera offsets
	# with authored feet. Wholecanvas ground shadow is not a foreground prop.
	var image := sprite.texture.get_image()
	if image.is_compressed(): image.decompress()
	var frame := _sprite_frame(sprite, image)
	var key := "%d:%s" % [sprite.texture.get_instance_id(), str(frame)]
	if not source_alpha_rects.has(key):
		source_alpha_rects[key] = image.get_region(frame).get_used_rect()
	var used: Rect2i = source_alpha_rects[key]
	if used.size.x <= 0 or used.size.y <= 0: return Rect2()
	var uv := Rect2(Vector2(used.position) / Vector2(frame.size), Vector2(used.size) / Vector2(frame.size))
	if sprite.flip_h: uv.position.x = 1.0 - uv.end.x
	if sprite.flip_v: uv.position.y = 1.0 - uv.end.y
	var render := sprite.get_rect()
	var rect := Rect2(render.position + uv.position * render.size, uv.size * render.size)
	var container: Node2D = field.get("world_container")
	var result := Rect2(container.to_local(sprite.to_global(rect.position)), Vector2.ZERO)
	for corner: Vector2 in [rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]:
		result = result.expand(container.to_local(sprite.to_global(corner)))
	return result

func _ghost_mask_check(label: String) -> Dictionary:
	# Independently sample ORIGINAL current-frame alpha; never use the generated
	# ghost image/count to classify artwork or decide which prop pixels are solid.
	var player: Node2D = field.get("_player")
	var actor: Sprite2D = player.get("sprite")
	var source := actor.texture.get_image()
	if source.is_compressed(): source.decompress()
	var frame := _sprite_frame(actor, source)
	var expected := Image.create(frame.size.x, frame.size.y, false, Image.FORMAT_RGBA8)
	expected.fill(Color.TRANSPARENT)
	var props: Array = []
	var container: Node2D = field.get("world_container")
	var actor_z := _effective_z(actor)
	var highest := 449
	for d: Dictionary in world.map_layout.visual_objects:
		var id := String(d.get("id", ""))
		if not bool(d.get("sort_by_feet", false)) or not runtime_props.has(id): continue
		var prop: Sprite2D = runtime_props[id]
		if not prop.is_visible_in_tree() or _effective_z(prop) <= actor_z: continue
		if container.to_global(Vector2(0, float(d.get("depth_sort_foot_y", 0)) * WORLD_SIZE.y)).y <= float(player.call("get_depth_sort_y")): continue
		var image := prop.texture.get_image()
		if image.is_compressed(): image.decompress()
		props.append({"sprite": prop, "image": image, "frame": _sprite_frame(prop, image)})
	var count := 0
	for y in frame.size.y:
		for x in frame.size.x:
			if source.get_pixelv(frame.position + Vector2i(x, y)).a == 0: continue
			var uv := Vector2(x + .5, y + .5) / Vector2(frame.size)
			if actor.flip_h: uv.x = 1.0 - uv.x
			if actor.flip_v: uv.y = 1.0 - uv.y
			var world_pixel := actor.to_global(actor.get_rect().position + uv * actor.get_rect().size)
			var uncovered := 1.0
			for item: Dictionary in props:
				var prop: Sprite2D = item.sprite
				var local := prop.to_local(world_pixel)
				var rect := prop.get_rect()
				if not rect.has_point(local): continue
				var puv := (local - rect.position) / rect.size
				var alpha := _prop_sample_alpha(prop, item.image, puv)
				uncovered *= 1.0 - alpha
				if alpha > 0: highest = maxi(highest, _effective_z(prop))
			if uncovered < 1.0:
				expected.set_pixel(x, y, Color(1, 1, 1, 1.0 - uncovered))
				count += 1
	# Refresh synchronously: a frame advance would compare a different idle
	# source crop against the independently reconstructed previous frame.
	field.call("_update_dynamic_occluders", player.position / WORLD_SIZE, true)
	var debug: Dictionary = field.call("get_v14_modular_overlap_debug")
	var mask := debug.get("mask_image") as Image
	_check(mask != null and mask.get_size() == frame.size and debug.get("frame_rect") == frame and debug.get("space") == "actor_frame", "actual ghost uses current cropped sprite frame/local space: " + label)
	var mismatches := 0
	if mask != null and mask.get_size() == frame.size:
		for y in frame.size.y:
			for x in frame.size.x:
				if absf(mask.get_pixel(x, y).a - expected.get_pixel(x, y).a) > 1.01 / 255: mismatches += 1
	_check(mismatches == 0 and int(debug.get("pixels", -1)) == count and bool(debug.get("active", false)) == (count > 0), "independent full-current-frame alpha union matches ghost: %s bad=%d count=%d" % [label, mismatches, count])
	var ghost := player.get_node("BuildingOverlapGhost") as Sprite2D
	_check(ghost.visible == (count > 0), "actual ghost visibility equals independently sampled entity alpha: " + label)
	if count > 0:
		_check(not ghost.z_as_relative and ghost.z_index > highest and int(debug.get("ghost_z", -1)) > highest, "actual ghost draws above real southern or northern occluders: " + label)
		ghost_positive += 1
		if player.position.y > 2048: ghost_south_positive += 1
	return {"pixels": count, "frame": frame, "debug": debug}

func _vec3(value: Variant) -> Vector3:
	if value is Array and value.size() == 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2]))
	return Vector3(INF, INF, INF)

func _global_sprite_bounds(sprite: Sprite2D) -> Rect2:
	var rect := sprite.get_rect()
	var result := Rect2(sprite.to_global(rect.position), Vector2.ZERO)
	for local in [rect.end, rect.position + Vector2(rect.size.x, 0), rect.position + Vector2(0, rect.size.y)]:
		result = result.expand(sprite.to_global(local))
	return result

func _prop_sample_alpha(sprite: Sprite2D, image: Image, uv: Vector2) -> float:
	if uv.x < 0 or uv.y < 0 or uv.x >= 1 or uv.y >= 1: return 0.0
	if sprite.flip_h: uv.x = 1.0 - uv.x
	if sprite.flip_v: uv.y = 1.0 - uv.y
	var frame := _sprite_frame(sprite, image)
	if sprite.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR:
		var pixel := frame.position + Vector2i(clampi(int(uv.x * frame.size.x), 0, frame.size.x - 1), clampi(int(uv.y * frame.size.y), 0, frame.size.y - 1))
		return image.get_pixelv(pixel).a * sprite.modulate.a * sprite.self_modulate.a
	# Real linear filtering uses four texture texels, including adjacent atlas
	# frame texels; only the outer non-repeating texture boundary is clamped.
	var pixel := Vector2(frame.position) + uv * Vector2(frame.size) - Vector2(.5, .5)
	var x := floori(pixel.x)
	var y := floori(pixel.y)
	var weights := pixel - Vector2(x, y)
	var alpha := 0.0
	for dy in 2:
		for dx in 2:
			var weight := (weights.x if dx == 1 else 1.0 - weights.x) * (weights.y if dy == 1 else 1.0 - weights.y)
			alpha += image.get_pixel(clampi(x + dx, 0, image.get_width() - 1), clampi(y + dy, 0, image.get_height() - 1)).a * weight
	return alpha * sprite.modulate.a * sprite.self_modulate.a

func _movement_axis(center: Vector2) -> Vector2:
	var axis := Vector2.ZERO
	for candidate in [Vector2(6, 0), Vector2(0, 6)]:
		var clear := true
		for point: Vector2 in _dense_polyline([center - candidate, center + candidate]):
			if not _foot_clear(point): clear = false
		if clear:
			axis = candidate.normalized()
			break
	return axis

func _independent_foreground_candidate_count() -> int:
	var player: Node2D = field.get("_player")
	var actor: Sprite2D = player.get("sprite")
	var container: Node2D = field.get("world_container")
	var bounds := _global_sprite_bounds(actor)
	var count := 0
	for d: Dictionary in world.map_layout.visual_objects:
		var id := String(d.get("id", ""))
		if not bool(d.get("sort_by_feet", false)) or not runtime_props.has(id): continue
		var prop: Sprite2D = runtime_props[id]
		if not prop.is_visible_in_tree() or prop.texture == null or _effective_z(prop) <= _effective_z(actor): continue
		if container.to_global(Vector2(0, float(d.get("depth_sort_foot_y", 0)) * WORLD_SIZE.y)).y <= float(player.call("get_depth_sort_y")): continue
		if bounds.intersects(_global_sprite_bounds(prop)): count += 1
	return count

func _movement_frame_sample(center: Vector2, label: String) -> void:
	var axis := _movement_axis(center)
	_check(axis != Vector2.ZERO, "actual performance station has a legal movement corridor: " + label)
	if DisplayServer.get_name() == "headless": return
	if axis == Vector2.ZERO or not await _place_fixture(center): return
	await _ghost_mask_check("performance station independent current-frame alpha: " + label)
	var candidate_count := _independent_foreground_candidate_count()
	_check(int(field.call("get_v14_modular_overlap_debug").get("candidate_count", -1)) == candidate_count, "performance helper candidate count independently matches live foreground broadphase: " + label)
	var samples: Array[float] = []
	var direction := 1.0
	var bad := 0
	var start := Time.get_ticks_usec()
	var player: Node2D = field.get("_player")
	var initial := player.position
	var distance := 0.0
	var candidate_counts: Array[int] = []
	var union_counts: Array[int] = []
	var observed_positions: Array[Vector2] = []
	for tick in range(240):
		if (player.position - center).dot(axis) > 4: direction = -1
		elif (player.position - center).dot(axis) < -4: direction = 1
		_release_movement()
		Input.action_press(("move_right" if direction > 0 else "move_left") if axis.x != 0 else ("move_down" if direction > 0 else "move_up"), .60)
		var previous := player.position
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append(float(now - start) / 1000.0)
		start = now
		distance += previous.distance_to(player.position)
		observed_positions.append(player.position)
		var debug: Dictionary = field.call("get_v14_modular_overlap_debug")
		union_counts.append(int(debug.get("pixels", 0)))
		candidate_counts.append(int(debug.get("candidate_count", -1)))
	_release_movement()
	# Verify every observed actual position AFTER the timed 240-frame window.
	# This avoids source-mask/17ellipse work contaminating the next frame interval.
	for position: Vector2 in observed_positions:
		if not _foot_clear(position): bad += 1
	samples.sort()
	var report := {"label": label, "frames": samples.size(), "median_ms": samples[samples.size() / 2], "p95_ms": samples[floori(samples.size() * .95)], "max_ms": samples.back(), "actual_distance_px": distance, "distance_semantics": "cumulative oscillating input travel, not net displacement", "net_displacement_px": initial.distance_to(player.position), "start_px": [initial.x, initial.y], "end_px": [player.position.x, player.position.y], "full_foot_bad": bad, "foreground_candidate_counts": candidate_counts, "actual_union_pixel_counts": union_counts, "qualification": "actual GPU process intervals including rendering; independent candidate/alpha reconstruction before timed window, counts during window read from actual helper; producer review required, no arbitrary threshold"}
	performance_samples.append(report)
	print("[WorldV14Performance] " + JSON.stringify(report))
	_check(distance > 0 and bad == 0, "real movement remains stable during GPU frame sampling: " + label)

func _ghost_negative_and_performance() -> void:
	var player: Node2D = field.get("_player")
	var no_alpha := Vector2(INF, INF)
	var empty := Vector2(INF, INF)
	var near_city := Vector2(INF, INF)
	for d: Dictionary in world.map_layout.visual_objects:
		if not d.has("portal_id") or not runtime_props.has(String(d.get("id"))): continue
		var prop: Sprite2D = runtime_props[String(d.get("id"))]
		var bounds := _alpha_bounds_world_local(prop)
		var base_y := float(d.get("depth_sort_foot_y", 0)) * WORLD_SIZE.y
		for y in range(floori(base_y) - 96, floori(base_y) - 8, 8):
			if no_alpha.is_finite(): break
			for x in range(floori(bounds.position.x) - 24, ceili(bounds.end.x) + 24, 12):
				var point := Vector2(x, y)
				if not _foot_clear(point): continue
				player.position = point
				player.call("refresh_depth_sort")
				_set_idle(Vector2.RIGHT)
				var actor: Sprite2D = player.get("sprite")
				if _effective_z(prop) <= _effective_z(actor) or not bounds.intersects(_alpha_bounds_world_local(actor)): continue
				if _actual_actor_alpha_intersection(prop) != 0: continue
				field.call("_update_dynamic_occluders", point / WORLD_SIZE, true)
				if bool(field.call("get_v14_modular_overlap_debug").get("active", false)): continue
				no_alpha = point
				break
		if String(d.get("id")) in ["bianzhou_landmark","luoyang_landmark","xiangzhou_landmark","jinling_landmark"] and not near_city.is_finite():
			var station := _prop_alpha_station(d, prop, false, 1, true)
			if not station.is_empty(): near_city = station.point
		if no_alpha.is_finite() and near_city.is_finite(): break
	_check(no_alpha.is_finite(), "real prop AABB overlap but source-alpha-transparent legal behind station exists")
	if no_alpha.is_finite() and await _place_fixture(no_alpha):
		_set_idle(Vector2.RIGHT)
		var result := await _ghost_mask_check("transparent source inside real city sprite AABB")
		_check(int(result.pixels) == 0, "transparent sprite rectangle overlap does not activate fade")
		await _capture("ghost_transparent_rectangle")
	for route: Dictionary in source_contract.get("routes", []):
		if empty.is_finite(): break
		for point: Vector2 in _dense_polyline(route.get("points_px", [])):
			if not _foot_clear(point): continue
			player.position = point
			player.call("refresh_depth_sort")
			_set_idle(Vector2.RIGHT)
			var actor: Sprite2D = player.get("sprite")
			var bounds := _alpha_bounds_world_local(actor)
			var overlap := false
			for d: Dictionary in world.map_layout.visual_objects:
				var id := String(d.get("id", ""))
				if not bool(d.get("sort_by_feet", false)) or not runtime_props.has(id): continue
				var prop: Sprite2D = runtime_props[id]
				if not prop.is_visible_in_tree() or _effective_z(prop) <= _effective_z(actor): continue
				var container: Node2D = field.get("world_container")
				if container.to_global(Vector2(0, float(d.get("depth_sort_foot_y", 0)) * WORLD_SIZE.y)).y <= float(player.call("get_depth_sort_y")): continue
				if bounds.intersects(_alpha_bounds_world_local(prop)) and _actual_actor_alpha_intersection(prop) > 0: overlap = true
			if not overlap:
				empty = point
				break
	_check(empty.is_finite(), "real no-prop source-alpha-negative movement station exists")
	if empty.is_finite() and await _place_fixture(empty):
		var result := await _ghost_mask_check("no-prop route")
		_check(int(result.pixels) == 0, "no-prop actual travelling frame never ghosts")
		await _movement_frame_sample(empty, "no_prop")
	_check(near_city.is_finite(), "near-city actual alpha-positive performance station exists")
	if near_city.is_finite(): await _movement_frame_sample(near_city, "near_city")
	await _dense_canopy_performance()

func _dense_canopy_performance() -> void:
	# Require real mature-tree source alpha on a complete-foot corridor; do not
	# reuse the old city measurements to claim new canopy performance.
	var mature_count := 0
	var station := {}
	var mature_props: Array[Sprite2D] = []
	var descriptors: Array[Dictionary] = []
	for d: Dictionary in world.map_layout.visual_objects:
		var id := String(d.get("id", ""))
		if not id.begins_with("native_") or id == "native_cast_shadow" or not runtime_props.has(id): continue
		var meta := _json(ART_DIR + "entities/" + id + ".json")
		if not meta.has("derived_mesh_recipe"): continue
		mature_count += 1
		mature_props.append(runtime_props[id])
		descriptors.append(d)
	_check(mature_count > 0, "new production map actually contains approved mature native LOD trees")
	var best_candidates := -1
	var player: Node2D = field.get("_player")
	for d: Dictionary in descriptors:
		var probe := _prop_alpha_station(d, runtime_props[String(d.id)], false, 1, true)
		if probe.is_empty(): continue
		player.position = probe.point
		player.call("refresh_depth_sort")
		_set_idle(probe.facing)
		var actor: Sprite2D = player.get("sprite")
		var count := 0
		for prop: Sprite2D in mature_props:
			if _effective_z(prop) > _effective_z(actor) and _global_sprite_bounds(actor).intersects(_global_sprite_bounds(prop)): count += 1
		if count > best_candidates:
			best_candidates = count
			station = probe
	if station.is_empty():
		print("[WorldV14CanopyPerformance] NO_LEGAL_ALPHA_POSITIVE_CANOPY_CORRIDOR; not measured, cannot claim canopy performance PASS")
		_check(false, "mature canopy needs actual legal full-foot alpha-positive movement corridor")
		return
	if await _place_fixture(station.point):
		_set_idle(station.facing)
		var alpha_positive_trees := 0
		for prop: Sprite2D in mature_props:
			if _effective_z(prop) > _effective_z(player.get("sprite")) and _actual_actor_alpha_intersection(prop) > 0: alpha_positive_trees += 1
		print("[WorldV14CanopyPerformance] bounded_best_mature_candidates=%d actual_currentframe_alpha_positive_trees=%d qualified_point=%s; fewer_than2_is_single_canopy_not_dense_group_proof" % [best_candidates, alpha_positive_trees, station.point])
		await _ghost_mask_check("mature tree actual legal canopy station")
		await _capture("mature_canopy_performance_station")
		await _movement_frame_sample(station.point, "dense_canopy_actual" if alpha_positive_trees >= 2 else "single_canopy_actual_dense_station_not_found")

func _collect_source_meshes(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null: meshes.append(node)
	for child: Node in node.get_children(): _collect_source_meshes(child, meshes)

func _height_at(point: Vector2) -> float:
	return float(_actual_terrain_triangle(point).get("height", NAN))

func _actual_terrain_triangle(point: Vector2) -> Dictionary:
	# Independent barycentric reconstruction from the stored GPU index/UV stream.
	# Neither the renderer's interpolation helper nor diagnostic brightness is used.
	if terrain_cols <= 0 or terrain_rows <= 0 or not point.is_finite(): return {}
	var uv := point / WORLD_SIZE
	if uv.x < 0 or uv.y < 0 or uv.x > 1 or uv.y > 1: return {}
	# Preserve the actual Vector2 grid transform at exact grid boundaries.
	# Scalar double multiplication after extracting a float32 UV can choose
	# the adjacent cell below an integer (the earlier herb-band failure mode).
	var grid_uv := uv * Vector2(terrain_cols, terrain_rows)
	var x := clampi(floori(grid_uv.x), 0, terrain_cols - 1)
	var y := clampi(floori(grid_uv.y), 0, terrain_rows - 1)
	var first := (y * terrain_cols + x) * 6
	if first + 5 >= terrain_indices.size(): return {}
	for offset in [0, 3]:
		var ia := terrain_indices[first + offset]
		var ib := terrain_indices[first + offset + 1]
		var ic := terrain_indices[first + offset + 2]
		var a := terrain_uvs[ia]
		var b := terrain_uvs[ib]
		var c := terrain_uvs[ic]
		var ab := b - a
		var ac := c - a
		var delta := uv - a
		var determinant := ab.cross(ac)
		if absf(determinant) < 1e-12: continue
		var wb := delta.cross(ac) / determinant
		var wc := ab.cross(delta) / determinant
		var wa := 1.0 - wb - wc
		if minf(wa, minf(wb, wc)) < -.0003: continue
		var va := terrain_vertices[ia]
		var vb := terrain_vertices[ib]
		var vc := terrain_vertices[ic]
		var normal := (vb - va).cross(vc - va)
		if absf(normal.y) < 1e-12: return {}
		return {"height": wa * va.y + wb * vb.y + wc * vc.y, "gradient": Vector2(-normal.x / normal.y, -normal.z / normal.y).length(), "indices": [ia, ib, ic]}
	return {}

func _array_sha(value: Variant) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(value.to_byte_array())
	return context.finish().hex_encode()

func _support_camera_project(vertex: Vector3, camera: Dictionary) -> Vector2:
	# Independently reproduce orthographic projection from actual captured pose.
	# This is not the builder's supported_height() or a bed-height clamp.
	var columns: Array = camera.get("actual_camera_basis_columns", [])
	var size := float(camera.get("actual_orthographic_size", 0))
	if columns.size() != 3 or size <= 0: return Vector2(INF, INF)
	var basis := Basis(_vec3(columns[0]), _vec3(columns[1]), _vec3(columns[2]))
	var local := basis.inverse() * (vertex - _vec3(camera.get("actual_camera_position")))
	return WORLD_SIZE * .5 + Vector2(local.x, -local.y) * (WORLD_SIZE.y / size)

func _source_xz_to_meters(point: Vector2, height: float) -> Vector3:
	var meters := _point(source_contract.get("camera", {}).get("world_meters"))
	return Vector3((point.x / WORLD_SIZE.x - .5) * meters.x, height, (point.y / WORLD_SIZE.y - .5) * meters.y)

func _triangle_height_in_source(point: Vector2, record: Dictionary) -> float:
	var vertices: PackedVector3Array = record.get("vertices", PackedVector3Array())
	var sources: PackedVector2Array = record.get("source_vertices", PackedVector2Array())
	var indices: PackedInt32Array = record.get("indices", PackedInt32Array())
	for first in range(0, indices.size(), 3):
		var a := sources[indices[first]]
		var b := sources[indices[first + 1]]
		var c := sources[indices[first + 2]]
		var determinant := (b - a).cross(c - a)
		if absf(determinant) < 1e-8: continue
		var wb := (point - a).cross(c - a) / determinant
		var wc := (b - a).cross(point - a) / determinant
		var wa := 1.0 - wb - wc
		if minf(wa, minf(wb, wc)) < -0.000001: continue
		return wa * vertices[indices[first]].y + wb * vertices[indices[first + 1]].y + wc * vertices[indices[first + 2]].y
	return NAN

func _actual_support_for_source(point: Vector2) -> Dictionary:
	for record: Dictionary in support_geometry_cache.values():
		var height := _triangle_height_in_source(point, record)
		if is_finite(height): return {"record": record, "height": height}
	return {}

func _actual_support_at_screen(point: Vector2, record: Dictionary) -> bool:
	var vertices: PackedVector2Array = record.get("projected_vertices", PackedVector2Array())
	var indices: PackedInt32Array = record.get("indices", PackedInt32Array())
	for first in range(0, indices.size(), 3):
		var a := vertices[indices[first]]
		var b := vertices[indices[first + 1]]
		var c := vertices[indices[first + 2]]
		var determinant := (b - a).cross(c - a)
		if absf(determinant) < 1e-8: continue
		var wb := (point - a).cross(c - a) / determinant
		var wc := (b - a).cross(point - a) / determinant
		if minf(1.0 - wb - wc, minf(wb, wc)) >= -0.000001: return true
	return false

func _structure_saved_mesh_checks() -> void:
	support_geometry_cache.clear()
	var entries: Array = source_contract.get("structure_entries", [])
	var meters := _point(source_contract.get("camera", {}).get("world_meters"))
	_check(meters.distance_to(Vector2(45, 42.42640687)) < .0001 and entries.size() == 5, "independent supports use same physical XZ scale and five actual deck meshes")
	if not meters.is_finite() or meters.x <= 0 or meters.y <= 0: return
	for entry: Dictionary in entries:
		var id := String(entry.get("id", ""))
		var path := String(entry.get("support_mesh_path", ""))
		var valid_path := path.begins_with(ART_DIR + "entities/support_") and path.ends_with(".res") and FileAccess.file_exists(path)
		_check(valid_path, "actual captured support mesh exists under candidate resource prefix: " + id)
		if not valid_path: continue
		_check(FileAccess.get_sha256(path).to_lower() == String(entry.get("support_mesh_sha256", "")).to_lower(), "saved support actual resource SHA bound: " + id)
		var mesh := load(path) as Mesh
		_check(mesh != null and mesh.get_surface_count() == 1, "support geometry is an actual saved native Mesh, not metadata rectangle: " + id)
		if mesh == null or mesh.get_surface_count() != 1: continue
		var arrays := mesh.surface_get_arrays(0)
		var local_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var position := _vec3(entry.get("support_node_position_m"))
		var camera: Dictionary = entry.get("support_capture_camera", {})
		var columns: Array = camera.get("actual_camera_basis_columns", [])
		var valid_camera := int(camera.get("actual_projection", -1)) == Camera3D.PROJECTION_ORTHOGONAL and absf(float(camera.get("actual_orthographic_size", 0)) - 30) < .0001 and _vec3(camera.get("actual_camera_position")).distance_to(Vector3(0, 20, 20)) < .0001 and columns.size() == 3
		if columns.size() == 3:
			valid_camera = valid_camera and _vec3(columns[0]).distance_to(Vector3.RIGHT) < .00001 and _vec3(columns[1]).distance_to(Vector3(0, 1, -1).normalized()) < .00001 and _vec3(columns[2]).distance_to(Vector3(0, 1, 1).normalized()) < .00001
		_check(valid_camera, "support projection reads actual full-map orthographic pose and basis: " + id)
		var valid_geometry := position.is_finite() and local_vertices.size() >= 4 and indices.size() >= 6 and indices.size() % 3 == 0 and absf(float(entry.get("deck_height_m", NAN))) < .000001
		for index in indices:
			if index < 0 or index >= local_vertices.size(): valid_geometry = false
		_check(valid_geometry, "native support has real triangle stream, finite identity-basis translation, explicit deckY0: " + id)
		if not valid_camera or not valid_geometry: continue
		var vertices := PackedVector3Array()
		var source_vertices := PackedVector2Array()
		var projected_vertices := PackedVector2Array()
		var flat := true
		var degenerate := 0
		for vertex: Vector3 in local_vertices:
			var actual := vertex + position
			vertices.append(actual)
			flat = flat and actual.is_finite() and absf(actual.y) < .000001
			source_vertices.append(Vector2((actual.x / meters.x + .5) * WORLD_SIZE.x, (actual.z / meters.y + .5) * WORLD_SIZE.y))
			projected_vertices.append(_support_camera_project(actual, camera))
		for first in range(0, indices.size(), 3):
			if (vertices[indices[first + 1]] - vertices[indices[first]]).cross(vertices[indices[first + 2]] - vertices[indices[first]]).length() < .000001: degenerate += 1
		_check(flat and degenerate == 0, "actual saved support triangles lie at sea-level independently of signed RF bed: " + id)
		var declared: Array = entry.get("source_deck_polygon", [])
		var hull := Geometry2D.convex_hull(source_vertices)
		var shape_equal := declared.size() == 4
		for corner: Variant in declared:
			var point := _point(corner)
			var nearest := INF
			for vertex: Vector2 in hull: nearest = minf(nearest, point.distance_to(vertex))
			shape_equal = shape_equal and nearest < .01
		var rect := _rect(entry.get("rect_px", []))
		var actual_rect := Rect2(projected_vertices[0], Vector2.ZERO)
		for point: Vector2 in projected_vertices: actual_rect = actual_rect.expand(point)
		shape_equal = shape_equal and actual_rect.position.distance_to(rect.position) < .01 and actual_rect.size.distance_to(rect.size) < .01
		_check(shape_equal, "declared source corners/runtime footprint reproduce independently projected actual saved vertices: " + id)
		if not flat or degenerate > 0 or not shape_equal: continue
		support_geometry_cache[id] = {"vertices": vertices, "source_vertices": source_vertices, "projected_vertices": projected_vertices, "indices": indices, "camera": camera, "entry": entry}
	_check(support_geometry_cache.size() == 5, "all five genuine support meshes independently validated before added-white pixel acceptance")
	for entry: Dictionary in entries:
		var source_passage: Array = entry.get("source_passage_px", [])
		var passage: Array = entry.get("passage_px", [])
		var same_count := source_passage.size() >= 2 and source_passage.size() == passage.size()
		_check(same_count, "source/deck-aware runtime passage pairing is explicit: " + String(entry.get("id")))
		if not same_count: continue
		var record: Dictionary = support_geometry_cache.get(String(entry.get("id")), {})
		if record.is_empty(): continue
		var deck_points := 0
		var bank_points := 0
		var projection_errors := 0
		for i in source_passage.size():
			var source := _point(source_passage[i])
			var actual_support := _actual_support_for_source(source)
			var height := float(actual_support.height) if not actual_support.is_empty() else _height_at(source)
			if actual_support.is_empty(): bank_points += 1
			var projected := _support_camera_project(_source_xz_to_meters(source, height), record.camera)
			if not projected.is_finite() or projected.distance_to(_point(passage[i])) >= .01: projection_errors += 1
		# Bridges intentionally publish just two bank controls. Their straight
		# continuous source segment crosses actual support between those controls.
		# Do not require a deck vertex to be explicitly inserted in that polyline.
		for source: Vector2 in _dense_polyline(source_passage):
			if is_finite(_triangle_height_in_source(source, record)): deck_points += 1
		_check(projection_errors == 0 and deck_points > 0 and bank_points > 0, "runtime passage uses actual deck triangles only inside support, signed bed triangle on dry approaches: %s bad=%d deck=%d bank=%d" % [entry.get("id"), projection_errors, deck_points, bank_points])

func _independent_derived_mesh(source: ArrayMesh, recipe: Dictionary) -> ArrayMesh:
	var path := String(recipe.get("derived_mesh_path", ""))
	if derived_mesh_cache.has(path): return derived_mesh_cache[path]
	_check(path.begins_with(ART_DIR + "entities/") and FileAccess.file_exists(path), "mature LOD is an actual separately stored production mesh")
	if not FileAccess.file_exists(path): return null
	_check(FileAccess.get_sha256(path).to_lower() == String(recipe.get("derived_mesh_sha256", "")).to_lower(), "derived actual LOD mesh SHA is independently bound")
	var derived := load(path) as ArrayMesh
	if derived == null: return null
	var importer := ImporterMesh.new()
	for surface in source.get_surface_count():
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, source.surface_get_arrays(surface), [], {}, source.surface_get_material(surface))
	# Executed only after art releases capture and producer approves headless.
	importer.generate_lods(60., 60., [])
	_check(source.get_surface_count() == derived.get_surface_count(), "LOD preserves actual source surface count")
	var records: Array = recipe.get("surfaces", [])
	var expected_mesh := ArrayMesh.new()
	var mixed_recipe := String(recipe.get("method", "")).contains("per-surface")
	var total_triangles := 0
	var source_triangles := 0
	for surface in source.get_surface_count():
		var original := source.surface_get_arrays(surface)
		var actual := derived.surface_get_arrays(surface)
		_check(surface < records.size(), "every actual mature mesh surface has an explicit recipe")
		if surface >= records.size(): continue
		var indices: PackedInt32Array = actual[Mesh.ARRAY_INDEX]
		var record: Dictionary = records[surface]
		var selected := int(record.get("lod_index", -99))
		var raw_source := selected == -1
		_check(not mixed_recipe or record.has("index_source"), "mixed production recipe explicitly declares every surface index source")
		_check(selected == 2 or raw_source, "only approved original surface or actual generated LOD2 is used")
		_check(int(record.get("selected_surface", record.get("surface", -1))) == surface, "recipe selected surface binds its actual surface")
		var expected: PackedInt32Array = original[Mesh.ARRAY_INDEX] if raw_source else PackedInt32Array()
		if not raw_source:
			_check(importer.get_surface_lod_count(surface) > selected and selected >= 0, "independent ImporterMesh supplies the explicitly selected level")
			if selected < 0 or importer.get_surface_lod_count(surface) <= selected: continue
			expected = importer.get_surface_lod_indices(surface, selected)
		if record.has("index_source"):
			_check(String(record.index_source) == ("source_lod0" if raw_source else "native_generated_lod"), "per-surface index source is honest")
			_check(raw_source == (surface == 1), "approved mixed recipe preserves original leaf cards, derives branch and trunk only")
		_check(indices.to_byte_array() == expected.to_byte_array() and indices.size() % 3 == 0, "stored draw indices equal independently selected source/native recipe: surface=%d" % surface)
		_check(_array_sha(indices) == String(record.get("indices_sha256", "")).to_lower() and int(record.get("actual_triangles", -1)) == indices.size() / 3, "recipe binds actual index stream and selected triangles")
		_check(absf(float(record.get("lod_distance", -1)) - (0.0 if raw_source else importer.get_surface_lod_size(surface, selected))) < .0001, "recorded distance belongs to actual selected surface")
		# Native ArrayMesh packing oct-encodes normals. Compare exact independently
		# re-packed streams, not decoded GLTF bytes and not an arbitrary tolerance.
		var control := original.duplicate()
		control[Mesh.ARRAY_INDEX] = expected
		expected_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, control)
		var repacked := expected_mesh.surface_get_arrays(surface)
		for attribute in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV]:
			_check(_array_sha(repacked[attribute]) == _array_sha(actual[attribute]), "index-only source attributes exactly match independent native packing: surface=%d attribute=%d" % [surface, attribute])
		total_triangles += indices.size() / 3
		source_triangles += original[Mesh.ARRAY_INDEX].size() / 3
	_check(source_triangles == int(recipe.get("original_triangles", -1)) and total_triangles > 0 and total_triangles < source_triangles, "actual native LOD reduces real draw triangles without inventing a simpler source model")
	derived_mesh_cache[path] = derived
	return derived

func _native_model_geometry(meta: Dictionary) -> void:
	var id := String(meta.get("id", ""))
	var source_path := String(meta.get("source", ""))
	var imported: Node
	var recipe: Dictionary = meta.get("derived_mesh_recipe", {})
	if original_model_cache.has(source_path):
		pass
	elif not recipe.is_empty() or source_path.contains("/pine_sapling_small/"):
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		var error := document.append_from_file(source_path, state)
		_check(error == OK, "original GLTF is independently parsed without trusting derived resource: " + id)
		if error == OK: imported = document.generate_scene(state)
	else:
		var packed := load(source_path) as PackedScene
		if packed != null: imported = packed.instantiate()
	if not original_model_cache.has(source_path):
		_check(imported != null, "registered original model can be independently read: " + id)
		if imported == null: return
		var nodes: Array[MeshInstance3D] = []
		_collect_source_meshes(imported, nodes)
		var originals: Array[Dictionary] = []
		for node: MeshInstance3D in nodes: originals.append({"mesh": node.mesh, "name": String(node.name)})
		original_model_cache[source_path] = originals
		imported.free()
	var meshes: Array = original_model_cache[source_path]
	var variant := int(meta.get("source_variant", -1))
	_check(variant >= 0 and variant < meshes.size(), "actual source variant is recorded and exists: " + id)
	if variant < 0 or variant >= meshes.size():
		return
	var basis := Basis(Vector3.UP, deg_to_rad(float(meta.get("yaw", 0)))) * Basis.from_scale(Vector3.ONE * float(meta.get("model_scale", 0)))
	var vertices := PackedVector3Array()
	var source_mesh := meshes[variant].mesh as ArrayMesh
	_check(String(meshes[variant].name) == String(meta.get("source_mesh_node", "")), "actual original mesh node matches captured variant: " + id)
	if not recipe.is_empty():
		_check(FileAccess.get_sha256(source_path).to_lower() == String(recipe.get("source_sha256", "")).to_lower(), "LOD recipe is bound to the original licensed GLTF")
		source_mesh = _independent_derived_mesh(source_mesh as ArrayMesh, recipe)
		if source_mesh == null:
			return
	for surface in source_mesh.get_surface_count():
		var attributes := source_mesh.surface_get_arrays(surface)
		var positions: PackedVector3Array = attributes[Mesh.ARRAY_VERTEX]
		var draw_indices: PackedInt32Array = attributes[Mesh.ARRAY_INDEX]
		var used: Dictionary = {}
		var invalid_indices := 0
		for index in draw_indices:
			if index < 0 or index >= positions.size(): invalid_indices += 1
			elif not used.has(index):
				used[index] = true
				vertices.append(basis * positions[index])
		_check(invalid_indices == 0 and not used.is_empty(), "actual selected draw indices have valid referenced geometry: " + id)
	var bounds := AABB()
	for i in vertices.size():
		bounds = AABB(vertices[i], Vector3.ZERO) if i == 0 else bounds.expand(vertices[i])
	var support := AABB()
	var first := true
	for vertex: Vector3 in vertices:
		if vertex.y > bounds.position.y + bounds.size.y * .06: continue
		support = AABB(vertex, Vector3.ZERO) if first else support.expand(vertex)
		first = false
	var source_foot := _point(meta.get("source_foot"))
	var height := _height_at(source_foot)
	var ground := Vector3((source_foot.x / WORLD_SIZE.x - .5) * 45.0, height, (source_foot.y / WORLD_SIZE.y - .5) * 42.42640687)
	var contact := Vector3(support.get_center().x, bounds.position.y, support.end.z)
	var position := _vec3(meta.get("model_position_m"))
	_check(not first and vertices.size() == int(meta.get("actual_vertex_count", -1)), "actual unique draw-referenced vertices, not unused LOD0 vertices, determine support: " + id)
	var captured_bounds: Array = meta.get("actual_transformed_bounds", [])
	_check(captured_bounds.size() == 6 and _vec3(captured_bounds.slice(0, 3)).distance_to(bounds.position) < .0001 and _vec3(captured_bounds.slice(3, 6)).distance_to(bounds.size) < .0001, "actual selected draw-vertex bounds independently match export: " + id)
	var extent := 0.0
	for corner in 8:
		var relative := bounds.get_endpoint(corner) - contact
		extent = maxf(extent, maxf(absf(relative.x * 102.4), absf((relative.z - relative.y) / sqrt(2.0) * 102.4)))
	var expected_canvas := maxi(512, int(ceil((extent * 2.0 + 32.0) / 256.0)) * 256)
	_check(_point(meta.get("sourcebody_canvas")).distance_to(Vector2(expected_canvas, expected_canvas)) < .01, "dynamic body canvas is independently sufficient for actual selected draw geometry under captured camera: " + id)
	_check(position.is_finite() and position.distance_to(ground - contact) < .0001, "independent GLTF real-vertex support anchor equals captured model transform: " + id)
	_check(_vec3(meta.get("ground_m")).distance_to(ground) < .0001 and _vec3(meta.get("support_contact_m")).distance_to(contact) < .0001, "recorded ground and support are independently reconstructed: " + id)
	_check(absf(position.y + bounds.position.y - ground.y) < .0001, "actual lowest source vertex sits on actual terrain, not AABB corner or metadata zero: " + id)
	var projection := Vector2(source_foot.x, source_foot.y - height * WORLD_SIZE.y / 30.0 / sqrt(2.0))
	_check(_point(meta.get("world_foot")).distance_to(projection) < .01, "actual model foot follows same camera terrain projection: " + id)

func _front_wall_semantic_checks() -> void:
	# Independently inspected ORIGINAL closed-city source, not samples generated
	# from its own collider. Roof alpha is not mistaken for an occupied floor.
	var closed_city_points := [Vector2(.28, .71), Vector2(.49, .75), Vector2(.68, .75), Vector2(.51, .41)]
	for site: Dictionary in source_contract.get("landmark_sources", []):
		var id := String(site.get("id", ""))
		var source_path := String(site.get("source", ""))
		_check(FileAccess.file_exists(source_path) and FileAccess.get_sha256(source_path).to_lower() == String(site.get("source_sha256", "")).to_lower(), "landmark original source exists with immutable SHA: " + id)
		var object: Dictionary = {}
		for d: Dictionary in world.map_layout.visual_objects:
			if String(d.get("portal_id", "")) == id: object = d
		_check(not object.is_empty(), "each actual portal owns an independent physical landmark: " + id)
		if object.is_empty(): continue
		var probes: Array = site.get("solid_ground_probes", []).duplicate(true)
		if source_path.ends_with("city_walled_compound_proto_v1.png"):
			for uv: Vector2 in closed_city_points: probes.append({"source_uv": uv, "semantic": "independently inspected closed front masonry/door and inner city"})
		_check(not probes.is_empty(), "all 16 source landmarks have real ground-solid semantic evidence, not collider center only: " + id)
		var original := _read_image(source_path)
		var center := _point(object.get("pos")) * WORLD_SIZE
		var size := _point(object.get("render_size_px"))
		for probe: Dictionary in probes:
			var uv := _point(probe.get("source_uv"))
			_check(uv.is_finite() and uv.x >= 0 and uv.x < 1 and uv.y >= 0 and uv.y < 1, "semantic source ground point is inside actual source canvas: " + id)
			if original == null or not uv.is_finite(): continue
			var point := center + (uv - Vector2(.5, .5)) * size
			_check(original.get_pixelv(Vector2i(uv * Vector2(original.get_size()))).a > .12, "source solid-ground witness has real entity alpha: " + id + " " + str(uv))
			if probe.has("world_px"):
				_check(point.distance_to(_point(probe.get("world_px"))) < .01, "source front-wall witness follows actual runtime sprite transform: " + id)
			_check(not _foot_clear(point), "closed wall/internal city cannot be entered by feet on world layer: " + id + " " + str(point))
		# Gate foot is an independent positive, not erased to make the city solid.
		for p: Dictionary in world.map_layout.portals:
			if String(p.get("id")) == id:
				_check(_foot_clear(_point(p.get("pos")) * WORLD_SIZE), "wall blocking preserves actual gate standing/interaction feet: " + id)
		var collision := Rect2(_point(site.get("collision_center_px")) - _point(site.get("collision_size_px")) * .5, _point(site.get("collision_size_px")))
		var entry := _point(site.get("outside_entry_px"))
		_check(collision.has_area() and _foot_clear(entry), "actual registered city/landmark ground and entry are usable: " + id)
		if not collision.has_area() or not _foot_clear(entry): continue
		if await _place_fixture(entry):
			Input.action_press("move_up", 1.0)
			var invaded := 0
			for tick in range(60):
				await physics_frame
				var moving: Node2D = field.get("_player")
				if collision.has_point(moving.position) or not _foot_clear(moving.position): invaded += 1
			_release_movement()
			var stopped: Node2D = field.get("_player")
			_check(invaded == 0 and stopped.position.y > collision.end.y, "actual gate-front continuous UP input stops outside front wall rather than walking into courtyard: %s bad=%d foot=%s" % [id, invaded, stopped.position])
			await _capture("wall_stop_" + id)
		# One lawful LAND-side bypass is sufficient; sea-side entry buildings
		# must not be promised a second impossible path over water.
		var margin := WORLD_SIZE * .004 + Vector2(13, 9)
		var bypass: Array = []
		for side in [-1, 1]:
			var x := collision.position.x - margin.x if side < 0 else collision.end.x + margin.x
			var path := [Vector2(x, collision.end.y + margin.y), Vector2(x, collision.get_center().y), Vector2(x, collision.position.y - margin.y)]
			var legal := true
			for foot: Vector2 in _dense_polyline(path):
				if not _foot_clear(foot): legal = false
			if legal:
				bypass = path
				break
		if bypass.is_empty() and world_pathfinder != null:
			# The approved alternative is an actual curved LAND-side route, not
			# a demand to walk through sea/ridge around a rectangular landmark.
			# Still reach a lateral point at/behind its middle, then validate the
			# entire path at <=4px before executing real movement input.
			var best_length := INF
			for side in [-1, 1]:
				for extra in [0, 32, 64, 128, 192]:
					var x: float = collision.position.x - margin.x - extra if side < 0 else collision.end.x + margin.x + extra
					for y in range(ceili(collision.position.y - margin.y), floori(collision.get_center().y) + 1, 16):
						var target := Vector2(x, y)
						if not _foot_clear(target): continue
						var path := _plan_to(target, world_pathfinder)
						if path.size() < 2: continue
						var legal := true
						var length := 0.0
						for index in range(path.size() - 1): length += path[index].distance_to(path[index + 1])
						if length >= best_length or length > 3000: continue
						for foot: Vector2 in _dense_polyline(path):
							if not _foot_clear(foot):
								legal = false
								break
						if legal:
							bypass = path
							best_length = length
		_check(not bypass.is_empty(), "at least one real land-side full-foot landmark bypass exists: " + id)
		if not bypass.is_empty() and await _place_fixture(_point(bypass.front())):
			await _input_path(bypass, "actual landmark land-side bypass: " + id)

func _bridge_source_semantics_checks() -> void:
	var source := _read_image(ART_DIR + "entities/bridge_stone_eastwest_v1.png")
	if source == null: return
	_check(source.get_size() == Vector2i(1774, 887), "EW source semantic witnesses refer to the actual independently inspected original canvas")
	var owned := PackedByteArray()
	owned.resize(source.get_width() * source.get_height())
	var parts: Array[Dictionary] = []
	var duplicate_pixels := 0
	var rgba_mismatches := 0
	for d: Dictionary in world.map_layout.visual_objects:
		var id := String(d.get("id", ""))
		if not id.begins_with("bridge_eastwest_") or not bool(d.get("sort_by_feet", false)): continue
		var mask := _read_image(String(d.get("texture")))
		if mask == null: continue
		_check(mask.get_size() == source.get_size() and mask.get_used_rect().has_area(), "EW separate physical silhouette is a nonempty original-canvas alpha layer: " + id)
		if mask.get_size() != source.get_size(): continue
		var actual_base := float(d.get("source_base_y", -1))
		var expected_base := -1.0
		if id.contains("post_"):
			var index := id.get_slice("post_", 1).to_int()
			var post_bottoms := [591, 590, 590, 590, 590, 594]
			if index >= 0 and index < post_bottoms.size(): expected_base = post_bottoms[index]
		elif id.contains("panel_"): expected_base = 607
		elif id.ends_with("fascia"): expected_base = 676
		var center := _point(d.get("pos")) * WORLD_SIZE
		var size := _point(d.get("render_size_px"))
		_check(expected_base >= 0 and absf(actual_base - expected_base) < .0001 and absf(float(d.get("depth_sort_foot_y", -1)) * WORLD_SIZE.y - (center.y + (expected_base / source.get_height() - .5) * size.y)) < .01, "EW each real post/panel/arch uses its independently inspected own source bottom, not shared Y: " + id)
		var used := mask.get_used_rect()
		for y in range(used.position.y, used.end.y):
			for x in range(used.position.x, used.end.x):
				var value := mask.get_pixel(x, y)
				if value.a == 0: continue
				var pixel := y * source.get_width() + x
				if owned[pixel] != 0: duplicate_pixels += 1
				owned[pixel] = 1
				if value != source.get_pixel(x, y): rgba_mismatches += 1
		parts.append({"id": id, "mask": mask, "layout": d})
	_check(parts.size() == 12 and duplicate_pixels == 0 and rgba_mismatches == 0, "all six posts/five panels/lower arches are unique source RGBA silhouettes: parts=%d duplicates=%d rgba_bad=%d" % [parts.size(), duplicate_pixels, rgba_mismatches])
	for point: Vector2i in [Vector2i(1000, 481), Vector2i(300, 481), Vector2i(900, 500)]:
		var alpha := 0.0
		for part: Dictionary in parts: alpha = maxf(alpha, (part.mask as Image).get_pixelv(point).a)
		_check(alpha == 0, "independently inspected EW walking floor is strictly excluded from all foreground layers: " + str(point))
	for point: Vector2i in [Vector2i(170, 495), Vector2i(727, 505), Vector2i(1603, 493), Vector2i(800, 556)]:
		var alpha := 0.0
		for part: Dictionary in parts: alpha = maxf(alpha, (part.mask as Image).get_pixelv(point).a)
		_check(source.get_pixelv(point).a > .12 and alpha > .12, "independently inspected EW post-cap/railing entity alpha is preserved rather than erased for floor tests: " + str(point))

func _structure_and_negative_checks() -> void:
	_bridge_source_semantics_checks()
	var supports: Array = source_contract.get("structure_entries", [])
	_check(supports.size() == 5, "three river bridges and two actual Bailu L-deck supports are declared")
	var deck_count := 0
	var driven: Dictionary = {}
	for entry: Dictionary in supports:
		var rect := _rect(entry.get("rect_px", []))
		var saved_support: Dictionary = support_geometry_cache.get(String(entry.get("id")), {})
		_check(not saved_support.is_empty(), "structure runtime checks require independently validated native support geometry")
		if saved_support.is_empty(): continue
		_check(rect.has_area(), "genuine structural deck support has positive native footprint")
		var vertical := rect.size.y > rect.size.x
		var passage: Array = entry.get("passage_px", [])
		_check(passage.size() >= 2, "structure publishes a real continuous approach/deck passage")
		if passage.size() < 2: continue
		var start := _point(passage.front())
		var finish := _point(passage.back())
		var samples := _dense_polyline(passage)
		var no_alpha := 0
		var bad_foot := 0
		var entity_overlap_samples := 0
		var on_water := 0
		var signed_wet_bed := 0
		var wet_bed_projection_separation := 0
		for source: Vector2 in _dense_polyline(entry.get("source_passage_px", [])):
			var deck_height := _triangle_height_in_source(source, saved_support)
			if not is_finite(deck_height): continue
			var bed_height := _height_at(source)
			var deck_point := _support_camera_project(_source_xz_to_meters(source, deck_height), saved_support.camera)
			if (native_images.land as Image).get_pixelv(Vector2i(deck_point)).r >= .5: continue
			if is_finite(bed_height) and bed_height < -.0001:
				signed_wet_bed += 1
				var bed_point := _support_camera_project(_source_xz_to_meters(source, bed_height), saved_support.camera)
				if bed_point.y > deck_point.y and absf(bed_point.y - deck_point.y + bed_height * WORLD_SIZE.y / 30 / sqrt(2.0)) < .01: wet_bed_projection_separation += 1
		_check(signed_wet_bed > 0 and signed_wet_bed == wet_bed_projection_separation, "real negative underwater RF/mesh bed remains distinct from actual Y0 deck and its camera projection: support%d wet=%d separated=%d" % [deck_count, signed_wet_bed, wet_bed_projection_separation])
		for point: Vector2 in samples:
			if not _foot_clear(point): bad_foot += 1
			if rect.has_point(point):
				if not _declared_structure_support(point): no_alpha += 1
				if (native_images.land as Image).get_pixelv(Vector2i(point)).r < .5: on_water += 1
				for foot: Vector2 in _foot_samples(point):
					for d: Dictionary in world.map_layout.visual_objects:
						if bool(d.get("sort_by_feet", false)) and String(d.get("id", "")).begins_with("bridge_") and _source_object_pixel(d, foot).a > .12:
							entity_overlap_samples += 1
		_check(bad_foot == 0 and no_alpha == 0, "entire bridge approach and deck have full-foot terrain/actual visual support: bridge%d bad=%d noalpha=%d" % [deck_count, bad_foot, no_alpha])
		_check(on_water > 0, "real structural deck spans genuine water rather than being painted land: support%d" % deck_count)
		print("[WorldV14Structure] support=%d legal_fullfoot_source_foreground_overlap_samples=%d wet_bed_witnesses=%d; actual entities may occlude behind feet, verified source walking-floor exclusion tested separately" % [deck_count, entity_overlap_samples, signed_wet_bed])
		# The dense runtime passage already checks every <=4px/17-sample foot.
		# Explicitly retain both actual dry-bank tie-ins, including 25..100px
		# approach spans outside narrow deck geometry, not just white deck center.
		if String(entry.get("kind")) == "bridge":
			var before_bank := 0
			var after_bank := 0
			var direction := (finish - start).normalized()
			for point: Vector2 in samples:
				if _actual_support_at_screen(point, saved_support): continue
				var distance_to_edge := point.distance_to(rect.get_center()) - (rect.size.y if vertical else rect.size.x) * .5
				if distance_to_edge < 25 or distance_to_edge > 100: continue
				if (native_images.land as Image).get_pixelv(Vector2i(point)).r < .5 or not _foot_clear(point): continue
				if (point - rect.get_center()).dot(direction) < 0: before_bank += 1
				else: after_bank += 1
			_check(before_bank > 0 and after_bank > 0, "both actual bridge banks retain dry full-foot 25..100px approach tie-ins: support%d before=%d after=%d" % [deck_count, before_bank, after_bank])
		var passage_id := String(entry.get("object_id", ""))
		if bad_foot == 0 and not driven.has(passage_id) and await _place_fixture(start):
			driven[passage_id] = true
			await _input_path(passage, "support%d forward actual input" % deck_count)
			await _capture("bridge%d_exit" % deck_count)
			var reverse := passage.duplicate()
			reverse.reverse()
			await _input_path(reverse, "support%d backward actual input" % deck_count)
			await _capture("bridge%d_return" % deck_count)
		var lateral := Vector2(rect.size.x * .5 + 12, 0) if vertical else Vector2(0, rect.size.y * .5 + 12)
		if String(entry.get("kind")) == "bridge":
			_check(not _foot_clear(rect.get_center() + lateral) and not _foot_clear(rect.get_center() - lateral), "bridge side/rail cannot become a second invisible water deck: bridge%d" % deck_count)
		deck_count += 1
	var dock_record: Dictionary = support_geometry_cache.get("support_3", {})
	if not dock_record.is_empty():
		# Authored Bailu boat-water witness, not a newly white point chosen to
		# suit the raster. It is outside both narrow real L-deck support meshes.
		var boat_source := Vector2(4296, 1744)
		var boat_bed := _height_at(boat_source)
		var boat_point := _support_camera_project(_source_xz_to_meters(boat_source, boat_bed), dock_record.camera)
		var in_canvas := Rect2(Vector2.ZERO, WORLD_SIZE).has_point(boat_point)
		_check(_actual_support_for_source(boat_source).is_empty() and is_finite(boat_bed) and boat_bed < -.0001 and in_canvas, "Bailu boat remains over actual negative wet bed, outside the two physical plank decks")
		if in_canvas:
			_check((native_images.land as Image).get_pixelv(Vector2i(boat_point)).r < .5 and not _declared_structure_support(boat_point) and not _foot_clear(boat_point), "real boat-water camera point is natural water and full-foot denied, never implicit harbour support")
	var raw: Image = native_images.land
	var water_probes := 0
	for y in range(32, int(WORLD_SIZE.y) - 32, 24):
		# Sample every survey row over the real east ocean, not just a few dots.
		for x in range(4376, int(WORLD_SIZE.x) - 16, 16):
			var point := Vector2(x, y)
			if raw.get_pixelv(Vector2i(point)).r >= .5: continue
			_check(not _foot_clear(point), "actual Field refuses surveyed natural ocean pixel %s" % point)
			water_probes += 1
	_check(water_probes > 100, "natural sea negative witnesses span entire coastline rather than only old screenshot")
	var geometry := _json(ART_DIR + "geometry.json")
	var steep: Array = geometry.get("steep_examples", [])
	var gentle: Array = geometry.get("gentle_examples", [])
	_check(steep.size() >= 12 and gentle.size() >= 12, "fresh source geometry has actual steep and gentle witnesses")
	for group: Array in [steep, gentle]:
		for probe: Dictionary in group:
			var source := _point(probe.get("source_point"))
			var height := _height_at(source)
			var gradient := float(_actual_terrain_triangle(source).get("gradient", NAN))
			var point := Vector2(source.x, source.y - height * WORLD_SIZE.y / 30 / sqrt(2.0))
			_check(point.distance_to(_point(probe.get("projected_point"))) < .01 and absf(gradient - float(probe.get("world_gradient", -1))) < .0001, "source RF independently reproduces current gradient and camera projection")
			if group == steep:
				_check(gradient > .72 and not _foot_clear(point), "real current steep terrain rejects Field feet: " + str(point))
			else:
				_check(gradient < .72 and (native_images.land as Image).get_pixelv(Vector2i(point)).r > .5 and _foot_clear(point), "real current gentle dry land supports Field feet: " + str(point))

func _terrain_capture_geometry_checks() -> void:
	var metadata := _json(ART_DIR + "geometry.json")
	var mesh := load(ART_DIR + "terrain_mesh.res") as ArrayMesh
	_check(mesh != null and mesh.get_surface_count() == 1, "actual GPU terrain mesh stored for independent source geometry verification")
	if mesh == null or mesh.get_surface_count() != 1: return
	var grid_file := FileAccess.open(ART_DIR + "height_grid.rf", FileAccess.READ)
	_check(grid_file != null, "raw Float32 height grid exists, not derived photo brightness")
	if grid_file == null: return
	var data := grid_file.get_buffer(grid_file.get_length())
	grid_file.close()
	var shape := _point(metadata.get("height_grid_shape"))
	var cols := int(shape.x) - 1
	var rows := int(shape.y) - 1
	_check(cols == 768 and rows == 512 and _point(metadata.get("source_node_spacing_px")).distance_to(Vector2(6, 6)) < .0001, "production relief uses the actual 6px source vertex grid")
	_check(String(metadata.get("height_interpolation", "")).contains("triangle") and String(metadata.get("gradient_method", "")).contains("triangle"), "capture explicitly identifies actual triangle height and derivative semantics")
	_check(data.size() == (cols + 1) * (rows + 1) * 4, "actual RF has every declared source vertex")
	if data.size() != (cols + 1) * (rows + 1) * 4: return
	var heights := data.to_float32_array()
	height_samples = heights
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	terrain_cols = cols
	terrain_rows = rows
	terrain_vertices = vertices
	terrain_indices = indices
	terrain_uvs = uvs
	_check(indices.size() == rows * cols * 6 and uvs.size() == vertices.size(), "actual nine-region terrain has full triangle/UV topology")
	var mismatched_vertices := 0
	var positive_height := 0
	for i in vertices.size():
		var uv := uvs[i]
		var x := roundi(uv.x * cols)
		var y := roundi(uv.y * rows)
		if x < 0 or y < 0 or x > cols or y > rows:
			mismatched_vertices += 1
			continue
		var expected := Vector3((uv.x - .5) * 45.0, heights[y * (cols + 1) + x], (uv.y - .5) * 42.42640687)
		if vertices[i].distance_to(expected) > .0001: mismatched_vertices += 1
		if expected.y > .05: positive_height += 1
	_check(mismatched_vertices == 0 and positive_height > 1000, "every actual terrain vertex follows recorded height/UV, with genuine relief not flat mesh: bad=%d positive=%d" % [mismatched_vertices, positive_height])
	var wrong_winding := 0
	var degenerate := 0
	var wrong_cell_indices := 0
	for y in rows:
		for x in cols:
			var a := Vector2(float(x) / cols, float(y) / rows)
			var b := Vector2(float(x + 1) / cols, float(y) / rows)
			var c := Vector2(float(x) / cols, float(y + 1) / rows)
			var d := Vector2(float(x + 1) / cols, float(y + 1) / rows)
			var first := (y * cols + x) * 6
			var expected := [a, b, c, b, d, c]
			for offset in 6:
				if uvs[indices[first + offset]] != expected[offset]: wrong_cell_indices += 1
	_check(wrong_cell_indices == 0, "stored actual index triangles occupy their source UV cell, not a metadata-only formula: bad=%d" % wrong_cell_indices)
	for triangle in range(0, indices.size(), 3):
		var a := vertices[indices[triangle]]
		var b := vertices[indices[triangle + 1]]
		var c := vertices[indices[triangle + 2]]
		var cross := (b - a).cross(c - a).y
		if absf(cross) < .0000001: degenerate += 1
		elif cross >= 0: wrong_winding += 1
	_check(wrong_winding == 0 and degenerate == 0, "all native terrain triangles retain front-facing negative winding: bad=%d degenerate=%d" % [wrong_winding, degenerate])
	_check(not metadata.is_empty(), "geometry capture metadata loads without executing renderer hooks")
	_check(String(metadata.get("terrain_mesh_path", "")) == ART_DIR + "terrain_mesh.res" and FileAccess.get_sha256(ART_DIR + "terrain_mesh.res").to_lower() == String(metadata.get("terrain_mesh_sha256", "")).to_lower(), "captured terrain mesh binds actual native production resource and SHA")
	var attribute_hashes: Dictionary = metadata.get("mesh_attributes_sha256", {})
	for entry: Array in [["vertex", Mesh.ARRAY_VERTEX], ["normal", Mesh.ARRAY_NORMAL], ["uv", Mesh.ARRAY_TEX_UV], ["index", Mesh.ARRAY_INDEX]]:
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(arrays[int(entry[1])].to_byte_array())
		_check(hash.finish().hex_encode() == String(attribute_hashes.get(String(entry[0]), "")).to_lower(), "actual mesh stream SHA independently matches captured " + String(entry[0]))
	# Binding a height source and full mesh is not a visual approval. True relief
	# projection, steep/gentle semantics and photographic contact are inspected
	# at the actual recorded witnesses and in the nine-region runtime captures.

func _native_export_and_ground_shadow_checks() -> void:
	var reconstructed := Image.create(int(WORLD_SIZE.x), int(WORLD_SIZE.y), false, Image.FORMAT_RGBA8)
	reconstructed.fill(Color.TRANSPARENT)
	var model_count := 0
	for d: Dictionary in world.map_layout.visual_objects:
		var id := String(d.get("id", ""))
		if not id.begins_with("native_") or id == "native_cast_shadow": continue
		var meta := _json(ART_DIR + "entities/" + id + ".json")
		if meta.is_empty(): continue
		model_count += 1
		_check(String(meta.get("id")) == id, "native exported metadata owns actual runtime entity: " + id)
		var source_path := String(meta.get("source", ""))
		_check(source_path.begins_with("res://art/external/") and FileAccess.file_exists(source_path), "native source model is the registered external local resource: " + id)
		_check(FileAccess.get_sha256(source_path).to_lower() == String(meta.get("source_sha256", "")).to_lower(), "actual native source SHA verified, not filename claim: " + id)
		_native_model_geometry(meta)
		var body := _read_image(ART_DIR + "entities/" + id + "_sourcebody.png")
		var repeat := _read_image(ART_DIR + "entities/" + id + "_sourcebody_repeat.png")
		var crop := _read_image(String(d.get("texture")))
		if body == null or repeat == null or crop == null: continue
		var canvas := Vector2i(_point(meta.get("sourcebody_canvas")))
		_check(canvas.x >= 512 and canvas.x == canvas.y and body.get_size() == canvas and body.get_format() == Image.FORMAT_RGBA8, "real dynamic transparent sourcebody matches final captured canvas/RGBA8: " + id)
		_check(body.get_data() == repeat.get_data(), "independent repeat capture exact actual source RGBA, not metadata: " + id)
		var used := body.get_used_rect()
		var transparent_edge := true
		for x in canvas.x:
			if body.get_pixel(x, 0).a != 0 or body.get_pixel(x, canvas.y - 1).a != 0: transparent_edge = false
		for y in canvas.y:
			if body.get_pixel(0, y).a != 0 or body.get_pixel(canvas.x - 1, y).a != 0: transparent_edge = false
		_check(used.has_area() and used.position.x >= 4 and used.position.y >= 4 and used.end.x <= canvas.x - 4 and used.end.y <= canvas.y - 4 and transparent_edge, "native body is nonempty with actual alpha-free safety margins, not a fixed small-model canvas: " + id)
		var region := used.grow(4).intersection(Rect2i(Vector2i.ZERO, canvas))
		_check(_rect(meta.get("sourcebody_crop_rect")).is_equal_approx(Rect2(region)), "recorded crop binds independently measured actual source alpha extent: " + id)
		_check(body.get_region(region).get_data() == crop.get_data(), "sprite crop exactly corresponds to original actual sourcebody: " + id)
		var foot := _point(meta.get("world_foot"))
		var camera_foot := _point(meta.get("sourcebody_camera_foot"))
		_check(camera_foot.distance_to(Vector2(canvas) * .5) < .01 and absf(float(meta.get("same_native_camera_orientation_px_per_meter", 0)) - 102.4) < .0001, "actual dynamic orthographic ground foot stays at camera center with fixed native pixels/metre: " + id)
		var camera: Dictionary = meta.get("sourcebody_camera", {})
		var ground := _vec3(meta.get("ground_m"))
		var basis_columns: Array = camera.get("basis_columns", [])
		_check(bool(camera.get("orthographic", false)) and int(camera.get("projection_enum", -1)) == Camera3D.PROJECTION_ORTHOGONAL and _point(camera.get("canvas")).distance_to(Vector2(canvas)) < .01 and absf(float(camera.get("size", 0)) - canvas.y / 102.4) < .0001, "source-audited actual body camera configuration follows dynamic canvas, not a fixed512 claim: " + id)
		_check(_vec3(camera.get("position")).distance_to(ground + Vector3(0, 36, 36)) < .0001 and _vec3(camera.get("look_at")).distance_to(ground) < .0001 and basis_columns.size() == 3, "source-audited body camera pose uses the same terrain ground anchor: " + id)
		if basis_columns.size() == 3:
			_check(_vec3(basis_columns[0]).distance_to(Vector3.RIGHT) < .00001 and _vec3(basis_columns[1]).distance_to(Vector3(0, 1, -1).normalized()) < .00001 and _vec3(basis_columns[2]).distance_to(Vector3(0, 1, 1).normalized()) < .00001, "independently reconstructed body camera basis matches fixed2.5D orthographic pose: " + id)
		var provenance := String(camera.get("provenance", ""))
		var source_audit := provenance.contains("metadata-only")
		var actual_read := provenance == "actual Camera3D properties read before this sourcebody capture/export"
		# Fourth reconstructed-camera metadata stored its execution binding inside
		# camera. Fifth actual-read camera stores binding at entity-meta level.
		var execution_binding := camera if source_audit else meta
		var executed_source := "res://build/world_map_v14_fourth_executed_builder.gd" if source_audit else String(execution_binding.get("executed_builder_path", ""))
		var executed_sha := String(execution_binding.get("executed_builder_sha256", "")).to_lower()
		if actual_read and FileAccess.file_exists(executed_source) and FileAccess.get_sha256(executed_source).to_lower() != executed_sha:
			# Explicit producer-approved capture-time snapshot, not future live code.
			var fifth_snapshot := "res://build/world_map_v14_fifth_executed_builder.gd"
			if FileAccess.file_exists(fifth_snapshot) and FileAccess.get_sha256(fifth_snapshot).to_lower() == executed_sha:
				executed_source = fifth_snapshot
		var trusted_source := executed_source.begins_with("res://build/world_map_v14_") or executed_source == "res://scripts/dev/build_world_map_native_full_v14.gd"
		_check((source_audit or actual_read) and executed_sha.length() == 64 and trusted_source and FileAccess.file_exists(executed_source) and FileAccess.get_sha256(executed_source).to_lower() == executed_sha, "camera provenance and frozen actual executed-source SHA are honest and bound: " + id)
		_check(_point(meta.get("sourcebody_origin_world_px")).distance_to(foot - camera_foot) < .01, "fullbody world origin follows actual dynamic camera ground anchor: " + id)
		var uv := _point(meta.get("foot_uv"))
		var expected_uv := (camera_foot - Vector2(region.position)) / Vector2(region.size)
		_check(uv.distance_to(expected_uv) < .0001, "transparent crop foot recalculated from actual camera anchor: " + id)
		_check(_point(d.get("render_size_px")).distance_to(Vector2(region.size)) < .01, "native sprite is not squashed/stretched on export: " + id)
		var runtime_center := _point(d.get("pos")) * WORLD_SIZE
		_check((runtime_center + (uv - Vector2(.5, .5)) * Vector2(region.size)).distance_to(foot) < .02, "sourcebody foot equals actual placed runtime foot: " + id)
		_check(absf(float(d.get("depth_sort_foot_y")) * WORLD_SIZE.y - foot.y) < .01, "each model uses its own actual exported Y line: " + id)
		_check(bool(meta.get("blocking", false)) == d.has("collision_size"), "natural entity blocking semantic equals real layout physics: " + id)
		if d.has("collision_size"):
			_check((_point(d.get("collision_size")) * WORLD_SIZE).distance_to(_point(meta.get("collision_size"))) < .02, "model XZ footprint genuinely bound into runtime: " + id)
			_check((runtime_center + _point(d.get("collision_offset")) * WORLD_SIZE).distance_to(_point(meta.get("collision_center"))) < .02, "model projected contact offset bound into runtime: " + id)
		var origin := Vector2i(foot - camera_foot)
		reconstructed.blend_rect(body, Rect2i(Vector2i.ZERO, canvas), origin)
	_check(model_count >= 6 and model_count == int(manifest.get("native_model_count", -1)), "every actual native model verified and contributes its body to ground exclusion")
	var union := _read_image(ART_DIR + "native_body_union.png")
	if union == null: return
	_check(reconstructed.get_data() == union.get_data(), "independently reconstructed all-native sourcebody union equals capture diagnostic")
	var on := _read_image(ART_DIR + "shadow_on.png")
	var off := _read_image(ART_DIR + "shadow_off.png")
	var on_repeat := _read_image(ART_DIR + "shadow_on_repeat.png")
	var off_repeat := _read_image(ART_DIR + "shadow_off_repeat.png")
	var shadow := _read_image(ART_DIR + "native_shadow.png")
	if on == null or off == null or shadow == null or on_repeat == null or off_repeat == null: return
	_check(on.get_data() == on_repeat.get_data() and off.get_data() == off_repeat.get_data(), "both actual ground ON/OFF captures independently repeat byte-for-byte")
	_check(off.get_data() == (native_images.visual as Image).get_data(), "runtime ground contains neither native model bodies nor native cast baked into base")
	var expanded := PackedByteArray()
	expanded.resize(int(WORLD_SIZE.x * WORLD_SIZE.y))
	var union_bytes := reconstructed.get_data()
	for y in range(int(WORLD_SIZE.y)):
		for x in range(int(WORLD_SIZE.x)):
			if union_bytes[(y * int(WORLD_SIZE.x) + x) * 4 + 3] == 0: continue
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					expanded[clampi(y + dy, 0, int(WORLD_SIZE.y) - 1) * int(WORLD_SIZE.x) + clampi(x + dx, 0, int(WORLD_SIZE.x) - 1)] = 1
	var land: Image = native_images.land
	var mismatches := 0
	var forbidden := 0
	var independent_ground_count := 0
	var actual_ground_count := 0
	for y in range(int(WORLD_SIZE.y)):
		for x in range(int(WORLD_SIZE.x)):
			var allowed := land.get_pixel(x, y).r >= .5 and expanded[y * int(WORLD_SIZE.x) + x] == 0
			for item: Variant in source_contract.get("structure_support_rects_px", []):
				var rect := _rect(item.get("rect_px", []) if item is Dictionary else item)
				if rect.has_point(Vector2(x, y)): allowed = false
			var a := on.get_pixel(x, y)
			var b := off.get_pixel(x, y)
			var la := a.r * .299 + a.g * .587 + a.b * .114
			var lb := b.r * .299 + b.g * .587 + b.b * .114
			var relative := clampf((lb - la) / maxf(lb, .01), 0.0, .85)
			var expected := relative if allowed and relative > .015 else 0.0
			var actual := shadow.get_pixel(x, y)
			if expected > 0: independent_ground_count += 1
			if actual.a > 0:
				actual_ground_count += 1
				if not allowed: forbidden += 1
			if absf(actual.a - expected) > 1.01 / 255.0 or (actual.a > 0 and maxf(actual.r, maxf(actual.g, actual.b)) > 0): mismatches += 1
	_check(independent_ground_count > 0 and actual_ground_count > 0, "true nonempty ground-only darkening outside all native bodies, not body ON/OFF contamination")
	_check(forbidden == 0, "shadow never paints natural water/structural decks/dilated native bodies")
	_check(mismatches == 0, "every ground shadow pixel independently reproduced from original ON/OFF lighting")
	print("[WorldV14Shadow] models=%d expected_ground=%d actual_ground=%d forbidden=%d mismatches=%d" % [model_count, independent_ground_count, actual_ground_count, forbidden, mismatches])

func _story_boundary_checks() -> void:
	var state := root.get_node("GameState")
	var dialog := root.get_node("DialogPlayer")
	_check(world.on_enter_dialog != null and String(world.on_enter_require_flag) != "" and String(world.on_enter_once_flag) != "", "actual formal once-only story remains present")
	if world.on_enter_dialog == null: return
	var require_key := String(world.on_enter_require_flag)
	var once_key := String(world.on_enter_once_flag)
	state.get("flags").erase(require_key)
	state.get("flags").erase(once_key)
	_check(await _open_world(world.player_spawn), "pre-story player can still enter full public world")
	_check(not bool(dialog.call("is_playing")) and not state.get("flags").has(once_key), "missing story prerequisite does not mark once flag or force main plot")
	state.call("set_flag", StringName(require_key), true)
	_check(await _open_world(world.player_spawn), "post-prerequisite player enters same actual world")
	_check(bool(dialog.call("is_playing")) and bool(state.get("flags").get(once_key, false)), "real required world intro fires and stamps once boundary")
	var script: DialogScript = dialog.get("_current_script")
	_check(script != null and script.dialog_id == world.on_enter_dialog.dialog_id, "real authored main-story dialog, not empty replacement")
	await _normal_dialog_finish()
	var router := root.get_node("SceneRouter")
	_check(router.call("get_current_field_id") == &"ch7_s1_lieyun_valley_ferry", "real first route choice sends player to existing narrative destination")
	_check(await _wait_field(&"ch7_s1_lieyun_valley_ferry"), "authored dialog-end destination completes its real Loading transition before any new request")
	_check(bool(state.get("flags").get("ch7_dual_route_chosen", false)) and bool(state.get("flags").get("ch7_route_first_lieyun", false)), "real choices apply existing authored route flags")
	var arrival_script: DialogScript = dialog.get("_current_script")
	if bool(dialog.call("is_playing")):
		_check(arrival_script != null and arrival_script.dialog_id == &"ch7_lieyun_arrival", "destination retains its real separate arrival intro, not a repeated world route choice")
		_check(await _normal_dialog_finish(), "actual destination arrival intro finishes before world return")
	_check(bool(state.get("flags").get("seen_ch7_lieyun_arrival", false)) and bool(state.get("flags").get("ch7_first_route_arrived", false)), "actual destination intro side effects are played, not suppressed by QA")
	_check(root.get_node("QuestManager").call("is_active", &"q_ch7_main_01_choose_first_route") or root.get_node("QuestManager").call("is_completed", &"q_ch7_main_01_choose_first_route"), "real plot keeps its quest acceptance/progression, not disabled gameplay")
	var story_flags: Dictionary = state.get("flags").duplicate(true)
	_check(await _open_world(world.player_spawn), "return to full world after actual route choice")
	_check(not bool(dialog.call("is_playing")), "second world arrival respects once flag and does not repeat route choice")
	_check(_domain_equal(story_flags, state.get("flags")), "once-only world return adds no duplicate plot side effects")

func _battle_and_modal_return_checks() -> void:
	var router := root.get_node("SceneRouter")
	_check(not bool(root.get_node("DialogPlayer").call("is_playing")), "battle begins only after real authored dialogs finish, not beneath a modal intro")
	if bool(root.get_node("DialogPlayer").call("is_playing")): return
	var player: Node2D = field.get("_player")
	var original := player.position / WORLD_SIZE
	var state := root.get_node("GameState")
	var stats: Resource = state.get("player")
	# A normal level-appropriate combat fixture, not altered enemies, result
	# payload injection, GM victory or disabled battle/reward code.
	stats.call("gain_exp", 250)
	stats.set("hp", stats.get("max_hp"))
	stats.set("mp", stats.get("max_mp"))
	var gold_before := int(state.get("gold"))
	var enemies: Array[StringName] = [&"thug_lone"]
	router.call("start_encounter", enemies, active_id, original)
	var battle: Node
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		if is_instance_valid(current_scene) and current_scene.get_node_or_null("%BtnAttack") != null:
			battle = current_scene
			break
	_check(battle != null, "actual production Router starts complete existing battle")
	if battle == null: return
	var battle_payload: Dictionary = router.call("get_battle_payload")
	_check(StringName(battle_payload.get("return_scene")) == active_id and int(battle_payload.get("return_world_map_version", -1)) == 14, "actual battle remembers the source map ID and coordinate version")
	var turns := 0
	var victory: Node
	var attack_presses: Array = []
	(battle.get_node("%BtnAttack") as Button).pressed.connect(func(): attack_presses.append(true))
	deadline = Time.get_ticks_msec() + 120000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		# A genuine win frees Battle while Loading is replacing the scene.
		# Wait for actual Victory controls rather than interpreting that gap
		# as a loss. No result or reward payload is injected.
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		# Victory/Defeat intentionally use immediate change_scene_to_file,
		# not LoadingManager. The genuine handoff has a null scene frame.
		if not is_instance_valid(current_scene): continue
		if is_instance_valid(current_scene) and current_scene.get_node_or_null("%BtnContinue") != null:
			victory = current_scene
			break
		if not is_instance_valid(battle) or current_scene != battle:
			print("[WorldV14Battle] actual nonbattle scene after transition: ", current_scene.scene_file_path if is_instance_valid(current_scene) else "null")
			break
		var button := battle.get_node("%BtnAttack") as Button
		if int(battle.get("_state")) == 1 and button.is_visible_in_tree() and not button.disabled:
			var pressed_before := attack_presses.size()
			await _pointer(button.get_global_rect().get_center())
			_check(attack_presses.size() == pressed_before + 1, "normal ready Attack receives actual pressed signal")
			if attack_presses.size() == pressed_before + 1: turns += 1
			for frame in range(6): await process_frame
	_check(victory != null and turns > 0, "real current command input resolves battle into victory, no fabricated result")
	if victory == null:
		_check(false, "battle fixture did not win within finite actual gameplay budget")
		return
	var result: Dictionary = router.call("get_result_payload")
	_check(int(result.get("return_world_map_version", -1)) == 14 and StringName(result.get("return_scene")) == active_id, "victory's actual payload keeps v14 source version")
	_check(bool(state.get("flags").get("defeated_thug_lone", false)) and int(state.get("gold")) > gold_before, "actual enemy defeat and reward effects remain enabled")
	await _pointer((victory.get_node("%BtnContinue") as Button).get_global_rect().get_center())
	_check(await _wait_field(active_id), "real victory continue returns to the full production map")
	player = field.get("_player")
	_check((player.position / WORLD_SIZE).distance_to(original) * WORLD_SIZE.length() < .03 and _foot_clear(player.position), "battle resumes exact v14 coordinate once, with legal complete feet")
	# Normal world_map action and regional paired-back route retain the active
	# candidate/canonical scope; no direct Field substitute is installed.
	router.call("go_field_smart", &"linxi_village_scrollmap")
	_check(await _wait_field(&"linxi_village_scrollmap"), "ordinary regional scene loaded for normal world_map action")
	await _normal_dialog_finish()
	var region_player: Node2D = field.get("_player")
	var region_spawn := region_player.position / (field.get("_world_size") as Vector2)
	router.call("set_field_return_spawn", region_spawn)
	router.call("resolve_action", "world_map")
	_check(await _wait_field(active_id), "ordinary world_map action loads actual active new world")
	var gateway: Variant = router.call("get_world_map_position_for_scene", &"linxi_village_scrollmap", active_id)
	player = field.get("_player")
	_check(gateway is Vector2 and (player.position / WORLD_SIZE).distance_to(gateway) < .00001, "normal world_map action arrives at regional live gateway")
	router.call("return_from_world_map")
	_check(await _wait_field(&"linxi_village_scrollmap"), "normal return_from_world_map preserves originating region")
	region_player = field.get("_player")
	_check((region_player.position / (field.get("_world_size") as Vector2)).distance_to(region_spawn) < .00001, "normal map back action preserves exact remembered regional feet")
	_check(int(region_player.get_meta("depth_band_max", 255)) == 255, "south depth range does not leak through normal map back")
	_check(field.get("_v14_modular_overlap") == null and not bool(field.call("get_v14_modular_overlap_debug").get("active", false)), "v14 modular local-alpha service is absent in ordinary scene")
	var regional_ghost := region_player.get_node("BuildingOverlapGhost") as Sprite2D
	_check(regional_ghost.z_index == 450, "ordinary scene ghost depth resets to existing 450 contract")
	await _open_world(world.player_spawn)

func _domain_equal(a: Variant, b: Variant, depth: int = 0) -> bool:
	if depth > 20: return false
	if a is Resource and b is Resource:
		if a.get_script() != b.get_script(): return false
		for property: Dictionary in a.get_property_list():
			if int(property.usage) & PROPERTY_USAGE_STORAGE == 0: continue
			var key := String(property.name)
			if key in ["resource_path", "resource_scene_unique_id", "script"]: continue
			if not _domain_equal(a.get(key), b.get(key), depth + 1): return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not _domain_equal(a[i], b[i], depth + 1): return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _domain_equal(a[key], b[key], depth + 1): return false
		return true
	return a == b

func _battle_defeat_and_flee_checks() -> void:
	var router := root.get_node("SceneRouter")
	var state := root.get_node("GameState")
	var bus := root.get_node("EventBus")
	var events: Array = []
	var record := func(won: bool, fled: bool): events.append({"won": won, "fled": fled})
	bus.connect("battle_ended",record)
	for mode: String in ["defeat","flee"]:
		# Reset ordinary new-game domain data, never enemy stats or result payloads.
		# One real player and 1HP make a genuine enemy turn a deterministic
		# loss fixture; flee retains normal healthy stats and the real production
		# team retreat action (not a claim to cover the legacy 1v1 RNG roll).
		_fixture_new_game()
		if not await _open_world(world.player_spawn): break
		var player: Node2D = field.get("_player")
		var original := player.position / WORLD_SIZE
		var stats: Resource = state.get("player")
		stats.set("hp",1 if mode == "defeat" else stats.get("max_hp"))
		stats.set("mp",stats.get("max_mp"))
		var random_seed := 140002 if mode == "defeat" else 140003
		seed(random_seed)
		var before := events.size()
		var gold_before := int(state.get("gold"))
		var enemies: Array[StringName] = [&"thug_lone"]
		router.call("start_encounter",enemies,active_id,original)
		var battle: Node
		var deadline := Time.get_ticks_msec()+30000
		while Time.get_ticks_msec() < deadline:
			await process_frame
			if bool(root.get_node("LoadingManager").get("_transition_active")): continue
			if is_instance_valid(current_scene) and current_scene.get_node_or_null("%BtnDefend") != null:
				battle = current_scene; break
		_check(battle != null,"real ordinary battle starts for "+mode)
		if battle == null: continue
		var payload: Dictionary = router.call("get_battle_payload").duplicate(true)
		_check(int(payload.get("return_world_map_version",-1)) == 14 and StringName(payload.get("return_scene")) == active_id,"real "+mode+" battle payload carries v14 source")
		var commands := 0
		var attempts := 0
		var pressed_signals: Array = []
		var action_button := battle.get_node("%BtnDefend" if mode == "defeat" else "%BtnFlee") as Button
		action_button.pressed.connect(func(): pressed_signals.append(true))
		var result_scene: Node
		deadline = Time.get_ticks_msec()+120000
		while Time.get_ticks_msec() < deadline:
			await process_frame
			if bool(root.get_node("LoadingManager").get("_transition_active")): continue
			if not is_instance_valid(current_scene): continue
			if is_instance_valid(current_scene) and current_scene.get_node_or_null("%BtnBack") != null and current_scene.scene_file_path.contains("defeat"):
				result_scene = current_scene; break
			if not is_instance_valid(battle) or current_scene != battle: break
			if attempts >= 32: continue # finite actual commands; allow final handoff.
			var button := action_button
			if int(battle.get("_state")) != 1 or not button.is_visible_in_tree() or button.disabled: continue
			var active_dialog := battle.get("_flee_confirm_dialog") as Control
			if active_dialog != null and active_dialog.is_visible_in_tree(): continue
			var pressed_before := pressed_signals.size()
			await _pointer(button.get_global_rect().get_center())
			attempts += 1
			var received := pressed_signals.size() == pressed_before + 1
			_check(received,"normal ready "+mode+" button receives one actual pressed signal")
			if not received: continue
			if mode == "defeat":
				_check(int(battle.get("_state")) != 1,"real Defend action is accepted, not an INTRO click")
				if int(battle.get("_state")) != 1: commands += 1
			if mode == "flee":
				var dialog := battle.get("_flee_confirm_dialog") as Control
				_check(dialog != null and dialog.is_visible_in_tree(),"real flee command opens normal confirmation")
				if dialog != null and dialog.is_visible_in_tree():
					var confirmation: Array = []
					var confirm := dialog.get_node("%ConfirmAction") as Button
					confirm.pressed.connect(func(): confirmation.append(true), CONNECT_ONE_SHOT)
					await _pointer(confirm.get_global_rect().get_center())
					_check(confirmation.size() == 1,"real ordinary flee confirmation receives actual pressed signal")
					if confirmation.size() == 1 and int(battle.get("_state")) != 1: commands += 1
			for frame in range(6): await process_frame
		print("[WorldV14BattleOutcome] mode=%s seed=%d attempts=%d accepted_commands=%d team_mode=%s events=%s" % [mode,random_seed,attempts,commands,battle.get("_team_mode") if is_instance_valid(battle) else "released",events.slice(before)])
		var outcome_found := false
		for event: Dictionary in events.slice(before):
			if not bool(event.won) and bool(event.fled) == (mode == "flee"): outcome_found = true
		_check(outcome_found and commands > 0,"normal action input really emits expected "+mode+" outcome, not fabricated results")
		if mode == "defeat":
			_check(result_scene != null,"1HP ordinary fixture reaches actual Defeat scene")
			if result_scene == null: continue
			var defeat: Dictionary = router.call("get_result_payload")
			_check(int(defeat.get("return_world_map_version",-1)) == 14 and StringName(defeat.get("return_scene")) == active_id,"actual Defeat result retains v14 version and source")
			await _capture("battle_actual_defeat")
			await _pointer((result_scene.get_node("%BtnBack") as Button).get_global_rect().get_center())
		_check(await _wait_field(active_id),"real "+mode+" normal UI/action returns to full world")
		if not is_instance_valid(field) or root.get_node("SceneRouter").call("get_current_field_id") != active_id: continue
		player = field.get("_player")
		_check((player.position / WORLD_SIZE).distance_to(original)*WORLD_SIZE.length() < .03 and _foot_clear(player.position),mode+" resumes exact v14 original feet without remigration")
		_check(int(router.call("get_navigation_state").get("world_map_version",-1)) == 14,mode+" navigation records current world version")
		_check(int(state.get("gold")) == gold_before and not bool(state.get("flags").get("defeated_thug_lone",false)),mode+" does not fabricate victory rewards or enemy-defeat flags")
		await _capture("battle_actual_"+mode+"_world_return")
	bus.disconnect("battle_ended",record)

func _fixture_new_game() -> void:
	for singleton in ["GameState", "Inventory", "QuestManager", "BountyManager", "InvestigationState", "WeatherManager", "SceneRouter"]:
		root.get_node(singleton).call("reset_for_new_game")
	var gm := root.get_node_or_null("GMConsole")
	if gm != null:
		if gm is CanvasLayer: gm.visible = false
		gm.set_process(false)
		gm.set_process_unhandled_input(false)
	_check(not bool(root.get_node("DialogPlayer").call("is_playing")), "new-game safe fixture starts outside dialogue; no plot data suppressed")

func _state_payload() -> Dictionary:
	var state := root.get_node("GameState")
	var stats: Resource = state.get("player")
	return {
		"flags": state.get("flags").duplicate(true), "gold": state.get("gold"),
		"reputation": state.get("reputation"), "player": isolated_slots.call("_serialize_stats", stats),
		"inventory": root.get_node("Inventory").call("to_dict").duplicate(true),
		"quests": root.get_node("QuestManager").call("to_dict").duplicate(true),
		"bounties": root.get_node("BountyManager").call("to_dict").duplicate(true),
		"investigation": root.get_node("InvestigationState").call("to_dict").duplicate(true),
	}

func _write_isolated_json(slot: int, data: Dictionary) -> void:
	var path := String(isolated_slots.call("slot_path", slot))
	_check(path.begins_with(isolated_dir + "/"), "synthetic historic JSON remains isolated")
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "write isolated historic save JSON")
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _independent_free_mapping(old_scene: SceneScript, point: Vector2) -> Vector2:
	# Source portal pairs define inverse-square local deformation. This is a
	# mathematical expectation from immutable legacy/current data, not a call
	# to SceneRouter/WorldV14's migration or repair implementation.
	var pairs: Array[Dictionary] = []
	for old: Dictionary in old_scene.map_layout.portals:
		for fresh: Dictionary in world.map_layout.portals:
			if String(old.get("id")) != String(fresh.get("id")): continue
			var previous := _point(old.get("pos"))
			var pixel_distance := ((point - previous) * Vector2(old_scene.map_layout.design_size)).length()
			if pixel_distance <= 64: return Vector2(INF, INF) # separate portal case, not free movement
			pairs.append({"distance_squared": pixel_distance * pixel_distance, "displacement": _point(fresh.get("pos")) - previous})
	pairs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.distance_squared) < float(b.distance_squared))
	var weighted := Vector2.ZERO
	var total := 0.0
	for index in mini(4, pairs.size()):
		var weight := 1.0 / maxf(1.0, float(pairs[index].distance_squared))
		weighted += (pairs[index].displacement as Vector2) * weight
		total += weight
	return point + weighted / total if total > 0 else point

func _save_version_checks() -> void:
	var router := root.get_node("SceneRouter")
	var saved_state := _state_payload()
	_check(isolated_slots.call("save_to_slot", 0), "actual SaveManager writes v14 fixture to isolated slot")
	var template := _json(String(isolated_slots.call("slot_path", 0)))
	var upgrade := CANDIDATE_ID if candidate_stage else &""
	for old_version in [12, 13]:
		var old_scene := load(LEGACY_PATH if old_version == 12 else "res://data/scenes/world_map_jianghu_v13_staging.tres") as SceneScript
		_check(old_scene != null and old_scene.map_layout != null, "independent historical coordinate source %d exists" % old_version)
		if old_scene == null: continue
		for old_portal: Dictionary in old_scene.map_layout.portals:
			var id := String(old_portal.get("id"))
			var old_foot := _point(old_portal.get("pos"))
			var target := String(old_portal.get("target_scene"))
			var expected := Vector2(-INF, -INF)
			for p: Dictionary in world.map_layout.portals:
				if String(p.get("id")) == id: expected = _point(p.get("pos"))
			var historic := template.duplicate(true)
			historic.current_field = String(old_scene.scene_id)
			historic.navigation = {
				"current_field": String(old_scene.scene_id), "current_field_spawn": [old_foot.x, old_foot.y],
				"portal_return_spawns": {"%s->%s" % [target, String(old_scene.scene_id)]: [old_foot.x, old_foot.y]},
			}
			# Absence of this field must infer 12/13, independently of JSON save
			# schema version=14. Explicit coordinate version is tested separately.
			_write_isolated_json(0, historic)
			_check(isolated_slots.call("get_save_field_id", 0, upgrade) == active_id, "normal/candidate save preview resolves correct fresh world: %d %s" % [old_version, id])
			_check(isolated_slots.call("load_from_slot", 0, upgrade), "actual missing-version historic save load: %d %s" % [old_version, id])
			var migrated: Dictionary = router.call("get_navigation_state")
			var foot := _point(migrated.get("current_field_spawn"))
			_check(router.call("get_current_field_id") == active_id and int(migrated.get("world_map_version", -1)) == 14, "historic coordinate scope upgraded to 14: " + id)
			_check(foot.distance_to(expected) * WORLD_SIZE.length() < .03 and _foot_clear(foot * WORLD_SIZE), "historic portal maps exact matching live gateway with complete feet: " + id)
			var returns: Dictionary = migrated.get("portal_return_spawns", {})
			_check(returns.has("%s->%s" % [target, String(active_id)]), "paired world-side return key migrated: " + id)
			if returns.has("%s->%s" % [target, String(active_id)]):
				_check(_point(returns["%s->%s" % [target, String(active_id)]]).distance_to(expected) < .00001, "paired old return point migrated once: " + id)
			_check(isolated_slots.call("save_to_slot", 1), "persist upgraded navigation in isolated slot")
			_check(isolated_slots.call("load_from_slot", 1, upgrade), "reload explicit coordinate v14 save")
			_check(_domain_equal(router.call("get_navigation_state"), migrated), "second load does not migrate coordinates a second time: " + id)
			_check(_domain_equal(_state_payload(), saved_state), "coordinate migration does not trigger reward/dialog/inventory side effects: " + id)
	for free_point in [Vector2(.5, .5), Vector2(.78, .34), Vector2(.94, .54), Vector2(.63, .92)]:
		var historic := template.duplicate(true)
		historic.current_field = String(WORLD_ID)
		historic.navigation = {"current_field": String(WORLD_ID), "current_field_spawn": [free_point.x, free_point.y], "world_map_version": 12}
		_write_isolated_json(0, historic)
		_check(isolated_slots.call("load_from_slot", 0, upgrade), "explicit v12 free-roam JSON loads")
		var migrated: Dictionary = router.call("get_navigation_state")
		_check(_foot_clear(_point(migrated.get("current_field_spawn")) * WORLD_SIZE), "old free coordinate repaired onto real new safe land")
		_check(isolated_slots.call("save_to_slot", 1) and isolated_slots.call("load_from_slot", 1, upgrade), "actual upgraded free-roam JSON round trip")
		_check(_domain_equal(migrated, router.call("get_navigation_state")), "free-roam v14 coordinates are idempotent")
	var immutable_old := load(LEGACY_PATH) as SceneScript
	var exact_free_count := 0
	for y in range(20, 85, 8):
		if exact_free_count >= 4: break
		for x in range(20, 85, 8):
			if exact_free_count >= 4: break
			var old_point := Vector2(x, y) / 100.0
			var expected := _independent_free_mapping(immutable_old, old_point)
			if not expected.is_finite() or not _raw_foot_reason(world, expected).is_empty(): continue
			var far_from_gateways := true
			for portal: Dictionary in world.map_layout.portals:
				if ((_point(portal.get("pos")) - expected) * WORLD_SIZE).length() <= 64: far_from_gateways = false
			if not far_from_gateways: continue
			var historic := template.duplicate(true)
			historic.current_field = String(WORLD_ID)
			historic.navigation = {"current_field": String(WORLD_ID), "current_field_spawn": [old_point.x, old_point.y], "world_map_version": 12}
			_write_isolated_json(0, historic)
			_check(isolated_slots.call("load_from_slot", 0, upgrade), "independently mapped nonportal free-coordinate JSON actually loads")
			var actual := _point(router.call("get_navigation_state").get("current_field_spawn"))
			_check(((actual - expected) * WORLD_SIZE).length() < .03, "free legacy coordinate exactly preserves independent local mapping without unnecessary repair: old=%s expected=%s actual=%s" % [old_point, expected, actual])
			for portal: Dictionary in world.map_layout.portals:
				_check(((actual - _point(portal.get("pos"))) * WORLD_SIZE).length() > 64, "safe free-coordinate migration is not unconditional nearest-portal absorption")
			exact_free_count += 1
	_check(exact_free_count >= 3, "multiple independently safe nonportal free positions distinguish local mapping from portal snapping")
	var current_foot := world.player_spawn
	for explicit_version in [false, true]:
		var current_save := template.duplicate(true)
		current_save.current_field = String(CANDIDATE_ID if candidate_stage else WORLD_ID)
		current_save.navigation = {"current_field": current_save.current_field, "current_field_spawn": [current_foot.x, current_foot.y]}
		if explicit_version: current_save.navigation["world_map_version"] = 14
		if not candidate_stage and not explicit_version: continue # canonical absent historically means v12.
		_write_isolated_json(0, current_save)
		_check(isolated_slots.call("load_from_slot", 0, upgrade), "current v14 JSON with explicit or candidate-inferred version loads")
		var current_nav: Dictionary = router.call("get_navigation_state")
		_check(int(current_nav.get("world_map_version", -1)) == 14 and _point(current_nav.get("current_field_spawn")).distance_to(current_foot) < .000001, "current v14 free coordinate remains exact rather than migrating twice")
	# Room coordinates are NOT world coordinates. Only the world-side remembered
	# return key/value migrates, and this version persists while in the room.
	var old := load(LEGACY_PATH) as SceneScript
	var anchor: Dictionary = old.map_layout.portals[0]
	var indoor := String(anchor.get("target_scene"))
	var room_foot := Vector2(.25, .78)
	var old_world_foot := _point(anchor.get("pos"))
	var indoor_save := template.duplicate(true)
	indoor_save.current_field = indoor
	indoor_save.navigation = {"current_field": indoor, "current_field_spawn": [room_foot.x, room_foot.y], "world_map_version": 12, "portal_return_spawns": {
		"world_map_jianghu->%s" % indoor: [room_foot.x, room_foot.y],
		"%s->world_map_jianghu" % indoor: [old_world_foot.x, old_world_foot.y]}}
	_write_isolated_json(0, indoor_save)
	_check(isolated_slots.call("load_from_slot", 0, upgrade), "indoor old-world return-context JSON loads")
	var nav: Dictionary = router.call("get_navigation_state")
	_check(router.call("get_current_field_id") == StringName(indoor) and _point(nav.get("current_field_spawn")).distance_to(room_foot) < .000001, "indoor location remains exact, not reprojected as world land")
	_check(int(nav.get("world_map_version", -1)) == 14, "world-side coordinate version retained while current field is indoors")
	_check(_point(nav.portal_return_spawns.get("%s->%s" % [String(active_id), indoor])).distance_to(room_foot) < .000001, "destination-side remembered room value unchanged; only route key changes")
	_check(isolated_slots.call("save_to_slot", 1) and isolated_slots.call("load_from_slot", 1, upgrade), "indoor v14 return context saves and reads")
	_check(_domain_equal(nav, router.call("get_navigation_state")), "indoor return migration is also idempotent")
	await _open_world(world.player_spawn)

func _depth_order(player: Node2D, prop: Sprite2D, front: bool) -> bool:
	if player.z_index != prop.z_index:
		return player.z_index > prop.z_index if front else player.z_index < prop.z_index
	if player.get_parent() != prop.get_parent(): return false
	return player.get_index() > prop.get_index() if front else player.get_index() < prop.get_index()

func _set_idle(direction: Vector2) -> void:
	var player: Node = field.get("_player")
	player.call("set_walk_direction", direction, false)
	var sprite: Sprite2D = player.get("sprite")
	sprite.frame = 0
	player.set("_frame_timer", 0.0)

func _prop_alpha_station(d: Dictionary, prop: Sprite2D, front: bool, minimum_hits: int = 1, require_corridor: bool = false, source_alpha_threshold: float = .12) -> Dictionary:
	# Frozen fifth original-PNG exhaustive 1px proof found this legitimate
	# northern stand, missed by the earlier 8px lattice. Normal downstream
	# fixture/physics/current-frame/depth/ghost checks still execute unchanged.
	if String(d.get("id")) == "native_rock_foothill" and not front and not require_corridor:
		var verified_point := Vector2(1604,1050)
		var verified_player: Node2D = field.get("_player")
		if _foot_clear(verified_point) and _planning_collisions(verified_point).is_empty():
			verified_player.position = verified_point
			_set_idle(Vector2.DOWN)
			verified_player.call("refresh_depth_sort")
			var verified_hits := _actual_actor_alpha_intersection(prop)
			if verified_hits >= minimum_hits and _depth_order(verified_player,prop,false):
				return {"point": verified_point,"facing":Vector2.DOWN,"hits":verified_hits}
	var base_y := float(d.get("depth_sort_foot_y")) * WORLD_SIZE.y
	var center := _point(d.get("pos")) * WORLD_SIZE
	var collision_center := center + _point(d.get("collision_offset", Vector2.ZERO)) * WORLD_SIZE
	var size := _point(d.get("collision_size", Vector2.ZERO)) * WORLD_SIZE
	var physical := Rect2(collision_center - size * .5, size)
	var gap := WORLD_SIZE.x * .004 + 10 + 3
	var candidates: Array[Vector2] = []
	for delta_y in range(9, 97, 4):
		var y := base_y + delta_y if front else base_y - delta_y
		for side in [-1, 1]:
			var x := physical.position.x - gap if side < 0 else physical.end.x + gap
			for outward in [0, 4, 8, 12]: candidates.append(Vector2(x + side * outward, y))
		candidates.append(Vector2(collision_center.x, y))
	# A city collision may extend several hundred pixels north of the foot.
	# The old foot±96 domain could never reach its legitimate roof-behind
	# ground. Bound the additional search by REAL alpha extent plus actual
	# current actor footprint, rather than an arbitrary radius/blank rectangle.
	var player: Node2D = field.get("_player")
	var prop_bounds := _alpha_bounds_world_local(prop)
	# Source LINEAR filtering can extend nonzero alpha one source texel beyond
	# the nontransparent source rect. Use conservative transformed bounds.
	var source_frame := _sprite_frame(prop,prop.texture.get_image())
	var container: Node2D = field.get("world_container")
	var transform_to_world := container.global_transform.affine_inverse()*prop.global_transform
	var source_texel := transform_to_world.basis_xform(prop.get_rect().size/Vector2(source_frame.size))
	prop_bounds = prop_bounds.grow(maxf(absf(source_texel.x),absf(source_texel.y)))
	var actor_relative := Rect2()
	var first_direction := true
	for facing: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_set_idle(facing)
		var extent := _alpha_bounds_world_local(player.get("sprite"))
		extent.position -= player.position
		actor_relative = extent if first_direction else actor_relative.merge(extent)
		first_direction = false
	var domain := Rect2(prop_bounds.position - actor_relative.end, prop_bounds.size + actor_relative.size)
	var y_min := maxi(0, ceili(domain.position.y))
	var y_max := mini(int(WORLD_SIZE.y) - 1, floori(domain.end.y))
	var specific_dense := source_alpha_threshold < .12 or (String(d.get("id")) == "native_rock_foothill" and not front) or (String(d.get("id")) == "original_grove_11" and front)
	if front: y_min = maxi(y_min, floori(base_y) + (1 if specific_dense else 9))
	else: y_max = mini(y_max, ceili(base_y) - (1 if specific_dense else 9))
	var x_min := maxi(0, ceili(domain.position.x))
	var x_max := mini(int(WORLD_SIZE.x) - 1, floori(domain.end.x))
	var spacing := 1 if specific_dense else 8
	for y in range(y_min, y_max + 1, spacing):
		for x in range(x_min, x_max + 1, spacing): candidates.append(Vector2(x, y))
	for point: Vector2 in candidates:
		if not _foot_clear(point): continue
		if require_corridor and _movement_axis(point) == Vector2.ZERO: continue
		player.position = point
		player.call("refresh_depth_sort")
		if not _depth_order(player, prop, front): continue
		for facing: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			_set_idle(facing)
			var hits := _actual_actor_alpha_intersection(prop,source_alpha_threshold)
			if hits >= minimum_hits: return {"point": point, "facing": facing, "hits": hits,"source_alpha_threshold":source_alpha_threshold}
	print("[WorldV14AlphaSearch] id=%s front=%s source_alpha_world=%s actor_relative=%s actual_bounded_domain=%s candidates=%d required_hits=%d corridor=%s no_qualifying_legal_currentalpha_found" % [String(d.get("id")),front,prop_bounds,actor_relative,domain,candidates.size(),minimum_hits,require_corridor])
	return {}

func _grove_front_continuous_fullfoot_denial(d: Dictionary, prop: Sprite2D) -> bool:
	# Classification is recomputed against THIS run's raw mask/source/frame;
	# no frozen fifth coordinates, row colours or cached report are accepted.
	var player: Node2D = field.get("_player")
	var container: Node2D = field.get("world_container")
	var relative := Rect2()
	var first := true
	var maximum_visual_offset := -INF
	for facing: Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		_set_idle(facing)
		var actor: Sprite2D = player.get("sprite")
		var bounds := _alpha_bounds_world_local(actor)
		bounds.position -= player.position
		relative = bounds if first else relative.merge(bounds)
		first = false
		maximum_visual_offset = maxf(maximum_visual_offset,actor.position.y+float(actor.texture.get_height())*actor.scale.y*.45)
	var source_frame := _sprite_frame(prop,prop.texture.get_image())
	var map := container.global_transform.affine_inverse()*prop.global_transform
	var texel := map.basis_xform(prop.get_rect().size/Vector2(source_frame.size))
	var bounds := _alpha_bounds_world_local(prop).grow(maxf(absf(texel.x),absf(texel.y)))
	var domain := Rect2(bounds.position-relative.end,bounds.size+relative.size).intersection(Rect2(Vector2.ZERO,WORLD_SIZE))
	var base_y := float(d.get("depth_sort_foot_y"))*WORLD_SIZE.y
	# Union over facings: the largest offset yields the earliest physical foot
	# that could be visually in front, conservatively including every facing.
	var lower_y := maxf(domain.position.y,base_y-maximum_visual_offset)
	var upper_y := minf(domain.end.y,WORLD_SIZE.y-6.0)
	var oracle := _raw_oracle(world)
	var raw := oracle.get("mask") as Image
	if raw==null or bool(oracle.get("invalid",false)):
		_check(false,"current raw mask is required for continuous boundary classification"); return false
	var covered := 0
	var open := 0
	if lower_y < upper_y:
		var lo := Vector2i(maxi(0,roundi(domain.position.x/WORLD_SIZE.x*(raw.get_width()-1))-1),roundi((lower_y+6.0)/WORLD_SIZE.y*(raw.get_height()-1)))
		var hi := Vector2i(mini(raw.get_width()-1,roundi(domain.end.x/WORLD_SIZE.x*(raw.get_width()-1))+1),mini(raw.get_height()-1,roundi((upper_y+6.0)/WORLD_SIZE.y*(raw.get_height()-1))))
		for y in range(lo.y,hi.y+1):
			for x in range(lo.x,hi.x+1):
				covered += 1
				var rgba := raw.get_pixel(x,y)
				if rgba.a>=.5 and maxf(rgba.r,maxf(rgba.g,rgba.b))>=.5: open+=1
		_check(covered>0 and open==0,"current continuous meaningful front domain has every south-foot raw cell denied: "+String(d.id))
	else:
		_check(lower_y>=WORLD_SIZE.y-6.0,"entire current front domain has southern foot outside canvas: "+String(d.id))
	print("[WorldV14BoundaryClassification] id=%s current_frame0_four_direction_domain=%s front_lower_y=%.9f safe_upper_y=%.9f raw_south_cells=%d open=%d; continuous current-idle fullfoot denial only, not all animations" % [String(d.id),domain,lower_y,upper_y,covered,open])
	# Never place the actor at an illegal front point. Its current legal rear
	# evidence remains in the ordinary positive loop; illegal entity/boundary
	# samples below are explicit source-fullfoot negatives.
	var middle_x := domain.get_center().x
	for y in [lower_y+.001,upper_y,WORLD_SIZE.y-3.0]:
		_check(not _raw_foot_reason(world,Vector2(middle_x,y)/WORLD_SIZE).is_empty(),"declared unavailable front/boundary station cannot pass center-only: "+String(d.id))
	return open==0 and (covered>0 or lower_y>=WORLD_SIZE.y-6.0)

func _independent_prop_runtime_checks() -> void:
	_collect_runtime()
	var south_positive := 0
	var count := 0
	var strong_behind := 0
	for d: Dictionary in world.map_layout.visual_objects:
		var id := String(d.get("id", ""))
		if not bool(d.get("sort_by_feet", false)) or not d.has("collision_size"): continue
		if not runtime_props.has(id): continue
		count += 1
		var prop: Sprite2D = runtime_props[id]
		var center := _point(d.get("pos")) * WORLD_SIZE + _point(d.get("collision_offset", Vector2.ZERO)) * WORLD_SIZE
		var size := _point(d.get("collision_size")) * WORLD_SIZE
		var footprint := Rect2(center - size * .5, size)
		var open_in_footprint := 0
		for y in range(ceili(footprint.position.y), floori(footprint.end.y) + 1, 4):
			for x in range(ceili(footprint.position.x), floori(footprint.end.x) + 1, 4):
				if _foot_clear(Vector2(x, y)): open_in_footprint += 1
		_check(open_in_footprint == 0, "entire independent prop bottom blocks every <=4px center: " + id)
		for front in [false, true]:
			var station := _prop_alpha_station(d, prop, front)
			if station.is_empty() and id=="original_grove_11" and front:
				_check(_grove_front_continuous_fullfoot_denial(d,prop),"unavailable current grove front is proven complete-foot negative, not skipped")
				continue
			var soft_boundary := false
			if station.is_empty() and id=="native_cliff_south" and not front:
				# Thin low-lying model alpha can intersect only its filtered edge
				# without permitting an actor inside its full XZ collision. This is
				# a separate micro-alpha/ghost case, not lowered global solid tests.
				station = _prop_alpha_station(d,prop,false,1,false,.01)
				soft_boundary = not station.is_empty()
			_check(not station.is_empty(), "legal current-frame actual-alpha %s station exists: %s" % ["front" if front else "behind", id])
			if station.is_empty(): continue
			var point: Vector2 = station.point
			_check(await _place_fixture(point), "depth station complete-foot fixture: " + id)
			_set_idle(station.facing)
			var player: Node2D = field.get("_player")
			var threshold := .01 if soft_boundary else .12
			var hits := _actual_actor_alpha_intersection(prop,threshold)
			if soft_boundary:
				_check(_planning_collisions(point).is_empty(),"low cliff edge fixture does not physically enter the model")
				print("[WorldV14SoftEdge] id=%s current_source_alpha_threshold=.01 hits=%d; separate filtered micro-edge case, NOT full solid-body occlusion" % [id,hits])
			_check(hits > 0 and _foot_clear(point), "real currently cropped frame intersects entity alpha while feet stay legal: %s %s hits=%d" % [id, "front" if front else "behind", hits])
			if not front and not soft_boundary and hits>0: strong_behind+=1
			_check(_depth_order(player, prop, front), "effective same-parent/sibling or strict band order correct: %s %s" % [id, "front" if front else "behind"])
			if point.y > 2048:
				_check(player.z_index > 255 and prop.z_index > 255, "actual southern alpha intersection is not clamped at old255: " + id)
				if front: south_positive += 1
			var ghost_evidence := await _ghost_mask_check(id + (" front" if front else " behind"))
			if not front:
				_check(int(ghost_evidence.pixels) > 0, "actual behind alpha remains visible as local-only ghost: " + id)
			elif int(ghost_evidence.pixels) == 0:
				ghost_front_inactive += 1
			print("[WorldV14Depth] id=%s front=%s foot=%s facing=%s actor_z=%d prop_z=%d actual_frame_hits=%d" % [id, front, point, station.facing, player.z_index, prop.z_index, hits])
			await _capture("depth_%s_%s" % [id, "front" if front else "behind"])
	_check(count >= 16, "independent landmark physics/depth is checked throughout all destinations")
	_check(strong_behind>=16,"at least16 real solid-alpha behind cases retained; micro-edge exception does not count as strong coverage")
	_check(south_positive >= 3, "southern Jinling/Zhuwei/Mingwu-height genuine-alpha front cases covered")
	_check(ghost_positive >= 16 and ghost_south_positive >= 3 and ghost_front_inactive >= 3, "actual behind, southern ghost and inactive front alpha regressions covered")

func _build_pathfinder() -> FullFootPlanningGrid:
	# The graph chooses a route only. Its existence is never a runtime pass:
	# every resulting edge is resampled at <=4px, then driven through Player.
	var size: Vector2 = field.get("_world_size")
	var grid := FullFootPlanningGrid.new()
	grid.build(size,Callable(self,"_planner_clear"))
	print("[WorldV14Planner] nodes=",grid.graph.get_point_count()," rejected_nonfullfoot_edges=",grid.rejected_edges)
	return grid

func _planning_collisions(point: Vector2) -> Array[Dictionary]:
	# Runtime NPC physical bodies are separate from authored walk masks. Query
	# the REAL player's present body at the proposed foot, without moving it,
	# changing any NPC or weakening the independent full-foot oracle.
	if not is_instance_valid(field): return [{"invalid_scene_physics":true}]
	var player := field.get("_player") as CharacterBody2D
	if player == null: return [{"invalid_player_physics":true}]
	var shape := player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or shape.shape == null or shape.disabled: return [{"invalid_player_body_shape":true}]
	var container: Node2D = field.get("world_container")
	if container == null: return [{"invalid_world_transform":true}]
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	query.transform = shape.global_transform
	query.transform.origin += container.to_global(point) - player.global_position
	query.collision_mask = player.collision_mask
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	return player.get_world_2d().direct_space_state.intersect_shape(query,8)

func _planner_clear(point: Vector2) -> bool:
	return _foot_clear(point) and _planning_collisions(point).is_empty()

func _nearest_grid_point(grid: Variant, position: Vector2) -> Vector2i:
	var center := Vector2i((position - grid.offset) / grid.cell_size)
	var closest := Vector2i(-1, -1)
	var distance := INF
	for y in range(center.y - 4, center.y + 5):
		for x in range(center.x - 4, center.x + 5):
			var id := Vector2i(x, y)
			if not grid.is_in_boundsv(id) or grid.is_point_solid(id): continue
			var point: Vector2 = grid.get_point_position(id)
			var d := point.distance_squared_to(position)
			if d >= distance: continue
			var clear := true
			for sample: Vector2 in _dense_polyline([position, point]):
				if not _planner_clear(sample):
					clear = false
					break
			if clear:
				closest = id
				distance = d
	return closest

func _plan_to(target: Vector2, grid: FullFootPlanningGrid) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var player: Node2D = field.get("_player")
	var start_id := _nearest_grid_point(grid, player.position)
	var finish_id := _nearest_grid_point(grid, target)
	if start_id.x < 0 or finish_id.x < 0: return result
	var path := grid.get_point_path(start_id, finish_id)
	if path.is_empty(): return result
	result.append(player.position)
	for point: Vector2 in path: result.append(point)
	result.append(target)
	return result

func _input_path(points: Array, description: String) -> bool:
	if points.size() < 2:
		_check(false, "actual input path exists: " + description)
		return false
	var dense := _dense_polyline(points)
	var bad := 0
	for point: Vector2 in dense:
		full_foot_samples += 1
		if not _foot_clear(point): bad += 1
	_check(bad == 0, "complete <=4px planned input path foot clearance: %s n=%d bad=%d" % [description, dense.size(), bad])
	if bad > 0: return false
	var success := true
	for raw_point: Variant in points.slice(1):
		var point := _point(raw_point)
		if not await _drive_to(point):
			var player: Node2D = field.get("_player")
			_check(false, "real Player input reached %s waypoint %s; actual=%s" % [description, point, player.position if player != null else Vector2(-1, -1)])
			success = false
			break
	_check(success, "real continuous production input, not graph-only proof: " + description)
	return success

func _safe_stand_near(point: Vector2, radius: int = 80) -> Vector2:
	if _foot_clear(point): return point
	for distance in range(4, radius + 1, 4):
		for i in range(24):
			var candidate := point + Vector2.from_angle(TAU * i / 24.0) * distance
			if _foot_clear(candidate): return candidate
	return Vector2(-INF, -INF)

func _place_fixture(point: Vector2) -> bool:
	# Only isolated depth/seam/screenshot starting fixtures may relocate. Travel
	# and portal reachability remain continuous input from the real prior spawn.
	if not _foot_clear(point): return false
	_release_movement()
	var player: Node2D = field.get("_player")
	player.position = point
	player.velocity = Vector2.ZERO
	player.call("refresh_depth_sort")
	root.get_node("SceneRouter").call("set_field_return_spawn", point / (field.get("_world_size") as Vector2))
	for step in range(4): await physics_frame
	return _foot_clear(player.position) and player.position.distance_to(point) < .01

func _seam_runtime_checks() -> void:
	var seams: Array = source_contract.get("seams", [])
	_check(seams.size() == 12, "all 12 internal borders represented, not old six-border plan")
	var seen: Dictionary = {}
	for seam: Dictionary in seams:
		var id := String(seam.get("id", ""))
		_check(not seen.has(id), "boundary identity is unique: " + id)
		seen[id] = true
		var witness := _point(seam.get("witness_px"))
		var axis := String(seam.get("axis", ""))
		var line := float(seam.get("line_px", -1))
		_check(axis in ["x", "y"] and witness.is_finite(), "boundary has true geometric axis/witness: " + id)
		_check(absf((witness.x if axis == "x" else witness.y) - line) < .01, "boundary witness sits on the real crop boundary: " + id)
		var open := String(seam.get("status", "open")) == "open"
		if open:
			# Follow the actual curved road, not an invented perpendicular chord.
			var path: Array[Vector2] = []
			var closest := INF
			for route: Dictionary in source_contract.get("routes", []):
				var dense := _dense_polyline(route.get("points_px", []))
				for i in dense.size():
					var distance := dense[i].distance_to(witness)
					if distance >= closest: continue
					closest = distance
					path.clear()
					for j in range(maxi(0, i - 13), mini(dense.size(), i + 14)): path.append(dense[j])
			_check(closest <= 2.01 and path.size() >= 3, "boundary witness belongs to actual curved road: " + id)
			if closest > 2.01 or path.size() < 3: continue
			var a: Vector2 = path.front()
			var b: Vector2 = path.back()
			_check((a.x - line) * (b.x - line) < 0 if axis == "x" else (a.y - line) * (b.y - line) < 0, "road subpath crosses real crop boundary: " + id)
			_check(await _place_fixture(a), "legal independent border starting fixture: " + id)
			if await _input_path(path, "border " + id + " forward"):
				path.reverse()
				_check(await _input_path(path, "border " + id + " backward"), "two-way genuine cross-crop input: " + id)
				seam_input_count += 1
				await _capture("boundary_" + id)
		else:
			_check(not _foot_clear(witness), "declared natural blocked seam truly refuses full foot: " + id)
			_check(not String(seam.get("blocked_reason", "")).is_empty(), "blocked border has authored natural semantic reason: " + id)
			# Alternative connectivity is proven by the subsequently driven full
			# portal tour. Never whitewash a legitimate sea/ridge for seam count.
	_check(seen.size() == 12, "every internal border tested independently")

func _world_routes_and_region_views() -> void:
	_route_foot_checks()
	world_pathfinder = _build_pathfinder()
	_check(world_pathfinder != null, "full-foot route planning uses actual production mask and blockers")
	for row in range(3):
		for col in range(3):
			var target := _safe_stand_near(Vector2((col + .5) * TILE_SIZE.x, (row + .5) * TILE_SIZE.y), 480)
			_check(target.is_finite(), "region %d,%d has an actual safe land camera stand" % [row, col])
			if target.is_finite() and await _place_fixture(target):
				await _capture("region_r%dc%d" % [row, col])
	await _seam_runtime_checks()
	# Portal tour starts again at authored production entry, then never
	# teleports between portals: actual destinations return us to live gateways.
	_check(await _open_world(world.player_spawn), "real default production entry restored for complete tour")
	_collect_runtime()

func _return_through_actual_exit(target_id: StringName) -> bool:
	var exits: Array = field.get("_exit_nodes")
	var reverse: Node2D
	for zone: Node2D in exits:
		if String(zone.get("target_scene_id")) in [String(WORLD_ID), String(CANDIDATE_ID)] or String(zone.get("action")) == "world_map":
			reverse = zone
			break
	_check(reverse != null, "destination has an actual public world return ExitZone: " + String(target_id))
	if reverse == null: return false
	var stand := _safe_stand_near(reverse.position, 70)
	_check(stand.is_finite(), "destination reverse marker has legal full-foot standing point: " + String(target_id))
	if not stand.is_finite(): return false
	var grid := _build_pathfinder()
	if not await _input_path(_plan_to(stand, grid), "destination return " + String(target_id)): return false
	await process_frame
	_check(bool(reverse.get("_in_range")), "real physics body enters reverse ExitZone: " + String(target_id))
	var marker: Sprite2D = reverse.get("marker_visual")
	var screen := marker.get_global_transform_with_canvas().origin if marker != null else reverse.get_global_transform_with_canvas().origin
	await _pointer(screen)
	return await _wait_field(active_id)

func _portal_runtime_tour() -> void:
	var router := root.get_node("SceneRouter")
	var index := 0
	for p: Dictionary in world.map_layout.portals:
		var id := String(p.get("id"))
		var target_id := StringName(p.get("target_scene"))
		var foot := _point(p.get("pos")) * WORLD_SIZE
		_collect_runtime()
		var player: Node2D = field.get("_player")
		print("[WorldV14Portal] %d/16 %s from=%s to=%s" % [index + 1, id, player.position, foot])
		if not await _input_path(_plan_to(foot, world_pathfinder), "world gateway " + id):
			index += 1
			continue
		await _capture("portal_" + id)
		var zone: Node2D = runtime_portals.get(String(target_id))
		_check(zone != null and bool(zone.get("_in_range")), "real overlap reaches actual world portal: " + id)
		if zone == null:
			index += 1
			continue
		if index % 2 == 0:
			await _key(KEY_SPACE)
		else:
			var marker: Sprite2D = zone.get("marker_visual")
			await _pointer(marker.get_global_transform_with_canvas().origin)
		if not await _wait_field(target_id):
			index += 1
			continue
		portal_input_count += 1
		_check(router.call("get_current_field_id") == target_id, "real key/pointer entered exact unchanged destination: " + id)
		var destination: SceneScript = field.get("_current_scene")
		_check(destination.resource_path == "res://data/scenes/%s.tres" % String(target_id), "ordinary full gameplay destination, not a disabled QA substitute: " + id)
		var local_player: Node2D = field.get("_player")
		_check(int(local_player.get_meta("depth_band_max", 255)) == 255 and int(field.call("_scene_depth_band_max")) == 255, "v14 depth override clears in ordinary destination: " + id)
		_check(_foot_clear(local_player.position), "actual destination repaired arrival has complete feet: " + id)
		await _normal_dialog_finish()
		if await _return_through_actual_exit(target_id):
			player = field.get("_player")
			_check(player.position.distance_to(foot) < .02, "paired real exit returns to exact live world gateway: " + id)
			_check(int(router.call("get_navigation_state").get("world_map_version", -1)) == 14, "world coordinate version persists across destination: " + id)
			_check(_foot_clear(player.position), "actual gateway return is not on roof/water/object: " + id)
		else:
			# Restore only to continue collecting independent failed cases. This
			# is not counted as a successful paired return or input traversal.
			_check(false, "actual paired world return failed: " + id)
			await _open_world(p.get("pos"))
		index += 1
	_check(portal_input_count == 16, "all 16 real portal transitions completed through actual input")

func _overview_check() -> void:
	await _key(KEY_M)
	var panel: Control = field.get("_world_map_panel")
	_check(panel != null and panel.visible, "actual M input opens live overview")
	if panel == null: return
	var texture: TextureRect = panel.get("map_texture")
	_check(texture != null and texture.texture != null and texture.texture.resource_path == ART_DIR + "overview.png", "actual overview uses v14 full-world art, not cached canonical legacy")
	var labels := 0
	for child: Node in (panel.get("map_rect") as Node).get_children():
		if child is Label and child.has_meta("world_map_runtime"): labels += 1
	_check(labels == 16, "overview contains all sixteen actual world labels")
	await _capture("overview_M")
	await _key(KEY_M)
	_check(not panel.visible, "actual M toggles overview closed and returns movement")

func _frozen_checks() -> void:
	var frozen := _json(FROZEN_PATH)
	var rows: Array = frozen.get("files", [])
	_check(rows.size() == 403, "independent baseline contains 403 recorded files")
	var changed := 0
	for row: Dictionary in rows:
		var path := String(row.get("Path", ""))
		var expected := String(row.get("Hash", "")).to_lower()
		var actual := FileAccess.get_sha256(path).to_lower() if FileAccess.file_exists(path) else "ABSENT"
		var canonical := path.replace("\\", "/").ends_with("/game/data/scenes/world_map_jianghu.tres")
		if canonical and not candidate_stage:
			_check(expected == LEGACY_SHA, "canonical baseline is precisely the preserved v12 SHA")
			_check(actual != expected, "canonical is deliberately activated, not a cached/legacy substitute")
			changed += 1 if actual != expected else 0
		else:
			_check(actual == expected, "frozen previous file unchanged: " + path)
			changed += 1 if actual != expected else 0
	_check(changed == (0 if candidate_stage else 1), "activation allowlist has exactly the expected canonical change")
	_check(FileAccess.file_exists(LEGACY_PATH) and FileAccess.get_sha256(LEGACY_PATH).to_lower() == LEGACY_SHA, "legacy coordinate evidence is the original byte-for-byte canonical resource")

func _asset_binding_checks() -> bool:
	world = load(active_path) as SceneScript
	_check(world != null, "fresh process loads selected production stage: " + active_path)
	if world == null or world.map_layout == null:
		_check(false, "world production layout exists")
		return false
	var layout := world.map_layout
	_check(world.scene_id == active_id and layout.schema_version == 14, "actual selected scene owns v14 schema and ID")
	_check(layout.design_size == Vector2i(WORLD_SIZE) and layout.display_at_native_size, "full nine-region native 4608x3072 size")
	_check(layout.resource_path == "res://data/maps/world_map_jianghu_layout_v14.tres", "actual formal layout binding is new, not staging alias")
	_check(world.background_path == ART_DIR + "visual.png" and layout.walkable_mask_path == ART_DIR + "walk.png", "runtime visual and nav resolve new v14 sources")
	_check(layout.travel_routes.size() >= 23, "runtime preserves primary and terminal route contract")
	for route: Dictionary in layout.travel_routes:
		_check(bool(route.get("baked_into_terrain", false)), "runtime route retains explicit baked ground semantics: " + String(route.get("id")))
		var authored: Dictionary = {}
		for entry: Dictionary in source_contract.get("routes", []):
			if String(entry.get("id")) == String(route.get("id")): authored = entry
		var points: PackedVector2Array = route.get("points", PackedVector2Array())
		var authored_points: Array = authored.get("points_px", [])
		_check(not authored.is_empty() and points.size() == authored_points.size() and absf(float(route.get("width_px", -1)) - float(authored.get("width_px", -2))) < .0001, "actual baked route retains source identity, width and count: " + String(route.get("id")))
		for i in mini(points.size(), authored_points.size()):
			_check((points[i] * WORLD_SIZE).distance_to(_point(authored_points[i])) < .001, "runtime route point equals actual projected production source")
	var old := load(LEGACY_PATH) as SceneScript
	_check(old != null, "original scene definition loads as immutable gameplay reference")
	if old != null:
		for name in ["on_enter_dialog", "on_enter_require_flag", "on_enter_once_flag", "bgm_path", "npcs", "hotspots", "is_walkable", "is_settlement", "encounter_groups", "encounter_enemy_ids", "encounter_require_flag", "encounter_step_distance", "encounter_chance", "trigger_zones"]:
			var property_exists := false
			for entry: Dictionary in old.get_property_list():
				if String(entry.name) == name: property_exists = true
			if property_exists:
				_check(_domain_equal(world.get(name), old.get(name)), "formal gameplay definition retained: " + name)
	var portal_ids: Dictionary = {}
	for p: Dictionary in layout.portals:
		var id := String(p.get("id", ""))
		_check(EXPECTED_DESTINATIONS.has(id) and not portal_ids.has(id), "existing portal identity unique: " + id)
		portal_ids[id] = p
		_check(String(p.get("target_scene", "")) == String(EXPECTED_DESTINATIONS.get(id, "MISSING")), "existing target retained: " + id)
		_check(String(p.get("require_flag", "")).is_empty() and not bool(p.get("staging_pending_asset", false)), "public portal is not pending/locked: " + id)
		var a := _point(p.get("pos"))
		_check(a.is_finite() and a.x > 0 and a.y > 0 and a.x < 1 and a.y < 1, "finite in-canvas portal: " + id)
		if old != null:
			var portal_found := false
			for prior: Dictionary in old.map_layout.portals:
				if String(prior.get("id")) == id:
					portal_found = true
					_check(p.get("target_scene") == prior.get("target_scene") and p.get("target_pos") == prior.get("target_pos"), "both destination-side fields unchanged: " + id)
			_check(portal_found, "portal belongs to original formal content: " + id)
	_check(portal_ids.size() == 16 and layout.portals.size() == 16, "all 16 formal destinations appear exactly once")
	var stream := world.streamed_background
	_check(stream != null, "production world has actual chunk streamer")
	if stream != null:
		_check(stream.resource_path == "res://data/background_sets/world_map_jianghu_v14_streamed.tres", "runtime streamer owns v14 path")
		var chunks: Array = stream.get_chunks(true)
		_check(chunks.size() == 9, "runtime chunk set has all nine unique regions")
		var keys: Dictionary = {}
		for d: Dictionary in chunks:
			var path := String(d.get("path", ""))
			_check(path.begins_with(ART_DIR + "chunks/") and ResourceLoader.exists(path), "actual imported unique v14 chunk: " + path)
			_check(not keys.has(path), "no repeated old texture/tile path: " + path)
			keys[path] = true
		_check(stream.get_preview_path(false) == ART_DIR + "overview.png", "overview resource belongs to fresh full map")
	return layout.schema_version == 14 and layout.design_size == Vector2i(WORLD_SIZE)

func _rect(value: Variant) -> Rect2:
	if value is Array and value.size() == 4:
		return Rect2(float(value[0]), float(value[1]), float(value[2]), float(value[3]))
	return Rect2()

func _source_object_pixel(d: Dictionary, point: Vector2) -> Color:
	var path := String(d.get("texture", ""))
	var image: Image = native_images.get(path)
	if image == null:
		image = _read_image(path)
		native_images[path] = image
	if image == null or image.is_empty(): return Color.TRANSPARENT
	var center := _point(d.get("pos")) * WORLD_SIZE
	var size := _point(d.get("render_size_px"))
	if not size.is_finite() or size.x <= 0 or size.y <= 0: return Color.TRANSPARENT
	var rect := Rect2(center - size * .5 if bool(d.get("centered", true)) else center, size)
	if not rect.has_point(point): return Color.TRANSPARENT
	var uv := (point - rect.position) / size
	return image.get_pixelv(Vector2i(uv * Vector2(image.get_size())))

func _declared_structure_support(point: Vector2) -> bool:
	for entry: Dictionary in source_contract.get("structure_entries", []):
		var rect := _rect(entry.get("rect_px", []))
		if not rect.has_point(point): continue
		var actual: Dictionary = support_geometry_cache.get(String(entry.get("id")), {})
		# Rect/alpha alone cannot legalize wet bed. Only independently projected
		# triangles from the actual captured support RES supply structural height.
		if actual.is_empty() or not _actual_support_at_screen(point, actual): continue
		var path := String(entry.get("texture_path", ""))
		var image: Image = native_images.get(path)
		if image == null:
			image = _read_image(path)
			native_images[path] = image
		var size := _point(entry.get("render_size_px"))
		var center := _point(entry.get("render_center_px"))
		if image == null or not size.is_finite() or size.x <= 0 or size.y <= 0: continue
		var uv := (point - center) / size + Vector2(.5, .5)
		if uv.x < 0 or uv.y < 0 or uv.x >= 1 or uv.y >= 1: continue
		if image.get_pixelv(Vector2i(uv * Vector2(image.get_size()))).a > .12: return true
	return false

func _raw_pixel_and_crop_checks() -> void:
	var fallback := "res://build/world_map_v14_second_shader_failure/visual.png"
	_check(FileAccess.file_exists(fallback) and FileAccess.get_sha256(ART_DIR + "visual.png") != FileAccess.get_sha256(fallback), "actual corrected native visual differs from archived shader-default failed capture; compiler log remains separate evidence")
	for name in ["visual", "land", "walk", "topology", "overview"]:
		var image := _read_image(ART_DIR + name + ".png")
		if image != null:
			_check(image.get_size() == Vector2i(WORLD_SIZE), "true full resolution source: " + name)
			native_images[name] = image
	if not native_images.has_all(["visual", "land", "walk", "topology"]): return
	var unique_visual: Dictionary = {}
	for row in range(3):
		for col in range(3):
			for name in ["visual", "land", "walk"]:
				var path := ART_DIR + "chunks/r%dc%d_%s.png" % [row, col, name]
				var chunk := _read_image(path)
				if chunk == null: continue
				_check(chunk.get_size() == TILE_SIZE, "chunk is native equal-scale size: " + path)
				var region := (native_images[name] as Image).get_region(Rect2i(Vector2i(col, row) * TILE_SIZE, TILE_SIZE))
				_check(chunk.get_format() == region.get_format() and chunk.get_data() == region.get_data(), "every pixel crop is from the actual full capture: " + path)
				if name == "visual": unique_visual[FileAccess.get_sha256(path)] = true
	_check(unique_visual.size() == 9, "all nine terrain crops have distinct actual pixel hashes, not reused images")
	# A separate raw pre-support navigation capture is required. White added to
	# its final counterpart may only lie over declared alpha-supported decks.
	var raw_path := String(manifest.get("raw_walk_path", ""))
	_check(raw_path.begins_with(ART_DIR) and FileAccess.file_exists(raw_path), "raw GPU walk evidence retained before explicit bridge support")
	if raw_path.is_empty() or not FileAccess.file_exists(raw_path): return
	var raw := _read_image(raw_path)
	if raw == null: return
	_check(raw.get_size() == Vector2i(WORLD_SIZE), "raw walk and final walk use identical full camera canvas")
	if raw.get_size() != Vector2i(WORLD_SIZE): return
	var nav: Image = native_images.walk
	var land: Image = native_images.land
	var unsupported := 0
	var erased := 0
	var water_open := 0
	var first_unsupported := Vector2i(-1, -1)
	for y in range(int(WORLD_SIZE.y)):
		for x in range(int(WORLD_SIZE.x)):
			var point := Vector2(x + .5, y + .5)
			var walkable := nav.get_pixel(x, y).r >= .5
			var raw_white := raw.get_pixel(x, y).r >= .5
			var dry := land.get_pixel(x, y).r >= .5
			if raw_white and not walkable: erased += 1
			if walkable and not raw_white:
				raw_added_support_pixels += 1
				if not _declared_structure_support(point):
					unsupported += 1
					if first_unsupported.x < 0: first_unsupported = Vector2i(x, y)
			if walkable and not dry and not _declared_structure_support(point): water_open += 1
			if not walkable and not dry: terrain_rejected_water += 1
	_check(erased == 0, "final support pass does not secretly erase raw navigation")
	_check(unsupported == 0, "all added white pixels have declared real structural alpha; bad=%d first=%s" % [unsupported, first_unsupported])
	_check(water_open == 0, "entire full map water is denied except genuine structural support; bad=%d" % water_open)
	_check(terrain_rejected_water > 0, "raw full map contains real blocked natural water")
	print("[WorldV14Pixels] raw_added_structure=%d unsupported=%d water_open=%d natural_water_denied=%d" % [raw_added_support_pixels, unsupported, water_open, terrain_rejected_water])

func _wait_field(id: StringName) -> bool:
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		var current := current_scene
		if is_instance_valid(current) and current.get("_current_scene") is SceneScript and current.get("_player") is Node2D:
			var definition: SceneScript = current.get("_current_scene")
			if definition.scene_id == id:
				field = current
				for settle in range(6): await physics_frame
				return true
	_check(false, "real production Field arrived: " + String(id))
	return false

func _normal_dialog_finish() -> bool:
	# Do not delete dialogs or blank story resources. Advance the real finite
	# introduction, taking the first real choice only where the content asks.
	var dialog := root.get_node("DialogPlayer")
	for step in range(80):
		if not bool(dialog.call("is_playing")): return true
		var node: Resource = dialog.get("_current_node")
		if node != null and not (node.get("choices") as Array).is_empty(): dialog.call("choose", 0)
		else: dialog.call("advance")
		for settle in range(4): await process_frame
	_check(false, "actual intro dialog completes without data stripping")
	return false

func _open_world(point: Variant = null) -> bool:
	# A real dialog end-action can already have queued a field transition.
	# Do not race that request or overwrite it with a QA navigation call.
	var deadline := Time.get_ticks_msec() + 30000
	while bool(root.get_node("LoadingManager").get("_transition_active")) and Time.get_ticks_msec() < deadline:
		await process_frame
	if bool(root.get_node("LoadingManager").get("_transition_active")):
		_check(false, "pending authored Loading transition finishes before opening world")
		return false
	root.get_node("SceneRouter").call("go_field_smart", active_id, point, "", 14)
	return await _wait_field(active_id)

func _collect_runtime() -> void:
	runtime_portals.clear()
	runtime_props.clear()
	for entry: Node in field.get("_exit_nodes"):
		runtime_portals[String(entry.get("target_scene_id"))] = entry
	for entry: Sprite2D in field.get("_scene_object_nodes"):
		runtime_props[String(entry.name).trim_prefix("SceneObject_")] = entry
	_check(runtime_portals.size() == 16, "all 16 actual ExitZone nodes spawned under production Field")
	_check(field.get("_world_size") == WORLD_SIZE, "real Field world canvas is the whole nine-region map")
	var player: Node2D = field.get("_player")
	_check(bool(player.get("_ground_anchored")), "formal travel actor position is its actual feet")
	_check(int(player.get_meta("depth_band_max", 255)) == 512, "v14-only Player southern depth range is 512")
	_check(int(field.call("_scene_depth_band_max")) == 512, "Field and Player share the same v14 depth range")
	var overlays := field.find_children("TravelRoute_*", "Line2D", true, false)
	_check(overlays.is_empty(), "baked production roads are not rendered twice as extra Line2D overlays")
	for prop: Sprite2D in runtime_props.values():
		_check(prop.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR, "actual v14 modular sprite explicitly uses production linear filtering: " + String(prop.name))
	for d: Dictionary in world.map_layout.visual_objects:
		var id := String(d.get("id", ""))
		_check(runtime_props.has(id), "actual independent sprite instantiated: " + id)
		if not runtime_props.has(id): continue
		var sprite: Sprite2D = runtime_props[id]
		_check(sprite.texture.resource_path == String(d.get("texture")), "runtime texture actually binds new source: " + id)
		_check(sprite.position.distance_to(_point(d.get("pos")) * WORLD_SIZE) < .01, "runtime object placement equals shared geographic contract: " + id)
		if bool(d.get("sort_by_feet", false)):
			var container: Node2D = field.get("world_container")
			var projected_foot := container.to_global(Vector2(0, float(d.get("depth_sort_foot_y")) * WORLD_SIZE.y)).y
			var expected := clampi(int(floor(projected_foot / 8.0)), 0, 512)
			_check(sprite.z_index == expected, "actual per-object foot depth, including south >2048: " + id)
			if id in ["native_herb_2_1", "native_herb_3_2"]:
				print("[WorldV14BandDiagnostic] id=%s actual_global_Vector2_Y=%.8f expected=%d actual=%d scalar_double_Y=%.16f" % [id, projected_foot, expected, sprite.z_index, float(d.get("depth_sort_foot_y")) * WORLD_SIZE.y])
		if d.has("collision_size"):
			var body := (field.get("_collision_layer") as Node).get_node_or_null("ObjectCollision_" + id) as StaticBody2D
			_check(body != null and body.collision_layer == 1, "paired physical object blocker exists: " + id)
			if body == null: continue
			var shape := body.get_child(0) as CollisionShape2D
			_check(shape != null and shape.shape is RectangleShape2D, "paired blocker is a real rectangle: " + id)
			if shape != null and shape.shape is RectangleShape2D:
				_check((shape.shape as RectangleShape2D).size.distance_to(_point(d.get("collision_size")) * WORLD_SIZE) < .01, "actual physical full footprint matches declaration: " + id)
				_check(shape.position.distance_to(_point(d.get("collision_offset", Vector2.ZERO)) * WORLD_SIZE) < .01, "actual physical offset matches visual anchor: " + id)

func _route_foot_checks() -> void:
	var route_ids: Dictionary = {}
	var terminal_ids: Dictionary = {}
	for route: Dictionary in source_contract.get("routes", []):
		var id := String(route.get("id", ""))
		_check(not route_ids.has(id), "road contract has unique identity: " + id)
		route_ids[id] = true
		var points: Array = route.get("points_px", [])
		_check(points.size() >= 2, "road has actual point sequence: " + id)
		var samples := _dense_polyline(points)
		var bad := 0
		var first_bad := Vector2(-1, -1)
		for point: Vector2 in samples:
			full_foot_samples += 1
			if not _foot_clear(point):
				bad += 1
				if first_bad.x < 0: first_bad = point
		_check(bad == 0, "<=4px entire road includes endpoint and 17 full-foot samples: %s count=%d bad=%d first=%s" % [id, samples.size(), bad, first_bad])
		if id.begins_with("portal_"):
			var portal_id := id.trim_prefix("portal_")
			terminal_ids[portal_id] = true
			for p: Dictionary in world.map_layout.portals:
				if String(p.get("id")) == portal_id and not samples.is_empty():
					_check(samples.back().distance_to(_point(p.get("pos")) * WORLD_SIZE) < .01, "terminal road reaches exact portal foot, no unsampled tail: " + portal_id)
	_check(terminal_ids.size() == 16, "all 16 gateways own a complete terminal road")
	_check(route_ids.size() >= 23, "complete primary and terminal roads, not the old pair sample")

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error("[WorldV14 FAIL] " + description)

func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		_check(false, "JSON exists: " + path)
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(value is Dictionary, "JSON object parses: " + path)
	return value if value is Dictionary else {}

func _point(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and value.size() == 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2(-INF, -INF)

func _read_image(path: String) -> Image:
	# Raw-source development QA intentionally bypasses import. Godot's export
	# warning still applies to Image.load; no claim of warning-free export support.
	var image := Image.new()
	var error := image.load(path)
	_check(error == OK and not image.is_empty(), "raw image loads: " + path)
	if error != OK: return null
	return image

func _actual_player_saves() -> Dictionary:
	# No read/write through SaveManager: retain the normal files byte-for-byte.
	var result: Dictionary = {}
	for slot in range(5):
		for suffix in ["", ".bak", ".tmp"]:
			var path := "user://save_%d.json%s" % [slot, suffix]
			result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT"
	return result

func _prepare_isolated_slots() -> void:
	isolated_dir = "user://qa_world_v14_%d" % Time.get_ticks_usec()
	var absolute := ProjectSettings.globalize_path(isolated_dir).simplify_path()
	var user_root := ProjectSettings.globalize_path("user://").simplify_path()
	_check(absolute.begins_with(user_root + "/") and absolute != user_root, "QA slots confined to unique user subdirectory")
	_check(DirAccess.make_dir_recursive_absolute(absolute) == OK, "isolated slot directory created")
	# Load after autoloads exist; an eager nested SaveManager subclass compiles
	# before the GameState global in check-only mode. Existing helper is read-only.
	isolated_slots = load(ISOLATED_MANAGER_PATH).new()
	isolated_slots.set("isolated_dir", isolated_dir)
	root.add_child(isolated_slots)
	for slot in range(5):
		_check(String(isolated_slots.call("slot_path", slot)).begins_with(isolated_dir + "/"), "all five slot paths isolated")

func _foot_samples(foot: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = [foot]
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		points.append(foot + Vector2(cos(angle) * 10.0, sin(angle) * 6.0))
	return points

func _foot_clear(point: Vector2) -> bool:
	if not is_instance_valid(field):
		return false
	var scene: SceneScript = field.get("_current_scene")
	var size: Vector2 = field.get("_world_size")
	return scene != null and size.x > 0 and size.y > 0 and _raw_foot_reason(scene, point / size).is_empty()

func _raw_oracle(scene: SceneScript) -> Dictionary:
	# Independently read source PNG/layout geometry. No Field/WorldV14 safe-foot
	# or repair helper is called by this oracle.
	if scene == null or scene.map_layout == null: return {}
	var layout := scene.map_layout
	var key := str(layout.get_instance_id())
	if raw_foot_oracles.has(key): return raw_foot_oracles[key]
	var size := Vector2(layout.design_size)
	var image: Image
	var tiles: Array[Dictionary] = []
	var invalid := size.x <= 0 or size.y <= 0
	if not String(layout.walkable_mask_path).is_empty(): image = Image.load_from_file(layout.walkable_mask_path)
	if not String(layout.walkable_mask_path).is_empty() and (image == null or image.is_empty()): invalid = true
	for entry: Dictionary in layout.walkable_mask_tiles:
		var path := String(entry.get("path", ""))
		var tile := Image.load_from_file(path) if not path.is_empty() else null
		var rect: Rect2 = entry.get("logical_rect", Rect2())
		if tile == null or rect.size.x <= 0 or rect.size.y <= 0: invalid = true
		tiles.append({"rect": rect, "image": tile})
	var shapes: Array[Dictionary] = []
	var objects: Array = source_contract.get("objects", []) if layout.schema_version == 14 else layout.visual_objects
	for d: Dictionary in objects:
		if not d.has("collision_size"): continue
		var center := _point(d.get("pos")) + _point(d.get("collision_offset", Vector2.ZERO))
		var extent := _point(d.get("collision_size"))
		shapes.append({"id": String(d.get("id", "unnamed_visual")), "kind": "source_visual_ground", "rect": Rect2(center - extent * .5, extent).grow(.004)})
	for d: Dictionary in layout.blockers:
		var extent := _point(d.get("size", Vector2.ZERO))
		var center := _point(d.get("pos", Vector2.ZERO))
		shapes.append({"id": String(d.get("id", "authored_blocker")), "kind": "source_authored_blocker", "rect": Rect2(center - extent * .5, extent).grow(maxf(0, float(d.get("walkability_margin", .014))))})
	var result := {"size": size, "mask": image, "tiles": tiles, "shapes": shapes, "regions": layout.walkable_regions, "invalid": invalid}
	raw_foot_oracles[key] = result
	return result

func _raw_foot_reason(scene: SceneScript, normalized: Vector2) -> Dictionary:
	var oracle := _raw_oracle(scene)
	if oracle.is_empty() or bool(oracle.get("invalid", false)) or not normalized.is_finite(): return {"kind": "invalid_source_scene_or_coordinate"}
	var size: Vector2 = oracle.size
	var image: Image = oracle.mask
	var logical_size := Vector2(image.get_size()) if image != null else size
	var samples: Array[Vector2] = [normalized]
	for index in 16:
		var angle := TAU * float(index) / 16.0
		samples.append(normalized + Vector2(cos(angle) * 10.0 / logical_size.x, sin(angle) * 6.0 / logical_size.y))
	var minimum := normalized
	var maximum := normalized
	for index in samples.size():
		var sample := samples[index]
		minimum = minimum.min(sample)
		maximum = maximum.max(sample)
		if sample.x < 0 or sample.y < 0 or sample.x >= 1 or sample.y >= 1: return {"kind": "canvas_boundary", "sample_index": index, "sample_px": sample * size}
		var color := Color.TRANSPARENT
		var has_mask: bool = image != null or not oracle.tiles.is_empty()
		if not oracle.tiles.is_empty():
			for tile: Dictionary in oracle.tiles:
				var rect: Rect2 = tile.rect
				var raw := tile.image as Image
				if raw == null or not rect.has_point(sample * size): continue
				var uv := (sample * size - rect.position) / rect.size
				color = raw.get_pixel(roundi(uv.x * (raw.get_width() - 1)), roundi(uv.y * (raw.get_height() - 1)))
				break
		elif image != null:
			color = image.get_pixel(roundi(sample.x * (image.get_width() - 1)), roundi(sample.y * (image.get_height() - 1)))
		if has_mask:
			if color.a < .5 or maxf(color.r, maxf(color.g, color.b)) < .5: return {"kind": "raw_walk_pixel", "sample_index": index, "sample_px": sample * size, "rgba": [color.r, color.g, color.b, color.a]}
		else:
			var inside := false
			for polygon: PackedVector2Array in oracle.regions:
				if Geometry2D.is_point_in_polygon(sample, polygon): inside = true
			if not inside: return {"kind": "source_walk_polygon", "sample_index": index, "sample_px": sample * size}
	for shape: Dictionary in oracle.shapes:
		var rect: Rect2 = shape.rect
		if rect.position.x > maximum.x or rect.position.y > maximum.y or rect.end.x < minimum.x or rect.end.y < minimum.y: continue
		for index in samples.size():
			if rect.has_point(samples[index]): return {"kind": shape.kind, "object_id": shape.id, "sample_index": index, "sample_px": samples[index] * size, "grown_rect_normalized": [rect.position.x, rect.position.y, rect.size.x, rect.size.y]}
	return {}

func _dense_polyline(points: Array) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for segment in range(points.size() - 1):
		var a := _point(points[segment])
		var b := _point(points[segment + 1])
		var steps := maxi(1, int(ceil(a.distance_to(b) / 4.0)))
		for step in range(steps):
			result.append(a.lerp(b, float(step) / steps))
	if not points.is_empty():
		result.append(_point(points.back()))
	return result

func _key(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame
	event = InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame

func _pointer(point: Vector2) -> void:
	# parse_input_event consumes WINDOW pixels, whereas marker/UI rects above
	# are logical viewport pixels. The final transform includes both scale and
	# letterbox translation (headless64x64 currently has a real14px Y inset).
	# Never hard-code that window size/scale; GPU uses its own live transform.
	var physical := root.get_final_transform() * point
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = physical
		event.global_position = physical
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame

func _release_movement() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(action)

func _drive_to(target: Vector2) -> bool:
	# Exercise the formal Player physics and collisions. Never teleport mid-route.
	if not is_instance_valid(field):
		return false
	var player: Node2D = field.get("_player")
	if not is_instance_valid(player):
		return false
	var tick_budget := maxi(60, int(ceil(player.position.distance_to(target) / 2.0)) + 100)
	var every_foot_clear := true
	for tick in range(tick_budget):
		if not is_instance_valid(player) or not is_instance_valid(field):
			_release_movement()
			return false
		var delta := target - player.position
		if delta.length() <= .15:
			break
		_release_movement()
		var direction := delta.normalized()
		var deadzone := 0.0
		for action in ["move_right", "move_left", "move_down", "move_up"]: deadzone += InputMap.action_get_deadzone(action) * .25
		var strength := deadzone + (1.0 - deadzone) * minf(1.0, delta.length() / (480.0 / Engine.physics_ticks_per_second))
		Input.action_press("move_right", maxf(direction.x, 0.0) * strength)
		Input.action_press("move_left", maxf(-direction.x, 0.0) * strength)
		Input.action_press("move_down", maxf(direction.y, 0.0) * strength)
		Input.action_press("move_up", maxf(-direction.y, 0.0) * strength)
		await physics_frame
		every_foot_clear = every_foot_clear and _foot_clear(player.position)
	_release_movement()
	await physics_frame
	return is_instance_valid(player) and player.position.distance_to(target) <= .3 and every_foot_clear

func _actual_actor_alpha_intersection(part: Sprite2D, source_alpha_threshold: float = .12) -> int:
	var player: Node = field.get("_player")
	var actor: Sprite2D = player.get("sprite")
	if actor == null or actor.texture == null or part == null or part.texture == null:
		return 0
	var source := actor.texture.get_image()
	var target := part.texture.get_image()
	if source.is_compressed(): source.decompress()
	if target.is_compressed(): target.decompress()
	var frame := _sprite_frame(actor, source)
	var cell := frame.size
	var frame_origin := frame.position
	var rect := actor.get_rect()
	var part_rect := part.get_rect()
	var intersections := 0
	for y in range(cell.y):
		for x in range(cell.x):
			if source.get_pixelv(frame_origin + Vector2i(x, y)).a <= source_alpha_threshold:
				continue
			var source_uv := Vector2((float(x) + .5) / cell.x, (float(y) + .5) / cell.y)
			if actor.flip_h: source_uv.x = 1.0 - source_uv.x
			if actor.flip_v: source_uv.y = 1.0 - source_uv.y
			var local := rect.position + source_uv * rect.size
			var part_local := part.to_local(actor.to_global(local))
			if not part_rect.has_point(part_local):
				continue
			var uv := (part_local - part_rect.position) / part_rect.size
			if _prop_sample_alpha(part, target, uv) > source_alpha_threshold:
				intersections += 1
	return intersections

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	if is_instance_valid(field) and current_scene == field:
		var player: Node2D = field.get("_player")
		_check(_foot_clear(player.position), "screenshot stand point has full foot: " + label)
		field.call("_snap_camera_to_player")
	else:
		_check(is_instance_valid(current_scene),"real non-Field UI/result exists for screenshot: "+label)
	for frame in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(image != null and image.get_size() == Vector2i(1920, 1080), "physical 1920x1080 screenshot: " + label)
	if image != null:
		_check(image.save_png(phase_output + label + ".png") == OK, "screenshot saved: " + label)
		captures += 1

func _run() -> void:
	candidate_stage = "--candidate-before-cutover" in OS.get_cmdline_user_args()
	active_id = CANDIDATE_ID if candidate_stage else WORLD_ID
	active_path = CANDIDATE_PATH if candidate_stage else WORLD_PATH
	phase_output = OUTPUT_DIR + ("candidate_" if candidate_stage else "canonical_") + ("headless_" if DisplayServer.get_name() == "headless" else "gpu_") + str(int(Time.get_unix_time_from_system())) + "/"
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output)) == OK, "new isolated QA log/screenshot output directory")
	player_saves_before = _actual_player_saves()
	prior_navigation = root.get_node("SceneRouter").get_navigation_state().duplicate(true)
	manifest = _json(MANIFEST_PATH)
	source_contract = _json(SOURCE_PATH)
	var status := String(manifest.get("status", ""))
	var ready := status in ["ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA", "PRODUCTION_APPROVED"] and String(source_contract.get("status", "")) == "ART_ASSETS_READY" and ResourceLoader.exists(active_path)
	var shader_gate: Array = manifest.get("native_shader_compiler_gate", [])
	ready = ready and shader_gate.size() == 4
	for compiler: Dictionary in shader_gate:
		ready = ready and bool(compiler.get("compiled", false)) and not compiler.get("required", []).is_empty()
		for uniform: String in compiler.get("required", []):
			ready = ready and uniform in compiler.get("actual_uniforms", [])
	if not candidate_stage:
		var approval := _json("res://data/maps/world_map_v14_acceptance.json")
		ready = ready and status == "PRODUCTION_APPROVED" and bool(manifest.get("production_approved", false)) and bool(manifest.get("visual_approved", false)) and bool(approval.get("technical_approved", false)) and bool(approval.get("visual_approved", false))
	_check(ready, "final completed art plus published production scene required before Field; current=" + status)
	if not ready:
		print("[WorldV14Production] PRECONDITION REFUSED; unfinished assets not loaded into Field or GPU")
		_finish()
		return
	if DisplayServer.get_name() != "headless":
		_check("--qa-gpu-approved" in OS.get_cmdline_user_args(), "GPU requires separate serialized producer approval")
		if failed > 0:
			_finish()
			return
	_frozen_checks()
	if not _asset_binding_checks():
		_finish()
		return
	schema_ready = true
	print("[WorldV14Phase] raw pixels/crops, actual native geometry/body/shadow verification")
	_terrain_capture_geometry_checks()
	_structure_saved_mesh_checks()
	_raw_pixel_and_crop_checks()
	_native_export_and_ground_shadow_checks()
	_prepare_isolated_slots()
	_fixture_new_game()
	if not await _open_world(world.player_spawn):
		_finish()
		return
	_collect_runtime()
	print("[WorldV14Phase] actual Field opened; isolated saves then 9 regions/12 borders/structures/16 portals")
	_check(not bool(root.get_node("DialogPlayer").call("is_playing")), "fresh early-game fixture can explore without late plot prerequisites")
	await _save_version_checks()
	await _world_routes_and_region_views()
	await _structure_and_negative_checks()
	await _front_wall_semantic_checks()
	await _portal_runtime_tour()
	await _overview_check()
	await _independent_prop_runtime_checks()
	await _ghost_negative_and_performance()
	await _story_boundary_checks()
	await _battle_and_modal_return_checks()
	await _battle_defeat_and_flee_checks()
	_frozen_checks()
	_finish()

func _finish() -> void:
	_release_movement()
	_check(player_saves_before == _actual_player_saves(), "normal player slots unchanged")
	var report := {"scope": qa_scope, "stage": "candidate-before-cutover" if candidate_stage else "fresh-canonical", "renderer": DisplayServer.get_name(),
		"checks": checks, "failures": failed, "screenshots": captures, "full_foot_centers": full_foot_samples,
		"actual_portal_input_count": portal_input_count, "actual_open_seam_input_count": seam_input_count,
		"raw_added_support_pixels": raw_added_support_pixels, "blocked_natural_water_pixels": terrain_rejected_water,
		"output_dir": phase_output, "player_saves_unchanged": player_saves_before == _actual_player_saves(),
		"visual_verdict": "REQUIRES_INDEPENDENT_IMAGE_REVIEW; no automatic visual PASS", "schema_ready": schema_ready, "performance_samples": performance_samples}
	var report_file := FileAccess.open(phase_output + "result.json", FileAccess.WRITE)
	if report_file != null:
		report_file.store_string(JSON.stringify(report, "\t"))
		report_file.close()
	print("[WorldV14Production] stage=%s checks=%d failures=%d captures=%d fullfoot_centers=%d portals_input=%d seams_input=%d output=%s" % [report.stage, checks, failed, captures, full_foot_samples, portal_input_count, seam_input_count, phase_output])
	# Normal user slots are untouched. Keep QA-created JSON/history in its unique
	# subdirectory for reproducibility, rather than broad user-directory cleanup.
	quit(1 if failed > 0 else 0)
