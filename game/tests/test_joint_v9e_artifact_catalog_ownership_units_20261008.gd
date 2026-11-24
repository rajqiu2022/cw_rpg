extends "res://tests/test_joint_v9e_source_entry_identity_roundtrips_20261008.gd"
## Causal pure ownership test, NOT full artifact/Field/input/visual acceptance.
## Actual original run(empty final pins) -> original validation refusal -> finish.
## Expected original failures are retained by the owner, not reset to zero.
const CURRENT_PATH: String="res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
const CURRENT_SHA: String="77af1707d32517fa1c7b9fecdfe84deefc6b8ef000f8bd82947beeb9ff8d7b9e"
const OLD_PATH: String="res://build/joint_world_luoyang_20261003_qa/362_v9e_candidate_complete_release_headless_strict_source_entry_20261008/joint_v15_world_artifact_semantics_v9e_probe.gd"
const OLD_SHA: String="c9d793a97b3b42f364b4888a64c079e523d8e4a6645ddaf5a3aa9d2587b8f3f1"
const ENTRY_PATH: String="res://tests/test_joint_v9e_source_entry_identity_roundtrips_20261008.gd"
const ENTRY_SHA: String="c706826e1bc8e1ab69eb0cd9306bc5de4ef2bf4baa0cdd1125c856f6c0879630"
const FLAG: String="--diagnose-artifact-catalog-ownership"
const REFUSAL: String="world actual artifact: explicit exact five v8 final paths/current 64hex SHAs; empty/PENDING/unknown/regional reject"

class TestOwner extends "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":
 var original_assertions: Array[Dictionary]=[]
 var watched_probe: RefCounted
 var mutate_owned_nested: bool=false
 var mutation_executed: bool=false
 func _check(ok: bool,label: String) -> void:
  checks+=1
  if not ok: failures+=1
  original_assertions.append({"ok":ok,"label":label})
  # Test-only controlled memory mutation of PROBE-owned fixture at the genuine
  # early-refusal callback, after original run has acquired its actual catalog.
  # No production source or manifest file is altered; no _finish override.
  if mutate_owned_nested and not ok and label==REFUSAL and watched_probe!=null:
   var owned: Dictionary=watched_probe.get("catalog")
   var fixture: Dictionary=owned.get("__ownership_nested_fixture",{})
   if fixture.get("array") is Array and fixture.get("typed") is Dictionary:
    fixture.array[0]["value"]=2.
    fixture.typed["value"]=2.
    fixture[&"typed_key"]=PackedFloat64Array([2.])
    mutation_executed=true

var causal_records: Array[Dictionary]=[]
func _bytes_sha(bytes: PackedByteArray) -> String:
 var h:=HashingContext.new()
 if h.start(HashingContext.HASH_SHA256)!=OK or h.update(bytes)!=OK: return ""
 return h.finish().hex_encode()
func _storage_bytes(resource: Resource) -> PackedByteArray:
 var fields: Dictionary={}
 for property: Dictionary in resource.get_property_list():
  if (int(property.usage)&PROPERTY_USAGE_STORAGE)!=0: fields[property.name]=resource.get(property.name)
 var metadata: Dictionary={}
 for key: StringName in resource.get_meta_list(): metadata[key]=resource.get_meta(key)
 return var_to_bytes({"fields":fields,"metadata":metadata})
func _binding_count(owner: RefCounted) -> int:
 var count: int=0
 for id: String in TestOwner.DESTINATIONS:
  if not (owner.call("_release_landmark_binding",id) as Dictionary).is_empty(): count+=1
 return count
func _case(label: String,script_path: String,old_control: bool,nested: bool,output: String) -> void:
 var owner:=TestOwner.new()
 owner.owner_tree=self; owner.source=_read(OLD_DIAG.SOURCE); owner.manifest=_read(OLD_DIAG.MANIFEST)
 owner.world=ResourceLoader.load(OLD_DIAG.WORLD,"",ResourceLoader.CACHE_MODE_IGNORE)
 owner.world.map_layout=ResourceLoader.load("res://data/maps/world_map_jianghu_layout_v15.tres","",ResourceLoader.CACHE_MODE_IGNORE)
 owner.output=output+label+"/"
 _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(owner.output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(owner.output))==OK,"unique actual early-return evidence "+label)
 if nested:
  var typed: Dictionary[String,float]={"value":1.}
  var array: Array[Dictionary]=[{"value":1.}]
  owner.manifest.asset_sha256["__ownership_nested_fixture"]={"typed":typed,"array":array,"string_key":PackedFloat64Array([1.])}
 var original_manifest: Dictionary=owner.manifest.duplicate(true)
 var before: PackedByteArray=var_to_bytes(owner.manifest)
 var catalog_before: PackedByteArray=var_to_bytes(owner.manifest.asset_sha256)
 var source_before: PackedByteArray=var_to_bytes(owner.source)
 var scene_before: PackedByteArray=_storage_bytes(owner.world)
 var layout_before: PackedByteArray=_storage_bytes(owner.world.map_layout)
 var binding_before: int=_binding_count(owner)
 var script: GDScript=ResourceLoader.load(script_path,"",ResourceLoader.CACHE_MODE_IGNORE)
 _check(script!=null and script.can_instantiate(),"actual original/current artifact script instantiates "+label)
 if script==null or not script.can_instantiate(): return
 var probe: RefCounted=script.new()
 owner.watched_probe=probe; owner.mutate_owned_nested=nested
 probe.call("configure_final_pins",{})
 var result: Dictionary=probe.call("run",owner)
 owner.watched_probe=null
 var binding_after: int=_binding_count(owner)
 var after: PackedByteArray=var_to_bytes(owner.manifest)
 var expected_old: Dictionary=original_manifest.duplicate(true); expected_old.asset_sha256={}
 var rejected: Array[Dictionary]=[]
 for assertion: Dictionary in owner.original_assertions:
  if not assertion.ok: rejected.append(assertion)
 _check(result.get("complete")==false and result.get("failures")==1 and owner.failures==1 and rejected.size()==1 and rejected[0].label==REFUSAL,"actual run preserved sole original bad-final-pins refusal and real finish "+label)
 _check(probe.get("geometry")==null and probe.get("phase")==null and (probe.get("catalog") as Dictionary).is_empty(),"real original finish ran, released helper and cleared owned working catalog "+label)
 _check(binding_before==16 and binding_after==(0 if old_control else 16),"real16 binding reproduces old16to0 versus owned16to16 "+label)
 _check(after==var_to_bytes(expected_old) if old_control else after==before,"complete owner manifest native/type/key bytes exact expected lifecycle "+label)
 _check(var_to_bytes(owner.source)==source_before and _storage_bytes(owner.world)==scene_before and _storage_bytes(owner.world.map_layout)==layout_before,"actual source and scene/layout storage metadata untouched "+label)
 if not old_control:
  _check(var_to_bytes(owner.manifest.asset_sha256)==catalog_before,"all catalog keys/types/native values remain exact, no disk reload restore "+label)
 if nested:
  _check(owner.call("_release_source_entry_equal",owner.manifest.asset_sha256.__ownership_nested_fixture,original_manifest.asset_sha256.__ownership_nested_fixture)==true,"small deep ownership fixture recursive semantic/type equality "+label)
  _check(owner.mutation_executed and owner.manifest.asset_sha256.__ownership_nested_fixture.typed.get_typed_key_builtin()==TYPE_STRING and owner.manifest.asset_sha256.__ownership_nested_fixture.typed.get_typed_value_builtin()==TYPE_FLOAT and owner.manifest.asset_sha256.__ownership_nested_fixture.array.get_typed_builtin()==TYPE_DICTIONARY,"deep working-copy nested mutation executed while owner typed fixture stayed intact "+label)
 causal_records.append({"label":label,"script_path":script_path,"script_sha256":FileAccess.get_sha256(script_path),"old_control":old_control,"nested_memory_fixture_not_actual_art":nested,"run_result":result,"original_owner_failures":owner.failures,"original_assertions":owner.original_assertions,"binding_before":binding_before,"binding_after":binding_after,"manifest_native_sha_before":_bytes_sha(before),"manifest_native_sha_after":_bytes_sha(after),"catalog_count_before":original_manifest.asset_sha256.size(),"catalog_count_after":owner.manifest.asset_sha256.size(),"deep_fixture_mutation_executed":owner.mutation_executed,"complete_artifact_executed":false,"Field_executed":false})
 probe=null; owner=null; script=null

func _run() -> void:
 var wanted:=PackedStringArray(SOURCE_DIAG.ARGS); wanted.append(FLAG)
 _check(OS.get_cmdline_user_args()==wanted,"explicit causal pure-unit arguments, no Field")
 var env0: Dictionary=_env()
 _check(env0.driver=="WASAPI" and env0.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen engine/1x start")
 var baseline_endpoint: Dictionary=_file(ACTUAL)
 _check(baseline_endpoint.get("sha256")==ACTUAL_SHA,"fixed ROOT358 input provenance retained")
 if not errors.is_empty(): quit(1); return
 var baseline: Dictionary=_read(ACTUAL)
 var expected: Dictionary=SOURCE_DIAG.PINS.duplicate(true)
 for path: String in baseline.source_before:
  if baseline.source_before[path].get("exists")==true: expected[path]=baseline.source_before[path].sha256
 expected[CURRENT_PATH]=CURRENT_SHA; expected[OLD_PATH]=OLD_SHA; expected[ENTRY_PATH]=ENTRY_SHA; expected[ADAPTER_PATH]=ADAPTER_SHA; expected[ACTUAL]=ACTUAL_SHA
 var paths: Dictionary=expected.duplicate(true); paths[get_script().resource_path]="SELF_CURRENT_BYTES"
 var before: Dictionary=_snapshot(paths,{ACTUAL:baseline_endpoint})
 for path: String in expected: _check(before[path].get("sha256")==expected[path],"fresh unique current/control source pin "+path)
 var players0: Dictionary=_players(); var slot0: Variant=root.get_node("SaveManager").get("active_slot")
 if not errors.is_empty(): quit(1); return
 var output: String="res://build/joint_world_luoyang_20261003_qa/artifact_catalog_ownership_units_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique causal-unit build directory")
 _case("old_real_run_control",OLD_PATH,true,false,output)
 _case("new_real_run_owned",CURRENT_PATH,false,false,output)
 _case("new_fresh_probe_fresh_owner_repeat",CURRENT_PATH,false,false,output)
 _case("new_real_run_owned_nested_fixture",CURRENT_PATH,false,true,output)
 _check(causal_records.size()==4,"all actual old/new/repeat/deep ownership lifecycles exercised")
 var after: Dictionary=_snapshot(paths); var env1: Dictionary=_env()
 _check(before==after and _players()==players0 and root.get_node("SaveManager").get("active_slot")==slot0,"all source bytes/SHA/mtime and15 players/slot unchanged")
 _check(env1.driver=="WASAPI" and env1.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen engine/1x finish")
 var report: Dictionary={"schema":1,"scope":"PURE_ACTUAL_ARTIFACT_RUN_EARLY_REFUSAL_CATALOG_OWNERSHIP_CAUSAL_UNITS_NOT_COMPLETE_ARTIFACT","checks":checks,"failures":errors.size(),"errors":errors,"cases":causal_records,"source_before":before,"source_after":after,"players_before":players0,"players_after":_players(),"environment_before":env0,"environment_after":env1,"original_ROOT362_failures_preserved":true,"original_bad_final_pin_failures_preserved":4,"complete_artifact_executed":false,"Field_executed":false,"source_complete":false,"release_complete":false,"output":output}
 var f:=FileAccess.open(output+"result.json",FileAccess.WRITE)
 if f!=null: f.store_string(JSON.stringify(report,"\t")); f.flush(); f.close()
 _check(f!=null and _read(output+"result.json")==JSON.parse_string(JSON.stringify(report)),"complete causal-unit report checked readback")
 print("V9E_ARTIFACT_CATALOG_OWNERSHIP_UNITS ",JSON.stringify({"checks":checks,"failures":errors.size(),"cases":causal_records.size(),"output":output,"complete_artifact_executed":false,"release_complete":false}))
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)
