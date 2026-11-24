extends SceneTree

## Parse availability only. This never invokes builders, publication or Field.
const PATHS: Array[String] = [
 "res://scripts/dev/luoyang_v3_wall_v5_saved_resource_checker.gd",
 "res://scripts/city/luoyang_layered_v3_wall_v5_candidate_contract.gd",
 "res://scripts/dev/publish_luoyang_v3_wall_v5_candidate.gd",
 "res://scripts/city/luoyang_layered_v3_contract.gd",
 "res://tests/helpers/joint_v15_wall_v5_ordinary_raw_oracle.gd",
 "res://tests/helpers/joint_v15_wall_v5_city_migration_load_probe.gd",
 "res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd",
 "res://tests/helpers/joint_v15_wall_v5_fine_alpha_probe.gd",
 "res://tests/helpers/joint_v15_v8_city_prepared_phase.gd",
 "res://tests/helpers/joint_v15_v8_city_gameplay_lifecycle_grace_phase.gd",
 "res://tests/helpers/joint_v15_v8_source_context_oracle.gd",
 "res://tests/helpers/joint_v15_v8_world_prepared_phase.gd",
 "res://tests/test_joint_v15_city_wall_v5_fine_geometry_limited_20261004.gd",
 "res://tests/test_joint_world_luoyang_v15_v8_full_20261004.gd",
 "res://scripts/dev/joint_world_city_v15_v8_wall_acceptance.gd"
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




