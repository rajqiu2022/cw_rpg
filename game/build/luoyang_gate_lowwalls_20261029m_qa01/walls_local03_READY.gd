extends SceneTree
## Only two retired wall domains. Public near-foot setup, not a World entry replay.
const FIXTURE := "res://build/luoyang_gate_lowwalls_20261029m_qa01/walls_local03_READY.json"
const OUTPUT := "res://build/luoyang_gate_lowwalls_20261029m_qa01/actual/"
const RETIRED := ["finish_i_gate_queue_low_edge_west","finish_i_gate_queue_low_edge_east"]
var spec: Dictionary={}
var errors: Array[String]=[]
var checks:=0
var began:=0
var input_ticks:=0
var sources: Dictionary={}
var saves: Dictionary={}
var records: Array=[]
func _initialize() -> void:_run.call_deferred()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("GATE_LOW_WALL_FAIL ",label)
	return ok
func facts(paths: Array) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(path):result[path]={"exists":false};continue
		var f:=FileAccess.open(path,FileAccess.READ)
		result[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":f.get_length() if f!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result
func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(raw is Dictionary and raw.get("ready")==true,"FROZEN_TWO_WALL_LOCAL_ONLY_FIXTURE"):finish();return
	spec=raw;sources=facts(spec.fixed_sources.keys());saves=facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:
		if not need(sources[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path):finish();return
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_PAUSED_NO_SAVE_READ_OR_WRITE"):finish();return
	if not need(root.get_node("SceneRouter").call("go_field_smart",&"ch4_s0_luoyang_gate",Vector2(500,1490)/Vector2(3072,2048),"",15,3)==true,"PUBLIC_GATE_LOCAL_NEARFOOT_SETUP_NOT_WORLD_JOURNEY"):
		records.append({"public_city_preparation_state":root.get_node("SceneRouter").call("get_public_city_preparation_state")})
		finish();return
	var field: Node=await ready_field()
	if field==null:finish();return
	var actor: Node2D=field.get("_player") as Node2D
	if not need(actor!=null and actor.position.distance_to(Vector2(500,1490))<=1,"ACTUAL_AUTHORIZED_LOCAL_SETUP_FOOT"):finish();return
	var found: Dictionary={}
	for sprite: Node in field.get("_scene_object_nodes"):found[String(sprite.name)]=true
	for id: String in RETIRED:
		if not need(not found.has("SceneObject_"+id),"RETIRED_WALL_RENDER_NODE_ABSENT:"+id):finish();return
	for id: String in ["notice_pavilion","seven26c_gate_west_return_south","seven26c_gate_west_return_north","seven26c_gate_west_waiting_front","seven26c_gate_east_transfer_front"]:
		if not need(found.has("SceneObject_"+id),"ADJACENT_NOTICE_AND_REAL_COURT_BOUNDARY_RETAINED:"+id):finish();return
	var waiting:=0
	for npc: Node in field.get("_npc_nodes"):
		if String(npc.get("npc_name"))=="候检旅人":waiting+=1
	if not need(waiting==2,"BOTH_EXISTING_WAITING_TRAVELLERS_RETAINED"):finish();return
	for point: Vector2 in [Vector2(500,1447),Vector2(900,1447)]:
		if not need(shape_clear(field,actor,point),"OLD_WALL_DOMAIN_FULL_ACTUAL_PLAYER_SHAPE_CLEAR:"+str(point)):finish();return
	var steps: Array=[{ "key":KEY_W,"ticks":10,"end":Vector2(500,1410) },{ "key":KEY_S,"ticks":10,"end":Vector2(500,1490) },{ "key":KEY_D,"ticks":50,"end":Vector2(900,1490) },{ "key":KEY_W,"ticks":10,"end":Vector2(900,1410) }]
	for step: Dictionary in steps:
		var before: Vector2=actor.position
		await key(step.key,step.ticks)
		records.append({"key":step.key,"physics_ticks":step.ticks,"before":before,"after":actor.position,"expected_end":step.end})
		if not need(actor.position.distance_to(step.end)<=16,"REAL_LOCAL_CROSS_OR_LINK_SEGMENT:"+str(step.end)):finish();return
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path:=OUTPUT+str(OS.get_process_id())+"/two_low_walls_removed.png"
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NATIVE_LOCAL_WALL_IMAGE"):finish();return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if need(image.save_png(path)==OK,"SAVE_ONE_LOCAL_NATIVE_IMAGE"):records.append({"image":path,"sha256":FileAccess.get_sha256(path)})
	finish()
func ready_field() -> Node:
	while Time.get_ticks_msec()-began<30000:
		await process_frame
		var field: Node=current_scene
		if field==null or not field.has_method("get_field_loading_state"):continue
		var state: Dictionary=field.call("get_field_loading_state")
		if String(state.get("scene_id"))!="ch4_s0_luoyang_gate":continue
		if state.get("failed")==true:need(false,"LOCAL_GATE_LOADING_REFUSED");return null
		if state.get("complete")!=true or root.get_node("LoadingManager").get("_transition_active")==true or root.get_node("LoadingManager").get("_external_active")==true:continue
		if not is_instance_valid(field.get("_player")) or field.get("_player").get("can_move")!=true:continue
		await physics_frame;await RenderingServer.frame_post_draw
		return field
	need(false,"LOCAL_GATE_SETUP_30S_BOUND");return null
func shape_clear(field: Node,actor: Node2D,point: Vector2) -> bool:
	var shape: CollisionShape2D=actor.get_node("CollisionShape2D") as CollisionShape2D
	var world: Node2D=field.get("world_container") as Node2D
	var query:=PhysicsShapeQueryParameters2D.new()
	var transform: Transform2D=shape.global_transform
	transform.origin+=world.to_global(point)-actor.global_position
	query.shape=shape.shape;query.transform=transform
	query.collision_mask=actor.get("collision_mask");query.exclude=[actor.call("get_rid")];query.collide_with_areas=false;query.collide_with_bodies=true;query.margin=0.0
	return actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()
func key(code: int,ticks: int) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=true
	Input.parse_input_event(event);Input.flush_buffered_events();await process_frame
	for _tick: int in range(ticks):await physics_frame;input_ticks+=1
	event=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false
	Input.parse_input_event(event);Input.flush_buffered_events();await process_frame;await physics_frame
func finish() -> void:
	for code: int in [KEY_W,KEY_S,KEY_D]:
		var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=false;Input.parse_input_event(event)
	Input.flush_buffered_events()
	if not sources.is_empty():need(sources==facts(sources.keys()),"FROZEN_SOURCE_FIRST_FINAL")
	if not saves.is_empty():need(saves==facts(saves.keys()),"SAVES_HASH_BYTES_SECONDS_SAME_ROOT_EXACT_TICKS_SEPARATE")
	var path:=OUTPUT+str(OS.get_process_id())+"/walls_result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":input_ticks,"save_writes":0,"actor_camera_writes":0,"setup":"public_direct_gate_nearfoot_not_world_entry","old_entry_three_towns_or_whole_city_replayed":false,"fixture_sha256":FileAccess.get_sha256(FIXTURE)},"\t"));file.close()
	print("[GateLowWalls] ",checks," checks / ",errors.size()," failures; ",path);quit(0 if errors.is_empty() else 1)
