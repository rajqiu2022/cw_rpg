extends "res://scripts/dev/build_world_map_v15_coherent_whole_v7_regional_proposal.gd"

## Bounded V8 preview ONLY. Reuses genuine fresh-world/repeat/native authority
## methods, never parent's FULL _run or any existing art/source output root.
const V8_ECOLOGY := preload("res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd")
const V8_SURFACE := preload("res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd")
const V8_ROOT := "res://build/world_map_v15_coherent_whole_v8_regional/"
const V8_SCOPE := "V8_BOUNDED_FRESH_REGIONAL_MATERIAL_AND_DRY_BANK_NOT_FULL_OR_FIELD"
const V8_PINS := {
	"res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd":"128e06197a8afb88dbc506f7b1c70c7ce515a805f0b9de5db0d31ee62681870f",
	"res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd":"f156c54905fdfa9d59c9d0fa8b2bf84473f5ab6a77c6f3c91dbe4dbc1f664c40",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v7_regional_proposal.gd":"fd6dc2a60fd4f0fd6f3e4803b96973d6827b9f781f48a82bed1176ed2fc3c9a8",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd":"74a7757a43c7ff4e339fa297bf29a0ec7860cf6a70f7508ebd80a418ce18e233",
 "res://scripts/dev/world_map_v15_complete_v8_rich_ecology_candidate.gd":"12eb2c4eb46ed1b20dcf072580075e60c0ddfe9ed6823301ef9f9578e4ae5b3d",
 "res://scripts/dev/world_map_v15_complete_v8_rich_surface_candidate.gd":"c76a0ae24aaacaa5cc9318d4efcaff44a7e8a0cee309d3b607e4532e20b7cb92",
 "res://scripts/dev/source_archives/world_v15_v8_before_rich_v2/world_map_v15_complete_v8_ecology_source_proposal.gd":"43da1cbe34362e32610a0c27070b514dc7f3f49853a7004ab61a59c7f6662bfa",
 "res://scripts/dev/source_archives/world_v15_v8_before_rich_v2/world_map_v15_complete_v8_surface_proposal.gd":"11bc6572071f58d8852ad3378091d4df30ea7c2e280f484a6f6dcf4d6c4d4f7f"
}
const V8_CASES := [
	{"id":"farmland","rect":Rect2i(3410,2700,1536,1024)},
	{"id":"marsh","rect":Rect2i(9870,5840,1536,1024)},
	{"id":"river","rect":Rect2i(6960,1820,1536,1024)},
	{"id":"snow","rect":Rect2i(3980,350,1536,1024)}]
var v8_installed := false

func _material_maps(rect: Rect2) -> Dictionary:
	# Parent load's actual material-map hook occurs after old-source prepare,
	# before terrain_material and before loading bodies. Install real objects,
	# NOT same-named const overrides which do not alter parent preloads.
	if not v8_installed:
		var actual:=V8_ECOLOGY.new()
		actual.heights=source.heights
		actual.prepare()
		if not actual.v7_proposal_error.is_empty():
			error=actual.v7_proposal_error
			return {}
		source=actual
		if not _v7_replace_bianzhou_approach(): return {}
		if surface!=null: surface.release()
		surface=V8_SURFACE.new()
		if not surface.load_sources():
			error=surface.error
			return {}
		for record: Dictionary in surface.evidence:
			for key: String in ["path","source_path"]:
				var path: String=record[key]
				if not pilot_inputs.has(path) or FileAccess.get_sha256(path).to_lower()!=String(pilot_inputs[path]).to_lower():
					error="Actual NEW V8 registered material input unpinned/changed: "+path
					return {}
		v8_installed=true
	return super._material_maps(rect)

func _load_pilot_inputs() -> bool:
	if not super._load_pilot_inputs(): return false
	if not source is V8_ECOLOGY or not surface is V8_SURFACE or source.get_script().resource_path!="res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd" or surface.get_script().resource_path!="res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd":
		error="Actual V8 source/surface objects not installed; no label-only revision."
		return false
	if not source.expanded_dry_marsh_candidate_enabled or not source.snow_rock_candidate_enabled or not surface.cultivation_candidate_enabled or not surface.water_candidate_enabled or not surface.dry_sediment_candidate_enabled or not surface.snow_rock_candidate_enabled:
		error="Final rich v2 facade switches differ; no partial/unlabelled revision."
		return false
	pilot_result["actual_v8_binding"]={"source_path":source.get_script().resource_path,"source_sha256":FileAccess.get_sha256(source.get_script().resource_path),"surface_path":surface.get_script().resource_path,"surface_sha256":FileAccess.get_sha256(surface.get_script().resource_path),"ecology":(source as V8_ECOLOGY).v8_proposal_contract(),"original_RF_sha256":FileAccess.get_sha256(CACHE_ROOT+"terrain_height.rf"),"original_mesh_sha256":FileAccess.get_sha256(CACHE_ROOT+"terrain_mesh.res"),"original_selector_sha256":FileAccess.get_sha256(CACHE_ROOT+"source_topology.png"),"navigation_geometry_change":false}
	return true

func _write_json(path: String,data: Dictionary) -> bool:
	var honest: Dictionary=data.duplicate(true)
	if path==pilot_output+"result.json":
		honest["scope"]=V8_SCOPE if "--coherent-whole-v8-source-plan" not in OS.get_cmdline_user_args() else "V8_SOURCE_FORECAST_NOT_NAV_FIELD_OR_GPU"
		honest["executed_builder"]={"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)}
		honest["production_approved"]=false
		honest["visual_approved"]=false
		if surface is V8_SURFACE: honest["v8_actual_materials"]=(surface as V8_SURFACE).v8_material_records.duplicate(true)
		if source is V8_ECOLOGY and surface is V8_SURFACE:
			honest["actual_rich_ecology_contract"]=source.rich_candidate_contract()
			honest["actual_rich_material_records"]=surface.rich_material_records.duplicate(true)
			honest["actual_rich_execution"]={"ecology":source.rich_execution_contract(),"surface":surface.rich_execution_contract()}
		if source is V8_ECOLOGY and surface is V8_SURFACE:
			honest["actual_v8_execution"]={"ecology":{"path":source.get_script().resource_path,"sha256":FileAccess.get_sha256(source.get_script().resource_path)},"surface":{"path":surface.get_script().resource_path,"sha256":FileAccess.get_sha256(surface.get_script().resource_path)},"inherited_regional":{"path":"res://scripts/dev/build_world_map_v15_coherent_whole_v7_regional_proposal.gd","sha256":FileAccess.get_sha256("res://scripts/dev/build_world_map_v15_coherent_whole_v7_regional_proposal.gd")},"inherited_full":{"path":"res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd","sha256":FileAccess.get_sha256("res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd")}}
	return super._write_json(path,honest)

func _pilot_authorized(path: String) -> bool:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary:
		error="Missing explicit NEW V8 root authorization."
		return false
	pilot_auth=value
	if pilot_auth.get("approved")!=true or pilot_auth.get("scope")!=V8_SCOPE or pilot_auth.get("builder_path")!=get_script().resource_path or String(pilot_auth.get("builder_sha256","")).to_lower()!=FileAccess.get_sha256(get_script().resource_path).to_lower() or pilot_auth.get("allow_full64")!=false or pilot_auth.get("memory_budget_approved")!=true:
		error="NEW V8 literal scope/builder/memory authorization mismatch."
		return false
	if not pilot_auth.get("input_sha256") is Dictionary: return false
	pilot_inputs=pilot_auth["input_sha256"]
	for path_key: String in V8_PINS:
		if not pilot_inputs.has(path_key) or String(pilot_inputs[path_key]).to_lower()!=String(V8_PINS[path_key]) or FileAccess.get_sha256(path_key).to_lower()!=String(V8_PINS[path_key]):
			error="NEW actual source/parent input pin mismatch: "+path_key
			return false
	for path_key: String in V7_SOURCE_PINS:
		if not pilot_inputs.has(path_key) or String(pilot_inputs[path_key]).to_lower()!=String(V7_SOURCE_PINS[path_key]):
			error="Original V7 source/caster/proof absent from actual input catalog: "+path_key
			return false
	for mandatory: String in [CACHE_ROOT+"terrain_height.rf",CACHE_ROOT+"terrain_mesh.res",CACHE_ROOT+"source_topology.png",CACHE_ROOT+"capture/terrain_shader.gdshader",CACHE_ROOT+"chunks/r0_c0_actual_deck_support_mesh.res",FULL_FOOTPRINTS,TRANSPORT_PATH,"res://scripts/dev/world_map_v15_complete_v5_source.gd","res://scripts/dev/world_map_v15_complete_v5_surface.gd","res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd","res://scripts/dev/build_world_map_v15_complete_v5_full_draft.gd"]:
		if not pilot_inputs.has(mandatory):
			error="Mandatory actual frozen input missing: "+mandatory
			return false
	for path_key: String in pilot_inputs:
		if FileAccess.get_sha256(path_key).to_lower()!=String(pilot_inputs[path_key]).to_lower():
			error="Changed actual input: "+path_key
			return false
	if not _v7_source_guard() or FileAccess.get_sha256(TRANSPORT_PATH).to_lower()!=TRANSPORT_SHA: return false
	var proof: Dictionary=pilot_auth.get("transport_proof",{})
	if proof.get("path","")=="" or FileAccess.get_sha256(proof["path"]).to_lower()!=String(proof.get("sha256","")).to_lower(): return false
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(proof["path"]))
	if not parsed is Dictionary or not bool(parsed.get("stage_A",{}).get("passed",false)) or not bool(parsed.get("stage_B",{}).get("passed",false)) or String(parsed.get("transfer_shader",{}).get("sha256","")).to_lower()!=TRANSPORT_SHA: return false
	pilot_proof_gpu_uuid=String(parsed.get("stage_B",{}).get("baseline",{}).get("gpu_uuid",""))
	if pilot_proof_gpu_uuid.is_empty() or pilot_proof_gpu_uuid!=String(parsed.get("whole_guard",{}).get("gpu_uuid","")): return false
	return true

func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	pilot_output=V8_ROOT+"%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	failure_output=pilot_output
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pilot_output))
	if "--coherent-whole-v8-source-plan" in args:
		await _regional_source_plan(args)
		return
	if "--coherent-whole-v8-regional" not in args or "--coherent-whole-v7-full" in args or DisplayServer.get_name()=="headless":
		error="NEW V8 bounded GPU opt-in only; default/headless/FULL refused."
		await _pilot_finish(false)
		return
	var auth_path := ""
	for argument: String in args:
		if argument.begins_with("--authorization="): auth_path=argument.trim_prefix("--authorization=")
	if not _pilot_authorized(auth_path):
		await _pilot_finish(false)
		return
	v7_regional=true
	v7_art_root=pilot_output+"evidence/"
	for folder: String in ["","entities/","prototypes/","capture/"]: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(v7_art_root+folder))
	pilot_result={"schema_version":1,"coordinate_version":15,"capture_protocol":"V8_BOUNDED_FRESH_REGIONAL_NATIVE_CAMERA_V1","scope":V8_SCOPE,"status":"BUILD_IN_PROGRESS","visual_approved":false,"production_approved":false,"whole_CPU_Image_allowed":false,"whole_GPU_allocation_requested":false,"cached_inputs_sha256":pilot_inputs,"executed_builder":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)},"authorization":{"path":auth_path,"sha256":FileAccess.get_sha256(auth_path)},"regions":[]}
	pilot_memory_history=_pilot_square_history()
	if not bool(pilot_memory_history.get("valid",false)) or not _load_pilot_inputs() or not _full_prepare_semantics() or not _full_export_compounds() or not _regional_materialize_native_instances() or not _v7_measure_coverage() or not await _full_export_structures():
		await _pilot_finish(false)
		return
	for spec: Dictionary in V8_CASES:
		v7_region_rect=spec["rect"]
		var record: Dictionary={"id":spec["id"],"logical_rect_px":_recti(v7_region_rect),"worlds":{},"comparisons":{}}
		for identity: String in ["primary","reference"]:
			var actual: Dictionary=await _pilot_capture_world(String(spec["id"])+"_"+identity)
			if actual.is_empty():
				pilot_result["failed_region"]=record
				await _pilot_finish(false)
				return
			record["worlds"][identity]=actual
		for role: String in ROLE_NAMES:
			var a: Dictionary=record["worlds"]["primary"]["roles"][role]["windows"]["region"]
			var b: Dictionary=record["worlds"]["reference"]["roles"][role]["windows"]["region"]
			var raw: Dictionary=_pilot_compare_pngs(a["raw_path"],b["raw_path"])
			var logical: Dictionary=_pilot_compare_pngs(a["path"],b["path"])
			record["comparisons"][role]={"raw":raw,"logical":logical}
			if not bool(raw["byte_exact"]) or not bool(logical["byte_exact"]):
				error="Actual independent V8 worlds differ; no tolerance/fallback."
				pilot_result["failed_region"]=record
				await _pilot_finish(false)
				return
		var primary: Dictionary=record["worlds"]["primary"]
		var on: Image=Image.load_from_file(primary["roles"]["visual"]["windows"]["region"]["path"])
		var off: Image=Image.load_from_file(primary["roles"]["shadow_off"]["windows"]["region"]["path"])
		var shadow: Dictionary=_full_ground_evidence(String(spec["id"]),Rect2(v7_region_rect),on,off,pilot_output)
		if shadow.is_empty():
			await _pilot_finish(false)
			return
		record["actual_shadow_evidence"]=shadow
		record["shadow_scope"]="Actual ON/OFF difference recorded, zero allowed for representative snow/farmland empty land; not positive caster proof. Original four-region alpha union remains required separately."
		record["independent_body_scene"]=_regional_composite(primary)
		if record["independent_body_scene"].is_empty():
			await _pilot_finish(false)
			return
		if spec["id"]=="river":
			record["actual_full17_approach"]=_regional_approach_audit(primary)
			if not bool(record["actual_full17_approach"]["passed"]):
				error="Original actual Bianzhou detour no longer safe."
				await _pilot_finish(false)
				return
		regional_regions.append(record)
	for path_key: String in pilot_inputs:
		if FileAccess.get_sha256(path_key).to_lower()!=String(pilot_inputs[path_key]).to_lower():
			error="Actual V8 input changed during capture."
			await _pilot_finish(false)
			return
	pilot_result["regions"]=regional_regions
	pilot_result["input_hashes_unchanged_after"]=true
	pilot_result["alpha_union"]=v7_alpha_union
	pilot_result["v8_actual_materials"]=(surface as V8_SURFACE).v8_material_records.duplicate(true)
	pilot_result["status"]="V8_REGIONAL_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_NOT_FULL_OR_FIELD"
	await _pilot_finish(true)
