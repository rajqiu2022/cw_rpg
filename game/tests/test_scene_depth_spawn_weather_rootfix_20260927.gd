extends SceneTree

var _failed := 0
var _checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_portal_anchor_contract()
	_check_weather_scope_and_direction()
	_check_scene_data_repairs()
	_check_safe_spawn_repair()
	_check_music_routes()
	print("[SceneDepthSpawnWeatherRootfix20260927] checks=%d failed=%d" % [_checks, _failed])
	quit(_failed)


func _check_portal_anchor_contract() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check("exit_triggered.connect(_on_exit_triggered.bind(source_portal_spawn))" in source, "portal signal binds its authored source anchor")
	_check("target_pos, source_portal_spawn" in source, "paired return stores the portal anchor instead of a movement sample")
	_check("_spawn_has_foot_clearance" in source and "_nearest_safe_spawn" in source, "all field arrivals use the generic foot-clearance repair")


func _check_weather_scope_and_direction() -> void:
	var shader := FileAccess.get_file_as_string("res://shaders/environment_rain.gdshader")
	_check("-TIME * speed * time_scale" in shader, "rain UV scroll produces downward screen motion")
	var weather := root.get_node_or_null("WeatherManager")
	_check(weather != null, "WeatherManager autoload exists")
	if weather == null:
		return
	weather.call("reset_for_new_game")
	weather.call("_on_scene_entered", &"ch1_s1_road")
	weather.call("set_weather", &"rain_light", 0.8)
	var road := load("res://data/scenes/ch1_s1_road.tres") as SceneScript
	var village := load("res://data/scenes/linxi_village_center.tres") as SceneScript
	_check(weather.call("is_weather_visible", road), "rain remains visible on the outdoor scene that enabled it")
	_check(not weather.call("is_weather_visible", village), "rain does not leak back into Linxi village")
	var saved: Dictionary = weather.call("to_dict")
	_check(saved.get("scope_scene_ids", []) == ["ch1_s1_road"], "weather save data preserves its scene scope")
	weather.call("clear_weather")


func _check_scene_data_repairs() -> void:
	var south := load("res://data/maps/linxi_village_scrollmap_layout_v1.tres") as WalkableMapLayout
	var scholar := _find_by_id(south.portals, "enter_south_scholar_house")
	_check(Vector2(scholar.get("size", Vector2.ZERO)).y >= 0.15, "South Ward school entrance has a reachable interaction throat")

	var huashan := load("res://data/maps/openworld_huashan_forecourt_layout_v2.tres") as WalkableMapLayout
	var gate: Dictionary = huashan.occluders[0]
	var max_fade_y := 0.0
	for point: Vector2 in gate.get("fade_region", PackedVector2Array()):
		max_fade_y = maxf(max_fade_y, point.y)
	_check(max_fade_y <= 0.57, "Huashan fade trigger ends at the gate threshold instead of the lower stairs")

	var wudang := load("res://data/maps/openworld_wudang_taiji_court_layout_v1.tres") as WalkableMapLayout
	_check(not _find_by_id(wudang.blockers, "west_side_brazier").is_empty(), "Wudang side brazier owns a collision footprint")
	_check(not _find_by_id(wudang.occluders, "west_side_brazier").is_empty(), "Wudang side brazier owns an independent Y-depth foreground")

	var lingyue := load("res://data/maps/ch2_s4_lingyue_gate_layout_v1.tres") as WalkableMapLayout
	_check(lingyue.actor_fade_zones.is_empty(), "Lingyue no longer fades the actor on an empty path rectangle")
	_check(not _find_by_id(lingyue.portals, "lingyue_to_inner_court").is_empty(), "Lingyue gate now has an actual inner-court entrance")
	_check(ResourceLoader.exists("res://data/scenes/openworld_lingyue_inner_court.tres"), "Lingyue inner court scene exists")

	for scene_id: String in ["openworld_wudang_gate", "openworld_wudang_taiji_court", "openworld_wudang_purple_cloud_court", "openworld_huashan_forecourt", "openworld_huashan_sword_terrace", "openworld_huashan_waterfall_terrace"]:
		var sect_scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(sect_scene != null and "/sect_maps_v5/" in sect_scene.background_path, "%s uses the reviewed realistic v5 runtime art" % scene_id)
	var wudang_gate := load("res://data/maps/openworld_wudang_gate_layout_v1.tres") as WalkableMapLayout
	var wudang_gate_arch: Dictionary = wudang_gate.occluders[0]
	_check(String(wudang_gate_arch.get("alpha_mask_texture_path", "")).ends_with("wudang_gate_foreground_mask_v2.svg"), "Wudang gate uses the v5-matched foreground alpha mask")

	var temple := load("res://data/maps/ch4_s4_ancient_temple_layout_v1.tres") as WalkableMapLayout
	_check(not _find_by_id(temple.blockers, "stone_offering_table").is_empty(), "ancient-temple stone table is blocked")
	_check(not _find_by_id(temple.occluders, "temple_stone_offering_table").is_empty(), "ancient-temple stone table has a Y-depth foreground")


func _check_safe_spawn_repair() -> void:
	var field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	var temple := load("res://data/scenes/ch4_s4_ancient_temple.tres") as SceneScript
	field.call("_rebuild_walkability_collision_entries", temple.map_layout.blockers, temple.map_layout.visual_objects)
	var repaired: Vector2 = field.call("_resolve_player_spawn", temple, Vector2(0.270,0.755))
	_check(repaired.distance_to(Vector2(0.270,0.755)) > 0.01, "unsafe saved spawn on the stone table is locally repaired")
	_check(field.call("_spawn_has_foot_clearance", temple, repaired), "repaired temple spawn has full foot clearance")
	field.free()


func _check_music_routes() -> void:
	var world := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	_check(world != null and world.background_path.ends_with("bg_world_map_jianghu_v12_2304.png"), "world map uses the realistic v12 clean plate")
	_check(world != null and world.map_layout.schema_version == 12, "world map art and navigation use the v12 synchronized contract")
	_check(world != null and world.streamed_background != null and world.streamed_background.mobile_chunks.size() == 15 and world.streamed_background.desktop_chunks.size() == 15, "world map keeps high-resolution streamed chunks")
	var expected := {
		"world_map_jianghu": "bgm_jianghu_journey_v4.wav",
		"openworld_wudang_gate": "bgm_sect_clouds_v4.wav",
		"openworld_huashan_forecourt": "bgm_mountain_path_v4.wav",
		"ch2_s4_lingyue_gate": "bgm_forest_mystery_v4.wav",
		"ch4_s3_luoyang_market": "bgm_market_lively_v4.wav",
	}
	for scene_id: String in expected:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(scene != null and scene.bgm_path.ends_with(expected[scene_id]), "%s uses its approved scene-class music route" % scene_id)
		_check(scene == null or not scene.bgm_path.ends_with("bgm_linxi_village_v6.wav"), "%s no longer reuses the rejected Linxi fallback" % scene_id)


func _find_by_id(entries: Array, wanted: String) -> Dictionary:
	for raw: Variant in entries:
		if raw is Dictionary and String(raw.get("id", "")) == wanted:
			return raw
	return {}


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("[PASS] %s" % message)
	else:
		_failed += 1
		push_error("[FAIL] %s" % message)
