extends SceneTree

# Pixel-derived navigation for the isolated generated clean plate. The rendered
# land/water seam is the source of truth; no independent hand-drawn sea polygon.
const SOURCE := "res://art/backgrounds/world_map_v13_proto/bg_world_map_native_coast_cleanplate_gen_v2_candidate.png"
const OUTPUT := "res://art/navigation_masks/world_map_v13_proto/native_coast_gen_v2_walk_candidate.png"
const OVERLAY := "res://build/native_coast_gen_v2_mask_overlay.png"
const SHORE_INSET := 130


func _initialize() -> void:
	call_deferred("_build")


func _looks_like_water(color: Color) -> bool:
	return color.b > 0.23 and color.b > color.r * 1.16 and color.b > color.g * 1.05 and color.r < 0.60


func _raw_boundary(image: Image, y: int) -> int:
	var width := image.get_width()
	var consecutive_land := 0
	for x in range(width - 1, -1, -1):
		var water_votes := 0
		for sample_x in range(maxi(0, x - 6), mini(width - 1, x + 6) + 1):
			if _looks_like_water(image.get_pixel(sample_x, y)):
				water_votes += 1
		if water_votes < 5:
			consecutive_land += 1
			if consecutive_land >= 7:
				return x + 7
		else:
			consecutive_land = 0
	return 0


func _build() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE))
	if image == null or image.is_empty():
		push_error("Generated native coast clean plate is missing")
		quit(1)
		return
	var width := image.get_width()
	var height := image.get_height()
	var raw := PackedInt32Array()
	raw.resize(height)
	for y in height:
		raw[y] = _raw_boundary(image, y)
	var walk := Image.create(width, height, false, Image.FORMAT_RGBA8)
	walk.fill(Color.WHITE)
	var overlay := image.duplicate()
	var boundaries := PackedInt32Array()
	boundaries.resize(height)
	for y in height:
		var smoothed := 0
		var count := 0
		for nearby_y in range(maxi(0, y - 12), mini(height - 1, y + 12) + 1):
			smoothed += raw[nearby_y]
			count += 1
		var visually_detected := roundi(float(smoothed) / float(count))
		var inset := 30 if visually_detected >= width - 8 else SHORE_INSET
		var boundary := clampi(visually_detected - inset, 0, width)
		boundaries[y] = boundary
		walk.fill_rect(Rect2i(boundary, y, width - boundary, 1), Color.BLACK)
		overlay.fill_rect(Rect2i(maxi(0, boundary - 2), y, 4, 1), Color(0.98, 0.1, 0.08, 1.0))
	var samples: Array[int] = [0, int(height / 4), int(height / 2), int(height * 3 / 4), height - 1]
	var sample_boundaries: Array[int] = []
	for y in samples:
		sample_boundaries.append(boundaries[y])
		if boundaries[y] < 300 or boundaries[y] > width - 10:
			push_error("Invalid shore boundary y=%d x=%d" % [y, boundaries[y]])
			quit(1)
			return
	var probes := [
		[Vector2i(280, 420), true],
		[Vector2i(700, 540), true],
		[Vector2i(700, 850), true],
		[Vector2i(1490, 500), false],
		[Vector2i(1350, 760), false],
		[Vector2i(1000, 925), false],
	]
	for probe in probes:
		var pixel: Vector2i = probe[0]
		var should_walk: bool = probe[1]
		if (walk.get_pixelv(pixel).r > 0.8) != should_walk:
			push_error("Generated image mask probe failed: %s expected walk=%s" % [pixel, should_walk])
			quit(1)
			return
	if walk.save_png(OUTPUT) != OK or overlay.save_png(OVERLAY) != OK:
		push_error("Could not save native coast mask/overlay")
		quit(1)
		return
	print("[NativeCoastGeneratedMask] size=", Vector2i(width, height), " shore x at rows=", sample_boundaries)
	quit(0)
