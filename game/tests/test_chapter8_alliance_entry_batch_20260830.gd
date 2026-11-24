extends SceneTree
var failures:=0
func _initialize():call_deferred("_run")
func _run():
	await process_frame
	var p:=load("res://data/chapters/chapter_8_content_plan.tres") as ChapterContentPlan
	var a:=load("res://data/scenes/ch8_s1_alliance_staging_ground.tres") as SceneScript
	var b:=load("res://data/scenes/ch8_s2_mistwood_blockade.tres") as SceneScript
	_check(p!=null and p.main_scene_ids.size()>=2 and p.main_quest_ids.size()>=2 and p.story_battle_groups.size()>=1,"chapter eight retains its alliance entry scenes, quests and anchor")
	_check(_uses_modular_art(a) and a.on_enter_require_flag==&"chapter7_complete","alliance entry uses formal art and chapter-seven gate")
	_check(_uses_modular_art(b),"mistwood blockade uses formal art")
	var g:=load("res://data/enemies/ch8_mistwood_blockade_guard.tres") as EnemyDef;var s:=load("res://data/enemies/ch8_mistwood_signal_burner.tres") as EnemyDef
	_check(g.level==13 and s.level==13 and g.attack>=120 and s.attack>=115,"mistwood enemies use chapter-eight current-scale stats")
	var d:=load("res://data/dialogs/ch8_mistwood_prebattle.tres") as DialogScript
	_check(d.nodes[0].on_end.contains("ch8_mistwood_blockade_guard,ch8_mistwood_signal_burner"),"mistwood dialogue owns the formal battle group")
	_check(root.get_node("SceneRouter").call("get_chapter_entry",8)==&"ch8_s1_alliance_staging_ground","chapter seven settlement enters chapter eight")
	print("[Chapter8AllianceEntry20260830] failures=%d"%failures);quit(1 if failures else 0)
func _uses_modular_art(scene: SceneScript) -> bool:
	return scene != null and scene.streamed_background != null and scene.map_layout != null and not scene.map_layout.visual_objects.is_empty()

func _check(ok:bool,msg:String):
	if ok:print("[PASS] %s"%msg)
	else:failures+=1;push_error("[FAIL] %s"%msg)
