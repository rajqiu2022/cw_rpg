extends SceneTree
## Root-only current Linxi interface capture. Public near setup, not travel credit.
const QA := "res://build/entrance_overlay_20261102b_qa01/"
const ID: StringName = &"linxi_village_center"
const FOOT := Vector2(3150, 2220)
var checks := 0
var errors: Array[String] = []
var records: Array = []
var finished := false
var suspended := false

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	_run.call_deferred()
	_watchdog.call_deferred()

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = bool(node.call("is_checkpoint_saves_suspended"))

func _watchdog() -> void:
	await create_timer(40.0, true, false, true).timeout
	if not finished:
		need(false, "40S_WATCHDOG")
		finish()

func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		errors.append(label)
		printerr("ENTRANCE_OVERLAY_NORMAL_FAIL ", label)
	return ok

func wait_field() -> Node:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 14000 and not finished:
		await process_frame
		var field: Node = current_scene
		if field == null or not field.has_method("get_field_loading_state"):
			continue
		var loading: Dictionary = field.call("get_field_loading_state")
		if String(loading.get("scene_id")) != String(ID):
			continue
		if loading.get("failed") == true:
			need(false, "REAL_FIELD_LOADING_FAILED")
			return null
		var manager: Node = root.get_node("LoadingManager")
		if loading.get("complete") != true or manager.get("_transition_active") == true or manager.get("_external_active") == true:
			continue
		if root.get_node("DialogPlayer").call("is_playing") == true or field.get("_scene_refresh_pending") == true:
			continue
		return field
	need(false, "REAL_FIELD14S_WAIT")
	return null

func effective_z(item: CanvasItem) -> int:
	var value: int = item.z_index
	var cursor: CanvasItem = item
	while cursor.z_as_relative and cursor.get_parent() is CanvasItem:
		cursor = cursor.get_parent() as CanvasItem
		value += cursor.z_index
	return clampi(value, -4096, 4096)

func _run() -> void:
	await process_frame
	if not need(suspended, "EARLY_CHECKPOINT_SUSPEND"):
		finish()
		return
	var router: Node = root.get_node("SceneRouter")
	if not need(router.call("go_field_smart", ID, null, "", -1, -1) == true, "PUBLIC_LINXI_BOOTSTRAP"):
		finish()
		return
	var field: Node = await wait_field()
	if field == null or finished:
		finish()
		return
	if not need(router.call("go_field_smart", ID, FOOT / Vector2(3600, 2800), "", -1, 3004) == true, "PUBLIC_CURRENT3004_NEAR_SETUP"):
		finish()
		return
	field = await wait_field()
	if field == null or finished:
		finish()
		return
	await process_frame
	await process_frame
	var town: Node = field.get("native_town") as Node
	var jars: Sprite2D = town.get_node_or_null("Town/Jars2/Art") as Sprite2D
	var zone: ExitZone
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.target_scene_id == "linxi_herbal_home":
			zone = candidate
			break
	if not need(zone != null and jars != null, "REAL_HERBAL_PORTAL_AND_ORIGINAL_JARS2"):
		finish()
		return
	var marker: Sprite2D = zone.get_node("MarkerVisual") as Sprite2D
	var prompt: Label = zone.get_node("Prompt") as Label
	var camera: Camera2D = field.get("_world_camera") as Camera2D
	var player: Node2D = field.get("_player") as Node2D
	var world: Node2D = field.get("world_container") as Node2D
	need(camera.zoom.distance_to(Vector2(0.9, 0.9)) < 0.001, "ORIGINAL_NATIVE_CAMERA09_NOT_QA_OVERVIEW")
	need(world.to_local(player.global_position).distance_to(FOOT) < 0.1, "PUBLIC_NEAR_EXACT_FOOT_NO_PRIVATE_MOVE")
	need(zone.position.distance_to(Vector2(2790, 2148)) < 0.1 and jars.get_parent().position == Vector2(2935, 2145), "PORTAL_AND_JARS_ORIGINAL_ANCHORS_UNMOVED")
	need(prompt.visible and marker.visible and not prompt.z_as_relative and not marker.z_as_relative and effective_z(prompt) == 4096 and effective_z(marker) == 4096 and effective_z(jars) < 4096, "LIVE_NAME_ARROW_ABOVE_ORIGINAL_JARS")
	var title_rect: Rect2 = prompt.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, prompt.size)
	var jars_rect: Rect2 = jars.get_global_transform_with_canvas() * jars.get_rect()
	need(title_rect.intersects(jars_rect), "SAME_ORIGINAL_VISUAL_OVERLAP_REPRODUCED_NOT_MOVED_ASIDE")
	var hud: CanvasLayer = field.get("_hud_canvas_layer") as CanvasLayer
	need(hud != null and hud.layer == 40 and prompt.get_canvas_layer_node() == null, "WORLD_NAME_REMAINS_BELOW_HUD40")
	records.append({"scene": field.scene_file_path, "scene_id": ID, "foot": world.to_local(player.global_position), "camera_zoom": camera.zoom, "portal": zone.position, "target": zone.target_scene_id, "title": prompt.text, "title_rect": title_rect, "jars_rect": jars_rect, "depths": {"name": effective_z(prompt), "arrow": effective_z(marker), "jars": effective_z(jars)}, "runtime": root.get_node("EntranceOverlayRuntime").call("get_debug_state"), "public_near_setup_not_continuous_walk": true})
	await RenderingServer.frame_post_draw
	if not errors.is_empty():
		finish()
		return
	var output := QA + "actual_normal/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	var pixels: Image = root.get_viewport().get_texture().get_image()
	if need(pixels != null and pixels.get_size() == Vector2i(1920, 1080), "REAL_NORMAL1920_IMAGE"):
		need(pixels.save_png(output + "/linxi_herbal_entrance_overlay_normal.png") == OK, "NORMAL_CAPTURE")
	finish()

func finish() -> void:
	if finished:
		return
	finished = true
	var output := QA + "actual_normal/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	var file := FileAccess.open(output + "/result.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"passed": errors.is_empty(), "checks": checks, "errors": errors, "records": records, "save_content_access": false, "input_events": 0, "private_actor_or_camera_writes": false, "scope": "LINXI_HERBAL_ENTRANCE_NORMAL_LAYER_ONLY_NOT_TRAVEL_OR_CITY_ART"}, "\t") + "\n")
		file.close()
	print("ENTRANCE_OVERLAY_NORMAL_RESULT ", checks, " / ", errors.size(), " ", output)
	quit(0 if errors.is_empty() else 1)
