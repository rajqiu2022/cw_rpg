extends SceneTree
## Limited real WASAPI playback; no Field, battle execution, save or load.
## Two wraps seek near the end; this does not listen through two complete loops.
const CATALOG_PATH := "res://scripts/audio/music_catalog.gd"
const MANIFEST_PATH := "F:/Code/RPG_GAME/assets/processed/audio/wuxia_music_integration_20261011/asset_manifest.json"
const OUT := "F:/Code/RPG_GAME/assets/processed/audio/wuxia_audio_install_qa_20261011/"
const NEW_ROOT := "res://art/audio/bgm/wuxia_20261011/"
const ENGINE_SHA := "975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
var checks := 0
var failures: Array[String] = []
var observations: Dictionary = {}
var audio: Node
var bridge: Node
var dialog: Node
var events: Node
var catalog: GDScript

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("[AUDIO INSTALL QA] " + label)
	return ok

func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout

func _player() -> AudioStreamPlayer:
	return audio.get("bgm_player") as AudioStreamPlayer

func _path() -> String:
	return String(audio.call("get_current_bgm"))

func _no_field() -> bool:
	# GameState initializes default CharacterStats even without a gameplay scene.
	var router := root.get_node_or_null("SceneRouter")
	return current_scene == null and router != null and String(router.call("get_current_field_id")).is_empty()

func _safe_dialog(id: StringName, node_id: StringName = &"start") -> void:
	var script := DialogScript.new()
	script.dialog_id = id
	script.entry_node_id = node_id
	var node := DialogNode.new()
	node.node_id = node_id
	node.text = "音频接入专项；无剧情副作用。"
	node.on_end = "end"
	script.nodes.append(node)
	dialog.call("play", script)

func _run() -> void:
	# Public checkpoint suspension is first, before every await and quit.
	bridge = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended"):
		push_error("[AUDIO INSTALL QA] checkpoint suspension API absent")
		quit(1)
		return
	bridge.call("set_checkpoint_saves_suspended", true)
	_check(bool(bridge.call("is_checkpoint_saves_suspended")), "checkpoint suspended")
	audio = root.get_node_or_null("AudioManager")
	dialog = root.get_node_or_null("DialogPlayer")
	events = root.get_node_or_null("EventBus")
	if not _check(audio != null and dialog != null and events != null, "actual autoloads exist"):
		_finish()
		return
	observations["driver"] = AudioServer.get_driver_name()
	observations["mix_rate"] = AudioServer.get_mix_rate()
	observations["engine_sha256"] = FileAccess.get_sha256(OS.get_executable_path())
	_check(String(observations["engine_sha256"]).to_lower() == ENGINE_SHA, "actual installed engine identity")
	if not _check(AudioServer.get_driver_name() == "WASAPI", "strict actual WASAPI; Dummy refused"):
		_finish()
		return
	_check(not bool(bridge.call("request_checkpoint_save")), "suspended checkpoint request refused")
	_check(_no_field(), "no actual gameplay scene or Field initialized")
	catalog = load(CATALOG_PATH) as GDScript
	if not _check(catalog != null, "actual catalog loads"):
		_finish()
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not _check(parsed is Dictionary and parsed.get("assets", []).size() == 23, "fixed 23 asset manifest"):
		_finish()
		return
	var asset_results: Array[Dictionary] = []
	for asset: Dictionary in parsed["assets"]:
		var path := String(asset["resource_path"])
		_check(FileAccess.get_sha256(path) == String(asset["destination"]["sha256"]), "asset source SHA " + path)
		var stream := load(path) as AudioStreamWAV
		if not _check(stream != null, "actual imported WAV " + path):
			continue
		_check(stream.format == AudioStreamWAV.FORMAT_16_BITS and stream.stereo and stream.mix_rate == 44100, "import preserves PCM16/stereo/rate " + path)
		var frames := stream.data.size() / 4
		_check(frames == int(asset["audio"]["frames"]), "actual untrimmed frames " + path)
		audio.call("play_bgm", path, 0.02, "qa_nonempty_context_20261011")
		_check(_player().stream == stream and _player().playing, "actual real player starts " + path)
		_check(stream.loop_mode == AudioStreamWAV.LOOP_FORWARD and stream.loop_begin == 0 and stream.loop_end == frames, "full-file loop frames " + path)
		_check(_player().get_playback_position() < 0.1, "new track actual first phrase begins zero " + path)
		await _wait(0.025)
		asset_results.append({"path":path,"frames":frames,"position":_player().get_playback_position(),"playing":_player().playing,"loop_begin":stream.loop_begin,"loop_end":stream.loop_end})
	observations["assets"] = asset_results
	# Compare every physical SceneTRES against the frozen independent source map.
	# Read authored strings with whitespace tolerance; never infer a missing BGM.
	var mapping_path := "F:/Code/RPG_GAME/assets/processed/audio/wuxia_music_adoption_source_20261011/source_final_mapping.json"
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(mapping_path))
	var expected_rows: Dictionary = {}
	for row: Dictionary in mapping["scene_resources"]:
		expected_rows["res://" + String(row["path"]).trim_prefix("game/")] = row
	_check(expected_rows.size() == 99, "frozen expected scene file count 99")
	var scene_results: Array[Dictionary] = []
	var seen_files: Dictionary = {}
	var seen_ids: Dictionary = {}
	var dir := DirAccess.open("res://data/scenes")
	for name: String in dir.get_files():
		if name.get_extension() != "tres": continue
		var path := "res://data/scenes/" + name
		if not _check(expected_rows.has(path), "actual scene file bound to expected map " + path): continue
		var expected: Dictionary = expected_rows[path]
		var text := FileAccess.get_file_as_string(path)
		var regex := RegEx.new()
		regex.compile('(?m)^bgm_path\\s*=\\s*"([^"\\n]*)"')
		var match_ := regex.search(text)
		var legacy := match_.get_string(1) if match_ != null else ""
		var id_regex := RegEx.new()
		id_regex.compile('(?m)^scene_id\\s*=\\s*&?"([^"\\n]*)"')
		var id_match := id_regex.search(text)
		var authored_id := id_match.get_string(1) if id_match != null else name.get_basename()
		_check(FileAccess.get_sha256(path) == String(expected["sha256"]), "actual SceneTRES bytes " + path)
		_check(authored_id == String(expected["scene_id"]) and legacy == String(expected["authored_bgm_path"]), "authored scene/BGM strings " + path)
		var result := String(catalog.call("scene_bgm", StringName(authored_id), legacy))
		_check(result == String(expected["catalog_bgm_path"]), "actual catalog matches independent expected map " + path)
		if not result.is_empty(): _check(ResourceLoader.exists(result), "mapped scene path exists " + path)
		seen_files[path] = true
		seen_ids[authored_id] = true
		scene_results.append({"file":path,"scene":authored_id,"legacy":legacy,"resolved":result,"expected":expected["catalog_bgm_path"],"runtime_empty_fallback":expected["runtime_empty_fallback"]})
	_check(seen_files.size() == expected_rows.size() and scene_results.size() == 99, "all 99 physical scene files compared without collapsing duplicate IDs")
	observations["scene_catalog_all_actual_ids"] = scene_results
	observations["unique_authored_scene_id_count"] = seen_ids.size()
	observations["scene_mapping_source_sha256"] = FileAccess.get_sha256(mapping_path)
	# Live EventBus normal audio receiver. No SceneRouter scene transition.
	for pair: Array in [[&"ch4_s1_luoyang_yamen","city_luoyang"],[&"openworld_bianzhou_city","city_bianzhou"],[&"openworld_jinling_city","city_jinling"],[&"openworld_xiangzhou_city","city_xiangzhou"],[&"openworld_qinghe_town","town_qinghe"],[&"openworld_yanmen_pass","pass_yanmen"],[&"ch2_s1_zhuwei_market","village_zhuwei"],[&"openworld_v15_bamboo_outskirts","outskirts_zhuxi_linxi"],[&"openworld_v15_forest_outskirts","outskirts_forest_xiangzhou"],[&"openworld_v15_marsh_outskirts","outskirts_wetland_jinling"],[&"linxi_village_center","LINXI_ORIGINAL"],[&"ch8_s1_alliance_staging_ground","exploration_mountain"],[&"ch8_s2_mistwood_blockade","outskirts_forest_xiangzhou"],[&"ch8_s3_manor_perimeter_encampment","outskirts_forest_xiangzhou"],[&"ch8_s4_alliance_mechanism_gallery","story_danger"],[&"ch8_s5_alliance_ceremonial_platform","city_luoyang"],[&"ch8_s6_mingwu_main_hall","exploration_mountain"],[&"ch8_s7_mingwu_rear_sanctum","story_danger"]]:
		var scene_id := StringName(pair[0])
		var expected := NEW_ROOT + String(pair[1]) + ".wav" if pair[1] != "LINXI_ORIGINAL" else "res://art/audio/bgm/bgm_village_day_v4.wav"
		events.emit_signal("scene_entered", scene_id)
		_check(_path() == expected and _player().playing, "live scene EventBus dispatch " + String(scene_id))
		await _wait(0.03)
	var base := NEW_ROOT + "exploration_journey.wav"
	for pair: Array in [[&"linxi_center_granny", "story_warm"], [&"ch4_peony_poetry", "story_joy"], [&"ch4_case_clue", "story_tension"], [&"ch4_temple_ambush", "story_danger"]]:
		audio.call("play_bgm", base, 0.03, "qa_field_restore")
		_safe_dialog(pair[0])
		_check(dialog.call("is_playing") and _path() == NEW_ROOT + String(pair[1]) + ".wav", "normal DialogPlayer mood " + String(pair[0]))
		await _wait(0.035)
		dialog.call("advance")
		_check(not bool(dialog.call("is_playing")) and _path() == base, "normal dialog end restores " + String(pair[0]))
		_check(String(audio.get("_current_bgm_context")) == "qa_field_restore", "dialog restores original context " + String(pair[0]))
	# Local end handlers run before EventBus end: a new same-ID dialogue owns its cue.
	audio.call("play_bgm", base, 0.02, "qa_chain_restore")
	_safe_dialog(&"ch4_case_clue")
	dialog.connect("dialog_ended", func(_id: StringName): _safe_dialog(&"ch4_case_clue"), CONNECT_ONE_SHOT)
	dialog.call("advance")
	_check(bool(dialog.call("is_playing")) and _path() == NEW_ROOT + "story_tension.wav", "stale same-ID end does not restore over newly started dialog")
	dialog.call("advance")
	_check(_path() == base, "same-ID chained final end restores original field")
	_safe_dialog(&"ch4_case_clue")
	audio.call("play_bgm", NEW_ROOT + "battle_default.wav", 0.02, "qa_battle")
	dialog.call("advance")
	_check(_path() == NEW_ROOT + "battle_default.wav", "battle winner not overwritten by dialog end")
	audio.call("play_bgm", base, 0.02, "qa_night_restore")
	_safe_dialog(&"ch8_master_ultimate_breakthrough", &"n6")
	_check(_path() == NEW_ROOT + "village_night.wav", "actual special dialog node night override")
	dialog.call("advance")
	_check(_path() == base, "night node ends restore")
	_safe_dialog(&"ch4_temple_ambush")
	audio.call("play_music_sting", "res://art/audio/bgm/bgm_victory_v4_approved.wav", 0.5)
	dialog.call("advance")
	await _wait(0.16)
	var sting := audio.get("_music_sting_player") as AudioStreamPlayer
	_check(sting.playing and _path().is_empty(), "victory sting clears old dialogue restoration ownership")
	_safe_dialog(&"linxi_center_granny")
	_check(sting.playing and _path().is_empty(), "active victory sting takes priority over a new dialog cue")
	dialog.call("advance")
	audio.call("play_bgm", base, 0.02, "qa_sting_skip")
	await _wait(0.6)
	_check(_path() == base and _player().playing and not sting.playing, "field music skips sting and stale completion cannot stop it")
	# Desktop simulation of Web's locked gate, not actual browser playback credit.
	audio.set("_web_audio_unlocked", false)
	_safe_dialog(&"ch4_case_clue")
	_check(String(audio.get("_pending_bgm_path")) == NEW_ROOT + "story_tension.wav", "simulated locked gate queues real dialogue cue")
	audio.call("stop_bgm", 0.01)
	audio.call("unlock_from_user_gesture")
	await _wait(0.07)
	_check(String(audio.get("_pending_bgm_path")).is_empty() and _path().is_empty() and not _player().playing, "stop cancels queued dialogue before unlock; desktop simulation only")
	dialog.call("advance")
	observations["web_queue_stop_unlock"] = "DESKTOP_PUBLIC_API_SIMULATION_NOT_BROWSER"
	# Actual battle selector; no ready(), UI, combat, reward or save lifecycle.
	var battle := load("res://scripts/battle/battle_controller.gd").new() as Node
	for pair: Array in [["bamboo_platforms","battle_spar"],["river_skirmish","battle_river"],["courtyard_wedge","battle_mountain"],["village_square","battle_village"],["unknown_qa_arena","battle_default"]]:
		_check(String(battle.call("_battle_bgm_for_payload", {"battle_arena":pair[0]})) == NEW_ROOT + String(pair[1]) + ".wav", "battle selector " + String(pair[0]))
	_check(String(battle.call("_battle_bgm_for_payload", {"enemy_id":"boss_zhao_wuji","battle_arena":"river_skirmish"})) == NEW_ROOT + "battle_boss.wav", "boss priority above arena")
	_check(String(battle.call("_battle_bgm_for_payload", {"battle_mode":&"sparring","enemy_id":"boss_zhao_wuji"})) == NEW_ROOT + "battle_spar.wav", "sparring priority above boss")
	battle.free()
	audio.call("play_bgm", base, 0.03, "qa_same")
	await _wait(0.35)
	var active := _player()
	var initial := active.get_playback_position()
	audio.call("play_bgm", base, 0.03, "qa_same")
	await _wait(0.08)
	_check(_player() == active and active.playing and active.get_playback_position() >= initial, "same track does not restart")
	var wraps: Array[Dictionary] = []
	for path: String in [base, NEW_ROOT + "battle_default.wav"]:
		audio.call("play_bgm", path, 0.03, "qa_wrap")
		await _wait(0.15)
		var player := _player()
		var length := player.stream.get_length()
		player.seek(length - 0.8)
		await _wait(0.12)
		var near_end := player.get_playback_position()
		await _wait(1.05)
		var wrapped := player.get_playback_position()
		_check(player.playing and near_end > length - 1.0 and wrapped < 2.0, "natural decoder loop crossing after seek " + path)
		wraps.append({"path":path,"length":length,"seek":length-0.8,"before":near_end,"after":wrapped,"still_playing":player.playing})
	observations["seek_assisted_natural_crossings_not_full_loop_listening"] = wraps
	# Rapid A/B/A must leave only the current player after outgoing timers finish.
	audio.call("play_bgm", base, 0.12, "qa_rapid_a")
	audio.call("play_bgm", NEW_ROOT + "city_luoyang.wav", 0.12, "qa_rapid_b")
	audio.call("play_bgm", base, 0.12, "qa_rapid_a_again")
	await _wait(0.36)
	for key: String in ["_bgm_player_a", "_bgm_player_b"]:
		var player := audio.get(key) as AudioStreamPlayer
		_check(player.playing if player == _player() else not player.playing and player.stream == null, "crossfade no stale outgoing " + key)
	_check(bool(bridge.call("is_checkpoint_saves_suspended")), "checkpoint suspension held through finish")
	_check(_no_field(), "no gameplay scene or Field at finish")
	_finish()

func _finish() -> void:
	var output := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--result="): output = arg.trim_prefix("--result=")
	if output.is_empty() or not output.replace("\\", "/").begins_with(OUT) or FileAccess.file_exists(output):
		push_error("[AUDIO INSTALL QA] absent, outside or existing result path")
		quit(1)
		return
	var report := {"checks":checks,"failures":failures,"pass":failures.is_empty(),"observations":observations,"checkpoint_suspension_held":bool(bridge.call("is_checkpoint_saves_suspended")),"no_field":_no_field(),"scope":"LIMITED_AUDIO_RUNTIME_NOT_GAMEPLAY_OR_EAR_REVIEW"}
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("[AUDIO INSTALL QA] cannot write result")
		quit(1)
		return
	file.store_string(JSON.stringify(report,"\t") + "\n")
	file.close()
	print("[AUDIO INSTALL QA] ", checks, " checks / ", failures.size(), " failures; ", output)
	quit(0 if failures.is_empty() else 1)
