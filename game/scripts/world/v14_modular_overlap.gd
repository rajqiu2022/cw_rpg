extends RefCounted
## V14 only: exact current-frame actor alpha intersecting independent prop alpha.
## No collision/nav edits, no rectangular fade, no background dependency.
var _world: Node2D
var _props: Array[Dictionary] = []
var _images: Dictionary = {}
var _actor_pixels: Dictionary = {}
var _signature: Array = []
var _mask: Image
var _texture: ImageTexture
var _debug: Dictionary = {"active": false, "pixels": 0, "prop_hits": {}, "candidate_count": 0}
var _depth_entries: Array[Dictionary] = []
var _depth_bands: Dictionary = {}
var _depth_ordinal := 0
var _order_revision := 0

func configure(world: Node2D) -> void:
	_world = world

func add_prop(sprite: Sprite2D, id: String, foot_y: float) -> void:
	var image := _image(sprite.texture)
	if image == null: return
	var foot_global := _world.to_global(Vector2(sprite.position.x, foot_y))
	_props.append({"sprite": sprite, "id": id, "foot_local": sprite.to_local(foot_global), "image": image})
	_register_depth(sprite, id, sprite.to_local(foot_global), false)
	_signature.clear()

func add_actor(actor: Node2D) -> void:
	# Only the actual ActorLayer root participates; never its sprite or ghost.
	actor.set_meta("depth_band_max", 512)
	_register_depth(actor, String(actor.name), Vector2.ZERO, true)

func _register_depth(node: Node2D, id: String, foot_local: Vector2, actor: bool) -> void:
	for entry: Dictionary in _depth_entries:
		if not is_instance_valid(entry.node): continue
		if entry.node == node: return
	_depth_entries.append({"node": node, "id": id, "foot_local": foot_local, "actor": actor, "ordinal": _depth_ordinal, "band": -1, "foot_y": INF})
	_depth_ordinal += 1

func _refresh_depth_order() -> void:
	# O(N) scalar snapshot; sort/move only changed 8px buckets, not the tree.
	# Exact-foot ties retain original registration/source order.
	var dirty: Dictionary = {}
	for index in range(_depth_entries.size() - 1, -1, -1):
		var entry: Dictionary = _depth_entries[index]
		var old_band: int = entry.band
		# A freed Object cannot even be cast; validate the stored Variant first.
		if not is_instance_valid(entry.node):
			if old_band >= 0:
				_depth_bands[old_band].erase(entry)
				dirty[old_band] = true
			_depth_entries.remove_at(index)
			continue
		var node := entry.node as Node2D
		var foot_y: float = float(node.call("get_depth_sort_y")) if entry.actor else node.to_global(entry.foot_local).y
		var band := clampi(int(floor(foot_y / 8.0)), 0, 512)
		node.z_index = band
		if old_band == band and float(entry.foot_y) == foot_y: continue
		if old_band != band:
			if old_band >= 0:
				_depth_bands[old_band].erase(entry)
				dirty[old_band] = true
			if not _depth_bands.has(band): _depth_bands[band] = []
			_depth_bands[band].append(entry)
		entry.band = band
		entry.foot_y = foot_y
		dirty[band] = true
	for band in dirty:
		var members: Array = _depth_bands[band]
		members.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.foot_y) < float(b.foot_y) if float(a.foot_y) != float(b.foot_y) else int(a.ordinal) < int(b.ordinal))
		for entry: Dictionary in members:
			if not is_instance_valid(entry.node): continue
			var node := entry.node as Node2D
			# Different bands are already ordered by z; moving this small bucket
			# to the end preserves all other buckets' relative sibling order.
			node.get_parent().move_child(node, -1)
	if not dirty.is_empty(): _order_revision += 1

func get_depth_order_state() -> Array[Dictionary]:
	var state: Array[Dictionary] = []
	for entry: Dictionary in _depth_entries:
		if not is_instance_valid(entry.node): continue
		var node := entry.node as Node2D
		state.append({"id": entry.id, "foot_y": entry.foot_y, "band": entry.band, "sibling_index": node.get_index(), "stable_ordinal": entry.ordinal, "actor": entry.actor})
	return state

func _image(texture: Texture2D) -> Image:
	if texture == null: return null
	var key := texture.get_instance_id()
	if not _images.has(key):
		var image := texture.get_image()
		if image != null and image.is_compressed(): image.decompress()
		_images[key] = image
	return _images[key]

func effective_z(item: CanvasItem) -> int:
	var result := 0
	var node: Node = item
	while node is CanvasItem:
		result += (node as CanvasItem).z_index
		if not (node as CanvasItem).z_as_relative: break
		node = node.get_parent()
	return result

func _frame_rect(sprite: Sprite2D, image: Image) -> Rect2i:
	var region := Rect2i(sprite.region_rect) if sprite.region_enabled else Rect2i(Vector2i.ZERO, image.get_size())
	# Malformed runtime regions must never sample outside the Image (or keep an
	# old mask alive). Valid production sprites use an integral in-bounds atlas.
	if region.position.x < 0 or region.position.y < 0 or region.size.x <= 0 or region.size.y <= 0 or region.end.x > image.get_width() or region.end.y > image.get_height(): return Rect2i()
	var cell := Vector2i(region.size.x / sprite.hframes, region.size.y / sprite.vframes)
	return Rect2i(region.position + sprite.frame_coords * cell, cell)

func _world_bounds(sprite: Sprite2D) -> Rect2:
	var rect := sprite.get_rect()
	var first := sprite.to_global(rect.position)
	var result := Rect2(first, Vector2.ZERO)
	for corner in [rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]:
		result = result.expand(sprite.to_global(corner))
	return result

func _alpha_at(sprite: Sprite2D, image: Image, point: Vector2) -> float:
	var rect := sprite.get_rect()
	if rect.size.x <= 0 or rect.size.y <= 0: return 0
	var uv := (sprite.to_local(point) - rect.position) / rect.size
	if uv.x < 0 or uv.y < 0 or uv.x >= 1 or uv.y >= 1: return 0
	if sprite.flip_h: uv.x = 1.0 - uv.x
	if sprite.flip_v: uv.y = 1.0 - uv.y
	var frame := _frame_rect(sprite, image)
	if frame.size.x <= 0 or frame.size.y <= 0: return 0
	if sprite.texture_filter == CanvasItem.TEXTURE_FILTER_LINEAR:
		# UV references the full source texture even for Sprite2D atlas frames.
		# Keep that frame-edge sampling (including the adjacent atlas texel), and
		# clamp only the outer texture edges, matching non-repeating GPU sampling.
		var source_pixel := Vector2(frame.position) + uv * Vector2(frame.size) - Vector2(.5, .5)
		return _linear_alpha(image, source_pixel) * sprite.modulate.a * sprite.self_modulate.a
	var pixel := frame.position + Vector2i(clampi(int(uv.x * frame.size.x), 0, frame.size.x - 1), clampi(int(uv.y * frame.size.y), 0, frame.size.y - 1))
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= image.get_width() or pixel.y >= image.get_height(): return 0
	return image.get_pixelv(pixel).a * sprite.modulate.a * sprite.self_modulate.a

func _linear_alpha(image: Image, source_pixel: Vector2) -> float:
	var x := int(floor(source_pixel.x))
	var y := int(floor(source_pixel.y))
	var fraction := source_pixel - Vector2(x, y)
	var x0 := clampi(x, 0, image.get_width() - 1)
	var x1 := clampi(x + 1, 0, image.get_width() - 1)
	var y0 := clampi(y, 0, image.get_height() - 1)
	var y1 := clampi(y + 1, 0, image.get_height() - 1)
	var top := lerpf(image.get_pixel(x0, y0).a, image.get_pixel(x1, y0).a, fraction.x)
	var bottom := lerpf(image.get_pixel(x0, y1).a, image.get_pixel(x1, y1).a, fraction.x)
	return lerpf(top, bottom, fraction.y)

func refresh(player: Player, force: bool = false) -> void:
	_refresh_depth_order()
	if not is_instance_valid(player) or player.sprite == null or player.sprite.texture == null: return
	var actor := player.sprite
	var signature: Array = [actor.texture.get_instance_id(), actor.frame, actor.hframes, actor.vframes, actor.region_rect, actor.region_enabled, actor.global_transform, actor.flip_h, actor.flip_v, effective_z(actor), player.get_depth_sort_y(), player.get_index()]
	for prop: Dictionary in _props:
		if not is_instance_valid(prop.sprite): continue
		var node := prop.sprite as Sprite2D
		signature.append([node.global_transform, node.texture, node.texture_filter, node.frame, node.hframes, node.vframes, node.region_rect, node.region_enabled, node.is_visible_in_tree(), node.modulate.a, node.self_modulate.a, effective_z(node), node.get_index(), node.flip_h, node.flip_v])
	if not force and signature == _signature: return
	_signature = signature
	var image := _image(actor.texture)
	if image == null: return
	var frame := _frame_rect(actor, image)
	var rect := actor.get_rect()
	if frame.size.x <= 0 or frame.size.y <= 0:
		_debug = {"active": false, "pixels": 0, "prop_hits": {}, "candidate_count": 0, "invalid_actor_frame": true}
		player.set_building_overlap(false, .46, true)
		return
	var key := "%d:%s" % [actor.texture.get_instance_id(), str(frame)]
	if not _actor_pixels.has(key):
		var points := PackedVector2Array()
		for y in frame.size.y:
			for x in frame.size.x:
				if image.get_pixel(frame.position.x + x, frame.position.y + y).a > 0:
					points.append(Vector2(x, y))
		_actor_pixels[key] = points
	var candidates: Array[Dictionary] = []
	var actor_z := effective_z(actor)
	var bounds := _world_bounds(actor)
	for prop: Dictionary in _props:
		if not is_instance_valid(prop.sprite): continue
		var node := prop.sprite as Sprite2D
		if not node.is_visible_in_tree(): continue
		prop.image = _image(node.texture)
		if prop.image == null: continue
		# Same-band ordering uses the real ActorLayer siblings after foot sort.
		# Strictly front/equal feet never ghost, including stable exact-foot ties.
		var prop_z := effective_z(node)
		if node.to_global(prop.foot_local).y <= player.get_depth_sort_y() or prop_z < actor_z or (prop_z == actor_z and node.get_index() <= player.get_index()): continue
		if bounds.intersects(_world_bounds(node)): candidates.append(prop)
	if _mask == null or _mask.get_size() != frame.size:
		_mask = Image.create(frame.size.x, frame.size.y, false, Image.FORMAT_RGBA8)
		_texture = ImageTexture.create_from_image(_mask)
	_mask.fill(Color(0, 0, 0, 0))
	var pixels := 0
	var hits: Dictionary = {}
	var ghost_z := 450
	# Most travelling frames have no overlapping foreground; avoid walking the
	# entire current actor alpha set then, but still clear any previous mask.
	var visible_points: PackedVector2Array = _actor_pixels[key] if not candidates.is_empty() else PackedVector2Array()
	for p: Vector2 in visible_points:
		var uv := (p + Vector2(.5, .5)) / Vector2(frame.size)
		if actor.flip_h: uv.x = 1.0 - uv.x
		if actor.flip_v: uv.y = 1.0 - uv.y
		var world_point := actor.to_global(rect.position + uv * rect.size)
		var remaining := 1.0
		for prop: Dictionary in candidates:
			var alpha := _alpha_at(prop.sprite, prop.image, world_point)
			if alpha > 0:
				remaining *= 1.0 - alpha
				hits[prop.id] = int(hits.get(prop.id, 0)) + 1
				ghost_z = maxi(ghost_z, effective_z(prop.sprite) + 1)
		if remaining < 1.0:
			_mask.set_pixel(int(p.x), int(p.y), Color(1, 1, 1, 1.0 - remaining))
			pixels += 1
	_texture.update(_mask)
	_debug = {"active": pixels > 0, "space": "actor_frame", "pixels": pixels, "prop_hits": hits, "candidate_count": candidates.size(), "frame_rect": frame, "actor_rect": rect, "flip": Vector2(1 if actor.flip_h else 0, 1 if actor.flip_v else 0), "actor_texture_id": actor.texture.get_instance_id(), "actor_z": actor_z, "actor_sibling_index": player.get_index(), "order_revision": _order_revision, "ghost_z": ghost_z, "mask_image": _mask, "mask_texture": _texture, "image_cache_size": _images.size()}
	player.set_building_overlap(pixels > 0, .46, true, {"space": "actor_frame", "texture": _texture, "actor_rect": rect, "flip": Vector2(1 if actor.flip_h else 0, 1 if actor.flip_v else 0), "ghost_z": ghost_z})

func get_debug_state() -> Dictionary:
	return _debug.duplicate()
