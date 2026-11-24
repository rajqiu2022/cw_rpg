extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var snow := load("res://data/scenes/ch5_s3_snow_pass.tres") as SceneScript
	var mine := load("res://data/scenes/ch5_s4_abandoned_mine.tres") as SceneScript
	var q3 := load("res://data/quests/q_ch5_main_03_snow_pass.tres") as QuestDef
	var q4 := load("res://data/quests/q_ch5_main_04_mine_survivor.tres") as QuestDef
	var testimony := load("res://data/investigation/testimonies/ts_ch5_old_case_survivor.tres") as TestimonyDef
	_check(snow != null and mine != null, "snow pass and abandoned mine scenes load")
	_check(q3 != null and q4 != null, "chapter five mid-route quests load")
	_check(testimony != null and testimony.chapter == 5, "old-case survivor testimony belongs to chapter five")
	if snow != null:
		_check(FileAccess.file_exists(snow.background_path) and snow.map_layout != null and _layout_probes_match(snow.map_layout), "snow pass background and navigation contract are valid")
		_check(_hotspot_action(snow, "突破雪岭截路者") == "dialog:ch5_snow_pass_battle", "snow pass uses authored pre-battle dialogue")
		_check(_exit_targets(snow, &"ch5_s2_grain_convoy_camp") and _exit_targets(snow, &"ch5_s4_abandoned_mine"), "snow pass connects convoy camp and mine bidirectionally")
	if mine != null:
		_check(FileAccess.file_exists(mine.background_path) and mine.map_layout != null and _layout_probes_match(mine.map_layout), "abandoned mine background and navigation contract are valid")
		_check(_hotspot_action(mine, "击退矿道灭口人") == "dialog:ch5_mine_hunter_battle", "mine encounter uses authored pre-battle dialogue")
		_check(_hotspot_action(mine, "询问旧案幸存者") == "dialog:ch5_mine_survivor_testimony", "survivor testimony is a separate post-battle interaction")
		_check(_exit_targets(mine, &"ch5_s3_snow_pass"), "mine returns to the snow pass")
	if q3 != null:
		_check(_quest_has_item(q3, &"gufeng_diamond_blade"), "snow pass quest grants a compatible purple blade")
		_check(&"snow_pass_returning_blade" in q3.reward_skills, "snow pass quest grants the matching blade technique")
	if q4 != null:
		_check(&"cold_ridge_guard_breath" in q4.reward_skills, "mine survivor quest grants the chapter-five internal art")
		_check("testimony_heard:ts_ch5_old_case_survivor" in q4.completion_triggers, "mine quest closes on testimony rather than combat alone")
	var blade_art := load("res://data/skills/snow_pass_returning_blade.tres") as Skill
	_check(blade_art != null and blade_art.quality == Skill.Quality.EPIC and blade_art.required_weapon_type == &"blade", "Snow Pass Returning Blade is a purple blade technique")
	_check(blade_art != null and BattleVfxPlayer.has_effect(blade_art.animation_id) and FileAccess.file_exists(blade_art.icon_path), "Snow Pass Returning Blade owns semantic icon and registered VFX")
	var mind := load("res://data/skills/cold_ridge_guard_breath.tres") as Skill
	_check(mind != null and mind.quality == Skill.Quality.EPIC and mind.is_internal_art, "Cold Ridge Guard Breath is a purple internal art")
	_check(mind != null and mind.active_effect_type == &"guard" and BattleVfxPlayer.has_effect(mind.animation_id) and FileAccess.file_exists(mind.icon_path), "Cold Ridge Guard Breath owns guard semantics, icon and VFX")
	var snow_battle := load("res://data/dialogs/ch5_snow_pass_battle.tres") as DialogScript
	var mine_battle := load("res://data/dialogs/ch5_mine_hunter_battle.tres") as DialogScript
	_check(_dialog_has_action(snow_battle, "battle_group_then:ch5_snow_pass_pursuer,ch5_false_liuyun_striker:ch5_snow_pass_victory"), "snow pass uses its formal two-enemy anchor")
	_check(_dialog_has_action(mine_battle, "battle_group_then:ch5_mine_tunnel_hunter,ch5_false_liuyun_striker:ch5_mine_hunter_victory"), "mine uses its formal two-enemy anchor")
	await _check_runtime_rewards()
	print("[Chapter5SnowMineSlice20260824] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check_runtime_rewards() -> void:
	var game_state := root.get_node("GameState")
	var inventory := root.get_node("Inventory")
	var quests := root.get_node("QuestManager")
	var investigation := root.get_node("InvestigationState")
	game_state.call("reset_for_new_game")
	inventory.call("reset_for_new_game")
	quests.call("reset_for_new_game")
	investigation.call("reset_for_new_game")
	_check(bool(quests.call("accept", &"q_ch5_main_03_snow_pass")), "snow pass quest can be accepted")
	game_state.call("set_flag", &"ch5_snow_pass_cleared", true)
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch5_main_03_snow_pass")), "snow pass quest completes on victory")
	_check(int(inventory.call("count_of", &"gufeng_diamond_blade")) == 1, "snow pass grants exactly one purple blade")
	var learned_blade: bool = &"snow_pass_returning_blade" in game_state.get("player").skills or &"snow_pass_returning_blade" in game_state.get("pending_skill_unlocks")
	_check(learned_blade, "snow pass learns or queues its blade technique")
	_check(bool(quests.call("accept", &"q_ch5_main_04_mine_survivor")), "mine survivor quest can be accepted")
	game_state.call("set_flag", &"ch5_mine_hunters_defeated", true)
	await process_frame
	_check(not bool(quests.call("is_completed", &"q_ch5_main_04_mine_survivor")), "mine combat alone does not skip survivor testimony")
	_check(bool(investigation.call("hear_testimony", &"ts_ch5_old_case_survivor")), "old-case survivor testimony can be heard")
	await process_frame
	_check(bool(quests.call("is_completed", &"q_ch5_main_04_mine_survivor")), "mine quest completes after testimony acquisition")
	var learned_mind: bool = &"cold_ridge_guard_breath" in game_state.get("player").skills or &"cold_ridge_guard_breath" in game_state.get("pending_skill_unlocks")
	_check(learned_mind, "mine testimony learns or queues Cold Ridge Guard Breath")


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


func _hotspot_action(scene: SceneScript, label: String) -> String:
	for hotspot: Dictionary in scene.hotspots:
		if String(hotspot.get("label", "")) == label:
			return String(hotspot.get("action", ""))
	return ""


func _exit_targets(scene: SceneScript, target: StringName) -> bool:
	for exit_data: Dictionary in scene.exits:
		if StringName(String(exit_data.get("target_scene", ""))) == target:
			return true
	return false


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
