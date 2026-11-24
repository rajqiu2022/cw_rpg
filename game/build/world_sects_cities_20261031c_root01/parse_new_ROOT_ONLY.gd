extends SceneTree
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var paths=["res://build/sect_repair_20261031c_system01/router_entry.gd","res://build/sect_repair_20261031c_system01/sect_field.gd","res://build/world_landmarks_20261031c/refinement.gd","res://build/three_towns_world_20261029j_system01/world_watcher.gd","res://build/city_visual_diversity_20261031c/district_visuals.gd","res://build/three_settlements_20261030e_system01/xiangzhou_author.gd","res://build/three_settlements_20261030e_system01/settlement_field.gd","res://build/jinling_city_20261029_system01/city_author.gd","res://build/jinling_city_20261029_system01/jinling_field.gd","res://build/luoyang_regions_20261027d_source01/region_field.gd"]
	var errors: Array[String]=[]
	for path: String in paths:
		var script:=load(path) as Script
		if script==null or not script.can_instantiate():errors.append(path)
	for path: String in ["res://scenes/drafts/sect_maps_20261029k/wudang.tscn","res://scenes/drafts/huashan_map_20261029m/huashan.tscn"]:
		var scene:=load(path) as PackedScene
		if scene==null or not scene.can_instantiate():errors.append(path)
	var registry: Script=load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	if registry==null or registry.call("source_valid")!=true:errors.append("NATIVE_SOURCE_VALID")
	print(JSON.stringify({"scope":"new31c parse and source only, no fields instantiated","errors":errors,"parsed_gd":paths.size(),"scenes":2}))
	quit(0 if errors.is_empty() else 1)
