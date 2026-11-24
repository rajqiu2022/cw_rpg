extends "res://tests/helpers/cold_sha_qa_retry2_20261017k.gd"
## One real joined Gate workspace; exact17 object slices, not capture/Field/GPU.
const OLD_PATH="res://build/luoyang_object_mapping_receipt_20261017l_source01/original_checker_1D7B.gd"
const NEW_PATH="res://build/luoyang_object_mapping_receipt_20261017l_source01/original_checker_candidate.gd"
const OLD=preload("res://build/luoyang_object_mapping_receipt_20261017l_source01/original_checker_1D7B.gd")
const NEW=preload("res://build/luoyang_object_mapping_receipt_20261017l_source01/original_checker_candidate.gd")
const WORKSPACE=preload("res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd")
const K_RESULT="res://build/luoyang_cold_source_gate_entry_20261017k/39608_2545/result.json"
const BASE_PATH="res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s0_luoyang_gate/art_contract.json"
const ID=&"ch4_s0_luoyang_gate"
const TOKEN=771
var input_record: Dictionary={}
var prior_record: Dictionary={}
var complete_sources: Dictionary={}
var job: Variant

func _initialize() -> void:
	atom_name="OBJECT_MAPPING_RECEIPT_20261017L_30S";budget_ms=30000
	super._initialize()

func precheck() -> bool:
	atom_name="OBJECT_MAPPING_RECEIPT_20261017L_30S";budget_ms=30000
	var pins: Dictionary={
		OLD_PATH:"1d7b01750b526df05084da3dc280ad27f662bfc6b3ee776a06aa025a0b886018",
		NEW_PATH:"17297869279c43e068e442e7269c57cc4d986b5b26c9a2374883d6ff97cb5481",
		"res://tests/helpers/cold_sha_qa_retry2_20261017k.gd":"001717611f3ec5a8f3cd3df518471f51a3b7c213bfe9592d48bb619b14919102",
		WORKSPACE.SELF_PATH:"57a9db94512afb4e286605eab778bb5ae1d1751a17fc56074a28ec042fe1df48",
		K_RESULT:"3ae5e7860f699a8b7c2bc6b43d132647a6cc72d360809b65215a4c254f8d5b7c",
		BASE_PATH:"2818f9fca10d30abbbbd386ff2b26a3d4ed87f300a9b8ef47f882bcb83f7640d",
		"res://scripts/dev/luoyang_v3_wall_v5_note_saved_resource_checker.gd":"10559051d50480fd1735bb8619b7e307ac654306115fa8b00d26d842795531d4",
		"res://build/luoyang_object_mapping_receipt_20261017l_source01/note_checker_candidate.gd":"7e3dd58d49a628e7b9ae3af428f050526bc5c7b473873c93b10dde5908ff3825"}
	for path: String in pins:
		if not track(path,pins[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	var result: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(K_RESULT))
	if not check(result.get("complete")==true and result.get("failures")==0,"Pinned actual cold Gate complete625 source proof"): return false
	for row: Dictionary in result.records:
		if row.get("kind")=="ACTUAL_GATE_FULL_SOURCE_PROOF":
			if not check(row.proof.get("sources_finalized")==true,"Actual C first/final finalized, not fabricated workspace sources"): return false
			complete_sources=row.proof.sources.duplicate(true)
	if not check(complete_sources.size()==625,"Exact current k full input set retained; only used leaves freshly guarded here"): return false
	input_record=JSON.parse_string(FileAccess.get_file_as_string(BASE_PATH))
	var prior_path: String=OLD.OLD_ROOT+String(ID)+"/art_contract.json"
	if not _asset(prior_path): return false
	prior_record=JSON.parse_string(FileAccess.get_file_as_string(prior_path))
	if not check(input_record.objects.size()==17,"All17 Gate objects, no prototype-only shortcut"): return false
	var paths: Dictionary={}
	var prefix: String=WORKSPACE.ROOT+String(ID)+"/"
	for role: String in ["on","off"]:
		for suffix: String in ["_raw.png","_raw_repeat.png"]: paths[prefix+"ground_"+role+suffix]=true
	paths[prefix+"floor.png"]=true
	for object: Dictionary in input_record.objects:
		paths[String(object.texture)]=true
		var before: Dictionary=_find(prior_record.objects,String(object.id))
		if not check(not before.is_empty(),"Original object identity "+str(object.id)): return false
		paths[String(before.texture)]=true
		var kind: String=String(object.get("prototype",""))
		if kind.is_empty(): continue
		for root_path: String in [prefix,OLD.OLD_ROOT+String(ID)+"/"]:
			paths[root_path+"entities/native_"+kind+".json"]=true
		for suffix: String in [".res",".json",".png","_raw.png","_raw_repeat.png"]:
			paths[prefix+"entities/native_"+kind+suffix]=true
	for path: String in paths:
		if not _asset(path): return false
	var old_text: String=FileAccess.get_file_as_string("res://scripts/dev/luoyang_v3_wall_v5_note_saved_resource_checker.gd")
	var new_text: String=FileAccess.get_file_as_string("res://build/luoyang_object_mapping_receipt_20261017l_source01/note_checker_candidate.gd")
	if not check(old_text.replace("1d7b01750b526df05084da3dc280ad27f662bfc6b3ee776a06aa025a0b886018","17297869279c43e068e442e7269c57cc4d986b5b26c9a2374883d6ff97cb5481")==new_text,"Market Note full algorithm exact; only original-checker pin, no Market speed claim"): return false
	return true

func _asset(path: String) -> bool:
	return check(complete_sources.has(path),"Used real asset is in actual complete C proof "+path) and track(path,complete_sources.get(path,""))

func _find(rows: Array,id: String) -> Dictionary:
	for row: Dictionary in rows:
		if row.get("id")==id: return row
	return {}

func _state(context: RefCounted,which: StringName=ID) -> Dictionary:
	var state: Dictionary={"record":input_record,"catalog":input_record.asset_sha256,"id":which,"cpu_context":context,"old":prior_record,"prefix":WORKSPACE.ROOT+String(ID)+"/","old_prefix":OLD.OLD_ROOT+String(ID)+"/"}
	var error: String=OLD._validation_objects_begin(state)
	check(error.is_empty(),"Unmodified original object-state setup",error)
	return state

func _snapshot(state: Dictionary) -> Dictionary:
	var value: Dictionary={}
	for key: String in ["seen","prototypes","object_skip","object_wall","object_metadata","object_old_metadata","object_stem","object_old_stem","object_kind"]:
		if state.has(key): value[key]=state[key]
	return value.duplicate(true)

func _same_slice(old_state: Dictionary,new_state: Dictionary,item: Dictionary,label: String,expect_success: bool) -> bool:
	var started: int=Time.get_ticks_usec()
	var old_error: String=OLD._validation_object(old_state,item)
	var old_usec: int=Time.get_ticks_usec()-started
	started=Time.get_ticks_usec()
	var new_error: String=NEW._validation_object(new_state,item)
	var new_usec: int=Time.get_ticks_usec()-started
	var snapshots_equal: bool=var_to_bytes(_snapshot(old_state))==var_to_bytes(_snapshot(new_state))
	records.append({"kind":"EXACT_OBJECT_SLICE","label":label,"id":item.id,"old_error":old_error,"new_error":new_error,"state_exact":snapshots_equal,"old_usec":old_usec,"new_usec":new_usec})
	return check(old_error==new_error and snapshots_equal and (old_error.is_empty()==expect_success),label+" exact return and all mutated state",{"old":old_error,"new":new_error})

func _receipt_reject(item: Dictionary,label: String,which: StringName=ID) -> bool:
	var state: Dictionary=_state(job,which)
	var error: String=NEW._validation_object(state,item)
	records.append({"kind":"LIVE_RECEIPT_REFUSAL","label":label,"error":error,"joined":job.get("_joined"),"cancelled":job.is_cancelled()})
	return check(not error.is_empty(),label+" fails closed without file fallback",error)

func exercise() -> bool:
	job=WORKSPACE.new()
	if not check(job.configure(TOKEN,ID,input_record,complete_sources,Callable(OLD,"_alpha_reconstruct")),"Real exact Script workspace configure from actual source proof"): return false
	var thread:=Thread.new()
	if not check(thread.start(Callable(job,"run"))==OK,"One actual background image workspace Thread"): return false
	while thread.is_alive():
		if Time.get_ticks_msec()>=deadline: job.request_cancel();break
		await process_frame
	thread.wait_to_finish()
	if not check(job.mark_joined(TOKEN,ID) and job.matches(TOKEN,ID,WORKSPACE.ROOT+String(ID)+"/",input_record,input_record.asset_sha256),"Actually ran and joined original workspace; full input identity"): job.release();return false
	var old_state: Dictionary=_state(job);var new_state: Dictionary=_state(job)
	var okay:=true
	for item: Dictionary in input_record.objects:
		okay=_same_slice(old_state,new_state,item,"Gate all17 / "+str(item.id),true) and okay
	var tree: Dictionary=_find(input_record.objects,"street_tree_0")
	var wall: Dictionary=_find(input_record.objects,"south_wall_388")
	var tree_before: Dictionary=_find(prior_record.objects,"street_tree_0")
	var old_path: String=tree_before.texture
	var tree_path: String=tree.texture
	for path: String in [old_path,tree_path]:
		okay=check(job.source_sha(ID,path)==FileAccess.get_sha256(path),"Joined source value exact independent FileAccess "+path) and okay
	okay=_same_slice(_state(null),_state(null),tree,"Sync/Web null context retains original disk expression",true) and okay
	var bad: Dictionary=wall.duplicate(true);bad.world_foot_px[0]+=1.0
	okay=_same_slice(_state(job),_state(job),bad,"Physical foot1px changed must still reject",false) and okay
	bad=wall.duplicate(true);bad.native_transform.origin[0]+=1.0/64.0
	okay=_same_slice(_state(job),_state(job),bad,"Caster transform1px changed must still reject",false) and okay
	var bad_catalog: Dictionary=input_record.asset_sha256.duplicate(true);bad_catalog[tree_path]="0".repeat(64)
	okay=check(not job.matches_input(ID,WORKSPACE.ROOT+String(ID)+"/",input_record,bad_catalog),"Real outer complete catalogue identity rejects wrong SHA") and okay
	var a: Dictionary=_state(job);var b: Dictionary=_state(job);a.catalog=bad_catalog;b.catalog=bad_catalog
	okay=_same_slice(a,b,tree,"Wrong catalogue SHA still exact original rejection",false) and okay
	okay=check(not job.matches_owner(TOKEN+1,ID),"Wrong request token rejected by existing owner contract") and okay
	okay=_receipt_reject(tree,"Wrong city ID",&"ch4_s1_luoyang_yamen") and okay
	job.set("_joined",false)
	okay=check(not job.ready(),"Actual unjoined workspace not ready") and _receipt_reject(tree,"Unjoined/unready") and okay
	job.set("_joined",true)
	var original_sources: Dictionary=job.get("_sources").duplicate(true)
	var missing: Dictionary=original_sources.duplicate(true);missing.erase(old_path)
	job.set("_sources",missing)
	okay=check(FileAccess.file_exists(old_path) and job.source_sha(ID,old_path).is_empty(),"Missing old receipt path while real file still exists") and _receipt_reject(tree,"Missing existing old PNG source") and okay
	job.set("_sources",original_sources)
	var wrong_sources: Dictionary=original_sources.duplicate(true);wrong_sources[old_path]="0".repeat(64)
	job.set("_sources",wrong_sources)
	okay=_receipt_reject(tree,"Wrong old PNG receipt SHA") and okay
	job.set("_sources",original_sources)
	job.request_cancel()
	okay=check(not job.ready() and not job.matches_owner(TOKEN,ID),"Cancelled workspace owner invalid") and _receipt_reject(tree,"Cancelled actual workspace") and _receipt_reject(wall,"Cancelled actual wall mesh source") and okay
	job.release();job=null
	records.append({"kind":"SCOPE","Gate_objects":17,"actual_workspaces":1,"Market_algorithm_unchanged_text_only":true,"real_C_prepare_or_Field":false,"full_RGBA_mesh_material_checks_not_replaced_by_this_test":true,"source_mutation_is_local_fixture_dictionary_only":true})
	return okay
