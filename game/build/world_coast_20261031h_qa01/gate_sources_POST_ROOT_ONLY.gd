extends SceneTree
## Run only after Root formal source selection. No Field or save APIs.
const ROOT: String="res://build/world_coast_20261031h_qa01/"
var suspended:=false
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge":node.call("set_checkpoint_saves_suspended",true);suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _run() -> void:
	await process_frame
	var directory: String=ROOT+"gate_sources_post_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	var bundle: Script=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd") as Script
	var collector: Script=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd") as Script
	var prewarm: Script=load("res://build/luoyang_loading_20261024e_perf01/candidate04/gate_source_prewarm04.gd") as Script
	var raw: Resource=ResourceLoader.load("res://data/scenes/ch4_s0_luoyang_gate.tres","",ResourceLoader.CACHE_MODE_IGNORE)
	var expected: Dictionary=prewarm.call("gate_expected_map");var keys: Dictionary=collector.call("_transition_sources",raw,false);var actual: Dictionary={}
	for path: String in keys:actual[path]=FileAccess.get_sha256(path)
	var changed: Array=[];var added: Array[String]=[];var missing: Array[String]=[]
	for path: String in actual:
		if not expected.has(path):added.append(path)
		elif actual[path]!=expected[path]:changed.append({"path":path,"expected":expected[path],"actual":actual[path]})
	for path: String in expected:
		if not actual.has(path):missing.append(path)
	var result: Dictionary=bundle.call("describe",&"ch4_s0_luoyang_gate",actual)
	var passed: bool=suspended and not expected.is_empty() and not actual.is_empty() and not result.is_empty() and changed.is_empty() and added.is_empty() and missing.is_empty()
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"expected_count":expected.size(),"actual_count":actual.size(),"changed_pins":changed,"added_paths":added,"missing_paths":missing,"actual_B_describe_accepted":not result.is_empty(),"expected_recipe_self_match_is_not_current_credit":true,"checkpoint_suspended":suspended,"scene_instances":0,"input_events":0,"real_save_API_calls":0,"production_writes":0},"\t"));file.close()
	quit(0 if passed else 1)
