extends "res://scripts/dev/render_polyhaven_boulder_v3.gd"


func _source_path() -> String:
	return "res://art/external/polyhaven/shrub_03/shrub_03_1k.gltf"


func _camera_size() -> float:
	return 0.7


func _output_path() -> String:
	return "res://art/modules/world_map_v13/shrub_03_cc0_ortho_v7.png"


func _meta_path() -> String:
	return "res://art/modules/world_map_v13/shrub_03_cc0_ortho_v7.json"


func _configure_model(model: Node3D) -> void:
	# The glTF contains four separate scan variations laid out side by side.
	# Extract one botanical entity, not a horizontal floating catalogue strip.
	var meshes: Array[MeshInstance3D] = []
	_bounds(model,meshes)
	for index in range(1,meshes.size()):
		meshes[index].get_parent().remove_child(meshes[index])
		meshes[index].free()
	model.rotation_degrees.y = 22.0


func _processing_metadata() -> Dictionary:
	return {"yaw_degrees":22,"mesh_variant":"shrub_03_a","camera_size":0.7,"adoption":"isolated_candidate_only","source_page":"https://polyhaven.com/a/shrub_03"}
