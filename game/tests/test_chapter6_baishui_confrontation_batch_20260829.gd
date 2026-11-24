extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_6_content_plan.tres") as ChapterContentPlan
	var archive := load("res://data/scenes/ch6_s3_underground_archive.tres") as SceneScript
	var route := load("res://data/scenes/ch6_s4_baishui_convoy_route.tres") as SceneScript
	var q4 := load("res://data/quests/q_ch6_main_04_old_convoy_route.tres") as QuestDef
	var q5 := load("res://data/quests/q_ch6_main_05_master_confrontation.tres") as QuestDef
	var evidence := load("res://data/investigation/evidence/ev_ch6_baishui_transfer_marks.tres") as EvidenceDef
	_check(plan != null and plan.main_quest_ids.size() == 6 and plan.story_battle_groups.size() == 2, "chapter six plan retains the Bai Shui route and two formal anchors after the finale was added")
	_check(route != null and FileAccess.file_exists(route.background_path), "Bai Shui route scene and project-local background load")
	if route != null:
		_check(route.map_layout != null and _layout_probes_match(route.map_layout), "Bai Shui main road and both investigation branches are reachable")
		_check(_portal_target(route.map_layout, "return_to_archive") == &"ch6_s3_underground_archive", "Bai Shui route returns to the archive")
		_check(_interaction_action(route.map_layout, "ch6_baishui_milestone") == "dialog:ch6_baishui_milestone", "route exposes the authored milestone clue")
		_check(_interaction_action(route.map_layout, "ch6_baishui_cart") == "dialog:ch6_baishui_cart_trace", "route exposes the authored cart-transfer clue")
	if archive != null:
		_check(_portal_target(archive.map_layout, "enter_baishui_convoy_route") == &"ch6_s4_baishui_convoy_route", "archive and Bai Shui route are bidirectional")
	_check(q4 != null and q4.require_all_completion_triggers and q4.completion_triggers.size() == 3, "Bai Shui quest requires milestone, physical evidence and combat")
	_check(q5 != null and _quest_has_item(q5, &"xuanshuang_script"), "master confrontation grants the incomplete Xuan Shuang manuscript")
	_check(evidence != null and evidence.chapter == 6, "Bai Shui cart-transfer evidence belongs to chapter six")
	var battle_dialog := load("res://data/dialogs/ch6_baishui_prebattle.tres") as DialogScript
	_check(_dialog_has_action(battle_dialog, "battle_group_then:ch6_convoy_pursuer,ch6_convoy_tracker:ch6_baishui_victory"), "Bai Shui interception owns pre-battle dialogue and a victory return")
	var confrontation := load("res://data/dialogs/ch6_master_confrontation.tres") as DialogScript
	var choice_node := confrontation.find_node_by_id(&"choice") if confrontation != null else null
	_check(choice_node != null and choice_node.choices.size() == 3, "master confrontation offers three non-binary attitudes")
	if choice_node != null:
		_check(_choice_sets_flag(choice_node, "ch6_master_stance_public"), "public-testimony branch owns a persistent flag")
		_check(_choice_sets_flag(choice_node, "ch6_master_stance_independent"), "independent-investigation branch owns a persistent flag")
		_check(_choice_sets_flag(choice_node, "ch6_master_stance_protect"), "protect-master branch owns a persistent flag")
	var pursuer := load("res://data/enemies/ch6_convoy_pursuer.tres") as EnemyDef
	var tracker := load("res://data/enemies/ch6_convoy_tracker.tres") as EnemyDef
	_check(pursuer != null and tracker != null and pursuer.level == 10 and tracker.level == 10, "Bai Shui battle uses its own chapter-six enemies")
	await _check_runtime_chain()
	print("[Chapter6BaishuiConfrontation20260829] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_runtime_chain() -> void:
	var game_state := root.get_node("GameState")
	var inventory := root.get_node("Inventory")
	var quests := root.get_node("QuestManager")
	var investigation := root.get_node("InvestigationState")
	game_state.call("reset_for_new_game")
	inventory.call("reset_for_new_game")
	quests.call("reset_for_new_game")
	investigation.call("reset_for_new_game")
	_check(bool(quests.call("accept", &"q_ch6_main_04_old_convoy_route")), "Bai Shui route quest can be accepted")
	game_state.call("set_flag", &"ch6_baishui_milestone_checked", true)
	_check(bool(investigation.call("acquire_evidence", &"ev_ch6_baishui_transfer_marks", &"test")), "Bai Shui transfer evidence can be acquired")
	await process_frame
	_check(not bool(quests.call("is_completed", &"q_ch6_main_04_old_convoy_route")), "investigation does not skip the route interception")
	game_state.call("set_flag", &"ch6_convoy_pursuers_defeated", true)
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch6_main_04_old_convoy_route")), "Bai Shui route completes after all three beats")
	_check(bool(quests.call("accept", &"q_ch6_main_05_master_confrontation")), "master confrontation can be accepted")
	game_state.call("set_flag", &"ch6_master_stance_public", true)
	game_state.call("set_flag", &"ch6_master_choice_made", true)
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch6_main_05_master_confrontation")), "master confrontation completes after a persistent stance")
	_check(int(inventory.call("count_of", &"xuanshuang_script")) == 1, "master confrontation grants exactly one manuscript")


func _layout_probes_match(layout: WalkableMapLayout) -> bool:
	if layout == null:
		return false
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


func _interaction_action(layout: WalkableMapLayout, interaction_id: String) -> String:
	if layout == null:
		return ""
	for interaction: Dictionary in layout.interactions:
		if String(interaction.get("id", "")) == interaction_id:
			return String(interaction.get("action", ""))
	return ""


func _portal_target(layout: WalkableMapLayout, portal_id: String) -> StringName:
	if layout == null:
		return &""
	for portal: Dictionary in layout.portals:
		if String(portal.get("id", "")) == portal_id:
			return StringName(String(portal.get("target_scene", "")))
	return &""


func _quest_has_item(quest: QuestDef, item_id: StringName) -> bool:
	for entry: Dictionary in quest.reward_items:
		if StringName(String(entry.get("item_id", entry.get("id", "")))) == item_id:
			return true
	return false


func _dialog_has_action(dialog: DialogScript, action: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node.on_end == action:
			return true
	return false


func _choice_sets_flag(node: DialogNode, flag_name: String) -> bool:
	for choice: Dictionary in node.choices:
		var flags: Dictionary = choice.get("set_flag", {})
		if bool(flags.get(flag_name, false)):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
