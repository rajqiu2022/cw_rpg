extends SceneTree
## Root-only current failure capture; no Field, input, process or save APIs.
const FIXTURE := "res://build/luoyang_entry_20261031e_qa01/admission_PRE_inputs_READY.json"
const OUTPUT := "res://build/luoyang_entry_20261031e_qa01/admission_pre_actual/"
const AUTH := "res://scripts/city/luoyang_execution_authority_20261022ap.gd"
const CULTURE := "res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd"
const PRESENTATION := "res://build/luoyang_city_full_rollout_20261022ap_npc01/presentation_execution.gd"
const ROUTER := "res://scripts/autoload/scene_router.gd"
const HISTORICAL := "d25da6fe7f5dd4ec47a7d6821163acc8c51862c40207facd3e7fa6ebe2d586bc"
var errors: Array[String]=[]
var records: Array=[]
var suspended := false
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true);suspended=bool(node.call("is_checkpoint_saves_suspended"))
func _run() -> void:
	await process_frame
	var spec: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE)) as Dictionary
	for path: String in spec.pins:
		if FileAccess.get_sha256("res://"+path.trim_prefix("game/"))!=String(spec.pins[path]):errors.append("EXPLICIT_PRE_PIN:"+path)
	if not suspended:errors.append("CHECKPOINT_NOT_SUSPENDED")
	if not errors.is_empty():finish();return
	var authority: Script=load(AUTH) as Script;var culture: Script=load(CULTURE) as Script;var presentation: Script=load(PRESENTATION) as Script
	if authority==null or culture==null or presentation==null:errors.append("SOURCE_SCRIPT_PARSE");finish();return
	var header: Dictionary=authority.call("header")
	var bad_edges: Array=[];var edge_count := 0
	if not header.is_empty() and header.get("owned") is Dictionary:
		var row: Dictionary=header.owned.get(ROUTER,{})
		for edge: Dictionary in row.get("edges",[]):
			var good: bool=bool(authority.call("edge_valid",edge,ROUTER,String(edge.get("new_sha256","")),header.source_sha256))
			if not good:bad_edges.append({"index":edge_count,"old_sha":edge.get("old_sha256"),"new_sha":edge.get("new_sha256"),"old_snapshot":edge.get("old_snapshot"),"new_snapshot":edge.get("new_snapshot")})
			edge_count+=1
	var approved: bool=bool(authority.call("approved",ROUTER,HISTORICAL))
	var unknown: bool=bool(authority.call("approved",ROUTER,"0000000000000000000000000000000000000000000000000000000000000000"))
	var readiness: Dictionary=culture.call("readiness")
	var paths: Dictionary=presentation.call("source_paths")
	records.append({"actual_Authority_header_ready":not header.is_empty(),"actual_current_router_sha":FileAccess.get_sha256(ROUTER),"actual_dynamic_router_edges":edge_count,"invalid_edges":bad_edges,"historical_D25_router_approved":approved,"unknown_sha_approved":unknown,"actual_culture_readiness_ok":readiness.get("ok",false),"actual_culture_error":readiness.get("error",""),"actual_AP_source_path_count":paths.size(),"AP_has_Authority":paths.has(AUTH),"scene_instances":0,"input_events":0})
	if header.is_empty() or edge_count==0 or not bad_edges.is_empty() or not approved or unknown:errors.append("ACTUAL_AUTHORITY_ADMISSION_REFUSED")
	if readiness.get("ok")!=true:errors.append("ACTUAL_CULTURE_REFUSED:"+String(readiness.get("error","")))
	if paths.is_empty() or not paths.has(AUTH):errors.append("ACTUAL_AP_SOURCE_PATHS_REFUSED")
	finish()
func finish() -> void:
	var dir:=OUTPUT+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(dir)
	var file:=FileAccess.open(dir+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"errors":errors,"records":records,"scope":"current31e pre-candidate actual admission, old thirteen-edge count not assumed; failure retained not replaced by repaired run","engine_launched_by_QA_agent":false,"real_save_API_calls":0},"\t"));file.close()
	print("LUOYANG31E_ADMISSION ",dir+"/result.json"," errors=",errors.size())
	quit(0 if errors.is_empty() else 1)
