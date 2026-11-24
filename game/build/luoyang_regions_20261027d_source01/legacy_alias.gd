extends RefCounted
## No save-file writes. Old IDs and UVs remain explicitly local to their version.
const Compiler = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")

static func district_at(compiled: Dictionary, foot: Vector2) -> String:
	for id: String in compiled.districts:
		if compiled.districts[id].domain.has_point(foot): return id
	return ""

static func arrive(compiled: Dictionary, logical_id: String, uv: Vector2, legacy_version: int, extension: Dictionary = {}) -> Dictionary:
	if not compiled.get("ok", false) or not compiled.districts.has(logical_id) or not uv.is_finite() or uv.x < 0.0 or uv.y < 0.0 or uv.x > 1.0 or uv.y > 1.0: return Compiler.fail("LEGACY_ALIAS")
	var district: Dictionary = compiled.districts[logical_id]
	if not extension.is_empty():
		if extension.get("region_id") != compiled.id or extension.get("revision") != compiled.revision or extension.get("logical_id") != logical_id: return Compiler.fail("REGION_SAVE_VERSION")
		var exact: Vector2 = Compiler.vec(extension.get("global_foot_px"))
		if district_at(compiled, exact) != logical_id or not Compiler.safe_body(compiled, exact, Vector2(17, 12)): return Compiler.fail("REGION_SAVED_FOOT_BLOCKED")
		return {"ok": true, "foot": exact, "reason": "exact_region_save", "logical_id": logical_id}
	var migrations: Array = district.migrations
	if legacy_version != district.legacy_version:
		var versions: Dictionary = district.get("legacy_version_migrations", {})
		if not versions.get(str(legacy_version)) is Array or versions[str(legacy_version)].is_empty(): return Compiler.fail("LEGACY_VERSION_REQUIRES_EXPLICIT_MIGRATOR", logical_id)
		migrations = versions[str(legacy_version)]
	var old_foot: Vector2 = uv * district.legacy_size
	# Explicit author partitions outrank identity mapping after a lot is relocated.
	var selected: Dictionary = {}
	for migration: Dictionary in migrations:
		if _legacy_partition_contains(Compiler.rect(migration.old_rect), old_foot, district.legacy_size):
			if not selected.is_empty(): return Compiler.fail("AMBIGUOUS_LEGACY_MIGRATION")
			selected = migration
	var point: Vector2 = old_foot + district.legacy_frame_origin
	var reason: String = "legacy_local_affine"
	if not selected.is_empty():
		point = Compiler.vec(selected.target_foot_px); reason = String(selected.reason)
	if district_at(compiled, point) != logical_id or not Compiler.safe_body(compiled, point, Vector2(17, 12)): return Compiler.fail("SAVED_FOOT_NEEDS_AUTHORED_MIGRATION", logical_id)
	return {"ok": true, "foot": point, "reason": reason, "logical_id": logical_id}

static func _legacy_partition_contains(area: Rect2, foot: Vector2, old_size: Vector2) -> bool:
	# Rect2 is half-open internally. Only the actual old map's outer edge is
	# closed, so UV=1 belongs to the final partition without overlap/epsilon.
	return foot.x >= area.position.x and foot.y >= area.position.y and (foot.x < area.end.x or foot.x == old_size.x and area.end.x == old_size.x) and (foot.y < area.end.y or foot.y == old_size.y and area.end.y == old_size.y)

static func navigation(compiled: Dictionary, global_foot: Vector2) -> Dictionary:
	var id: String = district_at(compiled, global_foot)
	if id.is_empty() or not Compiler.safe_body(compiled, global_foot, Vector2(17, 12)): return Compiler.fail("NO_LOGICAL_SAVE_DOMAIN")
	var district: Dictionary = compiled.districts[id]
	# Re-authored lots invalidate an affine inverse even when it happens to lie
	# inside [0,1]. Preserve a declared OLD-map safe anchor, not a new global UV.
	# The versioned extension alone records/restores the exact new walking foot.
	var uv: Vector2 = district.save_fallback_uv
	if not uv.is_finite() or uv.x < 0 or uv.y < 0 or uv.x > 1 or uv.y > 1: return Compiler.fail("NO_LEGACY_FALLBACK_ANCHOR")
	return {"ok": true, "current_field": id, "current_field_spawn": uv, "local_layout_version": district.legacy_version, "legacy_position_kind": "explicit_compatible_anchor_exact_position_in_region27d", "region27d": {"region_id": compiled.id, "revision": compiled.revision, "logical_id": id, "global_foot_px": [global_foot.x, global_foot.y]}}
