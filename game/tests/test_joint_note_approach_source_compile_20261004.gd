extends SceneTree

func _initialize() -> void:
	var passed := true
	for path: String in ["res://tests/helpers/joint_v15_wall_v5_note_approach_diagnostic_phase.gd", "res://tests/test_joint_v15_city_wall_v5_note_approach_limited_20261004.gd"]:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var valid := script != null and script.can_instantiate()
		passed = passed and valid
		print(JSON.stringify({"source": path, "sha256": FileAccess.get_sha256(path), "can_instantiate": valid, "scope": "SOURCE_COMPILE_ONLY_NOT_FIELD_APPROVAL"}))
	quit(0 if passed else 1)
