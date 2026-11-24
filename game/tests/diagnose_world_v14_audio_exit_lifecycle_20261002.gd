extends SceneTree

## SOURCE ONLY: producer runs once with --headless --verbose after full reading.
## A normal Field scene-enter event starts journey-v4. Only public stop APIs are
## used at this test-owned process exit; no autoload/player nodes are removed.
## This is LIMITED audio lifecycle evidence, never FULL world acceptance.
const AUDIO_PATH := "res://scripts/autoload/audio_manager.gd"
const AUDIO_SHA := "23f8fe91c0b526eb38722b08969dc40b5e47d1f1cfc99497ce8536b6743d3a5c"
const CANDIDATE := &"world_map_jianghu_v14"
const CANDIDATE_PATH := "res://data/scenes/world_map_jianghu_v14.tres"
const JOURNEY := "res://art/audio/bgm/bgm_jianghu_journey_v4.wav"
var checks := 0
var failures := 0
var evidence: Dictionary = {}
var saves_before: Dictionary = {}
var prior_navigation: Dictionary = {}
var prior_world: StringName
var prior_slot := -1
var output := ""

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[AudioExit FAIL] " + message)

func _saves() -> Dictionary:
	var result: Dictionary = {}
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path := "user://save_%d.json%s" % [slot, suffix]
			result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT"
	return result

func _run() -> void:
	output = "res://build/world_map_v14_qa/audio_exit_%d/" % Time.get_ticks_usec()
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique owned output directory")
	_check(DisplayServer.get_name() == "headless", "only producer-authorized headless diagnostic")
	_check(FileAccess.get_sha256(AUDIO_PATH) == AUDIO_SHA, "production AudioManager exact source under diagnosis")
	saves_before = _saves()
	var router := root.get_node("SceneRouter")
	prior_navigation = router.call("get_navigation_state").duplicate(true)
	prior_world = StringName(router.get("_active_world_map_scene"))
	prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	var definition := load(CANDIDATE_PATH) as SceneScript
	_check(definition != null and definition.scene_id == CANDIDATE and definition.bgm_path == JOURNEY, "actual candidate authors journey-v4")
	evidence = {"scope": "LIMITED_NORMAL_FIELD_BGM_EXIT_LIFECYCLE_NOT_FULL", "audio_source_sha256": AUDIO_SHA, "fixture_sha256": FileAccess.get_sha256(get_script().resource_path), "candidate_sha256": FileAccess.get_sha256(CANDIDATE_PATH), "bgm_sha256": FileAccess.get_sha256(JOURNEY), "renderer": DisplayServer.get_name()}
	if failures == 0:
		# Normal early-game state, not blanked scene/dialog/NPC definitions.
		for singleton: String in ["GameState", "Inventory", "QuestManager", "BountyManager", "InvestigationState", "WeatherManager", "SceneRouter"]:
			root.get_node(singleton).call("reset_for_new_game")
		router.call("go_field_smart", CANDIDATE, definition.player_spawn, "", 14)
		var deadline := Time.get_ticks_msec() + 30000
		var arrived := false
		while Time.get_ticks_msec() < deadline:
			await process_frame
			if bool(root.get_node("LoadingManager").get("_transition_active")): continue
			if not is_instance_valid(current_scene): continue
			var scene_data: Variant = current_scene.get("_current_scene")
			if scene_data is SceneScript and scene_data.scene_id == CANDIDATE and current_scene.get("_player") is Node2D:
				arrived = true
				break
		_check(arrived, "actual authored Field and Player arrived through normal Router/Loading")
		if arrived:
			await create_timer(.25).timeout
			await _observe_and_stop()
	definition = null
	await _finish()

func _observe_and_stop() -> void:
	var audio := root.get_node("AudioManager")
	var player: AudioStreamPlayer = audio.get("bgm_player")
	_check(player != null and player.playing and player.stream is AudioStreamWAV and String(audio.call("get_current_bgm")) == JOURNEY, "normal Field scene-enter truly owns playing journey WAV")
	if player == null or not player.playing or not player.stream is AudioStreamWAV: return
	var stream: AudioStream = player.stream
	var playback: AudioStreamPlayback = player.get_stream_playback()
	_check(playback != null and playback.get_class() == "AudioStreamPlaybackWAV", "actual native WAV playback exists before stop")
	var stream_ref: WeakRef = weakref(stream)
	var playback_ref: WeakRef = weakref(playback) if playback != null else null
	evidence["before"] = {"player_name": String(player.name), "stream_class": stream.get_class(), "stream_path": stream.resource_path, "playback_class": playback.get_class() if playback != null else "ABSENT", "position_seconds": player.get_playback_position(), "playing": player.playing}
	# Nothing in evidence retains the stream/playback; WeakRefs alone survive.
	stream = null
	playback = null
	audio.call("stop_music_sting")
	audio.call("stop_all_sfx")
	audio.call("stop_dialog_audio")
	await audio.call("stop_bgm", 0.0)
	await audio.call("stop_ambience", 0.0)
	# Await real timers plus process/physics boundaries; never delete Audio nodes.
	await create_timer(.20).timeout
	for settle in 8:
		await process_frame
		await physics_frame
	var channels: Array[Dictionary] = []
	for child: Node in audio.get_children():
		if child is AudioStreamPlayer:
			channels.append({"name": String(child.name), "playing": child.playing, "stream_class": child.stream.get_class() if child.stream != null else "NONE"})
			_check(not child.playing, "public stops leave channel stopped: " + String(child.name))
	var a: AudioStreamPlayer = audio.get("_bgm_player_a")
	var b: AudioStreamPlayer = audio.get("_bgm_player_b")
	var sting: AudioStreamPlayer = audio.get("_music_sting_player")
	_check(a.stream == null and b.stream == null and sting.stream == null and String(audio.call("get_current_bgm")).is_empty(), "public BGM/sting stop releases both source slots and context")
	var stream_released := not is_instance_valid(stream_ref.get_ref())
	var playback_released := playback_ref == null or not is_instance_valid(playback_ref.get_ref())
	_check(stream_released and playback_released, "actual journey WAV and native playback WeakRefs released after natural server frames")
	evidence["after"] = {"stream_released": stream_released, "playback_released": playback_released, "channels": channels, "public_apis": ["stop_music_sting", "stop_all_sfx", "stop_dialog_audio", "await stop_bgm(0)", "await stop_ambience(0)"], "natural_settle_seconds": .20, "natural_process_physics_pairs": 8}

func _finish() -> void:
	# Only the diagnostic's own Field is released. AudioManager remains intact.
	var scene: Node = current_scene
	var scene_ref: WeakRef = weakref(scene) if is_instance_valid(scene) else null
	current_scene = null
	if is_instance_valid(scene):
		if scene.get_parent() != null: scene.get_parent().remove_child(scene)
		scene.queue_free()
	scene = null
	for settle in 4:
		await process_frame
		await physics_frame
	_check(scene_ref == null or not is_instance_valid(scene_ref.get_ref()), "owned Field released, Audio autoload untouched")
	var router := root.get_node("SceneRouter")
	router.call("reset_for_new_game")
	router.call("restore_navigation_state", prior_navigation)
	router.set("_active_world_map_scene", prior_world)
	root.get_node("SaveManager").set("active_slot", prior_slot)
	# Custom cursor ownership is unrelated to this audio experiment, but its exit
	# release prevents the known cursor resource from obscuring verbose audio logs.
	var cursors := root.get_node_or_null("CursorManager")
	if cursors != null:
		for pair: Array in [["_arrow", Input.CURSOR_ARROW], ["_hand", Input.CURSOR_POINTING_HAND], ["_wait", Input.CURSOR_WAIT]]:
			Input.set_custom_mouse_cursor(null, int(pair[1]))
			cursors.set(String(pair[0]), null)
	for settle in 3:
		await process_frame
		await physics_frame
	_check(saves_before == _saves(), "15 normal save-file paths retain exact SHA/absence, no save I/O")
	evidence["checks"] = checks
	evidence["failures"] = failures
	evidence["player_saves_unchanged"] = saves_before == _saves()
	var text := JSON.stringify(evidence, "\t")
	var path := output + "audio_lifecycle.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	_check(file != null, "owned audio evidence opens")
	if file != null:
		file.store_string(text)
		file.flush()
		_check(file.get_error() == OK, "audio evidence flush succeeds")
		file.close()
		file = null
		_check(FileAccess.get_file_as_string(path) == text and JSON.parse_string(text) is Dictionary, "audio evidence exact readback")
	print("[AudioExitLifecycle] checks=%d failures=%d output=%s (NOT FULL; verbose shutdown still requires independent reading)" % [checks, failures, output])
	quit(1 if failures > 0 else 0)
