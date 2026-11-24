extends RefCounted
## One consolidated new-runtime script load. No Field/owner/Scene instantiation,
## transition, input, pixel access, geometry compilation or canonical mutation.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")

func run(_tree_context: SceneTree, input: Dictionary) -> Dictionary:
	var started: int = Time.get_ticks_msec()
	var result: Dictionary = {"passed": false, "errors": [], "rows": [], "Field_instances": 0, "owner_instances": 0, "scene_instances": 0, "explicit_pixel_decodes": 0, "transitions": 0, "canonical_writes": 0, "runtime_admission": false}
	if input.get("root_authorized") != true or not Core.source_pass(input.source_sha256): result.errors.append("AUTHORIZATION_OR_SOURCE_FIRST"); return result
	var flags_before: PackedByteArray = var_to_bytes(GameState.flags)
	var quests_before: PackedByteArray = var_to_bytes(QuestManager.states)
	for item: Dictionary in input.scripts:
		var loaded: Resource = load(String(item.path))
		var valid: bool = loaded is GDScript and loaded.resource_path == item.path and loaded.can_instantiate()
		result.rows.append({"path": item.path, "sha256": item.sha256, "can_instantiate": valid, "instantiated": false})
		if not valid: result.errors.append("SCRIPT_LOAD:" + String(item.path))
	if var_to_bytes(GameState.flags) != flags_before or var_to_bytes(QuestManager.states) != quests_before: result.errors.append("BUSINESS_STATE_CHANGED")
	if not Core.source_pass(input.source_sha256): result.errors.append("SOURCE_FINAL")
	result["passed"] = result.errors.is_empty() and result.rows.size() == input.scripts.size()
	result["elapsed_ms"] = Time.get_ticks_msec() - started
	var directory: String = String(input.output_root) + "/" + str(OS.get_process_id())
	if DirAccess.dir_exists_absolute(directory) or DirAccess.make_dir_recursive_absolute(directory) != OK: return {"passed": false, "errors": ["NEW_OUTPUT_DIRECTORY"]}
	var file: FileAccess = FileAccess.open(directory + "/result.json", FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result, "\t") + "\n"); file.close()
	return result
