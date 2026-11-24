extends RefCounted
## NEW independent V9C authority; derived geometry is READ ONLY here.
## No derive(), ResourceSaver, output edits, re-siting or old navigation credit.
## ROOT/state methods are mechanical copies; pure BASE predicates are SHA-pinned.
## A pilot, copied strip or unbound same-sized image is never a FULL candidate.
const C = preload("res://scripts/world/world_map_v15_contract.gd")
const FROZEN_SOURCE_SHA := "PENDING_FINAL_V9C_WORLD_ART"
const FROZEN_MANIFEST_SHA := "PENDING_FINAL_V9C_WORLD_ART"
const ROOT := "res://art/maps/world_map_v15_complete_v9c/"
const BUILDER := "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd"
const TERRAIN_SHADER := ROOT + "capture/v9c_actual_terrain_shader.gdshader"
const OVERSCAN_PX := 96
const REVIEW := "res://data/maps/world_map_v15_complete_v9c_visual_review.json"
const REVIEW_SCOPE := "ACTUAL_CURRENT_CAPTURE_VISUAL_REVIEW_NOT_FIELD_INPUT_APPROVAL"
const NEGATIVE_ORIGIN := "INDEPENDENT_ROOT_REVIEW_AUTHORED_NEGATIVES_V1"
const CAPTURED_NEGATIVE_ORIGIN := "CAPTURED_SOURCE_INPUT_NEGATIVES_EXACT_V1"
const NEGATIVE_FOOTPRINTS := "res://data/maps/world_map_v15_complete_v5_landmark_footprints_candidate.json"
const CORE_IDS := ["huashan", "luoyang", "bianzhou", "gufeng", "wudang", "xiangzhou", "jinling", "lingyue", "mingwu"]
const SOURCE_PATH := "res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST_PATH := ROOT + "art_contract.json"
const REPORT_PATH := ROOT + "whole_actual_capture.json"
const PROTOCOL := "COHERENT_WHOLE_FIXED_CAMERA_DERIVED_RF_V9C_FULL64_112_V1"
const TRANSPORT := "res://shaders/world_v15_native_texel_transfer.gdshader"
const TRANSPORT_SHA := "4997274fc2a62404235a69117785448c2ec65cc50667a4353d27c456d33ec47e"
const TRANSPORT_PROOF := "res://build/world_map_v15_native_texel_transfer/1791066200_2454361/result.json"
const TRANSPORT_PROOF_SHA := "53896c2af42ce245cadee635c4b2eb7b1d2dbfbae54c6845259931fc1e668de8"
const MAX_CPU_ROI_PIXELS := 8404992 # Root-approved NEW full interior ROI; pilot stays8388608.
const CAPTURE_ROLES := ["visual", "shadow_off", "land", "raw_walk", "walk"]
const ROLES := ["authoring_source_script", "source_script", "source_assembly_script", "builder_script", "surface_script", "selector_script", "terrain_shader", "height_rf", "landmark_semantics", "camera_contract", "transport_shader", "transport_proof", "terrain_mesh", "source_topology", "deck_support_mesh", "whole_capture_report", "geometry_helper", "derivation_report"]
const ECOLOGY_PATH := "res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_ecology_source.gd"
const SURFACE_PATH := "res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_surface.gd"
const CASTER_PATH := "res://scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd"
const REGIONAL_BUILDER := "res://scripts/dev/build_world_map_v15_coherent_whole_v9c_regional_proposal.gd"
const ECOLOGY = preload("res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_ecology_source.gd")
const BASE_PATH := "res://scripts/dev/world_map_v15_complete_v7_publication_gate_proposal.gd"
const BASE_SHA := "636769e29d745655d8adddaef67460498c1f646c5a79dcd01b362363a554491b"
const BASE = preload("res://scripts/dev/world_map_v15_complete_v7_publication_gate_proposal.gd")
const V7_ECOLOGY_PATH := "res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd"
const V7_SURFACE_PATH := "res://scripts/dev/world_map_v15_complete_v7_surface_proposal.gd"
const V7_FULL_PATH := "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd"
const V7_REGIONAL_PATH := "res://scripts/dev/build_world_map_v15_coherent_whole_v7_regional_proposal.gd"
const V7_ECOLOGY = preload("res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd")
const SURFACE = preload("res://scripts/dev/world_map_v15_v9c_visual_quality_proposal_surface.gd")
const GEOMETRY_HELPER_PATH := "res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v3.gd"
const GEOMETRY_HELPER_SHA := "34b30d35a4d3fe0349407ceada274ecf077010340d57741f80f38c82e2fabdf0"
const PROTECTION_V2 = preload("res://scripts/dev/world_map_v15_v9c_derived_geometry_helper_v2.gd")
const BASELINE_GEOMETRY = preload("res://scripts/dev/world_map_v15_v9c_derived_geometry_helper.gd")
const DERIVED_PREFIX := "res://build/world_map_v15_v9c_visual_quality_proposal/"
const REGIONAL_SCOPE := "V9C_TWO_FRESH_WHOLE_WORLDS_FIVE_REGIONAL_ROIS_NOT_FULL_OR_FIELD"
const REGIONAL_STATUS := "V9C_REGIONAL_TWO_WORLD_FIVE_ROLE_REPEAT_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_NOT_FULL"
const EXACT_INPUTS := {
 ECOLOGY_PATH:"9599af1cd080f0b32c90ff99158c7451b74cc3a82b6eea0fcbf30fa7782fb872",
 SURFACE_PATH:"d14e792202263186423751b030151eb2238cfa82ff00e2080ce859206f9f9627",
 CASTER_PATH:"d2d3795942aa452a18abc006d45bcde44749ccad276a7ec16e0f897604611290",
 GEOMETRY_HELPER_PATH:GEOMETRY_HELPER_SHA,
 BUILDER:"PENDING_ROOT_FROZEN_V9C_FULL_EXECUTOR",
 REGIONAL_BUILDER:"PENDING_ROOT_FROZEN_V9C_REGIONAL_EXECUTOR",
 BASELINE_GEOMETRY.BASELINE_SOURCE:BASELINE_GEOMETRY.BASELINE_PINS[BASELINE_GEOMETRY.BASELINE_SOURCE],
 BASELINE_GEOMETRY.BASELINE_MANIFEST:BASELINE_GEOMETRY.BASELINE_PINS[BASELINE_GEOMETRY.BASELINE_MANIFEST],
 BASELINE_GEOMETRY.BASELINE_RF:BASELINE_GEOMETRY.BASELINE_PINS[BASELINE_GEOMETRY.BASELINE_RF],
 BASELINE_GEOMETRY.BASELINE_MESH:BASELINE_GEOMETRY.BASELINE_PINS[BASELINE_GEOMETRY.BASELINE_MESH],
 BASELINE_GEOMETRY.BASELINE_SELECTOR:BASELINE_GEOMETRY.BASELINE_PINS[BASELINE_GEOMETRY.BASELINE_SELECTOR],
 BASELINE_GEOMETRY.BASELINE_SUPPORT:BASELINE_GEOMETRY.BASELINE_PINS[BASELINE_GEOMETRY.BASELINE_SUPPORT],
 PROTECTION_V2.ORIGINAL_HELPER_PATH:PROTECTION_V2.ORIGINAL_HELPER_SHA,
 "res://scripts/dev/test_world_v15_native_combined_rgba_word_stats_unit.gd":"f5ffe7adf8e9155f19fcd8640da51724605152dfe8bc1d3875789a8688d82608",
 "res://build/world_v15_native_binary_stats_unit/1791073994_1612124/result.json":"dde934b08ceacef6a887547c28af6296a0d6a2d5e9719b20775048582493c7e9"
}
static var _report: Dictionary = {}
static var _v7_tiles: Dictionary = {}
static var _v7_tile_order: Array[String] = []
static var _v7_plane_validation: Dictionary = {}

static var _v9c_material_signature: Dictionary = {}
static var _v9c_spare_material_signature: Dictionary = {}

static func validate(source: Dictionary, manifest: Dictionary) -> String:
	_report = {}
	if FileAccess.get_sha256(BASE_PATH).to_lower() != BASE_SHA: return "Pinned pure-predicate BASE changed"
	if not _same_hash(FROZEN_SOURCE_SHA, FileAccess.get_sha256(SOURCE_PATH)) or not _same_hash(FROZEN_MANIFEST_SHA, FileAccess.get_sha256(MANIFEST_PATH)): return "Whole V9C source/manifest PENDING; no candidate publication"
	if not _equal_exact_value(source, C.read_json(SOURCE_PATH)) or not _equal_exact_value(manifest, C.read_json(MANIFEST_PATH)): return "Arguments do not bind current pinned V9C source/manifest JSON"
	if source.get("art_revision") != "complete_v9c_coherent_whole" or manifest.get("art_revision") != "complete_v9c_coherent_whole": return "Current V9C art revision identity missing"
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
	var actual_shadow_total: int = 0
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
		var shadow: Variant = raw.get("ground_shadow")
		if not shadow is Dictionary or not _integer(shadow.get("outside_sourcebody_pixels"), 0) or not _bound(catalog, String(shadow.get("sourcebody_union_path", ""))) or not _bound(catalog, String(shadow.get("ground_shadow_path", ""))): return "Missing actual full-canvas ground shadow evidence " + id
		actual_shadow_total += int(shadow.outside_sourcebody_pixels)
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
	if actual_shadow_total <= 0 or not _num(manifest.get("outside_sourcebody_shadow_pixels"), actual_shadow_total): return "Actual FULL outside-body shadow total must be positive and exact; zero regional observations cannot substitute"
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
	if report.get("capture_protocol") != PROTOCOL or report.get("scope") != "V9C_FULL64_112SEAMS_DERIVED_RF_NEW_PROTOCOL_NOT_FORMAL_APPROVED" or report.get("status") != "V9C_FULL64_112SEAMS_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_FIELD_REVIEW" or not _false(report.get("whole_cpu_image_requested")) or not _false(report.get("whole_cpu_image_allowed")): return "PILOT/incomplete/wholeCPU capture cannot be published"
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
	return BASE._expected_windows()

static func _rgba_equal(first: String, second: String) -> bool:
	return BASE._rgba_equal(first, second)

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
	return BASE._guard_error(guard, history)

static func _whole_camera(value: Variant, factor: int) -> bool:
	return BASE._whole_camera(value, factor)

static func _pass_error(value: Variant, expected_id: String, canvas: Vector2) -> String:
	return BASE._pass_error(value, expected_id, canvas)

static func _roi_error(record: Dictionary, rect: Array, role: String, native_role: Dictionary, catalog: Dictionary, actual_root: String = ROOT) -> String:
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
		if path == raw or not path.begins_with(actual_root) or not raw.begins_with(actual_root) or not _bound(catalog, path) or not _bound(catalog, raw) or not _same_hash(current.get("sha256"), catalog[path]) or not _same_hash(current.get("raw_sha256"), catalog[raw]) or not _png_size(path, logical.size) or not _png_size(raw, raw_rect.size): return "Missing actual raw/logical PNG identities"
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
	return BASE._bytes_sha(bytes)

static func _rect_array(rect: Rect2i) -> Array:
	return BASE._rect_array(rect)

static func _integer(value: Variant, minimum: float) -> bool:
	return BASE._integer(value, minimum)

static func _nonnegative(value: Variant) -> bool:
	return BASE._nonnegative(value)

static func _near(value: Variant, expected: float) -> bool:
	return BASE._near(value, expected)

static func _triple_near(value: Variant, expected: Vector3) -> bool:
	return BASE._triple_near(value, expected)

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
	return BASE._spacing(source)

static func _routes(source: Dictionary) -> String:
	return BASE._routes(source)

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
	if FileAccess.get_sha256(BASE_PATH).to_lower() != BASE_SHA: return "Pinned pure-predicate BASE changed"
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
	return BASE._world_pair_in_domain(value)

static func reviewed_spawn_px(source: Dictionary, review: Dictionary) -> Vector2:
	if FileAccess.get_sha256(BASE_PATH).to_lower() != BASE_SHA: return Vector2(INF, INF)
	return BASE.reviewed_spawn_px(source, review)

static func _same_pair_values(first: Variant, second: Variant) -> bool:
	return BASE._same_pair_values(first, second)

static func _spawn_in_domain(point: Vector2) -> bool:
	return BASE._spawn_in_domain(point)

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
	return BASE._hash(value)

static func _same_hash(a: Variant, b: Variant) -> bool:
	return BASE._same_hash(a, b)

static func _bound(catalog: Dictionary, path: String) -> bool:
	return _asset_path(path) and _hash(catalog.get(path)) and FileAccess.file_exists(path)


static func _num(value: Variant, expected: float) -> bool:
	return BASE._num(value, expected)

static func _positive(value: Variant) -> bool:
	return BASE._positive(value)

static func _true(value: Variant) -> bool:
	return BASE._true(value)

static func _false(value: Variant) -> bool:
	return BASE._false(value)

static func _pair(value: Variant) -> bool:
	return BASE._pair(value)

static func _pair_eq(value: Variant, expected: Vector2) -> bool:
	return BASE._pair_eq(value, expected)

static func _quad(value: Variant) -> bool:
	return BASE._quad(value)

static func _rect_eq(value: Variant, expected: Array) -> bool:
	return BASE._rect_eq(value, expected)

static func _polygon(value: Variant) -> bool:
	return BASE._polygon(value)

static func _camera(value: Variant) -> bool:
	return BASE._camera(value)

static func _png_size(path: String, expected: Vector2i) -> bool:
	return BASE._png_size(path, expected)

static func _imported_authority_current(path: String) -> bool:
	return BASE._imported_authority_current(path)

static func _v7_revision_error(source: Dictionary, catalog: Dictionary, graph: Dictionary) -> String:
	_v7_tiles.clear()
	_v7_tile_order.clear()
	_v7_plane_validation.clear()
	for path: String in EXACT_INPUTS:
		if not _bound(catalog,path) or not _same_hash(catalog[path],EXACT_INPUTS[path]): return "V9C execution/baseline dependency not frozen/current " + path
	if source.get("art_revision")!="complete_v9c_coherent_whole" or source.get("pixel_sampling")!="round_world_pixel" or not _num(source.get("physical_navigation_margin_px"),0) or not _false(source.get("old_navigation_credit")): return "Wrong V9C identity or old NAV credit"
	var evidence: Variant=source.get("v7_revision_evidence")
	var v9c: Variant=source.get("v9c_revision_evidence")
	if not evidence is Dictionary or not evidence.get("ecology") is Dictionary or not _num(evidence.ecology.get("visual_material_map_step_px"),4) or not v9c is Dictionary: return "Missing actual independent V9C/sourcebody evidence"
	if not _equal_exact_value(v9c,_report.get("v9c_revision_evidence")): return "V9C source/report revision evidence differs"
	var execution_error: String=_v9c_execution_error(v9c,catalog,graph)
	if not execution_error.is_empty(): return execution_error
	var boundary: Dictionary=_v9c_prepared_source(graph,source,v9c,catalog)
	if not boundary.get("source") is ECOLOGY: return String(boundary.get("error","V9C reconstruction refused"))
	var boundary_error: String=_v9c_boundary_error(source,v9c,boundary,catalog)
	if not boundary_error.is_empty(): return boundary_error
	var material_error: String=_v9c_material_error(v9c,catalog,graph,boundary.source)
	if not material_error.is_empty(): return material_error
	var auth: Dictionary=C.read_json(String(_report.get("authorization",{}).get("path","")))
	var review_error: String=_v9c_regional_error(auth.get("regional_visual_review"),v9c.get("regional_approval"),catalog,graph,v9c)
	if not review_error.is_empty(): return review_error
	var shader: Variant=_report.get("actual_terrain_shader")
	if not shader is Dictionary or shader.get("path")!=TERRAIN_SHADER or not _bound(catalog,TERRAIN_SHADER) or not _same_hash(shader.get("sha256"),graph.terrain_shader.sha256) or shader.get("source_script")!=SURFACE_PATH or not _same_hash(shader.get("source_script_sha256"),EXACT_INPUTS[SURFACE_PATH]): return "Actual V9C saved shader/source identity differs"
	var receiver_source: ECOLOGY = boundary.source
	var rf: PackedByteArray = FileAccess.get_file_as_bytes(String(graph.height_rf.path))
	if rf.size() != 1537 * 1025 * 4: return "V7 actual Float32 RF byte count changed"
	if receiver_source.heights.to_byte_array() != rf: return "V9C reconstructed source RF differs"
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
	if id.begins_with("v8_"):
		if not id.begins_with("v8_marsh_lowgrass_") or body.kind != "herb" or not _false(body.get("blocking")) or not _pair_eq(body.get("collision_size_px"), Vector2.ZERO) or not _pair_eq(body.get("collision_size"), Vector2.ZERO) or body.get("v7_caster_recipe") != "unchanged original native draw geometry": return "V8 herb must remain independent nonblocking original native geometry " + id
		if height <= rf_source.WATER_Y: return "V8 herb is not on original dry RF " + id
		for offset: Vector2 in _shoe_offsets():
			if not _v7_nav_white(foot + offset, "raw_walk"): return "V8 herb lacks complete17 actual raw ground support " + id
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
	return BASE._json_native_exact(saved, native_expected)

static func _equal_exact_value(a: Variant, b: Variant) -> bool:
	return BASE._equal_exact_value(a, b)

static func _shoe_offsets() -> PackedVector2Array:
	return BASE._shoe_offsets()

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
	if FileAccess.get_sha256(BASE_PATH).to_lower() != BASE_SHA: return false
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


# V8 helpers below consume actual frozen executor fields, never ideal aliases.
static func _v8_inverse_approach(receiver: V7_ECOLOGY) -> Dictionary:
	var door: Vector2 = receiver.project_source(Vector2(7600, 2200))
	var world := PackedVector2Array([Vector2(7600,2340), Vector2(7840,2295), Vector2(7840,2230), Vector2(7600,2230), door])
	var inverted := PackedVector2Array()
	var records: Array = []
	for segment in range(world.size() - 1):
		var a: Vector2 = world[segment]
		var b: Vector2 = world[segment + 1]
		var steps: int = maxi(1, ceili(a.distance_to(b) / 4.))
		for n in range(steps + 1):
			if segment > 0 and n == 0: continue
			var desired: Vector2 = a.lerp(b, float(n) / steps)
			var point: Vector2 = desired
			var supported: bool = false
			for bridge: Dictionary in receiver.structures:
				if Geometry2D.is_point_in_polygon(desired, bridge.source_deck_polygon): supported = true
			if not supported:
				var low: float = maxf(0., desired.y - 512.)
				var high: float = minf(C.SIZE.y, desired.y + 512.)
				if receiver.project_source(Vector2(desired.x, low)).y > desired.y or receiver.project_source(Vector2(desired.x, high)).y < desired.y: return {"passed": false}
				for iteration in 32:
					var middle: float = (low + high) * .5
					if receiver.project_source(Vector2(desired.x, middle)).y < desired.y: low = middle
					else: high = middle
				point = Vector2(desired.x, (low + high) * .5)
				if receiver.project_source(point).distance_to(desired) > .001: return {"passed": false}
			inverted.append(point)
			var projected: Vector2 = receiver.project_source(point)
			records.append({"world_px": [desired.x, desired.y], "source_XZ_px": [point.x, point.y], "projected_RF_px": [projected.x, projected.y], "bridge_deck_Y0": receiver.supported_height(point) == 0.})
	var replacements: int = 0
	for route: Dictionary in receiver.routes:
		if route.id != "portal_bianzhou": continue
		route.points = inverted
		route.revision_origin = "NEW independent WORLD projected east bridge-end approach inverted through actual frozen RF; old door/bridge solids unchanged"
		replacements += 1
	if replacements != 1 or receiver.routes.size() != 27: return {"passed": false}
	receiver._index_segments(receiver.routes, receiver.road_buckets, 160.)
	var pairs: Array = []
	for point: Vector2 in world: pairs.append([point.x, point.y])
	return {"passed": true, "world": pairs, "records": records}


# New geometry/material methods are actual V9C fields, never old V8 aliases.
static func _v9c_execution_error(evidence: Dictionary,catalog: Dictionary,graph: Dictionary) -> String:
	var actual: Variant=evidence.get("actual_execution")
	if not actual is Dictionary or actual.size()!=5: return "Exactly five V9C executed roles required"
	var paths: Dictionary={"ecology":ECOLOGY_PATH,"surface":SURFACE_PATH,"full":BUILDER,"regional":REGIONAL_BUILDER,"geometry_helper":GEOMETRY_HELPER_PATH}
	var roles: Dictionary={"ecology":"ACTUAL_ECOLOGY_OBJECT","surface":"ACTUAL_SURFACE_OBJECT","full":"ACTUAL_FULL_EXECUTOR","regional":"ROOT_REVIEWED_PRIOR_REGIONAL_EXECUTOR","geometry_helper":"ACTUAL_CPU_DERIVATION_HELPER_NOT_REEXECUTED_DURING_GPU"}
	for role: String in paths:
		var row: Variant=actual.get(role)
		if not row is Dictionary or row.get("path")!=paths[role] or not _bound(catalog,paths[role]) or not _same_hash(row.get("sha256"),EXACT_INPUTS[paths[role]]): return "Wrong actual V9C execution role " + role
		# Source/surface inherited records may carry their truthful OBJECT labels.
		if role in ["full","regional","geometry_helper"] and row.get("role")!=roles[role]: return "Wrong actual executor/derivation scope " + role
	if graph.geometry_helper.path!=GEOMETRY_HELPER_PATH or not _same_hash(graph.geometry_helper.sha256,GEOMETRY_HELPER_SHA): return "Wrong actual packed geometry helper"
	if not _false(evidence.get("old_navigation_credit")) or not _false(evidence.get("production_approved")) or not _false(evidence.get("visual_approved")): return "Capture evidence cannot self-approve"
	return ""

static func _v9c_prepared_source(graph: Dictionary,source_record: Dictionary,evidence: Dictionary,catalog: Dictionary) -> Dictionary:
	var inputs: Variant=evidence.get("derived_geometry_inputs")
	var audit: Variant=evidence.get("derived_geometry_audit")
	var auth: Dictionary=C.read_json(String(_report.get("authorization",{}).get("path","")))
	if not inputs is Dictionary or inputs.size()!=4 or not audit is Dictionary or not _equal_exact_value(inputs,auth.get("derived_geometry_inputs")): return {"error":"Four actual CPU-derived inputs are not separately root-authorized"}
	for role: String in ["height_rf","terrain_mesh","source_topology","derivation_report"]:
		var row: Variant=inputs.get(role)
		if not row is Dictionary or not String(row.get("path","")).begins_with(DERIVED_PREFIX) or not _bound(catalog,String(row.get("path",""))) or not _same_hash(row.get("sha256"),catalog.get(row.get("path"))) or not _equal_exact_value(row,graph.get(role)): return {"error":"Actual approved NEW CPU input/graph differs "+role}
	for path: String in BASELINE_GEOMETRY.BASELINE_PINS:
		if not _bound(catalog,path) or not _same_hash(catalog[path],BASELINE_GEOMETRY.BASELINE_PINS[path]): return {"error":"Historical baseline changed "+path}
	var report: Dictionary=C.read_json(inputs.derivation_report.path)
	if not _true(report.get("passed")) or report.get("status")!="DERIVED_GEOMETRY_SOURCE_CHECKS_PASS_REQUIRES_ACTUAL_CAPTURE" or not _equal_exact_value(report.get("audit"),audit) or not report.get("artifacts") is Dictionary or report.artifacts.size()!=3: return {"error":"Real CPU derivation report/audit absent"}
	for role: String in ["height_rf","terrain_mesh","source_topology"]:
		if not _equal_exact_value(report.artifacts.get(role),inputs[role]): return {"error":"CPU report's three output roles differ"}
	if not _equal_exact_value(audit.get("baseline_sha256"),BASELINE_GEOMETRY.BASELINE_PINS) or not _equal_exact_value(audit.get("executed_helper"),graph.geometry_helper) or not _equal_exact_value(audit.get("caller_source"),graph.source_script) or not _pair_eq(audit.get("height_grid_size"),Vector2(1537,1025)) or not _num(audit.get("height_grid_step_px"),8) or not _rect_eq(audit.get("domain_source_px"),[3920,0,2320,1360]) or not _false(audit.get("old_NAV_unchanged_claim")) or not _false(audit.get("whole_GPU_approval")) or not _false(audit.get("visual_approved")) or not _false(audit.get("production_approved")) or not _true(audit.get("native_binary_capture_required")): return {"error":"Wrong derived geometry baseline/scope or old navigation credit"}
	var old_bytes: PackedByteArray=FileAccess.get_file_as_bytes(BASELINE_GEOMETRY.BASELINE_RF)
	var new_bytes: PackedByteArray=FileAccess.get_file_as_bytes(inputs.height_rf.path)
	if old_bytes.size()!=1537*1025*4 or new_bytes.size()!=old_bytes.size(): return {"error":"Actual new/old RF dimensions differ"}
	var original: PackedFloat32Array=old_bytes.to_float32_array()
	var fresh: PackedFloat32Array=new_bytes.to_float32_array()
	var actual:=ECOLOGY.new()
	actual.heights=original
	actual.prepare()
	if not actual.v7_proposal_error.is_empty(): return {"error":"Old-RF actual site preparation failed"}
	var first: Dictionary=_v8_inverse_approach(actual)
	if not first.get("passed",false): return {"error":"Original Bianzhou inverse approach failed"}
	var baseline: Dictionary=C.read_json(BASELINE_GEOMETRY.BASELINE_SOURCE)
	if not baseline.get("objects") is Array or baseline.objects.size()!=2687: return {"error":"All 2687 old sites required"}
	var sites: PackedByteArray=JSON.stringify(actual.vegetation_sites).to_utf8_buffer()
	if not _same_hash(audit.get("original_site_signature"),_bytes_sha(sites)): return {"error":"Original sites were re-drawn before height bind"}
	if not _same_hash(evidence.get("baseline_prepared_site_signature"),_bytes_sha(sites)) or not _json_native_exact(evidence.get("prepared_native_routes"),_v9c_native_paths(actual.routes)) or not _json_native_exact(evidence.get("prepared_native_rivers"),_v9c_native_paths(actual.rivers)): return {"error":"Recorded old-RF routes/rivers/site identity differs from actual prepared source"}
	if not _json_native_exact(source_record.get("v7_revision_evidence",{}).get("bianzhou_projected_world_approach"),first.world) or not _json_native_exact(source_record.get("v7_revision_evidence",{}).get("inverse_RF_records"),first.records): return {"error":"Actual preserved inverse approach differs"}
	var changed: Dictionary={}
	var maximum_delta:=0.
	for index in fresh.size():
		if not is_finite(original[index]) or not is_finite(fresh[index]): return {"error":"Nonfinite actual RF"}
		if (original[index]>-.025)!=(fresh[index]>-.025): return {"error":"New RF changed water/land"}
		if old_bytes.slice(index*4,index*4+4)==new_bytes.slice(index*4,index*4+4): continue
		var point:=Vector2((index%1537)*8,(index/1537)*8)
		if not Rect2(3920,0,2320,1360).has_point(point): return {"error":"Height change escaped northern domain"}
		changed[index]=true
		maximum_delta=maxf(maximum_delta,absf(fresh[index]-original[index]))
	if changed.is_empty() or not _num(audit.get("changed_nodes"),changed.size()) or not _num(audit.get("maximum_height_delta_m"),maximum_delta) or not _num(audit.get("water_land_vertex_changes"),0): return {"error":"Height change audit is not actual RF"}
	# The pinned helper's pure in-memory oracles do NOT call derive(), save or GPU.
	# Rebuild its measured protection from the exact original bodies, not its audit.
	var helper_script: Script=load(GEOMETRY_HELPER_PATH)
	if helper_script==null or not helper_script.can_instantiate(): return {"error":"Frozen native packing helper missing"}
	var helper: RefCounted=helper_script.new()
	helper.set("_catalog_v2",C.read_json(BASELINE_GEOMETRY.BASELINE_MANIFEST).get("asset_sha256",{}))
	if not helper.call("_prepare_protection",baseline,baseline.objects) or not helper.call("_index_roads",actual.routes): return {"error":"Actual original support/protection could not be reconstructed"}
	var support: Dictionary=helper.call("_support_audit",old_bytes,new_bytes)
	if not _true(support.get("passed")) or not _json_native_exact(audit.get("object_support"),support): return {"error":"All 2687 exact four-node supports/protection footprints differ"}
	var old_mesh: ArrayMesh=ResourceLoader.load(BASELINE_GEOMETRY.BASELINE_MESH,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var new_mesh: ArrayMesh=ResourceLoader.load(inputs.terrain_mesh.path,"",ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	var mesh_result: Dictionary=helper.call("_derive_mesh",old_mesh,original,fresh,changed)
	if not _true(mesh_result.get("passed")) or not mesh_result.get("mesh") is ArrayMesh or new_mesh==null or not helper.call("_mesh_exact",mesh_result.mesh,new_mesh) or not _json_native_exact(audit.get("mesh"),mesh_result.get("audit")): return {"error":"Saved native mesh differs from exact A/B/C packed-height/normal oracle"}
	var old_selector: Image=Image.load_from_file(BASELINE_GEOMETRY.BASELINE_SELECTOR)
	var new_selector: Image=Image.load_from_file(inputs.source_topology.path)
	if old_selector==null or new_selector==null or old_selector.get_size()!=Vector2i(6144,4096) or new_selector.get_size()!=old_selector.get_size(): return {"error":"Actual new selector missing"}
	old_selector.convert(Image.FORMAT_RGB8)
	var expected_selector: Image=old_selector.duplicate() as Image
	var selector_result: Dictionary=helper.call("_derive_selector",actual,original,fresh,old_selector,expected_selector,changed)
	if not _true(selector_result.get("passed")) or not _json_native_exact(audit.get("selector"),selector_result.get("audit")): return {"error":"New selector is not full-cell native RF/grade/shore predicate"}
	new_selector.convert(Image.FORMAT_RGB8)
	if new_selector.get_data()!=expected_selector.get_data(): return {"error":"Actual new selector pixels differ; old NAV is never a substitute"}
	if not actual.bind_derived_geometry({"passed":true,"heights":fresh,"artifacts":inputs,"audit":audit}) or JSON.stringify(actual.vegetation_sites).to_utf8_buffer()!=sites: return {"error":"Read-only new height bind re-sited original bodies"}
	return {"source":actual,"baseline":baseline,"world":first.world,"inputs":inputs,"audit":audit}

static func _v9c_boundary_error(source: Dictionary,evidence: Dictionary,boundary: Dictionary,catalog: Dictionary) -> String:
	var baseline: Dictionary=boundary.baseline
	var old_ids: Dictionary={}
	for row: Dictionary in baseline.objects:
		if old_ids.has(row.id): return "Duplicate old body"
		old_ids[row.id]=row
	var current: Variant=source.get("objects")
	if not current is Array or current.size()!=2687: return "All 2687 independent bodies required"
	var seen: Dictionary={}
	for row: Variant in current:
		if not row is Dictionary or not old_ids.has(row.get("id")) or seen.has(row.id): return "Added/missing/re-sited body identity"
		seen[row.id]=true
		var old: Dictionary=old_ids[row.id]
		for key: String in ["kind","pose","role","source_XZ_foot_px","world_foot_px","foot_uv","render_size_px","blocking","collision_size","collision_offset","solid_polygons_px","depth_foot_y","deck_height_m","source_fullxz_rect_px","actual_used_world_bounds_m"]:
			if old.has(key)!=row.has(key) or (old.has(key) and not _equal_exact_value(old[key],row[key])): return "Protected ordinary body/physics identity changed "+String(row.id)+"/"+key
	var actual: ECOLOGY=boundary.source
	var prepare: Variant=evidence.get("original_site_preparation")
	if not prepare is Dictionary or prepare.get("method")!="BASELINE_RF_PREPARE_THEN_FIXED_BIANZHOU_APPROACH_THEN_BIND_DERIVED_RF_NO_REPREPARE" or not _num(prepare.get("baseline_objects"),2687) or not _equal_exact_value(prepare.get("baseline_RF"),{"path":BASELINE_GEOMETRY.BASELINE_RF,"sha256":BASELINE_GEOMETRY.BASELINE_PINS[BASELINE_GEOMETRY.BASELINE_RF]}) or not _equal_exact_value(prepare.get("support_audit"),boundary.audit.object_support) or not _same_hash(prepare.get("site_signature"),boundary.audit.original_site_signature): return "Old preparation/new height bind provenance differs"
	if not _json_native_exact(evidence.get("ecology_contract"),actual.v9_execution_contract()): return "Current V9C ecology object contract differs"
	if not source.get("routes") is Array or source.routes.size()!=27 or not source.get("portals") is Array or source.portals.size()!=16: return "All original routes/doors required"
	var roads: Dictionary={}
	for row: Dictionary in source.routes: roads[row.id]=row
	for row: Dictionary in actual.routes:
		if not roads.has(row.id): return "Missing original route"
		var points: Array=[]
		for p: Vector2 in row.points:
			var q: Vector2=actual.project_source(p)
			for structure: Dictionary in actual.structures:
				if Geometry2D.is_point_in_polygon(p,structure.source_deck_polygon): q=p
			points.append([q.x,q.y])
		if row.id=="portal_bianzhou": points=boundary.world
		if not _json_native_exact(roads[row.id].get("points_px"),points): return "Fresh actual projected route differs "+String(row.id)
	for entry: Dictionary in source.portals:
		var raw: Variant=entry.get("source_XZ_foot_px")
		if not _pair(raw): return "Invalid protected source doorway "+String(entry.id)
		var point:=Vector2(float(raw[0]),float(raw[1]))
		if not _pair_eq(entry.get("door_foot_px"),actual.project_source(point)): return "Fresh actual protected doorway differs "+String(entry.id)
	if not _bound(catalog,GEOMETRY_HELPER_PATH): return "Geometry helper missing from whole input closure"
	return ""

static func _v9c_native_paths(paths: Array) -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for path: Dictionary in paths:
		var points: Array=[]
		for point: Vector2 in path["points"]: points.append([point.x,point.y])
		result.append({"id":path["id"],"points":points,"half_width_px":path["half_width_px"],"coordinate_space":"SOURCE_XZ_LOGICAL_PIXELS_NOT_PROJECTED_WORLD"})
	return result

static func _v9c_material_error(evidence: Dictionary,catalog: Dictionary,graph: Dictionary,actual: ECOLOGY) -> String:
	var maps: Dictionary=actual.visual_material_maps(Rect2(Vector2.ZERO,C.SIZE))
	if not _num(maps.get("step_px"),4): return "Actual V9C control-map step differs"
	var textures: Dictionary={}
	for row: Array in [["biome","ecology"],["roads","roads"]]:
		var path: String=ROOT+"capture/"+row[1]+"_reconstructed.png"
		var saved: Image=Image.load_from_file(path)
		var expected: Variant=maps.get(row[0])
		if not expected is Image or saved==null or not _bound(catalog,path) or saved.get_size()!=Vector2i(3072,2048) or saved.get_format()!=expected.get_format() or saved.has_mipmaps() or expected.has_mipmaps() or saved.get_data()!=expected.get_data(): return "Current V9C actual map bytes differ "+path
		textures[row[1]]=ImageTexture.create_from_image(saved)
	var surface:=SURFACE.new()
	if not surface.load_sources(): return "Actual registered V9C PBR sources missing: "+surface.error
	if surface.evidence.size()!=18 or not _json_native_exact(evidence.get("actual_materials"),surface.evidence): surface.release(); return "Actual eighteen CC0 source/copy/sampler records differ"
	for row: Dictionary in surface.evidence:
		for key: String in ["path","source_path"]:
			if not _bound(catalog,String(row.get(key,""))) or not _same_hash(row.get("sha256" if key=="path" else "source_sha256"),catalog.get(row.get(key))): surface.release(); return "Actual licensed source/copy bytes changed"
	var records: Variant=evidence.get("attached_material_creations")
	if not records is Array or records.size()!=5: surface.release(); return "Exactly initial plus two actual terrain/water pairs required"
	var rf: ImageTexture=ImageTexture.create_from_image(Image.create_from_data(1537,1025,false,Image.FORMAT_RF,FileAccess.get_file_as_bytes(graph.height_rf.path)))
	var initial: ShaderMaterial=surface.terrain_material(textures.ecology,textures.roads,Rect2(Vector2.ZERO,C.SIZE))
	var saved_shader: Shader=ResourceLoader.load(TERRAIN_SHADER,"",ResourceLoader.CACHE_MODE_IGNORE) as Shader
	if initial==null or saved_shader==null or initial.shader.code!=saved_shader.code or not _num(initial.get_shader_parameter("v9c_material_identity"),1): surface.release(); return "Saved V9C shader differs from actual source construction"
	var expected_initial: Dictionary=surface.v9_material_records.back().duplicate(true)
	expected_initial["creation_stage"]="INITIAL_ACTUAL_SHADER_CONSTRUCTION_NOT_A_DRAW"
	expected_initial["actual_saved_shader"]=_report.get("actual_terrain_shader").duplicate(true)
	if not _json_native_exact(records[0],expected_initial): surface.release(); return "Actual initial V9C construction record differs"
	for index in range(1,5):
		var kind: String="terrain" if index%2==1 else "water"
		var expected: ShaderMaterial=surface.terrain_material(textures.ecology,textures.roads,Rect2(Vector2.ZERO,C.SIZE)) if kind=="terrain" else surface.water_material(rf,Vector2i.ZERO,Vector2i(1537,1025))
		var row: Variant=records[index]
		if not row is Dictionary or row.get("kind")!=kind or row.get("creation_stage")!="ACTUAL_ATTACHED_WHOLE_WORLD_MATERIAL" or not _bound(catalog,String(row.get("path",""))) or not String(row.path).begins_with(ROOT+"capture/") or not _same_hash(row.get("sha256"),catalog[row.path]) or not _equal_exact_value(row.get("actual_surface"),graph.surface_script) or not _true(row.get("RF_bound_to_actual_new_texture")): surface.release(); return "Actual attached V9C material identity missing"
		var saved: ShaderMaterial=ResourceLoader.load(row.path,"",ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
		if expected==null or saved==null or expected.shader==null or saved.shader==null or expected.shader.code!=saved.shader.code or not _same_hash(row.get("actual_code_sha256"),_bytes_sha(saved.shader.code.to_utf8_buffer())): surface.release(); return "Actual saved attached shader differs"
		if not _json_native_exact(row.get("registered_binding"),surface._v7_binding_evidence(expected)): surface.release(); return "Current registered sampler binding evidence differs"
		var error: String=_v9c_uniform_error(saved,expected,row)
		if not error.is_empty(): surface.release(); return error
	surface.release()
	return ""

static func _v9c_uniform_error(saved: ShaderMaterial,expected: ShaderMaterial,row: Dictionary) -> String:
	var specs: Array=saved.shader.get_shader_uniform_list()
	var other: Array=expected.shader.get_shader_uniform_list()
	var records: Variant=row.get("actual_uniforms")
	if not records is Array or records.size()!=specs.size() or not _json_native_exact(specs,other): return "Current attached material uniform schema differs"
	for index in specs.size():
		var name: String=String(specs[index].name)
		var record: Variant=records[index]
		var value: Variant=saved.get_shader_parameter(name)
		var actual: Variant=expected.get_shader_parameter(name)
		if not record is Dictionary or record.get("name")!=name or not _json_native_exact(record.get("schema"),specs[index]) or not _num(record.get("variant_type"),typeof(value)) or typeof(value)!=typeof(actual): return "Actual uniform identity/type differs "+name
		if value is Texture2D:
			var image: Image=value.get_image()
			var fresh: Image=actual.get_image()
			var tex: Variant=record.get("texture")
			if image==null or fresh==null or not tex is Dictionary or image.get_size()!=fresh.get_size() or image.get_format()!=fresh.get_format() or image.get_mipmap_count()!=fresh.get_mipmap_count() or image.get_data()!=fresh.get_data() or not _pair_eq(tex.get("canvas"),Vector2(image.get_size())) or not _num(tex.get("format"),image.get_format()) or not _num(tex.get("mip_count"),image.get_mipmap_count()) or not _same_hash(tex.get("RGBA_and_all_mips_sha256"),_bytes_sha(image.get_data())): return "Actual current sampler/full mip bytes differ "+name
		else:
			if value is Resource or var_to_bytes(value)!=var_to_bytes(actual) or not _same_hash(record.get("native_variant_bytes_sha256"),_bytes_sha(var_to_bytes(value))) or record.get("value_as_text")!=str(value): return "Actual native uniform value differs "+name
	return ""

static func _v9c_regional_error(review: Variant,source_review: Variant,catalog: Dictionary,graph: Dictionary,evidence: Dictionary) -> String:
	if not review is Dictionary or not _equal_exact_value(review,source_review) or not _true(review.get("approved")) or review.get("approved_by")!="root" or review.get("scope")!=REGIONAL_SCOPE: return "Missing independent current V9C regional root review"
	var target: Variant=review.get("candidate_full_builder")
	if not target is Dictionary or target.get("path")!=BUILDER or not _same_hash(target.get("sha256"),EXACT_INPUTS[BUILDER]): return "Regional root review must bind exact NEW FULL executor"
	var path: String=String(review.get("result_path",""))
	if not path.begins_with("res://build/world_map_v15_coherent_whole_v9c_regional/") or not _bound(catalog,path) or not _same_hash(review.get("result_sha256"),catalog[path]): return "Current actual V9C regional result unbound"
	var result: Dictionary=C.read_json(path)
	if result.get("scope")!=REGIONAL_SCOPE or result.get("status")!=REGIONAL_STATUS or not _true(result.get("input_hashes_unchanged_after")) or not _equal_exact_value(result.get("derived_geometry_inputs"),evidence.get("derived_geometry_inputs")): return "Regional FULL sources/derived inputs differ"
	var executed: Variant=result.get("executed_builder")
	var inputs: Variant=result.get("cached_inputs_sha256")
	if not executed is Dictionary or executed.get("path")!=REGIONAL_BUILDER or not _same_hash(executed.get("sha256"),EXACT_INPUTS[REGIONAL_BUILDER]) or not inputs is Dictionary: return "Wrong current regional execution identity"
	for dependency: String in EXACT_INPUTS:
		if not _same_hash(inputs.get(dependency),EXACT_INPUTS[dependency]) or not _bound(catalog,dependency): return "Regional current source/helper/baseline changed "+dependency
	var revision: Variant=result.get("v9c_revision_evidence")
	if not revision is Dictionary or not _equal_exact_value(revision.get("derived_geometry_inputs"),evidence.get("derived_geometry_inputs")) or not _equal_exact_value(revision.get("derived_geometry_audit"),evidence.get("derived_geometry_audit")) or not _equal_exact_value(revision.get("ecology_contract"),evidence.get("ecology_contract")) or not _equal_exact_value(revision.get("actual_materials"),evidence.get("actual_materials")): return "Regional actual new source/RF/material evidence differs"
	var chain: Variant=revision.get("actual_execution")
	if not chain is Dictionary or chain.size()!=5: return "Regional actual five-role inheritance/object chain missing"
	for role: String in ["ecology","surface","full","regional","geometry_helper"]:
		var row: Variant=chain.get(role)
		var current: Dictionary=evidence.actual_execution[role]
		if not row is Dictionary or row.get("path")!=current.path or not _same_hash(row.get("sha256"),current.sha256): return "Regional actual execution chain differs "+role
	if chain.full.get("role")!="INHERITED_FULL_METHODS_NOT_REGIONAL_EXECUTOR" or chain.regional.get("role")!="ACTUAL_REGIONAL_EXECUTOR" or chain.geometry_helper.get("role")!="ACTUAL_CPU_DERIVATION_HELPER_NOT_REEXECUTED_DURING_GPU": return "Regional inherited method cannot claim actual FULL execution"
	var population: Variant=result.get("alpha_union")
	if not population is Dictionary or not _true(population.get("passed")) or not population.get("regions") is Array or population.regions.size()!=4: return "Four original native alpha regions are mandatory despite five new material ROIs"
	for row: Variant in population.regions:
		if not row is Dictionary or not _true(row.get("passed")) or not _num(row.get("alpha_threshold_byte"),30) or not _num(row.get("minimum_exclusive"),.08) or not _positive(row.get("actual_union_fraction")) or float(row.actual_union_fraction)<=.08: return "Every original canopy region must exceed8% actual alpha"
		var images: Variant=row.get("actual_sourcebody_sha256")
		if not images is Dictionary or images.is_empty(): return "Actual regional body union lacks images"
		for file: Variant in images:
			if not file is String or not _bound(catalog,file) or not _same_hash(images[file],catalog[file]): return "Regional alpha source PNG is not current"
	var worlds: Variant=result.get("worlds")
	var history: Variant=result.get("actual_memory_history")
	var guards: Variant=result.get("fresh_preallocation_guards")
	if not worlds is Dictionary or worlds.size()!=2 or not history is Dictionary or not guards is Array or guards.size()!=2: return "Two actual regional worlds/memory guards required"
	var history_error: String=_history_error(history,catalog)
	if not history_error.is_empty(): return history_error
	var expected: Dictionary={"farmland":[3460,2582,1280,1024],"marsh":[10160,6576,1280,1024],"snow":[4360,0,1280,1024],"limestone":[560,1375,1280,1024],"meadow_river":[5960,3288,1280,1024]}
	var world_ids: Dictionary={}
	var view_ids: Dictionary={}
	var effective_ids: Dictionary={}
	for identity: String in ["primary","reference"]:
		var world: Variant=worlds.get(identity)
		if not world is Dictionary or world.get("identity")!=identity or not _true(world.get("actual_world_released_before_next")) or not world.get("roles") is Dictionary or world.roles.size()!=5 or not _whole_camera(world.get("camera"),2): return "Actual regional world/camera incomplete"
		for pair: Array in [["world_node_instance_id",world_ids],["viewport_instance_id",view_ids],["world_3d_instance_id",effective_ids]]:
			var value: Variant=world.get(pair[0])
			if not _integer(value,1) or pair[1].has(str(value)): return "Shared regional World3D/camera instance"
			pair[1][str(value)]=true
		for pair: Array in [["authoritative_global_mesh","terrain_mesh"],["support_mesh","deck_support_mesh"]]:
			if not _equal_exact_value(world.get(pair[0]),graph[pair[1]]): return "Regional actual derived receiver/support differs"
		var guard: Dictionary={}
		for raw: Variant in guards:
			if raw is Dictionary and raw.get("world_identity")==identity:
				if not guard.is_empty(): return "Duplicate regional allocation guard"
				guard=raw
		var guard_error: String=_guard_error(guard,history)
		if not guard_error.is_empty(): return guard_error
		var coverage: Variant=world.get("coverage")
		if not coverage is Dictionary or not _true(coverage.get("passed")) or not _true(coverage.get("entire_canvas_covered")) or not _num(coverage.get("shadow_max_actual_m"),160) or not _nonnegative(coverage.get("max_actual_source_projection_error_px")) or float(coverage.max_actual_source_projection_error_px)>.01: return "Regional derived receiver/caster coverage failed"
		for role: String in CAPTURE_ROLES:
			var record: Variant=world.roles.get(role)
			var factor: int=2 if role in ["visual","shadow_off"] else 1
			if not record is Dictionary or not _pair_eq(record.get("actual_native_canvas"),C.SIZE*factor) or not _whole_camera(record.get("frozen_camera_projection"),factor) or not _num(record.get("MSAA_3D_actual"),0) or not _num(record.get("MSAA_2D_actual"),0) or not record.get("passes") is Array or record.passes.size()!=2 or not record.get("windows") is Dictionary or record.windows.size()!=5: return "Regional native role/draw/ROI evidence incomplete"
			if not _num(record.get("caster_shadow_setting_actual"),GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY) or record.get("caster_actual_visible")!=(role=="visual") or record.get("water_actual_visible")!=(factor==2) or record.get("support_actual_visible")!=(role=="walk") or not _num(record.get("terrain_actual_cast_shadow"),GeometryInstance3D.SHADOW_CASTING_SETTING_ON if factor==2 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF): return "Regional actual role visibility/shadow authority differs"
			for n in 2:
				var error: String=_pass_error(record.passes[n],identity+"_"+role+"_"+str(n),C.SIZE*factor)
				if not error.is_empty(): return error
			if float(record.passes[1].process_before)<=float(record.passes[0].process_after) or float(record.passes[1].fence_sequence)<=float(record.passes[0].fence_sequence): return "Regional repeat is not fresh later draw"
			for id: String in expected:
				var window: Variant=record.windows.get(id)
				if not window is Dictionary: return "Missing regional ROI "+id
				var error: String=_roi_error(window,expected[id],role,record,catalog,path.get_base_dir()+"/")
				if not error.is_empty(): return error
	for role: String in CAPTURE_ROLES:
		for id: String in expected:
			var a: Dictionary=worlds.primary.roles[role].windows[id]
			var b: Dictionary=worlds.reference.roles[role].windows[id]
			if a.path==b.path or a.raw_path==b.raw_path or not _rgba_equal(a.path,b.path) or not _rgba_equal(a.raw_path,b.raw_path): return "Two fresh regional worlds disagree in actual RGBA"
	var materials: Variant=revision.get("attached_material_creations")
	var full_materials: Array=evidence.attached_material_creations
	if not materials is Array or materials.size()!=5: return "Actual regional five attached materials missing"
	for index in range(1,5):
		var row: Variant=materials[index]
		var original: Dictionary=full_materials[index]
		if not row is Dictionary or row.get("kind")!=original.kind or not _actual_saved_file(row) or not _bound(catalog,String(row.get("path",""))) or not _same_hash(row.get("actual_code_sha256"),original.actual_code_sha256) or not _equal_exact_value(row.get("actual_uniforms"),original.actual_uniforms) or not _equal_exact_value(row.get("registered_binding"),original.registered_binding): return "Regional/FULL actual material uniforms/samplers differ"
	return ""

