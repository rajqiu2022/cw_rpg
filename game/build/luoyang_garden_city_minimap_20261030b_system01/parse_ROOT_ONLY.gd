extends SceneTree
## One compile-only pass. Never instantiates a Field, publishes a bin or moves
## actors; Root alone may run this inside the real project/autoload context.
const ROOT := "res://build/luoyang_garden_city_minimap_20261030b_system01/"
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var checks: Array[Dictionary] = []
	var passed := true
	for path: String in [ROOT + "city_minimap.gd", ROOT + "garden_visual.gd", ROOT + "ready02/field_walkable_controller.gd", ROOT + "ready02/region_field.gd", ROOT + "ready02/town_field.gd"]:
		var script: Script = ResourceLoader.load(path, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var ok := script != null and script.can_instantiate()
		checks.append({"path": path, "sha256": FileAccess.get_sha256(path), "can_instantiate": ok})
		passed = passed and ok
	print(JSON.stringify({"status": "30B_COMPILE_ONLY_NOT_RUNTIME_ACCEPTANCE", "passed": passed, "checks": checks, "field_instances": 0, "publication_runs": 0}))
	quit(0 if passed else 1)
