extends "res://tests/test_luoyang_culture_source_admission_draft_20261019x.gd"
## NEW two-public-setups representative only. No world route, old CPU suite or room replay.
const FIELD_READY := true
const WHOLE_MS := 180000
const ARRIVAL_MS := 60000
const CONTROL_RESULT := "res://build/luoyang_culture_dialog_save_20261019x/109256/result.json"
const CONTROL_RESULT_SHA := "fcb56486e7bd966dff71fed55b032c8236308ffb9b3ff77277841fd13a722111"
const ADMISSION_RESULT := "res://build/luoyang_culture_source_admission_20261019x/115872/result.json"
const ADMISSION_RESULT_SHA := "fbb3c4754ed8d897fa1edcdf4c8779f7173aad6b39c057179ca1a50e3ab031d4"
const ADMISSION_CONSOLE := "res://build/luoyang_culture_integration_20261019x_root01/admission_console.log"
const ADMISSION_CONSOLE_SHA := "1954c5ff22a4786e5f9b0ec5b45a2466bd2c0c28a988df5bc6c412f37fe1dd7d"
const X_PATH := "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd"
const RAW_PATH := "res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd"
const INPUT_PATH := "res://tests/helpers/v15_input_driver.gd"
const MARKET_GEOMETRY := "res://tests/fixtures/luoyang_t_market_herbal_actual_retry2_20261019u.json"
const DOCKS := "ch4_s2_canal_docks"
const MARKET := "ch4_s3_luoyang_market"
const LETTER := "q_ch4_side_10_luoshui_letter"
const CLERK := "harbour_life_docks_booking_attendant"
const BUYER := "district_life_market_buyer"
const WORLD := Vector2(3072, 2048)
var expected_maps: Dictionary = {}
var api: Script
var ready: Dictionary = {}
var field: Node
var scene: SceneScript
var driver: RefCounted
var oracle: RefCounted
var mask: Image
var dp: Node
var gs: Node
var qm: Node
var deadline := 0
var native_queries := 0
var pictures: Array = []
var folder := ""
var seeded_parts: Dictionary = {}
var original_parts: Dictionary = {}
var original_rewards: Dictionary = {}
var prior_fields: Array[WeakRef] = []

func _v(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(value[0], value[1])

func _precheck_field() -> bool:
	if not check(FIELD_READY and DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and OS.get_cmdline_user_args().is_empty(), "Frozen default no-args actual GUI representative, not controlled owner or candidate flag"): return false
	if not track(CONTROL_RESULT, CONTROL_RESULT_SHA) or not track(ADMISSION_RESULT, ADMISSION_RESULT_SHA) or not track(ADMISSION_CONSOLE, ADMISSION_CONSOLE_SHA): return false
	var controlled := json(CONTROL_RESULT)
	var admitted := json(ADMISSION_RESULT)
	if not check(controlled.get("complete") == true and controlled.get("failures") == 0 and not controlled.get("letter_setup_parts", {}).is_empty(), "Independent actual controlled DP/QM prerequisites, never the prior SCRIPT-failed result"): return false
	if not check(admitted.get("scope") == "METADATA_ONLY_EXACT_SOURCE_SUCCESSOR_NOT_GEOMETRY_OR_FIELD" and admitted.get("complete") == false and admitted.get("checks") == 9102 and admitted.get("failures") == 1 and admitted.get("budget_ms") == 60000 and admitted.get("elapsed_ms") > 60000, "Original metadata whole result remains FAIL/over its original fixed sixty-second budget; never relabelled a PASS"): return false
	var budget_failures: Array[String] = []
	for line: String in FileAccess.get_file_as_string(ADMISSION_CONSOLE).split("\n"):
		if line.begins_with("CULTURE_X_ADMISSION_FAIL"): budget_failures.append(line.strip_edges())
		if not check(not line.contains("SCRIPT ERROR") and not line.begins_with("ERROR:"), "Original metadata console contains no runtime SCRIPT/ERROR"): return false
	if not check(budget_failures == ["CULTURE_X_ADMISSION_FAIL Fixed sixty-second metadata-only atom, no geometry or old task replay <null>"], "Exact sole metadata failure is its retained timing-budget assertion, not a source-admission failure"): return false
	if not check(admitted.get("source_before", {}).size() == 2473 and admitted.source_before == admitted.get("source_after") and admitted.get("players_before", {}).size() == 15 and admitted.players_before == admitted.get("players_after"), "Only completed source components: all2473 first/final facts and fifteen save facts remain exactly equal"): return false
	seeded_parts = controlled.letter_setup_parts.duplicate(true)
	var expected_counts := {"ch4_s0_luoyang_gate": 709, "ch4_s1_luoyang_yamen": 1034, DOCKS: 1447, MARKET: 1240}
	var seen: Dictionary = {}
	if not check(admitted.get("records", []).size() == 4, "All four completed metadata collector components exist, not a partial subset"): return false
	for row: Dictionary in admitted.records:
		var id: String = row.get("id", "")
		if not check(expected_counts.has(id) and not seen.has(id) and row.get("kind") == "METADATA_ONLY_FULL_COLLECTOR" and row.get("whole_semantic_inverse") == true and row.get("geometry_or_Field_credit") == false and row.get("source_count") == expected_counts[id] and row.get("actual_source_sha256", {}).size() == expected_counts[id], "Each whole source-only collector completed with its exact independent count " + id): return false
		seen[id] = true
		if id in [DOCKS, MARKET]: expected_maps[id] = row.actual_source_sha256.duplicate(true)
	records.append({"kind": "METADATA_COMPONENTS_ONLY_ORIGINAL_OVERBUDGET_FAIL_RETAINED", "original_report": ADMISSION_RESULT, "original_complete": false, "original_failures": 1, "original_budget_ms": 60000, "original_elapsed_ms": admitted.elapsed_ms, "source_component_counts": expected_counts, "grants_whole_metadata_budget_PASS": false, "actual_two_Field_current_SHA_recheck_still_required": true})
	if not check(expected_maps.size() == 2, "Both complete independently admitted source maps, never derived from live Field proof"): return false
	var fixed := {RAW_PATH: "0f00d4a8a7bc7f514d4b0859275c2eb6d03296dd81eaa170416694c6068b2835", INPUT_PATH: "a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7", MARKET_GEOMETRY: "55a315e0d2c10e9c3d8b4caea7266c1be2b4c1ee813ee50afa1f6eccf92cdeb3"}
	for path: String in fixed:
		if not track(path, fixed[path]): return false
	for path: String in [get_script().resource_path, "res://tests/test_luoyang_culture_source_admission_draft_20261019x.gd"]:
		if not track(path, FileAccess.get_sha256(path)): return false
	api = load(X_PATH); c = load(C_PATH)
	if not check(api is GDScript and api.can_instantiate() and c is GDScript and c.can_instantiate() and api.enabled(), "Actual coordinator and city API compile/default-enabled without a flag"): return false
	ready = api.readiness()
	return check(ready.get("ok") == true, "Default actual coordinator source readiness", ready)

func _rewards() -> Dictionary:
	return {"gold": gs.get("gold"), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true), "training_total": gs.get("training_points_total"), "training_available": gs.get("training_points_available"), "reputation": gs.get("reputation")}

func _state() -> Dictionary:
	var result: Dictionary = api.read_state(LETTER, gs.get("flags"), qm.get("states"))
	check(result.get("ok") == true, "Actual GS/QM letter phase agrees", result)
	return result.get("state", {})

func _native(foot: Vector2) -> bool:
	var player := field.get("_player") as CharacterBody2D
	var shape := player.get_node("CollisionShape2D") as CollisionShape2D
	if shape.position != Vector2.ZERO or not shape.shape is RectangleShape2D or (shape.shape as RectangleShape2D).size != Vector2(34, 24): return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape; query.transform = shape.global_transform
	query.transform.origin += (field.get("world_container") as Node2D).to_global(foot) - player.global_position
	query.exclude = [player.get_rid()]; query.collision_mask = 1; query.collide_with_areas = false
	native_queries += 1
	return player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _mask_clear(foot: Vector2) -> bool:
	if mask == null: return false
	var rounded := foot.round()
	for y: int in range(-12, 13):
		for x: int in range(-17, 18):
			var p := Vector2i(rounded + Vector2(x, y))
			if p.x < 0 or p.y < 0 or p.x >= 3072 or p.y >= 2048: return false
			var color := mask.get_pixelv(p)
			if color.r < .5 or color.a < .5: return false
	return true

func _clear(foot: Vector2) -> bool:
	return Time.get_ticks_msec() < deadline and is_instance_valid(field) and current_scene == field and oracle != null and oracle.clear(foot) and _mask_clear(foot) and _native(foot)

func _segment(a: Vector2, z: Vector2) -> Dictionary:
	var count := maxi(1, ceili(a.distance_to(z) / 4.0))
	for i: int in range(count + 1):
		var point := a.lerp(z, float(i) / count)
		if Time.get_ticks_msec() >= deadline or not oracle.clear(point) or not _mask_clear(point): return {"clear": false, "sample": i, "foot": point, "raw": oracle.last}
	return {"clear": true, "samples": count + 1, "continuous34x24": true, "full87517": true, "step_le4": true}

func _geometry(id: String) -> bool:
	var fixed: Dictionary = expected_maps[id]
	var raw_script: Script = load(RAW_PATH)
	oracle = raw_script.new()
	if id == MARKET:
		var geometry: Dictionary = json(MARKET_GEOMETRY).geometry[MARKET]
		if not check(oracle.configure(geometry.floor_regions_px, geometry.solids, _v(geometry.source_size_px), _v(geometry.world_size_px), geometry.foot_forbidden_regions_px), "Unchanged independent published Market raw geometry, not live C geometry"): return false
		if not check(fixed.has(geometry.mask_path), "Market independent saved mask belongs to complete admitted sources"): return false
		mask = Image.load_from_file(geometry.mask_path)
	else:
		var spacing: Script = load("res://scripts/city/luoyang_building_spacing_20261017p.gd")
		var bind := json(spacing.BIND_PATH)
		var publication := json(bind.manifest_path)
		var author := json("res://data/maps/luoyang_district_life_20261016f/author.json")
		for path: String in [spacing.SELF, spacing.BIND_PATH, bind.manifest_path, bind.walk_path, "res://data/maps/luoyang_district_life_20261016f/author.json"]:
			if not check(fixed.has(path), "Every independent Docks source explicitly admitted " + path): return false
		var solids: Array = []
		for object: Dictionary in publication.record.objects:
			var index := 0
			for poly: Array in object.get("solid_polygons_px", []):
				solids.append({"id": String(object.id) + "_poly_" + str(index), "points_px": poly}); index += 1
			var extent := _v(object.collision_size_px)
			if extent.x > 0 and extent.y > 0:
				var center := _v(object.physical_center_px); var low := center - extent * .5; var high := center + extent * .5
				solids.append({"id": String(object.id) + "_box", "points_px": [low, Vector2(high.x, low.y), high, Vector2(low.x, high.y)]})
		for placement: Dictionary in author.districts[DOCKS].placements:
			var asset: Dictionary = author.assets[placement.asset_id]
			var index := 0
			for poly: Array in asset.ground_solid_polygons_px:
				var points: Array = []
				for point: Array in poly: points.append(_v(placement.foot_px) + (_v(point) - _v(asset.source_ground_anchor_px)) * float(placement.scale))
				solids.append({"id": String(placement.id) + "_delta_" + str(index), "points_px": points}); index += 1
		if not check(oracle.configure([[[0,0],[3072,0],[3072,2048],[0,2048]]], solids, WORLD, WORLD), "Unchanged independently published Docks parent plus every current District base"): return false
		mask = Image.load_from_file(bind.walk_path)
	return check(mask != null and mask.get_size() == Vector2i(WORLD) and _clear(field.get("_player").position), "Actual spawn full87517/continuous34x24/nativePhysics and independent saved mask")

func _arrive(id: String, foot: Vector2) -> bool:
	var start := Time.get_ticks_usec()
	if is_instance_valid(field): prior_fields.append(weakref(field))
	if not check(root.get_node("SceneRouter").call("go_field_smart", StringName(id), foot / WORLD, "", -1, 3), "One public version3 near-actor setup, explicitly not portal/world travel " + id): return false
	var until := mini(deadline, Time.get_ticks_msec() + ARRIVAL_MS)
	while Time.get_ticks_msec() < until:
		await process_frame
		var request: Dictionary = root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if request.get("scene_id") == id and request.get("phase") == "FAILED": return check(false, "Actual request failed instead of silently returning world", request)
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): continue
		var state: Dictionary = current_scene.call("get_field_loading_state")
		if state.get("failed", false): return check(false, "Actual Field failed", state)
		var candidate := current_scene.get("_current_scene") as SceneScript
		var player := current_scene.get("_player") as CharacterBody2D
		if candidate == null or String(candidate.scene_id) != id or player == null or not bool(player.get("can_move")) or state.get("complete") != true: continue
		var screen: Node = root.get_node("LoadingManager").get("_screen")
		var panel := screen.get("root") as Control if is_instance_valid(screen) else null
		if panel != null and panel.is_visible_in_tree(): continue
		await RenderingServer.frame_post_draw
		field = current_scene; scene = candidate
		var elapsed := Time.get_ticks_usec() - start
		var proof: Dictionary = c.resident_receipt(scene)
		if not check(proof.get("sources_finalized") == true and proof.get("sources", {}) == expected_maps[id], "Whole actual same-owner finalized source map exactly equals independently admitted set " + id, {"actual_count": proof.get("sources", {}).size(), "expected_count": expected_maps[id].size()}): return false
		records.append({"kind": "DEFAULT_FIELD_FIRSTDRAW_OPERABLE", "id": id, "elapsed_usec": elapsed, "performance_promise": false, "public_setup_not_travel": true, "source_proof": proof.duplicate(true)})
		for path: String in expected_maps[id]:
			if not track(path, expected_maps[id][path]): return false
		return check(field.get_script().resource_path == FIELD and scene.actor_positions_are_feet and field.get("_world_size") == WORLD and field.get("_player").position.distance_to(foot) < .03, "Actual unmodified Field/current Scene/native feet and legal public spawn") and _geometry(id)
	return check(false, "Actual hidden Loading/operable/drawn within fixed sixty-second arrival limit " + id)

func _visible_actors(id: String) -> Array[NPCNode]:
	var result: Array[NPCNode] = []
	for node: Node in root.find_children("*", "", true, false):
		if node is NPCNode and node.npc_id == id and node.is_inside_tree() and node.is_visible_in_tree(): result.append(node as NPCNode)
	return result

func _person(id: String) -> NPCNode:
	var found := _visible_actors(id)
	if not check(found.size() == 1 and found[0].get_parent() == field.get("_actor_layer"), "One real current visible actor, never two district duplicates " + id, found.size()): return null
	var npc: NPCNode = found[0]
	var body := npc.get("_body_collider") as StaticBody2D
	if not check(body != null and body.is_inside_tree() and body.collision_layer == 1 and body.get_child_count() == 1, "Real current native actor body " + id): return null
	var shape := body.get_child(0) as CollisionShape2D
	if not check(shape != null and not shape.disabled and shape.shape is RectangleShape2D and npc.sprite != null and npc.sprite.texture != null, "Real visible textured actor and active native rectangle " + id): return null
	return npc

func _move(from: Vector2, to: Vector2) -> bool:
	var result: Dictionary = await driver.follow(field, PackedVector2Array([from, to]), _clear, _segment)
	records.append({"kind": "NORMAL_INPUT", "scene_id": String(scene.scene_id), "result": result})
	return check(result.get("ok") == true, "Actual normal short INPUT, independent full87517 plus native Physics", result)

func _choose(label: String) -> bool:
	var node := dp.get("_current_node") as DialogNode
	if not check(dp.call("is_playing") and node != null and node.has_choices(), "Real DP choice node " + label): return false
	var indices: Array[int] = []
	for i: int in node.choices.size():
		if node.choices[i].text == label: indices.append(i)
	if not check(indices.size() == 1, "One exact visible choice " + label, node.choices): return false
	dp.call("choose", indices[0])
	return true

func _drain() -> bool:
	for i: int in 16:
		if not dp.call("is_playing"):
			var until := mini(deadline, Time.get_ticks_msec() + 10000)
			while Time.get_ticks_msec() < until:
				await driver.completed_actor_stage()
				if not field.get("_scene_rebuilding") and field.get("_player").can_move: return true
			return check(false, "Actual deferred dynamic refresh settled without forced refresh within ten seconds")
		var node := dp.get("_current_node") as DialogNode
		if not check(node != null and not node.has_choices() and Time.get_ticks_msec() < deadline, "Normal bounded advance never chooses a menu implicitly"): return false
		dp.call("advance")
		await process_frame
	return check(false, "Dialogue including real Field feedback failed to end")

func _space_topic(npc_id: String) -> bool:
	await driver.completed_actor_stage()
	if not check(not dp.call("is_playing") and _clear(field.get("_player").position), "Actual safe close player outside dialogue before Space"): return false
	await driver.key(KEY_SPACE)
	var debug: Dictionary = field.call("get_culture_integration_state")
	var npc := _person(npc_id)
	if not check(npc != null and debug.get("session_active") == true and debug.get("session", {}).get("npc_instance") == npc.get_instance_id(), "Normal Space selected the original actual intended NPC/session", debug): return false
	return _choose(ready.text.common.culture_topics) and _choose(ready.text_by_id[LETTER].topic_label)

func _picture(name: String) -> bool:
	await RenderingServer.frame_post_draw
	var path := folder.path_join(name + ".png")
	var image := root.get_texture().get_image()
	if not check(image != null and image.save_png(path) == OK, "One unmodified ordinary-camera actual handoff picture"): return false
	pictures.append({"path": path, "sha256": FileAccess.get_sha256(path), "qa_camera_modified": false})
	return true

func _handoff() -> bool:
	if not await _arrive(DOCKS, Vector2(1950, 1990)) or not await _move(Vector2(1950, 1990), Vector2(1950, 1940)): return false
	var clerk := _person(CLERK); var buyer := _person(BUYER)
	if clerk == null or buyer == null: return false
	var clerk_id := clerk.get_instance_id()
	if not check(clerk.position == Vector2(2010, 1900) and buyer.position == Vector2(1890, 1900) and buyer.npc_name == "采买妇人" and buyer.sprite_path == ready.contract.pickup.sprite_path and buyer.portrait_path == ready.contract.pickup.portrait_path and buyer.get_meta("culture_x_actual_recipient", false) == true and _state().status == "solved", "Actual original clerk and same-identity recipient at measured separate native stations, not caller boolean"): return false
	if not await _space_topic(CLERK) or not _choose("请按原约由本人亲领"): return false
	var letter := clerk.get_node_or_null("CultureSealedLetter") as Sprite2D
	if not check(letter != null and letter.is_visible_in_tree() and letter.texture.resource_path == ready.contract.pickup.letter_texture and letter.get_parent() == clerk and _state().status != "collected", "Actual visible sealed-letter Node starts under original clerk; no premature progress"): return false
	var cancelled_letter: WeakRef = weakref(letter)
	# A real player can dismiss this terminal before the .45s animation finishes.
	# Exercise that normal DP path once, never a test-call bool/abort hook.
	if not await _drain(): return false
	if not check(_state().status == "solved" and qm.call("get_status", StringName(LETTER)) == 1 and cancelled_letter.get_ref() == null and field.call("get_culture_integration_state").get("last_receipt", {}).get("committed") == false, "Early normal dialogue dismissal cancels visible in-flight transfer without progress/reward or a stranded letter"): return false
	var stale_until := mini(deadline, Time.get_ticks_msec() + 550)
	while Time.get_ticks_msec() < stale_until: await process_frame
	if not check(_state().status == "solved" and _visible_actors(BUYER).size() == 1, "Cancelled tween cannot later collect or duplicate the real recipient"): return false
	if not await _space_topic(CLERK) or not _choose("请按原约由本人亲领"): return false
	letter = clerk.get_node_or_null("CultureSealedLetter") as Sprite2D
	if not check(letter != null and letter.is_visible_in_tree() and letter.get_parent() == clerk, "Replacement real session owns a fresh visible letter after cancellation"): return false
	var letter_id := letter.get_instance_id()
	var until := mini(deadline, Time.get_ticks_msec() + 2000)
	while Time.get_ticks_msec() < until and field.call("get_culture_integration_state").get("session", {}).get("handoff_ready") != true: await process_frame
	if not check(is_instance_valid(letter) and letter.get_instance_id() == letter_id and letter.get_parent() == buyer and letter.is_visible_in_tree() and buyer.get_meta("culture_x_letter_holder", 0) == letter_id and _state().status == "solved", "Same real sealed-letter Node naturally reparented to same recipient before committing, not generated event bool"): return false
	if not await _picture("docks_actual_personal_handoff"): return false
	if not await _drain(): return false
	var result: Dictionary = field.call("get_culture_integration_state")
	var receipt: Dictionary = result.get("last_receipt", {})
	if not check(_state().status == "collected" and qm.call("get_status", StringName(LETTER)) == 1 and receipt.get("event") == "pickup" and receipt.get("accepted") == true and receipt.get("actual_handoff") == true and receipt.get("sealed_letter_node") == letter_id and receipt.get("normal_dialog_end") == true and receipt.get("npc_instance") == clerk_id, "Only normal actual handoff end commits collected, with same letter/holder/original clerk receipt", result): return false
	await driver.completed_actor_stage()
	if not check(_visible_actors(BUYER).is_empty(), "Recipient departs Docks after confirmed feedback; no duplicate resident left behind"): return false
	records.append({"kind": "REAL_PERSONAL_HANDOFF", "letter_node_id": letter_id, "receipt": receipt.duplicate(true), "actual_world_presence_verified": true, "pure_bool_api_used": false})
	return true

func _report_market() -> bool:
	if not await _arrive(MARKET, Vector2(2820, 1980)) or not await _move(Vector2(2820, 1980), Vector2(2820, 1960)): return false
	var buyer := _person(BUYER)
	if buyer == null or not check(buyer.npc_name == "采买妇人" and buyer.portrait_path == ready.contract.pickup.portrait_path and buyer.get_parent() == field.get("_actor_layer"), "Same recipient identity restored uniquely in Market"): return false
	if not await _space_topic(BUYER) or not _choose(ready.text_by_id[LETTER].report_choice) or not await _drain(): return false
	var debug: Dictionary = field.call("get_culture_integration_state")
	if not check(_state().status == "reported" and _state().report_count == 1 and qm.call("get_status", StringName(LETTER)) == 2 and debug.get("last_receipt", {}).get("event") == "report" and debug.get("last_receipt", {}).get("accepted") == true, "Real Market explicit report completes QM once after prior actual personal pickup", debug): return false
	if not await _space_topic(BUYER): return false
	var node := dp.get("_current_node") as DialogNode
	for choice: Dictionary in node.choices:
		if not check(choice.text != ready.text_by_id[LETTER].report_choice, "Repeat report action absent after actual completion"): return false
	if not await _drain(): return false
	return check(_state().report_count == 1 and _rewards() == original_rewards, "No duplicate completion or numeric/inventory/training/reputation reward")

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began + WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves()
	folder = "res://build/luoyang_culture_letter_field_20261019x/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var complete := _precheck_field()
	if complete:
		dp = root.get_node("DialogPlayer"); gs = root.get_node("GameState"); qm = root.get_node("QuestManager")
		original_parts = {"flags": gs.get("flags").duplicate(true), "quests": qm.call("to_dict").duplicate(true)}
		original_rewards = _rewards()
		gs.set("flags", seeded_parts.flags.duplicate(true)); qm.call("from_dict", seeded_parts.quests.duplicate(true))
		complete = check(_state().status == "solved", "Controlled real-DP-earned prerequisites only, not credit for earlier city traversal")
		driver = (load(INPUT_PATH) as Script).new(); driver.configure(self)
		if complete: complete = await _handoff()
		if complete: complete = await _report_market()
	if driver != null: driver.release(); driver = null
	if is_instance_valid(current_scene):
		var own := current_scene; var weak: WeakRef = weakref(own)
		current_scene = null; own.queue_free(); field = null; scene = null; own = null
		await process_frame; await process_frame
		check(weak.get_ref() == null, "Own final actual Field exited naturally")
	if dp != null and dp.call("is_playing"): dp.call("_end_dialog") # Field._exit_tree already aborted its own session.
	for prior: WeakRef in prior_fields: check(prior.get_ref() == null, "Prior Docks Field naturally released after the one Market switch; no hidden duplicate owner")
	if not original_parts.is_empty():
		gs.set("flags", original_parts.flags.duplicate(true)); qm.call("from_dict", original_parts.quests.duplicate(true))
		check(gs.get("flags") == original_parts.flags and qm.call("to_dict") == original_parts.quests, "Actual original GS/QM parts restored exactly after own Fields exit, without save writes")
		check(_rewards() == original_rewards, "Approved zero-reward channels unchanged through actual Field sequence")
	oracle = null; mask = null
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after := saves()
	check(source_before == source_after, "All complete admitted runtime sources and independent test sources unchanged")
	check(players_before == players_after and players_before.size() == 15, "All fifteen existing/absent save facts unchanged, no slot writes")
	check(Time.get_ticks_msec() < deadline, "Explicit bounded two-Field representative; no general loading performance promise")
	var path := folder.path_join("result.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope": "DEFAULT_TWO_FIELD_NATIVE_PERSONAL_HANDOFF_AND_MARKET_REPORT_ONLY", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "budget_ms": WHOLE_MS, "arrival_ms": ARRIVAL_MS, "native_queries": native_queries, "records": records, "pictures": pictures, "players_before": players_before, "players_after": players_after, "source_before": source_before, "source_after": source_after, "old_world_route_or_city_room_suite_retested": false}, "\t")); file.close()
	print(JSON.stringify({"report_path": path, "checks": checks, "failures": failures, "complete": complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
