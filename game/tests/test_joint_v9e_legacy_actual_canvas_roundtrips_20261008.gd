extends SceneTree
## LIMITED nine actual original normal-input roundtrips, NOT filtered RELEASE.
## Original ROOT353/354 failures are immutable. No router return shortcut,
## authored landing/collision changes, planner override or new thresholds.
const OLD_DIAG=preload("res://tests/test_joint_v9e_portal_arrival_return_diagnostic_20261008.gd")
const RAW=preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const CONTEXT=preload("res://tests/helpers/joint_v15_v9e_source_context_oracle.gd")
const ACTUAL: String="res://build/joint_world_luoyang_20261003_qa/portal_arrival_return_diagnostic_1791435678_805337396_35724/diagnostic.json"
const ACTUAL_SHA: String="e11a8629d1c228815cbf726bc99dee73aeaffdf880e0d407abd7ab5c06eeb1d0"
const ADAPTER_PATH: String="res://tests/helpers/joint_v15_release_world_prepared_phase.gd"
const ADAPTER_SHA: String="766f13443af68510914555211778e88bee6b53ac81328dad1576386dfc8b2a3e"
const FROZEN: String=OLD_DIAG.FROZEN
const IDS: Array[String]=["yanmen_pass","gufeng","lingyue"]
const MODES: Array[String]=["space","door_mouse","arrow"]

class ObservedDriver extends "res://tests/helpers/v15_input_driver.gd":
 var follows: Array[Dictionary]=[]
 var pointers: Array[Dictionary]=[]
 var keys: Array[Dictionary]=[]
 func follow(field: Node,points: PackedVector2Array,independent_clear: Callable,independent_segment: Callable) -> Dictionary:
  var id: String=String((field.get("_current_scene") as SceneScript).scene_id)
  var result: Dictionary=await super.follow(field,points,independent_clear,independent_segment)
  var p: Array=[]
  for point: Vector2 in points: p.append([point.x,point.y])
  follows.append({"scene_id":id,"points":p,"result":result.duplicate(true)})
  return result
 func pointer(point: Vector2) -> Dictionary:
  var result: Dictionary=await super.pointer(point)
  pointers.append(result.duplicate(true))
  return result
 func key(code: Key) -> void:
  await super.key(code)
  keys.append({"code":code})

class ObservedPhase extends "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":
 var attempts: Array[Dictionary]=[]
 var active: Dictionary={}
 var consumed: Dictionary={}
 var labels: Array[String]=[]
 func _check(ok: bool,label: String) -> void:
  if not ok: labels.append(label)
  super._check(ok,label)
 func _point_proof(point: Vector2) -> Dictionary:
  var player: Node2D=field.get("_player") as Node2D
  var container: Node2D=field.get("world_container") as Node2D
  var offset: Vector2=container.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y"))))-player.position
  return {"root_px":[point.x,point.y],"offset_px":[offset.x,offset.y],"mapped17":_release_legacy_foot_evidence(ordinary_raw,release_legacy_source_size,release_legacy_actual_size,point,offset),"actual_Physics_clear":_physical_clear(point),"actual_combined_clear":_ordinary_clear(point)}
 func _configure_ordinary(definition: SceneScript) -> bool:
  var ok: bool=super._configure_ordinary(definition)
  if ok:
   for layer: Dictionary in ordinary_raw.get("layers"): consumed[layer.path]=layer.sha256
   var player: Node2D=field.get("_player") as Node2D
   active["arrival"]={"definition_path":definition.resource_path,"actual_size":[ordinary_size.x,ordinary_size.y],"source_size":[release_legacy_source_size.x,release_legacy_source_size.y],"actor_positions_are_feet":definition.actor_positions_are_feet,"point":_point_proof(player.position)}
  return ok
 func _actual_return(destination: StringName) -> bool:
  var reverse: Area2D
  for zone: Node2D in field.get("_exit_nodes"):
   if String(zone.get("target_scene_id")) in [String(scene_id),"world_map_jianghu"] or String(zone.get("action"))=="world_map": reverse=zone as Area2D; break
  var candidates: Array=[]
  if reverse!=null:
   for radius in [0,16,32,48,64]:
    for direction in 16:
     var point: Vector2=reverse.position+Vector2(cos(TAU*direction/16),sin(TAU*direction/16))*radius
     var proof: Dictionary=_point_proof(point)
     proof["radius"]=radius; proof["direction"]=direction
     proof["actual_foot_and_body_contains"]=_area_contains_actual_foot_and_body(reverse,point)
     candidates.append(proof)
  active["all80_original_candidates"]=candidates
  var driver: RefCounted=input_driver
  var before_follows: int=(driver.get("follows") as Array).size()
  var before_pointers: int=(driver.get("pointers") as Array).size()
  # Entire actual return, planner and input implementation stays inherited.
  var returned: bool=await super._actual_return(destination)
  active["actual_returned"]=returned
  var follow_rows: Array=driver.get("follows")
  var pointer_rows: Array=driver.get("pointers")
  active["original_return_follow"]=follow_rows.slice(before_follows).duplicate(true)
  active["original_return_pointer"]=pointer_rows.slice(before_pointers).duplicate(true)
  return returned
 func _portal_roundtrip(id: String,mode: String,measurement: Dictionary) -> void:
  active={"id":id,"mode":mode,"start_failures":failures}
  var driver: RefCounted=input_driver
  var k: int=(driver.get("keys") as Array).size()
  var p: int=(driver.get("pointers") as Array).size()
  await super._portal_roundtrip(id,mode,measurement)
  active["failure_delta"]=failures-int(active.start_failures)
  active["actual_keys"]=(driver.get("keys") as Array).slice(k).duplicate(true)
  active["actual_pointers"]=(driver.get("pointers") as Array).slice(p).duplicate(true)
  attempts.append(active.duplicate(true))
  _check(_write_json("roundtrip_%02d_%s_%s.json"%[attempts.size(),id,mode],active),"unique limited actual roundtrip checked readback")
  print("LEGACY_ACTUAL_ROUNDTRIP ",JSON.stringify({"id":id,"mode":mode,"failure_delta":active.failure_delta,"actual_returned":active.get("actual_returned",false),"output":output}))

var checks: int=0
var errors: Array[String]=[]
var phase: ObservedPhase
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok: errors.append(label); push_error("[LEGACY ROUNDTRIP] "+label)
 return ok
func _read(path: String) -> Dictionary:
 var j:=JSON.new()
 return j.data if j.parse(FileAccess.get_file_as_string(path))==OK and j.data is Dictionary else {}
func _file(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {"exists":false}
 var f:=FileAccess.open(path,FileAccess.READ)
 if f==null: return {"exists":true,"readable":false}
 var n: int=f.get_length(); f.close()
 return {"exists":true,"bytes":n,"sha256":FileAccess.get_sha256(path),"mtime":FileAccess.get_modified_time(path)}
func _snapshot(paths: Dictionary,endpoint_cache: Dictionary={}) -> Dictionary:
 var r: Dictionary={}
 for p: String in paths: r[p]=endpoint_cache[p] if endpoint_cache.has(p) else _file(p)
 return r
func _players() -> Dictionary:
 var r: Dictionary={}
 for slot in 5:
  for suffix: String in ["",".bak",".tmp"]:
   var p: String="user://save_%d.json%s"%[slot,suffix]; r[p]=_file(p)
 return r
func _env() -> Dictionary:
 return {"driver":AudioServer.get_driver_name(),"exe_sha256":FileAccess.get_sha256(OS.get_executable_path()),"display":DisplayServer.get_name(),"mix_rate":AudioServer.get_mix_rate(),"device":AudioServer.output_device,"latency":AudioServer.get_output_latency(),"source_version_equivalence":false}
func _run() -> void:
 _check(OS.get_cmdline_user_args()==PackedStringArray(["--candidate-before-cutover"]),"explicit limited regression, no filtered RELEASE request")
 var env0: Dictionary=_env()
 _check(env0.driver=="WASAPI" and env0.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen executable/1x start")
 var actual_endpoint: Dictionary=_file(ACTUAL)
 _check(actual_endpoint.get("sha256")==ACTUAL_SHA,"fixed complete ROOT354 original evidence")
 var baseline: Dictionary=_read(ACTUAL)
 _check(baseline.get("original_phase_failures")==15 and baseline.get("diagnostic_failures")==0,"all original failures retained, no retroactive approval")
 # Expected hashes bind provenance; actual hashes are freshly computed ONCE
 # per unique path per endpoint, never borrowed from the old evidence.
 var expected: Dictionary=OLD_DIAG.PINS.duplicate(true)
 for p: String in baseline.get("source_before",{}):
  var row: Dictionary=baseline.source_before[p]
  if row.get("exists")==true: expected[p]=row.sha256
 expected[ADAPTER_PATH]=ADAPTER_SHA
 expected[ACTUAL]=ACTUAL_SHA
 var paths: Dictionary=expected.duplicate(true)
 paths[get_script().resource_path]="SELF_CURRENT_BYTES"
 var before: Dictionary=_snapshot(paths,{ACTUAL:actual_endpoint})
 for p: String in expected: _check(before[p].get("sha256")==expected[p],"fresh unique actual fixed input "+p)
 var players0: Dictionary=_players(); var slot0: Variant=root.get_node("SaveManager").get("active_slot")
 if not errors.is_empty(): quit(1); return
 var frozen: Dictionary=_read(FROZEN)
 var source: Dictionary=_read(OLD_DIAG.SOURCE)
 var manifest: Dictionary=_read(OLD_DIAG.MANIFEST)
 var context: RefCounted=CONTEXT.new()
 _check(context.call("validate_v9c_world_pins",frozen.get("execution_sha256",{}),frozen.get("v9c_artifact_sha256",{}),manifest,frozen.get("derived_geometry_inputs",{}))==true,"all original frozen source pins/derived bindings")
 context=null
 var world: SceneScript=load(OLD_DIAG.WORLD)
 _check(world!=null and world.map_layout!=null and world.map_layout.walkable_mask_tiles.size()==64,"actual candidate complete64nav layout")
 if not errors.is_empty(): quit(1); return
 var output: String="res://build/joint_world_luoyang_20261003_qa/legacy_actual_canvas_roundtrips_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"new unique evidence directory")
 if not errors.is_empty(): quit(1); return
 phase=ObservedPhase.new(); phase.owner_tree=self; phase.output=output; phase.requested_phase="LIMITED_NINE_LEGACY_ROUNDTRIPS_NOT_RELEASE"
 phase.before_saves=phase.call("_actual_saves"); phase.prior_navigation=root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
 phase.prior_active=StringName(root.get_node("SceneRouter").get("_active_world_map_scene")); phase.prior_slot=int(slot0)
 phase.source=source; phase.manifest=manifest; phase.world=world
 phase.execution_sha256=frozen.execution_sha256.duplicate(true); phase.v9c_artifact_sha256=frozen.v9c_artifact_sha256.duplicate(true); phase.derived_geometry_inputs=frozen.derived_geometry_inputs.duplicate(true)
 phase.oracle=RAW.new()
 _check(phase.oracle.call("configure",world.map_layout)==true,"actual64nav independent full17/source-solids oracle")
 phase.call("_read_independent_door_review")
 var ready: bool=errors.is_empty() and phase.failures==0
 if ready:
  phase.call("_ensure_runtime_fixture")
  phase.input_driver.call("release")
  phase.input_driver=ObservedDriver.new(); phase.input_driver.call("configure",self)
  ready=phase.failures==0
 if ready:
  for id: String in IDS:
   var measurement: Dictionary=phase.call("_source_door",id)
   if measurement.is_empty(): _check(false,"actual SHA-bound source door "+id); continue
   for mode: String in MODES: await phase._portal_roundtrip(id,mode,measurement)
 _check(phase.attempts.size()==9 and phase.actual_portal_roundtrips.size()==9 and phase.failures==0,"all nine real paired returns with original assertions, not merely arrival/diagnosis")
 for attempt: Dictionary in phase.attempts:
  _check(attempt.get("failure_delta")==0 and attempt.get("actual_returned")==true,"original normal input return succeeds "+str(attempt.id)+"/"+str(attempt.mode))
  _check(attempt.get("all80_original_candidates",[]).size()==80 and attempt.get("original_return_follow",[]).size()==1 and attempt.get("original_return_pointer",[]).size()==1,"all80 fixed candidates and actual inherited follow/arrow return evidence")
  if not attempt.has("arrival"): _check(false,"actual arrival recorded"); continue
  _check(attempt.arrival.actual_size==[1920.,1280.] and attempt.arrival.source_size==[1536.,1024.] and attempt.arrival.point.actual_combined_clear==true,"real actual/source canvas distinction and mapped17+Physics arrival")
  var eligible: int=0; var denied: int=0
  for proof: Dictionary in attempt.get("all80_original_candidates",[]):
   if proof.actual_combined_clear and proof.actual_foot_and_body_contains: eligible+=1
   if not proof.actual_Physics_clear: denied+=1
  _check(eligible=={"yanmen_pass":74,"gufeng":52,"lingyue":28}[attempt.id] and denied==(15 if attempt.id=="gufeng" else 0),"fixed80 mapped eligibility and all original real Physics denials retained")
  _check((attempt.actual_keys.size()==1 and attempt.actual_keys[0].code==KEY_SPACE) if attempt.mode=="space" else attempt.actual_keys.is_empty(),"original Space key only in Space mode")
  _check(attempt.actual_pointers.size()==(1 if attempt.mode=="space" else 2),"actual entry pointer and public return arrow events, no direct router return")
 var attempts: Array=phase.attempts.duplicate(true)
 var trips: Array=phase.actual_portal_roundtrips.duplicate(true)
 var labels: Array=phase.labels.duplicate()
 for p: String in phase.consumed: _check(before.has(p) and before[p].get("sha256")==phase.consumed[p],"consumed local nav present in fresh pre-Field snapshot "+p)
 await phase.call("_finish")
 _check(phase.failures==0 and phase.result.get("release_complete")==false and phase.result.get("source_complete")==false,"full original normal cleanup, limited regression never RELEASE")
 var after: Dictionary=_snapshot(paths); var env1: Dictionary=_env()
 _check(after==before and _players()==players0 and root.get_node("SaveManager").get("active_slot")==slot0,"all unique consumed source bytes/SHA/mtime and15 player files/slot unchanged")
 _check(env1.driver=="WASAPI" and env1.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen executable/1x finish")
 var report: Dictionary={"schema":1,"scope":"LIMITED_NINE_REAL_LEGACY_ORIGINAL_INPUT_ROUNDTRIPS_NOT_RELEASE","checks":checks,"failures":errors.size(),"errors":errors,"phase_failures":phase.failures,"phase_failure_labels":labels,"attempts":attempts,"original_roundtrips":trips,"unique_source_count":paths.size(),"source_before":before,"source_after":after,"players_before":players0,"players_after":_players(),"environment_before":env0,"environment_after":env1,"preserved_ROOT354_path":ACTUAL,"preserved_ROOT354_sha256":ACTUAL_SHA,"preserved_ROOT354_failures":15,"source_complete":false,"release_complete":false,"formal_approval":false,"output":output}
 _check(phase.call("_write_json","limited_roundtrips.json",report)==true,"unique complete limited roundtrip report checked readback")
 print("V9E_LEGACY_ACTUAL_CANVAS_ROUNDTRIPS ",JSON.stringify({"checks":checks,"failures":errors.size(),"phase_failures":phase.failures,"roundtrips":trips.size(),"source_count":paths.size(),"output":output,"release_complete":false}))
 phase=null; world=null
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)
