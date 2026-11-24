extends SceneTree


func _initialize() -> void:
	await process_frame
	var manager := root.get_node("AudioManager")
	manager.call("play_bgm", "res://art/audio/bgm/bgm_jianghu_journey_v4.wav", 0.08)
	await create_timer(0.20).timeout
	var field_player := manager.get("bgm_player") as AudioStreamPlayer
	print("[BgmRuntime] field path=%s playing=%s position=%.3f" % [manager.call("get_current_bgm"), field_player.playing if field_player != null else false, field_player.get_playback_position() if field_player != null else -1.0])
	var switch_started := Time.get_ticks_msec()
	manager.call("play_bgm", "res://art/audio/bgm/bgm_battle_mountain_v4.wav", 0.08)
	var switch_elapsed := Time.get_ticks_msec() - switch_started
	await create_timer(0.20).timeout
	var active: AudioStreamPlayer = manager.get("bgm_player") as AudioStreamPlayer
	var full_loop := false
	if active != null and active.stream is AudioStreamWAV:
		var wav := active.stream as AudioStreamWAV
		var expected_end := int(round(wav.get_length() * float(wav.mix_rate)))
		full_loop = wav.loop_mode == AudioStreamWAV.LOOP_FORWARD and absi(wav.loop_end - expected_end) <= 1
	var valid: bool = manager.call("get_current_bgm") == "res://art/audio/bgm/bgm_battle_mountain_v4.wav" and active != null and active.stream != null and switch_elapsed < 50 and full_loop
	print("[BgmRuntime] battle path=%s playing=%s position=%.3f switch_ms=%d" % [manager.call("get_current_bgm"), active.playing if active != null else false, active.get_playback_position() if active != null else -1.0, switch_elapsed])
	print("[BgmRuntime] full_length_loop=%s" % full_loop)
	quit(0 if valid else 1)
