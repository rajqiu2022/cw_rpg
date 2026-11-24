extends "res://tests/test_world_map_v14_production_20261002.gd"

## The normal public new-game initialization precedes the unchanged FULL suite.
## This does not restore a fabricated save, bypass migration, or run candidate mode.
const CANONICAL_PARENT_SHA := "068dc74f3c5025056b14b5cddccf8693fc94f739537e7ac165a351fd5528e55c"
const CANONICAL_CONTRACT := preload("res://scripts/world/world_map_v14_contract.gd")

func _begin_owned_test_run() -> void:
	_check(FileAccess.get_sha256("res://tests/test_world_map_v14_production_20261002.gd") == CANONICAL_PARENT_SHA, "canonical launcher inherits the exact frozen FULL source")
	_check(not "--candidate-before-cutover" in OS.get_cmdline_user_args(), "canonical FULL launcher rejects candidate mode")
	_check(CANONICAL_CONTRACT.formal_version() == 14, "actual published canonical world is version 14 before public reset")
	var router := root.get_node_or_null("SceneRouter")
	var saves := root.get_node_or_null("SaveManager")
	_check(router != null and saves != null, "canonical launcher uses the actual existing navigation/save autoloads")
	if failed > 0:
		quit(1)
		return
	var before: Dictionary = _canonical_reset_player_files()
	var before_slot: int = int(saves.get("active_slot"))
	router.call("reset_for_new_game")
	var navigation: Dictionary = router.call("get_navigation_state")
	_check(_domain_equal(navigation, {"current_field": "", "portal_return_spawns": {}, "world_map_version": 14}), "public new-game reset establishes exact v14 empty navigation with no spawn or world-return keys")
	_check(_domain_equal(before, _canonical_reset_player_files()), "public reset leaves every normal save/backup/temp and existing root save file byte-identical")
	_check(int(saves.get("active_slot")) == before_slot, "public navigation reset does not change the managed save slot")
	if failed > 0:
		quit(1)
		return
	print("[CanonicalFullLauncher] " + JSON.stringify({"executing_script_path": get_script().resource_path, "executing_script_sha256": FileAccess.get_sha256(get_script().resource_path), "parent_source_sha256": FileAccess.get_sha256("res://tests/test_world_map_v14_production_20261002.gd"), "public_reset_navigation": navigation, "player_files_before_reset": before, "active_slot": before_slot}))
	# The parent still owns _run, all gameplay assertions, baseline snapshot and
	# cleanup. Its new baseline is the real public new-game state, not cold v12.
	super._begin_owned_test_run()

func _canonical_reset_player_files() -> Dictionary:
	var result: Dictionary = _actual_player_saves()
	var directory := DirAccess.open("user://")
	_check(directory != null, "normal user save directory is readable without writes")
	if directory != null:
		for filename: String in directory.get_files():
			if filename.begins_with("save"):
				var path: String = "user://" + filename
				result[path] = FileAccess.get_sha256(path)
	return result
