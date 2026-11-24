extends "res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd"
## NEW v7 context sibling of the frozen original artifact oracle. Four context
## methods below are mechanical copies: only literal root/executed-builder change.
## Original body raw/repeat/crop/PNG/camera/used-index/material/support, deck and
## ecology methods are inherited unchanged. Plane caster proof is additional.
## SOURCE_READY is NOT compilation, Field input, FULL execution or visual approval.
const V7_ROOT: String = "res://art/maps/world_map_v15_complete_v7/"
const V7_SOURCE: String = "res://data/maps/world_map_v15_complete_v7_source.json"
const V7_MANIFEST: String = V7_ROOT + "art_contract.json"
const V7_REPORT: String = V7_ROOT + "whole_actual_capture.json"
const V7_BUILDER: String = "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd"
const ORIGINAL_PARENT_PATH: String = "res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd"
const ORIGINAL_PARENT_SHA: String = "946fcc3f9ba9d1d46b067672bd8bd560e12bc651a96b7096d48d94a5f5f060a9"
const CASTER_PATH: String = "res://tests/helpers/joint_v15_v7_plane_caster_semantic_probe.gd"
const CASTER_SHA: String = "c34a5da6a91a1c2665dd0edd040827651e74639d8531f0a7ec5dd32f6f105b9c"
const CASTER = preload("res://tests/helpers/joint_v15_v7_plane_caster_semantic_probe.gd")
var final_pins: Dictionary = {}

func configure_final_pins(pins: Dictionary) -> void:
	# Configuration is explicit test input, not a source of approval or a lookup
	# of newest artifacts. run retains the exact frozen parent method signature.
	final_pins=pins.duplicate(true)

func _v7_required_paths() -> Array[String]:
	return [V7_SOURCE,V7_MANIFEST,V7_REPORT,V7_BUILDER,V7_ROOT+"terrain_height.rf"]

func _v7_pins_unchanged() -> bool:
	var paths: Array[String]=_v7_required_paths()
	if final_pins.size()!=paths.size(): return false
	var sha_pattern: RegEx=RegEx.create_from_string("^[0-9a-fA-F]{64}$")
	for path: String in paths:
		var value: Variant=final_pins.get(path)
		if not value is String or sha_pattern.search(value)==null or not FileAccess.file_exists(path) or FileAccess.get_sha256(path).to_lower()!=value.to_lower(): return false
	return true

func _validate_v7_context(source: Dictionary,manifest: Dictionary) -> bool:
	var before: int=failures
	_check(FileAccess.get_sha256(ORIGINAL_PARENT_PATH).to_lower()==ORIGINAL_PARENT_SHA and FileAccess.get_sha256(CASTER_PATH).to_lower()==CASTER_SHA,"exact original parent and independent caster implementation bytes, no silent latest code")
	if not _check(_v7_pins_unchanged(),"explicit exact five v7 final paths/current 64hex SHAs; empty/PENDING/unknown/regional reject"): return false
	var current_source: Variant=JSON.parse_string(FileAccess.get_file_as_string(V7_SOURCE))
	var current_manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(V7_MANIFEST))
	_check(current_source is Dictionary and current_manifest is Dictionary and _numeric_equal(source,current_source) and _numeric_equal(manifest,current_manifest),"owner dictionaries exactly match actual frozen v7 JSON; no v6 in-memory relabel")
	var capture: Variant=source.get("capture")
	_check(source.get("art_revision")=="complete_v7_coherent_whole" and source.get("schema_version")==15 and source.get("world_size")==[12288,8192] and capture is Dictionary and capture.get("capture_protocol")==PROTOCOL and manifest.get("art_revision")=="complete_v7_coherent_whole" and manifest.get("source_contract_path")==V7_SOURCE,"actual coordinate15 v7 whole source/M authority")
	records["v7_context"]={"pins":final_pins.duplicate(true),"parent_path":ORIGINAL_PARENT_PATH,"parent_sha256":ORIGINAL_PARENT_SHA,"caster_path":CASTER_PATH,"caster_sha256":CASTER_SHA,"original_prototype_same_model_boolean_scope":"FROZEN_ORIGINAL_BODY_AND_ORIGINAL_NATIVE_CASTER_PROVENANCE_ONLY_NOT_NEW_PLANE_PROOF","complete":failures==before,"visual_approved":false}
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
		if not _check(raw_path.begins_with(V7_ROOT) and path.begins_with(V7_ROOT) and raw_path!=path and String(r.get("raw_sha256","")).length()==64 and String(r.get("sha256","")).length()==64 and _bound(raw_path,String(r.get("raw_sha256",""))) and _bound(path,String(r.get("sha256",""))),"actual raw/logical PNG bytes bound, not metadata-only "+label): continue
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
	if not _check(binding is Dictionary and binding.get("path")==V7_ROOT+"whole_actual_capture.json" and String(binding.get("sha256","")).length()==64 and _bound(String(binding.get("path","")),String(binding.get("sha256",""))),"new FULL whole report current SHA"): return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(binding.path))
	if not _check(data is Dictionary,"actual whole report dictionary"): return
	whole_capture=data
	if not _check(whole_capture.get("capture_protocol")==PROTOCOL and whole_capture.get("scope")=="FULL64_112SEAMS_NEW_PROTOCOL_NOT_FORMAL_APPROVED" and whole_capture.get("status")=="FULL64_112SEAMS_NEW_PROTOCOL_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_REVIEW" and whole_capture.get("chunk_count_required")==64 and whole_capture.get("seam_count_required")==112 and whole_capture.get("input_hashes_unchanged_after")==true and whole_capture.get("no_legacy_frustum_seam_pass_claim")==true and whole_capture.get("whole_cpu_image_requested")==false and whole_capture.get("whole_cpu_image_allowed")==false and whole_capture.get("maximum_CPU_ROI_pixels")==ROI_CAP,"FULL protocol/scope/64+112 with exact CPU ceiling; bounded pilot is not FULL"): return
	var expected_budget: Dictionary={"previous_pilot_pixels":8388608,"maximum_pixels":8404992,"maximum_native_canvas":[3456,2432],"logical_tile":[1536,1024],"logical_halo_px":96,"ssaa_scale":2,"additional_pixels":16384,"additional_RGBA_bytes":65536,"whole_CPU_Image_allowed":false}
	_check(_numeric_equal(whole_capture.get("CPU_ROI_budget"),expected_budget),"new FULL explicit memory delta, not silently relabelled pilot cap")
	var executed: Variant=whole_capture.get("executed_builder")
	var authorization: Variant=whole_capture.get("authorization")
	if not _check(executed is Dictionary and executed.get("path")=="res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd" and String(executed.get("sha256","")).length()==64 and _bound(executed.path,String(executed.get("sha256",""))) and authorization is Dictionary and String(authorization.get("sha256","")).length()==64 and _bound(String(authorization.get("path","")),String(authorization.get("sha256",""))),"exact executed FULL source and actual authorization bytes"): return
	var auth: Variant=JSON.parse_string(FileAccess.get_file_as_string(authorization.path))
	_check(auth is Dictionary and auth.get("approved")==true and auth.get("scope")==PROTOCOL and auth.get("builder_path")==executed.path and auth.get("builder_sha256")==executed.sha256 and auth.get("output_root")==V7_ROOT and auth.get("allow_full64")==true and auth.get("memory_budget_approved")==true and auth.get("maximum_cpu_roi_pixels")==ROI_CAP and _numeric_equal(auth.get("CPU_ROI_budget"),expected_budget) and auth.get("CPU_whole_402M_Image_allowed")==false,"root FULL authorization explicitly binds actual source/cap and forbids whole CPU Image")
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
		var path: String=V7_ROOT+"chunks/"+id+"_"+role+".png"
		var repeat_path: String=V7_ROOT+"chunks/"+id+"_"+role+"_repeat.png"
		var output: Image=_raw_pair(path,repeat_path,TILE)
		var original: Image=_image(r.path)
		var exact: bool=output!=null and original!=null and c.get(role+"_path")==path and entry.get(role+"_path")==path and c.get(role+"_repeat_path")==repeat_path and c.get("outputs_sha256",{}).get(path)==catalog.get(path) and c.get("outputs_sha256",{}).get(repeat_path)==catalog.get(repeat_path) and output.get_data()==original.get_data() and FileAccess.get_file_as_bytes(path)==FileAccess.get_file_as_bytes(r.path) and FileAccess.get_file_as_bytes(repeat_path)==FileAccess.get_file_as_bytes(r.repeat_path)
		_check(exact,"distinct runtime file is byteexact verified whole ROI copy, no extra capture claim "+id+"/"+role)
		if exact: completed.append(role)
	var visual: Image=_image(V7_ROOT+"chunks/"+id+"_visual.png")
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
	if not _validate_v7_context(source,manifest): return _finish()
	_whole(manifest)
	if not whole_complete: return _finish()
	var rf: String=V7_ROOT+"terrain_height.rf"
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
	_check(_v7_pins_unchanged(),"all five final v7 source/artifact inputs unchanged after inherited body/deck/ecology and independent caster reads")
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
	records["v7_saved_casters"]=caster_result.duplicate(true)
	_check(bool(phase.call("_write_json","actual_v7_saved_caster_semantics.json",caster_result)),"separate actual v7 caster evidence checked write/readback; not a FULL/Field/visual verdict")
	probe.call("release")
	probe=null


