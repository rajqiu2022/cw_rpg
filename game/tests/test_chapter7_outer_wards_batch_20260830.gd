extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_7_content_plan.tres") as ChapterContentPlan
	var lieyun_entry := load("res://data/scenes/ch7_s1_lieyun_valley_ferry.tres") as SceneScript
	var mingwu_entry := load("res://data/scenes/ch7_s2_mingwu_tea_town.tres") as SceneScript
	var lieyun_outer := load("res://data/scenes/ch7_s3_lieyun_outpost_outer_ward.tres") as SceneScript
	var mingwu_outer := load("res://data/scenes/ch7_s4_mingwu_manor_outer_court.tres") as SceneScript
	var quest := load("res://data/quests/q_ch7_main_03_outer_wards.tres") as QuestDef
	_check(plan != null and plan.main_scene_ids.size() >= 4 and plan.main_quest_ids.size() >= 3, "chapter seven retains the four outer-route scenes and their three opening quests")
	_check(plan != null and plan.story_battle_groups.size() >= 1, "chapter seven retains the outer-ward production battle anchor from this batch")
	if plan != null and not plan.story_battle_groups.is_empty():
		var anchor: Dictionary = plan.story_battle_groups[0]
		_check(String(anchor.get("id", "")) == "lieyun_outer_ward_hardliners" and int(anchor.get("recommended_level", 0)) == 11, "outer-ward battle anchor is a level-eleven evidence obstruction")
		_check((anchor.get("enemy_ids", []) as Array).size() == 2, "outer-ward anchor is a two-enemy encounter")
	_check(_portal_target(lieyun_entry.map_layout, "enter_lieyun_outer_ward") == &"ch7_s3_lieyun_outpost_outer_ward", "Lieyun old ferry opens the outpost outer ward")
	_check(_portal_gate(lieyun_entry.map_layout, "enter_lieyun_outer_ward") == "ch7_outer_routes_opened", "Lieyun inner route uses the shared dual-front gate")
	_check(_portal_target(mingwu_entry.map_layout, "enter_mingwu_outer_court") == &"ch7_s4_mingwu_manor_outer_court", "Mingwu tea town opens the manor outer court")
	_check(_portal_gate(mingwu_entry.map_layout, "enter_mingwu_outer_court") == "ch7_outer_routes_opened", "Mingwu inner route uses the shared dual-front gate")
	_check(_scene_contract_ok(lieyun_outer, "bg_ch7_lieyun_outpost_outer_ward_gameplay_v1.png"), "Lieyun outer ward uses a formal reachable 1536x1024 background")
	_check(_scene_contract_ok(mingwu_outer, "bg_ch7_mingwu_manor_outer_court_gameplay_v1.png"), "Mingwu outer court uses a formal reachable 1536x1024 background")
	if lieyun_outer != null:
		_check(_portal_target(lieyun_outer.map_layout, "return_to_lieyun_ferry") == &"ch7_s1_lieyun_valley_ferry", "Lieyun outer ward returns to the old ferry")
		_check(_interaction_action(lieyun_outer.map_layout, "ch7_lieyun_quarantine_register") == "dialog:ch7_lieyun_quarantine_register", "Lieyun medicine registry is a separate evidence interaction")
		_check(_npc_gate(lieyun_outer, "ch7_lieyun_hardliner_field", "ch7_lieyun_registry_checked", "ch7_lieyun_hardliners_defeated"), "hardliners appear only after the medicine record and disappear after defeat")
	if mingwu_outer != null:
		_check(_portal_target(mingwu_outer.map_layout, "return_to_mingwu_tea_town") == &"ch7_s2_mingwu_tea_town", "Mingwu outer court returns to the tea town")
		_check(_interaction_requires(mingwu_outer.map_layout, "ch7_mingwu_transfer_ledger_direct", "ch7_route_first_mingwu"), "Mingwu-first order preserves the direct ledger version")
		_check(_interaction_requires(mingwu_outer.map_layout, "ch7_mingwu_transfer_ledger_alerted", "ch7_route_first_lieyun"), "Lieyun-first order exposes the alerted missing-ledger version")
	var open_dialog := load("res://data/dialogs/ch7_outer_routes_open.tres") as DialogScript
	var open_node := open_dialog.find_node_by_id(&"open") if open_dialog != null else null
	_check(open_node != null and open_node.accept_quest == &"q_ch7_main_03_outer_wards" and _node_sets_flag(open_node, "ch7_outer_routes_opened"), "two-front completion explicitly accepts and unlocks the outer-wards quest")
	_check(quest != null and quest.require_all_completion_triggers and quest.completion_triggers.size() == 3, "outer-wards quest requires both evidence records and the hardliner battle")
	var lieyun_evidence := load("res://data/investigation/evidence/ev_ch7_lieyun_quarantine_formula.tres") as EvidenceDef
	var mingwu_evidence := load("res://data/investigation/evidence/ev_ch7_mingwu_transfer_ledger_gap.tres") as EvidenceDef
	_check(lieyun_evidence != null and lieyun_evidence.chapter == 7 and lieyun_evidence.description.contains("晚于五派弟子案"), "Lieyun evidence separates its proven old crime from the five-disciples case")
	_check(mingwu_evidence != null and mingwu_evidence.chapter == 7 and mingwu_evidence.description.contains("尚不能确认"), "Mingwu evidence proves document removal without inventing the passenger's fate")
	var guard := load("res://data/enemies/ch7_lieyun_hardliner_guard.tres") as EnemyDef
	var tracker := load("res://data/enemies/ch7_lieyun_hardliner_tracker.tres") as EnemyDef
	_check(_enemy_contract_ok(guard) and _enemy_contract_ok(tracker), "both level-eleven hardliners use current-scale stats and real battle art")
	var skill := CombatBalanceSimulator.recommended_skill_for_level(11)
	var gear := CombatBalanceSimulator.expected_gear_for_level(11)
	var guard_sim := CombatBalanceSimulator.simulate_encounter(guard, 11, skill, gear)
	var tracker_sim := CombatBalanceSimulator.simulate_encounter(tracker, 11, skill, gear)
	print("[Chapter7Balance] guard_tkk=%s guard_ttd=%s tracker_tkk=%s tracker_ttd=%s" % [guard_sim.get("tkk", 0), guard_sim.get("ttd", 0), tracker_sim.get("tkk", 0), tracker_sim.get("ttd", 0)])
	_check(int(guard_sim.get("tkk", 0)) >= 3 and int(guard_sim.get("tkk", 0)) <= 6, "hardliner guard is a durable but non-boss individual anchor")
	_check(int(tracker_sim.get("tkk", 0)) >= 3 and int(tracker_sim.get("tkk", 0)) <= 6, "hardliner tracker stays below the guard's durability band")
	_check(float(guard_sim.get("safety_factor", 0.0)) > 0.0 and float(tracker_sim.get("safety_factor", 0.0)) > 0.0, "both hardliners produce finite incoming-pressure estimates")
	var prebattle := load("res://data/dialogs/ch7_lieyun_hardliner_prebattle.tres") as DialogScript
	var alerted := load("res://data/dialogs/ch7_lieyun_hardliner_prebattle_alerted.tres") as DialogScript
	var battle_action := "battle_group_then:ch7_lieyun_hardliner_guard,ch7_lieyun_hardliner_tracker:ch7_lieyun_hardliner_victory"
	_check(_dialog_has_action(prebattle, battle_action) and _dialog_has_action(alerted, battle_action), "both investigation orders converge on the same formal hardliner battle")
	_check(root.get_node("SceneRouter").call("_battle_arena_for_scene", &"ch7_s3_lieyun_outpost_outer_ward") == &"outskirts_road", "outer-ward battle selects the open outskirts arena")
	await _check_runtime_chain(true)
	await _check_runtime_chain(false)
	print("[Chapter7OuterWards20260830] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_runtime_chain(lieyun_first: bool) -> void:
	var game_state := root.get_node("GameState")
	var quests := root.get_node("QuestManager")
	var investigation := root.get_node("InvestigationState")
	game_state.call("reset_for_new_game")
	quests.call("reset_for_new_game")
	investigation.call("reset_for_new_game")
	_check(bool(quests.call("accept", &"q_ch7_main_03_outer_wards")), "%s order can accept outer-wards cross-checking" % ("Lieyun-first" if lieyun_first else "Mingwu-first"))
	if lieyun_first:
		investigation.call("acquire_evidence", &"ev_ch7_lieyun_quarantine_formula", &"test")
		game_state.call("set_flag", &"ch7_lieyun_hardliners_defeated", true)
	else:
		investigation.call("acquire_evidence", &"ev_ch7_mingwu_transfer_ledger_gap", &"test")
	await process_frame
	_check(not bool(quests.call("is_completed", &"q_ch7_main_03_outer_wards")), "one route never completes outer-wards cross-checking")
	if lieyun_first:
		investigation.call("acquire_evidence", &"ev_ch7_mingwu_transfer_ledger_gap", &"test")
	else:
		investigation.call("acquire_evidence", &"ev_ch7_lieyun_quarantine_formula", &"test")
		await process_frame
		_check(not bool(quests.call("is_completed", &"q_ch7_main_03_outer_wards")), "both records still require clearing the hardliner obstruction")
		game_state.call("set_flag", &"ch7_lieyun_hardliners_defeated", true)
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch7_main_03_outer_wards")), "%s order completes only after both records and battle" % ("Lieyun-first" if lieyun_first else "Mingwu-first"))


func _scene_contract_ok(scene: SceneScript, expected_file: String) -> bool:
	if scene == null or scene.map_layout == null or not scene.background_path.ends_with(expected_file) or not FileAccess.file_exists(scene.background_path):
		return false
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(scene.background_path)) != OK or image.get_size() != Vector2i(1536,1024):
		return false
	return _layout_probes_match(scene.map_layout)


func _layout_probes_match(layout: WalkableMapLayout) -> bool:
	for probe: Dictionary in layout.walkable_probes:
		var point := probe.get("pos", Vector2(-1.0,-1.0)) as Vector2
		if not layout.walkable_regions.any(func(region: PackedVector2Array): return Geometry2D.is_point_in_polygon(point, region)):
			return false
	for probe: Dictionary in layout.blocked_probes:
		var point := probe.get("pos", Vector2(-1.0,-1.0)) as Vector2
		var inside_region := layout.walkable_regions.any(func(region: PackedVector2Array): return Geometry2D.is_point_in_polygon(point, region))
		var inside_blocker := layout.blockers.any(func(blocker: Dictionary):
			var center := blocker.get("pos", Vector2.ZERO) as Vector2
			var size := blocker.get("size", Vector2.ZERO) as Vector2
			return Rect2(center - size * 0.5, size).has_point(point)
		)
		if inside_region and not inside_blocker:
			return false
	return true


func _portal_target(layout: WalkableMapLayout, portal_id: String) -> StringName:
	for portal: Dictionary in layout.portals:
		if String(portal.get("id", "")) == portal_id:
			return StringName(String(portal.get("target_scene", "")))
	return &""


func _portal_gate(layout: WalkableMapLayout, portal_id: String) -> String:
	for portal: Dictionary in layout.portals:
		if String(portal.get("id", "")) == portal_id:
			return String(portal.get("require_flag", ""))
	return ""


func _interaction_action(layout: WalkableMapLayout, interaction_id: String) -> String:
	for interaction: Dictionary in layout.interactions:
		if String(interaction.get("id", "")) == interaction_id:
			return String(interaction.get("action", ""))
	return ""


func _interaction_requires(layout: WalkableMapLayout, interaction_id: String, flag_name: String) -> bool:
	for interaction: Dictionary in layout.interactions:
		if String(interaction.get("id", "")) == interaction_id:
			return String(interaction.get("require_flag", "")) == flag_name
	return false


func _npc_gate(scene: SceneScript, npc_id: String, require_flag: String, hide_flag: String) -> bool:
	for npc: Dictionary in scene.npcs:
		if String(npc.get("npc_id", "")) == npc_id:
			return String(npc.get("require_flag", "")) == require_flag and String(npc.get("hide_flag", "")) == hide_flag
	return false


func _node_sets_flag(node: DialogNode, flag_name: String) -> bool:
	for entry: Dictionary in node.set_flags:
		if String(entry.get("key", "")) == flag_name and bool(entry.get("value", false)):
			return true
	return false


func _enemy_contract_ok(enemy: EnemyDef) -> bool:
	return enemy != null and enemy.level == 11 and enemy.attack >= 100 and enemy.max_hp >= 450 and FileAccess.file_exists(enemy.battle_actor_path) and not enemy.is_chapter_boss


func _dialog_has_action(dialog: DialogScript, action: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node.on_end == action:
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
