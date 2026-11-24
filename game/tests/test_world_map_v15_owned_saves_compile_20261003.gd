extends SceneTree
## LIMITED dependency compilation, not candidate/runtime/save acceptance.
const OWNED_PATH := "res://tests/helpers/v15_isolated_save_manager.gd"
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[V15 owned-save compile FAIL] " + label)

func _run() -> void:
	var before: Dictionary = _save_files()
	for singleton: String in ["GameState", "Inventory", "QuestManager", "SceneRouter", "SaveManager"]:
		_check(root.has_node(singleton), "real autoload registered before inherited script loading: " + singleton)
	var script: Script = load(OWNED_PATH) as Script
	_check(script != null and script.can_instantiate(), "inherited actual SaveManager dynamically compiles with registered singletons")
	if script != null and script.can_instantiate():
		var owned: Node = script.new() as Node
		_check(owned != null, "actual inherited instance; no candidate or slot action")
		if owned != null:
			_check(String(owned.get("isolated_dir")).is_empty(), "unconfigured isolated manager cannot select player directory")
			_check(String(owned.call("slot_path", 0)).is_empty(), "unconfigured primary path remains closed")
			_check(String(owned.call("slot_backup_path", 0)).is_empty(), "unconfigured backup path remains closed")
			owned.free()
	_check(before == _save_files(), "normal player save bytes unchanged without invoking save/load")
	print("V15_OWNED_SAVE_DEFERRED_COMPILE_ONLY: %d checks / %d failures; NO FIELD / NO SAVE LOAD / NO GPU" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _save_files() -> Dictionary:
	var result: Dictionary = {}
	var directory: DirAccess = DirAccess.open("user://")
	_check(directory != null, "normal save directory can be independently read")
	if directory != null:
		for filename: String in directory.get_files():
			if filename.begins_with("save"):
				var path: String = "user://" + filename
				result[path] = FileAccess.get_sha256(path)
	return result
