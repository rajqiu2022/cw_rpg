extends SceneTree
## Root only. Candidate code/resources, no Field or map instances and no saves.
const PATHS: Array[String]=[
	"res://build/player_portrait_minimap_20261030f_system01/portrait_marker.gd",
	"res://build/player_portrait_minimap_20261030f_system01/closure01_READY/build__luoyang_garden_city_minimap_20261030b_system01__city_minimap.gd",
	"res://build/player_portrait_minimap_20261030f_system01/closure01_READY/build__three_settlements_20261030e_system01__city_minimap.gd",
	"res://build/player_portrait_minimap_20261030f_system01/closure01_READY/build__four_settlements_20261030e_system01__minimap.gd",
	"res://build/player_portrait_minimap_20261030f_system01/closure01_READY/build__four_settlements_20261030e_system01__locations.gd",
	"res://build/linxi_scale_access_20261030f_system01/restore.gd",
	"res://build/player_portrait_minimap_20261030f_system01/closure01_READY/build__three_towns_world_20261029j_system01__town_registry.gd",
	"res://build/player_portrait_minimap_20261030f_system01/closure01_READY/scripts__autoload__scene_router.gd",
	"res://build/linxi_scale_access_20261030f_system01/linxi_master.tscn",
	"res://build/linxi_scale_access_20261030f_system01/linxi_master_ground.gdshader"
]
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var failures:=0
	for path: String in PATHS:
		var resource: Resource=load(path)
		var okay: bool=resource!=null
		if resource is Script:okay=resource.can_instantiate()
		elif resource is PackedScene:okay=resource.can_instantiate()
		print("PORTRAIT30F_FINAL_PARSE ",okay," ",path," ",FileAccess.get_sha256(path))
		if not okay:failures+=1
	print("PORTRAIT30F_FINAL_RESULT resources=",PATHS.size()," failures=",failures," field_instances=0 map_instances=0 save_reads=0")
	quit(1 if failures>0 else 0)
