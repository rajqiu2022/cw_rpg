extends "res://tests/test_world_map_v14_production_20261002.gd"

## Root-run, original actual saved receiver geometry only. No Field/GPU.
func _initialize() -> void:
	call_deferred("_run_guard_binding")

func _run_guard_binding() -> void:
	qa_scope = "LIMITED_NORTH_VISUAL_GUARD_BINDING_NOT_FULL_WORLD"
	candidate_stage = true
	active_id = CANDIDATE_ID
	active_path = CANDIDATE_PATH
	phase_output = OUTPUT_DIR + "north_guard_binding_" + str(int(Time.get_unix_time_from_system())) + "/"
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output)) == OK, "unique limited guard evidence directory")
	player_saves_before = _actual_player_saves()
	prior_navigation = root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	manifest = _json(MANIFEST_PATH)
	source_contract = _json(SOURCE_PATH)
	_check(DisplayServer.get_name() == "headless", "limited geometry fixture has no unapproved GPU")
	_check(int(manifest.get("capture_iteration", -1)) == 9 and _ninth_compiler_precondition(manifest.get("native_shader_compiler_gate", [])) and String(manifest.get("status", "")) == "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA" and String(source_contract.get("status", "")) == "ART_ASSETS_READY", "limited guard diagnostic requires completed actual candidate, never partial OUT")
	if failed > 0 or not _asset_binding_checks():
		_finish()
		return
	schema_ready = true
	_ninth_north_visual_guard_checks()
	_checked_alpha_json(phase_output + "north_guard_binding_evidence.json", {"guard": manifest.get("north_visual_only_guard", {}), "checks_after_actual_guard": checks, "failures_after_actual_guard": failed, "scope": qa_scope, "no_field_or_gpu_or_full_category_credits": true})
	_finish()
