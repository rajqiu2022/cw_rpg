extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_8_content_plan.tres") as ChapterContentPlan
	var scene := load("res://data/scenes/ch8_s6_mingwu_main_hall.tres") as SceneScript
	var layout := load("res://data/maps/ch8_s6_mingwu_main_hall_layout_v1.tres") as WalkableMapLayout
	_check(plan.main_scene_ids.size() >= 6 and plan.main_quest_ids.size() >= 9 and plan.story_battle_groups.size() >= 3, "chapter eight retains the main hall and evacuation slice")
	_check(scene != null and scene.is_walkable and FileAccess.file_exists(scene.background_path), "Mingwu main hall uses formal walkable scene art")
	_check(layout.portals.any(func(p: Dictionary): return String(p.get("target_scene", "")) == "ch8_s5_alliance_ceremonial_platform"), "main hall returns to alliance platform")
	_check(scene.npcs.any(func(n: Dictionary): return String(n.get("npc_id", "")) == "ch8_su_wusheng_main_hall" and String(n.get("portrait_path", "")) == "res://art/characters/portraits/portrait_su_wusheng_ch8_v1.png"), "Su Wusheng keeps canonical identity")
	_check(scene.npcs.any(func(n: Dictionary): return String(n.get("npc_id", "")) == "ch8_xueying_main_hall" and String(n.get("portrait_path", "")) == "res://art/characters/portraits/portrait_xueying_ch8_v1.png"), "Xueying uses unique canonical identity")
	var authorization := load("res://data/dialogs/ch8_su_xueying_authorization.tres") as DialogScript
	var choice := authorization.find_node_by_id(&"choice")
	var converge := authorization.find_node_by_id(&"converge")
	_check(choice.choices.size() == 3, "authorization confrontation supports testimony, responsibility and rescue methods")
	_check(converge.complete_quest == &"q_ch8_main_08_su_xueying_authorization" and converge.accept_quest == &"q_ch8_main_09_final_evacuation", "authorization converges into final evacuation")
	var testimony := load("res://data/investigation/testimonies/ts_ch8_xueying_personal_orders.tres") as TestimonyDef
	_check(testimony != null and testimony.related_evidence_ids.has(&"ev_ch7_su_personal_signed_directive"), "Xueying testimony is a formal investigation resource cross-linked to the signed directive")
	for id in ["ch8_final_evacuation_split", "ch8_final_evacuation_public", "ch8_final_evacuation_luoyang"]:
		var dialog := load("res://data/dialogs/%s.tres" % id) as DialogScript
		var done := dialog.find_node_by_id(&"done")
		_check(done.complete_quest == &"q_ch8_main_09_final_evacuation" and done.set_flags.any(func(entry: Dictionary): return String(entry.get("key", "")) == "ch8_rear_sanctum_unlocked"), "evacuation route converges and unlocks rear sanctum: %s" % id)
	var quest_manager := root.get_node("QuestManager")
	var game_state := root.get_node("GameState")
	quest_manager.reset_for_new_game()
	quest_manager.accept(&"q_ch8_main_08_su_xueying_authorization")
	game_state.set_flag(&"ch8_su_xueying_authorization_exposed", true)
	_check(quest_manager.is_completed(&"q_ch8_main_08_su_xueying_authorization"), "authorization quest completes from runtime flag")
	quest_manager.accept(&"q_ch8_main_09_final_evacuation")
	game_state.set_flag(&"ch8_final_evacuation_complete", true)
	_check(quest_manager.is_completed(&"q_ch8_main_09_final_evacuation"), "evacuation quest completes from runtime flag")
	print("[Chapter8MainHallEvacuation20260830] failures=%d" % failures)
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
