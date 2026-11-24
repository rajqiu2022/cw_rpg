extends RefCounted
## Only the three newly admitted buildings. The successful Civic component is
## inherited, not recompiled, and the other eight components are never loaded.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")

func run(_tree_context: SceneTree, input: Dictionary) -> Dictionary:
	var result: Dictionary = {"passed": false, "errors": [], "Field_instances": 0, "legacy_owner_prepare_calls": 0, "PNG_pixel_decodes": 0, "canonical_writes": 0, "inherited_components": 9}
	var started: int = Time.get_ticks_msec()
	if input.get("root_authorized") != true or not Core.source_pass(input.module_sources): return _fail(result, "AUTHORIZATION_OR_MODULE_SOURCE")
	var binding: Dictionary = input.parent_compiled
	var parent_bytes: PackedByteArray = FileAccess.get_file_as_bytes(binding.path)
	if parent_bytes.size() != int(binding.bytes) or FileAccess.get_sha256(binding.path) != binding.sha256: return _fail(result, "PARENT_COMPILED_SOURCE")
	var parent: Variant = bytes_to_var(parent_bytes)
	if not parent is Dictionary or not Core.plain(parent) or parent.get("ok") != true or parent.get("id") != "luoyang_civic_market_region_27d": return _fail(result, "PARENT_COMPILED_ID")
	var author: Dictionary = Core.read_json(input.author.path, input.author.sha256)
	var original_author: Dictionary = Core.read_json(input.parent_author.path, input.parent_author.sha256)
	if author.is_empty() or original_author.is_empty(): return _fail(result, "FIXED_AUTHOR")
	var definition: Dictionary = author.regions[parent.id]
	var old_definition: Dictionary = original_author.regions[parent.id]
	var terminals: Dictionary = {}
	for district: Dictionary in old_definition.districts:
		var logical: String = district.logical_id
		terminals[logical] = _inherited_terminal(original_author.terminal_bindings[logical])
		if terminals[logical].is_empty(): return _fail(result, "FIXED_TERMINAL:" + logical)
	# Recover the exact parallel solid ownership sequence without rasterizing,
	# re-running routes, or projecting any legacy actors or resources.
	var ownership: Dictionary = _solid_ownership(old_definition, terminals, parent)
	if ownership.get("ok") != true: return _fail(result, ownership.error)
	var retired: Array = ["ch4_s3_luoyang_market/shop", "ch4_s3_luoyang_market/north_market_front"]
	var out: Dictionary = parent.duplicate(true)
	var removed_render: Array = []
	var retained_render: Array = []
	for index: int in range(out.render.size()):
		var row: Dictionary = out.render[index]
		if String(row.logical_id) + "/" + String(row.owner_id) in retired: removed_render.append({"index": index, "row": row.duplicate(true)})
		else: retained_render.append(row)
	if removed_render.size() != 2: return _fail(result, "EXACT_TWO_RETIRED_FRONTS")
	out.render = retained_render
	var removed_solids: Array = []
	var retained_solids: Array = []
	for index: int in range(out.solids.size()):
		if ownership.owners[index] in retired: removed_solids.append({"index": index, "polygon": out.solids[index].duplicate()})
		else: retained_solids.append(out.solids[index])
	if removed_solids.is_empty(): return _fail(result, "RETIRED_GROUND_BODY_REQUIRED")
	out.solids = retained_solids
	var new_render_keys: Array = []
	var new_polygons: Array = []
	var new_bounds: Array[Rect2] = []
	var checks: Array = []
	for building: Dictionary in definition.pending_buildings:
		if building.get("adoption_enabled") != true: return _fail(result, "ALL_THREE_ASSETS_REQUIRED")
		var asset: Dictionary = building.asset_binding
		if not Core.source_pass(asset.source_sha256) or asset.source_sha256.size() != 3: return _fail(result, "BUILDING_MEDIA_TUPLE:" + building.id)
		var size: Vector2 = Core.vec(asset.native_size_px)
		var anchor: Vector2 = Core.vec(asset.native_ground_anchor_px)
		var foot: Vector2 = Core.vec(building.target_foot_px)
		var scale: float = float(asset.world_scale)
		if not size.is_finite() or not anchor.is_finite() or not foot.is_finite() or scale <= 0: return _fail(result, "BUILDING_TRANSFORM")
		var complete: Rect2 = Core.rect(asset.complete_alpha_rect_px)
		var lot: Rect2 = Core.rect(building.lot)
		var world_alpha := Rect2(foot + (complete.position - anchor) * scale, complete.size * scale)
		if not lot.encloses(world_alpha): return _fail(result, "COMPLETE_A1_OUTSIDE_AUTHORED_LOT:" + building.id)
		var body: PackedVector2Array = _world_polygon(asset.native_closed_ground_polygon_px, anchor, foot, scale)
		var channel: PackedVector2Array = _world_polygon(asset.native_front_walk_channel_px, anchor, foot, scale)
		if body.size() < 3 or channel.size() < 3: return _fail(result, "BUILDING_TRUE_BASE_OR_DOOR_CHANNEL")
		var pieces: Array[PackedVector2Array] = Geometry2D.clip_polygons(body, channel)
		if pieces.is_empty() or pieces.size() > 3: return _fail(result, "BUILDING_CLOSED_MINUS_DOOR")
		for polygon: PackedVector2Array in pieces:
			if polygon.size() < 3 or not Rect2(Vector2.ZERO, out.size).encloses(_bounds(polygon)): return _fail(result, "NEW_BASE_BOUNDS")
			for old_polygon: PackedVector2Array in retained_solids:
				if not Geometry2D.intersect_polygons(polygon, old_polygon).is_empty(): return _fail(result, "NEW_BASE_INTERSECTS_RETAINED_BODY:" + building.id)
			for prior: PackedVector2Array in new_polygons:
				if not Geometry2D.intersect_polygons(polygon, prior).is_empty(): return _fail(result, "NEW_BUILDING_BODY_OVERLAP")
			new_polygons.append(polygon); new_bounds.append(_bounds(polygon).grow(32))
		var key: String = String(building.logical_id) + "/" + String(building.id)
		if out.render.any(func(row: Dictionary) -> bool: return row.key == key): return _fail(result, "NEW_BUILDING_ID_DUPLICATE")
		out.render.append({"id": building.id, "owner_id": building.id, "key": key, "logical_id": building.logical_id, "texture": asset.texture, "texture_size_px": size, "position_px": foot - anchor * scale, "foot_px": foot, "scale": Vector2.ONE * scale, "centered": false, "plot_id": "new_" + String(building.id), "source_row": {"sort_by_feet": true}})
		new_render_keys.append(key); out.sources.merge(asset.source_sha256, true)
		checks.append({"id": building.id, "complete_alpha_in_lot": true, "solid_pieces": pieces.size(), "world_alpha": [world_alpha.position, world_alpha.size]})
	if new_render_keys.size() != 3: return _fail(result, "EXACT_THREE_BUILDINGS")
	# Reindex the inherited polygons; this is not a fresh geometry publication.
	out.solids = []; out.solid_cells = {}
	for polygon: PackedVector2Array in retained_solids: Core._append_solid(out, polygon)
	for polygon: PackedVector2Array in new_polygons: Core._append_solid(out, polygon)
	var checked_routes: Array = []
	for route: Dictionary in input.new_door_routes:
		if not _route(out, route.points_px): return _fail(result, "NEW_DOOR_ROUTE_BLOCKED:" + String(route.id))
		checked_routes.append(route.id)
	# Old successful paths are inherited unless their body sweep meets a new base.
	for route: Dictionary in old_definition.routes:
		if not _affected_route(route.points_px, new_bounds): continue
		if not _route(out, route.points_px): return _fail(result, "AFFECTED_OLD_ROUTE_BLOCKED:" + String(route.id))
		checked_routes.append(route.id)
	for door: Dictionary in out.portals:
		for point: Vector2 in [door.foot, door.return_foot]:
			if _affected(point, new_bounds) and (not Core.safe_body(out, point, Vector2(17, 12)) or not Core.npc_route_clear(out, point, point, Vector2(17, 12))): return _fail(result, "AFFECTED_ORIGINAL_DOOR:" + String(door.key))
	for actor: Dictionary in out.npcs:
		var offset: Vector2 = actor.get("body_offset_px", Vector2.ZERO)
		var half: Vector2 = actor.get("half_body", Vector2(17, 15))
		var origin: Vector2 = actor.foot + offset
		var axis: Vector2 = actor.data.get("patrol_axis", Vector2.RIGHT)
		var distance: float = float(actor.data.get("patrol_distance", 0)) if actor.data.get("movement_mode", "idle") == "patrol" else 0.0
		if _affected_route([origin - axis * distance, origin + axis * distance], new_bounds) and not Core.safe_segment(out, origin - axis * distance, origin + axis * distance, half): return _fail(result, "AFFECTED_ACTOR_BODY:" + String(actor.data.npc_id))
	for logical: String in out.districts:
		var variants: Array = [out.districts[logical].migrations] + out.districts[logical].get("legacy_version_migrations", {}).values()
		for migrations: Array in variants:
			for migration: Dictionary in migrations:
				var point: Vector2 = Core.vec(migration.target_foot_px)
				if _affected(point, new_bounds) and not Core.safe_body(out, point, Vector2(17, 12)): return _fail(result, "AFFECTED_MIGRATION_ANCHOR:" + logical)
	# Exactly four mutable compiled keys. All logical actors, Task areas, portals,
	# positive ground, services and old room targets remain byte-identical.
	var unmodified_before: Dictionary = parent.duplicate(true)
	var unmodified_after: Dictionary = out.duplicate(true)
	for key: String in ["render", "solids", "solid_cells", "sources"]: unmodified_before.erase(key); unmodified_after.erase(key)
	if var_to_bytes(unmodified_before) != var_to_bytes(unmodified_after): return _fail(result, "UNRELATED_COMPILED_FIELD_CHANGED")
	var inverse: Dictionary = out.duplicate(true)
	inverse.render = inverse.render.filter(func(row: Dictionary) -> bool: return row.key not in new_render_keys)
	for row: Dictionary in removed_render: inverse.render.insert(row.index, row.row)
	inverse.solids.resize(retained_solids.size())
	for row: Dictionary in removed_solids: inverse.solids.insert(row.index, row.polygon)
	inverse.solid_cells = parent.solid_cells.duplicate(true); inverse.sources = parent.sources.duplicate(true)
	if var_to_bytes(inverse) != parent_bytes: return _fail(result, "COMPLETE_TYPED_INVERSE")
	if not Core.source_pass(input.module_sources) or FileAccess.get_sha256(binding.path) != binding.sha256: return _fail(result, "SOURCE_FINAL")
	for building: Dictionary in definition.pending_buildings:
		if not Core.source_pass(building.asset_binding.source_sha256): return _fail(result, "NEW_MEDIA_SOURCE_FINAL")
	var directory: String = String(input.output_root) + "/" + str(OS.get_process_id())
	if DirAccess.dir_exists_absolute(directory) or DirAccess.make_dir_recursive_absolute(directory) != OK: return _fail(result, "NEW_OUTPUT_DIRECTORY")
	var path: String = directory + "/civic_region.bin"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return _fail(result, "OUTPUT")
	var raw: PackedByteArray = var_to_bytes(out); file.store_buffer(raw); file.close()
	result["compiled"] = {"path": path, "sha256": FileAccess.get_sha256(path), "bytes": raw.size()}
	result["counts"] = {"render": out.render.size(), "solids": out.solids.size(), "actors": out.npcs.size(), "portals": out.portals.size(), "interactions": out.interactions.size()}
	result["checks"] = checks; result["checked_routes"] = checked_routes
	result["whole_typed_inverse"] = true; result["only_four_compiled_keys_changed"] = true
	result["removed_render"] = removed_render.size(); result["removed_solids"] = removed_solids.size(); result["added_render"] = 3; result["added_solids"] = new_polygons.size()
	result["passed"] = true; result["elapsed_ms"] = Time.get_ticks_msec() - started
	file = FileAccess.open(directory + "/result.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t") + "\n"); file.close()
	return result

static func _fail(result: Dictionary, reason: String) -> Dictionary:
	result.errors.append(reason)
	return result

static func _inherited_terminal(binding: Dictionary) -> Dictionary:
	# These bundles already passed the Root cold extraction. Bind their exact
	# bytes, not another read of every inherited bitmap in the legacy inventory.
	if FileAccess.get_sha256(binding.path) != binding.sha256: return {}
	var raw: PackedByteArray = FileAccess.get_file_as_bytes(binding.path)
	if raw.size() != int(binding.bytes): return {}
	var value: Variant = bytes_to_var(raw)
	return value if value is Dictionary and Core.plain(value) and value.get("schema") == "27D_SOURCE_TERMINAL_V1" else {}

static func _bounds(points: PackedVector2Array) -> Rect2:
	var area := Rect2(points[0], Vector2.ZERO)
	for point: Vector2 in points: area = area.expand(point)
	return area

static func _world_polygon(raw: Array, anchor: Vector2, foot: Vector2, scale: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for value: Variant in raw:
		var point: Vector2 = Core.vec(value)
		if not point.is_finite(): return PackedVector2Array()
		points.append(foot + (point - anchor) * scale)
	return points

static func _route(out: Dictionary, points: Array) -> bool:
	for index: int in range(1, points.size()):
		var a: Vector2 = points[index - 1] if points[index - 1] is Vector2 else Core.vec(points[index - 1])
		var b: Vector2 = points[index] if points[index] is Vector2 else Core.vec(points[index])
		if not Core.safe_segment(out, a, b, Vector2(17, 12)) or not Core.npc_route_clear(out, a, b, Vector2(17, 12)): return false
	return true

static func _affected(point: Vector2, areas: Array[Rect2]) -> bool:
	for area: Rect2 in areas:
		if area.has_point(point): return true
	return false

static func _affected_route(points: Array, areas: Array[Rect2]) -> bool:
	for index: int in range(1, points.size()):
		var a: Vector2 = points[index - 1] if points[index - 1] is Vector2 else Core.vec(points[index - 1])
		var b: Vector2 = points[index] if points[index] is Vector2 else Core.vec(points[index])
		for area: Rect2 in areas:
			if _bounds(PackedVector2Array([a, b])).grow(18).intersects(area): return true
	return false

static func _solid_ownership(definition: Dictionary, terminals: Dictionary, compiled: Dictionary) -> Dictionary:
	var owners: Array = []; var expected: Array = []
	for district: Dictionary in definition.districts:
		var terminal: Dictionary = terminals[district.logical_id]
		var assignments: Dictionary = {}
		for plot: Dictionary in district.plots:
			var delta: Vector2 = Core.vec(plot.target_anchor_px) - Core.vec(plot.source_anchor_px)
			for owner: String in plot.owners: assignments[owner] = delta
		for solid: Dictionary in terminal.solids:
			if solid.owner_id in district.retired_owners: continue
			if not assignments.has(solid.owner_id): return {"ok": false, "error": "PARENT_OWNER_ASSIGNMENT"}
			var points := PackedVector2Array()
			for point: Vector2 in solid.points_px: points.append(point + assignments[solid.owner_id])
			expected.append(points); owners.append(String(district.logical_id) + "/" + String(solid.owner_id))
		for row: Dictionary in district.get("new_solids", []):
			var points := PackedVector2Array()
			for point: Variant in row.points_px: points.append(Core.vec(point))
			expected.append(points); owners.append(String(district.logical_id) + "/new/" + String(row.id))
	for instance: Dictionary in definition.get("reused_instances", []):
		var terminal: Dictionary = terminals.get(instance.donor_logical_id, {})
		if terminal.is_empty(): return {"ok": false, "error": "PARENT_REUSED_TERMINAL"}
		var donors: Array = terminal.render.filter(func(row: Dictionary) -> bool: return row.owner_id == instance.donor_owner_id)
		if donors.size() != 1: return {"ok": false, "error": "PARENT_REUSED_OWNER"}
		var delta: Vector2 = Core.vec(instance.target_foot_px) - donors[0].foot_px
		for solid: Dictionary in terminal.solids:
			if solid.owner_id != instance.donor_owner_id: continue
			var points := PackedVector2Array()
			for point: Vector2 in solid.points_px: points.append(point + delta)
			expected.append(points); owners.append("reused/" + String(instance.id))
	if var_to_bytes(expected) != var_to_bytes(compiled.solids): return {"ok": false, "error": "COMPLETE_PARENT_SOLID_TYPED_SEQUENCE"}
	return {"ok": true, "owners": owners}
