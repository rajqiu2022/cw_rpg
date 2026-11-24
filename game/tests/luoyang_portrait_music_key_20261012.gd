extends SceneTree
## Short resource/audio-only check. No scene_entered emission, Field, save or travel.
const MUSIC = preload("res://scripts/audio/music_catalog.gd")
const CATALOG := "res://data/npcs/npc_catalog.tres"
const PORTRAIT := "res://art/characters/portraits/luoyang_20261012/portrait_luoyang_gate_sergeant_mature_20261012_v1.png"
const TRACK := "res://art/audio/bgm/wuxia_20261011/city_bianzhou.wav"
const BEFORE := "res://build/luoyang_portrait_music_source_before_20261012/2c9542e782c146cf83c017b62b1273a2/"
const IDS := [&"ch4_s0_luoyang_gate", &"ch4_s1_luoyang_yamen", &"ch4_s2_canal_docks", &"ch4_s3_luoyang_market"]
const PINS := {
	CATALOG: "1172cb8394619930bbc5cf9f4b875204f6835955add724113982791eb25354d8",
	PORTRAIT: "6d67f981b738228a6e8541104be86415b9c6192c51638a8ab672ee8360e9c0aa",
	TRACK: "1ec62fae51205248cb244a92078e9332369817a5ca0c504c60675eb3518dbe36",
	"res://scripts/audio/music_catalog.gd": "7ae3e331a71bf1b8c589a292def4d4f5963bb61136d410c643f0f49231bbe25c",
	"res://scripts/autoload/audio_manager.gd": "2a089d4b96d094559410ab8c8321f599172d974325f7ccda01a2df89e2c5a419",
	"res://scripts/domain/npc_profile.gd": "5fe2290b530837b1df36e79e4196f8ad37bd1dd6793bd11a1d17010a831cf8d6",
	"res://scripts/domain/npc_catalog.gd": "deb06f9cdca68068c3895486a26dcfd307d20d9eeb9799c42b1b2c0425ed9ec8",
	BEFORE + "music_catalog.gd.source": "cafbabdd3d82f1ebf6d694e9cc6f2eb2cf04744a4febb36a0503eb0cdf3c39e4",
	BEFORE + "npc_catalog.tres.source": "9aee67db9c9a4aa7f7fe5242c6c65ee80b6f092998974602baf9100dd1d4df34",
}
var checks := 0
var failures := 0
var records: Array[Dictionary] = []
var bgm_events: Array[String] = []
var first: Dictionary = {}
var output := ""

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("[LUOYANG PORTRAIT MUSIC KEY FAIL] " + label)
	return ok

func _file(path: String) -> Dictionary:
	var exists := FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ) if exists else null
	return {"exists": exists, "bytes": file.get_length() if file != null else 0, "sha256": FileAccess.get_sha256(path) if exists else "ABSENT", "mtime_seconds": FileAccess.get_modified_time(path) if exists else 0}

func _players() -> Dictionary:
	var files: Dictionary = {}
	for index in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path := "user://save_%d.json%s" % [index, suffix]
			files[path] = _file(path)
	return files

func _track_source(path: String) -> void:
	first[path] = _file(path)
	_check(first[path].exists, "consumed source exists " + path)

func _track_import(path: String) -> void:
	_track_source(path)
	_track_source(path + ".import")
	if not FileAccess.file_exists(path + ".import"): return
	var regex := RegEx.new()
	regex.compile('"(res://[^"\\r\\n]+)"')
	var compiled_count := 0
	for match_value: RegExMatch in regex.search_all(FileAccess.get_file_as_string(path + ".import")):
		var leaf := match_value.get_string(1)
		if leaf.begins_with("res://.godot/imported/"):
			_track_source(leaf)
			compiled_count += 1
	_check(compiled_count > 0, "actual compiled import destination tracked " + path)

func _source_delta() -> void:
	var text := FileAccess.get_file_as_string("res://scripts/audio/music_catalog.gd")
	text = text.replace("\t# Temporary prosperous-market reuse; retain the original Luoyang track.\n", "")
	for id: StringName in IDS:
		text = text.replace('\t&"' + String(id) + '": &"city_bianzhou",', '\t&"' + String(id) + '": &"city_luoyang",')
	_check(text == FileAccess.get_file_as_string(BEFORE + "music_catalog.gd.source"), "all non-Luoyang mappings/dialogues/functions remain exact original source")
	var catalog_text := FileAccess.get_file_as_string(CATALOG)
	var block := '[sub_resource type="Resource" id="luoyang_gate_sergeant_portrait"]\nscript = ExtResource("2_profile")\nnpc_id = &"luoyang_gate_sergeant"\nscene_ids = [&"ch4_s0_luoyang_gate"]\nportrait_path = "' + PORTRAIT + '"\nsprite_scale = 0.0\n\n'
	catalog_text = catalog_text.replace(block, "").replace('load_steps=14', 'load_steps=13').replace(', SubResource("luoyang_gate_sergeant_portrait")', "")
	_check(catalog_text == FileAccess.get_file_as_string(BEFORE + "npc_catalog.tres.source"), "only Gate portrait profile appended; all original NPC records exact")

func _portrait() -> void:
	var catalog := ResourceLoader.load(CATALOG, "Resource", ResourceLoader.CACHE_MODE_IGNORE)
	if not _check(catalog != null and catalog.has_method("find"), "actual ResourceLoader NPCCatalog"): return
	var profile: Resource = catalog.call("find", &"luoyang_gate_sergeant", IDS[0]) as Resource
	if not _check(profile != null, "Gate-specific profile found"): return
	var scene_ids: Variant = profile.get("scene_ids")
	_check(scene_ids is Array and scene_ids.size() == 1 and scene_ids[0] == IDS[0] and profile.get("npc_id") == &"luoyang_gate_sergeant", "exact single-scene native profile identity")
	_check(profile.get("portrait_path") == PORTRAIT and profile.get("sprite_scale") == 0.0 and profile.get("sprite_path") == "" and profile.get("walk_sprite_path") == "", "portrait-only profile leaves authored field scale/sprites intact")
	for id: StringName in [IDS[1], IDS[2], IDS[3], &"openworld_qinghe_town"]:
		_check(catalog.call("find", &"luoyang_gate_sergeant", id) == null, "cross-scene profile rejected " + String(id))
	var texture := ResourceLoader.load(PORTRAIT, "Texture2D") as Texture2D
	if not _check(texture != null and texture.get_width() > 0 and texture.get_height() > 0, "actual imported portrait Texture2D valid"): return
	var image := texture.get_image()
	_check(image != null and not image.is_empty(), "portrait native texture image available")
	records.append({"kind": "GATE_PORTRAIT_RESOURCE_ONLY", "profile_id": profile.get_instance_id(), "npc_id": String(profile.get("npc_id")), "scene_ids": [String(scene_ids[0])], "sprite_scale": profile.get("sprite_scale"), "portrait_path": texture.resource_path, "texture_class": texture.get_class(), "size": [texture.get_width(), texture.get_height()], "image_format": image.get_format() if image != null else -1, "dialogue_visible_tested": false})

func _snapshot(audio: Node) -> Dictionary:
	var player := audio.get("bgm_player") as AudioStreamPlayer
	var stream: AudioStream = player.stream if player != null else null
	var playback: AudioStreamPlayback = player.get_stream_playback() if player != null and player.playing else null
	return {"msec": Time.get_ticks_msec(), "driver": AudioServer.get_driver_name(), "selected_path": audio.call("get_current_bgm"), "context": audio.get("_current_bgm_context"), "request": audio.get("_bgm_request_id"), "player_id": player.get_instance_id() if player != null else 0, "stream_id": stream.get_instance_id() if stream != null else 0, "stream_path": stream.resource_path if stream != null else "", "playback_id": playback.get_instance_id() if playback != null else 0, "position": player.get_playback_position() if player != null else -1.0, "playing": player != null and player.playing, "paused": player != null and player.stream_paused, "pitch": player.pitch_scale if player != null else 0.0}

func _on_bgm_changed(path: String) -> void:
	bgm_events.append(path)

func _music() -> void:
	var audio: Node = root.get_node("AudioManager")
	var bus: Node = root.get_node("EventBus")
	bus.connect("bgm_changed", _on_bgm_changed)
	var previous: Dictionary = {}
	for id: StringName in IDS:
		var resolved: String = MUSIC.scene_bgm(id, "res://art/audio/bgm/bgm_city_ceremony_v4.wav")
		if not _check(resolved == TRACK, "actual MusicCatalog Luoyang mapping " + String(id)): break
		var before := _snapshot(audio)
		var event_count := bgm_events.size()
		audio.call("play_bgm", resolved, 0.12, "portrait_music_key:" + String(id))
		var immediate := _snapshot(audio)
		var until: int = Time.get_ticks_msec() + 400
		while Time.get_ticks_msec() < until:
			await process_frame
		var after := _snapshot(audio)
		_check(after.driver == "WASAPI" and after.playing and not after.paused and after.pitch == 1.0 and after.selected_path == TRACK and after.stream_path == TRACK and after.playback_id > 0, "real WASAPI normal selected stream playing")
		_check(after.position > immediate.position, "normal audio position advances without seek")
		if not previous.is_empty():
			var stable := true
			for key: String in ["request", "player_id", "stream_id", "playback_id"]:
				stable = stable and before[key] == previous[key] and immediate[key] == before[key] and after[key] == before[key]
			_check(stable and immediate.position >= before.position and after.position > previous.position and bgm_events.size() == event_count, "same-track request/player/stream/playback preserved; no restart/change event")
		records.append({"kind": "DIRECT_PLAY_BGM_NOT_FIELD_TRANSITION", "scene_catalog_id": String(id), "resolved": resolved, "before": before, "immediate": immediate, "after": after, "bgm_events": bgm_events.duplicate()})
		previous = after
	bus.disconnect("bgm_changed", _on_bgm_changed)

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended", true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true, "checkpoint held before first await through quit")
	var players := _players()
	var save: Node = root.get_node("SaveManager")
	var slot: Variant = save.get("active_slot")
	_check("--luoyang-portrait-music-key" in OS.get_cmdline_user_args(), "explicit short QA flag")
	output = "res://build/joint_world_luoyang_20261003_qa/luoyang_portrait_music_key_%d_%d/" % [OS.get_process_id(), Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK, "unique evidence directory")
	for path: String in PINS:
		_track_source(path)
		_check(first[path].sha256.to_lower() == PINS[path], "fixed current source SHA " + path)
	for path: String in [get_script().resource_path, "res://project.godot", "res://scripts/autoload/platform_bridge.gd", "res://scripts/autoload/save_manager.gd", "res://scripts/autoload/event_bus.gd"]: _track_source(path)
	_track_import(PORTRAIT)
	_track_import(TRACK)
	_source_delta()
	if failures == 0:
		_portrait()
		if failures == 0: await _music()
	var last: Dictionary = {}
	for path: String in first: last[path] = _file(path)
	_check(first == last and players == _players() and slot == save.get("active_slot") and bridge.call("is_checkpoint_saves_suspended") == true, "source/player15/slot/checkpoint preserved")
	_check(records.size() == 5, "portrait plus four short normal audio calls completed")
	var result := {"scope": "LUOYANG_GATE_PORTRAIT_RESOURCE_AND_FOUR_CATALOG_DIRECT_AUDIO_CALLS_ONLY", "checks": checks, "failures": failures, "complete": failures == 0, "records": records, "source_before": first, "source_after": last, "players_before": players, "players_after": _players(), "slot_before": slot, "slot_after": save.get("active_slot"), "actual_driver": AudioServer.get_driver_name(), "field_tested": false, "scene_transition_tested": false, "dialogue_portrait_visible_tested": false, "whole_music_continuity_or_listening_credit": false, "outer_precise_UTC_ticks_and_full_stderr_review_required": true}
	var file := FileAccess.open(output + "result.json", FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result, "\t"))
		file.close()
	_check(file != null and JSON.parse_string(FileAccess.get_file_as_string(output + "result.json")) is Dictionary, "result saved and read back")
	print("LUOYANG_PORTRAIT_MUSIC_KEY_RESULT=" + output + "result.json checks=" + str(checks) + " failures=" + str(failures))
	quit(0 if failures == 0 else 1)
