extends RefCounted
## Independent current-frame alpha/depth evidence. No production helper reads.
## Original Texture Images are cloned before decompression/cache ownership.
var images: Dictionary = {}

func image_for(sprite: Sprite2D) -> Image:
	if sprite == null or sprite.texture == null: return null
	var key: int = sprite.texture.get_instance_id()
	if images.has(key): return images[key]
	var original: Image = sprite.texture.get_image()
	if original == null or original.is_empty(): return null
	var owned: Image = original.duplicate() as Image
	if owned.is_compressed() and owned.decompress() != OK: return null
	images[key] = owned
	return owned

func frame(sprite: Sprite2D, image: Image) -> Rect2i:
	if image == null or sprite.hframes <= 0 or sprite.vframes <= 0: return Rect2i()
	var region := Rect2i(sprite.region_rect) if sprite.region_enabled else Rect2i(Vector2i.ZERO, image.get_size())
	if region.position.x < 0 or region.position.y < 0 or region.end.x > image.get_width() or region.end.y > image.get_height() or region.size.x <= 0 or region.size.y <= 0: return Rect2i()
	if region.size.x % sprite.hframes != 0 or region.size.y % sprite.vframes != 0: return Rect2i()
	var cell := Vector2i(region.size.x / sprite.hframes, region.size.y / sprite.vframes)
	var result := Rect2i(region.position + sprite.frame_coords * cell, cell)
	return result if region.encloses(result) else Rect2i()

func _bilinear(image: Image, coordinate: Vector2) -> float:
	var left: int = floori(coordinate.x)
	var top: int = floori(coordinate.y)
	var dx: float = coordinate.x - left
	var dy: float = coordinate.y - top
	var first: float = lerpf(image.get_pixel(clampi(left, 0, image.get_width() - 1), clampi(top, 0, image.get_height() - 1)).a, image.get_pixel(clampi(left + 1, 0, image.get_width() - 1), clampi(top, 0, image.get_height() - 1)).a, dx)
	var second: float = lerpf(image.get_pixel(clampi(left, 0, image.get_width() - 1), clampi(top + 1, 0, image.get_height() - 1)).a, image.get_pixel(clampi(left + 1, 0, image.get_width() - 1), clampi(top + 1, 0, image.get_height() - 1)).a, dx)
	return lerpf(first, second, dy)

func alpha_at(sprite: Sprite2D, world: Vector2) -> float:
	var image: Image = image_for(sprite)
	var source: Rect2i = frame(sprite, image)
	var rect: Rect2 = sprite.get_rect()
	if source.size.x <= 0 or source.size.y <= 0 or rect.size.x <= 0 or rect.size.y <= 0: return 0
	var uv: Vector2 = (sprite.to_local(world) - rect.position) / rect.size
	if uv.x < 0 or uv.y < 0 or uv.x >= 1 or uv.y >= 1: return 0
	if sprite.flip_h: uv.x = 1 - uv.x
	if sprite.flip_v: uv.y = 1 - uv.y
	var alpha := 0.0
	if sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR:
		alpha = _bilinear(image, Vector2(source.position) + uv * Vector2(source.size) - Vector2(.5, .5))
	else:
		var pixel: Vector2i = source.position + Vector2i(clampi(floori(uv.x * source.size.x), 0, source.size.x - 1), clampi(floori(uv.y * source.size.y), 0, source.size.y - 1))
		alpha = image.get_pixelv(pixel).a
	return alpha * sprite.modulate.a * sprite.self_modulate.a

func strong_intersection(actor: Sprite2D, prop: Sprite2D, hypothetical_world_delta := Vector2.ZERO) -> Dictionary:
	var original: Image = image_for(actor)
	var current: Rect2i = frame(actor, original)
	if current.size.x <= 0 or current.size.y <= 0 or image_for(prop) == null: return {"valid": false, "hits": 0}
	var rect: Rect2 = actor.get_rect()
	var hits := 0
	var witness: Array = []
	for y in current.size.y:
		for x in current.size.x:
			if original.get_pixelv(current.position + Vector2i(x, y)).a * actor.modulate.a * actor.self_modulate.a <= .12: continue
			var uv := Vector2((x + .5) / current.size.x, (y + .5) / current.size.y)
			if actor.flip_h: uv.x = 1 - uv.x
			if actor.flip_v: uv.y = 1 - uv.y
			var world: Vector2 = actor.to_global(rect.position + uv * rect.size) + hypothetical_world_delta
			if alpha_at(prop, world) > .12:
				hits += 1
				if witness.is_empty(): witness = [world.x, world.y]
	return {"valid": true, "hits": hits, "frame": actor.frame, "hframes": actor.hframes, "vframes": actor.vframes, "frame_rect": [current.position.x, current.position.y, current.size.x, current.size.y], "actor_texture_path": actor.texture.resource_path, "actor_texture_sha256": FileAccess.get_sha256(actor.texture.resource_path), "prop_texture_path": prop.texture.resource_path, "prop_texture_sha256": FileAccess.get_sha256(prop.texture.resource_path), "prop_filter": prop.texture_filter, "first_actual_strong_pixel": witness}

func bounds_in(sprite: Sprite2D, container: Node2D) -> Rect2:
	var rect: Rect2 = sprite.get_rect()
	var result := Rect2(container.to_local(sprite.to_global(rect.position)), Vector2.ZERO)
	for point: Vector2 in [rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]: result = result.expand(container.to_local(sprite.to_global(point)))
	return result

func effective_z(item: CanvasItem) -> int:
	var total := 0
	var current: Node = item
	while current is CanvasItem:
		total += (current as CanvasItem).z_index
		if not (current as CanvasItem).z_as_relative: break
		current = current.get_parent()
	return total

func actual_in_front(first: CanvasItem, second: CanvasItem) -> bool:
	var a: int = effective_z(first)
	var b: int = effective_z(second)
	return a > b or (a == b and first.get_parent() == second.get_parent() and first.get_index() > second.get_index())

func release() -> void:
	images.clear()
