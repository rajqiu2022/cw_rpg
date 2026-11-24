extends "res://tests/test_luoyang_culture_source_admission_draft_20261019x.gd"
## One canonical Docks source/admission atom. No Field, raster, route or old suite replay.
const AB_READY := true
const AB_BINDING := "res://tests/fixtures/luoyang_docks08_admission_retry2_20261019ab.json"
const AB_BINDING_SHA := "8d75c7954a6b8da8df01f032b5eb913683f63b54e48ed1358109e427820a3b01"
const AB_LIMIT_MS := 60000
const AB_CITY := &"ch4_s2_canal_docks"
const AB_AA := "res://scripts/city/luoyang_docks_district08_20261019aa.gd"
var ab: Dictionary = {}
var aa: Script
var ab_expected: Dictionary = {}

func check(value: bool, label: String, detail: Variant = null) -> bool:
	checks += 1
	if not value:
		failures += 1
		printerr("DOCKS_AB_ADMISSION_FAIL ", label, " ", detail)
	return value
func ab_state() -> Dictionary:
	return {"flags": root.get_node("GameState").get("flags").duplicate(true), "quests": root.get_node("QuestManager").call("to_dict").duplicate(true), "inventory": root.get_node("Inventory").call("to_dict").duplicate(true), "gold": root.get_node("GameState").get("gold")}
func ab_same_keys(left: Dictionary, right: Dictionary) -> bool:
	if left.size() != right.size(): return false
	for path: Variant in left:
		if not right.has(path): return false
	return true
func ab_precheck(expected_phase: String) -> bool:
	if not check(AB_READY, "NOTREADY until canonical deployment and independent three-phase source maps freeze"): return false
	if not track(AB_BINDING, AB_BINDING_SHA): return false
	ab = json(AB_BINDING)
	if not check(ab.get("phase") == expected_phase and ab.get("expected_from_actual_collector") == false, "Independent old-source-plus-finite-delta authority, never actual output backfill"): return false
	for path: String in ab.get("test_dependencies", {}):
		if not track(path, ab.test_dependencies[path]): return false
	for path: String in ab.get("fixed_current_sources", {}):
		if not track(path, ab.fixed_current_sources[path]): return false
	if not track(ab.expected_map_path, ab.expected_map_sha256): return false
	var map := json(ab.expected_map_path)
	ab_expected = map.get("source_sha256", {}).duplicate(true)
	if not check(not ab_expected.is_empty() and ab_expected.size() == ab.expected_source_count, "Exact independently fixed Docks complete source cardinality"): return false
	b = load(B_PATH); c = load(C_PATH); aa = load(AB_AA)
	if not check(b is GDScript and b.can_instantiate() and c is GDScript and c.can_instantiate() and aa is GDScript and aa.can_instantiate(), "Canonical production APIs compile, no candidate-path owner bypass"): return false
	var self_path: String = get_script().resource_path
	return track(self_path, FileAccess.get_sha256(self_path))

func ab_describe_negatives() -> bool:
	if not check(not b.describe(AB_CITY, ab_expected).is_empty(), "Actual B.describe accepts only the independently frozen whole set"): return false
	var missing := ab_expected.duplicate(true); missing.erase(AB_AA)
	var extra := ab_expected.duplicate(true); extra["res://ab_unapproved_extra.txt"] = "0".repeat(64)
	var wrong := ab_expected.duplicate(true); wrong[AB_AA] = "0".repeat(64)
	if not check(b.describe(AB_CITY, missing).is_empty() and b.describe(AB_CITY, extra).is_empty() and b.describe(AB_CITY, wrong).is_empty(), "Missing/extra/wrong-SHA source maps all rejected without editing files"): return false
	return check(b.describe(&"ch4_s0_luoyang_gate", ab_expected).is_empty(), "AA Docks whole map cannot authorize a different city")

func ab_packet_negatives(data: Dictionary, raw: SceneScript) -> bool:
	if not check(b.aa_packet_valid(data), "Unmodified exact CPU69DA packet passes production whole typed inverse boundary"): return false
	var before_sha: String = b.bytes_sha(var_to_bytes(data))
	for mode: String in ["author", "parent27", "parent28", "mask_pixel"]:
		var bad := data.duplicate(true)
		match mode:
			"author": bad["aa_author_sha256"] = "0".repeat(64)
			"parent27": bad.aa_parent_record.objects.remove_at(0)
			"parent28": bad.aa_district_parent_record.objects.remove_at(0)
			"mask_pixel": bad.walk_bytes[0] = 255 if bad.walk_bytes[0] == 0 else 0
		if not check(not b.aa_packet_valid(bad) and b.materialize(raw, AB_CITY, bad, ab_expected) == null, "Changed packet clone rejected by fixed-byte hash boundary: " + mode): return false
		bad.clear()
	if not check(b.bytes_sha(var_to_bytes(data)) == before_sha, "Negative clones leave exact valid packet bytes unchanged"): return false
	records.append({"kind": "FIXED_PACKET_HASH_MUTATION_REJECTIONS_ONLY", "cases": ["author", "parent27", "parent28", "mask_pixel"], "claims_deep_guard_bypassed_hash": false})
	return true

func ab_native_inverse(data: Dictionary) -> bool:
	var author: Dictionary = aa.author()
	var old: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(author.parent_bundle_root + "packet.bin"))
	var spacing := json(author.old_spacing_manifest)
	if not check(old.record.objects.size() == 27 and data.record.objects.size() == 25 and data.aa_district_parent_record.objects.size() == 28, "Effective parent27 versus original Harbour28 are not conflated"): return false
	if not check(b.equal(data.aa_parent_record, old.record) and b.equal(b._wire(data.aa_district_parent_record), b._wire(spacing.parent_record)), "Both actual immutable complete parent record authorities exact"): return false
	var wanted: Dictionary = old.record.duplicate(true); var retained: Array = []
	for row: Dictionary in old.record.objects:
		if String(row.id) not in ["harbour_small_cargo_store", "south_canal_front"]: retained.append(row.duplicate(true))
	wanted.objects = retained; wanted.walk_path = aa.ROOT + String(AB_CITY) + "/walk.png"
	wanted["aa_geometry_basis"] = aa.BASIS; wanted["aa_author_sha256"] = aa.AUTHOR_SHA
	if not check(b.equal(wanted, data.record), "Independent exact full old-plus-two-removals record, not same-count acceptance"): return false
	var inverse := data.duplicate(true)
	for key: String in ["geometry_basis", "record", "solids", "walk_bytes", "mask_sha", "scene_storage", "layout_storage"]: inverse[key] = old[key]
	for key: String in ["aa_author_sha256", "aa_parent_record", "aa_district_parent_record", "aa_parent_packet_sha256"]: inverse.erase(key)
	return check(b.equal(inverse, old), "Whole typed packet inverse; every unrelated value remains exact")

func ab_owner_session(data: Dictionary, raw: SceneScript) -> bool:
	var original_count: int = b.session_count()
	var first: SceneScript = b.materialize(raw, AB_CITY, data, ab_expected)
	if not check(first != null and b.whole_bound(first) and aa.bound(first), "Real canonical materialize registers its own exact weak Scene/layout owner"): return false
	var first_id: int = first.get_instance_id(); var old_ref: WeakRef = weakref(first)
	if not check(b.session_count() == original_count + 1, "Exactly one own new weak session"): return false
	first = null
	if not check(old_ref.get_ref() == null, "First native Resource genuinely released before successor materialization"): return false
	# Do not call session_count here: it would prune before the production path under test.
	var second: SceneScript = b.materialize(raw, AB_CITY, data, ab_expected)
	if not check(second != null and not b._scene_sessions.has(first_id) and b._scene_sessions.size() == original_count + 1, "Materialize itself prunes dead weak session without touching its live successor"): return false
	var meta: Variant = second.get_meta(aa.META)
	second.set_meta(aa.META, "0".repeat(64))
	if not check(not b.bound(second) and not b.whole_bound(second) and not aa.bound(second), "Wrong own author metadata cannot stay bound"): return false
	second.set_meta(aa.META, meta)
	var layout: WalkableMapLayout = second.map_layout
	second.map_layout = layout.duplicate(true) as WalkableMapLayout
	if not check(not b.bound(second) and not b.whole_bound(second), "Equal-looking different layout instance fails weak ownership"): return false
	second.map_layout = layout
	second.set_meta(&"ab_unapproved_extra", true)
	if not check(not b.whole_bound(second), "Extra stored metadata fails the whole storage graph, no ignored-key allowance"): return false
	second.remove_meta(&"ab_unapproved_extra")
	if not check(b.whole_bound(second), "Restored exact native owner remains valid after negative clones"): return false
	var result_ref: WeakRef = weakref(second)
	second = null; layout = null
	if not check(result_ref.get_ref() == null and b.prune_sessions() == 1 and b.session_count() == original_count, "Own final weak session drains with no retained packet owner"): return false
	records.append({"kind": "NATIVE_WEAK_SESSION_OWNERSHIP_NOT_FIELD", "prior_count": original_count, "final_count": b.session_count(), "first_id": first_id})
	return true

func exercise() -> bool:
	if not ab_precheck("AA_FLAG_FALSE_INDEX"): return false
	if not check(OS.get_cmdline_user_args() == PackedStringArray([aa.FLAG]) and aa.enabled(), "Exactly one AA flag under frozen false-index authority, not formal default credit"): return false
	if not ab_describe_negatives(): return false
	var raw: SceneScript = ResourceLoader.load("res://data/scenes/" + String(AB_CITY) + ".tres", "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(raw != null, "Actual canonical original Scene resource, no fake owner or Field setup"): return false
	var current_paths: Dictionary = c._transition_sources(raw, false)
	var missing_paths: Array[String] = []; var extra_paths: Array[String] = []
	for path: String in ab_expected:
		if not current_paths.has(path): missing_paths.append(path)
	for path: String in current_paths:
		if not ab_expected.has(path): extra_paths.append(path)
	missing_paths.sort(); extra_paths.sort()
	if not check(ab_same_keys(current_paths, ab_expected), "Only this one actual Docks complete collector equals independent source set", {"actual_count": current_paths.size(), "expected_count": ab_expected.size(), "missing": missing_paths, "extra": extra_paths}): return false
	for path: String in ab_expected:
		if not track(path, ab_expected[path]): return false
	records.append({"kind": "ONE_DOCKS_ACTUAL_COMPLETE_SOURCE_COLLECTOR", "count": current_paths.size(), "sources": ab_expected.duplicate(true), "other_three_collectors_rerun": false})
	var bad_owner: Variant = b.new()
	if not check(not bad_owner.configure(0, AB_CITY, ab_expected), "Zero token cannot configure canonical job"): return false
	bad_owner.release(); bad_owner = null
	var cancelled: Variant = b.new()
	if not check(cancelled.configure(801, AB_CITY, ab_expected), "Own cancelled-attempt legitimate canonical configure"): return false
	cancelled.request_cancel(); cancelled.run()
	if not check(not cancelled.mark_joined(801, AB_CITY) and cancelled.packet(801, AB_CITY).is_empty() and cancelled.error() == "Bundle packet cancelled", "Cancelled job never exposes packet/joins or contaminates a future job"): return false
	cancelled.release(); cancelled = null
	var job: Variant = b.new()
	if not check(job.configure(802, AB_CITY, ab_expected) and not job.configure(803, AB_CITY, ab_expected) and job.packet(802, AB_CITY).is_empty(), "One immutable job configure and no packet before join"): return false
	job.run()
	if not check(not job.mark_joined(803, AB_CITY) and job.mark_joined(802, AB_CITY) and job.packet(803, AB_CITY).is_empty() and job.packet(802, &"ch4_s0_luoyang_gate").is_empty(), "Only exact token and city may read a joined successful job"): return false
	var data: Dictionary = job.packet(802, AB_CITY)
	if not check(not data.is_empty(), "Actual new AA packet read/join succeeded"): return false
	if not ab_native_inverse(data) or not ab_packet_negatives(data, raw) or not ab_owner_session(data, raw): return false
	job.release(); job = null; data.clear(); raw = null
	return true

func _run() -> void:
	began = Time.get_ticks_msec()
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true)
	players_before = saves(); var state_before := ab_state()
	var complete := exercise()
	var source_after: Dictionary = {}
	for path: String in source_before: source_after[path] = fact(path)
	var players_after := saves(); var state_after := ab_state()
	if not check(source_before == source_after and players_before == players_after and players_before.size() == 15 and state_before == state_after, "Complete finite source/save/state first-final equality; no slot writes"): complete = false
	if not check(Time.get_ticks_msec() - began < AB_LIMIT_MS, "Fixed60s one-Docks source/admission atom, no geometry replay"): complete = false
	var folder := "res://build/luoyang_docks08_runtime_admission_20261019ab/%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var result := {"scope": "ONE_AA_FLAG_FALSE_INDEX_DOCKS_SOURCE_NATIVE_OWNER_ADMISSION_NOT_FIELD", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "limit_ms": AB_LIMIT_MS, "records": records, "source_before": source_before, "source_after": source_after, "players_before": players_before, "players_after": players_after, "state_before": state_before, "state_after": state_after, "Field_credit": false, "Physics_credit": false, "formal_default_credit": false, "geometry_rerun": false}
	var file := FileAccess.open(folder.path_join("result.json"), FileAccess.WRITE)
	if file == null: failures += 1
	else: file.store_string(JSON.stringify(result, "\t", true, true)); file.close()
	print(JSON.stringify({"report_path": folder.path_join("result.json"), "checks": checks, "failures": failures, "complete": complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
