extends "res://tests/test_joint_v9e_source_entry_identity_roundtrips_20261008.gd"
## DIAGNOSTIC ONLY: original offline source queries versus matching live Field.
## NO adapter/parent/production edits, no replacement planner or return shortcut.
const BASE_PATH: String="res://tests/test_joint_v9e_source_entry_identity_roundtrips_20261008.gd"
const BASE_SHA: String="c706826e1bc8e1ab69eb0cd9306bc5de4ef2bf4baa0cdd1125c856f6c0879630"
const BEFORE366: String="res://build/joint_world_luoyang_20261003_qa/366_v9e_candidate_complete_release_headless_owned_artifact_catalog_20261008/before.json"
const BEFORE366_SHA: String="1a37f79ab9a7555cf212513555af44f25e3c3b404498ea3d2d19a61a5688f726"
const ARCHIVE_ADAPTER: String="res://build/joint_world_luoyang_20261003_qa/366_v9e_candidate_complete_release_headless_owned_artifact_catalog_20261008/joint_v15_release_world_prepared_phase.gd"
const CURRENT_ARTIFACT: String="res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
const CURRENT_ARTIFACT_SHA: String="77af1707d32517fa1c7b9fecdfe84deefc6b8ef000f8bd82947beeb9ff8d7b9e"
const SOURCE_RAW_PATH: String="res://tests/helpers/v15_field_raw_oracle.gd"
const SOURCE_RAW_SHA: String="dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb"
const SOURCE_RAW=preload("res://tests/helpers/v15_field_raw_oracle.gd")
const FLAG: String="--diagnose-legacy-offline-live-domain"
const TARGETS: Dictionary={"bianzhou":"openworld_bianzhou_city","wudang":"openworld_wudang_gate","linxi_village":"linxi_village_scrollmap"}
const BASE=preload("res://tests/test_joint_v9e_source_entry_identity_roundtrips_20261008.gd")
var dependency_seen: Dictionary={}

class DomainPhase extends "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":
 var observations: Array[Dictionary]=[]
 var attempts: Array[Dictionary]=[]
 var consumed: Dictionary={}
 var failure_labels: Array[String]=[]
 var diagnostic_stage: String="UNSET"
 func _check(ok: bool,label: String) -> void:
  if not ok: failure_labels.append(label)
  super._check(ok,label)
 func _native(value: Variant) -> Dictionary:
  return {"type":typeof(value),"native_bytes_hex":var_to_bytes(value).hex_encode(),"text":str(value)}
 func _native_inventory(value: Array) -> Dictionary:
  var digest:=HashingContext.new()
  digest.start(HashingContext.HASH_SHA256); digest.update(var_to_bytes(value))
  return {"type":typeof(value),"count":value.size(),"native_bytes_sha256":digest.finish().hex_encode(),"typed_builtin":value.get_typed_builtin(),"typed_class":String(value.get_typed_class_name())}
 func _definition(value: SceneScript) -> Dictionary:
  return {"scene_id":String(value.scene_id),"path":value.resource_path,"instance_id":str(value.get_instance_id()),"script_path":value.get_script().resource_path,"layout_path":value.map_layout.resource_path,"layout_instance_id":str(value.map_layout.get_instance_id()),"layout_script_path":value.map_layout.get_script().resource_path,"design_size":_native(value.map_layout.design_size),"actor_positions_are_feet":value.actor_positions_are_feet,"default_root":_native(value.player_spawn),"layout_blockers":_native_inventory(value.map_layout.blockers),"layout_visual_objects":_native_inventory(value.map_layout.visual_objects)}
 func _shoe(raw: RefCounted,point: Vector2,index: int) -> Dictionary:
  var hits: Array=[]
  for solid: Dictionary in raw.get("solids"):
   var blocked: bool=Geometry2D.is_point_in_polygon(point,solid.polygon) if solid.kind=="exact_world_polygon" else (solid.rect as Rect2).has_point(point)
   if blocked: hits.append({"id":solid.id,"kind":solid.kind})
  var pixel: Dictionary=raw.call("pixel_evidence",point)
  return {"shoe_index":index,"source_point_px":[point.x,point.y],"pixel_evidence":pixel,"source_solid_hits":hits,"clear":pixel.get("clear")==true and hits.is_empty()}
 func _source17(raw: RefCounted,center: Vector2) -> Dictionary:
  var points: PackedVector2Array=raw.call("samples",center)
  var records: Array=[]; var clear: bool=true
  for index in points.size():
   var row: Dictionary=_shoe(raw,points[index],index)
   records.append(row); clear=clear and row.clear
  return {"center_source_px":_native(center),"samples":records,"clear":clear,"scope":"INDEPENDENT_SOURCE_ONLY_10X6_SHOES_NO_LIVE_OFFSET"}
 func _actual17(raw: RefCounted,root_point: Vector2,offset: Vector2,actual: Vector2,source_size: Vector2) -> Dictionary:
  # Independent formula uses actual actor/foot and canvas, never any tested
  # mapping output. All actual ellipse shoes map separately; no center resample.
  var foot: Vector2=root_point+offset
  var records: Array=[]; var clear: bool=true
  for index in 17:
   var actual_point: Vector2=foot
   if index>0:
    var angle: float=TAU*(index-1)/16
    actual_point+=Vector2(cos(angle)*10,sin(angle)*6)
   var source_point: Vector2=(actual_point/actual)*source_size
   var row: Dictionary=_shoe(raw,source_point,index)
   row["actual_point_px"]=[actual_point.x,actual_point.y]
   row["actual_domain_valid"]=actual_point.is_finite() and actual_point.x>=0 and actual_point.y>=0 and actual_point.x<actual.x and actual_point.y<actual.y
   row.clear=row.clear and row.actual_domain_valid
   records.append(row); clear=clear and row.clear
  return {"samples":records,"clear":clear,"scope":"INDEPENDENT_EACH_ACTUAL_10X6_SHOE_TO_ORIGINAL_SOURCE"}
 func _configure_ordinary(definition: SceneScript) -> bool:
  var before_failures: int=failures
  var ok: bool=super._configure_ordinary(definition)
  if not ok or not is_instance_valid(field) or ordinary_raw==null: return ok
  var live: SceneScript=field.get("_current_scene") as SceneScript
  var player: Node2D=field.get("_player") as Node2D
  var container: Node2D=field.get("world_container") as Node2D
  if live==null or player==null or container==null: _check(false,"diagnostic real Field/actor/source identity available"); return ok
  var source_size: Vector2=Vector2(definition.map_layout.design_size)
  var actual: Vector2=field.get("_world_size")
  var offset: Vector2=container.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y"))))-player.position
  var offline: bool=diagnostic_stage=="OFFLINE_SOURCE_WHILE_WORLD_FIELD"
  var input_point: Vector2=definition.player_spawn*source_size if offline else player.position
  var independent: RefCounted=SOURCE_RAW.new()
  var configured: bool=independent.call("configure",definition.map_layout,"normalized_image_round",-1.0)
  _check(configured,"independent original raw source configured with unchanged normalized sampling/margins")
  if not configured: return ok
  var source_proof: Dictionary=_source17(independent,definition.player_spawn*source_size if offline else (player.position/actual)*source_size)
  var mapped: Dictionary=_release_legacy_foot_evidence(ordinary_raw,release_legacy_source_size,release_legacy_actual_size,input_point,offset)
  var actual_expected: Dictionary=_actual17(independent,input_point,offset,actual,source_size)
  var differences: Array=[]
  var mapped_expected_exact: bool=(mapped.get("samples",[]) as Array).size()==17
  for index in 17:
   if index>=(mapped.get("samples",[]) as Array).size(): mapped_expected_exact=false; continue
   var tested: Dictionary=mapped.samples[index]
   var own: Dictionary=actual_expected.samples[index]
   if var_to_bytes(tested.get("source_point_px"))!=var_to_bytes(source_proof.samples[index].source_point_px): differences.append(index)
   for key: String in ["source_point_px","pixel_evidence","source_solid_hits"]:
    if var_to_bytes(tested.get(key))!=var_to_bytes(own.get(key)): mapped_expected_exact=false
  var layers: Array=[]
  for layer: Dictionary in independent.get("layers"):
   consumed[layer.path]=layer.sha256
   layers.append({"path":layer.path,"sha256":layer.sha256,"rect":_native(layer.rect),"native_tile":layer.native_tile})
  var row: Dictionary={"stage":diagnostic_stage,"definition":_definition(definition),"actual_definition":_definition(live),"same_definition_instance":definition==live,"same_scene_id":definition.scene_id==live.scene_id,"Field_instance_id":str(field.get_instance_id()),"actual_size":_native(actual),"source_size":_native(source_size),"ordinary_size":_native(ordinary_size),"release_legacy_context":release_legacy_context,"input_point":_native(input_point),"actual_player_root":_native(player.position),"actual_visible_offset":_native(offset),"source_original_margin_override":independent.get("physical_margin_override"),"original_source_solids":_native(independent.get("solids")),"tested_source_solids":_native(ordinary_raw.get("solids")),"source_only17":source_proof,"current_adapter_mapped17":mapped,"independent_actual17":actual_expected,"mapped_each_shoe_matches_independent_actual_formula":mapped_expected_exact,"source_only_vs_mapped_coordinate_difference_indices":differences,"original_static_boolean":_ordinary_static_clear(input_point),"actual_Physics_clear":_physical_clear(input_point) if not offline else null,"source_layers":layers,"configuration_failure_delta":failures-before_failures,"clear_boolean_equivalence_does_not_prove_domain_equivalence":true,"offline_source_legality_pass_claimed":false,"release_credit":false}
  _check(independent.call("verify_sources")==true,"independent original source images unchanged through diagnosis")
  _check(var_to_bytes(independent.get("solids"))==var_to_bytes(ordinary_raw.get("solids")),"original grown margins and solid geometry have not changed")
  _check(mapped_expected_exact,"all17 tested actual mapping pixels/solids recorded against independent formula")
  if offline: _check(definition!=live and live.scene_id==scene_id and differences.size()>0,"offline source/world Field identity and coordinate-domain discrepancy actually observed")
  else: _check(definition==live and row.original_static_boolean==true and row.actual_Physics_clear==true,"matching real Field preserves original mapped17/static/Physics predicates")
  observations.append(row)
  _check(_write_json("domain_%02d_%s.json"%[observations.size(),String(definition.scene_id)],row),"unique complete actual domain observation checked readback")
  independent.call("release"); independent=null
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
     candidates.append({"radius":radius,"direction":direction,"point":_native(point),"original_combined_clear":_ordinary_clear(point),"actual_Physics_clear":_physical_clear(point),"actual_foot_and_body_contains":_area_contains_actual_foot_and_body(reverse,point)})
  var returned: bool=await super._actual_return(destination)
  attempts.append({"target_scene":String(destination),"all80_original_candidates":candidates,"actual_returned":returned})
  return returned

func _dependencies(path: String,paths: Dictionary) -> void:
 if dependency_seen.has(path): return
 dependency_seen[path]=true
 if not paths.has(path): paths[path]="FIRST_ENDPOINT_REQUIRED"
 if not ResourceLoader.exists(path): return
 for item: String in ResourceLoader.get_dependencies(path):
  var pieces: PackedStringArray=item.split("::")
  if pieces[pieces.size()-1].begins_with("res://"): _dependencies(pieces[pieces.size()-1],paths)
 # Scene/layout background_path and walkable_mask_path are String properties,
 # not ExtResources. Include these original PNGs before any actual Field/raw
 # consumer, with the same per-path traversal/hash deduplication.
 if path.get_extension() in ["tres","tscn"]:
  var pattern:=RegEx.new()
  pattern.compile('res://[^"\\s]+')
  for found: RegExMatch in pattern.search_all(FileAccess.get_file_as_string(path)):
   _dependencies(found.get_string(),paths)

func _run() -> void:
 var wanted:=PackedStringArray(SOURCE_DIAG.ARGS); wanted.append(FLAG)
 _check(OS.get_cmdline_user_args()==wanted,"explicit limited actual offline/live domain diagnostic, not RELEASE")
 var env0: Dictionary=_env()
 _check(env0.driver=="WASAPI" and env0.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/exact engine/1x start")
 var endpoints: Dictionary={ACTUAL:_file(ACTUAL),BEFORE366:_file(BEFORE366)}
 _check(endpoints[ACTUAL].get("sha256")==ACTUAL_SHA and endpoints[BEFORE366].get("sha256")==BEFORE366_SHA,"fixed original identity and ROOT366 source provenance")
 if not errors.is_empty(): quit(1); return
 var baseline: Dictionary=_read(ACTUAL); var wrapper: Dictionary=_read(BEFORE366)
 var expected: Dictionary=SOURCE_DIAG.PINS.duplicate(true)
 for path: String in baseline.source_before:
  if baseline.source_before[path].get("exists")==true: expected[path]=baseline.source_before[path].sha256
 _check(wrapper.get("sources") is Array and wrapper.sources.size()==69,"complete frozen ROOT366 source inventory")
 for row: Dictionary in wrapper.get("sources",[]): expected[ProjectSettings.localize_path(String(row.path).replace("\\","/"))]=String(row.sha256).to_lower()
 expected[ADAPTER_PATH]=ADAPTER_SHA; expected[ARCHIVE_ADAPTER]=ADAPTER_SHA
 expected[BASE_PATH]=BASE_SHA; expected[CURRENT_ARTIFACT]=CURRENT_ARTIFACT_SHA
 expected[SOURCE_RAW_PATH]=SOURCE_RAW_SHA
 expected[ACTUAL]=ACTUAL_SHA; expected[BEFORE366]=BEFORE366_SHA
 var paths: Dictionary=expected.duplicate(true); paths[get_script().resource_path]="SELF_CURRENT_BYTES"
 _dependencies(SOURCE_RAW_PATH,paths)
 for id: String in TARGETS.values(): _dependencies("res://data/scenes/"+id+".tres",paths)
 var before: Dictionary=_snapshot(paths,endpoints)
 for path: String in paths:
  _check(before[path].get("exists")==true and before[path].has("sha256"),"unique fresh readable input "+path)
  if expected.has(path): _check(before[path].get("sha256")==expected[path],"exact frozen consumed source "+path)
 var players0: Dictionary=_players(); var slot0: Variant=root.get_node("SaveManager").get("active_slot")
 if not errors.is_empty(): quit(1); return
 var output: String="res://build/joint_world_luoyang_20261003_qa/legacy_offline_live_domain_diagnostic_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique actual diagnostic evidence directory")
 if not errors.is_empty(): quit(1); return
 var subject:=DomainPhase.new()
 subject.owner_tree=self; subject.output=output; subject.requested_phase="LIMITED_OFFLINE_LIVE_DOMAIN_DIAGNOSTIC_NOT_RELEASE"
 subject.before_saves=subject.call("_actual_saves"); subject.prior_navigation=root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
 subject.prior_active=StringName(root.get_node("SceneRouter").get("_active_world_map_scene")); subject.prior_slot=int(slot0)
 subject.source=_read(OLD_DIAG.SOURCE); subject.manifest=_read(OLD_DIAG.MANIFEST); subject.world=load(OLD_DIAG.WORLD)
 var frozen: Dictionary=_read(FROZEN)
 subject.execution_sha256=frozen.execution_sha256.duplicate(true); subject.v9c_artifact_sha256=frozen.v9c_artifact_sha256.duplicate(true); subject.derived_geometry_inputs=frozen.derived_geometry_inputs.duplicate(true)
 subject.oracle=RAW.new()
 _check(subject.oracle.call("configure",subject.world.map_layout)==true,"actual64 current navigation oracle, no artifact rerun")
 subject.call("_read_independent_door_review"); subject.call("_static_portals_and_spacing")
 var ready: bool=errors.is_empty() and subject.failures==0
 if ready:
  subject.call("_ensure_runtime_fixture")
  subject.input_driver.call("release"); subject.input_driver=BASE.ObservedDriver.new(); subject.input_driver.call("configure",self)
  ready=await subject.call("_open_owned_world_fixture",subject.reviewed_default_spawn)
 if ready:
  subject.diagnostic_stage="OFFLINE_SOURCE_WHILE_WORLD_FIELD"
  for id: String in TARGETS.values():
   var definition: SceneScript=load("res://data/scenes/"+id+".tres") as SceneScript
   _check(subject.call("_configure_ordinary",definition)==true,"unchanged original offline configure observed "+id)
  subject.diagnostic_stage="MATCHING_REAL_FIELD_ORIGINAL_SPACE_ROUNDTRIP"
  for id: String in TARGETS:
   var measurement: Dictionary=subject.call("_source_door",id)
   await subject.call("_portal_roundtrip",id,"space",measurement)
 var observations: Array=subject.observations.duplicate(true)
 var offline_count: int=0; var matching_ids: Dictionary={}
 for row: Dictionary in observations:
  if row.stage=="OFFLINE_SOURCE_WHILE_WORLD_FIELD": offline_count+=1
  elif row.same_definition_instance==true: matching_ids[row.definition.scene_id]=true
 _check(offline_count==3 and matching_ids.size()==3,"three distinct offline world-context definitions and all3 genuine matching live controls captured")
 _check(subject.actual_portal_roundtrips.size()==3 and subject.attempts.size()==3,"all3 actual original Space entries and normal reverse flows completed")
 for trip: Dictionary in subject.actual_portal_roundtrips: _check(trip.passed==true and trip.mode=="space","unchanged original complete entry/return predicates "+String(trip.id))
 for attempt: Dictionary in subject.attempts: _check(attempt.actual_returned==true and attempt.all80_original_candidates.size()==80,"all80 original return candidates retained, no alternate planner/threshold/shortcut")
 for path: String in subject.consumed: _check(before.has(path) and before[path].get("sha256")==subject.consumed[path],"every actual source PNG existed in unique before inventory "+path)
 var trips: Array=subject.actual_portal_roundtrips.duplicate(true); var attempts: Array=subject.attempts.duplicate(true)
 await subject.call("_finish")
 _check(subject.failures==0 and subject.result.get("release_complete")==false and subject.result.get("source_complete")==false,"complete original cleanup with no RELEASE/source-complete credit")
 var after: Dictionary=_snapshot(paths); var env1: Dictionary=_env()
 _check(before==after and _players()==players0 and root.get_node("SaveManager").get("active_slot")==slot0,"all unique input SHA/bytes/mtime and15 player files/slot unchanged")
 _check(env1.driver=="WASAPI" and env1.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/exact engine/1x finish")
 var report: Dictionary={"schema":1,"scope":"ACTUAL_LEGACY_OFFLINE_LIVE_DOMAIN_DIAGNOSTIC_NOT_RELEASE","checks":checks,"failures":errors.size(),"errors":errors,"phase_failures":subject.failures,"phase_failure_labels":subject.failure_labels,"observations":observations,"offline_count":offline_count,"matching_scene_ids":matching_ids.keys(),"original_roundtrips":trips,"original_return_candidates":attempts,"unique_source_count":paths.size(),"source_before":before,"source_after":after,"players_before":players0,"players_after":_players(),"environment_before":env0,"environment_after":env1,"source_complete":false,"release_complete":false,"offline_source_legality_pass_claimed":false,"formal_approval":false,"output":output}
 _check(subject.call("_write_json","diagnostic.json",report)==true,"unique complete actual diagnostic checked readback")
 print("V9E_LEGACY_OFFLINE_LIVE_DOMAIN_DIAGNOSTIC ",JSON.stringify({"checks":checks,"failures":errors.size(),"phase_failures":subject.failures,"offline_count":offline_count,"matching_count":matching_ids.size(),"roundtrips":trips.size(),"output":output,"release_complete":false}))
 subject=null
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)
