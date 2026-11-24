extends "res://tests/test_field_loading_key_exit_cleanup_20261013.gd"
## Worker-only sibling. Does not rerun the old failed token/cold-proof test.
const WORKER_CITY := "res://data/scenes/ch4_s0_luoyang_gate.tres"
const WORKER_LAYOUT := "res://data/maps/luoyang_enclosure_v11_candidates/ch4_s0_luoyang_gate_layout.tres"
const WORKER_MASK := "res://art/maps/luoyang_enclosure_v11/ch4_s0_luoyang_gate/walk.png"
const WORKER_CONTRACT := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const WORKER_PINS := {
	"res://scripts/autoload/loading_manager.gd": "cca11b27788193b0aa11d6ecd3de9c048c1858860264a9bf960eadcadcc5f896",
	"res://scripts/autoload/scene_router.gd": "7bfb3f2bd900c45cd1d4f294a14b1d78143fc0aedb05b3374cddaf473388bfb4",
	"res://scripts/field/field_walkable_controller.gd": "ee60a9d44c895a69d0d0490d405802df686243eb722d215d590584f7925bb204",
	"res://scripts/ui/loading_screen.gd": "60a8bade4696dc3b8d0736561bd0a6c19ccc4637540a0fcca366171d0c9850da",
	"res://scripts/city/luoyang_city3_motion_guard_20261009.gd": "aacd53e5020bc5a40353d9cf7537662c44139fa7f861e3a54c6faf59e8ba3a93",
	WORKER_CONTRACT: "13a3e3dcddd1d4b90ecf3195432fe1f26b4f6bbceb9740b4cfe83482890da368",
	WORKER_CITY: "872b4ff502f4f8c88eb238a25e3bcdfcb37bec5f71d2e84906ad53f751c90e17",
	WORKER_LAYOUT: "b4a50f1925abf1054ee2166a09b7b2a1080b0210544eb52a7f82edb70ec1d988",
	WORKER_MASK: "779441a6f70d071c0b5e2b8c22fa4fe782f00e13aa2dc693a68742f1fde5dbc3",
	DEFINITION: "67a7adae40e7dfed22c7b072152f775aa957f4def015a7aea0a95ae95ff285ea",
	"res://tests/test_field_loading_key_exit_cleanup_20261013.gd": "028acdf8c2ae12e7305a1624c9a7fbe40a04b127472ef18c3cb992c196c15d99",
	"res://tests/test_field_loading_transition_token_20261013.gd": "e53454baadf89ce6f5c97fee94768b67a6bb3b2a007b8b13001219b2b52d17d1",
}
var cpu_done := false
var cpu_guard: RefCounted
var worker_record: Dictionary = {}

func _build_worker(field: Node, mask: Image, visuals: Array) -> void:
	cpu_guard = await field.call("_build_city3_motion_guard", mask, visuals, true)
	cpu_done = true

func _exercise_worker(loading: Node, router: Node) -> void:
	var accepted: Variant = router.call("go_field_smart", MAP_ID)
	if not _check(typeof(accepted) == TYPE_BOOL and accepted, "small public Field startup accepted"): return
	if not await _wait(func() -> bool: return _ready_field(loading), "small Field startup"): return
	var field := current_scene
	var scene: Resource = load(WORKER_CITY) as Resource
	var contract: Script = load(WORKER_CONTRACT) as Script
	if not _check(scene != null and contract != null and scene.resource_path == WORKER_CITY and scene.get("scene_id") == &"ch4_s0_luoyang_gate" and contract.call("is_v3", scene) == true, "exact canonical enclosure resource and metadata; no full prepare called"): return
	var layout: Resource = scene.get("map_layout")
	if not _check(layout != null and layout.resource_path == WORKER_LAYOUT and layout.get("walkable_mask_path") == WORKER_MASK, "frozen actual layout selects exact frozen mask"): return
	# Exactly mirrors production Field: a non-null map_layout replaces scene_objects.
	var visuals: Variant = layout.get("visual_objects")
	var legacy: Variant = scene.get("scene_objects")
	if not _check(visuals is Array and not visuals.is_empty() and legacy is Array, "actual production layout visual_objects are a nonempty Array"): return
	var blocking_count := 0
	for value: Variant in visuals:
		if not _check(value is Dictionary and typeof(value.get("blocking")) == TYPE_BOOL, "actual layout object has native blocking bool"): return
		if value.blocking: blocking_count += 1
	_check(blocking_count > 0, "actual layout contains physical solids, not an empty fixture")
	var mask: Image = Image.load_from_file(WORKER_MASK)
	if not _check(mask != null and mask.get_size() == Vector2i(3072, 2048), "exact native mask domain"): return
	var validation_before: Dictionary = contract.call("transition_validation_state")
	var started := Time.get_ticks_msec()
	var start_frame := Engine.get_process_frames()
	_build_worker(field, mask, visuals)
	var task: int = field.get("_city3_motion_task_id")
	var job: RefCounted = field.get("_city3_motion_job") as RefCounted
	var active := task >= 0 and job != null and not WorkerThreadPool.is_task_completed(task)
	var completed := await _wait(func() -> bool: return cpu_done, "worker completes inside shared 45s deadline")
	if completed:
		var configured: Variant = cpu_guard.get("_configured") if cpu_guard != null else null
		var prefix: Variant = cpu_guard.get("_prefix") if cpu_guard != null else null
		var succeeded: Variant = job.get("succeeded") if job != null else null
		_check(active and Engine.get_process_frames() > start_frame and typeof(succeeded) == TYPE_BOOL and succeeded and typeof(configured) == TYPE_BOOL and configured and prefix is PackedInt32Array and prefix.size() == 3073 * 2049, "real task active, natural frames advance, joined guard configured with full prefix")
		_check(field.get("_city3_motion_task_id") == -1 and field.get("_city3_motion_job") == null and job != null and is_same(job.get("guard"), cpu_guard) and job.get("mask") == null and (job.get("visual_objects") as Array).is_empty(), "join completed and exclusive input refs released")
		worker_record = {"started_msec":started, "finished_msec":Time.get_ticks_msec(), "start_frame":start_frame, "finish_frame":Engine.get_process_frames(), "task_id":task, "active_after_start":active, "succeeded_after_join":succeeded, "configured":configured, "prefix_entries":prefix.size() if prefix is PackedInt32Array else 0, "production_input":"map_layout.visual_objects", "layout_objects":visuals.size(), "blocking_objects":blocking_count, "legacy_scene_objects":legacy.size(), "city_instance":scene.get_instance_id(), "layout_instance":layout.get_instance_id(), "mask_source":first[WORKER_MASK]}
	else:
		field.call("_release_city3_motion")
		await process_frame
	if cpu_guard != null:
		cpu_guard.call("release")
		_check(cpu_guard.get("_configured") == false and (cpu_guard.get("_prefix") as PackedInt32Array).is_empty(), "normal returned-guard release clears prefix")
	cpu_guard = null
	job = null
	var validation_after: Dictionary = contract.call("transition_validation_state")
	_check(validation_after == validation_before, "worker-only retry does not repeat cold validation or create a token proof")
	worker_record.validation_state_before = validation_before
	worker_record.validation_state_after = validation_after
	_check(Time.get_ticks_msec() < deadline, "worker and small startup share one 45s deadline")

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended", true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true, "checkpoint held before first await through quit")
	var players := _players()
	var save: Node = root.get_node("SaveManager")
	var slot: Variant = save.get("active_slot")
	_check("--field-loading-key" in OS.get_cmdline_user_args(), "explicit limited flag")
	output = "res://build/joint_world_luoyang_20261003_qa/field_loading_motion_worker_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique QA output")
	for path: String in WORKER_PINS:
		_source(path)
		_check(first[path].sha256.to_lower() == WORKER_PINS[path], "frozen SHA " + path)
	for path: String in [get_script().resource_path, "res://project.godot", "res://scripts/autoload/platform_bridge.gd", "res://scripts/autoload/audio_manager.gd", "res://scripts/domain/scene_script.gd", "res://scripts/domain/walkable_map_layout.gd", FIELD, "res://data/maps/interior_inn_hall_layout_v1.tres"]: _source(path)
	_import("res://art/backgrounds/bg_interior_inn_hall_v1.png")
	deadline = Time.get_ticks_msec() + 45000
	var loading: Node = root.get_node("LoadingManager")
	if failures == 0: await _exercise_worker(loading, root.get_node("SceneRouter"))
	if loading.get("_transition_active") == false: loading.call("_reset_transition")
	if is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null
	await process_frame
	await process_frame
	_normal_audio_exit(root.get_node("AudioManager"))
	await _wait(func() -> bool: return audio_cleanup_done, "normal public audio exit cleanup")
	await process_frame
	await process_frame
	var last: Dictionary = {}
	for path: String in first: last[path] = _file(path)
	_check(first == last and players == _players() and slot == save.get("active_slot") and bridge.call("is_checkpoint_saves_suspended") == true, "source/player15/slot/checkpoint unchanged")
	_check(not worker_record.is_empty(), "worker-only result collected")
	var result := {"scope":"ACTUAL_CANONICAL_LAYOUT_CPU_MOTION_WORKER_ONLY_NOT_CITY_FIELD_OR_TOKEN_RETEST", "checks":checks, "failures":failures, "complete":failures == 0, "worker":worker_record, "normal_audio_exit_cleanup":audio_cleanup, "source_before":first, "source_after":last, "players_before":players, "players_after":_players(), "slot_before":slot, "slot_after":save.get("active_slot"), "deadline_msec":deadline, "finished_msec":Time.get_ticks_msec(), "actual_driver":AudioServer.get_driver_name(), "cold_validation_executed":false, "city_field_or_router_travel_tested":false, "audio_or_movement_credit":false, "smoothness_or_full_acceptance_credit":false, "outer_exact_UTC_ticks_and_dependency_closure_required":true}
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result, "\t"))
		file.close()
	_check(file != null and JSON.parse_string(FileAccess.get_file_as_string(output + "result.json")) is Dictionary, "result written and read back")
	print("FIELD_LOADING_WORKER_RESULT=" + output + "result.json checks=" + str(checks) + " failures=" + str(failures))
	file = null
	call_deferred("_quit_after_run", 0 if failures == 0 else 1)
