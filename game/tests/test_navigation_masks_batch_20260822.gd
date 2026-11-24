extends SceneTree

var failures := 0


func _initialize() -> void:
	_check_mask("res://data/maps/ch1_s3_zhuwei_forest_layout_v2.tres", [Vector2(0.15,0.86), Vector2(0.56,0.46), Vector2(0.88,0.12)], [Vector2(0.02,0.20), Vector2(0.70,0.82)])
	_check_mask("res://data/maps/ch1_s4_zhuwei_beast_cave_layout_v3.tres", [Vector2(0.50,0.82), Vector2(0.205,0.265), Vector2(0.80,0.275)], [Vector2(0.50,0.46), Vector2(0.93,0.50)])
	_check_mask("res://data/maps/ch1_s4_cave_mine_gallery_layout_v1.tres", [Vector2(0.18,0.75), Vector2(0.245,0.285), Vector2(0.355,0.755), Vector2(0.735,0.650), Vector2(0.865,0.610), Vector2(0.89,0.205)], [Vector2(0.505,0.505), Vector2(0.80,0.90)])
	_check_mask("res://data/maps/ch1_s4_cave_waterway_layout_v1.tres", [Vector2(0.82,0.75), Vector2(0.18,0.50), Vector2(0.46,0.59), Vector2(0.12,0.205)], [Vector2(0.50,0.50), Vector2(0.50,0.02)])
	_check_mask("res://data/maps/ch1_s4_cave_deep_den_layout_v1.tres", [Vector2(0.25,0.72), Vector2(0.50,0.455), Vector2(0.75,0.72)], [Vector2(0.02,0.50), Vector2(0.95,0.30)])
	_check_mask("res://data/maps/ch2_s1_zhuwei_market_layout_v2.tres", [Vector2(0.50,0.72), Vector2(0.24,0.36), Vector2(0.72,0.28), Vector2(0.90,0.20), Vector2(0.56,0.86), Vector2(0.30,0.90)], [Vector2(0.02,0.20), Vector2(0.98,0.72)])
	_check_topology()
	print("[NavigationMaskBatch] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_mask(path: String, walkable: Array[Vector2], blocked: Array[Vector2]) -> void:
	var layout := load(path) as WalkableMapLayout
	_check(layout != null, "%s loads" % path)
	if layout == null:
		return
	_check(not layout.walkable_mask_path.is_empty(), "%s owns raster mask" % path)
	var texture := load(layout.walkable_mask_path) as Texture2D
	_check(texture != null, "%s mask loads" % path)
	if texture == null:
		return
	var image := texture.get_image()
	for point in walkable:
		_check(_sample(image, point), "%s walkable %s" % [path, point])
	for point in blocked:
		_check(not _sample(image, point) or _inside_blocker(layout, point), "%s blocked %s" % [path, point])


func _sample(image: Image, point: Vector2) -> bool:
	var x := clampi(int(round(point.x * float(image.get_width() - 1))), 0, image.get_width() - 1)
	var y := clampi(int(round(point.y * float(image.get_height() - 1))), 0, image.get_height() - 1)
	var color := image.get_pixel(x, y)
	return color.a >= 0.5 and maxf(color.r, maxf(color.g, color.b)) >= 0.5


func _inside_blocker(layout: WalkableMapLayout, point: Vector2) -> bool:
	for blocker in layout.blockers:
		var pos: Vector2 = blocker.get("pos", Vector2.ZERO)
		var size: Vector2 = blocker.get("size", Vector2.ZERO)
		if Rect2(pos - size * 0.5, size).grow(0.014).has_point(point):
			return true
	return false


func _check_topology() -> void:
	var village := load("res://data/maps/ch1_s2_qingfeng_layout_v2.tres") as WalkableMapLayout
	var market := load("res://data/maps/ch2_s1_zhuwei_market_layout_v2.tres") as WalkableMapLayout
	var ruin := load("res://data/maps/ch1_s3_ruin_inner_layout_v1.tres") as WalkableMapLayout
	_check(not _has_target(village.portals, "ch2_s1_zhuwei_market"), "village main street no longer jumps into market")
	_check(not _has_target(market.portals, "ch1_s2_qingfeng"), "market no longer exits to main street")
	_check(_has_target(market.portals, "ch1_s3_ruin_inner"), "market returns to ruin inner")
	_check(_has_target(ruin.portals, "ch2_s1_zhuwei_market"), "ruin inner enters market")
	_check(_has_target(market.portals, "ch2_s1_market_inn"), "market enters inn")
	_check(_has_target(market.portals, "ch2_s1_market_training_hall"), "market enters training hall")
	var return_portal := _portal(village.portals, "return_to_mountain_road")
	_check(return_portal.get("target_pos", Vector2.ZERO).distance_to(Vector2(0.82, 0.22)) < 0.001, "village southwest exit returns beside the Zhuwei-side mountain-road entrance")


func _has_target(portals: Array[Dictionary], target: String) -> bool:
	for portal in portals:
		if String(portal.get("target_scene", "")) == target:
			return true
	return false


func _portal(portals: Array[Dictionary], portal_id: String) -> Dictionary:
	for portal in portals:
		if String(portal.get("id", "")) == portal_id:
			return portal
	return {}


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
