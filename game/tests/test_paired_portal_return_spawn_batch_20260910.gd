extends SceneTree

var _failures := 0
var _router: Node = null


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_router = root.get_node_or_null("SceneRouter")
	_expect(_router != null, "SceneRouter autoload is available")
	if _router == null:
		quit(_failures)
		return
	_test_master_room_returns_to_used_doorway()
	_test_multiple_house_routes_stay_independent()
	_test_all_reciprocal_portals_return_to_used_source()
	_test_navigation_state_round_trip()
	_test_save_contract()
	if _failures > 0:
		push_error("[Paired Portal Return Spawn Test] %d failure(s)" % _failures)
	quit(_failures)


func _test_master_room_returns_to_used_doorway() -> void:
	_router.call("reset_for_new_game")
	var courtyard_door := Vector2(0.302, 0.361)
	var indoor_authored := Vector2(0.500, 0.790)
	var entered: Vector2 = _router.call("resolve_portal_arrival",
		&"linxi_tutorial", &"linxi_master_hall", courtyard_door, indoor_authored
	)
	_expect_vec(entered, indoor_authored, "first entry still uses the authored indoor arrival")
	var returned: Vector2 = _router.call("resolve_portal_arrival",
		&"linxi_master_hall", &"linxi_tutorial", Vector2(0.500, 0.900), Vector2(0.300, 0.405)
	)
	_expect_vec(returned, courtyard_door, "master room exit returns to the exact courtyard doorway used")


func _test_multiple_house_routes_stay_independent() -> void:
	_router.call("reset_for_new_game")
	var herbal_door := Vector2(0.834, 0.874)
	var scholar_door := Vector2(0.455, 0.311)
	_router.call("resolve_portal_arrival", &"linxi_village_center", &"linxi_herbal_home", herbal_door, Vector2(0.5, 0.76))
	_router.call("resolve_portal_arrival", &"linxi_village_center", &"linxi_scholar_house", scholar_door, Vector2(0.5, 0.76))
	_expect_vec(
		_router.call("resolve_portal_arrival", &"linxi_herbal_home", &"linxi_village_center", Vector2(0.5, 0.845), Vector2(0.625, 0.710)),
		herbal_door,
		"herbalist house does not reuse another house's old target"
	)
	_expect_vec(
		_router.call("resolve_portal_arrival", &"linxi_scholar_house", &"linxi_village_center", Vector2(0.5, 0.845), Vector2(0.455, 0.335)),
		scholar_door,
		"scholar house keeps its own paired return doorway"
	)


func _test_all_reciprocal_portals_return_to_used_source() -> void:
	var checked := 0
	for file_name: String in DirAccess.get_files_at("res://data/scenes"):
		if not file_name.ends_with(".tres"):
			continue
		var source: Resource = load("res://data/scenes/%s" % file_name)
		if source == null:
			continue
		var source_id := StringName(source.get("scene_id"))
		if String(source_id).is_empty():
			continue
		for raw_portal: Variant in _scene_portals(source):
			if not raw_portal is Dictionary:
				continue
			var portal: Dictionary = raw_portal
			var target_id := StringName(portal.get("target_scene", ""))
			if String(target_id).is_empty() or target_id == &"world_map_jianghu":
				continue
			var target_path := "res://data/scenes/%s.tres" % String(target_id)
			if not ResourceLoader.exists(target_path):
				continue
			var target: Resource = load(target_path)
			var reverse := _find_portal_to(_scene_portals(target), source_id)
			if reverse.is_empty():
				continue
			var used_source: Vector2 = portal.get("pos", Vector2(0.5, 0.8))
			_router.call("reset_for_new_game")
			_router.call("resolve_portal_arrival", source_id, target_id, used_source, portal.get("target_pos", null))
			var returned: Vector2 = _router.call(
				"resolve_portal_arrival",
				target_id,
				source_id,
				reverse.get("pos", Vector2(0.5, 0.8)),
				reverse.get("target_pos", null)
			)
			_expect_vec(returned, used_source, "%s reverse portal returns to its used source doorway" % String(source_id))
			checked += 1
	_expect(checked >= 30, "reciprocal portal audit covers at least 30 directed routes (actual=%d)" % checked)


func _test_navigation_state_round_trip() -> void:
	_router.call("reset_for_new_game")
	var market_door := Vector2(0.241, 0.361)
	_router.call("resolve_portal_arrival", &"ch2_s1_zhuwei_market", &"ch2_s1_market_inn", market_door, Vector2(0.5, 0.72))
	var saved: Dictionary = _router.call("get_navigation_state")
	_router.call("reset_for_new_game")
	_router.call("restore_navigation_state", saved)
	var returned: Vector2 = _router.call("resolve_portal_arrival",
		&"ch2_s1_market_inn", &"ch2_s1_zhuwei_market", Vector2(0.5, 0.82), Vector2(0.24, 0.43)
	)
	_expect_vec(returned, market_door, "paired doorway survives save/load while the player is indoors")


func _test_save_contract() -> void:
	var saver: Node = load("res://tests/fixtures/memory_save_probe_20260910.gd").new()
	_expect(saver.SAVE_VERSION >= 12, "save schema retains navigation-capable version")
	var expected: Dictionary = JSON.parse_string(JSON.stringify(_router.get_navigation_state()))
	_expect(saver.save_to_slot(0), "actual SaveManager serialization succeeds without writing user slots")
	_expect(saver.captured.get("navigation",{}) == expected, "serialized save contains real navigation state")
	_router.reset_for_new_game()
	_expect(saver.load_from_slot(0), "actual SaveManager restore accepts captured save")
	_expect(JSON.parse_string(JSON.stringify(_router.get_navigation_state())) == expected, "actual load restores portal navigation state")
	saver.free()


func _scene_portals(scene: Resource) -> Array:
	if scene == null:
		return []
	var layout: Resource = scene.get("map_layout")
	if layout != null:
		return layout.get("portals")
	return scene.get("exits")


func _find_portal_to(portals: Array, target_scene_id: StringName) -> Dictionary:
	for raw_portal: Variant in portals:
		if raw_portal is Dictionary and StringName(raw_portal.get("target_scene", "")) == target_scene_id:
			return raw_portal
	return {}


func _expect_vec(actual: Vector2, expected: Vector2, message: String) -> void:
	_expect(actual.distance_to(expected) < 0.0001, "%s (expected=%s actual=%s)" % [message, expected, actual])


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		push_error("[FAIL] %s" % message)
