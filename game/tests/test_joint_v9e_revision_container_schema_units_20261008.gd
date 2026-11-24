extends SceneTree
## Actual frozen revision-container reader regression only. No whole image/RF
## reconstruction, Field, capture, publisher, approvals or player-slot writes.
const PROBE_PATH: String="res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
const SOURCE: String="res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST: String="res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const REPORT: String="res://art/maps/world_map_v15_complete_v9c/whole_actual_capture.json"
const REGIONAL: String="res://build/world_map_v15_coherent_whole_v9c_regional/v9d_broad_soft/1791137714_2690526/result.json"
const C_KEY: String="v9c_revision_evidence"
const E_KEY: String="v9e_revision_evidence"
const PINS: Dictionary={
	PROBE_PATH:"9c698776f3e1f1d6208db8504acd44b8efb1b95a61b58f332f2e9d5c0a7efc55",
	"res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd":"946fcc3f9ba9d1d46b067672bd8bd560e12bc651a96b7096d48d94a5f5f060a9",
	SOURCE:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
	MANIFEST:"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
	REPORT:"cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851",
	REGIONAL:"fe50ec4312753bd62eee0e4c62a1944dfb29859e6f339e04282dc05864f960d0",
	"res://scripts/dev/world_map_v15_complete_v7_surface_proposal.gd":"0f469cd0bfac24195df18e9667873b926d6bee9875f1ca171ccbddeaff2dd7f8",
	"res://scripts/dev/world_map_v15_complete_v8_rich_surface_candidate.gd":"c76a0ae24aaacaa5cc9318d4efcaff44a7e8a0cee309d3b607e4532e20b7cb92",
	"res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v6.gd":"80302ec86f3fb60499602893b34c5fc321cd8877dbc27d1000bb9fb39766427e"
}
class AuditSink extends RefCounted:
	var rejected: Array[String]=[]
	func _check(ok: bool,label: String) -> bool:
		if not ok: rejected.append(label)
		return ok

var checks: int=0
var failures: int=0
var predicate_checks: int=0
var records: Array[Dictionary]=[]
var subject: RefCounted
var sink: AuditSink=AuditSink.new()
var controls: Dictionary={}
var source: Dictionary={}
var manifest: Dictionary={}
var report: Dictionary={}
var regional: Dictionary={}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks+=1
	records.append({"ok":ok,"label":label})
	if not ok:
		failures+=1
		push_error("[ACTUAL REVISION CONTAINER UNIT] "+label)

func _read(path: String) -> Dictionary:
	var decoder: JSON=JSON.new()
	if decoder.parse(FileAccess.get_file_as_string(path))!=OK or not decoder.data is Dictionary: return {}
	return decoder.data

func _file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false}
	var file: FileAccess=FileAccess.open(path,FileAccess.READ)
	if file==null: return {"exists":true,"readable":false}
	var size: int=file.get_length()
	file.close()
	return {"exists":true,"readable":true,"bytes":size,"sha256":FileAccess.get_sha256(path).to_lower(),"mtime":FileAccess.get_modified_time(path)}

func _snapshot(paths: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths: result[path]=_file(path)
	return result

func _players() -> Dictionary:
	var result: Dictionary={}
	for slot in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String="user://save_%d.json%s" % [slot,suffix]
			result[ProjectSettings.globalize_path(path)]=_file(path)
	return result

func _begin_predicate() -> void:
	subject.set("checks",0)
	subject.set("failures",0)
	sink.rejected.clear()

func _end_predicate(label: String,want: bool,result: bool) -> void:
	var actual_checks: int=int(subject.get("checks"))
	var actual_failures: int=int(subject.get("failures"))
	predicate_checks+=actual_checks
	_check(actual_checks>0 and result==want and ((actual_failures==0 and sink.rejected.is_empty()) if want else (actual_failures>0 and not sink.rejected.is_empty())),label)
	records.append({"predicate":label,"expected_accept":want,"actual_accept":result,"actual_checks":actual_checks,"actual_failures":actual_failures,"rejections":sink.rejected.duplicate()})

func _full(label: String,want: bool,s: Dictionary,m: Dictionary,r: Dictionary) -> void:
	_begin_predicate()
	var result: bool=subject.call("_full_E_revision_records",s,m,r,controls)==true
	_end_predicate(label,want,result)

func _own(label: String,want: bool,container: Dictionary,inherited: Variant,is_regional: bool=false) -> void:
	_begin_predicate()
	var result: bool=subject.call("_v9e_revision_records",container,controls,is_regional,inherited)==true
	_end_predicate(label,want,result)

func _revision_changed(container: Dictionary,key: String,value: Variant) -> Dictionary:
	var changed: Dictionary=container.duplicate(false)
	changed[E_KEY]=container[E_KEY].duplicate(true)
	changed[E_KEY][key]=value
	return changed

func _run() -> void:
	var self_path: String=get_script().resource_path
	var self_sha: String=FileAccess.get_sha256(self_path).to_lower()
	var save: Node=root.get_node_or_null("SaveManager")
	_check(save!=null and current_scene==null,"normal autoloads, no Field/main scene")
	if save==null: quit(1); return
	var slot_before: Variant=save.get("active_slot")
	var players_before: Dictionary=_players()
	var paths: Dictionary=PINS.duplicate(true)
	paths[self_path]=self_sha
	var initial: Dictionary=_snapshot(paths)
	for path: String in paths:
		_check(initial[path].get("readable")==true and initial[path].get("sha256")==paths[path],"literal current input SHA "+path)
	if failures!=0: quit(1); return
	var loaded: Script=load(PROBE_PATH) as Script
	_check(loaded!=null and loaded.can_instantiate(),"actual current reader loads and can instantiate")
	if loaded==null or not loaded.can_instantiate(): quit(1); return
	subject=loaded.new() as RefCounted
	subject.set("phase",sink)
	source=_read(SOURCE)
	manifest=_read(MANIFEST)
	report=_read(REPORT)
	regional=_read(REGIONAL)
	_check(source.get(C_KEY) is Dictionary and report.get(C_KEY) is Dictionary and regional.get(C_KEY) is Dictionary and not manifest.has(C_KEY),"actual C writer source/report/regional own C; manifest actual absence")
	_check(source.get(E_KEY) is Dictionary and manifest.get(E_KEY) is Dictionary and report.get(E_KEY) is Dictionary and regional.get(E_KEY) is Dictionary,"actual E writer all four actual revision containers")
	_check(manifest.get("asset_sha256") is Dictionary and source.get(C_KEY) is Dictionary,"actual catalog and inherited input roles typed")
	if failures!=0: quit(1); return
	var catalog: Dictionary=manifest.asset_sha256.duplicate(true)
	var constants: Dictionary=loaded.get_script_constant_map()
	var execution: Dictionary=constants["V9E_EXECUTION_PINS"].duplicate(true)
	for path: String in execution:
		_check(catalog.get(path)==execution[path],"literal eight execution pins also bound by actual catalog "+path)
		paths[path]=execution[path]
	# Actual revision predicates decode only these original registered PBR
	# inputs. Protect every consumed registration/JPEG, not all FULL images.
	for asset: Dictionary in constants["V9C_PBR_SOURCES"]:
		var registration_path: String=asset.directory+"SOURCE.json"
		_check(catalog.get(registration_path) is String,"actual catalog registration "+registration_path)
		paths[registration_path]=catalog.get(registration_path,"")
		for channel: String in ["diff","nor_gl","arm"]:
			var path: String=asset.directory+asset.id+"_"+channel+"_2k.jpg"
			_check(catalog.get(path) is String,"actual catalog channel "+path)
			paths[path]=catalog.get(path,"")
	var before: Dictionary=_snapshot(paths)
	for path: String in paths:
		_check(before[path].get("readable")==true and before[path].get("sha256")==paths[path],"all actual consumed inputs before SHA "+path)
	if failures!=0: quit(1); return
	subject.set("catalog",catalog)
	subject.call("configure_derived_inputs",source[C_KEY].derived_geometry_inputs,execution)
	_begin_predicate()
	controls=subject.call("_actual_shader_controls")
	_end_predicate("independent pinned original shader literals and exact E deltas",true,controls.size()==2)
	if failures!=0: quit(1); return
	_full("actual source/manifest/whole FULL revision consumer, no fabricated manifest C",true,source,manifest,report)
	_own("actual regional own C with exact regional roles/five E creations",true,regional,regional[C_KEY],true)
	for wrong: Variant in [null,{},[],"stale C",17]:
		_own("source explicitly supplied inherited wrong type/content rejected "+str(typeof(wrong)),false,source,wrong)
		var missing_or_wrong: Dictionary=source.duplicate(false)
		missing_or_wrong[C_KEY]=wrong
		_full("FULL own source C missing/wrong cannot borrow report C "+str(typeof(wrong)),false,missing_or_wrong,manifest,report)
	for fixture: Array in [[source,false],[report,false],[regional,true]]:
		var original: Dictionary=fixture[0]
		var is_regional: bool=fixture[1]
		var absent: Dictionary=original.duplicate(false)
		absent.erase(C_KEY)
		_own("only manifest may lack own C; actual container missing rejected regional="+str(is_regional),false,absent,original[C_KEY],is_regional)
		var substituted: Dictionary=original[C_KEY].duplicate(false)
		substituted["scope"]="WRONG_INHERITED_ORIGIN"
		_own("valid C execution/creation cannot substitute another container origin regional="+str(is_regional),false,original,substituted,is_regional)
		_own("actual other capture origin cannot substitute own C regional="+str(is_regional),false,original,source[C_KEY] if is_regional else regional[C_KEY],is_regional)
	for fake: Variant in [null,{},source[C_KEY]]:
		var fabricated: Dictionary=manifest.duplicate(false)
		fabricated[C_KEY]=fake
		_full("manifest inherited C must remain actually absent even for valid C "+str(typeof(fake)),false,source,fabricated,report)
	var mismatched_report: Dictionary=report.duplicate(false)
	mismatched_report[C_KEY]=report[C_KEY].duplicate(false)
	mismatched_report[C_KEY]["scope"]="WRONG_REPORT_ORIGIN"
	_full("actual FULL source/report complete inherited origin equality remains strict",false,source,manifest,mismatched_report)
	var wrong_manifest_path: Dictionary=manifest.duplicate(false)
	wrong_manifest_path["source_contract_path"]="res://data/maps/WRONG.json"
	_own("missing-own C exception is only actual source-bound manifest",false,wrong_manifest_path,report[C_KEY])
	var wrong_manifest_capture: Dictionary=manifest.duplicate(false)
	wrong_manifest_capture["whole_actual_capture"]={"path":REPORT,"sha256":"0".repeat(64)}
	_own("missing-own C manifest must retain actual current report SHA",false,wrong_manifest_capture,report[C_KEY])
	for wrong: Variant in [17,null,[],{}]:
		var wrong_source_type: Dictionary=manifest.duplicate(false)
		wrong_source_type["source_contract_path"]=wrong
		_own("manifest source path wrong type rejects without String coercion "+str(typeof(wrong)),false,wrong_source_type,report[C_KEY])
		var wrong_capture_type: Dictionary=manifest.duplicate(false)
		wrong_capture_type["whole_actual_capture"]=manifest.whole_actual_capture.duplicate(true)
		wrong_capture_type.whole_actual_capture.path=wrong
		_own("manifest report path wrong type rejects without String coercion "+str(typeof(wrong)),false,wrong_capture_type,report[C_KEY])
	_own("regional cannot borrow manifest-only missing-own C domain",false,manifest,report[C_KEY],true)
	for wrong: Variant in [null,{},[],"old E"]:
		var changed: Dictionary=source.duplicate(false)
		changed[E_KEY]=wrong
		_own("E revision missing/wrong container rejected "+str(typeof(wrong)),false,changed,source[C_KEY])
	var missing_e: Dictionary=source.duplicate(false)
	missing_e.erase(E_KEY)
	_own("E revision missing key rejected",false,missing_e,source[C_KEY])
	var changed_roles: Dictionary=source[E_KEY].actual_execution.duplicate(true)
	changed_roles.full.role="ACTUAL_REGIONAL_EXECUTOR"
	_own("E six roles cannot differ from own inherited actual execution",false,_revision_changed(source,"actual_execution",changed_roles),source[C_KEY])
	_own("E five creation record coverage cannot shrink",false,_revision_changed(source,"actual_material_creations",[]),source[C_KEY])
	_own("E five attached creation record coverage cannot shrink",false,_revision_changed(source,"actual_attached_material_creations",[]),source[C_KEY])
	var missing_manifest_e: Dictionary=manifest.duplicate(false)
	missing_manifest_e.erase(E_KEY)
	_full("actual FULL manifest E missing cannot borrow source/report E",false,source,missing_manifest_e,report)
	var distinct_manifest_e: Dictionary=_revision_changed(manifest,"unit_memory_only_extra_E_field",true)
	_own("manifest single-container revision remains valid with memory-only extra E field",true,distinct_manifest_e,report[C_KEY])
	_full("FULL three-container E equality independently rejects otherwise valid distinct manifest E",false,source,distinct_manifest_e,report)
	_check(sink.rejected.size()==1 and sink.rejected[0].contains("same actual current E source/manifest/report revision bytes"),"otherwise valid distinct manifest E rejected specifically by preserved three-container equality")
	var stale_e: Dictionary=_revision_changed(source,"material_revision_identity","V9D_ANCESTOR_NOT_E")
	_own("stale E identity rejected by actual unchanged material predicates",false,stale_e,source[C_KEY])
	var prior_execution: Dictionary=execution.duplicate(true)
	var first_path: String=String(execution.keys()[0])
	prior_execution[first_path]="0".repeat(64)
	subject.set("execution_inputs",prior_execution)
	_own("all eight execution pins remain strict",false,source,source[C_KEY])
	subject.set("execution_inputs",execution)
	_full("unchanged actual FULL positive retained after memory-only negatives",true,source,manifest,report)
	var geometry: RefCounted=subject.get("geometry") as RefCounted
	if geometry!=null: geometry.call("release")
	subject.set("geometry",null)
	subject.set("phase",null)
	subject=null
	loaded=null
	source.clear(); manifest.clear(); report.clear(); regional.clear(); controls.clear()
	var audio: Node=root.get_node_or_null("AudioManager")
	if audio!=null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame in 16: await process_frame
	_check(_snapshot(paths)==before,"every actual consumed frozen/source/unit input unchanged after predicates")
	_check(_players()==players_before and save.get("active_slot")==slot_before,"all15 protected player files and active slot unchanged without restore writes")
	var output: String="res://build/joint_world_luoyang_20261003_qa/revision_container_schema_units_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	var unique_output: bool=not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output)==OK
	_check(unique_output,"unique BUILD-only limited schema evidence")
	if not unique_output: quit(1); return
	var payload: String=JSON.stringify({"schema":1,"scope":"ACTUAL_FROZEN_E_C_REVISION_CONTAINER_PREDICATES_ONLY_NOT_FULL_FIELD_OR_RELEASE","checks":checks,"failures":failures,"predicate_checks":predicate_checks,"records":records,"pins":paths,"before":before,"source_path":self_path,"source_sha256":self_sha,"manifest_C_fabricated":false,"whole_image_or_RF_rebuilt":false,"Field_executed":false,"physics_executed":false,"capture_executed":false,"release_complete":false,"formal_cutover":false,"output":output},"\t",true)
	var file: FileAccess=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null:
		_check(false,"limited schema result open")
	else:
		file.store_string(payload); file.flush()
		var error: Error=file.get_error()
		file.close()
		_check(error==OK and FileAccess.get_file_as_string(output+"result.json")==payload,"limited schema result exact write/readback")
	print("ACTUAL_REVISION_CONTAINER_SCHEMA_UNITS: %d/%d predicate_checks=%d output=%s" % [checks,failures,predicate_checks,output])
	quit(0 if failures==0 else 1)
