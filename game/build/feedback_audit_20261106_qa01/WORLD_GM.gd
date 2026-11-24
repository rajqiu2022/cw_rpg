extends SceneTree
const HOME := "res://build/feedback_audit_20261106_qa01/"
var suspended := false
var done := false
var checks := 0
var errors: Array[String] = []
var record: Dictionary = {}

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children(): _early(node)
	run.call_deferred()
	watch.call_deferred()

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func watch() -> void:
	await create_timer(80.0, true, false, true).timeout
	if not done:
		need(false,"80S_WATCHDOG")
		finish()

func need(ok: bool,label: String) -> bool:
	checks += 1
	if not ok:
		errors.append(label)
		printerr("WORLD_GM_FAIL ",label)
	return ok

func run() -> void:
	await process_frame
	if not need(suspended,"EARLY_CHECKPOINTS_SUSPENDED"): finish(); return
	var router: Node = root.get_node("SceneRouter")
	var loading: Node = root.get_node("LoadingManager")
	var icons: Node = root.get_node("MapIconRuntime")
	router.call("go_world_map")
	var field: Node
	var overlay: Control
	var until := Time.get_ticks_msec()+65000
	while Time.get_ticks_msec()<until:
		await process_frame
		field = current_scene
		if field == null or not field.has_method("get_field_loading_state"): continue
		var scene: Resource = field.get("_current_scene") as Resource
		if scene == null or not String(scene.get("scene_id")).begins_with("world_map_jianghu"): continue
		var state: Dictionary = field.call("get_field_loading_state")
		if state.get("failed") == true: need(false,"FIELD_FAILED"); finish(); return
		var actor: Node = field.get("_player") as Node
		var screen: Node = loading.get("_screen") as Node
		if state.get("complete") != true or actor == null or actor.get("can_move") != true: continue
		if loading.get("_transition_active") == true or loading.get("_external_active") == true or (screen != null and screen.call("is_showing")): continue
		var debug: Dictionary = icons.call("get_debug_state")
		if debug.get("overlay",{}).get("kind") != "WORLD" or debug.get("overlay",{}).get("markers",[]).is_empty(): continue
		var overlay_ref: WeakRef = icons.get("_overlay") as WeakRef
		overlay = overlay_ref.get_ref() as Control if overlay_ref != null else null
		break
	if not need(is_instance_valid(overlay),"FORMAL_WORLD_READY"): finish(); return
	var live: Array = overlay.call("_live")
	var mini: Control = live[2]
	var helper: RefCounted = overlay.get("_gm_avoidance")
	var button: Control = root.get_node("GMConsole/GMFloatingButton")
	var map_rect: Rect2 = mini.get("_map_rect")
	var exclusion: Rect2 = helper.call("_viewport_rect",mini,map_rect.grow(8.0))
	var button_rect: Rect2 = helper.call("_viewport_rect",button,Rect2(Vector2.ZERO,button.size))
	need(not exclusion.intersects(button_rect),"REAL_WORLD_NONOVERLAP")
	need(helper.get_debug_state().moves > 0,"REAL_GM_RELOCATED")
	record["before_drag"] = {"gm":button_rect,"map":exclusion,"layout":helper.get_debug_state()}
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	need(picture.save_png(ProjectSettings.globalize_path(HOME+"WORLD_GM_NORMAL.png")) == OK,"ONE_NORMAL_IMAGE")
	var start := button_rect.get_center()
	var target := exclusion.get_center()
	var down := InputEventMouseButton.new()
	down.position=start; down.global_position=start; down.button_index=MOUSE_BUTTON_LEFT; down.pressed=true
	root.push_input(down,true)
	await process_frame
	var motion := InputEventMouseMotion.new()
	motion.position=target; motion.global_position=target; motion.relative=target-start; motion.button_mask=MOUSE_BUTTON_MASK_LEFT
	root.push_input(motion,true)
	await process_frame
	var up := InputEventMouseButton.new()
	up.position=target; up.global_position=target; up.button_index=MOUSE_BUTTON_LEFT; up.pressed=false
	root.push_input(up,true)
	await process_frame
	var dragged := button.position
	for i in range(20): await process_frame
	need(helper.get_debug_state().user_override,"REAL_GUI_DRAG_USER_OVERRIDE")
	need(button.position == dragged,"REAL_GUI_DRAG_NOT_RECLAIMED")
	record["after_drag"] = {"position":button.position,"layout":helper.get_debug_state()}
	finish()

func finish() -> void:
	if done: return
	done=true
	var report := {"checks":checks,"errors":errors,"passed":errors.is_empty(),"checkpoint_suspended":suspended,"real_save_access":false,"images":1,"route":"public go_world_map only; no entrance matrix","record":record}
	var file := FileAccess.open(HOME+"WORLD_GM_RESULT.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report,"\t"))
	print("WORLD_GM_RESULT ",JSON.stringify(report))
	quit(0 if errors.is_empty() else 1)
