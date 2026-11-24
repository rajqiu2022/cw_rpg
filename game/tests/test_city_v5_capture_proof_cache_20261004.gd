extends SceneTree
## Read-only source/resource test. No Field, publisher, save or formal writes.
const C = preload("res://scripts/city/luoyang_layered_v3_wall_v5_candidate_contract.gd")
const EXPECTED_C_SHA := "99d1a8b6f38e99ef1abb215fefdae54b29e874ec95aec716871b3a35744b110e"
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)

func _run() -> void:
	var router: Node = root.get_node("SceneRouter")
	var before: Dictionary = router.call("get_navigation_state").duplicate(true)
	_check(FileAccess.get_sha256(C.SELF_PATH).to_lower() == EXPECTED_C_SHA, "Exact current candidate source")
	for id: String in C.LEGACY_SHAS:
		var runs: int = C.capture_cache_stats().validation_runs
		var start: int = Time.get_ticks_usec()
		var accepted: bool = C.prepare(StringName(id))
		var cold_us: int = Time.get_ticks_usec() - start
		_check(accepted, "Strict first prepare: " + id + " " + "; ".join(C.errors()))
		_check(C.capture_cache_stats().validation_runs == runs + 1, "First prepare independently executed capture oracle: " + id)
		var hits: int = C.capture_cache_stats().hits
		start = Time.get_ticks_usec()
		_check(C.prepare(StringName(id)), "Fresh current/new/old catalogs and navigation still validate on cache hit: " + id)
		_check(C.capture_cache_stats().validation_runs == runs + 1 and C.capture_cache_stats().hits == hits + 1, "Only successful exact-byte capture proof reused: " + id)
		print("CITY_CAPTURE_CACHE_ACTUAL ", id, " cold_us=", cold_us, " warm_us=", Time.get_ticks_usec()-start, " stats=", JSON.stringify(C.capture_cache_stats()))
	# A wrong in-memory key cannot suppress the independently executed checker.
	var selected: String = "ch4_s0_luoyang_gate"
	var runs: int = C.capture_cache_stats().validation_runs
	C._capture_proofs[selected] = "STALE_OR_UNTRUSTED_PROOF"
	_check(C.prepare(StringName(selected)), "Stale proof revalidated exact current bytes")
	_check(C.capture_cache_stats().validation_runs == runs + 1, "Stale proof never counts as a hit")
	_check(not C.prepare(&"unknown_city") and C.capture_cache_stats().entries == 0, "Failed precondition clears all process-only successful proofs")
	_check(router.call("get_navigation_state") == before, "No gameplay or navigation mutation")
	print("CITY_CAPTURE_CACHE_RESULT ", JSON.stringify({"scope":"SOURCE_SAVED_RESOURCE_ONLY_NOT_FIELD_OR_VISUAL_APPROVAL", "checks":checks, "failures":failures, "candidate_source_sha256":FileAccess.get_sha256(C.SELF_PATH), "capture_checker_sha256":FileAccess.get_sha256(C.DETAIL_CHECKER_PATH), "stats":C.capture_cache_stats(), "disk_cache_written":false}))
	var until: int = Time.get_ticks_msec()+9000
	while Time.get_ticks_msec()<until: await process_frame
	root.get_node("AudioManager").call("stop_bgm", .15)
	await create_timer(.25).timeout
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	quit(0 if failures.is_empty() else 1)
