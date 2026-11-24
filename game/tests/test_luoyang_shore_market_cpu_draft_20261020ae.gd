extends "res://tests/test_luoyang_docks08_remove_two_cpu_ready_20261019aa.gd"
## AE one bounded dual-domain CPU. No Field/owner bypass/old raster or NPC suite.
const AE_DUAL_READY = false
const AE_DUAL_BIND = "PENDING_AE_DUAL_CPU_FIXTURE"
const AE_DUAL_BIND_SHA = "PENDING"
const AE_C = "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const AE_SHORE = "res://scripts/city/luoyang_docks_shore_20261020ae.gd"
const AE_MARKET = "res://scripts/city/luoyang_market_ground_20261020ae.gd"
const AE_DOCKS_ID = "ch4_s2_canal_docks"
const AE_MARKET_ID = "ch4_s3_luoyang_market"
var ae_fixture: Dictionary = {}
var ae_city: Script

func ae_import_evidence() -> bool:
	if not check(ae_fixture.import_proofs.size() == 2 and ae_fixture.selected_new_texture_paths.size() == 4,"Two distinct actual cohorts: original3 once, authorized wet1 once; never pretend single4PNG import"): return false
	var seen: Dictionary = {}
	var cohort_sizes: Array[int] = []
	for proof_row: Dictionary in ae_fixture.import_proofs:
		if not track(proof_row.path,proof_row.sha256): return false
		var report: Dictionary = json(proof_row.path)
		if not check(report.scope == proof_row.scope and report.passed == true and report.failures.is_empty() and report.rows.size() == proof_row.texture_paths.size() and report.source_first == report.source_final,"One pinned real import cohort; first-final protected, not composite invented actual"): return false
		cohort_sizes.append(report.rows.size())
		var local_seen: Dictionary = {}
		for row: Dictionary in report.rows:
			if not check(proof_row.texture_paths.has(row.texture) and ae_fixture.selected_new_texture_paths.has(row.texture) and not seen.has(row.texture) and not local_seen.has(row.texture),"Exact Root-approved disjoint texture cohorts; excluded stone-strip wet candidate cannot enter"): return false
			seen[row.texture] = true; local_seen[row.texture] = true
			var expected: Dictionary = ae_fixture.texture_proofs[row.texture]
			if not check(row.source_sha256 == expected.source_sha256 and row.rgba_sha256 == expected.rgba_sha256 and wire_equal(row.size,expected.size) and row.visual_kind == expected.visual_kind and row.compiled_path == expected.compiled_path and row.full_rgba_exact == true and row.params23 == true and row.zero_mipmaps == true and row.detect3d_compress_to == 0,"Pinned actual fullRGBA/23/mip0/detect0 and exact remap "+row.texture): return false
			if not check(report.source_first.get(row.texture) == row.source_sha256 and report.source_first.get(row.import_path) == row.import_sha256 and report.source_first.get(row.compiled_path) == row.compiled_sha256,"Each real row triple belongs to its own actual first-final snapshot"): return false
			if not track(row.texture,row.source_sha256) or not track(row.import_path,row.import_sha256) or not track(row.compiled_path,row.compiled_sha256): return false
		if not check(local_seen.size() == proof_row.texture_paths.size(),"Complete individual actual cohort, no duplicate rows"): return false
		records.append({"kind":"AE_INDIVIDUAL_IMPORT_COHORT_EVIDENCE","report_path":proof_row.path,"report_sha256":proof_row.sha256,"texture_paths":proof_row.texture_paths.duplicate(),"checks":report.checks,"elapsed_ms":report.elapsed_ms,"import_replayed":false})
	cohort_sizes.sort()
	return check(cohort_sizes.size() == 2 and cohort_sizes[0] == 1 and cohort_sizes[1] == 3 and seen.size() == ae_fixture.selected_new_texture_paths.size(),"Original3 plus wet1 honest union only, not art/Field credit")

func ae_domain(id: String,api_path: String) -> bool:
	var domain: Dictionary = ae_fixture.domains[id]
	var api: Script = load(api_path)
	if not check(api != null and api.can_instantiate(),"Actual new visual module compiles "+id): return false
	var ready: Dictionary = api.readiness()
	if not check(ready.get("ok") == true and ready.spec.geometry_unchanged == true and wire_equal(ready.spec.overlays,domain.authored_overlays),"Independent ART exact7-key overlay list "+id,ready.get("error","")): return false
	for overlay: Dictionary in ready.spec.overlays:
		if not check(overlay.size() == 7 and not overlay.has("blocking") and not overlay.has("interaction_action") and not overlay.has("support"),"Only explicit visual plan; no physics/task/support authorization"): return false
		if id == AE_MARKET_ID:
			var rect: Rect2 = Rect2(vec(overlay.center_px)-vec(overlay.render_size_px)*.5,vec(overlay.render_size_px))
			var texture_proof: Dictionary = ready.spec.textures[overlay.texture]
			if not check(Rect2(1050,1012,960,368).encloses(rect) and vec(overlay.region_origin_px) == Vector2.ZERO and vec(overlay.region_size_px) == vec(texture_proof.size_px),"Market first-cluster complete wholePNG only, not unsupported Field atlas crop"): return false
	if not track(domain.old_map.path,domain.old_map.sha256) or not track(domain.false_map.path,domain.false_map.sha256): return false
	var original: Dictionary = json(domain.old_map.path).source_sha256.duplicate(true)
	var expected: Dictionary = json(domain.false_map.path).source_sha256.duplicate(true)
	var old_count: int = 1499 if id == AE_DOCKS_ID else 1242
	if not check(original.size() == old_count and expected.size() == domain.false_map.count,"Independent frozen parent source count "+id): return false
	var inverse: Dictionary = original.duplicate(true)
	for path: String in domain.source_delta:
		var delta: Dictionary = domain.source_delta[path]
		if not check(inverse.get(path,"ABSENT") == delta.old_sha256 and expected.get(path) == delta.new_sha256,"Explicit finite source successor "+path): return false
		inverse[path] = delta.new_sha256
	if not check(inverse == expected,"Whole parent+finite delta source equality, no actual backfill "+id): return false
	for path: String in domain.immutable_native_paths:
		if not check(original.has(path) and original[path] == expected.get(path),"Original Scene/layout/packet/walk immutable bytes "+path): return false
		if not track(path,original[path]): return false
	if not track(domain.packet.path,domain.packet.sha256): return false
	var packet: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(domain.packet.path))
	if not check(packet.record.objects.size() == (29 if id == AE_DOCKS_ID else 24),"Original typed record count only, no geometry reraster "+id): return false
	if id == AE_DOCKS_ID and not check(serial.ac_packet_valid(packet),"Exact existing29 full typed ancestry/packet valid"): return false
	var source_scene: SceneScript = ResourceLoader.load("res://data/scenes/"+id+".tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(source_scene != null,"Canonical source path input only, not C prepare "+id): return false
	var actual: Dictionary = ae_city._transition_sources(source_scene,false)
	var missing: Array[String] = []; var extra: Array[String] = []
	for path: String in expected:
		if not actual.has(path): missing.append(path)
	for path: String in actual:
		if not expected.has(path): extra.append(path)
	if not check(actual.size() == expected.size() and missing.is_empty() and extra.is_empty(),"One actual path set per authorized domain only "+id,{"actual_count":actual.size(),"missing":missing,"extra":extra}): return false
	for path: String in expected:
		if not track(path,expected[path]): return false
	records.append({"kind":"AE_EXACT_SOURCE_IMMUTABLE_NATIVE_COMPONENT","scene_id":id,"source_count":expected.size(),"sources":expected.duplicate(true),"native_object_count":packet.record.objects.size(),"enabled_install_Field_or_geometry_credit":false})
	return true

func ae_market_old36() -> bool:
	var row: Dictionary = ae_fixture.market_old36
	for source: Dictionary in [row.native_scene,row.district_author,row.t_author]:
		if not track(source.path,source.sha256): return false
	var native: SceneScript = ResourceLoader.load(row.native_scene.path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var district: Script = load("res://scripts/city/luoyang_district_life_20261016f.gd")
	var transform: Script = load("res://build/luoyang_layout_quest_20261018t_layout_source01/layout_transform_retry2.gd")
	if not check(native != null and native.map_layout.visual_objects.size() == 24 and district != null and district.can_instantiate() and transform != null and transform.can_instantiate(),"Frozen native24 and original pure DG/T scripts"): return false
	var projection: Dictionary = transform.district_projection(district.G.project(json(row.district_author.path),StringName(AE_MARKET_ID)),StringName(AE_MARKET_ID),json(row.t_author.path))
	if not check(not projection.is_empty() and projection.replacements.size() == 1 and projection.additions.size() == 12 and projection.spec.crowd.size() == 10,"13 placements means1replace+12adds; crowd10 is distinct"): return false
	var old36: Array = district.G.apply_render(native.map_layout.visual_objects,projection)
	if not check(old36.size() == 36,"Independent old36 render/navigation plan only, no fake prepared owner"): return false
	records.append({"kind":"AE_MARKET_INDEPENDENT_OLD36_VALUE_PLAN_NOT_FIELD","native_count":24,"replacement_count":1,"additions":12,"crowd_count":10,"prefix36":old36,"actual_prepared_session_credit":false})
	return true

func _exercise() -> bool:
	if not check(AE_DUAL_READY and OS.get_cmdline_user_args().is_empty(),"AE dual CPU NOTREADY until exact ART/import/source freeze"): return false
	if not track(AE_DUAL_BIND,AE_DUAL_BIND_SHA): return false
	ae_fixture = json(AE_DUAL_BIND)
	for path: String in ae_fixture.test_dependencies:
		if not track(path,ae_fixture.test_dependencies[path]): return false
	serial = load(SERIAL); ae_city = load(AE_C)
	if not check(serial != null and serial.can_instantiate() and ae_city != null and ae_city.can_instantiate(),"Real base APIs compile before access"): return false
	return ae_import_evidence() and ae_domain(AE_DOCKS_ID,AE_SHORE) and ae_domain(AE_MARKET_ID,AE_MARKET) and ae_market_old36()

func _run() -> void:
	began = Time.get_ticks_msec(); root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var saves_before: Dictionary = saves(); var state_before: Dictionary = world_state()
	var self_path: String = get_script().resource_path; sources[self_path] = fact(self_path)
	var complete: bool = _exercise()
	var after: Dictionary = {}
	for path: String in sources: after[path] = fact(path)
	var saved: Dictionary = saves(); var state_after: Dictionary = world_state()
	check(sources == after and saves_before == saved and saved.size() == 15 and state_before == state_after,"Dual CPU complete sources/state/15save first-final unchanged")
	check(Time.get_ticks_msec()-began < 60000,"Original bounded60s two source components, no four-city/raster/Field suite")
	var folder: String = "res://build/luoyang_shore_market_20261020ae_qa01/cpu_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var file: FileAccess = FileAccess.open(folder.path_join("result.json"),FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope":"AE_DOCKS_MARKET_VISUAL_SOURCE_IMMUTABLE_NATIVE_NOT_FIELD","complete":complete and failures == 0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000,"records":records,"source_before":sources,"source_after":after,"players_before":saves_before,"players_after":saved,"state_before":state_before,"state_after":state_after,"Field_or_geometry_or_old_NPC_credit":false},"\t",true,true)); file.close()
	print(JSON.stringify({"report_path":folder.path_join("result.json"),"checks":checks,"failures":failures,"complete":complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
