extends RefCounted
## One real authored region compilation. No Field, legacy prepare or pixels.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Content = preload("res://build/luoyang_regions_20261027d_source01/region_content_compiler.gd")

func run(_tree_context: SceneTree, input: Dictionary) -> Dictionary:
	var started: int = Time.get_ticks_msec()
	var result: Dictionary = {"passed": false, "errors": [], "Field_instances": 0, "legacy_owner_prepare_calls": 0, "PNG_pixel_decodes": 0, "canonical_writes": 0, "runtime_admission": false}
	if input.get("root_authorized") != true: result.errors.append("ROOT_AUTHORIZATION_REQUIRED"); return result
	if not Core.source_pass(input.module_sources): result.errors.append("MODULE_SOURCE_FIRST"); return result
	var author: Dictionary = Core.read_json(input.author.path, input.author.sha256)
	if author.is_empty(): result.errors.append("AUTHOR_SOURCE"); return result
	var terminals: Dictionary = {}
	for logical: String in author.terminal_bindings:
		var terminal: Dictionary = Core.load_terminal(author.terminal_bindings[logical])
		if terminal.is_empty(): result.errors.append("FIXED_TERMINAL:" + logical); return result
		terminals[logical] = terminal
	var compiled: Dictionary = Content.compile(author, input.region_id, terminals)
	if compiled.get("ok") != true: result.errors.append({"error": compiled.get("error", "COMPILE"), "detail": compiled.get("detail", "")})
	elif not Core.source_pass(compiled.sources): result.errors.append("COMPILED_CONTENT_SOURCE")
	var directory: String = String(input.output_root) + "/" + str(OS.get_process_id())
	if DirAccess.dir_exists_absolute(directory) or DirAccess.make_dir_recursive_absolute(directory) != OK: result.errors.append("NEW_OUTPUT_DIRECTORY"); return result
	if compiled.get("ok") == true:
		var raw: PackedByteArray = var_to_bytes(compiled)
		var path: String = directory + "/civic_region.bin"
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file == null: result.errors.append("OUTPUT"); return result
		file.store_buffer(raw); file.close()
		result["compiled"] = {"path": path, "sha256": FileAccess.get_sha256(path), "bytes": raw.size()}
		result["counts"] = {"render": compiled.render.size(), "solids": compiled.solids.size(), "actors": compiled.npcs.size(), "portals": compiled.portals.size(), "interactions": compiled.interactions.size(), "ground_rectangles": compiled.floor_rects.size()}
		result["source_sha256"] = compiled.sources
	if not Core.source_pass(input.module_sources): result.errors.append("MODULE_SOURCE_FINAL")
	result["passed"] = result.errors.is_empty()
	result["elapsed_ms"] = Time.get_ticks_msec() - started
	var report: FileAccess = FileAccess.open(directory + "/result.json", FileAccess.WRITE)
	if report != null: report.store_string(JSON.stringify(result, "\t") + "\n"); report.close()
	return result
