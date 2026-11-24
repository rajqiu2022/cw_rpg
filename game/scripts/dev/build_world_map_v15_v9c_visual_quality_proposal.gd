extends "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd"

## NEW bounded visual authoring executor, not a FULL/publisher/Field executor.
## One real WHOLE fixed-camera GPU world; only five ROI visual/shadow_off draws.
## Never requests a whole CPU Image, never exports binary/nav or 64/112 credit.
const V9C_SOURCE := preload("res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_ecology_source.gd")
const V9C_GEOMETRY := preload("res://scripts/dev/world_map_v15_v9c_derived_geometry_helper.gd")
const V9C_SURFACE := preload("res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_surface.gd")
const V9C_SCOPE := "V9C_VISUAL_QUALITY_PROPOSAL_FIVE_WHOLE_CAMERA_ROIS_NOT_FULL_NAV_FIELD"
const V9C_OUTPUT := "res://build/world_map_v15_v9c_visual_quality_proposal/"
const V9C_BASE_MANIFEST := "res://art/maps/world_map_v15_complete_v8/art_contract.json"
const V9C_BASE_MANIFEST_SHA := "cfb7656b2b50690ddb2e28cc91a0fcd23c734ba28cd21b171c67f2857561dd94"
const V9C_BASE_SOURCE := "res://data/maps/world_map_v15_complete_v8_source.json"
const V9C_BASE_SOURCE_SHA := "13f3d5a9940283a92971ea20eae0234301635812dd0975a4c119536fb026cff5"
const V9C_PARENT_PINS := {
	"res://scripts/dev/world_map_v15_v9b_visual_quality_proposal_ecology_source.gd":"f171fbb95eeba7baa7e06b9eadd50c2dfc71bb9d216eb2a6119c3bbeb5d046ed",
	"res://scripts/dev/world_map_v15_v9b_visual_quality_proposal_surface.gd":"49f02c1c5c837ea5e2fe83d27da8741d3648dfa95f476620852f00c7ba59b636",
	"res://scripts/dev/world_map_v15_v9_visual_quality_proposal_ecology_source.gd":"090a1f0c75b781c8760866a895cb8403e4b0655de2eb2e18054a49c7ef91ada7",
	"res://scripts/dev/world_map_v15_v9_visual_quality_proposal_surface.gd":"65402fecc8c787cb6adae956e3997eb6f354410e0b8c72795584f2fa7b97433e",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd":"74a7757a43c7ff4e339fa297bf29a0ec7860cf6a70f7508ebd80a418ce18e233",
	"res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd":"128e06197a8afb88dbc506f7b1c70c7ce515a805f0b9de5db0d31ee62681870f",
	"res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd":"f156c54905fdfa9d59c9d0fa8b2bf84473f5ab6a77c6f3c91dbe4dbc1f664c40"}
const V9C_CASES := [{"id":"farmland","rect":Rect2i(3460,2582,1280,1024)},
	{"id":"marsh","rect":Rect2i(10160,6576,1280,1024)},
	{"id":"snow","rect":Rect2i(4360,0,1280,1024)},
	{"id":"limestone","rect":Rect2i(560,1375,1280,1024)},
	{"id":"meadow_river","rect":Rect2i(5960,3288,1280,1024)}]
var v9c_plan_only: bool=false
var v9c_geometry_result: Dictionary={}
var v9c_installed := false
var v9c_body_inputs: Dictionary={}
var v9c_script_closure: Dictionary={}

static func authorization_template() -> Dictionary:
	# ROOT supplies literal real SHA values and signs a separate NEW file.
	# A template is NEVER interpreted as approval or fallback to an old auth.
	return {"approved":false,"scope":V9C_SCOPE,"builder_path":"res://scripts/dev/build_world_map_v15_v9c_visual_quality_proposal.gd",
		"builder_sha256":"PENDING_ROOT_CURRENT_SHA","allow_full64":false,"memory_budget_approved":false,
		"maximum_CPU_ROI_pixels":8404992,"CPU_ROI_budget":V7_CPU_ROI_BUDGET,
		"derived_geometry_inputs":{},"CPU_plan_mode":"--v9c-derived-source-plan generates NEW four artifacts; separate ROOT GPU auth must pin them before allocation",
		"input_sha256":{},"transport_proof":{"path":"res://build/world_map_v15_native_texel_transfer/1791066200_2454361/result.json",
		"sha256":"53896c2af42ce245cadee635c4b2eb7b1d2dbfbae54c6845259931fc1e668de8"},
		"scope_limit":"explicit CPU new-geometry plan OR one actual whole-camera world; tiny owner diagnostic then five visual/shadow_off ROIs; two true draws per role; no FULL/binary/Field approval"}

func _run() -> void:
	var args: PackedStringArray=OS.get_cmdline_user_args()
	v9c_plan_only="--v9c-derived-source-plan" in args
	pilot_output=V9C_OUTPUT+"%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	failure_output=pilot_output
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(pilot_output)) or DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pilot_output))!=OK:
		error="Cannot create unique NEW V9C evidence output."
		await _pilot_finish(false)
		return
	var gpu_requested: bool="--v9c-visual-quality-proposal" in args
	if v9c_plan_only==gpu_requested or "--full" in args or (not v9c_plan_only and DisplayServer.get_name()=="headless"):
		error="Choose explicit CPU derived-source-plan OR bounded GPU five-window V9C. Default/headless GPU/FULL refused."
		await _pilot_finish(false)
		return
	var auth_path: String=""
	for arg: String in args:
		if arg.begins_with("--authorization="): auth_path=arg.trim_prefix("--authorization=")
	if not _pilot_authorized(auth_path):
		await _pilot_finish(false)
		return
	pilot_result={"schema_version":1,"coordinate_version":15,"scope":V9C_SCOPE,"mode":"CPU_DERIVED_SOURCE_PLAN" if v9c_plan_only else "BOUNDED_GPU_FIVE_ROIS",
		"capture_protocol":"NEW_DERIVED_RF_SINGLE_WHOLE_FIXED_CAMERA_LITERAL_OWNER_AND_FIVE_VISUAL_ROIS_ON_OFF_REPEAT_PROPOSAL",
		"status":"BUILD_IN_PROGRESS","engine_pid":OS.get_process_id(),"executed_builder":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)},
		"authorization":{"path":auth_path,"sha256":FileAccess.get_sha256(auth_path)},"cached_inputs_sha256":pilot_inputs,
		"whole_CPU_Image_allowed":false,"maximum_CPU_ROI_pixels":V7_MAX_CPU_ROI_PIXELS,"CPU_ROI_budget":V7_CPU_ROI_BUDGET,
		"visual_approved":false,"production_approved":false,"FULL64_credit":false,"seam112_credit":false,"binary_navigation_capture_credit":false,"Field_credit":false,"worlds":{}}
	# Actual body metadata is needed by the CPU helper before terrain derivation.
	if not _v9c_load_bodies() or not _load_pilot_inputs():
		if error.is_empty(): error="Exact NEW derivation/source/material/body binding failed."
		await _pilot_finish(false)
		return
	if not v9c_plan_only:
		pilot_memory_history=_pilot_square_history()
		pilot_result["actual_memory_history"]=pilot_memory_history
		if not bool(pilot_memory_history.get("valid",false)):
			error="Exact square memory history failed before any whole-world allocation."
			await _pilot_finish(false)
			return
		v7_regional=false
		var measured: Dictionary=await _pilot_capture_world("showcase")
		if measured.is_empty():
			await _pilot_finish(false)
			return
		pilot_result["worlds"]["showcase"]=measured
		if not _v9c_composites(measured):
			await _pilot_finish(false)
			return
	for path: String in pilot_inputs:
		if FileAccess.get_sha256(path).to_lower()!=String(pilot_inputs[path]).to_lower():
			error="Frozen input changed during bounded V9C: "+path
			await _pilot_finish(false)
			return
	pilot_result["input_hashes_unchanged_after"]=true
	pilot_result["status"]="V9C_DERIVED_SOURCE_PLAN_PASS_NOT_GPU_NAV_FIELD" if v9c_plan_only else "V9C_FIVE_VISUAL_ROIS_REPEAT_TECHNICAL_PASS_PENDING_ROOT_VISUAL_NOT_FULL_NAV_FIELD"
	await _pilot_finish(true)

func _pilot_authorized(path: String) -> bool:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary:
		error="Missing independent ROOT V9C authorization."
		return false
	pilot_auth=value
	if pilot_auth.get("approved",false)!=true or pilot_auth.get("scope")!=V9C_SCOPE or pilot_auth.get("builder_path")!=get_script().resource_path or String(pilot_auth.get("builder_sha256","")).to_lower()!=FileAccess.get_sha256(get_script().resource_path).to_lower() or pilot_auth.get("allow_full64",true)!=false or (not v9c_plan_only and pilot_auth.get("memory_budget_approved",false)!=true):
		error="Exact V9C scope/builder/memory approval absent; no allocation."
		return false
	if not _v7_budget_exact(pilot_auth.get("CPU_ROI_budget")) or int(pilot_auth.get("maximum_CPU_ROI_pixels",0))!=V7_MAX_CPU_ROI_PIXELS or not pilot_auth.get("input_sha256") is Dictionary:
		error="Exact bounded ROI budget/input catalog absent."
		return false
	pilot_inputs=pilot_auth["input_sha256"]
	var required: Array=[CACHE_ROOT+"terrain_height.rf",CACHE_ROOT+"terrain_mesh.res",CACHE_ROOT+"source_topology.png",CACHE_ROOT+"chunks/r0_c0_actual_deck_support_mesh.res",TRANSPORT_PATH,SQUARE_RESULT,SQUARE_PNG,SQUARE_REPEAT,V9C_BASE_MANIFEST,V9C_BASE_SOURCE,get_script().resource_path]
	required.append("res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_ecology_source.gd")
	required.append("res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_surface.gd")
	required.append("res://scripts/dev/world_map_v15_v9c_derived_geometry_helper.gd")
	for p: String in V9C_PARENT_PINS: required.append(p)
	for p: String in V7_SOURCE_PINS: required.append(p)
	for p: String in required:
		if p.is_empty() or not pilot_inputs.has(p):
			error="Mandatory exact V9C input missing: "+p
			return false
	for p: String in pilot_inputs:
		if String(pilot_inputs[p]).length()!=64 or FileAccess.get_sha256(p).to_lower()!=String(pilot_inputs[p]).to_lower():
			error="Changed/unknown frozen input: "+p
			return false
	for p: String in V9C_PARENT_PINS:
		if FileAccess.get_sha256(p).to_lower()!=V9C_PARENT_PINS[p]:
			error="Frozen V9C parent bytes differ: "+p
			return false
	for p: String in V7_SOURCE_PINS:
		if FileAccess.get_sha256(p).to_lower()!=String(V7_SOURCE_PINS[p]).to_lower():
			error="Frozen inherited geometry/caster source bytes differ: "+p
			return false
	if not _v9c_bind_executed_script_closure(get_script().resource_path,{}): return false
	if FileAccess.get_sha256(V9C_BASE_MANIFEST).to_lower()!=V9C_BASE_MANIFEST_SHA or FileAccess.get_sha256(V9C_BASE_SOURCE).to_lower()!=V9C_BASE_SOURCE_SHA or FileAccess.get_sha256(TRANSPORT_PATH).to_lower()!=TRANSPORT_SHA:
		error="Immutable 179 body manifest or transport changed."
		return false
	var proof: Dictionary=pilot_auth.get("transport_proof",{})
	var proof_path: String=proof.get("path","")
	if proof_path.is_empty() or FileAccess.get_sha256(proof_path).to_lower()!=String(proof.get("sha256","")).to_lower():
		error="Real native transfer proof not pinned."
		return false
	var decoded: Variant=JSON.parse_string(FileAccess.get_file_as_string(proof_path))
	if not decoded is Dictionary or not bool(decoded.get("stage_A",{}).get("passed",false)) or not bool(decoded.get("stage_B",{}).get("passed",false)) or String(decoded.get("transfer_shader",{}).get("sha256","")).to_lower()!=TRANSPORT_SHA:
		error="Actual transfer StageA+B proof absent."
		return false
	pilot_proof_gpu_uuid=String(decoded.get("stage_B",{}).get("baseline",{}).get("gpu_uuid",""))
	if pilot_proof_gpu_uuid.is_empty() or pilot_proof_gpu_uuid!=String(decoded.get("whole_guard",{}).get("gpu_uuid","")):
		error="Actual proof GPU identity inconsistent."
		return false
	return true

func _v9c_bind_executed_script_closure(path: String,visited: Dictionary) -> bool:
	if visited.has(path): return true
	visited[path]=true
	if not pilot_inputs.has(path) or FileAccess.get_sha256(path).to_lower()!=String(pilot_inputs[path]).to_lower():
		error="Actual inherited/preloaded script not explicitly pinned: "+path
		return false
	v9c_script_closure[path]=pilot_inputs[path]
	var pattern:=RegEx.new()
	if pattern.compile("(?:extends\\s+|preload\\(\\s*)[\"'](res://[^\"']+\\.gd)[\"']")!=OK:
		error="Executed source closure matcher failed."
		return false
	for found in pattern.search_all(FileAccess.get_file_as_string(path)):
		if not _v9c_bind_executed_script_closure(found.get_string(1),visited): return false
	return true

func _material_maps(rect: Rect2) -> Dictionary:
	if not v9c_installed or source==null or not (source as V9C_SOURCE).v9c_derived_rf_installed:
		error="NEW RF must be explicitly installed before actual material ownership. No cached selector/height fallback."
		return {}
	return super._material_maps(rect)

func _load_pilot_inputs() -> bool:
	# Deliberately NOT super: its cache loader binds the old RF/mesh/selector.
	source=V9C_SOURCE.new()
	var original: PackedByteArray=FileAccess.get_file_as_bytes(CACHE_ROOT+"terrain_height.rf")
	if original.size()!=SOURCE.GRID_SIZE.x*SOURCE.GRID_SIZE.y*4:
		error="Frozen baseline RF shape differs."
		return false
	source.heights=original.to_float32_array()
	source.prepare()
	if not (source as V9C_SOURCE).v7_proposal_error.is_empty() or source.heights.to_byte_array()!=original or not _v7_replace_bianzhou_approach():
		if error.is_empty(): error="Prepared source/baseline RF/explicit Bianzhou approach failed."
		return false
	if v9c_plan_only:
		# The helper owns this absent child directory; never pre-create it.
		var helper := V9C_GEOMETRY.new()
		v9c_geometry_result=helper.derive(source,full_objects,pilot_output+"derived_geometry/")
		helper=null
		if not bool(v9c_geometry_result.get("passed",false)):
			error="NEW real geometry derivation refused: "+String(v9c_geometry_result.get("error","Missing helper result"))
			pilot_result["derivation_failure"]=v9c_geometry_result
			return false
	else:
		v9c_geometry_result=_v9c_read_derived_inputs()
		if v9c_geometry_result.is_empty(): return false
	if not (source as V9C_SOURCE).bind_derived_geometry(v9c_geometry_result):
		error=(source as V9C_SOURCE).v7_proposal_error
		return false
	v9c_installed=true
	pilot_result["actual_v9c_execution"]={"ecology":{"path":source.get_script().resource_path,"sha256":FileAccess.get_sha256(source.get_script().resource_path)},
		"geometry_helper":{"path":"res://scripts/dev/world_map_v15_v9c_derived_geometry_helper.gd","sha256":FileAccess.get_sha256("res://scripts/dev/world_map_v15_v9c_derived_geometry_helper.gd")},
		"ecology_contract":(source as V9C_SOURCE).v9_execution_contract()}
	pilot_result["actual_executed_script_closure_sha256"]=v9c_script_closure.duplicate(true)
	pilot_result["derived_geometry_inputs"]=v9c_geometry_result["artifacts"].duplicate(true)
	pilot_result["geometry_derivation_audit"]=v9c_geometry_result["audit"].duplicate(true)
	pilot_result["navigation_authority_unchanged"]=false
	pilot_result["geometry_scope"]="NEW RF/mesh/selector derived from old exact inputs. Protected source supports retain original Float32 nodes; unprotected mountain navigation may change. No fresh binary/FULL/Field credit."
	if v9c_plan_only: return true
	var heights: PackedFloat32Array=source.heights
	var topology: Image=v9c_geometry_result.get("selector")
	pilot_global_mesh=v9c_geometry_result.get("mesh")
	if topology==null or topology.get_size()!=SOURCE.SIZE/SOURCE.SELECTOR_STEP or pilot_global_mesh==null:
		error="Actual NEW native mesh/selector missing."
		return false
	full_rf=ImageTexture.create_from_image(Image.create_from_data(SOURCE.GRID_SIZE.x,SOURCE.GRID_SIZE.y,false,Image.FORMAT_RF,heights.to_byte_array()))
	full_topology=ImageTexture.create_from_image(topology)
	pilot_support_mesh=ResourceLoader.load(CACHE_ROOT+"chunks/r0_c0_actual_deck_support_mesh.res","",ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	pilot_transport=ResourceLoader.load(TRANSPORT_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as Shader
	if pilot_support_mesh==null or pilot_transport==null:
		error="Exact original deck support/native transport missing."
		return false
	surface=V9C_SURFACE.new()
	if not surface.load_sources():
		error=surface.error
		return false
	for entry: Dictionary in surface.evidence:
		for key: String in ["path","source_path"]:
			var p: String=entry[key]
			if not pilot_inputs.has(p) or FileAccess.get_sha256(p).to_lower()!=String(pilot_inputs[p]).to_lower():
				error="Actual NEW PBR dependency is unpinned: "+p
				return false
	full_map_textures=_material_maps(Rect2(Vector2.ZERO,Vector2(SOURCE.SIZE)))
	if full_map_textures.is_empty(): return false
	var weights: Dictionary={}
	for role: String in ["ecology","roads"]:
		var image: Image=full_map_textures[role].get_image()
		var p: String=pilot_output+role+"_reconstructed.png"
		if image.save_png(p)!=OK:
			error="NEW actual ownership save failed."
			return false
		weights[role]={"path":p,"sha256":FileAccess.get_sha256(p),"canvas":_v2i(image.get_size()),"recipe":"4px current ownership from installed NEW derived RF and explicit original Bianzhou detour"}
	var actual: ShaderMaterial=surface.terrain_material(full_map_textures["ecology"],full_map_textures["roads"],Rect2(Vector2.ZERO,Vector2(SOURCE.SIZE)))
	if actual==null or actual.shader==null:
		error="NEW actual terrain material absent."
		return false
	pilot_shader=actual.shader
	var shader_path: String=pilot_output+"v9c_actual_terrain_shader.gdshader"
	if ResourceSaver.save(pilot_shader,shader_path)!=OK:
		error="Actual V9C shader resource save failed."
		return false
	full_catalog[shader_path]=FileAccess.get_sha256(shader_path)
	full_graph[shader_path]=full_catalog[shader_path]
	pilot_result["actual_terrain_shader"]={"path":shader_path,"sha256":full_catalog[shader_path],"source_script":surface.get_script().resource_path,"source_script_sha256":FileAccess.get_sha256(surface.get_script().resource_path)}
	v7_material_records=(surface as V7_SURFACE).v7_material_records.duplicate(true)
	if not _v9c_load_original_prototypes(): return false
	pilot_result["actual_v9c_execution"]["surface"]={"path":surface.get_script().resource_path,"sha256":FileAccess.get_sha256(surface.get_script().resource_path)}
	pilot_result["actual_materials"]=surface.evidence.duplicate(true)
	pilot_result["cache_provenance"]={"baseline_RF_path":CACHE_ROOT+"terrain_height.rf","baseline_RF_sha256":pilot_inputs[CACHE_ROOT+"terrain_height.rf"],"height_grid_regenerated":true,"selector_regenerated":true,"actual_new_geometry":v9c_geometry_result["artifacts"],"original_deck_support_unchanged":true,"original_prototypes_reused_under_protected_supports":true,"not_old_nav_or_old_visual_approval":true,"weight_maps":weights}
	return true

func _v9c_read_derived_inputs() -> Dictionary:
	var entries: Variant=pilot_auth.get("derived_geometry_inputs")
	if not entries is Dictionary:
		error="GPU authorization must pin the four actual NEW CPU-derived artifacts before allocation."
		return {}
	for role: String in ["height_rf","terrain_mesh","source_topology","derivation_report"]:
		var e: Variant=entries.get(role)
		if not e is Dictionary:
			error="Missing derived artifact role: "+role
			return {}
		var p: String=e.get("path","")
		if not p.begins_with(V9C_OUTPUT) or ".." in p or String(e.get("sha256","")).length()!=64 or not pilot_inputs.has(p) or String(pilot_inputs[p]).to_lower()!=String(e["sha256"]).to_lower() or FileAccess.get_sha256(p).to_lower()!=String(e["sha256"]).to_lower():
			error="Changed/unbound derived artifact: "+role
			return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(entries["derivation_report"]["path"]))
	if not value is Dictionary or value.get("passed",false)!=true or value.get("status")!="DERIVED_GEOMETRY_SOURCE_CHECKS_PASS_REQUIRES_ACTUAL_CAPTURE" or not value.get("audit") is Dictionary or not value.get("artifacts") is Dictionary:
		error="Exact NEW source-only derivation report refused."
		return {}
	var audit: Dictionary=value["audit"]
	var helper_path: String="res://scripts/dev/world_map_v15_v9c_derived_geometry_helper.gd"
	if audit.get("executed_helper",{}).get("path")!=helper_path or String(audit.get("executed_helper",{}).get("sha256","")).to_lower()!=FileAccess.get_sha256(helper_path).to_lower() or audit.get("caller_source",{}).get("path")!=source.get_script().resource_path or String(audit.get("caller_source",{}).get("sha256","")).to_lower()!=FileAccess.get_sha256(source.get_script().resource_path).to_lower():
		error="Actual helper/source execution provenance differs from NEW frozen inputs."
		return {}
	for role: String in ["height_rf","terrain_mesh","source_topology"]:
		var row: Dictionary=value["artifacts"].get(role,{})
		if row.get("path")!=entries[role]["path"] or String(row.get("sha256","")).to_lower()!=String(entries[role]["sha256"]).to_lower():
			error="Auth/report artifact binding mismatch: "+role
			return {}
	for p: String in V9C_GEOMETRY.BASELINE_PINS:
		if String(audit.get("baseline_sha256",{}).get(p,"")).to_lower()!=String(V9C_GEOMETRY.BASELINE_PINS[p]).to_lower() or not pilot_inputs.has(p) or String(pilot_inputs[p]).to_lower()!=String(V9C_GEOMETRY.BASELINE_PINS[p]).to_lower():
			error="Exact geometry baseline provenance unbound: "+p
			return {}
	if int(audit.get("changed_nodes",0))<=0 or int(audit.get("water_land_vertex_changes",-1))!=0 or audit.get("object_support",{}).get("passed",false)!=true or int(audit.get("object_support",{}).get("objects",0))!=full_objects.size() or audit.get("old_NAV_unchanged_claim",true)!=false:
		error="Actual protected support/land/new-navigation derivation conditions missing."
		return {}
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(entries["height_rf"]["path"])
	var mesh: ArrayMesh=ResourceLoader.load(entries["terrain_mesh"]["path"],"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var selector: Image=Image.load_from_file(entries["source_topology"]["path"])
	if bytes.size()!=SOURCE.GRID_SIZE.x*SOURCE.GRID_SIZE.y*4 or mesh==null or selector==null or selector.get_size()!=SOURCE.SIZE/SOURCE.SELECTOR_STEP:
		error="Pinned NEW actual derived resources cannot be decoded."
		return {}
	return {"passed":true,"error":"","heights":bytes.to_float32_array(),"mesh":mesh,"selector":selector,"artifacts":entries.duplicate(true),"audit":audit}

func _v9c_load_original_prototypes() -> bool:
	for kind: String in ["boulder","tree","bamboo","herb"]:
		for pose in 3:
			var metadata_path: String=CACHE_ROOT+"prototypes/native_"+kind+str(pose)+".json"
			if not pilot_inputs.has(metadata_path):
				error="Unpinned original prototype metadata."
				return false
			var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
			if not parsed is Dictionary:
				error="Original native metadata parse failed."
				return false
			var record: Dictionary=parsed
			for key: String in ["actual_draw_mesh_path","texture","sourcebody_raw","sourcebody_repeat","draw_mesh_source"]:
				if not pilot_inputs.has(record[key]):
					error="Unpinned actual original prototype: "+String(record[key])
					return false
			if FileAccess.get_sha256(record["actual_draw_mesh_path"]).to_lower()!=String(record["actual_draw_mesh_sha256"]).to_lower() or record.get("kind")!=kind or int(record.get("pose",-1))!=pose:
				error="Original native source/pose mismatch."
				return false
			var mesh: ArrayMesh=ResourceLoader.load(record["actual_draw_mesh_path"],"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
			var body: Image=Image.load_from_file(record["texture"])
			if mesh==null or body==null or body.is_empty():
				error="Original caster mesh/sourcebody missing."
				return false
			var bounds: Dictionary=_pilot_native_bounds(mesh)
			if bounds.is_empty(): return false
			var b: Array=record["basis_columns"]
			var support: Vector3=_array3(record["support_m"])
			var uv: Array=record["foot_uv"]
			native_prototype_cache[kind+str(pose)]={"mesh":mesh,"basis":Basis(_array3(b[0]),_array3(b[1]),_array3(b[2])),"support":support,"image":body,"foot":Vector2(uv[0]*body.get_width(),uv[1]*body.get_height()),"record":record,"actual_native_bounds":bounds}
	return true

func _pilot_windows() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for row: Dictionary in V9C_CASES: result.append(row.duplicate(true))
	return result

func _pilot_capture_world(identity: String) -> Dictionary:
	var directory: String=pilot_output+identity+"/"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))!=OK or not _pilot_memory_guard(identity) or not _pilot_make_world(directory): return {}
	var effective: World3D=active_view.find_world_3d()
	if effective==null:
		error="Missing actual World3D."
		return {}
	var measured: Dictionary={"world_node_instance_id":pilot_world.get_instance_id(),"viewport_instance_id":active_view.get_instance_id(),"world3d_instance_id":effective.get_instance_id(),"camera":_pilot_camera_record(),"coverage":_pilot_coverage(),"roles":{},"casters":pilot_caster_records.duplicate(true),"scope":V9C_SCOPE}
	if not bool(measured["coverage"].get("passed",false)):
		error="Actual whole receiver/caster coverage failed."
		return {}
	var diagnostic: Dictionary=await _v9c_owner_debug(directory)
	if diagnostic.is_empty(): return {}
	measured["finite_owner_diagnostic"]=diagnostic
	for role: String in ["visual","shadow_off"]:
		if not _pilot_set_role(role): return {}
		var row: Dictionary={"actual_native_canvas":_v2i(active_view.size),"camera":_pilot_camera_record(),"windows":{},"passes":[],"caster_visible":role=="visual","actual_caster_shadow_mode":GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,"terrain_self_shadow_retained":pilot_receivers[0].cast_shadow,"actual_msaa":active_view.msaa_3d}
		for pass_index in 2:
			var draw: Dictionary=await _pilot_draw(identity+"_"+role+str(pass_index))
			if not bool(draw.get("fresh_actual_post_draw_observed",false)) or not _shader_gate(pilot_receivers[0].material_override,["biome_weights","road_weights","v9c_material_identity","grass_ground_diff","rock_01_arm"]) or not _shader_gate(pilot_water.material_override,["actual_height_rf","grid_origin","grid_shape"]):
				error="Actual material/draw fence failed."
				return {}
			row["passes"].append(draw)
			for item: Dictionary in _pilot_windows():
				var captured: Dictionary=await _pilot_read_roi(item,role,directory,pass_index,draw)
				if captured.is_empty(): return {}
				var id: String=item["id"]
				if pass_index==0: row["windows"][id]=captured
				else:
					var first: Dictionary=row["windows"][id]
					first["repeat_transfer_evidence"]=captured
					first["raw_repeat_path"]=captured["raw_path"]
					first["repeat_path"]=captured["path"]
					first["actual_raw_repeat"]=_pilot_compare_pngs(first["raw_path"],captured["raw_path"])
					first["actual_logical_repeat"]=_pilot_compare_pngs(first["path"],captured["path"])
					if not bool(first["actual_raw_repeat"]["byte_exact"]) or not bool(first["actual_logical_repeat"]["byte_exact"]):
						error="Actual zero-tolerance V9C repeated draw failed: "+role+"/"+id
						pilot_result["failed_role"]=row
						return {}
		measured["roles"][role]=row
	measured["actual_materials"]=(surface as V9C_SURFACE).v9_material_records.duplicate(true)
	var reference: WeakRef=weakref(active_view)
	await _pilot_release_world()
	measured["actual_world_released"]=reference.get_ref()==null
	if not bool(measured["actual_world_released"]):
		error="Whole viewport did not release."
		return {}
	return measured

func _v9c_owner_debug(directory: String) -> Dictionary:
	# Same actual whole viewport/camera/RF/mesh. Only unshaded diagnostic colour
	# changes; no binary/navigation credit or fabricated material-map readback.
	var saved: Array[Material]=[]
	for receiver: MeshInstance3D in pilot_receivers: saved.append(receiver.material_override)
	var material: ShaderMaterial=(surface as V9C_SURFACE).parcel_diagnostic_material()
	if material==null:
		error="Independent finite-owner diagnostic material missing."
		return {}
	var diagnostic_shader_path: String=directory+"finite_owner_diagnostic.gdshader"
	if ResourceSaver.save(material.shader,diagnostic_shader_path)!=OK:
		error="Actual diagnostic shader resource save failed."
		return {}
	var diagnostic_binding: Dictionary={"actual_shader_path":diagnostic_shader_path,
		"actual_shader_sha256":FileAccess.get_sha256(diagnostic_shader_path),
		"actual_shader_code_sha256":(surface as V9C_SURFACE)._v7_code_sha(material.shader.code),
		"actual_uploaded_uniform":material.get_shader_parameter("debug_uniform_parcels"),
		"actual_uploaded_uniform_variant_sha256":(surface as V9C_SURFACE)._v9_variant_sha(material.get_shader_parameter("debug_uniform_parcels"))}
	for receiver: MeshInstance3D in pilot_receivers: receiver.material_override=material
	pilot_water.visible=false
	pilot_support.visible=false
	for caster: MeshInstance3D in pilot_casters: caster.visible=false
	var rows: Array[Dictionary]=[]
	var witnesses: Array[Dictionary]=[
		{"id":"parcel_inside","source_px":Vector2(3690,3080),"expected_literal":255},
		{"id":"parcel_outside","source_px":Vector2(2800,3500),"expected_literal":0}]
	for witness: Dictionary in witnesses:
		var p: Vector2=witness["source_px"]
		var h: float=source.triangle_height(p)
		var native: Vector2=pilot_camera.unproject_position(SOURCE.point3(p,h))
		var logical:=Vector2i((native/float(SSAA)).round())
		var rect:=Rect2i(logical-Vector2i(32,32),Vector2i(64,64))
		if not Rect2i(Vector2i.ZERO,SOURCE.SIZE).encloses(rect):
			error="Diagnostic source witness projects beyond actual canvas."
			return {}
		var row: Dictionary={"id":witness["id"],"source_XZ_px":[p.x,p.y],"actual_RF_height":h,
			"actual_camera_native_px":[native.x,native.y],"actual_logical_center_px":_v2i(logical),
			"literal_expected_R":witness["expected_literal"],"roles":"R literal finite-owner / G old untyped Array uploaded-owner / B zero",
			"scope":"unshaded shader owner diagnostic only; NOT ecology image, binary authority or visual approval"}
		for pass_index in 2:
			var draw: Dictionary=await _pilot_draw("finite_owner_"+String(witness["id"])+str(pass_index))
			if not bool(draw.get("fresh_actual_post_draw_observed",false)) or not _shader_gate(material,["debug_uniform_parcels"]):
				error="Actual diagnostic shader/draw fence rejected."
				return {}
			var captured: Dictionary=await _pilot_read_roi({"id":"debug_"+String(witness["id"]),"rect":rect},"visual",directory,pass_index,draw)
			if captured.is_empty(): return {}
			if pass_index==0: row["capture"]=captured
			else:
				row["repeat_capture"]=captured
				row["actual_raw_repeat"]=_pilot_compare_pngs(row["capture"]["raw_path"],captured["raw_path"])
				row["actual_logical_repeat"]=_pilot_compare_pngs(row["capture"]["path"],captured["path"])
				if not bool(row["actual_raw_repeat"]["byte_exact"]) or not bool(row["actual_logical_repeat"]["byte_exact"]):
					error="Finite-owner diagnostic true repeat differs."
					return {}
		var image: Image=Image.load_from_file(row["capture"]["path"])
		if image==null or image.get_size()!=rect.size or image.get_format()!=Image.FORMAT_RGBA8:
			error="Actual finite-owner PNG decode failed."
			return {}
		var bytes: PackedByteArray=image.get_data()
		var offset: int=(32*rect.size.x+32)*4
		var rgba: Array=[bytes[offset],bytes[offset+1],bytes[offset+2],bytes[offset+3]]
		row["actual_center_RGBA"]=rgba
		row["literal_at_source_witness_correct"]=int(rgba[0])==int(witness["expected_literal"]) and int(rgba[2])==0 and int(rgba[3])==255
		row["legacy_uploaded_matches_literal_at_witness"]=int(rgba[0])==int(rgba[1])
		image=null
		if not bool(row["literal_at_source_witness_correct"]):
			pilot_result["failed_finite_owner_diagnostic"]=row
			error="Literal finite parcel shader does not match actual source witness; refuse normal showcase."
			return {}
		rows.append(row)
	for index in pilot_receivers.size(): pilot_receivers[index].material_override=saved[index]
	saved.clear()
	material=null
	return {"identity":"ACTUAL_WHOLE_GPU_LITERAL_VS_UNTYPED_ARRAY_OWNER_DIAGNOSTIC_V1","witnesses":rows,
		"actual_binding":diagnostic_binding,
		"legacy_uniform_variant_sha256":(surface as V9C_SURFACE)._v9_variant_sha(_v9c_legacy_parcel_array()),
		"no_navigation_capture_credit":true,"not_a_visual_approval":true}

func _v9c_legacy_parcel_array() -> Array:
	var values: Array=[]
	for parcel: Vector4 in V9C_SURFACE.V9_PARCELS: values.append(parcel)
	return values

func _v9c_load_bodies() -> bool:
	var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(V9C_BASE_MANIFEST))
	if not manifest is Dictionary or manifest.get("source_contract_path")!=V9C_BASE_SOURCE:
		error="179 manifest does not bind its actual source body contract."
		return false
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(V9C_BASE_SOURCE))
	if not parsed is Dictionary or not parsed.get("objects") is Array:
		error="Immutable 179 actual independent body list unavailable."
		return false
	full_objects.clear()
	for object: Dictionary in parsed["objects"]:
		var path: String=object.get("texture","")
		if not pilot_inputs.has(path) or FileAccess.get_sha256(path).to_lower()!=String(pilot_inputs[path]).to_lower():
			error="Unpinned unchanged independent 179 body: "+path
			return false
		full_objects.append(object.duplicate(true))
		v9c_body_inputs[path]=pilot_inputs[path]
	pilot_result["body_composite_provenance"]={"manifest_path":V9C_BASE_MANIFEST,"manifest_sha256":V9C_BASE_MANIFEST_SHA,"source_path":V9C_BASE_SOURCE,"source_sha256":V9C_BASE_SOURCE_SHA,"unchanged_objects":full_objects.size(),"body_inputs_sha256":v9c_body_inputs,"scope":"unchanged actual 179 bodies/foot/render/layers on NEW ground only; not a new body/physics acceptance"}
	return true

func _v9c_composites(measured: Dictionary) -> bool:
	var ordered: Array[Dictionary]=full_objects.duplicate()
	ordered.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
		if (int(a.get("z_index",0))<0)!=(int(b.get("z_index",0))<0): return int(a.get("z_index",0))<0
		return float(a.get("depth_sort_foot_y",0.))<float(b.get("depth_sort_foot_y",0.)))
	var evidence: Dictionary={}
	for item: Dictionary in _pilot_windows():
		var rect: Rect2i=item["rect"]
		var record: Dictionary=measured["roles"]["visual"]["windows"][item["id"]]
		var image: Image=Image.load_from_file(record["path"])
		if image==null or image.get_size()!=rect.size:
			error="Actual bounded ground canvas missing."
			return false
		for object: Dictionary in ordered:
			var size:=Vector2i(object["render_size_px"][0],object["render_size_px"][1])
			var center:=Vector2(object["pos"][0]*SOURCE.SIZE.x,object["pos"][1]*SOURCE.SIZE.y)
			var bounds:=Rect2i(Vector2i((center-Vector2(size)*.5).round()),size)
			if not bounds.intersects(rect): continue
			var body: Image=Image.load_from_file(object["texture"])
			if body==null:
				error="Actual body decode failed."
				return false
			if body.get_size()!=size: body=_alpha_resize(body,size)
			image.blend_rect(body,Rect2i(Vector2i.ZERO,size),bounds.position-rect.position)
		var path: String=pilot_output+String(item["id"])+"_scene_components.png"
		if image.save_png(path)!=OK:
			error="Bounded actual composite save failed."
			return false
		evidence[item["id"]]={"path":path,"sha256":FileAccess.get_sha256(path),"logical_rect_px":_recti(rect),"actual_ground_path":record["path"],"actual_ground_sha256":record["sha256"],"scope":"CPU composite of current whole-camera ground + exact unchanged independent 179 bodies; not Field screenshot"}
	pilot_result["showcase_composites"]=evidence
	return true

func _pilot_finish(passed: bool) -> void:
	if not passed:
		pilot_result["status"]="V9C_PROPOSAL_REFUSED_OR_TECHNICAL_FAIL"
		pilot_result["reason"]=error
	if not pilot_output.is_empty() and not _write_json(pilot_output+"result.json",pilot_result): passed=false
	await _pilot_release_world()
	v7_plane_prototypes.clear()
	v7_walk_cache.clear()
	v9c_body_inputs.clear()
	v9c_script_closure.clear()
	pilot_transport=null
	pilot_global_mesh=null
	pilot_support_mesh=null
	pilot_shader=null
	_release_full_refs()
	if surface!=null: surface.release()
	surface=null
	source=null
	var started: int=Time.get_ticks_msec()
	while Time.get_ticks_msec()-started<9000: await process_frame
	var audio:=root.get_node_or_null("AudioManager")
	if audio!=null and audio.has_method("stop_bgm"): audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	print("V9C_VISUAL_QUALITY_PROPOSAL_RESULT ",pilot_output," passed=",passed)
	await _v9c_quit(passed)




func _v9c_quit(passed: bool) -> void:
	# Dedicated NEW tool lifecycle, no parent failure writer/old output fallback.
	if not passed: push_error(error)
	height_texture=null
	native_mesh_cache.clear()
	native_prototype_cache.clear()
	native_texture_cache.clear()
	PLANTS.textures.clear()
	PLANTS.texture_evidence.clear()
	PLANTS.geometry_evidence.clear()
	v9c_geometry_result.clear()
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	var cursor: Node=root.get_node_or_null("CursorManager")
	if cursor!=null:
		for key: String in ["_arrow","_hand","_wait"]: cursor.set(key,null)
	for frame in range(16): await process_frame
	quit(0 if passed else 1)

