extends SceneTree
## Actual _native_bounds and the exact private surface predicate it calls.
## Owned in-memory corruptions only; no saved asset, factory, Field or RELEASE.
const PROBE = preload("res://tests/helpers/joint_v15_v9c_derived_geometry_probe.gd")
const HELPER := "res://tests/helpers/joint_v15_v9c_derived_geometry_probe.gd"
const HELPER_SHA := "23066b42f7f4d83c38335660f5d24a741c3abe6777d51622fa0126e39de6b7fd"
const CURRENT := "res://data/maps/world_map_v15_complete_v9c_source.json"
const CURRENT_SHA := "85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f"
var checks: int=0
var errors: Array[String]=[]
var cases: Array[Dictionary]=[]

func _initialize() -> void:
 call_deferred("_run")

func _check(ok: bool,label: String) -> void:
 checks+=1
 if not ok: errors.append(label)

func _read(path: String) -> Dictionary:
 var parser:=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary: return {}
 return parser.data

func _sha(bytes: PackedByteArray) -> String:
 var context:=HashingContext.new()
 context.start(HashingContext.HASH_SHA256)
 context.update(bytes)
 return context.finish().hex_encode()

func _find(source: Dictionary,pose: int) -> Dictionary:
 for obj in source.get("objects",[]):
  if not obj is Dictionary: continue
  var proto: Variant=obj.get("prototype_actual_sourcebody_evidence")
  if proto is Dictionary and proto.get("kind")=="herb" and proto.get("pose")==pose: return proto.duplicate(true)
 return {}

func _owned_arrays(arrays: Array) -> Array:
 var owned: Array=[]
 for value in arrays: owned.append(null if value==null else value.duplicate())
 return owned

func _bounds_negative(probe: RefCounted,valid: Dictionary,kind: String) -> void:
 var bad: Dictionary=valid.duplicate(true)
 var hashes: Dictionary=bad.actual_surfaces[0].draw_arrays_sha256
 var marker: String=""
 match kind:
  "missing_0","missing_1","missing_4","missing_12":
   hashes.erase(kind.trim_prefix("missing_"))
   marker="writer exact four recorded array keys"
  "alias_0","alias_1","alias_4","alias_12":
   var key: String=kind.trim_prefix("alias_")
   var digest: String=hashes[key]
   hashes.erase(key)
   hashes[int(key)]=digest
   marker="writer exact four recorded array keys"
  "basis_double_ulp_up","basis_double_ulp_down":
   var bytes: PackedByteArray=PackedFloat64Array([float(bad.basis_columns[0][0])]).to_byte_array()
   bytes.encode_s64(0,bytes.decode_s64(0)+(1 if kind.ends_with("_up") else -1))
   bad.basis_columns[0][0]=bytes.decode_double(0)
   _check(bad.basis_columns[0][0]!=valid.basis_columns[0][0] and JSON.stringify(bad)==JSON.stringify(valid),"actual DoubleULP differs but old JSON cache identity aliases:"+kind)
   marker="metadata selection: basis_columns"
  "extra_2":
   hashes["2"]="0".repeat(64)
   marker="writer exact four recorded array keys"
  "extra_numeric_key":
   hashes[2]="0".repeat(64)
   marker="writer exact four recorded array keys"
  "sha_0","sha_1","sha_4","sha_12":
   hashes[kind.trim_prefix("sha_")]="0".repeat(64)
   marker="used-source array byte SHA"
  "format":
   bad.actual_surfaces[0].native_surface_format+=1.
   marker="native format exact"
  "ordinal":
   bad.actual_surfaces[0].surface_index=1.
   marker="surface ordinal"
  "source":
   bad.draw_mesh_source="res://wrong.gltf"
   marker="metadata selection: draw_mesh_source"
  "source_sha":
   bad.draw_mesh_source_sha256="0".repeat(64)
   marker="metadata selection: draw_mesh_source_sha256"
  "source_type":
   bad.draw_mesh_source=7
   marker="metadata selection: draw_mesh_source"
  "pose_type":
   bad.pose=true
   marker="exact pose0/1/2"
  "basis":
   bad.basis_columns[0][0]+=.01
   marker="metadata selection: basis_columns"
  "metadata_path":
   bad.metadata_path="res://wrong.json"
   marker="same-domain herb metadata path"
  "origin":
   bad.sourcebody_capture_origin.original_metadata_sha256="0".repeat(64)
   marker="mesh-copy provenance"
  "mesh_sha":
   bad.actual_draw_mesh_sha256="0".repeat(64)
   marker="saved mesh/Basis SHA"
  "bounds":
   bad.used_vertex_bounds_m[0][0]+=.01
   marker="used-bounds/support exact"
  "support":
   bad.support_m[0]+=.01
   marker="used-bounds/support exact"
 for attempt in 2:
  probe.errors.clear()
  var value: Dictionary=probe._native_bounds(bad)
  var failed: bool=not probe.errors.is_empty()
  var targeted: bool=false
  for message: String in probe.errors:
   if marker in message: targeted=true
  _check(failed and value.is_empty() and targeted,"same warmed probe rejects actual bounds mutation twice:"+str(valid.pose)+"/"+kind+"/"+str(attempt))
  cases.append({"API":"_native_bounds","pose":valid.pose,"mutation":kind,"same_probe_after_positive":true,"attempt":attempt,"rejected":failed,"errors":probe.errors.duplicate()})
 probe.errors.clear()
 _check(not probe._native_bounds(valid).is_empty() and probe.errors.is_empty(),"valid cached prototype remains valid after negative:"+kind)

func _surface_negative(probe: RefCounted,actual: Array,expected: Array,format: int,row: Dictionary,kind: String) -> void:
 var original_sha: String=_sha(var_to_bytes(actual))
 var expected_sha: String=_sha(var_to_bytes(expected))
 var owned: Array=_owned_arrays(actual)
 var owned_row: Dictionary=row.duplicate(true)
 var actual_format: int=format
 var primitive: int=Mesh.PRIMITIVE_TRIANGLES
 match kind:
  "tangent_bytes": owned[Mesh.ARRAY_TANGENT][0]+=.125
  "tangent_type": owned[Mesh.ARRAY_TANGENT]=PackedFloat64Array([1.,0.,0.,1.])
  "tangent_null": owned[Mesh.ARRAY_TANGENT]=null
  "extra_slot": owned[Mesh.ARRAY_COLOR]=PackedColorArray([Color.WHITE])
  "vertex_bytes": owned[Mesh.ARRAY_VERTEX][0]+=Vector3(.125,0,0)
  "normal_bytes": owned[Mesh.ARRAY_NORMAL][0]+=Vector3(.125,0,0)
  "uv_bytes": owned[Mesh.ARRAY_TEX_UV][0]+=Vector2(.125,0)
  "index_bytes": owned[Mesh.ARRAY_INDEX][0]+=1
  "missing_slot": owned.pop_back()
  "added_slot": owned.append(null)
  "format": actual_format=actual_format^4
  "primitive": primitive=Mesh.PRIMITIVE_LINES
  "record_type": owned_row.draw_arrays_sha256="bad"
 probe.errors.clear()
 var ok: bool=probe._herb_surface_arrays(owned,expected,actual_format,format,primitive,owned_row,0)
 _check(not ok and not probe.errors.is_empty(),"real all-slot predicate rejects owned mutation:"+kind)
 _check(_sha(var_to_bytes(actual))==original_sha and _sha(var_to_bytes(expected))==expected_sha,"packed arrays independent ownership preserved:"+kind)
 cases.append({"API":"_herb_surface_arrays (same predicate used by _native_bounds)","mutation":kind,"rejected":not ok,"errors":probe.errors.duplicate(),"Field_executed":false})
 owned.clear()
 _check(_sha(var_to_bytes(actual))==original_sha and _sha(var_to_bytes(expected))==expected_sha,"owned cleanup preserves both original arrays:"+kind)
 probe.errors.clear()

func _run() -> void:
 var self_sha: String=FileAccess.get_sha256(get_script().resource_path)
 _check(OS.get_cmdline_user_args().is_empty(),"no filters or execution arguments")
 _check(FileAccess.get_sha256(HELPER)==HELPER_SHA,"exact actual helper SHA before")
 _check(FileAccess.get_sha256(PROBE.BASE_SOURCE)==PROBE.BASE_PINS[PROBE.BASE_SOURCE] and FileAccess.get_sha256(CURRENT)==CURRENT_SHA,"actual original/current sources before")
 var original: Dictionary=_read(PROBE.BASE_SOURCE)
 var current: Dictionary=_read(CURRENT)
 var original_bytes: String=_sha(JSON.stringify(original).to_utf8_buffer())
 var current_bytes: String=_sha(JSON.stringify(current).to_utf8_buffer())
 var probe=PROBE.new()
 if errors.is_empty():
  for pose in 3:
   var base: Dictionary=_find(original,pose)
   var candidate: Dictionary=_find(current,pose)
   _check(not base.is_empty() and not candidate.is_empty(),"actual original/current three pose records:"+str(pose))
   if base.is_empty() or candidate.is_empty(): continue
   for positive: Dictionary in [base,candidate]:
    probe.errors.clear()
    var actual: Dictionary=probe._native_bounds(positive)
    _check(not actual.is_empty() and probe.errors.is_empty(),"real independent native bounds positive:"+str(pose)+"/"+positive.actual_draw_mesh_path)
    _check(not probe._native_bounds(positive).is_empty() and probe.errors.is_empty(),"same valid prototype cache positive:"+str(pose))
    cases.append({"API":"_native_bounds","pose":pose,"path":positive.actual_draw_mesh_path,"positive":true,"passed":not actual.is_empty() and probe.errors.is_empty(),"bounds":actual})
   for kind: String in ["missing_0","missing_1","missing_4","missing_12","extra_2","extra_numeric_key","sha_0","sha_1","sha_4","sha_12","format","ordinal","source","source_sha","source_type","pose_type","basis","metadata_path","origin","mesh_sha","bounds","support","alias_0","alias_1","alias_4","alias_12","basis_double_ulp_up","basis_double_ulp_down"]:
    _bounds_negative(probe,base,kind)
   var mesh: ArrayMesh=ResourceLoader.load(String(base.actual_draw_mesh_path),"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
   var control: ArrayMesh=probe._herb_control(base)
   if mesh!=null and control!=null:
    var actual_arrays: Array=mesh.surface_get_arrays(0)
    var expected_arrays: Array=control.surface_get_arrays(0)
    for kind: String in ["tangent_bytes","tangent_type","tangent_null","extra_slot","vertex_bytes","normal_bytes","uv_bytes","index_bytes","missing_slot","added_slot","format","primitive","record_type"]:
     _surface_negative(probe,actual_arrays,expected_arrays,mesh.surface_get_format(0),base.actual_surfaces[0],kind)
    actual_arrays.clear()
    expected_arrays.clear()
   else: _check(false,"actual saved mesh and independent original control available for surface negatives")
   mesh=null
   control=null
  _check(probe.herb_controls.size()==3 and probe.native_cache.size()==6,"only three per-run raw controls/six original-current prototype pass entries; invalid records never cached")
 _check(_sha(JSON.stringify(original).to_utf8_buffer())==original_bytes and _sha(JSON.stringify(current).to_utf8_buffer())==current_bytes,"all original/current in-memory sources unchanged")
 probe.errors.clear()
 probe._herb_inputs_unchanged()
 _check(probe.errors.is_empty(),"all consumed raw/source/metadata/mesh dependencies final SHA")
 var input_pins: Dictionary=probe.herb_input_pins.duplicate()
 var helper_checks: int=probe.checks
 probe.release()
 _check(probe.errors.is_empty() and probe.herb_controls.is_empty() and probe.herb_input_pins.is_empty() and probe.native_cache.is_empty(),"release rechecks pins and clears only owned controls/caches")
 _check(_sha(JSON.stringify(original).to_utf8_buffer())==original_bytes and _sha(JSON.stringify(current).to_utf8_buffer())==current_bytes,"release does not clear caller dictionaries")
 _check(FileAccess.get_sha256(HELPER)==HELPER_SHA and FileAccess.get_sha256(get_script().resource_path)==self_sha,"actual helper/unit sources unchanged")
 _check(FileAccess.get_sha256(PROBE.BASE_SOURCE)==PROBE.BASE_PINS[PROBE.BASE_SOURCE] and FileAccess.get_sha256(CURRENT)==CURRENT_SHA,"actual original/current sources after")
 print("V9E_NATIVE_HERB_CONSUMER_UNITS ",JSON.stringify({"scope":"ACTUAL_NATIVE_BOUNDS_AND_SAME_ALL13_SLOT_PREDICATE_ONLY_NOT_FIELD_RELEASE","checks":checks,"helper_checks":helper_checks,"failures":errors.size(),"errors":errors,"cases":cases,"source_sha256":self_sha,"helper_sha256":HELPER_SHA,"input_pins":input_pins,"frozen_assets_written":false,"factory_called":false,"builder_called":false,"Field_executed":false,"release_complete":false}))
 var audio: Node=root.get_node_or_null("AudioManager")
 if audio!=null: audio.call("stop_bgm",.15)
 await create_timer(.25).timeout
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)
