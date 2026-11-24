extends SceneTree
## One production resolve only: no repeated materialize, router or Field.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const PATH := "res://data/scenes/ch4_s0_luoyang_gate.tres"

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var platform := root.get_node("PlatformBridge")
	platform.call("set_checkpoint_saves_suspended", true)
	var scene := ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var started := Time.get_ticks_msec()
	var resolved: SceneScript = C.resolve_scene(scene)
	print("LUOYANG_FORMAL_RESOLVE_ONCE=" + JSON.stringify({"scope": "READONLY_ONE_RESOLVE_REJECTION_NOT_FIELD_APPROVAL", "scene_path": PATH, "scene_sha256": FileAccess.get_sha256(PATH), "contract_sha256": FileAccess.get_sha256("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"), "scene_present": scene != null, "resolved": resolved != null, "C_errors": C.errors(), "BASE_errors": C.BASE.errors(), "elapsed_ms": Time.get_ticks_msec() - started, "checkpoint_suspended": platform.call("is_checkpoint_saves_suspended")}))
	quit(0)
