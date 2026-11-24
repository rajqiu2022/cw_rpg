extends "res://tests/test_luoyang_docks08_formal_field_ready_retry1_20261019ab.gd"
## Remaining component only. Preserve115024 whole FAIL; reuse its completed layout/NPC/portal component.
const AB_PRIOR_FIELD := "res://build/luoyang_docks08_formal_field_20261019ab/115024/result.json"
const AB_PRIOR_CONSOLE := "res://build/luoyang_docks_runtime_integration_20261019ab_root01/formal_field_retry1_actual_console.log"
const AB_DRY_SUPPORT := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s2_canal_docks/raw_walk.png"

func ab_preflight() -> bool:
	if not super.ab_preflight(): return false
	var dependencies := {
		"res://tests/test_luoyang_docks08_formal_field_ready_retry1_20261019ab.gd": "fe8ce18a489add76ae118ef42b557542539f4b6a64ecfaf4152e6a336f4ecf2f",
		AB_PRIOR_FIELD: "ee2bd1ec2f6ae12ef2f0af61daa782f23ff91348ab04b08abbf23b96a0176cf1",
		AB_PRIOR_CONSOLE: "99e8700e11676d6d493b446c32ac2a36f4601adeb0c80098a00abd7f435574c7",
		AB_DRY_SUPPORT: "b9e5b36b482a34f1f12afda59358f62c74c097e6379d05ea9d920ab3dd177a4a"
	}
	for path: String in dependencies:
		if not track(path, dependencies[path]): return false
	var prior := json(AB_PRIOR_FIELD)
	if not check(prior.get("complete") == false and prior.get("checks") == 1692 and prior.get("failures") == 1 and prior.get("budget_ms") == 90000 and prior.get("arrival_ms") == 60000 and prior.get("elapsed_ms") == 25310 and prior.get("native_queries") == 10 and prior.get("records", []).size() == 2 and prior.get("pictures", []).is_empty(), "Original115024 whole result remains exact FAIL, not relabelled or assigned a missing picture"): return false
	if not check(prior.get("source_before", {}).size() == 1483 and prior.source_before == prior.get("source_after") and prior.get("players_before", {}).size() == 15 and prior.players_before == prior.get("players_after"), "Completed prior component all1483 source and fifteen save facts stable"): return false
	var first: Dictionary = prior.records[0]
	var moved: Dictionary = prior.records[1]
	if not check(first.get("kind") == "ORDINARY_NULL_SPAWN_FIRSTDRAW_OPERABLE" and first.get("source_proof", {}).get("sources_finalized") == true and first.source_proof.sources == expected_maps[DOCKS] and moved.get("kind") == "NORMAL_INPUT" and moved.get("result", {}).get("ok") == true, "Reuse only completed same-source1466 default-field and normal-input components; new process still rechecks current source/arrival/geometry/input"): return false
	var sole_failures: Array[String] = []
	for line: String in FileAccess.get_file_as_string(AB_PRIOR_CONSOLE).split("\n"):
		if line.begins_with("DOCKS_AB_FIELD_FAIL"): sole_failures.append(line.strip_edges())
		if not check(not line.contains("SCRIPT ERROR"), "Prior component has no runtime SCRIPT failure"): return false
	if not check(sole_failures == ["DOCKS_AB_FIELD_FAIL Unchanged river water remains forbidden to full player footprint, not added ground support <null>"], "Exact sole prior failure is the test's omitted dry-support domain, not production layout/NPC/door failure"): return false
	var published: Dictionary = json(ab_binding.default_spawn_authority.publication_path).record
	if not check(published.raw_walk_path == AB_DRY_SUPPORT and published.asset_sha256.get(AB_DRY_SUPPORT) == dependencies[AB_DRY_SUPPORT] and String(published.navigation_recipe).contains("water is absent from land/raw_walk"), "Independent original native dry-support authority; water is not a solid on an all-world floor"): return false
	records.append({"kind": "REUSED_COMPLETED_LAYOUT_COMPONENT_ORIGINAL_WHOLE_FAIL_RETAINED", "prior_report": AB_PRIOR_FIELD, "original_complete": false, "original_failures": 1, "completed_layout_component": "actual25 plus unchanged District render/bodies, office/two jobs, original10 crowd/6 lanes, taskNPC/two ships/four portal Areas and clearance before water assertion", "repeats_layout_NPC_four_portal_suite": false, "new_component_scope": "dry-support water rejection, three removed-building clearance stations, one ordinary camera picture", "geometry_or_routes_rebuilt": false})
	return true

func ab_actual_layout() -> bool:
	var support := Image.load_from_file(AB_DRY_SUPPORT)
	if not check(support != null and support.get_size() == Vector2i(WORLD) and mask != null, "Frozen original3072x2048 dry-support image and actual-byte-equal AA mask loaded"): return false
	var at := Vector2i(2600, 1400)
	var source_walkable := 0
	var actual_walkable := 0
	for y: int in range(-12, 13):
		for x: int in range(-17, 18):
			var pixel := at + Vector2i(x, y)
			var raw_color := support.get_pixelv(pixel)
			var actual_color := mask.get_pixelv(pixel)
			if raw_color.r >= .5 and raw_color.a >= .5: source_walkable += 1
			if actual_color.r >= .5 and actual_color.a >= .5: actual_walkable += 1
	if not check(source_walkable == 0 and actual_walkable == 0, "Water foot has zero dry-support and zero actual walkable pixels over all875 footprint samples, no ship support invented", {"source_walkable": source_walkable, "actual_walkable": actual_walkable}): return false
	var offsets: Array[Vector2] = [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]
	for offset: Vector2 in offsets:
		var pixel := Vector2i((Vector2(at) + offset).round())
		if not check(support.get_pixelv(pixel).r < .5 and mask.get_pixelv(pixel).r < .5, "Each original17 footprint probe rejects water in source and actual mask"): return false
	if not check(not _mask_clear(Vector2(at)) and not c.safe_body(StringName(DOCKS), Vector2(at)), "Actual committed C player navigation policy rejects absent water support; no fictitious water Physics wall required"): return false
	support = null
	for foot: Vector2 in [Vector2(500,1130), Vector2(560,1570), Vector2(560,1600)]:
		if not check(_clear(foot), "Remaining new freed foot full87517/raw continuous34x24/actual nativePhysics without teleport " + str(foot)): return false
	records.append({"kind": "ACTUAL_REMAINING_DRY_SUPPORT_AND_THREE_CLEARANCE_STATIONS", "water_foot": Vector2(at), "source_support_path": AB_DRY_SUPPORT, "full875_source_walkable": source_walkable, "full875_actual_walkable": actual_walkable, "seventeen_rejected": 17, "C_safe_body_rejected": true, "invented_river_Physics_wall_credit": false, "clearance_stations": [Vector2(500,1130),Vector2(560,1570),Vector2(560,1600)], "layout_NPC_four_portal_component_reused_only": true, "old_whole_FAIL_changed": false})
	return true
