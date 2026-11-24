extends SceneTree
## Original six-case assertions retained; normal audio exit cleanup only. No audio credit.
const MAP_ID := &"interior_inn_hall"
const FIELD := "res://scenes/field_walkable.tscn"
const DEFINITION := "res://data/scenes/interior_inn_hall.tres"
const MISSING_ID := "__qa_missing_loading_definition_20261013"
const PINS := {
	"res://scripts/autoload/loading_manager.gd": "9007f04c84937d26cf7f940869c5db2e9bbae3859cbd88c239a1864b761896ce",
	"res://scripts/ui/loading_screen.gd": "60a8bade4696dc3b8d0736561bd0a6c19ccc4637540a0fcca366171d0c9850da",
	"res://scripts/autoload/scene_router.gd": "da9f185209474f2fe09bc3cc737c81f86e2cd9ddda5acbe287a0b6a9ef87b702",
	"res://scripts/field/field_walkable_controller.gd": "b9dd37e4c9f5f20af6d9fb99057ce575b68fe7478a053a1b2aa208b82e3cd283",
	DEFINITION: "67a7adae40e7dfed22c7b072152f775aa957f4def015a7aea0a95ae95ff285ea",
	"res://data/maps/interior_inn_hall_layout_v1.tres": "08df9b2e75f76c116c8163e3529897223549cd0485f10537212d9a9456600a27",
	FIELD: "d605d74a12f297b1472ae613cbb38d567672808c44c0a11d0d01279a6c240058",
	"res://scenes/ui/loading_screen.tscn": "340c4fd57e4a8aabd3be217d479c7361aebdae24d5cc6440ecbeba0efe1c3c01",
}
var checks := 0
var failures := 0
var deadline := 0
var rows: Array[Dictionary] = []
var first: Dictionary = {}
var progressive_done := false
var hide_done := false
var output := ""
var audio_cleanup_done := false
var audio_cleanup: Dictionary = {}

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("[FIELD LOADING KEY FAIL] " + label)
	return ok

func _file(path: String) -> Dictionary:
	var exists := FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ) if exists else null
	return {"exists": exists, "bytes": file.get_length() if file != null else 0, "sha256": FileAccess.get_sha256(path) if exists else "ABSENT", "mtime_seconds": FileAccess.get_modified_time(path) if exists else 0}

func _players() -> Dictionary:
	var result: Dictionary = {}
	for index in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path := "user://save_%d.json%s" % [index, suffix]
			result[path] = _file(path)
	return result

func _source(path: String) -> void:
	first[path] = _file(path)
	_check(first[path].exists, "source exists " + path)

func _import(path: String) -> void:
	_source(path)
	_source(path + ".import")
	if not FileAccess.file_exists(path + ".import"): return
	var regex := RegEx.new()
	regex.compile('"(res://[^"\\r\\n]+)"')
	var count := 0
	for match_value: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path + ".import")):
		var leaf := match_value.get_string(1)
		if leaf.begins_with("res://.godot/imported/"):
			_source(leaf)
			count += 1
	_check(count > 0, "compiled destination tracked " + path)

func _wait(predicate: Callable, label: String) -> bool:
	while Time.get_ticks_msec() < deadline:
		if predicate.call() == true: return true
		await process_frame
	return _check(false, "single 45s deadline: " + label)

func _snapshot(field: Node) -> Dictionary:
	var valid := is_instance_valid(field) and field.is_inside_tree() and not field.is_queued_for_deletion()
	var player: Variant = field.get("_player") if valid else null
	return {"msec": Time.get_ticks_msec(), "frame": Engine.get_process_frames(), "field_id": field.get_instance_id() if valid else 0, "current": valid and current_scene == field, "process_mode": field.process_mode if valid else -1, "rebuilding": field.get("_scene_rebuilding") if valid else null, "player_id": player.get_instance_id() if is_instance_valid(player) else 0, "state": field.call("get_field_loading_state").duplicate(true) if valid else {}}

func _ready_field(loading: Node) -> bool:
	var field := current_scene
	if field == null or not field.has_method("get_field_loading_state") or loading.get("_transition_active") != false: return false
	var state: Dictionary = field.call("get_field_loading_state")
	return typeof(state.get("complete")) == TYPE_BOOL and state.complete and typeof(state.get("failed")) == TYPE_BOOL and not state.failed and state.scene_id == String(MAP_ID) and field.get("_scene_rebuilding") == false and is_instance_valid(field.get("_player"))

func _progressive(field: Node, scene: Resource) -> void:
	await field.call("_setup_scene", scene, null, true)
	progressive_done = true

func _hide(screen: Node) -> void:
	await screen.call("hide_screen")
	hide_done = true

func _exercise(loading: Node, router: Node) -> void:
	var accepted: Variant = router.call("go_field_smart", MAP_ID)
	if not _check(typeof(accepted) == TYPE_BOOL and accepted, "original synchronous bool request accepted"): return
	if not await _wait(func() -> bool: return _ready_field(loading), "small public Field startup"): return
	var field := current_scene
	rows.append({"kind": "SMALL_PUBLIC_STARTUP", "after": _snapshot(field)})
	var definition: Resource = field.get("_current_scene")
	var before := _snapshot(field)
	field.call("_setup_scene", definition)
	var after := _snapshot(field)
	_check(after.frame == before.frame and after.rebuilding == false and after.player_id > 0 and after.player_id != before.player_id, "default setup completes synchronously with actual new Player")
	rows.append({"kind": "DEFAULT_IMMEDIATE_SETUP", "before": before, "after": after})
	before = _snapshot(field)
	_progressive(field, definition)
	var suspended := _snapshot(field)
	_check(not progressive_done and suspended.rebuilding == true and suspended.player_id == 0, "explicit progressive setup really yields before Player construction")
	if not await _wait(func() -> bool: return progressive_done, "explicit progressive setup"): return
	after = _snapshot(field)
	_check(after.frame > before.frame and after.rebuilding == false and after.player_id > 0, "progressive natural frames finish actual geometry then Player")
	rows.append({"kind": "EXPLICIT_PROGRESSIVE_SETUP", "before": before, "suspended": suspended, "after": after})
	before = _snapshot(field)
	loading.call("transition_to", FIELD, &"field", {"field_scene_id": String(MAP_ID), "field_spawn": definition.get("player_spawn"), "title": "QA small ready handshake"})
	var held := _snapshot(field)
	_check(held.process_mode == Node.PROCESS_MODE_DISABLED, "actual old Field held during resource read")
	if not await _wait(func() -> bool: return _ready_field(loading), "mandatory ready handshake"): return
	field = current_scene
	after = _snapshot(field)
	_check(after.field_id != before.field_id and after.state.complete == true and after.state.failed == false and after.state.scene_id == String(MAP_ID), "actual replacement satisfies exact mandatory ready protocol")
	_check((loading.get("_field_preloaded") as Array).is_empty() and loading.get("_source_field") == null, "successful handshake releases retained loading refs")
	rows.append({"kind": "MANDATORY_READY_HANDSHAKE", "before": before, "held": held, "after": after})
	before = _snapshot(field)
	_check(not FileAccess.file_exists("res://data/scenes/%s.tres" % MISSING_ID), "intentional missing definition fixture absent")
	loading.call("transition_to", FIELD, &"field", {"field_scene_id": MISSING_ID, "title": "QA expected resource failure"})
	if not await _wait(func() -> bool:
		var screen: Node = loading.get("_screen")
		return loading.get("_transition_active") == false and screen != null and screen.get("retry_button").visible == true,
		"expected missing-definition failure"): return
	after = _snapshot(field)
	_check(after.current and after.field_id == before.field_id and after.player_id == before.player_id and after.process_mode == before.process_mode and after.rebuilding == false, "preloader failure restores exact previous live Field and process mode")
	_check((loading.get("_field_preloaded") as Array).is_empty() and loading.get("_source_field") == null, "failed preload releases retained resources/WeakRef")
	var screen: Node = loading.get("_screen")
	rows.append({"kind": "EXPECTED_MISSING_DEFINITION_FAILURE", "missing_id": MISSING_ID, "before": before, "after": after, "failure_text": screen.get("stage_label").text, "retry_visible": screen.get("retry_button").visible, "intentional_resource_loader_errors_require_exact_log_review": true})
	loading.call("_reset_transition")
	screen.call("show_screen", true)
	hide_done = false
	_hide(screen)
	await process_frame
	screen.call("show_screen", true)
	var until := Time.get_ticks_msec() + 350
	if not await _wait(func() -> bool: return hide_done and Time.get_ticks_msec() >= until, "superseded hide releases pending call"): return
	var screen_root: Control = screen.get("root")
	_check(screen_root.visible and screen_root.modulate.a == 1.0, "old hide cannot conceal newer opaque show")
	rows.append({"kind": "NEW_SHOW_CANCELS_OLD_HIDE", "old_hide_done": hide_done, "visible": screen_root.visible, "alpha": screen_root.modulate.a, "generation": screen.get("_visibility_generation")})
	hide_done = false
	_hide(screen)
	await _wait(func() -> bool: return hide_done, "final normal hide")

func _audio_exit_state(audio: Node) -> Dictionary:
	var players: Array[Dictionary] = []
	for key: String in ["_bgm_player_a", "_bgm_player_b", "_ambience_player"]:
		var player: AudioStreamPlayer = audio.get(key) as AudioStreamPlayer
		players.append({"owner": key, "id": player.get_instance_id() if player != null else 0, "playing": player != null and player.playing, "paused": player != null and player.stream_paused, "stream_path": player.stream.resource_path if player != null and player.stream != null else "", "stream_present": player != null and player.stream != null})
	return {"current_bgm": audio.call("get_current_bgm"), "players": players}

func _normal_audio_exit(audio: Node) -> void:
	audio_cleanup.before = _audio_exit_state(audio)
	audio.call("stop_all_sfx")
	audio.call("stop_dialog_audio")
	await audio.call("stop_bgm", 0.05)
	await audio.call("stop_ambience", 0.05)
	audio_cleanup.after = _audio_exit_state(audio)
	audio_cleanup_done = true

func _quit_after_run(code: int) -> void:
	# Invoked only after _run has returned and released its local references.
	quit(code)

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended", true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true, "checkpoint held before first await through quit")
	var players := _players()
	var save: Node = root.get_node("SaveManager")
	var slot: Variant = save.get("active_slot")
	_check("--field-loading-key" in OS.get_cmdline_user_args(), "explicit limited flag")
	output = "res://build/joint_world_luoyang_20261003_qa/field_loading_key_exit_cleanup_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique QA output")
	for path: String in PINS:
		_source(path)
		_check(first[path].sha256.to_lower() == PINS[path], "frozen SHA " + path)
	for path: String in [get_script().resource_path, "res://project.godot", "res://scripts/autoload/platform_bridge.gd", "res://scripts/domain/scene_script.gd", "res://scripts/domain/walkable_map_layout.gd", "res://scripts/autoload/audio_manager.gd", "res://tests/test_field_loading_key_20261013.gd"]: _source(path)
	_import("res://art/backgrounds/bg_interior_inn_hall_v1.png")
	deadline = Time.get_ticks_msec() + 45000
	var loading: Node = root.get_node("LoadingManager")
	if failures == 0: await _exercise(loading, root.get_node("SceneRouter"))
	# No writes to player files; navigation changes belong only to this isolated process.
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
	_check(rows.size() == 6, "all six limited records completed")
	var result := {"scope": "SMALL_FIELD_LOADING_SYNC_PROGRESSIVE_READY_FAILURE_AND_VISIBILITY_ONLY", "checks": checks, "failures": failures, "complete": failures == 0, "rows": rows, "normal_audio_exit_cleanup": audio_cleanup, "source_before": first, "source_after": last, "players_before": players, "players_after": _players(), "slot_before": slot, "slot_after": save.get("active_slot"), "deadline_msec": deadline, "finished_msec": Time.get_ticks_msec(), "actual_driver": AudioServer.get_driver_name(), "expected_failure_id": MISSING_ID, "full_stderr_expected_failure_classification_required": true, "world_or_city_contract_tested": false, "audio_or_movement_credit": false, "smoothness_or_full_acceptance_credit": false, "outer_exact_UTC_ticks_and_dependency_closure_required": true}
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result, "\t"))
		file.close()
	_check(file != null and JSON.parse_string(FileAccess.get_file_as_string(output + "result.json")) is Dictionary, "result written and read back")
	print("FIELD_LOADING_KEY_RESULT=" + output + "result.json checks=" + str(checks) + " failures=" + str(failures))
	file = null
	call_deferred("_quit_after_run", 0 if failures == 0 else 1)
