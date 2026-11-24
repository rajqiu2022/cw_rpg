extends SceneTree
## DRAFT: single formal private-garden loop. Freeze only after approved deployment.
const FIXTURE := "res://build/luoyang_private_garden_20261029q_qa01/garden_READY.json"
const OUT := "res://build/luoyang_private_garden_20261029q_qa01/actual/"
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
	if not ok:errors.append(label);printerr("PRIVATE_GARDEN_FAIL ",label)
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
	if not need(raw is Dictionary and raw.get("ready")==true,"ROOT_FROZEN_ONE_PRIVATE_GARDEN_LOOP"):finish();return
	spec=raw
	first_sources=facts(spec.fixed_sources.keys());first_saves=facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:
		if not need(first_sources[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path):finish();return
	router=root.get_node("SceneRouter")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED"):finish();return
	first_state=state()
	if not admission_three():finish();return
	if not garden_saved_foot_cases():finish();return
	var dispatcher: Resource=load("res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd")
	var extension: Dictionary={"region_id":String(spec.room_id),"revision":1,"logical_id":String(spec.room_id),"global_foot_px":[960,240]}
	if not need(dispatcher.call("start",router,StringName(spec.room_id),Vector2(.5,.875),"",-1,extension)==true,"LEGAL_FORMAL_ROOM_NORTH_SETUP_NOT_OLD_ROOM_RETEST"):finish();return
	var room: Node=await wait_region(String(spec.room_id))
	if room==null:finish();return
	await key(KEY_W,10)
	if not need((room.get("_player") as Node2D).position.distance_to(Vector2(960,160))<=1,"ORIGINAL_HALL_NORTH_DOOR_APPROACH"):finish();return
	var north: Node=door(room,String(spec.hall_north_id))
	if not need(north!=null and north.has_method("_can_enter") and north.call("_can_enter")==true,"REAL_HALL_NORTH_EXIT_ENTERABLE"):finish();return
	await key(KEY_SPACE,1)
	var garden: Node=await wait_region(String(spec.source_region))
	if garden==null:finish();return
	if not need((garden.get("_player") as Node2D).position.distance_to(point(spec.garden_arrival))<=1 and state()==first_state,"ORIGINAL_HALL_TO_PRIVATE_GARDEN_AUTHORED_ARRIVAL_REAL_STATE"):finish();return
	for block: Dictionary in spec.body_blocks:
		if not need(full_body_blocked(garden,point(block.foot)),"REAL_PHYSICS_AND_DECLARED_BODY_BLOCK:"+String(block.id)):finish();return
	if not await walk(garden,spec.garden_steps):finish();return
	var back: Node=door(garden,String(spec.garden_back_id))
	if not need(back!=null and back.has_method("_can_enter") and back.call("_can_enter")==true,"NEW_GARDEN_RETURN_TO_HALL_PORTAL_ENTERABLE"):finish();return
	await key(KEY_SPACE,1)
	room=await wait_region(String(spec.room_id))
	if room==null:finish();return
	if not need((room.get("_player") as Node2D).position.distance_to(Vector2(960,240))<=1 and state()==first_state,"NEW_REAR_DOOR_RETURNS_HALL_NORTH_NOT_SOUTH_OR_OUTSIDE"):finish();return
	if not await walk(room,spec.room_exit_steps):finish();return
	var south: Node=door(room,String(spec.hall_south_id))
	if not need(south!=null and south.has_method("_can_enter") and south.call("_can_enter")==true,"ORIGINAL_HALL_SOUTH_EXIT_STILL_ENTERABLE"):finish();return
	await key(KEY_SPACE,1)
	var estate: Node=await wait_region(String(spec.source_region))
	if estate==null:finish();return
	if not need((estate.get("_player") as Node2D).position.distance_to(Vector2(1536,2060))<=1 and state()==first_state,"WHOLE_GARDEN_LOOP_TRUE_HALL_SOUTH_RETURN_REAL_SAME_STATE"):finish();return
	var images: int=0
	for record: Dictionary in records:
		if record.has("image"):images+=1
	if not need(images==2,"EXACTLY_TWO_NATIVE_GARDEN_VIEWS_NO_OLD_ROOM_IMAGES"):finish();return
	finish()
func garden_saved_foot_cases() -> bool:
	var entry: GDScript=load("res://build/luoyang_regions_20261027d_source01/region_entry.gd")
	var author_sha: String=String(router.get_script().get_script_constant_map().get("REGION27D_AUTHOR_SHA",""))
	var extension: Dictionary={"region_id":String(spec.source_region),"revision":1,"logical_id":String(spec.source_logical),"global_foot_px":spec.new_block_old_safe}
	var migrated: Dictionary=entry.call("prepare",StringName(spec.source_logical),point(spec.legacy_estate_uv),3,extension,author_sha)
	entry.call("abort_pending")
	var world_uv: Variant=migrated.get("world_uv")
	if not need(migrated.get("ok")==true and world_uv is Vector2 and (world_uv*Vector2(3072,4096)).distance_to(point(spec.garden_arrival))<=.01,"NEW_GARDEN_SOLID_ONLY_OLD_SAFE_SAVE_MIGRATES_TO_AUTHORED_AXIS"):return false
	extension.global_foot_px=spec.old_block_still_rejected
	var refused: Dictionary=entry.call("prepare",StringName(spec.source_logical),point(spec.legacy_estate_uv),3,extension,author_sha)
	entry.call("abort_pending")
	return need(refused.get("ok")!=true and refused.get("error")=="REGION_SAVED_FOOT_BLOCKED","OLD_GARDEN_BLOCKED_SAVE_STILL_REJECTED_NOT_THRESHOLD_CASE_REPLAY")
func full_body_blocked(field: Node,foot: Vector2) -> bool:
	var owner: RefCounted=field.call("region_session_handle")
	if owner.call("safe_foot",field,field.get("_current_scene"),foot)!=false:return false
	var shape:=RectangleShape2D.new();shape.size=Vector2(34,24)
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape;query.transform=Transform2D(0,field.get("world_container").to_global(foot));query.collision_mask=1;query.collide_with_areas=false;query.collide_with_bodies=true;query.margin=0
	query.exclude=[field.get("_player").call("get_rid")]
	return not (field.get("_player") as Node2D).get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
func walk(field: Node,steps: Array) -> bool:
	for step: Dictionary in steps:
		await key(int(step.key),int(step.ticks))
		var foot: Vector2=field.get("_player").position
		records.append({"route":step.id,"actual":foot,"expected":step.end,"ticks":step.ticks})
		if not need(foot.distance_to(point(step.end))<=1,"TRUE_AUTHORED_GARDEN_OR_EXIT_WALK:"+String(step.id)):return false
		if step.has("capture"):
			if not camera_fact(field,String(step.capture)):return false
			if not await capture(String(step.capture)):return false
	return true
func camera_fact(field: Node,label: String) -> bool:
	var camera: Camera2D=field.get("_world_camera") as Camera2D
	var actor: Node2D=field.get("_player") as Node2D
	if not need(camera!=null and camera.zoom==Vector2.ONE and is_equal_approx(float(actor.get("_visual_scale_multiplier")),1.12),"NORMAL_GARDEN_CAMERA_ZOOM_AND_HERO_RATIO:"+label):return false
	var screen: Vector2=actor.get_global_transform_with_canvas()*Vector2.ZERO
	records.append({"camera_at":label,"centre":camera.get_screen_center_position(),"zoom":camera.zoom,"hero_screen":screen,"hero_foot":actor.position})
	return need(Rect2(Vector2.ZERO,Vector2(1920,1080)).has_point(screen),"NORMAL_HERO_IN_ACTUAL_VIEWPORT:"+label)
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
func key(code: int,ticks: int) -> void:
	await physics_frame
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events()
	for _tick: int in range(ticks):await physics_frame;input_ticks+=1
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
	Input.parse_input_event(event);Input.flush_buffered_events();await physics_frame;await process_frame
func capture(label: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image();var path:=OUT+str(OS.get_process_id())+"/"+label+".png"
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NATIVE_BOUNDARY_IMAGE:"+label):return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(image.save_png(path)==OK,"SAVE_NATIVE_BOUNDARY_IMAGE:"+label):return false
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
	print("PRIVATE_GARDEN_LOCAL ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)




