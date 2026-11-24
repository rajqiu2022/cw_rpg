extends SceneTree
## Real preparation API with SHA-bound original RF/source. Route-only QA, not
## RF derivation, renderer, Field/input/FULL/visual/RELEASE or formal approval.
const PROBE = preload("res://tests/helpers/joint_v15_v9c_derived_geometry_probe.gd")
const HELPER := "res://tests/helpers/joint_v15_v9c_derived_geometry_probe.gd"
const SOURCE := "res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST := "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const FULL := "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const CPU := "res://build/world_map_v15_v9c_visual_quality_proposal/v9d_broad_soft/1791124651_1751026/derived_geometry/derivation_report.json"
const PINS := {
 HELPER:"f165ef42649d82d42f26c8128a634338f17d77a6ed7a205cf54a64e8a911f52f",
 SOURCE:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
 MANIFEST:"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
 FULL:"cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851",
 CPU:"707870fe709b12f9df4eeff76fb253b08c41631bc87065ab2d638828c674f1a0",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd":"4d006169a3cc0f9dc347c467d4ab05204ee2f78be790e3c75c368d77e9b5abfb",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd":"74a7757a43c7ff4e339fa297bf29a0ec7860cf6a70f7508ebd80a418ce18e233"
}
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

func _route(rows: Array,id: String) -> Dictionary:
 for row: Dictionary in rows:
  if row.get("id")==id: return row
 return {}

func _rf_hash(value: PackedFloat32Array) -> String:
 var context:=HashingContext.new()
 context.start(HashingContext.HASH_SHA256)
 if not value.is_empty(): context.update(value.to_byte_array())
 return context.finish().hex_encode()

func _prepare(value: Dictionary,audit: Dictionary,rf: PackedFloat32Array,expected: bool,label: String,failure_marker: String="") -> void:
 var original_size: int=rf.size()
 var original_sha: String=_rf_hash(rf)
 var valid: bool=original_size==PROBE.GRID.x*PROBE.GRID.y and original_sha==PROBE.BASE_PINS[PROBE.BASE_RF]
 _check(valid,"caller complete original RF size/SHA before case:"+label)
 if not valid: return
 var probe=PROBE.new()
 # Packed arrays are shared references here: release() intentionally clears its
 # owned input. Explicit duplicate prevents that cleanup from clearing caller RF.
 var owned_rf: PackedFloat32Array=rf.duplicate()
 probe.old_height=owned_rf
 var owned_valid: bool=probe.old_height.size()==original_size and _rf_hash(probe.old_height)==original_sha
 _check(owned_valid,"owned duplicate complete RF before real API:"+label)
 if not owned_valid:
  probe.release()
  return
 var before: String=JSON.stringify(value.v9c_revision_evidence.prepared_native_routes)
 var ok: bool=probe._prepare_native_inputs(value,audit)
 _check(ok==expected,label)
 _check(probe.old_height.size()==original_size and _rf_hash(probe.old_height)==original_sha,"real API preserves owned RF size/bytes:"+label)
 if not expected:
  var targeted: bool=false
  for message: String in probe.errors:
   if message.contains(failure_marker): targeted=true
  _check(not failure_marker.is_empty() and targeted,"actual rejection reaches targeted predicate:"+label)
 _check(JSON.stringify(value.v9c_revision_evidence.prepared_native_routes)==before,"API leaves all original native route points unchanged:"+label)
 if expected:
  _check(probe.original_bridge_domains.size()==5 and not probe.road_buckets.is_empty() and not probe.rf_road_buckets.is_empty() and not probe.original_road_buckets.is_empty(),"real five bridge domains plus all three native road bucket families")
  _check(_route(value.v9c_revision_evidence.prepared_native_routes,"portal_bianzhou").points.size()==149 and _route(value.routes,"portal_bianzhou").points_px.size()==5,"actual149 native road points retained independently of five world bends")
 cases.append({"case":label,"actual_prepare_API_executed":true,"passed":ok,"checks":probe.checks,"errors":probe.errors.duplicate(),"Field_executed":false})
 probe.release()
 _check(probe.old_height.is_empty() and owned_rf.is_empty(),"release clears only its owned packed RF:"+label)
 _check(rf.size()==original_size and _rf_hash(rf)==original_sha,"caller RF independent ownership survives release:"+label)

func _run() -> void:
 _check(OS.get_cmdline_user_args().is_empty(),"no execution/filter arguments")
 var self_sha: String=FileAccess.get_sha256(get_script().resource_path)
 var pins: Dictionary=PINS.duplicate()
 for path: String in PROBE.BASE_PINS: pins[path]=PROBE.BASE_PINS[path]
 for path: String in pins: _check(FileAccess.get_sha256(path).to_lower()==pins[path],"actual frozen source before:"+path)
 var source: Dictionary=_read(SOURCE)
 var manifest: Dictionary=_read(MANIFEST)
 var cpu: Dictionary=_read(CPU)
 _check(not source.is_empty() and not manifest.is_empty() and cpu.get("audit") is Dictionary,"actual source/manifest/CPU audit")
 if errors.is_empty():
  var probe=PROBE.new()
  var binding: Dictionary=probe.bindings_report(source.v9c_revision_evidence.derived_geometry_inputs,manifest,source)
  _check(binding.failed==0 and binding.complete==true,"real original bindings_report all branches, not report self-certification")
  probe.release()
  var rf: PackedFloat32Array=FileAccess.get_file_as_bytes(PROBE.BASE_RF).to_float32_array()
  _check(rf.size()==PROBE.GRID.x*PROBE.GRID.y,"complete actual old Float32 RF lattice loaded, not rederived")
  _prepare(source,cpu.audit,rf,true,"all27 actual native/projected routes and all3 native rivers")
  for kind: String in ["bridge_missing","bridge_identity_type","bridge_domain_changed","bridge_height_changed","bridge_domain_type","route_width","route_missing","generic_point_count","generic_bridge_projection","bianzhou_bend","bianzhou_matching_fake_bends","bianzhou_native_sample","bianzhou_native_missing","bianzhou_world_record","bianzhou_native_record","bianzhou_RF_record","bianzhou_bridge_flag","bianzhou_record_missing","river_sample"]:
   var bad: Dictionary=source.duplicate(true)
   var native: Dictionary=_route(bad.v9c_revision_evidence.prepared_native_routes,"portal_bianzhou")
   var projected: Dictionary=_route(bad.routes,"portal_bianzhou")
   match kind:
    "bridge_missing": bad.structures.pop_back()
    "bridge_identity_type": bad.structures[0].id=7
    "bridge_domain_changed": bad.structures[0].source_deck_polygon[0][0]+=1.
    "bridge_height_changed": bad.structures[0].deck_height_m=1.
    "bridge_domain_type": bad.structures[0].source_deck_polygon=null
    "route_width": projected.width_px+=1.
    "route_missing": bad.v9c_revision_evidence.prepared_native_routes.pop_back()
    "generic_point_count": _route(bad.routes,"northeastern_trade").points_px.pop_back()
    "generic_bridge_projection": _route(bad.routes,"northeastern_trade").points_px[0][1]+=1.
    "bianzhou_bend": projected.points_px[1][0]+=1.
    "bianzhou_matching_fake_bends":
     projected.points_px[1][0]+=1.
     bad.v7_revision_evidence.bianzhou_projected_world_approach[1][0]+=1.
    "bianzhou_native_sample": native.points[30][0]+=1.
    "bianzhou_native_missing": native.points.pop_back()
    "bianzhou_world_record": bad.v7_revision_evidence.inverse_RF_records[30].world_px[0]+=1.
    "bianzhou_native_record": bad.v7_revision_evidence.inverse_RF_records[30].source_XZ_px[0]+=1.
    "bianzhou_RF_record": bad.v7_revision_evidence.inverse_RF_records[0].projected_RF_px[1]+=1.
    "bianzhou_bridge_flag": bad.v7_revision_evidence.inverse_RF_records[0].bridge_deck_Y0=false
    "bianzhou_record_missing": bad.v7_revision_evidence.inverse_RF_records.pop_back()
    "river_sample": bad.v9c_revision_evidence.prepared_native_rivers[0].points[0][0]+=1.
   var failure_marker: String
   match kind:
    "bridge_missing": failure_marker="exact five original/current bridge projection domains"
    "bridge_identity_type","bridge_domain_changed","bridge_height_changed","bridge_domain_type": failure_marker="original/current exact bridge identity/Y0/domain"
    "route_width": failure_marker="native/prepared/projected route real width"
    "route_missing": failure_marker="captured exact pre-bind native route/river inputs"
    "generic_point_count","generic_bridge_projection": failure_marker="(.01 original contract): northeastern_trade"
    "bianzhou_bend","bianzhou_matching_fake_bends": failure_marker="independent original fixed five Bianzhou world bends"
    "river_sample": failure_marker="independent entire native river Catmull-Rom exact"
    _: failure_marker="all149 native points/4px samples/32-step inverse/RF projection/bridge flags exact original writer"
   _prepare(bad,cpu.audit,rf,false,"actual API rejects in-memory corruption:"+kind,failure_marker)
  rf.clear()
 for path: String in pins: _check(FileAccess.get_sha256(path).to_lower()==pins[path],"actual frozen source after:"+path)
 _check(FileAccess.get_sha256(get_script().resource_path)==self_sha,"unit source unchanged")
 print("V9E_DERIVED_ROUTE_PROJECTION_UNITS ",JSON.stringify({"scope":"SHA_BOUND_ACTUAL_ORIGINAL_RF_ROUTE_PREPARATION_API_ONLY_NOT_FIELD_DERIVATION_RELEASE","checks":checks,"failures":errors.size(),"errors":errors,"cases":cases,"source_sha256":self_sha,"pins":pins,"RF_reconstructed":false,"builder_invoked":false,"renderer_invoked":false,"Field_executed":false,"release_complete":false,"formal_cutover":false}))
 var audio: Node=root.get_node_or_null("AudioManager")
 if audio!=null: audio.call("stop_bgm",.15)
 await create_timer(.25).timeout
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)



