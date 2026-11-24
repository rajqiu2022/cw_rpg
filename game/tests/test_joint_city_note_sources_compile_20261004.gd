extends SceneTree

func _initialize() -> void:
	var passed := true
	for path: String in ["res://scripts/dev/luoyang_modular_v3_wall_v5_note_source.gd", "res://scripts/dev/build_luoyang_modular_v3_wall_v5_note_capture.gd", "res://scripts/dev/luoyang_v3_wall_v5_note_saved_resource_checker.gd", "res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd", "res://scripts/dev/publish_luoyang_v3_wall_v5_note_candidate.gd"]:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var valid := script != null and script.can_instantiate()
		passed = passed and valid
		print(JSON.stringify({"source":path,"sha256":FileAccess.get_sha256(path),"can_instantiate":valid,"scope":"SOURCE_COMPILE_ONLY_NOT_CAPTURE_FIELD_OR_PUBLICATION"}))
	quit(0 if passed else 1)
