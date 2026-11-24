extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_7_content_plan.tres") as ChapterContentPlan
	var world := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	var lieyun := load("res://data/scenes/ch7_s1_lieyun_valley_ferry.tres") as SceneScript
	var mingwu := load("res://data/scenes/ch7_s2_mingwu_tea_town.tres") as SceneScript
	var q1 := load("res://data/quests/q_ch7_main_01_choose_first_route.tres") as QuestDef
	var q2 := load("res://data/quests/q_ch7_main_02_compare_two_fronts.tres") as QuestDef
	_check(plan != null and plan.chapter == 7 and plan.main_scene_ids.size() >= 2 and plan.main_quest_ids.size() >= 2, "chapter seven retains both current entry scenes and their two opening quests")
	_check(plan != null and plan.story_battle_groups.size() >= 1, "later chapter-seven batches retain the first formal anchor without changing the dual-entry contract")
	_check(world != null and world.on_enter_dialog != null and world.on_enter_dialog.dialog_id == &"ch7_route_choice", "chapter seven opens its route choice on the world map")
	_check(world != null and world.on_enter_require_flag == &"chapter6_complete" and world.on_enter_once_flag == &"seen_ch7_route_choice", "route choice is chapter-six gated and one-shot")
	if world != null:
		_check(_portal_target(world.map_layout, "lieyun_valley") == &"ch7_s1_lieyun_valley_ferry", "world map reaches Lieyun valley")
		_check(_portal_target(world.map_layout, "mingwu") == &"ch7_s2_mingwu_tea_town", "world map reaches Mingwu tea town")
		_check(_portal_gate(world.map_layout, "lieyun_valley") == "ch7_dual_route_chosen" and _portal_gate(world.map_layout, "mingwu") == "ch7_dual_route_chosen", "both routes unlock together after choosing investigation order")
	_check(_scene_contract_ok(lieyun, "bg_ch7_lieyun_valley_ferry_gameplay_v1.png"), "Lieyun entry uses its formal 1536x1024 gameplay background and reachable layout")
	_check(_scene_contract_ok(mingwu, "bg_ch7_mingwu_tea_town_gameplay_v1.png"), "Mingwu entry uses its formal 1536x1024 gameplay background and reachable layout")
	if lieyun != null:
		_check(lieyun.on_enter_require_flag == &"ch7_dual_route_chosen", "Lieyun arrival also plays when it is visited second")
		_check(_portal_target(lieyun.map_layout, "return_to_world_map") == &"world_map_jianghu", "Lieyun entry can return to the world map")
		_check(_interaction_action(lieyun.map_layout, "ch7_lieyun_old_ferry_marks") == "dialog:ch7_lieyun_ferry_marks", "Lieyun old ferry contains an optional physical trace")
		_check(_npc_variant_requires(lieyun, "ch7_lieyun_gatekeeper", "ch7_lieyun_gatekeeper_alerted", "ch7_route_first_mingwu"), "Lieyun guard reacts when Mingwu was investigated first")
	if mingwu != null:
		_check(mingwu.on_enter_require_flag == &"ch7_dual_route_chosen", "Mingwu arrival also plays when it is visited second")
		_check(_portal_target(mingwu.map_layout, "return_to_world_map") == &"world_map_jianghu", "Mingwu entry can return to the world map")
		_check(_interaction_action(mingwu.map_layout, "ch7_mingwu_courier_table") == "dialog:ch7_mingwu_courier_table", "Mingwu courier pavilion contains an optional cleaned-wax trace")
		_check(_npc_variant_requires(mingwu, "ch7_mingwu_broker", "ch7_mingwu_broker_alerted", "ch7_route_first_lieyun"), "Mingwu broker reacts when Lieyun was investigated first")
	var choice_dialog := load("res://data/dialogs/ch7_route_choice.tres") as DialogScript
	var choice := choice_dialog.find_node_by_id(&"choice") if choice_dialog != null else null
	_check(choice != null and choice.choices.size() == 2, "route choice offers exactly two investigation orders")
	if choice != null:
		_check(_choice_sets_flag(choice.choices[0], "ch7_route_first_lieyun") and _choice_next(choice.choices[0]) == "lieyun", "Lieyun-first option persists its order and routes to Lieyun")
		_check(_choice_sets_flag(choice.choices[1], "ch7_route_first_mingwu") and _choice_next(choice.choices[1]) == "mingwu", "Mingwu-first option persists its order and routes to Mingwu")
	_check(q1 != null and q1.completion_triggers.size() == 1 and q1.completion_triggers[0] == "flag_set:ch7_first_route_arrived", "first quest completes only after reaching the chosen route")
	_check(q2 != null and q2.require_all_completion_triggers and q2.completion_triggers.size() == 2, "second quest requires visiting both fronts")
	_check(root.get_node("SceneRouter").call("get_chapter_entry", 7) == &"world_map_jianghu", "chapter-seven settlement entry remains the world map choice hub")
	await _check_runtime_order(true)
	await _check_runtime_order(false)
	print("[Chapter7DualEntry20260829] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_runtime_order(lieyun_first: bool) -> void:
	var game_state := root.get_node("GameState")
	var quests := root.get_node("QuestManager")
	game_state.call("reset_for_new_game")
	quests.call("reset_for_new_game")
	_check(bool(quests.call("accept", &"q_ch7_main_01_choose_first_route")), "%s order can accept the route-choice quest" % ("Lieyun-first" if lieyun_first else "Mingwu-first"))
	game_state.call("set_flag", &"ch7_dual_route_chosen", true)
	game_state.call("set_flag", &"ch7_route_first_lieyun" if lieyun_first else &"ch7_route_first_mingwu", true)
	game_state.call("set_flag", &"ch7_lieyun_entry_seen" if lieyun_first else &"ch7_mingwu_entry_seen", true)
	game_state.call("set_flag", &"ch7_first_route_arrived", true)
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch7_main_01_choose_first_route")), "%s order completes after the first arrival" % ("Lieyun-first" if lieyun_first else "Mingwu-first"))
	_check(bool(quests.call("accept", &"q_ch7_main_02_compare_two_fronts")), "%s order can accept dual-front reconnaissance" % ("Lieyun-first" if lieyun_first else "Mingwu-first"))
	_check(not bool(quests.call("is_completed", &"q_ch7_main_02_compare_two_fronts")), "one visited front never completes dual-front reconnaissance")
	game_state.call("set_flag", &"ch7_mingwu_entry_seen" if lieyun_first else &"ch7_lieyun_entry_seen", true)
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch7_main_02_compare_two_fronts")), "%s order completes after visiting the second front" % ("Lieyun-first" if lieyun_first else "Mingwu-first"))


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
	if layout == null:
		return &""
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


func _npc_variant_requires(scene: SceneScript, npc_id: String, dialog_id: String, flag_name: String) -> bool:
	for npc: Dictionary in scene.npcs:
		if String(npc.get("npc_id", "")) != npc_id:
			continue
		for variant: Dictionary in npc.get("dialog_variants", []):
			if String(variant.get("dialog_id", "")) == dialog_id and flag_name in variant.get("require_flags", []):
				return true
	return false


func _choice_sets_flag(choice: Dictionary, flag_name: String) -> bool:
	return bool((choice.get("set_flag", {}) as Dictionary).get(flag_name, false))


func _choice_next(choice: Dictionary) -> String:
	return String(choice.get("next", ""))


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
