extends "res://tests/test_world_native_pair_field_props_v5.gd"


func _prop_contract() -> GDScript:
	return preload("res://scripts/dev/world_native_pair_prop_contract_v6.gd")


func _expected_prop_count() -> int:
	return 13


func _ground_path() -> String:
	return "res://build/world_native_pair_ortho_v6_visual.png"


func _walk_path() -> String:
	return "res://build/world_native_pair_ortho_v6_walk.png"


func _route_path() -> String:
	return "res://build/world_native_pair_ortho_v6_route.json"


func _output_prefix() -> String:
	return "res://build/world_native_pair_field_props_v6_"
