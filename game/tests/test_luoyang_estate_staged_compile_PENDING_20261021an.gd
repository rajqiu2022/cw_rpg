extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## ROOT-only autoload-context compile gate. No candidate instantiated or invoked.
const COMPILE_READY: bool = false
const FIXTURE: String = "res://build/luoyang_estate_courtyard_20261021an_qa01/staged_compile_fixture_PENDING.json"
const FIXTURE_SHA: String = "PENDING_EXACT_STAGE_CODE_PINS"
const LIMIT_MS: int = 30000
const BASE_PATH: String = "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
const BASE_SHA: String = "a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895"

func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists": false, "sha256": "ABSENT", "bytes": 0, "mtime_seconds": "0"}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null: return {"exists": true, "read_error": true}
	var size: int = file.get_length(); file.close()
	return {"exists": true, "sha256": FileAccess.get_sha256(path), "bytes": size, "mtime_seconds": str(FileAccess.get_modified_time(path))}

func _json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func _compile() -> bool:
	if not check(COMPILE_READY and OS.get_cmdline_user_args().is_empty(), "Frozen stage-only compilation, not stale AM or candidate activation flag"): return false
	if not track(BASE_PATH, BASE_SHA) or not track(FIXTURE, FIXTURE_SHA): return false
	var fixture: Dictionary = _json(FIXTURE)
	if not check(fixture.get("status") == "ROOT_FROZEN_AN_FINAL_STAGED_AUTOLOAD_COMPILE" and fixture.get("code_sources", {}).size() == 12, "Exactly eleven final code targets plus true index alternative"): return false
	if not track(fixture.stage_receipt.path, fixture.stage_receipt.sha256): return false
	var stage: Dictionary = _json(fixture.stage_receipt.path)
	if not check(stage.get("status") == "AN_STAGED_SOURCE_READY_NOT_DEPLOYED_NOT_FIELD_PASS" and stage.get("targets", []).size() == 19, "Actual final nineteen-target stage, no production deployment implied"): return false
	var exact: Dictionary = {}
	for row: Dictionary in stage.targets:
		if String(row.target).ends_with(".gd"):
			if not check(not exact.has(row.candidate_path), "One distinct staged code candidate"): return false
			exact[row.candidate_path] = row.candidate_sha256
	exact[stage.true_index_candidate_path] = stage.family_index_true_sha256
	if not check(exact.size() == 12 and exact == fixture.code_sources, "Independent fixture pins entire actual staged code domain"): return false
	for path: String in exact:
		if not track(path, exact[path]): return false
	if not check(root.get_node_or_null("GameState") != null and root.get_node_or_null("SceneRouter") != null and current_scene == null, "Autoloads established before deferred load; no Field or fake owner"): return false
	var self_path: String = get_script().resource_path
	if not track(self_path, FileAccess.get_sha256(self_path)): return false
	for path: String in exact:
		var began_us: int = Time.get_ticks_usec()
		var candidate: Script = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		if not check(candidate != null and candidate.resource_path == path and candidate.can_instantiate(), "Final staged Script compiles in real autoload domain " + path): return false
		records.append({"path": path, "sha256": exact[path], "can_instantiate": true, "instantiated": false, "api_invoked": false, "elapsed_us": Time.get_ticks_usec() - began_us})
		if Time.get_ticks_msec() >= deadline: return check(false, "Fixed30s new-code-only compile budget")
		await process_frame
	return true

func _run() -> void:
	var began: int = Time.get_ticks_msec(); deadline = began + LIMIT_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves()
	var state_before: Dictionary = {"flags": root.get_node("GameState").get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict").duplicate(true), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true)}
	var complete: bool = await _compile()
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after: Dictionary = saves()
	var state_after: Dictionary = {"flags": root.get_node("GameState").get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict").duplicate(true), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true)}
	check(source_before == source_after, "All staged source facts unchanged")
	check(players_before.size() == 15 and players_before == players_after and state_before == state_after, "No save/state writes from script compilation")
	check(Time.get_ticks_msec() - began < LIMIT_MS, "Whole staged compile fixed30s")
	var folder: String = "res://build/luoyang_estate_courtyard_20261021an_qa01/staged_compile_%d" % OS.get_process_id()
	if DirAccess.dir_exists_absolute(folder): printerr("AN_COMPILE_REPORT_EXISTS"); quit(2); return
	DirAccess.make_dir_recursive_absolute(folder)
	var output: FileAccess = FileAccess.open(folder.path_join("result.json"), FileAccess.WRITE)
	if output == null: printerr("AN_COMPILE_REPORT_OPEN_FAILED"); quit(2); return
	var result: Dictionary = {"scope": "AN_FINAL_STAGED_AUTOLOAD_CONTEXT_COMPILE_ONLY_NOT_RUNTIME_OR_FIELD", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "budget_ms": LIMIT_MS, "records": records, "source_before": source_before, "source_after": source_after, "players_before": players_before, "players_after": players_after, "state_before": state_before, "state_after": state_after, "candidates_instantiated_or_api_invoked": false, "canonical_deployment": false}
	output.store_string(JSON.stringify(result, "\t")); output.close()
	print(JSON.stringify({"report_path": folder.path_join("result.json"), "complete": result.complete, "checks": checks, "failures": failures}))
	quit(0 if result.complete else 1)
