extends "res://scripts/dev/build_luoyang_modular_v3.gd"
## Visual-only isolated prototype trial. Never writes city art or runtime data.
## Base meshes and ground supports are unchanged; raised tile overhang is new.
const BASE_BUILDER := "res://scripts/dev/build_luoyang_modular_v3.gd"
const BASE_BUILDER_SHA := "3a7fa038d977c3671eeeda1dabaf8cd6c5e20807964b89eaee09ae0091950a30"

func _run() -> void:
	if "--city-wall-tile-cap-pilot" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		push_error("Explicit isolated GPU wall-cap trial required.")
		quit(2)
		return
	if FileAccess.get_sha256(BASE_BUILDER) != BASE_BUILDER_SHA:
		push_error("Frozen masonry base builder changed; trial refuses.")
		quit(2)
		return
	var trial_root := "res://build/luoyang_wall_tile_cap_trial/%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
	surface = SURFACE.new()
	if not surface.load_sources():
		error = surface.error
		await _finish(false)
		return
	var records: Array[Dictionary] = []
	for district: String in ["ch4_s0_luoyang_gate", "ch4_s1_luoyang_yamen"]:
		source = SOURCE.new()
		source.prepare(district)
		OUT = trial_root + district + "/"
		if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "entities/")) != OK:
			error = "Trial directory creation failed."
			await _finish(false)
			return
		for kind: String in ["wall_horizontal", "wall_vertical"]:
			var base: ArrayMesh = super._prop_mesh(kind)
			var base_bounds: Dictionary = _bounds(base, Basis.IDENTITY)
			if not await _prototype(kind):
				await _finish(false)
				return
			var current: ArrayMesh = prototypes[kind].mesh
			var bounds: Dictionary = _bounds(current, Basis.IDENTITY)
			var base_exact := current.get_surface_count() == base.get_surface_count() + 1
			for index in base.get_surface_count():
				base_exact = base_exact and var_to_bytes(base.surface_get_arrays(index)) == var_to_bytes(current.surface_get_arrays(index))
			var support_exact: bool = bounds.support == base_bounds.support and bounds.support_count == base_bounds.support_count
			if not base_exact or not support_exact:
				error = "Raised cap changed original base arrays or actual support."
				await _finish(false)
				return
			var captured: Dictionary = prototypes[kind].record
			captured["geometry_change_scope"] = "Isolated raised tile-cap geometry trial: original base surface arrays byte-exact; one new raised tile surface; original ground support unchanged. NOT material-only, NOT formal city approval."
			if not _json(String(captured.metadata_path), captured):
				await _finish(false)
				return
			records.append({"district": district, "kind": kind, "base_surface_arrays_byte_exact": base_exact, "ground_support_exact": support_exact, "base_support_m": _v3(base_bounds.support), "trial_support_m": _v3(bounds.support), "new_geometry_scope": "one raised tile surface; roof overhang is NOT a widened ground solid", "captured_prototype": prototypes[kind].record})
		prototypes.clear()
	if not _json(trial_root + "result.json", {"scope": "ISOLATED_VISUAL_WALL_CAP_NOT_CITY_OR_FIELD_APPROVAL", "executed_builder": get_script().resource_path, "executed_builder_sha256": FileAccess.get_sha256(get_script().resource_path), "frozen_base_builder_sha256": BASE_BUILDER_SHA, "records": records, "production_approved": false, "formal_city_bytes_written": false}):
		await _finish(false)
		return
	print("CITY_WALL_CAP_TRIAL ", trial_root)
	await _finish(true)

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
