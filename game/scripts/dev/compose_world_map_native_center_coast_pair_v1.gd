extends SceneTree

# Read-only source comparison. The output is a QA contact sheet, not a runtime map.
const CENTER := "res://art/backgrounds/world_map_v13_proto/bg_world_map_native_center_cleanplate_gen_v1_candidate.png"
const COAST := "res://art/backgrounds/world_map_v13_proto/bg_world_map_native_coast_cleanplate_gen_v2_candidate.png"
const OUTPUT_RAW := "res://build/world_map_v13_native_center_coast_pair_raw_v1.png"
const OUTPUT_FEATHERED := "res://build/world_map_v13_native_center_coast_pair_feathered_v1.png"
const OUTPUT_OVERLAP := "res://build/world_map_v13_native_center_coast_pair_overlap_v1.png"
const OUTPUT_SEAM_TARGET := "res://build/world_map_v13_native_center_coast_seam_target_v1.png"
const TILE_SIZE := Vector2i(1536, 1024)
const WARP_START_X := 1120
const ROAD_EXIT_SHIFT_Y := 48.0
const FEATHER_HALF_WIDTH := 80
const OVERLAP_WIDTH := 160
const OVERLAP_ROAD_SHIFT_Y := 120.0


func _initialize() -> void:
	call_deferred("_compose")


func _compose() -> void:
	var left := Image.load_from_file(ProjectSettings.globalize_path(CENTER))
	var right := Image.load_from_file(ProjectSettings.globalize_path(COAST))
	if left == null or right == null or left.get_size() != TILE_SIZE or right.get_size() != TILE_SIZE:
		push_error("Center/coast source image missing or wrong size")
		quit(1)
		return
	left.convert(Image.FORMAT_RGBA8)
	right.convert(Image.FORMAT_RGBA8)
	var raw_pair := Image.create(TILE_SIZE.x * 2, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	raw_pair.blit_rect(left, Rect2i(Vector2i.ZERO, TILE_SIZE), Vector2i.ZERO)
	raw_pair.blit_rect(right, Rect2i(Vector2i.ZERO, TILE_SIZE), Vector2i(TILE_SIZE.x, 0))
	if raw_pair.save_png(OUTPUT_RAW) != OK:
		push_error("Could not write raw center/coast contact sheet")
		quit(1)
		return
	var seam_target := Image.create(1024, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	seam_target.blit_rect(raw_pair, Rect2i(1024, 0, 1024, TILE_SIZE.y), Vector2i.ZERO)
	if seam_target.save_png(OUTPUT_SEAM_TARGET) != OK:
		push_error("Could not write seam edit target")
		quit(1)
		return
	var pair := Image.create(TILE_SIZE.x * 2, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	for x in TILE_SIZE.x:
		for y in TILE_SIZE.y:
			pair.set_pixel(x, y, _warped_left_pixel(left, x, y))
	pair.blit_rect(right, Rect2i(Vector2i.ZERO, TILE_SIZE), Vector2i(TILE_SIZE.x, 0))
	for offset in range(-FEATHER_HALF_WIDTH, FEATHER_HALF_WIDTH):
		var pair_x := TILE_SIZE.x + offset
		var right_weight := float(offset + FEATHER_HALF_WIDTH) / float(FEATHER_HALF_WIDTH * 2)
		for y in TILE_SIZE.y:
			var left_color: Color = _warped_left_pixel(left, mini(pair_x, TILE_SIZE.x - 1), y)
			var right_color: Color = right.get_pixel(maxi(0, offset), y)
			pair.set_pixel(pair_x, y, left_color.lerp(right_color, right_weight))
	if pair.save_png(OUTPUT_FEATHERED) != OK:
		push_error("Could not write feathered center/coast contact sheet")
		quit(1)
		return
	var overlap_pair := Image.create(TILE_SIZE.x * 2 - OVERLAP_WIDTH, TILE_SIZE.y, false, Image.FORMAT_RGBA8)
	var overlap_start := TILE_SIZE.x - OVERLAP_WIDTH
	for output_x in overlap_pair.get_width():
		for y in TILE_SIZE.y:
			if output_x < overlap_start:
				overlap_pair.set_pixel(output_x, y, left.get_pixel(output_x, y))
			elif output_x >= TILE_SIZE.x:
				overlap_pair.set_pixel(output_x, y, right.get_pixel(output_x - overlap_start, y))
			else:
				var blend_t := float(output_x - overlap_start) / float(OVERLAP_WIDTH)
				var curved_t := blend_t * blend_t * (3.0 - 2.0 * blend_t)
				var warped_y := clampi(roundi(float(y) - curved_t * OVERLAP_ROAD_SHIFT_Y), 0, TILE_SIZE.y - 1)
				var left_color := left.get_pixel(output_x, warped_y)
				var right_color := right.get_pixel(output_x - overlap_start, y)
				overlap_pair.set_pixel(output_x, y, left_color.lerp(right_color, blend_t))
	if overlap_pair.save_png(OUTPUT_OVERLAP) != OK:
		push_error("Could not write overlapping center/coast contact sheet")
		quit(1)
		return
	print("[WorldCenterCoastPair] raw=", OUTPUT_RAW, " feathered=", OUTPUT_FEATHERED, " overlap=", OUTPUT_OVERLAP)
	quit(0)


func _warped_left_pixel(left: Image, x: int, y: int) -> Color:
	var sample_x := clampi(x, 0, TILE_SIZE.x - 1)
	var warp_t := clampf(float(sample_x - WARP_START_X) / float(TILE_SIZE.x - 1 - WARP_START_X), 0.0, 1.0)
	var smooth_t := warp_t * warp_t * (3.0 - 2.0 * warp_t)
	var sample_y := clampi(roundi(float(y) - smooth_t * ROAD_EXIT_SHIFT_Y), 0, TILE_SIZE.y - 1)
	return left.get_pixel(sample_x, sample_y)
