extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var controller_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check("\"mist_drift\":" in controller_source and "func _make_mist_drift_prop" in controller_source, "field runtime owns the reusable mist-drift type")
	_check("puff.create_tween().set_loops()" in controller_source, "mist and smoke loops bind to short-lived visual nodes")
	var scenes := {
		"ch1_s4_zhuwei_beast_cave": 1,
		"ch2_s5_bandit_cave": 2,
		"ch2_s4_lingyue_gate": 2,
		"ch3_s4_forbidden_tomb": 3,
		"ch4_s1_luoyang_yamen": 4,
		"ch4_s4_ancient_temple": 4,
		"ch4_s5_temple_tunnel": 4,
		"ch5_s2_grain_convoy_camp": 5,
		"ch5_s4_abandoned_mine": 5,
		"ch6_s3_underground_archive": 6,
		"ch6_s5_ancient_road_inn": 6,
		"ch7_s1_lieyun_valley_ferry": 7,
		"ch7_s10_lieyun_night_transfer_station": 7,
		"ch8_s1_alliance_staging_ground": 8,
		"ch8_s4_alliance_mechanism_gallery": 8,
	}
	var chapter_coverage := {}
	for scene_id: String in scenes:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		chapter_coverage[int(scenes[scene_id])] = true
		_check(scene != null and not scene.animated_props.is_empty(), "audited scene owns ambient animation: %s" % scene_id)
		_check(scene.animated_props.size() <= 10, "audited scene stays inside the ten-prop mobile budget: %s" % scene_id)
		var mist_count := 0
		var ids := {}
		for prop: Dictionary in scene.animated_props:
			var prop_id := String(prop.get("id", ""))
			var prop_type := String(prop.get("type", ""))
			var pos: Vector2 = prop.get("pos", Vector2(-1, -1))
			var size: Vector2 = prop.get("size", Vector2.ZERO)
			_check(not prop_id.is_empty() and not ids.has(prop_id), "expanded ambient id is unique: %s/%s" % [scene_id, prop_id])
			ids[prop_id] = true
			_check(prop_type in ["texture_sway", "flame", "smoke", "mist_drift", "glow"], "expanded ambient type is supported: %s/%s" % [scene_id, prop_id])
			_check(pos.x >= 0.0 and pos.x <= 1.0 and pos.y >= 0.0 and pos.y <= 1.0 and size.x > 0.0 and size.y > 0.0, "expanded ambient prop uses normalized visual coordinates: %s/%s" % [scene_id, prop_id])
			_check(not prop.has("collision_size") and not prop.has("interaction_action") and not prop.has("target_scene"), "expanded ambient prop remains visual-only: %s/%s" % [scene_id, prop_id])
			if prop_type == "mist_drift":
				mist_count += 1
				_check(float(prop.get("opacity", 0.14)) <= 0.15 and int(prop.get("count", 4)) <= 6, "mist stays within opacity and sprite-count budget: %s/%s" % [scene_id, prop_id])
		_check(mist_count >= 1, "audited scene includes a restrained mist or vapor layer: %s" % scene_id)
	_check(chapter_coverage.size() == 8, "ambient expansion covers every story chapter")
	var tomb := load("res://data/scenes/ch3_s4_forbidden_tomb.tres") as SceneScript
	var tunnel := load("res://data/scenes/ch4_s5_temple_tunnel.tres") as SceneScript
	_check(_type_set(tomb.animated_props) == _type_set(tunnel.animated_props), "shared tomb background keeps a reusable flame-and-mist preset")
	var gallery := load("res://data/scenes/ch8_s4_alliance_mechanism_gallery.tres") as SceneScript
	for prop: Dictionary in gallery.animated_props:
		if String(prop.get("id", "")).contains("steam") or String(prop.get("id", "")).contains("floor_mist"):
			_check(String(prop.get("hide_flag", "")) == "ch8_mist_vents_disabled", "mechanism vapor stops after the mist vents are disabled")
	print("[EnvironmentAmbientExpansion20260831] failures=%d" % failures)
	quit(1 if failures else 0)


func _type_set(props: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for prop: Dictionary in props:
		var prop_type := String(prop.get("type", ""))
		if prop_type not in result:
			result.append(prop_type)
	result.sort()
	return result


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
