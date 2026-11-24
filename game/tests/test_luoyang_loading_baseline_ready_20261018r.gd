extends "res://tests/test_live_city_ordinary_warm_key_20261017j.gd"
## r BASELINE ONLY. Same instrument will be used by a separately frozen candidate.
## First operable DRAW is immutable; expensive correctness checks run afterwards.
const BASELINE_READY=true
const CORE_PATH="res://tests/fixtures/luoyang_loading_baseline_20261018r_core.json"
const CORE_SHA="bbf1f1ffc4be3d8d08431e434fcda08e2bf9376845581e747dd06cfc7edb0f98"
var baseline_sources: Dictionary={}
var draw_target: String=""
var draw_label: String=""
var draw_started: int=0
var draw_previous: int=0
var draw_previous_frame: int=0
var first_draw: Dictionary={}
var draw_max_gap: Dictionary={}
var draw_worker_frames: int=0

func precheck() -> bool:
	if not check(BASELINE_READY,"NOTREADY: Root must review and freeze a NEW execution file"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty() and LEASE.LIVE_WORLD_FORMAL_ENABLED,"Ordinary GPU/native clock, formal live lease, no flags"): return false
	if not track(CORE_PATH,CORE_SHA): return false
	var core: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CORE_PATH))
	for path: String in core.source_sha256:
		if not track(path,core.source_sha256[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	# No asset-corpus prehash/preflight prepare before cold Space. Own C worker
	# still does its complete first/final validation. Independent disk recheck
	# and baseline expected fullmap capture happen AFTER the timestamp freeze.
	package=R.binding();author=R.author(package)
	return check(not package.is_empty() and not author.is_empty(),"Actual current district package loaded, not old runtime SHA expectations")

func _draw_scalars() -> Dictionary:
	return {"source_worker":C._live_source_task>=0,"nav_worker":C._live_navigation_task>=0,"base_worker":C._live_base_cpu_task>=0,"module_worker":C._live_module_task>=0,"revision_worker":C._live_revision_task>=0,"base_main":C._live_base_main_active}

func _r_draw() -> void:
	if draw_target.is_empty() or not first_draw.is_empty(): return
	var now: int=Time.get_ticks_usec()
	var frame: int=Engine.get_process_frames()
	var workers: Dictionary=_draw_scalars()
	if watch_jobs:
		for active: bool in workers.values():
			if active: draw_worker_frames+=1;break
	if draw_previous>0 and now-draw_previous>int(draw_max_gap.get("gap_usec",0)):
		draw_max_gap={"gap_usec":now-draw_previous,"previous_frame":draw_previous_frame,"frame":frame,"observed_usec":now,"workers_after":workers}
	draw_previous=now;draw_previous_frame=frame
	if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): return
	var target_scene: SceneScript=current_scene.get("_current_scene") as SceneScript
	if target_scene==null or String(target_scene.scene_id)!=draw_target: return
	var loading_state: Dictionary=current_scene.call("get_field_loading_state")
	var player: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
	var loading: Node=root.get_node("LoadingManager").get("_screen")
	var panel: Control=loading.get("root") as Control if is_instance_valid(loading) else null
	if not loading_state.get("complete",false) or loading_state.get("failed",false) or player==null or not player.is_inside_tree() or not player.can_process() or player.get("can_move")!=true or (panel!=null and panel.is_visible_in_tree()): return
	# Read trusted ready scalars BY REFERENCE only: no resident_receipt(),
	# source collector, deep copy, SHA, PNG, physics loop, or file I/O here.
	var ready: Dictionary=C._resident_ready
	first_draw={"label":draw_label,"target":draw_target,"trigger_usec":draw_started,"first_operable_draw_usec":now,"elapsed_usec":now-draw_started,"draw_frame":frame,"Field_id":current_scene.get_instance_id(),"Scene_id":target_scene.get_instance_id(),"Player_id":player.get_instance_id(),"foot":player.position,"field_complete":true,"Loading_hidden":true,"can_move":true,"can_process":true,"trusted_scene_same":ready.get("scene")==target_scene,"trusted_id":String(ready.get("id","")),"trusted_token":int(ready.get("token",0)),"trusted_sources_finalized":ready.get("sources_finalized",false),"trusted_source_count":ready.get("sources",{}).size(),"workers":workers,"worker_frames":draw_worker_frames,"max_gap":draw_max_gap.duplicate(true),"instrument":"R_FIRST_OPERABLE_FRAME_POST_DRAW_SCALARS_ONLY"}

func _arm_draw(target: String,label: String) -> void:
	draw_target=target;draw_label=label;first_draw={};draw_max_gap={};draw_previous=0;draw_previous_frame=0;draw_worker_frames=0
	draw_started=Time.get_ticks_usec()

func _wait_once(target: String,_source_id: String="") -> bool:
	if draw_target!=target or draw_started==0: _arm_draw(target,"PUBLIC_SETUP")
	var until: int=mini(deadline,int(draw_started/1000)+60000)
	while Time.get_ticks_msec()<until:
		if not first_draw.is_empty():
			field=current_scene;scene=field.get("_current_scene") as SceneScript
			draw_target=""
			records.append({"kind":"FIRST_OPERABLE_DRAW_FROZEN_BEFORE_POSTVERIFY","measurement":first_draw.duplicate(true)})
			return true
		await process_frame
	draw_target=""
	return check(false,"Fixed 60s arrival / shared160s; never extend for 10s target",{"target":target,"elapsed_usec":Time.get_ticks_usec()-draw_started,"C_errors":C.errors(),"C_state":C.transition_validation_state(),"public":root.get_node("SceneRouter").call("get_public_city_preparation_state")})

func _post_gate(warm: bool) -> bool:
	var started: int=Time.get_ticks_usec()
	if not check(first_draw.trusted_scene_same and first_draw.trusted_id==GATE_ID and first_draw.trusted_token>0 and first_draw.trusted_sources_finalized and first_draw.trusted_source_count>0,"First operable draw itself already had same-scene finalized trusted owner; not backfilled after QA"): return false
	var proof: Dictionary=C.resident_receipt(scene)
	if not check(not proof.is_empty() and proof.get("sources_finalized",false) and int(proof.token)==int(first_draw.trusted_token),"POSTVERIFY actual trusted receipt passes full live geometry/storage/nav/stamps checks"): return false
	var paths: Dictionary=C._transition_sources(proof.source_scene,false)
	if not check(not paths.is_empty() and paths.size()==proof.sources.size(),"Current complete collector set equals trusted source map, no fixed625 assumption"): return false
	for path: String in paths:
		if not check(proof.sources.has(path),"Complete collector path present "+path): return false
	if not warm:
		for path: String in paths:
			if not track(path,String(proof.sources[path])): return false
		baseline_sources=proof.sources.duplicate(true)
		var output:=FileAccess.open(folder.path_join("baseline_expected_current_sources.json"),FileAccess.WRITE)
		if not check(output!=null,"Write independently rehashed current fullmap AFTER first draw"): return false
		output.store_string(JSON.stringify(baseline_sources,"\t",true,true));output.close()
	else:
		if not check(C._equal_value(proof.sources,baseline_sources),"Warm exact complete map unchanged; live identity basis, NOT fresh warm disk SHA"): return false
	for path: String in source_before:
		if proof.sources.has(path) and not check(proof.sources[path]==source_before[path].sha256,"Own finite pre/post source pin agrees with actual trusted map "+path): return false
	var elapsed: int=Time.get_ticks_usec()-started
	records.append({"kind":"POSTVERIFY_SEPARATE_FROM_FIRST_DRAW","warm":warm,"post_verify_usec":elapsed,"complete_current_sources":proof.sources.duplicate(true),"source_count":paths.size(),"token":proof.token,"timing_profile_after_freeze":C.transition_validation_state(),"fullmap_capture_phase":"AFTER_FIRST_DRAW_INDEPENDENT_DISK_SHA_C_OWNS_TRANSITION_FIRST_FINAL","warm_fresh_disk_sha":false})
	return true

func _space_to(id: String,label: String,warm: bool=false) -> bool:
	_arm_draw(id,label) # Installed before actual Input dispatch and its awaits.
	await driver.key(KEY_SPACE)
	if not await _wait_once(id): return false
	var measurement: Dictionary=first_draw.duplicate(true)
	if id==GATE_ID and not _post_gate(warm): return false
	var returned: Dictionary=root.get_node("SceneRouter").call("get_resident_city_state")
	records.append({"kind":"ENTRY_METRIC_NOT_WHOLE_SCRIPT","label":label,"first_draw":measurement,"user_10s_target_met":int(measurement.elapsed_usec)<10000000,"goal_failure_not_hidden_by_correctness_pass":true,"lease_after_postverify":returned})
	if not warm: return true
	var value: Dictionary=returned.get("return",{})
	return check(int(measurement.elapsed_usec)<2000000 and value.get("hit")==true and value.get("final_live_identity")==true and value.get("source_fresh_sha")==false and value.get("source_basis")=="SAME_LIVE_OBJECTS_AND_EDITOR_METADATA" and int(measurement.worker_frames)==0 and int(C.transition_validation_state().get("full_validations_total"))==validations_before,"Existing strict2s warm regression until first hidden/operable draw; same live owner and0coldjobs",value)

func _exercise() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var definition: SceneScript=ResourceLoader.load("res://data/scenes/world_map_jianghu.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var portals: Array=[]
	for item: Dictionary in definition.map_layout.portals:
		if item.get("target_scene")==GATE_ID: portals.append(item)
	if not check(portals.size()==1,"Immutable unique world Gate original portal"): return false
	var entry: Vector2=portals[0].pos*Vector2(12288,8192)
	var setup: Vector2=entry+Vector2(0,96)
	_arm_draw(WORLD_ID,"LEGAL_NEAR_WORLD_SETUP_NOT_TRAVEL")
	if not check(router.call("go_field_smart",StringName(WORLD_ID),setup/Vector2(12288,8192),"",15),"One legal public world near setup, no direct city setup") or not await _wait_once(WORLD_ID) or not _world_bind(): return false
	if not await _walk(PackedVector2Array([field.get("_player").position,entry])) or not _zone(GATE_ID) or not await _space_to(GATE_ID,"BASELINE_COLD_WORLD96_SPACE_GATE"): return false
	district="gate";scene_id=GATE_ID
	if not _bind_actual() or not check(GATE.bound(field.get("_harbour_gate_visual_scene")) and field.get("_player").position==Vector2(1536,1860),"Real formal Gate/actual original arrival/nativebody"): return false
	if not await _walk(PackedVector2Array([Vector2(1536,1860),Vector2(1568,1860),Vector2(1536,1860)])) or not _zone("","world_map") or not _retain_gate(): return false
	if not await _space_to(WORLD_ID,"REAL_GATE_SPACE_EXIT_WORLD") or not _world_bind(): return false
	var parked: Dictionary=router.call("get_resident_city_state")
	var retained_player: CharacterBody2D=retained.get("_player")
	if not check(parked.get("occupied")==true and parked.get("parked")==true and parked.get("excursion_kind")=="world" and parked.get("field_id")==retained.get_instance_id() and not retained.is_inside_tree() and not retained_player.is_inside_tree() and not PhysicsServer2D.body_get_space(retained_player.get_rid()).is_valid() and parked.get("estimated_bytes",LEASE.LIMIT_BYTES+1)<=LEASE.LIMIT_BYTES,"Actual world excursion with same bounded detached city, not parked-room substitute",parked): return false
	# One tiny real QUEUED cancellation; not a second travel or metadata mutation.
	var world_field: Node=field
	var world_foot: Vector2=field.get("_player").position
	if not check(router.call("go_field_smart",StringName(GATE_ID),Vector2(1536,1860)/Vector2(3072,2048),"",-1,C.VERSION),"Public warm enqueue solely for owned queued-cancel fixture"): return false
	var queued: Dictionary=router.call("get_resident_city_state")
	var token: int=int(queued.get("return",{}).get("token",0))
	if not check(token>0 and router.call("cancel_public_city_preparation",token),"Actual queued warm token cancelled"): return false
	await process_frame;await physics_frame
	if not check(current_scene==world_field and field.get("_player").position==world_foot and field.get("_player").get("can_move")==true and router.call("get_resident_city_state").get("parked")==true and not router.call("cancel_public_city_preparation",token),"Cancelled owner leaves world/foot/city intact and stale token rejected"): return false
	validations_before=int(C.transition_validation_state().get("full_validations_total"));watch_jobs=true
	if not await _walk(PackedVector2Array([world_foot,entry])) or not _zone(GATE_ID) or not await _space_to(GATE_ID,"BASELINE_SECOND_SAME_GATE_AFTER_REAL_WORLD",true): return false
	watch_jobs=false;oracle=retained_oracle;district="gate";scene_id=GATE_ID
	if not _same_gate() or not check(field.get("_player").position==Vector2(1536,1860) and _clear(Vector2(1536,1860)),"Same original Gate full87517/native34x24 Physics after warm"): return false
	return await _capture("baseline_same_gate_warm_ordinary")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+160000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_loading_baseline_20261018r/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		RenderingServer.frame_post_draw.connect(_r_draw)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
		if not await _leave_actual_field(): complete=false
	draw_target=""
	if RenderingServer.frame_post_draw.is_connected(_r_draw): RenderingServer.frame_post_draw.disconnect(_r_draw)
	if driver!=null: driver.release();driver=null
	root.get_node("SceneRouter").call("reset_for_new_game")
	await process_frame;await process_frame
	field=null;scene=null;oracle=null;retained=null;retained_scene=null;retained_oracle=null;retained_static.clear();retained_nav.clear();retained_crowd.clear();frame_images.clear()
	records.append({"kind":"SCOPE","whole_ms":160000,"arrival_ms":60000,"cold_user_target_usec":10000000,"warm_user_target_usec":10000000,"strict_existing_warm_regression_usec":2000000,"captures":captures,"native_queries":native_queries,"current_fullmap_count":baseline_sources.size(),"cold_means_fresh_process_not_OS_cache_flush":true,"instrument_changed_from_old_o_q":true,"timing_target_and_correctness_separate":true,"full_source_guard_after_firstdraw_and_at_finish":true,"no_Market_rooms_fourcity_or_old_CPU_suite":true})
	finish(folder,began,complete,"R_CURRENT_FORMAL_BASELINE_REAL_WORLD_COLD_GATE_WORLD_WARM")
