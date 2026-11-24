extends SceneTree
## PURE fixtures exercise the NEW observer's actual evaluator. No live-playback
## positive credit, Field, publisher, approvals, save writes or RELEASE subsets.
const OBS = preload("res://tests/helpers/joint_v15_wasapi_operational_bgm_continuity_20261007.gd")
const OBS_PATH: String = "res://tests/helpers/joint_v15_wasapi_operational_bgm_continuity_20261007.gd"
const OBS_SHA: String = "bf7d6c9265b19def36b6b1e4da326694b1c84e75a9eeeb23721128173e5322ca"
const SONG: String = "res://art/audio/bgm/bgm_city_ceremony_v4.wav"
const SONG_SHA: String = "b722c1ddedfc460b316361d3496ea89d16593de8fe904c58a29443325121d279"
var checks: int = 0
var failures: int = 0
var observer: RefCounted
var evidence: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1
	evidence.append({"label":label,"ok":ok})
	if not ok:
		failures += 1
		push_error("[OPERATIONAL PURE UNIT] "+label)

func _fixture(ticks: int, position: float) -> Dictionary:
	var identity: Dictionary = {"manager_id":"11","player_id":"12","stream_id":"-9223372036854775700","playback_id":"-9223372036854775699",
		"path":SONG,"stream_path":SONG,"stream_source_sha256":SONG_SHA,"stream_class":"AudioStreamWAV","request_id":7,
		"stop_pending":false,"playing":true,"paused":false,"pitch_scale":1.0,"global_speed_scale":1.0,"engine_time_scale":1.0,
		"stream_length_sec":48.0,"mix_rate_hz":22050,"loop_mode":AudioStreamWAV.LOOP_FORWARD,"loop_begin_frame":0,"loop_end_frame":1058400,"loop_period_sec":48.0,
		"actual_audio_driver":"WASAPI","output_mix_rate_hz":48000.0,"output_device":"Default","output_latency_sec":.02,
		"engine_executable_path":"fixture/explicit-installed-binary.exe","engine_executable_sha256":OBS.EXECUTABLE_SHA}
	var row: Dictionary = identity.duplicate(true)
	row.merge({"identity_before":identity.duplicate(true),"identity_after":identity.duplicate(true),"ticks_usec":ticks,
		"read_ticks_usec":[ticks-20,ticks-18,ticks-15,ticks-12,ticks-9,ticks-5,ticks],
		"position_before_sec":position,"position_after_sec":position,"since_before_sec":.003,"since_after_sec":.003,"until_before_sec":.007,"until_after_sec":.007})
	return row

func _field(row: Dictionary, key: String, value: Variant) -> void:
	row[key] = value
	row.identity_before[key] = value
	row.identity_after[key] = value

func _rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = [_fixture(1000000,12.0),_fixture(51000000,14.0)]
	return result

func _verdict(rows: Array[Dictionary], observed_events: Array[Dictionary] = [], observed_errors: Array[String] = [], maximum: int = 180000000, after_source: Dictionary = {}) -> Dictionary:
	var before: Dictionary = {SONG:SONG_SHA}
	var after: Dictionary = before.duplicate() if after_source.is_empty() else after_source
	return observer.call("_evaluate_samples",rows,observed_events,observed_errors,before,after,OBS.EXECUTABLE_SHA,maximum)

func _run() -> void:
	var self_sha: String = FileAccess.get_sha256(get_script().resource_path)
	_check(OS.get_cmdline_user_args().is_empty(),"no hidden modes")
	_check(FileAccess.get_sha256(OBS_PATH) == OBS_SHA,"actual NEW observer exact source")
	observer = OBS.new()
	var rows: Array[Dictionary] = _rows()
	var positive: Dictionary = _verdict(rows)
	_check(positive.get("ok") == true and positive.elapsed_sec == 50.0 and positive.whole_observation_progress.inferred_wrap_count == 1,"pure unchanged50s modulo48 fixture passes, not live credit")
	_check(positive.get("source_version_equivalence_proven") == false and positive.get("runtime_block_constants_reflected") == false,"engineering limitations explicit")
	_check(positive.whole_observation_progress.audio_timing_tolerance_sec < .48,"finite resolution below1percent period")
	rows[0].since_before_sec = .023
	rows[0].since_after_sec = .023
	rows[0].until_before_sec = -.013
	rows[0].until_after_sec = -.013
	rows[0].position_before_sec = 11.98
	rows[0].position_after_sec = 11.98
	_check(_verdict(rows).get("ok") == true,"legitimate bounded overdue negativeuntil retained, no clamp")
	rows = _rows()
	rows[1].position_after_sec += .635
	rows[1].position_before_sec += .635
	_check(_verdict(rows).get("ok") == false,"constant +.635 second drift rejected by actual edge and whole formula")
	_check(observer.call("_progress_edge",rows[0],rows[1]).get("ok") == false,"+.635 edge independently refused")
	var accumulated: Array[Dictionary] = []
	for index in 151:
		accumulated.append(_fixture(1000000+index*1000000,fmod(12.0+float(index)*(1.0+.635/150.0),48.0)))
	var drift_result: Dictionary = _verdict(accumulated)
	var all_adjacent: bool = drift_result.adjacent_progress_edges.size() == 150
	for edge: Dictionary in drift_result.adjacent_progress_edges:
		all_adjacent = all_adjacent and edge.get("ok") == true
	_check(all_adjacent,"150s linear cumulative+.635 fixture has every adjacent edge individually within engineering resolution")
	_check(drift_result.whole_observation_progress.get("ok") == false and drift_result.get("ok") == false,"whole-only accumulated drift refused despite all adjacent positives; no fitted speed")
	for key: String in OBS.IDENTITY_KEYS:
		rows = _rows()
		var old: Variant = rows[1][key]
		var changed: Variant
		match typeof(old):
			TYPE_STRING: changed = str(old)+"_changed"
			TYPE_INT: changed = int(old)+1
			TYPE_FLOAT: changed = float(old)+.125
			_: changed = null
		_field(rows[1],key,changed)
		_check(_verdict(rows).get("ok") == false,"actual evaluator rejects identity/source/driver/rate/device/latency change:"+key)
	for key: String in ["playing","paused","stop_pending","pitch_scale","global_speed_scale","engine_time_scale"]:
		rows = _rows()
		var changed: Variant = false if key == "playing" else true
		if key.ends_with("scale"): changed = 1.01
		_field(rows[1],key,changed)
		_check(_verdict(rows).get("ok") == false,"stop/pause/pitch/global/time rejected:"+key)
	rows = _rows()
	rows[1].identity_before.playback_id = "-9223372036854775698"
	_check(_verdict(rows).get("ok") == false,"within-read playback instance change rejected even if after matches initial")
	for bad: Variant in ["12",0.0,false,null]:
		rows = _rows()
		_field(rows[1],"playback_id",bad)
		_check(_verdict(rows).get("ok") == false,"playbackID requires exact nonzero integer STRING")
	for suffix: String in ["before","after"]:
		for bad: float in [NAN,INF,-INF,-1.0,100.01]:
			rows = _rows()
			rows[1]["since_"+suffix+"_sec"] = bad
			rows[1]["until_"+suffix+"_sec"] = .01-bad
			_check(_verdict(rows).get("ok") == false,"invalid/cancelling huge since-until:"+suffix+"/"+str(bad))
		for quantum: float in [0.0,-.01,.250001,INF]:
			rows = _rows()
			rows[1]["until_"+suffix+"_sec"] = quantum-.003
			_check(_verdict(rows).get("ok") == false,"Q finite/positive/upper bound:"+suffix+"/"+str(quantum))
	rows = _rows()
	rows[1].read_ticks_usec[0] -= 500000
	_check(_verdict(rows).get("ok") == false,"huge raw read span cannot expand uncertainty into arbitrary PASS")
	rows = _rows()
	rows[1].read_ticks_usec[2] = rows[1].read_ticks_usec[0]-1
	_check(_verdict(rows).get("ok") == false,"nonmonotonic raw read ticks refused")
	rows = _rows()
	rows[1].ticks_usec = rows[0].ticks_usec
	rows[1].read_ticks_usec = rows[0].read_ticks_usec.duplicate()
	_check(_verdict(rows).get("ok") == false,"nonpositive elapsed refused")
	rows = _rows()
	var observed_events: Array[Dictionary] = [{"ticks_usec":2000000,"path":SONG}]
	_check(_verdict(rows,observed_events).get("ok") == false,"synchronous bgm_changed event rejects even same path")
	var observed_errors: Array[String] = ["sample_budget_exhausted"]
	_check(_verdict(rows,[],observed_errors).get("ok") == false,"sample budget exhausted never clears into PASS")
	_check(_verdict(rows,[],[],49000000).get("ok") == false,"actual finite observation budget exceeded")
	_check(_verdict(rows,[],[],180000001).get("ok") == false,"unknown expanded observation budget refused")
	_check(_verdict(rows,[],[],180000000,{SONG:"changed_source"}).get("ok") == false,"actual after-source hash differs")
	var duplicate_rows: Array[Dictionary] = []
	for index in OBS.MAX_SAMPLES+1: duplicate_rows.append(rows[0])
	_check(_verdict(duplicate_rows).get("ok") == false,"more than4096 retained rows refused")
	var output: String = "res://build/joint_world_luoyang_20261003_qa/operational_bgm_pure_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output) == OK,"unique BUILD fixture evidence only")
	_check(FileAccess.get_sha256(OBS_PATH) == OBS_SHA and FileAccess.get_sha256(get_script().resource_path) == self_sha,"source unchanged")
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"schema":1,"scope":"PURE_OPERATIONAL_MODEL_UNITS_NOT_LIVE_AUDIO_OR_RELEASE","checks":checks,"failures":failures,"evidence":evidence,"positive_fixture":positive,"source_sha256":self_sha,"observer_sha256":OBS_SHA,"output":output,"live_audio_credit":false,"release_complete":false,"formal_cutover":false},"\t"))
		file.close()
	observer.call("release")
	observer = null
	for index in 8: await process_frame
	print("OPERATIONAL_BGM_PURE: %d/%d; output=%s; no live/Field/RELEASE credit" % [checks,failures,output])
	quit(0 if failures == 0 else 1)



