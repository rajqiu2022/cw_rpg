extends "res://tests/test_world_map_v14_production_20261002.gd"

## Actual original 75F6 missing stations only. No FULL category credits.
## Root alone runs this serialized fixture after reading its immutable source.
const ORIGINAL_MISSING := [
	["wudang_landmark", false],
	["native_ridge_base_0", false], ["native_ridge_base_1", false],
	["native_ridge_base_2", false], ["native_ridge_base_3", false],
	["native_ridge_base_4", false], ["native_ridge_base_5", false],
	["native_ridge_base_6", false], ["native_ridge_base_7", false],
	["native_rock_west", false],
	["native_ridge_face_west_volume_main", true],
	["native_ridge_face_west_volume_talus_left", false],
	["native_ridge_face_west_volume_talus_right", true],
	["native_ridge_face_near_volume_main", false],
	["native_ridge_face_near_volume_main", true],
	["native_ridge_face_near_volume_talus_left", false],
	["native_ridge_face_near_volume_talus_left", true],
	["native_ridge_face_near_volume_talus_right", false],
	["native_ridge_face_crest_volume_main", true],
	["native_ridge_face_crest_volume_talus_left", false],
	["native_ridge_face_crest_volume_talus_left", true],
	["native_ridge_face_crest_volume_talus_right", true],
	["native_ridge_face_east_volume_main", true],
	["native_ridge_face_east_volume_talus_left", false],
	["native_ridge_face_east_volume_talus_left", true],
	["native_ridge_face_pine_volume_main", true],
	["native_ridge_face_pine_volume_talus_left", false],
	["native_pass_face_volume_talus_left", false],
	["native_pine_09", false], ["native_pine_18", true],
	["native_tree_019", true], ["native_tree_047", true],
	["native_tree_081", true], ["native_tree_097", true],
	["native_tree_100", true],
]

func _initialize() -> void:
	call_deferred("_run_original35")

func _run_original35() -> void:
	qa_scope = "FOCUSED_ORIGINAL35_CURRENT_ALPHA_NOT_FULL_WORLD"
	candidate_stage = true
	active_id = CANDIDATE_ID
	active_path = CANDIDATE_PATH
	phase_output = OUTPUT_DIR + "original35_alpha_" + str(int(Time.get_unix_time_from_system())) + "/"
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(phase_output)) == OK, "unique focused evidence directory")
	player_saves_before = _actual_player_saves()
	prior_navigation = root.get_node("SceneRouter").call("get_navigation_state").duplicate(true)
	manifest = _json(MANIFEST_PATH)
	source_contract = _json(SOURCE_PATH)
	_check(DisplayServer.get_name() == "headless", "root-authorized source fixture is headless only, no unapproved GPU")
	_check(int(manifest.get("capture_iteration", -1)) == 9 and _ninth_compiler_precondition(manifest.get("native_shader_compiler_gate", [])) and String(manifest.get("status", "")) == "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA" and String(source_contract.get("status", "")) == "ART_ASSETS_READY", "current completed candidate capture required; no partial Field")
	if failed > 0 or not _asset_binding_checks():
		_finish()
		return
	# Same actual saved-geometry prerequisites as FULL, before added-white
	# pixels can be classified. Do not replace structural alpha with rectangles.
	_terrain_capture_geometry_checks()
	_structure_saved_mesh_checks()
	_raw_pixel_and_crop_checks()
	_check(raw_walk_tiles_exact, "all nine actual raw navigation crops equal current original full mask before continuous proof")
	if not raw_walk_tiles_exact:
		_finish()
		return
	schema_ready = true
	_prepare_isolated_slots()
	_fixture_new_game()
	if not await _open_world(world.player_spawn):
		_finish()
		return
	_collect_runtime()
	_check(ORIGINAL_MISSING.size() == 35, "exact original 75F6 missing station cases preserved")
	var records: Array[Dictionary] = []
	for original: Array in ORIGINAL_MISSING:
		var id := String(original[0])
		var front := bool(original[1])
		var object: Dictionary = {}
		for entry: Dictionary in world.map_layout.visual_objects:
			if String(entry.get("id", "")) == id: object = entry; break
		_check(not object.is_empty() and runtime_props.has(id), "actual original failed entity exists: " + id)
		if object.is_empty() or not runtime_props.has(id): continue
		var prop: Sprite2D = runtime_props[id]
		var station := _prop_alpha_station(object, prop, front)
		var classification: Dictionary = {"status": "POSITIVE" if not station.is_empty() else "INCONCLUSIVE", "method": "original_coarse_with_actual_halfplane_and_physics", "station": station}
		if station.is_empty():
			classification = _complete_alpha_station(object, prop, front)
			if classification.get("status") == "POSITIVE": station = classification.get("station", {})
		classification["id"] = id
		classification["front"] = front
		classification["source_prop_path"] = prop.texture.resource_path
		classification["source_prop_sha256"] = FileAccess.get_sha256(prop.texture.resource_path)
		if not station.is_empty():
			var player: Node2D = field.get("_player")
			player.position = station.point
			_set_idle(station.facing)
			var actor: Sprite2D = player.get("sprite")
			var identity := "%s:%s:frame%d" % [actor.texture.resource_path, str(station.facing), actor.frame]
			classification["live_evidence"] = _station_live_evidence(object, prop, station.point, station.facing, front, identity)
		if not _checked_alpha_json(phase_output + "resolution_" + id + ("_front" if front else "_behind") + ".json", classification): classification["status"] = "INCONCLUSIVE"
		if classification.get("status") == "POSITIVE" and not station.is_empty():
			_check(await _place_fixture(station.point), "focused real station settles with full17 and ordinary physics: " + id)
			_set_idle(station.facing)
			await _completed_normal_actor_stage()
			var player: Node2D = field.get("_player")
			var hits := _actual_actor_alpha_intersection(prop)
			_check(_foot_clear(player.position) and _planning_collisions(player.position).is_empty() and hits > 0 and _candidate_actual_foot_relation(player, object, front), "focused actual current .12 alpha/full17/physics/real-side positive: " + id)
			_check(_depth_order(player, prop, front), "focused actual normal-stage Y/sibling order: " + id)
			classification["observed_hits_after_normal_stage"] = hits
			classification["observed_actor_z"] = player.z_index
			classification["observed_prop_z"] = prop.z_index
			await _ghost_mask_check(id + " original35 focused positive", false)
		elif classification.get("status") == "DENIED":
			var directions: Array = classification.get("records", [])
			var complete := directions.size() == 4
			for direction: Dictionary in directions: complete = complete and direction.get("status") == "DENIED" and direction.get("denied") == true and int(direction.get("unresolved_box_count", -1)) == 0 and direction.get("threshold") == .12
			_check(complete, "focused four-direction continuous proof has no unresolved boxes: " + id)
			if complete: await _denied_alpha_boundary_check(object, prop, front)
		else:
			_check(false, "original missing station remains unresolved, no absence waiver: " + id)
		records.append(classification)
		print("[Original35Alpha] id=%s front=%s status=%s method=%s" % [id, front, classification.get("status"), classification.get("method", "continuous_interval")])
	_check(records.size() == 35, "all exact original missing cases actually evaluated")
	_check(ghost_positive == 0 and ghost_south_positive == 0, "focused classifications grant no FULL-map strong/ghost category credits")
	_checked_alpha_json(phase_output + "original35_evidence.json", {"cases": records, "coverage": "original35 current idle-frame0 station diagnostics, NOT full-map/visual/canonical acceptance"})
	_finish()
