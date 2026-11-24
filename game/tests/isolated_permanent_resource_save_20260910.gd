extends "res://scripts/autoload/save_manager.gd"

var isolated_dir: String

func slot_path(slot: int) -> String:
	return isolated_dir.path_join("save_%d.json" % clamp_slot(slot))

func slot_backup_path(slot: int) -> String:
	return slot_path(slot) + ".bak"
