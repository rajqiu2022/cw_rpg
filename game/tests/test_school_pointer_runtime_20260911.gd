extends SceneTree

# Real scenes, Player footprint and actual pointer dispatch; only scene-change
# signal listeners are intercepted so no user saves or unrelated scenes run.
var checks := 0
var failed := 0
var exit_count := 0
var npc_count := 0
var last_dialog := ""

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error("[SchoolPointer] " + why)

func _run() -> void:
	root.size = Vector2i(1920,1080)
	root.get_node("GameState").reset_for_new_game()
	root.get_node("Inventory").reset_for_new_game()
	await classroom()
	await pointer()
	await root.get_node("AudioManager").stop_bgm(0.0)
	await process_frame
	print("[SchoolPointer] checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)

func spawn_field(id: StringName) -> Node:
	var router := root.get_node("SceneRouter")
	router.set("_field_payload", {"scene_id": id})
	router.set("_current_field_id", id)
	var field: Node = load("res://scenes/field_walkable.tscn").instantiate()
	root.add_child(field)
	for i in range(12):
		await process_frame
	for i in range(3):
		await physics_frame
	return field

func footprint(field: Node, point: Vector2) -> bool:
	var actor: Player = field.get("_player")
	var collision: CollisionShape2D = actor.get_node("CollisionShape2D")
	var size: Vector2 = field.get("_screen_size")
	# Runtime constrains the ROOT against already-expanded rectangles; do not
	# erroneously expand these a second time with foot corners. The separate
	# physics query uses the actual Player collider against real static bodies.
	if not field.call("_is_normalized_spawn_walkable", field.get("_current_scene"), point): return false
	var world: Node2D = field.get("world_container")
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.transform.origin = world.to_global(point*size) + collision.global_position-actor.global_position
	query.collision_mask = actor.collision_mask
	query.exclude = [actor.get_rid()]
	return actor.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func classroom() -> void:
	var scene := load("res://data/scenes/linxi_south_scholar_house.tres") as SceneScript
	var old := load("res://data/scenes/linxi_scholar_house.tres") as SceneScript
	check(scene.background_path != old.background_path and scene.map_layout != old.map_layout, "classroom and old ledger house have distinct art/layout")
	check(old.background_path == "res://art/backgrounds/bg_linxi_scholar_house_25d_v2.png", "old house image path unchanged")
	var hashes := {
		"res://data/scenes/linxi_scholar_house.tres": "3085015d7e81581a4b11eff1207f38c33f286d16e89ea9ff8430993bbc8eeadb",
		"res://data/maps/linxi_scholar_house_layout_v1.tres": "9ef6503c91767e3fccffb5c14aa9473faa7bbe57af834b4907b434d79f689021",
		"res://art/backgrounds/bg_linxi_scholar_house_25d_v2.png": "40126767e8cd41dea6b05b39293b4518ed376f897c82841af2944d23551f989a"}
	for path: String in hashes:
		check(FileAccess.get_sha256(path) == hashes[path], "old resource bytes unchanged " + path)
	check(load(scene.background_path).get_size() == Vector2(1536,1024), "native classroom pixels")
	check(scene.map_layout.display_at_native_size and not scene.map_layout.fill_viewport, "doorway retained in complete native framing")
	check(scene.map_layout.blockers.size() == 24 and scene.map_layout.walkable_probes.size() >= 24 and scene.map_layout.blocked_probes.size() >= 26, "dense nine-desk/bench contracts")
	check(scene.player_spawn == Vector2(0.56,0.76), "reviewed classroom arrival clears desk margin")
	var south := load("res://data/maps/linxi_village_scrollmap_layout_v1.tres") as WalkableMapLayout
	var arrival_matches := false
	for entry: Dictionary in south.portals:
		if entry.get("target_scene", "") == "linxi_south_scholar_house":
			arrival_matches = entry.target_pos == scene.player_spawn
	check(arrival_matches, "south doorway uses same corrected classroom arrival")
	var west_probe_matches := false
	for probe: Dictionary in scene.map_layout.walkable_probes:
		if probe.id == "west_row3":
			west_probe_matches = probe.pos.is_equal_approx(Vector2(0.192708,0.722656))
	check(west_probe_matches, "west aisle probe clears cabinet expansion boundary")
	var portal: Dictionary = scene.map_layout.portals[0]
	check(portal.pos == Vector2(0.5,0.845) and portal.target_pos == Vector2(0.355,0.310) and portal.target_scene == "linxi_village_scrollmap", "paired south portal unchanged")
	var field := await spawn_field(scene.scene_id)
	var actor: Player = field.get("_player")
	var size: Vector2 = field.get("_screen_size")
	check(footprint(field, scene.player_spawn), "real Player collision rectangle fits arrival")
	const STEP := 8.0
	var visited := {}
	var start := Vector2i((scene.player_spawn*size/STEP).round())
	var queue: Array[Vector2i] = [start]
	visited[start] = true
	var at := 0
	while at < queue.size():
		var p := queue[at]
		at += 1
		for delta: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var n := p+delta
			if visited.has(n) or n.x < 0 or n.y < 0 or n.x*STEP > size.x or n.y*STEP > size.y:
				continue
			if footprint(field, Vector2(n)*STEP/size):
				visited[n] = true
				queue.append(n)
	for probe: Dictionary in scene.map_layout.walkable_probes:
		check(footprint(field, probe.pos), "full feet at " + probe.id)
		var nearest := INF
		for cell: Vector2i in queue:
			nearest = minf(nearest, (Vector2(cell)*STEP - probe.pos*size).length())
		check(nearest < 15.0, "spawn-connected central/side aisle " + probe.id + " nearest=" + str(nearest))
	for probe: Dictionary in scene.map_layout.blocked_probes:
		check(not field.call("_is_normalized_spawn_walkable", scene, probe.pos), "table/shelf/wall blocks " + probe.id)
		var foot_root: Vector2 = probe.pos - actor.get_node("CollisionShape2D").position/size
		check(not footprint(field, foot_root), "actual feet cannot occupy " + probe.id)
	field.queue_free()
	await process_frame

func detach(signal_owner: Object, signal_name: String) -> void:
	for connection: Dictionary in signal_owner.get_signal_connection_list(signal_name):
		signal_owner.disconnect(signal_name, connection.callable)

func pointer() -> void:
	var field := await spawn_field(&"linxi_village_scrollmap")
	var actor: Player = field.get("_player")
	actor.set_physics_process(false)
	field.set_process(false)
	var camera: Camera2D = field.get("_world_camera")
	if camera != null:
		camera.enabled = false
	root.canvas_transform = Transform2D.IDENTITY
	var world: Node2D = field.get("world_container")
	for zone: ExitZone in field.get("_exit_nodes"):
		detach(zone, "exit_triggered")
		detach(zone, "exit_action_triggered")
		zone.exit_triggered.connect(func(_id: String, _pos: Vector2): exit_count += 1)
		zone.exit_action_triggered.connect(func(_action: String): exit_count += 1)
		check(not zone.input_pickable, "exit has one pointer dispatcher")
	for npc: NPCNode in field.get("_npc_nodes"):
		detach(npc, "npc_interacted")
		npc.npc_interacted.connect(func(_id: String, dialog: String): npc_count += 1; last_dialog = dialog)
	for pair: Array in [["linxi_south_apothecary_home", "linxi_south_farmer"], ["world_map_jianghu", "linxi_south_veteran"]]:
		var chosen: ExitZone
		var person: NPCNode
		for zone: ExitZone in field.get("_exit_nodes"):
			if zone.target_scene_id == pair[0]: chosen = zone
		for npc: NPCNode in field.get("_npc_nodes"):
			if npc.npc_id == pair[1]: person = npc
		check(chosen != null and person != null, "reported portal/NPC fixtures exist " + pair[0])
		if chosen == null or person == null: continue
		for zoom: float in [0.8,1.0,1.45]:
			world.scale = Vector2.ONE*zoom
			world.position = Vector2(1080,530)-chosen.marker_visual.position*zoom-chosen.position*zoom
			actor.position = chosen.position-Vector2(0,42)
			for i in range(4): await physics_frame
			check(chosen.get("_in_range"), "actual portal proximity after scaled translation")
			var point: Vector2 = chosen.marker_visual.get_global_transform_with_canvas().origin
			# Exercise actual overlap deterministically even if animation bob moves
			# the authored overlap by a few pixels. Only visual offset is changed.
			var old_visual := person.sprite.position
			person.sprite.global_position = chosen.marker_visual.global_position
			check(field.call("_pointer_hits_sprite", person.sprite, point), "stress pointer intersects overlapping NPC sprite")
			for touch: bool in [false,true]:
				var e0 := exit_count
				var n0 := npc_count
				await press(field, point, touch)
				check(exit_count == e0+1 and npc_count == n0, "one marker press wins over NPC: " + pair[0] + " touch="+str(touch)+" zoom="+str(zoom))
			person.sprite.position = old_visual
			actor.position = person.position
			for i in range(4): await physics_frame
			var npc_point := person.sprite.get_global_transform_with_canvas() * Vector2(0,24)
			check(not field.call("_pointer_hits_sprite", chosen.marker_visual, npc_point, 9.0), "NPC-only click outside marker")
			var before_npc := npc_count
			await press(field, npc_point, false)
			check(npc_count == before_npc+1 and ResourceLoader.exists("res://data/dialogs/%s.tres" % last_dialog), "NPC-only click emits real existing dialogue request")
			actor.position = Vector2(200,500)
			for i in range(4): await physics_frame
			var before_exit := exit_count
			await press(field, point, false)
			check(exit_count == before_exit, "far marker does not activate")
			check(has_label(field, "请靠近出口后再点击"), "far marker explains approach")
			actor.position = chosen.position-Vector2(0,42)
			for i in range(4): await physics_frame
			field.set("_system_panel_open", true)
			await press(field, point, true)
			check(exit_count == before_exit, "modal blocks touch")
			field.set("_system_panel_open", false)
		# Both real proximity flags must be set for keyboard priority.
		# Authored NPCs were deliberately moved away from the exits this patch;
		# put the same real NPC in overlap temporarily to isolate Space priority.
		var npc_position := person.position
		person.position = chosen.position + Vector2(-20,0)
		actor.position = chosen.position+Vector2(-18,-12)
		for i in range(4): await physics_frame
		check(chosen.get("_in_range") and (person.get("_in_range") or person.call("_is_player_within_interaction_distance")), "keyboard overlap has both candidates in range")
		var n0 := npc_count
		var e0 := exit_count
		var space := InputEventKey.new()
		space.keycode = KEY_SPACE
		space.pressed = true
		actor.call("_unhandled_input", space)
		check(npc_count == n0+1 and exit_count == e0, "Space keeps NPC-first priority")
		person.position = npc_position
		# Do not mistake a signal pointing at a malformed legacy resource for
		# a working conversation: also run the actual field dialogue handler.
		actor.position = person.position
		for i in range(3): await physics_frame
		field.call("_on_npc_interacted", person.npc_id, person.call("_resolve_dialog_id"))
		check(root.get_node("DialogPlayer").is_playing(), "actual NPC handler opens readable dialogue " + person.npc_id)
		if root.get_node("DialogPlayer").is_playing():
			root.get_node("DialogPlayer").call("_end_dialog")
	# Actual DialogPlayer state, not just a synthetic boolean.
	var modal := DialogScript.new()
	modal.dialog_id = &"qa_pointer_modal"
	var modal_node := DialogNode.new()
	modal_node.node_id = &"start"
	modal_node.text = "QA pointer modal, no quest effects."
	modal.nodes.append(modal_node)
	root.get_node("DialogPlayer").play(modal)
	check(root.get_node("DialogPlayer").is_playing(), "real DialogPlayer modal opened")
	var locked_before := exit_count
	field.call("_unhandled_input", mouse(Vector2(1080,530), true))
	check(exit_count == locked_before, "real dialogue modal blocks pointer")
	root.get_node("DialogPlayer").call("_end_dialog")
	await create_timer(2.7).timeout
	field.queue_free()
	await process_frame

func mouse(point: Vector2, down: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.position = point
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = down
	return e

func press(field: Node, point: Vector2, touch: bool) -> void:
	# Deliver native events through the real controller's actual input branch;
	# headless GUI ordering is not claimed as a desktop end-to-end input test.
	if touch:
		var e := InputEventScreenTouch.new()
		e.position = point
		e.pressed = true
		field.call("_unhandled_input", e)
		e.pressed = false
		field.call("_unhandled_input", e)
	else:
		field.call("_unhandled_input", mouse(point,true))
		field.call("_unhandled_input", mouse(point,false))
	await process_frame

func has_label(node: Node, text: String) -> bool:
	if node is Label and node.text == text: return true
	for child in node.get_children():
		if has_label(child,text): return true
	return false
