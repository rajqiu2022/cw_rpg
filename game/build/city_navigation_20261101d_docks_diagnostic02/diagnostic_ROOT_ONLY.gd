extends "res://build/city_navigation_20261101d_docks_diagnostic01/diagnostic_ROOT_ONLY.gd"
## Independent read-only successor. Preserve01 and its actual138260 failure.
## Never inject a substitute owner/header into C. Raw hashes below are explicitly
## NON-ADMITTING, because original C collection must remain empty while AA refuses.
const HOME2 := "res://build/city_navigation_20261101d_docks_diagnostic02/"
const AA_PATH := "res://scripts/city/luoyang_docks_district08_20261019aa.gd"
const AC_PATH := "res://scripts/city/luoyang_docks_workyard_20261019ac.gd"

func _early(node: Node) -> void:
	if node.name == &"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true)
		suspended = node.call("is_checkpoint_saves_suspended") == true
	if node.name == &"EventBus" and node.has_signal("toast_requested"):
		var callback := Callable(self,"_toast")
		if not node.is_connected("toast_requested",callback): node.connect("toast_requested",callback)

static func _raw_hash_mismatches(pins: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for path: String in pins:
		var actual: String = FileAccess.get_sha256(path)
		if actual != pins[path]: rows.append({"path":path,"expected":pins[path],"actual":actual})
	return rows

static func snapshot_with_header_stages(router: Node) -> Dictionary:
	var base: GDScript = load("res://build/city_navigation_20261101d_docks_diagnostic01/diagnostic_ROOT_ONLY.gd") as GDScript
	var result: Dictionary = base.call("snapshot",router)
	var b: GDScript = load(B_PATH) as GDScript
	var aa: GDScript = load(AA_PATH) as GDScript
	var ac: GDScript = load(AC_PATH) as GDScript
	var a: Dictionary = aa.get_script_constant_map()
	var d: Dictionary = ac.get_script_constant_map()
	var entry: Dictionary = b.call("_entry",DOCKS)
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(String(entry.manifest_path))) as Dictionary
	var aa_raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(String(a.AUTHOR))) as Dictionary
	var ac_raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(String(d.AUTHOR))) as Dictionary
	var author_mismatches: Array[Dictionary] = _raw_hash_mismatches(aa_raw.source_sha256)
	for row: Dictionary in author_mismatches:
		row["original_ordinary_c_source_admitted"] = aa.call("ordinary_c_source_admitted",row.path,row.expected)
	result["header_stage_audit"] = {
		"selected_manifest_path":entry.manifest_path,"selected_manifest_expected_sha":entry.manifest_sha256,
		"selected_manifest_actual_sha":FileAccess.get_sha256(String(entry.manifest_path)),
		"selected_manifest_exact":FileAccess.get_sha256(String(entry.manifest_path)) == entry.manifest_sha256,
		"B_first_Docks_specific_check":"_aa(id).author().is_empty() at B.manifest before raw header admission",
		"AA_author_file_expected_sha":a.AUTHOR_SHA,"AA_author_file_actual_sha":FileAccess.get_sha256(String(a.AUTHOR)),
		"AA_author_source_count":aa_raw.source_sha256.size(),"AA_author_raw_source_mismatches":author_mismatches,
		"AA_author_original_available":not aa.call("author").is_empty(),
		"AA_ordinary_C_path":a.ORDINARY_C_PATH,"AA_ordinary_C_expected_historical_sha":a.ORDINARY_C_OLD_SHA,
		"AA_ordinary_C_outer_FINISH_C_SHA":a.FINISH_C_SHA,"actual_current_C_SHA":FileAccess.get_sha256(String(a.ORDINARY_C_PATH)),
		"AA_hard_actualC_equals_FINISH_C_SHA":FileAccess.get_sha256(String(a.ORDINARY_C_PATH)) == a.FINISH_C_SHA,
		"AA_finish_parent_bytes_count":aa.call("_finish_c_parent_bytes").size(),
		"AA_current_parent_bytes_count":aa.call("_ordinary_c_current_parent_bytes").size(),
		"AC_author_original_available":not ac.call("author").is_empty(),
		"AC_author_raw_source_mismatches_NOT_OWNER_ADMISSION":_raw_hash_mismatches(ac_raw.source_sha256),
		"AC_source_paths_original_count":ac.call("source_paths").size(),
		"no_guard_bypass_or_owner_substitution":true}
	var domains: Dictionary = {}
	for key: String in ["legacy_source_sha256","runtime_authority_sha256","artifacts"]:
		domains[key] = {"count":raw.get(key,{}).size(),"mismatches":_raw_hash_mismatches(raw.get(key,{}))}
	result["unadmitted_raw_AC_manifest_hash_audit"] = domains
	result["raw_AC_manifest_hash_audit_is_not_actual_C_collector_or_B_admission"] = true
	result["actual_C_collection_blocked_by_original_AA_author_gate"] = int(result.get("actual_count",0)) == 0 and aa.call("author").is_empty()
	return result

func run() -> void:
	await process_frame
	if not suspended: printerr("DOCKS_DIAGNOSTIC02_EARLY_SAVE_SUSPEND_REQUIRED"); quit(1); return
	var router: Node = root.get_node_or_null("SceneRouter")
	if router == null: printerr("DOCKS_DIAGNOSTIC02_ROUTER_MISSING"); quit(1); return
	var result: Dictionary = snapshot_with_header_stages(router)
	result["toasts_observed_this_process"] = toasts.duplicate()
	result["standalone_no_navigation_requested"] = true
	result["prior_process_public_state_not_recoverable"] = true
	var directory: String = HOME2 + "actual/" + str(OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(directory)
	var output: FileAccess = FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if output == null: printerr("DOCKS_DIAGNOSTIC02_OUTPUT_OPEN_FAILED"); quit(1); return
	output.store_string(JSON.stringify(result,"\t")+"\n"); output.close()
	print("DOCKS_DIAGNOSTIC02 ",JSON.stringify({"result":directory+"/result.json","actual_count":result.get("actual_count",0),"selected_manifest_exact":result.header_stage_audit.selected_manifest_exact,"AA_author_original_available":result.header_stage_audit.AA_author_original_available,"AA_ordinary_C_outer_hardpin_matches":result.header_stage_audit.AA_hard_actualC_equals_FINISH_C_SHA,"travel_requests":0}))
	quit(0)
