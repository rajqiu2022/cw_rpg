extends "res://tests/test_luoyang_culture_source_admission_draft_20261019x.gd"
## Thin no-args false-index component: path-set/describe, no C collector/packet/Field.
const AB_FALLBACK_READY := true
const AB_FALLBACK_BIND := "res://tests/fixtures/luoyang_docks08_fallback_20261019ab.json"
const AB_FALLBACK_BIND_SHA := "f2e0f3d300cfb7097adb19e836647386e94ffbcf52cf43b9cfd07539bd7d52c0"
const AB_FALLBACK_LIMIT_MS := 15000
const AB_FALLBACK_CITY := &"ch4_s2_canal_docks"
const AB_FALLBACK_AA := "res://scripts/city/luoyang_docks_district08_20261019aa.gd"

func check(value: bool, label: String, detail: Variant = null) -> bool:
	checks += 1
	if not value:
		failures += 1
		printerr("DOCKS_AB_FALLBACK_FAIL ", label, " ", detail)
	return value
func ab_fallback_state() -> Dictionary:
	return {"flags": root.get_node("GameState").get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict").duplicate(true), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true), "gold": root.get_node("GameState").get("gold")}
func exercise() -> bool:
	if not check(AB_FALLBACK_READY and OS.get_cmdline_user_args().is_empty(), "Frozen no-args fallback only; no AA flag or formal default credit"): return false
	if not track(AB_FALLBACK_BIND, AB_FALLBACK_BIND_SHA): return false
	var binding := json(AB_FALLBACK_BIND)
	if not check(binding.get("phase") == "FALLBACK_FALSE_NO_ARGS" and binding.get("expected_from_actual_collector") == false, "Independent old-plus-explicit-delta fallback map"): return false
	for path: String in binding.get("test_dependencies", {}):
		if not track(path, binding.test_dependencies[path]): return false
	for path: String in binding.get("fixed_current_sources", {}):
		if not track(path, binding.fixed_current_sources[path]): return false
	if not track(binding.expected_map_path, binding.expected_map_sha256): return false
	var expected: Dictionary = json(binding.expected_map_path).get("source_sha256", {}).duplicate(true)
	if not check(not expected.is_empty() and expected.size() == binding.expected_source_count, "Exact independently frozen fallback source count"): return false
	b = load(B_PATH)
	var aa: Script = load(AB_FALLBACK_AA)
	if not check(b is GDScript and b.can_instantiate() and aa is GDScript and aa.can_instantiate() and not aa.enabled() and b.requested(AB_FALLBACK_CITY), "Bound AA false-index, ordinary original bundle fallback still enabled"): return false
	var paths: Dictionary = b.source_paths(AB_FALLBACK_CITY)
	if not check(paths.size() == expected.size(), "Actual B fallback path-set has exact independent cardinality"): return false
	for path: String in expected:
		if not check(paths.has(path), "Each independent fallback path exists exactly " + path): return false
	if not check(not b.describe(AB_FALLBACK_CITY, expected).is_empty(), "Actual ordinary fallback describe accepts the fixed complete map"): return false
	var missing := expected.duplicate(true); missing.erase(aa.INDEX)
	var extra := expected.duplicate(true); extra["res://unapproved_ab_fallback.txt"] = "0".repeat(64)
	var wrong := expected.duplicate(true); wrong[aa.INDEX] = "0".repeat(64)
	if not check(b.describe(AB_FALLBACK_CITY, missing).is_empty() and b.describe(AB_FALLBACK_CITY, extra).is_empty() and b.describe(AB_FALLBACK_CITY, wrong).is_empty(), "Fallback rejects missing/extra/wrong AA-authority leaf without file edits"): return false
	var config: Dictionary = b.manifest(AB_FALLBACK_CITY)
	if not check(config.get("geometry_proof_basis") == b.UNCHANGED_BASIS and b._root(AB_FALLBACK_CITY) == b.ROOT and not config.legacy_source_sha256.has(aa.INDEX) and not config.runtime_authority_sha256.has(aa.INDEX), "Fallback remains original native root/basis; AA-index remains external to manifest hash domain"): return false
	records.append({"kind": "NOARGS_FALSE_FALLBACK_PATHSET_DESCRIBE_ONLY", "source_count": paths.size(), "C_collector_run": false, "full_source_hash_sweep": false, "packet_read": false, "Field": false})
	var self_path: String = get_script().resource_path
	return track(self_path, FileAccess.get_sha256(self_path))
func _run() -> void:
	began = Time.get_ticks_msec()
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves(); var state_before := ab_fallback_state()
	var complete := exercise()
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after := saves(); var state_after := ab_fallback_state()
	if not check(source_before == source_after and players_before == players_after and players_before.size() == 15 and state_before == state_after, "Finite fixed sources and fifteen save/state facts unchanged"): complete = false
	if not check(Time.get_ticks_msec() - began < AB_FALLBACK_LIMIT_MS, "Fixed15s thin fallback component, no collector or native replay"): complete = false
	var folder := "res://build/luoyang_docks08_fallback_source_20261019ab/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var result := {"scope": "NOARGS_FALSE_INDEX_FALLBACK_PATHSET_DESCRIBE_ONLY_NOT_FULL_COLLECTOR", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "limit_ms": AB_FALLBACK_LIMIT_MS, "records": records, "source_before": source_before, "source_after": source_after, "players_before": players_before, "players_after": players_after, "state_before": state_before, "state_after": state_after, "full_collector_credit": false, "Field_credit": false, "formal_AA_default_credit": false}
	var file := FileAccess.open(folder.path_join("result.json"), FileAccess.WRITE)
	if file == null: failures += 1
	else: file.store_string(JSON.stringify(result, "\t", true, true)); file.close()
	print(JSON.stringify({"report_path": folder.path_join("result.json"), "checks": checks, "failures": failures, "complete": complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
