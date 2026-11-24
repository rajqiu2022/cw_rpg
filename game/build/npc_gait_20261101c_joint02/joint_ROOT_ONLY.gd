extends "res://build/npc_gait_20261101c_qa01/gate_finite_ROOT_ONLY.gd"
## New joint successor. The frozen base/runtime/16-leaf manifest are unchanged.
const JOINT := "res://build/npc_gait_20261101c_joint02/"
const JOINT_INPUTS := JOINT + "joint_inputs_ROOT_READY.json"
const AUDIT := "res://build/luoyang_gate_front_walls_20261101c_system01/collector_audit_READY.gd"
const PAYLOAD := "res://build/luoyang_gate_front_walls_20261101c_system01/output/71200/payload.bin"
const PAYLOAD_SHA := "2c2186a0d59bbe2fb5b010b172e26f7676696e679351a1970051495f243c4246"
const WORLD_DISPATCH := "res://build/world_coast_20261031h_system02/world_contract_dispatch03.gd"
const WORLD_CONTRACT := "res://build/world_coast_20261031h_system02/world_v16_contract03.gd"
const RETIRED := ["seven26c_gate_west_waiting_front", "seven26c_gate_east_transfer_front"]
const RETAINED := ["seven26c_gate_west_return_south", "seven26c_gate_west_return_north", "seven26c_gate_east_transfer_cart", "seven26c_gate_east_transfer_sacks", "seven26c_gate_waiting_bench", "seven26c_gate_waiting_forecourt_gallery"]
var joint: Dictionary = {}
var wall_input_ticks := 0

func _entry_core() -> Dictionary:
	var game: Node = root.get_node("GameState")
	var hero: Resource = game.get("player") as Resource
	var party: Array = []
	for member: Resource in game.get("party"): party.append(member.get_instance_id())
	return {"hero_instance": hero.get_instance_id(), "hp": hero.get("hp"), "mp": hero.get("mp"), "gold": game.get("gold"), "party_instances": party}

func watch() -> void:
	await create_timer(180.0, true, false, true).timeout
	if not done: need(false, "JOINT_INDEPENDENT_180S_WATCHDOG"); finish()

func run() -> void:
	directory = JOINT + "actual/" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended, "JOINT_EARLIEST_CHECKPOINT_SUSPENDED"): finish(); return
	joint = JSON.parse_string(FileAccess.get_file_as_string(JOINT_INPUTS)) as Dictionary
	if not need(joint.get("schema") == "GATE_WALL_GAIT_JOINT_QA_20261101C_V2" and joint.get("ready") == true, "ROOT_SEALED_EXTRA_JOINT_QA_MANIFEST"): finish(); return
	if not need(FileAccess.get_sha256(MANIFEST) == joint.get("approved_gait_manifest_sha256"), "EXISTING_GAIT_FREEZE_9101DB37_UNCHANGED"): finish(); return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not need(manifest.get("ready") == true and manifest.get("source_pins", {}).size() == 16, "ORIGINAL_SIXTEEN_RUNTIME_LEAVES_UNCHANGED"): finish(); return
	pins = manifest.source_pins.duplicate(true)
	pins.merge(manifest.get("qa_pins", {}), false)
	for path: String in joint.get("required_source_paths", []):
		if not need(joint.get("source_pins", {}).has(path), "ROOT_EXPLICIT_EXTRA_JOINT_PIN:" + path): finish(); return
	for path: String in joint.get("source_pins", {}):
		var expected: String = String(joint.source_pins[path])
		if not need(expected.length() == 64 and (not pins.has(path) or pins[path] == expected), "NO_JOINT_OVERRIDE_OF_ALREADY_FROZEN_SOURCE:" + path): finish(); return
		pins[path] = expected
	pins[MANIFEST] = joint.approved_gait_manifest_sha256
	pins[JOINT_INPUTS] = FileAccess.get_sha256(JOINT_INPUTS)
	first = _facts()
	for path: String in pins:
		if not need(first[path].sha256 == pins[path], "JOINT_SOURCE_FIRST:" + path): finish(); return
	cfg = JSON.parse_string(FileAccess.get_file_as_string(INPUTS)) as Dictionary
	router = root.get_node("SceneRouter"); gait = root.get_node_or_null("NPCGaitRuntime"); dialogs = root.get_node("DialogPlayer")
	if not need(gait != null and gait.call("get_debug_state").get("ready") == true and gait.process_priority == 100, "ORIGINAL_GAIT_AUTOLOAD_READY"): finish(); return
	dialogs.connect("text_displayed", _on_text)
	if not await _world16_real_gate(): finish(); return
	if not _actual_gate_audit(): finish(); return
	for item: Dictionary in joint.wall_cases:
		if not await _wall_passage(item): finish(); return
	# This explicit local Gate request repositions the public near test only.
	# Do not repeat the original normal Gate bootstrap already covered above.
	if not await _setup(_point(cfg.near_foot_px) / _point(cfg.native_world_size_px), int(cfg.local_coordinate_version)): finish(); return
	var player: Node2D = field.get("_player") as Node2D
	if not need(player.position.distance_to(_point(cfg.near_foot_px)) < 0.03, "JOINT_PUBLIC_V3_GAIT_NEAR_FOOT"): finish(); return
	if not await _gait_tail(): finish(); return
	finish()

func _world16_real_gate() -> bool:
	var dispatch: GDScript = load(WORLD_DISPATCH) as GDScript
	var contract: GDScript = load(WORLD_CONTRACT) as GDScript
	if not need(dispatch != null and contract != null and int(dispatch.call("formal_version")) == 16 and joint.get("world_version") == 16, "CURRENT_FORMAL_WORLD16_NOT_OLD15"): return false
	var old: int = current_scene.get_instance_id() if is_instance_valid(current_scene) else 0
	var target: Vector2 = _point(joint.world_near_foot_px)
	var size: Vector2 = _point(joint.world_size_px)
	records.append({"public_world_near_setup_not_continuous_world_travel": true, "version": 16, "foot": target})
	if not need(router.call("go_field_smart", &"world_map_jianghu", target / size, "", 16, -1) == true, "PUBLIC_WORLD16_NEAR_REQUEST"): return false
	var until: int = Time.get_ticks_msec() + 30000
	var world_ready := false
	while not done and Time.get_ticks_msec() < until:
		await process_frame
		var candidate: Node = current_scene
		if not is_instance_valid(candidate) or candidate.get_instance_id() == old or router.call("get_current_field_id") != &"world_map_jianghu": continue
		if not candidate.has_method("get_field_loading_state"): continue
		var loading: Dictionary = candidate.call("get_field_loading_state")
		if loading.get("failed", false): return need(false, "FORMAL_WORLD16_LOAD_FAILED")
		if loading.get("complete") != true: continue
		var manager: Node = root.get_node("LoadingManager")
		if manager.get("_transition_active") == true or manager.get("_external_active") == true: continue
		var actor: Node2D = candidate.get("_player") as Node2D
		var container: Node2D = candidate.get("world_container") as Node2D
		var scene: SceneScript = candidate.get("_current_scene") as SceneScript
		if actor == null or container == null or scene == null or actor.get("can_move") != true: continue
		field = candidate
		for _index: int in range(3): await physics_frame; await process_frame
		if not need(container.to_local(actor.global_position).distance_to(target) < 0.04 and router.call("layered_world_contract", scene) == contract and contract.call("safe_foot", scene, target / size) == true, "ACTUAL_WORLD16_SOURCE_AND_EXACT_NEAR_FOOT"): return false
		world_ready = true; break
	if not need(world_ready, "FINITE_30S_FORMAL_WORLD16_READY"): return false
	var gate: ExitZone
	var count := 0
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.target_scene_id == String(GATE): gate = candidate; count += 1
	if not need(count == 1 and gate != null and gate.call("can_enter") == true, "ONE_ORIGINAL_WORLD_LUOYANG_DOOR_TRUE_CAN_ENTER"): return false
	var before: Dictionary = _entry_core()
	var world_instance: int = field.get_instance_id()
	await _key(KEY_SPACE)
	if not await _wait_field(world_instance): return false
	records.append({"true_original_world_space_to_gate": true, "arrival_foot": (field.get("_player") as Node2D).position, "gate_scene_instance": (field.get("_current_scene") as SceneScript).get_instance_id()})
	return need(_entry_core() == before, "TRUE_WORLD_GATE_ENTRY_SAME_HERO_PARTY_HP_MP_GOLD")

func _actual_gate_audit() -> bool:
	var auditor: GDScript = load(AUDIT) as GDScript
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if not need(auditor != null and scene != null and scene.scene_id == GATE, "REAL_GATE_SCENE_FOR_COLLECTOR_AUDIT"): return false
	var report: Dictionary = auditor.call("audit", scene)
	var bundle: GDScript = load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd") as GDScript
	var described: Dictionary = bundle.call("describe", GATE, report.get("actual_complete", {})) if bundle != null else {}
	records.append({"actual_GateScene_C_collector_complete_expected_and_B_describe": report, "actual_B_describe_accepted": not described.is_empty()})
	return need(report.get("passed") == true and int(report.get("actual_count", 0)) > 0 and report.get("actual_count") == report.get("expected_count") and report.get("missing", []).is_empty() and report.get("added", []).is_empty() and report.get("stale", []).is_empty() and not described.is_empty(), "ACTUAL_COMPLETE_GATE_C_EXPECTED_MAP_AND_B_DESCRIBE")

func _wall_owner_snapshot() -> Dictionary:
	var session: RefCounted = field.get("_finish25i") as RefCounted
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if session == null or scene == null or scene.scene_id != GATE or FileAccess.get_sha256(PAYLOAD) != PAYLOAD_SHA: return {}
	var state: Dictionary = session.get("_state")
	var payload: Dictionary = state.get("payload", {})
	if var_to_bytes(payload) != FileAccess.get_file_as_bytes(PAYLOAD) or state.get("finalized") != true or session.call("revalidate_boundary") != true: return {}
	var names: Dictionary = {}
	for sprite: Sprite2D in field.get("_scene_object_nodes"):
		if is_instance_valid(sprite): names[String(sprite.name)] = sprite
	for id: String in RETIRED:
		if names.has("SceneObject_" + id): return {}
		for key: String in ["visual_additions", "effective_navigation"]:
			for row: Dictionary in payload.get(key, []):
				if String(row.get("id", "")) == id: return {}
	var kept: Dictionary = {}
	for id: String in RETAINED:
		var rows: Array = payload.visual_additions.filter(func(row: Dictionary) -> bool: return row.get("id") == id)
		var sprite: Sprite2D = names.get("SceneObject_" + id) as Sprite2D
		if rows.size() != 1 or sprite == null or sprite.texture == null or not sprite.is_inside_tree(): return {}
		kept[id] = {"sprite_instance": sprite.get_instance_id(), "source_row": var_to_bytes(rows[0]).hex_encode()}
		if id in ["seven26c_gate_west_return_south", "seven26c_gate_west_return_north"]:
			var matching_bodies: Array = []
			for expected: PackedVector2Array in rows[0].city_v3_solid_polygons_px:
				var count := 0
				for body: Node in (field.get("_collision_layer") as Node).get_children():
					if not body is StaticBody2D or not body.has_meta("finish25i_source_ordinal"): continue
					for shape: Node in body.get_children():
						if shape is CollisionPolygon2D and var_to_bytes(shape.polygon) == var_to_bytes(expected) and body.collision_layer == 1:
							matching_bodies.append(body.get_instance_id()); count += 1
				if count != 1: return {}
			kept[id]["physical_body_instances"] = matching_bodies
	return {"field_instance": field.get_instance_id(), "scene_instance": scene.get_instance_id(), "owner_kind": state.get("owner_kind"), "owner_key": state.get("owner_key"), "token": state.get("token"), "binding_sha": state.get("binding_sha"), "payload_sha": PAYLOAD_SHA, "retired_front_ids_absent": RETIRED, "retained_owners": kept, "effective_solids": payload.effective_solids.size()}

func _wall_passage(item: Dictionary) -> bool:
	var start: Vector2 = _point(item.start_foot_px)
	if not await _setup(start / _point(cfg.native_world_size_px), 3): return false
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not need(player.position.distance_to(start) < 0.03 and shape != null and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size == Vector2(34, 24) and shape.position == Vector2.ZERO, "TRUE_PUBLIC_WALL_NEAR_WITH_FULL_NATIVE_34X24_FOOT:" + String(item.id)): return false
	var owner: Dictionary = _wall_owner_snapshot()
	if not need(not owner.is_empty() and owner.effective_solids == 58, "RETIRED_FRONT_ABSENT_OTHER_WALLS_PHYSICAL_OWNER_LIVE:" + String(item.id)): return false
	var event := InputEventKey.new(); event.keycode = KEY_W; event.physical_keycode = KEY_W; event.pressed = true
	Input.parse_input_event(event); Input.flush_buffered_events(); input_events += 1
	for _index: int in range(28):
		await physics_frame; await process_frame; wall_input_ticks += 1
		if player.position.y <= float(item.target_y) + 4.8: break
	event = InputEventKey.new(); event.keycode = KEY_W; event.physical_keycode = KEY_W; event.pressed = false
	Input.parse_input_event(event); Input.flush_buffered_events(); input_events += 1
	await physics_frame; await process_frame; await RenderingServer.frame_post_draw
	var end: Vector2 = player.position
	if not need(absf(end.x - start.x) < 0.03 and absf(end.y - float(item.target_y)) <= 6.0 and start.y - 12.0 > 1980.0 and end.y + 12.0 < 1971.6, "REAL_W_FULL_FOOT_COMPLETELY_CROSSED_OLD_FRONT_POLYGON:" + String(item.id)): return false
	if not need(var_to_bytes(_wall_owner_snapshot()) == var_to_bytes(owner), "SAME_OTHER_WALL_OWNER_AND_PHYSICAL_INSTANCES_AFTER_REAL_W:" + String(item.id)): return false
	records.append({"retired_wall_id": item.id, "public_near_start": start, "true_W_end": end, "native_foot_size": Vector2(34, 24), "old_wall_y_interval": [1971.6, 1980.0], "full_foot_crossed": true, "unrelated_wall_owner": owner})
	if String(item.id) == "seven26c_gate_east_transfer_front": return await _capture("east_retired_front_wall_true_W_normal")
	return true

func _gait_tail() -> bool:
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
		if not need(npc != null and initial.has(id), "JOINT_REAL_GAIT_TARGET:" + id): return false
		var state: Dictionary = initial[id]
		if id in cfg.guard_ids:
			if not need(npc.walk_sprite_path == cfg.source_walk_path and state.frame_count == 4 and state.family == "guard", "JOINT_CURRENT_ARMOUR_4F:" + id): return false
		else:
			if not need(state.family == "merchant" and state.frame_count == 8, "JOINT_MERCHANT_FAMILY_8F"): return false
		metrics[id] = {"instance": npc.get_instance_id(), "previous_position": npc.position, "independent_travel": 0.0, "host_travel_start": state.actual_travel_px, "previous_flip": npc.sprite.flip_h, "previous_frame": npc.sprite.frame, "flip_changes": 0, "frame_changes": 0, "max_mid_speed": 0.0, "min_endpoint_speed": 1000000.0, "endpoint_samples": 0, "samples": 0, "native_origin": npc.get("_patrol_origin"), "native_radius": npc.patrol_distance, "peak": state.applied_speed, "cycle": state.cycle_distance_px}
	business_before = _business()
	if not await _observe(targets, metrics, float(cfg.observation_seconds)): return false
	for id: String in targets:
		var measured: Dictionary = metrics[id]
		need(measured.samples >= 60 and measured.frame_changes >= 3, "JOINT_REAL_MOVING_SAMPLES:" + id)
		need(measured.flip_changes >= 1, "JOINT_NATIVE_FLIP_ONCE:" + id)
		need(measured.max_mid_speed >= float(measured.peak) * 0.75, "JOINT_MIDLANE_SPEED:" + id)
		need(measured.endpoint_samples > 0 and measured.min_endpoint_speed < float(measured.peak) * 0.25, "JOINT_ENDPOINT_SLOW_PHASE:" + id)
		measured.erase("previous_position"); measured.erase("previous_flip"); measured.erase("previous_frame")
	records.append({"reused_original_gait_observer": true, "observation_seconds": cfg.observation_seconds, "three_target_metrics": metrics})
	if not need(float(metrics[String(cfg.guard_ids[0])].peak) > float(metrics[String(cfg.merchant_id)].peak) * 1.2 and _business() == business_before, "JOINT_ROLE_SPEED_AND_BUSINESS_PRESERVED"): return false
	if not await _capture("gate_dual_armoured_patrol_normal"): return false
	if not await _real_daily(String(cfg.conversation_id)): return false
	return need(_business() == business_before, "JOINT_REAL_DAILY_NO_NEW_BUSINESS_EFFECT")

func finish() -> void:
	if done: return
	records.append({"joint_scope": "one original World16 true Space Gate entry / complete actual collector+B.describe / two retired-front true W crossings / inherited10.5s gait+realDaily", "wall_physics_input_ticks": wall_input_ticks, "images_maximum": 3, "old_gait_runtime_manifest_and_QA_base_unchanged": true, "no_battle_or_other_gate_matrix": true})
	super.finish()
