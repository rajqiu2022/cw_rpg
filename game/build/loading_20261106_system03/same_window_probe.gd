extends SceneTree
## Same-window diagnostic only; in-memory timers, not formal functional admission.
## Root alone runs this probe in fresh isolated APPDATA/LOCALAPPDATA.
const HOME := "res://build/loading_20261106_system03/"
const PAIR := "res://build/city_navigation_20261101d_candidate01/navigation_pairs.gd"
const DISPATCH := "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd"
var errors: Array[String] = []
var checks := 0
var suspended := false
var finished := false
var router: Node
var host: Node
var loading: Node
var endpoint: Dictionary = {}
var started_usec := 0
var first_loading_draw_usec := 0
var first_loading_full_draw_usec := 0
var target_complete_usec := 0
var target_hidden_usec := 0
var operable_usec := 0
var dispatch_return_usec := 0
var last_frame_usec := 0
var samples: Array[Dictionary] = []
var setup_call_ms := 0.0
var sample_phase := "setup"
var instrumented_scripts: Array[GDScript] = []
var finish_runtime: GDScript
var instrumentation_ready := false

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	RenderingServer.frame_post_draw.connect(_draw)
	_run.call_deferred()
	_watchdog.call_deferred()

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func _watchdog() -> void:
	await create_timer(70.0, true, false, true).timeout
	if not finished:
		need(false, "70S_FINITE_WATCHDOG")
		finish()

func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		errors.append(label)
		printerr("TRANSITION_LATENCY_FAIL ", label)
	return ok

func _screen() -> Node:
	return loading.get("_screen") as Node if is_instance_valid(loading) else null

func _busy() -> bool:
	return loading.get("_transition_active") == true or loading.get("_external_active") == true

func _physical(field: Node) -> String:
	var scene: Resource = field.get("_current_scene") as Resource if is_instance_valid(field) else null
	return String(scene.get("scene_id")) if scene != null else ""

func _draw() -> void:
	if started_usec == 0 or finished:
		return
	var now := Time.get_ticks_usec()
	var screen: Node = _screen()
	var showing := is_instance_valid(screen) and bool(screen.call("is_showing"))
	var alpha := float(screen.get("root").modulate.a) if showing else 0.0
	if showing and alpha > 0.01 and first_loading_draw_usec == 0:
		first_loading_draw_usec = now
	if showing and alpha >= 0.95 and first_loading_full_draw_usec == 0:
		first_loading_full_draw_usec = now
	var field: Node = current_scene
	var physical := _physical(field)
	var actor: Node = field.get("_player") as Node if is_instance_valid(field) and field.has_method("get_field_loading_state") else null
	var ready: Dictionary = field.call("get_field_loading_state") if is_instance_valid(actor) else {}
	var target := physical == String(endpoint.get("target", {}).get("scene_id", ""))
	if target and ready.get("complete") == true and target_complete_usec == 0:
		target_complete_usec = now
	if target and not showing and not _busy() and target_hidden_usec == 0:
		target_hidden_usec = now
	if samples.size() < 5000:
		samples.append({"usec":now, "gap_ms":(now-last_frame_usec)/1000.0 if last_frame_usec > 0 else 0.0, "screen":showing, "alpha":alpha, "loading_busy":_busy(), "physical":physical, "field_complete":ready.get("complete",false), "can_move":actor.get("can_move") if actor != null else false})
	last_frame_usec = now

func _wait(id: String) -> Node:
	var until := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < until and not finished:
		await process_frame
		var field: Node = current_scene
		if _physical(field) != id or not field.has_method("get_field_loading_state"):
			continue
		var state: Dictionary = field.call("get_field_loading_state")
		if state.get("failed") == true:
			need(false, "REAL_FIELD_FAILED:"+id)
			return null
		var actor: Node = field.get("_player") as Node
		var screen: Node = _screen()
		var hidden := screen == null or not bool(screen.call("is_showing"))
		var nav: Dictionary = host.call("get_debug_state")
		if state.get("complete") == true and not _busy() and hidden and actor != null and actor.get("can_move") == true and nav.get("attached_scene") == id and nav.get("mini_ok") == true and nav.get("pending",{}).is_empty():
			return field
	need(false, "30S_READY:"+id)
	return null

func _run() -> void:
	await process_frame
	if not need(suspended, "EARLY_CHECKPOINT_SUSPEND"):
		finish()
		return
	router = root.get_node("SceneRouter")
	host = root.get_node("CityNavigationRuntime")
	loading = root.get_node("LoadingManager")
	if not install_diagnostic():
		finish()
		return
	var pairs: GDScript = load(PAIR) as GDScript
	for row: Dictionary in pairs.call("endpoints", "luoyang_civic_market_region_27d"):
		if row.get("pair_id") == "yamen_artisan" and row.get("side") == "a":
			endpoint = row
	if not need(not endpoint.is_empty(), "ONE_CURRENT_DECLARED_PAIR"):
		finish()
		return
	var point: Vector2 = endpoint.mouth - endpoint.outward * 20.0
	var dispatch: GDScript = load(DISPATCH) as GDScript
	var extension := {"region_id":endpoint.scene_id,"revision":1,"logical_id":endpoint.logical_id,"global_foot_px":[point.x,point.y]}
	var setup_started := Time.get_ticks_usec()
	var accepted: bool = dispatch.call("start",router,StringName(endpoint.logical_id),Vector2(.5,.5),"",3,extension)
	setup_call_ms = (Time.get_ticks_usec()-setup_started)/1000.0
	if not need(accepted, "PUBLIC_REGION_NEAR_SETUP_NOT_TRAVEL_CREDIT"):
		finish()
		return
	var field: Node = await _wait(String(endpoint.scene_id))
	if field == null or finished:
		finish()
		return
	var actor: Node2D = field.get("_player") as Node2D
	if not need(actor.position.distance_to(point) < .03, "PUBLIC_NEAR_EXACT_FOOT"):
		finish()
		return
	await physics_frame
	Engine.set_meta("loading03_trace", {"enabled":true,"rows":[],"stack":[],"dropped":0})
	started_usec = Time.get_ticks_usec()
	last_frame_usec = started_usec
	sample_phase = "one_actual_space_pair"
	var event := InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	dispatch_return_usec = Time.get_ticks_usec()
	await physics_frame
	event = InputEventKey.new()
	event.keycode = KEY_SPACE
	event.physical_keycode = KEY_SPACE
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	field = await _wait(String(endpoint.target.scene_id))
	if field == null or finished:
		finish()
		return
	operable_usec = Time.get_ticks_usec()
	actor = field.get("_player") as Node2D
	need(actor.position.distance_to(endpoint.target.arrival) < .03, "ONE_REAL_PAIR_DECLARED_TARGET_FOOT")
	var debug: Dictionary = host.call("get_debug_state")
	var history: Array = debug.get("route_history",[])
	need(not history.is_empty() and history.back().get("pair_id") == "yamen_artisan", "ONE_REAL_PAIR_HISTORY_NO_PRIVATE_TRAVEL")
	await create_timer(1.0,true,false,true).timeout
	finish()

func finish() -> void:
	if finished:
		return
	finished = true
	var max_before_draw := 0.0
	var max_after_hidden := 0.0
	var max_under_screen := 0.0
	for row: Dictionary in samples:
		if first_loading_draw_usec == 0 or row.usec <= first_loading_draw_usec:
			max_before_draw = maxf(max_before_draw,row.gap_ms)
		if target_hidden_usec > 0 and row.usec >= target_hidden_usec:
			max_after_hidden = maxf(max_after_hidden,row.gap_ms)
		if row.screen:
			max_under_screen = maxf(max_under_screen,row.gap_ms)
	var result := {"passed":errors.is_empty(),"checks":checks,"errors":errors,"scope":"ONE_TRUE_YAMEN_ARTISAN_SPACE_LEG_AFTER_PUBLIC_NEAR_NOT_22_MATRIX","input_events":2 if started_usec > 0 else 0,"setup_call_ms":setup_call_ms,"dispatch_return_ms":(dispatch_return_usec-started_usec)/1000.0 if started_usec > 0 else -1.0,"first_loading_draw_ms":(first_loading_draw_usec-started_usec)/1000.0 if first_loading_draw_usec > 0 else -1.0,"first_loading_full_draw_ms":(first_loading_full_draw_usec-started_usec)/1000.0 if first_loading_full_draw_usec > 0 else -1.0,"target_field_complete_ms":(target_complete_usec-started_usec)/1000.0 if target_complete_usec > 0 else -1.0,"target_loading_hidden_ms":(target_hidden_usec-started_usec)/1000.0 if target_hidden_usec > 0 else -1.0,"target_operable_ms":(operable_usec-started_usec)/1000.0 if operable_usec > 0 else -1.0,"max_frame_before_loading_draw_ms":max_before_draw,"max_frame_after_loading_hidden_ms":max_after_hidden,"max_frame_under_loading_ms":max_under_screen,"frames":samples,"runtime":host.call("get_debug_state") if is_instance_valid(host) else {},"real_save_contents_accessed":false,"private_flags_written":false}
	var screen: Node = _screen()
	result["screen_barrier_events"] = screen.get("_barrier_events").duplicate(true) if screen != null and screen.get("_barrier_events") is Array else []
	result["target_field_profile"] = current_scene.call("get_field_loading_profile") if is_instance_valid(current_scene) and current_scene.has_method("get_field_loading_profile") else {}
	var original: Dictionary=load("res://scripts/city/luoyang_quarters_family_20261022ap.gd").call("validation_receipt")
	result["original_validation_receipt"]={"source_count":original.get("source_first",{}).size(),"full_source_hash_passes":original.get("full_source_hash_passes",0),"finalized":original.get("finalized",false),"first_hash_elapsed_us":original.get("first_hash_elapsed_us",-1),"final_hash_elapsed_us":original.get("final_hash_elapsed_us",-1)}
	var trace: Dictionary=Engine.get_meta("loading03_trace",{})
	trace["enabled"]=false
	var spans: Array=trace.get("rows",[])
	var names: Dictionary={}
	for span: Dictionary in spans: names[span.name]=true
	for required: String in ["router.go_field_smart","family.validation_begin","family.validation_finish","family.matches","family._finish25i_ensure"]:
		need(names.has(required),"ACTUAL_TRACE_HIT:"+required)
	need(trace.get("dropped",0)==0,"TRACE_NOT_TRUNCATED")
	var calls: Array=finish_runtime.call("diagnostic_calls") if finish_runtime!=null else []
	var target_calls: Array=[]
	var cold_hit:=false
	for call_row: Dictionary in calls:
		if int(call_row.get("start_us",0))<started_usec or call_row.get("scene_id")!=String(endpoint.get("target",{}).get("scene_id","")): continue
		target_calls.append(call_row)
		for segment: Dictionary in call_row.get("segments",[]):
			if call_row.get("ok",false)==true and segment.get("phase")=="object_textures_all": cold_hit=true
	need(cold_hit,"SAME_PAIR_TARGET_COLD_ENSURE_HIT")
	result["scope"]="ONE_SAME_WINDOW_MEMORY_INSTRUMENTED_SPACE_PAIR_DIAGNOSTIC_NOT_FORMAL_ADMISSION_OR_FUNCTIONAL_PASS"
	result.erase("passed")
	result["diagnostic_completed"]=errors.is_empty()
	result["checks"]=checks
	result["errors"]=errors
	result["absolute_spans"]=spans
	result["same_pair_ensure_calls"]=target_calls
	result["trace_dropped"]=trace.get("dropped",0)
	result["limits"]="In-memory exact inverse timers; instrumentation overhead included. Nested spans overlap: union/clip to exact draw interval, never sum nested totals. PC atlas _ready runs before pair; this is not app-start measurement. No header or texture-batch optimization adopted."
	var output := HOME + "actual/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	var file := FileAccess.open(output+"/result.json",FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result,"\t")+"\n")
		file.close()
	print("TRANSITION_LATENCY_RESULT ",checks," / ",errors.size()," ",output)
	quit(0 if errors.is_empty() else 1)

func install_diagnostic() -> bool:
	var receipt: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(HOME+"instrumentation_receipt.json"))
	for spec: Dictionary in receipt.scripts:
		var formal: String=spec.formal_path
		var candidate: String=spec.candidate_path
		if not need(FileAccess.get_sha256(formal)==spec.formal_sha256 and FileAccess.get_sha256(candidate)==spec.candidate_sha256,"INSTRUMENT_SOURCE_SHA:"+spec.group): return false
		var code: String=FileAccess.get_file_as_string(candidate)
		var inverse:=code
		if spec.group=="finish":
			var absolute: Array=spec.absolute_changes.duplicate();absolute.reverse()
			for change: Dictionary in absolute: inverse=inverse.replace(change.after,change.before)
			var base: Dictionary=spec.base_receipt
			inverse=inverse.replace(base.wrapper,"").replace("static func _diag_ensure_body(","static func ensure(")
			var changes: Array=base.changes.duplicate();changes.reverse()
			for change: Dictionary in changes: inverse=inverse.replace(change.after,change.before)
			if base.original_newline=="CRLF": inverse=inverse.replace("\n","\r\n")
		else:
			inverse=inverse.trim_suffix(String(spec.suffix))
			var changes: Array=spec.changes.duplicate();changes.reverse()
			for change: Dictionary in changes: inverse=inverse.replace(change.after,change.before)
		if not need(inverse.to_utf8_buffer()==FileAccess.get_file_as_bytes(formal),"WHOLE_BYTE_INVERSE:"+spec.group): return false
		var script: GDScript=load(formal) as GDScript
		if not need(script!=null and script.resource_path==formal,"MEMORY_SAME_PATH:"+spec.group): return false
		script.source_code=code
		if not need(script.reload(true)==OK,"MEMORY_RELOAD_KEEP_STATE:"+spec.group): return false
		instrumented_scripts.append(script)
		if spec.group=="finish": finish_runtime=script
	instrumentation_ready=true
	return true
