extends "res://tests/test_world_map_native_pair_ortho_v4.gd"


func _prefix() -> String:
	return "res://build/world_native_pair_ortho_v5_"


func _extra_checks(walk: Image, _land: Image, errors: Array[String]) -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_prefix() + "route.json"))
	if not data is Dictionary or not data.has("road_feet"):
		errors.append("Projected road foot samples are missing")
		return
	if data["road_feet"].size() < 90:
		errors.append("Projected samples do not cover the center-to-coast approach")
	for entry in data["road_feet"]:
		var foot := Vector2i(roundi(entry[0]), roundi(entry[1]))
		for offset in [Vector2i.ZERO, Vector2i(0, 10), Vector2i(0, -10), Vector2i(10, 0), Vector2i(-10, 0)]:
			var pixel: Vector2i = foot + offset
			if walk.get_pixelv(pixel).r < 0.9:
				errors.append("Rendered road lacks foot clearance at %s" % pixel)
				break
	if data["height_west"] < 2.5 or data["height_east"] < 2.2:
		errors.append("Inland terrain is still flattened by the old saturated coast distance")
	for foot in [Vector2i(530, 180), Vector2i(2070, 180)]:
		if walk.get_pixelv(foot).r > 0.1:
			errors.append("Steep rocky shoulder remains walkable at %s" % foot)
