extends RefCounted
## Exact current-frame alpha, including region and mirrors. Scoped to new city.
## Retains at most eight decoded textures; no image/actor scale modification.
var _images: Dictionary = {}
var _lru: Array[int] = []

func hits(sprite: Sprite2D, viewport_point: Vector2) -> bool:
	if sprite == null or sprite.texture == null or not sprite.is_visible_in_tree(): return false
	var local: Vector2 = sprite.get_global_transform_with_canvas().affine_inverse() * viewport_point
	var rect: Rect2 = sprite.get_rect()
	if rect.size.x <= 0 or rect.size.y <= 0 or not rect.has_point(local): return false
	var texture_id: int = sprite.texture.get_instance_id()
	if not _images.has(texture_id):
		var actual: Image = sprite.texture.get_image()
		if actual == null or (actual.is_compressed() and actual.decompress() != OK): return false
		if _lru.size() >= 8: _images.erase(_lru.pop_front())
		_images[texture_id] = actual
	else: _lru.erase(texture_id)
	_lru.append(texture_id)
	var image: Image = _images[texture_id]
	var uv: Vector2 = (local - rect.position) / rect.size
	if sprite.flip_h: uv.x = 1.0 - uv.x
	if sprite.flip_v: uv.y = 1.0 - uv.y
	var source: Rect2 = sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO, Vector2(image.get_size()))
	var frame_size: Vector2 = source.size / Vector2(sprite.hframes, sprite.vframes)
	if frame_size.x <= 0 or frame_size.y <= 0: return false
	var origin: Vector2 = source.position + Vector2(sprite.frame % sprite.hframes, floori(float(sprite.frame) / float(sprite.hframes))) * frame_size
	var pixel := Vector2i(origin + Vector2(minf(floorf(uv.x * frame_size.x), frame_size.x - 1), minf(floorf(uv.y * frame_size.y), frame_size.y - 1)))
	return pixel.x >= 0 and pixel.y >= 0 and pixel.x < image.get_width() and pixel.y < image.get_height() and image.get_pixelv(pixel).a > .1
