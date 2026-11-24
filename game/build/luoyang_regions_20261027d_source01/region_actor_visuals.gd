extends RefCounted
## One adopted same-person pair. Task data, scales and bodies are not rewritten.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const LOGICAL := "ch4_s4_ancient_temple"
const ACTOR := "temple_cave_keeper_20261018t"

static func bind(compiled: Dictionary, overrides: Array) -> Dictionary:
	for contract: Dictionary in overrides:
		if contract.get("source_logical_id") != LOGICAL or contract.get("npc_id") != ACTOR: return Core.fail("VISUAL_PAIR_EXACT_ID")
		var rows: Array = compiled.npcs.filter(func(row: Dictionary) -> bool: return row.logical_id == LOGICAL and row.data.npc_id == ACTOR)
		if rows.size() != 1 or rows[0].has("visual_contract"): return Core.fail("VISUAL_PAIR_UNIQUE_SLOT")
		if contract.get("before", {}).keys().size() != 2 or contract.get("after", {}).keys().size() != 2: return Core.fail("VISUAL_PAIR_FIELDS")
		for key: String in ["sprite_path", "portrait_path"]:
			if rows[0].data.get(key) != contract.before.get(key) or not contract.get("source_sha256", {}).has(contract.after.get(key)): return Core.fail("VISUAL_PAIR_ORIGINAL_OR_SOURCE", key)
		if contract.source_sha256.size() != 6 or Core.vec(contract.get("frame_size_px")) != Vector2(160, 160) or contract.get("preserve_all_other_actor_fields") != true: return Core.fail("VISUAL_PAIR_FRAME_BODY_CONTRACT")
		rows[0]["visual_contract"] = contract.duplicate(true)
		for path: String in contract.source_sha256:
			if compiled.sources.has(path) and compiled.sources[path] != contract.source_sha256[path]: return Core.fail("VISUAL_PAIR_SOURCE_CONFLICT", path)
			compiled.sources[path] = contract.source_sha256[path]
	return {"ok": true}

static func actor_data(source: Dictionary, phase: Dictionary, first: Dictionary) -> Dictionary:
	var data: Dictionary = phase.duplicate(true)
	if not source.has("visual_contract"): return {"ok": true, "data": data}
	var contract: Dictionary = source.visual_contract
	if source.get("logical_id") != LOGICAL or data.get("npc_id") != ACTOR or source.data.get("npc_id") != ACTOR: return Core.fail("VISUAL_PAIR_LIVE_ID")
	for path: String in contract.source_sha256:
		if first.get(path) != contract.source_sha256[path]: return Core.fail("VISUAL_PAIR_FIRST", path)
	for key: String in ["sprite_path", "portrait_path"]:
		if data.get(key) != contract.before[key] or source.data.get(key) != contract.before[key]: return Core.fail("VISUAL_PAIR_PHASE_ORIGINAL", key)
		data[key] = contract.after[key]
	# The exact same 160-frame/148px adult calibration is preserved. No scale,
	# ground anchor, movement, task, body offset or NPCNode property is altered.
	return {"ok": true, "data": data}
