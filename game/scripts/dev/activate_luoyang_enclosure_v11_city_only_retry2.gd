extends SceneTree
## NEW retry2 sibling of retained byte-backup/journal workflow. No world or
## outskirts publisher/activator, no old-save compatibility, no auto approval.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const APPROVAL_PATH := "res://build/luoyang_enclosure_v11_city_only_approval.json"
const APPROVAL_SHA := "PENDING_ROOT_CITY_ONLY_FRESH_ACTUAL_APPROVAL"
const RECOVERY_ROOT := "res://build/luoyang_enclosure_v11_city_only_cutover/"
const PROTECTED := {"res://data/scenes/world_map_jianghu.tres":"838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015","res://data/config/outskirts_native_adoption.json":"203c9f08e941908ace3e8d56e18a15963e3a60859c04741b04e28a968386d0ff"}
var journal_path := ""
var failure := ""

static func _scene_signature_matches(id: String, actual: Variant) -> bool:
	return C.LEGACY_SHAS.has(id) and actual is String and C._hash(actual) and actual == C.LEGACY_SHAS[id].scene
static func _rollback_entry_error(id: String, path: String, entry: Variant, current_sha: String, backup_sha: String) -> String:
	if not path.begins_with(RECOVERY_ROOT) or ".." in path or not path.ends_with("/journal.json") or not C.LEGACY_SHAS.has(id): return "Recovery scope/identity unbound"
	var target: String = "res://data/scenes/"+id+".tres"
	if not entry is Dictionary or not _scene_signature_matches(id,entry.get("original_sha256")) or entry.get("backup_path") != path.get_base_dir()+"/original_"+target.get_file() or not _scene_signature_matches(id,backup_sha) or not C._hash(entry.get("activated_sha256")): return "Recovery target/backup identity unbound"
	if current_sha != entry.activated_sha256 and current_sha != entry.original_sha256: return "Canonical city changed after operation; preserve unrelated edits"
	return ""

## Pure pre-PREPARED binding core; called with the SHA of the captured byte buffer,
## never with a later reread of the staged pathname.
static func _prepared_binding_error(id: String, entry: Variant, proof: Variant, captured_stage_sha: Variant, current_candidate_sha: Variant, current_layout_sha: Variant) -> String:
	if not C.LEGACY_SHAS.has(id) or not entry is Dictionary or not proof is Dictionary: return "Prepared city identity/records unbound"
	var candidate: String = C.candidate_path(StringName(id))
	var layout: String = C.layout_path(StringName(id))
	if not proof.get("candidate_sha256") is Dictionary or not proof.get("layout_sha256") is Dictionary or entry.get("required_layout_path") != layout: return "Prepared candidate/layout approval tables unbound"
	var candidate_sha: Variant = proof.candidate_sha256.get(candidate)
	var layout_sha: Variant = proof.layout_sha256.get(layout)
	for value: Variant in [captured_stage_sha,current_candidate_sha,current_layout_sha,entry.get("activated_sha256"),entry.get("required_layout_sha256"),candidate_sha,layout_sha]:
		if not value is String or not C._hash(value): return "Prepared candidate/layout SHA malformed"
	if captured_stage_sha != entry.activated_sha256 or captured_stage_sha != candidate_sha or current_candidate_sha != candidate_sha: return "Captured staging/current candidate differs from root approval"
	if current_layout_sha != entry.required_layout_sha256 or current_layout_sha != layout_sha: return "Current required layout differs from root approval"
	return ""

static func _bytes_sha256(bytes: PackedByteArray) -> String:
	if bytes.is_empty(): return ""
	var context := HashingContext.new()
	if context.start(HashingContext.HASH_SHA256) != OK or context.update(bytes) != OK: return ""
	return context.finish().hex_encode()

func _initialize() -> void: call_deferred("_dispatch_city_only")
func _dispatch_city_only() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge == null or not bridge.has_method("set_checkpoint_saves_suspended"): _fail("Public checkpoint suspension unavailable"); return
	bridge.call("set_checkpoint_saves_suspended",true)
	if bridge.call("is_checkpoint_saves_suspended") != true: _fail("Checkpoint suspension not acknowledged"); return
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not "--confirm-producer-approved" in args or not "--city-only-cutover" in args or not "--fresh-start-only" in args: _fail("Explicit producer-approved city-only fresh scope required"); return
	for flag: String in ["--candidate-before-cutover","--outskirts-candidate-preview","--outskirts-complete-v5","--luoyang-v3-candidate","--luoyang-enclosure-v11-candidate"]:
		if flag in args: _fail("No candidate/world/outskirts flags during formal byte operation"); return
	for arg: String in args:
		if arg.begins_with("--rollback-journal="):
			if "--activate" in args: _fail("Activation and rollback are separate"); return
			_rollback(arg.trim_prefix("--rollback-journal=")); return
	if not "--activate" in args: _fail("Explicit activation or rollback journal required"); return
	var proof: Dictionary = _approval()
	if proof.is_empty(): _fail(failure); return
	var directory: String = RECOVERY_ROOT+str(int(Time.get_unix_time_from_system()))+"_"+str(Time.get_ticks_usec())+"/"
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK or not _write(directory+".gdignore",PackedByteArray()): _fail("Cannot retain isolated recovery directory"); return
	var entries: Dictionary = {}
	for id: String in C.LEGACY_SHAS:
		var target: String = "res://data/scenes/"+id+".tres"
		var candidate: String = C.candidate_path(StringName(id))
		var layout: String = C.layout_path(StringName(id))
		var scene: SceneScript = ResourceLoader.load(candidate,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if scene == null or scene.map_layout.resource_path != layout or not C.is_v3(scene) or not C.runtime_fidelity(scene): _fail("Reviewed exact four-city candidate/layout unavailable: "+id); return
		if proof.get("candidate_sha256",{}).get(candidate) != FileAccess.get_sha256(candidate) or proof.get("layout_sha256",{}).get(layout) != FileAccess.get_sha256(layout): _fail("Candidate/layout differs from root approval"); return
		var backup: String = directory+"original_"+target.get_file(); var staged: String = directory+"new_"+target.get_file()
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(target)
		if bytes.is_empty() or not _scene_signature_matches(id,FileAccess.get_sha256(target)) or not _write(backup,bytes) or not _scene_signature_matches(id,FileAccess.get_sha256(backup)) or not _write(staged,FileAccess.get_file_as_bytes(candidate)): _fail("Original/staging bytes not retained exactly"); return
		entries[target] = {"backup_path":backup,"original_sha256":C.LEGACY_SHAS[id].scene,"staged_path":staged,"activated_sha256":FileAccess.get_sha256(staged),"required_layout_path":layout,"required_layout_sha256":FileAccess.get_sha256(layout)}
	var rechecked: Dictionary = _approval()
	if rechecked.is_empty() or not C._equal_value(proof,rechecked): _fail("Approved original/source bytes changed while staging"); return
	# Local buffers are not journal JSON. Capture each staged scene exactly once;
	# these same verified bytes are the only activation-write inputs below.
	var staged_bytes: Dictionary = {}
	for id: String in C.LEGACY_SHAS:
		var target: String = "res://data/scenes/"+id+".tres"
		var entry: Dictionary = entries[target]
		var captured: PackedByteArray = FileAccess.get_file_as_bytes(entry.staged_path)
		var reason: String = _prepared_binding_error(id,entry,proof,_bytes_sha256(captured),FileAccess.get_sha256(C.candidate_path(StringName(id))),FileAccess.get_sha256(C.layout_path(StringName(id))))
		if not reason.is_empty(): _fail(reason+"; no canonical scene writes"); return
		staged_bytes[target] = captured
	journal_path = directory+"journal.json"
	var journal := {"schema_version":1,"scope":"LUOYANG_FOUR_CITY_ONLY_FRESH","state":"PREPARED","targets":entries,"approval_path":APPROVAL_PATH,"approval_sha256":APPROVAL_SHA,"protected_world_outskirts":PROTECTED,"historical_compatibility_tested":false,"formal_no_flags_qa":"NOT_RUN","layout_dependency_scope":"Existing immutable NEW city candidate layouts referenced directly; no old layout overwrite"}
	if not _save_journal(journal): _fail("Recovery journal failed; no canonical scene writes"); return
	for target: String in entries:
		if not _protected_same() or not _write(target,staged_bytes[target]) or FileAccess.get_sha256(target) != entries[target].activated_sha256:
			var restored: bool = _restore(entries); journal.state = "ROLLED_BACK" if restored else "RECOVERY_REQUIRED"; _save_journal(journal)
			_fail("Four-city byte switch failed; recovery journal="+journal_path); return
	journal.state = "ACTIVATED_REQUIRES_FRESH_FORMAL_NO_FLAGS_QA"
	if not _protected_same() or not _save_journal(journal):
		var restored: bool = _restore(entries); journal.state = "ROLLED_BACK" if restored else "RECOVERY_REQUIRED"; _save_journal(journal)
		_fail("Postwrite protected bytes/journal failed; originals retained"); return
	print("LUOYANG_CITY_ONLY_FOUR_SCENES_ACTIVATED_FORMAL_QA_PENDING "+journal_path)
	quit(0)

func _approval() -> Dictionary:
	if not C._hash(APPROVAL_SHA) or FileAccess.get_sha256(APPROVAL_PATH) != APPROVAL_SHA: failure = "Independent root actual city-only approval is PENDING/changed"; return {}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(APPROVAL_PATH))
	if not raw is Dictionary or raw.get("status") != "ROOT_APPROVED_FOUR_CITY_FRESH_CANDIDATE" or raw.get("art_current_images_approved") != true or raw.get("world_subject_version") != 14 or raw.get("historical_compatibility_tested") != false or not _protected_same(): failure = "Independent city-only visual/fresh/protected approval invalid"; return {}
	if not raw.get("source_sha256") is Dictionary or not raw.source_sha256.has("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd") or not raw.source_sha256.has("res://scripts/city/luoyang_layered_v3_contract.gd"): failure = "Final consumer/facade sources not independently approved"; return {}
	for path: String in raw.source_sha256:
		if not C._hash(raw.source_sha256[path]) or FileAccess.get_sha256(path) != raw.source_sha256[path]: failure = "Changed reviewed city source: "+path; return {}
	for id: String in C.LEGACY_SHAS:
		if not _scene_signature_matches(id,FileAccess.get_sha256("res://data/scenes/"+id+".tres")): failure = "Formal city baseline changed"; return {}
	if not raw.get("results") is Array or raw.results.size() != 6: failure = "Actual geometry/gameplay/save BOTH backends required"; return {}
	var seen: Dictionary = {}
	for item: Variant in raw.results:
		if not item is Dictionary or item.get("phase") not in ["geometry","gameplay","save"] or item.get("backend") not in ["headless","gpu"] or not C._hash(item.get("sha256")) or FileAccess.get_sha256(String(item.get("path",""))) != item.sha256 or item.get("actual_os_exit") != 0 or item.get("complete_stderr_reviewed") != true or item.get("source_changes") != [] or item.get("player_changes") != [] or item.get("exact_utc_ticks_reviewed") != true: failure = "Missing actual root process/log/player protection review"; return {}
		var key: String = String(item.phase)+"/"+String(item.backend)
		if seen.has(key): failure = "Duplicate candidate endpoint approval"; return {}
		seen[key] = true
		var result: Variant = JSON.parse_string(FileAccess.get_file_as_string(item.path))
		if not result is Dictionary or result.get("scope") != "LUOYANG_ENCLOSURE_V11_CITY_ONLY_FRESH_ACTUAL" or result.get("complete") != true or result.get("failures") != 0 or result.get("mode",{}).get("phase") != item.phase or result.get("mode",{}).get("candidate") != true or result.get("world_subject_version") != 14 or result.get("historical_compatibility_tested") != false or result.get("actual_audio_driver") != "WASAPI" or not C._equal_value(result.get("players_before"),result.get("players_after")): failure = "Bound actual full city stage result failed"; return {}
	return raw

func _protected_same() -> bool:
	for path: String in PROTECTED:
		if FileAccess.get_sha256(path) != PROTECTED[path]: return false
	return true
func _rollback(path: String) -> void:
	if not path.begins_with(RECOVERY_ROOT) or ".." in path or not path.ends_with("/journal.json") or not _protected_same(): _fail("Only retained city-only journal/protected originals allowed"); return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not raw is Dictionary or raw.get("scope") != "LUOYANG_FOUR_CITY_ONLY_FRESH" or not raw.get("targets") is Dictionary or raw.targets.size() != 4: _fail("Malformed city-only recovery journal"); return
	var entries: Dictionary = raw.targets
	for id: String in C.LEGACY_SHAS:
		var target: String = "res://data/scenes/"+id+".tres"; var entry: Variant = entries.get(target)
		var backup_sha: String = FileAccess.get_sha256(String(entry.get("backup_path",""))) if entry is Dictionary else ""
		var current: String = FileAccess.get_sha256(target)
		var reason: String = _rollback_entry_error(id,path,entry,current,backup_sha)
		if not reason.is_empty(): _fail(reason); return
	journal_path = path
	if not _restore(entries): _fail("Recovery incomplete; original bytes retained"); return
	raw.state = "ROLLED_BACK"
	if not _save_journal(raw): _fail("Original bytes restored; journal update failed"); return
	print("LUOYANG_CITY_ONLY_FOUR_ORIGINAL_SCENES_RESTORED "+path); quit(0)
func _restore(entries: Dictionary) -> bool:
	var ok := true
	for id: String in C.LEGACY_SHAS:
		var target: String = "res://data/scenes/"+id+".tres"
		if not _write(target,FileAccess.get_file_as_bytes(entries[target].backup_path)) or not _scene_signature_matches(id,FileAccess.get_sha256(target)): ok = false
	return ok and _protected_same()
func _save_journal(journal: Dictionary) -> bool: return _write(journal_path,(JSON.stringify(journal,"\t",false)+"\n").to_utf8_buffer())
func _write(path: String, bytes: PackedByteArray) -> bool:
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null: return false
	file.store_buffer(bytes); file.flush(); var ok: bool = file.get_error() == OK; file.close()
	return ok and FileAccess.get_file_as_bytes(path) == bytes
func _fail(reason: String) -> void: push_error(reason); quit(1)
