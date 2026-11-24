extends "res://tests/helpers/cold_sha_qa_retry2_20261017k.gd"
## One actual workspace, OLD packet once, NEW packet once through real Module.
const DIR="res://build/luoyang_module_source_receipt_20261017m_source01/"
const OLD=preload("res://scripts/city/luoyang_gate_fortification_contract_20261013.gd")
const GATE=preload("res://build/luoyang_module_source_receipt_20261017m_source01/gate_qa_adapted.gd")
const MODULE=preload("res://build/luoyang_module_source_receipt_20261017m_source01/module_qa_adapted.gd")
const STABLE=preload("res://build/luoyang_module_source_receipt_20261017m_source01/stable_candidate.gd")
const WORKSPACE=preload("res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd")
const L_RESULT="res://build/luoyang_object_mapping_cold_gate_20261017l/83180_2534/result.json"
const ID=&"ch4_s0_luoyang_gate"
const TOKEN=871
const BASE_PATH="res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s0_luoyang_gate/art_contract.json"
const PATCH_PATH="res://art/maps/luoyang_enclosure_v11/ch4_s0_luoyang_gate/art_patch.json"
const PLAN_PATH="res://art/maps/luoyang_enclosure_v11/ch4_s0_luoyang_gate/export_plan.json"
var sources: Dictionary={}
var base_record: Dictionary={}
var prior: Dictionary={}
var approval: Dictionary={}
var context: Variant
var module: Variant
var old_packet: Dictionary={}
var old_usec: int

func _initialize() -> void:
	atom_name="MODULE_SOURCE_RECEIPT_20261017M_30S";budget_ms=30000
	super._initialize()

func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))

func _asset(path: String) -> bool:
	return check(sources.has(path),"Used asset in actual l625 source proof "+path) and track(path,sources.get(path,""))

func precheck() -> bool:
	var pins: Dictionary={
		DIR+"gate_candidate.gd":"23719d1be5633ddf681c08ae220fb1196853bfc54894b08c484a48a2df0121b3",
		DIR+"module_candidate.gd":"95f1c05c217868857f91da21bae460cc27e7813a47e907dc47dec3bbaa3560e0",
		DIR+"stable_candidate.gd":"29001631c265538b8d89a7aa13896017bdd49b74d1396bd488c7a810153cd784",
		DIR+"C_candidate.gd":"3deb7395e2441f94068377c905e5a9e85222416c672834bbfad1754b22ac50ca",
		DIR+"gate_qa_adapted.gd":"0789fba7eb35ed3acf1b808cec10cd8fd920fb4ba35d140ac1e1bc797f75f807",
		DIR+"module_qa_adapted.gd":"3265cd30a81760414fb6f984cd5b8a66a53d70eec60bfe6911b1513adeb2023e",
		"res://scripts/city/luoyang_gate_fortification_contract_20261013.gd":"62a9f85d9ee8cd6cd295c089a70060809c1df14d896b66027a269ef0cbd3caa7",
		WORKSPACE.SELF_PATH:"57a9db94512afb4e286605eab778bb5ae1d1751a17fc56074a28ec042fe1df48",
		"res://tests/helpers/cold_sha_qa_retry2_20261017k.gd":"001717611f3ec5a8f3cd3df518471f51a3b7c213bfe9592d48bb619b14919102",
		L_RESULT:"02037915cad7c7389b2b25777ee51545c51a1ce274a2ca73856da7434998e26a"}
	for path: String in pins:
		if not track(path,pins[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	if not check(FileAccess.get_file_as_string(DIR+"gate_candidate.gd").replace("res://scripts/city/luoyang_gate_stable_imports_20261017.gd",DIR+"stable_candidate.gd")==FileAccess.get_file_as_string(DIR+"gate_qa_adapted.gd"),"Gate bridge only exact one preload path replacement"): return false
	if not check(FileAccess.get_file_as_string(DIR+"module_candidate.gd").replace("res://scripts/city/luoyang_gate_fortification_contract_20261013.gd",DIR+"gate_qa_adapted.gd")==FileAccess.get_file_as_string(DIR+"module_qa_adapted.gd"),"Module bridge only exact one preload path replacement"): return false
	var result: Dictionary=_json(L_RESULT);var proof: Dictionary={}
	if not check(result.get("complete")==true and result.get("failures")==0,"Actual successful l source evidence"): return false
	for row: Dictionary in result.records:
		if row.get("kind")=="ACTUAL_GATE_FULL_SOURCE_PROOF": proof=row.proof
	if not check(proof.get("sources_finalized")==true and proof.get("sources",{}).size()==625,"Complete current asset input proof, not invented source dictionary"): return false
	sources=proof.sources.duplicate(true)
	for path: String in [BASE_PATH,PATCH_PATH,PLAN_PATH,OLD.AUTHOR_PATH,OLD.MANIFEST_PATH,STABLE.APPROVAL_PATH,STABLE.PREPARED_PATH,OLD.BASE.SELF_PATH,OLD.BASE.DETAIL_CHECKER_PATH,OLD.BASE.DETAIL_CHECKER.ORIGINAL_CHECKER_PATH,OLD.STABLE_IMPORTS.SELF_PATH]:
		if not _asset(path): return false
	base_record=_json(BASE_PATH);var patch: Dictionary=_json(PATCH_PATH)
	var ground_path: String=proof.input.get("metadata/city_ground_manifest_path","")
	if not _asset(ground_path) or not check(sources[ground_path]==proof.input.get("metadata/city_ground_manifest_sha"),"Frozen actual original ground sidecar identity"): return false
	var ground: Dictionary=_json(ground_path)
	prior=base_record.duplicate(true);var objects: Array=[];var removed: Dictionary={}
	for id: String in patch.remove_object_ids: removed[id]=false
	for item: Dictionary in prior.objects:
		if removed.has(String(item.id)): removed[String(item.id)]=true
		else: objects.append(item)
	for id: String in removed:
		if not check(removed[id]==true,"Actual prior Base removal "+id): return false
	for item: Dictionary in patch.objects: objects.append(item)
	prior.objects=objects;prior.walk_path=patch.walk_path
	for catalogue: Dictionary in [patch.asset_sha256,ground.asset_sha256]:
		for path: String in catalogue: prior.asset_sha256[path]=catalogue[path]
	prior.ground_path=ground.ground_path;prior.ground_capture_path=ground_path;prior.ground_capture_sha256=sources[ground_path]
	prior.enclosure_patch_path=PATCH_PATH;prior.enclosure_patch_sha256=sources[PATCH_PATH]
	prior.enclosure_base_manifest_path=BASE_PATH;prior.enclosure_base_manifest_sha256=sources[BASE_PATH]
	if not check(prior.objects.size()==22 and prior.canonical_scene_id==String(ID),"Pure frozen V11 pre-module data projection22 objects, not final Harbour record"): return false
	var needed: Dictionary={};var config: Dictionary=_json(OLD.AUTHOR_PATH)
	for kind: String in ["wall","tower"]:
		var path: String=config.native_captures[kind].path
		if not _asset(path): return false
		var report: Dictionary=_json(path)
		for asset: String in report.consumer_catalog.source_catalog.sha256_by_res_path: needed[asset]=true
	for path: String in _json(OLD.MANIFEST_PATH).asset_sha256: needed[path]=true
	approval=_json(STABLE.APPROVAL_PATH)
	for path: String in approval.source_sha256: needed[path]=true
	var prefix: String=WORKSPACE.ROOT+String(ID)+"/"
	for role: String in ["on","off"]:
		for suffix: String in ["_raw.png","_raw_repeat.png"]: needed[prefix+"ground_"+role+suffix]=true
	needed[prefix+"floor.png"]=true
	for item: Dictionary in base_record.objects:
		if String(item.get("prototype","")) not in ["wall_horizontal","wall_vertical"]: continue
		var stem: String=prefix+"entities/native_"+str(item.prototype)
		for suffix: String in [".json","_raw.png","_raw_repeat.png",".png"]: needed[stem+suffix]=true
	for path: String in needed:
		if not _asset(path): return false
	return true

static func _never_cancel() -> bool: return false
static func _no_progress(_phase: String,_completed: int,_total: int) -> void: pass

func _old_run() -> void:
	var started: int=Time.get_ticks_usec()
	old_packet=OLD.read_after_original_cpu(prior,Callable(get_script(),"_never_cancel"),Callable(get_script(),"_no_progress"))
	old_usec=Time.get_ticks_usec()-started

func _joined_thread(target: Object,method: String) -> bool:
	var thread:=Thread.new()
	if not check(thread.start(Callable(target,method))==OK,"Actual independent CPU Thread "+method): return false
	while thread.is_alive():
		if Time.get_ticks_msec()>=deadline:
			if target.has_method("request_cancel"): target.call("request_cancel")
			check(false,"Original30s deadline; join, never extend");break
		await process_frame
	thread.wait_to_finish()
	return check(not thread.is_started() and Time.get_ticks_msec()<deadline,"Actual thread joined within original budget "+method)

func _configure_refuses(value: RefCounted,token: int,id: StringName,label: String) -> bool:
	var test: RefCounted=MODULE.new()
	var accepted: bool=test.call("configure",token,id,prior,value)
	test.call("release")
	return check(not accepted,label+" real Module.configure refuses")

func _variant(path: String,old_sha: String) -> bool:
	return STABLE.matches_from_receipt(path,old_sha,context,TOKEN,ID)

func exercise() -> bool:
	context=WORKSPACE.new()
	if not check(context.configure(TOKEN,ID,base_record,sources,Callable(OLD.BASE.DETAIL_CHECKER.ORIGINAL_CHECKER,"_alpha_reconstruct")),"Real canonical workspace configure, actual625 asset inputs"): return false
	if not await _joined_thread(context,"run"): context.release();return false
	if not check(context.mark_joined(TOKEN,ID) and context.matches(TOKEN,ID,WORKSPACE.ROOT+String(ID)+"/",base_record,base_record.asset_sha256),"Original workspace truly complete/joined/full input bound"): context.release();return false
	if not await _joined_thread(self,"_old_run"): context.release();return false
	if not check(not old_packet.is_empty() and not old_packet.has("error"),"OLD full3arg disk pipeline accepts true V11 prior",old_packet.get("error","")): context.release();return false
	module=MODULE.new()
	if not check(module.configure(TOKEN,ID,prior,context) and module.get("_source_context")==context,"NEW Module accepts and strongly retains actual joined owner"): context.release();return false
	if not await _joined_thread(module,"run"): module.release();context.release();return false
	if not check(module.mark_joined(TOKEN,ID),"NEW actual Module joined same owner"): module.release();context.release();return false
	var packet: Dictionary=module.packet(TOKEN,ID)
	var equal: bool=var_to_bytes(old_packet)==var_to_bytes(packet)
	var okay: bool=check(equal and not packet.is_empty() and not packet.has("error"),"Whole OLD/NEW packet exact native var bytes, no numeric normalization")
	if not okay: records.append({"kind":"PACKET_FAILURE","old_keys":old_packet.keys(),"new_keys":packet.keys(),"error":packet.get("error","")})
	if not okay: module.release();context.release();return false
	okay=check(packet.imports.size()==2 and packet.walk_bytes==old_packet.walk_bytes,"Both imports plus complete walk bytes retained") and okay
	for i: int in 2:
		var a: Dictionary=old_packet.imports[i];var b: Dictionary=packet.imports[i]
		okay=check(a.path==b.path and a.size==b.size and a.bytes==b.bytes and b.bytes.size()==3072*2048*4,"Actual complete raw RGBA import packet "+str(i)) and okay
	records.append({"kind":"WHOLE_PACKET_EXACT","old_usec":old_usec,"new_module_ms":module.elapsed_ms,"imports_count":packet.imports.size(),"import_bytes_each":3072*2048*4,"whole_var_bytes_exact":equal,"current_native_catalog_exact":var_to_bytes(old_packet.native)==var_to_bytes(packet.native),"prior_objects":prior.objects.size(),"no_Field_or_imported_Texture_credit":true})
	okay=_configure_refuses(context,TOKEN+1,ID,"Wrong token") and _configure_refuses(context,TOKEN,&"ch4_s1_luoyang_yamen","Wrong id") and _configure_refuses(RefCounted.new(),TOKEN,ID,"Wrong Script") and okay
	context.set("_joined",false)
	okay=_configure_refuses(context,TOKEN,ID,"Unjoined actual workspace") and check(STABLE._approval_from_receipt(context,TOKEN,ID).is_empty(),"Unjoined approval fails closed") and okay
	context.set("_joined",true)
	var original: Dictionary=context.get("_sources").duplicate(true)
	for row: Dictionary in STABLE.ROWS:
		for pair: Array in [[String(row.texture)+".import",row.old_import],[row.compiled,row.old_compiled]]:
			okay=check(_variant(pair[0],pair[1]) and not _variant(pair[0],"0".repeat(64)),"Each approved8 path and strict historical SHA "+str(pair[0])) and okay
		okay=check(not GATE._source(String(row.texture)+".import",row.new_import,context,TOKEN),"Handled path cannot bypass authority by claiming current SHA") and okay
		for path: String in [row.texture,String(row.texture)+".import",row.compiled]:
			for altered: bool in [false,true]:
				var changed: Dictionary=original.duplicate(true)
				if altered: changed[path]="0".repeat(64)
				else: changed.erase(path)
				context.set("_sources",changed)
				okay=check(FileAccess.file_exists(path) and not _variant(String(row.texture)+".import",row.old_import),"Actual existing group leaf missing/altered receipt, no fallback "+path+"/"+str(altered)) and okay
				context.set("_sources",original)
	okay=check(not _variant(BASE_PATH,sources[BASE_PATH]),"Fifth non-approved path refused by compatibility helper") and okay
	for path: String in approval.source_sha256:
		for altered: bool in [false,true]:
			var changed: Dictionary=original.duplicate(true)
			if altered: changed[path]="0".repeat(64)
			else: changed.erase(path)
			context.set("_sources",changed)
			okay=check(STABLE._approval_from_receipt(context,TOKEN,ID).is_empty(),"All15 approval leaves missing/wrong source refuses "+path+"/"+str(altered)) and okay
			context.set("_sources",original)
	context.request_cancel()
	okay=_configure_refuses(context,TOKEN,ID,"Cancelled actual workspace") and check(STABLE._approval_from_receipt(context,TOKEN,ID).is_empty(),"Cancelled approval refuses") and okay
	module.release();okay=check(module.get("_source_context")==null,"Module release drops strong source context after join") and okay
	context.release();module=null;context=null;old_packet.clear();packet.clear()
	records.append({"kind":"SCOPE","budget_ms":30000,"actual_workspaces":1,"OLD_full_packets":1,"NEW_Module_full_packets":1,"approved_paths":8,"approval_leaves":15,"prior_is_source_data_projection_not_C_prepare":true,"live_source_or_saves_mutated":false,"Market_or_warm_tested":false})
	return okay
