extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("[SceneDepthContract] " + label)


func _run() -> void:
	var directory := DirAccess.open("res://data/scenes")
	_check(directory != null, "scene resource directory opens")
	if directory == null:
		quit(1)
		return
	var scene_count := 0
	var walkable_count := 0
	var blockers_checked := 0
	var covers_checked := 0
	for file_name in directory.get_files():
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
		for raw_blocker in layout.blockers:
			if not raw_blocker is Dictionary:
				_check(false, "%s has a non-dictionary blocker" % scene.scene_id)
				continue
			var blocker: Dictionary = raw_blocker as Dictionary
			var pos: Vector2 = blocker.get("pos", Vector2(-1, -1))
			var size: Vector2 = blocker.get("size", Vector2(-1, -1))
			_check(pos.x >= 0.0 and pos.x <= 1.0 and pos.y >= 0.0 and pos.y <= 1.0 and size.x > 0.0 and size.y > 0.0, "%s blocker %s uses normalized positive geometry" % [scene.scene_id, blocker.get("id", "")])
			blockers_checked += 1
		for raw_object in layout.visual_objects:
			if not raw_object is Dictionary:
				_check(false, "%s has a non-dictionary visual object" % scene.scene_id)
				continue
			var object_data: Dictionary = raw_object as Dictionary
			if not bool(object_data.get("sort_by_feet", false)):
				continue
			var object_id := String(object_data.get("id", ""))
			_check(object_data.has("depth_sort_foot_y"), "%s depth prop %s has an authored foot line" % [scene.scene_id, object_id])
			_check(object_data.has("collision_size"), "%s depth prop %s has paired foot collision" % [scene.scene_id, object_id])
		var texture := load(scene.background_path) as Texture2D
		_check(texture != null, "%s runtime background loads" % scene.scene_id)
		if texture == null:
			continue
		for raw_cover in layout.occluders:
			if not raw_cover is Dictionary:
				_check(false, "%s has a non-dictionary foreground" % scene.scene_id)
				continue
			var data: Dictionary = raw_cover as Dictionary
			var cover := DynamicOccluder2D.new()
			root.add_child(cover)
			_check(cover.configure(data, texture, Vector2(layout.design_size)), "%s foreground %s configures" % [scene.scene_id, data.get("id", "")])
			cover.free()
			covers_checked += 1
	_check(scene_count >= 90 and walkable_count >= 89, "full scene inventory was covered")
	var qinghe := load("res://data/scenes/openworld_qinghe_town.tres") as SceneScript
	var qinghe_well := _find_by_blocker_id(qinghe.map_layout.occluders, "well")
	_check(not qinghe_well.is_empty(), "Qinghe well retains an authored foreground")
	if not qinghe_well.is_empty():
		var cover := DynamicOccluder2D.new()
		root.add_child(cover)
		var background := load(qinghe.background_path) as Texture2D
		_check(cover.configure(qinghe_well, background, Vector2(qinghe.map_layout.design_size)), "Qinghe well foreground configures")
		cover.update_player_position(Vector2(0.5, cover.depth_y - 0.03), true)
		_check(cover.visible, "Qinghe well hides actor behind")
		cover.update_player_position(Vector2(0.5, cover.depth_y + 0.03), true)
		_check(not cover.visible, "Qinghe well yields to actor in front")
		cover.free()
	var linxi := load("res://data/scenes/linxi_village_center.tres") as SceneScript
	var linxi_well := _find_by_id(linxi.map_layout.visual_objects, "village_well")
	_check(not linxi_well.is_empty(), "Linxi well is an independent visual object")
	if not linxi_well.is_empty():
		_check(bool(linxi_well.get("sort_by_feet", false)), "Linxi well sorts by actor foot Y")
		_check(linxi_well.has("collision_size"), "Linxi well has a paired foot blocker")
		_check(ResourceLoader.exists(String(linxi_well.get("texture", ""))), "Linxi well transparent prop exists")
		var well_foot_y := float(linxi_well.get("depth_sort_foot_y", 0.0))
		_check(well_foot_y > 0.0 and well_foot_y < 1.0, "Linxi well has a valid depth line")
		_check(0.390 < well_foot_y and 0.550 > well_foot_y, "Linxi well front/back capture feet straddle its depth line")
		var linxi_field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
		linxi_field.set("_current_scene", linxi)
		linxi_field.call("_rebuild_walkability_collision_entries", linxi.map_layout.blockers, linxi.map_layout.visual_objects)
		var collision_center: Vector2 = linxi_well.get("pos", Vector2.ZERO) + linxi_well.get("collision_offset", Vector2.ZERO)
		_check(not linxi_field.call("_is_normalized_spawn_walkable", linxi, collision_center), "Linxi well base blocks feet")
		linxi_field.free()
	_check(_find_by_blocker_id(linxi.map_layout.occluders, "village_well").is_empty(), "Linxi well no longer uses a baked foreground copy")
	var huashan := load("res://data/scenes/openworld_huashan_waterfall_terrace.tres") as SceneScript
	var field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	field.set("_current_scene", huashan)
	field.call("_load_walkable_mask", huashan.map_layout.walkable_mask_path)
	field.call("_rebuild_walkability_collision_entries", huashan.map_layout.blockers, huashan.map_layout.visual_objects)
	for bench_id in ["north_bench", "east_bench"]:
		var blocker := _find_by_id(huashan.map_layout.blockers, bench_id)
		var foreground := _find_by_blocker_id(huashan.map_layout.occluders, bench_id)
		_check(not blocker.is_empty() and not foreground.is_empty(), "%s has paired foot collision and depth art" % bench_id)
		if not blocker.is_empty():
			_check(not field.call("_is_normalized_spawn_walkable", huashan, blocker.pos), "%s foot is blocked" % bench_id)
	field.free()
	print("[SceneDepthContract] scenes=%d walkable=%d blockers=%d foregrounds=%d checks=%d failures=%d" % [scene_count, walkable_count, blockers_checked, covers_checked, checks, failures])
	quit(1 if failures > 0 else 0)


func _find_by_id(entries: Array, wanted: String) -> Dictionary:
	for entry in entries:
		if entry is Dictionary and String(entry.get("id", "")) == wanted:
			return entry
	return {}


func _find_by_blocker_id(entries: Array, wanted: String) -> Dictionary:
	for entry in entries:
		if entry is Dictionary and String(entry.get("blocker_id", "")) == wanted:
			return entry
	return {}
