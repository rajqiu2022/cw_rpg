extends "res://tests/test_world_v15_key_map_smoke_20261012.gd"
## Production queue on an owned LM state fixture, then ONE normal formal world entry.
## User game may be running; OS/file/GPU caches are uncontrolled, NOT clean-cold.
const LM_PATH := "res://scripts/autoload/loading_manager.gd"
const PINS := {
	LM_PATH:"38fce81dd6b397fc171a13f142f8032b7de1c76687654e09fb6fe27738f00e77",
	"res://scripts/autoload/scene_router.gd":"a51f2b769cca1d9541a890c5b31ef75fd240fcb7f70bad1b8e401b117ea0cbff",
	"res://scripts/field/field_walkable_controller.gd":"94d87559b57e79264499f5a6bf387823d707f4f29e78aa9f6e4f180fd054cf8f",
	"res://scripts/world/world_map_v15_contract.gd":"c10efd8bfeca980325ac0d8d4dcd99a03f5d01aba636efabc524a1cb9f43def8",
	"res://tests/test_world_v15_key_map_smoke_20261012.gd":"41ace920b78520de784541f50b6c50ebcebba7789257b91b2f8d648cf288928c",
	"res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd":"7628d404d7587dfd885937ad1e26ac6a06f4e48ca53c273ccd8d5f1aee5db9db",
	"res://data/scenes/world_map_jianghu.tres":"685876ac86cb3b739f9b51be12da60e4a125480c715da2d08f9b486d76e5a046",
	"res://data/maps/world_map_jianghu_layout_v15.tres":"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
	"res://data/background_sets/world_map_jianghu_v15_streamed.tres":"3536182ec4eba967e8cd6b5da6b8ca6bb44072022f342d190eb807995a772400",
}
const SMALL := ["res://art/ui/field_hud/v2/hud_bar_bg.png","res://art/ui/field_hud/v2/hud_hp_fill.png","res://art/ui/field_hud/v2/hud_mp_fill.png","res://art/ui/field_hud/v2/hud_map_info_panel.png"]
const FAR := "res://art/maps/world_map_v15_complete_v9c/chunks/r0_c0_visual.png"
var deadline: int
var old_done := false
var old_ok := false
var timeline: Array[Dictionary] = []
var loaded_paths: Array[String] = []
var world_measurement: Dictionary = {}

func _metrics(count: int) -> Dictionary:
	return {"scene_id":"OWNED_QUEUE_FIXTURE","limit":8,"count":count,"completed":0,"request_peak":0,"poll_frames":0,"collect_ms":0.0,"scene_read_ms":0.0,"elapsed_ms":0.0,"complete":false}

func _arm(manager: Node) -> Dictionary:
	manager.call("_reset_transition")
	manager.set("_external_token",int(manager.get("_external_token"))+1)
	manager.set("_loading_path","res://scenes/field_walkable.tscn")
	manager.set("_transition_kind",&"field")
	manager.set("_transition_context",{"field_scene_id":"OWNED_QUEUE_FIXTURE"})
	manager.set("_transition_active",true); manager.set("_finishing",true)
	return manager.call("_capture_transition_owner")

func _resource_paths(manager: Node) -> Array[String]:
	var paths: Array[String] = []
	for resource: Resource in manager.get("_field_preloaded"):
		if resource is Texture2D: paths.append(resource.resource_path)
	paths.sort()
	return paths

func _old_batch(manager: Node, owner: Dictionary, metrics: Dictionary) -> void:
	old_ok = await manager.call("_preload_field_parallel",[FAR],owner,metrics,Time.get_ticks_usec())
	old_done = true

func _small_queues() -> void:
	var manager: Node = (load(LM_PATH) as Script).new() as Node
	root.add_child(manager); manager.call("_ensure_screen")
	var owner: Dictionary = _arm(manager)
	var empty := _metrics(0)
	var empty_ok: bool = await manager.call("_preload_field_parallel",[],owner,empty,Time.get_ticks_usec())
	_check(empty_ok and empty.complete and empty.completed == 0 and empty.request_peak == 0,"production empty queue completes without requests")
	rows.append({"kind":"EMPTY_QUEUE","ok":empty_ok,"metrics":empty})
	owner = _arm(manager)
	var old_metrics := _metrics(1)
	call("_old_batch",manager,owner,old_metrics)
	var at_cancel: Dictionary = manager.call("get_field_preload_metrics")
	var active_at_cancel: bool = not old_done and int(at_cancel.active_requests) > 0
	_check(active_at_cancel,"real far imported PNG request in flight before cancellation")
	var newer: Dictionary = _arm(manager)
	var replacement := _metrics(1)
	var newer_ok: bool = await manager.call("_preload_field_parallel",[FAR],newer,replacement,Time.get_ticks_usec())
	while not old_done and Time.get_ticks_msec() < deadline: await process_frame
	var after: Dictionary = manager.call("get_field_preload_metrics")
	_check(old_done and not old_ok and newer_ok and replacement.complete and replacement.completed == 1 and replacement.request_peak <= 8 and _resource_paths(manager) == [FAR] and after.active_requests == 0 and after.draining_requests == 0,"old cancelled same-path drain cannot collect into or clear new owner")
	rows.append({"kind":"CANCEL_AND_SAME_PATH_NEW_OWNER","active_at_cancel":active_at_cancel,"old_ok":old_ok,"new_ok":newer_ok,"old_metrics":old_metrics,"new_metrics":replacement,"resources":_resource_paths(manager),"after":after,"ownership_scope":"REAL_PRODUCTION_QUEUE_OWNED_LM_STATE_NOT_FIELD_CANCEL"})
	owner = _arm(manager)
	var success := _metrics(SMALL.size())
	var success_ok: bool = await manager.call("_preload_field_parallel",SMALL,owner,success,Time.get_ticks_usec())
	var expected: Array[String] = []; for path: String in SMALL: expected.append(path)
	expected.sort()
	var screen: Node = manager.get("_screen")
	var stage: Label = screen.get_node("Root/Content/Stage") as Label
	var percent: Label = screen.get_node("Root/Content/Percent") as Label
	_check(success_ok and success.complete and success.completed == SMALL.size() and success.request_peak <= 8 and _resource_paths(manager) == expected,"real imported small PNG resource set complete/max8")
	_check(stage.text == "正在读取地图资源……" and not "/" in stage.text and percent.text.ends_with("%"),"production queue stage excludes counts but percent remains")
	rows.append({"kind":"SMALL_SUCCESS_QUEUE","metrics":success,"resources":_resource_paths(manager),"stage":stage.text,"percent":percent.text})
	owner = _arm(manager)
	var bad := _metrics(1)
	var bad_ok: bool = await manager.call("_preload_field_parallel",["res://tests/intentional_missing_preload_20261014.png"],owner,bad,Time.get_ticks_usec())
	_check(not bad_ok and not bad.complete and bad.completed == 0,"real missing resource never becomes a successful preload")
	rows.append({"kind":"INTENTIONAL_MISSING_RESOURCE","ok":bad_ok,"metrics":bad})
	manager.call("_reset_transition")
	while int(manager.call("get_field_preload_metrics").draining_requests) > 0 and Time.get_ticks_msec() < deadline: manager.call("_drain_field_requests"); await process_frame
	manager.queue_free(); manager = null
	await process_frame; await process_frame

func _expected_paths(scene: SceneScript) -> Array[String]:
	# Exact old production enumerator domain: top-level entities, visible chunks,
	# spawn shoe navtile; not recursive authoring metadata/prototype references.
	var paths: Dictionary = {}
	var spawn: Vector2 = scene.player_spawn
	if scene.streamed_background == null:
		if not scene.background_path.is_empty() and ResourceLoader.exists(scene.background_path): paths[scene.background_path] = true
	else:
		var stream: StreamedBackgroundSet = scene.streamed_background
		var size: Vector2 = Vector2(stream.logical_size)
		var visible_size: Vector2 = root.get_visible_rect().size/maxf(1.0,scene.camera_zoom)
		var half: Vector2 = visible_size*.5
		var center: Vector2 = (spawn*size).clamp(half.min(size*.5),(size-half).max(size*.5))
		var visible_rect: Rect2 = Rect2(center-half,visible_size).grow(stream.load_padding)
		for entry: Dictionary in stream.get_chunks(stream.uses_desktop_variant()):
			if (entry.get("logical_rect",Rect2()) as Rect2).intersects(visible_rect,true) and ResourceLoader.exists(String(entry.get("path",""))): paths[String(entry.path)] = true
	var objects: Array = scene.scene_objects
	if scene.map_layout != null:
		objects = scene.map_layout.visual_objects
		if not scene.map_layout.walkable_mask_path.is_empty() and ResourceLoader.exists(scene.map_layout.walkable_mask_path): paths[scene.map_layout.walkable_mask_path] = true
		var shoe: Rect2 = Rect2(spawn*Vector2(scene.map_layout.design_size)-Vector2(17,12),Vector2(34,24)).grow(1.0)
		for tile: Dictionary in scene.map_layout.walkable_mask_tiles:
			if (tile.get("logical_rect",Rect2()) as Rect2).intersects(shoe,true) and ResourceLoader.exists(String(tile.get("path",""))): paths[String(tile.path)] = true
	for object: Dictionary in objects:
		var path: String = String(object.get("texture",""))
		if not path.is_empty() and ResourceLoader.exists(path): paths[path] = true
	for npc: Dictionary in scene.npcs:
		for key: String in ["sprite_path","walk_sprite_path","portrait_path"]:
			var path: String = String(npc.get(key,""))
			if not path.is_empty() and ResourceLoader.exists(path): paths[path] = true
	var result: Array[String] = []; for path: String in paths: result.append(path)
	result.sort(); return result

func _world_entry() -> void:
	var manager: Node = root.get_node("LoadingManager")
	var router: Node = root.get_node("SceneRouter")
	router.call("reset_for_new_game")
	var started: int = Time.get_ticks_usec()
	var started_frame: int = Engine.get_process_frames()
	var last_signature: String = ""
	var max_gap_usec: int = 0
	var prior_observation: int = started
	var accepted: bool = router.call("go_field_smart",ID)
	_check(accepted,"one public no-flags default world entry accepted")
	var ready := false
	while accepted and Time.get_ticks_msec() < deadline:
		await process_frame
		var now: int = Time.get_ticks_usec(); max_gap_usec = maxi(max_gap_usec,now-prior_observation); prior_observation = now
		var metrics: Dictionary = manager.call("get_field_preload_metrics")
		if metrics.get("complete") == true and loaded_paths.is_empty(): loaded_paths = _resource_paths(manager)
		var actual: Node = current_scene
		var state: Dictionary = actual.call("get_field_loading_state") if is_instance_valid(actual) and actual.has_method("get_field_loading_state") else {}
		var stage: String = String(state.get("stage","NO_FIELD"))
		var signature: String = stage+"/"+str(metrics.get("complete",false))+"/"+str(manager.get("_transition_active"))
		if signature != last_signature:
			timeline.append({"elapsed_ms":(now-started)/1000.0,"process_frame":Engine.get_process_frames(),"Field_stage":stage,"Field_ready":state.get("complete",false),"LM_active":manager.get("_transition_active"),"preload":metrics})
			last_signature = signature
		if state.get("failed") == true: break
		if state.get("complete") == true and state.get("scene_id") == String(ID) and manager.get("_transition_active") == false:
			field = actual; ready = true; break
	var elapsed_ms: float = (Time.get_ticks_usec()-started)/1000.0
	var metrics: Dictionary = manager.call("get_field_preload_metrics")
	world_measurement = {"ready":ready,"normal_entry_total_ms":elapsed_ms,"preload_metrics":metrics,"max_observed_frame_gap_usec":max_gap_usec,"observed_frames":Engine.get_process_frames()-started_frame,"stage_intervals":"OBSERVED_BRACKETS_NOT_PURE_SOURCEHASH_NAV_OBJECT_TIMINGS","cache_condition":"UNCONTROLLED_USER_GAME_RUNNING_NOT_CLEAN_COLD","old_serial_comparison_executed":false}
	if not _check(ready,"actual complete Field and Loading naturally hidden within shared120s"): return
	definition = field.get("_current_scene") as SceneScript
	var expected: Array[String] = _expected_paths(definition)
	_check(metrics.complete == true and metrics.limit == 8 and metrics.count == 2692 and metrics.completed == expected.size() and metrics.request_peak <= 8 and expected == loaded_paths,"actual2692 production preloaded full exact resource set/max8")
	var file: FileAccess = FileAccess.open(output+"preload_path_sets.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify({"expected":expected,"actual":loaded_paths},"\t")); file.close()
	_check(file != null,"complete resource-set evidence saved without console flooding")
	oracle = RAW.new()
	_check(bool(oracle.call("configure",definition.map_layout)),"independent original world nav source oracle")
	await physics_frame; await physics_frame
	var player: Node2D = field.get("_player") as Node2D
	var foot: Vector2 = player.position
	_check(WORLD.is_v15(definition) and foot.distance_to(definition.player_spawn*Vector2(definition.map_layout.design_size)) < .03 and _clear(foot),"normal default world spawn independent17+real Physics")
	var screen: Node = manager.get("_screen")
	_check(not bool(screen.call("is_showing")),"ready protocol completed before Loading hid")
	world_measurement.spawn = [foot.x,foot.y]; world_measurement.raw17 = oracle.call("foot_evidence",foot); world_measurement.Physics = _physical(foot)
	world_measurement.full_world_or_portal_credit = false
	rows.append({"kind":"ONE_NORMAL_WORLD_ENTRY","measurement":world_measurement})

func _run() -> void:
	var platform: Node = root.get_node("PlatformBridge")
	var prior: bool = platform.call("is_checkpoint_saves_suspended")
	platform.call("set_checkpoint_saves_suspended",true)
	_check(platform.call("is_checkpoint_saves_suspended") == true,"checkpoint held before first await")
	var players: Dictionary = _players(); slot = int(root.get_node("SaveManager").get("active_slot"))
	output = "res://build/joint_world_luoyang_20261003_qa/loading_parallel8_world_key_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK,"unique bounded queue/world evidence")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_check("--loading-parallel8-world-key" in args and DisplayServer.get_name() != "headless" and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args and not "--luoyang-gate-fortification-candidate" in args,"explicit GPU no-flags world measurement")
	for path: String in PINS: first[path] = _file(path); _check(first[path].sha256 == PINS[path],"exact executed source "+path)
	for path: String in SMALL + [FAR,get_script().resource_path]: first[path] = _file(path)
	deadline = Time.get_ticks_msec()+120000
	var bound_sources: bool = failures == 0
	if bound_sources: await _small_queues(); await _world_entry()
	if oracle != null: _check(bool(oracle.call("verify_sources")),"original nav sources unchanged"); oracle.call("release"); oracle = null
	root.get_node("LoadingManager").call("_reset_transition") # Invalidate a failed/timed-out own entry before freeing its Field.
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	root.get_node("AudioManager").call("stop_dialog_audio"); root.get_node("AudioManager").call("stop_bgm",0.0)
	await process_frame; await process_frame
	var last: Dictionary = {}; for path: String in first: last[path] = _file(path)
	_check(first == last and players == _players() and root.get_node("SaveManager").get("active_slot") == slot,"source/15 saves/slot unchanged; exactticks require outer guard")
	platform.call("set_checkpoint_saves_suspended",prior)
	_check(platform.call("is_checkpoint_saves_suspended") == prior,"checkpoint restored")
	var result: Dictionary = {"scope":"REAL_DESKTOP_MAX8_QUEUE_AND_ONE_WORLD_READY_ONLY","complete":failures == 0,"checks":checks,"failures":failures,"rows":rows,"world":world_measurement,"timeline":timeline,"source_before":first,"source_after":last,"players_before":players,"players_after":_players(),"actual_audio_driver":AudioServer.get_driver_name(),"audio_credit":false,"world_portal_or_all_object_credit":false,"cache_condition":"UNCONTROLLED_USER_GAME_RUNNING_NOT_CLEAN_COLD"}
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	_check(file != null,"write final bounded actual receipt")
	if file != null: file.store_string(JSON.stringify(result,"\t")); file.close()
	print("LOADING_PARALLEL8_WORLD_KEY_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures == 0 else 1)
