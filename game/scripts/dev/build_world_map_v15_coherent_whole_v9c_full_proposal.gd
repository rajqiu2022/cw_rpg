extends "res://scripts/dev/build_world_map_v15_v9c_visual_quality_proposal_retry5.gd"

## NEW complete coordinate15 adapter. Baseline sites are prepared on original RF
## BEFORE the approved derived Float32 RF is installed. No old navigation credit.
## Actual NEW derived RF/mesh/selector are read from ROOT-pinned CPU artifacts;
## v9c runtime copies record exact original/actual GPU paths. Old179 is immutable.
## New full execution requires current two-world regional evidence + root review.
const V9C_FULL_ROOT := "res://art/maps/world_map_v15_complete_v9c/"
const V9C_FULL_SOURCE_JSON := "res://data/maps/world_map_v15_complete_v9c_source.json"
const V9C_FULL_REPORT := V9C_FULL_ROOT+"whole_actual_capture.json"
const V9C_FULL_PROTOCOL := "COHERENT_WHOLE_FIXED_CAMERA_DERIVED_RF_V9C_FULL64_112_V1"
const V9C_FULL_SCOPE := "V9C_FULL64_112SEAMS_DERIVED_RF_NEW_PROTOCOL_NOT_FORMAL_APPROVED"
const V9C_FULL_STATUS := "V9C_FULL64_112SEAMS_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_FIELD_REVIEW"
const V9C_REGIONAL_PATH := "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_regional_proposal.gd"
const V9C_REGIONAL_ROOT := "res://build/world_map_v15_coherent_whole_v9c_regional/v9d_broad_soft/"
const V9C_REGIONAL_SCOPE := "V9C_TWO_FRESH_WHOLE_WORLDS_SIX_REGIONAL_ROIS_NOT_FULL_OR_FIELD"
const V9C_REGIONAL_STATUS := "V9C_REGIONAL_TWO_WORLD_FIVE_ROLE_REPEAT_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_NOT_FULL"
const V9C_LIMITED_PARENT := "res://scripts/dev/build_world_map_v15_v9c_visual_quality_proposal_retry5.gd"
const V9C_LIMITED_PARENT_SHA := "27a2826b93453dc4b4d139b775a6c907a048996f758f87b983769648ec3e5596"
const V9C_FULL_PINS := {
 V9C_LIMITED_PARENT:V9C_LIMITED_PARENT_SHA,
 "res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_ecology_source.gd":"9599af1cd080f0b32c90ff99158c7451b74cc3a82b6eea0fcbf30fa7782fb872",
 "res://scripts/dev/world_map_v15_v9d_material_quality_proposal_surface.gd":"4bb8890a6142d5d23931c949243d19f9754cf47642e62080de7e18f7f2546854",
 "res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v6.gd":"80302ec86f3fb60499602893b34c5fc321cd8877dbc27d1000bb9fb39766427e"
}
var v9c_regional_mode: bool=false
var v9c_attached_material_creations: Array[Dictionary]=[]
var v9c_prepared_native_routes: Array[Dictionary]=[]
var v9c_prepared_native_rivers: Array[Dictionary]=[]
var v9c_baseline_prepared_site_signature: String=""

func _run() -> void:
	v7_art_root = V9C_FULL_ROOT
	var args: PackedStringArray = OS.get_cmdline_user_args()
	pilot_output = "res://build/world_map_v15_coherent_whole_v9c_full/%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	failure_output = pilot_output
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pilot_output))
	if "--coherent-whole-v9c-full" not in args or DisplayServer.get_name() == "headless":
		error = "NEW FULL explicit GPU authorization required; default/headless/pilot invocation refuses."
		await _pilot_finish(false)
		return
	for arg: String in args:
		if arg.begins_with("--authorization="): v7_auth_path = arg.trim_prefix("--authorization=")
	if not _pilot_authorized(v7_auth_path):
		await _pilot_finish(false)
		return
	# Never overwrite previous current/failed candidates. Root archives them.
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(V9C_FULL_ROOT)) or FileAccess.file_exists(V9C_FULL_SOURCE_JSON):
		error = "NEW v9c root/source JSON must be absent before capture; root recoverable archive required."
		await _pilot_finish(false)
		return
	for folder: String in ["", "capture/", "entities/", "prototypes/", "chunks/", "seams/", "ecology/", "entities/chunks/"]:
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(V9C_FULL_ROOT + folder)) != OK:
			error = "Cannot create NEW v9c artifact directory."
			await _pilot_finish(false)
			return
	v7_started = true
	pilot_output = V9C_FULL_ROOT + "capture/"
	pilot_result = {"schema_version": 1, "coordinate_version": 15, "capture_protocol": V9C_FULL_PROTOCOL, "scope": V9C_FULL_SCOPE, "status": "BUILD_IN_PROGRESS", "production_approved": false, "visual_approved": false, "engine_pid": OS.get_process_id(), "executed_builder": {"path": get_script().resource_path, "sha256": FileAccess.get_sha256(get_script().resource_path)}, "authorization": {"path": v7_auth_path, "sha256": FileAccess.get_sha256(v7_auth_path)}, "cached_inputs_sha256": pilot_inputs, "whole_cpu_image_requested": false, "whole_cpu_image_allowed": false, "maximum_CPU_ROI_pixels": V7_MAX_CPU_ROI_PIXELS, "CPU_ROI_budget": V7_CPU_ROI_BUDGET, "no_legacy_frustum_seam_pass_claim": true, "worlds": {}, "comparisons": {}, "chunk_count_required": 64, "seam_count_required": 112}
	pilot_memory_history = _pilot_square_history()
	pilot_result["actual_memory_history"] = pilot_memory_history
	if not bool(pilot_memory_history.get("valid", false)) or not _load_pilot_inputs() or not _full_prepare_semantics():
		if error.is_empty(): error = "Strict history/cache/authoring binding failed before FULL allocation."
		await _pilot_finish(false)
		return
	for path: String in pilot_inputs:
		full_catalog[path] = pilot_inputs[path]
		full_graph[path] = pilot_inputs[path]
	if not _full_register_literal_inputs(get_script().resource_path, {}) or not _v7_copy_geometry() or not _v7_copy_prototypes() or not _full_export_compounds():
		await _pilot_finish(false)
		return
	if not _full_export_native_instances() or not _v7_measure_coverage() or not await _full_export_structures():
		await _pilot_finish(false)
		return
	for identity: String in ["primary", "reference"]:
		print("V9C_FULL_WORLD_BEGIN ", identity, " ", Time.get_ticks_usec())
		var measured: Dictionary = await _pilot_capture_world(identity)
		if measured.is_empty():
			await _pilot_finish(false)
			return
		pilot_result["worlds"][identity] = measured
		print("V9C_FULL_WORLD_RELEASED ", identity, " ", Time.get_ticks_usec())
	if not _pilot_compare() or not _v7_export_chunks_and_refs() or not _v7_actual_routes_and_doors():
		await _pilot_finish(false)
		return
	for path: String in pilot_inputs:
		if FileAccess.get_sha256(path).to_lower() != String(pilot_inputs[path]).to_lower():
			error = "Frozen input changed during FULL: " + path
			await _pilot_finish(false)
			return
	pilot_result["input_hashes_unchanged_after"] = true
	if not _v9c_final_revision_evidence():
		await _pilot_finish(false)
		return
	pilot_result["status"] = V9C_FULL_STATUS
	if not _write_json(V9C_FULL_REPORT, pilot_result):
		await _pilot_finish(false)
		return
	full_catalog[V9C_FULL_REPORT] = FileAccess.get_sha256(V9C_FULL_REPORT)
	full_graph[V9C_FULL_REPORT] = full_catalog[V9C_FULL_REPORT]
	_full_register_paths(pilot_result)
	_full_register_paths(v7_auth_path)
	if not _full_assemble_contract():
		await _pilot_finish(false)
		return
	await _pilot_finish(true)

func _pilot_authorized(path: String) -> bool:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary:
		error="Missing independent ROOT V9C authorization."
		return false
	pilot_auth=value
	if pilot_auth.get("approved",false)!=true or pilot_auth.get("scope")!=(V9C_REGIONAL_SCOPE if v9c_regional_mode else V9C_FULL_PROTOCOL) or pilot_auth.get("builder_path")!=get_script().resource_path or String(pilot_auth.get("builder_sha256","")).to_lower()!=FileAccess.get_sha256(get_script().resource_path).to_lower() or pilot_auth.get("allow_full64")!=(not v9c_regional_mode) or (not v9c_plan_only and pilot_auth.get("memory_budget_approved",false)!=true):
		error="Exact V9C scope/builder/memory approval absent; no allocation."
		return false
	if not _v7_budget_exact(pilot_auth.get("CPU_ROI_budget")) or int(pilot_auth.get("maximum_CPU_ROI_pixels",0))!=V7_MAX_CPU_ROI_PIXELS or not pilot_auth.get("input_sha256") is Dictionary:
		error="Exact bounded ROI budget/input catalog absent."
		return false
	pilot_inputs=pilot_auth["input_sha256"]
	var required: Array=[CACHE_ROOT+"terrain_height.rf",CACHE_ROOT+"terrain_mesh.res",CACHE_ROOT+"source_topology.png",CACHE_ROOT+"chunks/r0_c0_actual_deck_support_mesh.res",TRANSPORT_PATH,SQUARE_RESULT,SQUARE_PNG,SQUARE_REPEAT,V9C_BASE_MANIFEST,V9C_BASE_SOURCE,get_script().resource_path]
	required.append("res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_ecology_source.gd")
	required.append("res://scripts/dev/world_map_v15_v9d_material_quality_proposal_surface.gd")
	required.append("res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v6.gd")
	for p: String in V9C_FULL_PINS: required.append(p)
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
	for p: String in V9C_FULL_PINS:
		if FileAccess.get_sha256(p).to_lower()!=V9C_FULL_PINS[p]:
			error="Actual NEW V9C adapter dependency differs "+p
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
	if not v9c_regional_mode:
		if pilot_auth.get("output_root")!=V9C_FULL_ROOT or pilot_auth.get("source_json_path")!=V9C_FULL_SOURCE_JSON or not _v9c_regional_approval_error().is_empty(): return false
	return true

func _v7_copy_geometry() -> bool:
	var copies: Array[Dictionary] = []
	for pair: Array in [["terrain_height.rf", "terrain_height.rf"], ["terrain_mesh.res", "terrain_mesh.res"], ["source_topology.png", "source_topology.png"], ["capture/terrain_shader.gdshader", "capture/terrain_shader.gdshader"], ["chunks/r0_c0_actual_deck_support_mesh.res", "deck_support_mesh.res"]]:
		var original: String = CACHE_ROOT + pair[0]
		if pair[0]=="terrain_height.rf": original=v9c_geometry_result["artifacts"]["height_rf"]["path"]
		if pair[0]=="terrain_mesh.res": original=v9c_geometry_result["artifacts"]["terrain_mesh"]["path"]
		if pair[0]=="source_topology.png": original=v9c_geometry_result["artifacts"]["source_topology"]["path"]
		if pair[0]=="capture/terrain_shader.gdshader": original=pilot_result["actual_terrain_shader"]["path"]
		var copy: String = v7_art_root + pair[1]
		if not _full_copy_exact(original, copy): return false
		copies.append({"original_path": original, "original_sha256": FileAccess.get_sha256(original), "copy_path": copy, "copy_sha256": FileAccess.get_sha256(copy), "actual_GPU_input_path": original, "byte_exact_copy": true, "provenance": "NEW actual V9C Shader instance saved before draw; created by exact V9C surface source, not loaded from old shader" if pair[0]=="capture/terrain_shader.gdshader" else ("Unchanged original Y0 deck support" if pair[0].begins_with("chunks/") else "Actual approved NEW derived RF/mesh/selector artifact, not old RF navigation reuse")})
	full_geometry = {"height_grid_shape": _v2i(SOURCE.GRID_SIZE), "height_grid_origin_px": [0, 0], "source_node_spacing_px": SOURCE.GRID_STEP, "height_interpolation": "actual derived Float32 [a,b,c,b,d,c] affine triangles", "selector_cell_rule": "actual entire 2px selector cell intersects both native triangles; bank28/gradient .72 unchanged", "rf_path": v7_art_root + "terrain_height.rf", "rf_sha256": FileAccess.get_sha256(v7_art_root + "terrain_height.rf"), "terrain_mesh_path": v7_art_root + "terrain_mesh.res", "terrain_mesh_sha256": FileAccess.get_sha256(v7_art_root + "terrain_mesh.res"), "source_topology_path": v7_art_root + "source_topology.png", "actual_GPU_RF_input_path": _v9c_artifact_path("height_rf"), "actual_GPU_mesh_input_path": _v9c_artifact_path("terrain_mesh"), "actual_GPU_support_input_path": CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res", "native_binary_msaa_enum": 0, "native_binary_resized": false, "capture_protocol": V9C_FULL_PROTOCOL, "cache_copy_provenance": copies}
	var names: Array[String] = ["height_rf_copy", "runtime_mesh_copy", "source_topology_copy", "runtime_shader_copy", "deck_support_mesh_copy"]
	for index in copies.size():
		var entry: Dictionary = copies[index]
		full_geometry[names[index]] = {"path": entry["copy_path"], "sha256": entry["copy_sha256"], "original_path": entry["original_path"], "original_sha256": entry["original_sha256"], "actual_GPU_input_path": entry["actual_GPU_input_path"]}
	pilot_result["actual_RF"] = {"path": _v9c_artifact_path("height_rf"), "sha256": FileAccess.get_sha256(_v9c_artifact_path("height_rf"))}
	pilot_result["authoritative_global_mesh"] = {"path": _v9c_artifact_path("terrain_mesh"), "sha256": FileAccess.get_sha256(_v9c_artifact_path("terrain_mesh"))}
	full_geometry["derivation_report"]=v9c_geometry_result["artifacts"]["derivation_report"].duplicate(true)
	full_geometry["derivation_audit"]=v9c_geometry_result["audit"].duplicate(true)
	full_geometry["navigation_authority_unchanged"]=false
	if not _write_json(v7_art_root + "geometry.json", full_geometry): return false
	_full_register_paths(v7_art_root + "geometry.json")
	_full_register_paths(pilot_result["cache_provenance"])
	return true

func _v7_copy_prototypes() -> bool:
	for key: String in native_prototype_cache:
		var proto: Dictionary = native_prototype_cache[key]
		var original: Dictionary = proto["record"].duplicate(true)
		var old_metadata: String = CACHE_ROOT + "prototypes/native_" + key + ".json"
		var original_copy: String = v7_art_root + "prototypes/native_" + key + "_original_metadata.json"
		if not _full_copy_exact(old_metadata, original_copy): return false
		var revised: Dictionary = _v7_rebind_prototype_paths(original)
		if revised.is_empty() or not error.is_empty(): return false
		revised["metadata_path"] = v7_art_root + "prototypes/native_" + key + ".json"
		revised["sourcebody_capture_origin"] = {"scope": "BYTE_EXACT_FROZEN_SAME_POSE_CACHE_REUSE_NOT_NEW_BODY_RENDER", "original_metadata_path": old_metadata, "original_metadata_sha256": FileAccess.get_sha256(old_metadata), "original_metadata_copy_path": original_copy, "actual_GPU_loaded_mesh_path": original["actual_draw_mesh_path"], "actual_GPU_loaded_mesh_sha256": original["actual_draw_mesh_sha256"], "new_mesh_artifact_is_exact_copy": true}
		revised["alpha_unpremultiply_epsilon"] = .00001
		if not _write_json(revised["metadata_path"], revised): return false
		proto["record"] = revised
		native_prototype_cache[key] = proto
		_full_register_paths(original)
		_full_register_paths(revised)
	return true

func _v7_capture_record(world_id: String, window_id: String) -> Dictionary:
	var world: Dictionary = pilot_result["worlds"][world_id]
	var roles: Dictionary = {}
	for role: String in ROLE_NAMES: roles[role] = world["roles"][role]["windows"][window_id].duplicate(true)
	var result: Dictionary = {"capture_protocol": V9C_FULL_PROTOCOL, "capture_role": world_id, "window_id": window_id, "roles": roles, "actual_camera": world["camera"], "actual_native_canvas": world["camera"]["whole_visual_native_canvas"], "actual_logical_canvas": roles["visual"]["logical_rect_px"].slice(2, 4), "actual_whole_GPU_input_canvas": world["camera"]["whole_visual_native_canvas"], "actual_receiver_coverage": world["coverage"], "global_terrain_mesh_path": _v9c_artifact_path("terrain_mesh"), "global_terrain_mesh_sha256": FileAccess.get_sha256(_v9c_artifact_path("terrain_mesh")), "height_rf_path": _v9c_artifact_path("height_rf"), "height_rf_sha256": FileAccess.get_sha256(_v9c_artifact_path("height_rf")), "actual_deck_mesh_path": CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res", "actual_deck_mesh_sha256": pilot_inputs[CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res"], "logical_overscan": HALO, "logical_rect_px": roles["visual"]["logical_rect_px"], "CPU_ROI_budget": V7_CPU_ROI_BUDGET, "whole_capture_report_path": V9C_FULL_REPORT, "binary_MSAA": 0, "binary_resized": false, "whole_CPU_Image_requested": false}
	return result

func _v7_export_chunks_and_refs() -> bool:
	for authored: Dictionary in SOURCE.chunks():
		var id: String = authored["id"]
		var chunk: Dictionary = authored.duplicate(true)
		var capture: Dictionary = _v7_capture_record("primary", id)
		for role: String in ROLE_NAMES:
			var record: Dictionary = capture["roles"][role]
			var destination: String = V9C_FULL_ROOT + "chunks/" + id + "_" + role + ".png"
			var repeat: String = V9C_FULL_ROOT + "chunks/" + id + "_" + role + "_repeat.png"
			if not _full_copy_exact(record["path"], destination) or not _full_copy_exact(record["repeat_path"], repeat): return false
			chunk[role + "_path"] = destination
			if not capture.has("outputs_sha256"): capture["outputs_sha256"] = {}
			capture["outputs_sha256"][destination] = FileAccess.get_sha256(destination)
			capture["outputs_sha256"][repeat] = FileAccess.get_sha256(repeat)
			capture[role + "_path"] = destination
			capture[role + "_repeat_path"] = repeat
			_full_register_paths(record)
		var rect := Rect2(_rect_from_array(authored["logical_rect_px"]))
		var on: Image = Image.load_from_file(chunk["visual_path"])
		var off: Image = Image.load_from_file(chunk["shadow_off_path"])
		var shadow: Dictionary = _full_ground_evidence(id, rect, on, off, V9C_FULL_ROOT + "chunks/")
		if shadow.is_empty(): return false
		chunk["ground_shadow"] = shadow
		chunk["capture"] = capture
		full_chunks.append(chunk)
	for row in 8:
		for col in 7:
			var seam: Dictionary = _v7_reference_edge(_edge(row, col, true))
			if seam.is_empty(): return false
			full_seams.append(seam)
	for row in 7:
		for col in 8:
			var seam: Dictionary = _v7_reference_edge(_edge(row, col, false))
			if seam.is_empty(): return false
			full_seams.append(seam)
	if full_chunks.size() != 64 or full_seams.size() != 112:
		error = "Incomplete actual64/112 output matrix."
		return false
	return true

func _v7_reference_edge(edge: Dictionary) -> Dictionary:
	var id: String = edge["id"]
	var capture: Dictionary = _v7_capture_record("reference", id)
	var differences: Dictionary = {}
	for role: String in ROLE_NAMES:
		var record: Dictionary = capture["roles"][role]
		var destination: String = V9C_FULL_ROOT + "seams/" + id + "_" + role + ".png"
		var repeat: String = V9C_FULL_ROOT + "seams/" + id + "_" + role + "_repeat.png"
		if not _full_copy_exact(record["path"], destination) or not _full_copy_exact(record["repeat_path"], repeat): return {}
		capture[role + "_path"] = destination
		capture[role + "_repeat_path"] = repeat
		if not capture.has("outputs_sha256"): capture["outputs_sha256"] = {}
		capture["outputs_sha256"][destination] = FileAccess.get_sha256(destination)
		capture["outputs_sha256"][repeat] = FileAccess.get_sha256(repeat)
		_full_register_paths(record)
		var left: Image = Image.load_from_file(V9C_FULL_ROOT + "chunks/" + String(edge["from"]) + "_" + role + ".png")
		var right: Image = Image.load_from_file(V9C_FULL_ROOT + "chunks/" + String(edge["to"]) + "_" + role + ".png")
		var reference: Image = Image.load_from_file(destination)
		if left == null or right == null or reference == null:
			error = "Missing genuine reference or primary chunk."
			return {}
		var joined: Image = Image.create(reference.get_width(), reference.get_height(), false, Image.FORMAT_RGBA8)
		if edge["vertical"]:
			joined.blit_rect(left, Rect2i(SOURCE.TILE.x - 16, 0, 16, SOURCE.TILE.y), Vector2i.ZERO)
			joined.blit_rect(right, Rect2i(0, 0, 16, SOURCE.TILE.y), Vector2i(16, 0))
		else:
			joined.blit_rect(left, Rect2i(0, SOURCE.TILE.y - 16, SOURCE.TILE.x, 16), Vector2i.ZERO)
			joined.blit_rect(right, Rect2i(0, 0, SOURCE.TILE.x, 16), Vector2i(0, 16))
		differences[role] = _pilot_difference(joined, reference)
		if not bool(differences[role]["byte_exact"]):
			pilot_result["failed_reference_seam"] = {"id": id, "differences": differences, "capture": capture}
			error = "FULL genuine second-world reference does not equal primary chunks: " + id + "/" + role
			return {}
	var walk: Image = Image.load_from_file(capture["walk_path"])
	var rect: Rect2 = edge["rect"]
	var positive: Array = []
	var negative: Array = []
	for n in range(12, int(rect.size.y if edge["vertical"] else rect.size.x) - 12, 4):
		var center: Vector2 = rect.position + (Vector2(16, n) if edge["vertical"] else Vector2(n, 16))
		var clear := true
		var bad := Vector2(INF, INF)
		for side in [-4., 0., 4.]:
			for offset: Vector2 in source.foot_offsets():
				var foot: Vector2 = center + (Vector2(side, 0) if edge["vertical"] else Vector2(0, side)) + offset
				var local := Vector2i((foot - rect.position).round())
				if local.x < 0 or local.y < 0 or local.x >= walk.get_width() or local.y >= walk.get_height() or walk.get_pixelv(local).r != 1.:
					clear = false
					if bad.x == INF and local.x >= 0 and local.y >= 0 and local.x < walk.get_width() and local.y < walk.get_height(): bad = Vector2(local) + rect.position
		if clear and positive.size() < 12:
			positive.append({"from_px": [center.x - 4 if edge["vertical"] else center.x, center.y if edge["vertical"] else center.y - 4], "to_px": [center.x + 4 if edge["vertical"] else center.x, center.y if edge["vertical"] else center.y + 4], "basis": "actual second whole-world native walk, all17 shoes at -4/0/+4; source solids checked separately by Field"})
		elif not clear and bad.x != INF and negative.size() < 12:
			negative.append({"foot_px": [bad.x, bad.y], "crossing_center_px": [center.x, center.y], "basis": "actual second whole-world native black walk pixel, no authoring-label guess"})
	if positive.is_empty() and negative.is_empty():
		error = "No actual completefoot seam positive or black negative."
		return {}
	var result: Dictionary = edge.duplicate()
	result.erase("rect")
	result["logical_rect_px"] = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	result["classification"] = "open" if not positive.is_empty() else "blocked"
	result["projected_witnesses"] = positive if not positive.is_empty() else negative
	result["independent_reference_capture"] = capture
	result["comparison_status"] = "ACTUAL_ALL_FIVE_ROLE_RGBA_EXACT"
	result["compared_byte_difference"] = differences
	return result

func _full_sample_walk(p: Vector2) -> bool:
	var pixel := Vector2i(p.round())
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= SOURCE.SIZE.x or pixel.y >= SOURCE.SIZE.y: return false
	var col: int = pixel.x / SOURCE.TILE.x
	var row: int = pixel.y / SOURCE.TILE.y
	var id: String = "r%d_c%d" % [row, col]
	if not v7_walk_cache.has(id):
		if v7_walk_cache.size() >= 4: v7_walk_cache.erase(v7_walk_cache.keys()[0])
		var image: Image = Image.load_from_file(V9C_FULL_ROOT + "chunks/" + id + "_walk.png")
		if image == null or image.get_size() != SOURCE.TILE: return false
		v7_walk_cache[id] = image
	var image: Image = v7_walk_cache[id]
	return image.get_pixel(pixel.x - col * SOURCE.TILE.x, pixel.y - row * SOURCE.TILE.y) == Color.WHITE

func _v7_actual_routes_and_doors() -> bool:
	var failures: Array = []
	var centers := 0
	for route: Dictionary in source.routes:
		for segment in range(route["points"].size() - 1):
			var a: Vector2 = route["points"][segment]
			var b: Vector2 = route["points"][segment + 1]
			var steps: int = maxi(1, ceili(a.distance_to(b) / 4.))
			for index in range(steps + 1):
				var source_point: Vector2 = a.lerp(b, float(index) / steps)
				var projected: Vector2 = source.project_source(source_point)
				for structure: Dictionary in source.structures:
					if Geometry2D.is_point_in_polygon(source_point, structure["source_deck_polygon"]): projected = source_point
				centers += 1
				for offset: Vector2 in source.foot_offsets():
					if not _v7_actor_point_clear(projected + offset):
						if failures.size() < 1024: failures.append({"route_id": route["id"], "source_px": [source_point.x, source_point.y], "projected_px": [projected.x, projected.y], "shoe_offset": [offset.x, offset.y]})
						break
	for portal: Dictionary in full_portals:
		var path: Array = portal["passage_path_px"]
		for segment in range(path.size() - 1):
			var a := Vector2(path[segment][0], path[segment][1])
			var b := Vector2(path[segment + 1][0], path[segment + 1][1])
			var steps: int = maxi(1, ceili(a.distance_to(b) / 4.))
			for index in range(steps + 1):
				var projected: Vector2 = a.lerp(b, float(index) / steps)
				centers += 1
				for offset: Vector2 in source.foot_offsets():
					if not _v7_actor_point_clear(projected + offset):
						if failures.size() < 1024: failures.append({"portal_id": portal["id"], "projected_px": [projected.x, projected.y], "shoe_offset": [offset.x, offset.y]})
						break
	var record: Dictionary = {"scope": "ACTUAL_CAPTURED_NATIVE_WALK_AND_SOURCE_PHYSICS_NOT_FIELD_INPUT", "passed": failures.is_empty(), "centers": centers, "route_count": source.routes.size(), "portal_count": full_portals.size(), "all17_offsets": _v7_vec2_list(source.foot_offsets()), "failures": failures, "threshold_waiver": false, "physical_margin_px": 0}
	var path: String = V9C_FULL_ROOT + "capture/actual_routes_and_doors.json"
	if not _write_json(path, record): return false
	_full_register_paths(path)
	pilot_result["actual_route_and_door_audit"] = {"path": path, "sha256": FileAccess.get_sha256(path), "passed": failures.is_empty(), "centers": centers}
	if not failures.is_empty():
		error = "Actual fullfoot routes/doors disagree with captured native/nav/solids; no ART ready."
		return false
	return true

func _full_overview_and_door_reviews() -> bool:
	# No whole 402M or 100M CPU image. 6.3M overview assembled from bounded
	# actual ground+independent-object tile compositions, released one by one.
	var overview: Image = Image.create(3072, 2048, false, Image.FORMAT_RGBA8)
	for chunk: Dictionary in full_chunks:
		var rect := Rect2i(int(chunk["col"]) * SOURCE.TILE.x, int(chunk["row"]) * SOURCE.TILE.y, SOURCE.TILE.x, SOURCE.TILE.y)
		var scene: Image = _v7_composite_roi(rect)
		if scene == null: return false
		scene.resize(384, 256, Image.INTERPOLATE_LANCZOS)
		overview.blit_rect(scene, Rect2i(0, 0, 384, 256), Vector2i(int(chunk["col"]) * 384, int(chunk["row"]) * 256))
	if overview.save_png(V9C_FULL_ROOT + "overview.png") != OK:
		error = "Bounded overview save failed."
		return false
	_full_register_paths(V9C_FULL_ROOT + "overview.png")
	for portal: Dictionary in full_portals:
		var foot := Vector2(portal["door_foot_px"][0], portal["door_foot_px"][1])
		var rect := Rect2i(Vector2i((foot - Vector2(380, 400)).round()), Vector2i(760, 500)).intersection(Rect2i(Vector2i.ZERO, SOURCE.SIZE))
		var scene: Image = _v7_composite_roi(rect)
		if scene == null: return false
		var path: String = V9C_FULL_ROOT + "capture/doorstep_" + String(portal["id"]) + "_review.png"
		if scene.save_png(path) != OK: return false
		_full_register_paths(path)
		portal["doorstep_review_image_path"] = path
		portal["doorstep_review_image_sha256"] = FileAccess.get_sha256(path)
		portal["doorstep_review_image_scope"] = "Bounded actual whole native ground + own-alpha feet-ordered runtime objects; NOT Field input approval"
	for habitat: Dictionary in SOURCE.HABITATS:
		var center: Vector2 = source.project_source(habitat["center"])
		var position := Vector2i((center - Vector2(640, 512)).round())
		position.x = clampi(position.x, 0, SOURCE.SIZE.x - 1280)
		position.y = clampi(position.y, 0, SOURCE.SIZE.y - 1024)
		var rect := Rect2i(position, Vector2i(1280, 1024))
		var scene: Image = _v7_composite_roi(rect)
		if scene == null: return false
		var path: String = V9C_FULL_ROOT + "ecology/" + String(habitat["id"]) + "_scene_components.png"
		if scene.save_png(path) != OK: return false
		_full_register_paths(path)
		var authorities: Array = []
		for chunk: Dictionary in full_chunks:
			if rect.intersects(Rect2i(chunk["logical_rect_px"][0], chunk["logical_rect_px"][1], SOURCE.TILE.x, SOURCE.TILE.y)):
				authorities.append({"id": chunk["id"], "visual_path": chunk["visual_path"], "visual_sha256": FileAccess.get_sha256(chunk["visual_path"]), "capture_window_id": chunk["id"], "capture_role": "primary"})
		var evidence: Dictionary = {"scene_components_path": path, "scene_components_sha256": FileAccess.get_sha256(path), "logical_rect_px": _recti(rect), "scope": "BOUNDED_CPU_COMPOSITE_ACTUAL_WHOLE_CHUNK_GROUND_AND_INDEPENDENT_Y_BODIES_NOT_EXTRA_GPU_CAPTURE", "actual_whole_ground_authorities": authorities, "whole_report_path": V9C_FULL_REPORT, "no_additional_GPU_window_claim": true}
		if not _write_json(V9C_FULL_ROOT + "ecology/" + String(habitat["id"]) + ".json", evidence): return false
		_full_register_paths(V9C_FULL_ROOT + "ecology/" + String(habitat["id"]) + ".json")
	return _v7_runtime_entity_groups()

func _v7_runtime_entity_groups() -> bool:
	for object: Dictionary in full_objects:
		var path: String = v7_art_root + "entities/" + String(object["id"]) + ".json"
		object["metadata_path"] = path
		if not _write_json(path, object): return false
		full_catalog[path] = FileAccess.get_sha256(path)
	for chunk: Dictionary in full_chunks:
		var rect := Rect2(float(chunk["col"]) * SOURCE.TILE.x, float(chunk["row"]) * SOURCE.TILE.y, SOURCE.TILE.x, SOURCE.TILE.y)
		var ids: Array = []
		var entries: Array = []
		for object: Dictionary in full_objects:
			var size := Vector2(object["render_size_px"][0], object["render_size_px"][1])
			var center := Vector2(object["pos"][0] * SOURCE.SIZE.x, object["pos"][1] * SOURCE.SIZE.y)
			if not Rect2(center - size * .5, size).grow(2.).intersects(rect): continue
			ids.append(object["id"])
			entries.append({"id": object["id"], "metadata_path": object["metadata_path"], "metadata_sha256": full_catalog[object["metadata_path"]], "texture": object["texture"], "texture_sha256": FileAccess.get_sha256(object["texture"]), "coordinate_space": "global world logical pixels; not relocated per tile"})
		var path: String = V9C_FULL_ROOT + "entities/chunks/" + String(chunk["id"]) + ".json"
		if not _write_json(path, {"schema_version": 15, "chunk_id": chunk["id"], "logical_rect_px": chunk["logical_rect_px"], "object_ids": ids, "entries": entries, "source_objects_are_independent": true}): return false
		_full_register_paths(path)
		chunk["runtime_entity_group"] = {"path": path, "sha256": FileAccess.get_sha256(path), "object_ids": ids}
	return true

func _full_register_literal_inputs(path: String, visited: Dictionary) -> bool:
	if visited.has(path): return true
	visited[path] = true
	if not FileAccess.file_exists(path):
		error = "Missing exact NEW FULL source input " + path
		return false
	full_catalog[path] = FileAccess.get_sha256(path)
	full_graph[path] = full_catalog[path]
	if path.get_extension() == "gltf":
		var gltf: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not gltf is Dictionary:
			error = "Invalid native GLTF dependency graph " + path
			return false
		for section: String in ["buffers", "images"]:
			for entry: Dictionary in gltf.get(section, []):
				var uri: String = entry.get("uri", "")
				if uri.is_empty() or uri.begins_with("data:"): continue
				if not _full_register_literal_inputs(path.get_base_dir().path_join(uri.uri_decode()), visited): return false
		return true
	if path.get_extension() != "gd": return true
	var regex := RegEx.new()
	if regex.compile("['\"](res://[^'\"]+)['\"]") != OK:
		error = "Cannot close NEW FULL source dependency graph."
		return false
	for match in regex.search_all(FileAccess.get_file_as_string(path)):
		var dependency: String = match.get_string(1)
		# CF21 is retained as exact historical source, not executed here. Its
		# own generated JSON declaration is not an input to this v7 capture.
		var historical_output: String = "res://data/maps/" + "world_map_v15_complete_v6_source.json"
		if path == V7_CF21_PATH and full_catalog[path].to_lower() == V7_CF21_SHA and dependency == historical_output:
			pilot_result["historical_generated_output_classification"] = {"parent_script": path, "parent_sha256": V7_CF21_SHA, "declared_output": dependency, "role": "GENERATED_OUTPUT_DECLARATION_NOT_CURRENT_INPUT"}
			continue
		# The pinned parent declares its old generated output, not an input to v8.
		var historical_v7_output: String = "res://data/maps/" + "world_map_v15_complete_v7_source.json"
		if path == "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd" and full_catalog[path].to_lower() == "74a7757a43c7ff4e339fa297bf29a0ec7860cf6a70f7508ebd80a418ce18e233" and dependency == historical_v7_output:
			pilot_result["historical_v7_generated_output_classification"] = {"parent_script": path, "parent_sha256": "74a7757a43c7ff4e339fa297bf29a0ec7860cf6a70f7508ebd80a418ce18e233", "declared_output": dependency, "role": "GENERATED_OUTPUT_DECLARATION_NOT_CURRENT_INPUT"}
			continue
		# These are generated outputs, not a phantom pre-existing input. Frozen
		# authoring/capture dependencies remain mandatory and catalog-bound.
		if dependency == V9C_FULL_SOURCE_JSON or dependency.begins_with(V9C_FULL_ROOT) or dependency.begins_with("res://build/") or dependency.begins_with(FULL_ROOT): continue
		if dependency.get_extension() not in ["gd", "gdshader", "gltf", "glb", "res", "obj", "tga", "png", "jpg", "json"]: continue
		if not _full_register_literal_inputs(dependency, visited): return false
	return true

func _full_assemble_contract() -> bool:
	if full_shadow_pixels<=0:
		error="No actual outside-sourcebody shadow evidence; empty exports cannot be READY."
		return false
	var routes: Array=[]
	for route in source.routes:
		var points: Array=[]
		for p: Vector2 in route["points"]:
			var projected: Vector2=source.project_source(p)
			# Authored bridges are worldY0 support, distinct from their wet RF bed.
			for structure in source.structures:
				if Geometry2D.is_point_in_polygon(p,structure["source_deck_polygon"]): projected=p
			points.append([projected.x,projected.y])
		if route["id"] == "portal_bianzhou": points = _v7_pairs(v7_approach_world)
		routes.append({"id":route["id"],"points_px":points,"width_px":float(route["half_width_px"])*2.,"kind":route["kind"]})
	var supports: Array=[]
	for structure in source.structures:
		var polygon: Array=[]
		for p: Vector2 in structure["source_deck_polygon"]: polygon.append([p.x,p.y])
		var source_path: Array=[]
		var projected_path: Array=[]
		for p: Vector2 in structure["source_passage_px"]:
			source_path.append([p.x,p.y])
			var q: Vector2=source.project_source(p)
			if Geometry2D.is_point_in_polygon(p,structure["source_deck_polygon"]): q=p
			projected_path.append([q.x,q.y])
		var support: Dictionary={"id":structure["id"],"kind":"bridge","route_id":structure["route_id"],"river_id":structure["river_id"],"source_deck_polygon":polygon,"projected_deck_polygon_px":polygon,"source_passage_px":source_path,"projected_passage_px":projected_path,"deck_height_m":0.,"actual_wet_bed_m":source.triangle_height(structure["center"]),"actual_deck_mesh_path":full_chunks[0]["capture"]["actual_deck_mesh_path"],"actual_deck_mesh_sha256":full_chunks[0]["capture"]["actual_deck_mesh_sha256"],"mesh_vertex_space":"global world metres","mesh_transform":{"basis_columns":[[1,0,0],[0,1,0],[0,0,1]],"origin":[0,0,0]},"deck_object_id":String(structure["id"])+"_deck","water_negative_probes":[]}
		var center: Vector2=structure["center"]
		var axis: Vector2=structure["axis"]
		for side in [-1.,1.]:
			var negative: Vector2=center+Vector2(-axis.y,axis.x)*(float(structure["half_width_px"])+64.)*side
			if source.triangle_height(negative)<SOURCE.WATER_Y:
				support["water_negative_probes"].append({"source_px":[negative.x,negative.y],"projected_water_px":[negative.x,negative.y-SOURCE.WATER_Y*SOURCE.Z_PPM],"side":side})
			else:
				error="Missing genuine two-sided off-deck wet-bed negative "+String(structure["id"])
				return false
		supports.append(support)
	var ecology: Array=[]
	var profiles: Array[String]=["snow_rock_ridge","western_limestone","northeastern_pine_forest","luoyang_fields","central_meadow","western_forest","southern_bamboo","river_fields","southeastern_marsh"]
	for index in range(9):
		var habitat: Dictionary=SOURCE.HABITATS[index]
		var source_point: Vector2=habitat["center"]
		var point: Vector2=source.project_source(source_point)
		var selector: Dictionary=source.selector_cell_info(source_point)
		var all17 := true
		for offset: Vector2 in source.foot_offsets():
			if not _full_sample_walk(point+offset): all17=false
		ecology.append({"id":habitat["id"],"source_XZ_px":[source_point.x,source_point.y],"projected_px":[point.x,point.y],"profile":profiles[index],"actual_rf_height_m":source.triangle_height(source_point),"native_selector":{"gradient":selector["gradient"],"min_height":selector["min_height"],"min_bank":selector["min_bank"],"walk":selector["walk"]},"walkable":all17,"material_binding":_v7_material_bindings(),"review_evidence_path":V9C_FULL_ROOT+"ecology/"+String(habitat["id"])+".json","review_scope":"BOUNDED_CPU_COMPOSITE_OF_ACTUAL_GLOBAL_CHUNK_CAPTURES_AND_INDEPENDENT_BODIES","scene_components_path":V9C_FULL_ROOT+"ecology/"+String(habitat["id"])+"_scene_components.png","visual_approved":false})
	var camera_path: String=V9C_FULL_ROOT+"capture/camera_contract.json"
	if not _write_json(camera_path, {"capture_protocol": V9C_FULL_PROTOCOL, "whole_capture": true, "local_camera_authority": false, "projection": "orthographic", "logical_pixels_per_meter_x": SOURCE.PPM, "logical_pixels_per_meter_source_z": SOURCE.Z_PPM, "source_world_size_px": _v2i(SOURCE.SIZE), "visual_ssaa_scale": SSAA, "ROI96_halo": HALO, "binary_msaa_enum": 0, "binary_resized": false, "actual_world_cameras": {"primary": pilot_result["worlds"]["primary"]["camera"], "reference": pilot_result["worlds"]["reference"]["camera"]}, "actual_whole_world_receiver_coverage": {"primary": pilot_result["worlds"]["primary"]["coverage"], "reference": pilot_result["worlds"]["reference"]["coverage"]}, "authoring_source": {"path": source.get_script().resource_path, "sha256": FileAccess.get_sha256(source.get_script().resource_path)}, "executed_capture_builder": {"path": get_script().resource_path, "sha256": FileAccess.get_sha256(get_script().resource_path)}, "whole_report_path": V9C_FULL_REPORT, "whole_CPU_Image_allowed": false, "maximum_CPU_ROI_pixels": V7_MAX_CPU_ROI_PIXELS, "CPU_ROI_budget": V7_CPU_ROI_BUDGET}): return false
	full_catalog[camera_path]=FileAccess.get_sha256(camera_path)
	full_graph[camera_path]=full_catalog[camera_path]
	var semantics_path: String=V9C_FULL_ROOT+"landmark_semantics.json"
	if not _write_json(semantics_path,{"schema_version":15,"status":"MEASURED_ACTUAL_SOURCE_NOT_FIELD_APPROVED","landmarks":source.semantics,"source_authoring_path":FULL_FOOTPRINTS,"source_authoring_sha256":FileAccess.get_sha256(FULL_FOOTPRINTS)}): return false
	full_catalog[semantics_path]=FileAccess.get_sha256(semantics_path)
	full_graph[semantics_path]=full_catalog[semantics_path]
	full_catalog[FULL_FOOTPRINTS]=FileAccess.get_sha256(FULL_FOOTPRINTS)
	full_graph[FULL_FOOTPRINTS]=full_catalog[FULL_FOOTPRINTS]
	if not _full_overview_and_door_reviews(): return false
	var source_contract: Dictionary={"schema_version":15,"version":"world_v15","status":"ART_ASSETS_READY","authoring_revision":"complete_v5_geography_v4_WITH_EXPLICIT_V9C_DERIVED_RF","world_size":[SOURCE.SIZE.x,SOURCE.SIZE.y],"tile_size":[SOURCE.TILE.x,SOURCE.TILE.y],"overview_path":V9C_FULL_ROOT+"overview.png","chunks":full_chunks,"seams":full_seams,"objects":full_objects,"portals":full_portals,"core_landmarks":full_core_landmarks,"routes":routes,"structures":supports,"ecology_probes":ecology,"geometry":{"grid_size":[SOURCE.GRID_SIZE.x,SOURCE.GRID_SIZE.y],"grid_step_px":SOURCE.GRID_STEP,"height_rf_path":full_geometry["rf_path"],"height_rf_sha256":full_geometry["rf_sha256"],"terrain_mesh_path":full_geometry["terrain_mesh_path"],"terrain_mesh_sha256":full_geometry["terrain_mesh_sha256"]},"pixel_sampling":"round_world_pixel","physical_navigation_margin_px":0,"visual_approved":false,"production_approved":false}
	source_contract["coordinate_version"] = 15
	source_contract["art_revision"] = "complete_v9c_coherent_whole"
	source_contract["v7_revision_evidence"]={"ecology":source.v7_proposal_contract(),"actual_alpha_union":v7_alpha_union,"actual_plane_casters":v7_plane_records,"bianzhou_projected_world_approach":_v7_pairs(v7_approach_world),"inverse_RF_records":v7_approach_inverse,"scope":"historical source/caster recipe retained, NOT old RF or navigation acceptance"}
	source_contract["v9c_revision_evidence"]=pilot_result["v9c_revision_evidence"].duplicate(true)
	source_contract["old_navigation_credit"]=false
	source_contract["capture"] = {"capture_protocol": V9C_FULL_PROTOCOL, "whole_capture": true, "local_camera_authority": false, "authoring_source": {"path": source.get_script().resource_path, "sha256": FileAccess.get_sha256(source.get_script().resource_path)}, "executed_builder": {"path": get_script().resource_path, "sha256": FileAccess.get_sha256(get_script().resource_path)}, "capture_report": {"path": V9C_FULL_REPORT, "sha256": FileAccess.get_sha256(V9C_FULL_REPORT)}, "authoritative_nav_msaa": 0, "authoritative_nav_resize": false, "CPU_ROI_budget": V7_CPU_ROI_BUDGET, "whole_CPU_Image_allowed": false}
	source_contract["geometry"]["geometry_contract_path"] = v7_art_root + "geometry.json"
	source_contract["geometry"]["geometry_contract_sha256"] = FileAccess.get_sha256(v7_art_root + "geometry.json")
	source_contract["geometry"]["height_grid_shape"] = _v2i(SOURCE.GRID_SIZE)
	source_contract["geometry"]["height_grid_origin_px"] = [0, 0]
	source_contract["geometry"]["source_node_spacing_px"] = SOURCE.GRID_STEP
	source_contract["source_graph"] = full_graph.duplicate(true)
	source_contract["asset_sha256"] = full_catalog.duplicate(true) # Excludes this document itself; manifest binds its final SHA.
	var contract_path: String = V9C_FULL_SOURCE_JSON
	if not _write_json(contract_path,source_contract): return false
	full_catalog[contract_path]=FileAccess.get_sha256(contract_path)
	full_graph[contract_path]=full_catalog[contract_path]
	if not _full_copy_exact(contract_path, V9C_FULL_ROOT + "source_contract.json"): return false
	var roles: Dictionary={"authoring_source_script":source.get_script().resource_path,"source_assembly_script":get_script().resource_path,"transport_shader":TRANSPORT_PATH,"transport_proof":pilot_auth["transport_proof"]["path"],"terrain_mesh":_v9c_artifact_path("terrain_mesh"),"source_topology":_v9c_artifact_path("source_topology"),"deck_support_mesh":CACHE_ROOT+"chunks/r0_c0_actual_deck_support_mesh.res","whole_capture_report":V9C_FULL_REPORT,"geometry_contract":V9C_FULL_ROOT+"geometry.json","source_contract":V9C_FULL_SOURCE_JSON,"source_script":source.get_script().resource_path,"builder_script":get_script().resource_path,"surface_script":surface.get_script().resource_path,"selector_script":source.get_script().resource_path,"terrain_shader":pilot_result["actual_terrain_shader"]["path"],"height_rf":_v9c_artifact_path("height_rf"),"landmark_semantics":semantics_path,"camera_contract":camera_path}
	roles["geometry_helper"]="res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v6.gd"
	roles["derivation_report"]=_v9c_artifact_path("derivation_report")
	var capture_graph: Dictionary={}
	for role: String in roles:
		capture_graph[role]={"path":roles[role],"sha256":FileAccess.get_sha256(roles[role])}
	if not _write_json(V9C_FULL_ROOT+"art_contract.json",{"version":"world_v15","coordinate_version":15,"art_revision":"complete_v9c_coherent_whole","capture_protocol":V9C_FULL_PROTOCOL,"status":"ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","source_contract_path":V9C_FULL_SOURCE_JSON,"whole_actual_capture":{"path":V9C_FULL_REPORT,"sha256":FileAccess.get_sha256(V9C_FULL_REPORT)},"source_graph":full_graph,"capture_graph":capture_graph,"asset_sha256":full_catalog,"chunks":full_chunks,"seams":full_seams,"outside_sourcebody_shadow_pixels":full_shadow_pixels,"native_object_count":source.vegetation_sites.size(),"structure_count":supports.size(),"portal_count":16,"core_count":9,"visual_approved":false,"production_approved":false,"door_review_requires_root":true}): return false
	return true

func _pilot_make_world(directory: String) -> bool:
	active_view = SubViewport.new()
	active_view.size = (v7_region_rect.size if v7_regional else SOURCE.SIZE) * SSAA
	active_view.own_world_3d = true
	active_view.msaa_2d = Viewport.MSAA_DISABLED
	active_view.msaa_3d = Viewport.MSAA_DISABLED
	active_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(active_view)
	pilot_world = Node3D.new()
	active_view.add_child(pilot_world)
	pilot_environment = WorldEnvironment.new()
	pilot_environment.environment = surface.environment()
	pilot_world.add_child(pilot_environment)
	pilot_sun = DirectionalLight3D.new()
	pilot_sun.rotation_degrees = Vector3(-55, -34, 0)
	pilot_sun.light_energy = .85
	pilot_sun.shadow_enabled = true
	pilot_sun.shadow_normal_bias = 2.
	pilot_sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	pilot_sun.directional_shadow_max_distance = 160.
	pilot_world.add_child(pilot_sun)
	var material: ShaderMaterial = surface.terrain_material(full_map_textures["ecology"], full_map_textures["roads"], Rect2(Vector2.ZERO, Vector2(SOURCE.SIZE)))
	if material == null or material.shader == null or material.shader.code != pilot_shader.code:
		error = "Frozen actual global terrain shader differs."
		return false
	var terrain := MeshInstance3D.new()
	terrain.mesh = _mesh(Rect2(v7_region_rect).grow(1024.),false) if v7_regional else pilot_global_mesh
	if v7_regional:
		var regional_mesh_path: String = directory+"actual_regional_receiver.res"
		if ResourceSaver.save(terrain.mesh,regional_mesh_path)!=OK:
			error="Actual regional same-RF receiver save failed."
			return false
		pilot_result["current_actual_regional_receiver"]={"path":regional_mesh_path,"sha256":FileAccess.get_sha256(regional_mesh_path),"source_RF":_v9c_artifact_path("height_rf"),"source_RF_sha256":FileAccess.get_sha256(_v9c_artifact_path("height_rf")),"source_rect":_recti(v7_region_rect.grow(1024)),"scope":"regional local mesh recreated from exact global RF, NOT whole mesh draw"}
	terrain.material_override = material
	pilot_world.add_child(terrain)
	pilot_receivers.append(terrain)
	# Real domain-external edge receivers, not a painted sky/water/nav guard.
	# Preserve cached authoritative domain mesh/RF. Only this recipe is new.
	var guards: Array[Rect2] = [Rect2(-GUARD, -GUARD, SOURCE.SIZE.x + GUARD * 2, GUARD), Rect2(-GUARD, SOURCE.SIZE.y, SOURCE.SIZE.x + GUARD * 2, GUARD), Rect2(-GUARD, 0, GUARD, SOURCE.SIZE.y), Rect2(SOURCE.SIZE.x, 0, GUARD, SOURCE.SIZE.y)]
	var guard_evidence: Array = []
	for i in (0 if v7_regional else guards.size()):
		var node := MeshInstance3D.new()
		node.mesh = _mesh(guards[i], false)
		node.material_override = material
		var path: String = directory + "visual_only_guard_" + str(i) + ".res"
		if ResourceSaver.save(node.mesh, path) != OK:
			error = "Cannot preserve actual visual guard mesh."
			return false
		pilot_world.add_child(node)
		pilot_receivers.append(node)
		guard_evidence.append({"path": path, "sha256": FileAccess.get_sha256(path), "source_rect_px": [guards[i].position.x, guards[i].position.y, guards[i].size.x, guards[i].size.y], "role": "visual_only_receiver_no_land_nav_support", "recipe": "unchanged parent exact 8px mesh with cached RF edge clamp; original domain vertices never rewritten"})
	pilot_result["visual_guard_recipe"] = guard_evidence
	pilot_water = MeshInstance3D.new()
	var water_mesh := PlaneMesh.new()
	water_mesh.size = Vector2(float(SOURCE.SIZE.x + 2 * GUARD) / SOURCE.PPM, float(SOURCE.SIZE.y + 2 * GUARD) / SOURCE.Z_PPM)
	pilot_water.mesh = water_mesh
	if ResourceSaver.save(water_mesh, directory + "actual_visual_water_plane.res") != OK:
		error = "Cannot save actual global planar water geometry."
		return false
	pilot_water.position.y = SOURCE.WATER_Y
	pilot_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pilot_water.material_override = surface.water_material(full_rf, Vector2i.ZERO, SOURCE.GRID_SIZE)
	pilot_world.add_child(pilot_water)
	pilot_camera = Camera3D.new()
	pilot_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	pilot_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	pilot_camera.size = float(v7_region_rect.size.y if v7_regional else SOURCE.SIZE.y) / SOURCE.PPM
	pilot_camera.near = .05
	pilot_camera.far = 200.
	var camera_target: Vector3 = SOURCE.point3(Vector2(v7_region_rect.get_center()),0.) if v7_regional else Vector3.ZERO
	pilot_camera.position = camera_target + Vector3(0,60,60)
	pilot_world.add_child(pilot_camera)
	pilot_camera.look_at(camera_target)
	pilot_camera.current = true
	var bridges := Node3D.new()
	pilot_world.add_child(bridges)
	_add_bridge_geometry(bridges, Rect2(v7_region_rect).grow(1024.) if v7_regional else Rect2(Vector2.ZERO, Vector2(SOURCE.SIZE)))
	_full_set_shadow_only(bridges, pilot_casters)
	if not _v7_add_casters(directory): return false
	pilot_support = MeshInstance3D.new()
	pilot_support.mesh = pilot_support_mesh
	var white := StandardMaterial3D.new()
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	white.cull_mode = BaseMaterial3D.CULL_DISABLED
	white.albedo_color = Color.WHITE
	pilot_support.material_override = white
	pilot_support.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pilot_support.visible = false
	pilot_world.add_child(pilot_support)
	if not _v9c_record_live_material(material,"terrain",directory+"actual_terrain_material.res") or not _v9c_record_live_material(pilot_water.material_override as ShaderMaterial,"water",directory+"actual_water_material.res"): return false
	return true

func _pilot_capture_world(identity: String) -> Dictionary:
	var directory: String = pilot_output + identity + "/"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK:
		error = "Cannot create actual world output."
		return {}
	if not _pilot_memory_guard(identity): return {}
	if not _pilot_make_world(directory): return {}
	var effective_world: World3D = active_view.find_world_3d()
	if effective_world == null:
		error = "Actual effective World3D unavailable; no synthetic identity credit."
		return {}
	var water_shape: PlaneMesh = pilot_water.mesh as PlaneMesh
	var measured: Dictionary = {"identity": identity, "world_node_instance_id": pilot_world.get_instance_id(), "viewport_instance_id": active_view.get_instance_id(), "world_3d_instance_id": effective_world.get_instance_id(), "camera": _pilot_camera_record(), "coverage": _pilot_coverage(), "roles": {}, "casters": pilot_caster_records.duplicate(true), "authoritative_global_mesh": {"path": _v9c_artifact_path("terrain_mesh"), "sha256": FileAccess.get_sha256(_v9c_artifact_path("terrain_mesh"))}, "support_mesh": {"path": CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res", "sha256": pilot_inputs[CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res"]}, "visual_guard_meshes": pilot_result["visual_guard_recipe"].duplicate(true), "water_recipe": {"native_mesh": "actual flat PlaneMesh in source XZ, one surface", "path": directory + "actual_visual_water_plane.res", "sha256": FileAccess.get_sha256(directory + "actual_visual_water_plane.res"), "water_Y": SOURCE.WATER_Y, "RF_grid_origin": [0, 0], "RF_grid_shape": _v2i(SOURCE.GRID_SIZE), "RF_grid_spacing_px": SOURCE.GRID_STEP, "RF_triangle_formula": "same stored [a,b,c,b,d,c] Float32 texelFetch affine triangles; global p, not PlaneMesh UV", "source_width_m": water_shape.size.x, "source_Z_depth_m": water_shape.size.y}}
	measured["actual_RF"]=v9c_geometry_result["artifacts"]["height_rf"].duplicate(true)
	measured["actual_source_topology"]=v9c_geometry_result["artifacts"]["source_topology"].duplicate(true)
	if not bool(measured["coverage"]["passed"]):
		error = "Actual fullreceiver depth/projection or model clip rejected."
		return {}
	for role: String in ROLE_NAMES:
		if not _pilot_set_role(role): return {}
		var role_record: Dictionary = {"actual_native_canvas": _v2i(active_view.size), "frozen_camera_projection": _pilot_camera_record(), "passes": [], "windows": {}, "caster_actual_visible": role == "visual", "caster_shadow_setting_actual": GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "terrain_actual_cast_shadow": pilot_receivers[0].cast_shadow, "support_actual_visible": pilot_support.visible, "water_actual_visible": pilot_water.visible, "MSAA_3D_actual": active_view.msaa_3d, "MSAA_2D_actual": active_view.msaa_2d}
		for pass_index in 2:
			var pass_record: Dictionary = await _pilot_draw(identity + "_" + role + "_" + str(pass_index))
			if not bool(pass_record["fresh_actual_post_draw_observed"]):
				error = "Fresh native whole draw not fenced."
				return {}
			if role in ["visual", "shadow_off"] and (not _shader_gate(pilot_receivers[0].material_override, ["biome_weights", "road_weights", "grass_ground_diff", "rock_01_arm","v9d_material_identity"]) or not _shader_gate(pilot_water.material_override, ["actual_height_rf", "grid_origin", "grid_shape"])):
				error = "Actual after-draw shader binding rejected; no default fallback."
				return {}
			role_record["passes"].append(pass_record)
			for item: Dictionary in _pilot_windows():
				var captured: Dictionary = await _pilot_read_roi(item, role, directory, pass_index, pass_record)
				if captured.is_empty(): return {}
				var id: String = item["id"]
				if pass_index == 0:
					role_record["windows"][id] = captured
				else:
					var first: Dictionary = role_record["windows"][id]
					var raw_difference: Dictionary = _pilot_compare_pngs(first["raw_path"], captured["raw_path"])
					var logical_difference: Dictionary = _pilot_compare_pngs(first["path"], captured["path"])
					first["raw_repeat_path"] = captured["raw_path"]
					first["repeat_path"] = captured["path"]
					first["repeat_transfer_evidence"] = captured
					first["actual_repeat_raw"] = raw_difference
					first["actual_repeat_logical"] = logical_difference
					if not bool(raw_difference["byte_exact"]) or not bool(logical_difference["byte_exact"]):
						error = "Actual raw/logical repeat failed: " + identity + "/" + role + "/" + id
						pilot_result["failed_role_evidence"] = role_record
						return {}
		measured["roles"][role] = role_record
		# ON/OFF are still native 3D draws. Terrain self shadow never disabled
		# for visual or shadow_off; only sourcebody casters become invisible.
	var primary_ref: WeakRef = weakref(active_view)
	await _pilot_release_world()
	measured["actual_world_released_before_next"] = primary_ref.get_ref() == null
	if not bool(measured["actual_world_released_before_next"]):
		error = "Actual primary viewport not released; no second huge allocation."
		return {}
	return measured

func _pilot_windows() -> Array[Dictionary]:
	if not v7_windows.is_empty(): return v7_windows
	for row in 8:
		for col in 8:
			v7_windows.append({"id": "r%d_c%d" % [row, col], "rect": Rect2i(col * SOURCE.TILE.x, row * SOURCE.TILE.y, SOURCE.TILE.x, SOURCE.TILE.y)})
	for row in 8:
		for col in 7:
			var edge: Dictionary = _edge(row, col, true)
			v7_windows.append({"id": edge["id"], "rect": Rect2i(edge["rect"])})
	for row in 7:
		for col in 8:
			var edge: Dictionary = _edge(row, col, false)
			v7_windows.append({"id": edge["id"], "rect": Rect2i(edge["rect"])})
	return v7_windows


func _v9c_artifact_path(role: String) -> String:
	return String(v9c_geometry_result["artifacts"][role]["path"])

func _v9c_native_paths(paths: Array) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for path: Dictionary in paths:
		var points: Array=[]
		for point: Vector2 in path["points"]: points.append([point.x,point.y])
		result.append({"id":path["id"],"points":points,"half_width_px":path["half_width_px"],"coordinate_space":"SOURCE_XZ_LOGICAL_PIXELS_NOT_PROJECTED_WORLD"})
	return result

func _v9c_read_derived_inputs() -> Dictionary:
	# Parent calls this AFTER original RF prepare/detour and BEFORE NEW bind.
	v9c_prepared_native_routes=_v9c_native_paths(source.routes)
	v9c_prepared_native_rivers=_v9c_native_paths(source.rivers)
	v9c_baseline_prepared_site_signature=_bytes_sha(JSON.stringify(source.vegetation_sites).to_utf8_buffer())
	var derived: Dictionary=super._v9c_read_derived_inputs()
	if derived.is_empty(): return derived
	if derived["audit"].get("original_site_signature")!=v9c_baseline_prepared_site_signature:
		error="Original baseline prepared site signature differs from actual CPU derivation."
		return {}
	return derived

func _load_pilot_inputs() -> bool:
	# The limited parent is the explicit NEW loader, not the old cache loader.
	# It prepares original sites on baseline RF, replays Bianzhou, binds NEW RF.
	if not _v9c_load_bodies() or not super._load_pilot_inputs(): return false
	if not source is V9C_SOURCE or not surface is V9C_SURFACE or not source.v9c_derived_rf_installed:
		error="Actual V9C source/surface/derived RF object identity missing."
		return false
	var native: Dictionary=v9c_geometry_result["audit"].get("mesh",{})
	var guard: Dictionary=v9c_geometry_result["audit"].get("RF_support_guard",{})
	var rf_guard: Dictionary=guard.get("RF",{})
	var nav_guard: Dictionary=guard.get("NAV",{})
	if guard.get("identity")!="RF_HARD_EXTRA16_SOFT640_ORIGINAL_NAV_HARD_UNCHANGED_V2" or guard.get("RF_support_extra_px")!=16. or rf_guard.get("physical_total_halo_px")!=40. or rf_guard.get("physical_soft_width_px")!=640. or rf_guard.get("road_hard_extra_px")!=136. or rf_guard.get("road_soft_end_extra_px")!=776. or rf_guard.get("shore_hard_bank_px")!=144. or rf_guard.get("shore_soft_end_bank_px")!=784. or rf_guard.get("own_bucket_px")!=128. or rf_guard.get("separate_physical_and_road_buckets")!=true or nav_guard.get("physical_halo_px")!=24. or nav_guard.get("road_hard_extra_px")!=120. or nav_guard.get("shore_hard_bank_px")!=128. or nav_guard.get("selector_formula_unchanged")!=true or nav_guard.get("hard_domain_expanded")!=false or guard.get("no_RF_triangle_support_or_NAV_threshold_waiver")!=true:
		error="Actual helper6 broad RF soft triangle-support guard/NAV hard-domain audit missing or different; no allocation."
		return false
	if native.get("identity")!="NEW_NORMAL_OLD_SEMANTIC_TANGENT_NATIVE_ABC_PACKING_BYTE_EXACT_V1" or native.get("passed")!=true or native.get("slot_records",[]).size()!=Mesh.ARRAY_MAX or native.get("semantic_tangent_input_unchanged")!=true or native.get("original_normal_tangent_bits_unchanged_claim")!=false or native.get("outside_incident_TBN_byte_exact_to_native_control")!=true or native.get("actual_TBN_byte_exact_to_new_normal_oracle")!=true or native.get("outside_incident_actual_normal_changed_vertices",-1)!=0 or native.get("outside_incident_actual_tangent_changed_vertices",-1)!=0:
		error="Approved actual derived mesh must include native ABC packed-TBN audit; no original tangent-bit or epsilon shortcut."
		return false
	if source.heights.to_byte_array()!=FileAccess.get_file_as_bytes(_v9c_artifact_path("height_rf")):
		error="Actual installed NEW RF bytes differ."
		return false
	var initial: Dictionary=surface.v9_material_records.back().duplicate(true)
	if initial.get("kind")!="terrain" or initial.get("identity")!=V9C_SURFACE.V9D_SURFACE_ID:
		error="Initial actual V9C terrain material creation missing."
		return false
	initial["creation_stage"]="INITIAL_ACTUAL_SHADER_CONSTRUCTION_NOT_A_DRAW"
	initial["actual_saved_shader"]=pilot_result["actual_terrain_shader"].duplicate(true)
	v9c_attached_material_creations.append(initial)
	pilot_result["original_site_preparation"]={"baseline_RF":{"path":CACHE_ROOT+"terrain_height.rf","sha256":pilot_inputs[CACHE_ROOT+"terrain_height.rf"]},"method":"BASELINE_RF_PREPARE_THEN_FIXED_BIANZHOU_APPROACH_THEN_BIND_DERIVED_RF_NO_REPREPARE","baseline_objects":full_objects.size(),"support_audit":v9c_geometry_result["audit"].get("object_support",{}),"site_signature":v9c_geometry_result["audit"].get("original_site_signature",{})}
	# These immutable baseline objects were protection inputs, not duplicated
	# runtime instances. Re-export all preserved sites/compounds independently.
	full_objects.clear()
	return true

func _v9c_record_live_material(material: ShaderMaterial,kind: String,path: String) -> bool:
	if material==null or material.shader==null or ResourceSaver.save(material,path)!=OK:
		error="Cannot preserve actual attached V9C material."
		return false
	var uniform_rows: Array[Dictionary]=[]
	for spec: Dictionary in material.shader.get_shader_uniform_list():
		var name: String=String(spec["name"])
		var value: Variant=material.get_shader_parameter(name)
		var row: Dictionary={"name":name,"schema":spec,"variant_type":typeof(value)}
		if value is Texture2D:
			var image: Image=value.get_image()
			if image==null or image.is_empty():
				error="Actual attached texture image missing "+name
				return false
			row["texture"]={"resource_path":value.resource_path,"canvas":_v2i(image.get_size()),"format":image.get_format(),"mip_count":image.get_mipmap_count(),"RGBA_and_all_mips_sha256":_bytes_sha(image.get_data())}
		elif value is Resource:
			error="Unexpected actual attached resource uniform "+name
			return false
		else:
			row["native_variant_bytes_sha256"]=_bytes_sha(var_to_bytes(value))
			row["value_as_text"]=str(value)
		uniform_rows.append(row)
	var binding: Dictionary=surface._v7_binding_evidence(material)
	if kind=="water" and (material.get_shader_parameter("actual_height_rf")!=full_rf or material.get_shader_parameter("grid_origin")!=Vector2i.ZERO or material.get_shader_parameter("grid_shape")!=SOURCE.GRID_SIZE):
		error="Actual attached water uses a different RF/grid."
		return false
	if kind=="terrain":
		if material.shader.code!=pilot_shader.code or material.get_shader_parameter("v9c_material_identity")!=1. or material.get_shader_parameter("v9d_material_identity")!=1.:
			error="Attached actual terrain shader/identity differs."
			return false
		for name: String in binding:
			if binding[name].get("same_registered_texture_object")!=true:
				error="Actual terrain scan sampler not bound "+name
				return false
	v9c_attached_material_creations.append({"kind":kind,"creation_stage":"ACTUAL_ATTACHED_WHOLE_WORLD_MATERIAL","path":path,"sha256":FileAccess.get_sha256(path),"actual_code_sha256":_bytes_sha(material.shader.code.to_utf8_buffer()),"actual_surface":{"path":surface.get_script().resource_path,"sha256":FileAccess.get_sha256(surface.get_script().resource_path)},"actual_uniforms":uniform_rows,"registered_binding":binding,"RF_bound_to_actual_new_texture":material.get_shader_parameter("actual_height_rf")==full_rf if kind=="water" else true,"visual_approved":false,"production_approved":false})
	_full_register_paths(path)
	return true

func _v9c_final_revision_evidence() -> bool:
	if v9c_attached_material_creations.size()!=5:
		error="Actual V9C initial plus two worlds terrain/water material creations incomplete."
		return false
	var helper_path: String="res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v6.gd"
	var execution: Dictionary=pilot_result["actual_v9c_execution"].duplicate(true)
	execution.erase("ecology_contract")
	execution["full"]={"path":"res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd","sha256":FileAccess.get_sha256("res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd"),"role":"INHERITED_FULL_METHODS_NOT_REGIONAL_EXECUTOR" if v9c_regional_mode else "ACTUAL_FULL_EXECUTOR"}
	execution["regional"]={"path":V9C_REGIONAL_PATH,"sha256":FileAccess.get_sha256(V9C_REGIONAL_PATH),"role":"ACTUAL_REGIONAL_EXECUTOR" if v9c_regional_mode else "ROOT_REVIEWED_PRIOR_REGIONAL_EXECUTOR"}
	execution["geometry_helper"]={"path":helper_path,"sha256":FileAccess.get_sha256(helper_path),"role":"ACTUAL_CPU_DERIVATION_HELPER_NOT_REEXECUTED_DURING_GPU"}
	pilot_result["v9c_revision_evidence"]={"actual_execution":execution,"ecology_contract":source.v9_execution_contract(),"derived_geometry_inputs":v9c_geometry_result["artifacts"].duplicate(true),"derived_geometry_audit":v9c_geometry_result["audit"].duplicate(true),"attached_material_creations":v9c_attached_material_creations.duplicate(true),"actual_materials":surface.evidence.duplicate(true),"original_site_preparation":pilot_result["original_site_preparation"].duplicate(true),"prepared_native_routes":v9c_prepared_native_routes.duplicate(true),"prepared_native_rivers":v9c_prepared_native_rivers.duplicate(true),"baseline_prepared_site_signature":v9c_baseline_prepared_site_signature,"regional_approval":pilot_auth.get("regional_visual_review",{}),"old_navigation_credit":false,"production_approved":false,"visual_approved":false,"scope":"Actual NEW RF/mesh/selector; protected supports preserved, new native binary navigation must pass fresh global/Field gates"}
	return true

func _v9c_regional_approval_error() -> String:
	var review: Variant=pilot_auth.get("regional_visual_review")
	if not review is Dictionary or review.get("approved_by")!="root" or review.get("approved")!=true or review.get("scope")!=V9C_REGIONAL_SCOPE:
		error="NEW FULL requires separate actual current V9C regional root review."
		return error
	var target: Dictionary=review.get("candidate_full_builder",{})
	if target.get("path")!=get_script().resource_path or String(target.get("sha256","")).to_lower()!=FileAccess.get_sha256(get_script().resource_path).to_lower():
		error="Independent regional review must bind this exact FULL target."
		return error
	var path: String=review.get("result_path","")
	if not path.begins_with(V9C_REGIONAL_ROOT) or String(review.get("result_sha256","")).length()!=64 or FileAccess.get_sha256(path).to_lower()!=String(review["result_sha256"]).to_lower() or String(pilot_inputs.get(path,"")).to_lower()!=String(review["result_sha256"]).to_lower():
		error="Actual current NEW regional result is not bound."
		return error
	var actual: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not actual is Dictionary or actual.get("scope")!=V9C_REGIONAL_SCOPE or actual.get("status")!=V9C_REGIONAL_STATUS or actual.get("input_hashes_unchanged_after")!=true:
		error="Actual current V9C regional technical evidence incomplete."
		return error
	var executor: Dictionary=actual.get("executed_builder",{})
	if executor.get("path")!=V9C_REGIONAL_PATH or String(executor.get("sha256","")).to_lower()!=FileAccess.get_sha256(V9C_REGIONAL_PATH).to_lower() or String(pilot_inputs.get(V9C_REGIONAL_PATH,"")).to_lower()!=FileAccess.get_sha256(V9C_REGIONAL_PATH).to_lower():
		error="Actual regional executor differs from current input catalog."
		return error
	var recorded: Dictionary=actual.get("cached_inputs_sha256",{})
	for dependency: String in V9C_FULL_PINS:
		if String(recorded.get(dependency,"")).to_lower()!=V9C_FULL_PINS[dependency]:
			error="Regional current V9C source/material/helper dependency differs "+dependency
			return error
	var actual_derived: Dictionary=actual.get("derived_geometry_inputs",{})
	if actual_derived!=pilot_auth.get("derived_geometry_inputs",{}):
		error="Regional and FULL derived geometry roles differ."
		return error
	for role: String in ["height_rf","terrain_mesh","source_topology","derivation_report"]:
		var entry: Dictionary=actual_derived.get(role,{})
		if String(entry.get("sha256","")).length()!=64 or FileAccess.get_sha256(entry.get("path","")).to_lower()!=String(entry["sha256"]).to_lower():
			error="Actual regional derived geometry changed "+role
			return error
	var worlds: Dictionary=actual.get("worlds",{})
	if worlds.size()!=2 or worlds.get("primary",{}).get("world_node_instance_id")==worlds.get("reference",{}).get("world_node_instance_id") or worlds.get("primary",{}).get("world_3d_instance_id")==worlds.get("reference",{}).get("world_3d_instance_id"):
		error="Two truly independent regional worlds not proven."
		return error
	var ids: Array[String]=["farmland","marsh","snow","limestone","meadow_river","northern_river_bailu_junction"]
	for identity: String in ["primary","reference"]:
		var world: Dictionary=worlds.get(identity,{})
		if world.get("actual_world_released_before_next")!=true or world.get("coverage",{}).get("passed")!=true:
			error="Actual regional coverage/release missing."
			return error
		for role: String in ROLE_NAMES:
			var row: Dictionary=world.get("roles",{}).get(role,{})
			var windows: Dictionary=row.get("windows",{})
			if row.get("passes",[]).size()!=2 or windows.size()!=6:
				error="Regional two draws/all5 roles/all6 exact ROIs incomplete."
				return error
			for id: String in ids:
				var window: Dictionary=windows.get(id,{})
				var repeat: Dictionary=window.get("repeat_transfer_evidence",{})
				if window.get("actual_repeat_raw",{}).get("byte_exact")!=true or window.get("actual_repeat_logical",{}).get("byte_exact")!=true:
					error="Actual regional repeat failed."
					return error
				for record: Dictionary in [window,repeat]:
					for key: String in ["path","raw_path"]:
						var file: String=record.get(key,"")
						var sha_key: String="sha256" if key=="path" else "raw_sha256"
						if not file.begins_with(V9C_REGIONAL_ROOT) or String(record.get(sha_key,"")).length()!=64 or FileAccess.get_sha256(file).to_lower()!=String(record[sha_key]).to_lower():
							error="Actual original/repeat regional image binding failed."
							return error
	for role: String in ROLE_NAMES:
		var compared: Dictionary=actual.get("comparisons",{}).get(role,{}).get("independent_worlds_same_global_coordinates",{})
		for id: String in ids:
			if compared.get(id,{}).get("byte_exact")!=true or compared.get(id,{}).get("independent_raw_RGBA",{}).get("byte_exact")!=true:
				error="Actual independent regional RGBA equality missing."
				return error
	if actual.get("alpha_union",{}).get("passed")!=true or actual.get("v9c_revision_evidence",{}).get("attached_material_creations",[]).size()!=5:
		error="Regional actual canopy/material evidence incomplete."
		return error
	return ""

func _pilot_finish(passed: bool) -> void:
	if not passed and v7_started:
		pilot_result["status"]="V9C_FULL_REFUSED_OR_TECHNICAL_FAIL"
		pilot_result["reason"]=error
		_write_json(V9C_FULL_ROOT+"art_contract.json",{"status":"TECHNICAL_FAIL","capture_protocol":V9C_FULL_PROTOCOL,"reason":error,"production_approved":false})
		_write_json(V9C_FULL_REPORT,pilot_result)
	# Limited NEW parent owns release/9s natural frames/public audio stop and
	# cursor lifetime cleanup; it never writes the historical V8/V7 art roots.
	await super._pilot_finish(passed)
