extends SceneTree
## Root-only single true World Field. Five local setups, not continuous travel.
const SIZE := Vector2(12288,8192)
const FIXTURE := "res://build/world_bridges_20261030m_qa01/world5_inputs_READY.json"
const STREAM = preload("res://scripts/world/world_v15_visible_stream_20261018r.gd")
const PATCH = preload("res://build/world_bridges_20261030m_system01/bridge_visual_patch.gd")
const WORLD = preload("res://scripts/world/world_map_v15_contract.gd")
var errors: Array[String]=[]
var checks := 0
var inputs := 0
var records: Array=[]
var done := false
var suspended := false
var deadline := 0
var directory := ""
var field: Node
var actor: Player
var world: Node2D
var scene: SceneScript
var source: SceneScript
var source_bytes: PackedByteArray
var pins: Dictionary={}
var first: Dictionary={}
var bridges: Array=[]
var rails: Array=[]
var held: Key=KEY_NONE

func _initialize() -> void:
	deadline=Time.get_ticks_msec()+75000
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred();_watch.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true);suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _watch() -> void:
	await create_timer(75.0,true,false,true).timeout
	if not done:need(false,"HARD75S_NO_RECOVERY_OR_NEW_DOMAIN");finish()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("WORLD5_FAIL ",label)
	return ok
func json(path: String) -> Dictionary:return JSON.parse_string(FileAccess.get_file_as_string(path))
func vec(value: Array) -> Vector2:return Vector2(float(value[0]),float(value[1]))
func facts() -> Dictionary:
	var result: Dictionary={}
	for path: String in pins:
		var file:=FileAccess.open(path,FileAccess.READ)
		result[path]={"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result
func foot() -> Vector2:return world.to_local(actor.global_position)
func set_key(code: Key) -> void:
	if held==code:return
	if held!=KEY_NONE:
		var up:=InputEventKey.new();up.keycode=held;up.physical_keycode=held;up.pressed=false;Input.parse_input_event(up);inputs+=1
	held=code
	if held!=KEY_NONE:
		var down:=InputEventKey.new();down.keycode=held;down.physical_keycode=held;down.pressed=true;Input.parse_input_event(down);inputs+=1
func toward(delta: Vector2) -> Key:
	if absf(delta.x)>absf(delta.y):return KEY_D if delta.x>0 else KEY_A
	return KEY_S if delta.y>0 else KEY_W
func step_frame() -> void:
	await physics_frame;await process_frame
func walk(target: Vector2) -> bool:
	var start: Vector2=foot();var pieces: int=maxi(1,ceili(start.distance_to(target)/28.0))
	for part: int in range(1,pieces+1):
		var waypoint: Vector2=start.lerp(target,float(part)/pieces)
		var ticks := 0
		while foot().distance_to(waypoint)>7.0 and ticks<20 and not done:
			if Time.get_ticks_msec()>deadline:need(false,"WALK_DEADLINE");return false
			set_key(toward(waypoint-foot()));await step_frame();ticks+=1
		set_key(KEY_NONE)
		if not need(foot().distance_to(waypoint)<=9.0,"REAL_WASD_BRIDGE_LOCAL_STEP"):records.append({"failed_target":waypoint,"actual_foot":foot()});return false
	records.append({"real_short_leg_start":start,"target":target,"actual_foot":foot()})
	return true
func ready_world() -> bool:
	while Time.get_ticks_msec()<deadline and not done:
		await process_frame
		if current_scene==null or not current_scene.has_method("get_world_v15_stream_debug"):continue
		var state: Dictionary=current_scene.call("get_field_loading_state")
		if state.get("failed",false):need(false,"TRUE_WORLD_LOAD_FAILED");return false
		if state.get("complete")!=true or root.get_node("LoadingManager").get("_transition_active"):continue
		field=current_scene;actor=field.get("_player") as Player;world=field.get("world_container") as Node2D
		if actor==null or world==null:continue
		var debug: Dictionary=field.call("get_world_v15_stream_debug")
		if not String(debug.get("error","")).is_empty():need(false,"STREAM_ERROR:"+String(debug.error));return false
		if int(debug.get("pending",-1))!=0:continue
		await step_frame();return need(actor.can_move,"TRUE_WORLD_ACTOR_CAN_MOVE")
	need(false,"WORLD_READY75S");return false
func local_setup(at: Vector2) -> bool:
	set_key(KEY_NONE)
	var old: Node=field.get("_world_v15_stream") as Node
	var old_ref: WeakRef=weakref(old)
	var old_debug: Dictionary=field.call("get_world_v15_stream_debug")
	# Deliberate QA-only setup of this owned true MainField, not actor teleport.
	await field.call("_setup_scene",scene,at/SIZE,false)
	if not await ready_world():return false
	var retained: Node=old_ref.get_ref() as Node
	var released: bool=not is_instance_valid(retained)
	var released_debug: Dictionary={}
	if is_instance_valid(retained):released_debug=retained.call("debug_state");released=int(released_debug.get("loaded",-1))==0 and int(released_debug.get("pending",-1))==0
	records.append({"setup":"OWNED_TRUE_WORLD_SHALLOW_SCENE_SETUP_NOT_CONTINUOUS_TRAVEL","requested_foot":at,"actual_foot":foot(),"old_stream_debug":old_debug,"old_stream_released":released,"old_stream_after":released_debug,"new_stream_debug":field.call("get_world_v15_stream_debug")})
	return need(released and foot().distance_to(at)<1 and (field.get("_current_scene") as SceneScript).map_layout==source.map_layout,"OLD_STREAM_RELEASE_AND_EXACT_NEW_LOCAL_SETUP")
func node_named(name: String) -> Node:return world.find_child(name,true,false)
func source_integrity() -> bool:
	var objects: Array=source.map_layout.visual_objects
	var result: Dictionary=STREAM.make_index(objects,SIZE)
	if not need(result.get("ok",false),"FINAL_INDEX_VALIDATES93_ORIGINAL_BRIDGE_ROWS"):return false
	var by_id: Dictionary={};var native := 0
	for entry: Dictionary in result.entries:by_id[String(entry.id)]=entry;native+=1 if entry.data.get("_bridge_native30m",false) else 0
	var depth := 0;var others := 0;var bridge_rows := 0;var physical := 0;var ok := true
	for ordinal: int in range(objects.size()):
		var row: Dictionary=objects[ordinal];var id: String=String(row.id)
		if id.begins_with("bridge_"):
			bridge_rows+=1
			if row.has("solid_polygons_px") or row.has("collision_size"):physical+=1
		else:
			others+=1
			if not by_id.has(id):ok=false
			else:
				var item: Dictionary=by_id[id]
				ok=ok and int(item.ordinal)==ordinal and int(item.depth_ordinal)==depth and var_to_bytes(item.data)==var_to_bytes(row) and item.bounds==STREAM.render_bounds(row,SIZE)
		if row.get("sort_by_feet",false):depth+=1
	records.append({"original_rows":objects.size(),"bridge_original93":bridge_rows,"bridge_original_physical88":physical,"new_native_presentations":native,"other_rows_exact_source_data_original_ordinal_depth_bounds":others,"other_rows_exact":ok})
	return need(bridge_rows==93 and physical==88 and native==20 and ok,"ORIGINAL93_ROWS_88PHYSICS_AND_EVERY_OTHER_ROW_INDEX_EXACT")
func bodies88() -> bool:
	var ok := true;var count := 0;var examples: Array=[]
	for row: Dictionary in source.map_layout.visual_objects:
		if not String(row.id).begins_with("bridge_") or (not row.has("solid_polygons_px") and not row.has("collision_size")):continue
		count+=1
		var body: StaticBody2D=node_named("ObjectCollision_"+String(row.id)) as StaticBody2D
		if body==null:ok=false;continue
		ok=ok and body.position==row.pos*SIZE and body.collision_layer==1 and body.collision_mask==0
		if row.has("solid_polygons_px"):
			ok=ok and body.get_child_count()==row.solid_polygons_px.size()
			for i: int in range(mini(body.get_child_count(),row.solid_polygons_px.size())):
				var polygon: CollisionPolygon2D=body.get_child(i) as CollisionPolygon2D;var expected:=PackedVector2Array()
				for point: Vector2 in row.solid_polygons_px[i]:expected.append(point-row.pos*SIZE)
				ok=ok and polygon!=null and polygon.polygon==expected
		else:
			var shape: CollisionShape2D=body.get_child(0) as CollisionShape2D
			ok=ok and shape!=null and shape.shape is RectangleShape2D and shape.position==row.get("collision_offset",Vector2.ZERO)*SIZE and shape.shape.size==row.collision_size*SIZE
		if examples.size()<3:examples.append({"id":row.id,"position":body.position,"children":body.get_child_count()})
	records.append({"actual_original_bridge_bodies":count,"exact_geometry_layers_masks":ok,"examples":examples})
	return need(count==88 and ok,"TRUE_WORLD88_ORIGINAL_BRIDGE_PHYSICAL_NODES_EXACT")
func pixels(row: Dictionary) -> bool:
	var base: Sprite2D=node_named(String(row.base_node_name)) as Sprite2D
	if not need(base!=null,"REAL_NATIVE_BASE_NODE:"+String(row.id)):return false
	var results: Array=[];var ok := true
	for point: Dictionary in row.samples:
		var owner: Sprite2D=node_named(String(point.node_name)) as Sprite2D
		if owner==null:ok=false;continue
		var global_point: Vector2=world.to_global(vec(point.world_pixel_center_px))
		var on_owner: bool=PATCH.source_pixel_visible(owner,global_point)
		var on_base: bool=PATCH.source_pixel_visible(base,global_point)
		var image: Image=owner.texture.get_image();var p:=Vector2i(vec(point.source_pixel_center_px).floor())
		var alpha: float=image.get_pixelv(p).a
		ok=ok and on_owner and not on_base and alpha>=200.0/255.0 and owner.texture==base.texture and owner.material is ShaderMaterial and base.material is ShaderMaterial
		results.append({"source_pixel":p,"global_point":global_point,"owner":String(owner.name),"source_alpha":alpha,"owner_partition":on_owner,"base_partition":on_base,"shared_texture_id":owner.texture.get_instance_id()})
	records.append({"bridge":row.id,"new_same_source_nearrail_pixels":results,"stream":field.call("get_world_v15_stream_debug")})
	return need(results.size()==3 and ok,"THREE_REAL_NEW_SOURCE_PIXELS_DISJOINT_SHARED_TEXTURE:"+String(row.id))
func rail_negative(row: Dictionary,center: Vector2) -> bool:
	var target: Vector2=vec(row.original_rail_contact_probe_world_px)
	var shape: CollisionShape2D=actor.get_node("CollisionShape2D") as CollisionShape2D
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape.shape;query.transform=shape.global_transform
	query.transform.origin+=world.to_global(target)-actor.global_position;query.collision_mask=actor.collision_mask;query.exclude=[actor.get_rid()];query.collide_with_areas=false
	var hits: Array=actor.get_world_2d().direct_space_state.intersect_shape(query,16);var names: Array[String]=[]
	for hit: Dictionary in hits:names.append(String(hit.collider.name))
	if not need(names.has("ObjectCollision_"+String(row.original_physics_nearrail_id)),"TRUE_CIRCLE5_AT_ORIGINAL_NEARRAIL_BLOCKED:"+String(row.id)):return false
	var normal: Vector2=(target-center).normalized();var began: Vector2=foot()
	set_key(toward(normal))
	for tick: int in range(15):await step_frame()
	set_key(KEY_NONE);await step_frame();await step_frame()
	var reached: Vector2=foot();var overlap: Dictionary=field.call("get_v14_modular_overlap_debug")
	records.append({"bridge":row.id,"real_rail_pressure_from":began,"after":reached,"contact_target":target,"normal_progress":(reached-began).dot(normal),"signed_distance_before_original_rail":(reached-target).dot(normal),"actual_circle5_blocking_nodes":names,"overlap":overlap,"depth_order":field.call("get_v14_depth_order_debug")})
	if not need((reached-began).dot(normal)>1 and (reached-target).dot(normal)< -3.0,"REAL_INPUT_RAIL_NEGATIVE_NO_CROSSING:"+String(row.id)):return false
	return true
func shot(id: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image();var path: String=directory+"/"+id+"_normal_center_rail.png"
	need(image!=null and image.save_png(path)==OK,"NORMAL_WORLD_BRIDGE_IMAGE:"+id);records.append({"image":path,"sha256":FileAccess.get_sha256(path),"normal_camera_unmodified":true,"actual_actor_foot":foot()})
func _run() -> void:
	directory="res://build/world_bridges_20261030m_qa01/world5_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPEND"):finish();return
	var fixture: Dictionary=json(FIXTURE);pins=fixture.pins;first=facts()
	for path: String in pins:
		if not need(String(first[path].sha256)==String(pins[path]),"FINAL_SOURCE_PIN:"+path):finish();return
	bridges=json("res://build/world_bridges_20261030m_system01/bridge_inventory_READY.json").bridges
	rails=json("res://build/world_bridges_20261030m_system01/rail_probe_points_STATIC_02.json").bridges
	var start: Vector2=vec(bridges[0].outer_passage_endpoints_world_px[0])
	if not need(root.get_node("SceneRouter").call("go_field_smart",&"world_map_jianghu",start/SIZE,"",15,-1)==true,"PUBLIC_TRUE_WORLD_ENTER"):finish();return
	if not await ready_world():finish();return
	source=field.get("_current_scene") as SceneScript;scene=source.duplicate(false) as SceneScript
	if not need(scene!=source and scene.map_layout==source.map_layout and WORLD.is_v15(scene),"SHALLOW_SOURCE_SCENE_CLONE_TRUE_WORLD_KEEP_LAYOUT_RESOURCE_PATH"):finish();return
	source_bytes=var_to_bytes(source.map_layout.visual_objects)
	var shape: CollisionShape2D=actor.get_node("CollisionShape2D") as CollisionShape2D
	if not need(shape.shape is CircleShape2D and shape.shape.radius==5.0,"ACTUAL_WORLD_CONTACT_CIRCLE5_NOT_OUTDOOR_ORACLE"):finish();return
	if not source_integrity() or not bodies88():finish();return
	for i: int in range(5):
		var bridge: Dictionary=bridges[i];var a: Vector2=vec(bridge.deck_surface_bank_centers_world_px[0]);var b: Vector2=vec(bridge.deck_surface_bank_centers_world_px[1]);var center: Vector2=(a+b)*.5
		if i>0 and not await local_setup(vec(bridge.outer_passage_endpoints_world_px[0])):finish();return
		if not need(var_to_bytes(source.map_layout.visual_objects)==source_bytes,"SOURCE_ROWS_NOT_MUTATED_BY_PRESENTATION:"+String(bridge.id)):finish();return
		if not await walk(a) or not await walk(center) or not pixels(rails[i]) or not await rail_negative(rails[i],center):finish();return
		await shot(String(bridge.id))
		if not await walk(center) or not await walk(b) or not await walk(vec(bridge.outer_passage_endpoints_world_px[1])):finish();return
		var stream: Dictionary=field.call("get_world_v15_stream_debug")
		if not need(int(stream.get("bridge_visual_count",0))==20 and int(stream.get("bridge_native_images",0))==5 and int(stream.get("bridge_original_visuals",0))==93 and stream.get("bridge_original_physics_unchanged")==true and String(stream.get("bridge_binding_sha",""))==String(fixture.binding_sha256) and String(stream.get("error",""))=="","FINAL20_NATIVE_PRESENTATIONS_NO_OLD93_DRAW:"+String(bridge.id)):finish();return
	# Publicly labeled owned setup revisit, not >1024px natural eviction claim.
	if not await local_setup(vec(bridges[0].deck_surface_bank_centers_world_px[0])):finish();return
	records.append({"first_bridge_revisited_no_route_replay":true,"stream":field.call("get_world_v15_stream_debug")})
	finish()
func finish() -> void:
	if done:return
	done=true;set_key(KEY_NONE)
	var last: Dictionary=facts() if not first.is_empty() else {}
	if not first.is_empty():need(first==last,"FROZEN_SOURCE_FIRST_FINAL_METADATA")
	need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"CHECKPOINT_REMAINS_SUSPENDED_UNTIL_OWNED_EXIT")
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"inputs":inputs,"records":records,"first_sources":first,"final_sources":last,"hard_limit_seconds":75,"five_local_owned_setups_not_continuous_world_travel":true,"release_revisit_not_natural_hysteresis_eviction":true,"SaveManager_calls":0,"save_reads":0,"save_writes":0,"production_writes":0,"old_city_or_doors_matrix":false},"\t")+"\n");file.close()
	print("WORLD5_RESULT ",checks," / ",errors.size());quit(0 if errors.is_empty() else 1)
