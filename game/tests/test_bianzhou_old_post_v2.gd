extends SceneTree
## Isolated desktop-only smoke test. Use private AppData and keep the editor.

const POST := &"openworld_bianzhou_old_post"
const CITY := &"openworld_bianzhou_city"
const AUTHOR_PATH := "res://build/bianzhou_city_20261028_system01/city_author.gd"
const OLD_LAYOUT := "res://data/maps/openworld_bianzhou_old_post_layout_v1.tres"
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
		printerr("OLD_POST_V2_FAIL ", message)
	return ok

func _done() -> void:
	print("OLD_POST_V2_RESULT ", _checks, "/", _failed)
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

func _run() -> void:
	if not _expect(_paused_checkpoints, "private test checkpoints suspended"):
		_done()
		return
	_router = root.get_node("SceneRouter")
	var author: Script = load(AUTHOR_PATH) as Script
	var city_map: WalkableMapLayout = author.call("layout")
	var city_size := Vector2(city_map.design_size)
	var north_gate: Vector2
	for portal: Dictionary in city_map.portals:
		if portal.get("id") == "old_post": north_gate = portal.pos
	var arrival := north_gate + Vector2(0, 35.0 / city_size.y)
	if not _expect(north_gate != Vector2.ZERO and bool(author.call("safe_foot", arrival)), "old city north gate safe sample"):
		_done()
		return
	if not _expect(bool(_router.call("go_field_smart", CITY, arrival, "", -1, city_map.schema_version)), "city loaded through formal router"):
		_done()
		return
	var city: Node = await _ready_field(CITY)
	if city == null:
		_done()
		return
	var outbound := _portal(city, POST)
	if not _expect(outbound != null and bool(outbound.get("_in_range")), "existing north exit in physical range"):
		_done()
		return
	await _press_space()
	var post: Node = await _ready_field(POST)
	if post == null:
		_done()
		return
	var actual: SceneScript = post.get("_current_scene")
	var original: WalkableMapLayout = load(OLD_LAYOUT)
	var layout := actual.map_layout
	var actor := post.get("_player") as Player
	var world := post.get("world_container") as Node2D
	_expect(layout.resource_path.ends_with("openworld_bianzhou_old_post_layout_v2.tres") and actual.background_path.is_empty(), "formal new layout, no old painted scene")
	_expect(layout.portals == original.portals and layout.walkable_regions == original.walkable_regions and layout.schema_version == original.schema_version, "original portal and normalized navigation contract")
	_expect(post.get("_world_size") == Vector2(3072, 2048) and actual.player_spawn == Vector2(.50, .88), "original world scale and spawn")
	_expect(actual.encounter_step_distance == 230.0 and actual.encounter_chance == .38 and actual.encounter_groups.size() == 3, "original encounter contract")
	_expect(world.to_local(actor.global_position).distance_to(Vector2(1536, .88 * 2048)) < 1.0, "formal old post entry retains original feet")
	var visual: Node2D = post.get("_visual_layer")
	var actor_layer: Node2D = post.get("_actor_layer")
	_expect(visual.has_node("SceneObject_meadow_1_1") and visual.has_node("SceneObject_south_post_road") and visual.has_node("SceneObject_broken_yard_approach"), "separate ground and curved approaches")
	for id in ["post_cottage", "post_stables", "ruined_post_wall"]:
		var item := actor_layer.get_node_or_null("SceneObject_" + id) as Sprite2D
		var collider: Node2D = (post.get("_collision_layer") as Node2D).get_node_or_null("ObjectCollision_" + id)
		_expect(item != null and item.visible and collider != null, "separate feet-sorted prop and body " + id)
	for probe: Dictionary in layout.walkable_probes:
		_expect(bool(post.call("_spawn_has_foot_clearance", actual, probe.pos)), "original fully clear probe " + String(probe.id))
	for probe: Dictionary in layout.blocked_probes:
		_expect(not bool(post.call("_spawn_has_foot_clearance", actual, probe.pos)), "physically blocked probe " + String(probe.id))
	if not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		if shot != null: shot.save_png("user://old_post_v2_arrival.png")
		for view: Dictionary in [{"name":"west_post","uv":Vector2(.23,.60)},{"name":"east_ruin","uv":Vector2(.78,.45)}]:
			actor.global_position=world.to_global(view.uv*Vector2(3072,2048))
			post.call("_snap_camera_to_player")
			await process_frame
			await RenderingServer.frame_post_draw
			var detail:=root.get_texture().get_image()
			_expect(detail!=null and detail.save_png("user://old_post_v2_"+String(view.name)+".png")==OK,"normal view "+String(view.name))
	var inbound := _portal(post, CITY)
	_expect(inbound != null and not inbound.is_locked, "unchanged open return to city")
	if inbound != null:
		# Fixture relocates within the private test process; the interaction is
		# still the original collision Area/Space input, not direct Router travel.
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
				_expect(back_world.to_local(returned.global_position).distance_to(north_gate * city_size) < 100.0, "returns to real north gate")
	_done()
