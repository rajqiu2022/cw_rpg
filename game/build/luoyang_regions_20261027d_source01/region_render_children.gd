extends RefCounted
## Exact authored door-depth children. No collision, masking, or new image pixels.
static func install(parent: Sprite2D, rows: Array, declared_sources: Dictionary) -> bool:
	if parent == null or parent.texture == null or not parent.is_inside_tree(): return false
	var ids: Dictionary = {}
	for row: Dictionary in rows:
		var id: String = String(row.get("id", ""))
		var path: String = String(row.get("texture", ""))
		var position: Variant = row.get("local_position_px")
		var expected: Variant = row.get("texture_size_px")
		if id.is_empty() or ids.has(id) or not declared_sources.has(path) or not position is Vector2 or not position.is_finite() or not expected is Vector2: return false
		if int(row.get("relative_z", 0)) != -1 or row.get("inherit_parent_material") != true: return false
		var texture: AtlasTexture = load(path) as AtlasTexture
		if texture == null or texture.get_size() != expected or texture.atlas == null or not texture.filter_clip: return false
		if texture.region != row.get("atlas_region") or texture.atlas.resource_path != row.get("atlas_source") or not declared_sources.has(texture.atlas.resource_path): return false
		var child := Sprite2D.new()
		child.name = id; child.texture = texture; child.position = position
		child.centered = true; child.scale = Vector2.ONE
		child.z_as_relative = true; child.z_index = -1
		child.use_parent_material = true
		# Parent scale/modulate naturally multiply the child; assigning the same
		# modulate again would square opacity/tint. White is the neutral multiplier.
		child.modulate = Color.WHITE
		parent.add_child(child); ids[id] = true
	return true
