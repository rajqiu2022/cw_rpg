extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var banner_path := "res://art/props/ambient/prop_ambient_tattered_crimson_banner_v1.png"
	_check(FileAccess.file_exists(banner_path), "ambient banner runtime asset exists")
	var banner := Image.load_from_file(ProjectSettings.globalize_path(banner_path))
	_check(banner != null and banner.detect_alpha() and banner.get_width() == 1024 and banner.get_height() == 1536, "ambient banner is a true-alpha production asset")
	var controller_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check("\"flame\":" in controller_source and "func _make_flame_prop" in controller_source, "field runtime owns a dedicated procedural flame type")
	_check(FileAccess.file_exists("res://shaders/environment_flame.gdshader"), "environment flame uses a dedicated animated shader")
	_check("ENVIRONMENT_FLAME_SHADER" in controller_source and "_loop_flame_ember" in controller_source, "flame runtime combines turbulent body, glow and rising embers")
	var scenes := {
		"ch5_s5_false_banner_outpost": {"minimum": 9, "required": ["texture_sway", "flame", "smoke"]},
		"ch8_s2_mistwood_blockade": {"minimum": 4, "required": ["flame", "smoke", "glow"]},
		"ch8_s7_mingwu_rear_sanctum": {"minimum": 4, "required": ["glow"]},
	}
	for scene_id: String in scenes:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		var contract: Dictionary = scenes[scene_id]
		_check(scene != null and scene.animated_props.size() >= int(contract.get("minimum", 1)), "scene owns reviewed ambient props: %s" % scene_id)
		_check(scene.animated_props.size() <= 10, "scene stays inside the ten-prop mobile budget: %s" % scene_id)
		var ids := {}
		var types := []
		for prop: Dictionary in scene.animated_props:
			var prop_id := String(prop.get("id", ""))
			var prop_type := String(prop.get("type", ""))
			var pos: Vector2 = prop.get("pos", Vector2(-1, -1))
			var size: Vector2 = prop.get("size", Vector2.ZERO)
			_check(not prop_id.is_empty() and not ids.has(prop_id), "ambient prop id is unique: %s/%s" % [scene_id, prop_id])
			ids[prop_id] = true
			types.append(prop_type)
			_check(prop_type in ["texture_sway", "flame", "smoke", "glow", "snow_drift", "rain_field", "rain_splash"], "ambient prop uses a supported visual type: %s/%s" % [scene_id, prop_id])
			_check(pos.x >= 0.0 and pos.x <= 1.0 and pos.y >= 0.0 and pos.y <= 1.0 and size.x > 0.0 and size.y > 0.0, "ambient prop keeps normalized visual bounds: %s/%s" % [scene_id, prop_id])
			_check(not prop.has("collision_size") and not prop.has("interaction_action") and not prop.has("target_scene"), "ambient prop does not modify collision, interaction or portals: %s/%s" % [scene_id, prop_id])
			if prop_type == "texture_sway":
				_check(String(prop.get("texture", "")) == banner_path, "sway prop uses the adopted banner asset: %s/%s" % [scene_id, prop_id])
		for required_type: String in contract.get("required", []):
			_check(required_type in types, "scene includes required ambient type %s: %s" % [required_type, scene_id])
	var mistwood := load("res://data/scenes/ch8_s2_mistwood_blockade.tres") as SceneScript
	for prop: Dictionary in mistwood.animated_props:
		if String(prop.get("id", "")).begins_with("ch8_signal_brazier"):
			_check(String(prop.get("hide_flag", "")) == "ch8_mistwood_blockade_cleared", "signal fire and smoke extinguish after the blockade is cleared")
	print("[EnvironmentAmbientAnimation20260831] failures=%d" % failures)
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
