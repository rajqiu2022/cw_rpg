extends "res://tests/helpers/joint_v15_release_world_prepared_phase.gd"
## Current-format only: real menu input and real isolated SaveManager/Field births.
## Inherited readers retain full17/source solids, city875 and actual Player Physics.
## No historical coordinate fixture, ordinary player slot or production resource write.
const FRESH_SCOPE: String="JOINT_FRESH_START_CURRENT_FORMAT_ACTUAL_FIELD_INPUT"
const FROZEN_SCOPE: String="JOINT_FROZEN_FRESH_START_CURRENT_FORMAT_INPUTS"
const SAVE_SCOPE: String="CURRENT_FORMAT_SAVE_LOAD_FIELD_BIRTH_NO_HISTORICAL_COMPATIBILITY"
const ORDINARY_IDS: Array[String]=["openworld_bianzhou_city","openworld_wudang_gate","linxi_village_scrollmap"]
const LOCAL_IDS: Array[String]=["openworld_v15_bamboo_outskirts","openworld_v15_forest_outskirts","openworld_v15_marsh_outskirts"]
const BAD_WORLD: Array=[-1,16,99,15.5,"15",true]
const BAD_LOCAL: Array=[2,99,1.5,"3",true]
const CURRENT_ENGINE_SHA: String="975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
var current_records: Array[Dictionary]=[]
var unknown_records: Array[Dictionary]=[]
var current_slots: Node
var current_directory: String=""

static func mode_metadata() -> Dictionary:
	return {"fresh_start_only":true,"historical_compatibility_tested":false,"excluded_historical_versions":{"world":[12,13,14],"local":[1]},"excluded_world_source_versions":[12,13,14],"excluded_local_source_versions":[1]}

static func frozen_mode_matches(value: Variant,fresh: bool) -> bool:
	if not value is Dictionary or typeof(value.get("scope"))!=TYPE_STRING: return false
	if not fresh: return value.scope=="JOINT_FROZEN_CANDIDATE_INPUTS" and not value.has("fresh_start_only")
	if value.scope!=FROZEN_SCOPE: return false
	for key: String in mode_metadata():
		if not value.has(key) or not _mode_equal(value[key],mode_metadata()[key]): return false
	return true

static func _mode_equal(a: Variant,b: Variant) -> bool:
	# JSON integers may be Float64, but booleans/strings are never coerced.
	if typeof(b) in [TYPE_INT,TYPE_FLOAT]: return typeof(a) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(a)) and float(a)==float(b)
	if typeof(a)!=typeof(b): return false
	if b is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in b:
			if not a.has(key) or not _mode_equal(a[key],b[key]): return false
		return true
	if b is Array:
		if a.size()!=b.size(): return false
		for index in b.size():
			if not _mode_equal(a[index],b[index]): return false
		return true
	return a==b

static func case_ids(before_cutover: bool) -> Array[String]:
	var ids: Array[String]=["world_map_jianghu_v15" if before_cutover else "world_map_jianghu"]
	ids.append_array(CITY_IDS)
	ids.append_array(ORDINARY_IDS)
	ids.append_array(LOCAL_IDS)
	return ids

static func current_report_matches(value: Variant,before_cutover: bool) -> bool:
	if not value is Dictionary or typeof(value.get("scope"))!=TYPE_STRING or value.scope!=SAVE_SCOPE: return false
	for key: String in mode_metadata():
		if not value.has(key) or not _mode_equal(value[key],mode_metadata()[key]): return false
	for key: String in ["complete","actual_save_load_field_birth","repeat_no_remap","state_preserved","unknown_rejected_zero_mutation","player_saves_unchanged"]:
		if typeof(value.get(key))!=TYPE_BOOL or value[key]!=true: return false
	if not _mode_equal(value.get("world_coordinate_version"),15) or not _mode_equal(value.get("city_layout_version"),3) or not _mode_equal(value.get("save_schema_version"),14) or not _mode_equal(value.get("failures"),0): return false
	if not _mode_equal(value.get("scene_ids"),case_ids(before_cutover)) or not value.get("records") is Array or value.records.size()!=11 or not value.get("unknown_records") is Array or value.unknown_records.size()!=26: return false
	var seen: Dictionary={}
	for row: Variant in value.records:
		if not row is Dictionary or typeof(row.get("scene_id"))!=TYPE_STRING or row.scene_id not in case_ids(before_cutover) or seen.has(row.scene_id): return false
		seen[row.scene_id]=true
		for key: String in ["saved","loaded","actual_Field_birth","reloaded","actual_birth_full_feet_clear","repeat_no_remap","state_preserved","passed"]:
			if typeof(row.get(key))!=TYPE_BOOL or row[key]!=true: return false
		if not row.get("births") is Array or row.births.size()!=2: return false
		for birth: Variant in row.births:
			if not birth is Dictionary or typeof(birth.get("scene_id"))!=TYPE_STRING or birth.scene_id!=row.scene_id: return false
			for key: String in ["raw_full_feet_clear","actual_Physics_clear","position_matches_saved"]:
				if typeof(birth.get(key))!=TYPE_BOOL or birth[key]!=true: return false
		for key: String in ["navigation_before","loaded_navigation","reloaded_navigation"]:
			if not row.get(key) is Dictionary or not _mode_equal(row[key].get("world_map_version"),15) or typeof(row[key].get("current_field"))!=TYPE_STRING or row[key].current_field!=row.scene_id: return false
			for city: String in CITY_IDS:
				if not row[key].get("local_layout_versions") is Dictionary or not _mode_equal(row[key].local_layout_versions.get(city),3): return false
	var unknown: Dictionary={}
	for row: Variant in value.unknown_records:
		if not row is Dictionary or typeof(row.get("scene_id"))!=TYPE_STRING or typeof(row.get("version_domain"))!=TYPE_STRING or typeof(row.get("loaded"))!=TYPE_BOOL or row.loaded!=false or typeof(row.get("zero_mutation"))!=TYPE_BOOL or row.zero_mutation!=true: return false
		var versions: Array=BAD_WORLD if row.version_domain=="world" else BAD_LOCAL if row.version_domain=="local" else []
		if versions.is_empty() or (row.version_domain=="world" and row.scene_id!=case_ids(before_cutover)[0]) or (row.version_domain=="local" and row.scene_id not in CITY_IDS): return false
		var version_index: int=-1
		for index in versions.size():
			if _mode_equal(row.get("version"),versions[index]): version_index=index; break
		var identity: String=row.scene_id+"/"+row.version_domain+"/"+str(version_index)
		if version_index<0 or unknown.has(identity) or not row.get("before") is Dictionary or not row.get("after") is Dictionary or row.before!=row.after: return false
		unknown[identity]=true
	return seen.size()==11 and unknown.size()==26

func _current_setup(tree: SceneTree,before_cutover: bool) -> void:
	owner_tree=tree
	scene_id=&"world_map_jianghu_v15" if before_cutover else &"world_map_jianghu"
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
	_check(before_cutover or formal_version==15,"formal fresh NewGame requires actual canonical world15")
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
	var report: Dictionary={"scope":"ACTUAL_MAIN_MENU_NEW_GAME_INPUT","complete":failures==0 and entered and intro,"normal_button_input":pressed.observed,"input":input,"actual_start_scene_id":String(start_id),"actual_reset_navigation":reset_navigation,"formal_world_version":formal_version,"candidate_reset_uses_formal_baseline":before_cutover,"formal_requires_world15":true,"historical_compatibility_tested":false}
	return await _current_cleanup(report)

func _json_copy(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value,"\t",true))

func _read_current(path: String) -> Dictionary:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return parsed as Dictionary if parsed is Dictionary else {}

func _state_payload(data: Dictionary) -> Dictionary:
	var state: Dictionary=data.duplicate(true)
	for key: String in ["timestamp","slot","navigation","current_field"]: state.erase(key)
	return state

func _navigation_matches(saved: Dictionary,actual: Dictionary) -> bool:
	# Exactly one original default JSON writer boundary for the LIVE expectation.
	# The saved dictionary is neither cast nor rounded to hide modifications.
	return saved==_json_copy(actual)

func _birth(id: String,saved_navigation: Dictionary) -> Dictionary:
	var entered: bool=await _wait_field(StringName(id))
	if not entered or not await _normal_intro(): return {}
	var player: Node2D=field.get("_player") as Node2D
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var size: Vector2=field.get("_world_size")
	var expected: Vector2=_point(saved_navigation.get("current_field_spawn"))
	var raw_clear: bool=false
	if id==String(scene_id):
		raw_clear=oracle!=null and bool(oracle.call("clear",player.position))
	elif _configure_ordinary(definition): raw_clear=_ordinary_static_clear(player.position)
	var physical: bool=_physical_clear(player.position)
	var matches: bool=expected.is_finite() and size.is_finite() and size.x>0 and size.y>0 and player.position.distance_to(expected*size)<.02
	_check(raw_clear and physical and matches,"current saved Field birth exact coordinate/fullfeet/actualPhysics: "+id)
	var container: Node2D=field.get("world_container") as Node2D
	var visible: Vector2=container.to_local(Vector2(player.global_position.x,float(player.call("get_depth_sort_y"))))
	return {"scene_id":id,"actor_root_px":[player.position.x,player.position.y],"world_size_px":[size.x,size.y],"expected_root_normalized":[expected.x,expected.y],"actual_root_normalized":[player.position.x/size.x,player.position.y/size.y],"raw_full_feet_clear":raw_clear,"actual_Physics_clear":physical,"position_matches_saved":matches,"layout_schema_version":definition.map_layout.schema_version,"layout_design_size_px":[definition.map_layout.design_size.x,definition.map_layout.design_size.y],"visible_foot_px":[visible.x,visible.y],"visible_offset_px":[visible.x-player.position.x,visible.y-player.position.y]}

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
		# Normalize only the actual CURRENT15 ledger through its public contract,
		# exactly as the existing pre-Field fixture does. No old save is supplied.
		var raw_navigation: Dictionary=(router.call("get_navigation_state") as Dictionary).duplicate(true)
		var target_versions: Dictionary=(router.call("_city_target_versions") as Dictionary).duplicate(true)
		_check(raw_navigation.get("world_map_version")==15,"current world selected before current-format ledger initialization")
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
	_check(saved and original.get("version")==14 and original.get("current_field")==id and navigation.get("world_map_version")==15,"real schema14/world15 current input, not historic template")
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

func _domain_snapshot() -> Dictionary:
	var game: Node=root.get_node("GameState")
	var serializer: Node=root.get_node("SaveManager")
	var state: Dictionary={"player":serializer.call("_serialize_stats",game.get("player")),"party":[],"flags":game.get("flags"),"gold":game.get("gold"),"chapter":game.get("current_chapter"),"player_faction":String(game.get("player_faction")),"skill_mastery":game.get("skill_mastery"),"pending_skill_unlocks":game.get("pending_skill_unlocks"),"training_total":game.get("training_points_total"),"training_available":game.get("training_points_available"),"reputation":game.get("reputation"),"sparring":game.call("get_sparring_records_save_data"),"navigation":root.get_node("SceneRouter").call("get_navigation_state"),"active_slot":serializer.get("active_slot"),"isolated_active_slot":current_slots.get("active_slot"),"normal_files":_actual_saves(),"audio_volumes":root.get_node("AudioManager").call("get_volumes")}
	for member: Resource in game.get("party"): (state.party as Array).append(serializer.call("_serialize_stats",member))
	for singleton: String in ["Inventory","QuestManager","BountyManager","InvestigationState","WeatherManager"]: state[singleton]=root.get_node(singleton).call("to_dict")
	return _json_copy(state)

func _unsupported(template: Dictionary,id: String,version_domain: String,version: Variant) -> void:
	var data: Dictionary=template.duplicate(true)
	if version_domain=="world": data.navigation.world_map_version=version
	else: data.navigation.local_layout_versions[id]=version
	# Deliberate application sentinels must never be applied by rejected input.
	data.gold=int(data.gold)+313
	data.flags["qa_invalid_current_format_must_not_apply"]=true
	var directory: String=current_directory+"/unsupported_%02d"%unknown_records.size()
	var directory_ready: bool=not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)) and current_slots.call("configure_directory",directory)
	_check(directory_ready,"unique unsupported current-format case")
	if not directory_ready: return
	var path: String=current_slots.call("slot_path",0)
	var encoded: String=JSON.stringify(data,"\t",true)
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	var opened: bool=file!=null
	_check(opened,"owned unsupported input open")
	if not opened: return
	file.store_string(encoded); file.flush()
	var error: Error=file.get_error()
	file.close()
	var readback_ok: bool=error==OK and _read_current(path)==JSON.parse_string(encoded)
	_check(readback_ok,"unsupported input exact checked readback")
	if not readback_ok: return
	var before: Dictionary=_domain_snapshot()
	var loaded: bool=current_slots.call("load_from_slot",0,scene_id)
	var after: Dictionary=_domain_snapshot()
	var unchanged: bool=before==after
	_check(not loaded and unchanged,"invalid current coordinate type/version rejects before any state mutation")
	unknown_records.append({"scene_id":id,"version_domain":version_domain,"version":version,"loaded":loaded,"zero_mutation":unchanged,"input_path":path,"input_sha256":FileAccess.get_sha256(path),"before":before,"after":after})

func run_current(tree: SceneTree,before_cutover: bool) -> Dictionary:
	_current_setup(tree,before_cutover)
	world=load("res://data/scenes/%s.tres"%scene_id) as SceneScript
	oracle=RAW_ORACLE.new()
	_check(world!=null and world.map_layout!=null and oracle.call("configure",world.map_layout),"independent exact current world full17 raw oracle")
	current_directory="user://world_map_v15_qa/current_format_%d_%d"%[Time.get_ticks_usec(),OS.get_process_id()]
	var save_script: Script=load(ISOLATED_SAVES_PATH) as Script
	current_slots=save_script.new() as Node if save_script!=null and save_script.can_instantiate() else null
	_check(current_slots!=null,"real inherited isolated SaveManager")
	if current_slots!=null: root.add_child(current_slots)
	if failures==0:
		var ids: Array[String]=case_ids(before_cutover)
		for index in ids.size(): await _current_case(ids[index],index)
	var all_passed: bool=current_records.size()==11 and unknown_records.size()==26
	for row: Dictionary in current_records: all_passed=all_passed and row.get("passed")==true
	_check(all_passed,"exact11 current worlds/cities/ordinary/outskirts and26 invalid current-format actual loads")
	var report: Dictionary={"scope":SAVE_SCOPE,"complete":failures==0 and all_passed,"world_coordinate_version":15,"city_layout_version":3,"save_schema_version":14,"scene_ids":case_ids(before_cutover),"records":current_records.duplicate(true),"unknown_records":unknown_records.duplicate(true),"actual_save_load_field_birth":all_passed,"repeat_no_remap":all_passed,"state_preserved":all_passed,"unknown_rejected_zero_mutation":all_passed,"isolated_root":current_directory}
	return await _current_cleanup(report)

func _current_cleanup(report: Dictionary) -> Dictionary:
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
	report.merge(mode_metadata(),true)
	report["checks"]=checks+1
	report["failures"]=failures
	report["complete"]=report.get("complete")==true and failures==0
	report["player_saves_unchanged"]=before_saves==_actual_saves()
	report["executing_script_path"]=get_script().resource_path
	report["executing_script_sha256"]=FileAccess.get_sha256(get_script().resource_path)
	_check(_write_json("result.json",report),"current-format result checked persistence")
	report.checks=checks; report.failures=failures; report.complete=report.complete and failures==0
	return report
