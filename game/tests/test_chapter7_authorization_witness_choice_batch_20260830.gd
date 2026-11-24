extends SceneTree
var failures := 0
func _initialize(): call_deferred("_run")
func _run():
	await process_frame
	var p:=load("res://data/chapters/chapter_7_content_plan.tres") as ChapterContentPlan
	var q8:=load("res://data/quests/q_ch7_main_08_inner_office_authorization.tres") as QuestDef
	var q9:=load("res://data/quests/q_ch7_main_09_protect_witnesses.tres") as QuestDef
	_check(p.main_scene_ids.size()==10 and p.main_quest_ids.size()==9,"chapter seven keeps ten scenes and expands to nine quests")
	_check(p.story_battle_groups.size()==1,"authorization batch adds no battle")
	_check(q8.require_all_completion_triggers and q8.completion_triggers.size()==2,"authorization requires order and route objectives")
	_check(q8.desc_completed.contains("个人签发"),"institutional authorization does not fake a personal signature")
	var choice:=load("res://data/dialogs/ch7_witness_protection_choice.tres") as DialogScript
	var c:=choice.find_node_by_id(&"choice"); var end:=choice.find_node_by_id(&"converge")
	_check(c!=null and c.choices.size()==3,"witness protection offers three methods")
	_check(end!=null and end.complete_quest==&"q_ch7_main_09_protect_witnesses" and _sets(end,"ch7_witness_protection_resolved"),"all methods converge on persistent settlement")
	_check(q9.completion_triggers.size()==1 and q9.completion_triggers[0]=="flag_set:ch7_witness_protection_resolved","witness quest requires explicit protection resolution")
	await _runtime()
	print("[Chapter7AuthorizationWitnessChoice20260830] failures=%d"%failures);quit(1 if failures else 0)
func _runtime():
	var gs:=root.get_node("GameState");var qm:=root.get_node("QuestManager");var inv:=root.get_node("InvestigationState")
	gs.call("reset_for_new_game");qm.call("reset_for_new_game");inv.call("reset_for_new_game")
	_check(qm.call("accept",&"q_ch7_main_08_inner_office_authorization"),"authorization quest accepts")
	inv.call("acquire_evidence",&"ev_ch7_inner_office_authorization",&"test");await process_frame
	_check(not qm.call("is_completed",&"q_ch7_main_08_inner_office_authorization"),"one authorization document never completes motive")
	inv.call("acquire_evidence",&"ev_ch7_xueying_retrieval_objectives",&"test");await process_frame
	_check(qm.call("is_completed",&"q_ch7_main_08_inner_office_authorization"),"order and objectives complete authorization motive")
	_check(qm.call("accept",&"q_ch7_main_09_protect_witnesses"),"witness protection quest accepts")
	gs.call("set_flag",&"ch7_witness_protection_resolved",true);await process_frame
	_check(qm.call("is_completed",&"q_ch7_main_09_protect_witnesses"),"protection resolution completes witness quest")
func _sets(n:DialogNode,k:String)->bool:
	for e:Dictionary in n.set_flags:
		if String(e.get("key",""))==k and bool(e.get("value",false)):return true
	return false
func _check(ok:bool,msg:String):
	if ok:print("[PASS] %s"%msg)
	else:failures+=1;push_error("[FAIL] %s"%msg)
