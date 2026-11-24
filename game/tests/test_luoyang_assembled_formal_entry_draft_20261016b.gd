extends "res://tests/test_luoyang_assembled_scenes_key_retry2_20261016b.gd"
## Independent NEW90s ordinary smoke; never calls parent candidate precheck/run.
## Candidate actual PASS + ROOT exact bool backups/pins are mandatory first.
const FORMAL_SOURCE_READY := false
const FORMAL_LIMIT_MS := 90000
const CANDIDATE_RESULT_PATH := "PENDING_ROOT_ACTUAL_SUCCESS"
const CANDIDATE_RESULT_SHA := "PENDING_ROOT_ACTUAL_SUCCESS"
const BASE_PATH := "res://tests/test_luoyang_assembled_scenes_key_retry2_20261016b.gd"
const BASE_SHA := "d6c946ab17e6fbd7b414b43a576d0bbd1317d2cc0b37c83393b6fc4b7828ff68"
const FORMAL_PATCHES := {
	"res://scripts/city/luoyang_assembled_rooms_20261016b.gd":{"old_sha":"6e2d7d3c13c3e5b54da5905619f1db014beecb1f0293c161c09108dda6a5e094","new_sha":"PENDING_ROOT_BOOL_TRUE","backup_path":"PENDING_ROOT_FALSE_FULL_SOURCE"},
	"res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd":{"old_sha":"f1e339e2780a02fe27ae006f38a896559c0fc16f5f839b179fab75977232aefe","new_sha":"PENDING_ROOT_BOOL_TRUE","backup_path":"PENDING_ROOT_FALSE_FULL_SOURCE"}
}

func _precheck() -> bool:
	if not _check(FORMAL_SOURCE_READY,"Formal draft cannot execute before actual candidate and ROOT bool proof"): return false
	if not _check(ASSEMBLY.FORMAL_ENABLED and R.FORMAL_ENABLED and ASSEMBLY.FLAG not in OS.get_cmdline_user_args(),"Ordinary default-enabled runtime with no candidate flag"): return false
	if not _track(BASE_PATH,BASE_SHA) or not _track(CANDIDATE_RESULT_PATH,CANDIDATE_RESULT_SHA): return false
	var proof: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CANDIDATE_RESULT_PATH))
	if not _check(proof.get("complete")==true and proof.get("failures")==0 and proof.get("shared_ms")==120000 and proof.get("source_ready")==true,"Exact completed candidate scope, not old failure or extended budget"): return false
	var prior: Dictionary=proof.get("source_after",{})
	if not _check(not prior.is_empty() and prior==proof.get("source_before") and proof.get("players_after")==proof.get("players_before"),"Candidate source and all15save protection complete"): return false
	for path: String in prior:
		if FORMAL_PATCHES.has(path):
			var patch: Dictionary=FORMAL_PATCHES[path]
			if not _check(prior[path].sha256==patch.old_sha,"Exact authorized old helper provenance "+path): return false
			if not _track(patch.backup_path,patch.old_sha) or not _track(path,patch.new_sha): return false
			var before:=FileAccess.get_file_as_string(patch.backup_path)
			var after:=FileAccess.get_file_as_string(path)
			var old_literal: String="const FORMAL_ENABLED := false" if path==ASSEMBLY.SELF_PATH else "const FORMAL_ENABLED=false"
			var new_literal:=old_literal.replace("false","true")
			if not _check(before.count(old_literal)==1 and before.replace(old_literal,new_literal)==after,"Sole exact FORMAL false->true complete source edit "+path): return false
		else:
			if not _track(path,prior[path].sha256): return false
			var fresh: Dictionary=source_before[path]
			# JSON writer numeric domain only, no fractional/truncated fact acceptance.
			if not _check(prior[path].exists==fresh.exists and typeof(prior[path].bytes)==TYPE_FLOAT and typeof(prior[path].mtime_seconds)==TYPE_FLOAT and typeof(fresh.bytes)==TYPE_INT and typeof(fresh.mtime_seconds)==TYPE_INT and prior[path].bytes==float(fresh.bytes) and prior[path].mtime_seconds==float(fresh.mtime_seconds),"Unchanged exact source facts in writer numeric domain "+path): return false
	room_author=ASSEMBLY.author()
	var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(R.BIND_PATH))
	for id: String in ["ch4_s3_luoyang_market","ch4_s1_luoyang_yamen"]:
		var item: Dictionary=config.cities[id]
		manifest_records[id]=(JSON.parse_string(FileAccess.get_file_as_string(item.manifest_path)) as Dictionary).record
		candidate_manifest_paths[id]=item
	return _check(not room_author.is_empty(),"Formal room and city revision initialized, not parent candidate precheck bypass") and _track(get_script().resource_path)

func _exercise() -> bool:
	if not await _setup(PLAN.market): return false
	if not await _way(PLAN.market.approach,"formal_market_final46px_INPUT") or not _portal(PLAN.market): return false
	await driver.call("key",KEY_SPACE)
	if not await _wait(String(ASSEMBLY.ROOM)): return false
	var player:=field.get("_player") as CharacterBody2D
	var expected:=Vector2(room_author.geometry.spawn_foot_px[0],room_author.geometry.spawn_foot_px[1])*room_scale
	if not _check(player.position.distance_to(expected)<.3 and _clear(player.position),"Ordinary real Space new assembled-room exact feet spawn/full875+17/nativePhysics"): return false
	if _foot_frame("formal_ordinary_room_spawn").is_empty(): return false
	await _capture("formal_ordinary_assembled_smith_spawn")
	return failures==0

func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+FORMAL_LIMIT_MS
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players()
	output="res://build/luoyang_assembled_formal_entry_20261016b/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var complete:=false
	if _precheck():
		_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1,"Actual ordinary normal-clock GPU engine")
		driver=INPUT.new(); driver.call("configure",self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		initialized=true
		complete=await _exercise()
	if initialized: root.get_node("SceneRouter").call("reset_for_new_game")
	if driver!=null: driver.call("release"); driver=null
	if oracle!=null: oracle.call("release"); oracle=null
	field=null
	if initialized and is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	if initialized: await process_frame; await process_frame
	var after: Dictionary={}
	for path: String in source_before: after[path]=_fact(path)
	var player_after:=_players()
	_check(after==source_before and player_after==players_before and bridge.call("is_checkpoint_saves_suspended")==true,"Fresh formal source closure and15saves exact, not restored from snapshot")
	_check(complete and Time.get_ticks_msec()<deadline,"Independent NEW90s/60arrival ordinary birth-and-entry only")
	var file:=FileAccess.open(output.path_join("result.json"),FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"scope":"ORDINARY_ASSEMBLED_MARKET_BIRTH_ONE_REAL_DOOR_ENTRY_NOT_FULL_CANDIDATE_REPLAY","complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"shared_ms":FORMAL_LIMIT_MS,"arrival_ms":ARRIVAL_MS,"candidate_result_sha":CANDIDATE_RESULT_SHA,"records":rows,"captures":captures,"source_before":source_before,"source_after":after,"players_before":players_before,"players_after":player_after,"formal_source_ready":FORMAL_SOURCE_READY,"no_return_three_stations_yamen_or_quest_replay":true},"\t")); file.close()
	else: failures+=1
	print("ASSEMBLED_FORMAL_ENTRY=",output,"/result.json")
	quit(0 if complete and failures==0 else 1)
