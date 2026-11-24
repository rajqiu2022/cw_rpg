extends "res://tests/test_luoyang_docks08_runtime_admission_ready_retry4_20261019ab.gd"
## One AC source/native admission only. Inherited helpers; no AA exercise or geometry replay.
const AC_BIND = "res://tests/fixtures/luoyang_docks_workyard_admission_20261019ac.json"
const AC_BIND_SHA = "4a6eb0eb1ff65c21f3c803bb0bf775a152a663d101b6b72a64ddc0c69aa36285"
const AC_PATH = "res://scripts/city/luoyang_docks_workyard_20261019ac.gd"
const AC_SWITCH = "res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd"
var ac: Script
func ab_precheck(expected_phase: String) -> bool:
	if not track(AC_BIND,AC_BIND_SHA): return false
	ab = json(AC_BIND)
	if not check(ab.phase == expected_phase and ab.expected_from_actual_collector == false,"Independent ab1466 finite authored AC map, never actual collector backfill"): return false
	for path: String in ab.test_dependencies:
		if not track(path,ab.test_dependencies[path]): return false
	for path: String in ab.fixed_current_sources:
		if not track(path,ab.fixed_current_sources[path]): return false
	if not track(ab.expected_map_path,ab.expected_map_sha256) or not track(ab.stage_receipt_path,ab.stage_receipt_sha256): return false
	ab_expected = json(ab.expected_map_path).source_sha256.duplicate(true)
	if not check(ab_expected.size() == 1481,"Complete fixed candidate1481 source map"): return false
	if not track(ab.delta_cpu.path,ab.delta_cpu.sha256): return false
	var delta: Dictionary = json(ab.delta_cpu.path)
	if not check(delta.complete == true and delta.failures == 0 and delta.source_before == delta.source_after and delta.players_before.size() == 15 and delta.players_before == delta.players_after and delta.state_before == delta.state_after and delta.scope == "INDEPENDENT_ADD_FOUR_NATIVE_PACKET_LOCAL_RASTER_NOT_FIELD","Actual independent native/typed/raster AC component, not Field"): return false
	b = load(B_PATH); c = load(C_PATH); aa = load(AB_AA); ac = load(AC_PATH)
	if not check(b is GDScript and b.can_instantiate() and c is GDScript and c.can_instantiate() and aa is GDScript and aa.can_instantiate() and ac is GDScript and ac.can_instantiate(),"Actual canonical APIs compile before access"): return false
	var index: Script = load(AC_SWITCH)
	if not check(index != null and index.can_instantiate() and index.FORMAL_ENABLED == false and OS.get_cmdline_user_args() == PackedStringArray([b.AC_FLAG]),"Exactly one AC flag under false index, never formal default credit"): return false
	var self_path: String = get_script().resource_path
	return track(self_path,FileAccess.get_sha256(self_path))

func ab_describe_negatives() -> bool:
	if not check(not b.describe(AB_CITY,ab_expected).is_empty(),"B.describe admits exact independently fixed candidate map"): return false
	var missing: Dictionary = ab_expected.duplicate(true); missing.erase(AC_PATH)
	var extra: Dictionary = ab_expected.duplicate(true); extra["res://ac_unapproved_extra"] = "0".repeat(64)
	var wrong: Dictionary = ab_expected.duplicate(true); wrong[AC_PATH] = "0".repeat(64)
	return check(b.describe(AB_CITY,missing).is_empty() and b.describe(AB_CITY,extra).is_empty() and b.describe(AB_CITY,wrong).is_empty() and b.describe(&"ch4_s0_luoyang_gate",ab_expected).is_empty(),"Missing/extra/wrong SHA/wrong city all rejected")

func ab_native_inverse(data: Dictionary) -> bool:
	var fixed: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(ac.ROOT+String(AB_CITY)+"/packet.bin"))
	var parent: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes("res://data/maps/luoyang_docks_district08_20261019aa/runtime/ch4_s2_canal_docks/packet.bin"))
	if not check(b.equal(data,fixed) and b.ac_packet_valid(data) and data.record.objects.size() == 29 and data.ac_parent_record.objects.size() == 25 and data.aa_parent_record.objects.size() == 27 and data.aa_district_parent_record.objects.size() == 28,"Exact fixed1CB6 whole new29, immediate25, prior27 and originalHarbour28 distinct"): return false
	var inverse: Dictionary = data.duplicate(true)
	for key: String in ["geometry_basis","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"]: inverse[key] = parent[key]
	for key: String in ["ac_author_sha256","ac_parent_record","ac_parent_packet_sha256"]: inverse.erase(key)
	return check(b.equal(inverse,parent),"Whole typed29to25 inverse retains all existing AA/Harbour ancestry")

func ab_packet_negatives(data: Dictionary,raw: SceneScript) -> bool:
	var before: String = b.bytes_sha(var_to_bytes(data))
	for mode: String in ["ac_author","parent25","new_solid","mask_pixel"]:
		var bad: Dictionary = data.duplicate(true)
		match mode:
			"ac_author": bad["ac_author_sha256"] = "0".repeat(64)
			"parent25": bad.ac_parent_record.objects.remove_at(0)
			"new_solid": bad.record.objects[25].solid_polygons_px[0][0][0] += 1
			"mask_pixel": bad.walk_bytes[0] = 255 if bad.walk_bytes[0] == 0 else 0
		if not check(not b.ac_packet_valid(bad) and b.materialize(raw,AB_CITY,bad,ab_expected) == null,"Fixed packet hash rejects mutated clone only, no claimed deep-bypass credit "+mode): return false
		bad.clear()
	return check(before == b.bytes_sha(var_to_bytes(data)),"All negative clones leave authoritative packet unchanged")
func ab_owner_session(data: Dictionary, raw: SceneScript) -> bool:
	var original_count: int = b.session_count()
	var first: SceneScript = b.materialize(raw, AB_CITY, data, ab_expected)
	if not check(first != null and b.whole_bound(first) and aa.bound(first), "AC real canonical materialize registers own exact weak Scene/layout owner"): return false
	var first_id: int = first.get_instance_id(); var old_ref: WeakRef = weakref(first)
	if not check(b.session_count() == original_count + 1, "Exactly one own new weak session"): return false
	first = null
	if not check(old_ref.get_ref() == null, "First native Resource genuinely released before successor materialization"): return false
	# Do not call session_count here: it would prune before the production path under test.
	var second: SceneScript = b.materialize(raw, AB_CITY, data, ab_expected)
	if not check(second != null and not b._scene_sessions.has(first_id) and b._scene_sessions.size() == original_count + 1, "Materialize itself prunes dead weak session without touching its live successor"): return false
	var meta: Variant = second.get_meta(ac.META)
	second.set_meta(ac.META, "0".repeat(64))
	if not check(not b.bound(second) and not b.whole_bound(second) and not aa.bound(second), "Wrong own author metadata cannot stay bound"): return false
	second.set_meta(ac.META, meta)
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
	if not ab_precheck("AC_FLAG_FALSE_INDEX") or not ab_describe_negatives(): return false
	var raw: SceneScript = ResourceLoader.load("res://data/scenes/"+String(AB_CITY)+".tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(raw != null,"Real original canonical Scene, no fake owner"): return false
	var paths: Dictionary = c._transition_sources(raw,false)
	var missing: Array[String] = []; var extra: Array[String] = []
	for path: String in ab_expected:
		if not paths.has(path): missing.append(path)
	for path: String in paths:
		if not ab_expected.has(path): extra.append(path)
	if not check(ab_same_keys(paths,ab_expected),"Only one actual complete C Docks source collector equals independent1481",{"actual_count":paths.size(),"expected_count":ab_expected.size(),"missing":missing,"extra":extra}): return false
	for path: String in ab_expected:
		if not track(path,ab_expected[path]): return false
	records.append({"kind":"ONE_AC_DOCKS_ACTUAL_COMPLETE_SOURCE_COLLECTOR","count":paths.size(),"sources":ab_expected.duplicate(true),"other_collectors_repeated":false})
	var cancelled: Variant = b.new()
	if not check(cancelled.configure(901,AB_CITY,ab_expected),"One genuine cancelled AC job configured"): return false
	cancelled.request_cancel(); cancelled.run()
	if not check(not cancelled.mark_joined(901,AB_CITY) and cancelled.packet(901,AB_CITY).is_empty() and cancelled.error() == "Bundle packet cancelled","AC cancelled job cannot join or return data"): return false
	cancelled.release(); cancelled = null
	var job: Variant = b.new()
	if not check(job.configure(902,AB_CITY,ab_expected) and job.packet(902,AB_CITY).is_empty(),"One actual AC job, no packet before joined"): return false
	job.run()
	if not check(not job.mark_joined(903,AB_CITY) and job.mark_joined(902,AB_CITY) and job.packet(903,AB_CITY).is_empty(),"Only own token may join/read AC result"): return false
	var data: Dictionary = job.packet(902,AB_CITY)
	if not check(not data.is_empty(),"AC actual worker/native packet obtained"): return false
	if not ab_native_inverse(data) or not ab_packet_negatives(data,raw) or not ab_owner_session(data,raw): return false
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
	var folder := "res://build/luoyang_docks_workyard_20261019ac_qa01/admission_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var result := {"scope": "ONE_AC_FLAG_FALSE_INDEX_DOCKS_SOURCE_NATIVE_OWNER_ADMISSION_NOT_FIELD", "complete": complete and failures == 0, "checks": checks, "failures": failures, "elapsed_ms": Time.get_ticks_msec() - began, "limit_ms": AB_LIMIT_MS, "records": records, "source_before": source_before, "source_after": source_after, "players_before": players_before, "players_after": players_after, "state_before": state_before, "state_after": state_after, "Field_credit": false, "Physics_credit": false, "formal_default_credit": false, "geometry_rerun": false}
	var file := FileAccess.open(folder.path_join("result.json"), FileAccess.WRITE)
	if file == null: failures += 1
	else: file.store_string(JSON.stringify(result, "\t", true, true)); file.close()
	print(JSON.stringify({"report_path": folder.path_join("result.json"), "checks": checks, "failures": failures, "complete": complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)


