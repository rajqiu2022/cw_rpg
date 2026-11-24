extends SceneTree
var failures:=0
func _initialize():call_deferred("_run")
func _run():
	await process_frame
	var p:=load("res://data/chapters/chapter_8_content_plan.tres") as ChapterContentPlan
	var s:=load("res://data/scenes/ch8_s5_alliance_ceremonial_platform.tres") as SceneScript
	_check(p.main_scene_ids.size()>=5 and p.main_quest_ids.size()>=6 and p.story_battle_groups.size()>=3,"chapter eight retains its platform scenes, quests and three anchors")
	_check(s!=null and FileAccess.file_exists(s.background_path) and s.npcs.any(func(n:Dictionary):return String(n.get("npc_id",""))=="ch8_alliance_registrar") and s.npcs.any(func(n:Dictionary):return String(n.get("npc_id",""))=="ch8_false_order_courier_field"),"platform uses formal art, registrar and courier")
	for id in ["ch8_roles_split","ch8_roles_public","ch8_roles_luoyang"]:
		var d:=load("res://data/dialogs/%s.tres"%id) as DialogScript
		_check(d.nodes[0].complete_quest==&"q_ch8_main_05_final_alliance_roles" and d.nodes[0].accept_quest==&"q_ch8_main_06_first_false_order","role branch converges and opens courier: %s"%id)
	var g:=load("res://data/enemies/ch8_false_order_courier.tres") as EnemyDef;var e:=load("res://data/enemies/ch8_false_order_escort.tres") as EnemyDef
	_check(g.level==14 and e.level==14 and g.max_hp>e.max_hp,"false-order battle has distinct courier and escort roles")
	print("[Chapter8PlatformRoles20260830] failures=%d"%failures);quit(1 if failures else 0)
func _check(ok:bool,msg:String):
	if ok:print("[PASS] %s"%msg)
	else:failures+=1;push_error("[FAIL] %s"%msg)
