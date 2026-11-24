extends SceneTree
## Startup availability ONLY: no Field, playback request, device setter,
## system configuration, continuity verdict, RELEASE or formal approval.
## Normal AudioManager autoload keeps its original silent startup warmup;
## this probe neither requests playback nor disables that production behavior.
const SCOPE: String = "READ_ONLY_AUDIO_STARTUP_10_FRAMES_NOT_CONTINUITY_OR_RELEASE"
const EXECUTABLE_SHA: String = "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const SOURCE_ROOTS: Array[String] = ["res://scripts", "res://tests", "res://data", "res://scenes"]
var failures: int = 0
var checks: int = 0
var source_scan_ok: bool = true

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[AUDIO STARTUP READONLY] " + label)

func _file_record(path: String) -> Dictionary:
	var result: Dictionary = {"exists":FileAccess.file_exists(path)}
	if not result.exists: return result
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	result["readable"] = file != null
	if file == null: return result
	result["bytes"] = file.get_length()
	file.close()
	result["sha256"] = FileAccess.get_sha256(path)
	result["modified_seconds"] = FileAccess.get_modified_time(path)
	return result

func _source_tree(path: String, result: Dictionary) -> void:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		source_scan_ok = false
		return
	var files: PackedStringArray = directory.get_files()
	files.sort()
	for name: String in files:
		if name.get_extension() in ["gd", "tscn", "tres", "json", "godot", "gdshader"]:
			var child: String = path.path_join(name)
			result[child] = _file_record(child)
			if result[child].get("readable") != true or String(result[child].get("sha256", "")).length() != 64:
				source_scan_ok = false
	var directories: PackedStringArray = directory.get_directories()
	directories.sort()
	for name: String in directories:
		_source_tree(path.path_join(name), result)

func _sources() -> Dictionary:
	source_scan_ok = true
	var result: Dictionary = {"res://project.godot":_file_record("res://project.godot")}
	if result["res://project.godot"].get("readable") != true: source_scan_ok = false
	for path: String in SOURCE_ROOTS: _source_tree(path, result)
	return result

func _players() -> Dictionary:
	var result: Dictionary = {}
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = "user://save_%d.json%s" % [slot, suffix]
			result[ProjectSettings.globalize_path(path)] = _file_record(path)
	return result

func _environment(frame_index: int) -> Dictionary:
	return {"frame_index":frame_index, "ticks_usec":Time.get_ticks_usec(),
		"actual_audio_driver":AudioServer.get_driver_name(),
		"output_devices":AudioServer.get_output_device_list(), "output_device":AudioServer.output_device,
		"output_mix_rate_hz":AudioServer.get_mix_rate(), "output_latency_sec":AudioServer.get_output_latency(),
		"engine_version":Engine.get_version_info(), "display_driver":DisplayServer.get_name(),
		"executable_path":OS.get_executable_path(), "executable_sha256":FileAccess.get_sha256(OS.get_executable_path()),
		"engine_time_scale":Engine.time_scale, "global_audio_speed_scale":AudioServer.playback_speed_scale,
		"fallback_list_is_not_WASAPI_device_inventory":AudioServer.get_driver_name() != "WASAPI"}

func _write(path: String, value: Dictionary) -> bool:
	if FileAccess.file_exists(path): return false
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	var encoded: String = JSON.stringify(value, "\t", true)
	file.store_string(encoded)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	return error == OK and FileAccess.get_file_as_string(path) == encoded

func _run() -> void:
	_check(OS.get_cmdline_user_args().is_empty(), "no hidden gameplay/device selection arguments")
	_check(current_scene == null, "no Field or main scene instantiated")
	var save: Node = root.get_node_or_null("SaveManager")
	_check(save != null, "normal SaveManager available for readonly active-slot preservation")
	if save == null: quit(1); return
	var slot_before: Variant = save.get("active_slot")
	var players_before: Dictionary = _players()
	var sources_before: Dictionary = _sources()
	_check(source_scan_ok and sources_before.size() > 0, "complete repository-native source tree readable and hashed; no art-byte proof claimed")
	_check(players_before.size() == 15, "all15 normal player paths captured")
	for row: Dictionary in players_before.values():
		_check(row.get("exists") == false or (row.get("readable") == true and String(row.get("sha256", "")).length() == 64), "existing protected player file readable")
	var output: String = "res://build/joint_world_luoyang_20261003_qa/audio_startup_readonly_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	var unique_output: bool = not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK
	_check(unique_output, "unique BUILD-only diagnostic evidence directory")
	if not unique_output:
		quit(1)
		return
	var rows: Array[Dictionary] = []
	for frame_index in 10:
		await process_frame
		var row: Dictionary = _environment(frame_index)
		rows.append(row)
		print("AUDIO_STARTUP_READONLY_FRAME " + JSON.stringify(row))
		_check(row.actual_audio_driver == "WASAPI", "actual WASAPI required; Dummy never receives backend availability credit")
		_check(row.executable_sha256 == EXECUTABLE_SHA, "actual original installed executable identity")
		_check(is_finite(float(row.output_mix_rate_hz)) and float(row.output_mix_rate_hz) > 0.0 and is_finite(float(row.output_latency_sec)) and float(row.output_latency_sec) >= 0.0, "finite actual output metadata")
	var sources_after: Dictionary = _sources()
	var players_after: Dictionary = _players()
	_check(source_scan_ok and sources_after == sources_before, "complete native source set/SHA/bytes/mtime unchanged")
	_check(players_after == players_before and save.get("active_slot") == slot_before, "all15 files and active slot unchanged; no restoration writes")
	_check(current_scene == null and Engine.time_scale == 1.0 and AudioServer.playback_speed_scale == 1.0, "no Field and unaltered ordinary clocks")
	var result: Dictionary = {"schema":1, "scope":SCOPE, "checks":checks, "failures":failures,
		"engine_pid":OS.get_process_id(), "output":output, "samples":rows,
		"source_roots":SOURCE_ROOTS, "source_extensions":["gd","tscn","tres","json","godot","gdshader"],
		"sources_before":sources_before, "sources_after":sources_after, "players_before":players_before, "players_after":players_after,
		"active_slot_before":slot_before, "active_slot_after":save.get("active_slot"),
		"probe_playback_requested":false, "device_setter_called":false, "system_configuration_changed":false,
		"normal_autoload_silent_warmup_not_disabled":true, "art_binary_snapshot_claimed":false,
		"continuity_passed":false, "DAC_continuity_proven":false, "source_version_equivalence_proven":false,
		"Field_executed":false, "release_complete":false, "formal_cutover":false}
	_check(_write(output + "result.json", result), "full before/after diagnostic persisted without overwrite")
	print("AUDIO_STARTUP_READONLY_END checks=%d failures=%d actual_driver=%s sources=%d output=%s" % [checks,failures,AudioServer.get_driver_name(),sources_before.size(),output])
	quit(0 if failures == 0 else 1)
