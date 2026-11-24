extends SceneTree

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_8_content_plan.tres") as ChapterContentPlan
	var platform := load("res://data/scenes/ch8_s5_alliance_ceremonial_platform.tres") as SceneScript
	_check(plan.main_scene_ids.size() == 7 and plan.main_quest_ids.size() == 13 and plan.story_battle_groups.size() == 5, "chapter eight expands to thirteen main quests without adding a filler scene or battle")
	var registrar: Dictionary = {}
	for npc: Dictionary in platform.npcs:
		if String(npc.get("npc_id", "")) == "ch8_truth_disclosure_registrar":
			registrar = npc
			break
	_check(not registrar.is_empty() and String(registrar.get("require_quest_active", "")) == "q_ch8_main_12_truth_disclosure", "alliance platform hosts the post-boss disclosure registrar")
	var variants: Array = registrar.get("dialog_variants", [])
	_check(variants.size() == 3 and variants.all(func(v: Dictionary): return String(v.get("dialog_id", "")).begins_with("ch8_truth_disclosure_")), "registrar preserves all three chapter-seven disclosure strategies")
	for id in ["ch8_truth_disclosure_full", "ch8_truth_disclosure_staged", "ch8_truth_disclosure_joint"]:
		var dialog := load("res://data/dialogs/%s.tres" % id) as DialogScript
		var facts := dialog.find_node_by_id(&"facts")
		var arts := dialog.find_node_by_id(&"arts")
		var end := dialog.find_node_by_id(&"end")
		_check("烈云" in facts.text and "茗雾" in facts.text and "薛影" in facts.text and "苏雾笙" in facts.text, "all disclosure routes keep the same four verified responsibility sets: %s" % id)
		_check("危险" in arts.text and ("封" in arts.text or "拆" in arts.text), "route defines a concrete dangerous-art archive policy: %s" % id)
		_check(end.complete_quest == &"q_ch8_main_12_truth_disclosure" and end.accept_quest == &"q_ch8_main_13_aftermath_returns", "disclosure route converges into aftermath returns: %s" % id)
		_check(end.set_flags.any(func(entry: Dictionary): return String(entry.get("key", "")) == "ch8_evidence_multi_copy") and end.set_flags.any(func(entry: Dictionary): return String(entry.get("key", "")) == "ch8_truth_disclosure_settled"), "route creates multi-party copies and settles disclosure: %s" % id)
		_check(end.on_end == "end", "disclosure does not prematurely claim chapter-eight epilogues are complete: %s" % id)
	var aftermath := load("res://data/quests/q_ch8_main_13_aftermath_returns.tres") as QuestDef
	_check(aftermath != null and aftermath.require_all_completion_triggers and aftermath.completion_triggers.has("flag_set:ch8_linxi_final_return_done"), "aftermath quest remains the explicit multi-milestone final settlement gate")
	var quest_manager := root.get_node("QuestManager")
	var game_state := root.get_node("GameState")
	quest_manager.reset_for_new_game()
	quest_manager.accept(&"q_ch8_main_12_truth_disclosure")
	game_state.set_flag(&"ch8_truth_disclosure_settled", true)
	_check(quest_manager.is_completed(&"q_ch8_main_12_truth_disclosure"), "truth-disclosure quest completes from runtime settlement flag")
	print("[Chapter8TruthDisclosure20260831] failures=%d" % failures)
	quit(1 if failures else 0)


func _check(ok: bool, message: String) -> void:
	if ok:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
