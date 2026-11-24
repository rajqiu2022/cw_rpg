extends SceneTree
## Root-only repaired original World→Luoyang gate, one short input and one image.
const FIXTURE := "res://build/luoyang_entry_20261029l_qa01/entry_READY.json"
const OUTPUT := "res://build/luoyang_entry_20261029l_qa01/actual/"
var spec: Dictionary={}
var checks:=0
var errors: Array[String]=[]
var records: Array=[]
var began:=0
var input_ticks:=0
var sources: Dictionary={}
var saves: Dictionary={}
var router: Node
var loading: Node
var dialogs: Node
func _initialize() -> void:_run.call_deferred()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("LUOYANG_ENTRY_FAIL ",label)
	return ok
func facts(paths: Array) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(path):result[path]={"exists":false};continue
		var file:=FileAccess.open(path,FileAccess.READ)
		result[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result
func actual_state() -> Dictionary:
	var game: Node=root.get_node("GameState")
	var player: Resource=game.get("player") as Resource
	var party: Array=[]
	for member: Resource in game.get("party"):party.append(str(member.get_instance_id()))
	return {"player_instance":str(player.get_instance_id()),"hp":player.get("hp"),"mp":player.get("mp"),"gold":game.get("gold"),"party_instances":party}
func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(raw is Dictionary and raw.get("ready")==true,"EXACT_REPAIRED_ENTRY_FIXTURE"):finish();return
	spec=raw;sources=facts(spec.fixed_sources.keys());saves=facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:
		if not need(sources[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path):finish();return
	router=root.get_node("SceneRouter");loading=root.get_node("LoadingManager");dialogs=root.get_node("DialogPlayer")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_PAUSED_NO_USER_SAVE_READ_OR_WRITE"):finish();return
	var state: Dictionary=actual_state()
	if not need(router.call("go_field_smart",&"world_map_jianghu",Vector2(4000,2594.4912)/Vector2(12288,8192),"",15,-1)==true,"PUBLIC_ORIGINAL_WORLD_DOOR_SETUP_NOT_LONG_DISTANCE_TRAVEL"):finish();return
	var world: Node=await wait_field("world_map_jianghu",20)
	if world==null:finish();return
	var doors: Array=[]
	for door: Node in world.get("_exit_nodes"):
		if String(door.get("target_scene_id"))=="ch4_s0_luoyang_gate":doors.append(door)
	for _tick: int in range(3):await physics_frame
	if not need(doors.size()==1 and doors[0].call("can_enter")==true,"ORIGINAL_LUOYANG_DOOR_UNIQUE_AND_REAL_CAN_ENTER"):finish();return
	var world_actor: Node2D=world.get("_player") as Node2D
	records.append({"world_source_foot":world_actor.position,"target_scene":doors[0].get("target_scene_id"),"target_spawn":doors[0].get("target_spawn_pos"),"setup_scope":"public_original_world_door_nearfoot_not_whole_world_walk"})
	var depart:=Time.get_ticks_msec()
	await key(KEY_SPACE,1)
	var gate: Node=await wait_field("ch4_s0_luoyang_gate",30)
	if gate==null:finish();return
	var actor: Node2D=gate.get("_player") as Node2D
	if not need(actor!=null and actual_state()==state,"GATE_HAS_REAL_ACTOR_AND_SAME_PLAYER_HP_MP_GOLD_PARTY"):finish();return
	var before: Vector2=actor.position
	await key(KEY_D,4)
	var after: Vector2=actor.position
	if not need(after.distance_to(before)>=24 and after.distance_to(before)<=48 and after.x>before.x,"ONE_TRUE_SHORT_APPROX32PX_MOVE_NO_ACTOR_ASSIGNMENT"):finish();return
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path:=OUTPUT+str(OS.get_process_id())+"/luoyang_gate_after_entry.png"
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NORMAL_NATIVE_GATE_IMAGE"):finish();return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(image.save_png(path)==OK,"SAVE_GATE_NATIVE_IMAGE"):finish();return
	records.append({"gate_arrival_foot":before,"after_true_short_walk":after,"departure_to_capture_ms":Time.get_ticks_msec()-depart,"image":path,"image_sha256":FileAccess.get_sha256(path),"long_distance_or_whole_city_art_claim":false})
	need(actual_state()==state,"CURRENT_PLAYER_STATE_PRESERVED_AFTER_GATE_SHORT_MOVE")
	finish()
func wait_field(id: String,seconds: int) -> Node:
	var start:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<seconds*1000 and Time.get_ticks_msec()-began<60000:
		await process_frame
		var field: Node=current_scene
		if field==null or not field.has_method("get_field_loading_state"):continue
		var state: Dictionary=field.call("get_field_loading_state")
		if String(state.get("scene_id"))!=id:continue
		if state.get("failed")==true:diagnose(field,"FIELD_LOAD_FAILED:"+id);return null
		if state.get("complete")!=true or loading.get("_transition_active")==true or loading.get("_external_active")==true:continue
		var actor: Node=field.get("_player")
		if not is_instance_valid(actor) or actor.get("can_move")!=true or dialogs.call("is_playing")==true:continue
		await physics_frame;await RenderingServer.frame_post_draw
		return field
	diagnose(current_scene,"ENTRY_BOUND_"+str(seconds)+"S:"+id);return null
func diagnose(field: Node,label: String) -> void:
	need(false,label)
	var detail: Dictionary={"failure":label,"router_current_field":router.call("get_current_field_id"),"actual_scene_file":field.scene_file_path if field!=null else "","loading_transition":loading.get("_transition_active"),"loading_external":loading.get("_external_active")}
	if field!=null and field.has_method("get_field_loading_state"):detail.field_loading=field.call("get_field_loading_state")
	var culture: Variant=load("res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd")
	if culture!=null:detail.culture_readiness=culture.call("readiness")
	records.append(detail)
func key(code: int,ticks: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events();await process_frame
	for _tick: int in range(ticks):await physics_frame;input_ticks+=1
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
	Input.parse_input_event(event);Input.flush_buffered_events();await process_frame;await physics_frame
func finish() -> void:
	for code: int in [KEY_SPACE,KEY_D]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false;Input.parse_input_event(event)
	Input.flush_buffered_events()
	if not sources.is_empty():need(sources==facts(sources.keys()),"FROZEN_SOURCE_FIRST_FINAL")
	if not saves.is_empty():need(saves==facts(saves.keys()),"SAVE_HASH_BYTES_SECONDS_SAME_ROOT_EXACT_TICKS_SEPARATE")
	var path:=OUTPUT+str(OS.get_process_id())+"/entry_result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"save_writes":0,"qa_actor_camera_writes":0,"old_failure_reproduced":false,"three_town_or_whole_city_matrices_replayed":false,"fixture_sha256":FileAccess.get_sha256(FIXTURE)},"\t"));file.close()
	print("[LuoyangEntry] ",checks," checks / ",errors.size()," failures; ",path);quit(0 if errors.is_empty() else 1)
