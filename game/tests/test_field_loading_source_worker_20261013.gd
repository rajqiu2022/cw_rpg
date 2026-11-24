extends "res://tests/test_field_loading_key_exit_cleanup_20261013.gd"
## Limited source-worker/cancellation test. No cold city validation or city Field.
const CITY := "res://data/scenes/ch4_s0_luoyang_gate.tres"
const CONTRACT_PATH := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const CURRENT_PINS := {
	CONTRACT_PATH:"36c0e782d5747a2a022c655d3f4a6804d90de5956a64e5c9d932876770da5b50",
	"res://scripts/autoload/scene_router.gd":"a51f2b769cca1d9541a890c5b31ef75fd240fcb7f70bad1b8e401b117ea0cbff",
	"res://scripts/field/field_walkable_controller.gd":"a5e8d4097193c62910a5402ec87b887d907677d503738d7296fdbdd429794e70",
	"res://scripts/autoload/loading_manager.gd":"cca11b27788193b0aa11d6ecd3de9c048c1858860264a9bf960eadcadcc5f896",
	"res://scripts/ui/loading_screen.gd":"60a8bade4696dc3b8d0736561bd0a6c19ccc4637540a0fcca366171d0c9850da",
	"res://tests/test_field_loading_key_exit_cleanup_20261013.gd":"028acdf8c2ae12e7305a1624c9a7fbe40a04b127472ef18c3cb992c196c15d99",
	CITY:"872b4ff502f4f8c88eb238a25e3bcdfcb37bec5f71d2e84906ad53f751c90e17",
	"res://data/maps/luoyang_enclosure_v11_candidates/ch4_s0_luoyang_gate_layout.tres":"b4a50f1925abf1054ee2166a09b7b2a1080b0210544eb52a7f82edb70ec1d988",
	"res://art/maps/luoyang_enclosure_v11/ch4_s0_luoyang_gate/walk.png":"779441a6f70d071c0b5e2b8c22fa4fe782f00e13aa2dc693a68742f1fde5dbc3",
}
var source_rows: Array[Dictionary] = []
var portal_done := false

func _portal_request(router: Node) -> void:
	await router.call("go_field_from_portal", &"ch4_s0_luoyang_gate")
	portal_done = true

func _exercise_sources(contract: Script) -> void:
	var scene: Resource = load(CITY) as Resource
	if not _check(scene != null and scene.resource_path == CITY, "actual frozen canonical city Resource loaded without prepare"): return
	var paths: Dictionary = contract.call("_transition_sources", scene, false)
	if not _check(not paths.is_empty() and paths.has(CITY) and paths.has(CONTRACT_PATH), "real production complete source-path collector"): return
	var before: Dictionary = contract.call("transition_validation_state")
	var job: RefCounted = contract.TransitionSourceJob.new()
	job.set("paths", paths.keys())
	var started := Time.get_ticks_msec()
	var frame := Engine.get_process_frames()
	var task := WorkerThreadPool.add_task(Callable(job, "run"), false, "QA actual city source SHA")
	if not _check(task >= 0, "real source SHA task dispatched"): return
	var active := not WorkerThreadPool.is_task_completed(task)
	var completed := await _wait(func() -> bool: return WorkerThreadPool.is_task_completed(task), "actual source worker")
	WorkerThreadPool.wait_for_task_completion(task)
	var hashes: Dictionary = job.get("hashes")
	_check(completed and active and Engine.get_process_frames() > frame and hashes.size() == paths.size(), "real source worker joins with complete hashes and natural frames")
	var typed := hashes.size() == paths.size()
	for path: Variant in paths:
		var sha: Variant = hashes.get(path)
		typed = typed and typeof(path) == TYPE_STRING and typeof(sha) == TYPE_STRING and sha.length() == 64
	_check(typed and hashes.get(CITY) == CURRENT_PINS[CITY] and hashes.get(CONTRACT_PATH) == CURRENT_PINS[CONTRACT_PATH], "actual worker native String SHA and current canonical/code binding")
	_check(contract.call("transition_validation_state") == before, "direct real worker does not invent a city proof or execute cold validation")
	source_rows.append({"kind":"ACTUAL_COMPLETE_SOURCE_WORKER_ONLY", "task_id":task, "active":active, "start_frame":frame, "finish_frame":Engine.get_process_frames(), "started_msec":started, "finished_msec":Time.get_ticks_msec(), "sources":hashes, "validation_before":before, "validation_after":contract.call("transition_validation_state")})
	job = null
	# Only this unique QA output fixture is mutated; no production source is edited.
	var fixture := output + "owned_source_change.txt"
	var file := FileAccess.open(fixture, FileAccess.WRITE)
	if not _check(file != null, "owned isolated source fixture created"): return
	file.store_string("SOURCE_BEFORE"); file.close(); file = null
	var expected := FileAccess.get_sha256(fixture)
	_check(contract.call("_transition_sources_match", {fixture:expected}) == true, "unchanged real owned source accepted by production source predicate")
	file = FileAccess.open(fixture, FileAccess.WRITE)
	if not _check(file != null, "owned fixture reopened"): return
	file.store_string("SOURCE_AFTER"); file.close(); file = null
	var changed := FileAccess.get_sha256(fixture)
	var rejected: Variant = contract.call("_transition_sources_match", {fixture:expected})
	var errors: Array = contract.call("errors")
	_check(typeof(rejected) == TYPE_BOOL and not rejected and expected != changed and errors.has("Transition validated source changed: " + fixture), "changed actual owned source rejected; exact intentional error retained")
	source_rows.append({"kind":"OWNED_FILE_SOURCE_CHANGE_REJECTION", "path":fixture, "before_sha":expected, "after_sha":changed, "accepted":rejected, "errors":errors.duplicate(), "not_city_proof_credit":true})

func _exercise_cancel(loading: Node, router: Node, contract: Script) -> void:
	var accepted: Variant = router.call("go_field_smart", MAP_ID)
	if not _check(typeof(accepted) == TYPE_BOOL and accepted, "small original public Field startup accepted"): return
	if not await _wait(func() -> bool: return _ready_field(loading), "small Field"): return
	var held := current_scene
	var before := _snapshot(held)
	var validation_before: Dictionary = contract.call("transition_validation_state")
	var started := Time.get_ticks_msec()
	_portal_request(router)
	var token: int = router.get("_city_transition_token")
	_check(token > 0 and loading.get("_field_preparation_token") == token and loading.get("_external_token") == token and loading.get("_external_active") == true and held.process_mode == Node.PROCESS_MODE_DISABLED, "real public portal holds old Field and exact Loading preparation token")
	if not await _wait(func() -> bool: return contract.get("_live_source_task") >= 0, "real Router source worker active before cold"): return
	var task: int = contract.get("_live_source_task")
	var worker: RefCounted = contract.get("_live_source_job") as RefCounted
	var worker_active := task >= 0 and worker != null and not WorkerThreadPool.is_task_completed(task)
	var held_during := _snapshot(held)
	var cancel_frame := Engine.get_process_frames()
	var canceled_before: Dictionary = contract.call("transition_validation_state")
	_check(worker_active and canceled_before.full_validations_total == validation_before.full_validations_total and not canceled_before.active, "cancel while actual source worker active, before any full cold proof")
	# Exact scoped cancellation APIs, then normal old-Field restoration/hide.
	router.call("end_field_transition_validation", token)
	loading.call("finish_field_preparation", token)
	if not await _wait(func() -> bool: return portal_done, "canceled Router coroutine returns"): return
	var after := _snapshot(held)
	var validation_after: Dictionary = contract.call("transition_validation_state")
	_check(after.current and after.field_id == before.field_id and after.player_id == before.player_id and after.process_mode == before.process_mode and after.rebuilding == false, "cancellation retains exact old Field/player and restores original mode")
	_check(router.get("_city_transition_token") == 0 and router.get("_city_transition_live") == false and router.get("_portal_preparing") == false and loading.get("_transition_active") == false and loading.get("_field_preparation_token") == 0 and loading.get("_external_active") == false, "canceled token cannot become live or fall back into a new transition")
	_check(validation_after.active == false and validation_after.source_worker_active == false and validation_after.full_validations_total == validation_before.full_validations_total and contract.get("_live_source_token") == 0 and contract.get("_live_source_task") == -1 and contract.get("_live_source_job") == null, "ownership canceled, task joined by production cancel, CPU buffers/proof cleared with no cold validation")
	var finalized: Variant = await router.call("finalize_field_transition_sources", &"ch4_s0_luoyang_gate", token)
	_check(typeof(finalized) == TYPE_BOOL and not finalized, "captured canceled mandatory token cannot finalize")
	source_rows.append({"kind":"ACTUAL_LOADING_ROUTER_SOURCE_WORKER_CANCEL", "token":token, "task_id":task, "worker_active_at_cancel":worker_active, "started_msec":started, "finished_msec":Time.get_ticks_msec(), "cancel_frame":cancel_frame, "finish_frame":Engine.get_process_frames(), "before":before, "held":held_during, "after":after, "validation_before":validation_before, "validation_at_cancel":canceled_before, "validation_after":validation_after, "canceled_finalized":finalized})
	worker = null

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended", true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true, "checkpoint held before first await until quit")
	var players := _players()
	var save: Node = root.get_node("SaveManager")
	var slot: Variant = save.get("active_slot")
	_check("--field-loading-key" in OS.get_cmdline_user_args(), "explicit limited flag")
	output = "res://build/joint_world_luoyang_20261003_qa/field_loading_source_worker_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique isolated QA output")
	for path: String in CURRENT_PINS:
		_source(path)
		_check(first[path].sha256.to_lower() == CURRENT_PINS[path], "frozen source SHA " + path)
	for path: String in [get_script().resource_path, DEFINITION, FIELD, "res://project.godot", "res://scripts/autoload/audio_manager.gd", "res://scripts/autoload/platform_bridge.gd", "res://scripts/domain/scene_script.gd", "res://scripts/domain/walkable_map_layout.gd", "res://data/maps/interior_inn_hall_layout_v1.tres"]: _source(path)
	_import("res://art/backgrounds/bg_interior_inn_hall_v1.png")
	deadline = Time.get_ticks_msec() + 45000
	var contract: Script = load(CONTRACT_PATH) as Script
	var validation_at_start: Dictionary = contract.call("transition_validation_state")
	var loading: Node = root.get_node("LoadingManager")
	var router: Node = root.get_node("SceneRouter")
	if failures == 0: await _exercise_sources(contract)
	if failures == 0: await _exercise_cancel(loading, router, contract)
	var token: int = router.get("_city_transition_token")
	if token > 0:
		router.call("end_field_transition_validation", token)
		loading.call("finish_field_preparation", token)
	if loading.get("_transition_active") == false: loading.call("_reset_transition")
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	await process_frame
	await process_frame
	_normal_audio_exit(root.get_node("AudioManager"))
	await _wait(func() -> bool: return audio_cleanup_done, "normal public audio exit")
	await process_frame
	await process_frame
	var last: Dictionary = {}
	for path: String in first: last[path] = _file(path)
	var validation_at_end: Dictionary = contract.call("transition_validation_state")
	var cold_executed: bool = validation_at_end.full_validations_total != validation_at_start.full_validations_total
	_check(not cold_executed, "actual full-validation counter confirms no cold city validation")
	_check(first == last and players == _players() and slot == save.get("active_slot") and bridge.call("is_checkpoint_saves_suspended") == true, "protected sources/player15/slot/checkpoint unchanged")
	_check(source_rows.size() == 3 and Time.get_ticks_msec() < deadline, "three limited rows inside one 45s deadline")
	var result := {"scope":"ACTUAL_SOURCE_SHA_WORKER_AND_LOADING_CANCEL_ONLY_NOT_COLD_CITY_FIELD", "checks":checks, "failures":failures, "complete":failures == 0, "rows":source_rows, "source_before":first, "source_after":last, "players_before":players, "players_after":_players(), "slot_before":slot, "slot_after":save.get("active_slot"), "normal_audio_exit_cleanup":audio_cleanup, "deadline_msec":deadline, "finished_msec":Time.get_ticks_msec(), "actual_driver":AudioServer.get_driver_name(), "validation_at_start":validation_at_start, "validation_at_end":validation_at_end, "cold_city_validation_executed":cold_executed, "live_packet_or_city_field_credit":false, "smoothness_audio_or_full_acceptance_credit":false, "intentional_error":"Transition validated source changed: owned QA fixture", "outer_exact_UTC_ticks_and_dependency_coverage_required":true}
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t")); file.close()
	_check(file != null and JSON.parse_string(FileAccess.get_file_as_string(output + "result.json")) is Dictionary, "result written and read back")
	print("FIELD_LOADING_SOURCE_WORKER_RESULT=" + output + "result.json checks=" + str(checks) + " failures=" + str(failures))
	file = null
	call_deferred("_quit_after_run", 0 if failures == 0 else 1)
