extends SceneTree

const RANDOM_SCENES := [
	"ch1_s1_road",
	"ch1_s3_zhuwei_forest",
	"ch1_s4_cave_mine_gallery",
	"ch1_s4_cave_waterway",
	"ch2_s2_forest_edge",
	"ch2_s6_river_camp",
	"ch3_s2_trial_ground",
	"ch3_s3_faction_training",
	"ch4_s5_temple_tunnel",
]

const MINE_SCENES := [
	"ch2_s5_bandit_cave",
	"ch2_s5_mine_workshop",
	"ch2_s5_mine_command",
]

const MINE_LAYOUTS := [
	"ch2_s5_bandit_cave_entrance_layout_v2",
	"ch2_s5_mine_workshop_layout_v2",
	"ch2_s5_mine_command_layout_v2",
]

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_party_scaling_and_formations()
	_validate_wolf_pack_and_alpha()
	_validate_three_stage_mine()
	_validate_solo_trials_and_reward_normalization()
	await _validate_mine_runtime()
	print("[EncounterRebalanceMine20260909] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[EncounterRebalanceMine20260909] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_party_scaling_and_formations() -> void:
	var luoyang_docks := load("res://data/scenes/ch4_s2_canal_docks.tres") as SceneScript
	_check(luoyang_docks.is_settlement and luoyang_docks.encounter_groups.is_empty(), "洛阳码头属于城市安全区，只保留显式任务战")
	var baseline := load("res://data/enemies/zhuwei_bandit.tres") as EnemyDef
	_check(baseline != null, "普通敌人数据可加载")
	if baseline != null:
		var solo := baseline.to_runtime_stats(0)
		var full_party := baseline.to_runtime_stats(2)
		_check(full_party.max_hp > solo.max_hp, "三人队伍会提高敌方耐久")
		_check(full_party.attack > solo.attack, "三人队伍只小幅提高敌方攻击")
		_check(full_party.max_hp >= roundi(float(solo.max_hp) * 1.40), "默认三人队伍耐久至少提高40%")
	var game_state := root.get_node_or_null("GameState")
	var party: Array = game_state.get("party") if game_state != null else []
	var original_party_size := party.size()
	while party.size() < 3:
		party.append(CharacterStats.new())
	if game_state != null:
		game_state.set("party", party)
	var router := root.get_node_or_null("SceneRouter")
	if router != null:
		var alpha_group: Array[StringName] = router.call("_expanded_single_enemy_group", &"zhuwei_cave_wolf")
		var zhao_group: Array[StringName] = router.call("_expanded_single_enemy_group", &"boss_zhao_wuji")
		_check(alpha_group.size() == 3 and alpha_group.count(&"zhuwei_pack_wolf") == 2, "三人队伍的狼王战补齐两只群狼")
		_check(zhao_group.size() == 3 and zhao_group.count(&"zhuwei_bandit") == 2, "三人队伍的章末Boss战补齐两名护卫")
	party.resize(original_party_size)
	if game_state != null:
		game_state.set("party", party)
	for scene_id: String in RANDOM_SCENES:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(scene != null, "随机战场景可加载：%s" % scene_id)
		if scene == null:
			continue
		_check(scene.encounter_enemy_ids.is_empty(), "随机战不再回退单敌：%s" % scene_id)
		_check(not scene.encounter_groups.is_empty(), "随机战拥有编队：%s" % scene_id)
		for group: Dictionary in scene.encounter_groups:
			var ids: Array = group.get("enemy_ids", [])
			_check(ids.size() >= 2 and ids.size() <= 3, "随机编队为2～3人：%s" % scene_id)


func _validate_wolf_pack_and_alpha() -> void:
	var pack := load("res://data/enemies/zhuwei_pack_wolf.tres") as EnemyDef
	var alpha := load("res://data/enemies/zhuwei_cave_wolf.tres") as EnemyDef
	_check(pack != null, "普通群狼数据存在")
	_check(alpha != null, "狼王数据存在")
	if alpha == null:
		return
	_check(alpha.battle_actor_scale >= 1.25, "狼王体型显著大于普通狼")
	_check(alpha.max_hp >= 200, "狼王拥有Boss级耐久")
	_check(alpha.ready_sfx_path.ends_with("sfx_wolf_alpha_howl_cc0_v1.mp3"), "狼王登场绑定专属狼嚎")
	_check(ResourceLoader.exists(alpha.ready_sfx_path), "狼嚎音频可加载")
	_check(alpha.party_reinforcement_ids.has(&"zhuwei_pack_wolf"), "狼王会随队伍规模呼来群狼")
	var mine_gallery := load("res://data/scenes/ch1_s4_cave_mine_gallery.tres") as SceneScript
	if mine_gallery != null:
		for group: Dictionary in mine_gallery.encounter_groups:
			var ids: Array = group.get("enemy_ids", [])
			_check(ids.size() in [2, 3], "狼群随机战为2～3只")


func _validate_three_stage_mine() -> void:
	for scene_id: String in MINE_SCENES:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(scene != null, "矿洞分段场景可加载：%s" % scene_id)
		if scene == null:
			continue
		_check(scene.is_walkable and scene.map_layout != null, "矿洞分段为可探索地图：%s" % scene_id)
		_check(scene.hotspots.is_empty(), "矿洞分段没有裸感叹号热点：%s" % scene_id)
		_check(ResourceLoader.exists(scene.background_path), "矿洞正式底图可加载：%s" % scene_id)
		var image := Image.load_from_file(ProjectSettings.globalize_path(scene.background_path))
		_check(image != null and image.get_size() == Vector2i(1536, 1024), "矿洞底图尺寸统一为1536×1024：%s" % scene_id)
	for layout_id: String in MINE_LAYOUTS:
		var layout := load("res://data/maps/%s.tres" % layout_id) as WalkableMapLayout
		_check(layout != null, "矿洞导航数据可加载：%s" % layout_id)
		if layout == null:
			continue
		_check(not layout.walkable_regions.is_empty(), "矿洞分段存在行走区域：%s" % layout_id)
		_check(not layout.portals.is_empty(), "矿洞分段存在成对路线入口：%s" % layout_id)
		for interaction: Dictionary in layout.interactions:
			var has_world_object := bool(interaction.get("visual_baked", false)) or not String(interaction.get("interaction_visual_kind", "")).is_empty() or not String(interaction.get("visual_texture", "")).is_empty()
			_check(has_world_object, "矿洞交互依附画面实物：%s/%s" % [layout_id, String(interaction.get("id", ""))])
	var sentry_dialog := FileAccess.get_file_as_string("res://data/dialogs/ch2_mine_workshop_sentries.tres")
	var leader_dialog := FileAccess.get_file_as_string("res://data/dialogs/ch2_hideout_battle.tres")
	_check(sentry_dialog.contains("battle_group:ch2_mine_sentry,ch2_mine_sentry"), "制牌作坊为双巡哨战")
	_check(leader_dialog.contains("battle_group:masked_killer_ambush,zhuwei_bandit,zhuwei_bandit"), "账房首领战为三人编队")


func _validate_solo_trials_and_reward_normalization() -> void:
	for faction: String in ["gufeng", "huashan", "lingyue", "mingwu", "wudang", "wanderer"]:
		var dialog_text := FileAccess.get_file_as_string("res://data/dialogs/ch3_%s_trial.tres" % faction)
		_check(dialog_text.contains("battle_solo_then:"), "门派/江湖考校明确为单人：%s" % faction)
	var router_source := FileAccess.get_file_as_string("res://scripts/autoload/scene_router.gd")
	var battle_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	_check(router_source.contains("func start_solo_battle") and router_source.contains('"solo_player": true'), "单人正式战入口已接入")
	_check(router_source.contains("party_reinforcement_ids"), "单敌Boss入口会按队伍规模补护卫")
	_check(battle_source.contains("support_reward_scale") and battle_source.contains("grant_guaranteed_items"), "多人编队奖励已归一化且不重复必掉物")


func _validate_mine_runtime() -> void:
	var router := root.get_node_or_null("SceneRouter")
	var packed := load("res://scenes/field_walkable.tscn") as PackedScene
	_check(router != null and packed != null, "探索场景运行依赖可用")
	if router == null or packed == null:
		return
	for scene_id: String in MINE_SCENES:
		router.set("_field_payload", {"scene_id": StringName(scene_id)})
		router.set("_current_field_id", StringName(scene_id))
		var field := packed.instantiate()
		root.add_child(field)
		await process_frame
		await process_frame
		var current: SceneScript = field.get("_current_scene") as SceneScript
		_check(current != null and String(current.scene_id) == scene_id, "矿洞运行态进入正确分段：%s" % scene_id)
		var background := field.get("_world_background") as Sprite2D
		_check(background != null and background.texture != null, "矿洞运行态显示正式底图：%s" % scene_id)
		field.queue_free()
		await process_frame


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
