extends "res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd"
## GPU diagnostic scope ONLY one complete original yamen region.
## Retains original failed assertions; OS1 if any original trial fails.
const SELF_PATH := "res://tests/test_luoyang_yamen_original_stop_diagnostic_20261010.gd"
const DIAG_PATH := "res://tests/helpers/luoyang_yamen_original_stop_diagnostic_probe_20261010.gd"
const DIAG_SHA := "5fdd4f040a18013819bada8d81aa301c6946492e9fdf9d9a3258936009976b55"
const INVENTORY := "res://build/joint_world_luoyang_20261003_qa/428_luoyang_finite_source_inventory_retry3_20261009/source_inventory.json"
const INVENTORY_SHA := "7cc2ef19ae0329dbea384ee8084ed75fcff75b0eb9c0cba3ca1d6ab455ed0c23"
const SUBJECT := "ch4_s1_luoyang_yamen"
const TARGET := "v11_yamen_west_north_940"
const DIAGNOSTIC_SCOPE := "YAMEN_ORIGINAL_FOUR_ROUTES_TWENTY_OBJECTS_STOP_DIAGNOSTIC_NOT_FOUR_CITY_APPROVAL"
const PINNED := {
	"res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd":"3291a768f9cab0ca7ae8d348f4d86532c3aefb846d0749424663dcc13d07b892",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_phase.gd":"0d2d2a4ee8e4e725c8a79bf97a267b042b80bbeaf356bc3a93cd153d842b1efd",
	"res://tests/helpers/luoyang_enclosure_v11_native_npc_band_probe_20261009.gd":"5c913322c10cb3e7dd593abbcdd2b34e005f29f26d6a5841ae0b9cbad7fc9667",
	"res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd":"40b42c901ef05ac1971ccaae9ba049b60cfe439baea8778f796f978c4bd54450",
	"res://tests/helpers/luoyang_enclosure_v11_roof_front_actual_probe_20261009.gd":"6c19ac175b452419eb2a2790c3106d823ae8641122dd35a3fbb4f93c2c47301d",
	"res://tests/helpers/joint_v15_wall_v5_fine_alpha_probe.gd":"8950ddbf02416cffa4e608d68938cbab2051ff3ebcd1afa7478614a1d2fa31dc",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"558a3edfaa368ff52b67ff0eaade7505191011928c2a724897efc727e43887f6",
	"res://scripts/field/field_walkable_controller.gd":"1eb104fa0e321f7d4c361996639ae882340ec029ce5aed14e17b2d6a711dd740",
	"res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd":"f926cf876da1afe746411ff5a007a49894b191040e57e709bdbc486021b3e535",
	"res://scripts/city/luoyang_city3_motion_guard_20261009.gd":"aacd53e5020bc5a40353d9cf7537662c44139fa7f861e3a54c6faf59e8ba3a93",
	"res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd":"6ad7b6be15fd23ea4f8356c111c5a5a6c54c8e1ec7496083597d01e904711c62",
	"res://data/scenes/world_map_jianghu.tres":"838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015",
	"res://data/maps/world_map_jianghu_layout_v14.tres":"3dfa1f251b5a5319b8cc6d6b902932fde6382470ae597c697e391252e98f2b3b"
}
var diagnostic_phase: RefCounted
var evidence: Dictionary={}
var initial_nav: Dictionary={}
var field_was_opened: bool=false

static func fixture_sources() -> Array[String]:
	return [SELF_PATH,DIAG_PATH,INVENTORY,
		"res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd",
		"res://tests/helpers/luoyang_enclosure_v11_city_only_phase.gd",
		"res://tests/helpers/luoyang_enclosure_v11_native_npc_band_probe_20261009.gd",
		"res://data/scenes/world_map_jianghu.tres",
		"res://data/maps/world_map_jianghu_layout_v14.tres",
		"res://data/scenes/ch4_s0_luoyang_gate.tres","res://data/scenes/ch4_s1_luoyang_yamen.tres",
		"res://data/scenes/ch4_s2_canal_docks.tres","res://data/scenes/ch4_s3_luoyang_market.tres"]

func _track(path: String) -> void:
	if path.is_empty() or paths.has(path): return
	if not _check(FileAccess.file_exists(path),"required diagnostic source exists "+path): return
	paths[path]=true
	if path.get_extension()!="gd": return
	var expression:=RegEx.new()
	expression.compile('res://[^"\\r\\n]+[.]gd(?=["\\r\\n])')
	for source_match: RegExMatch in expression.search_all(FileAccess.get_file_as_string(path)): _track(source_match.get_string())

func _inventory_sources() -> void:
	_check(FileAccess.get_sha256(INVENTORY)==INVENTORY_SHA,"fixed finite428 path inventory, not old digest credit")
	var parser:=JSON.new()
	if not _check(parser.parse(FileAccess.get_file_as_string(INVENTORY))==OK and parser.data is Dictionary,"inventory dictionary parse"): return
	var rows: Variant=parser.data.get("sources")
	if not _check(rows is Array and rows.size()==4614,"bounded current path inventory exact4614"): return
	var prefix: String=ProjectSettings.globalize_path("res://").replace("\\","/").trim_suffix("/")
	var project_prefix: String=prefix.get_base_dir()+"/"
	for row: Variant in rows:
		if not _check(row is Dictionary and typeof(row.get("path"))==TYPE_STRING,"actual inventory leaf path typed"): continue
		var path: String=String(row.path).replace("\\","/")
		if not _check(path.begins_with(project_prefix) and "/../" not in path,"project leaf domain, no traversal"): continue
		if path.begins_with(prefix+"/"): path="res://"+path.trim_prefix(prefix+"/")
		_track(path)
	# Snapshot every listed leaf freshly this run, never import the inventory SHA
	# as a before snapshot. ROOT must supply these paths before engine startup.
	_track(INVENTORY)
	for path: String in fixture_sources(): _track(path)
	for path: String in PINNED: _track(path); _check(FileAccess.get_sha256(path)==PINNED[path],"frozen diagnostic consumer "+path)


func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): quit(1); return
	var default: Variant=bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	players=_normal_files(); slot=root.get_node("SaveManager").get("active_slot")
	checkpoint={"default_suspended":default,"before_any_await":bridge.call("is_checkpoint_saves_suspended"),"restored_before_exit":false,"automatic_checkpoint_saves_tested":false}
	_check(typeof(default)==TYPE_BOOL and not default and checkpoint.before_any_await==true and FileAccess.get_sha256(BRIDGE_PATH)==BRIDGE_SHA,"public checkpoint suspended before fixture/all awaits")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	var legal: Array[String]=["--luoyang-yamen-original-stop-diagnostic","--fresh-start-only","--luoyang-v3-candidate","--luoyang-enclosure-v11-candidate","--qa-gpu-approved"]
	_check(args.size()==legal.size(),"only explicit bounded original yamen diagnostic arguments")
	for arg: String in legal: _check(args.count(arg)==1,"unique required diagnostic flag "+arg)
	_check(DisplayServer.get_name()!="headless" and AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"real GPU/WASAPI/executable/ordinary time")
	output="res://build/joint_world_luoyang_20261003_qa/yamen_original_stop_diagnostic_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique diagnostic output"): quit(1); return
	_inventory_sources()
	_check(FileAccess.get_sha256(DIAG_PATH)==DIAG_SHA,"NEW read-only collision appendix exact source")
	var scripts: Dictionary={}
	for path: String in [PHASE_PATH,RAW_PATH,DIAG_PATH]:
		var script: Script=load(path) as Script
		_check(script!=null and script.can_instantiate(),"diagnostic load/can_instantiate "+path)
		scripts[path]=script
	var reader: RefCounted
	var record: Dictionary={}
	if failed==0:
		reader=(scripts[RAW_PATH] as Script).new()
		record=reader.call("independent_record",StringName(SUBJECT))
		_check(not record.is_empty(),"actual independent BASE/patch/ground author record")
		if not record.is_empty():
			_check(record.routes.size()==4 and record.objects.size()==20,"original yamen complete four routes/twenty objects")
			for path: String in record.asset_sha256: _track(path)
			_track(String(record.enclosure_patch_path)); _track(String(record.ground_capture_path))
	if reader!=null: reader.call("release"); reader=null
	first=_snapshot()
	_check(_write("source_before.json",first),"all unique fresh sources before first await")
	if failed==0:
		diagnostic_phase=(scripts[PHASE_PATH] as Script).new()
		diagnostic_phase.set("tree",self); diagnostic_phase.set("candidate",true); diagnostic_phase.set("output",output)
		diagnostic_phase.set("before_files",diagnostic_phase.call("_normal_files"))
		diagnostic_phase.set("before_slot",slot)
		var input: RefCounted=load("res://tests/helpers/v15_input_driver.gd").new()
		input.call("configure",self); diagnostic_phase.set("driver",input)
		diagnostic_phase.call("_public_fixture",{})
		var router: Node=root.get_node("SceneRouter")
		router.call("reset_for_new_game")
		router.call("restore_navigation_state",router.call("get_navigation_state"),&"",&"world_map_jianghu")
		initial_nav=(router.call("get_navigation_state") as Dictionary).duplicate(true)
		diagnostic_phase.set("before_nav",initial_nav.duplicate(true))
		_check(initial_nav.get("world_map_version")==14 and String(router.call("get_active_world_map_scene"))=="world_map_jianghu","unchanged formal world14 navigation baseline")
		evidence["initial_navigation"]=initial_nav.duplicate(true)
		diagnostic_phase.call("_connect_events")
		# Same original second process fixture immediately before the sole region.
		diagnostic_phase.call("_public_fixture",{})
		field_was_opened=await diagnostic_phase.call("_open",SUBJECT)
		_check(field_was_opened,"original phase normal public Field entry/binding")
		if field_was_opened:
			var original_probe: RefCounted=diagnostic_phase.get("probe") as RefCounted
			original_probe.call("release")
			var probe: RefCounted=(scripts[DIAG_PATH] as Script).new()
			diagnostic_phase.set("probe",probe)
			var configured: bool=probe.call("configure",self,diagnostic_phase.get("field"),diagnostic_phase.get("manifest"),Callable(diagnostic_phase,"_check"),Callable(diagnostic_phase,"_capture"))
			_check(configured and probe.call("set_diagnostic_directory",output)==true,"NEW appendix uses original full manifest/callbacks")
			if configured:
				var manifest: Dictionary=diagnostic_phase.get("manifest")
				var route_order: Array=[]; var object_order: Array=[]
				for route: Dictionary in manifest.routes: route_order.append(route.id)
				for object: Dictionary in manifest.objects: object_order.append(object.id)
				evidence["original_route_order"]=route_order; evidence["original_object_order"]=object_order
				await probe.call("run_routes")
				await probe.call("run_objects")
				var data: Dictionary=(probe.get("data") as Dictionary).duplicate(true)
				evidence["physical_and_current_alpha"]=data
				evidence["immediate_collision_receipts"]=(probe.get("collision_receipts") as Array).duplicate(true)
				_check(data.routes.size()==4 and data.objects.size()==20,"all original four routes/twenty objects completed without subset")
				var actual_order: Array=[]
				for object: Dictionary in data.objects: actual_order.append(object.id)
				_check(actual_order==object_order,"original object sequence preserved")
				var targets: Array=[]
				for row: Dictionary in probe.get("collision_receipts"):
					if row.id==TARGET: targets.append(row)
				_check(targets.size()==1,"unique immediate original940 collision receipt")
	await _finish_diagnostic()

func _finish_diagnostic() -> void:
	if diagnostic_phase!=null:
		if field_was_opened: await diagnostic_phase.call("natural_field_grace","yamen_diagnostic_before_actual_cleanup")
		evidence["natural_grace"]=(diagnostic_phase.get("natural_grace_records") as Array).duplicate(true)
		var bus: Node=root.get_node("EventBus")
		for row: Dictionary in diagnostic_phase.get("event_connections"):
			if bus.is_connected(row.signal,row.callable): bus.disconnect(row.signal,row.callable)
		(diagnostic_phase.get("event_connections") as Array).clear()
		var raw: RefCounted=diagnostic_phase.get("raw") as RefCounted
		if raw!=null: _check(raw.call("verify_sources")==true,"last independent yamen source verification")
		diagnostic_phase.call("_release_field_oracles")
		var phase_field: Node=diagnostic_phase.get("field") as Node
		var reference: WeakRef=weakref(phase_field) if is_instance_valid(phase_field) else null
		if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
		diagnostic_phase.set("field",null)
		for tick in 8: await process_frame
		_check(reference==null or reference.get_ref()==null,"owned original Field released normally")
		_check(diagnostic_phase.call("_normal_files")==diagnostic_phase.get("before_files") and root.get_node("SaveManager").get("active_slot")==slot,"original phase all player paths/slot unchanged")
		evidence["original_phase_checks"]=diagnostic_phase.get("checks")
		evidence["original_phase_failures"]=diagnostic_phase.get("failures")
		_check(diagnostic_phase.get("failures")==0,"original phase failures preserved; diagnostic cannot green an original FAIL")
		var driver: RefCounted=diagnostic_phase.get("driver") as RefCounted
		if driver!=null: driver.call("release"); diagnostic_phase.set("driver",null)
		diagnostic_phase=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	if not initial_nav.is_empty():
		var router: Node=root.get_node("SceneRouter")
		router.call("reset_for_new_game")
		router.call("restore_navigation_state",router.call("get_navigation_state"),&"",&"world_map_jianghu")
		_check(router.call("get_navigation_state")==initial_nav,"original public current-format navigation baseline restored")
	for tick in 8: await process_frame
	var grace: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-grace<9000000: await process_frame
	root.get_node("AudioManager").call("stop_bgm",.15)
	var drain: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-drain<250000: await process_frame
	for shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for tick in 4: await process_frame
	var last: Dictionary=_snapshot()
	_check(first==last,"all fresh consumed source/import/compiled bytes/SHA/mtime after last await")
	_check(players==_normal_files() and slot==root.get_node("SaveManager").get("active_slot"),"all15 normal player paths and slot; outer exact UTCticks required")
	_check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true and AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"checkpoint throughquit/actual audio/engine/time")
	var result: Dictionary={"scope":DIAGNOSTIC_SCOPE,"complete":failed==0 and field_was_opened,"checks":checks+1,"failures":failed,"evidence":evidence,"source_before":first,"source_after":last,"players_before":players,"players_after":_normal_files(),"active_slot_before":slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"checkpoint_suspension":checkpoint,"actual_audio_driver":AudioServer.get_driver_name(),"actual_display_driver":DisplayServer.get_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"geometry_full_four_city_pass_claimed":false,"gameplay_pass_claimed":false,"visual_approved":false,"formal_approved":false,"original443_failure_changed":false,"historical_compatibility_tested":false,"world_subject_version":14,"world_full_tested":false,"outer_prelaunch_exact_UTCticks_and_complete_stderr_review_required":true}
	_check(_write("result.json",result),"unique diagnostic final checked readback")
	print("YAMEN_ORIGINAL_STOP_DIAGNOSTIC_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failed))
	quit(0 if failed==0 else 1)
