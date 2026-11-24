extends "res://tests/test_luoyang_culture_letter_field_draft_20261019x.gd"
## Reuse only public-arrival/native-input/source utilities, never x exercise/precheck.
## One Gate only; local NPCNode pairs are explicitly NOT other maps or patrol reruns.
const Y_READY := true
const Y_WHOLE_MS := 90000
const Y_SOURCE := "res://tests/fixtures/luoyang_military_static_gate_20261019y.json"
const Y_SOURCE_SHA := "ec298589f776945067ccc9f905abc3e6abb7162cf46506fcbde49cc843240ee7"
const Y_API := "res://scripts/city/luoyang_military_static_presentation_20261019y.gd"
const Y_CPU_RESULT := "res://build/luoyang_military_static_cpu_20261019y/95736/result.json"
const Y_CPU_SHA := "f4ffdfff2e26bec8b80367198b1b2394443d733301975bb929e2dbd9fbba0361"
const Y_GATE := "ch4_s0_luoyang_gate"
const Y_GEOMETRY := "res://tests/fixtures/luoyang_t_ordinary_world_gate_final_20261019u.json"
const Y_GEOMETRY_SHA := "b6aea50592ba2046f07846d666dfd3a7a8309764cf0b7047ae02faf08fdfc114"
const Y_NPC_SCENE := "res://scenes/npc_node.tscn"
const Y_FOUR := ["luoyang_gate_sergeant", "harbour_life_gate_check_assistant", "harbour_life_gate_patrol_west", "harbour_life_gate_patrol_east"]
var y_geometry: Dictionary = {}
var y_local: Array[WeakRef] = []

func _geometry(id: String) -> bool:
	if not check(id == Y_GATE, "Exactly the one requested Gate, never x Docks/Market suite"): return false
	var raw_script: Script = load(RAW_PATH)
	if not check(raw_script is GDScript and raw_script.can_instantiate(), "Independent existing raw-shape oracle compiles"): return false
	oracle = raw_script.new()
	mask = Image.load_from_file(y_geometry.mask_path)
	return check(expected_maps[id].has(y_geometry.mask_path) and mask != null and oracle.configure(y_geometry.floor_regions_px, y_geometry.solids, Vector2(3072, 2048), WORLD, y_geometry.foot_forbidden_regions_px), "Unchanged original independent Gate geometry/full875+17, no visual or native footprint shrink")

func _y_precheck() -> bool:
	if not check(Y_READY and DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and OS.get_cmdline_user_args().is_empty(), "Frozen single ordinary no-args Gate90/60; never controlled/candidate mode"): return false
	for pair: Array in [[Y_SOURCE, Y_SOURCE_SHA], [Y_CPU_RESULT, Y_CPU_SHA], [Y_GEOMETRY, Y_GEOMETRY_SHA]]:
		if not track(pair[0], pair[1]): return false
	var source := json(Y_SOURCE)
	var cpu := json(Y_CPU_RESULT)
	if not check(cpu.get("complete") == true and cpu.get("failures") == 0 and cpu.get("scope") == "CANDIDATE_FOUR_STATIC_FIVE_PERSON_ROW_PROJECTION_ONLY", "Actual finite pure-row CPU prerequisite only, no inherited x/u actual credit"): return false
	if not track(source.expected_source_path, source.expected_source_sha256) or not track(source.stage_receipt_path, source.stage_receipt_sha256): return false
	var independent := json(source.expected_source_path)
	var staged := json(source.stage_receipt_path)
	var fixed: Dictionary = independent.get("source_sha256", {})
	if not check(independent.get("status") == "INDEPENDENT_BASELINE_PLUS_FINITE_AUTHORED_DELTA" and fixed.size() == 733 and source.get("geometry_recomputed") == false and staged.get("geometry_artifact_sources_preserved") == true and staged.get("independent_expected_source_counts", {}).get(Y_GATE) == 733, "Root independent exact old map plus explicit static successor, not live-proof-derived expectation"): return false
	expected_maps[Y_GATE] = fixed.duplicate(true)
	for path: String in source.get("test_dependencies", {}):
		if not track(path, source.test_dependencies[path]): return false
	y_geometry = json(Y_GEOMETRY).gate_geometry
	api = load(Y_API); c = load(C_PATH)
	if not check(api is GDScript and api.can_instantiate() and c is GDScript and c.can_instantiate() and api.enabled(), "Actual enabled static API and city compile, no externally fabricated source result"): return false
	ready = api.readiness()
	return check(ready.get("ok") == true, "Actual source-bound four-static readiness", ready) and track(get_script().resource_path, FileAccess.get_sha256(get_script().resource_path))

func _y_body(npc: NPCNode) -> Dictionary:
	var body := npc.get("_body_collider") as StaticBody2D
	if body == null or body.get_child_count() != 1: return {}
	var shape := body.get_child(0) as CollisionShape2D
	if shape == null or not shape.shape is RectangleShape2D: return {}
	return {"size": (shape.shape as RectangleShape2D).size, "child_position": shape.position, "body_position": body.position, "body_layer": body.collision_layer, "disabled": shape.disabled, "calibrated": npc.get("_calibrate_adult_body"), "ground_anchored": npc.get("_ground_anchored"), "sprite_scale": npc.sprite_scale, "visible_scale": npc.sprite.scale, "visual_foot_offset": npc.call("_visual_foot_offset")}

func _y_gate_people() -> bool:
	var observed: Array = []
	for id: String in Y_FOUR:
		var npc := _person(id)
		if npc == null: return false
		var moving: bool = id in [Y_FOUR[2], Y_FOUR[3]]
		var path: String = api.GUARD_IDLE if moving else ready.data.styles["sergeant" if id == Y_FOUR[0] else "young_gate"].idle_path
		var body := _y_body(npc)
		if not check(npc.sprite_path == path and npc.walk_sprite_path == (api.GUARD_WALK if moving else "") and npc.movement_mode == ("patrol" if moving else "idle") and npc.get("_ground_anchored") == true and npc.get("_calibrate_adult_body") == true, "Actual intended two static and two unchanged real patrols, old branches/feet preserved " + id): return false
		if moving:
			if not check(npc.patrol_axis == Vector2.RIGHT and npc.patrol_speed == 26.0 and npc.walk_frame_seconds == 0.12 and npc.sprite.hframes == 8 and npc.get("_walk_texture") != null, "Existing actual original eight-frame patrol retained, not new rejected atlas " + id): return false
		else:
			if not check(npc.sprite.hframes == 1 and npc.sprite.vframes == 1 and npc.sprite.frame == 0 and npc.get("_walk_texture") == null, "Honest one-frame still, no fake idle/walk animation " + id): return false
		if not check(not body.is_empty() and body.body_layer == 1 and not body.disabled and body.child_position + body.body_position == Vector2.ZERO, "Actual active native body anchored at original feet " + id, body): return false
		observed.append({"id": id, "instance": npc.get_instance_id(), "sprite": npc.sprite_path, "walk": npc.walk_sprite_path, "position": npc.position, "patrol_origin": npc.get("_patrol_origin"), "distance": npc.patrol_distance, "body": body, "scope": "REAL_GATE_ACTOR"})
	records.append({"kind": "REAL_GATE_TWO_NEW_TWO_OLD", "actors": observed, "all_four_unique_new_identity_credit": false})
	return true

func _y_local_pairs() -> bool:
	var packed: PackedScene = load(Y_NPC_SCENE) as PackedScene
	if not check(packed != null, "Actual native NPCNode packed scene"): return false
	var local := Node2D.new(); local.name = "Y_Local_Not_Other_Map"; local.position = Vector2(-10000, -10000)
	root.add_child(local); y_local.append(weakref(local))
	for spec: Array in [["sergeant", 0.96, true], ["old_soldier", 0.94, true], ["commander", 0.82, false]]:
		var pair: Array[NPCNode] = []
		for newer: bool in [false, true]:
			var npc := packed.instantiate() as NPCNode
			if npc == null: return check(false, "Actual native NPCNode instance")
			npc.npc_id = "qa_y_local_" + spec[0] + ("_new" if newer else "_old")
			npc.sprite_path = ready.data.styles[spec[0]].idle_path if newer else (api.EXAMINER if spec[0] == "commander" else api.GUARD_IDLE)
			npc.sprite_scale = spec[1]; npc.movement_mode = "idle"
			npc.position = Vector2(100 if newer else 0, 0)
			local.add_child(npc); npc.set_ground_anchored(true); npc.set_process(false)
			pair.append(npc)
		await physics_frame
		var old_body := _y_body(pair[0]); var new_body := _y_body(pair[1])
		if not check(not old_body.is_empty() and not new_body.is_empty() and old_body.calibrated == spec[2] and new_body.calibrated == spec[2], "Preserved true/false original native calibration branch " + spec[0]): return false
		for key: String in ["size", "child_position", "body_position", "body_layer", "disabled", "calibrated", "ground_anchored", "sprite_scale"]:
			if not check(old_body[key] == new_body[key], "Old/new actual NPCNode exact original native body/foot property " + spec[0] + ":" + key, {"old": old_body[key], "new": new_body[key]}): return false
		for npc: NPCNode in pair:
			if not check(npc.sprite.position.y + float(npc.call("_visual_foot_offset")) == 0.0, "Actual ground anchor is exactly at instance feet " + npc.npc_id): return false
			var native := npc.get("_body_collider") as StaticBody2D
			var query := PhysicsPointQueryParameters2D.new()
			query.position = (native.get_child(0) as CollisionShape2D).global_position; query.collision_mask = 1; query.collide_with_areas = false
			var hits := npc.get_world_2d().direct_space_state.intersect_point(query, 8)
			var own_hit := false
			for hit: Dictionary in hits:
				if hit.get("collider") == native: own_hit = true
			native_queries += 1
			if not check(own_hit, "Local old/new actual native body registered in physics, not synthetic values " + npc.npc_id): return false
		records.append({"kind": "LOCAL_NATIVE_PAIR_NOT_OTHER_FIELD", "style": spec[0], "old_body": old_body, "new_body": new_body, "actual_other_scene_credit": false})
		for npc: NPCNode in pair: npc.queue_free()
		pair.clear(); await process_frame
	local.queue_free(); local = null
	await process_frame; await process_frame
	return check(y_local[0].get_ref() == null, "Own local native pair root released")

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began + Y_WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves()
	folder = "res://build/luoyang_military_static_gate_20261019y/%d" % OS.get_process_id(); DirAccess.make_dir_recursive_absolute(folder)
	var complete := _y_precheck()
	if complete:
		gs = root.get_node("GameState"); qm = root.get_node("QuestManager")
		original_parts = {"flags": gs.get("flags").duplicate(true), "quests": qm.call("to_dict").duplicate(true)}; original_rewards = _rewards()
		driver = (load(INPUT_PATH) as Script).new(); driver.configure(self)
		complete = await _arrive(Y_GATE, Vector2(1536, 1860))
		if complete: complete = await _move(Vector2(1536, 1860), Vector2(1568, 1860))
		if complete: complete = _y_gate_people()
		if complete: complete = await _y_local_pairs()
		if complete: complete = await _picture("gate_two_static_two_original_patrols")
	if driver != null: driver.release(); driver = null
	for ref: WeakRef in y_local:
		var local: Node = ref.get_ref() as Node
		if local != null: local.queue_free()
	if is_instance_valid(current_scene):
		var own: Node = current_scene; var weak: WeakRef = weakref(own)
		current_scene = null; own.queue_free(); field = null; scene = null; own = null
		await process_frame; await process_frame
		check(weak.get_ref() == null, "Own single actual Gate naturally released")
	root.get_node("SceneRouter").call("reset_for_new_game")
	await process_frame; await process_frame
	for ref: WeakRef in y_local: check(ref.get_ref() == null, "Every own local pair root released even on early failure")
	if not original_parts.is_empty():
		gs.set("flags", original_parts.flags.duplicate(true)); qm.call("from_dict", original_parts.quests.duplicate(true))
		check(gs.get("flags") == original_parts.flags and qm.call("to_dict") == original_parts.quests and _rewards() == original_rewards, "Original in-memory flags/quests restored after normal Field visit; no quest or reward credit")
	oracle = null; mask = null
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after := saves()
	check(source_before == source_after and players_before == players_after and players_before.size() == 15, "Complete runtime/QA source set and fifteen existing/absent saves unchanged")
	check(Time.get_ticks_msec() < deadline, "Single Gate90/60 fixed atom, no new loading promise")
	var report := {"scope": "ONE_DEFAULT_GATE_TWO_NEW_STILLS_TWO_OLD_PATROLS_PLUS_LOCAL_NATIVE_PAIRS", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "budget_ms": Y_WHOLE_MS, "arrival_ms": ARRIVAL_MS, "native_queries": native_queries, "records": records, "pictures": pictures, "source_before": source_before, "source_after": source_after, "players_before": players_before, "players_after": players_after, "old_x_u_suite_rerun": false, "other_Field_or_new_walk_credit": false}
	var file := FileAccess.open(folder.path_join("result.json"), FileAccess.WRITE)
	if file == null: failures += 1
	else: file.store_string(JSON.stringify(report, "\t", true, true)); file.close()
	print(JSON.stringify({"report_path": folder.path_join("result.json"), "checks": checks, "failures": failures, "complete": complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)


