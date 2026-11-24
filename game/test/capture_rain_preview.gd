extends SceneTree

## Captures a short deterministic visual-QA sequence for the authored mountain
## rain sample. PNG frames can be assembled into GIF/WebP without screen video.

const OUTPUT_DIR := "screenshots/previews/rain_mountain_road_v1_frames"
const FRAME_COUNT := 14
const FRAME_INTERVAL := 0.085


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	var game_state := get_root().get_node_or_null("GameState")
	if game_state != null:
		game_state.call("set_flag", &"seen_ch1_road_intro", true)
	var weather_manager := get_root().get_node_or_null("WeatherManager")
	if weather_manager != null:
		weather_manager.call("set_weather", &"rain_light", 0.80)
	var router := get_root().get_node_or_null("SceneRouter")
	if router == null:
		push_error("[CaptureRain] SceneRouter unavailable")
		quit(1)
		return
	var scene_id := &"ch1_s1_road"
	var scene_def := load("res://data/scenes/ch1_s1_road.tres") as SceneScript
	router.set("_field_payload", {"scene_id": scene_id, "player_spawn": scene_def.player_spawn})
	router.set("_current_field_id", scene_id)
	change_scene_to_file(String(router.call("get_field_scene_path", scene_id)))
	for _index in range(14):
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for frame_index in range(FRAME_COUNT):
		await create_timer(FRAME_INTERVAL).timeout
		var image := get_root().get_viewport().get_texture().get_image()
		var path := "%s/rain_%02d.png" % [OUTPUT_DIR, frame_index]
		var error := image.save_png(path)
		if error != OK:
			push_error("[CaptureRain] failed to save %s: %d" % [path, error])
			quit(1)
			return
	print("[CaptureRain] saved %d frames to %s" % [FRAME_COUNT, OUTPUT_DIR])
	quit(0)
