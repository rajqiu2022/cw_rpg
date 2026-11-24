extends SceneTree
## Draft only. All new door/room/NPC/media/route facts must be frozen by Root first.
const FIXTURE := "res://build/luoyang_yihongyuan_20261029n_qa01/trip03_READY.json"
const OUTPUT := "res://build/luoyang_yihongyuan_20261029n_qa01/actual/"
var spec: Dictionary={}
var errors: Array[String]=[]
var records: Array=[]
var checks:=0
var began:=0
var input_ticks:=0
var spoken: Array=[]
var before_state: Dictionary={}
var source_before: Dictionary={}
var save_before: Dictionary={}
var router: Node
var dialogs: Node
var finished:=false
func _initialize() -> void:
	_watchdog.call_deferred()
	_run.call_deferred()
func _watchdog() -> void:
	await create_timer(90.0,true,false,true).timeout
	if not finished:
		need(false,"INDEPENDENT_90S_WATCHDOG_INCLUDING_SCRIPT_COROUTINE_ABORT")
		finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("YIHONGYUAN_FAIL ",label)
	return ok
func point(raw: Array) -> Vector2:return Vector2(float(raw[0]),float(raw[1]))
func facts(paths: Array) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(path):result[path]={"exists":false};continue
		var file:=FileAccess.open(path,FileAccess.READ)
		result[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result
func state() -> Dictionary:
	var game: Node=root.get_node("GameState");var save: Node=root.get_node("SaveManager")
	var hero: Resource=game.get("player") as Resource;var party: Array=[]
	for member: Resource in game.get("party"):party.append({"instance":str(member.get_instance_id()),"data":save.call("_serialize_stats",member)})
	return {"hero_instance":str(hero.get_instance_id()),"hero":save.call("_serialize_stats",hero),"party":party,"gold":game.get("gold"),"flags":game.get("flags").duplicate(true),"quests":root.get_node("QuestManager").call("to_dict"),"inventory":root.get_node("Inventory").call("to_dict")}.duplicate(true)
func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(raw is Dictionary and raw.get("ready")==true,"ROOT_FROZEN_NEW_BUILDING_ONLY_FIXTURE"):finish();return
	spec=raw;source_before=facts(spec.fixed_sources.keys());save_before=facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:
		if not need(source_before[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path):finish();return
	router=root.get_node("SceneRouter");dialogs=root.get_node("DialogPlayer")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED_NO_SAVE_READ_OR_WRITE"):finish();return
	before_state=state()
	if spec.get("residual_only")==true:
		if not admission_three():finish();return
		await residual_exit_and_visuals()
		return
	dialogs.connect("text_displayed",Callable(self,"text_shown"))
	# Explicit existing SE local-v3 market anchor. Not a global-Civic UV or a World trip.
	if not need(router.call("go_field_smart",&"ch4_s3_luoyang_market",point(spec.market_legacy_setup_uv),"",15,3)==true,"PUBLIC_MARKET_EXACT_LOCAL3_SETUP_NOT_WORLD"):finish();return
	var outside: Node=await wait_region(String(spec.exterior_region))
	if outside==null:finish();return
	if not need((outside.get("_player") as Node2D).position.distance_to(point(spec.market_arrival_foot))<=1,"AUTHORED_SE_MARKET_ARRIVAL_NOT_OBSERVED_EXPECTATION"):finish();return
	# The first actual already passed both outside legs and all three full-body
	# checks. Movement below is necessary public-SE approach only, not a retest.
	for step: Dictionary in spec.outside_steps:await key(int(step.key),int(step.ticks))
	var entrance: Node=door(outside,String(spec.entrance_portal_id))
	if not need(entrance!=null and entrance.has_method("_can_enter") and entrance.call("_can_enter")==true and String(entrance.get("exit_label")).contains("怡红院"),"FORMAL_CHINESE_YIHONGYUAN_DOOR_ENTERABLE"):finish();return
	if not await capture("outside"):finish();return
	await key(KEY_SPACE,1)
	var room: Node=await wait_region(String(spec.room_id))
	if room==null:finish();return
	if not need(state()==before_state and (room.get("_player") as Node2D).position.distance_to(point(spec.room_arrival_foot))<=1,"FORMAL_ROOM_REAL_SAME_STATS_PARTY_QUESTS_AND_ARRIVAL"):finish();return
	if not await walk(room,spec.room_to_keeper_steps):finish();return
	var static_before:=static_identity(room)
	spoken.clear()
	await key(KEY_SPACE,1)
	if not need(dialogs.call("is_playing")==true,"REAL_KEEPER_SPACE_CONVERSATION_STARTED"):finish();return
	var active_keeper: Node=room.get("_active_dialog_npc") as Node
	if not need(active_keeper!=null and String(active_keeper.get("npc_id"))==String(spec.keeper_id),"ACTUAL_ACTIVE_KEEPER_ID_NOT_DIALOG_ONLY_STUB"):finish();return
	var started:=Time.get_ticks_msec()
	while dialogs.call("is_playing")==true and Time.get_ticks_msec()-started<15000:
		await create_timer(.05).timeout
		await key(KEY_SPACE,1)
	if not need(dialogs.call("is_playing")==false,"KEEPER_CONVERSATION_NATURALLY_FINISHED"):finish();return
	for _frame: int in range(4):await process_frame
	var hero: Resource=root.get_node("GameState").get("player") as Resource
	if not need(not spoken.is_empty() and spoken[0].speaker==String(hero.get("display_name")) and spoken[0].portrait==String(hero.get("portrait_path")) and spoken[0].choices==false,"FIRST_REAL_DIALOG_TEXT_IS_HERO_WITH_ACTUAL_PORTRAIT_NO_CHOICES"):finish();return
	var keeper_lines: Array=[]
	for row: Dictionary in spoken:
		if row.speaker==String(spec.keeper_name):
			keeper_lines.append(row.text)
			if not need(row.portrait==String(active_keeper.get("portrait_path")) and row.portrait==String(spec.keeper_portrait),"KEEPER_REAL_TEXT_USES_BOUND_CORRECT_NPC_PORTRAIT"):finish();return
	if not need(keeper_lines==spec.keeper_lines,"EXACT_KEEPER_LINES_FROM_NEW_NATIVE_DIALOG"):finish();return
	if not need(static_identity(room)==static_before,"SAME_ROOM_STATIC_FLOORS_BODIES_OWNER_AND_ACTOR_AFTER_DIALOG"):finish();return
	if not need(state()==before_state,"LIVE_STATS_TASKS_INVENTORY_UNCHANGED_AFTER_KEEPER"):finish();return
	if not await capture("inside"):finish();return
	if not await walk(room,spec.room_to_exit_steps):finish();return
	var exit: Node=door(room,String(spec.exit_portal_id))
	if not need(exit!=null and exit.has_method("_can_enter") and exit.call("_can_enter")==true,"REAL_ROOM_RETURN_DOOR_ENTERABLE"):finish();return
	await key(KEY_SPACE,1)
	outside=await wait_region(String(spec.exterior_region))
	if outside==null:finish();return
	if not need((outside.get("_player") as Node2D).position.distance_to(point(spec.authored_return_foot))<=1 and state()==before_state,"TRUE_ROOM_EXIT_RETURNS_AUTHORED_EXTERIOR_FOOT_SAME_BUSINESS_STATE"):finish();return
	finish()
func admission_three() -> bool:
	var authority: GDScript=load("res://scripts/city/luoyang_execution_authority_20261022ap.gd")
	var culture: GDScript=load("res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd")
	var path: String="res://scripts/autoload/scene_router.gd"
	var historical: String="d25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc"
	if not need(authority!=null and culture!=null and authority.call("approved",path,historical)==true,"NEW_ROUTER_APPROVED_HISTORICAL_D25_COMPLETE_CHAIN"):return false
	if not need(authority.call("approved",path,"0000000000000000000000000000000000000000000000000000000000000000")==false,"NEW_ROUTER_UNKNOWN_SHA_REJECTED"):return false
	var ready: Dictionary=culture.call("readiness")
	return need(ready.get("ok")==true and ready.get("contract",{}).get("source_sha256",{}).get(path)==historical,"NEW_ROUTER_ORIGINAL_CULTURE_READINESS_WITH_HISTORICAL_PIN")
func residual_exit_and_visuals() -> void:
	# A real saved-coordinate entry through the existing public versioned
	# dispatcher. No user save is read/written; no actor/camera is assigned.
	var dispatcher: Resource=load("res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd")
	var extension: Dictionary={"region_id":String(spec.room_id),"revision":1,"logical_id":String(spec.room_id),"global_foot_px":[1152,586]}
	if not need(dispatcher.call("start",router,StringName(spec.room_id),Vector2(.5,850.0/1024.0),"",-1,extension)==true,"PUBLIC_VERSIONED_ROOM_RESUME_AT_AUTHORED_COUNTER_FRONT_NOT_TELEPORT"):finish();return
	var room: Node=await wait_region(String(spec.room_id))
	if room==null:finish();return
	if not need((room.get("_player") as Node2D).position.distance_to(Vector2(1152,586))<=1 and state()==before_state,"RESIDUAL_ROOM_SETUP_REAL_STATE_AND_EXACT_FOOT"):finish();return
	if not await capture("inside"):finish();return
	if not await walk(room,spec.room_to_exit_steps):finish();return
	var exit: Node=door(room,String(spec.exit_portal_id))
	if not need(exit!=null and exit.has_method("_can_enter") and exit.call("_can_enter")==true,"RESIDUAL_REAL_ROOM_RETURN_DOOR_ENTERABLE"):finish();return
	await key(KEY_SPACE,1)
	var outside: Node=await wait_region(String(spec.exterior_region))
	if outside==null:finish();return
	if not need((outside.get("_player") as Node2D).position.distance_to(point(spec.authored_return_foot))<=1 and state()==before_state,"RESIDUAL_TRUE_ROOM_EXIT_EXACT_AUTHORED_STREET_FOOT_AND_REAL_STATE"):finish();return
	await key(KEY_W,12)
	if not need((outside.get("_player") as Node2D).position.distance_to(Vector2(5206.18017578125,4184))<=1,"REVISED_DOORWAY_HERO_VISUAL_FOOT"):finish();return
	if not await capture("outside"):finish();return
	finish()
func wait_region(id: String) -> Node:
	var started:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-started<30000 and Time.get_ticks_msec()-began<90000:
		await process_frame
		var field: Node=current_scene
		if field==null or not field.has_method("get_region27d_state"):continue
		var loading: Dictionary=field.call("get_field_loading_state")
		var region: Dictionary=field.call("get_region27d_state")
		if String(region.get("id"))!=id:continue
		if loading.get("failed")==true:need(false,"REGION_FIELD_FAILED:"+id);return null
		if loading.get("complete")!=true or root.get_node("LoadingManager").get("_transition_active")==true or root.get_node("LoadingManager").get("_external_active")==true:continue
		if not is_instance_valid(field.get("_player")) or field.get("_player").get("can_move")!=true:continue
		await physics_frame;await RenderingServer.frame_post_draw
		return field
	need(false,"REGION_ENTRY_30S_BOUND:"+id);return null
func walk(field: Node,steps: Array) -> bool:
	for step: Dictionary in steps:
		await key(int(step.key),int(step.ticks))
		var actual: Vector2=field.get("_player").position
		records.append({"key":step.key,"ticks":step.ticks,"expected_foot":step.end,"actual_foot":actual})
		if not need(actual.distance_to(point(step.end))<=16,"TRUE_LOCAL_WALK:"+String(step.id)):return false
	return true
func door(field: Node,id: String) -> Node:
	var found: Array=[];var rows: Dictionary=field.get("_region_portals")
	for zone: Node in field.get("_exit_nodes"):
		if String(rows.get(zone.get_instance_id(),{}).get("id",""))==id:found.append(zone)
	return found[0] if found.size()==1 else null
func full_body_clear(field: Node,foot: Vector2) -> bool:
	var shape:=RectangleShape2D.new();shape.size=Vector2(34,24)
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape;query.transform=Transform2D(0,field.get("world_container").to_global(foot));query.collision_mask=1;query.collide_with_areas=false;query.collide_with_bodies=true;query.margin=0
	query.exclude=[field.get("_player").call("get_rid")]
	return (field.get("_player") as Node2D).get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
func static_identity(field: Node) -> Dictionary:
	var visuals: Array=[];var bodies: Array=[]
	for child: Node in field.get("_visual_layer").get_children():visuals.append(str(child.get_instance_id()))
	for child: Node in field.get("_collision_layer").get_children():bodies.append(str(child.get_instance_id()))
	return {"field":str(field.get_instance_id()),"scene":str(field.get("_current_scene").get_instance_id()),"owner":str(field.call("region_session_handle").get_instance_id()),"actor":str(field.get("_player").get_instance_id()),"visuals":visuals,"bodies":bodies}
func text_shown(speaker: String,text: String,choices: bool,portrait: String) -> void:spoken.append({"speaker":speaker,"text":text,"choices":choices,"portrait":portrait})
func key(code: int,ticks: int) -> void:
	# Align press to a physics boundary. In particular do not await process_frame
	# with the key down after a GPU readback: catch-up steps would go uncounted.
	await physics_frame
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events()
	for _tick: int in range(ticks):await physics_frame;input_ticks+=1
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
	Input.parse_input_event(event);Input.flush_buffered_events();await physics_frame;await process_frame
func capture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image();var path:=OUTPUT+str(OS.get_process_id())+"/"+name+".png"
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NATIVE_IMAGE:"+name):return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(image.save_png(path)==OK,"SAVE_NATIVE_IMAGE:"+name):return false
	records.append({"image":path,"sha256":FileAccess.get_sha256(path)});return true
func finish() -> void:
	if finished:return
	finished=true
	for code: int in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false;Input.parse_input_event(event)
	Input.flush_buffered_events()
	if not source_before.is_empty():need(source_before==facts(source_before.keys()),"FROZEN_SOURCE_FIRST_FINAL")
	if not save_before.is_empty():need(save_before==facts(save_before.keys()),"SAVE_HASH_BYTES_SECONDS_SAME_ROOT_EXACTTICKS_SEPARATE")
	var path:=OUTPUT+str(OS.get_process_id())+"/trip_result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir());var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"spoken":spoken,"input_ticks":input_ticks,"elapsed_ms":Time.get_ticks_msec()-began,"save_writes":0,"actor_camera_writes":0,"world_old_walls_or_three_towns_replayed":false,"fixture_sha256":FileAccess.get_sha256(FIXTURE)},"\t"));file.close()
	print("[Yihongyuan] ",checks," checks / ",errors.size()," failures; ",path);quit(0 if errors.is_empty() else 1)
