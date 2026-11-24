extends SceneTree
## Exact residual only: ONE changed pair both directions + ONE Civic normal
## image; Docks native zoom/receipt tail only, with its old normal image inherited.
const HOME := "res://build/city_navigation_20261102a_visual04/"
const SELF := HOME+"residual_ROOT_ONLY.gd"
const INPUTS := HOME+"residual_inputs_ROOT_READY.json"
const HOST := "res://build/city_navigation_20261101d_candidate01/city_navigation_runtime.gd"
const PAIRS := "res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd"
const GEO := "res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd"
const MANIFEST := "res://build/city_navigation_20261101d_candidate01/source_pins_READY.json"
const REG_DISPATCH := "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd"
const REG_ENTRY := "res://build/luoyang_regions_20261027d_source01/region_entry.gd"
const OLD_MANIFEST_SHA := "cfd6d77c8afcc1d90c808d5cd82ec77e106ede9250c2c094c81cb9171e5f66a0"
const DOCKS_SCENE := "res://data/scenes/ch4_s2_canal_docks.tres"
var cfg: Dictionary = {}
var pins: Dictionary = {}
var first: Dictionary = {}
var records: Array[Dictionary] = []
var errors: Array[String] = []
var observed_toasts: Array[String] = []
var passed_legs: Array[Dictionary] = []
var checks := 0
var inputs := 0
var done := false
var suspended := false
var directory := ""
var input_sha := ""
var field: Node
var host: Node
var router: Node
var pair_data: GDScript
var geometry: GDScript
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
	await create_timer(180.0,true,false,true).timeout
	if not done:
		need(false,"FINITE_180S_WATCHDOG")
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
	print("CITYNAV02A_R04_STATE ",JSON.stringify(value))

func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		_diagnostic("FAIL_BEFORE_ORACLE:"+label)
		errors.append(label)
		printerr("CITYNAV02A_R04_FAIL ",label)
	return ok

func facts() -> Dictionary:
	var result: Dictionary = {}
	for path: String in pins:
		var file := FileAccess.open(path,FileAccess.READ)
		result[path] = {"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file != null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result

func _wait_field(previous: int, physical: String) -> bool:
	var limit: int = Time.get_ticks_msec()+30000
	var signature := ""
	var last_observation := 0
	var observations := 0
	_diagnostic("WAIT_BEGIN:"+physical)
	while not done and Time.get_ticks_msec() < limit:
		await process_frame
		var candidate: Node = current_scene
		var preparation: Dictionary = router.call("get_public_city_preparation_state")
		var loading: Dictionary = candidate.call("get_field_loading_state") if is_instance_valid(candidate) and candidate.has_method("get_field_loading_state") else {}
		var next_signature: String = var_to_str([preparation.get("phase"),preparation.get("error"),preparation.get("active"),_physical(candidate),loading.get("stage"),loading.get("failed"),_busy()])
		if observations < 24 and (next_signature != signature or Time.get_ticks_msec()-last_observation >= 2000):
			signature=next_signature; last_observation=Time.get_ticks_msec(); observations+=1
			_diagnostic("WAIT_PHASE:"+physical)
		if preparation.get("scene_id") == physical and preparation.get("active") == false and preparation.get("phase") in ["FAILED","REJECTED","CANCELLED"]:
			return need(false,"ACTUAL_PUBLIC_PREPARATION_FAILED:"+physical+":"+String(preparation.get("error","")))
		if not is_instance_valid(candidate) or candidate.get_instance_id() == previous or _physical(candidate) != physical: continue
		if loading.get("failed") == true: return need(false,"ACTUAL_FIELD_LOAD_FAILED:"+physical)
		var actor: Node = _property(candidate,"_player") as Node
		if loading.get("complete") != true or _property(candidate,"_scene_rebuilding",false) == true or _busy() or not is_instance_valid(actor) or _property(actor,"can_move") != true: continue
		field=candidate
		var state: Dictionary = host.call("get_debug_state")
		if not String(state.get("last_error","")).is_empty(): return need(false,"ACTUAL_HOST_RUNTIME_ERROR:"+String(state.last_error))
		if state.get("ready") != true or state.get("metadata",{}).get("scene_id") != physical or state.get("attached_scene") != physical or state.get("mini_ok") != true or not state.get("pending",{}).is_empty(): continue
		if not need(state.get("source_manifest_sha256") == String(cfg.approved_after_manifest_sha256),"ACTUAL_HOST_EXPLICIT_APPROVED_PAIR_SUCCESSOR99"): return false
		var mini: Node = _property(field,"_world_travel_minimap") as Node
		var cache: Node = _property(mini,"_visual_cache") as Node
		if cache != null and _property(cache,"capture_ready") != true: continue
		await physics_frame
		await RenderingServer.frame_post_draw
		_diagnostic("WAIT_SUCCESS:"+physical)
		return true
	return need(false,"ACTUAL_FIELD_FINITE_READY:"+physical)

func _near(endpoint: Dictionary) -> bool:
	var requested: Vector2 = endpoint.arrival
	var previous: int = current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
	var entry: GDScript = load(REG_ENTRY) as GDScript
	if entry.call("requested",StringName(endpoint.logical_id)) == true:
		var dispatch: GDScript = load(REG_DISPATCH) as GDScript
		var extension: Dictionary = {"region_id":endpoint.scene_id,"revision":1,"logical_id":endpoint.logical_id,"global_foot_px":[requested.x,requested.y]}
		if not need(dispatch.call("start",router,StringName(endpoint.logical_id),Vector2(.5,.5),"",3,extension) == true,"PUBLIC_REGION_NEAR_SETUP:"+endpoint.logical_id): return false
	else:
		if String(router.call("get_current_field_id")) != endpoint.logical_id:
			if not need(router.call("go_field_smart",StringName(endpoint.logical_id),null,"",-1,-1) == true,"PUBLIC_LEGACY_CONTEXT_SETUP_NOT_TRUE_LEG:"+endpoint.logical_id): return false
			if not await _wait_field(previous,endpoint.scene_id): return false
			previous=field.get_instance_id()
		var extent: Vector2 = geometry.call("size_for",String(endpoint.scene_id))
		if not need(extent.x > 0 and extent.y > 0,"ORIGINAL_DECLARED_LEGACY_EXTENT:"+endpoint.scene_id): return false
		if not need(router.call("go_field_smart",StringName(endpoint.logical_id),requested/extent,"",-1,3) == true,"PUBLIC_V3_NEAR_SETUP:"+endpoint.logical_id): return false
	if not await _wait_field(previous,endpoint.scene_id): return false
	var actor: Node2D = field.get("_player") as Node2D
	records.append({"public_near_setup_not_continuous_travel":true,"pair_id":endpoint.pair_id,"seed_side":endpoint.side,"requested_foot":requested,"actual_foot":actor.position,"physical":_physical(field),"logical":router.call("get_current_field_id"),"private_actor_router_writes":false})
	return need(actor.position.distance_to(requested) < .03 and String(router.call("get_current_field_id")) == endpoint.logical_id,"EXACT_PUBLIC_NEAR_FOOT_AND_LOGICAL:"+endpoint.pair_id)


func _pair(id: String) -> Dictionary:
	var result: Array = pair_data.call("relations").filter(func(row: Dictionary) -> bool: return row.get("pair_id") == id)
	return result[0] if result.size() == 1 else {}

func _endpoint(pair: Dictionary, side: String) -> Dictionary:
	var value: Dictionary = pair[side].duplicate(true)
	value["pair_id"]=pair.pair_id; value["side"]=side; value["id"]="citynav/"+String(pair.pair_id)+"/"+side
	value["target"]=pair["b" if side == "a" else "a"].duplicate(true)
	return value

func _zone(endpoint: Dictionary) -> ExitZone:
	var result: ExitZone
	for node: Node in get_nodes_in_group("exit_zone"):
		if not node is ExitZone or not node.has_meta("citynav_endpoint"): continue
		var value: Dictionary = node.get_meta("citynav_endpoint")
		if value.get("pair_id") != endpoint.pair_id or value.get("side") != endpoint.side: continue
		if result != null: return null
		result=node as ExitZone
	return result

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode=code; event.physical_keycode=code; event.pressed=pressed
	Input.parse_input_event(event); Input.flush_buffered_events(); inputs+=1

func _tap_space() -> void:
	await physics_frame
	_key(KEY_SPACE,true)
	await physics_frame
	_key(KEY_SPACE,false)
	await process_frame

func _original_lock(endpoint: Dictionary, zone: ExitZone) -> bool:
	var snapshots: Array[Dictionary] = []
	var expected_locked := false
	var states: Dictionary = host.get("_states")
	for state: Dictionary in states.values():
		var reference: WeakRef = state.get("field") as WeakRef
		if reference == null or reference.get_ref() != field: continue
		for row: Dictionary in state.get("retired",[]):
			if row.get("target") != endpoint.target.logical_id: continue
			for foot: Vector2 in endpoint.retired_feet:
				if (row.position as Vector2).distance_to(foot) < .5:
					expected_locked=expected_locked or bool(row.locked)
					snapshots.append({"position":row.position,"target":row.target,"original_locked":row.locked})
	records.append({"original_lock_readonly":snapshots,"pair":endpoint.pair_id,"side":endpoint.side,"new_zone_locked":zone.is_locked,"expected_locked_or":expected_locked,"flags_written":false})
	if not need(snapshots.size() == endpoint.retired_feet.size() and zone.is_locked == expected_locked,"ORIGINAL_LOCK_AND_RETURN_ENDPOINT_IDENTITY:"+endpoint.pair_id+":"+endpoint.side): return false
	return need(not zone.is_locked,"ORIGINAL_LOCK_ACTIVE_NO_UNLOCK_OR_FAKE_LEG:"+endpoint.pair_id+":"+endpoint.side)

func _coherent(endpoint: Dictionary, zone: ExitZone) -> bool:
	var actual: Dictionary = zone.get_meta("citynav_endpoint",{})
	var metadata: Dictionary = host.call("get_debug_state").get("metadata",{})
	var rows: Array = metadata.get("portals",[]).filter(func(row: Dictionary) -> bool: return row.get("id") == endpoint.id)
	var visual: Sprite2D = zone.get_node_or_null("MarkerVisual") as Sprite2D
	var prompt: Label = zone.get_node_or_null("Prompt") as Label
	var shape: CollisionShape2D = zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var expected_label: String = "空格 · 前往"+String(pair_data.call("destination_name",String(endpoint.target.logical_id)))
	var reference: WeakRef = field.get_meta("city_navigation_20261101d_minimap") as WeakRef
	var mini: Node = reference.get_ref() as Node if reference != null else null
	var mini_rows: Array = []
	var mini_state: Dictionary = {}
	if is_instance_valid(mini):
		mini_state=mini.call("get_debug_state")
		mini_rows=(mini.get("_rows") as Array).filter(func(row: Dictionary) -> bool: return row.get("id") == endpoint.id)
	var ok: bool = zone.position.distance_to(endpoint.mouth) < .01 and zone.target_scene_id == endpoint.target.logical_id and not zone.auto_trigger and actual.get("mouth") == endpoint.mouth and actual.get("arrival") == endpoint.arrival and actual.get("outward") == endpoint.outward
	ok=ok and rows.size() == 1 and rows[0].get("foot") == endpoint.mouth and rows[0].get("target_scene") == endpoint.target.logical_id and rows[0].get("kind") == "area_exit" and rows[0].get("locked") == zone.is_locked
	ok=ok and visual != null and prompt != null and prompt.text == expected_label and zone.exit_label == expected_label and shape != null and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size == endpoint.activation_size
	ok=ok and mini_rows.size() == 1 and mini_rows[0].get("foot") == endpoint.mouth and mini_rows[0].get("target_scene") == endpoint.target.logical_id and mini_rows[0].get("kind") == "area_exit" and mini_rows[0].get("locked") == zone.is_locked
	if visual != null: ok=ok and absf(angle_difference(visual.rotation,endpoint.outward.angle()-PI*.5)) < .0001
	records.append({"actual_trigger_marker_mini_coherence":ok,"pair":endpoint.pair_id,"side":endpoint.side,"zone":String(zone.get_path()),"mouth":zone.position,"target":zone.target_scene_id,"prompt":prompt.text if prompt != null else "","expected_target_only_prompt":expected_label,"original_mini_rows":mini_rows,"mini_actual_presentation":mini_state})
	return need(ok,"ACTUAL_TRIGGER_MINI_TARGET_DIRECTION_PROMPT:"+endpoint.pair_id+":"+endpoint.side)

func _walk(endpoint: Dictionary, zone: ExitZone) -> bool:
	var actor: CharacterBody2D = field.get("_player") as CharacterBody2D
	var outward: Vector2 = endpoint.outward
	var code: Key = KEY_S if outward.y > 0 else (KEY_W if outward.y < 0 else (KEY_D if outward.x > 0 else KEY_A))
	var start: Vector2 = actor.position
	var ticks := 0
	_key(code,true)
	while not done and ticks < 40 and is_instance_valid(zone) and zone.call("_can_enter") != true:
		await physics_frame
		ticks+=1
	_key(code,false)
	await physics_frame
	var can_enter: bool = is_instance_valid(zone) and zone.call("_can_enter") == true
	records.append({"real_short_walk":true,"pair":endpoint.pair_id,"side":endpoint.side,"start":start,"actual_end":actor.position,"velocity":actor.velocity,"ticks":ticks,"can_enter":can_enter,"can_move":actor.get("can_move"),"mouth":endpoint.mouth})
	return need(ticks > 0 and actor.position.distance_to(start) > 1 and can_enter,"TRUE_SHORT_WALK_TO_ACTUAL_ACTIVATION:"+endpoint.pair_id+":"+endpoint.side)

func _stable_arrival(endpoint: Dictionary) -> bool:
	var actor: CharacterBody2D = field.get("_player") as CharacterBody2D
	var instance: int = field.get_instance_id()
	var history_count: int = host.call("get_debug_state").get("route_history",[]).size()
	var contact := Rect2(endpoint.mouth-endpoint.activation_size*.5,endpoint.activation_size)
	var shape: CollisionShape2D = actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not need(shape != null and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size == Vector2(34,24),"ACTUAL_ORIGINAL34X24_PLAYER_FOOT"): return false
	if not need(actor.position.distance_to(endpoint.arrival) < .03 and not contact.has_point(actor.position) and geometry.call("physics_clear",field,actor.position) == true,"ACTUAL_DECLARED_ARRIVAL_OUTSIDE_TRIGGER_FULL_FOOT_CLEAR:"+endpoint.pair_id+":"+endpoint.side): return false
	await create_timer(.35,true,false,true).timeout
	var unchanged: bool = is_instance_valid(current_scene) and current_scene.get_instance_id() == instance and is_instance_valid(actor) and actor.position.distance_to(endpoint.arrival) < .03 and host.call("get_debug_state").get("route_history",[]).size() == history_count and host.call("get_debug_state").get("pending",{}).is_empty()
	records.append({"natural_arrival_outside_activation_no_automatic_bounce":unchanged,"pair":endpoint.pair_id,"side":endpoint.side,"foot":actor.position if is_instance_valid(actor) else null,"manual_input_required":true})
	return need(unchanged,"ARRIVAL_NO_INSTANT_RETURN_WITHOUT_INPUT:"+endpoint.pair_id+":"+endpoint.side)

func _cross(endpoint: Dictionary) -> bool:
	var leg_key: String = String(endpoint.pair_id)+":"+String(endpoint.side)
	for passed: Dictionary in passed_legs:
		if not need(passed.get("key") != leg_key,"NO_SUCCESSFUL_LEG_REPEATED:"+leg_key): return false
	var zone: ExitZone = _zone(endpoint)
	if not need(zone != null,"UNIQUE_CURRENT_ACTUAL_EXITZONE:"+leg_key): return false
	if not _original_lock(endpoint,zone) or not _coherent(endpoint,zone) or not await _walk(endpoint,zone): return false
	var actor: CharacterBody2D = field.get("_player") as CharacterBody2D
	var activation_foot: Vector2 = actor.position
	var previous: int = field.get_instance_id()
	var history_before: int = host.call("get_debug_state").get("route_history",[]).size()
	await _tap_space()
	if not await _wait_field(previous,endpoint.target.scene_id): return false
	actor=field.get("_player") as CharacterBody2D
	var history: Array = host.call("get_debug_state").get("route_history",[])
	if not need(history.size() == history_before+1,"ONE_REAL_SPACE_ONE_ROUTE_HISTORY_ENTRY:"+leg_key): return false
	var actual: Dictionary = history.back()
	var contact := Rect2(endpoint.mouth-endpoint.activation_size*.5,endpoint.activation_size)
	var ok: bool = actual.get("pair_id") == endpoint.pair_id and actual.get("source_side") == endpoint.side and actual.get("source_scene") == endpoint.scene_id and actual.get("source_declared_return") == endpoint.arrival and actual.get("target_scene") == endpoint.target.scene_id and actual.get("target_logical") == endpoint.target.logical_id and actual.get("target_foot") == endpoint.target.arrival
	ok=ok and actual.get("actual_arrival") is Vector2 and (actual.actual_arrival as Vector2).distance_to(endpoint.target.arrival) < .03
	ok=ok and actual.get("source_activation_foot") is Vector2 and contact.has_point(actual.source_activation_foot) and (actual.source_activation_foot as Vector2).distance_to(activation_foot) < .03
	ok=ok and _physical(field) == endpoint.target.scene_id and String(router.call("get_current_field_id")) == endpoint.target.logical_id and actor.position.distance_to(endpoint.target.arrival) < .03 and actor.get("can_move") == true and geometry.call("physics_clear",field,actor.position) == true
	records.append({"true_space_crossing":true,"passed":ok,"key":leg_key,"actual_physical":_physical(field),"actual_logical":router.call("get_current_field_id"),"actual_foot":actor.position,"expected_arrival":endpoint.target.arrival,"actual_route_history_entry":actual,"input_events_so_far":inputs})
	if not need(ok,"TRUE_SPACE_EXACT_PHYSICAL_LOGICAL_ARRIVAL_RETURN_HISTORY:"+leg_key): return false
	passed_legs.append({"key":leg_key,"pair_id":endpoint.pair_id,"source_side":endpoint.side,"target_scene":_physical(field),"target_logical":String(router.call("get_current_field_id")),"actual_arrival":actor.position,"route_history_entry":actual.duplicate(true)})
	return true



func _new_pair_exact(pair: Dictionary) -> bool:
	if not need(not pair.is_empty(),"ONE_ROOT_APPROVED_CHANGED_PAIR"): return false
	var a: Dictionary=pair.a
	var b: Dictionary=pair.b
	var a_ok: bool=a.scene_id=="luoyang_civic_market_region_27d" and a.logical_id=="ch4_s1_luoyang_yamen" and a.source_portal=="finish_i_yamen_to_artisan" and a.mouth==Vector2(720,840) and a.arrival==Vector2(824,840) and a.outward==Vector2(-1,0) and a.activation_size==Vector2(80,128) and a.retired_feet==[Vector2(720,970)]
	var b_ok: bool=b.scene_id=="luoyang_artisan_residential_20261022ap" and b.logical_id=="luoyang_artisan_residential_20261022ap" and b.source_portal=="finish_i_artisan_to_yamen" and b.mouth==Vector2(2910,1300) and b.arrival==Vector2(2806,1300) and b.outward==Vector2(1,0) and b.activation_size==Vector2(80,128) and b.retired_feet==[Vector2(128,1300)]
	records.append({"one_authorized_pair_change":true,"a":a,"b":b,"original_a_retired_foot_remains720970":true,"other21_endpoints_unchanged_by_Root_exact_pair_proof":cfg.get("approved_pair_proof",{}),"this_is_not_a_static22_retest":true})
	return need(a_ok and b_ok,"EXACT_A_NORTH130_B_UNCHANGED_RETURN_DERIVES_NEW824840")

func _normal_state() -> Dictionary:
	var actor: Node2D=field.get("_player") as Node2D
	var camera: Camera2D=field.get("_world_camera") as Camera2D
	var world: Node2D=field.get("world_container") as Node2D
	var scene: SceneScript=field.get("_current_scene") as SceneScript
	return {"field_instance":field.get_instance_id(),"physical":_physical(field),"logical":String(router.call("get_current_field_id")),"foot":actor.position,"camera_zoom":camera.zoom if camera!=null else null,"camera_position":camera.position if camera!=null else null,"world_scale":world.scale,"field_camera_zoom":field.get("_camera_zoom"),"actual_scene_camera_zoom":scene.camera_zoom if scene!=null else null,"actual_scene_resource":scene.resource_path if scene!=null else "","viewport":root.get_viewport().get_visible_rect().size}

func _capture_civic_first() -> bool:
	await RenderingServer.frame_post_draw
	var before: Dictionary=_normal_state()
	var image: Image=root.get_viewport().get_texture().get_image()
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and images==0 and before.physical=="luoyang_civic_market_region_27d","ONE_ACTUAL_CIVIC1920_IMAGE_BEFORE_MEASURES"): return false
	var path: String=directory+"/civic_north_real_opening_normal.png"
	if not need(image.save_png(path)==OK,"SAVE_ONE_CIVIC_NORMAL_IMAGE"): return false
	images=1
	records.append({"normal_image_saved_before_measure":path,"sha256":FileAccess.get_sha256(path),"normal_state_before":before,"normal_state_after":_normal_state(),"old73468_Civic_remains_ART_REJECTED":true,"Root_new_ART_review_required":true})
	return true

func _receipt_tail(pair_id: String, endpoint_id: String, expected: Dictionary) -> bool:
	var receipt: Dictionary=field.get_meta("city_navigation_20261101d_mouth_visual",{})
	var rows: Array=receipt.get("rows",[]).filter(func(row: Dictionary)->bool:return row.get("pair_id")==pair_id)
	if not need(receipt.get("ok")==true and receipt.get("original_NAV_and_bodies_unchanged")==true and rows.size()==1,"CURRENT_ONE_RESIDUAL_RECEIPT:"+endpoint_id): return false
	if not need(not expected.is_empty(),"EXPLICIT_ROOT_RECEIPT_EXPECTATION:"+endpoint_id): return false
	for key: String in expected:
		if not need(rows[0].get(key)==expected[key],"RESIDUAL_RECEIPT_FIELD:"+endpoint_id+":"+key): return false
	records.append({"residual_receipt_tail":endpoint_id,"actual":rows[0],"expected":expected,"old_mini_matrix_not_repeated":true})
	return true

func _civic_new_visual(a: Dictionary) -> bool:
	var normal: Dictionary=_normal_state()
	var expected_zoom: float=float(cfg.expected_original_zoom.civic)
	var ok: bool=normal.physical==a.scene_id and normal.logical==a.logical_id and normal.foot.distance_to(a.arrival)<.03 and normal.camera_zoom.is_equal_approx(Vector2.ONE*expected_zoom) and absf(float(normal.field_camera_zoom)-expected_zoom)<.000001 and normal.world_scale==Vector2.ONE and normal.viewport==Vector2(1920,1080)
	if not need(ok,"CIVIC_NORMAL_NATIVE_ZOOM_ONE_NEW824840_NO_CAMERA_WRITES"): return false
	var zone: ExitZone=_zone(a)
	if not need(zone!=null and zone.position==Vector2(720,840),"CIVIC_CHANGED_ACTUAL_ARROW_AND_TRIGGER_NORTH_OF_OLD_WALL"): return false
	var metadata: Dictionary=host.call("get_debug_state").get("metadata",{})
	var rows: Array=metadata.get("portals",[]).filter(func(row: Dictionary)->bool:return row.get("id")=="citynav/yamen_artisan/a")
	if not need(rows.size()==1 and rows[0].get("foot")==Vector2(720,840),"CIVIC_CHANGED_MINI_MARKER_SAME_NEW_MOUTH_ONLY"): return false
	records.append({"civic_new_visual_only":true,"actual_changed_endpoint":zone.get_meta("citynav_endpoint"),"actual_minimap_marker_row":rows[0],"normal":normal,"full_mini_clone_and_19_old_checks_inherited_not_repeated":true})
	return _receipt_tail("yamen_artisan","citynav/yamen_artisan/a",cfg.expected_receipts.civic)

func _docks_native_zoom_and_tail() -> bool:
	var normal: Dictionary=_normal_state()
	var expected_zoom: float=float(cfg.expected_original_zoom.docks)
	var original: SceneScript=field.get("_current_scene") as SceneScript
	var ok: bool=expected_zoom==1.05 and normal.physical=="ch4_s2_canal_docks" and normal.logical=="ch4_s2_canal_docks" and normal.foot.distance_to(Vector2(304,850))<.03 and normal.camera_zoom.is_equal_approx(Vector2.ONE*expected_zoom) and absf(float(normal.field_camera_zoom)-expected_zoom)<.000001 and original!=null and absf(float(original.camera_zoom)-expected_zoom)<.000001 and normal.world_scale==Vector2.ONE and normal.viewport==Vector2(1920,1080)
	# The old hard-1 camera conjunction short-circuited before its final physics
	# query; retain this previously unexecuted tail instead of claiming credit.
	var actual_foot_clear: bool=geometry.call("physics_clear",field,normal.foot)==true
	ok=ok and actual_foot_clear
	records.append({"Docks_only_previously_failed_native_zoom_oracle":true,"native_expected_from_Root_pinned_source":expected_zoom,"canonical_source":DOCKS_SCENE,"canonical_source_sha256":pins.get(DOCKS_SCENE),"actual_normal":normal,"actual_full_foot_physics_clear":actual_foot_clear,"inherited_old_821E_Docks_normal_image_not_recaptured":cfg.get("inherited_Docks_image",{}),"no_camera_or_actor_writes":true})
	if not need(ok,"DOCKS_NATIVE_ORIGINAL1_POINT05_NOT_FORCED_ONE"): return false
	return _receipt_tail("yamen_docks","citynav/yamen_docks/b",cfg.expected_receipts.docks)

func run() -> void:
	directory=HOME+"actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND_OUTER_ROOT_GUARD_ONLY171"): finish();return
	input_sha=FileAccess.get_sha256(INPUTS)
	cfg=JSON.parse_string(FileAccess.get_file_as_string(INPUTS)) as Dictionary
	if not need(cfg.get("schema")=="CITY_NAVIGATION_20261102A_RESIDUAL04_TWO_LEGS_ONE_IMAGE_V1" and cfg.get("ready")==true and cfg.get("root_only")==true and cfg.get("baseline_before_manifest_sha256")==OLD_MANIFEST_SHA,"ROOT_EXPLICIT_ONE_PAIR_SCOPE_SUCCESSOR"): finish();return
	pins=cfg.get("source_pins",{}).duplicate(true)
	if not need(pins.has(SELF) and pins.has(MANIFEST) and pins.has(PAIRS) and pins.has(DOCKS_SCENE) and String(cfg.get("approved_after_manifest_sha256","")).length()==64 and pins[MANIFEST]==cfg.approved_after_manifest_sha256 and cfg.get("real_pair_ids")==["yamen_artisan"] and cfg.get("expected_original_zoom",{}).get("civic")==1.0 and cfg.expected_original_zoom.get("docks")==1.05,"ROOT_PINNED_PAIR_SUCCESSOR99_AND_NATIVE_ZOOMS"): finish();return
	for path: String in pins:
		if not need(path.begins_with("res://") and not ".." in path and String(pins[path]).length()==64,"SOURCE_ONLY_PIN_NO_USER_FILES:"+path): finish();return
	first=facts()
	for path: String in pins:
		if not need(first[path].sha256==pins[path],"RESIDUAL04_SOURCE_FIRST:"+path): finish();return
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) as Dictionary
	var pool: Dictionary=manifest.get("source_pins",{})
	if not need(manifest.get("ready")==true and pool.size()==99 and pool.get(PAIRS)==pins[PAIRS],"ROOT_APPROVED_PAIR_ONLY99_SUCCESSOR"): finish();return
	for path: String in [HOST,GEO,"res://build/city_navigation_20261101d_candidate01/mouth_visual.gd","res://build/city_navigation_20261101d_candidate01/mouth_shoulder.gdshader"]:
		if not need(pool.get(path)==pins.get(path),"UNCHANGED_HOST_GEO_TWO_HELPERS:"+path): finish();return
	router=root.get_node_or_null("SceneRouter");host=root.get_node_or_null("CityNavigationRuntime")
	if not need(router!=null and host!=null and host.get_script().resource_path==HOST,"ACTUAL_UNCHANGED_HOST"): finish();return
	pair_data=load(PAIRS) as GDScript;geometry=load(GEO) as GDScript
	var pair: Dictionary=_pair("yamen_artisan")
	if not _new_pair_exact(pair): finish();return
	var a: Dictionary=_endpoint(pair,"a")
	var b: Dictionary=_endpoint(pair,"b")
	if not await _near(a) or not await _capture_civic_first(): finish();return
	var civic_visual_ok: bool=_civic_new_visual(a)
	records.append({"new_Civic_visual_measure_passed":civic_visual_ok,"image_retained_before_measure":true})
	# Exactly this approved changed pair. No setup between the two true legs.
	if not await _stable_arrival(a) or not await _cross(a) or not await _stable_arrival(b) or not await _cross(b) or not await _stable_arrival(a): finish();return
	if not need(passed_legs.size()==2,"ONLY_CHANGED_PAIR_TWO_REAL_DIRECTIONS_COMPLETED"): finish();return
	var docks: Dictionary=_pair("yamen_docks")
	if not need(not docks.is_empty(),"EXISTING_DOCKS_TAIL_SOURCE_PAIR"): finish();return
	var docks_b: Dictionary=_endpoint(docks,"b")
	if not need(docks_b.arrival==Vector2(304,850) and docks_b.mouth==Vector2(200,850),"UNCHANGED_DOCKS_TAIL_PUBLIC_NEAR_COORDINATE"): finish();return
	if not await _near(docks_b): finish();return
	_docks_native_zoom_and_tail()
	finish()

func finish() -> void:
	if done:return
	done=true
	for code: Key in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE]:
		if Input.is_physical_key_pressed(code):_key(code,false)
	var last: Dictionary=facts() if not pins.is_empty() else {}
	if not first.is_empty():need(var_to_bytes(first)==var_to_bytes(last),"SMALL_SOURCE_FIRST_FINAL_EXACT")
	if not input_sha.is_empty():need(FileAccess.get_sha256(INPUTS)==input_sha,"ROOT_SEALED_CONFIG_UNCHANGED")
	var result: Dictionary={"passed":errors.is_empty() and passed_legs.size()==2 and images==1,"checks":checks,"errors":errors,"normal_images":images,"input_events":inputs,"actual_true_legs":passed_legs.size(),"passed_legs":passed_legs,"checkpoint_suspended":suspended,"records":records,"source_first":first,"source_final":last,"inputs_sha256":input_sha,"root_only":true,"save_content_or_metadata_APIs":0,"inherited20_functional_directions":cfg.get("inherited20",{}),"scope":"ONLY_CHANGED_YAMEN_ARTISAN_TWO_LEGS_ONE_CIVIC_IMAGE_DOCKS_ZOOM_RECEIPT_TAIL"}
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(result,"\t")+"\n")
	print("CITYNAV02A_RESIDUAL04 ",JSON.stringify({"passed":result.passed,"checks":checks,"errors":errors,"images":images,"inputs":inputs,"true_legs":passed_legs.size(),"result":directory+"/result.json"}))
	quit(0 if result.passed else 1)

