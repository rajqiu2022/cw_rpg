extends "res://tests/test_luoyang_docks08_remove_two_cpu_ready_20261019aa.gd"
## AE visual delta only. No fake C owner, enabled install, Field or geometry reraster.
const AE_READY = false
const AE_FIXTURE = "PENDING_AE_INDEPENDENT_ART_SOURCE_FIXTURE"
const AE_FIXTURE_SHA = "PENDING"
const AE_API = "res://scripts/city/luoyang_docks_shore_20261020ae.gd"
const AE_CITY = &"ch4_s2_canal_docks"
const AE_C = "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const AE_PACKET = "res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/packet.bin"
const AE_PACKET_SHA = "1cb6bbf9825d538c982fcdf1171c5f3e268854be54796c3684c91502da14f221"
var ae_fixture: Dictionary = {}

func _exercise() -> bool:
	if not check(AE_READY and OS.get_cmdline_user_args().is_empty(),"AE NOTREADY until ART/import/source exact freeze; CPU source-only component"): return false
	if not track(AE_FIXTURE,AE_FIXTURE_SHA): return false
	ae_fixture = json(AE_FIXTURE)
	for path: String in ae_fixture.test_dependencies:
		if not track(path,ae_fixture.test_dependencies[path]): return false
	serial = load(SERIAL)
	var shore: Script = load(AE_API)
	var city: Script = load(AE_C)
	if not check(serial != null and serial.can_instantiate() and shore != null and shore.can_instantiate() and city != null and city.can_instantiate(),"Actual production scripts compile before API access"): return false
	var readiness: Dictionary = shore.readiness()
	if not check(readiness.get("ok") == true,"Frozen visual-only source contract",readiness): return false
	if not check(readiness.spec.geometry_unchanged == true and wire_equal(readiness.spec.overlays,ae_fixture.authored_overlays),"Independent ART-authored overlay7-key values, not observed rendered-node backfill"): return false
	for overlay: Dictionary in readiness.spec.overlays:
		if not check(overlay.size() == 7 and String(overlay.id).begins_with("shore_ae_") and not overlay.has("blocking") and not overlay.has("interaction_action") and not overlay.has("support"),"Only explicit ground visual fields, no geometry/task/support permission"): return false
	var old_map_row: Dictionary = ae_fixture.old_map
	var next_map_row: Dictionary = ae_fixture.false_map
	if not track(old_map_row.path,old_map_row.sha256) or not track(next_map_row.path,next_map_row.sha256): return false
	var old_map: Dictionary = json(old_map_row.path).source_sha256.duplicate(true)
	var expected: Dictionary = json(next_map_row.path).source_sha256.duplicate(true)
	if not check(old_map.size() == 1499 and expected.size() == next_map_row.count,"Independent formal AD1499 parent plus finite authored AE source successor"): return false
	var inverse: Dictionary = old_map.duplicate(true)
	for path: String in ae_fixture.source_delta:
		var delta: Dictionary = ae_fixture.source_delta[path]
		if not check(inverse.get(path,"ABSENT") == delta.old_sha256 and expected.get(path) == delta.new_sha256,"Explicit old/new source delta only "+path): return false
		inverse[path] = delta.new_sha256
	if not check(inverse == expected,"Complete source-map equality with no removed old source/native leaves"): return false
	for path: String in ae_fixture.immutable_native_paths:
		if not check(old_map.has(path) and old_map[path] == expected.get(path),"Original native Scene/layout/packet/walk storage bytes retained "+path): return false
		if not track(path,old_map[path]): return false
	if not track(AE_PACKET,AE_PACKET_SHA): return false
	var packet: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(AE_PACKET))
	if not check(packet.record.objects.size() == 29 and serial.ac_packet_valid(packet),"Exact original29 typed record/native storage/solids/walk packet, no new geometry credit"): return false
	var base: SceneScript = ResourceLoader.load("res://data/scenes/ch4_s2_canal_docks.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(base != null,"Original canonical scene only for one source path set, never prepare/materialize"): return false
	var actual: Dictionary = city._transition_sources(base,false)
	var missing: Array[String] = []; var extra: Array[String] = []
	for path: String in expected:
		if not actual.has(path): missing.append(path)
	for path: String in actual:
		if not expected.has(path): extra.append(path)
	if not check(actual.size() == expected.size() and missing.is_empty() and extra.is_empty(),"One Docks complete actual source path set, no other city collector",{"missing":missing,"extra":extra}): return false
	for path: String in expected:
		if not track(path,expected[path]): return false
	records.append({"kind":"AE_SOURCE_AND_IMMUTABLE29_COMPONENT_NOT_FIELD","source_count":expected.size(),"sources":expected.duplicate(true),"enabled_install_or_tree_credit":false,"geometry_rerun":false,"old_NPC_task_chain_replayed":false})
	return true

func _run() -> void:
	began = Time.get_ticks_msec()
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var saves_before: Dictionary = saves(); var state_before: Dictionary = world_state()
	var self_path: String = get_script().resource_path; sources[self_path] = fact(self_path)
	var complete: bool = _exercise()
	var after: Dictionary = {}
	for path: String in sources: after[path] = fact(path)
	var saves_after: Dictionary = saves(); var state_after: Dictionary = world_state()
	check(sources == after and saves_before == saves_after and saves_before.size() == 15 and state_before == state_after,"AE sources/state/all15save first-final preserved")
	check(Time.get_ticks_msec()-began < 60000,"Bounded60s new visual/source component, no routes/raster/Field")
	var folder: String = "res://build/luoyang_shore_market_20261020ae_qa01/cpu_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var file: FileAccess = FileAccess.open(folder.path_join("result.json"),FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope":"AE_SOURCE_VISUAL_PLAN_IMMUTABLE29_NOT_FIELD","complete":complete and failures == 0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000,"records":records,"source_before":sources,"source_after":after,"players_before":saves_before,"players_after":saves_after,"state_before":state_before,"state_after":state_after,"Field_or_new_geometry_credit":false},"\t",true,true)); file.close()
	print(JSON.stringify({"report_path":folder.path_join("result.json"),"checks":checks,"failures":failures,"complete":complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)
