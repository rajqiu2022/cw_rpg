extends "res://scripts/dev/build_world_map_native_pair_shared_v1.gd"

# Same topology, road and navigation as v1. Only the ground's broad visual
# variation and water grading change; image generation cannot move the shore.
const MACRO_GROUND := "res://art/modules/world_map_v13/terrain_macro_ground_v2_candidate.png"


func _output_prefix() -> String:
	return "res://build/world_native_pair_shared_v2_"


func _macro_ground_path() -> String:
	return MACRO_GROUND


func _macro_blend() -> float:
	return 0.74


func _water_tint() -> Color:
	return Color(0.30, 0.48, 0.56)
