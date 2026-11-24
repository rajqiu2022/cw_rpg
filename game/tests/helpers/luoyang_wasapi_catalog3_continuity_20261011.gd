extends "res://tests/helpers/luoyang_wasapi_authored48_journey52_continuity_20261010.gd"
## NEW QA only. Original observation/clock/edge/evaluator mathematics are inherited.
## Same-song continuity and a real different-song selection are separate claims.
## No playback, seek, production writes, arbitrary-period admission or DAC proof.
const BASE_PATH := "res://tests/helpers/luoyang_wasapi_authored48_journey52_continuity_20261010.gd"
const BASE_SHA := "6ef8906708f3f12cda59e53a65a98aa4f328d1a30eafa732f9d1829517af1019"
const CATALOG_PATH := "res://scripts/audio/music_catalog.gd"
const CATALOG_SHA := "cafbabdd3d82f1ebf6d694e9cc6f2eb2cf04744a4febb36a0503eb0cdf3c39e4"
const AUDIO_PATH := "res://scripts/autoload/audio_manager.gd"
const AUDIO_SHA := "2a089d4b96d094559410ab8c8321f599172d974325f7ccda01a2df89e2c5a419"
const DIR := "res://art/audio/bgm/wuxia_20261011/"
const PROFILES := {
	DIR+"city_luoyang.wav": {"frames":3339020,"sha256":"2ad0d168c87462bce7ffc9b4634000c185947994010343b132d653cb48a95b78"},
	DIR+"exploration_journey.wav": {"frames":3275104,"sha256":"07bea078194a01945c127f5ec3f4971a47fe9d31729958af3e7b38f3d357b979"},
	DIR+"exploration_mountain.wav": {"frames":2508112,"sha256":"f192701d686ef0693b0e9edeed60ab204a0262209bc69295f3643c365e40fcc8"},
}
## Independent finite expected selection, not an oracle derived from the resolver.
const SCENES := {
	"ch4_s0_luoyang_gate":{"legacy":"res://art/audio/bgm/bgm_city_ceremony_v4.wav","actual":DIR+"city_luoyang.wav"},
	"ch4_s1_luoyang_yamen":{"legacy":"res://art/audio/bgm/bgm_city_ceremony_v4.wav","actual":DIR+"city_luoyang.wav"},
	"ch4_s2_canal_docks":{"legacy":"res://art/audio/bgm/bgm_jianghu_journey_v4.wav","actual":DIR+"city_luoyang.wav"},
	"ch4_s3_luoyang_market":{"legacy":"res://art/audio/bgm/bgm_market_lively_v4.wav","actual":DIR+"city_luoyang.wav"},
	"world_map_jianghu":{"legacy":"res://art/audio/bgm/bgm_jianghu_journey_v4.wav","actual":DIR+"exploration_journey.wav"},
	"ch4_s4_ancient_temple":{"legacy":"res://art/audio/bgm/bgm_sect_clouds_v4.wav","actual":DIR+"exploration_mountain.wav"},
}
var _transfer_selection: Dictionary = {}
var _transfer_dependencies: Dictionary = {}

static func dependency_pins() -> Dictionary:
	var result: Dictionary = {BASE_PATH:BASE_SHA,CATALOG_PATH:CATALOG_SHA,AUDIO_PATH:AUDIO_SHA}
	for path: String in PROFILES: result[path] = PROFILES[path].sha256
	return result

static func dependency_hashes() -> Dictionary:
	var result: Dictionary = {}
	for path: String in dependency_pins(): result[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "MISSING"
	return result

static func _exact_fields(actual: Dictionary, expected: Dictionary) -> bool:
	if actual.size() != expected.size(): return false
	for key: Variant in expected:
		if not actual.has(key) or typeof(actual[key]) != typeof(expected[key]) or actual[key] != expected[key]: return false
	return true

static func expected_transfer(source_scene: Variant, target_scene: Variant) -> Dictionary:
	if typeof(source_scene) != TYPE_STRING or typeof(target_scene) != TYPE_STRING or not SCENES.has(source_scene) or not SCENES.has(target_scene): return {}
	if not _exact_fields(dependency_hashes(), dependency_pins()): return {}
	var catalog: Script = load(CATALOG_PATH) as Script
	if catalog == null or not catalog.can_instantiate(): return {}
	for id: String in [source_scene,target_scene]:
		if catalog.call("scene_bgm",StringName(id),String(SCENES[id].legacy)) != SCENES[id].actual: return {}
	return {"source_scene":source_scene,"target_scene":target_scene,
		"source_path":SCENES[source_scene].actual,"target_path":SCENES[target_scene].actual,
		"kind":"SAME_SELECTED_TRACK" if SCENES[source_scene].actual == SCENES[target_scene].actual else "DIFFERENT_SELECTED_TRACK",
		"catalog_sha256":CATALOG_SHA,"audio_manager_sha256":AUDIO_SHA}

static func selection_valid(selection: Variant) -> bool:
	if not selection is Dictionary: return false
	var expected: Dictionary = expected_transfer(selection.get("source_scene"),selection.get("target_scene"))
	return not expected.is_empty() and _exact_fields(selection,expected)

func _period_domain(identity: Dictionary, period: float) -> bool:
	var path: Variant = identity.get("path")
	if typeof(path) != TYPE_STRING or not PROFILES.has(path): return false
	var profile: Dictionary = PROFILES[path]
	var exact: Dictionary = {"path":path,"stream_path":path,"stream_source_sha256":profile.sha256,
		"stream_class":"AudioStreamWAV","mix_rate_hz":44100,"loop_mode":AudioStreamWAV.LOOP_FORWARD,
		"loop_begin_frame":0,"loop_end_frame":int(profile.frames),
		"loop_period_sec":float(profile.frames)/44100.0,"stream_length_sec":float(profile.frames)/44100.0}
	for key: String in exact:
		if not identity.has(key) or typeof(identity[key]) != typeof(exact[key]) or identity[key] != exact[key]: return false
	return is_finite(period) and period == exact.loop_period_sec

func _evaluate_samples(rows: Array[Dictionary], observed_events: Array[Dictionary], observed_errors: Array[String], source_before: Dictionary, source_after: Dictionary, executable_sha_after: String, maximum_usec: int) -> Dictionary:
	var result: Dictionary = super._evaluate_samples(rows,observed_events,observed_errors,source_before,source_after,executable_sha_after,maximum_usec)
	# Output label only: every original formula, threshold and verdict is retained.
	if result.has("period_domain"):
		result.period_domain.kind = "EXACT_SHA_BOUND_CATALOG3_PCM"
		result.period_domain.profile_recognized = not rows.is_empty() and _identity_profile(rows[0])
	return result

func _identity_profile(identity: Variant) -> bool:
	return identity is Dictionary and typeof(identity.get("loop_period_sec")) == TYPE_FLOAT and _period_domain(identity,identity.loop_period_sec)

func begin_transfer(tree: SceneTree, case_label: String, selection: Dictionary, maximum_seconds: float = 120.0) -> Dictionary:
	if active: return {"ok":false,"reason":"observation_already_active"}
	_transfer_selection = {}; _transfer_dependencies = {}
	if not selection_valid(selection): return {"ok":false,"reason":"unknown_or_unbound_effective_selection"}
	_transfer_selection = selection.duplicate(true)
	_transfer_dependencies = dependency_hashes()
	var begun: Dictionary = super.begin_observation(tree,case_label,maximum_seconds)
	if begun.get("ok") == true and String(begun.before.get("path","")) != selection.source_path:
		errors.append("actual_initial_track_differs_from_effective_source")
		release(); begun.ok = false
	begun["selection"] = _transfer_selection.duplicate(true)
	begun["dependency_sha256_before"] = _transfer_dependencies.duplicate()
	return begun

func finish_transfer() -> Dictionary:
	var raw_report: Dictionary = super.finish_observation()
	return evaluate_transfer(raw_report,_transfer_selection,_transfer_dependencies,dependency_hashes())

func evaluate_transfer(raw_report: Dictionary, selection: Dictionary, dependencies_before: Dictionary, dependencies_after: Dictionary) -> Dictionary:
	var verdict: Dictionary = {"schema":1,"ok":false,"kind":selection.get("kind","UNKNOWN"),
		"continuity_tested":false,"continuity_credit":false,"Field_credit":false,"formal_approved":false,
		"selection":selection.duplicate(true),"raw_observer_report":raw_report.duplicate(true),
		"dependency_sha256_before":dependencies_before.duplicate(),"dependency_sha256_after":dependencies_after.duplicate(),
		"scope":"CATALOG3_BOUNDED_OPERATIONAL_SELECTION_NOT_DAC_OR_SOURCE_EQUIVALENCE"}
	if not selection_valid(selection) or not _exact_fields(dependencies_before,dependency_pins()) or not _exact_fields(dependencies_after,dependency_pins()): return verdict
	var rows: Variant = raw_report.get("samples")
	if not rows is Array or rows.size() < 2 or rows.size() > MAX_SAMPLES: return verdict
	for row: Variant in rows:
		if not row is Dictionary: return verdict
		if not _identity_profile(row) or not _identity_profile(row.get("identity_before")) or not _identity_profile(row.get("identity_after")): return verdict
		for key: String in IDENTITY_KEYS + STATE_KEYS:
			if not row.has(key) or not row.identity_after.has(key) or typeof(row[key]) != typeof(row.identity_after[key]) or row[key] != row.identity_after[key]: return verdict
	var first: Dictionary = rows[0]; var last: Dictionary = rows[-1]
	if _snapshot_metrics(first).get("valid") != true or _snapshot_metrics(last).get("valid") != true: return verdict
	if first.get("path") != selection.source_path or last.get("path") != selection.target_path: return verdict
	var before_hashes: Variant = raw_report.get("source_sha256_before")
	var after_hashes: Variant = raw_report.get("source_sha256_after")
	if not before_hashes is Dictionary or not after_hashes is Dictionary or not _exact_fields(before_hashes,after_hashes): return verdict
	if before_hashes.size() != (1 if selection.kind == "SAME_SELECTED_TRACK" else 2): return verdict
	for path: String in [selection.source_path,selection.target_path]:
		if typeof(before_hashes.get(path)) != TYPE_STRING or typeof(after_hashes.get(path)) != TYPE_STRING or before_hashes.get(path) != PROFILES[path].sha256 or after_hashes.get(path) != PROFILES[path].sha256: return verdict
	var elapsed: float = float(int(last.ticks_usec)-int(first.ticks_usec))/1000000.0
	var maximum: Variant = raw_report.get("maximum_duration_sec")
	if not _finite_number(maximum) or not is_finite(elapsed) or elapsed <= 0.0 or float(maximum) <= 0.0 or float(maximum) > 180.0 or elapsed > float(maximum): return verdict
	var changes: Variant = raw_report.get("bgm_changed_events")
	var observed_errors: Variant = raw_report.get("errors")
	if not changes is Array or not observed_errors is Array or typeof(raw_report.get("engine_executable_sha256_after")) != TYPE_STRING: return verdict
	var typed_rows: Array[Dictionary] = []; var typed_events: Array[Dictionary] = []; var typed_errors: Array[String] = []
	for row: Dictionary in rows: typed_rows.append(row)
	for event_row: Variant in changes:
		if not event_row is Dictionary or typeof(event_row.get("path")) != TYPE_STRING: return verdict
		typed_events.append(event_row)
	for error_row: Variant in observed_errors:
		if typeof(error_row) != TYPE_STRING: return verdict
		typed_errors.append(error_row)
	# Exercise the inherited actual core, not a caller-supplied ok/summary bit.
	var computed: Dictionary = _evaluate_samples(typed_rows,typed_events,typed_errors,before_hashes,after_hashes,String(raw_report.engine_executable_sha256_after),int(float(maximum)*1000000.0))
	verdict["recomputed_observer_report"] = computed
	if computed.get("source_bytes_unchanged") != true or computed.get("engine_executable_bytes_unchanged") != true or computed.get("actual_audio_driver") != "WASAPI": return verdict
	if selection.kind == "SAME_SELECTED_TRACK":
		verdict.continuity_tested = true
		verdict.ok = computed.get("ok") == true
		verdict.continuity_credit = verdict.ok
		return verdict
	# A changed stream is not a failed same-song continuity claim made into PASS.
	# Only the normal single scene-selected change and exact final state are tested.
	if not changes is Array or changes.size() != 1 or not changes[0] is Dictionary or not observed_errors is Array or not observed_errors.is_empty(): return verdict
	var event: Dictionary = changes[0]
	if event.get("path") != selection.target_path or typeof(event.get("ticks_usec")) != TYPE_INT or event.ticks_usec < first.ticks_usec or event.ticks_usec > last.ticks_usec: return verdict
	if computed.get("bgm_changed_count") != 1: return verdict
	var previous_tick: int = -1
	for row: Dictionary in typed_rows:
		if typeof(row.get("ticks_usec")) != TYPE_INT or row.ticks_usec < previous_tick: return verdict
		previous_tick = row.ticks_usec
		# A real transition can straddle the two identity reads. Each side must
		# still belong to one of the two selected exact PCM profiles; no third song.
		for identity: Variant in [row.get("identity_before"),row.get("identity_after")]:
			if not _identity_profile(identity) or identity.path not in [selection.source_path,selection.target_path]: return verdict
	for endpoint: Dictionary in [first,last]:
		if endpoint.playing != true or endpoint.paused != false or endpoint.stop_pending != false: return verdict
	if first.manager_id != last.manager_id or last.request_id != first.request_id+1: return verdict
	if first.player_id == last.player_id or first.stream_id == last.stream_id or first.playback_id == last.playback_id: return verdict
	verdict.ok = true
	verdict["normal_target_change"] = {"event":event.duplicate(),"initial_path":first.path,"target_path":last.path,"final_playing":last.playing,"request_delta":last.request_id-first.request_id}
	return verdict
