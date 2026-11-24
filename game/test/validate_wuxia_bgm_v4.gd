extends SceneTree

const EXPLORATION_TRACKS := [
	"bgm_jianghu_journey_v4.wav",
	"bgm_village_day_v4.wav",
	"bgm_mountain_path_v4.wav",
	"bgm_forest_mystery_v4.wav",
	"bgm_cave_ominous_v4.wav",
	"bgm_market_lively_v4.wav",
	"bgm_city_ceremony_v4.wav",
	"bgm_sect_clouds_v4.wav",
]
const BATTLE_TRACKS := [
	"bgm_battle_village_v4.wav",
	"bgm_battle_mountain_v4.wav",
	"bgm_battle_river_v4.wav",
	"bgm_battle_spar_v4.wav",
	"bgm_battle_boss_v4.wav",
]

var checks := 0
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_tracks()
	_validate_scene_mapping()
	_validate_battle_mapping()
	print("[WuxiaBgmV4] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[WuxiaBgmV4] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_tracks() -> void:
	for file_name: String in EXPLORATION_TRACKS + BATTLE_TRACKS:
		var path := "res://art/audio/bgm/%s" % file_name
		_check(ResourceLoader.exists(path), "配乐资源存在：%s" % file_name)
		var stream := load(path) as AudioStreamWAV
		_check(stream != null, "配乐导入为WAV流：%s" % file_name)
		if stream == null:
			continue
		_check(stream.stereo, "配乐使用立体声：%s" % file_name)
		_check(stream.mix_rate == 22050, "配乐采样率统一：%s" % file_name)
		_check(stream.get_length() >= (28.0 if file_name in BATTLE_TRACKS else 29.0), "配乐长度足够形成完整乐句：%s" % file_name)


func _validate_scene_mapping() -> void:
	var unique_tracks: Dictionary = {}
	var scene_dir := DirAccess.open("res://data/scenes")
	for file_name: String in scene_dir.get_files() if scene_dir != null else []:
		if not file_name.ends_with(".tres"):
			continue
		var scene := load("res://data/scenes/%s" % file_name) as SceneScript
		if scene == null:
			continue
		_check(scene.bgm_path.ends_with("_v4.wav"), "场景使用武侠v4主题：%s" % String(scene.scene_id))
		_check(ResourceLoader.exists(scene.bgm_path), "场景主题路径存在：%s" % String(scene.scene_id))
		unique_tracks[scene.bgm_path] = true
	_check(unique_tracks.size() >= 8, "探索场景保持八类独立主题")
	var audio_source := FileAccess.get_file_as_string("res://scripts/autoload/audio_manager.gd")
	_check(audio_source.contains("bgm_jianghu_journey_v4.wav") and audio_source.contains("bgm_battle_mountain_v4.wav"), "默认回退音乐也使用武侠v4")
	var generator_source := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../scripts/generate_wuxia_bgm_v4.py"))
	_check(generator_source.contains("bgm_field_bards_tale_cc0.mp3") and generator_source.contains("bgm_battle_medieval_cc0.mp3"), "v4沿用用户认可的早期音乐骨架")
	_check(not generator_source.contains("pluck("), "v4不再使用连续拨弦琶音层")


func _validate_battle_mapping() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	for file_name: String in BATTLE_TRACKS:
		_check(source.contains(file_name), "战斗运行时接入：%s" % file_name)
	_check(source.contains("_payload_has_chapter_boss") and source.contains("is_chapter_boss"), "章节Boss自动选择Boss战主题")
	_check(source.contains('battle_mode", &"")) == &"sparring"'), "NPC切磋自动选择切磋主题")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
