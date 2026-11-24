extends SceneTree

var failures := 0


func _initialize() -> void:
	var root := get_root()
	var game_state := root.get_node("GameState")
	var inventory := root.get_node("Inventory")
	var quest_manager := root.get_node("QuestManager")
	var investigation := root.get_node("InvestigationState")
	var save_manager := root.get_node("SaveManager")
	game_state.call("reset_for_new_game")
	inventory.call("reset_for_new_game")
	quest_manager.call("reset_for_new_game")
	investigation.call("reset_for_new_game")
	save_manager.set("active_slot", 3)
	game_state.set("gold", 101)
	_check(bool(save_manager.call("save_to_slot", 3)), "first atomic save succeeds")
	var primary_path := String(save_manager.call("slot_path", 3))
	var backup_path := String(save_manager.call("slot_backup_path", 3))
	_check(FileAccess.file_exists(primary_path), "primary save exists")
	game_state.set("gold", 202)
	_check(bool(save_manager.call("save_to_slot", 3)), "second atomic save succeeds")
	_check(FileAccess.file_exists(backup_path), "previous save is retained as backup")
	var corrupt := FileAccess.open(primary_path, FileAccess.WRITE)
	_check(corrupt != null, "test can replace the primary save")
	if corrupt != null:
		corrupt.store_string("{broken-json")
		corrupt.close()
	game_state.set("gold", 0)
	_check(bool(save_manager.call("load_from_slot", 3)), "corrupt primary recovers from backup")
	_check(int(game_state.get("gold")) == 101, "backup contains the previous complete checkpoint")
	print("[SaveAtomicRecovery20260824] checks=8 failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
