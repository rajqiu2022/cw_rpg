extends SceneTree
## Diagnostic acquisition only. The inherited three target-identity FAILs are
## expected evidence, NEVER converted to portal/Field/RELEASE approval.
const BASE=preload("res://tests/test_joint_v9e_portal_arrival_return_diagnostic_20261008.gd")
const RAW=preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const CONTEXT=preload("res://tests/helpers/joint_v15_v9e_source_context_oracle.gd")
const OUTSKIRTS=preload("res://scripts/world/outskirts_native_contract.gd")
const CANONICAL: String="res://data/scenes/linxi_village_scrollmap.tres"
const LAYOUT: String="res://data/maps/linxi_village_scrollmap_layout_v1.tres"
const CONTRACT: String="res://art/maps/world_map_v15_outskirts_complete_v5_retry1/bamboo/art_contract.json"
const STRIP: String="res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_down_25d_4f.png"
const PRIOR: String="res://build/joint_world_luoyang_20261003_qa/legacy_actual_canvas_roundtrips_1791437189_14631568_87916/limited_roundtrips.json"
const ABORT: String="res://build/joint_world_luoyang_20261003_qa/357_v9e_candidate_complete_release_headless_legacy_canvas_20261008/known_failure_abort.json"
const EXPECTED_FAILURE: String="normal unchanged target identity; only current SHA-bound exact candidate city clone allowed: linxi_village"
const ARGS: Array[String]=["--candidate-before-cutover","--luoyang-v3-candidate","--outskirts-candidate-preview","--outskirts-complete-v5"]
const PINS: Dictionary={
 "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":"766f13443af68510914555211778e88bee6b53ac81328dad1576386dfc8b2a3e",
 "res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd":"16a66f74eba277c9dcf7c1a6801bb5183d0fedf363a3e6fc3805bc41e7474970",
 "res://scripts/world/outskirts_native_contract.gd":"0a6ebb105751b8beb2ff17f709672fcc7c07f71bdfad90d3750cfffd72127f87",
 "res://scripts/field/field_walkable_controller.gd":"b3301d6064e332e519b0fc3b4daed880ec3d77d98f2c744933b5d7077b9eb8ef",
 "res://scripts/autoload/scene_router.gd":"f3ead7459632188350e1e3383ee915c83b71c1b86d36dadf718bd338a4324eca",
 CANONICAL:"4b733d3ff600d0117573aa41c1e943d49a0d9372fb5de956a112f81dfdcc9819",
 LAYOUT:"6c859cff6ef58d3440a087d34412edbbd4dcb47d9dfc8c921796d0201dd13650",
 CONTRACT:"6ad6eb7473cee3cd97db997adee735ac68c82189a1df1ebbdd08f52cf88fb768",
 PRIOR:"199f4feeee3f3f485e03469c95253a72d2c753135ece895c7937bccb06e2e22a",
 ABORT:"26cfb530266abc2a472ad2ebc357c96cf3d1e8b97e2f9306ec268dd0d68f6276"
}

class DiagnosticPhase extends "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":
 var attempts: Array[Dictionary]=[]
 var active: Dictionary={}
 var labels: Array[String]=[]
 var observer: Callable
 func _check(ok: bool,label: String) -> void:
  if not ok: labels.append(label)
  super._check(ok,label)
 func _wait_field(id: StringName) -> bool:
  var entered: bool=await super._wait_field(id)
  if entered and id==&"linxi_village_scrollmap":
   active["identity"]=observer.call(field.get("_current_scene"))
  return entered
 func _portal_roundtrip(id: String,mode: String,measurement: Dictionary) -> void:
  var start: int=failures
  var label_start: int=labels.size()
  active={"id":id,"mode":mode}
  await super._portal_roundtrip(id,mode,measurement)
  active["original_failure_delta"]=failures-start
  active["original_failure_labels"]=labels.slice(label_start)
  active["original_return_executed"]=false
  active["original_identity_predicate_unchanged"]=true
  attempts.append(active.duplicate(true))
  _check(_write_json("identity_%s.json"%mode,active),"unique identity acquisition checked readback")

var checks: int=0
var errors: Array[String]=[]
var phase: DiagnosticPhase
var cached: SceneScript
var cached_before: Dictionary={}
var expected_post: Dictionary={}
var expected_portal: Dictionary={}
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok: errors.append(label); push_error("[SOURCE ENTRY IDENTITY DIAGNOSTIC] "+label)
 return ok
func _read(path: String) -> Dictionary:
 var parser:=JSON.new()
 return parser.data if parser.parse(FileAccess.get_file_as_string(path))==OK and parser.data is Dictionary else {}
func _sha(bytes: PackedByteArray) -> String:
 var context:=HashingContext.new(); context.start(HashingContext.HASH_SHA256); context.update(bytes)
 return context.finish().hex_encode()
func _file(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {"exists":false}
 var file:=FileAccess.open(path,FileAccess.READ)
 if file==null: return {"exists":true,"readable":false}
 var size: int=file.get_length(); file.close()
 return {"exists":true,"bytes":size,"sha256":FileAccess.get_sha256(path),"mtime":FileAccess.get_modified_time(path)}
func _snapshot(paths: Dictionary,endpoint_cache: Dictionary={}) -> Dictionary:
 var result: Dictionary={}
 for path: String in paths: result[path]=endpoint_cache[path] if endpoint_cache.has(path) else _file(path)
 return result
func _players() -> Dictionary:
 var result: Dictionary={}
 for slot in 5:
  for suffix: String in ["",".bak",".tmp"]: result["user://save_%d.json%s"%[slot,suffix]]=_file("user://save_%d.json%s"%[slot,suffix])
 return result
func _env() -> Dictionary:
 return {"driver":AudioServer.get_driver_name(),"exe_sha256":FileAccess.get_sha256(OS.get_executable_path()),"display":DisplayServer.get_name(),"mix_rate":AudioServer.get_mix_rate(),"device":AudioServer.output_device,"latency":AudioServer.get_output_latency(),"source_version_equivalence":false}
func _value(value: Variant) -> Dictionary:
 var result: Dictionary={"variant_type":typeof(value),"native_text":str(value)}
 if value is Resource:
  result.merge({"class":value.get_class(),"instance_id":str(value.get_instance_id()),"resource_path":value.resource_path,"disk_file":value.resource_path.get_slice("::",0)})
 elif value is Object:
  result.merge({"class":value.get_class(),"instance_id":str(value.get_instance_id())})
 else:
  var bytes: PackedByteArray=var_to_bytes(value)
  result["native_bytes_sha256"]=_sha(bytes)
  result["native_bytes_hex"]=bytes.hex_encode()
 return result
func _storage(resource: Resource) -> Dictionary:
 var properties: Dictionary={}; var metadata: Dictionary={}
 for property: Dictionary in resource.get_property_list():
  if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0: continue
  properties[String(property.name)]=_value(resource.get(property.name))
 for name: StringName in resource.get_meta_list(): metadata[String(name)]=_value(resource.get_meta(name))
 return {"instance_id":str(resource.get_instance_id()),"resource_path":resource.resource_path,"class":resource.get_class(),"properties":properties,"metadata":metadata}
func _semantic_equal(a: Variant,b: Variant) -> bool:
 if typeof(a)!=typeof(b): return false
 if a is Resource: return b is Resource and a.get_class()==b.get_class() and a.resource_path==b.resource_path
 if a is Dictionary:
  if a.size()!=b.size(): return false
  for key: Variant in a:
   if not b.has(key) or not _semantic_equal(a[key],b[key]): return false
  return true
 if a is Array:
  if a.size()!=b.size(): return false
  for index in a.size():
   if not _semantic_equal(a[index],b[index]): return false
  return true
 return var_to_bytes(a)==var_to_bytes(b)
func _diff(a: Resource,b: Resource,exceptions: Array[String]) -> Array:
 var result: Array=[]; var names: Dictionary={}
 for property: Dictionary in a.get_property_list():
  if (int(property.usage)&PROPERTY_USAGE_STORAGE)!=0: names[String(property.name)]=true
 for property: Dictionary in b.get_property_list():
  if (int(property.usage)&PROPERTY_USAGE_STORAGE)!=0: names[String(property.name)]=true
 for name: String in names:
  if name in exceptions: continue
  if not _semantic_equal(a.get(name),b.get(name)): result.append({"name":name,"canonical":_value(a.get(name)),"actual":_value(b.get(name))})
 return result
func _resource_pair(scene: SceneScript) -> Dictionary:
 return {"scene":_storage(scene),"layout":_storage(scene.map_layout)}
func _v(value: Array) -> Vector2: return Vector2(value[0],value[1])
func _expected_append(canonical: SceneScript,data: Dictionary) -> void:
 # Independent frozen writer math, not OUTSKIRTS.materialize/_runtime_object.
 var source_size: Vector2=Vector2(canonical.map_layout.design_size)
 var source_foot:=Vector2(.55,.53)
 var source_spawn: Vector2=source_foot
 var strip: Texture2D=load(STRIP)
 if not canonical.actor_positions_are_feet:
  source_spawn-=Vector2(0,float(strip.get_height())*.945*canonical.player_visual_scale*.45)/source_size
 var post: Dictionary=data.source_entry_object.duplicate(true)
 var old_foot: Vector2=_v(post.world_foot_px)
 var foot: Vector2=source_foot*source_size+Vector2(32,0)
 if post.get("blocking")==true: post.physical_center_px=foot+_v(post.physical_center_px)-old_foot
 var size: Vector2=_v(post.render_size_px); var uv: Vector2=_v(post.foot_uv)
 var center: Vector2=foot-(uv-Vector2(.5,.5))*size
 expected_post={"id":"outskirts_bamboo_routepost","texture":post.texture,"pos":center/source_size,"render_size_px":size,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/source_size.y,"interaction_action":"outskirts_entry:bamboo","interaction_size":Vector2(64,48)/source_size,"interaction_offset":source_foot-center/source_size}
 if post.get("blocking")==true:
  expected_post["collision_size"]=_v(post.collision_size_px)/source_size
  expected_post["collision_offset"]=(post.physical_center_px-center)/source_size
 expected_portal={"id":"outskirts_bamboo_entrance","label":"前往竹溪林","destination_name":"竹溪林","pos":source_foot,"source_foot_pos":source_foot,"source_spawn_pos":source_spawn,"size":Vector2(64,48)/source_size,"target_scene":"openworld_v15_bamboo_outskirts","target_pos":_v(data.return_foot_px)/Vector2(1536,1024),"marker_offset":Vector2(0,18)/source_size,"show_destination_label":true}
func _observe(actual: SceneScript) -> Dictionary:
 var canonical: SceneScript=ResourceLoader.load(CANONICAL,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
 var independent_layout: WalkableMapLayout=ResourceLoader.load(LAYOUT,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
 if not _check(actual!=null and canonical!=null and canonical.map_layout!=null and independent_layout!=null,"actual/canonical/independent external layout exist"): return {}
 var scene_diff: Array=_diff(canonical,actual,["map_layout","resource_path"])
 var layout_diff: Array=_diff(independent_layout,actual.map_layout,["visual_objects","portals","resource_path"])
 var objects: Array=actual.map_layout.visual_objects; var portals: Array=actual.map_layout.portals
 var original_objects: Array=independent_layout.visual_objects; var original_portals: Array=independent_layout.portals
 var objects_ok: bool=objects.size()==original_objects.size()+1
 var portals_ok: bool=portals.size()==original_portals.size()+1
 for index in original_objects.size(): objects_ok=objects_ok and _semantic_equal(objects[index],original_objects[index])
 for index in original_portals.size(): portals_ok=portals_ok and _semantic_equal(portals[index],original_portals[index])
 var actual_post: Variant=objects.back() if not objects.is_empty() else null
 var actual_portal: Variant=portals.back() if not portals.is_empty() else null
 var exact_post: bool=_semantic_equal(actual_post,expected_post)
 var exact_portal: bool=_semantic_equal(actual_portal,expected_portal)
 var cached_now: Dictionary=_resource_pair(cached)
 _check(cached_now==cached_before,"cached canonical scene/layout/metadata unchanged through real arrival")
 _check(_diff(independent_layout,canonical.map_layout,[]).is_empty(),"fresh external layout independently agrees with canonical loader dependency")
 _check(scene_diff.is_empty() and layout_diff.is_empty(),"all original scene/layout storage fields unchanged except explicit append and resource path")
 _check(_storage(canonical).metadata==_storage(actual).metadata and _storage(independent_layout).metadata==_storage(actual.map_layout).metadata,"all canonical scene/layout metadata preserved")
 _check(objects_ok and portals_ok and exact_post and exact_portal,"only original prefixes plus independently reconstructed unique source-entry post/portal")
 _check(actual.scene_id==&"linxi_village_scrollmap" and actual.resource_path.is_empty(),"actual observed exact target ID and empty clone resource path")
 _check(not is_same(actual,canonical) and not is_same(actual.map_layout,canonical.map_layout) and not is_same(actual.map_layout,cached.map_layout),"actual scene and external layout are isolated resources")
 _check(not is_same(objects,cached.map_layout.visual_objects) and not is_same(portals,cached.map_layout.portals),"actual appended arrays not shared with cached source")
 return {"actual":_resource_pair(actual),"fresh_canonical":_resource_pair(canonical),"independent_external_layout":_storage(independent_layout),"cached_canonical":cached_now,"scene_storage_differences_excluding_layout_and_path":scene_diff,"layout_storage_differences_excluding_two_append_arrays_and_path":layout_diff,"canonical_object_count":original_objects.size(),"actual_object_count":objects.size(),"canonical_portal_count":original_portals.size(),"actual_portal_count":portals.size(),"original_object_prefix_exact":objects_ok,"original_portal_prefix_exact":portals_ok,"actual_appended_post":_value(actual_post),"actual_appended_portal":_value(actual_portal),"independent_expected_post":_value(expected_post),"independent_expected_portal":_value(expected_portal),"append_native_exact":exact_post and exact_portal,"canonical_resource_path":canonical.resource_path,"actual_resource_path":actual.resource_path,"production_contract_root":OUTSKIRTS.active_root(),"contract_path":CONTRACT,"contract_sha256":PINS[CONTRACT],"production_materialize_used_as_expected":false}
func _discover(paths: Dictionary) -> void:
 # Discover references without hashing repeated occurrences. Endpoint snapshots
 # compute actual bytes/SHA/mtime once per UNIQUE path, fresh again at the end.
 var regex:=RegEx.new(); regex.compile("res://[^\"\\s<>]+")
 var queue: Array[String]=[CANONICAL,LAYOUT,"res://scripts/world/outskirts_native_contract.gd","res://scripts/field/player.gd",CONTRACT]
 var seen: Dictionary={}
 while not queue.is_empty():
  var path: String=queue.pop_back()
  if seen.has(path): continue
  seen[path]=true
  if not FileAccess.file_exists(path): continue
  if not paths.has(path): paths[path]="DISCOVERED_CURRENT_CONSUMPTION"
  if path.get_extension() not in ["gd","tres","tscn","json"]: continue
  for match: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path)):
   var dependency: String=match.get_string()
   if not dependency.begins_with("res://build/") and FileAccess.file_exists(dependency) and not seen.has(dependency): queue.append(dependency)
func _run() -> void:
 _check(OS.get_cmdline_user_args()==PackedStringArray(ARGS),"exact complete candidate environment, limited three-entry acquisition")
 var env0: Dictionary=_env()
 _check(env0.driver=="WASAPI" and env0.exe_sha256==BASE.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen executable/1x start")
 var prior_endpoint: Dictionary=_file(PRIOR)
 _check(prior_endpoint.get("sha256")==PINS[PRIOR],"fixed prior source ownership/provenance report")
 if not errors.is_empty(): quit(1); return
 var prior: Dictionary=_read(PRIOR)
 var expected: Dictionary=BASE.PINS.duplicate(true)
 for path: String in prior.source_before:
  if prior.source_before[path].get("exists")==true: expected[path]=prior.source_before[path].sha256
 for path: String in PINS: expected[path]=PINS[path]
 var paths: Dictionary=expected.duplicate(true)
 paths[get_script().resource_path]="SELF_CURRENT_BYTES"
 paths[STRIP]="CURRENT_SOURCE_SPAWN_STRIP"
 _discover(paths)
 var before: Dictionary=_snapshot(paths,{PRIOR:prior_endpoint})
 for path: String in expected: _check(before[path].get("sha256")==expected[path],"fresh unique fixed source SHA "+path)
 var players0: Dictionary=_players(); var slot0: Variant=root.get_node("SaveManager").get("active_slot")
 if not errors.is_empty(): quit(1); return
 var data: Dictionary=_read(CONTRACT)
 _check(data.get("scene_id")=="openworld_v15_bamboo_outskirts" and data.get("logical_size_px")==[1536.,1024.] and data.get("source_entry_object") is Dictionary,"actual fixed complete bamboo writer contract")
 cached=load(CANONICAL) as SceneScript
 _check(cached!=null and cached.map_layout!=null and ResourceLoader.exists(STRIP),"cached canonical and original source spawn strip available")
 if not errors.is_empty(): quit(1); return
 cached_before=_resource_pair(cached)
 _expected_append(cached,data)
 var frozen: Dictionary=_read(BASE.FROZEN); var source: Dictionary=_read(BASE.SOURCE); var manifest: Dictionary=_read(BASE.MANIFEST)
 var context: RefCounted=CONTEXT.new()
 _check(context.call("validate_v9c_world_pins",frozen.get("execution_sha256",{}),frozen.get("v9c_artifact_sha256",{}),manifest,frozen.get("derived_geometry_inputs",{}))==true,"original frozen execution/artifact/derived binding preflight")
 context=null
 var world: SceneScript=load(BASE.WORLD)
 _check(world!=null and world.map_layout!=null and world.map_layout.walkable_mask_tiles.size()==64,"actual complete candidate64nav, no artifact rerun")
 if not errors.is_empty(): quit(1); return
 var output: String="res://build/joint_world_luoyang_20261003_qa/source_entry_identity_diagnostic_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique diagnostics-only evidence directory")
 if not errors.is_empty(): quit(1); return
 phase=DiagnosticPhase.new(); phase.owner_tree=self; phase.output=output; phase.requested_phase="THREE_SOURCE_ENTRY_IDENTITY_DIAGNOSIS_NOT_RELEASE"; phase.observer=_observe
 phase.before_saves=phase.call("_actual_saves"); phase.prior_navigation=root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
 phase.prior_active=StringName(root.get_node("SceneRouter").get("_active_world_map_scene")); phase.prior_slot=int(slot0)
 phase.source=source; phase.manifest=manifest; phase.world=world; phase.execution_sha256=frozen.execution_sha256.duplicate(true); phase.v9c_artifact_sha256=frozen.v9c_artifact_sha256.duplicate(true); phase.derived_geometry_inputs=frozen.derived_geometry_inputs.duplicate(true)
 phase.oracle=RAW.new()
 _check(phase.oracle.call("configure",world.map_layout)==true,"original complete17/source-solid64nav oracle")
 phase.call("_read_independent_door_review")
 if phase.failures==0 and errors.is_empty():
  phase.call("_ensure_runtime_fixture")
  var measurement: Dictionary=phase.call("_source_door","linxi_village")
  _check(not measurement.is_empty(),"exact original SHA-bound linxi doorstep")
  if phase.failures==0 and errors.is_empty():
   for mode: String in ["space","door_mouse","arrow"]: await phase._portal_roundtrip("linxi_village",mode,measurement)
 _check(phase.attempts.size()==3 and phase.failures==3 and phase.labels.size()==3 and phase.actual_portal_roundtrips.is_empty(),"three original FAILs retained, no successful return/portal claim")
 for attempt: Dictionary in phase.attempts:
  _check(attempt.get("original_failure_delta")==1 and attempt.get("original_failure_labels")==[EXPECTED_FAILURE] and attempt.has("identity"),"complete real target identity acquisition with exactly original failure "+str(attempt.mode))
 var attempts: Array=phase.attempts.duplicate(true); var labels: Array=phase.labels.duplicate()
 await phase.call("_finish")
 _check(phase.failures==3 and phase.result.get("source_complete")==false and phase.result.get("release_complete")==false,"original cleanup adds no failure and grants no completion")
 _check(_resource_pair(cached)==cached_before,"cached canonical scene/layout/metadata unchanged after all three original flows and cleanup")
 var after: Dictionary=_snapshot(paths); var env1: Dictionary=_env()
 _check(after==before and _players()==players0 and root.get_node("SaveManager").get("active_slot")==slot0,"all unique source bytes/SHA/mtime and15 normal player files/slot unchanged")
 _check(env1.driver=="WASAPI" and env1.exe_sha256==BASE.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen executable/1x finish")
 var report: Dictionary={"schema":1,"scope":"THREE_REAL_SOURCE_ENTRY_IDENTITY_ACQUISITIONS_ORIGINAL_FAILS_NOT_RELEASE","checks":checks,"diagnostic_failures":errors.size(),"diagnostic_errors":errors,"original_phase_failures":phase.failures,"original_failure_labels":labels,"attempts":attempts,"cached_canonical_before":cached_before,"cached_canonical_after":_resource_pair(cached),"source_before":before,"source_after":after,"unique_source_count":paths.size(),"players_before":players0,"players_after":_players(),"environment_before":env0,"environment_after":env1,"preserved_ROOT357_abort_path":ABORT,"preserved_ROOT357_abort_sha256":PINS[ABORT],"stderr_review_required":true,"expected_stderr_errors":[EXPECTED_FAILURE,EXPECTED_FAILURE,EXPECTED_FAILURE],"any_other_ERROR_SCRIPT_WARNING_requires_root_rejection":true,"source_complete":false,"release_complete":false,"formal_approval":false,"output":output}
 _check(phase.call("_write_json","diagnostic.json",report)==true,"unique complete diagnosis checked JSON readback")
 print("V9E_SOURCE_ENTRY_IDENTITY_DIAGNOSTIC ",JSON.stringify({"checks":checks,"diagnostic_failures":errors.size(),"errors":errors,"original_phase_failures":phase.failures,"attempts":attempts.size(),"unique_source_count":paths.size(),"output":output,"release_complete":false}))
 phase=null; cached=null; world=null
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)
