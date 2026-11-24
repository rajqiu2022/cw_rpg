extends SceneTree
## NEW risk-stratified RELEASE sibling of immutable V9c activator. Explicit producer operation only. Six canonical targets, retained byte-exact
## backups and a recovery journal; no gameplay, save or auto-approval calls.
const GATE = preload("res://scripts/dev/joint_world_city_v15_release_acceptance.gd")
const WORLD = preload("res://scripts/world/world_map_v15_contract.gd")
const CITY = preload("res://scripts/city/luoyang_layered_v3_contract.gd")
const OUTSKIRTS = preload("res://scripts/world/outskirts_native_contract.gd")
const RECOVERY_ROOT := "res://build/joint_world_city_v15_release_cutover/"
var _journal_path := ""

func _initialize() -> void:
	call_deferred("_dispatch")

func _dispatch() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not "--confirm-producer-approved" in args: _fail("Producer confirmation required; no formal writes"); return
	for arg: String in args:
		if arg.begins_with("--rollback-journal="):
			if "--activate" in args: _fail("Activation and recovery are separate operations"); return
			_rollback(arg.trim_prefix("--rollback-journal=")); return
	if not "--activate" in args: _fail("Explicit --activate or retained rollback journal required"); return
	var fresh_start: bool = "--fresh-start-only" in args
	if args.count("--fresh-start-only") > 1: _fail("Fresh-start mode must be selected exactly once"); return
	var acceptance_scope: String = GATE.FRESH_START_PHASE if fresh_start else GATE.RELEASE_PHASE
	var error: String = GATE.approval_error(fresh_start)
	if not error.is_empty(): _fail(error); return
	var reviewed: Dictionary = GATE.snapshot()
	var directory: String = RECOVERY_ROOT + str(int(Time.get_unix_time_from_system())) + "_" + str(Time.get_ticks_usec()) + "/"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK: _fail("Cannot create recovery directory"); return
	if not _write(directory + ".gdignore", PackedByteArray()): _fail("Cannot isolate retained recovery evidence"); return
	var entries: Dictionary = {}
	for target: String in GATE.BASELINE:
		var backup: String = directory + "original_" + target.get_file()
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(target)
		if bytes.is_empty() or not _write(backup, bytes) or FileAccess.get_sha256(backup).to_lower() != GATE.BASELINE[target]: _fail("Original bytes could not be retained: " + target); return
		entries[target] = {"backup_path": backup, "original_sha256": GATE.BASELINE[target], "staged_path": directory + "new_" + target.get_file()}
	var world: SceneScript = ResourceLoader.load(WORLD.CANDIDATE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not WORLD.is_v15(world): _fail("Reviewed world candidate unavailable"); return
	# Preserve the candidate's external layout/stream bindings. Only its scene
	# identity becomes canonical; independent candidate resources stay untouched.
	var formal_world: SceneScript = world.duplicate(false) as SceneScript
	formal_world.scene_id = &"world_map_jianghu"
	var world_target := "res://data/scenes/world_map_jianghu.tres"
	if ResourceSaver.save(formal_world, String(entries[world_target].staged_path)) != OK: _fail("World staging failed"); return
	for id: String in CITY.LEGACY_SHAS:
		var target := "res://data/scenes/" + id + ".tres"
		if not _write(String(entries[target].staged_path), FileAccess.get_file_as_bytes(CITY.candidate_path(StringName(id)))): _fail("City staging failed: " + id); return
	var adopted := {"schema_version": 1, "status": "APPROVED_LOCAL_FIELDS", "art_root": OUTSKIRTS.COMPLETE_V5_ROOT, "contract_sha256": {}, "reason": "Independent joint actual-image and risk-stratified RELEASE normal-gameplay approval; retained exact rollback journal.", "acceptance_scope": acceptance_scope, "legacy_full_executed": false, "exhaustive_2687_normal_input_executed": false}
	if fresh_start:
		adopted.reason = "Independent joint fresh-start/current-format actual Field approval only; historical compatibility not tested; retained exact rollback journal."
		adopted.merge(_fresh_start_metadata())
	for biome: String in OUTSKIRTS.ENTRIES:
		adopted.contract_sha256[biome] = FileAccess.get_sha256(OUTSKIRTS.COMPLETE_V5_ROOT + biome + "/art_contract.json").to_lower()
	if not _write(String(entries[OUTSKIRTS.ADOPTION].staged_path), (JSON.stringify(adopted, "\t") + "\n").to_utf8_buffer()): _fail("Outskirts staging failed"); return
	for target: String in entries:
		entries[target]["activated_sha256"] = FileAccess.get_sha256(String(entries[target].staged_path)).to_lower()
		if not GATE._hash(entries[target].activated_sha256): _fail("Unverifiable staged bytes: " + target); return
	var staged_world: SceneScript = ResourceLoader.load(String(entries[world_target].staged_path), "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not WORLD.is_v15(staged_world) or staged_world.scene_id != &"world_map_jianghu": _fail("Staged canonical world lost binding"); return
	for id: String in CITY.LEGACY_SHAS:
		var staged: SceneScript = ResourceLoader.load(String(entries["res://data/scenes/" + id + ".tres"].staged_path), "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if not CITY.is_v3(staged) or not CITY.runtime_fidelity(staged): _fail("Staged city lost native/gameplay identity: " + id); return
	# Stage serialization must not change approved source/candidate bytes. Recheck
	# independent approvals and baseline after all backups, before any target write.
	error = GATE.approval_error(fresh_start)
	if not error.is_empty() or not GATE.matches_snapshot(GATE.snapshot(), reviewed): _fail("Approval/baseline changed while staging: " + error); return
	_journal_path = directory + "journal.json"
	var journal := {"schema_version": 1, "state": "PREPARED", "world_coordinate_version": 15, "city_layout_version": 3, "targets": entries, "approved_source_sha256": reviewed, "acceptance_scope": acceptance_scope, "legacy_full_executed": false, "exhaustive_2687_normal_input_executed": false}
	if fresh_start: journal.merge(_fresh_start_metadata())
	if not _save_journal(journal): _fail("Recovery journal could not be persisted; no formal writes"); return
	for target: String in entries:
		if not _write(target, FileAccess.get_file_as_bytes(String(entries[target].staged_path))) or FileAccess.get_sha256(target).to_lower() != entries[target].activated_sha256:
			var restored: bool = _restore(entries)
			journal.state = "ROLLED_BACK" if restored else "RECOVERY_REQUIRED"
			_save_journal(journal)
			_fail("Formal write failed; " + ("all six original bytes restored" if restored else "manual recovery required") + "; journal=" + _journal_path); return
	journal.state = "ACTIVATED_REQUIRES_FRESH_FORMAL_QA"
	if not _save_journal(journal):
		var restored: bool = _restore(entries)
		_fail("Final journal write failed; " + ("original bytes restored" if restored else "recovery required") + "; journal=" + _journal_path); return
	var result := {"state": journal.state, "journal_path": _journal_path, "targets": entries, "formal_post_cutover_field_qa": "NOT_RUN", "acceptance_scope": acceptance_scope, "legacy_full_executed": false, "exhaustive_2687_normal_input_executed": false}
	if fresh_start: result.merge(_fresh_start_metadata())
	print(JSON.stringify(result))
	quit(0)

func _fresh_start_metadata() -> Dictionary:
	return {"fresh_start_only": true, "historical_compatibility_tested": false, "excluded_historical_versions": GATE.EXCLUDED_HISTORICAL_VERSIONS.duplicate(true), "excluded_world_source_versions": [12, 13, 14], "excluded_local_source_versions": [1]}

func _rollback(path: String) -> void:
	if not path.begins_with(RECOVERY_ROOT) or ".." in path or not path.ends_with("/journal.json"): _fail("Only this operation's retained journal is allowed"); return
	var journal: Dictionary = WORLD.read_json(path)
	var entries: Variant = journal.get("targets")
	if journal.get("schema_version") != 1 or not entries is Dictionary or entries.size() != GATE.BASELINE.size(): _fail("Malformed recovery journal"); return
	for target: String in GATE.BASELINE:
		var entry: Variant = entries.get(target)
		if not entry is Dictionary or entry.get("original_sha256") != GATE.BASELINE[target] or entry.get("backup_path") != path.get_base_dir() + "/original_" + target.get_file() or FileAccess.get_sha256(String(entry.backup_path)).to_lower() != GATE.BASELINE[target] or not GATE._hash(entry.get("activated_sha256")): _fail("Recovery bytes/target identity unbound: " + target); return
		var current: String = FileAccess.get_sha256(target).to_lower()
		if current != entry.activated_sha256 and current != GATE.BASELINE[target]: _fail("Target changed after activation; refuse overwriting unrelated edits: " + target); return
	_journal_path = path
	if not _restore(entries): _fail("Recovery failed; originals retained at " + path.get_base_dir()); return
	journal.state = "ROLLED_BACK"
	if not _save_journal(journal): _fail("Bytes restored but recovery journal update failed"); return
	print("JOINT_V15_ALL_SIX_FORMAL_TARGET_BYTES_RESTORED: " + path)
	quit(0)

func _restore(entries: Dictionary) -> bool:
	var ok := true
	for target: String in GATE.BASELINE:
		if not _write(target, FileAccess.get_file_as_bytes(String(entries[target].backup_path))) or FileAccess.get_sha256(target).to_lower() != GATE.BASELINE[target]: ok = false
	return ok

func _save_journal(journal: Dictionary) -> bool:
	return _write(_journal_path, (JSON.stringify(journal, "\t") + "\n").to_utf8_buffer())

func _write(path: String, bytes: PackedByteArray) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_buffer(bytes)
	file.flush()
	var success: bool = file.get_error() == OK
	file.close()
	return success and FileAccess.file_exists(path) and FileAccess.get_file_as_bytes(path) == bytes

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
