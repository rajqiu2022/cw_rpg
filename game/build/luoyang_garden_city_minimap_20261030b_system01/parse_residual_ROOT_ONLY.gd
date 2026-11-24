extends SceneTree
## Only the failed new module. Prior compile-only results remain prior facts.
const PATH := "res://build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd"
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var script: Script = ResourceLoader.load(PATH, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as Script
	var passed := script != null and script.can_instantiate()
	print(JSON.stringify({"status": "30B_RESIDUAL_COMPILE_ONLY_NOT_RUNTIME_ACCEPTANCE", "path": PATH, "sha256": FileAccess.get_sha256(PATH), "passed": passed, "field_instances": 0, "publication_runs": 0}))
	quit(0 if passed else 1)
