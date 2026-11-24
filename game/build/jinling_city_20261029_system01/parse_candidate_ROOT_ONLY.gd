extends SceneTree
## Root-only bounded load/parse. No Field/scene instance, save or gameplay.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failed:=false
	for path: String in ["res://build/jinling_city_20261029_system01/city_author.gd","res://build/jinling_city_20261029_system01/jinling_field.gd","res://build/jinling_city_20261029_system01/router_entry.gd"]:
		var source: Script=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Script
		var okay: bool=source!=null and source.can_instantiate()
		print(JSON.stringify({"path":path,"loaded_can_instantiate":okay}))
		if not okay:failed=true
	var scene:=load("res://build/jinling_city_20261029_system01/jinling_field.tscn") as PackedScene
	var scene_ok: bool=scene!=null and scene.can_instantiate()
	print(JSON.stringify({"scene_loaded_can_instantiate":scene_ok,"instantiated_fields":0}))
	quit(1 if failed or not scene_ok else 0)
