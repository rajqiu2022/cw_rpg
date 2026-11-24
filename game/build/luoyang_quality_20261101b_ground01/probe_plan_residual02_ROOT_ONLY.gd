extends SceneTree
## Root may execute once under its existing source/save guard. This script is
## read-only: no Field, SceneRouter action, input, save, or resource publication.
## Residual only after actual01: 11 PASS / 2 FAIL retained. Civic six checks
## already passed and are deliberately not replayed; original probe stays intact.
const Ground = preload("res://build/luoyang_quality_20261101b_ground01/ground_visual.gd")
const MANIFEST := "res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json"
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("GROUND31B_CHECK ", "PASS " if ok else "FAIL ", label)

func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for id: String in ["luoyang_estate_region_27d", "luoyang_temple_region_27d"]:
		var binding: Dictionary = manifest.compiled_bindings[id]
		check(FileAccess.get_sha256(binding.path) == binding.sha256, "CURRENT_BIN_SHA:" + id)
		var region: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(binding.path))
		var before := var_to_bytes(region)
		var result: Dictionary = Ground.plan(region)
		check(bool(result.get("ok", false)), "PLAN:" + id)
		check(before == var_to_bytes(region), "COMPILED_UNCHANGED:" + id)
		if not result.get("ok", false):
			print("GROUND31B_ERROR ", result); continue
		check(result.paving.size() > 0 and result.paving.size() <= 256 and result.edging.size() > 0 and result.edging.size() <= 512, "FINITE_QUADS:" + id)
		var finite := true
		for area: Rect2 in result.paving:
			finite = finite and area.position.is_finite() and area.size.is_finite() and area.size.x > 0 and area.size.y > 0
		check(finite, "FINITE_POSITIVE_PAVING:" + id)
		check(result.period_px == Vector2(256, 512.0 / 3.0) and result.same_world_uv, "UNIFIED_SOURCE_UV:" + id)
		print("GROUND31B_PLAN ", id, " paving=", result.paving.size(), " edges=", result.edging.size(), " cells=", result.cell_count)
		if id == "luoyang_estate_region_27d":
			check(_covers(result.paving, Vector2(1536, 3900)), "ESTATE_ARRIVAL_REMAINS_PAVING")
			check(not _covers(result.paving, Vector2(2250, 3000)), "ESTATE_SERVANTS_EARTH_REMAINS_EARTH")
			check(_covers(result.paving, Vector2(2000, 3000)), "ESTATE_ADJACENT_COURT_REMAINS_PAVING")
			check(not _covers(result.paving, Vector2(1536, 200)), "ESTATE_RETIRED_NORTH_STUB_STAYS_HIDDEN")
	print("GROUND31B_RESULT passed=", passed, " failed=", failed)
	quit(0 if failed == 0 else 1)

func _covers(areas: Array, point: Vector2) -> bool:
	for area: Rect2 in areas:
		if area.has_point(point): return true
	return false
