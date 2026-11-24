extends SceneTree
## Root-only current Gate bundle rejection, no Field or synthetic travel.
const B := "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const C := "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const P := "res://build/luoyang_loading_20261024e_perf01/candidate04/gate_source_prewarm04.gd"
const RAW := "res://data/scenes/ch4_s0_luoyang_gate.tres"
const ID := &"ch4_s0_luoyang_gate"
func _initialize() -> void:call_deferred("_run")
func _run() -> void:
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	var bundle: Script=load(B) as Script;var contract: Script=load(C) as Script;var prewarm: Script=load(P) as Script
	var raw:=ResourceLoader.load(RAW,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var expected: Dictionary=prewarm.call("gate_expected_map")
	var keys: Dictionary=contract.call("_transition_sources",raw,false)
	var actual: Dictionary={}
	for path: String in keys:actual[path]=FileAccess.get_sha256(path)
	var changed: Array=[];var added: Array=[];var missing: Array=[]
	for path: String in expected:
		if not actual.has(path):missing.append(path)
		elif actual[path]!=expected[path]:changed.append({"path":path,"bundle_expected":expected[path],"actual_current":actual[path]})
	for path: String in actual:
		if not expected.has(path):added.append(path)
	var described: Dictionary=bundle.call("describe",ID,actual)
	var result: Dictionary={"passed":not described.is_empty(),"diagnostic_current_bundle_rejected":described.is_empty(),"expected_recipe_self_match_not_current_credit":not expected.is_empty(),"actual_current_source_collector":C,"expected_count":expected.size(),"actual_count":actual.size(),"changed_pins":changed,"added_current_paths":added,"missing_current_paths":missing,"bundle_manifest_sha":FileAccess.get_sha256("res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json"),"source_scene_original_path":raw.resource_path if raw!=null else "","checkpoint_suspended":bridge.call("is_checkpoint_saves_suspended"),"scene_instances":0,"input_events":0,"real_save_API_calls":0,"source_writes":0}
	var directory: String="res://build/luoyang_entry_20261031e_qa01/bundle_pre_actual/"+str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(result,"\t"));file.close()
	print("BUNDLE31E_CURRENT ",directory+"/result.json expected=",expected.size()," actual=",actual.size()," changed=",changed.size()," added=",added.size()," rejected=",described.is_empty())
	quit(1 if described.is_empty() else 0)
