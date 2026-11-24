extends SceneTree
const PATHS: Array[String]=[
	"res://build/player_portrait_minimap_20261030f_system01/portrait_marker.gd",
	"res://build/player_portrait_minimap_20261030f_system01/canonical_city_minimap_READY.gd",
	"res://build/player_portrait_minimap_20261030f_system01/three_city_minimap_READY.gd",
	"res://build/player_portrait_minimap_20261030f_system01/four_minimap_READY02.gd"
]
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var failures:=0
	for path: String in PATHS:
		var script:=load(path) as Script
		var okay: bool=script!=null and script.can_instantiate()
		print("PORTRAIT30F_PARSE ",okay," ",path," ",FileAccess.get_sha256(path))
		if not okay:failures+=1
	print("PORTRAIT30F_RESULT leaves=4 failures=",failures," field_instances=0 png_writes=0")
	quit(1 if failures>0 else 0)
