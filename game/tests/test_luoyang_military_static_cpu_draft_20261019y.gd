extends SceneTree
## NOTREADY until the static-only source/import authority is frozen by Root.
## Pure row projection only. No Field setup, quest/dialogue suite or save write.
const READY := false
const API_PATH := "res://scripts/city/luoyang_military_static_presentation_20261019y.gd"
const ALIASES := "assets/processed/sprite/luoyang_soldier_diversity_20261019y/final_static_admission_successor2.json"
const ALIASES_SHA := "e5e1c4505c325f949db2232a8fca1b1f9b7206113a19b5ee85bfb69da911f0b9"
const FREEZE := "PENDING_ROOT_STATIC_SOURCE_CLOSURE"
const FREEZE_SHA := "PENDING"
const WHOLE_MS := 30000
const HARBOUR_CROWD := "res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd"
const DISTRICT_CROWD := "res://scripts/city/luoyang_district_life_crowd_20261016f.gd"
const DISTRICT_AUTHOR := "res://data/maps/luoyang_district_life_20261016f/author.json"
const LEGACY := "res://data/maps/luoyang_v3_legacy/"
const IDS := ["ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market"]
const TARGETS := {"luoyang_gate_sergeant": [0, "sergeant"], "harbour_life_gate_check_assistant": [0, "young_gate"], "canal_old_soldier": [2, "old_soldier"], "spar_yamen_captain": [1, "commander"], "district_life_yamen_guard": [1, "young_gate"]}
const KEEP := ["harbour_life_gate_patrol_west", "harbour_life_gate_patrol_east", "harbour_life_docks_quay_patrol", "district_life_market_patrol", "district_life_yamen_west_patrol", "spar_yamen_patrol", "spar_luoyang_patrol"]
const VISUAL := ["sprite_path", "walk_sprite_path", "portrait_path"]
var api: Script
var checks := 0
var failures := 0
var records: Array = []
var sources: Dictionary = {}
var expected: Dictionary = {}

func _initialize() -> void: call_deferred("_run")
func check(value: bool, label: String, detail: Variant = null) -> bool:
	checks += 1
	if not value:
		failures += 1
		printerr("MILITARY_Y_CPU_FAIL ", label, " ", detail)
	return value
func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists": false, "sha256": "ABSENT", "bytes": 0, "mtime_seconds_string": "0"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"exists": false, "sha256": "OPEN_FAILED", "bytes": 0, "mtime_seconds_string": "0"}
	var size := file.get_length(); file.close()
	return {"exists": true, "sha256": FileAccess.get_sha256(path), "bytes": size, "mtime_seconds_string": str(FileAccess.get_modified_time(path))}
func track(path: String, sha: String) -> bool:
	var actual := fact(path)
	if sources.has(path): return check(sources[path] == actual and actual.sha256 == sha, "One fixed source authority " + path)
	sources[path] = actual
	return check(actual.exists and sha.length() == 64 and actual.sha256 == sha, "Frozen exact source " + path)
func json(path: String) -> Dictionary:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return data if data is Dictionary else {}
func saves() -> Dictionary:
	var result: Dictionary = {}
	for slot: int in 5:
		for suffix: String in [".json", ".json.bak", ".json.tmp"]: result["user://save_" + str(slot) + suffix] = fact("user://save_" + str(slot) + suffix)
	return result
func nonvisual(row: Dictionary) -> Dictionary:
	var result := row.duplicate(true)
	for key: String in VISUAL: result.erase(key)
	return result

func _exercise() -> bool:
	if not check(READY, "NOTREADY: Root must freeze static-only source/import closure"): return false
	if not track(FREEZE, FREEZE_SHA): return false
	var freeze := json(FREEZE)
	expected = freeze.get("source_sha256", {}).duplicate(true)
	if not check(not expected.is_empty(), "Independent finite frozen source authority, not current computed expectations"): return false
	for path: String in expected:
		if not track(path, expected[path]): return false
	api = load(API_PATH)
	if not check(api is GDScript and api.can_instantiate(), "Non-entry API actually compiles before any API access"): return false
	if not check(OS.get_cmdline_user_args() == PackedStringArray([api.FLAG]) and api.enabled(), "Explicit static candidate flag; no default/formal Field credit"): return false
	var ready: Dictionary = api.readiness()
	if not check(ready.get("ok") == true, "Actual frozen imported four-static source readiness", ready): return false
	var aliases_path := ProjectSettings.globalize_path("res://").path_join("../" + ALIASES).simplify_path()
	if not track(aliases_path, ALIASES_SHA): return false
	var aliases := json(aliases_path)
	var style_keys := {"young_gate_sentry": "young_gate", "old_veteran": "old_soldier", "squad_leader": "sergeant", "commander": "commander"}
	if not check(aliases.get("aliases", []).size() == 4 and aliases.get("pixel_change_from_parent") == false, "Four independently art-approved unchanged static aliases"): return false
	for alias: Dictionary in aliases.aliases:
		var style: Dictionary = ready.data.styles[style_keys[alias.identity]]
		if not check(style.idle_path == "res://" + String(alias.path).trim_prefix("game/") and FileAccess.get_sha256(style.idle_path) == alias.sha256 and api._legacy_calibrated_path(style.idle_path) == alias.expected_npc_node_calibrated_adult and style.walk_path == "" and style.walk_frames == 0, "Exact static alias SHA/prefix branch, no contact idle or invented walk " + alias.identity): return false
	var declared: Dictionary = api.source_paths()
	for path: String in declared:
		if not check(expected.has(path), "Every runtime static leaf independently frozen " + path): return false
	var harbour: Script = load(HARBOUR_CROWD)
	var district: Script = load(DISTRICT_CROWD)
	if not check(harbour is GDScript and harbour.can_instantiate() and district is GDScript and district.can_instantiate(), "Actual original pure crowd projectors compile"): return false
	var author := json(DISTRICT_AUTHOR)
	var seen: Dictionary = {}; var retained: Dictionary = {}
	for index: int in IDS.size():
		var id: String = IDS[index]
		var scene_path := LEGACY + id + "_scene.tres"
		var scene: SceneScript = load(scene_path) as SceneScript
		if not check(scene != null and expected.has(scene_path), "Fixed independent original canonical row source " + id): return false
		var rows: Array = scene.npcs.duplicate(true)
		if index in [0, 2]: rows.append_array(harbour.project(StringName(id)))
		var spec: Dictionary = author.get("districts", {}).get(id, {})
		if not spec.is_empty(): rows.append_array(district.project(spec.get("crowd", [])))
		var before := rows.duplicate(true)
		var output: Dictionary = api.project(StringName(id), rows)
		if not check(output.get("ok") == true and output.get("npcs", []).size() == rows.size() and rows == before, "Pure projection preserves input deep values and count " + id, output.get("error")): return false
		var actual_changes: Array[String] = []
		for i: int in rows.size():
			var old: Dictionary = rows[i]; var next: Dictionary = output.npcs[i]
			var npc_id: String = old.get("npc_id", "")
			if TARGETS.has(npc_id):
				if not check(not seen.has(npc_id) and TARGETS[npc_id][0] == index, "One intended original person in intended scene " + npc_id): return false
				seen[npc_id] = true; actual_changes.append(npc_id)
				var style: Dictionary = ready.data.styles[TARGETS[npc_id][1]]
				if not check(nonvisual(old) == nonvisual(next) and next.sprite_path == style.idle_path and next.get("walk_sprite_path", "") == old.get("walk_sprite_path", "") and next.get("portrait_path", "") == old.get("portrait_path", ""), "Only approved static art changes; all gameplay/scale/feet/patrol/primary and existing portrait unchanged " + npc_id): return false
				var duplicate: Dictionary = api.project(StringName(id), [old.duplicate(true), old.duplicate(true)])
				if not check(duplicate.get("ok") == false and duplicate.get("error") == "MILITARY_Y_DUPLICATE_ID:" + npc_id, "Target duplicate refuses explicitly " + npc_id): return false
				var wrong_scene: String = IDS[1] if index != 1 else IDS[0]
				var wrong: Dictionary = api.project(StringName(wrong_scene), [old.duplicate(true)])
				if not check(wrong.get("ok") == false and wrong.get("error") == "MILITARY_Y_WRONG_SCENE:" + npc_id, "Target cannot project into a different requested scene " + npc_id): return false
				var changed_old := old.duplicate(true); changed_old["sprite_path"] = "res://UNAPPROVED.png"
				var changed_before := changed_old.duplicate(true)
				var refused: Dictionary = api.project(StringName(id), [changed_old])
				if not check(refused.get("ok") == false and refused.get("error") == "MILITARY_Y_ORIGINAL_VISUAL_OR_MOVEMENT_CHANGED:" + npc_id and changed_old == changed_before, "Changed old source refuses without mutation " + npc_id): return false
			else:
				if not check(old == next, "Every non-target row remains entirely equal " + npc_id): return false
				if npc_id in KEEP: retained[npc_id] = true
		if not check(output.changed_ids == actual_changes, "Exact five-person change domain component " + id): return false
		records.append({"kind": "PURE_ROWS_NOT_FIELD", "id": id, "rows": rows.size(), "changed_ids": actual_changes})
	if not check(seen.size() == 5 and retained.size() == 7, "Exactly five static targets and all seven original patrols observed, not just table counts", {"targets": seen, "retained": retained}): return false
	return true

func _run() -> void:
	var began := Time.get_ticks_msec()
	var players_before := saves()
	var path := get_script().resource_path
	sources[path] = fact(path)
	var complete := _exercise()
	var source_after: Dictionary = {}
	for source: String in sources: source_after[source] = fact(source)
	var players_after := saves()
	if not check(sources == source_after and players_before == players_after, "Finite source and fifteen save facts unchanged, including absence"): complete = false
	if not check(Time.get_ticks_msec() - began < WHOLE_MS, "Fixed thirty-second pure CPU atom, no map setup"): complete = false
	var folder := "res://build/luoyang_military_static_cpu_20261019y/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var report := {"scope": "CANDIDATE_FOUR_STATIC_FIVE_PERSON_ROW_PROJECTION_ONLY", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "records": records, "source_before": sources, "source_after": source_after, "players_before": players_before, "players_after": players_after, "Field_or_native_calibration_verified": false, "true_walk_credit": false, "formal_default_credit": false}
	var file := FileAccess.open(folder.path_join("result.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report, "\t", true, true)); file.close()
	print(JSON.stringify({"checks": checks, "failures": failures, "complete": report.complete, "report_path": folder.path_join("result.json")}))
	quit(0 if report.complete else 1)
