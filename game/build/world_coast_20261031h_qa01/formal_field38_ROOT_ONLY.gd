extends "res://build/world_coast_20261031h_qa01/formal_field37_ROOT_ONLY.gd"
## Retain actual37 FAIL. Only the same unpassed Luoyang entry residual remains.
## Coordinator.readiness is a pure pre-Field check, not a quest/session action.
func boot(domain: String) -> bool:
	var ok: bool=await super.boot(domain)
	directory="res://build/world_coast_20261031h_qa01/formal_field38_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	return ok
func actual_gate_admission() -> bool:
	var culture: Script=load("res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd") as Script
	if not need(culture!=null,"ACTUAL_CULTURE_COORDINATOR_PRESENT"):return false
	var ready: Dictionary=culture.call("readiness")
	records.append({"pre_field_actual_CULTURE_readiness":ready,"no_quest_or_session_actions":true,"original37_fail_retained":"formal_field37_actual/133864/result.json"})
	if not need(ready.get("ok")==true,"ACTUAL_CULTURE_READINESS_BEFORE_ANY_FIELD"):return false
	var contract: Script=load(GATE_C) as Script
	var bundle: Script=load(GATE_B) as Script
	var prewarm: Script=load(GATE_P) as Script
	var raw: SceneScript=ResourceLoader.load(GATE_RAW,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(contract!=null and bundle!=null and prewarm!=null and raw!=null,"ACTUAL_GATE_COLLECTOR_INPUTS_PRESENT"):return false
	var expected: Dictionary=prewarm.call("gate_expected_map")
	var paths: Dictionary=contract.call("_transition_sources",raw,false)
	var actual: Dictionary={}
	for path: String in paths:actual[path]=FileAccess.get_sha256(path)
	var changed: Array=[];var added: Array=[];var missing: Array=[]
	for path: String in expected:
		if not actual.has(path):missing.append(path)
		elif actual[path]!=expected[path]:changed.append({"path":path,"expected":expected[path],"actual":actual[path]})
	for path: String in actual:
		if not expected.has(path):added.append(path)
	var described: Dictionary=bundle.call("describe",&"ch4_s0_luoyang_gate",actual)
	records.append({"pre_field_actual_C_collector":GATE_C,"actual_bundle":GATE_B,"expected_count":expected.size(),"actual_count":actual.size(),"changed_pins":changed,"added_paths":added,"missing_paths":missing,"describe_ready":not described.is_empty(),"actual_source_sha256":actual,"expected_source_sha256":expected})
	return need(expected.size()==1716 and actual.size()==1716 and changed.is_empty() and added.is_empty() and missing.is_empty() and not described.is_empty(),"ACTUAL_C_COLLECTOR_B_DESCRIBE_EXACT1716_WHOLE_MAP")
func finish() -> void:
	if done:return
	key(KEY_NONE);done=true
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"input_events":inputs,"scope":"RESIDUAL_ONLY pureCULTURE.readiness and actualC/B exact1716 before anyField then originalWorld Luoyang trueSpace entry +32px +one normalimage; inherited37_run; publiclocal setup notcontinuous travel; all passed boat shore M mini Bianzhou components not repeated","real_save_API_calls":0,"actor_camera_writes":0,"production_writes":0},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
