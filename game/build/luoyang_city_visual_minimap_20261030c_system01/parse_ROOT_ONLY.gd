extends SceneTree
## Compile only the new visual cache/consumer; never instantiates a Field or
## publishes geometry. Root alone may run in the real autoload project.
const ROOT := "res://build/luoyang_city_visual_minimap_20261030c_system01/"
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var passed := true
	var checks: Array[Dictionary] = []
	for path: String in [ROOT + "visual_cache.gd", ROOT + "city_minimap_READY.gd"]:
		var script: Script = ResourceLoader.load(path, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as Script
		var ok: bool = script != null and script.can_instantiate()
		passed = passed and ok
		checks.append({"path": path, "sha256": FileAccess.get_sha256(path), "can_instantiate": ok})
	print(JSON.stringify({"status": "30C_NEW_MODULE_COMPILE_ONLY_NOT_RUNTIME_ACCEPTANCE", "passed": passed, "checks": checks, "field_instances": 0, "cache_captures": 0, "publication_runs": 0}))
	quit(0 if passed else 1)
