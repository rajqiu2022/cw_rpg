extends "res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd"
## NEW v9c derived-RF context sibling of the frozen original artifact oracle. Four context
## methods below are mechanical copies: only literal root/executed-builder change.
## Original body raw/repeat/crop/PNG/camera/used-index/material/support, deck and
## ecology methods are inherited unchanged. Plane caster proof is additional.
## SOURCE_READY is NOT compilation, Field input, FULL execution or visual approval.
const V9C_ROOT: String = "res://art/maps/world_map_v15_complete_v9c/"
const V9C_SOURCE: String = "res://data/maps/world_map_v15_complete_v9c_source.json"
const V9C_MANIFEST: String = V9C_ROOT + "art_contract.json"
const V9C_REPORT: String = V9C_ROOT + "whole_actual_capture.json"
const V9C_BUILDER: String = "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd"
const ORIGINAL_PARENT_PATH: String = "res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd"
const ORIGINAL_PARENT_SHA: String = "946fcc3f9ba9d1d46b067672bd8bd560e12bc651a96b7096d48d94a5f5f060a9"
const CASTER_PATH: String = "res://tests/helpers/joint_v15_v9c_plane_caster_semantic_probe.gd"
const CASTER_SHA: String = "a98542e32df6f063627ad7ca2a7c8d802d07d1840c4eb02f261ea8c8d51583be"
const CASTER = preload("res://tests/helpers/joint_v15_v9c_plane_caster_semantic_probe.gd")
const V9C_PROTOCOL: String = "COHERENT_WHOLE_FIXED_CAMERA_DERIVED_RF_V9C_FULL64_112_V1"
const DERIVED = preload("res://tests/helpers/joint_v15_v9c_derived_geometry_probe.gd")
var derived_inputs: Dictionary={}
var execution_inputs: Dictionary={}
var final_pins: Dictionary = {}

func configure_derived_inputs(inputs: Dictionary,execution: Dictionary) -> void:
	derived_inputs=inputs.duplicate(true)
	execution_inputs=execution.duplicate(true)

func configure_final_pins(pins: Dictionary) -> void:
	# Configuration is explicit test input, not a source of approval or a lookup
	# of newest artifacts. run retains the exact frozen parent method signature.
	final_pins=pins.duplicate(true)

func _v9c_required_paths() -> Array[String]:
	return [V9C_SOURCE,V9C_MANIFEST,V9C_REPORT,V9C_BUILDER,V9C_ROOT+"terrain_height.rf"]

func _v9c_pins_unchanged() -> bool:
	var paths: Array[String]=_v9c_required_paths()
	if final_pins.size()!=paths.size(): return false
	var sha_pattern: RegEx=RegEx.create_from_string("^[0-9a-fA-F]{64}$")
	for path: String in paths:
		var value: Variant=final_pins.get(path)
		if not value is String or sha_pattern.search(value)==null or not FileAccess.file_exists(path) or FileAccess.get_sha256(path).to_lower()!=value.to_lower(): return false
	return true

func _validate_v9c_context(source: Dictionary,manifest: Dictionary) -> bool:
	var before: int=failures
	_check(FileAccess.get_sha256(ORIGINAL_PARENT_PATH).to_lower()==ORIGINAL_PARENT_SHA and FileAccess.get_sha256(CASTER_PATH).to_lower()==CASTER_SHA,"exact original parent and independent caster implementation bytes, no silent latest code")
	if not _check(_v9c_pins_unchanged(),"explicit exact five v8 final paths/current 64hex SHAs; empty/PENDING/unknown/regional reject"): return false
	var current_source: Variant=JSON.parse_string(FileAccess.get_file_as_string(V9C_SOURCE))
	var current_manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(V9C_MANIFEST))
	_check(current_source is Dictionary and current_manifest is Dictionary and _numeric_equal(source,current_source) and _numeric_equal(manifest,current_manifest),"owner dictionaries exactly match actual frozen v8 JSON; no v6 in-memory relabel")
	var independent: RefCounted=DERIVED.new()
	var binding: Dictionary=independent.call("bindings_report",derived_inputs,manifest,source)
	_check(binding.get("complete")==true,"independent explicit CPU original/runtime copies and actual derivation source report: "+str(binding.get("errors",[])))
	independent.call("release")
	independent=null
	var capture: Variant=source.get("capture")
	_check(source.get("art_revision")=="complete_v9c_coherent_whole" and source.get("schema_version")==15 and _numeric_equal(source.get("world_size"),[12288,8192]) and capture is Dictionary and capture.get("capture_protocol")==V9C_PROTOCOL and manifest.get("art_revision")=="complete_v9c_coherent_whole" and manifest.get("source_contract_path")==V9C_SOURCE,"actual coordinate15 v8 whole source/M authority")
	records["v8_context"]={"pins":final_pins.duplicate(true),"parent_path":ORIGINAL_PARENT_PATH,"parent_sha256":ORIGINAL_PARENT_SHA,"caster_path":CASTER_PATH,"caster_sha256":CASTER_SHA,"original_prototype_same_model_boolean_scope":"FROZEN_ORIGINAL_BODY_AND_ORIGINAL_NATIVE_CASTER_PROVENANCE_ONLY_NOT_NEW_PLANE_PROOF","complete":failures==before,"visual_approved":false}
	return failures==before

func _whole_roi(value: Variant,rect: Rect2i,role: String,native: Dictionary,label: String,actual_root: String=V9C_ROOT) -> bool:
	if not value is Dictionary: return _check(false,"typed actual integer ROI "+label)
	var record: Dictionary=value
	var before: int=failures
	var factor: int=2 if role in ["visual","shadow_off"] else 1
	var halo: Rect2i=rect.grow(96).intersection(Rect2i(Vector2i.ZERO,Vector2i(SIZE)))
	var native_rect:=Rect2i(halo.position*factor,halo.size*factor)
	var crop:=Rect2i(rect.position-halo.position,rect.size)
	if not _check(native_rect.size.x*native_rect.size.y<=ROI_CAP,"exact approved bounded ROI ceiling "+label): return false
	var repeat: Variant=record.get("repeat_transfer_evidence")
	if not _check(repeat is Dictionary,"second genuine GPU integer-transfer record "+label): return false
	for n in 2:
		var r: Dictionary=record if n==0 else repeat
		var draw: Dictionary=native.passes[n]
		var shape: bool=_rect(r.get("logical_rect_px"))==rect and _rect(r.get("global_native_readback_rect_px"))==native_rect and _rect(r.get("logical_overscan_rect_px"))==halo and _rect(r.get("local_logical_crop_px"))==crop and _p(r.get("actual_readback_canvas"))==Vector2(native_rect.size) and _p(r.get("actual_whole_GPU_canvas"))==SIZE*factor and r.get("factor")==factor
		if not _check(shape and r.get("96px_kernel_halo_actual_boundaries_clipped_to_whole")==true and r.get("gamma_correction")==false and r.get("actual_transfer_view_released")==true,"integer global native ROI/actual clipped halo/crop; no gamma or whole CPU readback "+label): continue
		var shader: Variant=r.get("transfer_shader")
		var source_draw: bool=r.get("source_draw")==draw and r.get("source_primary_texture_rid")==draw.get("texture_rid") and _integer(r.get("destination_texture_rid"),1) and _integer(r.get("actual_transfer_post_draw_fence_sequence"),1) and float(r.get("actual_transfer_post_draw_fence_sequence",-1))>float(draw.get("fence_sequence",-1))
		var identity: String="OPAQUE_RGBA8_LANCZOS_ROI96_V1" if factor==2 else "NONE_NATIVE_MSAA0"
		if not _check(source_draw and shader is Dictionary and shader.get("path")==TRANSFER and String(shader.get("sha256","")).to_lower()==TRANSFER_SHA and _bound(TRANSFER,TRANSFER_SHA) and r.get("resampling_identity")==identity,"actual fenced whole source RID→texelFetch target and exact recipe "+label): continue
		var raw_path: String=String(r.get("raw_path",""))
		var path: String=String(r.get("path",""))
		if not _check(raw_path.begins_with(actual_root) and path.begins_with(actual_root) and raw_path!=path and String(r.get("raw_sha256","")).length()==64 and String(r.get("sha256","")).length()==64 and _bound(raw_path,String(r.get("raw_sha256",""))) and _bound(path,String(r.get("sha256",""))),"actual raw/logical PNG bytes bound, not metadata-only "+label): continue
		var raw: Image=Image.load_from_file(raw_path)
		var output: Image=Image.load_from_file(path)
		if not _check(raw!=null and output!=null and raw.get_size()==native_rect.size and output.get_size()==rect.size and raw.get_format()==Image.FORMAT_RGBA8 and output.get_format()==Image.FORMAT_RGBA8 and not raw.has_mipmaps() and not output.has_mipmaps(),"original decoded RGBA8 dimensions/format, no representation conversion "+label): continue
		var bytes: PackedByteArray=raw.get_data()
		_check(_sha(bytes)==r.get("raw_RGBA_sha256") and _sha(output.get_data())==r.get("logical_RGBA_sha256"),"independent decoded raw/logical RGBA SHA "+label)
		var pixels_good: bool=raw.detect_alpha()==Image.ALPHA_NONE
		if factor==1:
			# Little-endian RGBA8 words: exact opaque black/white only. Packed
			# native count scans ALL pixels without billions of GDScript calls.
			var words: PackedInt32Array=bytes.to_int32_array()
			pixels_good=pixels_good and words.size()*4==bytes.size() and words.count(-1)+words.count(-16777216)==words.size()
		else:
			# Sort a newly decoded signed-word copy, never the original Image/data.
			# Exactly the inclusive FF000000..FFFFFFFF range has alpha byte255;
			# detect_alpha() may classify254 as opaque and is not authority here.
			var opaque_words: PackedInt32Array=bytes.to_int32_array()
			opaque_words.sort()
			pixels_good=not opaque_words.is_empty() and opaque_words.size()*4==bytes.size() and opaque_words[0]>=-16777216 and opaque_words[opaque_words.size()-1]<=-1
		_check(pixels_good,"every original pixel opaque; native authority RGB exactly binary, no threshold "+label)
		# Independent original-image reconstruction; never call a capture helper.
		if factor==2: raw.resize(halo.size.x,halo.size.y,Image.INTERPOLATE_LANCZOS)
		_check(raw.get_region(crop).get_data()==output.get_data(),"independent exact Lanczos once then integer crop / native binary noresize "+label)
	var raw_repeat: String=String(record.get("raw_repeat_path",""))
	var logical_repeat: String=String(record.get("repeat_path",""))
	_check(raw_repeat==String(repeat.get("raw_path","")) and logical_repeat==String(repeat.get("path","")),"repeat filenames identify actual second transport "+label)
	# Both independent passes were fully decoded above. Reuse only their proven
	# decoded-byte SHA, then independently compare the ORIGINAL PNG byte arrays;
	# this avoids a redundant third decoding, never a repeat or pixel omission.
	for keys: Array in [["raw_path","raw_repeat_path","raw_RGBA_sha256"],["path","repeat_path","logical_RGBA_sha256"]]:
		var first: String=String(record.get(keys[0],""))
		var second: String=String(record.get(keys[1],""))
		_check(first!=second and _bound(first) and _bound(second) and record.get(keys[2])==repeat.get(keys[2]) and FileAccess.get_file_as_bytes(first)==FileAccess.get_file_as_bytes(second),"distinct actual raw/logical passes decoded RGBA and original PNG byteexact "+label+"/"+String(keys[0]))
	return failures==before

func _whole(manifest: Dictionary) -> void:
	var before: int=failures
	var binding: Variant=manifest.get("whole_actual_capture")
	if not _check(binding is Dictionary and binding.get("path")==V9C_ROOT+"whole_actual_capture.json" and String(binding.get("sha256","")).length()==64 and _bound(String(binding.get("path","")),String(binding.get("sha256",""))),"new FULL whole report current SHA"): return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(binding.path))
	if not _check(data is Dictionary,"actual whole report dictionary"): return
	whole_capture=data
	if not _check(whole_capture.get("capture_protocol")==V9C_PROTOCOL and whole_capture.get("scope")=="V9C_FULL64_112SEAMS_DERIVED_RF_NEW_PROTOCOL_NOT_FORMAL_APPROVED" and whole_capture.get("status")=="V9C_FULL64_112SEAMS_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_FIELD_REVIEW" and whole_capture.get("chunk_count_required")==64 and whole_capture.get("seam_count_required")==112 and whole_capture.get("input_hashes_unchanged_after")==true and whole_capture.get("no_legacy_frustum_seam_pass_claim")==true and whole_capture.get("whole_cpu_image_requested")==false and whole_capture.get("whole_cpu_image_allowed")==false and whole_capture.get("maximum_CPU_ROI_pixels")==ROI_CAP,"FULL protocol/scope/64+112 with exact CPU ceiling; bounded pilot is not FULL"): return
	var expected_budget: Dictionary={"previous_pilot_pixels":8388608,"maximum_pixels":8404992,"maximum_native_canvas":[3456,2432],"logical_tile":[1536,1024],"logical_halo_px":96,"ssaa_scale":2,"additional_pixels":16384,"additional_RGBA_bytes":65536,"whole_CPU_Image_allowed":false}
	_check(_numeric_equal(whole_capture.get("CPU_ROI_budget"),expected_budget),"new FULL explicit memory delta, not silently relabelled pilot cap")
	var executed: Variant=whole_capture.get("executed_builder")
	var authorization: Variant=whole_capture.get("authorization")
	if not _check(executed is Dictionary and executed.get("path")=="res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd" and String(executed.get("sha256","")).length()==64 and _bound(executed.path,String(executed.get("sha256",""))) and authorization is Dictionary and String(authorization.get("sha256","")).length()==64 and _bound(String(authorization.get("path","")),String(authorization.get("sha256",""))),"exact executed FULL source and actual authorization bytes"): return
	var auth: Variant=JSON.parse_string(FileAccess.get_file_as_string(authorization.path))
	_check(auth is Dictionary and auth.get("approved")==true and auth.get("scope")==V9C_PROTOCOL and auth.get("builder_path")==executed.path and auth.get("builder_sha256")==executed.sha256 and auth.get("output_root")==V9C_ROOT and auth.get("allow_full64")==true and auth.get("memory_budget_approved")==true and auth.get("maximum_cpu_roi_pixels")==ROI_CAP and _numeric_equal(auth.get("CPU_ROI_budget"),expected_budget) and auth.get("CPU_whole_402M_Image_allowed")==false,"root FULL authorization explicitly binds actual source/cap and forbids whole CPU Image")
	var worlds: Variant=whole_capture.get("worlds")
	if not _check(worlds is Dictionary and worlds.size()==2 and worlds.get("primary") is Dictionary and worlds.get("reference") is Dictionary,"exact two independent typed whole-world identities"): return
	var guards: Variant=whole_capture.get("fresh_preallocation_guards")
	var history: Variant=whole_capture.get("actual_memory_history")
	if not _check(guards is Array and guards.size()==2 and history is Dictionary and history.get("valid")==true,"both actual whole allocations have fresh guards and bound actual memory history"): return
	var guard_ids: Dictionary={}
	for guard: Variant in guards:
		if not _check(guard is Dictionary and guard.get("world_identity") in ["primary","reference"] and not guard_ids.has(guard.get("world_identity")),"unique typed primary/reference preallocation guard"): continue
		guard_ids[guard.world_identity]=true
		var actual: Variant=guard.get("actual_fresh_queries")
		_check(guard.get("passed")==true and guard.get("allocation_requested_after_guard")==true and guard.get("no_resolution_or_SSAA_downgrade")==true and actual is Dictionary and actual.get("valid")==true and actual.get("gpu_uuid")==history.get("gpu_uuid") and _integer(guard.get("vram_required_bytes"),1) and _integer(guard.get("host_RAM_required_bytes"),1) and _integer(actual.get("vram_free_bytes")) and _integer(actual.get("host_free_bytes")) and float(actual.get("vram_free_bytes",-1))>=float(guard.get("vram_required_bytes",INF)) and float(actual.get("host_free_bytes",-1))>=float(guard.get("host_RAM_required_bytes",INF)),"actual preallocation capacity/fresh adapter and no resolution downgrade "+String(guard.world_identity))
	_check(guard_ids.size()==2,"each fresh whole-world allocation has its own guard")
	whole_windows=_enumerate_windows()
	var completed: int=0
	for identity: String in ["primary","reference"]:
		var w: Variant=worlds[identity]
		if not _check(w is Dictionary and w.get("identity")==identity and w.get("actual_world_released_before_next")==true and _integer(w.get("world_node_instance_id"),1) and _integer(w.get("viewport_instance_id"),1) and _integer(w.get("world_3d_instance_id"),1) and _camera(w.get("camera"),2) and w.get("roles") is Dictionary and w.roles.size()==5,"fresh true World3D/viewport/whole camera released before next "+identity): continue
		var coverage: Variant=w.get("coverage")
		_check(coverage is Dictionary and coverage.get("passed")==true and coverage.get("entire_canvas_covered")==true and _integer(coverage.get("actual_receiver_vertices"),1) and _integer(coverage.get("actual_caster_unique_draw_vertices_across_instances"),1) and coverage.get("shadow_max_actual_m")==160 and is_finite(float(coverage.get("max_actual_source_projection_error_px",NAN))) and float(coverage.get("max_actual_source_projection_error_px",INF))<=.01,"actual full receiver/native casters/projection contract "+identity)
		for role: String in WHOLE_ROLES:
			var r: Variant=w.roles.get(role)
			var factor: int=2 if role in ["visual","shadow_off"] else 1
			if not _check(r is Dictionary and _p(r.get("actual_native_canvas"))==SIZE*factor and _camera(r.get("frozen_camera_projection"),factor) and r.get("MSAA_3D_actual")==0 and r.get("MSAA_2D_actual")==0 and r.get("passes") is Array and r.passes.size()==2 and r.get("windows") is Dictionary and r.windows.size()==176,"five-role actual camera/native canvas and 2 draws/176 ROIs "+identity+"/"+role): continue
			var draws_ok: bool=true
			for n in 2: draws_ok=_pass(r.passes[n],identity+"_"+role+"_"+str(n),SIZE*factor) and draws_ok
			if not draws_ok: continue
			_check(float(r.passes[1].process_before)>float(r.passes[0].process_after) and float(r.passes[1].fence_sequence)>float(r.passes[0].fence_sequence),"repeat is later actual fenced draw, never file copy "+identity+"/"+role)
			for id: String in whole_windows:
				if _whole_roi(r.windows.get(id),whole_windows[id],role,r,identity+"/"+role+"/"+id): completed+=1
	for key: String in ["world_node_instance_id","viewport_instance_id","world_3d_instance_id"]:
		_check(worlds.primary.get(key)!=worlds.reference.get(key),"second actual world has distinct "+key)
	if completed==2*5*176:
		for role: String in WHOLE_ROLES:
			for id: String in whole_windows:
				var a: Dictionary=worlds.primary.roles[role].windows[id]
				var b: Dictionary=worlds.reference.roles[role].windows[id]
				var matched: bool=a.path!=b.path and a.raw_path!=b.raw_path
				# Every raw/logical source in both worlds has already been decoded
				# and independently reconstructed. Compare those proven RGBA hashes
				# plus each original PNG byte array; do not allocate a whole Image.
				for keys: Array in [["path","logical_RGBA_sha256"],["raw_path","raw_RGBA_sha256"]]:
					matched=matched and a.get(keys[1])==b.get(keys[1]) and FileAccess.get_file_as_bytes(a[keys[0]])==FileAccess.get_file_as_bytes(b[keys[0]])
				_check(matched,"two fresh worlds same global native/raw and logical PNG/RGBA byteexact, zero tolerance "+role+"/"+id)
	_check(completed==1760,"all2 worlds×5 roles×176 windows independently reconstructed twice")
	whole_complete=failures==before
	records["whole"]={"path":binding.path,"sha256":binding.sha256,"completed_windows":completed,"required_windows":1760,"pixel_tolerance":0,"local_frustum_authority_claimed":false,"complete":whole_complete}

func _chunk(entry: Dictionary) -> void:
	var id: String=String(entry.get("id",""))
	var capture: Variant=entry.get("capture")
	if not _check(capture is Dictionary,"actual full chunk capture record: "+id): return
	var c: Dictionary=capture
	if not _check(whole_complete and whole_windows.has(id) and c.get("capture_protocol")==V9C_PROTOCOL and c.get("capture_role")=="primary" and c.get("window_id")==id and _p(c.get("actual_native_canvas"))==SIZE*2 and _p(c.get("actual_logical_canvas"))==Vector2(TILE) and c.get("binary_MSAA")==0 and c.get("binary_resized")==false and c.get("whole_CPU_Image_requested")==false,"runtime tile originates in verified fixed whole primary draw, not local viewport "+id): return
	var w: Dictionary=whole_capture.worlds.primary
	_check(c.get("actual_camera")==w.camera,"tile camera equals actual whole camera; not re-labelled local frustum "+id)
	var before: int=failures
	var completed: Array[String]=[]
	for role: String in WHOLE_ROLES:
		var r: Dictionary=w.roles[role].windows[id]
		if not _check(c.get("roles",{}).get(role)==r,"runtime alias references exact verified whole ROI record "+id+"/"+role): continue
		var path: String=V9C_ROOT+"chunks/"+id+"_"+role+".png"
		var repeat_path: String=V9C_ROOT+"chunks/"+id+"_"+role+"_repeat.png"
		var output: Image=_raw_pair(path,repeat_path,TILE)
		var original: Image=_image(r.path)
		var exact: bool=output!=null and original!=null and c.get(role+"_path")==path and entry.get(role+"_path")==path and c.get(role+"_repeat_path")==repeat_path and c.get("outputs_sha256",{}).get(path)==catalog.get(path) and c.get("outputs_sha256",{}).get(repeat_path)==catalog.get(repeat_path) and output.get_data()==original.get_data() and FileAccess.get_file_as_bytes(path)==FileAccess.get_file_as_bytes(r.path) and FileAccess.get_file_as_bytes(repeat_path)==FileAccess.get_file_as_bytes(r.repeat_path)
		_check(exact,"distinct runtime file is byteexact verified whole ROI copy, no extra capture claim "+id+"/"+role)
		if exact: completed.append(role)
	var visual: Image=_image(V9C_ROOT+"chunks/"+id+"_visual.png")
	var on: Image=_image(String(w.roles.visual.windows[id].path))
	_check(visual!=null and on!=null and visual.get_data()==on.get_data(),"runtime visual is actual primary ON ground; actual whole has no invented shadow_on alias file: "+id)
	_check(w.roles.visual.get("caster_actual_visible")==true and w.roles.shadow_off.get("caster_actual_visible")==false and w.roles.visual.get("caster_shadow_setting_actual")==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY,"actual independent native ON/OFF caster pass is SHADOWS_ONLY; no body baked into ground "+id)
	records.chunks.append({"id":id,"exact_roles":completed,"actual_whole_GPU_native_size":[24576,16384],"actual_runtime_size":[TILE.x,TILE.y],"complete":completed.size()==5 and failures==before,"capture":c.duplicate(true)})

func run(owner: RefCounted) -> Dictionary:
	phase=owner
	tree=phase.get("owner_tree") as SceneTree
	var manifest: Dictionary=phase.get("manifest")
	var source: Dictionary=phase.get("source")
	catalog=manifest.get("asset_sha256",{})
	if not _validate_v9c_context(source,manifest): return _finish()
	_whole(manifest)
	if not _v9c_material_evidence(source,manifest): return _finish()
	if not _six_regional_material_inputs(source): return _finish()
	if not whole_complete: return _finish()
	var rf: String=V9C_ROOT+"terrain_height.rf"
	if not _check(_bound(rf) and FileAccess.get_file_as_bytes(rf).size()==1537*1025*4,"actual full RF bytes before independent instance/deck projection"): return _finish()
	geometry.set("height",FileAccess.get_file_as_bytes(rf).to_float32_array())
	var ids: Dictionary={}
	for chunk: Dictionary in manifest.get("chunks",[]):
		var id: String=String(chunk.get("id",""))
		_check(not ids.has(id),"unique actual chunk capture")
		ids[id]=true
		_chunk(chunk)
	_check(ids.size()==64 and records.chunks.size()==64,"all64 whole-world high/raw/repeat/derived authoritative capture checks completed")
	_instances(source)
	_decks(manifest,source,phase.get("oracle"))
	_ecology(source,phase.get("oracle"))
	_check(_v9c_pins_unchanged(),"all five final v8 source/artifact inputs unchanged after inherited body/deck/ecology and independent caster reads")
	return _finish()

func _instances(source: Dictionary) -> void:
	# No bypass or edited prototype JSON: super runs every original body assertion,
	# including historical cache same-model provenance. That old boolean cannot
	# establish the NEW plane's mesh/material/pose, which is verified separately.
	super._instances(source)
	var probe: RefCounted=CASTER.new()
	var caster_result: Dictionary=probe.call("run",final_pins)
	var child_checks: int=int(caster_result.get("checks",0))
	var child_failed: int=int(caster_result.get("failed",0))
	# Aggregate actual performed child checks, not synthetic per-ID pass credits.
	# The independent child emits its own original errors and retains all rows.
	checks+=child_checks
	failures+=child_failed
	phase.set("checks",int(phase.get("checks"))+child_checks)
	phase.set("failures",int(phase.get("failures"))+child_failed)
	_check(child_checks>0 and child_failed>=0 and child_failed<=child_checks and caster_result.get("complete")==true and child_failed==0,"both actual worlds' complete independent plane/native caster semantics; original body proof remains required")
	records["v8_saved_casters"]=caster_result.duplicate(true)
	_check(bool(phase.call("_write_json","actual_v9c_saved_caster_semantics.json",caster_result)),"separate actual v8-context/original-v7-identity caster evidence checked write/readback; not a FULL/Field/visual verdict")
	probe.call("release")
	probe=null



const V9C_MATERIAL_ID: String="V9C_CONTINUOUS_CULTIVATION_DRY_BANK_SEDIMENT_STATIC_WATER_PROPOSAL"
const V9C_BASE_SURFACE: String="res://scripts/dev/world_map_v15_complete_v7_surface_proposal.gd"
const V9C_BASE_SURFACE_SHA: String="0f469cd0bfac24195df18e9667873b926d6bee9875f1ca171ccbddeaff2dd7f8"
const V9C_PBR_SOURCES: Array[Dictionary]=[
 {"id":"leafy_grass","meters":2.,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/leafy_grass/"},
 {"id":"grass_ground","meters":2.51,"directory":"res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/"},
 {"id":"forest_ground_04","meters":3.2,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/forest_ground_04/"},
 {"id":"rock_01","meters":1.5,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/"},
 {"id":"brown_mud_03","meters":1.3,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/"},
 {"id":"aerial_grass_rock","meters":15.,"directory":"res://art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock/"}
]

func _historical_shader_controls() -> Dictionary:
	# Read the pinned original shader literals, NEVER instantiate its script or
	# the changed executor. Independently specified algebraic deltas below.
	if not _check(_bound(V9C_BASE_SURFACE,V9C_BASE_SURFACE_SHA),"frozen original shader-source bytes"): return {}
	var original: String=FileAccess.get_file_as_string(V9C_BASE_SURFACE).replace("\r\n","\n")
	var expression: RegEx=RegEx.create_from_string('(?s)shader\\.code="""(.*?)"""')
	var matches: Array[RegExMatch]=expression.search_all(original)
	if not _check(matches.size()==2,"exact original terrain/water shader literal pair"): return {}
	var terrain: String=matches[0].get_string(1)
	var water: String=matches[1].get_string(1)
	var changes: Array[Array]=[
	 ["float plot=step(.46,n2(vec2(floor(xyz.x/4.8),floor((xyz.z+.21*xyz.x)/8.6))));",
	  """// Continuous 0.8-1.3m cultivated furrows; no categorical plot floor/step.
 float field_warp=.19*sin(xyz.z*.61)+.12*sin(xyz.x*.37+xyz.z*.23);
 float furrow_phase=(xyz.x+.21*xyz.z+field_warp)*6.8;
 float furrow=.5+.5*sin(furrow_phase);
 float plot=.32+.28*smoothstep(.22,.78,furrow);
 float furrow_detail=.014*sin(furrow_phase)*field*(1.-route);"""],
	 ["// Broad green pasture / bare-earth islands stay continuous across chunks.",
	  """// Same-owner wet sediment replaces cracked-mud dominance on actual dry banks.
 float wet_owner=wet*(1.-route)*(1.-rock)*(1.-snow);
 float sediment=n2(xyz.xz/1.65)*.35+n2(xyz.xz/6.2)*.65;
 vec3 wet_loam=mix(vec3(.145,.175,.135),vec3(.265,.285,.20),sediment);
 vec3 leaf=scan(leafy_grass_diff,2.,w,1.);
 col=mix(col,mix(wet_loam,leaf,.18),wet_owner*.88);
 arm=mix(arm,mix(vec3(1.,.68,0.),scan(leafy_grass_arm,2.,w,1.),.18),wet_owner*.88);
 detail=mix(detail,mix(vec3(.5,.5,1.),scan(leafy_grass_nor_gl,2.,w,1.),.18),wet_owner*.88);
 // Broad green pasture / bare-earth islands stay continuous across chunks."""],
	 ["vec3 wn=normalize(gn+vec3((detail.r-.5)*strength,0.,(detail.g-.5)*strength));",
	  "vec3 wn=normalize(gn+vec3((detail.r-.5)*strength+furrow_detail,0.,(detail.g-.5)*strength+furrow_detail*.21));"]
	]
	for delta: Array in changes:
		if not _check(terrain.count(delta[0])==1,"unique original terrain algebra anchor"): return {}
		terrain=terrain.replace(delta[0],delta[1])
	var old_water: String="ALBEDO=mix(shallow,channel,deep)+vec3(.007,.011,.009)*crest;"
	if not _check(water.count(old_water)==1,"unique original water algebra anchor"): return {}
	var new_water: String="""// Native static interference detail: no TIME, fake foam, or new wet mask.
 float fine=.5+.5*sin(a*.73+b*.21);
 ALBEDO=mix(shallow,channel,deep)+vec3(.018,.025,.021)*crest+vec3(.004,.006,.005)*(fine-.5)*deep;"""
	return {"terrain":terrain,"water":water.replace(old_water,new_water),"original_terrain_sha256":_sha(matches[0].get_string(1).to_utf8_buffer()),"original_water_sha256":_sha(matches[1].get_string(1).to_utf8_buffer())}

func _v9c_registered_binding(binding: Variant) -> bool:
	var initial: int=failures
	if not _check(binding is Dictionary and binding.size()==18,"exact eighteen actual registered terrain channels"): return false
	var expected_keys: Array[String]=[]
	for asset: Dictionary in V9C_PBR_SOURCES:
		var registration_path: String=asset.directory+"SOURCE.json"
		if not _check(_bound(registration_path),"actual official PBR registration bytes"): continue
		var registration: Dictionary=_v9c_json(registration_path)
		_check(registration.get("license")=="CC0-1.0" and registration.get("asset")==asset.id,"actual PBR license/identity")
		for channel: String in ["diff","nor_gl","arm"]:
			var key: String=asset.id+"_"+channel
			expected_keys.append(key)
			var path: String=asset.directory+key+"_2k.jpg"
			var row_value: Variant=binding.get(key)
			if not _check(row_value is Dictionary and _bound(path),"present exact registered texture channel "+key): continue
			var row: Dictionary=row_value
			var source_row: Dictionary={}
			for item: Dictionary in registration.get("channels",[]):
				if item.get("channel")==channel: source_row=item
			var image: Image=Image.load_from_file(path)
			if not _check(image!=null and not image.is_empty() and image.generate_mipmaps()==OK,"private independently decoded mip chain "+key): continue
			_check(row.get("path")==path and row.get("sha256")==catalog.get(path) and source_row.get("sha256")==catalog.get(path) and source_row.get("md5_verified")==true and row.get("physical_width_m")==asset.meters and row.get("actual_mip_count")==image.get_mipmap_count() and row.get("same_registered_texture_object")==true,"actual recorded channel binding plus original bytes/physical scale/full mip count "+key)
			image=null
	for key: Variant in binding:
		_check(key is String and key in expected_keys,"no unregistered additional terrain channel")
	return failures==initial

func _v9c_json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not _check(value is Dictionary and not value.is_empty(),"actual nonempty dictionary "+path): return {}
	return value



## Independently frozen shader mathematics; no executor method is invoked.
## This is an explicit recipe oracle, not a digest copied from capture metadata.
const ACTUAL_MATERIAL_ID := "V9D_RGB_GRASS_DAMP_SILT_PALE_MINERAL_STEEP_SNOW_EXCLUSION_PROPOSAL"
const PARCELS := [Vector4(3150,3000,220,170),Vector4(3690,3080,240,150),Vector4(4250,3250,195,210),Vector4(4810,3150,215,145),Vector4(5310,3480,230,190),Vector4(3260,3540,245,190),Vector4(3860,3750,210,145),Vector4(4490,3760,225,195),Vector4(4950,3970,210,175),Vector4(5570,4000,185,135),Vector4(6680,5670,205,160),Vector4(7230,5740,240,180),Vector4(7800,5790,185,210),Vector4(8380,5880,230,175),Vector4(6880,6240,235,165),Vector4(7480,6310,190,160),Vector4(8050,6410,235,180),Vector4(8660,6470,210,150)]

func _independent_parcels() -> String:
	var code: String="float field_owner=0.,crop=0.,furrow_n=0.;\n"
	for index in PARCELS.size():
		var parcel: Vector4=PARCELS[index]
		code+=""" {
 vec4 parcel=vec4(%.9f,%.9f,%.9f,%.9f);vec2 delta=p-parcel.xy;
 float angle=sin(%.9f*2.17)*.61;vec2 axis=vec2(cos(angle),sin(angle));
 vec2 local=vec2(dot(delta,axis),dot(delta,vec2(-axis.y,axis.x)))/parcel.zw;
 float margin=max(abs(local.x),abs(local.y));
 float owner=1.-smoothstep(.980,1.014,margin);
 float phase=dot(delta,axis)*.785398163397+%.9f*1.73+(n2(xyz.xz/2.3)-.5)*.35;
 if(owner>field_owner){field_owner=owner;crop=.20+.35*smoothstep(.55,.88,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
"""%[parcel.x,parcel.y,parcel.z,parcel.w,float(index),float(index)]
	return code

func _independent_fragment() -> String:
	return """uniform float v9d_material_identity=1.;
void fragment(){
 vec2 p=vec2(xyz.x*102.4+6144.,xyz.z*72.40773439+4096.);
 vec2 uv=(p-source_rect.xy)/source_rect.zw;
 vec4 eco=texture(biome_weights,uv);vec3 road=texture(road_weights,uv).rgb;
 vec3 gn=normalize(geo);vec3 w=pow(abs(gn),vec3(4.));w/=max(dot(w,vec3(1.)),.00001);
 float forest=clamp(eco.r,0.,1.),rock=clamp(eco.g,0.,1.),wet=clamp(eco.b,0.,1.),snow=clamp(eco.a,0.,1.);
 float route=clamp(road.r,0.,1.),sand=road.b*(1.-snow)*(1.-forest);
 float patch=n2(xyz.xz/1.9)*.38+n2(xyz.xz/5.8+vec2(7.,-3.))*.62;
 float growth=smoothstep(.34,.67,patch);
 // Registered diffuse stays in RGB. Native pigment correction is a small
 // multiplier, not replacement by two flat colours or a luma-only field.
 vec3 gd=scan(grass_ground_diff,2.51,w,.25),ld=scan(leafy_grass_diff,2.,w,.25);
 vec3 fd=scan(forest_ground_04_diff,3.2,w,0.),rd=scan(rock_01_diff,1.5,w,0.);
 vec3 bd=scan(brown_mud_03_diff,1.3,w,.25),ad=scan(aerial_grass_rock_diff,15.,w,0.);
 vec3 ga=scan(grass_ground_arm,2.51,w,.25),la=scan(leafy_grass_arm,2.,w,.25);
 vec3 fa=scan(forest_ground_04_arm,3.2,w,0.),ra=scan(rock_01_arm,1.5,w,0.);
 vec3 ba=scan(brown_mud_03_arm,1.3,w,.25),aa=scan(aerial_grass_rock_arm,15.,w,0.);
 vec3 gnscan=scan(grass_ground_nor_gl,2.51,w,.25),ln=scan(leafy_grass_nor_gl,2.,w,.25);
 vec3 fn=scan(forest_ground_04_nor_gl,3.2,w,0.),rn=scan(rock_01_nor_gl,1.5,w,0.);
 vec3 bn=scan(brown_mud_03_nor_gl,1.3,w,.25),an=scan(aerial_grass_rock_nor_gl,15.,w,0.);
 vec3 turf=(gd*.80+ld*.20)*vec3(.86,1.10,.80);
 vec3 turf_a=ga*.80+la*.20,turf_n=gnscan*.80+ln*.20;
 vec3 loam=fd*.75+rd*.20+bd*.05;
 vec3 loam_a=fa*.75+ra*.20+ba*.05,loam_n=fn*.75+rn*.20+bn*.05;
 float dry_island=.015+.085*(1.-growth);
 vec3 col=mix(turf,loam,dry_island),arm=mix(turf_a,loam_a,dry_island),detail=mix(turf_n,loam_n,dry_island);
 // Real litter/soil detail at roots, not a flat black forest disk.
 vec3 litter=ld*.74+fd*.26;
 col=mix(col,litter*vec3(.74,.94,.69),forest*.80);
 arm=mix(arm,la*.74+fa*.26,forest*.80);detail=mix(detail,ln*.74+fn*.26,forest*.80);
 """+_independent_parcels()+"""
 field_owner*=.88*(1.-route)*(1.-forest)*(1.-wet)*(1.-rock)*(1.-snow)*(1.-sand);
 // Narrow ridges between actual granular earth and actual low grass scans.
 // No full-region high-contrast green/brown ALBEDO sine bands.
 col=mix(col,mix(loam,turf,crop)*(.97+.035*furrow_n),field_owner);
 arm=mix(arm,mix(loam_a,turf_a,crop),field_owner);
 detail=mix(detail,mix(loam_n,turf_n,crop),field_owner);
 // Mineral patches retain RGB scan grains at the real1.5/3.2/15m periods.
 float plate=smoothstep(.29,.67,n2(xyz.xz/1.3)*.40+n2(xyz.xz/4.4)*.60);
 vec3 mineral=rd*.93+ad*.07;
 mineral*=vec3(1.07,1.08,1.06);
 float exposed=rock*.95*(1.-snow);
 col=mix(col,mix(mineral,loam,plate*.08),exposed);
 arm=mix(arm,ra*.93+aa*.07,exposed);detail=mix(detail,rn*.93+an*.07,exposed);
 // Existing native sand owner, explicitly not a licensed sand photograph.
 float sand_owner=sand*.90;
 col=mix(col,mix(fd*.43+rd*.57,vec3(.38,.34,.25),.20),sand_owner);
 arm=mix(arm,fa*.43+ra*.57,sand_owner);detail=mix(detail,fn*.43+rn*.57,sand_owner);
 // Irregular opaque wet-soil films/pools on already legal RF soil. They
 // never alter ALPHA/discard/waterY/land/navigation or become walk support.
 float pool=smoothstep(.43,.64,n2(xyz.xz/1.2)*.30+n2(xyz.xz/3.4+vec2(4.,9.))*.70);
 float wet_owner=wet*.97*(1.-route)*(1.-snow);
 float bank_film=1.-smoothstep(.04,.25,xyz.y);

 vec3 silt=fd*.76+ld*.20+bd*.04;
 vec3 wet_col=mix(silt*vec3(.47,.58,.44),silt*vec3(.24,.34,.29),pool*.68+bank_film*.20);
 col=mix(col,wet_col,wet_owner);
 vec3 wet_a=fa*.76+la*.20+ba*.04;wet_a.g=mix(wet_a.g*.55,.18,clamp(pool*.66+bank_film*.28,0.,1.));
 arm=mix(arm,wet_a,wet_owner);detail=mix(detail,fn*.76+ln*.20+bn*.04,wet_owner*(1.-pool*.25));
 // Material snow coverage is irregular; it cannot certify that a cached
 // shelf mesh has been repaired. A derived-RF executor must say so honestly.
 float grade=length(gn.xz)/max(abs(gn.y),.05);
 float deposit=snow*smoothstep(.22,.60,n2(xyz.xz/1.8)*.38+n2(xyz.xz/4.7+vec2(-3.,5.))*.62)*(1.-smoothstep(.30,.68,grade));
 float snow_bed=snow*(1.-deposit);
 col=mix(col,mineral,snow_bed);arm=mix(arm,ra*.93+aa*.07,snow_bed);detail=mix(detail,rn*.93+an*.07,snow_bed);
 vec3 snow_col=mix(vec3(.68,.71,.70),vec3(.85,.87,.86),clamp(rd.r*.80+patch*.45,0.,1.));
 col=mix(col,snow_col,deposit);arm=mix(arm,vec3(1.,.78,0.),deposit);
 detail=mix(detail,mix(vec3(.5,.5,1.),rn,.28),deposit);
 // Coherent compact earth with real mineral ALBEDO/ARM/normal, not a blurred
 // whole brown colour replacement and not the cracked mud scan as a road.
 float compact=n2(xyz.xz/.56)*.34+n2(xyz.xz/2.1)*.66;
 vec3 earth=mix(vec3(.25,.23,.18),vec3(.34,.30,.24),compact);
 vec3 aggregate=fd*.70+rd*.30;
 vec3 lane=mix(earth,aggregate,.62);
 float shoulder=clamp(road.g-route,0.,1.);
 col=mix(col,mix(loam,lane,.65),shoulder*.64);col=mix(col,lane,route);
 arm=mix(arm,mix(vec3(1.,.90,0.),fa*.70+ra*.30,.62),route);
 detail=mix(detail,mix(vec3(.5,.5,1.),fn*.70+rn*.30,.62),route);
 ALBEDO=col;AO=mix(1.,arm.r,.24);ROUGHNESS=clamp(arm.g,.14,.98);SPECULAR=mix(.18,.38,clamp((pool*.70+bank_film*.30)*wet_owner,0.,1.));METALLIC=0.;
 float strength=mix(.26,.20,route);vec3 wn=normalize(gn+vec3((detail.r-.5)*strength,0.,(detail.g-.5)*strength));
 wn=normalize(wn+vec3(furrow_n*.07*field_owner,0.,0.));NORMAL=normalize((VIEW_MATRIX*vec4(wn,0.)).xyz);
}
"""

func _actual_shader_controls() -> Dictionary:
	var inherited: Dictionary=_historical_shader_controls()
	if inherited.is_empty(): return {}
	var original: String=FileAccess.get_file_as_string(V9C_BASE_SURFACE).replace("\r\n","\n")
	var expression: RegEx=RegEx.create_from_string('(?s)shader\\.code="""(.*?)"""')
	var matches: Array[RegExMatch]=expression.search_all(original)
	if not _check(matches.size()==2,"exact frozen original shader pair for V9c header"): return {}
	var terrain: String=matches[0].get_string(1)
	if not _check(terrain.count("void fragment(){")==1 and terrain.count("varying vec3 xyz;varying vec3 geo;")==1,"original native vertex/header anchors"): return {}
	var header: String=terrain.substr(0,terrain.find("void fragment(){"))
	header=header.replace("varying vec3 xyz;varying vec3 geo;","uniform float v9c_material_identity=1.;\nvarying vec3 xyz;varying vec3 geo;")
	return {"terrain":header+_independent_fragment(),"water":inherited.water}

func _v9c_material_evidence(source: Dictionary,manifest: Dictionary) -> bool:
	var initial: int=failures
	var evidence: Variant=source.get("v9c_revision_evidence")
	var report: Dictionary=_v9c_json(V9C_REPORT)
	if not _check(evidence is Dictionary and _numeric_equal(evidence,report.get("v9c_revision_evidence")),"actual source/report same NEW derived revision evidence"): return false
	var controls: Dictionary=_actual_shader_controls()
	if controls.is_empty(): return false
	var execution: Variant=evidence.get("actual_execution")
	if not _check(execution is Dictionary and execution.size()==5 and execution_inputs.size()==5,"actual five execution identities + explicit producer pins"): return false
	var expected: Dictionary={
	 "ecology":"res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_ecology_source.gd",
	 "surface":"res://scripts/dev/world_map_v15_v9d_material_quality_proposal_surface.gd",
	 "full":V9C_BUILDER,
	 "regional":"res://scripts/dev/build_world_map_v15_coherent_whole_v9c_regional_proposal.gd",
	 "geometry_helper":String(derived_inputs.get("derivation_report",{}).get("path",""))
	}
	var derivation: Dictionary=_v9c_json(expected.geometry_helper)
	expected.geometry_helper=String(derivation.get("audit",{}).get("executed_helper",{}).get("path",""))
	for role: String in expected:
		var row: Variant=execution.get(role)
		var path: String=expected[role]
		var exact_pin: String=String(execution_inputs.get(path,"")) if role!="geometry_helper" else String(derivation.get("audit",{}).get("executed_helper",{}).get("sha256",""))
		_check(row is Dictionary and row.get("path")==path and row.get("sha256")==exact_pin and _bound(path,exact_pin) and manifest.get("source_graph",{}).get(path)==exact_pin,"actual executed five roles/current source graph: "+role)
	var caster_path: String="res://scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd"
	_check(_bound(caster_path,String(execution_inputs.get(caster_path,""))),"fifth configured execution pin retains actual original V7 caster source")
	var original_preparation: Variant=evidence.get("original_site_preparation")
	_check(original_preparation is Dictionary and original_preparation.get("baseline_objects")==2687 and original_preparation.get("method")=="BASELINE_RF_PREPARE_THEN_FIXED_BIANZHOU_APPROACH_THEN_BIND_DERIVED_RF_NO_REPREPARE" and original_preparation.get("site_signature")==derivation.get("audit",{}).get("original_site_signature"),"original 2687 sites prepared on immutable baseline, never resampled on NEW RF")
	_check(evidence.get("old_navigation_credit")==false and evidence.get("visual_approved")==false and evidence.get("production_approved")==false,"NEW navigation needs all fresh runtime predicates, no inherited approval")
	var channels: Variant=evidence.get("actual_materials")
	if not _check(channels is Array and channels.size()==18,"all actual original registered texture-source records"): return false
	var channel_index: int=0
	for asset: Dictionary in V9C_PBR_SOURCES:
		for channel: String in ["diff","nor_gl","arm"]:
			var row: Variant=channels[channel_index]
			channel_index+=1
			var path: String=asset.directory+asset.id+"_"+channel+"_2k.jpg"
			var registration: String=asset.directory+"SOURCE.json"
			var image: Image=Image.load_from_file(path)
			var mip_ok: bool=image!=null and image.generate_mipmaps()==OK
			_check(row is Dictionary and _bound(path) and _bound(registration) and row.get("path")==path and row.get("sha256")==catalog.get(path) and row.get("source_path")==registration and row.get("source_sha256")==catalog.get(registration) and row.get("physical_width_m")==asset.meters and row.get("channel")==channel and row.get("color_space")==("sRGB" if channel=="diff" else "linear") and mip_ok and row.get("actual_mip_count")==image.get_mipmap_count(),"actual texture-source order/raw SHA/registration/physical scale/full mips "+path)
			image=null
	var rows: Variant=evidence.get("attached_material_creations")
	if not _check(rows is Array and rows.size()==5,"initial creation plus four actual attached materials"): return false
	var terrain_count: int=0
	var water_count: int=0
	var saved_paths: Dictionary={}
	for index in rows.size():
		var row: Variant=rows[index]
		if not _check(row is Dictionary,"typed actual material row"): continue
		var kind: String=String(row.get("kind",""))
		if index==0:
			_check(kind=="terrain" and row.get("identity")==ACTUAL_MATERIAL_ID and row.get("creation_stage")=="INITIAL_ACTUAL_SHADER_CONSTRUCTION_NOT_A_DRAW" and row.get("row_period_logical_px")==8. and row.get("actual_scan_ALBEDO_primary")==true and row.get("actual_code_sha256")==_sha(String(controls.terrain).to_utf8_buffer()),"initial shader recipe/current identity; not an actual draw credit")
			_v9c_registered_binding(row.get("registered_binding"))
			continue
		if not _check(kind in ["terrain","water"] and row.get("creation_stage")=="ACTUAL_ATTACHED_WHOLE_WORLD_MATERIAL" and row.get("visual_approved")==false and row.get("production_approved")==false,"four real attached non-self-approved materials"): continue
		var path: String=String(row.get("path",""))
		if not _check(path.begins_with(V9C_ROOT) and not saved_paths.has(path) and _bound(path,String(row.get("sha256",""))),"distinct actual saved attached material bytes"): continue
		saved_paths[path]=true
		var material: ShaderMaterial=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
		if not _check(material!=null and material.shader!=null,"actual saved material and shader resource"): continue
		_check(material.shader.code==controls[kind] and row.get("actual_code_sha256")==_sha(material.shader.code.to_utf8_buffer()),"saved actual code equals independent full recipe "+kind)
		var uniform_rows: Variant=row.get("actual_uniforms")
		var uniforms: Array[Dictionary]=material.shader.get_shader_uniform_list()
		if _check(uniform_rows is Array and uniform_rows.size()==uniforms.size(),"all actual saved uniforms/schema retained "+kind):
			for sid in uniforms.size():
				var spec: Dictionary=uniforms[sid]
				var saved_row: Variant=uniform_rows[sid]
				var value: Variant=material.get_shader_parameter(String(spec.name))
				if not _check(saved_row is Dictionary and saved_row.get("name")==spec.name and _numeric_equal(saved_row.get("schema"),JSON.parse_string(JSON.stringify(spec))) and saved_row.get("variant_type")==typeof(value),"actual uniform ordered identity/default-codec schema/native value type"): continue
				if value is Texture2D:
					var image: Image=value.get_image()
					var texture_row: Variant=saved_row.get("texture")
					_check(image!=null and texture_row is Dictionary and texture_row.get("resource_path")==value.resource_path and _p(texture_row.get("canvas"))==Vector2(image.get_size()) and texture_row.get("format")==image.get_format() and texture_row.get("mip_count")==image.get_mipmap_count() and texture_row.get("RGBA_and_all_mips_sha256")==_sha(image.get_data()),"actual saved sampler including every mip exact")
					if kind=="water" and spec.name=="actual_height_rf": _check(image!=null and image.get_format()==Image.FORMAT_RF and image.get_size()==Vector2i(1537,1025) and image.get_data()==FileAccess.get_file_as_bytes(V9C_ROOT+"terrain_height.rf"),"saved water RF texture is exact approved NEW RF")
					image=null
				else:
					_check(not value is Resource and saved_row.get("native_variant_bytes_sha256")==_sha(var_to_bytes(value)) and saved_row.get("value_as_text")==str(value),"all nonresource native uniform bytes exact, not JSON type coercion")
		if kind=="terrain":
			terrain_count+=1
			_check(material.get_shader_parameter("v9c_material_identity")==1. and material.get_shader_parameter("v9d_material_identity")==1.,"actual receiver identity bound")
			_v9c_registered_binding(row.get("registered_binding"))
			for asset: Dictionary in V9C_PBR_SOURCES:
				for channel: String in ["diff","nor_gl","arm"]:
					var key: String=asset.id+"_"+channel
					var texture: Texture2D=material.get_shader_parameter(key) as Texture2D
					var expected_image: Image=Image.load_from_file(asset.directory+key+"_2k.jpg")
					var actual_image: Image=texture.get_image() if texture!=null else null
					var mip_ok: bool=expected_image!=null and expected_image.generate_mipmaps()==OK
					_check(mip_ok and actual_image!=null and expected_image.get_format()==actual_image.get_format() and expected_image.get_mipmap_count()==actual_image.get_mipmap_count() and expected_image.get_data()==actual_image.get_data(),"saved actual registered sampler equals independent original source + full mip recipe "+key)
					expected_image=null; actual_image=null; texture=null
		else:
			water_count+=1
			_check(row.get("RF_bound_to_actual_new_texture")==true and material.get_shader_parameter("grid_origin")==Vector2i.ZERO and material.get_shader_parameter("grid_shape")==Vector2i(1537,1025),"both actual water materials bound approved NEW lattice")
		material=null
	_check(terrain_count==2 and water_count==2 and saved_paths.size()==4,"exact two worlds terrain/water saved-resource coverage")
	var shader_row: Variant=report.get("actual_terrain_shader")
	if _check(shader_row is Dictionary and _bound(String(shader_row.get("path","")),String(shader_row.get("sha256",""))),"actual initial saved terrain shader"):
		var shader: Shader=ResourceLoader.load(String(shader_row.path),"Shader",ResourceLoader.CACHE_MODE_IGNORE) as Shader
		_check(shader!=null and shader.code==controls.terrain,"actual saved initial shader exact independent code")
		shader=null
	records["v9c_material_semantics"]={"complete":failures==initial,"terrain":terrain_count,"water":water_count,"registered_channels":18,"normal_ARM_diffuse_all_mips":true,"new_RF_replaces_old_NAV_credit":true,"executor_invoked":false}
	return failures==initial


# Prior regional evidence is a bound six-ROI source prerequisite, never FULL
# or Field credit. Reuse only THIS independent exact ROI decoder/math.
func _six_regional_material_inputs(source: Dictionary) -> bool:
	var before: int=failures
	var evidence: Dictionary=source.get("v9c_revision_evidence",{})
	var review: Variant=evidence.get("regional_approval")
	var expected: Dictionary={"farmland":Rect2i(3460,2582,1280,1024),"marsh":Rect2i(10160,6576,1280,1024),"snow":Rect2i(4360,0,1280,1024),"limestone":Rect2i(560,1375,1280,1024),"meadow_river":Rect2i(5960,3288,1280,1024),"northern_river_bailu_junction":Rect2i(7960,2489,1280,1024)}
	var scope: String="V9C_TWO_FRESH_WHOLE_WORLDS_SIX_REGIONAL_ROIS_NOT_FULL_OR_FIELD"
	if not _check(review is Dictionary and review.get("approved")==true and review.get("approved_by")=="root" and review.get("scope")==scope,"independent explicit current six-ROI root review prerequisite"): return false
	var path: String=String(review.get("result_path",""))
	if not _check(path.begins_with("res://build/world_map_v15_coherent_whole_v9c_regional/v9d_broad_soft/") and _bound(path,String(review.get("result_sha256",""))),"actual bound six-ROI result, no latest-directory lookup"): return false
	var data: Dictionary=_v9c_json(path)
	var regional: String="res://scripts/dev/build_world_map_v15_coherent_whole_v9c_regional_proposal.gd"
	var executed: Variant=data.get("executed_builder")
	var target: Variant=review.get("candidate_full_builder")
	_check(data.get("scope")==scope and data.get("capture_protocol")=="V9C_DERIVED_RF_TWO_FRESH_WHOLE_FIXED_CAMERA_SIX_ROIS_V2" and data.get("status")=="V9C_REGIONAL_TWO_WORLD_FIVE_ROLE_REPEAT_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_NOT_FULL" and data.get("FULL64_credit")==false and data.get("seam112_credit")==false and data.get("Field_credit")==false and data.get("input_hashes_unchanged_after")==true,"six-ROI actual technical scope cannot supply FULL/Field approval")
	_check(executed is Dictionary and executed.get("path")==regional and executed.get("sha256")==execution_inputs.get(regional) and _bound(regional,String(executed.get("sha256",""))) and target is Dictionary and target.get("path")==V9C_BUILDER and target.get("sha256")==execution_inputs.get(V9C_BUILDER),"actual regional executor and reviewed future FULL source exact")
	var revision: Variant=data.get("v9c_revision_evidence")
	if not _check(revision is Dictionary and _numeric_equal(data.get("derived_geometry_inputs"),derived_inputs) and _numeric_equal(revision.get("derived_geometry_inputs"),derived_inputs) and _numeric_equal(revision.get("derived_geometry_audit"),evidence.get("derived_geometry_audit")) and _numeric_equal(revision.get("actual_materials"),evidence.get("actual_materials")) and _numeric_equal(revision.get("ecology_contract"),evidence.get("ecology_contract")),"same actual RF640/surface18/ecology, not old regional credit"): return false
	var chain: Variant=revision.get("actual_execution")
	if not _check(chain is Dictionary and chain.size()==5,"regional exact five actual source roles"): return false
	for role: String in ["ecology","surface","full","regional","geometry_helper"]:
		var row: Variant=chain.get(role)
		var current: Variant=evidence.get("actual_execution",{}).get(role)
		_check(row is Dictionary and current is Dictionary and row.get("path")==current.get("path") and row.get("sha256")==current.get("sha256"),"same current regional/full source bytes "+role)
	_check(chain.get("full",{}).get("role")=="INHERITED_FULL_METHODS_NOT_REGIONAL_EXECUTOR" and chain.get("regional",{}).get("role")=="ACTUAL_REGIONAL_EXECUTOR" and chain.get("geometry_helper",{}).get("role")=="ACTUAL_CPU_DERIVATION_HELPER_NOT_REEXECUTED_DURING_GPU","regional truthful inherited/executed/helper identities")
	var worlds: Variant=data.get("worlds")
	if not _check(worlds is Dictionary and worlds.size()==2 and worlds.get("primary") is Dictionary and worlds.get("reference") is Dictionary,"two actual fresh regional worlds"): return false
	var completed: int=0
	for identity: String in ["primary","reference"]:
		var world: Dictionary=worlds[identity]
		if not _check(world.get("identity")==identity and world.get("actual_world_released_before_next")==true and _camera(world.get("camera"),2) and world.get("roles") is Dictionary and world.roles.size()==5,"actual regional whole camera/world release "+identity): continue
		for key: String in ["world_node_instance_id","viewport_instance_id","world_3d_instance_id"]:
			_check(_integer(world.get(key),1) and worlds.primary.get(key)!=worlds.reference.get(key),"fresh distinct regional native identity "+key)
		for role: String in WHOLE_ROLES:
			var native: Variant=world.roles.get(role)
			var factor: int=2 if role in ["visual","shadow_off"] else 1
			if not _check(native is Dictionary and _p(native.get("actual_native_canvas"))==SIZE*factor and _camera(native.get("frozen_camera_projection"),factor) and native.get("MSAA_3D_actual")==0 and native.get("MSAA_2D_actual")==0 and native.get("passes") is Array and native.passes.size()==2 and native.get("windows") is Dictionary and native.windows.size()==6,"five native roles/two passes/exact6 ROI "+identity+"/"+role): continue
			var draws: bool=true
			for n in 2: draws=_pass(native.passes[n],identity+"_"+role+"_"+str(n),SIZE*factor) and draws
			if not draws: continue
			_check(float(native.passes[1].process_before)>float(native.passes[0].process_after) and float(native.passes[1].fence_sequence)>float(native.passes[0].fence_sequence),"actual second later regional draw "+role)
			for id: String in expected:
				if _whole_roi(native.windows.get(id),expected[id],role,native,"regional/"+identity+"/"+role+"/"+id,path.get_base_dir()+"/"): completed+=1
	if completed==60:
		for role: String in WHOLE_ROLES:
			for id: String in expected:
				var a: Dictionary=worlds.primary.roles[role].windows[id]
				var b: Dictionary=worlds.reference.roles[role].windows[id]
				var exact: bool=a.path!=b.path and a.raw_path!=b.raw_path
				for keys: Array in [["path","logical_RGBA_sha256"],["raw_path","raw_RGBA_sha256"]]:
					exact=exact and a.get(keys[1])==b.get(keys[1]) and FileAccess.get_file_as_bytes(a[keys[0]])==FileAccess.get_file_as_bytes(b[keys[0]])
				_check(exact,"two fresh regional worlds original raw/logical PNG/RGBA exact "+role+"/"+id)
	_check(completed==60,"all2worlds×5roles×6ROIs×2draw exact decode; no FULL credit")
	records["six_regional_prerequisite"]={"result_path":path,"result_sha256":review.get("result_sha256"),"completed_windows":completed,"required_windows":60,"pixel_tolerance":0,"FULL_credit":false,"Field_credit":false,"complete":failures==before}
	return failures==before

func _finish() -> Dictionary:
	var result: Dictionary={"scope":"ALL64_ACTUAL_ARTIFACTS_MODEL_PROTOTYPES_Y0_DECK_VS_SIGNED_BED_NINE_REGIONS_NOT_VISUAL_APPROVAL","capture_protocol":V9C_PROTOCOL,"checks":checks,"failures":failures,"complete":whole_complete and failures==0 and records.chunks.size()==64 and records.decks.size()==5 and records.ecology.size()==9 and not records.instances.is_empty(),"records":records.duplicate(true),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path)}
	_check(bool(phase.call("_write_json","actual_world_artifact_semantics.json",result)),"full independent artifact evidence checked readback")
	result.checks=checks
	result.failures=failures
	result.complete=bool(result.complete) and failures==0
	geometry.call("release")
	geometry=null
	decoded_models.clear()
	prototype_checks.clear()
	support_checks.clear()
	whole_capture.clear()
	whole_windows.clear()
	catalog.clear()
	phase=null
	tree=null
	return result
