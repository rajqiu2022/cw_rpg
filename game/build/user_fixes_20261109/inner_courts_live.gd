extends SceneTree
## Isolated desktop-only smoke test. Use private AppData and keep the editor.

const TAIJI := &"openworld_wudang_taiji_court"
const PURPLE := &"openworld_wudang_purple_cloud_court"
const GATE := &"ch2_s4_lingyue_gate"
const INNER := &"openworld_lingyue_inner_court"
const ADOPTION := "res://build/sect_repair_20261031c_system01/adoption_contract.gd"
const REGISTRY := "res://build/three_towns_world_20261029j_system01/town_registry.gd"
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
		printerr("INNER_COURTS_FAIL ", message)
	return ok

func _done() -> void:
	print("INNER_COURTS_RESULT ", _checks, "/", _failed)
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
	_expect(shot != null and shot.save_png("user://inner_courts_" + key + ".png") == OK, "normal view " + key)

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

func _outside_approach(field: Node, child: StringName, foot: Vector2) -> bool:
	var zone := _portal(field,child)
	if zone == null or zone.is_locked:
		return false
	var town := field.get("native_town") as Node
	var terrain := town.get("terrain") as Node
	var actor := field.get("_player") as Player
	var world := field.get("world_container") as Node2D
	actor.global_position = world.to_global(foot)
	terrain.call("reset_actor",terrain.call("level_at",foot))
	terrain.call("project_actor")
	town.call("update_view")
	await physics_frame
	await physics_frame
	await process_frame
	await process_frame
	return int(zone.get_meta("sect_floor",-1)) == int(terrain.get("actor_level")) and bool(zone.get("_in_range"))

func _pair(parent: StringName, child: StringName, foot: Vector2, back_foot: Vector2, parent_size: Vector2, version: int, arrive: Vector2) -> bool:
	var requested: Variant = foot / parent_size if parent == TAIJI else null
	if not _expect(bool(_router.call("go_field_smart",parent,requested,"",-1,version)),"original parent route " + String(parent)):
		return false
	var outside: Node = await _ready_field(parent)
	if outside == null:
		return false
	var ready: bool = await _outside_approach(outside,child,foot)
	if not _expect(ready,"original native gate physically ready " + String(child)):
		return false
	print("INNER_COURTS_INPUT Space ",child)
	await _press_space()
	var inside: Node = await _ready_field(child)
	if inside == null:
		return false
	var actual := inside.get("_current_scene") as SceneScript
	var original := load("res://data/maps/%s_layout_v1.tres" % child) as WalkableMapLayout
	var layout := actual.map_layout
	var size := Vector2(inside.get("_world_size"))
	_expect(actual.background_path.is_empty() and layout.visual_objects.size() >= 12 and layout.resource_path != original.resource_path,"live new terrain and fixtures " + String(child))
	_expect(layout.schema_version == original.schema_version and layout.portals.size() == original.portals.size() and layout.walkable_regions == original.walkable_regions,"original version, region and return contract " + String(child))
	_expect(_feet(inside).distance_to(arrive * size) < 1.0,"original local entry foot " + String(child))
	for probe: Dictionary in layout.walkable_probes:
		_expect(bool(inside.call("_spawn_has_foot_clearance",actual,probe.pos)), "clear " + str([child,probe.id]))
	for probe: Dictionary in layout.blocked_probes:
		_expect(not bool(inside.call("_spawn_has_foot_clearance",actual,probe.pos)), "blocked " + str([child,probe.id]))
	if child == PURPLE:
		_expect(inside.get("_exit_nodes").size() == 1,"single formal return marker")
		await _capture(inside,"purple_arrival")
	await _place(inside,Vector2(.50,.52 if child == PURPLE else .44))
	await _capture(inside,String(child))
	if child == PURPLE:
		var camera := root.get_camera_2d()
		var offset_before := camera.offset
		camera.offset = Vector2(0,-230)
		camera.force_update_scroll()
		await _capture(inside,"purple_hall_overview")
		camera.offset = offset_before
		camera.force_update_scroll()

	var reverse := _portal(inside,parent)
	if not _expect(reverse != null and not reverse.is_locked,"original return portal " + String(child)):
		return false
	await _place(inside,Vector2(.50,.883 if child == PURPLE else .913))
	await physics_frame
	if not _expect(bool(reverse.get("_in_range")),"local return physically ready " + String(child)):
		return false
	print("INNER_COURTS_INPUT Space ",parent)
	await _press_space()
	outside = await _ready_field(parent)
	if outside == null:
		return false
	return _expect(_feet(outside).distance_to(back_foot) < 1.0,"exact native return foot " + str([parent,_feet(outside)]))

func _run() -> void:
	if not _expect(_paused_checkpoints,"private checkpoints suspended"):
		_done()
		return
	_router = root.get_node("SceneRouter")
	var adapter := load(ADOPTION) as Script
	var taiji: Dictionary = adapter.call("town",TAIJI)
	var raw: Dictionary = adapter.call("raw",TAIJI)
	var purple_foot: Vector2 = adapter.call("vec",raw.portal_feet.to_wudang_purple_cloud_court)
	var purple_back: Vector2 = adapter.call("vec",raw.purple_return)
	if not await _pair(TAIJI,PURPLE,purple_foot,purple_back,taiji.size,3006,Vector2(.50,.865)):
		_done()
		return
	var registry := load(REGISTRY) as Script
	var lingyue: Dictionary = registry.call("town",GATE)
	await _pair(GATE,INNER,lingyue.inner_entrance,lingyue.inner_arrival,lingyue.size,1,Vector2(.50,.84))
	_done()

