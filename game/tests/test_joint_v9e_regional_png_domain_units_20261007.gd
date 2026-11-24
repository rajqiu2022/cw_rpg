extends SceneTree
## Independent QA domain negatives plus the ACTUAL six-regional decoder.
## No capture/Field/approval/publication or production/save writes.
const ARTIFACT := preload("res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd")
const ARTIFACT_PATH := "res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
const ARTIFACT_SHA := "ad884308d3dc3b538ec04ee7cd3fb25f181807f88760d09f3d53bb191784ebdd"
const SOURCE_SHA := "85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f"
const MANIFEST_SHA := "1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a"
var checks: int=0
var errors: Array[String]=[]

class CheckSink extends RefCounted:
	var checks: int=0
	var errors: Array[String]=[]
	func _check(ok: bool,label: String) -> void:
		checks+=1
		if not ok: errors.append(label)

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: errors.append(label)

func _window_changed(data: Dictionary,key: String,value: Variant) -> Dictionary:
	# Copy only the branch under test; retain immutable actual records elsewhere.
	var changed: Dictionary=data.duplicate()
	changed.worlds=data.worlds.duplicate()
	changed.worlds.primary=data.worlds.primary.duplicate()
	changed.worlds.primary.roles=data.worlds.primary.roles.duplicate()
	changed.worlds.primary.roles.visual=data.worlds.primary.roles.visual.duplicate()
	changed.worlds.primary.roles.visual.windows=data.worlds.primary.roles.visual.windows.duplicate()
	changed.worlds.primary.roles.visual.windows.farmland=data.worlds.primary.roles.visual.windows.farmland.duplicate(true)
	changed.worlds.primary.roles.visual.windows.farmland[key]=value
	return changed

func _run() -> void:
	_check(FileAccess.get_sha256(ARTIFACT_PATH).to_lower()==ARTIFACT_SHA,"literal NEW E independent helper revision")
	_check(FileAccess.get_sha256(ARTIFACT.V9C_SOURCE).to_lower()==SOURCE_SHA,"actual frozen final Source")
	_check(FileAccess.get_sha256(ARTIFACT.V9C_MANIFEST).to_lower()==MANIFEST_SHA,"actual frozen final FULL manifest")
	_check(FileAccess.get_sha256(ARTIFACT.REGIONAL_RESULT_PATH).to_lower()==ARTIFACT.REGIONAL_RESULT_SHA,"actual frozen FE50 regional result")
	if not errors.is_empty(): _finish({}); return
	var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ARTIFACT.V9C_SOURCE))
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ARTIFACT.V9C_MANIFEST))
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ARTIFACT.REGIONAL_RESULT_PATH))
	var helper: RefCounted=ARTIFACT.new()
	var sink: RefCounted=CheckSink.new()
	helper.set("phase",sink)
	helper.set("catalog",manifest.asset_sha256.duplicate(true))
	var catalog_before: PackedByteArray=var_to_bytes(helper.get("catalog"))
	var final_pins: Dictionary={}
	for path: String in helper.call("_v9c_required_paths"): final_pins[path]=FileAccess.get_sha256(path).to_lower()
	helper.call("configure_final_pins",final_pins)
	helper.call("configure_derived_inputs",source.v9c_revision_evidence.derived_geometry_inputs,ARTIFACT.V9E_EXECUTION_PINS)
	var origin: String=ARTIFACT.REGIONAL_RESULT_PATH.get_base_dir()+"/"
	var sample: Dictionary=data.worlds.primary.roles.visual.windows.farmland
	_check(not helper.call("_bound",sample.path,sample.sha256),"legacy FULL-only binding demonstrably refuses actual regional PNG")
	var view: Dictionary=helper.call("_regional_png_view",data,ARTIFACT.REGIONAL_RESULT_PATH)
	_check(view.size()==240,"exact actual 240-PNG local view")
	_check(helper.call("_roi_file_bound",sample.path,sample.sha256,origin,view),"current actual regional PNG bound within private view")
	_check(not helper.call("_roi_file_bound",sample.path,sample.sha256,ARTIFACT.V9C_ROOT,view),"regional view cannot extend or contaminate FULL branch")
	_check(not helper.call("_roi_file_bound",sample.path,sample.sha256,origin,{}),"regional binding requires complete explicit view")
	_check(not helper.call("_roi_file_bound",sample.path,"0".repeat(64),origin,view),"regional record SHA mismatch refused")
	_check(not helper.call("_roi_file_bound",sample.path,sample.sha256,origin+"alternate/",view),"alternate regional prefix refused")
	_check(helper.call("_regional_png_records",data,origin+"alternate/result.json").is_empty(),"alternate result identity refused")
	for pair: Array in [["path",origin+"primary/visual_farmland_pass1.png"],["path",sample.path.replace("primary/","primary/../primary/")],["raw_path",sample.path],["sha256","0".repeat(64)],["raw_sha256",12],["repeat_transfer_evidence",{}]]:
		_check(helper.call("_regional_png_records",_window_changed(data,pair[0],pair[1]),ARTIFACT.REGIONAL_RESULT_PATH).is_empty(),"malformed canonical pass/path/SHA/repeat rejected: "+pair[0]+"/"+str(pair[1]))
	var fewer: Dictionary=data.duplicate()
	fewer.worlds=data.worlds.duplicate()
	fewer.worlds.erase("reference")
	_check(helper.call("_regional_png_records",fewer,ARTIFACT.REGIONAL_RESULT_PATH).is_empty(),"one-world subset refused")
	var live_catalog: Dictionary=helper.get("catalog")
	live_catalog[sample.path]=sample.sha256
	_check(helper.call("_regional_png_records",data,ARTIFACT.REGIONAL_RESULT_PATH).is_empty(),"FULL key override refused even with identical digest")
	live_catalog.erase(sample.path)
	var bad_pins: Dictionary=final_pins.duplicate()
	bad_pins[ARTIFACT.V9C_SOURCE]="0".repeat(64)
	helper.call("configure_final_pins",bad_pins)
	_check(helper.call("_regional_png_view",data,ARTIFACT.REGIONAL_RESULT_PATH).is_empty(),"different final Source snapshot refused")
	helper.call("configure_final_pins",final_pins)
	var forged: Dictionary=data.duplicate()
	forged["unit_decoy"]=true
	_check(helper.call("_regional_png_view",forged,ARTIFACT.REGIONAL_RESULT_PATH).is_empty(),"fabricated dictionary is not actual SHA-bound result")
	_check(var_to_bytes(helper.get("catalog"))==catalog_before,"domain negatives leave actual FULL catalog unchanged")
	# Execute the actual production-facing independent QA branch, including all
	# 60 windows, both passes, exact opaque/RGBA/Lanczos/repeat/camera/ObjectIDs.
	var actual_ok: bool=helper.call("_six_regional_material_inputs",source)
	var actual_record: Dictionary=helper.get("records").get("six_regional_prerequisite",{})
	_check(actual_ok and helper.get("failures")==0 and sink.get("errors").is_empty(),"actual full six-regional method passes with no predicate waiver")
	_check(actual_record.get("complete")==true and actual_record.get("completed_windows")==60 and actual_record.get("FULL_credit")==false and actual_record.get("Field_credit")==false,"actual60 regional windows only, no FULL/Field promotion")
	_check(var_to_bytes(helper.get("catalog"))==catalog_before,"actual regional execution preserves FULL catalog exact native bytes")
	var detail: Dictionary={"actual_regional":actual_record,"artifact_checks":helper.get("checks"),"artifact_failures":helper.get("failures"),"artifact_errors":sink.get("errors")}
	helper.get("geometry").call("release")
	helper.set("geometry",null)
	helper.set("phase",null)
	helper=null
	sink=null
	_check(FileAccess.get_sha256(ARTIFACT.V9C_SOURCE).to_lower()==SOURCE_SHA and FileAccess.get_sha256(ARTIFACT.V9C_MANIFEST).to_lower()==MANIFEST_SHA and FileAccess.get_sha256(ARTIFACT.REGIONAL_RESULT_PATH).to_lower()==ARTIFACT.REGIONAL_RESULT_SHA,"Source/manifest/regional evidence unchanged after actual decoder")
	_finish(detail)

func _finish(detail: Dictionary) -> void:
	print("V9E_QA_REGIONAL_PNG_DOMAIN_UNITS ",JSON.stringify({"scope":"INDEPENDENT240_REGIONAL_DOMAIN_AND_ACTUAL60_DECODE_NOT_FULL_FIELD_RELEASE_APPROVAL","checks":checks,"failures":errors.size(),"errors":errors,"detail":detail,"Field_executed":false,"GPU_executed":false,"production_written":false}))
	quit(0 if errors.is_empty() else 1)
