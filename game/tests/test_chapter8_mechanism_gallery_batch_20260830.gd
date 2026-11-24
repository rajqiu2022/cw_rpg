extends SceneTree
var failures:=0
func _initialize():call_deferred("_run")
func _run():
	await process_frame
	var p:=load("res://data/chapters/chapter_8_content_plan.tres") as ChapterContentPlan
	var s:=load("res://data/scenes/ch8_s4_alliance_mechanism_gallery.tres") as SceneScript
	var q:=load("res://data/quests/q_ch8_main_04_drum_mist_mechanisms.tres") as QuestDef
	_check(p.main_scene_ids.size()>=4 and p.main_quest_ids.size()>=4 and p.story_battle_groups.size()>=2,"chapter eight retains its mechanism-gallery scenes, quests and anchors")
	_check(s!=null and FileAccess.file_exists(s.background_path),"mechanism gallery uses formal background")
	_check(q.require_all_completion_triggers and q.completion_triggers.size()==3,"mechanism quest requires battle, drum and mist")
	var g:=load("res://data/enemies/ch8_mechanism_warden.tres") as EnemyDef;var m:=load("res://data/enemies/ch8_mist_valve_keeper.tres") as EnemyDef
	_check(g.level==14 and m.level==14 and g.attack>=130 and m.speed>=38,"mechanism enemies use level-fourteen roles")
	await _runtime()
	print("[Chapter8MechanismGallery20260830] failures=%d"%failures);quit(1 if failures else 0)
func _runtime():
	var gs:=root.get_node("GameState");var qm:=root.get_node("QuestManager")
	gs.call("reset_for_new_game");qm.call("reset_for_new_game");_check(qm.call("accept",&"q_ch8_main_04_drum_mist_mechanisms"),"mechanism quest accepts")
	gs.call("set_flag",&"ch8_mechanism_guards_defeated",true);gs.call("set_flag",&"ch8_false_drum_disabled",true);await process_frame
	_check(not qm.call("is_completed",&"q_ch8_main_04_drum_mist_mechanisms"),"battle and drum do not replace mist shutdown")
	gs.call("set_flag",&"ch8_mist_vents_disabled",true);await process_frame
	_check(qm.call("is_completed",&"q_ch8_main_04_drum_mist_mechanisms"),"all three beats complete mechanism quest")
func _check(ok:bool,msg:String):
	if ok:print("[PASS] %s"%msg)
	else:failures+=1;push_error("[FAIL] %s"%msg)
