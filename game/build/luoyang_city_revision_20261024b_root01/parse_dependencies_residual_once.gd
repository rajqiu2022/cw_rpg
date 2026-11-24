extends SceneTree
## Candidate parsing only. No candidate method, Field instance or collector.
const PROOF="res://build/luoyang_city_space_20261024b_source01/runtime_dependencies_READY02/culture_temple_dependency_inverse_NOT_STAGE.json"
const PROOF_SHA="36a42c3dd6b2f6f2c207a55c244b901a38417ed5ac721d739f08633ebb7f815f"
const OUT="res://build/luoyang_city_revision_20261024b_root01/parse_dependencies_residual_actual.json"
var checks: int=0
var failures: Array[String]=[]
var before: Dictionary={}
var rows: Array=[]
var completed: bool=false
func _initialize() -> void:
	call_deferred("run")
func need(value: bool,label: String) -> bool:
	checks+=1
	if not value: failures.append(label);printerr("READY02_PARSE_FAIL ",label)
	return value
func save_facts() -> Dictionary:
	var result: Dictionary={}
	for slot: int in 5:
		for suffix: String in [".json",".json.bak",".json.tmp"]:
			var path: String="user://save_"+str(slot)+suffix
			result[path]={"exists":FileAccess.file_exists(path),"sha256":FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "ABSENT","mtime":FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else 0}
	return result
func watchdog() -> void:
	await create_timer(25.0).timeout
	if not completed:
		printerr("READY02_PARSE_WATCHDOG_25S_NO_EXTENSION")
		quit(2)
func run() -> void:
	var began: int=Time.get_ticks_msec()
	watchdog()
	await process_frame
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if not need(bridge!=null and not FileAccess.file_exists(OUT),"Autoload ready and NEW output"): quit(2);return
	bridge.call("set_checkpoint_saves_suspended",true)
	before=save_facts()
	if not need(FileAccess.get_sha256(PROOF)==PROOF_SHA,"Frozen reviewed mechanical code proof"): quit(2);return
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(PROOF))
	var sources: Array=[proof.coordinator.candidate,proof.temple.candidate,{"path":"res://build/luoyang_city_space_20261024b_source01/runtime_READY02/G_scope_dialog_sources_READY.gd","sha256":"66e81fe56206f5b52400a5e41f8c3114bbc10f01fb9d5758cc07dc6fe58b6905"}]
	var initial: Dictionary={}
	for row: Dictionary in sources:
		var path: String=row.path
		if not need(FileAccess.get_sha256(path)==row.sha256,"Fixed candidate source "+path): break
		initial[path]=row.sha256
		var script: GDScript=load(path) as GDScript
		var okay: bool=script!=null and script.resource_path==path and script.can_instantiate()
		rows.append({"path":path,"parsed_can_instantiate":okay,"candidate_methods_called":0})
		if not need(okay,"Actual candidate parsed without instantiation "+path): break
	var after: Dictionary={}
	for path: String in initial: after[path]=FileAccess.get_sha256(path)
	need(initial==after and FileAccess.get_sha256(PROOF)==PROOF_SHA,"Candidate/proof first-final unchanged")
	var save_after:=save_facts()
	need(save_after==before,"All fifteen current saves unchanged")
	need(Time.get_ticks_msec()-began<25000,"Actual whole parse scope below original25s")
	var file:=FileAccess.open(OUT,FileAccess.WRITE)
	if file==null: quit(2);return
	file.store_string(JSON.stringify({"complete":failures.is_empty() and rows.size()==3,"checks":checks,"failures":failures,"rows":rows,"sources_first":initial,"sources_final":after,"save_first":before,"save_final":save_after,"Field_instances":0,"candidate_method_calls":0,"collector_calls":0,"formal_writes":0,"no_runtime_ART_or_loading_credit":true,"previous_12_not_replayed":true},"\t",true,true));file.close()
	completed=true
	print("READY02_PARSE_RESULT ",OUT)
	quit(0 if failures.is_empty() and rows.size()==3 else 1)
