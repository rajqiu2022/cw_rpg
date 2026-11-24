extends "res://tests/test_joint_v9e_source_entry_identity_roundtrips_20261008.gd"
## READ ONLY pure Router diagnosis. NO Field, artifact, commit, save or RELEASE.
## ROOT366's original rejection is retained, not reclassified as a parent pass.
const BASE_PATH: String="res://tests/test_joint_v9e_source_entry_identity_roundtrips_20261008.gd"
const BASE_SHA: String="c706826e1bc8e1ab69eb0cd9306bc5de4ef2bf4baa0cdd1125c856f6c0879630"
const BEFORE366: String="res://build/joint_world_luoyang_20261003_qa/366_v9e_candidate_complete_release_headless_owned_artifact_catalog_20261008/before.json"
const BEFORE366_SHA: String="1a37f79ab9a7555cf212513555af44f25e3c3b404498ea3d2d19a61a5688f726"
const FLAG: String="--diagnose-world-city-migration"
const CITY_ROOT: String="res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/"
const CITY_ENTRY_PATH: String=CITY_ROOT+"ch4_s0_luoyang_gate/art_contract.json"
const CITY_ENTRY_SHA: String="2818f9fca10d30abbbbd386ff2b26a3d4ed87f300a9b8ef47f882bcb83f7640d"
const PARENT_PATH: String="res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd"
const PARENT_SHA: String="16a66f74eba277c9dcf7c1a6801bb5183d0fedf363a3e6fc3805bc41e7474970"
const CURRENT_ARTIFACT: String="res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
const CURRENT_ARTIFACT_SHA: String="77af1707d32517fa1c7b9fecdfe84deefc6b8ef000f8bd82947beeb9ff8d7b9e"
const ROUTER_PATH: String="res://scripts/autoload/scene_router.gd"
const ROUTER_SHA: String="f3ead7459632188350e1e3383ee915c83b71c1b86d36dadf718bd338a4324eca"
const CITY_PATH: String="res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd"
const CITY_SHA: String="4f4f5584f6320215207d960f8e244cd31ab657806f32e4b8a58c1a77107a63c1"
const OLD_PATHS: Dictionary={12:"res://data/maps/world_map_jianghu_legacy_v12_scene.tres",13:"res://data/scenes/world_map_jianghu_v13_staging.tres",14:"res://data/scenes/world_map_jianghu_v14.tres"}
const HISTORIC_PINS: Dictionary={
 "res://data/maps/world_map_jianghu_legacy_v12_scene.tres":"09fa89449b1792063e66ad488aa2f60671aa00da2193e5c68acb861df14d71d5",
 "res://data/scenes/world_map_jianghu_v13_staging.tres":"1567097134c4e182b54fa813bc6ea9a2cde851adfa8e8a3e82ec497bdecb428e",
 "res://data/scenes/world_map_jianghu_v14.tres":"6922d310f952056c556141d6690dc35079880e212e5646700222eaf92b1103a8",
 "res://data/maps/world_map_jianghu_layout_v12.tres":"7ce59139b203baf9b333f8136b7ce3de7bcf3031735488696348f2bb6427d141",
 "res://data/maps/world_map_jianghu_v13_staging_layout.tres":"8bba89aaf31e4a151c877b300c3f71ff7a9b2cefa2d620c350dbde7cc08a3149",
 "res://data/maps/world_map_jianghu_layout_v14.tres":"3dfa1f251b5a5319b8cc6d6b902932fde6382470ae597c697e391252e98f2b3b"}
const ORIGINAL_LABEL: String="indoor remembered coordinate only changes route key, never world scaling"
var dependency_seen: Dictionary={}

class MigrationPhase extends "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":
 var original_assertions: Array[Dictionary]=[]
 var consumed: Dictionary={}
 var offline_configurations: Array[Dictionary]=[]
 func _check(ok: bool,label: String) -> void:
  # Preserve the original boolean and failure counter, without push_error.
  # This owner is a diagnostic collector, never a RELEASE phase result.
  checks+=1
  if not ok: failures+=1
  original_assertions.append({"passed":ok,"label":label})
 func _configure_ordinary(definition: SceneScript) -> bool:
  var ok: bool=super._configure_ordinary(definition)
  offline_configurations.append({"scene_id":String(definition.scene_id),"Field_valid":is_instance_valid(field),"Router_world_id":root.get_node("SceneRouter").call("is_world_map_scene",definition.scene_id),"legacy_live_context_used":release_legacy_context,"source_design_size":_native_size(Vector2(definition.map_layout.design_size)),"ordinary_size":_native_size(ordinary_size),"configured":ok})
  _check(not is_instance_valid(field) and not release_legacy_context and ordinary_size==Vector2(definition.map_layout.design_size),"original historic offline source reader never consumes an actual Field canvas")
  if ordinary_raw!=null:
   for layer: Dictionary in ordinary_raw.get("layers"): consumed[layer.path]=layer.sha256
  return ok
 func _native_size(value: Vector2) -> Dictionary:
  return {"type":typeof(value),"native_bytes_hex":var_to_bytes(value).hex_encode(),"text":str(value)}

func _native(value: Variant) -> Dictionary:
 return {"type":typeof(value),"native_bytes_hex":var_to_bytes(value).hex_encode(),"text":str(value)}

func _cache(router: Node,data: Dictionary) -> Dictionary:
 var cached_input: Dictionary=router.get("_city_preflight_input")
 var cached_result: Dictionary=router.get("_city_preflight_result")
 var matched: bool=data==cached_input and not cached_result.is_empty() and (data.has("current_field") or String(cached_result.get("current_field",""))=="")
 return {"matches_real_Router_condition":matched,"input":_native(cached_input),"result":_native(cached_result)}

func _original_input(old: SceneScript,version: int,target: String,pos: Vector2) -> Dictionary:
 var inner:=Vector2(.25,.75)
 return {"current_field":String(old.scene_id),"current_field_spawn":[pos.x,pos.y],"world_map_version":version,"portal_return_spawns":{target+"->"+String(old.scene_id):[pos.x,pos.y],String(old.scene_id)+"->"+target:[inner.x,inner.y]}}

func _route(prepared: Dictionary,from: String,to: String) -> Variant:
 var routes: Variant=prepared.get("portal_return_spawns")
 return routes.get(from+"->"+to) if routes is Dictionary else null

func _observe_prepare(subject: MigrationPhase,router: Node,data: Dictionary) -> Dictionary:
 var input_bytes: PackedByteArray=var_to_bytes(data)
 var navigation: Dictionary=router.call("get_navigation_state").duplicate(true)
 var active: Variant=router.get("_active_world_map_scene")
 var cache_before: Dictionary=_cache(router,data)
 var versions: Dictionary=router.call("_city_target_versions").duplicate(true)
 var prepared: Dictionary=router.call("prepare_v15_navigation",data,&"",subject.scene_id)
 _check(var_to_bytes(data)==input_bytes,"real pure prepare preserves its caller input bytes")
 _check(router.call("get_navigation_state")==navigation and router.get("_active_world_map_scene")==active,"real pure prepare never commits navigation or active world")
 return {"input":_native(data),"input_value":data.duplicate(true),"prepared":_native(prepared),"prepared_value":prepared.duplicate(true),"actual_target_versions":_native(versions),"cache_before":cache_before,"cache_after":_cache(router,data),"navigation_before":_native(navigation),"navigation_after":_native(router.call("get_navigation_state")),"active_before":_native(active),"active_after":_native(router.get("_active_world_map_scene")),"local_trace":_native(prepared.get("local_migration_trace")),"local_versions":_native(prepared.get("local_layout_versions"))}

func _dependencies(path: String,paths: Dictionary) -> void:
 if dependency_seen.has(path): return
 dependency_seen[path]=true
 if not paths.has(path): paths[path]="FIRST_ENDPOINT_REQUIRED"
 if not ResourceLoader.exists(path): return
 for item: String in ResourceLoader.get_dependencies(path):
  var pieces: PackedStringArray=item.split("::")
  var dependency: String=pieces[pieces.size()-1]
  if dependency.begins_with("res://"): _dependencies(dependency,paths)

func _run() -> void:
 var wanted:=PackedStringArray(SOURCE_DIAG.ARGS); wanted.append(FLAG)
 _check(OS.get_cmdline_user_args()==wanted,"explicit read-only world/city migration diagnostic, no filtered RELEASE")
 var env0: Dictionary=_env()
 _check(env0.driver=="WASAPI" and env0.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/exact engine/1x start")
 var endpoints: Dictionary={ACTUAL:_file(ACTUAL),BEFORE366:_file(BEFORE366),CITY_ENTRY_PATH:_file(CITY_ENTRY_PATH)}
 _check(endpoints[ACTUAL].get("sha256")==ACTUAL_SHA and endpoints[BEFORE366].get("sha256")==BEFORE366_SHA and endpoints[CITY_ENTRY_PATH].get("sha256")==CITY_ENTRY_SHA,"fixed ROOT358/366 provenance and independent city entry")
 if not errors.is_empty(): quit(1); return
 var baseline: Dictionary=_read(ACTUAL)
 var wrapper: Dictionary=_read(BEFORE366)
 var expected: Dictionary=SOURCE_DIAG.PINS.duplicate(true)
 for path: String in baseline.source_before:
  if baseline.source_before[path].get("exists")==true: expected[path]=baseline.source_before[path].sha256
 _check(wrapper.get("sources") is Array and wrapper.sources.size()==69,"complete original ROOT366 wrapper inventory")
 for row: Dictionary in wrapper.get("sources",[]):
  expected[ProjectSettings.localize_path(String(row.path).replace("\\","/"))]=String(row.sha256).to_lower()
 expected[ADAPTER_PATH]=ADAPTER_SHA; expected[BASE_PATH]=BASE_SHA
 expected[PARENT_PATH]=PARENT_SHA; expected[CURRENT_ARTIFACT]=CURRENT_ARTIFACT_SHA.to_lower()
 expected[ROUTER_PATH]=ROUTER_SHA; expected[CITY_PATH]=CITY_SHA
 for path: String in HISTORIC_PINS: expected[path]=HISTORIC_PINS[path]
 expected[ACTUAL]=ACTUAL_SHA; expected[BEFORE366]=BEFORE366_SHA; expected[CITY_ENTRY_PATH]=CITY_ENTRY_SHA
 # Four actual city catalogs are consumed by Router's real preflight. Bind
 # every asset once, not each repeated res:// reference in the large layout.
 var city_records: Dictionary={}
 for id: String in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]:
  var path: String=CITY_ROOT+id+"/art_contract.json"
  var record: Dictionary=_read(path); city_records[id]=record
  _check(record.get("canonical_scene_id")==id and record.get("asset_sha256") is Dictionary,"actual city manifest identity/catalog "+id)
  if not expected.has(path): expected[path]="FIRST_ENDPOINT_REQUIRED"
  for asset: String in record.get("asset_sha256",{}): expected[asset]=String(record.asset_sha256[asset]).to_lower()
 var paths: Dictionary=expected.duplicate(true)
 paths[get_script().resource_path]="SELF_CURRENT_BYTES"
 for path: String in OLD_PATHS.values(): _dependencies(path,paths)
 var before: Dictionary=_snapshot(paths,endpoints)
 for path: String in paths:
  _check(before[path].get("exists")==true and before[path].has("sha256"),"fresh unique readable consumed input "+path)
  if expected.has(path) and expected[path]!="FIRST_ENDPOINT_REQUIRED": _check(before[path].get("sha256")==expected[path],"exact fixed source input "+path)
 var players0: Dictionary=_players(); var slot0: Variant=root.get_node("SaveManager").get("active_slot")
 var router: Node=root.get_node("SceneRouter")
 var nav0: Dictionary=router.call("get_navigation_state").duplicate(true)
 var active0: Variant=router.get("_active_world_map_scene")
 if not errors.is_empty(): quit(1); return
 var output: String="res://build/joint_world_luoyang_20261003_qa/world_city_migration_diagnostic_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique diagnostic-only evidence directory")
 if not errors.is_empty(): quit(1); return
 var subject:=MigrationPhase.new()
 subject.owner_tree=self; subject.output=output; subject.requested_phase="READ_ONLY_ORIGINAL_MIGRATION_DIAGNOSIS_NOT_RELEASE"
 subject.before_saves=subject.call("_actual_saves")
 subject.source=_read(OLD_DIAG.SOURCE); subject.manifest=_read(OLD_DIAG.MANIFEST); subject.world=load(OLD_DIAG.WORLD)
 subject.oracle=RAW.new()
 _check(subject.oracle.call("configure",subject.world.map_layout)==true,"actual64 PNG/full17/source-solids oracle for independent world mapping")
 subject.call("_static_portals_and_spacing")
 _check(subject.failures==0 and subject.portals_by_id.size()==16,"actual16 author/runtime portal association and complete original static predicates")
 # Independent entry comes from the SHA-bound original manifest, not a
 # production materializer/migration result or the saved point under test.
 var entry_record: Dictionary=city_records["ch4_s0_luoyang_gate"]
 var entry_px: Vector2=Vector2(entry_record.entry_foot_px[0],entry_record.entry_foot_px[1])
 var city_size: Vector2=Vector2(entry_record.logical_size_px[0],entry_record.logical_size_px[1])
 _check(city_size==Vector2(3072,2048) and entry_px.is_finite(),"independent original authored city entry domain")
 var independent_entry: Vector2=entry_px/city_size
 var rows: Array[Dictionary]=[]; var changed_ids: Array[String]=[]
 var first_luoyang: Dictionary={}; var first_noncity: Dictionary={}; var first_noncity_target: String=""
 var old_resources: Dictionary={}
 if errors.is_empty():
  for version: int in [12,13,14]:
   var old: SceneScript=load(OLD_PATHS[version]) as SceneScript; old_resources[version]=old
   _check(old!=null and old.map_layout!=null and old.map_layout.portals.size()==16,"real immutable historic16 anchors v%d"%version)
   if old==null or old.map_layout==null: continue
   for portal: Dictionary in old.map_layout.portals:
    var id: String=portal.get("id","")
    var target: String=subject.DESTINATIONS.get(id,"")
    var pos: Vector2=portal.get("pos",Vector2(INF,INF))
    _check(subject.portals_by_id.has(id) and not target.is_empty(),"original fixture has exact current portal mapping "+id)
    var data: Dictionary=_original_input(old,version,target,pos)
    var paired: Dictionary=subject.call("_independent_historic_mapping",old,pos)
    var row: Dictionary=_observe_prepare(subject,router,data)
    var prepared: Dictionary=row.prepared_value
    var inner_actual: Variant=_route(prepared,String(subject.scene_id),target)
    var old_assertion: bool=typeof(inner_actual)==TYPE_VECTOR2 and inner_actual==Vector2(.25,.75)
    var entry_route_proven: bool=id=="luoyang" and version in [12,14]
    row.merge({"source_version":version,"id":id,"historic_resource":OLD_PATHS[version],"historic_resource_sha256":before[OLD_PATHS[version]].sha256,"independent_world":_native(paired),"actual_indoor":_native(inner_actual),"independent_city_entry_reference":_native(independent_entry),"entry_route_proven":entry_route_proven,"v13_city_semantic_correctness_judged":false,"original_line584_boolean":old_assertion})
    _check(prepared.get("world_map_version")==15 and prepared.get("current_field_id")==subject.scene_id and prepared.get("current_field_spawn")==paired.get("expected"),"actual world mapping agrees with original independent oracle v%d/%s"%[version,id])
    _check(_route(prepared,target,String(subject.scene_id))==paired.get("expected"),"world-side remembered coordinate remains independent exact mapping")
    if id!="luoyang":
     _check(typeof(inner_actual)==TYPE_VECTOR2 and inner_actual==Vector2(.25,.75),"noncity indoor remains exactly original identity v%d/%s"%[version,id])
     if first_noncity.is_empty(): first_noncity=data.duplicate(true); first_noncity_target=target
    elif entry_route_proven:
     _check(typeof(inner_actual)==TYPE_VECTOR2 and inner_actual==independent_entry,"v12/v14 actual city entry matches original SHA-bound authored entry")
    else:
     # Production's literal authored-world list contains world_map_jianghu_staging,
     # not this original world_map_jianghu_v13_staging. Observe its trace/result;
     # do not grant the unresolved v13 local migration semantic correctness.
     row["v13_authored_world_literal_match"]=String(old.scene_id) in ["world_map_jianghu","world_map_jianghu_staging","world_map_jianghu_v14","world_map_jianghu_v15"]
     _check(typeof(inner_actual)==TYPE_VECTOR2 and inner_actual.is_finite(),"v13 city actual output captured as finite native point, not semantic approval")
    if not old_assertion: changed_ids.append("v%d/%s"%[version,id])
    if id=="luoyang" and first_luoyang.is_empty(): first_luoyang=data.duplicate(true)
    rows.append(row)
 _check(rows.size()==48 and changed_ids.has("v12/luoyang") and changed_ids.has("v14/luoyang") and changed_ids.size() in [2,3],"all48 original inputs collected; v12/v14 city changes and45 noncity identities proved, v13 observed only")
 for changed: String in changed_ids: _check(changed in ["v12/luoyang","v13/luoyang","v14/luoyang"],"no noncity original indoor identity changed")
 var controls: Array[Dictionary]=[]
 if not first_noncity.is_empty():
  var control: Dictionary=first_noncity.duplicate(true)
  control.local_layout_versions={"ch4_s0_luoyang_gate":3}
  var row: Dictionary=_observe_prepare(subject,router,control)
  row["control"]="NONCITY_WITH_EXPLICIT_CITY_VERSION3"; controls.append(row)
  _check(_route(row.prepared_value,String(subject.scene_id),first_noncity_target)==Vector2(.25,.75) and (row.prepared_value.get("local_migration_trace",[]) as Array).is_empty(),"explicit city version ledger does not alter noncity indoor point or produce a city trace")
 if not first_luoyang.is_empty():
  var data: Dictionary=first_luoyang.duplicate(true)
  data.local_layout_versions={"ch4_s0_luoyang_gate":3}
  var route: String=String(data.current_field)+"->ch4_s0_luoyang_gate"
  data.portal_return_spawns[route]=[independent_entry.x,independent_entry.y]
  for repeat_index in 2:
   var row: Dictionary=_observe_prepare(subject,router,data)
   row["control"]="EXPLICIT_LOCAL3_REPEAT_%d"%repeat_index; controls.append(row)
   _check(_route(row.prepared_value,String(subject.scene_id),"ch4_s0_luoyang_gate")==independent_entry,"explicit local3 city point is not migrated again")
   var trace: Variant=row.prepared_value.get("local_migration_trace")
   _check(trace is Array and trace.size()==1 and trace[0].get("source_version")==3 and trace[0].get("target_version")==3 and trace[0].get("reason")=="same_version_local_clearance","actual trace proves local3 repeat rather than legacy remapping")
  for invalid: Variant in [-1,0,2,4,1.5,"3",true]:
   var bad: Dictionary=first_luoyang.duplicate(true)
   bad.local_layout_versions={"ch4_s0_luoyang_gate":invalid}
   var row: Dictionary=_observe_prepare(subject,router,bad)
   row["control"]="INVALID_LOCAL_VERSION"; row["invalid_version"]=_native(invalid); controls.append(row)
   _check(row.prepared_value.is_empty(),"invalid local city version is refused without state commit: "+str(invalid))
 # Execute the untouched parent method, including its free-coordinate cases,
 # invalid world versions, original failure booleans and original report write.
 var parent_start: int=subject.original_assertions.size()
 var parent_fail_start: int=subject.failures
 var original_executed: bool=errors.is_empty()
 if original_executed: subject.call("_migration_prepare_phase")
 var parent_assertions: Array=subject.original_assertions.slice(parent_start).duplicate(true)
 var original_rejections: Array=[]
 for assertion: Dictionary in parent_assertions:
  if assertion.passed!=true: original_rejections.append(assertion)
 _check(original_executed and original_rejections.size()==changed_ids.size() and original_rejections.size()>=2 and subject.failures-parent_fail_start==original_rejections.size(),"original parent executes and preserves its actual observed indoor-domain refusals, not a presumed v13 outcome")
 for rejection: Dictionary in original_rejections: _check(rejection.label==ORIGINAL_LABEL,"no unknown parent failure is hidden")
 for path: String in subject.consumed: _check(before.has(path) and before[path].get("sha256")==subject.consumed[path],"all consumed historic navigation present in unique before guard "+path)
 _check(subject.oracle.call("verify_sources")==true,"all64 actual navigation source SHA remain exact")
 if subject.ordinary_raw!=null:
  _check(subject.ordinary_raw.call("verify_sources")==true,"last actual historic raw source remains exact")
  subject.ordinary_raw.call("release"); subject.ordinary_raw=null
 subject.oracle.call("release"); subject.oracle=null
 var after: Dictionary=_snapshot(paths); var env1: Dictionary=_env()
 _check(before==after and _players()==players0 and root.get_node("SaveManager").get("active_slot")==slot0,"unique complete source bytes/SHA/mtime and15 player files/slot unchanged")
 _check(router.call("get_navigation_state")==nav0 and router.get("_active_world_map_scene")==active0,"entire pure diagnosis leaves Router navigation/active world unchanged")
 _check(env1.driver=="WASAPI" and env1.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/exact engine/1x finish")
 var report: Dictionary={"schema":1,"scope":"READ_ONLY_WORLD_CITY_MIGRATION_DIAGNOSTIC_NO_FIELD_NOT_RELEASE","checks":checks,"failures":errors.size(),"errors":errors,"original48":rows,"changed_original584_ids":changed_ids,"controls":controls,"independent_city_entry_px":_native(entry_px),"independent_city_entry_uv":_native(independent_entry),"v13_city_semantic_correctness_judged":false,"all48_migration_pass_claimed":false,"original_parent_executed":original_executed,"original_parent_assertions":parent_assertions,"original_parent_rejections":original_rejections,"original_parent_failures":subject.failures-parent_fail_start,"original_parent_passed":false,"offline_source_configurations":subject.offline_configurations,"original_parent_evidence":_read(output+"migration_prepare.json") if FileAccess.file_exists(output+"migration_prepare.json") else {},"navigation_before":_native(nav0),"navigation_after":_native(router.call("get_navigation_state")),"source_before":before,"source_after":after,"unique_source_count":paths.size(),"players_before":players0,"players_after":_players(),"environment_before":env0,"environment_after":env1,"source_complete":false,"release_complete":false,"Field_executed":false,"formal_approval":false,"output":output}
 _check(subject.call("_write_json","diagnostic.json",report)==true,"unique complete pure diagnostic report checked readback")
 print("V9E_WORLD_CITY_MIGRATION_DIAGNOSTIC ",JSON.stringify({"checks":checks,"failures":errors.size(),"original_parent_failures":original_rejections.size(),"original48":rows.size(),"changed584":changed_ids,"output":output,"original_parent_passed":false,"release_complete":false}))
 subject=null; old_resources.clear()
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)
