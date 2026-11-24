extends "res://tests/test_luoyang_city3_motion_guard_units_retry1_20261009.gd"
## Production repair: original14 targets and original INPUT/4px probe unchanged.
## Then the original front approach and 2px facing leg; focused, not whole-city.
const REPAIR_PATH := "res://tests/test_luoyang_shop_corner_motion_repair_focused_retry1_20261009.gd"

func _run() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended") or not bridge.has_method("is_checkpoint_saves_suspended"): quit(1); return
	var default: Variant=bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	players=_normal_files(); slot=root.get_node("SaveManager").get("active_slot")
	checkpoint={"default_suspended":default,"before_any_await":bridge.call("is_checkpoint_saves_suspended"),"automatic_checkpoint_saves_tested":false,"restored_before_exit":false}
	_check(typeof(default)==TYPE_BOOL and not default and checkpoint.before_any_await==true and FileAccess.get_sha256(BRIDGE_PATH)==BRIDGE_SHA,"public checkpoint suspended before fixture/all awaits")
	var args: PackedStringArray=OS.get_cmdline_user_args()
	_check("--luoyang-shop-corner-motion-repair" in args and "--fresh-start-only" in args and "--luoyang-v3-candidate" in args and "--luoyang-enclosure-v11-candidate" in args and not "--qa-phase=release" in args and not "--activate" in args,"explicit diagnostic candidate scope, never whole RELEASE")
	_check(AudioServer.get_driver_name()=="WASAPI" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"actual WASAPI/executable/time")
	output="res://build/joint_world_luoyang_20261003_qa/shop_corner_motion_repair_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique diagnostic output"): quit(1); return
	_motion_startup(); _dynamic(REPAIR_PATH); _market_sources()
	_check(FileAccess.get_sha256(MOTION_PATH)==MOTION_SHA and FileAccess.get_sha256("res://scripts/field/field_walkable_controller.gd")==NEW_FIELD_SHA,"exact production motion repair/Field")
	for path: String in PINS:
		if path!="res://scripts/field/field_walkable_controller.gd": _check(FileAccess.get_sha256(path)==PINS[path],"frozen unchanged input/probe/source "+path)
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
	first=_snapshot(); _check(_write("source_before.json",first),"all consumed source/import/compiled guard before fixture/await")
	if failed==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		var state: Node=root.get_node("GameState")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: state.call("set_flag",StringName(flag),true)
		state.set("current_chapter",4)
		var init_started: int=Time.get_ticks_usec()
		_check(root.get_node("SceneRouter").call("go_field_smart",StringName(DIAG_ID),null,"",-1,3)==true,"ordinary public market route")
		_check(await _wait_market(),"actual market Field ready")
		evidence["actual_runtime_init_usec"]=Time.get_ticks_usec()-init_started
		evidence["runtime_init_timing_scope"]="PUBLIC_ROUTE_TO_READY; includes normal scene setup, not isolated prefix time"
		if failed==0:
			_check(diag_raw.call("configure_city",diag_field.get("_current_scene"),true)==true,"independent full current market source/layout")
			diag_probe=(scripts[PHYSICAL_PATH] as Script).new()
			_check(diag_probe.call("configure",self,diag_field,diag_raw.get("source_record"),_check,_unused_capture)==true,"unchanged full875+17 source/Physics probe")
			_check(diag_probe.call("_physical_binding","shop")==true,"original shop actual body/shape exactly bound to frozen source")
			var live_player: CharacterBody2D=diag_field.get("_player") as CharacterBody2D
			var shape: CollisionShape2D=live_player.get_node_or_null("CollisionShape2D") as CollisionShape2D
			_check(shape!=null and not shape.disabled and shape.shape is RectangleShape2D and shape.shape.size==Vector2(34,24) and shape.position==Vector2.ZERO,"actual unchanged ordinary centered34x24 shape")
			evidence["actual_motion_support"]={"safe_margin":live_player.safe_margin,"shape_size":[34,24],"original_navigation_margin_px":diag_raw.get("source_record").physical_navigation_margin_px,"conservative_motion_support_not_original_nav_equivalence":true}
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
				_check(evidence.original_bad_point_current_evidence.get("raw_full875_and17",{}).get("clear",true)==false,"original illegal point remains forbidden, no art/nav relaxation")
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
				var stage_costs: Array[int]=[]
				for tick: Dictionary in observer.get("rows"):
					stage_costs.append(int(tick.post_ticks_usec)-int(tick.pre_ticks_usec))
				evidence["actual_pre_Player_post_duration"]=_timing_summary(stage_costs)
				evidence["actual_pre_Player_post_duration_scope"]="OBSERVED_PAIR; includes Player physics and post-query observer, NOT pure motion-call time"
				_check((observer.get("errors") as Array).is_empty() and (observer.get("pending") as Dictionary).is_empty() and not (observer.get("rows") as Array).is_empty(),"bounded sameframe pre/Player/post pairs collected")
				_check(driven.get("ok")==true and (driven.get("segments",[]) as Array).size()==14,"original unmodified14 normal-input segments all legal and reached after production fix")
				if failed==0:
					_runtime_query_timings()
					await _original_front_leg(original)
	await _finish_repair()

func _runtime_query_timings() -> void:
	# Read-only calls to the actual public Field movement constraint. Neither
	# Player._constrain_velocity nor any controller/position setter is invoked.
	var player: CharacterBody2D=diag_field.get("_player") as CharacterBody2D
	var constraint: Callable=player.movement_constraint
	var costs: Array[int]=[]; var queries: Array=[]
	for repeat: int in 8:
		for offset: Vector2 in [Vector2(4,4),Vector2(4,0),Vector2(0,4)]:
			var requested: Vector2=player.global_position+offset
			var started: int=Time.get_ticks_usec()
			var answer: Variant=constraint.call(requested)
			var elapsed: int=Time.get_ticks_usec()-started
			costs.append(elapsed)
			_check(typeof(answer)==TYPE_BOOL,"actual public full/axis motion result typed bool")
			queries.append({"offset":[offset.x,offset.y],"answer":answer,"usec":elapsed})
	evidence["actual_public_Field_motion_query_timing"]={"summary":_timing_summary(costs),"queries":queries,"scope":"READONLY_ACTUAL_BOUND_CONSTRAINT_24_SHORT_FULL_HORIZONTAL_VERTICAL_QUERIES; not actual Player call count"}

func _original_front_leg(original: Dictionary) -> void:
	var player: Node2D=diag_field.get("_player") as Node2D
	var target: Sprite2D=diag_probe.call("prop","shop")
	var sprite: Sprite2D=player.get("sprite") as Sprite2D
	var container: Node2D=diag_field.get("world_container") as Node2D
	var rows: Array=[]
	for object: Dictionary in diag_raw.get("source_record").objects:
		if object.get("id")=="shop": rows.append(object)
	if not _check(rows.size()==1 and is_instance_valid(target),"unique actual shop/runtime sprite"): return
	var object: Dictionary=rows[0]
	var station:=Vector2(float(original.station.point[0]),float(original.station.point[1]))
	var direction:=Vector2(float(original.station.direction[0]),float(original.station.direction[1]))
	_check(station==Vector2(2204,852) and direction==Vector2.UP,"exact original front target and natural-facing direction")
	_check(paths.has(sprite.texture.resource_path) and paths.has(target.texture.resource_path),"current actual actor and shop texture guarded before first await")
	var approach: Dictionary=await diag_probe.call("move_to",station-direction*2)
	var driver: RefCounted=diag_probe.get("driver")
	var leg: Dictionary=await driver.call("drive",diag_field,station,Callable(diag_probe,"clear")) if approach.get("ok")==true else {"ok":false}
	await driver.call("completed_actor_stage")
	var alpha: RefCounted=diag_probe.get("alpha")
	var hits: Dictionary=alpha.call("strong_intersection",sprite,target)
	var actor_front: bool=alpha.call("actual_in_front",player,target)
	var feet_relation: bool=float(player.call("get_depth_sort_y"))>container.to_global(diag_probe.call("point",object.world_foot_px)).y
	var debug: Dictionary=diag_field.call("get_v14_modular_overlap_debug")
	var assertion: Dictionary=diag_probe.call("_alpha_observation",target)
	var raw: Dictionary=diag_probe.call("raw_evidence",player.position)
	var physical: bool=diag_probe.call("physical_clear",player.position)
	var union_exact: bool=diag_probe.call("exact_union",debug)
	var ghosts: int=int((debug.get("prop_hits",{}) as Dictionary).get("shop",0))
	_check(approach.get("ok")==true and leg.get("ok")==true,"original approach854 and final2px facing-input852 reached")
	_check(diag_probe.call("raw_clear",player.position)==true and physical and int(hits.get("hits",0))>0,"original full875+17/Physics/current strong alpha")
	_check(feet_relation and actor_front==feet_relation,"original actual front feet/order")
	_check(ghosts==0 and union_exact,"original front no target ghost and independent current exact union")
	evidence["final_original_front_leg"]={"target":[station.x,station.y],"direction":[direction.x,direction.y],"approach":approach,"final_leg":leg,"actual_alpha":hits,"raw":raw,"physical_clear":physical,"actor_front":actor_front,"feet_front":feet_relation,"ghost_target_pixels":ghosts,"exact_union":union_exact,"first_assertion_snapshot":assertion}
	await driver.call("completed_actor_stage")
	evidence.final_original_front_leg["second_natural_stage_snapshot"]=diag_probe.call("_alpha_observation",target)
	evidence.final_original_front_leg["second_stage_is_diagnostic_not_assertion_replacement"]=true

func _finish_repair() -> void:
	if observer!=null: observer.call("release"); observer=null
	if diag_probe!=null: diag_probe.call("release"); diag_probe=null
	if diag_raw!=null: _check(diag_raw.call("verify_sources")==true,"independent sources final exact"); diag_raw.call("release"); diag_raw=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	diag_field=null
	market_definition=null
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
	var result: Dictionary={"scope":"ORIGINAL418_SHOP_FRONT14_SEGMENTS_PRODUCTION_MOTION_REPAIR_FOCUSED","complete":failed==0,"checks":checks+1,"failures":failed,"evidence":evidence,"source_before":first,"source_after":last,"players_before":players,"players_after":_normal_files(),"active_slot_before":slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"checkpoint":checkpoint,"actual_audio_driver":AudioServer.get_driver_name(),"engine_sha256":FileAccess.get_sha256(OS.get_executable_path()),"original418_failure_preserved":true,"original14_fixed_input_tested":true,"new_continuous_QA_planner_used":false,"focused_route_pass":failed==0,"all_city_geometry_tested":false,"gameplay_save_tested":false,"formal_approved":false,"outer_exact_ticks_and_complete_stderr_review_required":true}
	_check(_write("result.json",result),"diagnostic result exact readback")
	print("SHOP_CORNER_MOTION_REPAIR_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failed))
	quit(0 if failed==0 else 1)
