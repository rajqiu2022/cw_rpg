extends SceneTree
## Load-only final-source check. No target is instantiated or called: in
## particular no QA, frozen/review generator, publisher or activator executes.
## Actual hashes are printed, not pinned to today's still-PENDING source state.
## ROOT must retain all twelve inputs in wrapper before/after source snapshots.
const INPUTS: Array[String] = [
	"res://tests/test_joint_world_luoyang_v15_release_20261005.gd",
	"res://tests/helpers/joint_v15_v9e_source_context_oracle.gd",
	"res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd",
	"res://tests/helpers/joint_v15_release_world_prepared_phase.gd",
	"res://tests/helpers/joint_v15_release_world_object_input_probe.gd",
	"res://scripts/dev/joint_world_city_v15_release_acceptance.gd",
	"res://scripts/dev/activate_joint_world_city_v15_release.gd",
	"res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd",
	"res://scripts/world/world_map_v15_complete_v9c_candidate_contract.gd",
	"res://scripts/dev/publish_world_map_v15_complete_v9c_candidate.gd",
	"res://tests/helpers/prepare_joint_v9e_release_frozen_inputs_20261007.gd",
	"res://tests/helpers/prepare_joint_v9e_joint_release_review_drafts_20261007.gd",
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var failed: bool = INPUTS.size() != 12
	var seen: Dictionary = {}
	for path: String in INPUTS:
		var actual_sha: String = FileAccess.get_sha256(path).to_lower()
		var script: GDScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		var ok: bool = not seen.has(path) and actual_sha.length() == 64 and actual_sha.is_valid_hex_number(false) and script != null and script.can_instantiate() and FileAccess.get_sha256(path).to_lower() == actual_sha
		seen[path] = true
		print("V9E_POSTFREEZE_SOURCE_COMPILE ", path, " actual_sha256=", actual_sha, " valid=", ok, " target_executed=false")
		failed = failed or not ok
		script = null
	print("V9E_POSTFREEZE_SOURCES_LOAD_ONLY count=", INPUTS.size(), " valid=", not failed, " target_executed=false approval=false")
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null: audio.call("stop_bgm", .15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	for frame in 16: await process_frame
	quit(1 if failed else 0)
