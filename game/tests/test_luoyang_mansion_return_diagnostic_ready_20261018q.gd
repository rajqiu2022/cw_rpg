extends "res://tests/test_luoyang_three_doors_actual_retry3_20261018q.gd"
## NOTREADY: one mansion only; original approach/Space/2s return predicate is inherited unchanged.
const MANSION_DIAG_READY=true
const MANSION_ID="luoyang_functional_mansion_candidate_20261016"
const MANSION_WHOLE_MS=90000
var last_wait_sample: Dictionary={}
var phase_samples: Array[Dictionary]=[]
var sample_signature: String=""
var wait_target: String=""
var wait_started_usec:=0
var sample_count:=0
func _precheck_actual() -> bool:
	if not check(MANSION_DIAG_READY,"NOTREADY until ROOT reviews mansion-only bounded observer"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty(),"Ordinary GUI/no spacing or other candidate flag"): return false
	var pins: Dictionary={M.SELF:"d82232b96035f365652831238bad490e79dc973b75d3550c79d6ab6b2070b979",M.REGISTRY_PATH:"959bc6f5408261586a6165bf731347959e6287bea9afa8bfb40f6e4035302ad5",CONTRACT:CONTRACT_SHA,RAW_PATH:RAW_SHA,"res://tests/test_luoyang_three_doors_actual_retry3_20261018q.gd":"52aaaa3db603ba52504cd7dff1667e18d5f1013020d362fa7897181fb086b8e2","res://tests/test_luoyang_three_exterior_doors_cpu_20261016g.gd":"91c09043fc1ad85fb392909ed3b6235ddf064dee3bea943365c91cd88fdb5b89","res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd":"a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895","res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7","res://scripts/field/field_walkable_controller.gd":"638cd8f0a37aacff56d074383d868f2d00bab3b81fcf56bf4d148fb84f556839","res://scripts/autoload/scene_router.gd":"9cfbf3d17cb263b63d50558b5d95a574286bfe921da45dccda04a84272caa869","res://scripts/autoload/loading_manager.gd":"5550a037e8001069713b0af317a6db2cd2ac427189f8f75d2e87e755ece210db","res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"06244b1dc286149ce8299cd83f766d2d9f5fd9b61bcb59180261dff40d8e9d3d","res://scripts/city/luoyang_harbour_life_runtime_20261016.gd":"1a269bc65df4aa70edd59a67ee5415768bee039ea52188939905746a99ef61ad","res://scripts/city/luoyang_district_life_20261016f.gd":"6921fa796c419202fc9707559addabdb013ea0b37ec51e6303e9f4923a79fc17","res://scripts/city/luoyang_resident_field_20261016.gd":"f1730e461fe6328763cfd70c79b2bbc36c80a2afb7609c364fa7ea7af8acdd7f","res://scripts/city/luoyang_temple_assembly_20261016.gd":"cde7675f20904610c3fba203e2a4fa9bb947d049e23f2e154a2d9c0ff1b56f90","res://data/maps/luoyang_temple_assembly_20261016/binding_spacing_fusion_v11.json":"33dcf6d9e1eb55841951c5610f71d021deb5ba3f0ed72bc3d617131e07c1d3be"}
	for path: String in pins:
		if not track(path,pins[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	package=M.catalogue()
	if not check(M.FORMAL_ENABLED and package.get("rooms",{}).has(MANSION_ID),"Same default new-room catalogue, no synthetic room"): return false
	for path: String in package.source_sha256:
		if not track(path,package.source_sha256[path]): return false
	var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	var navigation: Dictionary=contract.combined_navigation_sources
	if not check(navigation.size()==9 and navigation.get("world_size_px") is Array and _v(navigation.world_size_px)==WORLD,"Exact immutable mixed contract/world domain"): return false
	for key: String in ["district_author","district_binding","district_geometry","district_runtime"]:
		var declared: Variant=navigation.get(key)
		if not check(declared is Dictionary and declared.has("path") and declared.has("sha256"),"Original explicit source dictionary "+key): return false
		# Only the approved current District dependency differs. The immutable
		# old contract and old CPU source facts remain separately pinned above.
		var expected: String=pins.get(String(declared.path),String(declared.sha256))
		if not track(declared.path,expected): return false
	author=JSON.parse_string(FileAccess.get_file_as_string(navigation.district_author.path))
	return true
func _sample_wait_state() -> void:
	# Small scalar/value-only observation. No C receipt/source collector, SHA,
	# image/storage traversal, resource loading, waiting, or production mutation.
	var router: Node=root.get_node("SceneRouter")
	var lease: Dictionary=router.call("get_resident_city_state")
	var returning: Dictionary=lease.get("return",{})
	var public: Dictionary=router.call("get_public_city_preparation_state")
	var loading: Node=root.get_node("LoadingManager")
	var screen: Node=loading.get("_screen")
	var panel: Control=screen.get("root") as Control if is_instance_valid(screen) else null
	var active: Node=current_scene if is_instance_valid(current_scene) else null
	var state: Dictionary=active.call("get_field_loading_state") if active!=null and active.has_method("get_field_loading_state") else {}
	var player: Node2D=active.get("_player") as Node2D if active!=null else null
	var definition: SceneScript=active.get("_current_scene") as SceneScript if active!=null else null
	sample_count+=1
	last_wait_sample={"frame":Engine.get_process_frames(),"sample_usec":Time.get_ticks_usec(),"wait_target":wait_target,"wait_elapsed_usec":Time.get_ticks_usec()-wait_started_usec if wait_started_usec>0 else 0,"current_field_id":active.get_instance_id() if active!=null else 0,"current_scene_id":String(definition.scene_id) if definition!=null else "","field_complete":state.get("complete",false),"field_failed":state.get("failed",false),"field_stage":state.get("stage",""),"can_move":bool(player.get("can_move")) if player!=null else false,"player_foot":player.position if player!=null else Vector2(INF,INF),"loading_visible":panel.is_visible_in_tree() if panel!=null else false,"external_active":loading.get("_external_active"),"transition_active":loading.get("_transition_active"),"lease_occupied":lease.get("occupied",false),"lease_parked":lease.get("parked",false),"lease_phase":lease.get("phase",""),"return_phase":returning.get("phase",""),"return_active":returning.get("active",false),"return_token":returning.get("token",0),"return_hit":returning.get("hit",false),"return_identity":returning.get("final_live_identity",false),"return_field_id":returning.get("field_id",0),"return_metadata_ms":returning.get("metadata_ms",0.0),"return_resume_ms":returning.get("resume_ms",0.0),"return_total_ms_excludes_hide":returning.get("total_ms",0.0),"public_phase":public.get("phase",""),"public_token":public.get("token",0)}
	var signature: String=str([wait_target,last_wait_sample.current_scene_id,last_wait_sample.field_stage,last_wait_sample.field_complete,last_wait_sample.can_move,last_wait_sample.loading_visible,last_wait_sample.lease_phase,last_wait_sample.return_phase,last_wait_sample.public_phase])
	if signature!=sample_signature:
		sample_signature=signature
		if phase_samples.size()==48: phase_samples.pop_front()
		phase_samples.append(last_wait_sample.duplicate(true))
func _wait_actual(id: StringName,arrival_ms: int) -> bool:
	wait_target=String(id);wait_started_usec=Time.get_ticks_usec();_sample_wait_state()
	var result: bool=await super._wait_actual(id,arrival_ms)
	_sample_wait_state()
	records.append({"kind":"MANSION_WAIT_LAST_SNAPSHOT","target":id,"limit_ms":arrival_ms,"success":result,"snapshot":last_wait_sample.duplicate(true),"bounded_phase_samples":phase_samples.duplicate(true),"samples":sample_count,"original_resident_receipt_and_deadline_checks_preserved":true,"observer_instrument_changed":true})
	return result
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+MANSION_WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_mansion_return_diagnostic_20261018q/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=_precheck_actual()
	if complete:
		driver=INPUT.new();driver.configure(self)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		process_frame.connect(_sample_wait_state)
		var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT));var matches: Array[Dictionary]=[]
		for door: Dictionary in contract.doors:
			if door.room_id==MANSION_ID: matches.append(door)
		complete=check(matches.size()==1,"Exactly one original mansion door; pawn/warehouse NOT rerun")
		if complete: complete=await _trip_door(matches[0])
		_sample_wait_state();process_frame.disconnect(_sample_wait_state)
	if driver!=null: driver.release();driver=null
	if is_instance_valid(current_scene):
		var own: Node=current_scene;var weak: WeakRef=weakref(own);current_scene=null;own.queue_free();field=null;scene=null;own=null
		await process_frame;await process_frame
		if not check(weak.get_ref()==null,"Own diagnostic current Field tree-exited"): complete=false
	contexts.clear();independent=null;active_mask=null
	records.append({"kind":"MANSION_ONLY_DIAGNOSTIC_SCOPE","doors":door_rows,"captures":pictures,"whole_ms":MANSION_WHOLE_MS,"arrival_ms":ARRIVAL_MS,"return_ms":RETURN_MS,"last_snapshot":last_wait_sample,"bounded_phases":phase_samples,"source_oracle_or_return_predicates_weakened":false,"spacing_flag":false,"pawn_retested":false})
	complete=check(door_rows.size()==1 and pictures.size()==1,"One mansion true entry/exact return, original2s predicate") and complete
	finish(folder,began,complete,"MANSION_ONLY_ORIGINAL2S_RETURN_WITH_BOUNDED_PASSIVE_PHASE_DIAGNOSTIC")
