extends SceneTree
## Root only AFTER exact16 candidate deployment; no Field or save APIs.
const C := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const B := "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const P := "res://build/luoyang_loading_20261024e_perf01/candidate04/gate_source_prewarm04.gd"
const DISPATCH := "res://build/world_coast_20261031h_system02/world_contract_dispatch02.gd"
const RAW := "res://data/scenes/ch4_s0_luoyang_gate.tres"
const ID := &"ch4_s0_luoyang_gate"
var _suspended := false

func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred()

func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true)
		_suspended=bool(node.call("is_checkpoint_saves_suspended"))

func _run() -> void:
	await process_frame
	var errors: Array[String]=[]
	if not "--coast-v16-source-probe" in OS.get_cmdline_user_args():errors.append("EXPLICIT_ROOT_PROBE_FLAG_REQUIRED")
	if not _suspended:errors.append("CHECKPOINT_NOT_SUSPENDED")
	var contract: Script=load(C) as Script
	var dispatch: Script=load(DISPATCH) as Script
	if contract==null or not contract.has_method("_world_v16_source_paths"):errors.append("NEW16_C_BRANCH_NOT_DEPLOYED")
	if dispatch==null or int(dispatch.call("formal_version"))!=16:errors.append("FORMAL16_NOT_DEPLOYED_NO_OLD_PREFIX_CREDIT")
	var result: Dictionary={"errors":errors,"engine_pid":OS.get_process_id(),"scene_instances":0,"input_events":0,"real_save_API_calls":0,"source_writes":0,"checkpoint_suspended":_suspended}
	if errors.is_empty():
		var world_pins: Dictionary=contract.call("_world_v16_source_paths")
		if world_pins.size()!=7:errors.append("EXACT7_WORLD_PROOF_INPUTS_NOT_READY")
		var raw:=ResourceLoader.load(RAW,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var bundle: Script=load(B) as Script
		var prewarm: Script=load(P) as Script
		var expected: Dictionary=prewarm.call("gate_expected_map")
		var keys: Dictionary=contract.call("_transition_sources",raw,false)
		var actual: Dictionary={}
		for path: String in keys:actual[path]=FileAccess.get_sha256(path)
		var changed: Array=[]
		var added: Array=[]
		var missing: Array=[]
		for path: String in expected:
			if not actual.has(path):missing.append(path)
			elif actual[path]!=expected[path]:changed.append({"path":path,"expected":expected[path],"actual":actual[path]})
		for path: String in actual:
			if not expected.has(path):added.append(path)
		var described: Dictionary=bundle.call("describe",ID,actual)
		if expected.is_empty() or actual.is_empty() or not changed.is_empty() or not added.is_empty() or not missing.is_empty() or described.is_empty():errors.append("ACTUAL_COLLECTOR_DESCRIBE_EXACT_MAP_REJECTED")
		result.merge({"actual_expected_count":expected.size(),"actual_collector_count":actual.size(),"changed_pins":changed,"added_paths":added,"missing_paths":missing,"describe_ready":not described.is_empty(),"world_proof_count":world_pins.size(),"collector":C,"bundle":B},true)
	result.passed=errors.is_empty()
	result.scope="ACTUAL_NEW16_SOURCE_COLLECTOR_ONLY_NOT_FIELD_OR_ART"
	var directory: String="res://build/world_coast_20261031h_system03/probe_actual/"+str(OS.get_process_id())+"_"+str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(directory)
	var output:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if output!=null:output.store_string(JSON.stringify(result,"\t")+"\n");output.close()
	print("COAST16_SOURCE_PROBE ",directory+"/result.json errors=",errors.size())
	quit(0 if errors.is_empty() else 1)
