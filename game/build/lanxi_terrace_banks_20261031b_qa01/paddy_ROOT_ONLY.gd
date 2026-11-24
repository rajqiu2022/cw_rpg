extends SceneTree
## Root-owned process only. Public local setups, not continuous town travel.
const ID := &"openworld_lanxi_zhai"
const SIZE := Vector2(7600,5200)
const FIXTURE := "res://build/lanxi_terrace_banks_20261031b_qa01/actual_inputs_READY.json"
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
	await create_timer(60.0,true,false,true).timeout
	if not done:need(false,"HARD60S");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("PADDY31B_FAIL ",label)
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
func debug() -> Dictionary:return town.call("get_paddy_passage_debug")
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
		return need(town.has_method("get_paddy_passage_debug") and int(debug().actor_level)==(1 if at is Vector2 else 0) and int(debug().active_ramp)==-1,"NATIVE_EXPECTED_LAYER_READY")
	records.append({"router_id":router.call("get_current_field_id"),"scene":str(current_scene),"loading_metrics":root.get_node("LoadingManager").get("_field_preload_metrics")})
	return need(false,"PUBLIC_SETUP_TIMEOUT")
func walk(at: Vector2) -> bool:
	var start: Vector2=actor.global_position
	for frame: int in range(220):
		var delta: Vector2=at-actor.global_position
		if delta.length()<=4.5:break
		key((KEY_D if delta.x>0 else KEY_A) if absf(delta.x)>absf(delta.y) else (KEY_S if delta.y>0 else KEY_W));await tick()
	key(KEY_NONE);await tick()
	records.append({"real_short_leg_start":start,"target":at,"end":actor.global_position})
	return need(actor.global_position.distance_to(at)<=6.0,"REAL_DRY_ENDPOINT_OR_CENTER_SHORT_LEG")
func finish() -> void:
	if done:return
	key(KEY_NONE);done=true
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"input_events":inputs,"records":records,"scope":"one continuous L1 paddy left/right short leg, adjacent old cliff negative, one new-body restore and one image; no old bridge/stairs/World/sect tour; no save APIs"},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
func _run() -> void:
	directory="res://build/lanxi_terrace_banks_20261031b_qa01/actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
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
	var proposal: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(fixture.proposal))
	var static_ok: bool=proposal.rows.size()==4 and proposal.west_path.failures.is_empty()
	for row: Dictionary in proposal.rows:
		static_ok=static_ok and int(row.visible_alpha8_source_pixels_checked)==564110 and int(row.alpha8_points_outside_projected_L1)==0 and row.native_bank_alpha8_overlaps.is_empty() and row.new_body_overlaps_other_static.is_empty()
	records.append({"inherited_System_static_alpha_body_and159_full35_samples_not_GPU_recomputed":proposal})
	if not need(static_ok,"INHERITED_PINNED_STATIC_ALPHA_AND_BODY_ZERO_OVERLAP"):finish();return
	if not await setup(null):finish();return
	var before: Vector2=vec(fixture.migration.before)
	var after: Vector2=vec(fixture.migration.after)
	if not await setup(before):finish();return
	var migrated: Dictionary=debug().migration;sample("only_new_paddy_body_old_legal_restore")
	if not need(migrated.get("migrated",false) and Vector2(migrated.before).distance_to(before)<.03 and Vector2(migrated.after).distance_to(after)<.03 and actor.global_position.distance_to(after)<.03,"DECLARED_ONLY_NEW_BODY_RESTORE"):finish();return
	if not await setup(Vector2(6890,2700)):finish();return
	var state: Dictionary=debug()
	var shape: CollisionShape2D=actor.get_node("CollisionShape2D") as CollisionShape2D
	if not need(shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size.is_equal_approx(Vector2(34,24)) and actor.collision_mask==40 and int(state.actor_level)==1 and absf(float(state.actor_height)-120)<.01,"ACTUAL34X24_L1_HEIGHT120_MASK40"):finish();return
	var rows: Array=state.paddies
	if not need(rows.size()==4,"FOUR_PADDY_RUNTIME_ROOTS"):finish();return
	for expected: Dictionary in proposal.rows:
		var found: Dictionary={}
		for row: Dictionary in rows:
			if String(row.name)==String(expected.name):found=row;break
		if not need(not found.is_empty(),"PADDY_PRESENT:"+String(expected.name)):finish();return
		var at: Vector2=vec(expected.foot)
		var art: Vector2=vec(expected.new_art_local_position)
		var item: Node2D=town.get_node("Town/"+String(expected.name)) as Node2D
		var outline: CollisionPolygon2D=item.get_node("Body/Outline") as CollisionPolygon2D
		var body_ok: bool=outline.polygon.size()==expected.new_body_world_polygon.size()
		if body_ok:
			for i: int in range(outline.polygon.size()):
				body_ok=body_ok and outline.to_global(outline.polygon[i]).distance_to(vec(expected.new_body_world_polygon[i]))<.02
		var scale_factor: float=float(expected.scale)
		if not need(Vector2(found.ground_foot).distance_to(at)<.02 and int(found.level)==1 and absf(float(found.height)-120)<.01 and Vector2(found.art_scale).distance_to(Vector2.ONE*scale_factor)<.001 and Vector2(found.art_position).distance_to(art)<.03 and body_ok,"FOUR_PADDY_FOOT_SCALE_ART_ANCHOR_BODY:"+String(expected.name)):finish();return
	var journey: Array=[]
	if not await across(Vector2(6100,2700),KEY_A,journey) or not await across(Vector2(6890,2700),KEY_D,journey):finish();return
	records.append({"same_instance_continuous_paddy_inside_left_then_right":journey,"no_setup_between_legs":true})
	var cliff: Dictionary=fixture.cliff
	if not await setup(vec(cliff.start)):finish();return
	shape=actor.get_node("CollisionShape2D") as CollisionShape2D
	var start: Vector2=actor.global_position;var hits: Array[String]=[];var stayed_inside := true
	var edge_start: Vector2=vec(cliff.edge_start);var edge_end: Vector2=vec(cliff.edge_end)
	var code: Key=KEY_D if String(cliff.key)=="D" else KEY_A
	for frame: int in range(30):
		key(code);await tick()
		var half: Vector2=(shape.shape as RectangleShape2D).size*.5
		for corner: Vector2 in [Vector2(-half.x,-half.y),Vector2(half.x,-half.y),Vector2(half.x,half.y),Vector2(-half.x,half.y)]:
			var point: Vector2=shape.global_transform*corner
			stayed_inside=stayed_inside and (edge_end-edge_start).cross(point-edge_start)*float(cliff.interior_sign)>=-.1
		for i: int in range(actor.get_slide_collision_count()):
			var collider: Object=actor.get_slide_collision(i).get_collider()
			if collider is Node:
				var path: String=String(collider.get_path())
				if not hits.has(path):hits.append(path)
	key(KEY_NONE);await tick();sample("adjacent_original_cliff_contact")
	var hit_expected := false
	for path: String in hits:hit_expected=hit_expected or path.ends_with(String(cliff.node_suffix))
	records.append({"old_cliff_negative_start":start,"end":actor.global_position,"collider_paths":hits,"full_actual_foot_stayed_inside_original_edge":stayed_inside,"sloped_cliff_may_slide_not_stationary_wall_oracle":true})
	if not need(hit_expected and stayed_inside and actor.global_position.distance_to(start)>3 and int(debug().actor_level)==1,"ORIGINAL_ADJACENT_CLIFF_STILL_BLOCKS_CROSSING"):finish();return
	if not await setup(Vector2(6495,2700)):finish();return
	await process_frame;await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image();var path: String=directory+"/paddy4_normal.png"
	if need(image!=null and image.save_png(path)==OK,"ONE_NORMAL_PADDY4_AND_BANK_GAP_IMAGE"):records.append({"normal_image":path,"sha256":FileAccess.get_sha256(path)})
	finish()
func vec(value: Array) -> Vector2:return Vector2(float(value[0]),float(value[1]))
func across(target: Vector2,code: Key,journey: Array) -> bool:
	var start: Vector2=actor.global_position;var layer_ok := true;var native_id: int=town.get_instance_id()
	for frame: int in range(180):
		if actor.global_position.distance_to(target)<=4.5:break
		key(code);await tick()
		var state: Dictionary=debug()
		layer_ok=layer_ok and int(state.actor_level)==1 and absf(float(state.actor_height)-120)<.01 and int(state.active_ramp)==-1 and absf(actor.global_position.y-2700)<.1 and town.get_instance_id()==native_id
	key(KEY_NONE);await tick()
	journey.append({"start":start,"target":target,"actual_end":actor.global_position,"same_instance":native_id,"layer1_height120_all_frames":layer_ok})
	return need(layer_ok and actor.global_position.distance_to(target)<6,"REAL_CONTINUOUS_PADDY_A_D_L1_NO_CLIFF_TELEPORT")
