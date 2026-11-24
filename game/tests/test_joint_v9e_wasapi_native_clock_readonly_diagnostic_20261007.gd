extends SceneTree
## QA raw clock collection ONLY. No Field, original observer, RELEASE entry,
## navigation fixture, save load/write, clock tolerance, fit or acceptance.
## Uses public AudioManager playback and natural public cleanup only.
const SCOPE: String = "WASAPI_RAW_NATIVE_CLOCK_60_SECONDS_NO_FIELD_NOT_CONTINUITY_ACCEPTANCE"
const SONG: String = "res://art/audio/bgm/bgm_city_ceremony_v4.wav"
const DURATION_USEC: int = 60000000
const SAMPLE_INTERVAL_USEC: int = 50000
const MAX_SAMPLES: int = 1500
const SOURCE_PINS: Dictionary = {
	"res://tests/test_joint_world_luoyang_v15_release_20261005.gd":"890dcee53610ba7ccf47d3b79f7104b437cf4bef724bbf18df9f3e9b9d101c84",
	"res://tests/helpers/joint_v15_looped_bgm_continuity.gd":"28252849ab92aee8e687bf4372d24c7f369b6c13fc51180510a1b3e00d6563a3",
	"res://scripts/autoload/audio_manager.gd":"23f8fe91c0b526eb38722b08969dc40b5e47d1f1cfc99497ce8536b6743d3a5c",
	SONG:"b722c1ddedfc460b316361d3496ea89d16593de8fe904c58a29443325121d279",
	"res://data/scenes/world_map_jianghu.tres":"838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015",
	"res://data/scenes/ch4_s0_luoyang_gate.tres":"b967c347e745e6f05d51a8f596fde4744571f5d459279467c706e66d9be24bd1",
	"res://data/scenes/ch4_s1_luoyang_yamen.tres":"7bed5d322d583c9c7bf4e392f3f4c75ffb0577db24bb9e6237a4ae3aa0808b01",
	"res://data/scenes/ch4_s2_canal_docks.tres":"81850afd0877bba70e2ed0786fe4e81570faee8e06e827561349988f9c4d41a5",
	"res://data/scenes/ch4_s3_luoyang_market.tres":"5cd76d0c0a0c54358f50b341186c5ea078a7d20657c97dc15ef15027755661ab",
	"res://data/config/outskirts_native_adoption.json":"203c9f08e941908ace3e8d56e18a15963e3a60859c04741b04e28a968386d0ff",
}
var manager: Node
var bus: Node
var output: String = ""
var checks: int = 0
var failures: int = 0
var events: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var source_before: Dictionary = {}
var players_before: Dictionary = {}
var slot_before: int = -1
var self_sha: String = ""

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("[RAW WASAPI CLOCK DIAGNOSTIC] " + label)
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

func _changed(path: String) -> void:
	events.append({"ticks_usec":Time.get_ticks_usec(), "path":path})

func _value(value: float) -> Variant:
	# Preserve nonfinite failures visibly, never JSON-null or silently discard.
	return value if is_finite(value) else str(value)

func _identity() -> Dictionary:
	var player: AudioStreamPlayer = manager.get("bgm_player") as AudioStreamPlayer
	if not is_instance_valid(player) or player.stream == null: return {"available":false}
	var stream: AudioStream = player.stream
	var playback: AudioStreamPlayback = player.get_stream_playback() if player.has_stream_playback() else null
	var row: Dictionary = {"available":true, "ticks_usec":Time.get_ticks_usec(),
		"manager_id":str(manager.get_instance_id()), "player_id":str(player.get_instance_id()),
		"stream_id":str(stream.get_instance_id()), "has_stream_playback":playback != null,
		"playback_id":str(playback.get_instance_id()) if playback != null else "MISSING",
		"stream_path":stream.resource_path, "stream_class":stream.get_class(),
		"path":String(manager.get("_current_bgm_path")), "context":String(manager.get("_current_bgm_context")),
		"request_id":int(manager.get("_bgm_request_id")), "stop_pending":bool(manager.get("_bgm_stop_pending")),
		"playing":player.playing, "paused":player.stream_paused, "pitch_scale":player.pitch_scale,
		"global_speed_scale":AudioServer.playback_speed_scale, "engine_time_scale":Engine.time_scale,
		"stream_length_sec":stream.get_length(), "actual_audio_driver":AudioServer.get_driver_name()}
	if stream is AudioStreamWAV:
		var wav: AudioStreamWAV = stream as AudioStreamWAV
		row.merge({"source_mix_rate_hz":wav.mix_rate, "loop_mode":wav.loop_mode,
			"loop_begin_frame":wav.loop_begin, "loop_end_frame":wav.loop_end})
	return row

func _sample() -> Dictionary:
	var identity_before: Dictionary = _identity()
	var player: AudioStreamPlayer = manager.get("bgm_player") as AudioStreamPlayer
	if not is_instance_valid(player): return {"identity_before":identity_before, "clock_available":false, "ticks_usec":Time.get_ticks_usec()}
	# No AudioServer lock, retry, filtering, hash or per-sample latency query.
	# Every public read is independently enclosed by monotonic microsecond ticks.
	var t0: int = Time.get_ticks_usec()
	var p0: float = player.get_playback_position()
	var t1: int = Time.get_ticks_usec()
	var s0: float = AudioServer.get_time_since_last_mix()
	var t2: int = Time.get_ticks_usec()
	var u0: float = AudioServer.get_time_to_next_mix()
	var t3: int = Time.get_ticks_usec()
	var p1: float = player.get_playback_position()
	var t4: int = Time.get_ticks_usec()
	var s1: float = AudioServer.get_time_since_last_mix()
	var t5: int = Time.get_ticks_usec()
	var u1: float = AudioServer.get_time_to_next_mix()
	var t6: int = Time.get_ticks_usec()
	return {"ticks_usec":t6, "clock_available":true, "identity_before":identity_before,
		"identity_after":_identity(), "read_ticks_usec":[t0,t1,t2,t3,t4,t5,t6], "read_span_usec":t6-t0,
		"read_order":["P_before","since_before","until_before","P_after","since_after","until_after"],
		"position_before_sec":_value(p0), "position_after_sec":_value(p1),
		"since_before_sec":_value(s0), "since_after_sec":_value(s1), "until_before_sec":_value(u0), "until_after_sec":_value(u1),
		"native_float64_bytes_hex":[PackedFloat64Array([p0]).to_byte_array().hex_encode(),PackedFloat64Array([s0]).to_byte_array().hex_encode(),PackedFloat64Array([u0]).to_byte_array().hex_encode(),PackedFloat64Array([p1]).to_byte_array().hex_encode(),PackedFloat64Array([s1]).to_byte_array().hex_encode(),PackedFloat64Array([u1]).to_byte_array().hex_encode()],
		"all_clock_reads_finite":is_finite(p0) and is_finite(p1) and is_finite(s0) and is_finite(s1) and is_finite(u0) and is_finite(u1)}

func _environment() -> Dictionary:
	return {"engine_version_info":Engine.get_version_info(), "actual_audio_driver":AudioServer.get_driver_name(),
		"engine_executable_path":OS.get_executable_path(), "engine_executable_sha256":FileAccess.get_sha256(OS.get_executable_path()),
		"display_driver":DisplayServer.get_name(),
		"output_device":AudioServer.output_device, "output_devices":AudioServer.get_output_device_list(),
		"output_mix_rate_hz":AudioServer.get_mix_rate(), "output_latency_sec":AudioServer.get_output_latency(),
		"engine_time_scale":Engine.time_scale, "global_speed_scale":AudioServer.playback_speed_scale,
		"upstream_tag_commit":"001aa128b1cd80dc4e47e823c360bccf45ed6bad",
		"installed_banner_commit_NOT_mapped_to_official_tag":"71f334935",
		"source_constants_hypothesis_only":{"output_block_frames":512,"resampled_source_prefetch_frames":128},
		"source_version_equivalence_proven":false, "runtime_block_constants_reflected":false}

func _run() -> void:
	_check(OS.get_cmdline_user_args().is_empty(), "no arguments or hidden gameplay modes")
	_check(AudioServer.get_driver_name() == "WASAPI", "actual WASAPI, no silent Dummy fallback")
	_check(Engine.time_scale == 1.0 and AudioServer.playback_speed_scale == 1.0, "unaltered ordinary1x clocks")
	source_before = _hashes()
	_check(source_before == SOURCE_PINS, "exact original audio/entry/observer/song and six formal baseline bytes")
	self_sha = FileAccess.get_sha256(get_script().resource_path)
	manager = root.get_node_or_null("AudioManager")
	bus = root.get_node_or_null("EventBus")
	var save: Node = root.get_node_or_null("SaveManager")
	_check(manager != null and bus != null and save != null and current_scene == null, "normal autoloads, standalone diagnostic without Field")
	if failures > 0: quit(1); return
	players_before = _players()
	slot_before = int(save.get("active_slot"))
	_check(players_before.size() == 15 and self_sha.length() == 64, "all15 protected player paths and actual diagnostic source captured")
	for item: Dictionary in players_before.values():
		_check(item.get("exists") == false or (item.get("readable") == true and String(item.get("sha256", "")).length() == 64), "each existing protected player file readable and hashed")
	if failures > 0: quit(1); return
	output = "res://build/joint_world_luoyang_20261003_qa/wasapi_raw_clock_60_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output) == OK, "new exclusive evidence directory")
	if failures > 0: quit(1); return
	var environment_before: Dictionary = _environment()
	bus.connect("bgm_changed", _changed)
	# Public production route; no private player.play/seek/pause or stream edits.
	manager.call("play_bgm", SONG, .18, "field")
	var wait_start: int = Time.get_ticks_usec()
	while Time.get_ticks_usec()-wait_start < 5000000:
		var initial: Dictionary = _identity()
		if initial.get("playing") == true and initial.get("has_stream_playback") == true: break
		await process_frame
	var initial_identity: Dictionary = _identity()
	_check(initial_identity.get("available") == true and initial_identity.get("playing") == true and initial_identity.get("has_stream_playback") == true and initial_identity.get("stream_path") == SONG and initial_identity.get("path") == SONG, "public original WAV playback actually available")
	_check(initial_identity.get("source_mix_rate_hz") == 22050 and initial_identity.get("loop_begin_frame") == 0 and initial_identity.get("loop_end_frame") == 1058400 and initial_identity.get("loop_mode") == AudioStreamWAV.LOOP_FORWARD, "actual original22050Hz48second loop metadata")
	var observation_start: int = Time.get_ticks_usec()
	var event_start_count: int = events.size()
	print("RAW_WASAPI_CLOCK_BEGIN: output=%s driver=%s rate=%s;60s normal1x; NO_CONTINUITY_ACCEPTANCE" % [output,AudioServer.get_driver_name(),environment_before.output_mix_rate_hz])
	if failures == 0:
		samples.append(_sample())
		while Time.get_ticks_usec()-observation_start < DURATION_USEC and samples.size() < MAX_SAMPLES:
			await process_frame
			if Time.get_ticks_usec()-int(samples[-1].ticks_usec) >= SAMPLE_INTERVAL_USEC:
				samples.append(_sample())
		samples.append(_sample())
	var observation_end: int = Time.get_ticks_usec()
	var final_identity: Dictionary = _identity()
	var environment_after: Dictionary = _environment()
	_check(failures > 0 or (observation_end-observation_start >= DURATION_USEC and samples.size() < MAX_SAMPLES), "finite60s diagnostic collection completed without sample budget exhaustion")
	var immediate: Dictionary = {"schema":1,"scope":SCOPE,"engine_pid":OS.get_process_id(),"output":output,
		"diagnostic_source_sha256":self_sha,"source_pins_before":source_before,"players_before":players_before,
		"players_immediately_after":_players(),"active_slot_before":slot_before,"active_slot_immediately_after":save.get("active_slot"),
		"environment_before":environment_before,"environment_after":environment_after,
		"initial_identity":initial_identity,"final_identity":final_identity,"events":events.duplicate(true),"event_count_at_observation_start":event_start_count,
		"observation_start_usec":observation_start,"observation_end_usec":observation_end,"elapsed_usec":observation_end-observation_start,
		"sample_interval_usec":SAMPLE_INTERVAL_USEC,"samples":samples,"sample_count":samples.size(),
		"invalid_negative_until_filtered":false,"clock_fit_performed":false,"clock_tolerance_evaluated":false,
		"continuity_passed":false,"continuity_approved":false,"full_city_executed":false,"full_world_executed":false,"release_complete":false,"formal_cutover":false,
		"limitations":"Raw public unlocked API observations only; source512/128 constants are upstream hypothesis, not reflected installed-binary proof. WAV loop_count not used. No mathematical continuity verdict or physical listening claim."}
	_check(_write("raw_clock_before_cleanup.json", immediate), "every raw sample retained immediately before natural cleanup")
	if bus.is_connected("bgm_changed", _changed): bus.disconnect("bgm_changed", _changed)
	# Natural lifecycle after persistence; no private cache/timer cancellation.
	var grace_start: int = Time.get_ticks_usec()
	while Time.get_ticks_usec()-grace_start < 9000000: await process_frame
	manager.call("stop_bgm", .15)
	await create_timer(.25).timeout
	_check(_hashes() == source_before and FileAccess.get_sha256(get_script().resource_path) == self_sha, "all source/song/formal and diagnostic bytes unchanged")
	_check(_players() == players_before and int(save.get("active_slot")) == slot_before, "all15 player files and active_slot unchanged; no restoration writes")
	_check(AudioServer.get_driver_name() == "WASAPI" and Engine.time_scale == 1.0 and AudioServer.playback_speed_scale == 1.0, "actual WASAPI and ordinary1x unchanged")
	_check(_write("result.json", {"schema":1,"scope":SCOPE,"checks":checks,"failures":failures,"output":output,
		"diagnostic_source_sha256":self_sha,"source_pins_after":_hashes(),"players_after":_players(),"active_slot_after":save.get("active_slot"),
		"sample_count":samples.size(),"actual_audio_driver":AudioServer.get_driver_name(),"cleanup_natural_grace_usec":Time.get_ticks_usec()-grace_start,
		"public_stop_bgm_requested":true,"private_audio_mutated":false,"clock_fit_performed":false,"clock_tolerance_evaluated":false,
		"diagnostic_collection_only":true,"continuity_passed":false,"continuity_approved":false,"release_complete":false,"formal_cutover":false}), "final diagnostic execution evidence saved")
	print("RAW_WASAPI_CLOCK_END: %d checks/%d failures; samples=%d; output=%s; diagnostic ONLY, continuity NOT evaluated" % [checks,failures,samples.size(),output])
	quit(0 if failures == 0 else 1)
