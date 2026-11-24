extends "res://tests/test_luoyang_ap_yamen_three_low_props_METRICS_PARENT_20261023.gd"
## Complete finite itinerary, but final owner/deployment pins are NOT frozen.
## Parent contributes only documented read-only clock/capture primitives.
const FINAL_OWNER_READY: bool = false
const FINAL_PLAN: String = "res://build/luoyang_city_full_rollout_20261022ap_qa01/yamen_expression_stage_trace_fixture_CANDIDATE_NOTREADY.json"
const FINAL_PLAN_SHA: String = "065940d353e3d525503610d54b3b102c6e7b9452055dd0323055cd8fecec05af"
const SIZE: Vector2 = Vector2(3072, 2048)
const SOURCE_TRANSFORM := preload("res://tests/helpers/yamen_low_props_source_expression_oracle_PREPARATION_ONLY_20261023.gd")
const ENDPOINT_TOLERANCE: float = .3 # Original driver endpoint, not geometry epsilon.
const SOURCE_CONNECTORS: String = "res://build/luoyang_city_full_rollout_20261022ap_qa01/yamen_local_connectors_source_only_EXPECTATIONS_NOT_RUNTIME_READY.json"
const SOURCE_CONNECTORS_SHA: String = "6f5cf1fa7ef0cf3f2efa509a46fa6bc50f4d429d49e3f3c131609580c8f682d8"
var connectors: Dictionary = {}
var own_output: String = ""
var gameplay_before: Dictionary = {}
var actual_mask: Image
var actual_queries: int = 0
var actual_mask_samples: int = 0
var prop_nodes: Dictionary = {}
var prop_bodies: Dictionary = {}
var npc_initial: Dictionary = {}
var source_author_rows: Dictionary = {}
var trace_signature: String = ""
var stage_trace_events: int = 0
var prior_observe_usec: int = 0
var max_observe_wall_gap_usec: int = 0

func _observe_readonly() -> void:
	super._observe_readonly()
	if requested_usec <= 0: return
	var now_usec: int = Time.get_ticks_usec()
	var gap_usec: int = now_usec - prior_observe_usec if prior_observe_usec > 0 else 0
	prior_observe_usec = now_usec
	max_observe_wall_gap_usec = maxi(max_observe_wall_gap_usec,gap_usec)
	if stage_trace_events >= 96: return
	var router: Node = root.get_node("SceneRouter")
	var public_state: Dictionary = router.call("get_public_city_preparation_state")
	if public_state.get("scene_id") != String(YAMEN): return
	var profile: Dictionary = C.transition_validation_state()
	var live_owner: int = int(router.call("live_field_transition_token",YAMEN))
	var same_owner: bool = live_owner > 0 and profile.get("active") == true and profile.get("live_scope") == true and profile.get("scene_id") == String(YAMEN) and profile.get("token") == live_owner
	var field_state: Dictionary = {}
	var field_instance: int = 0
	if is_instance_valid(current_scene) and current_scene.has_method("get_field_loading_state"):
		field_state = current_scene.call("get_field_loading_state")
		field_instance = current_scene.get_instance_id()
	var scalar_profile: Dictionary = {"same_current_owner":same_owner,"live_owner":live_owner,"active":profile.get("active"),"live_scope":profile.get("live_scope"),"scene_id":profile.get("scene_id"),"token":profile.get("token"),"source_worker_active":profile.get("source_worker_active"),"sources_finalized":profile.get("sources_finalized")}
	var signature: String = JSON.stringify([public_state.get("request_generation"),public_state.get("token"),public_state.get("phase"),field_instance,field_state.get("scene_id"),field_state.get("stage"),field_state.get("complete"),field_state.get("failed"),scalar_profile])
	if signature == trace_signature: return
	trace_signature = signature; stage_trace_events += 1
	var clock: Dictionary = _clock_fact()
	clock["elapsed_usec"] = int(clock.usec) - requested_usec
	records.append({"kind":"READONLY_STAGE_CHANGE_CLOCK","clock":clock,"public":public_state.duplicate(true),"Field_instance":field_instance,"Field_loading_state":field_state.duplicate(true),"C_current_scalars":scalar_profile,"previous_observe_wall_gap_usec":gap_usec,"max_observe_wall_gap_usec":max_observe_wall_gap_usec,"no_extra_yield_or_worker":true})

func _point(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(value[0], value[1])

func _gameplay_readonly() -> Dictionary:
	var gs: Node = root.get_node("GameState")
	return {"flags": gs.get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict").duplicate(true), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true), "gold": gs.get("gold"), "reputation": gs.get("reputation")}

func precheck() -> bool:
	if not check(FINAL_OWNER_READY, "NOTREADY: independent final owner/actual deployment not pinned"): return false
	if not track(FINAL_PLAN, FINAL_PLAN_SHA) or not track(SOURCE_CONNECTORS, SOURCE_CONNECTORS_SHA): return false
	contract = JSON.parse_string(FileAccess.get_file_as_string(FINAL_PLAN))
	connectors = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_CONNECTORS))
	if not check(contract.get("ready") == true and contract.get("whole_ms") == WHOLE_MS and contract.get("arrival_ms") == ARRIVAL_MS and contract.get("max_pictures") == 2, "Frozen sole default-entry sixty-second scope"): return false
	if not check(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0, "Ordinary GUI/no candidate flags/native clock"): return false
	if not check(contract.get("input_endpoint_tolerance_px") == ENDPOINT_TOLERANCE and contract.get("source_connectors_sha256") == SOURCE_CONNECTORS_SHA, "Original .3 input endpoint; fixed seven source attempts"): return false
	if not check(not contract.expected_city_source_sha256.is_empty() and contract.props.size() == 3 and contract.npc_rows.size() == 6 and contract.get("mask_whiteness_preclaimed") == false, "Complete independent owner / exact finite identities; mask gap preserved"): return false
	var author: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(contract.source_transform_author.path))
	for authored: Dictionary in author.Yamen.independent_new_visuals:
		if not check(not source_author_rows.has(authored.id), "Unique independent author prop row"): return false
		source_author_rows[authored.id] = authored.duplicate(true)
	if not check(source_author_rows.size() == 3, "Only frozen three source-expression rows"): return false
	for path: String in contract.source_sha256:
		if not track(path, contract.source_sha256[path]): return false
	for path: String in contract.expected_city_source_sha256:
		if not check(contract.source_sha256.get(path) == contract.expected_city_source_sha256[path], "QA protects each fixed city source, never an observed map"): return false
	return true

func _actual_body_query(at: Vector2) -> Array[Dictionary]:
	if not is_instance_valid(own_player) or not is_instance_valid(own_field): return [{"invalid_player": true}]
	var shape: CollisionShape2D = own_player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not shape.shape is RectangleShape2D or shape.position != Vector2.ZERO or (shape.shape as RectangleShape2D).size != Vector2(34, 24) or shape.disabled: return [{"invalid_original34x24": true}]
	var world: Node2D = own_field.get("world_container") as Node2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape; query.transform = shape.global_transform
	query.transform.origin += world.to_global(at) - own_player.global_position
	query.collision_mask = own_player.collision_mask; query.exclude = [own_player.get_rid()]; query.collide_with_areas = false
	actual_queries += 1
	return own_player.get_world_2d().direct_space_state.intersect_shape(query, 16)

func _finite_actual_clear(foot: Vector2) -> bool:
	if Time.get_ticks_msec() >= deadline or own_field != current_scene or not foot.is_finite() or actual_mask == null: return false
	# Seventeen observations of the already-loaded exact native mask, not a
	# source-white proof, image decode or rerun of875/1085/old planned routes.
	var offsets: Array[Vector2] = [Vector2.ZERO, Vector2(-17,-12), Vector2(17,-12), Vector2(17,12), Vector2(-17,12), Vector2(-17,0), Vector2(17,0), Vector2(0,-12), Vector2(0,12), Vector2(-17,-6), Vector2(-17,6), Vector2(17,-6), Vector2(17,6), Vector2(-8,-12), Vector2(8,-12), Vector2(-8,12), Vector2(8,12)]
	for offset: Vector2 in offsets:
		var pixel: Vector2i = Vector2i(foot.round() + offset)
		actual_mask_samples += 1
		if pixel.x < 0 or pixel.y < 0 or pixel.x >= actual_mask.get_width() or pixel.y >= actual_mask.get_height() or actual_mask.get_pixelv(pixel) != Color.WHITE: return false
	return _actual_body_query(foot).is_empty()

func _drive_to(point: Vector2, label: String) -> bool:
	var result: Dictionary = await input_driver.drive(own_field, point, _finite_actual_clear)
	if first_input_fact.is_empty():
		first_input_fact = _clock_fact(); first_input_fact["elapsed_usec"] = int(first_input_fact.usec) - requested_usec
	records.append({"kind": "FINITE_NORMAL_INPUT", "label": label, "result": result, "endpoint_tolerance_px": ENDPOINT_TOLERANCE, "mask_scope": "ACTUAL17_NOT_SOURCE875"})
	return check(result.get("ok") == true and own_player.position.distance_to(point) <= ENDPOINT_TOLERANCE, "Fixed endpoint reached with original body; do not choose another station " + label, result)

func _fixed_points(raw: Array, label: String) -> bool:
	for index: int in raw.size():
		if not await _drive_to(_point(raw[index]), label + ":" + str(index)): return false
	return true

func _connector(id: String, backwards: bool = false) -> bool:
	var found: Array[Dictionary] = []
	for row: Dictionary in connectors.connections:
		if row.id == id: found.append(row)
	if not check(found.size() == 1, "Exactly fixed source connector " + id): return false
	var points: Array = found[0].points.duplicate(true)
	if backwards: points.reverse()
	if not check(own_player.position.distance_to(_point(points[0])) <= ENDPOINT_TOLERANCE, "No teleport/implicit unproved connector " + id): return false
	return await _fixed_points(points.slice(1), id)

func _post_natural_owner() -> bool:
	var proof: Dictionary = C._resident_ready # Read only; no resident_receipt/collector/validator.
	if not check(proof.get("scene") == own_scene and proof.get("id") == YAMEN and int(proof.get("token", 0)) > 0 and proof.get("sources_finalized") == true and proof.get("proof_kind") == "PRECOMPUTED_PUBLISHED_FULL_SOURCE_V1", "Naturally finalized exact Yamen owner"): return false
	if not check(C._equal_value(proof.get("sources"), contract.expected_city_source_sha256), "Complete independent source-first/final owner set/every SHA, no new collector"): return false
	if not check(own_scene.resource_path == contract.scene_path and own_scene.map_layout.resource_path == contract.layout_path and _point(own_field.get("_world_size")) == SIZE and own_scene.actor_positions_are_feet, "Actual exact native Scene/layout/world/body basis"): return false
	actual_mask = own_field.get("_walkable_mask_image") as Image
	if not check(actual_mask != null and actual_mask.get_size() == Vector2i(3072,2048), "Existing imported Field native mask, no image load or decode"): return false
	# Field owns Texture2D.get_image(); C owns packet Image.create_from_data.
	# They are distinct Image objects. Compare exact frozen RGBA, not identity.
	var rgba_readback: Image = actual_mask.duplicate()
	rgba_readback.convert(Image.FORMAT_RGBA8)
	if not check(C._transition_bytes_sha(rgba_readback.get_data()) == contract.mask_RGBA_sha256, "Installed Field mask exact independent frozen RGBA; no new raster generation"): return false
	rgba_readback = null
	if not check(own_player.position.distance_to(_point(contract.default_spawn_px)) <= ENDPOINT_TOLERANCE and _finite_actual_clear(own_player.position), "True default production foot, not legal-near setup"): return false
	for row: Dictionary in contract.props:
		var sprites: Array[Sprite2D] = []; var bodies: Array[StaticBody2D] = []
		for sprite: Sprite2D in own_field.get("_scene_object_nodes"):
			if sprite.name == "SceneObject_" + String(row.id): sprites.append(sprite)
		for body: StaticBody2D in own_field.get("_collision_bodies"):
			if body.name == "CityV3Physical_" + String(row.id): bodies.append(body)
		if not check(sprites.size() == 1 and bodies.size() == 1, "One exact native sprite/body, no duplicated District prop " + row.id): return false
		var sprite: Sprite2D = sprites[0]
		var expected_transform: Dictionary = SOURCE_TRANSFORM.expected_sprite(source_author_rows[String(row.id)])
		var actual_transform: Dictionary = {"texture_path":sprite.texture.resource_path,"texture_size":sprite.texture.get_size(),"native_scale":sprite.scale,"field_position":sprite.position}
		records.append({"kind":"EXACT_NATIVE_TRANSFORM_ACTUAL_AND_INDEPENDENT_SOURCE_EXPRESSION","id":row.id,"actual":actual_transform,"expected":expected_transform.duplicate(true),"expected_not_from_actual":true})
		if not check(not expected_transform.is_empty(), "Exact frozen-author native expression exists " + row.id): return false
		if not check(sprite.texture.resource_path == expected_transform.texture_path and row.texture_path == expected_transform.texture_path, "Exact original texture path " + row.id, actual_transform): return false
		if not check(sprite.texture.get_size() == expected_transform.texture_size, "Exact full original canvas size " + row.id, actual_transform): return false
		if not check(sprite.scale == expected_transform.native_scale, "Exact source-expression native scale, no epsilon " + row.id, {"actual":actual_transform,"expected":expected_transform}): return false
		if not check(sprite.position == expected_transform.field_position, "Exact source-expression normalized Field position " + row.id, {"actual":actual_transform,"expected":expected_transform}): return false
		var polys: Array[CollisionPolygon2D] = []
		for child: Node in bodies[0].get_children():
			if child is CollisionPolygon2D: polys.append(child)
		var expected := PackedVector2Array()
		for point: Variant in row.source_polygon_px: expected.append(_point(point))
		if not check(polys.size() == 1 and not polys[0].disabled and polys[0].polygon == expected and bodies[0].position == Vector2.ZERO, "Actual exact source native polygon " + row.id): return false
		prop_nodes[row.id] = sprite; prop_bodies[row.id] = bodies[0]
	records.append({"kind": "NATURAL_SOURCE_FINAL_OWNER", "token": proof.token, "sources": proof.sources.duplicate(true), "scene_instance": own_scene.get_instance_id(), "layout_instance": own_scene.map_layout.get_instance_id(), "full8751085_not_replayed": true})
	return _six_npcs_readonly(true)

func _six_npcs_readonly(first: bool) -> bool:
	var observed: Array[Dictionary] = []
	for row: Dictionary in contract.npc_rows:
		var found: Array[Node] = []
		for node: Node in own_field.get("_npc_nodes"):
			if node.get("npc_id") == row.id: found.append(node)
		if not check(found.size() == 1, "One ordinary existing DG actor " + row.id): return false
		var actor: Node = found[0]
		if not check(actor.get("movement_mode") == row.movement_mode and actor.get("patrol_axis") == _point(row.axis) and actor.get("patrol_distance") == row.distance and actor.get("patrol_speed") == row.speed and actor.get("_patrol_origin") == _point(row.origin_px), "Full original lane configuration, no forced phase " + row.id): return false
		if first: npc_initial[row.id] = actor.get_instance_id()
		elif not check(npc_initial.get(row.id) == actor.get_instance_id(), "Same naturally running NPC instance " + row.id): return false
		observed.append({"id": row.id, "instance": actor.get_instance_id(), "position": actor.get("position"), "origin": actor.get("_patrol_origin"), "mode": actor.get("movement_mode"), "distance": actor.get("patrol_distance"), "speed": actor.get("patrol_speed")})
	records.append({"kind": "SIX_DG_CONFIG_ONLY_NOT_ENTIRE_PATROL_PERIOD", "initial": first, "rows": observed})
	return true

func _opaque_and_local(prop_id: String, expect_hit: bool) -> bool:
	await input_driver.completed_actor_stage() # Normal late refresh only.
	var fact: Dictionary = _ghost_and_opacity_readonly(prop_nodes[prop_id], prop_id)
	for row: Dictionary in fact.prop_alpha_chain:
		if not check(row.modulate_alpha == 1.0 and row.self_modulate_alpha == 1.0, "Prop/ancestor modulation remains opaque " + prop_id, row): return false
	if not check(prop_id not in fact.fade_ids and fact.actor_base_alpha == 1.0, "Object not faded/base actor not globally dimmed " + prop_id, fact): return false
	var hits: Dictionary = fact.get("prop_hits", {})
	if expect_hit:
		if not check(fact.get("active") == true and fact.get("space") == "actor_frame" and int(fact.get("pixels", 0)) > 0 and int(hits.get(prop_id, 0)) > 0 and fact.ghost_visible and fact.ghost_material_present, "Exact behind actor-frame local ghost, object intact " + prop_id, fact): return false
	elif not check(int(hits.get(prop_id, 0)) == 0, "Leaving this overlap clears this exact prop mask " + prop_id, fact): return false
	records.append({"kind": "ACTUAL_PROP_ACTOR_LOCAL_STATE", "expected_target_hit": expect_hit, "fact": fact})
	return true

func _attempt_north_front(prop_id: String, forbidden_foot: Vector2) -> bool:
	var negative: Array[Dictionary] = _actual_body_query(forbidden_foot)
	if not check(not negative.is_empty(), "Target inside-body negative control " + prop_id): return false
	for hit: Dictionary in negative:
		if not check(hit.get("collider") == prop_bodies[prop_id], "Negative hits only exact intended native prop " + prop_id): return false
	var pixel: Vector2i = Vector2i(forbidden_foot)
	if not check(actual_mask.get_pixelv(pixel) == Color.BLACK, "Known source-negative cell is blocked in installed native mask " + prop_id): return false
	var before: Vector2 = own_player.position
	var samples: Array[Vector2] = []
	Input.action_press("move_up")
	for tick: int in 24:
		await physics_frame
		if not is_instance_valid(own_player) or Time.get_ticks_msec() >= deadline: break
		samples.append(own_player.position)
		if not _finite_actual_clear(own_player.position): input_driver.release_movement(); return check(false, "Actual stopped body never enters native footprint " + prop_id)
	input_driver.release_movement(); await input_driver.completed_actor_stage()
	if not check(not samples.is_empty() and own_player.position.y < before.y and own_player.position.y > forbidden_foot.y and absf(own_player.position.x - before.x) <= ENDPOINT_TOLERANCE and (samples[-1] - samples[maxi(0,samples.size()-4)]).length() <= ENDPOINT_TOLERANCE, "Bounded real front-input stops above intended prop; no reach-through " + prop_id, {"before": before, "after": own_player.position, "samples": samples}): return false
	records.append({"kind": "ACTUAL_FRONT_BLOCK_AND_EXACT_NEGATIVE", "id": prop_id, "start": before, "end": own_player.position, "observed_feet": samples, "negative_collider_instance": prop_bodies[prop_id].get_instance_id()})
	return true

func _return_front(point: Vector2, label: String) -> bool:
	return await _drive_to(point, label)

func exercise_cpu() -> bool:
	# The inherited name is historical; this performs no CPU geometry/collector.
	if not await _request_default_yamen() or not _post_natural_owner(): return false
	if not await _fixed_points([[1536,1530],[1300,1530],[1130,1530],[1130,1498]], "inherited_default_trunk_and_desk_front"): return false
	var desk: String = "ap_yamen_petition_writing_desk"
	if not await _opaque_and_local(desk, false) or not await _attempt_north_front(desk, Vector2(1130,1436)) or not await _return_front(Vector2(1130,1498), "desk_original_front_restore"): return false
	if not await _connector("desk_front_to_east_bypass") or not await _connector("desk_east_to_behind") or not await _opaque_and_local(desk, true): return false
	if not await _capture_representative("desk_behind_actor_local"): return false
	if not await _connector("desk_behind_to_south_bench_front") or not await _opaque_and_local(desk, false): return false
	var south: String = "ap_yamen_waiting_bench_south"
	if not await _opaque_and_local(south, false) or not await _attempt_north_front(south, Vector2(1140,1284)) or not await _return_front(Vector2(1140,1330), "south_original_front_restore"): return false
	if not await _connector("south_bench_front_around_east_to_behind") or not await _opaque_and_local(south, true): return false
	if not await _connector("south_behind_to_north_bench_front") or not await _opaque_and_local(south, false): return false
	var north: String = "ap_yamen_waiting_bench_north"
	if not await _opaque_and_local(north, false) or not await _capture_representative("bench_front_opaque") or not await _attempt_north_front(north, Vector2(1140,1154)) or not await _return_front(Vector2(1140,1200), "north_original_front_restore"): return false
	if not await _connector("north_bench_front_around_east_to_behind") or not await _opaque_and_local(north, true): return false
	if not await _connector("north_bench_back_to_front_restore") or not await _opaque_and_local(north, false): return false
	# Reverse already-frozen constituent segments; do not invent an exit portal.
	if not await _fixed_points([[1232,1200],[1232,1246],[1232,1330],[1232,1394],[1300,1394]], "fixed_constituents_outside_all_three"): return false
	var final_overlap: Dictionary = _ghost_and_opacity_readonly(prop_nodes[desk], desk)
	if not check(final_overlap.get("active") == false and not final_overlap.ghost_visible and final_overlap.actor_base_alpha == 1.0, "Outside all three restores ordinary actor; no forced refresh", final_overlap): return false
	if not _six_npcs_readonly(false) or not check(_gameplay_readonly() == gameplay_before, "No quest/dialogue/reward/flag/inventory change"): return false
	var proof: Dictionary = C._resident_ready
	return check(proof.get("scene") == own_scene and proof.get("sources_finalized") == true and C._equal_value(proof.get("sources"), contract.expected_city_source_sha256), "Same naturally finalized source owner at finite end")

func _cleanup_own() -> bool:
	if input_driver != null: input_driver.release(); input_driver = null
	var weak: WeakRef = null
	if is_instance_valid(own_field):
		weak = weakref(own_field); current_scene = null; own_field.queue_free()
		own_field = null; own_scene = null; own_player = null
	prop_nodes.clear(); prop_bodies.clear(); actual_mask = null
	root.get_node("SceneRouter").call("reset_for_new_game")
	await process_frame; await process_frame
	return check(weak == null or weak.get_ref() == null, "Only own Field/validation cleanup; no second travel")

func _run() -> void:
	var began: int = Time.get_ticks_msec(); deadline = began + WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true); players_before = saves()
	own_output = "res://build/luoyang_city_full_rollout_20261022ap_qa01/yamen_three_low_props_expression_stage_trace_candidate/%d_%d" % [OS.get_process_id(), began]
	DirAccess.make_dir_recursive_absolute(own_output)
	var complete: bool = false
	if precheck():
		contract["output_path"] = own_output
		input_driver = INPUT.new(); input_driver.configure(self)
		RenderingServer.frame_post_draw.connect(_post_draw_readonly)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		root.get_node("GameState").set("current_chapter",4)
		gameplay_before = _gameplay_readonly()
		complete = await exercise_cpu()
	if RenderingServer.frame_post_draw.is_connected(_post_draw_readonly): RenderingServer.frame_post_draw.disconnect(_post_draw_readonly)
	if not await _cleanup_own(): complete = false
	records.append({"kind":"SINGLE_YAMEN_FINITE_SCOPE","whole_ms":WHOLE_MS,"arrival_cap_in_whole_ms":ARRIVAL_MS,"ready":ready_fact,"firstdraw":draw_fact,"first_actual_input":first_input_fact,"last_matching_profile":last_matching_profile,"pictures":pictures,"Physics_queries_actual":actual_queries,"native_mask_observations_actual":actual_mask_samples,"stage_trace_events":stage_trace_events,"max_original_observe_wall_gap_usec":max_observe_wall_gap_usec,"mask_independent_prior_white_claim":false,"other_city_room_or_collector_calls":0})
	finish(own_output,began,complete,"ONE_DEFAULT_YAMEN_THREE_LOW_PROPS_60S_NOT_WHOLE_CITY")
