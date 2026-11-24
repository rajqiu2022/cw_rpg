extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Root-only one default public entry. No prior furniture/route executor.
const FIXTURE="res://build/luoyang_city_full_rollout_20261022ap_qa01/yamen_performance03_fixture_ROOT16_READY.json"
const FIXTURE_SHA="a488ba0536d9df8da4b1130a0ea0f4a11626d8bcc0ff7c88a6f744ef6a02c036"
const ID=&"ch4_s1_luoyang_yamen"
const WHOLE_MS=60000
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
var fixture: Dictionary={}
var requested_usec: int=0
var ready_fact: Dictionary={}
var draw_fact: Dictionary={}
var last_matching_C: Dictionary={}
var last_finalized_C: Dictionary={}
var last_LM: Dictionary={}
var last_Field_profile: Dictionary={}
var trace_signature: String=""
var trace_count: int=0
var last_observe_usec: int=0
var max_observe_gap_usec: int=0

func clock_fact() -> Dictionary:
	return {"usec":Time.get_ticks_usec(),"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames()}

func precheck() -> bool:
	if not track(FIXTURE,FIXTURE_SHA): return false
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not check(value is Dictionary and value.get("ready")==true,"Frozen one-entry performance fixture"): return false
	fixture=value
	if not check(fixture.whole_ms==WHOLE_MS and fixture.max_pictures==0 and fixture.public_requests==1 and fixture.expected_city_source_sha256.size()==1217,"Fixed60s/0pictures/one default public entry/source1217"): return false
	if not check(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name()!="headless" and Engine.time_scale==1.0,"Ordinary GUI clock/no candidate arguments"): return false
	for p: String in fixture.source_sha256:
		if not track(p,fixture.source_sha256[p]): return false
	for p: String in fixture.expected_city_source_sha256:
		if not check(fixture.source_sha256.get(p)==fixture.expected_city_source_sha256[p],"Protect each independent Yamen source expectation"): return false
	return true

func observe_readonly() -> void:
	if requested_usec<=0: return
	var now: int=Time.get_ticks_usec()
	var gap: int=now-last_observe_usec if last_observe_usec>0 else 0
	last_observe_usec=now;max_observe_gap_usec=maxi(max_observe_gap_usec,gap)
	var field_state: Dictionary={}
	var current: SceneScript
	var actor: CharacterBody2D
	if is_instance_valid(current_scene) and current_scene.has_method("get_field_loading_state"):
		current=current_scene.get("_current_scene") as SceneScript
		if current!=null and current.scene_id==ID:
			field_state=current_scene.call("get_field_loading_state")
			actor=current_scene.get("_player") as CharacterBody2D
			if ready_fact.is_empty() and field_state.get("complete")==true and not field_state.get("failed",false) and actor!=null and actor.can_process() and actor.get("can_move")==true:
				# Cheap first-ready scalar before copied timing/receipt dictionaries.
				ready_fact=clock_fact()
				ready_fact.merge({"elapsed_usec":int(ready_fact.usec)-requested_usec,"Field":current_scene.get_instance_id(),"Scene":current.get_instance_id(),"Player":actor.get_instance_id()})
	var router: Node=root.get_node("SceneRouter")
	var public_state: Dictionary=router.call("get_public_city_preparation_state")
	var live_token: int=int(router.call("live_field_transition_token",ID))
	var state: Dictionary=C.transition_validation_state()
	var same_owner: bool=live_token>0 and state.get("active")==true and state.get("live_scope")==true and state.get("scene_id")==String(ID) and state.get("token")==live_token
	if same_owner:
		last_matching_C={"captured":clock_fact(),"same_live_owner":live_token,"C":state}
		if state.get("sources_finalized")==true: last_finalized_C=last_matching_C.duplicate(true)
	var metrics: Dictionary=root.get_node("LoadingManager").call("get_field_preload_metrics")
	if metrics.get("scene_id")==String(ID): last_LM={"captured":clock_fact(),"metrics":metrics,"matching_scene_only_not_a_C_freshsource_receipt":true}
	if current!=null and current.scene_id==ID and current_scene.has_method("get_field_loading_profile"):
		var profile: Dictionary=current_scene.call("get_field_loading_profile")
		if profile.get("setup_identity_current")==true and profile.get("Field_instance")==current_scene.get_instance_id() and profile.get("scene_instance")==current.get_instance_id(): last_Field_profile=profile
	if trace_count>=96 or public_state.get("scene_id")!=String(ID): return
	var scalar: Dictionary={"same_current_owner":same_owner,"live_owner":live_token,"active":state.get("active"),"token":state.get("token"),"scene_id":state.get("scene_id"),"sources_finalized":state.get("sources_finalized"),"source_worker_active":state.get("source_worker_active")}
	var signature: String=JSON.stringify([public_state.get("request_generation"),public_state.get("phase"),field_state.get("stage"),field_state.get("complete"),field_state.get("failed"),scalar])
	if signature==trace_signature: return
	trace_signature=signature;trace_count+=1
	var stamp: Dictionary=clock_fact();stamp["elapsed_usec"]=int(stamp.usec)-requested_usec
	records.append({"kind":"PERF03_PHASE_CLOCK","clock":stamp,"public":public_state,"Field_loading_state":field_state,"C_scalars":scalar,"previous_observe_gap_usec":gap,"max_observe_gap_usec":max_observe_gap_usec,"no_extra_yield_worker_or_hash":true})

func post_draw_readonly() -> void:
	if requested_usec<=0 or not draw_fact.is_empty() or not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): return
	var current: SceneScript=current_scene.get("_current_scene") as SceneScript
	var actor: CharacterBody2D=current_scene.get("_player") as CharacterBody2D
	if current==null or current.scene_id!=ID or actor==null or not actor.can_process() or actor.get("can_move")!=true: return
	var state: Dictionary=current_scene.call("get_field_loading_state")
	var lm: Node=root.get_node("LoadingManager");var screen: Node=lm.get("_screen")
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	if state.get("complete")!=true or state.get("failed",false) or lm.get("_external_active")==true or lm.get("_transition_active")==true or (panel!=null and panel.is_visible_in_tree()): return
	if C._resident_ready.get("scene")!=current or C._resident_ready.get("sources_finalized")!=true: return
	# Timestamp before natural source-map copy/compare or source final hashes.
	draw_fact=clock_fact()
	draw_fact.merge({"elapsed_usec":int(draw_fact.usec)-requested_usec,"Field":current_scene.get_instance_id(),"Scene":current.get_instance_id(),"Player":actor.get_instance_id(),"loading_hidden_inactive":true,"can_move":true})

func natural_receipt_only() -> bool:
	var current: SceneScript=current_scene.get("_current_scene") as SceneScript
	var proof: Dictionary=C._resident_ready
	var sources: Dictionary=proof.get("sources",{}).duplicate()
	var identity: Dictionary={"scene_matches":proof.get("scene")==current,"scene_id":String(proof.get("id",&"")),"token":proof.get("token"),"sources_finalized":proof.get("sources_finalized"),"proof_kind":proof.get("proof_kind"),"sources_count":sources.size(),"native_scene_path":current.resource_path,"native_layout_path":current.map_layout.resource_path}
	records.append({"kind":"PERF03_NATURAL_C_RECEIPT_SELECTIVE_READ","identity":identity,"sources":sources,"no_resident_receipt_matches_or_collector_call":true})
	if not check(identity.scene_matches and identity.scene_id==String(ID) and int(identity.token)>0 and identity.sources_finalized==true and identity.proof_kind=="PRECOMPUTED_PUBLISHED_FULL_SOURCE_V1","Natural same-owner completed public CITY proof"): return false
	if not check(sources==fixture.expected_city_source_sha256,"Natural full1217 source map equals independent owner1292"): return false
	return check(current.resource_path==fixture.scene_path and current.map_layout.resource_path==fixture.layout_path,"Frozen Scene/layout identity only, no geometry validation")

func exercise_cpu() -> bool:
	requested_usec=Time.get_ticks_usec()
	if not check(root.get_node("SceneRouter").call("go_field_smart",ID,null),"Sole public default-null Yamen request"): return false
	while Time.get_ticks_msec()<deadline:
		observe_readonly()
		var public_state: Dictionary=root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if public_state.get("scene_id")==String(ID) and public_state.get("phase")=="FAILED":
			records.append({"kind":"PERF03_TERMINAL_FAILURE","public":public_state,"C_errors":C.errors(),"last_matching_C":last_matching_C,"last_Field_profile":last_Field_profile,"last_LM":last_LM})
			return check(false,"Public Yamen failed; no success loading time")
		if not draw_fact.is_empty():
			# Receipt checks occur only after the frozen ready/draw clocks.
			var owner_ok: bool=natural_receipt_only()
			records.append({"kind":"PERF03_ONE_DEFAULT_ENTRY_RESULT","functional_entry_and_natural_owner_ok":owner_ok,"ready":ready_fact,"hidden_canmove_firstdraw":draw_fact,"first_under10s":int(draw_fact.elapsed_usec)<int(fixture.firstdraw_target_usec),"target_usec":fixture.firstdraw_target_usec,"performance_report_separate_from_functional_completion":true,"last_matching_active_C":last_matching_C,"last_same_token_finalized_C":last_finalized_C,"Field_profile":last_Field_profile,"LM":last_LM,"max_observe_gap_usec":max_observe_gap_usec,"missing_reset_metrics_not_zero_or_fresh":true,"nested_wall_timings_not_additive":true,"no_picture_input_geometry_or_other_region_credit":true})
			return owner_ok
		await process_frame
	records.append({"kind":"PERF03_TIMEOUT","ready":ready_fact,"draw":draw_fact,"last_matching_C":last_matching_C,"Field_profile":last_Field_profile,"LM":last_LM,"max_observe_gap_usec":max_observe_gap_usec})
	return check(false,"Fixed60s whole exhausted; no added arrival budget")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	RenderingServer.frame_post_draw.connect(post_draw_readonly)
	var complete: bool=false
	if precheck(): complete=await exercise_cpu()
	if RenderingServer.frame_post_draw.is_connected(post_draw_readonly): RenderingServer.frame_post_draw.disconnect(post_draw_readonly)
	finish("res://build/luoyang_city_full_rollout_20261022ap_qa01/yamen_performance03_LIGHT_ROOT16_READY/%d_%d"%[OS.get_process_id(),began],began,complete,"YAMEN_PERF03_ONE_DEFAULT_PUBLIC_ENTRY_0INPUT_0PICTURE_NO_GEOMETRY_OR_COLLECTOR")
