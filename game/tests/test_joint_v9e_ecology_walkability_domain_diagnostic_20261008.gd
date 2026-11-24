extends SceneTree
## Read-only all-nine ecology domain diagnosis. No Field/Physics, factory,
## selector execution, raster/object mutation, QA override or approval.
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
 "res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd":"b0d3da01ef1347385636765773f4d1a211c871f51b9338c13577f76075e0c2f0",
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
var disagreement_ids: Array[String]=[]
var source_objects: Dictionary={}

func _initialize() -> void:
 call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok:
  errors.append(label)
  push_error("[ECOLOGY DOMAIN DIAGNOSTIC] "+label)
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

func _source_fields(value: Dictionary) -> Dictionary:
 var result: Dictionary={}
 for key: String in ["id","role","blocking","pos","collision_size","collision_size_px","collision_center_world_px","collision_offset","walkability_margin_px","solid_polygons_px","source_XZ_foot_px","world_foot_px","texture"]:
  if value.has(key): result[key]=value[key]
 return result

func _sample_domain(raw: RefCounted,center: Vector2,writer_offsets: bool) -> Dictionary:
 var shoes: PackedVector2Array=raw.samples(center)
 if writer_offsets:
  # Independent reproduction of frozen source foot_offsets construction.
  shoes=PackedVector2Array([center])
  for index in 16:
   var angle: float=TAU*float(index)/16.
   shoes.append(center+Vector2(cos(angle),sin(angle))*Vector2(10,6))
 var rows: Array[Dictionary]=[]
 var all_threshold: bool=true
 var all_exact_white: bool=true
 for index in shoes.size():
  var sample: Dictionary=raw.pixel_evidence(shoes[index])
  var color: Variant=sample.get("rgba")
  var white: bool=color is Array and color.size()==4 and color[0]==1. and color[1]==1. and color[2]==1. and color[3]==1.
  all_threshold=all_threshold and sample.get("clear")==true
  all_exact_white=all_exact_white and white
  sample["shoe_index"]=index
  sample["writer_exact_Color_WHITE"]=white
  var hits: Array[Dictionary]=[]
  for entry: Dictionary in raw.blockers:
   var rect: Rect2=entry.grown
   var hit: bool=Geometry2D.is_point_in_polygon(shoes[index],entry.polygon) if entry.get("shape")=="exact_world_polygon" else rect.has_point(shoes[index])
   if hit: hits.append({"id":entry.id,"actual_oracle_collision":entry.duplicate(true),"bound_source_object":source_objects.get(entry.id,{})})
  sample["source_solid_hits"]=hits
  rows.append(sample)
 var reason: Dictionary=raw.foot_evidence(center)
 return {"center_px":[center.x,center.y],"sample_construction":"ORIGINAL_WRITER_FOOT_OFFSETS" if writer_offsets else "ACTUAL_RAW_ORACLE_SAMPLES","all17_threshold_raster":all_threshold,"all17_exact_WHITE_raster":all_exact_white,"all17_raw_pixels":rows,"raw_clear_includes_source_solids":raw.clear(center),"actual_raw_foot_evidence":reason,"Physics_queried":false}

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
 for path: String in paths: _check(before[path].get("sha256")==paths[path],"fixed actual350 input before "+path)
 if not errors.is_empty(): await _finish(); return
 var source: Dictionary=_read(SOURCE)
 var manifest: Dictionary=_read(MANIFEST)
 var old: Dictionary=_read(FAILURE)
 _check(old.get("failures")==1 and old.get("complete")==false and old.get("records",{}).get("ecology") is Array,"preserved actual350 sole failure, no replacement PASS")
 var layout: Resource=ResourceLoader.load(LAYOUT,"",ResourceLoader.CACHE_MODE_IGNORE)
 var raw: RefCounted=RAW.new()
 var geometry: RefCounted=GEOMETRY.new()
 geometry.set("height",FileAccess.get_file_as_bytes(RF).to_float32_array())
 _check(raw.configure(layout),"actual published layout and source-solid raw oracle")
 for obj: Dictionary in source.get("objects",[]): source_objects[String(obj.get("id",""))]=_source_fields(obj)
 for cell: Vector2i in raw.tiles:
  var tile: Dictionary=raw.tiles[cell]
  var pin: Variant=manifest.get("asset_sha256",{}).get(tile.path)
  _check(pin is String and tile.sha256==pin and source.get("asset_sha256",{}).get(tile.path)==pin,"actual64PNG SHA bound to source/manifest "+tile.path)
  paths[tile.path]=pin
 before=_snapshot(paths)
 for path: String in paths: _check(before[path].get("sha256")==paths[path],"every consumed current input before "+path)
 var probes: Variant=source.get("ecology_probes")
 _check(probes is Array and probes.size()==9 and old.records.ecology.size()==9,"all9 fixed source and actual350 recorded regions")
 if errors.is_empty():
  for index in 9:
   var probe: Dictionary=probes[index]
   var id: String=String(probe.id)
   var original: Dictionary=old.records.ecology[index]
   _check(original.id==id and original.source==probe,"actual350 exact frozen regional record "+id)
   var source_point: Vector2=_point(probe.source_XZ_px)
   var h: float=geometry.height_at(source_point)
   var consumer_point: Vector2=source_point-Vector2(0,h*Z_PPM)
   var writer_point: Vector2=_point(probe.projected_px)
   _check(is_finite(h) and consumer_point.distance_to(_point(original.projected_px))<.01,"actual350 same independently consumed RF projection "+id)
   var consumer: Dictionary=_sample_domain(raw,consumer_point,false)
   var writer: Dictionary=_sample_domain(raw,writer_point,true)
   var agrees: bool=consumer.raw_clear_includes_source_solids==probe.walkable
   if not agrees: disagreement_ids.append(id)
   var row: Dictionary={"id":id,"profile":probe.profile,"declared_writer_walkable":probe.walkable,"recorded_native_selector":probe.native_selector,"source_XZ_px":probe.source_XZ_px,"recorded_RF_height_m":probe.actual_rf_height_m,"independent_RF_height_m":h,"consumer_domain":consumer,"original_writer_domain":writer,"consumer_full_clear_matches_declared":agrees,"writer_raster_matches_declared":writer.all17_exact_WHITE_raster==probe.walkable,"fullPhysics_pass_claimed":false}
   regions.append(row)
   print("ECOLOGY_DOMAIN ",JSON.stringify(row))
 _check(regions.size()==9,"all9 domains diagnosed without failure subset or reselection")
 _check(raw.verify_sources() and raw.errors.is_empty(),"actual64PNG sources unchanged and raw valid")
 raw.release(); geometry.release()
 raw=null; geometry=null; layout=null
 source_objects.clear(); source.clear(); manifest.clear(); old.clear()
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
 var output: String="res://build/joint_world_luoyang_20261003_qa/ecology_domain_diagnostic_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 if not _check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output)==OK,"unique BUILD-only output"): quit(1); return
 var payload: String=JSON.stringify({"scope":"READ_ONLY_NINE_ECOLOGY_RASTER_SELECTOR_SOURCE_SOLID_DOMAIN_DIAGNOSTIC_NOT_PHYSICS_FIELD_OR_RELEASE","checks":checks,"diagnostic_failures":errors.size(),"diagnostic_errors":errors,"diagnostics_complete":errors.is_empty() and regions.size()==9,"disagreement_ids":disagreement_ids,"regions":regions,"pins":paths,"before":before,"after":after,"environment_before":environment_before,"environment_after":environment_after,"source_version_equivalence":false,"original350failure_preserved":true,"writer_selector_executed":false,"factory_executed":false,"Field_executed":false,"Physics_queried":false,"source_blocking_or_17shoes_relaxed":false,"release_complete":false,"formal_cutover":false},"\t",true)
 var file: FileAccess=FileAccess.open(output+"result.json",FileAccess.WRITE)
 if file==null: _check(false,"diagnostic result writable")
 else:
  file.store_string(payload); file.flush()
  var error: Error=file.get_error()
  file.close()
  _check(error==OK and FileAccess.get_file_as_string(output+"result.json")==payload,"diagnostic exact flush/readback")
 print("ECOLOGY_DOMAIN_DIAGNOSTIC checks=%d failures=%d diagnosed=%d disagreements=%s output=%s" % [checks,errors.size(),regions.size(),JSON.stringify(disagreement_ids),output])
 quit(0 if errors.is_empty() else 1)
