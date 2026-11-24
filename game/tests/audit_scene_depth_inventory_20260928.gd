extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var directory := DirAccess.open("res://data/scenes")
	if directory == null:
		push_error("Cannot enumerate scene resources")
		quit(1)
		return
	var scene_files := Array(directory.get_files())
	scene_files.sort()
	var scene_count := 0
	var walkable_count := 0
	var no_depth_count := 0
	var total_blockers := 0
	var total_occluders := 0
	var two_sided_unpaired := 0
	var field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	for file_name: String in scene_files:
		if not file_name.ends_with(".tres"):
			continue
		var resource := load("res://data/scenes/%s" % file_name)
		if not resource is SceneScript:
			continue
		var scene := resource as SceneScript
		scene_count += 1
		if scene.map_layout == null:
			continue
		walkable_count += 1
		var layout := scene.map_layout
		var blocker_count := layout.blockers.size()
		var occluder_count := layout.occluders.size()
		var object_count := layout.visual_objects.size()
		total_blockers += blocker_count
		total_occluders += occluder_count
		field.set("_current_scene", scene)
		field.call("_load_walkable_mask", layout.walkable_mask_path)
		field.call("_rebuild_walkability_collision_entries", layout.blockers, layout.visual_objects)
		for raw_blocker: Variant in layout.blockers:
			if not raw_blocker is Dictionary:
				continue
			var blocker: Dictionary = raw_blocker as Dictionary
			var blocker_id := String(blocker.get("id", ""))
			var has_foreground := false
			for raw_cover: Variant in layout.occluders:
				if not raw_cover is Dictionary:
					continue
				var cover: Dictionary = raw_cover as Dictionary
				var cover_polygon: PackedVector2Array = cover.get("cover_polygon", PackedVector2Array())
				var blocker_center: Vector2 = blocker.get("pos", Vector2.ZERO)
				if String(cover.get("id", "")) == blocker_id or String(cover.get("blocker_id", "")) == blocker_id or (cover_polygon.size() >= 3 and Geometry2D.is_point_in_polygon(blocker_center, cover_polygon)):
					has_foreground = true
					break
			if has_foreground:
				continue
			var position: Vector2 = blocker.get("pos", Vector2.ZERO)
			var size: Vector2 = blocker.get("size", Vector2.ZERO)
			var north_foot := position - Vector2(0.0, size.y * 0.5 + 0.030)
			var south_foot := position + Vector2(0.0, size.y * 0.5 + 0.030)
			if north_foot.y <= 0.0 or south_foot.y >= 1.0:
				continue
			if field.call("_is_normalized_spawn_walkable", scene, north_foot) and field.call("_is_normalized_spawn_walkable", scene, south_foot):
				two_sided_unpaired += 1
				print("TWO_SIDED_UNPAIRED\t%s\t%s\t%s\t%s" % [scene.scene_id, blocker_id, north_foot, south_foot])
		if occluder_count == 0 and layout.actor_fade_zones.is_empty():
			no_depth_count += 1
		print("AUDIT\t%s\t%s\t%s\t%d\t%d\t%d\t%d\t%d\t%d" % [
			scene.scene_id,
			scene.background_path,
			layout.walkable_mask_path,
			blocker_count,
			occluder_count,
			layout.actor_fade_zones.size(),
			object_count,
			layout.walkable_probes.size(),
			layout.blocked_probes.size(),
		])
	print("SUMMARY\tscenes=%d\twalkable=%d\tno_depth=%d\tblockers=%d\toccluders=%d\ttwo_sided_unpaired=%d" % [scene_count, walkable_count, no_depth_count, total_blockers, total_occluders, two_sided_unpaired])
	field.free()
	quit()
