extends SceneTree
## Compile only. No GPU, Field or visual acceptance.
const PATHS: Array[String] = [
	"res://scripts/dev/world_map_v15_v9c_derived_geometry_helper.gd",
	"res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_ecology_source.gd",
	"res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_surface.gd",
	"res://scripts/dev/build_world_map_v15_v9c_visual_quality_proposal.gd"
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
	var until: int = Time.get_ticks_msec() + 9000
	while Time.get_ticks_msec() < until: await process_frame
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	quit(0 if failures.is_empty() else 1)
