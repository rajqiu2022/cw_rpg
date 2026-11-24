extends SceneTree
## Local desktop smoke test; run only with the metadata-protected private AppData launcher.

const CITY := &"openworld_xiangzhou_city"
const VALLEY := &"openworld_xiangzhou_mine_valley"
const DEEP_MINE := &"adventure_xiangzhou_deep_mine"
const SIZE := Vector2(3072, 2048)
const CITY_AUTHOR := "res://build/three_settlements_20261030e_system01/xiangzhou_author.gd"
const OLD_LAYOUT := "res://data/maps/openworld_xiangzhou_mine_valley_layout_v1.tres"
const GATHER := "res://scripts/life_skills/gathering_service.gd"
const SHAFT_FOOT := Vector2(1000, 1500)

var _suspended := false
var _checks := 0
var _failed := 0
var _router: Node
var _life: Node
var _adventure: Node
var _pickups: Array = []
var _toasts: Array[String] = []

func _initialize() -> void:
	root.child_entered_tree.connect(_suspend)
	for child: Node in root.get_children():
		_suspend(child)
	_run.call_deferred()

func _suspend(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		_suspended = bool(node.call("is_checkpoint_saves_suspended"))

func _expect(ok: bool, label: String) -> bool:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("MINE_VALLEY_V2_FAIL ", label)
	return ok

func _done() -> void:
	print("MINE_VALLEY_V2_RESULT ", _checks, "/", _failed)
	quit(0 if _failed == 0 else 1)

func _settle() -> void:
	await physics_frame
	await physics_frame
	await process_frame

func _ready_field(id: StringName) -> Node:
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		await process_frame
		var field := current_scene
		if field == null or not field.has_method("get_field_loading_state") or _router.call("get_current_field_id") != id:
			continue
		var state: Dictionary = field.call("get_field_loading_state")
		var actor := field.get("_player") as Player
		if not bool(state.get("complete", false)) or not is_instance_valid(actor) or not actor.can_move:
			continue
		var loading := root.get_node("LoadingManager")
		if bool(loading.get("_transition_active")) or bool(loading.get("_external_active")):
			continue
		if id == VALLEY:
			var site_nodes: Dictionary = _life.get("_site_nodes")
			var adventure_state: Dictionary = _adventure.call("get_adventure_state")
			if site_nodes.size() != 3 or StringName(adventure_state.get("logical_id", "")) != VALLEY:
				continue
		await _settle()
		return field
	_expect(false, "operable formal field " + String(id))
	return null

func _portal(field: Node, target: StringName) -> ExitZone:
	for zone: ExitZone in field.get("_exit_nodes"):
		if StringName(zone.target_scene_id) == target:
			return zone
	return null

func _press(key: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = key
	press.physical_keycode = key
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := press.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)
	print("MINE_VALLEY_V2_INPUT ", OS.get_keycode_string(key))

func _feet(field: Node) -> Vector2:
	var actor := field.get("_player") as Player
	var world := field.get("world_container") as Node2D
	return world.to_local(actor.global_position)

func _walk_into(zone: ExitZone, key: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = key
	press.physical_keycode = key
	press.pressed = true
	Input.parse_input_event(press)
	for i in range(35):
		await physics_frame
		var ready := bool(zone.call("_can_enter")) if zone.has_method("_can_enter") else bool(zone.get("_in_range"))
		if ready:
			break
	press = press.duplicate() as InputEventKey
	press.pressed = false
	Input.parse_input_event(press)
	await _settle()

func _place(field: Node, foot: Vector2) -> void:
	# Relocate only the private fixture. Teleport distance is not real gameplay
	# walking, so omit it from the otherwise unchanged random encounter meter.
	var actor := field.get("_player") as Player
	var world := field.get("world_container") as Node2D
	actor.global_position = world.to_global(foot)
	field.set("_last_encounter_position", actor.position)
	field.set("_encounter_distance", 0.0)
	await _settle()

func _shot(field: Node, name: String, foot: Vector2) -> void:
	await _place(field, foot)
	field.call("_snap_camera_to_player")
	await process_frame
	await RenderingServer.frame_post_draw
	var shot := root.get_texture().get_image()
	_expect(shot != null and shot.save_png("user://mine_valley_v2_" + name + ".png") == OK, "normal GPU view " + name)

func _gather(field: Node, id: String, item: StringName, foot: Vector2) -> void:
	await _place(field, foot)
	var nodes: Dictionary = _life.get("_site_nodes")
	var point := nodes.get(id) as Node2D
	if not _expect(point != null and point.is_visible_in_tree() and String(_life.get("_nearest")) == id, "visible reachable resource " + id):
		return
	var hud_serial: int = field.get("_item_toast_serial")
	_pickups.clear()
	_toasts.clear()
	await _press(KEY_F)
	await create_timer(1.95).timeout
	var toast := field.get("_item_toast") as RichTextLabel
	_expect(_pickups == [[item, 2]] and _toasts.is_empty() and toast != null and toast.visible and int(field.get("_item_toast_serial")) == hud_serial + 1, "one F pickup and one standard notice " + id + " " + str([_pickups, _toasts]))
	var gather := load(GATHER) as Script
	_expect(not point.is_visible_in_tree() and String(_life.get("_nearest")).is_empty() and not bool(gather.call("is_available", id)), "depleted sprite, label and input hidden " + id)

func _run() -> void:
	if not _expect(_suspended, "checkpoints suspended before entry"):
		_done()
		return
	_router = root.get_node("SceneRouter")
	_life = root.get_node("LifeSkills")
	_adventure = root.get_node("AdventureRuntime")
	var bus := root.get_node("EventBus")
	bus.connect("item_picked_up", func(id: StringName, count: int) -> void: _pickups.append([id, count]))
	bus.connect("toast_requested", func(message: String) -> void: _toasts.append(message))
	var author := load(CITY_AUTHOR) as Script
	var city_map: WalkableMapLayout = author.call("layout")
	var city_size := Vector2(city_map.design_size)
	var gate := Vector2.ZERO
	for portal: Dictionary in city_map.portals:
		if StringName(portal.get("target_scene", "")) == VALLEY:
			gate = portal.pos
	var city_foot := gate + Vector2(0, 28.0 / city_size.y)
	if not _expect(gate != Vector2.ZERO and bool(author.call("safe_foot", city_foot)), "formal city northern mine entrance has safe approach"):
		_done()
		return
	if not _expect(bool(_router.call("go_field_smart", CITY, city_foot, "", -1, city_map.schema_version)), "city accepted by formal router"):
		_done()
		return
	var city: Node = await _ready_field(CITY)
	if city == null:
		_done()
		return
	var outbound := _portal(city, VALLEY)
	if not _expect(outbound != null and not outbound.is_locked, "live north mine gate exists and is open"):
		_done()
		return
	var city_world := city.get("world_container") as Node2D
	var actual_gate := city_world.to_local(outbound.global_position)
	if not bool(outbound.get("_in_range")):
		await _place(city, actual_gate + Vector2(0, 90))
		await _walk_into(outbound, KEY_W)
	var area := outbound.get_node("CollisionShape2D") as CollisionShape2D
	var city_actor := city.get("_player") as Player
	var actor_shape := city_actor.get_node("CollisionShape2D") as CollisionShape2D
	var overlap_debug := [actual_gate, _feet(city), outbound.get_overlapping_bodies(), area.global_position, (area.shape as RectangleShape2D).size, city_actor.collision_layer, outbound.collision_mask, actor_shape.global_position, actor_shape.disabled]
	if not _expect(bool(outbound.get("_in_range")), "live north mine gate in Space range: " + str(overlap_debug)):
		_done()
		return
	await _press(KEY_SPACE)
	var field: Node = await _ready_field(VALLEY)
	if field == null:
		_done()
		return
	var actual := field.get("_current_scene") as SceneScript
	var original := load(OLD_LAYOUT) as WalkableMapLayout
	var layout := actual.map_layout
	_expect(layout.resource_path.ends_with("openworld_xiangzhou_mine_valley_layout_v2.tres") and actual.background_path.is_empty(), "new canonical mine modules, no painted v1 plate")
	_expect(layout.portals == original.portals and layout.walkable_regions == original.walkable_regions and layout.schema_version == original.schema_version and layout.blockers[0] == original.blockers[0], "same city portal, terrain mask, coordinate version and cart obstacle")
	_expect(field.get("_world_size") == SIZE and actual.player_spawn == Vector2(.5, .88) and _feet(field).distance_to(Vector2(1536, 1802.24)) < 1.0, "real city Space lands on original mine feet")
	var group_one: Array = [&"mine_outlaw"]
	var group_two: Array = [&"mine_outlaw", &"mine_brute"]
	var group_three: Array = [&"mine_outlaw", &"mine_brute", &"mine_outlaw"]
	var expected_groups: Array[Dictionary] = [{"enemy_ids": group_one, "weight": 2.0}, {"enemy_ids": group_two, "weight": 5.0}, {"enemy_ids": group_three, "weight": 3.0}]
	_expect(actual.encounter_groups == expected_groups and actual.encounter_allow_full_group_for_solo and actual.encounter_step_distance == 245.0 and is_equal_approx(actual.encounter_chance, .42), "original encounter groups, rates and solo contract")
	var visual := field.get("_visual_layer") as Node2D
	var depth := field.get("_actor_layer") as Node2D
	var bodies := field.get("_collision_layer") as Node2D
	for id: String in ["scree_1_1", "south_haul_approach", "east_bypass", "shaft_branch"]:
		_expect(visual.has_node("SceneObject_" + id), "ground and approach mounted " + id)
	for id: String in ["pit_terrace_rear", "yard_shed", "haul_cart", "shaft_cave"]:
		var sprite := depth.get_node_or_null("SceneObject_" + id) as Sprite2D
		_expect(sprite != null and sprite.is_visible_in_tree() and is_equal_approx(sprite.modulate.a, 1.0), "visible feet-sorted prop " + id)
	_expect(bodies.has_node("ObjectCollision_yard_shed"), "visible shed has live physics body")
	for probe: Dictionary in layout.walkable_probes:
		_expect(bool(field.call("_spawn_has_foot_clearance", actual, probe.pos)), "clear " + String(probe.id))
	for probe: Dictionary in layout.blocked_probes:
		_expect(not bool(field.call("_spawn_has_foot_clearance", actual, probe.pos)), "blocked " + String(probe.id))
	if DisplayServer.get_name() != "headless":
		await _shot(field, "shaft", Vector2(1250, 1600))
		await _shot(field, "workyard", Vector2(1920, 1050))
	await _gather(field, "life_mine_ore_01", &"iron_ore", Vector2(1210, 1310))
	await _gather(field, "life_mine_ore_02", &"iron_ore", Vector2(2006, 1540))
	await _gather(field, "life_mine_herb_01", &"herb_bundle", Vector2(1440, 1672))
	await _place(field, SHAFT_FOOT)
	var feature: Dictionary = _adventure.call("get_adventure_state")
	if not _expect(not String(feature.get("nearest", "")).is_empty(), "Space shaft selectable at its original feet"):
		_done()
		return
	await _press(KEY_SPACE)
	var deep: Node = await _ready_field(DEEP_MINE)
	if deep == null:
		_done()
		return
	_expect(_feet(deep).distance_to(Vector2(2048, 2764.8)) < 1.0, "real Space lands on original deep-mine feet")
	var back_to_valley := _portal(deep, VALLEY)
	if not _expect(back_to_valley != null and not back_to_valley.is_locked, "live deep mine Space return"):
		_done()
		return
	await _walk_into(back_to_valley, KEY_S)
	var deep_in_range := bool(back_to_valley.call("_can_enter")) if back_to_valley.has_method("_can_enter") else bool(back_to_valley.get("_in_range"))
	if not _expect(deep_in_range, "deep return actual-foot clearance: " + str(_feet(deep))):
		_done()
		return
	await _press(KEY_SPACE)
	var valley_again: Node = await _ready_field(VALLEY)
	if valley_again == null:
		_done()
		return
	_expect(_feet(valley_again).distance_to(SHAFT_FOOT) < 1.0, "deep mine returns to exact approach feet")
	var return_nodes: Dictionary = _life.get("_site_nodes")
	for id: String in ["life_mine_ore_01", "life_mine_ore_02", "life_mine_herb_01"]:
		var point := return_nodes.get(id) as Node2D
		_expect(point != null and not point.is_visible_in_tree(), "collected resource remains hidden on reload " + id)
	var back_to_city := _portal(valley_again, CITY)
	if _expect(back_to_city != null and not back_to_city.is_locked, "live original city Space return"):
		await _place(valley_again, Vector2(1536, 1760))
		await _walk_into(back_to_city, KEY_S)
		if _expect(bool(back_to_city.get("_in_range")), "valley south return physically in range"):
			await _press(KEY_SPACE)
			var back: Node = await _ready_field(CITY)
			if back != null:
				_expect(_feet(back).distance_to(actual_gate) < 100.0, "returned to real city north mine gate")
	_done()
