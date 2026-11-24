extends "res://scripts/dev/render_polyhaven_boulder_v3.gd"


func _output_path() -> String:
	return "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v4.png"


func _meta_path() -> String:
	return "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v4.json"


func _processing_metadata() -> Dictionary:
	return {"geometry_scale": [1.0, 0.6, 1.0], "yaw_degrees": 35.0, "albedo_multiplier": [0.72, 0.77, 0.73], "adoption": "isolated_candidate_only"}


func _configure_model(model: Node3D) -> void:
	# A low embedded rock, not an upright pale slab. Transform the licensed
	# geometry before rendering so its foot projection is recomputed as well.
	model.scale = Vector3(1.0, 0.60, 1.0)
	model.rotation_degrees.y = 35.0
	var meshes: Array[MeshInstance3D] = []
	_bounds(model, meshes)
	for mesh in meshes:
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.get_active_material(surface)
			if original is StandardMaterial3D:
				var material := original.duplicate() as StandardMaterial3D
				material.albedo_color *= Color(0.72, 0.77, 0.73)
				material.roughness = 1.0
				mesh.set_surface_override_material(surface, material)
