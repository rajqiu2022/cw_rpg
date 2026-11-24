extends SceneTree
## NEW QA live WASAPI counterexamples + untouched >48s positive, NO Field or
## RELEASE credit. Only this test deliberately uses public playback controls.
const OBS = preload("res://tests/helpers/joint_v15_wasapi_operational_bgm_continuity_20261007.gd")
const OBS_SHA: String = "bf7d6c9265b19def36b6b1e4da326694b1c84e75a9eeeb23721128173e5322ca"
const SONG: String = "res://art/audio/bgm/bgm_city_ceremony_v4.wav"
const ALTERNATE: String = "res://art/audio/bgm/bgm_linxi_village_v6.wav"
const SOURCE_PINS: Dictionary = {
	"res://tests/helpers/joint_v15_wasapi_operational_bgm_continuity_20261007.gd":OBS_SHA,
	"res://scripts/autoload/audio_manager.gd":"23f8fe91c0b526eb38722b08969dc40b5e47d1f1cfc99497ce8536b6743d3a5c",
	ALTERNATE:"ca4188ef4fd028ae4ff5b2ce4a7c555e12b4652aa6f58d201bc0708e7d5676b3",
	SONG:"b722c1ddedfc460b316361d3496ea89d16593de8fe904c58a29443325121d279"}
var output: String = ""
var checks: int = 0
var failures: int = 0
var evidence: Array[Dictionary] = []
var manager: Node
var bus: Node

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("[OPERATIONAL LIVE UNIT] "+label)
	return ok

func _hashes() -> Dictionary:
	var result: Dictionary = {}
	for path: String in SOURCE_PINS:
		result[path] = FileAccess.get_sha256(path).to_lower() if FileAccess.file_exists(path) else "MISSING"
	return result


func _players() -> Dictionary:
	var result: Dictionary = {}
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = "user://save_%d.json%s" % [slot, suffix]
			var item: Dictionary = {"exists":FileAccess.file_exists(path)}
			if item.exists:
				var file: FileAccess = FileAccess.open(path, FileAccess.READ)
				item["readable"] = file != null
				if file != null:
					item["bytes"] = file.get_length()
					file.close()
				item["sha256"] = FileAccess.get_sha256(path)
				item["modified_seconds"] = FileAccess.get_modified_time(path)
			result[ProjectSettings.globalize_path(path)] = item
	return result


func _write(name: String, data: Dictionary) -> bool:
	var path: String = output + name
	if output.is_empty() or FileAccess.file_exists(path): return false
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	var encoded: String = JSON.stringify(data, "\t")
	file.store_string(encoded)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	return error == OK and FileAccess.get_file_as_string(path) == encoded and JSON.parse_string(encoded) is Dictionary


func _wait(seconds: float) -> void:
	var start: int = Time.get_ticks_usec()
	while Time.get_ticks_usec()-start < int(seconds*1000000.0): await process_frame

func _fresh() -> AudioStreamPlayer:
	manager.call("resume_after_platform")
	manager.call("stop_bgm",.05)
	await _wait(.15)
	AudioServer.playback_speed_scale = 1.0
	Engine.time_scale = 1.0
	manager.call("play_bgm",SONG,.06,"field")
	await _wait(.3)
	var player: AudioStreamPlayer = manager.get("bgm_player") as AudioStreamPlayer
	if is_instance_valid(player): player.pitch_scale = 1.0
	return player

func _run_case(kind: String) -> void:
	var player: AudioStreamPlayer = await _fresh()
	if not _check(is_instance_valid(player) and player.playing and player.has_stream_playback(),"actual baseline playback before "+kind): return
	var observation: RefCounted = OBS.new()
	var maximum: float = .15 if kind == "finite_budget" else 5.0
	var started: Dictionary = observation.call("begin_observation",self,kind,maximum)
	_check(started.get("ok") == true,"bounded WASAPI initial observation valid:"+kind)
	await _wait(.08)
	# Public APIs deliberately exercised by TEST, never by observer.
	match kind:
		"public_stop": manager.call("stop_bgm",.2)
		"public_restart":
			var position: float = player.get_playback_position()
			player.stop()
			player.play(position)
		"public_seek": player.seek(fmod(player.get_playback_position()+.25,48.0))
		"platform_pause": manager.call("pause_for_platform")
		"pitch": player.pitch_scale = 1.1
		"global_speed": AudioServer.playback_speed_scale = 1.1
		"engine_time": Engine.time_scale = .9
		"same_path_event": bus.emit_signal("bgm_changed",SONG)
		"different_source": manager.call("play_bgm",ALTERNATE,.06,"field")
		"finite_budget": pass
		_:
			_check(false,"unknown actual mutation case")
	# Record the actual mutated state immediately, not after restoring it.
	observation.call("_append_sample")
	await _wait(.3)
	var result: Dictionary = observation.call("finish_observation")
	observation.call("release")
	observation = null
	_check(result.get("ok") == false,"actual counterexample refused:"+kind)
	if kind == "public_restart": _check(result.get("exact_identity") == false,"same-player immediate replay caught by exact playback STRING instance ID")
	if kind == "same_path_event": _check(result.get("bgm_changed_count",0) > 0,"same-path event retained synchronously")
	if kind == "public_seek": _check(result.get("modulo_elapsed_progress") == false,"quarter-second same-instance seek fails adjacent/whole progress")
	if kind == "finite_budget": _check(result.get("errors",[]).has("finite_wall_budget_exhausted"),"real elapsed finite budget exhaustion retained")
	if kind == "different_source": _check(result.get("exact_identity") == false,"real different WAV/player/source identity refused, frozen bytes not edited")
	evidence.append({"case":kind,"started":started,"result":result,"mutation_by_test_only":true})
	_check(_write(kind+".json",evidence[-1]),"raw actual case evidence persisted:"+kind)
	if is_instance_valid(player): player.pitch_scale = 1.0
	AudioServer.playback_speed_scale = 1.0
	Engine.time_scale = 1.0
	manager.call("resume_after_platform")

func _run() -> void:
	_check(OS.get_cmdline_user_args().is_empty(),"no hidden phase or gameplay arguments")
	_check(AudioServer.get_driver_name() == "WASAPI" and FileAccess.get_sha256(OS.get_executable_path()).to_lower() == OBS.EXECUTABLE_SHA,"actual pinned WASAPI engine, no Dummy fallback")
	_check(Engine.time_scale == 1.0 and AudioServer.playback_speed_scale == 1.0,"initial normal1x")
	var before: Dictionary = _hashes()
	var self_sha: String = FileAccess.get_sha256(get_script().resource_path)
	_check(before == SOURCE_PINS,"NEW observer/original AudioManager/song exact source pins")
	manager = root.get_node_or_null("AudioManager")
	bus = root.get_node_or_null("EventBus")
	var save: Node = root.get_node_or_null("SaveManager")
	_check(manager != null and bus != null and save != null and current_scene == null,"normal autoloads, no Field or player fixture")
	if failures > 0: quit(1); return
	var players_before: Dictionary = _players()
	var slot_before: int = int(save.get("active_slot"))
	_check(players_before.size() == 15,"all15 player paths captured")
	for item: Dictionary in players_before.values():
		_check(item.get("exists") == false or (item.get("readable") == true and String(item.get("sha256","")).length() == 64),"each protected existing player file readable and hashed")
	output = "res://build/joint_world_luoyang_20261003_qa/operational_bgm_live_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output) == OK,"unique BUILD-only evidence")
	if failures > 0: quit(1); return
	var player: AudioStreamPlayer = await _fresh()
	_check(is_instance_valid(player) and player.playing and player.has_stream_playback(),"actual unchanged loop baseline")
	var observation: RefCounted = OBS.new()
	var started: Dictionary = observation.call("begin_observation",self,"unchanged_real_49_seconds",60.0)
	_check(started.get("ok") == true,"actual positive initial clock valid")
	await _wait(49.0)
	var positive: Dictionary = observation.call("finish_observation")
	observation.call("release")
	observation = null
	_check(positive.get("ok") == true and float(positive.get("elapsed_sec",0)) > 48.0,"untouched real playback >48s operational positive")
	_check(_write("positive_49_seconds.json",{"started":started,"result":positive}),"all raw49s positive samples persisted")
	for kind: String in ["public_stop","public_restart","public_seek","platform_pause","pitch","global_speed","engine_time","same_path_event","different_source","finite_budget"]:
		await _run_case(kind)
	# Natural final draining, no cancellation or production timer edits.
	await _wait(9.0)
	manager.call("stop_bgm",.15)
	await _wait(.3)
	_check(_hashes() == before and FileAccess.get_sha256(get_script().resource_path) == self_sha,"all original/NEW source and song bytes unchanged")
	_check(_players() == players_before and int(save.get("active_slot")) == slot_before,"all15 files/active slot unchanged, no restoration writes")
	_check(AudioServer.get_driver_name() == "WASAPI" and Engine.time_scale == 1.0 and AudioServer.playback_speed_scale == 1.0,"actual WASAPI normal1x final")
	_check(_write("result.json",{"schema":1,"scope":"ACTUAL_WASAPI_OPERATIONAL_POSITIVE_NEGATIVES_NO_FIELD_NOT_RELEASE","checks":checks,"failures":failures,"observer_sha256":OBS_SHA,"entry_sha256":self_sha,"actual_audio_driver":AudioServer.get_driver_name(),"actual_executable_sha256":FileAccess.get_sha256(OS.get_executable_path()),"output":output,"positive":positive,"cases":evidence,"source_before":before,"source_after":_hashes(),"players_before":players_before,"players_after":_players(),"active_slot_before":slot_before,"active_slot_after":save.get("active_slot"),"source_version_equivalence_proven":false,"DAC_continuity_proven":false,"release_complete":false,"formal_cutover":false}),"final result persisted")
	print("OPERATIONAL_BGM_LIVE: %d/%d; output=%s; no Field/RELEASE/DAC credit" % [checks,failures,output])
	quit(0 if failures == 0 else 1)

