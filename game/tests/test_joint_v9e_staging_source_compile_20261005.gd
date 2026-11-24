extends SceneTree
## Source-load check only. Final capture pins remain PENDING, not approval.
const INPUTS := {
 "res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd":"da9da1a2997213fc993f2ade78510e61d74bd1c3f5f3c30a2c73bd9fa826dfda",
 "res://scripts/world/world_map_v15_complete_v9c_candidate_contract.gd":"84c6d7d592fcad51a6503d5d5fd04b0ff850f7acb97b001401f181a8aede1f33",
 "res://scripts/dev/publish_world_map_v15_complete_v9c_candidate.gd":"e8d1bba8db7a8f0186310b3d08d9031ee0b35820287ad763fbf0530aca592197"
}
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var failed := false
	for path: String in INPUTS:
		var script: GDScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		var ok: bool = FileAccess.get_sha256(path).to_lower() == INPUTS[path] and script != null and script.can_instantiate()
		print("V9E_STAGING_SOURCE_COMPILE ", path, " valid=", ok)
		failed = failed or not ok
		script = null
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(1 if failed else 0)
