extends SceneTree

## Read-only tile QA plus generated contact/seam crops. The output images are
## evidence, not runtime art, and do not modify any of the nine source tiles.

const TILE_DIR := "res://art/backgrounds/world_map_v13_tiles"
const OUTPUT_DIR := "res://screenshots/world_map_v13_staging_qa"
const TILE_SIZE := Vector2i(1536, 1024)

var _checks := 0
var _failures := 0
var _pending := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var staging := load("res://data/scenes/world_map_jianghu_v13_staging.tres") as SceneScript if ResourceLoader.exists("res://data/scenes/world_map_jianghu_v13_staging.tres") else null
	if staging == null or staging.streamed_background == null:
		print("[PENDING] staging streamed manifest is needed to select the nine active tile revisions")
		quit(0)
		return
	var active_paths: Dictionary = {}
	for raw in staging.streamed_background.get_chunks(true):
		var chunk: Dictionary = raw
		var rect: Rect2 = chunk.get("logical_rect", Rect2())
		var cell := Vector2i(int(rect.position.x / TILE_SIZE.x), int(rect.position.y / TILE_SIZE.y))
		_check(rect.size == Vector2(TILE_SIZE), "active tile keeps native logical rect: " + str(cell))
		_check(not active_paths.has(cell), "active tile cell unique: " + str(cell))
		active_paths[cell] = String(chunk.get("path", ""))
	_check(active_paths.size() == 9, "streamed manifest selects exactly nine active tiles")
	var tiles: Dictionary = {}
	var hashes: Dictionary = {}
	for row in range(3):
		for col in range(3):
			var path := String(active_paths.get(Vector2i(col, row), ""))
			if not path.begins_with(TILE_DIR + "/") or not FileAccess.file_exists(path):
				_pending += 1
				print("[PENDING] no imported active source for r%dc%d: %s" % [row, col, path])
				continue
			_check(path.get_file().begins_with("tile_%d%d_" % [row, col]), "active filename matches logical cell r%dc%d" % [row, col])
			var image := Image.load_from_file(path)
			_check(image != null and image.get_size() == TILE_SIZE, "native tile dimensions r%dc%d" % [row, col])
			if image == null or image.get_size() != TILE_SIZE:
				continue
			image.convert(Image.FORMAT_RGBA8)
			var digest := FileAccess.get_sha256(path)
			_check(not hashes.has(digest), "distinct source bitmap r%dc%d" % [row, col])
			hashes[digest] = path
			_check(image.get_pixel(0, 0).a > 0.95 and image.get_pixel(TILE_SIZE.x - 1, TILE_SIZE.y - 1).a > 0.95, "tile has opaque terrain at opposite corners r%dc%d" % [row, col])
			tiles[Vector2i(col, row)] = image
	_check(tiles.size() <= 9, "tile coordinate inventory has no overflow")
	if tiles.size() != 9:
		print("[WorldMapV13TileAudit] checks=%d failed=%d pending=%d; contact sheet waits for nine tiles" % [_checks, _failures, _pending])
		quit(1 if _failures else 0)
		return
	var combined := Image.create_empty(TILE_SIZE.x * 3, TILE_SIZE.y * 3, false, Image.FORMAT_RGBA8)
	for row in range(3):
		for col in range(3):
			var tile: Image = tiles[Vector2i(col, row)]
			combined.blit_rect(tile, Rect2i(Vector2i.ZERO, TILE_SIZE), Vector2i(col * TILE_SIZE.x, row * TILE_SIZE.y))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var contact_path := OUTPUT_DIR.path_join("terrain_3x3_contact_20260928.png")
	_check(combined.save_png(contact_path) == OK, "nine-tile contact image saves")
	print("[EVIDENCE] " + ProjectSettings.globalize_path(contact_path))
	_audit_and_capture_seams(combined)
	_pending += 1
	print("[PENDING] seam color/shape alignment still requires visual approval; alpha and unique hashes alone are insufficient")
	print("[WorldMapV13TileAudit] checks=%d failed=%d pending=%d" % [_checks, _failures, _pending])
	quit(1 if _failures else 0)


func _audit_and_capture_seams(combined: Image) -> void:
	for boundary_col in [1, 2]:
		for row in range(3):
			var x: int = boundary_col * TILE_SIZE.x
			var y0: int = row * TILE_SIZE.y
			var strip := combined.get_region(Rect2i(x - 128, y0, 256, TILE_SIZE.y))
			var path := OUTPUT_DIR.path_join("seam_vertical_c%d_r%d.png" % [boundary_col, row])
			_check(strip.save_png(path) == OK, "vertical seam crop saves c%d/r%d" % [boundary_col, row])
			var mean := _vertical_delta(combined, x, y0, y0 + TILE_SIZE.y)
			print("[SEAM_RGB] vertical c%d/r%d mean=%.4f crop=%s" % [boundary_col, row, mean, ProjectSettings.globalize_path(path)])
	for boundary_row in [1, 2]:
		for col in range(3):
			var y: int = boundary_row * TILE_SIZE.y
			var x0: int = col * TILE_SIZE.x
			var strip := combined.get_region(Rect2i(x0, y - 128, TILE_SIZE.x, 256))
			var path := OUTPUT_DIR.path_join("seam_horizontal_r%d_c%d.png" % [boundary_row, col])
			_check(strip.save_png(path) == OK, "horizontal seam crop saves r%d/c%d" % [boundary_row, col])
			var mean := _horizontal_delta(combined, y, x0, x0 + TILE_SIZE.x)
			var water_note := " WATER_NO_BRIDGE" if (boundary_row == 2 and col == 1) else ""
			print("[SEAM_RGB] horizontal r%d/c%d mean=%.4f%s crop=%s" % [boundary_row, col, mean, water_note, ProjectSettings.globalize_path(path)])


func _vertical_delta(image: Image, x: int, y0: int, y1: int) -> float:
	var sum := 0.0
	var count := 0
	var gaps := 0
	for y in range(y0, y1, 4):
		var a := image.get_pixel(x - 1, y)
		var b := image.get_pixel(x, y)
		if a.a <= 0.95 or b.a <= 0.95:
			gaps += 1
		sum += (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) / 3.0
		count += 1
	_check(gaps == 0, "vertical seam has no alpha gaps x=%d y=%d..%d (gaps=%d)" % [x, y0, y1, gaps])
	return sum / maxf(1.0, float(count))


func _horizontal_delta(image: Image, y: int, x0: int, x1: int) -> float:
	var sum := 0.0
	var count := 0
	var gaps := 0
	for x in range(x0, x1, 4):
		var a := image.get_pixel(x, y - 1)
		var b := image.get_pixel(x, y)
		if a.a <= 0.95 or b.a <= 0.95:
			gaps += 1
		sum += (absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b)) / 3.0
		count += 1
	_check(gaps == 0, "horizontal seam has no alpha gaps y=%d x=%d..%d (gaps=%d)" % [y, x0, x1, gaps])
	return sum / maxf(1.0, float(count))


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if not ok:
		_failures += 1
		push_error("[FAIL] " + message)
