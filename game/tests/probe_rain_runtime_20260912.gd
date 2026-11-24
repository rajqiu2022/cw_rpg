extends SceneTree

## Desktop-only diagnostic for the reported rainy mountain-road movement hitch.
## It loads the real field, enables the plot rain and samples rendered frame
## intervals while movement input is active. This is evidence, not a CI gate:
## renderer/driver speed differs between machines.

const SAMPLE_FRAMES := 240
const WARMUP_FRAMES := 45


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := get_root().get_node_or_null("GameState")
	var weather := get_root().get_node_or_null("WeatherManager")
	var router := get_root().get_node_or_null("SceneRouter")
	if game_state == null or weather == null or router == null:
		push_error("[RainRuntimeProbe] required autoload missing")
		quit(1)
		return
	game_state.call("reset_for_new_game")
	game_state.call("set_flag", &"seen_ch1_road_intro", true)
	weather.call("set_weather", &"rain_light", 0.80)
	router.set("_field_payload", {"scene_id": &"ch1_s1_road", "player_spawn": Vector2(0.48, 0.43)})
	router.set("_current_field_id", &"ch1_s1_road")
	change_scene_to_file("res://scenes/field_walkable.tscn")
	for _frame in range(WARMUP_FRAMES):
		await process_frame

	var frame_ms: Array[float] = []
	var last_usec := Time.get_ticks_usec()
	Input.action_press("move_right")
	for frame in range(SAMPLE_FRAMES):
		if frame == 60:
			Input.action_release("move_right")
			Input.action_press("move_down")
		elif frame == 120:
			Input.action_release("move_down")
			Input.action_press("move_left")
		elif frame == 180:
			Input.action_release("move_left")
			Input.action_press("move_up")
		await process_frame
		var now_usec := Time.get_ticks_usec()
		frame_ms.append(float(now_usec - last_usec) / 1000.0)
		last_usec = now_usec
	Input.action_release("move_up")
	frame_ms.sort()
	var total_ms := 0.0
	for value in frame_ms:
		total_ms += value
	var average_ms := total_ms / maxf(1.0, float(frame_ms.size()))
	var p95_index := clampi(roundi(float(frame_ms.size() - 1) * 0.95), 0, frame_ms.size() - 1)
	var p99_index := clampi(roundi(float(frame_ms.size() - 1) * 0.99), 0, frame_ms.size() - 1)
	print("[RainRuntimeProbe] frames=%d avg_ms=%.3f avg_fps=%.1f p95_ms=%.3f p99_ms=%.3f" % [
		frame_ms.size(),
		average_ms,
		1000.0 / maxf(average_ms, 0.001),
		frame_ms[p95_index],
		frame_ms[p99_index],
	])
	await RenderingServer.frame_post_draw
	var screenshot := get_root().get_viewport().get_texture().get_image()
	screenshot.save_png("res://screenshots/rain_mountain_road_performance_v2.png")
	weather.call("clear_weather")
	quit(0)
