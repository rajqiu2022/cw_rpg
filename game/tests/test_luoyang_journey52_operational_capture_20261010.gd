extends SceneTree
## NEW >52s normal AudioManager request/counter observation only. No Field,
## portal, listener/DAC/visual, gameplay/full-six/approval/cutover credit.
const OBS = preload("res://tests/helpers/luoyang_wasapi_authored48_journey52_continuity_20261010.gd")
const OBS_PATH: String = "res://tests/helpers/luoyang_wasapi_authored48_journey52_continuity_20261010.gd"
const OBS_SHA: String = "6ef8906708f3f12cda59e53a65a98aa4f328d1a30eafa732f9d1829517af1019"
const SONG: String = "res://art/audio/bgm/bgm_jianghu_journey_v4.wav"
const SOURCE_PINS: Dictionary = {
	OBS_PATH:OBS_SHA,
	"res://tests/helpers/joint_v15_wasapi_operational_bgm_continuity_20261007.gd":"bf7d6c9265b19def36b6b1e4da326694b1c84e75a9eeeb23721128173e5322ca",
	SONG:"4e52dfafc8555bbdace7c1e6aa95b5511c606105ee6d95fb35a1d9e68fbad236",
	SONG+".import":"a5e38767b210c0c3715d29fd830f384f21a172e0f16326193cdbaa7a3ef87160",
	"res://.godot/imported/bgm_jianghu_journey_v4.wav-1a8101cf096c312ce6ccb65a31d34571.sample":"7768db05905c545a788e0357d34b0d830561df49549eb973a0433395a12d3b53",
	"res://scripts/autoload/audio_manager.gd":"23f8fe91c0b526eb38722b08969dc40b5e47d1f1cfc99497ce8536b6743d3a5c",
	"res://scripts/autoload/event_bus.gd":"c42bdb64161dfec0aa7e65e6027b0b335dee358f84558068abb54ccd26785db8",
	"res://scripts/autoload/platform_bridge.gd":"eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a",
	"res://scripts/autoload/save_manager.gd":"67c06cd14d6a7c0bbfd7467bbaae84f906aad57b19cabc0902baf80eb3aff7d9",
	"res://data/scenes/world_map_jianghu.tres":"838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015",
	"res://data/maps/luoyang_v3_legacy/ch4_s2_canal_docks_scene.tres":"81850afd0877bba70e2ed0786fe4e81570faee8e06e827561349988f9c4d41a5"}
var checks: int = 0
var failures: int = 0
var output: String = ""
var observer: RefCounted
var source_before: Dictionary = {}
var players_before: Dictionary = {}
var slot_before: Variant
var started: Dictionary = {}
var observed: Dictionary = {}
var bridge: Node
var manager: Node
var save: Node

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("[JOURNEY52 DIAGNOSTIC] "+label)
	return ok

func fixture_sources() -> Array[String]:
	var paths: Array[String] = [get_script().resource_path]
	for path: String in SOURCE_PINS: paths.append(path)
	return paths

func _file(path: String) -> Dictionary:
	var row: Dictionary = {"exists":FileAccess.file_exists(path)}
	if row.exists:
		var file: FileAccess = FileAccess.open(path,FileAccess.READ)
		row["readable"] = file != null
		if file != null:
			row["bytes"] = file.get_length()
			file.close()
		row["sha256"] = FileAccess.get_sha256(path).to_lower()
		row["modified_seconds"] = FileAccess.get_modified_time(path)
	return row

func _sources() -> Dictionary:
	var result: Dictionary = {}
	for path: String in fixture_sources(): result[path] = _file(path)
	return result

func _players() -> Dictionary:
	var result: Dictionary = {}
	for slot in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String = "user://save_%d.json%s" % [slot,suffix]
			result[path] = _file(path)
	return result

func _wait(seconds: float) -> void:
	var start: int = Time.get_ticks_usec()
	while Time.get_ticks_usec()-start < int(seconds*1000000.0): await process_frame

func _write(name: String, data: Dictionary) -> bool:
	if output.is_empty() or FileAccess.file_exists(output+name): return false
	var file: FileAccess = FileAccess.open(output+name,FileAccess.WRITE)
	if file == null: return false
	var encoded: String = JSON.stringify(data,"\t",true)
	file.store_string(encoded)
	file.flush()
	var ok: bool = file.get_error() == OK
	file.close()
	return ok and FileAccess.get_file_as_string(output+name) == encoded and JSON.parse_string(encoded) is Dictionary

func _run() -> void:
	bridge = root.get_node_or_null("PlatformBridge")
	manager = root.get_node_or_null("AudioManager")
	save = root.get_node_or_null("SaveManager")
	if not _check(bridge != null and manager != null and save != null and current_scene == null,"normal autoloads only; no Field/current scene"):
		quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true,"public checkpoint held BEFORE first await and through quit")
	_check(OS.get_cmdline_user_args() == PackedStringArray(["--luoyang-journey52-readonly-diagnostic"]),"exact explicit diagnostic mode; not candidate/full")
	_check(AudioServer.get_driver_name() == "WASAPI" and FileAccess.get_sha256(OS.get_executable_path()).to_lower() == OBS.EXECUTABLE_SHA,"actual pinned installed executable and WASAPI, no fallback")
	_check(Engine.time_scale == 1.0 and AudioServer.playback_speed_scale == 1.0,"normal1x clock units")
	source_before = _sources()
	for path: String in SOURCE_PINS:
		_check(source_before[path].get("readable") == true and source_before[path].get("sha256") == SOURCE_PINS[path],"actual pinned consumed source:"+path)
	players_before = _players()
	slot_before = save.get("active_slot")
	_check(players_before.size() == 15 and typeof(slot_before) == TYPE_INT,"15 players and original active slot captured; external prelaunch exactUTCtick guard required")
	output = "res://build/joint_world_luoyang_20261003_qa/journey52_operational_capture_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output) == OK,"NEW unique BUILD only"):
		quit(1); return
	if failures == 0:
		# Only normal public request BEFORE observation, no private player control.
		manager.call("play_bgm",SONG,.18,"field")
		await _wait(.4)
		var player: AudioStreamPlayer = manager.get("bgm_player") as AudioStreamPlayer
		if _check(player != null and player.playing and player.has_stream_playback(),"normal request actual WAV playback"):
			observer = OBS.new()
			started = observer.call("begin_observation",self,"normal_journey52_request_uninterrupted_53_seconds",60.0)
			_check(started.get("ok") == true,"initial exact52 identity and clock valid")
			if started.get("ok") == true:
				await _wait(53.0)
				observed = observer.call("finish_observation")
				_check(observed.get("ok") == true and float(observed.get("elapsed_sec",0)) > 52.0,"actual unchanged >52s whole+all adjacent engineering observation")
				_check(observed.get("period_domain",{}).get("kind") == "EXACT_SHA_BOUND_JOURNEY52","actual source-bound domain receipt, not merely a fake period")
			observer.call("release")
			observer = null
	for tick in 8: await process_frame
	_check(_sources() == source_before,"first/last consumed source bytes/SHA/seconds unchanged")
	_check(_players() == players_before and save.get("active_slot") == slot_before,"15 normal paths/SHA/bytes/seconds/active slot unchanged; no restoration writes")
	_check(bridge.call("is_checkpoint_saves_suspended") == true,"checkpoint not restored with test process fixture")
	_check(AudioServer.get_driver_name() == "WASAPI" and FileAccess.get_sha256(OS.get_executable_path()).to_lower() == OBS.EXECUTABLE_SHA and Engine.time_scale == 1.0 and AudioServer.playback_speed_scale == 1.0,"end actual WASAPI/installed executable/1x identity")
	_check(_write("result.json",{"scope":"ACTUAL_JOURNEY52_OPERATIONAL_OBSERVATION_NOT_FIELD_FERRY_OR_APPROVAL","checks":checks,"failures":failures,"started":started,"observation":observed,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"active_slot_before":slot_before,"active_slot_after":save.get("active_slot"),"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"checkpoint_suspension":{"before_any_await":true,"restored_before_exit":false},"exact_player_UTC_ticks_credit":"EXTERNAL_FRESH_PRELAUNCH_WRAPPER_REQUIRED","full_dynamic_startup_guard_credit":"EXTERNAL_FRESH_PATHS_REQUIRED","field_credit":false,"ferry_credit":false,"release_complete":false,"formal_approved":false,"DAC_continuity_proven":false}),"complete raw observation and readback persisted")
	print("JOURNEY52_DIAGNOSTIC %sresult.json checks=%d failures=%d; no Field/ferry/RELEASE/approval" % [output,checks,failures])
	quit(0 if failures == 0 else 1)

