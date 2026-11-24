extends "res://scripts/dev/render_polyhaven_boulder_v4.gd"


func _output_path() -> String:
	return "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v4b.png"


func _meta_path() -> String:
	return "res://art/modules/world_map_v13/boulder_01_cc0_ortho_v4b.json"


func _configure_model(model: Node3D) -> void:
	super._configure_model(model)
	model.rotation_degrees.y = -55.0


func _processing_metadata() -> Dictionary:
	var metadata := super._processing_metadata()
	metadata["yaw_degrees"] = -55.0
	return metadata
