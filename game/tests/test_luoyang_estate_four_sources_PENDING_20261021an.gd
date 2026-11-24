extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## ROOT-only once after exact formal target deployment. Not four-city gameplay.
const SOURCES_READY: bool = false
const FIXTURE: String = "res://build/luoyang_estate_courtyard_20261021an_qa01/four_source_fixture_PENDING.json"
const FIXTURE_SHA: String = "PENDING_INDEPENDENT_STAGER_FOUR_TRUE_MAPS"
const LIMIT_MS: int = 60000
const C_PATH: String = "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const FAMILY: String = "res://scripts/city/luoyang_estate_family_20261021am.gd"
const IDS: Array[String] = ["ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market"]
const BASE_PATH: String = "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
const BASE_SHA: String = "a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895"
var configuration: Dictionary = {}
var union_sources: Dictionary = {}
var completed_collectors: int = 0

func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists": false, "sha256": "ABSENT", "bytes": 0, "mtime_seconds": "0"}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null: return {"exists": true, "read_error": true}
	var count: int = f.get_length(); f.close()
	return {"exists": true, "sha256": FileAccess.get_sha256(path), "bytes": count, "mtime_seconds": str(FileAccess.get_modified_time(path))}

func _json(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}

func _state() -> Dictionary:
	var gs: Node = root.get_node("GameState")
	return {"flags": gs.get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict").duplicate(true), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true), "gold": gs.get("gold"), "reputation": gs.get("reputation")}

func _prepare() -> bool:
	if not check(SOURCES_READY and OS.get_cmdline_user_args().is_empty(), "Frozen ordinary no-flag four-source admission, never candidate flag"): return false
	if not track(BASE_PATH, BASE_SHA) or not track(FIXTURE, FIXTURE_SHA): return false
	configuration = _json(FIXTURE)
	if not check(configuration.get("status") == "ROOT_FROZEN_AN_FOUR_TRUE_SOURCE_MAPS" and configuration.get("maps", {}).size() == 4, "Only exact four independently staged true maps"): return false
	if not track(configuration.stage_receipt.path, configuration.stage_receipt.sha256): return false
	var stage: Dictionary = _json(configuration.stage_receipt.path)
	if not check(stage.get("status") == "AN_STAGED_SOURCE_READY_NOT_DEPLOYED_NOT_FIELD_PASS" and stage.get("all_six_manifest_whole_inverse") == true and stage.get("no_actual_collector_backfill") == true and stage.get("independent_expected_maps", {}).size() == 4, "Actual stager full source inverse, not a collector-derived expected set"): return false
	for path: String in configuration.test_dependencies:
		if not track(path, configuration.test_dependencies[path]): return false
	for path: String in [C_PATH, FAMILY]:
		if not check(configuration.test_dependencies.has(path), "Executed production entry fixed before load " + path): return false
	for id: String in IDS:
		var row: Dictionary = configuration.maps.get(id, {})
		var staged: Dictionary = stage.independent_expected_maps.get(id, {})
		if not check(row.get("path") == staged.get("true_path") and row.get("sha256") == staged.get("true_sha256") and row.get("count") == staged.get("count"), "Final stage exact true authority map " + id): return false
		if not track(row.path, row.sha256): return false
		var expected: Dictionary = _json(row.path).get("source_sha256", {})
		if not check(not expected.is_empty() and expected.size() == row.count, "Full independent map count " + id): return false
		for path: String in expected:
			if not check(not union_sources.has(path) or union_sources[path] == expected[path], "Shared source has one exact epoch " + path): return false
			union_sources[path] = expected[path]
		row["expected"] = expected
		configuration.maps[id] = row
	for path: String in union_sources:
		if not track(path, union_sources[path]): return false
		if Time.get_ticks_msec() >= deadline: return check(false, "Original60s source admission budget reached during first pass")
	var self_path: String = get_script().resource_path
	return track(self_path, FileAccess.get_sha256(self_path))

func _collect() -> bool:
	var c: Script = load(C_PATH) as Script
	var family: Script = load(FAMILY) as Script
	if not check(c != null and c.can_instantiate() and family != null and family.can_instantiate() and family.requested() == true, "Default formal family/city sources actually compile after deployment"): return false
	for id: String in IDS:
		if Time.get_ticks_msec() >= deadline: return check(false, "Original60s source budget before collector " + id)
		var raw_path: String = "res://data/scenes/" + id + ".tres"
		var expected: Dictionary = configuration.maps[id].expected
		if not check(expected.has(raw_path), "Raw Scene input belongs to independent map " + id): return false
		var raw: SceneScript = ResourceLoader.load(raw_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if not check(raw != null and String(raw.scene_id) == id, "Real canonical raw Scene only, not C materialization " + id): return false
		var started_us: int = Time.get_ticks_usec()
		var actual_paths: Dictionary = c._transition_sources(raw, false)
		var missing: Array[String] = []; var extra: Array[String] = []
		for path: String in expected:
			if not actual_paths.has(path): missing.append(path)
		for path: String in actual_paths:
			if not expected.has(path): extra.append(path)
		if not check(actual_paths.size() == expected.size() and missing.is_empty() and extra.is_empty(), "Actual complete collector set equals independent old-plus-finite map " + id, {"actual": actual_paths.size(), "expected": expected.size(), "missing": missing, "extra": extra}): return false
		var actual_hashes: Dictionary = {}
		for path: String in actual_paths: actual_hashes[path] = source_before[path].sha256
		if not check(actual_hashes == expected, "Every actual collector path has independently checked full current SHA " + id): return false
		records.append({"kind": "ACTUAL_COMPLETE_C_SOURCE_COLLECTOR_NOT_FIELD", "scene_id": id, "source_count": actual_paths.size(), "source_sha256": actual_hashes, "collector_elapsed_us": Time.get_ticks_usec() - started_us, "deduplicated_source_pass": true, "geometry_or_Field_credit": false})
		completed_collectors += 1
		await process_frame
	return check(completed_collectors == 4, "All four source collectors completed exactly once")

func _run() -> void:
	var started: int = Time.get_ticks_msec(); deadline = started + LIMIT_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves(); var state_before: Dictionary = _state()
	var folder: String = "res://build/luoyang_estate_courtyard_20261021an_qa01/four_sources_%d" % OS.get_process_id()
	if DirAccess.dir_exists_absolute(folder): printerr("AN_SOURCE_REPORT_EXISTS"); quit(2); return
	DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool = _prepare()
	if complete: complete = await _collect()
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after: Dictionary = saves(); var state_after: Dictionary = _state()
	check(source_before == source_after, "All complete unique source facts first/final unchanged")
	check(players_before.size() == 15 and players_before == players_after, "All15 absent/present slots unchanged")
	check(state_before == state_after and root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended") == true, "State unchanged; checkpoints suspended; no restore masks writes")
	check(Time.get_ticks_msec() - started < LIMIT_MS, "Original fixed60s includes source-first/final, no budget expansion")
	var result: Dictionary = {"scope": "AN_FOUR_ACTUAL_COMPLETE_SOURCE_COLLECTORS_ONLY_NOT_GEOMETRY_FIELD_OR_ROOM_REPLAY", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - started, "budget_ms": LIMIT_MS, "completed_collectors": completed_collectors, "unique_runtime_sources": union_sources.size(), "records": records, "source_before": source_before, "source_after": source_after, "players_before": players_before, "players_after": players_after, "state_before": state_before, "state_after": state_after, "mtime_precision": "Godot seconds String; Root guard supplies independent exactticks", "materialize_geometry_or_Field_run": false}
	var path: String = folder.path_join("result.json")
	if FileAccess.file_exists(path): printerr("AN_SOURCE_RESULT_EXISTS"); quit(2); return
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: printerr("AN_SOURCE_REPORT_OPEN_FAILED"); quit(2); return
	file.store_string(JSON.stringify(result, "\t")); file.close()
	print(JSON.stringify({"report_path": path, "complete": result.complete, "checks": checks, "failures": failures}))
	quit(0 if result.complete else 1)
