extends "res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd"
## GPU cause diagnostic only. Original normal INPUT, physical probe, route and
## alpha predicates remain immutable; no sorting/position/refresh intervention.
const SELF_PATH := "res://tests/test_luoyang_inn_y830_natural_alpha_diagnostic_retry1_20261009.gd"
const DIAG_PATH := "res://tests/helpers/luoyang_inn_y830_natural_alpha_diagnostic_20261009.gd"
const DIAG_SHA := "3dc5d99225999b50fb74ec8409e629e3aaed52812d2e5f11764d561f24df841e"
const INVENTORY := "res://build/joint_world_luoyang_20261003_qa/428_luoyang_finite_source_inventory_retry3_20261009/source_inventory.json"
const INVENTORY_SHA := "7cc2ef19ae0329dbea384ee8084ed75fcff75b0eb9c0cba3ca1d6ab455ed0c23"
const SUBJECT := "ch4_s3_luoyang_market"
const INN_ROUTE := "inn_and_paper"
const PINNED := {
	"res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd":"3291a768f9cab0ca7ae8d348f4d86532c3aefb846d0749424663dcc13d07b892",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"d112f9e7867d612596ab1ead2428000749ea44f62a26433a73e170480af6ec51",
	"res://scripts/field/field_walkable_controller.gd":"93a34013d42a773f0fe82c77b82ed6a2477dbedf25d771137eb1eb455cdcfb93",
	"res://scripts/city/luoyang_city3_motion_guard_20261009.gd":"aacd53e5020bc5a40353d9cf7537662c44139fa7f861e3a54c6faf59e8ba3a93",
	"res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd":"6ad7b6be15fd23ea4f8356c111c5a5a6c54c8e1ec7496083597d01e904711c62",
	"res://tests/helpers/joint_v15_wall_v5_fine_alpha_probe.gd":"8950ddbf02416cffa4e608d68938cbab2051ff3ebcd1afa7478614a1d2fa31dc",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://scripts/city/luoyang_v3_modular_overlap.gd":"70072f2993abcefd52e1ac3b71d611cbe6b72c8938f1aa60628cbb995520a99e",
	"res://scripts/world/v14_modular_overlap.gd":"92f80ed076d90be292c848cb9743130b465b71e06250e8867d24e01f02090dab",
	"res://scripts/world/outskirts_modular_overlap.gd":"3b0f36a525260e4444bdfe1f9b8d0f5323728019024caf5568b02a74a4a39fdd"
}
var inn_field: Control
var inn_raw: RefCounted
var inn_probe: RefCounted
var observed: Array[Dictionary]=[]
var evidence: Dictionary={}
var initial_nav: Dictionary={}

static func fixture_sources() -> Array[String]:
	return [SELF_PATH,"res://tests/test_luoyang_inn_y830_natural_alpha_diagnostic_20261009.gd",DIAG_PATH,INVENTORY,"res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd",
		"res://scripts/field/field_walkable_controller.gd","res://scripts/city/luoyang_city3_motion_guard_20261009.gd",
		"res://scripts/field/player.gd","res://scripts/city/luoyang_v3_modular_overlap.gd",
		"res://scripts/world/outskirts_modular_overlap.gd","res://scripts/world/v14_modular_overlap.gd"]

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

func _wait_inn() -> bool:
	var deadline: int=Time.get_ticks_msec()+60000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		var loader: Node=root.get_node_or_null("LoadingManager")
		if loader!=null and loader.get("_transition_active")==true: continue
		var node: Node=current_scene
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_script()==null or node.get_script().resource_path!="res://scripts/field/field_walkable_controller.gd": continue
		var definition: SceneScript=node.get("_current_scene") as SceneScript
		if definition==null or definition.scene_id!=StringName(SUBJECT) or not is_instance_valid(node.get("_player")) or node.get("_scene_rebuilding")==true: continue
		await physics_frame
		if current_scene==node and is_instance_valid(node) and not node.is_queued_for_deletion(): inn_field=node as Control; return true
	return false

func _unused_capture(_label: String) -> void:
	pass

func _natural_observations(label: String) -> void:
	# driver.drive/follow already finishes the exact original completed actor
	# stage. Do not refresh before the first observation or replace it later.
	for stage: int in 3:
		if stage==1: await (inn_probe.get("driver") as RefCounted).call("completed_actor_stage")
		elif stage==2: await RenderingServer.frame_post_draw
		var row: Dictionary=inn_probe.call("observe",label+"_"+str(stage))
		_check(row.get("valid")==true,"natural state actually collected "+label+"/"+str(stage))
		row["stage"]="AFTER_ORIGINAL_COMPLETED_ACTOR_STAGE" if stage==0 else "NEXT_NATURAL_COMPLETED_ACTOR_STAGE" if stage==1 else "NEXT_FRAME_POST_DRAW"
		row["later_stage_replaces_first_assertion"]=false
		row["alpha_or_geometry_pass_claimed"]=false
		observed.append(row)
		if stage==2:
			var image: Image=root.get_texture().get_image()
			var path: String=output+label+"_postdraw.png"
			_check(image!=null and image.save_png(path)==OK,"actual GPU postdraw PNG "+label)
			row["gpu_capture"]={"path":path,"sha256":FileAccess.get_sha256(path)}

func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): quit(1); return
	var default: Variant=bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	players=_normal_files(); slot=root.get_node("SaveManager").get("active_slot")
	checkpoint={"default_suspended":default,"before_any_await":bridge.call("is_checkpoint_saves_suspended"),"restored_before_exit":false,"automatic_checkpoint_saves_tested":false}
	_check(typeof(default)==TYPE_BOOL and not default and checkpoint.before_any_await==true and FileAccess.get_sha256(BRIDGE_PATH)==BRIDGE_SHA,"public checkpoint suspended before fixture/all awaits")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	var legal: Array[String]=["--luoyang-inn-y830-diagnostic","--fresh-start-only","--luoyang-v3-candidate","--luoyang-enclosure-v11-candidate","--qa-gpu-approved"]
	_check(args.size()==legal.size(),"only explicit bounded GPU diagnostic arguments")
	for arg: String in legal: _check(args.count(arg)==1,"unique required diagnostic flag "+arg)
	_check(DisplayServer.get_name()!="headless" and AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"real GPU/WASAPI/executable/ordinary time")
	output="res://build/joint_world_luoyang_20261003_qa/inn_y830_natural_alpha_diagnostic_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique diagnostic output"): quit(1); return
	_inventory_sources()
	_check(FileAccess.get_sha256(DIAG_PATH)==DIAG_SHA,"NEW read-only observer exact source")
	var scripts: Dictionary={}
	for path: String in [RAW_PATH,CONTRACT_PATH,DIAG_PATH]:
		var script: Script=load(path) as Script
		_check(script!=null and script.can_instantiate(),"diagnostic load/can_instantiate "+path); scripts[path]=script
	var record: Dictionary={}
	if failed==0:
		inn_raw=(scripts[RAW_PATH] as Script).new()
		record=inn_raw.call("independent_record",StringName(SUBJECT))
		_check(not record.is_empty(),"actual independent BASE/patch/ground author record")
	first=_snapshot()
	_check(_write("source_before.json",first),"all unique fresh sources before first await")
	if failed==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		var router: Node=root.get_node("SceneRouter")
		router.call("restore_navigation_state",router.call("get_navigation_state"),&"",&"world_map_jianghu")
		initial_nav=(router.call("get_navigation_state") as Dictionary).duplicate(true)
		_check(initial_nav.get("world_map_version")==14 and String(router.call("get_active_world_map_scene"))=="world_map_jianghu","unchanged formal world14 navigation baseline")
		evidence["initial_navigation"]=initial_nav.duplicate(true)
		var state: Node=root.get_node("GameState")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: state.call("set_flag",StringName(flag),true)
		state.set("current_chapter",4)
		_check(router.call("go_field_smart",StringName(SUBJECT),null,"",-1,3)==true,"public normal candidate market route")
		_check(await _wait_inn(),"actual production market Field")
		if failed==0:
			_check(inn_raw.call("configure_city",inn_field.get("_current_scene"),true)==true,"full actual source/layout independently bound")
			inn_probe=(scripts[DIAG_PATH] as Script).new()
			_check(inn_probe.call("configure",self,inn_field,record,_check,_unused_capture)==true,"unchanged physical/full875+17/alpha input probe")
		if failed==0:
			var route_matches: Array=[]
			for route: Dictionary in record.routes:
				if route.get("id")==INN_ROUTE: route_matches.append(route)
			_check(route_matches.size()==1,"unique original inn_and_paper route")
			var points:=PackedVector2Array()
			if route_matches.size()==1:
				for p: Variant in route_matches[0].points_px: points.append(inn_probe.call("point",p))
			_check(points==PackedVector2Array([Vector2(1000,1060),Vector2(735,920),Vector2(735,830)]),"original route all3 points unchanged")
			evidence["source_route"]=route_matches.duplicate(true)
			evidence["source_route_native_hex"]=points.to_byte_array().hex_encode()
			evidence["reference429_stage_path"]="res://build/joint_world_luoyang_20261003_qa/luoyang_enclosure_v11_city_only_1791544952_2824495_60928/stage_result.json"
			evidence["reference429_stage_SHA"]="fa6cce592a53a6b7781f034a9de0c8563bbd49511f1148345c74ffc06a334c50"
			evidence["reference429_credit_inherited"]=false
			if failed==0:
				var approach: Dictionary=await inn_probe.call("move_to",points[0])
				_check(approach.get("ok")==true,"normal INPUT reaches original route start")
				var driven: Dictionary=await (inn_probe.get("driver") as RefCounted).call("follow",inn_field,points,Callable(inn_probe,"clear"),Callable(inn_probe,"segment")) if approach.get("ok")==true else {"ok":false}
				evidence["original_route"]={"approach":approach,"drive":driven}
				_check(driven.get("ok")==true,"original normal INPUT entire route reaches830")
				if driven.get("ok")==true:
					await _natural_observations("original_route_830")
					var control: Dictionary=await (inn_probe.get("driver") as RefCounted).call("drive",inn_field,Vector2(735,832),Callable(inn_probe,"clear"))
					_check(control.get("ok")==true,"normal2px control reaches832")
					evidence["control_to832"]=control
					if control.get("ok")==true:
						await _natural_observations("control_832")
						var back: Dictionary=await (inn_probe.get("driver") as RefCounted).call("drive",inn_field,Vector2(735,830),Callable(inn_probe,"clear"))
						evidence["normal832_to830"]=back
						_check(back.get("ok")==true,"normal2px832-to830 control")
						if back.get("ok")==true: await _natural_observations("control_832_to830")
	await _finish_inn()

func _finish_inn() -> void:
	if inn_probe!=null:
		for path: String in inn_probe.get("png_bindings"):
			_check(first.has(path) and first[path].exists==true,"actually observed original PNG protected before first await "+path)
		inn_probe.call("release"); inn_probe=null
	if inn_raw!=null: _check(inn_raw.call("verify_sources")==true,"last independent market source verification"); inn_raw.call("release"); inn_raw=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	inn_field=null
	if not initial_nav.is_empty():
		var router: Node=root.get_node("SceneRouter")
		router.call("reset_for_new_game")
		router.call("restore_navigation_state",router.call("get_navigation_state"),&"",&"world_map_jianghu")
		_check(router.call("get_navigation_state")==initial_nav,"public process navigation baseline restored")
	for tick: int in 8: await process_frame
	var grace: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-grace<9000000: await process_frame
	root.get_node("AudioManager").call("stop_bgm",.15)
	var drain: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-drain<250000: await process_frame
	for shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for tick: int in 4: await process_frame
	var last: Dictionary=_snapshot()
	_check(first==last,"all fresh consumed source/import/compiled bytes/SHA/mtime after last await")
	_check(players==_normal_files() and slot==root.get_node("SaveManager").get("active_slot"),"all15 normal players and active slot preserved; outer exact ticks required")
	_check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true and AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"checkpoint throughquit/actual audio/engine/time")
	_check(observed.size()==9,"three normal-input endpoints times three natural-stage observations")
	var result: Dictionary={"scope":"INN_Y830_NATURAL_GPU_ALPHA_CAUSE_DIAGNOSTIC_NOT_GEOMETRY_APPROVAL","complete":failed==0,"checks":checks+1,"failures":failed,"evidence":evidence,"observations":observed,"source_before":first,"source_after":last,"players_before":players,"players_after":_normal_files(),"active_slot_before":slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"checkpoint_suspension":checkpoint,"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"actual_display_driver":DisplayServer.get_name(),"geometry_pass_claimed":false,"gameplay_pass_claimed":false,"visual_approved":false,"formal_approved":false,"original_routes_or_alpha_thresholds_changed":false,"source_inventory_is_fresh_path_seed_not_prior_snapshot_credit":true,"outer_prelaunch_exact_UTC_ticks_and_complete_stderr_review_required":true}
	_check(_write("result.json",result),"unique diagnostic checked readback")
	print("INN_Y830_DIAGNOSTIC_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failed))
	quit(0 if failed==0 else 1)



