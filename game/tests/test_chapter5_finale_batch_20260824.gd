extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var scene := load("res://data/scenes/ch5_s5_false_banner_outpost.tres") as SceneScript
	var q5 := load("res://data/quests/q_ch5_main_05_false_banner_outpost.tres") as QuestDef
	var q6 := load("res://data/quests/q_ch5_main_06_disclosure_choice.tres") as QuestDef
	var poison_blade := load("res://data/investigation/evidence/ev_ch5_poisoned_false_banner_blade.tres") as EvidenceDef
	var sealed_orders := load("res://data/investigation/evidence/ev_ch5_captain_sealed_orders.tres") as EvidenceDef
	_check(scene != null and q5 != null and q6 != null, "chapter-five finale scene and quests load")
	_check(poison_blade != null and sealed_orders != null and poison_blade.chapter == 5 and sealed_orders.chapter == 5, "finale evidence belongs to chapter five")
	if scene != null:
		_check(FileAccess.file_exists(scene.background_path) and scene.map_layout != null and _layout_probes_match(scene.map_layout), "outpost background and navigation contract are valid")
		_check(_exit_targets(scene, &"ch5_s4_abandoned_mine"), "outpost returns to the abandoned mine")
		_check(_interaction_action(scene.map_layout, "inspect_poisoned_weapons") == "dialog:ch5_false_banner_poisoned_weapons", "visible weapon evidence gates the boss approach")
		_check(_npc_dialog(scene, "ch5_false_banner_captain") == "ch5_false_banner_boss_prebattle", "captain starts with authored pre-battle dialogue")
		_check(_npc_dialog(scene, "ch5_false_banner_captain_wounded") == "ch5_false_banner_captain_followup", "wounded captain remains available after the battle")
		_check(_npc_sprite(scene, "ch5_false_banner_captain") != _npc_sprite(scene, "ch5_false_banner_captain_wounded"), "standing and wounded captain use distinct runtime art")
	var mine := load("res://data/scenes/ch5_s4_abandoned_mine.tres") as SceneScript
	_check(mine != null and _exit_targets(mine, &"ch5_s5_false_banner_outpost"), "mine and outpost form a bidirectional edge")
	if q5 != null:
		_check(q5.require_all_completion_triggers, "outpost quest requires both investigation and combat")
		_check("evidence_acquired:ev_ch5_poisoned_false_banner_blade" in q5.completion_triggers and "flag_set:ch5_false_banner_captain_defeated" in q5.completion_triggers, "outpost quest cannot skip the weapon clue or boss")
	if q6 != null:
		_check("flag_set:ch5_disclosure_choice_made" in q6.completion_triggers, "chapter closes on the disclosure decision")
	var boss := load("res://data/enemies/ch5_false_banner_captain.tres") as EnemyDef
	_check(boss != null and boss.is_chapter_boss, "false-banner captain is the chapter-five boss")
	_check(boss != null and FileAccess.file_exists(boss.portrait_path) and FileAccess.file_exists(boss.battle_actor_path), "captain owns project-local portrait and battle art")
	_check(boss != null and not boss.ready_frame_paths.is_empty() and not boss.attack_frame_paths.is_empty() and not boss.hit_frame_paths.is_empty() and not boss.defeat_frame_paths.is_empty(), "captain owns all battle animation states")
	var battle := load("res://data/dialogs/ch5_false_banner_boss_prebattle.tres") as DialogScript
	_check(_dialog_has_action(battle, "battle_group_then:ch5_false_banner_captain,ch5_false_liuyun_striker,ch5_false_liuyun_striker:ch5_false_banner_boss_victory"), "boss uses the formal three-enemy anchor")
	var victory := load("res://data/dialogs/ch5_false_banner_boss_victory.tres") as DialogScript
	_check(_dialog_adds_evidence(victory, &"ev_ch5_captain_sealed_orders") and _dialog_accepts(victory, &"q_ch5_main_06_disclosure_choice"), "victory secures orders and opens the disclosure decision")
	var choice := load("res://data/dialogs/ch5_disclosure_choice.tres") as DialogScript
	_check(_choice_contract(choice), "disclosure choice has two persistent methods and a shared convergence flag")
	_check(_dialog_sets_flag(choice, &"chapter5_complete") and _dialog_has_action(choice, "chapter_end:5"), "both choice branches converge on chapter-five completion")
	var chapter_plan := load("res://data/chapters/chapter_5_content_plan.tres") as ChapterContentPlan
	_check(chapter_plan != null and chapter_plan.main_scene_ids.size() == 5 and chapter_plan.main_quest_ids.size() == 6, "chapter-five plan owns the complete five-scene six-quest chain")
	_check(_storyline_marks_chapter_five_implemented(), "story catalogue marks chapter five implemented with current quest ids")
	var chapter_end_source := FileAccess.get_file_as_string("res://scripts/ui/chapter_end.gd")
	_check(chapter_end_source.contains('5: "第五章 · 古峰残雪"'), "chapter end names the fifth chapter")
	await _check_runtime_completion()
	print("[Chapter5Finale20260824] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_runtime_completion() -> void:
	var game_state := root.get_node("GameState")
	var quests := root.get_node("QuestManager")
	var investigation := root.get_node("InvestigationState")
	game_state.call("reset_for_new_game")
	quests.call("reset_for_new_game")
	investigation.call("reset_for_new_game")
	_check(bool(quests.call("accept", &"q_ch5_main_05_false_banner_outpost")), "outpost quest can be accepted")
	game_state.call("set_flag", &"ch5_false_banner_captain_defeated", true)
	await process_frame
	_check(not bool(quests.call("is_completed", &"q_ch5_main_05_false_banner_outpost")), "boss defeat alone cannot skip the weapon clue")
	_check(bool(investigation.call("acquire_evidence", &"ev_ch5_poisoned_false_banner_blade", &"ch5_s5_false_banner_outpost")), "poisoned weapon evidence can be acquired")
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch5_main_05_false_banner_outpost")), "outpost quest completes after both required facts")
	_check(bool(quests.call("accept", &"q_ch5_main_06_disclosure_choice")), "disclosure quest can be accepted")
	game_state.call("set_flag", &"ch5_disclosure_choice_made", true)
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch5_main_06_disclosure_choice")), "disclosure quest completes after a method is chosen")


func _layout_probes_match(layout: WalkableMapLayout) -> bool:
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
	for entry: Dictionary in layout.interactions:
		if String(entry.get("id", "")) == interaction_id:
			return String(entry.get("action", ""))
	return ""


func _exit_targets(scene: SceneScript, target: StringName) -> bool:
	for exit_data: Dictionary in scene.exits:
		if StringName(String(exit_data.get("target_scene", ""))) == target:
			return true
	return false


func _npc_dialog(scene: SceneScript, npc_id: String) -> String:
	for npc: Dictionary in scene.npcs:
		if String(npc.get("npc_id", "")) == npc_id:
			return String(npc.get("dialog_id", ""))
	return ""


func _npc_sprite(scene: SceneScript, npc_id: String) -> String:
	for npc: Dictionary in scene.npcs:
		if String(npc.get("npc_id", "")) == npc_id:
			return String(npc.get("sprite_path", ""))
	return ""


func _dialog_has_action(dialog: DialogScript, action: String) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node.on_end == action:
			return true
	return false


func _dialog_adds_evidence(dialog: DialogScript, evidence_id: StringName) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if evidence_id in node.add_evidence:
			return true
	return false


func _dialog_accepts(dialog: DialogScript, quest_id: StringName) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node.accept_quest == quest_id:
			return true
	return false


func _choice_contract(dialog: DialogScript) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		if node.choices.size() != 2:
			continue
		var immediate := node.choices[0] as Dictionary
		var delayed := node.choices[1] as Dictionary
		var immediate_flags := immediate.get("method_flags", []) as Array
		var delayed_flags := delayed.get("method_flags", []) as Array
		var immediate_set := immediate.get("set_flag", {}) as Dictionary
		var delayed_set := delayed.get("set_flag", {}) as Dictionary
		return (
			_method_has(immediate_flags, "ch5_publish_partial_evidence")
			and _method_has(delayed_flags, "ch5_hold_evidence_for_witnesses")
			and bool(immediate_set.get("ch5_disclosure_choice_made", false))
			and bool(delayed_set.get("ch5_disclosure_choice_made", false))
		)
	return false


func _method_has(entries: Array, key: String) -> bool:
	for raw: Variant in entries:
		if raw is Dictionary and String((raw as Dictionary).get("key", "")) == key:
			return true
	return false


func _dialog_sets_flag(dialog: DialogScript, flag_id: StringName) -> bool:
	if dialog == null:
		return false
	for node: DialogNode in dialog.nodes:
		for entry: Dictionary in node.set_flags:
			if StringName(String(entry.get("key", ""))) == flag_id and bool(entry.get("value", false)):
				return true
	return false


func _storyline_marks_chapter_five_implemented() -> bool:
	var path := "res://../docs/storyline-data.json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return false
	for raw: Variant in (parsed as Dictionary).get("chapters", []):
		var chapter := raw as Dictionary
		if int(chapter.get("number", 0)) == 5:
			var ids := chapter.get("mainQuestIds", []) as Array
			return String(chapter.get("implementation", "")) == "implemented" and ids.size() == 6
	return false


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
