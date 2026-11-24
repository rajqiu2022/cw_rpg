extends SceneTree
## DRAFT: single formal private-garden loop. Freeze only after approved deployment.
const FIXTURE := "res://build/luoyang_city_visual_minimap_20261030c_qa01/visual_READY.json"
const OUT := "res://build/luoyang_city_visual_minimap_20261030c_qa01/actual/"
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
	if not need(raw is Dictionary and raw.get("ready")==true,"FROZEN_REAL_VISUAL_MINIMAP_ONLY"):finish();return
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
	if not need(dispatcher.call("start",router,&"luoyang_estate_riverside_20261021ai",Vector2(.5,.947265625),"",3,extension)==true,"LEGAL_SAME_ESTATE_VIEW_ONLY"):finish();return
	var field: Node=await wait_region("luoyang_estate_region_27d")
	if field==null:finish();return
	var mini: Control=field.get("_world_travel_minimap") as Control
	if not need(mini!=null,"ACTUAL_LOCAL_MINIMAP"):finish();return
	var cache: Node=mini.get("_visual_cache") as Node
	if not need(cache!=null,"ACTUAL_VISUAL_CACHE_NOT_ABSTRACT_PLAN"):finish();return
	var began:=Time.get_ticks_msec()
	while cache.call("get_debug_state").get("ready")!=true and Time.get_ticks_msec()-began<5000:await process_frame
	await process_frame;await RenderingServer.frame_post_draw
	var before: Dictionary=cache.call("get_debug_state")
	if not need(before.get("ready")==true and before.get("valid")==true and int(before.render_requests)==1 and int(before.viewport_update_mode)==SubViewport.UPDATE_DISABLED,"ONE_SHOT_CACHE_READY_THEN_DISABLED"):finish();return
	var vp: SubViewport=cache.get("_viewport") as SubViewport
	var canvas: Node=cache.get("_canvas") as Node
	if not need(vp!=null and canvas!=null and vp.world_2d!=field.get("world_container").get_world_2d(),"INDEPENDENT_CACHE_WORLD_NOT_LIVE_SCENE_CAPTURE"):finish();return
	var pending: Array=[canvas];var texture_nodes:=0
	while not pending.is_empty():
		var node: Node=pending.pop_back()
		if not need(node.get_script()==null and (node==canvas or node is Sprite2D or node is Polygon2D),"UNSCRIPTED_PURE_VISUAL_CACHE_NO_NPC_HUD_COLLISION:"+String(node.name)):finish();return
		if node is Sprite2D or node is Polygon2D:
			var tex: Texture2D=node.get("texture") as Texture2D
			if tex!=null:
				texture_nodes+=1
				if not need(not tex.resource_path.contains("/characters/"),"STATIC_TEXTURE_NOT_ACTOR"):finish();return
		pending.append_array(node.get_children())
	var rows: Array=field.get("_region").get("render",[])
	if not need(int(before.full_compiled_render_count)==rows.size() and int(before.compiled_render_count)==rows.size() and before.compiled_rows.size()==rows.size() and texture_nodes>=rows.size(),"ALL_ESTATE_COMPILED_RENDER_NOT_PLAYER_CHUNK"):finish();return
	var far_ancestral:=false;var far_kitchen:=false
	for row: Dictionary in rows:
		var found:=false
		for copy: Dictionary in before.compiled_rows:
			if String(copy.key)==String(row.key) and String(copy.texture)==String(row.texture):found=true
		if not need(found,"FULL_TEXTURE_ROW:"+String(row.key)):finish();return
		if String(row.key).contains("ancestral_wing"):far_ancestral=true
		if String(row.key).contains("kitchen_rear_house"):far_kitchen=true
	if not need(far_ancestral and far_kitchen,"DISTANT_SOUTH_BUILDINGS_INCLUDED"):finish();return
	var texture: Texture2D=cache.call("get_texture") as Texture2D
	var rid: RID=texture.get_rid()
	await key(KEY_D,4)
	for _frame: int in range(3):await process_frame
	var after: Dictionary=cache.call("get_debug_state")
	var map: Dictionary=mini.call("get_debug_state")
	if not need((field.get("_player") as Node2D).position.distance_to(Vector2(1600,434))<=1 and int(after.render_requests)==1 and vp.render_target_update_mode==SubViewport.UPDATE_DISABLED and (cache.call("get_texture") as Texture2D).get_rid()==rid,"REAL32PX_ONLY_MARKER_NO_CACHE_RERENDER"):finish();return
	if not need(map.scene_id=="luoyang_estate_region_27d" and map.overview_path=="" and mini.mouse_filter==Control.MOUSE_FILTER_IGNORE and state()==first_state,"LOCAL_SCENE_AND_ORIGINAL_REAL_STATE_PRESERVED"):finish();return
	records.append({"cache_before":before,"cache_after":after,"map":map,"texture_nodes":texture_nodes,"other_cities":"source interfaces only; no extra loads/travel"})
	if not await capture("real_scene_minimap"):finish();return
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


