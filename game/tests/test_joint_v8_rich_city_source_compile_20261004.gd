extends SceneTree

## Parse availability only. This never invokes builders, publication or Field.
const PATHS: Array[String] = [
 "res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd",
 "res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v8_regional_proposal.gd",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v8_full_proposal.gd",
 "res://scripts/dev/world_map_v15_complete_v8_publication_gate.gd",
 "res://scripts/world/world_map_v15_complete_v8_candidate_contract.gd",
 "res://scripts/world/world_map_v15_contract.gd",
 "res://scripts/dev/publish_world_map_v15_complete_v8_candidate.gd",
 "res://scripts/dev/draft_world_v15_v8_whole_review_negatives.gd",
 "res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd",
 "res://scripts/dev/build_luoyang_modular_v3_wall_street_adapter_proposal.gd",
 "res://scripts/dev/build_luoyang_modular_v3_wall_street_capture_proposal.gd",
 "res://scripts/dev/luoyang_v3_wall_street_saved_resource_checker.gd",
 "res://scripts/city/luoyang_layered_v3_wall_street_candidate_contract.gd",
 "res://scripts/city/luoyang_layered_v3_contract.gd",
 "res://scripts/dev/publish_luoyang_v3_wall_street_candidate.gd",
 "res://scripts/dev/joint_world_city_v15_v8_wall_acceptance.gd",
 "res://scripts/dev/activate_joint_world_city_v15_v8_wall.gd",
 "res://tests/helpers/joint_v15_v8_source_context_oracle.gd",
 "res://tests/helpers/joint_v15_v8_world_raw_oracle.gd",
 "res://tests/helpers/joint_v15_v8_world_geometry_phase.gd",
 "res://tests/helpers/joint_v15_v8_world_object_input_probe.gd",
 "res://tests/helpers/joint_v15_v8_overview_input_probe.gd",
 "res://tests/helpers/joint_v15_world_artifact_semantics_v8_probe.gd",
 "res://tests/helpers/joint_v15_v8_plane_caster_semantic_probe.gd",
 "res://tests/helpers/joint_v15_v8_world_prepared_phase.gd",
 "res://tests/helpers/joint_v15_v8_city_prepared_phase.gd",
 "res://tests/helpers/joint_v15_v8_city_gameplay_lifecycle_grace_phase.gd",
 "res://tests/test_joint_world_luoyang_v15_v8_full_20261004.gd",
 "res://scripts/dev/world_map_v15_complete_v8_rich_surface_candidate.gd",
 "res://scripts/dev/world_map_v15_complete_v8_rich_ecology_candidate.gd",
 "res://scripts/dev/build_world_map_v15_v8_rich_regional_candidate.gd",
 "res://tests/test_joint_v15_city_wall_v4_geometry_limited_20261004.gd",
 "res://scripts/dev/luoyang_modular_v3_zone_finish_candidate.gd",
 "res://tests/helpers/joint_v15_wall_v4_fine_alpha_probe.gd",
 "res://tests/helpers/joint_v15_wall_v4_fine_alpha_grace_phase.gd",
 "res://tests/test_joint_v15_city_wall_v4_fine_geometry_limited_20261004.gd",
 "res://scripts/dev/build_luoyang_modular_v3_wall_v5_adapter_candidate.gd",
 "res://scripts/dev/build_luoyang_modular_v3_wall_v5_capture_candidate.gd"
]

func _initialize() -> void:
 _run.call_deferred()

func _run() -> void:
 var failures: Array[String] = []
 for path: String in PATHS:
  var script: GDScript = load(path) as GDScript
  var ready: bool = script != null and script.can_instantiate()
  if not ready: failures.append(path)
  print("SOURCE_COMPILE ",path," ",ready," SHA=",FileAccess.get_sha256(path))
 print("JOINT_V8_RICH_CITY_SOURCE_COMPILE ",JSON.stringify({"scope":"SOURCE_COMPILE_ONLY_NOT_ART_FIELD_OR_APPROVAL","paths":PATHS.size(),"failures":failures,"builders_executed":false,"field_executed":false,"formal_activated":false}))
 var until: int = Time.get_ticks_msec()+9000
 while Time.get_ticks_msec()<until: await process_frame
 var audio: Node = root.get_node_or_null("AudioManager")
 if audio != null: audio.call("stop_bgm",.15)
 await create_timer(.25).timeout
 for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
 quit(0 if failures.is_empty() else 1)
