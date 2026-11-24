extends RefCounted

## Approved 2026-10-11 music selection. SceneScript resources keep their authored
## legacy paths; this catalog returns the actual path consumed by AudioManager.
const DIRECTORY := "res://art/audio/bgm/wuxia_20261011/"
const LINXI_DAY := "res://art/audio/bgm/bgm_linxi_village_full_20261111.wav"
const TRACK_IDS := [
	&"city_luoyang", &"city_bianzhou", &"city_jinling", &"city_xiangzhou",
	&"town_qinghe", &"pass_yanmen", &"village_zhuwei", &"village_night",
	&"outskirts_zhuxi_linxi", &"outskirts_forest_xiangzhou", &"outskirts_wetland_jinling",
	&"story_tension", &"story_warm", &"story_joy", &"story_danger",
	&"battle_spar", &"battle_river", &"battle_village", &"battle_mountain", &"battle_boss",
	&"exploration_mountain", &"exploration_journey", &"battle_default",
]
const SCENE_TRACKS := {
	# Temporary prosperous-market reuse; retain the original Luoyang track.
	&"ch4_s0_luoyang_gate": &"city_bianzhou",
	&"ch4_s1_luoyang_yamen": &"city_bianzhou",
	&"ch4_s2_canal_docks": &"city_bianzhou",
	&"ch4_s3_luoyang_market": &"city_bianzhou",
	&"openworld_bianzhou_city": &"city_bianzhou",
	&"openworld_jinling_city": &"city_jinling",
	&"openworld_xiangzhou_city": &"city_xiangzhou",
	&"openworld_qinghe_town": &"town_qinghe",
	&"openworld_yanmen_pass": &"pass_yanmen",
	&"ch1_s2_qingfeng": &"village_zhuwei",
	&"ch1_s2_qingfeng_walkable": &"village_zhuwei",
	&"ch2_s1_zhuwei_market": &"village_zhuwei",
	&"ch2_s1_market_inn": &"village_zhuwei",
	&"ch2_s1_market_training_hall": &"village_zhuwei",
	&"interior_inn_hall": &"village_zhuwei",
	&"ch6_s5_ancient_road_inn": &"exploration_journey",
	&"openworld_v15_bamboo_outskirts": &"outskirts_zhuxi_linxi",
	&"openworld_v15_forest_outskirts": &"outskirts_forest_xiangzhou",
	&"openworld_v15_marsh_outskirts": &"outskirts_wetland_jinling",
	&"openworld_jinling_reed_marsh": &"outskirts_wetland_jinling",
	&"openworld_bailu_ferry": &"exploration_journey",
	&"openworld_east_sea_port": &"exploration_journey",
}
const LINXI_DAY_SCENES := [
	&"ch1_s0_linxi_main_walkable", &"linxi_tutorial", &"linxi_village_center",
	&"linxi_village_scrollmap", &"linxi_hero_bedroom", &"linxi_master_hall",
	&"linxi_farmer_cottage", &"linxi_herbal_home", &"linxi_scholar_house",
	&"linxi_south_apothecary_home", &"linxi_south_scholar_house", &"linxi_south_villager_home",
	&"interior_martial_hall",
]
## Explicit fallback decisions for the former eight exploration arrangements.
## Dedicated regions above take priority; arbitrary new/unknown paths survive.
const LEGACY_EXPLORATION_TRACKS := {
	"res://art/audio/bgm/bgm_mountain_path_v4.wav": &"exploration_mountain",
	"res://art/audio/bgm/bgm_mountain_path_v5.wav": &"exploration_mountain",
	"res://art/audio/bgm/bgm_jianghu_journey_v4.wav": &"exploration_journey",
	"res://art/audio/bgm/bgm_forest_mystery_v4.wav": &"outskirts_forest_xiangzhou",
	"res://art/audio/bgm/bgm_forest_mystery_v5.wav": &"outskirts_forest_xiangzhou",
	"res://art/audio/bgm/bgm_cave_ominous_v4.wav": &"story_danger",
	"res://art/audio/bgm/bgm_cave_ominous_v5.wav": &"story_danger",
	"res://art/audio/bgm/bgm_sect_clouds_v4.wav": &"exploration_mountain",
	"res://art/audio/bgm/bgm_market_lively_v4.wav": &"village_zhuwei",
	"res://art/audio/bgm/bgm_city_ceremony_v4.wav": &"city_luoyang",
	"res://art/audio/bgm/bgm_village_day_v4.wav": &"village_zhuwei",
}
## Reviewed whole-dialogue moods, not keyword inference from dialogue text.
const DIALOG_TRACKS := {
	&"ch4_case_clue": &"story_tension",
	&"linxi_center_granny": &"story_warm",
	&"ch4_peony_poetry": &"story_joy",
	&"ch1_side_caravan_done": &"story_joy",
	&"ch4_temple_ambush": &"story_danger",
	&"ch1_road_corpse": &"story_danger",
}
## These authored nodes explicitly move from late afternoon to lamplight.
## There is no day/night simulation or permanent village-night override.
const DIALOG_NODE_TRACKS := {
	"ch8_false_order_prebattle:declare": &"story_tension",
	"ch8_master_ultimate_breakthrough:n6": &"village_night",
	"ch8_master_ultimate_breakthrough:n7": &"village_night",
}


static func track_path(track_id: StringName) -> String:
	if not TRACK_IDS.has(track_id):
		return ""
	return DIRECTORY + String(track_id) + ".wav"


static func scene_bgm(scene_id: StringName, legacy_path: String) -> String:
	if SCENE_TRACKS.has(scene_id):
		return track_path(SCENE_TRACKS[scene_id])
	if LINXI_DAY_SCENES.has(scene_id):
		return LINXI_DAY
	if LEGACY_EXPLORATION_TRACKS.has(legacy_path):
		return track_path(LEGACY_EXPLORATION_TRACKS[legacy_path])
	return legacy_path


static func dialog_bgm(dialog_id: StringName) -> String:
	return track_path(DIALOG_TRACKS[dialog_id]) if DIALOG_TRACKS.has(dialog_id) else ""


static func dialog_node_bgm(dialog_id: StringName, node_id: StringName) -> String:
	var key := "%s:%s" % [String(dialog_id), String(node_id)]
	return track_path(DIALOG_NODE_TRACKS[key]) if DIALOG_NODE_TRACKS.has(key) else ""


static func is_adopted_loop(path: String) -> bool:
	if path == LINXI_DAY:
		return true
	if not path.begins_with(DIRECTORY) or not path.ends_with(".wav"):
		return false
	return TRACK_IDS.has(StringName(path.trim_prefix(DIRECTORY).trim_suffix(".wav")))
