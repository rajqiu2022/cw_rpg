extends RefCounted
## Loaded only after the normal project's 16 autoloads have initialized.
const Adapter = preload("res://build/luoyang_regions_20261027d_source01/terminal_adapter03_market.gd")
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")

func run(tree_context: SceneTree, input: Dictionary) -> Dictionary:
	var started: int = Time.get_ticks_msec()
	var result: Dictionary = {"passed": false, "errors": [], "rows": [], "Field_instances": 0, "legacy_owner_prepare_calls": 0, "PNG_pixel_decodes": 0, "canonical_writes": 0, "runtime_admission": false}
	if input.get("root_authorized") != true: result.errors.append("ROOT_AUTHORIZATION_REQUIRED"); return result
	var modules: Dictionary = input.get("module_sources", {})
	if not Core.source_pass(modules): result.errors.append("MODULE_SOURCE_FIRST"); return result
	# Enumerate ALL actual actor media before any terminal rebuild/seal. Missing
	# tuples are reported together; no per-PNG engine retry.
	var media_missing: Array = []
	var checked_media: Dictionary = {}
	for path: String in input.get("final_actor_media_paths", []):
		if not Adapter.capture_media(path, checked_media, input.available_parent_sources): media_missing.append(path)
	if not media_missing.is_empty(): result.errors.append({"all_actor_media_authority_missing": media_missing}); return result
	result["all_actor_media_authority_checked"] = checked_media.size()
	var flags_before: PackedByteArray = var_to_bytes(GameState.flags)
	var quests_before: PackedByteArray = var_to_bytes(QuestManager.states)
	var directory: String = String(input.output_root) + "/" + str(OS.get_process_id())
	if DirAccess.dir_exists_absolute(directory) or DirAccess.make_dir_recursive_absolute(directory) != OK: result.errors.append("NEW_OUTPUT_DIRECTORY"); return result
	for binding: Dictionary in input.bindings:
		if Time.get_ticks_msec() - started > 20000: result.errors.append("COLD_COMPILE_20S"); break
		var product: Dictionary = Adapter.build(binding, input.terminal_sources[binding.logical_id], GameState.flags.duplicate(true), QuestManager.states.duplicate(true), input.available_parent_sources)
		if product.get("ok") != true:
			result.errors.append({"logical_id": binding.logical_id, "error": product.get("error", "TERMINAL_BUILD"), "detail": product.get("detail", "")}); continue
		var terminal: Dictionary = product.terminal
		var bin_path: String = directory + "/" + binding.logical_id + "_terminal.bin"
		var raw: PackedByteArray = var_to_bytes(terminal)
		var file: FileAccess = FileAccess.open(bin_path, FileAccess.WRITE)
		if file == null: result.errors.append("TERMINAL_OUTPUT"); continue
		file.store_buffer(raw); file.close()
		var actors: Array = []; var doors: Array = []; var interactions: Array = []
		for actor: Dictionary in terminal.npcs:
			actors.append({"npc_id": actor.data.npc_id, "foot_px": [actor.foot_px.x, actor.foot_px.y], "half_body": [actor.half_body.x, actor.half_body.y], "default_active": actor.get("default_active", true), "phase_exclusive_group": actor.get("phase_exclusive_group", ""), "movement_mode": actor.data.get("movement_mode", "idle"), "patrol_axis": str(actor.data.get("patrol_axis", Vector2.RIGHT)), "patrol_distance": actor.data.get("patrol_distance", 0), "role": actor.data.get("npc_name", "")})
		for door: Dictionary in terminal.portals:
			doors.append({"id": door.id, "foot_px": [door.foot_px.x, door.foot_px.y], "target_scene": door.target_scene, "legacy_source_uv": [door.legacy_source_uv.x, door.legacy_source_uv.y], "target_pos": str(door.data.get("target_pos")), "label": door.data.get("label", "")})
		for area: Dictionary in terminal.interactions:
			interactions.append({"id": area.id, "foot_px": [area.foot_px.x, area.foot_px.y], "default_active": area.get("default_active", true), "size_px": [area.size_px.x, area.size_px.y], "action": area.data.get("action", "")})
		result.rows.append({"logical_id": binding.logical_id, "terminal": {"path": bin_path, "sha256": FileAccess.get_sha256(bin_path), "bytes": raw.size()}, "render_count": terminal.render.size(), "solid_count": terminal.solids.size(), "actors": actors, "portals": doors, "interactions": interactions, "source_sha256": terminal.sources, "complete_owner_solids_typed_sequence": true, "source_resource_unmodified": true})
	if var_to_bytes(GameState.flags) != flags_before or var_to_bytes(QuestManager.states) != quests_before: result.errors.append("QUEST_OR_FLAGS_CHANGED")
	if not Core.source_pass(modules): result.errors.append("MODULE_SOURCE_FINAL")
	result["module_sources"] = modules.duplicate(true)
	result["elapsed_ms"] = Time.get_ticks_msec() - started
	result["passed"] = result.errors.is_empty() and result.rows.size() == input.bindings.size()
	result["output_directory"] = directory
	var output: FileAccess = FileAccess.open(directory + "/result.json", FileAccess.WRITE)
	if output != null: output.store_string(JSON.stringify(result, "\t") + "\n"); output.close()
	return result
