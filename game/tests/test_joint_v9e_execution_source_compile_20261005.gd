extends SceneTree
## Parse/load only; no capture, navigation, Field, or publication approval.
const INPUTS := {
 "res://scripts/dev/world_map_v15_v9e_material_refinement_surface.gd":"3cb4f995cc800482fe859f0424a4839b70097721ec5f11f21e53a7d6ca3253b1",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd":"dcda6d3227cad5fd646b6fa3390cae5c4f71354fec1adf15552a12188a8d0121",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v9e_regional_proposal.gd":"f00e83e40d3c24f1d48ecee959ddbc02bd5791c924af01a897f5a7667dcf9d0f"
}
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var failed := false
	for path: String in INPUTS:
		var script: GDScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		var ok: bool = FileAccess.get_sha256(path).to_lower() == INPUTS[path] and script != null and script.can_instantiate()
		print("V9E_EXECUTION_SOURCE_COMPILE ", path, " valid=", ok)
		failed = failed or not ok
		script = null
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(1 if failed else 0)
