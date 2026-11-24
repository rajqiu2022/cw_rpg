extends "res://tests/helpers/cold_sha_qa_retry2_20261017k.gd"
## NOTREADY/source checkpoint. Root alone may run a separately frozen successor.
##30s: actual DialogPlayer effects behind candidate auth; no Field/GPU/geometry.
const TASK_READY=false
const TASK_ROOT="res://build/luoyang_layout_quest_20261018t_task_source01/"
const TASK_MANIFEST_SHA="ff9467061898812f5b9ee309f7919d5d05dccd6821fae569367f80fd1b77d5b6"
const TASK_PROJECTION_SHA="daa54efa85038bb6ae1fcdd8c7f030f139a01c6d240229d5aaf883ee2b580f72"
const TASK_CONTRACT_SHA="356be38ff6af30eeb67dff59f9dd5c1b8d7f045e9f41700f0410d275ee685b6b"
const TASK_CPU_BASE_SHA="001717611f3ec5a8f3cd3df518471f51a3b7c213bfe9592d48bb619b14919102"
const PREFIX="luoyang_layout_quest_20261018t/"
const LONGMEN=&"q_ch4_side_04_longmen_mystery"
var api: Variant
var dp: Node
var gs: Node
var qm: Node
var inv: Node
var dialogs: Dictionary={}
var original_defs: Dictionary={}

func _initialize() -> void:
	budget_ms=30000;atom_name="T_TASK_STATE_DRAFT_NOTREADY"
	super._initialize()

func precheck() -> bool:
	if not check(TASK_READY,"NOTREADY: candidate-only namespace/QuestDefs not production hooked; no actual credit"): return false
	for pair: Array in [["res://tests/helpers/cold_sha_qa_retry2_20261017k.gd",TASK_CPU_BASE_SHA],[TASK_ROOT+"candidate_manifest.json",TASK_MANIFEST_SHA],[TASK_ROOT+"source_contract.json",TASK_CONTRACT_SHA],[TASK_ROOT+"luoyang_task_projection_candidate.gd",TASK_PROJECTION_SHA]]:
		if not track(pair[0],pair[1]): return false
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(TASK_ROOT+"candidate_manifest.json"))
	if not check(manifest.status=="SOURCE_READY_NOT_DEPLOYED" and manifest.static_validation.engine_or_field_run==false,"SOURCE_READY means source only; static149 is not this DialogPlayer test"): return false
	for row: Dictionary in manifest.source_files:
		if not check(not String(row.path).contains(".."),"Candidate relative file stays in frozen task package") or not track(TASK_ROOT+row.path,row.sha256): return false
	var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(TASK_ROOT+"source_contract.json"))
	for path: String in contract.production_sources:
		if not track("res://"+path.trim_prefix("game/"),contract.production_sources[path].sha256): return false
	if not track("res://art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png","6268061eab18d2bf8c1ea0c13873f0d718feb82a119f00a67edf7c52bcb077ad") or not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	api=load(TASK_ROOT+"luoyang_task_projection_candidate.gd")
	dp=root.get_node("DialogPlayer");gs=root.get_node("GameState");qm=root.get_node("QuestManager");inv=root.get_node("Inventory")
	for kind: String in ["longmen","baima","peony"]:
		for phase: String in ["offer","progress","investigate","report","after"]:
			dialogs[kind+"_"+phase]=load(TASK_ROOT+"dialogs/"+kind+"_"+phase+".tres")
	return check(api!=null and dialogs.size()==15,"Exact candidate projection and15 real DialogScript resources")

func _auth(name: String) -> bool:
	return api.authorize_dialog(PREFIX+name,gs.get("flags"),qm.get("states"))

func _guarded_play(name: String) -> bool:
	# Current DialogPlayer itself has no task namespace guard. This explicitly
	# models the candidate Field authorization boundary, not a deployed hook.
	if not _auth(name): return false
	dp.call("play",dialogs[name]);return true

func _drain() -> bool:
	for step: int in 12:
		if not dp.call("is_playing"): return true
		if not check(Time.get_ticks_msec()<deadline and dp.get("_pending_side_offer_id")==&"","Bounded dialogue completion; never auto-accept an unobserved offer"): return false
		dp.call("advance")
	return check(false,"Candidate dialogue did not finish in12nodes")

func _value() -> Dictionary:
	var items: Dictionary={}
	for id: String in ["yuanming_ancient_jade","diamond_powder","dragon_tendon_staff"]: items[id]=inv.call("count_of",StringName(id))
	return {"gold":gs.get("gold"),"exp":gs.get("player").exp,"training":gs.get("training_points_total"),"items":items}

func _projection_matrix() -> bool:
	var scene: SceneScript=load("res://data/scenes/luoyang_temple_assembly_20261016/temple.tres") as SceneScript
	var adapter: Variant=load("res://scripts/city/luoyang_temple_task_adapter_20261016.gd")
	for phase: int in 4:
		var flags: Dictionary={};var states: Dictionary={}
		for entry: Array in [[api.LONGMEN,api.LONGMEN_STARTED,api.LONGMEN_EVIDENCE],[api.BAIMA,api.BAIMA_STARTED,api.BAIMA_EVIDENCE],[api.PEONY,api.PEONY_STARTED,api.PEONY_ANSWERED]]:
			states[entry[0]]=0 if phase==0 else (2 if phase==3 else 1)
			if phase>0: flags[entry[1]]=true
			if phase>1: flags[entry[2]]=true
		var base: Dictionary=adapter.project(scene,flags,states,scene.map_layout.interactions,scene.map_layout.visual_objects)
		var projected: Dictionary=api.project_temple(base,scene.map_layout.portals,flags,states)
		if not check(projected.get("ok")==true and projected.npcs.size()==2,"Real canonical adapter→candidate persistent two-NPC projection phase"+str(phase)): return false
		var suffix: String=["offer","progress","report","after"][phase]
		for index: int in 2:
			var npc: Dictionary=projected.npcs[index]
			var kind: String="longmen" if index==0 else "baima"
			var expected_id: String="temple_cave_keeper_20261018t" if index==0 else "temple_bell_keeper_20261018t"
			var expected_foot: Vector2=Vector2(500,600) if index==0 else Vector2(1180,690)
			if not check(npc.npc_id==expected_id and npc.pos==expected_foot/Vector2(1536,1024) and npc.dialog_id==PREFIX+kind+"_"+suffix and npc.scale==api.MONK_SCALE and npc.sprite_path==api.MONK_SPRITE and npc.portrait_path==api.MONK_SPRITE and not npc.has("hide_flag") and not npc.has("ambient"),"Exact persistent monk/sourcefoot/dialog/140px scale, not ambient/calibrated body"): return false
		for kind: String in ["baima","peony"]:
			if not check(api.authorize_dialog(PREFIX+kind+"_report",flags,states)==(phase==2) and api.authorize_dialog(PREFIX+kind+"_investigate",flags,states)==(phase==1),"Fast phase auth matrix, not a second full quest chain "+kind): return false
	return true

func exercise() -> bool:
	await process_frame
	for singleton: String in ["GameState","Inventory","QuestManager"]: root.get_node(singleton).call("reset_for_new_game")
	# Explicit controlled in-memory fixture: no production QuestDef replacement.
	var definitions: Dictionary=qm.get("_defs")
	for qid: StringName in [api.LONGMEN,api.BAIMA,api.PEONY]:
		var old: QuestDef=qm.call("load_def",qid);original_defs[qid]=old
		var candidate: QuestDef=load(TASK_ROOT+"quests/"+String(qid)+".tres") as QuestDef
		if not check(candidate!=null and candidate.quest_id==qid and candidate.completion_triggers.is_empty() and candidate.reward_gold==old.reward_gold and candidate.reward_exp==old.reward_exp and candidate.reward_items==old.reward_items,"Same QuestID/exact original rewards with explicit empty auto-completion triggers"): return false
		definitions[qid]=candidate
	if not _projection_matrix(): return false
	# The legacy solved flag is deliberately preexisting; accept must stay ACTIVE.
	gs.call("set_flag",&"longmen_mystery_solved",true)
	var before: Dictionary=_value()
	if not check(_guarded_play("longmen_offer") and dp.get("_pending_side_offer_id")==LONGMEN,"Actual DialogPlayer side-offer before selection"): return false
	dp.call("choose",1)
	if not check(qm.call("get_status",LONGMEN)==0 and not gs.get("flags").get(api.LONGMEN_STARTED,false) and _value()==before,"Actual rejection has no started/status/reward effect"): return false
	if not check(_guarded_play("longmen_offer"),"Offer remains available after rejection"): return false
	dp.call("choose",0)
	if not _drain() or not check(qm.call("get_status",LONGMEN)==1 and gs.get("flags").get(api.LONGMEN_STARTED,false) and _value()==before,"Actual acceptance is ACTIVE/no award despite old solved flag"): return false
	if not check(not _auth("longmen_report") and not _guarded_play("longmen_report") and _value()==before,"Candidate authorization denies report before investigation; no direct-play bypass claim"): return false
	if not check(_guarded_play("longmen_investigate"),"Separate actual investigation dialogue allowed"): return false
	if not _drain() or not check(gs.get("flags").get(api.LONGMEN_EVIDENCE,false) and qm.call("get_status",LONGMEN)==1 and _value()==before,"Investigation only adds evidence, no completion/reward"): return false
	if not check(_guarded_play("longmen_report"),"Evidence gates explicit report"): return false
	if not _drain(): return false
	var after: Dictionary=_value()
	if not check(qm.call("get_status",LONGMEN)==2 and after.gold-before.gold==30 and after.exp-before.exp==35 and after.training-before.training==35,"Original gold/EXP/training rewarded exactly once"): return false
	for pair: Array in [["yuanming_ancient_jade",1],["diamond_powder",2],["dragon_tendon_staff",1]]:
		if not check(int(after.items[pair[0]])-int(before.items[pair[0]])==pair[1],"Exact original reward item "+pair[0]): return false
	if not check(not _guarded_play("longmen_report") and qm.call("complete",LONGMEN)==false and _value()==after,"Stale authorized route and QuestManager duplicate complete cannot reward again"): return false
	for qid: Variant in original_defs: definitions[qid]=original_defs[qid]
	records.append({"kind":"T_CONTROLLED_CANDIDATE_TASK_STATE","real_DialogPlayer_and_QuestManager":true,"candidate_authorize_gate_not_deployed_Field_hook":true,"candidate_QuestDefs_in_memory_only":true,"legacy_solved_before_accept":true,"before_rewards":before,"after_rewards":after,"no_Field_Physics_import_or_actual_NPC_credit":true})
	return true
