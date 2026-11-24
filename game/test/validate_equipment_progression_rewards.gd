extends SceneTree

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var game_state: Node = root.get_node("GameState")
	var inventory: Node = root.get_node("Inventory")
	var quest_manager: Node = root.get_node("QuestManager")
	game_state.call("reset_for_new_game")
	inventory.call("reset_for_new_game")
	quest_manager.call("reset_for_new_game")

	_expect(bool(quest_manager.call("accept", &"q_ch4_side_06_canal_grudge")), "canal quest cannot be accepted")
	game_state.call("set_flag", &"canal_feud_resolved", true)
	await process_frame
	_expect(bool(quest_manager.call("is_completed", &"q_ch4_side_06_canal_grudge")), "canal quest did not complete")
	_expect(int(inventory.call("count_of", &"xuantong_fist_gauntlets")) == 1, "purple fist gauntlets were not granted exactly once")

	_expect(bool(quest_manager.call("accept", &"q_ch5_side_03_ancient_tomb_trap")), "ancient tomb quest cannot be accepted")
	game_state.call("set_flag", &"ancient_tomb_cleared", true)
	await process_frame
	_expect(bool(quest_manager.call("is_completed", &"q_ch5_side_03_ancient_tomb_trap")), "ancient tomb quest did not complete")
	_expect(int(inventory.call("count_of", &"zhouju_bronze_sword")) == 1, "orange sword was not granted exactly once")

	var gauntlets := inventory.call("load_item_by_id", &"xuantong_fist_gauntlets") as Equipment
	var sword := inventory.call("load_item_by_id", &"zhouju_bronze_sword") as Equipment
	_expect(gauntlets != null and gauntlets.quality == 3 and gauntlets.slot == Equipment.Slot.WEAPON and gauntlets.weapon_type == &"palm",
		"purple palm weapon runtime contract failed")
	_expect(sword != null and sword.quality == 4 and sword.slot == Equipment.Slot.WEAPON and sword.weapon_type == &"sword", "orange sword runtime contract failed")

	# 后期绝学只发给对应门派，并继续经过悟性门槛；不允许串学。
	game_state.call("select_faction", &"gufeng")
	_expect(bool(quest_manager.call("accept", &"q_ch5_side_02_cliff_immortal_herb")), "cliff herb quest cannot be accepted")
	game_state.call("set_flag", &"cliff_immortal_herb_collected", true)
	await process_frame
	_expect(bool(quest_manager.call("is_completed", &"q_ch5_side_02_cliff_immortal_herb")), "cliff herb quest did not complete")
	var learned: bool = &"gufeng_liedi" in game_state.get("player").skills
	var pending: bool = &"gufeng_liedi" in game_state.get("pending_skill_unlocks")
	_expect(learned or pending, "Gufeng ultimate was neither learned nor queued by its faction quest")
	_expect(&"wudang_taiji_liangyi" not in game_state.get("player").skills,
		"completing a Gufeng quest must not grant another faction's ultimate")

	print("[EquipmentProgressionRewards] failed=%d" % _failures.size())
	for failure: String in _failures:
		push_error("[EquipmentProgressionRewards] %s" % failure)
	quit(1 if not _failures.is_empty() else 0)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
