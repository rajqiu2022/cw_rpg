extends SceneTree

const APPROVED_FIELD_PATH := "res://art/audio/bgm/bgm_linxi_village_v6.wav"
const VICTORY_PATH := "res://art/audio/bgm/bgm_victory_v4_approved.wav"
const WUDANG_SCENES := [
	"res://data/scenes/openworld_wudang_gate.tres",
	"res://data/scenes/openworld_wudang_taiji_court.tres",
	"res://data/scenes/openworld_wudang_purple_cloud_court.tres",
]

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var wudang := load(APPROVED_FIELD_PATH) as AudioStreamWAV
	var victory := load(VICTORY_PATH) as AudioStreamWAV
	_check(wudang != null, "approved Linxi field cue imports as WAV")
	_check(victory != null, "approved victory v4 cue imports as WAV")
	if wudang != null:
		_check(wudang.get_length() >= 37.0 and wudang.get_length() <= 39.0, "approved field loop keeps the accepted full phrase")
		_check(wudang.mix_rate == 22050 and wudang.stereo, "approved field loop is 22.05kHz stereo")
	if victory != null:
		_check(victory.get_length() >= 7.9 and victory.get_length() <= 8.1, "victory cue is an eight-second celebration")
		_check(victory.mix_rate == 22050 and victory.stereo, "victory cue is 22.05kHz stereo")
	for scene_path: String in WUDANG_SCENES:
		var scene := load(scene_path) as SceneScript
		_check(scene != null and scene.bgm_path == APPROVED_FIELD_PATH, "Wudang district uses the accepted safe baseline: " + scene_path)
	var victory_script := FileAccess.get_file_as_string("res://scripts/ui/result_victory.gd")
	var audio_manager_script := FileAccess.get_file_as_string("res://scripts/autoload/audio_manager.gd")
	_check(victory_script.contains(VICTORY_PATH), "victory result screen requests approved v4 cue")
	_check(audio_manager_script.contains(VICTORY_PATH), "audio manager default requests approved v4 cue")
	print("[WuxiaAudioV7] checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[WuxiaAudioV7] " + label)
