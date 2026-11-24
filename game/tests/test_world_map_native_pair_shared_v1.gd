extends SceneTree

# Isolated contract for the two-region sample, not the shipping world map.
const SIZE := Vector2i(3072, 1024)
const HALF_WIDTH := 1536


func _prefix() -> String:
	return "res://build/world_native_pair_shared_v1_"


func _baseline_prefix() -> String:
	return ""


func _read_png(path: String) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	return image if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK else null


func _initialize() -> void:
	var visual := _read_png(_prefix() + "visual.png")
	var center := _read_png(_prefix() + "center.png")
	var coast := _read_png(_prefix() + "coast.png")
	var walk := _read_png(_prefix() + "walk.png")
	var topology := _read_png(_prefix() + "topology.png")
	var errors: Array[String] = []
	if visual == null or center == null or coast == null or walk == null or topology == null:
		push_error("Native pair images are missing; run the renderer first")
		quit(1)
		return
	if visual.get_size() != SIZE or walk.get_size() != SIZE or topology.get_size() != SIZE:
		errors.append("Full image dimensions differ from 3072x1024")
	if center.get_size() != Vector2i(HALF_WIDTH, SIZE.y) or coast.get_size() != Vector2i(HALF_WIDTH, SIZE.y):
		errors.append("Split image dimensions differ from 1536x1024")
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return
	for y in range(0, SIZE.y, 7):
		for offset in range(0, HALF_WIDTH, 71):
			if visual.get_pixel(offset, y) != center.get_pixel(offset, y):
				errors.append("Center crop is not pixel-identical to the full render")
				break
			if visual.get_pixel(HALF_WIDTH + offset, y) != coast.get_pixel(offset, y):
				errors.append("Coast crop is not pixel-identical to the full render")
				break
	var road_left := topology.get_pixel(HALF_WIDTH - 1, 347).g
	var road_right := topology.get_pixel(HALF_WIDTH, 347).g
	if road_left < 0.8 or road_right < 0.8 or absf(road_left - road_right) > 0.15:
		errors.append("Road coverage is missing or jumps at the center/coast seam")
	if walk.get_pixel(1400, 350).r < 0.9 or walk.get_pixel(1850, 415).r < 0.9:
		errors.append("The inland approach is not walkable")
	if walk.get_pixel(3000, 512).r > 0.1:
		errors.append("Open water is walkable")
	if walk.get_pixel(2600, 512).r > 0.1:
		errors.append("Coastal cliff buffer is walkable")
	if not _baseline_prefix().is_empty():
		for suffix in ["topology.png", "walk.png"]:
			if FileAccess.get_sha256(_prefix() + suffix) != FileAccess.get_sha256(_baseline_prefix() + suffix):
				errors.append("Visual variation changed the shared " + suffix)
	if errors.is_empty():
		print("[WorldNativePairShared] PASS: crops identical, road continuous, land walkable, coast and water blocked; prefix=", _prefix())
		quit(0)
	else:
		for error in errors:
			push_error(error)
		quit(1)
