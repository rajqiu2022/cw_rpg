extends SceneTree

## Parse availability only. This never invokes builders, publication or Field.
const PATHS: Array[String] = [
 "res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd",
 "res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd",
 "res://scripts/dev/world_map_v15_complete_v8_rich_ecology_candidate.gd",
 "res://scripts/dev/world_map_v15_complete_v8_rich_surface_candidate.gd",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v8_regional_proposal.gd",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v8_full_proposal.gd",
 "res://scripts/dev/world_map_v15_complete_v8_publication_gate.gd",
 "res://scripts/world/world_map_v15_complete_v8_candidate_contract.gd"
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


