extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_check_resource_contracts()
	await _check_runtime_rewards()
	print("[MainlineProgressionRewards20260824] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_resource_contracts() -> void:
	var ch2_main := load("res://data/quests/q_ch2_main_04_report_lingyue.tres") as QuestDef
	var ch2_rescue := load("res://data/quests/q_ch2_main_02_rescue_yue.tres") as QuestDef
	var ch2_side := load("res://data/quests/q_ch2_side_04_herb_thief.tres") as QuestDef
	var ch4_main := load("res://data/quests/q_ch4_main_04_tunnel_mastermind.tres") as QuestDef
	var ch4_side := load("res://data/quests/q_ch4_side_06_canal_grudge.tres") as QuestDef
	_check(ch2_main != null and &"zhuwei_bamboo_guard_art" in ch2_main.reward_skills, "chapter two report guarantees Bamboo Vitality Art")
	_check(ch2_rescue != null and _quest_has_item(ch2_rescue, &"zhuwei_bamboo_sleeve_crossbow"), "chapter two rescue guarantees a hidden weapon")
	_check(ch2_rescue != null and &"bamboo_rain_piercing_shot" in ch2_rescue.reward_skills, "chapter two rescue guarantees a non-sword attack art")
	_check(ch2_side != null and &"zhuwei_bamboo_guard_art" not in ch2_side.reward_skills, "herb-thief side quest no longer duplicates the main internal art")
	_check(ch4_main != null and _quest_has_item(ch4_main, &"luoshui_canal_staff"), "chapter four finale guarantees Luoshui Canal-Guarding Staff")
	_check(ch4_main != null and &"rolling_cloud_staff_storm" in ch4_main.reward_skills, "chapter four finale guarantees a non-sword attack art")
	_check(ch4_side != null and &"rolling_cloud_staff_storm" not in ch4_side.reward_skills, "canal side quest keeps its fist-gauntlet identity without a staff-art mismatch")
	var staff := load("res://data/equipment/luoshui_canal_staff.tres") as Equipment
	_check(staff != null, "Luoshui staff resource loads")
	if staff != null:
		_check(staff.quality == Item.Quality.RARE and staff.weapon_type == &"staff", "Luoshui staff is a blue staff weapon")
		_check(staff.atk_bonus == 30 and staff.weapon_skill_bonus_scaling == 10, "Luoshui staff fits the chapter-four blue weapon budget")
		_check(staff.special_effect_type == &"weaken" and is_equal_approx(staff.special_effect_chance, 0.20) and staff.special_effect_duration == 2, "Luoshui staff proc obeys the blue quality cap")
		_check(FileAccess.file_exists(staff.icon_path), "Luoshui staff owns a project-local icon")
	var staff_art := load("res://data/skills/rolling_cloud_staff_storm.tres") as Skill
	_check(staff_art != null and staff_art.animation_id == staff_art.skill_id, "Rolling Cloud Staff Formation owns its dedicated VFX id")
	_check(staff_art != null and BattleVfxPlayer.has_effect(staff_art.animation_id), "Rolling Cloud Staff Formation VFX is registered")
	if staff_art != null:
		var effect_path := String(BattleVfxPlayer.get_effect_config(staff_art.animation_id).get("sheet", ""))
		_check(not effect_path.is_empty() and FileAccess.file_exists(effect_path), "Rolling Cloud Staff Formation owns a project-local four-frame VFX")
	var bamboo_art := load("res://data/skills/zhuwei_bamboo_guard_art.tres") as Skill
	_check(bamboo_art != null and bamboo_art.animation_id == bamboo_art.skill_id, "Bamboo Vitality Art owns its dedicated VFX id")
	_check(bamboo_art != null and BattleVfxPlayer.has_effect(bamboo_art.animation_id), "Bamboo Vitality Art VFX is registered")
	if bamboo_art != null:
		var bamboo_effect := BattleVfxPlayer.get_effect_config(bamboo_art.animation_id)
		var bamboo_effect_path := String(bamboo_effect.get("sheet", ""))
		_check(String(bamboo_effect.get("delivery", "")) == "self", "Bamboo Vitality Art is registered as a self-cast effect")
		_check(not bamboo_effect_path.is_empty() and FileAccess.file_exists(bamboo_effect_path), "Bamboo Vitality Art owns a project-local four-frame VFX")
	var hidden_weapon := load("res://data/equipment/zhuwei_bamboo_sleeve_crossbow.tres") as Equipment
	_check(hidden_weapon != null, "Zhuwei bamboo sleeve crossbow resource loads")
	if hidden_weapon != null:
		_check(hidden_weapon.quality == Item.Quality.RARE and hidden_weapon.weapon_type == &"hidden", "Zhuwei sleeve crossbow is a blue hidden weapon")
		_check(hidden_weapon.atk_bonus == 22 and hidden_weapon.weapon_skill_bonus_scaling == 10, "Zhuwei sleeve crossbow fits the chapter-two blue weapon budget")
		_check(hidden_weapon.crit_chance_bonus == 0.0 and hidden_weapon.hit_chance_bonus == 0.0 and hidden_weapon.special_effect_type == &"poison", "Zhuwei sleeve crossbow keeps a focused poison-utility identity")
		_check(FileAccess.file_exists(hidden_weapon.icon_path), "Zhuwei sleeve crossbow owns a project-local icon")
	var hidden_art := load("res://data/skills/bamboo_rain_piercing_shot.tres") as Skill
	_check(hidden_art != null and hidden_art.required_weapon_type == &"hidden" and hidden_art.martial_category == &"hidden", "Bamboo Rain Piercing Shot requires hidden weapons")
	_check(hidden_art != null and hidden_art.quality == Skill.Quality.RARE and hidden_art.base_hit_chance == 0.96, "Bamboo Rain Piercing Shot fits the chapter-two blue skill budget")
	_check(hidden_art != null and hidden_art.animation_id == hidden_art.skill_id and BattleVfxPlayer.has_effect(hidden_art.animation_id), "Bamboo Rain Piercing Shot owns a registered dedicated VFX")
	if hidden_art != null:
		var hidden_effect_path := String(BattleVfxPlayer.get_effect_config(hidden_art.animation_id).get("sheet", ""))
		_check(not hidden_effect_path.is_empty() and FileAccess.file_exists(hidden_effect_path), "Bamboo Rain Piercing Shot owns a project-local four-frame VFX")


func _check_runtime_rewards() -> void:
	var game_state := root.get_node("GameState")
	var inventory := root.get_node("Inventory")
	var quest_manager := root.get_node("QuestManager")
	game_state.call("reset_for_new_game")
	inventory.call("reset_for_new_game")
	quest_manager.call("reset_for_new_game")
	_check(bool(quest_manager.call("accept", &"q_ch2_main_02_rescue_yue")), "chapter two rescue quest can be accepted")
	game_state.call("set_flag", &"ch2_rescue_complete", true)
	await process_frame
	_check(bool(quest_manager.call("is_completed", &"q_ch2_main_02_rescue_yue")), "chapter two rescue quest completes")
	_check(int(inventory.call("count_of", &"zhuwei_bamboo_sleeve_crossbow")) == 1, "chapter two rescue grants one hidden weapon")
	var hidden_learned: bool = &"bamboo_rain_piercing_shot" in game_state.get("player").skills
	var hidden_pending: bool = &"bamboo_rain_piercing_shot" in game_state.get("pending_skill_unlocks")
	_check(hidden_learned or hidden_pending, "chapter two rescue learns or queues Bamboo Rain Piercing Shot")
	_check(bool(quest_manager.call("accept", &"q_ch2_main_04_report_lingyue")), "chapter two report quest can be accepted")
	game_state.call("set_flag", &"chapter2_complete", true)
	await process_frame
	_check(bool(quest_manager.call("is_completed", &"q_ch2_main_04_report_lingyue")), "chapter two report quest completes")
	_check(&"zhuwei_bamboo_guard_art" in game_state.get("player").skills, "chapter two main reward teaches Bamboo Vitality Art")

	_check(bool(quest_manager.call("accept", &"q_ch4_main_04_tunnel_mastermind")), "chapter four finale quest can be accepted")
	game_state.call("set_flag", &"chapter4_complete", true)
	await process_frame
	_check(bool(quest_manager.call("is_completed", &"q_ch4_main_04_tunnel_mastermind")), "chapter four finale quest completes")
	_check(int(inventory.call("count_of", &"luoshui_canal_staff")) == 1, "chapter four main reward grants one Luoshui staff")
	var learned: bool = &"rolling_cloud_staff_storm" in game_state.get("player").skills
	var pending: bool = &"rolling_cloud_staff_storm" in game_state.get("pending_skill_unlocks")
	_check(learned or pending, "chapter four main reward learns or queues Rolling Cloud Staff Formation")


func _quest_has_item(quest: QuestDef, item_id: StringName) -> bool:
	for entry: Dictionary in quest.reward_items:
		if StringName(String(entry.get("id", entry.get("item_id", "")))) == item_id:
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
