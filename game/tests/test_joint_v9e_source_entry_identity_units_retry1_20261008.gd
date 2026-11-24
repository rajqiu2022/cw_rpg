extends "res://tests/test_joint_v9e_legacy_actual_canvas_roundtrips_20261008.gd"
## ROOT359 retry1: original BFDF unit/failure preserved. Pure identity-reader units. Production materialize supplies ACTUAL only;
## expected append is independent writer math, also bound to ROOT358 native hex.
const SUBJECT=preload("res://tests/helpers/joint_v15_release_world_prepared_phase.gd")
const PRODUCTION=preload("res://scripts/world/outskirts_native_contract.gd")
const DIAG=preload("res://tests/test_joint_v9e_source_entry_identity_diagnostic_20261008.gd")
const EVIDENCE: String="res://build/joint_world_luoyang_20261003_qa/source_entry_identity_diagnostic_1791440630_14879535_60368/diagnostic.json"
const EVIDENCE_SHA: String="602e3b0dc3200dc7c6a535df1f24b58d98a7cd5800cc0c1071df8c9697a16315"
const SUBJECT_SHA: String="9e9c496ec1a7e15c57eb1aff13aefa509fb4d0872346209d236ffc8808d8f661"
var subject: RefCounted
var canonical: SceneScript
var control: WalkableMapLayout
var expected_append: Dictionary
var mutations: Array[Dictionary]=[]
func _owned(scene: SceneScript) -> SceneScript:
 var result: SceneScript=scene.duplicate(true)
 result.map_layout=scene.map_layout.duplicate(true)
 for property: Dictionary in scene.map_layout.get_property_list():
  if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0: continue
  var value: Variant=scene.map_layout.get(property.name)
  if value is Array or value is Dictionary: result.map_layout.set(property.name,value.duplicate(true))
 return result
func _matches(value: Variant,clone: bool=true) -> bool:
 return subject.call("_release_source_entry_matches",value,canonical,control,expected_append,clone)
func _negative(value: Variant,label: String) -> void:
 _check(not _matches(value),"real identity predicate rejects "+label)
 mutations.append({"label":label,"API":"_release_source_entry_matches","rejected":not _matches(value)})
func _change(resource: Resource,name: String) -> bool:
 var value: Variant=resource.get(name)
 match typeof(value):
  TYPE_BOOL: resource.set(name,not value)
  TYPE_INT: resource.set(name,value+1)
  TYPE_FLOAT: resource.set(name,value+1.)
  TYPE_STRING: resource.set(name,value+"__WRONG")
  TYPE_STRING_NAME: resource.set(name,StringName(String(value)+"__WRONG"))
  TYPE_VECTOR2: resource.set(name,value+Vector2(1,0))
  TYPE_VECTOR2I: resource.set(name,value+Vector2i(1,0))
  TYPE_ARRAY:
   var array: Array=value.duplicate(true)
   if not array.is_empty(): array.remove_at(0)
   elif array.get_typed_builtin() in [TYPE_NIL,TYPE_DICTIONARY]: array.append({"wrong":true})
   elif array.get_typed_builtin()==TYPE_PACKED_VECTOR2_ARRAY: array.append(PackedVector2Array([Vector2.ZERO]))
   elif array.get_typed_builtin()==TYPE_STRING_NAME: array.append(&"wrong")
   else: return false
   resource.set(name,array)
  TYPE_DICTIONARY:
   var dict: Dictionary=value.duplicate(true); dict["wrong"]=true; resource.set(name,dict)
  TYPE_NIL:
   if name=="on_enter_dialog": resource.set(name,DialogScript.new())
   elif name=="streamed_background": resource.set(name,StreamedBackgroundSet.new())
   else: return false
  _: return false
 return true
func _ulp(value: float) -> float:
 var bytes: PackedByteArray=PackedFloat64Array([value]).to_byte_array()
 bytes.encode_u64(0,bytes.decode_u64(0)+1)
 return bytes.decode_double(0)
func _exercise(actual: SceneScript,evidence: Dictionary) -> void:
 _check(subject.call("_release_source_entry_identity",canonical)==true,"real disk-bound canonical identity also strictly verified")
 _check(subject.call("_release_source_entry_identity",actual)==true and _matches(actual),"real production materialize actual passes independently constructed expected")
 var hex_post: String=evidence.attempts[0].identity.independent_expected_post.native_bytes_hex
 var hex_portal: String=evidence.attempts[0].identity.independent_expected_portal.native_bytes_hex
 _check(subject.call("_release_source_entry_equal",expected_append.object,bytes_to_var(hex_post.hex_decode())) and subject.call("_release_source_entry_equal",expected_append.portal,bytes_to_var(hex_portal.hex_decode())),"independent expectation exactly matches preserved ROOT358 native values")
 var reordered: Dictionary={}
 var keys: Array=expected_append.object.keys(); keys.reverse()
 for key: Variant in keys: reordered[key]=expected_append.object[key]
 _check(subject.call("_release_source_entry_equal",reordered,expected_append.object),"dictionary insertion order is not semantic identity")
 for domain: String in ["scene","layout"]:
  var original: Resource=actual if domain=="scene" else actual.map_layout
  for property: Dictionary in original.get_property_list():
   var name: String=String(property.name)
   if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or name in ["script","map_layout","resource_path"]: continue
   var owned: SceneScript=_owned(actual)
   var target: Resource=owned if domain=="scene" else owned.map_layout
   _check(_change(target,name),"owned valid-typed mutation constructed for every original storage field "+domain+"/"+name)
   _negative(owned,domain+"/"+name)
 for field: String in ["visual_objects","portals"]:
  for action: String in ["missing","duplicate","wrong_id","wrong_value","typed_key"]:
   var owned: SceneScript=_owned(actual)
   var array: Array=owned.map_layout.get(field)
   if action=="missing": array.remove_at(array.size()-1)
   elif action=="duplicate": array.append(array.back().duplicate(true))
   elif action=="wrong_id": array.back()["id"]="wrong"
   elif action=="wrong_value": array.back()["pos"]+=Vector2(.001,0)
   else:
    var last: Dictionary=array.back(); var value: Variant=last["id"]; last.erase("id"); last[StringName("id")]=value
    _check(typeof(last.keys().filter(func(key: Variant) -> bool: return String(key)=="id")[0])==TYPE_STRING_NAME,"actual StringName key mutation represented")
   _negative(owned,field+"/"+action)
 for owner: String in ["scene","layout"]:
  var owned: SceneScript=_owned(actual)
  (owned if owner=="scene" else owned.map_layout).set_meta("unapproved",true)
  _negative(owned,owner+" metadata")
 var mutated: SceneScript=_owned(actual); mutated.npc_visual_scale=_ulp(mutated.npc_visual_scale)
 _negative(mutated,"native Double one-ULP old scale")
 var untyped: Array=[{"x":1}]; var typed: Array[Dictionary]=[{"x":1}]
 _check(not subject.call("_release_source_entry_equal",untyped,typed),"typed Array metadata mismatch rejected, standalone real comparator")
 var string_key: Dictionary={"x":1}; var name_key: Dictionary={StringName("x"):1}
 _check(not subject.call("_release_source_entry_equal",string_key,name_key),"dictionary key native type mismatch rejected")
 var typed_dict: Dictionary[String,int]={"x":1}
 var same_typed_dict: Dictionary[String,int]={"x":1}
 var key_only: Dictionary[String,Variant]={"x":1}
 var value_only: Dictionary[Variant,int]={"x":1}
 _check(subject.call("_release_source_entry_equal",typed_dict,same_typed_dict),"same typed Dictionary content and metadata accepted")
 _check(not subject.call("_release_source_entry_equal",string_key,typed_dict),"same-content untyped versus typed Dictionary rejected")
 _check(not subject.call("_release_source_entry_equal",typed_dict,key_only),"Dictionary value typing independently checked")
 _check(not subject.call("_release_source_entry_equal",typed_dict,value_only),"Dictionary key typing independently checked")
 for field: String in ["visual_objects","portals"]:
  var owned: SceneScript=_owned(actual)
  var array: Array=owned.map_layout.get(field)
  var typed_append: Dictionary[String,Variant]={}
  typed_append.assign(array.back())
  _check(typed_append.get_typed_key_builtin()==TYPE_STRING and array.back().get_typed_key_builtin()==TYPE_NIL,"actual append typed container mutation represented "+field)
  array[array.size()-1]=typed_append
  _negative(owned,field+" same-content typed Dictionary append")
 var canonical_fake: SceneScript=ResourceLoader.load(DIAG.CANONICAL,"",ResourceLoader.CACHE_MODE_IGNORE)
 canonical_fake.npc_visual_scale+=.125
 _check(canonical_fake.resource_path==DIAG.CANONICAL and not subject.call("_release_source_entry_identity",canonical_fake),"same-path SceneScript with internal field mutation rejected")
 # READONLY field-core regression, NOT an independent same-path GDScript claim.
 # Godot CACHE_MODE_IGNORE returned the shared script in ROOT359; do not mutate it.
 for script_path: String in ["res://scripts/domain/scene_script.gd","res://scripts/domain/walkable_map_layout.gd"]:
  var readonly_script: GDScript=load(script_path)
  var actual_code: String=readonly_script.source_code
  var bad_code: String=actual_code+"\n# OWNED STRING MUTATION ONLY\n"
  _check(subject.call("_release_source_entry_script_fields",readonly_script.resource_path,script_path,actual_code,actual_code),"real readonly script field-core positive "+script_path)
  _check(not subject.call("_release_source_entry_script_fields",script_path,script_path,bad_code,actual_code),"same-path left code mutation rejected by actual core")
  _check(not subject.call("_release_source_entry_script_fields",script_path,script_path,actual_code,bad_code),"same-path right code mutation rejected by actual core")
  _check(not subject.call("_release_source_entry_script_fields",script_path,script_path,bad_code,bad_code),"matching malicious codes still rejected against actual disk")
  for bad: Variant in [null,0,StringName(script_path),[]]:
   _check(not subject.call("_release_source_entry_script_fields",bad,script_path,actual_code,actual_code),"wrong typed left script path rejected")
   _check(not subject.call("_release_source_entry_script_fields",script_path,bad,actual_code,actual_code),"wrong typed right script path rejected")
   _check(not subject.call("_release_source_entry_script_fields",script_path,script_path,bad,actual_code),"wrong typed left script code rejected")
   _check(not subject.call("_release_source_entry_script_fields",script_path,script_path,actual_code,bad),"wrong typed right script code rejected")
  _check(not subject.call("_release_source_entry_script_fields",script_path,script_path+"__WRONG",actual_code,actual_code),"different script path rejected")
  _check(not subject.call("_release_source_entry_script_fields","res://unapproved.gd","res://unapproved.gd",actual_code,actual_code),"matching unapproved script path rejected")
 var owned_script:=GDScript.new()
 _check(not subject.call("_release_source_entry_equal",owned_script,load("res://scripts/domain/scene_script.gd")),"owned empty-path GDScript rejected without cache mutation")
 _check(not subject.call("_release_source_entry_equal",Resource.new(),load("res://scripts/domain/scene_script.gd")),"non-GDScript Resource class rejected")
 var empty: SceneScript=_owned(canonical)
 _negative(empty,"arbitrary empty-path clone without append")
 _negative(null,"null")
 _negative(Resource.new(),"unapproved Resource class")
 var current: Dictionary={}
 for biome: String in ["bamboo","forest","marsh"]: current[biome]=SUBJECT.RELEASE_SOURCE_ENTRY_PINS[SUBJECT.RELEASE_SOURCE_ENTRY_ROOT+biome+"/art_contract.json"]
 var adoption: Dictionary={"schema_version":1,"status":"APPROVED_LOCAL_FIELDS","art_root":SUBJECT.RELEASE_SOURCE_ENTRY_ROOT,"contract_sha256":current.duplicate(true)}
 _check(subject.call("_release_source_entry_domain",PackedStringArray(DIAG.ARGS),{},current),"fixed complete candidate domain accepts current three manifests")
 _check(subject.call("_release_source_entry_domain",PackedStringArray(),adoption,current),"formal adoption fixture requires all three exact current frozen manifest hashes")
 for args: PackedStringArray in [PackedStringArray(),PackedStringArray(["--outskirts-candidate-preview"]),PackedStringArray(["--outskirts-complete-v5"]),PackedStringArray(["--outskirts-candidate-preview","--outskirts-complete-v5","--outskirts-visual-v4"])]:
  _check(not subject.call("_release_source_entry_domain",args,{},current),"wrong/missing/conflicting candidate selection rejects")
 for key: String in ["schema_version","status","art_root","contract_sha256"]:
  for bad: Variant in [null,0,"wrong",{}]:
   var copy: Dictionary=adoption.duplicate(true); copy[key]=bad
   _check(not subject.call("_release_source_entry_domain",PackedStringArray(),copy,current),"formal adoption wrongtype/value "+key)
 for biome: String in current:
  var copy: Dictionary=current.duplicate(true); copy[biome]="0".repeat(64)
  _check(not subject.call("_release_source_entry_domain",PackedStringArray(DIAG.ARGS),adoption,copy),"current frozen manifest mismatch "+biome)
  var omitted: Dictionary=adoption.duplicate(true); omitted.contract_sha256.erase(biome)
  _check(not subject.call("_release_source_entry_domain",PackedStringArray(),omitted,current),"formal complete three required "+biome)
 _check(subject.call("_release_source_entry_identity",actual),"warm negative calls never turn malformed identity into cached PASS")
func _run() -> void:
 _check(OS.get_cmdline_user_args()==PackedStringArray(DIAG.ARGS),"explicit pure identity domain, no Field")
 var env0: Dictionary=_env()
 _check(env0.driver=="WASAPI" and env0.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen engine/1x start")
 var endpoint: Dictionary=_file(EVIDENCE)
 _check(endpoint.get("sha256")==EVIDENCE_SHA,"fixed full ROOT358 actual proof")
 if not errors.is_empty(): quit(1); return
 var evidence: Dictionary=_read(EVIDENCE)
 var expected: Dictionary=DIAG.PINS.duplicate(true)
 for path: String in evidence.source_before:
  if evidence.source_before[path].get("exists")==true: expected[path]=evidence.source_before[path].sha256
 expected[ADAPTER_PATH]=SUBJECT_SHA; expected[EVIDENCE]=EVIDENCE_SHA
 var paths: Dictionary=expected.duplicate(true); paths[get_script().resource_path]="SELF_CURRENT_BYTES"
 var before: Dictionary=_snapshot(paths,{EVIDENCE:endpoint})
 for path: String in expected: _check(before[path].get("sha256")==expected[path],"fresh unique actual pinned source "+path)
 var players0: Dictionary=_players(); var slot0: Variant=root.get_node("SaveManager").get("active_slot")
 if not errors.is_empty(): quit(1); return
 subject=SUBJECT.new()
 canonical=ResourceLoader.load(DIAG.CANONICAL,"",ResourceLoader.CACHE_MODE_IGNORE)
 control=ResourceLoader.load(DIAG.LAYOUT,"",ResourceLoader.CACHE_MODE_IGNORE)
 expected_append=subject.call("_release_source_entry_expected",canonical,_read(DIAG.CONTRACT))
 var actual: SceneScript=PRODUCTION.materialize(load(DIAG.CANONICAL))
 _check(actual!=null and actual.resource_path.is_empty(),"production materialize actual only, not expected authority")
 if actual!=null: _exercise(actual,evidence)
 var after: Dictionary=_snapshot(paths); var env1: Dictionary=_env()
 _check(before==after and _players()==players0 and root.get_node("SaveManager").get("active_slot")==slot0,"all source bytes/SHA/mtime and15 player files/slot unchanged")
 _check(env1.driver=="WASAPI" and env1.exe_sha256==OLD_DIAG.EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen engine/1x finish")
 var output: String="res://build/joint_world_luoyang_20261003_qa/source_entry_identity_units_retry1_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique pure evidence directory")
 var report: Dictionary={"schema":1,"scope":"PURE_STRICT_SOURCE_ENTRY_IDENTITY_NOT_FIELD_RELEASE","checks":checks,"failures":errors.size(),"errors":errors,"mutations":mutations,"source_before":before,"source_after":after,"players_before":players0,"players_after":_players(),"environment_before":env0,"environment_after":env1,"original_ROOT358_failures_preserved":3,"production_materialize_is_actual_only":true,"Field_executed":false,"release_complete":false,"output":output}
 var file:=FileAccess.open(output+"result.json",FileAccess.WRITE)
 if file!=null: file.store_string(JSON.stringify(report,"\t")); file.flush(); file.close()
 _check(file!=null and _read(output+"result.json")==JSON.parse_string(JSON.stringify(report)),"pure result checked readback")
 print("V9E_SOURCE_ENTRY_IDENTITY_UNITS ",JSON.stringify({"checks":checks,"failures":errors.size(),"errors":errors,"mutation_count":mutations.size(),"output":output,"Field_executed":false,"release_complete":false}))
 subject=null; canonical=null; control=null; actual=null
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)


