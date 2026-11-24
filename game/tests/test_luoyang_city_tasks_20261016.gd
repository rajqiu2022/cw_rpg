extends SceneTree
## Pure-state/real DialogPlayer key; NOT Field, Physics, reachability or art acceptance.
const T = preload("res://scripts/city/luoyang_city_tasks_20261016.gd")
const PREFIX := "luoyang_city_tasks_20261016/"
var dp: Node
var gs: Node
var qm: Node
var inv: Node
var failures: Array[String] = []
var checks := 0
var deadline := 0
var sources: Dictionary = {}
var dialogs: Dictionary = {}
var observations: Array = []

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: failures.append(label); push_error(label)
	return ok

func _facts(paths: Array) -> Dictionary:
	var result := {}
	for raw: Variant in paths:
		var path := String(raw)
		result[path] = {"exists":FileAccess.file_exists(path),"sha":FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "","mtime":FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else 0}
	return result

func _players() -> Dictionary:
	var paths: Array = []
	for slot in range(5):
		for suffix in ["", ".bak", ".tmp"]: paths.append("user://save_%d.json%s" % [slot,suffix])
	return _facts(paths)

func _flags() -> Dictionary: return gs.get("flags")
func _states() -> Dictionary: return qm.get("states")
func _auth(name: String) -> bool: return T.authorize_dialog(PREFIX+name,_flags(),_states())
func _flag(key: String) -> bool: return bool(_flags().get(key,false))
func _status(qid: String) -> int: return int(qm.call("get_status",StringName(qid)))
func _count(id: String) -> int: return int(inv.call("count_of",StringName(id)))

func _play(name: String) -> bool:
	if not _check(_auth(name),"Authorized stage "+name): return false
	dp.call("play",dialogs[name]); return true

func _finish() -> void:
	for step in range(16):
		if not dp.call("is_playing"): return
		if not _check(Time.get_ticks_msec()<deadline,"Shared30s deadline"): return
		if dp.get("_pending_side_offer_id") != &"": dp.call("choose",0)
		else: dp.call("advance")
	_check(false,"Dialogue bounded16 steps")

func _offer(name: String, qid: String, flag: String) -> void:
	for accept in [false,true]:
		if not _play(name): return
		for step in range(4):
			if dp.get("_pending_side_offer_id") != &"": break
			dp.call("advance")
		_check(dp.get("_pending_side_offer_id")==StringName(qid) and not _flag(flag) and _status(qid)==0,"Offer is inert before choice "+name)
		dp.call("choose",0 if accept else 1)
		_check(_flag(flag)==accept and _status(qid)==(1 if accept else 0),"Real choose acceptance/rejection "+name)
		_finish()

func _snapshot() -> Dictionary:
	var counts := {}
	for id in ["xuantong_fist_gauntlets","healing_pill_major","antidote_pill","spirit_stone","heaven_element_pill","canglong_fragment_lower"]: counts[id]=_count(id)
	return {"gold":gs.get("gold"),"training":gs.get("training_points_total"),"exp":gs.get("player").exp,"items":counts,"states":_states().duplicate(true),"flags":_flags().duplicate(true)}

func _report(name: String, qid: String, gold: int, exp: int, rewards: Dictionary) -> void:
	var before := _snapshot()
	if not _play(name): return
	_finish()
	var after := _snapshot()
	_check(_status(qid)==2 and after.gold-before.gold==gold and after.training-before.training==exp and after.exp-before.exp==exp,"Exact original gold/exp/training "+name)
	for id: String in rewards: _check(int(after.items[id])-int(before.items[id])==int(rewards[id]),"Exact original item "+id)
	_check(not _auth(name),"Stale report authorization denied "+name)
	# Real DialogPlayer backstop must also reject a second play; do not bypass by play_at.
	dp.call("play",dialogs[name]); _finish()
	_check(_snapshot()==after,"Repeated report has no effects "+name)
	observations.append({"report":name,"before":before,"after":after})

func _run() -> void:
	deadline=Time.get_ticks_msec()+30000
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true) # BEFORE first await; never unsuspend/write/restore player files.
	var before_players:=_players()
	var slot: Variant=root.get_node("SaveManager").get("active_slot")
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"Checkpoint writes suspended before first await")
	await process_frame
	dp=root.get_node("DialogPlayer"); gs=root.get_node("GameState"); qm=root.get_node("QuestManager"); inv=root.get_node("Inventory")
	var paths:=T.source_paths()
	_check(paths.size()==35,"Complete35 task source closure valid")
	for path in ["res://tests/test_luoyang_city_tasks_20261016.gd","res://scripts/autoload/dialog_player.gd","res://scripts/autoload/quest_manager.gd","res://scripts/autoload/game_state.gd","res://scripts/autoload/inventory.gd","res://data/quests/q_secret_canglong_three_pages.tres"]: paths[path]=true
	sources=_facts(paths.keys())
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(T.SPEC_PATH))
	for path: String in spec.source_pins:
		_check(FileAccess.get_sha256(path)==spec.source_pins[path],"Source pin "+path)
		if not path.begins_with("res://data/dialogs/"+PREFIX): continue
		var dialog:=load(path) as DialogScript
		_check(dialog!=null and dialog.dialog_id==StringName("ch4_city_tasks_20261016_"+path.get_file().get_basename()),"Real DialogScript identity "+path)
		if dialog==null: continue
		dialogs[path.get_file().get_basename()]=dialog
		var ids:=[]
		for node: DialogNode in dialog.nodes: _check(node.node_id not in ids,"Unique node "+path+":"+String(node.node_id)); ids.append(node.node_id)
		_check(dialog.get_entry_node()!=null,"Entry exists "+path)
		for node: DialogNode in dialog.nodes:
			if node.on_end.begins_with("next:"): _check(dialog.find_node_by_id(StringName(node.on_end.trim_prefix("next:")))!=null,"Next exists "+path)
	_check(dialogs.size()==20,"All20 new dialogues loaded")
	gs.set("flags",{}); gs.set("gold",0); gs.set("training_points_total",0); gs.set("training_points_available",0); gs.set("player",CharacterStats.new())
	qm.set("states",{}); qm.set("tracked_side_quest_id",&""); inv.call("from_dict",{})
	_check(T.stages(_flags(),_states())=={"canal":"not_started","paper":"not_started"},"Initial stages")
	_check(not _auth("unknown") and T.authorize_dialog("outside_namespace",{},{}),"Fail closed only owned namespace")
	for name in ["canal_witness","canal_warehouse_clue","canal_evidence","canal_report","paper_hint","paper_materials","paper_report"]: _check(not _auth(name),"No prequest action "+name)
	_offer("canal_offer",T.CANAL,"canal_grudge_started")
	_check(T.stages(_flags(),_states()).canal=="accepted" and _auth("canal_progress") and not _auth("canal_evidence"),"Accepted: NPC progress, no evidence")
	_play("canal_witness"); _check(not _flag("canal_grudge_route_heard"),"Witness requires second line"); _finish()
	_check(T.stages(_flags(),_states()).canal=="witness" and not _auth("canal_report"),"Witness does not grant report")
	_play("canal_warehouse_clue"); _check(not _flag("canal_grudge_warehouse_located"),"Locate requires second line"); _finish()
	_check(T.stages(_flags(),_states()).canal=="located" and not _auth("canal_warehouse_clue"),"Located stage stale clue denied")
	_play("canal_evidence"); _check(not _flag("canal_grudge_evidence_found"),"Evidence requires second line"); _finish()
	_check(T.stages(_flags(),_states()).canal=="evidence" and not _auth("canal_evidence"),"Collected evidence action hidden/denied")
	_report("canal_report",T.CANAL,35,30,{"xuantong_fist_gauntlets":1,"healing_pill_major":2,"antidote_pill":1})
	_check(_auth("canal_after") and not _auth("canal_progress"),"Completed chief still has after dialogue")
	_offer("paper_offer",T.PAPER,"luoyang_paper_started")
	_check(_auth("paper_progress") and not _auth("paper_materials"),"Accepted paper no materials before hint")
	_play("paper_hint"); _check(not _flag("luoyang_paper_artisan_hint"),"Artisan requires second line"); _finish()
	_check(_auth("paper_hint_repeat") and not _auth("paper_report"),"Hint repeat and no premature report")
	_play("paper_materials"); _check(not _flag("luoyang_paper_materials_found"),"Materials require second line"); _finish()
	_check(T.stages(_flags(),_states()).paper=="materials" and not _auth("paper_materials") and _auth("paper_ready"),"Materials hidden after collection")
	_check(_count("canglong_fragment_lower")==0 and _status("q_secret_canglong_three_pages")==0,"No fragment/secret reward before report")
	_report("paper_report",T.PAPER,10,25,{"spirit_stone":3,"heaven_element_pill":1,"canglong_fragment_lower":1})
	_check(_status("q_secret_canglong_three_pages")==1 and _auth("paper_after") and _auth("artisan_after"),"One fragment and secret accepted; both NPC after dialogues")
	_offer("hanjia_offer",T.HANJIA,"hanjia_blade_search_started")
	_check(_auth("hanjia_progress") and not _auth("hanjia_after"),"Old soldier retains original active blade task")
	_check(_players()==before_players and root.get_node("SaveManager").get("active_slot")==slot and bridge.call("is_checkpoint_saves_suspended")==true,"15 player file facts / slot / suspension unchanged")
	_check(_facts(paths.keys())==sources,"All task/consumer sources unchanged")
	_check(Time.get_ticks_msec()<deadline,"Whole pure state shared30s")
	var output:="res://build/luoyang_city_tasks_20261016/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var result:={"ok":failures.is_empty(),"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-(deadline-30000),"source_before":sources,"source_after":_facts(paths.keys()),"players_before":before_players,"players_after":_players(),"observations":observations,"scope":"PURE_STATE_REAL_DIALOGPLAYER_NOT_FIELD_NOT_GEOMETRY_NOT_ART"}
	var file:=FileAccess.open(output+"result.json",FileAccess.WRITE); file.store_string(JSON.stringify(result,"\t")); file.close()
	print("TASK_KEY_RESULT "+output+"result.json "+JSON.stringify({"checks":checks,"failures":failures}))
	quit(0 if failures.is_empty() else 1)
