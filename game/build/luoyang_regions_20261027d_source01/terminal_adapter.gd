extends RefCounted
## Cold source compiler adapter. No legacy owner preparation and no live Field.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Projector = preload("res://build/luoyang_city_rectification_20261027d_system01/logical_terminal_projector.gd")
const Portals = preload("res://build/luoyang_city_rectification_20261027d_system01/pure_portal_projection.gd")

static func vector(value: Variant) -> Vector2:
	return value if value is Vector2 else Core.vec(value)

static func fail(code: String, detail: String = "") -> Dictionary:
	return Core.fail("TERMINAL_" + code, detail)

static func source_context(terminal: Dictionary) -> Dictionary:
	var path: String = String(terminal.get("source_scene_path", ""))
	if not path.begins_with("res://") or terminal.get("sources", {}).get(path) != terminal.get("source_scene_sha256", "") or FileAccess.get_sha256(path) != terminal.get("source_scene_sha256", ""): return fail("SCENE_PIN")
	var source: SceneScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if source == null or String(source.scene_id) != terminal.get("logical_id") or source.map_layout == null: return fail("SCENE_IDENTITY")
	var layout_path: String = String(terminal.get("source_layout_path", ""))
	if not layout_path.is_empty():
		if terminal.sources.get(layout_path) != terminal.get("source_layout_sha256", "") or FileAccess.get_sha256(layout_path) != terminal.get("source_layout_sha256", ""): return fail("PAIRED_LAYOUT_PIN")
		var layout: WalkableMapLayout = ResourceLoader.load(layout_path, "", ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if layout == null: return fail("PAIRED_LAYOUT_TYPE")
		# A source view is an independent compilation resource, not an old owner.
		# The original Scene and external Layout are never written or mutated.
		source = source.duplicate(true) as SceneScript
		source.map_layout = layout
	return {"ok": true, "source_scene": source, "terminal": terminal}

static func png_size(path: String) -> Vector2:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 24: return Vector2.ZERO
	var header: PackedByteArray = file.get_buffer(24)
	if header.slice(0, 8) != PackedByteArray([137,80,78,71,13,10,26,10]): return Vector2.ZERO
	var width: int = (int(header[16]) << 24) | (int(header[17]) << 16) | (int(header[18]) << 8) | int(header[19])
	var height: int = (int(header[20]) << 24) | (int(header[21]) << 16) | (int(header[22]) << 8) | int(header[23])
	return Vector2(width, height) if width > 0 and height > 0 else Vector2.ZERO

static func polygon(raw: Variant) -> PackedVector2Array:
	if raw is PackedVector2Array: return raw.duplicate()
	var result := PackedVector2Array()
	if not raw is Array: return result
	for point: Variant in raw:
		var v: Vector2 = vector(point)
		if not v.is_finite(): return PackedVector2Array()
		result.append(v)
	return result

static func capture_media(path: String, pins: Dictionary, available: Dictionary) -> bool:
	if path.is_empty(): return true
	if not available.has(path): return false
	pins[path] = available[path]
	if path.ends_with(".png"):
		var sidecar: String = path + ".import"
		if not available.has(sidecar) or FileAccess.get_sha256(sidecar) != available[sidecar]: return false
		pins[sidecar] = available[sidecar]
		var expression := RegEx.new()
		if expression.compile('path="(res://[^"\\r\\n]+\\.ctex)"') != OK: return false
		var matched: RegExMatch = expression.search(FileAccess.get_file_as_string(sidecar))
		if matched == null or not available.has(matched.get_string(1)): return false
		pins[matched.get_string(1)] = available[matched.get_string(1)]
	return true

static func build(binding: Dictionary, declared_sources: Dictionary, flags: Dictionary, states: Dictionary, available_sources: Dictionary = {}) -> Dictionary:
	# binding itself is fixed author input. All SHA values are declarations, never
	# filled from runtime observation. This runs once to produce an immutable bin.
	var payload_binding: Dictionary = binding.get("payload", {})
	var payload_path: String = String(payload_binding.get("path", ""))
	if not declared_sources.has(payload_path) or declared_sources[payload_path] != payload_binding.get("sha256") or not Core.source_pass(declared_sources): return fail("DECLARED_SOURCE_SET")
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(payload_path)
	if bytes.size() != int(payload_binding.get("bytes", -1)): return fail("PAYLOAD_LENGTH")
	var decoded: Variant = bytes_to_var(bytes)
	if not decoded is Dictionary or not Core.plain(decoded): return fail("PAYLOAD_TYPE")
	var payload: Dictionary = decoded
	var logical: String = String(binding.get("logical_id", ""))
	var size: Vector2 = vector(payload.get("world_size_px"))
	if payload.get("scene_id") != logical or not size.is_finite() or size.x <= 0 or size.y <= 0: return fail("PAYLOAD_ID")
	var terminal: Dictionary = {"schema": "27D_SOURCE_TERMINAL_V1", "logical_id": logical, "local_size_px": [size.x, size.y], "sources": declared_sources.duplicate(true), "source_scene_path": binding.get("source_scene_path", ""), "source_scene_sha256": binding.get("source_scene_sha256", ""), "source_layout_path": binding.get("source_layout_path", ""), "source_layout_sha256": binding.get("source_layout_sha256", ""), "finish_payload": payload.duplicate(true), "render": [], "solids": [], "npcs": [], "portals": [], "interactions": []}
	var context: Dictionary = source_context(terminal)
	if context.get("ok") != true: return context
	var source: SceneScript = context.source_scene
	if var_to_bytes(source.map_layout.visual_objects) != var_to_bytes(payload.parent_native_navigation): return fail("ORIGINAL_NATIVE_NAVIGATION")
	var all_polygons: Array = []
	var owner_ids: Dictionary = {}
	for row: Dictionary in payload.effective_navigation:
		var id: String = String(row.get("id", ""))
		var texture: String = String(row.get("texture", ""))
		if id.is_empty() or owner_ids.has(id) or not declared_sources.has(texture): return fail("RENDER_OWNER_OR_TEXTURE", id)
		owner_ids[id] = true
		var dimensions: Vector2 = png_size(texture)
		if dimensions == Vector2.ZERO: return fail("PNG_DIMENSIONS_OR_ATLAS_NEEDS_EXPLICIT_ADAPTER", id)
		var position: Vector2 = vector(row.get("pos")) * size
		var foot: Vector2 = vector(row.get("world_foot_px"))
		if not foot.is_finite() and row.has("depth_sort_foot_y"): foot = Vector2(position.x, float(row.depth_sort_foot_y) * size.y)
		var scale: Vector2 = vector(row.get("render_size_px")) / dimensions if row.has("render_size_px") else Vector2.ONE * float(row.get("scale", 1.0))
		if not position.is_finite() or not foot.is_finite() or not scale.is_finite() or scale.x <= 0 or scale.y <= 0: return fail("RENDER_TRANSFORM", id)
		terminal.render.append({"id": id, "owner_id": id, "position_px": position, "foot_px": foot, "scale": scale, "centered": row.get("centered", true), "texture": texture, "texture_size_px": dimensions, "source_row": row.duplicate(true)})
		var ordinal: int = 0
		var raw_polygons: Array = row.get("city_v3_solid_polygons_px", []).duplicate(true)
		var collision: Vector2 = vector(row.get("collision_size_px", Vector2.ZERO))
		if raw_polygons.is_empty() and collision.x > 0 and collision.y > 0:
			var center: Vector2 = vector(row.get("physical_center_px"))
			if not center.is_finite(): return fail("RECT_BODY_CENTER", id)
			var top: Vector2 = center - collision * .5
			var end: Vector2 = top + collision # Original Rect2(pos,size).end order, including f32.
			raw_polygons.append(PackedVector2Array([top, Vector2(end.x, top.y), end, Vector2(top.x, end.y)]))
		for raw: Variant in raw_polygons:
			var points: PackedVector2Array = polygon(raw)
			if points.size() < 3: return fail("OWNER_POLYGON", id)
			terminal.solids.append({"id": id + "/" + str(ordinal), "owner_id": id, "points_px": points})
			all_polygons.append(points); ordinal += 1
	# Exact complete sequence, not approximate geometry or a count-only claim.
	if var_to_bytes(all_polygons) != var_to_bytes(payload.effective_solids): return fail("OWNER_COMPLETE_SOLIDS_TYPED_SEQUENCE")
	var portal_projection: Dictionary = Portals.project(source, terminal)
	if portal_projection.get("ok") != true: return portal_projection
	for path: String in portal_projection.source_sha256:
		if terminal.sources.has(path) and terminal.sources[path] != portal_projection.source_sha256[path]: return fail("PORTAL_SOURCE_CONFLICT", path)
		terminal.sources[path] = portal_projection.source_sha256[path]
	for row: Dictionary in portal_projection.portals:
		var uv: Vector2 = vector(row.get("source_spawn_pos", row.get("pos")))
		var foot: Vector2 = vector(row.get("pos")) * size
		if not foot.is_finite() or not uv.is_finite(): return fail("PORTAL_FOOT")
		terminal.portals.append({"id": String(row.get("id", "")), "foot_px": foot, "legacy_source_uv": uv, "size_px": vector(row.get("size", Vector2(.03, .025))) * size, "target_scene": String(row.get("target_scene", "")), "data": row.duplicate(true)})
	var projected: Dictionary = Projector.project(StringName(logical), source, terminal, flags, states)
	if projected.get("ok") != true: return projected
	for actor: Dictionary in projected.npcs:
		for key: String in ["sprite_path", "portrait_path", "walk_sprite_path"]:
			var path: String = String(actor.data.get(key, ""))
			if not capture_media(path, projected.sources, available_sources): return fail("ACTOR_MEDIA_AUTHORITY", path)
		for path: String in actor.data.get("conversation_sprite_paths", {}):
			if not capture_media(String(actor.data.conversation_sprite_paths[path]), projected.sources, available_sources): return fail("ACTOR_FACING_AUTHORITY", path)
	if not Core.source_pass(projected.sources): return fail("FINAL_CONSUMED_SOURCE")
	projected.erase("actor_slots"); projected.erase("receipt"); projected.erase("ok")
	if not Core.plain(projected): return fail("PROJECTOR_OBJECT_ESCAPE")
	return {"ok": true, "terminal": projected, "source_context": context}
