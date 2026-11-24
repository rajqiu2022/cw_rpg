extends SceneTree

## Parsing/instantiation availability only. Never executes builders or Field.
const PATHS := [
 "res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd",
 "res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v8_regional_proposal.gd",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v8_full_proposal.gd",
 "res://scripts/dev/world_map_v15_complete_v8_publication_gate.gd",
 "res://scripts/dev/luoyang_modular_v3_wall_street_surface_proposal.gd",
 "res://scripts/dev/build_luoyang_modular_v3_wall_street_adapter_proposal.gd",
 "res://scripts/dev/build_luoyang_modular_v3_wall_street_capture_proposal.gd",
 "res://scripts/dev/luoyang_v3_wall_street_saved_resource_checker.gd",
 "res://scripts/city/luoyang_layered_v3_wall_street_candidate_contract.gd",
 "res://scripts/dev/publish_luoyang_v3_wall_street_candidate.gd",
 "res://tests/helpers/joint_v15_wall_street_v7_source_context_oracle.gd",
 "res://tests/helpers/joint_v15_wall_street_ordinary_raw_oracle.gd",
 "res://tests/helpers/joint_v15_wall_street_city_physical_alpha_probe.gd",
 "res://tests/helpers/joint_v15_wall_street_city_migration_load_probe.gd",
 "res://tests/helpers/joint_v15_wall_street_city_prepared_phase.gd",
 "res://tests/helpers/joint_v15_wall_street_city_gameplay_lifecycle_grace_phase.gd",
 "res://tests/helpers/joint_v15_wall_street_world_parent_parsefix_phase.gd",
 "res://tests/helpers/joint_v15_wall_street_v7_world_prepared_phase.gd",
 "res://tests/test_joint_world_luoyang_v15_wall_street_20261004.gd"
]

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var failures: Array=[]
 for path: String in PATHS:
  var script:=load(path) as GDScript
  var ready: bool=script!=null and script.can_instantiate()
  if not ready: failures.append(path)
  print("SOURCE_COMPILE ",path," ",ready," SHA=",FileAccess.get_sha256(path))
 print("JOINT_V8_WALL_SOURCE_COMPILE ",JSON.stringify({"scope":"SOURCE_COMPILE_ONLY_NOT_ART_FIELD_OR_APPROVAL","paths":PATHS.size(),"failures":failures,"builders_executed":false}))
 var until: int=Time.get_ticks_msec()+9000
 while Time.get_ticks_msec()<until: await process_frame
 var audio: Node=root.get_node_or_null("AudioManager")
 if audio!=null: audio.call("stop_bgm",.15)
 await create_timer(.25).timeout
 for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
 quit(0 if failures.is_empty() else 1)
