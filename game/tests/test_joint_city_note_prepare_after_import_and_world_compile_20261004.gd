extends "res://tests/test_joint_city_note_actual_resource_prepare_20261004.gd"

func _run() -> void:
	for path: String in ["res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd", "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_regional_proposal.gd"]:
		var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var valid := script != null and script.can_instantiate()
		print(JSON.stringify({"source":path,"sha256":FileAccess.get_sha256(path),"can_instantiate":valid,"scope":"WORLD_SOURCE_COMPILE_ONLY_NOT_GPU_OR_FULL"}))
		if not valid:
			quit(1)
			return
	super._run()
