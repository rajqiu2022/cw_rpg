extends RefCounted
## NEW whole-frame authority only. Historical local-frustum gates stay immutable.
## A pilot, copied strip or unbound same-sized image is never a FULL candidate.
const C = preload("res://scripts/world/world_map_v15_contract.gd")
const FROZEN_SOURCE_SHA := "PENDING_FINAL_V7_WORLD_ART"
const FROZEN_MANIFEST_SHA := "PENDING_FINAL_V7_WORLD_ART"
const ROOT := "res://art/maps/world_map_v15_complete_v7/"
const BUILDER := "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd"
const TERRAIN_SHADER := ROOT + "capture/v7_actual_terrain_shader.gdshader"
const OVERSCAN_PX := 96
const REVIEW := "res://data/maps/world_map_v15_complete_v7_visual_review.json"
const REVIEW_SCOPE := "ACTUAL_CURRENT_CAPTURE_VISUAL_REVIEW_NOT_FIELD_INPUT_APPROVAL"
const NEGATIVE_ORIGIN := "INDEPENDENT_ROOT_REVIEW_AUTHORED_NEGATIVES_V1"
const CAPTURED_NEGATIVE_ORIGIN := "CAPTURED_SOURCE_INPUT_NEGATIVES_EXACT_V1"
const NEGATIVE_FOOTPRINTS := "res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json"
const CORE_IDS := ["huashan", "luoyang", "bianzhou", "gufeng", "wudang", "xiangzhou", "jinling", "lingyue", "mingwu"]
const SOURCE_PATH := "res://data/maps/world_map_v15_complete_v7_source.json"
const MANIFEST_PATH := ROOT + "art_contract.json"
const REPORT_PATH := ROOT + "whole_actual_capture.json"
const PROTOCOL := "COHERENT_WHOLE_FIXED_CAMERA_INTEGER_TEXEL_ROI_V1_FULL"
const TRANSPORT := "res://shaders/world_v15_native_texel_transfer.gdshader"
const TRANSPORT_SHA := "4997274fc2a62404235a69117785448c2ec65cc50667a4353d27c456d33ec47e"
const TRANSPORT_PROOF := "res://build/world_map_v15_native_texel_transfer/1791066200_2454361/result.json"
const TRANSPORT_PROOF_SHA := "53896c2af42ce245cadee635c4b2eb7b1d2dbfbae54c6845259931fc1e668de8"
const MAX_CPU_ROI_PIXELS := 8404992 # Root-approved NEW full interior ROI; pilot stays8388608.
const CAPTURE_ROLES := ["visual", "shadow_off", "land", "raw_walk", "walk"]
const ROLES := ["authoring_source_script", "source_script", "source_assembly_script", "builder_script", "surface_script", "selector_script", "terrain_shader", "height_rf", "landmark_semantics", "camera_contract", "transport_shader", "transport_proof", "terrain_mesh", "source_topology", "deck_support_mesh", "whole_capture_report"]
const ECOLOGY_PATH := "res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd"
const SURFACE_PATH := "res://scripts/dev/world_map_v15_complete_v7_surface_proposal.gd"
const CASTER_PATH := "res://scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd"
const REGIONAL_BUILDER := "res://scripts/dev/build_world_map_v15_coherent_whole_v7_regional_proposal.gd"
const ECOLOGY = preload("res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd")
const EXACT_V7_INPUTS := {
 ECOLOGY_PATH:"434aca511887eb06939fcd85cbe815b74e1f3fc3c7b560777fb91e78e91a5d16",
 SURFACE_PATH:"0f469cd0bfac24195df18e9667873b926d6bee9875f1ca171ccbddeaff2dd7f8",
 CASTER_PATH:"d2d3795942aa452a18abc006d45bcde44749ccad276a7ec16e0f897604611290",
 BUILDER:"74a7757a43c7ff4e339fa297bf29a0ec7860cf6a70f7508ebd80a418ce18e233",
 REGIONAL_BUILDER:"fd6dc2a60fd4f0fd6f3e4803b96973d6827b9f781f48a82bed1176ed2fc3c9a8",
 "res://scripts/dev/test_world_v15_native_combined_rgba_word_stats_unit.gd":"f5ffe7adf8e9155f19fcd8640da51724605152dfe8bc1d3875789a8688d82608",
 "res://build/world_v15_native_binary_stats_unit/1791073994_1612124/result.json":"dde934b08ceacef6a887547c28af6296a0d6a2d5e9719b20775048582493c7e9"
}
const REGIONAL_SCOPE := "V7_REGIONAL_NATIVE_GEOMETRY_ALPHA_SHADOW_NOT_FULL64"
static var _report: Dictionary = {}
static var _v7_tiles: Dictionary = {}
static var _v7_tile_order: Array[String] = []
static var _v7_plane_validation: Dictionary = {}

static func validate(source: Dictionary, manifest: Dictionary) -> String:
	_report = {}
	if not _same_hash(FROZEN_SOURCE_SHA, FileAccess.get_sha256(SOURCE_PATH)) or not _same_hash(FROZEN_MANIFEST_SHA, FileAccess.get_sha256(MANIFEST_PATH)): return "Whole v7 source/manifest PENDING; no candidate publication"
	if not _num(source.get("schema_version"), 15) or not _pair_eq(source.get("world_size"), C.SIZE) or source.get("status") != "ART_ASSETS_READY" or manifest.get("version") != "world_v15" or not _num(manifest.get("coordinate_version"), 15) or manifest.get("status") != "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA": return "Incomplete FULL coordinate15 source"
	var capture_source: Variant = source.get("capture")
	if not capture_source is Dictionary or capture_source.get("capture_protocol") != PROTOCOL or not _true(capture_source.get("whole_capture")) or not _false(capture_source.get("local_camera_authority")): return "PILOT/local-frustum authority is not FULL whole capture"
	var catalog: Variant = manifest.get("asset_sha256")
	if not catalog is Dictionary or catalog.is_empty(): return "Missing actual SHA catalog"
	for path: Variant in catalog:
		if not path is String or not _asset_path(path) or not _hash(catalog[path]) or not FileAccess.file_exists(path) or not _same_hash(catalog[path], FileAccess.get_sha256(path)): return "Changed/unbound actual bytes " + str(path)
	for path: String in [SOURCE_PATH, REPORT_PATH, ROOT + "landmark_semantics.json", String(source.get("overview_path", ""))]:
		if not _bound(catalog, path): return "Unbound mandatory source/report/overview " + path
	for path: String in _all_art(ROOT):
		if not _bound(catalog, path): return "Uncatalogued NEW output " + path
	var graph: Variant = manifest.get("source_graph")
	var capture: Variant = manifest.get("capture_graph")
	if not graph is Dictionary or graph.is_empty() or not capture is Dictionary: return "Missing executed source/capture graph"
	for path: Variant in graph:
		if not path is String or not _bound(catalog, path) or not _same_hash(graph[path], catalog[path]): return "Graph/catalog/current byte mismatch " + str(path)
		if String(path).get_extension() in ["gd", "gdshader"]:
			var error := _literal_dependencies(path, graph, catalog)
			if not error.is_empty(): return error
	for role: String in ROLES:
		var record: Variant = capture.get(role)
		if not record is Dictionary or not _bound(catalog, String(record.get("path", ""))) or not _same_hash(record.get("sha256"), catalog.get(record.get("path"))) or not graph.has(record.path): return "Unbound FULL capture role " + role
	if capture.authoring_source_script.path != ECOLOGY_PATH or capture.source_script.path != capture.authoring_source_script.path or capture.selector_script.path != capture.authoring_source_script.path or capture.builder_script.path != BUILDER or capture.source_assembly_script.path != BUILDER or capture.surface_script.path != SURFACE_PATH or capture.terrain_shader.path != TERRAIN_SHADER or capture.transport_shader.path != TRANSPORT or not _same_hash(capture.transport_shader.sha256, TRANSPORT_SHA) or capture.transport_proof.path != TRANSPORT_PROOF or not _same_hash(capture.transport_proof.sha256, TRANSPORT_PROOF_SHA) or capture.whole_capture_report.path != REPORT_PATH: return "Not the actual NEW full builder/authoring/transport graph"
	for binding: Array in [["authoring_source", "authoring_source_script"], ["executed_builder", "builder_script"], ["capture_report", "whole_capture_report"]]:
		var record: Variant = capture_source.get(binding[0])
		if not record is Dictionary or record.get("path") != capture[binding[1]].path or not _same_hash(record.get("sha256"), capture[binding[1]].sha256): return "Source authoring/execution identity mismatch " + binding[0]
	var copies_error := _runtime_copies_error(catalog, capture)
	if not copies_error.is_empty(): return copies_error
	var proof := C.read_json(TRANSPORT_PROOF)
	if proof.get("status") != "SMALL_ORACLE_AND_WHOLE_WINDOW_PASS" or not proof.get("stage_A") is Dictionary or not proof.get("stage_B") is Dictionary or not _true(proof.stage_A.get("passed")) or not _true(proof.stage_B.get("passed")) or not _false(proof.get("whole_cpu_image_requested")) or not _true(proof.get("zero_tolerance")) or not proof.get("transfer_shader") is Dictionary or not _same_hash(proof.transfer_shader.get("sha256"), TRANSPORT_SHA): return "Actual ROOT094 opaque transport proof absent"
	_report = C.read_json(REPORT_PATH)
	var full_error := _whole_error(_report, catalog, capture)
	if not full_error.is_empty(): return full_error
	var geometry: Variant = source.get("geometry")
	if not geometry is Dictionary or not _pair_eq(geometry.get("grid_size"), Vector2(1537, 1025)) or not _num(geometry.get("grid_step_px"), 8): return "Wrong original coordinate15 lattice"
	var portal_ids: Dictionary = {}
	for portal: Variant in source.get("portals", []):
		if not portal is Dictionary or not String(portal.get("id", "")) in C.PORTAL_IDS or portal_ids.has(String(portal.get("id", ""))): return "Unknown/duplicate original portal"
		portal_ids[String(portal.id)] = true
	if portal_ids.size() != 16: return "Exactly16 original portals required"
	for error: String in [_chunks(source, manifest, catalog, capture), _seams(source, manifest, catalog, capture), _portals(source, catalog), _spacing(source), _routes(source)]:
		if not error.is_empty(): return error
	var revision_error: String = _v7_revision_error(source, catalog, capture)
	if not revision_error.is_empty(): return revision_error
	return _review(source, manifest, catalog)

static func _runtime_copies_error(catalog: Dictionary, graph: Dictionary) -> String:
	var path := ROOT + "geometry.json"
	if not _bound(catalog, path): return "Missing bound runtime geometry-copy provenance"
	var geometry := C.read_json(path)
	for binding: Array in [["runtime_mesh_copy", "terrain_mesh"], ["height_rf_copy", "height_rf"], ["runtime_shader_copy", "terrain_shader"], ["source_topology_copy", "source_topology"], ["deck_support_mesh_copy", "deck_support_mesh"]]:
		var copy: Variant = geometry.get(binding[0])
		var original: Dictionary = graph[binding[1]]
		if not copy is Dictionary: return "Missing original/GPU/runtime-copy record " + binding[0]
		var runtime := String(copy.get("path", ""))
		if not runtime.begins_with(ROOT) or runtime == original.path or not _bound(catalog, runtime) or copy.get("original_path") != original.path or copy.get("actual_GPU_input_path") != original.path or not _same_hash(copy.get("sha256"), catalog[runtime]) or not _same_hash(copy.get("original_sha256"), original.sha256) or not _same_hash(catalog[runtime], original.sha256): return "Actual original/GPU/runtime-copy bytes differ " + binding[0]
	return ""

static func _chunks(source: Dictionary, manifest: Dictionary, catalog: Dictionary, graph: Dictionary) -> String:
	var source_chunks: Variant = source.get("chunks")
	var captured_chunks: Variant = manifest.get("chunks")
	if not source_chunks is Array or not captured_chunks is Array or source_chunks.size() != 64 or captured_chunks.size() != 64: return "Exactly 64 source and actual capture chunks required"
	var ids: Dictionary = {}
	for raw: Variant in captured_chunks:
		if not raw is Dictionary: return "Malformed chunk evidence"
		var id := String(raw.get("id", ""))
		if not _integer(raw.get("row"), 0) or not _integer(raw.get("col"), 0): return "Noninteger chunk coordinates"
		var row := int(raw.get("row", -1))
		var col := int(raw.get("col", -1))
		if row < 0 or row > 7 or col < 0 or col > 7 or id != "r%d_c%d" % [row, col] or ids.has(id): return "Duplicate/outside chunk " + id
		ids[id] = true
		var expected := [col * 1536, row * 1024, 1536, 1024]
		if not _rect_eq(raw.get("logical_rect_px"), expected): return "Wrong actual chunk rect " + id
		var authored: Dictionary = {}
		for entry: Variant in source_chunks:
			if entry is Dictionary and String(entry.get("id", "")) == id:
				if not authored.is_empty(): return "Duplicate source chunk " + id
				authored = entry
		if authored.is_empty() or not _rect_eq(authored.get("logical_rect_px"), expected): return "Missing exact source chunk " + id
		for kind: String in CAPTURE_ROLES:
			var key := kind + "_path"
			var path := ROOT + "chunks/" + id + "_" + kind + ".png"
			if raw.get(key) != path or authored.get(key) != path or not _bound(catalog, path) or not _png_size(path, C.TILE_SIZE): return "Missing/broken native chunk artifact " + path
		if not _imported_authority_current(String(raw.walk_path)): return "Missing/stale imported authoritative walk pixels " + id + "; strict import current PNGs before publishing"
		var evidence: Variant = raw.get("capture")
		if not evidence is Dictionary: return "Missing actual capture " + id
		if evidence.get("capture_role") != "primary" or evidence.get("window_id") != id: return "Chunk does not originate in primary whole draw"
		var capture_error := _capture_window_error(evidence, expected, catalog, graph)
		if not capture_error.is_empty(): return capture_error + " " + id
		var output_hashes: Variant = evidence.get("outputs_sha256")
		if not output_hashes is Dictionary: return "Missing actual outputs hashes " + id
		for kind: String in CAPTURE_ROLES:
			var path := String(raw[kind + "_path"])
			if evidence.get(kind + "_path") != path or not _same_hash(output_hashes.get(path), catalog[path]): return "Capture output/catalog SHA mismatch " + path
	return ""

static func _capture_window_error(evidence: Dictionary, rect: Array, catalog: Dictionary, graph: Dictionary) -> String:
	# Explicit NEW protocol. No old translated camera/window-mesh compatibility branch.
	if evidence.get("capture_protocol") != PROTOCOL or not _rect_eq(evidence.get("logical_rect_px"), rect): return "Capture protocol/window mismatch"
	var identity: String = String(evidence.get("capture_role", ""))
	var window_id: String = String(evidence.get("window_id", ""))
	if identity not in ["primary", "reference"] or window_id.is_empty(): return "Missing actual whole source identity"
	var world: Dictionary = _report.worlds[identity]
	if evidence.get("actual_camera") != world.camera: return "Capture copied a different actual whole camera"
	if not _pair_eq(evidence.get("actual_native_canvas"), C.SIZE * 2) or not _pair_eq(evidence.get("actual_whole_GPU_input_canvas"), C.SIZE * 2) or not _pair_eq(evidence.get("actual_logical_canvas"), Vector2(float(rect[2]), float(rect[3]))) or not _num(evidence.get("logical_overscan"), OVERSCAN_PX) or evidence.get("whole_capture_report_path") != REPORT_PATH or not _num(evidence.get("binary_MSAA"), 0) or not _false(evidence.get("binary_resized")) or not _false(evidence.get("whole_CPU_Image_requested")) or evidence.get("CPU_ROI_budget") != _report.get("CPU_ROI_budget"): return "Capture wrapper lost exact whole/ROI/native authority identity"
	for binding: Array in [["global_terrain_mesh_path", "global_terrain_mesh_sha256", "terrain_mesh"], ["height_rf_path", "height_rf_sha256", "height_rf"], ["actual_deck_mesh_path", "actual_deck_mesh_sha256", "deck_support_mesh"]]:
		if evidence.get(binding[0]) != graph[binding[2]].path or not _same_hash(evidence.get(binding[1]), graph[binding[2]].sha256): return "Capture actual source authority differs " + binding[2]
	var roles: Variant = evidence.get("roles")
	if not roles is Dictionary or roles.size() != CAPTURE_ROLES.size(): return "Exactly5 whole capture roles required"
	for role: String in CAPTURE_ROLES:
		var native_role: Dictionary = world.roles[role]
		var windows: Dictionary = native_role.windows
		if not windows.has(window_id) or not roles.get(role) is Dictionary or roles[role] != windows[window_id]: return "ROI is not actual saved whole-world window " + role
		# Every window in BOTH worlds was independently decoded in _whole_error.
		if not _rect_eq(roles[role].get("logical_rect_px"), rect): return "Window identity has wrong actual coordinates"
		for suffix: String in ["path", "repeat_path"]:
			# Runtime PNGs are honest byte-exact copies of the independently retained
			# report ROI, not fictitious aliases with the same resource path.
			var runtime: String = String(evidence.get(role + "_" + suffix, ""))
			var original: String = String(roles[role].get(suffix, ""))
			var expected: String = ROOT + ("chunks/" if identity == "primary" else "seams/") + window_id + "_" + role + ("_repeat.png" if suffix == "repeat_path" else ".png")
			var hashes: Variant = evidence.get("outputs_sha256")
			if runtime != expected or runtime == original or not _bound(catalog, runtime) or not _bound(catalog, original) or not _same_hash(catalog[runtime], catalog[original]) or not hashes is Dictionary or not _same_hash(hashes.get(runtime), catalog[runtime]): return "Runtime copy/report ROI bytes differ " + role + "/" + suffix
	return ""

static func _whole_error(report: Dictionary, catalog: Dictionary, graph: Dictionary) -> String:
	if report.get("capture_protocol") != PROTOCOL or report.get("scope") != "FULL64_112SEAMS_NEW_PROTOCOL_NOT_FORMAL_APPROVED" or report.get("status") != "FULL64_112SEAMS_NEW_PROTOCOL_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_REVIEW" or not _false(report.get("whole_cpu_image_requested")) or not _false(report.get("whole_cpu_image_allowed")): return "PILOT/incomplete/wholeCPU capture cannot be published"
	if not _num(report.get("maximum_CPU_ROI_pixels"), MAX_CPU_ROI_PIXELS): return "Wrong literal bounded FULL CPU ROI budget"
	var authorization_error := _authorization_error(report, catalog, graph)
	if not authorization_error.is_empty(): return authorization_error
	var executed: Variant = report.get("executed_builder")
	if not executed is Dictionary or executed.get("path") != BUILDER or not _same_hash(executed.get("sha256"), graph.builder_script.sha256): return "FULL report executed a different source"
	var worlds: Variant = report.get("worlds")
	var guards: Variant = report.get("fresh_preallocation_guards")
	var history: Variant = report.get("actual_memory_history")
	if not worlds is Dictionary or worlds.size() != 2 or not guards is Array or guards.size() != 2 or not history is Dictionary or not _true(history.get("valid")): return "Missing two fresh whole worlds/memory evidence"
	var history_error := _history_error(history, catalog)
	if not history_error.is_empty(): return history_error
	var expected_windows := _expected_windows()
	var world_ids: Dictionary = {}
	var viewport_ids: Dictionary = {}
	var effective_ids: Dictionary = {}
	for identity: String in ["primary", "reference"]:
		var world: Variant = worlds.get(identity)
		if not world is Dictionary or world.get("identity") != identity or not _true(world.get("actual_world_released_before_next")) or not world.get("roles") is Dictionary or world.roles.size() != 5 or not _whole_camera(world.get("camera"), 2): return "Incomplete real whole world " + identity
		for item: Array in [["world_node_instance_id", world_ids], ["viewport_instance_id", viewport_ids], ["world_3d_instance_id", effective_ids]]:
			var value: Variant = world.get(item[0])
			if not _integer(value, 1) or item[1].has(str(value)): return "Reused/missing actual World3D/viewport identity"
			item[1][str(value)] = true
		for binding: Array in [["authoritative_global_mesh", "terrain_mesh"], ["support_mesh", "deck_support_mesh"]]:
			var record: Variant = world.get(binding[0])
			if not record is Dictionary or record.get("path") != graph[binding[1]].path or not _same_hash(record.get("sha256"), graph[binding[1]].sha256): return "Whole world actual mesh differs from graph"
		var coverage: Variant = world.get("coverage")
		if not coverage is Dictionary or not _true(coverage.get("passed")) or not _true(coverage.get("entire_canvas_covered")) or not _positive(coverage.get("actual_receiver_vertices")) or not _positive(coverage.get("actual_caster_unique_draw_vertices_across_instances")) or not _num(coverage.get("shadow_max_actual_m"), 160) or not _nonnegative(coverage.get("max_actual_source_projection_error_px")) or float(coverage.max_actual_source_projection_error_px) > .01: return "Whole receiver/caster/shadow coverage failed"
		var guard: Dictionary = {}
		for candidate: Variant in guards:
			if candidate is Dictionary and candidate.get("world_identity") == identity:
				if not guard.is_empty(): return "Duplicate fresh memory guard"
				guard = candidate
		var guard_error := _guard_error(guard, history)
		if not guard_error.is_empty(): return guard_error
		for role: String in CAPTURE_ROLES:
			var record: Variant = world.roles.get(role)
			var factor: int = 2 if role in ["visual", "shadow_off"] else 1
			if not record is Dictionary or not _pair_eq(record.get("actual_native_canvas"), C.SIZE * factor) or not _whole_camera(record.get("frozen_camera_projection"), factor) or not _num(record.get("MSAA_3D_actual"), 0) or not _num(record.get("MSAA_2D_actual"), 0) or not record.get("passes") is Array or record.passes.size() != 2 or not record.get("windows") is Dictionary or record.windows.size() != 176: return "Incomplete5role64+112 actual draws " + identity + "/" + role
			if not _num(record.get("caster_shadow_setting_actual"), GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY) or typeof(record.get("caster_actual_visible")) != TYPE_BOOL or record.caster_actual_visible != (role == "visual") or typeof(record.get("water_actual_visible")) != TYPE_BOOL or record.water_actual_visible != (factor == 2) or typeof(record.get("support_actual_visible")) != TYPE_BOOL or record.support_actual_visible != (role == "walk"): return "Incorrect actual caster/water/support role"
			if not _num(record.get("terrain_actual_cast_shadow"), GeometryInstance3D.SHADOW_CASTING_SETTING_ON if factor == 2 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF): return "Visual ground shadow disabled or binary authority contaminated"
			for n in 2:
				var error := _pass_error(record.passes[n], identity + "_" + role + "_" + str(n), C.SIZE * factor)
				if not error.is_empty(): return error
			if float(record.passes[1].process_before) <= float(record.passes[0].process_after) or float(record.passes[1].fence_sequence) <= float(record.passes[0].fence_sequence): return "Repeat is not a later true whole draw"
			for id: String in expected_windows:
				var window: Variant = record.windows.get(id)
				if not window is Dictionary: return "Missing exact64+112 window " + identity + "/" + role + "/" + id
				var error := _roi_error(window, expected_windows[id], role, record, catalog)
				if not error.is_empty(): return error + " " + identity + "/" + role + "/" + id
	for role: String in CAPTURE_ROLES:
		for id: String in expected_windows:
			var primary: Dictionary = worlds.primary.roles[role].windows[id]
			var reference: Dictionary = worlds.reference.roles[role].windows[id]
			if primary.path == reference.path or primary.raw_path == reference.raw_path or not _rgba_equal(primary.path, reference.path) or not _rgba_equal(primary.raw_path, reference.raw_path): return "Independent whole worlds differ at same global coordinates " + role + "/" + id
	return ""

static func _authorization_error(report: Dictionary, catalog: Dictionary, graph: Dictionary) -> String:
	var reference: Variant = report.get("authorization")
	if not reference is Dictionary or not _bound(catalog, String(reference.get("path", ""))) or not _same_hash(reference.get("sha256"), catalog.get(reference.get("path"))): return "Actual root FULL authorization bytes absent"
	var auth := C.read_json(reference.path)
	if not _true(auth.get("approved")) or auth.get("scope") != PROTOCOL or not _true(auth.get("allow_full64")) or not _true(auth.get("memory_budget_approved")) or auth.get("builder_path") != BUILDER or not _same_hash(auth.get("builder_sha256"), graph.builder_script.sha256): return "PILOT/stale/unapproved execution authorization"
	var budget: Variant = auth.get("CPU_ROI_budget")
	if not budget is Dictionary or report.get("CPU_ROI_budget") != budget or not _num(budget.get("previous_pilot_pixels"), 8388608) or not _num(budget.get("maximum_pixels"), MAX_CPU_ROI_PIXELS) or not _pair_eq(budget.get("maximum_native_canvas"), Vector2(3456, 2432)) or not _pair_eq(budget.get("logical_tile"), Vector2(1536, 1024)) or not _num(budget.get("logical_halo_px"), 96) or not _num(budget.get("ssaa_scale"), 2) or not _num(budget.get("additional_pixels"), 16384) or not _num(budget.get("additional_RGBA_bytes"), 65536) or not _false(budget.get("whole_CPU_Image_allowed")): return "NEW maximum ROI budget not explicitly authorized; old pilot cannot inherit it"
	var inputs: Variant = auth.get("input_sha256")
	if not inputs is Dictionary or inputs.is_empty() or report.get("cached_inputs_sha256") != inputs: return "Missing actual immutable authoring inputs"
	for path: Variant in inputs:
		if not path is String or not _bound(catalog, path) or not _same_hash(inputs[path], catalog[path]): return "Execution authorization input differs from actual graph"
	var proof: Variant = auth.get("transport_proof")
	if not proof is Dictionary or proof.get("path") != TRANSPORT_PROOF or not _same_hash(proof.get("sha256"), TRANSPORT_PROOF_SHA): return "Execution did not bind actual ROOT094 transport proof"
	return ""

static func _expected_windows() -> Dictionary:
	var result: Dictionary = {}
	for row in 8:
		for col in 8:
			var id := "r%d_c%d" % [row, col]
			result[id] = [col * 1536, row * 1024, 1536, 1024]
			if col < 7: result[id + "--r%d_c%d" % [row, col + 1]] = [(col + 1) * 1536 - 16, row * 1024, 32, 1024]
			if row < 7: result[id + "--r%d_c%d" % [row + 1, col]] = [col * 1536, (row + 1) * 1024 - 16, 1536, 32]
	return result

static func _rgba_equal(first: String, second: String) -> bool:
	var a := Image.load_from_file(first)
	var b := Image.load_from_file(second)
	return a != null and b != null and a.get_size() == b.get_size() and a.get_format() == Image.FORMAT_RGBA8 and b.get_format() == Image.FORMAT_RGBA8 and a.get_data() == b.get_data()

static func _history_error(history: Dictionary, catalog: Dictionary) -> String:
	var origin := "res://build/world_map_v15_whole_framebuffer_memory/1791062610_2434323/"
	var result_sha := "635f79565e1258f077c47ab53ed5e22c235921896c48079dbdc695b5859cd6fe"
	var image_sha := "d9a06a25a2bd0394d86a2ba246cafe6b5229f8d64f0b0751277da131348a97e5"
	for binding: Array in [["result_path", "result_sha256", origin + "result.json", result_sha], ["square_PNG_path", "square_PNG_sha256", origin + "native_8192x8192_raw.png", image_sha], ["square_repeat_path", "square_repeat_sha256", origin + "native_8192x8192_raw_repeat.png", image_sha]]:
		if history.get(binding[0]) != binding[2] or not _same_hash(history.get(binding[1]), binding[3]) or not _bound(catalog, binding[2]) or not _same_hash(catalog[binding[2]], binding[3]): return "Historical square component bytes are not actual ROOT078"
	var original := C.read_json(origin + "result.json")
	if original.get("status") != "WHOLE_FRAMEBUFFER_ACTUAL_FAILED" or not _num(original.get("proposed_exit_code_not_external_OS_evidence"), 1) or original.get("executed_fixture_sha256") != "fa4a63b9e3413362e0eb14b3de97556fc4ddb82a9c1fa25f5ab06bbc4306c26a" or original.get("parent_fixture_sha256") != "73cc260391873fa7f167a8a29c0099b20b9375de787e90c88fd870dfc40100c7": return "Historical OS1/failed whole authority was rewritten"
	var square: Variant = original.get("square")
	var baseline: Variant = original.get("baseline")
	if not square is Dictionary or not baseline is Dictionary or not _true(square.get("passed")) or not _true(square.get("actual_viewport_node_released")) or not _true(square.get("raw_repeat_byte_exact")) or not _pair_eq(square.get("actual_raw_canvas"), Vector2(8192, 8192)) or not _true(baseline.get("valid")) or baseline.get("gpu_uuid") != history.get("gpu_uuid") or not _integer(baseline.get("vram_used_bytes"), 0) or not _integer(baseline.get("process_private_bytes"), 0): return "Invalid actual historical square memory baseline"
	var gpu_peak := 0.0
	var ram_peak := 0.0
	for key: String in ["allocated", "first_readback_memory", "two_readbacks_memory", "byte_comparison_peak_memory", "after_save_memory"]:
		var sample: Variant = square.get(key)
		if not sample is Dictionary or not _true(sample.get("valid")) or sample.get("gpu_uuid") != history.gpu_uuid or not _integer(sample.get("vram_used_bytes"), 0) or not _integer(sample.get("process_private_bytes"), 0): return "Missing actual square peak sample"
		gpu_peak = maxf(gpu_peak, float(sample.vram_used_bytes) - float(baseline.vram_used_bytes))
		ram_peak = maxf(ram_peak, float(sample.process_private_bytes) - float(baseline.process_private_bytes))
	if gpu_peak <= 0 or ram_peak <= 0 or not _num(history.get("vram_peak_delta_bytes"), gpu_peak) or not _num(history.get("process_peak_delta_bytes"), ram_peak): return "Historical whole estimate is not recomputed from actual square peaks"
	return ""

static func _guard_error(guard: Dictionary, history: Dictionary) -> String:
	if not _true(guard.get("passed")) or not _true(guard.get("allocation_requested_after_guard")) or guard.get("ROOT078_square_peak_bound") != history: return "Allocation lacks exact historical-bound fresh guard"
	var actual: Variant = guard.get("actual_fresh_queries")
	if not actual is Dictionary or not _true(actual.get("valid")) or actual.get("gpu_uuid") != history.get("gpu_uuid"): return "Missing/mismatched actual adapter query"
	if actual.get("stage") != String(guard.get("world_identity", "")) + "_immediately_before_whole_GPU_allocation" or not _num(actual.get("gpu_query_exit"), 0) or not _num(actual.get("host_query_exit"), 0) or not _integer(actual.get("ticks_usec_before_queries"), 0) or not _integer(actual.get("ticks_usec_after_queries"), 0) or float(actual.ticks_usec_after_queries) <= float(actual.ticks_usec_before_queries): return "No fresh successful read-only GPU/RAM query before allocation"
	for key: String in ["vram_peak_delta_bytes", "process_peak_delta_bytes"]:
		if not _integer(history.get(key), 1): return "Invalid actual8192square memory delta"
	var vram: float = float(history.vram_peak_delta_bytes) * 6 + 1073741824.0
	var ram: float = maxf(8589934592.0, float(history.process_peak_delta_bytes) * 6)
	if not _num(history.get("whole_pixel_to_square_ratio"), 6) or not _num(history.get("vram_requirement_bytes"), vram) or not _num(history.get("host_RAM_requirement_bytes"), ram) or not _num(guard.get("vram_required_bytes"), vram) or not _num(guard.get("host_RAM_required_bytes"), ram) or not _integer(actual.get("vram_free_bytes"), 0) or not _integer(actual.get("host_free_bytes"), 0) or float(actual.vram_free_bytes) < vram or float(actual.host_free_bytes) < ram: return "Insufficient actual whole memory budget"
	return ""

static func _whole_camera(value: Variant, factor: int) -> bool:
	if not value is Dictionary or not _num(value.get("projection"), Camera3D.PROJECTION_ORTHOGONAL) or not _num(value.get("keep_aspect"), Camera3D.KEEP_HEIGHT) or not _num(value.get("size_m"), 80) or not _pair_eq(value.get("whole_logical_canvas"), C.SIZE) or not _pair_eq(value.get("whole_visual_native_canvas"), C.SIZE * 2) or not _pair_eq(value.get("actual_current_GPU_canvas"), C.SIZE * factor) or not _pair_eq(value.get("source_center_px"), C.SIZE * .5) or not _num(value.get("PPM_X"), 102.4) or not _near(value.get("PPM_source_Z"), 102.4 * sqrt(.5)) or not _near(value.get("near"), .05) or not _num(value.get("far"), 200) or not _num(value.get("shadow_max_distance"), 160) or not _num(value.get("directional_shadow_mode"), DirectionalLight3D.SHADOW_ORTHOGONAL): return false
	var transform: Variant = value.get("transform")
	if not transform is Dictionary or not _triple_near(transform.get("origin"), Vector3(0, 60, 60)) or not transform.get("basis_columns") is Array or transform.basis_columns.size() != 3: return false
	var half := sqrt(.5)
	for i in 3:
		if not _triple_near(transform.basis_columns[i], [Vector3.RIGHT, Vector3(0, half, -half), Vector3(0, half, half)][i]): return false
	return _triple_near(value.get("light_rotation_degrees"), Vector3(-55, -34, 0)) and _near(value.get("light_energy"), .85) and _num(value.get("shadow_normal_bias"), 2)

static func _pass_error(value: Variant, expected_id: String, canvas: Vector2) -> String:
	if not value is Dictionary or value.get("id") != expected_id or not _true(value.get("fresh_actual_post_draw_observed")) or not _pair_eq(value.get("whole_native_canvas"), canvas) or not _num(value.get("frozen_update_mode"), SubViewport.UPDATE_DISABLED) or not _integer(value.get("texture_rid"), 1) or not _integer(value.get("viewport_rid"), 1) or not _integer(value.get("process_before"), 0) or not _integer(value.get("process_after"), 0) or float(value.process_after) <= float(value.process_before) or not value.get("post_draw_fences") is Array or value.post_draw_fences.size() != 8: return "Missing true whole UPDATE_ONCE/frame-post-draw identity"
	var sequence := -1.0
	var frame := -1.0
	for fence: Variant in value.post_draw_fences:
		if not fence is Dictionary or not _integer(fence.get("sequence"), 1) or float(fence.sequence) <= sequence or not _integer(fence.get("process_frame"), 0) or float(fence.process_frame) < frame or not _num(fence.get("update_request"), SubViewport.UPDATE_ONCE) or not _integer(fence.get("ticks_usec"), 0): return "Invalid actual fence order"
		sequence = float(fence.sequence)
		frame = float(fence.process_frame)
	if not _num(value.get("fence_sequence"), sequence): return "Whole draw final fence differs"
	return ""

static func _roi_error(record: Dictionary, rect: Array, role: String, native_role: Dictionary, catalog: Dictionary) -> String:
	var factor: int = 2 if role in ["visual", "shadow_off"] else 1
	var logical := Rect2i(int(rect[0]), int(rect[1]), int(rect[2]), int(rect[3]))
	var window := logical.grow(OVERSCAN_PX).intersection(Rect2i(Vector2i.ZERO, Vector2i(C.SIZE)))
	var raw_rect := Rect2i(window.position * factor, window.size * factor)
	if raw_rect.size.x * raw_rect.size.y > MAX_CPU_ROI_PIXELS: return "CPU ROI exceeds approved native bound"
	var crop := Rect2i(logical.position - window.position, logical.size)
	for index in 2:
		var current: Variant = record if index == 0 else record.get("repeat_transfer_evidence")
		if not current is Dictionary: return "Missing second actual GPU ROI transport"
		if not _rect_eq(current.get("logical_rect_px"), rect) or not _rect_eq(current.get("global_native_readback_rect_px"), _rect_array(raw_rect)) or not _rect_eq(current.get("logical_overscan_rect_px"), _rect_array(window)) or not _rect_eq(current.get("local_logical_crop_px"), _rect_array(crop)) or not _pair_eq(current.get("actual_readback_canvas"), Vector2(raw_rect.size)) or not _pair_eq(current.get("actual_whole_GPU_canvas"), C.SIZE * factor) or not _num(current.get("factor"), factor) or not _true(current.get("96px_kernel_halo_actual_boundaries_clipped_to_whole")) or not _false(current.get("gamma_correction")) or not _true(current.get("actual_transfer_view_released")): return "Wrong actual integer ROI96/crop/whole canvas"
		if current.get("resampling_identity") != ("OPAQUE_RGBA8_LANCZOS_ROI96_V1" if factor == 2 else "NONE_NATIVE_MSAA0") or current.get("source_draw") != native_role.passes[index] or not _num(current.get("source_primary_texture_rid"), native_role.passes[index].texture_rid) or not _integer(current.get("destination_texture_rid"), 1) or not _integer(current.get("actual_transfer_post_draw_fence_sequence"), 1) or float(current.actual_transfer_post_draw_fence_sequence) <= float(native_role.passes[index].fence_sequence): return "Actual transport draw/texture/fence mismatch"
		var transport: Variant = current.get("transfer_shader")
		if not transport is Dictionary or transport.get("path") != TRANSPORT or not _same_hash(transport.get("sha256"), TRANSPORT_SHA): return "Wrong actual texelFetch shader"
		var path := String(current.get("path", ""))
		var raw := String(current.get("raw_path", ""))
		if path == raw or not path.begins_with(ROOT) or not raw.begins_with(ROOT) or not _bound(catalog, path) or not _bound(catalog, raw) or not _same_hash(current.get("sha256"), catalog[path]) or not _same_hash(current.get("raw_sha256"), catalog[raw]) or not _png_size(path, logical.size) or not _png_size(raw, raw_rect.size): return "Missing actual raw/logical PNG identities"
		var original := Image.load_from_file(raw)
		var actual := Image.load_from_file(path)
		if original == null or actual == null or original.get_format() != Image.FORMAT_RGBA8 or actual.get_format() != Image.FORMAT_RGBA8 or original.has_mipmaps() or actual.has_mipmaps(): return "Not actual original RGBA8 data"
		if not _same_hash(current.get("raw_RGBA_sha256"), _bytes_sha(original.get_data())) or not _same_hash(current.get("logical_RGBA_sha256"), _bytes_sha(actual.get_data())): return "Decoded original RGBA identity differs"
		var pixels := original.get_data()
		if factor == 1:
			# ROOT111:108 adversarial cases/540 assertions prove the combined
			# original RGB-binary AND A255 predicate exactly, including alpha254.
			# Native word counts retain all original RGBA bytes; no conversion,
			# threshold, detect_alpha() or pixel tolerance is used.
			var words := pixels.to_int32_array()
			var count := original.get_width() * original.get_height()
			if pixels.size() != count * 4 or words.size() != count or words.count(-16777216) + words.count(-1) != count: return "Nonopaque/nonbinary original authority; no threshold allowed"
		else:
			for n in range(3, pixels.size(), 4):
				if pixels[n] != 255: return "Nonopaque actual capture pixel"
		if factor == 2: original.resize(window.size.x, window.size.y, Image.INTERPOLATE_LANCZOS)
		if original.get_region(crop).get_data() != actual.get_data(): return "Actual bounded ROI96 Lanczos/native crop RGBA mismatch"
	if record.path == record.get("repeat_path") or record.raw_path == record.get("raw_repeat_path") or record.get("repeat_path") != record.repeat_transfer_evidence.path or record.get("raw_repeat_path") != record.repeat_transfer_evidence.raw_path or not _same_hash(catalog.get(record.path), catalog.get(record.repeat_path)) or not _same_hash(catalog.get(record.raw_path), catalog.get(record.raw_repeat_path)): return "True distinct raw/logical repeat differs"
	return ""

static func _bytes_sha(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256) != OK or hash.update(bytes) != OK: return ""
	return hash.finish().hex_encode()

static func _rect_array(rect: Rect2i) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

static func _integer(value: Variant, minimum: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= minimum and floorf(float(value)) == float(value)

static func _nonnegative(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) >= 0

static func _near(value: Variant, expected: float) -> bool:
	# Float32 camera geometry only; NEVER used for pixel/PNG/SHA comparisons.
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and absf(float(value) - expected) <= .0001

static func _triple_near(value: Variant, expected: Vector3) -> bool:
	return value is Array and value.size() == 3 and _near(value[0], expected.x) and _near(value[1], expected.y) and _near(value[2], expected.z)

static func _seams(source: Dictionary, manifest: Dictionary, catalog: Dictionary, graph: Dictionary) -> String:
	var authored: Variant = source.get("seams")
	var captured: Variant = manifest.get("seams")
	if not authored is Array or authored.size() != 112 or not captured is Array or captured.size() != 112: return "Exactly 112 authored and independent captured seams required"
	var expected: Dictionary = {}
	for row in 8:
		for col in 8:
			var from := "r%d_c%d" % [row, col]
			if col < 7: expected[from + "--r%d_c%d" % [row, col + 1]] = {"from": from, "to": "r%d_c%d" % [row, col + 1], "vertical": true, "rect": [(col + 1) * 1536 - 16, row * 1024, 32, 1024]}
			if row < 7: expected[from + "--r%d_c%d" % [row + 1, col]] = {"from": from, "to": "r%d_c%d" % [row + 1, col], "vertical": false, "rect": [col * 1536, (row + 1) * 1024 - 16, 1536, 32]}
	var source_ids: Dictionary = {}
	for record: Variant in authored:
		if not record is Dictionary or not record.get("id") is String or not expected.has(record.id) or source_ids.has(record.id): return "Unknown/duplicate authored seam"
		source_ids[record.id] = record
	var seen: Dictionary = {}
	for record: Variant in captured:
		if not record is Dictionary or not record.get("id") is String or not expected.has(record.id) or seen.has(record.id): return "Unknown/duplicate actual seam"
		var id: String = record.id
		seen[id] = true
		var edge: Dictionary = expected[id]
		var original: Dictionary = source_ids[id]
		for entry: Dictionary in [record, original]:
			if entry.get("from") != edge.from or entry.get("to") != edge.to or typeof(entry.get("vertical")) != TYPE_BOOL or entry.vertical != edge.vertical: return "Wrong actual seam neighbors " + id
		if record.get("classification") not in ["open", "blocked"] or record.get("classification") != original.get("classification") or not record.get("projected_witnesses") is Array or record.projected_witnesses.is_empty() or record.projected_witnesses != original.get("projected_witnesses"): return "Missing/different actual seam navigation witnesses " + id
		for witness: Variant in record.projected_witnesses:
			if not witness is Dictionary: return "Malformed actual seam witness " + id
			if record.classification == "open":
				if not _pair(witness.get("from_px")) or not _pair(witness.get("to_px")): return "Missing actual open seam feet " + id
			else:
				if not _pair(witness.get("foot_px")): return "Missing actual blocked seam feet " + id
		var reference: Variant = record.get("independent_reference_capture")
		if not reference is Dictionary: return "Missing independent actual seam capture " + id
		if reference.get("capture_role") != "reference" or reference.get("window_id") != id: return "Seam reference is not independent whole draw"
		var capture_error := _capture_window_error(reference, edge.rect, catalog, graph)
		if not capture_error.is_empty(): return capture_error + " seam " + id
		if record.get("comparison_status") != "ACTUAL_ALL_FIVE_ROLE_RGBA_EXACT" or not record.get("compared_byte_difference") is Dictionary or record.compared_byte_difference.size() != CAPTURE_ROLES.size(): return "Missing exact actual seam comparison " + id
		for kind: String in CAPTURE_ROLES:
			var path: String = String(reference.get(kind + "_path", ""))
			var difference: Variant = record.compared_byte_difference.get(kind)
			if not difference is Dictionary or not _true(difference.get("byte_exact")) or not _num(difference.get("different_bytes"), 0) or not _num(difference.get("maximum_delta"), 0) or not _num(difference.get("tolerance"), 0) or not _pair_eq(difference.get("canvas"), Vector2(float(edge.rect[2]), float(edge.rect[3]))) or not _same_hash(difference.get("a_RGBA_sha256"), difference.get("b_RGBA_sha256")) or not _same_hash(difference.get("b_RGBA_sha256"), reference.roles[kind].get("logical_RGBA_sha256")): return "Actual seam difference record is not all-RGBA exact " + id + "/" + kind
			if not path.begins_with(ROOT + "seams/") or not _seam_pixels_match(edge, path, kind): return "Actual original/reference RGBA seam mismatch " + id + "/" + kind
	return ""

static func _seam_pixels_match(edge: Dictionary, path: String, kind: String) -> bool:
	var reference := Image.load_from_file(path)
	var from := Image.load_from_file(ROOT + "chunks/" + String(edge.from) + "_" + kind + ".png")
	var to := Image.load_from_file(ROOT + "chunks/" + String(edge.to) + "_" + kind + ".png")
	if reference == null or from == null or to == null or from.get_size() != C.TILE_SIZE or to.get_size() != C.TILE_SIZE: return false
	for image: Image in [reference, from, to]: image.convert(Image.FORMAT_RGBA8)
	var expected := Image.create(int(edge.rect[2]), int(edge.rect[3]), false, Image.FORMAT_RGBA8)
	if edge.vertical:
		expected.blit_rect(from, Rect2i(1520, 0, 16, 1024), Vector2i.ZERO)
		expected.blit_rect(to, Rect2i(0, 0, 16, 1024), Vector2i(16, 0))
	else:
		expected.blit_rect(from, Rect2i(0, 1008, 1536, 16), Vector2i.ZERO)
		expected.blit_rect(to, Rect2i(0, 0, 1536, 16), Vector2i(0, 16))
	return reference.get_size() == expected.get_size() and reference.get_data() == expected.get_data()

static func _portals(source: Dictionary, catalog: Dictionary) -> String:
	var semantics := C.read_json(ROOT + "landmark_semantics.json")
	var records: Variant = semantics.get("landmarks")
	if not records is Dictionary: return "Missing measured landmark semantics"
	var portals: Variant = source.get("portals")
	var objects: Variant = source.get("objects")
	if not portals is Array or portals.size() != 16 or not objects is Array: return "Incomplete entity/doorway contract"
	for object: Variant in objects:
		if not object is Dictionary: return "Malformed independent object"
		if not _pair(object.get("pos")) or not _pair(object.get("render_size_px")) or not _positive(object.render_size_px[0]) or not _positive(object.render_size_px[1]): return "Invalid actual object render transform"
		var texture := String(object.get("texture", ""))
		if not texture.begins_with(ROOT) or not _bound(catalog, texture): return "Unbound actual object texture " + texture
		if not object.has("solid_polygons_px"): continue
		if not object.solid_polygons_px is Array or object.solid_polygons_px.is_empty(): return "Missing measured multi-solid geometry " + String(object.get("id", ""))
		for polygon: Variant in object.solid_polygons_px:
			if not _polygon(polygon): return "Invalid measured solid polygon " + String(object.get("id", ""))
			for point: Array in polygon:
				if point[0] < 0 or point[1] < 0 or point[0] >= C.SIZE.x or point[1] >= C.SIZE.y: return "Solid outside world " + String(object.get("id", ""))
	for raw: Variant in portals:
		if not raw is Dictionary: return "Invalid doorway record"
		var id := String(raw.get("id", ""))
		var measured: Variant = records.get(id)
		if not measured is Dictionary or measured.get("status") != "MEASURED_ACTUAL_SOURCE": return "Not an actual measured doorway " + id
		var original := String(raw.get("source", ""))
		if not _bound(catalog, original) or not _same_hash(raw.get("source_sha256"), catalog[original]) or measured.get("source") != original or not _same_hash(measured.get("source_sha256"), catalog[original]): return "Stale measured original source " + id
		if not _pair(raw.get("source_doorstep_uv")) or raw.source_doorstep_uv != measured.get("source_doorstep_uv") or not _pair(raw.get("door_foot_px")) or not _pair(raw.get("source_XZ_foot_px")): return "Doorway/source measurement mismatch " + id
		var uv := Vector2(float(raw.source_doorstep_uv[0]), float(raw.source_doorstep_uv[1]))
		if uv.x < 0 or uv.y < 0 or uv.x > 1 or uv.y > 1: return "Outside source doorway UV " + id
		if not _polygon(raw.get("interaction_polygon_px")) or not _polygon(raw.get("passage_polygon_px")) or not _pair(raw.get("approach_direction")): return "Missing actual doorway passage " + id
		if raw.get("auto_trigger", false) != false: return "V15 doorway must use explicit player interaction " + id
		var approach := Vector2(float(raw.approach_direction[0]), float(raw.approach_direction[1]))
		if not is_equal_approx(approach.length(), 1.0): return "Undefined doorway approach direction " + id
		var path: Variant = raw.get("passage_path_px")
		if not path is Array or path.size() < 2: return "Missing actual full-foot passage path " + id
		var has_door := false
		for point: Variant in path:
			if not _pair(point): return "Nonfinite actual passage path " + id
			if point == raw.door_foot_px: has_door = true
		if not has_door: return "Passage path misses actual visible doorway " + id
		var compound := String(raw.get("compound_id", ""))
		var found := false
		for object: Variant in objects:
			if not object is Dictionary or object.get("id") != compound: continue
			if found: return "Duplicate doorway compound " + id
			found = true
			var runtime := String(object.get("texture", ""))
			if not runtime.begins_with(ROOT + "entities/") or not _bound(catalog, runtime) or not _same_hash(catalog[runtime], catalog[original]) or not _same_hash(object.get("source_sha256"), catalog[original]): return "Runtime original-alpha copy differs " + id
			# The authored measurement remains an exact original double-array
			# record. The captured object first constructs a native Vector2 and
			# then writes its components with the default JSON codec.
			if not _json_native_exact(object.get("foot_uv"), [uv.x, uv.y]): return "Runtime foot is not measured visible doorway " + id
			if not object.has("solid_polygons_px"): return "Doorway compound has no measured solids " + id
			if not _true(object.get("sort_by_feet")) or object.get("centered", true) != true or not _num(object.get("rotation", 0), 0): return "Compound render does not match measured centered/Y-sorted contract " + id
			var center := Vector2(float(object.pos[0]), float(object.pos[1])) * C.SIZE
			var render_size := Vector2(float(object.render_size_px[0]), float(object.render_size_px[1]))
			var expected_foot := center + (uv - Vector2(.5, .5)) * render_size
			var door := Vector2(float(raw.door_foot_px[0]), float(raw.door_foot_px[1]))
			if expected_foot.distance_to(door) > .01: return "Doorway is not the actual source-to-render transform " + id
			if not _json_native_exact(object.get("depth_sort_foot_y"), door.y / C.SIZE.y): return "Compound depth line is not actual visible foot " + id
		if not found: return "Missing independent doorway compound " + id
	return ""

static func _literal_dependencies(path: String, graph: Dictionary, catalog: Dictionary) -> String:
	# Close literal preload/shader/material dependencies as well as the owner's
	# declared graph. Missing declared input files are not silently accepted.
	var expression := RegEx.new()
	if expression.compile("['\"](res://[^'\"]+)['\"]") != OK: return "Cannot validate executed source dependencies"
	for match: RegExMatch in expression.search_all(FileAccess.get_file_as_string(path)):
		var dependency := match.get_string(1)
		if dependency.get_extension() not in ["gd", "gdshader", "gltf", "glb", "png", "jpg", "jpeg", "tres"]: continue
		if dependency.begins_with("res://build/"): continue
		if not graph.has(dependency) or not _bound(catalog, dependency): return "Unbound executed literal dependency " + path + " -> " + dependency
	return ""

static func _spacing(source: Dictionary) -> String:
	var cores: Variant = source.get("core_landmarks")
	if not cores is Array or cores.size() != 9: return "Missing nine actual projected core positions including Mingwu"
	var ids: Array[String] = []
	for entry: Variant in cores:
		if not entry is Dictionary or String(entry.get("id", "")) not in CORE_IDS or String(entry.id) in ids or not _pair(entry.get("center_px")) or not _pair(entry.get("door_foot_px")): return "Invalid actual core position"
		ids.append(String(entry.id))
		var portal: Dictionary = {}
		for candidate: Dictionary in source.portals:
			if candidate.id == entry.id: portal = candidate
		if portal.is_empty() or portal.door_foot_px != entry.door_foot_px: return "Core spacing measured from different doorway " + String(entry.id)
		var compound: Dictionary = {}
		for object: Variant in source.get("objects", []):
			if object is Dictionary and object.get("id") == portal.get("compound_id"):
				if not compound.is_empty(): return "Duplicate actual core compound " + String(entry.id)
				compound = object
		if compound.is_empty() or not _pair(compound.get("pos")): return "Missing actual core compound " + String(entry.id)
		var actual_center := Vector2(float(compound.pos[0]), float(compound.pos[1])) * C.SIZE
		# Replay the builder's center construction before normalized-pos storage.
		# Reading normalized doubles into Vector2 and multiplying back can add
		# one Float32 ULP; that is not the originally captured center authority.
		if not _pair(compound.get("world_foot_px")) or not _pair(compound.get("foot_uv")) or not _pair(compound.get("render_size_px")): return "Core captured center inputs absent " + String(entry.id)
		var captured_foot := Vector2(compound.world_foot_px[0], compound.world_foot_px[1])
		var captured_uv := Vector2(compound.foot_uv[0], compound.foot_uv[1])
		var captured_size := Vector2(compound.render_size_px[0], compound.render_size_px[1])
		var captured_center := captured_foot - (captured_uv - Vector2(.5,.5)) * captured_size
		if not _json_native_exact(entry.center_px, [captured_center.x, captured_center.y]) or actual_center.distance_to(captured_center) > .01: return "Core center does not bind actual rendered compound " + String(entry.id)
	for i in cores.size():
		for j in range(i + 1, cores.size()):
			for key: String in ["center_px", "door_foot_px"]:
				var a := Vector2(float(cores[i][key][0]), float(cores[i][key][1]))
				var b := Vector2(float(cores[j][key][0]), float(cores[j][key][1]))
				if a.distance_to(b) < 3072: return "Actual core spacing < 3072px " + String(cores[i].id) + "/" + String(cores[j].id)
	return ""

static func _routes(source: Dictionary) -> String:
	var routes: Variant = source.get("routes")
	if not routes is Array or routes.is_empty(): return "Missing unambiguous actual route network"
	var ids: Dictionary = {}
	for route: Variant in routes:
		if not route is Dictionary: return "Malformed route"
		var id := String(route.get("id", ""))
		var points: Variant = route.get("points_px")
		if id.is_empty() or ids.has(id) or not points is Array or points.size() < 2 or not _positive(route.get("width_px")): return "Invalid/duplicate route " + id
		ids[id] = true
		for point: Variant in points:
			if not _pair(point): return "Nonfinite route point " + id
	return ""

static func _review(source: Dictionary, _manifest: Dictionary, catalog: Dictionary) -> String:
	var review := C.read_json(REVIEW)
	if not _num(review.get("schema_version"), 1) or not _num(review.get("version"), 15) or review.get("capture_protocol") != PROTOCOL or review.get("scope") != REVIEW_SCOPE or review.get("reviewer_role") != "producer/root" or review.get("review_method") != "actual_png_individual_review" or not _true(review.get("visual_approved")) or String(review.get("reviewer", "")).strip_edges().is_empty(): return "Independent producer actual-image review absent"
	if not _same_hash(review.get("source_sha256"), FileAccess.get_sha256(SOURCE_PATH)) or not _same_hash(review.get("manifest_sha256"), FileAccess.get_sha256(MANIFEST_PATH)): return "Producer review does not bind current source/manifest"
	if review.get("whole_capture_report_path") != REPORT_PATH or not _bound(catalog, REPORT_PATH) or not _same_hash(review.get("whole_capture_report_sha256"), catalog[REPORT_PATH]): return "Producer review does not bind actual current whole capture report"
	var images: Variant = review.get("reviewed_assets_sha256")
	if not images is Dictionary: return "Missing individual reviewed image hashes"
	var required: Array[String] = [String(source.overview_path)]
	for chunk: Dictionary in source.chunks: required.append(String(chunk.visual_path))
	for object: Dictionary in source.objects: required.append(String(object.get("texture", "")))
	for portal: Dictionary in source.portals:
		# The captured PENDING status is immutable evidence, not the approval
		# channel. Only this independently SHA-bound root review can approve it.
		var door_error: String = door_review_error(portal, review, catalog)
		if not door_error.is_empty(): return door_error
		var image := String(portal.get("doorstep_review_image_path", ""))
		required.append(image)
	for path: String in required:
		if not _bound(catalog, path) or not _same_hash(images.get(path), catalog[path]): return "Producer has not reviewed current image " + path
	if not reviewed_spawn_px(source, review).is_finite(): return "Missing/invalid independently authored default spawn; invalid explicit source spawn cannot fall back"
	return ""

static func door_review_error(portal: Dictionary, review: Dictionary, catalog: Dictionary) -> String:
	# Exact sixteen keys; unknown/extra/missing doors never inherit approval.
	var doors: Variant = review.get("doors")
	if not doors is Dictionary or doors.size() != C.PORTAL_IDS.size(): return "Independent review requires exactly sixteen doorway approvals"
	for key: Variant in doors:
		if not key is String or key not in C.PORTAL_IDS: return "Unknown independent reviewed doorway " + str(key)
	var id: String = String(portal.get("id", ""))
	var approval: Variant = doors.get(id)
	if not approval is Dictionary or approval.get("status") != "APPROVED": return "Unreviewed independent doorway " + id
	var original: String = String(portal.get("source", ""))
	var image: String = String(portal.get("doorstep_review_image_path", ""))
	if approval.get("source") != original or not _bound(catalog, original) or not _same_hash(portal.get("source_sha256"), catalog[original]) or not _same_hash(approval.get("source_sha256"), catalog[original]): return "Independent door review original source differs " + id
	if approval.get("compound_id") != portal.get("compound_id") or not _same_pair_values(approval.get("source_doorstep_uv"), portal.get("source_doorstep_uv")) or not _same_pair_values(approval.get("door_foot_px"), portal.get("door_foot_px")): return "Independent door review compound/UV/actual foot differs " + id
	if approval.get("doorstep_review_image_path") != image or not _bound(catalog, image) or not _same_hash(portal.get("doorstep_review_image_sha256"), catalog[image]) or not _same_hash(approval.get("doorstep_review_image_sha256"), catalog[image]): return "Independent doorway review PNG is missing/stale " + id
	return _negative_review_error(portal, approval, catalog)

static func _negative_review_error(portal: Dictionary, approval: Dictionary, catalog: Dictionary) -> String:
	# These are authored test intentions, not claims of navigation/physics/input
	# success. Actual FULL QA must still run all three mechanisms on every door.
	var id: String = String(portal.get("id", ""))
	var probes: Variant = approval.get("input_negative_probes")
	if not probes is Array or probes.size() != 3: return "Exactly three independently reviewed input negatives required " + id
	if portal.has("input_negative_probes"):
		# Explicit malformed, empty or unreviewed source records cannot fall back
		# to independent invented records or silently inherit the new origin.
		if approval.get("negative_origin") != CAPTURED_NEGATIVE_ORIGIN or not portal.input_negative_probes is Array or probes != portal.input_negative_probes: return "Captured source negatives must bind exact original records " + id
	elif approval.get("negative_origin") != NEGATIVE_ORIGIN:
		return "Missing source negatives require explicit independent root authorship " + id
	if approval.get("negative_source_footprint_path") != NEGATIVE_FOOTPRINTS or not _bound(catalog, NEGATIVE_FOOTPRINTS) or not _same_hash(approval.get("negative_source_footprint_sha256"), catalog[NEGATIVE_FOOTPRINTS]) or not _same_hash(catalog[NEGATIVE_FOOTPRINTS], FileAccess.get_sha256(NEGATIVE_FOOTPRINTS)): return "Negative source footprint is missing/stale " + id
	var footprints: Dictionary = C.read_json(NEGATIVE_FOOTPRINTS)
	var landmarks: Variant = footprints.get("landmarks")
	if not _num(footprints.get("schema_version"), 15) or not landmarks is Dictionary: return "Malformed actual source footprint registry " + id
	var measured: Variant = landmarks.get(id)
	if not measured is Dictionary or measured.get("source") != portal.get("source") or not _same_hash(measured.get("source_sha256"), portal.get("source_sha256")) or measured.get("compound_id") != portal.get("compound_id") or not _same_pair_values(measured.get("source_doorstep_uv"), portal.get("source_doorstep_uv")): return "Negative footprint/source/compound/door UV differs " + id
	var original: String = String(portal.get("source", ""))
	var original_size: Variant = measured.get("source_size_px")
	if not _pair(original_size) or not _positive(original_size[0]) or not _positive(original_size[1]) or not _num(original_size[0], floor(float(original_size[0]))) or not _num(original_size[1], floor(float(original_size[1]))) or not _png_size(original, Vector2i(int(original_size[0]), int(original_size[1]))) or not _same_hash(FileAccess.get_sha256(original), measured.get("source_sha256")): return "Negative original PNG actual dimensions/bytes differ " + id
	var kinds: Dictionary = {}
	for probe: Variant in probes:
		if not probe is Dictionary: return "Malformed reviewed negative record " + id
		var kind: Variant = probe.get("kind")
		if not kind is String or kind not in ["wall_approach", "roof_click", "wrongside"] or kinds.has(kind) or probe.get("semantic_review_status") != "APPROVED": return "Negative requires three distinct reviewed mechanisms " + id
		kinds[kind] = true
		var stand_key: String = "legal_start_px" if kind == "wall_approach" else "legal_stand_px"
		var target_key: String = "blocked_foot_px" if kind == "wall_approach" else "world_click_px"
		if not _world_pair_in_domain(probe.get(stand_key)) or not _world_pair_in_domain(probe.get(target_key)): return "Negative world point is nonfinite/outside actual canvas " + id + "/" + kind
		if _same_pair_values(probe[stand_key], probe[target_key]): return "Negative stand and target must be distinct " + id + "/" + kind
		if kind == "roof_click":
			var uv: Variant = probe.get("source_uv")
			if not _pair(uv) or float(uv[0]) < 0 or float(uv[1]) < 0 or float(uv[0]) >= 1 or float(uv[1]) >= 1: return "Roof negative requires actual original-image UV inside pixel domain " + id
	return ""

static func _world_pair_in_domain(value: Variant) -> bool:
	return _pair(value) and float(value[0]) >= 0 and float(value[1]) >= 0 and float(value[0]) < C.SIZE.x and float(value[1]) < C.SIZE.y

static func reviewed_spawn_px(source: Dictionary, review: Dictionary) -> Vector2:
	# An existing invalid authored field is an error, never permission to select
	# another point. Only absence permits the single independently reviewed policy.
	if source.has("player_spawn_px"):
		var explicit: Variant = source.get("player_spawn_px")
		if not _pair(explicit): return Vector2(INF, INF)
		var point := Vector2(float(explicit[0]), float(explicit[1]))
		return point if _spawn_in_domain(point) else Vector2(INF, INF)
	var declaration: Variant = review.get("default_spawn")
	if not declaration is Dictionary or not _true(declaration.get("approved")) or declaration.get("policy") != "EXACT_REVIEWED_LINXI_DOOR_V1" or declaration.get("portal_id") != "linxi_village": return Vector2(INF, INF)
	var portals: Variant = source.get("portals")
	if not portals is Array: return Vector2(INF, INF)
	var selected: Dictionary = {}
	for portal: Variant in portals:
		if not portal is Dictionary: return Vector2(INF, INF)
		if portal.get("id") != "linxi_village": continue
		if not selected.is_empty(): return Vector2(INF, INF)
		selected = portal
	if selected.is_empty() or not _same_pair_values(declaration.get("foot_px"), selected.get("door_foot_px")): return Vector2(INF, INF)
	var doors: Variant = review.get("doors")
	if not doors is Dictionary or not doors.get("linxi_village") is Dictionary or doors.linxi_village.get("status") != "APPROVED" or not _same_pair_values(doors.linxi_village.get("door_foot_px"), selected.door_foot_px): return Vector2(INF, INF)
	var point := Vector2(float(selected.door_foot_px[0]), float(selected.door_foot_px[1]))
	return point if _spawn_in_domain(point) else Vector2(INF, INF)

static func _same_pair_values(first: Variant, second: Variant) -> bool:
	return _pair(first) and _pair(second) and _num(first[0], float(second[0])) and _num(first[1], float(second[1]))

static func _spawn_in_domain(point: Vector2) -> bool:
	return point.is_finite() and point.x >= 0 and point.y >= 0 and point.x < C.SIZE.x and point.y < C.SIZE.y

static func _all_art(directory: String) -> Array[String]:
	var result: Array[String] = []
	var access := DirAccess.open(directory)
	if access == null: return result
	for file: String in access.get_files():
		if file.get_extension().to_lower() in ["png", "jpg", "jpeg", "rf", "gltf", "glb", "bin", "gdshader", "res", "json"] and directory.path_join(file) != MANIFEST_PATH: result.append(directory.path_join(file))
	for subdir: String in access.get_directories(): result.append_array(_all_art(directory.path_join(subdir)))
	return result

static func _asset_path(value: String) -> bool:
	return value.begins_with("res://") and not ".." in value and not value.ends_with(".import") and value != MANIFEST_PATH and value != REVIEW

static func _hash(value: Variant) -> bool:
	if not value is String or value.length() != 64: return false
	for c: String in value.to_lower():
		if not c in "0123456789abcdef": return false
	return true

static func _same_hash(a: Variant, b: Variant) -> bool:
	return _hash(a) and _hash(b) and String(a).to_lower() == String(b).to_lower()

static func _bound(catalog: Dictionary, path: String) -> bool:
	return _asset_path(path) and _hash(catalog.get(path)) and FileAccess.file_exists(path)

static func _num(value: Variant, expected: float) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == expected

static func _positive(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) > 0

static func _true(value: Variant) -> bool: return typeof(value) == TYPE_BOOL and value == true
static func _false(value: Variant) -> bool: return typeof(value) == TYPE_BOOL and value == false

static func _pair(value: Variant) -> bool:
	return value is Array and value.size() == 2 and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value[0])) and is_finite(float(value[1]))

static func _pair_eq(value: Variant, expected: Vector2) -> bool: return _pair(value) and _num(value[0], expected.x) and _num(value[1], expected.y)

static func _quad(value: Variant) -> bool:
	if not value is Array or value.size() != 4: return false
	for element: Variant in value:
		if not typeof(element) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(element)): return false
	return true

static func _rect_eq(value: Variant, expected: Array) -> bool:
	if not _quad(value): return false
	for i in 4:
		if not _num(value[i], expected[i]): return false
	return true

static func _polygon(value: Variant) -> bool:
	if not value is Array or value.size() < 3: return false
	var points := PackedVector2Array()
	for point: Variant in value:
		if not _pair(point): return false
		points.append(Vector2(float(point[0]), float(point[1])))
	return not Geometry2D.triangulate_polygon(points).is_empty()

static func _camera(value: Variant) -> bool:
	if not value is Dictionary or not _num(value.get("projection"), Camera3D.PROJECTION_ORTHOGONAL) or not _positive(value.get("size")): return false
	var position: Variant = value.get("position")
	var basis: Variant = value.get("basis_columns")
	if not position is Array or position.size() != 3 or not basis is Array or basis.size() != 3: return false
	for row: Variant in [position, basis[0], basis[1], basis[2]]:
		if not row is Array or row.size() != 3: return false
		for component: Variant in row:
			if not typeof(component) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(component)): return false
	return true

static func _png_size(path: String, expected: Vector2i) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < 24 or file.get_buffer(8) != PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10]): return false
	file.big_endian = true
	return file.get_32() == 13 and file.get_buffer(4).get_string_from_ascii() == "IHDR" and file.get_32() == expected.x and file.get_32() == expected.y

static func _imported_authority_current(path: String) -> bool:
	# Raw SHA validation alone cannot catch a stale same-path .ctex import.
	# Compare the authoritative base level, retaining RGB and alpha, without
	# retaining all 64 decoded masks or modifying any importer settings.
	if not FileAccess.file_exists(path + ".import") or not ResourceLoader.exists(path): return false
	var texture := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	if texture == null: return false
	var imported := texture.get_image()
	var raw := Image.load_from_file(path)
	if imported == null or raw == null or imported.get_size() != C.TILE_SIZE or raw.get_size() != C.TILE_SIZE: return false
	if imported.is_compressed() and imported.decompress() != OK: return false
	if raw.is_compressed() and raw.decompress() != OK: return false
	imported.convert(Image.FORMAT_RGBA8)
	raw.convert(Image.FORMAT_RGBA8)
	var base_bytes := C.TILE_SIZE.x * C.TILE_SIZE.y * 4
	return imported.get_data().slice(0, base_bytes) == raw.get_data().slice(0, base_bytes)

# V7 is a genuinely different source/caster recipe. No v6 image or minY model
# evidence may be relabelled as a camera plane. These checks never approve art.
static func _v7_revision_error(source: Dictionary, catalog: Dictionary, graph: Dictionary) -> String:
	_v7_tiles.clear()
	_v7_tile_order.clear()
	_v7_plane_validation.clear()
	for path: String in EXACT_V7_INPUTS:
		if not _bound(catalog, path) or not _same_hash(catalog[path], EXACT_V7_INPUTS[path]) or not _same_hash(FileAccess.get_sha256(path), EXACT_V7_INPUTS[path]): return "Unbound current v7 execution dependency " + path
	if source.get("art_revision") != "complete_v7_coherent_whole" or source.get("pixel_sampling") != "round_world_pixel" or not _num(source.get("physical_navigation_margin_px"), 0): return "Wrong v7 authoring/pixel/margin identity"
	var evidence: Variant = source.get("v7_revision_evidence")
	if not evidence is Dictionary or not evidence.get("ecology") is Dictionary or not _num(evidence.ecology.get("visual_material_map_step_px"), 4): return "Missing actual v7 4px visual ownership recipe"
	var auth_reference: Dictionary = _report.get("authorization", {})
	var auth: Dictionary = C.read_json(String(auth_reference.get("path", "")))
	var review_error: String = _v7_regional_error(auth.get("regional_visual_review"), evidence.get("regional_approval"), catalog)
	if not review_error.is_empty(): return review_error
	var shader: Variant = _report.get("actual_terrain_shader")
	if not shader is Dictionary or shader.get("path") != TERRAIN_SHADER or not _bound(catalog, TERRAIN_SHADER) or not _same_hash(shader.get("sha256"), graph.terrain_shader.sha256) or shader.get("source_script") != SURFACE_PATH or not _same_hash(shader.get("source_script_sha256"), EXACT_V7_INPUTS[SURFACE_PATH]): return "V7 actual shader is not saved from the executed new surface"
	var receiver_source := ECOLOGY.new()
	var rf: PackedByteArray = FileAccess.get_file_as_bytes(String(graph.height_rf.path))
	if rf.size() != 1537 * 1025 * 4: return "V7 actual Float32 RF byte count changed"
	receiver_source.heights = rf.to_float32_array()
	var objects: Array[Dictionary] = []
	var native: Dictionary = {}
	for raw: Variant in source.get("objects", []):
		if not raw is Dictionary: return "Malformed v7 independent body"
		objects.append(raw)
		if not raw.has("kind") or raw.get("kind") not in ["tree", "bamboo", "herb", "boulder"]: continue
		var id: String = String(raw.get("id", ""))
		if id.is_empty() or native.has(id): return "Duplicate actual v7 native instance " + id
		native[id] = raw
		var body_error: String = _v7_body_error(raw, catalog, receiver_source)
		if not body_error.is_empty(): return body_error
	if native.is_empty(): return "V7 independent native body population absent"
	var counts: Variant = evidence.ecology.get("actual_registered_counts")
	if not counts is Dictionary or counts.size() != 4: return "V7 source population count identity missing"
	var actual_counts := {"tree":0,"bamboo":0,"herb":0,"boulder":0}
	for id: String in native: actual_counts[native[id].kind] += 1
	if not _equal_exact_value(counts,actual_counts): return "Actual independent bodies disagree with authored v7 population"
	var union: Dictionary = receiver_source.measure_v7_alpha_union(objects)
	if not _true(union.get("passed")) or not _json_native_exact(evidence.get("actual_alpha_union"), union) or not _json_native_exact(_report.get("alpha_union"), union): return "Actual four-region source PNG alpha union does not bind FULL capture"
	if not union.get("regions") is Array or union.regions.size() != 4: return "Exactly four v7 source alpha regions required"
	for region: Variant in union.regions:
		if not region is Dictionary or not _true(region.get("passed")) or not _num(region.get("alpha_threshold_byte"), 30) or not _num(region.get("minimum_exclusive"), .08) or not _positive(region.get("actual_union_fraction")) or float(region.actual_union_fraction) <= .08: return "V7 alpha union must strictly exceed8%, not a stem-count proxy"
	for identity: String in ["primary", "reference"]:
		var world: Dictionary = _report.worlds[identity]
		var casters: Variant = world.get("casters")
		if not casters is Array: return "Missing per-id actual v7 world caster records"
		var seen: Dictionary = {}
		for record: Variant in casters:
			if not record is Dictionary or not record.get("id") is String or not native.has(record.id) or seen.has(record.id): return "Unknown/duplicate actual caster " + identity
			seen[record.id] = true
			var caster_error: String = _v7_caster_error(native[record.id], record, catalog, receiver_source)
			if not caster_error.is_empty(): return caster_error + " " + identity
		if seen.size() != native.size(): return "Each independent sourcebody needs its own actual caster transform in both worlds"
	var captured_planes: Array = []
	for caster: Dictionary in _report.worlds.reference.casters:
		if caster.get("identity") != "V7_ACTUAL_PROTOTYPE_RGBA_CAMERA_PLANE_CASTER_SOURCE_ONLY": continue
		var original_record: Dictionary = caster.duplicate(true)
		for key: String in ["id","kind","pose","source_foot_px","transform","shadow_on_enum","sourcebody_baked"]: original_record.erase(key)
		captured_planes.append(original_record)
	if not _equal_exact_value(captured_planes,evidence.get("actual_plane_casters")): return "V7 source plane evidence is not the actual reference-world mesh records"
	return ""

static func _v7_regional_error(review: Variant, source_review: Variant, catalog: Dictionary) -> String:
	if not review is Dictionary or not _equal_exact_value(review, source_review) or not _true(review.get("approved")) or review.get("approved_by") != "root" or review.get("scope") != REGIONAL_SCOPE: return "Missing independent current v7 regional root approval"
	var path: String = String(review.get("result_path", ""))
	if not path.begins_with("res://build/world_map_v15_coherent_whole_v7_regional/") or not _bound(catalog, path) or not _same_hash(review.get("result_sha256"), catalog[path]): return "Regional approval lost actual result identity"
	var result := C.read_json(path)
	if result.get("scope") != REGIONAL_SCOPE or result.get("status") != "REGIONAL_TECHNICAL_PASS_NOT_FULL_OR_FIELD" or not _true(result.get("input_hashes_unchanged_after")) or not result.get("alpha_union") is Dictionary or not _true(result.alpha_union.get("passed")): return "A source-only forecast cannot replace actual regional capture"
	var executed: Variant = result.get("executed_builder")
	var pins: Variant = result.get("cached_inputs_sha256")
	if not executed is Dictionary or executed.get("path") != REGIONAL_BUILDER or not _same_hash(executed.get("sha256"), EXACT_V7_INPUTS[REGIONAL_BUILDER]) or not pins is Dictionary: return "Regional actual executor source mismatch"
	for dependency: String in [ECOLOGY_PATH, SURFACE_PATH, CASTER_PATH, BUILDER, REGIONAL_BUILDER]:
		if not _same_hash(pins.get(dependency), EXACT_V7_INPUTS[dependency]): return "Regional proof belongs to another source revision " + dependency
	var regions: Variant = result.get("regions")
	if not regions is Array or regions.size() != 4: return "Four actual regional native captures required beforeFULL"
	var expected := {"northeastern_forest":[9460,1690,1536,1024], "southern_bamboo":[2450,6370,1536,1024], "wet_bank":[9870,5840,1536,1024], "bianzhou_bridge_end":[6960,1820,1536,1024]}
	var seen: Dictionary = {}
	for region: Variant in regions:
		if not region is Dictionary or not expected.has(region.get("id")) or seen.has(region.id) or not _rect_eq(region.get("logical_rect_px"), expected[region.id]): return "Unknown/duplicate actual regional canvas"
		seen[region.id] = true
		var shadow: Variant = region.get("actual_shadow_evidence")
		if not shadow is Dictionary or not _positive(shadow.get("outside_sourcebody_pixels")): return "Regional shadowON/OFF contains no genuine outside-body shadow"
		var composite: Variant = region.get("independent_body_scene")
		if not composite is Dictionary or not _actual_saved_file(composite): return "Regional independent-body composite is missing/current SHA differs"
		var worlds: Variant = region.get("worlds")
		if not worlds is Dictionary or worlds.size() != 2: return "Regional native two-world evidence missing"
		var identities: Dictionary = {}
		for identity: String in ["primary", "reference"]:
			var world: Variant = worlds.get(identity)
			if not world is Dictionary or not _true(world.get("actual_world_released_before_next")) or not _integer(world.get("world_3d_instance_id"), 1) or identities.has(str(world.world_3d_instance_id)) or not world.get("roles") is Dictionary or world.roles.size() != 5: return "Regional proof reuses or misses a realWorld3D"
			identities[str(world.world_3d_instance_id)] = true
			for role: String in CAPTURE_ROLES:
				var record: Variant = world.roles.get(role)
				if not record is Dictionary or not record.get("passes") is Array or record.passes.size() != 2 or not record.get("windows") is Dictionary or record.windows.size() != 1 or not record.windows.get("region") is Dictionary: return "Incomplete actual bounded native regional roles/draws"
				var frame: Dictionary = record.windows.region
				for binding: Array in [["path","sha256"],["raw_path","raw_sha256"]]:
					if not _actual_saved_file({"path":frame.get(binding[0]), "sha256":frame.get(binding[1])}): return "Regional current raw/logical bytes changed"
				if not frame.get("repeat_transfer_evidence") is Dictionary: return "Regional second real native draw missing"
				var repeated: Dictionary = frame.repeat_transfer_evidence
				for binding: Array in [["path","sha256"],["raw_path","raw_sha256"]]:
					if not _actual_saved_file({"path":repeated.get(binding[0]),"sha256":repeated.get(binding[1])}) or not _rgba_equal(String(frame[binding[0]]), String(repeated[binding[0]])): return "Regional exact native repeat was lost"
		if region.id == "bianzhou_bridge_end" and (not region.get("actual_full17_approach") is Dictionary or not _true(region.actual_full17_approach.get("passed"))): return "New WORLD Bianzhou approach was not actually checked"
	return ""

static func _actual_saved_file(record: Dictionary) -> bool:
	var path: Variant = record.get("path")
	return path is String and _asset_path(path) and _same_hash(record.get("sha256"), FileAccess.get_sha256(path))

static func _v7_body_error(body: Dictionary, catalog: Dictionary, rf_source: ECOLOGY) -> String:
	var id: String = String(body.get("id", ""))
	if not _integer(body.get("pose"), 0) or float(body.pose) > 2: return "Unknown native source pose " + id
	var metadata_path: String = ROOT + "entities/" + id + ".json"
	if not _bound(catalog, metadata_path) or not _equal_exact_value(body, C.read_json(metadata_path)): return "Independent instance metadata differs " + id
	var prototype: Variant = body.get("prototype_actual_sourcebody_evidence")
	if not prototype is Dictionary or not prototype.get("texture") is String or not _bound(catalog, prototype.texture) or not _same_hash(catalog[prototype.texture], catalog.get(body.texture)): return "Instance body is not original prototype PNG bytes " + id
	var origin: Variant = prototype.get("sourcebody_capture_origin")
	var key: String = String(body.kind) + str(int(body.get("pose", -1)))
	var original_path: String = "res://art/maps/world_map_v15_complete_v5/prototypes/native_" + key + ".json"
	if not origin is Dictionary or origin.get("scope") != "BYTE_EXACT_FROZEN_SAME_POSE_CACHE_REUSE_NOT_NEW_BODY_RENDER" or origin.get("original_metadata_path") != original_path or not _bound(catalog, original_path) or not _same_hash(origin.get("original_metadata_sha256"), catalog[original_path]): return "V7 body original used-index evidence is missing " + id
	var original_metadata := C.read_json(original_path)
	var original_copy: String = ROOT + "prototypes/native_" + key + "_original_metadata.json"
	if origin.get("original_metadata_copy_path") != original_copy or not _bound(catalog, original_copy) or not _same_hash(catalog[original_copy],catalog[original_path]): return "V7 body changed original source metadata bytes " + id
	for field: String in ["foot_uv","render_size_px","basis_columns","support_m","used_vertex_bounds_m"]:
		if not _equal_exact_value(prototype.get(field), original_metadata.get(field)): return "V7 body original source geometry was rewritten " + id + "/" + field
	var image := Image.load_from_file(String(body.texture))
	if image == null or not _pair(prototype.get("foot_uv")) or not _pair_eq(body.get("render_size_px"), Vector2(image.get_size())) or not _same_pair_values(body.get("render_size_px"), prototype.get("render_size_px")): return "V7 body changed original foot/1:1 canvas " + id
	# Replay the actual Float32 Vector2 source->foot->UV calculation exactly.
	# JSON original fractions are not silently compared as rounded native UVs.
	var original_foot := Vector2(float(prototype.foot_uv[0]) * image.get_width(), float(prototype.foot_uv[1]) * image.get_height())
	var reconstructed_uv: Vector2 = original_foot / Vector2(image.get_size())
	if not _json_native_exact(body.get("foot_uv"), [reconstructed_uv.x, reconstructed_uv.y]): return "V7 body UV differs from actual native source-foot construction " + id
	if not _world_pair_in_domain(body.get("source_XZ_foot_px")) or not _pair(body.get("world_foot_px")) or not _pair(body.get("pos")) or not _pair_eq(body.get("walkability_margin_px"), Vector2.ZERO) or not _true(body.get("sort_by_feet")): return "V7 body lost explicit independent foot/depth/margin " + id
	var source_foot := Vector2(body.source_XZ_foot_px[0], body.source_XZ_foot_px[1])
	var height: float = rf_source.triangle_height(source_foot)
	var foot := Vector2(source_foot.x, source_foot.y - height * 102.4 * sqrt(.5))
	if not _json_native_exact(body.get("actual_ground_m"), height) or not _json_native_exact(body.world_foot_px, [foot.x, foot.y]) or not _json_native_exact(body.get("depth_sort_foot_y"), foot.y / C.SIZE.y): return "V7 body foot does not bind actual current RF " + id
	var render_origin := Vector2(body.pos[0], body.pos[1]) * C.SIZE - Vector2(image.get_size()) * .5
	var actual_foot := render_origin + Vector2(body.foot_uv[0], body.foot_uv[1]) * Vector2(image.get_size())
	if actual_foot.distance_to(foot) > .01: return "V7 measured alpha foot is not actual placed body " + id
	if id.begins_with("v7_") and body.kind in ["tree", "bamboo"]:
		var expected := Vector2(18,14) if body.kind == "tree" else Vector2(12,10)
		if body.get("v7_caster_recipe") != "NEW actual measured-foot RGBA camera plane" or not _true(body.get("blocking")) or not _pair_eq(body.get("collision_size_px"), expected) or not _json_native_exact(body.get("collision_size"), [expected.x / C.SIZE.x, expected.y / C.SIZE.y]) or not _json_native_exact(body.get("collision_center_world_px"), [foot.x, foot.y]): return "New stem collider/caster identity differs " + id
		for offset: Vector2 in _shoe_offsets():
			if not _v7_nav_white(foot + offset, "raw_walk"): return "New stem lacks all17 genuine ground support " + id
	return ""

static func _v7_caster_error(body: Dictionary, record: Dictionary, catalog: Dictionary, rf_source: ECOLOGY) -> String:
	var id: String = String(body.id)
	if record.get("id") != id or record.get("kind") != body.kind or not _num(record.get("pose"), float(body.pose)) or not _same_pair_values(record.get("source_foot_px"), body.source_XZ_foot_px) or not _false(record.get("sourcebody_baked")) or not _num(record.get("shadow_on_enum"), GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY): return "Actual per-id caster identity differs " + id
	var path: String = String(record.get("actual_draw_mesh_path", ""))
	if not _bound(catalog, path) or not _same_hash(record.get("actual_draw_mesh_sha256"), catalog[path]): return "Unbound actual caster mesh " + id
	if not id.begins_with("v7_") or body.kind not in ["tree", "bamboo"]:
		var original: Variant = body.get("sourcebody_capture_origin")
		if not original is Dictionary or path != original.get("actual_GPU_loaded_mesh_path") or not _same_hash(catalog[path], original.get("actual_GPU_loaded_mesh_sha256")) or not _equal_exact_value(record.get("transform"), body.get("actual_model_transform")): return "Original 3D caster silently replaced or lost used-index support " + id
		var prototype: Dictionary = body.prototype_actual_sourcebody_evidence
		var support: Variant = prototype.get("support_m")
		var bounds: Variant = prototype.get("used_vertex_bounds_m")
		if not support is Array or support.size() != 3 or not bounds is Array or bounds.size() != 2 or not bounds[0] is Array or bounds[0].size() != 3 or not _num(support[1],float(bounds[0][1])) or not _equal_exact_value(record.get("support_m"),support): return "Original native used-index minY support no longer binds its own geometry " + id
		return ""
	var prototype_uv := Vector2(body.prototype_actual_sourcebody_evidence.foot_uv[0],body.prototype_actual_sourcebody_evidence.foot_uv[1])
	if record.get("identity") != "V7_ACTUAL_PROTOTYPE_RGBA_CAMERA_PLANE_CASTER_SOURCE_ONLY" or not _num(record.get("actual_draw_vertices"), 4) or not _num(record.get("actual_draw_indices"), 6) or not _num(record.get("actual_triangles"), 2) or not _num(record.get("actual_surface_count"), 1) or not _json_native_exact(record.get("actual_foot_uv"), [prototype_uv.x, prototype_uv.y]) or not _same_pair_values(record.get("logical_canvas_px"), body.render_size_px): return "New plane cannot inherit original GLTF minY proof " + id
	var original_path: String = String(body.prototype_actual_sourcebody_evidence.texture)
	if record.get("actual_sourcebody_path") != original_path or not _same_hash(record.get("actual_sourcebody_sha256"), catalog[original_path]): return "New plane source is not actual body prototype " + id
	var p := Vector2(body.source_XZ_foot_px[0], body.source_XZ_foot_px[1])
	var ground: Vector3 = rf_source.point3(p, rf_source.triangle_height(p))
	if not _triple_near(record.get("world_foot_m"), ground) or not record.get("transform") is Dictionary or not _triple_near(record.transform.get("origin"), ground): return "New plane instance is not at its own actual RF foot " + id
	var basis: Variant = record.transform.get("basis_columns")
	if not basis is Array or basis.size() != 3 or not _triple_near(basis[0],Vector3.RIGHT) or not _triple_near(basis[1],Vector3.UP) or not _triple_near(basis[2],Vector3.BACK): return "New plane instance transform changed its exact camera-plane geometry " + id
	# Per-instance identity/RF/transform checks above are never cached. Identical
	# serialized mesh+PNG+UV+arrays/material proof may be verified once per pose.
	var signature: Dictionary = {"mesh":catalog[path],"source":catalog[original_path],"uv":record.get("actual_foot_uv"),"size":record.get("logical_canvas_px"),"vertex":record.get("native_stored_vertex_sha256"),"normal":record.get("native_stored_normal_sha256"),"tex_uv":record.get("native_stored_uv_sha256"),"indices":record.get("native_stored_index_sha256"),"material":record.get("actual_material_properties")}
	if _v7_plane_validation.has(path) and _equal_exact_value(_v7_plane_validation[path],signature): return ""
	var mesh := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	if mesh == null or mesh.get_surface_count() != 1 or mesh.surface_get_primitive_type(0) != Mesh.PRIMITIVE_TRIANGLES: return "Actual saved plane geometry missing " + id
	var arrays: Array = mesh.surface_get_arrays(0)
	var uv: Vector2 = prototype_uv
	var canvas := Vector2(body.render_size_px[0], body.render_size_px[1])
	var texcoords := PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)])
	var positions := PackedVector3Array()
	var normals := PackedVector3Array()
	for t: Vector2 in texcoords:
		var screen := Vector2((t.x-uv.x)*canvas.x,(uv.y-t.y)*canvas.y)
		positions.append(Vector3.RIGHT*(screen.x/102.4)+Vector3(0,sqrt(.5),-sqrt(.5))*(screen.y/102.4))
		normals.append(Vector3(0,sqrt(.5),sqrt(.5)))
	var indices := PackedInt32Array([0,1,2,1,3,2])
	for binding: Array in [[Mesh.ARRAY_VERTEX,positions,"native_stored_vertex_sha256"],[Mesh.ARRAY_NORMAL,normals,"native_stored_normal_sha256"],[Mesh.ARRAY_TEX_UV,texcoords,"native_stored_uv_sha256"],[Mesh.ARRAY_INDEX,indices,"native_stored_index_sha256"]]:
		if typeof(arrays[binding[0]]) != typeof(binding[1]) or arrays[binding[0]].to_byte_array() != binding[1].to_byte_array() or not _same_hash(record.get(binding[2]), _bytes_sha(arrays[binding[0]].to_byte_array())): return "Actual two-triangle plane arrays differ " + id
	var material := mesh.surface_get_material(0) as StandardMaterial3D
	if material == null or material.albedo_texture == null or material.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR or not _near(material.alpha_scissor_threshold,.12) or material.cull_mode != BaseMaterial3D.CULL_DISABLED or material.texture_filter != BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC or material.shading_mode != BaseMaterial3D.SHADING_MODE_UNSHADED: return "Actual plane alpha/material/sampler changed " + id
	var material_record: Variant = record.get("actual_material_properties")
	if not material_record is Dictionary or not _num(material_record.get("transparency"),material.transparency) or not _near(material_record.get("alpha_scissor_threshold"),material.alpha_scissor_threshold) or not _num(material_record.get("cull_mode"),material.cull_mode) or not _num(material_record.get("texture_filter"),material.texture_filter) or not _num(material_record.get("shading_mode"),material.shading_mode): return "Actual plane material record differs from serialized current resource " + id
	var embedded := material.albedo_texture.get_image()
	var original_image := Image.load_from_file(original_path)
	if embedded == null or original_image == null: return "Actual plane embedded PNG sampler missing " + id
	if embedded.is_compressed() and embedded.decompress() != OK: return "Cannot decode actual plane sampler " + id
	if original_image.generate_mipmaps() != OK or embedded.get_format() != original_image.get_format() or embedded.get_size() != original_image.get_size() or embedded.get_data() != original_image.get_data(): return "Actual plane mip sampler differs from original PNG bytes " + id
	_v7_plane_validation[path] = signature
	return ""

static func _json_native_exact(saved: Variant, native_expected: Variant) -> bool:
	# Match the unchanged capture writer's DEFAULT stringify/parse numeric
	# representation exactly. This is not an epsilon, Vector2 cast of saved
	# data, full-precision alternate codec, or a waiver of any PNG/RF/SHA check.
	# Callers must replay the actual builder operations before this boundary.
	return _equal_exact_value(saved, JSON.parse_string(JSON.stringify(native_expected, "\t")))

static func _equal_exact_value(a: Variant, b: Variant) -> bool:
	if typeof(a) in [TYPE_INT,TYPE_FLOAT] and typeof(b) in [TYPE_INT,TYPE_FLOAT]: return is_finite(float(a)) and is_finite(float(b)) and float(a) == float(b)
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equal_exact_value(a[key],b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not _equal_exact_value(a[i],b[i]): return false
		return true
	return a == b

static func _shoe_offsets() -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in 16: result.append(Vector2(cos(TAU*i/16.)*10,sin(TAU*i/16.)*6))
	result.append(Vector2.ZERO)
	return result

static func _v7_nav_white(point: Vector2, kind: String = "walk") -> bool:
	if not point.is_finite(): return false
	var pixel := Vector2i(roundi(point.x),roundi(point.y))
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= C.SIZE.x or pixel.y >= C.SIZE.y: return false
	var cell := Vector2i(pixel.x/C.TILE_SIZE.x,pixel.y/C.TILE_SIZE.y)
	var path := ROOT + "chunks/r%d_c%d_%s.png" % [cell.y,cell.x,kind]
	if not _v7_tiles.has(path):
		var image := Image.load_from_file(path)
		if image == null or image.get_size() != C.TILE_SIZE or image.get_format() != Image.FORMAT_RGBA8: return false
		_v7_tiles[path] = image
	_v7_tile_order.erase(path)
	_v7_tile_order.append(path)
	while _v7_tile_order.size() > 12: _v7_tiles.erase(_v7_tile_order.pop_front())
	var image: Image = _v7_tiles[path]
	var local := pixel - cell*C.TILE_SIZE
	return image.get_pixel(local.x,local.y) == Color.WHITE

static func safe_source_foot(source: Dictionary, point: Vector2) -> bool:
	# Independent publication preflight only, not Physics2D or runtime adoption.
	for offset: Vector2 in _shoe_offsets():
		var sample := point + offset
		if not _v7_nav_white(sample): return false
		for object: Dictionary in source.get("objects", []):
			if object.has("solid_polygons_px"):
				for raw: Array in object.solid_polygons_px:
					var polygon := PackedVector2Array()
					for pair: Array in raw: polygon.append(Vector2(pair[0],pair[1]))
					if Geometry2D.is_point_in_polygon(sample,polygon): return false
				continue
			if not object.get("blocking",false) or not _pair(object.get("collision_size_px")) or not _pair(object.get("collision_center_world_px")): continue
			var size := Vector2(object.collision_size_px[0],object.collision_size_px[1])
			var center := Vector2(object.collision_center_world_px[0],object.collision_center_world_px[1])
			if Rect2(center-size*.5,size).has_point(sample): return false
		for blocker: Dictionary in source.get("blockers", []):
			if not _pair(blocker.get("pos")) or not _pair(blocker.get("size")): return false
			var center := Vector2(blocker.pos[0],blocker.pos[1])*C.SIZE
			var size := Vector2(blocker.size[0],blocker.size[1])*C.SIZE
			if Rect2(center-size*.5,size).has_point(sample): return false
	return true
