extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_6_content_plan.tres") as ChapterContentPlan
	var courtyard := load("res://data/scenes/linxi_tutorial.tres") as SceneScript
	var residence := load("res://data/scenes/linxi_master_hall.tres") as SceneScript
	var archive := load("res://data/scenes/ch6_s3_underground_archive.tres") as SceneScript
	var q1 := load("res://data/quests/q_ch6_main_01_homecoming.tres") as QuestDef
	var q2 := load("res://data/quests/q_ch6_main_02_old_residence.tres") as QuestDef
	var q3 := load("res://data/quests/q_ch6_main_03_underground_archive.tres") as QuestDef
	_check(plan != null and plan.chapter == 6 and plan.main_quest_ids.size() >= 3, "chapter six plan retains the initial three-stage slice")
	_check(courtyard != null and residence != null and archive != null, "homecoming, residence and archive scenes load")
	if courtyard != null:
		_check(courtyard.on_enter_dialog != null and courtyard.on_enter_require_flag == &"chapter5_complete", "return story starts only after chapter five")
		_check(courtyard.on_enter_once_flag == &"seen_ch6_return_intro", "homecoming dialogue is one-shot")
	if residence != null:
		_check(residence.background_path.ends_with("bg_linxi_master_hall_interior_v3_secret_door.png") and FileAccess.file_exists(residence.background_path), "master residence uses its formal authored background")
		_check(residence.map_layout != null and _layout_probes_match(residence.map_layout), "master residence navigation matches the formal background")
		_check(_interaction_action(residence.map_layout, "ch6_revised_escort_note") == "dialog:ch6_residence_escort_note", "residence exposes the revised escort note")
		_check(_portal_target(residence.map_layout, "enter_underground_archive") == &"ch6_s3_underground_archive", "residence opens the archive through a gated two-way portal")
	if archive != null:
		_check(archive.background_path.ends_with("bg_ch6_underground_archive_gameplay_v1.png") and FileAccess.file_exists(archive.background_path), "archive uses the new project-local gameplay background")
		_check(archive.map_layout != null and _layout_probes_match(archive.map_layout), "archive main route and both short branches are walkable")
		_check(_portal_target(archive.map_layout, "return_to_master_hall") == &"linxi_master_hall", "archive returns to the master residence")
		_check(_interaction_action(archive.map_layout, "ch6_parent_convoy_roster") == "dialog:ch6_archive_parent_roster", "archive owns a visible original-roster interaction")
	_check(q1 != null and q2 != null and q3 != null, "chapter six initial quests load")
	if q3 != null:
		_check(q3.require_all_completion_triggers and q3.completion_triggers.size() == 4, "archive quest requires battle, both records and final securing")
		_check(_quest_has_item(q3, &"jinhe_duanyue_blade"), "archive anchor grants the reserved chapter-six orange blade")
	var battle_dialog := load("res://data/dialogs/ch6_archive_prebattle.tres") as DialogScript
	_check(_dialog_has_action(battle_dialog, "battle_group_then:ch6_archive_reclaimer,ch6_archive_burner:ch6_archive_victory"), "archive battle has authored pre-battle dialogue and victory return")
	_check(root.get_node("SceneRouter").call("get_chapter_entry", 6) == &"linxi_tutorial", "chapter five settlement can enter chapter six")
	await _check_runtime_chain()
	print("[Chapter6HomeArchiveSlice20260829] failures=%d" % failures)
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
	_check(bool(quests.call("accept", &"q_ch6_main_01_homecoming")), "homecoming quest can be accepted")
	game_state.call("set_flag", &"ch6_master_found", true)
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch6_main_01_homecoming")), "finding the wounded master completes homecoming")
	_check(bool(quests.call("accept", &"q_ch6_main_02_old_residence")), "old-residence quest can be accepted")
	root.get_node("EventBus").scene_entered.emit(&"ch6_s3_underground_archive")
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch6_main_02_old_residence")), "entering the discovered archive completes the residence stage")
	_check(bool(investigation.call("acquire_evidence", &"ev_ch6_revised_escort_note", &"test")), "revised escort note can be acquired before the archive quest")
	_check(bool(quests.call("accept", &"q_ch6_main_03_underground_archive")), "archive quest can be accepted")
	game_state.call("set_flag", &"ch6_archive_reclaimers_defeated", true)
	_check(bool(investigation.call("acquire_evidence", &"ev_ch6_parent_convoy_roster", &"test")), "original convoy roster can be acquired")
	await process_frame
	_check(not bool(quests.call("is_completed", &"q_ch6_main_03_underground_archive")), "archive does not complete before records are secured")
	game_state.call("set_flag", &"ch6_archive_records_secured", true)
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch6_main_03_underground_archive")), "archive completes after the full evidence chain")
	_check(int(inventory.call("count_of", &"jinhe_duanyue_blade")) == 1, "archive grants exactly one orange blade")


func _layout_probes_match(layout: WalkableMapLayout) -> bool:
	if layout == null:
		return false
	for probe: Dictionary in layout.walkable_probes:
		var point := probe.get("pos", Vector2(-1.0, -1.0)) as Vector2
		if not layout.walkable_regions.any(func(region: PackedVector2Array): return Geometry2D.is_point_in_polygon(point, region)):
			return false
	for probe: Dictionary in layout.blocked_probes:
		var point := probe.get("pos", Vector2(-1.0, -1.0)) as Vector2
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


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
