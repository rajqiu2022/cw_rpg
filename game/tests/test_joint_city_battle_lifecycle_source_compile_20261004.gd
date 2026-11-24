extends SceneTree
## Parse-only; no Field, gameplay, capture or formal approval credit.
const PATHS: Array[String] = [
	"res://tests/helpers/joint_v15_v8_city_authored_battle_lifecycle_phase.gd",
	"res://tests/test_joint_v15_city_wall_v5_authored_battle_lifecycle_limited_20261004.gd"
]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var failures: Array[String] = []
	for path: String in PATHS:
		var script: GDScript = load(path) as GDScript
		var ready: bool = script != null and script.can_instantiate()
		if not ready: failures.append(path)
		print("SOURCE_COMPILE ", path, " ", ready, " SHA=", FileAccess.get_sha256(path))
	print("CITY_BATTLE_LIFECYCLE_PARSE_ONLY ", JSON.stringify({"scope":"SOURCE_COMPILE_ONLY_NOT_GPU_FIELD_OR_APPROVAL", "paths":PATHS.size(), "failures":failures}))
	var until: int = Time.get_ticks_msec() + 9000
	while Time.get_ticks_msec() < until: await process_frame
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	quit(0 if failures.is_empty() else 1)
