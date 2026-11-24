extends "res://scripts/city/luoyang_v3_modular_overlap.gd"
## Enclosure only. Native Float32 feet, prop-before-actor ties, stable ordinal.
## The snapshot used to write Z/siblings also owns mask eligibility/cache keys.
## Alpha/image/frame/LINEAR sampling is inherited, without any threshold change.
var _native_snapshot: Dictionary = {}
var _native_snapshot_valid := false

static func native_depth_key(value: float) -> Variant:
	if not is_finite(value): return null
	var native: float = Vector2(0.0, value).y
	if not is_finite(native): return null
	return 0.0 if native == 0.0 else native

static func canonical_depth_order_key(foot_y: float, actor: bool, ordinal: int) -> Dictionary:
	var native: Variant = native_depth_key(foot_y)
	if native == null or ordinal < 0: return {}
	return {"foot_y":native,"kind_rank":1 if actor else 0,"stable_ordinal":ordinal}

static func _valid_depth_key(key: Dictionary) -> bool:
	if key.size() != 3 or not key.has_all(["foot_y","kind_rank","stable_ordinal"]): return false
	if typeof(key.foot_y) != TYPE_FLOAT or typeof(key.kind_rank) != TYPE_INT or typeof(key.stable_ordinal) != TYPE_INT: return false
	var native: Variant = native_depth_key(key.foot_y)
	return native != null and native == key.foot_y and int(key.kind_rank) in [0,1] and int(key.stable_ordinal) >= 0

static func depth_key_before(a: Dictionary, b: Dictionary) -> bool:
	if not _valid_depth_key(a) or not _valid_depth_key(b): return false
	if a.foot_y != b.foot_y: return a.foot_y < b.foot_y
	if a.kind_rank != b.kind_rank: return a.kind_rank < b.kind_rank
	return a.stable_ordinal < b.stable_ordinal

func _refresh_depth_order() -> void:
	_native_snapshot.clear()
	_native_snapshot_valid = false
	if not is_instance_valid(_world): return
	var dirty: Dictionary = {}
	var shared_parent: Node
	# Read each live scalar foot exactly once. No getter is queried later by
	# eligibility, and no Double residue can disagree with native Sprite2D Y.
	for index in range(_depth_entries.size() - 1, -1, -1):
		var entry: Dictionary = _depth_entries[index]
		var old_band: int = int(entry.band)
		if not is_instance_valid(entry.node):
			if old_band >= 0 and _depth_bands.has(old_band):
				_depth_bands[old_band].erase(entry); dirty[old_band] = true
			_depth_entries.remove_at(index)
			continue
		var node: Node2D = entry.node as Node2D
		if node == null or not node.is_inside_tree() or node.is_queued_for_deletion() or not _world.is_ancestor_of(node): return
		if shared_parent == null: shared_parent = node.get_parent()
		elif node.get_parent() != shared_parent: return
		if bool(entry.actor) and not node.has_method("get_depth_sort_y"): return
		var raw: Variant = node.call("get_depth_sort_y") if bool(entry.actor) else node.to_global(entry.foot_local).y
		if typeof(raw) not in [TYPE_FLOAT,TYPE_INT]: return
		var key: Dictionary = canonical_depth_order_key(float(raw), bool(entry.actor), int(entry.ordinal))
		if key.is_empty(): return
		var band: int = clampi(int(floor(float(key.foot_y) / 8.0)), 0, 255)
		_native_snapshot[node.get_instance_id()] = {"node":node,"key":key,"raw_foot_y":float(raw),"band":band}
	# The whole finite snapshot must be valid before any live node is reordered.
	for entry: Dictionary in _depth_entries:
		var node: Node2D = entry.node as Node2D
		var snap: Dictionary = _native_snapshot[node.get_instance_id()]
		var old_band: int = int(entry.band)
		var band: int = int(snap.band)
		node.z_index = band
		entry.raw_foot_y = snap.raw_foot_y
		if old_band == band and entry.foot_y == snap.key.foot_y: continue
		if old_band != band:
			if old_band >= 0 and _depth_bands.has(old_band):
				_depth_bands[old_band].erase(entry); dirty[old_band] = true
			if not _depth_bands.has(band): _depth_bands[band] = []
			_depth_bands[band].append(entry)
		entry.band = band; entry.foot_y = snap.key.foot_y
		dirty[band] = true
	for band: Variant in dirty:
		var members: Array = _depth_bands[band]
		members.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return depth_key_before(_native_snapshot[a.node.get_instance_id()].key, _native_snapshot[b.node.get_instance_id()].key))
		for entry: Dictionary in members:
			var node: Node2D = entry.node as Node2D
			node.get_parent().move_child(node, -1)
	if not dirty.is_empty(): _order_revision += 1
	for snap: Dictionary in _native_snapshot.values():
		snap.sibling_index = snap.node.get_index()
		snap.effective_z = effective_z(snap.node)
	_native_snapshot_valid = true

func get_depth_order_state() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in _depth_entries:
		if not is_instance_valid(entry.node): continue
		var snap: Dictionary = _native_snapshot.get(entry.node.get_instance_id(), {})
		if snap.is_empty() or not _native_snapshot_valid: continue
		result.append({"id":entry.id,"foot_y":snap.key.foot_y,"raw_foot_y":snap.raw_foot_y,"kind_rank":snap.key.kind_rank,"band":snap.band,"sibling_index":snap.sibling_index,"stable_ordinal":snap.key.stable_ordinal,"actor":entry.actor})
	return result

func refresh(player: Player, force: bool = false) -> void:
	_refresh_depth_order()
	if not is_instance_valid(player) or player.sprite == null or player.sprite.texture == null: return
	if not _native_snapshot_valid or not _native_snapshot.has(player.get_instance_id()):
		_signature.clear()
		_debug = {"active":false,"pixels":0,"prop_hits":{},"candidate_count":0,"invalid_depth_snapshot":true}
		player.set_building_overlap(false, .46, true)
		return
	var actor := player.sprite
	var actor_snapshot: Dictionary = _native_snapshot[player.get_instance_id()]
	var actor_z: int = effective_z(actor)
	var signature: Array = [actor.texture.get_instance_id(), actor.frame, actor.hframes, actor.vframes, actor.region_rect, actor.region_enabled, actor.global_transform, actor.flip_h, actor.flip_v, actor_z, actor_snapshot.key, actor_snapshot.sibling_index, _order_revision]
	for prop: Dictionary in _props:
		if not is_instance_valid(prop.sprite): continue
		var node := prop.sprite as Sprite2D
		var snap: Dictionary = _native_snapshot.get(node.get_instance_id(), {})
		signature.append([node.global_transform, node.texture, node.texture_filter, node.frame, node.hframes, node.vframes, node.region_rect, node.region_enabled, node.is_visible_in_tree(), node.modulate.a, node.self_modulate.a, snap, node.flip_h, node.flip_v])
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
	var bounds := _world_bounds(actor)
	for prop: Dictionary in _props:
		if not is_instance_valid(prop.sprite): continue
		var node := prop.sprite as Sprite2D
		if not node.is_visible_in_tree(): continue
		prop.image = _image(node.texture)
		if prop.image == null: continue
		var snap: Dictionary = _native_snapshot.get(node.get_instance_id(), {})
		# Equal native feet put props BEFORE actors, so there is no ghost. Z,
		# sibling indices and the strict total-order key come from this refresh.
		if snap.is_empty() or not depth_key_before(actor_snapshot.key, snap.key) or int(snap.effective_z) < actor_z or (int(snap.effective_z) == actor_z and int(snap.sibling_index) <= int(actor_snapshot.sibling_index)): continue
		if bounds.intersects(_world_bounds(node)): candidates.append(prop)
	# This pixel core is the original refresh body: same RGBA mask, current-frame
	# alpha points, LINEAR prop sampling, union multiplication and ghost Z/math.
	if _mask == null or _mask.get_size() != frame.size:
		_mask = Image.create(frame.size.x, frame.size.y, false, Image.FORMAT_RGBA8)
		_texture = ImageTexture.create_from_image(_mask)
	_mask.fill(Color(0, 0, 0, 0))
	var pixels := 0
	var hits: Dictionary = {}
	var ghost_z := 450
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
				var snap: Dictionary = _native_snapshot[prop.sprite.get_instance_id()]
				ghost_z = maxi(ghost_z, int(snap.effective_z) + 1)
		if remaining < 1.0:
			_mask.set_pixel(int(p.x), int(p.y), Color(1, 1, 1, 1.0 - remaining))
			pixels += 1
	_texture.update(_mask)
	_debug = {"active": pixels > 0, "space": "actor_frame", "pixels": pixels, "prop_hits": hits, "candidate_count": candidates.size(), "frame_rect": frame, "actor_rect": rect, "flip": Vector2(1 if actor.flip_h else 0, 1 if actor.flip_v else 0), "actor_texture_id": actor.texture.get_instance_id(), "actor_z": actor_z, "actor_sibling_index": actor_snapshot.sibling_index, "order_revision": _order_revision, "ghost_z": ghost_z, "mask_image": _mask, "mask_texture": _texture, "image_cache_size": _images.size(), "native_depth_key":actor_snapshot.key,"raw_actor_foot_y":actor_snapshot.raw_foot_y}
	player.set_building_overlap(pixels > 0, .46, true, {"space": "actor_frame", "texture": _texture, "actor_rect": rect, "flip": Vector2(1 if actor.flip_h else 0, 1 if actor.flip_v else 0), "ghost_z": ghost_z})
