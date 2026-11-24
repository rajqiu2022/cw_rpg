extends SceneTree
## DRAFT: exact owner, gate and authored feet await System. Never run unfrozen.
const FIXTURE := "res://build/luoyang_threshold_20261029o_qa01/door_READY.json"
const OUT := "res://build/luoyang_threshold_20261029o_qa01/actual/"
var spec: Dictionary={}
var errors: Array[String]=[]
var records: Array=[]
var checks:=0
var input_ticks:=0
var finished:=false
var router: Node
var first_state: Dictionary={}
var first_sources: Dictionary={}
var first_saves: Dictionary={}
func _initialize() -> void:
	_watchdog.call_deferred()
	_run.call_deferred()
func _watchdog() -> void:
	await create_timer(90.0,true,false,true).timeout
	if not finished:need(false,"INDEPENDENT_90S_WATCHDOG");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("THRESHOLD_FAIL ",label)
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
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(raw is Dictionary and raw.get("ready")==true,"ROOT_FROZEN_THIS_ONE_GATE_ONLY"):finish();return
	spec=raw
	first_sources=facts(spec.fixed_sources.keys());first_saves=facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:
		if not need(first_sources[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path):finish();return
	router=root.get_node("SceneRouter")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED"):finish();return
	first_state=state()
	if not admission_three():finish();return
	if not saved_foot_two_cases():finish();return
	var dispatcher: Resource=load("res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd")
	var extension: Dictionary={"region_id":String(spec.source_region),"revision":1,"logical_id":String(spec.source_logical),"global_foot_px":spec.front_foot}
	if not need(dispatcher.call("start",router,StringName(spec.source_logical),point(spec.legacy_uv),"",3,extension)==true,"PUBLIC_VERSIONED_EXACT_FRONT_SETUP_NOT_ACTOR_ASSIGNMENT"):finish();return
	var outside: Node=await wait_region(String(spec.source_region))
	if outside==null:finish();return
	if not need((outside.get("_player") as Node2D).position.distance_to(point(spec.front_foot))<=1,"AUTHORED_FRONT_ARRIVAL"):finish();return
	var samples: Array=await held_north(outside,48)
	var min_y:=INF
	for foot: Vector2 in samples:min_y=minf(min_y,foot.y)
	var stopped: Vector2=(outside.get("_player") as Node2D).position
	var stable: bool=samples.size()>=16
	for sample: Vector2 in samples.slice(maxi(0,samples.size()-16)):
		if sample.distance_to(stopped)>.01:stable=false
	records.append({"continuous_W_samples":samples,"actual_stop":stopped,"authored_barrier_front_y":spec.barrier_front_y,"declared_half_body":[17,12]})
	if not need(min_y>=float(spec.barrier_front_y)+12.0-.1 and stopped.y<=float(spec.barrier_front_y)+21.0 and stable and point(spec.front_foot).y-stopped.y>=64.0,"CONTINUOUS_REAL_W_STOPS_AT_THRESHOLD_WITH_FULL_BODY_AND_LAST16_STABLE"):finish();return
	var entrance: Node=door(outside,String(spec.entrance_id))
	if not need(entrance!=null and entrance.has_method("_can_enter") and entrance.call("_can_enter")==true,"BLOCKED_THRESHOLD_STILL_ACTUAL_PORTAL_ENTERABLE"):finish();return
	if not await capture():finish();return
	await key(KEY_SPACE,1)
	var inside: Node=await wait_region(String(spec.target_region))
	if inside==null:finish();return
	if not need((inside.get("_player") as Node2D).position.distance_to(point(spec.target_spawn))<=1 and state()==first_state,"REAL_SPACE_ENTERS_ORIGINAL_HALL_SAME_LIVE_STATE"):finish();return
	await key(KEY_S,6)
	if not need((inside.get("_player") as Node2D).position.distance_to(Vector2(960,1308))<=1,"ORIGINAL_HALL_EXIT_APPROACH"):finish();return
	var exit: Node=door(inside,String(spec.exit_id))
	if not need(exit!=null and exit.has_method("_can_enter") and exit.call("_can_enter")==true,"ORIGINAL_HALL_EXIT_ENTERABLE"):finish();return
	await key(KEY_SPACE,1)
	outside=await wait_region(String(spec.source_region))
	if outside==null:finish();return
	if not need((outside.get("_player") as Node2D).position.distance_to(point(spec.return_foot))<=1 and state()==first_state,"ORIGINAL_AUTHORED_RETURN_FOOT_SAME_HERO_PARTY_STATS_QUESTS"):finish();return
	await key(KEY_S,4)
	if not need((outside.get("_player") as Node2D).position.distance_to(point(spec.return_foot)+Vector2(0,32))<=1,"RETURN_NOT_TRAPPED_REAL32PX_AWAY_FROM_THRESHOLD"):finish();return
	finish()
func saved_foot_two_cases() -> bool:
	var entry: GDScript=load("res://build/luoyang_regions_20261027d_source01/region_entry.gd")
	var author_sha: String=String(router.get_script().get_script_constant_map().get("REGION27D_AUTHOR_SHA",""))
	var extension: Dictionary={"region_id":String(spec.source_region),"revision":1,"logical_id":String(spec.source_logical),"global_foot_px":[1536,1900]}
	var migrated: Dictionary=entry.call("prepare",StringName(spec.source_logical),point(spec.legacy_uv),3,extension,author_sha)
	entry.call("abort_pending")
	var world_uv: Variant=migrated.get("world_uv")
	if not need(migrated.get("ok")==true and migrated.get("region_id")==String(spec.source_region) and world_uv is Vector2 and (world_uv*Vector2(3072,4096)).distance_to(point(spec.front_foot))<=.01,"ONLY_OLD_SAFE_NEW_THRESHOLD_SAVED_FOOT_MIGRATES_TO_AUTHORED_FRONT"):return false
	extension.global_foot_px=[1400,1900]
	var refused: Dictionary=entry.call("prepare",StringName(spec.source_logical),point(spec.legacy_uv),3,extension,author_sha)
	entry.call("abort_pending")
	return need(refused.get("ok")!=true and refused.get("error")=="REGION_SAVED_FOOT_BLOCKED","OLD_ALREADY_BLOCKED_SIDE_WALL_FOOT_STILL_REJECTED")
func admission_three() -> bool:
	var authority: GDScript=load("res://scripts/city/luoyang_execution_authority_20261022ap.gd")
	var culture: GDScript=load("res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd")
	var path: String="res://scripts/autoload/scene_router.gd"
	var old: String="d25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc"
	if not need(authority!=null and culture!=null and authority.call("approved",path,old)==true,"NEW_ROUTER_HISTORICAL_D25_ACCEPTED"):return false
	if not need(authority.call("approved",path,"0000000000000000000000000000000000000000000000000000000000000000")==false,"NEW_ROUTER_UNKNOWN_SHA_REJECTED"):return false
	var ready: Dictionary=culture.call("readiness")
	return need(ready.get("ok")==true and ready.get("contract",{}).get("source_sha256",{}).get(path)==old,"ORIGINAL_CULTURE_READY_HISTORICAL_ROUTER_PIN")
func wait_region(id: String) -> Node:
	var started:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-started<30000:
		await process_frame
		var field: Node=current_scene
		if field==null or not field.has_method("get_region27d_state"):continue
		var loading: Dictionary=field.call("get_field_loading_state");var region: Dictionary=field.call("get_region27d_state")
		if String(region.get("id"))!=id:continue
		if loading.get("failed")==true:need(false,"REGION_FAILED:"+id);return null
		if loading.get("complete")!=true or root.get_node("LoadingManager").get("_transition_active")==true or root.get_node("LoadingManager").get("_external_active")==true:continue
		if not is_instance_valid(field.get("_player")) or field.get("_player").get("can_move")!=true:continue
		await physics_frame;await RenderingServer.frame_post_draw
		return field
	need(false,"REGION_30S_TIMEOUT:"+id);return null
func door(field: Node,id: String) -> Node:
	var found: Array=[];var rows: Dictionary=field.get("_region_portals")
	for zone: Node in field.get("_exit_nodes"):
		if String(rows.get(zone.get_instance_id(),{}).get("id",""))==id:found.append(zone)
	return found[0] if found.size()==1 else null
func held_north(field: Node,ticks: int) -> Array:
	var samples: Array=[]
	await physics_frame
	var event:=InputEventKey.new();event.keycode=KEY_W;event.physical_keycode=KEY_W;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events()
	for _tick: int in range(ticks):
		await physics_frame;input_ticks+=1
		samples.append((field.get("_player") as Node2D).position)
	event=InputEventKey.new();event.keycode=KEY_W;event.physical_keycode=KEY_W;event.pressed=false
	Input.parse_input_event(event);Input.flush_buffered_events();await physics_frame;await process_frame
	return samples
func key(code: int,ticks: int) -> void:
	await physics_frame
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events()
	for _tick: int in range(ticks):await physics_frame;input_ticks+=1
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
	Input.parse_input_event(event);Input.flush_buffered_events();await physics_frame;await process_frame
func capture() -> bool:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image();var path:=OUT+str(OS.get_process_id())+"/gate.png"
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NATIVE_GATE_IMAGE"):return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(image.save_png(path)==OK,"SAVE_NATIVE_GATE_IMAGE"):return false
	records.append({"image":path,"sha256":FileAccess.get_sha256(path)});return true
func finish() -> void:
	if finished:return
	finished=true
	for code: int in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false;Input.parse_input_event(event)
	Input.flush_buffered_events()
	if not first_sources.is_empty():need(first_sources==facts(first_sources.keys()),"SOURCE_FIRST_FINAL")
	if not first_saves.is_empty():need(first_saves==facts(first_saves.keys()),"SAVE_HASH_BYTES_SECONDS_SAME_ROOT_EXACTTICKS_SEPARATE")
	var path:=OUT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir());var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"input_ticks":input_ticks,"save_writes":0,"actor_camera_writes":0,"old_city_tests_replayed":false,"fixture_sha256":FileAccess.get_sha256(FIXTURE)},"\t"));file.close()
	print("THRESHOLD_LOCAL ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
