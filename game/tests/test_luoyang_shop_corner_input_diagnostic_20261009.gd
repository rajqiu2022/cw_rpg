extends "res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd"
## ROOT418 original single failed approach; diagnostic success is NOT route PASS.
const OBS_PATH := "res://tests/helpers/luoyang_shop_corner_physics_observer_20261009.gd"
const OBS_SHA := "13e47e45f69b723755d4e5cbee902ff503f26725329408c4ce7524cff071b72f"
const PHYSICAL_PATH := "res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd"
const INPUT_PATH := "res://tests/helpers/v15_input_driver.gd"
const ACTUAL418 := "res://build/joint_world_luoyang_20261003_qa/luoyang_enclosure_v11_city_only_1791533783_1569461_2088/stage_result.json"
const ACTUAL418_SHA := "5b00f12d8073686bb60f3aa8011d45b8a45c50f659c4a65903159b043c4f09c6"
const DIAG_ID := "ch4_s3_luoyang_market"
const PINS := {
	"res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://scripts/field/field_walkable_controller.gd":"b3301d6064e332e519b0fc3b4daed880ec3d77d98f2c744933b5d7077b9eb8ef",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd":"40b42c901ef05ac1971ccaae9ba049b60cfe439baea8778f796f978c4bd54450",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd":"6ad7b6be15fd23ea4f8356c111c5a5a6c54c8e1ec7496083597d01e904711c62",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"d112f9e7867d612596ab1ead2428000749ea44f62a26433a73e170480af6ec51",
	"res://tests/test_luoyang_enclosure_v11_city_only_fresh_20261009.gd":"3291a768f9cab0ca7ae8d348f4d86532c3aefb846d0749424663dcc13d07b892"
}
var diag_field: Control
var diag_probe: RefCounted
var diag_raw: RefCounted
var observer: RefCounted
var evidence: Dictionary={}

static func fixture_sources() -> Array[String]:
	var result: Array[String]=[OBS_PATH,PHYSICAL_PATH,INPUT_PATH,RAW_PATH,CONTRACT_PATH,BRIDGE_PATH,ACTUAL418,"res://tests/test_luoyang_shop_corner_input_diagnostic_20261009.gd","res://scripts/autoload/scene_router.gd","res://scripts/city/luoyang_layered_v3_contract.gd","res://data/scenes/world_map_jianghu.tres","res://data/config/outskirts_native_adoption.json"]
	for id: String in IDS: result.append("res://data/scenes/"+id+".tres")
	for path: String in PINS:
		if not result.has(path): result.append(path)
	return result

func _wait_market() -> bool:
	var deadline: int=Time.get_ticks_msec()+60000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		var loader: Node=root.get_node_or_null("LoadingManager")
		if loader!=null and loader.get("_transition_active")==true: continue
		var node: Node=current_scene
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion() or node.get_script()==null or node.get_script().resource_path!="res://scripts/field/field_walkable_controller.gd": continue
		var definition: SceneScript=node.get("_current_scene") as SceneScript
		if definition==null or definition.scene_id!=StringName(DIAG_ID) or not is_instance_valid(node.get("_player")) or node.get("_scene_rebuilding")==true: continue
		await physics_frame
		if current_scene!=node or not is_instance_valid(node) or node.is_queued_for_deletion(): continue
		diag_field=node as Control; return true
	return false

func _unused_capture(_label: String) -> void:
	pass

func _original() -> Dictionary:
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(ACTUAL418))
	if not parsed is Dictionary: return {}
	var found: Array=[]
	for region: Dictionary in parsed.get("records",{}).get("regions",[]):
		if region.get("id")!=DIAG_ID: continue
		for object: Dictionary in region.get("physical_and_current_alpha",{}).get("objects",[]):
			if object.get("id")!="shop": continue
			for row: Dictionary in object.get("alpha",{}).get("records",[]):
				if row.get("relation")=="front": found.append({"row":row,"station":object.alpha.discovered_stations.front,"collision_bounds":object.collision.exterior_bounds})
	return found[0] if found.size()==1 else {}

func _track_image(path: String) -> void:
	_track(path)
	if path.get_extension()!="png": return
	_track(path+".import")
	var config:=ConfigFile.new()
	if not _check(config.load(path+".import")==OK,"exact consumed image import "+path): return
	var compiled: Variant=config.get_value("remap","path",null)
	if _check(typeof(compiled)==TYPE_STRING,"typed actual compiled image path"): _track(compiled)

func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): quit(1); return
	var default: Variant=bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	players=_normal_files(); slot=root.get_node("SaveManager").get("active_slot")
	checkpoint={"default_suspended":default,"before_any_await":bridge.call("is_checkpoint_saves_suspended"),"automatic_checkpoint_saves_tested":false,"restored_before_exit":false}
	_check(typeof(default)==TYPE_BOOL and not default and checkpoint.before_any_await==true and FileAccess.get_sha256(BRIDGE_PATH)==BRIDGE_SHA,"public checkpoint suspended before fixture/all awaits")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check("--luoyang-shop-corner-diagnostic" in args and "--fresh-start-only" in args and "--luoyang-v3-candidate" in args and "--luoyang-enclosure-v11-candidate" in args and not "--qa-phase=release" in args and not "--activate" in args,"explicit diagnostic candidate scope, never whole RELEASE")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"actual WASAPI/executable/time")
	output="res://build/joint_world_luoyang_20261003_qa/shop_corner_diagnostic_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique diagnostic output"): quit(1); return
	for path: String in fixture_sources(): _track(path)
	for path: String in PINS: _check(FileAccess.get_sha256(path)==PINS[path],"frozen actual source "+path)
	_check(FileAccess.get_sha256(ACTUAL418)==ACTUAL418_SHA and FileAccess.get_sha256(OBS_PATH)==OBS_SHA,"exact original418 and NEW read-only observer")
	var scripts: Dictionary={}
	for path: String in [RAW_PATH,CONTRACT_PATH,PHYSICAL_PATH,OBS_PATH]:
		var script: Script=load(path) as Script
		_check(script!=null and script.can_instantiate(),"load/can_instantiate "+path); scripts[path]=script
	var original: Dictionary=_original() if failed==0 else {}
	_check(not original.is_empty(),"one original shop/front failure from immutable418")
	var points:=PackedVector2Array()
	if not original.is_empty():
		var segments: Array=original.row.approach.segments
		_check(segments.size()==14 and original.row.approach.index==14 and original.row.approach.ok==false and original.row.final_leg.ok==false,"exact original14 rejected, final leg not executed")
		points.append(Vector2(float(segments[0].start[0]),float(segments[0].start[1])))
		for row: Dictionary in segments: points.append(Vector2(float(row.target[0]),float(row.target[1])))
		_check(points[0]==Vector2(2204,594) and points[13]==Vector2(1888,832) and points[14]==Vector2(1920,864),"original14 targets unchanged, no replan")
		evidence["original418"]=original.duplicate(true)
		evidence["fixed_points_native_hex"]=points.to_byte_array().hex_encode()
	if failed==0:
		diag_raw=(scripts[RAW_PATH] as Script).new()
		var record: Dictionary=diag_raw.call("independent_record",StringName(DIAG_ID))
		_check(not record.is_empty(),"independent frozen full market author record")
		for path: String in record.get("asset_sha256",{}): _track_image(path)
		for key: String in ["enclosure_patch_path","enclosure_base_manifest_path","ground_capture_path"]:
			if typeof(record.get(key))==TYPE_STRING: _track(record[key])
		if record.has("enclosure_patch_path"):
			var patch: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(record.enclosure_patch_path)); _track(String(patch.export_plan_path))
		for path: String in [(scripts[CONTRACT_PATH] as Script).call("candidate_path",StringName(DIAG_ID)),(scripts[CONTRACT_PATH] as Script).call("layout_path",StringName(DIAG_ID))]: _track(path)
		# Player may choose any current directional strip while original INPUT runs.
		for family: String in ["sword","dao","staff","palm","hidden"]:
			for state: String in ["idle","walk"]:
				for direction: String in ["up","down","left","right"]:
					_track_image("res://art/characters/weapon_variants/lengguyun/v7_idle_stable/%s/lengguyun_%s_%s_%s_25d_%df.png"%[family,family,state,direction,4 if state=="idle" else 8])
		var definition: SceneScript=(scripts[CONTRACT_PATH] as Script).call("legacy_scene",StringName(DIAG_ID))
		if definition!=null:
			_track(definition.bgm_path)
			_track(definition.resource_path)
			if definition.map_layout!=null: _track(definition.map_layout.resource_path)
			for npc: Dictionary in definition.npcs:
				var npc_paths: Array=[]
				for key: String in ["sprite_path","walk_sprite_path","portrait_path"]:
					if typeof(npc.get(key))==TYPE_STRING and not String(npc[key]).is_empty(): npc_paths.append(npc[key])
				for value: Variant in npc.get("conversation_sprite_paths",{}).values():
					if typeof(value)==TYPE_STRING and not String(value).is_empty(): npc_paths.append(value)
				for source: String in npc_paths:
					_track_image(source)
					for direction: String in ["up","down","left","right"]:
						for state_name: String in ["idle","walk"]:
							var asset_variant: String=source.replace("_down_","_"+direction+"_").replace("_idle_","_"+state_name+"_")
							if FileAccess.file_exists(asset_variant): _track_image(asset_variant)
	first=_snapshot(); _check(_write("source_before.json",first),"all consumed source/import/compiled guard before fixture/await")
	if failed==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		var state: Node=root.get_node("GameState")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: state.call("set_flag",StringName(flag),true)
		state.set("current_chapter",4)
		_check(root.get_node("SceneRouter").call("go_field_smart",StringName(DIAG_ID),null,"",-1,3)==true,"ordinary public market route")
		_check(await _wait_market(),"actual market Field ready")
		if failed==0:
			_check(diag_raw.call("configure_city",diag_field.get("_current_scene"),true)==true,"independent full current market source/layout")
			diag_probe=(scripts[PHYSICAL_PATH] as Script).new()
			_check(diag_probe.call("configure",self,diag_field,diag_raw.get("source_record"),_check,_unused_capture)==true,"unchanged full875+17 source/Physics probe")
		if failed==0:
			var setup_drive: Dictionary=await diag_probe.call("move_to",points[0])
			evidence["normal_setup_to_original_behind_start"]=setup_drive
			_check(setup_drive.get("ok")==true and (diag_field.get("_player") as Node2D).position.distance_to(points[0])<=.3,"normal original INPUT reaches originalstart, no teleport")
		if failed==0:
			observer=(scripts[OBS_PATH] as Script).new()
			_check(observer.call("attach",diag_field,diag_probe)==true,"actual physics priorities strictly bracket unmodified Player")
			if failed==0:
				evidence["rounding_domain_segment14"]=observer.call("rounding_events",points[13],points[14])
				evidence["original13_center_segment_check"]=diag_probe.call("segment",points[13],points[14])
				var bad: Array=original.row.approach.segments[13].first_bad
				evidence["original_bad_point_current_evidence"]=observer.call("independent",Vector2(float(bad[0]),float(bad[1])))
				observer.set("active",true)
				var driven: Dictionary=await (diag_probe.get("driver") as RefCounted).call("follow",diag_field,points,Callable(diag_probe,"clear"),Callable(diag_probe,"segment"))
				observer.set("active",false)
				evidence["actual_original_follow"]=driven
				evidence["observer_setup"]=observer.get("setup").duplicate(true)
				evidence["physics_ticks"]=observer.get("rows").duplicate(true)
				evidence["tree_physics_boundary_observations"]=observer.get("physics_boundaries").duplicate(true)
				var last_samples: PackedVector2Array=(diag_probe.get("driver") as RefCounted).get("observed_positions")
				evidence["unmodified_driver_last_segment_observed_positions"]={"native_hex":last_samples.to_byte_array().hex_encode(),"points":[]}
				for p: Vector2 in last_samples: evidence.unmodified_driver_last_segment_observed_positions.points.append([p.x,p.y])
				evidence["observer_errors"]=observer.get("errors").duplicate()
				_check((observer.get("errors") as Array).is_empty() and (observer.get("pending") as Dictionary).is_empty() and not (observer.get("rows") as Array).is_empty(),"bounded sameframe pre/Player/post pairs collected")
				_check(driven.get("ok")==false and driven.get("index")==14 and driven.get("reason")=="real_input_failed","original14 rejection actually reproduced, never treated as route PASS")
				evidence["final_original_front_leg"]={"not_run":true,"reason":"original approach rejected","target":original.station.point,"original_approach_target":[2204,854]}
	await _finish_diagnostic()

func _finish_diagnostic() -> void:
	if observer!=null: observer.call("release"); observer=null
	if diag_probe!=null: diag_probe.call("release"); diag_probe=null
	if diag_raw!=null: _check(diag_raw.call("verify_sources")==true,"independent sources final exact"); diag_raw.call("release"); diag_raw=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	diag_field=null
	for tick: int in 8: await process_frame
	var grace: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-grace<9000000: await process_frame
	root.get_node("AudioManager").call("stop_bgm",.15)
	var drain: int=Time.get_ticks_usec()
	while Time.get_ticks_usec()-drain<250000: await process_frame
	for shape: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for tick: int in 4: await process_frame
	var last: Dictionary=_snapshot()
	_check(first==last,"all unique source first/last SHA bytes mtime unchanged after last await")
	_check(players==_normal_files() and slot==root.get_node("SaveManager").get("active_slot"),"all15 players/slot unchanged; outer exact UTC ticks required")
	_check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true and AudioServer.get_driver_name()=="WASAPI" and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA and Engine.time_scale==1.,"checkpoint held toquit/actual engine audio/time")
	var result: Dictionary={"scope":"ORIGINAL418_SHOP_FRONT14_SEGMENT_READONLY_PHYSICS_ROUNDING_DIAGNOSTIC","complete":failed==0,"checks":checks+1,"failures":failed,"evidence":evidence,"source_before":first,"source_after":last,"players_before":players,"players_after":_normal_files(),"active_slot_before":slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"checkpoint":checkpoint,"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"original418_failure_preserved":true,"route_pass_claimed":false,"all_city_geometry_tested":false,"gameplay_save_tested":false,"formal_approved":false,"outer_exact_ticks_and_complete_stderr_review_required":true}
	_check(_write("result.json",result),"diagnostic result exact readback")
	print("SHOP_CORNER_DIAGNOSTIC_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failed))
	quit(0 if failed==0 else 1)
