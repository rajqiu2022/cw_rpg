extends SceneTree
## Root-owned process only. Public local setups, not continuous town travel.
const ID := &"openworld_lanxi_zhai"
const SIZE := Vector2(7600,5200)
const FIXTURE := "res://build/lanxi_boardwalk_edges_20261031a_qa01/actual_inputs_READY.json"
var errors: Array[String]=[]
var records: Array=[]
var checks := 0
var inputs := 0
var done := false
var suspended := false
var directory := ""
var field: Node
var town: Node2D
var actor: CharacterBody2D
var router: Node
var held: Key=KEY_NONE
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred();_watch.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true);suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _watch() -> void:
	await create_timer(70.0,true,false,true).timeout
	if not done:need(false,"HARD70S");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("BOARDWALK31A_FAIL ",label)
	return ok
func key(code: Key) -> void:
	if held==code:return
	if held!=KEY_NONE:
		var up:=InputEventKey.new();up.keycode=held;up.physical_keycode=held;up.pressed=false;Input.parse_input_event(up);inputs+=1
	held=code
	if held!=KEY_NONE:
		var down:=InputEventKey.new();down.keycode=held;down.physical_keycode=held;down.pressed=true;Input.parse_input_event(down);inputs+=1
func tick() -> void:
	await physics_frame;await process_frame
func debug() -> Dictionary:return town.call("get_boardwalk_edge_debug")
func sample(label: String) -> void:
	var shape: CollisionShape2D=actor.get_node("CollisionShape2D") as CollisionShape2D
	var terrain: Node=town.get("terrain") as Node
	records.append({"label":label,"raw":debug(),"actual_shape_size":(shape.shape as RectangleShape2D).size if shape.shape is RectangleShape2D else null,"contact_transform":shape.global_transform,"ground_xy":actor.global_position,"projected_foot":terrain.call("projected_foot"),"conservative_restore_foot":Vector2(35,25)})
func setup(at: Variant) -> bool:
	key(KEY_NONE)
	var old: int=current_scene.get_instance_id() if current_scene!=null else 0
	records.append({"public_near_setup_not_continuous_travel":at,"version":1})
	if not need(router.call("go_field_smart",ID,at/SIZE if at is Vector2 else null,"",-1,1)==true,"PUBLIC_VERSION1_SETUP_ACCEPTED"):return false
	var until: int=Time.get_ticks_msec()+12000
	while not done and Time.get_ticks_msec()<until:
		await process_frame
		if current_scene==null or current_scene.get_instance_id()==old or router.call("get_current_field_id")!=ID:continue
		if bool(root.get_node("LoadingManager").get("_transition_active")):continue
		var state: Dictionary=current_scene.call("get_field_loading_state")
		if state.get("failed",false):records.append({"load_failure":state});return need(false,"FIELD_LOAD_FAILED")
		if not state.get("complete",false):continue
		field=current_scene;town=field.get("native_town") as Node2D;actor=field.get("_player") as CharacterBody2D
		if town==null or actor==null or not bool(actor.get("can_move")):continue
		await tick();await tick();sample("public_setup_ready")
		return need(town.has_method("get_boardwalk_edge_debug") and int(debug().actor_level)==0 and int(debug().active_ramp)==-1,"NATIVE_LEVEL0_READY")
	records.append({"router_id":router.call("get_current_field_id"),"scene":str(current_scene),"loading_metrics":root.get_node("LoadingManager").get("_field_preload_metrics")})
	return need(false,"PUBLIC_SETUP_TIMEOUT")
func walk(at: Vector2) -> bool:
	var start: Vector2=actor.global_position
	for frame: int in range(85):
		var delta: Vector2=at-actor.global_position
		if delta.length()<=4.5:break
		key((KEY_D if delta.x>0 else KEY_A) if absf(delta.x)>absf(delta.y) else (KEY_S if delta.y>0 else KEY_W));await tick()
	key(KEY_NONE);await tick()
	records.append({"real_short_leg_start":start,"target":at,"end":actor.global_position})
	return need(actor.global_position.distance_to(at)<=6.0,"REAL_DRY_ENDPOINT_OR_CENTER_SHORT_LEG")
func side(code: Key,origin: Vector2,label: String) -> bool:
	var start: Vector2=actor.global_position;var tail: Vector2=start;var end: Vector2=start
	for frame: int in range(20):
		key(code);await tick()
		if frame==15:tail=actor.global_position
	end=actor.global_position;key(KEY_NONE);await tick();sample(label)
	var shape: CollisionShape2D=actor.get_node("CollisionShape2D") as CollisionShape2D
	var half_y: float=(shape.shape as RectangleShape2D).size.y*.5*absf(shape.global_scale.y)
	var within: bool=end.y+half_y<=origin.y+20.45 if code==KEY_S else end.y-half_y>=origin.y-22.45
	return need(within and end.distance_to(tail)<.05 and end.distance_to(start)>3.0,"TRUE_SIDE_CONTACT_STOP:"+label)
func finish() -> void:
	if done:return
	key(KEY_NONE);done=true
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"input_events":inputs,"records":records,"scope":"two boardwalk edges only, local public setups noncontinuous, bridge3 left WaterLast inherited blocked, no old stairs/World bridges/sect/door tour, no save APIs"},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
func _run() -> void:
	directory="res://build/lanxi_boardwalk_edges_20261031a_qa01/actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND"):finish();return
	router=root.get_node("SceneRouter")
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	for path: String in fixture.pins:
		if not need(FileAccess.get_sha256(path)==String(fixture.pins[path]),"FINAL_NARROW_PIN:"+path):finish();return
	var helper: Script=load(fixture.controller) as Script
	if not need(helper!=null and helper.can_instantiate(),"NEW_CONTROLLER_PARSE"):finish();return
	var packed: PackedScene=load(fixture.scene) as PackedScene
	if not need(packed!=null and packed.can_instantiate(),"NEW_SCENE_PARSE_NO_INSTANCE"):finish();return
	var registry: Script=load(fixture.registry) as Script
	if not need(registry!=null and registry.call("source_valid")==true,"SOURCE_VALID_FAIL_FAST"):finish();return
	if not await setup(null):finish();return
	# One targeted old-legal/new-front-overlap restore, no save file or private helper call.
	if not await setup(Vector2(3650,3586)):finish();return
	var migration: Dictionary=debug().migration;sample("new_front_old_legal_restore")
	if not need(migration.get("migrated",false) and Vector2(migration.before).distance_to(Vector2(3650,3586))<.02 and actor.global_position.distance_to(Vector2(3650,3560))<.02,"EXACT_X_CENTERLINE_Y_RESTORE_ONLY_NEW_EDGE"):finish();return
	if not await setup(Vector2(3650,3660)):finish();return
	if not need(not debug().migration.get("migrated",false) and actor.global_position.distance_to(Vector2(3650,3660))<.02,"FAR_SUPPORTS_LEGAL_GROUND_UNCHANGED"):finish();return
	for origin: Vector2 in [Vector2(3650,3560),Vector2(6740,3930)]:
		if not await setup(origin):finish();return
		var contact: CollisionShape2D=actor.get_node("CollisionShape2D") as CollisionShape2D
		if not need(contact.shape is RectangleShape2D and (contact.shape as RectangleShape2D).size.is_equal_approx(Vector2(34,24)) and actor.collision_mask==24,"ACTUAL34X24_MASK24_NOT_WORLD_CIRCLE5"):finish();return
		if not await side(KEY_S,origin,"south_front"):finish();return
		if not await walk(origin):finish();return
		if not await side(KEY_W,origin,"north_back"):finish();return
		if origin.x==3650:
			if not await setup(Vector2(4190,3560)) or not await walk(Vector2(4260,3560)):finish();return
		else:
			if not await setup(Vector2(6120,3930)) or not await walk(Vector2(6230,3930)):finish();return
			if not await setup(Vector2(7270,3930)) or not await walk(Vector2(7360,3930)):finish();return
	if not await setup(Vector2(3650,3560)):finish();return
	await process_frame;await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image();var path: String=directory+"/boardwalk3_normal.png"
	if need(image!=null and image.save_png(path)==OK,"ONE_NORMAL_FOLLOW_CAMERA_IMAGE"):records.append({"normal_image":path,"sha256":FileAccess.get_sha256(path)})
	finish()
