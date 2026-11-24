extends SceneTree

## LIMITED cold-navigation diagnostic. No Field, slots, or gameplay acceptance.
const CONTRACT := preload("res://scripts/world/world_map_v14_contract.gd")
const FULL_PATH := "res://tests/test_world_map_v14_production_20261002.gd"
const FULL_SHA := "068dc74f3c5025056b14b5cddccf8693fc94f739537e7ac165a351fd5528e55c"
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[CanonicalColdNavigation FAIL] " + label)

func _normal_save_files() -> Dictionary:
	var result: Dictionary = {}
	for slot in range(5):
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = "user://save_%d.json%s" % [slot, suffix]
			result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT"
	var directory := DirAccess.open("user://")
	_check(directory != null, "normal user save directory is read-only accessible")
	if directory != null:
		for filename: String in directory.get_files():
			if filename.begins_with("save"):
				var path: String = "user://" + filename
				result[path] = FileAccess.get_sha256(path)
	return result

func _run() -> void:
	_check(DisplayServer.get_name() == "headless", "bounded diagnostic is headless only")
	_check(not "--candidate-before-cutover" in OS.get_cmdline_user_args(), "diagnostic uses actual canonical publication, not candidate")
	_check(FileAccess.get_sha256(FULL_PATH) == FULL_SHA, "unchanged frozen FULL source is the baseline under diagnosis")
	_check(CONTRACT.formal_version() == 14, "actual formal resource is version 14")
	var router := root.get_node_or_null("SceneRouter")
	var saves := root.get_node_or_null("SaveManager")
	_check(router != null and saves != null, "actual navigation and save autoloads exist")
	if failures > 0:
		quit(1)
		return
	var before: Dictionary = _normal_save_files()
	var before_slot: int = int(saves.get("active_slot"))
	var cold: Dictionary = router.call("get_navigation_state").duplicate(true)
	var expected_cold: Dictionary = {"current_field": "", "portal_return_spawns": {}, "world_map_version": 12}
	var expected_reset: Dictionary = {"current_field": "", "portal_return_spawns": {}, "world_map_version": 14}
	_check(cold == expected_cold, "genuine untouched cold autoload navigation has version 12 and no field/spawn/returns")
	router.call("restore_navigation_state", cold)
	var cold_restored: Dictionary = router.call("get_navigation_state").duplicate(true)
	_check(cold_restored == expected_reset, "public restore genuinely migrates the cold version to canonical 14")
	_check(cold_restored != cold, "cold snapshot restoration is intentionally not an identity after canonical activation")
	_check(before == _normal_save_files() and int(saves.get("active_slot")) == before_slot, "cold restore migration performs no normal save writes or active-slot change")
	router.call("reset_for_new_game")
	var reset: Dictionary = router.call("get_navigation_state").duplicate(true)
	_check(reset == expected_reset, "public new-game reset supplies genuine canonical empty v14 navigation")
	router.call("restore_navigation_state", reset)
	var reset_restored: Dictionary = router.call("get_navigation_state").duplicate(true)
	_check(reset_restored == reset, "public-reset canonical snapshot restores exactly, without migration drift")
	_check(before == _normal_save_files() and int(saves.get("active_slot")) == before_slot, "public reset plus restore leaves normal player files and selected slot unchanged")
	# Only exit-time public audio stops and custom-cursor release. No production
	# node deletion, slot loading, cache purge, or synthetic navigation assignment.
	var audio := root.get_node_or_null("AudioManager")
	if audio != null:
		audio.call("stop_music_sting")
		audio.call("stop_all_sfx")
		audio.call("stop_dialog_audio")
		await audio.call("stop_bgm", 0.0)
		await audio.call("stop_ambience", 0.0)
	var cursor_refs: Array[WeakRef] = []
	var cursors := root.get_node_or_null("CursorManager")
	_check(cursors != null, "exit-time cursor release uses the actual autoload")
	if cursors != null:
		for pair: Array in [["_arrow", Input.CURSOR_ARROW], ["_hand", Input.CURSOR_POINTING_HAND], ["_wait", Input.CURSOR_WAIT]]:
			var texture := cursors.get(String(pair[0])) as Texture2D
			if texture != null: cursor_refs.append(weakref(texture))
			Input.set_custom_mouse_cursor(null, int(pair[1]))
			cursors.set(String(pair[0]), null)
			texture = null
	await create_timer(.20).timeout
	for settle in 8:
		await process_frame
		await physics_frame
	for reference: WeakRef in cursor_refs:
		_check(not is_instance_valid(reference.get_ref()), "actual process-exit cursor texture is naturally released")
	var after: Dictionary = _normal_save_files()
	_check(before == after and int(saves.get("active_slot")) == before_slot, "all normal save files and managed slot remain unchanged after diagnostic exit cleanup")
	var output: String = "res://build/world_map_v14_qa/canonical_cold_navigation_%d/" % Time.get_ticks_usec()
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique diagnostic-only result directory")
	var report: Dictionary = {"schema": 1, "scope": "LIMITED_CANONICAL_COLD_NAVIGATION_NOT_FULL", "checks": checks, "failures": failures,
		"executing_script_path": get_script().resource_path, "executing_script_sha256": FileAccess.get_sha256(get_script().resource_path), "full_source_path": FULL_PATH, "full_source_sha256": FileAccess.get_sha256(FULL_PATH),
		"formal_version": CONTRACT.formal_version(), "cold": cold, "cold_restored": cold_restored, "public_reset": reset, "reset_restored": reset_restored,
		"player_files_before": before, "player_files_after": after, "player_saves_unchanged": before == after, "active_slot_before": before_slot, "active_slot_after": int(saves.get("active_slot")), "field_runtime_executed": false, "full_acceptance_executed": false}
	var path: String = output + "result.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "diagnostic result opens for writing")
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.flush()
		var error: Error = file.get_error()
		file.close()
		file = null
		_check(error == OK, "diagnostic result flush succeeds")
		var readback: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		_check(readback is Dictionary and readback == JSON.parse_string(JSON.stringify(report)), "exact diagnostic result readback")
	print("[CanonicalColdNavigation] LIMITED checks=%d failures=%d output=%s" % [checks, failures, output])
	quit(1 if failures > 0 else 0)
