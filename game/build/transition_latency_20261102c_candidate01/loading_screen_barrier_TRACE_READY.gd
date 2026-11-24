extends "res://scripts/ui/loading_screen.gd"
## Same PackedScene and inherited onready/animation state, installed before ready.
## Retains the visible loading surface until the real navigation/minimap tail is ready.
var _view_job := false
var _barrier_events: Array[Dictionary] = []

func show_screen(immediate: bool = false) -> void:
	# Original dispatch can show the same already-visible view again. Do not
	# reset alpha to zero and flash the source world between preparation phases.
	super.show_screen(immediate or is_showing())

func _input(event: InputEvent) -> void:
	# Source Player is held before dispatch; Field's menu shortcuts are in
	# _unhandled_input and must not sneak through the asynchronous SHA window.
	# Keep mouse GUI dispatch for the ORIGINAL failure/retry surface.
	if not is_showing() or not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	var host: Node = get_node_or_null("/root/CityNavigationRuntime")
	if host != null and host.call("view_preparation_busy"):
		get_viewport().set_input_as_handled()

func set_progress(ratio: float, stage_text: String) -> void:
	var host: Node = get_node_or_null("/root/CityNavigationRuntime")
	var manager: Node = get_parent()
	var field: Node = get_tree().current_scene
	if ratio >= 1.0 and manager != null and manager.get("_transition_active") == true and host != null and host.call("loading_barrier_required", field):
		super.set_progress(.99, "正在完成入口与小地图……")
		return
	super.set_progress(ratio, stage_text)

func hide_screen() -> void:
	_trace_view("hide_override_enter")
	# LoadingManager can complete both a field transition and a previously
	# scheduled external hide. Neither may fade out the surface owned by an
	# in-flight real-view job. Only _complete_view may call super.hide_screen.
	if _view_job:
		_trace_view("hide_owned_job_retained")
		return
	var host: Node = get_node_or_null("/root/CityNavigationRuntime")
	var field: Node = get_tree().current_scene
	var required := host != null and bool(host.call("loading_barrier_required", field))
	_trace_view("hide_required", required)
	if required:
		# Legacy completed leases legitimately require LoadingManager's flags to
		# be inactive. Let its ORIGINAL reset finish; do not edit flags/tokens.
		# An external completion already clears its active flag BEFORE hide,
		# so active=true is not an admissible condition for retaining this view.
		if prepare_new_field(field):
			return
	_trace_view("hide_passthrough_base")
	await super.hide_screen()
	_trace_view("hide_passthrough_base_complete")

func prepare_new_field(field: Node) -> bool:
	var host: Node = get_node_or_null("/root/CityNavigationRuntime")
	if _view_job or host == null or not host.call("begin_loading_barrier", field):
		_trace_view("prepare_rejected")
		return false
	_trace_view("prepare_accepted")
	_view_job = true
	if not is_showing():
		var manager: Node = get_parent()
		configure(manager.call("_choose_card", &"field"), "正在准备地图")
	# Cancel any older completion fade before this job owns a postdraw. A
	# visible-but-fading surface is not a retained preparation screen.
	show_screen(true)
	_complete_view.call_deferred(weakref(field), _visibility_generation, int(get_parent().get("_external_token")))
	return true

func _owns(reference: WeakRef, generation: int, token: int) -> bool:
	return is_inside_tree() and generation == _visibility_generation and token == int(get_parent().get("_external_token")) and reference != null and reference.get_ref() == get_tree().current_scene

func _complete_view(reference: WeakRef, generation: int, token: int) -> void:
	var manager: Node = get_parent()
	_trace_view("complete_wait_original_reset")
	while _owns(reference, generation, token) and (manager.get("_transition_active") == true or manager.get("_external_active") == true):
		await get_tree().process_frame
	if not _owns(reference, generation, token):
		_view_job = false
		_cancel_own_view(reference)
		return
	# Ensure the retained loading surface itself really draws before tail work.
	await RenderingServer.frame_post_draw
	if not _owns(reference, generation, token):
		_view_job = false
		_cancel_own_view(reference)
		return
	var host: Node = get_node_or_null("/root/CityNavigationRuntime")
	var field: Node = reference.get_ref() as Node
	var ok := false
	if host != null:
		_trace_view("tail_prepare_start")
		ok = bool(await host.call("prepare_field_for_loading", field))
		_trace_view("tail_prepare_return", ok)
	if not _owns(reference, generation, token):
		_view_job = false
		_cancel_own_view(reference)
		return
	if not ok:
		# Never unlock or hide an unprepared field. Retry only the same owned view.
		show_failure("入口或小地图准备未完成，请重试。", func() -> void: _complete_view(reference, generation, token))
		return
	_trace_view("tail_final_fade_start")
	super.set_progress(1.0, "准备完成")
	await super.hide_screen()
	_trace_view("tail_final_fade_complete")
	_view_job = false
	if is_instance_valid(host):
		if not root.visible and token == int(manager.get("_external_token")) and field == get_tree().current_scene:
			host.call("finish_loading_barrier", field, true)
		else:
			host.call("cancel_loading_barrier", field)

func _cancel_own_view(reference: WeakRef) -> void:
	var host: Node = get_node_or_null("/root/CityNavigationRuntime")
	if host != null:
		host.call("cancel_loading_barrier", reference.get_ref() as Node if reference != null else null)

func _trace_view(phase: String, required: bool = false) -> void:
	var field: Node = get_tree().current_scene if is_inside_tree() else null
	var host: Node = get_node_or_null("/root/CityNavigationRuntime")
	var manager: Node = get_parent()
	var scene: Resource = field.get("_current_scene") as Resource if is_instance_valid(field) else null
	var key := str(field.get_instance_id()) + ":" + str(scene.get_instance_id()) if scene != null else ""
	var states: Dictionary = host.get("_states") if host != null else {}
	var state: Dictionary = states.get(key, {})
	var context: Dictionary = manager.get("_transition_context") if manager != null and manager.get("_transition_context") is Dictionary else {}
	_barrier_events.append({"phase":phase,"usec":Time.get_ticks_usec(),"required":required,"view_job":_view_job,"visible":root.visible,"alpha":root.modulate.a,"generation":_visibility_generation,"external_token":manager.get("_external_token") if manager != null else -1,"transition_active":manager.get("_transition_active") if manager != null else false,"external_active":manager.get("_external_active") if manager != null else false,"loading_context_scene":context.get("field_scene_id",""),"field_node":field.get_instance_id() if field != null else 0,"field_script":field.get_script().resource_path if field != null and field.get_script() != null else "","scene_id":String(scene.get("scene_id")) if scene != null else "","scene_instance":scene.get_instance_id() if scene != null else 0,"field_complete":field.get("_field_loading_complete") if field != null else false,"field_failed":field.get("_field_loading_failed") if field != null else false,"rebuilding":field.get("_scene_rebuilding") if field != null else false,"host_ready":host.get("_ready_sources") if host != null else false,"state_exists":states.has(key),"state_mini_ok":state.get("mini_ok",false),"host_last_error":host.get("_last_error") if host != null else ""})
	if _barrier_events.size() > 64:
		_barrier_events.pop_front()
