extends SceneTree
## LIMITED reproducer only. Executes the unchanged RELEASE inner phase method,
## not its run()/finish(), and writes its full outer observation BEFORE cleanup.
## Never grants city/FULL/RELEASE/visual/formal acceptance or writes player saves.
const ENTRY = preload("res://tests/test_joint_world_luoyang_v15_release_20261005.gd")
const INPUT = preload("res://tests/helpers/v15_input_driver.gd")
const CITY_NOTE = preload("res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd")
const SOURCE_PINS: Dictionary = {
	"res://tests/test_joint_world_luoyang_v15_release_20261005.gd":"890dcee53610ba7ccf47d3b79f7104b437cf4bef724bbf18df9f3e9b9d101c84",
	"res://tests/helpers/joint_v15_looped_bgm_continuity.gd":"28252849ab92aee8e687bf4372d24c7f369b6c13fc51180510a1b3e00d6563a3",
	"res://tests/helpers/joint_v15_v9c_city_authored_transition_phase.gd":"0894e56e0239e1c269a1bebceeae099d119a678865db73e100424b71b1f7b135",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://scripts/autoload/audio_manager.gd":"23f8fe91c0b526eb38722b08969dc40b5e47d1f1cfc99497ce8536b6743d3a5c",
	"res://scripts/field/field_walkable_controller.gd":"b3301d6064e332e519b0fc3b4daed880ec3d77d98f2c744933b5d7077b9eb8ef",
	"res://scripts/autoload/scene_router.gd":"f3ead7459632188350e1e3383ee915c83b71c1b86d36dadf718bd338a4324eca",
	"res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd":"4f4f5584f6320215207d960f8e244cd31ab657806f32e4b8a58c1a77107a63c1",
}
const FORMAL_BASELINE: Dictionary = {
	"res://data/scenes/world_map_jianghu.tres":"838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015",
	"res://data/scenes/ch4_s0_luoyang_gate.tres":"b967c347e745e6f05d51a8f596fde4744571f5d459279467c706e66d9be24bd1",
	"res://data/scenes/ch4_s1_luoyang_yamen.tres":"7bed5d322d583c9c7bf4e392f3f4c75ffb0577db24bb9e6237a4ae3aa0808b01",
	"res://data/scenes/ch4_s2_canal_docks.tres":"81850afd0877bba70e2ed0786fe4e81570faee8e06e827561349988f9c4d41a5",
	"res://data/scenes/ch4_s3_luoyang_market.tres":"5cd76d0c0a0c54358f50b341186c5ea078a7d20657c97dc15ef15027755661ab",
	"res://data/config/outskirts_native_adoption.json":"203c9f08e941908ace3e8d56e18a15963e3a60859c04741b04e28a968386d0ff",
}
const SCOPE: String = "LIMITED_UNCHANGED_RELEASE_CITY_NATURAL48_ORIGINAL_SPACE_RETURN_BGM_DIAGNOSTIC_NOT_ACCEPTANCE"
var checks: int = 0
var failures: int = 0
var output: String = ""
var started_ticks: int = 0
var source_before: Dictionary = {}
var phase: RefCounted
var cleanup: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("[LIMITED NATURAL48 BGM DIAGNOSTIC] " + label)
	return ok

func _hashes(paths: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for path: String in paths:
		result[path] = FileAccess.get_sha256(path).to_lower() if FileAccess.file_exists(path) else "MISSING"
	return result

func _write(name: String,data: Dictionary) -> bool:
	var path: String = output + name
	if output.is_empty() or FileAccess.file_exists(path): return false
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null: return false
	var encoded: String = JSON.stringify(data,"\t")
	file.store_string(encoded)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	return error == OK and FileAccess.get_file_as_string(path) == encoded and JSON.parse_string(encoded) is Dictionary

func _run() -> void:
	started_ticks = Time.get_ticks_usec()
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var wanted: Array[String] = ["--candidate-before-cutover","--luoyang-v3-candidate"]
	_check(arguments.size() == wanted.size(),"exact limited candidate CLI, no implicit modes or unknown arguments")
	for arg: String in wanted: _check(arguments.count(arg) == 1,"single explicit candidate flag: " + arg)
	_check(Engine.time_scale == 1.0,"normal clocks before original method")
	source_before = _hashes(SOURCE_PINS)
	_check(source_before == SOURCE_PINS,"exact original entry/observer/adapter/input/audio/Field/Router/note source pins")
	_check(_hashes(FORMAL_BASELINE) == FORMAL_BASELINE,"six formal targets remain original baseline before diagnostic")
	if failures > 0:
		print("LIMITED_NATURAL48_BGM_DIAGNOSTIC_SETUP_REFUSED: %d failures; no phase or gameplay started" % failures)
		quit(1)
		return
	output = "res://build/joint_world_luoyang_20261003_qa/limited_release_city_natural48_bgm_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output) == OK,"new exclusive diagnostic evidence directory")
	if failures > 0: quit(1); return
	phase = ENTRY.ReleaseCityPhase.new()
	phase.set("tree",self)
	phase.set("candidate",true)
	phase.set("output",output)
	phase.set("before_files",phase.call("_normal_files"))
	phase.set("before_slot",root.get_node("SaveManager").get("active_slot"))
	var driver: RefCounted = INPUT.new()
	driver.call("configure",self)
	phase.set("driver",driver)
	phase.call("_public_fixture",{})
	var router: Node = root.get_node("SceneRouter")
	router.call("reset_for_new_game")
	var before_nav: Dictionary = router.call("get_navigation_state")
	phase.set("before_nav",before_nav.duplicate(true))
	var candidate_nav: Dictionary = before_nav.duplicate(true)
	candidate_nav["world_map_version"] = 15
	router.call("restore_navigation_state",candidate_nav,&"",&"world_map_jianghu_v15")
	_check(String(router.call("get_active_world_map_scene")) == "world_map_jianghu_v15","same public explicit candidate navigation fixture as original city phase")
	phase.call("_connect_events")
	var legacy: SceneScript = CITY_NOTE.legacy_scene(&"ch4_s0_luoyang_gate")
	var selected: Dictionary = {}
	var matching: int = 0
	if legacy != null:
		for row: Dictionary in legacy.map_layout.portals:
			if String(row.get("id","")) == "enter_luoyang":
				selected = row.duplicate(true)
				matching += 1
	_check(legacy != null and matching == 1 and String(selected.get("target_scene","")) == "ch4_s1_luoyang_yamen","unique immutable authored gate-to-yamen portal, no substitute station or action")
	print("LIMITED_NATURAL48_BGM_DIAGNOSTIC_BEGIN: output=%s source=%s; original method only; no FULL credit" % [output,source_before["res://tests/test_joint_world_luoyang_v15_release_20261005.gd"]])
	if failures == 0:
		# The exact unchanged method owns the actual48s, both original _open calls,
		# normal continuous approach, original Space, original reverse and observers.
		await phase.call("_normal_portal_case","ch4_s0_luoyang_gate",selected,"space")
	var immediate_records: Dictionary = (phase.get("records") as Dictionary).duplicate(true)
	var immediate_grace: Array = (phase.get("natural_grace_records") as Array).duplicate(true)
	# Persist before ANY grace, release, public reset or audio cleanup. All samples,
	# failed edges, nested portal and original failures survive later diagnostics.
	_check(_write("outer_observation_actual.json",{
		"schema":1,"scope":SCOPE,"engine_pid":OS.get_process_id(),"diagnostic_source_sha256":FileAccess.get_sha256(get_script().resource_path),
		"source_pins_before":source_before,"formal_baseline":FORMAL_BASELINE,"normal_clock_scale":Engine.time_scale,
		"elapsed_usec_before_cleanup":Time.get_ticks_usec()-started_ticks,"original_phase_checks":phase.get("checks"),"original_phase_failures":phase.get("failures"),
		"records":immediate_records,"natural_grace_records":immediate_grace,"events":(phase.get("events") as Array).duplicate(true),
		"player_files_before":phase.get("before_files"),"player_files_immediately_after":phase.call("_normal_files"),
		"active_slot_before":phase.get("before_slot"),"active_slot_immediately_after":root.get_node("SaveManager").get("active_slot"),
		"source_complete":false,"release_complete":false,"full_city_executed":false,"formal_cutover":false,
	}),"full actual outer evidence persisted immediately before cleanup")
	var outer: Dictionary = immediate_records.get("release_natural48_bgm",{})
	var portals: Array = immediate_records.get("portals",[])
	var exact_portal: bool = portals.size() == 1
	if exact_portal:
		var portal: Dictionary = portals[0]
		exact_portal = String(portal.get("source_scene_id","")) == "ch4_s0_luoyang_gate" and String(portal.get("source_id","")) == "enter_luoyang" and String(portal.get("mode","")) == "space" and String(portal.get("target","")) == "ch4_s1_luoyang_yamen" and portal.get("entered") == true and (portal.get("return",{}) as Dictionary).get("returned") == true and String((portal.get("return",{}) as Dictionary).get("kind","")) == "DIRECT_ORIGINAL_REVERSE_INPUT"
	_check(not outer.is_empty() and exact_portal,"actual original method retained outer observation and exact normal Space/direct reverse evidence")
	_check(int(phase.get("failures")) == 0 and outer.get("passed") == true,"unchanged original limited predicate passed; a reproduction failure is not approval")
	await _cleanup_phase()
	_check(int(phase.get("failures")) == 0,"all original phase assertions including final live-Field natural grace remain enforced")
	var source_after: Dictionary = _hashes(SOURCE_PINS)
	_check(source_after == source_before and source_after == SOURCE_PINS,"original sources remain byteexact after actual observation and natural cleanup")
	_check(_hashes(FORMAL_BASELINE) == FORMAL_BASELINE,"six formal targets unchanged after diagnostic")
	var observed: Dictionary = outer.get("observed",{})
	var failed_edges: Array[Dictionary] = []
	for edge: Dictionary in observed.get("adjacent_progress_edges",[]):
		if edge.get("ok") != true: failed_edges.append(edge.duplicate(true))
	var report: Dictionary = {
		"schema":1,"scope":SCOPE,"engine_pid":OS.get_process_id(),"output":output,"checks":checks,"failures":failures,
		"original_phase_checks":phase.get("checks"),"original_phase_failures":phase.get("failures"),"exact_original_portal_executed":exact_portal,
		"original_outer_passed":outer.get("passed",false),"observer_errors":observed.get("errors",[]),"observer_elapsed_sec":observed.get("elapsed_sec"),
		"observer_maximum_duration_sec":observed.get("maximum_duration_sec"),"observer_sample_count":observed.get("sample_count"),
		"exact_identity":observed.get("exact_identity"),"no_stop":observed.get("all_observed_states_playing_unpaused_no_pending_stop"),
		"bgm_changed_count":observed.get("bgm_changed_count"),"modulo_elapsed_progress":observed.get("modulo_elapsed_progress"),
		"failed_adjacent_edge_count":failed_edges.size(),"failed_adjacent_edges":failed_edges,"whole_observation_progress":observed.get("whole_observation_progress",{}),
		"cleanup":cleanup,"source_pins_before":source_before,"source_pins_after":source_after,
		"records_after_cleanup":(phase.get("records") as Dictionary).duplicate(true),"natural_grace_records_after_cleanup":(phase.get("natural_grace_records") as Array).duplicate(true),
		"source_complete":false,"release_complete":false,"full_city_executed":false,"full_world_executed":false,"visual_approved":false,"formal_cutover":false,
	}
	_check(_write("result.json",report),"limited actual diagnostic result retained with exact bytes readback")
	phase.set("tree",null)
	phase = null
	print("LIMITED_NATURAL48_BGM_DIAGNOSTIC_END: %d checks / %d failures; original_outer_passed=%s; elapsed=%s maximum=%s; errors=%s; failed_adjacent_edges=%d; output=%s; NOT_ACCEPTANCE" % [checks,failures,outer.get("passed",false),observed.get("elapsed_sec"),observed.get("maximum_duration_sec"),str(observed.get("errors",[])),failed_edges.size(),output])
	quit(0 if failures == 0 else 1)

func _cleanup_phase() -> void:
	await phase.call("natural_field_grace","limited_bgm_before_release")
	var bus: Node = root.get_node("EventBus")
	var connections: Array = phase.get("event_connections")
	for entry: Dictionary in connections:
		if bus.is_connected(entry.signal,entry.callable): bus.disconnect(entry.signal,entry.callable)
	connections.clear()
	phase.call("_release_field_oracles")
	var field: Node = phase.get("field") as Node
	var field_ref: WeakRef = weakref(field) if is_instance_valid(field) else null
	if is_instance_valid(current_scene):
		var owned: Node = current_scene
		current_scene = null
		owned.queue_free()
	phase.set("field",null)
	for tick in 8: await process_frame
	_check(field_ref == null or field_ref.get_ref() == null,"owned Field naturally released after all original observation records saved")
	_check(phase.call("_normal_files") == phase.get("before_files") and root.get_node("SaveManager").get("active_slot") == phase.get("before_slot"),"all15 normal save files and active slot unchanged; no player restore/write")
	root.get_node("SceneRouter").call("reset_for_new_game")
	_check(root.get_node("SceneRouter").call("get_navigation_state") == phase.get("before_nav"),"public process-navigation reset matches original pre-candidate baseline")
	var driver: RefCounted = phase.get("driver") as RefCounted
	driver.call("release")
	phase.set("driver",null)
	driver = null
	# Same public natural final audio lifecycle, strictly AFTER all observations.
	var began: int = Time.get_ticks_usec()
	var frames: int = 0
	while Time.get_ticks_usec()-began < 9000000:
		await process_frame
		frames += 1
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	cleanup = {"scope":"NATURAL_CLEANUP_ONLY_NOT_BGM_ACCEPTANCE","natural_grace_usec":Time.get_ticks_usec()-began,"natural_process_frames":frames,"public_stop_bgm_requested":audio != null,"public_fade_seconds":.15,"natural_drain_seconds":.25,"timer_cancelled":false,"private_audio_cache_cleared":false}
	_check(audio != null and Engine.time_scale == 1.0,"public natural audio cleanup with unchanged1x clocks")
	_check(phase.call("_normal_files") == phase.get("before_files") and root.get_node("SaveManager").get("active_slot") == phase.get("before_slot"),"all15 normal player files remain unchanged after final natural cleanup")
