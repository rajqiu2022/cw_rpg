extends SceneTree
## Root-only real Gate observation and original daily dialogue input. No fake
## begin_conversation, actor/phase/camera writes, private Router writes or saves.
const HOME := "res://build/npc_gait_20261101c_qa01/"
const CANDIDATE := "res://build/npc_gait_20261101c_candidate01/"
const MANIFEST := CANDIDATE + "source_pins_READY.json"
const INPUTS := HOME + "gate_inputs_ROOT_READY.json"
const FIELD := "res://scripts/field/field_walkable_controller.gd"
const GATE := &"ch4_s0_luoyang_gate"
const Model = preload("res://build/npc_gait_20261101c_candidate01/distance_phase.gd")
var cfg: Dictionary = {}
var errors: Array[String] = []
var records: Array = []
var samples: Array = []
var checks := 0
var input_events := 0
var done := false
var suspended := false
var directory := ""
var router: Node
var gait: Node
var dialogs: Node
var field: Node
var pins: Dictionary = {}
var first: Dictionary = {}
var business_before: Dictionary = {}
var dialog_events: Array = []

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children(): _early(node)
	run.call_deferred(); watch.call_deferred()
func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended", true)
		suspended = node.call("is_checkpoint_saves_suspended") == true
func watch() -> void:
	await create_timer(120.0, true, false, true).timeout
	if not done: need(false, "INDEPENDENT_120S_WATCHDOG"); finish()
func need(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: errors.append(label); printerr("GAIT31C_FAIL ", label)
	return ok
func _point(raw: Array) -> Vector2: return Vector2(float(raw[0]), float(raw[1]))
func _facts() -> Dictionary:
	var facts: Dictionary = {}
	for path: String in pins:
		var file := FileAccess.open(path, FileAccess.READ)
		facts[path] = {"sha256": FileAccess.get_sha256(path), "bytes": file.get_length() if file != null else -1, "mtime_seconds": FileAccess.get_modified_time(path)}
	return facts
func _business() -> Dictionary:
	# Memory serialization only, no real save/load or file content access.
	var game: Node = root.get_node("GameState")
	var serializer: Node = root.get_node("SaveManager")
	var hero: Resource = game.get("player") as Resource
	var party: Array = []
	for member: Resource in game.get("party"): party.append({"instance": member.get_instance_id(), "data": serializer.call("_serialize_stats", member)})
	return {"hero_instance": hero.get_instance_id(), "hero": serializer.call("_serialize_stats", hero), "party": party, "gold": game.get("gold"), "flags": game.get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict"), "inventory": root.get_node("Inventory").call("to_dict")}.duplicate(true)
func _actor(id: String) -> NPCNode:
	var found: NPCNode
	for npc: NPCNode in field.get("_npc_nodes"):
		if is_instance_valid(npc) and npc.npc_id == id:
			if found != null: return null
			found = npc
	return found
func _states() -> Dictionary:
	var result: Dictionary = {}
	for state: Dictionary in gait.call("get_debug_state").get("actors", []):
		if result.has(state.id): return {}
		result[state.id] = state
	return result
func _wait_field(previous: int) -> bool:
	var until: int = Time.get_ticks_msec() + 30000
	while not done and Time.get_ticks_msec() < until:
		await process_frame
		var candidate: Node = current_scene
		if not is_instance_valid(candidate) or candidate.get_instance_id() == previous or candidate.get_script() == null or candidate.get_script().resource_path != FIELD: continue
		var scene: SceneScript = candidate.get("_current_scene") as SceneScript
		if scene == null or scene.scene_id != GATE: continue
		var loading: Dictionary = candidate.call("get_field_loading_state")
		if loading.get("failed", false): return need(false, "ACTUAL_GATE_LOAD_FAILED")
		if loading.get("complete") != true or candidate.get("_scene_rebuilding") == true: continue
		var loader: Node = root.get_node("LoadingManager")
		if loader.get("_transition_active") == true or loader.get("_external_active") == true: continue
		var player: Node = candidate.get("_player")
		if not is_instance_valid(player) or player.get("can_move") != true: continue
		field = candidate
		await physics_frame; await RenderingServer.frame_post_draw
		return true
	records.append({"gate_preparation": router.call("get_public_city_preparation_state")})
	return need(false, "ACTUAL_GATE_FINITE_30S_READY")
func _setup(spawn: Variant, local_version: int) -> bool:
	var previous: int = current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
	records.append({"public_near_setup_not_continuous_world_travel": true, "scene": GATE, "spawn_uv": spawn, "local_version": local_version})
	if not need(router.call("go_field_smart", GATE, spawn, "", -1, local_version) == true, "EXISTING_PUBLIC_GATE_REQUEST"): return false
	return await _wait_field(previous)
func _key(code: Key) -> void:
	await physics_frame
	var event := InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = true
	Input.parse_input_event(event); Input.flush_buffered_events(); input_events += 1
	await physics_frame
	event = InputEventKey.new(); event.keycode = code; event.physical_keycode = code; event.pressed = false
	Input.parse_input_event(event); Input.flush_buffered_events(); input_events += 1
	await process_frame; await RenderingServer.frame_post_draw
func _capture(label: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_viewport().get_texture().get_image()
	if not need(image != null and image.get_size() == Vector2i(1920, 1080), "NORMAL_1920_CAMERA_NO_QA_CAMERA_WRITES:" + label): return false
	var path: String = directory + "/" + label + ".png"
	if not need(image.save_png(path) == OK, "NORMAL_IMAGE_SAVED:" + label): return false
	records.append({"image": path, "sha256": FileAccess.get_sha256(path), "normal_camera": true})
	return true
func _on_text(speaker: String, text: String, choices: bool, portrait: String) -> void:
	dialog_events.append({"speaker": speaker, "text": text, "choices": choices, "portrait": portrait})

func run() -> void:
	directory = HOME + "actual/" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended, "EARLIEST_CHECKPOINT_SUSPEND_NO_REAL_SAVE_API"): finish(); return
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not need(manifest is Dictionary and manifest.get("ready") == true and manifest.get("source_pins", {}).size() == 16, "ROOT_FROZEN_SIXTEEN_INDEPENDENT_LEAVES"): finish(); return
	pins = manifest.source_pins.duplicate(true)
	pins.merge(manifest.get("qa_pins", {}), false)
	pins[MANIFEST] = FileAccess.get_sha256(MANIFEST)
	if not need(pins.has(INPUTS) and pins.has(HOME + "gate_finite_ROOT_ONLY.gd"), "ROOT_FROZEN_QA_AND_PUBLIC_NEAR_FIXTURE"): finish(); return
	first = _facts()
	for path: String in pins:
		if not need(first[path].sha256 == pins[path], "SOURCE_FIRST:" + path): finish(); return
	cfg = JSON.parse_string(FileAccess.get_file_as_string(INPUTS)) as Dictionary
	if not need(cfg.get("schema") == "NPC_GAIT_GATE_FINITE_QA_20261101C_V1" and cfg.get("observation_seconds") >= 8.0 and cfg.get("observation_seconds") <= 12.0, "FINITE_APPROVED_QA_SCOPE"): finish(); return
	router = root.get_node("SceneRouter"); gait = root.get_node_or_null("NPCGaitRuntime"); dialogs = root.get_node("DialogPlayer")
	if not need(gait != null and gait.call("get_debug_state").get("ready") == true and gait.process_priority == 100, "ACTUAL_NEW_AUTOLOAD_READY_AND_LATE_PROCESS"): finish(); return
	dialogs.connect("text_displayed", _on_text)
	# Bootstrap establishes the real public city's local coordinate context; a
	# later explicit same-Gate v3 request supplies the honest near setup.
	if not await _setup(null, -1): finish(); return
	if not await _setup(_point(cfg.near_foot_px) / _point(cfg.native_world_size_px), int(cfg.local_coordinate_version)): finish(); return
	var player: Node2D = field.get("_player") as Node2D
	if not need(player.position.distance_to(_point(cfg.near_foot_px)) < 0.03, "PUBLIC_V3_NEAR_FOOT_NOT_ACTOR_TELEPORT"): finish(); return
	var targets: Array[String] = []
	for id: String in cfg.guard_ids: targets.append(id)
	targets.append(String(cfg.merchant_id))
	var until: int = Time.get_ticks_msec() + 2500
	while Time.get_ticks_msec() < until:
		await process_frame; await RenderingServer.frame_post_draw
		var ready := true
		for id: String in targets:
			if not _states().has(id): ready = false
		if ready: break
	var initial: Dictionary = _states()
	var metrics: Dictionary = {}
	for id: String in targets:
		var npc: NPCNode = _actor(id)
		if not need(npc != null and initial.has(id), "ACTUAL_FINITE_TARGET_LEASE:" + id): finish(); return
		var state: Dictionary = initial[id]
		if id in cfg.guard_ids:
			if not need(npc.walk_sprite_path == cfg.source_walk_path and state.frame_count == 4 and state.family == "guard", "TRUE_CURRENT_ARMOUR_4F_LAST_CONSUMER:" + id): finish(); return
		else:
			if not need(state.family == "merchant" and state.frame_count == 8, "SAME_MECHANISM_MERCHANT_8F_NOT_BLIND_GUARD_SPEED"): finish(); return
		metrics[id] = {"instance": npc.get_instance_id(), "previous_position": npc.position, "independent_travel": 0.0, "host_travel_start": state.actual_travel_px, "previous_flip": npc.sprite.flip_h, "previous_frame": npc.sprite.frame, "flip_changes": 0, "frame_changes": 0, "max_mid_speed": 0.0, "min_endpoint_speed": 1000000.0, "endpoint_samples": 0, "samples": 0, "native_origin": npc.get("_patrol_origin"), "native_radius": npc.patrol_distance, "peak": state.applied_speed, "cycle": state.cycle_distance_px}
	business_before = _business()
	if not await _observe(targets, metrics, float(cfg.observation_seconds)): finish(); return
	for id: String in targets:
		var measured: Dictionary = metrics[id]
		need(measured.samples >= 60 and measured.frame_changes >= 3, "FINITE_REAL_MOVING_FRAME_SAMPLES:" + id)
		need(measured.flip_changes >= 1, "ONE_NATURAL_NATIVE_DIRECTION_FLIP:" + id)
		need(measured.max_mid_speed >= float(measured.peak) * 0.75, "REAL_MIDLANE_SPEED_NOT_ONLY_TIMER_CHANGE:" + id)
		need(measured.endpoint_samples > 0 and measured.min_endpoint_speed < float(measured.peak) * 0.25, "NATIVE_ENDPOINT_SLOWS_WITH_DISTANCE_PHASE:" + id)
		measured.erase("previous_position"); measured.erase("previous_flip"); measured.erase("previous_frame")
	records.append({"observation_seconds": cfg.observation_seconds, "three_target_metrics": metrics})
	need(float(metrics[String(cfg.guard_ids[0])].peak) > float(metrics[String(cfg.merchant_id)].peak) * 1.2, "ROLE_FAMILY_MERCHANT_REMAINS_SLOWER_THAN_PATROL")
	if not need(_business() == business_before, "OBSERVATION_NO_BUSINESS_EFFECTS"): finish(); return
	if not await _capture("gate_dual_armoured_patrol_normal"): finish(); return
	if not await _real_daily(String(cfg.conversation_id)): finish(); return
	need(_business() == business_before, "ORIGINAL_DAILY_NO_NEW_BUSINESS_EFFECTS")
	finish()

func _observe(targets: Array[String], metrics: Dictionary, seconds: float) -> bool:
	var began: int = Time.get_ticks_msec()
	while not done and Time.get_ticks_msec() - began < int(seconds * 1000.0):
		await process_frame; await RenderingServer.frame_post_draw
		var states: Dictionary = _states()
		for id: String in targets:
			var npc: NPCNode = _actor(id)
			if not need(npc != null and states.has(id), "SAME_ACTOR_AND_LEASE_DURING_OBSERVATION:" + id): return false
			var state: Dictionary = states[id]
			var measured: Dictionary = metrics[id]
			var ds: float = absf((npc.position - (measured.previous_position as Vector2)).dot(npc.patrol_axis.normalized()))
			measured.previous_position = npc.position
			measured.independent_travel += ds
			var host_delta: float = float(state.actual_travel_px) - float(measured.host_travel_start)
			var expected: int = Model.frame_for_distance(float(state.distance_px), float(state.cycle_distance_px), state.fractions)
			if not need(absf(host_delta - float(measured.independent_travel)) < 0.001 and npc.sprite.frame == expected, "REAL_DS_ACCUMULATION_AND_FINAL_FRAME:" + id): return false
			if not need(state.body_typed_identical == true and npc.get("_patrol_origin") == measured.native_origin and npc.patrol_distance == measured.native_radius and npc.is_processing(), "ORIGINAL_BODY_ROUTE_PROCESS_UNCHANGED:" + id): return false
			var phase: float = float(npc.get("_patrol_phase"))
			if not need(npc.sprite.flip_h == ((cos(phase) < 0.0) != npc.invert_patrol_facing), "ORIGINAL_NATIVE_MIRROR_RULE:" + id): return false
			var delta: float = npc.get_process_delta_time()
			var speed: float = float(state.last_ds) / delta if delta > 0.0 else 0.0
			if absf(cos(phase)) > 0.90: measured.max_mid_speed = maxf(float(measured.max_mid_speed), speed)
			if absf(cos(phase)) < 0.10:
				measured.min_endpoint_speed = minf(float(measured.min_endpoint_speed), speed); measured.endpoint_samples += 1
			if npc.sprite.flip_h != measured.previous_flip: measured.flip_changes += 1
			if npc.sprite.frame != measured.previous_frame: measured.frame_changes += 1
			measured.previous_flip = npc.sprite.flip_h; measured.previous_frame = npc.sprite.frame; measured.samples += 1
			samples.append({"elapsed_ms": Time.get_ticks_msec() - began, "id": id, "position": npc.position, "actual_ds": ds, "distance_phase_px": state.distance_px, "cycle_px": state.cycle_distance_px, "expected_frame": expected, "actual_frame": npc.sprite.frame, "native_sin_phase": phase, "native_flip_h": npc.sprite.flip_h, "actual_speed": speed})
	return errors.is_empty()

func _freeze_snapshot(npc: NPCNode) -> Dictionary:
	var state: Dictionary = _states().get(npc.npc_id, {})
	return {"position": npc.position, "native_phase": npc.get("_patrol_phase"), "texture_instance": npc.sprite.texture.get_instance_id(), "frame": npc.sprite.frame, "flip": npc.sprite.flip_h, "distance_phase_px": state.get("distance_px"), "actual_travel_px": state.get("actual_travel_px")}
func _real_daily(id: String) -> bool:
	var npc: NPCNode = _actor(id)
	var player: Node2D = field.get("_player") as Node2D
	if not need(npc != null and npc.interaction_action == "ambient25i_daily" and npc.get_meta("ambient25i_exact_identity", false) == true and player.global_position.distance_to(npc.global_position) <= 118.0, "EXISTING_REAL_DAILY_ACTOR_WITHIN_SPACE_RANGE"): return false
	dialog_events.clear()
	await _key(KEY_SPACE)
	var ambient: Dictionary = field.call("get_ambient25i_state")
	var script: DialogScript = dialogs.get("_current_script") as DialogScript
	if not need(dialogs.call("is_playing") == true and script != null and ambient.get("active") == true and ambient.get("npc_id") == id and ambient.get("dialog_id") == String(script.dialog_id) and field.get("_active_dialog_npc") == npc and npc.get("_conversation_active") == true, "REAL_SPACE_OPENED_ORIGINAL_AMBIENT_SESSION_NOT_DIRECT_BEGIN"): return false
	var hero: Resource = root.get_node("GameState").get("player") as Resource
	if not need(not dialog_events.is_empty() and dialog_events[0].speaker == hero.get("display_name"), "REAL_ORIGINAL_HERO_OPENING_OBSERVED"): return false
	var frozen: Dictionary = _freeze_snapshot(npc)
	var conversation_start_samples: int = int(_states()[id].conversation_samples)
	var until: int = Time.get_ticks_msec() + 1300
	while Time.get_ticks_msec() < until:
		await process_frame; await RenderingServer.frame_post_draw
		if not need(_freeze_snapshot(npc) == frozen and dialogs.call("is_playing") == true, "REAL_DIALOGUE_POSITION_TEXTURE_FRAME_DISTANCE_PHASE_FROZEN"): return false
	await _key(KEY_ESCAPE)
	if not need(dialogs.call("is_playing") == true and dialogs.get("_current_script") == script and _freeze_snapshot(npc) == frozen, "TRUE_ESC_PRESERVES_ORIGINAL_DIALOGUE_FREEZE_NO_FAKE_CANCEL"): return false
	if not need(int(_states()[id].conversation_samples) > conversation_start_samples, "LATE_ADDON_RECOGNIZED_NATIVE_CONVERSATION_AND_DID_NOT_OVERRIDE"): return false
	if not await _capture("gate_original_daily_freeze_normal"): return false
	for _index: int in range(6):
		if dialogs.call("is_playing") != true: break
		await _key(KEY_SPACE)
		await create_timer(0.10).timeout
	if not need(dialogs.call("is_playing") != true and npc.get("_conversation_active") == false and player.get("can_move") == true, "REAL_SPACE_COMPLETES_ORIGINAL_DIALOGUE_AND_RELEASES_MOVEMENT"): return false
	var old_distance: float = float(frozen.distance_phase_px)
	var began: int = Time.get_ticks_msec()
	var resumed := false
	while Time.get_ticks_msec() - began < 1000:
		await process_frame; await RenderingServer.frame_post_draw
		var state: Dictionary = _states().get(id, {})
		if state.is_empty() or npc.sprite.texture != npc.get("_walk_texture"): continue
		var expected: int = Model.frame_for_distance(float(state.distance_px), float(state.cycle_distance_px), state.fractions)
		if not need(npc.sprite.frame == expected and float(state.distance_px) >= old_distance and float(state.distance_px) - old_distance <= float(state.applied_speed) * 1.3 + 2.0 and state.body_typed_identical == true, "RESUME_USES_PRESERVED_DISTANCE_PHASE_NOT_DIALOGUE_CLOCK_CATCHUP"): return false
		if float(state.distance_px) > old_distance + 0.01: resumed = true
	records.append({"real_daily_id": id, "script_id": String(script.dialog_id), "actor_instance": npc.get_instance_id(), "freeze_before_esc": frozen, "text_events": dialog_events.duplicate(true), "space_open": true, "esc_not_a_cancel_feature": true, "space_natural_finish": true})
	return need(resumed, "REAL_PATROL_RESUMED_AFTER_ORIGINAL_DAILY")

func finish() -> void:
	if done: return
	done = true
	if not pins.is_empty(): need(_facts() == first, "EXACT_INDEPENDENT_AND_QA_SOURCE_FIRST_FINAL_IDENTICAL")
	if directory.is_empty(): directory = HOME + "actual/" + str(OS.get_process_id()); DirAccess.make_dir_recursive_absolute(directory)
	var result: Dictionary = {"passed": errors.is_empty(), "checks": checks, "errors": errors, "records": records, "input_events": input_events, "samples": samples, "real_save_API_calls": 0, "save_file_content_reads": 0, "actor_camera_phase_writes": 0, "no_battle_or_other_city_matrix": true, "dynamic_art_acceptance_requires_root_viewing": true}
	var file := FileAccess.open(directory + "/result.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "  ") + "\n"); file.close()
	print("[Gait31c finite QA] ", checks, " / ", errors.size(), " failures; ", directory)
	quit(0 if errors.is_empty() else 1)
