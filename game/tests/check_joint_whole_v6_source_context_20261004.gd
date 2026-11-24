extends SceneTree
## Read-only source compilation and mechanism checks. No new() of a publisher,
## no capture, Field, candidate preparation, rewards, save/load or visual credit.
const TARGETS := {
	"res://scripts/dev/world_map_v15_complete_v6_publication_gate.gd": "7d4a629d5e81c7a6f8eb5d89a1b27f6fef4f45e8f333a2adbfeb8f2fbce39634",
	"res://scripts/dev/publish_world_map_v15_complete_v6.gd": "60902b36a6807f1e0ebb90aaa8a4dbedbff3515db73101cfedc6a48976de4e22",
	"res://tests/helpers/joint_v15_city_gameplay_natural_grace_phase.gd": "18e1f66a052ea202f196a845807a06005c30c2ed715e1422e81607cb6c718f45",
}
const PILOT := "res://build/world_map_v15_coherent_whole_v6_pilot/1791066772_2575509/result.json"
const PILOT_SHA := "ca506b4f4f84e02d5cea327264636599cb421f9f48148fdd7961f114f919dbf1"
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[WHOLE V6 SOURCE UNIT FAIL] " + label)

func _files() -> Dictionary:
	var result: Dictionary = {}
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path := "user://save_%d.json%s" % [slot, suffix]
			var record := {"exists": FileAccess.file_exists(path)}
			if bool(record.exists):
				var file := FileAccess.open(path, FileAccess.READ)
				record["bytes"] = file.get_length() if file != null else -1
				if file != null: file.close()
				record["sha256"] = FileAccess.get_sha256(path)
				record["modified_seconds"] = FileAccess.get_modified_time(path)
			result[path] = record
	return result

func _run() -> void:
	var files_before := _files()
	var router: Node = root.get_node("SceneRouter")
	var manager: Node = root.get_node("SaveManager")
	var navigation_before: Dictionary = router.call("get_navigation_state").duplicate(true)
	var slot_before: Variant = manager.get("active_slot")
	var sources: Array[Dictionary] = []
	var gate: GDScript = null
	for path: String in TARGETS:
		_check(FileAccess.get_sha256(path).to_lower() == TARGETS[path], "exact current reviewed source " + path)
		var script: GDScript = load(path) as GDScript
		_check(script != null and script.can_instantiate(), "autoload-context dynamic compilation only " + path)
		sources.append({"path": path, "sha256": FileAccess.get_sha256(path), "compiled": script != null and script.can_instantiate()})
		if path.ends_with("publication_gate.gd"): gate = script
		script = null
	_check(FileAccess.get_sha256(PILOT).to_lower() == PILOT_SHA, "original actual pilot remains immutable")
	if failures == 0 and gate != null:
		var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PILOT)) as Dictionary
		var camera: Dictionary = original.worlds.primary.camera
		_check(bool(gate.call("_whole_camera", camera, 2)), "new mechanism accepts exact actual pilot whole camera only, not full proof")
		var wrong: Dictionary = camera.duplicate(true)
		wrong.size_m = 20
		_check(not bool(gate.call("_whole_camera", wrong, 2)), "local frustum cannot impersonate full whole camera")
		_check(not String(gate.call("_whole_error", original, {}, {})).is_empty(), "pilot never grants new full capture approval")
		var windows: Dictionary = gate.call("_expected_windows")
		_check(windows.size() == 176, "64 cells and 112 adjacency windows in independent full topology")
		for row in 8:
			for col in 8:
				var id := "r%d_c%d" % [row, col]
				_check(windows.get(id) == [col * 1536, row * 1024, 1536, 1024], "exact native full cell identity " + id)
	gate = null
	_check(files_before == _files(), "all15 normal save paths unchanged")
	_check(navigation_before == router.call("get_navigation_state") and slot_before == manager.get("active_slot"), "normal navigation and active slot unchanged")
	var output := "res://build/joint_world_luoyang_20261003_qa/whole_v6_source_unit_%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output) == OK, "unique source-only evidence")
	var report := {"scope": "WHOLE_V6_AUTOLOAD_SOURCE_MECHANISM_ONLY_NOT_CAPTURE_FIELD_OR_ACCEPTANCE", "checks": checks + 1, "failures": failures, "sources": sources, "executing_source": get_script().resource_path, "executing_sha256": FileAccess.get_sha256(get_script().resource_path), "engine_pid": OS.get_process_id(), "field_executed": false, "GPU_capture_executed": false, "candidate_published": false, "visual_approved": false, "player_files_before": files_before, "player_files_after": _files()}
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	var saved := file != null
	if file != null:
		var encoded := JSON.stringify(report, "\t")
		file.store_string(encoded)
		file.flush()
		saved = file.get_error() == OK
		file.close()
		saved = saved and JSON.parse_string(FileAccess.get_file_as_string(output + "result.json")) == JSON.parse_string(encoded)
	_check(saved, "actual source-only report readback")
	router = null
	manager = null
	for tick in 4: await process_frame
	print("WHOLE_V6_SOURCE_MECHANISM_ONLY: %d checks / %d failures; output=%s" % [checks, failures, output])
	quit(0 if failures == 0 else 1)
