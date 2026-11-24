extends "res://tests/diagnose_luoyang_formal_runtime_rejection_20261012.gd"
## Exactly one materialize; inspect only the rejected visual_objects field.
func _run() -> void:
	var platform := root.get_node("PlatformBridge")
	platform.call("set_checkpoint_saves_suspended", true)
	var scene := ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var started := Time.get_ticks_msec()
	var expected: SceneScript = C.materialize(ID)
	var report := {"scope": "READONLY_ONE_MATERIALIZE_VISUAL_FIRSTDIFF_NOT_FIELD_APPROVAL", "scene_path": PATH, "scene_sha256": FileAccess.get_sha256(PATH), "contract_sha256": FileAccess.get_sha256("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"), "materialize_present": expected != null, "C_errors": C.errors(), "BASE_errors": C.BASE.errors(), "materialize_elapsed_ms": Time.get_ticks_msec() - started, "checkpoint_suspended": platform.call("is_checkpoint_saves_suspended")}
	if expected != null and scene != null and scene.map_layout != null:
		report["visual_equal"] = C.equal_visual_serialized_value(expected.map_layout.visual_objects, scene.map_layout.visual_objects, ["visual_objects"])
		_diff(expected.map_layout.visual_objects, scene.map_layout.visual_objects, ["visual_objects"], true)
		report["strict_differences"] = differences
	print("LUOYANG_FORMAL_VISUAL_ONCE=" + JSON.stringify(report))
	quit(0)
