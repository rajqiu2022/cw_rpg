extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## NOTREADY: real production Field journey only, never a Sprite preview/owner fixture.
## ROOT alone compiles/runs a frozen successor after final walls/import/source epoch.
const TRAVEL_READY: bool = false
const FIXTURE: String = "res://build/luoyang_estate_courtyard_20261021an_qa01/travel_fixture_placement_retry1_PENDING.json"
const FIXTURE_SHA: String = "PENDING_FINAL_INDEPENDENT_FIXTURE"
const WHOLE_MS: int = 180000
const ARRIVAL_MS: int = 60000
const MARKET: String = "ch4_s3_luoyang_market"
const ESTATE: String = "luoyang_estate_riverside_20261021ai"
const MANSION: String = "luoyang_functional_mansion_candidate_20261016"
const DESIGN: Vector2 = Vector2(3072, 2048)
const FIELD_PATH: String = "res://scripts/field/field_walkable_controller.gd"
const CITY_PATH: String = "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const FAMILY_PATH: String = "res://scripts/city/luoyang_estate_family_20261021am.gd"
const RAW_PATH: String = "res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd"
const INPUT_PATH: String = "res://tests/helpers/v15_input_driver.gd"
const INHERITED_QA: Dictionary = {
	"res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd": "a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895",
	RAW_PATH: "0f00d4a8a7bc7f514d4b0859275c2eb6d03296dd81eaa170416694c6068b2835",
	INPUT_PATH: "a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7"
}
var fixed: Dictionary = {}
var field: Node
var scene: SceneScript
var driver: RefCounted
var oracle: RefCounted
var mask: Image
var geometry_size: Vector2
var world: Vector2
var city: Script
var family: Script
var began: int = 0
var folder: String = ""
var native_queries: int = 0
var pictures: Array[Dictionary] = []
var prior_fields: Array[WeakRef] = []
var state_before: Dictionary = {}
var reached_legs: int = 0

func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists": false, "sha256": "ABSENT", "bytes": 0, "mtime_seconds": "0"}
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null: return {"exists": true, "read_error": true}
	var count: int = f.get_length(); f.close()
	return {"exists": true, "sha256": FileAccess.get_sha256(path), "bytes": count, "mtime_seconds": str(FileAccess.get_modified_time(path))}

func _json(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func _v(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(value[0], value[1])

func _state() -> Dictionary:
	var gs: Node = root.get_node("GameState")
	return {"flags": gs.get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict").duplicate(true), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true), "gold": gs.get("gold"), "training_total": gs.get("training_points_total"), "training_available": gs.get("training_points_available"), "reputation": gs.get("reputation")}

func _preflight() -> bool:
	if not check(TRAVEL_READY, "Draft refuses before final wall mask/import/formal source freeze"): return false
	if not check(DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().is_empty() and Engine.time_scale == 1.0 and root.size == Vector2i(1920, 1080), "Ordinary no-flag fixed-viewport production GUI, not candidate owner"): return false
	if not track(FIXTURE, FIXTURE_SHA): return false
	fixed = _json(FIXTURE)
	if not check(fixed.get("status") == "ROOT_FROZEN_AN_FORMAL_JOURNEY" and fixed.get("legs", []).size() == 5, "Independent final five-leg fixture"): return false
	for path: String in INHERITED_QA:
		if not track(path, INHERITED_QA[path]): return false
	var ids: Array = []
	for leg: Dictionary in fixed.legs: ids.append(leg.id)
	if not check(ids == [MARKET, ESTATE, MANSION, ESTATE, MARKET] and _v(fixed.expected_design_size) == DESIGN, "Exact authorized directed journey and independent design dimensions"): return false
	for path: String in fixed.test_dependencies:
		if not track(path, fixed.test_dependencies[path]): return false
	# Self is first/final protected, not accepted as an independently approved dependency.
	var own_path: String = get_script().resource_path
	if not track(own_path, FileAccess.get_sha256(own_path)): return false
	for path: String in [RAW_PATH, INPUT_PATH, FIELD_PATH, CITY_PATH, FAMILY_PATH]:
		if not check(fixed.test_dependencies.has(path), "Every executed helper/production entry fixed before load " + path): return false
	for row: Dictionary in fixed.actual_receipts:
		if not track(row.path, row.sha256): return false
		var receipt: Dictionary = _json(row.path)
		if not check(receipt.get(row.success_field) == row.success_value and receipt.get(row.first_field) == receipt.get(row.final_field) and receipt.get(row.first_field) is Dictionary and not receipt.get(row.first_field).is_empty(), "Fixed completed component receipt, not old whole FAIL " + row.path): return false
	city = load(CITY_PATH) as Script; family = load(FAMILY_PATH) as Script
	if not check(city != null and city.can_instantiate() and family != null and family.can_instantiate() and family.requested() == true, "Real default-enabled family and city APIs compile in autoload context"): return false
	var input_script: Script = load(INPUT_PATH) as Script
	if not check(input_script != null and input_script.can_instantiate(), "Input driver can instantiate"): return false
	driver = input_script.new(); driver.configure(self)
	return true

func _native(foot: Vector2) -> bool:
	if not is_instance_valid(field): return false
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	if player == null: return false
	var shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or shape.position != Vector2.ZERO or not shape.shape is RectangleShape2D or (shape.shape as RectangleShape2D).size != Vector2(34, 24): return false
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape; query.transform = shape.global_transform
	query.transform.origin += (field.get("world_container") as Node2D).to_global(foot) - player.global_position
	query.exclude = [player.get_rid()]; query.collision_mask = 1; query.collide_with_areas = false
	native_queries += 1
	return player.get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty()

func _mask_clear(foot: Vector2) -> bool:
	if mask == null: return false
	# For rooms actual display scale differs; test the actual 34x24 world body
	# against source raster, not a falsely enlarged source-space body.
	var rounded: Vector2 = foot.round()
	for y: int in range(-12, 13):
		for x: int in range(-17, 18):
			var point: Vector2i = Vector2i(((rounded + Vector2(x, y)) * geometry_size / world).floor())
			if point.x < 0 or point.y < 0 or point.x >= mask.get_width() or point.y >= mask.get_height(): return false
			var color: Color = mask.get_pixelv(point)
			if color.r < .5 or color.a < .5: return false
	return true

func _clear(foot: Vector2) -> bool:
	return Time.get_ticks_msec() < deadline and is_instance_valid(field) and current_scene == field and oracle != null and oracle.clear(foot) and _mask_clear(foot) and _native(foot)

func _segment(a: Vector2, b: Vector2) -> Dictionary:
	var count: int = maxi(1, ceili(a.distance_to(b) / 4.0))
	for index: int in range(count + 1):
		var point: Vector2 = a.lerp(b, float(index) / count)
		if Time.get_ticks_msec() >= deadline or not oracle.clear(point) or not _mask_clear(point): return {"clear": false, "index": index, "foot": point, "raw": oracle.last}
	return {"clear": true, "samples": count + 1, "full87517": true, "continuous_body": [34, 24], "step_le4": true}

func _configure_geometry(id: String) -> bool:
	var geometry: Dictionary = fixed.geometry[id]
	geometry_size = _v(geometry.source_size_px)
	var raw_script: Script = load(RAW_PATH) as Script
	if not check(raw_script != null and raw_script.can_instantiate(), "Independent polygon oracle compiles"): return false
	oracle = raw_script.new()
	if not check(oracle.configure(geometry.floor_regions_px, geometry.solids, geometry_size, world, geometry.get("foot_forbidden_regions_px", [])), "Source-authored polygons, not runtime clearance as its own oracle " + id): return false
	if not check(fixed.expected_sources[id].get(geometry.mask_path) == geometry.mask_sha256, "Raw mask belongs to complete independent source map"): return false
	mask = Image.load_from_file(geometry.mask_path)
	return check(mask != null and mask.get_size() == Vector2i(geometry_size) and _clear(field.get("_player").position), "Arrival actual body/87517/raw polygon/mask/Physics agree " + id)

func _arrive(leg: Dictionary, started_us: int) -> bool:
	var until: int = mini(deadline, Time.get_ticks_msec() + ARRIVAL_MS)
	while Time.get_ticks_msec() < until:
		await process_frame
		var request: Dictionary = root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if request.get("scene_id") == leg.id and request.get("phase") == "FAILED": return check(false, "Real request refused; no silent world fallback", request)
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): continue
		var loading: Dictionary = current_scene.call("get_field_loading_state")
		if loading.get("failed", false): return check(false, "Real Field loading failure", loading)
		var candidate: SceneScript = current_scene.get("_current_scene") as SceneScript
		var player: CharacterBody2D = current_scene.get("_player") as CharacterBody2D
		if candidate == null or String(candidate.scene_id) != leg.id or player == null or player.get("can_move") != true or loading.get("complete") != true: continue
		var screen: Node = root.get_node("LoadingManager").get("_screen")
		var panel: Control = screen.get("root") as Control if is_instance_valid(screen) else null
		if panel != null and panel.is_visible_in_tree(): continue
		await RenderingServer.frame_post_draw
		field = current_scene; scene = candidate; world = _v(leg.world_size)
		var firstdraw_us: int = Time.get_ticks_usec() - started_us
		if not check(firstdraw_us <= ARRIVAL_MS * 1000, "Hidden Loading firstdraw/operable within original sixty-second budget", firstdraw_us): return false
		if not check(field.get_script().resource_path == FIELD_PATH and scene.actor_positions_are_feet and field.get("_world_size") == world and player.position.distance_to(_v(leg.arrival_uv) * world) < .03, "Unmodified actual Field/native feet/exact independently authored or remembered return", {"id": leg.id, "actual_world": field.get("_world_size"), "expected_world": world, "actual_foot": player.position, "expected_uv": leg.arrival_uv}): return false
		if leg.id == ESTATE:
			if not check(world == DESIGN and scene.map_layout.design_size == Vector2i(DESIGN) and scene.background_path == fixed.estate_background.path, "Independent 3:2 native background produces 3072x2048, no actual backfill"): return false
			if not check(family.matches(scene) and scene.resource_path == fixed.estate_native.scene_path and scene.map_layout.resource_path == fixed.estate_native.layout_path and scene.map_layout.visual_objects.size() == fixed.estate_native.visual_count and scene.map_layout.blockers.size() == fixed.estate_native.solid_count, "Actual same-instance native storage bound to fixed packet with exact new entity counts"): return false
			for row: Dictionary in fixed.estate_native.new_entities:
				var visuals: Array = scene.map_layout.visual_objects.filter(func(item: Dictionary) -> bool: return item.get("id") == row.id)
				if not check(visuals.size() == 1, "One source-bound new visual " + row.id): return false
				var foot: Vector2 = _v(row.foot_px)
				var canvas: Vector2 = _v(row.source_size_px)
				var anchor: Vector2 = _v(row.source_anchor_px)
				var uniform_scale: float = float(row.uniform_scale)
				# Independent source placement, including transparent padding/anchor.
				# Match the serialized Vector2f domain byte-exactly; no epsilon.
				var draw_center: Vector2 = foot + (canvas * .5 - anchor) * uniform_scale
				var expected_position: Vector2 = draw_center / DESIGN
				var expected_render: Vector2 = canvas * uniform_scale
				var actual_position: Variant = visuals[0].get("pos")
				var actual_render: Variant = visuals[0].get("render_size_px")
				if not check(actual_position is Vector2 and actual_render is Vector2 and visuals[0].get("texture") == row.texture and PackedVector2Array([actual_position, actual_render]).to_byte_array() == PackedVector2Array([expected_position, expected_render]).to_byte_array() and visuals[0].get("depth_sort_foot_y") == foot.y / DESIGN.y and visuals[0].get("centered") == true and visuals[0].get("sort_by_feet") == true, "Independent source canvas/anchor/scale draw-center and ground-depth footprint " + row.id, {"foot": foot, "draw_center": draw_center, "actual_pos": actual_position, "expected_pos": expected_position}): return false
		var proof: Dictionary = city.resident_receipt(scene) if leg.id == MARKET else family.validation_receipt()
		var expected: Dictionary = fixed.expected_sources[leg.id]
		if leg.id == MARKET:
			if not check(proof.get("sources_finalized") == true and proof.get("sources") == expected, "Actual Market finalized whole source set equals independent staged map", {"actual": proof.get("sources", {}).size(), "expected": expected.size()}): return false
		else:
			if not check(proof.get("finalized") == true and proof.get("source_first") == fixed.family_validation_sources and proof.get("source_final") == fixed.family_validation_sources and proof.get("full_source_hash_passes") == 2, "Actual joint family first/final source receipt exact independent manifest domain"): return false
		var hash_start: int = Time.get_ticks_usec()
		for path: String in expected:
			if not track(path, expected[path]): return false
		records.append({"kind": "REAL_JOURNEY_FIRSTDRAW", "id": leg.id, "firstdraw_hidden_operable_us": firstdraw_us, "postdraw_source_check_us": Time.get_ticks_usec() - hash_start, "proof": proof.duplicate(true), "initial_public_setup": reached_legs == 0, "performance_target_claimed": false})
		reached_legs += 1
		return _configure_geometry(leg.id)
	return check(false, "Actual intended destination not ready in fixed arrival budget " + leg.id)

func _picture(name: String) -> bool:
	if not check(pictures.size() < 2 and String(scene.scene_id) == ESTATE, "At most two actual Estate gameplay pictures, camera untouched"): return false
	await RenderingServer.frame_post_draw
	var path: String = folder.path_join(name + ".png")
	if not check(not FileAccess.file_exists(path), "Picture output refuses overwrite"): return false
	var image: Image = root.get_texture().get_image()
	if not check(image != null and image.save_png(path) == OK, "Actual gameplay screenshot"): return false
	pictures.append({"path": path, "sha256": FileAccess.get_sha256(path), "qa_camera_modified": false, "player": field.get("_player").position})
	return true

func _walk(leg: Dictionary) -> bool:
	var points: PackedVector2Array = PackedVector2Array()
	for raw: Array in leg.points_px: points.append(_v(raw) * world / _v(leg.source_size_px))
	if not check(points.size() >= 2 and field.get("_player").position.distance_to(points[0]) < .3, "Complete authored path begins at actual arrival, never teleport"): return false
	var result: Dictionary = await driver.follow(field, points, _clear, _segment)
	records.append({"kind": "REAL_INPUT_AUTHORED_PATH_ONLY", "id": leg.id, "result": result})
	if not check(result.get("ok") == true, "Actual INPUT with every reached foot native/87517 clear", result): return false
	for probe: Dictionary in leg.get("blocked_probes", []):
		var point: Vector2 = _v(probe.foot_px) * world / _v(leg.source_size_px)
		if not check(not oracle.clear(point) and not _mask_clear(point) and not _native(point), "Representative new solid polygon/mask/actual Physics all block " + probe.id): return false
	if leg.has("picture") and not await _picture(leg.picture): return false
	return true

func _portal(leg: Dictionary, next: Dictionary) -> bool:
	var expected_foot: Vector2 = _v(leg.portal.foot_px) * world / _v(leg.source_size_px)
	var matches: Array[ExitZone] = []
	for node: Node in (field.get("_portal_layer") as Node).get_children():
		if node is ExitZone and node.target_scene_id == next.id: matches.append(node as ExitZone)
	if not check(matches.size() == 1 and matches[0].position == expected_foot and matches[0].target_spawn_pos == _v(leg.portal.target_uv) and not matches[0].is_locked and not matches[0].auto_trigger and matches[0].action.is_empty(), "One real manual exact-source portal to intended next Scene, no signal/API injection"): return false
	var bindings: Array = matches[0].get_signal_connection_list("exit_triggered")
	if not check(bindings.size() == 1 and bindings[0].callable.get_object() == field and bindings[0].callable.get_method() == "_on_exit_triggered" and bindings[0].callable.get_bound_arguments() == [_v(leg.portal.source_spawn_uv)], "True portal callback carries independent authored return source, not arbitrary remembered feet"): return false
	await driver.completed_actor_stage()
	if not check(_clear(field.get("_player").position) and matches[0].get("_in_range") == true and not root.get_node("DialogPlayer").call("is_playing"), "Normal Space is in actual intended portal range and outside dialogue"): return false
	var old: Node = field; prior_fields.append(weakref(old))
	var started_us: int = Time.get_ticks_usec()
	await driver.key(KEY_SPACE)
	return await _arrive(next, started_us)

func _journey() -> bool:
	var started_us: int = Time.get_ticks_usec()
	if not check(root.get_node("SceneRouter").call("go_field_smart", StringName(MARKET)), "Only initial ordinary public default Market setup; all four subsequent transfers use true Space"): return false
	if not await _arrive(fixed.legs[0], started_us): return false
	for index: int in range(5):
		var leg: Dictionary = fixed.legs[index]
		if not await _walk(leg): return false
		if index < 4 and not await _portal(leg, fixed.legs[index + 1]): return false
	return check(reached_legs == 5, "All real directed transfers returned to Market, not previews or separate setups")

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began + WHOLE_MS
	folder = "res://build/luoyang_estate_courtyard_20261021an_qa01/travel_%d" % OS.get_process_id()
	if DirAccess.dir_exists_absolute(folder): printerr("AN_REPORT_ALREADY_EXISTS ", folder); quit(2); return
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves(); state_before = _state()
	var complete: bool = _preflight()
	if complete: complete = await _journey()
	if driver != null: driver.release(); driver = null
	if is_instance_valid(current_scene):
		var own: Node = current_scene; var weak: WeakRef = weakref(own)
		current_scene = null; own.queue_free(); field = null; scene = null; own = null
		await process_frame; await process_frame
		check(weak.get_ref() == null, "Own final current Field naturally released")
	# Router resident park may retain exactly its normal bounded city cache;
	# no fake release assertions or private cache mutation are used here.
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after: Dictionary = saves(); var state_after: Dictionary = _state()
	check(source_before == source_after, "Complete actually consumed sources first/final unchanged")
	check(players_before.size() == 15 and players_before == players_after, "Fifteen absent/present save facts unchanged; checkpoint writes suspended")
	check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended") == true, "Checkpoint suppression remains active for the entire isolated test process")
	check(state_before == state_after, "Flags/QM/inventory/rewards unchanged by pure travel; no state restoration masks mutation")
	check(Time.get_ticks_msec() < deadline, "Fixed180s whole real journey budget; no ten-second performance promise")
	var path: String = folder.path_join("result.json")
	if FileAccess.file_exists(path): printerr("AN_RESULT_REFUSES_OVERWRITE"); quit(2); return
	var report: Dictionary = {"scope": "AN_FORMAL_MARKET_ESTATE_MANSION_ESTATE_MARKET_TRUE_INPUT_SPACE_ONLY", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "budget_ms": WHOLE_MS, "arrival_ms": ARRIVAL_MS, "reached_legs": reached_legs, "native_queries": native_queries, "records": records, "pictures": pictures, "source_before": source_before, "source_after": source_after, "players_before": players_before, "players_after": players_after, "state_before": state_before, "state_after": state_after, "old_full_geometry_or_city_room_suite_retested": false, "mtime_precision": "Godot seconds String; Root independent guard covers exact UTC ticks"}
	var output: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if output == null: printerr("AN_RESULT_OPEN_FAILED"); quit(2); return
	output.store_string(JSON.stringify(report, "\t")); output.close()
	print(JSON.stringify({"report_path": path, "checks": checks, "failures": failures, "complete": report.complete}))
	quit(0 if report.complete else 1)

