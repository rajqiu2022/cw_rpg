extends SceneTree

var failures := 0


func _initialize() -> void:
	await process_frame
	_test_environment_mapping()
	await _test_five_point_formation()
	_test_background_assets()
	_test_scale_and_trial_contracts()
	print("[BattleArenaExpansion20260902] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_environment_mapping() -> void:
	var router := root.get_node_or_null("SceneRouter")
	_check(router != null, "SceneRouter autoload is available")
	if router == null:
		return
	var cases := {
		&"linxi_tutorial": &"village_square",
		&"ch4_s1_luoyang_yamen": &"city_street",
		&"ch2_s3_forest_ambush": &"outskirts_road",
		&"ch1_s4_cave_deep_den": &"cave_depths",
		&"ch3_s2_trial_ground": &"sect_courtyard",
		&"ch5_s3_snow_pass": &"snow_peak",
		&"ch6_s4_baishui_convoy_route": &"grassland",
		&"ch4_s2_canal_docks": &"river_skirmish",
		&"ch8_s7_mingwu_rear_sanctum": &"mingwu_sanctum",
	}
	for scene_id: StringName in cases:
		var actual := StringName(router.call("_battle_arena_for_scene", scene_id))
		_check(actual == cases[scene_id], "%s maps to %s" % [scene_id, cases[scene_id]])


func _test_five_point_formation() -> void:
	var view := BattleFormationView.new()
	view.size = Vector2(1920.0, 1080.0)
	root.add_child(view)
	var single_positions: Array[Vector2] = []
	for variant in range(3):
		view.set_formation_profile(&"village_square", variant)
		var enemy_slots: Array[Vector2] = view.call("_selected_slots", view.call("_slots_for", true), 1, true)
		_check(enemy_slots.size() == 1, "loose enemy variant %d selects one safe point" % variant)
		if not enemy_slots.is_empty():
			single_positions.append(enemy_slots[0])
			_check(enemy_slots[0].y >= 0.42 and enemy_slots[0].y <= 0.59, "village enemy foot anchor stays inside the upper-right red-box ground")
	view.set_formation_profile(&"village_square", 0)
	var allies: Array[Vector2] = view.call("_selected_slots", view.call("_slots_for", false), 5, false)
	var enemies: Array[Vector2] = view.call("_selected_slots", view.call("_slots_for", true), 5, true)
	_check(allies.size() == 5 and enemies.size() == 5, "unmarked arenas retain five authored logical points per side")
	_check(_unique_points(single_positions) == 3, "single-unit loose placement rotates across three safe points")
	_check(_unique_y(allies) >= 4 and _unique_y(enemies) == 5, "five-unit formations are depth-staggered rather than straight rows")
	_check(allies.all(func(point: Vector2): return point.x >= 0.17 and point.x <= 0.45 and point.y >= 0.70 and point.y <= 0.92), "all village allies remain inside the lower-left red-box region")
	_check(enemies.all(func(point: Vector2): return point.x >= 0.53 and point.x <= 0.82 and point.y >= 0.42 and point.y <= 0.59), "all village enemies remain inside the upper-right red-box region")
	view.queue_free()
	await process_frame


func _test_background_assets() -> void:
	var files := [
		"bg_battle_village_square_v3.jpg",
		"bg_battle_city_street_v1.jpg",
		"bg_battle_outskirts_road_v1.jpg",
		"bg_battle_cave_depths_v1.jpg",
		"bg_battle_sect_courtyard_v1.jpg",
		"bg_battle_snow_peak_v1.jpg",
		"bg_battle_grassland_v1.jpg",
	]
	for file_name in files:
		var path := "res://art/backgrounds/battle_arenas_v2/%s" % file_name
		_check(FileAccess.file_exists(path), "%s exists" % file_name)
		var image := Image.new()
		var loaded := image.load(ProjectSettings.globalize_path(path))
		_check(loaded == OK and image.get_size() == Vector2i(1920, 1080), "%s is a formal 1920x1080 arena" % file_name)


func _test_scale_and_trial_contracts() -> void:
	var controller := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	_check("PROTAGONIST_FORMATION_SCALE_FACTOR := 1.28" in controller, "slim protagonist frames normalize by visible-alpha area")
	_check('maxf(0.96, def.battle_actor_scale)' in controller, "ordinary enemies retain a stable minimum presentation scale")
	var stage_builder := FileAccess.get_file_as_string("res://../scripts/prepare_wechat_trial_stage.py")
	for future_name in ["bg_battle_city_street_v1.jpg", "bg_battle_snow_peak_v1.jpg", "bg_battle_grassland_v1.jpg"]:
		_check(future_name in stage_builder, "trial staging blocks future arena %s" % future_name)


func _unique_points(points: Array[Vector2]) -> int:
	var seen := {}
	for point in points:
		seen[point] = true
	return seen.size()


func _unique_y(points: Array[Vector2]) -> int:
	var seen := {}
	for point in points:
		seen[snappedf(point.y, 0.001)] = true
	return seen.size()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
