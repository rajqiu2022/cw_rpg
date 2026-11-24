extends RefCounted
## QA-owned observation only: call begin_observation immediately BEFORE normal
## portal input, then finish_observation AFTER the actual destination is ready.
## Never plays/seeks/stops audio, injects events, or changes a production timer.
## Explicit installed-binary operational engineering model, NOT source-equivalence
## proof, continuous mixer trace or DAC/listening continuity. Unknown backend fails.
const SCOPE: String = "WASAPI_OPERATIONAL_BGM_CONTINUITY_NOT_DAC_OR_EXACT_SOURCE_PROOF"
const EXECUTABLE_SHA: String = "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const OUTPUT_BLOCK_FRAMES: int = 512
const SOURCE_PREFETCH_FRAMES: int = 128
const RESAMPLER_PHASE_STEPS: int = 65536
const TIMESTAMP_GRANULARITY_SEC: float = .000002
const IDENTITY_KEYS: Array[String] = ["manager_id", "player_id", "stream_id", "playback_id", "path", "stream_path", "stream_source_sha256", "stream_class", "request_id", "stream_length_sec", "mix_rate_hz", "loop_mode", "loop_begin_frame", "loop_end_frame", "loop_period_sec", "actual_audio_driver", "output_mix_rate_hz", "output_device", "output_latency_sec", "engine_executable_path", "engine_executable_sha256"]
const STATE_KEYS: Array[String] = ["playing", "paused", "stop_pending", "pitch_scale", "global_speed_scale", "engine_time_scale"]
var executable_sha_before: String = ""
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
	executable_sha_before = FileAccess.get_sha256(OS.get_executable_path()).to_lower()
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

func _identity() -> Dictionary:
	if not is_instance_valid(manager): return {}
	var player: AudioStreamPlayer = manager.get("bgm_player") as AudioStreamPlayer
	if not is_instance_valid(player) or not player.stream is AudioStreamWAV: return {}
	var wav: AudioStreamWAV = player.stream as AudioStreamWAV
	var playback: AudioStreamPlayback = player.get_stream_playback() if player.has_stream_playback() else null
	var source_path: String = wav.resource_path
	if not source_hash_cache.has(source_path):
		source_hash_cache[source_path] = FileAccess.get_sha256(source_path) if FileAccess.file_exists(source_path) else "MISSING"
	return {"manager_id":str(manager.get_instance_id()), "player_id":str(player.get_instance_id()),
		"stream_id":str(wav.get_instance_id()), "playback_id":str(playback.get_instance_id()) if playback != null else "MISSING",
		"path":String(manager.get("_current_bgm_path")), "stream_path":source_path, "stream_source_sha256":source_hash_cache[source_path],
		"stream_class":wav.get_class(), "request_id":int(manager.get("_bgm_request_id")), "stop_pending":bool(manager.get("_bgm_stop_pending")),
		"playing":player.playing, "paused":player.stream_paused, "pitch_scale":player.pitch_scale,
		"global_speed_scale":AudioServer.playback_speed_scale, "engine_time_scale":Engine.time_scale,
		"stream_length_sec":wav.get_length(), "mix_rate_hz":wav.mix_rate, "loop_mode":wav.loop_mode,
		"loop_begin_frame":wav.loop_begin, "loop_end_frame":wav.loop_end,
		"loop_period_sec":float(wav.loop_end-wav.loop_begin)/float(wav.mix_rate) if wav.mix_rate > 0 else 0.0,
		"actual_audio_driver":AudioServer.get_driver_name(), "output_mix_rate_hz":AudioServer.get_mix_rate(),
		"output_device":AudioServer.output_device, "output_latency_sec":AudioServer.get_output_latency(),
		"engine_executable_path":OS.get_executable_path(), "engine_executable_sha256":executable_sha_before}

func _snapshot() -> Dictionary:
	var before: Dictionary = _identity()
	var row: Dictionary = {"valid":false, "ticks_usec":Time.get_ticks_usec(), "identity_before":before}
	if before.is_empty(): return row
	var player: AudioStreamPlayer = manager.get("bgm_player") as AudioStreamPlayer
	# Exactly two unlocked raw reads; no retries, discarded samples or smoothing.
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
	var after: Dictionary = _identity()
	row.merge(after, true)
	row.merge({"identity_after":after, "ticks_usec":t6, "read_ticks_usec":[t0,t1,t2,t3,t4,t5,t6],
		"read_start_usec":t0, "read_end_usec":t6, "read_span_sec":float(t6-t0)/1000000.0,
		"read_order":["P_before","since_before","until_before","P_after","since_after","until_after"],
		"position_before_sec":p0, "position_after_sec":p1, "since_before_sec":s0, "since_after_sec":s1,
		"until_before_sec":u0, "until_after_sec":u1,
		"native_float64_bytes_hex":[PackedFloat64Array([p0]).to_byte_array().hex_encode(),PackedFloat64Array([s0]).to_byte_array().hex_encode(),PackedFloat64Array([u0]).to_byte_array().hex_encode(),PackedFloat64Array([p1]).to_byte_array().hex_encode(),PackedFloat64Array([s1]).to_byte_array().hex_encode(),PackedFloat64Array([u1]).to_byte_array().hex_encode()]}, true)
	var metrics: Dictionary = _snapshot_metrics(row)
	row.merge(metrics, true)
	return row

func _finite_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

func _ulp32(value: float) -> float:
	if not is_finite(value) or value < 0: return INF
	var encoded: PackedByteArray = PackedFloat32Array([value]).to_byte_array()
	var bits: int = encoded.decode_u32(0)
	if bits >= 0x7f7fffff: return INF
	encoded.encode_u32(0, bits+1)
	return float(encoded.decode_float(0))-float(PackedFloat32Array([value])[0])

func _snapshot_metrics(row: Dictionary) -> Dictionary:
	var rejected: Dictionary = {"valid":false, "reason":"observation_insufficient_invalid_identity_clock_or_resolution"}
	if not row.get("identity_before") is Dictionary or not row.get("identity_after") is Dictionary: return rejected
	var before: Dictionary = row.identity_before
	var after: Dictionary = row.identity_after
	for key: String in IDENTITY_KEYS + STATE_KEYS:
		if not before.has(key) or not after.has(key) or typeof(before[key]) != typeof(after[key]) or before[key] != after[key] or row.get(key) != after[key]: return rejected
	for key: String in ["manager_id","player_id","stream_id","playback_id"]:
		if typeof(after[key]) != TYPE_STRING or not String(after[key]).is_valid_int() or String(after[key]) == "0": return rejected
	if after.actual_audio_driver != "WASAPI" or after.engine_executable_sha256 != EXECUTABLE_SHA: return rejected
	if typeof(after.engine_executable_path) != TYPE_STRING or String(after.engine_executable_path).is_empty() or typeof(after.output_device) != TYPE_STRING or String(after.output_device).is_empty(): return rejected
	if after.stream_class != "AudioStreamWAV" or typeof(after.path) != TYPE_STRING or String(after.path).is_empty() or typeof(after.stream_path) != TYPE_STRING or String(after.stream_path).is_empty(): return rejected
	if typeof(after.stream_source_sha256) != TYPE_STRING or String(after.stream_source_sha256).length() != 64: return rejected
	if typeof(after.request_id) != TYPE_INT or after.request_id < 0: return rejected
	for key: String in ["playing","paused","stop_pending"]:
		if typeof(after[key]) != TYPE_BOOL: return rejected
	for key: String in ["pitch_scale","global_speed_scale","engine_time_scale","stream_length_sec","mix_rate_hz","loop_begin_frame","loop_end_frame","loop_period_sec","output_mix_rate_hz","output_latency_sec"]:
		if not _finite_number(after[key]): return rejected
	if after.pitch_scale != 1.0 or after.global_speed_scale != 1.0 or after.engine_time_scale != 1.0: return rejected
	if after.mix_rate_hz <= 0 or after.output_mix_rate_hz <= 0 or after.output_latency_sec < 0 or after.output_latency_sec > .25: return rejected
	if after.loop_mode != AudioStreamWAV.LOOP_FORWARD or after.loop_begin_frame < 0 or after.loop_end_frame <= after.loop_begin_frame: return rejected
	var source_rate: float = float(after.mix_rate_hz)
	var period: float = float(after.loop_end_frame-after.loop_begin_frame)/source_rate
	# This operational contract is explicitly the authored 48-second city loop.
	if period != 48.0 or after.loop_period_sec != period or after.loop_end_frame/source_rate > after.stream_length_sec+1.0/source_rate: return rejected
	if not row.get("read_ticks_usec") is Array or row.read_ticks_usec.size() != 7: return rejected
	var ticks: Array = row.read_ticks_usec
	for index in ticks.size():
		if typeof(ticks[index]) != TYPE_INT or ticks[index] < 0 or (index > 0 and ticks[index] < ticks[index-1]): return rejected
	if typeof(row.get("ticks_usec")) != TYPE_INT or row.ticks_usec != ticks[6]: return rejected
	var span: float = float(ticks[6]-ticks[0])/1000000.0
	for key: String in ["position_before_sec","position_after_sec","since_before_sec","since_after_sec","until_before_sec","until_after_sec"]:
		if not _finite_number(row.get(key)): return rejected
	var q0: float = float(row.since_before_sec)+float(row.until_before_sec)
	var q1: float = float(row.since_after_sec)+float(row.until_after_sec)
	if not is_finite(q0) or not is_finite(q1) or q0 <= 0 or q1 <= 0 or q0 > .25 or q1 > .25: return rejected
	var upper: float = maxf(q0,q1)+span+TIMESTAMP_GRANULARITY_SEC
	var position: float = float(row.position_after_sec)
	var ulp: float = _ulp32(position)
	var budget: float = upper+float(OUTPUT_BLOCK_FRAMES)/float(after.output_mix_rate_hz)+float(SOURCE_PREFETCH_FRAMES)/source_rate+span+ulp+1.0/source_rate+TIMESTAMP_GRANULARITY_SEC
	if not is_finite(budget) or budget <= 0 or budget >= period*.01: return rejected
	for suffix: String in ["before","after"]:
		var p: float = float(row["position_"+suffix+"_sec"])
		var since: float = float(row["since_"+suffix+"_sec"])
		var until: float = float(row["until_"+suffix+"_sec"])
		# Noncircular resolution-derived overdue bound, not a fitted clamp.
		if p < 0 or p > after.stream_length_sec+1.0/source_rate or since < 0 or since > upper+budget or until < -budget: return rejected
	return {"valid":true, "reason":"bounded_operational_clock", "position_sec":position+float(row.since_after_sec),
		"observed_mix_quantum_sec":upper, "quantum_before_sec":q0, "quantum_after_sec":q1,
		"read_span_sec":span, "position_float32_ulp_sec":ulp, "endpoint_budget_sec":budget,
		"since_last_mix_sec":row.since_after_sec, "until_next_mix_sec":row.until_after_sec}

func finish_observation() -> Dictionary:
	if not active: return {"ok":false, "scope":SCOPE, "reason":"no_active_observation"}
	_append_sample()
	release()
	var source_hashes_after: Dictionary = {}
	for source_path: String in source_hash_cache:
		source_hashes_after[source_path] = FileAccess.get_sha256(source_path) if FileAccess.file_exists(source_path) else "MISSING"
	var executable_sha_after: String = FileAccess.get_sha256(OS.get_executable_path()).to_lower()
	return _evaluate_samples(samples, events, errors, source_hash_cache, source_hashes_after, executable_sha_after, limit_usec)

func _evaluate_samples(rows: Array[Dictionary], observed_events: Array[Dictionary], observed_errors: Array[String], source_before: Dictionary, source_after: Dictionary, executable_sha_after: String, maximum_usec: int) -> Dictionary:
	# Shared pure evaluator makes negative fixtures exercise the actual verdict.
	var identity_ok: bool = rows.size() >= 2 and rows.size() <= MAX_SAMPLES
	var no_stop: bool = identity_ok
	var progress_ok: bool = identity_ok
	var edges: Array[Dictionary] = []
	if rows.is_empty(): return {"ok":false, "scope":SCOPE, "reason":"no_samples"}
	var first: Dictionary = rows[0]
	var source_unchanged: bool = not source_before.is_empty() and source_before == source_after and not source_before.values().has("MISSING")
	var elapsed: float = float(int(rows[-1].get("ticks_usec",0))-int(first.get("ticks_usec",0)))/1000000.0
	for row: Dictionary in rows:
		var same: bool = bool(_snapshot_metrics(row).get("valid",false))
		for key: String in IDENTITY_KEYS:
			same = same and typeof(row.get(key)) == typeof(first.get(key)) and row.get(key) == first.get(key)
		identity_ok = identity_ok and same
		no_stop = no_stop and row.get("playing") == true and row.get("paused") == false and row.get("stop_pending") == false
		progress_ok = progress_ok and row.get("pitch_scale") == 1.0 and row.get("global_speed_scale") == 1.0 and row.get("engine_time_scale") == 1.0
		source_unchanged = source_unchanged and source_before.get(String(row.get("stream_path",""))) == row.get("stream_source_sha256")
	for index in range(1, rows.size()):
		var edge: Dictionary = _progress_edge(rows[index-1], rows[index])
		edges.append(edge)
		progress_ok = progress_ok and bool(edge.get("ok",false))
	var whole_edge: Dictionary = _progress_edge(first, rows[-1])
	progress_ok = progress_ok and bool(whole_edge.get("ok",false)) and elapsed > 0 and maximum_usec > 0 and maximum_usec <= 180000000 and elapsed <= float(maximum_usec)/1000000.0
	var executable_unchanged: bool = executable_sha_after == EXECUTABLE_SHA and first.get("engine_executable_sha256") == executable_sha_after
	return {"schema":2, "scope":SCOPE, "label":label,
		"ok":observed_errors.is_empty() and identity_ok and executable_unchanged and source_unchanged and no_stop and observed_events.is_empty() and progress_ok,
		"exact_identity":identity_ok, "all_observed_states_playing_unpaused_no_pending_stop":no_stop,
		"bgm_changed_count":observed_events.size(), "bgm_changed_events":observed_events.duplicate(true), "modulo_elapsed_progress":progress_ok,
		"elapsed_sec":elapsed, "maximum_duration_sec":float(maximum_usec)/1000000.0,
		"sample_count":rows.size(), "sample_interval_usec":SAMPLE_INTERVAL_USEC, "errors":observed_errors.duplicate(),
		"samples":rows.duplicate(true), "adjacent_progress_edges":edges, "whole_observation_progress":whole_edge,
		"source_sha256_before":source_before.duplicate(), "source_sha256_after":source_after, "source_bytes_unchanged":source_unchanged,
		"engine_executable_sha256_before":first.get("engine_executable_sha256"), "engine_executable_sha256_after":executable_sha_after, "engine_executable_bytes_unchanged":executable_unchanged,
		"actual_audio_driver":first.get("actual_audio_driver"), "source_version_equivalence_proven":false,
		"runtime_block_constants_reflected":false, "engineering_model":{"output_block_frames":OUTPUT_BLOCK_FRAMES,"resampled_source_prefetch_frames":SOURCE_PREFETCH_FRAMES,"fixed_point_phase_steps":RESAMPLER_PHASE_STEPS,"position_precision":"Float32","timestamp_granularity_sec":TIMESTAMP_GRANULARITY_SEC},
		"tolerance_basis":"C=P_after+since_after; Qupper=max(Q0,Q1)+readspan+2us; b=Qupper+512/Rout+128/Rsrc+readspan+ULP32(P)+1/Rsrc+2us; E=b0+b1+dt*Rout/(65536*Rsrc). Both Q bounded; overdue phase bounded by b; no fitted speed.",
		"limitations":"Explicit operational 512-output/128-source/16bit resampler model, not exact installed-binary source equivalence or DAC continuity. Finite process-frame observations plus synchronous events/request/playback identity, not continuous mixer trace. Same-instance whole-period silent seek remains potentially indistinguishable.",
		"audio_mutated_by_helper":false, "normal_input_executed_by_helper":false, "visual_approved":false}

func _progress_edge(before: Dictionary, after: Dictionary) -> Dictionary:
	var bm: Dictionary = _snapshot_metrics(before)
	var am: Dictionary = _snapshot_metrics(after)
	if bm.get("valid") != true or am.get("valid") != true: return {"ok":false, "reason":"observation_insufficient_invalid_snapshot"}
	var period: float = float(before.loop_period_sec)
	var elapsed: float = float(int(after.ticks_usec)-int(before.ticks_usec))/1000000.0
	if not is_finite(elapsed) or elapsed <= 0 or period != float(after.loop_period_sec) or before.mix_rate_hz != after.mix_rate_hz or before.output_mix_rate_hz != after.output_mix_rate_hz: return {"ok":false, "reason":"invalid_period_elapsed_or_rates"}
	var raw_delta: float = float(am.position_sec)-float(bm.position_sec)
	var wraps: int = roundi((elapsed-raw_delta)/period)
	var unfolded: float = raw_delta+float(wraps)*period
	var drift: float = elapsed*float(before.output_mix_rate_hz)/(float(RESAMPLER_PHASE_STEPS)*float(before.mix_rate_hz))
	var tolerance: float = float(bm.endpoint_budget_sec)+float(am.endpoint_budget_sec)+drift
	var error: float = unfolded-elapsed
	var resolution_valid: bool = is_finite(tolerance) and tolerance > 0 and tolerance < period*.01
	return {"ok":resolution_valid and wraps >= 0 and unfolded >= 0 and is_finite(error) and absf(error) <= tolerance,
		"before_ticks_usec":before.ticks_usec, "after_ticks_usec":after.ticks_usec,
		"elapsed_sec":elapsed, "raw_position_delta_sec":raw_delta, "inferred_wrap_count":wraps,
		"actual_loop_period_sec":period, "unfolded_progress_sec":unfolded, "progress_error_sec":error,
		"audio_timing_tolerance_sec":tolerance, "resolution_valid":resolution_valid,
		"before_endpoint_budget":bm, "after_endpoint_budget":am, "fixed_point_drift_bound_sec":drift}

func release() -> void:
	active = false
	if is_instance_valid(bus) and bus.is_connected("bgm_changed", Callable(self, "_changed")):
		bus.disconnect("bgm_changed", Callable(self, "_changed"))
	if owner != null and owner.process_frame.is_connected(_observe_frame): owner.process_frame.disconnect(_observe_frame)
	bus = null
	manager = null
	owner = null


