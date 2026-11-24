extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	await process_frame
	var plan := load("res://data/chapters/chapter_7_content_plan.tres") as ChapterContentPlan
	var q6 := load("res://data/quests/q_ch7_main_06_threefold_identity_check.tres") as QuestDef
	var q7 := load("res://data/quests/q_ch7_main_07_confirm_xueying_identity.tres") as QuestDef
	_check(plan != null and plan.main_scene_ids.size() >= 10 and plan.main_quest_ids.size() >= 7, "chapter seven retains the ten-scene identity-confirmation slice")
	_check(plan.story_battle_groups.size() >= 1, "identity confirmation retains its prior anchors without adding a battle of its own")
	_check(q6 != null and q6.require_all_completion_triggers and q6.completion_triggers.size() == 3, "identity check requires authorization, direct recognition and route continuity")
	_check(q7 != null and q7.completion_triggers.size() == 1 and q7.completion_triggers[0] == "flag_set:ch7_xueying_identity_confirmed", "formal identity quest completes only on the explicit conclusion flag")
	var seal := load("res://data/investigation/evidence/ev_ch7_mingwu_counterseal_chain.tres") as EvidenceDef
	var route := load("res://data/investigation/evidence/ev_ch7_posthumous_route_timeline.tres") as EvidenceDef
	var witness := load("res://data/investigation/testimonies/ts_ch7_mingwu_instructor_recognized_xueying.tres") as TestimonyDef
	_check(seal != null and seal.description.contains("正式授权"), "counterseals establish internal authorization")
	_check(route != null and route.description.contains("没有足够时间交接身份"), "route timeline establishes one continuous user")
	_check(witness != null and witness.statement.contains("认出") and witness.statement.contains("必须与"), "instructor directly recognizes Xueying but requires corroboration")
	var conclusion := load("res://data/dialogs/ch7_xueying_identity_conclusion.tres") as DialogScript
	var confirm := conclusion.find_node_by_id(&"confirm") if conclusion != null else null
	_check(confirm != null and confirm.accept_quest == &"q_ch7_main_07_confirm_xueying_identity" and confirm.complete_quest == &"q_ch7_main_07_confirm_xueying_identity", "formal conclusion owns the identity quest settlement")
	_check(_sets(confirm, "ch7_xueying_identity_confirmed"), "formal conclusion persists confirmed identity")
	await _runtime()
	print("[Chapter7ActualUserConfirmation20260830] failures=%d" % failures)
	quit(1 if failures > 0 else 0)
func _runtime() -> void:
	var gs := root.get_node("GameState"); var qm := root.get_node("QuestManager"); var inv := root.get_node("InvestigationState")
	gs.call("reset_for_new_game"); qm.call("reset_for_new_game"); inv.call("reset_for_new_game")
	_check(bool(qm.call("accept", &"q_ch7_main_06_threefold_identity_check")), "threefold identity quest can be accepted")
	inv.call("acquire_evidence", &"ev_ch7_mingwu_counterseal_chain", &"test"); inv.call("hear_testimony", &"ts_ch7_mingwu_instructor_recognized_xueying"); await process_frame
	_check(not bool(qm.call("is_completed", &"q_ch7_main_06_threefold_identity_check")), "two of three identity proofs never conclude identity")
	inv.call("acquire_evidence", &"ev_ch7_posthumous_route_timeline", &"test"); await process_frame
	_check(bool(qm.call("is_completed", &"q_ch7_main_06_threefold_identity_check")), "three aligned proofs complete identity checking")
	_check(bool(qm.call("accept", &"q_ch7_main_07_confirm_xueying_identity")), "formal identity quest can be accepted")
	gs.call("set_flag", &"ch7_xueying_identity_confirmed", true); await process_frame
	_check(bool(qm.call("is_completed", &"q_ch7_main_07_confirm_xueying_identity")), "explicit conclusion confirms actual user")
func _sets(node: DialogNode, key: String) -> bool:
	if node == null: return false
	for e: Dictionary in node.set_flags:
		if String(e.get("key", "")) == key and bool(e.get("value", false)): return true
	return false
func _check(ok: bool, message: String) -> void:
	if ok: print("[PASS] %s" % message)
	else: failures += 1; push_error("[FAIL] %s" % message)
