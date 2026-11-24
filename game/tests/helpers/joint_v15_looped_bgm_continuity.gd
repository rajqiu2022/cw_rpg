extends RefCounted
## QA-owned observation only: call begin_observation immediately BEFORE normal
## portal input, then finish_observation AFTER the actual destination is ready.
## Never plays/seeks/stops audio, injects events, or changes a production timer.
const SCOPE: String = "OBSERVED_NORMAL_BOUNDARY_LOOPED_BGM_CONTINUITY_NOT_JOINT_FULL"
const SAMPLE_INTERVAL_USEC: int = 50000
const MAX_SAMPLES: int = 4096
var owner: SceneTree
var bus: Node
var manager: Node
var active: bool = false
var label: String = ""
var limit_usec: int = 0
var samples: Array[Dictionary] = []
var events: Array[Dictionary] = []
var errors: Array[String] = []
var last_sample_ticks: int = 0
var source_hash_cache: Dictionary = {}

func begin_observation(tree: SceneTree, case_label: String, maximum_seconds: float = 120.0) -> Dictionary:
	if active: return {"ok": false, "reason": "observation_already_active"}
	release()
	samples.clear()
	events.clear()
	errors.clear()
	source_hash_cache.clear()
	label = case_label
	if tree == null or not is_finite(maximum_seconds) or maximum_seconds <= 0 or maximum_seconds > 180:
		return {"ok": false, "reason": "invalid_owner_or_explicit_finite_budget"}
	owner = tree
	bus = owner.root.get_node_or_null("EventBus")
	manager = owner.root.get_node_or_null("AudioManager")
	if not is_instance_valid(bus) or not is_instance_valid(manager) or not bus.has_signal("bgm_changed"):
		release()
		return {"ok": false, "reason": "missing_normal_autoloads"}
	limit_usec = int(maximum_seconds * 1000000.0)
	# Connect first, so a synchronous action cannot escape the observation.
	bus.connect("bgm_changed", Callable(self, "_changed"))
	owner.process_frame.connect(_observe_frame)
	active = true
	_append_sample()
	if not bool(samples[0].get("valid", false)):
		errors.append("invalid_initial_audio_state")
		release()
	return {"ok": errors.is_empty(), "scope": SCOPE, "label": label, "before": samples[0].duplicate(true), "maximum_seconds": maximum_seconds}

func _changed(path: String) -> void:
	if active:
		events.append({"ticks_usec": Time.get_ticks_usec(), "path": path})

func _observe_frame() -> void:
	if not active: return
	if Time.get_ticks_usec() - last_sample_ticks >= SAMPLE_INTERVAL_USEC: _append_sample()

func _append_sample() -> void:
	if samples.size() >= MAX_SAMPLES:
		if not errors.has("sample_budget_exhausted"): errors.append("sample_budget_exhausted")
		return
	var row: Dictionary = _snapshot()
	samples.append(row)
	last_sample_ticks = int(row.get("ticks_usec", Time.get_ticks_usec()))
	if samples.size() > 1 and last_sample_ticks - int(samples[0].ticks_usec) > limit_usec:
		if not errors.has("finite_wall_budget_exhausted"): errors.append("finite_wall_budget_exhausted")

func _snapshot() -> Dictionary:
	var row: Dictionary = {"valid": false, "ticks_usec": Time.get_ticks_usec()}
	if not is_instance_valid(manager): return row
	var player: AudioStreamPlayer = manager.get("bgm_player") as AudioStreamPlayer
	if not is_instance_valid(player) or player.stream == null: return row
	var stream: AudioStream = player.stream
	# This predicate is deliberately scoped to the actually authored looping WAV;
	# unknown playback/loop contracts fail closed rather than guessing a period.
	if not stream is AudioStreamWAV: return row
	var wav: AudioStreamWAV = stream as AudioStreamWAV
	if wav.mix_rate <= 0 or wav.loop_mode != AudioStreamWAV.LOOP_FORWARD or wav.loop_begin < 0 or wav.loop_end <= wav.loop_begin: return row
	if not AudioServer.has_method("get_time_since_last_mix") or not AudioServer.has_method("get_time_to_next_mix"): return row
	var read_start: int = Time.get_ticks_usec()
	var position: float = player.get_playback_position()
	var since_mix: float = AudioServer.get_time_since_last_mix()
	var until_mix: float = AudioServer.get_time_to_next_mix()
	var read_end: int = Time.get_ticks_usec()
	var quantum: float = since_mix + until_mix
	var loop_begin: float = float(wav.loop_begin) / float(wav.mix_rate)
	var loop_end: float = float(wav.loop_end) / float(wav.mix_rate)
	var period: float = loop_end - loop_begin
	var path: String = String(manager.get("_current_bgm_path"))
	var stream_path: String = stream.resource_path
	if not source_hash_cache.has(stream_path):
		source_hash_cache[stream_path] = FileAccess.get_sha256(stream_path) if FileAccess.file_exists(stream_path) else "MISSING"
	var global_speed: float = float(AudioServer.get("playback_speed_scale"))
	var finite: bool = is_finite(position) and is_finite(since_mix) and is_finite(until_mix) and is_finite(quantum) and is_finite(period)
	var clock_valid: bool = finite and since_mix >= 0 and until_mix >= 0 and quantum > 0 and quantum <= .25 and period > 0 and loop_end <= stream.get_length()+1.0/float(wav.mix_rate)
	row.merge({"valid": clock_valid and not path.is_empty() and FileAccess.file_exists(stream_path), "ticks_usec": read_end,
		"read_start_usec": read_start, "read_end_usec": read_end, "read_span_sec": float(read_end-read_start)/1000000.0,
		"path": path, "player_id": player.get_instance_id(), "stream_id": stream.get_instance_id(), "stream_path": stream_path,
		"stream_source_sha256": source_hash_cache[stream_path], "stream_class": stream.get_class(),
		"request_id": int(manager.get("_bgm_request_id")), "stop_pending": bool(manager.get("_bgm_stop_pending")),
		"playing": player.playing, "paused": player.stream_paused, "pitch_scale": player.pitch_scale, "global_speed_scale": global_speed,
		"position_sec": position, "stream_length_sec": stream.get_length(), "mix_rate_hz": wav.mix_rate,
		"loop_begin_frame": wav.loop_begin, "loop_end_frame": wav.loop_end, "loop_begin_sec": loop_begin,
		"loop_end_sec": loop_end, "loop_period_sec": period, "since_last_mix_sec": since_mix, "until_next_mix_sec": until_mix,
		"observed_mix_quantum_sec": quantum}, true)
	return row

func finish_observation() -> Dictionary:
	if not active: return {"ok": false, "scope": SCOPE, "reason": "no_active_observation"}
	_append_sample()
	# No signal callback/Node/stream reference is retained in the evidence.
	release()
	var identity_ok: bool = samples.size() >= 2
	var no_stop: bool = samples.size() >= 2
	var progress_ok: bool = samples.size() >= 2
	var edges: Array[Dictionary] = []
	var first: Dictionary = samples[0]
	var source_hashes_after: Dictionary = {}
	for source_path: String in source_hash_cache:
		source_hashes_after[source_path] = FileAccess.get_sha256(source_path) if FileAccess.file_exists(source_path) else "MISSING"
	var source_unchanged: bool = source_hash_cache == source_hashes_after and not source_hash_cache.values().has("MISSING")
	var elapsed: float = float(int(samples[-1].ticks_usec)-int(first.ticks_usec))/1000000.0
	for row: Dictionary in samples:
		var same: bool = bool(row.get("valid", false)) and bool(first.get("valid", false))
		for key: String in ["path", "player_id", "stream_id", "stream_path", "stream_source_sha256", "request_id", "stream_length_sec", "mix_rate_hz", "loop_begin_frame", "loop_end_frame"]:
			same = same and row.get(key) == first.get(key)
		identity_ok = identity_ok and same
		no_stop = no_stop and bool(row.get("playing", false)) and not bool(row.get("paused", true)) and not bool(row.get("stop_pending", true))
		# Normal-speed continuity only. A different supported rate needs its own
		# explicit contract, not a fitted coefficient hiding a restart/stop.
		progress_ok = progress_ok and float(row.get("pitch_scale", 0)) == 1.0 and float(row.get("global_speed_scale", 0)) == 1.0
	for index in range(1, samples.size()):
		var edge: Dictionary = _progress_edge(samples[index-1], samples[index])
		edges.append(edge)
		progress_ok = progress_ok and bool(edge.get("ok", false))
	var whole_edge: Dictionary = _progress_edge(first, samples[-1])
	progress_ok = progress_ok and bool(whole_edge.get("ok", false)) and elapsed > 0 and elapsed <= float(limit_usec)/1000000.0
	return {"schema": 1, "scope": SCOPE, "label": label,
		"ok": errors.is_empty() and identity_ok and source_unchanged and no_stop and events.is_empty() and progress_ok,
		"exact_identity": identity_ok, "all_observed_states_playing_unpaused_no_pending_stop": no_stop,
		"bgm_changed_count": events.size(), "bgm_changed_events": events.duplicate(true), "modulo_elapsed_progress": progress_ok,
		"elapsed_sec": elapsed, "maximum_duration_sec": float(limit_usec)/1000000.0,
		"sample_count": samples.size(), "sample_interval_usec": SAMPLE_INTERVAL_USEC, "errors": errors.duplicate(),
		"samples": samples.duplicate(true), "adjacent_progress_edges": edges, "whole_observation_progress": whole_edge,
		"source_sha256_before": source_hash_cache.duplicate(), "source_sha256_after": source_hashes_after, "source_bytes_unchanged": source_unchanged,
		"tolerance_basis": "Two endpoint measured audio mix quanta + endpoint read spans + two source sample periods + 2 microseconds timestamp granularity; no pixel tolerance and no fitted playback speed.",
		"limitations": "Finite process-frame observations plus synchronous bgm_changed/request identity; not a continuous mixer-thread trace. Whole-period silent seek indistinguishability is not claimed away.",
		"audio_mutated_by_helper": false, "normal_input_executed_by_helper": false, "visual_approved": false}

func _progress_edge(before: Dictionary, after: Dictionary) -> Dictionary:
	if not bool(before.get("valid", false)) or not bool(after.get("valid", false)): return {"ok": false, "reason": "invalid_snapshot"}
	var period: float = float(before.loop_period_sec)
	var elapsed: float = float(int(after.ticks_usec)-int(before.ticks_usec))/1000000.0
	if period <= 0 or elapsed <= 0: return {"ok": false, "reason": "invalid_period_or_elapsed"}
	var raw_delta: float = float(after.position_sec)-float(before.position_sec)
	var wraps: int = roundi((elapsed-raw_delta)/period)
	var unfolded: float = raw_delta + float(wraps)*period
	var tolerance: float = float(before.observed_mix_quantum_sec)+float(after.observed_mix_quantum_sec)+float(before.read_span_sec)+float(after.read_span_sec)+2.0/float(before.mix_rate_hz)+.000002
	var error: float = unfolded-elapsed
	# A massive audio quantum cannot silently permit arbitrary discontinuity.
	var resolution_valid: bool = tolerance < period*.01
	return {"ok": resolution_valid and wraps >= 0 and unfolded >= 0 and absf(error) <= tolerance,
		"before_ticks_usec": before.ticks_usec, "after_ticks_usec": after.ticks_usec,
		"elapsed_sec": elapsed, "raw_position_delta_sec": raw_delta, "inferred_wrap_count": wraps,
		"actual_loop_period_sec": period, "unfolded_progress_sec": unfolded, "progress_error_sec": error,
		"audio_timing_tolerance_sec": tolerance, "resolution_valid": resolution_valid,
		"before_mix_quantum_sec": before.observed_mix_quantum_sec, "after_mix_quantum_sec": after.observed_mix_quantum_sec}

func release() -> void:
	active = false
	if is_instance_valid(bus) and bus.is_connected("bgm_changed", Callable(self, "_changed")):
		bus.disconnect("bgm_changed", Callable(self, "_changed"))
	if owner != null and owner.process_frame.is_connected(_observe_frame): owner.process_frame.disconnect(_observe_frame)
	bus = null
	manager = null
	owner = null
