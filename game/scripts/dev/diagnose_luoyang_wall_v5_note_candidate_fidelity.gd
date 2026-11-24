extends SceneTree
## Read-only ROOT228 candidate roundtrip diagnosis, not Field/FULL acceptance.
## Does not save resources, publish, restore navigation or run authored actions.
const CONTRACT_PATH := "res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd"
const CONTRACT_SHA := "10a2bf0330b695ad6086f5d3cdefae54d242f72d0dc212881a27e2ee5296f2a4"
const FACADE_PATH := "res://scripts/city/luoyang_layered_v3_contract.gd"
const FACADE_SHA := "037c52a57b3906889a53e1975fee0c8c704282dc20be772213dc5c551a86fcc5"
const IDS := ["ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market"]
const SPATIAL_FIELDS := ["background_path", "streamed_background", "player_spawn", "player_visual_scale", "actor_positions_are_feet", "npcs", "animated_props", "scene_objects", "collision_rects", "exits", "trigger_zones"]
const SAMPLE_LIMIT := 32

func _initialize() -> void:
	call_deferred("_diagnose")

func _diagnose() -> void:
	if not "--diagnose-note-candidate-fidelity" in OS.get_cmdline_user_args():
		push_error("Explicit read-only diagnostic flag required")
		quit(2)
		return
	if FileAccess.get_sha256(CONTRACT_PATH) != CONTRACT_SHA or FileAccess.get_sha256(FACADE_PATH) != FACADE_SHA:
		push_error("Pinned ROOT228 source changed; diagnostic requires explicit refreeze")
		quit(2)
		return
	var contract: Script = load(CONTRACT_PATH) as Script
	if contract == null or not contract.can_instantiate():
		push_error("Pinned candidate contract unavailable")
		quit(2)
		return
	var before: Dictionary = {CONTRACT_PATH: CONTRACT_SHA, FACADE_PATH: FACADE_SHA}
	for id: String in IDS:
		for path: String in [contract.candidate_path(StringName(id)), contract.layout_path(StringName(id)), contract.ROOT + id + "/art_contract.json"]:
			before[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT"
	var rows: Array = []
	var failure_count: int = 0
	for id: String in IDS:
		var path: String = contract.candidate_path(StringName(id))
		var row: Dictionary = {"id": id, "candidate_path": path, "candidate_exists": FileAccess.file_exists(path), "mismatched_leaf_count": 0, "mismatches": []}
		if not row.candidate_exists:
			row["status"] = "ABSENT_NO_COMPARISON"
			rows.append(row)
			continue
		var actual: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		var actual_layout: Resource = actual.get("map_layout") as Resource if actual != null else null
		row["is_v3"] = contract.is_v3(actual)
		row["schema"] = actual_layout.get("schema_version") if actual_layout != null else null
		row["layout_path"] = actual_layout.resource_path if actual_layout != null else ""
		row["metadata"] = {"revision": actual.get_meta("luoyang_layered_revision", null), "manifest_sha": actual.get_meta("city_manifest_sha", null)} if actual != null else {}
		row["runtime_fidelity"] = contract.runtime_fidelity(actual)
		row["runtime_fidelity_errors"] = contract.errors()
		var expected: Resource = contract.materialize(StringName(id))
		var expected_layout: Resource = expected.get("map_layout") as Resource if expected != null else null
		row["materialize_errors"] = contract.errors()
		if actual == null or expected == null or actual_layout == null or expected_layout == null:
			row["status"] = "UNAVAILABLE"
			failure_count += 1
		else:
			for field: String in SPATIAL_FIELDS:
				_diff(expected.get(field), actual.get(field), "scene." + field, row)
			for property: Dictionary in expected_layout.get_property_list():
				var field: String = String(property.name)
				if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or field in ["script", "resource_path", "resource_name", "resource_local_to_scene"]: continue
				_diff(expected_layout.get(field), actual_layout.get(field), "layout." + field, row)
			row["status"] = "EXACT" if row.runtime_fidelity and row.mismatched_leaf_count == 0 else "EXACT_FIDELITY_REJECTED"
			if row.status != "EXACT": failure_count += 1
		rows.append(row)
		actual_layout = null
		expected_layout = null
		actual = null
		expected = null
	var changed: Array = []
	for path: String in before:
		var after: String = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT"
		if after != before[path]: changed.append({"path": path, "before": before[path], "after": after})
	var report: Dictionary = {"scope": "READ_ONLY_SERIALIZED_CANDIDATE_FIDELITY_NOT_FIELD_OR_FULL", "rows": rows, "source_candidate_manifest_changes": changed, "failed_regions": failure_count}
	print("NOTE_CANDIDATE_FIDELITY_DIAGNOSTIC=" + JSON.stringify(report))
	contract = null
	rows.clear()
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null and audio.has_method("stop_bgm"): audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	quit(1 if failure_count > 0 or not changed.is_empty() else 0)

func _diff(expected: Variant, actual: Variant, path: String, row: Dictionary) -> void:
	if typeof(expected) != typeof(actual):
		_record(expected, actual, path, "TYPE", row)
		return
	if expected is Resource:
		if expected.resource_path != actual.resource_path or expected.get_script() != actual.get_script(): _record(expected, actual, path, "RESOURCE_PATH_OR_SCRIPT", row)
		return
	if expected is Array:
		if expected.size() != actual.size(): _record(expected.size(), actual.size(), path + ".size", "ARRAY_SIZE", row)
		for index: int in mini(expected.size(), actual.size()): _diff(expected[index], actual[index], path + "[" + str(index) + "]", row)
		return
	if expected is Dictionary:
		if expected.size() != actual.size(): _record(expected.size(), actual.size(), path + ".size", "DICTIONARY_SIZE", row)
		for key: Variant in expected:
			if not actual.has(key): _record(expected[key], null, path + "." + str(key), "MISSING_KEY", row)
			else: _diff(expected[key], actual[key], path + "." + str(key), row)
		return
	if expected != actual: _record(expected, actual, path, "EXACT_VALUE", row)

func _record(expected: Variant, actual: Variant, path: String, reason: String, row: Dictionary) -> void:
	row.mismatched_leaf_count += 1
	if row.mismatches.size() >= SAMPLE_LIMIT: return
	row.mismatches.append({"path": path, "reason": reason, "expected_type": typeof(expected), "actual_type": typeof(actual), "expected": _display(expected), "actual": _display(actual)})

func _display(value: Variant) -> String:
	if typeof(value) == TYPE_FLOAT: return String.num(value, 17)
	if value is Resource: return value.resource_path
	return var_to_str(value)
