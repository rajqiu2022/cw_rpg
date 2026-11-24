extends RefCounted
## Physical residency is authored separately from original business identity.
## A known source actor assigned to another room owns no node/body here.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")

func project(flags: Dictionary, states: Dictionary, bridge: RefCounted, contexts: Dictionary, compiled: Dictionary) -> Dictionary:
	var result: Variant = bridge.call("project_all", flags, states, contexts)
	if not result is Dictionary or result.get("ok") != true: return Core.fail("PHASE_BUSINESS_SOURCE")
	var scope: Dictionary = compiled.get("physical_phase_scope", {})
	if scope.is_empty(): return result
	var local_actors: Dictionary = {}; var local_areas: Dictionary = {}; var local_visuals: Dictionary = {}
	for row: Dictionary in compiled.npcs: local_actors[row.slot_key] = true
	for row: Dictionary in compiled.interactions: local_areas[row.key] = true
	for row: Dictionary in compiled.render: local_visuals[row.key] = true
	for field: String in ["actor_slots", "npcs", "interactions", "dynamic_visual_state"]:
		var allowed: Dictionary = scope.get("actors" if field in ["actor_slots", "npcs"] else ("interactions" if field == "interactions" else "visuals"), {})
		var local: Dictionary = local_actors if field in ["actor_slots", "npcs"] else (local_areas if field == "interactions" else local_visuals)
		if not result.get(field) is Dictionary: return Core.fail("PHASE_SCOPE_SCHEMA", field)
		for key: String in result[field].keys():
			if not allowed.has(key): return Core.fail("PHASE_UNDECLARED_SOURCE_SLOT", field + ":" + key)
			if not local.has(key): result[field].erase(key)
	return result
