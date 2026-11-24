extends SceneTree
## LIMITED: autoload-context source compilation ONLY. Never publishes, prepares
## candidates, instantiates a publisher, enters Field, or grants gameplay PASS.
const TARGETS: Array[String] = [
	"res://scripts/dev/world_map_v15_complete_v5_publication_gate.gd",
	"res://scripts/dev/publish_world_map_v15_complete_v5.gd",
	"res://scripts/city/luoyang_layered_v3_contract.gd",
	"res://scripts/world/world_map_v15_contract.gd",
	"res://scripts/world/v15_modular_overlap.gd",
	"res://scripts/field/world_v15_exit_zone.gd",
	"res://scripts/dev/world_map_v15_complete_v5_source.gd",
	"res://scripts/dev/world_map_v15_complete_v5_surface.gd",
	"res://scripts/dev/build_world_map_v15_complete_v5.gd",
	"res://scripts/dev/luoyang_modular_v3_source.gd",
	"res://scripts/dev/luoyang_modular_v3_surface.gd",
	"res://scripts/dev/build_luoyang_modular_v3.gd",
	"res://scripts/dev/world_v15_outskirts_complete_v5_source.gd",
	"res://scripts/dev/world_v15_outskirts_complete_v5_surface.gd",
	"res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd",
	"res://scripts/dev/build_world_v15_outskirts_complete_v5.gd",
	"res://scripts/world/outskirts_native_contract.gd",
	"res://scripts/autoload/scene_router.gd",
	"res://scripts/autoload/save_manager.gd",
	"res://scripts/field/field_walkable_controller.gd",
]
var checks: int = 0
var failures: int = 0
var records: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[JOINT source-context FAIL] " + label)

func _normal_files() -> Dictionary:
	var found: Dictionary = {}
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = "user://save_%d.json%s" % [slot, suffix]
			var record: Dictionary = {"exists": FileAccess.file_exists(path)}
			if record.exists:
				var file: FileAccess = FileAccess.open(path, FileAccess.READ)
				record["readable"] = file != null
				if file != null:
					record["bytes"] = file.get_length()
					file.close()
				record["sha256"] = FileAccess.get_sha256(path)
				record["godot_modified_seconds"] = FileAccess.get_modified_time(path)
			found[ProjectSettings.globalize_path(path)] = record
	return found

func _save_result(path: String, value: Dictionary) -> bool:
	if FileAccess.file_exists(path): return false
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	var encoded: String = JSON.stringify(value, "\t")
	file.store_string(encoded)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK: return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var canonical: Variant = JSON.parse_string(encoded)
	return parsed is Dictionary and parsed == canonical

func _run() -> void:
	var before_files: Dictionary = _normal_files()
	for id: String in ["GameState", "Inventory", "QuestManager", "BountyManager", "SceneRouter", "SaveManager"]:
		_check(root.has_node(id), "actual autoload registered before loading sources: " + id)
	if failures > 0:
		print("JOINT_SOURCE_CONTEXT_COMPILE_ONLY: %d checks / %d failures; AUTOLOADS_MISSING; NO FIELD/GPU/PUBLICATION" % [checks, failures])
		quit(1)
		return
	var router: Node = root.get_node("SceneRouter")
	var save_manager: Node = root.get_node("SaveManager")
	var before_navigation: Dictionary = router.call("get_navigation_state").duplicate(true)
	var before_slot: Variant = save_manager.get("active_slot")
	for path: String in TARGETS:
		var present: bool = FileAccess.file_exists(path)
		_check(present, "required current source exists: " + path)
		var script: GDScript = load(path) as GDScript if present else null
		var compiled: bool = script != null and script.can_instantiate()
		_check(compiled, "dynamic compile after normal autoload registration: " + path)
		records.append({"path": path, "sha256": FileAccess.get_sha256(path) if present else "", "compiled": compiled})
		# Do not new() SceneTree or call any candidate/publication API.
		script = null
	var after_files: Dictionary = _normal_files()
	_check(before_files == after_files, "all fifteen normal primary/bak/tmp positions bytes/size/second-mtime unchanged")
	_check(before_navigation == router.call("get_navigation_state"), "source compilation leaves managed navigation unchanged")
	_check(before_slot == save_manager.get("active_slot"), "active slot unchanged; no save/load invoked")
	var output: String = "res://build/joint_world_luoyang_20261003_qa/source_context_%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output) == OK, "new QA evidence directory")
	var result: Dictionary = {"schema": 1, "scope": "JOINT_AUTOLOAD_SOURCE_COMPILE_ONLY_NOT_ACCEPTANCE", "checks": checks + 1, "failures": failures, "completed": failures == 0, "engine_pid": OS.get_process_id(), "records": records, "normal_files_before": before_files, "normal_files_after": after_files, "player_saves_unchanged": before_files == after_files, "exact_UTCticks": "NOT_AVAILABLE_FROM_GODOT; external root compares fresh exact ticks", "executing_script_path": get_script().resource_path, "executing_script_sha256": FileAccess.get_sha256(get_script().resource_path), "field_executed": false, "gpu_executed": false, "publication_executed": false, "candidate_ready_claimed": false}
	_check(_save_result(output + "result.json", result), "compile evidence persisted with exact JSON readback")
	router = null
	save_manager = null
	for frame in 4: await process_frame
	print("JOINT_SOURCE_CONTEXT_COMPILE_ONLY: %d checks / %d failures; NO FIELD / NO GPU / NO PUBLICATION; output=%s" % [checks, failures, output])
	quit(0 if failures == 0 else 1)
