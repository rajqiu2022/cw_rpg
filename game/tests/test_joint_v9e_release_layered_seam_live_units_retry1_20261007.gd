extends SceneTree
## LIMITED actual normal candidate Field: original raster1344, new fixed1344
## full17/live Player-shape Physics, all94 original blocked-shoe ownRID.
## Retry of preserved ROOT333: only public pre-Field fixture normalization differs.
## No normal crossing input, derived/FULL/RELEASE/visual/approval credit.
const ADAPTER=preload("res://tests/helpers/joint_v15_release_world_prepared_phase.gd")
const RASTER=preload("res://tests/helpers/joint_v15_release_layered_seam_geometry_20261007.gd")
const RAW=preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const PLAN: String="res://build/joint_world_luoyang_20261003_qa/v9e_physical_seam_plan_1791382780_55287449_11796/physical_seam_plan.json"
const PINS: Dictionary={
 "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":"c18e5318956188059991911963e713d7042b037f582d8e95b3f76afc2952b7d5",
 "res://tests/helpers/joint_v15_release_layered_seam_geometry_20261007.gd":"12a8277b1f4847844d8c37c0f041f5f9b21426aa0e03727ebb32aee5a92bd512",
 "res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd":"16a66f74eba277c9dcf7c1a6801bb5183d0fedf363a3e6fc3805bc41e7474970",
 "res://tests/helpers/joint_v15_v9c_world_geometry_phase.gd":"6ee5d11e56fb7d8cffaa2475abe801222cb94e417e2c8c0d4f0dac7586a02333",
 "res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd":"7628d404d7587dfd885937ad1e26ac6a06f4e48ca53c273ccd8d5f1aee5db9db",
 "res://tests/helpers/v15_raw_world_oracle.gd":"c58043373af6154d5f7f79cfa2d0e8dcda38f3fbe0c6648a4af4ce626e8a9c51",
 "res://scripts/autoload/scene_router.gd":"f3ead7459632188350e1e3383ee915c83b71c1b86d36dadf718bd338a4324eca",
 "res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd":"4f4f5584f6320215207d960f8e244cd31ab657806f32e4b8a58c1a77107a63c1",
 "res://scripts/field/field_walkable_controller.gd":"b3301d6064e332e519b0fc3b4daed880ec3d77d98f2c744933b5d7077b9eb8ef",
 "res://data/maps/world_map_v15_complete_v9c_source.json":"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
 "res://art/maps/world_map_v15_complete_v9c/art_contract.json":"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
 "res://data/maps/world_map_jianghu_layout_v15.tres":"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
 "res://data/scenes/world_map_jianghu_v15.tres":"31c5034e44092f146879e45715b97425c6e899e8ef1c375c94f03b2a35fc9065",
 PLAN:"024e9a09f37721e787990ba035416996e75d69518e8d18698fdc9f0a4c1f3bd8"
}
var checks: int=0
var failures: int=0
var phase: RefCounted
var self_sha: String=""
var output: String=""

func _initialize() -> void:
 call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok:
  failures+=1
  push_error("[LAYERED SEAM LIMITED] "+label)
 return ok

func _pins() -> bool:
 var same: bool=true
 for path: String in PINS:
  same=_check(FileAccess.file_exists(path) and FileAccess.get_sha256(path)==PINS[path],"exact actual phase/source/layout/art/plan input SHA: "+path) and same
 return same

func _raw_writer_reason_units(raw: RefCounted) -> void:
 # Three actual ROOT332 points where Float32->Double native differs from its
 # original default JSON writer. Exercise the real narrow reader, not a copy.
 var targets: Dictionary={"r7_c1--r7_c2/8":0,"r7_c1--r7_c2/11":0,"r1_c7--r2_c7/11":1}
 var seen: Dictionary={}
 var plan: Dictionary=phase.get("physical_seam_plan")
 var seams: Dictionary=phase.get("physical_seams_by_id")
 for negative: Dictionary in plan.get("original_source_collision_negatives",[]):
  var key: String=String(negative.seam_id)+"/"+str(int(negative.original_witness_index))
  if not targets.has(key): continue
  var witness: Dictionary=seams[negative.seam_id].original_captured_witnesses[int(negative.original_witness_index)]
  var live: Dictionary=raw.call("segment_evidence",phase.call("_point",witness.from_px),phase.call("_point",witness.to_px))
  var stored: Dictionary=negative.actual_segment_evidence
  var axis: int=targets[key]
  _check(live.point[axis]!=stored.point[axis],"actual native/raw point and original saved15sig are distinct domains: "+key)
  _check(phase.call("_release_raw_reason_matches",stored,live)==true,"real reader accepts actual original writer-once point: "+key)
  for delta: int in [-1,1]:
   var wrong: Dictionary=stored.duplicate(true)
   var bytes: PackedByteArray=PackedFloat64Array([float(wrong.point[axis])]).to_byte_array()
   bytes.encode_u64(0,bytes.decode_u64(0)+delta)
   wrong.point[axis]=bytes.decode_double(0)
   _check(wrong.point[axis]!=stored.point[axis] and phase.call("_release_raw_reason_matches",wrong,live)==false,"untouched saved Double adjacent-bit mutation rejected without re-encoding: "+key+"/"+str(delta))
  seen[key]=true
 _check(seen.size()==3,"all three actual writer-domain boundary regressions and six strict saved-ULP negatives")

func _run() -> void:
 self_sha=FileAccess.get_sha256(get_script().resource_path)
 _check(OS.get_cmdline_user_args()==PackedStringArray(["--candidate-before-cutover"]),"explicit candidate-only limited static/negative test; no phase subset or normal input claim")
 _check(Engine.time_scale==1.0,"ordinary1x physics clocks")
 if not _pins() or failures>0: quit(1); return
 output="res://build/joint_world_luoyang_20261003_qa/limited_layered_seams_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"new unique owned evidence directory")
 if failures>0: quit(1); return
 phase=ADAPTER.new()
 phase.set("owner_tree",self)
 phase.set("requested_phase","limited_layered_seams_static_negative")
 phase.set("output",output)
 phase.set("before_saves",phase.call("_actual_saves"))
 var router: Node=root.get_node("SceneRouter")
 phase.set("prior_navigation",router.call("get_navigation_state").duplicate(true))
 phase.set("prior_active",StringName(router.get("_active_world_map_scene")))
 phase.set("prior_slot",int(root.get_node("SaveManager").get("active_slot")))
 phase.set("source",JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/world_map_v15_complete_v9c_source.json")))
 phase.set("manifest",JSON.parse_string(FileAccess.get_file_as_string("res://art/maps/world_map_v15_complete_v9c/art_contract.json")))
 phase.set("world",load("res://data/scenes/world_map_jianghu_v15.tres"))
 var world: SceneScript=phase.get("world")
 _check(world!=null and world.map_layout!=null and world.map_layout.resource_path=="res://data/maps/world_map_jianghu_layout_v15.tres","actual published candidate external layout, not synthetic world")
 var raw: RefCounted=RAW.new()
 _check(world!=null and raw.call("configure",world.map_layout)==true,"real current64 original nav PNG/source-solids oracle")
 phase.set("oracle",raw)
 var ready: bool=failures==0 and phase.call("_read_physical_seam_plan")==true
 _check(ready,"actual complete fixed ROOT332 plan preflight before Field")
 if ready:
  _raw_writer_reason_units(raw)
  var raster: RefCounted=RASTER.new()
  var old: Array[Dictionary]=[]
  var source: Dictionary=phase.get("source")
  for seam: Dictionary in source.get("seams",[]):
   for wi in seam.get("projected_witnesses",[]).size():
    var witness: Dictionary=seam.projected_witnesses[wi]
    var proof: Dictionary=raster.call("_raster_segment",raw,phase.call("_point",witness.from_px),phase.call("_point",witness.to_px))
    _check(proof.get("clear")==true,"original complete17/three-center raster-only proof: "+str(seam.id)+"/"+str(wi))
    old.append({"seam_id":seam.id,"witness_index":wi,"original_witness":witness.duplicate(true),"raster_only":proof})
  _check(old.size()==1344,"all1344 original raster witnesses, never physical success claim")
  phase.set("original_raster_seam_records",old)
  raster.call("release")
  raster=null
  if failures==0:
   phase.call("_ensure_runtime_fixture")
   _check(int(phase.get("failures"))==0 and (phase.get("fixture_navigation_evidence") as Dictionary).get("valid")==true,"same actual RELEASE adapter establishes public normalized idempotent baseline before Field")
   if failures==0: await phase.call("_release_layered_static_seams")
 _check(int(phase.get("failures"))==0,"real Field all1344 new physical positives/all94 blocked-shoe ownRID assertions, not normal input or FULL")
 _check((phase.get("release_seam_static") as Array).size()==1344 and (phase.get("original_source_collision_negative_records") as Array).size()==94 and (phase.get("original_raw_seam_classifications") as Array).size()==1344,"complete positive/negative/original classification counts, no successful subset")
 _check((phase.get("actual_open_seam_crossings") as Array).is_empty(),"no normal-input representative credit from hypothetical Physics")
 var before_finish_navigation: Dictionary=router.call("get_navigation_state").duplicate(true)
 var fixture_diagnostic: Dictionary=(phase.get("fixture_navigation_evidence") as Dictionary).duplicate(true)
 var expected_baseline: Dictionary=(phase.get("prior_navigation") as Dictionary).duplicate(true)
 await phase.call("_finish")
 var report: Dictionary=phase.get("result")
 _check(report.get("release_complete")==false and report.get("source_complete")==false and int(report.get("failures",1))==0,"natural cleanup and limited report never grants RELEASE/FULL")
 var after_finish_navigation: Dictionary=router.call("get_navigation_state").duplicate(true)
 fixture_diagnostic["navigation_before_finish"]=before_finish_navigation
 fixture_diagnostic["expected_cleanup_baseline"]=expected_baseline
 fixture_diagnostic["actual_navigation_after_finish"]=after_finish_navigation
 fixture_diagnostic["actual_cleanup_navigation_equal"]=after_finish_navigation==expected_baseline
 fixture_diagnostic["source_complete"]=false
 fixture_diagnostic["release_complete"]=false
 _check(after_finish_navigation==expected_baseline,"actual original complete cleanup strict navigation equality retained")
 _check(phase.call("_write_json","limited_fixture_navigation_diagnostic.json",fixture_diagnostic)==true,"raw/normalized/second/before-finish/after-finish actual navigation diagnostics retained")
 _check(FileAccess.get_sha256(get_script().resource_path)==self_sha and _pins(),"all source/art/plan files unchanged after natural cleanup")
 print("V9E_LAYERED_SEAM_LIMITED_ACTUAL ",JSON.stringify({"scope":"LIMITED_ACTUAL_FIELD_NEW1344_PHYSICS_ORIGINAL1344_RASTER_AND94_BLOCKED_SHOE_OWNRID_NOT_FULL","checks":checks,"failures":failures,"phase_checks":report.get("checks"),"phase_failures":report.get("failures"),"fixture_navigation_diagnostic":fixture_diagnostic,"output":output,"physical_seam_plan_path":PLAN,"physical_seam_plan_sha256":PINS[PLAN],"normal_input_executed":false,"source_complete":false,"release_complete":false,"formal_approval":false}))
 phase=null
 world=null
 raw=null
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if failures==0 else 1)



