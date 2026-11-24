extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_8_content_plan.tres") as ChapterContentPlan
	var scene := load("res://data/scenes/ch8_s7_mingwu_rear_sanctum.tres") as SceneScript
	_check(plan.main_scene_ids.size() >= 7 and plan.main_quest_ids.size() >= 12 and plan.story_battle_groups.size() >= 5, "chapter eight retains the Su final-boss slice")
	var su_npc: Dictionary = {}
	for npc: Dictionary in scene.npcs:
		if String(npc.get("npc_id", "")) == "ch8_su_wusheng_final":
			su_npc = npc
			break
	_check(not su_npc.is_empty() and String(su_npc.get("require_quest_active", "")) == "q_ch8_main_11_su_final_order", "Su Wusheng appears only for the final-order quest")
	var variants: Array = su_npc.get("dialog_variants", [])
	_check(String(su_npc.get("dialog_id", "")) == "ch8_su_final_prelude_dead" and variants.size() == 3, "Su prelude reads Mingwu, testimony, surrender and dead-battle contexts")
	for id in ["ch8_su_final_prelude_dead", "ch8_su_final_prelude_surrender", "ch8_su_final_prelude_testify", "ch8_su_final_prelude_mingwu"]:
		var prelude := load("res://data/dialogs/%s.tres" % id) as DialogScript
		_check(prelude.nodes[0].on_end == "dialog:ch8_su_final_common", "context prelude converges into final order: %s" % id)
	var common := load("res://data/dialogs/ch8_su_final_common.tres") as DialogScript
	var master := common.find_node_by_id(&"master")
	var battle := common.find_node_by_id(&"battle")
	_check(master.set_flags.any(func(entry: Dictionary): return String(entry.get("key", "")) == "ch8_second_bell_isolated"), "Xing Fantian explicitly isolates the second bell")
	_check(battle.on_end == "battle_group_then:ch8_su_wusheng_final:ch8_su_final_victory", "third-bell confrontation starts dedicated Su boss")
	var enemy := load("res://data/enemies/ch8_su_wusheng_final.tres") as EnemyDef
	_check(enemy != null and enemy.level == 16 and enemy.is_chapter_boss and enemy.max_hp >= 2600 and enemy.skill_ids.has(&"ch8_su_teapot_meridian_rain"), "Su Wusheng is a level-sixteen final boss with a unique teapot technique")
	_check(enemy.ready_frame_paths.size() == 4 and enemy.move_frame_paths.size() == 4 and enemy.attack_frame_paths.size() == 4 and enemy.hit_frame_paths.size() == 4 and enemy.defeat_frame_paths.size() == 4, "Su Wusheng owns four frames for all five battle states")
	var alpha_ok := true
	for path in enemy.ready_frame_paths + enemy.move_frame_paths + enemy.attack_frame_paths + enemy.hit_frame_paths + enemy.defeat_frame_paths:
		if not FileAccess.file_exists(path):
			alpha_ok = false
			break
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or not image.detect_alpha():
			alpha_ok = false
			break
	_check(alpha_ok, "all twenty Su Wusheng battle frames are true-alpha runtime assets")
	for dialog_id in ["ch8_xueying_resolution_choice", "ch8_xueying_battle_victory"]:
		var dialog := load("res://data/dialogs/%s.tres" % dialog_id) as DialogScript
		_check(dialog.nodes.any(func(node: DialogNode): return node.accept_quest == &"q_ch8_main_11_su_final_order"), "Xueying outcome opens final order: %s" % dialog_id)
	var victory := load("res://data/dialogs/ch8_su_final_victory.tres") as DialogScript
	var end := victory.find_node_by_id(&"end")
	_check(end.complete_quest == &"q_ch8_main_11_su_final_order" and end.accept_quest == &"q_ch8_main_12_truth_disclosure", "boss victory opens the truth-disclosure quest")
	_check(end.set_flags.any(func(entry: Dictionary): return String(entry.get("key", "")) == "ch8_su_alive" and bool(entry.get("value", false))), "boss victory captures Su alive for evidence disclosure")
	var quest_manager := root.get_node("QuestManager")
	quest_manager.reset_for_new_game()
	quest_manager.accept(&"q_ch8_main_11_su_final_order")
	quest_manager.call("_on_enemy_defeated", &"ch8_su_wusheng_final")
	_check(quest_manager.is_completed(&"q_ch8_main_11_su_final_order"), "final-order quest completes from runtime boss defeat")
	print("[Chapter8SuFinalBoss20260830] failures=%d" % failures)
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
