extends "res://scripts/autoload/save_manager.gd"
## Real SaveManager implementation; only test-owned paths differ.
var isolated_dir := ""

func configure_directory(path: String) -> bool:
	if not path.begins_with("user://world_map_v15_qa/") or ".." in path or path.ends_with("/"): return false
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path)) != OK: return false
	isolated_dir = path
	return true

func slot_path(slot: int) -> String:
	return isolated_dir.path_join("save_%d.json" % clamp_slot(slot)) if not isolated_dir.is_empty() else ""

func slot_backup_path(slot: int) -> String:
	return slot_path(slot) + ".bak" if not isolated_dir.is_empty() else ""

func _write_slot_atomic(slot: int, text: String) -> bool:
	if isolated_dir.is_empty() or not slot_path(slot).begins_with("user://world_map_v15_qa/"): return false
	return super._write_slot_atomic(slot, text)
