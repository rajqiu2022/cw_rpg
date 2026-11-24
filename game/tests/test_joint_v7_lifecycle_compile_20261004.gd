extends SceneTree

const PATHS := [
 "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v7_regional_proposal.gd",
 "res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd",
 "res://scripts/dev/world_map_v15_complete_v7_surface_proposal.gd",
 "res://scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd",
 "res://scripts/field/field_walkable_controller.gd",
 "res://tests/helpers/joint_v15_city_physical_alpha_probe.gd",
 "res://tests/helpers/joint_v15_city_prepared_phase.gd",
 "res://tests/helpers/joint_v15_looped_bgm_continuity.gd"
]

func _initialize() -> void:
 call_deferred("_run")

func _run() -> void:
 var failures: Array = []
 for path: String in PATHS:
  var script := load(path) as GDScript
  if script == null or not script.can_instantiate(): failures.append(path)
  print("SOURCE_COMPILE ", path, " ", script != null and script.can_instantiate())
 print("JOINT_V7_LIFECYCLE_COMPILE failures=", failures)
 quit(0 if failures.is_empty() else 1)
