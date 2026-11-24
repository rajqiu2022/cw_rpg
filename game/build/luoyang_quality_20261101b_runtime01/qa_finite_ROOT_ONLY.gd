extends SceneTree
## Root-only finite real renderer QA. Does not execute itself or touch save files.
## Near setups use the existing public versioned Region dispatcher; they are
## explicitly not continuous World/city travel. Actual Yihong doors use Space.
const HOME := "res://build/luoyang_quality_20261101b_runtime01/"
const MANIFEST := HOME + "source_pins_READY.json"
const OUTPUT := HOME + "actual/"
const FIELD := "res://build/luoyang_regions_20261027d_source01/region_field.gd"
const DISPATCH := "res://build/luoyang_regions_20261027d_source01/router_region_dispatch.gd"
const LOGICAL := "ch4_s3_luoyang_market"
const ROOM := "yihongyuan27n_interior"
const GROUND_CASES := [
	{"id": "luoyang_estate_region_27d", "logical": "luoyang_estate_riverside_20261021ai", "foot": [1850, 3672], "image": "estate_servants_edge_normal"},
	{"id": "luoyang_civic_market_region_27d", "logical": LOGICAL, "foot": [2640, 4280], "image": "civic_cloth_court_normal"},
	{"id": "luoyang_temple_region_27d", "logical": "ch4_s4_ancient_temple", "foot": [850, 3100], "image": "temple_court_edge_normal"},
]
var errors: Array[String] = []
var records: Array = []
var checks := 0
var input_ticks := 0
var began := 0
var finished := false
var pins: Dictionary = {}
var first: Dictionary = {}
var business_before: Dictionary = {}
var router: Node
var host: Node
var _previous_field_instance := 0

func _initialize() -> void:
	_watchdog.call_deferred(); _run.call_deferred()

func _watchdog() -> void:
	await create_timer(180.0, true, false, true).timeout
	if not finished: need(false, "INDEPENDENT_180S_COROUTINE_WATCHDOG"); finish()

func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: errors.append(label); printerr("QUALITY31B_QA_FAIL ", label)
	return ok

func _point(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))

func _facts() -> Dictionary:
	var result: Dictionary = {}
	for path: String in pins:
		var file := FileAccess.open(path, FileAccess.READ)
		result[path] = {"sha256": FileAccess.get_sha256(path), "bytes": file.get_length() if file != null else -1, "mtime_seconds": FileAccess.get_modified_time(path)}
	return result

func _business() -> Dictionary:
	# In-memory serialization only; never SaveManager load/save or file content.
	var game: Node = root.get_node("GameState")
	var serializer: Node = root.get_node("SaveManager")
	var hero: Resource = game.get("player") as Resource
	var party: Array = []
	for member: Resource in game.get("party"): party.append({"instance": str(member.get_instance_id()), "data": serializer.call("_serialize_stats", member)})
	return {"hero_instance": str(hero.get_instance_id()), "hero": serializer.call("_serialize_stats", hero), "party": party, "gold": game.get("gold"), "flags": game.get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict"), "inventory": root.get_node("Inventory").call("to_dict")}.duplicate(true)

func _run() -> void:
	began = Time.get_ticks_msec()
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not need(raw is Dictionary and raw.get("ready") == true, "ROOT_FROZEN_INDEPENDENT_SOURCE_MANIFEST"): finish(); return
	pins = raw.source_pins.duplicate(true)
	pins[MANIFEST] = FileAccess.get_sha256(MANIFEST)
	first = _facts()
	for path: String in pins:
		if not need(first[path].sha256 == pins[path], "SOURCE_FIRST:" + path): finish(); return
	router = root.get_node("SceneRouter")
	host = root.get_node_or_null("SceneArtQualityRuntime")
	if not need(host != null and host.has_method("get_debug_state") and host.call("get_debug_state").get("ready") == true, "NEW_HOST_READY_FROM_REAL_AUTOLOAD"): finish(); return
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	if not need(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended") == true, "CHECKPOINT_SUSPENDED_NO_REAL_SAVE_API"): finish(); return
	business_before = _business()
	for item: Dictionary in GROUND_CASES:
		if not _setup(String(item.id), String(item.logical), _point(item.foot)): finish(); return
		var field: Node = await _wait_field(String(item.id), true)
		if field == null: finish(); return
		if not need((field.get("_player") as Node2D).position.distance_to(_point(item.foot)) <= 0.02, "PUBLIC_VERSIONED_EXACT_NEAR_FOOT:" + String(item.id)): finish(); return
		var original: Dictionary = _original_identity(field)
		var receipt: Dictionary = field.get_meta("ground_quality31b", {})
		if not need(receipt.get("attached") == true and receipt.get("physics_changed") == false and receipt.get("compiled_changed") == false and receipt.get("period_px") == Vector2(256, 512.0 / 3.0), "REAL_GROUND_VIEW_RECEIPT:" + String(item.id)): finish(); return
		var view: Node = (field.get("_visual_layer") as Node).get_node_or_null("SourceBoundGroundView31b")
		if not need(view != null and _flat_view_only(view), "NEW_VIEW_HAS_ONLY_TEXTURED_UNSCRIPTED_GROUND:" + String(item.id)): finish(); return
		if not await _capture(String(item.image)): finish(); return
		await create_timer(0.55).timeout
		if not need(original == _original_identity(field) and _business() == business_before, "GROUND_STABLE_OLD_COMPILED_OWNER_BODIES_BUSINESS:" + String(item.id)): finish(); return
		var mini: Node = field.get("_world_travel_minimap")
		var debug: Dictionary = mini.call("get_debug_state") if is_instance_valid(mini) else {}
		if not need(debug.get("visual_cache_ready") == true and debug.get("cache_render_requests") == 1, "REAL_MINI_REBUILT_READY_ONE_SHOT:" + String(item.id)): finish(); return
	# Source-bound public near setup on the existing street, then real W/Space
	# enter, stationary two-second seat observation, S/Space return. No fake door.
	if not _setup("luoyang_civic_market_region_27d", LOGICAL, Vector2(5206.18017578125, 4280)): finish(); return
	var outside: Node = await _wait_field("luoyang_civic_market_region_27d", true)
	if outside == null: finish(); return
	await _key(KEY_W, 12)
	var entrance: Node = _door(outside, "enter_yihongyuan27n")
	if not need(entrance != null and entrance.call("_can_enter") == true, "CURRENT_REAL_YIHONG_DOOR_ENTERABLE"): finish(); return
	await _key(KEY_SPACE, 1)
	var room: Node = await _wait_field(ROOM, false)
	if room == null: finish(); return
	if not need((room.get("_player") as Node2D).position.distance_to(Vector2(768, 850)) <= 1, "REAL_DOOR_AUTHORED_ROOM_ARRIVAL"): finish(); return
	var room_before: Dictionary = _original_identity(room)
	var seats: Dictionary = _seat_state(room)
	if not need(seats.size() == 2, "EXACT_TWO_REAL_SILENT_SEATED_GUESTS_SINGLE_FRAME"): finish(); return
	var started := Time.get_ticks_msec()
	var samples := 0
	while Time.get_ticks_msec() - started < 2100:
		await create_timer(0.10).timeout
		samples += 1
		if not need(_seat_state(room) == seats, "REAL_SEATED_NO_HEAD_TURN_SAMPLE:" + str(samples)): finish(); return
	if not need(samples >= 15 and _original_identity(room) == room_before and _business() == business_before, "SEATED_2S_ORIGINAL_BODY_OWNER_COMPILED_BUSINESS_IDENTICAL"): finish(); return
	if raw.get("decor_enabled") == true:
		if not need(room.get_meta("quality_20261101b_decor", {}).get("ok") == true, "ROOT_SEALED_DECOR_ACTUALLY_ATTACHED"): finish(); return
	if not await _capture("yihong_seated_wall_normal"): finish(); return
	await _key(KEY_S, 8)
	var exit: Node = _door(room, "yihongyuan27n_exit")
	if not need(exit != null and exit.call("_can_enter") == true, "CURRENT_REAL_ROOM_RETURN_DOOR_ENTERABLE"): finish(); return
	await _key(KEY_SPACE, 1)
	outside = await _wait_field("luoyang_civic_market_region_27d", true)
	if outside == null: finish(); return
	need((outside.get("_player") as Node2D).position.distance_to(Vector2(5206.18017578125, 4280)) <= 1 and _business() == business_before, "TRUE_EXIT_RETURNS_EXACT_CURRENT_STREET_FOOT_SAME_BUSINESS")
	finish()

func _setup(id: String, logical: String, foot: Vector2) -> bool:
	_previous_field_instance = current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
	var dispatcher: GDScript = load(DISPATCH) as GDScript
	var extension := {"region_id": id, "revision": 1, "logical_id": logical, "global_foot_px": [foot.x, foot.y]}
	records.append({"kind": "PUBLIC_VERSIONED_NEAR_SETUP_NOT_CONTINUOUS_TRAVEL", "region_id": id, "logical": logical, "foot": foot})
	return need(dispatcher != null and dispatcher.call("start", router, StringName(logical), Vector2(0.5, 0.5), "", -1, extension) == true, "EXISTING_PUBLIC_VERSIONED_SETUP:" + id)

func _wait_field(id: String, ground: bool) -> Node:
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 30000:
		await process_frame
		var field: Node = current_scene
		if not is_instance_valid(field) or field.get_script() == null or field.get_script().resource_path != FIELD: continue
		if field.get_instance_id() == _previous_field_instance: continue
		var region: Dictionary = field.get("_region")
		if String(region.get("id", "")) != id: continue
		if field.get("_field_loading_failed") == true: need(false, "FIELD_LOADING_FAILED:" + id); return null
		if field.get("_field_loading_complete") != true or field.get("_scene_rebuilding") == true: continue
		var loading: Node = root.get_node("LoadingManager")
		if loading.get("_transition_active") == true or loading.get("_external_active") == true: continue
		var quality: Dictionary = field.get_meta("scene_art_quality31b", {})
		if quality.get("ok") != true:
			if not String(host.call("get_debug_state").get("last_error", "")).is_empty(): need(false, "HOST_ATTACH_FAILED:" + id); return null
			continue
		var mini: Node = field.get("_world_travel_minimap")
		if ground and (not is_instance_valid(mini) or mini.call("get_debug_state").get("visual_cache_ready") != true): continue
		var player: Node = field.get("_player")
		if not is_instance_valid(player) or player.get("can_move") != true: continue
		await physics_frame; await RenderingServer.frame_post_draw
		return field
	need(false, "FINITE_30S_FIELD_BOUND:" + id); return null

func _flat_view_only(view: Node) -> bool:
	if view.get_script() != null: return false
	for child: Node in view.get_children():
		if not child is Polygon2D or child.get_script() != null or child.texture == null or child.get_child_count() != 0: return false
	return view.get_child_count() > 0

func _original_identity(field: Node) -> Dictionary:
	var owner: RefCounted = field.get("_region_owner") as RefCounted
	var bodies: Array = []
	for body: Node in (field.get("_collision_layer") as Node).get_children(): bodies.append(body.get_instance_id())
	return {"field": field.get_instance_id(), "player": field.get("_player").get_instance_id(), "scene": field.get("_current_scene").get_instance_id(), "owner": owner.get_instance_id(), "receipt": var_to_bytes(owner.call("receipt")), "compiled": var_to_bytes(field.get("_region")), "bodies": bodies}

func _seat_state(field: Node) -> Dictionary:
	var helper: GDScript = load("res://build/luoyang_quality_20261101b_seated01/live_seated_view.gd") as GDScript
	var actors: Dictionary = field.get("_region_actors")
	var result: Dictionary = {}
	for id: String in ["yihongyuan27n_elder_guest", "yihongyuan27n_woman_guest"]:
		var npc: NPCNode = actors.get(LOGICAL + "/" + id, {}).get("node") as NPCNode
		if not is_instance_valid(npc) or npc.movement_mode != "seated" or npc.sprite.hframes != 1 or npc.get("_hframes") != 1 or npc.sprite.frame != 0 or not npc.sprite.texture is AtlasTexture: return {}
		var texture: AtlasTexture = npc.sprite.texture as AtlasTexture
		if texture.region != Rect2(160, 0, 160, 160): return {}
		result[id] = {"body_and_original_fields": helper.call("_body_state", npc), "texture": texture.get_instance_id(), "frame": npc.sprite.frame, "hframes": npc.sprite.hframes, "idle_texture": npc.get("_idle_texture").get_instance_id()}
	return result

func _door(field: Node, id: String) -> Node:
	var rows: Dictionary = field.get("_region_portals")
	var matches: Array[Node] = []
	for zone: Node in field.get("_exit_nodes"):
		if String(rows.get(zone.get_instance_id(), {}).get("id", "")) == id: matches.append(zone)
	return matches[0] if matches.size() == 1 else null

func _key(code: int, ticks: int) -> void:
	await physics_frame
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true
	Input.parse_input_event(event); Input.flush_buffered_events()
	for _tick: int in range(ticks): await physics_frame; input_ticks += 1
	event = InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = false
	Input.parse_input_event(event); Input.flush_buffered_events(); await physics_frame; await process_frame

func _capture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	var path := OUTPUT + str(OS.get_process_id()) + "/" + name + ".png"
	if not need(image != null and image.get_size() == Vector2i(1920, 1080) and not FileAccess.file_exists(path), "NORMAL_UNALTERED_1920_IMAGE:" + name): return false
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if not need(image.save_png(path) == OK, "SAVE_NEW_EVIDENCE_IMAGE:" + name): return false
	records.append({"image": path, "sha256": FileAccess.get_sha256(path), "normal_camera": true}); return true

func finish() -> void:
	if finished: return
	finished = true
	for code: int in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE]:
		var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = false; Input.parse_input_event(event)
	Input.flush_buffered_events()
	if not first.is_empty(): need(first == _facts(), "INDEPENDENT_FROZEN_SOURCE_FIRST_FINAL")
	var path := OUTPUT + str(OS.get_process_id()) + "/quality_result.json"
	if FileAccess.file_exists(path): quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: quit(2); return
	file.store_string(JSON.stringify({"passed": errors.is_empty(), "checks": checks, "errors": errors, "records": records, "input_ticks": input_ticks, "elapsed_ms": Time.get_ticks_msec() - began, "save_file_reads": 0, "save_writes": 0, "actor_camera_writes": 0, "public_near_setups_not_continuous_travel": true, "old_success_matrices_replayed": false, "host": host.call("get_debug_state") if is_instance_valid(host) else {}}, "\t")); file.close()
	print("[SceneArtQuality31b QA] ", checks, " checks / ", errors.size(), " failures; ", path)
	quit(0 if errors.is_empty() else 1)
