extends SceneTree
## Root-only read-only current Market C -> B exact source-set diagnostic, no travel.
const HOME := "res://build/loading_20261106_system01/"
var suspended := false
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	_run.call_deferred()
func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true)
		suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _run() -> void:
	await process_frame
	if not suspended:
		printerr("MARKET_DIAGNOSTIC_SAVE_SUSPEND_FAILED")
		quit(2)
		return
	var id: StringName=&"ch4_s3_luoyang_market"
	var router: Node=root.get_node("SceneRouter")
	var path: String=router.call("field_scene_resource_path",id)
	var scene: Resource=load(path)
	var c: GDScript=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	var b: GDScript=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
	var actual: Dictionary=c.call("_transition_sources",scene,true)
	var config: Dictionary=b.call("manifest",id)
	var expected: Dictionary=config.get("legacy_source_sha256",{}).duplicate(true)
	expected.merge(config.get("runtime_authority_sha256",{}))
	expected.merge(config.get("artifacts",{}))
	for index: String in [b.INDEX,b.ESTATE_INDEX,b.AO_INDEX,b.AP_INDEX,b.AP_ENV_INDEX,b.AP_EXEC_INDEX,b.AP_QUARTER_INDEX,b.MG_INDEX]:
		expected[index]=FileAccess.get_sha256(index)
	var entry: Dictionary=b.call("_entry",id)
	if not entry.is_empty():expected[entry.manifest_path]=entry.manifest_sha256
	var extra: Dictionary={}
	var missing: Dictionary={}
	var different: Dictionary={}
	for p: String in actual:
		if not expected.has(p):extra[p]=actual[p]
		elif actual[p]!=expected[p]:different[p]={"expected":expected[p],"actual":actual[p]}
	for p: String in expected:
		if not actual.has(p):missing[p]=expected[p]
	var admitted: Dictionary=b.call("describe",id,actual)
	var report: Dictionary={"scope":"ONE_MARKET_ACTUAL_C_TO_B_READONLY_NO_TRAVEL","save_suspended":suspended,"real_save_contents_accessed":false,"scene_path":path,"manifest_valid":not config.is_empty(),"entry":entry,"actual_count":actual.size(),"expected_count":expected.size(),"extra":extra,"missing":missing,"different":different,"actual_sources":actual,"expected_sources":expected,"admitted":not admitted.is_empty()}
	var output: String=HOME+"actual/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(output)
	var file:=FileAccess.open(output+"/market_source_diagnostic.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t")+"\n")
	file.close()
	print("MARKET_SOURCE_DIAGNOSTIC ",output," actual=",actual.size()," expected=",expected.size()," extra=",extra.size()," missing=",missing.size()," different=",different.size()," admitted=",not admitted.is_empty())
	quit(0)
