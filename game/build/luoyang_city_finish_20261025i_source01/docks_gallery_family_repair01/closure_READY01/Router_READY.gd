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
const ESTATE_AM=preload("res://scripts/city/luoyang_estate_family_20261021am.gd")
const AP_QUARTERS=preload("res://scripts/city/luoyang_quarters_family_20261022ap.gd")
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
const LUOYANG_V3 = preload("res://scripts/city/luoyang_layered_v3_contract.gd")
const RESIDENT_CITY = preload("res://scripts/city/luoyang_resident_field_20261016.gd")
const AP_RETURN_SHA = preload("res://scripts/city/luoyang_parallel_source_hash_20261017k.gd")
const AP_LEASE_MARKET := &"ch4_s3_luoyang_market"
const AP_LEASE_ARTISAN := &"luoyang_artisan_residential_20261022ap"
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
var _portal_preparing := false
var _city_transition_token := 0
var _city_transition_live := false
var _city_transition_target: StringName = &""
var _public_city_request: Dictionary = {}
var _public_city_state: Dictionary = {}
var _public_city_generation := 0
var _resident_city = RESIDENT_CITY.new()
var _resident_return: Dictionary = {}
var _resident_return_state: Dictionary = {}
var _ap_return_source_job: RefCounted = null
var _ap_return_source_task: int = -1
var _local_layout_versions: Dictionary = {}
var _city_preflight_input: Dictionary = {}
var _city_preflight_result: Dictionary = {}
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

func _exit_tree() -> void:
	_cancel_resident_return("ROUTER_EXIT")
	_resident_city.release("ROUTER_EXIT")
	_cancel_public_city_owner("ROUTER_EXIT")
	end_field_transition_validation(_city_transition_token)


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
	go_field_smart(target, payload.get("return_spawn", null), pending_action, int(payload.get("return_world_map_version", _world_map_version)), int(payload.get("return_local_layout_version", _local_layout_versions.get(String(target), 1))))


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
		"return_local_layout_version": _battle_payload.get("return_local_layout_version", 1),
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
		"return_local_layout_version": _battle_payload.get("return_local_layout_version", 1),
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
		"return_local_layout_version": _battle_payload.get("return_local_layout_version", 1),
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
	if not OUTSKIRTS.biome_for(scene_id).is_empty() or LUOYANG_V3.owns_id(scene_id) or scene_id in AP_QUARTERS.IDS or scene_id==ESTATE_AM.ID:
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


func go_field_smart(scene_id: StringName, player_spawn: Variant = null, pending_action: String = "", spawn_version: int = -1, local_spawn_version: int = -1) -> bool:
	## City true means accepted/enqueued, NOT completed validation or arrival.
	## Non-city keeps the old bool contract; prepared portals call private below.
	if not _public_city_request.is_empty() or _portal_preparing or not _resident_return.is_empty(): return false
	if scene_id==&"": return false
	if LUOYANG_V3.owns_id(scene_id) and not OS.has_feature("web"):
		return _enqueue_public_city(scene_id,player_spawn,pending_action,spawn_version,local_spawn_version)
	# Exact original Family direct-entry lifecycle. Portal joint preparation keeps
	# its existing private path; no source receipt/token is invented here.
	if scene_id in AP_QUARTERS.IDS:
		if not AP_QUARTERS.validation_begin(): return false
		var direct_quarter: SceneScript=_load_field_scene_def(scene_id)
		if direct_quarter==null or not direct_quarter.is_walkable or not AP_QUARTERS.validation_finish(): return false
	elif scene_id==ESTATE_AM.ID:
		if not ESTATE_AM.validation_begin(): return false
		var direct_estate: SceneScript=_load_field_scene_def(scene_id)
		if direct_estate==null or not direct_estate.is_walkable or not ESTATE_AM.validation_finish(): return false
	return _go_field_smart_prepared(scene_id,player_spawn,pending_action,spawn_version,local_spawn_version)


func get_public_city_preparation_state() -> Dictionary:
	# Explicit value-only receipt. Never expose weak refs, Images or nav buffers.
	return _public_city_state.duplicate(true)


func get_resident_city_state() -> Dictionary:
	var result: Dictionary=_resident_city.state()
	result["return"]= _resident_return_state.duplicate(true)
	return result

func park_resident_exterior_for_room(room_id: StringName) -> bool:
	if OS.has_feature("web") or not _resident_return.is_empty() or not LUOYANG_V3.revision_room_known(room_id): return false
	var field: Node=get_tree().current_scene
	if not is_instance_valid(field) or not field.has_method("resident_begin_park"): return false
	var scene: SceneScript=field.get("_current_scene") as SceneScript
	if scene==null or not RESIDENT_CITY.supports_city(scene.scene_id) or scene.map_layout==null: return false
	# An enabled, visible authored portal is mandatory: the disabled southwest
	# pillar's ninth room definition alone cannot authorize residency.
	var portals: Array=scene.map_layout.portals
	var assembled: Variant=load("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
	if assembled.enabled() and assembled.known(room_id):
		var projected: Dictionary=assembled.project_portals(scene,portals)
		if projected.get("ok")!=true or not projected.get("portals") is Array: return false
		portals=projected.portals
	var count:=0
	for portal: Dictionary in portals:
		if StringName(portal.get("target_scene",&""))==room_id: count+=1
	if count!=1: return false
	var foot: Variant=_portal_return_spawns.get(_portal_route_key(room_id,scene.scene_id))
	if not foot is Vector2 or not LUOYANG_V3.safe_body(scene.scene_id,foot*LUOYANG_V3.SIZE): return false
	var proof:=LUOYANG_V3.resident_receipt(scene)
	var room_binding: Dictionary=LUOYANG_V3.revision_room_binding(room_id)
	if room_binding.is_empty(): return false
	if room_binding.has("city_id") and String(scene.scene_id)!=room_binding.city_id: return false
	var authored_exit: Vector2=assembled.authored_return_uv(room_id) if assembled.enabled() and assembled.known(room_id) else LUOYANG_V3._vec(room_binding.return_foot_px)/LUOYANG_V3.SIZE
	var loading:=get_node_or_null("/root/LoadingManager")
	var mode: int=int(loading.get("_source_process_mode")) if loading!=null and loading.get("_source_field")!=null else field.process_mode
	if not _resident_city.stage(field,room_id,proof,foot,authored_exit,mode): return false
	if _resident_city.detach(get_tree()): return true
	_resident_city.release("DETACH_REFUSED"); return false


func _ap_market_artisan_header() -> Dictionary:
	# Two literal existing public links only, with their original author feet.
	var header: Dictionary=AP_QUARTERS.source_header()
	if header.is_empty(): return {}
	var forward: Dictionary={};var backward: Dictionary={}
	for row: Dictionary in header.get("connections",[]):
		if row.get("source")==String(AP_LEASE_MARKET) and row.get("target")==String(AP_LEASE_ARTISAN):
			if not forward.is_empty(): return {}
			forward=row
		if row.get("source")==String(AP_LEASE_ARTISAN) and row.get("target")==String(AP_LEASE_MARKET):
			if not backward.is_empty(): return {}
			backward=row
	if forward.get("id")!="market_to_artisan" or backward.get("id")!="artisan_to_market" or forward.get("kind")!="PUBLIC_QUARTER_LINK" or backward.get("kind")!="PUBLIC_QUARTER_LINK": return {}
	# JSON stores numeric array components as floats. Validate only these four
	# fixed author feet structurally, then compare exact native Vector2 values.
	for row: Dictionary in [forward,backward]:
		for key: String in ["source_foot","target_foot"]:
			var pair: Variant=row.get(key)
			if not pair is Array or pair.size()!=2: return {}
			for scalar: Variant in pair:
				if typeof(scalar) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(scalar)): return {}
	if Vector2(forward.source_foot[0],forward.source_foot[1])!=Vector2(1100,1860) or Vector2(forward.target_foot[0],forward.target_foot[1])!=Vector2(2816,1740) or Vector2(backward.source_foot[0],backward.source_foot[1])!=Vector2(2816,1740) or Vector2(backward.target_foot[0],backward.target_foot[1])!=Vector2(1100,1860): return {}
	return {"forward":forward,"backward":backward}

func _ap_live_pair_portal(field: Node,source: StringName,target: StringName) -> bool:
	if not is_instance_valid(field) or not field.is_inside_tree() or not field.get("_exit_nodes") is Array: return false
	var source_scene: SceneScript=field.get("_current_scene") as SceneScript
	if source_scene==null or source_scene.scene_id!=source or field.get("_world_size")!=LUOYANG_V3.SIZE: return false
	var expected_pos: Vector2=Vector2(1100,1860) if source==AP_LEASE_MARKET else Vector2(2816,1740)
	var expected_target: Vector2=(Vector2(2816,1740) if source==AP_LEASE_MARKET else Vector2(1100,1860))/LUOYANG_V3.SIZE
	var count: int=0
	for zone: Node in field.get("_exit_nodes"):
		if is_instance_valid(zone) and zone.get("target_scene_id")==String(target):
			if zone.get("target_spawn_pos")!=expected_target or zone.get("position")!=(expected_pos/LUOYANG_V3.SIZE)*LUOYANG_V3.SIZE or zone.get("is_locked")!=false or zone.get("action")!="": return false
			if source==AP_LEASE_MARKET:
				# LoadingManager freezes this source before park. REMOVE-mode physics
				# overlap can be empty then; use the original exact doorway polygon,
				# actual player foot and original safe-foot callable, with no radius.
				if zone.get_script().resource_path!="res://scripts/field/luoyang_v3_exit_zone.gd" or not zone.has_method("can_enter") or not zone.call("can_enter"): return false
			else:
				# Artisan return is checked before LoadingManager freezes the field.
				if zone.get("_in_range")!=true or not zone is Area2D or not (zone as Area2D).get_overlapping_bodies().has(field.get("_player")): return false
			count+=1
	return count==1

func _park_market_for_exact_artisan() -> bool:
	if OS.has_feature("web") or not RESIDENT_CITY.extended_enabled() or not _resident_return.is_empty() or _resident_city.state().occupied: return false
	var field: Node=get_tree().current_scene
	if not is_instance_valid(field) or not field.has_method("resident_begin_park") or _ap_market_artisan_header().is_empty() or not _ap_live_pair_portal(field,AP_LEASE_MARKET,AP_LEASE_ARTISAN): return false
	var scene: SceneScript=field.get("_current_scene") as SceneScript
	var foot: Variant=_portal_return_spawns.get(_portal_route_key(AP_LEASE_ARTISAN,AP_LEASE_MARKET))
	var authored: Vector2=Vector2(1100,1860)/LUOYANG_V3.SIZE
	# Keep the existing public-link return policy (author portal UV), not a new
	# actor movement sample. Actual feet still must be safe and in the real Area.
	if scene==null or scene.scene_id!=AP_LEASE_MARKET or not foot is Vector2 or foot!=authored or not LUOYANG_V3.safe_body(AP_LEASE_MARKET,foot*LUOYANG_V3.SIZE): return false
	var actual: Vector2=field.call("resident_actual_spawn")
	if not actual.is_finite() or not LUOYANG_V3.safe_body(AP_LEASE_MARKET,actual*LUOYANG_V3.SIZE): return false
	var proof: Dictionary=LUOYANG_V3.resident_receipt(scene)
	if proof.is_empty(): return false
	var family: Dictionary=AP_QUARTERS.validation_receipt()
	if family.get("finalized")!=true or family.get("full_source_hash_passes")!=2 or family.get("source_first")!=family.get("source_final"): return false
	var loading: Node=get_node_or_null("/root/LoadingManager")
	var mode: int=int(loading.get("_source_process_mode")) if loading!=null and loading.get("_source_field")!=null else field.process_mode
	if not _resident_city.stage(field,AP_LEASE_ARTISAN,proof,foot,authored,mode,"ap_artisan"): return false
	if _resident_city.detach(get_tree()): return true
	_resident_city.release("AP_ARTISAN_DETACH_REFUSED");return false

func park_resident_exterior_for_excursion(destination: StringName) -> bool:
	if destination==AP_LEASE_ARTISAN: return _park_market_for_exact_artisan()
	if not is_world_map_scene(destination): return park_resident_exterior_for_room(destination)
	if not RESIDENT_CITY.extended_enabled() or OS.has_feature("web") or not _resident_return.is_empty() or _resident_city.state().occupied: return false
	var field: Node=get_tree().current_scene
	if not is_instance_valid(field) or not field.has_method("resident_begin_park"): return false
	var scene: SceneScript=field.get("_current_scene") as SceneScript
	if scene==null or not RESIDENT_CITY.supports_city(scene.scene_id): return false
	var foot: Vector2=field.call("resident_actual_spawn")
	var remembered: Variant=_portal_return_spawns.get(_portal_route_key(destination,scene.scene_id))
	if not remembered is Vector2 or remembered!=foot or not LUOYANG_V3.safe_body(scene.scene_id,foot*LUOYANG_V3.SIZE): return false
	var proof: Dictionary=LUOYANG_V3.resident_receipt(scene)
	var loading: Node=get_node_or_null("/root/LoadingManager")
	var mode: int=int(loading.get("_source_process_mode")) if loading!=null and loading.get("_source_field")!=null else field.process_mode
	if not _resident_city.stage(field,destination,proof,foot,Vector2.ZERO,mode,"world"): return false
	if _resident_city.detach(get_tree()): return true
	_resident_city.release("WORLD_DETACH_REFUSED"); return false

func rollback_resident_room_install() -> void:
	# Only the original source or an empty failed install can be restored. Never
	# replace an unrelated successor scene.
	if not _resident_city.parked or not is_instance_valid(_resident_city.field): return
	var current: Node=get_tree().current_scene
	if current!=null:
		var scene: SceneScript=current.get("_current_scene") as SceneScript
		if (scene==null and (current.scene_file_path!=SCENE_FIELD_WALKABLE or _current_field_id!=_resident_city.room)) or (scene!=null and scene.scene_id!=_resident_city.room): return
		current.get_parent().remove_child(current); current.queue_free()
	if _resident_city.attach(get_tree()):
		_current_field_id=_resident_city.city_id
		_current_field_spawn=_resident_city.field.call("resident_actual_spawn")
		_field_payload={"scene_id":_current_field_id,"player_spawn":_current_field_spawn}
		_resident_city.field.call("resident_abort_park",_resident_city.original_mode)
	_resident_city.finish()

func _try_resident_return(target: StringName,authored: Variant,source_spawn: Variant,action: String,public_request: bool=false,public_spawn: Variant=null) -> bool:
	if not _resident_city.matches(_current_field_id,target): return false
	var remembered: Variant=_portal_return_spawns.get(_portal_route_key(_current_field_id,target))
	var arrival: Variant=remembered
	if public_request and _resident_city.excursion_kind=="ap_artisan":
		_resident_city.release("AP_ARTISAN_PUBLIC_RETURN_NOT_AUTHORED");return false
	if public_request:
		var retained: SceneScript=_resident_city.field.get("_current_scene") as SceneScript
		if retained==null: _resident_city.release("RETAINED_SCENE_MISSING"); return false
		arrival=public_spawn if public_spawn is Vector2 else retained.player_spawn
	elif _resident_city.excursion_kind=="ap_artisan":
		var source_node: Node=get_tree().current_scene
		var source_scene: SceneScript=source_node.get("_current_scene") as SceneScript if is_instance_valid(source_node) else null
		var expected_source: Vector2=Vector2(2816,1740)/LUOYANG_V3.SIZE
		var actual_source: Vector2=source_node.call("resident_actual_spawn") if is_instance_valid(source_node) else Vector2(INF,INF)
		if not actual_source.is_finite() or not AP_QUARTERS.safe_body(AP_LEASE_ARTISAN,actual_source*LUOYANG_V3.SIZE): _resident_city.release("AP_ARTISAN_ACTUAL_FEET_UNSAFE");return false
		if _current_field_id!=AP_LEASE_ARTISAN or target!=AP_LEASE_MARKET or not action.is_empty() or _ap_market_artisan_header().is_empty() or source_scene==null or not AP_QUARTERS.matches(source_scene) or not _ap_live_pair_portal(source_node,AP_LEASE_ARTISAN,AP_LEASE_MARKET): _resident_city.release("AP_ARTISAN_RETURN_PAIR_DIFFERS");return false
		if not authored is Vector2 or authored!=_resident_city.authored_exit or not source_spawn is Vector2 or source_spawn!=expected_source or not remembered is Vector2 or remembered!=_resident_city.return_spawn or not LUOYANG_V3.safe_body(target,remembered*LUOYANG_V3.SIZE): _resident_city.release("AP_ARTISAN_RETURN_FEET_DIFFERS");return false
	elif _resident_city.excursion_kind=="room":
		if not authored is Vector2 or authored!=_resident_city.authored_exit or not remembered is Vector2 or remembered!=_resident_city.return_spawn: _resident_city.release("RETURN_DOOR_DIFFERS"); return false
	else:
		# World return preserves the actual safe city foot remembered on exit.
		# A normal entrance must still be the source world's exact authored gate.
		var source_node: Node=get_tree().current_scene
		var source_scene: SceneScript=source_node.get("_current_scene") as SceneScript if is_instance_valid(source_node) else null
		if source_scene==null or source_scene.map_layout==null or source_scene.scene_id!=_current_field_id or not is_world_map_scene(source_scene.scene_id) or not remembered is Vector2 or remembered!=_resident_city.return_spawn: _resident_city.release("WORLD_RETURN_IDENTITY_DIFFERS"); return false
		if authored!=null:
			var matches_gate: int=0
			for portal: Dictionary in source_scene.map_layout.portals:
				if StringName(portal.get("target_scene",&""))==target and portal.get("target_pos")==authored: matches_gate+=1
			if matches_gate!=1: _resident_city.release("WORLD_RETURN_PORTAL_DIFFERS"); return false
	if not arrival is Vector2 or not arrival.is_finite() or arrival.x<0 or arrival.y<0 or arrival.x>1 or arrival.y>1: return false
	var loading:=get_node_or_null("/root/LoadingManager")
	if loading==null or _portal_preparing or loading.get("_external_active")==true or loading.get("_transition_active")==true: return true
	var token: int=loading.call("begin_field_preparation","返回洛阳")
	if token<=0: return true
	_resident_return={"token":token,"generation":_resident_city.generation,"room":get_tree().current_scene,"target":target,"authored":authored,"arrival":arrival,"source_spawn":source_spawn,"action":action,"source_id":_current_field_id,"source_current_spawn":_current_field_spawn,"payload":_field_payload.duplicate(true),"attached":false,"public_request":public_request,"public_spawn":public_spawn}
	_resident_return_state={"active":true,"phase":"QUEUED","token":token,"started_usec":Time.get_ticks_usec(),"field_id":_resident_city.field.get_instance_id(),"metadata_ms":0.0,"resume_ms":0.0,"total_ms":0.0}
	_resident_return_state.merge({"hit":true,"excursion_kind":_resident_city.excursion_kind,"source_fresh_sha":false,"source_basis":"SAME_LIVE_OBJECTS_AND_EDITOR_METADATA","retained_bytes":_resident_city.last.get("estimated_bytes",0),"lease_generation":_resident_city.generation,"public_request":public_request,"final_live_identity":false})
	if public_request: _public_city_state={"active":true,"accepted":true,"phase":"LIVE_LEASE_QUEUED","token":token,"scene_id":String(target),"bool_means":"ACCEPTED_ENQUEUED_NOT_READY","source_fresh_sha":false}
	_portal_preparing=true
	_continue_resident_return.call_deferred(_resident_return.duplicate())
	return true

func _resident_return_owns(context: Dictionary) -> bool:
	return not _resident_return.is_empty() and context.get("token")==_resident_return.get("token") and context.get("generation")==_resident_return.get("generation")

func _finish_ap_return_source_job(cancel: bool) -> void:
	if _ap_return_source_job!=null and cancel: _ap_return_source_job.call("request_cancel")
	if _ap_return_source_task>=0: WorkerThreadPool.wait_for_task_completion(_ap_return_source_task)
	_ap_return_source_task=-1;_ap_return_source_job=null

func _ap_return_complete_source_sha(context: Dictionary) -> bool:
	if not _resident_return_owns(context) or _ap_return_source_task>=0 or _ap_return_source_job!=null: return false
	var expected: Dictionary=_resident_city.receipt.get("sources",{}).duplicate(true)
	if expected.is_empty(): return false
	var job: RefCounted=AP_RETURN_SHA.new()
	job.set("paths",expected.keys());job.set("worker_limit",4)
	_ap_return_source_job=job
	var started: int=Time.get_ticks_usec()
	var task: int=WorkerThreadPool.add_task(Callable(job,"run"),false,"Exact AP Market lease complete source SHA")
	if task<0: _finish_ap_return_source_job(true);return false
	_ap_return_source_task=task
	_resident_return_state.phase="VERIFYING_COMPLETE_MARKET_SOURCES"
	while _ap_return_source_task==task and not WorkerThreadPool.is_task_completed(task):
		if not _resident_return_owns(context): _finish_ap_return_source_job(true);return false
		await get_tree().process_frame
	if not _resident_return_owns(context) or _ap_return_source_task!=task: return false
	WorkerThreadPool.wait_for_task_completion(task)
	var actual: Dictionary=job.get("hashes")
	var details: Dictionary=job.call("debug_state")
	_ap_return_source_task=-1;_ap_return_source_job=null
	var valid: bool=details.get("complete")==true and actual.size()==expected.size() and LUOYANG_V3._equal_value(actual,expected)
	_resident_return_state.source_fresh_sha=valid
	_resident_return_state.source_hash_passes=1
	_resident_return_state.source_count=expected.size()
	_resident_return_state.source_sha_ms=(Time.get_ticks_usec()-started)/1000.0
	_resident_return_state.source_worker=details
	_resident_return_state.source_basis="FRESH_COMPLETE_MARKET_SHA_THEN_ORIGINAL_LIVE_IDENTITY_AND_METADATA"
	return valid

func _cancel_resident_return(reason: String) -> bool:
	_finish_ap_return_source_job(true)
	if _resident_return.is_empty(): return false
	var context:=_resident_return.duplicate()
	var loading:=get_node_or_null("/root/LoadingManager")
	if context.attached and is_instance_valid(_resident_city.field):
		var exterior: Node=_resident_city.field
		if exterior.is_inside_tree():
			if get_tree().current_scene==exterior: get_tree().current_scene=null
			exterior.get_parent().remove_child(exterior)
		_resident_city.parked=true
		_resident_city.release(reason)
		var room: Node=context.room
		if is_instance_valid(room) and not room.is_inside_tree():
			get_tree().root.add_child(room); get_tree().current_scene=room
			room.call("resident_abort_park",int(context.get("room_mode",Node.PROCESS_MODE_INHERIT)))
		_current_field_id=context.source_id; _current_field_spawn=context.source_current_spawn; _field_payload=context.payload.duplicate(true)
	_resident_return={}; _portal_preparing=false
	_resident_return_state.active=false; _resident_return_state.phase=reason
	if context.public_request: _public_city_state.active=false; _public_city_state.phase=reason; _public_city_state.error=reason
	if loading!=null and _field_preparation_is_current(loading,int(context.token)): loading.call("finish_field_preparation",int(context.token))
	return true

func _continue_resident_return(context: Dictionary) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not _resident_return_owns(context): return
	var loading:=get_node_or_null("/root/LoadingManager")
	if not _field_preparation_is_current(loading,int(context.token)) or get_tree().current_scene!=context.room:
		_cancel_resident_return("OWNER_CHANGED"); return
	var started:=Time.get_ticks_usec()
	var exterior: Node=_resident_city.field
	var scene: SceneScript=exterior.get("_current_scene") as SceneScript
	var valid: bool=_resident_city.identities_match() and LUOYANG_V3.resident_matches(_resident_city.receipt,scene)
	_resident_return_state.metadata_ms=(Time.get_ticks_usec()-started)/1000.0
	if valid and _resident_city.excursion_kind=="ap_artisan":
		valid=await _ap_return_complete_source_sha(context)
		if not _resident_return_owns(context): return
		# Full SHA is additional, never a substitute for original live/metadata.
		valid=valid and _field_preparation_is_current(loading,int(context.token)) and get_tree().current_scene==context.room and _resident_city.identities_match() and LUOYANG_V3.resident_matches(_resident_city.receipt,scene)
	if not valid:
		_cancel_resident_return("SOURCE_INVALIDATED_COLD_FALLBACK")
		_resident_city.release("SOURCE_INVALIDATED")
		_resident_return_state.hit=false; _resident_return_state.miss_reason="SOURCE_OR_LIVE_IDENTITY_CHANGED"
		if context.public_request: go_field_smart.call_deferred(context.target,context.public_spawn,context.action,-1,LUOYANG_V3.VERSION)
		else: go_field_from_portal.call_deferred(context.target,context.authored,context.source_spawn,context.action)
		return
	_resident_return_state.phase="RESTORING_LIVE_FIELD"
	loading.call("update_field_preparation_progress",int(context.token),.6,"正在恢复街区与人物……")
	var room: Node=context.room
	var room_mode: int=room.process_mode
	if not room.call("resident_begin_park"):
		_cancel_resident_return("ROOM_NOT_READY"); return
	get_tree().current_scene=null; room.get_parent().remove_child(room)
	if not _resident_city.attach(get_tree()):
		get_tree().root.add_child(room); get_tree().current_scene=room; room.call("resident_abort_park",Node.PROCESS_MODE_INHERIT)
		_cancel_resident_return("RESIDENT_ATTACH_REFUSED"); return
	_resident_return.attached=true
	_resident_return.room_mode=room_mode
	started=Time.get_ticks_usec()
	var resumed: bool=await exterior.call("resident_resume",context.arrival)
	if not _resident_return_owns(context): return
	_resident_return_state.resume_ms=(Time.get_ticks_usec()-started)/1000.0
	if not resumed or not _field_preparation_is_current(loading,int(context.token)) or not _resident_city.identities_match() or not LUOYANG_V3.resident_matches(_resident_city.receipt,scene):
		_cancel_resident_return("RESIDENT_SAFETY_REFUSED"); return
	_current_field_id=context.target; _current_field_spawn=context.arrival
	_local_layout_versions[String(context.target)]=LUOYANG_V3.VERSION
	_field_payload={"scene_id":context.target,"player_spawn":context.arrival}
	if not context.public_request and is_world_map_scene(context.source_id) and context.source_spawn is Vector2 and context.source_spawn.is_finite():
		_portal_return_spawns[_portal_route_key(context.target,context.source_id)]=context.source_spawn
	if _resident_city.excursion_kind=="ap_artisan": _portal_return_spawns[_portal_route_key(context.target,context.source_id)]=context.source_spawn
	room.call("resident_discard"); room.free()
	exterior.call("resident_abort_park",_resident_city.original_mode)
	_resident_city.finish()
	_resident_return={}; _portal_preparing=false
	_resident_return_state.active=false; _resident_return_state.phase="READY"
	_resident_return_state.final_live_identity=true
	_resident_return_state.total_ms=(Time.get_ticks_usec()-int(_resident_return_state.started_usec))/1000.0
	_resident_return_state.total_ms_excludes_loading_hide=true
	if context.public_request: _public_city_state.active=false; _public_city_state.phase="LIVE_LEASE_ARRIVED"; _public_city_state.finished_msec=Time.get_ticks_msec()
	EventBus.scene_entered.emit(context.target)
	AudioManager.ensure_bgm_for_scene(context.target)
	loading.call("finish_field_preparation",int(context.token))
	if not String(context.action).is_empty(): resolve_action(context.action)


func _public_city_reject(reason: String) -> bool:
	if _public_city_request.is_empty():
		_public_city_state={"active":false,"accepted":false,"phase":"REJECTED","token":0,"error":reason}
	return false


func _enqueue_public_city(id: StringName,spawn: Variant,action: String,world_version: int,local_version: int) -> bool:
	var loading:=get_node_or_null("/root/LoadingManager")
	if not _public_city_request.is_empty() or _portal_preparing or _city_transition_token>0 or loading==null or loading.get("_transition_active")==true or loading.get("_external_active")==true: return _public_city_reject("BUSY_OR_LOADING_UNAVAILABLE")
	if spawn!=null and (not spawn is Vector2 or not spawn.is_finite() or spawn.x<0 or spawn.y<0 or spawn.x>1 or spawn.y>1): return _public_city_reject("INVALID_PUBLIC_SPAWN")
	if local_version not in [-1,1,LUOYANG_V3.VERSION] or world_version not in [-1,12,13,14,15]: return _public_city_reject("INVALID_PUBLIC_COORDINATE_VERSION")
	var same_position: bool=id==_current_field_id and spawn==null and _current_field_spawn is Vector2
	var effective_version: int=local_version if local_version>=0 else (int(_local_layout_versions.get(String(id),1)) if spawn is Vector2 or same_position else LUOYANG_V3.VERSION)
	# A direct public request has no authored source portal for legacy version1.
	if effective_version!=LUOYANG_V3.VERSION: return _public_city_reject("PUBLIC_CITY_REQUIRES_CURRENT_COORDINATES")
	if not FileAccess.file_exists(FIELD_SCENE_DIR+String(id)+".tres") or not FileAccess.file_exists(SCENE_FIELD_WALKABLE) or not LUOYANG_V3._hash(LUOYANG_V3.manifest_sha(id)): return _public_city_reject("MISSING_OR_PENDING_CITY_SOURCE")
	_public_city_generation+=1
	var generation:=_public_city_generation
	var source_id:=_current_field_id
	var source_scene: Node=get_tree().current_scene
	var source_instance:=source_scene.get_instance_id() if is_instance_valid(source_scene) else 0
	if not ContentPackManager.ensure_scene_pack(id,func(ok: bool) -> void:
		if ok and generation==_public_city_generation and _public_city_request.is_empty() and _current_field_id==source_id and (get_tree().current_scene.get_instance_id() if is_instance_valid(get_tree().current_scene) else 0)==source_instance:
			go_field_smart(id,spawn,action,world_version,local_version)
	): return _public_city_reject("PACK_PENDING_NO_CITY_REQUEST_ENQUEUED")
	if RESIDENT_CITY.extended_enabled() and _try_resident_return(id,null,_current_field_spawn,action,true,spawn): return true
	# One alive city only. Never overwrite its C navigation while it is parked.
	if _resident_city.state().occupied: _resident_city.release("COLD_CITY_REQUEST")
	_resident_return_state={"active":false,"phase":"MISS_COLD_CITY","hit":false,"miss_reason":String(_resident_city.last.get("reason",_resident_city.last.get("phase","EMPTY"))),"source_fresh_sha":false,"cold_full_sha_required":true}
	var navigation:=get_navigation_state().duplicate(true)
	var snapshot: Dictionary={}
	var stores: Dictionary={"_records":LUOYANG_V3._records,"_masks":LUOYANG_V3._masks,"_solids":LUOYANG_V3._solids,"_using_patch":LUOYANG_V3._using_patch}
	for key: String in ["_records","_masks","_solids","_using_patch"]:
		var values: Dictionary=stores[key]
		var value: Variant=values.get(String(id))
		# The original Image is retained by identity, not duplicated/mutated.
		if value is Dictionary or value is Array: value=value.duplicate(true)
		snapshot[key]={"exists":values.has(String(id)),"value":value}
	var token: int=loading.call("begin_field_preparation","前往洛阳")
	if token<=0: return _public_city_reject("LOADING_PREPARATION_REFUSED")
	var context: Dictionary={"generation":generation,"token":token,"id":id,"spawn":spawn,"action":action,"world_version":world_version,"local_version":local_version,"source_id":source_id,"source_spawn":_current_field_spawn,"source_instance":source_instance,"navigation_before":navigation,"payload_before":_field_payload.duplicate(true),"local_versions_before":_local_layout_versions.duplicate(true),"nav_before":snapshot}
	_public_city_request=context.duplicate()
	_public_city_state={"active":true,"accepted":true,"phase":"QUEUED","token":token,"request_generation":generation,"scene_id":String(id),"source_scene_id":String(source_id),"request_msec":Time.get_ticks_msec(),"request_frame":Engine.get_process_frames(),"draw_checkpoint_frame":0,"validation_started_msec":0,"prepared_msec":0,"finished_msec":0,"error":"","bool_means":"ACCEPTED_ENQUEUED_NOT_READY"}
	_portal_preparing=true
	_city_transition_token=token; _city_transition_target=id; _city_transition_live=false
	_continue_public_city.call_deferred(context)
	return true


func _public_city_request_identity(context: Dictionary) -> bool:
	return not _public_city_request.is_empty() and _public_city_request.get("generation")==context.get("generation") and _public_city_request.get("token")==context.get("token") and _public_city_request.get("id")==context.get("id")

func _owns_public_city(context: Dictionary) -> bool:
	return _public_city_request_identity(context) and _city_transition_token==context.token and _city_transition_target==context.id


func _public_city_source_unchanged(context: Dictionary) -> bool:
	var current:=get_tree().current_scene
	return _current_field_id==context.source_id and (current.get_instance_id() if is_instance_valid(current) else 0)==context.source_instance and get_navigation_state()==context.navigation_before and _field_payload==context.payload_before


func _restore_public_city_nav(context: Dictionary) -> void:
	# Joined worker cannot mutate these retained original values. This is undo,
	# never a proof for a new arrival, and lives only for this active request.
	var stores: Dictionary={"_records":LUOYANG_V3._records,"_masks":LUOYANG_V3._masks,"_solids":LUOYANG_V3._solids,"_using_patch":LUOYANG_V3._using_patch}
	for key: String in ["_records","_masks","_solids","_using_patch"]:
		var values: Dictionary=stores[key]
		var prior: Dictionary=context.nav_before[key]
		if prior.exists: values[String(context.id)]=prior.value
		else: values.erase(String(context.id))


func _finish_public_city_failure(context: Dictionary,reason: String) -> bool:
	context=context.duplicate() # caller may pass the active outer dictionary
	if not _public_city_request_identity(context): return false
	var loading:=get_node_or_null("/root/LoadingManager")
	var loading_owned: bool=loading!=null and _field_preparation_is_current(loading,int(context.token))
	var source: Node=get_tree().current_scene
	var same_source: bool=(source.get_instance_id() if is_instance_valid(source) else 0)==context.source_instance
	var no_successor: bool=_city_transition_token in [0,int(context.token)] and LUOYANG_V3._live_source_token in [0,int(context.token)] and int(LUOYANG_V3._transition_validation.get("token",0)) in [0,int(context.token)]
	_public_city_generation+=1
	if _city_transition_token==context.token: end_field_transition_validation(int(context.token))
	elif LUOYANG_V3._live_source_token==context.token: LUOYANG_V3.end_transition_validation(int(context.token))
	# A synchronous LM handoff failure may already have ended this token.
	# Roll back only our data while the original Scene still exists and no new
	# C owner has taken over. Never finish/hide another external Loading owner.
	if no_successor and same_source:
		_restore_public_city_nav(context)
		if _public_city_state.get("phase")=="PREPARED" and _current_field_id==context.id and _field_payload.get("scene_id")==context.id:
			_current_field_id=context.source_id; _current_field_spawn=context.source_spawn
			_field_payload=context.payload_before.duplicate(true)
			_local_layout_versions=context.local_versions_before.duplicate(true)
	_public_city_state.active=false; _public_city_state.phase="CANCELLED" if reason=="CANCELLED" else "FAILED"
	_public_city_state.error=reason; _public_city_state.finished_msec=Time.get_ticks_msec()
	_public_city_request={}; _portal_preparing=false
	if loading_owned: loading.call("finish_field_preparation",int(context.token))
	return true


func cancel_public_city_preparation(token: int) -> bool:
	# Synchronous cooperative join, prepare-only. Handoff cannot be cancelled.
	if _resident_return.get("token",0)==token: return _cancel_resident_return("CANCELLED")
	if token<=0 or _public_city_request.get("token",0)!=token: return false
	var loading:=get_node_or_null("/root/LoadingManager")
	if loading==null or not _field_preparation_is_current(loading,token): return false
	return _finish_public_city_failure(_public_city_request,"CANCELLED")


func _cancel_public_city_owner(reason: String) -> void:
	_public_city_generation+=1 # also invalidate pending content-pack callbacks
	if not _public_city_request.is_empty(): _finish_public_city_failure(_public_city_request,reason)


func _continue_public_city(context: Dictionary) -> void:
	await get_tree().process_frame
	if not _owns_public_city(context):
		_finish_public_city_failure(context,"PUBLIC_REQUEST_OWNER_CHANGED"); return
	await get_tree().process_frame
	if not _owns_public_city(context):
		_finish_public_city_failure(context,"PUBLIC_REQUEST_OWNER_CHANGED"); return
	var loading:=get_node_or_null("/root/LoadingManager")
	if not _public_city_source_unchanged(context) or not _field_preparation_is_current(loading,int(context.token)):
		_finish_public_city_failure(context,"PUBLIC_SOURCE_OR_LOADING_OWNER_CHANGED"); return
	_public_city_state.phase="VALIDATING"; _public_city_state.draw_checkpoint_frame=Engine.get_process_frames(); _public_city_state.validation_started_msec=Time.get_ticks_msec()
	var raw:=ResourceLoader.load(FIELD_SCENE_DIR+String(context.id)+".tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if raw==null or not raw.has_meta("city_enclosure_manifest_sha"):
		_finish_public_city_failure(context,"CITY_CANONICAL_ENCLOSURE_UNAVAILABLE"); return
	var scene: SceneScript=await LUOYANG_V3.resolve_scene_for_live_transition(raw,int(context.token))
	if not _owns_public_city(context):
		_finish_public_city_failure(context,"PUBLIC_REQUEST_OWNER_CHANGED"); return
	if scene==null or not _public_city_source_unchanged(context) or not _field_preparation_is_current(loading,int(context.token)):
		_finish_public_city_failure(context,"CITY_COMPLETE_LIVE_VALIDATION_FAILED"); return
	_city_transition_live=LUOYANG_V3.transition_validation_state().get("live_scope",false)==true
	if not _city_transition_live: _finish_public_city_failure(context,"CITY_LIVE_PROOF_REQUIRED"); return
	_public_city_state.phase="PREPARED"; _public_city_state.prepared_msec=Time.get_ticks_msec()
	var accepted:=_go_field_smart_prepared(context.id,context.spawn,context.action,int(context.world_version),int(context.local_version))
	if not _public_city_request_identity(context): return
	if not accepted or loading.get("_transition_active")!=true:
		_finish_public_city_failure(context,"PREPARED_CITY_HANDOFF_REFUSED"); return
	_public_city_state.active=false; _public_city_state.phase="HANDED_OFF"; _public_city_state.finished_msec=Time.get_ticks_msec()
	_public_city_request={}; _portal_preparing=false
	loading.call("finish_field_preparation",int(context.token))


func _go_field_smart_prepared(scene_id: StringName, player_spawn: Variant = null, pending_action: String = "", spawn_version: int = -1, local_spawn_version: int = -1) -> bool:
	var revision_room: bool=LUOYANG_V3.revision_room_known(scene_id)
	if revision_room and _load_field_scene_def(scene_id)==null: return false
	var city_scene: SceneScript = _load_field_scene_def(scene_id) if LUOYANG_V3.owns_id(scene_id) else null
	var new_world: bool = is_world_map_scene(scene_id) and world_version_for_scene(scene_id) == 15
	if new_world and not WORLD_V15.is_v15(_load_field_scene_def(scene_id)):
		push_warning("[SceneRouter] 完整v15地图尚未发布，导航未修改。")
		return false
	if LUOYANG_V3.is_v3(city_scene) or new_world or revision_room:
		var loading: Node = get_node_or_null("/root/LoadingManager")
		if loading != null and loading.get("_transition_active") == true:
			push_warning("[SceneRouter] 上一场景仍在载入，新门户请求未修改导航。")
			return false
	if LUOYANG_V3.owns_id(scene_id) and city_scene == null:
		push_warning("[SceneRouter] 洛阳分层候选资源尚未就绪，保留当前场景。")
		return false
	if LUOYANG_V3.is_v3(city_scene):
		var current_position: bool = scene_id == _current_field_id and not player_spawn is Vector2 and _current_field_spawn is Vector2
		var requested: Vector2 = player_spawn if player_spawn is Vector2 else (_current_field_spawn if current_position else city_scene.player_spawn)
		if scene_id==&"ch4_s3_luoyang_market" and not player_spawn is Vector2 and not current_position:
			var default_spawn_contract_24e: Variant=LUOYANG_V3
			requested=default_spawn_contract_24e.call("project_authored_default_spawn",city_scene,requested)
		var source_local: int = local_spawn_version if local_spawn_version >= 0 else (int(_local_layout_versions.get(String(scene_id), 1)) if player_spawn is Vector2 or current_position else LUOYANG_V3.VERSION)
		var resolved: Dictionary = LUOYANG_V3.migrate_spawn_report(scene_id, requested, source_local, &"", _city_transition_token_for(scene_id))
		if resolved.is_empty():
			push_warning("[SceneRouter] 洛阳没有安全的同区落点，保留当前状态。")
			return false
		player_spawn = resolved.spawn
		local_spawn_version = LUOYANG_V3.VERSION
	elif LUOYANG_V3.owns_id(scene_id) and (local_spawn_version == LUOYANG_V3.VERSION or int(_local_layout_versions.get(String(scene_id), 1)) == LUOYANG_V3.VERSION):
		push_warning("[SceneRouter] 当前洛阳地图不支持新版坐标降级，保留当前状态。")
		return false
	if not OUTSKIRTS.biome_for(scene_id).is_empty():
		var local_scene := _load_field_scene_def(scene_id)
		if local_scene == null:
			push_warning("[SceneRouter] 新郊外尚未完成审查或资源缺失，暂不进入。")
			return false
		var requested: Vector2 = player_spawn if player_spawn is Vector2 else (_current_field_spawn if scene_id == _current_field_id and _current_field_spawn is Vector2 else local_scene.player_spawn)
		var resolved: Variant = OUTSKIRTS.repair_spawn(local_scene, requested)
		if not resolved is Vector2:
			push_warning("[SceneRouter] 新郊外没有安全落点，保留当前场景。")
			return false
		player_spawn = resolved
	if not ContentPackManager.ensure_scene_pack(scene_id, func(ok: bool) -> void:
		if ok:
			go_field_smart(scene_id, player_spawn, pending_action, spawn_version, local_spawn_version)
	):
		return false
	scene_id = _normalize_field_id(scene_id)
	var target_scene := SCENE_FIELD_WALKABLE if LUOYANG_V3.is_v3(city_scene) else get_field_scene_path(scene_id)
	if target_scene.is_empty(): return false
	if (LUOYANG_V3.is_v3(city_scene) or (is_world_map_scene(scene_id) and world_version_for_scene(scene_id) == 15)) and not ResourceLoader.exists(target_scene):
		push_warning("[SceneRouter] 新地图控制器资源缺失，保留当前导航状态。")
		return false
	if target_scene == SCENE_FIELD_WALKABLE:
		var spawn := city_scene.player_spawn if LUOYANG_V3.is_v3(city_scene) else _scene_default_spawn(scene_id)
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
				return false
			spawn = repaired
			_world_map_version = world_contract.VERSION
		elif scene_id == WORLD_MAP_STAGING_SCENE:
			_world_map_version = 13
		_current_field_spawn = spawn
		_field_payload = {"scene_id": scene_id, "player_spawn": spawn}
	else:
		_current_field_spawn = null
		_field_payload = {"scene_id": scene_id}
	AudioManager.stop_dialog_audio()
	if is_world_map_scene(scene_id): _active_world_map_scene = scene_id
	if not pending_action.is_empty():
		_field_payload["pending_action"] = pending_action
	_current_field_id = scene_id
	if LUOYANG_V3.owns_id(scene_id): _local_layout_versions[String(scene_id)] = LUOYANG_V3.VERSION if LUOYANG_V3.is_v3(city_scene) else 1
	var loading_context := {"title": _loading_title_for_field(scene_id)}
	var exact_ap_excursion: bool=scene_id==AP_LEASE_ARTISAN and not _ap_market_artisan_header().is_empty() and is_instance_valid(get_tree().current_scene) and (get_tree().current_scene.get("_current_scene") as SceneScript)!=null and (get_tree().current_scene.get("_current_scene") as SceneScript).scene_id==AP_LEASE_MARKET
	if LUOYANG_V3.is_v3(city_scene) or new_world or revision_room or exact_ap_excursion:
		loading_context["field_scene_id"] = String(scene_id)
		loading_context["field_spawn"] = _current_field_spawn
		if _city_transition_token_for(scene_id) > 0: loading_context["city_validation_token"] = _city_transition_token
	_transition_to(target_scene, &"field", loading_context)
	return true


func go_field_from_portal(
	scene_id: StringName,
	authored_target_spawn: Variant = null,
	source_player_spawn: Variant = null,
	pending_action: String = ""
) -> void:
	if not _public_city_request.is_empty() or not _resident_return.is_empty(): return
	if _try_resident_return(scene_id,authored_target_spawn,source_player_spawn,pending_action): return
	if LUOYANG_V3.owns_id(scene_id) and _resident_city.state().occupied: _resident_city.release("DIFFERENT_OR_COLD_CITY_PORTAL")
	var target: StringName = _active_world_map_scene if scene_id == WORLD_MAP_SCENE and _active_world_map_scene != WORLD_MAP_SCENE else scene_id
	if not _joint_portal_requires_prepare(_current_field_id, target):
		_go_field_from_portal_prepared(scene_id, authored_target_spawn, source_player_spawn, pending_action)
		return
	if _portal_preparing: return
	if not ContentPackManager.ensure_scene_pack(target, func(ok: bool) -> void:
		if ok: go_field_from_portal(scene_id, authored_target_spawn, source_player_spawn, pending_action)
	): return
	var loading: Node = get_node_or_null("/root/LoadingManager")
	if loading == null or not loading.has_method("begin_field_preparation"):
		_go_field_from_portal_prepared(scene_id, authored_target_spawn, source_player_spawn, pending_action)
		return
	var token: int = loading.call("begin_field_preparation", _loading_title_for_field(target))
	if token == 0: return
	_portal_preparing = true
	if LUOYANG_V3.owns_id(target):
		_city_transition_token = token
		_city_transition_target = target
		_city_transition_live = false
	var source: StringName = _current_field_id
	# Draw first. The live source SHA job is threaded; cold BASE/C validation
	# still uses its unchanged main-thread GPU/Resource checks.
	await get_tree().process_frame
	await get_tree().process_frame
	var city_prepared: bool = source == _current_field_id and _field_preparation_is_current(loading, token)
	if LUOYANG_V3.owns_id(target) and _city_transition_token_for(target) != token: city_prepared = false
	if city_prepared and _city_transition_token_for(target) == token:
		var raw: SceneScript = load(FIELD_SCENE_DIR + String(target) + ".tres") as SceneScript
		var candidate: bool = "--luoyang-enclosure-v11-candidate" in OS.get_cmdline_user_args() and "--luoyang-v3-candidate" in OS.get_cmdline_user_args()
		if raw != null and (raw.has_meta("city_enclosure_manifest_sha") or candidate):
			var validated_city: SceneScript = await LUOYANG_V3.resolve_scene_for_live_transition(raw, token)
			city_prepared = validated_city != null and source == _current_field_id and _city_transition_token_for(target) == token and _field_preparation_is_current(loading, token)
			if city_prepared: _city_transition_live = LUOYANG_V3.transition_validation_state().get("live_scope",false) == true
		elif raw == null:
			city_prepared = false
		else:
			end_field_transition_validation(token)
	if city_prepared and source == _current_field_id and _field_preparation_is_current(loading, token):
		_go_field_from_portal_prepared(scene_id, authored_target_spawn, source_player_spawn, pending_action)
	_portal_preparing = false
	loading.call("finish_field_preparation", token)
	if loading.get("_transition_active") != true: end_field_transition_validation(token)


func _field_preparation_is_current(loading: Node, token: int) -> bool:
	return token > 0 and is_instance_valid(loading) and loading.is_inside_tree() and loading.get("_field_preparation_token") == token and loading.get("_external_token") == token and loading.get("_external_active") == true and loading.get("_transition_active") == false


func _go_field_from_portal_prepared(
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
	if _joint_portal_requires_prepare(source_scene_id, scene_id):
		# New city/world route: no remembered coordinate/version writes until the
		# pack, destination art and safe arrival have all passed. Legacy91 keeps
		# its public resolve-and-record contract below.
		if not ContentPackManager.ensure_scene_pack(scene_id, func(ok: bool) -> void:
			if ok: go_field_from_portal(scene_id, authored_target_spawn, source_player_spawn, pending_action)
		): return
		var source_spawn: Variant = source_player_spawn if source_player_spawn is Vector2 else _current_field_spawn
		var prepared: Dictionary = _prepare_joint_portal_arrival(source_scene_id, scene_id, source_spawn, authored_target_spawn)
		if prepared.is_empty(): return
		if not _go_field_smart_prepared(scene_id, prepared.arrival, pending_action, int(prepared.world_version), int(prepared.local_version)): return
		if is_world_map_scene(scene_id): _world_map_return_scene = source_scene_id
		if prepared.has("return_spawn"): _portal_return_spawns[_portal_route_key(scene_id, source_scene_id)] = prepared.return_spawn
		return
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
	if _joint_portal_requires_prepare(source_scene_id, target_scene_id):
		var prepared: Dictionary = _prepare_joint_portal_arrival(source_scene_id, target_scene_id, source_player_spawn, authored_target_spawn)
		return prepared.arrival if not prepared.is_empty() else Vector2(INF, INF)
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
	var target_city: SceneScript = _load_field_scene_def(target_scene_id) if LUOYANG_V3.owns_id(target_scene_id) else null
	if LUOYANG_V3.is_v3(target_city):
		var target_version: int = int(_local_layout_versions.get(String(target_scene_id), 1)) if remembered is Vector2 else 1
		var city_arrival: Dictionary = LUOYANG_V3.migrate_spawn_report(target_scene_id, arrival, target_version, source_scene_id if not remembered is Vector2 else &"")
		if city_arrival.is_empty(): return Vector2(INF, INF)
		arrival = city_arrival.spawn
		_local_layout_versions[String(target_scene_id)] = LUOYANG_V3.VERSION

	if String(source_scene_id) != "" and source_scene_id != target_scene_id and source_player_spawn is Vector2:
		var safe_source := source_player_spawn as Vector2
		safe_source.x = clampf(safe_source.x, 0.0, 1.0)
		safe_source.y = clampf(safe_source.y, 0.0, 1.0)
		_portal_return_spawns[_portal_route_key(target_scene_id, source_scene_id)] = safe_source
	return arrival


func _joint_portal_requires_prepare(source: StringName, target: StringName) -> bool:
	if AP_QUARTERS.owns_route(source,target): return true
	if ESTATE_AM.owns_route(source,target): return true
	if "--luoyang-v3-candidate" in OS.get_cmdline_user_args() and (LUOYANG_V3.owns_id(source) or LUOYANG_V3.owns_id(target)): return true
	for id: StringName in [source, target]:
		if LUOYANG_V3.owns_id(id):
			var raw: SceneScript = ResourceLoader.load(FIELD_SCENE_DIR + String(id) + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
			if LUOYANG_V3.is_v3(raw): return true
	return (is_world_map_scene(source) and world_version_for_scene(source) == 15) or (is_world_map_scene(target) and world_version_for_scene(target) == 15)


func _prepare_joint_portal_arrival(source: StringName, target: StringName, source_spawn: Variant, authored: Variant) -> Dictionary:
	# Pure, including the public resolve path. All committed navigation remains
	# untouched if candidate resolution, native clearance or content pack fails.
	if AP_QUARTERS.owns_route(source,target) and not AP_QUARTERS.validation_begin(): return {}
	if ESTATE_AM.owns_route(source,target) and not ESTATE_AM.validation_begin(): return {}
	var destination: SceneScript = _load_field_scene_def(target)
	if destination == null: push_warning("[SceneRouter] 新门户目标尚未就绪，导航未修改。"); return {}
	var arrival: Vector2 = authored if authored is Vector2 else destination.player_spawn
	var remembered: Variant = _portal_return_spawns.get(_portal_route_key(source, target), null)
	if remembered is Vector2: arrival = remembered
	var family_arrival: Dictionary={}
	if AP_QUARTERS.owns_route(source,target):
		family_arrival=AP_QUARTERS.prepare_arrival(source,target,authored,remembered,destination)
		if family_arrival.is_empty(): return {}
		arrival=family_arrival.spawn
	if ESTATE_AM.owns_route(source,target):
		family_arrival=ESTATE_AM.prepare_arrival(source,target,authored,remembered,destination)
		if family_arrival.is_empty(): return {}
		arrival=family_arrival.spawn
	var world_version: int = _world_map_version
	var local_version: int=3 if not family_arrival.is_empty() else -1
	if is_world_map_scene(target):
		var gateway: Variant = get_world_map_position_for_scene(source, target)
		if gateway is Vector2: arrival = gateway; world_version = world_version_for_scene(target)
		var contract: Variant = layered_world_contract(destination)
		if contract != null:
			var repaired: Variant = contract.migrate_spawn(arrival, world_version, destination)
			if not repaired is Vector2: return {}
			arrival = repaired
			world_version = int(contract.VERSION)
	if LUOYANG_V3.owns_id(target):
		if not LUOYANG_V3.is_v3(destination):
			if "--luoyang-v3-candidate" in OS.get_cmdline_user_args() or int(_local_layout_versions.get(String(target), 1)) == LUOYANG_V3.VERSION: return {}
		else:
			var previous: int = 3 if not family_arrival.is_empty() else (int(_local_layout_versions.get(String(target), 1)) if remembered is Vector2 else 1)
			if LUOYANG_V3.revision_room_known(source):
				var room_return: Dictionary=LUOYANG_V3.revision_room_return(source,target,authored,remembered)
				if room_return.is_empty(): return {}
				arrival=room_return.spawn
				previous=LUOYANG_V3.VERSION
			var report: Dictionary = LUOYANG_V3.migrate_spawn_report(target, arrival, previous, source if not remembered is Vector2 and family_arrival.is_empty() else &"", _city_transition_token_for(target))
			if report.is_empty(): return {}
			arrival = report.spawn
			local_version = LUOYANG_V3.VERSION
	if not arrival.is_finite() or arrival.x < 0 or arrival.y < 0 or arrival.x > 1 or arrival.y > 1: return {}
	if AP_QUARTERS.owns_route(source,target):
		if not AP_QUARTERS.validation_finish(): return {}
	elif not family_arrival.is_empty() and not ESTATE_AM.validation_finish(): return {}
	var prepared := {"arrival": arrival, "world_version": world_version, "local_version": local_version}
	if source != &"" and source != target and source_spawn is Vector2:
		if not source_spawn.is_finite() or source_spawn.x < 0 or source_spawn.y < 0 or source_spawn.x > 1 or source_spawn.y > 1: return {}
		prepared.return_spawn = source_spawn
	return prepared


func go_field_walkable(scene_id: StringName, player_spawn: Vector2 = Vector2(0.5, 0.8)) -> void:
	if not OUTSKIRTS.biome_for(scene_id).is_empty() or LUOYANG_V3.owns_id(scene_id) or scene_id in AP_QUARTERS.IDS or scene_id==ESTATE_AM.ID:
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
	if _joint_portal_requires_prepare(_current_field_id, target_map):
		go_field_from_portal(target_map, player_spawn, _current_field_spawn)
		return
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
	if _joint_portal_requires_prepare(_current_field_id, target):
		go_field_from_portal(target, null, _current_field_spawn)
	else:
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
	_cancel_resident_return("NEW_GAME_RESET")
	_resident_city.release("NEW_GAME_RESET")
	LUOYANG_V3.clear_resident_receipt()
	_cancel_public_city_owner("NEW_GAME_RESET")
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
	_local_layout_versions.clear()
	_city_preflight_input.clear()
	_city_preflight_result.clear()


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
		"local_layout_versions": _local_layout_versions.duplicate(true),
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
	_cancel_resident_return("RESTORE_NAVIGATION_STATE")
	_resident_city.release("RESTORE_NAVIGATION_STATE")
	# Missing legacy navigation fields must use the caller's known save field,
	# not an empty preflight key that masks fallback after city preparation.
	data = data.duplicate(true)
	if (not data.has("current_field") or String(data.get("current_field", "")).is_empty()) and fallback_field != &"": data.current_field = String(fallback_field)
	var selected_world := world_map_upgrade_target if world_map_upgrade_target != &"" else WORLD_MAP_SCENE
	if not navigation_coordinate_version_supported(data, selected_world): return
	# Reuse the exact pure resolution computed before any save state writes.
	data = _city_preflight_result.duplicate(true)
	if world_map_upgrade_target == WORLD_MAP_V15_SCENE or (world_map_upgrade_target == &"" and WORLD_V15.formal_version() == 15):
		_restore_v15_navigation(data, fallback_field, WORLD_MAP_V15_SCENE if world_map_upgrade_target == WORLD_MAP_V15_SCENE else WORLD_MAP_SCENE)
		return
	if world_map_upgrade_target == WORLD_MAP_V14_SCENE or (world_map_upgrade_target == &"" and WORLD_V14.formal_version() == 14):
		_restore_v14_navigation(data, fallback_field, WORLD_MAP_V14_SCENE if world_map_upgrade_target == WORLD_MAP_V14_SCENE else WORLD_MAP_SCENE)
		return
	# The third argument is an explicit cutover switch. Existing v12 saves and
	# ordinary loads keep their original map/scope until the full v13 map ships.
	var upgrade_world := world_map_upgrade_target == WORLD_MAP_STAGING_SCENE
	_local_layout_versions = data.get("local_layout_versions", {}).duplicate(true)
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
	_city_preflight_input.clear()
	_city_preflight_result.clear()
	var source_version: int = _saved_world_coordinate_version(data)
	if source_version < 0:
		push_warning("[SceneRouter] 大地图坐标版本必须为受支持的确切整数，导航未修改。")
		return false
	var city_prepared: Dictionary = LUOYANG_V3.prepare_navigation(data, StringName(data.get("current_field", "")), _city_target_versions())
	if city_prepared.is_empty():
		push_warning("[SceneRouter] 洛阳坐标版本或资源校验失败，存档尚未应用：" + "; ".join(LUOYANG_V3.errors()))
		return false
	var local_id := StringName(data.get("current_field", ""))
	if not OUTSKIRTS.biome_for(local_id).is_empty():
		var local_scene := _load_field_scene_def(local_id)
		var saved_spawn: Variant = data.get("current_field_spawn", null)
		var local_spawn: Variant = OUTSKIRTS._v(saved_spawn) if saved_spawn != null else (local_scene.player_spawn if local_scene != null else null)
		if local_scene == null or not local_spawn is Vector2 or not local_spawn.is_finite() or local_spawn.x < 0 or local_spawn.y < 0 or local_spawn.x > 1 or local_spawn.y > 1 or not OUTSKIRTS.repair_spawn(local_scene, local_spawn) is Vector2:
			push_warning("[SceneRouter] 存档郊外资源尚未就绪，保留当前状态。")
			return false
	if source_version == 15 and world_version_for_scene(target_id) < 15:
		push_warning("[SceneRouter] 此存档使用新版大地图v15，当前地图较旧；为防止落点错乱，暂不支持降级读取。请恢复v15地图后重试。")
		return false
	_city_preflight_input = data.duplicate(true)
	_city_preflight_result = city_prepared
	return true


func _saved_world_coordinate_version(data: Dictionary, fallback: StringName = &"") -> int:
	var saved_id: StringName = _normalize_field_id(StringName(data.get("current_field", fallback)))
	var inferred: int = 15 if saved_id == WORLD_MAP_V15_SCENE else (14 if saved_id == WORLD_MAP_V14_SCENE else (13 if saved_id == WORLD_MAP_STAGING_SCENE else 12))
	var raw: Variant = data.get("world_map_version", inferred)
	# JSON decodes exact integers as float. Do not coerce strings, booleans,
	# fractions or nonfinite numbers before checking the supported identity.
	if typeof(raw) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(raw)) or float(raw) not in [12.0, 13.0, 14.0, 15.0]: return -1
	return int(raw)


func _restore_v15_navigation(data: Dictionary, fallback: StringName, target_id: StringName) -> void:
	var prepared := prepare_v15_navigation(data, fallback, target_id)
	if not prepared.is_empty(): commit_v15_navigation(prepared)


func prepare_v15_navigation(data: Dictionary, fallback: StringName, target_id: StringName) -> Dictionary:
	# Pure resolution: SaveManager calls this before applying ANY save data.
	# A failure may populate diagnostic caches, but cannot change Router state.
	var old_version: int = _saved_world_coordinate_version(data, fallback)
	if old_version < 0:
		push_warning("[SceneRouter] 不支持的大地图源坐标版本，导航未修改。")
		return {}
	var cached_local_matches: bool = data == _city_preflight_input and not _city_preflight_result.is_empty() and (data.has("current_field") or String(_city_preflight_result.get("current_field", "")) == String(fallback))
	var local_prepared: Dictionary = _city_preflight_result.duplicate(true) if cached_local_matches else LUOYANG_V3.prepare_navigation(data, fallback, _city_target_versions())
	if local_prepared.is_empty(): return {}
	data = local_prepared
	var target := _load_field_scene_def(target_id)
	if not WORLD_V15.is_v15(target):
		push_error("[SceneRouter] v15 upgrade requested before candidate publication")
		return {}
	var saved_id := _normalize_field_id(StringName(data.get("current_field", fallback)))
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
	return {"active_world_map_scene": target_id, "current_field_id": target_id if is_world_map_scene(saved_id) else saved_id, "current_field_spawn": spawn, "world_map_return_scene": StringName(data.get("world_map_return_scene", "")), "portal_return_spawns": repaired_returns, "world_map_version": 15, "local_layout_versions": local_prepared.local_layout_versions, "local_migration_trace": local_prepared.local_migration_trace}


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
	_local_layout_versions = prepared.get("local_layout_versions", {}).duplicate(true)


func _restore_v14_navigation(data: Dictionary, fallback: StringName, target_id: StringName) -> void:
	var target := _load_field_scene_def(target_id)
	if not WORLD_V14.is_v14(target):
		push_error("[SceneRouter] v14 upgrade requested before production publication")
		return
	_local_layout_versions = data.get("local_layout_versions", {}).duplicate(true)
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
	# A declared native Family may never silently become a guessed flat classic scene.
	if scene_id in AP_QUARTERS.IDS or scene_id==ESTATE_AM.ID: return ""
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
		"return_local_layout_version": int(_local_layout_versions.get(String(_current_field_id), 1)),
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
	_cancel_resident_return("SUPERSEDED_TRANSITION")
	if _resident_city.state().get("occupied",false) and context.get("field_scene_id","")!=String(_resident_city.room): _resident_city.release("LEAVING_EXCURSION")
	var own_handoff: bool=not _public_city_request.is_empty() and scene_path==SCENE_FIELD_WALKABLE and context.get("city_validation_token",0)==_public_city_request.get("token",0) and context.get("field_scene_id","")==String(_public_city_request.get("id",&""))
	if not own_handoff: _cancel_public_city_owner("SUPERSEDED_TRANSITION")
	if scene_path == SCENE_BATTLE:
		_battle_payload["return_world_map_version"] = _world_map_version
		_battle_payload["return_local_layout_version"] = int(_local_layout_versions.get(String(_battle_payload.get("return_scene", _current_field_id)), 1))
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


func field_scene_resource_path(scene_id: StringName) -> String:
	if scene_id in AP_QUARTERS.IDS: return AP_QUARTERS.scene_path(scene_id)
	if scene_id==ESTATE_AM.ID: return ESTATE_AM.scene_path(scene_id)
	var temple: Variant=load("res://scripts/city/luoyang_temple_assembly_20261016.gd")
	if temple.requested(scene_id): return temple.scene_path()
	# Flat room IDs have one exact nested path. No guessed filename, path
	# takeover, canonical alias or external path supplied by a portal.
	if LUOYANG_V3.revision_room_known(scene_id): return LUOYANG_V3.revision_room_path(scene_id)
	return "%s%s.tres" % [FIELD_SCENE_DIR,String(scene_id)]

func _load_field_scene_def(scene_id: StringName) -> SceneScript:
	var path := field_scene_resource_path(scene_id)
	if path.is_empty(): return null
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is SceneScript:
		if scene_id in AP_QUARTERS.IDS: return res if AP_QUARTERS.matches(res) else null
		if scene_id==ESTATE_AM.ID: return res if ESTATE_AM.matches(res) else null
		var temple: Variant=load("res://scripts/city/luoyang_temple_assembly_20261016.gd")
		if temple.requested(scene_id): return res if temple.is_scene(res) else null
		if LUOYANG_V3.revision_room_known(scene_id):
			return res if res.scene_id==scene_id and LUOYANG_V3.revision_room_matches(res,scene_id) else null
		if _city_transition_token_for(scene_id) > 0:
			var candidate: bool = "--luoyang-enclosure-v11-candidate" in OS.get_cmdline_user_args() and "--luoyang-v3-candidate" in OS.get_cmdline_user_args()
			if res.has_meta("city_enclosure_manifest_sha") or candidate:
				if _city_transition_live: return LUOYANG_V3.resolve_scene_from_live_transition(res, _city_transition_token)
				return LUOYANG_V3.resolve_scene_for_transition(res, _city_transition_token)
			# A rolled-back/legacy city keeps the old non-transition contract.
			end_field_transition_validation(_city_transition_token)
		return LUOYANG_V3.resolve_scene(OUTSKIRTS.materialize(res))
	return null


func _city_transition_token_for(scene_id: StringName) -> int:
	return _city_transition_token if scene_id == _city_transition_target else 0


func get_validated_field_transition(scene_id: StringName) -> Dictionary:
	var token := _city_transition_token_for(scene_id)
	if token == 0: return {}
	# The presence of this key is authoritative even on refusal. Consumers must
	# not fall back to a second full load after the scoped proof fails.
	var scene: SceneScript = LUOYANG_V3.transition_scene_live(token, scene_id) if _city_transition_live else LUOYANG_V3.transition_scene(token, scene_id)
	return {"scene":scene, "token":token}


func live_field_transition_token(scene_id: StringName) -> int:
	return _city_transition_token_for(scene_id) if _city_transition_live else 0


func finalize_field_transition_sources(scene_id: StringName, token: int) -> bool:
	if token <= 0 or live_field_transition_token(scene_id) != token: return false
	var verified: bool = await LUOYANG_V3.finalize_live_transition_sources(token, scene_id)
	return verified and _city_transition_token_for(scene_id) == token and _city_transition_live


func end_field_transition_validation(token: int) -> void:
	if token <= 0 or token != _city_transition_token: return
	LUOYANG_V3.end_transition_validation(token)
	_city_transition_token = 0
	_city_transition_live = false
	_city_transition_target = &""


func _city_target_versions() -> Dictionary:
	var result: Dictionary = {}
	for id: String in LUOYANG_V3.LEGACY_SHAS:
		var path: String = FIELD_SCENE_DIR + id + ".tres"
		var scene: SceneScript = load(path) as SceneScript if ResourceLoader.exists(path) else null
		result[id] = LUOYANG_V3.VERSION if "--luoyang-v3-candidate" in OS.get_cmdline_user_args() or LUOYANG_V3.is_v3(scene) else 1
	return result


func _grant_skill(skill_id: StringName) -> void:
	GameState.learn_skill(skill_id)


func _scene_default_spawn(scene_id: StringName) -> Vector2:
	var scene_def := _load_field_scene_def(scene_id)
	if scene_def != null:
		return scene_def.player_spawn
	return Vector2(0.5, 0.8)
