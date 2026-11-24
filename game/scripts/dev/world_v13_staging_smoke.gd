extends SceneTree

const SCENE_PATH := "res://data/scenes/world_map_jianghu_v13_staging.tres"
const EXPECTED_PORTALS := 16


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var failures: Array[String] = []
	var scene := load(SCENE_PATH) as SceneScript
	if scene == null or scene.map_layout == null or scene.streamed_background == null:
		push_error("v13 staging scene/layout/streamer failed to load")
		quit(1)
		return
	var layout := scene.map_layout
	if layout.design_size != Vector2i(4608, 3072):
		failures.append("logical map is not 4608x3072")
	if layout.tiles.size() != 9 or layout.walkable_mask_tiles.size() != 9:
		failures.append("tile/terrain-mask count is not 9")
	if scene.streamed_background.get_chunks(false).size() != 9:
		failures.append("streamed tile count is not 9")
	if layout.portals.size() != EXPECTED_PORTALS:
		failures.append("portal count is not 16")
	var seen_paths: Dictionary = {}
	for tile: Dictionary in layout.tiles:
		var path := String(tile.get("terrain_path", ""))
		var nav_path := String(tile.get("navigation_path", ""))
		if not ResourceLoader.exists(path) or not ResourceLoader.exists(nav_path):
			failures.append("missing terrain/nav: %s" % String(tile.get("id", "")))
		if seen_paths.has(path):
			failures.append("duplicate terrain: %s" % path)
		seen_paths[path] = true
	var seen_ids: Dictionary = {}
	for portal: Dictionary in layout.portals:
		var portal_id := String(portal.get("id", ""))
		if seen_ids.has(portal_id):
			failures.append("duplicate portal: %s" % portal_id)
		seen_ids[portal_id] = true
		var pos: Vector2 = portal.get("pos", Vector2.ZERO)
		if not _mask_walkable(layout, pos):
			failures.append("portal on blocked ground: %s" % portal_id)
		if _blocked_by_footprint(layout, pos):
			failures.append("portal intersects landmark foot: %s" % portal_id)
		if not bool(portal.get("staging_pending_asset", false)):
			var matched := false
			for obj: Dictionary in layout.visual_objects:
				if String(obj.get("portal_id", "")) == portal_id:
					matched = true
					break
			if not matched:
				failures.append("active portal lacks landmark: %s" % portal_id)
	for probe: Dictionary in layout.walkable_probes:
		if not _mask_walkable(layout, probe.get("pos", Vector2.ZERO)):
			failures.append("positive probe blocked: %s" % String(probe.get("id", "")))
	for probe: Dictionary in layout.blocked_probes:
		var pos: Vector2 = probe.get("pos", Vector2.ZERO)
		if _mask_walkable(layout, pos) and not _blocked_by_footprint(layout, pos):
			failures.append("negative probe open: %s" % String(probe.get("id", "")))
	if failures.is_empty():
		print("V13_STAGING_SMOKE_OK tiles=9 portals=16")
		quit(0)
	else:
		for failure: String in failures:
			push_error("V13_STAGING_SMOKE: " + failure)
		quit(1)


func _mask_walkable(layout: WalkableMapLayout, pos: Vector2) -> bool:
	var point := pos * Vector2(layout.design_size)
	for tile: Dictionary in layout.walkable_mask_tiles:
		var rect: Rect2 = tile.get("logical_rect", Rect2())
		if not rect.has_point(point):
			continue
		var tex := load(String(tile.get("path", ""))) as Texture2D
		if tex == null:
			return false
		var img := tex.get_image()
		var local := (point - rect.position) / rect.size
		var x := clampi(int(round(local.x * float(img.get_width() - 1))), 0, img.get_width() - 1)
		var y := clampi(int(round(local.y * float(img.get_height() - 1))), 0, img.get_height() - 1)
		var c := img.get_pixel(x, y)
		return c.a >= 0.5 and maxf(c.r, maxf(c.g, c.b)) >= 0.5
	return false


func _blocked_by_footprint(layout: WalkableMapLayout, pos: Vector2) -> bool:
	for block: Dictionary in layout.blockers:
		var size: Vector2 = block.get("size", Vector2.ZERO)
		var center: Vector2 = block.get("pos", Vector2.ZERO)
		var margin := float(block.get("walkability_margin", 0.014))
		if Rect2(center - size * 0.5, size).grow(margin).has_point(pos):
			return true
	for obj: Dictionary in layout.visual_objects:
		if not obj.has("collision_size"):
			continue
		var size: Vector2 = obj.get("collision_size", Vector2.ZERO)
		var center: Vector2 = obj.get("pos", Vector2.ZERO) + obj.get("collision_offset", Vector2.ZERO)
		if Rect2(center - size * 0.5, size).grow(0.004).has_point(pos):
			return true
	return false
