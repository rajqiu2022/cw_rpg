extends "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd"

## NEW explicit v8 path adapter. Parent byte identity is pinned, not a const override.
## _v7_* method and variable names are retained solely as real dynamic parent hooks.
## Camera, RF/mesh, two fresh worlds, five roles, two draws, ROI96 and zeroRGBA remain inherited.
## No gate, runtime, QA, old capture, approval, formal map or save is written by this source.
## FULL requires separate actual current v8 regional root review; pending pins fail closed.
const V8_ROOT := "res://art/maps/world_map_v15_complete_v8/"
const V8_SOURCE_JSON := "res://data/maps/world_map_v15_complete_v8_source.json"
const V8_REPORT := V8_ROOT + "whole_actual_capture.json"
const V8_PARENT_PATH := "res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd"
const V8_PARENT_SHA := "74a7757a43c7ff4e339fa297bf29a0ec7860cf6a70f7508ebd80a418ce18e233"
const V8_REGIONAL_PATH := "res://scripts/dev/build_world_map_v15_coherent_whole_v8_regional_proposal.gd"
const V8_REGIONAL_PARENT := "res://scripts/dev/build_world_map_v15_coherent_whole_v7_regional_proposal.gd"
const V8_REGIONAL_PARENT_SHA := "fd6dc2a60fd4f0fd6f3e4803b96973d6827b9f781f48a82bed1176ed2fc3c9a8"
const V8_REGIONAL_ROOT := "res://build/world_map_v15_coherent_whole_v8_regional/"
const V8_REGIONAL_SCOPE := "V8_BOUNDED_FRESH_REGIONAL_MATERIAL_AND_DRY_BANK_NOT_FULL_OR_FIELD"
const V8_ECOLOGY := preload("res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd")
const V8_SURFACE := preload("res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd")
const V8_SOURCE_PINS := {
 "res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd":"434aca511887eb06939fcd85cbe815b74e1f3fc3c7b560777fb91e78e91a5d16",
 "res://scripts/dev/world_map_v15_complete_v7_surface_proposal.gd":"0f469cd0bfac24195df18e9667873b926d6bee9875f1ca171ccbddeaff2dd7f8",
 "res://scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd":"d2d3795942aa452a18abc006d45bcde44749ccad276a7ec16e0f897604611290",
 V7_CF21_PATH:V7_CF21_SHA,
 "res://scripts/dev/test_world_v15_native_combined_rgba_word_stats_unit.gd":"f5ffe7adf8e9155f19fcd8640da51724605152dfe8bc1d3875789a8688d82608",
 "res://build/world_v15_native_binary_stats_unit/1791073994_1612124/result.json":"dde934b08ceacef6a887547c28af6296a0d6a2d5e9719b20775048582493c7e9",
 V8_PARENT_PATH:V8_PARENT_SHA,
 V8_REGIONAL_PARENT:V8_REGIONAL_PARENT_SHA,
 V8_REGIONAL_PATH:"9647a9e175f9686ec36ca76954c57982addd7e90a9c1458f633abd8380c932d8",
 "res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd":"43da1cbe34362e32610a0c27070b514dc7f3f49853a7004ab61a59c7f6662bfa",
 "res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd":"11bc6572071f58d8852ad3378091d4df30ea7c2e280f484a6f6dcf4d6c4d4f7f"
}

func _run() -> void:
	v7_art_root = V8_ROOT
	var args: PackedStringArray = OS.get_cmdline_user_args()
	pilot_output = "res://build/world_map_v15_coherent_whole_v8_full/%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	failure_output = pilot_output
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pilot_output))
	if "--coherent-whole-v8-full" not in args or DisplayServer.get_name() == "headless":
		error = "NEW FULL explicit GPU authorization required; default/headless/pilot invocation refuses."
		await _pilot_finish(false)
		return
	for arg: String in args:
		if arg.begins_with("--authorization="): v7_auth_path = arg.trim_prefix("--authorization=")
	if not _pilot_authorized(v7_auth_path):
		await _pilot_finish(false)
		return
	# Never overwrite previous current/failed candidates. Root archives them.
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(V8_ROOT)) or FileAccess.file_exists(V8_SOURCE_JSON):
		error = "NEW v8 root/source JSON must be absent before capture; root recoverable archive required."
		await _pilot_finish(false)
		return
	for folder: String in ["", "capture/", "entities/", "prototypes/", "chunks/", "seams/", "ecology/", "entities/chunks/"]:
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(V8_ROOT + folder)) != OK:
			error = "Cannot create NEW v8 artifact directory."
			await _pilot_finish(false)
			return
	v7_started = true
	pilot_output = V8_ROOT + "capture/"
	pilot_result = {"schema_version": 1, "coordinate_version": 15, "capture_protocol": V7_PROTOCOL, "scope": V7_SCOPE, "status": "BUILD_IN_PROGRESS", "production_approved": false, "visual_approved": false, "engine_pid": OS.get_process_id(), "executed_builder": {"path": get_script().resource_path, "sha256": FileAccess.get_sha256(get_script().resource_path)}, "authorization": {"path": v7_auth_path, "sha256": FileAccess.get_sha256(v7_auth_path)}, "cached_inputs_sha256": pilot_inputs, "whole_cpu_image_requested": false, "whole_cpu_image_allowed": false, "maximum_CPU_ROI_pixels": V7_MAX_CPU_ROI_PIXELS, "CPU_ROI_budget": V7_CPU_ROI_BUDGET, "no_legacy_frustum_seam_pass_claim": true, "worlds": {}, "comparisons": {}, "chunk_count_required": 64, "seam_count_required": 112}
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
		print("V8_FULL_WORLD_BEGIN ", identity, " ", Time.get_ticks_usec())
		var measured: Dictionary = await _pilot_capture_world(identity)
		if measured.is_empty():
			await _pilot_finish(false)
			return
		pilot_result["worlds"][identity] = measured
		print("V8_FULL_WORLD_RELEASED ", identity, " ", Time.get_ticks_usec())
	if not _pilot_compare() or not _v7_export_chunks_and_refs() or not _v7_actual_routes_and_doors():
		await _pilot_finish(false)
		return
	for path: String in pilot_inputs:
		if FileAccess.get_sha256(path).to_lower() != String(pilot_inputs[path]).to_lower():
			error = "Frozen input changed during FULL: " + path
			await _pilot_finish(false)
			return
	pilot_result["input_hashes_unchanged_after"] = true
	pilot_result["status"] = V7_STATUS
	if not _write_json(V8_REPORT, pilot_result):
		await _pilot_finish(false)
		return
	full_catalog[V8_REPORT] = FileAccess.get_sha256(V8_REPORT)
	full_graph[V8_REPORT] = full_catalog[V8_REPORT]
	_full_register_paths(pilot_result)
	_full_register_paths(v7_auth_path)
	if not _full_assemble_contract():
		await _pilot_finish(false)
		return
	await _pilot_finish(true)

func _v7_copy_geometry() -> bool:
	var copies: Array[Dictionary] = []
	for pair: Array in [["terrain_height.rf", "terrain_height.rf"], ["terrain_mesh.res", "terrain_mesh.res"], ["source_topology.png", "source_topology.png"], ["capture/terrain_shader.gdshader", "capture/terrain_shader.gdshader"], ["chunks/r0_c0_actual_deck_support_mesh.res", "deck_support_mesh.res"]]:
		var original: String = CACHE_ROOT + pair[0]
		if pair[0]=="capture/terrain_shader.gdshader": original=pilot_result["actual_terrain_shader"]["path"]
		var copy: String = v7_art_root + pair[1]
		if not _full_copy_exact(original, copy): return false
		copies.append({"original_path": original, "original_sha256": FileAccess.get_sha256(original), "copy_path": copy, "copy_sha256": FileAccess.get_sha256(copy), "actual_GPU_input_path": original, "byte_exact_copy": true, "provenance": "NEW actual v8 Shader instance saved before draw; created by exact v8 surface source, not loaded from old shader" if pair[0]=="capture/terrain_shader.gdshader" else "Frozen authored geometry input from ROOT066; NOT reuse of its rejected narrow-frustum seam acceptance"})
	full_geometry = {"height_grid_shape": _v2i(SOURCE.GRID_SIZE), "height_grid_origin_px": [0, 0], "source_node_spacing_px": SOURCE.GRID_STEP, "height_interpolation": "exact original Float32 [a,b,c,b,d,c] affine triangles", "selector_cell_rule": "original entire 2px selector cell intersects both native triangles; bank28/gradient .72 unchanged", "rf_path": v7_art_root + "terrain_height.rf", "rf_sha256": FileAccess.get_sha256(v7_art_root + "terrain_height.rf"), "terrain_mesh_path": v7_art_root + "terrain_mesh.res", "terrain_mesh_sha256": FileAccess.get_sha256(v7_art_root + "terrain_mesh.res"), "source_topology_path": v7_art_root + "source_topology.png", "actual_GPU_RF_input_path": CACHE_ROOT + "terrain_height.rf", "actual_GPU_mesh_input_path": CACHE_ROOT + "terrain_mesh.res", "actual_GPU_support_input_path": CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res", "native_binary_msaa_enum": 0, "native_binary_resized": false, "capture_protocol": V7_PROTOCOL, "cache_copy_provenance": copies}
	var names: Array[String] = ["height_rf_copy", "runtime_mesh_copy", "source_topology_copy", "runtime_shader_copy", "deck_support_mesh_copy"]
	for index in copies.size():
		var entry: Dictionary = copies[index]
		full_geometry[names[index]] = {"path": entry["copy_path"], "sha256": entry["copy_sha256"], "original_path": entry["original_path"], "original_sha256": entry["original_sha256"], "actual_GPU_input_path": entry["actual_GPU_input_path"]}
	pilot_result["actual_RF"] = {"path": CACHE_ROOT + "terrain_height.rf", "sha256": pilot_inputs[CACHE_ROOT + "terrain_height.rf"]}
	pilot_result["authoritative_global_mesh"] = {"path": CACHE_ROOT + "terrain_mesh.res", "sha256": pilot_inputs[CACHE_ROOT + "terrain_mesh.res"]}
	if not _write_json(v7_art_root + "geometry.json", full_geometry): return false
	_full_register_paths(v7_art_root + "geometry.json")
	_full_register_paths(pilot_result["cache_provenance"])
	return true

func _v7_copy_prototypes() -> bool:
	for key: String in native_prototype_cache:
		var proto: Dictionary = native_prototype_cache[key]
		var original: Dictionary = proto["record"].duplicate(true)
		var old_metadata: String = CACHE_ROOT + "prototypes/native_" + key + ".json"
		var original_copy: String = V8_ROOT + "prototypes/native_" + key + "_original_metadata.json"
		if not _full_copy_exact(old_metadata, original_copy): return false
		var revised: Dictionary = _v7_rebind_prototype_paths(original)
		if revised.is_empty() or not error.is_empty(): return false
		revised["metadata_path"] = V8_ROOT + "prototypes/native_" + key + ".json"
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
	var result: Dictionary = {"capture_protocol": V7_PROTOCOL, "capture_role": world_id, "window_id": window_id, "roles": roles, "actual_camera": world["camera"], "actual_native_canvas": world["camera"]["whole_visual_native_canvas"], "actual_logical_canvas": roles["visual"]["logical_rect_px"].slice(2, 4), "actual_whole_GPU_input_canvas": world["camera"]["whole_visual_native_canvas"], "actual_receiver_coverage": world["coverage"], "global_terrain_mesh_path": CACHE_ROOT + "terrain_mesh.res", "global_terrain_mesh_sha256": pilot_inputs[CACHE_ROOT + "terrain_mesh.res"], "height_rf_path": CACHE_ROOT + "terrain_height.rf", "height_rf_sha256": pilot_inputs[CACHE_ROOT + "terrain_height.rf"], "actual_deck_mesh_path": CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res", "actual_deck_mesh_sha256": pilot_inputs[CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res"], "logical_overscan": HALO, "logical_rect_px": roles["visual"]["logical_rect_px"], "CPU_ROI_budget": V7_CPU_ROI_BUDGET, "whole_capture_report_path": V8_REPORT, "binary_MSAA": 0, "binary_resized": false, "whole_CPU_Image_requested": false}
	return result

func _v7_export_chunks_and_refs() -> bool:
	for authored: Dictionary in SOURCE.chunks():
		var id: String = authored["id"]
		var chunk: Dictionary = authored.duplicate(true)
		var capture: Dictionary = _v7_capture_record("primary", id)
		for role: String in ROLE_NAMES:
			var record: Dictionary = capture["roles"][role]
			var destination: String = V8_ROOT + "chunks/" + id + "_" + role + ".png"
			var repeat: String = V8_ROOT + "chunks/" + id + "_" + role + "_repeat.png"
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
		var shadow: Dictionary = _full_ground_evidence(id, rect, on, off, V8_ROOT + "chunks/")
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
		var destination: String = V8_ROOT + "seams/" + id + "_" + role + ".png"
		var repeat: String = V8_ROOT + "seams/" + id + "_" + role + "_repeat.png"
		if not _full_copy_exact(record["path"], destination) or not _full_copy_exact(record["repeat_path"], repeat): return {}
		capture[role + "_path"] = destination
		capture[role + "_repeat_path"] = repeat
		if not capture.has("outputs_sha256"): capture["outputs_sha256"] = {}
		capture["outputs_sha256"][destination] = FileAccess.get_sha256(destination)
		capture["outputs_sha256"][repeat] = FileAccess.get_sha256(repeat)
		_full_register_paths(record)
		var left: Image = Image.load_from_file(V8_ROOT + "chunks/" + String(edge["from"]) + "_" + role + ".png")
		var right: Image = Image.load_from_file(V8_ROOT + "chunks/" + String(edge["to"]) + "_" + role + ".png")
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
		var image: Image = Image.load_from_file(V8_ROOT + "chunks/" + id + "_walk.png")
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
	var path: String = V8_ROOT + "capture/actual_routes_and_doors.json"
	if not _write_json(path, record): return false
	_full_register_paths(path)
	pilot_result["actual_route_and_door_audit"] = {"path": path, "sha256": FileAccess.get_sha256(path), "passed": failures.is_empty(), "centers": centers}
	if not failures.is_empty():
		error = "Actual fullfoot routes/doors disagree with captured native/nav/solids; no ART ready."
		return false
	return true

func _pilot_finish(passed: bool) -> void:
	v7_walk_cache.clear()
	v7_plane_prototypes.clear()
	if not passed:
		pilot_result["status"] = "FULL_NEW_PROTOCOL_REFUSED_OR_TECHNICAL_FAIL"
		pilot_result["reason"] = error
		if v7_started:
			_write_json(V8_ROOT + "art_contract.json", {"status": "TECHNICAL_FAIL", "capture_protocol": V7_PROTOCOL, "reason": error, "production_approved": false})
	var result_path: String = V8_REPORT if v7_started else pilot_output + "refused.json"
	if not passed and not _write_json(result_path, pilot_result): passed = false
	await _pilot_release_world()
	pilot_transport = null
	pilot_global_mesh = null
	pilot_support_mesh = null
	pilot_shader = null
	print("COHERENT_WHOLE_V8_FULL_RESULT ", result_path, " passed=", passed)
	await _finish(passed)

func _pilot_authorized(path: String) -> bool:
	if not _v7_source_guard(): return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		error = "Missing explicit root NEW FULL authorization JSON."
		return false
	pilot_auth = parsed
	if pilot_auth.get("approved", false) != true or pilot_auth.get("scope") != V7_PROTOCOL or pilot_auth.get("builder_path") != get_script().resource_path or String(pilot_auth.get("builder_sha256", "")).to_lower() != FileAccess.get_sha256(get_script().resource_path).to_lower():
		error = "Authorization scope/executed builder SHA mismatch."
		return false
	if pilot_auth.get("allow_full64", false) != true or pilot_auth.get("memory_budget_approved", false) != true:
		error = "NEW FULL64/memory authorization not granted; no allocation."
		return false
	if pilot_auth.get("output_root") != V8_ROOT or pilot_auth.get("source_json_path") != V8_SOURCE_JSON or not _v7_budget_exact(pilot_auth.get("CPU_ROI_budget", {})) or pilot_auth.get("maximum_cpu_roi_pixels", 0) != V7_MAX_CPU_ROI_PIXELS or pilot_auth.get("CPU_whole_402M_Image_allowed", true) != false:
		error = "NEW FULL output/ROI96 budget/whole CPU refusal does not match explicit approval."
		return false
	if not pilot_auth.get("input_sha256") is Dictionary:
		error = "Pinned cache/input catalog missing."
		return false
	pilot_inputs = pilot_auth["input_sha256"]
	for required: String in V8_SOURCE_PINS:
		if not pilot_inputs.has(required) or String(pilot_inputs[required]).to_lower() != String(V8_SOURCE_PINS[required]):
			error = "Mandatory current v7 source/proof absent: " + required
			return false
	if pilot_inputs.get(get_script().resource_path) != FileAccess.get_sha256(get_script().resource_path):
		error = "Executed v8 source must also be in the pinned input closure."
		return false
	for required: String in [CACHE_ROOT + "terrain_height.rf", CACHE_ROOT + "terrain_mesh.res", CACHE_ROOT + "source_topology.png", CACHE_ROOT + "capture/terrain_shader.gdshader", CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res", "res://scripts/dev/world_map_v15_complete_v5_source.gd", "res://scripts/dev/world_map_v15_complete_v5_surface.gd", "res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd", "res://scripts/dev/build_world_map_v15_complete_v5_full_draft.gd", V7_PILOT_PATH, TRANSPORT_PATH, FULL_FOOTPRINTS]:
		if not pilot_inputs.has(required):
			error = "Mandatory frozen input absent: " + required
			return false
	for input_path: String in pilot_inputs:
		if FileAccess.get_sha256(input_path).to_lower() != String(pilot_inputs[input_path]).to_lower():
			error = "Changed frozen input: " + input_path
			return false
	if FileAccess.get_sha256(TRANSPORT_PATH).to_lower() != TRANSPORT_SHA:
		error = "Unapproved transport shader bytes."
		return false
	var proof: Dictionary = pilot_auth.get("transport_proof", {})
	if String(proof.get("path", "")).is_empty() or FileAccess.get_sha256(proof["path"]).to_lower() != String(proof.get("sha256", "")).to_lower():
		error = "Actual StageA/whole transport proof not bound."
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(proof["path"]))
	if not data is Dictionary:
		error = "Actual transport proof JSON invalid."
		return false
	var proof_data: Dictionary = data
	if not bool(proof_data.get("stage_A", {}).get("passed", false)) or not bool(proof_data.get("stage_B", {}).get("passed", false)) or String(proof_data.get("transfer_shader", {}).get("sha256", "")).to_lower() != TRANSPORT_SHA:
		error = "Actual exact StageA and whole native-window proof required; no assumed pass."
		return false
	pilot_proof_gpu_uuid = String(proof_data.get("stage_B", {}).get("baseline", {}).get("gpu_uuid", ""))
	if pilot_proof_gpu_uuid.is_empty() or pilot_proof_gpu_uuid != String(proof_data.get("whole_guard", {}).get("gpu_uuid", "")):
		error = "Actual StageB baseline/guard GPU UUID unavailable or inconsistent."
		return false
	var prior: Dictionary = pilot_auth.get("coherent_pilot_proof", {})
	if prior.get("path") != V7_PILOT_REPORT or prior.get("sha256") != V7_PILOT_REPORT_SHA or FileAccess.get_sha256(V7_PILOT_REPORT) != V7_PILOT_REPORT_SHA or FileAccess.get_sha256(V7_PILOT_PATH) != V7_PILOT_SHA:
		error = "Successful actual bounded coherent pilot/source SHA not bound; FULL refuses."
		return false
	var proof_full: Variant = JSON.parse_string(FileAccess.get_file_as_string(V7_PILOT_REPORT))
	if not proof_full is Dictionary or proof_full.get("status") != "NEW_PROTOCOL_BOUNDED_PILOT_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_REVIEW" or proof_full.get("capture_protocol") != PROTOCOL or not bool(proof_full.get("input_hashes_unchanged_after", false)):
		error = "Bounded pilot does not prove new whole coordinate/kernel protocol; no assumed full approval."
		return false
	return _v7_regional_approval_error().is_empty()

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
		if path == V8_PARENT_PATH and full_catalog[path].to_lower() == V8_PARENT_SHA and dependency == historical_v7_output:
			pilot_result["historical_v7_generated_output_classification"] = {"parent_script": path, "parent_sha256": V8_PARENT_SHA, "declared_output": dependency, "role": "GENERATED_OUTPUT_DECLARATION_NOT_CURRENT_INPUT"}
			continue
		# These are generated outputs, not a phantom pre-existing input. Frozen
		# authoring/capture dependencies remain mandatory and catalog-bound.
		if dependency == V8_SOURCE_JSON or dependency.begins_with(V8_ROOT) or dependency.begins_with("res://build/") or dependency.begins_with(FULL_ROOT): continue
		if dependency.get_extension() not in ["gd", "gdshader", "gltf", "glb", "res", "obj", "tga", "png", "jpg", "json"]: continue
		if not _full_register_literal_inputs(dependency, visited): return false
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
	if overview.save_png(V8_ROOT + "overview.png") != OK:
		error = "Bounded overview save failed."
		return false
	_full_register_paths(V8_ROOT + "overview.png")
	for portal: Dictionary in full_portals:
		var foot := Vector2(portal["door_foot_px"][0], portal["door_foot_px"][1])
		var rect := Rect2i(Vector2i((foot - Vector2(380, 400)).round()), Vector2i(760, 500)).intersection(Rect2i(Vector2i.ZERO, SOURCE.SIZE))
		var scene: Image = _v7_composite_roi(rect)
		if scene == null: return false
		var path: String = V8_ROOT + "capture/doorstep_" + String(portal["id"]) + "_review.png"
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
		var path: String = V8_ROOT + "ecology/" + String(habitat["id"]) + "_scene_components.png"
		if scene.save_png(path) != OK: return false
		_full_register_paths(path)
		var authorities: Array = []
		for chunk: Dictionary in full_chunks:
			if rect.intersects(Rect2i(chunk["logical_rect_px"][0], chunk["logical_rect_px"][1], SOURCE.TILE.x, SOURCE.TILE.y)):
				authorities.append({"id": chunk["id"], "visual_path": chunk["visual_path"], "visual_sha256": FileAccess.get_sha256(chunk["visual_path"]), "capture_window_id": chunk["id"], "capture_role": "primary"})
		var evidence: Dictionary = {"scene_components_path": path, "scene_components_sha256": FileAccess.get_sha256(path), "logical_rect_px": _recti(rect), "scope": "BOUNDED_CPU_COMPOSITE_ACTUAL_WHOLE_CHUNK_GROUND_AND_INDEPENDENT_Y_BODIES_NOT_EXTRA_GPU_CAPTURE", "actual_whole_ground_authorities": authorities, "whole_report_path": V8_REPORT, "no_additional_GPU_window_claim": true}
		if not _write_json(V8_ROOT + "ecology/" + String(habitat["id"]) + ".json", evidence): return false
		_full_register_paths(V8_ROOT + "ecology/" + String(habitat["id"]) + ".json")
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
		var path: String = V8_ROOT + "entities/chunks/" + String(chunk["id"]) + ".json"
		if not _write_json(path, {"schema_version": 15, "chunk_id": chunk["id"], "logical_rect_px": chunk["logical_rect_px"], "object_ids": ids, "entries": entries, "source_objects_are_independent": true}): return false
		_full_register_paths(path)
		chunk["runtime_entity_group"] = {"path": path, "sha256": FileAccess.get_sha256(path), "object_ids": ids}
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
		ecology.append({"id":habitat["id"],"source_XZ_px":[source_point.x,source_point.y],"projected_px":[point.x,point.y],"profile":profiles[index],"actual_rf_height_m":source.triangle_height(source_point),"native_selector":{"gradient":selector["gradient"],"min_height":selector["min_height"],"min_bank":selector["min_bank"],"walk":selector["walk"]},"walkable":all17,"material_binding":_v7_material_bindings(),"review_evidence_path":V8_ROOT+"ecology/"+String(habitat["id"])+".json","review_scope":"BOUNDED_CPU_COMPOSITE_OF_ACTUAL_GLOBAL_CHUNK_CAPTURES_AND_INDEPENDENT_BODIES","scene_components_path":V8_ROOT+"ecology/"+String(habitat["id"])+"_scene_components.png","visual_approved":false})
	var camera_path: String=V8_ROOT+"capture/camera_contract.json"
	if not _write_json(camera_path, {"capture_protocol": V7_PROTOCOL, "whole_capture": true, "local_camera_authority": false, "projection": "orthographic", "logical_pixels_per_meter_x": SOURCE.PPM, "logical_pixels_per_meter_source_z": SOURCE.Z_PPM, "source_world_size_px": _v2i(SOURCE.SIZE), "visual_ssaa_scale": SSAA, "ROI96_halo": HALO, "binary_msaa_enum": 0, "binary_resized": false, "actual_world_cameras": {"primary": pilot_result["worlds"]["primary"]["camera"], "reference": pilot_result["worlds"]["reference"]["camera"]}, "actual_whole_world_receiver_coverage": {"primary": pilot_result["worlds"]["primary"]["coverage"], "reference": pilot_result["worlds"]["reference"]["coverage"]}, "authoring_source": {"path": source.get_script().resource_path, "sha256": FileAccess.get_sha256(source.get_script().resource_path)}, "executed_capture_builder": {"path": get_script().resource_path, "sha256": FileAccess.get_sha256(get_script().resource_path)}, "whole_report_path": V8_REPORT, "whole_CPU_Image_allowed": false, "maximum_CPU_ROI_pixels": V7_MAX_CPU_ROI_PIXELS, "CPU_ROI_budget": V7_CPU_ROI_BUDGET}): return false
	full_catalog[camera_path]=FileAccess.get_sha256(camera_path)
	full_graph[camera_path]=full_catalog[camera_path]
	var semantics_path: String=V8_ROOT+"landmark_semantics.json"
	if not _write_json(semantics_path,{"schema_version":15,"status":"MEASURED_ACTUAL_SOURCE_NOT_FIELD_APPROVED","landmarks":source.semantics,"source_authoring_path":FULL_FOOTPRINTS,"source_authoring_sha256":FileAccess.get_sha256(FULL_FOOTPRINTS)}): return false
	full_catalog[semantics_path]=FileAccess.get_sha256(semantics_path)
	full_graph[semantics_path]=full_catalog[semantics_path]
	full_catalog[FULL_FOOTPRINTS]=FileAccess.get_sha256(FULL_FOOTPRINTS)
	full_graph[FULL_FOOTPRINTS]=full_catalog[FULL_FOOTPRINTS]
	if not _full_overview_and_door_reviews(): return false
	var source_contract: Dictionary={"schema_version":15,"version":"world_v15","status":"ART_ASSETS_READY","authoring_revision":"complete_v5_geography_v4","world_size":[SOURCE.SIZE.x,SOURCE.SIZE.y],"tile_size":[SOURCE.TILE.x,SOURCE.TILE.y],"overview_path":V8_ROOT+"overview.png","chunks":full_chunks,"seams":full_seams,"objects":full_objects,"portals":full_portals,"core_landmarks":full_core_landmarks,"routes":routes,"structures":supports,"ecology_probes":ecology,"geometry":{"grid_size":[SOURCE.GRID_SIZE.x,SOURCE.GRID_SIZE.y],"grid_step_px":SOURCE.GRID_STEP,"height_rf_path":full_geometry["rf_path"],"height_rf_sha256":full_geometry["rf_sha256"],"terrain_mesh_path":full_geometry["terrain_mesh_path"],"terrain_mesh_sha256":full_geometry["terrain_mesh_sha256"]},"pixel_sampling":"round_world_pixel","physical_navigation_margin_px":0,"visual_approved":false,"production_approved":false}
	source_contract["coordinate_version"] = 15
	source_contract["art_revision"] = "complete_v8_coherent_whole"
	source_contract["v7_revision_evidence"] = {"ecology":(source as V8_ECOLOGY).v7_proposal_contract(),"actual_alpha_union":v7_alpha_union,"actual_materials":v7_material_records,"actual_plane_casters":v7_plane_records,"bianzhou_projected_world_approach":_v7_pairs(v7_approach_world),"inverse_RF_records":v7_approach_inverse,"regional_approval":pilot_auth.get("regional_visual_review",{}),"scope":"NEW v8 exact same coordinate15 geometry; source-only revision becomes candidate only after actual FULL and Field"}
	source_contract["v8_revision_evidence"] = {
		"ecology": (source as V8_ECOLOGY).v8_proposal_contract(),
		"actual_materials": (surface as V8_SURFACE).v8_material_records.duplicate(true),
		"actual_execution": pilot_result["actual_v8_execution"].duplicate(true),
		"source_boundary": pilot_result["v8_source_boundary"].duplicate(true),
		"regional_approval": pilot_auth.get("regional_visual_review", {}),
		"scope": "NEW v8 visual ownership and independent nonblocking original lowgrass; original coordinate15/RF/mesh/selector/physical solids and doorway contracts unchanged; NOT Field or formal approval"
	}
	source_contract["capture"] = {"capture_protocol": V7_PROTOCOL, "whole_capture": true, "local_camera_authority": false, "authoring_source": {"path": source.get_script().resource_path, "sha256": FileAccess.get_sha256(source.get_script().resource_path)}, "executed_builder": {"path": get_script().resource_path, "sha256": FileAccess.get_sha256(get_script().resource_path)}, "capture_report": {"path": V8_REPORT, "sha256": FileAccess.get_sha256(V8_REPORT)}, "authoritative_nav_msaa": 0, "authoritative_nav_resize": false, "CPU_ROI_budget": V7_CPU_ROI_BUDGET, "whole_CPU_Image_allowed": false}
	source_contract["geometry"]["geometry_contract_path"] = v7_art_root + "geometry.json"
	source_contract["geometry"]["geometry_contract_sha256"] = FileAccess.get_sha256(v7_art_root + "geometry.json")
	source_contract["geometry"]["height_grid_shape"] = _v2i(SOURCE.GRID_SIZE)
	source_contract["geometry"]["height_grid_origin_px"] = [0, 0]
	source_contract["geometry"]["source_node_spacing_px"] = SOURCE.GRID_STEP
	source_contract["source_graph"] = full_graph.duplicate(true)
	source_contract["asset_sha256"] = full_catalog.duplicate(true) # Excludes this document itself; manifest binds its final SHA.
	var contract_path: String = V8_SOURCE_JSON
	if not _write_json(contract_path,source_contract): return false
	full_catalog[contract_path]=FileAccess.get_sha256(contract_path)
	full_graph[contract_path]=full_catalog[contract_path]
	if not _full_copy_exact(contract_path, V8_ROOT + "source_contract.json"): return false
	var roles: Dictionary={"authoring_source_script":source.get_script().resource_path,"source_assembly_script":get_script().resource_path,"transport_shader":TRANSPORT_PATH,"transport_proof":pilot_auth["transport_proof"]["path"],"terrain_mesh":CACHE_ROOT+"terrain_mesh.res","source_topology":CACHE_ROOT+"source_topology.png","deck_support_mesh":CACHE_ROOT+"chunks/r0_c0_actual_deck_support_mesh.res","whole_capture_report":V8_REPORT,"geometry_contract":V8_ROOT+"geometry.json","source_contract":V8_SOURCE_JSON,"source_script":source.get_script().resource_path,"builder_script":get_script().resource_path,"surface_script":surface.get_script().resource_path,"selector_script":source.get_script().resource_path,"terrain_shader":pilot_result["actual_terrain_shader"]["path"],"height_rf":CACHE_ROOT+"terrain_height.rf","landmark_semantics":semantics_path,"camera_contract":camera_path}
	var capture_graph: Dictionary={}
	for role: String in roles:
		capture_graph[role]={"path":roles[role],"sha256":FileAccess.get_sha256(roles[role])}
	if not _write_json(V8_ROOT+"art_contract.json",{"version":"world_v15","coordinate_version":15,"art_revision":"complete_v8_coherent_whole","capture_protocol":V7_PROTOCOL,"status":"ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","source_contract_path":V8_SOURCE_JSON,"whole_actual_capture":{"path":V8_REPORT,"sha256":FileAccess.get_sha256(V8_REPORT)},"source_graph":full_graph,"capture_graph":capture_graph,"asset_sha256":full_catalog,"chunks":full_chunks,"seams":full_seams,"outside_sourcebody_shadow_pixels":full_shadow_pixels,"native_object_count":source.vegetation_sites.size(),"structure_count":supports.size(),"portal_count":16,"core_count":9,"visual_approved":false,"production_approved":false,"door_review_requires_root":true}): return false
	return true

func _load_pilot_inputs() -> bool:
	source = V8_ECOLOGY.new()
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(CACHE_ROOT + "terrain_height.rf")
	if bytes.size() != SOURCE.GRID_SIZE.x * SOURCE.GRID_SIZE.y * 4:
		error = "Actual cached RF byte count mismatch."
		return false
	source.heights = bytes.to_float32_array()
	source.prepare()
	if not (source as V8_ECOLOGY).v7_proposal_error.is_empty():
		error = (source as V8_ECOLOGY).v7_proposal_error
		return false
	if not _v7_replace_bianzhou_approach() or not _v8_source_boundary(): return false
	full_rf = ImageTexture.create_from_image(Image.create_from_data(SOURCE.GRID_SIZE.x, SOURCE.GRID_SIZE.y, false, Image.FORMAT_RF, bytes))
	var topology: Image = Image.load_from_file(CACHE_ROOT + "source_topology.png")
	if topology == null or topology.get_size() != SOURCE.SIZE / SOURCE.SELECTOR_STEP:
		error = "Cached selector size missing."
		return false
	full_topology = ImageTexture.create_from_image(topology)
	pilot_global_mesh = ResourceLoader.load(CACHE_ROOT + "terrain_mesh.res", "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
	pilot_support_mesh = ResourceLoader.load(CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res", "", ResourceLoader.CACHE_MODE_IGNORE) as Mesh
	pilot_shader = Shader.new()
	pilot_transport = ResourceLoader.load(TRANSPORT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as Shader
	if pilot_global_mesh == null or pilot_support_mesh == null or pilot_shader == null or pilot_transport == null:
		error = "Actual frozen mesh/support/shader load failed."
		return false
	surface = V8_SURFACE.new()
	if not surface.load_sources():
		error = surface.error
		return false
	for entry: Dictionary in surface.evidence:
		for key: String in ["path", "source_path"]:
			var p: String = entry[key]
			if not pilot_inputs.has(p) or FileAccess.get_sha256(p).to_lower() != String(pilot_inputs[p]).to_lower():
				error = "Unpinned actual PBR dependency: " + p
				return false
	full_map_textures = _material_maps(Rect2(Vector2.ZERO, Vector2(SOURCE.SIZE)))
	if full_map_textures.is_empty(): return false
	var weights: Dictionary = {}
	for role: String in ["ecology", "roads"]:
		var image: Image = full_map_textures[role].get_image()
		var path: String = pilot_output + role + "_reconstructed.png"
		if image.save_png(path) != OK:
			error = "Weight texture write failed."
			return false
		weights[role] = {"path": path, "sha256": FileAccess.get_sha256(path), "canvas": _v2i(image.get_size()), "recipe": "NEW 4px ownership; original RF/selector unchanged; inverse-RF Bianzhou road explicitly revised"}
	var actual_material: ShaderMaterial = surface.terrain_material(full_map_textures["ecology"], full_map_textures["roads"], Rect2(Vector2.ZERO, Vector2(SOURCE.SIZE)))
	if actual_material == null or actual_material.shader == null:
		error = "NEW actual v8 material absent."
		return false
	pilot_shader = actual_material.shader
	var shader_path: String = pilot_output + "v8_actual_terrain_shader.gdshader"
	if ResourceSaver.save(pilot_shader, shader_path) != OK:
		error = "Cannot save NEW actual v8 shader."
		return false
	full_catalog[shader_path] = FileAccess.get_sha256(shader_path)
	full_graph[shader_path] = full_catalog[shader_path]
	pilot_result["actual_terrain_shader"] = {"path":shader_path,"sha256":full_catalog[shader_path],"source_script":surface.get_script().resource_path,"source_script_sha256":FileAccess.get_sha256(surface.get_script().resource_path)}
	v7_material_records = (surface as V8_SURFACE).v7_material_records.duplicate(true)
	pilot_result["actual_v8_execution"] = {
		"ecology": {"path": source.get_script().resource_path, "sha256": FileAccess.get_sha256(source.get_script().resource_path)},
		"surface": {"path": surface.get_script().resource_path, "sha256": FileAccess.get_sha256(surface.get_script().resource_path)},
		"inherited_full": {"path": V8_PARENT_PATH, "sha256": V8_PARENT_SHA}
	}
	for kind: String in ["boulder", "tree", "bamboo", "herb"]:
		for pose in 3:
			var metadata_path: String = CACHE_ROOT + "prototypes/native_" + kind + str(pose) + ".json"
			if not pilot_inputs.has(metadata_path):
				error = "Unpinned native prototype metadata."
				return false
			var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
			if not parsed is Dictionary:
				error = "Native metadata parse failed."
				return false
			var record: Dictionary = parsed
			for key: String in ["actual_draw_mesh_path", "texture", "sourcebody_raw", "sourcebody_repeat", "draw_mesh_source"]:
				if not pilot_inputs.has(record[key]):
					error = "Unpinned actual native prototype input: " + String(record[key])
					return false
			if FileAccess.get_sha256(record["actual_draw_mesh_path"]) != record["actual_draw_mesh_sha256"] or record.get("kind") != kind or int(record.get("pose", -1)) != pose:
				error = "Actual native draw source/pose mismatch."
				return false
			var mesh: ArrayMesh = ResourceLoader.load(record["actual_draw_mesh_path"], "", ResourceLoader.CACHE_MODE_IGNORE) as ArrayMesh
			var body: Image = Image.load_from_file(record["texture"])
			if mesh == null or body == null or body.is_empty():
				error = "Frozen caster mesh/sourcebody missing."
				return false
			var bounds: Dictionary = _pilot_native_bounds(mesh)
			if bounds.is_empty(): return false
			var b: Array = record["basis_columns"]
			var support: Vector3 = _array3(record["support_m"])
			var uv: Array = record["foot_uv"]
			native_prototype_cache[kind + str(pose)] = {"mesh": mesh, "basis": Basis(_array3(b[0]), _array3(b[1]), _array3(b[2])), "support": support, "image": body, "foot": Vector2(uv[0] * body.get_width(), uv[1] * body.get_height()), "record": record, "actual_native_bounds": bounds}
	pilot_result["cache_provenance"] = {"producer_approved_exact_SHA_reuse": true, "origin": "ROOT066 failed per-frustum capture; reuse only exact same-source authored RF/selector/native geometry, NOT its failed seam or visual approval", "height_grid_regenerated": false, "25M_selector_regenerated": false, "global_mesh_reserialized_as_original": false, "rf_shape": _v2i(SOURCE.GRID_SIZE), "rf_spacing_px": SOURCE.GRID_STEP, "weight_maps": weights}
	pilot_result["actual_materials"] = surface.evidence.duplicate(true)
	return true

func _material_maps(rect: Rect2) -> Dictionary:
	var maps: Dictionary = (source as V8_ECOLOGY).visual_material_maps(rect)
	if maps.get("step_px") != 4 or not maps.get("biome") is Image or not maps.get("roads") is Image:
		error = "NEW v8 exact 4px ownership maps absent."
		return {}
	var biome: Image = maps["biome"]
	var road: Image = maps["roads"]
	if biome.has_mipmaps() or road.has_mipmaps() or biome.get_size() != Vector2i(ceili(rect.size.x/4.),ceili(rect.size.y/4.)) or road.get_size() != biome.get_size():
		error = "NEW v8 map canvas/mip mismatch."
		return {}
	return {"ecology":ImageTexture.create_from_image(biome),"roads":ImageTexture.create_from_image(road)}

func _v7_source_guard() -> bool:
	# Pin every old dependency/proof and the actual inherited executor as well
	# as new ecology/surface/regional bytes; this is not a mutable parent const.
	if not super._v7_source_guard(): return false
	for path: String in V8_SOURCE_PINS:
		if FileAccess.get_sha256(path).to_lower() != String(V8_SOURCE_PINS[path]):
			error = "NEW v8 exact dependency differs or is still pending: " + path
			return false
	return true

func _v8_source_boundary() -> bool:
	if source.heights.to_byte_array() != FileAccess.get_file_as_bytes(CACHE_ROOT + "terrain_height.rf"):
		error = "V8 source must use the exact old RF bytes; no visual height change."
		return false
	var actual_source: V8_ECOLOGY = source as V8_ECOLOGY
	if actual_source == null or actual_source.v8_bank_sites.is_empty():
		error = "V8 actual ecology object/independent dry-bank sites missing."
		return false
	# Compare the prepared old proposal against the actual new one in the same
	# native Variant domain, not a JSON float-vs-int structural comparison.
	var baseline := V7_ECOLOGY.new()
	baseline.heights = actual_source.heights
	baseline.prepare()
	if not baseline.v7_proposal_error.is_empty():
		error = baseline.v7_proposal_error
		return false
	source = baseline
	var approach_ok: bool = _v7_replace_bianzhou_approach()
	source = actual_source
	if not approach_ok: return false
	if baseline.routes != actual_source.routes or baseline.structures != actual_source.structures:
		error = "V8 changed the original27 routes/bridge support after exact Bianzhou replay."
		return false
	var by_id: Dictionary = {}
	for site: Dictionary in actual_source.vegetation_sites:
		var id: String = site.get("id", "")
		if id.is_empty() or by_id.has(id):
			error = "V8 duplicate or missing independent site ID."
			return false
		by_id[id] = site
	for old_site: Dictionary in baseline.vegetation_sites:
		var id: String = old_site["id"]
		if not by_id.has(id) or by_id[id] != old_site:
			error = "V8 changed original stem/body/pose/physical contract: " + id
			return false
		by_id.erase(id)
	if by_id.size() != actual_source.v8_bank_sites.size():
		error = "V8 additions do not equal the declared independent lowgrass set."
		return false
	var complete17: int = 0
	for site: Dictionary in actual_source.v8_bank_sites:
		var id: String = site.get("id", "")
		if not by_id.has(id) or by_id[id] != site or not id.begins_with("v8_marsh_lowgrass_") or site.get("kind") != "herb" or not site.get("pose") is int or site["pose"] < 0 or site["pose"] > 2 or site.get("blocking") != false or site.get("collision_size_px") != Vector2.ZERO:
			error = "V8 additions must be unchanged native-pose nonblocking herb bodies."
			return false
		var foot: Vector2 = site["source_foot"]
		if actual_source.triangle_height(foot) <= SOURCE.WATER_Y:
			error = "V8 lowgrass source foot is not on actual dry RF."
			return false
		for offset: Vector2 in actual_source.foot_offsets():
			if not bool(actual_source.selector_cell_info(foot + offset)["walk"]):
				error = "V8 lowgrass complete17 source shoe intersects original black selector."
				return false
			complete17 += 1
	pilot_result["v8_source_boundary"] = {
		"passed": true, "method": "NATIVE_PREPARED_OLD_AND_NEW_EXACT_IDENTITY_PLUS_DECLARED_NONBLOCKING_ADDITIONS_V1",
		"original_source": {"path": "res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd", "sha256": V8_SOURCE_PINS["res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd"]},
		"original_RF_sha256": pilot_inputs[CACHE_ROOT + "terrain_height.rf"],
		"old_instances_exact": baseline.vegetation_sites.size(), "new_independent_lowgrass_instances": by_id.size(),
		"original_routes_exact": 27, "original_structures_exact": baseline.structures.size(),
		"new_source_17_points_checked": complete17, "navigation_threshold_changed": false,
		"new_body_caster_recipe": "original native herb used-index mesh/pose; never tree/bamboo camera plane",
		"scope": "SOURCE_RF_SELECTOR_AND_AUTHORED_PHYSICAL_BOUNDARY_NOT_ACTUAL_PNG_OR_FIELD_APPROVAL"
	}
	return true

func _v7_regional_approval_error() -> String:
	var review: Variant = pilot_auth.get("regional_visual_review")
	if not review is Dictionary or review.get("approved_by") != "root" or review.get("approved") != true or review.get("scope") != V8_REGIONAL_SCOPE:
		error = "NEW v8 FULL requires independent current four-region root visual review."
		return error
	var target: Variant = review.get("candidate_full_builder")
	if not target is Dictionary or target.get("path") != get_script().resource_path or String(target.get("sha256", "")).to_lower() != FileAccess.get_sha256(get_script().resource_path).to_lower():
		error = "Regional review must bind this exact new FULL as its target, not falsely its executor."
		return error
	var path: String = review.get("result_path", "")
	if not path.begins_with(V8_REGIONAL_ROOT) or String(review.get("result_sha256", "")).length() != 64 or FileAccess.get_sha256(path).to_lower() != String(review["result_sha256"]).to_lower():
		error = "NEW v8 regional actual result path/current SHA not bound."
		return error
	var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not result is Dictionary or result.get("scope") != V8_REGIONAL_SCOPE or result.get("status") != "V8_REGIONAL_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_NOT_FULL_OR_FIELD" or result.get("input_hashes_unchanged_after") != true:
		error = "Actual v8 regional mechanism result incomplete or not current."
		return error
	var union: Variant = result.get("alpha_union")
	var executor: Variant = result.get("executed_builder")
	var closure: Variant = result.get("cached_inputs_sha256")
	var actual: Variant = result.get("actual_v8_execution")
	if not union is Dictionary or union.get("passed") != true or not executor is Dictionary or executor.get("path") != V8_REGIONAL_PATH or String(executor.get("sha256", "")).to_lower() != String(V8_SOURCE_PINS[V8_REGIONAL_PATH]) or not closure is Dictionary or not actual is Dictionary:
		error = "Actual v8 alpha/executor/source closure missing."
		return error
	for dependency: String in V8_SOURCE_PINS:
		# FULL is the independently reviewed target, not a fictional regional parent.
		if dependency == V8_REGIONAL_PATH: continue
		if String(closure.get(dependency, "")).to_lower() != String(V8_SOURCE_PINS[dependency]):
			error = "Regional evidence has a different actual ecology/material/parent/proof revision: " + dependency
			return error
	var real_paths: Dictionary = {
		"ecology": "res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd",
		"surface": "res://scripts/dev/world_map_v15_complete_v8_surface_proposal.gd",
		"inherited_regional": V8_REGIONAL_PARENT, "inherited_full": V8_PARENT_PATH
	}
	for role: String in real_paths:
		var evidence: Variant = actual.get(role)
		var actual_path: String = real_paths[role]
		if not evidence is Dictionary or evidence.get("path") != actual_path or String(evidence.get("sha256", "")).to_lower() != String(V8_SOURCE_PINS[actual_path]):
			error = "Regional actual object/parent identity differs: " + role
			return error
	var regions: Variant = result.get("regions")
	if not regions is Array or regions.size() != 4:
		error = "All four current v8 regional cases are required."
		return error
	var expected_ids: Array[String] = ["farmland", "marsh", "river", "snow"]
	for region: Variant in regions:
		if not region is Dictionary or not expected_ids.has(region.get("id", "")):
			error = "Duplicate/unknown v8 regional case."
			return error
		expected_ids.erase(region["id"])
		var worlds: Variant = region.get("worlds")
		var compared: Variant = region.get("comparisons")
		if not worlds is Dictionary or worlds.size() != 2 or not compared is Dictionary or compared.size() != ROLE_NAMES.size():
			error = "Regional independent two worlds/all5 role evidence missing."
			return error
		for role: String in ROLE_NAMES:
			var comparison: Variant = compared.get(role)
			if not comparison is Dictionary or not comparison.get("raw") is Dictionary or not comparison.get("logical") is Dictionary or comparison["raw"].get("byte_exact") != true or comparison["logical"].get("byte_exact") != true:
				error = "Actual current v8 raw/logical comparison failed: " + role
				return error
			for identity: String in ["primary", "reference"]:
				var world: Variant = worlds.get(identity)
				if not world is Dictionary or world.get("actual_world_released_before_next") != true or not world.get("roles") is Dictionary or not world["roles"].get(role) is Dictionary:
					error = "Actual independent regional world/role not complete/released."
					return error
				var windows: Variant = world["roles"][role].get("windows")
				if not windows is Dictionary or not windows.get("region") is Dictionary:
					error = "Actual regional native window missing."
					return error
				var window: Dictionary = windows["region"]
				for file_key: String in ["path", "repeat_path", "raw_path", "raw_repeat_path"]:
					var binding: Dictionary = window
					var path_key: String = file_key
					var file: Variant = window.get(file_key)
					if file_key in ["repeat_path", "raw_repeat_path"]:
						var repeated: Variant = window.get("repeat_transfer_evidence")
						if not repeated is Dictionary:
							error = "Actual second regional transfer evidence missing."
							return error
						binding = repeated
						path_key = "path" if file_key == "repeat_path" else "raw_path"
						if binding.get(path_key) != file:
							error = "Regional second draw path differs from actual repeat transfer."
							return error
					var sha_key: String = "sha256" if path_key == "path" else "raw_sha256"
					if not file is String or not file.begins_with(V8_REGIONAL_ROOT) or String(binding.get(sha_key, "")).length() != 64 or FileAccess.get_sha256(file).to_lower() != String(binding[sha_key]).to_lower():
						error = "Regional actual original/repeat PNG changed or is not bound: " + file_key
						return error
		if region["id"] == "river":
			var approach: Variant = region.get("actual_full17_approach")
			if not approach is Dictionary or approach.get("passed") != true:
				error = "Actual v8 Bianzhou native17 approach is not proven."
				return error
	return ""

