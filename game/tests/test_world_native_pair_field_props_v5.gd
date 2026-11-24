extends "res://tests/test_world_native_pair_field_props_v1.gd"


func _prop_contract() -> GDScript:
	return preload("res://scripts/dev/world_native_pair_prop_contract_v5.gd")


func _ground_path() -> String:
	return "res://build/world_native_pair_ortho_v5_visual.png"


func _walk_path() -> String:
	return "res://build/world_native_pair_ortho_v5_walk.png"


func _output_prefix() -> String:
	return "res://build/world_native_pair_field_props_v5_"


func _road_points() -> Array[Vector2]:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_route_path()))
	var points: Array[Vector2] = []
	if data is Dictionary and data.get("road_feet") is Array:
		for entry in data["road_feet"]:
			points.append(Vector2(entry[0], entry[1]))
	return points


func _route_path() -> String:
	return "res://build/world_native_pair_ortho_v5_route.json"


func _runtime_checks(field: Node, _player: Player) -> void:
	var points := _road_points()
	_check(points.size() >= 90, "projected road feet exist for runtime checks")
	var probes := 0
	for index in range(1, points.size()):
		var start := points[index - 1]
		var finish := points[index]
		var steps := ceili(start.distance_to(finish) / 4.0)
		for step in range(steps + 1):
			var foot := start.lerp(finish, float(step) / steps)
			_check(bool(field.call("_is_inside_walkable_screen", foot)), "actual Field road foot clears at %s" % foot)
			probes += 1
	for foot in [Vector2(530, 180), Vector2(2070, 180), Vector2(3000, 512), Vector2(2600, 512)]:
		_check(not bool(field.call("_is_inside_walkable_screen", foot)), "actual Field blocks slope or sea at %s" % foot)
	print("[WorldNativePairFieldPropsRoad] continuous road foot probes=%d; %s" % [probes, _output_prefix()])


func _screenshot_placements() -> Array[Dictionary]:
	var placements := super._screenshot_placements()
	var points := _road_points()
	if points.size() >= 90:
		placements.append({"name": "western_road", "foot": points[22]})
		placements.append({"name": "seam_road", "foot": points[63]})
		placements.append({"name": "eastern_road", "foot": points[90]})
	return placements
