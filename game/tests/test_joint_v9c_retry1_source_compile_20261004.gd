extends SceneTree
## Compile only. No capture/gameplay/approval.
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var path: String = "res://scripts/dev/build_world_map_v15_v9c_visual_quality_proposal_retry1.gd"
	var script: GDScript = load(path) as GDScript
	var ready: bool = script != null and script.can_instantiate()
	print("SOURCE_COMPILE ", path, " ", ready, " SHA=", FileAccess.get_sha256(path))
	var until: int = Time.get_ticks_msec() + 9000
	while Time.get_ticks_msec() < until: await process_frame
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	quit(0 if ready else 1)
