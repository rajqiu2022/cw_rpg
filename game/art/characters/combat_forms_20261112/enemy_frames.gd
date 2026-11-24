extends RefCounted

const ROOT := "res://art/characters/combat_forms_20261112/"
const SIGNATURES := {
	&"boss_zhao_wuji": {&"zhao_black_wind_sweep": "zhao.png"},
	&"ch6_archive_reclaimer": {&"mingwu_yinying_duoming": "archive.png"},
	&"wild_elite_snow": {&"gufeng_fuhu": "elite.png"},
}
const EXPANSION_ROOT := "res://art/sprites/battle/enemy_expansion_20261112/"
const STORY_ROOT := "res://art/sprites/battle/story_duels_20261121/"
const SPARRING_ROOT := "res://art/sprites/battle/field_sparring_20261121/"
const SQUAD_ROOT := "res://art/sprites/battle/story_squads_20261121/"
const FOREST_ROOT := "res://art/sprites/battle/north_forest_20261122/"
const ARCHIVE_ROAD_ROOT := "res://art/sprites/battle/ch6_mingwu_20261122/"
const FERRY_OFFICE_ROOT := "res://art/sprites/battle/ch7_ferry_office_20261122/"
const TOMB_DOCK_ROOT := "res://art/sprites/battle/tomb_docks_20261122/"
const SNOW_MINE_ROOT := "res://art/sprites/battle/snow_mine_20261122/"
const FRAME_FOLDERS := {
	&"ch6_archive_shelf_guard": {&"ch6_oiled_darts": ARCHIVE_ROAD_ROOT + "tracker/darts"},
	&"ch6_archive_lamp_guard": {&"toxic_needle": TOMB_DOCK_ROOT + "spy/needle"},
	&"ch7_pulse_current_guard": {&"ch7_current_cut": TOMB_DOCK_ROOT + "spy/sweep"},
	&"ch7_pulse_wrist_guard": {&"ch7_wrist_tap": TOMB_DOCK_ROOT + "shadow/mist"},
	&"ch5_snow_pass_pursuer": {
		&"gufeng_fuhu": SNOW_MINE_ROOT + "ridge/tiger",
		&"heavy_swing": SNOW_MINE_ROOT + "ridge/heavy",
	},
	&"ch5_mine_tunnel_hunter": {
		&"mingwu_saofeng": SNOW_MINE_ROOT + "hunter/sweep",
		&"toxic_needle": SNOW_MINE_ROOT + "hunter/needle",
	},
	&"mingwu_infiltrator": {
		&"mingwu_yinying_duoming": TOMB_DOCK_ROOT + "infiltrator/volley",
	},
	&"mingwu_spy": {
		&"mingwu_saofeng": TOMB_DOCK_ROOT + "spy/sweep",
		&"toxic_needle": TOMB_DOCK_ROOT + "spy/needle",
	},
	&"mingwu_shadow": {
		&"mingwu_wuyin_sanshi": TOMB_DOCK_ROOT + "shadow/mist",
	},
	&"ch7_lieyun_hardliner_guard": {
		&"heavy_swing": FERRY_OFFICE_ROOT + "patrol/heavy",
		&"toxic_needle": FERRY_OFFICE_ROOT + "patrol/needle",
	},
	&"ch7_lieyun_hardliner_tracker": {
		&"blood_shadow_scattering_darts": FERRY_OFFICE_ROOT + "trail/darts",
		&"toxic_needle": FERRY_OFFICE_ROOT + "trail/needle",
	},
	&"ch7_mingwu_record_guard": {
		&"mingwu_wuyin_sanshi": FERRY_OFFICE_ROOT + "keeper/mist",
		&"toxic_needle": FERRY_OFFICE_ROOT + "keeper/needle",
		&"mingwu_counterseal_needles": FERRY_OFFICE_ROOT + "keeper/seal",
	},
	&"ch7_mingwu_order_burner": {
		&"blood_shadow_scattering_darts": FERRY_OFFICE_ROOT + "burner/darts",
		&"toxic_needle": FERRY_OFFICE_ROOT + "burner/needle",
	},
	&"ch6_archive_burner": {
		&"mingwu_saofeng": ARCHIVE_ROAD_ROOT + "burner/sweep",
		&"toxic_needle": ARCHIVE_ROAD_ROOT + "burner/needle",
	},
	&"ch6_convoy_pursuer": {
		&"mingwu_wuyin_sanshi": ARCHIVE_ROAD_ROOT + "pursuer/mist",
		&"toxic_needle": ARCHIVE_ROAD_ROOT + "pursuer/needle",
	},
	&"ch6_convoy_tracker": {
		&"mingwu_saofeng": ARCHIVE_ROAD_ROOT + "tracker/sweep",
		&"blood_shadow_scattering_darts": ARCHIVE_ROAD_ROOT + "tracker/darts",
	},
	&"masked_killer_minion": {&"toxic_needle": FOREST_ROOT + "minion/needle"},
	&"masked_killer_elite": {&"toxic_needle": FOREST_ROOT + "elite/needle"},
	&"ch5_false_liuyun_striker": {
		&"heavy_swing": SQUAD_ROOT + "striker/chop",
		&"toxic_needle": SQUAD_ROOT + "striker/needle",
	},
	&"ch8_mistwood_blockade_guard": {
		&"mingwu_wuyin_sanshi": SQUAD_ROOT + "blockade/mist",
		&"toxic_needle": SQUAD_ROOT + "blockade/needle",
	},
	&"ch8_mistwood_signal_burner": {
		&"blood_shadow_scattering_darts": SQUAD_ROOT + "signal/darts",
		&"toxic_needle": SQUAD_ROOT + "signal/needle",
	},
	&"ch8_mechanism_warden": {
		&"mingwu_wuyin_sanshi": SQUAD_ROOT + "warden/mist",
		&"toxic_needle": SQUAD_ROOT + "warden/needle",
	},
	&"ch8_mist_valve_keeper": {
		&"blood_shadow_scattering_darts": SQUAD_ROOT + "valve/darts",
		&"toxic_needle": SQUAD_ROOT + "valve/needle",
	},
	&"luoyang_patrol": {
		&"huashan_yijian": SPARRING_ROOT + "luoyang_patrol/thrust",
	},
	&"boss_luoyang_captain": {
		&"heavy_swing": SPARRING_ROOT + "boss_luoyang_captain/sweep",
	},
	&"gufeng_trainee": {
		&"gufeng_kaishan_yidao": SPARRING_ROOT + "gufeng_trainee/cleave",
	},
	&"lingyue_guard": {
		&"lingyue_lingbo_yizhi": SPARRING_ROOT + "lingyue_guard/point",
	},
	&"wandering_blademaster": {
		&"gufeng_kaishan_yidao": SPARRING_ROOT + "wandering_blademaster/cleave",
		&"gufeng_fuhu": SPARRING_ROOT + "wandering_blademaster/tiger",
	},
	&"ch8_su_wusheng_final": {&"ch8_su_teapot_meridian_rain": EXPANSION_ROOT + "su_teapot"},
	&"ch8_xueying_last_guard": {&"ch8_xueying_shadow_fan": EXPANSION_ROOT + "xueying_shadow"},
	&"ch5_false_banner_captain": {
		&"ch5_false_banner_signal": STORY_ROOT + "captain/banner",
		&"zhao_broken_gate_strike": STORY_ROOT + "captain/cleave",
	},
	&"ch8_false_order_courier": {
		&"mingwu_wuyin_sanshi": STORY_ROOT + "courier/mist",
		&"toxic_needle": STORY_ROOT + "courier/needle",
	},
	&"ch8_false_order_escort": {
		&"mingwu_wuyin_sanshi": STORY_ROOT + "escort/mist",
		&"blood_shadow_scattering_darts": STORY_ROOT + "escort/darts",
	},
}

static func resolve(enemy_id: StringName, skill: Skill, fallback: Array[Texture2D]) -> Array[Texture2D]:
	if skill == null:
		return fallback
	var folder: String = FRAME_FOLDERS.get(enemy_id, {}).get(skill.skill_id, "")
	if not folder.is_empty():
		var new_frames: Array[Texture2D] = []
		for index in range(1, 5):
			var path := "%s/signature_%02d.tres" % [folder, index]
			var frame := load(path) as Texture2D if ResourceLoader.exists(path) else null
			if frame == null:
				return fallback
			new_frames.append(frame)
		return new_frames
	if not SIGNATURES.has(enemy_id):
		return fallback
	var file: String = SIGNATURES[enemy_id].get(skill.skill_id, "")
	if file.is_empty() or not ResourceLoader.exists(ROOT + file):
		return fallback
	var sheet := load(ROOT + file) as Texture2D
	if sheet == null or sheet.get_size() != Vector2(1536, 1024):
		return fallback
	var frames: Array[Texture2D] = []
	for index in 4:
		var frame := AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(16 + (index % 2) * 768, 12 + int(index / 2) * 512, 736, 500)
		frame.filter_clip = true
		frames.append(frame)
	return frames
