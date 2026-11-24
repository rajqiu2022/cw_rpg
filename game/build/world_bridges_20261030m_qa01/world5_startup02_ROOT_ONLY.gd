extends "res://build/world_bridges_20261030m_qa01/world5_ROOT_ONLY.gd"
## Startup residual only; first41/1 retained. If ready, same-process unrun five-bridge leg.
const START_FIXTURE := "res://build/world_bridges_20261030m_qa01/world5_startup02_inputs_READY.json"
var prepared_index: Dictionary={}
var startup_began := 0

func safe(value: Variant,depth: int=0) -> Variant:
	if depth>5:return "<depth-limit>"
	if value==null:return null
	if value is WeakRef:
		var reference: Object=value.get_ref()
		return {"kind":"WeakRef","valid":is_instance_valid(reference),"node_path":String(reference.get_path()) if reference is Node and reference.is_inside_tree() else ""}
	if value is Node:return node_info(value)
	if value is Resource:return {"kind":value.get_class(),"resource_path":value.resource_path}
	if value is Dictionary:
		var object: Dictionary={}
		for key: Variant in value:object[String(key)]=safe(value[key],depth+1)
		return object
	if value is Array:
		var array: Array=[]
		for item: Variant in value:array.append(safe(item,depth+1))
		return array
	if typeof(value) in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING,TYPE_STRING_NAME]:return value
	return str(value)
func node_info(node: Node) -> Dictionary:
	var script: Script=node.get_script() as Script
	return {"path":String(node.get_path()) if node.is_inside_tree() else String(node.name),"type":node.get_class(),"script":script.resource_path if script!=null else "","children":node.get_child_count(),"queued":node.is_queued_for_deletion(),"processing":node.is_processing(),"process_mode":node.process_mode}
func capture_startup(label: String) -> void:
	var loading: Node=root.get_node("LoadingManager")
	var nodes: Array=[]
	for child: Node in root.get_children():
		var item: Dictionary=node_info(child);var children: Array=[]
		for grandchild: Node in child.get_children():children.append(node_info(grandchild))
		item["direct_children"]=children;nodes.append(item)
	var screen: Node=loading.get("_screen") as Node
	var text: Array=[]
	if is_instance_valid(screen):
		for child: Node in screen.find_children("*","",true,false):
			if child is Label or child is RichTextLabel:text.append({"path":String(child.get_path()),"text":String(child.text)})
	var state: Dictionary={}
	if is_instance_valid(current_scene):
		state["node"]=node_info(current_scene)
		if current_scene.has_method("get_field_loading_state"):state["loading"]=safe(current_scene.call("get_field_loading_state"))
		state["loading_profile"]=safe(current_scene.get("_field_loading_profile"))
		if current_scene.has_method("get_world_v15_stream_debug"):state["stream"]=safe(current_scene.call("get_world_v15_stream_debug"))
	var broker: Node=STREAM._broker
	records.append({"startup_label":label,"elapsed_ms":Time.get_ticks_msec()-startup_began,"current_scene":state,"root_nodes":nodes,"router_field":String(root.get_node("SceneRouter").call("get_current_field_id")),"loading_transition_active":loading.get("_transition_active"),"loading_external_active":loading.get("_external_active"),"loading_context":safe(loading.get("_transition_context")),"field_preload_metrics":safe(loading.get("_field_preload_metrics")),"loading_screen_text":text,"broker_rows_value_only":safe(broker.get("rows")) if is_instance_valid(broker) else {}})
func startup_ready() -> bool:
	if not is_instance_valid(current_scene) or not current_scene.has_method("get_world_v15_stream_debug"):return false
	var state: Dictionary=current_scene.call("get_field_loading_state")
	if state.get("complete")!=true or state.get("failed",false) or root.get_node("LoadingManager").get("_transition_active"):return false
	var debug: Dictionary=current_scene.call("get_world_v15_stream_debug")
	if not String(debug.get("error","")).is_empty():return false
	field=current_scene;actor=field.get("_player") as Player;world=field.get("world_container") as Node2D
	return actor!=null and actor.can_move and world!=null and int(debug.get("pending",-1))==0
func startup_shot(label: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image();var path: String=directory+"/"+label+".png"
	if image!=null:image.save_png(path);records.append({"startup_image_not_World_acceptance":path,"sha256":FileAccess.get_sha256(path)})
func _run() -> void:
	directory="res://build/world_bridges_20261030m_qa01/world5_startup02_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	startup_began=Time.get_ticks_msec()
	if not need(suspended,"NEW_PROCESS_EARLIEST_CHECKPOINT_SUSPEND"):finish();return
	var configuration: Dictionary=json(START_FIXTURE);pins=configuration.startup_pins;first=facts()
	var exact := true
	for path: String in pins:exact=exact and String(first[path].sha256)==String(pins[path])
	if not need(exact,"ONLY_REQUIRED_NEW_BUDGET_BINDING_STARTUP_PINS_NO600_RECHECK"):finish();return
	capture_startup("before_prepare_no_Field")
	var preparation_source: SceneScript=load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	if not need(WORLD.is_v15(preparation_source),"REAL_SOURCE_SCENE_CONTRACT_BEFORE_WORLD"):finish();return
	prepared_index=STREAM.make_index(preparation_source.map_layout.visual_objects,SIZE)
	records.append({"same_formal_STREAM_make_index":true,"ok":prepared_index.get("ok",false),"error":String(prepared_index.get("error","")),"entries":prepared_index.get("entries",[]).size(),"bridge_visual_count":prepared_index.get("bridge_visual_count"),"elapsed_ms":Time.get_ticks_msec()-startup_began,"no_Field_instance_created_by_diagnostic":true})
	if not prepared_index.get("ok",false):
		need(false,"EXACT_FORMAL_PRELOAD_INDEX_REFUSAL:"+String(prepared_index.get("error","")));capture_startup("prepare_refused");await startup_shot("prepare_refused_UI_not_World");finish();return
	bridges=json("res://build/world_bridges_20261030m_system01/bridge_inventory_READY.json").bridges
	rails=json("res://build/world_bridges_20261030m_system01/rail_probe_points_STATIC_02.json").bridges
	var start: Vector2=vec(bridges[0].outer_passage_endpoints_world_px[0])
	if not need(root.get_node("SceneRouter").call("go_field_smart",&"world_map_jianghu",start/SIZE,"",15,-1)==true,"PUBLIC_TRUE_WORLD_STARTUP"):capture_startup("public_refused");finish();return
	var thresholds: Array[int]=[2000,5000,10000,18000];var next := 0
	while Time.get_ticks_msec()-startup_began<20000 and not done:
		if startup_ready():capture_startup("ready_continue_same_process");break
		if next<thresholds.size() and Time.get_ticks_msec()-startup_began>=thresholds[next]:
			capture_startup(str(thresholds[next])+"ms");next+=1
		await process_frame
	if not startup_ready():
		capture_startup("20s_startup_not_ready_no_retry");await startup_shot("startup20_loading_not_World")
		need(false,"20S_STARTUP_RAW_DIAGNOSIS_NOT_EMPTY_WATCHDOG");finish();return
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
		if not need(int(stream.get("bridge_visual_count",0))==20 and int(stream.get("bridge_native_images",0))==5 and int(stream.get("bridge_original_visuals",0))==93 and stream.get("bridge_original_physics_unchanged")==true and String(stream.get("bridge_binding_sha",""))==String(configuration.binding_sha256) and String(stream.get("error",""))=="","FINAL20_NATIVE_PRESENTATIONS_NO_OLD93_DRAW:"+String(bridge.id)):finish();return
	# Publicly labeled owned setup revisit, not >1024px natural eviction claim.
	if not await local_setup(vec(bridges[0].deck_surface_bank_centers_world_px[0])):finish();return
	records.append({"first_bridge_revisited_no_route_replay":true,"stream":field.call("get_world_v15_stream_debug")})
	finish()
func source_integrity() -> bool:
	var objects: Array=source.map_layout.visual_objects
	var result: Dictionary=prepared_index
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
