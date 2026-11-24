extends SceneTree
## Read-only three-mesh diagnostic. No builder/factory/prepare/Field/publication.
## Expected geometry comes only from the pinned raw Shrub03 GLTF, selected by
## original pose and encoded through one original ArrayMesh native boundary.
const BASE := "res://data/maps/world_map_v15_complete_v8_source.json"
const CURRENT := "res://data/maps/world_map_v15_complete_v9c_source.json"
const RAW := "res://art/external/polyhaven/shrub_03/shrub_03_1k.gltf"
const ROOT8 := "res://art/maps/world_map_v15_complete_v8/prototypes/"
const ROOTC := "res://art/maps/world_map_v15_complete_v9c/prototypes/"
const ROOT5 := "res://art/maps/world_map_v15_complete_v5/prototypes/"
const PINS := {
 BASE:"13f3d5a9940283a92971ea20eae0234301635812dd0975a4c119536fb026cff5",
 CURRENT:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
 RAW:"b76d7c14bc027e834e82d3f984c32b5d060e62908aa90ff9420a637ca253a8ea",
 "res://art/external/polyhaven/shrub_03/shrub_03.bin":"bf4df21e6d2a2bc5f00b4c9142f776171fe7da00cf960001825748067af542b6",
 "res://art/external/polyhaven/shrub_03/textures/shrub_03_nor_gl_1k.jpg":"ff856bacfce859b8a7555dd9a3b92fbd36b2e775d486be71df485afb4235d6c9",
 "res://art/external/polyhaven/shrub_03/textures/shrub_03_diff_1k.jpg":"3cadc7aba46d3aabbd7d6d2b1d04aa32e2a7da0bc87c2d38ef3cb1ee42cb03ec",
 "res://art/external/polyhaven/shrub_03/textures/shrub_03_arm_1k.jpg":"3e2b16812a623037138eedace958210c5f3443a827bbe69663045bba5612f815",
 "res://scripts/dev/build_world_map_v15_complete_v5_full_draft.gd":"2e5efff6bf27f478bea3f6a1131c2919cdd502c6fa37f7969d60067a8c4d2f85",
 "res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd":"032a483213e99649b4adec193d24f413cc897ccc6b7de52a29f46a26abb9a23f",
 "res://tests/helpers/joint_v15_v9c_derived_geometry_probe.gd":"f165ef42649d82d42f26c8128a634338f17d77a6ed7a205cf54a64e8a911f52f"
}
const MESH_SHA := [
 "581cb860ad7f6e302d207f4e0650f77e6a5294e37b0e7c98808f21408d4b5e12",
 "8c801f2b04d2f0a070b26c0f5d50c0e71c3bf3bb537a3c1425207820f196c2eb",
 "81e09ba965a2c28647a95b2d68ab95439e5215b9f0c3b09bf7aed1e5e3f73af1"
]
const META8_SHA := [
 "8a1731bbc5b5b2be26a0275702a00e7419c7a92dc38d68ce02510fc38f4e0543",
 "a26ffb0ac51f45e48ce9c68ea060784f35e78139539aa158018a01f862890389",
 "16f2fb4308cd87c0a18620df56a9c72c454712fff9e13cd1aab79e81a81a4935"
]
const ORIGINAL_SHA := [
 "53e90bc14494dc2db0fdf80c2b573caa5ef5e853c6200a88846fc5147fbc8f44",
 "876f0005ea2300d9b455d54ae3a7b8b5b13e6255e2b082c6a2e134d2c6a8fbfb",
 "471ed22c3eb120d70b1ba32f896edf7b0c77fdeead485d934077467b3cd30218"
]
const METAC_SHA := [
 "e3d0b63ca99e6eab4b369f84ac1c8e1de3981be6a7a4d3b897be47e9785db745",
 "46fff336a5d197e799c637cee26ffaffe1bfdf86a04b00895f065d64e5bd9082",
 "a2bd1743a5df8d2d153b30dd98031c8b1ec51096d6fc6c29ad72ec4ffbf19cc6"
]
var checks: int=0
var errors: Array[String]=[]
var rows: Array[Dictionary]=[]

func _initialize() -> void:
 call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok: errors.append(label)
 return ok

func _read(path: String) -> Dictionary:
 var parser:=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary: return {}
 return parser.data

func _sha(bytes: PackedByteArray) -> String:
 var context:=HashingContext.new()
 context.start(HashingContext.HASH_SHA256)
 context.update(bytes)
 return context.finish().hex_encode()

func _equal(a: Variant,b: Variant) -> bool:
 if typeof(a)!=typeof(b): return false
 if a is Dictionary:
  if a.size()!=b.size(): return false
  for key in a:
   if not b.has(key) or not _equal(a[key],b[key]): return false
  return true
 if a is Array:
  if a.size()!=b.size(): return false
  for i in a.size():
   if not _equal(a[i],b[i]): return false
  return true
 return a==b

func _collect(node: Node,found: Array[MeshInstance3D]) -> void:
 if node is MeshInstance3D: found.append(node as MeshInstance3D)
 for child: Node in node.get_children(): _collect(child,found)

func _slot(value: Variant) -> Dictionary:
 if value==null: return {"type":TYPE_NIL,"count":0,"byte_count":0,"sha256":""}
 var bytes: PackedByteArray=value.to_byte_array()
 return {"type":typeof(value),"count":value.size(),"byte_count":bytes.size(),"sha256":_sha(bytes)}

func _same_slot(a: Variant,b: Variant) -> bool:
 if a==null or b==null: return a==null and b==null
 return typeof(a)==typeof(b) and a.to_byte_array()==b.to_byte_array()

func _prototype_rows(source: Dictionary,pose: int) -> Array:
 var result: Array=[]
 for item in source.get("objects",[]):
  if not item is Dictionary: continue
  var proto: Variant=item.get("prototype_actual_sourcebody_evidence")
  if proto is Dictionary and proto.get("kind")=="herb" and proto.get("pose")==pose:
   result.append(proto)
 return result

func _v3(value: Array) -> Vector3:
 return Vector3(float(value[0]),float(value[1]),float(value[2]))

func _bounds(control: ArrayMesh,basis: Basis,proto: Dictionary,key: String) -> Dictionary:
 var low:=Vector3(INF,INF,INF)
 var high:=Vector3(-INF,-INF,-INF)
 var points:=PackedVector3Array()
 for sid in control.get_surface_count():
  var arrays: Array=control.surface_get_arrays(sid)
  var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
  var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
  var seen: Dictionary={}
  for index: int in indices:
   if not _check(index>=0 and index<vertices.size(),"independent original used vertex index range:"+key): continue
   if seen.has(index): continue
   seen[index]=true
   var point: Vector3=basis*vertices[index]
   points.append(point)
   low=low.min(point)
   high=high.max(point)
 var total: float=0.
 var front: float=-INF
 var count: int=0
 for point: Vector3 in points:
  if point.y<=low.y+(high.y-low.y)*.02:
   total+=point.x
   front=maxf(front,point.z)
   count+=1
 if not _check(count>0,"independent original lowest2 percent support:"+key): return {}
 var support:=Vector3(total/count,low.y,front)
 var saved: Variant=proto.get("used_vertex_bounds_m")
 var saved_support: Variant=proto.get("support_m")
 var shape_ok: bool=saved is Array and saved.size()==2 and saved[0] is Array and saved[0].size()==3 and saved[1] is Array and saved[1].size()==3 and saved_support is Array and saved_support.size()==3
 _check(shape_ok,"original used bounds/support shapes:"+key)
 var exact: bool=shape_ok and low==_v3(saved[0]) and high==_v3(saved[1]) and support==_v3(saved_support)
 _check(exact,"independent raw-native used bounds/support exact native Vector3:"+key)
 return {"used_unique_vertices":points.size(),"lowest2_percent_vertices":count,"low_native_bytes":var_to_bytes(low).hex_encode(),"high_native_bytes":var_to_bytes(high).hex_encode(),"support_native_bytes":var_to_bytes(support).hex_encode(),"actual_metadata_native_exact":exact}

func _diagnose(pose: int,raw_mesh: ArrayMesh,selected_name: String,base: Dictionary,current: Dictionary) -> void:
 var key: String="herb"+str(pose)
 var path: String=ROOTC+"native_"+key+"_actual_draw_mesh.res"
 var metadata: Dictionary=_read(ROOTC+"native_"+key+".json")
 var original: Dictionary=_read(ROOT5+"native_"+key+".json")
 var base_rows: Array=_prototype_rows(base,pose)
 var current_rows: Array=_prototype_rows(current,pose)
 var expected_count: int=[121,114,125][pose]
 if not _check(base_rows.size()==expected_count and current_rows.size()==expected_count,"exact original/current herb pose population:"+key): return
 var proto: Dictionary=current_rows[0]
 for candidate in base_rows+current_rows:
  for field: String in ["kind","pose","basis_columns","actual_draw_mesh_sha256","actual_surfaces","draw_mesh_source","draw_mesh_source_sha256","used_vertex_bounds_m","support_m"]:
   _check(_equal(candidate.get(field),proto.get(field)),"all original/current pose records exact:"+key+"/"+field)
 for candidate in base_rows:
  _check(candidate.get("actual_draw_mesh_path")==ROOT8+"native_"+key+"_actual_draw_mesh.res","original exact pose mesh path:"+key)
 for candidate in current_rows:
  _check(candidate.get("actual_draw_mesh_path")==path,"current exact pose mesh path:"+key)
 _check(proto.get("actual_draw_mesh_path")==path and proto.get("actual_draw_mesh_sha256")==MESH_SHA[pose],"unique actual stored path/SHA:"+key)
 _check(proto.get("draw_mesh_source")==RAW and proto.get("draw_mesh_source_sha256")==PINS[RAW],"original raw GLTF source binding:"+key)
 for field: String in ["kind","pose","basis_columns","actual_surfaces","draw_mesh_source","draw_mesh_source_sha256"]:
  _check(_equal(metadata.get(field),proto.get(field)) and _equal(original.get(field),proto.get(field)),"original writer metadata evidence exact:"+key+"/"+field)
 var origin: Variant=proto.get("sourcebody_capture_origin")
 _check(origin is Dictionary and origin.get("original_metadata_path")==ROOT5+"native_"+key+".json" and origin.get("original_metadata_copy_path")==ROOTC+"native_"+key+"_original_metadata.json" and origin.get("original_metadata_sha256")==ORIGINAL_SHA[pose] and origin.get("actual_GPU_loaded_mesh_path")==ROOT5+"native_"+key+"_actual_draw_mesh.res" and origin.get("actual_GPU_loaded_mesh_sha256")==MESH_SHA[pose] and typeof(origin.get("new_mesh_artifact_is_exact_copy"))==TYPE_BOOL and origin.new_mesh_artifact_is_exact_copy==true,"actual v5-to-current original byte-copy provenance:"+key)
 # Original writer uses this Basis solely for support/capture; it is NOT baked
 # into draw mesh arrays. Replay original expected native Basis -> writer JSON.
 var basis:=Basis(Vector3.UP,deg_to_rad(25.+pose*65.)).scaled(Vector3.ONE*.65)
 var basis_json: Variant=JSON.parse_string(JSON.stringify([[basis.x.x,basis.x.y,basis.x.z],[basis.y.x,basis.y.y,basis.y.z],[basis.z.x,basis.z.y,basis.z.z]]))
 _check(_equal(proto.get("basis_columns"),basis_json),"independent original pose/metric Basis exact writer boundary:"+key)
 var stored: ArrayMesh=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
 if not _check(stored!=null and raw_mesh!=null,"actual stored/raw selected ArrayMesh:"+key): return
 var control:=ArrayMesh.new()
 for sid in raw_mesh.get_surface_count():
  control.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,raw_mesh.surface_get_arrays(sid))
 var bounds: Dictionary=_bounds(control,basis,proto,key)
 var evidence: Variant=proto.get("actual_surfaces")
 if not _check(evidence is Array and stored.get_surface_count()==control.get_surface_count() and stored.get_surface_count()==evidence.size(),"three same surface domains:"+key): return
 for sid in stored.get_surface_count():
  var raw_arrays: Array=raw_mesh.surface_get_arrays(sid)
  var actual_arrays: Array=stored.surface_get_arrays(sid)
  var expected_arrays: Array=control.surface_get_arrays(sid)
  var record: Dictionary=evidence[sid]
  var record_shas: Dictionary=record.get("draw_arrays_sha256",{})
  var expected_keys: Array=["0","1","4","12"]
  var keys: Array=record_shas.keys()
  keys.sort()
  expected_keys.sort()
  _check(keys==expected_keys and record.get("surface_index")==sid,"frozen writer exact four recorded slots:"+key+"/"+str(sid))
  _check(raw_arrays.size()==Mesh.ARRAY_MAX and actual_arrays.size()==Mesh.ARRAY_MAX and expected_arrays.size()==Mesh.ARRAY_MAX,"all thirteen slots present including nulls:"+key)
  var actual_format: int=stored.surface_get_format(sid)
  var control_format: int=control.surface_get_format(sid)
  _check(actual_format==control_format and record.get("native_surface_format")==actual_format,"independent native format exact stored+record:"+key)
  _check(stored.surface_get_primitive_type(sid)==Mesh.PRIMITIVE_TRIANGLES and control.surface_get_primitive_type(sid)==Mesh.PRIMITIVE_TRIANGLES,"original triangle primitive exact:"+key)
  var slot_rows: Array=[]
  for slot in Mesh.ARRAY_MAX:
   var same: bool=_same_slot(actual_arrays[slot],expected_arrays[slot])
   _check(same,"actual all-slot type/bytes vs independent raw-native control:"+key+"/"+str(sid)+"/"+str(slot))
   var actual_description: Dictionary=_slot(actual_arrays[slot])
   var recorded: bool=record_shas.has(str(slot))
   if recorded:
    _check(actual_arrays[slot]!=null and record_shas[str(slot)]==actual_description.sha256,"original four recorded SHA exact actual bytes:"+key+"/"+str(slot))
   slot_rows.append({"slot":slot,"raw_source":_slot(raw_arrays[slot]),"native_control":_slot(expected_arrays[slot]),"actual_saved":actual_description,"control_actual_type_and_bytes_exact":same,"raw_control_type_and_bytes_exact":_same_slot(raw_arrays[slot],expected_arrays[slot]),"writer_records_slot":recorded,"record_sha256":record_shas.get(str(slot),"")})
  var observation: Dictionary={"pose":pose,"selected_raw_node":selected_name,"selection_rule":"raw GLTF depth-first MeshInstance3D order; original pose modulo4; directory translation not applied","population":base_rows.size(),"path":path,"sha256":FileAccess.get_sha256(path),"surface":sid,"native_format":actual_format,"control_native_format":control_format,"original_record":record,"independent_basis_writer_exact":_equal(proto.get("basis_columns"),basis_json),"independent_raw_native_bounds":bounds,"slots":slot_rows}
  rows.append(observation)
  print("V9E_NATIVE_HERB_SURFACE ",JSON.stringify(observation))
 stored=null
 control=null

func _run() -> void:
 _check(OS.get_cmdline_user_args().is_empty(),"no filters or execution arguments")
 var self_sha: String=FileAccess.get_sha256(get_script().resource_path)
 var pins: Dictionary=PINS.duplicate()
 for pose in 3:
  var key: String="herb"+str(pose)
  pins[ROOT8+"native_"+key+"_actual_draw_mesh.res"]=MESH_SHA[pose]
  pins[ROOTC+"native_"+key+"_actual_draw_mesh.res"]=MESH_SHA[pose]
  pins[ROOT5+"native_"+key+"_actual_draw_mesh.res"]=MESH_SHA[pose]
  pins[ROOT8+"native_"+key+".json"]=META8_SHA[pose]
  pins[ROOTC+"native_"+key+".json"]=METAC_SHA[pose]
  pins[ROOTC+"native_"+key+"_original_metadata.json"]=ORIGINAL_SHA[pose]
  pins[ROOT8+"native_"+key+"_original_metadata.json"]=ORIGINAL_SHA[pose]
  pins[ROOT5+"native_"+key+".json"]=ORIGINAL_SHA[pose]
 for path: String in pins: _check(FileAccess.get_sha256(path)==pins[path],"immutable input before:"+path)
 var base: Dictionary=_read(BASE)
 var current: Dictionary=_read(CURRENT)
 if errors.is_empty():
  var document:=GLTFDocument.new()
  var state:=GLTFState.new()
  var code: int=document.append_from_file(RAW,state)
  if _check(code==OK,"pinned original raw GLTF native import"):
   var scene: Node=document.generate_scene(state)
   if _check(scene!=null,"pinned original GLTF generated owned scene"):
    var nodes: Array[MeshInstance3D]=[]
    _collect(scene,nodes)
    if _check(nodes.size()==4,"exact four original independent herb variants"):
     for pose in 3: _diagnose(pose,nodes[pose].mesh as ArrayMesh,String(nodes[pose].name),base,current)
    nodes.clear()
    scene.free()
 _check(rows.size()==3,"three unique actual stored herb surface observations")
 for path: String in pins: _check(FileAccess.get_sha256(path)==pins[path],"immutable input after:"+path)
 _check(FileAccess.get_sha256(get_script().resource_path)==self_sha,"diagnostic source unchanged")
 print("V9E_NATIVE_HERB_ARRAY_DIAGNOSTIC ",JSON.stringify({"scope":"READ_ONLY_RAW_GLTF_NATIVE_CODEC_THREE_HERB_MESH_DIAGNOSTIC_NOT_FIELD_RELEASE","checks":checks,"failures":errors.size(),"errors":errors,"unique_meshes":rows.size(),"pins":pins,"source_sha256":self_sha,"factory_called":false,"derived_geometry_helper_called":false,"builder_called":false,"written_resources":false,"Field_executed":false,"release_complete":false}))
 var audio: Node=root.get_node_or_null("AudioManager")
 if audio!=null: audio.call("stop_bgm",.15)
 await create_timer(.25).timeout
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)

