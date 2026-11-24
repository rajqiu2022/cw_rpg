extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var shader_path := "res://shaders/environment_rain.gdshader"
	_check(FileAccess.file_exists(shader_path), "procedural rain shader exists")
	var shader_source := FileAccess.get_file_as_string(shader_path)
	_check("far_rain" in shader_source and "near_rain" in shader_source and "slant" in shader_source, "rain shader owns two depths and authored wind slant")
	_check("rain_pattern" in shader_source and "texture(rain_pattern" in shader_source, "rain shader samples a cached sparse tile")
	_check("hash21" not in shader_source, "rain shader no longer hashes every rendered pixel")
	var controller_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check("func _make_rain_field_prop" in controller_source and "func _make_rain_splash_prop" in controller_source, "field runtime owns rain sheet and ground response")
	_check("func _get_rain_pattern_texture" in controller_source and "_rain_pattern_texture" in controller_source, "field runtime creates and caches one rain pattern texture")
	_check("ENVIRONMENT_RAIN_SHADER" in controller_source and "_spawn_active_weather" in controller_source, "field weather is injected from global state instead of scene data")

	var road := load("res://data/scenes/ch1_s1_road.tres") as SceneScript
	var interior := load("res://data/scenes/interior_martial_hall.tres") as SceneScript
	_check(road != null and interior != null, "outdoor and indoor weather test scenes load")
	if road != null:
		var scene_source := FileAccess.get_file_as_string("res://data/scenes/ch1_s1_road.tres")
		_check("rain_field" not in scene_source and "amb_rain" not in scene_source, "mountain road no longer owns weather or rain audio")
	_check(FileAccess.file_exists("res://art/audio/ambience/amb_rain_mountain_soft_v1.wav"), "global rain ambience runtime asset exists")

	var audio_source := FileAccess.get_file_as_string("res://scripts/autoload/audio_manager.gd")
	_check("func play_ambience" in audio_source and "func ensure_ambience_for_scene" in audio_source, "audio manager follows scene ambience lifecycle")
	var weather_manager := get_root().get_node_or_null("WeatherManager")
	var audio_manager := get_root().get_node_or_null("AudioManager")
	var scene_router := get_root().get_node_or_null("SceneRouter")
	_check(weather_manager != null, "weather manager autoload is available")
	_check(audio_manager != null, "audio manager autoload is available")
	_check(scene_router != null, "scene router autoload is available")
	if weather_manager != null and audio_manager != null and scene_router != null and road != null and interior != null:
		weather_manager.call("reset_for_new_game")
		_check(not bool(weather_manager.call("is_active")), "new game starts with clear weather")
		scene_router.call("resolve_action", "weather:rain_light:0.80")
		_check(StringName(weather_manager.get("current_weather")) == &"rain_light", "story action enables light rain")
		_check(bool(weather_manager.call("is_weather_visible", road)), "active plot rain renders outdoors")
		_check(not bool(weather_manager.call("is_weather_visible", interior)), "active plot rain is suppressed indoors without clearing state")
		var types: Array[String] = []
		for prop: Dictionary in weather_manager.call("get_visual_props"):
			var prop_type := String(prop.get("type", ""))
			types.append(prop_type)
			_check(not prop.has("collision_size") and not prop.has("interaction_action") and not prop.has("target_scene"), "global rain remains visual-only: %s" % String(prop.get("id", "")))
			if prop_type == "rain_splash":
				_check(int(prop.get("count", 0)) <= 8, "ground splashes stay inside the reduced movement budget")
		_check("rain_field" in types and "rain_splash" in types, "weather preset combines falling rain and ground splashes")
		weather_manager.call("_on_scene_entered", &"ch1_s1_road")
		await process_frame
		_check(String(audio_manager.call("get_current_ambience")).ends_with("amb_rain_mountain_soft_v1.wav"), "outdoor entry starts the global rain loop")
		weather_manager.call("_on_scene_entered", &"interior_martial_hall")
		_check(StringName(weather_manager.get("current_weather")) == &"rain_light", "indoor entry preserves plot weather")
		var saved_weather: Dictionary = weather_manager.call("to_dict")
		scene_router.call("resolve_action", "weather:clear")
		_check(not bool(weather_manager.call("is_active")), "story action clears weather")
		weather_manager.call("from_dict", saved_weather)
		_check(StringName(weather_manager.get("current_weather")) == &"rain_light" and is_equal_approx(float(weather_manager.get("strength")), 0.80), "weather state survives save/load serialization")
		weather_manager.call("clear_weather")
	var save_source := FileAccess.get_file_as_string("res://scripts/autoload/save_manager.gd")
	_check('"weather": WeatherManager.to_dict()' in save_source and "WeatherManager.from_dict" in save_source, "save schema persists global weather")
	var road_intro := load("res://data/dialogs/ch1_road_intro.tres") as DialogScript
	var road_departure := load("res://data/dialogs/ch1_road_to_zhuwei.tres") as DialogScript
	_check(road_intro != null and road_intro.get_entry_node().weather_id == &"rain_light", "chapter-one road opening starts rain from a plot node")
	_check(road_departure != null and road_departure.find_node_by_id(&"n2").weather_id == &"clear", "chapter-one departure clears rain from a plot node")
	print("[EnvironmentRain20260910] failures=%d" % failures)
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
