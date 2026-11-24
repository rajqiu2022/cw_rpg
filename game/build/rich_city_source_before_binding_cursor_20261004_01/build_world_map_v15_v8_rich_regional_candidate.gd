extends "res://scripts/dev/build_world_map_v15_coherent_whole_v8_regional_proposal.gd"

## Isolated material follow-up, never substitutes the current FULL inputs.
## Uses the parent's bounded two-world/five-role/two-draw mechanism only.
## The inherited result remains a limited capture, never FULL or Field credit.
const RICH_ECOLOGY := preload("res://scripts/dev/world_map_v15_complete_v8_rich_ecology_candidate.gd")
const RICH_SURFACE := preload("res://scripts/dev/world_map_v15_complete_v8_rich_surface_candidate.gd")
const RICH_SCOPE := "V8_RICH_REGIONAL_CANDIDATE_NOT_FULL_FIELD_OR_APPROVAL"
var rich_installed := false

func _material_maps(rect: Rect2) -> Dictionary:
	if not rich_installed:
		var actual := RICH_ECOLOGY.new()
		actual.heights = source.heights
		actual.prepare()
		if not actual.v7_proposal_error.is_empty():
			error = actual.v7_proposal_error
			return {}
		source = actual
		if not _v7_replace_bianzhou_approach(): return {}
		if surface != null: surface.release()
		surface = RICH_SURFACE.new()
		if not surface.load_sources():
			error = surface.error
			return {}
		for record: Dictionary in surface.evidence:
			for key: String in ["path", "source_path"]:
				var path: String = record[key]
				if not pilot_inputs.has(path) or FileAccess.get_sha256(path).to_lower() != String(pilot_inputs[path]).to_lower():
					error = "Rich candidate actual registered input missing or changed: " + path
					return {}
		v8_installed = true
		rich_installed = true
	return super._material_maps(rect)

func _pilot_authorized(path: String) -> bool:
	if not super._pilot_authorized(path): return false
	if pilot_auth.get("rich_candidate_scope") != RICH_SCOPE:
		error = "Explicit isolated rich material candidate scope required."
		return false
	for required: String in [get_script().resource_path, RICH_ECOLOGY.resource_path, RICH_SURFACE.resource_path]:
		if not pilot_inputs.has(required) or FileAccess.get_sha256(required).to_lower() != String(pilot_inputs[required]).to_lower():
			error = "Unbound rich candidate source: " + required
			return false
	return true

func _load_pilot_inputs() -> bool:
	if not super._load_pilot_inputs(): return false
	if not source is RICH_ECOLOGY or not surface is RICH_SURFACE:
		error = "Actual rich candidate objects not installed; inherited labels are not evidence."
		return false
	pilot_result["actual_rich_candidate_binding"] = {
		"scope": RICH_SCOPE,
		"ecology_path": source.get_script().resource_path,
		"ecology_sha256": FileAccess.get_sha256(source.get_script().resource_path),
		"surface_path": surface.get_script().resource_path,
		"surface_sha256": FileAccess.get_sha256(surface.get_script().resource_path),
		"field_executed": false,
		"visual_approved": false,
		"production_approved": false
	}
	return true

func _write_json(path: String, data: Dictionary) -> bool:
	var record: Dictionary = data.duplicate(true)
	if path == pilot_output + "result.json":
		record["isolated_followup_scope"] = RICH_SCOPE
		record["formal_source_replaced"] = false
		record["full_source_replaced"] = false
		record["field_executed"] = false
	return super._write_json(path, record)
