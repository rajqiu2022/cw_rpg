extends SceneTree
## Isolated desktop-only smoke test. Use private AppData and keep the editor.

const ROAD := &"ch5_s1_relief_road"
const CAMP := &"ch5_s2_grain_convoy_camp"
const WORLD := &"world_map_jianghu_v16"
const OLD_LAYOUT := "res://data/maps/ch5_s1_relief_road_layout_v1.tres"
var _paused_checkpoints := false
var _failed := 0
var _checks := 0
var _router: Node

func _initialize() -> void:
	root.child_entered_tree.connect(_suspend)
	for child: Node in root.get_children(): _suspend(child)
	_run.call_deferred()

func _suspend(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		_paused_checkpoints = bool(node.call("is_checkpoint_saves_suspended"))

func _expect(ok: bool, message: String) -> bool:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("RELIEF_ROAD_V2_FAIL ", message)
	return ok

func _done() -> void:
	print("RELIEF_ROAD_V2_RESULT ", _checks, "/", _failed)
	quit(0 if _failed == 0 else 1)

func _ready_field(id: StringName) -> Node:
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var current := current_scene
		if current == null or not current.has_method("get_field_loading_state"): continue
		if _router.call("get_current_field_id") != id: continue
		var state: Dictionary = current.call("get_field_loading_state")
		var actor := current.get("_player") as Player
		if not bool(state.get("complete", false)) or not is_instance_valid(actor) or not actor.can_move: continue
		if bool(root.get_node("LoadingManager").get("_transition_active")): continue
		await physics_frame
		return current
	_expect(false, "field ready " + String(id))
	return null

func _portal(field: Node, target: StringName) -> ExitZone:
	for zone: ExitZone in field.get("_exit_nodes"):
		if StringName(zone.target_scene_id) == target: return zone
	return null

func _press_space() -> void:
	var press := InputEventKey.new()
	press.keycode = KEY_SPACE
	press.physical_keycode = KEY_SPACE
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := press.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)

func _place(field: Node, uv: Vector2) -> void:
	var actor := field.get("_player") as Player
	var world := field.get("world_container") as Node2D
	actor.global_position = world.to_global(uv * Vector2(field.get("_world_size")))
	field.set("_last_encounter_position", actor.position)
	field.set("_encounter_distance", 0.0)
	await physics_frame
	await physics_frame
	await process_frame
	await process_frame

func _feet(field: Node) -> Vector2:
	var actor := field.get("_player") as Player
	var world := field.get("world_container") as Node2D
	return world.to_local(actor.global_position)

func _capture(field: Node, key: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	field.call("_snap_camera_to_player")
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	_expect(shot != null and shot.save_png("user://relief_road_v2_" + key + ".png") == OK, "normal view " + key)

func _area_for_action(field: Node, action: String) -> Area2D:
	for area: Area2D in field.get("_trigger_areas"):
		var data: Dictionary = area.get_meta("trigger_data", {})
		if String(data.get("action", "")) == action:
			return area
	return null

func _world_exit(field: Node) -> ExitZone:
	for zone: ExitZone in field.get("_exit_nodes"):
		if zone.action == "world_map":
			return zone
	return null

func _run() -> void:
	if not _expect(_paused_checkpoints, "private test checkpoints suspended"):
		_done()
		return
	_router = root.get_node("SceneRouter")
	var flags: Dictionary = root.get_node("GameState").get("flags")
	# Fixture represents the chapter-five investigation before victory, with
	# auto-intro already seen so the actual cart input can be tested separately.
	flags["chapter4_complete"] = true
	flags["chapter5_started"] = true
	flags["seen_ch5_relief_road_intro"] = true
	flags["seen_ch5_grain_convoy_intro"] = true
	var surveyed: Variant = _router.call("get_world_map_position_for_scene", ROAD, WORLD)
	if not _expect(surveyed is Vector2 and bool(_router.call("go_field_smart", WORLD, surveyed, "", 16)), "formal world and original Gufeng approach"):
		_done()
		return
	var world: Node = await _ready_field(WORLD)
	if world == null:
		_done()
		return
	var gate := _portal(world, ROAD)
	if not _expect(gate != null, "original Gufeng world portal exists"):
		_done()
		return
	if not bool(gate.call("can_enter")):
		var door: PackedVector2Array = gate.get("_doorway_polygon")
		var center := Vector2.ZERO
		for point in door: center += point
		if not door.is_empty():
			var world_container := world.get("world_container") as Node2D
			await _place(world, world_container.to_local(gate.to_global(center / door.size())) / Vector2(world.get("_world_size")))
	if not _expect(bool(gate.call("can_enter")), "native world doorway full-foot admission"):
		_done()
		return
	await _press_space()
	var field: Node = await _ready_field(ROAD)
	if field == null:
		_done()
		return
	var size := Vector2(1920, 1280)
	var actual: SceneScript = field.get("_current_scene")
	var layout := actual.map_layout
	var old: WalkableMapLayout = load(OLD_LAYOUT)
	_expect(layout.resource_path.ends_with("_layout_v2.tres") and actual.background_path.is_empty(), "formal chapter and World target use modular layout")
	_expect(layout.walkable_regions == old.walkable_regions and layout.schema_version == old.schema_version and field.get("_world_size") == size, "legacy navigable regions and version retained")
	_expect(_feet(field).distance_to(Vector2(.52,.90) * size) < 1.0, "original normalized entry spawn")
	_expect(actual.hotspots.size() == 3 and actual.exits[0].require_flag == "ch5_relief_road_cleared" and actual.encounter_groups.size() == 3 and actual.encounter_step_distance == 720.0 and actual.encounter_chance == .12 and actual.encounter_require_flag == &"ch5_relief_road_cleared", "original gameplay records")
	var prop := (field.get("_actor_layer") as Node).get_node_or_null("SceneObject_overturned_grain_cart") as Sprite2D
	var visuals := field.get("_visual_layer") as Node
	_expect(prop != null and prop.texture != null and is_equal_approx(prop.modulate.a, 1.0) and visuals.has_node("SceneObject_camp_cut"), "live layered art and depth-sorted grain cart")
	for probe: Dictionary in layout.walkable_probes:
		_expect(bool(field.call("_spawn_has_foot_clearance", actual, probe.pos)), "clear probe " + String(probe.id))
	for probe: Dictionary in layout.blocked_probes:
		_expect(not bool(field.call("_spawn_has_foot_clearance", actual, probe.pos)), "blocked probe " + String(probe.id))
	_expect(bool(field.call("_spawn_has_foot_clearance", actual, Vector2(.84,.17))), "original camp fallback spawn remains safe")
	var locked := false
	for zone: ExitZone in field.get("_exit_nodes"):
		if zone.destination_name == "赶往护粮营地": locked = zone.is_locked
	_expect(locked and _portal(field, CAMP) == null, "camp is gated before victory")
	_expect(_area_for_action(field, "dialog:ch5_relief_road_battle") != null, "original ambush interaction exists")
	await _capture(field, "arrival")
	await _place(field, Vector2(.361,.562))
	await _capture(field, "cart")
	var cart_zone := _area_for_action(field, "dialog:ch5_relief_road_intro")
	if not _expect(cart_zone != null and cart_zone.overlaps_body(field.get("_player")), "cart inspection can be reached on foot"):
		_done()
		return
	await _press_space()
	var dialog := root.get_node("DialogPlayer")
	var script: DialogScript = dialog.get("_current_script")
	if not _expect(bool(dialog.call("is_playing")) and script != null and script.dialog_id == &"ch5_relief_road_intro", "actual Space opens original cart dialogue"):
		_done()
		return
	dialog.call("advance")
	dialog.call("advance")
	await process_frame
	_expect(not bool(dialog.call("is_playing")) and bool(root.get_node("QuestManager").call("is_active", &"q_ch5_main_01_relief_route")), "original clue and quest flow completes")
	# Test the gated leg without changing enemy balance or faking a combat win.
	root.get_node("GameState").call("set_flag", &"ch5_relief_road_cleared", true)
	await create_timer(0.4).timeout
	var to_camp := _portal(field, CAMP)
	if not _expect(to_camp != null and not to_camp.is_locked, "camp opens only after its original flag"):
		_done()
		return
	await _place(field, Vector2(.89,.116))
	await _capture(field, "pass")
	if not _expect(bool(to_camp.get("_in_range")), "camp exit physical range"):
		_done()
		return
	await _press_space()
	var camp: Node = await _ready_field(CAMP)
	if camp == null:
		_done()
		return
	var camp_next_locked := false
	for zone: ExitZone in camp.get("_exit_nodes"):
		if zone.destination_name == "前往雪岭关":
			camp_next_locked = zone.is_locked
	_expect(camp_next_locked and _area_for_action(camp, "dialog:ch5_grain_convoy_battle") != null, "camp battle remains available; Snow Pass still needs the banner clue")
	var to_road := _portal(camp, ROAD)
	var camp_world := _world_exit(camp)
	_expect(camp_world != null and to_road != null and camp_world.global_position.distance_to(to_road.global_position) > 300.0, "camp World and road markers are separated")
	await _place(camp, Vector2(.105,.796))
	if not _expect(to_road != null and bool(to_road.get("_in_range")), "original camp return area"):
		_done()
		return
	await _press_space()
	field = await _ready_field(ROAD)
	if field == null:
		_done()
		return
	# Portal memory takes precedence over the camp's unpaired fallback.
	_expect(_feet(field).distance_to(Vector2(.89,.11) * size) < 1.0, "camp returns at the exact remembered north portal: " + str(_feet(field)))
	var leave := _world_exit(field)
	await _place(field, Vector2(.51,.90))
	if not _expect(leave != null and bool(leave.get("_in_range")), "southern exit physical range"):
		_done()
		return
	await _press_space()
	var world_again: Node = await _ready_field(WORLD)
	if world_again != null:
		_expect(_feet(world_again).distance_to(Vector2(surveyed) * Vector2(world_again.get("_world_size"))) < 150.0, "world return at original Gufeng gate")
	_done()

