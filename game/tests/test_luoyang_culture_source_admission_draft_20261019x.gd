extends SceneTree
## NEW metadata admission only; no geometry rebuild, Field setup or task replay.
const READY := true
const PLAN := "res://build/luoyang_culture_integration_20261019x_root01/source_successor_plan_retry1.json"
const PLAN_SHA := "30242823733d8f03b80db6520987dc6c66bd328de328a6ca15289e9a5474e93c"
const TRUE_CLOSURE := "res://build/luoyang_culture_integration_20261019x_root01/frozen_source_closure_true.json"
const TRUE_CLOSURE_SHA := "ef37e6bf706dbd1d45f675bd3078fb667fe0a85e4d3e1221d3b669c15e1213c8"
const B_PATH := "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const C_PATH := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const INDEX := "res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd"
const ROOT_MAP := "res://data/maps/luoyang_layout_bundle_20261018t_retry2/"
const BEFORE := "res://build/luoyang_culture_integration_20261019x_root01/before/"
const FIELD := "res://scripts/field/field_walkable_controller.gd"
const TEMPLE := "res://scripts/city/luoyang_temple_assembly_20261016.gd"
const BUDGET_MS := 60000
var checks := 0
var failures := 0
var began := 0
var records: Array = []
var source_before: Dictionary = {}
var players_before: Dictionary = {}
var b: Script
var c: Script

func _initialize() -> void: call_deferred("_run")
func check(value: bool, label: String, detail: Variant = null) -> bool:
	checks += 1
	if not value:
		failures += 1
		printerr("CULTURE_X_ADMISSION_FAIL ", label, " ", detail)
	return value
func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists": false, "sha256": "ABSENT", "bytes": 0, "mtime_seconds_string": "0"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"exists": false, "sha256": "OPEN_FAILED", "bytes": 0, "mtime_seconds_string": "0"}
	var length := file.get_length()
	file.close()
	return {"exists": true, "sha256": FileAccess.get_sha256(path), "bytes": length, "mtime_seconds_string": str(FileAccess.get_modified_time(path))}
func track(path: String, expected: String) -> bool:
	if source_before.has(path): return check(source_before[path].sha256 == expected, "Repeated leaf has one exact authority " + path)
	var actual := fact(path)
	source_before[path] = actual
	return check(actual.exists and actual.sha256 == expected and expected.length() == 64, "Exact frozen current source " + path)
func saves() -> Dictionary:
	var result: Dictionary = {}
	for slot: int in 5:
		for suffix: String in [".json", ".json.bak", ".json.tmp"]:
			var path := "user://save_" + str(slot) + suffix
			result[path] = fact(path)
	return result
func json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
func exercise() -> bool:
	if not check(READY and OS.get_cmdline_user_args().is_empty(), "Final frozen source successor, no candidate flags"): return false
	if not track(PLAN, PLAN_SHA): return false
	var plan := json(PLAN)
	if not check(plan.get("scope") == "SOURCE_METADATA_ONLY_NO_GEOMETRY_RECOMPUTE" and plan.get("rows", []).size() == 4, "Four exact metadata-only successors"): return false
	b = load(B_PATH); c = load(C_PATH)
	if not check(b != null and c != null, "Actual bundle and complete collector scripts load"): return false
	if not track(INDEX, plan.index_sha256) or not track(TEMPLE, plan.temple_helper_sha256) or not track(plan.temple_binding_path, plan.temple_binding_sha256): return false
	var prior_binding_path := BEFORE + "temple_binding.json"
	var binding := json(plan.temple_binding_path)
	var binding_successor: Dictionary = binding.get("culture_source_successor", {})
	if not check(binding_successor.get("prior_path") == prior_binding_path and track(prior_binding_path, binding_successor.get("prior_sha256", "")), "Exact historical Temple binding predecessor"): return false
	if not track(TRUE_CLOSURE, TRUE_CLOSURE_SHA): return false
	var closure := json(TRUE_CLOSURE)
	if not check(closure.get("count") == 53 and closure.get("bad", []).is_empty() and closure.get("source_sha256", {}).size() == 53, "Exact default-enabled fifty-three-leaf integration closure"): return false
	var old_binding := json(prior_binding_path)
	var expected_delta: Dictionary = old_binding.source_delta.duplicate(true)
	expected_delta.merge(closure.source_sha256, true)
	if not check(b.equal(binding.get("source_delta"), expected_delta), "Whole Temple source_delta equals old closure plus only the explicit fifty-three source successor leaves"): return false
	var binding_inverse := binding.duplicate(true)
	binding_inverse.erase("culture_source_successor")
	binding_inverse.id = old_binding.id
	binding_inverse.source_delta = old_binding.source_delta.duplicate(true)
	if not check(binding.id == "luoyang_temple_culture_field_source_successor_20261019x" and b.equal(binding_inverse, old_binding), "Whole Temple binding inverse preserves replacement map, task history, monk proof and limits, not selected fields"): return false
	var old_helper_path := BEFORE + "temple_helper.gd.source"
	if not track(old_helper_path, FileAccess.get_sha256(old_helper_path)): return false
	var old_helper := FileAccess.get_file_as_string(old_helper_path)
	var changed_helper := FileAccess.get_file_as_string(TEMPLE)
	var old_path_line := ""
	var old_sha_line := ""
	for line: String in old_helper.split("\n"):
		if line.begins_with("const BIND_PATH="): old_path_line = line.trim_suffix("\r")
		if line.begins_with("const BIND_SHA="): old_sha_line = line.trim_suffix("\r")
	var restored_helper := changed_helper.replace('const BIND_PATH="' + String(plan.temple_binding_path) + '"', old_path_line).replace('const BIND_SHA="' + String(plan.temple_binding_sha256) + '"', old_sha_line)
	check(not old_path_line.is_empty() and not old_sha_line.is_empty() and restored_helper == old_helper, "Temple helper whole text inverse changes only two binding constants")
	var old_index := FileAccess.get_file_as_string(BEFORE + "bundle_index.gd.source")
	var expected_index := old_index
	for row: Dictionary in plan.rows:
		var id: String = row.id
		var path := ROOT_MAP + id + "/manifest.json"
		var old_path := BEFORE + id + "_manifest.json"
		if not track(path, row.new_sha256) or not track(old_path, row.prior_sha256): return false
		var current := json(path)
		var old := json(old_path)
		var successor: Dictionary = current.get("culture_integration_successor", {})
		if not check(successor.get("prior_manifest_path") == old_path and successor.get("prior_manifest_sha256") == row.prior_sha256 and b.equal(successor.get("source_delta"), row.source_delta) and b.equal(successor.get("added_source_sha256"), row.added_source_sha256) and successor.get("geometry_and_publication_unchanged") == true, "Independent planned successor authority " + id): return false
		var inverse := current.duplicate(true)
		inverse.erase("culture_integration_successor")
		for leaf: String in row.source_delta:
			var delta: Dictionary = row.source_delta[leaf]
			if not check(leaf in [FIELD, TEMPLE] and old.legacy_source_sha256.get(leaf) == delta.old_sha256 and current.legacy_source_sha256.get(leaf) == delta.new_sha256, "Only two authorized old-source changes " + leaf): return false
			inverse.legacy_source_sha256[leaf] = delta.old_sha256
		for leaf: String in row.added_source_sha256:
			if not check(not old.legacy_source_sha256.has(leaf) and current.legacy_source_sha256.get(leaf) == row.added_source_sha256[leaf], "Explicit previously absent runtime leaf " + leaf): return false
			inverse.legacy_source_sha256.erase(leaf)
		if not check(b.equal(inverse, old), "Whole manifest semantic inverse, not selected-field comparison " + id): return false
		var expected: Dictionary = current.legacy_source_sha256.duplicate(true)
		expected.merge(current.runtime_authority_sha256)
		expected.merge(current.artifacts)
		expected[INDEX] = plan.index_sha256
		expected[path] = row.new_sha256
		var scene: SceneScript = load("res://data/scenes/" + id + ".tres") as SceneScript
		if not check(scene != null, "Actual canonical collector input Scene " + id): return false
		var actual_keys: Dictionary = c._transition_sources(scene, false)
		if not check(actual_keys.size() == expected.size(), "Complete current collector exact count " + id, {"actual": actual_keys.size(), "expected": expected.size()}): return false
		var actual: Dictionary = {}
		for leaf: String in actual_keys:
			if not check(expected.has(leaf), "No extra or missing collector leaf " + id + "/" + leaf) or not track(leaf, expected.get(leaf, "")): return false
			actual[leaf] = source_before[leaf].sha256
		if not check(b.equal(actual, expected) and not b.describe(StringName(id), actual).is_empty(), "Actual all-current-SHA collector equals frozen complete map and B.describe " + id): return false
		var sentinel: String = String(actual.keys()[0])
		var missing := actual.duplicate(true); missing.erase(sentinel)
		var extra := actual.duplicate(true); extra["res://tests/EXTRA_UNAUTHORIZED_CULTURE_LEAF"] = "0".repeat(64)
		var changed := actual.duplicate(true); changed[sentinel] = "0".repeat(64) if actual[sentinel] != "0".repeat(64) else "1".repeat(64)
		check(b.describe(StringName(id), missing).is_empty() and b.describe(StringName(id), extra).is_empty() and b.describe(StringName(id), changed).is_empty(), "Missing, extra and wrong SHA all refused " + id)
		expected_index = expected_index.replace(row.prior_sha256, row.new_sha256)
		records.append({"kind": "METADATA_ONLY_FULL_COLLECTOR", "id": id, "source_count": actual.size(), "actual_source_sha256": actual, "whole_semantic_inverse": true, "geometry_or_Field_credit": false})
	check(expected_index == FileAccess.get_file_as_string(INDEX), "Index text changes only four approved SHA literals")
	return failures == 0
func _run() -> void:
	began = Time.get_ticks_msec()
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves()
	track(get_script().resource_path, FileAccess.get_sha256(get_script().resource_path))
	var complete := exercise()
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after := saves()
	check(source_before == source_after, "All actual complete-source facts first/final exact")
	check(players_before == players_after and players_before.size() == 15, "All fifteen existing or absent save facts unchanged")
	check(Time.get_ticks_msec() - began < BUDGET_MS, "Fixed sixty-second metadata-only atom, no geometry or old task replay")
	var folder := "res://build/luoyang_culture_source_admission_20261019x/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join("result.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope": "METADATA_ONLY_EXACT_SOURCE_SUCCESSOR_NOT_GEOMETRY_OR_FIELD", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "budget_ms": BUDGET_MS, "source_before": source_before, "source_after": source_after, "players_before": players_before, "players_after": players_after, "records": records}, "\t"))
		file.close()
	print(JSON.stringify({"report_path": path, "checks": checks, "failures": failures, "complete": complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
