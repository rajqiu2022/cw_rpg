extends SceneTree
## Only Lanxi first-draw follow residual; public direct arrival, no World trip replay.
const FIXTURE := "res://build/three_towns_world_20261029j_qa01/camera04_READY.json"
const OUTPUT := "res://build/three_towns_world_20261029j_qa01/camera04_actual/"
var spec: Dictionary={}
var errors: Array[String]=[]
var checks:=0
var began:=0
var evidence: Dictionary={}
var sources: Dictionary={}
var saves: Dictionary={}
func _initialize() -> void:_run.call_deferred()
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label);printerr("THREE_TOWNS_CAMERA_FAIL ",label)
	return ok
func point(raw: Array) -> Vector2:return Vector2(raw[0],raw[1])
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
	if not need(raw is Dictionary and raw.get("ready")==true,"FROZEN_FIRST_DRAW_RESIDUAL_FIXTURE"):finish();return
	spec=raw;sources=facts(spec.fixed_sources.keys());saves=facts(spec.registered_save_paths)
	for path: String in spec.fixed_sources:
		if not need(sources[path].get("sha256")==spec.fixed_sources[path],"PIN:"+path):finish();return
	if not need(spec.legs.size()==1 and String(spec.legs[0].id)=="openworld_lanxi_zhai","ONLY_LANXI_RESIDUAL_NO_SUCCESSFUL_LEG_REPLAY"):finish();return
	var leg: Dictionary=spec.legs[0]
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true,"CHECKPOINT_SUSPENDED"):finish();return
	if not need(root.get_node("SceneRouter").call("go_field_smart",StringName(leg.id),point(leg.arrival_foot)/point(leg.town_size),"",15,1)==true,"PUBLIC_DIRECT_NORMAL_ARRIVAL_NOT_WORLD_TRAVEL"):finish();return
	var field: Node=await ready_field(leg)
	if field==null:finish();return
	var native: Node=field.get_node(NodePath(leg.town_node))
	var actor: Node2D=native.get("actor") as Node2D
	var camera: Camera2D=native.get_node("Camera") as Camera2D
	var terrain: Node=native.get("terrain") as Node
	if not need(actor!=null and camera!=null and terrain!=null and camera.is_current(),"ACTUAL_NATIVE_ACTOR_CURRENT_CAMERA_AND_TERRAIN"):finish();return
	var projected: Vector2=terrain.call("projected_foot")
	var center: Vector2=camera.get_screen_center_position()
	var screen_foot: Vector2=actor.get_global_transform_with_canvas().origin
	var expected_screen: Vector2=root.get_viewport().get_visible_rect().size*.5+Vector2(0,190.0*camera.zoom.y)
	evidence={"setup":"public_direct_lanxi_normal_arrival_not_world_trip","actual_actor_foot":actor.global_position,"projected_foot":projected,"actual_camera_screen_center":center,"expected_camera_center":projected-Vector2(0,190),"actual_actor_screen_foot":screen_foot,"expected_actor_screen_foot":expected_screen,"camera_zoom":camera.zoom,"input_ticks":0,"actor_camera_writes":0}
	need(actor.global_position.distance_to(point(leg.arrival_foot))<=1 and camera.zoom.is_equal_approx(Vector2(.9,.9)),"NORMAL_NATIVE_ARRIVAL_AND_EXISTING_FOLLOW_ZOOM")
	need(center.distance_to(projected-Vector2(0,190))<=1,"ACTUAL_FIRST_DRAW_SCREEN_CENTER_FOLLOWS_PROJECTED_FOOT")
	need(screen_foot.distance_to(expected_screen)<=2 and Rect2(Vector2.ZERO,root.get_viewport().get_visible_rect().size).has_point(screen_foot),"HERO_PROJECTED_IN_SCREEN_AT_CENTER_PLUS_190_TIMES_ZOOM")
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path:=OUTPUT+str(OS.get_process_id())+"/lanxi_first_draw.png"
	if need(image!=null and image.get_size()==Vector2i(1920,1080) and not FileAccess.file_exists(path),"ONE_NORMAL_NATIVE_RESIDUAL_IMAGE"):
		DirAccess.make_dir_recursive_absolute(path.get_base_dir())
		if need(image.save_png(path)==OK,"SAVE_LANXI_FIRST_DRAW_IMAGE"):evidence.image=path;evidence.image_sha256=FileAccess.get_sha256(path)
	finish()
func ready_field(leg: Dictionary) -> Node:
	while Time.get_ticks_msec()-began<20000:
		await process_frame
		var field: Node=current_scene
		if field==null or String(field.scene_file_path)!=String(leg.wrapper_scene):continue
		var state: Dictionary=field.call("get_field_loading_state")
		if state.get("failed")==true:need(false,"DIRECT_FIELD_LOAD_FAILED");return null
		if state.get("complete")!=true or root.get_node("LoadingManager").get("_transition_active")==true or root.get_node("LoadingManager").get("_external_active")==true:continue
		await physics_frame
		await RenderingServer.frame_post_draw
		return field
	need(false,"DIRECT_FIRST_DRAW_20S_BOUND");return null
func finish() -> void:
	if not sources.is_empty():need(sources==facts(sources.keys()),"FROZEN_SOURCES_FIRST_FINAL")
	if not saves.is_empty():need(saves==facts(saves.keys()),"SAVE_HASH_BYTES_SECONDS_SAME_EXACT_TICKS_ROOT_GUARD_SEPARATE")
	var path:=OUTPUT+str(OS.get_process_id())+"/camera04_result.json"
	if FileAccess.file_exists(path):quit(2);return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null:quit(2);return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"evidence":evidence,"elapsed_ms":Time.get_ticks_msec()-began,"input_ticks":0,"actor_camera_writes":0,"save_writes":0,"world_or_successful_town_legs_replayed":false,"fixture_sha256":FileAccess.get_sha256(FIXTURE)},"\t"));file.close()
	print("[ThreeTownsCamera] ",checks," checks / ",errors.size()," failures; ",path);quit(0 if errors.is_empty() else 1)
