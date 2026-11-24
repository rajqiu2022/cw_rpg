extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var assets := {
		"res://art/modules/veg/veg_bamboo_top_canopy.png": Vector2i(527, 94),
		"res://art/props/ambient/prop_ambient_tent_flap_canvas_v1.png": Vector2i(1230, 1278),
		"res://art/props/ambient/prop_ambient_teal_mist_banner_v1.png": Vector2i(1024, 1536),
	}
	for path: String in assets:
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		_check(image != null and image.detect_alpha() and image.get_size() == assets[path], "foreground sway asset is true-alpha with reviewed dimensions: %s" % path)
	var scene_assets := {
		"ch1_s3_zhuwei_forest": "res://art/modules/veg/veg_bamboo_top_canopy.png",
		"ch2_s2_forest_edge": "res://art/modules/veg/veg_bamboo_top_canopy.png",
		"ch2_s3_forest_ambush": "res://art/modules/veg/veg_bamboo_top_canopy.png",
		"ch5_s2_grain_convoy_camp": "res://art/props/ambient/prop_ambient_tent_flap_canvas_v1.png",
		"ch7_s2_mingwu_tea_town": "res://art/modules/veg/veg_bamboo_top_canopy.png",
		"ch7_s4_mingwu_manor_outer_court": "res://art/modules/veg/veg_bamboo_top_canopy.png",
		"ch7_s6_mingwu_inner_court": "res://art/modules/veg/veg_bamboo_top_canopy.png",
		"ch8_s1_alliance_staging_ground": "res://art/props/ambient/prop_ambient_tent_flap_canvas_v1.png",
		"ch8_s5_alliance_ceremonial_platform": "res://art/props/ambient/prop_ambient_teal_mist_banner_v1.png",
	}
	for scene_id: String in scene_assets:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		var expected_texture := String(scene_assets[scene_id])
		var matches := 0
		for prop: Dictionary in scene.animated_props:
			if String(prop.get("type", "")) == "texture_sway" and String(prop.get("texture", "")) == expected_texture:
				matches += 1
				_check(not prop.has("collision_size") and not prop.has("interaction_action") and not prop.has("target_scene"), "foreground sway stays visual-only: %s/%s" % [scene_id, String(prop.get("id", ""))])
		_check(matches >= 1 and scene.animated_props.size() <= 10, "scene uses the intended independent foreground asset within budget: %s" % scene_id)
	var assembly := load("res://data/scenes/ch3_s1_wulin_assembly.tres") as SceneScript
	var assembly_teal := assembly.animated_props.filter(func(prop: Dictionary): return String(prop.get("texture", "")) == "res://art/props/ambient/prop_ambient_teal_mist_banner_v1.png")
	_check(assembly_teal.size() == 2 and assembly.animated_props.size() <= 10, "Wulin assembly uses two teal banners alongside its red banners")
	var bridge_source := FileAccess.get_file_as_string("res://scripts/autoload/platform_bridge.gd")
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check("func ambient_animation_density" in bridge_source and "return 0.55" in bridge_source and "return 0.70" in bridge_source, "platform bridge defines WeChat and Web ambient density levels")
	_check(field_source.count("_ambient_animation_density()") >= 5, "smoke, mist, water and snow child counts consume the platform density")
	var platform := root.get_node("PlatformBridge")
	_check(is_equal_approx(float(platform.call("ambient_animation_density")), 1.0), "desktop keeps full ambient density")
	print("[EnvironmentForegroundMobile20260831] failures=%d" % failures)
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
