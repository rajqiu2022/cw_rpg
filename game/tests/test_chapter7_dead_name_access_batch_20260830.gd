extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_7_content_plan.tres") as ChapterContentPlan
	var hall := load("res://data/scenes/ch7_s5_lieyun_assembly_hall.tres") as SceneScript
	var inner := load("res://data/scenes/ch7_s6_mingwu_inner_court.tres") as SceneScript
	var lieyun_archive := load("res://data/scenes/ch7_s7_lieyun_resettlement_archive.tres") as SceneScript
	var permission_archive := load("res://data/scenes/ch7_s8_mingwu_permission_archive.tres") as SceneScript
	var quest := load("res://data/quests/q_ch7_main_05_dead_name_live_access.tres") as QuestDef
	_check(plan != null and plan.main_scene_ids.size() >= 8 and plan.main_quest_ids.size() >= 5, "chapter seven retains the eight permission-chain scenes and five opening quests")
	_check(plan != null and plan.story_battle_groups.size() == 1, "dead-name investigation adds no unneeded battle")
	_check(_portal_target(hall.map_layout, "enter_lieyun_resettlement_archive") == &"ch7_s7_lieyun_resettlement_archive", "assembly hall opens the resettlement archive")
	_check(_portal_gate(hall.map_layout, "enter_lieyun_resettlement_archive") == "ch7_dead_code_routes_opened", "Lieyun archive uses the shared dead-code route gate")
	_check(_portal_target(inner.map_layout, "enter_mingwu_permission_archive") == &"ch7_s8_mingwu_permission_archive", "Mingwu inner court opens the permission archive")
	_check(_portal_gate(inner.map_layout, "enter_mingwu_permission_archive") == "ch7_dead_code_routes_opened", "Mingwu archive uses the shared dead-code route gate")
	_check(_scene_contract_ok(lieyun_archive, "bg_ch7_lieyun_resettlement_archive_gameplay_v1.png"), "Lieyun archive uses a formal reachable 1536x1024 background")
	_check(_scene_contract_ok(permission_archive, "bg_ch7_mingwu_permission_archive_gameplay_v1.png"), "Mingwu permission room uses a formal reachable 1536x1024 background")
	_check(_portal_target(lieyun_archive.map_layout, "return_to_lieyun_assembly_hall") == &"ch7_s5_lieyun_assembly_hall", "Lieyun archive returns to the assembly hall")
	_check(_portal_target(permission_archive.map_layout, "return_to_mingwu_inner_court") == &"ch7_s6_mingwu_inner_court", "permission room returns to the Mingwu inner court")
	_check(_interaction_action(permission_archive.map_layout, "ch7_mingwu_revoked_access_roll") == "dialog:ch7_mingwu_revoked_access_roll", "revocation roll is a separate visible investigation interaction")
	_check(_npc_is_available_after_previous_quest(hall, "ch7_qi_yunsheng", "ch7_dead_code_routes_open"), "Qi Yunsheng remains present after the prior quest to open both archive routes")
	var open_dialog := load("res://data/dialogs/ch7_dead_code_routes_open.tres") as DialogScript
	var open_node := open_dialog.find_node_by_id(&"open") if open_dialog != null else null
	_check(open_node != null and open_node.accept_quest == &"q_ch7_main_05_dead_name_live_access" and _node_sets_flag(open_node, "ch7_dead_code_routes_opened"), "Qi Yunsheng explicitly accepts and unlocks the dead-name investigation")
	_check(quest != null and quest.require_all_completion_triggers and quest.completion_triggers.size() == 2, "dead-name quest requires both registered ownership and posthumous use")
	_check(quest != null and quest.desc_completed.contains("尚不能确认实际使用者"), "quest conclusion does not turn registered ownership into identity proof")
	var evidence := load("res://data/investigation/evidence/ev_ch7_mingwu_revoked_access_roll.tres") as EvidenceDef
	var testimony := load("res://data/investigation/testimonies/ts_ch7_lieyun_posthumous_code_use.tres") as TestimonyDef
	_check(evidence != null and evidence.description.contains("登记在大弟子薛影名下") and evidence.description.contains("不能单独证明实际使用者"), "revocation roll names the registered owner and preserves user uncertainty")
	_check(testimony != null and testimony.statement.contains("没有看清脸") and testimony.statement.contains("只能证明权限"), "second witness proves posthumous use without identifying the user")
	_check(testimony != null and &"ev_ch7_mingwu_revoked_access_roll" in testimony.related_evidence_ids, "second witness is explicitly cross-linked to the permission roll")
	var roll_dialog := load("res://data/dialogs/ch7_mingwu_revoked_access_roll.tres") as DialogScript
	var record_node := roll_dialog.find_node_by_id(&"record") if roll_dialog != null else null
	_check(record_node != null and &"ev_ch7_mingwu_revoked_access_roll" in record_node.add_evidence and record_node.text.contains("不记“薛影本人出现”"), "runtime roll dialogue records only the supported claim")
	var keeper_dialog := load("res://data/dialogs/ch7_lieyun_record_keeper_testimony.tres") as DialogScript
	_check(_dialog_adds_testimony(keeper_dialog, &"ts_ch7_lieyun_posthumous_code_use"), "record keeper contributes the second limited testimony")
	await _check_runtime_chain(true)
	await _check_runtime_chain(false)
	print("[Chapter7DeadNameAccess20260830] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_runtime_chain(evidence_first: bool) -> void:
	var game_state := root.get_node("GameState")
	var quests := root.get_node("QuestManager")
	var investigation := root.get_node("InvestigationState")
	game_state.call("reset_for_new_game")
	quests.call("reset_for_new_game")
	investigation.call("reset_for_new_game")
	_check(bool(quests.call("accept", &"q_ch7_main_05_dead_name_live_access")), "%s order can accept dead-name investigation" % ("Roll-first" if evidence_first else "Witness-first"))
	if evidence_first:
		investigation.call("acquire_evidence", &"ev_ch7_mingwu_revoked_access_roll", &"test")
	else:
		investigation.call("hear_testimony", &"ts_ch7_lieyun_posthumous_code_use")
	await process_frame
	_check(not bool(quests.call("is_completed", &"q_ch7_main_05_dead_name_live_access")), "one side never resolves who used a dead person's access")
	if evidence_first:
		investigation.call("hear_testimony", &"ts_ch7_lieyun_posthumous_code_use")
	else:
		investigation.call("acquire_evidence", &"ev_ch7_mingwu_revoked_access_roll", &"test")
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch7_main_05_dead_name_live_access")), "%s order completes after ownership and posthumous use cross-check" % ("Roll-first" if evidence_first else "Witness-first"))


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


func _npc_is_available_after_previous_quest(scene: SceneScript, npc_id: String, dialog_id: String) -> bool:
	for npc: Dictionary in scene.npcs:
		if String(npc.get("npc_id", "")) != npc_id or npc.has("require_quest_active"):
			continue
		for variant: Dictionary in npc.get("dialog_variants", []):
			if String(variant.get("dialog_id", "")) == dialog_id and String(variant.get("require_quest_completed", "")) == "q_ch7_main_04_reform_and_witness":
				return true
	return false


func _node_sets_flag(node: DialogNode, flag_name: String) -> bool:
	for entry: Dictionary in node.set_flags:
		if String(entry.get("key", "")) == flag_name and bool(entry.get("value", false)):
			return true
	return false


func _dialog_adds_testimony(dialog: DialogScript, testimony_id: StringName) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if testimony_id in node.add_testimonies:
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
