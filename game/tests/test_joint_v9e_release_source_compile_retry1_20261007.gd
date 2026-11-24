extends SceneTree
## Source-load check only. Final capture pins remain PENDING, not approval.
## Does not execute artifact reconstruction, Field input, publication or cutover.
const INPUTS := {
 "res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd":"334fb0a665acf1cdaed46b949f71bc9cf9850bc915402c16293e2da2ffa7bcdd",
 "res://tests/helpers/joint_v15_v9e_source_context_oracle.gd":"92bd1f1b8a77a5fa571acb4419c7047108181c0b6bf0569d09bcb309d83f1cd0",
 "res://tests/helpers/joint_v15_release_world_object_input_probe.gd":"bd09de99e15ef77aa2761079e0926f223f870e51ed8908d4bd4f51b585b152ca",
 "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":"90a3528dacb4ce36f5eed5a7adc15bd07b12e0d88ca86e09cde6c4a7fb946c96",
 "res://tests/test_joint_world_luoyang_v15_release_20261005.gd":"51747921d8da73c2dc0939ed792a536d97e64a1854265fee48a30b0cc71e8d76",
 "res://scripts/dev/joint_world_city_v15_release_acceptance.gd":"522dc372c3dd2c20a1df198ba142139d562237455a27f9617a78673accba84b7",
 "res://scripts/dev/activate_joint_world_city_v15_release.gd":"cd6127a3edc55c6a50c17761af5143961fb53b16ea2919ee2abb9549b64eb5e2"
}
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var failed := INPUTS.size() != 7
	for path: String in INPUTS:
		var script: GDScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		var ok: bool = FileAccess.get_sha256(path).to_lower() == INPUTS[path] and script != null and script.can_instantiate()
		print("V9E_RELEASE_SOURCE_COMPILE_RETRY1 ", path, " valid=", ok)
		failed = failed or not ok
		script = null
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(1 if failed else 0)
