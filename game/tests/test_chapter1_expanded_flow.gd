extends SceneTree

var _failures: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_road_progression()
	_test_road_walkable_corridor()
	_test_single_enemy_battle_runtime_regression()
	_test_battle_action_commit_contract()
	_test_linxi_village_route()
	_test_training_gate()
	_test_skill_delivery_modes()
	_test_leveling_content()
	_test_zhuwei_wilds_expansion()
	_test_final_boss_and_resolution()
	if _failures > 0:
		push_error("[Chapter 1 Expanded Flow] %d failure(s)" % _failures)
	quit(_failures)


func _test_road_progression() -> void:
	var road: SceneScript = _load_scene(&"ch1_s1_road")
	_expect(road != null, "mountain road scene loads")
	if road == null or road.map_layout == null:
		return
	_expect(
		_dialog_has_action(_load_dialog(&"ch1_road_corpse"), "battle_then:thug_lone:ch1_road_after_battle"),
		"road queues the post-battle clue dialog after the ambush victory"
	)
	_expect(
		_has_entry(road.map_layout.portals, "action", "dialog:ch1_road_exit_locked", "hide_flag", "defeated_thug_lone"),
		"uninvestigated road exit reminds the player instead of starting corpse investigation"
	)
	_expect(
		_has_entry(road.map_layout.portals, "target_scene", "linxi_village_center"),
		"road keeps an unrestricted return route to Linxi village center"
	)
	_expect(
		_has_entry(road.map_layout.portals, "action", "dialog:ch1_road_to_zhuwei", "require_flag", "master_training_done"),
		"Zhuwei route requires completed master training"
	)


func _test_road_walkable_corridor() -> void:
	var road: SceneScript = _load_scene(&"ch1_s1_road")
	_expect(road != null and road.map_layout != null, "mountain road walkability data loads")
	if road == null or road.map_layout == null:
		return
	var route: Array[Vector2] = [
		Vector2(0.34, 0.56),
		Vector2(0.36, 0.50),
		Vector2(0.40, 0.46),
		Vector2(0.45, 0.42),
		Vector2(0.50, 0.40),
		Vector2(0.55, 0.41),
		Vector2(0.59, 0.47),
		Vector2(0.62, 0.53),
		Vector2(0.66, 0.60),
	]
	for index: int in range(route.size()):
		_expect(
			_layout_point_walkable(road.map_layout, route[index]),
			"mountain road center corridor sample %d stays walkable" % (index + 1)
		)


func _test_single_enemy_battle_runtime_regression() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	var setup_start: int = source.find("func _setup_team_formation")
	var next_function: int = source.find("func _build_player_party_payload", setup_start)
	var setup_body: String = source.substr(setup_start, next_function - setup_start)
	_expect(
		setup_body.contains("_setup_team_runtime(enemy_ids, _team_player_party_payload)"),
		"1v1 formation initializes combatants instead of resolving as an empty battle"
	)


func _test_battle_action_commit_contract() -> void:
	var source: String = FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	var team_finish_body := _function_body(source, "func _team_finish_player_action", "func _team_living_enemies")
	var defend_body := _function_body(source, "func _player_action_defend", "func _team_player_action_defend")
	var team_defend_body := _function_body(source, "func _team_player_action_defend", "func _player_action_flee")
	var inventory_body := _function_body(source, "func _on_battle_inventory_action", "func _on_equip_selected")
	_expect(team_finish_body.contains("if _team_all_dead(_team_enemies):"), "enemy defeat is checked before remaining action points")
	_expect(team_finish_body.contains("_team_finish(true)"), "a lethal action ends the battle immediately")
	_expect(defend_body.contains("_post_action(true)"), "defend consumes the rest of the current turn")
	_expect(not defend_body.contains("extra_action"), "defend no longer grants an extra action")
	_expect(team_defend_body.contains("_team_finish_player_action(true)"), "formation defend consumes the current character action")
	_expect(not team_defend_body.contains("extra_action"), "formation defend no longer grants an extra action")
	_expect(inventory_body.contains("_team_finish_player_action(true)"), "battle inventory commits the formation character action")
	_expect(inventory_body.contains("_post_action(true)"), "battle inventory commits the legacy character action")


func _test_linxi_village_route() -> void:
	var center: SceneScript = _load_scene(&"linxi_village_center")
	_expect(center != null and center.map_layout != null, "Linxi village center scene and walkable layout load")
	if center != null and center.map_layout != null:
		_expect(center.background_path.ends_with("bg_linxi_village_center_25d_v2_three_routes.png"), "Linxi center uses the approved three-route 2.5D background")
		_expect(_has_entry(center.map_layout.portals, "target_scene", "linxi_tutorial"), "Linxi center connects to the master courtyard")
		_expect(_has_entry(center.map_layout.portals, "target_scene", "ch1_s1_road", "require_flag", "got_sword"), "Linxi center connects to the mountain road after receiving the sword")
		_expect(not _has_entry(center.map_layout.portals, "action", "shop:linxi_apothecary"), "Linxi center pharmacy no longer uses a misleading entrance arrow")
		_expect(_has_entry(center.map_layout.portals, "target_scene", "linxi_farmer_cottage"), "Linxi center opens the farmer cottage")
		_expect(_has_entry(center.map_layout.portals, "target_scene", "linxi_herbal_home"), "Linxi center opens the herbal home")
		_expect(_has_entry(center.map_layout.portals, "target_scene", "linxi_scholar_house"), "Linxi center opens the scholar house")
		_expect(center.npcs.size() >= 4, "Linxi center has a lived-in village cast")
	var herbalist: DialogScript = _load_dialog(&"linxi_center_herbalist")
	_expect(_dialog_has_choice_text(herbalist, "购买"), "herbalist explicitly offers medicine purchase")
	_expect(_dialog_has_choice_text(herbalist, "不用了"), "herbalist supports declining the shop")
	_expect(_dialog_has_action(herbalist, "shop:linxi_apothecary"), "medicine shop opens from the herbalist dialog")
	_expect(ResourceLoader.exists("res://data/scenes/linxi_farmer_cottage.tres"), "farmer cottage scene exists")
	_expect(ResourceLoader.exists("res://data/scenes/linxi_herbal_home.tres"), "herbal home scene exists")
	_expect(ResourceLoader.exists("res://data/scenes/linxi_scholar_house.tres"), "scholar house scene exists")
	_expect(ResourceLoader.exists("res://data/quests/q_ch1_side_11_old_ledger.tres"), "scholar clue side quest exists")
	var tutorial: SceneScript = _load_scene(&"linxi_tutorial")
	_expect(tutorial != null and tutorial.map_layout != null, "master courtyard scene loads")
	if tutorial != null and tutorial.map_layout != null:
		_expect(_has_entry(tutorial.map_layout.portals, "target_scene", "linxi_village_center"), "master courtyard exits into Linxi center")
		_expect(_has_npc_state(tutorial.npcs, "xingfantian_after_farewell", "master_farewell_done", "defeated_thug_lone"), "master idle state hides as soon as the road ambush is defeated")
		_expect(_has_npc_state(tutorial.npcs, "xingfantian_return", "defeated_thug_lone", "master_training_done"), "returning master state exclusively triggers the debrief")
		_expect(_has_npc_state(tutorial.npcs, "xingfantian_after_training", "master_training_done", "ch8_linxi_final_return_open"), "master remains available after the debrief until the final Linxi return opens")
func _test_training_gate() -> void:
	var training: DialogScript = _load_dialog(&"ch1_return_to_master")
	_expect(training != null, "return-to-master dialog loads")
	if training != null:
		_expect(training.find_node_by_id(&"n11") != null, "training dialog contains its final node")
		_expect(_dialog_sets_flag(training, "learned_sword_two"), "training dialog grants Linxi Sword Form Two")
		_expect(_dialog_learns_skill(training, &"linxi_basic_sword_two"), "training dialog adds Linxi Sword Form Two to the learned skill list")
		_expect(_dialog_learns_skill(training, &"linxi_inner_breath"), "training dialog adds the Linxi breathing method to the learned skill list")
		_expect(_dialog_sets_flag(training, "master_training_done"), "training dialog unlocks the chapter route")
		var completion_node: DialogNode = training.find_node_by_id(&"n10")
		_expect(
			completion_node != null and &"linxi_basic_sword_two" in completion_node.learn_skills,
			"training completion immediately guarantees Linxi Sword Form Two"
		)
	_expect(ResourceLoader.exists("res://data/skills/linxi_basic_sword_two.tres"), "Linxi Sword Form Two skill resource exists")
	var travel: DialogScript = _load_dialog(&"ch1_road_to_zhuwei")
	_expect(travel != null, "post-training Zhuwei travel dialog loads")
	_expect(_dialog_accepts_quest(travel, &"q_ch1_main_zhuwei"), "travel dialog starts the Zhuwei investigation")
	var village: SceneScript = _load_scene(&"ch1_s2_qingfeng")
	_expect(village != null and village.on_enter_dialog != null, "Zhuwei arrival dialog is mounted on the playable scene")
	_expect(village != null and village.player_spawn == Vector2(0.24, 0.72), "Zhuwei uses the authored lower-left arrival point")


func _test_skill_delivery_modes() -> void:
	var projectile: Skill = load("res://data/skills/lingyue_lingbo_yizhi.tres") as Skill
	var area: Skill = load("res://data/skills/lingyue_hanshuang_wan_zhen.tres") as Skill
	_expect(
		projectile != null and projectile.delivery == Skill.Delivery.PROJECTILE,
		"Lingbo Finger casts from formation"
	)
	_expect(
		area != null
		and area.delivery == Skill.Delivery.STATIONARY_AOE
		and area.target == Skill.Target.ENEMY_ALL,
		"Frost formation is a stationary multi-target attack"
	)


func _test_leveling_content() -> void:
	var road: SceneScript = _load_scene(&"ch1_s1_road")
	_expect(road.encounter_enemy_ids.has(&"bandit_mountain"), "mountain road has repeatable bandit encounters")
	_expect(road.encounter_step_distance > 0.0 and road.encounter_chance > 0.0, "road encounters use distance and chance")
	_expect(road.encounter_require_flag == &"master_training_done", "road encounters stay disabled until combat training is complete")
	_expect(ResourceLoader.exists("res://data/scenes/interior_martial_hall.tres"), "martial hall training scene exists")
	_expect(ResourceLoader.exists("res://data/scenes/interior_bandit_cave.tres"), "bandit cave training scene exists")
	var cave: SceneScript = _load_scene(&"interior_bandit_cave")
	_expect(cave != null and cave.map_layout != null, "bandit cave map loads")
	if cave != null and cave.map_layout != null:
		_expect(
			_has_entry(cave.map_layout.interactions, "action", "battle:bandit_mountain"),
			"bandit cave supports repeatable clearing battles"
		)
	_expect(ResourceLoader.exists("res://data/quests/q_ch1_side_10_bandit_cave.tres"), "bandit cave side quest exists")


func _test_zhuwei_wilds_expansion() -> void:
	var arrival := _load_dialog(&"ch1_s2_intro")
	_expect(_dialog_accepts_quest(arrival, &"q_ch1_main_village_inquiry"), "Zhuwei arrival starts the village inquiry")
	_expect(not _dialog_accepts_quest(arrival, &"q_ch1_main_west_ruin"), "Zhuwei arrival no longer skips directly to the final ruin quest")
	_expect(ResourceLoader.exists("res://data/quests/q_ch1_main_village_inquiry.tres"), "village inquiry main quest exists")
	_expect(ResourceLoader.exists("res://data/quests/q_ch1_main_zhuwei_wilds.tres"), "forest and cave main quest exists")
	_expect(ResourceLoader.exists("res://data/quests/q_ch1_main_west_ruin_trace.tres"), "west ruin investigation main quest exists")
	_expect(ResourceLoader.exists("res://data/quests/q_ch1_side_12_forest_medicine.tres"), "forest medicine side quest exists")
	var guard_report := _load_dialog(&"ch1_s2_guard_report")
	_expect(_dialog_sets_flag(guard_report, "zhuwei_village_inquiry_done"), "guard report completes the three-person inquiry")
	_expect(_dialog_accepts_quest(guard_report, &"q_ch1_main_zhuwei_wilds"), "guard report starts the forest main quest")
	var village := _load_scene(&"ch1_s2_qingfeng")
	_expect(village != null and village.map_layout != null, "Zhuwei village map loads for expansion checks")
	if village != null and village.map_layout != null:
		_expect(_has_entry(village.map_layout.portals, "target_scene", "ch1_s3_zhuwei_forest", "require_flag", "zhuwei_village_inquiry_done"), "village inquiry unlocks the forest route")
		_expect(_has_entry(village.map_layout.portals, "target_scene", "ch1_s3_west_ruin", "require_flag", "clue_west_ruin_supply_route"), "west ruin stays locked until the cave clue")
	var forest := _load_scene(&"ch1_s3_zhuwei_forest")
	_expect(forest != null and forest.map_layout != null, "Zhuwei forest scene and layout load")
	if forest != null and forest.map_layout != null:
		_expect(forest.on_enter_dialog != null, "forest entrance establishes the new beast-trail story")
		_expect(forest.encounter_enemy_ids.has(&"linxi_wild_beast"), "forest has repeatable beast encounters for leveling")
		_expect(_has_entry(forest.map_layout.interactions, "action", "battle:linxi_wild_beast"), "forest contains the mandatory beast encounter")
		_expect(_has_entry(forest.map_layout.portals, "target_scene", "ch1_s4_zhuwei_beast_cave", "require_flag", "defeated_linxi_wild_beast"), "defeating the forest beast unlocks the cave")
	var cave := _load_scene(&"ch1_s4_zhuwei_beast_cave")
	_expect(cave != null and cave.map_layout != null, "new rear-mountain cave scene and layout load")
	if cave != null and cave.map_layout != null:
		_expect(_has_entry(cave.map_layout.portals, "target_scene", "ch1_s4_cave_mine_gallery"), "cave entrance opens the left mine-gallery route")
		_expect(_has_entry(cave.map_layout.portals, "target_scene", "ch1_s4_cave_waterway"), "cave entrance opens the right waterway route")
		_expect(_has_entry(cave.map_layout.portals, "target_scene", "ch1_s3_zhuwei_forest"), "cave has a return route to the forest")
	var deep_den := _load_scene(&"ch1_s4_cave_deep_den")
	_expect(deep_den != null and deep_den.map_layout != null, "both cave branches converge on the deep den")
	if deep_den != null and deep_den.map_layout != null:
		_expect(_has_entry(deep_den.map_layout.interactions, "action", "dialog:ch1_zhuwei_cave_wolf_encounter"), "deep den contains the mandatory alpha-wolf battle interaction")
		_expect(_has_entry(deep_den.map_layout.interactions, "action", "dialog:ch1_zhuwei_cave_clue", "require_flag", "defeated_zhuwei_cave_wolf"), "deep-den evidence is gated by the alpha wolf")
	var cave_clue := _load_dialog(&"ch1_zhuwei_cave_clue")
	_expect(_dialog_sets_flag(cave_clue, "clue_west_ruin_supply_route"), "cave clue unlocks the west ruin route")
	_expect(_dialog_accepts_quest(cave_clue, &"q_ch1_main_west_ruin_trace"), "cave clue starts the west ruin investigation stage")
	_expect(not _dialog_accepts_quest(cave_clue, &"q_ch1_main_west_ruin"), "cave clue does not skip directly to Zhao Wuji")
	var ruin := _load_scene(&"ch1_s3_west_ruin")
	_expect(ruin != null and ruin.map_layout != null, "west ruin map loads for boss-route checks")
	if ruin != null and ruin.map_layout != null:
		_expect(ruin.on_enter_dialog != null, "west ruin entrance explains why the player is there")
		_expect(_has_entry(ruin.map_layout.interactions, "action", "dialog:ch1_s3_ruin_shipping_marks", "require_flag", "defeated_zhuwei_bandit"), "outer guard victory unlocks the shipping evidence")
		_expect(_has_entry(ruin.map_layout.interactions, "action", "dialog:ch1_s3_ruin_watch_roster", "require_flag", "ruin_shipping_marks_found"), "shipping evidence leads to Zhao Wuji's roster")
		_expect(_has_entry(ruin.map_layout.portals, "target_scene", "ch1_s3_ruin_inner", "require_flag", "zhao_wuji_identified"), "boss inner hall opens only after Zhao Wuji is identified")
		_expect(not _has_entry(ruin.map_layout.portals, "min_level", 4), "boss inner hall does not impose a hard level gate")
	var shipping_marks := _load_dialog(&"ch1_s3_ruin_shipping_marks")
	_expect(_dialog_sets_flag(shipping_marks, "ruin_shipping_marks_found"), "shipping evidence advances the ruin investigation")
	var watch_roster := _load_dialog(&"ch1_s3_ruin_watch_roster")
	_expect(_dialog_sets_flag(watch_roster, "zhao_wuji_identified"), "watch roster identifies Zhao Wuji before the confrontation")
	_expect(_dialog_accepts_quest(watch_roster, &"q_ch1_main_west_ruin"), "identifying Zhao Wuji starts the confrontation stage")


func _test_final_boss_and_resolution() -> void:
	var boss_text: String = FileAccess.get_file_as_string("res://data/enemies/boss_zhao_wuji.tres")
	_expect(not boss_text.is_empty(), "Zhao Wuji boss definition loads")
	_expect(
		boss_text.contains("level = 6") and boss_text.contains("max_hp = 320") and boss_text.contains("attack = 38"),
		"chapter boss uses strengthened combat stats"
	)
	_expect(boss_text.contains("is_chapter_boss = true"), "Zhao Wuji remains marked as chapter boss")
	var inner: SceneScript = _load_scene(&"ch1_s3_ruin_inner")
	_expect(inner != null, "west ruin inner scene loads")
	if inner != null:
		_expect(_has_npc_gate(inner.npcs, "zhao_wuji", "master_training_done"), "boss battle requires master training")
	var finale: DialogScript = _load_dialog(&"ch1_s3_ruin_after_boss")
	_expect(finale != null, "chapter finale dialog loads")
	_expect(_dialog_has_action(finale, "field_cutscene:zhao_wounded_escape"), "boss dialog hands off to the wounded-escape field cutscene")
	_expect(not _dialog_contains_text(finale, "倒下后"), "finale no longer describes Zhao Wuji as a slain boss")
	var orders: DialogScript = _load_dialog(&"ch1_s3_ruin_orders")
	_expect(_dialog_sets_flag(orders, "chapter1_complete"), "inspecting Zhao's orders marks chapter one complete")
	_expect(_dialog_sets_flag(orders, "chapter2_river_lead"), "orders carry the investigation forward to the chapter-two river lead")
	_expect(_dialog_has_action(orders, "chapter_end:1"), "orders enter automatic chapter settlement")
	if inner != null and inner.map_layout != null:
		_expect(
			_has_entry(inner.map_layout.interactions, "action", "dialog:ch1_s3_ruin_orders", "require_flag", "zhao_wuji_wounded_escape"),
			"boss orders appear only after Zhao Wuji's escape cutscene"
		)
		_expect(_has_entry(inner.map_layout.portals, "target_scene", "ch1_s3_west_ruin"), "inner hall always keeps its physical return route")
		_expect(_has_entry(inner.map_layout.portals, "target_scene", "ch2_s1_zhuwei_market", "require_flag", "chapter1_complete"), "chapter-two exit unlocks after inspecting the orders")
	var quest: QuestDef = load("res://data/quests/q_ch1_main_west_ruin.tres") as QuestDef
	_expect(quest != null and quest.reward_exp >= 100 and quest.reward_gold >= 60, "final main quest has chapter-scale rewards")
	_expect(quest != null and "逼退" in quest.desc_completed, "final quest records a narrow victory instead of a kill")
	var battle_source := FileAccess.get_file_as_string("res://scripts/battle/battle_controller.gd")
	var outcome_body := _function_body(battle_source, "func _apply_nonlethal_boss_outcome", "func _log")
	_expect(outcome_body.contains("zhao_wuji_escape_cutscene_pending"), "battle settlement queues the nonlethal field cutscene")
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	var cutscene_body := _function_body(field_source, "func _play_zhao_wounded_escape", "func _should_play_enter_dialog")
	_expect(cutscene_body.contains("zhao_wuji_wounded_escape"), "field cutscene persists Zhao Wuji's escape")
	_expect(cutscene_body.contains("lengguyun_severely_wounded_ch1"), "field cutscene records Leng Guyun's injury")
	_expect(cutscene_body.contains("0.18"), "field cutscene leaves Leng Guyun heavily injured")
	var team_finish_body := _function_body(battle_source, "func _team_finish", "func _begin_round")
	var gain_exp_index := team_finish_body.find(".gain_exp(total_exp)")
	var injury_index := team_finish_body.find("_apply_nonlethal_boss_outcome")
	_expect(
		gain_exp_index >= 0 and injury_index > gain_exp_index,
		"nonlethal outcome is queued after any level-up refill"
	)


func _load_scene(scene_id: StringName) -> SceneScript:
	return load("res://data/scenes/%s.tres" % String(scene_id)) as SceneScript


func _load_dialog(dialog_id: StringName) -> DialogScript:
	return load("res://data/dialogs/%s.tres" % String(dialog_id)) as DialogScript


func _function_body(source: String, start_marker: String, end_marker: String) -> String:
	var start_index := source.find(start_marker)
	if start_index < 0:
		return ""
	var end_index := source.find(end_marker, start_index + start_marker.length())
	if end_index < 0:
		return source.substr(start_index)
	return source.substr(start_index, end_index - start_index)


func _has_entry(entries: Array, key: String, value: Variant, gate_key: String = "", gate_value: Variant = null) -> bool:
	for raw_entry: Variant in entries:
		var entry: Dictionary = raw_entry as Dictionary
		if entry.get(key) != value:
			continue
		if gate_key == "" or entry.get(gate_key) == gate_value:
			return true
	return false


func _has_npc_gate(entries: Array, npc_id: String, flag: String) -> bool:
	for raw_entry: Variant in entries:
		var entry: Dictionary = raw_entry as Dictionary
		if String(entry.get("npc_id", "")) == npc_id and String(entry.get("require_flag", "")) == flag:
			return true
	return false


func _has_npc_state(entries: Array, npc_id: String, require_flag: String, hide_flag: String) -> bool:
	for raw_entry: Variant in entries:
		var entry: Dictionary = raw_entry as Dictionary
		if String(entry.get("npc_id", "")) != npc_id:
			continue
		if String(entry.get("require_flag", "")) != require_flag:
			continue
		return String(entry.get("hide_flag", "")) == hide_flag
	return false


func _dialog_sets_flag(dialog: DialogScript, flag: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		for raw_flag: Variant in node.set_flags:
			var flag_data: Dictionary = raw_flag as Dictionary
			if String(flag_data.get("key", "")) == flag and bool(flag_data.get("value", false)):
				return true
	return false


func _dialog_accepts_quest(dialog: DialogScript, quest_id: StringName) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node.accept_quest == quest_id:
			return true
	return false


func _dialog_learns_skill(dialog: DialogScript, skill_id: StringName) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if skill_id in node.learn_skills:
			return true
	return false


func _layout_point_walkable(layout: WalkableMapLayout, point: Vector2) -> bool:
	var inside_region: bool = false
	for region: PackedVector2Array in layout.walkable_regions:
		if Geometry2D.is_point_in_polygon(point, region):
			inside_region = true
			break
	if not inside_region:
		return false
	for blocker: Dictionary in layout.blockers:
		var blocker_pos: Vector2 = blocker.get("pos", Vector2.ZERO)
		var blocker_size: Vector2 = blocker.get("size", Vector2.ZERO)
		if Rect2(blocker_pos - blocker_size * 0.5, blocker_size).grow(0.014).has_point(point):
			return false
	return true


func _dialog_has_action(dialog: DialogScript, action: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node.on_end == action:
			return true
	return false


func _dialog_has_choice_text(dialog: DialogScript, choice_text: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		for raw_choice: Variant in node.choices:
			var choice: Dictionary = raw_choice as Dictionary
			if String(choice.get("text", "")) == choice_text:
				return true
	return false


func _dialog_contains_text(dialog: DialogScript, fragment: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if fragment in node.text:
			return true
	return false


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		_failures += 1
		push_error("[FAIL] %s" % message)
