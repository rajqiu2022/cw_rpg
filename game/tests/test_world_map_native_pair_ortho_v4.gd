extends SceneTree

# The ortho candidate uses a single fixed camera for picture, land, and walk.
# This is an isolated lab contract, never a shipping-map promotion check.
const SIZE := Vector2i(3072, 1024)
const HALF_WIDTH := 1536
const PREFIX := "res://build/world_native_pair_ortho_v4_"


func _prefix() -> String:
	return PREFIX


func _extra_checks(_walk: Image, _land: Image, _errors: Array[String]) -> void:
	pass


func _read_png(suffix: String) -> Image:
	var path := _prefix() + suffix + ".png"
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	return image if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK else null


func _initialize() -> void:
	var visual := _read_png("visual")
	var center := _read_png("center")
	var coast := _read_png("coast")
	var walk := _read_png("walk")
	var land := _read_png("land")
	var center_walk := _read_png("center_walk")
	var coast_walk := _read_png("coast_walk")
	var center_land := _read_png("center_land")
	var coast_land := _read_png("coast_land")
	var errors: Array[String] = []
	if visual == null or center == null or coast == null or walk == null or land == null or center_walk == null or coast_walk == null or center_land == null or coast_land == null:
		push_error("Render the v4 picture, land and walk outputs first")
		quit(1)
		return
	if visual.get_size() != SIZE or walk.get_size() != SIZE or land.get_size() != SIZE:
		errors.append("Full projected outputs are not 3072x1024")
	if center.get_size() != Vector2i(HALF_WIDTH, SIZE.y) or coast.get_size() != Vector2i(HALF_WIDTH, SIZE.y) or center_walk.get_size() != Vector2i(HALF_WIDTH, SIZE.y) or coast_walk.get_size() != Vector2i(HALF_WIDTH, SIZE.y) or center_land.get_size() != Vector2i(HALF_WIDTH, SIZE.y) or coast_land.get_size() != Vector2i(HALF_WIDTH, SIZE.y):
		errors.append("Projected region crops are not 1536x1024")
	if not errors.is_empty():
		for error in errors:
			push_error(error)
		quit(1)
		return
	for y in range(0, SIZE.y, 7):
		for offset in range(0, HALF_WIDTH, 71):
			if visual.get_pixel(offset, y) != center.get_pixel(offset, y):
				errors.append("Center crop differs from the projected full frame")
				break
			if visual.get_pixel(HALF_WIDTH + offset, y) != coast.get_pixel(offset, y):
				errors.append("Coast crop differs from the projected full frame")
				break
			if walk.get_pixel(offset, y) != center_walk.get_pixel(offset, y) or land.get_pixel(offset, y) != center_land.get_pixel(offset, y):
				errors.append("Center navigation or land crop differs from the full projection")
				break
			if walk.get_pixel(HALF_WIDTH + offset, y) != coast_walk.get_pixel(offset, y) or land.get_pixel(HALF_WIDTH + offset, y) != coast_land.get_pixel(offset, y):
				errors.append("Coast navigation or land crop differs from the full projection")
				break
	for y in range(0, SIZE.y, 4):
		for x in range(0, SIZE.x, 4):
			if walk.get_pixel(x, y).r > 0.5 and land.get_pixel(x, y).r < 0.5:
				errors.append("Walkable mask extends beyond the same-camera land silhouette at %d,%d" % [x, y])
				break
	for y in [100, 250, 512, 750, 900]:
		var last_walk := -1
		var last_land := -1
		for x in range(SIZE.x):
			if walk.get_pixel(x, y).r > 0.5:
				last_walk = x
			if land.get_pixel(x, y).r > 0.5:
				last_land = x
		if last_walk < 0 or last_land - last_walk < 40:
			errors.append("Coast safety buffer is missing at row %d" % y)
	for x in [HALF_WIDTH - 1, HALF_WIDTH, HALF_WIDTH + 1]:
		if walk.get_pixel(x, 347).r < 0.9:
			errors.append("Seam route is not traversable at x=%d" % x)
	if walk.get_pixel(3000, 512).r > 0.1 or walk.get_pixel(2600, 512).r > 0.1:
		errors.append("Open water or coastal buffer is traversable")
	_extra_checks(walk, land, errors)
	if errors.is_empty():
		print("[WorldNativePairOrtho] PASS: same-camera crops, seam route, coast buffer, walk subset of land; ", _prefix())
		quit(0)
	else:
		for error in errors:
			push_error(error)
		quit(1)
