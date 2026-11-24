extends Node

## Global plot-driven weather state. Weather is never authored into a scene:
## dialogue/actions switch it on or off, outdoor fields render it, and indoor
## fields temporarily suppress it without clearing the story state.

const CLEAR := &"clear"
const RAIN_LIGHT := &"rain_light"
const RAIN_HEAVY := &"rain_heavy"
const STORM := &"storm"
const RAIN_AMBIENCE := "res://art/audio/ambience/amb_rain_mountain_soft_v1.wav"
const SUPPORTED_WEATHER: Array[StringName] = [CLEAR, RAIN_LIGHT, RAIN_HEAVY, STORM]
const SHELTER_TOKENS: Array[String] = [
	"interior", "cave", "tunnel", "underground", "mine", "archive",
	"bedroom", "martial_hall", "main_hall", "sanctum", "gallery", "inn_hall", "ruin_inner",
]

var current_weather: StringName = CLEAR
var strength: float = 1.0
var _current_scene_id: StringName = &""
var _scope_scene_ids: Array[StringName] = []


func _ready() -> void:
	EventBus.scene_entered.connect(_on_scene_entered)


func set_weather(weather_id: StringName, requested_strength: float = 1.0, scope_scene_ids: Array[StringName] = []) -> bool:
	var normalized := _normalize_weather(weather_id)
	if normalized not in SUPPORTED_WEATHER:
		push_warning("[WeatherManager] unsupported weather: %s" % weather_id)
		return false
	var clamped_strength := clampf(requested_strength, 0.25, 1.50)
	if normalized == CLEAR:
		clamped_strength = 1.0
	var resolved_scope: Array[StringName] = []
	if normalized != CLEAR:
		for scene_id in scope_scene_ids:
			if String(scene_id) != "" and scene_id not in resolved_scope:
				resolved_scope.append(scene_id)
		# Plot weather defaults to the outdoor field where the dialogue enabled
		# it. It must not leak into the village merely because both are exposed.
		if resolved_scope.is_empty() and String(_current_scene_id) != "":
			resolved_scope.append(_current_scene_id)
	var changed := normalized != current_weather or not is_equal_approx(clamped_strength, strength) or resolved_scope != _scope_scene_ids
	current_weather = normalized
	strength = clamped_strength
	_scope_scene_ids = resolved_scope
	_sync_audio()
	if changed:
		EventBus.weather_changed.emit(current_weather, strength)
		print("[Weather] %s strength=%.2f" % [current_weather, strength])
	return true


func clear_weather() -> void:
	set_weather(CLEAR)


func is_active() -> bool:
	return current_weather != CLEAR


func is_weather_visible(scene: SceneScript) -> bool:
	return is_active() and is_scene_exposed(scene)


func has_active_weather_for_scene_id(scene_id: StringName) -> bool:
	if not is_active():
		return false
	var scene := _load_scene(scene_id)
	return scene != null and is_scene_exposed(scene)


func is_scene_exposed(scene: SceneScript) -> bool:
	if scene == null:
		return false
	if not _scope_scene_ids.is_empty() and scene.scene_id not in _scope_scene_ids:
		return false
	var signature := String(scene.scene_id).to_lower()
	for token in SHELTER_TOKENS:
		if token in signature:
			return false
	# Art filenames can mention a visible cave entrance while the actual scene is
	# still outdoors (the chapter-one road does). Only the explicit interior
	# background prefix is safe as a legacy fallback.
	if "/bg_interior_" in scene.background_path.to_lower():
		return false
	return true


func get_visual_props() -> Array[Dictionary]:
	if not is_active():
		return []
	var heavy := current_weather in [RAIN_HEAVY, STORM]
	var storming := current_weather == STORM
	var intensity := (0.92 if heavy else 0.62) * strength
	var opacity := (0.62 if heavy else 0.43) * minf(strength, 1.20)
	var speed := (1.48 if heavy else 1.08) * lerpf(0.88, 1.12, clampf(strength - 0.5, 0.0, 1.0))
	return [
		{
			"id": "global_story_rain",
			"type": "rain_field",
			"pos": Vector2(0.50, 0.50),
			"size": Vector2(1.06, 1.06),
			"speed": speed,
			"intensity": clampf(intensity, 0.15, 1.0),
			"opacity": clampf(opacity, 0.12, 0.72),
			"wind_x": 0.27 if storming else (0.21 if heavy else 0.16),
			"color": "#86abb6" if heavy else "#91b8c2",
			"tint_color": "#102833" if storming else "#16313d",
			"tint_opacity": 0.22 if storming else (0.17 if heavy else 0.12),
			"z_index": 72,
		},
		{
			"id": "global_story_rain_splashes",
			"type": "rain_splash",
			"pos": Vector2(0.50, 0.78),
			"size": Vector2(0.92, 0.30),
			"speed": 1.28 if heavy else 1.0,
			"count": 8 if heavy else 5,
			"opacity": 0.56 if heavy else 0.44,
			"color": "#c3e0e5",
			"z_index": 76,
		},
	]


func to_dict() -> Dictionary:
	var packed_scope: Array[String] = []
	for scene_id in _scope_scene_ids:
		packed_scope.append(String(scene_id))
	return {
		"weather_id": String(current_weather),
		"strength": strength,
		"scope_scene_ids": packed_scope,
	}


func from_dict(data: Dictionary) -> void:
	var restored_scope: Array[StringName] = []
	var raw_scope: Variant = data.get("scope_scene_ids", [])
	if raw_scope is Array:
		for raw_scene_id: Variant in raw_scope:
			var scene_id := StringName(String(raw_scene_id))
			if String(scene_id) != "":
				restored_scope.append(scene_id)
	# Old active-weather saves predate scoping. The only authored chapter-one
	# rain starts on the village-outskirts road, so do not restore it globally.
	if restored_scope.is_empty() and String(data.get("weather_id", "clear")) != "clear":
		restored_scope.append(&"ch1_s1_road")
	set_weather(StringName(data.get("weather_id", "clear")), float(data.get("strength", 1.0)), restored_scope)


func reset_for_new_game() -> void:
	_current_scene_id = &""
	_scope_scene_ids.clear()
	clear_weather()


func _normalize_weather(weather_id: StringName) -> StringName:
	match String(weather_id).to_lower():
		"rain", "light_rain", "rain_light":
			return RAIN_LIGHT
		"heavy_rain", "rain_heavy":
			return RAIN_HEAVY
		"thunder", "thunderstorm", "storm":
			return STORM
		"off", "none", "sunny", "clear":
			return CLEAR
	return weather_id


func _on_scene_entered(scene_id: StringName) -> void:
	_current_scene_id = scene_id
	_sync_audio()


func _sync_audio() -> void:
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		return
	if has_active_weather_for_scene_id(_current_scene_id):
		var offset := -11.5 if current_weather in [RAIN_HEAVY, STORM] else -16.0
		audio_manager.call("play_ambience", RAIN_AMBIENCE, offset)
	else:
		audio_manager.call("ensure_ambience_for_scene", _current_scene_id)


func _load_scene(scene_id: StringName) -> SceneScript:
	if String(scene_id).is_empty():
		return null
	var path := "res://data/scenes/%s.tres" % String(scene_id)
	return load(path) as SceneScript if ResourceLoader.exists(path) else null


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F9:
		set_weather(CLEAR if is_active() else RAIN_LIGHT)
		get_viewport().set_input_as_handled()
