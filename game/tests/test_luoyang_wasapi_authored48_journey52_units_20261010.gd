extends SceneTree
## PURE fixtures exercise the NEW observer's actual evaluator. No live-playback
## positive credit, Field, publisher, approvals, save writes or RELEASE subsets.
const OBS = preload("res://tests/helpers/luoyang_wasapi_authored48_journey52_continuity_20261010.gd")
const OBS_PATH: String = "res://tests/helpers/luoyang_wasapi_authored48_journey52_continuity_20261010.gd"
const OBS_SHA: String = "6ef8906708f3f12cda59e53a65a98aa4f328d1a30eafa732f9d1829517af1019"
const OLD = preload("res://tests/helpers/joint_v15_wasapi_operational_bgm_continuity_20261007.gd")
const OLD_PATH: String = "res://tests/helpers/joint_v15_wasapi_operational_bgm_continuity_20261007.gd"
const OLD_SHA: String = "bf7d6c9265b19def36b6b1e4da326694b1c84e75a9eeeb23721128173e5322ca"
const JOURNEY: String = "res://art/audio/bgm/bgm_jianghu_journey_v4.wav"
const JOURNEY_SHA: String = "4e52dfafc8555bbdace7c1e6aa95b5511c606105ee6d95fb35a1d9e68fbad236"
const IMPORT_PATH: String = JOURNEY+".import"
const IMPORT_SHA: String = "a5e38767b210c0c3715d29fd830f384f21a172e0f16326193cdbaa7a3ef87160"
const SAMPLE_PATH: String = "res://.godot/imported/bgm_jianghu_journey_v4.wav-1a8101cf096c312ce6ccb65a31d34571.sample"
const SAMPLE_SHA: String = "7768db05905c545a788e0357d34b0d830561df49549eb973a0433395a12d3b53"
const SONG: String = "res://art/audio/bgm/bgm_city_ceremony_v4.wav"
const SONG_SHA: String = "b722c1ddedfc460b316361d3496ea89d16593de8fe904c58a29443325121d279"
var checks: int = 0
var failures: int = 0
var observer: RefCounted
var old_observer: RefCounted
var source_before: Dictionary
var players_before: Dictionary
var slot_before: Variant
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
	var result: Dictionary = observer.call("_evaluate_samples",rows,observed_events,observed_errors,before,after,OBS.EXECUTABLE_SHA,maximum)
	var original: Dictionary = old_observer.call("_evaluate_samples",rows,observed_events,observed_errors,before,after,OBS.EXECUTABLE_SHA,maximum)
	var same: bool = true
	for key: Variant in original: same = same and typeof(original[key]) == typeof(result.get(key)) and original[key] == result.get(key)
	_check(same,"actual old48 evaluator complete original fields equal NEW; original fixture/negative unchanged")
	return result

func _run() -> void:
	var self_sha: String = FileAccess.get_sha256(get_script().resource_path)
	_check(OS.get_cmdline_user_args().is_empty(),"no hidden modes")
	_check(FileAccess.get_sha256(OBS_PATH) == OBS_SHA,"actual NEW observer exact source")
	old_observer = OLD.new()
	observer = OBS.new()
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	_check(bridge != null,"public checkpoint bridge")
	if bridge == null: quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true,"checkpoint held through quit")
	players_before = _players()
	slot_before = root.get_node("SaveManager").get("active_slot")
	source_before = _source_hashes()
	_check(source_before[OLD_PATH] == OLD_SHA and source_before[JOURNEY] == JOURNEY_SHA and source_before[IMPORT_PATH] == IMPORT_SHA and source_before[SAMPLE_PATH] == SAMPLE_SHA,"original48 and actual52 raw/import/compiled source pins")
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
	_run52()
	for index in 8: await process_frame
	_check(_source_hashes() == source_before,"all consumed52/original sources unchanged")
	_check(_players() == players_before and root.get_node("SaveManager").get("active_slot") == slot_before,"15 normal player files/slot unchanged; external exactUTCtick guard required")
	_check(bridge.call("is_checkpoint_saves_suspended") == true,"public checkpoint remains held after final await to quit")
	var output: String = "res://build/joint_world_luoyang_20261003_qa/authored48_journey52_pure_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output) == OK,"unique BUILD fixture evidence only")
	_check(FileAccess.get_sha256(OBS_PATH) == OBS_SHA and FileAccess.get_sha256(get_script().resource_path) == self_sha,"source unchanged")
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"schema":1,"scope":"PURE_OPERATIONAL_MODEL_UNITS_NOT_LIVE_AUDIO_OR_RELEASE","checks":checks,"failures":failures,"evidence":evidence,"positive_fixture":positive,"source_sha256":self_sha,"observer_sha256":OBS_SHA,"output":output,"live_audio_credit":false,"release_complete":false,"formal_cutover":false},"\t"))
		file.close()
	old_observer.call("release")
	old_observer = null
	observer.call("release")
	observer = null
	print("OPERATIONAL_BGM_PURE: %d/%d; output=%s; no live/Field/RELEASE credit" % [checks,failures,output])
	quit(0 if failures == 0 else 1)

func fixture_sources() -> Array[String]:
	return [get_script().resource_path,OBS_PATH,OLD_PATH,SONG,JOURNEY,IMPORT_PATH,SAMPLE_PATH,
		"res://scripts/autoload/platform_bridge.gd","res://scripts/autoload/audio_manager.gd"]

func _source_hashes() -> Dictionary:
	var result: Dictionary = {}
	for path: String in fixture_sources(): result[path] = FileAccess.get_sha256(path).to_lower() if FileAccess.file_exists(path) else "MISSING"
	return result

func _players() -> Dictionary:
	var result: Dictionary = {}
	for slot in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String = "user://save_%d.json%s" % [slot,suffix]
			var row: Dictionary = {"exists":FileAccess.file_exists(path)}
			if row.exists:
				var file: FileAccess = FileAccess.open(path,FileAccess.READ)
				row["readable"] = file != null
				if file != null: row["bytes"] = file.get_length(); file.close()
				row["sha256"] = FileAccess.get_sha256(path)
				row["modified_seconds"] = FileAccess.get_modified_time(path)
			result[path] = row
	return result

func _fixture52(ticks: int, position: float) -> Dictionary:
	var row: Dictionary = _fixture(ticks,position)
	for key: String in ["path","stream_path"]: _field(row,key,JOURNEY)
	_field(row,"stream_source_sha256",JOURNEY_SHA)
	_field(row,"stream_length_sec",52.0)
	_field(row,"loop_period_sec",52.0)
	_field(row,"loop_end_frame",1146600)
	row["read_order"] = ["P_before","since_before","until_before","P_after","since_after","until_after"]
	row["native_float64_bytes_hex"] = []
	for key: String in ["position_before_sec","since_before_sec","until_before_sec","position_after_sec","since_after_sec","until_after_sec"]:
		row.native_float64_bytes_hex.append(PackedFloat64Array([row[key]]).to_byte_array().hex_encode())
	return row

func _rows52() -> Array[Dictionary]:
	return [_fixture52(1000000,12.0),_fixture52(55000000,14.0)]

func _verdict52(rows: Array[Dictionary], observed_events: Array[Dictionary] = [], observed_errors: Array[String] = [], after_source: Dictionary = {}, maximum: int = 180000000) -> Dictionary:
	var sources: Dictionary = {JOURNEY:JOURNEY_SHA}
	return observer.call("_evaluate_samples",rows,observed_events,observed_errors,sources,sources if after_source.is_empty() else after_source,OBS.EXECUTABLE_SHA,maximum)

func _run52() -> void:
	var wav: AudioStreamWAV = ResourceLoader.load(JOURNEY,"",ResourceLoader.CACHE_MODE_IGNORE) as AudioStreamWAV
	_check(wav != null and wav.mix_rate == 22050 and wav.get_length() == 52.0 and roundi(wav.get_length()*wav.mix_rate) == 1146600,"actual imported source length/rate/frame count; fixture clocks remain synthetic")
	var rows: Array[Dictionary] = _rows52()
	var good: Dictionary = _verdict52(rows)
	_check(good.get("ok") == true and good.elapsed_sec == 54.0 and good.whole_observation_progress.inferred_wrap_count == 1 and good.period_domain.kind == "EXACT_SHA_BOUND_JOURNEY52","exact source-bound synthetic54s modulo52, actual imported source fields")
	for key: String in ["path","stream_path","stream_source_sha256","stream_class","mix_rate_hz","loop_mode","loop_begin_frame","loop_end_frame","loop_period_sec","stream_length_sec"]:
		rows = _rows52()
		var identity: Dictionary = rows[0].identity_after
		for bad: Variant in [null,false,[identity[key]]]:
			var changed: Dictionary = identity.duplicate(true)
			changed[key] = bad
			_check(observer.call("_period_domain",changed,52.0) == false,"typed52 domain rejects:"+key)
		rows = _rows52()
		var changed_value: Variant = str(rows[1][key])+"_changed" if typeof(rows[1][key]) == TYPE_STRING else float(rows[1][key])+1.0
		for row: Dictionary in rows: _field(row,key,changed_value)
		_check(_verdict52(rows).get("ok") == false,"actual evaluator stable wrong52 domain:"+key)
	for key: String in OBS.IDENTITY_KEYS:
		rows = _rows52()
		var old: Variant = rows[1][key]
		_field(rows[1],key,str(old)+"_changed" if typeof(old) == TYPE_STRING else float(old)+1.0)
		_check(_verdict52(rows).get("ok") == false,"52 identity/source/driver/request/restart rejects:"+key)
	for key: String in ["playing","paused","stop_pending","pitch_scale","global_speed_scale","engine_time_scale"]:
		rows = _rows52()
		_field(rows[1],key,1.01 if key.ends_with("scale") else key != "playing")
		_check(_verdict52(rows).get("ok") == false,"52 stopped/pause/unit rejects:"+key)
	for drift: float in [.25,.635]:
		rows = _rows52()
		rows[1].position_before_sec += drift
		rows[1].position_after_sec += drift
		_check(_verdict52(rows).get("ok") == false,"52 seek/drift actual progress rejects:"+str(drift))
	rows = _rows52()
	rows[1].since_after_sec = 100.01; rows[1].until_after_sec = -100.0
	_check(_verdict52(rows).get("ok") == false,"52 pathological overdue clock rejects")
	rows = _rows52(); rows[1].read_ticks_usec[0] -= 600000
	_check(_verdict52(rows).get("ok") == false,"52 oversized readspan cannot fit drift")
	_check(_verdict52(_rows52(),[{"path":JOURNEY,"ticks_usec":2000000}]).get("ok") == false,"52 same-path change event rejects")
	_check(_verdict52(_rows52(),[],["sample_budget_exhausted"]).get("ok") == false,"52 exhausted retained sample budget rejects")
	_check(_verdict52(_rows52(),[],[],{JOURNEY:"changed"}).get("ok") == false,"52 after-source bytes reject")
	_check(_verdict52(_rows52(),[],[],{},53000000).get("ok") == false,"52 actual finite wallbudget rejects")
	_check(observer.call("_period_domain",_rows52()[0].identity_after,51.0) == false,"unknown51 period rejects")

