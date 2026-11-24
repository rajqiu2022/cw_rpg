extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Only the actual helper's pure arithmetic, no _data/attach/room/Field/open.
const PLAN_READY25H=true
const HELPER25H="res://build/luoyang_indoor_services_20261025h_system01/services_runtime01_CANDIDATE.gd"
const HELPER_SHA25H="37f767e67c672a5438e897b76f7852c898128bcd3d26bb352fde0f92f52dea5b"
const ORACLE25H="res://build/luoyang_city_revision_20261025h_qa01/service_oracle_NOTREADY.gd"
const ORACLE_SHA25H="9a391dae4d2769e8d20f2a6f1918888f5660e1644be8681f8c427a15487ef444"
var helper25h: Variant
var global_before25h: Dictionary={}
func _global25h() -> Dictionary:
	var gs: Node=root.get_node("GameState")
	var rows: Array=[]
	for value: Variant in gs.get("party"):
		if value is CharacterStats: rows.append({"id":str(value.get_instance_id()),"hp":value.hp,"mp":value.mp,"max_hp":value.max_hp,"max_mp":value.max_mp})
	return {"gold":gs.get("gold"),"flags":gs.get("flags").duplicate(true),"party":rows,"inventory":root.get_node("Inventory").call("to_dict").duplicate(true),"quests":root.get_node("QuestManager").call("to_dict").duplicate(true)}
func precheck() -> bool:
	if not check(PLAN_READY25H,"Hardfalse until Root reads fixed pure helper candidate and this finite key"): return false
	if not track(HELPER25H,HELPER_SHA25H) or not track(ORACLE25H,ORACLE_SHA25H): return false
	helper25h=load(HELPER25H)
	return check(helper25h is GDScript and helper25h.resource_path==HELPER25H,"Exact candidate pure function only, no FORMAL_READY bypass")
func _case25h(label: String,service: String,rows: Array,gold: int,expected: Dictionary) -> bool:
	var before: PackedByteArray=var_to_bytes(rows)
	var actual: Dictionary=helper25h.plan_party(service,rows,gold)
	if not check(var_to_bytes(rows)==before and actual==expected,"Independent literal plan "+label,{"actual":actual,"expected":expected}): return false
	records.append({"kind":"25H_PURE_PLAN_ONLY","label":label,"service":service,"gold":gold,"result":actual,"input_unchanged":true,"room_or_owner_credit":false})
	return true
func exercise_cpu() -> bool:
	global_before25h=_global25h()
	var rows: Array=[{"hp":1,"mp":0,"max_hp":101,"max_mp":41},{"hp":0,"mp":0,"max_hp":3,"max_mp":1},{"hp":7,"mp":4,"max_hp":8,"max_mp":5},{"hp":1,"mp":0,"max_hp":5,"max_mp":0}]
	var meal: Dictionary={"ok":true,"reason":"ready","cost":5,"effects":[{"hp":26,"mp":10},{"hp":1,"mp":1},{"hp":8,"mp":5},{"hp":2,"mp":0}]}
	var rest: Dictionary={"ok":true,"reason":"ready","cost":20,"effects":[{"hp":101,"mp":41},{"hp":3,"mp":1},{"hp":8,"mp":5},{"hp":5,"mp":0}]}
	if not _case25h("meal_exact_fee_floor_min1_dead_companion_and_clamp","meal",rows,5,meal): return false
	if not _case25h("rest_exact_fee_entire_party_maximum","rest",rows,20,rest): return false
	if not _case25h("meal_insufficient_by1","meal",rows,4,{"ok":false,"reason":"insufficient","cost":5}): return false
	if not _case25h("rest_insufficient_by1","rest",rows,19,{"ok":false,"reason":"insufficient","cost":20}): return false
	var full: Array=[]
	for row: Dictionary in rows: full.append({"hp":row.max_hp,"mp":row.max_mp,"max_hp":row.max_hp,"max_mp":row.max_mp})
	for service: String in ["meal","rest"]:
		if not _case25h("all_full_no_charge_even_zero_gold",service,full,0,{"ok":false,"reason":"full","cost":0}): return false
	var partial: Array=full.duplicate(true);partial[2].mp-=1
	if not _case25h("any_one_resource_nonfull_eligible","meal",partial,5,{"ok":true,"reason":"ready","cost":5,"effects":rest.effects}): return false
	var next_rows: Array=[]
	for i: int in range(rows.size()):
		var row: Dictionary=rows[i].duplicate(true);row.hp=meal.effects[i].hp;row.mp=meal.effects[i].mp;next_rows.append(row)
	if not _case25h("fresh_second_session_current_rows_not_permanent_flag","meal",next_rows,35,{"ok":true,"reason":"ready","cost":5,"effects":[{"hp":51,"mp":20},{"hp":2,"mp":1},{"hp":8,"mp":5},{"hp":3,"mp":0}]}): return false
	var invalid: Dictionary={"ok":false,"reason":"invalid"}
	if not _case25h("unknown_service","not_service",rows,50,invalid) or not _case25h("empty_party","meal",[],50,invalid) or not _case25h("negative_gold","meal",rows,-1,invalid) or not _case25h("not_dictionary_row","meal",[null],50,invalid): return false
	for pair: Array in [["hp",-1],["hp",102],["mp",-1],["mp",42],["max_hp",0],["max_mp",-1],["hp",1.0]]:
		var bad: Array=rows.duplicate(true);bad[0][pair[0]]=pair[1]
		if not _case25h("reject_invalid_"+str(pair),"meal",bad,50,invalid): return false
	var missing: Array=rows.duplicate(true);missing[0].erase("hp")
	if not _case25h("reject_missing_stat","meal",missing,50,invalid): return false
	return check(_global25h()==global_before25h,"Actual helper pure plan never changed current gold/party/flags/quest/inventory")
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+15000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=false
	if precheck(): complete=exercise_cpu()
	finish("res://build/luoyang_city_revision_20261025h_qa01/service_plan01_ROOT_READY_output/%d_%d"%[OS.get_process_id(),began],began,complete,"25H_ACTUAL_PURE_PLAN_ONLY_NO_ROOM_UI_OR_OWNER_CREDIT_ROOT_READY")
