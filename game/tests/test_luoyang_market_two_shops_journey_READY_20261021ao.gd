extends "res://tests/test_luoyang_estate_formal_travel_remaining_READY_20261021an.gd"
## READY: exact staged_dependency_retry3; Root alone executes after all20 explicit targets deploy.
## Reuses only frozen input/physics/save helpers, never runs the prior AN journey.
const AO_READY: bool = true
const AO_FIXTURE: String = "res://build/luoyang_market_two_shops_20261021ao_qa01/journey_fixture_READY.json"
const AO_FIXTURE_SHA: String = "0623b3981c1bd785e9ca5655f7b5ffe3cb20c570bfa1784db12cf3e13cc67db0"
const HERBAL: String = "luoyang_market_market_northeast_rear_frontage_interior_20261015"
const STUDY: String = "luoyang_market_market_east_ward_frontage_interior_20261015"
const G_PATH: String = "res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
const BUNDLE_PATH: String = "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
var rooms_api: Script
var bundle_api: Script
var remembered_returns: Dictionary = {}
var retired_visual_checked: bool = false

func _preflight() -> bool:
	if not check(AO_READY, "PENDING author/source/geometry epoch never runs"): return false
	if not check(DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().is_empty() and Engine.time_scale == 1.0 and root.size == Vector2i(1920,1080), "Normal no-userflag production GUI viewport"): return false
	if not track(AO_FIXTURE, AO_FIXTURE_SHA): return false
	fixed = _json(AO_FIXTURE)
	if not check(fixed.get("status") == "ROOT_FROZEN_AO_TWO_SHOPS_FIVE_LEG_JOURNEY" and fixed.get("legs", []).size() == 5, "Frozen two-room same-session journey only"): return false
	var ids: Array = []
	for leg: Dictionary in fixed.legs: ids.append(leg.id)
	if not check(ids == [MARKET,HERBAL,MARKET,STUDY,MARKET], "One initial Market and four real portal transfers, not ten rooms or Estate"): return false
	if not track(fixed.stage_receipt.path,fixed.stage_receipt.sha256): return false
	var staged: Dictionary = _json(fixed.stage_receipt.path)
	if not check(staged.get("status") == "AO_EXACT_TWO_SHOP_SOURCE_SUCCESSOR_READY_NOT_DEPLOYED" and staged.get("targets",[]).size() == 20 and staged.get("single_batch_true_deployment_required") == true and staged.get("two_room_registry_whole_inverse") == true and staged.get("other9_rows_unchanged_and_mansion_source_only_successor") == true and staged.get("family_source_count") == 331, "Exact final20-target dependency scope; staging receipt is not itself deployment or Field PASS"): return false
	var market_stage: Dictionary = staged.independent_expected_maps[MARKET]
	if not check(market_stage.count == 1367 and market_stage.old_plus_finite_delta == true and market_stage.true_path == fixed.source_domains[0].path and market_stage.true_sha256 == fixed.source_domains[0].sha256, "Market1367 expected comes from original source map plus finite declared successor, not current collector"): return false
	if not track(fixed.registry.candidate_path,fixed.registry.sha256) or not track(fixed.registry.canonical_path,fixed.registry.sha256): return false
	var runtime_registry: Dictionary = _json(fixed.registry.candidate_path)
	if not check(runtime_registry.get("rooms",{}).size() == 12, "Actual deployed registry remains twelve rooms"): return false
	for path: String in fixed.test_dependencies:
		if not track(path, fixed.test_dependencies[path]): return false
	var own_path: String = get_script().resource_path
	if not track(own_path, FileAccess.get_sha256(own_path)): return false
	for path: String in [RAW_PATH,INPUT_PATH,FIELD_PATH,CITY_PATH,G_PATH,BUNDLE_PATH]:
		if not check(fixed.test_dependencies.has(path), "Executed helper/API has independently inherited fixed source " + path): return false
	if not track(fixed.author.path, fixed.author.sha256): return false
	domain = _json(fixed.author.path)
	if not check(domain.get("status") == "READY_AO_TWO_SHOPS_ACTUAL_ART" and domain.get("parent_count") == 24 and domain.get("child_count") == 24 and domain.get("district_count") == 36 and domain.get("new_objects", []).size() == 2, "Exactly two replacements keep24 native and36 District; not old AI three buildings"): return false
	for row: Dictionary in fixed.component_receipts:
		if not track(row.path, row.sha256): return false
		var receipt: Dictionary = _json(row.path)
		if not check(receipt.get(row.success_field) == row.success_value and receipt.get(row.first_field) is Dictionary and not receipt.get(row.first_field).is_empty() and receipt.get(row.first_field) == receipt.get(row.final_field), "Pinned completed CPU/import component, not Field credit " + row.path): return false
	fixed.expected_sources = {}
	for descriptor: Dictionary in fixed.source_domains:
		if not track(descriptor.path, descriptor.sha256): return false
		var source_document: Dictionary = _json(descriptor.path)
		var expected: Dictionary = source_document.get("source_sha256", {})
		if not check(expected.size() == descriptor.count and descriptor.count > 0 and not fixed.expected_sources.has(descriptor.id), "Exact independently staged source domain, never collector-backfilled " + descriptor.id): return false
		fixed.expected_sources[descriptor.id] = expected
	for id: String in [MARKET,HERBAL,STUDY]:
		if not check(fixed.expected_sources.has(id), "All actually consumed scene domains fixed before setup " + id): return false
	for id: String in [HERBAL,STUDY]:
		if not check(fixed.expected_sources[id] == runtime_registry.rooms[id].source_sha256, "Exact per-room declared source closure from independent staged registry " + id): return false
	# Original room geometry is the independent oracle; only return/building metadata may change.
	for row: Dictionary in fixed.room_domains:
		if not track(row.original_author, row.original_author_sha256) or not track(row.new_author, row.new_author_sha256): return false
		var original: Dictionary = _json(row.original_author)
		var successor: Dictionary = _json(row.new_author)
		if not check(original.geometry == successor.geometry and original.room.scene_id == successor.room.scene_id and successor.room.city_id == MARKET and successor.room.building_id == row.building_id and successor.room.return_foot_px == row.return_foot_px, "Old room identity and all internal geometry preserved; paired new return only " + row.id): return false
	city = load(CITY_PATH) as Script; rooms_api = load(G_PATH) as Script; bundle_api = load(BUNDLE_PATH) as Script
	var input_script: Script = load(INPUT_PATH) as Script
	if not check(city != null and city.can_instantiate() and rooms_api != null and rooms_api.can_instantiate() and bundle_api != null and bundle_api.can_instantiate() and input_script != null and input_script.can_instantiate(), "Real production APIs compile in established autoload context"): return false
	driver = input_script.new(); driver.configure(self)
	return true

func _mask_clear(foot: Vector2) -> bool:
	if mask == null: return not raster_required and String(scene.scene_id) in [HERBAL,STUDY]
	var rounded: Vector2 = foot.round()
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			var point: Vector2i = Vector2i(((rounded+Vector2(x,y))*geometry_size/world).floor())
			if point.x < 0 or point.y < 0 or point.x >= mask.get_width() or point.y >= mask.get_height(): return false
			var color: Color = mask.get_pixelv(point)
			if color.r < .5 or color.a < .5: return false
	return true

func _configure_geometry(id: String) -> bool:
	var geometry: Dictionary = {}
	if id == MARKET:
		if not track(fixed.market_geometry_base.path, fixed.market_geometry_base.sha256): return false
		geometry = _json(fixed.market_geometry_base.path).geometry[MARKET].duplicate(true)
		var kept: Array = []
		for row: Dictionary in geometry.solids:
			if row.id not in fixed.retired_solid_ids: kept.append(row.duplicate(true))
		if not check(geometry.solids.size()-kept.size() == 2, "Only retired shared building and wall solids removed from independent parent"): return false
		for index: int in 2:
			var asset: Dictionary = domain.assets["apothecary" if index == 0 else "study"]
			var foot: Vector2 = _v(domain.new_objects[index].world_foot_px)
			var anchor: Vector2 = _v(asset.source_ground_anchor_px)
			for poly_index: int in asset.ground_solid_polygons_px.size():
				var points: Array = []
				for source_point: Array in asset.ground_solid_polygons_px[poly_index]: points.append(foot+(_v(source_point)-anchor)*float(asset.scale))
				kept.append({"id": String(domain.new_objects[index].id)+"_poly_%d"%poly_index, "points_px": points})
		geometry.solids = kept
	else:
		var rows: Array = fixed.room_domains.filter(func(row: Dictionary) -> bool: return row.id == id)
		if not check(rows.size() == 1, "One independent original room author"): return false
		geometry = _json(rows[0].original_author).geometry.duplicate(true)
		geometry.solids = []
		for row: Dictionary in geometry.furniture_bases:
			if row.get("blocking") == true: geometry.solids.append({"id":row.id,"points_px":row.ground_polygon_px})
	geometry_size = _v(geometry.source_size_px)
	var raw_script: Script = load(RAW_PATH) as Script
	if not check(raw_script != null and raw_script.can_instantiate(), "Independent polygon oracle compiles"): return false
	oracle = raw_script.new()
	if not check(oracle.configure(geometry.floor_regions_px,geometry.solids,geometry_size,world,geometry.get("foot_forbidden_regions_px",[])), "Full source geometry body oracle; not production clearance as expected"): return false
	raster_required = id == MARKET
	if raster_required:
		if not check(fixed.expected_sources[id].get(fixed.market_mask.path) == fixed.market_mask.sha256, "New Market raster fixed by independent current source map"): return false
		mask = Image.load_from_file(fixed.market_mask.path)
		if not check(mask != null and mask.get_size() == Vector2i(3072,2048), "New actual Market raw raster dimensions"): return false
	else:
		mask = null
		if not check(scene.map_layout.walkable_mask_path.is_empty() and geometry_size == Vector2(1536,1024) and world == Vector2(1920,1280), "Original room polygon-only geometry; no invented mask credit"): return false
	return check(_clear(field.get("_player").position), "Actual arrival34x24/nativePhysics/full87517/continuous source-domain clearance " + id)

func _arrive(leg: Dictionary, started_us: int) -> bool:
	var until: int = mini(deadline,Time.get_ticks_msec()+60000)
	while Time.get_ticks_msec() < until:
		await process_frame
		if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): continue
		var request: Dictionary = root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if request.get("scene_id") == leg.id and request.get("phase") == "FAILED": return check(false,"Production Router refused intended scene; no silent fallback",request)
		var loading: Dictionary = current_scene.call("get_field_loading_state")
		if loading.get("failed") == true: return check(false,"Production Field failed",loading)
		var candidate: SceneScript = current_scene.get("_current_scene") as SceneScript
		var player: CharacterBody2D = current_scene.get("_player") as CharacterBody2D
		if candidate == null or String(candidate.scene_id) != leg.id or player == null or player.get("can_move") != true or loading.get("complete") != true: continue
		var screen: Node = root.get_node("LoadingManager").get("_screen")
		var panel: Control = screen.get("root") as Control if is_instance_valid(screen) else null
		if panel != null and panel.is_visible_in_tree(): continue
		await RenderingServer.frame_post_draw
		field = current_scene; scene = candidate; world = _v(leg.world_size)
		var firstdraw_us: int = Time.get_ticks_usec()-started_us
		if not check(firstdraw_us <= 60000000 and field.get_script().resource_path == FIELD_PATH and scene.actor_positions_are_feet and field.get("_world_size") == world and player.position.distance_to(_v(leg.arrival_uv)*world) < .03, "Real hidden Loading, authored world/feet and precise portal return within60s",{"id":leg.id,"actual":player.position,"expected_uv":leg.arrival_uv,"firstdraw_us":firstdraw_us}): return false
		if not check(scene.resource_path == fixed.scene_paths[leg.id], "Real published native Scene resource identity"): return false
		if leg.id == MARKET:
			var proof: Dictionary = city.resident_receipt(scene)
			if not check(proof.get("sources_finalized") == true and proof.get("sources") == fixed.expected_sources[MARKET] and scene.map_layout.design_size == Vector2i(3072,2048) and scene.map_layout.visual_objects.size() == 24, "Current independent whole Market source proof and unchanged native count24"): return false
			if not retired_visual_checked:
				if not check(bundle_api.ao_retired_visual_id(scene,"v13_market_east_plot_wall") == true, "Only actual published bound Market authorizes retired wall omission"): return false
				if not check(bundle_api.ao_retired_visual_id(scene,"market_east_ward_frontage") == false, "Other retained/new ID cannot borrow retired-wall exemption"): return false
				var unbound: SceneScript = scene.duplicate(true) as SceneScript
				if not check(unbound != null and bundle_api.ao_retired_visual_id(unbound,"v13_market_east_plot_wall") == false, "Copied native metadata is not a whole-bound actual scene"): return false
				unbound.scene_id = &"ch4_s0_luoyang_gate"
				if not check(bundle_api.ao_retired_visual_id(unbound,"v13_market_east_plot_wall") == false, "Non-Market cannot borrow AO retired-wall exemption"): return false
				retired_visual_checked = true
		else:
			if not check(rooms_api.matches(scene,StringName(leg.id)), "Original two-room strict production binding"): return false
		var hash_start: int = Time.get_ticks_usec()
		for path: String in fixed.expected_sources[leg.id]:
			if not track(path,fixed.expected_sources[leg.id][path]): return false
		records.append({"kind":"AO_ACTUAL_FIRSTDRAW_AND_SOURCE","id":leg.id,"firstdraw_hidden_operable_us":firstdraw_us,"postdraw_sourcecheck_us":Time.get_ticks_usec()-hash_start,"initial_public_setup":reached_legs==0,"performance_target_claimed":false})
		reached_legs += 1
		return _configure_geometry(leg.id)
	return check(false,"Intended AO destination not ready within60s",{"expected":leg.id,"router":root.get_node("SceneRouter").call("get_public_city_preparation_state"),"actual_scene":String(scene.scene_id) if scene != null else ""})

func _picture(name: String) -> bool:
	if not check(pictures.size() < 2 and String(scene.scene_id) == MARKET,"At most two real Market pictures, ordinary unmodified camera"): return false
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = folder.path_join(name+".png")
	if not check(not FileAccess.file_exists(path) and image != null and image.save_png(path) == OK,"New actual gameplay PNG only"): return false
	pictures.append({"path":path,"sha256":FileAccess.get_sha256(path),"qa_camera_modified":false,"player":field.get("_player").position})
	return true

func _portal(leg: Dictionary, next: Dictionary) -> bool:
	var expected_foot: Vector2 = _v(leg.portal.foot_px)*world/_v(leg.source_size_px)
	var matches: Array[ExitZone] = []
	for node: Node in (field.get("_portal_layer") as Node).get_children():
		if node is ExitZone and node.target_scene_id == next.id: matches.append(node as ExitZone)
	if not check(matches.size() == 1 and matches[0].position == expected_foot and matches[0].target_spawn_pos == _v(leg.portal.target_uv) and not matches[0].is_locked and not matches[0].auto_trigger and matches[0].action.is_empty(), "One real manual exact-source portal to paired shop/Market",{"from":leg.id,"to":next.id,"matches":matches.size()}): return false
	var bindings: Array = matches[0].get_signal_connection_list("exit_triggered")
	if not check(bindings.size() == 1 and bindings[0].callable.get_object() == field and bindings[0].callable.get_method() == "_on_exit_triggered" and bindings[0].callable.get_bound_arguments() == [_v(leg.portal.source_spawn_uv)], "Callback retains independent authored source anchor"): return false
	await driver.completed_actor_stage()
	var player: CharacterBody2D = field.get("_player") as CharacterBody2D
	if not check(_clear(player.position) and matches[0].get("_in_range") == true and not root.get_node("DialogPlayer").call("is_playing"), "Real Space occurs at clear foot inside intended manual portal range"): return false
	# Production Field3817 remembers the actual pre-Space foot on city->room.
	# This is measured BEFORE transfer, never copied from a later returned position.
	if leg.id == MARKET:
		var actual_source_uv: Vector2 = player.position/world
		if not check(field.call("resident_actual_spawn") == actual_source_uv and player.position.distance_to(expected_foot) < .3, "Source remembers actual INPUT arrival foot, not a guessed return marker"): return false
		remembered_returns[next.id] = actual_source_uv
		records.append({"kind":"AO_TRUE_SPACE_SOURCE_FOOT_BEFORE_DEPARTURE","room":next.id,"actual_source_uv":actual_source_uv,"authored_marker_uv":leg.portal.source_spawn_uv,"authored_room_spawn_uv":leg.portal.target_uv})
	else:
		if not check(remembered_returns.has(leg.id), "Matching prior true city departure exists before room return"): return false
		next["arrival_uv"] = remembered_returns[leg.id]
	var old: Node = field; prior_fields.append(weakref(old))
	var started_us: int = Time.get_ticks_usec()
	await driver.key(KEY_SPACE)
	return await _arrive(next,started_us)

func _journey() -> bool:
	var started_us: int = Time.get_ticks_usec()
	if not check(root.get_node("SceneRouter").call("go_field_smart",StringName(MARKET)),"Only initial ordinary public default Market request"): return false
	if not await _arrive(fixed.legs[0],started_us): return false
	for index: int in range(5):
		var leg: Dictionary = fixed.legs[index]
		if not await _walk(leg): return false
		if index < 4 and not await _portal(leg,fixed.legs[index+1]): return false
	return check(reached_legs == 5,"Same-session Market-herbal-Market-study-Market, four real INPUT/Space transfers")

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began+180000
	folder = "res://build/luoyang_market_two_shops_20261021ao_qa01/journey_%d"%OS.get_process_id()
	if DirAccess.dir_exists_absolute(folder): printerr("AO_REPORT_EXISTS"); quit(2); return
	DirAccess.make_dir_recursive_absolute(folder)
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before = saves(); state_before = _state()
	var complete: bool = _preflight()
	if complete: complete = await _journey()
	if driver != null: driver.release(); driver = null
	if is_instance_valid(current_scene):
		var own: Node = current_scene; var weak: WeakRef = weakref(own)
		current_scene = null; own.queue_free(); field = null; scene = null; own = null
		await process_frame; await process_frame
		check(weak.get_ref() == null,"Own current Field naturally freed")
	var after: Dictionary = {}
	for path: String in source_before: after[path] = fact(path)
	var players_after: Dictionary = saves(); var state_after: Dictionary = _state()
	check(source_before == after,"All actually consumed fixed sources unchanged first/final")
	check(players_before.size() == 15 and players_before == players_after,"15save first/final unchanged; no slot writes")
	check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended") == true,"Checkpoint writes suspended throughout")
	check(state_before == state_after,"No quest/flag/reward/inventory mutation hidden by restoration")
	check(Time.get_ticks_msec() < deadline,"Original180s whole budget unchanged")
	var report_path: String = folder.path_join("result.json")
	if FileAccess.file_exists(report_path): printerr("AO_RESULT_EXISTS"); quit(2); return
	var report: Dictionary = {"scope":"AO_TWO_SHOPS_ONLY_FIVE_LEG_TRUE_INPUT_SPACE_NO_ESTATE_OR_TEN_ROOM_REPLAY","complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"budget_ms":180000,"arrival_ms":60000,"reached_legs":reached_legs,"native_queries":native_queries,"records":records,"pictures":pictures,"source_before":source_before,"source_after":after,"players_before":players_before,"players_after":players_after,"state_before":state_before,"state_after":state_after,"room_geometry_republication_or_four_city_collectors_retested":false,"mtime_precision":"Godot seconds String; Root independent guard covers exact UTC ticks"}
	var output: FileAccess = FileAccess.open(report_path,FileAccess.WRITE)
	if output == null: printerr("AO_RESULT_OPEN_FAIL"); quit(2); return
	output.store_string(JSON.stringify(report,"\t")); output.close()
	print(JSON.stringify({"report_path":report_path,"checks":checks,"failures":failures,"complete":report.complete}))
	quit(0 if report.complete else 1)




