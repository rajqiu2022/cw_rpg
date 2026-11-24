extends "res://build/luoyang_city_revision_20261025h_qa01/common_ui01_NOTREADY.gd"
const READY25H=false
const FIXTURE25H="PENDING_SOURCE25H_INN_FINAL_FIXTURE"
const FIXTURE_SHA25H="PENDING_SOURCE25H_INN_FINAL_FIXTURE_SHA"
const ADAPTER25H=preload("res://build/luoyang_city_revision_20261025h_qa01/ui_adapter01_NOTREADY.gd")
const ORACLE25H=preload("res://build/luoyang_city_revision_20261025h_qa01/service_oracle_NOTREADY.gd")
var adapter25h: RefCounted
var gs25h: Node
var original25h: Dictionary={}
var completed25h: Array=[]
func precheck() -> bool:
	if not check(READY25H and track(FIXTURE25H,FIXTURE_SHA25H),"Hardfalse until independent Source final/actual helper and Root deployment"): return false
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE25H))
	if not check(raw is Dictionary and raw.get("ready")==true and raw.get("formal_deployed")==true,"Final25h inn source fixture only"): return false
	fixture=raw
	if not check(fixture.whole_ms==60000 and fixture.entry_ms==20000 and fixture.max_pictures==1 and fixture.meal_price==5 and fixture.lodging_price==20 and fixture.full_party_policy=="NO_CHARGE_REJECT" and fixture.owner_change_target.room_id!=fixture.inn.room_id,"Root exact5/20/no-full-charge,60/20,one image and distinct final owner setup"): return false
	for path: String in fixture.source_sha256:
		if not track(path,fixture.source_sha256[path]): return false
	adapter25h=ADAPTER25H.new()
	return check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and root.get_visible_rect().size==Vector2(1920,1080) and OS.get_cmdline_user_args().is_empty(),"Original GUI only; isolated party setup never writes saves")
func _notify25h() -> void:
	gs25h.emit_signal("player_changed");gs25h.emit_signal("party_changed");gs25h.emit_signal("gold_changed",gs25h.get("gold"));root.get_node("EventBus").emit_signal("gold_changed",gs25h.get("gold"))
func _remember25h() -> void:
	gs25h=root.get_node("GameState");var hero: CharacterStats=gs25h.get("player")
	original25h={"gold":gs25h.get("gold"),"party":(gs25h.get("party") as Array).duplicate(),"hero":hero,"hp":hero.hp,"mp":hero.mp,"max_hp":hero.max_hp,"max_mp":hero.max_mp}
func _restore_memory25h() -> void:
	if original25h.is_empty(): return
	var hero: CharacterStats=original25h.hero
	hero.hp=original25h.hp;hero.mp=original25h.mp;hero.max_hp=original25h.max_hp;hero.max_mp=original25h.max_mp
	gs25h.set("party",original25h.party);gs25h.set("gold",original25h.gold);_notify25h();original25h.clear()
func _case_party25h(mode: String,gold: int) -> Dictionary:
	var hero: CharacterStats=gs25h.get("player")
	var companion: CharacterStats=hero.duplicate(true);companion.character_id=&"qa25h_dead_companion"
	var clamp_member: CharacterStats=hero.duplicate(true);clamp_member.character_id=&"qa25h_clamp"
	hero.max_hp=101;hero.max_mp=41;hero.hp=1;hero.mp=0
	companion.max_hp=3;companion.max_mp=1;companion.hp=0;companion.mp=0
	clamp_member.max_hp=8;clamp_member.max_mp=5;clamp_member.hp=7;clamp_member.mp=4
	if mode=="full":
		for member: CharacterStats in [hero,companion,clamp_member]: member.hp=member.max_hp;member.mp=member.max_mp
	var party: Array[CharacterStats]=[hero,companion,clamp_member]
	gs25h.set("party",party);gs25h.set("gold",gold);_notify25h()
	return ORACLE25H.snapshot(gs25h)
func _one25h(service: String,decision: String,gold: int,mode: String="damaged",mutate_current: bool=false) -> bool:
	var open_snapshot: Dictionary=_case_party25h(mode,gold)
	if not await adapter25h.open_service_to_confirmation(self,service): return false
	if mutate_current:
		# Explicit process-only late change after actual confirmation UI appeared.
		var hero: CharacterStats=gs25h.get("player")
		hero.max_hp=109;hero.max_mp=43;gs25h.set("gold",4);_notify25h()
	var before: Dictionary=ORACLE25H.snapshot(gs25h)
	var apply: bool=decision=="confirm" and int(before.gold)>=(5 if service=="meal" else 20) and not ORACLE25H.all_full(before)
	var expected: Dictionary=ORACLE25H.expected(before,service,apply)
	if not await adapter25h.decide_confirmation(self,service,decision): return false
	var after: Dictionary=ORACLE25H.snapshot(gs25h)
	if not check(after==expected,"Actual UI commit uses current whole party/max/gold, exact fee and clamp "+service+"/"+decision+"/"+mode): return false
	records.append({"kind":"25H_REAL_SERVICE_POSTCONDITION_NOT_PURE_MATRIX_REPLAY","service":service,"decision":decision,"mode":mode,"at_open":open_snapshot,"current_before_final_input":before,"after":after,"late_process_only_mutation":mutate_current,"deltas":ORACLE25H.deltas(before,after)})
	completed25h.append(service+"/"+decision+"/"+mode)
	return true
func _fresh_meal25h() -> bool:
	var before: Dictionary=ORACLE25H.snapshot(gs25h);var expected: Dictionary=ORACLE25H.expected(before,"meal",true)
	if not check(not ORACLE25H.all_full(before) and before.gold>=5,"Fresh legitimate request has currently eligible party"): return false
	if not await adapter25h.real_open_service_and_decide(self,"meal","confirm"): return false
	return check(ORACLE25H.snapshot(gs25h)==expected,"New valid session may consume again; not a permanent one-use flag")
func exercise_cpu() -> bool:
	if not await adapter25h.enter_inn_and_assert_actor(self,fixture): return false
	_remember25h()
	for service: String in ["meal","lodging"]:
		if not await _one25h(service,"cancel",40): return false
		if not await _one25h(service,"confirm",0): return false
		if not await _one25h(service,"confirm",40): return false
		if not await adapter25h.assert_same_confirmation_replay_no_side_effect(self,service): return false
		if service=="meal" and not await _fresh_meal25h(): return false
		if not await _one25h(service,"confirm",40,"full"): return false
	if not await _one25h("meal","confirm",40,"damaged",true): return false
	return await adapter25h.assert_owner_change_invalidates_unconsumed_confirmation(self,fixture)
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+60000
	output="res://build/luoyang_city_revision_20261025h_qa01/inn03_output/%d_%d"%[OS.get_process_id(),began]
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self);gameplay=_gameplay()
		complete=await exercise_cpu()
	_restore_memory25h()
	if driver!=null: driver.release();driver=null
	if complete: complete=check(_gameplay()==gameplay,"Process-only party/gold restoration leaves flags/quests/inventory unchanged")
	records.append({"kind":"25H_INN_REAL_LOCAL_SERVICE_FINITE_SCOPE","completed":completed25h,"memory_setup_restored":original25h.is_empty(),"pictures":pictures,"save_writes":0,"collector_calls":0,"old25g_replay":0,"pure20case_credit":"Root79460407_28checks_passed_not_replayed"})
	finish(output,began,complete,"25H_INN03_HARDFALSE_FINAL_SOURCE_PENDING")
