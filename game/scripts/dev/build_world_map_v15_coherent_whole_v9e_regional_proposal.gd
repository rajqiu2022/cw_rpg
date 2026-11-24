extends "res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd"

## NEW V9E material execution sibling; unchanged technical regional protocol.
## Actual new surface is installed by the inherited V9E factory before draw.
## NEW bounded native authority pilot. Same whole fixed camera as FULL, two
## genuinely independent worlds, all five roles/two actual draws/six exact ROIs.
## No64chunk/112seam/Field/production credit and no automatic FULL execution.
## Geometry must already exist as ROOT-reviewed CPU derivation artifacts.
const V9E_REGIONAL_BUILDER_PATH := "res://scripts/dev/build_world_map_v15_coherent_whole_v9e_regional_proposal.gd"

func _run() -> void:
	v9c_regional_mode=true
	v9c_plan_only=false
	v7_regional=false
	var args: PackedStringArray=OS.get_cmdline_user_args()
	pilot_output=V9C_REGIONAL_ROOT+"%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	failure_output=pilot_output
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(pilot_output)) or DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pilot_output))!=OK:
		error="Unique NEW V9C regional output unavailable."
		await _pilot_finish(false)
		return
	if "--coherent-whole-v9c-regional" not in args or "--coherent-whole-v9c-full" in args or DisplayServer.get_name()=="headless":
		error="NEW regional native GPU opt-in required. Default/headless/FULL refused."
		await _pilot_finish(false)
		return
	var auth_path: String=""
	for argument: String in args:
		if argument.begins_with("--authorization="): auth_path=argument.trim_prefix("--authorization=")
	if not _pilot_authorized(auth_path):
		await _pilot_finish(false)
		return
	v7_art_root=pilot_output+"evidence/"
	for folder: String in ["","entities/","prototypes/","capture/"]:
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(v7_art_root+folder))!=OK:
			error="Cannot create NEW regional evidence directories."
			await _pilot_finish(false)
			return
	pilot_result={"schema_version":1,"coordinate_version":15,"capture_protocol":"V9C_DERIVED_RF_TWO_FRESH_WHOLE_FIXED_CAMERA_SIX_ROIS_V2","scope":V9C_REGIONAL_SCOPE,"status":"BUILD_IN_PROGRESS","engine_pid":OS.get_process_id(),"cached_inputs_sha256":pilot_inputs,"executed_builder":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)},"authorization":{"path":auth_path,"sha256":FileAccess.get_sha256(auth_path)},"whole_CPU_Image_allowed":false,"maximum_CPU_ROI_pixels":V7_MAX_CPU_ROI_PIXELS,"CPU_ROI_budget":V7_CPU_ROI_BUDGET,"FULL64_credit":false,"seam112_credit":false,"Field_credit":false,"production_approved":false,"visual_approved":false,"worlds":{},"comparisons":{},"regions":[]}
	pilot_memory_history=_pilot_square_history()
	pilot_result["actual_memory_history"]=pilot_memory_history
	if not bool(pilot_memory_history.get("valid",false)) or not _load_pilot_inputs() or not _full_prepare_semantics():
		if error.is_empty(): error="Actual NEW regional history/geometry/body/source failed before allocation."
		await _pilot_finish(false)
		return
	for path: String in pilot_inputs:
		full_catalog[path]=pilot_inputs[path]
		full_graph[path]=pilot_inputs[path]
	if not _full_register_literal_inputs(get_script().resource_path,{}) or not _v7_copy_geometry() or not _v7_copy_prototypes() or not _full_export_compounds() or not _full_export_native_instances() or not _v7_measure_coverage() or not await _full_export_structures():
		await _pilot_finish(false)
		return
	for identity: String in ["primary","reference"]:
		var measured: Dictionary=await _pilot_capture_world(identity)
		if measured.is_empty():
			await _pilot_finish(false)
			return
		pilot_result["worlds"][identity]=measured
	if not _pilot_compare():
		await _pilot_finish(false)
		return
	for spec: Dictionary in V9C_CASES:
		var id: String=spec["id"]
		var rect: Rect2i=spec["rect"]
		var first: Dictionary=pilot_result["worlds"]["primary"]
		var on: Image=Image.load_from_file(first["roles"]["visual"]["windows"][id]["path"])
		var off: Image=Image.load_from_file(first["roles"]["shadow_off"]["windows"][id]["path"])
		if on==null or off==null:
			error="Actual regional ON/OFF readback unavailable."
			await _pilot_finish(false)
			return
		var shadow: Dictionary=_full_ground_evidence(id,Rect2(rect),on,off,pilot_output)
		if shadow.is_empty():
			await _pilot_finish(false)
			return
		var evidence: Dictionary={"id":id,"logical_rect_px":_recti(rect),"actual_shadow_evidence":shadow,"world_window_id":id,"scope":"ACTUAL_TWO_FRESH_WHOLE_CAMERAS_FIVE_ROLE_TWO_DRAW_ROI_NOT_FULL64_OR_FIELD"}
		pilot_result["regions"].append(evidence)
	if not _v9c_composites(pilot_result["worlds"]["primary"]) or not _v9c_final_revision_evidence():
		await _pilot_finish(false)
		return
	for path: String in pilot_inputs:
		if FileAccess.get_sha256(path).to_lower()!=String(pilot_inputs[path]).to_lower():
			error="Immutable input changed during NEW regional."
			await _pilot_finish(false)
			return
	pilot_result["input_hashes_unchanged_after"]=true
	pilot_result["status"]=V9C_REGIONAL_STATUS
	await _pilot_finish(true)

func _pilot_windows() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for spec: Dictionary in V9C_CASES:
		result.append({"id":spec["id"],"rect":spec["rect"]})
	return result

func _pilot_finish(passed: bool) -> void:
	if not passed:
		pilot_result["status"]="V9C_REGIONAL_REFUSED_OR_TECHNICAL_FAIL"
		pilot_result["reason"]=error
	# Parent NEW cleanup leaves historical art/source/candidates untouched.
	await super._pilot_finish(passed)
