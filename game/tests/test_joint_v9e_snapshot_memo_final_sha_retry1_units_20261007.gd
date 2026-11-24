extends SceneTree
## SOURCE_READY fixture units only; never calls the real full snapshot or Field.
## ROOT must supply the retained original gate and the exact candidate gate SHA.
## Runtime writes are confined to this run's NEW build fixture/evidence directory.
const GATE_PATH := "res://scripts/dev/joint_world_city_v15_release_acceptance.gd"
const ORIGINAL_SHA := "e29f17f22e2c17beb44f9dff6dd2612b4dd08e33fa21932ccde75c640dace1ff"
const DOMAIN := "res://build/joint_world_luoyang_20261003_qa/"
var checks := 0
var errors: Array[String] = []
var fixture_root := ""
var original_path := ""
var candidate_sha := ""
var original_methods_sha := ""
var gate: Script
var original: GDScript
var fixture_keys: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: errors.append(label)
	return ok

func _sha(value: String) -> bool:
	if value.length() != 64: return false
	for character: String in value.to_lower():
		if character not in "0123456789abcdef": return false
	return true

func _args() -> bool:
	var seen: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		var pair: PackedStringArray = argument.split("=", true, 1)
		if not _check(pair.size() == 2 and pair[0] in ["--original-gate", "--candidate-gate-sha"] and not seen.has(pair[0]), "exact unique explicit unit arguments"): return false
		seen[pair[0]] = true
		if pair[0] == "--original-gate": original_path = pair[1]
		else: candidate_sha = pair[1].to_lower()
	return _check(seen.size() == 2 and original_path.begins_with(DOMAIN) and not ".." in original_path and FileAccess.file_exists(original_path) and _sha(candidate_sha), "retained original build path and explicit exact candidate SHA")

func _write(path: String, text: String) -> bool:
	if not _check(path.begins_with(fixture_root + "/") and not ".." in path, "write confined to new fixture directory"): return false
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not _check(file != null, "fixture write open: " + path): return false
	file.store_string(text)
	file.close()
	return _check(FileAccess.get_file_as_string(path) == text, "actual fixture bytes: " + path)

func _load_original_methods() -> bool:
	if not _check(FileAccess.get_sha256(original_path).to_lower() == ORIGINAL_SHA, "archived original full gate exact E29F SHA"): return false
	var text: String = FileAccess.get_file_as_string(original_path)
	var start: int = text.find("static func _append(result: Dictionary, path: String) -> bool:")
	if not _check(start >= 0 and text.count("static func _append(") == 1, "unique original append-to-EOF method block"): return false
	var methods: String = text.substr(start)
	original_methods_sha = methods.sha256_text()
	var constants := ""
	for line: String in text.split("\n"):
		if line.begins_with("const VISUAL_REVIEW := ") or line.begins_with("const TECHNICAL_REVIEW := "): constants += line + "\n"
	if not _check(constants.count("const ") == 2, "exact archived circular-approval exclusions"): return false
	original = GDScript.new()
	original.source_code = "extends RefCounted\n" + constants + methods
	return _check(original.reload() == OK, "actual archived original functions compile without replacement")

func _exercise(script: Script) -> Dictionary:
	var result: Dictionary = {}
	var leaf: String = fixture_root + "/leaf.bin"
	for iteration in 16:
		if not _check(bool(script.call("_append", result, leaf)), "actual repeated append fixture %d" % iteration): return {}
	var catalog: Dictionary = {leaf: FileAccess.get_sha256(leaf).to_lower(), fixture_root + "/graph.gd": FileAccess.get_sha256(fixture_root + "/graph.gd").to_lower()}
	if not _check(bool(script.call("_catalog", result, catalog)), "actual fixture catalog exact digests"): return {}
	if not _check(bool(script.call("_data_tree", result, fixture_root + "/data")), "actual recursive data-tree fixture"): return {}
	var visited: Dictionary = {}
	for path: String in result.keys():
		if not _check(bool(script.call("_dependency_tree", result, path, visited)), "actual literal closure with repeated references/cycle"): return {}
	_check(visited.size() == result.size(), "finite closure visits every unique fixture leaf")
	return result

func _final(result: Dictionary) -> bool:
	return bool(gate.call("_snapshot_bytes_unchanged", result))

func _fixtures() -> bool:
	fixture_root = DOMAIN + "snapshot_memo_final_sha_units_%d_%d_%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec(), OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(fixture_root)), "NEW fixture directory does not overwrite evidence"): return false
	if not _check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fixture_root + "/data/nested")) == OK, "create only independent fixture tree"): return false
	var leaf: String = fixture_root + "/leaf.bin"
	var graph: String = fixture_root + "/graph.gd"
	var cycle: String = fixture_root + "/cycle.gd"
	var graph_text: String = "# exact literal dependency fixture, not executable gameplay\n"
	for iteration in 24: graph_text += '# "%s" "%s"\n' % [leaf, cycle]
	graph_text += '# "res://data/maps/joint_world_city_v15_release_visual_review.json"\n# "res://data/maps/joint_world_city_v15_release_technical_review.json"\n'
	graph_text += '# "%s/missing.bin" "res://../forbidden.bin"\n' % fixture_root
	return _write(leaf, "immutable leaf bytes A\n") and _write(graph, graph_text) and _write(cycle, '# "%s" "%s"\n' % [graph, leaf]) and _write(fixture_root + "/data/a.tres", '# "%s"\n' % graph) and _write(fixture_root + "/data/nested/b.tres", '# "%s"\n' % leaf)

func _semantics() -> void:
	var old_result: Dictionary = _exercise(original)
	var new_result: Dictionary = _exercise(gate)
	_check(old_result.size() == 5 and new_result == old_result, "unchanged inputs: exact original fixture closure keyset AND every SHA value")
	_check(_final(new_result), "actual final full-SHA reread accepts unchanged complete fixture result")
	fixture_keys = new_result.keys()
	fixture_keys.sort()
	# Exercise every position in the complete fixture keyset, not just its first leaf.
	for path: String in fixture_keys:
		var unchanged_text: String = FileAccess.get_file_as_string(path)
		_check(_write(path, unchanged_text + "\n# controlled unique-key mutation\n"), "mutate actual bytes at each unique closure key")
		_check(not _final(new_result) and new_result == old_result, "full final reread rejects each changed key without overwriting: " + path)
		_check(_write(path, unchanged_text) and _final(new_result), "restored exact bytes pass after each unique-key negative: " + path)
	var leaf: String = fixture_root + "/leaf.bin"
	var first_sha: String = FileAccess.get_sha256(leaf).to_lower()
	var memo: Dictionary = {}
	_check(bool(gate.call("_append", memo, leaf)) and memo.get(leaf) == first_sha, "first append stores actual initial digest")
	_check(_write(leaf, "changed leaf bytes B\n"), "controlled same-path post-first-hash fixture mutation")
	var changed_sha: String = FileAccess.get_sha256(leaf).to_lower()
	_check(changed_sha != first_sha, "post-first-hash fixture actually changed bytes")
	_check(bool(gate.call("_append", memo, leaf)) and memo.get(leaf) == first_sha, "same-result memo preserves first SHA, never overwrites it")
	_check(not _final(memo) and memo.get(leaf) == first_sha, "final independent full read rejects changed bytes without replacing initial SHA")
	var next_call: Dictionary = {}
	_check(bool(gate.call("_append", next_call, leaf)) and next_call.get(leaf) == changed_sha and _final(next_call), "new result hashes current bytes: no static or cross-call cache")
	_check(_write(leaf, "immutable leaf bytes A\n") and _final(memo), "restored original fixture bytes satisfy original bound SHA")
	var catalog_result: Dictionary = {}
	_check(bool(gate.call("_catalog", catalog_result, {leaf:first_sha})), "first exact catalog accepted")
	_check(not bool(gate.call("_catalog", catalog_result, {leaf:changed_sha})) and catalog_result.get(leaf) == first_sha, "conflicting second catalog same path rejected; no digest overwrite")
	_check(bool(gate.call("_catalog", catalog_result, {leaf:first_sha})) and _final(catalog_result), "repeated matching catalog retains original exact identity")
	var dropped: String = fixture_root + "/dropped.bin"
	_check(_write(dropped, "independent removal fixture\n"), "new independent removal fixture")
	var dropped_result: Dictionary = {}
	_check(bool(gate.call("_append", dropped_result, dropped)), "removal fixture first hash")
	_check(DirAccess.remove_absolute(ProjectSettings.globalize_path(dropped)) == OK and not FileAccess.file_exists(dropped), "remove ONLY this run's own dropped.bin fixture")
	_check(not bool(gate.call("_append", dropped_result, dropped)) and not _final(dropped_result), "missing file rejected even with local memo; final reread also rejects")
	for wrong: String in ["user://outside.bin", "res://../outside.bin", fixture_root + "/absent.bin", fixture_root + "/data"]:
		var bad: Dictionary = {wrong:first_sha}
		_check(not bool(gate.call("_append", bad, wrong)), "invalid path/missing/non-file append refused: " + wrong)
		_check(not _final(bad), "invalid path/missing/non-file final reread refused: " + wrong)
	for wrong: Variant in [null, true, 7, "", "not-sha", "z".repeat(64)]:
		var bad: Dictionary = {leaf:wrong}
		_check(not bool(gate.call("_append", bad, leaf)) and not _final(bad), "memo value type/hash format remains strict")
	var wrong_digest: Dictionary = {leaf:"0".repeat(64)}
	_check(not _final(wrong_digest), "well-formed but wrong digest cannot survive final actual full SHA")
	_check(_final(new_result) and new_result == old_result, "fixture restoration leaves exact original full fixture closure unchanged")

func _run() -> void:
	if _args():
		_check(FileAccess.get_sha256(GATE_PATH).to_lower() == candidate_sha, "actual candidate gate exact explicit frozen SHA before")
		gate = load(GATE_PATH) as Script
		var ready := false
		if gate != null:
			for method: Dictionary in gate.get_script_method_list():
				if method.get("name") == "_snapshot_bytes_unchanged": ready = true
		if _check(ready and gate != null, "candidate has final reread method; old gate must not receive unit credit") and _load_original_methods() and _fixtures(): _semantics()
		_check(FileAccess.get_sha256(GATE_PATH).to_lower() == candidate_sha, "candidate source immutable after fixture unit")
		_check(FileAccess.get_sha256(original_path).to_lower() == ORIGINAL_SHA, "retained original gate immutable after fixture unit")
	var result: Dictionary = {"scope":"SMALL_FIXTURE_ACTUAL_ORIGINAL_VS_MEMO_AND_FINAL_FULL_SHA_NOT_REAL_CLOSURE_APPROVAL", "checks":checks,"failures":errors.size(),"errors":errors,"original_gate_path":original_path,"original_gate_sha256":ORIGINAL_SHA,"original_exact_method_block_sha256":original_methods_sha,"candidate_gate_sha256":candidate_sha,"fixture_root":fixture_root,"fixture_closure_keys":fixture_keys,"real_full_snapshot_executed":false,"all_real_closure_passed":false,"Field_executed":false,"publisher_executed":false,"formal_cutover":false,"player_save_writes":false}
	print("V9E_SNAPSHOT_MEMO_FINAL_SHA_RETRY1_UNITS ", JSON.stringify(result))
	quit(0 if errors.is_empty() else 1)
