extends SceneTree
## Root-only. Three original World doors, new near-foot segments, true exits.
const FIXTURE := "res://build/three_settlements_20261030e_qa01/actual_READY.json"
const OUTPUT := "res://build/three_settlements_20261030e_qa01/actual/"
const ORIGINAL_XIANGZHOU_BOUNTY_IDS: Array[String]=["xiangzhou_mine_jackal","xiangzhou_white_deer"]
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
var first_bounties_raw: Dictionary={}
func _initialize() -> void:
	_watchdog.call_deferred();_run.call_deferred()
func _watchdog() -> void:
	await create_timer(90.0,true,false,true).timeout
	if not finished:need(false,"INDEPENDENT_90S_WATCHDOG");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("SETTLEMENT30E_FAIL ",label)
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
	var bounty: Dictionary=root.get_node("BountyManager").call("to_dict").duplicate(true)
	var bounty_states: Dictionary=bounty.get("states",{})
	# Opening the original board lazily materializes exactly these four defaults.
	# Normalize absence/default equivalence only; all active/captured/nondefault data stays exact.
	for id: String in bounty_states.keys():
		var row: Dictionary=bounty_states[id]
		if id in ORIGINAL_XIANGZHOU_BOUNTY_IDS and row.size()==4 and String(row.get("status"))=="available" and int(row.get("location_index",-99))==-1 and int(row.get("escape_count",-99))==0 and int(row.get("completion_count",-99))==0:bounty_states.erase(id)
	return {"hero_instance":str(hero.get_instance_id()),"hero":save.call("_serialize_stats",hero),"party":party,"gold":game.get("gold"),"flags":game.get("flags").duplicate(true),"chapter":game.get("current_chapter"),"inventory":root.get_node("Inventory").call("to_dict"),"quests":root.get_node("QuestManager").call("to_dict"),"bounties_semantic":bounty}.duplicate(true)
func _run() -> void:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(raw is Dictionary and raw.get("ready")==true,"ROOT_FROZEN_READY_FIXTURE"):finish();return
	spec=raw;first_sources=facts(spec.fixed_sources.keys());first_saves=facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:
		if not need(first_sources[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path):finish();return
	router=root.get_node("SceneRouter");game=root.get_node("GameState");dialog=root.get_node("DialogPlayer")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED"):finish();return
	first_bounties_raw=root.get_node("BountyManager").call("to_dict").duplicate(true);first_state=state()
	if not admission():finish();return
	for leg: Dictionary in spec.legs:
		if not await run_leg(leg):finish();return
	need(state()==first_state,"SAME_REAL_HERO_PARTY_STATS_QUESTS_ITEMS_AFTER_ALL_THREE")
	records.append({"bounty_raw_before":first_bounties_raw,"bounty_raw_after":root.get_node("BountyManager").call("to_dict"),"normalization":"Only two original Xiangzhou IDs with exact four-field available/-1/0/0 absent/default equivalence; unknown IDs and active/captured/nondefault data remain exact; no bounty accepted"})
	finish()
func admission() -> bool:
	var authority: Variant=load("res://scripts/city/luoyang_execution_authority_20261022ap.gd")
	var culture: Variant=load("res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd")
	var path: String="res://scripts/autoload/scene_router.gd"
	var old: String="d25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc"
	if not need(authority.call("approved",path,old)==true,"NEW_ROUTER_ORIGINAL_HISTORICAL_PIN_ACCEPTED"):return false
	if not need(authority.call("approved",path,"0000000000000000000000000000000000000000000000000000000000000000")==false,"UNKNOWN_SHA_REJECTED"):return false
	var readiness: Dictionary=culture.call("readiness")
	return need(readiness.get("ok")==true and readiness.get("contract",{}).get("source_sha256",{}).get(path)==old,"ORIGINAL_CULTURE_READY")
func run_leg(leg: Dictionary) -> bool:
	var id: String=String(leg.id);var world_id: String=String(leg.world_id)
	var world_size: Vector2=point(spec.world_size)
	if not need(router.call("go_field_smart",StringName(world_id),point(leg.world_setup_foot)/world_size,"",15,-1)==true,"PUBLIC_ORIGINAL_WORLD_DOOR_SETUP:"+id):return false
	var world: Node=await wait_field(world_id)
	if world==null:return false
	var matching: Array=[]
	var world_scene: Resource=world.get("_current_scene") as Resource
	for row: Dictionary in (world_scene.get("map_layout") as Resource).get("portals"):
		if String(row.get("target_scene",""))==id:matching.append(row)
	if not need(matching.size()==1,"ONE_ORIGINAL_WORLD_TARGET:"+id):return false
	var anchor: Vector2=matching[0].get("source_spawn_pos",matching[0].pos)
	var zones: Array=[]
	for zone: Node in world.get("_exit_nodes"):
		if String(zone.get("target_scene_id"))==id:zones.append(zone)
	if not need(zones.size()==1 and zones[0].call("can_enter")==true,"ACTUAL_WORLD_DOOR_ENTERABLE:"+id):return false
	await key(KEY_SPACE,1)
	var field: Node=await wait_field(id)
	if field==null:return false
	var author: Variant=load(String(leg.author));var size: Vector2=author.SIZE
	var hero: Node2D=field.get("_player") as Node2D
	if not need(hero.position.distance_to(author.SOUTH_ARRIVAL)<=1 and state()==first_state,"NEW_NATIVE_ARRIVAL_SAME_LIVE_STATE:"+id):return false
	var before: Vector2=hero.position
	await key(KEY_D,4);var stepped: Vector2=hero.position;await key(KEY_A,4)
	if not need(stepped.distance_to(before)>=24 and stepped.distance_to(before)<=40 and hero.position.distance_to(before)<=8,"TRUE32PX_INPUT_SAME_ARRIVAL:"+id):return false
	if not await capture(id+"_arrival"):return false
	if leg.has("near_foot"):
		# From within the same town: requested v30 foot is not overridden by World arrival.
		if not need(router.call("go_field_smart",StringName(id),point(leg.near_foot)/size,"",-1,30)==true,"PUBLIC_VERSION30_NEARFOOT_SETUP:"+id):return false
		field=await wait_field(id)
		if field==null:return false
		hero=field.get("_player") as Node2D
		if not need(hero.position.distance_to(point(leg.near_foot))<=1,"NEARFOOT_ACTUAL_NOT_TELEPORT:"+id):return false
		if leg.get("capture_near",false):
			if not await capture(id+"_detail"):return false
		var actor_instance: int=hero.get_instance_id();var field_instance: int=field.get_instance_id()
		for step: Dictionary in leg.get("steps",[]):
			await key(int(step.key),int(step.ticks))
			if not need(hero.position.distance_to(point(step.end))<=8,"NEW_ROUTE_ACTUAL_END:"+id+":"+str(step.end)):return false
			if step.get("capture",false):
				if not await capture(id):return false
		if not need(hero.get_instance_id()==actor_instance and field.get_instance_id()==field_instance,"SAME_FIELD_AND_ACTOR_DURING_REAL_SEGMENT:"+id):return false
	if leg.has("npc_foot"):
		if not need(router.call("go_field_smart",StringName(id),point(leg.npc_foot)/size,"",-1,30)==true,"PUBLIC_ORIGINAL_NPC_APPROACH:"+id):return false
		field=await wait_field(id)
		if field==null:return false
		await key(KEY_SPACE,1)
		for _frame: int in range(3):await process_frame
		var script: Resource=dialog.get("_current_script") as Resource
		if not need(dialog.call("is_playing")==true and script!=null and String(script.get("dialog_id"))==String(leg.dialog_id),"REAL_SPACE_OPENS_ORIGINAL_NPC_DIALOG:"+id):return false
		# Only the frozen original first choice may open the existing supply shop.
		await key(KEY_1 if leg.has("shop_id") else KEY_2,1)
		if leg.has("shop_id"):
			var shop: Node=await wait_ui("res://scenes/shop.tscn")
			if not need(shop!=null and String(router.call("get_shop_payload").get("shop_id"))==String(leg.shop_id),"ORIGINAL_QINGHE_SHOP_OPEN_NO_TRADE"):return false
			await key(KEY_ESCAPE,1);field=await wait_field(id)
			if field==null:return false
		for _frame: int in range(3):await process_frame
		if not need(dialog.call("is_playing")==false and state()==first_state,"ORIGINAL_SERVICE_NO_TASK_OR_ECONOMY_CHANGE:"+id):return false
	if leg.has("board_foot"):
		if not need(router.call("go_field_smart",StringName(id),point(leg.board_foot)/size,"",-1,30)==true,"PUBLIC_ORIGINAL_BOUNTY_BOARD_APPROACH"):return false
		field=await wait_field(id)
		if field==null:return false
		await key(KEY_SPACE,1)
		var board: Node=await wait_ui("res://scenes/bounty_board.tscn")
		var payload: Dictionary=router.call("get_bounty_board_payload")
		if not need(board!=null and String(payload.get("city_id"))=="xiangzhou" and String(payload.get("return_scene"))==id and int(payload.get("return_local_layout_version"))==30,"REAL_ORIGINAL_XIANGZHOU_BOARD_OPEN_NO_BOUNTY_TAKEN"):return false
		await key(KEY_ESCAPE,1);field=await wait_field(id)
		if field==null:return false
		if not need(state()==first_state,"ORIGINAL_BOARD_CLOSE_PRESERVES_TASK_STATE"):return false
	if not need(router.call("go_field_smart",StringName(id),point(leg.exit_setup)/size,"",-1,30)==true,"PUBLIC_NEAR_ORIGINAL_SOUTH_EXIT:"+id):return false
	field=await wait_field(id)
	if field==null:return false
	await key(KEY_S,int(leg.exit_ticks))
	var exit: Node=null
	for zone: Node in field.get("_exit_nodes"):
		if String(zone.get("action"))=="world_map":exit=zone
	if not need(exit!=null and (bool(exit.call("_can_enter")) if exit.has_method("_can_enter") else bool(exit.get("_in_range"))),"ACTUAL_SOUTH_EXIT_IN_RANGE:"+id):return false
	await key(KEY_SPACE,1);world=await wait_field(world_id)
	if world==null:return false
	if not need((world.get("_player") as Node2D).position.distance_to(anchor*world_size)<=1 and state()==first_state,"TRUE_RETURN_SAME_WORLD_ALIAS_ANCHOR_AND_REAL_STATE:"+id):return false
	records.append({"scene":id,"world_alias":world_id,"world_anchor_frozen_before_space":anchor,"not_whole_city_walk":true,"old_minimap_matrix_inherited":true})
	return true
func wait_ui(scene_path: String) -> Node:
	var started: int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-started<5000 and not finished:
		await process_frame
		if current_scene!=null and String(current_scene.scene_file_path)==scene_path:
			await RenderingServer.frame_post_draw;return current_scene
	need(false,"ORIGINAL_UI5S_TIMEOUT:"+scene_path);return null
func wait_field(id: String) -> Node:
	var started: int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-started<20000 and not finished:
		await process_frame
		var field: Node=current_scene
		if field==null or not field.has_method("get_field_loading_state"):continue
		var loading: Dictionary=field.call("get_field_loading_state")
		if String(loading.get("scene_id"))!=id:continue
		if loading.get("failed")==true:need(false,"LOAD_FAILED:"+id);return null
		var manager: Node=root.get_node("LoadingManager")
		if loading.get("complete")!=true or manager.get("_transition_active")==true or manager.get("_external_active")==true:continue
		var player: Node=field.get("_player")
		if not is_instance_valid(player) or player.get("can_move")!=true or dialog.call("is_playing")==true:continue
		await physics_frame;await RenderingServer.frame_post_draw
		return field
	need(false,"LOAD20S_TIMEOUT:"+id);return null
func key(code: int,ticks: int) -> void:
	await physics_frame
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true;Input.parse_input_event(event);Input.flush_buffered_events()
	for _tick: int in range(ticks):await physics_frame;input_ticks+=1
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false;Input.parse_input_event(event);Input.flush_buffered_events();await physics_frame;await process_frame
func capture(label: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image();var path: String=OUTPUT+str(OS.get_process_id())+"/"+label+".png"
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"NATIVE_NORMAL_CAMERA_IMAGE:"+label):return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(image.save_png(path)==OK,"SAVE_NORMAL_IMAGE:"+label):return false
	records.append({"image":path,"sha256":FileAccess.get_sha256(path)});return true
func finish() -> void:
	if finished:return
	finished=true
	for code: int in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE,KEY_1,KEY_2]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false;Input.parse_input_event(event)
	Input.flush_buffered_events()
	if not first_sources.is_empty():need(first_sources==facts(first_sources.keys()),"SOURCE_FIRST_FINAL")
	if not first_saves.is_empty():need(first_saves==facts(first_saves.keys()),"SAVE_HASH_BYTES_SECONDS_SAME_ROOT_EXACTTICKS_SEPARATE")
	var path: String=OUTPUT+str(OS.get_process_id())+"/result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir());var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"input_ticks":input_ticks,"save_writes":0,"actor_camera_assignments":0,"old_success_matrix_replayed":false,"fixture_sha256":FileAccess.get_sha256(FIXTURE)},"\t"));file.close()
	print("SETTLEMENT30E_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
