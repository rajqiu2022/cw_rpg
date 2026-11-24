extends Node

## 全局音频管理 autoload。
##
## 职责：
##   - BGM 播放/停止/淡入淡出（专用 AudioStreamPlayer）
##   - SFX 池化播放（8 个 AudioStreamPlayer 轮转，避免重叠音效互相打断）
##   - 监听 EventBus.scene_entered，自动读取 SceneScript.bgm_path 切 BGM
##   - 音量控制（BGM / SFX / UI 三路独立，线段 0~1）
##
## Audio Bus 要求在编辑器中手动创建（Audio 面板）：
##   Master → BGM / SFX / UI
## 若对应 bus 不存在，自动 fallback 到 Master。

const BGM_BUS := &"BGM"
const SFX_BUS := &"SFX"
const UI_BUS  := &"UI"
const VOICE_BUS := &"Voice"
const SFX_POOL_SIZE := 8
const FIELD_SCENE_DIR := "res://data/scenes/"
const DEFAULT_FIELD_BGM := "res://art/audio/bgm/bgm_linxi_village_v6.wav"
const DEFAULT_BATTLE_BGM := "res://art/audio/bgm/bgm_battle_mountain_v4.wav"
const DEFAULT_ATTACK_SFX := "res://art/audio/free/sfx_blade_light_wuxia_v2.wav"
const DEFAULT_SKILL_SFX := "res://art/audio/free/sfx_palm_burst_wuxia_v2.wav"
const DEFAULT_HIT_SFX := "res://art/audio/free/sfx_hit_body_wuxia_v2.wav"
const SWORD_ATTACK_SFX := "res://art/audio/free/sfx_blade_light_wuxia_v2.wav"
const BLADE_ATTACK_SFX := "res://art/audio/free/sfx_blade_whoosh_wuxia_v2.wav"
const STAFF_ATTACK_SFX := "res://art/audio/free/sfx_staff_whoosh_wuxia_v2.wav"
const PALM_ATTACK_SFX := "res://art/audio/free/sfx_palm_burst_wuxia_v2.wav"
const METAL_HIT_SFX := "res://art/audio/free/sfx_hit_metal_wuxia_v2.wav"
const DEFAULT_DEFEND_SFX := "res://art/audio/free/sfx_defend_free_v1.wav"
const DEFAULT_CONFIRM_SFX := "res://art/audio/free/sfx_ui_confirm_free_v1.wav"
const DEFAULT_VICTORY_SFX := "res://art/audio/free/sfx_victory_free_v1.wav"
const DEFAULT_DEFEAT_SFX := "res://art/audio/free/sfx_defeat_free_v1.wav"
const DEFAULT_VICTORY_MUSIC := "res://art/audio/bgm/bgm_victory_v4_approved.wav"

var bgm_player: AudioStreamPlayer
var _bgm_player_a: AudioStreamPlayer
var _bgm_player_b: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _ambience_player: AudioStreamPlayer
var _music_sting_player: AudioStreamPlayer
var _music_sting_request_id := 0

var bgm_volume: float = 0.4
var sfx_volume: float = 1.0
var ui_volume: float = 1.0

var _current_bgm_path: String = ""
var _current_bgm_context: String = ""
var _bgm_request_id: int = 0
var _bgm_stop_pending := false
var _bgm_fade_tweens: Dictionary = {}
var _web_audio_unlocked := true
var _pending_bgm_path := ""
var _pending_bgm_crossfade := 0.18
var _pending_bgm_context := ""
var _current_ambience_path := ""
var _pending_ambience_path := ""
var _pending_ambience_volume_db := -14.0
var _ambience_request_id := 0
var _ambience_tween: Tween = null
var _platform_paused := false

func _ready() -> void:
	_web_audio_unlocked = not OS.has_feature("web")
	_bgm_player_a = _create_bgm_player("BgmPlayerA")
	_bgm_player_b = _create_bgm_player("BgmPlayerB")
	bgm_player = _bgm_player_a

	var sfx_bus := SFX_BUS if _has_bus(SFX_BUS) else &"Master"
	for _i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = sfx_bus
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_pool.append(p)

	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = sfx_bus
	_ambience_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_ambience_player)

	_music_sting_player = _create_bgm_player("MusicStingPlayer")

	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = VOICE_BUS if _has_bus(VOICE_BUS) else &"Master"
	_voice_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_voice_player)

	_narrator_player = AudioStreamPlayer.new()
	_narrator_player.bus = VOICE_BUS if _has_bus(VOICE_BUS) else &"Master"
	_narrator_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_narrator_player)

	# 预热音频设备，避免首次播放延迟
	# WebAudio由PlatformBridge的首次用户手势解锁。AudioStreamGenerator在
	# Web导出中无法走sample播放路径，强行预热会产生无意义警告。
	if not OS.has_feature("web"):
		_warmup_audio_device()

	EventBus.scene_entered.connect(_on_scene_entered)
	EventBus.sfx_requested.connect(_on_sfx_requested)
	var platform := get_node_or_null("/root/PlatformBridge")
	if platform != null and platform.has_signal("user_gesture_detected"):
		platform.user_gesture_detected.connect(unlock_from_user_gesture)
	_preload_core_battle_sfx()


func _create_bgm_player(node_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = node_name
	player.bus = BGM_BUS if _has_bus(BGM_BUS) else &"Master"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	return player


func _warmup_audio_device() -> void:
	# 以零音量播放一帧静音脉冲，初始化 AudioServer 管线
	var pulse := AudioStreamGenerator.new()
	pulse.mix_rate = 44100
	pulse.buffer_length = 0.01
	_voice_player.stream = pulse
	_voice_player.volume_db = -80.0
	_voice_player.play()
	await get_tree().process_frame
	_voice_player.stop()
	_voice_player.stream = null
	_voice_player.volume_db = 0.0

# --- BGM ---

func play_bgm(path: String, crossfade: float = 0.18, context: String = "") -> void:
	if path.is_empty():
		return
	path = _normalized_audio_path(path)
	stop_music_sting()
	if not _web_audio_unlocked:
		_pending_bgm_path = path
		_pending_bgm_crossfade = crossfade
		_pending_bgm_context = context
		return
	# Scene context selects an entry phrase only on an actual track change.
	# The same song must continue through rooms, loading and scene refreshes.
	if path == _current_bgm_path and (bgm_player.playing or bgm_player.stream_paused):
		_current_bgm_context = context
		_cancel_pending_bgm_stop()
		return
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] BGM not found: %s" % path)
		return

	var stream := load(path) as AudioStream
	if stream == null:
		return
	if (bgm_player.playing or bgm_player.stream_paused) and bgm_player.stream != null and (
		stream == bgm_player.stream or _normalized_audio_path(stream.resource_path) == _normalized_audio_path(bgm_player.stream.resource_path)
	):
		_current_bgm_path = path
		_current_bgm_context = context
		_cancel_pending_bgm_stop()
		return
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		# Imported WAVs default loop_end to 0. Enabling LOOP_FORWARD without
		# defining the end creates a zero-frame loop and `playing` becomes false
		# immediately on both WASAPI and release builds.
		wav.loop_begin = 0
		wav.loop_end = maxi(1, int(round(wav.get_length() * float(wav.mix_rate))))
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

	_bgm_request_id += 1
	var previous := bgm_player
	_bgm_stop_pending = false
	var incoming := _bgm_player_b if bgm_player == _bgm_player_a else _bgm_player_a
	incoming.stop()
	incoming.stream = stream
	incoming.stream_paused = false
	incoming.volume_db = -30.0
	incoming.play(_contextual_start_position(stream, context))
	bgm_player = incoming
	_current_bgm_path = path
	_current_bgm_context = context
	_fade_to(incoming, _linear2db(bgm_volume), maxf(0.06, crossfade))
	if previous != null and previous != incoming and previous.playing:
		_fade_to(previous, -40.0, maxf(0.08, crossfade))
		_stop_outgoing_bgm_after_fade(previous, maxf(0.08, crossfade))
	EventBus.bgm_changed.emit(path)


func _normalized_audio_path(path: String) -> String:
	var normalized := path.strip_edges().replace("\\", "/")
	if normalized.begins_with("uid://"):
		var uid := ResourceUID.text_to_id(normalized)
		if ResourceUID.has_id(uid):
			normalized = ResourceUID.get_id_path(uid)
	return normalized.simplify_path()


func _cancel_pending_bgm_stop() -> void:
	if not _bgm_stop_pending:
		return
	_bgm_stop_pending = false
	_bgm_request_id += 1
	_fade_to(bgm_player, _linear2db(bgm_volume), 0.08)


func unlock_from_user_gesture() -> void:
	if _web_audio_unlocked:
		return
	_web_audio_unlocked = true
	if not _pending_bgm_path.is_empty():
		var requested := _pending_bgm_path
		var requested_crossfade := _pending_bgm_crossfade
		var requested_context := _pending_bgm_context
		_pending_bgm_path = ""
		_pending_bgm_context = ""
		play_bgm(requested, requested_crossfade, requested_context)
	if not _pending_ambience_path.is_empty():
		var ambience_path := _pending_ambience_path
		var ambience_volume := _pending_ambience_volume_db
		_pending_ambience_path = ""
		play_ambience(ambience_path, ambience_volume)


func pause_for_platform() -> void:
	_platform_paused = true
	for player in [_bgm_player_a, _bgm_player_b]:
		if player != null and player.playing:
			player.stream_paused = true
	if _music_sting_player != null and _music_sting_player.playing:
		_music_sting_player.stream_paused = true
	if _ambience_player != null and _ambience_player.playing:
		_ambience_player.stream_paused = true
	stop_dialog_audio()


func resume_after_platform() -> void:
	if not _platform_paused:
		return
	_platform_paused = false
	if not _web_audio_unlocked:
		return
	var resumed := false
	for player in [_bgm_player_a, _bgm_player_b]:
		if player != null and (player.playing or player.stream_paused):
			player.stream_paused = false
			resumed = true
	if _music_sting_player != null and _music_sting_player.playing:
		_music_sting_player.stream_paused = false
		resumed = true
	if _ambience_player != null and _ambience_player.playing:
		_ambience_player.stream_paused = false
	if not resumed and not _current_bgm_path.is_empty():
		var restart_path := _current_bgm_path
		var restart_context := _current_bgm_context
		_current_bgm_path = ""
		play_bgm(restart_path, 0.08, restart_context)


func _contextual_start_position(stream: AudioStream, context: String) -> float:
	## Keep the approved original wuxia themes, but enter them at a stable phrase
	## per scene/encounter so every village and fight does not replay the same
	## opening bars.  Four quarter points are deliberate musical phrase seams in
	## the v4 arrangements, not random per-frame seeking.
	if context.is_empty():
		return 0.0
	var length := stream.get_length()
	if length < 24.0:
		return 0.0
	var phrase_entries: Array[float] = [0.0, length * 0.25, length * 0.50, length * 0.75]
	var phrase_hash: int = 2166136261
	for index in context.length():
		# Mix all characters and use middle bits.  Modulo-four on a simple rolling
		# sum over scene IDs collapsed common even suffixes onto the same seam.
		phrase_hash = ((phrase_hash ^ context.unicode_at(index)) * 16777619) & 0x7fffffff
	var phrase_slot := (phrase_hash >> 8) % phrase_entries.size()
	return minf(phrase_entries[phrase_slot], length - 4.0)


func _stop_outgoing_bgm_after_fade(player: AudioStreamPlayer, duration: float) -> void:
	await get_tree().create_timer(duration + 0.02).timeout
	if player != null and player != bgm_player:
		player.stop()
		player.stream = null


func ensure_bgm_for_scene(scene_id: StringName) -> void:
	var path := "%s%s.tres" % [FIELD_SCENE_DIR, String(scene_id)]
	if not ResourceLoader.exists(path):
		play_bgm(DEFAULT_FIELD_BGM, 0.12, String(scene_id))
		return
	var scene := load(path) as SceneScript
	var requested := scene.bgm_path if scene != null else ""
	if requested.is_empty() or not ResourceLoader.exists(requested):
		requested = DEFAULT_FIELD_BGM
	play_bgm(requested, 0.12, String(scene_id))

func stop_bgm(fade_out: float = 0.5) -> void:
	stop_music_sting()
	if not _bgm_player_a.playing and not _bgm_player_b.playing and not _bgm_player_a.stream_paused and not _bgm_player_b.stream_paused:
		return
	_bgm_request_id += 1
	_bgm_stop_pending = true
	var request_id := _bgm_request_id
	_fade_to(_bgm_player_a, -40.0, fade_out)
	_fade_to(_bgm_player_b, -40.0, fade_out)
	await get_tree().create_timer(fade_out).timeout
	if request_id != _bgm_request_id:
		return
	_bgm_player_a.stop()
	_bgm_player_b.stop()
	_bgm_player_a.stream = null
	_bgm_player_b.stream = null
	_bgm_stop_pending = false
	_current_bgm_path = ""
	_current_bgm_context = ""
	EventBus.bgm_changed.emit("")

func get_current_bgm() -> String:
	return _current_bgm_path


func play_music_sting(path: String = DEFAULT_VICTORY_MUSIC, max_duration: float = 8.0) -> void:
	## Short non-looping celebration used by result screens. It owns a separate
	## BGM-bus player so SFX remain audible and field music can replace it cleanly.
	if path.is_empty() or not ResourceLoader.exists(path) or _music_sting_player == null:
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false
	_music_sting_request_id += 1
	var request_id := _music_sting_request_id
	_bgm_request_id += 1
	for player in [_bgm_player_a, _bgm_player_b]:
		if player != null and player.playing:
			_fade_to(player, -40.0, 0.10)
	_stop_regular_bgm_for_sting_after_fade(request_id, 0.10)
	_music_sting_player.stop()
	_music_sting_player.stream = stream
	_music_sting_player.volume_db = _linear2db(bgm_volume)
	_music_sting_player.play(0.0)
	await get_tree().create_timer(minf(maxf(0.5, max_duration), stream.get_length())).timeout
	if request_id != _music_sting_request_id or _music_sting_player == null:
		return
	_fade_to(_music_sting_player, -40.0, 0.30)
	await get_tree().create_timer(0.32).timeout
	if request_id == _music_sting_request_id:
		_music_sting_player.stop()
		_music_sting_player.stream = null


func _stop_regular_bgm_for_sting_after_fade(request_id: int, duration: float) -> void:
	await get_tree().create_timer(duration + 0.02).timeout
	if request_id != _music_sting_request_id:
		return
	for player in [_bgm_player_a, _bgm_player_b]:
		if player != null:
			player.stop()
			player.stream = null
	_current_bgm_path = ""
	_current_bgm_context = ""


func stop_music_sting() -> void:
	_music_sting_request_id += 1
	if _music_sting_player != null:
		_music_sting_player.stop()
		_music_sting_player.stream = null


# --- Environmental ambience ---

func play_ambience(path: String, volume_offset_db: float = -14.0, fade_in: float = 0.35) -> void:
	if path.is_empty():
		stop_ambience(fade_in)
		return
	if not _web_audio_unlocked:
		_pending_ambience_path = path
		_pending_ambience_volume_db = volume_offset_db
		return
	_pending_ambience_volume_db = volume_offset_db
	if path == _current_ambience_path and _ambience_player.playing:
		_fade_ambience_to(_linear2db(sfx_volume) + volume_offset_db, fade_in)
		return
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] ambience not found: %s" % path)
		return
	var stream := load(path) as AudioStream
	if stream == null:
		return
	_enable_stream_loop(stream)
	_ambience_request_id += 1
	_ambience_player.stop()
	_ambience_player.stream = stream
	_ambience_player.volume_db = -40.0
	_ambience_player.play(0.0)
	_current_ambience_path = path
	_fade_ambience_to(_linear2db(sfx_volume) + volume_offset_db, maxf(0.06, fade_in))


func stop_ambience(fade_out: float = 0.30) -> void:
	_pending_ambience_path = ""
	if _ambience_player == null or not _ambience_player.playing:
		_current_ambience_path = ""
		return
	_ambience_request_id += 1
	var request_id := _ambience_request_id
	_fade_ambience_to(-40.0, maxf(0.06, fade_out))
	await get_tree().create_timer(maxf(0.06, fade_out) + 0.02).timeout
	if request_id != _ambience_request_id:
		return
	_ambience_player.stop()
	_ambience_player.stream = null
	_current_ambience_path = ""


func ensure_ambience_for_scene(scene_id: StringName) -> void:
	var path := "%s%s.tres" % [FIELD_SCENE_DIR, String(scene_id)]
	if not ResourceLoader.exists(path):
		stop_ambience()
		return
	var scene := load(path) as SceneScript
	if scene == null or scene.ambience_path.is_empty():
		stop_ambience()
		return
	play_ambience(scene.ambience_path, scene.ambience_volume_db)


func get_current_ambience() -> String:
	return _current_ambience_path


func _enable_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_begin = 0
		wav.loop_end = maxi(1, int(round(wav.get_length() * float(wav.mix_rate))))
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true


func _fade_ambience_to(target_db: float, duration: float) -> void:
	if _ambience_tween != null and _ambience_tween.is_valid():
		_ambience_tween.kill()
	_ambience_tween = create_tween()
	_ambience_tween.tween_property(_ambience_player, "volume_db", target_db, duration).set_ease(Tween.EASE_IN_OUT)

# --- SFX ---

var _sfx_cache: Dictionary = {}  ## path → AudioStream
var _voice_player: AudioStreamPlayer  ## 角色对白专用通道，不参与 SFX 池
var _narrator_player: AudioStreamPlayer  ## 旁白独立通道

func play_sfx(path: String, volume_offset: float = 0.0) -> void:
	if path.is_empty():
		return

	var stream: AudioStream = _sfx_cache.get(path)
	if stream == null:
		if not ResourceLoader.exists(path):
			push_warning("[AudioManager] SFX not found: %s" % path)
			return
		stream = load(path) as AudioStream
		if stream == null:
			return
		_sfx_cache[path] = stream

	var player := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE

	player.stream = stream
	player.volume_db = _linear2db(sfx_volume) + volume_offset
	player.play()


func _preload_core_battle_sfx() -> void:
	for path in [
		DEFAULT_ATTACK_SFX,
		DEFAULT_SKILL_SFX,
		DEFAULT_HIT_SFX,
		SWORD_ATTACK_SFX,
		BLADE_ATTACK_SFX,
		STAFF_ATTACK_SFX,
		PALM_ATTACK_SFX,
		METAL_HIT_SFX,
		DEFAULT_DEFEND_SFX,
		DEFAULT_VICTORY_SFX,
		DEFAULT_DEFEAT_SFX,
		"res://art/audio/free/sfx_legendary_title_reveal_v2.wav",
	]:
		_load_cached_audio(path)


func _on_sfx_requested(path: String, volume_offset: float) -> void:
	play_sfx(path, volume_offset)

func stop_all_sfx() -> void:
	for p in _sfx_pool:
		if p.playing:
			p.stop()
	_voice_player.stop()
	_narrator_player.stop()

# --- Voice (对话语音专用通道) ---

func play_voice(path: String) -> void:
	play_dialog_voice(path)


func play_dialog_voice(path: String) -> void:
	if path.is_empty(): return
	var stream: AudioStream = _load_cached_audio(path)
	if stream == null: return
	# 不要 await — 直接切换流开始播放
	_voice_player.stop()
	_voice_player.stream = stream
	_voice_player.play(0.0)


func play_narration(path: String) -> void:
	if path.is_empty(): return
	var stream: AudioStream = _load_cached_audio(path)
	if stream == null: return
	_narrator_player.stop()
	_narrator_player.stream = stream
	_narrator_player.play(0.0)

func stop_voice() -> void:
	_voice_player.stop()
	_narrator_player.stop()


func stop_dialog_audio() -> void:
	stop_voice()

func is_voice_playing() -> bool:
	return _voice_player.playing


func is_narration_playing() -> bool:
	return _narrator_player.playing


func preload_audio(path: String) -> void:
	_load_cached_audio(path)


func _load_cached_audio(path: String) -> AudioStream:
	var stream: AudioStream = _sfx_cache.get(path)
	if stream != null:
		return stream
	if not ResourceLoader.exists(path):
		return null
	stream = load(path) as AudioStream
	if stream != null:
		_sfx_cache[path] = stream
	return stream

# --- Volume ---

func set_bgm_volume(linear: float) -> void:
	bgm_volume = clampf(linear, 0.0, 1.0)
	for player in [_bgm_player_a, _bgm_player_b]:
		if player != null and player.playing:
			player.volume_db = _linear2db(bgm_volume)
	if _music_sting_player != null and _music_sting_player.playing:
		_music_sting_player.volume_db = _linear2db(bgm_volume)
	EventBus.audio_volume_changed.emit(&"bgm", bgm_volume)

func set_sfx_volume(linear: float) -> void:
	sfx_volume = clampf(linear, 0.0, 1.0)
	if _ambience_player != null and _ambience_player.playing:
		_ambience_player.volume_db = _linear2db(sfx_volume) + _pending_ambience_volume_db
	EventBus.audio_volume_changed.emit(&"sfx", sfx_volume)

func set_ui_volume(linear: float) -> void:
	ui_volume = clampf(linear, 0.0, 1.0)
	EventBus.audio_volume_changed.emit(&"ui", ui_volume)

func get_volumes() -> Dictionary:
	return {"bgm": bgm_volume, "sfx": sfx_volume, "ui": ui_volume}

func set_volumes(d: Dictionary) -> void:
	if d.has("bgm"): set_bgm_volume(float(d["bgm"]))
	if d.has("sfx"): set_sfx_volume(float(d["sfx"]))
	if d.has("ui"):  set_ui_volume(float(d["ui"]))

# --- internal ---

func _on_scene_entered(scene_id: StringName) -> void:
	ensure_bgm_for_scene(scene_id)
	var weather_manager := get_node_or_null("/root/WeatherManager")
	if weather_manager != null and bool(weather_manager.call("has_active_weather_for_scene_id", scene_id)):
		return
	ensure_ambience_for_scene(scene_id)

func play_ui_confirm() -> void:
	EventBus.sfx_requested.emit(DEFAULT_CONFIRM_SFX, -4.0)

func _has_bus(bus_name: StringName) -> bool:
	return AudioServer.get_bus_index(bus_name) != -1

func _linear2db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return linear_to_db(linear)

func _fade_to(player: AudioStreamPlayer, target_db: float, duration: float) -> void:
	if player == null:
		return
	var key := player.get_instance_id()
	var existing: Tween = _bgm_fade_tweens.get(key) as Tween
	if existing != null and existing.is_valid():
		existing.kill()
	var tw := create_tween()
	_bgm_fade_tweens[key] = tw
	tw.tween_property(player, "volume_db", target_db, duration).set_ease(Tween.EASE_IN_OUT)
