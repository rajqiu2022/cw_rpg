extends SceneTree
## Root-only finite real input. No SaveManager/GameState/user-file API, no actor
## writes, no synthetic begin_conversation and no World/old-success rerun.
const HOME := "res://build/city_navigation_20261101d_qa01/"
const INPUTS := HOME + "finite_inputs_ROOT_READY.json"
const HOST := "res://build/city_navigation_20261101d_candidate01/city_navigation_runtime.gd"
const PAIRS := "res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd"
const MANIFEST := "res://build/city_navigation_20261101d_candidate01/source_pins_READY.json"
const MINI := "res://build/city_navigation_minimap_20261101d_candidate01/mini_marker_overlay.gd"
const REG_DISPATCH := "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd"
const REG_ENTRY := "res://build/luoyang_regions_20261027d_source01/region_entry.gd"
const ART := "res://build/luoyang_temple_adult_20261101d_art01/live_art_view.gd"
const ADULT_IDS := ["spar_luoyang_blademaster","luoyang_paper_scholar","spar_luoyang_examiner","feng_yanqiu_ch4","luoyang_poetry_host","luoyang_armorer"]
var cfg: Dictionary = {}
var pins: Dictionary = {}
var first: Dictionary = {}
var records: Array[Dictionary] = []
var errors: Array[String] = []
var checks := 0
var inputs := 0
var done := false
var suspended := false
var directory := ""
var field: Node
var host: Node
var router: Node
var pair_data: GDScript
var images := 0

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children(): _early(node)
	run.call_deferred(); watch.call_deferred()
func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = node.call("is_checkpoint_saves_suspended") == true
func watch() -> void:
	await create_timer(240.0,true,false,true).timeout
	if not done: need(false,"FINITE_240S_WATCHDOG"); finish()
func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: errors.append(label); printerr("CITYNAV31D_FAIL ",label)
	return ok
func facts() -> Dictionary:
	var result: Dictionary = {}
	for path: String in pins:
		# Root's exact source-only pin list is constrained to the game workspace.
		var file := FileAccess.open(path,FileAccess.READ)
		result[path] = {"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file != null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result
func _physical(candidate: Node) -> String:
	var scene: SceneScript = candidate.get("_current_scene") as SceneScript if is_instance_valid(candidate) else null
	return String(scene.scene_id) if scene != null else ""
func _busy() -> bool:
	var loader: Node = root.get_node("LoadingManager")
	return loader.get("_transition_active") == true or loader.get("_external_active") == true
func _wait_field(previous: int, physical: String) -> bool:
	var limit := Time.get_ticks_msec() + 30000
	while not done and Time.get_ticks_msec() < limit:
		await process_frame
		var candidate: Node = current_scene
		if not is_instance_valid(candidate) or candidate.get_instance_id() == previous or _physical(candidate) != physical or not candidate.has_method("get_field_loading_state"): continue
		var loading: Dictionary = candidate.call("get_field_loading_state")
		if loading.get("failed") == true: return need(false,"ACTUAL_FIELD_LOAD_FAILED:"+physical)
		var player: Node = candidate.get("_player")
		if loading.get("complete") != true or candidate.get("_scene_rebuilding") == true or _busy() or not is_instance_valid(player) or player.get("can_move") != true: continue
		field = candidate
		await physics_frame; await RenderingServer.frame_post_draw
		var until := Time.get_ticks_msec() + 4000
		while Time.get_ticks_msec() < until:
			var state: Dictionary = host.call("get_debug_state")
			if not String(state.get("last_error","")).is_empty(): records.append({"actual_host_error":state}); return need(false,"HOST_NEW_RUNTIME_ERROR:"+String(state.last_error))
			if state.get("ready") == true and state.get("metadata",{}).get("scene_id") == physical:
				var mini: Node = field.get("_world_travel_minimap") as Node
				var cache: Node = mini.get("_visual_cache") as Node if is_instance_valid(mini) else null
				if cache != null and cache.get("capture_ready") != true: await process_frame; continue
				await physics_frame; await RenderingServer.frame_post_draw
				return true
			await process_frame
		return need(false,"ACTUAL_HOST_ATTACHED_CURRENT_FIELD:"+physical)
	return need(false,"ACTUAL_FIELD_FINITE_READY:"+physical)
func _near(endpoint: Dictionary, requested: Vector2) -> bool:
	var previous: int = current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
	var entry: GDScript = load(REG_ENTRY) as GDScript
	if entry.call("requested",StringName(endpoint.logical_id)) == true:
		var dispatch: GDScript = load(REG_DISPATCH) as GDScript
		var extension: Dictionary = {"region_id":endpoint.scene_id,"revision":int(cfg.region_revision),"logical_id":endpoint.logical_id,"global_foot_px":[requested.x,requested.y]}
		if not need(dispatch.call("start",router,StringName(endpoint.logical_id),Vector2(.5,.5),"",3,extension) == true,"PUBLIC_REGION_NEAR_SETUP:"+endpoint.logical_id): return false
	else:
		# Original public city near setup requires its genuine local context first.
		if String(router.call("get_current_field_id")) != endpoint.logical_id:
			if not need(router.call("go_field_smart",StringName(endpoint.logical_id),null,"",-1,-1) == true,"PUBLIC_LEGACY_CONTEXT:"+endpoint.logical_id): return false
			if not await _wait_field(previous,endpoint.scene_id): return false
			previous = field.get_instance_id()
		var world_size: Vector2 = field.get("_world_size") if _physical(field) == endpoint.scene_id else Vector2(cfg.legacy_sizes[endpoint.scene_id][0],cfg.legacy_sizes[endpoint.scene_id][1])
		if not need(router.call("go_field_smart",StringName(endpoint.logical_id),requested/world_size,"",-1,3) == true,"PUBLIC_V3_NEAR_SETUP:"+endpoint.logical_id): return false
	if not await _wait_field(previous,endpoint.scene_id): return false
	var player: Node2D = field.get("_player") as Node2D
	records.append({"public_near_setup_not_continuous_travel":true,"physical":endpoint.scene_id,"logical":endpoint.logical_id,"requested_foot":requested,"actual_foot":player.position,"private_router_or_player_writes":false})
	return need(player.position.distance_to(requested) < .03,"EXACT_PUBLIC_NEAR_FOOT:"+endpoint.logical_id)
func _pair(id: String) -> Dictionary:
	var found: Array = pair_data.call("relations").filter(func(row: Dictionary) -> bool: return row.get("pair_id") == id)
	return found[0] if found.size() == 1 else {}
func _endpoint(pair: Dictionary, side: String) -> Dictionary:
	var result: Dictionary = pair[side].duplicate(true)
	result["pair_id"] = pair.pair_id; result["side"] = side
	result["target"] = pair["b" if side == "a" else "a"].duplicate(true)
	return result
func _zone(endpoint: Dictionary) -> ExitZone:
	var found: ExitZone
	for zone: Node in get_nodes_in_group("exit_zone"):
		if not zone is ExitZone or not zone.has_meta("citynav_endpoint"): continue
		var source: Dictionary = zone.get_meta("citynav_endpoint")
		if source.get("pair_id") != endpoint.pair_id or source.get("side") != endpoint.side: continue
		if found != null: return null
		found = zone as ExitZone
	return found
func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = pressed
	Input.parse_input_event(event); Input.flush_buffered_events(); inputs += 1
func _tap_space() -> void:
	await physics_frame; _key(KEY_SPACE,true)
	await physics_frame; _key(KEY_SPACE,false)
	await process_frame
func _walk_to_zone(endpoint: Dictionary, zone: ExitZone) -> bool:
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	var direction: Vector2 = endpoint.outward
	var code: Key = KEY_S if direction.y > 0 else (KEY_W if direction.y < 0 else (KEY_D if direction.x > 0 else KEY_A))
	var start := player.position
	_key(code,true)
	var ticks := 0
	while ticks < 40 and is_instance_valid(zone) and not zone.call("_can_enter"):
		await physics_frame; ticks += 1
	_key(code,false); await physics_frame
	var constraint: Callable = player.get("movement_constraint")
	records.append({"real_short_walk":true,"pair":endpoint.pair_id,"side":endpoint.side,"start":start,"end":player.position,"velocity":player.velocity,"ticks":ticks,"can_move":player.can_move,"mouth":endpoint.mouth,"activation_size":endpoint.activation_size,"can_enter":zone.call("_can_enter") if is_instance_valid(zone) else false,"constraint_valid":constraint.is_valid()})
	return need(ticks > 0 and player.position.distance_to(start) > 1 and is_instance_valid(zone) and zone.call("_can_enter") == true,"TRUE_SHORT_WALK_INTO_ACTUAL_MOUTH:"+endpoint.pair_id+":"+endpoint.side)
func _actual_coherence(endpoint: Dictionary, zone: ExitZone) -> bool:
	var metadata: Dictionary = zone.get_meta("citynav_endpoint",{})
	var source: Dictionary = host.call("get_debug_state").get("metadata",{})
	var rows: Array = source.get("portals",[]).filter(func(row: Dictionary) -> bool: return row.get("pair_id") == endpoint.pair_id and row.get("source_portal") == endpoint.source_portal)
	var visual: Sprite2D = zone.get_node_or_null("MarkerVisual") as Sprite2D
	var prompt: Label = zone.get_node_or_null("Prompt") as Label
	var collision: CollisionShape2D = zone.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var ok: bool = zone.position.distance_to(endpoint.mouth) < .01 and zone.target_scene_id == endpoint.target.logical_id and metadata.get("mouth") == endpoint.mouth and rows.size() == 1 and rows[0].get("foot") == endpoint.mouth and rows[0].get("kind") == "area_exit"
	ok = ok and visual != null and prompt != null and prompt.text == zone.exit_label and zone.exit_label.contains(String(_pair(endpoint.pair_id).label)) and collision != null and collision.shape is RectangleShape2D and (collision.shape as RectangleShape2D).size == endpoint.activation_size
	records.append({"actual_zone_marker_label_cohere":ok,"pair":endpoint.pair_id,"side":endpoint.side,"zone":String(zone.get_path()),"zone_position":zone.position,"label":zone.exit_label,"prompt":prompt.text if prompt != null else "","target":zone.target_scene_id,"marker_rotation":visual.rotation if visual != null else 0,"mini_rows":rows})
	return need(ok,"ACTUAL_TRIGGER_MARKER_MINI_TARGET_COHERENT:"+endpoint.pair_id+":"+endpoint.side)
func _cross(endpoint: Dictionary) -> bool:
	var zone: ExitZone = _zone(endpoint)
	if not need(zone != null,"UNIQUE_ACTUAL_PAIR_EXITZONE:"+endpoint.pair_id+":"+endpoint.side): return false
	if not _actual_coherence(endpoint,zone) or not await _walk_to_zone(endpoint,zone): return false
	var previous: int = field.get_instance_id()
	var history_before: int = host.call("get_debug_state").get("route_history",[]).size()
	await _tap_space()
	if not await _wait_field(previous,endpoint.target.scene_id): return false
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	var history: Array = host.call("get_debug_state").get("route_history",[])
	records.append({"true_space_crossing":true,"pair":endpoint.pair_id,"side":endpoint.side,"actual_physical":_physical(field),"actual_logical":router.call("get_current_field_id"),"actual_foot":player.position,"expected_arrival":endpoint.target.arrival,"route_history_before":history_before,"route_history_after":history.size(),"route_history":history})
	return need(String(router.call("get_current_field_id")) == endpoint.target.logical_id and player.position.distance_to(endpoint.target.arrival) < .03 and player.can_move and history.size() > history_before,"TRUE_SPACE_EXACT_PAIRED_ARRIVAL:"+endpoint.pair_id+":"+endpoint.side)
func _mini_check() -> bool:
	var reference: WeakRef = field.get_meta("city_navigation_20261101d_minimap") as WeakRef
	var layer: Node = reference.get_ref() as Node if reference != null else null
	if not need(is_instance_valid(layer),"ACTUAL_NEW_MINI_OVERLAY"): return false
	var state: Dictionary = layer.call("get_debug_state")
	var kinds: Dictionary = {}; var roles: Dictionary = {}
	for row: Dictionary in state.get("markers",[]): kinds[String(row.kind)] = true; roles[String(row.get("service",""))] = true
	var mini: Control = field.get("_world_travel_minimap") as Control
	var portrait: Control = mini.get("_portrait_marker") as Control
	var textures: Dictionary = layer.get("_textures")
	var hammer: AtlasTexture = textures.get("smith") as AtlasTexture
	var real_hammer: bool = hammer != null and hammer.atlas.resource_path == "res://art/props/blacksmith_hammer.png" and hammer.atlas.get_size() == Vector2(128,128) and hammer.region == Rect2(28,13,100,100)
	records.append({"civic_actual_mini":state,"actual_hammer_atlas":real_hammer,"portrait_unchanged_visible":portrait != null and portrait.visible,"original_mini":mini.call("get_debug_state")})
	return need(kinds.has("area_exit") and kinds.has("building_door") and roles.has("medicine") and roles.has("smith") and roles.has("inn") and real_hammer and portrait != null and portrait.visible and mini.mouse_filter == Control.MOUSE_FILTER_IGNORE and layer.get("mouse_filter") == Control.MOUSE_FILTER_IGNORE,"VISIBLE_EXIT_DOOR_MEDICINE_HAMMER_INN_REAL_TEXTURE_PORTRAIT_PASSTHROUGH")
func _adult_body_business(npc: NPCNode) -> Dictionary:
	var body: StaticBody2D = npc.get("_body_collider") as StaticBody2D
	var shape: CollisionShape2D = body.get_child(0) as CollisionShape2D if body != null and body.get_child_count() == 1 else null
	if shape == null or not shape.shape is RectangleShape2D: return {}
	# Independently read the actual nodes, then compare the original pre-art
	# snapshots retained by the display owner. No temporary QA mutation.
	return {"node":npc.get_instance_id(),"position":npc.position,"transform":npc.transform,"body":body.get_instance_id(),"body_transform":body.transform,"shape":shape.get_instance_id(),"shape_transform":shape.transform,"shape_size":(shape.shape as RectangleShape2D).size,"layer":body.collision_layer,"mask":body.collision_mask,"dialog_id":npc.dialog_id,"action":npc.interaction_action,"variants":npc.dialog_variants.duplicate(true),"portrait":npc.portrait_path,"source":npc.sprite_path,"movement_mode":npc.movement_mode,"processing":npc.is_processing()}
func _civic_adults_near(endpoint: Dictionary) -> bool:
	var region: Dictionary = field.get("_region")
	var authored: Array = region.get("npcs",[]).filter(func(row: Dictionary) -> bool: return row.get("data",{}).get("npc_id") == "spar_luoyang_blademaster")
	if not need(authored.size() == 1 and authored[0].get("foot") is Vector2,"EXACT_COMPILED_BLADEMASTER_FOOT_NOT_NAME_GUESS"): return false
	var npc_foot: Vector2 = authored[0].foot
	var near_foot: Vector2 = npc_foot + Vector2(0,120)
	var geo: GDScript = load("res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd") as GDScript
	if not need(geo.call("safe_static",String(endpoint.scene_id),near_foot) == true,"ORIGINAL_FULL_FOOT_SAFE_120PX_SOUTH_OF_BLADEMASTER"): return false
	if not await _near(endpoint,near_foot): return false
	await process_frame; await RenderingServer.frame_post_draw
	var art: Node = field.get_node_or_null("Quality20261101dArtView")
	if not need(art != null and art.get_script().resource_path == ART,"ACTUAL_CIVIC_ADULT_ART_OWNER"): return false
	var originals: Dictionary = art.get("_actor_before")
	var actors: Dictionary = field.get("_region_actors")
	var measured: Array[Dictionary] = []
	records.append({"civic_six_adult_current_residents_measured":measured,"compiled_blademaster_foot":npc_foot,"public_safe_south120_near":near_foot,"one_normal_image_replaces_old_civic_service_image":true,"no_dialogue_or_actor_writes":true})
	var blademaster_visible := false
	for id: String in ADULT_IDS:
		var key: String = "ch4_s3_luoyang_market/" + id
		var npc: NPCNode = actors.get(key,{}).get("node") as NPCNode
		if not is_instance_valid(npc): measured.append({"id":id,"resident":false,"not_fabricated":"original flags or absent actor slot"}); continue
		if not need(npc.sprite != null and npc.sprite.texture != null,"RESIDENT_ADULT_REAL_SPRITE:"+id): return false
		var sprite: Sprite2D = npc.sprite
		var image: Image = sprite.texture.get_image()
		if not need(image != null,"RESIDENT_ADULT_REAL_GPU_IMAGE:"+id): return false
		var frame_size := Vector2i(floori(float(image.get_width())/maxi(1,sprite.hframes)),floori(float(image.get_height())/maxi(1,sprite.vframes)))
		var frame := Rect2i(sprite.frame_coords * frame_size,frame_size)
		var current_core: Rect2i = image.get_region(frame).get_used_rect()
		var visible_height: float = float(current_core.size.y) * absf(sprite.scale.y)
		var local_core := Rect2(sprite.get_rect().position+Vector2(current_core.position),Vector2(current_core.size))
		var transform: Transform2D = sprite.get_global_transform_with_canvas()
		var screen := Rect2(transform * local_core.position,Vector2.ZERO)
		for corner: Vector2 in [local_core.position,Vector2(local_core.end.x,local_core.position.y),local_core.end,Vector2(local_core.position.x,local_core.end.y)]: screen = screen.expand(transform * corner)
		var on_screen: bool = sprite.is_visible_in_tree() and Rect2(Vector2.ZERO,root.get_viewport().get_visible_rect().size).encloses(screen)
		var after: Dictionary = _adult_body_business(npc)
		var original: Dictionary = originals.get(npc.get_instance_id(),{})
		var intact: bool = not original.is_empty() and var_to_bytes(original) == var_to_bytes(after)
		measured.append({"id":id,"resident":true,"current_texture":sprite.texture.resource_path,"current_frame":sprite.frame,"hframes":sprite.hframes,"vframes":sprite.vframes,"actual_frame_rect":frame,"current_alpha_core":current_core,"actual_sprite_scale":sprite.scale,"actual_visible_core_height":visible_height,"screen_core_rect":screen,"visible_in_tree":sprite.is_visible_in_tree(),"whole_core_on_screen":on_screen,"original_body_action_unchanged":intact,"original_body_business":original,"actual_body_business":after})
		if not need(current_core.size.y > 0 and intact,"RESIDENT_ADULT_BODY_ACTION_ORIGINAL_IDENTITY:"+id): return false
		if id == "spar_luoyang_blademaster":
			blademaster_visible = on_screen and absf(visible_height-132.0) <= .1
			if not need(blademaster_visible,"ACTUAL_VISIBLE_CURRENT_FRAME_BLADEMASTER_132PX_PLUS_MINUS_POINT1"): return false
	return need(blademaster_visible,"HERO_AND_BLADEMASTER_NORMAL_NEAR_FRAME_NOT_OFFSCREEN_HEIGHT_ONLY")
func _capture(label: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	if not need(image != null and image.get_size() == Vector2i(1920,1080) and images < 3,"THREE_NORMAL_1920_IMAGES_MAX_NO_CAMERA_WRITES:"+label): return false
	var path: String = directory + "/" + label + ".png"
	if not need(image.save_png(path) == OK,"NORMAL_IMAGE:"+label): return false
	images += 1; records.append({"image":path,"sha256":FileAccess.get_sha256(path),"normal_camera":true,"player_foot":field.get("_player").position})
	return true
func _hall_check() -> bool:
	var art: Node = field.get_node_or_null("Quality20261101dArtView")
	var mini: Node = field.get("_world_travel_minimap") as Node
	if not need(art != null and art.get_script().resource_path == ART and mini != null,"ACTUAL_TEMPLE_NEW_ART_OWNER"): return false
	var receipt: Dictionary = art.call("receipt")
	var original: Dictionary = field.get("_region")
	var copy: Dictionary = mini.get("_compiled")
	var helper: GDScript = load(ART) as GDScript
	if not need(receipt.get("compiled_unchanged") == true and String(receipt.get("error","")) == "" and var_to_bytes(copy) == var_to_bytes(helper.call("mini_compiled_copy",original)),"ORIGINAL_BIN_UNCHANGED_ONLY_MINI_PRIVATE_COPY_FILTER"): return false
	var cache: Node = mini.get("_visual_cache") as Node
	var canvas: Node = cache.get("_canvas") as Node
	var hall_copies := 0
	for leaf: Node in canvas.get_children():
		if leaf is Polygon2D and leaf.texture != null and leaf.texture.resource_path == "res://art/modules/city_navigation_20261101d/east_scripture_hall_v1.png": hall_copies += 1
		if leaf.has_meta("source_compiled_key") and leaf.get_meta("source_compiled_key") == "ch4_s4_ancient_temple/finish_i_temple_east_sutra_house": return need(false,"OLD_WING_NOT_RECLONED_IN_MINI")
	if not need(hall_copies == 1 and cache.get("capture_ready") == true,"ACTUAL_MINI_ONE_COMPLETE_NEW_HALL_NO_OLD_WING_DUPLICATE"): return false
	var quad: Polygon2D = field.get("_visual_layer").get_node_or_null("Quality20261101dEastScriptureHall") as Polygon2D
	if not need(quad != null and quad.texture != null and absf(quad.scale.x-quad.scale.y) < .000001,"ACTUAL_NEW_HALL_NATIVE_UNIFORM_QUAD"): return false
	# Original image review marked RAW door x690..846/y526..754; runtime64px
	# transparent padding gives this source rect. It is a manual native landmark,
	# not an alpha-inferred or physics doorway, and remains labelled as such.
	var door_source := Rect2(754,590,156,228)
	var door_height: float = door_source.size.y * absf(quad.scale.y)
	var hall_image: Image = quad.texture.get_image()
	if not need(hall_image != null,"ACTUAL_HALL_GPU_ALPHA_IMAGE"): return false
	var door_alpha_samples: Array[Dictionary] = []
	for point: Vector2i in [Vector2i(832,590),Vector2i(832,704),Vector2i(832,817)]: door_alpha_samples.append({"source_pixel":point,"alpha":hall_image.get_pixelv(point).a})
	if not need(door_height >= 140.0 and absf(door_height-144.49633088725818) < .01,"ACTUAL_QUAD_MANUAL_NATIVE_DOOR_ESTIMATE_AT_LEAST140PX"): return false
	records.append({"hall_native_door_landmark_estimate_not_physics_claim":true,"manual_runtime_source_door_rect":door_source,"actual_uniform_quad_scale":quad.scale,"actual_door_world_height":door_height,"current_gpu_alpha_used_rect":hall_image.get_used_rect(),"current_door_alpha_samples":door_alpha_samples,"normal_zoom_unchanged":true})
	var bodies: Node = field.get("_collision_layer").get_node_or_null("Quality20261101dTempleOverlayBodies")
	var rectangles: Array = helper.call("overlay_rects")
	if not need(bodies != null and bodies.get_child_count() == 3 and rectangles.size() == 3,"EXACT_THREE_ADDITIVE_HALL_BODIES"): return false
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	var shape: CollisionShape2D = player.get_node("CollisionShape2D") as CollisionShape2D
	var world: Node2D = field.get("world_container") as Node2D
	var probes: Array[Dictionary] = []
	for index: int in range(3):
		var body: StaticBody2D = bodies.get_child(index) as StaticBody2D
		var added: CollisionShape2D = body.get_child(0) as CollisionShape2D
		var rectangle: Rect2 = rectangles[index]
		if not need(added.shape is RectangleShape2D and (added.shape as RectangleShape2D).size == rectangle.size and added.position == rectangle.get_center() and (body.collision_layer & player.collision_mask) != 0,"ACTUAL_HALL_BODY_RECT_AND_PLAYER_MASK:"+str(index)): return false
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape.shape; query.transform = shape.global_transform
		var transform: Transform2D = query.transform; transform.origin = world.to_global(rectangle.get_center()); query.transform = transform
		query.collision_mask = player.collision_mask; query.collide_with_bodies = true; query.collide_with_areas = false
		var excluded: Array[RID] = [player.get_rid()]; query.exclude = excluded
		var hit_expected := false
		for hit: Dictionary in player.get_world_2d().direct_space_state.intersect_shape(query,64):
			if hit.get("collider") == body: hit_expected = true
		probes.append({"rectangle":rectangle,"center":rectangle.get_center(),"actual_own_body_hit":hit_expected,"player_not_moved":true})
		if not need(hit_expected,"READONLY_FULL_FOOT_ACTUAL_NEW_BODY_QUERY:"+str(index)): return false
	records.append({"actual_hall_receipt":receipt,"mini_new_hall_copies":hall_copies,"additive_physics_readonly_probes":probes,"no_extra_travel_or_image":true})
	return true
func run() -> void:
	directory = HOME + "actual/" + str(OS.get_process_id()); DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND_NO_USERSTATE_READ_WRITE"): finish(); return
	cfg = JSON.parse_string(FileAccess.get_file_as_string(INPUTS)) as Dictionary
	if not need(cfg.get("schema") == "CITY_NAVIGATION_20261101D_FINITE_QA_V1" and cfg.get("ready") == true,"ROOT_EXPLICIT_FINITE_QA_FREEZE"): finish(); return
	pins = cfg.get("source_pins",{}).duplicate(true)
	for path: String in pins:
		if not need(path.begins_with("res://") and not ".." in path and String(pins[path]).length() == 64,"SOURCE_ONLY_PIN_PATH_NO_USER_FILES:"+path): finish(); return
	if not need(pins.has(HOME+"finite_ROOT_ONLY.gd") and pins.has(MANIFEST) and pins.has(PAIRS) and pins.has(HOST) and pins.has(MINI),"ROOT_PINNED_QA_HOST_PAIR_MINI_AND_MANIFEST"): finish(); return
	first = facts()
	for path: String in pins:
		if not need(first[path].sha256 == pins[path],"SOURCE_FIRST:"+path): finish(); return
	router = root.get_node("SceneRouter"); host = root.get_node_or_null("CityNavigationRuntime")
	if not need(host != null and host.get_script().resource_path == HOST and ProjectSettings.get_setting("autoload/CityNavigationRuntime","") == "*"+HOST,"ACTUAL_NEW_INDEPENDENT_AUTOLOAD"): finish(); return
	pair_data = load(PAIRS) as GDScript
	var host_until := Time.get_ticks_msec()+3000
	while Time.get_ticks_msec() < host_until and host.call("get_debug_state").get("ready") != true: await process_frame
	if not _static_pairs(): finish(); return
	records.append({"inherited_11c_original_world_gate_entry_not_rerun":true,"old_collector_wall_gait_dialogue_not_repeated":true,"save_metadata_checked_only_by_root_guard_before_and_after":true})
	var previous: int = current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
	if not need(router.call("go_field_smart",&"ch4_s0_luoyang_gate",null,"",-1,-1) == true,"PUBLIC_DIRECT_GATE_BOOTSTRAP_NOT_WORLD"): finish(); return
	if not await _wait_field(previous,"ch4_s0_luoyang_gate"): finish(); return
	for id: String in cfg.real_pair_ids:
		var pair: Dictionary = _pair(id)
		if not need(not pair.is_empty(),"EXACT_FINITE_PAIR_ID:"+id): finish(); return
		var a: Dictionary = _endpoint(pair,"a"); var b: Dictionary = _endpoint(pair,"b")
		if not await _near(a,a.arrival) or not await _cross(a): finish(); return
		if id == "docks_temple" and not await _capture("temple_south_roadmouth_minimap_normal"): finish(); return
		if not await _cross(b): finish(); return
		if id == "market_artisan":
			if not await _civic_adults_near(a) or not _mini_check() or not await _capture("civic_blademaster_adult_and_services_minimap_normal"): finish(); return
	var temple: Dictionary = _endpoint(_pair("temple_riverside"),"a")
	var hall_foot := Vector2(cfg.temple_hall_foot[0],cfg.temple_hall_foot[1])
	if not await _near(temple,hall_foot) or not _hall_check() or not await _capture("temple_scripture_hall_adult_scale_normal"): finish(); return
	finish()
func _static_pairs() -> bool:
	var rows: Array = pair_data.call("relations")
	var seen: Dictionary = {}
	if not need(rows.size() == 11 and cfg.real_pair_ids == ["market_artisan","market_temple","docks_temple","temple_riverside"],"EXACT11_STATIC_FOUR_REAL_PAIRS_ONLY"): return false
	for pair: Dictionary in rows:
		if not need(not seen.has(pair.pair_id),"UNIQUE_PAIR:"+pair.pair_id): return false
		seen[pair.pair_id] = true
		for side: String in ["a","b"]:
			var endpoint: Dictionary = pair[side]
			var contact := Rect2(endpoint.mouth-endpoint.activation_size*.5,endpoint.activation_size)
			if not need(endpoint.mouth.is_finite() and endpoint.arrival.is_finite() and endpoint.outward.length() == 1.0 and not contact.has_point(endpoint.arrival),"FINITE_DISTINCT_ARRIVAL_OUTSIDE_MANUAL_TRIGGER:"+pair.pair_id+":"+side): return false
	# Existing host read-only audit traverses original immutable Region bins and
	# actual imported legacy NAV with the full 34x24 foot and approach sweep.
	# It is explicitly a static result, separate from the eight real crossings.
	if not need(host.has_method("audit_relations"),"ACTUAL_READONLY_ALL22_GEOMETRY_API"): return false
	var report: Dictionary = host.call("audit_relations")
	if not need(report.get("ok") == true and report.get("pair_count") == 11 and report.get("end_count") == 22 and report.get("original_geometry_mutations") == 0,"ORIGINAL_GEOMETRY_ALL22_STATIC_ROUTE_SAFE_NO_TRAVEL"): return false
	for row: Dictionary in report.get("rows",[]):
		var pair: Dictionary = _pair(String(row.pair_id))
		var endpoint: Dictionary = pair[String(row.side)]
		if not need(row.get("full_body_route_safe") == true and row.get("mouth") == endpoint.mouth and row.get("arrival") == endpoint.arrival and row.get("source_portal") == endpoint.source_portal,"STATIC_AUDIT_EXACT_CURRENT_DATA_ENDPOINT:"+String(row.pair_id)+":"+String(row.side)): return false
	records.append({"static_only_no_travel":report,"pair_source_sha256":pins[PAIRS]})
	return true
func finish() -> void:
	if done: return
	done = true
	for code: Key in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE]:
		if Input.is_physical_key_pressed(code): _key(code,false)
	var final_sources: Dictionary = facts() if not pins.is_empty() else {}
	if not first.is_empty(): need(var_to_bytes(first) == var_to_bytes(final_sources),"SOURCE_FIRST_FINAL_EXACT_NO_OLD_WRITES")
	records.append({"scope":"FOUR_PAIRS_EIGHT_REAL_SPACE_CROSSINGS_PLUS_STATIC_OTHERS_THREE_NORMAL_IMAGES","no_world_retest":true,"no_battle_crafting_or_gait_retest":true,"save_apis":0,"userstate_reads_writes":0,"player_router_camera_private_writes":0})
	var result: Dictionary = {"passed":errors.is_empty(),"checks":checks,"errors":errors,"input_events":inputs,"normal_images":images,"records":records,"source_first":first,"source_final":final_sources,"checkpoint_suspended":suspended,"root_only":true}
	var file := FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result,"\t")+"\n")
	print("CITYNAV31D_FINITE ",JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"inputs":inputs,"images":images,"result":directory+"/result.json"}))
	quit(0 if errors.is_empty() else 1)
