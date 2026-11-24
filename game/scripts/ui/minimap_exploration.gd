extends RefCounted
## Local chart in normalized world coordinates. Fog stores remaining opacity.
const ZOOM := 4.5
const GRID := 384
const LEGACY_GRID := 120
const FOG := Color(0.025, 0.045, 0.055, 0.7)

var window := Rect2()
var texture: ImageTexture
var _key := ""
var _encoded := ""
var _legacy := ""
var _mask: Image
var _last := Vector2i(-1, -1)

func follow(id: String, uv: Vector2, world: Vector2, panel: Vector2) -> void:
	var fit := maxf(panel.x / world.x, panel.y / world.y)
	var span := panel / (fit * ZOOM) / world
	uv = uv.clamp(Vector2.ZERO, Vector2.ONE)
	window = Rect2((uv - span * 0.5).clamp(Vector2.ZERO, Vector2.ONE - span), span)
	var key := "minimap_trail_v2/" + id
	var saved := str(GameState.flags.get(key, ""))
	var legacy := str(GameState.flags.get("minimap_trail_v1/" + id, "")) if saved.is_empty() else ""
	if key != _key or saved != _encoded or legacy != _legacy:
		_key = key
		_encoded = saved
		_legacy = legacy
		_restore()
	var cell := Vector2i(uv * GRID).clampi(0, GRID - 1)
	if cell == _last:
		return
	_last = cell
	# Keep the former world-space reveal distance independent of the HUD zoom.
	var radius := panel.x / fit * 0.05
	var reach := Vector2i((Vector2.ONE * radius / world * GRID).ceil())
	var changed := false
	for y in range(maxi(0, cell.y - reach.y), mini(GRID, cell.y + reach.y + 1)):
		for x in range(maxi(0, cell.x - reach.x), mini(GRID, cell.x + reach.x + 1)):
			var distance := (((Vector2(x, y) + Vector2(0.5, 0.5)) / GRID - uv) * world).length()
			var opacity := roundf(smoothstep(radius * 0.87, radius, distance) * 255.0) / 255.0
			if opacity < _mask.get_pixel(x, y).a - 0.001:
				_mask.set_pixel(x, y, Color(1, 1, 1, opacity))
				changed = true
	if changed or _encoded.is_empty():
		texture.update(_mask)
		_encoded = Marshalls.raw_to_base64(_mask.get_data().compress(FileAccess.COMPRESSION_DEFLATE))
		GameState.flags[_key] = _encoded
		_legacy = ""

func _restore() -> void:
	_last = Vector2i(-1, -1)
	if not _encoded.is_empty():
		var raw := Marshalls.base64_to_raw(_encoded).decompress(GRID * GRID * 2, FileAccess.COMPRESSION_DEFLATE)
		if raw.size() == GRID * GRID * 2:
			_mask = Image.create_from_data(GRID, GRID, false, Image.FORMAT_LA8, raw)
			texture = ImageTexture.create_from_image(_mask)
			return
	_mask = Image.create(GRID, GRID, false, Image.FORMAT_LA8)
	_mask.fill(Color.WHITE)
	if not _legacy.is_empty():
		var bits := Marshalls.base64_to_raw(_legacy)
		if bits.size() == LEGACY_GRID * LEGACY_GRID / 8:
			var old := Image.create(LEGACY_GRID, LEGACY_GRID, false, Image.FORMAT_LA8)
			old.fill(Color.WHITE)
			for i in LEGACY_GRID * LEGACY_GRID:
				if bits[i >> 3] & (1 << (i % 8)):
					old.set_pixel(i % LEGACY_GRID, i / LEGACY_GRID, Color(1, 1, 1, 0))
			# The old flags describe whole coarse cells. Reconstruct their contour
			# before enlarging so old routes do not acquire square corners.
			old = _blur_legacy(_blur_legacy(old, Vector2i.RIGHT), Vector2i.DOWN)
			for i in LEGACY_GRID * LEGACY_GRID:
				if bits[i >> 3] & (1 << (i % 8)):
					var point := Vector2i(i % LEGACY_GRID, i / LEGACY_GRID)
					var opacity := minf(old.get_pixelv(point).a, 0.38)
					old.set_pixelv(point, Color(1, 1, 1, opacity))
			old.resize(GRID, GRID, Image.INTERPOLATE_CUBIC)
			_mask = old
	texture = ImageTexture.create_from_image(_mask)

func _blur_legacy(source: Image, axis: Vector2i) -> Image:
	var output := Image.create(LEGACY_GRID, LEGACY_GRID, false, Image.FORMAT_LA8)
	const WEIGHTS := [1, 4, 6, 4, 1]
	for y in LEGACY_GRID:
		for x in LEGACY_GRID:
			var point := Vector2i(x, y)
			var opacity := 0.0
			for tap in 5:
				var neighbor := (point + axis * (tap - 2)).clampi(0, LEGACY_GRID - 1)
				opacity += source.get_pixelv(neighbor).a * float(WEIGHTS[tap])
			output.set_pixelv(point, Color(1, 1, 1, opacity / 16.0))
	return output

func project(uv: Vector2, panel: Rect2) -> Vector2:
	return panel.position + (uv - window.position) / window.size * panel.size

func draw_layer(canvas: CanvasItem, source: Texture2D, panel: Rect2) -> void:
	if source != null and window.has_area():
		canvas.draw_texture_rect_region(source, panel, Rect2(window.position * source.get_size(), window.size * source.get_size()), FOG if source == texture else Color.WHITE)

func is_explored(uv: Vector2) -> bool:
	var cell := Vector2i(uv * GRID).clampi(0, GRID - 1)
	return _mask != null and _mask.get_pixelv(cell).a < 0.5
