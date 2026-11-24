extends RefCounted
## Cold visual-child construction under the real REGION_27D lease only.
## No collision, SceneObject, portal, static floor refresh, or old-owner adapter.
const SELF = "res://build/luoyang_city_rectification_20261027d_system01/region_render_auxiliary.gd"
const SESSION = "res://build/luoyang_regions_20261027d_source01/region_session.gd"

static func _vector(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if raw is Array and raw.size() == 2:
		for value: Variant in raw:
			if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)): return Vector2.INF
		return Vector2(float(raw[0]), float(raw[1]))
	return Vector2.INF

static func _color(raw: Variant) -> Color:
	if raw is Color: return raw
	if raw is Array and raw.size() == 4:
		for value: Variant in raw:
			if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)): return Color(-1,-1,-1,-1)
		return Color(float(raw[0]), float(raw[1]), float(raw[2]), float(raw[3]))
	return Color(-1,-1,-1,-1)

static func install(field: Node, session: RefCounted, render_row: Dictionary, parent: Sprite2D) -> bool:
	var children: Variant = render_row.get("auxiliary_children", [])
	if not children is Array: return false
	if children.is_empty(): return true
	if not is_instance_valid(field) or not is_instance_valid(session) or not is_instance_valid(parent) or not parent.is_inside_tree(): return false
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if scene == null or scene.map_layout == null or field.get("_region_owner") != session or session.get_script() != load(SESSION) or session.call("matches", field, scene) != true: return false
	var receipt: Dictionary = session.call("receipt")
	if receipt.get("owner_kind") != "REGION_27D" or receipt.get("token") != session.get_instance_id() or receipt.get("token") == 0 or receipt.get("phase") not in ["FIRST", "LIVE"]: return false
	if receipt.get("field_instance") != field.get_instance_id() or receipt.get("scene_instance") != scene.get_instance_id() or receipt.get("layout_instance") != scene.map_layout.get_instance_id(): return false
	var first: Variant = receipt.get("source_first")
	if not first is Dictionary or not first.has(SELF) or not first.has(SESSION) or first.get(SELF) != FileAccess.get_sha256(SELF): return false
	if receipt.phase == "LIVE" and var_to_bytes(receipt.get("source_final")) != var_to_bytes(first): return false
	var compiled: Variant = session.get("_compiled")
	var region: Variant = field.get("_region")
	if not compiled is Dictionary or not region is Dictionary or compiled.get("id") != region.get("id") or compiled.get("revision") != receipt.get("revision"): return false
	var key: String = String(render_row.get("key", ""))
	if key.is_empty(): return false
	# Compare this entire row, including every child descriptor, to both frozen
	# session content and its actual Field render table. No observed expectation.
	for table: Variant in [compiled.get("render"), region.get("render")]:
		if not table is Array: return false
		var found: int = 0
		for candidate: Dictionary in table:
			if candidate.get("key") != key: continue
			found += 1
			if var_to_bytes(candidate) != var_to_bytes(render_row): return false
		if found != 1: return false
	var visuals: Variant = field.get("_region_visuals")
	var path: String = String(render_row.get("texture", ""))
	if not visuals is Dictionary or visuals.get(key) != parent or parent.get_parent() != field.get("_visual_layer") or not first.has(path): return false
	if parent.texture == null or parent.texture != load(path) or parent.texture.get_size() != render_row.get("texture_size_px") or parent.position != render_row.get("position_px") or parent.scale != render_row.get("scale"): return false
	if parent.centered != render_row.get("centered", true) or parent.flip_h or parent.flip_v or parent.region_enabled or parent.rotation != 0.0 or parent.material != null: return false
	var original: Dictionary = render_row.get("source_row", {})
	var expected_modulate: Color = original.modulate if original.get("modulate") is Color else Color.WHITE
	if parent.modulate != expected_modulate or parent.self_modulate != Color.WHITE: return false
	var expected_z: int = clampi(floori(render_row.foot_px.y / 8.0), 0, 4095) if original.get("sort_by_feet", true) else int(original.get("z_index", 0))
	if parent.z_index != expected_z: return false
	var ids: Dictionary = {}
	var plans: Array[Dictionary] = []
	for child: Dictionary in children:
		var id: String = String(child.get("id", ""))
		var texture_path: String = String(child.get("texture", ""))
		var atlas_path: String = String(child.get("atlas_source", ""))
		var sources: Variant = child.get("source_sha256")
		if id.is_empty() or "/" in id or ":" in id or ids.has(id) or parent.get_node_or_null(NodePath(id)) != null: return false
		if child.get("parent_key") != key or child.get("parent_texture") != path or _vector(child.get("parent_texture_size_px")) != parent.texture.get_size() or child.get("parent_centered") != parent.centered: return false
		if not sources is Dictionary or sources.is_empty() or not sources.has(texture_path) or not sources.has(atlas_path): return false
		for source_path: String in sources:
			if not sources[source_path] is String or sources[source_path].length() != 64 or first.get(source_path) != sources[source_path]: return false
		var local_position: Vector2 = _vector(child.get("local_position_px"))
		var dimensions: Vector2 = _vector(child.get("texture_size_px"))
		var local_scale: Vector2 = _vector(child.get("local_scale", Vector2.ONE))
		var tint: Color = _color(child.get("modulate", Color.WHITE))
		if not local_position.is_finite() or not dimensions.is_finite() or dimensions.x <= 0 or dimensions.y <= 0 or local_scale != Vector2.ONE: return false
		for channel: float in [tint.r, tint.g, tint.b, tint.a]:
			if not is_finite(channel): return false
		if tint.r < 0 or tint.r > 1 or tint.g < 0 or tint.g > 1 or tint.b < 0 or tint.b > 1 or tint.a != 1.0: return false
		if child.get("relative_z") != -1 or child.get("inherit_parent_material") != true or child.get("centered", true) != true or child.get("texture_filter", CanvasItem.TEXTURE_FILTER_LINEAR) != CanvasItem.TEXTURE_FILTER_LINEAR: return false
		var texture: AtlasTexture = load(texture_path) as AtlasTexture
		if texture == null or texture.resource_path != texture_path or texture.get_size() != dimensions or texture.atlas == null or texture.atlas != load(atlas_path) or texture.atlas.resource_path != atlas_path: return false
		if not child.get("atlas_region") is Rect2 or texture.region != child.atlas_region or texture.region.size != dimensions or texture.margin != Rect2() or not texture.filter_clip: return false
		if not Rect2(Vector2.ZERO, texture.atlas.get_size()).encloses(texture.region): return false
		plans.append({"id":id, "texture":texture, "position":local_position, "tint":tint})
		ids[id] = true
	# Allocate only after every descriptor passes. Parent owns lifetime, transform,
	# depth and modulation. Explicit child tint is a local multiplier, not a copy
	# of parent.modulate (which would square inherited opacity).
	for plan: Dictionary in plans:
		var child := Sprite2D.new()
		child.name = plan.id; child.texture = plan.texture; child.centered = true
		child.position = plan.position; child.scale = Vector2.ONE
		child.z_as_relative = true; child.z_index = -1
		child.modulate = plan.tint; child.use_parent_material = true
		child.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		child.set_meta("region27d_auxiliary", {"parent_key":key, "session_token":str(session.get_instance_id()), "scene_instance":str(scene.get_instance_id()), "compiled_SHA256":receipt.compiled_SHA256, "source_first":true, "new_body_or_portal":false})
		parent.add_child(child)
	return session.call("matches", field, scene) == true
