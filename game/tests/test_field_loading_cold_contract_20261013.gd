extends "res://tests/test_field_loading_key_exit_cleanup_20261013.gd"
## One real cold contract, not a full city Field construction or smoothness claim.
const CITY := "res://data/scenes/ch4_s0_luoyang_gate.tres"
const CONTRACT_PATH := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const CURRENT_PINS := {
	CONTRACT_PATH:"64aa769a2b551e386d9e7ccd87cad3ef4e53bb498da67c5b74a2421dedf47cab",
	"res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd":"4f4f5584f6320215207d960f8e244cd31ab657806f32e4b8a58c1a77107a63c1",
	"res://scripts/dev/luoyang_v3_wall_v5_saved_resource_checker.gd":"ad231d62314fb6a0d37683c223259f218a252db987f2c50a41277bd89de12a15",
	"res://scripts/city/luoyang_enclosure_v14_ground_binding.gd":"39f844cdcf48795c7dbbadb0d0b98b7c987ccb8e427b5473b57f46bc8395becf",
	"res://scripts/autoload/scene_router.gd":"a51f2b769cca1d9541a890c5b31ef75fd240fcb7f70bad1b8e401b117ea0cbff",
	"res://scripts/field/field_walkable_controller.gd":"a5e8d4097193c62910a5402ec87b887d907677d503738d7296fdbdd429794e70",
	"res://scripts/autoload/loading_manager.gd":"cca11b27788193b0aa11d6ecd3de9c048c1858860264a9bf960eadcadcc5f896",
	"res://scripts/ui/loading_screen.gd":"60a8bade4696dc3b8d0736561bd0a6c19ccc4637540a0fcca366171d0c9850da",
	"res://tests/test_field_loading_key_exit_cleanup_20261013.gd":"028acdf8c2ae12e7305a1624c9a7fbe40a04b127472ef18c3cb992c196c15d99",
	CITY:"872b4ff502f4f8c88eb238a25e3bcdfcb37bec5f71d2e84906ad53f751c90e17",
	"res://data/maps/luoyang_enclosure_v11_candidates/ch4_s0_luoyang_gate_layout.tres":"b4a50f1925abf1054ee2166a09b7b2a1080b0210544eb52a7f82edb70ec1d988",
	"res://art/maps/luoyang_enclosure_v11/ch4_s0_luoyang_gate/walk.png":"779441a6f70d071c0b5e2b8c22fa4fe782f00e13aa2dc693a68742f1fde5dbc3",
}
var cold_contract: Script
var observed_loading: Node
var observe := false
var observation_phase := "idle"
var last_frame_usec := 0
var frame_observation := {"frames":0, "source_worker_frames":0, "navigation_worker_frames":0, "opaque_frames":0, "max_frame_gap_usec":0, "max_gap_by_phase_usec":{}}
var proof_row: Dictionary = {}
var navigation_first: Dictionary = {}
var navigation_last: Dictionary = {}
var captures: Array[Dictionary] = []
var navigation_capture_started := false
var navigation_capture_done := false

func _cache_state() -> Dictionary:
	var records: Dictionary = cold_contract.get("_records")
	var masks: Dictionary = cold_contract.get("_masks")
	var solids: Dictionary = cold_contract.get("_solids")
	var used: Dictionary = cold_contract.get("_using_patch")
	return {"record_keys":records.keys(), "mask_keys":masks.keys(), "solid_keys":solids.keys(), "using_patch":used.duplicate(), "gate_record":records.has("ch4_s0_luoyang_gate"), "gate_mask":masks.has("ch4_s0_luoyang_gate")}

func _capture_loading(label: String) -> void:
	var started := Time.get_ticks_msec()
	var nav_before: int = cold_contract.get("_live_navigation_task")
	await RenderingServer.frame_post_draw
	var screen: Node = observed_loading.get("_screen")
	var panel: Control = screen.get("root") as Control
	var path := output + label + ".png"
	var image: Image = root.get_texture().get_image()
	var saved: int = image.save_png(path) if image != null else ERR_CANT_CREATE
	_check(saved == OK and FileAccess.file_exists(path), "actual GPU Loading PNG " + label)
	captures.append({"label":label, "path":path, "sha256":FileAccess.get_sha256(path) if saved == OK else "", "size": [image.get_width(),image.get_height()] if image != null else [], "readback_elapsed_msec":Time.get_ticks_msec()-started, "frame":Engine.get_process_frames(), "navigation_task_before":nav_before, "navigation_task_after":cold_contract.get("_live_navigation_task"), "loading_visible":panel.visible, "loading_alpha":panel.modulate.a})
	if label == "navigation_worker_loading": navigation_capture_done = true

func _observe_frame() -> void:
	if not observe: return
	var now := Time.get_ticks_usec()
	var phase := observation_phase
	if cold_contract.get("_live_source_task") >= 0: phase = "source_worker"
	elif cold_contract.get("_live_navigation_task") >= 0:
		phase = "navigation_worker"
		var value := {"task_id":cold_contract.get("_live_navigation_task"), "frame":Engine.get_process_frames(), "msec":now / 1000, "cache":_cache_state()}
		if navigation_first.is_empty(): navigation_first = value.duplicate(true)
		navigation_last = value
		if not navigation_capture_started:
			navigation_capture_started = true
			_capture_loading("navigation_worker_loading")
	if last_frame_usec > 0:
		var gap := now - last_frame_usec
		frame_observation.max_frame_gap_usec = maxi(frame_observation.max_frame_gap_usec, gap)
		frame_observation.max_gap_by_phase_usec[phase] = maxi(frame_observation.max_gap_by_phase_usec.get(phase, 0), gap)
	last_frame_usec = now
	frame_observation.frames += 1
	if phase == "source_worker": frame_observation.source_worker_frames += 1
	if phase == "navigation_worker": frame_observation.navigation_worker_frames += 1
	var screen: Node = observed_loading.get("_screen")
	var panel: Control = screen.get("root") as Control if is_instance_valid(screen) else null
	if panel != null and panel.visible and panel.modulate.a == 1.0: frame_observation.opaque_frames += 1

func _exercise_cold(loading: Node, router: Node) -> void:
	var accepted: Variant = router.call("go_field_smart", MAP_ID)
	if not _check(typeof(accepted) == TYPE_BOOL and accepted, "small original public Field startup accepted"): return
	if not await _wait(func() -> bool: return _ready_field(loading), "small Field before one cold proof"): return
	var held := current_scene
	var held_before := _snapshot(held)
	var scene: Resource = load(CITY) as Resource
	if not _check(scene != null and scene.resource_path == CITY and scene.get("scene_id") == &"ch4_s0_luoyang_gate", "actual canonical Gate loaded, not a mock packet"): return
	var validation_before: Dictionary = cold_contract.call("transition_validation_state")
	var token: int = loading.call("begin_field_preparation", "QA real cold Gate contract only")
	proof_row.token = token
	if not _check(token > 0 and held.process_mode == Node.PROCESS_MODE_DISABLED, "real Loading preparation owns token and holds previous Field"): return
	await process_frame
	await process_frame
	var screen: Node = loading.get("_screen")
	var panel: Control = screen.get("root") as Control
	_check(panel.visible and panel.modulate.a == 1.0 and loading.get("_field_preparation_token") == token, "actual opaque Loading shown before cold validation")
	await _capture_loading("before_cold_loading")
	proof_row["cache_before"] = _cache_state()
	observe = true
	observation_phase = "cold_resolve_main"
	last_frame_usec = Time.get_ticks_usec()
	process_frame.connect(_observe_frame)
	var started := Time.get_ticks_msec()
	var resolved: Resource = await cold_contract.call("resolve_scene_for_live_transition", scene, token)
	var resolved_at := Time.get_ticks_msec()
	var state: Dictionary = cold_contract.call("transition_validation_state")
	proof_row.merge({"started_msec":started, "resolved_msec":resolved_at, "validation_before":validation_before, "validation_resolved":state, "held_before":held_before, "held_during":_snapshot(held)})
	if _check(resolved != null and resolved == scene and state.active == true and state.live_scope == true and state.token == token and state.scene_id == "ch4_s0_luoyang_gate", "real cold resolver yields exact canonical bound live proof"):
		_check(state.full_validations_total == validation_before.full_validations_total + 1, "exactly one actual full BASE/C cold validation")
		var packet: Dictionary = cold_contract.get("_transition_validation")
		var sources: Dictionary = packet.sources.duplicate()
		var typed := not sources.is_empty() and sources.has(CITY) and sources.has(CONTRACT_PATH)
		for path: Variant in sources:
			typed = typed and typeof(path) == TYPE_STRING and typeof(sources[path]) == TYPE_STRING and sources[path].length() == 64
		_check(typed and sources.get(CITY) == CURRENT_PINS[CITY] and sources.get(CONTRACT_PATH) == CURRENT_PINS[CONTRACT_PATH], "complete real start source SHA set includes canonical and executed contract")
		var reused: Resource = cold_contract.call("resolve_scene_from_live_transition", scene, token)
		_check(reused == resolved and cold_contract.call("transition_validation_state").full_validations_total == state.full_validations_total, "live same-token consumer retains same Resource without a second cold validation")
		var record: Dictionary = packet.record
		var entry: Array = record.entry_foot_px
		_check(cold_contract.call("safe_body", &"ch4_s0_luoyang_gate", Vector2(entry[0], entry[1])) == true, "joined original full-body guard accepts actual authored Gate entry")
		observation_phase = "final_source_hash"
		var final_started := Time.get_ticks_msec()
		var finalized: Variant = await cold_contract.call("finalize_live_transition_sources", token, &"ch4_s0_luoyang_gate")
		var final_at := Time.get_ticks_msec()
		var final_state: Dictionary = cold_contract.call("transition_validation_state")
		_check(typeof(finalized) == TYPE_BOOL and finalized and final_state.sources_finalized == true and final_state.full_validations_total == state.full_validations_total, "complete real final source SHA equality seals same proof")
		_check(final_state.source_worker_active == false and final_state.navigation_worker_active == false and frame_observation.navigation_worker_frames > 0 and frame_observation.source_worker_frames > 0 and frame_observation.opaque_frames > 0, "real workers joined after observable natural frames under Loading")
		_check(not navigation_first.is_empty() and navigation_first.cache.gate_record == false and navigation_first.cache.gate_mask == false and navigation_last.cache.gate_record == false and navigation_last.cache.gate_mask == false and _cache_state().gate_record and _cache_state().gate_mask, "static navigation commit occurs after worker, not during active CPU raster")
		proof_row.merge({"source_start":sources, "source_final_equal":finalized, "final_hash_started_msec":final_started, "final_hash_finished_msec":final_at, "final_hash_msec":final_at-final_started, "validation_finalized":final_state, "phase_msec":final_state.live_phase_msec, "record_objects":record.objects.size(), "record_routes":record.routes.size(), "mask_sha":packet.mask_sha, "cache_joined":_cache_state()})
	if navigation_capture_started: await _wait(func() -> bool: return navigation_capture_done, "pending actual GPU observation")
	proof_row.merge({"navigation_first":navigation_first, "navigation_last":navigation_last, "captures":captures.duplicate(true)})
	observe = false
	if process_frame.is_connected(_observe_frame): process_frame.disconnect(_observe_frame)
	proof_row["natural_frame_observation"] = frame_observation.duplicate(true)
	cold_contract.call("end_transition_validation", token)
	await loading.call("finish_field_preparation", token)
	var held_after := _snapshot(held)
	var ended: Dictionary = cold_contract.call("transition_validation_state")
	_check(held_after.current and held_after.field_id == held_before.field_id and held_after.player_id == held_before.player_id and held_after.process_mode == held_before.process_mode, "contract-only validation restores exact previous small Field/player/mode")
	_check(ended.active == false and ended.source_worker_active == false and ended.navigation_worker_active == false and cold_contract.get("_live_source_token") == 0 and cold_contract.get("_live_navigation_job") == null and loading.get("_field_preparation_token") == 0 and loading.get("_external_active") == false, "completed proof token and owned CPU jobs released normally")
	proof_row.merge({"held_after":held_after, "validation_ended":ended, "errors":cold_contract.call("errors")})
	_check((cold_contract.call("errors") as Array).is_empty(), "no contract validation error hidden")

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended", true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true, "checkpoint held before first await through quit")
	var players := _players()
	var save: Node = root.get_node("SaveManager")
	var slot: Variant = save.get("active_slot")
	_check("--field-loading-key" in OS.get_cmdline_user_args(), "explicit limited flag")
	output = "res://build/joint_world_luoyang_20261003_qa/field_loading_cold_contract_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique isolated QA output")
	for path: String in CURRENT_PINS:
		_source(path)
		_check(first[path].sha256.to_lower() == CURRENT_PINS[path], "frozen source SHA " + path)
	for path: String in [get_script().resource_path, DEFINITION, FIELD, "res://project.godot", "res://scripts/autoload/platform_bridge.gd", "res://scripts/autoload/audio_manager.gd", "res://scripts/domain/scene_script.gd", "res://scripts/domain/walkable_map_layout.gd", "res://data/maps/interior_inn_hall_layout_v1.tres"]: _source(path)
	_import("res://art/backgrounds/bg_interior_inn_hall_v1.png")
	deadline = Time.get_ticks_msec() + 120000
	cold_contract = load(CONTRACT_PATH) as Script
	observed_loading = root.get_node("LoadingManager")
	if failures == 0: await _exercise_cold(observed_loading, root.get_node("SceneRouter"))
	observe = false
	if process_frame.is_connected(_observe_frame): process_frame.disconnect(_observe_frame)
	var remaining: int = cold_contract.get("_live_source_token")
	if remaining > 0: cold_contract.call("end_transition_validation", remaining)
	var held_token: int = observed_loading.get("_field_preparation_token")
	if held_token > 0: await observed_loading.call("finish_field_preparation", held_token)
	if observed_loading.get("_transition_active") == false: observed_loading.call("_reset_transition")
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	await process_frame
	await process_frame
	_normal_audio_exit(root.get_node("AudioManager"))
	await _wait(func() -> bool: return audio_cleanup_done, "normal public audio exit")
	await process_frame
	await process_frame
	var last: Dictionary = {}
	for path: String in first: last[path] = _file(path)
	_check(first == last and players == _players() and slot == save.get("active_slot") and bridge.call("is_checkpoint_saves_suspended") == true, "source/player15/slot/checkpoint unchanged")
	_check(Time.get_ticks_msec() < deadline, "single shared 120s deadline including cleanup")
	var result := {"scope":"ONE_REAL_COLD_GATE_CONTRACT_LOADING_DISPLAY_AND_FINAL_SOURCE_PROOF_NOT_CITY_FIELD", "checks":checks, "failures":failures, "complete":failures == 0, "proof":proof_row, "source_before":first, "source_after":last, "players_before":players, "players_after":_players(), "slot_before":slot, "slot_after":save.get("active_slot"), "deadline_msec":deadline, "finished_msec":Time.get_ticks_msec(), "normal_audio_exit_cleanup":audio_cleanup, "actual_driver":AudioServer.get_driver_name(), "rendering_method":RenderingServer.get_current_rendering_method(), "video_adapter":RenderingServer.get_video_adapter_name(), "full_city_field_or_gameplay_credit":false, "smoothness_audio_or_full_acceptance_credit":false, "outer_exact_ticks_and_dependency_coverage_required":true}
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t")); file.close()
	_check(file != null and JSON.parse_string(FileAccess.get_file_as_string(output + "result.json")) is Dictionary, "result written and read back")
	print("FIELD_LOADING_COLD_CONTRACT_RESULT=" + output + "result.json checks=" + str(checks) + " failures=" + str(failures))
	file = null
	cold_contract = null
	observed_loading = null
	call_deferred("_quit_after_run", 0 if failures == 0 else 1)
