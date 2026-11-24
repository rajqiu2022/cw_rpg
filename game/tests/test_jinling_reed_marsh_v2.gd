extends SceneTree
## Isolated desktop-only smoke test. Use private AppData and keep the editor.

const MARSH := &"openworld_jinling_reed_marsh"
const CITY := &"openworld_jinling_city"
const AUTHOR_PATH := "res://build/jinling_city_20261029_system01/city_author.gd"
const OLD_LAYOUT := "res://data/maps/openworld_jinling_reed_marsh_layout_v1.tres"
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
		printerr("OLD_MARSH_V2_FAIL ", message)
	return ok

func _done() -> void:
	print("OLD_MARSH_V2_RESULT ", _checks, "/", _failed)
	quit(0 if _failed == 0 else 1)

func _ready_field(id: StringName) -> Node:
	var deadline := Time.get_ticks_msec() + 20000
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

func _capture(field: Node, actor: Player, name: String, foot: Vector2) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var world := field.get("world_container") as Node2D
	actor.global_position = world.to_global(foot)
	field.call("_snap_camera_to_player")
	await process_frame
	await RenderingServer.frame_post_draw
	var detail := root.get_texture().get_image()
	_expect(detail != null and detail.save_png("user://marsh_v2_" + name + ".png") == OK, "normal view " + name)

func _run() -> void:
	if not _expect(_paused_checkpoints, "private test checkpoints suspended"):
		_done()
		return
	_router = root.get_node("SceneRouter")
	var author: Script = load(AUTHOR_PATH) as Script
	var city_map: WalkableMapLayout = author.call("layout")
	var city_size := Vector2(city_map.design_size)
	var city_dock: Vector2
	for portal: Dictionary in city_map.portals:
		if portal.get("id") == "reed_marsh": city_dock = portal.pos
	var arrival := city_dock + Vector2(0, 35.0 / city_size.y)
	if not _expect(city_dock != Vector2.ZERO and bool(author.call("safe_foot", arrival)), "formal city dock safe sample"):
		_done()
		return
	if not _expect(bool(_router.call("go_field_smart", CITY, arrival, "", -1, city_map.schema_version)), "city loaded through formal router"):
		_done()
		return
	var city: Node = await _ready_field(CITY)
	if city == null:
		_done()
		return
	var outbound := _portal(city, MARSH)
	if not _expect(outbound != null and bool(outbound.get("_in_range")), "existing ferry in physical range"):
		_done()
		return
	var city_actor := city.get("_player") as Player
	var city_world := city.get("world_container") as Node2D
	var ferry_foot := city_world.to_local(city_actor.global_position)
	await _press_space()
	var marsh: Node = await _ready_field(MARSH)
	if marsh == null:
		_done()
		return
	var actual: SceneScript = marsh.get("_current_scene")
	var original: WalkableMapLayout = load(OLD_LAYOUT)
	var layout := actual.map_layout
	var actor := marsh.get("_player") as Player
	var world := marsh.get("world_container") as Node2D
	var size := Vector2(3072, 2048)
	_expect(layout.resource_path.ends_with("openworld_jinling_reed_marsh_layout_v2.tres") and actual.background_path.is_empty(), "formal new layout, no old painted scene")
	_expect(layout.portals == original.portals and layout.walkable_regions == original.walkable_regions and layout.blockers == original.blockers and layout.schema_version == original.schema_version, "original portal, native region and deep pool blocker")
	_expect(marsh.get("_world_size") == size and actual.player_spawn == Vector2(.50, .88), "original world scale and spawn")
	_expect(actual.encounter_step_distance == 255.0 and actual.encounter_chance == .44 and actual.encounter_groups.size() == 3 and actual.encounter_allow_full_group_for_solo, "original encounter contract")
	_expect(world.to_local(actor.global_position).distance_to(Vector2(1536, .88 * 2048)) < 1.0, "formal ferry arrival feet")
	var visual: Node2D = marsh.get("_visual_layer")
	var actor_layer: Node2D = marsh.get("_actor_layer")
	var mask: Image = marsh.get("_walkable_mask_image")
	_expect(mask != null and mask.get_size() == Vector2i(3072, 2048), "actual shoreline mask imported at native resolution")
	for id in ["reed_pool", "river_reach", "ferry_boat", "net_landing", "south_landing", "camp_track_lower"]:
		var item := visual.get_node_or_null("SceneObject_" + id) as Sprite2D
		_expect(item != null and item.texture != null and item.visible, "active terrain/landing component " + id)
	for id in ["fishing_camp", "paper_workshop", "paper_rinse_trough"]:
		var item := actor_layer.get_node_or_null("SceneObject_" + id) as Sprite2D
		var collider: Node2D = (marsh.get("_collision_layer") as Node2D).get_node_or_null("ObjectCollision_" + id)
		_expect(item != null and item.visible and collider != null, "feet-sorted prop with body " + id)
	for probe: Dictionary in layout.walkable_probes:
		_expect(bool(marsh.call("_spawn_has_foot_clearance", actual, probe.pos)), "clear authored probe " + String(probe.id))
	for probe: Dictionary in layout.blocked_probes:
		_expect(not bool(marsh.call("_spawn_has_foot_clearance", actual, probe.pos)), "blocked authored probe " + String(probe.id))
	var life := root.get_node("LifeSkills")
	for foot: Vector2 in [Vector2(760,900), Vector2(2520,840), Vector2(1510,1640)]:
		_expect(bool(marsh.call("_spawn_has_foot_clearance", actual, foot / size)), "herb foot clear " + str(foot))
	_expect(life.get("_field") == marsh and String(life.get("_field_id")) == String(MARSH), "existing gathering runtime mounted")
	await _capture(marsh, actor, "arrival", Vector2(1536, 1802))
	await _capture(marsh, actor, "west_camp", Vector2(1000, 1170))
	await _capture(marsh, actor, "east_bank", Vector2(2250, 1170))
	var inbound := _portal(marsh, CITY)
	_expect(inbound != null and not inbound.is_locked, "unchanged open ferry return")
	if inbound != null:
		actor.global_position = inbound.global_position - Vector2(0, 36)
		await physics_frame
		await physics_frame
		await process_frame
		if _expect(bool(inbound.get("_in_range")), "original return area in physical range"):
			await _press_space()
			var back: Node = await _ready_field(CITY)
			if back != null:
				var returned := back.get("_player") as Player
				var back_world := back.get("world_container") as Node2D
				var back_foot := back_world.to_local(returned.global_position)
				_expect(minf(back_foot.distance_to(ferry_foot), back_foot.distance_to(city_dock * city_size)) < 2.0, "returns to actual ferry position: " + str(back_foot))
	_done()

