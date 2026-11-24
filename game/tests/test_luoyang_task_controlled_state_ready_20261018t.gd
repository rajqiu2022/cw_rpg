extends "res://tests/test_luoyang_layout_task_state_draft_20261018t.gd"
## READY means this controlled CPU fixture only, NOT a deployed task resolver.
## Actual DialogPlayer/QuestManager; QA authorization boundary and in-memory Defs.
const CONTROLLED_READY := true
const OLD_DRAFT_SHA := "07c53c3b08f7c8c3130ad169121c4caef63735518df3cc86114b60f80329cc69"
const CURRENT_MANIFEST_SHA := "c35dca2093fab8c580ed0f45e1f782e34b3c4ff2b03a07f9e068e20add10680c"
const CURRENT_PROJECTION_SHA := "95c7d38fd1c6baddcded5a90d33fea8d696c7aad6ee67df33c6ebf074bc70bfb"
const CURRENT_CONTRACT_SHA := "f940c684f8005b4908c1189aa233d0dc69ad70d9076cca350a08eed5311d46fc"
const STATE_SOURCES := "res://tests/fixtures/luoyang_task_controlled_state_sources_20261018t.json"
const STATE_SOURCES_SHA := "d79fec2cc2e77a9e5329a37573a00c0f57c4a808e163ae4df88fe9307cae5429"
var offer_calls: int = 0
var before_first_offer: Dictionary = {}

func _initialize() -> void:
	budget_ms=30000
	atom_name="T_CONTROLLED_DIALOGPLAYER_STATE_30S"
	# Do not call the NOTREADY draft initializer which names its different scope.
	call_deferred("_run")

func precheck() -> bool:
	if not check(CONTROLLED_READY and OS.get_cmdline_user_args().is_empty(),"Controlled candidate only; no runtime candidate flags"): return false
	for pair: Array in [["res://tests/test_luoyang_layout_task_state_draft_20261018t.gd",OLD_DRAFT_SHA],["res://tests/helpers/cold_sha_qa_retry2_20261017k.gd",TASK_CPU_BASE_SHA],[STATE_SOURCES,STATE_SOURCES_SHA],[TASK_ROOT+"candidate_manifest.json",CURRENT_MANIFEST_SHA],[TASK_ROOT+"source_contract.json",CURRENT_CONTRACT_SHA],[TASK_ROOT+"luoyang_task_projection_candidate.gd",CURRENT_PROJECTION_SHA]]:
		if not track(pair[0],pair[1]): return false
	var frozen: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(STATE_SOURCES))
	if not check(frozen.scope=="CONTROLLED_STATE_SEMANTIC_SUPERSET_NOT_RENDER_OR_FORMAL_HOOK" and frozen.paths.size()==933,"Complete frozen state-semantic source superset, not the old eighteen-path subset"): return false
	for path: String in frozen.paths:
		if not track(path,frozen.paths[path]): return false
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(TASK_ROOT+"candidate_manifest.json"))
	if not check(manifest.status=="SOURCE_READY_NOT_DEPLOYED" and manifest.static_validation.engine_or_field_run==false,"Static source validation is not actual DialogPlayer credit"): return false
	for row: Dictionary in manifest.source_files:
		if not check(not String(row.path).contains(".."),"Candidate relative dependency stays in package") or not track(TASK_ROOT+row.path,row.sha256): return false
	var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(TASK_ROOT+"source_contract.json"))
	for path: String in contract.production_sources:
		if not track("res://"+path.trim_prefix("game/"),contract.production_sources[path].sha256): return false
	if not track("res://art/characters/luoyang_layout_quest_20261018t/npc_temple_gate_monk_idle_down_1f_v1.png","6268061eab18d2bf8c1ea0c13873f0d718feb82a119f00a67edf7c52bcb077ad"): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	api=load(TASK_ROOT+"luoyang_task_projection_candidate.gd")
	dp=root.get_node("DialogPlayer");gs=root.get_node("GameState");qm=root.get_node("QuestManager");inv=root.get_node("Inventory")
	for kind: String in ["longmen","baima","peony"]:
		for phase: String in ["offer","progress","investigate","report","after"]:
			var name: String=kind+"_"+phase
			dialogs[name]=load(TASK_ROOT+"dialogs/"+name+".tres")
			if not check(dialogs[name] is DialogScript and String(dialogs[name].dialog_id)==PREFIX+name,"Exact native candidate DialogScript identity "+name): return false
	records.append({"kind":"CONTROLLED_SCOPE","formal_dispatch_or_resolver_tested":false,"actual_DialogPlayer_QuestManager":true,"QuestDefs_in_memory_only":true,"NPC_projection_Field_import_Render_audio_credit":false,"state_semantic_source_paths":frozen.paths.size()})
	return check(api!=null and dialogs.size()==15,"Frozen candidate authorization plus fifteen native dialogs")

func _state_snapshot() -> Dictionary:
	return {"flags":gs.get("flags").duplicate(true),"quests":qm.call("to_dict").duplicate(true),"inventory":inv.call("to_dict").duplicate(true),"rewards":_value()}

func _guarded_play(name: String) -> bool:
	# This is explicitly a QA-controlled boundary, not the production resolver.
	var before: Dictionary=_state_snapshot()
	if name=="longmen_offer":
		offer_calls+=1
		if offer_calls==1: before_first_offer=before.duplicate(true)
		if offer_calls==2 and not check(before==before_first_offer,"Actual decline leaves ALL flags, quests, inventory and rewards unchanged"): return false
	if not _auth(name):
		check(before==_state_snapshot(),"Unauthorized candidate action has no state effects "+name)
		return false
	dp.call("play",dialogs[name])
	return true

func _projection_matrix() -> bool:
	# New Temple successor is not yet integrated. Do NOT feed the old empty-NPC
	# scene to the new strict two-entity API or fabricate entity/Field credit.
	for phase: int in 4:
		var flags: Dictionary={};var states: Dictionary={}
		for entry: Array in [[api.LONGMEN,api.LONGMEN_STARTED,api.LONGMEN_EVIDENCE],[api.BAIMA,api.BAIMA_STARTED,api.BAIMA_EVIDENCE],[api.PEONY,api.PEONY_STARTED,api.PEONY_ANSWERED]]:
			states[entry[0]]=0 if phase==0 else (2 if phase==3 else 1)
			if phase>0: flags[entry[1]]=true
			if phase>1: flags[entry[2]]=true
		for kind: String in ["longmen","baima","peony"]:
			for action: String in ["offer","progress","investigate","report","after"]:
				var expected: bool=(phase==0 and action=="offer") or (phase==1 and action in ["progress","investigate"]) or (phase==2 and action=="report") or (phase==3 and action=="after")
				if not check(api.authorize_dialog(PREFIX+kind+"_"+action,flags,states)==expected,"Exact phase authorization "+kind+"/"+action+"/"+str(phase)): return false
	if not check(api.authorize_dialog(PREFIX+"unknown",{}, {})==false,"Unknown candidate namespace action rejected"): return false
	return true
