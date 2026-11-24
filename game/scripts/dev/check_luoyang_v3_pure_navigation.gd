extends SceneTree
## SOURCE/SYNTHETIC ONLY. No authored art/Field/physics/input/rewards tested.
const C = preload("res://scripts/city/luoyang_layered_v3_contract.gd")
var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _expect(condition: bool, description: String) -> void:
	checks += 1
	if not condition: failures.append(description)

func _run() -> void:
	var router: Node = root.get_node_or_null("SceneRouter")
	if router == null: push_error("Autoload context required"); quit(1); return
	var navigation: Dictionary = router.get_navigation_state().duplicate(true)
	var saved_records: Dictionary = C._records.duplicate()
	var saved_masks: Dictionary = C._masks.duplicate()
	var saved_solids: Dictionary = C._solids.duplicate()
	var saved_errors: Array[String] = C.errors()
	var id := &"ch4_s0_luoyang_gate"
	var legacy: SceneScript = C.legacy_scene(id)
	_expect(legacy != null, "Immutable legacy source available")
	if legacy != null:
		_expect(C.semantic_fidelity(legacy), "Untouched original semantics accepted")
		var changed: SceneScript = C._independent_copy(legacy) as SceneScript
		changed.npcs[0]["dialog_id"] = "fabricated_dialog"
		_expect(not C.semantic_fidelity(changed), "Changed NPC dialogue identity rejected")
		changed = C._independent_copy(legacy) as SceneScript
		changed.map_layout.portals[0]["target_scene"] = "fabricated_destination"
		_expect(not C.semantic_fidelity(changed), "Changed portal target rejected")
		_expect(C.semantic_fidelity(legacy), "Rejected clone did not change original")
		var image := Image.create(3072, 2048, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		C._masks[String(id)] = image
		C._solids[String(id)] = []
		C._records[String(id)] = _identity_fixture(legacy)
		_expect(C.safe_body(id, Vector2(100, 100)), "Synthetic complete ordinary body accepted")
		_expect(not C.safe_body(id, Vector2(3072 - 17.4, 100)), "Rounded last-pixel endpoint rejected before get_pixel")
		_expect(not C.safe_body(id, Vector2(100, 2048 - 12.4)), "Rounded last-row endpoint rejected before get_pixel")
		for free: Vector2 in [Vector2(.18, .55), Vector2(.78, .53), Vector2(.24, .66)]:
			var first: Dictionary = C.migrate_spawn_report(id, free, 1)
			_expect(not first.is_empty(), "Synthetic old free position resolves")
			if not first.is_empty():
				_expect(first.reason == "same_district_semantic_interpolation" and first.spawn.distance_to(free) < .00001, "Identity geography preserves free point rather than teleporting to doorway")
				var repeated: Dictionary = C.migrate_spawn_report(id, first.spawn, 3)
				_expect(not repeated.is_empty() and repeated.spawn == first.spawn and repeated.reason == "same_version_local_clearance", "Already-v3 repeat does not remap")
		var invalid: Dictionary = C.migrate_spawn_report(id, Vector2(.5, .5), 99)
		_expect(invalid.is_empty(), "Unknown source local version rejected")
		var incoming: Dictionary = C.migrate_spawn_report(id, Vector2(.9, .1), 1, &"world_map_jianghu_v15")
		_expect(not incoming.is_empty() and incoming.spawn == legacy.player_spawn and incoming.reason == "authored_world_city_entry", "World incoming uses exact city entry, not old roof coordinate")
		image.fill(Color.BLACK)
		var portal: Dictionary = legacy.map_layout.portals[0]
		var safe: Vector2 = portal.pos * C.SIZE
		for y in range(roundi(safe.y - 12), roundi(safe.y + 12) + 1):
			for x in range(roundi(safe.x - 17), roundi(safe.x + 17) + 1): image.set_pixel(x, y, Color.WHITE)
		var fallback: Dictionary = C.migrate_spawn_report(id, Vector2(.18, .55), 1)
		_expect(not fallback.is_empty() and fallback.reason == "same_district_author_anchor_fallback" and fallback.anchor_id == String(portal.id), "Old-only fallback explicitly retains same-district semantic anchor")
		_expect(C.migrate_spawn_report(id, Vector2(.18, .55), 3).is_empty(), "Unrepairable new city coordinate cannot teleport to portal")
		image.fill(Color.BLACK)
		_expect(C.migrate_spawn_report(id, Vector2(.18, .55), 1).is_empty(), "No complete safe fallback foot refuses old migration")
	_expect(not C.versions_supported({"local_layout_versions": {String(id): 99}}, {String(id): 3}), "Unknown saved local version rejected")
	_expect(not C.versions_supported({"local_layout_versions": {String(id): 3}}, {String(id): 1}), "Saved3 to old1 downgrade refused")
	_expect(not C.versions_supported({"local_layout_versions": {"unknown_city": 1}}, {}), "Unknown local version key refused")
	_expect(not C.versions_supported({"local_layout_versions": {String(id): 1.5}}, {}), "Nonintegral local version refused without truncation")
	var decoded: Variant = JSON.parse_string(JSON.stringify({"local_layout_versions": {String(id): 1}}))
	_expect(decoded is Dictionary and C.versions_supported(decoded, {String(id): 1}), "Exact supported version survives real JSON float decoding")
	_expect(not router.navigation_coordinate_version_supported({"world_map_version": 14, "local_layout_versions": {String(id): 99}}, router.WORLD_MAP_SCENE), "Router preparse rejects unknown local version")
	for bad: Variant in [14.5, "14", true, 99, INF, NAN]:
		_expect(router._saved_world_coordinate_version({"world_map_version": bad}) == -1, "Exact world version rejects coercible/unknown value " + str(bad))
		_expect(not router.navigation_coordinate_version_supported({"world_map_version": bad}, router.WORLD_MAP_SCENE), "Bad world version preparse refuses before state application")
		_expect(router.prepare_v15_navigation({"world_map_version": bad}, &"", router.WORLD_MAP_V15_SCENE).is_empty(), "Bad world version pure v15 preparation refuses before art resolution")
		var bad_payload: Dictionary = router.get_field_payload().duplicate(true)
		router.restore_navigation_state({"world_map_version": bad}, &"ch1_s1_road")
		_expect(router.get_navigation_state() == navigation and router.get_field_payload() == bad_payload, "Bad world restore cannot mutate navigation/payload")
	var world_decoded: Variant = JSON.parse_string("{\"world_map_version\":14}")
	_expect(world_decoded is Dictionary and router._saved_world_coordinate_version(world_decoded) == 14, "JSON exact world integer float remains supported")
	for supported in [12, 13, 14, 15]: _expect(router._saved_world_coordinate_version({"world_map_version": float(supported)}) == supported, "Exact supported world identity " + str(supported))
	_expect(router.get_navigation_state() == navigation, "All pure checks left Router navigation unchanged")
	if "--luoyang-v3-candidate" in OS.get_cmdline_user_args() and not C._hash(C.MANIFEST_SHAS[String(id)]):
		var payload: Dictionary = router.get_field_payload().duplicate(true)
		var refused: Vector2 = router.resolve_portal_arrival(&"ch1_s1_road", id, Vector2(.25, .6), Vector2(.5, .9))
		_expect(not refused.is_finite(), "PENDING city public portal preparation refuses")
		_expect(router.get_navigation_state() == navigation and router.get_field_payload() == payload, "Failed public preparation records no paired return or version")
		router.go_field_from_portal(id, Vector2(.5, .9), Vector2(.25, .6))
		_expect(router.get_navigation_state() == navigation and router.get_field_payload() == payload, "PENDING city real portal dispatch leaves all navigation/payload unchanged")
		_expect(not router.go_field_smart(id, Vector2(.5, .9)), "PENDING direct smart dispatch reports refusal")
		_expect(router.get_navigation_state() == navigation and router.get_field_payload() == payload, "PENDING direct smart dispatch does not commit local/active/current state")
	C._records = saved_records
	C._masks = saved_masks
	C._solids = saved_solids
	C._errors = saved_errors
	for failure: String in failures: push_error(failure)
	print(JSON.stringify({"phase": "SOURCE_SYNTHETIC_CITY_NAVIGATION", "checks": checks, "failed": failures.size(), "failures": failures, "sha256": FileAccess.get_sha256("res://scripts/city/luoyang_layered_v3_contract.gd"), "actual_city_art_physics_input_gameplay": "NOT_RUN"}))
	# Return this stack (temporary cloned Resources + synthetic image) before
	# tree shutdown. Quitting inside the live probe stack obscures ownership.
	call_deferred("_finish")

func _finish() -> void:
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)

func _identity_fixture(legacy: SceneScript) -> Dictionary:
	var slots := {"npcs": [], "interactions": [], "portals": []}
	for npc: Dictionary in legacy.npcs: slots.npcs.append({"source_id": String(npc.npc_id), "foot_px": [npc.pos.x * C.SIZE.x, npc.pos.y * C.SIZE.y]})
	for interaction: Dictionary in legacy.map_layout.interactions: slots.interactions.append({"source_id": String(interaction.id), "stand_px": [interaction.pos.x * C.SIZE.x, interaction.pos.y * C.SIZE.y]})
	for portal: Dictionary in legacy.map_layout.portals: slots.portals.append({"source_id": String(portal.id), "arrival_foot_px": [portal.pos.x * C.SIZE.x, portal.pos.y * C.SIZE.y]})
	return {"gameplay_slots": slots, "entry_foot_px": [legacy.player_spawn.x * C.SIZE.x, legacy.player_spawn.y * C.SIZE.y], "routes": []}
