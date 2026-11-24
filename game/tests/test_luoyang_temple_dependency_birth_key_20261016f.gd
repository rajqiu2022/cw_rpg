extends "res://tests/test_luoyang_temple_assembly_gpu_key_20261016.gd"
## Only v2 dependency rebinding ordinary birth. Not old seven-station replay.
const DEPENDENCY_READY=true
const DEPENDENCY_HELPER_SHA="d397be2a64670b67091a47ae85c1a34db47fc4cdbbd1f2bfcc091614e5ae78b7"
const DEPENDENCY_BIND_SHA="340e52b6b1cb991e1ecf555a0dabfcfcba6e933972b2b54d2124e200d8cd2f24"
func precheck() -> bool:
	if not check(DEPENDENCY_READY and A.FORMAL_ENABLED and A.FLAG not in OS.get_cmdline_user_args() and "--luoyang-district-life-20261016f" not in OS.get_cmdline_user_args(),"Explicit ordinary v2 source-ready, no candidate flags"): return false
	if not track(A.SELF,DEPENDENCY_HELPER_SHA) or not track(A.BIND_PATH,DEPENDENCY_BIND_SHA): return false
	config=A.binding(); author=A.author(config)
	if not check(A.BIND_SHA==DEPENDENCY_BIND_SHA and A.structure_valid(config,author),"v2 exact full own Temple closure, not C-city receipt"): return false
	for path: String in config.source_sha256:
		if not track(path,config.source_sha256[path]): return false
	for path: String in A.source_paths():
		if not before.has(path) and not track(path): return false
	if not track("res://tests/helpers/temple_assembly_raw_oracle_20261016.gd","d66cdad0a2f1cfd172f7ffc083f142e22723ae181f2b1ca0451389d801a506ae"): return false
	child=ResourceLoader.load(A.SCENE_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	geometry=ORACLE.new()
	return check(child!=null and A.is_scene(child) and geometry.configure(author,WORLD),"Unchanged own temple geometry/sourcefeet") and track(get_script().resource_path)
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+60000
	output="res://build/luoyang_temple_dependency_birth_20261016f/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players=saves()
	var complete:=false
	if precheck():
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",A.ID,null,"",-1,-1)
		if check(accepted,"One ordinary public Temple dependency entry") and await wait_arrival(): complete=await capture("ordinary_v2_temple_birth")
		root.get_node("SceneRouter").call("reset_for_new_game"); await process_frame; await process_frame
	field=null; child=null; geometry=null
	rows.append({"kind":"DEPENDENCY_BIRTH_ONLY","captures":captures,"shared_ms":60000,"arrival_ms":ARRIVAL_MS,"seven_stations_tasks_exits_not_repeated":true})
	finish("luoyang_temple_dependency_birth_20261016f",began,complete)
