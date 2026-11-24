extends "res://tests/test_luoyang_annex_yamen_only_key_20261016.gd"
## Independent ordinary single-birth smoke. No lane/room/route replay.
## ROOT fills exact actual candidate/result + sole-bool provenance in NEW file.
const FORMAL_READY=true
const FORMAL_RUNTIME_SHA="7021af9aeef4565e239d0fc535c70f63cb5a99505d89e5f693663e196885af74"
const FORMAL_FALSE_PATH="res://build/luoyang_interiors10_20261016_root01/yamen_runtime_false_before_formal.gd.txt"
const FORMAL_FALSE_SHA="3b57b024afc09219490ca2d53e0ed3eab3b134f184597b0ed019c10823c857e5"
const FORMAL_CANDIDATE_PATH="res://build/luoyang_annex_yamen_only_key_20261016/35568_2861/result.json"
const FORMAL_CANDIDATE_SHA="bcfbb5bfab3e5bdeb5a7c43aaa6651e97bd0195963bb933219b9f4daac465ea0"
const YAMEN_KEY_PATH="res://tests/test_luoyang_annex_yamen_only_key_20261016.gd"
const YAMEN_KEY_SHA="e53dd8dc37ae76ed45449f90aaec53da7d28cd3aee440d4f7648dc99b4ed0103"

func _precheck() -> bool:
	if not _check(FORMAL_READY,"Explicit ordinary source readiness, draft must refuse"): return false
	if not _track(YAMEN_KEY_PATH,YAMEN_KEY_SHA) or not _track(YAMEN_PARENT_PATH,YAMEN_PARENT_SHA) or not _track(BASE_PATH,BASE_SHA): return false
	for path: String in FINAL_PINS:
		if path==ANNEX_PATH: continue
		if not _track(path,FINAL_PINS[path]): return false
	if not _track(ANNEX_PATH,FORMAL_RUNTIME_SHA) or not _track(FORMAL_FALSE_PATH,FORMAL_FALSE_SHA) or not _track(FORMAL_CANDIDATE_PATH,FORMAL_CANDIDATE_SHA): return false
	var previous:=FileAccess.get_file_as_string(FORMAL_FALSE_PATH)
	var current:=FileAccess.get_file_as_string(ANNEX_PATH)
	if not _check(previous.count("const FORMAL_ENABLED=false")==1 and previous.replace("const FORMAL_ENABLED=false","const FORMAL_ENABLED=true")==current,"Complete exact sole-bool false-to-true edit"): return false
	var candidate: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(FORMAL_CANDIDATE_PATH))
	if not _check(candidate.complete==true and candidate.failures==0 and candidate.shared_ms==90000 and candidate.arrival_ms==60000 and candidate.source_before==candidate.source_after and candidate.players_before==candidate.players_after,"Reuse only exact completed Yamen-only candidate, not timed-out26088"): return false
	annex=load(ANNEX_PATH)
	if not _check(annex!=null and annex.FORMAL_ENABLED and annex.enabled() and annex.FLAG not in OS.get_cmdline_user_args(),"Ordinary formal default-enabled Yamen, no candidate flag"): return false
	var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(annex.BIND_PATH))
	if not _track(annex.BIND_PATH,annex.BIND_SHA): return false
	for path: String in config.source_sha256:
		if not source_before.has(path) and not _track(path,config.source_sha256[path]): return false
	if not _track(config.manifest_path,config.manifest_sha256): return false
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(config.manifest_path))
	manifest_records["ch4_s1_luoyang_yamen"]=manifest.record
	candidate_manifest_paths["ch4_s1_luoyang_yamen"]=config
	var canonical:=ResourceLoader.load("res://data/scenes/ch4_s1_luoyang_yamen.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var closure: Dictionary=C._transition_sources(canonical,false)
	if not _check(not closure.is_empty(),"Full current production-declared Yamen source closure"): return false
	for path: String in closure:
		if not source_before.has(path) and not _track(path): return false
	for path: String in annex.source_paths():
		if not source_before.has(path) and not _track(path): return false
	return _track(get_script().resource_path)

func _exercise() -> bool:
	var setup: Dictionary={"id":"ch4_s1_luoyang_yamen","size":Vector2(3072,2048),"setup_foot":Vector2(2190,1260)}
	if not await _setup(setup): return false
	rows.append({"kind":"ORDINARY_FORMAL_SINGLE_BIRTH","scene_id":String(scene.scene_id),"source_candidate_sha":FORMAL_CANDIDATE_SHA,"actual_foot":(field.get("_player") as Node2D).position,"ordinary_without_candidate_flag":true,"no_lanes_room_or_route_replay":true})
	return await _overview("ordinary_formal_yamen_annex_birth")

func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+YAMEN_SHARED_MS
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players()
	output="res://build/luoyang_annex_formal_birth_20261016/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var complete:=false
	if _precheck():
		_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1,"Actual ordinary normal-clock GPU")
		driver=INPUT.new(); driver.call("configure",self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4); initialized=true
		complete=await _exercise()
	if initialized: root.get_node("SceneRouter").call("reset_for_new_game")
	if driver!=null: driver.call("release"); driver=null
	if oracle!=null: oracle.call("release"); oracle=null
	field=null; scene=null
	if initialized and is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	if initialized: await process_frame; await process_frame
	var after: Dictionary={}
	for path: String in source_before: after[path]=_fact(path)
	var players_after:=_players()
	_check(after==source_before and players_after==players_before and bridge.call("is_checkpoint_saves_suspended")==true,"Exact ordinary closure/15saves before-after, no restoration")
	_check(complete and Time.get_ticks_msec()<deadline,"Independent90s/arrival60 ordinary birth only")
	var file:=FileAccess.open(output.path_join("result.json"),FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"scope":"ORDINARY_YAMEN_ANNEX_SINGLE_BIRTH_NOT_LANES_OR_ROOM_REPLAY","complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"shared_ms":YAMEN_SHARED_MS,"arrival_ms":ARRIVAL_MS,"records":rows,"captures":captures,"source_before":source_before,"source_after":after,"players_before":players_before,"players_after":players_after,"candidate_result_sha256":FORMAL_CANDIDATE_SHA},"\t")); file.close()
	else: failures+=1
	print("YAMEN_FORMAL_BIRTH=",output,"/result.json")
	quit(0 if complete and failures==0 else 1)
