extends "res://build/npc_gait_20261101c_joint02/joint_ROOT_ONLY.gd"
## Root-approved QA-only x650 pillar gap. Keep actual102424 FAIL and all of its
## proven World/C/B work; neither successful component is executed here again.
const RESIDUAL := "res://build/npc_gait_20261101c_residual03/"
const RESIDUAL_INPUTS := RESIDUAL + "residual_inputs_ROOT_READY.json"

func run() -> void:
	directory = RESIDUAL + "actual/" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended, "RESIDUAL_EARLIEST_CHECKPOINT_SUSPENDED"): finish(); return
	joint = JSON.parse_string(FileAccess.get_file_as_string(RESIDUAL_INPUTS)) as Dictionary
	if not need(joint.get("schema") == "GATE_WALL_GAIT_RESIDUAL_20261101C_V3" and joint.get("ready") == true, "ROOT_SEALED_RESIDUAL_QA_MANIFEST"): finish(); return
	if not need(FileAccess.get_sha256(MANIFEST) == joint.approved_gait_manifest_sha256, "ORIGINAL_GAIT_FREEZE_9101DB37_UNCHANGED"): finish(); return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	pins = manifest.source_pins.duplicate(true); pins.merge(manifest.get("qa_pins", {}), false)
	for path: String in joint.required_source_paths:
		if not need(joint.source_pins.has(path), "ROOT_EXPLICIT_RESIDUAL_PIN:" + path): finish(); return
	for path: String in joint.source_pins:
		var expected: String = String(joint.source_pins[path])
		if not need(expected.length() == 64 and (not pins.has(path) or pins[path] == expected), "RESIDUAL_DOES_NOT_OVERRIDE_EXISTING_PIN:" + path): finish(); return
		pins[path] = expected
	pins[MANIFEST] = joint.approved_gait_manifest_sha256
	pins[RESIDUAL_INPUTS] = FileAccess.get_sha256(RESIDUAL_INPUTS)
	first = _facts()
	for path: String in pins:
		if not need(first[path].sha256 == pins[path], "RESIDUAL_SOURCE_FIRST:" + path): finish(); return
	if not _inherit_proven_prefix(): finish(); return
	var registry: GDScript = load("res://build/three_towns_world_20261029j_system01/town_registry.gd") as GDScript
	if not need(registry != null and registry.call("source_valid") == true, "EXACT_NATIVE_SOURCE_VALID_AFTER_APPROVED_TWO_PIN_REPAIR_NO_TRAVEL"): finish(); return
	cfg = JSON.parse_string(FileAccess.get_file_as_string(INPUTS)) as Dictionary
	router = root.get_node("SceneRouter"); gait = root.get_node_or_null("NPCGaitRuntime"); dialogs = root.get_node("DialogPlayer")
	if not need(gait != null and gait.call("get_debug_state").get("ready") == true, "UNCHANGED_GAIT_AUTOLOAD_READY"): finish(); return
	dialogs.connect("text_displayed", _on_text)
	records.append({"direct_Gate_bootstrap_context_only": true, "World_entry_and_C_B_audit_not_repeated": true})
	if not await _setup(null, -1): finish(); return
	for item: Dictionary in joint.wall_cases:
		if not await _wall_passage(item): finish(); return
	if not await _setup(_point(cfg.near_foot_px) / _point(cfg.native_world_size_px), int(cfg.local_coordinate_version)): finish(); return
	if not await _gait_tail(): finish(); return
	finish()

func _inherit_proven_prefix() -> bool:
	if not need(FileAccess.get_sha256(joint.inherited_report) == joint.inherited_report_sha256, "IMMUTABLE_102424_WHOLE_FAIL_REPORT_PRESERVED"): return false
	var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(joint.inherited_report)) as Dictionary
	var worlds: Array = prior.get("records", []).filter(func(row: Dictionary) -> bool: return row.get("true_original_world_space_to_gate") == true)
	var collectors: Array = prior.get("records", []).filter(func(row: Dictionary) -> bool: return row.has("actual_GateScene_C_collector_complete_expected_and_B_describe"))
	if not need(prior.get("passed") == false and prior.get("errors") == ["REAL_W_FULL_FOOT_COMPLETELY_CROSSED_OLD_FRONT_POLYGON:seven26c_gate_west_waiting_front"] and worlds.size() == 1 and collectors.size() == 1, "EXACT_PRIOR_FAIL_SCOPE_WITH_PROVEN_PREFIX"): return false
	var audit: Dictionary = collectors[0].actual_GateScene_C_collector_complete_expected_and_B_describe
	if not need(audit.get("passed") == true and audit.get("actual_count") == 1727 and audit.get("expected_count") == 1727 and collectors[0].get("actual_B_describe_accepted") == true, "INHERITED_TRUE_WORLD_ENTRY_AND_COMPLETE_1727_C_B_PASS_NO_RERUN"): return false
	records.append({"inherited_only_not_executed_here": ["originalWorld16_trueSpace_Gate", "actualGateScene_complete1727_C_expected_B_describe"], "report": joint.inherited_report, "report_sha256": joint.inherited_report_sha256, "prior_whole_passed": false, "old_endfoot_missing_not_invented": true})
	return true

func _physics_at(player: CharacterBody2D, foot: Vector2) -> Array:
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var container: Node2D = field.get("world_container") as Node2D
	if shape == null or container == null: return []
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape
	var requested_transform: Transform2D = shape.global_transform
	requested_transform.origin = container.to_global(foot)
	query.transform = requested_transform
	query.collision_mask = player.collision_mask
	query.collide_with_bodies = true; query.collide_with_areas = false
	var exclude: Array[RID] = [player.get_rid()]; query.exclude = exclude
	var result: Array = []
	var session: RefCounted = field.get("_finish25i") as RefCounted
	var payload: Dictionary = session.get("_state").get("payload", {})
	for hit: Dictionary in player.get_world_2d().direct_space_state.intersect_shape(query, 32):
		var body: Node = hit.get("collider") as Node
		var owners: Array[String] = []
		if is_instance_valid(body):
			for polygon: Node in body.get_children():
				if not polygon is CollisionPolygon2D: continue
				for row: Dictionary in payload.get("effective_navigation", []):
					for source: PackedVector2Array in row.get("city_v3_solid_polygons_px", []):
						if var_to_bytes(source) == var_to_bytes(polygon.polygon): owners.append(String(row.get("id", "")))
		result.append({"collider_path": String(body.get_path()) if is_instance_valid(body) else "", "instance": body.get_instance_id() if is_instance_valid(body) else 0, "source_ordinal": body.get_meta("finish25i_source_ordinal", -1) if is_instance_valid(body) else -1, "source_owners": owners})
	return result

func _motion_facts(player: CharacterBody2D, requested: Vector2) -> Dictionary:
	var container: Node2D = field.get("world_container") as Node2D
	var constraint: Callable = player.get("movement_constraint")
	var slides: Array = []
	for index: int in range(player.get_slide_collision_count()):
		var collision: KinematicCollision2D = player.get_slide_collision(index)
		var collider: Object = collision.get_collider()
		slides.append({"collider_path": String((collider as Node).get_path()) if collider is Node else str(collider), "normal": collision.get_normal(), "position": collision.get_position()})
	return {"foot": player.position, "velocity": player.velocity, "can_move": player.can_move, "is_physics_processing": player.is_physics_processing(), "move_up_pressed": Input.is_action_pressed("move_up"), "input_vector": Input.get_vector("move_left", "move_right", "move_up", "move_down"), "requested_next_foot": requested, "movement_constraint_valid": constraint.is_valid(), "movement_constraint_accepts_next": constraint.call(container.to_global(requested)) if constraint.is_valid() else true, "slide_collisions": slides}

func _wall_passage(item: Dictionary) -> bool:
	var start: Vector2 = _point(item.start_foot_px)
	if not await _setup(start / _point(cfg.native_world_size_px), 3): return false
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var owner: Dictionary = _wall_owner_snapshot()
	if not need(player.position.distance_to(start) < 0.03 and shape != null and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size == Vector2(34, 24) and shape.position == Vector2.ZERO and not owner.is_empty(), "RESIDUAL_REAL_NATIVE_FULL_FOOT_AND_RETAINED_OWNER:" + String(item.id)): return false
	var session: RefCounted = field.get("_finish25i") as RefCounted
	var before: Dictionary = {"kind": "PRE_INPUT_ACTUAL_FIELD_GEOMETRY_QUERY_NOT_ACTOR_TELEPORT", "wall": item.id, "actual_actor_foot": player.position, "body_shape": (shape.shape as RectangleShape2D).size, "body_offset": shape.position, "old_x600_path_safe": session.call("safe_motion", Vector2(600, 2010), Vector2(600, 1940)), "old_x600_requested_1978_safe": session.call("safe_foot", Vector2(600, 1978), true), "old_x600_1978_actual_physics_hits": _physics_at(player, Vector2(600, 1978)), "approved_current_path_safe": session.call("safe_motion", start, Vector2(start.x, float(item.target_y))), "actual_input_and_constraint_before_press": _motion_facts(player, start + Vector2(0, -8))}
	records.append(before)
	if not need(before.approved_current_path_safe == true, "APPROVED_QA_PILLAR_GAP_FULL_PATH_SAFE_BEFORE_INPUT:" + String(item.id)): return false
	var ticks: Array = []
	var event := InputEventKey.new(); event.keycode = KEY_W; event.physical_keycode = KEY_W; event.pressed = true
	Input.parse_input_event(event); Input.flush_buffered_events(); input_events += 1
	for index: int in range(28):
		await physics_frame; await process_frame; wall_input_ticks += 1
		ticks.append({"tick": index, "facts": _motion_facts(player, player.position + Vector2(0, -8))})
		if player.position.y <= float(item.target_y) + 4.8: break
	event = InputEventKey.new(); event.keycode = KEY_W; event.physical_keycode = KEY_W; event.pressed = false
	Input.parse_input_event(event); Input.flush_buffered_events(); input_events += 1
	await physics_frame; await process_frame; await RenderingServer.frame_post_draw
	var end: Vector2 = player.position
	# Always record the actual failure evidence BEFORE any success oracle returns.
	records.append({"kind": "ACTUAL_W_TRACE_BEFORE_ORACLE", "wall": item.id, "start": start, "end": end, "ticks": ticks, "end_facts": _motion_facts(player, end + Vector2(0, -8)), "end_physics_hits": _physics_at(player, end), "next_step_physics_hits": _physics_at(player, end + Vector2(0, -8)), "remaining_owner_identical": var_to_bytes(_wall_owner_snapshot()) == var_to_bytes(owner)})
	if not need(absf(end.x - start.x) < 0.03 and absf(end.y - float(item.target_y)) <= 6.0 and start.y - 12.0 > 1980.0 and end.y + 12.0 < 1971.6, "RESIDUAL_REAL_W_FULL_FOOT_CROSSED_RETIRED_WALL:" + String(item.id)): return false
	if not need(var_to_bytes(_wall_owner_snapshot()) == var_to_bytes(owner), "RESIDUAL_RETAINED_WALL_AND_GALLERY_OWNER_UNCHANGED:" + String(item.id)): return false
	if String(item.id) == "seven26c_gate_east_transfer_front": return await _capture("east_retired_front_wall_true_W_normal")
	return true

func finish() -> void:
	if done: return
	done = true
	if not pins.is_empty(): need(_facts() == first, "RESIDUAL_EXACT_SOURCE_FIRST_FINAL_IDENTICAL")
	if directory.is_empty(): directory = RESIDUAL + "actual/" + str(OS.get_process_id()); DirAccess.make_dir_recursive_absolute(directory)
	var result: Dictionary = {"passed": errors.is_empty(), "checks": checks, "errors": errors, "records": records, "input_events": input_events, "wall_input_ticks": wall_input_ticks, "samples": samples, "real_save_API_calls": 0, "save_file_content_reads": 0, "actor_camera_phase_writes": 0, "World_and_collector_rerun": false, "inherited102424_whole_FAIL_preserved": true, "runtime_and_old_manifests_written": false}
	var file := FileAccess.open(directory + "/result.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "  ") + "\n"); file.close()
	print("[Gait31c residual03] ", checks, " / ", errors.size(), " failures; ", directory)
	quit(0 if errors.is_empty() else 1)
