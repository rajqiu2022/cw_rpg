extends SceneTree
## Two class samples only. Capture same-scene normal image BEFORE measures;
## failed measures stay FAIL and do not erase that image or old travel credit.
const HOME := "res://build/city_navigation_20261102a_visual03/"
const SELF := HOME+"visual_ROOT_ONLY.gd"
const INPUTS := HOME+"visual_inputs_ROOT_READY.json"
const HOST := "res://build/city_navigation_20261101d_candidate01/city_navigation_runtime.gd"
const PAIRS := "res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd"
const GEO := "res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd"
const MOUTH := "res://build/city_navigation_20261101d_candidate01/mouth_visual.gd"
const SHADER := "res://build/city_navigation_20261101d_candidate01/mouth_shoulder.gdshader"
const MANIFEST := "res://build/city_navigation_20261101d_candidate01/source_pins_READY.json"
const REG_DISPATCH := "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd"
const OLD_MANIFEST_SHA := "9ebd1f6fd09d8548fb12648f4da83b5ed18558244e7d09e494a4f1e6acdafcf9"
const FIXED := [
	{"id":"citynav/yamen_artisan/a","pair":"yamen_artisan","side":"a","physical":"luoyang_civic_market_region_27d","logical":"ch4_s1_luoyang_yamen","foot":Vector2(824,970),"mouth":Vector2(720,970),"outward":Vector2(-1,0),"portal":"finish_i_yamen_to_artisan","target":"luoyang_artisan_residential_20261022ap","retired":[Vector2(720,970)],"size":Vector2(80,128),"image":"civic_internal_street_normal"},
	{"id":"citynav/yamen_docks/b","pair":"yamen_docks","side":"b","physical":"ch4_s2_canal_docks","logical":"ch4_s2_canal_docks","foot":Vector2(304,850),"mouth":Vector2(200,850),"outward":Vector2(-1,0),"portal":"to_yamen_square","target":"ch4_s1_luoyang_yamen","retired":[Vector2(260,790)],"size":Vector2(80,128),"image":"docks_narrow_shore_interface_normal"}
]
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
	await create_timer(150.0,true,false,true).timeout
	if not done:
		need(false,"FINITE_150S_WATCHDOG")
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
	print("CITYNAV02A_VISUAL03_STATE ",JSON.stringify(value))

func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		_diagnostic("FAIL_BEFORE_ORACLE:"+label)
		errors.append(label)
		printerr("CITYNAV02A_VISUAL03_FAIL ",label)
	return ok

func facts() -> Dictionary:
	var result: Dictionary = {}
	for path: String in pins:
		var file := FileAccess.open(path,FileAccess.READ)
		result[path] = {"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file != null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result




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



func _wait_field(previous: int, physical: String) -> bool:
	var limit: int=Time.get_ticks_msec()+30000
	var last_signature: String=""
	var last_time := 0
	var observations := 0
	_diagnostic("WAIT_BEGIN:"+physical)
	while not done and Time.get_ticks_msec()<limit:
		await process_frame
		var active: Node=current_scene
		var prep: Dictionary=router.call("get_public_city_preparation_state")
		var loading: Dictionary=active.call("get_field_loading_state") if is_instance_valid(active) and active.has_method("get_field_loading_state") else {}
		var signature: String=var_to_str([prep.get("phase"),prep.get("error"),_physical(active),loading.get("stage"),loading.get("failed"),_busy()])
		if observations<24 and (signature!=last_signature or Time.get_ticks_msec()-last_time>=2000):
			observations+=1;last_signature=signature;last_time=Time.get_ticks_msec()
			_diagnostic("WAIT_PHASE:"+physical)
		if loading.get("failed")==true and _physical(active)==physical: return need(false,"ACTUAL_FIELD_LOAD_FAILED:"+physical)
		if prep.get("scene_id")==physical and prep.get("active")==false and prep.get("phase") in ["FAILED","REJECTED","CANCELLED"]: return need(false,"ACTUAL_PUBLIC_PREPARATION_REJECTED:"+physical)
		if not is_instance_valid(active) or active.get_instance_id()==previous or _physical(active)!=physical: continue
		var actor: Node=_property(active,"_player") as Node
		if loading.get("complete")!=true or _property(active,"_scene_rebuilding",false)==true or _busy() or not is_instance_valid(actor) or actor.get("can_move")!=true: continue
		field=active
		var state: Dictionary=host.call("get_debug_state")
		if not String(state.get("last_error","")).is_empty(): return need(false,"ACTUAL_HOST_ERROR:"+String(state.last_error))
		if state.get("ready")!=true or state.get("attached_scene")!=physical or state.get("metadata",{}).get("scene_id")!=physical or state.get("mini_ok")!=true: continue
		var mini: Node=field.get("_world_travel_minimap") as Node
		var cache: Node=_property(mini,"_visual_cache") as Node
		if cache==null or cache.get("capture_ready")!=true: continue
		await physics_frame
		await RenderingServer.frame_post_draw
		_diagnostic("WAIT_SUCCESS:"+physical)
		return need(state.get("source_manifest_sha256")==cfg.approved_after_manifest_sha256,"ACTUAL_HOST_EXPLICIT_FINAL99")
	return need(false,"ACTUAL_FINITE_FIELD_READY:"+physical)

func _near(sample: Dictionary) -> bool:
	var previous: int=current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
	if sample.physical=="luoyang_civic_market_region_27d":
		var dispatch: GDScript=load(REG_DISPATCH) as GDScript
		var extension: Dictionary={"region_id":sample.physical,"revision":1,"logical_id":sample.logical,"global_foot_px":[sample.foot.x,sample.foot.y]}
		if not need(dispatch.call("start",router,StringName(sample.logical),Vector2(.5,.5),"",3,extension)==true,"PUBLIC_CIVIC_NEAR_SETUP_ONLY"): return false
	else:
		if String(router.call("get_current_field_id"))!=sample.logical:
			if not need(router.call("go_field_smart",StringName(sample.logical),null,"",-1,-1)==true,"PUBLIC_DOCKS_CONTEXT_SETUP_NOT_TRUE_LEG"): return false
			if not await _wait_field(previous,sample.physical): return false
			previous=field.get_instance_id()
		var geo: GDScript=load(GEO) as GDScript
		var extent: Vector2=geo.call("size_for",String(sample.physical))
		if not need(extent.x>0 and extent.y>0,"ORIGINAL_DOCKS_EXTENT"): return false
		if not need(router.call("go_field_smart",StringName(sample.logical),sample.foot/extent,"",-1,3)==true,"PUBLIC_DOCKS_V3_NEAR_SETUP_ONLY"): return false
	if not await _wait_field(previous,sample.physical): return false
	records.append({"public_near_not_continuous_travel":true,"sample":sample.id,"requested_foot":sample.foot,"actual":_normal_state(),"no_space_or_movement":true})
	return true

func _normal_state() -> Dictionary:
	var actor: Node2D=field.get("_player") as Node2D
	var camera: Camera2D=field.get("_world_camera") as Camera2D
	var world: Node2D=field.get("world_container") as Node2D
	return {"field_instance":field.get_instance_id(),"physical":_physical(field),"logical":String(router.call("get_current_field_id")),"foot":actor.position,"camera_zoom":camera.zoom if camera!=null else null,"camera_position":camera.position if camera!=null else null,"world_scale":world.scale,"field_camera_zoom":field.get("_camera_zoom"),"viewport":root.get_viewport().get_visible_rect().size}

func _capture_first(sample: Dictionary) -> bool:
	await RenderingServer.frame_post_draw
	var before: Dictionary=_normal_state()
	var image: Image=root.get_viewport().get_texture().get_image()
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and images<2 and before.physical==sample.physical,"TWO_SAME_SCENE1920_IMAGES_MAX:"+sample.id): return false
	var path: String=directory+"/"+String(sample.image)+".png"
	if not need(image.save_png(path)==OK,"SAVE_NORMAL_IMAGE_BEFORE_VISUAL_MEASURES:"+sample.id): return false
	images+=1
	records.append({"normal_image_saved_before_measure":path,"sha256":FileAccess.get_sha256(path),"sample":sample.id,"normal_state_before":before,"normal_state_after":_normal_state(),"no_input_camera_writes":true,"preserve_image_even_if_measure_fails":true})
	return true

func _uniforms(material: ShaderMaterial) -> Dictionary:
	var result: Dictionary={}
	for uniform: Dictionary in material.shader.get_shader_uniform_list():
		var name: String=String(uniform.name)
		var value: Variant=material.get_shader_parameter(name)
		if value is Texture2D: result[name]={"texture":value.resource_path,"size":value.get_size()}
		elif value is Resource: result[name]={"resource_class":value.get_class(),"path":value.resource_path}
		else: result[name]=value
	return result

func _cache_z(source: Node2D, world: Node2D) -> int:
	var value: int=source.z_index
	var item: Node2D=source
	while item.z_as_relative and item.get_parent() is Node2D and item.get_parent()!=world:
		item=item.get_parent() as Node2D
		value+=item.z_index
	return clampi(value,-4096,4095)

func _endpoint_evidence(sample: Dictionary) -> bool:
	var pair_script: GDScript=load(PAIRS) as GDScript
	var found: Array=pair_script.call("relations").filter(func(row: Dictionary)->bool:return row.get("pair_id")==sample.pair)
	if not need(found.size()==1,"ONE_UNCHANGED_PAIR:"+sample.id): return false
	var endpoint: Dictionary=found[0][sample.side]
	if not need(endpoint.scene_id==sample.physical and endpoint.logical_id==sample.logical and endpoint.mouth==sample.mouth and endpoint.arrival==sample.foot and endpoint.outward==sample.outward and endpoint.source_portal==sample.portal and endpoint.retired_feet==sample.retired and endpoint.activation_size==sample.size,"ORIGINAL_PAIR_GEOMETRY_PRECISE:"+sample.id): return false
	var zones: Array=[]
	for node: Node in get_nodes_in_group("exit_zone"):
		if node is ExitZone and node.has_meta("citynav_endpoint"):
			var data: Dictionary=node.get_meta("citynav_endpoint")
			if data.get("id")==sample.id: zones.append(node)
	if not need(zones.size()==1,"ONE_CURRENT_LIVE_ZONE:"+sample.id): return false
	var zone: ExitZone=zones[0] as ExitZone
	var shape: CollisionShape2D=zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not need(zone.position==sample.mouth and zone.target_scene_id==sample.target and not zone.auto_trigger and shape!=null and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size==sample.size,"LIVE_ENDPOINT_POS_TARGET_ACTIVATION_UNCHANGED:"+sample.id): return false
	var originals: Array[Dictionary]=[]
	var original_locked := false
	var states: Dictionary=host.get("_states")
	for state: Dictionary in states.values():
		var reference: WeakRef=state.get("field") as WeakRef
		if reference==null or reference.get_ref()!=field: continue
		for row: Dictionary in state.get("retired",[]):
			if row.get("target")!=sample.target: continue
			for foot: Vector2 in sample.retired:
				if (row.position as Vector2).distance_to(foot)<.5:
					original_locked=original_locked or bool(row.locked)
					originals.append({"original_position":row.position,"target":row.target,"locked":row.locked})
	if not need(originals.size()==sample.retired.size() and zone.is_locked==original_locked,"ORIGINAL_LOCK_AND_RETIRED_POS_PRESERVED:"+sample.id): return false
	var normal: Dictionary=_normal_state()
	var geo: GDScript=load(GEO) as GDScript
	if not need(normal.physical==sample.physical and normal.logical==sample.logical and normal.foot.distance_to(sample.foot)<.03 and normal.camera_zoom==Vector2.ONE and normal.world_scale==Vector2.ONE and normal.field_camera_zoom==1.0 and normal.viewport==Vector2(1920,1080) and geo.call("physics_clear",field,normal.foot)==true,"NORMAL_EXACT_PUBLIC_NEAR_AND_REAL_FOOT_CLEAR:"+sample.id): return false
	var receipt: Dictionary=field.get_meta("city_navigation_20261101d_mouth_visual",{})
	var rows: Array=receipt.get("rows",[]).filter(func(row: Dictionary)->bool:return row.get("pair_id")==sample.pair)
	if not need(receipt.get("ok")==true and receipt.get("original_NAV_and_bodies_unchanged")==true and rows.size()==1,"CURRENT_CLASS_ROAD_RECEIPT:"+sample.id): return false
	var expected: Dictionary={}
	for row: Dictionary in cfg.cases:
		if row.get("id")==sample.id: expected=row.get("expected_receipt",{})
	if not need(not expected.is_empty(),"ROOT_EXPLICIT_EXPECTED_CLASS_RECEIPT_REQUIRED:"+sample.id): return false
	for key: String in expected:
		if not need(rows[0].get(key)==expected[key],"ROOT_APPROVED_CLASS_RECEIPT_FIELD:"+sample.id+":"+key): return false
	records.append({"actual_endpoint_evidence":sample.id,"original_retired_positions":originals,"actual_zone_pos":zone.position,"actual_lock":zone.is_locked,"current_road_receipt":receipt,"selected_class_receipt":rows[0],"root_expected_class_fields":expected,"normal_state":normal})
	return true

func _mini_ground_evidence(sample: Dictionary) -> bool:
	var layer: Node=field.get("_visual_layer").get_node_or_null("CityNavigationRoadMouths11d")
	var mini: Node=field.get("_world_travel_minimap") as Node
	var cache: Node=_property(mini,"_visual_cache") as Node
	var canvas: Node=_property(cache,"_canvas") as Node
	var world: Node2D=field.get("world_container") as Node2D
	var actor: Node2D=field.get("_player") as Node2D
	if not need(layer!=null and cache!=null and canvas!=null,"REAL_ROAD_LAYER_AND_MINI_CACHE:"+sample.id): return false
	var cache_state: Dictionary=cache.call("get_debug_state")
	var plan: Node=mini.get("_plan") as Node
	if not need(cache_state.get("ready")==true and cache_state.get("valid")==true and cache_state.get("render_requests")==1 and cache_state.get("compiled_render_count")==cache_state.get("full_compiled_render_count") and plan.get("base_texture")==cache.call("get_texture"),"ACTUAL_ONE_CAPTURE_FULL_COMPILED_CACHE_TEXTURE:"+sample.id): return false
	var evidence: Array[Dictionary]=[]
	var actor_depth: Dictionary=_depth(actor)
	for source: Node in layer.get_children():
		if not source is Polygon2D or not source.is_visible_in_tree(): continue
		var source_poly: Polygon2D=source as Polygon2D
		var depth: Dictionary=_depth(source_poly)
		var material: ShaderMaterial=source_poly.material as ShaderMaterial
		var uniforms: Dictionary=_uniforms(material) if material!=null and material.shader!=null else {}
		var matches: Array[Dictionary]=[]
		for leaf: Node in canvas.get_children():
			if not leaf is Polygon2D or leaf.polygon!=source_poly.polygon or leaf.uv!=source_poly.uv: continue
			if leaf.texture==null or source_poly.texture==null or leaf.texture.resource_path!=source_poly.texture.resource_path: continue
			var cloned: ShaderMaterial=leaf.material as ShaderMaterial
			var material_exact: bool=(material==null and cloned==null) or (material!=null and cloned!=null and cloned.shader!=null and material.shader!=null and cloned.shader.code==material.shader.code and var_to_bytes(_uniforms(cloned))==var_to_bytes(uniforms))
			matches.append({"clone_scriptless":leaf.get_script()==null,"material_uniforms_exact":material_exact,"cache_z":leaf.z_index,"expected_cache_z":_cache_z(source_poly,world),"transform_exact":leaf.transform.is_equal_approx(world.global_transform.affine_inverse()*source_poly.global_transform)})
		var exact: bool=matches.size()==1 and matches[0].clone_scriptless and matches[0].material_uniforms_exact and matches[0].cache_z==matches[0].expected_cache_z and matches[0].transform_exact
		evidence.append({"source":String(source_poly.get_path()),"texture":source_poly.texture.resource_path if source_poly.texture!=null else "","effective_depth":depth,"shader_uniforms":uniforms,"clone_matches":matches,"exact":exact})
		if not need(source_poly.z_as_relative and depth.effective_z<actor_depth.effective_z and exact,"CURRENT_GROUND_MINI_CLONE_AND_EFFECTIVE_DEPTH:"+sample.id+":"+String(source_poly.name)):
			records.append({"actual_mini_ground_evidence":evidence,"cache":cache_state,"actor_effective_depth":actor_depth});return false
	if not need(not evidence.is_empty() and evidence.size()<=64 and layer.find_children("*","CollisionObject2D",true,false).is_empty(),"FINITE_ACTUAL_GROUND_POLYGONS_ZERO_ADDED_BODIES:"+sample.id): return false
	records.append({"actual_mini_ground_evidence":evidence,"cache":cache_state,"actor_effective_depth":actor_depth,"same_class_scene":sample.id})
	return true

func run() -> void:
	directory=HOME+"actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND_NO171_RESAMPLE"): finish();return
	input_sha=FileAccess.get_sha256(INPUTS)
	cfg=JSON.parse_string(FileAccess.get_file_as_string(INPUTS)) as Dictionary
	if not need(cfg.get("schema")=="CITY_NAVIGATION_20261102A_TWO_CLASSES_VISUAL03_QA_V1" and cfg.get("ready")==true and cfg.get("root_only")==true and cfg.get("baseline_before_manifest_sha256")==OLD_MANIFEST_SHA,"ROOT_EXPLICIT_TWO_CLASS_SUCCESSOR_APPROVAL"): finish();return
	pins=cfg.get("source_pins",{}).duplicate(true)
	if not need(pins.has(SELF) and pins.has(MANIFEST) and String(cfg.get("approved_after_manifest_sha256","")).length()==64 and pins.get(MANIFEST)==cfg.approved_after_manifest_sha256 and cfg.get("cases",[]).size()==2,"ROOT_EXPLICIT_FINAL99_EXPECTED_NOT_ACTUAL_INFERRED"): finish();return
	for path: String in pins:
		if not need(path.begins_with("res://") and not ".." in path and String(pins[path]).length()==64,"SOURCE_ONLY_PIN_NO_USER_FILES:"+path): finish();return
	first=facts()
	for path: String in pins:
		if not need(first[path].sha256==pins[path],"VISUAL03_SOURCE_FIRST:"+path): finish();return
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) as Dictionary
	var pool: Dictionary=manifest.get("source_pins",{})
	if not need(manifest.get("ready")==true and pool.size()==99,"APPROVED_FINAL99_NO_NEW_POOL"): finish();return
	for path: String in [HOST,PAIRS,GEO,MOUTH,SHADER]:
		if not need(pool.get(path)==pins.get(path),"FINAL99_HOST_PAIR_GEO_TWO_HELPERS:"+path): finish();return
	router=root.get_node_or_null("SceneRouter");host=root.get_node_or_null("CityNavigationRuntime")
	if not need(router!=null and host!=null and host.get_script().resource_path==HOST,"ACTUAL_UNCHANGED_NAVIGATION_HOST"): finish();return
	for index: int in range(FIXED.size()):
		var sample: Dictionary=FIXED[index]
		if not need(cfg.cases[index].get("id")==sample.id,"ONLY_TWO_FIXED_CLASS_ENDPOINTS:"+str(index)): finish();return
		if not await _near(sample): finish();return
		# Keep actual normal images even when the following visual oracle fails.
		if not await _capture_first(sample): finish();return
		var endpoint_ok: bool=_endpoint_evidence(sample)
		var ground_ok: bool=_mini_ground_evidence(sample)
		records.append({"sample_measure_passed":endpoint_ok and ground_ok,"sample":sample.id,"normal_image_already_preserved":true,"continues_to_other_requested_class_after_measure_failure":true})
	finish()

func finish() -> void:
	if done:return
	done=true
	var last: Dictionary=facts() if not pins.is_empty() else {}
	if not first.is_empty():need(var_to_bytes(first)==var_to_bytes(last),"SMALL_SOURCE_FIRST_FINAL_EXACT")
	if not input_sha.is_empty():need(FileAccess.get_sha256(INPUTS)==input_sha,"ROOT_CONFIG_UNCHANGED")
	var result: Dictionary={"passed":errors.is_empty() and images==2,"checks":checks,"errors":errors,"normal_images":images,"input_events":0,"true_legs_executed":0,"checkpoint_suspended":suspended,"records":records,"source_first":first,"source_final":last,"inputs_sha256":input_sha,"root_only":true,"save_content_or_metadata_APIs":0,"inherited_functional_evidence":cfg.get("inherited_functional",{}),"scope":"TWO_CLASS_NORMAL_IMAGES_NOT22_END_ART"}
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(result,"\t")+"\n")
	print("CITYNAV02A_VISUAL03 ",JSON.stringify({"passed":result.passed,"checks":checks,"errors":errors,"images":images,"inputs":0,"result":directory+"/result.json"}))
	quit(0 if result.passed else 1)

