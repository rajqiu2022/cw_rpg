extends SceneTree
## Deterministic input preparation only. No approval, publication, Field or cutover.
## ROOT must first review ROOT250 and freeze the current E context/RELEASE entry.
const CONTEXT = preload("res://tests/helpers/joint_v15_v9e_source_context_oracle.gd")
const RELEASE = preload("res://tests/test_joint_world_luoyang_v15_release_20261005.gd")
const CONTEXT_PATH := "res://tests/helpers/joint_v15_v9e_source_context_oracle.gd"
const RELEASE_PATH := "res://tests/test_joint_world_luoyang_v15_release_20261005.gd"
const DOMAIN := "res://build/joint_world_luoyang_20261003_qa/"
const ROOT250 := DOMAIN + "250_v9e_full64_112_current_candidate_GPU_20261007/"
const FULL := "res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd"
const SURFACE := "res://scripts/dev/world_map_v15_v9e_material_refinement_surface.gd"
const IDENTITY := "V9E_SNOW_EXPOSURE_DAMP_FILM_DEPTH_WATER_VISUAL_EXPERIMENT"
const FLAG := "--prepare-v9e-release-frozen-inputs"
const CURRENT_FORMAT_MODE = preload("res://tests/helpers/joint_v15_current_save_load_20261008.gd")
const KNOWN_CITIES: Array[String] = ["ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen", "ch4_s2_canal_docks", "ch4_s3_luoyang_market"]
var errors: Array[String] = []
var retained: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	if not ok: errors.append(label)
	return ok

func _hash(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value.to_lower():
		if character not in "0123456789abcdef": return false
	return true

func _number(value: Variant, expected: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == expected

func _positive_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) > 0 and float(value) == floor(float(value))

func _retain(path: String, expected: Variant = null) -> String:
	if not _check(FileAccess.file_exists(path), "required existing input: " + path): return ""
	var sha: String = FileAccess.get_sha256(path).to_lower()
	if not _check(_hash(sha), "actual SHA256: " + path): return ""
	if expected != null and not _check(_hash(expected) and sha == String(expected).to_lower(), "exact frozen bytes: " + path): return ""
	if retained.has(path) and not _check(retained[path] == sha, "input stable between reads: " + path): return ""
	retained[path] = sha
	return sha

func _bound(path: String, expected: Variant) -> String:
	if not _check(_hash(expected), "required literal 64hex frozen SHA: " + path): return ""
	return _retain(path, expected)

func _json(path: String) -> Dictionary:
	if _retain(path).is_empty(): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not _check(value is Dictionary and not value.is_empty(), "actual nonempty JSON dictionary: " + path): return {}
	return value

func _wrapper_ready() -> Dictionary:
	var before: Dictionary = _json(ROOT250 + "before.json")
	var after: Dictionary = _json(ROOT250 + "after.json")
	_check(before.get("entry") == FULL and typeof(before.get("gpu")) == TYPE_BOOL and before.get("gpu") == true, "literal ROOT250 current E actual GPU entry")
	_check(_number(after.get("actual_os_exit"), 0), "ROOT250 must have naturally recorded actual OS0")
	for key: String in ["source_changes", "player_file_changes"]:
		var changes: Variant = after.get(key)
		_check(changes is Array and changes.is_empty(), "ROOT250 actual zero " + key)
	_check(_positive_integer(after.get("actual_wrapper_pid")), "actual recorded wrapper PID")
	_check(after.get("after_utc") is String and not String(after.get("after_utc", "")).is_empty(), "actual recorded process completion time")
	var players: Variant = before.get("player_files")
	_check(players is Array and players.size() == 15, "ROOT250 original snapshot contains all fifteen player main/bak/tmp paths")
	var sources: Variant = before.get("sources")
	if _check(sources is Array and not sources.is_empty(), "ROOT250 actual source snapshot"):
		var seen: Dictionary = {}
		for value: Variant in sources:
			if not _check(value is Dictionary, "typed ROOT250 source snapshot"): continue
			var path: Variant = value.get("path")
			if not _check(path is String and not String(path).is_empty() and not seen.has(path), "unique ROOT250 snapshot source path"): continue
			seen[path] = true
			_bound(path, value.get("sha256"))
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			_check(file != null and _number(value.get("bytes"), file.get_length() if file != null else -1), "exact ROOT250 snapshot file size: " + String(path))
			if file != null: file.close()
		var full_bound: bool = false
		for path: String in seen:
			var normalized: String = path.replace("\\", "/").simplify_path()
			if ProjectSettings.localize_path(normalized) == FULL: full_bound = true
		_check(full_bound, "ROOT250 snapshot explicitly bound the actual E FULL executor")
	for name: String in ["stdout.log", "stderr.log"]:
		var path: String = ROOT250 + name
		if _retain(path).is_empty(): continue
		for line: String in FileAccess.get_file_as_string(path).split("\n"):
			var text: String = line.strip_edges()
			_check(not (text.begins_with("ERROR:") or text.begins_with("SCRIPT ERROR:") or text.begins_with("Parse Error:") or text.begins_with("SHADER ERROR:")), "ROOT250 error-free actual log line: " + name)
	return {"before_path": ROOT250 + "before.json", "before_sha256": retained.get(ROOT250 + "before.json", ""), "after_path": ROOT250 + "after.json", "after_sha256": retained.get(ROOT250 + "after.json", ""), "actual_os_exit": after.get("actual_os_exit"), "scope": "CAPTURE_PROVENANCE_ONLY_NOT_RELEASE_OR_VISUAL_APPROVAL"}

func _prepare() -> Dictionary:
	var wrapper: Dictionary = _wrapper_ready()
	if not errors.is_empty(): return {}
	var context_sha: String = _retain(CONTEXT_PATH)
	var release_sha: String = _retain(RELEASE_PATH)
	_check(_hash(RELEASE.RELEASE_FINAL_CONTEXT_SHA) and RELEASE.RELEASE_FINAL_CONTEXT_SHA == context_sha and RELEASE.ORACLE_PATH == CONTEXT_PATH, "RELEASE explicitly binds this actual final E context; PENDING refused")
	_check(CONTEXT.WORLD_SOURCE == "res://data/maps/world_map_v15_complete_v9c_source.json" and CONTEXT.WORLD_ROOT == "res://art/maps/world_map_v15_complete_v9c/", "known current E staging source and root")
	_check(CONTEXT.V9C_EXECUTION_PINS.size() == 8 and CONTEXT.V9C_EXECUTION_PINS.has(FULL) and CONTEXT.V9C_EXECUTION_PINS.has(SURFACE), "exact E and inherited eight execution pins")
	var execution: Dictionary = CONTEXT.V9C_EXECUTION_PINS.duplicate(true)
	for path: String in execution: _bound(path, execution[path])
	var final: Dictionary = CONTEXT.V9C_FINAL_PIN_STATE.duplicate(true)
	var paths: Array[String] = [CONTEXT.WORLD_SOURCE, CONTEXT.WORLD_ROOT + "art_contract.json", CONTEXT.WORLD_ROOT + "whole_actual_capture.json", FULL, CONTEXT.WORLD_ROOT + "terrain_height.rf"]
	_check(CONTEXT.V9C_FINAL_PATHS == paths and final.size() == 5, "exact five known current E final artifact paths")
	for path: String in paths: _bound(path, final.get(path))
	var derived: Dictionary = CONTEXT.V9C_DERIVED_PIN_STATE.duplicate(true)
	_check(derived.size() == 4, "exact four pinned derived inputs")
	for role: String in ["height_rf", "terrain_mesh", "source_topology", "derivation_report"]:
		var row: Variant = derived.get(role)
		if not _check(row is Dictionary and row.size() == 2 and row.get("path") is String, "typed exact derived input: " + role): continue
		_bound(row.path, row.get("sha256"))
	if not errors.is_empty(): return {}
	var source: Dictionary = _json(CONTEXT.WORLD_SOURCE)
	var manifest: Dictionary = _json(CONTEXT.WORLD_ROOT + "art_contract.json")
	var whole: Dictionary = _json(CONTEXT.WORLD_ROOT + "whole_actual_capture.json")
	_check(source.get("status") == "ART_ASSETS_READY" and _number(source.get("schema_version"), 15), "current actual ready V15 source")
	_check(manifest.get("capture_protocol") == CONTEXT.WORLD_PROTOCOL and manifest.get("source_contract_path") == CONTEXT.WORLD_SOURCE and manifest.get("status") == "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA", "current whole candidate manifest, never old approval")
	_check(whole.get("capture_protocol") == CONTEXT.WORLD_PROTOCOL and whole.get("scope") == "V9C_FULL64_112SEAMS_DERIVED_RF_NEW_PROTOCOL_NOT_FORMAL_APPROVED" and whole.get("status") == "V9C_FULL64_112SEAMS_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_FIELD_REVIEW", "actual whole capture technical scope, not RELEASE credit")
	for record: Dictionary in [source, manifest, whole]:
		var revision: Variant = record.get("v9e_revision_evidence")
		_check(record.get("material_revision_identity") == IDENTITY and revision is Dictionary and revision.get("surface") == {"path": SURFACE, "sha256": execution[SURFACE]}, "actual E material identity/source; no ancestral D substitution")
	_check(source.get("v9e_revision_evidence") == manifest.get("v9e_revision_evidence") and source.get("v9e_revision_evidence") == whole.get("v9e_revision_evidence"), "same actual E revision in Source/M/report")
	var catalog: Variant = manifest.get("asset_sha256")
	var graph: Variant = manifest.get("source_graph")
	if _check(catalog is Dictionary and graph is Dictionary, "typed actual manifest catalog/source graph"):
		for path: String in execution:
			_check(catalog.get(path) == execution[path] and graph.get(path) == execution[path], "actual current eight source/manifest execution bindings: " + path)
	var binding: Variant = manifest.get("whole_actual_capture")
	_check(binding is Dictionary and binding.get("path") == paths[2] and binding.get("sha256") == final[paths[2]] and catalog is Dictionary and catalog.get(paths[2]) == final[paths[2]], "actual final whole report bound to manifest catalog")
	_check(CONTEXT.CITY_IDS == KNOWN_CITIES and CONTEXT.CITY_ROOT == "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/" and CONTEXT.OUTSKIRTS_ROOT == "res://art/maps/world_map_v15_outskirts_complete_v5_retry1/", "known four current city and three outskirts roots")
	var artifacts: Dictionary = {}
	for path: String in [CONTEXT.WORLD_SOURCE, CONTEXT.WORLD_ROOT + "art_contract.json"]: artifacts[path] = _bound(path, final[path])
	for id: String in KNOWN_CITIES:
		var path: String = CONTEXT.CITY_ROOT + id + "/art_contract.json"
		artifacts[path] = _retain(path)
	for biome: String in ["bamboo", "forest", "marsh"]:
		var path: String = CONTEXT.OUTSKIRTS_ROOT + biome + "/art_contract.json"
		artifacts[path] = _retain(path)
	_check(artifacts.size() == 9, "exact manifest9 set, not an old template or successful subset")
	if not errors.is_empty(): return {}
	var result: Dictionary={"schema": 1, "scope": "JOINT_FROZEN_CANDIDATE_INPUTS", "artifact_sha256": artifacts, "execution_sha256": execution, "v9c_artifact_sha256": final, "derived_geometry_inputs": derived, "release_source_context_sha256": context_sha, "release_entry_sha256": release_sha, "capture_wrapper_evidence": wrapper, "preparation_scope": "INPUT_FREEZE_ONLY_NOT_FIELD_RELEASE_VISUAL_OR_PRODUCTION_APPROVAL"}
	if "--fresh-start-only" in OS.get_cmdline_user_args():
		result.scope=CURRENT_FORMAT_MODE.FROZEN_SCOPE
		result.merge(CURRENT_FORMAT_MODE.mode_metadata(),true)
	return result

func _run() -> void:
	_check(OS.get_cmdline_user_args() in [PackedStringArray([FLAG]),PackedStringArray([FLAG,"--fresh-start-only"])], "explicit prepare-only mode flags; no publication, approval or formal arguments")
	var value: Dictionary = _prepare() if errors.is_empty() else {}
	for path: String in retained:
		_check(FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower() == retained[path], "all preparation inputs remain exact before output: " + path)
	if not errors.is_empty() or value.is_empty():
		for error: String in errors: push_error("V9E frozen inputs refused: " + error)
		quit(1)
		return
	var directory: String = DOMAIN + "v9e_release_frozen_%d_%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec(), OS.get_process_id()]
	var path: String = directory + "frozen_inputs.json"
	if DirAccess.dir_exists_absolute(directory) or FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("V9E unique evidence directory unavailable; no overwrite")
		quit(1)
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("V9E frozen input output cannot open")
		quit(1)
		return
	var encoded: String = JSON.stringify(value, "\t", true)
	file.store_string(encoded)
	file.flush()
	var io_error: Error = file.get_error()
	file.close()
	var actual: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var expected: Variant = JSON.parse_string(encoded)
	var valid: bool = io_error == OK and actual is Dictionary and actual == expected and FileAccess.get_file_as_string(path) == encoded and FileAccess.get_sha256(path).to_lower() == encoded.sha256_text()
	if not valid:
		push_error("V9E frozen input output readback failed; failed evidence retained")
		quit(1)
		return
	print("V9E_RELEASE_FROZEN_INPUTS_READY path=", path, " sha256=", FileAccess.get_sha256(path), " scope=INPUT_PREPARATION_ONLY_NOT_APPROVAL")
	quit(0)
