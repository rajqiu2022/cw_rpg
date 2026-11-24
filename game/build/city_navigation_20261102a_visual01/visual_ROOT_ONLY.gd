extends SceneTree
## Root-only ONE Temple south normal image; no input injection or old QA run.
const HOME := "res://build/city_navigation_20261102a_visual01/"
const SELF := HOME+"visual_ROOT_ONLY.gd"
const INPUTS := HOME+"visual_inputs_ROOT_READY.json"
const HOST := "res://build/city_navigation_20261101d_candidate01/city_navigation_runtime.gd"
const PAIRS := "res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd"
const GEO := "res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd"
const MOUTH := "res://build/city_navigation_20261101d_candidate01/mouth_visual.gd"
const SHADER := "res://build/city_navigation_20261101d_candidate01/mouth_shoulder.gdshader"
const MANIFEST := "res://build/city_navigation_20261101d_candidate01/source_pins_READY.json"
const CANDIDATE_PLAN := "res://build/city_navigation_20261102a_mouth_sample01/candidate_plan_READY.json"
const REG_DISPATCH := "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd"
const PHYSICAL := "luoyang_temple_region_27d"
const LOGICAL := "ch4_s4_ancient_temple"
const FOOT := Vector2(2390,4276)
const OLD_MANIFEST_SHA := "760534d8b33534c083d8e5537bb8e4287daf66409f7fddc5fb081090b22f1fa2"
var cfg: Dictionary = {}
var pins: Dictionary = {}
var first: Dictionary = {}
var records: Array[Dictionary] = []
var errors: Array[String] = []
var observed_toasts: Array[String] = []
var checks := 0
var done := false
var suspended := false
var directory := ""
var input_sha := ""
var field: Node
var host: Node
var router: Node
var images := 0

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children(): _early(node)
	run.call_deferred()
	watch.call_deferred()

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true)
		suspended = node.call("is_checkpoint_saves_suspended") == true
	if node.name == &"EventBus" and node.has_signal("toast_requested") and not node.is_connected("toast_requested",_observe_toast):
		node.connect("toast_requested",_observe_toast)

func _observe_toast(message: String) -> void:
	observed_toasts.append(message)
	if observed_toasts.size() > 16: observed_toasts.pop_front()

func watch() -> void:
	await create_timer(90.0,true,false,true).timeout
	if not done:
		need(false,"FINITE_90S_WATCHDOG")
		finish()

func _property(object: Object, key: String, fallback: Variant = null) -> Variant:
	if not is_instance_valid(object): return fallback
	for row: Dictionary in object.get_property_list():
		if String(row.name) == key: return object.get(key)
	return fallback

func _physical(candidate: Node) -> String:
	var scene: SceneScript = _property(candidate,"_current_scene") as SceneScript
	return String(scene.scene_id) if scene != null else ""

func _busy() -> bool:
	var loader: Node = root.get_node_or_null("LoadingManager")
	return loader == null or _property(loader,"_transition_active",false) == true or _property(loader,"_external_active",false) == true

func _diagnostic(reason: String) -> void:
	var value: Dictionary = {"reason":reason,"msec":Time.get_ticks_msec(),"read_only":true,"toasts":observed_toasts.duplicate()}
	if is_instance_valid(router):
		value["public_preparation"] = router.call("get_public_city_preparation_state")
		value["current_logical"] = router.call("get_current_field_id")
		value["field_payload"] = router.call("get_field_payload")
	var loader: Node = root.get_node_or_null("LoadingManager")
	if loader != null:
		var state: Dictionary = {}
		for key: String in ["_transition_active","_external_active","_finishing","_loading_path","_transition_kind","_transition_context","_started_msec","_field_preparation_token","_external_token","_handoff_progress"]:
			state[key] = _property(loader,key)
		if loader.has_method("get_field_preload_metrics"): state["preload_metrics"] = loader.call("get_field_preload_metrics")
		var screen: Node = _property(loader,"_screen") as Node
		var labels: Array[Dictionary] = []
		if is_instance_valid(screen):
			for label: Node in screen.find_children("*","Label",true,false):
				if label is Label and label.is_visible_in_tree() and not label.text.is_empty(): labels.append({"path":String(label.get_path()),"text":label.text.left(800)})
		state["visible_status_labels"] = labels
		value["loading_manager"] = state
	var active: Node = current_scene
	if is_instance_valid(active):
		var state: Dictionary = {"instance":active.get_instance_id(),"physical":_physical(active),"path":String(active.get_path()),"script":active.get_script().resource_path if active.get_script() != null else ""}
		if active.has_method("get_field_loading_state"): state["loading"] = active.call("get_field_loading_state")
		if active.has_method("get_field_loading_profile"): state["loading_profile"] = active.call("get_field_loading_profile")
		for key: String in ["_scene_rebuilding","_field_loading_failed","_field_loading_complete","_field_loading_stage"]: state[key] = _property(active,key)
		var actor: CharacterBody2D = _property(active,"_player") as CharacterBody2D
		if is_instance_valid(actor):
			var collisions: Array[Dictionary] = []
			for index: int in range(actor.get_slide_collision_count()):
				var collision: KinematicCollision2D = actor.get_slide_collision(index)
				var collider: Object = collision.get_collider()
				collisions.append({"normal":collision.get_normal(),"position":collision.get_position(),"collider":str(collider),"path":String(collider.get_path()) if collider is Node else ""})
			state["player"] = {"foot":actor.position,"velocity":actor.velocity,"can_move":_property(actor,"can_move"),"slide_collisions":collisions}
		var toast: Label = _property(active,"_feedback_toast") as Label
		if is_instance_valid(toast): state["toast"] = {"text":toast.text,"visible":toast.is_visible_in_tree()}
		value["actual_field"] = state
	var dialog: Node = root.get_node_or_null("DialogPlayer")
	if dialog != null and dialog.has_method("is_playing"): value["original_dialog_playing"] = dialog.call("is_playing")
	if is_instance_valid(host): value["navigation_host"] = host.call("get_debug_state")
	records.append({"actual_diagnostic_before_oracle":value})
	print("CITYNAV02A_SAMPLE_STATE ",JSON.stringify(value))

func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		_diagnostic("FAIL_BEFORE_ORACLE:"+label)
		errors.append(label)
		printerr("CITYNAV02A_SAMPLE_FAIL ",label)
	return ok

func facts() -> Dictionary:
	var result: Dictionary = {}
	for path: String in pins:
		var file := FileAccess.open(path,FileAccess.READ)
		result[path] = {"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file != null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result



func _wait_temple(previous: int) -> bool:
 var limit: int=Time.get_ticks_msec()+30000
 var last_signature: String=""
 var last_time := 0
 var observations := 0
 _diagnostic("WAIT_TEMPLE_BEGIN")
 while not done and Time.get_ticks_msec()<limit:
  await process_frame
  var active: Node=current_scene
  var prep: Dictionary=router.call("get_public_city_preparation_state")
  var loading: Dictionary=active.call("get_field_loading_state") if is_instance_valid(active) and active.has_method("get_field_loading_state") else {}
  var signature: String=var_to_str([prep.get("phase"),prep.get("error"),_physical(active),loading.get("stage"),loading.get("failed"),_busy()])
  if observations<24 and (signature!=last_signature or Time.get_ticks_msec()-last_time>=2000):
   observations+=1;last_signature=signature;last_time=Time.get_ticks_msec()
   _diagnostic("WAIT_TEMPLE_PHASE")
  if loading.get("failed")==true and _physical(active)==PHYSICAL: return need(false,"ACTUAL_TEMPLE_LOAD_FAILED")
  if prep.get("scene_id")==PHYSICAL and prep.get("active")==false and prep.get("phase") in ["FAILED","REJECTED","CANCELLED"]: return need(false,"ACTUAL_PUBLIC_PREPARATION_REJECTED")
  if not is_instance_valid(active) or active.get_instance_id()==previous or _physical(active)!=PHYSICAL: continue
  var actor: Node=_property(active,"_player") as Node
  if loading.get("complete")!=true or _property(active,"_scene_rebuilding",false)==true or _busy() or not is_instance_valid(actor) or actor.get("can_move")!=true: continue
  field=active
  var state: Dictionary=host.call("get_debug_state")
  if not String(state.get("last_error","")).is_empty(): return need(false,"ACTUAL_HOST_ERROR:"+String(state.last_error))
  if state.get("ready")!=true or state.get("attached_scene")!=PHYSICAL or state.get("metadata",{}).get("scene_id")!=PHYSICAL or state.get("mini_ok")!=true: continue
  var mini: Node=field.get("_world_travel_minimap") as Node
  var cache: Node=_property(mini,"_visual_cache") as Node
  if cache==null or cache.get("capture_ready")!=true: continue
  await physics_frame
  await RenderingServer.frame_post_draw
  _diagnostic("WAIT_TEMPLE_SUCCESS")
  return need(state.get("source_manifest_sha256")==cfg.approved_after_manifest_sha256,"ACTUAL_HOST_EXPLICIT_APPROVED99")
 return need(false,"ACTUAL_TEMPLE_FINITE_READY")

func _depth(item: CanvasItem) -> Dictionary:
 var value := 0
 var chain: Array[Dictionary]=[]
 var current: CanvasItem=item
 while current!=null:
  value+=current.z_index
  chain.append({"node":String(current.get_path()),"z":current.z_index,"relative":current.z_as_relative})
  if not current.z_as_relative: break
  current=current.get_parent() as CanvasItem
 return {"effective_z":clampi(value,-4096,4095),"ancestor_chain":chain}

func _normal_state() -> Dictionary:
 var actor: Node2D=field.get("_player") as Node2D
 var camera: Camera2D=field.get("_world_camera") as Camera2D
 var world: Node2D=field.get("world_container") as Node2D
 return {"field_instance":field.get_instance_id(),"physical":_physical(field),"logical":String(router.call("get_current_field_id")),"foot":actor.position,"camera_zoom":camera.zoom if camera!=null else null,"camera_position":camera.position if camera!=null else null,"world_scale":world.scale,"field_camera_zoom":field.get("_camera_zoom"),"viewport":root.get_viewport().get_visible_rect().size}

func _scene_evidence() -> bool:
 var pair_script: GDScript=load(PAIRS) as GDScript
 var selected: Array=pair_script.call("relations").filter(func(row: Dictionary)->bool:return row.get("pair_id")=="docks_temple")
 if not need(selected.size()==1,"EXACT_EXISTING_DOCKS_TEMPLE_PAIR"): return false
 var endpoint: Dictionary=selected[0].b
 if not need(endpoint.scene_id==PHYSICAL and endpoint.logical_id==LOGICAL and endpoint.source_portal=="legacy_portal_7" and endpoint.mouth==Vector2(2390,4380) and endpoint.arrival==FOOT and endpoint.outward==Vector2(0,1) and endpoint.activation_size==Vector2(128,80) and endpoint.retired_feet==[Vector2(2390,4380)],"ORIGINAL_PAIR_POS_ARRIVAL_ACTIVATION_EXACT_UNCHANGED"): return false
 var actual_zones: Array=[]
 for node: Node in get_nodes_in_group("exit_zone"):
  if node is ExitZone and node.has_meta("citynav_endpoint"):
   var data: Dictionary=node.get_meta("citynav_endpoint")
   if data.get("id")=="citynav/docks_temple/b": actual_zones.append(node)
 if not need(actual_zones.size()==1,"ONE_EXISTING_ACTUAL_DOCKS_TEMPLE_ZONE"): return false
 var zone: ExitZone=actual_zones[0] as ExitZone
 var shape: CollisionShape2D=zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
 if not need(zone.position==endpoint.mouth and zone.target_scene_id=="ch4_s2_canal_docks" and not zone.auto_trigger and shape!=null and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size==endpoint.activation_size,"ACTUAL_ZONE_ORIGINAL_POSITION_MANUAL_TARGET_SIZE"): return false
 var compiled: Dictionary=field.get("_region")
 var original_portals: Array=compiled.get("portals",[]).filter(func(row: Dictionary)->bool:return row.get("id")=="legacy_portal_7")
 if not need(original_portals.size()==1 and original_portals[0].get("foot")==Vector2(2390,4380),"ORIGINAL_COMPILED_LEGACY7_FOOT_NOT_REAUTHORED"): return false
 var geo: GDScript=load(GEO) as GDScript
 if not need(var_to_bytes(compiled)==var_to_bytes(geo.call("region_for",PHYSICAL)) and geo.call("physics_clear",field,FOOT)==true,"CURRENT_COMPILED_EXACT_GEO_COPY_AND_ACTUAL_FOOT_CLEAR"): return false
 var receipt: Dictionary=field.get_meta("city_navigation_20261101d_mouth_visual",{})
 var sample: Array=receipt.get("rows",[]).filter(func(row: Dictionary)->bool:return row.get("sample_endpoint_id")=="citynav/docks_temple/b")
 if not need(receipt.get("ok")==true and receipt.get("original_NAV_and_bodies_unchanged")==true and sample.size()==1 and sample[0].get("sample_revision")=="20261102a_temple_docks_one_endpoint" and sample[0].get("activation_and_arrival_unchanged")==true,"ACTUAL_ONE_SAMPLE_ROAD_RECEIPT"): return false
 var layer: Node=field.get("_visual_layer").get_node_or_null("CityNavigationRoadMouths11d")
 var cap: Polygon2D=layer.get_node_or_null("TempleDocksContinuousOpening02a") as Polygon2D if layer!=null else null
 if not need(cap!=null and cap.z_as_relative and cap.z_index==-997 and cap.material is ShaderMaterial,"ACTUAL_SAME_PARENT_RELATIVE_GROUND_CAP"): return false
 var material: ShaderMaterial=cap.material as ShaderMaterial
 var points:=PackedVector2Array([Vector2(1536,4096),Vector2(1800,4144),Vector2(2170,4192),FOOT,Vector2(2390,4596)])
 var widths:=PackedFloat32Array([96,96,88,72,72])
 var soil: Texture2D=material.get_shader_parameter("soil_texture") as Texture2D
 if not need(material.shader!=null and material.shader.resource_path==SHADER and int(material.get_shader_parameter("sample_mode"))==1 and material.get_shader_parameter("sample_points")==points and material.get_shader_parameter("sample_half_widths")==widths and soil!=null and soil.resource_path=="res://art/modules/miao_town_20261029f/ground.png","ACTUAL_SAMPLE_SHADER_POLYLINE_WORLD_SOIL_BINDING"): return false
 var actor: Node2D=field.get("_player") as Node2D
 var cap_depth: Dictionary=_depth(cap)
 var actor_depth: Dictionary=_depth(actor)
 var course_depths: Array[Dictionary]=[]
 for index: int in range(2):
  var course: Polygon2D=layer.get_node_or_null("TempleDocksFlatCourtCourse02a_"+str(index)) as Polygon2D
  if not need(course!=null and course.z_as_relative and course.z_index==-996,"ACTUAL_TWO_FLAT_COURSES_RELATIVE:"+str(index)): return false
  var depth: Dictionary=_depth(course)
  course_depths.append(depth)
  if not need(depth.effective_z>cap_depth.effective_z and depth.effective_z<actor_depth.effective_z,"FLAT_GROUND_COURSE_BELOW_ACTOR:"+str(index)): return false
 if not need(cap_depth.effective_z<actor_depth.effective_z and layer.find_children("*","CollisionObject2D",true,false).is_empty(),"VISUAL_GROUND_BELOW_ACTOR_ZERO_ADDED_BODIES"): return false
 var mini: Node=field.get("_world_travel_minimap") as Node
 var cache: Node=mini.get("_visual_cache") as Node
 var canvas: Node=cache.get("_canvas") as Node
 var clones: Array[Dictionary]=[]
 for leaf: Node in canvas.get_children():
  if not leaf is Polygon2D or leaf.polygon!=cap.polygon or not leaf.material is ShaderMaterial: continue
  var cloned: ShaderMaterial=leaf.material as ShaderMaterial
  if int(cloned.get_shader_parameter("sample_mode"))!=1: continue
  var copied_soil: Texture2D=cloned.get_shader_parameter("soil_texture") as Texture2D
  var exact: bool=leaf.get_script()==null and cloned.shader!=null and cloned.shader.code==material.shader.code and cloned.get_shader_parameter("sample_points")==points and cloned.get_shader_parameter("sample_half_widths")==widths and copied_soil!=null and copied_soil.resource_path==soil.resource_path
  clones.append({"exact_native_quad_and_material":exact,"texture":leaf.texture.resource_path if leaf.texture!=null else "","clone_z":leaf.z_index,"relative":leaf.z_as_relative})
 var cache_state: Dictionary=cache.call("get_debug_state")
 var plan: Node=mini.get("_plan") as Node
 if not need(clones.size()==1 and clones[0].exact_native_quad_and_material and cache_state.get("ready")==true and cache_state.get("valid")==true and cache_state.get("render_requests")==1 and cache_state.get("compiled_render_count")==cache_state.get("full_compiled_render_count") and plan.get("base_texture")==cache.call("get_texture"),"ACTUAL_MINI_ONE_EXACT_NEW_SHADER_CAP_REAL_CACHED_TEXTURE"): return false
 var normal: Dictionary=_normal_state()
 if not need(normal.foot.distance_to(FOOT)<.03 and normal.logical==LOGICAL and normal.camera_zoom==Vector2.ONE and normal.world_scale==Vector2.ONE and normal.field_camera_zoom==1.0 and normal.viewport==Vector2(1920,1080),"NORMAL_SAME_FOOT_1920_CAMERA_NO_ZOOM_WRITES"): return false
 records.append({"actual_current_road_receipt":receipt,"sample_exact_endpoint":sample[0],"actual_zone_position":zone.position,"original_compiled_portal_foot":original_portals[0].foot,"original_lock_retained_by_runtime":zone.is_locked,"cap_effective_depth":cap_depth,"flat_course_effective_depths":course_depths,"actual_actor_effective_depth":actor_depth,"mini_cache":cache_state,"mini_shader_cap_clones":clones,"normal_state":normal,"host":host.call("get_debug_state"),"only_one_sample_endpoint_art_scope":true})
 return true

func run() -> void:
 directory=HOME+"actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
 await process_frame
 if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND_NO171_RESAMPLE"): finish();return
 input_sha=FileAccess.get_sha256(INPUTS)
 cfg=JSON.parse_string(FileAccess.get_file_as_string(INPUTS)) as Dictionary
 if not need(cfg.get("schema")=="CITY_NAVIGATION_20261102A_ONE_SAMPLE_VISUAL_QA_V1" and cfg.get("ready")==true and cfg.get("root_only")==true and cfg.get("baseline_before_manifest_sha256")==OLD_MANIFEST_SHA,"ROOT_EXPLICIT_ONE_SAMPLE_APPROVAL"): finish();return
 pins=cfg.get("source_pins",{}).duplicate(true)
 if not need(pins.has(SELF) and pins.has(CANDIDATE_PLAN) and pins.has(MANIFEST) and String(cfg.get("approved_after_manifest_sha256","")).length()==64 and pins[MANIFEST]==cfg.approved_after_manifest_sha256,"ROOT_EXPLICIT_NEW99_SHA_NOT_ACTUAL_INFERRED"): finish();return
 for path: String in pins:
  if not need(path.begins_with("res://") and not ".." in path and String(pins[path]).length()==64,"SOURCE_ONLY_NO_USER_FILES:"+path): finish();return
 first=facts()
 for path: String in pins:
  if not need(first[path].sha256==pins[path],"SAMPLE_SOURCE_FIRST:"+path): finish();return
 var proposal: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_PLAN)) as Dictionary
 var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) as Dictionary
 var pool: Dictionary=manifest.get("source_pins",{})
 if not need(proposal.get("old_runtime_manifest_sha256")==OLD_MANIFEST_SHA and proposal.get("changed_old_leaf_count")==2 and proposal.get("unchanged_old_leaf_count")==94 and manifest.get("ready")==true and pool.size()==99,"ROOT_LIMITED96_TO99_TWO_CHANGED_THREE_MEDIA_ONLY"): finish();return
 for change: Dictionary in proposal.get("targets",[]):
  if not need(pool.get(change.path)==change.after_sha256 and pins.get(change.path)==change.after_sha256,"APPROVED_TWO_HELPER_AFTER:"+String(change.path)): finish();return
 for path: String in proposal.get("new_existing_media_pins",{}):
  if not need(pool.get(path)==proposal.new_existing_media_pins[path] and pins.get(path)==proposal.new_existing_media_pins[path],"EXISTING_GROUND_TRIPLE_EXPLICIT:"+path): finish();return
 for path: String in proposal.get("unmodified_host_Pair_Geo_pins",{}):
  if not need(pool.get(path)==proposal.unmodified_host_Pair_Geo_pins[path] and pins.get(path)==proposal.unmodified_host_Pair_Geo_pins[path],"UNCHANGED_HOST_PAIR_GEO:"+path): finish();return
 router=root.get_node_or_null("SceneRouter");host=root.get_node_or_null("CityNavigationRuntime")
 if not need(router!=null and host!=null and host.get_script().resource_path==HOST,"ACTUAL_ORIGINAL_NAVIGATION_HOST"): finish();return
 var previous: int=current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
 var dispatch: GDScript=load(REG_DISPATCH) as GDScript
 var extension: Dictionary={"region_id":PHYSICAL,"revision":1,"logical_id":LOGICAL,"global_foot_px":[2390,4276]}
 if not need(dispatch.call("start",router,StringName(LOGICAL),Vector2(.5,.5),"",3,extension)==true,"ONLY_PUBLIC_REGION_NEAR_SETUP_NOT_TRAVEL"): finish();return
 if not await _wait_temple(previous) or not _scene_evidence(): finish();return
 var normal_before: Dictionary=_normal_state()
 await RenderingServer.frame_post_draw
 var image: Image=root.get_viewport().get_texture().get_image()
 if not need(image!=null and image.get_size()==Vector2i(1920,1080) and images==0,"ONE_NORMAL1920_IMAGE_ONLY"): finish();return
 var image_path: String=directory+"/temple_south_natural_mouth_sample_normal.png"
 if not need(image.save_png(image_path)==OK,"SAVE_ONE_NORMAL_SAMPLE_IMAGE"): finish();return
 images=1
 var normal_after: Dictionary=_normal_state()
 if not need(var_to_bytes(normal_before)==var_to_bytes(normal_after),"NO_INPUT_OR_CAMERA_OR_FOOT_CHANGE_DURING_CAPTURE"): finish();return
 records.append({"normal_image":image_path,"sha256":FileAccess.get_sha256(image_path),"same_foot_as_91216_south":FOOT,"normal_state_before":normal_before,"normal_state_after":normal_after,"visual_acceptance":"Root must inspect; numeric checks do not accept all22 ends","inherited_24624_baseline14_not_rerun":cfg.get("inherited_24624",{})})
 finish()

func finish() -> void:
 if done:return
 done=true
 var last: Dictionary=facts() if not pins.is_empty() else {}
 if not first.is_empty():need(var_to_bytes(first)==var_to_bytes(last),"SMALL_SOURCE_FIRST_FINAL_EXACT")
 if not input_sha.is_empty():need(FileAccess.get_sha256(INPUTS)==input_sha,"ROOT_CONFIG_UNCHANGED")
 var result: Dictionary={"passed":errors.is_empty() and images==1,"checks":checks,"errors":errors,"normal_images":images,"input_events":0,"true_legs_executed":0,"checkpoint_suspended":suspended,"records":records,"source_first":first,"source_final":last,"inputs_sha256":input_sha,"root_only":true,"save_content_or_metadata_APIs":0,"scope":"ONE_TEMPLE_SOUTH_NORMAL_SAMPLE_IMAGE_NOT22_END_ART"}
 var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
 if file!=null:file.store_string(JSON.stringify(result,"\t")+"\n")
 print("CITYNAV02A_VISUAL_SAMPLE ",JSON.stringify({"passed":result.passed,"checks":checks,"errors":errors,"images":images,"inputs":0,"result":directory+"/result.json"}))
 quit(0 if result.passed else 1)

