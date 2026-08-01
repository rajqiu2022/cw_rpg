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
const SFX_POOL_SIZE := 8
const FIELD_SCENE_DIR := "res://data/scenes/"
const DEFAULT_FIELD_BGM := "res://art/audio/cc0/bgm_field_bards_tale_cc0.mp3"
const DEFAULT_BATTLE_BGM := "res://art/audio/cc0/bgm_battle_medieval_cc0.mp3"
const DEFAULT_ATTACK_SFX := "res://art/audio/free/sfx_attack_free_v1.wav"
const DEFAULT_SKILL_SFX := "res://art/audio/free/sfx_skill_free_v1.wav"
const DEFAULT_HIT_SFX := "res://art/audio/free/sfx_hit_free_v1.wav"
const DEFAULT_DEFEND_SFX := "res://art/audio/free/sfx_defend_free_v1.wav"
const DEFAULT_CONFIRM_SFX := "res://art/audio/free/sfx_ui_confirm_free_v1.wav"
const DEFAULT_VICTORY_SFX := "res://art/audio/free/sfx_victory_free_v1.wav"
const DEFAULT_DEFEAT_SFX := "res://art/audio/free/sfx_defeat_free_v1.wav"

var bgm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

var bgm_volume: float = 1.0
var sfx_volume: float = 1.0
var ui_volume: float = 1.0

var _current_bgm_path: String = ""
var _bgm_request_id: int = 0

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = BGM_BUS if _has_bus(BGM_BUS) else &"Master"
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_player)

	var sfx_bus := SFX_BUS if _has_bus(SFX_BUS) else &"Master"
	for _i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = sfx_bus
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_pool.append(p)

	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = SFX_BUS if _has_bus(SFX_BUS) else &"Master"
	_voice_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_voice_player)

	# 预热音频设备，避免首次播放延迟
	_warmup_audio_device()

	EventBus.scene_entered.connect(_on_scene_entered)
	EventBus.sfx_requested.connect(_on_sfx_requested)


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

func play_bgm(path: String, crossfade: float = 0.8) -> void:
	if path.is_empty():
		return
	if path == _current_bgm_path and bgm_player.playing:
		return
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] BGM not found: %s" % path)
		return

	var stream := load(path) as AudioStream
	if stream == null:
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

	_bgm_request_id += 1
	var request_id := _bgm_request_id
	if bgm_player.playing:
		_fade_to(bgm_player, -40.0, 0.25)
		await get_tree().create_timer(0.25).timeout
		if request_id != _bgm_request_id:
			return
		bgm_player.stop()

	bgm_player.stream = stream
	bgm_player.volume_db = -40.0
	bgm_player.play()
	_current_bgm_path = path
	_fade_to(bgm_player, _linear2db(bgm_volume), crossfade)
	EventBus.bgm_changed.emit(path)

func stop_bgm(fade_out: float = 0.5) -> void:
	if not bgm_player.playing:
		return
	_bgm_request_id += 1
	var request_id := _bgm_request_id
	_fade_to(bgm_player, -40.0, fade_out)
	await get_tree().create_timer(fade_out).timeout
	if request_id != _bgm_request_id:
		return
	bgm_player.stop()
	bgm_player.stream = null
	_current_bgm_path = ""
	EventBus.bgm_changed.emit("")

func get_current_bgm() -> String:
	return _current_bgm_path

# --- SFX ---

var _sfx_cache: Dictionary = {}  ## path → AudioStream
var _voice_player: AudioStreamPlayer  ## 对话语音专用通道，不参与 SFX 池

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


func _on_sfx_requested(path: String, volume_offset: float) -> void:
	play_sfx(path, volume_offset)

func stop_all_sfx() -> void:
	for p in _sfx_pool:
		if p.playing:
			p.stop()
	_voice_player.stop()

# --- Voice (对话语音专用通道) ---

func play_voice(path: String) -> void:
	if path.is_empty(): return
	var stream: AudioStream = _sfx_cache.get(path)
	if stream == null:
		if not ResourceLoader.exists(path):
			return
		stream = load(path) as AudioStream
		if stream == null: return
		_sfx_cache[path] = stream
	_voice_player.stream = stream
	_voice_player.play()

func stop_voice() -> void:
	_voice_player.stop()

# --- Volume ---

func set_bgm_volume(linear: float) -> void:
	bgm_volume = clampf(linear, 0.0, 1.0)
	if bgm_player.playing:
		bgm_player.volume_db = _linear2db(bgm_volume)
	EventBus.audio_volume_changed.emit(&"bgm", bgm_volume)

func set_sfx_volume(linear: float) -> void:
	sfx_volume = clampf(linear, 0.0, 1.0)
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
	var path := "%s%s.tres" % [FIELD_SCENE_DIR, String(scene_id)]
	if not ResourceLoader.exists(path):
		return
	var res := load(path)
	if res is SceneScript:
		var sd := res as SceneScript
		var requested_path := sd.bgm_path
		if requested_path.is_empty() or requested_path.ends_with("bgm_test_440hz.wav"):
			requested_path = DEFAULT_FIELD_BGM
		if requested_path != _current_bgm_path:
			play_bgm(requested_path)

func play_ui_confirm() -> void:
	EventBus.sfx_requested.emit(DEFAULT_CONFIRM_SFX, -4.0)

func _has_bus(bus_name: StringName) -> bool:
	return AudioServer.get_bus_index(bus_name) != -1

func _linear2db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return linear_to_db(linear)

func _fade_to(player: AudioStreamPlayer, target_db: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(player, "volume_db", target_db, duration).set_ease(Tween.EASE_IN_OUT)
