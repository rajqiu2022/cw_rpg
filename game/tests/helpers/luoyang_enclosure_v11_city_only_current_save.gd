extends "res://tests/helpers/joint_v15_current_save_load_20261008.gd"
## Exactly four current city3 isolated save/load cases on the unchanged formal
## world14. Same real SaveManager serialization, two actual births and invalid
## local versions; no historical migration fixture or normal player slot write.
const ENCLOSURE = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const ENCLOSURE_RAW = preload("res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd")
const CITY_PHYSICAL = preload("res://tests/helpers/joint_v15_wall_v5_fine_alpha_probe.gd")
const CITY_SAVE_SCOPE := "LUOYANG_ENCLOSURE_V11_FOUR_CURRENT_SAVE_LOAD_FIELD_BIRTH"
var birth_probe: RefCounted
var before_cutover_mode: bool=false

func _current_setup(tree: SceneTree,before_cutover: bool) -> void:
	owner_tree=tree
	before_cutover_mode=before_cutover
	scene_id=&"world_map_jianghu"
	input_driver=INPUT_DRIVER.new()
	input_driver.call("configure",tree)
	before_saves=_actual_saves()
	prior_slot=int(root.get_node("SaveManager").get("active_slot"))
	output="res://build/joint_world_luoyang_20261003_qa/current_save_load_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"new current-format evidence directory")
	_check("--fresh-start-only" in OS.get_cmdline_user_args(),"current-format executor requires explicit fresh-start flag")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==CURRENT_ENGINE_SHA,"current-format actual frozen engine/ordinary clock/WASAPI")

func run_new_game(tree: SceneTree,before_cutover: bool) -> Dictionary:
	_current_setup(tree,before_cutover)
	var router: Node=root.get_node("SceneRouter")
	var formal_version: int=MIGRATION_SUBJECT.formal_version()
	_check(formal_version==14,"city-only fresh NewGame keeps actual canonical world14")
	var menu_scene: PackedScene=load("res://scenes/main_menu.tscn") as PackedScene
	if menu_scene==null:
		_check(false,"real MainMenu resource exists")
		return await _current_cleanup({"scope":"ACTUAL_MAIN_MENU_NEW_GAME_INPUT","complete":false})
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	var menu: Node=menu_scene.instantiate()
	root.add_child(menu)
	current_scene=menu
	for tick in 8: await process_frame
	var button: Button=menu.get_node_or_null("%BtnNewGame") as Button
	var pressed: Dictionary={"observed":false}
	var input: Dictionary={}
	_check(button!=null and not button.disabled and button.is_visible_in_tree(),"actual enabled NewGame button")
	if button!=null:
		button.pressed.connect(func()->void: pressed.observed=true,CONNECT_ONE_SHOT)
		input=await input_driver.call("pointer",button.get_global_rect().get_center())
	var constants: Dictionary=(router.get_script() as Script).get_script_constant_map()
	var start_id: StringName=StringName(constants.get("START_FIELD_SCENE",""))
	var entered: bool=await _wait_field(start_id)
	var reset_navigation: Dictionary=(router.call("get_navigation_state") as Dictionary).duplicate(true)
	_check(pressed.observed==true and entered,"real pointer activates normal menu reset and actual start Field")
	_check(reset_navigation.get("world_map_version")==formal_version and (reset_navigation.get("portal_return_spawns",{}) as Dictionary).is_empty(),"menu uses actual formal reset version, never claims candidate15 while canonical14")
	var intro: bool=await _normal_intro() if entered else false
	var report: Dictionary={"scope":"ACTUAL_MAIN_MENU_NEW_GAME_INPUT","complete":failures==0 and entered and intro,"normal_button_input":pressed.observed,"input":input,"actual_start_scene_id":String(start_id),"actual_reset_navigation":reset_navigation,"formal_world_version":formal_version,"candidate_reset_uses_formal_baseline":before_cutover,"formal_requires_world15":false,"world_subject_version":14,"historical_compatibility_tested":false}
	return await _current_cleanup(report)

func _current_case(id: String,index: int) -> void:
	var start: int=failures
	var router: Node=root.get_node("SceneRouter")
	var selected: bool=router.call("go_field_smart",StringName(id))
	_check(selected,"public current scene selection: "+id)
	if not selected: return
	if not await _wait_field(StringName(id)) or not await _normal_intro(): return
	var player: Node2D=field.get("_player") as Node2D
	var size: Vector2=field.get("_world_size")
	# Same public precise-position API used by the ordinary Save UI. No actor move.
	if index==0:
		# Normalize only the actual CURRENT14 ledger through its public contract,
		# exactly as the existing pre-Field fixture does. No old save is supplied.
		var raw_navigation: Dictionary=(router.call("get_navigation_state") as Dictionary).duplicate(true)
		var target_versions: Dictionary=(router.call("_city_target_versions") as Dictionary).duplicate(true)
		_check(raw_navigation.get("world_map_version")==14,"current world selected before current-format ledger initialization")
		router.call("restore_navigation_state",raw_navigation,scene_id,scene_id)
		var normalized: Dictionary=(router.call("get_navigation_state") as Dictionary).duplicate(true)
		var raw_other: Dictionary=raw_navigation.duplicate(true); raw_other.erase("local_layout_versions")
		var normalized_other: Dictionary=normalized.duplicate(true); normalized_other.erase("local_layout_versions")
		_check(raw_other==normalized_other and normalized.get("local_layout_versions")==target_versions,"current ledger inserts actual four-city versions only, no coordinate change")
		router.call("restore_navigation_state",normalized,scene_id,scene_id)
		_check(router.call("get_navigation_state")==normalized,"current native ledger normalization is idempotent")
	router.call("set_field_return_spawn",player.position/size)
	var directory: String=current_directory+"/current_%02d"%index
	var directory_ready: bool=not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)) and current_slots.call("configure_directory",directory)
	_check(directory_ready,"unique owned current-format case")
	if not directory_ready: return
	var saved: bool=current_slots.call("save_to_slot",0)
	var path: String=current_slots.call("slot_path",0)
	var original: Dictionary=_read_current(path)
	var input_sha: String=FileAccess.get_sha256(path)
	var navigation: Dictionary=original.get("navigation",{})
	_check(saved and original.get("version")==14 and original.get("current_field")==id and navigation.get("world_map_version")==14,"real schema14/world14/city3 current input, not historic template")
	for city: String in CITY_IDS: _check((navigation.get("local_layout_versions",{}) as Dictionary).get(city)==3,"current navigation explicitly keeps city3: "+city)
	var loaded: bool=current_slots.call("load_from_slot",0,scene_id)
	var loaded_nav: Dictionary=(router.call("get_navigation_state") as Dictionary).duplicate(true)
	_check(loaded and _navigation_matches(navigation,loaded_nav),"first current load no navigation repair or scaling")
	var births: Array[Dictionary]=[]
	if loaded:
		router.call("resume_current_field")
		births.append(await _birth(id,navigation))
	var second_saved: bool=current_slots.call("save_to_slot",1)
	var repeated_path: String=current_slots.call("slot_path",1)
	var repeated: Dictionary=_read_current(repeated_path)
	var repeated_nav: Dictionary=repeated.get("navigation",{})
	var first_state_preserved: bool=_state_payload(original)==_state_payload(repeated)
	_check(second_saved and first_state_preserved and repeated_nav==navigation,"actual first Field birth preserves every serialized gameplay domain and exact saved navigation")
	var reloaded: bool=current_slots.call("load_from_slot",1,scene_id)
	var reloaded_nav: Dictionary=(router.call("get_navigation_state") as Dictionary).duplicate(true)
	var repeat_no_remap: bool=reloaded and _navigation_matches(navigation,reloaded_nav)
	_check(repeat_no_remap,"second current-format actual load is no-remap identity")
	if reloaded:
		router.call("resume_current_field")
		births.append(await _birth(id,repeated_nav))
	var final_saved: bool=current_slots.call("save_to_slot",2)
	var final_path: String=current_slots.call("slot_path",2)
	var final: Dictionary=_read_current(final_path)
	var state_preserved: bool=first_state_preserved and _state_payload(original)==_state_payload(final)
	_check(final_saved and state_preserved and final.get("navigation")==navigation,"second real Field birth and save preserve state/coordinates")
	_check(FileAccess.get_sha256(path)==input_sha,"original current input bytes immutable through two actual loads")
	var birth_ok: bool=births.size()==2
	for row: Dictionary in births: birth_ok=birth_ok and row.get("raw_full_feet_clear")==true and row.get("actual_Physics_clear")==true and row.get("position_matches_saved")==true
	var domain: String="world" if id==String(scene_id) else "city" if id in CITY_IDS else "outskirts" if id in LOCAL_IDS else "ordinary"
	current_records.append({"scene_id":id,"domain":domain,"saved":saved,"loaded":loaded,"actual_Field_birth":birth_ok,"reloaded":reloaded,"actual_birth_full_feet_clear":birth_ok,"repeat_no_remap":repeat_no_remap,"state_preserved":state_preserved,"input_path":path,"input_sha256":input_sha,"repeated_path":repeated_path,"repeated_sha256":FileAccess.get_sha256(repeated_path),"final_path":final_path,"final_sha256":FileAccess.get_sha256(final_path),"navigation_before":navigation,"loaded_navigation":loaded_nav,"reloaded_navigation":reloaded_nav,"births":births,"passed":failures==start})
	if id==String(scene_id):
		for version: Variant in BAD_WORLD: _unsupported(original,id,"world",version)
	elif id in CITY_IDS:
		for version: Variant in BAD_LOCAL: _unsupported(original,id,"local",version)

func _configure_ordinary(definition: SceneScript) -> bool:
	if birth_probe!=null: birth_probe.call("release"); birth_probe=null
	if ordinary_raw!=null: ordinary_raw.call("release"); ordinary_raw=null
	if definition==null or String(definition.scene_id) not in CITY_IDS or not ENCLOSURE.is_v3(definition) or not ENCLOSURE.semantic_fidelity(definition): return false
	ordinary_raw=ENCLOSURE_RAW.new()
	if not ordinary_raw.call("configure_city",definition,before_cutover_mode): return false
	birth_probe=CITY_PHYSICAL.new()
	return birth_probe.call("configure",owner_tree,field,(ordinary_raw.get("source_record") as Dictionary).duplicate(true),_check,_unused_capture)

func _ordinary_static_clear(center: Vector2) -> bool:
	return ordinary_raw!=null and birth_probe!=null and ordinary_raw.call("clear",center) and birth_probe.call("raw_clear",center)

func _unused_capture(_label: String) -> void:
	await process_frame

func run_current(tree: SceneTree,before_cutover: bool) -> Dictionary:
	_current_setup(tree,before_cutover)
	current_directory="user://world_map_v15_qa/city_only_current_%d_%d"%[Time.get_ticks_usec(),OS.get_process_id()]
	var save_script: Script=load(ISOLATED_SAVES_PATH) as Script
	current_slots=save_script.new() as Node if save_script!=null and save_script.can_instantiate() else null
	_check(current_slots!=null,"real inherited isolated SaveManager")
	if current_slots!=null: root.add_child(current_slots)
	if failures==0:
		for index in CITY_IDS.size(): await _current_case(CITY_IDS[index],index)
	var all_passed: bool=current_records.size()==4 and unknown_records.size()==20
	for row: Dictionary in current_records: all_passed=all_passed and row.get("passed")==true
	_check(all_passed,"all four city current-save/load/two-birth/state cases and20 invalid local inputs")
	var report: Dictionary={"scope":CITY_SAVE_SCOPE,"complete":failures==0 and all_passed,"world_coordinate_version":14,"city_layout_version":3,"save_schema_version":14,"scene_ids":CITY_IDS,"records":current_records.duplicate(true),"unknown_records":unknown_records.duplicate(true),"actual_save_load_field_birth":all_passed,"repeat_no_remap":all_passed,"state_preserved":all_passed,"unknown_rejected_zero_mutation":all_passed,"isolated_root":current_directory,"candidate_before_cutover":before_cutover}
	return await _current_cleanup(report)

func _current_cleanup(report: Dictionary) -> Dictionary:
	if birth_probe!=null: birth_probe.call("release"); birth_probe=null
	if ordinary_raw!=null:
		_check(ordinary_raw.call("verify_sources"),"all current ordinary source PNG bytes stable")
		ordinary_raw.call("release"); ordinary_raw=null
	if oracle!=null:
		_check(oracle.call("verify_sources"),"current world source PNG bytes stable")
		oracle.call("release"); oracle=null
	if is_instance_valid(current_slots): current_slots.queue_free(); current_slots=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for frame in 8: await process_frame
	input_driver.call("release"); input_driver=null
	_check(before_saves==_actual_saves() and root.get_node("SaveManager").get("active_slot")==prior_slot,"all fifteen normal player paths and public active slot unchanged")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==CURRENT_ENGINE_SHA,"actual frozen engine/WASAPI/ordinary clock through current-format cleanup")
	report.merge({"fresh_start_only":true,"historical_compatibility_tested":false,"world_subject_version":14,"city_layout_version":3,"formal_approved":false},true)
	report["checks"]=checks+1
	report["failures"]=failures
	report["complete"]=report.get("complete")==true and failures==0
	report["player_saves_unchanged"]=before_saves==_actual_saves()
	report["executing_script_path"]=get_script().resource_path
	report["executing_script_sha256"]=FileAccess.get_sha256(get_script().resource_path)
	_check(_write_json("result.json",report),"current-format result checked persistence")
	report.checks=checks; report.failures=failures; report.complete=report.complete and failures==0
	return report

