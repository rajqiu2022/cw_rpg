extends SceneTree
## DISTINCT RELEASE source, not the original exhaustive FULL and not approval.
## Every nonhistorical city/outskirts predicate remains; default mode also retains
## historical migration. Explicit fresh-start mode substitutes current save/load.
## World inventory is exhaustive,
## ordinary world prop input is preselected130 risk representatives across44PNG/8families.
## Actual final context SHA is explicit; no old capture execution credit.
const V9C_FULL_ORIGIN_PATH: String = "res://tests/test_joint_world_luoyang_v15_v8_full_20261004.gd"
const V9C_FULL_ORIGIN_SHA: String = "066bb2561768eabc9d883b47d59fd0c3ecac59cc5a1aa271a606b9f764acaa4b"
const V8_ENTRY_ORIGIN_PATH: String = "res://tests/test_joint_world_luoyang_v15_wall_street_20261004.gd"
const V8_ENTRY_ORIGIN_SHA: String = "59a31a8c52d197be9233785bea018cbf278427f62c3b0788b6d5c6c1733ef12b"
const SNAPSHOT_ORIGIN_PATH: String = "res://tests/test_joint_world_luoyang_v15_20261004.gd"
const SNAPSHOT_ORIGIN_SHA: String = "9c070d8248e7dc4b7688853ee3300dab0835e99326cc3dfe4f9592160fa80a9d"
## Current artifacts and every RELEASE category fail closed. ROOT owns actual
## OS exit/log review and all visual verdicts; no old FULL result is imported.
const RELEASE_FULL_ORIGIN_PATH: String="res://tests/test_joint_world_luoyang_v15_v9c_full_20261004.gd"
const RELEASE_FULL_ORIGIN_SHA: String="b63826b743ba358b6f9564405519d58b5677e65f43e2506383961b1b92a418ec"
# ROOT bound the actual final E artifact context; fresh mode also binds its scope.
# This source binding is not approval or inherited execution of ROOT234 V9D.
const RELEASE_FINAL_CONTEXT_SHA: String="28e48d79615858d3843cebab81cae2f78a651ffdb3d26ef5f3a1906c4a037a4f"
const RELEASE_SELECTION_PATH: String="res://build/joint_world_luoyang_20261003_qa/release_selection_root234_20261005_01/representative_selection.json"
const RELEASE_SELECTION_SHA: String="34a6ffd4b6da7adfc953c7339e1398c5a77e6f112399e4361350050246c4704f"
const ORACLE_PATH: String = "res://tests/helpers/joint_v15_v9e_source_context_oracle.gd"
const WORLD_PHASE: String = "res://tests/helpers/joint_v15_release_world_prepared_phase.gd"
const CITY_PHASE: String = "res://tests/helpers/joint_v15_wasapi_operational_city_phase_20261007.gd"
const OUTSKIRTS_PHASE: String = "res://tests/helpers/joint_v15_outskirts_prepared_phase.gd"
const CURRENT_FORMAT = preload("res://tests/helpers/joint_v15_current_save_load_20261008.gd")
const PHASES: Array[String] = ["release"]
const JOINT_GATE_PATH := "res://scripts/dev/joint_world_city_v15_release_acceptance.gd"
const REQUIRED_WORLD: Array[String]=["saved_global_mesh_RF_and112_actual_reference_edges","all64_raw_repeat_SSAA_models_support_and_nine_ecology_regions","all_authored_world_routes_actual_normal_input","all1344_seam_17shoe_Physics_and_fixed112_normal_input","all16_space_door_mouse_arrow_actual_returns","all16_wall_roof_wrongside_actual_input_negatives","all2687_binding_2322_ownRID_physics_and_fixed130_actual_inputs","three_southern_strong_current_frame_same_band_gt512_pairs","actual48_historic_isolated_save_load_Field_birth_and15_reread","actual_free_indoor_native15_and_unknown_version_zero_mutation_saves","actual_M_v15_overview_sixteen_labels_and_current_player_marker","actual_victory_defeat_confirmed_team_flee_version15_exact_returns","normal_spawned_NPC_south_gt512_same_band_both_directions_four_frames_tie_cleanup"]
var checks: int = 0
var failures: int = 0
var phase: String = "release"
var frozen_inputs_path: String = ""
var candidate: bool = false
var fresh_start_only: bool = false
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
	_check(FileAccess.get_sha256(RELEASE_FULL_ORIGIN_PATH).to_lower()==RELEASE_FULL_ORIGIN_SHA,"immutable original exhaustive FULL remains unchanged, never inherited as executed")
	_check(Engine.time_scale==1.0,"RELEASE ordinary production clocks remain1x including real48s audio")
	_check(RELEASE_FINAL_CONTEXT_SHA.length()==64 and FileAccess.get_sha256(ORACLE_PATH).to_lower()==RELEASE_FINAL_CONTEXT_SHA,"actual NEW final context is explicitly frozen; PENDING cannot run")
	_check(FileAccess.get_sha256(RELEASE_SELECTION_PATH).to_lower()==RELEASE_SELECTION_SHA,"exact preexecution representative selection immutable")
	_check(FileAccess.get_sha256(V9C_FULL_ORIGIN_PATH).to_lower()==V9C_FULL_ORIGIN_SHA,"exact immutable V8 FULL origin; no prior result credit")
	_check(FileAccess.get_sha256(V8_ENTRY_ORIGIN_PATH).to_lower()==V8_ENTRY_ORIGIN_SHA,"exact preserved city-only entry origin; new FULL never inherits old PASS")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-phase="): phase = argument.trim_prefix("--qa-phase=")
		elif argument.begins_with("--qa-frozen-inputs="): frozen_inputs_path = argument.trim_prefix("--qa-frozen-inputs=")
		elif argument == "--candidate-before-cutover": candidate = true
		elif argument == "--fresh-start-only": fresh_start_only = true
		elif argument in ["--qa-gpu-approved","--luoyang-v3-candidate","--outskirts-candidate-preview","--outskirts-complete-v5"]: pass
		else: _check(false,"unknown joint argument, no silent default: "+argument)
	_check(FileAccess.get_sha256(SNAPSHOT_ORIGIN_PATH).to_lower()==SNAPSHOT_ORIGIN_SHA and phase in PHASES,"exact immutable original parent provenance and explicit RELEASE-only phase")
	_check(phase == "release","NEW RELEASE entry rejects phase subsets; final current source pins remain mandatory")
	_check(OS.get_cmdline_user_args().count("--fresh-start-only")<=1,"fresh-start mode flag must not be duplicated")
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
	output = "res://build/joint_world_luoyang_20261003_qa/joint_release_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(output) == OK,"new evidence output, never overwrite earlier failures")
	for id: String in ["GameState","Inventory","QuestManager","BountyManager","SceneRouter","SaveManager"]:
		_check(root.has_node(id),"normal autoload registered: "+id)
	_check(AudioServer.get_driver_name()=="WASAPI","actual WASAPI required before RELEASE arguments/preflight; no silent backend fallback")
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
	_check(CURRENT_FORMAT.frozen_mode_matches(frozen_inputs,fresh_start_only),"explicit frozen mode matches fresh-start flag; historical evidence cannot satisfy fresh scope")
	_check(frozen_inputs.get("release_entry_sha256")==FileAccess.get_sha256(get_script().resource_path).to_lower(),"frozen input binds this actual current executor, not old release source")
	_check(String(frozen_inputs.get("release_source_context_sha256","")).to_lower()==RELEASE_FINAL_CONTEXT_SHA,"producer frozen inputs exact final RELEASE context SHA, not newest discovery")
	if failures>0:
		await _finish()
		return
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
	if preflight_ready and phase=="release":
		source_before=_source_snapshot()
		_check(not source_before.is_empty(),"complete independent approval catalog exists before any actual FULL gameplay, no missing file omission")
		_check(_write_checked("all_actual_sources_before.json",source_before),"complete actual pre-run source catalog retained with checked readback")
		preflight_ready=failures==0
	if preflight_ready and fresh_start_only:
		var menu_probe: RefCounted=CURRENT_FORMAT.new()
		var menu_result: Dictionary=await menu_probe.call("run_new_game",self,candidate)
		menu_probe=null
		checks+=int(menu_result.get("checks",0)); failures+=int(menu_result.get("failures",1))
		phase_reports["new_game"]=menu_result
		_check(menu_result.get("complete")==true and menu_result.get("normal_button_input")==true,"fresh scope includes actual MainMenu NewGame input and normal start birth")
		_check(_write_checked("new_game_actual.json",menu_result),"actual menu NewGame evidence checked readback")
		preflight_ready=failures==0
	if failures==0 and phase in ["world","migration","release"] and _check(_frozen_inputs_unchanged(),"world phase receives unchanged producer-frozen inputs"):
		var world_script: GDScript = load(WORLD_PHASE) as GDScript
		if _check(world_script!=null and world_script.can_instantiate(),"prepared new-world runtime phase loads only after current-artifact preflight"):
			var world_phase: RefCounted = world_script.new() as RefCounted
			var selected_phase: String = "migration" if phase=="migration" else "release"
			var world_record: Dictionary = await world_phase.call("run",self,selected_phase,candidate,frozen_inputs.duplicate(true))
			_check(_frozen_inputs_unchanged(),"actual world phase leaves its exact final/execution pin input file unchanged")
			checks += int(world_record.get("checks",0))
			failures += int(world_record.get("failures",1))
			phase_reports["world"] = world_record
			_check(_write_checked("world_phase_actual.json",world_record),"actual world runtime phase result checked readback; no previous run reuse")
			world_phase = null
		world_script = null
	if phase in ["world","migration","release"]:
		# Do not credit absent categories, but do not falsely label actual completed
		# world input as a stub. Its independent result preserves every real FAIL.
		for category: String in (phase_reports.get("world",{}) as Dictionary).get("incomplete_phases",[]):
			unfinished.append("WORLD:"+category)
	if preflight_ready and phase in ["city","release"]:
		await _run_prepared_phase("city",CITY_PHASE)
		for category: String in (phase_reports.get("city",{}) as Dictionary).get("incomplete_phases",[]): unfinished.append("CITY:"+category)
	if preflight_ready and phase in ["outskirts","release"]:
		await _run_prepared_phase("outskirts",OUTSKIRTS_PHASE)
	if preflight_ready and fresh_start_only and failures==0:
		var saves_probe: RefCounted=CURRENT_FORMAT.new()
		var saves_result: Dictionary=await saves_probe.call("run_current",self,candidate)
		saves_probe=null
		checks+=int(saves_result.get("checks",0)); failures+=int(saves_result.get("failures",1))
		phase_reports["current_save_load"]=saves_result
		_check(_write_checked("current_save_load_actual.json",saves_result),"actual current-format isolated saves checked readback")
	if phase=="release":
		_check(unfinished.is_empty(),"all actual joint RELEASE mandatory mechanisms implemented; unfinished runtime categories cannot silently receive complete credit")
		coverage=_release_coverage()
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
	# Extend READ-ONLY historical catalogue with this distinct RELEASE source/selection closure.
	for extra: String in [get_script().resource_path,WORLD_PHASE,"res://tests/helpers/joint_v15_release_world_object_input_probe.gd",RELEASE_SELECTION_PATH]:
		if not FileAccess.file_exists(extra): return {}
		var sha: String=FileAccess.get_sha256(extra).to_lower()
		if sha.length()!=64: return {}
		current[extra]=sha
	if String(current[RELEASE_SELECTION_PATH])!=RELEASE_SELECTION_SHA: return {}
	return current.duplicate(true)

func _ids(actual: Variant,expected: Array) -> bool:
	if not actual is Array or actual.size()!=expected.size(): return false
	var seen: Dictionary={}
	for id: Variant in actual:
		if not id in expected or seen.has(id): return false
		seen[id]=true
	return seen.size()==expected.size()

func _release_coverage() -> Dictionary:
	var world: Dictionary=phase_reports.get("world",{})
	var city: Dictionary=phase_reports.get("city",{})
	var outskirts: Dictionary=phase_reports.get("outskirts",{})
	var world_done: bool=bool(world.get("release_complete",false)) and int(world.get("failures",-1))==0 and bool(world.get("field_input_executed",false))
	var phases: Array=world.get("completed_phases",[])
	for required: String in REQUIRED_WORLD:
		if fresh_start_only and required in ["actual48_historic_isolated_save_load_Field_birth_and15_reread","actual_free_indoor_native15_and_unknown_version_zero_mutation_saves"]: continue
		_check(required in phases,"actual RELEASE world category completed in this process: "+required)
		world_done=world_done and required in phases
	var object_report: Dictionary=world.get("all_current_objects",{})
	world_done=world_done and object_report.get("release_complete")==true and object_report.get("static_inventory_count")==2687 and object_report.get("attributed_forbidden_core_count")==2322 and object_report.get("unique_png_sha_count")==44 and object_report.get("representative_count")==130 and object_report.get("families",[]).size()==8 and object_report.get("selection_sha256")==RELEASE_SELECTION_SHA
	world_done=world_done and world.get("seam_static_witness_count")==1344 and world.get("seam_actual_input_count")==112 and world.get("actual_route_input",[]).size()==27 and world.get("legacy_full_executed")==false and world.get("exhaustive_2687_normal_input_executed")==false
	var expected_world: Array=["yanmen_pass","huashan","luoyang","bianzhou","gufeng","linxi_village","qinghe_town","zhuwei_village","wudang","xiangzhou","jinling","bailu_ferry","east_sea_port","mingwu","lingyue","lieyun_valley"]
	var expected_core: Array=["huashan","luoyang","bianzhou","gufeng","wudang","xiangzhou","jinling","lingyue","mingwu"]
	world_done=world_done and _ids(world.get("portal_ids"),expected_world) and _ids(world.get("core_ids"),expected_core) and world.get("chunk_count")==64 and world.get("seam_count")==112
	var city_done: bool=bool(city.get("source_complete",false)) and int(city.get("failures",-1))==0 and bool(city.get("normal_gameplay",false)) and city.get("dry_run") is bool and city.get("dry_run")==false and bool(city.get("ordinary_Field_executed",false))
	city_done=city_done and _ids(city.get("region_ids"),["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]) and city.get("npcs_ids",[]).size()==15 and city.get("interactions_ids",[]).size()==11 and city.get("portals_ids",[]).size()==12
	var city_records: Dictionary=city.get("records",{})
	var city_object_count: int=0
	var city_route_count: int=0
	for region: Dictionary in city_records.get("regions",[]):
		var geometry: Dictionary=region.get("physical_and_current_alpha",{})
		city_object_count+=geometry.get("objects",[]).size()
		city_route_count+=geometry.get("routes",[]).size()
	city_done=city_done and city_object_count==74 and city_route_count==20 and city_records.get("npcs",[]).size()==30 and city_records.get("interactions",[]).size()==22 and city_records.get("portals",[]).size()==24 and (city_records.get("interaction_negatives",{}) as Dictionary).get("records",[]).size()==55
	var natural_bgm: Dictionary=city_records.get("release_natural48_bgm",{})
	var clock_done: bool=Engine.time_scale==1.0 and natural_bgm.get("passed")==true and natural_bgm.get("normal_clock_scale")==1.0
	_check(clock_done,"live same-source48s BGM natural loop plus actual original portal input, exact identity/no-stop/events/modulo proof")
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
	var current_saves: Dictionary=phase_reports.get("current_save_load",{})
	var save_done: bool=CURRENT_FORMAT.current_report_matches(current_saves,candidate) if fresh_start_only else migration_done
	_check(world_done and city_done and outskirts_done and save_done and clock_done,"RELEASE actual source/Field/input/identity coverage complete; no source/unit/old proof credit")
	if DisplayServer.get_name()!="headless":
		var city_images: Array=(city.get("records",{}) as Dictionary).get("screenshots",[])
		_check("--qa-gpu-approved" in OS.get_cmdline_user_args() and bool(world.get("GPU_executed",false)) and not city_images.is_empty() and not outskirts.get("GPU_screenshots",[]).is_empty(),"separate actual GPU renders all three normal gameplay scopes; no reused headless captures")
	var result: Dictionary={"world":{"complete":false,"release_complete":world_done,"legacy_full_executed":false,"exhaustive_2687_normal_input_executed":false,"inventory_count":object_report.get("static_inventory_count",0),"ownRID_forbidden_core_count":object_report.get("attributed_forbidden_core_count",0),"unique_png_sha_count":object_report.get("unique_png_sha_count",0),"representative_ids":object_report.get("representative_ids",[]),"representative_count":object_report.get("representative_count",0),"family_count":object_report.get("families",[]).size(),"selection_path":RELEASE_SELECTION_PATH,"selection_sha256":RELEASE_SELECTION_SHA,"seam_static_witness_count":world.get("seam_static_witness_count",0),"seam_actual_input_count":world.get("seam_actual_input_count",0),"portal_ids":world.get("portal_ids",[]),"core_ids":world.get("core_ids",[]),"chunk_count":world.get("chunk_count",0),"seam_count":world.get("seam_count",0),"route_centers_4px_full17":world.get("route_4px_full17_centers",0),"fixed_boundary_representative_inputs":world.get("actual_open_seam_input",[]).size(),"limits":"All112 independent reference edges and all1344 <=4px complete17 actual Physics witnesses;112 fixed normal input crossings. Not all1344 normal input or21456 exhaustive object cases."},"city":{"complete":city_done,"object_count":city_object_count,"route_count":city_route_count,"action_input_count":city_records.get("npcs",[]).size()+city_records.get("interactions",[]).size(),"portal_input_count":city_records.get("portals",[]).size(),"interaction_negative_count":(city_records.get("interaction_negatives",{}) as Dictionary).get("records",[]).size(),"migration_count":(city_records.get("migration",{}) as Dictionary).get("records",[]).size(),"region_ids":city.get("region_ids",[]),"npcs_ids":city.get("npcs_ids",[]),"interactions_ids":city.get("interactions_ids",[]),"portals_ids":city.get("portals_ids",[]),"normal_gameplay":city_done,"water_decoration_absence_proofs":city.get("water_decoration_absence_proofs",[])},"outskirts":{"complete":outskirts_done,"scene_ids":outskirts.get("scene_ids",[]),"normal_encounter_rewards_returns":outskirts_done},"migration":{"complete":migration_done,"world_source_versions":[12,13,14,15] if migration_done else [],"local_source_versions":[1,3] if migration_done else [],"repeat_no_remap":migration_done,"unknown_rejected_zero_mutation":migration_done,"actual_unknown_world_loads":unknown_world,"actual_unknown_local_loads":unknown_local,"actual_free_and_indoor_native_world_rereads":native_world_rereads,"actual_local_native_repeat_cases":native_local_cases},"clock":{"complete":clock_done,"time_scale":Engine.time_scale,"bgm_natural48_complete":clock_done,"bgm_evidence":natural_bgm}}
	if fresh_start_only:
		result.erase("migration")
		result["current_save_load"]=current_saves.duplicate(true)
	return result

func _run_prepared_phase(id: String,path: String) -> void:
	var prepared_script: GDScript=load(path) as GDScript
	if not _check(prepared_script!=null and prepared_script.can_instantiate(),"new prepared "+id+" phase compiles only in actual autoload context"): return
	var prepared: RefCounted=ReleaseCityPhase.new() if id=="city" else prepared_script.new() as RefCounted
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
	_check(AudioServer.get_driver_name()=="WASAPI","actual WASAPI remains required after complete RELEASE and natural cleanup")
	if not frozen_inputs_sha256.is_empty(): _check(_frozen_inputs_unchanged(),"frozen final inputs remain byteexact after natural cleanup")
	var after_files: Dictionary = _normal_files()
	_check(before_files == after_files,"normal player files unchanged; no save/load or restoration invoked")
	if root.has_node("SaveManager") and original_slot != null:
		_check(root.get_node("SaveManager").get("active_slot") == original_slot,"normal active slot unchanged")
	var after_sources: Dictionary={}
	if phase=="release" and not source_before.is_empty():
		after_sources=_source_snapshot()
		_check(source_before==after_sources and not after_sources.is_empty(),"all actual frozen runtime/art/gameplay/QA bytes unchanged through complete run")
		_check(_write_checked("all_actual_sources_after.json",after_sources),"actual full end source catalog checked persistence")
	var release_complete: bool=phase=="release" and failures==0 and unfinished.is_empty() and not source_before.is_empty() and source_before==after_sources and coverage.size()==5
	release_complete=release_complete and (coverage.get("world",{}) as Dictionary).get("release_complete")==true
	var required_complete: Array=["city","outskirts","current_save_load" if fresh_start_only else "migration","clock"]
	for id: String in required_complete: release_complete=release_complete and (coverage.get(id,{}) as Dictionary).get("complete")==true
	if fresh_start_only: release_complete=release_complete and (phase_reports.get("new_game",{}) as Dictionary).get("complete")==true
	var actual_phase: String="JOINT_RELEASE_RISK_STRATIFIED_ACTUAL_FIELD_INPUT" if phase=="release" else "JOINT_FAST_SOURCE_PREFLIGHT" if phase=="fast" else "JOINT_LIMITED_ACTUAL_"+phase.to_upper()
	var report: Dictionary = {"schema":1,"scope":"JOINT_RELEASE_RISK_STRATIFIED_NORMAL_GAMEPLAY_NOT_EXHAUSTIVE_FULL" if phase=="release" else "JOINT_FAST_SOURCE_PREFLIGHT_ONLY_NOT_FIELD" if phase=="fast" else "JOINT_LIMITED_NORMAL_PHASE_NOT_FULL","completed":release_complete or (failures==0 and phase=="fast"),"source_complete":false,"release_complete":release_complete,"legacy_full_executed":false,"exhaustive_2687_normal_input_executed":false,"phase":actual_phase,"requested_phase":phase,"mode":"headless" if DisplayServer.get_name()=="headless" else "gpu","dry_run":false,"source_sha256":source_before,"coverage":coverage,"candidate_before_cutover":candidate,"checks":checks+1,"failed":failures,"failures":failures,"unfinished_categories":unfinished,"normal_files_before":before_files,"normal_files_after":after_files,"player_saves_unchanged":before_files==after_files,"external_exact_UTCticks":"ROOT_FRESH_BEFORE_AFTER_REQUIRED","engine_pid":OS.get_process_id(),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path),"oracle_path":ORACLE_PATH,"oracle_sha256":FileAccess.get_sha256(ORACLE_PATH),"frozen_inputs_path":frozen_inputs_path,"frozen_inputs_sha256":FileAccess.get_sha256(frozen_inputs_path) if FileAccess.file_exists(frozen_inputs_path) else "","field_executed":false,"gpu_executed":false,"visual_approved":false,"production_approved":false}
	if fresh_start_only:
		actual_phase=CURRENT_FORMAT.FRESH_SCOPE
		report["scope"]=CURRENT_FORMAT.FRESH_SCOPE
		report["phase"]=CURRENT_FORMAT.FRESH_SCOPE
		report.merge(CURRENT_FORMAT.mode_metadata(),true)
	else: report["fresh_start_only"]=false
	report["actual_audio_driver"] = AudioServer.get_driver_name()
	report["engine_executable_path"] = OS.get_executable_path()
	report["engine_executable_sha256"] = FileAccess.get_sha256(OS.get_executable_path())
	report["source_version_equivalence_proven"] = false
	report["DAC_continuity_proven"] = false
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
	print("JOINT_WORLD_CITY_QA: %d checks / %d failures; phase=%s; Field=%s GPU=%s; complete=%s visual=NOT_REVIEWED; output=%s" % [checks,failures,actual_phase,report.field_executed,report.gpu_executed,release_complete,output])
	quit(0 if failures==0 else 1)


class ReleaseCityPhase:
	extends "res://tests/helpers/joint_v15_wasapi_operational_city_phase_20261007.gd"
	# Single additive observation. All normal city actions/portals/geometry and
	# the inherited45s/30s/180s/grace assertions still execute through super.
	var release_loop_attempted: bool=false
	func _normal_portal_case(id: String,entry: Dictionary,mode: String) -> void:
		if not release_loop_attempted and id=="ch4_s0_luoyang_gate" and String(entry.get("id",""))=="enter_luoyang" and mode=="space":
			release_loop_attempted=true
			_check(String(entry.get("target_scene",""))=="ch4_s1_luoyang_yamen","exact authored same-city gate->yamen loop observation, no substitute portal")
			_public_fixture(entry)
			if not await _open(id): return
			var observer: RefCounted=OPERATIONAL_BGM.new()
			_check(FileAccess.get_sha256("res://tests/helpers/joint_v15_wasapi_operational_bgm_continuity_20261007.gd")==OPERATIONAL_BGM_SHA,"same frozen operational read-only observer, explicit engineering resolution model")
			var started: Dictionary=observer.call("begin_observation",tree,"RELEASE_NATURAL48_GATE_YAMEN_ORIGINAL_SPACE",180.0)
			var began: int=Time.get_ticks_usec()
			var frames: int=0
			var live_field_id: int=field.get_instance_id()
			var live: bool=true
			while Time.get_ticks_usec()-began<48000000:
				await tree.process_frame
				frames+=1
				live=live and is_instance_valid(field) and field.is_inside_tree() and tree.current_scene==field and not field.is_queued_for_deletion() and field.get_instance_id()==live_field_id
			_check(live and Engine.time_scale==1.0,"actual48-second natural live Field grace, no seeking/timer cancel or timescale change")
			# Same complete original portal predicate, normal movement/Space/return.
			# Its normal _open may replace the Field, not the same authored audio.
			await super._normal_portal_case(id,entry,mode)
			var observed: Dictionary=observer.call("finish_observation")
			observer.call("release")
			observer=null
			var before_audio: Dictionary=started.get("before",{})
			var passed: bool=live and frames>0 and Engine.time_scale==1.0 and started.get("ok")==true and observed.get("ok")==true and float(before_audio.get("loop_period_sec",0))==48.0 and float(observed.get("elapsed_sec",0))>=48.0
			_check(passed,"same actual48s loop across original normal gate input: exact stream/player/request/source/no bgm_changed/no-stop/modulo measured clocks")
			records["release_natural48_bgm"]={"passed":passed,"normal_clock_scale":Engine.time_scale,"natural_start_ticks_usec":began,"natural_end_ticks_usec":Time.get_ticks_usec(),"natural_process_frames":frames,"live_field_id_before":live_field_id,"old_field_live_during_natural_grace":live,"started":started,"observed":observed,"normal_portal_source":"ch4_s0_luoyang_gate/enter_luoyang/space","time_scale_changed":false,"audio_seeked":false,"timer_cancelled":false}
		else:
			await super._normal_portal_case(id,entry,mode)

	# Mechanical original568A finish + originalA587 natural-grace preamble.
	# Only own-source SHA addresses the outer physical .gd rather than an inner
	# Script subresource path. No gameplay/cleanup/assertion predicate changes.
	func _finish() -> Dictionary:
		await natural_field_grace("before_super_finish")
		records["own_natural_grace"]=natural_grace_records.duplicate(true)
		var bus: Node=tree.root.get_node("EventBus")
		for entry: Dictionary in event_connections:
			if bus.is_connected(entry.signal,entry.callable): bus.disconnect(entry.signal,entry.callable)
		event_connections.clear()
		_release_field_oracles()
		var field_ref: WeakRef=weakref(field) if is_instance_valid(field) else null
		if is_instance_valid(tree.current_scene):
			var owned: Node=tree.current_scene
			tree.current_scene=null
			owned.queue_free()
		field=null
		for tick in 8: await tree.process_frame
		_check(field_ref==null or field_ref.get_ref()==null,"owned city Field/reference callbacks naturally released")
		_check(_normal_files()==before_files and tree.root.get_node("SaveManager").get("active_slot")==before_slot,"normal player files and active slot unchanged through all normal city gameplay")
		# Actual action/result evidence above is retained before process-only cleanup.
		# Do not restore flags/inventory/quests wholesale and hide gameplay side effects.
		if not before_nav.is_empty():
			tree.root.get_node("SceneRouter").call("reset_for_new_game")
			_check(tree.root.get_node("SceneRouter").call("get_navigation_state")==before_nav,"public empty-navigation cleanup returns exact process fixture baseline")
		var covered: Dictionary={}
		for kind: String in COUNTS:
			var actual: Dictionary={}
			for row: Dictionary in records[kind]: actual[String(row.source_scene_id)+"/"+String(row.source_id)]=true
			var complete: bool=actual.size()==(expected[kind] as Array).size()
			for id: String in expected[kind]: complete=complete and actual.has(id)
			_check(complete,"actual normal input covers every original "+kind+" identity")
			covered[kind]=actual.keys()
		_finalize_water_proofs()
		var incomplete: Array[String]=[]
		if not bool((records.interaction_negatives as Dictionary).get("complete",false)): incomplete.append("ALL11_INTERACTION_WRONG_SIDE_AND_PHYSICAL_BOUNDARY_INPUT_NEGATIVES")
		var fresh: bool="--fresh-start-only" in OS.get_cmdline_user_args()
		if not fresh and not bool((records.migration as Dictionary).get("complete",false)): incomplete.append("ACTUAL_LOCAL1_AND_LOCAL3_ISOLATED_MIGRATION_LOAD")
		if fresh and records.migration!={"scope":"HISTORICAL_COMPATIBILITY_NOT_EXECUTED","complete":false,"historical_compatibility_tested":false,"records":[]}:
			incomplete.append("FRESH_MODE_HISTORICAL_MARKER_INVALID")
		var report: Dictionary={"schema":1,"scope":"JOINT_CITY_ACTUAL_NORMAL_FIELD_GAMEPLAY_NOT_JOINT_FULL","checks":checks,"failures":failures,"dry_run":false,"source_complete":incomplete.is_empty() and failures==0 and runtime_started,"ordinary_Field_executed":runtime_started,"incomplete_phases":incomplete,"normal_gameplay":failures==0 and runtime_started,"region_ids":IDS,"npcs_ids":covered.npcs,"interactions_ids":covered.interactions,"portals_ids":covered.portals,"water_decoration_absence_proofs":water_summaries.duplicate(true),"records":records.duplicate(true),"player_saves_unchanged":before_files==_normal_files(),"output":output,"engine_pid":OS.get_process_id(),"executing_script_sha256":FileAccess.get_sha256("res://tests/test_joint_world_luoyang_v15_release_20261005.gd"),"visual_verdict":"NOT_REVIEWED"}
		if fresh:
			report["scope"]=CURRENT_FORMAT.FRESH_SCOPE
			report.merge(CURRENT_FORMAT.mode_metadata(),true)
		_check(_write("result.json",report),"complete actual city phase JSON persisted with checked readback")
		report.checks=checks
		report.failures=failures
		driver.call("release")
		driver=null
		manifest.clear()
		tree=null
		return report
	

