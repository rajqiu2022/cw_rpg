extends SceneTree

func _initialize() -> void:
	var passed := true
	for path: String in ["res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd", "res://scripts/world/world_map_v15_complete_v9c_candidate_contract.gd", "res://scripts/dev/publish_world_map_v15_complete_v9c_candidate.gd"]:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var valid := script != null and script.can_instantiate()
		passed = passed and valid
		print(JSON.stringify({"source":path,"sha256":FileAccess.get_sha256(path),"can_instantiate":valid,"scope":"SOURCE_COMPILE_ONLY_NOT_CAPTURE_FIELD_OR_PUBLICATION"}))
	quit(0 if passed else 1)
