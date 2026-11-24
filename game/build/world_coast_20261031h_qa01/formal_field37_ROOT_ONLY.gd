extends "res://build/world_coast_20261031h_qa01/formal_field36_ROOT_ONLY.gd"
## Narrow residual only. Field32/35/36 original FAIL reports remain unchanged.
## Before loading any Field, collect the real current C graph and require the
## complete Gate expected map plus B.describe, not a count-only substitute.
const GATE_C: String="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const GATE_B: String="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const GATE_P: String="res://build/luoyang_loading_20261024e_perf01/candidate04/gate_source_prewarm04.gd"
const GATE_RAW: String="res://data/scenes/ch4_s0_luoyang_gate.tres"
func boot(domain: String) -> bool:
	var ok: bool=await super.boot(domain)
	directory="res://build/world_coast_20261031h_qa01/formal_field37_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	return ok
func actual_gate_admission() -> bool:
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
	return need(expected.size()==1715 and actual.size()==1715 and changed.is_empty() and added.is_empty() and missing.is_empty() and not described.is_empty(),"ACTUAL_C_COLLECTOR_B_DESCRIBE_EXACT1715_WHOLE_MAP")
func _run() -> void:
	if not await boot("coast37"):finish();return
	base_core=core()
	records.append({"inherited_first_true_boat":"formal_field32_actual/125824/result.json","inherited_reverse_boat_shores_M_mini_plaza_three_images":"formal_field35_actual/128136/result.json","inherited_true_bianzhou_entry_and_return":"formal_field36_actual/138276/result.json","prior_whole_FAILs_retained":true,"successful_components_not_repeated":true})
	if not actual_gate_admission():finish();return
	if not await setup(&"world_map_jianghu",Vector2(4000,2594.4912)/SIZE):finish();return
	var gate: ExitZone
	for candidate: ExitZone in field.get("_exit_nodes"):
		if candidate.target_scene_id=="ch4_s0_luoyang_gate":gate=candidate;break
	if not need(gate!=null and bool(gate.call("can_enter")),"FORMAL16_ORIGINAL_LUOYANG_DOOR_CAN_ENTER"):finish();return
	if not await enter(&"ch4_s0_luoyang_gate"):finish();return
	var arrival: Vector2=foot()
	if not await walk(arrival+Vector2(32,0),12):finish();return
	await shot("formal16_original_luoyang_gate_true_entry")
	need(core()==base_core,"ORIGINAL_PLAYER_PARTY_HP_MP_GOLD_PRESERVED")
	finish()
func finish() -> void:
	if done:return
	key(KEY_NONE);done=true
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"input_events":inputs,"scope":"RESIDUAL_ONLY actual C/B exact1715 before any Field then originalWorld Luoyang trueSpace entry +32px +one normalimage; publiclocal setup notcontinuous travel; all passed boat shore M mini Bianzhou components inherited not repeated","real_save_API_calls":0,"actor_camera_writes":0,"production_writes":0},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
