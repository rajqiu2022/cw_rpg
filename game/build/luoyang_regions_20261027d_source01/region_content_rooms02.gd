extends RefCounted
## This batch's courtyard-to-room doors and explicit resident handoff.
## Original terminal bins and old Scene/Layout objects are never changed.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Content = preload("res://build/luoyang_regions_20261027d_source01/region_content_compiler.gd")
const Rooms = preload("res://build/luoyang_regions_20261027d_source01/region_room_compiler.gd")
const Visuals = preload("res://build/luoyang_regions_20261027d_source01/region_actor_visuals.gd")

static func compile(author: Dictionary, region_id: String, inputs: Dictionary) -> Dictionary:
	if region_id not in ["luoyang_estate_region_27d", "luoyang_temple_region_27d"]: return Content.compile(author, region_id, inputs)
	var local_author: Dictionary = author.duplicate(true)
	var local_inputs: Dictionary = inputs.duplicate(true)
	var definition: Dictionary = local_author.regions[region_id]
	if definition.districts.size() != 1: return Core.fail("COURTYARD_SINGLE_LOGICAL_SOURCE")
	var district: Dictionary = definition.districts[0]
	var logical: String = district.logical_id
	var terminal: Dictionary = local_inputs.get(logical, {})
	if terminal.is_empty(): return Core.fail("COURTYARD_ORIGINAL_TERMINAL")
	var retired: Array = definition.get("retired_portal_ids", [])
	for id: String in retired:
		var originals: Array = terminal.portals.filter(func(row: Dictionary) -> bool: return row.id == id)
		if originals.size() != 1: return Core.fail("COURTYARD_REPLACED_PORTAL_UNIQUE", id)
	terminal.portals = terminal.portals.filter(func(row: Dictionary) -> bool: return row.id not in retired)
	var target_table: Dictionary = {}
	if not definition.has("portal_region_return_feet"): definition["portal_region_return_feet"] = {}
	if not definition.portal_region_return_feet.has(logical): definition.portal_region_return_feet[logical] = {}
	for door: Dictionary in definition.get("exterior_room_doors", []):
		var id: String = String(door.get("id", ""))
		var target: String = String(door.get("target_scene", ""))
		var matches: Array = definition.get("rooms", []).filter(func(room: Dictionary) -> bool: return room.id == target)
		if matches.size() != 1 or Rooms.parent_region(target) != region_id or target_table.has(id): return Core.fail("COURTYARD_REAL_ROOM_TARGET", id)
		var foot: Vector2 = Core.vec(door.get("foot_px"))
		var spawn: Vector2 = Core.vec(door.get("source_spawn_px"))
		var size: Vector2 = Core.vec(door.get("size_px"))
		var target_foot: Vector2 = Core.vec(door.get("target_foot_px"))
		var target_size: Vector2 = Core.vec(matches[0].world_size_px)
		var fallback: Vector2 = Core.vec(district.get("save_fallback_uv"))
		if not foot.is_finite() or not spawn.is_finite() or not target_foot.is_finite() or not target_size.is_finite() or not fallback.is_finite() or size.x <= 0 or size.y <= 0: return Core.fail("COURTYARD_ROOM_COORDINATES", id)
		# The new world foot never occupies an old logical UV save slot.
		var row: Dictionary = {"id": id, "foot_px": foot, "legacy_source_uv": fallback, "size_px": size, "target_scene": target, "data": {"id": id, "pos": foot / Core.vec(definition.world_size_px), "size": size / Core.vec(definition.world_size_px), "source_spawn_pos": spawn / Core.vec(definition.world_size_px), "auto_trigger": false, "target_scene": target, "target_pos": target_foot / target_size, "label": door.label, "region27d_target": {"region_id": target, "logical_id": target, "foot_px": door.target_foot_px.duplicate()}}}
		terminal.portals.append(row); district.portals[id] = door.foot_px.duplicate()
		definition.portal_region_return_feet[logical][id] = door.source_spawn_px.duplicate()
		target_table[id] = true
	var moved: Dictionary = {}
	for transfer: Dictionary in definition.get("resident_transfers", []):
		var id: String = String(transfer.get("npc_id", ""))
		var target: String = String(transfer.get("target_room", ""))
		if transfer.get("source_logical_id") != logical or moved.has(id): return Core.fail("COURTYARD_RESIDENT_SOURCE", id)
		var originals: Array = terminal.npcs.filter(func(row: Dictionary) -> bool: return row.data.npc_id == id)
		var rooms: Array = definition.get("rooms", []).filter(func(room: Dictionary) -> bool: return room.id == target)
		if originals.size() != 1 or rooms.size() != 1: return Core.fail("COURTYARD_RESIDENT_TARGET", id)
		var residents: Array = rooms[0].get("residents", []).filter(func(row: Dictionary) -> bool: return row.npc_id == id and row.source_logical_id == logical)
		if residents.size() != 1: return Core.fail("COURTYARD_RESIDENT_RECIPROCAL", id)
		terminal.npcs = terminal.npcs.filter(func(row: Dictionary) -> bool: return row.data.npc_id != id)
		moved[id] = true
	var compiled: Dictionary = Content.compile(local_author, region_id, local_inputs)
	if compiled.get("ok") != true: return compiled
	compiled["physical_phase_scope"] = Rooms.source_scope(inputs, [logical])
	compiled["source_context_ids"] = [logical]
	var visual: Dictionary = Visuals.bind(compiled, definition.get("actor_visual_overrides", []))
	if visual.get("ok") != true: return visual
	return compiled
