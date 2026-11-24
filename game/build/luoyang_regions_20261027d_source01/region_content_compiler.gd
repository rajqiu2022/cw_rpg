extends RefCounted
## The batch's concrete data adapters: six rooms, declared door children and
## admitted buildings. The core keeps ownership/collision/route validation.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")

static func compile(author: Dictionary, region_id: String, inputs: Dictionary) -> Dictionary:
	var local_author: Dictionary = author.duplicate(true)
	var local_inputs: Dictionary = inputs.duplicate(true)
	if not local_author.get("regions", {}).has(region_id): return Core.fail("CONTENT_REGION_ID")
	var definition: Dictionary = local_author.regions[region_id]
	var material: Dictionary = _materials(author, definition)
	if material.get("ok") != true: return material
	var buildings: Dictionary = _admitted_buildings(definition, local_inputs)
	if buildings.get("ok") != true: return buildings
	var compiled: Dictionary = Core.compile(local_author, region_id, local_inputs)
	if compiled.get("ok") != true: return compiled
	compiled.sources.merge(material.sources, true)
	for override: Dictionary in definition.get("interaction_geometry_overrides", []):
		var key: String = String(override.get("logical_id", "")) + "/" + String(override.get("id", ""))
		var selected: Array = compiled.interactions.filter(func(row: Dictionary) -> bool: return row.key == key)
		if selected.size() != 1: return Core.fail("CONTENT_INTERACTION_OVERRIDE_ID", key)
		var points := PackedVector2Array()
		for raw: Variant in override.get("city_v3_interaction_polygon_px", []):
			var point: Vector2 = Core.vec(raw)
			if not point.is_finite(): return Core.fail("CONTENT_INTERACTION_OVERRIDE_POINT", key)
			points.append(point)
		var size: Vector2 = Core.vec(override.get("source_shape_size_px"))
		if points.size() != 4 or size.x <= 0 or size.y <= 0: return Core.fail("CONTENT_INTERACTION_OVERRIDE_SHAPE", key)
		selected[0].data["city_v3_interaction_polygon_px"] = points
		if selected[0].data.has("interaction_polygon_px"): selected[0].data.interaction_polygon_px = points.duplicate()
		selected[0]["size_px"] = size
	var migration_check: Dictionary = _migration_partitions(compiled)
	if migration_check.get("ok") != true: return migration_check
	for door: Dictionary in compiled.portals:
		var return_table: Dictionary = definition.get("portal_region_return_feet", {}).get(door.logical_id, {})
		if not return_table.has(door.id): return Core.fail("CONTENT_DOOR_RETURN_ANCHOR", door.key)
		var foot: Vector2 = Core.vec(return_table[door.id])
		if not Core.safe_body(compiled, foot, Vector2(17, 12)) or not Core.npc_route_clear(compiled, foot, foot, Vector2(17, 12)): return Core.fail("CONTENT_DOOR_RETURN_BODY", door.key)
		door["return_foot"] = foot
	# Every reused donor is an explicit source dependency, including cross-region
	# furniture. It is not enough that its image was once present in another map.
	for instance: Dictionary in definition.get("reused_instances", []):
		var source: Dictionary = local_inputs.get(String(instance.get("donor_logical_id", "")), {})
		if source.is_empty(): return Core.fail("CONTENT_DONOR_SOURCE")
		compiled.sources.merge(source.sources, true)
	for child: Dictionary in definition.get("auxiliary_render_children", []):
		var key: String = String(child.get("parent_key", ""))
		var parents: Array = compiled.render.filter(func(row: Dictionary) -> bool: return row.key == key)
		if parents.size() != 1: return Core.fail("CONTENT_DOOR_PARENT", key)
		var row: Dictionary = child.duplicate(true)
		row["local_position_px"] = Core.vec(child.get("local_position_px"))
		row["texture_size_px"] = Core.vec(child.get("texture_size_px"))
		var atlas: Variant = child.get("atlas_region")
		# This batch's fixed Atlas descriptors use [x,y,width,height], whereas
		# authored floor rectangles use [[x,y],[width,height]]. Keep Core strict.
		if not atlas is Array or atlas.size() != 4 or not Core.pair([atlas[0], atlas[1]]) or not Core.pair([atlas[2], atlas[3]]): return Core.fail("CONTENT_DOOR_ATLAS_RECT", key)
		row["atlas_region"] = Rect2(Vector2(atlas[0], atlas[1]), Vector2(atlas[2], atlas[3]))
		if not row.local_position_px.is_finite() or not row.texture_size_px.is_finite() or row.get("relative_z") != -1 or row.get("inherit_parent_material") != true: return Core.fail("CONTENT_DOOR_DESCRIPTOR", key)
		if not child.get("source_sha256") is Dictionary or child.source_sha256.is_empty() or not child.source_sha256.has(child.get("texture")) or not child.source_sha256.has(child.get("atlas_source")): return Core.fail("CONTENT_DOOR_SOURCES", key)
		compiled.sources.merge(child.source_sha256, true)
		if not parents[0].has("auxiliary_children"): parents[0]["auxiliary_children"] = []
		parents[0].auxiliary_children.append(row)
	return compiled

static func _migration_partitions(compiled: Dictionary) -> Dictionary:
	for logical: String in compiled.districts:
		var district: Dictionary = compiled.districts[logical]
		var variants: Array = [district.migrations]
		variants.append_array(district.get("legacy_version_migrations", {}).values())
		for rows: Array in variants:
			# Room-local version 1 may use an explicit identity frame; legacy city
			# revisions always declare complete bounded partitions in this batch.
			if rows.is_empty(): continue
			var areas: Array = []
			for row: Dictionary in rows:
				var area: Rect2 = Core.rect(row.get("old_rect"))
				if area.size.x <= 0 or area.size.y <= 0 or not Rect2(Vector2.ZERO, district.legacy_size).encloses(area): return Core.fail("CONTENT_OLD_MIGRATION_BOUNDS", logical)
				for previous: Rect2 in areas:
					if previous.intersects(area): return Core.fail("CONTENT_OLD_MIGRATION_OVERLAP", logical)
				areas.append(area)
				var foot: Vector2 = Core.vec(row.get("target_foot_px"))
				if Core.district_at(compiled, foot) != logical or not Core.safe_body(compiled, foot, Vector2(17, 12)) or not Core.npc_route_clear(compiled, foot, foot, Vector2(17, 12)): return Core.fail("CONTENT_OLD_MIGRATION_TARGET", logical + ":" + String(row.get("reason", "")))
			if not Core.ground_covers({"floor_rects": areas}, Rect2(Vector2.ZERO, district.legacy_size)): return Core.fail("CONTENT_OLD_MIGRATION_GAP", logical)
	return {"ok": true}

static func _materials(author: Dictionary, definition: Dictionary) -> Dictionary:
	var sources: Dictionary = {}
	for floor: Dictionary in definition.get("ground", []):
		var role: String = String(floor.get("texture_role", ""))
		var texture: Dictionary = author.get("texture_roles", {}).get(role, {})
		if texture.is_empty() or not texture.get("source_sha256") is Dictionary or not texture.source_sha256.has(texture.get("path")): return Core.fail("CONTENT_FLOOR_ROLE", role)
		floor["texture"] = texture.path
		sources.merge(texture.source_sha256, true)
	return {"ok": true, "sources": sources}

static func _admitted_buildings(definition: Dictionary, inputs: Dictionary) -> Dictionary:
	for building: Dictionary in definition.get("pending_buildings", []):
		if building.get("adoption_enabled", false) != true: continue
		var asset: Dictionary = building.get("asset_binding", {})
		var logical: String = String(building.get("logical_id", ""))
		var id: String = String(building.get("id", ""))
		var foot: Vector2 = Core.vec(building.get("target_foot_px"))
		var dimensions: Vector2 = Core.vec(asset.get("native_size_px"))
		var anchor: Vector2 = Core.vec(asset.get("native_ground_anchor_px"))
		var ratio: float = float(asset.get("world_scale", -1))
		if not inputs.has(logical) or id.is_empty() or not foot.is_finite() or not dimensions.is_finite() or not anchor.is_finite() or ratio <= 0: return Core.fail("CONTENT_BUILDING_ASSET_BINDING", id)
		if not asset.get("source_sha256") is Dictionary or not asset.source_sha256.has(asset.get("texture")): return Core.fail("CONTENT_BUILDING_SOURCE", id)
		var terminal: Dictionary = inputs[logical]
		if terminal.render.any(func(row: Dictionary) -> bool: return row.id == id): return Core.fail("CONTENT_BUILDING_DUPLICATE", id)
		var row: Dictionary = {"id": id, "owner_id": id, "texture": asset.texture, "texture_size_px": dimensions, "position_px": foot - anchor * ratio, "foot_px": foot, "scale": Vector2.ONE * ratio, "centered": false, "source_row": {"sort_by_feet": true}}
		terminal.render.append(row); terminal.sources.merge(asset.source_sha256, true)
		var ordinal: int = 0
		for raw: Array in asset.get("native_ground_polygons_px", []):
			var points := PackedVector2Array()
			for point: Variant in raw:
				var value: Vector2 = Core.vec(point)
				if not value.is_finite(): return Core.fail("CONTENT_BUILDING_POLYGON", id)
				points.append(foot + (value - anchor) * ratio)
			if points.size() < 3: return Core.fail("CONTENT_BUILDING_BODY_REQUIRED", id)
			terminal.solids.append({"id": id + "/" + str(ordinal), "owner_id": id, "points_px": points}); ordinal += 1
		if ordinal == 0: return Core.fail("CONTENT_BUILDING_BODY_REQUIRED", id)
		var districts: Array = definition.districts.filter(func(district: Dictionary) -> bool: return district.logical_id == logical)
		if districts.size() != 1: return Core.fail("CONTENT_BUILDING_LOGICAL_DISTRICT", id)
		var district: Dictionary = districts[0]
		var retired: String = String(building.get("replaces_legacy_owner", ""))
		if not retired.is_empty():
			if retired not in district.retired_owners: district.retired_owners.append(retired)
			var plots: Array = []
			for plot: Dictionary in district.plots:
				plot.owners.erase(retired)
				if not plot.owners.is_empty(): plots.append(plot)
			district.plots = plots
		district.plots.append({"id": "new_" + id, "owners": [id], "source_anchor_px": [0, 0], "target_anchor_px": [0, 0]})
	return {"ok": true}

static func room_definition(parent: Dictionary, room_id: String, inputs: Dictionary, sources: Dictionary) -> Dictionary:
	var rooms: Array = parent.get("rooms", []).filter(func(room: Dictionary) -> bool: return room.id == room_id)
	if rooms.size() != 1: return Core.fail("CONTENT_ROOM_ID", room_id)
	var room: Dictionary = rooms[0]
	var size: Vector2 = Core.vec(room.get("world_size_px"))
	if not size.is_finite(): return Core.fail("CONTENT_ROOM_SIZE", room_id)
	var portals: Array = []
	for door: Dictionary in room.get("portals", []):
		var foot: Vector2 = Core.vec(door.get("foot_px"))
		var spawn: Vector2 = Core.vec(door.get("source_spawn_px"))
		var target_size: Vector2 = Core.vec(door.get("target_world_size_px"))
		var target_foot: Vector2 = Core.vec(door.get("target_foot_px"))
		if not foot.is_finite() or not spawn.is_finite() or not target_size.is_finite() or not target_foot.is_finite(): return Core.fail("CONTENT_ROOM_DOOR_LINK", String(door.get("id", "")))
		portals.append({"id": door.id, "foot_px": foot, "legacy_source_uv": spawn / size, "size_px": Core.vec(door.get("size_px")), "target_scene": door.target_scene, "data": {"id": door.id, "pos": foot / size, "source_spawn_pos": spawn / size, "size": Core.vec(door.size_px) / size, "auto_trigger": false, "target_scene": door.target_scene, "target_pos": target_foot / target_size, "label": door.label}})
	var terminal: Dictionary = {"schema": "27D_SOURCE_TERMINAL_V1", "logical_id": room_id, "local_size_px": [size.x, size.y], "sources": sources.duplicate(true), "render": [], "solids": [], "npcs": [], "interactions": [], "portals": portals}
	var door_positions: Dictionary = {}
	for door: Dictionary in portals: door_positions[door.id] = [door.foot_px.x, door.foot_px.y]
	var solids: Array = []; var ordinal: int = 0
	for polygon: Array in room.get("enclosure", {}).get("wall_ground_polygons_px", []):
		solids.append({"id": "room_boundary_" + str(ordinal), "points_px": polygon.duplicate(true)}); ordinal += 1
	var definition: Dictionary = {"world_size_px": room.world_size_px.duplicate(), "ground": room.ground.duplicate(true), "routes": room.get("routes", []).duplicate(true), "reused_instances": room.get("furniture_instances", []).duplicate(true), "districts": [{"logical_id": room_id, "domain": [[0, 0], [size.x, size.y]], "legacy_size_px": [size.x, size.y], "legacy_version": 1, "legacy_frame_origin": [0, 0], "save_fallback_uv": room.get("safe_spawn_uv", [.5, .875]), "migrations": [], "plots": [], "retired_owners": [], "actors": {}, "portals": door_positions, "interactions": {}, "station_transforms": [], "new_solids": solids}]}
	var joined: Dictionary = inputs.duplicate(true); joined[room_id] = terminal
	return {"ok": true, "region": definition, "inputs": joined, "requires_authored_residents": room.get("npcs", []).is_empty()}
