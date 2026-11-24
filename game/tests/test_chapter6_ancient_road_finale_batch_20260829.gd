extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_6_content_plan.tres") as ChapterContentPlan
	var inn := load("res://data/scenes/ch6_s5_ancient_road_inn.tres") as SceneScript
	var quest := load("res://data/quests/q_ch6_main_06_ancient_road_letter.tres") as QuestDef
	var letter := load("res://data/items/qiyun_letter.tres") as Item
	var jade := load("res://data/items/qiyun_jade.tres") as Item
	_check(plan != null and plan.main_quest_ids.size() == 6 and plan.main_scene_ids.size() == 5, "chapter six plan includes the ancient-road finale")
	_check(inn != null and inn.background_path.ends_with("bg_interior_inn_hall_v1.png") and FileAccess.file_exists(inn.background_path), "ancient-road inn reuses a formal project-local interior")
	if inn != null:
		_check(inn.npcs.is_empty(), "ancient-road inn does not leak unrelated Qingfeng inn NPCs")
		_check(inn.map_layout != null and _layout_probes_match(inn.map_layout), "inn spawn, letter table and exit are reachable")
		_check(_interaction_action(inn.map_layout, "ch6_qiyun_sealed_letter") == "dialog:ch6_qiyun_letter", "sealed letter is a visible authored interaction")
		_check(_interaction_texture(inn.map_layout, "ch6_qiyun_sealed_letter").ends_with("interaction_letter_sealed_v1.png"), "sealed letter uses the dedicated letter prop")
		_check(_portal_target(inn.map_layout, "return_to_linxi") == &"linxi_tutorial", "inn can return to Linxi after reading")
	_check(quest != null and quest.kind == QuestDef.Kind.MAIN and quest.completion_triggers.size() == 1 and quest.completion_triggers[0] == "flag_set:ch6_qiyun_letter_read", "ancient-road letter is migrated into the current main line")
	_check(letter != null and letter.is_readable() and letter.read_content.contains("烈云分舵"), "Qi Yunsheng letter remains readable in the inventory")
	_check(jade != null and jade.description.contains("通行信物"), "black jade is framed as evidence and passage token")
	var confrontation := load("res://data/dialogs/ch6_master_confrontation.tres") as DialogScript
	var converge := confrontation.find_node_by_id(&"converge") if confrontation != null else null
	_check(converge != null and converge.accept_quest == &"q_ch6_main_06_ancient_road_letter", "master confrontation accepts the finale quest")
	_check(converge != null and converge.on_end == "scene:ch6_s5_ancient_road_inn", "master confrontation transitions directly to the authored inn")
	var finale := load("res://data/dialogs/ch6_qiyun_letter.tres") as DialogScript
	var resolve := finale.find_node_by_id(&"resolve") if finale != null else null
	_check(resolve != null and _node_sets_flag(resolve, "ch6_qiyun_letter_read"), "letter resolution records the investigated clue")
	_check(resolve != null and _node_sets_flag(resolve, "chapter7_investigation_unlocked"), "letter resolution unlocks the next investigation direction")
	_check(resolve != null and resolve.on_end == "chapter_end:6", "letter closes through formal chapter-six settlement")
	_check(root.get_node("SceneRouter").call("get_chapter_entry", 7) == &"world_map_jianghu", "chapter seven currently enters through the open-world map instead of legacy scenes")
	await _check_runtime_chain()
	print("[Chapter6AncientRoadFinale20260829] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_runtime_chain() -> void:
	var game_state := root.get_node("GameState")
	var inventory := root.get_node("Inventory")
	var quests := root.get_node("QuestManager")
	game_state.call("reset_for_new_game")
	inventory.call("reset_for_new_game")
	quests.call("reset_for_new_game")
	_check(bool(quests.call("accept", &"q_ch6_main_06_ancient_road_letter")), "ancient-road finale quest can be accepted")
	inventory.call("add_item", &"qiyun_letter", 1)
	inventory.call("add_item", &"qiyun_jade", 1)
	game_state.call("set_flag", &"ch6_qiyun_letter_read", true)
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch6_main_06_ancient_road_letter")), "reading the letter completes the current chapter-six main quest")
	_check(int(inventory.call("count_of", &"qiyun_letter")) == 1 and int(inventory.call("count_of", &"qiyun_jade")) == 1, "letter and jade are each retained exactly once")


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
	for interaction: Dictionary in layout.interactions:
		if String(interaction.get("id", "")) == interaction_id:
			return String(interaction.get("action", ""))
	return ""


func _interaction_texture(layout: WalkableMapLayout, interaction_id: String) -> String:
	for interaction: Dictionary in layout.interactions:
		if String(interaction.get("id", "")) == interaction_id:
			return String(interaction.get("visual_texture", ""))
	return ""


func _portal_target(layout: WalkableMapLayout, portal_id: String) -> StringName:
	for portal: Dictionary in layout.portals:
		if String(portal.get("id", "")) == portal_id:
			return StringName(String(portal.get("target_scene", "")))
	return &""


func _node_sets_flag(node: DialogNode, flag_name: String) -> bool:
	for entry: Dictionary in node.set_flags:
		if String(entry.get("key", "")) == flag_name and bool(entry.get("value", false)):
			return true
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
