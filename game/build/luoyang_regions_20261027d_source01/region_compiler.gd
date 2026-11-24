extends RefCounted
## NEW authority. Pure source projection; never changes a legacy Scene/Layout.
## terminal_inputs are authored, pinned Variant bundles, NOT live Field captures.
const SCHEMA := "LUOYANG_REGION_27D_V1"
const CELL := 256

static func pair(value: Variant) -> bool:
	return value is Array and value.size() == 2 and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value[0])) and is_finite(float(value[1])) and Vector2(value[0], value[1]).is_finite()

static func vec(value: Variant) -> Vector2:
	return Vector2(value[0], value[1]) if pair(value) else Vector2(INF, INF)

static func rect(value: Variant) -> Rect2:
	return Rect2(vec(value[0]), vec(value[1])) if value is Array and value.size() == 2 and pair(value[0]) and pair(value[1]) else Rect2()

static func fail(code: String, detail: String = "") -> Dictionary:
	return {"ok": false, "error": code, "detail": detail}

static func read_json(path: String, expected_sha: String) -> Dictionary:
	if expected_sha.length() != 64 or FileAccess.get_sha256(path) != expected_sha: return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

static func source_pass(sources: Dictionary) -> bool:
	if sources.is_empty(): return false
	for path: String in sources:
		if not path.begins_with("res://") or ".." in path or String(sources[path]).length() != 64 or FileAccess.get_sha256(path) != sources[path]: return false
	return true

static func load_terminal(binding: Dictionary) -> Dictionary:
	var path: String = String(binding.get("path", ""))
	if not path.begins_with("res://") or FileAccess.get_sha256(path) != binding.get("sha256", ""): return {}
	var raw: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if raw.size() != int(binding.get("bytes", -1)): return {}
	var value: Variant = bytes_to_var(raw)
	if not value is Dictionary or value.get("schema") != "27D_SOURCE_TERMINAL_V1" or not value.get("sources") is Dictionary: return {}
	# Historical extraction proofs may name canonical scripts, but new runtime
	# FIRST must bind immutable snapshots, not yesterday's changing Router hash.
	for source: String in value.sources:
		if source.begins_with("res://scripts/"): return {}
	# No shared WeakRefs, engine objects, observed receipts or serialized objects.
	if not plain(value) or not source_pass(value.sources): return {}
	for key: String in ["render", "solids", "npcs", "portals", "interactions"]:
		if not value.get(key) is Array: return {}
	return value

static func plain(value: Variant) -> bool:
	if value is Object or value is Callable or value is Signal or value is RID: return false
	if value is Dictionary:
		for key: Variant in value:
			if not plain(key) or not plain(value[key]): return false
	elif value is Array:
		for item: Variant in value:
			if not plain(item): return false
	return true

static func compile(author: Dictionary, region_id: String, terminal_inputs: Dictionary) -> Dictionary:
	if author.get("schema") != SCHEMA or not author.get("regions") is Dictionary or not author.regions.has(region_id): return fail("UNKNOWN_REGION")
	var region: Dictionary = author.regions[region_id]
	var size: Vector2 = vec(region.get("world_size_px"))
	if not size.is_finite() or size.x <= 0 or size.y <= 0: return fail("WORLD_SIZE")
	var bounds := Rect2(Vector2.ZERO, size)
	var out: Dictionary = {"ok": false, "schema": SCHEMA, "id": region_id, "size": size, "revision": int(author.get("revision", 0)), "sources": {}, "districts": {}, "floor_rects": [], "surfaces": [], "render": [], "solids": [], "npcs": [], "portals": [], "interactions": [], "solid_cells": {}, "npc_ids": {}}
	# Explicit positive ground only. A region bounding rectangle is never ground.
	for raw: Dictionary in region.get("ground", []):
		var area: Rect2 = rect(raw.get("rect"))
		if area.size.x <= 0 or area.size.y <= 0 or not bounds.encloses(area): return fail("GROUND_RECT", String(raw.get("id", "")))
		out.floor_rects.append(area)
		out.surfaces.append(raw.duplicate(true))
	if out.floor_rects.is_empty(): return fail("NO_AUTHORED_GROUND")
	for district: Dictionary in region.get("districts", []):
		var id: String = String(district.get("logical_id", ""))
		if id.is_empty() or out.districts.has(id) or not terminal_inputs.has(id): return fail("MISSING_OR_DUPLICATE_TERMINAL", id)
		var input: Dictionary = terminal_inputs[id]
		if input.get("logical_id") != id or input.get("schema") != "27D_SOURCE_TERMINAL_V1" or not plain(input): return fail("TERMINAL_ID", id)
		var old_size: Vector2 = vec(input.get("local_size_px"))
		if old_size != vec(district.get("legacy_size_px")): return fail("LEGACY_SIZE", id)
		if not input.get("sources") is Dictionary or input.sources.is_empty(): return fail("NO_TERMINAL_SOURCES", id)
		for path: String in input.sources:
			if out.sources.has(path) and out.sources[path] != input.sources[path]: return fail("SOURCE_CONFLICT", path)
			out.sources[path] = input.sources[path]
		var domain: Rect2 = rect(district.get("domain"))
		if not bounds.encloses(domain) or domain.size.x <= 0 or domain.size.y <= 0: return fail("DISTRICT_DOMAIN", id)
		for existing: Dictionary in out.districts.values():
			if domain.intersects(existing.domain): return fail("OVERLAPPING_LOGICAL_DOMAINS", id)
		out.districts[id] = {"logical_id": id, "domain": domain, "legacy_size": old_size, "legacy_version": int(district.get("legacy_version", -1)), "legacy_frame_origin": vec(district.get("legacy_frame_origin")), "save_fallback_uv": vec(district.get("save_fallback_uv")), "migrations": district.get("migrations", []).duplicate(true), "display_name": String(district.get("display_name", id))}
		out.districts[id]["legacy_version_migrations"] = district.get("legacy_version_migrations", {}).duplicate(true)
		var imported: Dictionary = _compile_district(district, input, out, region)
		if imported.get("ok") != true: return imported
	for replacement: Dictionary in region.get("pending_replacements", []):
		# Pending art never silently deletes its predecessor or its business door.
		var logical: String = String(replacement.get("logical_id", ""))
		var owner: String = String(replacement.get("owner_id", ""))
		if replacement.get("assets_ready", false) != true:
			if out.render.filter(func(row: Dictionary) -> bool: return row.logical_id == logical and row.owner_id == owner).is_empty(): return fail("PENDING_REPLACEMENT_RETIRED_ACTIVE_OWNER", owner)
	for instance: Dictionary in region.get("reused_instances", []):
		var imported: Dictionary = _compile_reused(instance, terminal_inputs, out)
		if imported.get("ok") != true: return imported
	for row: Dictionary in out.portals:
		if not safe_body(out, row.foot, Vector2(17, 12)): return fail("PORTAL_NOT_FULL_BODY_SAFE", row.key)
	for actor: Dictionary in out.npcs:
		if not safe_body(out, actor.foot + actor.get("body_offset_px", Vector2.ZERO), actor.get("half_body", Vector2(17, 15))): return fail("NPC_NOT_BODY_SAFE", String(actor.data.npc_id))
	for route: Dictionary in region.get("routes", []):
		var points: Array = route.get("points_px", [])
		if points.size() < 2: return fail("ROUTE_SCHEMA", String(route.get("id", "")))
		for index: int in range(1, points.size()):
			var a: Vector2 = vec(points[index - 1]); var b: Vector2 = vec(points[index])
			if not a.is_finite() or not b.is_finite() or not safe_segment(out, a, b, Vector2(17, 12)) or not npc_route_clear(out, a, b, Vector2(17, 12)): return fail("AUTHORED_ROUTE_BLOCKED", String(route.get("id", "")))
	out.erase("npc_ids")
	out.ok = true
	return out

static func _compile_reused(instance: Dictionary, inputs: Dictionary, out: Dictionary) -> Dictionary:
	var donor: String = String(instance.get("donor_logical_id", ""))
	var owner: String = String(instance.get("donor_owner_id", ""))
	var id: String = String(instance.get("id", ""))
	var foot: Vector2 = vec(instance.get("target_foot_px"))
	if id.is_empty() or not inputs.has(donor) or not foot.is_finite(): return fail("REUSED_DONOR_OR_FOOT", id)
	var rows: Array = inputs[donor].render.filter(func(row: Dictionary) -> bool: return row.owner_id == owner)
	if rows.size() != 1: return fail("REUSED_UNIQUE_FULL_OWNER", id)
	var logical: String = district_at(out, foot)
	if logical.is_empty() or out.render.any(func(row: Dictionary) -> bool: return row.key == logical + "/" + id): return fail("REUSED_ID_OR_DISTRICT", id)
	var row: Dictionary = rows[0].duplicate(true)
	var delta: Vector2 = foot - row.foot_px
	row.id = id; row.owner_id = id; row.key = logical + "/" + id; row.logical_id = logical
	row.position_px += delta; row.foot_px = foot
	row["reused_source_owner"] = donor + "/" + owner
	out.render.append(row)
	for solid: Dictionary in inputs[donor].solids:
		if solid.owner_id != owner: continue
		var points := PackedVector2Array()
		for point: Vector2 in solid.points_px: points.append(point + delta)
		_append_solid(out, points)
	return {"ok": true}

static func district_at(out: Dictionary, foot: Vector2) -> String:
	for id: String in out.districts:
		if out.districts[id].domain.has_point(foot): return id
	return ""

static func _compile_district(district: Dictionary, input: Dictionary, out: Dictionary, region: Dictionary) -> Dictionary:
	var id: String = String(district.logical_id)
	var assignments: Dictionary = {}
	for plot: Dictionary in district.get("plots", []):
		var delta: Vector2 = vec(plot.get("target_anchor_px")) - vec(plot.get("source_anchor_px"))
		var owners: Array = plot.get("owners", []).duplicate()
		# Source rects are fixed author selections, not a runtime best-fit search.
		if plot.has("source_rect"):
			var selection: Rect2 = rect(plot.source_rect)
			for item: Dictionary in input.render:
				var owner: String = String(item.get("owner_id", item.get("id", "")))
				if item.get("foot_px") is Vector2 and selection.has_point(item.foot_px) and owner not in owners: owners.append(owner)
		if not delta.is_finite() or owners.is_empty(): return fail("PLOT_ANCHOR_OR_OWNERS", String(plot.get("id", "")))
		for owner: String in owners:
			if assignments.has(owner): return fail("OWNER_ASSIGNED_TWICE", owner)
			assignments[owner] = {"delta": delta, "plot_id": String(plot.id)}
	var retired: Array = district.get("retired_owners", [])
	var seen: Dictionary = {}
	for row: Dictionary in input.render:
		var owner: String = String(row.get("owner_id", row.get("id", "")))
		if owner in retired: continue
		if not assignments.has(owner): return fail("UNPLACED_RENDER_OWNER", id + ":" + owner)
		if not row.get("position_px") is Vector2 or not row.get("foot_px") is Vector2 or not row.get("scale") is Vector2: return fail("TERMINAL_RENDER_TYPED", owner)
		var next: Dictionary = row.duplicate(true)
		next["key"] = id + "/" + String(row.id); next["logical_id"] = id
		next.position_px += assignments[owner].delta; next.foot_px += assignments[owner].delta
		next["plot_id"] = assignments[owner].plot_id
		out.render.append(next); seen[owner] = true
	for owner: String in assignments:
		if not seen.has(owner): return fail("UNRESOLVED_PLOT_OWNER", owner)
	for row: Dictionary in input.solids:
		var owner: String = String(row.get("owner_id", ""))
		if owner in retired: continue
		if not assignments.has(owner) or not row.get("points_px") is PackedVector2Array: return fail("UNPLACED_SOLID", owner)
		var polygon := PackedVector2Array()
		for point: Vector2 in row.points_px: polygon.append(point + assignments[owner].delta)
		if polygon.size() < 3: return fail("EMPTY_SOLID", owner)
		_append_solid(out, polygon)
	for raw: Dictionary in district.get("new_solids", []):
		var polygon := PackedVector2Array()
		for point: Variant in raw.get("points_px", []):
			if not pair(point): return fail("NEW_SOLID_FINITE")
			polygon.append(vec(point))
		if polygon.size() < 3: return fail("NEW_SOLID_EMPTY")
		_append_solid(out, polygon)
	# NPC and every door get explicit placement. No guessed nearest-safe fallback.
	var actor_places: Dictionary = district.get("actors", {})
	for row: Dictionary in input.npcs:
		var actor_id: String = String(row.get("data", {}).get("npc_id", ""))
		var group: String = String(row.get("phase_exclusive_group", ""))
		if actor_id.is_empty(): return fail("NPC_ID_OR_PLACEMENT", actor_id)
		if out.npc_ids.has(actor_id) and (group.is_empty() or out.npc_ids[actor_id] != group): return fail("DUPLICATE_NPC_WITHOUT_EXCLUSIVE_SOURCE_GROUP", actor_id)
		var next: Dictionary = row.duplicate(true)
		next["logical_id"] = id; next["foot"] = vec(actor_places[actor_id]) if actor_places.has(actor_id) else _map_station(district, row.get("foot_px"))
		next["slot_key"] = id + "/" + actor_id
		if not next.foot.is_finite(): return fail("NPC_FOOT", actor_id)
		out.npcs.append(next); out.npc_ids[actor_id] = group
	var portal_places: Dictionary = district.get("portals", {})
	for row: Dictionary in input.portals:
		var portal_id: String = String(row.get("id", ""))
		if row.get("target_scene", "") in region.get("internal_legacy_ids", []): continue
		if portal_id.is_empty(): return fail("EXTERNAL_DOOR_PLACEMENT", id)
		var next: Dictionary = row.duplicate(true)
		next["key"] = id + "/" + portal_id; next["logical_id"] = id
		next["foot"] = vec(portal_places[portal_id]) if portal_places.has(portal_id) else _map_station(district, row.get("foot_px"))
		next["legacy_source_uv"] = row.get("legacy_source_uv", Vector2(INF, INF))
		if not next.foot.is_finite() or not next.legacy_source_uv is Vector2 or not next.legacy_source_uv.is_finite(): return fail("DOOR_COORDINATE_CONTRACT", portal_id)
		out.portals.append(next)
	var interaction_places: Dictionary = district.get("interactions", {})
	for row: Dictionary in input.interactions:
		var interaction_id: String = String(row.get("id", ""))
		var next: Dictionary = row.duplicate(true)
		next["key"] = id + "/" + interaction_id; next["logical_id"] = id
		next["foot"] = vec(interaction_places[interaction_id]) if interaction_places.has(interaction_id) else _map_station(district, row.get("foot_px"))
		if not next.foot.is_finite(): return fail("INTERACTION_PLACEMENT", id + ":" + interaction_id)
		for polygon_key: String in ["city_v3_interaction_polygon_px", "interaction_polygon_px"]:
			if not next.get("data", {}).has(polygon_key): continue
			var original: Variant = next.data[polygon_key]
			if not original is PackedVector2Array or not row.get("foot_px") is Vector2: return fail("INTERACTION_POLYGON_TYPED", interaction_id)
			var moved := PackedVector2Array()
			for point: Vector2 in original: moved.append(point + next.foot - row.foot_px)
			next.data[polygon_key] = moved
		out.interactions.append(next)
	return {"ok": true}

static func _map_station(district: Dictionary, old_foot: Variant) -> Vector2:
	if not old_foot is Vector2 or not old_foot.is_finite(): return Vector2(INF, INF)
	var found: bool = false; var result := Vector2(INF, INF)
	for transform: Dictionary in district.get("station_transforms", []):
		if rect(transform.source_rect).has_point(old_foot):
			if found: return Vector2(INF, INF)
			found = true; result = old_foot + vec(transform.target_anchor_px) - vec(transform.source_anchor_px)
	return result

static func _append_solid(out: Dictionary, polygon: PackedVector2Array) -> void:
	var index: int = out.solids.size(); out.solids.append(polygon)
	var area := Rect2(polygon[0], Vector2.ZERO)
	for point: Vector2 in polygon: area = area.expand(point)
	for y: int in range(floori(area.position.y / CELL), floori(area.end.y / CELL) + 1):
		for x: int in range(floori(area.position.x / CELL), floori(area.end.x / CELL) + 1):
			var cell := Vector2i(x, y)
			if not out.solid_cells.has(cell): out.solid_cells[cell] = []
			out.solid_cells[cell].append(index)

static func ground_covers(out: Dictionary, body: Rect2) -> bool:
	# Exact rect-union coverage via y slabs, not center/corner-only acceptance.
	var cuts: Array[float] = [body.position.y, body.end.y]
	for area: Rect2 in out.floor_rects:
		if area.position.y > body.position.y and area.position.y < body.end.y: cuts.append(area.position.y)
		if area.end.y > body.position.y and area.end.y < body.end.y: cuts.append(area.end.y)
	cuts.sort()
	for index: int in range(1, cuts.size()):
		if cuts[index] == cuts[index - 1]: continue
		var y: float = (cuts[index] + cuts[index - 1]) * 0.5
		var intervals: Array[Vector2] = []
		for area: Rect2 in out.floor_rects:
			if y >= area.position.y and y <= area.end.y: intervals.append(Vector2(area.position.x, area.end.x))
		intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
		var covered: float = body.position.x
		for interval: Vector2 in intervals:
			if interval.x > covered: break
			covered = maxf(covered, interval.y)
		if covered < body.end.x: return false
	return true

static func safe_body(out: Dictionary, foot: Vector2, half: Vector2) -> bool:
	if not foot.is_finite() or not half.is_finite() or half.x <= 0 or half.y <= 0: return false
	var body := Rect2(foot - half, half * 2.0)
	if not Rect2(Vector2.ZERO, out.size).encloses(body) or not ground_covers(out, body): return false
	var body_poly := PackedVector2Array([body.position, Vector2(body.end.x, body.position.y), body.end, Vector2(body.position.x, body.end.y)])
	var checked: Dictionary = {}
	for y: int in range(floori(body.position.y / CELL), floori(body.end.y / CELL) + 1):
		for x: int in range(floori(body.position.x / CELL), floori(body.end.x / CELL) + 1):
			for index: int in out.solid_cells.get(Vector2i(x, y), []):
				if checked.has(index): continue
				checked[index] = true
				if not Geometry2D.intersect_polygons(body_poly, out.solids[index]).is_empty(): return false
	return true

static func safe_segment(out: Dictionary, a: Vector2, b: Vector2, half: Vector2) -> bool:
	# One-pixel sampled source route; Physics still owns continuous collision.
	var count: int = maxi(1, ceili(a.distance_to(b)))
	for index: int in range(count + 1):
		if not safe_body(out, a.lerp(b, float(index) / count), half): return false
	return true

static func npc_route_clear(out: Dictionary, a: Vector2, b: Vector2, half: Vector2) -> bool:
	# Include the full authored patrol swept envelope, not the current animation.
	for actor: Dictionary in out.npcs:
		var offset: Vector2 = actor.get("body_offset_px", Vector2.ZERO)
		var actor_half: Vector2 = actor.get("half_body", Vector2(17, 15))
		var origin: Vector2 = actor.foot + offset
		var axis: Vector2 = actor.data.get("patrol_axis", Vector2.RIGHT)
		var distance: float = float(actor.data.get("patrol_distance", 0.0)) if actor.data.get("movement_mode", "idle") == "patrol" else 0.0
		var sweep := Rect2(origin - axis * distance - actor_half, actor_half * 2.0)
		sweep = sweep.expand(origin + axis * distance + actor_half).expand(origin + axis * distance - actor_half)
		var expanded: Rect2 = sweep.grow_individual(half.x, half.y, half.x, half.y)
		if expanded.has_point(a) or expanded.has_point(b): return false
		var corners: Array[Vector2] = [expanded.position, Vector2(expanded.end.x, expanded.position.y), expanded.end, Vector2(expanded.position.x, expanded.end.y)]
		for index: int in range(4):
			if Geometry2D.segment_intersects_segment(a, b, corners[index], corners[(index + 1) % 4]) != null: return false
	return true
