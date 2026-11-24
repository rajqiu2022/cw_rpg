extends SceneTree
## ROOT330 read-only witness diagnosis. Actual raw oracle only, no Field/Physics,
## derived rebuild, witness reselection, builder, publication or asset writes.
const RAW = preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const SOURCE := "res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST := "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const LAYOUT := "res://data/maps/world_map_jianghu_layout_v15.tres"
const ROOT330 := "res://build/joint_world_luoyang_20261003_qa/330_v9e_candidate_complete_release_headless_native_herb_fix_20261007/"
const PINS := {
 SOURCE:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
 MANIFEST:"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
 LAYOUT:"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
 ROOT330+"world_map_v15_complete_v9c_source.json":"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
 ROOT330+"world_map_jianghu_layout_v15.tres":"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
 "res://build/joint_world_luoyang_20261003_qa/world_release_197271897/actual_saved_geometry_112_references.json":"14591ea011e9e984e921274cde234ec6c6deaf367553d15bfa463b96c294cd77",
 "res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd":"7628d404d7587dfd885937ad1e26ac6a06f4e48ca53c273ccd8d5f1aee5db9db",
 "res://tests/helpers/v15_raw_world_oracle.gd":"c58043373af6154d5f7f79cfa2d0e8dcda38f3fbe0c6648a4af4ce626e8a9c51",
 "res://tests/helpers/joint_v15_v9c_world_geometry_phase.gd":"6ee5d11e56fb7d8cffaa2475abe801222cb94e417e2c8c0d4f0dac7586a02333",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd":"4d006169a3cc0f9dc347c467d4ab05204ee2f78be790e3c75c368d77e9b5abfb"
}
var checks: int=0
var errors: Array[String]=[]
var source_objects: Dictionary={}
var runtime_objects: Dictionary={}
var collision_rows: Dictionary={}
var failed_edges: Dictionary={}
var failure_kinds: Dictionary={}
var total: int=0
var denied: int=0
var raster_denied: int=0

func _initialize() -> void:
 call_deferred("_run")

func _check(ok: bool,label: String) -> void:
 checks+=1
 if not ok: errors.append(label)

func _read(path: String) -> Dictionary:
 var parser:=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary: return {}
 return parser.data

func _manifest_seams() -> Dictionary:
 var manifest: Dictionary=_read(MANIFEST)
 var result: Dictionary={}
 for seam: Dictionary in manifest.get("seams",[]):
  var id: String=String(seam.get("id",""))
  _check(not result.has(id),"unique actual manifest seam:"+id)
  result[id]={"classification":seam.get("classification"),"witnesses":seam.get("projected_witnesses")}
 return result

func _point(value: Array) -> Vector2:
 return Vector2(float(value[0]),float(value[1]))

func _fields(value: Dictionary) -> Dictionary:
 var result: Dictionary={}
 for key: String in ["id","role","kind","pose","blocking","pos","collision_size","collision_offset","collision_size_px","collision_center_world_px","walkability_margin_px","solid_polygons_px","source_XZ_foot_px","world_foot_px","texture"]:
  if value.has(key): result[key]=value[key]
 return result

func _contains(raw: RefCounted,center: Vector2) -> Array:
 var shoes: PackedVector2Array=raw.samples(center)
 var result: Array=[]
 for index in shoes.size(): result.append([])
 for entry: Dictionary in raw.blockers:
  var rect: Rect2=entry.grown
  if rect.position.x>center.x+10 or rect.end.x<center.x-10 or rect.position.y>center.y+6 or rect.end.y<center.y-6: continue
  for index in shoes.size():
   var hit: bool=Geometry2D.is_point_in_polygon(shoes[index],entry.polygon) if entry.get("shape")=="exact_world_polygon" else rect.has_point(shoes[index])
   if hit: result[index].append(entry.id)
 return result

func _center(raw: RefCounted,point: Vector2,full: bool=false) -> Dictionary:
 var samples: PackedVector2Array=raw.samples(point)
 var contains: Array=_contains(raw,point)
 var rows: Array=[]
 var raster_clear: bool=true
 var solid_clear: bool=true
 for index in samples.size():
  var pixel: Dictionary=raw.pixel_evidence(samples[index])
  raster_clear=raster_clear and bool(pixel.get("clear",false))
  solid_clear=solid_clear and contains[index].is_empty()
  if full:
   pixel["shoe_index"]=index
   pixel["source_solid_contains"]=contains[index]
   rows.append(pixel)
  else:
   # All17 exact sample points/pixels/RGBA are retained without repeating long
   # file paths; tile identities/path/SHA are separately emitted once.
   rows.append({"shoe":index,"point":[samples[index].x,samples[index].y],"pixel":pixel.get("pixel"),"rgba":pixel.get("rgba"),"nav_clear":pixel.get("clear"),"source_solid_contains":contains[index]})
 return {"center":[point.x,point.y],"all17_raster_clear":raster_clear,"all17_source_solids_clear":solid_clear,"samples":rows}

func _failure_objects(reason: Dictionary) -> Array:
 var result: Array=[]
 if reason.get("kind")!="source_collision": return result
 var id: String=String(reason.get("id",""))
 for entry: Dictionary in collision_rows.get(id,[]):
  result.append({"actual_oracle_collision":entry,"actual_source":source_objects.get(id,{}),"actual_published_layout":runtime_objects.get(id,{})})
 return result

func _run() -> void:
 var self_sha: String=FileAccess.get_sha256(get_script().resource_path)
 _check(OS.get_cmdline_user_args().is_empty(),"no filters, reselection or execution arguments")
 for path: String in PINS: _check(FileAccess.get_sha256(path)==PINS[path],"actual330 bound input before:"+path)
 var source: Dictionary=_read(SOURCE)
 var manifest_seams: Dictionary=_manifest_seams()
 var layout: Resource=ResourceLoader.load(LAYOUT,"",ResourceLoader.CACHE_MODE_IGNORE)
 var raw=RAW.new()
 if errors.is_empty():
  _check(raw.configure(layout),"actual current published layout/raw oracle configure")
  for obj: Dictionary in source.get("objects",[]): source_objects[String(obj.get("id",""))]=_fields(obj)
  for obj: Dictionary in layout.get("visual_objects"): runtime_objects[String(obj.get("id",""))]=_fields(obj)
  for obj: Dictionary in layout.get("blockers"): runtime_objects[String(obj.get("id",""))]=_fields(obj)
  for entry: Dictionary in raw.blockers:
   if not collision_rows.has(entry.id): collision_rows[entry.id]=[]
   collision_rows[entry.id].append(entry.duplicate(true))
  var tile_rows: Array=[]
  for cell: Vector2i in raw.tiles:
   var tile: Dictionary=raw.tiles[cell]
   _check(source.get("asset_sha256",{}).get(tile.path)==tile.sha256,"actual navigation PNG bound to pinned source catalog:"+tile.path)
   tile_rows.append({"cell":[cell.x,cell.y],"path":tile.path,"sha256":tile.sha256})
  print("V9E_SEAM_WITNESS_DIAGNOSTIC_TILES ",JSON.stringify(tile_rows))
  _check(source.get("seams",[]).size()==112 and manifest_seams.size()==112,"all112 authored/source+manifest boundaries")
  if errors.is_empty() and raw.valid:
   for seam: Dictionary in source.seams:
    var id: String=String(seam.id)
    var record_rows: Array=[]
    var manifest: Dictionary=manifest_seams.get(id,{})
    _check(seam.classification==manifest.get("classification") and seam.projected_witnesses==manifest.get("witnesses"),"actual source/manifest classification+witnesses identical:"+id)
    _check(seam.classification=="open" and seam.projected_witnesses.size()==12,"actual frozen12 OPEN witnesses:"+id)
    var line: float=float(seam.logical_rect_px[0 if seam.vertical else 1])+16.
    for wi in seam.projected_witnesses.size():
     var witness: Dictionary=seam.projected_witnesses[wi]
     var a: Vector2=_point(witness.from_px)
     var b: Vector2=_point(witness.to_px)
     var crossing: bool=a.x<line and b.x>line if seam.vertical else a.y<line and b.y>line
     var reason: Dictionary=raw.segment_evidence(a,b)
     var steps: int=maxi(1,ceili(a.distance_to(b)/4.))
     _check(steps==2,"actual writer three-center8px witness:"+id)
     var centers: Array=[]
     var raster_only: bool=true
     for index in range(steps+1):
      var row: Dictionary=_center(raw,a.lerp(b,float(index)/steps))
      raster_only=raster_only and bool(row.all17_raster_clear)
      centers.append(row)
     total+=1
     if not raster_only: raster_denied+=1
     var failure_foot: Dictionary={}
     if not crossing or not bool(reason.get("clear",false)):
      denied+=1
      failed_edges[id]=int(failed_edges.get(id,0))+1
      var kind: String=String(reason.get("kind","unknown")) if crossing else "does_not_cross"
      failure_kinds[kind]=int(failure_kinds.get(kind,0))+1
      if reason.get("center") is Array: failure_foot=_center(raw,_point(reason.center),true)
     record_rows.append({"witness":wi,"from_px":witness.from_px,"to_px":witness.to_px,"crossing":crossing,"raster_only_all3centers17shoes":raster_only,"three_centers_all17":centers,"actual_segment_evidence":reason,"first_failure_full17":failure_foot,"first_failure_objects":_failure_objects(reason)})
    print("V9E_SEAM_WITNESS_DIAGNOSTIC_EDGE ",JSON.stringify({"id":id,"classification":seam.classification,"witnesses":record_rows}))
 _check(total==1344,"all1344 witnessed segments actually diagnosed, not a failure subset")
 _check(raw.verify_sources(),"all64 actual navigation PNG bytes unchanged")
 _check(raw.errors.is_empty(),"actual raw oracle remains valid with no read errors")
 for path: String in PINS: _check(FileAccess.get_sha256(path)==PINS[path],"actual330 bound input after:"+path)
 _check(FileAccess.get_sha256(get_script().resource_path)==self_sha,"diagnostic source unchanged")
 print("V9E_SEAM_WITNESS_DIAGNOSTIC ",JSON.stringify({"scope":"READ_ONLY_ALL1344_FROZEN_WITNESS_RASTER_VS_SOURCE_COLLISION_DIAGNOSIS_NOT_FIELD_RELEASE","checks":checks,"diagnostic_failures":errors.size(),"diagnostic_errors":errors,"witnesses_diagnosed":total,"denied_witnesses":denied,"raster_denied_witnesses":raster_denied,"failed_edges":failed_edges,"failure_kinds":failure_kinds,"all_witnesses_clear":denied==0,"source_sha256":self_sha,"pins":PINS,"Field_executed":false,"Physics_queried":false,"witnesses_reselected":false,"assets_written":false,"release_complete":false}))
 raw.release()
 raw=null
 layout=null
 source_objects.clear()
 runtime_objects.clear()
 collision_rows.clear()
 var audio: Node=root.get_node_or_null("AudioManager")
 if audio!=null: audio.call("stop_bgm",.15)
 await create_timer(.25).timeout
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)

