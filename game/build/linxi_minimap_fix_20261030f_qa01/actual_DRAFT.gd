extends SceneTree
## Root-only new Linxi3002 domains. No actor/camera writes or old room matrix.
const FIXTURE := "res://build/linxi_minimap_fix_20261030f_qa01/actual_READY.json"
const OUT := "res://build/linxi_minimap_fix_20261030f_qa01/actual/"
const ID: StringName=&"linxi_tutorial"
const SIZE := Vector2(2900,2400)
var spec: Dictionary={}
var checks: int=0
var errors: Array[String]=[]
var records: Array=[]
var input_ticks: int=0
var finished: bool=false
var router: Node
var game: Node
var dialog: Node
var first_sources: Dictionary={}
var first_saves: Dictionary={}
var first_state: Dictionary={}
var portrait_before: Dictionary={}
func _initialize() -> void:
	_watchdog.call_deferred();_run.call_deferred()
func _watchdog() -> void:
	await create_timer(90.0,true,false,true).timeout
	if not finished:need(false,"INDEPENDENT_90S_WATCHDOG");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("LINXI30F_FAIL ",label)
	return ok
func point(raw: Array) -> Vector2:return Vector2(float(raw[0]),float(raw[1]))
func facts(paths: Array) -> Dictionary:
	var out: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(path):out[path]={"exists":false};continue
		var file:=FileAccess.open(path,FileAccess.READ)
		out[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return out
func state() -> Dictionary:
	var save: Node=root.get_node("SaveManager");var hero: Resource=game.get("player") as Resource;var party: Array=[]
	for member: Resource in game.get("party"):party.append({"instance":str(member.get_instance_id()),"stats":save.call("_serialize_stats",member)})
	return {"hero_instance":str(hero.get_instance_id()),"hero":save.call("_serialize_stats",hero),"portrait_path":hero.get("portrait_path"),"party":party,"gold":game.get("gold"),"flags":game.get("flags").duplicate(true),"quests":root.get_node("QuestManager").call("to_dict"),"inventory":root.get_node("Inventory").call("to_dict"),"bounties":root.get_node("BountyManager").call("to_dict")}.duplicate(true)
func _run() -> void:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(raw is Dictionary and raw.get("ready")==true,"EXACT_ROOT30F_FROZEN_FIXTURE"):finish();return
	spec=raw;first_sources=facts(spec.fixed_sources.keys());first_saves=facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:
		if not need(first_sources[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path):finish();return
	router=root.get_node("SceneRouter");game=root.get_node("GameState");dialog=root.get_node("DialogPlayer")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED"):finish();return
	if not admission():finish();return
	var before_bootstrap: Dictionary=state()
	# locations.start preserves requested current-version feet only for the SAME ID.
	# The default root ID is World, so use one public native bootstrap first.
	if not need(router.call("go_field_smart",ID,null,"",-1,-1)==true,"PUBLIC_DEFAULT_NATIVE_BOOTSTRAP_NOT_WORLD_ENTRY_TEST"):finish();return
	var field: Node=await wait_native()
	if field==null:finish();return
	first_state=state()
	records.append({"phase":"public_default_bootstrap_then_same_ID_near_setups","before":before_bootstrap,"after":first_state,"old_entry_prefix_not_retested":true,"user_save_loaded":false})
	var live_portrait: String=String((game.get("player") as Resource).get("portrait_path"))
	if not need(not live_portrait.is_empty() and ResourceLoader.exists(live_portrait),"ACTUAL_LIVE_HERO_PORTRAIT_EXISTS_NOT_FAKE_OR_NPC"):finish();return
	portrait_before=facts([live_portrait])
	if not verify_business_schema(field):finish();return
	for item: Dictionary in spec.side_negatives:
		if not await side_negative(item):finish();return
	if not await north_grass():finish();return
	if not await bedroom_stair_and_portrait():finish();return
	if not need(state()==first_state,"SAME_REAL_HERO_PARTY_STATS_QUESTS_INVENTORY_AFTER_NEW_DOMAINS"):finish();return
	finish()
func admission() -> bool:
	var authority: Variant=load("res://scripts/city/luoyang_execution_authority_20261022ap.gd")
	var culture: Variant=load("res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd")
	var path: String="res://scripts/autoload/scene_router.gd"
	var old: String="d25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc"
	if not need(authority.call("approved",path,old)==true,"NEW_SOURCE_CLOSURE_ORIGINAL_ROUTER_PIN_ACCEPTED"):return false
	if not need(authority.call("approved",path,"0000000000000000000000000000000000000000000000000000000000000000")==false,"UNKNOWN_SHA_REJECTED"):return false
	var value: Dictionary=culture.call("readiness")
	return need(value.get("ok")==true,"ORIGINAL_CULTURE_SOURCE_READY_NO_OLD_CITY_INSTANCE")
func wait_native() -> Node:
	var started: int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-started<20000 and not finished:
		await process_frame
		var field: Node=current_scene
		if field==null or not field.has_method("get_field_loading_state"):continue
		var loading: Dictionary=field.call("get_field_loading_state")
		if String(loading.get("scene_id"))!=String(ID):continue
		if loading.get("failed")==true:need(false,"NATIVE_LOAD_FAILED");return null
		var manager: Node=root.get_node("LoadingManager")
		if loading.get("complete")!=true or manager.get("_transition_active")==true or manager.get("_external_active")==true:continue
		var native: Node=field.get("native_town") as Node
		if native==null or not is_instance_valid(native.get("actor")):continue
		if native.get("controls_enabled")!=true or dialog.call("is_playing")==true:continue
		await physics_frame;await RenderingServer.frame_post_draw
		return field
	need(false,"NATIVE20S_TIMEOUT_NO_PRIVATE_DIALOG_CLOSE_OR_FLAGS");return null
func near(foot: Vector2,label: String) -> Node:
	if not need(router.call("go_field_smart",ID,foot/SIZE,"",-1,3002)==true,"PUBLIC_SAME_ID_3002_NEAR_SETUP:"+label):return null
	var field: Node=await wait_native()
	if field==null:return null
	var native: Node=field.get("native_town") as Node;var actor: CharacterBody2D=native.get("actor") as CharacterBody2D
	if not need(actor.position.distance_to(foot)<=1 and String(native.scene_file_path)==String(spec.native_scene),"EXACT_NEW_SOURCE_AND_PUBLIC_FOOT:"+label):return null
	var nav: Dictionary=router.call("get_navigation_state")
	if not need(int(nav.get("local_layout_versions",{}).get(String(ID),0))==3002,"LINXI_ONLY_CURRENT_VERSION3002:"+label):return null
	records.append({"phase":"public_same_ID_near_setup","label":label,"foot":actor.position,"not_continuous_from_previous_case":true,"new_field_instance":str(field.get_instance_id())})
	return field
func clear_at(actor: CharacterBody2D,foot: Vector2,mask: int) -> bool:
	var collider: CollisionShape2D=actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collider==null or collider.shape==null or collider.disabled:return false
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=collider.shape
	query.transform=collider.global_transform;query.transform.origin+=foot-actor.global_position
	query.collision_mask=mask;query.exclude=[actor.get_rid()];query.collide_with_areas=false;query.collide_with_bodies=true;query.margin=0.0
	return actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
func actor_top_offset(actor: CharacterBody2D) -> float:
	var collider: CollisionShape2D=actor.get_node("CollisionShape2D") as CollisionShape2D
	var rect: Rect2=collider.shape.get_rect();var lowest: float=INF
	for corner: Vector2 in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:lowest=minf(lowest,(collider.global_transform*corner).y-actor.global_position.y)
	return lowest
func side_negative(item: Dictionary) -> bool:
	var start: Vector2=point(item.start);var field: Node=await near(start,String(item.label))
	if field==null:return false
	var native: Node=field.get("native_town") as Node;var actor: CharacterBody2D=native.get("actor") as CharacterBody2D;var terrain: Node=native.get("terrain") as Node
	var wall: Node2D=native.get_node_or_null(NodePath(item.wall_path)) as Node2D
	if not need(wall!=null,"FINAL_SAT_WALL_ACTUAL_NODE:"+String(item.label)):return false
	var wall_bottom: float=-INF
	for child: Node in wall.find_children("*","CollisionPolygon2D",true,false):
		var polygon: CollisionPolygon2D=child as CollisionPolygon2D
		for p: Vector2 in polygon.polygon:wall_bottom=maxf(wall_bottom,(polygon.global_transform*p).y)
	if not need(is_finite(wall_bottom),"REAL_WALL_POLYGON_NOT_GUESSED_OLD_FOOT"):return false
	var minimum_actor_y: float=wall_bottom-actor_top_offset(actor)
	var samples: Array=await held(KEY_W,int(item.ticks),native)
	var finish_foot: Vector2=actor.position
	if not need(finish_foot.y<start.y-5 and absf(finish_foot.x-start.x)<=1 and absf(finish_foot.y-minimum_actor_y)<=3,"REAL_VISIBLE_SIDE_WALL_STOPS_FULL_ACTOR:"+String(item.label)):return false
	if not need(int(terrain.get("actor_level"))==0 and clear_at(actor,actor.global_position,actor.collision_mask),"SIDE_WALL_NO_FLOOR_ESCAPE_OR_BODY_OVERLAP:"+String(item.label)):return false
	if not need(samples.size()>=6 and point(samples[-1].foot).distance_to(point(samples[-6].foot))<=.5,"LAST_SIX_TICKS_STATIONARY_AT_REAL_CONTACT"):return false
	await held(KEY_S,6,native)
	if not need(actor.position.y>finish_foot.y+20 and clear_at(actor,actor.global_position,actor.collision_mask),"CAN_WALK_AWAY_FROM_SIDE_CONTACT"):return false
	records.append({"phase":"side_negative","label":item.label,"wall_bottom_from_actual_polygon":wall_bottom,"actual_actor_top_offset":actor_top_offset(actor),"expected_minimum_actor_y":minimum_actor_y,"stopped_foot":finish_foot,"samples":samples})
	return true
func north_grass() -> bool:
	var field: Node=await near(point(spec.north.start),"new_north_tree_gap")
	if field==null:return false
	var native: Node=field.get("native_town") as Node;var actor: CharacterBody2D=native.get("actor") as CharacterBody2D;var terrain: Node=native.get("terrain") as Node
	if not need(int(terrain.get("actor_level"))==1,"NEW_NORTH_SAME_REAL_UPPER_FLOOR"):return false
	var up: Array=await held(KEY_W,int(spec.north.ticks),native)
	if not need(actor.position.y<240 and actor.position.y>195 and int(terrain.get("actor_level"))==1,"TRUE_W_CROSSES_OLD350_BOUNDARY_BETWEEN_TREE_ROOTS"):return false
	if not need(clear_at(actor,actor.global_position,actor.collision_mask),"NEW_NORTH_ACTUAL_BODY_CLEAR"):return false
	var down: Array=await held(KEY_S,int(spec.north.ticks),native)
	if not need(actor.position.distance_to(point(spec.north.start))<=12 and int(terrain.get("actor_level"))==1,"TRUE_S_RETURN_SAME_UPPER_GRASS"):return false
	records.append({"phase":"new_north_tree_gap_actual_WS","up":up,"down":down,"old_hidden_cliff_y":350,"not_full_garden_or_other_city_walk":true})
	return true
func bedroom_stair_and_portrait() -> bool:
	var field: Node=await near(point(spec.stair.start),"bedroom_real_stair_and_portrait")
	if field==null:return false
	var native: Node=field.get("native_town") as Node;var actor: CharacterBody2D=native.get("actor") as CharacterBody2D;var terrain: Node=native.get("terrain") as Node
	if not need(int(terrain.get("actor_level"))==0,"BEDROOM_REAL_LOW_ENTRY"):return false
	var before: Dictionary=await portrait_state(field)
	if before.is_empty():return false
	var actor_id: int=actor.get_instance_id();var field_id: int=field.get_instance_id()
	var up: Array=await held(KEY_W,int(spec.stair.up_ticks),native)
	if not need(int(terrain.get("actor_level"))==1 and absf(float(terrain.get("actor_height"))-60.0)<=.1 and actor.position.y>=945 and actor.position.y<=1010,"TRUE_W_BEDROOM_STAIR_REACHES60PX_UPPER_LEVEL"):return false
	if not need(clear_at(actor,actor.global_position,actor.collision_mask),"REAL_UPPER_STAIR_FOOT_BODY_CLEAR"):return false
	var above: Dictionary=await portrait_state(field)
	if above.is_empty():return false
	if not need(int(above.cache_render_requests)==int(before.cache_render_requests) and int(above.static_build_count)==int(before.static_build_count) and int(above.player_portrait_marker.portrait_loads)==int(before.player_portrait_marker.portrait_loads),"MOVEMENT_ONLY_MARKER_NO_CACHE_OR_PORTRAIT_RELOAD"):return false
	if not need((above.player_marker as Vector2).distance_to(before.player_marker)>=8,"REAL_HEAD_MARKER_FOLLOWS_REAL_STAIR_MOVEMENT"):return false
	if not need(int(native.get("view_mode"))==1 and not bool(native.get("show_details")) and (field.get("_world_camera") as Camera2D).zoom.distance_to(Vector2(.9,.9))<.001,"UNMODIFIED_NORMAL_CAMERA_AND_ADULT_SCALE"):return false
	if not await capture("bedroom_scale_wall_and_live_portrait_normal"):return false
	var down: Array=await held(KEY_S,int(spec.stair.down_ticks),native)
	if not need(int(terrain.get("actor_level"))==0 and absf(float(terrain.get("actor_height")))<=.1 and actor.position.y>=1265 and actor.position.y<=1335,"TRUE_S_SAME_STAIR_BACK_TO_LOW_ENTRY"):return false
	var transitions: Array=terrain.get("transitions")
	if not need(transitions.size()==2 and String(transitions[0].ramp)=="BedroomRise" and transitions[0].from==0 and transitions[0].to==1 and transitions[1].from==1 and transitions[1].to==0,"ONE_UP_ONE_DOWN_TRUE_TERRAIN_COMMIT"):return false
	if not need(actor.get_instance_id()==actor_id and field.get_instance_id()==field_id and state()==first_state,"SAME_REAL_ACTOR_FIELD_AND_STATE_DURING_STAIR_SEGMENT"):return false
	records.append({"phase":"bedroom_actual_WS","up":up,"down":down,"transitions":transitions,"portrait_before":before,"portrait_above":above})
	return true
func portrait_state(field: Node) -> Dictionary:
	var mini: Control=field.get("_world_travel_minimap") as Control
	if not need(mini!=null and mini.has_method("get_debug_state"),"ACTUAL_FIELD_LOCAL_MINIMAP_NOT_GUESSED_HUD_PATH"):return {}
	var started: int=Time.get_ticks_msec();var debug: Dictionary={}
	while Time.get_ticks_msec()-started<5000:
		debug=mini.call("get_debug_state")
		if debug.get("visual_cache_ready")==true:break
		await process_frame
	await RenderingServer.frame_post_draw;debug=mini.call("get_debug_state")
	var marker: Control=mini.get_node_or_null("PlayerPortraitMarker") as Control
	var portrait: Dictionary=debug.get("player_portrait_marker",{})
	var live_path: String=String((game.get("player") as Resource).get("portrait_path"))
	if not need(marker!=null and marker.is_visible_in_tree() and mini.is_visible_in_tree() and String(portrait.get("kind"))=="PLAYER_PORTRAIT","REAL_VISIBLE_PORTRAIT_CONTROL"):return {}
	if not need(String(portrait.get("requested_portrait_path"))==live_path and String(portrait.get("portrait_path"))==live_path and String(portrait.get("fallback_kind"))=="NONE","ACTUAL_LIVE_HERO_PORTRAIT_NOT_NPC_OR_FAKE_ARROW"):return {}
	var old_arrow: CanvasItem=mini.get("_marker") as CanvasItem
	if not need(debug.get("legacy_arrow_visible")==false and old_arrow!=null and not old_arrow.is_visible_in_tree(),"OLD_ARROW_KEEPS_POINT_BUT_IS_NOT_RENDERED"):return {}
	var rect: Rect2=portrait.get("screen_rect",Rect2());var size: Vector2=portrait.get("marker_size",Vector2.ZERO)
	if not need(rect.get_center().distance_to(debug.player_marker)<=.2 and size.x>=18 and size.x<=24 and absf(size.x-size.y)<.01 and marker.mouse_filter==Control.MOUSE_FILTER_IGNORE,"HEAD_EXACT_OLD_POINT_SMALL_AND_MOUSE_THROUGH"):return {}
	var texture: Texture2D=load(live_path) as Texture2D;var source_rect: Rect2=portrait.get("source_rect",Rect2())
	if not need(texture!=null and source_rect.has_area() and Rect2(Vector2.ZERO,texture.get_size()).encloses(source_rect),"RUNTIME_CROP_IN_ORIGINAL_PORTRAIT_NO_IMAGE_WRITE"):return {}
	if not need(debug.get("visual_cache_ready")==true and int(debug.get("cache_render_requests"))==1 and int(debug.get("static_build_count"))==1 and debug.get("render_mode")=="ONE_SHOT_REAL_SCENE_TEXTURE","INHERITED_ONE_SHOT_REAL_CACHE_NOT_REBUILT"):return {}
	var draw: String=mini.get_script().get_source_code().get_slice("func _draw() -> void:",1).get_slice("func _sync_portrait_marker",0)
	if not need(draw.count("draw_rect(")==2 and draw.contains("0.50") and draw.contains("0.26") and draw.contains("false, 1.0"),"ORIGINAL30D_HALF_ALPHA_SIMPLE_ONE_PIXEL_FRAME"):return {}
	return debug
func verify_business_schema(field: Node) -> bool:
	var native: Node=field.get("native_town") as Node;var layout: Dictionary=native.get("layout")
	var old: Variant=JSON.parse_string(FileAccess.get_file_as_string(String(spec.old_layout)))
	if not need(old is Dictionary and old.business==layout.business,"ORIGINAL_LINXI_BUSINESS_EXACT_SCHEMA"):return false
	var locations: Variant=load("res://build/four_settlements_20261030e_system01/locations.gd")
	var row: Dictionary=locations.call("town",ID)
	if not need(row.returns==spec.original_returns,"ORIGINAL_ROOM_AND_VILLAGE_RETURN_POINTS_EXACT"):return false
	var actor: CharacterBody2D=native.get("actor") as CharacterBody2D;var terrain: Node=native.get("terrain") as Node
	for foot: Vector2 in [Vector2(1249.3851102941176,818),Vector2(2069.592944369064,858)]:
		var mask: int=8|int(terrain.call("layer",int(terrain.call("level_at",foot))))
		if not need(clear_at(actor,foot,mask),"UNCHANGED_ORIGINAL_DOOR_NEW_COMPLETE_BODY_SAFE:"+str(foot)):return false
	records.append({"phase":"original_two_doors_schema_and_actual_physics_shape_only","bedroom_entry_replayed":false,"old_eleven_room_matrix_replayed":false,"doors_unchanged":true})
	return true
func held(code: int,ticks: int,native: Node) -> Array:
	await physics_frame
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
	var samples: Array=[]
	for _tick: int in range(ticks):
		await physics_frame;input_ticks+=1
		var actor: CharacterBody2D=native.get("actor") as CharacterBody2D;var terrain: Node=native.get("terrain") as Node
		samples.append({"foot":[actor.position.x,actor.position.y],"level":terrain.get("actor_level"),"height":terrain.get("actor_height"),"ramp":terrain.get("active_ramp")})
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events();await physics_frame;await process_frame
	return samples
func capture(label: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image();var path: String=OUT+str(OS.get_process_id())+"/"+label+".png"
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NORMAL1920_IMAGE"):return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(image.save_png(path)==OK,"SAVE_ONE_NORMAL_IMAGE"):return false
	records.append({"image":path,"sha256":FileAccess.get_sha256(path)});return true
func finish() -> void:
	if finished:return
	finished=true
	for code: int in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE,KEY_ESCAPE]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false;Input.parse_input_event(event)
	Input.flush_buffered_events()
	if not first_sources.is_empty():need(first_sources==facts(first_sources.keys()),"SOURCE_FIRST_FINAL")
	if not first_saves.is_empty():need(first_saves==facts(first_saves.keys()),"SAVE_HASH_BYTES_SECONDS_SAME_ROOT_EXACT_TICKS_SEPARATE")
	if not portrait_before.is_empty():need(portrait_before==facts(portrait_before.keys()),"LIVE_PORTRAIT_SOURCE_BYTES_UNCHANGED")
	var path: String=OUT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir());var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"input_ticks":input_ticks,"save_writes":0,"actor_camera_assignments":0,"fake_flags_or_stats":false,"old_eleven_rooms_replayed":false,"other_city_or_four_field_minimap_matrix_replayed":false,"fixture_sha256":FileAccess.get_sha256(FIXTURE)},"\t"));file.close()
	print("LINXI30F_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
