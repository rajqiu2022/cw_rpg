extends "res://tests/test_luoyang_temple_assembly_gpu_key_20261016.gd"
## Ordinary one birth only; seven station partial evidence remains an overall FAIL.
const FORMAL_READY=true
const FORMAL_HELPER_SHA="f7ff4265d6de61b1e00cf1334e3074d072e878b88a8af575c01e221e23dd39bc"
const FALSE_BACKUP="res://build/luoyang_temple_assembly_20261016_root01/helper_before_formal_5F72BB04.source"
const CANDIDATE_RESULT="res://build/luoyang_temple_assembly_exit_only_20261016/70888_2428/result.json"
const CANDIDATE_SHA="90ba39dec4721c47c6f7e99ece56812134f484a5c0bd3c7d00bfed00840e8253"
const STATION_RESULT="res://build/luoyang_temple_assembly_gpu_20261016/16808_2451/result.json"
const STATION_SHA="eacdf0232c9ad750768ef4c51601f3a55a25e5a470bffb2503abd1e275acfb60"
const GPU_BASE_SHA="71df21799e772eb1c4e9c4e7ced7d22a2eba6f353addfb2e9eb5d47eeabde474"
func precheck() -> bool:
	if not check(FORMAL_READY and A.FORMAL_ENABLED and A.FLAG not in OS.get_cmdline_user_args(),"Ordinary formal ready; no candidate flag"): return false
	if not track("res://tests/test_luoyang_temple_assembly_gpu_key_20261016.gd",GPU_BASE_SHA) or not track("res://tests/test_luoyang_temple_assembly_cpu_key_20261016.gd",BASE_SHA): return false
	if not track(CANDIDATE_RESULT,CANDIDATE_SHA) or not track(CPU_RESULT,CPU_SHA): return false
	var candidate: Variant=JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_RESULT))
	if not check(candidate is Dictionary and candidate.complete and candidate.failures==0,"Bound actual candidate completed, not draft or partial"): return false
	if not track(STATION_RESULT,STATION_SHA): return false
	var stations: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(STATION_RESULT))
	var station_count:=0
	for row: Dictionary in stations.records:
		if row.get("kind")=="ACTUAL_STATION": station_count+=1
	if not check(not stations.complete and stations.failures==2 and station_count==7,"Seven actual station rows only; original overall FAIL preserved"): return false
	rows.append({"kind":"REUSED_LIMITED_EVIDENCE","station_result":STATION_RESULT,"station_overall_pass":false,"station_rows":station_count,"exit_result":CANDIDATE_RESULT,"exit_overall_pass":true})
	if not track(FALSE_BACKUP,PINS[A.SELF]) or not track(A.SELF,FORMAL_HELPER_SHA): return false
	var old:=FileAccess.get_file_as_string(FALSE_BACKUP)
	var now:=FileAccess.get_file_as_string(A.SELF)
	var marker:="const FORMAL_ENABLED=false"
	if not check(old.count(marker)==1 and old.replace(marker,"const FORMAL_ENABLED=true")==now,"Exactly one formal bool edit; no other source exemptions"): return false
	for path: String in PINS:
		if path!=A.SELF and not track(path,PINS[path]): return false
	if not track(PUBLISHER_PATH,PUBLISHER_SHA) or not track(A.BIND_PATH,FINAL_BIND_SHA): return false
	config=A.binding(); author=A.author(config)
	if not check(A.BIND_SHA==FINAL_BIND_SHA and A.structure_valid(config,author),"Exact unchanged binding/full import closure"): return false
	for path: String in config.source_sha256:
		if not track(path,config.source_sha256[path]): return false
	for path: String in A.source_paths():
		if not before.has(path) and not track(path): return false
	for path: String in candidate.source_after:
		if path==A.SELF:
			if not check(candidate.source_after[path].sha256==PINS[A.SELF],"Candidate helper was exact protected false source"): return false
		elif not track(path,String(candidate.source_after[path].sha256)): return false
	child=ResourceLoader.load(A.SCENE_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	geometry=ORACLE.new()
	return check(child!=null and A.is_scene(child) and child.actor_positions_are_feet and geometry.configure(author,WORLD),"Exact formal child/sourcefeet independent oracle") and track(get_script().resource_path)
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+60000
	output="res://build/luoyang_temple_assembly_formal_birth_20261016/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players=saves()
	var complete:=false
	if precheck():
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		var call_start:=Time.get_ticks_msec()
		var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",A.ID,null,"",-1,-1)
		rows.append({"kind":"ORDINARY_PUBLIC_ENTRY","accepted":accepted,"call_ms":Time.get_ticks_msec()-call_start,"shared_ms":60000,"arrival_ms":ARRIVAL_MS})
		if check(accepted,"Actual ordinary public entry") and await wait_arrival(): complete=await capture("ordinary_temple_birth")
		root.get_node("SceneRouter").call("reset_for_new_game")
		await process_frame; await process_frame
	field=null; child=null; geometry=null
	rows.append({"kind":"ORDINARY_BIRTH_ONLY","captures":captures,"no_repeated_cpu_stations_exits_or_rewards":true})
	finish("luoyang_temple_assembly_formal_birth_20261016",began,complete)
