extends "res://scripts/dev/build_world_map_v15_coherent_whole_v6_pilot.gd"

## NEW complete capture protocol. Authoring coordinates remain VERSION15.
## Frozen F812 source/AD83 surface/066 geometry are dependencies, NOT this executor.
## No old ART, router, gate, QA, player saves or formal map writes.
const V7_ROOT := "res://art/maps/world_map_v15_complete_v7/"
const V7_SOURCE_JSON := "res://data/maps/world_map_v15_complete_v7_source.json"
const V7_PROTOCOL := "COHERENT_WHOLE_FIXED_CAMERA_INTEGER_TEXEL_ROI_V1_FULL"
const V7_REPORT := V7_ROOT + "whole_actual_capture.json"
const V7_MAX_CPU_ROI_PIXELS := 8404992
const V7_CPU_ROI_BUDGET := {"previous_pilot_pixels": 8388608, "maximum_pixels": 8404992, "maximum_native_canvas": [3456, 2432], "logical_tile": [1536, 1024], "logical_halo_px": 96, "ssaa_scale": 2, "additional_pixels": 16384, "additional_RGBA_bytes": 65536, "whole_CPU_Image_allowed": false}
const V7_SCOPE := "FULL64_112SEAMS_NEW_PROTOCOL_NOT_FORMAL_APPROVED"
const V7_STATUS := "FULL64_112SEAMS_NEW_PROTOCOL_TECHNICAL_PASS_REQUIRES_ROOT_VISUAL_REVIEW"
const V7_PILOT_PATH := "res://scripts/dev/build_world_map_v15_coherent_whole_v6_pilot.gd"
const V7_PILOT_SHA := "baad78a8b8a5e414b0a0293feb2daae51b32e86d565e7a5479f683b5a419299f"
const V7_PILOT_REPORT := "res://build/world_map_v15_coherent_whole_v6_pilot/1791066772_2575509/result.json"
const V7_PILOT_REPORT_SHA := "ca506b4f4f84e02d5cea327264636599cb421f9f48148fdd7961f114f919dbf1"
## Independent v7 proposal. Mechanical CF21 capture semantics plus explicit
## ecology/material/caster/approach revision; not compiled, executed or approved.
## FULL refuses until separate current-source regional ROOT review is bound.
const V7_CF21_PATH := "res://scripts/dev/build_world_map_v15_coherent_whole_v6_full.gd"
const V7_CF21_SHA := "cf21d191b911c32b156be4f27809827ab95961dfa0b49c117c3565c5794c83e0"
const V7_ECOLOGY := preload("res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd")
const V7_SURFACE := preload("res://scripts/dev/world_map_v15_complete_v7_surface_proposal.gd")
const V7_CASTER := preload("res://scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd")
const V7_SOURCE_PINS := {
 "res://scripts/dev/world_map_v15_complete_v7_ecology_source_proposal.gd":"434aca511887eb06939fcd85cbe815b74e1f3fc3c7b560777fb91e78e91a5d16",
 "res://scripts/dev/world_map_v15_complete_v7_surface_proposal.gd":"1298830248abab6626beb0d3abd2fb653ccdbf55419386221edd0a23fb87e1f9",
 "res://scripts/dev/world_map_v15_complete_v7_billboard_caster_proposal.gd":"d2d3795942aa452a18abc006d45bcde44749ccad276a7ec16e0f897604611290",
 V7_CF21_PATH:V7_CF21_SHA,
 "res://scripts/dev/test_world_v15_native_combined_rgba_word_stats_unit.gd":"f5ffe7adf8e9155f19fcd8640da51724605152dfe8bc1d3875789a8688d82608",
 "res://build/world_v15_native_binary_stats_unit/1791073994_1612124/result.json":"dde934b08ceacef6a887547c28af6296a0d6a2d5e9719b20775048582493c7e9"
}
const V7_REGIONAL_SCOPE := "V7_REGIONAL_NATIVE_GEOMETRY_ALPHA_SHADOW_NOT_FULL64"
var v7_art_root := V7_ROOT
var v7_regional := false
var v7_region_rect := Rect2i()
var v7_approach_world := PackedVector2Array()
var v7_approach_inverse: Array[Dictionary] = []
var v7_material_records: Array[Dictionary] = []
var v7_plane_records: Array[Dictionary] = []
var v7_alpha_union: Dictionary = {}
var v7_plane_prototypes: Dictionary = {}

var v7_windows: Array[Dictionary] = []
var v7_walk_cache: Dictionary = {}
var v7_started := false
var v7_auth_path := ""

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	pilot_output = "res://build/world_map_v15_coherent_whole_v7_full/%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	failure_output = pilot_output
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(pilot_output))
	if "--coherent-whole-v7-full" not in args or DisplayServer.get_name() == "headless":
		error = "NEW FULL explicit GPU authorization required; default/headless/pilot invocation refuses."
		await _pilot_finish(false)
		return
	for arg: String in args:
		if arg.begins_with("--authorization="): v7_auth_path = arg.trim_prefix("--authorization=")
	if not _pilot_authorized(v7_auth_path):
		await _pilot_finish(false)
		return
	# Never overwrite previous current/failed candidates. Root archives them.
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(V7_ROOT)) or FileAccess.file_exists(V7_SOURCE_JSON):
		error = "NEW v7 root/source JSON must be absent before capture; root recoverable archive required."
		await _pilot_finish(false)
		return
	for folder: String in ["", "capture/", "entities/", "prototypes/", "chunks/", "seams/", "ecology/", "entities/chunks/"]:
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(V7_ROOT + folder)) != OK:
			error = "Cannot create NEW v7 artifact directory."
			await _pilot_finish(false)
			return
	v7_started = true
	pilot_output = V7_ROOT + "capture/"
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
		print("V7_FULL_WORLD_BEGIN ", identity, " ", Time.get_ticks_usec())
		var measured: Dictionary = await _pilot_capture_world(identity)
		if measured.is_empty():
			await _pilot_finish(false)
			return
		pilot_result["worlds"][identity] = measured
		print("V7_FULL_WORLD_RELEASED ", identity, " ", Time.get_ticks_usec())
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
	if not _write_json(V7_REPORT, pilot_result):
		await _pilot_finish(false)
		return
	full_catalog[V7_REPORT] = FileAccess.get_sha256(V7_REPORT)
	full_graph[V7_REPORT] = full_catalog[V7_REPORT]
	_full_register_paths(pilot_result)
	_full_register_paths(v7_auth_path)
	if not _full_assemble_contract():
		await _pilot_finish(false)
		return
	await _pilot_finish(true)

func _full_prepare_semantics() -> bool:
	var authored: Variant = JSON.parse_string(FileAccess.get_file_as_string(FULL_FOOTPRINTS))
	if not authored is Dictionary or String(pilot_auth.get("source_footprints_sha256", "")).to_lower() != FileAccess.get_sha256(FULL_FOOTPRINTS).to_lower():
		error = "NEW FULL exact source-authoring footprint pin missing."
		return false
	source.semantics.clear()
	for landmark: Dictionary in SOURCE.LANDMARKS:
		var id: String = landmark["id"]
		var measured: Dictionary = authored.get("landmarks", {}).get(id, {})
		if not pilot_inputs.has(landmark["source"]) or measured.get("status") != "SOURCE_FOOTPRINT_AUTHORED_REQUIRES_ROOT_REVIEW" or measured.get("source") != landmark["source"] or String(measured.get("source_sha256", "")).to_lower() != FileAccess.get_sha256(landmark["source"]).to_lower() or measured.get("solid_polygons_source_px", []).is_empty() or measured.get("passage_path_source_px", []).size() < 2:
			error = "Missing genuine unchanged doorway source semantics: " + id
			return false
		var record: Dictionary = measured.duplicate(true)
		record["status"] = "MEASURED_ACTUAL_SOURCE"
		record["visual_review_status"] = "PENDING_CURRENT_COMPOSITE_AND_FIELD"
		record["root_source_authoring_approval_sha256"] = FileAccess.get_sha256(FULL_FOOTPRINTS)
		source.semantics[id] = record
	return true

func _v7_copy_geometry() -> bool:
	var copies: Array[Dictionary] = []
	for pair: Array in [["terrain_height.rf", "terrain_height.rf"], ["terrain_mesh.res", "terrain_mesh.res"], ["source_topology.png", "source_topology.png"], ["capture/terrain_shader.gdshader", "capture/terrain_shader.gdshader"], ["chunks/r0_c0_actual_deck_support_mesh.res", "deck_support_mesh.res"]]:
		var original: String = CACHE_ROOT + pair[0]
		if pair[0]=="capture/terrain_shader.gdshader": original=pilot_result["actual_terrain_shader"]["path"]
		var copy: String = v7_art_root + pair[1]
		if not _full_copy_exact(original, copy): return false
		copies.append({"original_path": original, "original_sha256": FileAccess.get_sha256(original), "copy_path": copy, "copy_sha256": FileAccess.get_sha256(copy), "actual_GPU_input_path": original, "byte_exact_copy": true, "provenance": "NEW actual v7 Shader instance saved before draw; created by exact v7 surface source, not loaded from old shader" if pair[0]=="capture/terrain_shader.gdshader" else "Frozen authored geometry input from ROOT066; NOT reuse of its rejected narrow-frustum seam acceptance"})
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
		var original_copy: String = V7_ROOT + "prototypes/native_" + key + "_original_metadata.json"
		if not _full_copy_exact(old_metadata, original_copy): return false
		var revised: Dictionary = _v7_rebind_prototype_paths(original)
		if revised.is_empty() or not error.is_empty(): return false
		revised["metadata_path"] = V7_ROOT + "prototypes/native_" + key + ".json"
		revised["sourcebody_capture_origin"] = {"scope": "BYTE_EXACT_FROZEN_SAME_POSE_CACHE_REUSE_NOT_NEW_BODY_RENDER", "original_metadata_path": old_metadata, "original_metadata_sha256": FileAccess.get_sha256(old_metadata), "original_metadata_copy_path": original_copy, "actual_GPU_loaded_mesh_path": original["actual_draw_mesh_path"], "actual_GPU_loaded_mesh_sha256": original["actual_draw_mesh_sha256"], "new_mesh_artifact_is_exact_copy": true}
		revised["alpha_unpremultiply_epsilon"] = .00001
		if not _write_json(revised["metadata_path"], revised): return false
		proto["record"] = revised
		native_prototype_cache[key] = proto
		_full_register_paths(original)
		_full_register_paths(revised)
	return true

func _v7_rebind_prototype_paths(value: Variant) -> Variant:
	if value is String and value.begins_with(CACHE_ROOT + "prototypes/") and FileAccess.file_exists(value):
		# Metadata itself is retained separately, never silently rewritten as raw.
		if value.get_extension() == "json": return value
		var destination: String = String(value).replace(CACHE_ROOT, v7_art_root)
		if not _full_copy_exact(value, destination): return null
		return destination
	if value is Dictionary:
		var mapped: Dictionary = {}
		for key: Variant in value:
			var next: Variant = _v7_rebind_prototype_paths(value[key])
			if next == null and value[key] != null: return {}
			mapped[key] = next
		return mapped
	if value is Array:
		var mapped_array: Array = []
		for item: Variant in value:
			var next: Variant = _v7_rebind_prototype_paths(item)
			if next == null and item != null: return []
			mapped_array.append(next)
		return mapped_array
	return value

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
		pilot_result["current_actual_regional_receiver"]={"path":regional_mesh_path,"sha256":FileAccess.get_sha256(regional_mesh_path),"source_RF":CACHE_ROOT+"terrain_height.rf","source_RF_sha256":pilot_inputs[CACHE_ROOT+"terrain_height.rf"],"source_rect":_recti(v7_region_rect.grow(1024)),"scope":"regional local mesh recreated from exact global RF, NOT whole mesh draw"}
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
	return true

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

func _pilot_compare() -> bool:
	var exact := true
	for role: String in ROLE_NAMES:
		var a: Dictionary = pilot_result["worlds"]["primary"]["roles"][role]["windows"]
		var b: Dictionary = pilot_result["worlds"]["reference"]["roles"][role]["windows"]
		var evidence: Dictionary = {}
		for window: Dictionary in _pilot_windows():
			var id: String = window["id"]
			var diff: Dictionary = _pilot_compare_pngs(a[id]["path"], b[id]["path"])
			var raw_diff: Dictionary = _pilot_compare_pngs(a[id]["raw_path"], b[id]["raw_path"])
			diff["independent_raw_RGBA"] = raw_diff
			evidence[id] = diff
			exact = exact and bool(diff["byte_exact"]) and bool(raw_diff["byte_exact"])
		pilot_result["comparisons"][role] = {"independent_worlds_same_global_coordinates": evidence, "tolerance": 0}
	var first: Dictionary = pilot_result["worlds"]["primary"]
	var second: Dictionary = pilot_result["worlds"]["reference"]
	if first["world_node_instance_id"] == second["world_node_instance_id"] or first["world_3d_instance_id"] == second["world_3d_instance_id"] or not bool(first["actual_world_released_before_next"]) or not bool(second["actual_world_released_before_next"]): exact = false
	if not exact: error = "FULL independent actual whole frames differ; no copying/reference or tolerance waiver."
	return exact

func _v7_capture_record(world_id: String, window_id: String) -> Dictionary:
	var world: Dictionary = pilot_result["worlds"][world_id]
	var roles: Dictionary = {}
	for role: String in ROLE_NAMES: roles[role] = world["roles"][role]["windows"][window_id].duplicate(true)
	var result: Dictionary = {"capture_protocol": V7_PROTOCOL, "capture_role": world_id, "window_id": window_id, "roles": roles, "actual_camera": world["camera"], "actual_native_canvas": world["camera"]["whole_visual_native_canvas"], "actual_logical_canvas": roles["visual"]["logical_rect_px"].slice(2, 4), "actual_whole_GPU_input_canvas": world["camera"]["whole_visual_native_canvas"], "actual_receiver_coverage": world["coverage"], "global_terrain_mesh_path": CACHE_ROOT + "terrain_mesh.res", "global_terrain_mesh_sha256": pilot_inputs[CACHE_ROOT + "terrain_mesh.res"], "height_rf_path": CACHE_ROOT + "terrain_height.rf", "height_rf_sha256": pilot_inputs[CACHE_ROOT + "terrain_height.rf"], "actual_deck_mesh_path": CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res", "actual_deck_mesh_sha256": pilot_inputs[CACHE_ROOT + "chunks/r0_c0_actual_deck_support_mesh.res"], "logical_overscan": HALO, "logical_rect_px": roles["visual"]["logical_rect_px"], "CPU_ROI_budget": V7_CPU_ROI_BUDGET, "whole_capture_report_path": V7_REPORT, "binary_MSAA": 0, "binary_resized": false, "whole_CPU_Image_requested": false}
	return result

func _v7_export_chunks_and_refs() -> bool:
	for authored: Dictionary in SOURCE.chunks():
		var id: String = authored["id"]
		var chunk: Dictionary = authored.duplicate(true)
		var capture: Dictionary = _v7_capture_record("primary", id)
		for role: String in ROLE_NAMES:
			var record: Dictionary = capture["roles"][role]
			var destination: String = V7_ROOT + "chunks/" + id + "_" + role + ".png"
			var repeat: String = V7_ROOT + "chunks/" + id + "_" + role + "_repeat.png"
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
		var shadow: Dictionary = _full_ground_evidence(id, rect, on, off, V7_ROOT + "chunks/")
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
		var destination: String = V7_ROOT + "seams/" + id + "_" + role + ".png"
		var repeat: String = V7_ROOT + "seams/" + id + "_" + role + "_repeat.png"
		if not _full_copy_exact(record["path"], destination) or not _full_copy_exact(record["repeat_path"], repeat): return {}
		capture[role + "_path"] = destination
		capture[role + "_repeat_path"] = repeat
		if not capture.has("outputs_sha256"): capture["outputs_sha256"] = {}
		capture["outputs_sha256"][destination] = FileAccess.get_sha256(destination)
		capture["outputs_sha256"][repeat] = FileAccess.get_sha256(repeat)
		_full_register_paths(record)
		var left: Image = Image.load_from_file(V7_ROOT + "chunks/" + String(edge["from"]) + "_" + role + ".png")
		var right: Image = Image.load_from_file(V7_ROOT + "chunks/" + String(edge["to"]) + "_" + role + ".png")
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
		var image: Image = Image.load_from_file(V7_ROOT + "chunks/" + id + "_walk.png")
		if image == null or image.get_size() != SOURCE.TILE: return false
		v7_walk_cache[id] = image
	var image: Image = v7_walk_cache[id]
	return image.get_pixel(pixel.x - col * SOURCE.TILE.x, pixel.y - row * SOURCE.TILE.y) == Color.WHITE

func _v7_actor_point_clear(p: Vector2) -> bool:
	if not _full_sample_walk(p) or not _full_compound_clear(p): return false
	for object: Dictionary in full_objects:
		if not bool(object.get("blocking", false)) or object.has("solid_polygons_px"): continue
		if object.has("collision_center_world_px") and object.has("collision_size_px"):
			var center: Array = object["collision_center_world_px"]
			var size: Array = object["collision_size_px"]
			if Rect2(Vector2(center[0], center[1]) - Vector2(size[0], size[1]) * .5, Vector2(size[0], size[1])).has_point(p): return false
	return true

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
	var path: String = V7_ROOT + "capture/actual_routes_and_doors.json"
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
			_write_json(V7_ROOT + "art_contract.json", {"status": "TECHNICAL_FAIL", "capture_protocol": V7_PROTOCOL, "reason": error, "production_approved": false})
	var result_path: String = V7_REPORT if v7_started else pilot_output + "refused.json"
	if not passed and not _write_json(result_path, pilot_result): passed = false
	await _pilot_release_world()
	pilot_transport = null
	pilot_global_mesh = null
	pilot_support_mesh = null
	pilot_shader = null
	print("COHERENT_WHOLE_V7_FULL_RESULT ", result_path, " passed=", passed)
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
	if pilot_auth.get("output_root") != V7_ROOT or pilot_auth.get("source_json_path") != V7_SOURCE_JSON or not _v7_budget_exact(pilot_auth.get("CPU_ROI_budget", {})) or pilot_auth.get("maximum_cpu_roi_pixels", 0) != V7_MAX_CPU_ROI_PIXELS or pilot_auth.get("CPU_whole_402M_Image_allowed", true) != false:
		error = "NEW FULL output/ROI96 budget/whole CPU refusal does not match explicit approval."
		return false
	if not pilot_auth.get("input_sha256") is Dictionary:
		error = "Pinned cache/input catalog missing."
		return false
	pilot_inputs = pilot_auth["input_sha256"]
	for required: String in V7_SOURCE_PINS:
		if not pilot_inputs.has(required) or String(pilot_inputs[required]).to_lower() != String(V7_SOURCE_PINS[required]):
			error = "Mandatory current v7 source/proof absent: " + required
			return false
	if pilot_inputs.get(get_script().resource_path) != FileAccess.get_sha256(get_script().resource_path):
		error = "Executed v7 source must also be in the pinned input closure."
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

func _v7_budget_exact(value: Variant) -> bool:
	if not value is Dictionary or value.size() != V7_CPU_ROI_BUDGET.size(): return false
	# JSON numbers decode as floats. Compare exact numeric values, never Variant
	# byte encodings or a tolerance that could change the approved memory cap.
	for key: String in V7_CPU_ROI_BUDGET:
		if not value.has(key): return false
		var expected: Variant = V7_CPU_ROI_BUDGET[key]
		var actual: Variant = value[key]
		if expected is Array:
			if not actual is Array or actual.size() != expected.size(): return false
			for index in expected.size():
				if not (actual[index] is int or actual[index] is float) or actual[index] != expected[index]: return false
		elif expected is bool:
			if not actual is bool or actual != expected: return false
		elif not (actual is int or actual is float) or actual != expected: return false
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
		# These are generated outputs, not a phantom pre-existing input. Frozen
		# authoring/capture dependencies remain mandatory and catalog-bound.
		if dependency == V7_SOURCE_JSON or dependency.begins_with(V7_ROOT) or dependency.begins_with("res://build/") or dependency.begins_with(FULL_ROOT): continue
		if dependency.get_extension() not in ["gd", "gdshader", "gltf", "glb", "res", "obj", "tga", "png", "jpg", "json"]: continue
		if not _full_register_literal_inputs(dependency, visited): return false
	return true

func _pilot_read_roi(item: Dictionary, role: String, directory: String, pass_index: int, draw: Dictionary) -> Dictionary:
	var factor: int = SSAA if role in ["visual", "shadow_off"] else 1
	var rect: Rect2i = item["rect"]
	var logical_window: Rect2i = rect.grow(HALO).intersection(Rect2i(Vector2i.ZERO, SOURCE.SIZE))
	var native_window := Rect2i(logical_window.position * factor, logical_window.size * factor)
	if native_window.size.x * native_window.size.y > V7_MAX_CPU_ROI_PIXELS or native_window.size.x <= 0 or native_window.size.y <= 0:
		error = "Bounded CPU ROI cap exceeded."
		return {}
	pilot_transfer_view = SubViewport.new()
	pilot_transfer_view.size = native_window.size
	pilot_transfer_view.disable_3d = true
	pilot_transfer_view.msaa_2d = Viewport.MSAA_DISABLED
	pilot_transfer_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(pilot_transfer_view)
	var panel := ColorRect.new()
	panel.size = Vector2(native_window.size)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material := ShaderMaterial.new()
	material.shader = pilot_transport
	material.set_shader_parameter("primary_texture", active_view.get_texture())
	material.set_shader_parameter("source_origin_px", native_window.position)
	panel.material = material
	pilot_transfer_view.add_child(panel)
	var before: int = Engine.get_process_frames()
	pilot_transfer_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	await RenderingServer.frame_post_draw
	pilot_fence += 1
	pilot_transfer_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	# The only GPU get_image call in this sibling is this bounded target.
	var raw: Image = pilot_transfer_view.get_texture().get_image()
	if raw == null or raw.get_size() != native_window.size or raw.get_format() != Image.FORMAT_RGBA8 or raw.is_compressed() or raw.has_mipmaps() or Engine.get_process_frames() <= before or active_view.render_target_update_mode != SubViewport.UPDATE_DISABLED or active_view.get_texture().get_rid().get_id() != draw["texture_rid"]:
		error = "Integer transport actual native RGBA/identity/fence failure."
		return {}
	var prefix: String = directory + role + "_" + String(item["id"]) + "_pass" + str(pass_index)
	var raw_path: String = prefix + "_raw.png"
	if raw.save_png(raw_path) != OK:
		error = "Actual ROI raw PNG write failed."
		return {}
	var decoded: Image = Image.load_from_file(raw_path)
	if decoded == null or decoded.get_format() != Image.FORMAT_RGBA8 or decoded.get_data() != raw.get_data():
		error = "Raw PNG decoded bytes changed."
		return {}
	decoded = null
	var raw_binary: Dictionary = {}
	if factor == 1:
		raw_binary = _pilot_binary_stats(raw)
		if not bool(raw_binary["passed"]):
			pilot_result["failed_binary_raw_ROI_evidence"] = {"raw_path": raw_path, "raw_sha256": FileAccess.get_sha256(raw_path), "role": role, "window_id": item["id"], "pass_index": pass_index, "source_draw": draw, "actual_raw_binary_stats": raw_binary}
			error = "Actual raw binary ROI/halo must be pure RGB black/white AND alpha255."
			return {}
	if factor > 1 and not _v7_opaque_exact(raw):
		error = "Actual SSAA2 raw RGBA requires exact alpha255; no detect_alpha approximation."
		return {}
	var derived: Image = raw.duplicate() as Image
	if factor > 1: derived.resize(logical_window.size.x, logical_window.size.y, Image.INTERPOLATE_LANCZOS)
	var crop := Rect2i(rect.position - logical_window.position, rect.size)
	derived = derived.get_region(crop)
	if factor > 1 and not _v7_opaque_exact(derived):
		error = "Actual SSAA2 derived RGBA requires exact alpha255."
		return {}
	var path: String = prefix + ".png"
	if derived.save_png(path) != OK:
		error = "Logical bounded ROI write failed."
		return {}
	var record: Dictionary = {"path": path, "sha256": FileAccess.get_sha256(path), "raw_path": raw_path, "raw_sha256": FileAccess.get_sha256(raw_path), "raw_RGBA_sha256": _bytes_sha(raw.get_data()), "logical_RGBA_sha256": _bytes_sha(derived.get_data()), "logical_rect_px": _recti(rect), "global_native_readback_rect_px": _recti(native_window), "logical_overscan_rect_px": _recti(logical_window), "local_logical_crop_px": _recti(crop), "actual_readback_canvas": _v2i(raw.get_size()), "actual_whole_GPU_canvas": _v2i(active_view.size), "factor": factor, "resampling_identity": "OPAQUE_RGBA8_LANCZOS_ROI96_V1" if factor > 1 else "NONE_NATIVE_MSAA0", "96px_kernel_halo_actual_boundaries_clipped_to_whole": true, "source_draw": draw, "actual_transfer_post_draw_fence_sequence": pilot_fence, "transfer_shader": {"path": TRANSPORT_PATH, "sha256": TRANSPORT_SHA}, "gamma_correction": false, "source_primary_texture_rid": active_view.get_texture().get_rid().get_id(), "destination_texture_rid": pilot_transfer_view.get_texture().get_rid().get_id()}
	if factor == 1:
		var logical_binary: Dictionary = _pilot_binary_stats(derived)
		record["actual_raw_binary_stats"] = raw_binary
		record["actual_logical_binary_stats"] = logical_binary
		if not bool(logical_binary["passed"]):
			pilot_result["failed_binary_ROI_evidence"] = record
			error = "Actual binary capture must be pure RGB black/white AND alpha255; no transparent mask accepted."
			return {}
	raw = null
	derived = null
	panel.material = null
	material.set_shader_parameter("primary_texture", null)
	material = null
	panel = null
	var destination_ref: WeakRef = weakref(pilot_transfer_view)
	pilot_transfer_view.queue_free()
	pilot_transfer_view = null
	for i in 4: await process_frame
	record["actual_transfer_view_released"] = destination_ref.get_ref() == null
	if not bool(record["actual_transfer_view_released"]):
		error = "ROI transfer viewport release failed."
		return {}
	record["CPU_ROI_budget"] = V7_CPU_ROI_BUDGET.duplicate(true)
	return record


func _full_export_native_instances() -> bool:
	for site in source.vegetation_sites:
		var key: String=String(site["kind"])+str(site["pose"])
		if not native_prototype_cache.has(key):
			error="Missing actual native prototype for "+String(site["id"])
			return false
		var proto: Dictionary=native_prototype_cache[key]
		var id: String=site["id"]
		var path: String=v7_art_root+"entities/"+id+".png"
		var source_png: String=proto["record"]["texture"]
		var bytes: PackedByteArray=FileAccess.get_file_as_bytes(source_png)
		var out:=FileAccess.open(path,FileAccess.WRITE)
		if out==null:
			error="Cannot save independent entity "+id
			return false
		out.store_buffer(bytes)
		var io: Error=out.get_error()
		out.close()
		if io!=OK or FileAccess.get_file_as_bytes(path)!=bytes:
			error="Instance alpha bytes differ from actual pose prototype "+id
			return false
		full_catalog[path]=FileAccess.get_sha256(path)
		var foot: Vector2=source.project_source(site["source_foot"])
		var actual: Dictionary=site.duplicate(true)
		actual.erase("source_foot")
		var image: Image=proto["image"]
		var uv: Vector2=Vector2(proto["foot"])/Vector2(image.get_size())
		var center: Vector2=foot-(uv-Vector2(.5,.5))*Vector2(image.get_size())
		actual["texture"]=path
		actual["source_XZ_foot_px"]=[site["source_foot"].x,site["source_foot"].y]
		actual["actual_ground_m"]=source.triangle_height(site["source_foot"])
		var model_transform:=Transform3D(proto["basis"],SOURCE.point3(site["source_foot"],actual["actual_ground_m"])-Vector3(proto["support"]))
		actual["actual_model_transform"]=_pilot_transform(model_transform)
		actual["actual_model_transform_scope"]="original cached native sourcebody support/pose only; actual v7 shadow caster is separately bound by per-world caster records"
		actual["v7_caster_recipe"]="NEW actual measured-foot RGBA camera plane" if String(site["id"]).begins_with("v7_") and site["kind"] in ["tree","bamboo"] else "unchanged original native draw geometry"
		actual["ground_contact_method"]="actual used-index prototype support translated onto exact frozen Float32 native triangle; no negative-bed clamping"
		actual["sourcebody_capture_origin"]=proto["record"]["sourcebody_capture_origin"]
		actual["world_foot_px"]=[foot.x,foot.y]
		actual["pos"]=[center.x/SOURCE.SIZE.x,center.y/SOURCE.SIZE.y]
		actual["foot_uv"]=[uv.x,uv.y]
		actual["render_size_px"]=[image.get_width(),image.get_height()]
		actual["depth_sort_foot_y"]=foot.y/SOURCE.SIZE.y
		actual["sort_by_feet"]=true
		actual["blocking"]=bool(site["blocking"])
		actual["walkability_margin_px"]=[0.,0.]
		actual["prototype_actual_sourcebody_evidence"]=proto["record"]
		_full_register_paths(proto["record"])
		_full_register_paths(PLANTS.texture_evidence)
		_full_register_paths(PLANTS.geometry_evidence)
		actual["collision_size_px"]=[site["collision_size_px"].x,site["collision_size_px"].y]
		var physical_center: Vector2=foot
		if site["kind"]=="boulder":
			var bounds: Array=proto["record"]["used_vertex_bounds_m"]
			var support: Vector3=proto["support"]
			var source_foot: Vector2=site["source_foot"]
			var start: Vector2=source_foot+Vector2((bounds[0][0]-support.x)*SOURCE.PPM,(bounds[0][2]-support.z)*SOURCE.Z_PPM)
			var size:=Vector2((bounds[1][0]-bounds[0][0])*SOURCE.PPM,(bounds[1][2]-bounds[0][2])*SOURCE.Z_PPM)
			actual["source_fullxz_rect_px"]=[start.x,start.y,size.x,size.y]
			actual["collision_size_px"]=[size.x,size.y]
			actual["collision_center_world_px"]=[start.x+size.x*.5,start.y+size.y*.5-source.triangle_height(source_foot)*SOURCE.Z_PPM]
			physical_center=Vector2(actual["collision_center_world_px"][0],actual["collision_center_world_px"][1])
		else:
			actual["collision_center_world_px"]=[physical_center.x,physical_center.y]
		if actual["blocking"]:
			var physical_size:=Vector2(actual["collision_size_px"][0],actual["collision_size_px"][1])
			actual["collision_size"]=[physical_size.x/SOURCE.SIZE.x,physical_size.y/SOURCE.SIZE.y]
			actual["collision_offset"]=[(physical_center.x-center.x)/SOURCE.SIZE.x,(physical_center.y-center.y)/SOURCE.SIZE.y]
		if not _write_json(v7_art_root+"entities/"+id+".json",actual): return false
		full_catalog[v7_art_root+"entities/"+id+".json"]=FileAccess.get_sha256(v7_art_root+"entities/"+id+".json")
		full_objects.append(actual)
	return true

func _full_export_compounds(copy_assets: bool=true) -> bool:
	full_portals.clear()
	full_core_landmarks.clear()
	for landmark in SOURCE.LANDMARKS:
		var id: String=landmark["id"]
		var measured: Dictionary=source.semantics[id]
		var texture: String=v7_art_root+"entities/compound_"+id+".png"
		if copy_assets and not _full_copy_exact(landmark["source"],texture): return false
		var foot: Vector2=source.project_source(landmark["foot"])
		var uv:=Vector2(float(measured["source_doorstep_uv"][0]),float(measured["source_doorstep_uv"][1]))
		var size:=Vector2(float(measured["render_size_px"][0]),float(measured["render_size_px"][1]))
		var center: Vector2=foot-(uv-Vector2(.5,.5))*size
		var solids: Array=[]
		for polygon: Array in measured["solid_polygons_source_px"]: solids.append(_full_map_points(polygon,foot,measured))
		var object: Dictionary={"id":"compound_"+id,"role":"independent_generated_compound","texture":texture,"source":landmark["source"],"source_sha256":measured["source_sha256"],"source_size_px":measured["source_size_px"],"render_size_px":[size.x,size.y],"foot_uv":[uv.x,uv.y],"world_foot_px":[foot.x,foot.y],"pos":[center.x/SOURCE.SIZE.x,center.y/SOURCE.SIZE.y],"depth_sort_foot_y":foot.y/SOURCE.SIZE.y,"sort_by_feet":true,"centered":true,"blocking":true,"solid_polygons_px":solids,"legacy_baked_light":true,"source_provenance":"project-original generated source, NOT CC0; original alpha and pixels unchanged"}
		full_objects.append(object)
		var passage: Array=_full_map_points(measured["passage_path_source_px"],foot,measured)
		var portal: Dictionary={"id":id,"compound_id":object["id"],"target_scene":landmark["target"],"target_pos":[landmark["target_pos"].x,landmark["target_pos"].y],"pos":[foot.x/SOURCE.SIZE.x,foot.y/SOURCE.SIZE.y],"source":landmark["source"],"source_sha256":measured["source_sha256"],"source_doorstep_uv":measured["source_doorstep_uv"],"source_XZ_foot_px":[landmark["foot"].x,landmark["foot"].y],"door_foot_px":[foot.x,foot.y],"interaction_polygon_px":_full_map_points(measured["interaction_polygon_source_px"],foot,measured),"passage_polygon_px":_full_map_points(measured["passage_polygon_source_px"],foot,measured),"passage_path_px":passage,"approach_direction":[0,1],"auto_trigger":false,"doorstep_visual_review_status":"PENDING_ROOT_ACTUAL_CURRENT_CAPTURE","size":[96./SOURCE.SIZE.x,48./SOURCE.SIZE.y]}
		full_portals.append(portal)
		if id in SOURCE.CORE_IDS: full_core_landmarks.append({"id":id,"center_px":[center.x,center.y],"door_foot_px":[foot.x,foot.y]})
	if full_portals.size()!=16 or full_core_landmarks.size()!=9:
		error="Incomplete actual compound/doorway assembly."
		return false
	for i in range(full_core_landmarks.size()):
		for j in range(i+1,full_core_landmarks.size()):
			for role: String in ["center_px","door_foot_px"]:
				var a: Array=full_core_landmarks[i][role]
				var b: Array=full_core_landmarks[j][role]
				if Vector2(a[0],a[1]).distance_to(Vector2(b[0],b[1]))<SOURCE.MIN_CORE_SPACING:
					error="Actual nine-core center/door spacing failed."
					return false
	return true

func _full_export_structures() -> bool:
	var holder:=Node3D.new()
	root.add_child(holder)
	_add_bridge_geometry(holder,Rect2(Vector2.ZERO,Vector2(SOURCE.SIZE)))
	for bridge: Node3D in holder.get_children():
		var id: String=bridge.get_meta("structure_id")
		var foot: Vector2=bridge.get_meta("source_foot")
		var deck:=Node3D.new()
		bridge.add_child(deck)
		var part_index := 0
		var parts: Array[Node3D]=[]
		for child in bridge.get_children():
			if not child is MeshInstance3D: continue
			var role: String=child.get_meta("runtime_role","")
			if role in ["bridge_deck","bridge_underbeam"]:
				child.reparent(deck,false)
			else: parts.append(child)
		var deck_record: Dictionary=await _full_capture_part(deck,id+"_deck",foot,"bridge_deck",false)
		if deck_record.is_empty():
			holder.queue_free()
			return false
		full_objects.append(deck_record)
		for part: Node3D in parts:
			var part_foot: Vector2=part.get_meta("source_foot")
			var role: String=part.get_meta("runtime_role")
			var record: Dictionary=await _full_capture_part(part,id+"_"+role+str(part_index),part_foot,role,true)
			if record.is_empty():
				holder.queue_free()
				return false
			full_objects.append(record)
			part_index+=1
		bridge.queue_free()
	holder.queue_free()
	await _sync()
	return true

func _full_capture_part(original: Node3D,id: String,source_foot: Vector2,role: String,blocking: bool) -> Dictionary:
	var actual_vertices: PackedVector3Array=_full_part_vertices(original)
	if actual_vertices.is_empty():
		error="Empty actual bridge draw vertices "+id
		return {}
	var view:=SubViewport.new()
	view.own_world_3d=true
	view.transparent_bg=true
	view.msaa_3d=Viewport.MSAA_DISABLED
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var world:=Node3D.new()
	view.add_child(world)
	var env:=WorldEnvironment.new()
	env.environment=surface.environment()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(0,0,0,0)
	world.add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-34,0)
	sun.light_energy=.85
	world.add_child(sun)
	var object:=original.duplicate() as Node3D
	world.add_child(object)
	object.global_transform=original.global_transform
	var foot3: Vector3=SOURCE.point3(source_foot,0.)
	var camera:=Camera3D.new()
	world.add_child(camera)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.position=foot3+Vector3(0,20,20)
	camera.look_at(foot3)
	var low:=Vector2(INF,INF)
	var high:=Vector2(-INF,-INF)
	var min3:=Vector3(INF,INF,INF)
	var max3:=Vector3(-INF,-INF,-INF)
	for v in actual_vertices:
		min3=min3.min(v)
		max3=max3.max(v)
		var delta: Vector3=v-foot3
		var pixel:=Vector2(delta.dot(camera.basis.x),-delta.dot(camera.basis.y))*SOURCE.PPM
		low=low.min(pixel)
		high=high.max(pixel)
	# The real worldY0 foot is part of the canvas contract even for a rail
	# bolted above it. Do not let a tight high-face bbox put foot_uv outside.
	low=low.min(Vector2.ZERO)
	high=high.max(Vector2.ZERO)
	var canvas:=Vector2i(ceili(high.x-low.x)+32,ceili(high.y-low.y)+32)
	canvas.x=maxi(canvas.x,64)
	canvas.y=maxi(canvas.y,64)
	view.size=canvas*SSAA
	camera.size=float(canvas.y)/SOURCE.PPM
	var offset: Vector2=(low+high)*.5/SOURCE.PPM
	camera.position+=camera.basis.x*offset.x-camera.basis.y*offset.y
	camera.current=true
	await _sync()
	var raw: Image=view.get_texture().get_image()
	raw.convert(Image.FORMAT_RGBA8)
	await _sync()
	var repeat: Image=view.get_texture().get_image()
	repeat.convert(Image.FORMAT_RGBA8)
	var prefix: String=v7_art_root+"entities/"+id
	if raw.get_size()!=canvas*SSAA or raw.get_data()!=repeat.get_data() or raw.save_png(prefix+"_raw.png")!=OK or repeat.save_png(prefix+"_raw_repeat.png")!=OK:
		error="Actual bridge body/raw-repeat failed "+id
		view.queue_free()
		return {}
	var logical: Image=_alpha_resize(raw,canvas)
	var logical_repeat: Image=_alpha_resize(repeat,canvas)
	var used: Rect2i=logical.get_used_rect()
	if logical.get_data()!=logical_repeat.get_data() or used.size==Vector2i.ZERO or used.position.x<4 or used.position.y<4 or used.end.x>canvas.x-4 or used.end.y>canvas.y-4:
		error="Actual bridge alpha/canvas/repeat failed "+id
		view.queue_free()
		return {}
	if logical.save_png(prefix+".png")!=OK or logical_repeat.save_png(prefix+"_repeat.png")!=OK:
		error="Bridge logical alpha save failed "+id
		view.queue_free()
		return {}
	var image_foot: Vector2=camera.unproject_position(foot3)/SSAA
	var foot: Vector2=source_foot # physical deck is exactly worldY0, not negative RF bed
	var origin: Vector2=foot-image_foot
	var center: Vector2=origin+Vector2(canvas)*.5
	var source_polygons: Array=[]
	if blocking:
		var projected_xz:=PackedVector2Array()
		for v in actual_vertices: projected_xz.append(Vector2(v.x*SOURCE.PPM+SOURCE.SIZE.x*.5,v.z*SOURCE.Z_PPM+SOURCE.SIZE.y*.5))
		var hull: PackedVector2Array=Geometry2D.convex_hull(projected_xz)
		var polygon: Array=[]
		for p in hull: polygon.append([p.x,p.y])
		if polygon.size()<3:
			error="Degenerate actual structural fullXZ hull "+id
			view.queue_free()
			return {}
		source_polygons=[polygon]
	var record: Dictionary={"id":id,"role":role,"texture":prefix+".png","render_size_px":[canvas.x,canvas.y],"source_size_px":[canvas.x,canvas.y],"world_foot_px":[foot.x,foot.y],"foot_uv":[image_foot.x/canvas.x,image_foot.y/canvas.y],"pos":[center.x/SOURCE.SIZE.x,center.y/SOURCE.SIZE.y],"sort_by_feet":blocking,"z_index":0 if blocking else -2,"depth_sort_foot_y":foot.y/SOURCE.SIZE.y,"blocking":blocking,"walk_support":role=="bridge_deck","deck_height_m":0.,"sourcebody_raw":prefix+"_raw.png","sourcebody_repeat":prefix+"_raw_repeat.png","body_repeat_path":prefix+"_repeat.png","sourcebody_exact":true,"alpha_algorithm":"RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1","actual_used_world_bounds_m":[_v3(min3),_v3(max3)],"actual_camera":{"projection":camera.projection,"size":camera.size,"position":_v3(camera.position),"basis_columns":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"raw_canvas":[canvas.x*SSAA,canvas.y*SSAA],"logical_canvas":[canvas.x,canvas.y]},"provenance":"project-original native timber geometry; no CC0 claim; actual captured native material"}
	record["alpha_unpremultiply_epsilon"]=.00001
	record["algorithm_identity"]="RGBAF_PREMULTIPLIED_LANCZOS_UNPREMULTIPLY_V1"
	record["walkability_margin_px"]=[0.,0.]
	var geometry_arrays: Array=[]
	geometry_arrays.resize(Mesh.ARRAY_MAX)
	geometry_arrays[Mesh.ARRAY_VERTEX]=actual_vertices
	var actual_geometry:=ArrayMesh.new()
	actual_geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,geometry_arrays)
	var geometry_path: String=prefix+"_actual_world_draw_geometry.res"
	if ResourceSaver.save(actual_geometry,geometry_path)!=OK:
		error="Actual bridge draw geometry proof save failed "+id
		view.queue_free()
		return {}
	record["actual_draw_geometry_path"]=geometry_path
	record["actual_draw_geometry_sha256"]=FileAccess.get_sha256(geometry_path)
	record["actual_draw_geometry_vertex_space"]="global world metres; identity transform; actual drawn triangle vertices in source order"
	full_catalog[geometry_path]=record["actual_draw_geometry_sha256"]
	record["sourcebody_camera"]=record["actual_camera"].duplicate(true)
	if blocking: record["solid_polygons_px"]=source_polygons
	for path: String in [prefix+".png",prefix+"_repeat.png",prefix+"_raw.png",prefix+"_raw_repeat.png"]: full_catalog[path]=FileAccess.get_sha256(path)
	record["metadata_path"]=prefix+".json"
	if not _write_json(record["metadata_path"],record):
		view.queue_free()
		return {}
	full_catalog[record["metadata_path"]]=FileAccess.get_sha256(record["metadata_path"])
	view.queue_free()
	await _sync()
	return record


func _v7_material_bindings() -> Dictionary:
	var bindings: Dictionary = {}
	for entry: Dictionary in surface.evidence:
		for key: String in ["path", "source_path"]:
			bindings[entry[key]] = FileAccess.get_sha256(entry[key])
	return bindings

func _v7_vec2_list(points: Variant) -> Array:
	var result: Array = []
	for p: Vector2 in points: result.append([p.x, p.y])
	return result

func _v7_composite_roi(rect: Rect2i) -> Image:
	if rect.size.x <= 0 or rect.size.y <= 0 or rect.size.x * rect.size.y > V7_MAX_CPU_ROI_PIXELS:
		error = "CPU composite ROI exceeds bounded image budget."
		return null
	var image: Image = Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	var covered_area := 0
	for chunk: Dictionary in full_chunks:
		var tile_rect := Rect2i(int(chunk["col"]) * SOURCE.TILE.x, int(chunk["row"]) * SOURCE.TILE.y, SOURCE.TILE.x, SOURCE.TILE.y)
		var part: Rect2i = tile_rect.intersection(rect)
		if part.size.x <= 0 or part.size.y <= 0: continue
		var ground: Image = Image.load_from_file(chunk["visual_path"])
		if ground == null or ground.get_size() != SOURCE.TILE:
			error = "Missing actual whole-derived native ground in composite ROI."
			return null
		image.blit_rect(ground, Rect2i(part.position - tile_rect.position, part.size), part.position - rect.position)
		covered_area += part.size.x * part.size.y
	if covered_area != rect.size.x * rect.size.y:
		error = "Composite ROI has uncovered pixels."
		return null
	var ordered: Array[Dictionary] = full_objects.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var low_a: bool = int(a.get("z_index", 0)) < 0
		var low_b: bool = int(b.get("z_index", 0)) < 0
		if low_a != low_b: return low_a
		return float(a.get("depth_sort_foot_y", 0.)) < float(b.get("depth_sort_foot_y", 0.)))
	for object: Dictionary in ordered:
		var size := Vector2i(object["render_size_px"][0], object["render_size_px"][1])
		var center := Vector2(object["pos"][0] * SOURCE.SIZE.x, object["pos"][1] * SOURCE.SIZE.y)
		var bounds := Rect2i(Vector2i((center - Vector2(size) * .5).round()), size)
		if not bounds.intersects(rect): continue
		var body: Image = Image.load_from_file(object["texture"])
		if body == null:
			error = "Independent runtime body missing in composite."
			return null
		if body.get_size() != size: body = _alpha_resize(body, size)
		image.blend_rect(body, Rect2i(Vector2i.ZERO, size), bounds.position - rect.position)
	return image

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
	if overview.save_png(V7_ROOT + "overview.png") != OK:
		error = "Bounded overview save failed."
		return false
	_full_register_paths(V7_ROOT + "overview.png")
	for portal: Dictionary in full_portals:
		var foot := Vector2(portal["door_foot_px"][0], portal["door_foot_px"][1])
		var rect := Rect2i(Vector2i((foot - Vector2(380, 400)).round()), Vector2i(760, 500)).intersection(Rect2i(Vector2i.ZERO, SOURCE.SIZE))
		var scene: Image = _v7_composite_roi(rect)
		if scene == null: return false
		var path: String = V7_ROOT + "capture/doorstep_" + String(portal["id"]) + "_review.png"
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
		var path: String = V7_ROOT + "ecology/" + String(habitat["id"]) + "_scene_components.png"
		if scene.save_png(path) != OK: return false
		_full_register_paths(path)
		var authorities: Array = []
		for chunk: Dictionary in full_chunks:
			if rect.intersects(Rect2i(chunk["logical_rect_px"][0], chunk["logical_rect_px"][1], SOURCE.TILE.x, SOURCE.TILE.y)):
				authorities.append({"id": chunk["id"], "visual_path": chunk["visual_path"], "visual_sha256": FileAccess.get_sha256(chunk["visual_path"]), "capture_window_id": chunk["id"], "capture_role": "primary"})
		var evidence: Dictionary = {"scene_components_path": path, "scene_components_sha256": FileAccess.get_sha256(path), "logical_rect_px": _recti(rect), "scope": "BOUNDED_CPU_COMPOSITE_ACTUAL_WHOLE_CHUNK_GROUND_AND_INDEPENDENT_Y_BODIES_NOT_EXTRA_GPU_CAPTURE", "actual_whole_ground_authorities": authorities, "whole_report_path": V7_REPORT, "no_additional_GPU_window_claim": true}
		if not _write_json(V7_ROOT + "ecology/" + String(habitat["id"]) + ".json", evidence): return false
		_full_register_paths(V7_ROOT + "ecology/" + String(habitat["id"]) + ".json")
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
		var path: String = V7_ROOT + "entities/chunks/" + String(chunk["id"]) + ".json"
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
		ecology.append({"id":habitat["id"],"source_XZ_px":[source_point.x,source_point.y],"projected_px":[point.x,point.y],"profile":profiles[index],"actual_rf_height_m":source.triangle_height(source_point),"native_selector":{"gradient":selector["gradient"],"min_height":selector["min_height"],"min_bank":selector["min_bank"],"walk":selector["walk"]},"walkable":all17,"material_binding":_v7_material_bindings(),"review_evidence_path":V7_ROOT+"ecology/"+String(habitat["id"])+".json","review_scope":"BOUNDED_CPU_COMPOSITE_OF_ACTUAL_GLOBAL_CHUNK_CAPTURES_AND_INDEPENDENT_BODIES","scene_components_path":V7_ROOT+"ecology/"+String(habitat["id"])+"_scene_components.png","visual_approved":false})
	var camera_path: String=V7_ROOT+"capture/camera_contract.json"
	if not _write_json(camera_path, {"capture_protocol": V7_PROTOCOL, "whole_capture": true, "local_camera_authority": false, "projection": "orthographic", "logical_pixels_per_meter_x": SOURCE.PPM, "logical_pixels_per_meter_source_z": SOURCE.Z_PPM, "source_world_size_px": _v2i(SOURCE.SIZE), "visual_ssaa_scale": SSAA, "ROI96_halo": HALO, "binary_msaa_enum": 0, "binary_resized": false, "actual_world_cameras": {"primary": pilot_result["worlds"]["primary"]["camera"], "reference": pilot_result["worlds"]["reference"]["camera"]}, "actual_whole_world_receiver_coverage": {"primary": pilot_result["worlds"]["primary"]["coverage"], "reference": pilot_result["worlds"]["reference"]["coverage"]}, "authoring_source": {"path": source.get_script().resource_path, "sha256": FileAccess.get_sha256(source.get_script().resource_path)}, "executed_capture_builder": {"path": get_script().resource_path, "sha256": FileAccess.get_sha256(get_script().resource_path)}, "whole_report_path": V7_REPORT, "whole_CPU_Image_allowed": false, "maximum_CPU_ROI_pixels": V7_MAX_CPU_ROI_PIXELS, "CPU_ROI_budget": V7_CPU_ROI_BUDGET}): return false
	full_catalog[camera_path]=FileAccess.get_sha256(camera_path)
	full_graph[camera_path]=full_catalog[camera_path]
	var semantics_path: String=V7_ROOT+"landmark_semantics.json"
	if not _write_json(semantics_path,{"schema_version":15,"status":"MEASURED_ACTUAL_SOURCE_NOT_FIELD_APPROVED","landmarks":source.semantics,"source_authoring_path":FULL_FOOTPRINTS,"source_authoring_sha256":FileAccess.get_sha256(FULL_FOOTPRINTS)}): return false
	full_catalog[semantics_path]=FileAccess.get_sha256(semantics_path)
	full_graph[semantics_path]=full_catalog[semantics_path]
	full_catalog[FULL_FOOTPRINTS]=FileAccess.get_sha256(FULL_FOOTPRINTS)
	full_graph[FULL_FOOTPRINTS]=full_catalog[FULL_FOOTPRINTS]
	if not _full_overview_and_door_reviews(): return false
	var source_contract: Dictionary={"schema_version":15,"version":"world_v15","status":"ART_ASSETS_READY","authoring_revision":"complete_v5_geography_v4","world_size":[SOURCE.SIZE.x,SOURCE.SIZE.y],"tile_size":[SOURCE.TILE.x,SOURCE.TILE.y],"overview_path":V7_ROOT+"overview.png","chunks":full_chunks,"seams":full_seams,"objects":full_objects,"portals":full_portals,"core_landmarks":full_core_landmarks,"routes":routes,"structures":supports,"ecology_probes":ecology,"geometry":{"grid_size":[SOURCE.GRID_SIZE.x,SOURCE.GRID_SIZE.y],"grid_step_px":SOURCE.GRID_STEP,"height_rf_path":full_geometry["rf_path"],"height_rf_sha256":full_geometry["rf_sha256"],"terrain_mesh_path":full_geometry["terrain_mesh_path"],"terrain_mesh_sha256":full_geometry["terrain_mesh_sha256"]},"pixel_sampling":"round_world_pixel","physical_navigation_margin_px":0,"visual_approved":false,"production_approved":false}
	source_contract["coordinate_version"] = 15
	source_contract["art_revision"] = "complete_v7_coherent_whole"
	source_contract["v7_revision_evidence"] = {"ecology":(source as V7_ECOLOGY).v7_proposal_contract(),"actual_alpha_union":v7_alpha_union,"actual_materials":v7_material_records,"actual_plane_casters":v7_plane_records,"bianzhou_projected_world_approach":_v7_pairs(v7_approach_world),"inverse_RF_records":v7_approach_inverse,"regional_approval":pilot_auth.get("regional_visual_review",{}),"scope":"NEW v7 exact same coordinate15 geometry; source-only revision becomes candidate only after actual FULL and Field"}
	source_contract["capture"] = {"capture_protocol": V7_PROTOCOL, "whole_capture": true, "local_camera_authority": false, "authoring_source": {"path": source.get_script().resource_path, "sha256": FileAccess.get_sha256(source.get_script().resource_path)}, "executed_builder": {"path": get_script().resource_path, "sha256": FileAccess.get_sha256(get_script().resource_path)}, "capture_report": {"path": V7_REPORT, "sha256": FileAccess.get_sha256(V7_REPORT)}, "authoritative_nav_msaa": 0, "authoritative_nav_resize": false, "CPU_ROI_budget": V7_CPU_ROI_BUDGET, "whole_CPU_Image_allowed": false}
	source_contract["geometry"]["geometry_contract_path"] = v7_art_root + "geometry.json"
	source_contract["geometry"]["geometry_contract_sha256"] = FileAccess.get_sha256(v7_art_root + "geometry.json")
	source_contract["geometry"]["height_grid_shape"] = _v2i(SOURCE.GRID_SIZE)
	source_contract["geometry"]["height_grid_origin_px"] = [0, 0]
	source_contract["geometry"]["source_node_spacing_px"] = SOURCE.GRID_STEP
	source_contract["source_graph"] = full_graph.duplicate(true)
	source_contract["asset_sha256"] = full_catalog.duplicate(true) # Excludes this document itself; manifest binds its final SHA.
	var contract_path: String = V7_SOURCE_JSON
	if not _write_json(contract_path,source_contract): return false
	full_catalog[contract_path]=FileAccess.get_sha256(contract_path)
	full_graph[contract_path]=full_catalog[contract_path]
	if not _full_copy_exact(contract_path, V7_ROOT + "source_contract.json"): return false
	var roles: Dictionary={"authoring_source_script":source.get_script().resource_path,"source_assembly_script":get_script().resource_path,"transport_shader":TRANSPORT_PATH,"transport_proof":pilot_auth["transport_proof"]["path"],"terrain_mesh":CACHE_ROOT+"terrain_mesh.res","source_topology":CACHE_ROOT+"source_topology.png","deck_support_mesh":CACHE_ROOT+"chunks/r0_c0_actual_deck_support_mesh.res","whole_capture_report":V7_REPORT,"geometry_contract":V7_ROOT+"geometry.json","source_contract":V7_SOURCE_JSON,"source_script":source.get_script().resource_path,"builder_script":get_script().resource_path,"surface_script":surface.get_script().resource_path,"selector_script":source.get_script().resource_path,"terrain_shader":pilot_result["actual_terrain_shader"]["path"],"height_rf":CACHE_ROOT+"terrain_height.rf","landmark_semantics":semantics_path,"camera_contract":camera_path}
	var capture_graph: Dictionary={}
	for role: String in roles:
		capture_graph[role]={"path":roles[role],"sha256":FileAccess.get_sha256(roles[role])}
	if not _write_json(V7_ROOT+"art_contract.json",{"version":"world_v15","coordinate_version":15,"art_revision":"complete_v7_coherent_whole","capture_protocol":V7_PROTOCOL,"status":"ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA","source_contract_path":V7_SOURCE_JSON,"whole_actual_capture":{"path":V7_REPORT,"sha256":FileAccess.get_sha256(V7_REPORT)},"source_graph":full_graph,"capture_graph":capture_graph,"asset_sha256":full_catalog,"chunks":full_chunks,"seams":full_seams,"outside_sourcebody_shadow_pixels":full_shadow_pixels,"native_object_count":source.vegetation_sites.size(),"structure_count":supports.size(),"portal_count":16,"core_count":9,"visual_approved":false,"production_approved":false,"door_review_requires_root":true}): return false
	return true



func _load_pilot_inputs() -> bool:
	source = V7_ECOLOGY.new()
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(CACHE_ROOT + "terrain_height.rf")
	if bytes.size() != SOURCE.GRID_SIZE.x * SOURCE.GRID_SIZE.y * 4:
		error = "Actual cached RF byte count mismatch."
		return false
	source.heights = bytes.to_float32_array()
	source.prepare()
	if not (source as V7_ECOLOGY).v7_proposal_error.is_empty():
		error = (source as V7_ECOLOGY).v7_proposal_error
		return false
	if not _v7_replace_bianzhou_approach(): return false
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
	surface = V7_SURFACE.new()
	if not surface.load_sources():
		error = surface.error
		return false
	for entry: Dictionary in surface.evidence:
		for key: String in ["path", "source_path"]:
			var p: String = entry[key]
			if not pilot_inputs.has(p):
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
		error = "NEW actual v7 material absent."
		return false
	pilot_shader = actual_material.shader
	var shader_path: String = pilot_output + "v7_actual_terrain_shader.gdshader"
	if ResourceSaver.save(pilot_shader, shader_path) != OK:
		error = "Cannot save NEW actual v7 shader."
		return false
	full_catalog[shader_path] = FileAccess.get_sha256(shader_path)
	full_graph[shader_path] = full_catalog[shader_path]
	pilot_result["actual_terrain_shader"] = {"path":shader_path,"sha256":full_catalog[shader_path],"source_script":surface.get_script().resource_path,"source_script_sha256":FileAccess.get_sha256(surface.get_script().resource_path)}
	v7_material_records = (surface as V7_SURFACE).v7_material_records.duplicate(true)
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



func _v7_source_guard() -> bool:
	for path: String in V7_SOURCE_PINS:
		if FileAccess.get_sha256(path).to_lower() != String(V7_SOURCE_PINS[path]):
			error = "NEW v7 current dependency/proof differs: " + path
			return false
	var proof: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://build/world_v15_native_binary_stats_unit/1791073994_1612124/result.json"))
	if not proof is Dictionary or proof.get("case_count") != 108 or proof.get("checks") != 540 or not proof.get("failed") is Array or not proof["failed"].is_empty() or proof.get("status") != "UNIT_EQUIVALENCE_PASS":
		error = "ROOT111 exact combined-predicate proof unavailable; no optimization assumption."
		return false
	return true

func _v7_regional_approval_error() -> String:
	var review: Variant = pilot_auth.get("regional_visual_review")
	if not review is Dictionary or review.get("approved_by") != "root" or review.get("approved") != true or review.get("scope") != V7_REGIONAL_SCOPE:
		error = "NEW FULL requires separate root current regional visual review; source-only proposal refuses."
		return error
	var path: String = review.get("result_path","")
	if not path.begins_with("res://build/world_map_v15_coherent_whole_v7_regional/") or FileAccess.get_sha256(path).to_lower() != String(review.get("result_sha256","")).to_lower():
		error = "NEW regional actual result SHA/path not bound."
		return error
	var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not result is Dictionary or result.get("scope") != V7_REGIONAL_SCOPE or result.get("status") != "REGIONAL_TECHNICAL_PASS_NOT_FULL_OR_FIELD" or not bool(result.get("input_hashes_unchanged_after",false)) or not bool(result.get("alpha_union",{}).get("passed",false)):
		error = "Regional actual mechanism/coverage proof incomplete."
		return error
	var regional_builder: String = "res://scripts/dev/build_world_map_v15_coherent_whole_v7_regional_proposal.gd"
	if result.get("executed_builder",{}).get("path") != regional_builder or result.get("executed_builder",{}).get("sha256") != FileAccess.get_sha256(regional_builder) or result.get("cached_inputs_sha256",{}).get("res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd") != FileAccess.get_sha256("res://scripts/dev/build_world_map_v15_coherent_whole_v7_full_proposal.gd"):
		error = "Regional actual executor/parent source proof belongs to another revision."
		return error
	for dependency: String in V7_SOURCE_PINS:
		if not dependency.begins_with("res://scripts/dev/world_map_v15_complete_v7_"): continue
		if result.get("cached_inputs_sha256",{}).get(dependency) != FileAccess.get_sha256(dependency):
			error = "Regional source/body/shader proof belongs to another revision."
			return error
	return ""

func _material_maps(rect: Rect2) -> Dictionary:
	var maps: Dictionary = (source as V7_ECOLOGY).visual_material_maps(rect)
	if maps.get("step_px") != 4 or not maps.get("biome") is Image or not maps.get("roads") is Image:
		error = "NEW v7 exact 4px ownership maps absent."
		return {}
	var biome: Image = maps["biome"]
	var road: Image = maps["roads"]
	if biome.has_mipmaps() or road.has_mipmaps() or biome.get_size() != Vector2i(ceili(rect.size.x/4.),ceili(rect.size.y/4.)) or road.get_size() != biome.get_size():
		error = "NEW v7 map canvas/mip mismatch."
		return {}
	return {"ecology":ImageTexture.create_from_image(biome),"roads":ImageTexture.create_from_image(road)}

func _v7_inverse_world_point(world: Vector2) -> Vector2:
	# The WORLD projected proposal is NOT inserted as SOURCE XZ coordinates.
	for bridge: Dictionary in source.structures:
		if Geometry2D.is_point_in_polygon(world,bridge["source_deck_polygon"]): return world
	var low: float = maxf(0.,world.y-512.)
	var high: float = minf(float(SOURCE.SIZE.y),world.y+512.)
	if source.project_source(Vector2(world.x,low)).y > world.y or source.project_source(Vector2(world.x,high)).y < world.y: return Vector2(INF,INF)
	for iteration in 32:
		var middle: float = (low+high)*.5
		if source.project_source(Vector2(world.x,middle)).y < world.y: low=middle
		else: high=middle
	var result:=Vector2(world.x,(low+high)*.5)
	# Numerical inversion residual, not a navigation/shoe acceptance tolerance.
	if source.project_source(result).distance_to(world) > .001: return Vector2(INF,INF)
	return result

func _v7_replace_bianzhou_approach() -> bool:
	var old_door:=source.project_source(Vector2(7600,2200))
	v7_approach_world=PackedVector2Array([Vector2(7600,2340),Vector2(7840,2295),Vector2(7840,2230),Vector2(7600,2230),old_door])
	var inverted:=PackedVector2Array()
	v7_approach_inverse.clear()
	for segment in range(v7_approach_world.size()-1):
		var a: Vector2=v7_approach_world[segment]
		var b: Vector2=v7_approach_world[segment+1]
		var steps: int=maxi(1,ceili(a.distance_to(b)/4.))
		for n in range(steps+1):
			if segment>0 and n==0: continue
			var world: Vector2=a.lerp(b,float(n)/steps)
			var actual: Vector2=_v7_inverse_world_point(world)
			if not is_finite(actual.x) or not is_finite(actual.y):
				error="Projected-world Bianzhou inverse RF failed; no fake XZ fallback."
				return false
			inverted.append(actual)
			v7_approach_inverse.append({"world_px":[world.x,world.y],"source_XZ_px":[actual.x,actual.y],"projected_RF_px":[source.project_source(actual).x,source.project_source(actual).y],"bridge_deck_Y0":source.supported_height(actual)==0.})
	var replacements:=0
	for route: Dictionary in source.routes:
		if route["id"]!="portal_bianzhou": continue
		route["points"]=inverted
		route["revision_origin"]="NEW independent WORLD projected east bridge-end approach inverted through actual frozen RF; old door/bridge solids unchanged"
		replacements+=1
	if replacements!=1 or source.routes.size()!=27:
		error="Expected unique Bianzhou route within unchanged27 route IDs."
		return false
	source._index_segments(source.routes,source.road_buckets,160.)
	return true

func _v7_pairs(points: PackedVector2Array) -> Array:
	var result: Array=[]
	for point: Vector2 in points: result.append([point.x,point.y])
	return result

func _v7_add_casters(directory: String) -> bool:
	v7_plane_records.clear()
	for site: Dictionary in source.vegetation_sites:
		if v7_regional and not Rect2(v7_region_rect).grow(1024.).has_point(site["source_foot"]): continue
		var key: String=String(site["kind"])+str(site["pose"])
		if not native_prototype_cache.has(key):
			error="Missing actual body/pose for v7 caster "+key
			return false
		var proto: Dictionary=native_prototype_cache[key]
		var foot: Vector2=site["source_foot"]
		var ground: Vector3=SOURCE.point3(foot,source.triangle_height(foot))
		var node: MeshInstance3D
		var record: Dictionary
		if String(site["id"]).begins_with("v7_") and site["kind"] in ["tree","bamboo"]:
			var png: String=proto["record"]["texture"]
			var png_sha: String=FileAccess.get_sha256(png)
			if not v7_plane_prototypes.has(key):
				var helper:=V7_CASTER.new()
				var measured: MeshInstance3D=helper.create_caster({"texture":png,"texture_sha256":png_sha,"foot_uv":proto["record"]["foot_uv"],"render_size_px":proto["record"]["render_size_px"]},Vector3.ZERO)
				if measured==null:
					error=helper.error
					return false
				v7_plane_prototypes[key]={"mesh":measured.mesh,"evidence":helper.evidence.duplicate(true),"source_sha256":png_sha}
				measured.free()
			var cached: Dictionary=v7_plane_prototypes[key]
			if cached["source_sha256"]!=png_sha:
				error="Actual plane prototype PNG changed during capture."
				return false
			node=MeshInstance3D.new()
			node.mesh=cached["mesh"]
			node.position=ground
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			record=cached["evidence"].duplicate(true)
			record["world_foot_m"]=_v3(ground)
			record["actual_cast_shadow_enum"]=node.cast_shadow
			record["actual_mesh_instance_id"]=node.mesh.get_instance_id()
			record["actual_sourcebody_material_reuse"]="same verified kind/pose PNG+mesh+material; own independent RF-foot instance; no per-stem GPUtexture duplication"
			var mesh_path: String=directory+"actual_plane_prototype_"+key+".res"
			if not FileAccess.file_exists(mesh_path) and ResourceSaver.save(node.mesh,mesh_path)!=OK:
				node.free()
				error="Could not preserve actual new camera-plane draw resource."
				return false
			record["actual_draw_mesh_path"]=mesh_path
			record["actual_draw_mesh_sha256"]=FileAccess.get_sha256(mesh_path)
			record["caster_recipe"]="NEW actual RGBA camera plane; NOT original GLTF/native support mesh"
			v7_plane_records.append(record.duplicate(true))
		else:
			node=MeshInstance3D.new()
			node.mesh=proto["mesh"]
			node.transform=Transform3D(proto["basis"],ground-Vector3(proto["support"]))
			node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			node.set_meta("pilot_prototype_key",key)
			var original: Dictionary=proto["record"].get("sourcebody_capture_origin",{})
			record={"actual_draw_mesh_path":original.get("actual_GPU_loaded_mesh_path",proto["record"]["actual_draw_mesh_path"]),"actual_draw_mesh_sha256":original.get("actual_GPU_loaded_mesh_sha256",proto["record"]["actual_draw_mesh_sha256"]),"support_m":_v3(proto["support"]),"caster_recipe":"original unchanged native used-index model/pose; herb and boulder are never camera planes"}
		pilot_world.add_child(node)
		pilot_casters.append(node)
		record.merge({"id":site["id"],"kind":site["kind"],"pose":site["pose"],"source_foot_px":[foot.x,foot.y],"transform":_pilot_transform(node.global_transform),"shadow_on_enum":node.cast_shadow,"sourcebody_baked":false},true)
		pilot_caster_records.append(record)
	return true

func _v7_measure_coverage() -> bool:
	v7_alpha_union=(source as V7_ECOLOGY).measure_v7_alpha_union(full_objects)
	pilot_result["alpha_union"]=v7_alpha_union
	if not bool(v7_alpha_union.get("passed",false)):
		error="Actual original-size sourcebody alpha union failed a required four-region >8% threshold."
		return false
	return true

func _pilot_binary_stats(image: Image) -> Dictionary:
	var invalid: Dictionary={"passed":false,"reason":"actual RGBA8/uncompressed/no-mip/byte-length or native endianness mismatch","thresholding_or_alpha_correction":false}
	if image==null or image.is_empty() or image.get_format()!=Image.FORMAT_RGBA8 or image.is_compressed() or image.has_mipmaps(): return invalid
	var bytes: PackedByteArray=image.get_data()
	var count: int=image.get_width()*image.get_height()
	if bytes.size()!=count*4 or PackedByteArray([0,0,0,255]).to_int32_array()[0]!=-16777216: return invalid
	var words: PackedInt32Array=bytes.to_int32_array()
	if words.size()!=count: return invalid
	var black: int=words.count(-16777216)
	var white: int=words.count(-1)
	var result: Dictionary={"passed":black+white==count,"canvas":_v2i(image.get_size()),"actual_nonbinary_RGB_pixels":0,"actual_nonopaque_alpha_pixels":0,"required_alpha_byte":255,"pixels_checked":count,"opaque_black_word_count":black,"opaque_white_word_count":white,"algorithm_identity":"RGBA8_COMBINED_OPAQUE_BINARY_NATIVE_SIGNED_WORD_COUNTS_V2","detect_alpha_used":false,"thresholding_or_alpha_correction":false,"ROOT111_proof_sha256":V7_SOURCE_PINS["res://build/world_v15_native_binary_stats_unit/1791073994_1612124/result.json"]}
	if bool(result["passed"]): return result
	# Failure preserves complete original RGB/alpha counts, not a fast sampled diagnosis.
	for n in range(0,bytes.size(),4):
		if not ((bytes[n]==0 and bytes[n+1]==0 and bytes[n+2]==0) or (bytes[n]==255 and bytes[n+1]==255 and bytes[n+2]==255)): result["actual_nonbinary_RGB_pixels"]+=1
		if bytes[n+3]!=255: result["actual_nonopaque_alpha_pixels"]+=1
	return result

func _v7_opaque_exact(image: Image) -> bool:
	if image==null or image.get_format()!=Image.FORMAT_RGBA8 or image.is_compressed() or image.has_mipmaps(): return false
	var bytes: PackedByteArray=image.get_data()
	if bytes.size()!=image.get_width()*image.get_height()*4: return false
	# detect_alpha is deliberately forbidden: ROOT107 proved alpha254 is opaque there.
	for n in range(3,bytes.size(),4):
		if bytes[n]!=255: return false
	return true

func _pilot_difference(a: Image,b: Image) -> Dictionary:
	if a==null or b==null or a.get_size()!=b.get_size() or a.get_format()!=Image.FORMAT_RGBA8 or b.get_format()!=Image.FORMAT_RGBA8 or a.is_compressed() or b.is_compressed() or a.has_mipmaps() or b.has_mipmaps(): return {"byte_exact":false,"reason":"actual native image shape/format mismatch"}
	var x: PackedByteArray=a.get_data()
	var y: PackedByteArray=b.get_data()
	if x.size()!=a.get_width()*a.get_height()*4 or y.size()!=x.size(): return {"byte_exact":false,"reason":"RGBA byte length mismatch"}
	var result: Dictionary={"byte_exact":x==y,"different_bytes":0,"maximum_delta":0,"tolerance":0,"canvas":_v2i(a.get_size()),"a_RGBA_sha256":_bytes_sha(x),"b_RGBA_sha256":_bytes_sha(y)}
	if bool(result["byte_exact"]): return result
	for i in x.size():
		if x[i]==y[i]: continue
		if int(result["different_bytes"])==0: result["first_difference"]={"byte_index":i,"pixel":[int(i/4)%a.get_width(),int(i/4)/a.get_width()],"channel":i%4,"a":x[i],"b":y[i]}
		result["different_bytes"]=int(result["different_bytes"])+1
		result["maximum_delta"]=maxi(int(result["maximum_delta"]),absi(int(x[i])-int(y[i])))
	return result
