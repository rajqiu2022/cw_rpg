extends Node

## 场景跳转 + 动作字符串解析中枢。
##
## 所有跨场景调度走这里：
##   - go_main_menu / go_field / start_battle / go_victory / go_defeat
##   - resolve_action(action_str)：DialogPlayer / FieldController 等统一调用
##
## action 字符串语法（详见 DialogNode.gd 注释）：
##   "dialog:<id>"          打开对话脚本
##   "battle:<id>"          启动战斗
##   "scene:<id>"           切换探索场景
##   "shop:<id>"            打开商店（M4）
##   "give_item:<id>:<n>"   给玩家物品
##   "give_gold:<n>"        给金币
##   "set_flag:<key>:<v>"   置 flag（v="true"/"false"/数字）
##   "accept_quest:<id>"    接受任务（→ QuestManager）
##   "complete_quest:<id>"  完成任务（→ QuestManager）
##   "open_inventory"       请求当前 Field 打开背包 UI（M5）
##   "open_equipment"       请求当前 Field 打开装备 UI（M5）
##   "open_quest_log"       请求当前 Field 打开任务面板（M3）
##   "chapter_end:<chapter>"进入章节结算（M6）
##   "play_bgm:<path>"      播放/切换 BGM（带 0.8s 交叉淡出）
##   "play_sfx:<path>"      播放一击音效
##   "stop_bgm"             停止当前 BGM（0.5s 淡出）
##   "end" 或 ""            空操作

const SCENE_MAIN_MENU := "res://scenes/main_menu.tscn"
const SCENE_BATTLE := "res://scenes/battle.tscn"
const SCENE_VICTORY := "res://scenes/result_victory.tscn"
const SCENE_DEFEAT := "res://scenes/result_defeat.tscn"
const SCENE_FIELD := "res://scenes/field.tscn"
const SCENE_FIELD_WALKABLE := "res://scenes/field_walkable.tscn"
const SCENE_SHOP := "res://scenes/shop.tscn"
const SCENE_BOUNTY_BOARD := "res://scenes/bounty_board.tscn"
const SCENE_CHAPTER_END := "res://scenes/chapter_end.tscn"
const START_FIELD_SCENE := &"linxi_tutorial"
const WORLD_MAP_SCENE := &"world_map_jianghu"
## Development-only layered map. The official world route remains v12 until
## every terrain tile, portal and return path passes art/navigation review.
const WORLD_MAP_STAGING_SCENE := &"world_map_jianghu_v13_staging"
const WORLD_MAP_V14_SCENE := &"world_map_jianghu_v14"
const WORLD_V14 = preload("res://scripts/world/world_map_v14_contract.gd")
const WORLD_MAP_V15_SCENE := &"world_map_jianghu_v15"
const WORLD_V15 = preload("res://scripts/world/world_map_v15_contract.gd")
const OUTSKIRTS = preload("res://scripts/world/outskirts_native_contract.gd")
const WORLD_MAP_REGION_PORTALS := {
	&"linxi_tutorial": &"linxi_village",
	&"linxi_village_center": &"linxi_village",
	&"linxi_village_scrollmap": &"linxi_village",
	&"ch1_s1_road": &"linxi_village",
	&"interior_bandit_cave": &"linxi_village",
	&"ch1_s2_qingfeng": &"zhuwei_village",
	&"ch1_s3_zhuwei_forest": &"zhuwei_village",
	&"ch1_zhuwei_cave_hub": &"zhuwei_village",
	&"ch1_zhuwei_cave_mine": &"zhuwei_village",
	&"ch1_zhuwei_cave_water": &"zhuwei_village",
	&"ch1_zhuwei_cave_goal": &"zhuwei_village",
	&"ch1_s4_ruin": &"zhuwei_village",
	&"ch2_s1_zhuwei_market": &"zhuwei_village",
	&"ch2_s4_lingyue_gate": &"lingyue",
	&"openworld_wudang_gate": &"wudang",
	&"ch3_s1_wulin_assembly": &"wudang",
	&"ch4_s0_luoyang_gate": &"luoyang",
	&"ch4_s1_luoyang_yamen": &"luoyang",
	&"ch4_s2_canal_docks": &"luoyang",
	&"ch4_s3_luoyang_market": &"luoyang",
	&"openworld_bianzhou_city": &"bianzhou",
	&"openworld_bianzhou_old_post": &"bianzhou",
	&"openworld_xiangzhou_city": &"xiangzhou",
	&"openworld_xiangzhou_mine_valley": &"xiangzhou",
	&"openworld_jinling_city": &"jinling",
	&"openworld_jinling_reed_marsh": &"jinling",
	&"openworld_bailu_ferry": &"bailu_ferry",
	&"ch7_s1_lieyun_valley_ferry": &"lieyun_valley",
	&"ch7_s2_mingwu_tea_town": &"mingwu",
	&"ch7_s3_lieyun_outpost_outer_ward": &"lieyun_valley",
	&"ch7_s4_mingwu_manor_outer_court": &"mingwu",
	&"ch7_s5_lieyun_assembly_hall": &"lieyun_valley",
	&"ch7_s6_mingwu_inner_court": &"mingwu",
	&"ch7_s7_lieyun_resettlement_archive": &"lieyun_valley",
	&"ch7_s8_mingwu_permission_archive": &"mingwu",
	&"ch7_s9_mingwu_seal_audit_room": &"mingwu",
	&"ch7_s10_lieyun_night_transfer_station": &"lieyun_valley",
}
const CHAPTER_ENTRIES := {
	1: &"linxi_tutorial",
	2: &"ch2_s1_zhuwei_market",
	3: &"ch3_s1_wulin_assembly",
	4: &"ch4_s0_luoyang_gate",
	5: &"ch5_s1_relief_road",
	6: &"linxi_tutorial",
	7: &"world_map_jianghu",
	8: &"ch8_s1_alliance_staging_ground",
}
const FACTION_IDS := [&"wudang", &"huashan", &"gufeng", &"lingyue", &"mingwu"]
const FACTION_ENTRY_QUESTS := {
	&"wudang": &"q_ch3_wudang_investigate",
	&"huashan": &"q_ch3_huashan_unity",
	&"gufeng": &"q_ch3_gufeng_drink",
	&"lingyue": &"q_ch3_lingyue_clue",
	&"mingwu": &"q_ch3_mingwu_shadow",
	&"wanderer": &"q_ch3_wanderer_investigate",
}

const DIALOG_DIR := "res://data/dialogs/"
const FIELD_SCENE_DIR := "res://data/scenes/"
const ENEMY_DIR := "res://data/enemies/"

var _battle_payload: Dictionary = {}
var _field_payload: Dictionary = {}
var _shop_payload: Dictionary = {}
var _bounty_board_payload: Dictionary = {}
var _result_payload: Dictionary = {}
var _current_field_id: StringName = &""
var _current_field_spawn: Variant = null
var _world_map_return_scene: StringName = &""
var _active_world_map_scene: StringName = WORLD_MAP_SCENE
var _world_map_version: int = 12
## Last known walkable position on the source side of each portal route.
## Key format is "source_scene->target_scene". When the player traverses the
## reverse route, this puts them back at the doorway they actually used instead
## of trusting a stale hand-authored target_pos.
var _portal_return_spawns: Dictionary = {}


# --- 场景跳转 ---

func go_main_menu() -> void:
	# Staging world routing is deliberately transient. A menu exit must not
	# redirect an unrelated later save or new game back to the preview map.
	_active_world_map_scene = WORLD_MAP_SCENE
	_transition_to(SCENE_MAIN_MENU, &"startup", {"title": "返回卷首"})


func start_battle(
	enemy_id: String = "thug_lone",
	return_scene_id: StringName = &"",
	return_spawn: Variant = null,
	victory_action: String = ""
) -> void:
	var resolved_return_scene: StringName = return_scene_id if String(return_scene_id) != "" else _current_field_id
	var enemy_ids := _expanded_single_enemy_group(StringName(enemy_id))
	_battle_payload = {
		"enemy_id": enemy_id,
		"enemy_ids": enemy_ids,
		"return_scene": resolved_return_scene,
		"battle_arena": _battle_arena_for_scene(resolved_return_scene),
	}
	if not victory_action.is_empty():
		_battle_payload["victory_action"] = victory_action
	var resolved_spawn: Variant = return_spawn if return_spawn is Vector2 else _current_field_spawn
	if resolved_spawn is Vector2:
		_battle_payload["return_spawn"] = resolved_spawn
	_transition_to(SCENE_BATTLE, &"battle_enter", {"title": "风起之前"})


func _expanded_single_enemy_group(enemy_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = [enemy_id]
	var desired_count := mini(3, maxi(1, GameState.party.size()))
	if desired_count <= 1:
		return result
	var path := "%s%s.tres" % [ENEMY_DIR, String(enemy_id)]
	if not ResourceLoader.exists(path):
		return result
	var enemy_def := load(path) as EnemyDef
	if enemy_def == null or enemy_def.party_reinforcement_ids.is_empty():
		return result
	var index := 0
	while result.size() < desired_count:
		result.append(enemy_def.party_reinforcement_ids[index % enemy_def.party_reinforcement_ids.size()])
		index += 1
	return result


func start_sparring(
	spar_id: StringName,
	opponent_name: String,
	enemy_id: String,
	win_training: int,
	loss_training: int,
	return_scene_id: StringName = &"",
	return_spawn: Variant = null,
	victory_action: String = ""
) -> void:
	var resolved_return_scene: StringName = return_scene_id if String(return_scene_id) != "" else _current_field_id
	var spar_snapshot: Array[Dictionary] = []
	for member: CharacterStats in GameState.party:
		if member != null:
			spar_snapshot.append({"character_id": member.character_id, "hp": member.hp, "mp": member.mp})
	_battle_payload = {
		"enemy_id": enemy_id,
		"battle_mode": &"sparring",
		"spar_id": spar_id,
		"spar_opponent_name": opponent_name,
		"spar_win_training": maxi(0, win_training),
		"spar_loss_training": maxi(0, loss_training),
		"spar_party_snapshot": spar_snapshot,
		"solo_player": true,
		"return_scene": resolved_return_scene,
		"battle_arena": _battle_arena_for_scene(resolved_return_scene),
	}
	if not victory_action.is_empty():
		_battle_payload["victory_action"] = victory_action
	var resolved_spawn: Variant = return_spawn if return_spawn is Vector2 else _current_field_spawn
	if resolved_spawn is Vector2:
		_battle_payload["return_spawn"] = resolved_spawn
	_transition_to(SCENE_BATTLE, &"battle_enter", {"title": "以武会友"})


func start_solo_battle(
	enemy_id: String,
	return_scene_id: StringName = &"",
	return_spawn: Variant = null,
	victory_action: String = ""
) -> void:
	## Formal trials and authored duels deliberately exclude companions. They
	## still use normal victory, drops and story continuation rather than the
	## non-lethal sparring settlement path.
	var resolved_return_scene: StringName = return_scene_id if String(return_scene_id) != "" else _current_field_id
	_battle_payload = {
		"enemy_id": enemy_id,
		"enemy_ids": [StringName(enemy_id)],
		"solo_player": true,
		"return_scene": resolved_return_scene,
		"battle_arena": _battle_arena_for_scene(resolved_return_scene),
	}
	if not victory_action.is_empty():
		_battle_payload["victory_action"] = victory_action
	var resolved_spawn: Variant = return_spawn if return_spawn is Vector2 else _current_field_spawn
	if resolved_spawn is Vector2:
		_battle_payload["return_spawn"] = resolved_spawn
	_transition_to(SCENE_BATTLE, &"battle_enter", {"title": "独自应试"})


func start_encounter(
	enemy_ids: Array[StringName],
	return_scene_id: StringName = &"",
	return_spawn: Variant = null,
	victory_action: String = ""
) -> void:
	## New team-battle entry point. Existing start_battle callers remain valid.
	var resolved_return_scene: StringName = return_scene_id if String(return_scene_id) != "" else _current_field_id
	var scene_def := _load_field_scene_def(resolved_return_scene)
	var allow_full_group := scene_def != null and scene_def.encounter_allow_full_group_for_solo
	var resolved_enemy_ids := _adapt_authored_group_to_party(enemy_ids, allow_full_group)
	_battle_payload = {
		"enemy_id": String(resolved_enemy_ids[0]) if not resolved_enemy_ids.is_empty() else "thug_lone",
		"enemy_ids": resolved_enemy_ids,
		"return_scene": resolved_return_scene,
		"battle_arena": _battle_arena_for_scene(resolved_return_scene),
	}
	if not victory_action.is_empty():
		_battle_payload["victory_action"] = victory_action
	var resolved_spawn: Variant = return_spawn if return_spawn is Vector2 else _current_field_spawn
	if resolved_spawn is Vector2:
		_battle_payload["return_spawn"] = resolved_spawn
	_transition_to(SCENE_BATTLE, &"battle_enter", {"title": "敌影渐近"})


func _adapt_authored_group_to_party(enemy_ids: Array[StringName], allow_full_group_for_solo: bool = false) -> Array[StringName]:
	## Authored groups keep at least two enemies so group combat remains visible,
	## while early regions protect a deliberately solo player from a fixed 1v3.
	## High-risk scenes can explicitly retain their authored three-unit formation.
	var result := enemy_ids.duplicate()
	if allow_full_group_for_solo:
		return result
	var max_enemy_count := clampi(GameState.party.size() + 1, 2, 3)
	if result.size() > max_enemy_count:
		result.resize(max_enemy_count)
	return result


func start_encounter_csv(
	enemy_csv: String,
	return_scene_id: StringName = &"",
	return_spawn: Variant = null,
	victory_action: String = ""
) -> void:
	var enemy_ids: Array[StringName] = []
	for raw_id in enemy_csv.split(",", false):
		var enemy_id := StringName(raw_id.strip_edges())
		if String(enemy_id) != "":
			enemy_ids.append(enemy_id)
	if enemy_ids.is_empty():
		push_warning("[SceneRouter] empty battle group: %s" % enemy_csv)
		return
	start_encounter(enemy_ids, return_scene_id, return_spawn, victory_action)


func start_bounty_encounter(bounty_id: StringName, enemy_ids: Array[StringName]) -> void:
	if enemy_ids.is_empty():
		return
	var scene_def := _load_field_scene_def(_current_field_id)
	var allow_full_group := scene_def != null and scene_def.encounter_allow_full_group_for_solo
	var resolved_enemy_ids := _adapt_authored_group_to_party(enemy_ids, allow_full_group)
	_battle_payload = {
		"enemy_id": String(resolved_enemy_ids[0]),
		"enemy_ids": resolved_enemy_ids,
		"return_scene": _current_field_id,
		"return_spawn": _current_field_spawn,
		"battle_arena": _battle_arena_for_scene(_current_field_id),
		"bounty_id": bounty_id,
		"battle_mode": &"bounty",
	}
	_transition_to(SCENE_BATTLE, &"battle_enter", {"title": "缉凶交锋"})


func start_party_encounter(player_party: Array[Dictionary], enemy_ids: Array[StringName], return_scene_id: StringName = &"", return_spawn: Variant = null) -> void:
	## Full party entry point. Each party dictionary may provide unit_id,
	## display_name, actor_path, hp/max_hp, mp/max_mp, attack/defense/speed.
	var resolved_return_scene: StringName = return_scene_id if String(return_scene_id) != "" else _current_field_id
	_battle_payload = {
		"enemy_id": String(enemy_ids[0]) if not enemy_ids.is_empty() else "thug_lone",
		"enemy_ids": enemy_ids.duplicate(),
		"player_party": player_party.duplicate(true),
		"return_scene": resolved_return_scene,
		"battle_arena": _battle_arena_for_scene(resolved_return_scene),
	}
	var resolved_spawn: Variant = return_spawn if return_spawn is Vector2 else _current_field_spawn
	if resolved_spawn is Vector2:
		_battle_payload["return_spawn"] = resolved_spawn
	_transition_to(SCENE_BATTLE, &"battle_enter", {"title": "列阵迎敌"})


func _battle_arena_for_scene(scene_id: StringName) -> StringName:
	match OUTSKIRTS.biome_for(scene_id):
		"bamboo": return &"bamboo_platforms"
		"forest": return &"outskirts_road"
		"marsh": return &"river_skirmish"
	var id := String(scene_id).to_lower()
	if "rear_sanctum" in id:
		return &"mingwu_sanctum"
	if "snow" in id or "ice" in id:
		return &"snow_peak"
	if "cave" in id or "mine" in id or "tunnel" in id or "tomb" in id or "archive" in id or "gallery" in id:
		return &"cave_depths"
	if "relief" in id or "convoy" in id or "grain" in id or "grass" in id or "staging_ground" in id:
		return &"grassland"
	if "river" in id or "canal" in id or "dock" in id:
		return &"river_skirmish"
	if "luoyang" in id or "yamen" in id or "city" in id:
		return &"city_street"
	if "lingyue" in id or "wudang" in id or "huashan" in id or "gufeng" in id or "mingwu" in id or "sect" in id or "trial" in id or "faction" in id or "assembly" in id or "ceremonial" in id or "manor" in id or "main_hall" in id:
		return &"sect_courtyard"
	if "village" in id or "zhuwei" in id or "linxi" in id or "market" in id or "inn" in id or "martial_hall" in id:
		return &"village_square"
	return &"outskirts_road"


func get_battle_payload() -> Dictionary:
	return _battle_payload


func return_from_battle_payload(payload: Dictionary, pending_action: String = "") -> void:
	var target := StringName(payload.get("return_scene", START_FIELD_SCENE))
	go_field_smart(target, payload.get("return_spawn", null), pending_action, int(payload.get("return_world_map_version", _world_map_version)))


func go_victory(reward_gold: int = 0, reward_exp: int = 0, party_exp_results: Array[Dictionary] = []) -> void:
	var bounty_result: Dictionary = {}
	var bounty_id := StringName(_battle_payload.get("bounty_id", &""))
	if String(bounty_id) != "":
		bounty_result = BountyManager.resolve_victory(bounty_id)
	_clear_transient_ui()
	_result_payload = {
		"gold": reward_gold,
		"exp": reward_exp,
		"party_exp_results": party_exp_results.duplicate(true),
		"return_scene": _battle_payload.get("return_scene", &""),
		"return_spawn": _battle_payload.get("return_spawn", null),
		"return_world_map_version": _battle_payload.get("return_world_map_version", _world_map_version),
		"victory_action": _battle_payload.get("victory_action", ""),
		"battle_mode": _battle_payload.get("battle_mode", &""),
		"bounty_result": bounty_result,
	}
	# 战斗画面直接切到结算，避免“最后一击 → Loading → 奖励”打断反馈。
	# 玩家关闭奖励界面后，result_victory.gd 会通过 go_field_smart() 再展示
	# 正式的场景 Loading，时序为“战斗 → 奖励 → Loading → 场景”。
	_change_scene_immediate(SCENE_VICTORY)


func go_defeat() -> void:
	var bounty_escape: Dictionary = {}
	var bounty_id := StringName(_battle_payload.get("bounty_id", &""))
	if String(bounty_id) != "":
		bounty_escape = BountyManager.record_defeat(bounty_id)
	_clear_transient_ui()
	_result_payload = {
		"return_scene": _battle_payload.get("return_scene", &""),
		"return_spawn": _battle_payload.get("return_spawn", null),
		"return_world_map_version": _battle_payload.get("return_world_map_version", _world_map_version),
		"battle_mode": _battle_payload.get("battle_mode", &""),
		"bounty_escape": bounty_escape,
	}
	_change_scene_immediate(SCENE_DEFEAT)


func settle_sparring(victory: bool) -> void:
	var spar_id := StringName(_battle_payload.get("spar_id", &""))
	var outcome := GameState.resolve_sparring_result(
		spar_id,
		victory,
		int(_battle_payload.get("spar_win_training", 0)),
		int(_battle_payload.get("spar_loss_training", 0))
	)
	var raw_snapshot: Variant = _battle_payload.get("spar_party_snapshot", [])
	GameState.restore_party_after_sparring(raw_snapshot if raw_snapshot is Array else [])
	_result_payload = {
		"battle_mode": &"sparring",
		"victory": victory,
		"opponent_name": String(_battle_payload.get("spar_opponent_name", "江湖同道")),
		"training": int(outcome.get("reward", 0)),
		"first_victory": bool(outcome.get("first_victory", false)),
		"first_loss": bool(outcome.get("first_loss", false)),
		"return_scene": _battle_payload.get("return_scene", &""),
		"return_spawn": _battle_payload.get("return_spawn", null),
		"return_world_map_version": _battle_payload.get("return_world_map_version", _world_map_version),
	}
	if victory:
		_result_payload["victory_action"] = _battle_payload.get("victory_action", "")
	_clear_transient_ui()
	_change_scene_immediate(SCENE_VICTORY if victory else SCENE_DEFEAT)


func get_result_payload() -> Dictionary:
	return _result_payload


func _clear_transient_ui() -> void:
	for transient: Node in get_tree().get_nodes_in_group("transient_ui"):
		if not is_instance_valid(transient):
			continue
		if transient is CanvasItem:
			(transient as CanvasItem).visible = false
		transient.queue_free()


func go_field(scene_id: StringName) -> void:
	if not OUTSKIRTS.biome_for(scene_id).is_empty():
		go_field_smart(scene_id)
		return
	if not ContentPackManager.ensure_scene_pack(scene_id, func(ok: bool) -> void:
		if ok:
			go_field(scene_id)
	):
		return
	AudioManager.stop_dialog_audio()
	_current_field_spawn = null
	_field_payload = {"scene_id": scene_id}
	_current_field_id = scene_id
	_transition_to(SCENE_FIELD, &"field", {"title": "行至下一处"})


func go_field_smart(scene_id: StringName, player_spawn: Variant = null, pending_action: String = "", spawn_version: int = -1) -> void:
	if not OUTSKIRTS.biome_for(scene_id).is_empty():
		var local_scene := _load_field_scene_def(scene_id)
		if local_scene == null:
			push_warning("[SceneRouter] 新郊外尚未完成审查或资源缺失，暂不进入。")
			return
		var requested: Vector2 = player_spawn if player_spawn is Vector2 else (_current_field_spawn if scene_id == _current_field_id and _current_field_spawn is Vector2 else local_scene.player_spawn)
		var resolved: Variant = OUTSKIRTS.repair_spawn(local_scene, requested)
		if not resolved is Vector2:
			push_warning("[SceneRouter] 新郊外没有安全落点，保留当前场景。")
			return
		player_spawn = resolved
	if not ContentPackManager.ensure_scene_pack(scene_id, func(ok: bool) -> void:
		if ok:
			go_field_smart(scene_id, player_spawn, pending_action, spawn_version)
	):
		return
	AudioManager.stop_dialog_audio()
	scene_id = _normalize_field_id(scene_id)
	if is_world_map_scene(scene_id):
		_active_world_map_scene = scene_id
	var target_scene := get_field_scene_path(scene_id)
	if target_scene == SCENE_FIELD_WALKABLE:
		var spawn := _scene_default_spawn(scene_id)
		if player_spawn is Vector2:
			spawn = player_spawn
		elif scene_id == _current_field_id and _current_field_spawn is Vector2:
			# Loading a save or rebuilding the same field must preserve the saved
			# position. Cross-scene transitions still use their authored arrival.
			spawn = _current_field_spawn
		var world_contract: Variant = layered_world_contract(_load_field_scene_def(scene_id)) if is_world_map_scene(scene_id) else null
		if world_contract != null:
			var source_version := spawn_version if spawn_version >= 0 else _world_map_version
			if not player_spawn is Vector2 and scene_id != _current_field_id:
				source_version = world_contract.VERSION
			var repaired: Variant = world_contract.migrate_spawn(spawn, source_version, _load_field_scene_def(scene_id))
			if not repaired is Vector2:
				push_error("[SceneRouter] layered world has no safe arrival; transition refused")
				return
			spawn = repaired
			_world_map_version = world_contract.VERSION
		elif scene_id == WORLD_MAP_STAGING_SCENE:
			_world_map_version = 13
		_current_field_spawn = spawn
		_field_payload = {"scene_id": scene_id, "player_spawn": spawn}
	else:
		_current_field_spawn = null
		_field_payload = {"scene_id": scene_id}
	if not pending_action.is_empty():
		_field_payload["pending_action"] = pending_action
	_current_field_id = scene_id
	_transition_to(target_scene, &"field", {"title": _loading_title_for_field(scene_id)})


func go_field_from_portal(
	scene_id: StringName,
	authored_target_spawn: Variant = null,
	source_player_spawn: Variant = null,
	pending_action: String = ""
) -> void:
	## Portal travel is paired at runtime. Entering a room remembers the exact
	## walkable point used outside; taking the reverse portal returns to it.
	## This also covers houses whose map art or doorway moved after target_pos
	## was authored, which previously caused an unrelated default spawn fallback.
	var source_scene_id := _current_field_id
	if scene_id == WORLD_MAP_SCENE and _active_world_map_scene != WORLD_MAP_SCENE:
		scene_id = _active_world_map_scene
	if is_world_map_scene(scene_id):
		_world_map_return_scene = source_scene_id
	var source_spawn: Variant = source_player_spawn if source_player_spawn is Vector2 else _current_field_spawn
	var arrival := resolve_portal_arrival(source_scene_id, scene_id, source_spawn, authored_target_spawn)
	go_field_smart(scene_id, arrival, pending_action)


func resolve_portal_arrival(
	source_scene_id: StringName,
	target_scene_id: StringName,
	source_player_spawn: Variant,
	authored_target_spawn: Variant
) -> Vector2:
	## Public so portal contracts can be regression-tested without changing the
	## active PackedScene.
	source_scene_id = _normalize_field_id(source_scene_id)
	target_scene_id = _normalize_field_id(target_scene_id)
	var arrival := _scene_default_spawn(target_scene_id)
	if authored_target_spawn is Vector2:
		arrival = authored_target_spawn

	var route_key := _portal_route_key(source_scene_id, target_scene_id)
	var remembered: Variant = _portal_return_spawns.get(route_key, null)
	if remembered is Vector2:
		arrival = remembered
	# World gateways move when the illustrated road survey changes. Always use
	# the live regional gateway, even when an old saved point is still walkable.
	# Interior A/B returns keep their precise per-door remembered coordinates.
	if is_world_map_scene(target_scene_id):
		var gateway: Variant = get_world_map_position_for_scene(source_scene_id, target_scene_id)
		if gateway is Vector2:
			arrival = gateway
			# This gateway is already authored in the destination map's space.
			_world_map_version = world_version_for_scene(target_scene_id)

	if String(source_scene_id) != "" and source_scene_id != target_scene_id and source_player_spawn is Vector2:
		var safe_source := source_player_spawn as Vector2
		safe_source.x = clampf(safe_source.x, 0.0, 1.0)
		safe_source.y = clampf(safe_source.y, 0.0, 1.0)
		_portal_return_spawns[_portal_route_key(target_scene_id, source_scene_id)] = safe_source
	return arrival


func go_field_walkable(scene_id: StringName, player_spawn: Vector2 = Vector2(0.5, 0.8)) -> void:
	if not OUTSKIRTS.biome_for(scene_id).is_empty():
		go_field_smart(scene_id, player_spawn)
		return
	if not ContentPackManager.ensure_scene_pack(scene_id, func(ok: bool) -> void:
		if ok:
			go_field_walkable(scene_id, player_spawn)
	):
		return
	AudioManager.stop_dialog_audio()
	scene_id = _normalize_field_id(scene_id)
	if is_world_map_scene(scene_id):
		go_field_smart(scene_id, player_spawn)
		return
	if not ResourceLoader.exists(SCENE_FIELD_WALKABLE):
		push_warning("[SceneRouter] walkable field scene not found, falling back to classic")
		go_field(scene_id)
		return
	_current_field_spawn = player_spawn
	_field_payload = {"scene_id": scene_id, "player_spawn": player_spawn}
	_current_field_id = scene_id
	_transition_to(SCENE_FIELD_WALKABLE, &"field", {"title": _loading_title_for_field(scene_id)})


func go_world_map(player_spawn: Variant = null) -> void:
	var target_map := _active_world_map_scene
	if _current_field_id != target_map:
		_world_map_return_scene = _current_field_id
		if _current_field_spawn is Vector2 and not String(_current_field_id).is_empty():
			_portal_return_spawns[_portal_route_key(target_map, _current_field_id)] = _current_field_spawn
	if player_spawn is Vector2:
		var arrival: Variant = player_spawn
		if target_map in [WORLD_MAP_STAGING_SCENE, WORLD_MAP_V14_SCENE, WORLD_MAP_V15_SCENE] or WORLD_V15.formal_version() in [14, 15]:
			arrival = get_world_map_position_for_scene(_current_field_id, target_map)
			_world_map_version = world_version_for_scene(target_map)
		go_field_smart(target_map, arrival if arrival is Vector2 else null)
	else:
		var authored_spawn: Variant = get_world_map_position_for_scene(_current_field_id, target_map)
		_world_map_version = world_version_for_scene(target_map)
		go_field_smart(target_map, authored_spawn if authored_spawn is Vector2 else null)


func return_from_world_map() -> void:
	var target := _world_map_return_scene
	if String(target) == "" or is_world_map_scene(target):
		target = START_FIELD_SCENE
	var arrival := resolve_portal_arrival(_current_field_id, target, _current_field_spawn, null)
	go_field_smart(target, arrival)


func get_field_payload() -> Dictionary:
	return _field_payload


func take_pending_field_action() -> String:
	var action: String = String(_field_payload.get("pending_action", ""))
	_field_payload.erase("pending_action")
	return action


func get_current_field_id() -> StringName:
	return _current_field_id


func get_current_field_spawn() -> Variant:
	return _current_field_spawn


func get_active_world_map_scene() -> StringName:
	return _active_world_map_scene


func get_world_map_position_for_scene(scene_id: StringName, world_scene_id: StringName = WORLD_MAP_SCENE) -> Variant:
	if scene_id == world_scene_id and _current_field_spawn is Vector2:
		return _current_field_spawn
	var portal_id: StringName = WORLD_MAP_REGION_PORTALS.get(scene_id, &"")
	var world_scene := _load_field_scene_def(world_scene_id)
	if world_scene == null or world_scene.map_layout == null:
		return null
	for raw_portal: Variant in world_scene.map_layout.portals:
		if not raw_portal is Dictionary:
			continue
		var portal: Dictionary = raw_portal
		if bool(portal.get("staging_pending_asset", false)):
			continue
		if String(portal_id) != "" and String(portal.get("id", "")) == String(portal_id):
			return portal.get("pos", null)
		if String(portal_id) == "" and String(portal.get("target_scene", "")) == String(scene_id):
			return portal.get("pos", null)
	return null


func resume_current_field(pending_action: String = "") -> void:
	## Only explicit returns from a modal scene reuse the last field position.
	## Normal scene transitions must use the destination's authored spawn point.
	var scene_id := _current_field_id
	if String(scene_id) == "":
		scene_id = START_FIELD_SCENE
	go_field_smart(scene_id, _current_field_spawn, pending_action)


func set_field_return_spawn(spawn: Vector2) -> void:
	## Field scenes update this as the player moves. Dialog-driven battles then
	## return to the actual conversation location instead of the map entrance.
	_current_field_spawn = spawn
	if _field_payload.get("scene_id", &"") == _current_field_id:
		_field_payload["player_spawn"] = spawn


func reset_for_new_game() -> void:
	_battle_payload.clear()
	_field_payload.clear()
	_shop_payload.clear()
	_bounty_board_payload.clear()
	_result_payload.clear()
	_current_field_id = &""
	_current_field_spawn = null
	_world_map_return_scene = &""
	_active_world_map_scene = WORLD_MAP_SCENE
	_world_map_version = WORLD_V15.formal_version()
	_portal_return_spawns.clear()


func get_navigation_state() -> Dictionary:
	var packed_returns: Dictionary = {}
	for raw_key: Variant in _portal_return_spawns:
		var raw_spawn: Variant = _portal_return_spawns[raw_key]
		if raw_spawn is Vector2:
			packed_returns[String(raw_key)] = _pack_spawn(raw_spawn)
	var state := {
		"current_field": String(_current_field_id),
		"portal_return_spawns": packed_returns,
		"world_map_version": _world_map_version,
	}
	if _current_field_spawn is Vector2:
		state["current_field_spawn"] = _pack_spawn(_current_field_spawn)
	if String(_world_map_return_scene) != "":
		state["world_map_return_scene"] = String(_world_map_return_scene)
	return state


func restore_navigation_state(
	data: Dictionary,
	fallback_field: StringName = &"",
	world_map_upgrade_target: StringName = &""
) -> void:
	var selected_world := world_map_upgrade_target if world_map_upgrade_target != &"" else WORLD_MAP_SCENE
	if not navigation_coordinate_version_supported(data, selected_world): return
	if world_map_upgrade_target == WORLD_MAP_V15_SCENE or (world_map_upgrade_target == &"" and WORLD_V15.formal_version() == 15):
		_restore_v15_navigation(data, fallback_field, WORLD_MAP_V15_SCENE if world_map_upgrade_target == WORLD_MAP_V15_SCENE else WORLD_MAP_SCENE)
		return
	if world_map_upgrade_target == WORLD_MAP_V14_SCENE or (world_map_upgrade_target == &"" and WORLD_V14.formal_version() == 14):
		_restore_v14_navigation(data, fallback_field, WORLD_MAP_V14_SCENE if world_map_upgrade_target == WORLD_MAP_V14_SCENE else WORLD_MAP_SCENE)
		return
	# The third argument is an explicit cutover switch. Existing v12 saves and
	# ordinary loads keep their original map/scope until the full v13 map ships.
	var upgrade_world := world_map_upgrade_target == WORLD_MAP_STAGING_SCENE
	_active_world_map_scene = WORLD_MAP_STAGING_SCENE if upgrade_world else WORLD_MAP_SCENE
	var saved_field := _normalize_field_id(StringName(data.get("current_field", fallback_field)))
	_world_map_version = 13 if upgrade_world or saved_field == WORLD_MAP_STAGING_SCENE else int(data.get("world_map_version", 12))
	_current_field_id = WORLD_MAP_STAGING_SCENE if upgrade_world and saved_field == WORLD_MAP_SCENE else saved_field
	_current_field_spawn = _unpack_spawn(data.get("current_field_spawn", null))
	if upgrade_world and saved_field == WORLD_MAP_SCENE and _current_field_spawn is Vector2:
		_current_field_spawn = _migrate_v12_world_spawn_to_staging(_current_field_spawn)
	_world_map_return_scene = StringName(data.get("world_map_return_scene", ""))
	_portal_return_spawns.clear()
	var packed_returns: Variant = data.get("portal_return_spawns", {})
	if not packed_returns is Dictionary:
		return
	for raw_key: Variant in packed_returns:
		if _portal_return_spawns.size() >= 64:
			break
		var spawn: Variant = _unpack_spawn(packed_returns[raw_key])
		if not spawn is Vector2:
			continue
		var route_key := String(raw_key)
		if upgrade_world:
			var parts := route_key.split("->")
			if parts.size() == 2:
				if parts[1] == String(WORLD_MAP_SCENE):
					# The value is a v12 world-side foot position. Replace it with
					# the matching v13 gateway, never a similarly-normalized water tile.
					spawn = _migrate_v12_world_spawn_to_staging(spawn)
					parts[1] = String(WORLD_MAP_STAGING_SCENE)
				elif parts[0] == String(WORLD_MAP_SCENE):
					# This value is on the destination scene side; only the key moves.
					parts[0] = String(WORLD_MAP_STAGING_SCENE)
				route_key = "->".join(parts)
		_portal_return_spawns[route_key] = spawn


func _migrate_v12_world_spawn_to_staging(old_spawn: Vector2) -> Vector2:
	var legacy_world := WORLD_V14.source_scene(12)
	if legacy_world == null:
		legacy_world = _load_field_scene_def(WORLD_MAP_SCENE)
	var staging_world := _load_field_scene_def(WORLD_MAP_STAGING_SCENE)
	if legacy_world == null or staging_world == null:
		return _scene_default_spawn(WORLD_MAP_STAGING_SCENE)
	if legacy_world.map_layout == null or staging_world.map_layout == null:
		return _scene_default_spawn(WORLD_MAP_STAGING_SCENE)
	var closest_id := ""
	var closest_distance := INF
	for raw_portal: Variant in legacy_world.map_layout.portals:
		if not raw_portal is Dictionary:
			continue
		var portal: Dictionary = raw_portal
		var portal_pos: Vector2 = portal.get("pos", Vector2.ZERO)
		var distance := old_spawn.distance_squared_to(portal_pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_id = String(portal.get("id", ""))
	for raw_portal: Variant in staging_world.map_layout.portals:
		if not raw_portal is Dictionary:
			continue
		var portal: Dictionary = raw_portal
		if String(portal.get("id", "")) == closest_id:
			return portal.get("pos", _scene_default_spawn(WORLD_MAP_STAGING_SCENE))
	return _scene_default_spawn(WORLD_MAP_STAGING_SCENE)


func is_world_map_scene(scene_id: StringName) -> bool:
	return scene_id in [WORLD_MAP_SCENE, WORLD_MAP_STAGING_SCENE, WORLD_MAP_V14_SCENE, WORLD_MAP_V15_SCENE]


func world_version_for_scene(scene_id: StringName) -> int:
	if scene_id == WORLD_MAP_V15_SCENE: return 15
	if scene_id == WORLD_MAP_V14_SCENE: return 14
	if scene_id == WORLD_MAP_STAGING_SCENE: return 13
	return WORLD_V15.formal_version()


func layered_world_contract(scene: SceneScript) -> Variant:
	if WORLD_V15.is_v15(scene): return WORLD_V15
	if WORLD_V14.is_v14(scene): return WORLD_V14
	return null


func navigation_coordinate_version_supported(data: Dictionary, target_id: StringName) -> bool:
	var local_id := StringName(data.get("current_field", ""))
	if not OUTSKIRTS.biome_for(local_id).is_empty():
		var local_scene := _load_field_scene_def(local_id)
		var saved_spawn: Variant = data.get("current_field_spawn", null)
		var local_spawn: Variant = OUTSKIRTS._v(saved_spawn) if saved_spawn != null else (local_scene.player_spawn if local_scene != null else null)
		if local_scene == null or not local_spawn is Vector2 or not local_spawn.is_finite() or local_spawn.x < 0 or local_spawn.y < 0 or local_spawn.x > 1 or local_spawn.y > 1 or not OUTSKIRTS.repair_spawn(local_scene, local_spawn) is Vector2:
			push_warning("[SceneRouter] 存档郊外资源尚未就绪，保留当前状态。")
			return false
	var saved_id := StringName(data.get("current_field", ""))
	var source_version := int(data.get("world_map_version", 15 if saved_id == WORLD_MAP_V15_SCENE else 12))
	if source_version == 15 and world_version_for_scene(target_id) < 15:
		push_warning("[SceneRouter] 此存档使用新版大地图v15，当前地图较旧；为防止落点错乱，暂不支持降级读取。请恢复v15地图后重试。")
		return false
	return true


func _restore_v15_navigation(data: Dictionary, fallback: StringName, target_id: StringName) -> void:
	var prepared := prepare_v15_navigation(data, fallback, target_id)
	if not prepared.is_empty(): commit_v15_navigation(prepared)


func prepare_v15_navigation(data: Dictionary, fallback: StringName, target_id: StringName) -> Dictionary:
	# Pure resolution: SaveManager calls this before applying ANY save data.
	# A failure may populate diagnostic caches, but cannot change Router state.
	var target := _load_field_scene_def(target_id)
	if not WORLD_V15.is_v15(target):
		push_error("[SceneRouter] v15 upgrade requested before candidate publication")
		return {}
	var saved_id := _normalize_field_id(StringName(data.get("current_field", fallback)))
	var inferred_version := 15 if saved_id == WORLD_MAP_V15_SCENE else (14 if saved_id == WORLD_MAP_V14_SCENE else (13 if saved_id == WORLD_MAP_STAGING_SCENE else 12))
	var old_version := int(data.get("world_map_version", inferred_version))
	if WORLD_V15.source_scene(old_version) == null:
		push_error("[SceneRouter] unknown/unavailable source coordinate version; v15 restore refused")
		return {}
	var spawn: Variant = _unpack_spawn(data.get("current_field_spawn", null))
	if is_world_map_scene(saved_id):
		spawn = WORLD_V15.migrate_spawn(spawn if spawn is Vector2 else target.player_spawn, old_version if spawn is Vector2 else 15, target)
		if not spawn is Vector2:
			push_error("[SceneRouter] no safe v15 restored arrival; navigation unchanged")
			return {}
	var repaired_returns: Dictionary = {}
	var returns: Variant = data.get("portal_return_spawns", {})
	if returns is Dictionary:
		for raw_key: Variant in returns:
			if repaired_returns.size() >= 64: break
			var parts := String(raw_key).split("->")
			var point: Variant = _unpack_spawn(returns[raw_key])
			if parts.size() != 2 or not point is Vector2: continue
			if is_world_map_scene(StringName(parts[1])):
				point = WORLD_V15.migrate_spawn(point, old_version, target)
				if not point is Vector2:
					push_error("[SceneRouter] no safe v15 remembered world arrival; navigation unchanged")
					return {}
				parts[1] = String(target_id)
			if is_world_map_scene(StringName(parts[0])): parts[0] = String(target_id)
			repaired_returns["->".join(parts)] = point
	return {"active_world_map_scene": target_id, "current_field_id": target_id if is_world_map_scene(saved_id) else saved_id, "current_field_spawn": spawn, "world_map_return_scene": StringName(data.get("world_map_return_scene", "")), "portal_return_spawns": repaired_returns, "world_map_version": 15}


func commit_v15_navigation(prepared: Dictionary) -> void:
	# Only the result of the matching pure preflight enters this commit path.
	if prepared.get("world_map_version") != 15 or not prepared.get("active_world_map_scene") in [WORLD_MAP_SCENE, WORLD_MAP_V15_SCENE]:
		push_error("[SceneRouter] malformed prepared v15 navigation")
		return
	_active_world_map_scene = prepared.active_world_map_scene
	_current_field_id = prepared.current_field_id
	_current_field_spawn = prepared.current_field_spawn
	_world_map_return_scene = prepared.world_map_return_scene
	_portal_return_spawns = prepared.portal_return_spawns
	_world_map_version = 15


func _restore_v14_navigation(data: Dictionary, fallback: StringName, target_id: StringName) -> void:
	var target := _load_field_scene_def(target_id)
	if not WORLD_V14.is_v14(target):
		push_error("[SceneRouter] v14 upgrade requested before production publication")
		return
	var saved_id := _normalize_field_id(StringName(data.get("current_field", fallback)))
	var inferred_version := 14 if saved_id == WORLD_MAP_V14_SCENE else (13 if saved_id == WORLD_MAP_STAGING_SCENE else 12)
	var old_version := int(data.get("world_map_version", inferred_version))
	_active_world_map_scene = target_id
	_current_field_id = target_id if is_world_map_scene(saved_id) else saved_id
	_current_field_spawn = _unpack_spawn(data.get("current_field_spawn", null))
	if is_world_map_scene(saved_id):
		_current_field_spawn = WORLD_V14.migrate_spawn(_current_field_spawn if _current_field_spawn is Vector2 else target.player_spawn, old_version if _current_field_spawn is Vector2 else 14, target)
	_world_map_return_scene = StringName(data.get("world_map_return_scene", ""))
	_portal_return_spawns.clear()
	var returns: Variant = data.get("portal_return_spawns", {})
	if returns is Dictionary:
		for raw_key: Variant in returns:
			if _portal_return_spawns.size() >= 64: break
			var parts := String(raw_key).split("->")
			var point: Variant = _unpack_spawn(returns[raw_key])
			if parts.size() != 2 or not point is Vector2: continue
			if is_world_map_scene(StringName(parts[1])):
				point = WORLD_V14.migrate_spawn(point, old_version, target)
				parts[1] = String(target_id)
			if is_world_map_scene(StringName(parts[0])):
				# Destination-side remembered positions are not world coordinates.
				parts[0] = String(target_id)
			if point is Vector2: _portal_return_spawns["->".join(parts)] = point
	_world_map_version = 14


func get_field_scene_path(scene_id: StringName) -> String:
	scene_id = _normalize_field_id(scene_id)
	var scene_def := _load_field_scene_def(scene_id)
	if scene_def != null and scene_def.is_walkable and ResourceLoader.exists(SCENE_FIELD_WALKABLE):
		return SCENE_FIELD_WALKABLE
	return SCENE_FIELD


func _normalize_field_id(scene_id: StringName) -> StringName:
	# This legacy alias was an AVG prototype. Keep old saves/dialogs compatible,
	# but always resolve it to the real free-roam village scene.
	if scene_id == &"ch1_s2_qingfeng_walkable":
		return &"ch1_s2_qingfeng"
	return scene_id


func go_shop(shop_id: StringName) -> void:
	_shop_payload = {"shop_id": shop_id}
	get_tree().change_scene_to_file(SCENE_SHOP)


func get_shop_payload() -> Dictionary:
	return _shop_payload


func go_bounty_board(city_id: StringName) -> void:
	_bounty_board_payload = {
		"city_id": city_id,
		"return_scene": _current_field_id,
		"return_spawn": _current_field_spawn,
	}
	get_tree().change_scene_to_file(SCENE_BOUNTY_BOARD)


func get_bounty_board_payload() -> Dictionary:
	return _bounty_board_payload


func go_chapter_end(chapter: int) -> void:
	GameState.set_flag(StringName("chapter%d_complete" % chapter), true)
	GameState.current_chapter = max(GameState.current_chapter, chapter + 1)
	EventBus.chapter_completed.emit(chapter)
	_result_payload = {"chapter": chapter}
	_transition_to(SCENE_CHAPTER_END, &"chapter", {"title": "第%s章落卷" % chapter})


func _transition_to(scene_path: String, kind: StringName, context: Dictionary = {}) -> void:
	if scene_path == SCENE_BATTLE:
		_battle_payload["return_world_map_version"] = _world_map_version
	var loading_manager := get_node_or_null("/root/LoadingManager")
	if loading_manager != null and loading_manager.has_method("transition_to"):
		loading_manager.call("transition_to", scene_path, kind, context)
		return
	get_tree().change_scene_to_file(scene_path)


func _change_scene_immediate(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


func _loading_title_for_field(scene_id: StringName) -> String:
	if scene_id == WORLD_MAP_SCENE:
		return "踏入江湖"
	var scene_path := FIELD_SCENE_DIR + String(scene_id) + ".tres"
	if ResourceLoader.exists(scene_path):
		var scene_def := load(scene_path)
		var display_name: Variant = scene_def.get("display_name") if scene_def != null else ""
		if not String(display_name).is_empty():
			return "前往%s" % String(display_name)
	return "行至下一处"


func get_chapter_entry(chapter: int) -> StringName:
	return CHAPTER_ENTRIES.get(chapter, &"")


func go_chapter(chapter: int) -> bool:
	var entry := get_chapter_entry(chapter)
	if String(entry) == "" or _load_field_scene_def(entry) == null:
		push_warning("[SceneRouter] chapter %d entry is unavailable: %s" % [chapter, entry])
		return false
	GameState.current_chapter = max(GameState.current_chapter, chapter)
	go_field_smart(entry)
	return true


func join_faction(faction_id: StringName) -> bool:
	if not GameState.select_faction(faction_id):
		push_warning("[SceneRouter] faction selection rejected: %s" % faction_id)
		EventBus.toast_requested.emit(GameState.last_faction_join_error)
		return false
	EventBus.flag_set.emit(&"player_faction", String(faction_id))
	EventBus.flag_set.emit(&"faction_application_submitted", true)
	EventBus.flag_set.emit(StringName("joined_%s" % faction_id), true)
	var entry_quest: StringName = FACTION_ENTRY_QUESTS.get(faction_id, &"")
	if String(entry_quest) != "":
		QuestManager.accept(entry_quest)
	go_field_smart(&"ch3_s2_trial_ground")
	return true


func quit_game() -> void:
	get_tree().quit()


# --- Action 字符串解析 ---

func resolve_action(action: String) -> void:
	if action == "" or action == "end":
		return

	var parts: PackedStringArray = action.split(":", true)
	var cmd: String = parts[0]

	match cmd:
		"dialog":
			_action_dialog(_arg(parts, 1))
		"field_cutscene":
			var cutscene_id := StringName(_arg(parts, 1))
			if String(cutscene_id) != "":
				EventBus.field_cutscene_requested.emit(cutscene_id)
		"battle":
			start_battle(_arg(parts, 1))
		"battle_solo":
			var enemy_id := _arg(parts, 1)
			if enemy_id != "":
				start_solo_battle(enemy_id)
		"spar":
			var spar_id := StringName(_arg(parts, 1))
			var enemy_id := _arg(parts, 2)
			var opponent_name := _arg(parts, 3, "江湖同道")
			if String(spar_id) != "" and enemy_id != "":
				start_sparring(spar_id, opponent_name, enemy_id, int(_arg(parts, 4, "20")), int(_arg(parts, 5, "5")))
		"spar_then":
			var spar_id := StringName(_arg(parts, 1))
			var enemy_id := _arg(parts, 2)
			var opponent_name := _arg(parts, 3, "江湖同道")
			var dialog_id := _arg(parts, 6)
			if String(spar_id) != "" and enemy_id != "":
				var victory_action := "dialog:%s" % dialog_id if dialog_id != "" else ""
				start_sparring(
					spar_id,
					opponent_name,
					enemy_id,
					int(_arg(parts, 4, "20")),
					int(_arg(parts, 5, "5")),
					&"",
					null,
					victory_action
				)
		"battle_then":
			var enemy_id := _arg(parts, 1)
			var dialog_id := _arg(parts, 2)
			if enemy_id != "":
				var victory_action := "dialog:%s" % dialog_id if dialog_id != "" else ""
				start_battle(enemy_id, &"", null, victory_action)
		"battle_solo_then":
			var enemy_id := _arg(parts, 1)
			var dialog_id := _arg(parts, 2)
			if enemy_id != "":
				var victory_action := "dialog:%s" % dialog_id if dialog_id != "" else ""
				start_solo_battle(enemy_id, &"", null, victory_action)
		"battle_group":
			start_encounter_csv(_arg(parts, 1))
		"battle_group_then":
			var enemy_csv := _arg(parts, 1)
			var dialog_id := _arg(parts, 2)
			if enemy_csv != "":
				var victory_action := "dialog:%s" % dialog_id if dialog_id != "" else ""
				start_encounter_csv(enemy_csv, &"", null, victory_action)
		"scene":
			var scene_id := _arg(parts, 1)
			if scene_id != "":
				go_field_smart(StringName(scene_id))
		"world_map":
			go_world_map()
		"world_map_return":
			return_from_world_map()
		"shop":
			var sid := _arg(parts, 1)
			if sid != "":
				go_shop(StringName(sid))
		"bounty_board":
			var city_id := StringName(_arg(parts, 1))
			if String(city_id) != "":
				go_bounty_board(city_id)
		"bounty_battle":
			BountyManager.start_bounty(StringName(_arg(parts, 1)))
		"give_item":
			var iid := _arg(parts, 1)
			var n: int = int(_arg(parts, 2, "1"))
			if iid != "":
				Inventory.add_item(StringName(iid), n)
		"read_item":
			var readable_id := StringName(_arg(parts, 1))
			if String(readable_id) != "" and Inventory.has_item(readable_id, 1):
				EventBus.ui_requested.emit(&"inventory")
				EventBus.item_read_requested.emit(readable_id)
		"discover_readable":
			var readable_id := StringName(_arg(parts, 1))
			var discovery_flag := StringName(_arg(parts, 2))
			if String(readable_id) != "":
				if not Inventory.has_item(readable_id, 1):
					Inventory.add_item(readable_id, 1)
				if String(discovery_flag) != "":
					GameState.set_flag(discovery_flag, true)
				EventBus.ui_requested.emit(&"inventory")
				EventBus.item_read_requested.emit(readable_id)
		"give_gold":
			GameState.add_gold(int(_arg(parts, 1, "0")))
		"set_flag":
			var k := _arg(parts, 1)
			var v_str := _arg(parts, 2, "true")
			var v: Variant = _parse_flag_value(v_str)
			if k != "":
				GameState.set_flag(StringName(k), v)
		"add_evidence":
			InvestigationState.acquire_evidence(StringName(_arg(parts, 1)), StringName(_arg(parts, 2)))
		"verify_evidence":
			InvestigationState.verify_evidence(StringName(_arg(parts, 1)), StringName(_arg(parts, 2)))
		"add_testimony":
			InvestigationState.hear_testimony(StringName(_arg(parts, 1)))
		"verify_testimony":
			InvestigationState.verify_testimony(StringName(_arg(parts, 1)), StringName(_arg(parts, 2)))
		"faction_trust":
			InvestigationState.adjust_faction_trust(StringName(_arg(parts, 1)), int(_arg(parts, 2, "0")))
		"companion_trust":
			InvestigationState.adjust_companion_trust(StringName(_arg(parts, 1)), int(_arg(parts, 2, "0")))
		"add_bond":
			InvestigationState.add_bond_event(StringName(_arg(parts, 1)), StringName(_arg(parts, 2)))
		"city_outcome":
			InvestigationState.set_city_outcome(
				StringName(_arg(parts, 1)),
				StringName(_arg(parts, 2)),
				_parse_flag_value(_arg(parts, 3, "true"))
			)
		"method_flag":
			InvestigationState.set_method_flag(StringName(_arg(parts, 1)), _parse_flag_value(_arg(parts, 2, "true")))
		"resolve_ch8_relationship_if_ready":
			_resolve_ch8_relationship_if_ready()
		"accept_quest":
			var qid := _arg(parts, 1)
			if qid != "":
				QuestManager.accept(StringName(qid))
		"complete_quest":
			var qid := _arg(parts, 1)
			if qid != "":
				QuestManager.complete(StringName(qid))
		"open_inventory":
			EventBus.ui_requested.emit(&"inventory")
		"open_equipment":
			EventBus.ui_requested.emit(&"equipment")
		"open_skills":
			EventBus.ui_requested.emit(&"skills")
		"give_skill":
			var sid := _arg(parts, 1)
			if sid != "":
				_grant_skill(StringName(sid))
		"open_quest_log":
			EventBus.ui_requested.emit(&"quest_log")
		"chapter_end":
			go_chapter_end(int(_arg(parts, 1, "1")))
		"join_faction":
			join_faction(StringName(_arg(parts, 1)))
		"play_bgm":
			AudioManager.play_bgm(_arg(parts, 1))
		"play_sfx":
			AudioManager.play_sfx(_arg(parts, 1))
		"stop_bgm":
			AudioManager.stop_bgm()
		"weather", "set_weather":
			WeatherManager.set_weather(StringName(_arg(parts, 1, "clear")), float(_arg(parts, 2, "1.0")))
		"clear_weather":
			WeatherManager.clear_weather()
		_:
			push_warning("[SceneRouter] unknown action: %s" % action)


func _resolve_ch8_relationship_if_ready() -> void:
	if bool(GameState.flags.get("ch8_relationship_epilogue_done", false)):
		return
	for flag_key: String in ["ch8_aftermath_luoyang_done", "ch8_aftermath_lieyun_done", "ch8_aftermath_zhuwei_done"]:
		if not bool(GameState.flags.get(flag_key, false)):
			return
	var outcome := InvestigationState.resolve_relationship_epilogue()
	GameState.set_flag(StringName("ch8_relationship_candidate_%s" % String(outcome)), true)
	_action_dialog("ch8_relationship_%s" % String(outcome))


# --- helpers ---

func _arg(parts: PackedStringArray, idx: int, default: String = "") -> String:
	return parts[idx] if idx < parts.size() else default


func _portal_route_key(source_scene_id: StringName, target_scene_id: StringName) -> String:
	return "%s->%s" % [String(source_scene_id), String(target_scene_id)]


func _pack_spawn(spawn: Vector2) -> Array[float]:
	return [spawn.x, spawn.y]


func _unpack_spawn(raw: Variant) -> Variant:
	if raw is Array and raw.size() >= 2:
		return Vector2(
			clampf(float(raw[0]), 0.0, 1.0),
			clampf(float(raw[1]), 0.0, 1.0)
		)
	return null


func _parse_flag_value(s: String) -> Variant:
	if s == "true": return true
	if s == "false": return false
	if s.is_valid_int(): return s.to_int()
	if s.is_valid_float(): return s.to_float()
	return s


func _action_dialog(dialog_id: String) -> void:
	if dialog_id == "":
		return
	var path := "%s%s.tres" % [DIALOG_DIR, dialog_id]
	if not ResourceLoader.exists(path):
		push_warning("[SceneRouter] dialog not found: %s" % path)
		return
	var script: Resource = load(path)
	if script is DialogScript:
		DialogPlayer.play(script)


func _load_field_scene_def(scene_id: StringName) -> SceneScript:
	var path := "%s%s.tres" % [FIELD_SCENE_DIR, String(scene_id)]
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is SceneScript:
		return OUTSKIRTS.materialize(res)
	return null


func _grant_skill(skill_id: StringName) -> void:
	GameState.learn_skill(skill_id)


func _scene_default_spawn(scene_id: StringName) -> Vector2:
	var scene_def := _load_field_scene_def(scene_id)
	if scene_def != null:
		return scene_def.player_spawn
	return Vector2(0.5, 0.8)
