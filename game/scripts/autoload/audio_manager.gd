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

var bgm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0

var bgm_volume: float = 1.0
var sfx_volume: float = 1.0
var ui_volume: float = 1.0

var _current_bgm_path: String = ""

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

	EventBus.scene_entered.connect(_on_scene_entered)

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

	if bgm_player.playing:
		_fade_to(bgm_player, -40.0, 0.25)
		await get_tree().create_timer(0.25).timeout
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
	_fade_to(bgm_player, -40.0, fade_out)
	await get_tree().create_timer(fade_out).timeout
	bgm_player.stop()
	bgm_player.stream = null
	_current_bgm_path = ""
	EventBus.bgm_changed.emit("")

func get_current_bgm() -> String:
	return _current_bgm_path

# --- SFX ---

func play_sfx(path: String, volume_offset: float = 0.0) -> void:
	if path.is_empty():
		return
	if not ResourceLoader.exists(path):
		push_warning("[AudioManager] SFX not found: %s" % path)
		return

	var stream := load(path) as AudioStream
	if stream == null:
		return

	var player := _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE

	player.stream = stream
	player.volume_db = _linear2db(sfx_volume) + volume_offset
	player.play()

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
		if not sd.bgm_path.is_empty() and sd.bgm_path != _current_bgm_path:
			play_bgm(sd.bgm_path)

func _has_bus(bus_name: StringName) -> bool:
	return AudioServer.get_bus_index(bus_name) != -1

func _linear2db(linear: float) -> float:
	if linear <= 0.0:
		return -80.0
	return linear_to_db(linear)

func _fade_to(player: AudioStreamPlayer, target_db: float, duration: float) -> void:
	var tw := create_tween()
	tw.tween_property(player, "volume_db", target_db, duration).set_ease(Tween.EASE_IN_OUT)
