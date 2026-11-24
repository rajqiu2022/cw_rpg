extends "res://tests/test_live_city_world_gate_warm_key_20261017j.gd"
## Ordinary real Space warm reentry only. Candidate lifecycle negatives reused.
const FORMAL_READY=true
const FORMAL_RESIDENT_SHA="f1730e461fe6328763cfd70c79b2bbc36c80a2afb7609c364fa7ea7af8acdd7f"
const RESIDENT_PATH="res://scripts/city/luoyang_resident_field_20261016.gd"
const FALSE_BACKUP="res://build/luoyang_load_acceleration_20261017j_root01/deployment_before/luoyang_resident_field_20261016.gd"
const MAIN_SOURCE="res://tests/test_live_city_world_gate_warm_key_20261017j.gd"
const CANDIDATE_RESULT="res://build/luoyang_live_city_world_gate_20261017j/54952_2536/result.json"
func precheck() -> bool:
	if not check(FORMAL_READY and not FINAL_SOURCE_PINS.is_empty(),"Formal exact deployed dependencies, no candidate flag"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0,"Real GPU/native clock"): return false
	if not check(OS.get_cmdline_user_args().is_empty() and LEASE.LIVE_WORLD_FORMAL_ENABLED,"Ordinary no user args and exact live lease formal true"): return false
	if not track(BASE_ENTRY,BASE_ENTRY_SHA) or not track(COLD_RESULT,COLD_RESULT_SHA): return false
	var evidence: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(COLD_RESULT))
	if not check(evidence.get("complete")==true and evidence.get("failures")==0,"Reuse i96048 real world entrance/cold profile, not new profiling suite"): return false
	if not track(MAIN_SOURCE,"5d58e78714760b29f82fc8a0d22355883e45a6a3609128037e2ac15a12ba2118") or not track(CANDIDATE_RESULT,"6d8cd9fc32c046ca7f6d00ebd789406fa1b4e771f4f3a4c6584c79b082c35756"): return false
	var candidate: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_RESULT))
	if not check(candidate.get("complete")==true and candidate.get("failures")==0 and candidate.get("checks")==461,"Exact successful real-world candidate proof reused, no whole suite repetition"): return false
	if not track(FALSE_BACKUP,"20086323c7aca3bb3efe51b77cdad393ec5e4ccdacdf98856eaca4beccd22624"): return false
	var old_text: String=FileAccess.get_file_as_string(FALSE_BACKUP)
	var current_text: String=FileAccess.get_file_as_string(RESIDENT_PATH)
	if not check(old_text.count("const LIVE_WORLD_FORMAL_ENABLED := false")==1 and old_text.replace("const LIVE_WORLD_FORMAL_ENABLED := false","const LIVE_WORLD_FORMAL_ENABLED := true")==current_text,"Only exact one resident formal bool differs from full old source"): return false
	for path: String in FINAL_SOURCE_PINS:
		var expected: String=FORMAL_RESIDENT_SHA if path==RESIDENT_PATH else FINAL_SOURCE_PINS[path]
		if not track(path,expected): return false
	var approval: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(STABLE.APPROVAL_PATH))
	for path: String in approval.source_sha256:
		if not track(path,approval.source_sha256[path]): return false
	var historical: Dictionary=GATE.runtime_manifest()
	if not check(historical.get("asset_sha256",{}).size()==56,"Original immutable56 catalog, no historical pin rewrite"): return false
	var authorized: int=0;var unchanged: int=0
	for path: String in historical.asset_sha256:
		if STABLE.handles(path):
			var effective: String=STABLE.effective_sha(path,historical.asset_sha256[path])
			if not check(effective.length()==64,"Actual FINAL exact8 approval plus raw/import/ctex pair identity") or not track(path,effective): return false
			authorized+=1
		else:
			if not track(path,historical.asset_sha256[path]): return false
			unchanged+=1
	if not check(authorized==8 and unchanged==48,"Only exact8 variants; remaining48 actual historical SHA unchanged"): return false
	for paths: Dictionary in [STABLE.source_paths(),OFFICE.source_paths()]:
		for path: String in paths:
			if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	if not track(R.BIND_PATH,FINAL_BIND_SHA): return false
	package=R.binding();author=R.author(package)
	if not check(R.cpu_proof_valid(package,author),"Existing district CPU geometry reused; no old city rebuild"): return false
	for path: String in R.source_paths():
		if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	for path: String in [get_script().resource_path,"res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd","res://data/scenes/world_map_jianghu.tres"]:
		if not track(path,FileAccess.get_sha256(path)): return false
	return true

func _exercise() -> bool:
	var router: Node=root.get_node("SceneRouter")
	var definition: SceneScript=ResourceLoader.load("res://data/scenes/world_map_jianghu.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var portals: Array=[]
	for item: Dictionary in definition.map_layout.portals:
		if item.get("target_scene")==GATE_ID: portals.append(item)
	if not check(portals.size()==1,"Original unique world Gate entry"): return false
	var entry: Vector2=portals[0].pos*Vector2(12288,8192)
	var setup: Vector2=entry+Vector2(0,96)
	var accepted: bool=router.call("go_field_smart",StringName(WORLD_ID),setup/Vector2(12288,8192),"",15)
	records.append({"kind":"ORDINARY_PUBLIC_LEGAL_NEAR_SETUP_NOT_LONG_TRAVEL","accepted":accepted,"entry":entry,"setup":setup})
	if not check(accepted,"One public world current15 near-entry setup") or not await _wait_once(WORLD_ID) or not _world_bind(): return false
	if not await _walk(PackedVector2Array([field.get("_player").position,entry])) or not _zone(GATE_ID) or not await _space_to(GATE_ID,"ORDINARY_FIRST_COLD_GATE"): return false
	district="gate";scene_id=GATE_ID
	if not _bind_actual() or not check(GATE.bound(field.get("_harbour_gate_visual_scene")) and field.get("_player").position==Vector2(1536,1860),"Actual original fortified visual parent/Harbour Gate arrival"): return false
	if not _zone("","world_map") or not _retain_gate(): return false
	if not await _space_to(WORLD_ID,"ORDINARY_REAL_GATE_EXIT_WORLD") or not _world_bind(): return false
	var parked: Dictionary=router.call("get_resident_city_state")
	var player: CharacterBody2D=retained.get("_player")
	if not check(parked.get("occupied")==true and parked.get("parked")==true and parked.get("excursion_kind")=="world" and parked.get("field_id")==retained.get_instance_id() and not retained.is_inside_tree() and not player.is_inside_tree() and not PhysicsServer2D.body_get_space(player.get_rid()).is_valid() and parked.get("estimated_bytes",LEASE.LIMIT_BYTES+1)<=LEASE.LIMIT_BYTES,"Actual world after Space with same bounded city outside tree and physics",parked): return false
	validations_before=int(C.transition_validation_state().get("full_validations_total"));watch_jobs=true
	if not await _walk(PackedVector2Array([field.get("_player").position,entry])) or not _zone(GATE_ID): return false
	if not await _space_to(GATE_ID,"ORDINARY_SECOND_SAME_GATE_AFTER_REAL_WORLD",true): return false
	watch_jobs=false;oracle=retained_oracle;district="gate";scene_id=GATE_ID
	if not _same_gate() or not check(field.get("_player").position==Vector2(1536,1860) and _clear(Vector2(1536,1860)),"Ordinary exact original arrival/native34x24/full87517/Physics"): return false
	return await _walk(PackedVector2Array([Vector2(1536,1860),Vector2(1568,1860)])) and await _capture("ordinary_same_gate_warm")

func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+WARM_WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_live_city_ordinary_warm_20261017j/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete:=false
	if precheck():
		driver=INPUT.new();driver.configure(self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		complete=await _exercise()
	if driver!=null: driver.release();driver=null
	root.get_node("SceneRouter").call("reset_for_new_game")
	if is_instance_valid(current_scene): current_scene.queue_free()
	await process_frame;await process_frame
	field=null;scene=null;oracle=null;retained=null;retained_scene=null;retained_oracle=null;retained_static.clear();retained_nav.clear();retained_crowd.clear();frame_images.clear()
	records.append({"kind":"SCOPE","whole_ms":160000,"arrival_ms":60000,"warm_limit_usec":2000000,"captures":captures,"native_queries":native_queries,"ordinary_no_flags":true,"candidate_cancel_clone_newgame_evidence_reused":true,"warm_fresh_disk_sha":false,"eleven_rooms_enabled":false})
	finish(folder,began,complete,"ORDINARY_REAL_WORLD_GATE_WORLD_SAME_GATE_WARM")



