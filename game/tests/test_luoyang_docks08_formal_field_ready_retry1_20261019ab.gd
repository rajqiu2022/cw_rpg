extends "res://tests/test_luoyang_culture_letter_field_draft_20261019x.gd"
## Single ordinary Docks default birth. Parent supplies utilities, never its x exercise/run.
const AB_FIELD_READY := true
const AB_FIELD_BIND := "res://tests/fixtures/luoyang_docks08_formal_field_retry1_20261019ab.json"
const AB_FIELD_BIND_SHA := "62b4015f9c147275e35089c72b01fb527a094c4cb5aac764c60aae6454e6e5c7"
const AB_FIELD_WHOLE_MS := 90000
const AB_FIELD_ARRIVAL_MS := 60000
const AB_AA_PATH := "res://scripts/city/luoyang_docks_district08_20261019aa.gd"
const AB_PACKET_PATH := "res://data/maps/luoyang_docks_district08_20261019aa/runtime/ch4_s2_canal_docks/packet.bin"
const AB_DISTRICT_AUTHOR := "res://data/maps/luoyang_district_life_20261016f/author.json"
const AB_OFFICE_PATH := "res://scripts/city/luoyang_docks_office_roles_20261016h.gd"
const AB_CROWD_PATH := "res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd"
const AB_TASKS_PATH := "res://scripts/city/luoyang_city_tasks_20261016.gd"
const AB_DEFAULT_FOOT := Vector2(2140, 1840)
var ab_binding: Dictionary = {}
var ab_packet: Dictionary = {}
var ab_record: Dictionary = {}
var ab_aa: Script

func check(value: bool, label: String, detail: Variant = null) -> bool:
	checks += 1
	if not value:
		failures += 1
		printerr("DOCKS_AB_FIELD_FAIL ", label, " ", detail)
	return value

func ab_preflight() -> bool:
	if not check(AB_FIELD_READY and DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and OS.get_cmdline_user_args().is_empty(), "Frozen ordinary no-args actual GUI, not AA flag/near-actor/controlled fixture"): return false
	if not track(AB_FIELD_BIND, AB_FIELD_BIND_SHA): return false
	ab_binding = json(AB_FIELD_BIND)
	if not check(ab_binding.get("phase") == "AA_FORMAL_TRUE_INDEX" and ab_binding.get("expected_from_actual_collector") == false, "Independent x old-map plus finite authored ab delta, never actual proof backfill"): return false
	for path: String in ab_binding.test_dependencies:
		if not track(path, ab_binding.test_dependencies[path]): return false
	for path: String in ab_binding.fixed_current_sources:
		if not track(path, ab_binding.fixed_current_sources[path]): return false
	for name: String in ["fallback", "admission"]:
		var row: Dictionary = ab_binding.prerequisite_reports[name]
		if not track(row.path, row.sha256): return false
		var report := json(row.path)
		if not check(report.get("complete") == true and report.get("failures") == 0 and report.get("scope") == row.scope and report.get("source_before") == report.get("source_after") and report.get("players_before", {}).size() == 15 and report.players_before == report.players_after, "Actual isolated completed prerequisite component, not failed/partial prior result " + name): return false
	var inherited: Dictionary = ab_binding.fallback_finite_source_successor
	for key: String in ["old_map", "new_false_map"]:
		if not track(inherited[key].path, inherited[key].sha256): return false
	var old_fallback: Dictionary = json(inherited.old_map.path).source_sha256.duplicate(true)
	var new_fallback: Dictionary = json(inherited.new_false_map.path).source_sha256.duplicate(true)
	if not check(old_fallback.size() == 1456 and new_fallback.size() == 1458 and inherited.delta.size() == 5, "Original1456 actually tested disabled fallback inherits only explicit three authority updates/two declared asset-import leaves"): return false
	var allowed_delta: Array[String] = ["res://scripts/city/luoyang_docks_district08_index_20261019aa.gd", INDEX, ROOT_MAP + DOCKS + "/manifest.json", "res://build/luoyang_docks_spacing_ordinary_20261018q/105980_2617/ordinary_docks_spacing_32px.png.import", "res://.godot/imported/ordinary_docks_spacing_32px.png-4ea5aa226b5a0e3027a9d1f59051966b.ctex"]
	for path: String in allowed_delta:
		if not check(inherited.delta.has(path) and old_fallback.get(path, "ABSENT") == inherited.delta[path].old_sha256 and new_fallback.get(path) == inherited.delta[path].new_sha256 and String(inherited.delta[path].new_sha256).length() == 64, "Explicit independent source-import closure successor only " + path): return false
		old_fallback[path] = inherited.delta[path].new_sha256
	if not check(old_fallback == new_fallback, "Whole exact finite fallback-source inverse; no repeated fallback suite or active-AA credit from original component"): return false
	if not track(ab_binding.expected_map_path, ab_binding.expected_map_sha256): return false
	expected_maps[DOCKS] = json(ab_binding.expected_map_path).get("source_sha256", {}).duplicate(true)
	if not check(expected_maps[DOCKS].size() == 1466, "Full independently import-closed formal true Docks source count, not disabled fallback1458"): return false
	b = load(B_PATH); c = load(C_PATH); ab_aa = load(AB_AA_PATH)
	if not check(b is GDScript and b.can_instantiate() and c is GDScript and c.can_instantiate() and ab_aa is GDScript and ab_aa.can_instantiate() and ab_aa.enabled() and b.requested(StringName(DOCKS)), "Default canonical APIs compile and AA formal sole true switch is active"): return false
	ab_packet = bytes_to_var(FileAccess.get_file_as_bytes(AB_PACKET_PATH))
	if not check(b.aa_packet_valid(ab_packet), "Exact immutable69DA native packet and whole typed inverse already admitted; no geometry replay"): return false
	var default_record: Dictionary = json(ab_binding.default_spawn_authority.publication_path).record
	if not check(_v(default_record.entry_foot_px) == AB_DEFAULT_FOOT and _v(ab_packet.record.entry_foot_px) == AB_DEFAULT_FOOT, "Published independent parent entry, not old canonical input or actual-run backfill, remains exact through AA inverse"): return false
	var self_path: String = get_script().resource_path
	return track(self_path, FileAccess.get_sha256(self_path))

func _geometry(id: String) -> bool:
	if not check(id == DOCKS, "This atom has only one Docks geometry oracle"): return false
	ab_record = c._records.get(DOCKS, {}).duplicate(true)
	if not check(ab_aa.bound(scene) and b.whole_bound(scene) and b.equal(ab_record, ab_packet.record) and ab_record.objects.size() == 25, "Actual AA native Scene/weak owner and all25 complete prepared record values equal exact packet"): return false
	mask = Image.load_from_file(String(ab_record.walk_path))
	var actual_mask: Image = c._masks.get(DOCKS)
	if not check(mask != null and actual_mask != null and mask.get_size() == Vector2i(WORLD) and mask.get_data() == ab_packet.walk_bytes and actual_mask.get_data() == ab_packet.walk_bytes and c._equal_value(c._solids.get(DOCKS), c.object_solids(ab_record.objects)), "Actual committed full RGBA mask and all25 base solids exactly match immutable new geometry"): return false
	var solids: Array = []
	for object: Dictionary in ab_packet.record.objects:
		var index := 0
		for poly: Array in object.get("solid_polygons_px", []):
			solids.append({"id": String(object.id) + "_poly_" + str(index), "points_px": poly}); index += 1
		var extent := _v(object.collision_size_px)
		if extent.x > 0 and extent.y > 0:
			var center := _v(object.physical_center_px); var low := center - extent * .5; var high := center + extent * .5
			solids.append({"id": String(object.id) + "_box", "points_px": [low, Vector2(high.x, low.y), high, Vector2(low.x, high.y)]})
	var author := json(AB_DISTRICT_AUTHOR)
	for placement: Dictionary in author.districts[DOCKS].placements:
		var asset: Dictionary = author.assets[placement.asset_id]
		var index := 0
		for poly: Array in asset.ground_solid_polygons_px:
			var points: Array = []
			for point: Array in poly: points.append(_v(placement.foot_px) + (_v(point) - _v(asset.source_ground_anchor_px)) * float(placement.scale))
			solids.append({"id": String(placement.id) + "_delta_" + str(index), "points_px": points}); index += 1
	oracle = (load(RAW_PATH) as Script).new()
	if not check(oracle.configure([[[0,0],[3072,0],[3072,2048],[0,2048]]], solids, WORLD, WORLD), "Independent fixed new25 packet plus all unchanged District polygons, not live collision backfill"): return false
	return check(_clear(field.get("_player").position), "Ordinary birth full875+17 mask/raw continuous34x24 and true native Physics")

func ab_arrive() -> bool:
	var start := Time.get_ticks_usec()
	if not check(root.get_node("SceneRouter").call("go_field_smart", StringName(DOCKS), null, "", -1, -1), "Exactly one ordinary public default-null Docks request, no special spawn or candidate flag"): return false
	var until := mini(deadline, Time.get_ticks_msec() + AB_FIELD_ARRIVAL_MS)
	while Time.get_ticks_msec() < until:
		await process_frame
		var request: Dictionary = root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if request.get("scene_id") == DOCKS and request.get("phase") == "FAILED": return check(false, "Actual request failed rather than loading back to world", request)
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): continue
		var state: Dictionary = current_scene.call("get_field_loading_state")
		if state.get("failed", false): return check(false, "Actual Field preparation failed", state)
		var candidate := current_scene.get("_current_scene") as SceneScript
		var player := current_scene.get("_player") as CharacterBody2D
		if candidate == null or String(candidate.scene_id) != DOCKS or player == null or not bool(player.get("can_move")) or state.get("complete") != true: continue
		var screen: Node = root.get_node("LoadingManager").get("_screen")
		var panel := screen.get("root") as Control if is_instance_valid(screen) else null
		if panel != null and panel.is_visible_in_tree(): continue
		await RenderingServer.frame_post_draw
		field = current_scene; scene = candidate
		var first_draw_operable_usec: int = Time.get_ticks_usec() - start
		var source_check_start_usec: int = Time.get_ticks_usec()
		var proof: Dictionary = c.resident_receipt(scene)
		if not check(proof.get("sources_finalized") == true and proof.get("sources", {}) == expected_maps[DOCKS], "Actual same-owner finalized complete1466 sources exactly equal independent formaltrue map", {"actual_count": proof.get("sources", {}).size()}): return false
		for path: String in expected_maps[DOCKS]:
			if not track(path, expected_maps[DOCKS][path]): return false
		records.append({"kind": "ORDINARY_NULL_SPAWN_FIRSTDRAW_OPERABLE", "elapsed_usec": first_draw_operable_usec, "source_check_elapsed_usec": Time.get_ticks_usec() - source_check_start_usec, "travel_credit": false, "performance_promise": false, "actual_foot": player.position, "source_proof": proof.duplicate(true)})
		if not check(field.get_script().resource_path == FIELD and scene.actor_positions_are_feet and field.get("_world_size") == WORLD and player.position.distance_to(AB_DEFAULT_FOOT) < .03, "Unmodified actual Field/native feet and published default21401840 birth, not injected test foot"): return false
		return _geometry(DOCKS)
	return check(false, "Hidden Loading/first draw/operable within original fixed60s arrival")

func ab_sprite(id: String) -> Sprite2D:
	for node: Node in field.get("_scene_object_nodes"):
		if String(node.name) == "SceneObject_" + id: return node as Sprite2D
	return null

func ab_actual_layout() -> bool:
	for id: String in ["harbour_small_cargo_store", "south_canal_front", "harbour_main_warehouse"]:
		if not check(ab_sprite(id) == null and field.find_child("CityV3Physical_" + id, true, false) == null, "Removed no-door duplicate has no rendered or invisible physical residual " + id): return false
	var tasks: Script = load(AB_TASKS_PATH)
	var projected: Dictionary = tasks.project(scene, gs.get("flags"), qm.get("states"), scene.map_layout.interactions.duplicate(true))
	if not check(projected.get("ok") == true and projected.get("matched") == true, "Original task projection still admitted on unchanged native interactions"): return false
	var expected_visuals: Dictionary = {}
	for row: Dictionary in projected.visual_objects:
		if not check(not expected_visuals.has(row.id) and ab_sprite(row.id) != null, "Every exact current task-projected25 parent visual exists " + String(row.id)): return false
		expected_visuals[row.id] = true
	for object: Dictionary in ab_packet.record.objects:
		if not expected_visuals.has(object.id):
			if not check(object.id == "warehouse_mud_trace" and object.blocking == false and object.solid_polygons_px.is_empty() and _v(object.collision_size_px) == Vector2.ZERO and ab_sprite(object.id) == null and int(qm.get("states").get(tasks.CANAL, 0)) == 0, "Only original nonblocking unaccepted-task evidence intentionally hidden, not blanket visual exemption"): return false
		if not object.get("blocking", false): continue
		var body := field.find_child("CityV3Physical_" + String(object.id), true, false) as StaticBody2D
		if not check(body != null, "All retained base physical bodies exist " + String(object.id)): return false
		var polygons: Array[PackedVector2Array] = []
		for node: Node in body.get_children():
			if node is CollisionPolygon2D: polygons.append(node.polygon)
		if not check(polygons.size() == object.get("solid_polygons_px", []).size(), "Retained exact native polygon count " + String(object.id)): return false
		for i: int in polygons.size():
			if not check(polygons[i] == c._polygon(object.solid_polygons_px[i]), "Retained exact native world polygon coordinates " + String(object.id)): return false
	var author := json(AB_DISTRICT_AUTHOR)
	for placement: Dictionary in author.districts[DOCKS].placements:
		if not check(ab_sprite(placement.id) != null, "Unchanged District addition still rendered " + String(placement.id)): return false
	var office: Script = load(AB_OFFICE_PATH)
	var office_author := json(office.AUTHOR_PATH)
	var building := ab_sprite(office.BUILDING)
	if not check(building != null and building.texture.resource_path == office_author.office.texture and scene.get_meta(office.META, "") == office.AUTHOR_SHA, "Original professional office texture and source metadata preserved"): return false
	var crowd: Script = load(AB_CROWD_PATH)
	var moving := 0
	for row: Dictionary in crowd.project(StringName(DOCKS)):
		var npc := _person(String(row.npc_id))
		if npc == null: return false
		var texture: String = office_author.roles[row.npc_id].texture if office_author.roles.has(row.npc_id) else row.sprite_path
		if not check(npc.sprite_path == texture and npc.walk_sprite_path == row.walk_sprite_path and npc.movement_mode == row.movement_mode and npc.patrol_axis == row.patrol_axis and npc.patrol_distance == row.patrol_distance and npc.patrol_speed == row.patrol_speed and npc.invert_patrol_facing == row.invert_patrol_facing, "Original Harbour identity/profession/animation/lane parameters unchanged " + String(row.npc_id)): return false
		if row.movement_mode == "patrol": moving += 1
		if office_author.roles.has(row.npc_id):
			var body := npc.get("_body_collider") as StaticBody2D
			var shape := body.get_child(0) as CollisionShape2D
			if not check(npc.position == _v(office_author.roles[row.npc_id].expected_foot_px) and npc.sprite.hframes == 1 and npc.sprite.vframes == 1 and npc.sprite.texture.get_size() == Vector2(160, 160) and (shape.shape as RectangleShape2D).size == Vector2(22.4, 28.8), "Both actual professional160px NPC/nativefeet/body remain original"): return false
	if not check(moving == 6, "Original six moving lanes configured without replaying old animation suite"): return false
	for id: String in ["canal_old_soldier", "canal_work_chief", CLERK]:
		if _person(id) == null: return false
	for id: String in ["harbour_rope_shop", "north_canal_warehouse", "harbour_cargo_ship", "harbour_covered_ferry"]:
		if not check(ab_sprite(id) != null, "Protected rope/north-door building/two ships remain actual " + id): return false
	for foot: Vector2 in [Vector2(260,790), Vector2(260,1740), Vector2(2140,1840), Vector2(754,610)]:
		var found: Array = []
		for zone: ExitZone in field.get("_exit_nodes"):
			if zone.position.distance_to(foot) < .03: found.append(zone)
		if not check(found.size() == 1 and found[0].is_inside_tree() and found[0].get_parent() == field.get("_portal_layer"), "Original three exits and existing north warehouse doorway remain one real native Area at unchanged foot " + str(foot)): return false
		if not check(_clear(foot), "Original portal/doorway foot retains full87517/native34x24 clearance without entering " + str(foot)): return false
	if not check(not oracle.clear(Vector2(2600, 1400)) and not _mask_clear(Vector2(2600, 1400)), "Unchanged river water remains forbidden to full player footprint, not added ground support"): return false
	for foot: Vector2 in [Vector2(500,1130), Vector2(560,1570), Vector2(560,1600)]:
		if not check(_clear(foot), "New freed local foot now true full87517/nativePhysics clear without teleport " + str(foot)): return false
	records.append({"kind": "ACTUAL25_PLUS_DISTRICT_AND_PRESERVED_LIFE", "base_count": 25, "district_count": author.districts[DOCKS].placements.size(), "moving_lanes_configured": moving, "new_room_trip": false, "task_chain_replayed": false, "geometric_routes_replayed": false})
	return true

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began + AB_FIELD_WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves()
	folder = "res://build/luoyang_docks08_formal_field_20261019ab/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var complete := ab_preflight()
	if complete:
		gs = root.get_node("GameState"); qm = root.get_node("QuestManager"); dp = root.get_node("DialogPlayer")
		original_parts = {"flags": gs.get("flags").duplicate(true), "quests": qm.call("to_dict").duplicate(true)}
		original_rewards = _rewards()
		driver = (load(INPUT_PATH) as Script).new(); driver.configure(self)
		complete = await ab_arrive()
		if complete: complete = await _move(AB_DEFAULT_FOOT, AB_DEFAULT_FOOT + Vector2(32, 0))
		if complete: complete = ab_actual_layout()
		if complete: complete = await _picture("ordinary_docks08_default_after32px")
	if driver != null: driver.release(); driver = null
	if is_instance_valid(current_scene):
		var own: Node = current_scene; var weak: WeakRef = weakref(own)
		current_scene = null; own.queue_free(); field = null; scene = null; own = null
		await process_frame; await process_frame
		check(weak.get_ref() == null, "Own ordinary Docks Field naturally exits; no second city or room setup")
	if not original_parts.is_empty():
		check(qm.call("to_dict") == original_parts.quests and _rewards() == original_rewards, "No dialogue/quest/reward changes during visual/layout-only test")
		gs.set("flags", original_parts.flags.duplicate(true)); qm.call("from_dict", original_parts.quests.duplicate(true))
		check(gs.get("flags") == original_parts.flags and qm.call("to_dict") == original_parts.quests, "Restore only ordinary visit flags/unchanged QM memory, never save slots")
	oracle = null; mask = null; ab_packet.clear(); ab_record.clear()
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after := saves()
	check(source_before == source_after and players_before == players_after and players_before.size() == 15, "Complete1466 runtime/test source and fifteen save first-final facts unchanged")
	check(pictures.size() <= 2 and Time.get_ticks_msec() < deadline, "Original fixed90s whole/60s arrival, maximum two captures, no expanded suite")
	var path := folder.path_join("result.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope": "ONE_ORDINARY_DOCKS_DEFAULT_BIRTH_32INPUT_NEW25_NATIVE_PHYSICS_NOT_FULL08_ART", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "budget_ms": AB_FIELD_WHOLE_MS, "arrival_ms": AB_FIELD_ARRIVAL_MS, "native_queries": native_queries, "records": records, "pictures": pictures, "source_before": source_before, "source_after": source_after, "players_before": players_before, "players_after": players_after, "room_trip": false, "old_geometry_or_city_or_culture_suite_repeated": false}, "\t", true, true)); file.close()
	print(JSON.stringify({"report_path": path, "checks": checks, "failures": failures, "complete": complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
