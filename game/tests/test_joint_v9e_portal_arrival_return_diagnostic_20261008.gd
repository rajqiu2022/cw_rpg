extends SceneTree
## LIMITED actual original normal-input diagnosis: three fixed portals x three
## modes. Expected original failures are retained, not converted into RELEASE
## approval. No authored landing/geometry/collision/threshold changes.
const RAW=preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const CONTEXT=preload("res://tests/helpers/joint_v15_v9e_source_context_oracle.gd")
const FROZEN: String="res://build/joint_world_luoyang_20261003_qa/353_v9e_candidate_complete_release_headless_ecology_domains_20261008/frozen_inputs.json"
const SOURCE: String="res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST: String="res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const WORLD: String="res://data/scenes/world_map_jianghu_v15.tres"
const EXE_SHA: String="975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const IDS: Array[String]=["yanmen_pass","gufeng","lingyue"]
const MODES: Array[String]=["space","door_mouse","arrow"]
const PINS: Dictionary={
 FROZEN:"6400e26f1d7a2435ab27fe0422e9801e75580d72f743cff5ad02a0335f2a4488",
 SOURCE:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
 MANIFEST:"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
 WORLD:"31c5034e44092f146879e45715b97425c6e899e8ef1c375c94f03b2a35fc9065",
 "res://data/maps/world_map_jianghu_layout_v15.tres":"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
 "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":"c18e5318956188059991911963e713d7042b037f582d8e95b3f76afc2952b7d5",
 "res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd":"16a66f74eba277c9dcf7c1a6801bb5183d0fedf363a3e6fc3805bc41e7474970",
 "res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
 "res://tests/helpers/joint_v15_v9e_source_context_oracle.gd":"52ade58531971527afe8b9cd6cb899b0325c42f3f41fa7f09426835231b9c4bc",
 "res://tests/helpers/joint_v15_wall_v5_ordinary_raw_oracle.gd":"46c3d80b804a2c2566d60563e500c2e84d9369a9ae80d246466a4b5c6a56b4a5",
 "res://tests/helpers/v15_field_raw_oracle.gd":"dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb",
 "res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd":"7628d404d7587dfd885937ad1e26ac6a06f4e48ca53c273ccd8d5f1aee5db9db",
 "res://tests/helpers/v15_raw_world_oracle.gd":"c58043373af6154d5f7f79cfa2d0e8dcda38f3fbe0c6648a4af4ce626e8a9c51",
 "res://scripts/autoload/scene_router.gd":"f3ead7459632188350e1e3383ee915c83b71c1b86d36dadf718bd338a4324eca",
 "res://scripts/field/field_walkable_controller.gd":"b3301d6064e332e519b0fc3b4daed880ec3d77d98f2c744933b5d7077b9eb8ef",
 "res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
 "res://scripts/field/exit_zone.gd":"bf0ee27eacdb592dc977e378e9e4b7fbe1c6e695f9101cd9415a303747e22bc5",
 "res://scripts/domain/scene_script.gd":"e01a01ba69d13492441960972109d32ba0c62b1e0e881c5b805b11b73cb41bef",
 "res://scripts/domain/walkable_map_layout.gd":"c90f62df3f1b3f88b2e361568903e5f35c7440e445115c3003656c3312eed451",
 "res://data/maps/world_map_v15_complete_v9c_visual_review.json":"59418b6e68d2e4f5613893b4a72946e47c0bee8e8a361e3eb7b1fc4ad241929d",
 "res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json":"72c942db3430e2ae58326b3acd330643d8c90e0cadf073d3ba731582f902f242",
 "res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json":"cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851",
 "res://data/scenes/openworld_yanmen_pass.tres":"e7741cb1a15f5b38a1c37d79e3c8661cfff91eebcada78ac76fa5b2f5da71880",
 "res://data/scenes/ch5_s1_relief_road.tres":"62a58bbd47cd5324a68351022ce7dfa1d8bd5a931996bdc531646aef4db1c052",
 "res://data/scenes/ch2_s4_lingyue_gate.tres":"2fe5a8a1ce0f6f7cf2866a0f8c31b3fd9b5ddda9e25c960103f5d5de4a7175ee",
 "res://data/maps/openworld_yanmen_pass_layout.tres":"b81cde81c5b2221c9940e4e8643bc94b18260374932e33ae25dbdef53f111073",
 "res://data/maps/ch5_s1_relief_road_layout_v1.tres":"c2754ab6b1b31f4de8fc85b71a5a8f031251d8917a48c3212118f19df7563525",
 "res://data/maps/ch2_s4_lingyue_gate_layout_v1.tres":"fc8f92c5a51206ac977e2f058b715225673f808f1344257a052f04a72c7af3f6",
 "res://build/joint_world_luoyang_20261003_qa/world_release_195402602/actual_world_artifact_semantics.json":"b4c8274968113cd6a22376050a821ff490bb5845a53d65f08a7d517ce0507fc3",
 "res://build/joint_world_luoyang_20261003_qa/world_release_195402602/release_112_seams_actual_input.json":"133e032486c0760063ad785ca395712e3477a80a3eb46b0cfa24c71b7ebb921e"
}

class DiagnosticDriver extends "res://tests/helpers/v15_input_driver.gd":
 var last_plan: Dictionary={}
 # Original a3c59 plan, same short-circuit order, queue, cap, geometry and
 # returns; additions only observe the branch/queue immediately before return.
 func plan(from: Vector2,to: Vector2,size: Vector2,independent_clear: Callable,independent_segment: Callable) -> PackedVector2Array:
  last_plan={"from":[from.x,from.y],"to":[to.x,to.y],"size":[size.x,size.y],"step":32,"cursor_cap":20000,"status":"started"}
  if not independent_clear.is_valid() or not independent_segment.is_valid():
   last_plan.status="invalid_callbacks"; return PackedVector2Array()
  if not bool(independent_clear.call(from)):
   last_plan.status="start_full17_or_Physics_denied"; return PackedVector2Array()
  if not bool(independent_clear.call(to)):
   last_plan.status="target_full17_or_Physics_denied"; return PackedVector2Array()
  var direct: Dictionary=independent_segment.call(from,to)
  last_plan["direct_edge"]=direct.duplicate(true)
  if bool(direct.get("clear",false)):
   last_plan.status="direct_edge"; last_plan["path_size"]=2; return PackedVector2Array([from,to])
  const STEP:=32.0
  var dimensions:=Vector2i(ceili(size.x/STEP),ceili(size.y/STEP))
  var parents: Dictionary={}
  var queue: Array[Vector2i]=[]
  var seed:=Vector2i(floori(from.x/STEP),floori(from.y/STEP))
  for dy in range(-1,2):
   for dx in range(-1,2):
    var cell:=seed+Vector2i(dx,dy)
    var point:=Vector2(cell)*STEP
    if cell.x<0 or cell.y<0 or cell.x>=dimensions.x or cell.y>=dimensions.y or not bool(independent_clear.call(point)): continue
    if bool((independent_segment.call(from,point) as Dictionary).get("clear",false)):
     parents[cell]=null; queue.append(cell)
  last_plan["seed_count"]=queue.size()
  var cursor:=0
  var goal:=Vector2i(-1,-1)
  const DIRECTIONS:=[Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(1,1)]
  while cursor<queue.size() and cursor<20000:
   var cell: Vector2i=queue[cursor]
   cursor+=1
   var point:=Vector2(cell)*STEP
   if point.distance_to(to)<=STEP*1.5 and bool((independent_segment.call(point,to) as Dictionary).get("clear",false)):
    goal=cell; break
   for direction: Vector2i in DIRECTIONS:
    var other: Vector2i=cell+direction
    if other.x<0 or other.y<0 or other.x>=dimensions.x or other.y>=dimensions.y or parents.has(other): continue
    var next: Vector2=Vector2(other)*STEP
    if not bool(independent_clear.call(next)) or not bool((independent_segment.call(point,next) as Dictionary).get("clear",false)): continue
    parents[other]=cell; queue.append(other)
  last_plan["cursor"]=cursor; last_plan["queue_size"]=queue.size()
  last_plan["goal_cell"]=[goal.x,goal.y]
  if goal.x<0:
   last_plan.status="cursor_cap" if cursor>=20000 and cursor<queue.size() else "queue_exhausted"
   return PackedVector2Array()
  var reversed:=PackedVector2Array([to])
  var node: Variant=goal
  while node is Vector2i:
   reversed.append(Vector2(node)*STEP); node=parents[node]
  reversed.append(from); reversed.reverse()
  last_plan.status="bounded_graph_path"; last_plan["path_size"]=reversed.size()
  return reversed

class DiagnosticPhase extends "res://tests/helpers/joint_v15_release_world_prepared_phase.gd":
 var attempts: Array[Dictionary]=[]
 var active_attempt: Dictionary={}
 var consumed: Dictionary={}
 var observed_failures: Array[String]=[]
 func _check(ok: bool,label: String) -> void:
  if not ok: observed_failures.append(label)
  super._check(ok,label)
 func _xy(p: Vector2) -> Array:
  return [p.x,p.y]
 func _transform(t: Transform2D) -> Array:
  return [t.x.x,t.x.y,t.y.x,t.y.y,t.origin.x,t.origin.y]
 func _hits(center: Vector2) -> Array:
  var player: CharacterBody2D=field.get("_player") as CharacterBody2D
  var shape: CollisionShape2D=player.get_node("CollisionShape2D") as CollisionShape2D
  var container: Node2D=field.get("world_container") as Node2D
  var query:=PhysicsShapeQueryParameters2D.new()
  query.shape=shape.shape; query.transform=shape.global_transform
  query.transform.origin+=container.to_global(center)-player.global_position
  query.collision_mask=int(player.collision_mask); query.exclude=[player.get_rid()]; query.collide_with_areas=false
  var records: Array=[]
  for hit: Dictionary in player.get_world_2d().direct_space_state.intersect_shape(query,128):
   var body: Node=hit.get("collider") as Node
   records.append({"rid":str(hit.get("rid")),"path":str(body.get_path()) if is_instance_valid(body) else "", "shape_index":hit.get("shape")})
  return records
 func _point_record(center: Vector2,area: Area2D=null) -> Dictionary:
  var player: Node2D=field.get("_player") as Node2D
  var container: Node2D=field.get("world_container") as Node2D
  var offset: Vector2=container.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y"))))-player.position
  var foot: Vector2=center+offset
  var pixels: Array=[]
  var mapped: Array=[]
  var actual_size: Vector2=field.get("_world_size")
  for shoe: Vector2 in ordinary_raw.call("samples",foot):
   pixels.append({"point_px":_xy(shoe),"pixel_evidence":ordinary_raw.call("pixel_evidence",shoe)})
   # Diagnostic comparison only: map EACH actual 10x6 shoe through actual
   # canvas normalization. Do not map center then resample a source10x6 shoe.
   var normalized: Vector2=shoe/actual_size
   var source_point: Vector2=normalized*ordinary_size
   var solid_hits: Array=[]
   for solid: Dictionary in ordinary_raw.get("solids"):
    var blocked: bool=Geometry2D.is_point_in_polygon(source_point,solid.polygon) if solid.kind=="exact_world_polygon" else (solid.rect as Rect2).has_point(source_point)
    if blocked: solid_hits.append({"id":solid.id,"kind":solid.kind})
   mapped.append({"actual_shoe_px":_xy(shoe),"normalized_actual_canvas":_xy(normalized),"source_shoe_px":_xy(source_point),"source_pixel_or_polygon":ordinary_raw.call("pixel_evidence",source_point),"source_solid_hits":solid_hits})
  return {"root_px":_xy(center),"visible_foot_px":_xy(foot),"foot_offset_px":_xy(offset),"original_adds_foot_offset":actual_size==ordinary_size,"root_raw17":ordinary_raw.call("foot_evidence",center),"visible_foot_raw17":ordinary_raw.call("foot_evidence",foot),"visible_foot_pixels":pixels,"mapped_actual17_to_source_comparison_only":mapped,"mapped_comparison_not_used_for_original_predicates":true,"original_static_clear":_ordinary_static_clear(center),"actual_Physics_clear":_physical_clear(center),"actual_Physics_hits":_hits(center),"original_ordinary_clear":_ordinary_clear(center),"actual_foot_and_body_contains":_area_contains_actual_foot_and_body(area,center) if area!=null else null}
 func _configure_ordinary(definition: SceneScript) -> bool:
  var configured: bool=super._configure_ordinary(definition)
  if configured:
   for layer: Dictionary in ordinary_raw.get("layers"): consumed[layer.path]=layer.sha256
   var player: Node2D=field.get("_player") as Node2D
   var shape: CollisionShape2D=player.get_node("CollisionShape2D") as CollisionShape2D
   var container: Node2D=field.get("world_container") as Node2D
   var background: TextureRect=field.get("background") as TextureRect
   active_attempt["arrival"]={"stage":"before_original_normal_intro","definition_path":definition.resource_path,"scene_id":String(definition.scene_id),"actor_positions_are_feet":definition.actor_positions_are_feet,"authored_spawn_uv":_xy(definition.player_spawn),"actual_viewport_size":_xy(field.get("_viewport_size")),"tree_viewport_visible_size":_xy(root.get_visible_rect().size),"design_size":_xy(Vector2(definition.map_layout.design_size)),"display_at_native_size":definition.map_layout.display_at_native_size,"background_path":definition.background_path,"background_texture_size":_xy(background.texture.get_size()) if background.texture!=null else [],"field_world_size":_xy(field.get("_world_size")),"raw_size":_xy(ordinary_size),"raw_sampling":ordinary_raw.get("sampling"),"player_global_position":_xy(player.global_position),"player_global_transform":_transform(player.global_transform),"container_global_transform":_transform(container.global_transform),"actual_shape_global_transform":_transform(shape.global_transform),"actual_shape_class":shape.shape.get_class(),"actual_shape_local_position":_xy(shape.position),"actual_shape_size":_xy((shape.shape as RectangleShape2D).size) if shape.shape is RectangleShape2D else [],"actual_shape_radius":(shape.shape as CircleShape2D).radius if shape.shape is CircleShape2D else null,"point":_point_record(player.position),"navigation":root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)}
  return configured
 func _portal_roundtrip(id: String,mode: String,measurement: Dictionary) -> void:
  active_attempt={"id":id,"mode":mode,"start_failures":failures,"destination":DESTINATIONS[id]}
  var t: int=Time.get_ticks_usec()
  await super._portal_roundtrip(id,mode,measurement)
  active_attempt["elapsed_sec"]=float(Time.get_ticks_usec()-t)/1000000.
  active_attempt["original_failure_delta"]=failures-int(active_attempt.start_failures)
  active_attempt["actual_scene_after"]=String((field.get("_current_scene") as SceneScript).scene_id) if is_instance_valid(field) else ""
  attempts.append(active_attempt.duplicate(true))
  _check(_write_json("attempt_%02d_%s_%s.json"%[attempts.size(),id,mode],active_attempt),"unique diagnostic actual attempt readback")
  print("PORTAL_DIAGNOSTIC_ATTEMPT ",JSON.stringify({"id":id,"mode":mode,"failure_delta":active_attempt.original_failure_delta,"elapsed_sec":active_attempt.elapsed_sec,"output":output}))
 func _actual_return(destination: StringName) -> bool:
  var reverse: Node2D
  for zone: Node2D in field.get("_exit_nodes"):
   if String(zone.get("target_scene_id")) in [String(scene_id),"world_map_jianghu"] or String(zone.get("action"))=="world_map":
    reverse=zone; break
  _check(reverse!=null,"actual target has public reverse exit: "+String(destination))
  if reverse==null: return false
  var player: Node2D=field.get("_player") as Node2D
  var shapes: Array=[]
  for child: Node in reverse.get_children():
   if child is CollisionPolygon2D: shapes.append({"class":"CollisionPolygon2D","disabled":child.disabled,"position":_xy(child.position),"polygon":str(child.polygon)})
   elif child is CollisionShape2D: shapes.append({"class":"CollisionShape2D","disabled":child.disabled,"position":_xy(child.position),"shape_class":child.shape.get_class() if child.shape!=null else "","size":_xy((child.shape as RectangleShape2D).size) if child.shape is RectangleShape2D else []})
  active_attempt["return_start"]=_point_record(player.position,reverse as Area2D)
  active_attempt["return_start_stage"]="after_original_normal_intro"
  active_attempt["reverse"]={"path":str(reverse.get_path()),"position":_xy(reverse.position),"global_transform":_transform(reverse.global_transform),"target":reverse.get("target_scene_id"),"action":reverse.get("action"),"in_range":reverse.get("_in_range"),"rid":str((reverse as Area2D).get_rid()),"shapes":shapes}
  var candidates: Array=[]
  for radius in [0,16,32,48,64]:
   for direction in 16:
    var point: Vector2=reverse.position+Vector2(cos(TAU*direction/16),sin(TAU*direction/16))*radius
    var record: Dictionary=_point_record(point,reverse as Area2D)
    record["radius"]=radius; record["direction"]=direction
    candidates.append(record)
  active_attempt["all80_original_candidates"]=candidates
  var plans: Array=[]
  var path:=PackedVector2Array()
  for radius in [0,16,32,48,64]:
   for direction in 16:
    var point: Vector2=reverse.position+Vector2(cos(TAU*direction/16),sin(TAU*direction/16))*radius
    if not _ordinary_clear(point): continue
    if not _area_contains_actual_foot_and_body(reverse as Area2D,point): continue
    path=input_driver.call("plan",player.position,point,ordinary_size,_ordinary_clear,_ordinary_segment)
    var plan: Dictionary=(input_driver.get("last_plan") as Dictionary).duplicate(true)
    plan["radius"]=radius; plan["direction"]=direction
    plans.append(plan)
    if path.size()>=2: break
   if path.size()>=2: break
  active_attempt["original_planner_attempts"]=plans
  active_attempt["selected_path_size"]=path.size()
  _check(path.size()>=2,"independent all-edge full17 path exists to actual reverse trigger: "+String(destination))
  if path.size()<2: return false
  var driven: Dictionary=await input_driver.call("follow",field,path,_ordinary_clear,_ordinary_segment)
  active_attempt["actual_return_input"]=driven.duplicate(true)
  _check(bool(driven.get("ok",false)),"real ordinary target input completes planned reverse path: %s %s"%[destination,driven])
  var reverse_live: bool=is_instance_valid(field) and field.is_inside_tree() and owner_tree.current_scene==field and is_instance_valid(reverse) and reverse.is_inside_tree() and not reverse.is_queued_for_deletion()
  _check(reverse_live,"original target Field and reverse exit stay live during actual return approach")
  if not reverse_live: return false
  _check(bool(reverse.get("_in_range")),"normal physics reaches reverse exit; no direct router return")
  if not bool(driven.get("ok",false)) or not bool(reverse.get("_in_range")): return false
  var marker: Sprite2D=reverse.get("marker_visual") as Sprite2D
  _check(marker!=null,"actual target reverse arrow exists")
  if marker==null: return false
  await input_driver.call("pointer",marker.get_global_transform_with_canvas().origin)
  return await _wait_field(scene_id)

var checks: int=0
var errors: Array[String]=[]
var paths: Dictionary={}
var before: Dictionary={}
var output: String=""
var phase: DiagnosticPhase
func _initialize() -> void:
 call_deferred("_run")
func _check(ok: bool,label: String) -> bool:
 checks+=1
 if not ok: errors.append(label); push_error("[PORTAL DIAGNOSTIC] "+label)
 return ok
func _file(path: String) -> Dictionary:
 if not FileAccess.file_exists(path): return {"exists":false}
 var f:=FileAccess.open(path,FileAccess.READ)
 if f==null: return {"exists":true,"readable":false}
 var n: int=f.get_length(); f.close()
 return {"exists":true,"bytes":n,"sha256":FileAccess.get_sha256(path),"mtime":FileAccess.get_modified_time(path)}
func _snapshot(p: Dictionary) -> Dictionary:
 var r: Dictionary={}
 for path: String in p: r[path]=_file(path)
 return r
func _players() -> Dictionary:
 var r: Dictionary={}
 for slot in 5:
  for suffix: String in ["",".bak",".tmp"]:
   var p: String="user://save_%d.json%s"%[slot,suffix]; r[p]=_file(p)
 return r
func _env() -> Dictionary:
 return {"actual_audio_driver":AudioServer.get_driver_name(),"output_device":AudioServer.output_device,"mix_rate":AudioServer.get_mix_rate(),"latency":AudioServer.get_output_latency(),"display":DisplayServer.get_name(),"engine":Engine.get_version_info(),"executable_sha256":FileAccess.get_sha256(OS.get_executable_path()),"source_version_equivalence":false}
func _read(path: String) -> Dictionary:
 var j:=JSON.new()
 return j.data if j.parse(FileAccess.get_file_as_string(path))==OK and j.data is Dictionary else {}
func _run() -> void:
 _check(OS.get_cmdline_user_args()==PackedStringArray(["--candidate-before-cutover"]),"explicit bounded diagnostic only")
 var env0: Dictionary=_env()
 _check(env0.actual_audio_driver=="WASAPI" and env0.executable_sha256==EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen executable/normal1x at start")
 paths=PINS.duplicate(true); paths[get_script().resource_path]=FileAccess.get_sha256(get_script().resource_path)
 for p: String in paths: _check(FileAccess.get_sha256(p)==paths[p],"fixed actual input "+p)
 # Capture existing direct scene/layout dependencies before Field reads them.
 var dep_regex:=RegEx.new(); dep_regex.compile('res://[^"\\s]+')
 for p: String in PINS:
  if p.ends_with(".tres"):
   for match: RegExMatch in dep_regex.search_all(FileAccess.get_file_as_string(p)):
    var dep: String=match.get_string()
    if FileAccess.file_exists(dep): paths[dep]=FileAccess.get_sha256(dep)
 var candidate_world: SceneScript=load(WORLD) as SceneScript
 _check(candidate_world!=null and candidate_world.map_layout!=null,"actual external candidate layout readable")
 if candidate_world!=null and candidate_world.map_layout!=null:
  var catalog: Dictionary=_read(MANIFEST).get("asset_sha256",{})
  var tiles: Array=candidate_world.map_layout.walkable_mask_tiles
  _check(tiles.size()==64,"all64 current world nav inputs before Field")
  for tile: Dictionary in tiles:
   var p: String=tile.path
   _check(catalog.get(p)==FileAccess.get_sha256(p),"current original64 nav bound to frozen manifest "+p)
   paths[p]=FileAccess.get_sha256(p)
 var frozen: Dictionary=_read(FROZEN)
 var context: RefCounted=CONTEXT.new()
 _check(context.call("validate_v9c_world_pins",frozen.get("execution_sha256",{}),frozen.get("v9c_artifact_sha256",{}),_read(MANIFEST),frozen.get("derived_geometry_inputs",{}))==true,"actual complete frozen source pins, not a fresh approval")
 context=null
 before=_snapshot(paths)
 var players0: Dictionary=_players()
 var slot0: Variant=root.get_node("SaveManager").get("active_slot")
 if not errors.is_empty(): quit(1); return
 output="res://build/joint_world_luoyang_20261003_qa/portal_arrival_return_diagnostic_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
 _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique evidence only")
 if not errors.is_empty(): quit(1); return
 phase=DiagnosticPhase.new(); phase.owner_tree=self; phase.output=output; phase.requested_phase="LIMITED_PORTAL_DIAGNOSTIC_NOT_RELEASE"
 phase.before_saves=phase.call("_actual_saves"); phase.prior_navigation=root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
 phase.prior_active=StringName(root.get_node("SceneRouter").get("_active_world_map_scene")); phase.prior_slot=int(slot0)
 phase.source=_read(SOURCE); phase.manifest=_read(MANIFEST); phase.world=candidate_world
 phase.execution_sha256=frozen.execution_sha256.duplicate(true); phase.v9c_artifact_sha256=frozen.v9c_artifact_sha256.duplicate(true); phase.derived_geometry_inputs=frozen.derived_geometry_inputs.duplicate(true)
 phase.oracle=RAW.new()
 _check(phase.oracle.call("configure",phase.world.map_layout)==true,"actual current world raw full17/source solids")
 phase.call("_read_independent_door_review")
 var ready: bool=errors.is_empty() and phase.failures==0
 if ready:
  phase.call("_ensure_runtime_fixture")
  phase.input_driver.call("release")
  phase.input_driver=DiagnosticDriver.new(); phase.input_driver.call("configure",self)
  ready=phase.failures==0
 if ready:
  for id: String in IDS:
   var measurement: Dictionary=phase.call("_source_door",id)
   if measurement.is_empty(): _check(false,"exact bound source door "+id); continue
   for mode: String in MODES: await phase._portal_roundtrip(id,mode,measurement)
 _check(phase.attempts.size()==9,"all nine original normal entry attempts recorded, not successful subset")
 for attempt: Dictionary in phase.attempts:
  _check(attempt.has("arrival") and attempt.has("return_start") and attempt.get("all80_original_candidates",[]).size()==80,"actual arrival and all80 unmodified original candidates: "+str(attempt.id)+"/"+str(attempt.mode))
 var observed: Array=phase.observed_failures.duplicate()
 var records: Array=phase.attempts.duplicate(true)
 var consumed: Dictionary=phase.consumed.duplicate(true)
 for p: String in consumed: _check(paths.has(p) and paths[p]==consumed[p],"actual consumed local PNG captured before Field: "+p)
 var original_failures: int=phase.failures
 await phase.call("_finish")
 _check(phase.failures==original_failures,"normal original cleanup adds no failure")
 _check(_snapshot(paths)==before and _players()==players0 and root.get_node("SaveManager").get("active_slot")==slot0,"all fixed/consumed source bytes/mtime and fifteen players/slot unchanged")
 var env1: Dictionary=_env()
 _check(env1.actual_audio_driver=="WASAPI" and env1.executable_sha256==EXE_SHA and Engine.time_scale==1.,"actual WASAPI/frozen executable/normal1x at finish")
 var report: Dictionary={"schema":1,"scope":"LIMITED_ACTUAL_3_PORTALS_9_ORIGINAL_NORMAL_ENTRIES_CAUSE_DIAGNOSTIC_NOT_RELEASE","checks":checks,"diagnostic_failures":errors.size(),"errors":errors,"original_phase_failures":original_failures,"original_failure_labels":observed,"attempts":records,"source_before":before,"source_after":_snapshot(paths),"players_before":players0,"players_after":_players(),"environment_before":env0,"environment_after":env1,"consumed_original_nav":consumed,"original_parent_immutable":true,"geometry_or_landing_changed":false,"source_complete":false,"release_complete":false,"formal_approval":false,"output":output}
 _check(phase.call("_write_json","diagnostic.json",report)==true,"unique diagnostic report readback")
 print("V9E_PORTAL_ARRIVAL_RETURN_DIAGNOSTIC ",JSON.stringify({"checks":checks,"diagnostic_failures":errors.size(),"original_phase_failures":original_failures,"attempts":records.size(),"output":output,"release_complete":false}))
 phase=null
 for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
 for frame in 16: await process_frame
 quit(0 if errors.is_empty() else 1)
