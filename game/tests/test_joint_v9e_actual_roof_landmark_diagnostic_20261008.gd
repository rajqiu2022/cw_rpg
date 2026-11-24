extends "res://tests/test_joint_v9e_source_entry_identity_roundtrips_20261008.gd"
## ROOT363 READONLY observation: original roof stand/load chain, NO roof clicks.
## Rejected lookup is evidence, not silently accepted negative/Field/RELEASE credit.
const BASE_ENTRY: String="res://tests/test_joint_v9e_source_entry_identity_roundtrips_20261008.gd"
const BASE_SHA: String="c706826e1bc8e1ab69eb0cd9306bc5de4ef2bf4baa0cdd1125c856f6c0879630"
const ROOT362_BEFORE: String="res://build/joint_world_luoyang_20261003_qa/362_v9e_candidate_complete_release_headless_strict_source_entry_20261008/before.json"
const ROOT362_BEFORE_SHA: String="c0f16e0e101711259cd9da97a33a7a7ff6dd9f1323b8d8b85f9d5f06d11caaab"
const ROOT362_TRIPS: String="res://build/joint_world_luoyang_20261003_qa/world_release_197501883/portal_roundtrips.json"
const ROOT362_TRIPS_SHA: String="4861ccdadf1cc86faec5305b624c9fa2a013134f2b264de4857fbac3291b9947"
const DIAGNOSTIC_FLAG: String="--diagnose-roof-landmark-only"

class RoofPhase extends "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":
 var observations: Array[Dictionary]=[]
 var diagnostic_labels: Array[String]=[]
 func _check(ok: bool,label: String) -> void:
  if not ok: diagnostic_labels.append(label)
  super._check(ok,label)
 func _native(value: Variant) -> Dictionary:
  return {"type":typeof(value),"text":str(value),"native_bytes_hex":var_to_bytes(value).hex_encode()}
 func _rows(values: Array,id: Variant) -> Array[Dictionary]:
  var result_rows: Array[Dictionary]=[]
  for row: Dictionary in values:
   if typeof(row.get("id"))==typeof(id) and row.get("id")==id: result_rows.append(row)
  return result_rows
 func _binding_observation(id: String) -> Dictionary:
  var result_row: Dictionary={"source_portals":[],"runtime_portals":[],"source_objects":[],"runtime_objects":[]}
  var authored: Array[Dictionary]=_rows(source.get("portals",[]),id)
  var runtime: Array[Dictionary]=_rows(world.map_layout.portals,id)
  result_row.source_portals=authored; result_row.runtime_portals=runtime
  result_row["portal_counts_exact"]=authored.size()==1 and runtime.size()==1
  if authored.size()!=1 or runtime.size()!=1: return result_row
  var compound: Variant=authored[0].get("compound_id")
  result_row["compound_source"]=_native(compound)
  result_row["compound_runtime"]=_native(runtime[0].get("compound_id"))
  result_row["portal_source_source"]=_native(authored[0].get("source"))
  result_row["portal_runtime_source"]=_native(runtime[0].get("source"))
  var originals: Array[Dictionary]=_rows(source.get("objects",[]),compound)
  var objects: Array[Dictionary]=_rows(world.map_layout.visual_objects,compound)
  result_row.source_objects=originals; result_row.runtime_objects=objects
  result_row["object_counts_exact"]=originals.size()==1 and objects.size()==1
  if originals.size()!=1 or objects.size()!=1: return result_row
  var original: Dictionary=originals[0]; var object: Dictionary=objects[0]
  var fields: Dictionary={}
  for key: String in ["id","source","source_sha256","texture","role"]:
   fields[key]={"original":_native(original.get(key)),"runtime":_native(object.get(key)),"same_type_and_bytes":typeof(original.get(key))==typeof(object.get(key)) and var_to_bytes(original.get(key))==var_to_bytes(object.get(key))}
  result_row["identity_fields"]=fields
  result_row["source_pos"]=_native(original.get("pos")); result_row["runtime_pos"]=_native(object.get("pos"))
  if _review_pair(original.get("pos")):
   var expected: Vector2=Vector2(float(original.pos[0]),float(original.pos[1]))
   result_row["source_native_position"]=_native(expected)
   result_row["native_position_equal"]=object.get("pos") is Vector2 and object.pos==expected
  var catalog: Dictionary=manifest.get("asset_sha256",{})
  for key: String in ["source","texture"]:
   var path: Variant=original.get(key)
   if typeof(path)==TYPE_STRING:
    result_row[key+"_catalog"]={"path":path,"catalog_sha":catalog.get(path),"actual_sha":FileAccess.get_sha256(path),"original_sha":original.get("source_sha256"),"actual_bound_predicate":_review_bound(path,original.get("source_sha256"),catalog)}
  return result_row
 func _observe(id: String,probe: Dictionary) -> Dictionary:
  var binding: Dictionary=_release_landmark_binding(id)
  var actual: Sprite2D=_actual_landmark_sprite(id)
  var uv: Vector2=_point(probe.get("source_uv")); var click: Vector2=_point(probe.get("world_click_px"))
  var nodes: Variant=field.get("_scene_object_nodes"); var screen: Variant=field.get("_screen_size")
  var world_size: Variant=field.get("_world_size")
  var record: Dictionary={"id":id,"probe":probe.duplicate(true),"binding_gate":_binding_observation(id),"actual_binding_nonempty":not binding.is_empty(),"actual_lookup_nonnull":actual!=null,"screen":_native(screen),"world_size":_native(world_size),"expected_SIZE":_native(SIZE),"nodes_type":typeof(nodes),"nodes_is_array":nodes is Array,"uv":_native(uv),"click":_native(click),"uv_finite":uv.is_finite(),"click_finite":click.is_finite(),"original_composite_predicate":actual!=null and uv.is_finite() and click.is_finite(),"matching_nodes":[],"all_registered_node_names":[],"pointer_executed":false,"negative_input_pass_claimed":false}
  var object: Dictionary=binding.get("object",{})
  var expected_name: String="SceneObject_"+String(object.get("id",""))
  record["expected_node_name"]=expected_name
  var qa_expected: Vector2=Vector2(INF,INF)
  if object.get("pos") is Vector2 and screen is Vector2:
   qa_expected=Vector2(object.pos.x*screen.x,object.pos.y*screen.y)
   record["QA_expected_position"]=_native(qa_expected)
   record["Field_actual_norm_to_screen"]=_native(field.call("_norm_to_screen",object.pos))
  if nodes is Array:
   record["registered_node_count"]=nodes.size()
   for node: Variant in nodes:
    if not node is Sprite2D or not is_instance_valid(node): continue
    record.all_registered_node_names.append(String(node.name))
    var path: String=node.texture.resource_path if node.texture!=null else ""
    if String(node.name)!=expected_name and path!=String(object.get("texture","")): continue
    var row: Dictionary={"name":String(node.name),"node_path":String(node.get_path()),"name_exact":String(node.name)==expected_name,"texture_class":node.texture.get_class() if node.texture!=null else "NULL","texture_path":path,"expected_texture":object.get("texture"),"texture_path_exact":node.texture!=null and path==object.get("texture"),"position":_native(node.position),"position_finite":node.position.is_finite(),"position_equal_QA":node.position==qa_expected,"global_position":_native(node.global_position),"scale":_native(node.scale),"centered":node.centered,"flip_h":node.flip_h,"flip_v":node.flip_v,"is_returned_lookup":node==actual}
    if node.texture!=null and uv.is_finite() and click.is_finite():
     var image: Image=node.texture.get_image()
     if image!=null and not image.is_empty():
      var owned: Image=image.duplicate()
      if owned.is_compressed(): owned.decompress()
      var pixel:=Vector2i(clampi(floori(uv.x*owned.get_width()),0,owned.get_width()-1),clampi(floori(uv.y*owned.get_height()),0,owned.get_height()-1))
      row["roof_source_pixel"]=[pixel.x,pixel.y]; row["roof_source_alpha"]=owned.get_pixelv(pixel).a
      row["roof_source_uv_in_domain"]=uv.x>=0 and uv.y>=0 and uv.x<1 and uv.y<1
      var rect: Rect2=node.get_rect()
      var container: Node2D=field.get("world_container") as Node2D
      var draw_uv:=Vector2(1.-uv.x if node.flip_h else uv.x,1.-uv.y if node.flip_v else uv.y)
      var projected: Vector2=container.to_local(node.to_global(rect.position+draw_uv*rect.size))
      row["projected"]=_native(projected); row["projected_error_px"]=projected.distance_to(click)
    record.matching_nodes.append(row)
  return record
 func observe_all_roofs() -> void:
  for id: String in DESTINATIONS:
   var approval: Dictionary=reviewed_doors.get(id,{})
   var roofs: Array[Dictionary]=[]
   for probe: Dictionary in approval.get("input_negative_probes",[]):
    if probe.get("kind")=="roof_click": roofs.append(probe)
   _check(roofs.size()==1,"one original reviewed roof probe "+id)
   if roofs.size()!=1: continue
   var stand: Vector2=_point(roofs[0].get("legal_stand_px"))
   _check(stand.is_finite() and bool(oracle.call("clear",stand)),"original roof fixture full17 legal "+id)
   if not stand.is_finite() or not bool(oracle.call("clear",stand)): continue
   # Exact original negative fixture/load/intro path; no pointer or roof input.
   root.get_node("SceneRouter").call("go_field_smart",scene_id,stand/SIZE,"",15)
   if not await _wait_field(scene_id) or not await _normal_intro(): continue
   _check(_runtime_input_ready(),"original roof normal input readiness "+id)
   var record: Dictionary=_observe(id,roofs[0])
   observations.append(record)
   _check(_write_json("roof_%02d_%s.json"%[observations.size(),id],record),"readonly roof observation checked readback "+id)
   print("ROOF_LANDMARK_DIAGNOSTIC ",JSON.stringify({"id":id,"binding":record.actual_binding_nonempty,"lookup":record.actual_lookup_nonnull,"composite":record.original_composite_predicate,"matching_nodes":record.matching_nodes.size()}))

func _run() -> void:
 var wanted:=PackedStringArray(SOURCE_DIAG.ARGS); wanted.append(DIAGNOSTIC_FLAG)
 _check(OS.get_cmdline_user_args()==wanted,"explicit roof-only diagnostic flags, not filtered RELEASE")
 var env0: Dictionary=_env()
 _check(env0.driver=="WASAPI" and env0.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen executable/1x start")
 var endpoints: Dictionary={ACTUAL:_file(ACTUAL),ROOT362_BEFORE:_file(ROOT362_BEFORE),ROOT362_TRIPS:_file(ROOT362_TRIPS)}
 _check(endpoints[ACTUAL].get("sha256")==ACTUAL_SHA and endpoints[ROOT362_BEFORE].get("sha256")==ROOT362_BEFORE_SHA and endpoints[ROOT362_TRIPS].get("sha256")==ROOT362_TRIPS_SHA,"fixed original source/ROOT362 provenance")
 if not errors.is_empty(): quit(1); return
 var baseline: Dictionary=_read(ACTUAL); var wrapper: Dictionary=_read(ROOT362_BEFORE)
 var expected: Dictionary=SOURCE_DIAG.PINS.duplicate(true)
 for path: String in baseline.source_before:
  if baseline.source_before[path].get("exists")==true: expected[path]=baseline.source_before[path].sha256
 _check(wrapper.get("sources") is Array and wrapper.sources.size()==66,"exact ROOT362 wrapper source inventory")
 for row: Dictionary in wrapper.get("sources",[]):
  var path: String=ProjectSettings.localize_path(String(row.path).replace("\\","/"))
  expected[path]=String(row.sha256).to_lower()
 expected[ADAPTER_PATH]=ADAPTER_SHA; expected[BASE_ENTRY]=BASE_SHA
 expected[ACTUAL]=ACTUAL_SHA; expected[ROOT362_BEFORE]=ROOT362_BEFORE_SHA; expected[ROOT362_TRIPS]=ROOT362_TRIPS_SHA
 var paths: Dictionary=expected.duplicate(true); paths[get_script().resource_path]="SELF_CURRENT_BYTES"
 var before: Dictionary=_snapshot(paths,endpoints)
 for path: String in expected: _check(before[path].get("sha256")==expected[path],"fresh unique source binding "+path)
 var players0: Dictionary=_players(); var slot0: Variant=root.get_node("SaveManager").get("active_slot")
 if not errors.is_empty(): quit(1); return
 var output: String="res://build/joint_world_luoyang_20261003_qa/roof_landmark_diagnostic_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique readonly diagnostic evidence")
 var subject:=RoofPhase.new()
 subject.owner_tree=self; subject.output=output; subject.requested_phase="ROOF_LOOKUP_OBSERVATION_NO_INPUT_NOT_RELEASE"
 subject.before_saves=subject.call("_actual_saves"); subject.prior_navigation=root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
 subject.prior_active=StringName(root.get_node("SceneRouter").get("_active_world_map_scene")); subject.prior_slot=int(slot0)
 subject.source=_read(OLD_DIAG.SOURCE); subject.manifest=_read(OLD_DIAG.MANIFEST); subject.world=load(OLD_DIAG.WORLD)
 var frozen: Dictionary=_read(FROZEN)
 subject.execution_sha256=frozen.execution_sha256.duplicate(true); subject.v9c_artifact_sha256=frozen.v9c_artifact_sha256.duplicate(true); subject.derived_geometry_inputs=frozen.derived_geometry_inputs.duplicate(true)
 subject.oracle=RAW.new()
 _check(subject.oracle.call("configure",subject.world.map_layout)==true,"actual64 current navigation/full17/source-solids oracle")
 subject.call("_read_independent_door_review")
 if errors.is_empty() and subject.failures==0:
  subject.call("_ensure_runtime_fixture")
  if subject.failures==0: await subject.observe_all_roofs()
 _check(subject.observations.size()==16,"all16 actual original roof fixtures observed, no input/pass inferred")
 var observations: Array=subject.observations.duplicate(true)
 var labels: Array=subject.diagnostic_labels.duplicate()
 await subject.call("_finish")
 _check(subject.failures==0 and subject.result.get("release_complete")==false,"all original normal cleanup; diagnostics never RELEASE")
 var after: Dictionary=_snapshot(paths); var env1: Dictionary=_env()
 _check(before==after and _players()==players0 and root.get_node("SaveManager").get("active_slot")==slot0,"all unique source SHA/bytes/mtime and15 players/slot unchanged")
 _check(env1.driver=="WASAPI" and env1.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen executable/1x finish")
 var report: Dictionary={"schema":1,"scope":"ACTUAL16_ROOF_LANDMARK_LOOKUP_DIAGNOSTIC_NO_POINTER_NOT_RELEASE","checks":checks,"failures":errors.size(),"errors":errors,"phase_failures":subject.failures,"phase_failure_labels":labels,"observations":observations,"source_before":before,"source_after":after,"unique_source_count":paths.size(),"players_before":players0,"players_after":_players(),"environment_before":env0,"environment_after":env1,"preserved_ROOT362_trips":ROOT362_TRIPS,"preserved_ROOT362_trips_sha256":ROOT362_TRIPS_SHA,"original_composite_rejections_observed_not_waived":true,"pointer_executed":false,"negative_input_pass_claimed":false,"source_complete":false,"release_complete":false,"output":output}
 _check(subject.call("_write_json","diagnostic.json",report)==true,"unique complete readonly diagnostic checked readback")
 print("V9E_ROOF_LANDMARK_DIAGNOSTIC ",JSON.stringify({"checks":checks,"failures":errors.size(),"phase_failures":subject.failures,"observations":observations.size(),"output":output,"release_complete":false}))
 subject=null
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)
