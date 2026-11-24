extends "res://tests/test_field_loading_key_exit_cleanup_20261013.gd"
## One real Stage9 live-phase cold contract, not a full city Field construction or smoothness claim.
const STAGE9_SOURCE_READY := true # Six final production pins independently source-reviewed; not a runtime claim.
const CITY := "res://data/scenes/ch4_s0_luoyang_gate.tres"
const CONTRACT_PATH := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const CURRENT_PINS := {
	CONTRACT_PATH:"317f0bd6bb0aa807ac93ed63827fa0996bc6210022cb5d33105aa8627035cb85",
	"res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd":"ca61c59a102fca11f325c89f72b74b656093626db65f867c795bc261837bdd84",
	"res://scripts/dev/luoyang_v3_wall_v5_saved_resource_checker.gd":"856b3eb42a48b1d2cbbc7980745b9d93654f000203cbce822f31f685c7ae0c05",
	"res://scripts/dev/luoyang_v3_wall_v5_note_saved_resource_checker.gd":"9b5139f6f6295fb842e218f573e8def5426a526ef5182bd0a4ba927e3bc5b377",
	"res://scripts/city/luoyang_layered_v3_wall_v5_candidate_contract.gd":"a16ef313d8ea912d09e3f5a96639ccd3ba9284b14ec30806fb71d220a23012d2",
	"res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd":"57a9db94512afb4e286605eab778bb5ae1d1751a17fc56074a28ec042fe1df48",
	"res://tests/test_field_loading_v4_ground_receipt_cold_contract_20261013.gd":"42ec97d2dba1d241e51e9b7ba91a7c15c92f017a2c6f0992a004594d2f0b88bb",
	"res://tests/test_field_loading_source_receipt_cold_contract_20261013.gd":"0c2f18acb7036983158ffe5a64a21cf9a67874ea4c07badb6709dee55d6d393c",
	"res://tests/test_field_loading_base_cpu_cold_contract_20261013.gd":"e1f900d603a9ce8c4bff17b22e978fbcfde40140a5b282621f0c2d9838e3ec3a",
	"res://tests/test_field_loading_cold_contract_20261013.gd":"db16a083b1011f4f62d59f08864a26cb8dfd91d3d02e88a97f9d83b134cc5947",
	"res://scripts/city/luoyang_enclosure_v14_ground_binding.gd":"94bb60f97b58b350d7c963d6013342ced9a4862e61166538d5b88e82f62bef15",
	"res://scripts/autoload/scene_router.gd":"a51f2b769cca1d9541a890c5b31ef75fd240fcb7f70bad1b8e401b117ea0cbff",
	"res://scripts/field/field_walkable_controller.gd":"a5e8d4097193c62910a5402ec87b887d907677d503738d7296fdbdd429794e70",
	"res://scripts/autoload/loading_manager.gd":"cca11b27788193b0aa11d6ecd3de9c048c1858860264a9bf960eadcadcc5f896",
	"res://scripts/ui/loading_screen.gd":"60a8bade4696dc3b8d0736561bd0a6c19ccc4637540a0fcca366171d0c9850da",
	"res://tests/test_field_loading_key_exit_cleanup_20261013.gd":"028acdf8c2ae12e7305a1624c9a7fbe40a04b127472ef18c3cb992c196c15d99",
	CITY:"872b4ff502f4f8c88eb238a25e3bcdfcb37bec5f71d2e84906ad53f751c90e17",
	"res://data/maps/luoyang_enclosure_v11_candidates/ch4_s0_luoyang_gate_layout.tres":"b4a50f1925abf1054ee2166a09b7b2a1080b0210544eb52a7f82edb70ec1d988",
	"res://art/maps/luoyang_enclosure_v11/ch4_s0_luoyang_gate/walk.png":"779441a6f70d071c0b5e2b8c22fa4fe782f00e13aa2dc693a68742f1fde5dbc3",
}
var base_contract: Script
var cold_contract: Script
var observed_loading: Node
var observe := false
var observation_phase := "idle"
var last_frame_usec := 0
var frame_observation := {"frames":0, "source_worker_frames":0, "base_cpu_worker_frames":0, "base_live_frames":0, "navigation_worker_frames":0, "opaque_frames":0, "max_frame_gap_usec":0, "max_gap_by_phase_usec":{}}
var proof_row: Dictionary = {}
var base_cpu_first: Dictionary = {}
var base_cpu_last: Dictionary = {}
var base_live_first: Dictionary = {}
var base_live_last: Dictionary = {}
var base_live_cache_clear := true
var base_live_owner_bound := true
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

func _base_cache_state() -> Dictionary:
	# Only main-thread cache keys; never inspect concurrent workspace results.
	var records: Dictionary = base_contract.get("_records")
	var masks: Dictionary = base_contract.get("_masks")
	var solids: Dictionary = base_contract.get("_solids")
	var proofs: Dictionary = base_contract.get("_capture_proofs")
	return {"record_keys":records.keys(), "mask_keys":masks.keys(), "solid_keys":solids.keys(), "proof_keys":proofs.keys(), "gate_record":records.has("ch4_s0_luoyang_gate"), "gate_mask":masks.has("ch4_s0_luoyang_gate"), "gate_solids":solids.has("ch4_s0_luoyang_gate"), "gate_proof":proofs.has("ch4_s0_luoyang_gate")}

func _capture_loading(label: String) -> void:
	var started := Time.get_ticks_msec()
	var nav_before: int = cold_contract.get("_live_navigation_task")
	var base_before: int = cold_contract.get("_live_base_cpu_task")
	await RenderingServer.frame_post_draw
	var screen: Node = observed_loading.get("_screen")
	var panel: Control = screen.get("root") as Control
	var path := output + label + ".png"
	var image: Image = root.get_texture().get_image()
	var saved: int = image.save_png(path) if image != null else ERR_CANT_CREATE
	_check(saved == OK and FileAccess.file_exists(path), "actual GPU Loading PNG " + label)
	captures.append({"label":label, "path":path, "sha256":FileAccess.get_sha256(path) if saved == OK else "", "size": [image.get_width(),image.get_height()] if image != null else [], "readback_elapsed_msec":Time.get_ticks_msec()-started, "frame":Engine.get_process_frames(), "navigation_task_before":nav_before, "navigation_task_after":cold_contract.get("_live_navigation_task"), "base_cpu_task_before":base_before, "base_cpu_task_after":cold_contract.get("_live_base_cpu_task"), "loading_visible":panel.visible, "loading_alpha":panel.modulate.a})
	if label == "base_cpu_worker_loading": navigation_capture_done = true

func _observe_frame() -> void:
	if not observe: return
	var now := Time.get_ticks_usec()
	var phase := observation_phase
	# Public main-only scalar state: no running workspace _completed/_sources access.
	var live_state: Dictionary = cold_contract.call("transition_validation_state")
	if live_state.BASE_live_active == true:
		phase = "base_live_main"
		var cache := _base_cache_state()
		var value := {"frame":Engine.get_process_frames(), "msec":now / 1000, "active":live_state.BASE_live_active, "owner":live_state.BASE_live_owner, "scene_id":live_state.BASE_live_scene_id, "phase":live_state.BASE_live_phase, "last_completed_stage":live_state.BASE_last_completed_stage, "main_stage_timings":live_state.main_stage_timings, "cache":cache}
		if base_live_first.is_empty(): base_live_first = value.duplicate(true)
		base_live_last = value
		frame_observation.base_live_frames += 1
		base_live_cache_clear = base_live_cache_clear and not cache.gate_record and not cache.gate_mask and not cache.gate_solids and not cache.gate_proof
		base_live_owner_bound = base_live_owner_bound and typeof(live_state.BASE_live_active) == TYPE_BOOL and typeof(live_state.BASE_live_owner) == TYPE_INT and live_state.BASE_live_owner == proof_row.token and typeof(live_state.BASE_live_scene_id) == TYPE_STRING and live_state.BASE_live_scene_id == "ch4_s0_luoyang_gate" and live_state.BASE_live_phase == "base.validation"
	if cold_contract.get("_live_source_task") >= 0: phase = "source_worker"
	elif cold_contract.get("_live_base_cpu_task") >= 0:
		phase = "base_cpu_worker"
		var state: Dictionary = cold_contract.call("transition_validation_state")
		var value := {"task_id":cold_contract.get("_live_base_cpu_task"), "frame":Engine.get_process_frames(), "msec":now / 1000, "active":state.base_cpu_worker_active, "owner_token":state.base_cpu_owner_token, "cache":_base_cache_state()}
		if base_cpu_first.is_empty(): base_cpu_first = value.duplicate(true)
		base_cpu_last = value
		if not navigation_capture_started:
			navigation_capture_started = true
			_capture_loading("base_cpu_worker_loading")
	elif cold_contract.get("_live_navigation_task") >= 0:
		phase = "navigation_worker"
		var value := {"task_id":cold_contract.get("_live_navigation_task"), "frame":Engine.get_process_frames(), "msec":now / 1000, "cache":_cache_state()}
		if navigation_first.is_empty(): navigation_first = value.duplicate(true)
		navigation_last = value
	if last_frame_usec > 0:
		var gap := now - last_frame_usec
		frame_observation.max_frame_gap_usec = maxi(frame_observation.max_frame_gap_usec, gap)
		frame_observation.max_gap_by_phase_usec[phase] = maxi(frame_observation.max_gap_by_phase_usec.get(phase, 0), gap)
	last_frame_usec = now
	frame_observation.frames += 1
	if phase == "source_worker": frame_observation.source_worker_frames += 1
	if phase == "base_cpu_worker": frame_observation.base_cpu_worker_frames += 1
	if phase == "navigation_worker": frame_observation.navigation_worker_frames += 1
	var screen: Node = observed_loading.get("_screen")
	var panel: Control = screen.get("root") as Control if is_instance_valid(screen) else null
	if panel != null and panel.visible and panel.modulate.a == 1.0: frame_observation.opaque_frames += 1

func _uncompleted_receipt_checks() -> void:
	# Owned and never submitted: no concurrent outputs, no fabricated live proof.
	var script: Script = load("res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd") as Script
	var workspace: RefCounted = script.new() as RefCounted
	_check(workspace.call("ready") == false and workspace.call("mark_joined", 1, &"ch4_s0_luoyang_gate") == false, "uncompleted workspace cannot become joined/ready")
	var cases: Array = [CONTRACT_PATH, "res://__qa_missing_receipt_leaf__.png", "F:/not_a_project_receipt.png", "res://../outside.png", null, 0, false, [CONTRACT_PATH]]
	for path: Variant in cases:
		var value: Variant = workspace.call("source_sha", &"ch4_s0_luoyang_gate", path)
		_check(typeof(value) == TYPE_STRING and value == "", "uncompleted receipt rejects path query " + str(path))
	_check(workspace.call("source_sha", &"unknown_city", CONTRACT_PATH) == "", "uncompleted receipt rejects wrong city identity")
	# Real current JSON inputs reach the new guard before the catalog/GPU work.
	var region := "ch4_s0_luoyang_gate"
	var id: StringName = StringName(region)
	var constants: Dictionary = cold_contract.get_script_constant_map()
	var bindings: Dictionary = constants["GROUND_MANIFESTS"]
	var plan_shas: Dictionary = constants["EXPORT_PLAN_SHAS"]
	var binding: Dictionary = bindings[region]
	var prefix: String = String(constants["ROOT"]) + region + "/"
	var base_path: String = cold_contract.call("base_manifest_path", id)
	var plan_path: String = prefix + "export_plan.json"
	for protected_path: String in [base_path, plan_path, String(binding.path)]: _source(protected_path)
	var base_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(base_path))
	var plan: Variant = JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	var plan_sha: String = plan_shas[region]
	if _check(base_raw is Dictionary and plan is Dictionary and FileAccess.get_sha256(base_path) == cold_contract.call("base_manifest_sha", id) and FileAccess.get_sha256(plan_path) == plan_sha and FileAccess.get_sha256(binding.path) == binding.sha256, "actual BASE/plan/GROUND JSON pins precede owned uncompleted receipt rejection"):
		var ground_script: Script = load("res://scripts/city/luoyang_enclosure_v14_ground_binding.gd") as Script
		var result: Variant = ground_script.call("read", binding, id, prefix, base_raw, plan, plan_sha, workspace)
		_check(result is Dictionary and result.get("error") == "Unbound/cancelled live native ground source receipt", "actual GROUND schema reaches exact uncompleted receipt guard before catalog/render")
		proof_row["ground_uncompleted_receipt"] = {"scope":"REAL_JSON_INPUT_GROUND_GUARD_REJECTION_ONLY_NOT_RENDER_OR_CITY", "error":result.get("error") if result is Dictionary else "", "base_path":base_path, "base_sha256":FileAccess.get_sha256(base_path), "plan_path":plan_path, "plan_sha256":plan_sha, "ground_path":binding.path, "ground_sha256":binding.sha256, "worker_submitted":false}
		ground_script = null
	workspace.call("release")
	_check(workspace.call("ready") == false and workspace.call("source_sha", &"ch4_s0_luoyang_gate", CONTRACT_PATH) == "", "released uncompleted receipt remains unavailable")
	proof_row["uncompleted_receipt"] = {"scope":"OWNED_UNCOMPLETED_ONLY_NOT_JOINED_PATH_BRANCH_COVERAGE_OR_CITY_CREDIT", "queries":cases.size()+1, "fake_completed_context":false, "worker_submitted":false}
	workspace = null
	script = null

func _invalidate_checkpoint_owner(owner: Dictionary) -> void:
	owner["alive"] = false

func _shared_yield_owner_rejection() -> void:
	# A real shared one-frame checkpoint, not a second cold or fake ready packet.
	var owner := {"alive":true, "calls":0, "first_frame":-1, "last_frame":-1}
	var checker: Script = load("res://scripts/dev/luoyang_v3_wall_v5_saved_resource_checker.gd") as Script
	var before_state: Dictionary = cold_contract.call("transition_validation_state")
	var before_base := _base_cache_state()
	var before_c := _cache_state()
	var owner_check := func() -> bool:
		owner.calls += 1
		var frame := Engine.get_process_frames()
		if owner.first_frame < 0: owner.first_frame = frame
		owner.last_frame = frame
		return owner.alive
	call_deferred("_invalidate_checkpoint_owner", owner)
	var accepted: Variant = await checker.call("yield_owner", owner_check)
	_check(typeof(accepted) == TYPE_BOOL and accepted == false and owner.alive == false and owner.calls == 2, "shared production checkpoint rejects owned callback invalidated across its real await")
	_check(owner.last_frame > owner.first_frame, "shared owner rejection includes an actual natural process_frame")
	_check(before_state == cold_contract.call("transition_validation_state") and before_base == _base_cache_state() and before_c == _cache_state(), "checkpoint-only owner loss cannot mutate transition or BASE/C cache state")
	proof_row["shared_yield_owner_rejection"] = {"scope":"REAL_SHARED_CHECKPOINT_OWNED_CALLBACK_ONLY_NOT_WHOLE_BASE_OR_CITY_CANCEL", "accepted":accepted, "owner":owner.duplicate(true), "state_unchanged":before_state == cold_contract.call("transition_validation_state"), "fake_ready_context":false, "second_cold":false}
	owner_check = Callable()
	checker = null

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
	proof_row["base_cache_before"] = _base_cache_state()
	var fresh_cache := _base_cache_state()
	_check(not fresh_cache.gate_record and not fresh_cache.gate_mask and not fresh_cache.gate_solids and not fresh_cache.gate_proof, "fresh cold Gate begins with all four BASE target caches empty; not a warm-cache erase claim")
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
		_check(final_state.source_worker_active == false and final_state.navigation_worker_active == false and final_state.base_cpu_worker_active == false and final_state.base_cpu_owner_token == 0 and frame_observation.base_cpu_worker_frames > 0 and frame_observation.navigation_worker_frames > 0 and frame_observation.source_worker_frames > 0 and frame_observation.opaque_frames > 0, "real BASE/source/navigation workers joined after observable natural frames under Loading")
		_check(not base_cpu_first.is_empty() and typeof(base_cpu_first.active) == TYPE_BOOL and base_cpu_first.active and base_cpu_first.owner_token == token and base_cpu_last.active == true and base_cpu_last.owner_token == token and base_cpu_first.cache.gate_record == false and base_cpu_first.cache.gate_mask == false and base_cpu_first.cache.gate_proof == false and base_cpu_last.cache.gate_record == false and base_cpu_last.cache.gate_mask == false and base_cpu_last.cache.gate_proof == false and _base_cache_state().gate_record and _base_cache_state().gate_mask and _base_cache_state().gate_proof, "BASE caches and capture proof commit only after owned CPU task has joined")
		_check(captures.size() == 2 and captures[1].label == "base_cpu_worker_loading" and captures[1].base_cpu_task_before >= 0 and captures[1].base_cpu_task_after == captures[1].base_cpu_task_before, "second actual GPU Loading capture belongs to active BASE CPU task")
		_check(not base_live_first.is_empty() and frame_observation.base_live_frames > 0 and base_live_owner_bound and base_live_cache_clear and final_state.BASE_live_active == false and final_state.BASE_live_owner == 0 and _base_cache_state().gate_record and _base_cache_state().gate_mask and _base_cache_state().gate_solids and _base_cache_state().gate_proof, "fresh-cold live BASE phases yield under exact owner without publishing any of four partial caches, then commit all four")
		var timings: Variant = final_state.main_stage_timings
		var timing_valid: bool = timings is Dictionary and not timings.is_empty()
		if timings is Dictionary:
			for label: Variant in timings:
				var row: Variant = timings[label]
				timing_valid = timing_valid and typeof(label) == TYPE_STRING and row is Dictionary
				if row is Dictionary:
					timing_valid = timing_valid and typeof(row.get("count")) == TYPE_INT and row.get("count",0) > 0 and typeof(row.get("total_usec")) == TYPE_INT and row.get("total_usec",-1) >= 0 and typeof(row.get("max_usec")) == TYPE_INT and row.get("max_usec",-1) >= 0 and row.get("max_usec",-1) <= row.get("total_usec",-1)
		_check(timing_valid, "joined main phase diagnostics are typed scalar counts/elapsed totals, not a smoothness threshold")
		_check(not navigation_first.is_empty() and navigation_first.cache.gate_record == false and navigation_first.cache.gate_mask == false and navigation_last.cache.gate_record == false and navigation_last.cache.gate_mask == false and _cache_state().gate_record and _cache_state().gate_mask, "static navigation commit occurs after worker, not during active CPU raster")
		proof_row.merge({"source_start":sources, "source_final_equal":finalized, "final_hash_started_msec":final_started, "final_hash_finished_msec":final_at, "final_hash_msec":final_at-final_started, "validation_finalized":final_state, "phase_msec":final_state.live_phase_msec, "record_objects":record.objects.size(), "record_routes":record.routes.size(), "mask_sha":packet.mask_sha, "cache_joined":_cache_state()})
	if navigation_capture_started: await _wait(func() -> bool: return navigation_capture_done, "pending actual GPU observation")
	proof_row.merge({"base_cpu_first":base_cpu_first, "base_cpu_last":base_cpu_last, "base_live_first":base_live_first, "base_live_last":base_live_last, "base_live_cache_clear_all_observed_frames":base_live_cache_clear, "base_live_owner_bound_all_observed_frames":base_live_owner_bound, "base_live_observation_scope":"FRESH_COLD_MAIN_PHASE_PROCESS_FRAMES_NOT_EXACT_CHECKPOINT_COUNT_WARM_CACHE_ERASE_OR_WHOLE_BASE_CANCEL", "base_cache_joined":_base_cache_state(), "navigation_first":navigation_first, "navigation_last":navigation_last, "captures":captures.duplicate(true)})
	observe = false
	if process_frame.is_connected(_observe_frame): process_frame.disconnect(_observe_frame)
	proof_row["natural_frame_observation"] = frame_observation.duplicate(true)
	cold_contract.call("end_transition_validation", token)
	await loading.call("finish_field_preparation", token)
	var held_after := _snapshot(held)
	var ended: Dictionary = cold_contract.call("transition_validation_state")
	_check(held_after.current and held_after.field_id == held_before.field_id and held_after.player_id == held_before.player_id and held_after.process_mode == held_before.process_mode, "contract-only validation restores exact previous small Field/player/mode")
	_check(ended.active == false and ended.source_worker_active == false and ended.navigation_worker_active == false and ended.base_cpu_worker_active == false and ended.base_cpu_owner_token == 0 and cold_contract.get("_live_base_cpu_job") == null and cold_contract.get("_live_base_cpu_task") == -1 and cold_contract.get("_live_source_token") == 0 and cold_contract.get("_live_navigation_job") == null and loading.get("_field_preparation_token") == 0 and loading.get("_external_active") == false, "completed proof token and owned CPU jobs released normally")
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
	output = "res://build/joint_world_luoyang_20261003_qa/field_loading_live_phase_cold_contract_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique isolated QA output")
	for path: String in CURRENT_PINS:
		_source(path)
		_check(first[path].sha256.to_lower() == CURRENT_PINS[path], "frozen source SHA " + path)
	for path: String in [get_script().resource_path, DEFINITION, FIELD, "res://project.godot", "res://scripts/autoload/platform_bridge.gd", "res://scripts/autoload/audio_manager.gd", "res://scripts/domain/scene_script.gd", "res://scripts/domain/walkable_map_layout.gd", "res://data/maps/interior_inn_hall_layout_v1.tres"]: _source(path)
	_import("res://art/backgrounds/bg_interior_inn_hall_v1.png")
	deadline = Time.get_ticks_msec() + 120000
	base_contract = load("res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd") as Script
	cold_contract = load(CONTRACT_PATH) as Script
	observed_loading = root.get_node("LoadingManager")
	_check(STAGE9_SOURCE_READY, "Stage9 final SOURCE freeze is required before execution")
	if failures == 0: _uncompleted_receipt_checks()
	if failures == 0: await _shared_yield_owner_rejection()
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
	var result := {"scope":"ONE_REAL_STAGE9_LIVE_PHASE_COLD_GATE_CONTRACT_LOADING_DISPLAY_AND_FINAL_SOURCE_PROOF_NOT_CITY_FIELD", "checks":checks, "failures":failures, "complete":failures == 0, "proof":proof_row, "source_before":first, "source_after":last, "players_before":players, "players_after":_players(), "slot_before":slot, "slot_after":save.get("active_slot"), "deadline_msec":deadline, "finished_msec":Time.get_ticks_msec(), "normal_audio_exit_cleanup":audio_cleanup, "actual_driver":AudioServer.get_driver_name(), "rendering_method":RenderingServer.get_current_rendering_method(), "video_adapter":RenderingServer.get_video_adapter_name(), "full_city_field_or_gameplay_credit":false, "smoothness_audio_or_full_acceptance_credit":false, "outer_exact_ticks_and_dependency_coverage_required":true}
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t")); file.close()
	_check(file != null and JSON.parse_string(FileAccess.get_file_as_string(output + "result.json")) is Dictionary, "result written and read back")
	print("FIELD_LOADING_LIVE_PHASE_COLD_CONTRACT_RESULT=" + output + "result.json checks=" + str(checks) + " failures=" + str(failures))
	file = null
	base_contract = null
	cold_contract = null
	observed_loading = null
	call_deferred("_quit_after_run", 0 if failures == 0 else 1)
