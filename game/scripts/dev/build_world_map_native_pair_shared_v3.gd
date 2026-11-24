extends "res://scripts/dev/build_world_map_native_pair_shared_v2.gd"

# Visual-only fixed-light heightfield trial. Coast/road topology and navigation
# are byte-identical to v1/v2; the rendered pair still fails until reviewed.


func _output_prefix() -> String:
	return "res://build/world_native_pair_shared_v3_"


func _relief_strength() -> float:
	return 0.86
