extends "res://scripts/dev/export_luoyang_enclosure_v11_candidate.gd"
## Frozen V11 export remains byte-identical for ROOT393 provenance. Only NEW
## authored patches call this subclass for explicit native nonblocking roles.

func _capture(author: Dictionary, crop: Rect2i, path: String) -> Dictionary:
	var role: Variant = author.get("role", "")
	if not role is String or role not in ["", "ground_overlay", "water_decoration"]:
		_error = "Unknown explicit source object role"; return {}
	var result: Dictionary = await super._capture(author, crop, path)
	if result.is_empty(): return result
	for key: String in ["role", "ghost_occlusion", "walk_support", "interaction_required", "z_index", "sort_by_feet"]:
		if author.has(key): result[key] = author[key]
	if author.get("source_kind") == "actual_native_gpu_capture":
		result.nature = "PROJECT_ORIGINAL_NATIVE_GPU_SPRITE_EXPORT_NOT_CC0"
	if not C._object_render_role_valid(StringName(_region), result) or not C._render_role_matches_author(result, author):
		_error = "Actual exported role violates authored ghost/solid/walk/depth contract"; return {}
	return result
