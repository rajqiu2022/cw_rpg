extends SceneTree
## PREPARATION ONLY: a new fixed physical plan, never a RELEASE result.
## Old ROOT234 selection and ROOT330/331 failed witnesses are preserved.
const RAW = preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const SOURCE := "res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST := "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const LAYOUT := "res://data/maps/world_map_jianghu_layout_v15.tres"
const ORIGINAL := "res://build/joint_world_luoyang_20261003_qa/release_selection_root234_20261005_01/representative_selection.json"
const DOMAIN := "res://build/joint_world_luoyang_20261003_qa/"
const FLAG := "--prepare-physical-seam-plan-only"
const ALGORITHM := "ALL112_EDGES_ALL4PX_CANDIDATES_FULL17_THREE_CENTERS_SOURCE_SOLIDS_THEN_12_EQUAL_RANKS_V1"
const PINS := {
 SOURCE:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
 MANIFEST:"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
 LAYOUT:"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
 ORIGINAL:"34a6ffd4b6da7adfc953c7339e1398c5a77e6f112399e4361350050246c4704f",
 "res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd":"7628d404d7587dfd885937ad1e26ac6a06f4e48ca53c273ccd8d5f1aee5db9db",
 "res://tests/helpers/v15_raw_world_oracle.gd":"c58043373af6154d5f7f79cfa2d0e8dcda38f3fbe0c6648a4af4ce626e8a9c51",
 "res://tests/test_joint_v9e_seam_witness_collision_diagnostic_20261007.gd":"5aaaeaf3789c7dfae1ad1447439d1e0107dd2692a096d5a75db2eaa4a159485f",
 "res://build/joint_world_luoyang_20261003_qa/world_release_197271897/actual_saved_geometry_112_references.json":"14591ea011e9e984e921274cde234ec6c6deaf367553d15bfa463b96c294cd77",
 "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd":"4d006169a3cc0f9dc347c467d4ab05204ee2f78be790e3c75c368d77e9b5abfb"
}
const EXPECTED_OLD_FAILURES := {"r1_c6--r1_c7":12,"r2_c4--r2_c5":12,"r4_c5--r4_c6":6,"r7_c1--r7_c2":9,"r7_c2--r7_c3":8,"r0_c1--r1_c1":6,"r0_c7--r1_c7":12,"r1_c5--r2_c5":12,"r1_c7--r2_c7":1,"r6_c2--r7_c2":8,"r6_c3--r7_c3":8}
var checks: int=0
var errors: Array[String]=[]
var retained: Dictionary={}
var old_failures: Array[Dictionary]=[]
var old_failure_edges: Dictionary={}
var original_witness_count: int=0
var scanned: int=0

func _initialize() -> void:
 call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok: errors.append(label)
 return ok

func _read(path: String) -> Dictionary:
 var parser:=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary:
  _check(false,"nonempty actual JSON dictionary:"+path)
  return {}
 return parser.data

func _equal(a: Variant,b: Variant) -> bool:
 if a is Dictionary and b is Dictionary:
  if a.size()!=b.size(): return false
  for key in a:
   if not b.has(key) or not _equal(a[key],b[key]): return false
  return true
 if a is Array and b is Array:
  if a.size()!=b.size(): return false
  for index in a.size():
   if not _equal(a[index],b[index]): return false
  return true
 if typeof(a) in [TYPE_INT,TYPE_FLOAT] and typeof(b) in [TYPE_INT,TYPE_FLOAT]:
  return is_finite(float(a)) and is_finite(float(b)) and a==b
 return typeof(a)==typeof(b) and a==b

func _retain(path: String,sha: String) -> void:
 _check(FileAccess.file_exists(path) and FileAccess.get_sha256(path)==sha,"actual preparation input SHA:"+path)
 retained[path]=sha

func _recheck() -> void:
 for path: String in retained:
  _check(FileAccess.file_exists(path) and FileAccess.get_sha256(path)==retained[path],"all original inputs unchanged:"+path)

func _point(value: Array) -> Vector2:
 return Vector2(float(value[0]),float(value[1]))

func _edge_matrix() -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for row in 8:
  for col in 7:
   result.append({"id":"r%d_c%d--r%d_c%d"%[row,col,row,col+1],"vertical":true,"line":(col+1)*1536,"start":row*1024,"length":1024})
 for row in 7:
  for col in 8:
   result.append({"id":"r%d_c%d--r%d_c%d"%[row,col,row+1,col],"vertical":false,"line":(row+1)*1024,"start":col*1536,"length":1536})
 return result

func _seam_map(rows: Array,label: String) -> Dictionary:
 var result: Dictionary={}
 for seam: Dictionary in rows:
  var id: String=String(seam.get("id",""))
  _check(not id.is_empty() and not result.has(id),"unique "+label+" seam:"+id)
  result[id]=seam
 _check(result.size()==112,"exact112 "+label+" seams")
 return result

func _manifest_witnesses() -> Dictionary:
 var manifest: Dictionary=_read(MANIFEST)
 var selected: Array=[]
 for seam: Dictionary in manifest.get("seams",[]):
  selected.append({"id":seam.get("id"),"classification":seam.get("classification"),"projected_witnesses":seam.get("projected_witnesses")})
 return _seam_map(selected,"manifest")

func _raster17(raw: RefCounted,a: Vector2,b: Vector2) -> bool:
 var clear: bool=true
 for index in 3:
  var center: Vector2=a.lerp(b,float(index)/2.)
  for shoe: Vector2 in raw.samples(center):
   var value: Dictionary=raw.pixel_evidence(shoe)
   clear=bool(value.get("clear",false)) and clear
 return clear

func _original_witnesses(raw: RefCounted,edge: Dictionary,seam: Dictionary,frozen: Dictionary) -> void:
 var id: String=edge.id
 _check(seam.get("classification")=="open" and _equal(seam.get("projected_witnesses"),frozen.get("projected_witnesses")) and seam.get("projected_witnesses",[]).size()==12,"all original ROOT234 captured witnesses unchanged:"+id)
 for wi in (seam.get("projected_witnesses",[]) as Array).size():
  var witness: Dictionary=seam.projected_witnesses[wi]
  var a: Vector2=_point(witness.from_px)
  var b: Vector2=_point(witness.to_px)
  var crossing: bool=a.x<edge.line and b.x>edge.line if edge.vertical else a.y<edge.line and b.y>edge.line
  _check(crossing and a.distance_to(b)==8. and _raster17(raw,a,b),"original1344 captured raster crossing/complete17 proof retained:"+id+"/"+str(wi))
  var actual: Dictionary=raw.segment_evidence(a,b)
  original_witness_count+=1
  if not bool(actual.get("clear",false)):
   var shape_ok: bool=actual.get("kind")=="source_collision" and typeof(actual.get("id"))==TYPE_STRING and actual.get("center") is Array and actual.get("point") is Array and typeof(actual.get("shoe_index"))==TYPE_INT
   _check(shape_ok,"original negative is real source solid with exact first shoe/center/point:"+id)
   old_failures.append({"seam_id":id,"original_witness_index":wi,"original_witness":witness.duplicate(true),"id":actual.get("id"),"center":actual.get("center"),"point":actual.get("point"),"shoe_index":actual.get("shoe_index"),"actual_segment_evidence":actual.duplicate(true),"requires_actual_live_Physics_recheck":true,"future_Physics_query_point":"exact blocked shoe point, matched object ownRID; not the Player center","raw_full17_denial_does_not_claim_Player_center_collision":true,"old_failure_claimed_passed":false})
   old_failure_edges[id]=int(old_failure_edges.get(id,0))+1

func _prepare() -> Dictionary:
 var self_path: String=get_script().resource_path
 _retain(self_path,FileAccess.get_sha256(self_path))
 for path: String in PINS: _retain(path,PINS[path])
 if not errors.is_empty(): return {}
 var original: Dictionary=_read(ORIGINAL)
 var source: Dictionary=_read(SOURCE)
 var authored: Dictionary=_seam_map(source.get("seams",[]),"source")
 var frozen: Dictionary=_seam_map(original.get("seams",[]),"ROOT234 original")
 var captured: Dictionary=_manifest_witnesses()
 _check(original.get("scope")=="PREEXECUTION_FIXED_RISK_STRATIFIED_SELECTION_NOT_TEST_RESULT" and original.get("object_count")==2687 and original.get("blocking_count")==2322 and original.get("unique_png_sha_count")==44 and original.get("representatives",[]).size()==130 and original.get("all_bindings",[]).size()==2687 and original.get("selection_replacement_after_failure_permitted")==false,"unchanged original130 representatives/2687bindings/all inventory contracts")
 var layout: Resource=ResourceLoader.load(LAYOUT,"",ResourceLoader.CACHE_MODE_IGNORE)
 var raw=RAW.new()
 _check(raw.configure(layout),"actual current published layout/raw independent source collider oracle")
 var tile_pins: Dictionary={}
 for cell: Vector2i in raw.tiles:
  var tile: Dictionary=raw.tiles[cell]
  _check(source.get("asset_sha256",{}).get(tile.path)==tile.sha256,"actual64 navigation PNGs pinned source catalog:"+tile.path)
  _retain(tile.path,tile.sha256)
  tile_pins[tile.path]=tile.sha256
 _check(tile_pins.size()==64,"all64 current raw navigation PNG identities")
 var plans: Array=[]
 if errors.is_empty():
  for edge: Dictionary in _edge_matrix():
   var id: String=edge.id
   if not _check(authored.has(id) and frozen.has(id) and captured.has(id),"independent full grid seam exists:"+id): continue
   var seam: Dictionary=authored[id]
   _check(seam.get("vertical")==edge.vertical and _equal(seam.get("logical_rect_px"),[edge.line-16 if edge.vertical else edge.start,edge.start if edge.vertical else edge.line-16,32 if edge.vertical else edge.length,edge.length if edge.vertical else 32]),"actual original seam grid axis/line/extent:"+id)
   _check(seam.get("classification")==captured[id].get("classification") and _equal(seam.get("projected_witnesses"),captured[id].get("projected_witnesses")),"source/manifest original captured witnesses exact:"+id)
   _original_witnesses(raw,edge,seam,frozen[id])
   var candidates: Array=[]
   var legal: Array=[]
   # Enumerate the full edge independently, not just old failed boundaries.
   # A failed candidate never shortens enumeration or selects a fallback live.
   for n in range(12,int(edge.length)-12,4):
    var center: Vector2=Vector2(edge.line,edge.start+n) if edge.vertical else Vector2(edge.start+n,edge.line)
    var a: Vector2=center-(Vector2(4,0) if edge.vertical else Vector2(0,4))
    var b: Vector2=center+(Vector2(4,0) if edge.vertical else Vector2(0,4))
    var proof: Dictionary=raw.segment_evidence(a,b)
    var centers: Array=[]
    var all_three: bool=true
    # Evaluate all three centers even when an earlier center is denied.
    for index in 3:
     var value: Dictionary=raw.foot_evidence(a.lerp(b,float(index)/2.))
     centers.append(value)
     all_three=bool(value.get("clear",false)) and all_three
    _check(bool(proof.get("clear",false))==all_three,"actual complete17 segment/three-center predicates agree:"+id+"/"+str(n))
    var row: Dictionary={"candidate_index":candidates.size(),"n":n,"from_px":[a.x,a.y],"to_px":[b.x,b.y],"clear":bool(proof.get("clear",false)),"actual_segment_evidence":proof,"all_three_full17_centers":centers}
    candidates.append(row)
    if bool(proof.get("clear",false)): legal.append(row)
    scanned+=1
   var selected: Array=[]
   var ranks: Array=[]
   if _check(legal.size()>=12,"at least12 physically clear candidates, no reduced edge coverage:"+id):
    var previous: int=-1
    for k in 12:
     var rank: int=floori(float(k)*float(legal.size()-1)/11.)
     _check(rank>previous and rank>=0 and rank<legal.size(),"twelve unique fixed equal-rank selections:"+id)
     selected.append(legal[rank].duplicate(true))
     ranks.append(rank)
     previous=rank
   plans.append({"id":id,"classification":"open","edge":edge,"original_captured_witnesses":seam.projected_witnesses.duplicate(true),"original_captured_scope":"RASTER_REFERENCE_ALL17_NOT_SOURCE_SOLID_PASS","candidate_count":candidates.size(),"legal_candidate_count":legal.size(),"all_candidates":candidates,"selected_legal_ranks":ranks,"physical_witnesses":selected,"actual_input_witness_indices":[0],"runtime_reselection_permitted":false})
   print("V9E_PHYSICAL_SEAM_PLAN_EDGE ",JSON.stringify({"id":id,"scanned":candidates.size(),"legal":legal.size(),"selected_ranks":ranks,"physical_witnesses":selected.size()}))
 _check(plans.size()==112 and scanned==35168,"all112 boundaries/all35168 four-pixel candidates scanned")
 _check(original_witness_count==1344 and old_failures.size()==94 and _equal(old_failure_edges,EXPECTED_OLD_FAILURES),"all original1344 raster witnesses plus exact94 source-collision negatives/11edges retained")
 _check(raw.verify_sources() and raw.errors.is_empty(),"all64 raw PNGs and oracle valid after complete scan")
 raw.release()
 raw=null
 layout=null
 _recheck()
 if not errors.is_empty(): return {}
 return {"schema":1,"scope":"PREEXECUTION_FIXED_PHYSICAL_SEAM_SELECTION_NOT_FIELD_RELEASE_OR_APPROVAL","algorithm_identity":ALGORITHM,"algorithm_source":{"path":self_path,"sha256":retained[self_path]},"input_sha256":retained.duplicate(),"raw_navigation_sha256":tile_pins,"origin_ROOT234_selection":{"path":ORIGINAL,"sha256":PINS[ORIGINAL],"object_count":2687,"blocking_count":2322,"representative_count":130,"all_bindings_count":2687,"object_selection_changed":false,"other_categories_changed":false},"selection_frozen_before_execution":true,"runtime_reselection_permitted":false,"selection_replacement_after_failure_permitted":false,"edge_count":112,"physical_static_witness_count":1344,"physical_actual_input_representative_count":112,"candidate_count":scanned,"candidate_step_px":4,"candidate_start_offset_px":12,"candidate_end_exclusive_offset_px":12,"selection_formula":"floor(k*(N-1)/11), k=0..11, N=all legal candidates in original enumeration order","seams":plans,"original_captured_witness_count":1344,"original_source_collision_negative_count":94,"original_source_collision_negative_edges":old_failure_edges,"original_source_collision_negatives":old_failures,"old_ROOT330_94_failures_preserved":true,"Field_executed":false,"actual_Physics_checked":false,"formal_approval":false,"visual_approved":false,"legacy_full_executed":false,"release_complete":false}

func _run() -> void:
 _check(OS.get_cmdline_user_args()==PackedStringArray([FLAG]),"only explicit prepare-physical-seam-plan-only argument")
 var plan: Dictionary=_prepare() if errors.is_empty() else {}
 var output: String=""
 if errors.is_empty() and not plan.is_empty():
  _recheck()
 if errors.is_empty() and not plan.is_empty():
  var directory: String=DOMAIN+"v9e_physical_seam_plan_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
  output=directory+"physical_seam_plan.json"
  var absolute: String=ProjectSettings.globalize_path(directory)
  if _check(not DirAccess.dir_exists_absolute(absolute) and not FileAccess.file_exists(output),"unique evidence domain, no existing output overwritten") and _check(DirAccess.make_dir_recursive_absolute(absolute)==OK,"new owned BUILD evidence directory"):
   var file:=FileAccess.open(output,FileAccess.WRITE)
   if _check(file!=null,"new physical plan opens"):
    var encoded: String=JSON.stringify(plan,"\t",true)
    file.store_string(encoded)
    file.flush()
    var io_error: Error=file.get_error()
    file.close()
    _check(io_error==OK and FileAccess.get_file_as_string(output)==encoded and FileAccess.get_sha256(output)==encoded.sha256_text(),"exact newly written plan bytes/flush/SHA/readback")
    var parsed: Dictionary=_read(output)
    _check(_equal(parsed,JSON.parse_string(encoded)),"new plan JSON readback exact saved writer domain")
    _recheck()
 print("V9E_PHYSICAL_SEAM_PLAN_PREPARATION ",JSON.stringify({"scope":"PREPARATION_ONLY_NOT_FIELD_RELEASE_APPROVAL","checks":checks,"failures":errors.size(),"errors":errors,"output":output,"output_sha256":FileAccess.get_sha256(output) if not output.is_empty() and FileAccess.file_exists(output) else "","edge_count":112 if not plan.is_empty() else 0,"candidate_count":scanned,"original_source_collision_negatives":old_failures.size(),"source_sha256":FileAccess.get_sha256(get_script().resource_path),"Field_executed":false,"release_complete":false,"formal_approval":false}))
 var audio: Node=root.get_node_or_null("AudioManager")
 if audio!=null: audio.call("stop_bgm",.15)
 await create_timer(.25).timeout
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)

