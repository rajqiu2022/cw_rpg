extends SceneTree
## Actual nine-region reader regression. Full NEW _ecology predicates plus
## narrow real-pixel/source-solid negatives. No Field/Physics, factory or approval.
const PROBE_PATH: String="res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
const DIAG: String="res://build/joint_world_luoyang_20261003_qa/ecology_domain_diagnostic_1791431157_9269078_90588/result.json"
const RAW=preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const GEOMETRY=preload("res://tests/helpers/joint_v15_world_geometry_phase.gd")
const SOURCE: String="res://data/maps/world_map_v15_complete_v9c_source.json"
const ROOT: String="res://art/maps/world_map_v15_complete_v9c/"
const MANIFEST: String=ROOT+"art_contract.json"
const LAYOUT: String="res://data/maps/world_map_jianghu_layout_v15.tres"
const RF: String=ROOT+"terrain_height.rf"
const FAILURE: String="res://build/joint_world_luoyang_20261003_qa/world_release_196250435/actual_world_artifact_semantics.json"
const EXE_SHA: String="975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const Z_PPM: float=102.4*0.7071067811865476
const PINS: Dictionary={
 SOURCE:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
 MANIFEST:"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
 LAYOUT:"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
 RF:"7158eaf91c38ce55541e895b449ee5645a772a2cd037479357eedaf1917e6f4b",
 FAILURE:"15b7a11eb195e28a87980c784557352d1274b02bc766fbb42dc36255fb0e6ddf",
 "res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd":"7628d404d7587dfd885937ad1e26ac6a06f4e48ca53c273ccd8d5f1aee5db9db",
 "res://tests/helpers/v15_raw_world_oracle.gd":"c58043373af6154d5f7f79cfa2d0e8dcda38f3fbe0c6648a4af4ce626e8a9c51",
 "res://tests/helpers/joint_v15_world_geometry_phase.gd":"b93df5b2fa2a78cc7f65fea48f43c37735edc44795ebc3709d312adc5a06e0c9",
 "res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd":"946fcc3f9ba9d1d46b067672bd8bd560e12bc651a96b7096d48d94a5f5f060a9",
 PROBE_PATH:"c9d793a97b3b42f364b4888a64c079e523d8e4a6645ddaf5a3aa9d2587b8f3f1",
 DIAG:"5d0cd2576fd4e853daedd921aa8764739bbc146ad343bf621be25512c277f262",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd":"4d006169a3cc0f9dc347c467d4ab05204ee2f78be790e3c75c368d77e9b5abfb",
 "res://scripts/dev/world_map_v15_complete_v5_source.gd":"f812bcd93efe93da54866c2d61287feaeaf6bc68543493b4b54a606d99769299"
}
var checks: int=0
var errors: Array[String]=[]
var paths: Dictionary={}
var before: Dictionary={}
var players_before: Dictionary={}
var environment_before: Dictionary={}
var slot_before: Variant
var save: Node
var regions: Array[Dictionary]=[]
class AuditSink extends RefCounted:
 var checks: int=0
 var failures: int=0
 func _check(ok: bool,_label: String) -> bool:
  checks+=1
  if not ok: failures+=1
  return ok
var subject: RefCounted
var sink: AuditSink=AuditSink.new()
var negative_cases: int=0
var predicate_calls: int=0

func _initialize() -> void:
 call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok:
  errors.append(label)
  push_error("[ECOLOGY DOMAIN UNIT] "+label)
 return ok

func _read(path: String) -> Dictionary:
 var decoder: JSON=JSON.new()
 if decoder.parse(FileAccess.get_file_as_string(path))!=OK or not decoder.data is Dictionary: return {}
 return decoder.data

func _file(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {"exists":false}
 var file: FileAccess=FileAccess.open(path,FileAccess.READ)
 if file==null: return {"exists":true,"readable":false}
 var length: int=file.get_length()
 file.close()
 return {"exists":true,"readable":true,"bytes":length,"sha256":FileAccess.get_sha256(path).to_lower(),"mtime":FileAccess.get_modified_time(path)}

func _snapshot(inputs: Dictionary) -> Dictionary:
 var result: Dictionary={}
 for path: String in inputs: result[path]=_file(path)
 return result

func _players() -> Dictionary:
 var result: Dictionary={}
 for slot in 5:
  for suffix: String in ["",".bak",".tmp"]:
   var path: String="user://save_%d.json%s" % [slot,suffix]
   result[ProjectSettings.globalize_path(path)]=_file(path)
 return result

func _environment() -> Dictionary:
 return {"actual_audio_driver":AudioServer.get_driver_name(),"output_device":AudioServer.output_device,"output_mix_rate_hz":AudioServer.get_mix_rate(),"output_latency_sec":AudioServer.get_output_latency(),"display_driver":DisplayServer.get_name(),"engine_version":Engine.get_version_info(),"executable_path":OS.get_executable_path(),"executable_sha256":FileAccess.get_sha256(OS.get_executable_path()).to_lower(),"source_version_equivalence":false}

func _point(value: Array) -> Vector2:
 return Vector2(float(value[0]),float(value[1]))

func _raster(label: String,want: bool,walkable: Variant,center: Vector2,pixels: Variant) -> void:
 predicate_calls+=1
 if not want: negative_cases+=1
 _check(subject.call("_ecology_native_raster_exact",walkable,center,pixels)==want,label)

func _solids(label: String,want: bool,center: Vector2,blockers: Array,pixels: Array,reason: Variant,clear_value: Variant) -> void:
 predicate_calls+=1
 if not want: negative_cases+=1
 var result: Dictionary=subject.call("_ecology_source_solid_record",center,blockers,pixels,reason,clear_value)
 _check(result.get("complete")==want,label)

func _negatives(raw: RefCounted,source: Dictionary,diag: Dictionary) -> void:
 var forest: Dictionary={}
 var bamboo: Dictionary={}
 for record: Dictionary in regions:
  if record.id=="western_woodland": forest=record
  if record.id=="southern_bamboo": bamboo=record
 if not _check(not forest.is_empty() and not bamboo.is_empty(),"actual fixed forest and black-PNG bamboo records present"): return
 var center: Vector2=_point(forest.writer_raster_center_px)
 var pixels: Array=forest.original_writer_raster_full17
 _raster("actual forest original17 exact WHITE positive",true,true,center,pixels)
 _raster("actual forest wrong declared navigation rejects",false,false,center,pixels)
 for invalid: Variant in [null,0,1,"true",[],{}]:
  _raster("missing/wrongtyped walkable rejects",false,invalid,center,pixels)
 var changed: Array=pixels.duplicate(true)
 changed.pop_back()
 _raster("16 instead of17 shoes rejects",false,true,center,changed)
 changed=pixels.duplicate(true); changed.append(pixels[0])
 _raster("18 instead of17 shoes rejects",false,true,center,changed)
 _raster("sourceXZ domain cannot substitute projected samples",false,true,_point(forest.source.source_XZ_px),pixels)
 changed=pixels.duplicate(true)
 changed[8].rgba=[.5,.5,.5,1.]
 _raster("gray threshold-positive cannot replace exact WHITE",false,true,center,changed)
 changed=pixels.duplicate(true); changed[8].rgba=[0.,0.,0.,1.]; changed[8].clear=false
 _raster("single original WHITE sample changed black rejects",false,true,center,changed)
 for key: String in ["point","pixel","chunk","path","sha256","pixel_sampling","rgba","clear"]:
  changed=pixels.duplicate(true); changed[8].erase(key)
  _raster("missing actual pixel field "+key+" rejects",false,true,center,changed)
 changed=pixels.duplicate(true); changed[8].path=ROOT+"chunks/r0_c0_walk.png"
 _raster("other chunk path cannot substitute current pixel",false,true,center,changed)
 changed=pixels.duplicate(true); changed[8].sha256="0".repeat(64)
 _raster("wrong actual native PNG binding rejects",false,true,center,changed)
 changed=pixels.duplicate(true); changed[8].point=[0,0]
 _raster("different shoe/point domain rejects",false,true,center,changed)
 _raster("actual black-PNG bamboo remains terrain-negative",true,false,_point(bamboo.writer_raster_center_px),bamboo.original_writer_raster_full17)
 _raster("black-PNG cannot become terrain-positive",false,true,_point(bamboo.writer_raster_center_px),bamboo.original_writer_raster_full17)
 var foot: Vector2=_point(forest.projected_px)
 var source_pixels: Array=[]
 for point: Vector2 in raw.call("samples",foot): source_pixels.append(raw.call("pixel_evidence",point))
 var blockers: Array=raw.get("blockers")
 var reason: Dictionary=raw.call("foot_evidence",foot)
 _check(reason.get("kind")=="source_collision" and reason.get("id")=="v7_west_middle_stem_0001" and reason.get("shoe_index")==8 and reason.get("shape")=="grown_rectangle","actual351 tree remains blocked shoe8 negative, not center-Physics claim")
 var hit_shoes: Array[int]=[]
 for shoe: Dictionary in forest.source_solid_domain.all17_source_hits:
  for hit: Dictionary in shoe.hits:
   if hit.id=="v7_west_middle_stem_0001": hit_shoes.append(int(shoe.shoe_index))
 var expected_hit_shoes: Array[int]=[8,9,10]
 _check(hit_shoes==expected_hit_shoes and forest.source_solid_domain.source_solid_all17_clear==false and forest.source_solid_domain.full17_raster_and_source_clear==false,"exact actual351 tree hits every shoe8/9/10 and preserves source-domain negative")
 var previous: Dictionary={}
 for record: Dictionary in diag.get("regions",[]):
  if record.id=="western_woodland": previous=record.consumer_domain.actual_raw_foot_evidence
 _check(subject.call("_numeric_equal",previous,JSON.parse_string(JSON.stringify(reason,"\t",true)))==true,"native actual blocked tree reason binds original351 writer domain once")
 var source_matches: Array[Dictionary]=[]
 for obj: Dictionary in source.get("objects",[]):
  if obj.get("id")=="v7_west_middle_stem_0001": source_matches.append(obj)
 _check(source_matches.size()==1 and source_matches[0].get("blocking")==true and subject.call("_numeric_equal",source_matches[0].get("collision_size_px"),[18,14])==true,"exact unique bound original tree remains blocking18x14")
 _solids("actual tree full17 independent source-solid attribution",true,foot,blockers,source_pixels,reason,false)
 _solids("blocked tree cannot claim source full-clear",false,foot,blockers,source_pixels,reason,true)
 for invalid: Variant in [null,0,"false",[]]:
  _solids("wrongtyped source clearance rejects",false,foot,blockers,source_pixels,reason,invalid)
 for key: String in ["id","kind","shape","shoe_index","point","center","clear"]:
  var altered: Dictionary=reason.duplicate(true); altered.erase(key)
  _solids("missing actual source reason "+key+" rejects",false,foot,blockers,source_pixels,altered,false)
 for change: Dictionary in [{"id":"other"},{"shoe_index":7},{"point":[0,0]},{"kind":"full17"},{"shape":"exact_world_polygon"}]:
  var altered: Dictionary=reason.duplicate(true)
  for key: String in change: altered[key]=change[key]
  _solids("wrong actual source reason payload rejects",false,foot,blockers,source_pixels,altered,false)
 var changed_blockers: Array=blockers.duplicate(true)
 for entry: Dictionary in changed_blockers:
  if entry.id=="v7_west_middle_stem_0001": entry.grown=Rect2(Vector2.ZERO,Vector2.ONE)
 _solids("removing original tree geometry cannot retain prior source reason",false,foot,changed_blockers,source_pixels,reason,false)
 changed_blockers=blockers.duplicate(true)
 for entry: Dictionary in changed_blockers:
  if entry.id=="v7_west_middle_stem_0001": entry.id="other"
 _solids("changing actual source object identity rejects",false,foot,changed_blockers,source_pixels,reason,false)
 changed=source_pixels.duplicate(true); changed.pop_back()
 _solids("source solids also require every one of17 shoes",false,foot,blockers,changed,reason,false)
 changed=source_pixels.duplicate(true); changed[8].point=[0,0]
 _solids("wrong source-solid shoe domain rejects",false,foot,blockers,changed,reason,false)

func _run() -> void:
 paths=PINS.duplicate(true)
 paths[get_script().resource_path]=FileAccess.get_sha256(get_script().resource_path).to_lower()
 before=_snapshot(paths)
 players_before=_players()
 environment_before=_environment()
 save=root.get_node_or_null("SaveManager")
 _check(save!=null and current_scene==null and OS.get_cmdline_user_args().is_empty(),"normal autoloads, no Field/filters/reselection")
 if save!=null: slot_before=save.get("active_slot")
 _check(environment_before.actual_audio_driver=="WASAPI" and environment_before.executable_sha256==EXE_SHA,"actual start WASAPI and exact975BF engine")
 for path: String in paths: _check(before[path].get("sha256")==paths[path],"fixed actual350/351 input before "+path)
 if not errors.is_empty(): await _finish(); return
 var source: Dictionary=_read(SOURCE)
 var manifest: Dictionary=_read(MANIFEST)
 var old: Dictionary=_read(FAILURE)
 var diag: Dictionary=_read(DIAG)
 _check(old.get("failures")==1 and old.get("complete")==false and diag.get("diagnostics_complete")==true,"original350 FAIL and actual351 complete diagnostic preserved")
 var layout: Resource=ResourceLoader.load(LAYOUT,"",ResourceLoader.CACHE_MODE_IGNORE)
 var raw: RefCounted=RAW.new()
 _check(raw.configure(layout),"actual published layout and source-solid raw oracle")
 for cell: Vector2i in raw.tiles:
  var tile: Dictionary=raw.tiles[cell]
  var pin: Variant=manifest.get("asset_sha256",{}).get(tile.path)
  _check(pin is String and tile.sha256==pin and source.get("asset_sha256",{}).get(tile.path)==pin,"actual64PNG SHA bound to source/manifest "+tile.path)
  paths[tile.path]=pin
 before=_snapshot(paths)
 for path: String in paths: _check(before[path].get("sha256")==paths[path],"every consumed current input before "+path)
 var script: Script=load(PROBE_PATH)
 if _check(script!=null and script.can_instantiate(),"actual current E ecology reader can instantiate") and errors.is_empty():
  subject=script.new()
  subject.set("phase",sink)
  subject.set("catalog",manifest.asset_sha256.duplicate(true))
  var geometry: RefCounted=subject.get("geometry")
  geometry.set("height",FileAccess.get_file_as_bytes(RF).to_float32_array())
  subject.call("_ecology",source,raw)
  var actual: Dictionary=subject.get("records")
  for record: Dictionary in actual.ecology: regions.append(record)
  _check(sink.checks>0 and sink.failures==0 and subject.get("failures")==0 and regions.size()==9,"complete real NEW ecology method preserves all9 RF/profile/material/17raster/source-solid predicates")
  if errors.is_empty(): _negatives(raw,source,diag)
  geometry.release()
  geometry=null; subject=null
 _check(regions.size()==9,"all9 original authored regions exercised, no successful subset")
 _check(raw.verify_sources() and raw.errors.is_empty(),"actual64PNG sources unchanged and raw valid")
 raw.release(); raw=null; layout=null
 source.clear(); manifest.clear(); old.clear(); diag.clear()
 await _finish()

func _finish() -> void:
 var audio: Node=root.get_node_or_null("AudioManager")
 if audio!=null: audio.call("stop_bgm",.15)
 await create_timer(.25).timeout
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 var environment_after: Dictionary=_environment()
 _check(environment_after.actual_audio_driver=="WASAPI" and environment_after.executable_sha256==EXE_SHA,"actual finish WASAPI and exact975BF engine")
 var after: Dictionary=_snapshot(paths)
 _check(after==before,"all source/PNG/RF/failure/writer/layout/diagnostic inputs unchanged")
 _check(_players()==players_before and save!=null and save.get("active_slot")==slot_before,"all15 player paths and active slot unchanged, no restore writes")
 var output: String="res://build/joint_world_luoyang_20261003_qa/ecology_domain_units_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 if not _check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output)==OK,"unique BUILD-only output"): quit(1); return
 var payload: String=JSON.stringify({"scope":"ACTUAL_NINE_ECOLOGY_READER_AND_NEGATIVE_UNITS_NOT_PHYSICS_FIELD_OR_RELEASE","checks":checks,"diagnostic_failures":errors.size(),"diagnostic_errors":errors,"diagnostics_complete":errors.is_empty() and regions.size()==9,"negative_cases":negative_cases,"pure_predicate_calls":predicate_calls,"full_ecology_checks":sink.checks,"full_ecology_failures":sink.failures,"regions":regions,"pins":paths,"before":before,"after":after,"environment_before":environment_before,"environment_after":environment_after,"source_version_equivalence":false,"original350failure_preserved":true,"writer_selector_executed":false,"factory_executed":false,"Field_executed":false,"Physics_queried":false,"source_blocking_or_17shoes_relaxed":false,"release_complete":false,"formal_cutover":false},"\t",true)
 var file: FileAccess=FileAccess.open(output+"result.json",FileAccess.WRITE)
 if file==null: _check(false,"diagnostic result writable")
 else:
  file.store_string(payload); file.flush()
  var error: Error=file.get_error()
  file.close()
  _check(error==OK and FileAccess.get_file_as_string(output+"result.json")==payload,"diagnostic exact flush/readback")
 print("ECOLOGY_DOMAIN_UNIT checks=%d failures=%d diagnosed=%d negative_cases=%d output=%s" % [checks,errors.size(),regions.size(),negative_cases,output])
 quit(0 if errors.is_empty() else 1)


