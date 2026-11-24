extends "res://scripts/dev/build_luoyang_modular_v3.gd"

## Explicit new geometry revision, never a material-only claim. Original layouts,
## collision polygons, foot support, paving and ordinary navigation are inherited.
## Root owns execution and archival of the previous candidate before capture.
const ROOF_BASE_PATH := "res://scripts/dev/build_luoyang_modular_v3.gd"
const ROOF_BASE_SHA := "3a7fa038d977c3671eeeda1dabaf8cd6c5e20807964b89eaee09ae0091950a30"
const ROOF_TRIAL_PATH := "res://scripts/dev/preview_luoyang_v3_wall_tile_cap.gd"
const ROOF_TRIAL_SHA := "88c8f173d97ad8bfb58aff8ede95ab1b4b045840693989fac939a542b594c387"
const ROOF_TRIAL_CAPTURE := "res://build/luoyang_wall_tile_cap_trial/1791066582_2036567/"
const ROOF_SOURCE_PATH := "res://scripts/dev/luoyang_modular_v3_source.gd"
const ROOF_SOURCE_SHA := "3a6f96cd823eb5e3f6d3b4fb1801d5e90342ed020ab293d3a578ccac048dbad5"
const ROOF_SURFACE_PATH := "res://scripts/dev/luoyang_modular_v3_surface.gd"
const ROOF_SURFACE_SHA := "76c65fa55f3e133829b3aab5b835ff7bf1d82bafb5ff99e54019df5458ee4f52"

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if "--luoyang-v3-roof-capture" not in args or "--luoyang-modular-v3-capture" not in args or "--luoyang-v3-source-plan" in args or DisplayServer.get_name() == "headless":
		error = "Roof geometry revision requires both explicit GPU capture flags; default, plan-only and headless refuse."
		await _roof_refuse()
		return
	var pins: Dictionary = {ROOF_BASE_PATH: ROOF_BASE_SHA, ROOF_TRIAL_PATH: ROOF_TRIAL_SHA, ROOF_SOURCE_PATH: ROOF_SOURCE_SHA, ROOF_SURFACE_PATH: ROOF_SURFACE_SHA}
	for path: String in pins:
		if FileAccess.get_sha256(path).to_lower() != String(pins[path]):
			error = "Frozen roof revision dependency changed: " + path
			await _roof_refuse()
			return
	await super._run()

func _roof_refuse() -> void:
	# The parent's failure handler invalidates a candidate contract. Before any
	# authorized capture starts, refuse WITHOUT writing that existing ART file.
	push_error(error)
	for shape in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
	var cursor: Node = root.get_node_or_null("CursorManager")
	if cursor != null:
		for key in ["_arrow", "_hand", "_wait"]: cursor.set(key, null)
	for tick in 16: await process_frame
	quit(2)

func _source_graph() -> Dictionary:
	var graph: Dictionary = super._source_graph()
	graph[ROOF_BASE_PATH] = FileAccess.get_sha256(ROOF_BASE_PATH)
	graph[ROOF_TRIAL_PATH] = FileAccess.get_sha256(ROOF_TRIAL_PATH)
	return graph

func _prototype(kind: String) -> bool:
	if kind not in ["wall_horizontal", "wall_vertical"]:
		return await super._prototype(kind)
	# Check the real original and prepared arrays BEFORE super performs capture;
	# then independently check the actual mesh retained by that capture.
	var original: ArrayMesh = super._prop_mesh(kind)
	var prepared: ArrayMesh = _prop_mesh(kind)
	if original == null or prepared == null:
		error = "Roof original/prepared actual mesh unavailable."
		return false
	var original_bounds: Dictionary = _bounds(original, Basis.IDENTITY)
	var prepared_bounds: Dictionary = _bounds(prepared, Basis.IDENTITY)
	if original_bounds.is_empty() or prepared_bounds.is_empty(): return false
	var before: Dictionary = _roof_original_comparison(original, prepared)
	if not bool(before["passed"]):
		error = "Raised roof changed original surfaces or ground support before capture."
		return false
	if not await super._prototype(kind): return false
	var actual: ArrayMesh = prototypes[kind]["mesh"]
	var actual_bounds: Dictionary = _bounds(actual, Basis.IDENTITY)
	if actual_bounds.is_empty(): return false
	var after: Dictionary = _roof_original_comparison(original, actual)
	var prepared_exact: bool = _roof_arrays_byte_exact(prepared, actual)
	var bounds_exact: bool = var_to_bytes(prepared_bounds) == var_to_bytes(actual_bounds)
	if not bool(after["passed"]) or not prepared_exact or not bounds_exact:
		error = "Actual captured roof is not the checked geometry/support."
		return false
	var record: Dictionary = prototypes[kind]["record"]
	record["source"] = "Project-authored native original masonry plus one raised tile surface copied exactly from bound ROOT097 trial; NOT CC0 modeled wall and NOT material-only."
	record["geometry_change_scope"] = "NEW raised tile overhang geometry: original surface arrays/primitive byte-exact and actual ground support unchanged. New complete bounds/canvas/alpha are measured by the actual revised capture, not inherited old body bounds."
	record["roof_geometry_revision"] = {
		"algorithm_identity": "ROOT097_CLOCKWISE_RAISED_TILE_CAP_V1",
		"new_geometry_not_material_only": true,
		"base_builder": {"path": ROOF_BASE_PATH, "sha256": FileAccess.get_sha256(ROOF_BASE_PATH)},
		"trial_builder": {"path": ROOF_TRIAL_PATH, "sha256": FileAccess.get_sha256(ROOF_TRIAL_PATH)},
		"historical_trial_capture_path": ROOF_TRIAL_CAPTURE,
		"historical_trial_scope": "ROOT097 actual four prototypes; permits candidate capture, not formal Field/visual approval",
		"original_surface_count": original.get_surface_count(),
		"actual_surface_count": actual.get_surface_count(),
		"new_surface_count": 1,
		"pre_capture_original_comparison": before,
		"captured_original_comparison": after,
		"prepared_and_captured_all_arrays_byte_exact": prepared_exact,
		"prepared_and_captured_actual_bounds_byte_exact": bounds_exact,
		"actual_new_surface": _roof_cap_evidence(actual, original.get_surface_count()),
		"raised_y_range_m": [1.73, 1.98],
		"cross_span_m": 1.15 if kind == "wall_horizontal" else 1.30,
		"ground_solids_recipe": "unchanged SOURCE polygons; raised overhang is not a widened foot collision or walk support",
		"production_approved": false
	}
	# Parent catalog subsequently hashes this corrected real prototype metadata.
	if not _json(String(record["metadata_path"]), record): return false
	prototypes[kind]["record"] = record
	return true

func _roof_arrays_byte_exact(a: ArrayMesh, b: ArrayMesh) -> bool:
	if a.get_surface_count() != b.get_surface_count(): return false
	for index in a.get_surface_count():
		if a.surface_get_primitive_type(index) != b.surface_get_primitive_type(index): return false
		if var_to_bytes(a.surface_get_arrays(index)) != var_to_bytes(b.surface_get_arrays(index)): return false
	return true

func _roof_original_comparison(original: ArrayMesh, revised: ArrayMesh) -> Dictionary:
	var exact: bool = revised.get_surface_count() == original.get_surface_count() + 1
	var evidence: Array[Dictionary] = []
	for index in original.get_surface_count():
		if index >= revised.get_surface_count():
			exact = false
			break
		var a: Array = original.surface_get_arrays(index)
		var b: Array = revised.surface_get_arrays(index)
		var primitive_exact: bool = original.surface_get_primitive_type(index) == revised.surface_get_primitive_type(index)
		var slots: Array[Dictionary] = []
		var slot_count_exact: bool = a.size() == b.size()
		exact = exact and primitive_exact and slot_count_exact
		for slot in mini(a.size(), b.size()):
			var slot_exact: bool = var_to_bytes(a[slot]) == var_to_bytes(b[slot])
			exact = exact and slot_exact
			slots.append({"slot": slot, "original_sha256": _variant_sha(a[slot]), "actual_sha256": _variant_sha(b[slot]), "byte_exact": slot_exact, "original_variant_type": typeof(a[slot]), "actual_variant_type": typeof(b[slot])})
		evidence.append({"surface_index": index, "primitive_type": original.surface_get_primitive_type(index), "primitive_exact": primitive_exact, "original_slot_count": a.size(), "actual_slot_count": b.size(), "slots": slots})
	var old_bounds: Dictionary = _bounds(original, Basis.IDENTITY)
	var new_bounds: Dictionary = _bounds(revised, Basis.IDENTITY)
	var support_exact: bool = not old_bounds.is_empty() and not new_bounds.is_empty()
	if support_exact:
		support_exact = var_to_bytes(old_bounds["support"]) == var_to_bytes(new_bounds["support"]) and old_bounds["support_count"] == new_bounds["support_count"] and old_bounds["minimum"].y == new_bounds["minimum"].y
	return {"passed": exact and support_exact, "all_original_surface_slots_byte_exact": exact, "surfaces_checked": evidence.size(), "original_surfaces": evidence, "support_exact": support_exact, "original_bounds": _roof_bound_record(old_bounds), "actual_bounds": _roof_bound_record(new_bounds), "comparison_method": "actual native original/revised arrays direct var_to_bytes for every slot; excludes material only; no epsilon, no cross-API topology assumption"}

func _roof_bound_record(bounds: Dictionary) -> Dictionary:
	if bounds.is_empty(): return {"valid": false}
	return {"valid": true, "minimum_m": _v3(bounds["minimum"]), "maximum_m": _v3(bounds["maximum"]), "support_m": _v3(bounds["support"]), "support_count": bounds["support_count"], "actual_used_vertices": bounds["actual_used_vertices"]}

func _roof_cap_evidence(mesh: ArrayMesh, surface_index: int) -> Dictionary:
	var arrays: Array = mesh.surface_get_arrays(surface_index)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices := PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] is PackedInt32Array: indices = arrays[Mesh.ARRAY_INDEX]
	var draw: PackedVector3Array = PackedVector3Array()
	if indices.is_empty():
		draw = vertices
	else:
		for index in indices: draw.append(vertices[index])
	var min_normal_y: float = INF
	var max_normal_y: float = -INF
	for normal: Vector3 in normals:
		min_normal_y = minf(min_normal_y, normal.y)
		max_normal_y = maxf(max_normal_y, normal.y)
	var clockwise_up_faces := 0
	var degenerate_faces := 0
	for offset in range(0, draw.size() - 2, 3):
		var cross: Vector3 = (draw[offset + 1] - draw[offset]).cross(draw[offset + 2] - draw[offset])
		if cross.length_squared() == 0.: degenerate_faces += 1
		if cross.y < 0.: clockwise_up_faces += 1
	var slots: Array[Dictionary] = []
	for index in arrays.size(): slots.append({"slot": index, "variant_type": typeof(arrays[index]), "sha256": _variant_sha(arrays[index])})
	return {"surface_index": surface_index, "primitive_type": mesh.surface_get_primitive_type(surface_index), "vertex_count": vertices.size(), "normal_count": normals.size(), "index_count": indices.size(), "actual_draw_vertex_count": draw.size(), "triangle_count": int(draw.size() / 3), "actual_normal_y_min": min_normal_y, "actual_normal_y_max": max_normal_y, "clockwise_up_faces": clockwise_up_faces, "degenerate_faces": degenerate_faces, "normal_sha256": _variant_sha(normals), "all_actual_surface_array_slots": slots}

func _prop_mesh(kind: String) -> ArrayMesh:
	var result: ArrayMesh = super._prop_mesh(kind)
	if result == null or kind not in ["wall_horizontal", "wall_vertical"]:
		return result
	var horizontal: bool = kind == "wall_horizontal"
	# A complete raised grey-tile coping above the piers, not a tiny strip
	# buried below their caps. This new roof is explicitly an overhang, not
	# permission to widen the wall's original foot collision polygon.
	var span: float = 1.15 if horizontal else 1.30
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tile in 16:
		var start: float = -2.5 + float(tile) * 5.0 / 16.0 + .0045
		var end: float = -2.5 + float(tile + 1) * 5.0 / 16.0 - .0045
		for side: float in [-1.0, 1.0]:
			var cross: float = span * .5 * side
			var a := Vector3(start, 1.73, cross) if horizontal else Vector3(cross, 1.73, start)
			var b := Vector3(end, 1.73, cross) if horizontal else Vector3(cross, 1.73, end)
			var c := Vector3(start, 1.98, 0) if horizontal else Vector3(0, 1.98, start)
			var d := Vector3(end, 1.98, 0) if horizontal else Vector3(0, 1.98, end)
			var normal: Vector3 = (b - a).cross(c - a).normalized()
			# Godot uses clockwise front faces. Negative mathematical cross-Y
			# supplies the actual upwards front face, as in the parent boat mesh.
			var vertices: PackedVector3Array = PackedVector3Array([a, b, c, b, d, c] if normal.y < 0 else [a, c, b, b, c, d])
			for vertex: Vector3 in vertices:
				tool.add_vertex(vertex)
	tool.generate_normals()
	var cap: ArrayMesh = tool.commit()
	if cap == null or cap.get_surface_count() != 1:
		error = "Native tile-cap geometry failed."
		return null
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, cap.surface_get_arrays(0))
	result.surface_set_material(result.get_surface_count() - 1, surface.masonry(Color(.99, .99, .97), _masonry_profile()))
	return result
