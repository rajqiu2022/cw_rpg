extends SceneTree
var failures:=0
func _initialize():call_deferred("_run")
func _run():
	await process_frame
	var p:=load("res://data/chapters/chapter_8_content_plan.tres") as ChapterContentPlan
	var s:=load("res://data/scenes/ch8_s5_alliance_ceremonial_platform.tres") as SceneScript
	_check(p.main_quest_ids.size()>=7 and p.story_battle_groups.size()>=3,"chapter eight retains the Su confrontation quest and its prior anchors")
	_check(FileAccess.file_exists("res://art/characters/portraits/portrait_su_wusheng_ch8_v1.png"),"Su Wusheng owns canonical portrait")
	_check(s.npcs.any(func(n:Dictionary):return String(n.get("npc_id",""))=="ch8_su_wusheng" and String(n.get("portrait_path",""))=="res://art/characters/portraits/portrait_su_wusheng_ch8_v1.png"),"platform uses Su Wusheng identity")
	var d:=load("res://data/dialogs/ch8_su_first_confrontation.tres") as DialogScript
	var c:=d.find_node_by_id(&"choice");var end:=d.find_node_by_id(&"converge")
	_check(c.choices.size()==3,"first confrontation offers save, evidence and motive methods")
	_check(end.complete_quest==&"q_ch8_main_07_su_first_confrontation","all confrontation methods converge")
	print("[Chapter8SuConfrontation20260830] failures=%d"%failures);quit(1 if failures else 0)
func _check(ok:bool,msg:String):
	if ok:print("[PASS] %s"%msg)
	else:failures+=1;push_error("[FAIL] %s"%msg)
