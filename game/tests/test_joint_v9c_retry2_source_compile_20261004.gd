extends SceneTree

func _initialize() -> void:
	var sources := ["res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v3.gd","res://scripts/dev/build_world_map_v15_v9c_visual_quality_proposal_retry2.gd"]
	var passed := true
	for path: String in sources:
		var script := ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Script
		var valid := script != null and script.can_instantiate()
		passed = passed and valid
		print(JSON.stringify({"source":path,"sha256":FileAccess.get_sha256(path),"can_instantiate":valid,"scope":"SOURCE_COMPILE_ONLY_NOT_FIELD_GPU_OR_GEOMETRY_APPROVAL"}))
	quit(0 if passed else 1)
