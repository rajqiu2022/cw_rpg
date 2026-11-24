extends "res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd"
## NEW v8 context sibling of the frozen original artifact oracle. Four context
## methods below are mechanical copies: only literal root/executed-builder change.
## Original body raw/repeat/crop/PNG/camera/used-index/material/support, deck and
## ecology methods are inherited unchanged. Plane caster proof is additional.
## SOURCE_READY is NOT compilation, Field input, FULL execution or visual approval.
const V8_ROOT: String = "res://art/maps/world_map_v15_complete_v8/"
const V8_SOURCE: String = "res://data/maps/world_map_v15_complete_v8_source.json"
const V8_MANIFEST: String = V8_ROOT + "art_contract.json"
const V8_REPORT: String = V8_ROOT + "whole_actual_capture.json"
const V8_BUILDER: String = "res://scripts/dev/build_world_map_v15_coherent_whole_v8_full_proposal.gd"
const ORIGINAL_PARENT_PATH: String = "res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd"
const ORIGINAL_PARENT_SHA: String = "946fcc3f9ba9d1d46b067672bd8bd560e12bc651a96b7096d48d94a5f5f060a9"
const CASTER_PATH: String = "res://tests/helpers/joint_v15_v8_plane_caster_semantic_probe.gd"
const CASTER_SHA: String = "9540d953dab742271a23f7016855a47773c134e35183d4aefc47558cb278583d"
const CASTER = preload("res://tests/helpers/joint_v15_v8_plane_caster_semantic_probe.gd")
var final_pins: Dictionary = {}

func configure_final_pins(pins: Dictionary) -> void:
	# Configuration is explicit test input, not a source of approval or a lookup
	# of newest artifacts. run retains the exact frozen parent method signature.
	final_pins=pins.duplicate(true)

func _v8_required_paths() -> Array[String]:
	return [V8_SOURCE,V8_MANIFEST,V8_REPORT,V8_BUILDER,V8_ROOT+"terrain_height.rf"]

func _v8_pins_unchanged() -> bool:
	var paths: Array[String]=_v8_required_paths()
	if final_pins.size()!=paths.size(): return false
	var sha_pattern: RegEx=RegEx.create_from_string("^[0-9a-fA-F]{64}$")
	for path: String in paths:
		var value: Variant=final_pins.get(path)
		if not value is String or sha_pattern.search(value)==null or not FileAccess.file_exists(path) or FileAccess.get_sha256(path).to_lower()!=value.to_lower(): return false
	return true

func _validate_v8_context(source: Dictionary,manifest: Dictionary) -> bool:
	var before: int=failures
	_check(FileAccess.get_sha256(ORIGINAL_PARENT_PATH).to_lower()==ORIGINAL_PARENT_SHA and FileAccess.get_sha256(CASTER_PATH).to_lower()==CASTER_SHA,"exact original parent and independent caster implementation bytes, no silent latest code")
	if not _check(_v8_pins_unchanged(),"explicit exact five v8 final paths/current 64hex SHAs; empty/PENDING/unknown/regional reject"): return false
	var current_source: Variant=JSON.parse_string(FileAccess.get_file_as_string(V8_SOURCE))
	var current_manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(V8_MANIFEST))
	_check(current_source is Dictionary and current_manifest is Dictionary and _numeric_equal(source,current_source) and _numeric_equal(manifest,current_manifest),"owner dictionaries exactly match actual frozen v8 JSON; no v6 in-memory relabel")
	var capture: Variant=source.get("capture")
	_check(source.get("art_revision")=="complete_v8_coherent_whole" and source.get("schema_version")==15 and _numeric_equal(source.get("world_size"),[12288,8192]) and capture is Dictionary and capture.get("capture_protocol")==PROTOCOL and manifest.get("art_revision")=="complete_v8_coherent_whole" and manifest.get("source_contract_path")==V8_SOURCE,"actual coordinate15 v8 whole source/M authority")
	records["v8_context"]={"pins":final_pins.duplicate(true),"parent_path":ORIGINAL_PARENT_PATH,"parent_sha256":ORIGINAL_PARENT_SHA,"caster_path":CASTER_PATH,"caster_sha256":CASTER_SHA,"original_prototype_same_model_boolean_scope":"FROZEN_ORIGINAL_BODY_AND_ORIGINAL_NATIVE_CASTER_PROVENANCE_ONLY_NOT_NEW_PLANE_PROOF","complete":failures==before,"visual_approved":false}
	return failures==before

func _whole_roi(value: Variant,rect: Rect2i,role: String,native: Dictionary,label: String) -> bool:
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
		if not _check(raw_path.begins_with(V8_ROOT) and path.begins_with(V8_ROOT) and raw_path!=path and String(r.get("raw_sha256","")).length()==64 and String(r.get("sha256","")).length()==64 and _bound(raw_path,String(r.get("raw_sha256",""))) and _bound(path,String(r.get("sha256",""))),"actual raw/logical PNG bytes bound, not metadata-only "+label): continue
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
	if not _check(binding is Dictionary and binding.get("path")==V8_ROOT+"whole_actual_capture.json" and String(binding.get("sha256","")).length()==64 and _bound(String(binding.get("path","")),String(binding.get("sha256",""))),"new FULL whole report current SHA"): return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(binding.path))
	if not _check(data is Dictionary,"actual whole report dictionary"): return
	whole_capture=data
	if not _check(whole_capture.get("capture_protocol")==PROTOCOL and whole_capture.get("scope")=="FULL64_112SEAMS_NEW_PROTOCOL_NOT_FORMAL_APPROVED" and whole_capture.get("status")=="FULL64_112SEAMS_NEW_PROTOCOL_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_REVIEW" and whole_capture.get("chunk_count_required")==64 and whole_capture.get("seam_count_required")==112 and whole_capture.get("input_hashes_unchanged_after")==true and whole_capture.get("no_legacy_frustum_seam_pass_claim")==true and whole_capture.get("whole_cpu_image_requested")==false and whole_capture.get("whole_cpu_image_allowed")==false and whole_capture.get("maximum_CPU_ROI_pixels")==ROI_CAP,"FULL protocol/scope/64+112 with exact CPU ceiling; bounded pilot is not FULL"): return
	var expected_budget: Dictionary={"previous_pilot_pixels":8388608,"maximum_pixels":8404992,"maximum_native_canvas":[3456,2432],"logical_tile":[1536,1024],"logical_halo_px":96,"ssaa_scale":2,"additional_pixels":16384,"additional_RGBA_bytes":65536,"whole_CPU_Image_allowed":false}
	_check(_numeric_equal(whole_capture.get("CPU_ROI_budget"),expected_budget),"new FULL explicit memory delta, not silently relabelled pilot cap")
	var executed: Variant=whole_capture.get("executed_builder")
	var authorization: Variant=whole_capture.get("authorization")
	if not _check(executed is Dictionary and executed.get("path")=="res://scripts/dev/build_world_map_v15_coherent_whole_v8_full_proposal.gd" and String(executed.get("sha256","")).length()==64 and _bound(executed.path,String(executed.get("sha256",""))) and authorization is Dictionary and String(authorization.get("sha256","")).length()==64 and _bound(String(authorization.get("path","")),String(authorization.get("sha256",""))),"exact executed FULL source and actual authorization bytes"): return
	var auth: Variant=JSON.parse_string(FileAccess.get_file_as_string(authorization.path))
	_check(auth is Dictionary and auth.get("approved")==true and auth.get("scope")==PROTOCOL and auth.get("builder_path")==executed.path and auth.get("builder_sha256")==executed.sha256 and auth.get("output_root")==V8_ROOT and auth.get("allow_full64")==true and auth.get("memory_budget_approved")==true and auth.get("maximum_cpu_roi_pixels")==ROI_CAP and _numeric_equal(auth.get("CPU_ROI_budget"),expected_budget) and auth.get("CPU_whole_402M_Image_allowed")==false,"root FULL authorization explicitly binds actual source/cap and forbids whole CPU Image")
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
	if not _check(whole_complete and whole_windows.has(id) and c.get("capture_protocol")==PROTOCOL and c.get("capture_role")=="primary" and c.get("window_id")==id and _p(c.get("actual_native_canvas"))==SIZE*2 and _p(c.get("actual_logical_canvas"))==Vector2(TILE) and c.get("binary_MSAA")==0 and c.get("binary_resized")==false and c.get("whole_CPU_Image_requested")==false,"runtime tile originates in verified fixed whole primary draw, not local viewport "+id): return
	var w: Dictionary=whole_capture.worlds.primary
	_check(c.get("actual_camera")==w.camera,"tile camera equals actual whole camera; not re-labelled local frustum "+id)
	var before: int=failures
	var completed: Array[String]=[]
	for role: String in WHOLE_ROLES:
		var r: Dictionary=w.roles[role].windows[id]
		if not _check(c.get("roles",{}).get(role)==r,"runtime alias references exact verified whole ROI record "+id+"/"+role): continue
		var path: String=V8_ROOT+"chunks/"+id+"_"+role+".png"
		var repeat_path: String=V8_ROOT+"chunks/"+id+"_"+role+"_repeat.png"
		var output: Image=_raw_pair(path,repeat_path,TILE)
		var original: Image=_image(r.path)
		var exact: bool=output!=null and original!=null and c.get(role+"_path")==path and entry.get(role+"_path")==path and c.get(role+"_repeat_path")==repeat_path and c.get("outputs_sha256",{}).get(path)==catalog.get(path) and c.get("outputs_sha256",{}).get(repeat_path)==catalog.get(repeat_path) and output.get_data()==original.get_data() and FileAccess.get_file_as_bytes(path)==FileAccess.get_file_as_bytes(r.path) and FileAccess.get_file_as_bytes(repeat_path)==FileAccess.get_file_as_bytes(r.repeat_path)
		_check(exact,"distinct runtime file is byteexact verified whole ROI copy, no extra capture claim "+id+"/"+role)
		if exact: completed.append(role)
	var visual: Image=_image(V8_ROOT+"chunks/"+id+"_visual.png")
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
	if not _validate_v8_context(source,manifest): return _finish()
	_whole(manifest)
	if not _v8_material_evidence(source,manifest): return _finish()
	if not whole_complete: return _finish()
	var rf: String=V8_ROOT+"terrain_height.rf"
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
	_check(_v8_pins_unchanged(),"all five final v8 source/artifact inputs unchanged after inherited body/deck/ecology and independent caster reads")
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
	_check(bool(phase.call("_write_json","actual_v8_saved_caster_semantics.json",caster_result)),"separate actual v8-context/original-v7-identity caster evidence checked write/readback; not a FULL/Field/visual verdict")
	probe.call("release")
	probe=null



const V8_MATERIAL_ID: String="V8_CONTINUOUS_CULTIVATION_DRY_BANK_SEDIMENT_STATIC_WATER_PROPOSAL"
const V8_BASE_SURFACE: String="res://scripts/dev/world_map_v15_complete_v7_surface_proposal.gd"
const V8_BASE_SURFACE_SHA: String="0f469cd0bfac24195df18e9667873b926d6bee9875f1ca171ccbddeaff2dd7f8"
const V8_EXECUTION_EXPECTED: Dictionary={
 "ecology":{"path":"res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd","sha256":"43da1cbe34362e32610a0c27070b514dc7f3f49853a7004ab61a59c7f6662bfa"},
 "surface":{"path":"res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd","sha256":"11bc6572071f58d8852ad3378091d4df30ea7c2e280f484a6f6dcf4d6c4d4f7f"},
 "inherited_full":{"path":"res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd","sha256":"74a7757a43c7ff4e339fa297bf29a0ec7860cf6a70f7508ebd80a418ce18e233"}
}
const V8_PBR_SOURCES: Array[Dictionary]=[
 {"id":"leafy_grass","meters":2.,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/leafy_grass/"},
 {"id":"grass_ground","meters":2.51,"directory":"res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/"},
 {"id":"forest_ground_04","meters":3.2,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/forest_ground_04/"},
 {"id":"rock_01","meters":1.5,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/"},
 {"id":"brown_mud_03","meters":1.3,"directory":"res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/"},
 {"id":"aerial_grass_rock","meters":15.,"directory":"res://art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock/"}
]

func _v8_shader_controls() -> Dictionary:
	# Read the pinned original shader literals, NEVER instantiate its script or
	# the changed executor. Independently specified algebraic deltas below.
	if not _check(_bound(V8_BASE_SURFACE,V8_BASE_SURFACE_SHA),"frozen original shader-source bytes"): return {}
	var original: String=FileAccess.get_file_as_string(V8_BASE_SURFACE).replace("\r\n","\n")
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

func _v8_registered_binding(binding: Variant) -> bool:
	var initial: int=failures
	if not _check(binding is Dictionary and binding.size()==18,"exact eighteen actual registered terrain channels"): return false
	var expected_keys: Array[String]=[]
	for asset: Dictionary in V8_PBR_SOURCES:
		var registration_path: String=asset.directory+"SOURCE.json"
		if not _check(_bound(registration_path),"actual official PBR registration bytes"): continue
		var registration: Dictionary=_v8_json(registration_path)
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

func _v8_material_evidence(source: Dictionary,manifest: Dictionary) -> bool:
	var initial: int=failures
	var evidence_value: Variant=source.get("v8_revision_evidence")
	var report: Dictionary=_v8_json(V8_REPORT)
	if not _check(evidence_value is Dictionary and not report.is_empty(),"actual explicit V8 evidence/report not V7 relabel"): return false
	var evidence: Dictionary=evidence_value
	var controls: Dictionary=_v8_shader_controls()
	if controls.is_empty(): return false
	_check(_numeric_equal(evidence.get("actual_execution"),V8_EXECUTION_EXPECTED) and _numeric_equal(report.get("actual_v8_execution"),V8_EXECUTION_EXPECTED),"exact current and actually inherited executor identities")
	for role: String in V8_EXECUTION_EXPECTED:
		var row: Dictionary=V8_EXECUTION_EXPECTED[role]
		_check(_bound(row.path,row.sha256) and manifest.get("source_graph",{}).get(row.path)==row.sha256,"independent current executor file/graph "+role)
	var shader_value: Variant=report.get("actual_terrain_shader")
	if not _check(shader_value is Dictionary,"actual saved V8 terrain shader descriptor"): return false
	var shader_row: Dictionary=shader_value
	var shader_path: String=String(shader_row.get("path",""))
	if not _check(shader_path.begins_with(V8_ROOT) and _bound(shader_path,String(shader_row.get("sha256",""))),"actual saved V8 Shader resource bytes"): return false
	var shader: Shader=ResourceLoader.load(shader_path,"Shader",ResourceLoader.CACHE_MODE_IGNORE) as Shader
	_check(shader!=null and shader.code==controls.terrain,"saved actual V8 terrain code exact independently reconstructed shader")
	shader=null
	var materials_value: Variant=evidence.get("actual_materials")
	if not _check(materials_value is Array and materials_value.size()==5,"initial+both worlds terrain3/water2 actual material record count"): return false
	var terrain_count: int=0
	var water_count: int=0
	for value: Variant in materials_value:
		if not _check(value is Dictionary,"typed actual V8 material record"): continue
		var row: Dictionary=value
		var kind: String=String(row.get("kind",""))
		if not _check(kind in ["terrain","water"] and row.get("identity")==V8_MATERIAL_ID and row.get("visual_approved")==false,"exact explicit V8 material kind/identity; metadata not visual approval"): continue
		_check(row.get("original_code_sha256")==controls["original_"+kind+"_sha256"] and row.get("actual_code_sha256")==_sha(String(controls[kind]).to_utf8_buffer()),"original and actual independently reconstructed shader code SHA "+kind)
		if kind=="terrain":
			terrain_count+=1
			_v8_registered_binding(row.get("actual_registered_binding"))
			_check(row.get("geometry_navigation_change")==false and row.get("source_rect")==JSON.parse_string(JSON.stringify(Rect2(Vector2.ZERO,SIZE))),"exact native default-codec full source rectangle; no geometry/nav change claim substituted for RF proof")
		else:
			water_count+=1
			_check(row.get("same_actual_RF_texture")==true and row.get("interpolation")=="unchanged exact8px native triangle; same depth/discard/opacity/waterY","both actual water records disclose unchanged RF interpolation; independent mesh/RF proof remains mandatory")
	_check(terrain_count==3 and water_count==2,"exact both-world terrain/water material record multiplicities")
	var ecology_value: Variant=evidence.get("ecology")
	var boundary_value: Variant=evidence.get("source_boundary")
	if not _check(ecology_value is Dictionary and boundary_value is Dictionary,"explicit added lowgrass/boundary evidence"): return false
	var ecology: Dictionary=ecology_value
	var boundary: Dictionary=boundary_value
	var sites_value: Variant=ecology.get("added_sites")
	if not _check(sites_value is Array and not sites_value.is_empty(),"actual nonempty independent added lowgrass source list"): return false
	var actual: Dictionary={}
	for entry: Dictionary in source.get("objects",[]):
		actual[String(entry.get("id",""))]=entry
	var ids: Dictionary={}
	for site_value: Variant in sites_value:
		if not _check(site_value is Dictionary,"typed lowgrass original source site"): continue
		var site: Dictionary=site_value
		var id: String=String(site.get("id",""))
		if not _check(id.begins_with("v8_marsh_lowgrass_") and not ids.has(id) and actual.has(id),"unique genuinely rendered added lowgrass ID "+id): continue
		ids[id]=true
		var obj: Dictionary=actual[id]
		_check(site.get("kind")=="herb" and obj.get("kind")=="herb" and site.get("pose")==obj.get("pose") and site.get("blocking")==false and obj.get("blocking")==false and _p(obj.get("collision_size_px"))==Vector2.ZERO,"actual added Shrub03 pose/full source binding and nonblocking semantics "+id)
		# Original source uses Vector2 values; compare only same declared codec,
		# never convert saved source coordinates into a new approximate float.
		_check(site.get("source_foot")==JSON.parse_string(JSON.stringify(_p(obj.get("source_XZ_foot_px")))),"exact captured native source-foot codec "+id)
	_check(ecology.get("identity")=="V8_DRY_BANK_OWNERSHIP_AND_ORIGINAL_SHRUB_CLUSTER" and ecology.get("visual_approved")==false and ecology.get("production_approved")==false and ecology.get("all_new_blocking")==false,"honest new original lowgrass identity and no self approval")
	_check(_numeric_equal(boundary,report.get("v8_source_boundary")) and boundary.get("method")=="NATIVE_PREPARED_OLD_AND_NEW_EXACT_IDENTITY_PLUS_DECLARED_NONBLOCKING_ADDITIONS_V1" and boundary.get("new_independent_lowgrass_instances")==ids.size() and boundary.get("new_source_17_points_checked")==ids.size()*17 and boundary.get("original_routes_exact")==27 and boundary.get("original_structures_exact")==5 and boundary.get("navigation_threshold_changed")==false,"exact report/source boundary records; 17 samples do not replace actual Field foot/input tests")
	_check(boundary.get("original_RF_sha256")==catalog.get("res://art/maps/world_map_v15_complete_v5/terrain_height.rf"),"actual retained V5 RF SHA separately disclosed")
	records["v8_material_semantics"]={"scope":"SAVED_TERRAIN_SHADER_AND_REGISTERED_SOURCE_TEXTURES_PLUS_BOUND_BOTH_WORLD_WATER_RECORDS_NOT_FIELD_OR_VISUAL_APPROVAL","terrain":terrain_count,"water":water_count,"added_ids":ids.keys(),"actual_saved_terrain_path":shader_path,"water_saved_resource_available":false,"complete":failures==initial}
	return failures==initial

func _v8_json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not _check(value is Dictionary and not value.is_empty(),"actual nonempty dictionary "+path): return {}
	return value

