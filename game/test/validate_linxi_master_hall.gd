extends SceneTree

var _failed := 0


func _initialize() -> void:
	var scene := load("res://data/scenes/linxi_master_hall.tres") as SceneScript
	_check(scene != null, "master hall scene does not load")
	if scene == null:
		quit(1)
		return
	var layout := scene.map_layout
	_check(layout != null, "master hall has no map layout")
	if layout == null:
		quit(1)
		return
	_check(scene.background_path.ends_with("bg_linxi_master_hall_interior_v3_secret_door.png") and ResourceLoader.exists(scene.background_path), "master residence background with the concealed passage door is missing")
	_check(layout.resource_path.ends_with("linxi_master_hall_layout_v3.tres"), "master residence must use its rebuilt layout")
	_check(layout.design_size == Vector2i(1536, 1024), "master residence design size must match the production background")
	_check(scene.player_visual_scale >= 1.15, "master residence protagonist scale remains readable")
	_check(layout.blockers.size() >= 7, "rebuilt furniture footprints are fully authored")
	_check(_inside_walkable(scene.player_spawn, layout.walkable_regions), "player spawn is outside the floor")
	for probe in layout.walkable_probes:
		_check(_inside_walkable(probe.pos, layout.walkable_regions), "%s is outside the floor" % probe.id)
		_check(not _is_blocked(probe.pos, layout.blockers), "%s intersects furniture" % probe.id)
	for probe in layout.blocked_probes:
		_check(_is_blocked(probe.pos, layout.blockers), "%s is not blocked" % probe.id)
	for portal in layout.portals:
		_check(_inside_walkable(portal.pos, layout.walkable_regions), "%s portal is outside the floor" % portal.id)
		_check(not _is_blocked(portal.pos, layout.blockers), "%s portal intersects furniture" % portal.id)
	var archive_portal: Dictionary = {}
	for portal: Dictionary in layout.portals:
		if String(portal.get("id", "")) == "enter_underground_archive":
			archive_portal = portal
			break
	_check(String(archive_portal.get("require_flag", "")) == "ch6_archive_entry_found", "archive entrance must wait for the chapter-six clue")
	_check(bool(archive_portal.get("reveal_only_when_unlocked", false)), "archive entrance stays completely hidden before discovery")
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check(field_source.contains("narrative_locked and reveal_only_when_unlocked"), "portal runtime suppresses unrevealed story entrances")
	print("[MasterHall] failed=%d" % _failed)
	quit(1 if _failed > 0 else 0)


func _inside_walkable(point: Vector2, regions: Array[PackedVector2Array]) -> bool:
	for region in regions:
		if Geometry2D.is_point_in_polygon(point, region):
			return true
	return false


func _is_blocked(point: Vector2, blockers: Array) -> bool:
	for blocker in blockers:
		var size: Vector2 = blocker.get("size", Vector2.ZERO)
		var pos: Vector2 = blocker.get("pos", Vector2.ZERO)
		if Rect2(pos - size * 0.5, size).has_point(point):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed += 1
	push_error("[MasterHall] %s" % message)
