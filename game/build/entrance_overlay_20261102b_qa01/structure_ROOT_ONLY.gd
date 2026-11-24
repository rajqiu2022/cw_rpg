extends SceneTree
## Root-only finite display-order regression. No scene travel or save API.
const QA := "res://build/entrance_overlay_20261102b_qa01/"
const ZONE_SCENE := preload("res://scenes/exit_zone.tscn")
var checks := 0
var errors: Array[String] = []
var records: Array = []
var finished := false
var suspended := false
var emitted := 0

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	_run.call_deferred()
	_watchdog.call_deferred()

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func _watchdog() -> void:
	await create_timer(15.0, true, false, true).timeout
	if not finished:
		need(false, "15S_WATCHDOG")
		finish()

func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		errors.append(label)
		printerr("ENTRANCE_OVERLAY_QA_FAIL ", label)
	return ok

func state(zone: ExitZone) -> Dictionary:
	var visuals: Dictionary = {}
	for name: String in ["MarkerVisual", "Prompt", "Indicator"]:
		var visual: CanvasItem = zone.get_node_or_null(NodePath(name)) as CanvasItem
		if visual == null:
			continue
		visuals[name] = {"transform": visual.get_global_transform_with_canvas(), "parent": str(visual.get_parent().get_instance_id()), "visible": visual.visible, "modulate": visual.modulate, "self_modulate": visual.self_modulate, "material": visual.material, "text": (visual as Label).text if visual is Label else ""}
	var collider: CollisionShape2D = zone.get_node("CollisionShape2D") as CollisionShape2D
	return {"visuals": visuals, "zone_transform": zone.global_transform, "zone_z": zone.z_index, "zone_relative": zone.z_as_relative, "collision_layer": zone.collision_layer, "collision_mask": zone.collision_mask, "shape": (collider.shape as RectangleShape2D).size, "target": zone.target_scene_id, "spawn": zone.target_spawn_pos, "action": zone.action, "locked": zone.is_locked, "auto": zone.auto_trigger, "pickable": zone.input_pickable}

func depth(zone: Node) -> bool:
	var ok := true
	for name: String in ["MarkerVisual", "Prompt", "Indicator"]:
		var visual: CanvasItem = zone.get_node_or_null(NodePath(name)) as CanvasItem
		if visual != null:
			ok = need(not visual.z_as_relative and visual.z_index == 4096, "ABSOLUTE_4096:" + String(zone.name) + ":" + name) and ok
	return ok

func _run() -> void:
	await process_frame
	if not need(suspended, "EARLY_CHECKPOINT_SUSPEND"):
		finish()
		return
	var runtime: Node = root.get_node_or_null("EntranceOverlayRuntime")
	if not need(runtime != null, "FORMAL_AUTOLOAD_PRESENT"):
		finish()
		return
	var parent := Node2D.new()
	parent.name = "NegativeDepthFixture"
	parent.z_index = -100
	parent.position = Vector2(43, 79)
	root.add_child(parent)
	var occluder := Node2D.new()
	occluder.z_as_relative = false
	occluder.z_index = 4095
	parent.add_child(occluder)
	var zone: ExitZone = ZONE_SCENE.instantiate() as ExitZone
	zone.name = "ActualExitZoneFixture"
	zone.destination_name = "进入采药人家"
	zone.target_scene_id = "qa_unconnected_target"
	zone.target_spawn_pos = Vector2(0.42, 0.67)
	zone.always_show_destination = true
	zone.position = Vector2(200, 300)
	parent.add_child(zone)
	zone.configure_marker(zone.position, Vector2(3600, 2800))
	zone.configure_destination_render_scale(0.9)
	zone.set_process(false)
	var before := state(zone)
	await process_frame
	await process_frame
	depth(zone)
	need(state(zone) == before, "ONLY_DISPLAY_DEPTH_CHANGED_NOT_BUSINESS_TRANSFORM_ALPHA_OR_SHAPE")
	zone.prompt.z_index = 4095
	zone.prompt.z_as_relative = true
	await process_frame
	await process_frame
	depth(zone)
	need(state(zone) == before, "LATE_WRITER_CORRECTION_STILL_DEPTH_ONLY")
	var late: ExitZone = ZONE_SCENE.instantiate() as ExitZone
	late.name = "LateZone"
	var delayed_prompt: Node = late.get_node("Prompt")
	late.remove_child(delayed_prompt)
	parent.add_child(late)
	late.set_process(false)
	await process_frame
	late.add_child(delayed_prompt)
	await process_frame
	await process_frame
	depth(late)
	var hud := CanvasLayer.new()
	hud.layer = 40
	root.add_child(hud)
	need(hud.layer > 0 and zone.get_canvas_layer_node() == null, "WORLD_CANVAS_BELOW_HUD40_NOT_GLOBAL_MODAL_OVERLAY")
	zone.exit_triggered.connect(func(_target: String, _spawn: Vector2) -> void: emitted += 1)
	need(not zone.try_interact() and emitted == 0, "OUT_OF_RANGE_INTERACTION_UNCHANGED")
	var actor := CharacterBody2D.new()
	actor.add_to_group("player")
	parent.add_child(actor)
	zone._on_body_entered(actor)
	need(zone.try_interact() and emitted == 1, "ORIGINAL_IN_RANGE_SIGNAL_UNCHANGED_NO_ROUTER_CONNECTED")
	zone._on_body_exited(actor)
	need(not zone.try_interact() and emitted == 1, "ORIGINAL_RANGE_EXIT_UNCHANGED")
	records.append({"runtime": runtime.call("get_debug_state"), "before": before, "after": state(zone), "occluder_z": occluder.z_index, "hud_canvas": hud.layer, "signal_count": emitted})
	parent.queue_free()
	hud.queue_free()
	await process_frame
	await process_frame
	records.append({"after_free": runtime.call("get_debug_state")})
	finish()

func finish() -> void:
	if finished:
		return
	finished = true
	var output := QA + "actual_structure/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	var file := FileAccess.open(output + "/result.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"passed": errors.is_empty(), "checks": checks, "errors": errors, "records": records, "save_content_access": false, "scene_travel": false, "input_events": 0, "scope": "ACTUAL_EXITZONE_DISPLAY_ORDER_ONLY"}, "\t") + "\n")
		file.close()
	print("ENTRANCE_OVERLAY_STRUCTURE_RESULT ", checks, " / ", errors.size(), " ", output)
	quit(0 if errors.is_empty() else 1)
