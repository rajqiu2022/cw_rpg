extends "res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd"
## LIMITED six-roof actual Field source/display binding; no full-city approval.
const FOCUS_PROBE_PATH := "res://tests/helpers/luoyang_roof_source_display_actual_probe_20261011.gd"
const FOCUS_PROBE_SHA := "527bbc8917fcd479feb0042956dc99776645f2d692008ea68918941addd68aaa"
const PROOF_SOURCE_PATH := "res://tests/helpers/luoyang_enclosure_v11_roof_front_proof_20261009.gd"
const FOCUS_PARENT_PATH := "res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd"
const FINE_PARENT_PATH := "res://tests/helpers/joint_v15_wall_v5_fine_alpha_probe.gd"
const FINE_PARENT_SHA := "8950ddbf02416cffa4e608d68938cbab2051ff3ebcd1afa7478614a1d2fa31dc"
const FOCUS_ID := "ch4_s1_luoyang_yamen"
const FIXED_SIX: Array[String]=["v11_yamen_west_south_1520","v11_yamen_west_south_1360","v11_yamen_west_north_780","v11_yamen_east_south_1520","v11_yamen_east_south_1360","v11_yamen_east_north_780"]
var focus_field: Control
var focus_probe: RefCounted
var focus_raw: RefCounted
var source_proof: RefCounted
var focus_report: Dictionary={}

static func fixture_sources() -> Array[String]:
	return [FOCUS_PROBE_PATH,PROOF_SOURCE_PATH,FOCUS_PARENT_PATH,FINE_PARENT_PATH,RAW_PATH,CONTRACT_PATH,BRIDGE_PATH,
		"res://tests/test_luoyang_enclosure_v11_six_roof_actual_20261009.gd","res://tests/test_luoyang_roof_source_display_actual_20261011.gd","res://tests/helpers/luoyang_roof_source_display_adapter_20261011.gd","res://tests/helpers/luoyang_enclosure_v11_fade_native_npc_band_probe_20261010.gd",
		"res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd","res://scripts/city/luoyang_enclosure_building_fade_preview_20261010.gd","res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd","res://scripts/field/npc_node.gd","res://scripts/field/player.gd",
		"res://scripts/autoload/scene_router.gd","res://scripts/city/luoyang_layered_v3_contract.gd",
		"res://data/scenes/world_map_jianghu.tres","res://data/config/outskirts_native_adoption.json",
		"res://data/scenes/ch4_s0_luoyang_gate.tres","res://data/scenes/ch4_s1_luoyang_yamen.tres","res://data/scenes/ch4_s2_canal_docks.tres","res://data/scenes/ch4_s3_luoyang_market.tres"]

func _wait_focus() -> bool:
	var deadline: int=Time.get_ticks_msec()+60000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		var loader: Node=root.get_node_or_null("LoadingManager")
		if loader!=null and loader.get("_transition_active")==true: continue
		var node: Node=current_scene
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_script()==null or node.get_script().resource_path!="res://scripts/field/field_walkable_controller.gd": continue
		var definition: SceneScript=node.get("_current_scene") as SceneScript
		if definition==null or definition.scene_id!=StringName(FOCUS_ID) or not is_instance_valid(node.get("_player")) or node.get("_scene_rebuilding")==true: continue
		await physics_frame
		if current_scene!=node or not is_instance_valid(node) or node.is_queued_for_deletion(): continue
		focus_field=node as Control
		return true
	return false

func _focus_capture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	await process_frame
	var texture: Texture2D=root.get_texture()
	var image: Image=texture.get_image() if texture!=null else null
	_check(label.is_valid_identifier() and image!=null and image.save_png(output+label+".png")==OK,"actual focused GPU capture "+label)

func _run() -> void:
	# Same public protective contract as the city-only entry, before all awaits.
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): quit(1); return
	var default: Variant=bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	players=_normal_files(); slot=root.get_node("SaveManager").get("active_slot")
	checkpoint={"default_suspended":default,"before_any_await":bridge.call("is_checkpoint_saves_suspended"),"automatic_checkpoint_saves_tested":false,"restored_before_exit":false}
	_check(typeof(default)==TYPE_BOOL and not default and checkpoint.before_any_await==true and FileAccess.get_sha256(BRIDGE_PATH)==BRIDGE_SHA,"exact public checkpoint protection")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check("--luoyang-roof-source-display-actual" in args and "--fresh-start-only" in args and "--luoyang-enclosure-v11-candidate" in args and "--luoyang-v3-candidate" in args and not "--activate" in args and not "--qa-phase=release" in args,"explicit limited six-roof fresh candidate scope")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"actual ordinary WASAPI/executable")
	output="res://build/joint_world_luoyang_20261003_qa/roof_source_display_actual_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique limited output"): quit(1); return
	for path: String in fixture_sources(): _track(path)
	var scripts: Dictionary={}
	for path: String in [FOCUS_PROBE_PATH,PROOF_SOURCE_PATH,RAW_PATH,CONTRACT_PATH]:
		var script: Script=load(path) as Script
		_check(script!=null and script.can_instantiate(),"actual focused load/can_instantiate "+path)
		scripts[path]=script
	_check(FileAccess.get_sha256(FINE_PARENT_PATH)==FINE_PARENT_SHA,"immutable original fine-alpha source exact")
	_check(FileAccess.get_sha256(FOCUS_PROBE_PATH)==FOCUS_PROBE_SHA,"exact new focused consumer source")
	if failed==0:
		source_proof=(scripts[PROOF_SOURCE_PATH] as Script).new()
		_check(source_proof.call("prepare")==true,"complete six source/import and40/240 before initial source guard")
		for path: String in source_proof.get("sources"): _track(path)
		focus_raw=(scripts[RAW_PATH] as Script).new()
		var record: Dictionary=focus_raw.call("independent_record",StringName(FOCUS_ID))
		_check(not record.is_empty(),"actual independently pinned entire yamen author record")
		if not record.is_empty():
			for path: String in record.asset_sha256:
				_track(path)
				if path.get_extension()=="png" and FileAccess.file_exists(path+".import"):
					_track(path+".import")
					var config:=ConfigFile.new()
					_check(config.load(path+".import")==OK,"current actual PNG import config")
					var remap: Variant=config.get_value("remap","path",null)
					if typeof(remap)==TYPE_STRING: _track(remap)
					else: _check(false,"current actual PNG compiled path typed")
			for key: String in ["enclosure_patch_path","enclosure_base_manifest_path","ground_capture_path"]:
				if typeof(record.get(key))==TYPE_STRING: _track(record[key])
			var patch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(record.enclosure_patch_path))
			_track(String(patch.export_plan_path))
		for path: String in [(scripts[CONTRACT_PATH] as Script).call("candidate_path",StringName(FOCUS_ID)),(scripts[CONTRACT_PATH] as Script).call("layout_path",StringName(FOCUS_ID))]: _track(path)
	first=_snapshot(); _check(_write("source_before.json",first),"source protection precedes any actual fixture/await")
	if failed==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		var state: Node=root.get_node("GameState")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: state.call("set_flag",StringName(flag),true)
		state.set("current_chapter",4)
		_check(root.get_node("SceneRouter").call("go_field_smart",StringName(FOCUS_ID),null,"",-1,3)==true,"public actual city route accepted")
		_check(await _wait_focus(),"actual production yamen Field ready")
		if failed==0:
			_check(focus_raw.call("configure_city",focus_field.get("_current_scene"),true)==true,"current definition bound to full independent author/layout")
			focus_probe=(scripts[FOCUS_PROBE_PATH] as Script).new()
			_check(focus_probe.call("configure",self,focus_field,focus_raw.get("source_record"),_check,_focus_capture)==true,"full manifest/all solids/875+17 actual Physics configured")
			if failed==0:
				await focus_probe.call("run_six_roofs")
				focus_report=(focus_probe.get("data") as Dictionary).duplicate(true)
				var seen: Dictionary={}
				for row: Dictionary in focus_report.objects:
					_check(row.id in FIXED_SIX and not seen.has(row.id),"fixed unique actual roof record "+str(row.id)); seen[row.id]=true
					_check(row.alpha.get("complete")==true and (row.alpha.get("records",[]) as Array).size()==2,"behind/front actual two records "+str(row.id))
				_check(seen.size()==6,"all six focused actual objects, never successful subset")
	await _finish_focus()

func _finish_focus() -> void:
	if focus_probe!=null: focus_probe.call("release"); focus_probe=null
	if focus_raw!=null: _check(focus_raw.call("verify_sources")==true,"all raw source assets final exact"); focus_raw.call("release"); focus_raw=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	focus_field=null
	for tick: int in 8: await process_frame
	var grace: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-grace<9000000: await process_frame
	root.get_node("AudioManager").call("stop_bgm",.15)
	var drain: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-drain<250000: await process_frame
	for shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for tick: int in 4: await process_frame
	if source_proof!=null: _check(source_proof.call("unchanged")==true,"40strip/240frame six PNG import compiled inputs unchanged after last await"); source_proof.call("release"); source_proof=null
	var last: Dictionary=_snapshot()
	_check(first==last,"all source/assets first/last SHA bytes mtime unchanged")
	_check(players==_normal_files() and slot==root.get_node("SaveManager").get("active_slot"),"15 player files and active slot unchanged")
	_check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true and AudioServer.get_driver_name()=="WASAPI" and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA and Engine.time_scale==1.,"checkpoint remains suspended and actual driver/engine/time exact")
	var result: Dictionary={"scope":"SIX_ROOF_SOURCE_RGBA_ALL240_BOUND_RUNTIME_DISPLAY_LIMITED_ACTUAL_FIELD_NOT_APPROVAL","complete":failed==0 and (focus_report.get("objects",[]) as Array).size()==6,"checks":checks+1,"failures":failed,"actual":focus_report,"source_before":first,"source_after":last,"players_before":players,"players_after":_normal_files(),"active_slot_before":slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"checkpoint_suspension":checkpoint,"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"all_city_routes_tested":false,"all_city_objects_tested":false,"gameplay_save_tested":false,"world_full_tested":false,"historical_compatibility_tested":false,"formal_approved":false,"original412FAIL_unchanged":true,"original476_479FAIL_unchanged":true,"outer_precise_UTCtick_and_stderr_review_required":true}
	_check(_write("result.json",result),"limited actual final report readback")
	print("ROOF_SOURCE_DISPLAY_ACTUAL_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failed))
	quit(0 if failed==0 else 1)
