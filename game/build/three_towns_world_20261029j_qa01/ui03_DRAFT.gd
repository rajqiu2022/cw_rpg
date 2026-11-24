extends SceneTree
## UI-only residual. Public direct town setup, NOT a repeated World journey.
const FIXTURE := "res://build/three_towns_world_20261029j_qa01/ui03_READY.json"
const OUTPUT := "res://build/three_towns_world_20261029j_qa01/ui03_actual/"
var spec: Dictionary={}
var checks:=0
var errors: Array[String]=[]
var records: Array=[]
var began:=0
var router: Node
var loading: Node
var sources: Dictionary={}
var saves: Dictionary={}
var png_count:=0

func _initialize() -> void:_run.call_deferred()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("THREE_TOWNS_UI_FAIL ",label)
	return ok
func point(raw: Array) -> Vector2:return Vector2(float(raw[0]),float(raw[1]))
func facts(paths: Array) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(path):result[path]={"exists":false};continue
		var file:=FileAccess.open(path,FileAccess.READ)
		result[path]={"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file!=null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return result

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not need(raw is Dictionary and raw.get("ready")==true,"FROZEN_UI_ONLY_FIXTURE"):finish();return
	spec=raw
	sources=facts(spec.fixed_sources.keys());saves=facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:
		if not need(sources[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path):finish();return
	router=root.get_node("SceneRouter");loading=root.get_node("LoadingManager")
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED_NO_SAVE_WRITE"):finish();return
	for leg: Dictionary in spec.legs:
		# Normal public setup at the original arrival: no fake entry, actor or camera assignment.
		if not need(router.call("go_field_smart",StringName(leg.id),point(leg.arrival_foot)/point(leg.town_size),"",15,1)==true,"DIRECT_PUBLIC_TOWN_UI_SETUP:"+leg.id):finish();return
		var wrapper: Node=await wait_town(leg)
		if wrapper==null:finish();return
		var native: Node=wrapper.get_node(NodePath(leg.town_node))
		for label: String in ["TopPanel","Title","Status","Hint"]:
			var node: Node=native.get_node_or_null("UI/"+label)
			if not need(node is CanvasItem and not (node as CanvasItem).is_visible_in_tree(),"NATIVE_UI_ACTUALLY_HIDDEN:"+leg.id+":"+label):finish();return
		var detail: Node=native.get_node_or_null("UI/Detail")
		if not need(detail is CanvasItem and detail.has_node("Text") and native.has_method("examine") and native.has_method("enter_hall") and native.has_method("leave_hall") and native.is_processing_unhandled_key_input()==false,"DETAIL_AND_NATIVE_ROOM_METHODS_RETAINED_NO_INTERACTION_REPLAY:"+leg.id):finish();return
		if not await capture(leg):finish();return
	need(png_count==3,"EXACTLY_THREE_UI_RESIDUAL_IMAGES_NO_TRIP_REPLAY")
	finish()

func wait_town(leg: Dictionary) -> Node:
	var start:=Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<20000 and Time.get_ticks_msec()-began<80000:
		await process_frame
		var field: Node=current_scene
		if field==null or String(field.scene_file_path)!=String(leg.wrapper_scene):continue
		if loading.get("_transition_active")==true or loading.get("_external_active")==true:continue
		var native: Node=field.get_node_or_null(NodePath(leg.town_node))
		if native==null or native.get("controls_enabled")!=true:continue
		await RenderingServer.frame_post_draw
		return field
	need(false,"UI_TOWN_DIRECT_SETUP_TIMEOUT:"+leg.id);return null

func capture(leg: Dictionary) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path:=OUTPUT+str(OS.get_process_id())+"/"+String(leg.screenshot_name)+"_ui03.png"
	if not need(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"NORMAL_NATIVE_UI_IMAGE:"+leg.id):return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(image.save_png(path)==OK,"SAVE_UI_IMAGE:"+leg.id):return false
	png_count+=1;records.append({"town":leg.id,"image":path,"sha256":FileAccess.get_sha256(path),"setup":"public_direct_town_not_world_journey","input_ticks":0,"actor_camera_writes":0});return true

func finish() -> void:
	if not sources.is_empty():need(sources==facts(sources.keys()),"FROZEN_SOURCES_FIRST_FINAL")
	if not saves.is_empty():need(saves==facts(saves.keys()),"SAVES_HASH_BYTES_SECONDS_SAME_EXACT_TICKS_ROOT_GUARD_SEPARATE")
	var path:=OUTPUT+str(OS.get_process_id())+"/ui03_result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":0,"normal_png_count":png_count,"actor_camera_writes":0,"save_writes":0,"world_journeys_replayed":false,"old_geometry_or_room_matrix_replayed":false,"fixture_sha256":FileAccess.get_sha256(FIXTURE)},"\t"));file.close()
	print("[ThreeTownsUI] ",checks," checks / ",errors.size()," failures; ",path);quit(0 if errors.is_empty() else 1)
