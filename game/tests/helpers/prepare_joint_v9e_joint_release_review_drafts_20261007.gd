extends SceneTree
## Evidence-bound DRAFTS ONLY. Never writes either data/maps approval document,
## calls approval_error/activation, signs for ROOT, or runs Field/gameplay.
const GATE = preload("res://scripts/dev/joint_world_city_v15_release_acceptance.gd")
const RELEASE = preload("res://tests/test_joint_world_luoyang_v15_release_20261005.gd")
const CONTEXT = preload("res://tests/helpers/joint_v15_v9e_source_context_oracle.gd")
const CURRENT_FORMAT = preload("res://tests/helpers/joint_v15_current_save_load_20261008.gd")
const DOMAIN := "res://build/joint_world_luoyang_20261003_qa/"
const FLAG := "--prepare-v9e-joint-release-review-drafts"
const KEYS: Array[String] = ["headless-wrapper", "headless-result", "gpu-wrapper", "gpu-result", "frozen-inputs"]
var arguments: Dictionary = {}
var retained: Dictionary = {}
var errors: Array[String] = []
var fresh_start_only: bool = false

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	if not ok: errors.append(label)
	return ok

func _path(value: Variant, directory: bool = false) -> bool:
	return value is String and value.begins_with(DOMAIN) and not ".." in value and not "\\" in value and (value.ends_with("/") if directory else value.ends_with(".json"))

func _retain(path: String, expected: Variant = null) -> Dictionary:
	if not _check(path.begins_with("res://") and not ".." in path and FileAccess.file_exists(path), "present canonical evidence: " + path): return {}
	var sha: String = FileAccess.get_sha256(path).to_lower()
	if not _check(GATE._hash(sha) and (expected == null or (GATE._hash(expected) and sha == String(expected).to_lower())), "actual exact SHA: " + path): return {}
	if retained.has(path) and not _check(retained[path] == sha, "same evidence bytes between reads: " + path): return {}
	retained[path] = sha
	return {"path": path, "sha256": sha}

func _json(path: String) -> Dictionary:
	if _retain(path).is_empty(): return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not _check(value is Dictionary and not value.is_empty(), "typed nonempty evidence JSON: " + path): return {}
	return value

func _parse() -> bool:
	var flags: int = 0
	var fresh_flags: int = 0
	for argument: String in OS.get_cmdline_user_args():
		if argument == FLAG:
			flags += 1
			continue
		if argument == "--fresh-start-only":
			fresh_flags += 1
			fresh_start_only = true
			continue
		var matched: bool = false
		for key: String in KEYS:
			var prefix: String = "--" + key + "="
			if not argument.begins_with(prefix): continue
			matched = true
			_check(not arguments.has(key), "no repeated argument: " + key)
			arguments[key] = argument.trim_prefix(prefix)
		_check(matched, "known prepare-only argument; approval/formal flags forbidden: " + argument)
	_check(flags == 1 and arguments.size() == KEYS.size(), "explicit prepare flag and all five exact evidence paths")
	_check(fresh_flags <= 1, "fresh-start mode must be explicit and cannot repeat")
	for key: String in KEYS: _check(_path(arguments.get(key), key.ends_with("wrapper")), "explicit QA-domain path: " + key)
	_check(arguments.get("headless-wrapper") != arguments.get("gpu-wrapper") and arguments.get("headless-result") != arguments.get("gpu-result"), "two separate actual processes/results, never one run twice")
	return errors.is_empty()

func _frozen(current: Dictionary) -> String:
	var path: String = arguments["frozen-inputs"]
	var frozen: Dictionary = _json(path)
	var context_sha: String = FileAccess.get_sha256(RELEASE.ORACLE_PATH).to_lower()
	_check(GATE._hash(RELEASE.RELEASE_FINAL_CONTEXT_SHA) and RELEASE.RELEASE_FINAL_CONTEXT_SHA == context_sha and frozen.get("release_source_context_sha256") == context_sha and current.get(RELEASE.ORACLE_PATH) == context_sha, "actual frozen current E context; PENDING and old context refused")
	_check(GATE._number(frozen.get("schema"), 1) and CURRENT_FORMAT.frozen_mode_matches(frozen,fresh_start_only), "actual explicit frozen input mode; fresh and historical scopes cannot mix")
	_check(frozen.get("execution_sha256") == CONTEXT.V9C_EXECUTION_PINS and frozen.get("execution_sha256") is Dictionary and frozen.execution_sha256.size() == 8, "same actual eight E/inherited execution pins")
	_check(frozen.get("v9c_artifact_sha256") == CONTEXT.V9C_FINAL_PIN_STATE and frozen.get("v9c_artifact_sha256") is Dictionary and frozen.v9c_artifact_sha256.size() == 5, "same actual five final capture pins")
	_check(frozen.get("derived_geometry_inputs") == CONTEXT.V9C_DERIVED_PIN_STATE and frozen.get("derived_geometry_inputs") is Dictionary and frozen.derived_geometry_inputs.size() == 4, "same actual four derived inputs")
	var expected_paths: Array[String] = [CONTEXT.WORLD_SOURCE, CONTEXT.WORLD_ROOT + "art_contract.json"]
	for id: String in CONTEXT.CITY_IDS: expected_paths.append(CONTEXT.CITY_ROOT + id + "/art_contract.json")
	for biome: String in ["bamboo", "forest", "marsh"]: expected_paths.append(CONTEXT.OUTSKIRTS_ROOT + biome + "/art_contract.json")
	var manifests: Variant = frozen.get("artifact_sha256")
	if _check(manifests is Dictionary and manifests.size() == 9 and expected_paths.size() == 9, "exact current nine frozen manifests"):
		for manifest: String in expected_paths:
			_check(GATE._hash(manifests.get(manifest)) and current.get(manifest) == manifests.get(manifest), "current full snapshot matches frozen manifest: " + manifest)
	for field: String in ["execution_sha256", "v9c_artifact_sha256"]:
		var pins: Variant = frozen.get(field)
		if pins is Dictionary:
			for input: String in pins: _retain(input, pins[input])
	if fresh_start_only or frozen.has("release_entry_sha256"): _check(frozen.get("release_entry_sha256") == current.get(GATE.RELEASE_ENTRY), "frozen actual RELEASE entry identity required for fresh mode")
	return String(retained.get(path, ""))

func _actual_run(mode: String, current: Dictionary, frozen_sha: String) -> Dictionary:
	var wrapper: String = arguments[mode + "-wrapper"]
	var result_path: String = arguments[mode + "-result"]
	var before: Dictionary = _json(wrapper + "before.json")
	var after: Dictionary = _json(wrapper + "after.json")
	var report: Dictionary = _json(result_path)
	_check(before.get("entry") == GATE.RELEASE_ENTRY and GATE._number(after.get("actual_os_exit"), 0) and GATE._positive_integer(after.get("actual_wrapper_pid")), "actual RELEASE wrapper entry/completed OS0: " + mode)
	_check(typeof(before.get("gpu")) == TYPE_BOOL and before.gpu == (mode == "gpu"), "actual separate wrapper rendering mode: " + mode)
	for key: String in ["source_changes", "player_file_changes"]:
		var changes: Variant = after.get(key)
		_check(changes is Array and changes.is_empty(), "actual zero wrapper " + key + ": " + mode)
	var players: Variant = before.get("player_files")
	_check(players is Array and players.size() == 15, "all fifteen exact player-file wrapper snapshots: " + mode)
	var run_args: Variant = before.get("user_arguments")
	_check(run_args is Array and "--candidate-before-cutover" in run_args and ("--qa-frozen-inputs=" + String(arguments["frozen-inputs"])) in run_args and (mode != "gpu" or "--qa-gpu-approved" in run_args), "actual explicit candidate/frozen/GPU invocation: " + mode)
	_check(run_args is Array and run_args.count("--fresh-start-only") == (1 if fresh_start_only else 0), "wrapper invocation matches explicit fresh/historical mode: " + mode)
	var phase_name: String = GATE.FRESH_START_PHASE if fresh_start_only else GATE.RELEASE_PHASE
	var scope_name: String = GATE.FRESH_START_SCOPE if fresh_start_only else "JOINT_RELEASE_RISK_STRATIFIED_NORMAL_GAMEPLAY_NOT_EXHAUSTIVE_FULL"
	_check(report.get("scope") == scope_name and report.get("phase") == phase_name and GATE._mode_metadata(report,fresh_start_only) and report.get("requested_phase") == "release" and GATE._release_flags(report), "actual complete explicit RELEASE scope; legacy/exhaustive false: " + mode)
	_check(GATE._true(report.get("completed")) and GATE._true(report.get("candidate_before_cutover")) and GATE._false(report.get("source_complete")) and GATE._false(report.get("dry_run")) and report.get("mode") == mode and GATE._number(report.get("failed"), 0) and GATE._number(report.get("failures"), 0), "actual current candidate RELEASE result, not partial/unit/formal: " + mode)
	var unfinished: Variant = report.get("unfinished_categories")
	_check(unfinished is Array and unfinished.is_empty(), "no omitted unfinished categories: " + mode)
	_check(report.get("frozen_inputs_path") == arguments["frozen-inputs"] and report.get("frozen_inputs_sha256") == frozen_sha and report.get("frozen_inputs_sha256_before") == frozen_sha, "actual same immutable input before/after run: " + mode)
	_check(report.get("oracle_path") == RELEASE.ORACLE_PATH and report.get("oracle_sha256") == RELEASE.RELEASE_FINAL_CONTEXT_SHA and report.get("executing_script_path") == GATE.RELEASE_ENTRY and String(report.get("executing_script_sha256", "")).to_lower() == current.get(GATE.RELEASE_ENTRY), "actual E context and RELEASE executor identities: " + mode)
	_check(GATE.matches_snapshot(report.get("source_sha256"), current), "actual result exact current complete source snapshot: " + mode)
	var directory: String = result_path.get_base_dir() + "/"
	for name: String in ["all_actual_sources_before.json", "all_actual_sources_after.json"]:
		_check(GATE.matches_snapshot(_json(directory + name), current), "actual retained full source snapshot: " + mode + "/" + name)
	# Reuse all existing pure predicates, without calling approval_error or writing
	# reviews. All nonhistorical semantics remain; explicit fresh mode substitutes
	# current-format real save/load for historical compatibility, never fake credit.
	_check(GATE._release_actual_evidence(report, current, mode, fresh_start_only), "all explicit-mode actual RELEASE evidence predicates: " + mode)
	var coverage: Variant = report.get("coverage")
	_check(coverage is Dictionary and GATE._complete_coverage(coverage, current, fresh_start_only), "all explicit-mode joint coverage predicates: " + mode)
	var records: Dictionary = {}
	for role: String in ["stdout", "stderr"]:
		var path: String = wrapper + role + ".log"
		records[role] = _retain(path)
		_check(GATE._clean_actual_log(path), "existing error-free full actual log predicate: " + mode + "/" + role)
	var summary_count: int = 0
	var pattern: RegEx = RegEx.new()
	_check(pattern.compile("(?m)^JOINT_WORLD_CITY_QA: [0-9]+ checks / 0 failures; phase=%s; Field=true GPU=(true|false); complete=true visual=NOT_REVIEWED; output=([^\\r\\n]+)\\r?$" % phase_name) == OK, "exact explicit-mode completion record parser")
	for match_value: RegExMatch in pattern.search_all(FileAccess.get_file_as_string(wrapper + "stdout.log")):
		if match_value.get_string(1) == ("true" if mode == "gpu" else "false") and match_value.get_string(2) == directory: summary_count += 1
	_check(summary_count == 1, "same wrapper stdout binds this exact complete result directory once: " + mode)
	records["result"] = _retain(result_path)
	records["actual_os_exit_code"] = after.get("actual_os_exit")
	records["wrapper_before"] = _retain(wrapper + "before.json")
	records["wrapper_after"] = _retain(wrapper + "after.json")
	records["manual_complete_stderr_and_exit_warning_review_required"] = true
	if fresh_start_only:
		_check(GATE._fresh_actual_run(records,report,{"frozen_inputs_path":arguments["frozen-inputs"],"frozen_inputs_sha256":frozen_sha},mode), "fresh actual wrapper/frozen binding is complete: " + mode)
	return records

func _write(path: String, value: Dictionary) -> bool:
	if not path.begins_with(DOMAIN) or FileAccess.file_exists(path): return false
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	var encoded: String = JSON.stringify(value, "\t", true)
	file.store_string(encoded)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	return error == OK and FileAccess.get_file_as_string(path) == encoded and FileAccess.get_sha256(path).to_lower() == encoded.sha256_text() and JSON.parse_string(FileAccess.get_file_as_string(path)) == JSON.parse_string(encoded)

func _run() -> void:
	var current: Dictionary = GATE.snapshot() if _parse() else {}
	_check(not current.is_empty(), "current complete independent GATE.snapshot, never old result-derived whitelist")
	var frozen_sha: String = _frozen(current) if errors.is_empty() else ""
	var runs: Dictionary = {}
	if errors.is_empty():
		for mode: String in ["headless", "gpu"]: runs[mode] = _actual_run(mode, current, frozen_sha)
	if errors.is_empty():
		var headless_after: Dictionary = _json(arguments["headless-wrapper"] + "after.json")
		var gpu_after: Dictionary = _json(arguments["gpu-wrapper"] + "after.json")
		_check(GATE._positive_integer(headless_after.get("actual_wrapper_pid")) and GATE._positive_integer(gpu_after.get("actual_wrapper_pid")) and int(headless_after.actual_wrapper_pid) != int(gpu_after.actual_wrapper_pid), "two distinct actual wrapper processes, never one process relabelled")
	if errors.is_empty():
		_check(GATE.matches_snapshot(GATE.snapshot(), current), "entire source/art/gameplay snapshot unchanged throughout draft preparation")
		for path: String in retained: _check(FileAccess.get_sha256(path).to_lower() == retained[path], "all actual run/frozen evidence unchanged: " + path)
	if not errors.is_empty():
		for error: String in errors: push_error("V9E review drafts refused: " + error)
		quit(1)
		return
	var common: Dictionary = {"schema_version": 1, "world_coordinate_version": 15, "city_layout_version": 3, "status": "DRAFT_NOT_APPROVED", "approved": false, "production_approved": false, "reviewer_role": "producer/root", "reviewer": "", "root_signature_present": false, "asset_sha256": current, "frozen_inputs_path": arguments["frozen-inputs"], "frozen_inputs_sha256": frozen_sha, "legacy_full_executed": false, "exhaustive_2687_normal_input_executed": false, "actual_runs": runs, "manual_complete_logs_and_actual_png_review_required": true}
	var phase_name: String = GATE.FRESH_START_PHASE if fresh_start_only else GATE.RELEASE_PHASE
	if fresh_start_only:
		common.merge(CURRENT_FORMAT.mode_metadata(),true)
		common["scope"] = GATE.FRESH_START_SCOPE
		common["phase"] = phase_name
	var technical: Dictionary = common.duplicate(true)
	technical.merge({"technical_approved": false, "release_complete": true, "phase": phase_name, "selection_path": GATE.RELEASE_SELECTION_PATH, "selection_sha256": GATE.RELEASE_SELECTION_SHA, "review_method": "PENDING_ROOT_INDEPENDENT_TECHNICAL_REVIEW", "required_review_method": "independent_risk_stratified_release_normal_gameplay_field_input"})
	var visual: Dictionary = common.duplicate(true)
	visual.merge({"visual_approved": false, "actual_png_individual_review_performed": false, "review_method": "PENDING_ROOT_ACTUAL_PNG_INDIVIDUAL_REVIEW", "required_review_method": "actual_world_city_outskirts_png_individual_review"})
	var directory: String = DOMAIN + "v9e_joint_release_review_drafts_%d_%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec(), OS.get_process_id()]
	if DirAccess.dir_exists_absolute(directory) or DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("V9E unique draft directory unavailable; no overwrite")
		quit(1)
		return
	var ok: bool = _write(directory + "technical_review_DRAFT.json", technical)
	ok = _write(directory + "visual_review_DRAFT.json", visual) and ok
	if not ok:
		push_error("V9E draft write/readback failure; failed evidence retained, never approved")
		quit(1)
		return
	print("V9E_JOINT_RELEASE_REVIEW_DRAFTS_READY directory=", directory, " approved=false formal_review_written=false")
	quit(0)
