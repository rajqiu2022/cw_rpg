extends "res://tests/test_luoyang_shore_market_cpu_ready_20261020ae.gd"
## Residual source/native components only. Prior import component is inherited
## explicitly from an unchanged whole-FAIL report, never relabelled whole PASS.
const AE_RESIDUAL_READY = true
const AE_RESIDUAL_BIND = "res://tests/fixtures/luoyang_shore_market_cpu_residual_ready_20261020ae.json"
const AE_RESIDUAL_BIND_SHA = "f4da17795de0f2d9c6cc5d790c0d5b67e24b823896ad557f08b5f57f7b9f4830"

func ae_import_evidence() -> bool:
	var prior: Dictionary = ae_fixture.prior_failed_import_component
	if not track(prior.report_path,prior.report_sha256) or not track(prior.stderr_path,prior.stderr_sha256): return false
	var report: Dictionary = json(prior.report_path)
	if not check(report.scope == "AE_DOCKS_MARKET_VISUAL_SOURCE_IMMUTABLE_NATIVE_NOT_FIELD" and report.complete == false and report.checks == 96 and report.failures == 1 and report.records.size() == 2 and report.source_before == report.source_after and report.players_before.size() == 15 and report.players_before == report.players_after and report.state_before == report.state_after,"Preserved118004 original wholeFAIL; import components only inherited, not wholePASS"): return false
	var error: String = FileAccess.get_file_as_string(prior.stderr_path).strip_edges()
	if not check(error == "DOCKS_AA_QA_FAIL Exact existing29 full typed ancestry/packet valid <null>","Original single actual failure was AC author/packet guard before source components"): return false
	if not check(ae_fixture.import_proofs.size() == 2,"Exactly two original actual import cohorts, no new decoding/import round"): return false
	for index: int in 2:
		var cohort: Dictionary = report.records[index]
		var expected: Dictionary = ae_fixture.import_proofs[index]
		if not track(expected.path,expected.sha256): return false
		if not check(cohort.kind == "AE_INDIVIDUAL_IMPORT_COHORT_EVIDENCE" and cohort.report_path == expected.path and cohort.report_sha256 == expected.sha256 and wire_equal(cohort.texture_paths,expected.texture_paths) and cohort.import_replayed == false and cohort.checks == (153 if index == 0 else 59) and cohort.elapsed_ms == (207 if index == 0 else 86),"Exact prior3+1 actual evidence retained without rerun "+str(index)): return false
		records.append({"kind":"AE_PRIOR_IMPORT_COMPONENT_ONLY_NOT_RERUN","original_whole_FAIL_path":prior.report_path,"original_whole_complete":false,"actual_import_cohort":cohort.duplicate(true),"new_import_or_texture_decode":false})
	return true

func _exercise() -> bool:
	if not check(AE_RESIDUAL_READY and OS.get_cmdline_user_args().is_empty(),"AE residual source/native only, no candidate or owner bypass"): return false
	if not track(AE_RESIDUAL_BIND,AE_RESIDUAL_BIND_SHA): return false
	ae_fixture = json(AE_RESIDUAL_BIND)
	for path: String in ae_fixture.test_dependencies:
		if not track(path,ae_fixture.test_dependencies[path]): return false
	serial = load(SERIAL); ae_city = load(AE_C)
	if not check(serial != null and serial.can_instantiate() and ae_city != null and ae_city.can_instantiate(),"Actual APIs compile before guarded use"): return false
	return ae_import_evidence() and ae_domain(AE_DOCKS_ID,AE_SHORE) and ae_domain(AE_MARKET_ID,AE_MARKET) and ae_market_old36()

func _run() -> void:
	began = Time.get_ticks_msec(); root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var saves_before: Dictionary = saves(); var state_before: Dictionary = world_state()
	var self_path: String = get_script().resource_path; sources[self_path] = fact(self_path)
	var complete: bool = _exercise()
	var after: Dictionary = {}
	for path: String in sources: after[path] = fact(path)
	var saved: Dictionary = saves(); var state_after: Dictionary = world_state()
	check(sources == after and saves_before == saved and saved.size() == 15 and state_before == state_after,"Residual complete sources/state/15save first-final unchanged")
	check(Time.get_ticks_msec()-began < 60000,"Original60s, only two uncompleted source components/native/old36, no raster or Field")
	var folder: String = "res://build/luoyang_shore_market_20261020ae_qa01/cpu_residual_%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(folder)
	var path: String = folder.path_join("result.json")
	var file: FileAccess = null
	if check(not FileAccess.file_exists(path),"Never overwrite residual report on PID reuse"): file = FileAccess.open(path,FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"scope":"AE_RESIDUAL_TWO_DOMAIN_SOURCE_NATIVE_MARKET36_PRIOR_IMPORT_COMPONENT_ONLY_NOT_FIELD","complete":complete and failures == 0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":60000,"records":records,"source_before":sources,"source_after":after,"players_before":saves_before,"players_after":saved,"state_before":state_before,"state_after":state_after,"original118004_whole_FAIL_preserved":true,"import_texture_raster_Field_replayed":false},"\t",true,true)); file.close()
	print(JSON.stringify({"report_path":path,"checks":checks,"failures":failures,"complete":complete and failures == 0}))
	quit(0 if complete and failures == 0 else 1)

