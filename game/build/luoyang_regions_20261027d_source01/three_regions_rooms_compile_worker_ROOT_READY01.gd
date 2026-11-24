extends RefCounted
## One cold pure content compile: inherit Civic21844, compile two new courts
## and their six real rooms. Never reproject the four successful terminals.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Courts = preload("res://build/luoyang_regions_20261027d_source01/region_content_rooms02.gd")
const Rooms = preload("res://build/luoyang_regions_20261027d_source01/region_room_compiler.gd")
const Furniture = preload("res://build/luoyang_regions_20261027d_source01/room_furniture_terminal.gd")

func run(_tree_context: SceneTree, input: Dictionary) -> Dictionary:
	var started: int = Time.get_ticks_msec()
	var result: Dictionary = {"passed": false, "errors": [], "rows": [], "Field_instances": 0, "legacy_owner_prepare_calls": 0, "NPC_reprojections": 0, "PNG_pixel_decodes": 0, "canonical_writes": 0, "runtime_admission": false}
	if input.get("root_authorized") != true or not Core.source_pass(input.module_sources): result.errors.append("MODULE_SOURCE_FIRST_OR_AUTHORIZATION"); return result
	var author: Dictionary = Core.read_json(input.author.path, input.author.sha256)
	if author.is_empty(): result.errors.append("AUTHOR_SOURCE"); return result
	var inputs: Dictionary = {}
	for logical: String in author.terminal_bindings:
		var terminal: Dictionary = Core.load_terminal(author.terminal_bindings[logical])
		if terminal.is_empty(): result.errors.append("IMMUTABLE_TERMINAL:" + logical); return result
		inputs[logical] = terminal
	for logical: String in author.furniture_donor_bindings:
		var product: Dictionary = Furniture.build(author.furniture_donor_bindings[logical], author.media_authority)
		if product.get("ok") != true: result.errors.append(product); return result
		inputs[logical] = product.terminal
	var directory: String = String(input.output_root) + "/" + str(OS.get_process_id())
	if DirAccess.dir_exists_absolute(directory) or DirAccess.make_dir_recursive_absolute(directory) != OK: result.errors.append("NEW_OUTPUT_DIRECTORY"); return result
	var inherited: Dictionary = input.inherited_civic
	if FileAccess.get_sha256(inherited.path) != inherited.sha256 or FileAccess.get_file_as_bytes(inherited.path).size() != int(inherited.bytes): result.errors.append("INHERITED_CIVIC_ACTUAL_PIN"); return result
	result.rows.append({"region_id": "luoyang_civic_market_region_27d", "inherited": true, "compiled": inherited.duplicate(true), "credit": "21844 complete compiler component only; no Field/runtime credit"})
	var ids: Array = ["luoyang_estate_region_27d", "luoyang_temple_region_27d"]
	ids.append_array(Rooms.ROOMS)
	for identity: String in ids:
		var compiled: Dictionary = Courts.compile(author, identity, inputs) if identity not in Rooms.ROOMS else Rooms.compile(author, identity, inputs)
		if compiled.get("ok") != true:
			result.errors.append({"region_id": identity, "error": compiled.get("error", "COMPILE"), "detail": compiled.get("detail", "")}); continue
		if not Core.source_pass(compiled.sources): result.errors.append({"region_id": identity, "error": "COMPILED_SOURCE"}); continue
		var raw: PackedByteArray = var_to_bytes(compiled)
		var path: String = directory + "/" + identity + ".bin"
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file == null: result.errors.append("OUTPUT:" + identity); continue
		file.store_buffer(raw); file.close()
		result.rows.append({"region_id": identity, "inherited": false, "compiled": {"path": path, "sha256": FileAccess.get_sha256(path), "bytes": raw.size()}, "counts": {"render": compiled.render.size(), "solids": compiled.solids.size(), "actors": compiled.npcs.size(), "portals": compiled.portals.size(), "interactions": compiled.interactions.size(), "positive_ground": compiled.floor_rects.size()}, "source_sha256": compiled.sources})
	if not Core.source_pass(input.module_sources): result.errors.append("MODULE_SOURCE_FINAL")
	result["passed"] = result.errors.is_empty() and result.rows.size() == 9
	result["elapsed_ms"] = Time.get_ticks_msec() - started
	var output: FileAccess = FileAccess.open(directory + "/result.json", FileAccess.WRITE)
	if output != null: output.store_string(JSON.stringify(result, "\t") + "\n"); output.close()
	return result
