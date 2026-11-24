extends RefCounted
## NEW independently scoped risk-stratified RELEASE gate, not legacy exhaustive FULL.
## Candidate, six-baseline, closure, staging and rollback authority are retained.
## Independent source authority only; never manufactures approval or QA results.
const WORLD = preload("res://scripts/world/world_map_v15_contract.gd")
const WORLD_GATE = preload("res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd")
const CITY = preload("res://scripts/city/luoyang_layered_v3_contract.gd")
const OUTSKIRTS = preload("res://scripts/world/outskirts_native_contract.gd")
const VISUAL_REVIEW := "res://data/maps/joint_world_city_v15_release_visual_review.json"
const TECHNICAL_REVIEW := "res://data/maps/joint_world_city_v15_release_technical_review.json"
const RELEASE_PHASE := "JOINT_RELEASE_RISK_STRATIFIED_ACTUAL_FIELD_INPUT"
const FRESH_START_PHASE := "JOINT_FRESH_START_CURRENT_FORMAT_ACTUAL_FIELD_INPUT"
const FRESH_START_SCOPE := "JOINT_FRESH_START_CURRENT_FORMAT_ACTUAL_FIELD_INPUT"
const FRESH_START_FROZEN_SCOPE := "JOINT_FROZEN_FRESH_START_CURRENT_FORMAT_INPUTS"
const EXCLUDED_HISTORICAL_VERSIONS := {"world": [12, 13, 14], "local": [1]}
const CURRENT_SAVE_LOAD_EXECUTOR := "res://tests/helpers/joint_v15_current_save_load_20261008.gd"
const RELEASE_SELECTION_PATH := "res://build/joint_world_luoyang_20261003_qa/release_selection_root234_20261005_01/representative_selection.json"
const RELEASE_SELECTION_SHA := "34a6ffd4b6da7adfc953c7339e1398c5a77e6f112399e4361350050246c4704f"
const PHYSICAL_SEAM_PLAN_PATH := "res://build/joint_world_luoyang_20261003_qa/v9e_physical_seam_plan_1791382780_55287449_11796/physical_seam_plan.json"
const PHYSICAL_SEAM_PLAN_SHA := "024e9a09f37721e787990ba035416996e75d69518e8d18698fdc9f0a4c1f3bd8"
const PHYSICAL_SEAM_GENERATOR := "res://tests/helpers/prepare_joint_v9e_physical_seam_plan_20261007.gd"
const PHYSICAL_SEAM_GENERATOR_SHA := "fe54500050d844e50ff3681ab44a9db6bdff15112995eae7adb46fee10c746af"
const PHYSICAL_SEAM_GEOMETRY := "res://tests/helpers/joint_v15_release_layered_seam_geometry_20261007.gd"
const PHYSICAL_SEAM_ALGORITHM := "ALL112_EDGES_ALL4PX_CANDIDATES_FULL17_THREE_CENTERS_SOURCE_SOLIDS_THEN_12_EQUAL_RANKS_V1"
const PHYSICAL_SEAM_INPUTS := {
	"res://data/maps/world_map_v15_complete_v9c_source.json":"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
	"res://art/maps/world_map_v15_complete_v9c/art_contract.json":"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
	"res://data/maps/world_map_jianghu_layout_v15.tres":"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
	RELEASE_SELECTION_PATH:RELEASE_SELECTION_SHA,
	PHYSICAL_SEAM_GENERATOR:PHYSICAL_SEAM_GENERATOR_SHA,
	"res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd":"7628d404d7587dfd885937ad1e26ac6a06f4e48ca53c273ccd8d5f1aee5db9db",
	"res://tests/helpers/v15_raw_world_oracle.gd":"c58043373af6154d5f7f79cfa2d0e8dcda38f3fbe0c6648a4af4ce626e8a9c51",
	"res://tests/test_joint_v9e_seam_witness_collision_diagnostic_20261007.gd":"5aaaeaf3789c7dfae1ad1447439d1e0107dd2692a096d5a75db2eaa4a159485f",
	"res://build/joint_world_luoyang_20261003_qa/world_release_197271897/actual_saved_geometry_112_references.json":"14591ea011e9e984e921274cde234ec6c6deaf367553d15bfa463b96c294cd77",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd":"4d006169a3cc0f9dc347c467d4ab05204ee2f78be790e3c75c368d77e9b5abfb",
}
const ORIGINAL_SEAM_NEGATIVE_EDGES := {"r1_c6--r1_c7":12,"r2_c4--r2_c5":12,"r4_c5--r4_c6":6,"r7_c1--r7_c2":9,"r7_c2--r7_c3":8,"r0_c1--r1_c1":6,"r0_c7--r1_c7":12,"r1_c5--r2_c5":12,"r1_c7--r2_c7":1,"r6_c2--r7_c2":8,"r6_c3--r7_c3":8}
const RELEASE_ENTRY := "res://tests/test_joint_world_luoyang_v15_release_20261005.gd"
const RELEASE_WORLD_REQUIRED := [
	"saved_global_mesh_RF_and112_actual_reference_edges", "all64_raw_repeat_SSAA_models_support_and_nine_ecology_regions",
	"all_authored_world_routes_actual_normal_input", "all1344_seam_17shoe_Physics_and_fixed112_normal_input",
	"all16_space_door_mouse_arrow_actual_returns", "all16_wall_roof_wrongside_actual_input_negatives",
	"all2687_binding_2322_ownRID_physics_and_fixed130_actual_inputs", "three_southern_strong_current_frame_same_band_gt512_pairs",
	"actual48_historic_isolated_save_load_Field_birth_and15_reread", "actual_free_indoor_native15_and_unknown_version_zero_mutation_saves",
	"actual_M_v15_overview_sixteen_labels_and_current_player_marker", "actual_victory_defeat_confirmed_team_flee_version15_exact_returns",
	"normal_spawned_NPC_south_gt512_same_band_both_directions_four_frames_tie_cleanup",
]
const BASELINE := {
	"res://data/scenes/world_map_jianghu.tres": "838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015",
	"res://data/scenes/ch4_s0_luoyang_gate.tres": "b967c347e745e6f05d51a8f596fde4744571f5d459279467c706e66d9be24bd1",
	"res://data/scenes/ch4_s1_luoyang_yamen.tres": "7bed5d322d583c9c7bf4e392f3f4c75ffb0577db24bb9e6237a4ae3aa0808b01",
	"res://data/scenes/ch4_s2_canal_docks.tres": "81850afd0877bba70e2ed0786fe4e81570faee8e06e827561349988f9c4d41a5",
	"res://data/scenes/ch4_s3_luoyang_market.tres": "5cd76d0c0a0c54358f50b341186c5ea078a7d20657c97dc15ef15027755661ab",
	"res://data/config/outskirts_native_adoption.json": "203c9f08e941908ace3e8d56e18a15963e3a60859c04741b04e28a968386d0ff",
}
const SYSTEM_PATHS := [
	"res://project.godot",
	"res://scripts/autoload/audio_manager.gd", "res://scripts/autoload/event_bus.gd",
	"res://scripts/autoload/game_state.gd", "res://scripts/autoload/inventory.gd", "res://scripts/autoload/quest_manager.gd",
	"res://scripts/autoload/scene_router.gd", "res://scripts/autoload/save_manager.gd",
	"res://scripts/autoload/dialog_player.gd", "res://scripts/autoload/bounty_manager.gd",
	"res://scripts/field/field_walkable_controller.gd", "res://scripts/field/player.gd", "res://scripts/field/npc_node.gd",
	"res://scripts/field/exit_zone.gd", "res://scripts/field/world_v15_exit_zone.gd", "res://scripts/field/luoyang_v3_exit_zone.gd",
	"res://scripts/world/world_map_v15_contract.gd", "res://scripts/world/world_map_v14_contract.gd",
	"res://scripts/world/outskirts_native_contract.gd", "res://scripts/world/outskirts_modular_overlap.gd",
	"res://scripts/world/v14_modular_overlap.gd", "res://scripts/world/v15_modular_overlap.gd",
	"res://scripts/city/luoyang_layered_v3_contract.gd", "res://scripts/city/luoyang_v3_sprite_alpha.gd",
	"res://scripts/city/luoyang_v3_modular_overlap.gd",
	"res://scripts/dev/world_map_v15_complete_v7_publication_gate_proposal.gd", "res://scripts/dev/publish_world_map_v15_complete_v7_proposal.gd",
	"res://scripts/dev/publish_luoyang_layered_v3.gd", "res://scripts/dev/joint_world_city_v15_acceptance.gd",
	"res://scripts/dev/activate_joint_world_city_v15.gd",
	"res://scripts/battle/battle_controller.gd", "res://scripts/ui/result_victory.gd", "res://scripts/ui/result_defeat.gd",
	"res://scripts/ui/shop_ui.gd", "res://scripts/ui/bounty_board.gd", "res://scripts/ui/world_map_panel.gd", "res://scripts/ui/dialog_box.gd",
	"res://scenes/battle.tscn", "res://scenes/battle_actor.tscn", "res://scenes/result_victory.tscn", "res://scenes/result_defeat.tscn",
	"res://scenes/shop.tscn", "res://scenes/bounty_board.tscn", "res://scenes/field_walkable.tscn",
	"res://tests/test_joint_world_luoyang_v15_20261004.gd",
	"res://tests/helpers/joint_v15_source_context_oracle.gd", "res://tests/helpers/joint_v15_world_prepared_phase.gd",
	"res://tests/helpers/joint_v15_world_raw_oracle.gd", "res://tests/helpers/joint_v15_world_geometry_phase.gd",
	"res://tests/helpers/joint_v15_world_object_input_probe.gd", "res://tests/helpers/joint_v15_world_saved_context_probe.gd",
	"res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd",
	"res://tests/helpers/joint_v15_overview_input_probe.gd", "res://tests/helpers/joint_v15_ordinary_raw_oracle.gd",
	"res://tests/helpers/joint_v15_normal_npc_depth_probe.gd", "res://tests/helpers/joint_v15_battle_return_probe.gd",
	"res://tests/helpers/joint_v15_city_prepared_phase.gd", "res://tests/helpers/joint_v15_city_physical_alpha_probe.gd",
	"res://tests/helpers/joint_v15_city_sprite_alpha_probe.gd", "res://tests/helpers/joint_v15_existing_battle_ui_probe.gd",
	"res://tests/helpers/joint_v15_city_migration_load_probe.gd", "res://tests/helpers/joint_v15_city_interaction_negative_probe.gd",
	"res://tests/helpers/joint_v15_outskirts_prepared_phase.gd", "res://tests/helpers/joint_v15_outskirts_field_probe.gd",
	"res://tests/helpers/joint_v15_outskirts_material_probe.gd", "res://tests/helpers/joint_v15_outskirts_encounter_probe.gd",
	"res://tests/helpers/joint_v15_outskirts_saved_geometry_probe.gd",
	"res://scripts/city/luoyang_layered_v3_street_detail_candidate_contract.gd",
	"res://scripts/dev/luoyang_v3_street_detail_material_checker.gd",
	"res://scripts/dev/publish_luoyang_v3_street_detail_candidate.gd",
	"res://tests/helpers/joint_v15_v7_source_context_oracle.gd",
	"res://tests/helpers/joint_v15_v7_world_raw_oracle.gd",
	"res://tests/helpers/joint_v15_v7_world_geometry_phase.gd",
	"res://tests/helpers/joint_v15_v7_world_object_input_probe.gd",
	"res://tests/helpers/joint_v15_v7_overview_input_probe.gd",
	"res://tests/helpers/joint_v15_v7_world_prepared_phase.gd",
	"res://tests/helpers/joint_v15_world_artifact_semantics_v7_probe.gd",
	"res://tests/helpers/joint_v15_v7_plane_caster_semantic_probe.gd",
	"res://tests/helpers/joint_v15_street_detail_ordinary_raw_oracle.gd",
	"res://tests/helpers/joint_v15_street_detail_city_physical_alpha_probe.gd",
	"res://tests/helpers/joint_v15_street_detail_city_prepared_phase.gd",
	"res://tests/helpers/joint_v15_street_detail_city_gameplay_lifecycle_grace_phase.gd",
	"res://tests/helpers/joint_v15_looped_bgm_continuity.gd",
	# Keep all83 original roots; append actual V8 capture/system/city/FULL QA roots.
	"res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd",
	"res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v8_regional_proposal.gd",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v8_full_proposal.gd",
	"res://scripts/dev/world_map_v15_complete_v8_publication_gate.gd",
	"res://scripts/world/world_map_v15_complete_v8_candidate_contract.gd",
	"res://scripts/dev/publish_world_map_v15_complete_v8_candidate.gd",
	"res://scripts/city/luoyang_layered_v3_wall_street_candidate_contract.gd",
	"res://scripts/dev/luoyang_v3_wall_street_saved_resource_checker.gd",
	"res://scripts/dev/publish_luoyang_v3_wall_street_candidate.gd",
	"res://scripts/dev/build_luoyang_modular_v3_wall_street_capture_proposal.gd",
	"res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd",
	"res://scripts/dev/build_luoyang_modular_v3_wall_street_adapter_proposal.gd",
	"res://scripts/dev/joint_world_city_v15_v8_wall_acceptance.gd",
	"res://scripts/dev/activate_joint_world_city_v15_v8_wall.gd",
	"res://tests/helpers/joint_v15_v8_world_prepared_phase.gd",
	"res://tests/helpers/joint_v15_v8_source_context_oracle.gd",
	"res://tests/helpers/joint_v15_v8_world_raw_oracle.gd",
	"res://tests/helpers/joint_v15_v8_world_geometry_phase.gd",
	"res://tests/helpers/joint_v15_v8_world_object_input_probe.gd",
	"res://tests/helpers/joint_v15_v8_overview_input_probe.gd",
	"res://tests/helpers/joint_v15_v8_plane_caster_semantic_probe.gd",
	"res://tests/helpers/joint_v15_v8_city_prepared_phase.gd",
	"res://tests/helpers/joint_v15_v8_city_gameplay_lifecycle_grace_phase.gd",
	"res://tests/helpers/joint_v15_world_artifact_semantics_v8_probe.gd",
	"res://tests/test_joint_world_luoyang_v15_v8_full_20261004.gd",
	# Current V5 resources and actual fine-alpha QA binding closure. Old roots
	# above remain bound; no old run can approve this new byte snapshot.
	"res://scripts/dev/build_luoyang_modular_v3_wall_v5_adapter_candidate.gd",
	"res://scripts/dev/build_luoyang_modular_v3_wall_v5_capture_candidate.gd",
	"res://scripts/dev/luoyang_modular_v3_zone_finish_candidate.gd",
	"res://scripts/dev/luoyang_v3_wall_v5_saved_resource_checker.gd",
	"res://scripts/city/luoyang_layered_v3_wall_v5_candidate_contract.gd",
	"res://scripts/dev/publish_luoyang_v3_wall_v5_candidate.gd",
	"res://tests/helpers/joint_v15_wall_v5_ordinary_raw_oracle.gd",
	"res://tests/helpers/joint_v15_wall_v5_city_migration_load_probe.gd",
	"res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd",
	"res://tests/helpers/joint_v15_wall_v5_fine_alpha_probe.gd",
	"res://tests/test_joint_v15_city_wall_v5_fine_geometry_limited_20261004.gd",
	# NEW closure appended; every historical mandatory path above remains bound.
	"res://tests/helpers/joint_v15_v9c_source_context_oracle.gd",
	"res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd",
	"res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd",
	"res://tests/helpers/joint_v15_v9c_world_geometry_phase.gd",
	"res://tests/helpers/joint_v15_v9c_world_object_input_probe.gd",
	"res://tests/helpers/joint_v15_v9c_overview_input_probe.gd",
	"res://tests/helpers/joint_v15_world_artifact_semantics_v9c_probe.gd",
	"res://tests/helpers/joint_v15_v9c_plane_caster_semantic_probe.gd",
	"res://tests/helpers/joint_v15_v9c_derived_geometry_probe.gd",
	"res://tests/helpers/joint_v15_v9c_city_authored_transition_phase.gd",
	"res://tests/test_joint_world_luoyang_v15_v9c_full_20261004.gd",
	"res://scripts/dev/joint_world_city_v15_v9c_wall_acceptance.gd",
	"res://scripts/dev/activate_joint_world_city_v15_v9c.gd",
	"res://scripts/dev/world_map_v15_complete_v9c_publication_gate.gd",
	"res://scripts/world/world_map_v15_complete_v9c_candidate_contract.gd",
	"res://scripts/dev/publish_world_map_v15_complete_v9c_candidate.gd",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v9c_regional_proposal.gd",
	"res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_ecology_source.gd",
	"res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_surface.gd",
	"res://scripts/dev/world_map_v15_v9c_derived_geometry_helper.gd",
	"res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v2.gd",
	"res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v3.gd",
	"res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v4.gd",
	"res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v5.gd",
	"res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v6.gd",
	"res://scripts/dev/world_map_v15_v9d_material_quality_proposal_surface.gd",
	"res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd",
	"res://scripts/dev/luoyang_v3_wall_v5_note_saved_resource_checker.gd",
	"res://scripts/dev/luoyang_modular_v3_wall_v5_note_source.gd",
	"res://scripts/dev/build_luoyang_modular_v3_wall_v5_note_capture.gd",
	"res://tests/test_joint_v15_city_wall_v5_note_authored_transition_limited_20261004.gd",
	"res://tests/test_joint_v15_city_wall_v5_note_fine_geometry_limited_20261004.gd",
	"res://tests/helpers/joint_v15_v8_city_authored_choice_phase.gd",
	"res://tests/helpers/joint_v15_v8_city_authored_two_choice_phase.gd",
	"res://tests/helpers/joint_v15_v8_city_authored_battle_lifecycle_phase.gd",
	"res://tests/helpers/joint_v15_v8_city_authored_transition_lifecycle_phase.gd",
	# Explicit NEW release/capture roots. Every old mandatory closure entry above
	# is retained; binding historical roots is not execution/PASS credit.
	"res://scripts/dev/world_map_v15_v9e_material_refinement_surface.gd",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v9e_regional_proposal.gd",
	"res://tests/helpers/joint_v15_release_world_object_input_probe.gd",
	"res://tests/helpers/joint_v15_release_world_prepared_phase.gd",
	"res://tests/test_joint_world_luoyang_v15_release_20261005.gd",
	"res://scripts/dev/joint_world_city_v15_release_acceptance.gd",
	"res://scripts/dev/activate_joint_world_city_v15_release.gd",
	PHYSICAL_SEAM_GENERATOR, PHYSICAL_SEAM_GEOMETRY,
]

static func candidate_error() -> String:
	if WORLD.SOURCE_PATH != WORLD_GATE.SOURCE_PATH or WORLD.MANIFEST_PATH != WORLD_GATE.MANIFEST_PATH or WORLD.CAPTURE_PROTOCOL != WORLD_GATE.PROTOCOL: return "World runtime/approval artifact authority mismatch"
	var source: Dictionary = WORLD.read_json(WORLD.SOURCE_PATH)
	var manifest: Dictionary = WORLD.read_json(WORLD.MANIFEST_PATH)
	var selection_error: String = _selection_error(source)
	if not selection_error.is_empty(): return selection_error
	var physical_error: String = _physical_seam_plan_error(source)
	if not physical_error.is_empty(): return physical_error
	var capture: Variant = source.get("capture")
	if not capture is Dictionary or capture.get("capture_protocol") != WORLD.CAPTURE_PROTOCOL or manifest.get("capture_protocol") != WORLD.CAPTURE_PROTOCOL: return "Joint approval requires actual FULL whole derived V9c, not old local-frustum/pilot artifacts"
	var world_error: String = WORLD_GATE.validate(source, manifest)
	if not world_error.is_empty(): return world_error
	var world: SceneScript = ResourceLoader.load(WORLD.CANDIDATE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not WORLD.is_v15(world) or world.scene_id != WORLD.CANDIDATE_ID or not WORLD.safe_foot(world, world.player_spawn): return "Missing/unbound safe full world candidate"
	for id: String in CITY.LEGACY_SHAS:
		var scene: SceneScript = ResourceLoader.load(CITY.candidate_path(StringName(id)), "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if not CITY.is_v3(scene) or scene.scene_id != StringName(id) or not CITY.runtime_fidelity(scene): return "Missing/unbound normal city candidate " + id
	if OUTSKIRTS.active_root() != OUTSKIRTS.COMPLETE_V5_ROOT: return "New outskirts root must be explicitly selected; old/v4 cannot inherit joint acceptance"
	for biome: String in OUTSKIRTS.ENTRIES:
		if OUTSKIRTS.authoring_contract(biome).is_empty(): return "New independent outskirts NOT_READY " + biome
	return ""

static func snapshot() -> Dictionary:
	# Every actual byte in all eight art graphs and all candidate resources is
	# bound. Approval files themselves are excluded to avoid a circular hash.
	if WORLD.SOURCE_PATH != WORLD_GATE.SOURCE_PATH or WORLD.MANIFEST_PATH != WORLD_GATE.MANIFEST_PATH or WORLD.CAPTURE_PROTOCOL != WORLD_GATE.PROTOCOL: return {}
	var result: Dictionary = {}
	for path: String in SYSTEM_PATHS:
		if not _append(result, path): return {}
	if not _append(result, RELEASE_SELECTION_PATH) or result[RELEASE_SELECTION_PATH] != RELEASE_SELECTION_SHA: return {}
	if not _append(result, PHYSICAL_SEAM_PLAN_PATH) or result[PHYSICAL_SEAM_PLAN_PATH] != PHYSICAL_SEAM_PLAN_SHA: return {}
	var physical_plan: Dictionary = WORLD.read_json(PHYSICAL_SEAM_PLAN_PATH)
	if not _catalog(result, physical_plan.get("input_sha256")): return {}
	for path: String in [WORLD.SOURCE_PATH, WORLD.MANIFEST_PATH, WORLD.CANDIDATE_PATH, WORLD.LAYOUT_PATH, WORLD.STREAM_PATH, WORLD_GATE.REVIEW]:
		if not _append(result, path): return {}
	if not _catalog(result, WORLD.read_json(WORLD.MANIFEST_PATH).get("asset_sha256", {})): return {}
	var source: Dictionary = WORLD.read_json(WORLD.SOURCE_PATH)
	if source.has("asset_sha256") and not _catalog(result, source.asset_sha256): return {}
	for id: String in CITY.LEGACY_SHAS:
		for path: String in [CITY.ROOT + id + "/art_contract.json", CITY.candidate_path(StringName(id)), CITY.layout_path(StringName(id)), CITY.LEGACY_ROOT + id + "_scene.tres", CITY.LEGACY_ROOT + id + "_layout.tres"]:
			if not _append(result, path): return {}
		if not _catalog(result, WORLD.read_json(CITY.ROOT + id + "/art_contract.json").get("asset_sha256", {})): return {}
	for biome: String in OUTSKIRTS.ENTRIES:
		var path: String = OUTSKIRTS.COMPLETE_V5_ROOT + biome + "/art_contract.json"
		if not _append(result, path) or not _catalog(result, WORLD.read_json(path).get("asset_sha256", {})): return {}
		if not _append(result, "res://data/scenes/" + String(OUTSKIRTS.ENTRIES[biome].scene) + ".tres"): return {}
	# Bind original gameplay leaves too, including nested dialogues, encounters,
	# shops, quests and generated item/skill references used by normal actions.
	for directory: String in ["res://data/dialogs", "res://data/enemies", "res://data/shops", "res://data/quests", "res://data/items", "res://data/equipment", "res://data/skills"]:
		if not _data_tree(result, directory): return {}
	# Bind the actual literal dependency closure of these gameplay and QA roots,
	# including reused helpers, resource-domain scripts, UI scenes and real audio.
	# This is byte protection, NOT a claim that every bound dialogue was played.
	var visited: Dictionary = {}
	for path: String in result.keys():
		if not _dependency_tree(result, path, visited): return {}
	if not _actor_frame_dependencies(result): return {}
	if not _snapshot_bytes_unchanged(result): return {}
	return result

static func approval_error(fresh_start: bool = false) -> String:
	for path: String in BASELINE:
		if FileAccess.get_sha256(path).to_lower() != BASELINE[path]: return "Formal activation baseline changed; no writes allowed: " + path
	var error: String = candidate_error()
	if not error.is_empty(): return error
	var current: Dictionary = snapshot()
	if current.is_empty(): return "Incomplete actual joint byte snapshot"
	var visual: Dictionary = WORLD.read_json(VISUAL_REVIEW)
	var technical: Dictionary = WORLD.read_json(TECHNICAL_REVIEW)
	for review: Dictionary in [visual, technical]:
		if review.get("schema_version") != 1 or review.get("world_coordinate_version") != 15 or review.get("city_layout_version") != 3 or review.get("reviewer_role") != "producer/root" or String(review.get("reviewer", "")).strip_edges().is_empty() or not matches_snapshot(review.get("asset_sha256"), current): return "Independent joint producer review absent/stale"
		if not _mode_metadata(review, fresh_start): return "Independent review fresh-start mode differs from explicit activation mode"
	if visual.get("visual_approved") != true or typeof(visual.get("visual_approved")) != TYPE_BOOL or visual.get("review_method") != "actual_world_city_outskirts_png_individual_review": return "Joint actual-image visual approval absent"
	if technical.get("technical_approved") != true or typeof(technical.get("technical_approved")) != TYPE_BOOL or technical.get("review_method") != "independent_risk_stratified_release_normal_gameplay_field_input": return "Independent risk-stratified RELEASE technical approval absent"
	var expected_phase: String = FRESH_START_PHASE if fresh_start else RELEASE_PHASE
	if not _release_flags(technical) or technical.get("phase") != expected_phase or technical.get("selection_path") != RELEASE_SELECTION_PATH or technical.get("selection_sha256") != RELEASE_SELECTION_SHA: return "RELEASE review scope/immutable selection absent; legacy FULL credit forbidden"
	var runs: Variant = technical.get("actual_runs")
	if not runs is Dictionary or runs.size() != 2: return "Separate actual headless/GPU run wrappers required"
	if fresh_start and not _fresh_review_inputs(technical, visual): return "Fresh-start reviews/frozen inputs or distinct actual runs are absent/mixed"
	for mode: String in ["headless", "gpu"]:
		var run: Variant = runs.get(mode)
		if not run is Dictionary or not _number(run.get("actual_os_exit_code"), 0): return "Actual process wrapper did not confirm exit0: " + mode
		for role: String in ["result", "stdout", "stderr"]:
			var evidence: Variant = run.get(role)
			if not evidence is Dictionary or not _bound_evidence(evidence): return "Missing/stale independently retained actual log: " + mode + "/" + role
		for role: String in ["stdout", "stderr"]:
			if not _clean_actual_log(String(run[role].path)): return "Actual process log contains engine/script error: " + mode + "/" + role
		var report: Dictionary = WORLD.read_json(String(run.result.path))
		if report.get("phase") != expected_phase or not _mode_metadata(report, fresh_start) or not _release_flags(report) or not _number(report.get("failed"), 0) or not _number(report.get("failures"), 0) or report.get("mode") != mode or not _false(report.get("source_complete")) or not _false(report.get("dry_run")) or not matches_snapshot(report.get("source_sha256"), current): return "Source/unit/limited/legacy FULL/stale evidence cannot approve RELEASE gameplay: " + mode
		if fresh_start and not _fresh_actual_run(run, report, technical, mode): return "Fresh-start actual candidate invocation/frozen mode evidence incomplete: " + mode
		if report.get("executing_script_path") != RELEASE_ENTRY or String(report.get("executing_script_sha256", "")).to_lower() != current.get(RELEASE_ENTRY): return "RELEASE actual executor identity absent/stale: " + mode
		for name: String in ["all_actual_sources_before.json", "all_actual_sources_after.json"]:
			if not matches_snapshot(WORLD.read_json(String(run.result.path).get_base_dir().path_join(name)), current): return "RELEASE retained before/after source catalog differs: " + mode
		if not _release_actual_evidence(report, current, mode, fresh_start): return "RELEASE actual inventory/selection/input/clock/save evidence incomplete: " + mode
		var coverage: Variant = report.get("coverage")
		if not coverage is Dictionary or not _complete_coverage(coverage, current, fresh_start): return "Joint actual coverage incomplete: " + mode
	return ""

static func _complete_coverage(coverage: Dictionary, actual_snapshot: Dictionary = {}, fresh_start: bool = false) -> bool:
	if not coverage.get("world") is Dictionary or not _release_flags(coverage.world) or not _false(coverage.world.get("complete")): return false
	for key: String in (["city", "outskirts"] if fresh_start else ["city", "outskirts", "migration"]):
		if not coverage.get(key) is Dictionary or coverage[key].get("complete") != true: return false
	if not _exact_ids(coverage.world.get("portal_ids"), WORLD.PORTAL_IDS) or not _exact_ids(coverage.world.get("core_ids"), WORLD_GATE.CORE_IDS) or coverage.world.get("chunk_count") != 64 or coverage.world.get("seam_count") != 112: return false
	if not _exact_ids(coverage.city.get("region_ids"), CITY.LEGACY_SHAS.keys()) or coverage.city.get("normal_gameplay") != true: return false
	var identities := {"npcs": [], "interactions": [], "portals": []}
	for id: String in CITY.LEGACY_SHAS:
		var original: SceneScript = CITY.legacy_scene(StringName(id))
		if original == null: return false
		for npc: Dictionary in original.npcs: identities.npcs.append(id + "/" + String(npc.npc_id))
		for entry: Dictionary in original.map_layout.interactions: identities.interactions.append(id + "/" + String(entry.id))
		for entry: Dictionary in original.map_layout.portals: identities.portals.append(id + "/" + String(entry.id))
	for key: String in identities:
		if not _exact_ids(coverage.city.get(key + "_ids"), identities[key]): return false
	if not _water_absence_proofs(coverage.city.get("water_decoration_absence_proofs"), actual_snapshot): return false
	if not _exact_ids(coverage.outskirts.get("scene_ids"), ["openworld_v15_bamboo_outskirts", "openworld_v15_forest_outskirts", "openworld_v15_marsh_outskirts"]) or coverage.outskirts.get("normal_encounter_rewards_returns") != true: return false
	if fresh_start: return not coverage.has("migration") and _current_save_load(coverage.get("current_save_load"), actual_snapshot)
	return not coverage.has("current_save_load") and _exact_ids(coverage.migration.get("world_source_versions"), [12, 13, 14, 15]) and _exact_ids(coverage.migration.get("local_source_versions"), [1, 3]) and coverage.migration.get("repeat_no_remap") == true and coverage.migration.get("unknown_rejected_zero_mutation") == true

static func _water_absence_proofs(value: Variant, actual_snapshot: Dictionary) -> bool:
	# Exact object exception only. Source role never certifies a missed station;
	# the actual complete continuous-domain QA proof is an approval prerequisite.
	if not value is Array or value.size() != 1 or actual_snapshot.is_empty(): return false
	var summary: Variant = value[0]
	if not summary is Dictionary or summary.get("region_id") != "ch4_s2_canal_docks" or summary.get("object_id") != "moored_canal_boat" or summary.get("method") != "continuous_full_drawrect_axis_separation" or summary.get("complete") != true: return false
	var id := &"ch4_s2_canal_docks"
	var manifest_path: String = CITY.ROOT + String(id) + "/art_contract.json"
	var manifest: Dictionary = WORLD.read_json(manifest_path)
	var boat: Dictionary = {}
	for object: Variant in manifest.get("objects", []):
		if object is Dictionary and object.get("id") == "moored_canal_boat": boat = object
	if boat.is_empty() or boat.get("role") != "water_decoration" or not CITY._object_role_error(id, boat).is_empty(): return false
	var nav_path: String = String(manifest.get("walk_path", ""))
	var source_path: String = String(boat.get("texture", ""))
	for binding: Array in [["manifest_sha256", manifest_path], ["nav_sha256", nav_path], ["source_sha256", source_path]]:
		if not actual_snapshot.has(binding[1]) or not _hash(summary.get(binding[0])) or String(summary[binding[0]]).to_lower() != actual_snapshot[binding[1]]: return false
	for key: String in ["source_frame_count", "source_alpha_pixels", "legal_nav_cells"]:
		if not _positive_integer(summary.get(key)): return false
	if not _number(summary.get("intersection_count"), 0) or not _positive(summary.get("minimum_gap_px")) or not summary.get("evidence") is Dictionary or not _bound_evidence(summary.evidence): return false
	var evidence: Dictionary = WORLD.read_json(String(summary.evidence.path))
	if evidence.get("scope") != "CONTINUOUS_ALL_NORMAL_PLAYER_WEAPONS_AND_ALL_GATED_NPC_FAMILIES" or evidence.get("complete") != true or not evidence.get("families") is Array or evidence.families.is_empty(): return false
	var original: SceneScript = CITY.legacy_scene(id)
	if original == null: return false
	var expected: Array = []
	for npc: Dictionary in original.npcs: expected.append(String(npc.npc_id))
	if not _exact_ids(evidence.get("normal_npc_ids"), expected): return false
	var seen: Dictionary = {}
	var frames := 0
	var gap := INF
	for family: Variant in evidence.families:
		if not family is Dictionary or not _water_family(family, summary, boat, actual_snapshot): return false
		frames += int(family.source_frame_count)
		gap = minf(gap, float(family.minimum_gap_px))
		for actor: Dictionary in family.actor_domains:
			if not String(actor.actor).begins_with("normal_player_"): seen[String(actor.actor)] = true
	if not _exact_ids(seen.keys(), expected) or not _number(summary.source_frame_count, frames) or absf(float(summary.minimum_gap_px) - gap) > .00001: return false
	return true

static func _water_family(row: Dictionary, summary: Dictionary, boat: Dictionary, actual_snapshot: Dictionary) -> bool:
	if row.get("complete") != true or row.get("method") != "continuous_full_drawrect_axis_separation" or row.get("region_id") != summary.region_id or row.get("object_id") != summary.object_id: return false
	for key: String in ["manifest_sha256", "nav_sha256", "source_sha256", "source_alpha_pixels", "legal_nav_cells"]:
		if row.get(key) != summary.get(key): return false
	if row.get("source_path") != boat.get("texture") or not _number(row.get("all_nav_cells_read"), 3072 * 2048) or not _number(row.get("linear_filter_margin_world_px"), 1) or not _number(row.get("intersection_count"), 0) or not _positive_integer(row.get("source_frame_count")): return false
	var bounds: Variant = row.get("prop_actual_world_rect_with_linear_margin")
	if not bounds is Array or bounds.size() != 4: return false
	var render: Vector2 = CITY._vec(boat.render_size_px)
	var origin: Vector2 = CITY._vec(boat.world_foot_px) - CITY._vec(boat.foot_uv) * render - Vector2.ONE
	for index in 4:
		var expected: float = [origin.x, origin.y, render.x + 2, render.y + 2][index]
		if typeof(bounds[index]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(bounds[index])) or absf(float(bounds[index]) - expected) > .01: return false
	if not row.get("actor_domains") is Array or row.actor_domains.is_empty(): return false
	var rightmost := -INF
	var frames := 0
	var player_count := 0
	for actor: Variant in row.actor_domains:
		if not actor is Dictionary: return false
		var is_player: bool = actor.get("actor") == "normal_player_all_five_weapon_families"
		if is_player: player_count += 1
		var sources: Variant = actor.get("sources")
		var source_rows: Variant = sources.get("sources") if is_player and sources is Dictionary else sources
		var script_key: String = "Player_script_sha256" if is_player else "NPC_script_sha256"
		var script_path: String = "res://scripts/field/player.gd" if is_player else "res://scripts/field/npc_node.gd"
		var family_data: Dictionary = sources if is_player and sources is Dictionary else actor
		if family_data.get("valid") != true or not _positive_integer(family_data.get("frame_count")) or family_data.get(script_key) != actual_snapshot.get(script_path) or not source_rows is Array or source_rows.is_empty(): return false
		if is_player and source_rows.size() != 40: return false
		var source_frames := 0
		var right_extent := 0.0
		var unique: Dictionary = {}
		for source: Variant in source_rows:
			if not source is Dictionary or source.get("valid") != true or not _positive_integer(source.get("frames")) or not _positive_integer(source.get("cell_px")) or not _positive(source.get("right_extent_px")): return false
			var path: String = String(source.get("path", ""))
			if unique.has(path) or not actual_snapshot.has(path) or not _hash(source.get("sha256")) or String(source.sha256).to_lower() != actual_snapshot[path]: return false
			unique[path] = true
			if not CITY._png_size(path, Vector2i(int(source.cell_px) * int(source.frames), int(source.cell_px))): return false
			if is_player:
				var weapon: Variant = source.get("weapon")
				var state: Variant = source.get("state")
				var direction: Variant = source.get("direction")
				if weapon not in ["sword", "dao", "staff", "palm", "hidden"] or state not in ["idle", "walk"] or direction not in ["down", "up", "left", "right"]: return false
				var count: int = 4 if state == "idle" else 8
				if not _number(source.frames, count) or path != "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/%s/lengguyun_%s_%s_%s_25d_%df.png" % [weapon, weapon, state, direction, count]: return false
			var scale_value: Variant = source.get("actual_normal_scale" if is_player else "scale")
			if not _positive(scale_value) or float(source.right_extent_px) < float(source.cell_px) * .5 * float(scale_value) + 1: return false
			if is_player and not _number(scale_value, .945 * .91): return false
			source_frames += int(source.frames)
			right_extent = maxf(right_extent, float(source.right_extent_px))
		if not _number(family_data.frame_count, source_frames): return false
		frames += source_frames
		if typeof(actor.get("rightmost_draw_x")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(actor.rightmost_draw_x)): return false
		if typeof(actor.get("root_upper_x")) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(actor.root_upper_x)) or float(actor.rightmost_draw_x) < float(actor.root_upper_x) + right_extent: return false
		if is_player:
			if not _positive_integer(row.get("nav_max_white_x")) or float(row.nav_max_white_x) >= CITY.SIZE.x or float(actor.root_upper_x) < float(row.nav_max_white_x) + .5 - CITY.BODY_SIZE.x * .5: return false
		rightmost = maxf(rightmost, float(actor.rightmost_draw_x))
	if player_count != 1 or not _number(row.source_frame_count, frames) or not _positive(row.get("minimum_gap_px")) or absf(float(row.minimum_gap_px) - (origin.x - rightmost)) > .00001: return false
	var negatives: Variant = row.get("negative_stations")
	if not negatives is Array or negatives.size() != 4: return false
	var directions: Array = []
	for negative: Variant in negatives:
		if not negative is Dictionary or not _number(negative.get("prop_ghost_pixels"), 0) or not negative.get("current_alpha") is Dictionary or not _number(negative.current_alpha.get("hits"), 0) or not negative.get("actual_input") is Dictionary or negative.actual_input.get("ok") != true: return false
		var direction: Vector2 = CITY._vec(negative.get("direction"))
		if direction not in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT] or direction in directions: return false
		directions.append(direction)
	return true

static func _true(value: Variant) -> bool:
	return typeof(value) == TYPE_BOOL and value == true

static func _false(value: Variant) -> bool:
	return typeof(value) == TYPE_BOOL and value == false

static func _release_flags(row: Dictionary) -> bool:
	return _true(row.get("release_complete")) and _false(row.get("legacy_full_executed")) and _false(row.get("exhaustive_2687_normal_input_executed"))

static func _mode_metadata(row: Dictionary, fresh_start: bool) -> bool:
	if not fresh_start: return not row.has("fresh_start_only") or _false(row.get("fresh_start_only"))
	return _fresh_metadata_fields(row) and row.get("scope") == FRESH_START_SCOPE and row.get("phase") == FRESH_START_PHASE

static func _fresh_metadata_fields(row: Dictionary) -> bool:
	return _true(row.get("fresh_start_only")) and _false(row.get("historical_compatibility_tested")) and _seam_equal(row.get("excluded_historical_versions"), EXCLUDED_HISTORICAL_VERSIONS) and _seam_equal(row.get("excluded_world_source_versions"), [12, 13, 14]) and _seam_equal(row.get("excluded_local_source_versions"), [1])

static func _historical_not_executed(value: Variant) -> bool:
	return value is Dictionary and value.get("scope") == "HISTORICAL_COMPATIBILITY_NOT_EXECUTED" and _false(value.get("complete")) and value.get("records") is Array and value.records.is_empty()

static func _fresh_review_inputs(technical: Dictionary, visual: Dictionary) -> bool:
	for key: String in ["actual_runs", "frozen_inputs_path", "frozen_inputs_sha256"]:
		if not _seam_equal(technical.get(key), visual.get(key)): return false
	var frozen_path: Variant = technical.get("frozen_inputs_path")
	if not frozen_path is String or not frozen_path.begins_with("res://build/joint_world_luoyang_20261003_qa/") or ".." in frozen_path or not _hash(technical.get("frozen_inputs_sha256")) or FileAccess.get_sha256(frozen_path).to_lower() != technical.frozen_inputs_sha256: return false
	var frozen: Dictionary = WORLD.read_json(frozen_path)
	if not _number(frozen.get("schema"), 1) or frozen.get("scope") != FRESH_START_FROZEN_SCOPE or not _fresh_metadata_fields(frozen): return false
	var runs: Dictionary = technical.actual_runs
	if not runs.get("headless") is Dictionary or not runs.get("gpu") is Dictionary: return false
	for role: String in ["result", "stdout", "stderr", "wrapper_before", "wrapper_after"]:
		if not runs.headless.get(role) is Dictionary or not runs.gpu.get(role) is Dictionary or not _bound_evidence(runs.headless[role]) or not _bound_evidence(runs.gpu[role]) or runs.headless[role].path == runs.gpu[role].path: return false
	var headless: Dictionary = WORLD.read_json(runs.headless.wrapper_after.path)
	var gpu: Dictionary = WORLD.read_json(runs.gpu.wrapper_after.path)
	return _positive_integer(headless.get("actual_wrapper_pid")) and _positive_integer(gpu.get("actual_wrapper_pid")) and headless.actual_wrapper_pid != gpu.actual_wrapper_pid

static func _fresh_actual_run(run: Dictionary, report: Dictionary, review: Dictionary, mode: String) -> bool:
	var before: Dictionary = WORLD.read_json(run.wrapper_before.path)
	var after: Dictionary = WORLD.read_json(run.wrapper_after.path)
	var args: Variant = before.get("user_arguments")
	if before.get("entry") != RELEASE_ENTRY or typeof(before.get("gpu")) != TYPE_BOOL or before.gpu != (mode == "gpu") or not _number(after.get("actual_os_exit"), 0) or not _seam_equal(after.get("source_changes"), []) or not _seam_equal(after.get("player_file_changes"), []) or not before.get("player_files") is Array or before.player_files.size() != 15: return false
	if not args is Array or args.count("--fresh-start-only") != 1 or "--candidate-before-cutover" not in args or ("--qa-frozen-inputs=" + String(review.frozen_inputs_path)) not in args or (mode == "gpu" and "--qa-gpu-approved" not in args): return false
	if not _true(report.get("completed")) or not _true(report.get("candidate_before_cutover")) or report.get("requested_phase") != "release" or not _seam_equal(report.get("unfinished_categories"), []): return false
	return report.get("frozen_inputs_path") == review.frozen_inputs_path and report.get("frozen_inputs_sha256") == review.frozen_inputs_sha256 and report.get("frozen_inputs_sha256_before") == review.frozen_inputs_sha256

static func _current_proof_executor(value: Dictionary, current: Dictionary) -> bool:
	return _fresh_metadata_fields(value) and value.get("executing_script_path") == CURRENT_SAVE_LOAD_EXECUTOR and _hash(current.get(CURRENT_SAVE_LOAD_EXECUTOR)) and value.get("executing_script_sha256") == current[CURRENT_SAVE_LOAD_EXECUTOR]

static func _actual_new_game(value: Variant, current: Dictionary) -> bool:
	if not value is Dictionary or not _current_proof_executor(value, current) or value.get("scope") != "ACTUAL_MAIN_MENU_NEW_GAME_INPUT" or not _true(value.get("complete")) or not _true(value.get("normal_button_input")) or value.get("actual_start_scene_id") != "linxi_tutorial" or not _true(value.get("player_saves_unchanged")) or not _true(value.get("formal_requires_world15")) or not _true(value.get("candidate_reset_uses_formal_baseline")): return false
	var input: Variant = value.get("input")
	if not input is Dictionary or not _seam_pair(input.get("logical")) or not _seam_pair(input.get("physical")) or not input.get("final_transform") is Array or input.final_transform.size() != 6: return false
	for component: Variant in input.final_transform:
		if typeof(component) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(component)): return false
	var logical := Vector2(float(input.logical[0]), float(input.logical[1]))
	var physical := Vector2(float(input.physical[0]), float(input.physical[1]))
	if not logical.is_finite() or not physical.is_finite(): return false
	var transform: Array = input.final_transform
	var projected := Vector2(float(transform[0]) * float(input.logical[0]) + float(transform[2]) * float(input.logical[1]) + float(transform[4]), float(transform[1]) * float(input.logical[0]) + float(transform[3]) * float(input.logical[1]) + float(transform[5]))
	if not projected.is_finite(): return false
	var pointer_distance: float = projected.distance_to(physical)
	if not is_finite(pointer_distance) or pointer_distance > .03: return false
	var navigation: Variant = value.get("actual_reset_navigation")
	# A candidate flag must not counterfeit a production cutover. The normal
	# menu reset uses the unchanged formal baseline; later isolated saves prove15.
	return navigation is Dictionary and navigation.get("current_field") == "linxi_tutorial" and _number(value.get("formal_world_version"), WORLD.formal_version()) and _number(navigation.get("world_map_version"), WORLD.formal_version()) and _seam_equal(navigation.get("local_layout_versions"), {}) and _seam_equal(navigation.get("portal_return_spawns"), {})

static func _current_save_file(path: Variant, sha: Variant, isolated_root: String) -> Dictionary:
	if not path is String or not path.begins_with(isolated_root + "/") or ".." in path or "\\" in path or not _hash(sha) or FileAccess.get_sha256(path).to_lower() != String(sha).to_lower(): return {}
	return WORLD.read_json(path)

static func _current_navigation(value: Variant, id: String, city_ids: Array) -> bool:
	if not value is Dictionary or value.get("current_field") != id or not _number(value.get("world_map_version"), 15) or not value.get("local_layout_versions") is Dictionary or not _seam_pair(value.get("current_field_spawn")): return false
	for city: Variant in value.local_layout_versions:
		if not city is String or city not in city_ids or not _number(value.local_layout_versions[city], 3): return false
	return _exact_ids(value.local_layout_versions.keys(), city_ids)

static func _current_native_pair_equal(actual: Variant, expected: Variant) -> bool:
	if not _seam_pair(actual) or not _seam_pair(expected): return false
	var actual_native := Vector2(float(actual[0]), float(actual[1]))
	var expected_native := Vector2(float(expected[0]), float(expected[1]))
	return actual_native.is_finite() and expected_native.is_finite() and var_to_bytes(actual_native) == var_to_bytes(expected_native)

static func _current_save_load(value: Variant, current: Dictionary) -> bool:
	if not value is Dictionary or not _current_proof_executor(value, current) or value.get("scope") != "CURRENT_FORMAT_SAVE_LOAD_FIELD_BIRTH_NO_HISTORICAL_COMPATIBILITY" or not _true(value.get("complete")) or not _positive_integer(value.get("checks")) or not _number(value.get("failures"), 0) or not _number(value.get("world_coordinate_version"), 15) or not _number(value.get("city_layout_version"), 3) or not _number(value.get("save_schema_version"), 14) or not _true(value.get("player_saves_unchanged")): return false
	for flag: String in ["actual_save_load_field_birth", "repeat_no_remap", "state_preserved", "unknown_rejected_zero_mutation"]:
		if not _true(value.get(flag)): return false
	var isolated_root: Variant = value.get("isolated_root")
	var root_pattern: RegEx = RegEx.new()
	if not isolated_root is String or root_pattern.compile("^user://world_map_v15_qa/current_format_[0-9]+_[1-9][0-9]*$") != OK or root_pattern.search(isolated_root) == null: return false
	var cities: Array = CITY.LEGACY_SHAS.keys()
	var ordinary: Array = ["openworld_bianzhou_city", "openworld_wudang_gate", "linxi_village_scrollmap"]
	var outskirts: Array = ["openworld_v15_bamboo_outskirts", "openworld_v15_forest_outskirts", "openworld_v15_marsh_outskirts"]
	var expected: Array = [String(WORLD.CANDIDATE_ID)] + cities + ordinary + outskirts
	if not _exact_ids(value.get("scene_ids"), expected) or not value.get("records") is Array or value.records.size() != 11 or not value.get("unknown_records") is Array or value.unknown_records.size() != 26: return false
	var seen: Array = []
	var paths: Array = []
	for row: Variant in value.records:
		if not row is Dictionary or not row.get("scene_id") is String or row.scene_id not in expected or row.scene_id in seen: return false
		var id: String = row.scene_id
		var domain: String = "world" if id == String(WORLD.CANDIDATE_ID) else ("city" if id in cities else ("ordinary" if id in ordinary else "outskirts"))
		if row.get("domain") != domain: return false
		for flag: String in ["saved", "loaded", "actual_Field_birth", "reloaded", "actual_birth_full_feet_clear", "repeat_no_remap", "state_preserved"]:
			if not _true(row.get(flag)): return false
		var directory: String = isolated_root + "/current_%02d/" % seen.size()
		if row.get("input_path") != directory + "save_0.json" or row.get("repeated_path") != directory + "save_1.json" or row.get("final_path") != directory + "save_2.json" or not _true(row.get("passed")): return false
		var saved: Dictionary = _current_save_file(row.input_path, row.get("input_sha256"), isolated_root)
		var repeated: Dictionary = _current_save_file(row.repeated_path, row.get("repeated_sha256"), isolated_root)
		var final_save: Dictionary = _current_save_file(row.final_path, row.get("final_sha256"), isolated_root)
		if saved.is_empty() or repeated.is_empty() or final_save.is_empty() or row.input_path in paths or row.repeated_path in paths or row.final_path in paths: return false
		paths.append(row.input_path); paths.append(row.repeated_path); paths.append(row.final_path)
		for stored: Dictionary in [saved, repeated, final_save]:
			if stored.get("current_field") != id or not _number(stored.get("version"), 14) or not _seam_equal(stored.get("navigation"), saved.get("navigation")): return false
			var state: Dictionary = stored.duplicate(true)
			var original_state: Dictionary = saved.duplicate(true)
			for field: String in ["timestamp", "slot", "navigation", "current_field"]: state.erase(field); original_state.erase(field)
			if not _seam_equal(state, original_state): return false
		for key: String in ["navigation_before", "loaded_navigation", "reloaded_navigation"]:
			if not _current_navigation(row.get(key), id, cities) or not _seam_equal(row[key], saved.get("navigation")): return false
		if not _seam_equal(repeated.get("navigation"), saved.get("navigation")): return false
		if not row.get("births") is Array or row.births.size() != 2: return false
		for birth: Variant in row.births:
			if not _current_birth(birth, id, domain, row.navigation_before): return false
		seen.append(id)
	if not _exact_ids(seen, expected): return false
	var mutations: Dictionary = {"world": [-1, 16, 99, 15.5, "15", true], "local": [2, 99, 1.5, "3", true]}
	var unknown_seen: Dictionary = {}
	for row: Variant in value.unknown_records:
		if not row is Dictionary or not row.get("scene_id") is String or row.get("version_domain") not in ["world", "local"] or not _false(row.get("loaded")) or not _true(row.get("zero_mutation")) or not row.get("before") is Dictionary or row.before.is_empty() or not _seam_equal(row.before, row.get("after")): return false
		var domain: String = row.version_domain
		if (domain == "world" and row.scene_id != String(WORLD.CANDIDATE_ID)) or (domain == "local" and row.scene_id not in cities): return false
		var index := -1
		for i in mutations[domain].size():
			if _seam_equal(row.get("version"), mutations[domain][i]): index = i; break
		if index < 0: return false
		var key: String = row.scene_id + "/" + domain + "/" + str(index)
		if unknown_seen.has(key) or row.get("input_path") in paths: return false
		if row.get("input_path") != isolated_root + "/unsupported_%02d/save_0.json" % unknown_seen.size(): return false
		var saved: Dictionary = _current_save_file(row.input_path, row.get("input_sha256"), isolated_root)
		if saved.is_empty() or not _number(saved.get("version"), 14) or saved.get("current_field") != row.scene_id or not saved.get("navigation") is Dictionary: return false
		var navigation: Dictionary = saved.navigation.duplicate(true)
		if domain == "world":
			if not _seam_equal(navigation.get("world_map_version"), row.version): return false
			navigation.world_map_version = 15
		else:
			if not navigation.get("local_layout_versions") is Dictionary or not _seam_equal(navigation.local_layout_versions.get(row.scene_id), row.version): return false
			navigation.local_layout_versions[row.scene_id] = 3
		if not _current_navigation(navigation, row.scene_id, cities): return false
		unknown_seen[key] = true
		paths.append(row.input_path)
	return unknown_seen.size() == 26

static func _current_birth(value: Variant, id: String, domain: String, navigation: Dictionary) -> bool:
	if not value is Dictionary or value.get("scene_id") != id or not _seam_pair(navigation.get("current_field_spawn")): return false
	for flag: String in ["raw_full_feet_clear", "actual_Physics_clear", "position_matches_saved"]:
		if not _true(value.get(flag)): return false
	for key: String in ["actor_root_px", "world_size_px", "expected_root_normalized", "actual_root_normalized", "layout_design_size_px", "visible_foot_px", "visible_offset_px"]:
		if not _seam_pair(value.get(key)): return false
	var size := Vector2(float(value.world_size_px[0]), float(value.world_size_px[1]))
	var root := Vector2(float(value.actor_root_px[0]), float(value.actor_root_px[1]))
	var expected := Vector2(float(navigation.current_field_spawn[0]), float(navigation.current_field_spawn[1]))
	var actual := Vector2(float(value.actual_root_normalized[0]), float(value.actual_root_normalized[1]))
	var foot := Vector2(float(value.visible_foot_px[0]), float(value.visible_foot_px[1]))
	var offset := Vector2(float(value.visible_offset_px[0]), float(value.visible_offset_px[1]))
	for point: Vector2 in [size, root, expected, actual, foot, offset]:
		if not point.is_finite(): return false
	var actual_root: Vector2 = actual * size
	var expected_root: Vector2 = expected * size
	var expected_foot: Vector2 = root + offset
	for point: Vector2 in [actual_root, expected_root, expected_foot]:
		if not point.is_finite(): return false
	var actual_distance: float = actual_root.distance_to(root)
	var expected_distance: float = root.distance_to(expected_root)
	var foot_distance: float = foot.distance_to(expected_foot)
	for distance: float in [actual_distance, expected_distance, foot_distance]:
		if not is_finite(distance): return false
	# Existing actual-actor pixel contract, not a new normalized Float64 epsilon.
	# Restore saved/default-JSON pairs to native Vector2 before comparison.
	if size.x <= 0 or size.y <= 0 or not _current_native_pair_equal(value.expected_root_normalized, navigation.current_field_spawn) or actual_distance > .03 or expected_distance > .03 or foot_distance > .03: return false
	if domain == "world" and (size != WORLD.SIZE or not _number(value.get("layout_schema_version"), 15)): return false
	if domain == "city" and (size != CITY.SIZE or not _number(value.get("layout_schema_version"), 3)): return false
	if domain == "outskirts" and size != Vector2(1536, 1024): return false
	var path: String = CITY.candidate_path(StringName(id)) if domain == "city" else "res://data/scenes/" + id + ".tres"
	var scene: SceneScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	return scene != null and scene.map_layout != null and _number(value.get("layout_schema_version"), scene.map_layout.schema_version) and _seam_equal(value.layout_design_size_px, [scene.map_layout.design_size.x, scene.map_layout.design_size.y])

static func _selection_error(source: Dictionary) -> String:
	if FileAccess.get_sha256(RELEASE_SELECTION_PATH).to_lower() != RELEASE_SELECTION_SHA: return "Missing/stale fixed preexecution RELEASE selection"
	var selection: Dictionary = WORLD.read_json(RELEASE_SELECTION_PATH)
	if selection.get("schema_version") != 1 or selection.get("scope") != "PREEXECUTION_FIXED_RISK_STRATIFIED_SELECTION_NOT_TEST_RESULT" or not _true(selection.get("selection_frozen_before_execution")) or not _false(selection.get("selection_replacement_after_failure_permitted")) or not _false(selection.get("normal_input_exhaustive")): return "Selection scope cannot assert execution/approval or permit postfailure replacement"
	if not _number(selection.get("object_count"), 2687) or not _number(selection.get("blocking_count"), 2322) or not _number(selection.get("unique_png_sha_count"), 44) or not _number(selection.get("seam_count"), 112) or not _number(selection.get("seam_static_witness_count"), 1344) or not _number(selection.get("seam_actual_input_count"), 112): return "Wrong fixed RELEASE inventory/PNG/seam cardinality"
	var objects: Variant = source.get("objects")
	var bindings: Variant = selection.get("all_bindings")
	if not objects is Array or objects.size() != 2687 or not bindings is Array or bindings.size() != 2687: return "All2687 current/frozen object bindings required"
	var actual: Dictionary = {}
	for value: Variant in objects:
		if not value is Dictionary or not value.get("id") is String or actual.has(value.id): return "Malformed/duplicate actual object identity"
		actual[value.id] = value
	var frozen: Dictionary = {}
	for value: Variant in bindings:
		if not value is Dictionary or not value.get("id") is String or frozen.has(value.id) or not actual.has(value.id): return "Frozen inventory identity missing/duplicate"
		var row: Dictionary = actual[value.id]
		for key: Variant in value:
			if key != "texture_sha256" and (not row.has(key) or not _release_binding_value_equal(String(key), row[key], value[key])): return "Frozen spatial/physical/foot semantics changed: " + value.id
		var texture: String = String(row.get("texture", ""))
		if not _hash(value.get("texture_sha256")) or FileAccess.get_sha256(texture).to_lower() != value.texture_sha256: return "Frozen PNG class bytes changed: " + value.id
		frozen[value.id] = value
	var groups: Variant = selection.get("png_groups")
	if not groups is Array or groups.size() != 44: return "Exactly44 actual PNG classes required"
	var pngs: Dictionary = {}
	var members: Dictionary = {}
	for value: Variant in groups:
		if not value is Dictionary or not _hash(value.get("sha256")) or pngs.has(value.sha256) or not value.get("ids") is Array or value.ids.is_empty(): return "Malformed/duplicate PNG class"
		pngs[value.sha256] = true
		for id: Variant in value.ids:
			if not id is String or members.has(id) or not frozen.has(id) or frozen[id].texture_sha256 != value.sha256: return "PNG class membership differs from frozen actual inventory"
			members[id] = true
	if members.size() != 2687: return "PNG classes do not cover all inventory exactly once"
	var representatives: Variant = selection.get("representatives")
	if not representatives is Array or representatives.size() != 130: return "Exactly130 preselected danger/PNG/spatial representatives required"
	var selected: Dictionary = {}
	var selected_pngs: Dictionary = {}
	var families: Dictionary = {}
	for value: Variant in representatives:
		if not value is Dictionary or not value.get("id") is String or selected.has(value.id) or not frozen.has(value.id) or value.get("texture_sha256") != frozen[value.id].texture_sha256 or not value.get("reasons") is Array or value.reasons.is_empty() or not value.get("family") is String: return "Malformed/replaced fixed representative"
		selected[value.id] = true
		selected_pngs[value.texture_sha256] = true
		families[value.family] = true
	if not _exact_ids(selected_pngs.keys(), pngs.keys()) or not _exact_ids(families.keys(), selection.get("families", [])): return "Selected input misses a PNG class/family"
	if not _exact_ids(families.keys(), ["bamboo", "boulder", "bridge_deck", "bridge_post", "bridge_rail", "herb", "independent_generated_compound", "tree"]): return "Wrong eight RELEASE families"
	var seams: Variant = selection.get("seams")
	var current_seams: Variant = source.get("seams")
	if not seams is Array or seams.size() != 112 or not current_seams is Array or current_seams.size() != 112: return "All112 current/frozen boundaries required"
	var seam_by_id: Dictionary = {}
	for value: Variant in current_seams:
		if not value is Dictionary or not value.get("id") is String or seam_by_id.has(value.id): return "Malformed current boundary"
		seam_by_id[value.id] = value
	var seen: Dictionary = {}
	for value: Variant in seams:
		if not value is Dictionary or not value.get("id") is String or seen.has(value.id) or not seam_by_id.has(value.id) or value.get("classification") != "open" or not value.get("projected_witnesses") is Array or value.projected_witnesses.size() != 12: return "Malformed fixed boundary/witness selection"
		var indices: Variant = value.get("actual_input_witness_indices")
		# JSON numbers deserialize as floats; require the same sole numeric zero.
		if not indices is Array or indices.size() != 1 or not _number(indices[0], 0): return "Malformed fixed boundary/witness selection"
		var current: Dictionary = seam_by_id[value.id]
		if current.get("classification") != value.classification or current.get("projected_witnesses") != value.projected_witnesses: return "Current boundary differs from frozen complete witnesses"
		seen[value.id] = true
	return ""

static func _release_binding_value_equal(key: String, actual: Variant, expected: Variant) -> bool:
	if key != "collision_offset": return actual == expected
	# Only this runtime Vector2 field: decimal/exponent JSON spellings can
	# parse to different Float64 tails. Require EXACT native Vector2 bytes,
	# never an epsilon, normalization of other fields, or altered selection.
	if not actual is Array or actual.size() != 2 or not expected is Array or expected.size() != 2: return false
	for index in 2:
		if typeof(actual[index]) not in [TYPE_INT,TYPE_FLOAT] or typeof(expected[index]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(actual[index])) or not is_finite(float(expected[index])): return false
	var actual_native := Vector2(float(actual[0]),float(actual[1]))
	var expected_native := Vector2(float(expected[0]),float(expected[1]))
	return actual_native.is_finite() and expected_native.is_finite() and var_to_bytes(actual_native) == var_to_bytes(expected_native)

static func _release_actual_evidence(report: Dictionary, current: Dictionary, mode: String, fresh_start: bool = false) -> bool:
	if not _mode_metadata(report, fresh_start): return false
	if not _true(report.get("field_executed")) or not _true(report.get("player_saves_unchanged")) or not report.get("normal_files_before") is Dictionary or report.normal_files_before.size() != 15 or report.get("normal_files_after") != report.normal_files_before: return false
	var coverage: Variant = report.get("coverage")
	if not coverage is Dictionary or not coverage.get("world") is Dictionary or coverage.world.get("selection_path") != RELEASE_SELECTION_PATH or coverage.world.get("selection_sha256") != RELEASE_SELECTION_SHA: return false
	if not report.get("phase_reports") is Dictionary: return false
	var phases: Dictionary = report.phase_reports
	for key: String in ["world", "city", "outskirts"]:
		if not phases.get(key) is Dictionary or not _number(phases[key].get("failures"), 0) or not _true(phases[key].get("player_saves_unchanged")): return false
	var world: Dictionary = phases.world
	if not _release_flags(world) or not _false(world.get("source_complete")) or not _true(world.get("field_input_executed")) or world.get("selection_path") != RELEASE_SELECTION_PATH or world.get("selection_sha256") != RELEASE_SELECTION_SHA or not _false(world.get("all1344_seam_witnesses_normal_input_executed")): return false
	if not world.get("completed_phases") is Array or not world.get("incomplete_phases") is Array or not world.incomplete_phases.is_empty(): return false
	for required: String in RELEASE_WORLD_REQUIRED:
		if fresh_start and required in ["actual48_historic_isolated_save_load_Field_birth_and15_reread", "actual_free_indoor_native15_and_unknown_version_zero_mutation_saves"]: continue
		if required not in world.completed_phases: return false
	if fresh_start:
		for historical: String in ["actual48_historic_isolated_save_load_Field_birth_and15_reread", "actual_free_indoor_native15_and_unknown_version_zero_mutation_saves"]:
			if historical in world.completed_phases: return false
	if not _release_objects(world.get("all_current_objects"), current) or not _release_seams(world): return false
	if not world.get("actual_route_input") is Array or world.actual_route_input.size() != 27 or not world.get("portal_roundtrips") is Array or world.portal_roundtrips.size() != 48: return false
	var current_source: Dictionary = WORLD.read_json(WORLD.SOURCE_PATH)
	var routes: Variant = current_source.get("routes")
	if not routes is Array or routes.size() != 27: return false
	var expected_routes: Array = []
	for row: Variant in routes:
		if not row is Dictionary or not row.get("id") is String: return false
		expected_routes.append(row.id)
	var actual_routes: Array = []
	for row: Variant in world.actual_route_input:
		if not row is Dictionary or not _true(row.get("ok")) or not row.get("id") is String: return false
		actual_routes.append(row.id)
	if not _exact_ids(actual_routes, expected_routes): return false
	var contexts: Variant = world.get("actual_saved_contexts")
	if fresh_start:
		if not _historical_not_executed(contexts) or not _current_save_load(phases.get("current_save_load"), current) or not _seam_equal(phases.current_save_load, coverage.get("current_save_load")) or not _actual_new_game(phases.get("new_game"), current): return false
	else:
		if not contexts is Dictionary or not _true(contexts.get("complete")) or not contexts.get("records") is Array or contexts.records.size() != 24: return false
		var unknown := 0
		var native := 0
		for row: Variant in contexts.records:
			if not row is Dictionary: return false
			if row.get("kind") == "UNKNOWN_VERSION_REJECTED_ZERO_MUTATION":
				if not _false(row.get("loaded")) or not _true(row.get("zero_mutation")): return false
				unknown += 1
			elif row.get("native_navigation") is Dictionary and _number(row.native_navigation.get("world_map_version"), 15): native += 1
		if unknown != 6 or native != 18: return false
	if mode == "gpu" and (not _true(world.get("GPU_executed")) or not _true(report.get("gpu_executed"))): return false
	if mode == "headless" and (not _false(world.get("GPU_executed")) or not _false(report.get("gpu_executed"))): return false
	return _release_city(phases.city, coverage, current, fresh_start)

static func _release_objects(value: Variant, current: Dictionary) -> bool:
	if not value is Dictionary or not _release_flags(value) or not _false(value.get("complete")) or not _number(value.get("failures"), 0) or value.get("selection_path") != RELEASE_SELECTION_PATH or value.get("selection_sha256") != RELEASE_SELECTION_SHA: return false
	if not _number(value.get("static_inventory_count"), 2687) or not _number(value.get("attributed_forbidden_core_count"), 2322) or not _number(value.get("unique_png_sha_count"), 44) or not _number(value.get("representative_count"), 130): return false
	var selection: Dictionary = WORLD.read_json(RELEASE_SELECTION_PATH)
	var inventory: Variant = value.get("static_inventory")
	var records: Variant = value.get("records")
	if not inventory is Array or inventory.size() != 2687 or not records is Array or records.size() != 130: return false
	var expected: Dictionary = {}
	for row: Dictionary in selection.all_bindings: expected[row.id] = row
	var seen: Dictionary = {}
	var blocking_count := 0
	for row: Variant in inventory:
		if not row is Dictionary or not row.get("id") is String or seen.has(row.id) or not expected.has(row.id) or row.get("texture") != expected[row.id].texture or row.get("texture_sha256") != expected[row.id].texture_sha256: return false
		if current.get(row.texture) != row.texture_sha256 or not row.get("geometry") is Dictionary or not _true(row.geometry.get("exact_binding")) or not row.get("forbidden_core") is Dictionary: return false
		var blocking: bool = _true(expected[row.id].get("blocking"))
		if row.geometry.get("blocking") != blocking: return false
		if blocking:
			if not _true(row.forbidden_core.get("passed")) or not row.forbidden_core.get("matched") is Dictionary: return false
			var matched: Dictionary = row.forbidden_core.matched
			if not _true(matched.get("own_rid_hit")) or not matched.get("raw_full17") is Dictionary or not _false(matched.raw_full17.get("clear")): return false
			blocking_count += 1
		elif not _true(row.forbidden_core.get("actual_body_absent")): return false
		seen[row.id] = true
	if blocking_count != 2322 or not _exact_ids(value.get("object_ids"), expected.keys()): return false
	var expected_reps: Array = []
	for row: Dictionary in selection.representatives: expected_reps.append(row.id)
	var actual_reps: Array = []
	for row: Variant in records:
		if not row is Dictionary or not row.get("id") is String or not row.get("geometry") is Dictionary or not _true(row.geometry.get("exact_binding")) or not row.get("collision") is Dictionary or not row.get("current_alpha") is Dictionary: return false
		actual_reps.append(row.id)
	return _exact_ids(actual_reps, expected_reps) and _exact_ids(value.get("representative_ids"), expected_reps) and value.get("selection_reasons") == selection.representatives and _exact_ids(value.get("families"), selection.families)

static func _release_seams(world: Dictionary) -> bool:
	# Frozen old raster witnesses and NEW fixed physical witnesses have distinct
	# credit. Never reinterpret the original 94 source-solid denials as passes.
	if FileAccess.get_sha256(PHYSICAL_SEAM_PLAN_PATH).to_lower() != PHYSICAL_SEAM_PLAN_SHA: return false
	var plan: Dictionary = WORLD.read_json(PHYSICAL_SEAM_PLAN_PATH)
	var selection: Dictionary = WORLD.read_json(RELEASE_SELECTION_PATH)
	var source: Dictionary = WORLD.read_json(WORLD.SOURCE_PATH)
	return _physical_seam_plan_schema(plan, source, selection).is_empty() and _release_layered_seams(world, plan, selection, source) and _release_layered_references(world, selection, WORLD.read_json("res://art/maps/world_map_v15_complete_v9c/art_contract.json"))

static func _release_layered_references(world: Dictionary, selection: Dictionary, manifest: Dictionary) -> bool:
	var value: Variant = world.get("saved_geometry_112")
	if not value is Dictionary or not _seam_equal(value.get("scope"), "RELEASE_LAYERED_SAVED_GEOMETRY_ALL112_FIVE_ROLE_REFERENCES_ORIGINAL1344_RASTER_ONLY") or not _number(value.get("failures"),0) or not _seam_equal(value.get("errors"),[]) or not _positive_integer(value.get("checks")): return false
	if not _false(value.get("runtime_input_executed")) or not _false(value.get("visual_approved")) or not _false(value.get("source_solid_Physics_credit")) or not _number(value.get("original_raster_witness_count"),1344) or not _seam_equal(value.get("immutable_geometry_origin_sha256"),"6ee5d11e56fb7d8cffaa2475abe801222cb94e417e2c8c0d4f0dac7586a02333"): return false
	if not _seam_equal(value.get("capture_protocol"),"COHERENT_WHOLE_FIXED_CAMERA_DERIVED_RF_V9C_FULL64_112_V1") or not _seam_equal(value.get("original_raster_seam_records"),world.get("original_raster_seam_records")): return false
	var actual: Dictionary = _seam_id_map(value.get("edges"),112)
	var original: Dictionary = _seam_id_map(selection.get("seams"),112)
	var captured: Dictionary = _seam_id_map(manifest.get("seams"),112)
	if actual.size()!=112 or original.size()!=112 or captured.size()!=112: return false
	for edge: Dictionary in _seam_edges():
		if not actual.has(edge.id) or not original.has(edge.id) or not captured.has(edge.id): return false
		var row: Dictionary = actual[edge.id]
		if not _seam_equal(row.get("classification"),"open") or not _seam_equal(row.get("witnesses"),original[edge.id].get("projected_witnesses")) or not _seam_equal(row.get("exact_kinds"),["visual","shadow_off","land","raw_walk","walk"]) or not _true(row.get("all_edge_pixels_checked")) or not _true(row.get("all_predicates_passed")): return false
		var reference: Variant = row.get("reference")
		if not reference is Dictionary or not _seam_equal(reference,captured[edge.id].get("independent_reference_capture")): return false
		var strip: Array = [edge.line-16,edge.start,32,edge.length] if edge.vertical else [edge.start,edge.line-16,edge.length,32]
		if not _seam_equal(reference.get("logical_rect_px"),strip): return false
	return true

static func _seam_equal(actual: Variant, expected: Variant) -> bool:
	if actual is Dictionary and expected is Dictionary:
		if actual.size() != expected.size(): return false
		for key: Variant in expected:
			if not actual.has(key) or not _seam_equal(actual[key], expected[key]): return false
		return true
	if actual is Array and expected is Array:
		if actual.size() != expected.size(): return false
		for index in expected.size():
			if not _seam_equal(actual[index], expected[index]): return false
		return true
	if typeof(actual) in [TYPE_INT, TYPE_FLOAT] and typeof(expected) in [TYPE_INT, TYPE_FLOAT]:
		return is_finite(float(actual)) and is_finite(float(expected)) and actual == expected
	return typeof(actual) == typeof(expected) and actual == expected

static func _seam_pair(value: Variant) -> bool:
	if not value is Array or value.size() != 2: return false
	for axis in 2:
		if typeof(value[axis]) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value[axis])): return false
	return Vector2(float(value[0]), float(value[1])).is_finite()

static func _seam_native_pair(point: Vector2) -> Variant:
	# Expected native point crosses the original writer ONCE. Saved values are
	# never re-rounded; no epsilon or generic Float32 equality is introduced.
	return JSON.parse_string(JSON.stringify([point.x, point.y]))

static func _seam_point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

static func _seam_shoe(center: Vector2, index: int) -> Vector2:
	if index == 0: return center
	var angle: float = TAU * float(index - 1) / 16.0
	return center + Vector2(cos(angle) * 10, sin(angle) * 6)

static func _seam_edges() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in 8:
		for col in 7: result.append({"id":"r%d_c%d--r%d_c%d" % [row,col,row,col+1],"vertical":true,"line":(col+1)*1536,"start":row*1024,"length":1024})
	for row in 7:
		for col in 8: result.append({"id":"r%d_c%d--r%d_c%d" % [row,col,row+1,col],"vertical":false,"line":(row+1)*1024,"start":col*1536,"length":1536})
	return result

static func _seam_id_map(value: Variant, count: int) -> Dictionary:
	var result: Dictionary = {}
	if not value is Array or value.size() != count: return {}
	for row: Variant in value:
		if not row is Dictionary or typeof(row.get("id")) != TYPE_STRING or row.id.is_empty() or result.has(row.id): return {}
		result[row.id] = row
	return result

static func _seam_input_bindings(plan: Dictionary, source: Dictionary) -> Dictionary:
	var result: Dictionary = PHYSICAL_SEAM_INPUTS.duplicate()
	var catalog: Variant = source.get("asset_sha256")
	if not catalog is Dictionary: return {}
	for row in 8:
		for col in 8:
			var path: String = "res://art/maps/world_map_v15_complete_v9c/chunks/r%d_c%d_walk.png" % [row,col]
			if not _hash(catalog.get(path)): return {}
			result[path] = catalog[path]
	if not _seam_equal(plan.get("input_sha256"), result): return {}
	var raw: Dictionary = {}
	for path: String in result:
		if path.ends_with("_walk.png"): raw[path] = result[path]
	if raw.size() != 64 or not _seam_equal(plan.get("raw_navigation_sha256"), raw): return {}
	return result

static func _physical_seam_plan_error(source: Dictionary) -> String:
	if FileAccess.get_sha256(PHYSICAL_SEAM_PLAN_PATH).to_lower() != PHYSICAL_SEAM_PLAN_SHA: return "Missing/stale distinct frozen physical seam plan"
	var plan: Dictionary = WORLD.read_json(PHYSICAL_SEAM_PLAN_PATH)
	var error: String = _physical_seam_plan_schema(plan, source, WORLD.read_json(RELEASE_SELECTION_PATH))
	if not error.is_empty(): return error
	for path: String in plan.input_sha256:
		if not FileAccess.file_exists(path) or FileAccess.get_sha256(path).to_lower() != plan.input_sha256[path]: return "Physical seam plan input changed: " + path
	return ""

static func _seam_raw_pixel(value: Variant, point: Vector2, raw_pins: Dictionary, must_clear: bool) -> bool:
	if not value is Dictionary or typeof(value.get("clear")) != TYPE_BOOL or not _seam_equal(value.get("kind"), "raw_nav") or not _seam_equal(value.get("pixel_sampling"), "round_world_pixel"): return false
	if not _seam_equal(value.get("point"), _seam_native_pair(point)): return false
	var pixel: Vector2i = Vector2i(roundi(point.x), roundi(point.y))
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= 12288 or pixel.y >= 8192: return false
	var cell: Vector2i = Vector2i(pixel.x / 1536, pixel.y / 1024)
	var path: String = "res://art/maps/world_map_v15_complete_v9c/chunks/r%d_c%d_walk.png" % [cell.y,cell.x]
	if not _seam_equal(value.get("pixel"), [pixel.x,pixel.y]) or not _seam_equal(value.get("chunk"), [cell.x,cell.y]) or not _seam_equal(value.get("path"), path) or not _seam_equal(value.get("sha256"), raw_pins.get(path)): return false
	var rgba: Variant = value.get("rgba")
	if not rgba is Array or rgba.size() != 4: return false
	for channel: Variant in rgba:
		if typeof(channel) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(channel)) or float(channel) < 0 or float(channel) > 1: return false
	var clear: bool = float(rgba[3]) >= .5 and maxf(float(rgba[0]), maxf(float(rgba[1]), float(rgba[2]))) >= .5
	return value.clear == clear and (not must_clear or clear)

static func _seam_foot_record(value: Variant, center: Vector2, objects: Dictionary, raw_pins: Dictionary) -> bool:
	if not value is Dictionary or typeof(value.get("clear")) != TYPE_BOOL or not _seam_equal(value.get("center"), _seam_native_pair(center)): return false
	if value.clear: return _seam_equal(value, {"clear":true,"kind":"full17","center":_seam_native_pair(center)})
	if not _number_index(value.get("shoe_index"), 17): return false
	var shoe: Vector2 = _seam_shoe(center, int(value.shoe_index))
	if not _seam_equal(value.get("point"), _seam_native_pair(shoe)): return false
	if _seam_equal(value.get("kind"), "raw_nav"): return _seam_raw_pixel(value, shoe, raw_pins, false)
	return _seam_equal(value.get("kind"), "source_collision") and typeof(value.get("id")) == TYPE_STRING and objects.has(value.id) and _true(objects[value.id].get("blocking")) and (_seam_equal(value.get("shape"), "exact_world_polygon") or _seam_equal(value.get("shape"), "grown_rectangle"))

static func _physical_seam_plan_schema(plan: Variant, source: Dictionary, selection: Dictionary) -> String:
	if not plan is Dictionary or not _number(plan.get("schema"), 1) or not _seam_equal(plan.get("scope"), "PREEXECUTION_FIXED_PHYSICAL_SEAM_SELECTION_NOT_FIELD_RELEASE_OR_APPROVAL") or not _seam_equal(plan.get("algorithm_identity"), PHYSICAL_SEAM_ALGORITHM): return "Physical seam preparation schema/algorithm differs"
	if not _seam_equal(plan.get("algorithm_source"), {"path":PHYSICAL_SEAM_GENERATOR,"sha256":PHYSICAL_SEAM_GENERATOR_SHA}): return "Physical seam generator identity differs"
	for key: String in ["runtime_reselection_permitted","selection_replacement_after_failure_permitted","Field_executed","actual_Physics_checked","formal_approval","visual_approved","legacy_full_executed","release_complete"]:
		if not _false(plan.get(key)): return "Physical seam preparation cannot grant execution/approval: " + key
	if not _true(plan.get("selection_frozen_before_execution")) or not _true(plan.get("old_ROOT330_94_failures_preserved")): return "Physical seam frozen selection/old failures not preserved"
	var counts: Dictionary = {"edge_count":112,"physical_static_witness_count":1344,"physical_actual_input_representative_count":112,"candidate_count":35168,"candidate_step_px":4,"candidate_start_offset_px":12,"candidate_end_exclusive_offset_px":12,"original_captured_witness_count":1344,"original_source_collision_negative_count":94}
	for key: String in counts:
		if not _number(plan.get(key), counts[key]): return "Physical seam count differs: " + key
	if not _seam_equal(plan.get("selection_formula"), "floor(k*(N-1)/11), k=0..11, N=all legal candidates in original enumeration order"): return "Physical seam rank formula differs"
	if not _seam_equal(plan.get("origin_ROOT234_selection"), {"path":RELEASE_SELECTION_PATH,"sha256":RELEASE_SELECTION_SHA,"object_count":2687,"blocking_count":2322,"representative_count":130,"all_bindings_count":2687,"object_selection_changed":false,"other_categories_changed":false}): return "Original ROOT234 inventory/selection changed"
	if _seam_input_bindings(plan, source).size() != 74: return "Physical seam exact source/74-input/64-PNG bindings differ"
	var raw_pins: Dictionary = plan.raw_navigation_sha256
	var original: Dictionary = _seam_id_map(selection.get("seams"), 112)
	var authored: Dictionary = _seam_id_map(source.get("seams"), 112)
	var objects: Dictionary = _seam_id_map(source.get("objects"), 2687)
	if original.size() != 112 or authored.size() != 112 or objects.size() != 2687 or not plan.get("seams") is Array or plan.seams.size() != 112: return "Physical seam complete original/source domains absent"
	for id: String in original:
		for domain: Dictionary in [original, authored]:
			if not domain.has(id) or not domain[id].get("projected_witnesses") is Array or domain[id].projected_witnesses.size() != 12: return "Original captured witness domain malformed"
			for witness: Variant in domain[id].projected_witnesses:
				if not witness is Dictionary or not _seam_pair(witness.get("from_px")) or not _seam_pair(witness.get("to_px")): return "Original captured witness coordinates malformed"
	var edges: Array[Dictionary] = _seam_edges()
	var scanned: int = 0
	for ei in edges.size():
		var edge: Dictionary = edges[ei]
		var row: Variant = plan.seams[ei]
		if not row is Dictionary or not _seam_equal(row.get("edge"), edge) or not _seam_equal(row.get("id"), edge.id) or not _seam_equal(row.get("classification"), "open") or not original.has(edge.id) or not authored.has(edge.id): return "Physical seam independent grid/order/identity differs"
		if not _seam_equal(row.get("original_captured_witnesses"), original[edge.id].get("projected_witnesses")) or not _seam_equal(row.get("original_captured_witnesses"), authored[edge.id].get("projected_witnesses")) or not _seam_equal(row.get("original_captured_scope"), "RASTER_REFERENCE_ALL17_NOT_SOURCE_SOLID_PASS"): return "Original captured witness bytes/credit differ"
		if not _false(row.get("runtime_reselection_permitted")) or not _seam_equal(row.get("actual_input_witness_indices"), [0]): return "Physical seam runtime selection differs"
		var candidates: Variant = row.get("all_candidates")
		var positions: Array = range(12, int(edge.length)-12, 4)
		if not candidates is Array or candidates.size() != positions.size() or not _number(row.get("candidate_count"), positions.size()): return "Physical seam full candidate domain reduced"
		var legal: Array = []
		for ci in candidates.size():
			var candidate: Variant = candidates[ci]
			var center: Vector2 = Vector2(edge.line, edge.start+positions[ci]) if edge.vertical else Vector2(edge.start+positions[ci], edge.line)
			var delta: Vector2 = Vector2(4,0) if edge.vertical else Vector2(0,4)
			var a: Vector2 = center-delta
			var b: Vector2 = center+delta
			if not candidate is Dictionary or not _number(candidate.get("candidate_index"), ci) or not _number(candidate.get("n"), positions[ci]) or not _seam_equal(candidate.get("from_px"), _seam_native_pair(a)) or not _seam_equal(candidate.get("to_px"), _seam_native_pair(b)) or typeof(candidate.get("clear")) != TYPE_BOOL: return "Physical seam candidate relocated/reordered/malformed"
			var centers: Variant = candidate.get("all_three_full17_centers")
			if not centers is Array or centers.size() != 3: return "Physical seam all three centers required"
			var first_denied: int = -1
			for si in 3:
				if not _seam_foot_record(centers[si], a.lerp(b,float(si)/2.), objects, raw_pins): return "Physical seam full17 center evidence differs"
				if not centers[si].clear and first_denied < 0: first_denied = si
			var expected_proof: Dictionary = {"clear":true,"centers":3,"max_step_px":4}
			if first_denied >= 0:
				expected_proof = centers[first_denied].duplicate(true)
				expected_proof["segment_index"] = first_denied
				expected_proof["segment_steps"] = 2
			if candidate.clear != (first_denied < 0) or not _seam_equal(candidate.get("actual_segment_evidence"), expected_proof): return "Physical seam candidate/first denial inconsistent"
			if candidate.clear: legal.append(candidate)
			scanned += 1
		if legal.size() < 12 or not _number(row.get("legal_candidate_count"), legal.size()): return "Physical seam legal candidates reduced"
		var selected: Variant = row.get("physical_witnesses")
		var ranks: Variant = row.get("selected_legal_ranks")
		if not selected is Array or selected.size() != 12 or not ranks is Array or ranks.size() != 12: return "Physical seam twelve fixed ranks required"
		for wi in 12:
			var rank: int = floori(float(wi)*float(legal.size()-1)/11.)
			if not _number(ranks[wi], rank) or not _seam_equal(selected[wi], legal[rank]): return "Physical seam fixed equal ranks replaced"
	if scanned != 35168: return "Physical seam enumeration incomplete"
	var negatives: Variant = plan.get("original_source_collision_negatives")
	if not negatives is Array or negatives.size() != 94: return "Original94 source collision negatives missing"
	var seen: Dictionary = {}
	var failure_edges: Dictionary = {}
	for value: Variant in negatives:
		if not value is Dictionary or typeof(value.get("seam_id")) != TYPE_STRING or not original.has(value.seam_id) or not _number_index(value.get("original_witness_index"),12) or typeof(value.get("id")) != TYPE_STRING or not objects.has(value.id): return "Original negative identity malformed"
		var key: String = value.seam_id + "/" + str(int(value.original_witness_index))
		var witness: Variant = original[value.seam_id].projected_witnesses[int(value.original_witness_index)]
		if seen.has(key) or not _seam_equal(value.get("original_witness"), witness) or not _number_index(value.get("shoe_index"),17) or not _seam_pair(value.get("center")) or not _seam_pair(value.get("point")): return "Original negative duplicate/relocated"
		var reason: Variant = value.get("actual_segment_evidence")
		if not reason is Dictionary or not _false(reason.get("clear")) or not _seam_equal(reason.get("kind"), "source_collision") or not _number_index(reason.get("segment_index"),3) or not _number(reason.get("segment_steps"),2): return "Original negative actual source denial absent"
		for field: String in ["id","center","point","shoe_index"]:
			if not _seam_equal(value.get(field), reason.get(field)): return "Original negative attribution differs"
		var center: Vector2 = _seam_point(witness.from_px).lerp(_seam_point(witness.to_px), float(reason.segment_index)/2.)
		var foot: Dictionary = reason.duplicate(true)
		foot.erase("segment_index")
		foot.erase("segment_steps")
		if not _seam_foot_record(foot, center, objects, raw_pins) or not _true(value.get("requires_actual_live_Physics_recheck")) or not _true(value.get("raw_full17_denial_does_not_claim_Player_center_collision")) or not _false(value.get("old_failure_claimed_passed")) or not _seam_equal(value.get("future_Physics_query_point"), "exact blocked shoe point, matched object ownRID; not the Player center"): return "Original negative shoe/source/credit differs"
		seen[key] = true
		failure_edges[value.seam_id] = int(failure_edges.get(value.seam_id,0))+1
	if not _seam_equal(failure_edges, ORIGINAL_SEAM_NEGATIVE_EDGES) or not _seam_equal(plan.get("original_source_collision_negative_edges"), failure_edges): return "Original94/11-edge negative coverage differs"
	return ""

static func _release_layered_seams(world: Dictionary, plan: Dictionary, selection: Dictionary, source: Dictionary) -> bool:
	if not _seam_equal(world.get("physical_seam_plan_path"), PHYSICAL_SEAM_PLAN_PATH) or not _seam_equal(world.get("physical_seam_plan_sha256"), PHYSICAL_SEAM_PLAN_SHA): return false
	if not _number(world.get("seam_static_witness_count"),1344) or not _number(world.get("seam_actual_input_count"),112): return false
	if not _number(world.get("original_raster_witness_count"),1344) or not _number(world.get("original_source_collision_negative_count"),94) or not _true(world.get("old_ROOT330_94_failures_preserved")) or not _false(world.get("all1344_seam_witnesses_normal_input_executed")): return false
	var expected: Dictionary = _seam_id_map(plan.get("seams"),112)
	var original: Dictionary = _seam_id_map(selection.get("seams"),112)
	if expected.size() != 112 or original.size() != 112: return false
	var raster: Variant = world.get("original_raster_seam_records")
	var classifications: Variant = world.get("original_raw_seam_classifications")
	var negatives: Variant = world.get("original_source_collision_negative_records")
	var rows: Variant = world.get("static_seam_records")
	var inputs: Variant = world.get("actual_open_seam_input")
	if not raster is Array or raster.size() != 1344 or not classifications is Array or classifications.size() != 1344 or not negatives is Array or negatives.size() != 94 or not rows is Array or rows.size() != 1344 or not inputs is Array or inputs.size() != 112: return false
	var old_denied: Dictionary = {}
	for row: Dictionary in plan.original_source_collision_negatives: old_denied[row.seam_id+"/"+str(int(row.original_witness_index))] = row
	var seen: Dictionary = {}
	for row: Variant in raster:
		if not row is Dictionary or typeof(row.get("seam_id")) != TYPE_STRING or not original.has(row.seam_id) or not _number_index(row.get("witness_index"),12): return false
		var key: String = row.seam_id+"/"+str(int(row.witness_index))
		var witness: Dictionary = original[row.seam_id].projected_witnesses[int(row.witness_index)]
		if seen.has(key) or not _seam_equal(row.get("original_witness"), witness) or not _release_original_raster(row.get("raster_only"), witness, plan.raw_navigation_sha256): return false
		seen[key] = true
	seen.clear()
	for row: Variant in classifications:
		if not row is Dictionary or typeof(row.get("seam_id")) != TYPE_STRING or not original.has(row.seam_id) or not _number_index(row.get("original_witness_index"),12) or not _false(row.get("actual_Physics_pass_claimed")) or not _false(row.get("old_failure_claimed_passed")): return false
		var key: String = row.seam_id+"/"+str(int(row.original_witness_index))
		var proof: Variant = row.get("actual_raw_segment")
		if seen.has(key): return false
		if old_denied.has(key):
			if not _seam_equal(proof, old_denied[key].actual_segment_evidence): return false
		elif not _seam_equal(proof, {"clear":true,"centers":3,"max_step_px":4}): return false
		seen[key] = true
	seen.clear()
	for row: Variant in negatives:
		if not row is Dictionary or typeof(row.get("seam_id")) != TYPE_STRING or not _number_index(row.get("original_witness_index"),12): return false
		var key: String = row.seam_id+"/"+str(int(row.original_witness_index))
		if seen.has(key) or not old_denied.has(key): return false
		var frozen: Dictionary = old_denied[key]
		for field: String in frozen:
			if not _seam_equal(row.get(field), frozen[field]): return false
		if not _seam_equal(row.get("actual_raw_denial"), frozen.actual_segment_evidence) or not _release_blocked_shoe(row.get("blocked_shoe_Physics"), frozen, source): return false
		seen[key] = true
	seen.clear()
	for row: Variant in rows:
		if not row is Dictionary or typeof(row.get("id")) != TYPE_STRING or not expected.has(row.id) or not _number_index(row.get("witness_index"),12): return false
		var index: int = int(row.witness_index)
		var key: String = row.id+"/"+str(index)
		var witness: Dictionary = expected[row.id].physical_witnesses[index]
		if seen.has(key) or not _number(row.get("candidate_index"),witness.candidate_index) or not _number(row.get("selected_legal_rank"),expected[row.id].selected_legal_ranks[index]) or not _seam_equal(row.get("from_px"),witness.from_px) or not _seam_equal(row.get("to_px"),witness.to_px) or not _false(row.get("normal_input_executed")): return false
		if not _seam_equal(row.get("full17_actual_physics"), {"clear":true,"centers":3,"max_step_px":4}): return false
		var centers: Variant = row.get("three_center_proofs")
		if not centers is Array or centers.size() != 3: return false
		for ci in 3:
			var center: Variant = centers[ci]
			var point: Variant = witness.all_three_full17_centers[ci].center
			if not center is Dictionary or not _seam_equal(center.get("center_px"),point) or not _true(center.get("actual_Physics_clear")) or not _seam_equal(center.get("raw_full17"), {"clear":true,"kind":"full17","center":point}): return false
		seen[key] = true
	var driven: Dictionary = {}
	for row: Variant in inputs:
		if not row is Dictionary or typeof(row.get("id")) != TYPE_STRING or not expected.has(row.id) or driven.has(row.id) or not _number(row.get("witness_index"),0) or not _true(row.get("ok")): return false
		var witness: Dictionary = expected[row.id].physical_witnesses[0]
		if not _seam_equal(row.get("physical_seam_plan_sha256"), PHYSICAL_SEAM_PLAN_SHA) or not _number(row.get("candidate_index"),witness.candidate_index): return false
		var segments: Variant = row.get("segments")
		if not segments is Array or segments.size() != 1 or not segments[0] is Dictionary: return false
		var segment: Dictionary = segments[0]
		if not _true(segment.get("ok")) or not _true(segment.get("reached")) or not _true(segment.get("all_recorded_feet_clear")) or not _positive_integer(segment.get("physics_samples")) or not _seam_pair(segment.get("start")) or not _seam_pair(segment.get("actual_end")) or not _seam_equal(segment.get("target"),witness.to_px): return false
		# Existing fixture (.02) and driver (.3) contracts, not new tolerances.
		if _seam_point(segment.start).distance_to(_seam_point(witness.from_px)) >= .02 or _seam_point(segment.actual_end).distance_to(_seam_point(witness.to_px)) > .3: return false
		driven[row.id] = true
	return _exact_ids(driven.keys(), expected.keys())

static func _release_original_raster(value: Variant, witness: Dictionary, raw_pins: Dictionary) -> bool:
	if not value is Dictionary or not _true(value.get("clear")) or not _seam_equal(value.get("scope"), "ORIGINAL_CAPTURED_RASTER_ONLY_NOT_SOURCE_SOLID_OR_PHYSICS_PASS") or not _number(value.get("max_step_px"),4): return false
	for key: String in ["normal_input_executed","source_solids_pass_claimed","actual_Physics_pass_claimed"]:
		if not _false(value.get(key)): return false
	var centers: Variant = value.get("centers")
	if not centers is Array or centers.size() != 3: return false
	for ci in 3:
		var center: Vector2 = _seam_point(witness.from_px).lerp(_seam_point(witness.to_px),float(ci)/2.)
		var row: Variant = centers[ci]
		if not row is Dictionary or not _seam_equal(row.get("center_px"),_seam_native_pair(center)) or not row.get("all17_raw_pixels") is Array or row.all17_raw_pixels.size() != 17: return false
		for si in 17:
			if not _seam_raw_pixel(row.all17_raw_pixels[si],_seam_shoe(center,si),raw_pins,true): return false
	return true

static func _release_blocked_shoe(value: Variant, frozen: Dictionary, source: Dictionary) -> bool:
	if not value is Dictionary or not _seam_equal(value.get("query_kind"), "ACTUAL_POINT_AT_ORIGINAL_BLOCKED_SHOE") or not _seam_equal(value.get("query_point_px"),frozen.point) or not _true(value.get("own_rid_hit")) or not _false(value.get("player_center_collision_claimed")) or not _true(value.get("player_was_not_moved")): return false
	var body: Variant = value.get("actual_body")
	if not body is Dictionary or not _seam_equal(body.get("id"), frozen.id) or typeof(body.get("path")) != TYPE_STRING or not _positive_integer(body.get("rid")) or not _seam_equal(value.get("expected_own_rid"),body.rid) or not _seam_equal(value.get("expected_body_path"), body.path) or not _seam_equal(value.get("source_kind"), body.get("source_collision_kind")): return false
	# RID association is local to this exact Field/query. Later inventory Fields
	# legitimately allocate new RIDs, so only source object identity crosses runs.
	var kind: Variant = body.get("source_collision_kind")
	if not _seam_equal(kind, "visual_objects") and not _seam_equal(kind, "blockers"): return false
	var name: String = ("ObjectCollision_" if kind == "visual_objects" else "Collision_") + String(frozen.id)
	if not body.path.begins_with("/root/") or body.path.get_file() != name: return false
	var objects: Dictionary = _seam_id_map(source.get("objects"),2687)
	if not objects.has(frozen.id) or not _true(objects[frozen.id].get("blocking")): return false
	var hits: Variant = value.get("hits")
	if not hits is Array or hits.is_empty(): return false
	var matched: int = 0
	for hit: Variant in hits:
		if not hit is Dictionary or not _positive_integer(hit.get("rid")) or typeof(hit.get("path")) != TYPE_STRING or typeof(hit.get("own_object_rid")) != TYPE_BOOL: return false
		var own: bool = _seam_equal(hit.rid,body.rid) and hit.path == body.path
		if hit.own_object_rid != own: return false
		if own: matched += 1
	return matched > 0

static func _number_index(value: Variant, count: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floor(float(value)) and float(value) >= 0 and float(value) < count

static func _release_city(city: Dictionary, coverage: Variant, current: Dictionary, fresh_start: bool = false) -> bool:
	if fresh_start and (not _fresh_metadata_fields(city) or city.get("scope") != FRESH_START_SCOPE): return false
	if not _true(city.get("source_complete")) or not _true(city.get("ordinary_Field_executed")) or not _true(city.get("normal_gameplay")) or not _false(city.get("dry_run")) or not city.get("records") is Dictionary: return false
	var records: Dictionary = city.records
	if not records.get("regions") is Array or records.regions.size() != 4 or not records.get("npcs") is Array or records.npcs.size() != 30 or not records.get("interactions") is Array or records.interactions.size() != 22 or not records.get("portals") is Array or records.portals.size() != 24: return false
	var seen_regions: Array = []
	var all_objects := 0
	var all_routes := 0
	for row: Variant in records.regions:
		if not row is Dictionary or not row.get("id") is String or row.id not in CITY.LEGACY_SHAS or row.id in seen_regions or not row.get("physical_and_current_alpha") is Dictionary: return false
		var actual: Variant = row.physical_and_current_alpha.get("objects")
		var manifest_path: String = CITY.ROOT + row.id + "/art_contract.json"
		var declared: Variant = WORLD.read_json(manifest_path).get("objects")
		if row.get("manifest_sha256") != current.get(manifest_path) or not actual is Array or not declared is Array: return false
		var expected_ids: Array = []
		for object: Variant in declared:
			if not object is Dictionary or not object.get("id") is String: return false
			expected_ids.append(object.id)
		var actual_ids: Array = []
		for object: Variant in actual:
			if not object is Dictionary or not object.get("id") is String or not object.get("collision") is Dictionary or not object.get("alpha") is Dictionary: return false
			actual_ids.append(object.id)
		if not _exact_ids(actual_ids, expected_ids): return false
		var routes: Variant = row.physical_and_current_alpha.get("routes")
		if not routes is Array: return false
		for route: Variant in routes:
			if not route is Dictionary or not route.get("approach") is Dictionary or not _true(route.approach.get("ok")) or not route.get("drive") is Dictionary or not _true(route.drive.get("ok")): return false
		all_routes += routes.size()
		all_objects += actual.size()
		seen_regions.append(row.id)
	if all_objects != 74 or all_routes != 20 or not _exact_ids(seen_regions, CITY.LEGACY_SHAS.keys()): return false
	var negatives: Variant = records.get("interaction_negatives")
	var migration: Variant = records.get("migration")
	if not negatives is Dictionary or not _true(negatives.get("complete")) or not _number(negatives.get("failures"), 0) or not negatives.get("records") is Array or negatives.records.size() != 55: return false
	if fresh_start:
		if not _historical_not_executed(migration): return false
	else:
		if not migration is Dictionary or not _true(migration.get("complete")) or not _number(migration.get("failures"), 0) or not migration.get("records") is Array or migration.records.size() != 80: return false
		var unknown_local := 0
		var native_repeat := 0
		for row: Variant in migration.records:
			if not row is Dictionary: return false
			if String(row.get("case", "")).begins_with("unsupported_"):
				if not _false(row.get("loaded")) or not _true(row.get("zero_mutation")): return false
				unknown_local += 1
			elif String(row.get("case", "")).begins_with("native_repeat_"): native_repeat += 1
		if unknown_local != 20 or native_repeat != 12: return false
	var bgm: Variant = records.get("release_natural48_bgm")
	if not bgm is Dictionary or not _true(bgm.get("passed")) or not _number(bgm.get("normal_clock_scale"), 1) or not _positive_integer(bgm.get("natural_process_frames")) or not bgm.get("started") is Dictionary or not _true(bgm.started.get("ok")): return false
	if not _true(bgm.get("old_field_live_during_natural_grace")) or bgm.get("normal_portal_source") != "ch4_s0_luoyang_gate/enter_luoyang/space" or not _false(bgm.get("time_scale_changed")) or not _false(bgm.get("audio_seeked")) or not _false(bgm.get("timer_cancelled")): return false
	if not _positive(bgm.get("natural_start_ticks_usec")) or not _positive(bgm.get("natural_end_ticks_usec")) or float(bgm.natural_end_ticks_usec) - float(bgm.natural_start_ticks_usec) < 48000000: return false
	var observed: Variant = bgm.get("observed")
	if not observed is Dictionary or not _true(observed.get("ok")) or not _true(observed.get("exact_identity")) or not _true(observed.get("all_observed_states_playing_unpaused_no_pending_stop")) or not _true(observed.get("modulo_elapsed_progress")) or not _true(observed.get("source_bytes_unchanged")) or not _number(observed.get("bgm_changed_count"), 0) or not _positive(observed.get("elapsed_sec")) or float(observed.elapsed_sec) < 48: return false
	if not observed.get("samples") is Array or observed.samples.size() < 2 or not observed.get("source_sha256_before") is Dictionary or observed.source_sha256_before.is_empty() or observed.get("source_sha256_after") != observed.source_sha256_before: return false
	var first: Variant = observed.samples[0]
	if not first is Dictionary or not _positive(first.get("mix_rate_hz")) or typeof(first.get("loop_end_frame")) not in [TYPE_INT, TYPE_FLOAT] or typeof(first.get("loop_begin_frame")) not in [TYPE_INT, TYPE_FLOAT]: return false
	if not _number((float(first.loop_end_frame) - float(first.loop_begin_frame)) / float(first.mix_rate_hz), 48): return false
	for sample: Variant in observed.samples:
		if not sample is Dictionary or not _true(sample.get("valid")) or not _number(sample.get("pitch_scale"), 1) or not _number(sample.get("global_speed_scale"), 1): return false
	for path: Variant in observed.source_sha256_before:
		if not path is String or not _hash(observed.source_sha256_before[path]) or current.get(path) != observed.source_sha256_before[path]: return false
	if not coverage is Dictionary or not coverage.get("clock") is Dictionary or not _true(coverage.clock.get("complete")) or not _number(coverage.clock.get("time_scale"), 1) or not _true(coverage.clock.get("bgm_natural48_complete")): return false
	return true

static func _clean_actual_log(path: String) -> bool:
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		var text: String = line.strip_edges()
		if text.begins_with("ERROR:") or text.begins_with("SCRIPT ERROR:") or text.begins_with("Parse Error:") or text.begins_with("SHADER ERROR:"): return false
	return true

static func _positive(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) > 0

static func _positive_integer(value: Variant) -> bool:
	return _positive(value) and float(value) == floor(float(value))

static func _actor_frame_dependencies(result: Dictionary) -> bool:
	# Player switches weapon/direction dynamically; literal resource closure
	# cannot find these paths. Bind every permitted current full-frame family.
	for weapon: String in ["sword", "dao", "staff", "palm", "hidden"]:
		for state: String in ["idle", "walk"]:
			for direction: String in ["down", "up", "left", "right"]:
				var count: int = 4 if state == "idle" else 8
				var path: String = "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/%s/lengguyun_%s_%s_%s_25d_%df.png" % [weapon, weapon, state, direction, count]
				if not _append(result, path): return false
	var catalog: NPCCatalog = ResourceLoader.load("res://data/npcs/npc_catalog.tres") as NPCCatalog
	if catalog == null or not _append(result, "res://data/npcs/npc_catalog.tres"): return false
	for id: String in CITY.LEGACY_SHAS:
		var scene: SceneScript = CITY.legacy_scene(StringName(id))
		if scene == null: return false
		for npc: Dictionary in scene.npcs:
			var paths: Array = [String(npc.get("sprite_path", "")), String(npc.get("walk_sprite_path", ""))]
			var conversations: Variant = npc.get("conversation_sprite_paths", {})
			if conversations is Dictionary: paths.append_array(conversations.values())
			var profile: NPCProfile = catalog.find(StringName(npc.npc_id), scene.scene_id)
			if profile != null: paths.append_array([profile.sprite_path, profile.walk_sprite_path])
			for path: String in paths:
				if path.is_empty(): continue
				if not _append(result, path): return false
				# Exact same permitted direction/state/version fallbacks as NPCNode.
				for old_direction: String in ["down", "up", "left", "right"]:
					if not path.contains("_" + old_direction + "_"): continue
					for direction: String in ["down", "up", "left", "right"]:
						var directional: String = path.replace("_" + old_direction + "_", "_" + direction + "_")
						var variants: Array[String] = [directional]
						for version in range(2, 10): variants.append(directional.replace("_v%d_" % version, "_"))
						for variant_path: String in variants:
							for state: String in ["idle", "walk"]:
								var candidate: String = variant_path.replace("_idle_", "_" + state + "_").replace("_walk_", "_" + state + "_")
								if FileAccess.file_exists(candidate) and not _append(result, candidate): return false
	return true

static func matches_snapshot(value: Variant, actual: Dictionary) -> bool:
	if not value is Dictionary or value.size() != actual.size(): return false
	for path: String in actual:
		if not _hash(value.get(path)) or String(value[path]).to_lower() != actual[path]: return false
	return true

static func _exact_ids(value: Variant, expected: Array) -> bool:
	if not value is Array or value.size() != expected.size(): return false
	var found: Array = []
	for id: Variant in value:
		if id not in expected or id in found: return false
		found.append(id)
	return true

static func _bound_evidence(value: Dictionary) -> bool:
	var path: Variant = value.get("path")
	return path is String and path.begins_with("res://build/") and not ".." in path and FileAccess.file_exists(path) and _hash(value.get("sha256")) and FileAccess.get_sha256(path).to_lower() == String(value.sha256).to_lower()

static func _append(result: Dictionary, path: String) -> bool:
	if not path.begins_with("res://") or ".." in path or not FileAccess.file_exists(path): return false
	# Per-result only: repeated graph edges retain the first actual SHA. Every
	# catalog still compares its own expected digest, and the final pass rereads
	# all unique files. Never share this memo across snapshot calls.
	if result.has(path): return _hash(result[path])
	var sha: String = FileAccess.get_sha256(path).to_lower()
	if not _hash(sha): return false
	result[path] = sha
	return true

static func _snapshot_bytes_unchanged(result: Dictionary) -> bool:
	# Do not overwrite the first values: a changed/deleted dependency must reject
	# the complete snapshot, including files discovered late by actor fallbacks.
	for path: String in result:
		if not path.begins_with("res://") or ".." in path or not FileAccess.file_exists(path) or not _hash(result[path]): return false
		if FileAccess.get_sha256(path).to_lower() != String(result[path]).to_lower(): return false
	return true

static func _catalog(result: Dictionary, value: Variant) -> bool:
	if not value is Dictionary or value.is_empty(): return false
	for path: Variant in value:
		if not path is String or not _hash(value[path]) or not _append(result, path) or result[path] != String(value[path]).to_lower(): return false
	return true

static func _data_tree(result: Dictionary, path: String) -> bool:
	var directory: DirAccess = DirAccess.open(path)
	if directory == null: return false
	for name: String in directory.get_files():
		if name.ends_with(".tres") and not _append(result, path.path_join(name)): return false
	for name: String in directory.get_directories():
		if not _data_tree(result, path.path_join(name)): return false
	return true

static func _dependency_tree(result: Dictionary, path: String, visited: Dictionary) -> bool:
	if visited.has(path): return true
	visited[path] = true
	if path.get_extension() not in ["gd", "tscn", "tres", "godot", "gdshader"]: return true
	var regex := RegEx.new()
	if regex.compile("[\"'](res://[^\"']+)[\"']") != OK: return false
	for reference: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path)):
		var dependency: String = reference.get_string(1)
		# These two independent approval documents certify this snapshot; hashing
		# them into it would make their own asset_sha256 bindings circular.
		# The world visual review and every mandatory art/source root remain bound.
		if dependency in [VISUAL_REVIEW, TECHNICAL_REVIEW]: continue
		# Dynamic path templates and intentionally missing negative fixtures are
		# not executable dependencies. Mandatory roots/graphs above remain strict.
		if ".." in dependency or not FileAccess.file_exists(dependency): continue
		if not _append(result, dependency) or not _dependency_tree(result, dependency, visited): return false
	return true

static func _hash(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for character: String in value.to_lower():
		if character not in "0123456789abcdef": return false
	return true

static func _number(value: Variant, expected: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == expected
