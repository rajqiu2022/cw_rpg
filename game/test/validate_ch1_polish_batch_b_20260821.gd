extends SceneTree

const STONE_QUEST := &"q_ch1_side_03_stone_inscription"
const CARAVAN_QUEST := &"q_ch1_side_06_caravan_escort"
const SIXTH_EVIDENCE := &"ev_ch1_erased_sixth_companion"

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_validate_sixth_companion_evidence()
	_validate_stone_quest()
	_validate_caravan_quest()
	_validate_runtime_completion()
	print("[Ch1PolishBatchB20260821] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[Ch1PolishBatchB20260821] %s" % failure)
	quit(1 if not failures.is_empty() else 0)


func _validate_sixth_companion_evidence() -> void:
	var evidence := load("res://data/investigation/evidence/%s.tres" % String(SIXTH_EVIDENCE)) as EvidenceDef
	_check(evidence != null, "第六名同行者证据资源存在")
	if evidence != null:
		_check(evidence.chapter == 1 and evidence.category == &"document", "证据归属第一章文书类")
		_check(evidence.description.contains("六个同行者") and evidence.description.contains("尚不能确认"), "证据只确认人数，不提前揭示身份")
	var roster := load("res://data/dialogs/ch1_s3_ruin_watch_roster.tres") as DialogScript
	var evidence_node := _dialog_node(roster, &"n4")
	_check(evidence_node != null, "废宅值守册拥有独立第六行调查节点")
	if evidence_node != null:
		_check(SIXTH_EVIDENCE in evidence_node.add_evidence, "调查值守册取得第六行证据")
		_check(_node_sets_flag(evidence_node, "ch1_sixth_companion_erased"), "调查写入持久剧情旗标")
		_check(evidence_node.accept_quest == &"q_ch1_main_west_ruin", "发现证据后再衔接赵无忌主线")


func _validate_stone_quest() -> void:
	var quest := load("res://data/quests/%s.tres" % String(STONE_QUEST)) as QuestDef
	_check(quest != null and not quest.tracker_hint.is_empty(), "残碑认字拥有无剧透地点提示")
	var south := load("res://data/scenes/linxi_village_scrollmap.tres") as SceneScript
	var teacher := _find_npc(south.npcs if south != null else [], "linxi_south_teacher")
	_check(String(teacher.get("dialog_id", "")) == "ch1_side_stone_teacher_offer", "村塾先生提供残碑委托")
	_check(_has_dialog_variant(teacher, "ch1_side_stone_teacher_waiting", "require_quest_active", String(STONE_QUEST)), "残碑任务拥有进行中复访")
	_check(_has_dialog_variant(teacher, "ch1_side_stone_teacher_done", "require_quest_completed", String(STONE_QUEST)), "残碑任务拥有完成后对白")
	var road := load("res://data/scenes/ch1_s1_road.tres") as SceneScript
	var rubbing := _find_entry(road.map_layout.interactions if road != null and road.map_layout != null else [], "road_stone_rubbing")
	_check(String(rubbing.get("require_quest_active", "")) == String(STONE_QUEST), "接取任务后山道才显示拓碑交互")
	_check(String(rubbing.get("action", "")) == "dialog:ch1_side_stone_rubbing", "拓碑交互连接正式对白")
	var turnin := load("res://data/dialogs/ch1_side_stone_teacher_turnin.tres") as DialogScript
	_check(_dialog_sets_flag(turnin, "stone_inscription_deciphered"), "先生解读拓本后完成残碑任务")


func _validate_caravan_quest() -> void:
	var quest := load("res://data/quests/%s.tres" % String(CARAVAN_QUEST)) as QuestDef
	_check(quest != null and not quest.tracker_hint.is_empty(), "古道护商拥有无剧透地点提示")
	var village := load("res://data/scenes/ch1_s2_qingfeng.tres") as SceneScript
	var escort := _find_npc(village.npcs if village != null else [], "patrol_scout_partner")
	_check(_has_dialog_variant(escort, "ch1_side_caravan_offer", "require_flags", "zhuwei_village_inquiry_done"), "完成村内调查后镖师提供护商委托")
	_check(_has_dialog_variant(escort, "ch1_side_caravan_waiting", "require_quest_active", String(CARAVAN_QUEST)), "护商任务拥有进行中复访")
	_check(_has_dialog_variant(escort, "ch1_side_caravan_done", "require_quest_completed", String(CARAVAN_QUEST)), "护商任务拥有完成后对白")
	var road := load("res://data/scenes/ch1_s1_road.tres") as SceneScript
	var caravan := _find_npc(road.npcs if road != null else [], "ch1_caravan_master_fan")
	_check(String(caravan.get("require_quest_active", "")) == String(CARAVAN_QUEST), "接取任务后古道才生成范掌柜")
	_check(String(caravan.get("hide_flag", "")) == "caravan_escort_done", "护送完成后商队离开古道")
	var start := load("res://data/dialogs/ch1_side_caravan_road_start.tres") as DialogScript
	var fight := _dialog_node(start, &"fight")
	_check(fight != null and fight.on_end == "battle_group_then:bandit_mountain,bandit_mountain:ch1_side_caravan_victory", "护商使用两人队伍战并连接胜利对白")
	var victory := load("res://data/dialogs/ch1_side_caravan_victory.tres") as DialogScript
	_check(_dialog_sets_flag(victory, "caravan_escort_done"), "胜利对白结算护商任务")
	var router_source := FileAccess.get_file_as_string("res://scripts/autoload/scene_router.gd")
	_check(router_source.contains('"battle_group_then"') and router_source.contains("victory_action"), "SceneRouter支持队伍战胜利后续对白")
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	var npc_spawn_start := field_source.find("func _spawn_npcs")
	var npc_spawn_end := field_source.find("\nfunc ", npc_spawn_start + 1)
	var npc_spawn_body := field_source.substr(npc_spawn_start, npc_spawn_end - npc_spawn_start)
	_check(npc_spawn_body.contains("_quest_gate_passes(d)"), "任务阶段NPC生成时执行统一任务门禁")


func _validate_runtime_completion() -> void:
	var quest_manager := root.get_node_or_null("QuestManager")
	var game_state := root.get_node_or_null("GameState")
	_check(quest_manager != null and game_state != null, "任务与状态Autoload可用于运行回归")
	if quest_manager == null or game_state == null:
		return
	quest_manager.call("reset_for_new_game")
	_check(bool(quest_manager.call("accept", STONE_QUEST)), "运行时可接取残碑认字")
	game_state.call("set_flag", &"stone_inscription_deciphered", true)
	_check(bool(quest_manager.call("is_completed", STONE_QUEST)), "解读旗标会结算残碑认字")
	var gold_after_stone := int(game_state.get("gold"))
	game_state.call("set_flag", &"stone_inscription_deciphered", true)
	_check(int(game_state.get("gold")) == gold_after_stone, "重复旗标不会重复发放残碑奖励")

	quest_manager.call("reset_for_new_game")
	_check(bool(quest_manager.call("accept", CARAVAN_QUEST)), "运行时可接取古道护商")
	game_state.call("set_flag", &"caravan_escort_done", true)
	_check(bool(quest_manager.call("is_completed", CARAVAN_QUEST)), "护送胜利旗标会结算古道护商")
	var gold_after_caravan := int(game_state.get("gold"))
	game_state.call("set_flag", &"caravan_escort_done", true)
	_check(int(game_state.get("gold")) == gold_after_caravan, "重复旗标不会重复发放护商奖励")


func _find_npc(entries: Array, npc_id: String) -> Dictionary:
	for raw_entry: Variant in entries:
		if raw_entry is Dictionary and String((raw_entry as Dictionary).get("npc_id", "")) == npc_id:
			return raw_entry as Dictionary
	return {}


func _find_entry(entries: Array, entry_id: String) -> Dictionary:
	for raw_entry: Variant in entries:
		if raw_entry is Dictionary and String((raw_entry as Dictionary).get("id", "")) == entry_id:
			return raw_entry as Dictionary
	return {}


func _has_dialog_variant(npc: Dictionary, dialog_id: String, key: String, value: String) -> bool:
	for raw_variant: Variant in npc.get("dialog_variants", []):
		if not raw_variant is Dictionary:
			continue
		var variant := raw_variant as Dictionary
		if String(variant.get("dialog_id", "")) != dialog_id:
			continue
		var actual: Variant = variant.get(key, "")
		if actual is Array:
			return value in actual
		return String(actual) == value
	return false


func _dialog_node(dialog: DialogScript, node_id: StringName) -> DialogNode:
	if dialog == null:
		return null
	for node: DialogNode in dialog.nodes:
		if node != null and node.node_id == node_id:
			return node
	return null


func _dialog_sets_flag(dialog: DialogScript, flag_key: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node != null and _node_sets_flag(node, flag_key):
			return true
	return false


func _node_sets_flag(node: DialogNode, flag_key: String) -> bool:
	for entry: Dictionary in node.set_flags:
		if String(entry.get("key", "")) == flag_key and bool(entry.get("value", true)):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
