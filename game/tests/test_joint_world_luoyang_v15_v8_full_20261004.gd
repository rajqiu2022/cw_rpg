extends SceneTree
## NEW fixed wall_street candidate sibling; original predicates remain unchanged.
## NEW V8 FULL prepared source only; final artifact pins are PENDING, never old results.
const V8_ENTRY_ORIGIN_PATH: String = "res://tests/test_joint_world_luoyang_v15_wall_street_20261004.gd"
const V8_ENTRY_ORIGIN_SHA: String = "59a31a8c52d197be9233785bea018cbf278427f62c3b0788b6d5c6c1733ef12b"
const SNAPSHOT_ORIGIN_PATH: String = "res://tests/test_joint_world_luoyang_v15_20261004.gd"
const SNAPSHOT_ORIGIN_SHA: String = "9c070d8248e7dc4b7688853ee3300dab0835e99326cc3dfe4f9592160fa80a9d"
## NEW joint entry. FULL aggregates only this process's actual normal phases.
## Current artifacts and every required category fail closed. SOURCE/FAST are
## separate scopes; root owns actual OS exit/log review and all visual verdicts.
const ORACLE_PATH: String = "res://tests/helpers/joint_v15_v8_source_context_oracle.gd"
const WORLD_PHASE: String = "res://tests/helpers/joint_v15_v8_world_prepared_phase.gd"
const CITY_PHASE: String = "res://tests/helpers/joint_v15_v8_city_gameplay_lifecycle_grace_phase.gd"
const OUTSKIRTS_PHASE: String = "res://tests/helpers/joint_v15_outskirts_prepared_phase.gd"
const PHASES: Array[String] = ["fast","world","city","outskirts","migration","full"]
const JOINT_GATE_PATH := "res://scripts/dev/joint_world_city_v15_v8_wall_acceptance.gd"
const REQUIRED_WORLD: Array[String]=["saved_global_mesh_RF_and112_actual_reference_edges","all64_raw_repeat_SSAA_models_support_and_nine_ecology_regions","all_authored_world_routes_actual_normal_input","all_authored_open_seam_witnesses_actual_normal_input","all16_space_door_mouse_arrow_actual_returns","all16_wall_roof_wrongside_actual_input_negatives","all_current_objects_source_binding_physical_stop_bypass_actual_current_alpha","three_southern_strong_current_frame_same_band_gt512_pairs","actual48_historic_isolated_save_load_Field_birth_and15_reread","actual_free_indoor_native15_and_unknown_version_zero_mutation_saves","actual_M_v15_overview_sixteen_labels_and_current_player_marker","actual_victory_defeat_confirmed_team_flee_version15_exact_returns","normal_spawned_NPC_south_gt512_same_band_both_directions_four_frames_tie_cleanup"]
var checks: int = 0
var failures: int = 0
var phase: String = "fast"
var frozen_inputs_path: String = ""
var candidate: bool = false
var output: String = ""
var raw_report: Dictionary = {}
var unfinished: Array[String] = []
var before_files: Dictionary = {}
var original_slot: Variant
var phase_reports: Dictionary = {}
var source_before: Dictionary={}
var coverage: Dictionary={}
var frozen_inputs: Dictionary={}
var frozen_inputs_sha256: String=""
var cleanup_evidence: Dictionary={}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		push_error("[JOINT V15 FAIL] " + label)
	return ok

func _normal_files() -> Dictionary:
	var files: Dictionary = {}
	for slot in 5:
		for suffix: String in ["", ".bak", ".tmp"]:
			var path: String = "user://save_%d.json%s" % [slot,suffix]
			var item: Dictionary = {"exists":FileAccess.file_exists(path)}
			if item.exists:
				var file: FileAccess = FileAccess.open(path,FileAccess.READ)
				item["readable"] = file != null
				if file != null:
					item["bytes"] = file.get_length()
					file.close()
				item["sha256"] = FileAccess.get_sha256(path)
				item["modified_seconds"] = FileAccess.get_modified_time(path)
			files[ProjectSettings.globalize_path(path)] = item
	return files

func _arguments() -> bool:
	_check(FileAccess.get_sha256(V8_ENTRY_ORIGIN_PATH).to_lower()==V8_ENTRY_ORIGIN_SHA,"exact preserved city-only entry origin; new FULL never inherits old PASS")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-phase="): phase = argument.trim_prefix("--qa-phase=")
		elif argument.begins_with("--qa-frozen-inputs="): frozen_inputs_path = argument.trim_prefix("--qa-frozen-inputs=")
		elif argument == "--candidate-before-cutover": candidate = true
		elif argument in ["--qa-gpu-approved","--luoyang-v3-candidate","--outskirts-candidate-preview","--outskirts-complete-v5"]: pass
		else: _check(false,"unknown joint argument, no silent default: "+argument)
	_check(FileAccess.get_sha256(SNAPSHOT_ORIGIN_PATH).to_lower()==SNAPSHOT_ORIGIN_SHA and phase in PHASES,"exact frozen FULL parent and known phase; FULL never accepts region/portal/input subset")
	_check(phase == "full","NEW V8 FULL entry rejects phase subsets; final current source pins remain mandatory")
	_check(not ("--luoyang-v3-candidate" in OS.get_cmdline_user_args()) or candidate,"in-memory city candidate flag requires explicit pre-cutover stage, forbidden in fresh canonical acceptance")
	_check(not ("--outskirts-candidate-preview" in OS.get_cmdline_user_args() or "--outskirts-complete-v5" in OS.get_cmdline_user_args()) or candidate,"complete-v5 local preview flags forbidden in fresh canonical acceptance")
	_check(frozen_inputs_path.begins_with("res://build/joint_world_luoyang_20261003_qa/") and frozen_inputs_path.ends_with(".json") and not ".." in frozen_inputs_path,"explicit root frozen-input JSON within new QA evidence domain")
	return failures == 0

func _write_checked(name: String, value: Dictionary) -> bool:
	var path: String = output+name
	if FileAccess.file_exists(path): return false
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null: return false
	var encoded: String = JSON.stringify(value,"\t")
	file.store_string(encoded)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	if error != OK: return false
	var readback: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var expected: Variant = JSON.parse_string(encoded)
	return readback is Dictionary and readback == expected

func _run() -> void:
	before_files = _normal_files()
	output = "res://build/joint_world_luoyang_20261003_qa/joint_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output) == OK,"new evidence output, never overwrite earlier failures")
	for id: String in ["GameState","Inventory","QuestManager","BountyManager","SceneRouter","SaveManager"]:
		_check(root.has_node(id),"normal autoload registered: "+id)
	var arguments_ok: bool = _arguments()
	if not arguments_ok or failures > 0:
		await _finish()
		return
	original_slot = root.get_node("SaveManager").get("active_slot")
	_check(FileAccess.file_exists(frozen_inputs_path),"explicit same frozen-input file exists before preflight")
	if failures > 0:
		await _finish()
		return
	frozen_inputs_sha256 = FileAccess.get_sha256(frozen_inputs_path)
	var frozen_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(frozen_inputs_path))
	_check(frozen_value is Dictionary and not frozen_value.is_empty() and frozen_inputs_sha256.length()==64 and _frozen_inputs_unchanged(),"same producer-frozen input dictionary and before/read SHA, never newest-directory discovery")
	if failures > 0:
		await _finish()
		return
	frozen_inputs = frozen_value.duplicate(true)
	var script: GDScript = load(ORACLE_PATH) as GDScript
	if _check(script != null and script.can_instantiate(),"independent current oracle dynamically compiles in real autoload context"):
		var oracle: RefCounted = script.new() as RefCounted
		if _check(oracle != null,"owned independent raw preflight oracle"):
			var selection: String = phase if phase in ["world","city","outskirts"] else "all"
			raw_report = oracle.call("run",frozen_inputs_path,selection)
			checks += int(raw_report.get("checks",0))
			for message: String in raw_report.get("errors",[]):
				failures += 1
				push_error("[JOINT preflight FAIL] "+message)
			oracle = null
	script = null
	_check(_frozen_inputs_unchanged(),"raw preflight read exactly the same immutable frozen-input file")
	_check(_write_checked("raw_source_preflight.json",raw_report),"actual raw-source evidence exact checked JSON readback")
	var preflight_ready: bool=failures==0
	if preflight_ready and phase=="full":
		source_before=_source_snapshot()
		_check(not source_before.is_empty(),"complete independent approval catalog exists before any actual FULL gameplay, no missing file omission")
		_check(_write_checked("all_actual_sources_before.json",source_before),"complete actual pre-run source catalog retained with checked readback")
		preflight_ready=failures==0
	if failures==0 and phase in ["world","migration","full"] and _check(_frozen_inputs_unchanged(),"world phase receives unchanged producer-frozen inputs"):
		var world_script: GDScript = load(WORLD_PHASE) as GDScript
		if _check(world_script!=null and world_script.can_instantiate(),"prepared new-world runtime phase loads only after current-artifact preflight"):
			var world_phase: RefCounted = world_script.new() as RefCounted
			var selected_phase: String = "migration" if phase=="migration" else "full"
			var world_record: Dictionary = await world_phase.call("run",self,selected_phase,candidate,frozen_inputs.duplicate(true))
			_check(_frozen_inputs_unchanged(),"actual world phase leaves its exact final/execution pin input file unchanged")
			checks += int(world_record.get("checks",0))
			failures += int(world_record.get("failures",1))
			phase_reports["world"] = world_record
			_check(_write_checked("world_phase_actual.json",world_record),"actual world runtime phase result checked readback; no previous run reuse")
			world_phase = null
		world_script = null
	if phase in ["world","migration","full"]:
		# Do not credit absent categories, but do not falsely label actual completed
		# world input as a stub. Its independent result preserves every real FAIL.
		for category: String in (phase_reports.get("world",{}) as Dictionary).get("incomplete_phases",[]):
			unfinished.append("WORLD:"+category)
	if preflight_ready and phase in ["city","full"]:
		await _run_prepared_phase("city",CITY_PHASE)
		for category: String in (phase_reports.get("city",{}) as Dictionary).get("incomplete_phases",[]): unfinished.append("CITY:"+category)
	if preflight_ready and phase in ["outskirts","full"]:
		await _run_prepared_phase("outskirts",OUTSKIRTS_PHASE)
	if phase=="full":
		_check(unfinished.is_empty(),"all actual joint FULL mandatory mechanisms implemented; unfinished runtime categories cannot silently receive complete credit")
		coverage=_full_coverage()
	await _finish()

func _source_snapshot() -> Dictionary:
	# The fixed independent approval catalogue is only read. Never invoke its
	# approval/activation methods, or derive a manifest whitelist from QA results.
	var script: Script=load(JOINT_GATE_PATH) as Script
	if script==null or not script.can_instantiate(): return {}
	var value: Variant=script.call("snapshot")
	if not value is Dictionary: return {}
	var current: Dictionary=value
	for path: String in current:
		if String(current[path]).length()!=64 or not FileAccess.file_exists(path) or FileAccess.get_sha256(path).to_lower()!=String(current[path]).to_lower(): return {}
	return current.duplicate(true)

func _ids(actual: Variant,expected: Array) -> bool:
	if not actual is Array or actual.size()!=expected.size(): return false
	var seen: Dictionary={}
	for id: Variant in actual:
		if not id in expected or seen.has(id): return false
		seen[id]=true
	return seen.size()==expected.size()

func _full_coverage() -> Dictionary:
	var world: Dictionary=phase_reports.get("world",{})
	var city: Dictionary=phase_reports.get("city",{})
	var outskirts: Dictionary=phase_reports.get("outskirts",{})
	var world_done: bool=bool(world.get("source_complete",false)) and int(world.get("failures",-1))==0 and bool(world.get("field_input_executed",false))
	var phases: Array=world.get("completed_phases",[])
	for required: String in REQUIRED_WORLD:
		_check(required in phases,"actual FULL world category completed in this process: "+required)
		world_done=world_done and required in phases
	var expected_world: Array=["yanmen_pass","huashan","luoyang","bianzhou","gufeng","linxi_village","qinghe_town","zhuwei_village","wudang","xiangzhou","jinling","bailu_ferry","east_sea_port","mingwu","lingyue","lieyun_valley"]
	var expected_core: Array=["huashan","luoyang","bianzhou","gufeng","wudang","xiangzhou","jinling","lingyue","mingwu"]
	world_done=world_done and _ids(world.get("portal_ids"),expected_world) and _ids(world.get("core_ids"),expected_core) and world.get("chunk_count")==64 and world.get("seam_count")==112
	var city_done: bool=bool(city.get("source_complete",false)) and int(city.get("failures",-1))==0 and bool(city.get("normal_gameplay",false)) and city.get("dry_run") is bool and city.get("dry_run")==false and bool(city.get("ordinary_Field_executed",false))
	city_done=city_done and _ids(city.get("region_ids"),["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]) and city.get("npcs_ids",[]).size()==15 and city.get("interactions_ids",[]).size()==11 and city.get("portals_ids",[]).size()==12
	var outskirts_done: bool=bool(outskirts.get("source_complete",false)) and int(outskirts.get("failures",-1))==0 and bool(outskirts.get("ordinary_Field_executed",false)) and bool(outskirts.get("normal_encounter_rewards_returns",false)) and _ids(outskirts.get("scene_ids"),["openworld_v15_bamboo_outskirts","openworld_v15_forest_outskirts","openworld_v15_marsh_outskirts"])
	var context: Dictionary=world.get("actual_saved_contexts",{})
	var local: Dictionary=(city.get("records",{}) as Dictionary).get("migration",{})
	var unknown_world: int=0
	var unknown_local: int=0
	var native_world_rereads: int=0
	var native_local_cases: int=0
	for row: Dictionary in context.get("records",[]):
		if row.get("kind")=="UNKNOWN_VERSION_REJECTED_ZERO_MUTATION":
			if row.get("loaded")==false and row.get("zero_mutation")==true: unknown_world+=1
		elif (row.get("native_navigation",{}) as Dictionary).get("world_map_version")==15: native_world_rereads+=1
	for row: Dictionary in local.get("records",[]):
		if String(row.get("case","")).begins_with("unsupported_"):
			if row.get("loaded")==false and row.get("zero_mutation")==true: unknown_local+=1
		elif String(row.get("case","")).begins_with("native_repeat_"): native_local_cases+=1
	var migration_done: bool=world_done and city_done and bool(context.get("complete",false)) and bool(local.get("complete",false)) and context.get("records",[]).size()==24 and local.get("records",[]).size()==80 and unknown_world==6 and unknown_local==20 and native_world_rereads==18 and native_local_cases==12
	_check(world_done and city_done and outskirts_done and migration_done,"FULL actual source/Field/input/identity coverage complete; no source/unit/old proof credit")
	if DisplayServer.get_name()!="headless":
		var city_images: Array=(city.get("records",{}) as Dictionary).get("screenshots",[])
		_check("--qa-gpu-approved" in OS.get_cmdline_user_args() and bool(world.get("GPU_executed",false)) and not city_images.is_empty() and not outskirts.get("GPU_screenshots",[]).is_empty(),"separate actual GPU renders all three normal gameplay scopes; no reused headless captures")
	return {"world":{"complete":world_done,"portal_ids":world.get("portal_ids",[]),"core_ids":world.get("core_ids",[]),"chunk_count":world.get("chunk_count",0),"seam_count":world.get("seam_count",0),"route_centers_4px_full17":world.get("route_4px_full17_centers",0),"all_declared_open_seams_input":world.get("actual_open_seam_input",[]).size(),"limits":"112 independent full32px reference strips and all authored open crossing witnesses; does not claim all112 boundaries open"},"city":{"complete":city_done,"region_ids":city.get("region_ids",[]),"npcs_ids":city.get("npcs_ids",[]),"interactions_ids":city.get("interactions_ids",[]),"portals_ids":city.get("portals_ids",[]),"normal_gameplay":city_done,"water_decoration_absence_proofs":city.get("water_decoration_absence_proofs",[])},"outskirts":{"complete":outskirts_done,"scene_ids":outskirts.get("scene_ids",[]),"normal_encounter_rewards_returns":outskirts_done},"migration":{"complete":migration_done,"world_source_versions":[12,13,14,15] if migration_done else [],"local_source_versions":[1,3] if migration_done else [],"repeat_no_remap":migration_done,"unknown_rejected_zero_mutation":migration_done,"actual_unknown_world_loads":unknown_world,"actual_unknown_local_loads":unknown_local,"actual_free_and_indoor_native_world_rereads":native_world_rereads,"actual_local_native_repeat_cases":native_local_cases}}

func _run_prepared_phase(id: String,path: String) -> void:
	var prepared_script: GDScript=load(path) as GDScript
	if not _check(prepared_script!=null and prepared_script.can_instantiate(),"new prepared "+id+" phase compiles only in actual autoload context"): return
	var prepared: RefCounted=prepared_script.new() as RefCounted
	var record: Dictionary=await prepared.call("run",self,candidate)
	checks+=int(record.get("checks",0))
	failures+=int(record.get("failures",1))
	phase_reports[id]=record
	_check(_write_checked(id+"_phase_actual.json",record),"actual new-root "+id+" phase result checked readback; no historical PASS reused")
	prepared=null
	prepared_script=null

func _frozen_inputs_unchanged() -> bool:
	return frozen_inputs_sha256.length()==64 and FileAccess.file_exists(frozen_inputs_path) and FileAccess.get_sha256(frozen_inputs_path)==frozen_inputs_sha256

func _natural_audio_cleanup() -> void:
	# All normal gameplay and BGM predicates have finished. Give existing 8s
	# victory-sting continuations their own natural stages (including .32s fade).
	# No timer cancellation, private cache clearing or stream/request-ID mutation.
	var began: int = Time.get_ticks_usec()
	var frames: int = 0
	while Time.get_ticks_usec()-began < 9000000:
		await process_frame
		frames += 1
	var audio: Node = root.get_node_or_null("AudioManager")
	var stop_requested: bool = audio != null
	if audio != null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	cleanup_evidence={"scope":"NATURAL_FINAL_AUDIO_LIFECYCLE_NOT_GAMEPLAY_OR_BGM_APPROVAL","natural_grace_usec":Time.get_ticks_usec()-began,"natural_process_frames":frames,"requested_sting_grace_usec":9000000,"public_stop_bgm_requested":stop_requested,"public_fade_seconds":.15,"natural_drain_seconds":.25,"timer_cancelled":false,"private_audio_cache_cleared":false}
	_check(stop_requested,"normal public AudioManager cleanup is available after all assertions")

func _finish() -> void:
	await _natural_audio_cleanup()
	if not frozen_inputs_sha256.is_empty(): _check(_frozen_inputs_unchanged(),"frozen final inputs remain byteexact after natural cleanup")
	var after_files: Dictionary = _normal_files()
	_check(before_files == after_files,"normal player files unchanged; no save/load or restoration invoked")
	if root.has_node("SaveManager") and original_slot != null:
		_check(root.get_node("SaveManager").get("active_slot") == original_slot,"normal active slot unchanged")
	var after_sources: Dictionary={}
	if phase=="full" and not source_before.is_empty():
		after_sources=_source_snapshot()
		_check(source_before==after_sources and not after_sources.is_empty(),"all actual frozen runtime/art/gameplay/QA bytes unchanged through complete run")
		_check(_write_checked("all_actual_sources_after.json",after_sources),"actual full end source catalog checked persistence")
	var full_complete: bool=phase=="full" and failures==0 and unfinished.is_empty() and not source_before.is_empty() and source_before==after_sources and coverage.size()==4
	for record: Dictionary in coverage.values(): full_complete=full_complete and record.get("complete")==true
	var actual_phase: String="JOINT_FULL_ACTUAL_FIELD_INPUT" if phase=="full" else "JOINT_FAST_SOURCE_PREFLIGHT" if phase=="fast" else "JOINT_LIMITED_ACTUAL_"+phase.to_upper()
	var report: Dictionary = {"schema":1,"scope":"JOINT_FULL_NORMAL_GAMEPLAY" if phase=="full" else "JOINT_FAST_SOURCE_PREFLIGHT_ONLY_NOT_FIELD" if phase=="fast" else "JOINT_LIMITED_NORMAL_PHASE_NOT_FULL","completed":full_complete or (failures==0 and phase=="fast"),"source_complete":full_complete,"phase":actual_phase,"requested_phase":phase,"mode":"headless" if DisplayServer.get_name()=="headless" else "gpu","dry_run":false,"source_sha256":source_before,"coverage":coverage,"candidate_before_cutover":candidate,"checks":checks+1,"failed":failures,"failures":failures,"unfinished_categories":unfinished,"normal_files_before":before_files,"normal_files_after":after_files,"player_saves_unchanged":before_files==after_files,"external_exact_UTCticks":"ROOT_FRESH_BEFORE_AFTER_REQUIRED","engine_pid":OS.get_process_id(),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path),"oracle_path":ORACLE_PATH,"oracle_sha256":FileAccess.get_sha256(ORACLE_PATH),"frozen_inputs_path":frozen_inputs_path,"frozen_inputs_sha256":FileAccess.get_sha256(frozen_inputs_path) if FileAccess.file_exists(frozen_inputs_path) else "","field_executed":false,"gpu_executed":false,"visual_approved":false,"production_approved":false}
	report["phase_reports"] = phase_reports.duplicate(true)
	report["frozen_inputs_sha256_before"] = frozen_inputs_sha256
	report["natural_final_audio_cleanup"] = cleanup_evidence.duplicate(true)
	report["prepared_world_phase_sha256"] = FileAccess.get_sha256(WORLD_PHASE)
	report["prepared_city_phase_sha256"] = FileAccess.get_sha256(CITY_PHASE)
	report["prepared_outskirts_phase_sha256"] = FileAccess.get_sha256(OUTSKIRTS_PHASE)
	report["field_executed"] = bool((phase_reports.get("world",{}) as Dictionary).get("field_input_executed",false))
	report["field_executed"] = report.field_executed or bool((phase_reports.get("city",{}) as Dictionary).get("ordinary_Field_executed",false)) or bool((phase_reports.get("outskirts",{}) as Dictionary).get("ordinary_Field_executed",false))
	report["gpu_executed"] = bool((phase_reports.get("world",{}) as Dictionary).get("GPU_executed",false))
	_check(_write_checked("result.json",report),"final result exact checked JSON readback; IO failure is test failure")
	for frame in 4: await process_frame
	print("JOINT_WORLD_CITY_QA: %d checks / %d failures; phase=%s; Field=%s GPU=%s; complete=%s visual=NOT_REVIEWED; output=%s" % [checks,failures,actual_phase,report.field_executed,report.gpu_executed,full_complete,output])
	quit(0 if failures==0 else 1)


