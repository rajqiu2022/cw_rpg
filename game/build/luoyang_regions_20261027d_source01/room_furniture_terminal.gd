extends RefCounted
## Concrete source-bound furniture donors for this batch's six actual rooms.
## It imports no old room floor, Scene owner, NPC or service identity.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")

static func build(binding: Dictionary, available: Dictionary) -> Dictionary:
	var path: String = String(binding.get("path", ""))
	var author: Dictionary = Core.read_json(path, String(binding.get("sha256", "")))
	if author.is_empty() or author.get("assets_ready") != true or not author.get("furniture") is Array: return Core.fail("ROOM_DONOR_AUTHOR")
	var logical: String = String(author.get("room", {}).get("scene_id", ""))
	if logical.is_empty() or logical != binding.get("logical_id"): return Core.fail("ROOM_DONOR_LOGICAL_ID")
	var pins: Dictionary = {path: binding.sha256}
	var terminal: Dictionary = {"schema": "27D_SOURCE_TERMINAL_V1", "logical_id": logical, "local_size_px": [1536, 1024], "sources": pins, "render": [], "solids": [], "npcs": [], "portals": [], "interactions": []}
	var seen: Dictionary = {}
	for item: Dictionary in author.furniture:
		var id: String = String(item.get("id", ""))
		var texture: String = String(item.get("texture", ""))
		var foot: Vector2 = Core.vec(item.get("placement_foot_px"))
		var anchor: Vector2 = Core.vec(item.get("source_ground_anchor_px"))
		var size: Vector2 = Core.vec(item.get("source_size_px"))
		var ratio: float = float(item.get("render_scale", 0))
		if id.is_empty() or seen.has(id) or not foot.is_finite() or not anchor.is_finite() or not size.is_finite() or ratio <= 0: return Core.fail("ROOM_DONOR_FURNITURE", id)
		if available.get(texture) != item.get("source_sha256") or not _media(texture, pins, available): return Core.fail("ROOM_DONOR_TEXTURE", id)
		terminal.render.append({"id": id, "owner_id": id, "texture": texture, "texture_size_px": size, "position_px": foot - anchor * ratio, "foot_px": foot, "scale": Vector2.ONE * ratio, "centered": false, "source_row": {"id": id, "sort_by_feet": true, "source_room_author": path}})
		var bases: Array = author.get("geometry", {}).get("furniture_bases", []).filter(func(row: Dictionary) -> bool: return row.get("id") == id)
		if bases.size() != 1 or bases[0].get("blocking") != true: return Core.fail("ROOM_DONOR_BASE", id)
		var points := PackedVector2Array()
		for raw: Variant in bases[0].get("ground_polygon_px", []):
			var point: Vector2 = Core.vec(raw)
			if not point.is_finite(): return Core.fail("ROOM_DONOR_BASE_FINITE", id)
			points.append(point)
		if points.size() < 3: return Core.fail("ROOM_DONOR_BASE_EMPTY", id)
		terminal.solids.append({"id": id + "/0", "owner_id": id, "points_px": points})
		seen[id] = true
	if not Core.source_pass(pins): return Core.fail("ROOM_DONOR_SOURCE_FINAL")
	return {"ok": true, "terminal": terminal}

static func _media(path: String, pins: Dictionary, available: Dictionary) -> bool:
	var sidecar: String = path + ".import"
	if not available.has(path) or not available.has(sidecar) or FileAccess.get_sha256(sidecar) != available[sidecar]: return false
	var expression := RegEx.new()
	if expression.compile('path="(res://[^"\\r\\n]+\\.ctex)"') != OK: return false
	var matched: RegExMatch = expression.search(FileAccess.get_file_as_string(sidecar))
	if matched == null or not available.has(matched.get_string(1)): return false
	pins[path] = available[path]; pins[sidecar] = available[sidecar]; pins[matched.get_string(1)] = available[matched.get_string(1)]
	return true
