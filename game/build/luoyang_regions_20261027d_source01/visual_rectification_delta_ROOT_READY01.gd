extends RefCounted
## Retire only explicitly named proxy bodies/visuals, move one bound external
## door, and append decorative data. Never invoke the content compiler.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Ownership = preload("res://build/luoyang_regions_20261027d_source01/civic_three_building_delta_ROOT_READY.gd")

func run(_tree_context: SceneTree, input: Dictionary) -> Dictionary:
	var result: Dictionary = {"passed": false, "errors": [], "components": [], "Field_instances": 0, "PNG_decodes": 0, "geometry_compile_calls": 0, "canonical_writes": 0}
	if input.get("root_authorized") != true or not Core.source_pass(input.module_sources): return _fail(result, "FIXED_MODULES")
	var original: Dictionary = Core.read_json(input.parent_author.path, input.parent_author.sha256)
	var author: Dictionary = Core.read_json(input.author.path, input.author.sha256)
	if original.is_empty() or author.is_empty(): return _fail(result, "AUTHOR_SOURCE")
	var terminals: Dictionary = {}
	for logical: String in input.terminals:
		var terminal: Dictionary = _read(input.terminals[logical])
		if terminal.get("schema") != "27D_SOURCE_TERMINAL_V1" or terminal.logical_id != logical: return _fail(result, "TERMINAL_SOURCE:" + logical)
		terminals[logical] = terminal
	var directory: String = String(input.output_root) + "/" + str(OS.get_process_id())
	if DirAccess.dir_exists_absolute(directory) or DirAccess.make_dir_recursive_absolute(directory) != OK: return _fail(result, "NEW_OUTPUT_DIRECTORY")
	for item: Dictionary in input.components:
		var parent: Dictionary = _read(item.parent)
		if parent.get("ok") != true or parent.get("id") != item.id: return _fail(result, "PARENT_BIN:" + item.id)
		var out: Dictionary = parent.duplicate(true)
		var removed_render: Array = []; var removed_solids: Array = []
		if not item.retire_keys.is_empty():
			var ownership: Dictionary = Ownership._solid_ownership(original.regions[item.id], terminals, parent)
			if ownership.get("ok") != true: return _fail(result, "OWNER_SEQUENCE:" + item.id)
			var retained_render: Array = []; var owner_counts: Dictionary = {}
			for index: int in range(parent.render.size()):
				var row: Dictionary = parent.render[index]
				if row.key in item.retire_keys:
					removed_render.append({"index": index, "row": row.duplicate(true)})
					owner_counts[row.key] = 0
				else: retained_render.append(row)
			if removed_render.size() != item.retire_keys.size(): return _fail(result, "EXACT_RETIRE_ROWS:" + item.id)
			var retained_solids: Array = []
			for index: int in range(parent.solids.size()):
				var owner: String = ownership.owners[index]
				var key: String = item.retire_owner_to_key.get(owner, "")
				if not key.is_empty():
					if not owner_counts.has(key): return _fail(result, "BODY_WITHOUT_RETIRED_ROW")
					owner_counts[key] += 1
					removed_solids.append({"index": index, "polygon": parent.solids[index].duplicate(), "owner": owner})
				else: retained_solids.append(parent.solids[index])
			for key: String in owner_counts:
				if owner_counts[key] != 1: return _fail(result, "EXACT_ONE_OWNED_BASE:" + key)
			out.render = retained_render; out.solids = []; out.solid_cells = {}
			for polygon: PackedVector2Array in retained_solids: Core._append_solid(out, polygon)
			# Removal only: every retained polygon remains bit-identical and in order.
			if var_to_bytes(out.solids) != var_to_bytes(retained_solids): return _fail(result, "RETAINED_SOLID_SEQUENCE")
		var old_door: Dictionary = {}
		if item.has("door"):
			var change: Dictionary = item.door
			var rows: Array = out.portals.filter(func(row: Dictionary) -> bool: return row.key == change.key)
			if rows.size() != 1: return _fail(result, "UNIQUE_GATE_DOOR")
			var door: Dictionary = rows[0]; old_door = door.duplicate(true)
			if door.foot != Core.vec(change.old_foot) or door.return_foot != Core.vec(change.old_return) or door.target_scene != "ch4_s0_luoyang_gate": return _fail(result, "BOUND_ORIGINAL_GATE")
			door.foot = Core.vec(change.foot); door.return_foot = Core.vec(change.return_foot)
			if Core.district_at(out, door.foot) != door.logical_id or Core.district_at(out, door.return_foot) != door.logical_id: return _fail(result, "GATE_LOGICAL_DOMAIN")
			for route: Array in change.routes:
				for index: int in range(1, route.size()):
					var a: Vector2 = Core.vec(route[index - 1]); var b: Vector2 = Core.vec(route[index])
					if not Core.safe_segment(out, a, b, Vector2(17, 12)) or not Core.npc_route_clear(out, a, b, Vector2(17, 12)): return _fail(result, "GATE_LOCAL_BODY_OR_NPC")
			var inverse_door: Dictionary = door.duplicate(true)
			inverse_door.foot = old_door.foot; inverse_door.return_foot = old_door.return_foot
			if var_to_bytes(inverse_door) != var_to_bytes(old_door): return _fail(result, "GATE_ID_TARGET_RAW_SOURCE_CHANGED")
		var decoration: Dictionary = author.regions[item.id].visual_underlay
		for source_path: String in decoration.source_sha256:
			if parent.sources.get(source_path) != decoration.source_sha256[source_path]: return _fail(result, "UNDERLAY_NOT_ALREADY_CAPTURED")
		if not Core.source_pass(decoration.source_sha256): return _fail(result, "UNDERLAY_MEDIA")
		out["visual_underlay"] = decoration.duplicate(true)
		out["hud_display_names"] = author.regions[item.id].hud_display_names.duplicate(true)
		var inverse: Dictionary = out.duplicate(true)
		inverse.erase("visual_underlay"); inverse.erase("hud_display_names")
		for row: Dictionary in removed_render: inverse.render.insert(row.index, row.row)
		for row: Dictionary in removed_solids: inverse.solids.insert(row.index, row.polygon)
		inverse.solid_cells = parent.solid_cells.duplicate(true)
		if not old_door.is_empty():
			for index: int in range(inverse.portals.size()):
				if inverse.portals[index].key == old_door.key: inverse.portals[index] = old_door
		if var_to_bytes(inverse) != FileAccess.get_file_as_bytes(item.parent.path): return _fail(result, "WHOLE_TYPED_BINARY_INVERSE:" + item.id)
		var output_path: String = directory + "/" + String(item.id) + ".bin"
		var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
		if file == null: return _fail(result, "OUTPUT_BIN")
		file.store_buffer(var_to_bytes(out)); file.close()
		result.components.append({"id": item.id, "path": output_path, "sha256": FileAccess.get_sha256(output_path), "bytes": FileAccess.get_file_as_bytes(output_path).size(), "retired_render": removed_render.size(), "retired_bodies": removed_solids.size(), "render_count": out.render.size(), "solid_count": out.solids.size(), "whole_typed_inverse": true, "positive_ground_unchanged": var_to_bytes(out.floor_rects) == var_to_bytes(parent.floor_rects), "npcs_interactions_unchanged": var_to_bytes(out.npcs) == var_to_bytes(parent.npcs) and var_to_bytes(out.interactions) == var_to_bytes(parent.interactions), "old_gate_source_unchanged": not old_door.is_empty()})
	if not Core.source_pass(input.module_sources): return _fail(result, "MODULE_SOURCE_FINAL")
	for component: Dictionary in input.components:
		if FileAccess.get_sha256(component.parent.path) != component.parent.sha256: return _fail(result, "PARENT_SOURCE_FINAL")
	result.passed = true
	var report := FileAccess.open(directory + "/result.json", FileAccess.WRITE)
	if report == null: return _fail(result, "OUTPUT_REPORT")
	report.store_string(JSON.stringify(result, "  ") + "\n"); report.close()
	return result

func _read(binding: Dictionary) -> Dictionary:
	if FileAccess.get_sha256(binding.path) != binding.sha256: return {}
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(binding.path)
	if bytes.size() != int(binding.bytes): return {}
	var value: Variant = bytes_to_var(bytes)
	return value if value is Dictionary and Core.plain(value) else {}

func _fail(result: Dictionary, error: String) -> Dictionary:
	result.errors.append(error); return result
