extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check("func _make_water_shimmer_prop" in source and "func _make_snow_drift_prop" in source, "field runtime owns water-shimmer and snow-drift types")
	_check("streak.create_tween().set_loops()" in source and "flake.create_tween().set_loops()" in source, "weather and water loops bind to their visual nodes")
	var water_scenes := ["ch4_s2_canal_docks", "ch6_s4_baishui_convoy_route", "ch7_s1_lieyun_valley_ferry", "ch7_s2_mingwu_tea_town", "ch7_s6_mingwu_inner_court", "ch7_s10_lieyun_night_transfer_station"]
	for scene_id: String in water_scenes:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(scene != null and scene.animated_props.size() <= 10, "water scene stays inside the top-level prop budget: %s" % scene_id)
		var water_count := 0
		for prop: Dictionary in scene.animated_props:
			if String(prop.get("type", "")) != "water_shimmer":
				continue
			water_count += 1
			_check(int(prop.get("count", 5)) <= 8 and float(prop.get("opacity", 0.18)) <= 0.22, "water shimmer stays sparse and restrained: %s/%s" % [scene_id, String(prop.get("id", ""))])
			_check(_visual_only(prop), "water shimmer never changes collision or interaction: %s/%s" % [scene_id, String(prop.get("id", ""))])
		_check(water_count >= 1, "audited water scene owns a shimmer region: %s" % scene_id)
	var snow_scenes := ["ch5_s1_relief_road", "ch5_s2_grain_convoy_camp", "ch5_s3_snow_pass", "ch5_s5_false_banner_outpost"]
	for scene_id: String in snow_scenes:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(scene != null and scene.animated_props.size() <= 10, "snow scene stays inside the top-level prop budget: %s" % scene_id)
		var snow_count := 0
		for prop: Dictionary in scene.animated_props:
			if String(prop.get("type", "")) != "snow_drift":
				continue
			snow_count += 1
			_check(int(prop.get("count", 14)) <= 18 and float(prop.get("opacity", 0.42)) <= 0.50, "snow drift stays inside sprite and opacity budgets: %s/%s" % [scene_id, String(prop.get("id", ""))])
			_check(_visual_only(prop), "snow drift never changes collision or interaction: %s/%s" % [scene_id, String(prop.get("id", ""))])
		_check(snow_count == 1, "snow is one shared field layer per scene: %s" % scene_id)
	var banner_path := "res://art/props/ambient/prop_ambient_tattered_crimson_banner_v1.png"
	var banner_scenes := ["ch3_s1_wulin_assembly", "ch3_s2_trial_ground", "ch3_s3_faction_training", "ch7_s3_lieyun_outpost_outer_ward", "ch8_s3_manor_perimeter_encampment"]
	for scene_id: String in banner_scenes:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		var matched := 0
		for prop: Dictionary in scene.animated_props:
			if String(prop.get("type", "")) == "texture_sway" and String(prop.get("texture", "")) == banner_path:
				matched += 1
				_check(_visual_only(prop), "red-banner sway uses the adopted independent cloth asset: %s" % scene_id)
		_check(matched >= 1 and scene.animated_props.size() <= 10, "banner scene stays explicit and within budget: %s" % scene_id)
	var trial := load("res://data/scenes/ch3_s2_trial_ground.tres") as SceneScript
	var training := load("res://data/scenes/ch3_s3_faction_training.tres") as SceneScript
	_check(_sway_signature(trial.animated_props) == _sway_signature(training.animated_props), "shared trial-ground background uses one consistent banner layout")
	print("[EnvironmentWeatherWater20260831] failures=%d" % failures)
	quit(1 if failures else 0)


func _visual_only(prop: Dictionary) -> bool:
	return not prop.has("collision_size") and not prop.has("interaction_action") and not prop.has("target_scene")


func _sway_signature(props: Array[Dictionary]) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for prop: Dictionary in props:
		if String(prop.get("type", "")) == "texture_sway":
			result.append(prop.get("pos", Vector2.ZERO))
	return result


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
