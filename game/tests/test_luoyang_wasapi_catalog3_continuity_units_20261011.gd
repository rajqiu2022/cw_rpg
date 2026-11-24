extends SceneTree
## Pure fixtures call the actual NEW core. No live Field/portal/playback credit.
## Root alone executes under fresh all23 WAV/import/compiled and player guards.
const OBS = preload("res://tests/helpers/luoyang_wasapi_catalog3_continuity_20261011.gd")
const OBS_PATH := "res://tests/helpers/luoyang_wasapi_catalog3_continuity_20261011.gd"
const OBS_SHA := "62acbff384fecf1de7309907745c2e736bdaefd6f3b3d34b7e8dcb86fe9e9f6a"
const OLD = preload("res://tests/helpers/luoyang_wasapi_authored48_journey52_continuity_20261010.gd")
var checks := 0
var failures := 0
var evidence: Array[Dictionary] = []
var observer: RefCounted
var old_observer: RefCounted
var sources: Dictionary = {}
var players: Dictionary = {}
var slot: Variant
var output := ""

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checks += 1; evidence.append({"ok":ok,"label":label})
	if not ok: failures += 1; push_error("[CATALOG3 PURE FAIL] "+label)

func _file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false}
	var file := FileAccess.open(path,FileAccess.READ)
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file != null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}

func _players() -> Dictionary:
	var result: Dictionary = {}
	for index in 5:
		for suffix: String in ["",".bak",".tmp"]: result["user://save_%d.json%s"%[index,suffix]] = _file("user://save_%d.json%s"%[index,suffix])
	return result

func _source_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for path: String in OBS.dependency_pins(): result[path] = _file(path)
	for path: String in [get_script().resource_path,OBS_PATH]: result[path] = _file(path)
	var pattern := RegEx.new(); pattern.compile('"(res://[.]godot/imported/[^"\\r\\n]+)"')
	for path: String in OBS.PROFILES:
		var imported: String = path+".import"; result[imported] = _file(imported)
		if not FileAccess.file_exists(imported): continue
		for found: RegExMatch in pattern.search_all(FileAccess.get_file_as_string(imported)): result[found.get_string(1)] = _file(found.get_string(1))
	return result

func _fixture(path: String, ticks: int, position: float) -> Dictionary:
	var profile: Dictionary = OBS.PROFILES[path]
	var period: float = float(profile.frames)/44100.0
	var identity: Dictionary = {"manager_id":"11","player_id":"12","stream_id":"-9223372036854775700","playback_id":"-9223372036854775699",
		"path":path,"stream_path":path,"stream_source_sha256":profile.sha256,"stream_class":"AudioStreamWAV","request_id":7,
		"stop_pending":false,"playing":true,"paused":false,"pitch_scale":1.0,"global_speed_scale":1.0,"engine_time_scale":1.0,
		"stream_length_sec":period,"mix_rate_hz":44100,"loop_mode":AudioStreamWAV.LOOP_FORWARD,"loop_begin_frame":0,"loop_end_frame":int(profile.frames),"loop_period_sec":period,
		"actual_audio_driver":"WASAPI","output_mix_rate_hz":48000.0,"output_device":"Default","output_latency_sec":.02,
		"engine_executable_path":"fixture/explicit-installed-binary.exe","engine_executable_sha256":OBS.EXECUTABLE_SHA}
	var row: Dictionary = identity.duplicate(true)
	row.merge({"identity_before":identity.duplicate(true),"identity_after":identity.duplicate(true),"ticks_usec":ticks,
		"read_ticks_usec":[ticks-20,ticks-18,ticks-15,ticks-12,ticks-9,ticks-5,ticks],
		"position_before_sec":position,"position_after_sec":position,"since_before_sec":.003,"since_after_sec":.003,"until_before_sec":.007,"until_after_sec":.007})
	return row

func _set(row: Dictionary,key: String,value: Variant) -> void:
	row[key] = value; row.identity_before[key] = value; row.identity_after[key] = value

func _same(path: String) -> Array[Dictionary]:
	var period: float = float(OBS.PROFILES[path].frames)/44100.0
	return [_fixture(path,1000000,12.0),_fixture(path,81000000,fmod(92.0,period))]

func _different(selection: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = [_fixture(selection.source_path,1000000,12.0),_fixture(selection.target_path,2000000,.05)]
	_set(rows[1],"player_id","13"); _set(rows[1],"stream_id","-9223372036854775698"); _set(rows[1],"playback_id","-9223372036854775697"); _set(rows[1],"request_id",8)
	return rows

func _raw(rows: Array[Dictionary],changes: Array[Dictionary]=[],observed_errors: Array[String]=[]) -> Dictionary:
	var hashes: Dictionary = {}
	for row: Dictionary in rows:
		if OBS.PROFILES.has(String(row.get("path",""))): hashes[row.path] = OBS.PROFILES[row.path].sha256
	return observer.call("_evaluate_samples",rows,changes,observed_errors,hashes,hashes.duplicate(),OBS.EXECUTABLE_SHA,180000000)

func _transfer(raw_report: Dictionary,selection: Dictionary,before: Dictionary={},after: Dictionary={}) -> Dictionary:
	return observer.call("evaluate_transfer",raw_report,selection,OBS.dependency_pins() if before.is_empty() else before,OBS.dependency_pins() if after.is_empty() else after)

func _domain_units() -> void:
	for path: String in OBS.PROFILES:
		var rows: Array[Dictionary] = _same(path)
		_check(observer.call("_period_domain",rows[0],rows[0].loop_period_sec)==true,"exact profile admitted "+path)
		var raw_report: Dictionary = _raw(rows)
		_check(raw_report.get("ok")==true and raw_report.period_domain.kind=="EXACT_SHA_BOUND_CATALOG3_PCM" and raw_report.whole_observation_progress.inferred_wrap_count==1,"actual inherited full/adjacent wrap formula positive "+path)
		_check(old_observer.call("_period_domain",rows[0],rows[0].loop_period_sec)==false,"original 6EF remains unable to approve new profile "+path)
		var mutations: Array[Dictionary] = [
			{"key":"path","value":"res://art/audio/bgm/unknown.wav"},{"key":"stream_path","value":"res://art/audio/bgm/unknown.wav"},
			{"key":"stream_source_sha256","value":"0".repeat(64)},{"key":"mix_rate_hz","value":22050},{"key":"mix_rate_hz","value":44100.0},{"key":"mix_rate_hz","value":true},
			{"key":"loop_begin_frame","value":1},{"key":"loop_end_frame","value":rows[0].loop_end_frame+1},{"key":"loop_end_frame","value":float(rows[0].loop_end_frame)},
			{"key":"stream_length_sec","value":rows[0].stream_length_sec+1.0/44100.0},{"key":"loop_period_sec","value":rows[0].loop_period_sec+1.0/44100.0},
			{"key":"loop_period_sec","value":NAN},{"key":"loop_period_sec","value":INF},{"key":"loop_period_sec","value":48.0},{"key":"loop_period_sec","value":52.0},
			{"key":"stream_class","value":"AudioStreamMP3"},{"key":"loop_mode","value":AudioStreamWAV.LOOP_DISABLED},{"key":"loop_mode","value":true}]
		for mutation: Dictionary in mutations:
			var bad: Dictionary = rows[0].duplicate(true); _set(bad,mutation.key,mutation.value)
			_check(observer.call("_period_domain",bad,rows[0].loop_period_sec)==false,"profile rejects "+mutation.key+"/"+str(mutation.value)+" "+path)
			# Parent raw clock API assumes native WAV loop_mode:int. Its unchanged
			# scalar comparison is not a raw boolean-type test; the new profile
			# guard above is the directly exercised typed rejection for this case.
			if mutation.key != "loop_mode" or typeof(mutation.value) != TYPE_BOOL:
				_check(_raw([bad,rows[1]]).get("ok")==false,"inherited metrics/core also rejects profile mutation "+mutation.key+" "+path)
		_check(observer.call("_period_domain",rows[0],NAN)==false and observer.call("_period_domain",rows[0],INF)==false,"nonfinite explicit period rejects "+path)

func _selection_units() -> void:
	var pairs: Array[Array] = [
		["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","SAME_SELECTED_TRACK"],
		["ch4_s1_luoyang_yamen","ch4_s3_luoyang_market","SAME_SELECTED_TRACK"],
		["ch4_s2_canal_docks","world_map_jianghu","DIFFERENT_SELECTED_TRACK"],
		["ch4_s4_ancient_temple","ch4_s2_canal_docks","DIFFERENT_SELECTED_TRACK"]]
	for pair: Array in pairs:
		var selected: Dictionary = OBS.expected_transfer(pair[0],pair[1])
		_check(not selected.is_empty() and selected.kind==pair[2] and OBS.selection_valid(selected),"independent finite effective selection "+str(pair))
	for bad: Variant in ["", "unknown", true, 1, StringName("ch4_s0_luoyang_gate"),null]:
		_check(OBS.expected_transfer(bad,"ch4_s1_luoyang_yamen").is_empty() and OBS.expected_transfer("ch4_s0_luoyang_gate",bad).is_empty(),"unknown/raw type scene refuses "+str(bad))
	var selected: Dictionary = OBS.expected_transfer("ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen")
	for key: String in selected:
		var bad: Dictionary = selected.duplicate(); bad[key] = "unknown"
		_check(not OBS.selection_valid(bad),"selection field binding rejects "+key)
	var extra: Dictionary = selected.duplicate(); extra.extra = true
	_check(not OBS.selection_valid(extra) and not OBS.selection_valid(null),"extra selection key/nonDictionary rejects")

func _same_units() -> void:
	var selected: Dictionary = OBS.expected_transfer("ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen")
	var rows: Array[Dictionary] = _same(selected.source_path)
	var positive: Dictionary = _transfer(_raw(rows),selected)
	_check(positive.ok==true and positive.continuity_tested==true and positive.continuity_credit==true,"same selected song full continuity positive; pure only")
	for key: String in ["request_id","player_id","playback_id","stream_id","playing","paused","stop_pending","pitch_scale","engine_time_scale"]:
		var changed: Array[Dictionary] = _same(selected.source_path)
		var value: Variant = 8 if key=="request_id" else "99" if key in ["player_id","playback_id","stream_id"] else false if key=="playing" else true if key in ["paused","stop_pending"] else 2.0
		_set(changed[1],key,value)
		_check(_transfer(_raw(changed),selected).ok==false,"same rejects actual identity/state "+key)
	var restarted: Array[Dictionary] = _same(selected.source_path); restarted[1].position_before_sec=.01; restarted[1].position_after_sec=.01
	_check(not _transfer(_raw(restarted),selected).ok,"restart/seek rejects actual inherited progression")
	var drift: Array[Dictionary] = []
	var period: float = rows[0].loop_period_sec
	for index in 151: drift.append(_fixture(selected.source_path,1000000+index*1000000,fmod(12.0+float(index)*(1.0+.635/150.0),period)))
	var drift_report: Dictionary = _raw(drift); var adjacent: bool = true
	for edge: Dictionary in drift_report.adjacent_progress_edges: adjacent = adjacent and edge.ok
	_check(adjacent and drift_report.whole_observation_progress.ok==false and not _transfer(drift_report,selected).ok,"whole rejects cumulative drift even when all adjacent pass")
	var changes: Array[Dictionary] = [{"ticks_usec":2000000,"path":selected.source_path}]
	_check(not _transfer(_raw(rows,changes),selected).ok,"same hidden/intermediate change event rejects")
	var forged: Dictionary = _raw(rows); forged.samples[1].position_after_sec += 1.0; forged.samples[1].position_before_sec += 1.0; forged.ok=true
	_check(not _transfer(forged,selected).ok,"caller summary ok cannot bypass recomputed actual edge")
	var invalid_type: Dictionary = _raw(rows); _set(invalid_type.samples[1],"loop_mode",true)
	_check(not _transfer(invalid_type,selected).ok,"raw bool mode refused by NEW profile gate before native scalar clock core")
	var bad_guard: Dictionary = OBS.dependency_pins(); bad_guard[OBS.CATALOG_PATH]="0".repeat(64)
	_check(not _transfer(_raw(rows),selected,bad_guard,OBS.dependency_pins()).ok and not _transfer(_raw(rows),selected,OBS.dependency_pins(),bad_guard).ok,"catalog first/last change rejects")
	var bad_audio: Dictionary = OBS.dependency_pins(); bad_audio[OBS.AUDIO_PATH]="0".repeat(64)
	_check(not _transfer(_raw(rows),selected,OBS.dependency_pins(),bad_audio).ok,"audio source last change rejects")
	var bad_source: Dictionary = _raw(rows); bad_source.source_sha256_after[selected.source_path]="0".repeat(64)
	_check(not _transfer(bad_source,selected).ok,"observed PCM source mutation rejects")
	var bad_engine: Dictionary = _raw(rows); bad_engine.engine_executable_sha256_after="0".repeat(64)
	_check(not _transfer(bad_engine,selected).ok,"actual executable last change rejects")

func _different_units() -> void:
	for target: String in ["world_map_jianghu","ch4_s4_ancient_temple"]:
		var selected: Dictionary = OBS.expected_transfer("ch4_s2_canal_docks",target)
		var rows: Array[Dictionary] = _different(selected)
		var changes: Array[Dictionary] = [{"ticks_usec":1500000,"path":selected.target_path}]
		var raw_report: Dictionary = _raw(rows,changes)
		var positive: Dictionary = _transfer(raw_report,selected)
		_check(raw_report.ok==false and positive.ok==true and positive.continuity_tested==false and positive.continuity_credit==false,"real changed track selection not same-song continuity "+target)
		_check(not _transfer(_raw(rows),selected).ok,"changed target without normal event rejects "+target)
		var wrong_event: Array[Dictionary] = [{"ticks_usec":1500000,"path":selected.source_path}]
		_check(not _transfer(_raw(rows,wrong_event),selected).ok,"wrong selected target event rejects "+target)
		var repeated: Array[Dictionary] = changes.duplicate(); repeated.append(changes[0])
		_check(not _transfer(_raw(rows,repeated),selected).ok,"multiple/third transition event rejects "+target)
		for bad_tick: Variant in [true,1.5,500000,3000000]:
			var bad_events: Array[Dictionary] = [{"ticks_usec":bad_tick,"path":selected.target_path}]
			_check(not _transfer(_raw(rows,bad_events),selected).ok,"invalid/outside event time rejects "+target+"/"+str(bad_tick))
		for key: String in ["path","stream_path","playing","paused","stop_pending","manager_id","player_id","stream_id","playback_id","request_id"]:
			var changed: Array[Dictionary] = _different(selected)
			var value: Variant = selected.source_path if key in ["path","stream_path"] else false if key=="playing" else true if key in ["paused","stop_pending"] else "999" if key=="manager_id" else rows[0][key] if key in ["player_id","stream_id","playback_id"] else 9
			_set(changed[1],key,value)
			_check(not _transfer(_raw(changed,changes),selected).ok,"different final exact state/normal change refuses "+target+"/"+key)
		var wrong_source: Array[Dictionary] = _different(selected); wrong_source[0]=_fixture(selected.target_path,1000000,12.0)
		_check(not _transfer(_raw(wrong_source,changes),selected).ok,"actual initial source binding refuses "+target)
		var third: Array[Dictionary] = _different(selected); third.insert(1,_fixture(OBS.DIR+"exploration_mountain.wav" if target=="world_map_jianghu" else OBS.DIR+"exploration_journey.wav",1400000,.01))
		_check(not _transfer(_raw(third,changes),selected).ok,"unselected third PCM refuses "+target)
		var errors: Array[String] = ["explicit observed error"]
		_check(not _transfer(_raw(rows,changes,errors),selected).ok,"observed error refuses changed selection "+target)

func _typed_transfer_units() -> void:
	var same: Dictionary = OBS.expected_transfer("ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen")
	var different: Dictionary = OBS.expected_transfer("ch4_s2_canal_docks","world_map_jianghu")
	var changes: Array[Dictionary] = [{"ticks_usec":1500000,"path":different.target_path}]
	var normal_different: Dictionary = _raw(_different(different),changes)
	_check(_transfer(normal_different,different).ok,"typed event String positive calls actual transfer core")
	var named_event: Dictionary = normal_different.duplicate(true)
	named_event.bgm_changed_events[0].path = StringName(different.target_path)
	_check(not _transfer(named_event,different).ok,"StringName event path alias refuses actual transfer core")
	for selected: Dictionary in [same,different]:
		var raw_report: Dictionary = _raw(_same(same.source_path)) if selected.kind == "SAME_SELECTED_TRACK" else normal_different.duplicate(true)
		_check(_transfer(raw_report,selected).ok,"typed PCM hash and top-level int request positive "+selected.kind)
		for path: String in raw_report.source_sha256_before:
			var named_hash: Dictionary = raw_report.duplicate(true)
			named_hash.source_sha256_before[path] = StringName(OBS.PROFILES[path].sha256)
			named_hash.source_sha256_after[path] = StringName(OBS.PROFILES[path].sha256)
			_check(not _transfer(named_hash,selected).ok,"StringName before/after PCM SHA alias refuses actual transfer core "+selected.kind+"/"+path)
		for index in 2:
			var double_request: Dictionary = raw_report.duplicate(true)
			double_request.samples[index].request_id = float(double_request.samples[index].request_id)
			_check(not _transfer(double_request,selected).ok,"Double top-level request differs from native identity_after int "+selected.kind+"/"+str(index))

func _run() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null: push_error("[CATALOG3 PURE FAIL] missing checkpoint bridge"); quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"public checkpoint held before any await")
	players=_players(); slot=root.get_node("SaveManager").get("active_slot"); sources=_source_snapshot()
	_check(OS.get_cmdline_user_args().is_empty(),"no hidden unit modes")
	_check(FileAccess.get_sha256(OBS_PATH)==OBS_SHA and OBS.dependency_hashes()==OBS.dependency_pins(),"exact current observer/base/catalog/audio/threePCM pins")
	_check(AudioServer.get_driver_name()=="WASAPI" and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==OBS.EXECUTABLE_SHA and Engine.time_scale==1.0,"actual installed engine/WASAPI/normal time; no live playback credit")
	for path: String in sources: _check(sources[path].get("exists")==true,"required actual source/import/compiled exists "+path)
	observer=OBS.new(); old_observer=OLD.new()
	_domain_units(); _selection_units(); _same_units(); _different_units(); _typed_transfer_units()
	observer.call("release"); observer=null; old_observer.call("release"); old_observer=null
	_check(sources==_source_snapshot(),"bounded source/import/compiled bytes unchanged")
	_check(players==_players() and slot==root.get_node("SaveManager").get("active_slot"),"all15 normal player and active slot unchanged")
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"public checkpoint still held through quit")
	output="res://build/joint_world_luoyang_20261003_qa/catalog3_continuity_units_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique unit evidence directory")
	var result: Dictionary = {"schema":1,"scope":"CATALOG3_PURE_ACTUAL_CORE_NOT_LIVE_FIELD_OR_AUDIO_CONTINUITY","complete":failures==0,"checks":checks,"failures":failures,"evidence":evidence,
		"source_before":sources,"source_after":_source_snapshot(),"players_before":players,"players_after":_players(),"active_slot_before":slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),
		"Field_executed":false,"live_playback_tested":false,"formal_approved":false,"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"exact_UTCticks":"ROOT_EXTERNAL_REQUIRED","source_self_sha256":FileAccess.get_sha256(get_script().resource_path)}
	var file := FileAccess.open(output+"result.json",FileAccess.WRITE)
	var encoded: String = JSON.stringify(result,"\t",true)
	if file != null: file.store_string(encoded); file.flush(); file.close()
	var parser := JSON.new()
	_check(file != null and parser.parse(FileAccess.get_file_as_string(output+"result.json"))==OK and parser.data==JSON.parse_string(encoded),"pure result saved/readback")
	print("CATALOG3_UNIT_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)
