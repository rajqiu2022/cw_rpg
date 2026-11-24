extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_8_content_plan.tres") as ChapterContentPlan
	var scene := load("res://data/scenes/ch8_s7_mingwu_rear_sanctum.tres") as SceneScript
	var layout := load("res://data/maps/ch8_s7_mingwu_rear_sanctum_layout_v1.tres") as WalkableMapLayout
	_check(plan.main_scene_ids.size() >= 7 and plan.main_quest_ids.size() >= 10 and plan.story_battle_groups.size() >= 4, "chapter eight retains the rear-sanctum Xueying resolution slice")
	_check(scene != null and scene.is_walkable and FileAccess.file_exists(scene.background_path), "rear sanctum uses formal walkable art")
	_check(layout.portals.any(func(p: Dictionary): return String(p.get("target_scene", "")) == "ch8_s6_mingwu_main_hall"), "rear sanctum returns to main hall")
	var main_layout := load("res://data/maps/ch8_s6_mingwu_main_hall_layout_v1.tres") as WalkableMapLayout
	_check(main_layout.portals.any(func(p: Dictionary): return String(p.get("target_scene", "")) == "ch8_s7_mingwu_rear_sanctum" and String(p.get("require_flag", "")) == "ch8_rear_sanctum_unlocked"), "main hall opens rear sanctum only after evacuation")
	var xueying_npc: Dictionary = scene.npcs[0]
	var variants: Array = xueying_npc.get("dialog_variants", [])
	_check(String(xueying_npc.get("dialog_id", "")) == "ch8_xueying_forced_battle" and variants.size() == 1 and (variants[0] as Dictionary).get("require_flags", []).size() == 3, "evidence and evacuation unlock voluntary Xueying resolutions; fallback is forced battle")
	var choice_dialog := load("res://data/dialogs/ch8_xueying_resolution_choice.tres") as DialogScript
	var choice := choice_dialog.find_node_by_id(&"choice")
	_check(choice.choices.size() == 3, "Xueying resolution offers surrender, testimony and dead battle")
	for node_id in [&"surrender_end", &"testify_end"]:
		var node := choice_dialog.find_node_by_id(node_id)
		_check(node.complete_quest == &"q_ch8_main_10_xueying_resolution" and node.set_flags.any(func(entry: Dictionary): return String(entry.get("key", "")) == "ch8_final_su_gate_open"), "noncombat resolution completes quest and opens final Su gate: %s" % node_id)
	var battle_node := choice_dialog.find_node_by_id(&"battle")
	_check(battle_node.on_end == "battle_group_then:ch8_xueying_last_guard:ch8_xueying_battle_victory", "dead-battle choice uses dedicated Xueying anchor")
	var victory := load("res://data/dialogs/ch8_xueying_battle_victory.tres") as DialogScript
	_check(victory.find_node_by_id(&"end").complete_quest == &"q_ch8_main_10_xueying_resolution", "dead-battle victory converges into the same quest")
	var enemy := load("res://data/enemies/ch8_xueying_last_guard.tres") as EnemyDef
	_check(enemy != null and enemy.level == 15 and enemy.is_chapter_boss and enemy.max_hp >= 1800, "Xueying is a level-fifteen formal boss anchor")
	_check(enemy.ready_frame_paths.size() == 4 and enemy.move_frame_paths.size() == 4 and enemy.attack_frame_paths.size() == 4 and enemy.hit_frame_paths.size() == 4 and enemy.defeat_frame_paths.size() == 4, "Xueying owns four frames for all five battle states")
	var alpha_ok := true
	for path in enemy.ready_frame_paths + enemy.move_frame_paths + enemy.attack_frame_paths + enemy.hit_frame_paths + enemy.defeat_frame_paths:
		if not FileAccess.file_exists(path):
			alpha_ok = false
			break
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or not image.detect_alpha():
			alpha_ok = false
			break
	_check(alpha_ok, "all twenty Xueying battle frames are true-alpha runtime assets")
	var scene_router := root.get_node("SceneRouter")
	_check(StringName(scene_router.call("_battle_arena_for_scene", &"ch8_s7_mingwu_rear_sanctum")) == &"mingwu_sanctum", "rear sanctum selects its dedicated battle arena")
	var quest_manager := root.get_node("QuestManager")
	var game_state := root.get_node("GameState")
	quest_manager.reset_for_new_game()
	quest_manager.accept(&"q_ch8_main_10_xueying_resolution")
	game_state.set_flag(&"ch8_xueying_resolution_done", true)
	_check(quest_manager.is_completed(&"q_ch8_main_10_xueying_resolution"), "Xueying resolution quest completes from runtime outcome flag")
	print("[Chapter8XueyingResolution20260830] failures=%d" % failures)
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
