extends RefCounted
## Six concrete interiors. Navigation belongs to a room; actor business belongs
## to its immutable original Estate/Temple source. No invented legacy owner.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Content = preload("res://build/luoyang_regions_20261027d_source01/region_content_compiler.gd")
const ROOMS := ["estate27d_living_hall", "estate27d_west_study", "estate27d_east_bedroom", "temple27d_main_hall", "temple27d_monks_room", "temple27d_sutra_room"]

static func parent_region(room_id: String) -> String:
	if room_id not in ROOMS: return ""
	return "luoyang_estate_region_27d" if room_id.begins_with("estate27d_") else "luoyang_temple_region_27d"

static func source_logical(room_id: String) -> String:
	if room_id not in ROOMS: return ""
	return "luoyang_estate_riverside_20261021ai" if room_id.begins_with("estate27d_") else "ch4_s4_ancient_temple"

static func source_scope(inputs: Dictionary, logical_ids: Array) -> Dictionary:
	var result: Dictionary = {"actors": {}, "interactions": {}, "visuals": {}}
	for logical: String in logical_ids:
		if not inputs.has(logical): return {}
		var terminal: Dictionary = inputs[logical]
		for row: Dictionary in terminal.npcs: result.actors[logical + "/" + String(row.data.npc_id)] = true
		for row: Dictionary in terminal.interactions: result.interactions[logical + "/" + String(row.id)] = true
		for row: Dictionary in terminal.render: result.visuals[logical + "/" + String(row.id)] = true
	return result

static func compile(author: Dictionary, room_id: String, inputs: Dictionary) -> Dictionary:
	var parent_id: String = parent_region(room_id)
	if parent_id.is_empty() or not author.get("regions", {}).has(parent_id): return Core.fail("ROOM_PARENT", room_id)
	var parent: Dictionary = author.regions[parent_id]
	var matches: Array = parent.get("rooms", []).filter(func(row: Dictionary) -> bool: return row.id == room_id)
	if matches.size() != 1: return Core.fail("ROOM_DEFINITION", room_id)
	var room: Dictionary = matches[0]
	if room_id == "estate27d_living_hall" and room.get("residents", []).size() != 1: return Core.fail("ROOM_ORIGINAL_STEWARD_REQUIRED", room_id)
	var logical: String = source_logical(room_id)
	if not inputs.has(logical): return Core.fail("ROOM_BUSINESS_SOURCE", logical)
	var sources: Dictionary = inputs[logical].sources.duplicate(true)
	var raw: Dictionary = room.duplicate(true)
	for door: Dictionary in raw.get("portals", []):
		var target: String = String(door.get("target_scene", ""))
		if target != parent_id: return Core.fail("ROOM_FIXED_PARENT_PORTAL", String(door.get("id", "")))
		door["target_world_size_px"] = parent.world_size_px.duplicate()
	var definition: Dictionary = parent.duplicate(true); definition.rooms = [raw]
	var materialized: Dictionary = Content.room_definition(definition, room_id, inputs, sources)
	if materialized.get("ok") != true: return materialized
	var terminal: Dictionary = materialized.inputs[room_id]
	var placements: Dictionary = {}
	var original_slots: Dictionary = {}
	for resident: Dictionary in room.get("residents", []):
		if resident.get("source_logical_id") != logical: return Core.fail("ROOM_RESIDENT_LOGICAL_SOURCE", room_id)
		var id: String = String(resident.get("npc_id", ""))
		var rows: Array = inputs[logical].npcs.filter(func(row: Dictionary) -> bool: return row.data.npc_id == id)
		if rows.size() != 1 or placements.has(id): return Core.fail("ROOM_RESIDENT_UNIQUE_ORIGINAL", id)
		var source: Dictionary = rows[0].duplicate(true)
		var foot: Vector2 = Core.vec(resident.get("foot_px"))
		if not foot.is_finite(): return Core.fail("ROOM_RESIDENT_FOOT", id)
		source.foot_px = foot
		terminal.npcs.append(source); placements[id] = resident.foot_px.duplicate()
		original_slots[id] = logical + "/" + id
	materialized.region.districts[0].actors = placements
	materialized.region.districts[0].legacy_version_migrations = {}
	materialized.region["default_legacy_uv"] = {room_id: room.get("safe_spawn_uv", [.5, .875])}
	materialized.region["portal_region_return_feet"] = {room_id: {}}
	for door: Dictionary in raw.get("portals", []): materialized.region.portal_region_return_feet[room_id][door.id] = door.source_spawn_px.duplicate()
	var local_author: Dictionary = author.duplicate(true)
	local_author.regions[room_id] = materialized.region
	var compiled: Dictionary = Content.compile(local_author, room_id, materialized.inputs)
	if compiled.get("ok") != true: return compiled
	# Core validated the physical room bodies/routes with the resident NPCs. The
	# post-step only restores their real logical business owner and original key.
	for actor: Dictionary in compiled.npcs:
		actor.logical_id = logical; actor.slot_key = original_slots[actor.data.npc_id]
	compiled["source_context_ids"] = [logical]
	compiled["navigation_kind"] = "AUTHORED_INTERIOR"
	compiled["room_source_logical_id"] = logical
	compiled["physical_phase_scope"] = source_scope(inputs, [logical])
	compiled["room_enclosure"] = room.enclosure.duplicate(true)
	var wall_material: Dictionary = author.get("room_wall_material", {})
	if not wall_material.get("source_sha256") is Dictionary or not wall_material.source_sha256.has(wall_material.get("texture")) or not wall_material.source_sha256.has(wall_material.get("shader")): return Core.fail("ROOM_WALL_MATERIAL_SOURCE")
	compiled.sources.merge(wall_material.source_sha256, true)
	compiled["room_wall_material"] = wall_material.duplicate(true)
	compiled["room_display_name"] = String(room.get("display_name", room_id))
	for door: Dictionary in compiled.portals:
		var authored: Array = raw.portals.filter(func(row: Dictionary) -> bool: return row.id == door.id)
		if authored.size() != 1: return Core.fail("ROOM_PORTAL_UNIQUE", door.id)
		door.data["region27d_target"] = {"region_id": parent_id, "logical_id": logical, "foot_px": authored[0].target_foot_px.duplicate()}
	return compiled
