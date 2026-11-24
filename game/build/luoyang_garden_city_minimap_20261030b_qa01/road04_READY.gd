extends SceneTree
## DRAFT: single formal private-garden loop. Freeze only after approved deployment.
const FIXTURE := "res://build/luoyang_garden_city_minimap_20261030b_qa01/road04_READY.json"
const OUT := "res://build/luoyang_garden_city_minimap_20261030b_qa01/actual/"
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
	if not ok:errors.append(label);printerr("CITY_MINIMAP_FAIL ",label)
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
	if not need(raw is Dictionary and raw.get("ready")==true,"FROZEN_ROAD_UNION_VISUAL_RESIDUAL_ONLY"):finish();return
	spec=raw;first_sources=facts(spec.fixed_sources.keys());first_saves=facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:
		if not need(first_sources[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path):finish();return
	router=root.get_node("SceneRouter")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED"):finish();return
	first_state=state()
	if not admission_three():finish();return
	var dispatcher: Resource=load("res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd")
	var extension: Dictionary={"region_id":"luoyang_estate_region_27d","revision":1,"logical_id":"luoyang_estate_riverside_20261021ai","global_foot_px":[1568,434]}
	if not need(dispatcher.call("start",router,&"luoyang_estate_riverside_20261021ai",Vector2(.5,.947265625),"",3,extension)==true,"SAME_AUTHORED_GARDEN_CAMERA_FOOT_NOT_UI_RETEST"):finish();return
	var field: Node=await wait_region("luoyang_estate_region_27d")
	if field==null:finish();return
	if not need((field.get("_player") as Node2D).position.distance_to(Vector2(1568,434))<=1 and state()==first_state,"SAME_NORMAL_ACTOR_FOOT_REAL_STATE"):finish();return
	if not await capture("garden_road_union_residual"):finish();return
	finish()
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
	print("CITY_MINIMAP_LOCAL ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
