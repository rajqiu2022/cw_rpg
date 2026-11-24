extends "res://build/luoyang_city_revision_20261024c_qa01/finite_Field_NOTREADY/common.gd"
## Positive purchases require native NPC/UI INPUT. Stale/replay are separate negatives.
const READY25H=false
const FIXTURE25H="PENDING_SOURCE25H_INDEPENDENT_INN_FIXTURE"
const FIXTURE_SHA25H="PENDING_SOURCE25H_INDEPENDENT_INN_FIXTURE_SHA"
const ORACLE25H=preload("res://build/luoyang_city_revision_20261025h_qa01/service_oracle_NOTREADY.gd")
var adapter25h: RefCounted
var gs25h: Node
var original25h: Dictionary={}
var completed25h: Array=[]
func precheck() -> bool:
	if not check(READY25H and track(FIXTURE25H,FIXTURE_SHA25H),"Hardfalse until implementation interface and independent Source freeze"): return false
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE25H))
	if not check(raw is Dictionary and raw.get("ready")==true and raw.get("formal_deployed")==true,"Final25h fixture only"): return false
	fixture=raw
	if not check(fixture.whole_ms==60000 and fixture.entry_ms==20000 and fixture.max_pictures<=1 and fixture.meal_price==5 and fixture.lodging_price==20,"Fixed5/20 services,60s/20s and max1 actual image"): return false
	for path: String in fixture.source_sha256:
		if not track(path,fixture.source_sha256[path]): return false
	return check(false,"HARDFALSE pending actual local-menu UI, full-party and stale-owner contract")
func _remember25h() -> void:
	gs25h=root.get_node("GameState")
	var hero: CharacterStats=gs25h.get("player")
	original25h={"gold":gs25h.get("gold"),"party":(gs25h.get("party") as Array).duplicate(),"hero":hero,"hp":hero.hp,"mp":hero.mp,"max_hp":hero.max_hp,"max_mp":hero.max_mp}
func _restore_memory25h() -> void:
	if original25h.is_empty(): return
	var hero: CharacterStats=original25h.hero
	hero.hp=original25h.hp;hero.mp=original25h.mp;hero.max_hp=original25h.max_hp;hero.max_mp=original25h.max_mp
	gs25h.set("party",original25h.party);gs25h.set("gold",original25h.gold)
	original25h.clear()
func _case_party25h(mode: String,gold: int) -> Dictionary:
	# Explicitly approved process-only state; no Character resource or save write.
	var hero: CharacterStats=gs25h.get("player")
	var tiny: CharacterStats=hero.duplicate(true);tiny.character_id=&"qa25h_tiny"
	var clamp_member: CharacterStats=hero.duplicate(true);clamp_member.character_id=&"qa25h_clamp"
	hero.max_hp=101;hero.max_mp=41;hero.hp=1;hero.mp=0
	tiny.max_hp=3;tiny.max_mp=1;tiny.hp=1;tiny.mp=0
	clamp_member.max_hp=8;clamp_member.max_mp=5;clamp_member.hp=7;clamp_member.mp=4
	if mode=="full":
		for member: CharacterStats in [hero,tiny,clamp_member]: member.hp=member.max_hp;member.mp=member.max_mp
	var party: Array[CharacterStats]=[hero,tiny,clamp_member]
	gs25h.set("party",party);gs25h.set("gold",gold)
	return ORACLE25H.snapshot(gs25h)
func _one25h(service: String,decision: String,gold: int,mode: String="damaged") -> bool:
	var before: Dictionary=_case_party25h(mode,gold)
	var apply: bool=decision=="confirm" and gold>=(5 if service=="meal" else 20) and not (mode=="full" and fixture.full_party_policy=="NO_CHARGE_REJECT")
	var expected: Dictionary=ORACLE25H.expected(before,service,apply)
	if not await adapter25h.call("real_open_service_and_decide",self,service,decision): return false
	var after: Dictionary=ORACLE25H.snapshot(gs25h)
	if not check(not expected.is_empty() and after==expected,"Independent whole-party restore/clamp and exact one fee "+service+"/"+decision+"/"+mode): return false
	records.append({"kind":"25H_INDEPENDENT_SERVICE_ARITHMETIC","service":service,"decision":decision,"mode":mode,"before":before,"after":after,"deltas":ORACLE25H.deltas(before,after),"process_only_test_setup":true})
	completed25h.append(service+"/"+decision+"/"+mode)
	return true
func exercise_cpu() -> bool:
	if not await adapter25h.call("enter_inn_and_assert_actor",self,fixture): return false
	_remember25h()
	for service: String in ["meal","lodging"]:
		if not await _one25h(service,"cancel",40): return false
		if not await _one25h(service,"confirm",0): return false
		if not await _one25h(service,"confirm",40): return false
		if not await adapter25h.call("assert_same_confirmation_replay_no_side_effect",self,service): return false
		if not await _one25h(service,"confirm",40,"full"): return false
	return await adapter25h.call("assert_owner_change_invalidates_unconsumed_confirmation",self,fixture)
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+60000
	output="res://build/luoyang_city_revision_20261025h_qa01/inn01_output/%d_%d"%[OS.get_process_id(),began]
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self);gameplay=_gameplay()
		complete=await exercise_cpu()
	_restore_memory25h()
	if driver!=null: driver.release();driver=null
	records.append({"kind":"25H_INN_SERVICE_FINITE_PROCESS_ONLY","completed":completed25h,"memory_setup_restored":original25h.is_empty(),"save_writes":0,"collector_calls":0,"old25g_replay":0})
	finish(output,began,complete,"25H_INN_HARDFALSE_PENDING_FINAL_INTERFACE")
