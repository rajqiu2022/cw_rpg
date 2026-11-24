extends SceneTree
## PURE consumer/schema tests. Synthetic report booleans below are deliberate
## fixtures, NEVER actual Field, Physics, normal-input, visual or RELEASE credit.
const GATE_PATH := "res://scripts/dev/joint_world_city_v15_release_acceptance.gd"
const GATE_SHA := "a86dae792b439ff1c507caf3bd22d820c33357f1f9603bfa8463a7df3699b930"
const OLD_GATE := "res://build/joint_world_luoyang_20261003_qa/330_v9e_candidate_complete_release_headless_native_herb_fix_20261007/joint_world_city_v15_release_acceptance.gd"
const OLD_SHA := "1a3b4e69029528da1c436917df5a923eedc401013d296a0092ff17f5e4639d6e"
const PLAN_PATH := "res://build/joint_world_luoyang_20261003_qa/v9e_physical_seam_plan_1791382780_55287449_11796/physical_seam_plan.json"
const PLAN_SHA := "024e9a09f37721e787990ba035416996e75d69518e8d18698fdc9f0a4c1f3bd8"
const SOURCE := "res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST := "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const SELECTION := "res://build/joint_world_luoyang_20261003_qa/release_selection_root234_20261005_01/representative_selection.json"
const PINS := {
 GATE_PATH:GATE_SHA,OLD_GATE:OLD_SHA,PLAN_PATH:PLAN_SHA,
 SOURCE:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
 MANIFEST:"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
 SELECTION:"34a6ffd4b6da7adfc953c7339e1398c5a77e6f112399e4361350050246c4704f",
 "res://tests/helpers/prepare_joint_v9e_physical_seam_plan_20261007.gd":"fe54500050d844e50ff3681ab44a9db6bdff15112995eae7adb46fee10c746af",
 "res://tests/helpers/joint_v15_release_layered_seam_geometry_20261007.gd":"12a8277b1f4847844d8c37c0f041f5f9b21426aa0e03727ebb32aee5a92bd512",
 "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":"c18e5318956188059991911963e713d7042b037f582d8e95b3f76afc2952b7d5",
 "res://tests/test_joint_v9e_release_layered_seam_live_units_retry1_20261007.gd":"761eed634c99aea148ad7702908d8fe1de8cc099068dda9720088e20ab0bc727"}
var gate: RefCounted
var plan: Dictionary
var source: Dictionary
var selection: Dictionary
var manifest: Dictionary
var fixture: Dictionary
var checks: int=0
var failures: int=0
var records: Array[Dictionary]=[]

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool,label: String) -> void:
 checks+=1
 records.append({"ok":ok,"label":label})
 if not ok:
  failures+=1
  push_error("[LAYERED SEAM PURE] "+label)

func _read(path: String) -> Dictionary:
 var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
 return value if value is Dictionary else {}

func _hashes(paths: Dictionary) -> Dictionary:
 var result: Dictionary={}
 for path: String in paths: result[path]=FileAccess.get_sha256(path).to_lower() if FileAccess.file_exists(path) else "MISSING"
 return result

func _player_files() -> Dictionary:
 var result: Dictionary={}
 for slot in 5:
  for suffix: String in [".json",".json.bak",".json.tmp"]:
   var path: String="user://save_%d"%slot+suffix
   result[path]=FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT"
 var dir: DirAccess=DirAccess.open("user://")
 if dir!=null:
  for file: String in dir.get_files():
   if file.begins_with("save"):
    var path: String="user://"+file
    result[path]=FileAccess.get_sha256(path)
 return result

func _method(text: String,name: String) -> String:
 var start: int=text.find("static func "+name+"(")
 if start<0: return ""
 var finish: int=text.find("\nstatic func ",start+1)
 return text.substr(start,finish-start if finish>=0 else -1).strip_edges()

func _schema_ok() -> bool:
 return String(gate.call("_physical_seam_plan_schema",plan,source,selection)).is_empty()

func _world_ok() -> bool:
 return gate.call("_release_layered_seams",fixture,plan,selection,source)==true

func _mutate_plan(target: Dictionary,key: String,value: Variant,label: String) -> void:
 var existed: bool=target.has(key)
 var before: Variant=target.get(key)
 target[key]=value
 _check(not _schema_ok(),"plan rejects "+label)
 if existed: target[key]=before
 else: target.erase(key)

func _mutate_world(target: Dictionary,key: String,value: Variant,label: String) -> void:
 var existed: bool=target.has(key)
 var before: Variant=target.get(key)
 target[key]=value
 _check(not _world_ok(),"synthetic full layered consumer rejects "+label)
 if existed: target[key]=before
 else: target.erase(key)

func _pair(point: Vector2) -> Array:
 return JSON.parse_string(JSON.stringify([point.x,point.y]))

func _point(pair: Array) -> Vector2: return Vector2(pair[0],pair[1])

func _shoe(center: Vector2,index: int) -> Vector2:
 if index==0: return center
 var angle: float=TAU*float(index-1)/16.
 return center+Vector2(cos(angle)*10,sin(angle)*6)

func _pixel(point: Vector2) -> Dictionary:
 var pixel: Vector2i=Vector2i(roundi(point.x),roundi(point.y))
 var cell: Vector2i=Vector2i(pixel.x/1536,pixel.y/1024)
 var path: String="res://art/maps/world_map_v15_complete_v9c/chunks/r%d_c%d_walk.png"%[cell.y,cell.x]
 # White is a synthetic PURE fixture, not a read or claim about actual pixels.
 return {"clear":true,"kind":"raw_nav","point":_pair(point),"pixel":[pixel.x,pixel.y],"chunk":[cell.x,cell.y],"rgba":[1,1,1,1],"path":path,"sha256":plan.raw_navigation_sha256[path],"pixel_sampling":"round_world_pixel"}

func _raster(witness: Dictionary) -> Dictionary:
 var centers: Array=[]
 for ci in 3:
  var center: Vector2=_point(witness.from_px).lerp(_point(witness.to_px),float(ci)/2.)
  var pixels: Array=[]
  for si in 17: pixels.append(_pixel(_shoe(center,si)))
  centers.append({"center_px":_pair(center),"all17_raw_pixels":pixels})
 return {"clear":true,"centers":centers,"max_step_px":4,"scope":"ORIGINAL_CAPTURED_RASTER_ONLY_NOT_SOURCE_SOLID_OR_PHYSICS_PASS","normal_input_executed":false,"source_solids_pass_claimed":false,"actual_Physics_pass_claimed":false}

func _build_fixture() -> Dictionary:
 var result: Dictionary={"physical_seam_plan_path":PLAN_PATH,"physical_seam_plan_sha256":PLAN_SHA,"seam_static_witness_count":1344,"seam_actual_input_count":112,"original_raster_witness_count":1344,"original_source_collision_negative_count":94,"old_ROOT330_94_failures_preserved":true,"all1344_seam_witnesses_normal_input_executed":false,"original_raster_seam_records":[],"original_raw_seam_classifications":[],"original_source_collision_negative_records":[],"static_seam_records":[],"actual_open_seam_input":[]}
 var denied: Dictionary={}
 for row: Dictionary in plan.original_source_collision_negatives:
  denied[row.seam_id+"/"+str(int(row.original_witness_index))]=row
  var value: Dictionary=row.duplicate(true)
  var rid: int=1000+result.original_source_collision_negative_records.size()
  var path: String="/root/SyntheticField/ObjectCollision_"+String(row.id)
  value["actual_raw_denial"]=row.actual_segment_evidence.duplicate(true)
  value["blocked_shoe_Physics"]={"query_kind":"ACTUAL_POINT_AT_ORIGINAL_BLOCKED_SHOE","query_point_px":row.point.duplicate(),"expected_own_rid":rid,"expected_body_path":path,"source_kind":"visual_objects","actual_body":{"id":row.id,"path":path,"rid":rid,"source_collision_kind":"visual_objects"},"own_rid_hit":true,"hits":[{"rid":rid,"path":path,"own_object_rid":true}],"player_center_collision_claimed":false,"player_was_not_moved":true}
  result.original_source_collision_negative_records.append(value)
 for row: Dictionary in selection.seams:
  for wi in 12:
   var witness: Dictionary=row.projected_witnesses[wi]
   result.original_raster_seam_records.append({"seam_id":row.id,"witness_index":wi,"original_witness":witness.duplicate(true),"raster_only":_raster(witness)})
   var key: String=row.id+"/"+str(wi)
   result.original_raw_seam_classifications.append({"seam_id":row.id,"original_witness_index":wi,"actual_raw_segment":denied[key].actual_segment_evidence.duplicate(true) if denied.has(key) else {"clear":true,"centers":3,"max_step_px":4},"actual_Physics_pass_claimed":false,"old_failure_claimed_passed":false})
 for row: Dictionary in plan.seams:
  for wi in 12:
   var witness: Dictionary=row.physical_witnesses[wi]
   var centers: Array=[]
   for ci in 3:
    var point: Array=witness.all_three_full17_centers[ci].center
    centers.append({"center_px":point.duplicate(),"raw_full17":{"clear":true,"kind":"full17","center":point.duplicate()},"actual_Physics_clear":true})
   result.static_seam_records.append({"id":row.id,"witness_index":wi,"candidate_index":witness.candidate_index,"selected_legal_rank":row.selected_legal_ranks[wi],"from_px":witness.from_px.duplicate(),"to_px":witness.to_px.duplicate(),"full17_actual_physics":{"clear":true,"centers":3,"max_step_px":4},"three_center_proofs":centers,"normal_input_executed":false})
  var witness: Dictionary=row.physical_witnesses[0]
  result.actual_open_seam_input.append({"id":row.id,"witness_index":0,"candidate_index":witness.candidate_index,"physical_seam_plan_sha256":PLAN_SHA,"ok":true,"segments":[{"ok":true,"reached":true,"all_recorded_feet_clear":true,"physics_samples":1,"start":witness.from_px.duplicate(),"target":witness.to_px.duplicate(),"actual_end":witness.to_px.duplicate()}]})
 var captured: Dictionary={}
 for row: Dictionary in manifest.seams: captured[row.id]=row
 var edges: Array=[]
 for row: Dictionary in selection.seams:
  edges.append({"id":row.id,"classification":"open","reference":captured[row.id].independent_reference_capture,"witnesses":row.projected_witnesses,"exact_kinds":["visual","shadow_off","land","raw_walk","walk"],"all_edge_pixels_checked":true,"all_predicates_passed":true})
 result["saved_geometry_112"]={"scope":"RELEASE_LAYERED_SAVED_GEOMETRY_ALL112_FIVE_ROLE_REFERENCES_ORIGINAL1344_RASTER_ONLY","capture_protocol":"COHERENT_WHOLE_FIXED_CAMERA_DERIVED_RF_V9C_FULL64_112_V1","checks":1,"failures":0,"errors":[],"runtime_input_executed":false,"visual_approved":false,"source_solid_Physics_credit":false,"original_raster_witness_count":1344,"immutable_geometry_origin_sha256":"6ee5d11e56fb7d8cffaa2475abe801222cb94e417e2c8c0d4f0dac7586a02333","original_raster_seam_records":result.original_raster_seam_records,"edges":edges}
 return result

func _run() -> void:
 var self_sha: String=FileAccess.get_sha256(get_script().resource_path)
 var player_before: Dictionary=_player_files()
 _check(OS.get_cmdline_user_args().is_empty(),"pure fixed scope has no runtime subsets or approval arguments")
 _check(_hashes(PINS)==PINS,"all frozen gate/plan/old-origin/consumer inputs exact SHA")
 if failures>0: quit(1); return
 var script: GDScript=load(GATE_PATH) as GDScript
 _check(script!=null,"actual gate loads as script")
 if failures>0: quit(1); return
 gate=script.new()
 plan=_read(PLAN_PATH)
 source=_read(SOURCE)
 selection=_read(SELECTION)
 manifest=_read(MANIFEST)
 var input_before: Dictionary=_hashes(plan.input_sha256)
 _check(input_before==plan.input_sha256,"all74 actual fixed preparation inputs readable with original SHA")
 _check(_schema_ok(),"actual frozen112/35168/1344/94 plan passes independent complete schema")
 var old: String=FileAccess.get_file_as_string(OLD_GATE)
 var current: String=FileAccess.get_file_as_string(GATE_PATH)
 for name: String in ["_selection_error","_release_binding_value_equal","_release_objects","_release_actual_evidence","_release_city","_append","_snapshot_bytes_unchanged","approval_error"]:
  var original: String=_method(old,name)
  _check(not original.is_empty() and original==_method(current,name),"unchanged original method bytes "+name)
 var baseline_start: int=old.find("const BASELINE :=")
 var baseline_end: int=old.find("const SYSTEM_PATHS :=",baseline_start)
 _check(current.contains(old.substr(baseline_start,baseline_end-baseline_start)),"all six baseline rollback identities unchanged")
 for key: String in ["schema","edge_count","candidate_count","physical_static_witness_count","physical_actual_input_representative_count","original_source_collision_negative_count"]: _mutate_plan(plan,key,0,"wrong count "+key)
 for key: String in ["Field_executed","actual_Physics_checked","formal_approval","visual_approved","legacy_full_executed","release_complete","runtime_reselection_permitted","selection_replacement_after_failure_permitted"]: _mutate_plan(plan,key,true,"false execution/approval credit "+key)
 for key: String in ["scope","algorithm_identity","selection_formula"]: _mutate_plan(plan,key,7,"string wrong type "+key)
 var inputs: Dictionary=plan.input_sha256
 _mutate_plan(inputs,SOURCE,"0".repeat(64),"source SHA")
 _mutate_plan(plan.origin_ROOT234_selection,"representative_count",129,"old130 representatives reduced")
 var required_scope: Variant=plan.scope
 plan.erase("scope")
 _check(not _schema_ok(),"plan missing required scope rejected")
 plan.scope=required_scope
 _mutate_plan(plan,"seams",plan.seams.slice(0,111),"edge dropped")
 var edge: Dictionary=plan.seams[0]
 _mutate_plan(edge,"all_candidates",edge.all_candidates.slice(1),"candidate domain reduced")
 _mutate_plan(edge,"selected_legal_ranks",[0,0,0,0,0,0,0,0,0,0,0,0],"equal ranks replaced")
 _mutate_plan(edge.all_candidates[0],"from_px",[0,0],"candidate relocated")
 _mutate_plan(edge.all_candidates[0],"candidate_index",1,"candidate reordered")
 _mutate_plan(edge.all_candidates[0],"clear",1,"boolean wrong type")
 _mutate_plan(plan,"original_source_collision_negatives",plan.original_source_collision_negatives.slice(1),"old94 negative dropped")
 _mutate_plan(plan.original_source_collision_negatives[0],"point",[0,0],"old blocked shoe relocated")
 _mutate_plan(plan.original_source_collision_negatives[0],"id",7,"old source identity wrong type")
 _mutate_plan(plan.original_source_collision_negatives[0],"old_failure_claimed_passed",true,"old failure recredited")
 var duplicate: Array=plan.original_source_collision_negatives.duplicate()
 duplicate[1]=duplicate[0]
 _mutate_plan(plan,"original_source_collision_negatives",duplicate,"old94 duplicate")
 fixture=_build_fixture()
 _check(_world_ok(),"SYNTHETIC full layered report fixture passes consumer, no real execution credit")
 _check(gate.call("_release_layered_references",fixture,selection,manifest)==true,"SYNTHETIC112 five-role whole32px references +original1344 preserved")
 for key: String in ["physical_seam_plan_path","physical_seam_plan_sha256"]: _mutate_world(fixture,key,7,"plan binding wrong type "+key)
 for key: String in ["original_raster_seam_records","original_raw_seam_classifications","original_source_collision_negative_records","static_seam_records","actual_open_seam_input"]:
  var rows: Array=fixture[key]
  _mutate_world(fixture,key,rows.slice(1),"coverage dropped "+key)
 _mutate_world(fixture,"all1344_seam_witnesses_normal_input_executed",true,"static evidence normal-input overclaim")
 var negative: Dictionary=fixture.original_source_collision_negative_records[0]
 var blocked: Dictionary=negative.blocked_shoe_Physics
 for key: String in ["expected_own_rid","expected_body_path","source_kind","query_kind","query_point_px"]: _mutate_world(blocked,key,0,"blocked shoe wrong binding/type "+key)
 _mutate_world(blocked,"own_rid_hit",false,"own RID missing")
 _mutate_world(blocked,"player_center_collision_claimed",true,"shoe evidence mislabeled Player center")
 _mutate_world(blocked.actual_body,"id","not_current_source","wrong source body")
 _mutate_world(blocked.actual_body,"rid",999,"same-query body RID mismatch")
 _mutate_world(blocked.hits[0],"rid",999,"own hit RID mismatch")
 _mutate_world(blocked.hits[0],"path","/root/Other","own hit path mismatch")
 _mutate_world(negative,"actual_raw_denial",{},"actual raw denial missing")
 var positive: Dictionary=fixture.static_seam_records[0]
 for key: String in ["candidate_index","selected_legal_rank","witness_index"]: _mutate_world(positive,key,-1,"fixed positive "+key)
 _mutate_world(positive,"from_px",[0,0],"physical positive relocated")
 _mutate_world(positive,"normal_input_executed",true,"static positive normal-input overclaim")
 _mutate_world(positive.full17_actual_physics,"clear",false,"actual Physics denied")
 _mutate_world(positive.three_center_proofs[0],"actual_Physics_clear",false,"one center missing actual Physics")
 var input: Dictionary=fixture.actual_open_seam_input[0]
 _mutate_world(input,"witness_index",1,"normal input not fixed index0")
 _mutate_world(input,"physical_seam_plan_sha256","0".repeat(64),"normal input stale plan")
 _mutate_world(input.segments[0],"physics_samples",0,"no actual samples")
 _mutate_world(input.segments[0],"target",[0,0],"normal input relocated target")
 _mutate_world(input.segments[0],"reached",false,"normal input not reached")
 for key: String in ["original_raster_seam_records","original_raw_seam_classifications","original_source_collision_negative_records","static_seam_records","actual_open_seam_input"]:
  var duplicate_rows: Array=fixture[key].duplicate()
  duplicate_rows[1]=duplicate_rows[0]
  _mutate_world(fixture,key,duplicate_rows,"duplicate identity "+key)
 var required_plan_sha: Variant=fixture.physical_seam_plan_sha256
 fixture.erase("physical_seam_plan_sha256")
 _check(not _world_ok(),"old failed report without distinct physical plan binding rejected")
 fixture.physical_seam_plan_sha256=required_plan_sha
 var bad_types: Array=[null,false,0,1.,"wrong",[],{},[0],Vector2.ZERO,PackedByteArray(),INF,NAN,Callable()]
 for value: Variant in bad_types:
  var before: Variant=blocked.query_kind
  blocked.query_kind=value
  _check(gate.call("_release_blocked_shoe",blocked,plan.original_source_collision_negatives[0],source)==false,"typed query kind rejected without runtime comparison error type "+str(typeof(value)))
  blocked.query_kind=before
  var raster: Dictionary=fixture.original_raster_seam_records[0].raster_only
  before=raster.scope
  raster.scope=value
  _check(gate.call("_release_original_raster",raster,fixture.original_raster_seam_records[0].original_witness,plan.raw_navigation_sha256)==false,"typed raster scope rejected type "+str(typeof(value)))
  raster.scope=before
 var geometry: Dictionary=fixture.saved_geometry_112
 for key: String in ["source_solid_Physics_credit","runtime_input_executed","visual_approved"]:
  var before: Variant=geometry[key]
  geometry[key]=true
  _check(gate.call("_release_layered_references",fixture,selection,manifest)==false,"reference false credit rejected "+key)
  geometry[key]=before
 var first_reference: Dictionary=geometry.edges[0]
 var before_kinds: Variant=first_reference.exact_kinds
 first_reference.exact_kinds=["visual","land","walk"]
 _check(gate.call("_release_layered_references",fixture,selection,manifest)==false,"missing shadow/raw role rejected")
 first_reference.exact_kinds=before_kinds
 _check(_schema_ok() and _world_ok(),"all in-memory mutations restored; original plan and synthetic positive still valid")
 _check(_hashes(plan.input_sha256)==input_before and _hashes(PINS)==PINS and FileAccess.get_sha256(get_script().resource_path)==self_sha,"all74 source inputs and bound scripts unchanged after tests")
 _check(_player_files()==player_before,"all15 player paths plus discovered save files unchanged")
 var output: String="res://build/joint_world_luoyang_20261003_qa/layered_seam_gate_pure_%d_%d"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
 var result: Dictionary={"scope":"PURE_SCHEMA_AND_SYNTHETIC_CONSUMER_FIXTURES_NOT_FIELD_PHYSICS_INPUT_OR_APPROVAL","checks":checks,"failures":failures,"records":records,"gate_sha256":GATE_SHA,"physical_seam_plan_sha256":PLAN_SHA,"actual_plan_edges":112,"actual_plan_candidates":35168,"synthetic_positive_records":1344,"synthetic_input_records":112,"synthetic_negative_records":94,"Field_executed":false,"actual_Physics_executed":false,"normal_input_executed":false,"visual_approved":false,"release_complete":false,"formal_approval":false,"source_unchanged":_hashes(plan.input_sha256)==input_before and _hashes(PINS)==PINS,"player_saves_unchanged":player_before==_player_files()}
 var written: bool=DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK
 var file: FileAccess=FileAccess.open(output+"/result.json",FileAccess.WRITE) if written else null
 if file!=null:
  file.store_string(JSON.stringify(result,"\t",true))
  file.close()
  written=FileAccess.file_exists(output+"/result.json") and _read(output+"/result.json").get("failures")==failures
 else: written=false
 _check(written,"NEW pure result written/read back only in unique build directory")
 print("LAYERED_SEAM_GATE_PURE checks=%d failures=%d output=%s"%[checks,failures,output])
 fixture.clear()
 gate=null
 quit(0 if failures==0 else 1)
