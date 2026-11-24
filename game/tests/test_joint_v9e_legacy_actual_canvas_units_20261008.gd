extends SceneTree
## Pure reader regression only: real three legacy layouts and all738 actual
## ROOT354 observations, plus explicitly synthetic owned image/solid fixtures.
## No Field/Physics execution, movement, source mutation or release approval.
const ADAPTER=preload("res://tests/helpers/joint_v15_release_world_prepared_phase.gd")
const RAW=preload("res://tests/helpers/joint_v15_wall_v5_ordinary_raw_oracle.gd")
const PARENT=preload("res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd")
const OLD_DIAG=preload("res://tests/test_joint_v9e_portal_arrival_return_diagnostic_20261008.gd")
const ACTUAL: String="res://build/joint_world_luoyang_20261003_qa/portal_arrival_return_diagnostic_1791435678_805337396_35724/diagnostic.json"
const ACTUAL_SHA: String="e11a8629d1c228815cbf726bc99dee73aeaffdf880e0d407abd7ab5c06eeb1d0"
const ADAPTER_SHA: String="766f13443af68510914555211778e88bee6b53ac81328dad1576386dfc8b2a3e"
const EXE_SHA: String="975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const CITY: String="res://data/scenes/luoyang_v3_candidates/ch4_s0_luoyang_gate.tres"
const CITY_SHA: String="3b6f208a44e4780e0af841260cd0e002bbd69579f87b7bc3c9b27dc0dbc7dc8e"
var checks: int=0
var failures: Array[String]=[]
var phase: RefCounted
var rows: int=0
var shoes: int=0
class SixteenShoeFixture extends "res://tests/helpers/joint_v15_wall_v5_ordinary_raw_oracle.gd":
 func samples(center: Vector2) -> PackedVector2Array:
  var p: PackedVector2Array=super.samples(center)
  p.resize(16)
  return p
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String) -> void:
 checks+=1
 if not ok: failures.append(label); push_error("[LEGACY CANVAS UNIT] "+label)
func _v(p: Array) -> Vector2: return Vector2(p[0],p[1])
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
func _write(path: String,value: Dictionary) -> bool:
 if FileAccess.file_exists(path): return false
 var f:=FileAccess.open(path,FileAccess.WRITE)
 if f==null: return false
 f.store_string(JSON.stringify(value,"\t")); f.flush()
 var error: Error=f.get_error(); f.close()
 return error==OK and _read(path)==JSON.parse_string(JSON.stringify(value))
func _delegation(raw: RefCounted,image: Image) -> void:
 var parent: RefCounted=PARENT.new()
 phase.set("owner_tree",self)
 var world: SceneScript=load("res://data/scenes/world_map_jianghu_v15.tres")
 phase.set("ordinary_native_city",false)
 _check(phase.call("_release_ordinary_is_legacy",world)==false,"actual Router world identity excludes adaptation")
 phase.set("ordinary_native_city",true)
 var city: SceneScript=load(CITY)
 _check(city!=null and city.map_layout.schema_version==3 and phase.call("_release_ordinary_is_legacy",city)==false,"actual current native-city branch excludes adaptation")
 for subject: RefCounted in [phase,parent]:
  subject.set("ordinary_raw",raw); subject.set("ordinary_size",Vector2(100,100))
 phase.set("release_legacy_context",false)
 for native_city: bool in [false,true]:
  phase.set("ordinary_native_city",native_city); parent.set("ordinary_native_city",native_city)
  image.fill(Color.WHITE)
  var original: bool=parent.call("_ordinary_static_clear",Vector2(50,50))
  _check(original and phase.call("_ordinary_static_clear",Vector2(50,50))==original,"executable unchanged parent delegation positive city="+str(native_city))
  image.set_pixel(50,50,Color.BLACK)
  original=parent.call("_ordinary_static_clear",Vector2(50,50))
  _check(not original and phase.call("_ordinary_static_clear",Vector2(50,50))==original,"executable unchanged parent delegation negative city="+str(native_city))
  image.fill(Color.WHITE)
 phase.set("ordinary_raw",null); parent.set("ordinary_raw",null); parent=null
func _actual_row(raw: RefCounted,actual_size: Vector2,point: Dictionary,label: String) -> bool:
 var result: Dictionary=phase.call("_release_legacy_foot_evidence",raw,raw.get("size"),actual_size,_v(point.root_px),_v(point.foot_offset_px))
 var expected_clear: bool=true
 var expected: Array=point.mapped_actual17_to_source_comparison_only
 _check(expected.size()==17 and result.get("samples",[]).size()==17,"real full17 count "+label)
 for index in mini(expected.size(),17):
  var row: Dictionary=expected[index]
  var expected_shoe_clear: bool=row.source_pixel_or_polygon.get("clear")==true and row.source_solid_hits.is_empty()
  expected_clear=expected_clear and expected_shoe_clear
  var actual: Dictionary=result.samples[index]
  _check(actual.get("clear")==expected_shoe_clear,"actual original pixel/polygon/source-solid class "+label+"/"+str(index))
  if actual.has("source_point_px"):
   # Stored actual evidence used the original default JSON writer. Normalize
   # only live expectation once, never round/recast the saved evidence.
   var encoded: Array=JSON.parse_string(JSON.stringify(actual.source_point_px))
   _check(encoded==row.source_shoe_px,"actual per-shoe source mapping original writer exact "+label+"/"+str(index))
  shoes+=1
 _check(result.get("clear")==expected_clear,"all17 conjunction, no center-only substitution "+label)
 rows+=1
 return result.get("clear")==true
func _fixtures() -> void:
 var raw: RefCounted=RAW.new()
 raw.set("size",Vector2(100,100)); raw.set("sampling","normalized_image_round"); raw.set("valid",true)
 var image:=Image.create(100,100,false,Image.FORMAT_RGBA8); image.fill(Color.WHITE)
 (raw.get("layers") as Array).append({"path":"SYNTHETIC_OWNED_IMAGE_NOT_FIELD","sha256":"fixture","rect":Rect2(0,0,100,100),"image":image,"native_tile":false})
 var source_size:=Vector2(100,100); var actual_size:=Vector2(200,300); var origin:=Vector2(80,120); var offset:=Vector2(0,20)
 var positive: Dictionary=phase.call("_release_legacy_foot_evidence",raw,source_size,actual_size,origin,offset)
 _check(positive.clear and positive.samples.size()==17,"synthetic nonuniform axes/nonzero visiblefoot positive")
 _check(_v(positive.samples[1].source_point_px).x-_v(positive.samples[0].source_point_px).x==5.,"10actual pixels maps to5source X, never resampled source10")
 _check(_v(positive.samples[5].source_point_px)==(Vector2(80,146)/actual_size)*source_size,"6actual pixels maps each Y directly; exact native arithmetic, no epsilon")
 for index in [0,1,5,9,13]:
  var p: Vector2=_v(positive.samples[index].source_point_px)
  var pixel:=Vector2i(roundi(p.x/100.*99.),roundi(p.y/100.*99.))
  image.set_pixelv(pixel,Color.BLACK)
  _check(phase.call("_release_legacy_foot_evidence",raw,source_size,actual_size,origin,offset).get("clear")==false,"actual predicate owned black center/side shoe "+str(index))
  image.set_pixelv(pixel,Color.WHITE)
 var edge: Vector2=_v(positive.samples[1].source_point_px)
 (raw.get("solids") as Array).append({"id":"SOURCE_GROWN_MARGIN_ONLY","kind":"grown_rectangle","rect":Rect2(edge-Vector2(.1,.1),Vector2(.2,.2))})
 var old_solids: PackedByteArray=var_to_bytes(raw.get("solids"))
 var solid_negative: Dictionary=phase.call("_release_legacy_foot_evidence",raw,source_size,actual_size,origin,offset)
 _check(solid_negative.clear==false and solid_negative.samples[0].clear==true and solid_negative.samples[1].source_solid_hits.size()==1,"original source margin hits side shoe though center is clear")
 _check(old_solids==var_to_bytes(raw.get("solids")),"no scaling/regrowing/mutation of source-grown margin")
 (raw.get("solids") as Array).clear()
 for bad: Variant in [null,1,"100",Vector2.ZERO,Vector2(-1,100),Vector2(NAN,100),Vector2(INF,100),Vector2(101,100)]:
  _check(phase.call("_release_legacy_foot_evidence",raw,bad,actual_size,origin,offset).get("clear")==false,"source size/type/domain rejects "+str(bad))
 for bad: Variant in [null,1,"200",Vector2.ZERO,Vector2(200,-1),Vector2(NAN,300),Vector2(INF,300),Vector2(100,100)]:
  _check(phase.call("_release_legacy_foot_evidence",raw,source_size,bad,origin,offset).get("clear")==false,"actual size/type/domain rejects "+str(bad))
 for bad: Variant in [null,1,"offset",Vector2(NAN,0),Vector2(INF,0),Vector2(0,1000)]:
  _check(phase.call("_release_legacy_foot_evidence",raw,source_size,actual_size,origin,bad).get("clear")==false,"visiblefoot offset wrong/nonfinite/outside rejects "+str(bad))
 for bad: Variant in [null,1,"root",Vector2(NAN,0),Vector2(-1,100),Vector2(199,100),Vector2(100,299)]:
  _check(phase.call("_release_legacy_foot_evidence",raw,source_size,actual_size,bad,Vector2.ZERO).get("clear")==false,"root/any side shoe outside actual domain rejects "+str(bad))
 _check(phase.call("_release_legacy_foot_evidence",null,source_size,actual_size,origin,offset).get("clear")==false,"missing raw source rejects")
 var short_raw: RefCounted=SixteenShoeFixture.new()
 short_raw.set("size",source_size); short_raw.set("valid",true); short_raw.set("sampling","normalized_image_round")
 for layer: Dictionary in raw.get("layers"): (short_raw.get("layers") as Array).append(layer.duplicate(true))
 _check(short_raw.get("sampling")=="normalized_image_round" and short_raw.call("samples",origin+offset).size()==16 and phase.call("_release_legacy_foot_evidence",short_raw,source_size,actual_size,origin,offset).get("clear")==false,"sixteen-shoe fixture rejected in correct legacy sampling domain")
 short_raw.call("release"); short_raw=null
 raw.set("sampling","round_world_pixel")
 _check(phase.call("_release_legacy_foot_evidence",raw,source_size,actual_size,origin,offset).get("clear")==false,"wrong native sampling domain rejects rather than substituting")
 raw.set("sampling","normalized_image_round")
 _delegation(raw,image)
 raw.call("release"); raw=null; image=null
func _run() -> void:
 _check(OS.get_cmdline_user_args().is_empty(),"pure units no gameplay flags")
 var env0: Dictionary=_env()
 _check(env0.driver=="WASAPI" and env0.exe_sha256==EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen engine/1x start")
 var actual_endpoint: Dictionary=_file(ACTUAL)
 _check(actual_endpoint.get("sha256")==ACTUAL_SHA,"fixed complete ROOT354 original failures/evidence")
 var actual: Dictionary=_read(ACTUAL)
 var pins: Dictionary=OLD_DIAG.PINS.duplicate(true)
 pins["res://tests/helpers/joint_v15_release_world_prepared_phase.gd"]=ADAPTER_SHA
 var self_path: String=get_script().resource_path
 var self_endpoint: Dictionary=_file(self_path)
 pins[ACTUAL]=ACTUAL_SHA; pins[CITY]=CITY_SHA; pins[self_path]=self_endpoint.sha256
 var before: Dictionary=_snapshot(pins,{ACTUAL:actual_endpoint,self_path:self_endpoint})
 for p: String in pins: _check(before[p].get("sha256")==pins[p],"fresh actual fixed input SHA "+p)
 var players0: Dictionary=_players(); var slot: Variant=root.get_node("SaveManager").get("active_slot")
 if not failures.is_empty(): quit(1); return
 var output: String="res://build/joint_world_luoyang_20261003_qa/legacy_actual_canvas_units_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique pure reader evidence directory")
 if not failures.is_empty(): quit(1); return
 phase=ADAPTER.new(); phase.set("owner_tree",self)
 _check(actual.get("original_phase_failures")==15 and actual.get("diagnostic_failures")==0 and actual.get("attempts",[]).size()==9,"preserved original353/354 failures not washed into new approval")
 var raws: Dictionary={}
 var source_solids: Dictionary={}
 for attempt: Dictionary in actual.attempts:
  var id: String=attempt.id
  if not raws.has(id):
   var definition: SceneScript=load(attempt.arrival.definition_path)
   var raw: RefCounted=RAW.new()
   _check(raw.call("configure",definition.map_layout,"normalized_image_round",-1.)==true,"real original three legacy layouts "+id)
   raws[id]=raw; source_solids[id]=var_to_bytes(raw.get("solids"))
   phase.set("ordinary_native_city",false)
   _check(phase.call("_release_ordinary_is_legacy",definition)==true,"actual original legacy scene selects only legacy adaptation "+id)
  var raw: RefCounted=raws[id]
  var size: Vector2=_v(attempt.arrival.field_world_size)
  _check(_actual_row(raw,size,attempt.arrival.point,id+"/"+attempt.mode+"/arrival"),"real arrival mapped positive "+id)
  _actual_row(raw,size,attempt.return_start,id+"/"+attempt.mode+"/intro_after")
  var eligible: int=0; var physics_denied: int=0
  for index in attempt.all80_original_candidates.size():
   var row: Dictionary=attempt.all80_original_candidates[index]
   var mapped: bool=_actual_row(raw,size,row,id+"/"+attempt.mode+"/"+str(index))
   if mapped and row.actual_Physics_clear and row.actual_foot_and_body_contains: eligible+=1
   if not row.actual_Physics_clear: physics_denied+=1
  _check(eligible=={"yanmen_pass":74,"gufeng":52,"lingyue":28}[id],"original80 fixed mapped/Area/actualPhysics attribution "+id)
  _check(physics_denied==(15 if id=="gufeng" else 0),"all15 original real MapBounds collisions preserved "+id)
  _check(var_to_bytes(raw.get("solids"))==source_solids[id] and raw.call("verify_sources")==true,"original source grown margins/PNGs unchanged "+id)
 _check(rows==738 and shoes==12546 and raws.size()==3,"all738 actual observations /12546 shoes /three original layouts, not subset")
 _fixtures()
 for raw: RefCounted in raws.values(): raw.call("release")
 raws.clear(); phase=null
 var after: Dictionary=_snapshot(pins); var env1: Dictionary=_env()
 _check(after==before and _players()==players0 and root.get_node("SaveManager").get("active_slot")==slot,"source bytes/SHA/mtime and all15 player files/slot unchanged")
 _check(env1.driver=="WASAPI" and env1.exe_sha256==EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen engine/1x finish")
 var report: Dictionary={"schema":1,"scope":"PURE_LEGACY_READER_ACTUAL738_AND_SYNTHETIC_NEGATIVES_NOT_FIELD","checks":checks,"failures":failures.size(),"errors":failures,"actual_rows":rows,"actual_shoes":shoes,"source_before":before,"source_after":after,"players_before":players0,"players_after":_players(),"environment_before":env0,"environment_after":env1,"actual_report_path":ACTUAL,"actual_report_sha256":ACTUAL_SHA,"source_complete":false,"release_complete":false,"Field_executed":false}
 _check(_write(output+"result.json",report),"unique pure reader JSON checked readback")
 print("V9E_LEGACY_ACTUAL_CANVAS_UNITS ",JSON.stringify({"checks":checks,"failures":failures.size(),"errors":failures,"actual_rows":rows,"actual_shoes":shoes,"output":output,"source_complete":false,"release_complete":false,"Field_executed":false}))
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if failures.is_empty() else 1)
