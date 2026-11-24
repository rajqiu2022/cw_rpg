extends SceneTree
## SOURCE/mode contract only. Synthetic report shapes are never Field or approval.
var MODE: Variant=null
const EXPECTED_ENGINE_SHA: String="975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const OLD_FROZEN: String="res://build/joint_world_luoyang_20261003_qa/353_v9e_candidate_complete_release_headless_ecology_domains_20261008/frozen_inputs.json"
const OLD_FROZEN_SHA: String="6400e26f1d7a2435ab27fe0422e9801e75580d72f743cff5ad02a0335f2a4488"
const LOADS: Array[String]=["res://tests/test_joint_world_luoyang_v15_release_20261005.gd","res://tests/helpers/joint_v15_release_world_prepared_phase.gd","res://tests/helpers/joint_v15_wasapi_operational_city_phase_20261007.gd","res://tests/helpers/joint_v15_current_save_load_20261008.gd","res://tests/helpers/joint_v15_v9e_source_context_oracle.gd","res://tests/helpers/prepare_joint_v9e_release_frozen_inputs_20261007.gd","res://scripts/dev/joint_world_city_v15_release_acceptance.gd","res://scripts/dev/activate_joint_world_city_v15_release.gd","res://tests/helpers/prepare_joint_v9e_joint_release_review_drafts_20261007.gd","res://tests/test_joint_v9e_fresh_start_current_save_load_limited_20261008.gd"]
var checks: int=0
var failures: int=0
var sources_before: Dictionary={}
var players_before: Dictionary={}
var slot_before: Variant

func _initialize() -> void: call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("[FRESH MODE UNIT] "+label)

func _file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false}
	var file: FileAccess=FileAccess.open(path,FileAccess.READ)
	var bytes: int=file.get_length() if file!=null else -1
	if file!=null: file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":bytes,"mtime_seconds":FileAccess.get_modified_time(path)}

func _players() -> Dictionary:
	var result: Dictionary={}
	for slot in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String="user://save_%d.json%s"%[slot,suffix]
			result[path]=_file(path)
	return result

func _fixture(before_cutover: bool) -> Dictionary:
	var ids: Array[String]=MODE.case_ids(before_cutover)
	var records: Array=[]
	var unknown: Array=[]
	for id: String in ids:
		var local: Dictionary={}
		for city: String in MODE.CITY_IDS: local[city]=3
		var nav: Dictionary={"current_field":id,"current_field_spawn":[.5,.5],"world_map_version":15,"local_layout_versions":local,"portal_return_spawns":{}}
		var birth: Dictionary={"scene_id":id,"raw_full_feet_clear":true,"actual_Physics_clear":true,"position_matches_saved":true}
		records.append({"scene_id":id,"saved":true,"loaded":true,"actual_Field_birth":true,"reloaded":true,"actual_birth_full_feet_clear":true,"repeat_no_remap":true,"state_preserved":true,"passed":true,"births":[birth.duplicate(true),birth.duplicate(true)],"navigation_before":nav.duplicate(true),"loaded_navigation":nav.duplicate(true),"reloaded_navigation":nav.duplicate(true)})
		var domain: String="world" if id==ids[0] else "local" if id in MODE.CITY_IDS else ""
		var versions: Array=MODE.BAD_WORLD if domain=="world" else MODE.BAD_LOCAL if domain=="local" else []
		for version: Variant in versions:
			unknown.append({"scene_id":id,"version_domain":domain,"version":version,"loaded":false,"zero_mutation":true,"before":{"sentinel":13},"after":{"sentinel":13}})
	var report: Dictionary={"scope":MODE.SAVE_SCOPE,"complete":true,"world_coordinate_version":15,"city_layout_version":3,"save_schema_version":14,"failures":0,"scene_ids":ids,"records":records,"unknown_records":unknown,"actual_save_load_field_birth":true,"repeat_no_remap":true,"state_preserved":true,"unknown_rejected_zero_mutation":true,"player_saves_unchanged":true}
	report.merge(MODE.mode_metadata(),true)
	return report

func _finite_gate_units() -> void:
	# Actual gate predicates, synthetic input contracts only: no Field/approval.
	var gate: Script=load(LOADS[6]) as Script
	if gate==null or not gate.can_instantiate():
		_check(false,"finite gate actual script available")
		return
	var contract_path: String="res://scripts/world/world_map_v15_contract.gd"
	sources_before[contract_path]=_file(contract_path)
	var contract: Script=load(contract_path) as Script
	if contract==null or not contract.can_instantiate():
		_check(false,"actual formal version contract loads")
		return
	var formal: int=int(contract.call("formal_version"))
	var current: Dictionary={}
	current[LOADS[3]]=FileAccess.get_sha256(LOADS[3])
	var menu: Dictionary={"scope":"ACTUAL_MAIN_MENU_NEW_GAME_INPUT","complete":true,"normal_button_input":true,"player_saves_unchanged":true,"formal_requires_world15":true,"candidate_reset_uses_formal_baseline":true,"actual_start_scene_id":"linxi_tutorial","formal_world_version":formal,"actual_reset_navigation":{"current_field":"linxi_tutorial","world_map_version":formal,"local_layout_versions":{},"portal_return_spawns":{}},"input":{"logical":[2,-2],"physical":[2,-2],"final_transform":[1,0,0,1,0,0]},"executing_script_path":LOADS[3],"executing_script_sha256":current[LOADS[3]]}
	menu.merge(MODE.mode_metadata(),true)
	_check(gate.call("_actual_new_game",menu,current),"synthetic finite original pointer contract positive")
	var malformed: Dictionary=menu.duplicate(true)
	var native_json: Variant=JSON.parse_string("{\"logical\":[2,-2],\"physical\":[0,0],\"final_transform\":[1e308,0,1e308,0,0,0]}")
	_check(native_json is Dictionary and is_finite(float(native_json.final_transform[0])),"overflow fixture uses finite original JSON numbers")
	malformed.input=native_json
	_check(not gate.call("_actual_new_game",malformed,current),"finite Double multiply-add Inf-minus-Inf cannot hide NaN pointer distance")
	var huge: Variant=JSON.parse_string("[1e200,0]")
	_check(not gate.call("_current_native_pair_equal",huge,huge),"finite JSON pair overflowing native Float32 rejected, not claimed new old-gate defect")
	var scene_path: String="res://data/scenes/linxi_village_scrollmap.tres"
	sources_before[scene_path]=_file(scene_path)
	var definition: SceneScript=load(scene_path) as SceneScript
	if definition==null or definition.map_layout==null:
		_check(false,"actual ordinary layout for finite contract control")
		return
	var dimensions: Vector2=definition.map_layout.design_size
	var nav: Dictionary={"current_field_spawn":[.5,.5]}
	var birth: Dictionary={"scene_id":"linxi_village_scrollmap","raw_full_feet_clear":true,"actual_Physics_clear":true,"position_matches_saved":true,"actor_root_px":[dimensions.x*.5,dimensions.y*.5],"world_size_px":[dimensions.x,dimensions.y],"expected_root_normalized":[.5,.5],"actual_root_normalized":[.5,.5],"layout_design_size_px":[dimensions.x,dimensions.y],"visible_foot_px":[dimensions.x*.5,dimensions.y*.5],"visible_offset_px":[0,0],"layout_schema_version":definition.map_layout.schema_version}
	_check(gate.call("_current_birth",birth,"linxi_village_scrollmap","ordinary",nav),"synthetic birth positive uses actual source layout, not actual Field credit")
	for key: String in ["actor_root_px","world_size_px","expected_root_normalized","actual_root_normalized","visible_foot_px","visible_offset_px"]:
		malformed=birth.duplicate(true); malformed[key]=huge.duplicate()
		_check(not gate.call("_current_birth",malformed,"linxi_village_scrollmap","ordinary",nav),"birth finite JSON/native overflow rejects: "+key)
	malformed=birth.duplicate(true); malformed.world_size_px=[3e38,3e38]; malformed.actual_root_normalized=[3e38,3e38]
	_check(not gate.call("_current_birth",malformed,"linxi_village_scrollmap","ordinary",nav),"native finite actual*size overflow rejects")
	malformed=birth.duplicate(true); malformed.world_size_px=[3e38,3e38]
	var large_nav: Dictionary={"current_field_spawn":[3e38,3e38]}
	_check(not gate.call("_current_birth",malformed,"linxi_village_scrollmap","ordinary",large_nav),"native finite expected*size overflow rejects")
	malformed=birth.duplicate(true); malformed.actor_root_px=[3e38,3e38]; malformed.visible_offset_px=[3e38,3e38]
	_check(not gate.call("_current_birth",malformed,"linxi_village_scrollmap","ordinary",nav),"native finite root+offset overflow rejects")
	malformed=birth.duplicate(true); malformed.actor_root_px=[3e38,3e38]; malformed.visible_foot_px=[3e38,3e38]
	_check(not gate.call("_current_birth",malformed,"linxi_village_scrollmap","ordinary",nav),"finite vector distance overflowing native length rejects")
	definition=null; contract=null; gate=null

func _run() -> void:
	players_before=_players()
	slot_before=root.get_node("SaveManager").get("active_slot")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==EXPECTED_ENGINE_SHA,"actual frozen engine/WASAPI/normal clock, not fallback")
	for path: String in LOADS:
		sources_before[path]=_file(path)
		var script: Script=load(path) as Script
		_check(script!=null and script.can_instantiate(),"actual current source loads/can_instantiate only: "+path)
		if path==LOADS[3]: MODE=script
		script=null
	if failures>0:
		await _finish_unit()
		return
	_check(FileAccess.get_sha256(OLD_FROZEN).to_lower()==OLD_FROZEN_SHA,"retained original historical frozen input bytes")
	sources_before[OLD_FROZEN]=_file(OLD_FROZEN)
	var original: Variant=JSON.parse_string(FileAccess.get_file_as_string(OLD_FROZEN))
	_check(original is Dictionary and MODE.frozen_mode_matches(original,false),"actual original frozen accepted only by historical mode")
	_check(not MODE.frozen_mode_matches(original,true),"actual old frozen cannot silently satisfy fresh scope")
	var fresh: Dictionary=original.duplicate(true)
	fresh.scope=MODE.FROZEN_SCOPE
	fresh.merge(MODE.mode_metadata(),true)
	fresh=JSON.parse_string(JSON.stringify(fresh,"\t",true))
	_check(MODE.frozen_mode_matches(fresh,true) and not MODE.frozen_mode_matches(fresh,false),"native JSON parse fresh scope accepted only by explicit fresh mode")
	for key: String in MODE.mode_metadata():
		var missing: Dictionary=fresh.duplicate(true); missing.erase(key)
		_check(not MODE.frozen_mode_matches(missing,true),"fresh required mode metadata absent rejects: "+key)
		var malformed: Dictionary=fresh.duplicate(true); malformed[key]="true"
		_check(not MODE.frozen_mode_matches(malformed,true),"fresh metadata wrong type rejects: "+key)
	for invalid: Variant in [null,[],1,"fresh",true]: _check(not MODE.frozen_mode_matches(invalid,true),"wrong frozen container rejects")
	var switched: Dictionary=fresh.duplicate(true); switched.scope="JOINT_FROZEN_CANDIDATE_INPUTS"
	_check(not MODE.frozen_mode_matches(switched,true) and not MODE.frozen_mode_matches(switched,false),"changed scope cannot launder fresh metadata as old execution")
	for candidate: bool in [true,false]:
		var report: Dictionary=_fixture(candidate)
		_check(MODE.current_report_matches(report,candidate),"synthetic exact11/26 mode-schema positive, NOT actual Field credit")
		_check(not MODE.current_report_matches(report,not candidate),"candidate/formal IDs cannot mix")
		for key: String in ["scope","complete","historical_compatibility_tested","records","unknown_records","world_coordinate_version","city_layout_version"]:
			var missing: Dictionary=report.duplicate(true); missing.erase(key)
			_check(not MODE.current_report_matches(missing,candidate),"current report required field absent rejects: "+key)
		var wrong: Dictionary=report.duplicate(true); wrong.records[0].loaded=false
		_check(not MODE.current_report_matches(wrong,candidate),"self complete cannot hide failed actual load")
		wrong=report.duplicate(true); wrong.records[0].births[1].actual_Physics_clear=false
		_check(not MODE.current_report_matches(wrong,candidate),"second birth Physics failure rejects")
		wrong=report.duplicate(true); wrong.records[0].reloaded_navigation.world_map_version=14
		_check(not MODE.current_report_matches(wrong,candidate),"historical world version cannot satisfy current report")
		wrong=report.duplicate(true); wrong.records[1].navigation_before.local_layout_versions[MODE.CITY_IDS[0]]=1
		_check(not MODE.current_report_matches(wrong,candidate),"historical local1 cannot satisfy current city3")
		wrong=report.duplicate(true); wrong.records[1]=wrong.records[0].duplicate(true)
		_check(not MODE.current_report_matches(wrong,candidate),"duplicate scene cannot replace any current domain")
		wrong=report.duplicate(true); wrong.unknown_records[0].after.sentinel=14
		_check(not MODE.current_report_matches(wrong,candidate),"unsupported load state mutation rejects")
		wrong=report.duplicate(true); wrong.unknown_records[1]=wrong.unknown_records[0].duplicate(true)
		_check(not MODE.current_report_matches(wrong,candidate),"duplicate unknown case cannot replace current negative")
	_finite_gate_units()
	await _finish_unit()

func _finish_unit() -> void:
	_check(players_before==_players() and root.get_node("SaveManager").get("active_slot")==slot_before,"all15 player paths and active slot unchanged")
	var after: Dictionary={}
	for path: String in sources_before: after[path]=_file(path)
	_check(after==sources_before,"all consumed mode/source/old evidence SHA/bytes/mtime unchanged")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==EXPECTED_ENGINE_SHA,"actual frozen engine/WASAPI/1x at end")
	var output: String="res://build/joint_world_luoyang_20261003_qa/fresh_start_mode_units_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique mode-unit evidence directory")
	var result: Dictionary={"scope":"FRESH_START_SOURCE_LOAD_AND_SYNTHETIC_MODE_CONTRACT_ONLY_NOT_FIELD_OR_RELEASE","checks":checks+1,"failures":failures,"Field_executed":false,"release_complete":false,"sources_before":sources_before,"sources_after":after,"players_before":players_before,"players_after":_players(),"actual_audio_driver":AudioServer.get_driver_name(),"engine_executable_sha256":FileAccess.get_sha256(OS.get_executable_path())}
	var path: String=output+"result.json"
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	var saved: bool=file!=null and not FileAccess.file_exists(path+".bak")
	if file!=null:
		file.store_string(JSON.stringify(result,"\t",true)); file.flush(); saved=saved and file.get_error()==OK; file.close()
	_check(saved and JSON.parse_string(FileAccess.get_file_as_string(path))==JSON.parse_string(JSON.stringify(result,"\t",true)),"unique mode result checked readback")
	root.get_node("AudioManager").call("stop_bgm",0.0)
	Input.set_custom_mouse_cursor(null)
	for frame in 8: await process_frame
	print("FRESH_START_MODE_UNITS checks=",checks," failures=",failures," output=",output)
	quit(0 if failures==0 else 1)
